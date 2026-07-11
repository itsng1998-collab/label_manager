import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/utils/log_context.dart';

String itemManagerDraftKey({
  required String userId,
  required int customerId,
  required int brandId,
  required int labelSizeId,
}) => '${userId}_${customerId}_${brandId}_$labelSizeId';

String itemManagerBaselineChecksum(ItemManagerDraftController controller) {
  final sourceRows = <int, ItemManagerDraftRow>{};
  for (final row in controller.rows) {
    final sourceItemId = row.sourceItemId;
    if (sourceItemId != null) sourceRows[sourceItemId] = row;
  }
  sourceRows.addAll(controller.deletedRowsBySourceItemId);
  return _itemManagerBaselineChecksumFor(
    sourceRows.values,
    controller.scopedColumnContents.values.values,
  );
}

String _itemManagerBaselineChecksumFor(
  Iterable<ItemManagerDraftRow> rows,
  Iterable<TColumnContent> columns,
) {
  final orderedSourceRows = rows.toList()
    ..sort((left, right) => left.originalIndex.compareTo(right.originalIndex));
  final scopedColumns = columns.toList()
    ..sort((left, right) {
      final itemCompare = left.itemId.compareTo(right.itemId);
      return itemCompare != 0
          ? itemCompare
          : left.columnId.compareTo(right.columnId);
    });
  return _fnv1a64Hex(
    jsonEncode({
      'rows': orderedSourceRows
          .map(_itemManagerBaselineRowJson)
          .toList(growable: false),
      'columns': [
        for (final value in scopedColumns)
          {
            'itemId': value.itemId,
            'columnId': value.columnId,
            'dataString': value.dataString,
          },
      ],
    }),
  );
}

class ItemManagerDraftJournalMetadata {
  final String draftKey;
  final String userId;
  final int customerId;
  final int brandId;
  final int labelSizeId;
  final int currentMarketId;
  final List<int> targetMarketIds;
  final Map<String, Object?> viewState;

  const ItemManagerDraftJournalMetadata({
    required this.draftKey,
    required this.userId,
    required this.customerId,
    required this.brandId,
    required this.labelSizeId,
    required this.currentMarketId,
    required this.targetMarketIds,
    this.viewState = const {},
  });

  void validate() {
    if (draftKey.trim().isEmpty ||
        userId.trim().isEmpty ||
        customerId <= 0 ||
        brandId <= 0 ||
        labelSizeId <= 0 ||
        currentMarketId <= 0) {
      throw ArgumentError('Draft journal metadata identities are required.');
    }
    if (targetMarketIds.isEmpty ||
        targetMarketIds.any((id) => id <= 0) ||
        targetMarketIds.toSet().length != targetMarketIds.length) {
      throw ArgumentError('Target market ids must be unique and positive.');
    }
  }

  Map<String, Object?> toJson() => {
    'draftKey': draftKey,
    'userId': userId,
    'customerId': customerId,
    'brandId': brandId,
    'labelSizeId': labelSizeId,
    'currentMarketId': currentMarketId,
    'targetMarketIds': targetMarketIds,
    'viewState': viewState,
  };
}

enum ItemManagerJournalRestoreResult {
  notFound,
  restored,
  invalid,
  externalChange,
}

class ItemManagerDraftJournal {
  static const int schemaVersion = 3;
  static const int checksumSchemaVersion = 1;
  static const List<String> checksumFields = [
    'rows.itemId',
    'rows.order',
    'rows.itemName',
    'rows.elementPlain',
    'rows.payloadEmpty',
    'rows.payloadFormat',
    'rows.payloadLength',
    'rows.payloadEdgeHash',
    'columns.itemId',
    'columns.columnId',
    'columns.dataString',
  ];
  static const String lastPathPreferenceKey = 'item_manager_draft_journal_path';
  static const String lastDraftKeyPreferenceKey =
      'item_manager_draft_journal_key';
  static const String lastSavedAtPreferenceKey =
      'item_manager_draft_journal_saved_at';

  final ItemManagerDraftController controller;
  final ItemManagerDraftJournalMetadata metadata;
  final ItemMarketMappingFingerprints mappingFingerprints;
  final Duration debounceDuration;
  final Future<Directory> Function() _directoryProvider;
  final Future<SharedPreferences> Function() _preferencesProvider;
  final Future<ItemMarketMappingFingerprints> Function(Iterable<int> itemIds)?
  _mappingFingerprintProvider;
  Timer? _debounce;
  Future<void> _writeQueue = Future<void>.value();
  bool _started = false;
  DateTime? _createdAt;

  ItemManagerDraftJournal({
    required this.controller,
    required this.metadata,
    required this.mappingFingerprints,
    this.debounceDuration = const Duration(milliseconds: 250),
    Future<Directory> Function()? directoryProvider,
    Future<SharedPreferences> Function()? preferencesProvider,
    Future<ItemMarketMappingFingerprints> Function(Iterable<int> itemIds)?
    mappingFingerprintProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance,
       _mappingFingerprintProvider = mappingFingerprintProvider;

  Future<void> start() async {
    if (_started) return;
    metadata.validate();
    _createdAt ??= DateTime.now().toUtc();
    await _ignoreBackgroundError(
      _clearLastJournalFromPreviousSession,
      'startup stale clear',
    );
    _started = true;
    controller.addListener(_handleDraftChanged);
    if (!controller.isDirty) await _ignoreBackgroundError(clear, 'start clear');
  }

  void _handleDraftChanged() {
    _debounce?.cancel();
    if (!controller.isDirty) {
      unawaited(_ignoreBackgroundError(clear, 'dirty clear'));
      return;
    }
    _debounce = Timer(
      debounceDuration,
      () => unawaited(_ignoreBackgroundError(flush, 'debounced flush')),
    );
  }

  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    if (!controller.isDirty) {
      await clear();
      return;
    }
    final document = _buildDocument();
    final previousWrite = _writeQueue;
    _writeQueue = () async {
      try {
        await previousWrite;
      } catch (error) {
        debugLog('item draft journal previous write failed: $error');
      }
      await _writeDocument(document);
    }();
    await _writeQueue;
  }

  Future<ItemManagerJournalRestoreResult> restoreBaseline() async {
    _debounce?.cancel();
    _debounce = null;
    await _writeQueue;
    final file = await _journalFile();
    if (!await file.exists()) return ItemManagerJournalRestoreResult.notFound;
    final document = jsonDecode(await file.readAsString());
    if (document is! Map<String, dynamic> ||
        document['version'] != schemaVersion) {
      return ItemManagerJournalRestoreResult.invalid;
    }
    final documentMetadata = document['metadata'];
    final baseline = document['baseline'];
    if (documentMetadata is! Map<String, dynamic> ||
        !_journalMetadataMatches(documentMetadata, metadata) ||
        baseline is! Map<String, dynamic> ||
        baseline['checksum'] != itemManagerBaselineChecksum(controller)) {
      return ItemManagerJournalRestoreResult.invalid;
    }
    final selectedRowKeys = documentMetadata['baselineSelectedRowKeys'];
    final baselineRows = baseline['rows'];
    final beforeSnapshots = document['beforeSnapshots'];
    final changes = document['changes'];
    if (selectedRowKeys is! List ||
        baselineRows is! List ||
        beforeSnapshots is! List ||
        changes is! Map<String, dynamic>) {
      return ItemManagerJournalRestoreResult.invalid;
    }
    final deletedSourceItemIds = changes['deletedSourceItemIds'];
    final changedRows = changes['rows'];
    final deletedRows = changes['deletedRows'];
    final changedExistingItemIds = _changedExistingRowItemIds(changedRows);
    final deletedItemIds = _strictPositiveIntSet(deletedSourceItemIds);
    final deletedRowItemIds = _deletedRowItemIds(deletedRows);
    if (changedExistingItemIds == null ||
        deletedItemIds == null ||
        deletedRowItemIds == null ||
        !setEquals(deletedItemIds, deletedRowItemIds) ||
        !setEquals(deletedItemIds, controller.deletedSourceItemIds)) {
      return ItemManagerJournalRestoreResult.invalid;
    }
    if (deletedItemIds.isNotEmpty && _mappingFingerprintProvider != null) {
      final storedFingerprints = baseline['mappingFingerprints'];
      if (storedFingerprints is! Map) {
        return ItemManagerJournalRestoreResult.invalid;
      }
      final currentFingerprints = await _mappingFingerprintProvider(
        deletedItemIds,
      );
      for (final itemId in deletedItemIds) {
        final stored = storedFingerprints['$itemId'];
        if (stored is! List || stored.any((id) => id is! int || id <= 0)) {
          return ItemManagerJournalRestoreResult.invalid;
        }
        final storedMarketIds = stored.cast<int>()..sort();
        if (!listEquals(
          storedMarketIds,
          currentFingerprints.marketIdsFor(itemId),
        )) {
          return ItemManagerJournalRestoreResult.externalChange;
        }
      }
    }
    final currentRows = {
      for (final row in controller.baselineRows) row.sourceItemId!: row,
    };
    final snapshotRows = <int, ItemManagerDraftRow>{};
    final snapshotColumns = <int, List<TColumnContent>>{};
    try {
      for (final value in beforeSnapshots) {
        final snapshot = Map<String, dynamic>.from(value as Map);
        final row = _draftRowBeforeSnapshotFromJson(snapshot);
        final itemId = row.sourceItemId!;
        if (snapshotRows.containsKey(itemId) ||
            row.currentMarketSnapshot?.itemId != itemId ||
            row.currentMarketSnapshot?.marketId != metadata.currentMarketId) {
          return ItemManagerJournalRestoreResult.invalid;
        }
        snapshotRows[itemId] = row;
        snapshotColumns[itemId] = [
          for (final column in snapshot['columns'] as List)
            _columnContentFromJson(Map<String, dynamic>.from(column as Map)),
        ];
        if (snapshotColumns[itemId]!.any((column) => column.itemId != itemId)) {
          return ItemManagerJournalRestoreResult.invalid;
        }
      }
      final requiredSnapshotItemIds = <int>{
        ...changedExistingItemIds,
        ...deletedItemIds,
      };
      if (!setEquals(snapshotRows.keys.toSet(), requiredSnapshotItemIds)) {
        return ItemManagerJournalRestoreResult.invalid;
      }
      final restoredRows = <ItemManagerDraftRow>[];
      final baselineItemIds = <int>{};
      for (final value in baselineRows) {
        final rowJson = Map<String, dynamic>.from(value as Map);
        final itemId = _jsonInt(rowJson, 'itemId');
        if (!baselineItemIds.add(itemId)) {
          return ItemManagerJournalRestoreResult.invalid;
        }
        final row = snapshotRows[itemId] ?? currentRows[itemId];
        if (row == null ||
            row.order != _jsonInt(rowJson, 'order') ||
            row.originalIndex != restoredRows.length) {
          return ItemManagerJournalRestoreResult.invalid;
        }
        restoredRows.add(row);
      }
      final restoredColumns = Map<ColumnItemKey, TColumnContent>.from(
        controller.scopedColumnContents.values,
      );
      for (final entry in snapshotColumns.entries) {
        restoredColumns.removeWhere((key, _) => key.itemId == entry.key);
        for (final column in entry.value) {
          restoredColumns[ColumnItemKey(
                columnId: column.columnId,
                itemId: column.itemId,
              )] =
              column;
        }
      }
      final restoredChecksum = _itemManagerBaselineChecksumFor(
        restoredRows,
        restoredColumns.values,
      );
      if (restoredChecksum != baseline['checksum']) {
        return ItemManagerJournalRestoreResult.invalid;
      }
      if (_started) controller.removeListener(_handleDraftChanged);
      try {
        controller.restoreJournalBaseline(
          rows: restoredRows,
          columnContents: TColumnContentScopedView(restoredColumns),
          selectedRowKeys: selectedRowKeys.whereType<String>(),
          anchorRowKey: documentMetadata['baselineAnchorRowKey'] as String?,
        );
      } finally {
        if (_started) controller.addListener(_handleDraftChanged);
      }
    } on Object catch (error) {
      debugLog('item draft journal restore invalid: $error');
      return ItemManagerJournalRestoreResult.invalid;
    }
    await _ignoreBackgroundError(clear, 'restore clear');
    return ItemManagerJournalRestoreResult.restored;
  }

  Future<void> _ignoreBackgroundError(
    Future<void> Function() operation,
    String operationName,
  ) async {
    try {
      await operation();
    } catch (error) {
      debugLog('item draft journal $operationName failed: $error');
    }
  }

  Future<void> clear() async {
    _debounce?.cancel();
    _debounce = null;
    final file = await _journalFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    for (final candidate in [temporary, file, backup]) {
      if (await candidate.exists()) await candidate.delete();
    }
    final preferences = await _preferencesProvider();
    if (preferences.getString(lastDraftKeyPreferenceKey) == metadata.draftKey) {
      await preferences.remove(lastPathPreferenceKey);
      await preferences.remove(lastDraftKeyPreferenceKey);
      await preferences.remove(lastSavedAtPreferenceKey);
    }
  }

  Future<void> _clearLastJournalFromPreviousSession() async {
    final preferences = await _preferencesProvider();
    final lastPath = preferences.getString(lastPathPreferenceKey);
    if (lastPath != null) {
      final directory = await _directoryProvider();
      final draftsDirectory = p.normalize(
        p.join(directory.path, 'item_manager_drafts'),
      );
      final normalizedPath = p.normalize(lastPath);
      if (p.isWithin(draftsDirectory, normalizedPath)) {
        for (final path in [
          '$normalizedPath.tmp',
          normalizedPath,
          '$normalizedPath.bak',
        ]) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      }
    }
    await preferences.remove(lastPathPreferenceKey);
    await preferences.remove(lastDraftKeyPreferenceKey);
    await preferences.remove(lastSavedAtPreferenceKey);
  }

  Future<void> close({bool clearFile = true}) async {
    _debounce?.cancel();
    _debounce = null;
    await _writeQueue;
    if (clearFile) await clear();
    if (_started) {
      controller.removeListener(_handleDraftChanged);
      _started = false;
    }
  }

  Map<String, Object?> _buildDocument() {
    final sourceRows = <int, ItemManagerDraftRow>{};
    for (final row in controller.rows) {
      final sourceItemId = row.sourceItemId;
      if (sourceItemId != null) sourceRows[sourceItemId] = row;
    }
    sourceRows.addAll(controller.deletedRowsBySourceItemId);
    final orderedSourceRows = sourceRows.values.toList()
      ..sort(
        (left, right) => left.originalIndex.compareTo(right.originalIndex),
      );

    final baselineRows = orderedSourceRows
        .map(_itemManagerBaselineRowJson)
        .toList(growable: false);
    final baselineItemIds = orderedSourceRows
        .map((row) => row.sourceItemId!)
        .toList(growable: false);
    final changedRows = controller.rows
        .where((row) => row.rowState != ItemManagerDraftRowState.existing)
        .map(_draftRowJson)
        .toList(growable: false);
    final deletedRows = controller.deletedRowsBySourceItemId.values
        .map(_draftRowJson)
        .toList(growable: false);
    final beforeSnapshotRows = <int, ItemManagerDraftRow>{
      for (final row in controller.rows)
        if (row.sourceItemId != null &&
            row.rowState != ItemManagerDraftRowState.existing)
          row.sourceItemId!: row,
      ...controller.deletedRowsBySourceItemId,
    };

    final updatedAt = DateTime.now().toUtc();
    return {
      'version': schemaVersion,
      'createdAt': (_createdAt ?? updatedAt).toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': {
        ...metadata.toJson(),
        'selectedRowKeys': controller.selectedRowKeys.toList(growable: false),
        'anchorRowKey': controller.anchorRowKey,
        'baselineSelectedRowKeys': controller.baselineSelectedRowKeys.toList(
          growable: false,
        ),
        'baselineAnchorRowKey': controller.baselineAnchorRowKey,
        'importViewState': controller.importViewState?.toJson(),
      },
      'baseline': {
        'rowCount': baselineRows.length,
        'rows': baselineRows,
        'checksum': itemManagerBaselineChecksum(controller),
        'checksumSchemaVersion': checksumSchemaVersion,
        'checksumFields': checksumFields,
        'mappingFingerprints': mappingFingerprints.toJsonForItems(
          baselineItemIds,
        ),
      },
      'beforeSnapshots': [
        for (final row in beforeSnapshotRows.values)
          _draftRowBeforeSnapshotJson(row),
      ],
      'changes': {
        'rows': changedRows,
        'deletedRows': deletedRows,
        'deletedSourceItemIds': controller.deletedSourceItemIds.toList(
          growable: false,
        ),
      },
    };
  }

  Map<String, Object?> _draftRowJson(ItemManagerDraftRow row) => {
    'rowKey': row.rowKey,
    'itemId': row.itemId,
    'draftRowKey': row.draftRowKey,
    'sourceItemId': row.sourceItemId,
    'insertAnchorItemId': row.insertAnchorItemId,
    'rowState': row.rowState.name,
    'order': row.order,
    'originalIndex': row.originalIndex,
    'itemName': row.itemName,
    'itemPrice': row.itemPrice,
    'elementPlain': row.elementPlain,
    'elementPayload': row.elementPayload,
    'elementPayloadFormat': row.elementPayloadFormat.name,
    'columnDrafts': {
      for (final entry in row.columnDrafts.entries)
        entry.key.toString(): {
          'editable': entry.value.editable,
          'dataString': entry.value.dataString,
        },
    },
    'currentMarketSnapshot': _rawSnapshotJson(row.currentMarketSnapshot),
    'newMappingDefaults': row.newMappingDefaults?.toJson(),
  };

  Map<String, Object?> _draftRowBeforeSnapshotJson(ItemManagerDraftRow row) {
    final source = row.source!;
    final itemId = row.sourceItemId!;
    return {
      'originalIndex': row.originalIndex,
      'source': _itemOfMarketJson(source),
      'rawSnapshot': _rawSnapshotJson(row.currentMarketSnapshot),
      'columns': [
        for (final value in controller.scopedColumnContents.values.values)
          if (value.itemId == itemId)
            {
              'colContentId': value.colContentId,
              'columnId': value.columnId,
              'itemId': value.itemId,
              'editable': value.editable,
              'dataString': value.dataString,
            },
      ],
    };
  }

  Map<String, Object?> _itemOfMarketJson(ItemOfMarket value) => {
    'marketId': value.marketId,
    'item': {
      'itemId': value.item.itemId,
      'labelSizeId': value.item.labelSizeId,
      'itemName': value.item.itemName,
      'labelSizeName': value.item.labelSizeName,
      'element': value.item.element,
      'elementRTF': value.item.elementRTF,
      'price': value.item.price,
      'order': value.item.order,
    },
    'additionalItem': {
      'additionalItemId': value.additionalItem.AdditionalItemId,
      'itemId': value.additionalItem.itemId,
      'element': value.additionalItem.element,
      'elementRTF': value.additionalItem.elementRTF,
      'price': value.additionalItem.price,
    },
    'gdsNo': value.gdsNo,
    'dateSaleStart': value.dateSaleStart.toIso8601String(),
    'dateSaleEnd': value.dateSaleEnd.toIso8601String(),
    'discountPercent': value.discountPercent,
    'discountAmount': value.discountAmount,
    'dateStartDiscount': value.dateStartDiscount.toIso8601String(),
    'dateEndDiscount': value.dateEndDiscount.toIso8601String(),
    'useDefineElement': value.useDefineElement,
    'rtfText': value.rtfText,
    'useLinefeed': value.useLinefeed,
    'linefeed': value.linefeed,
    'useScaleBarcode': value.useScaleBarcode,
    'printCount': value.printCount,
    'useLabelSize': value.useLabelSize,
    'labelSizeWidth': value.labelSizeWidth,
    'labelSizeHeight': value.labelSizeHeight,
    'useMargin': value.useMargin,
    'leftMargin': value.leftMargin,
    'rightMargin': value.rightMargin,
    'topMargin': value.topMargin,
    'leftPush': value.leftPush,
    'topPush': value.topPush,
  };

  Map<String, Object?>? _rawSnapshotJson(ItemOfMarketRawSnapshot? snapshot) {
    if (snapshot == null) return null;
    return {
      'marketId': snapshot.marketId,
      'itemId': snapshot.itemId,
      'additionalItemId': snapshot.additionalItemId,
      'gdsNo': snapshot.gdsNo,
      'dateSaleStart': snapshot.dateSaleStart?.toIso8601String(),
      'dateSaleEnd': snapshot.dateSaleEnd?.toIso8601String(),
      'discountPercent': snapshot.discountPercent,
      'discountAmount': snapshot.discountAmount,
      'dateStartDiscount': snapshot.dateStartDiscount?.toIso8601String(),
      'dateEndDiscount': snapshot.dateEndDiscount?.toIso8601String(),
      'useDefineElement': snapshot.useDefineElement,
      'rtfText': snapshot.rtfText,
      'useLinefeed': snapshot.useLinefeed,
      'linefeed': snapshot.linefeed,
      'useScaleBarcode': snapshot.useScaleBarcode,
      'printCount': snapshot.printCount,
      'useLabelSize': snapshot.useLabelSize,
      'labelSizeWidth': snapshot.labelSizeWidth,
      'labelSizeHeight': snapshot.labelSizeHeight,
      'useMargin': snapshot.useMargin,
      'leftMargin': snapshot.leftMargin,
      'rightMargin': snapshot.rightMargin,
      'topMargin': snapshot.topMargin,
      'leftPush': snapshot.leftPush,
      'topPush': snapshot.topPush,
    };
  }

  Future<File> _journalFile() async {
    final base = await _directoryProvider();
    final directory = Directory(p.join(base.path, 'item_manager_drafts'));
    if (!await directory.exists()) await directory.create(recursive: true);
    final safeKey = metadata.draftKey.replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    return File(p.join(directory.path, '$safeKey.json'));
  }

  Future<void> _writeDocument(Map<String, Object?> document) async {
    final target = await _journalFile();
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await temporary.writeAsString(jsonEncode(document), flush: true);
    if (await backup.exists()) await backup.delete();
    if (await target.exists()) await target.rename(backup.path);
    try {
      await temporary.rename(target.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await target.exists()) await target.delete();
      if (await backup.exists()) await backup.rename(target.path);
      rethrow;
    }

    final savedAt = document['updatedAt']! as String;
    final preferences = await _preferencesProvider();
    await preferences.setString(lastPathPreferenceKey, target.path);
    await preferences.setString(lastDraftKeyPreferenceKey, metadata.draftKey);
    await preferences.setString(lastSavedAtPreferenceKey, savedAt);
  }
}

String _payloadEdgeHash(String payload) {
  if (payload.isEmpty) return _fnv1a64Hex('');
  const edgeLength = 128;
  final head = payload.substring(0, payload.length.clamp(0, edgeLength));
  final tailStart = (payload.length - edgeLength).clamp(0, payload.length);
  return _fnv1a64Hex('$head|${payload.substring(tailStart)}');
}

Map<String, Object?> _itemManagerBaselineRowJson(ItemManagerDraftRow row) {
  final source = row.source!;
  final payload = source.item.elementRTF;
  return {
    'itemId': source.item.itemId,
    'order': source.item.order,
    'itemName': source.item.itemName,
    'elementPlain': source.item.element,
    'payloadEmpty': payload.isEmpty,
    'payloadFormat': row.elementPayloadFormat.name,
    'payloadLength': payload.length,
    'payloadEdgeHash': _payloadEdgeHash(payload),
  };
}

ItemManagerDraftRow _draftRowBeforeSnapshotFromJson(Map<String, dynamic> json) {
  final source = _itemOfMarketFromJson(
    Map<String, dynamic>.from(json['source'] as Map),
  );
  final rawSnapshot = _rawSnapshotFromJson(
    Map<String, dynamic>.from(json['rawSnapshot'] as Map),
  );
  return ItemManagerDraftRow.existing(
    source: source,
    currentMarketSnapshot: rawSnapshot,
    originalIndex: _jsonInt(json, 'originalIndex'),
  );
}

ItemOfMarket _itemOfMarketFromJson(Map<String, dynamic> json) {
  final item = Map<String, dynamic>.from(json['item'] as Map);
  final additional = Map<String, dynamic>.from(json['additionalItem'] as Map);
  return ItemOfMarket(
    marketId: _jsonInt(json, 'marketId'),
    item: Item(
      itemId: _jsonInt(item, 'itemId'),
      labelSizeId: _jsonInt(item, 'labelSizeId'),
      itemName: item['itemName'] as String,
      labelSizeName: item['labelSizeName'] as String,
      element: item['element'] as String,
      elementRTF: item['elementRTF'] as String,
      price: _jsonInt(item, 'price'),
      order: _jsonInt(item, 'order'),
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: _jsonInt(additional, 'additionalItemId'),
      itemId: _jsonInt(additional, 'itemId'),
      element: additional['element'] as String,
      elementRTF: additional['elementRTF'] as String,
      price: _jsonInt(additional, 'price'),
    ),
    gdsNo: _jsonInt(json, 'gdsNo'),
    dateSaleStart: DateTime.parse(json['dateSaleStart'] as String),
    dateSaleEnd: DateTime.parse(json['dateSaleEnd'] as String),
    discountPercent: (json['discountPercent'] as num).toDouble(),
    discountAmount: _jsonInt(json, 'discountAmount'),
    dateStartDiscount: DateTime.parse(json['dateStartDiscount'] as String),
    dateEndDiscount: DateTime.parse(json['dateEndDiscount'] as String),
    useDefineElement: json['useDefineElement'] as bool,
    rtfText: json['rtfText'] as String,
    useLinefeed: json['useLinefeed'] as bool,
    linefeed: _jsonInt(json, 'linefeed'),
    useScaleBarcode: json['useScaleBarcode'] as bool,
    printCount: _jsonInt(json, 'printCount'),
    useLabelSize: json['useLabelSize'] as bool,
    labelSizeWidth: _jsonInt(json, 'labelSizeWidth'),
    labelSizeHeight: _jsonInt(json, 'labelSizeHeight'),
    useMargin: json['useMargin'] as bool,
    leftMargin: (json['leftMargin'] as num).toDouble(),
    rightMargin: (json['rightMargin'] as num).toDouble(),
    topMargin: (json['topMargin'] as num).toDouble(),
    leftPush: (json['leftPush'] as num).toDouble(),
    topPush: (json['topPush'] as num).toDouble(),
  );
}

ItemOfMarketRawSnapshot _rawSnapshotFromJson(Map<String, dynamic> json) {
  DateTime? date(String key) =>
      json[key] == null ? null : DateTime.parse(json[key] as String);
  int? integer(String key) =>
      json[key] == null ? null : _strictJsonInt(json[key], key);
  double? number(String key) => (json[key] as num?)?.toDouble();
  return ItemOfMarketRawSnapshot(
    marketId: _jsonInt(json, 'marketId'),
    itemId: _jsonInt(json, 'itemId'),
    additionalItemId: integer('additionalItemId'),
    gdsNo: integer('gdsNo'),
    dateSaleStart: date('dateSaleStart'),
    dateSaleEnd: date('dateSaleEnd'),
    discountPercent: number('discountPercent'),
    discountAmount: integer('discountAmount'),
    dateStartDiscount: date('dateStartDiscount'),
    dateEndDiscount: date('dateEndDiscount'),
    useDefineElement: json['useDefineElement'] as bool?,
    rtfText: json['rtfText'] as String?,
    useLinefeed: json['useLinefeed'] as bool?,
    linefeed: integer('linefeed'),
    useScaleBarcode: json['useScaleBarcode'] as bool?,
    printCount: integer('printCount'),
    useLabelSize: json['useLabelSize'] as bool?,
    labelSizeWidth: integer('labelSizeWidth'),
    labelSizeHeight: integer('labelSizeHeight'),
    useMargin: json['useMargin'] as bool?,
    leftMargin: number('leftMargin'),
    rightMargin: number('rightMargin'),
    topMargin: number('topMargin'),
    leftPush: number('leftPush'),
    topPush: number('topPush'),
  );
}

TColumnContent _columnContentFromJson(Map<String, dynamic> json) =>
    TColumnContent(
      colContentId: _jsonInt(json, 'colContentId'),
      columnId: _jsonInt(json, 'columnId'),
      itemId: _jsonInt(json, 'itemId'),
      editable: json['editable'] as bool,
      dataString: json['dataString'] as String,
    );

int _jsonInt(Map<String, dynamic> json, String key) =>
    _strictJsonInt(json[key], key);

int _strictJsonInt(Object? value, String key) {
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Set<int>? _strictPositiveIntSet(Object? value) {
  if (value is! List) return null;
  final result = <int>{};
  for (final item in value) {
    if (item is! int || item <= 0 || !result.add(item)) return null;
  }
  return result;
}

Set<int>? _deletedRowItemIds(Object? value) {
  if (value is! List) return null;
  final result = <int>{};
  for (final item in value) {
    if (item is! Map) return null;
    final row = Map<String, dynamic>.from(item);
    final sourceItemId = row['sourceItemId'];
    if (sourceItemId is! int ||
        sourceItemId <= 0 ||
        !result.add(sourceItemId)) {
      return null;
    }
  }
  return result;
}

Set<int>? _changedExistingRowItemIds(Object? value) {
  if (value is! List) return null;
  final result = <int>{};
  for (final item in value) {
    if (item is! Map) return null;
    final row = Map<String, dynamic>.from(item);
    final sourceItemId = row['sourceItemId'];
    final rowState = row['rowState'];
    if (sourceItemId == null) {
      if (rowState != ItemManagerDraftRowState.added.name &&
          rowState != ItemManagerDraftRowState.imported.name) {
        return null;
      }
      continue;
    }
    if (sourceItemId is! int ||
        sourceItemId <= 0 ||
        rowState != ItemManagerDraftRowState.modified.name ||
        !result.add(sourceItemId)) {
      return null;
    }
  }
  return result;
}

bool _journalMetadataMatches(
  Map<String, dynamic> json,
  ItemManagerDraftJournalMetadata expected,
) {
  final targetMarketIds = json['targetMarketIds'];
  final actualTargets = _strictPositiveIntSet(targetMarketIds);
  if (actualTargets == null) return false;
  final expectedTargets = expected.targetMarketIds.toSet();
  return json['draftKey'] == expected.draftKey &&
      json['userId'] == expected.userId &&
      json['customerId'] is int &&
      json['customerId'] == expected.customerId &&
      json['brandId'] is int &&
      json['brandId'] == expected.brandId &&
      json['labelSizeId'] is int &&
      json['labelSizeId'] == expected.labelSizeId &&
      json['currentMarketId'] is int &&
      json['currentMarketId'] == expected.currentMarketId &&
      actualTargets.length == expectedTargets.length &&
      actualTargets.containsAll(expectedTargets);
}

String _fnv1a64Hex(String input) {
  final offset = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  var hash = offset;
  for (final byte in utf8.encode(input)) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
