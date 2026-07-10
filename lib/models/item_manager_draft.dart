import 'package:flutter/foundation.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_save.dart';
import 'package:label_manager/models/item_of_market.dart';

abstract final class ItemManagerLimits {
  static const int maxRows = 10000;
}

enum ItemManagerDraftRowState { existing, modified, added, imported }

enum ItemManagerElementPayloadFormat { empty, workbook, legacyRtf, unknown }

@immutable
class ItemManagerColumnDraft {
  final bool editable;
  final String dataString;

  const ItemManagerColumnDraft({
    required this.editable,
    required this.dataString,
  });
}

@immutable
class ItemManagerImportedRow {
  const ItemManagerImportedRow({
    required this.itemName,
    required this.elementPlain,
    required this.elementPayload,
    this.columnDrafts = const {},
  });

  final String itemName;
  final String elementPlain;
  final String elementPayload;
  final Map<int, ItemManagerColumnDraft> columnDrafts;
}

@immutable
class ItemManagerDraftRow {
  final String rowKey;
  final int? itemId;
  final String? draftRowKey;
  final int? sourceItemId;
  final int? insertAnchorItemId;
  final ItemManagerDraftRowState rowState;
  final int order;
  final int originalIndex;
  final String itemName;
  final int itemPrice;
  final String elementPlain;
  final String elementPayload;
  final ItemManagerElementPayloadFormat elementPayloadFormat;
  final Map<int, ItemManagerColumnDraft> columnDrafts;
  final ItemOfMarketRawSnapshot? currentMarketSnapshot;
  final ItemManagerNewMappingDefaults? newMappingDefaults;
  final ItemOfMarket? source;

  const ItemManagerDraftRow({
    required this.rowKey,
    required this.itemId,
    required this.draftRowKey,
    required this.sourceItemId,
    required this.insertAnchorItemId,
    required this.rowState,
    required this.order,
    required this.originalIndex,
    required this.itemName,
    required this.itemPrice,
    required this.elementPlain,
    required this.elementPayload,
    required this.elementPayloadFormat,
    required this.columnDrafts,
    required this.currentMarketSnapshot,
    required this.newMappingDefaults,
    required this.source,
  });

  factory ItemManagerDraftRow.existing({
    required ItemOfMarket source,
    required ItemOfMarketRawSnapshot currentMarketSnapshot,
    required int originalIndex,
  }) {
    if (source.item.itemId != currentMarketSnapshot.itemId) {
      throw ArgumentError('Item and raw snapshot identities must match.');
    }
    return ItemManagerDraftRow(
      rowKey: 'item:${source.item.itemId}',
      itemId: source.item.itemId,
      draftRowKey: null,
      sourceItemId: source.item.itemId,
      insertAnchorItemId: null,
      rowState: ItemManagerDraftRowState.existing,
      order: source.item.order,
      originalIndex: originalIndex,
      itemName: source.item.itemName,
      itemPrice: source.item.price,
      elementPlain: source.item.element,
      elementPayload: source.item.elementRTF,
      elementPayloadFormat: _classifyElementPayload(source.item.elementRTF),
      columnDrafts: const {},
      currentMarketSnapshot: currentMarketSnapshot,
      newMappingDefaults: null,
      source: source,
    );
  }

  factory ItemManagerDraftRow.newRow({
    required String draftRowKey,
    required int order,
    required int originalIndex,
    required int? insertAnchorItemId,
    required ItemManagerDraftRowState rowState,
    required String emptyElementPayload,
    ItemManagerNewMappingDefaults newMappingDefaults =
        const ItemManagerNewMappingDefaults(),
  }) {
    if (rowState != ItemManagerDraftRowState.added &&
        rowState != ItemManagerDraftRowState.imported) {
      throw ArgumentError('New rows require added or imported state.');
    }
    return ItemManagerDraftRow(
      rowKey: 'draft:$draftRowKey',
      itemId: null,
      draftRowKey: draftRowKey,
      sourceItemId: null,
      insertAnchorItemId: insertAnchorItemId,
      rowState: rowState,
      order: order,
      originalIndex: originalIndex,
      itemName: '',
      itemPrice: 0,
      elementPlain: '',
      elementPayload: emptyElementPayload,
      elementPayloadFormat: _classifyElementPayload(emptyElementPayload),
      columnDrafts: const {},
      currentMarketSnapshot: null,
      newMappingDefaults: newMappingDefaults,
      source: null,
    );
  }

  bool get isNew => sourceItemId == null;

  ItemOfMarket toPreviewItem({
    required int marketId,
    required int labelSizeId,
    required String labelSizeName,
  }) {
    if (source != null && rowState == ItemManagerDraftRowState.existing) {
      return source!;
    }
    final snapshot = currentMarketSnapshot;
    final defaults = newMappingDefaults;
    final now = DateTime.now();
    return ItemOfMarket(
      marketId: marketId,
      item: Item(
        itemId: itemId ?? 0,
        labelSizeId: labelSizeId,
        itemName: itemName,
        labelSizeName: labelSizeName,
        element: elementPlain,
        elementRTF: elementPayload,
        price: itemPrice,
        order: order,
      ),
      additionalItem: AdditionalItem(
        AdditionalItemId: snapshot?.additionalItemId ?? 0,
        itemId: itemId ?? 0,
        element: '',
        elementRTF: '',
        price: 0,
      ),
      gdsNo: snapshot?.gdsNo ?? defaults?.gdsNo ?? 0,
      dateSaleStart: snapshot?.dateSaleStart ?? defaults?.dateSaleStart ?? now,
      dateSaleEnd: snapshot?.dateSaleEnd ?? defaults?.dateSaleEnd ?? now,
      discountPercent:
          snapshot?.discountPercent ?? defaults?.discountPercent ?? 0,
      discountAmount: snapshot?.discountAmount ?? defaults?.discountAmount ?? 0,
      dateStartDiscount:
          snapshot?.dateStartDiscount ?? defaults?.dateStartDiscount ?? now,
      dateEndDiscount:
          snapshot?.dateEndDiscount ?? defaults?.dateEndDiscount ?? now,
      useDefineElement:
          snapshot?.useDefineElement ?? defaults?.useDefineElement ?? false,
      rtfText: snapshot?.rtfText ?? defaults?.rtfText ?? '',
      useLinefeed: snapshot?.useLinefeed ?? defaults?.useLinefeed ?? false,
      linefeed: snapshot?.linefeed ?? defaults?.linefeed ?? 100,
      useScaleBarcode:
          snapshot?.useScaleBarcode ?? defaults?.useScaleBarcode ?? false,
      printCount: snapshot?.printCount ?? defaults?.printCount ?? 1,
      useLabelSize: snapshot?.useLabelSize ?? defaults?.useLabelSize ?? false,
      labelSizeWidth: snapshot?.labelSizeWidth ?? defaults?.labelSizeWidth ?? 0,
      labelSizeHeight:
          snapshot?.labelSizeHeight ?? defaults?.labelSizeHeight ?? 0,
      useMargin: snapshot?.useMargin ?? defaults?.useMargin ?? false,
      leftMargin: snapshot?.leftMargin ?? defaults?.leftMargin ?? 0,
      rightMargin: snapshot?.rightMargin ?? defaults?.rightMargin ?? 0,
      topMargin: snapshot?.topMargin ?? defaults?.topMargin ?? 0,
      leftPush: snapshot?.leftPush ?? defaults?.leftPush ?? 0,
      topPush: snapshot?.topPush ?? defaults?.topPush ?? 0,
    );
  }

  ItemManagerDraftRow copyWith({
    ItemManagerDraftRowState? rowState,
    int? order,
    String? itemName,
    String? elementPlain,
    String? elementPayload,
    ItemManagerElementPayloadFormat? elementPayloadFormat,
    Map<int, ItemManagerColumnDraft>? columnDrafts,
  }) {
    return ItemManagerDraftRow(
      rowKey: rowKey,
      itemId: itemId,
      draftRowKey: draftRowKey,
      sourceItemId: sourceItemId,
      insertAnchorItemId: insertAnchorItemId,
      rowState: rowState ?? this.rowState,
      order: order ?? this.order,
      originalIndex: originalIndex,
      itemName: itemName ?? this.itemName,
      itemPrice: itemPrice,
      elementPlain: elementPlain ?? this.elementPlain,
      elementPayload: elementPayload ?? this.elementPayload,
      elementPayloadFormat: elementPayloadFormat ?? this.elementPayloadFormat,
      columnDrafts: columnDrafts ?? this.columnDrafts,
      currentMarketSnapshot: currentMarketSnapshot,
      newMappingDefaults: newMappingDefaults,
      source: source,
    );
  }
}

class ItemManagerDraftController extends ChangeNotifier {
  final List<ItemManagerDraftRow> _rows;
  final TColumnContentScopedView scopedColumnContents;
  final Set<int> _deletedSourceItemIds = {};
  final Map<int, ItemManagerDraftRow> _deletedRowsBySourceItemId = {};
  final Set<String> _selectedRowKeys = {};
  int _draftSequence = 0;
  String? _anchorRowKey;

  ItemManagerDraftController({
    required List<ItemManagerDraftRow> rows,
    required this.scopedColumnContents,
  }) : _rows = List.of(rows) {
    _validateRows(_rows);
  }

  factory ItemManagerDraftController.fromItems({
    required List<ItemOfMarket> items,
    required Map<int, ItemOfMarketRawSnapshot> rawSnapshots,
    required TColumnContentScopedView scopedColumnContents,
  }) {
    final rows = <ItemManagerDraftRow>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final snapshot = rawSnapshots[item.item.itemId];
      if (snapshot == null) {
        throw ArgumentError(
          'Missing raw snapshot for itemId:${item.item.itemId}.',
        );
      }
      rows.add(
        ItemManagerDraftRow.existing(
          source: item,
          currentMarketSnapshot: snapshot,
          originalIndex: index,
        ),
      );
    }
    return ItemManagerDraftController(
      rows: rows,
      scopedColumnContents: scopedColumnContents,
    );
  }

  List<ItemManagerDraftRow> get rows => List.unmodifiable(_rows);
  Set<int> get deletedSourceItemIds => Set.unmodifiable(_deletedSourceItemIds);
  Map<int, ItemManagerDraftRow> get deletedRowsBySourceItemId =>
      Map.unmodifiable(_deletedRowsBySourceItemId);
  Set<String> get selectedRowKeys => Set.unmodifiable(_selectedRowKeys);
  String? get anchorRowKey => _anchorRowKey;
  bool get isDirty =>
      _deletedSourceItemIds.isNotEmpty ||
      _rows.any((row) => row.rowState != ItemManagerDraftRowState.existing);

  String columnValue(ItemManagerDraftRow row, int columnId) {
    final draft = row.columnDrafts[columnId];
    if (draft != null) return draft.dataString;
    final itemId = row.sourceItemId;
    return itemId == null ? '' : scopedColumnContents.value(columnId, itemId);
  }

  void updateItemName(String rowKey, String itemName) {
    _updateRow(rowKey, (row) {
      if (row.itemName == itemName) return row;
      final changed = row.copyWith(itemName: itemName);
      return _withCurrentState(changed);
    });
  }

  void updateElement(
    String rowKey, {
    required String elementPlain,
    required String elementPayload,
  }) {
    _updateRow(rowKey, (row) {
      if (row.elementPlain == elementPlain &&
          row.elementPayload == elementPayload) {
        return row;
      }
      final changed = row.copyWith(
        elementPlain: elementPlain,
        elementPayload: elementPayload,
        elementPayloadFormat: _classifyElementPayload(elementPayload),
      );
      return _withCurrentState(changed);
    });
  }

  void updateColumnValue(
    String rowKey, {
    required int columnId,
    required bool editable,
    required String dataString,
  }) {
    if (columnId <= 0) {
      throw ArgumentError.value(columnId, 'columnId', 'Must be positive.');
    }
    _updateRow(rowKey, (row) {
      final original = row.sourceItemId == null
          ? ''
          : scopedColumnContents.value(columnId, row.sourceItemId!);
      final drafts = Map<int, ItemManagerColumnDraft>.of(row.columnDrafts);
      if (!row.isNew && dataString == original) {
        drafts.remove(columnId);
      } else {
        drafts[columnId] = ItemManagerColumnDraft(
          editable: editable,
          dataString: dataString,
        );
      }
      final changed = row.copyWith(columnDrafts: Map.unmodifiable(drafts));
      return _withCurrentState(changed);
    });
  }

  ItemManagerSaveCommand toSaveCommand({
    required int labelSizeId,
    required List<int> targetMarketIds,
  }) {
    validateForSave();
    if (labelSizeId <= 0) {
      throw ArgumentError.value(
        labelSizeId,
        'labelSizeId',
        'Must be positive.',
      );
    }
    final existingRows = <ItemManagerExistingRowSave>[];
    final newRows = <ItemManagerNewRowSave>[];
    final columnValues = <ItemManagerColumnValueSave>[];
    for (final row in _rows) {
      final sourceItemId = row.sourceItemId;
      if (sourceItemId != null &&
          row.rowState == ItemManagerDraftRowState.modified) {
        existingRows.add(
          ItemManagerExistingRowSave(
            sourceItemId: sourceItemId,
            itemName: row.itemName,
            elementPlain: row.elementPlain,
            elementSheet: row.elementPayload,
            order: row.order,
          ),
        );
      } else if (sourceItemId == null) {
        newRows.add(
          ItemManagerNewRowSave(
            draftRowKey: row.draftRowKey!,
            labelSizeId: labelSizeId,
            itemName: row.itemName,
            elementPlain: row.elementPlain,
            elementSheet: row.elementPayload,
            order: row.order,
            mappingDefaults: row.newMappingDefaults!,
          ),
        );
      }
      for (final entry in row.columnDrafts.entries) {
        columnValues.add(
          ItemManagerColumnValueSave(
            sourceItemId: sourceItemId,
            draftRowKey: row.draftRowKey,
            columnId: entry.key,
            editable: entry.value.editable,
            dataString: entry.value.dataString,
          ),
        );
      }
    }
    final command = ItemManagerSaveCommand(
      targetMarketIds: List.unmodifiable(targetMarketIds),
      deletedSourceItemIds: _deletedSourceItemIds.toList(growable: false),
      existingRows: existingRows,
      newRows: newRows,
      columnValues: columnValues,
    );
    command.validate();
    return command;
  }

  void validateForSave() {
    if (_rows.length > ItemManagerLimits.maxRows) {
      throw StateError('품목은 최대 ${ItemManagerLimits.maxRows}개까지 저장할 수 있습니다.');
    }
    final emptyNameIndex = _rows.indexWhere(
      (row) => row.itemName.trim().isEmpty,
    );
    if (emptyNameIndex >= 0) {
      throw StateError('${emptyNameIndex + 1}행의 품명을 입력해 주세요.');
    }
  }

  void setSelection(Iterable<String> rowKeys, {String? anchorRowKey}) {
    final validKeys = _rows.map((row) => row.rowKey).toSet();
    _selectedRowKeys
      ..clear()
      ..addAll(rowKeys.where(validKeys.contains));
    _anchorRowKey = anchorRowKey != null && validKeys.contains(anchorRowKey)
        ? anchorRowKey
        : (_selectedRowKeys.isEmpty ? null : _selectedRowKeys.last);
    notifyListeners();
  }

  List<ItemManagerDraftRow> addRows(
    int count, {
    required String emptyElementPayload,
  }) {
    _validateAddCount(count);
    final added = _createNewRows(
      count,
      startOrder: _nextOrder,
      originalIndex: _rows.length,
      insertAnchorItemId: null,
      emptyElementPayload: emptyElementPayload,
    );
    _rows.addAll(added);
    _selectAdded(added);
    notifyListeners();
    return List.unmodifiable(added);
  }

  List<ItemManagerDraftRow> insertRowsAfter(
    String anchorRowKey,
    int count, {
    required String emptyElementPayload,
  }) {
    _validateAddCount(count);
    final anchorIndex = _rows.indexWhere((row) => row.rowKey == anchorRowKey);
    if (anchorIndex < 0) {
      throw ArgumentError.value(anchorRowKey, 'anchorRowKey', 'Unknown row.');
    }
    final anchor = _rows[anchorIndex];
    final added = _createNewRows(
      count,
      startOrder: anchor.order + 1,
      originalIndex: anchorIndex + 1,
      insertAnchorItemId: anchor.sourceItemId,
      emptyElementPayload: emptyElementPayload,
    );
    _rows.insertAll(anchorIndex + 1, added);
    _renumberRows();
    _selectAdded(added);
    notifyListeners();
    return List.unmodifiable(added);
  }

  List<ItemManagerDraftRow> replaceAllWithImportedRows(
    List<ItemManagerImportedRow> importedRows,
  ) {
    if (isDirty) {
      throw StateError('Import requires a clean item draft.');
    }
    if (importedRows.isEmpty) {
      throw ArgumentError.value(
        importedRows,
        'importedRows',
        'Must not be empty.',
      );
    }
    if (importedRows.length > ItemManagerLimits.maxRows) {
      throw StateError(
        'Item row limit exceeded: ${ItemManagerLimits.maxRows}.',
      );
    }
    for (final row in _rows) {
      final sourceItemId = row.sourceItemId;
      if (sourceItemId == null) continue;
      _deletedSourceItemIds.add(sourceItemId);
      _deletedRowsBySourceItemId[sourceItemId] = row;
    }
    final replacements = [
      for (var index = 0; index < importedRows.length; index += 1)
        ItemManagerDraftRow.newRow(
          draftRowKey:
              'import-${DateTime.now().microsecondsSinceEpoch}-${_draftSequence++}',
          order: index + 1,
          originalIndex: index,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.imported,
          emptyElementPayload: importedRows[index].elementPayload,
        ).copyWith(
          itemName: importedRows[index].itemName,
          elementPlain: importedRows[index].elementPlain,
          columnDrafts: Map.unmodifiable(importedRows[index].columnDrafts),
        ),
    ];
    _validateRows(replacements);
    _rows
      ..clear()
      ..addAll(replacements);
    _selectedRowKeys
      ..clear()
      ..add(replacements.first.rowKey);
    _anchorRowKey = replacements.first.rowKey;
    notifyListeners();
    return List.unmodifiable(replacements);
  }

  String? deleteRows(Iterable<String> rowKeys) {
    final keys = rowKeys.toSet();
    if (keys.isEmpty) return _anchorRowKey;
    final indexes = <int>[];
    for (var index = 0; index < _rows.length; index++) {
      if (keys.contains(_rows[index].rowKey)) indexes.add(index);
    }
    if (indexes.isEmpty) return _anchorRowKey;

    final lastDeletedIndex = indexes.last;
    for (final index in indexes.reversed) {
      final removed = _rows.removeAt(index);
      final sourceItemId = removed.sourceItemId;
      if (sourceItemId != null) {
        _deletedSourceItemIds.add(sourceItemId);
        _deletedRowsBySourceItemId.putIfAbsent(sourceItemId, () => removed);
      }
    }
    _renumberRows();
    _selectedRowKeys.removeAll(keys);
    final nextIndex = _rows.isEmpty
        ? null
        : lastDeletedIndex.clamp(0, _rows.length - 1);
    final nextKey = nextIndex == null ? null : _rows[nextIndex].rowKey;
    _selectedRowKeys
      ..clear()
      ..addAll(nextKey == null ? const <String>[] : [nextKey]);
    _anchorRowKey = nextKey;
    notifyListeners();
    return nextKey;
  }

  void _validateAddCount(int count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Must be positive.');
    }
    if (_rows.length + count > ItemManagerLimits.maxRows) {
      throw StateError(
        'Item row limit exceeded: ${ItemManagerLimits.maxRows}.',
      );
    }
  }

  void _updateRow(
    String rowKey,
    ItemManagerDraftRow Function(ItemManagerDraftRow row) update,
  ) {
    final index = _rows.indexWhere((row) => row.rowKey == rowKey);
    if (index < 0) {
      throw ArgumentError.value(rowKey, 'rowKey', 'Unknown row.');
    }
    final previous = _rows[index];
    final next = update(previous);
    if (identical(previous, next)) return;
    _rows[index] = next;
    notifyListeners();
  }

  ItemManagerDraftRow _withCurrentState(ItemManagerDraftRow row) {
    if (row.isNew) return row;
    final source = row.source!;
    final modified =
        row.order != source.item.order ||
        row.itemName != source.item.itemName ||
        row.elementPlain != source.item.element ||
        row.elementPayload != source.item.elementRTF ||
        row.columnDrafts.isNotEmpty;
    return row.copyWith(
      rowState: modified
          ? ItemManagerDraftRowState.modified
          : ItemManagerDraftRowState.existing,
    );
  }

  List<ItemManagerDraftRow> _createNewRows(
    int count, {
    required int startOrder,
    required int originalIndex,
    required int? insertAnchorItemId,
    required String emptyElementPayload,
  }) {
    return List.generate(count, (offset) {
      final draftRowKey =
          '${DateTime.now().microsecondsSinceEpoch}-${_draftSequence++}';
      return ItemManagerDraftRow.newRow(
        draftRowKey: draftRowKey,
        order: startOrder + offset,
        originalIndex: originalIndex + offset,
        insertAnchorItemId: insertAnchorItemId,
        rowState: ItemManagerDraftRowState.added,
        emptyElementPayload: emptyElementPayload,
      );
    }, growable: false);
  }

  void _selectAdded(List<ItemManagerDraftRow> added) {
    _selectedRowKeys
      ..clear()
      ..addAll(added.map((row) => row.rowKey));
    _anchorRowKey = added.first.rowKey;
  }

  int get _nextOrder {
    if (_rows.isEmpty) return 1;
    return _rows.map((row) => row.order).reduce((a, b) => a > b ? a : b) + 1;
  }

  void _renumberRows() {
    for (var index = 0; index < _rows.length; index++) {
      final row = _rows[index];
      final nextOrder = index + 1;
      if (row.order == nextOrder) continue;
      final nextState = row.rowState == ItemManagerDraftRowState.existing
          ? ItemManagerDraftRowState.modified
          : row.rowState;
      _rows[index] = row.copyWith(rowState: nextState, order: nextOrder);
    }
  }

  static void _validateRows(List<ItemManagerDraftRow> rows) {
    if (rows.length > ItemManagerLimits.maxRows) {
      throw StateError(
        'Item row limit exceeded: ${ItemManagerLimits.maxRows}.',
      );
    }
    final rowKeys = rows.map((row) => row.rowKey).toSet();
    if (rowKeys.length != rows.length) {
      throw ArgumentError('Draft row keys must be unique.');
    }
    for (final row in rows) {
      final existing = row.sourceItemId != null;
      if (existing != (row.currentMarketSnapshot != null) ||
          existing == (row.newMappingDefaults != null)) {
        throw ArgumentError('Draft row state does not match its snapshots.');
      }
    }
  }
}

ItemManagerElementPayloadFormat _classifyElementPayload(String payload) {
  final value = payload.trimLeft();
  if (value.isEmpty) return ItemManagerElementPayloadFormat.empty;
  if (value.startsWith(r'{\rtf')) {
    return ItemManagerElementPayloadFormat.legacyRtf;
  }
  if (value.startsWith('UEsD') ||
      value.startsWith('{') ||
      value.startsWith('[')) {
    return ItemManagerElementPayloadFormat.workbook;
  }
  return ItemManagerElementPayloadFormat.unknown;
}
