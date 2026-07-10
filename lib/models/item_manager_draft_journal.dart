import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final orderedSourceRows = sourceRows.values.toList()
    ..sort((left, right) => left.originalIndex.compareTo(right.originalIndex));
  final scopedColumns = controller.scopedColumnContents.values.values.toList()
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

class ItemManagerDraftJournal {
  static const int schemaVersion = 2;
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
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

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
    if (_started) {
      controller.removeListener(_handleDraftChanged);
      _started = false;
    }
    _debounce?.cancel();
    _debounce = null;
    await _writeQueue;
    if (clearFile) await clear();
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

    final updatedAt = DateTime.now().toUtc();
    return {
      'version': schemaVersion,
      'createdAt': (_createdAt ?? updatedAt).toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': {
        ...metadata.toJson(),
        'selectedRowKeys': controller.selectedRowKeys.toList(growable: false),
        'anchorRowKey': controller.anchorRowKey,
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

Map<String, Object?> _itemManagerBaselineRowJson(
  ItemManagerDraftRow row,
) {
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
