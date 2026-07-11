import 'package:flutter/foundation.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/gs1_ai.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_save.dart';
import 'package:label_manager/models/item_of_market.dart';

abstract final class ItemManagerLimits {
  static const int maxRows = 10000;
}

class ItemManagerFixedColumnIds {
  static const int itemName = -1;
  static const int element = -2;
}

enum ItemManagerDraftRowState { existing, modified, added, imported }

String itemManagerSaveConfirmationMessage({required bool hasDeletedItems}) {
  const prompt = '품목관리 변경 사항을 저장할까요?';
  return hasDeletedItems
      ? '$prompt\n\n삭제한 품목은 같은 고객의 다른 market 품목관리에서도 보이지 않을 수 있습니다.'
      : prompt;
}

int? resolveItemManagerReloadSelectionIndex(
  List<ItemOfMarket> items, {
  int? selectedItemId,
  int? fallbackIndex,
}) {
  if (items.isEmpty) return null;
  if (selectedItemId != null) {
    final selectedIndex = items.indexWhere(
      (item) => item.item.itemId == selectedItemId,
    );
    if (selectedIndex >= 0) return selectedIndex;
  }
  if (fallbackIndex != null) return fallbackIndex.clamp(0, items.length - 1);
  return 0;
}

int? resolveItemManagerSavedSelectionItemId({
  required ItemManagerDraftRow? selectedRow,
  required Map<String, int> insertedItemIdsByDraftKey,
}) {
  final selectedDraftRowKey = selectedRow?.draftRowKey;
  if (selectedDraftRowKey != null) {
    final insertedItemId = insertedItemIdsByDraftKey[selectedDraftRowKey];
    if (insertedItemId != null) return insertedItemId;
  }
  final selectedSourceItemId = selectedRow?.sourceItemId;
  if (selectedSourceItemId != null) return selectedSourceItemId;
  return selectedRow == null && insertedItemIdsByDraftKey.length == 1
      ? insertedItemIdsByDraftKey.values.single
      : null;
}

enum ItemManagerElementPayloadFormat { empty, workbook, legacyRtf, unknown }

class ItemManagerImportViewState {
  const ItemManagerImportViewState({
    this.selectedItemId,
    this.selectedIndex,
    this.baselineChecksum,
    this.sortState = const [],
    this.filterState = const {},
  });

  final int? selectedItemId;
  final int? selectedIndex;
  final String? baselineChecksum;
  final List<Object?> sortState;
  final Map<String, Object?> filterState;

  Map<String, Object?> toJson() => {
    'selectedItemId': selectedItemId,
    'selectedIndex': selectedIndex,
    'baselineChecksum': baselineChecksum,
    'sortState': sortState,
    'filterState': filterState,
  };
}

class ItemManagerDraftValidationError extends StateError {
  ItemManagerDraftValidationError({
    required this.rowKey,
    required this.rowIndex,
    required this.columnId,
    required String message,
  }) : super(message);

  final String rowKey;
  final int rowIndex;
  final int? columnId;
}

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
class ItemManagerColumnValidationRule {
  const ItemManagerColumnValidationRule({
    required this.columnId,
    required this.columnName,
    required this.typeCode,
    required this.required,
    this.barcodeType,
    this.useBarcodeCheckDigit = false,
    this.useDateRange = false,
    this.dateRange = '',
    this.gs1Definition,
    this.timeBarcodeType = 0,
  });

  final int columnId;
  final String columnName;
  final int typeCode;
  final bool required;
  final BarcodeType? barcodeType;
  final bool useBarcodeCheckDigit;
  final bool useDateRange;
  final String dateRange;
  final Gs1AiDefinition? gs1Definition;
  final int timeBarcodeType;
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
  final List<ItemManagerDraftRow> _baselineRows;
  final TColumnContentScopedView scopedColumnContents;
  final List<ItemManagerColumnValidationRule> validationRules;
  final Set<int> _deletedSourceItemIds = {};
  final Map<int, ItemManagerDraftRow> _deletedRowsBySourceItemId = {};
  final Set<String> _selectedRowKeys = {};
  final DateTime Function() _now;
  int _draftSequence = 0;
  String? _anchorRowKey;
  int? _selectedColumnId;
  int _focusRequestId = 0;
  ItemManagerImportViewState? _importViewState;

  ItemManagerDraftController({
    required List<ItemManagerDraftRow> rows,
    required this.scopedColumnContents,
    this.validationRules = const [],
    this.requireElement = false,
    this.labelSizeName = '',
    DateTime Function()? now,
  }) : _rows = List.of(rows),
      _baselineRows = List.unmodifiable(rows),
       _now = now ?? DateTime.now {
    _validateRows(_rows);
  }

  factory ItemManagerDraftController.fromItems({
    required List<ItemOfMarket> items,
    required Map<int, ItemOfMarketRawSnapshot> rawSnapshots,
    required TColumnContentScopedView scopedColumnContents,
    List<ItemManagerColumnValidationRule> validationRules = const [],
    bool requireElement = false,
    String labelSizeName = '',
    DateTime Function()? now,
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
      validationRules: validationRules,
      requireElement: requireElement,
      labelSizeName: labelSizeName,
      now: now,
    );
  }

  List<ItemManagerDraftRow> get rows => List.unmodifiable(_rows);
  final bool requireElement;
  final String labelSizeName;
  Set<int> get deletedSourceItemIds => Set.unmodifiable(_deletedSourceItemIds);
  Map<int, ItemManagerDraftRow> get deletedRowsBySourceItemId =>
      Map.unmodifiable(_deletedRowsBySourceItemId);
  Set<String> get selectedRowKeys => Set.unmodifiable(_selectedRowKeys);
  String? get anchorRowKey => _anchorRowKey;
  int? get selectedColumnId => _selectedColumnId;
  int get focusRequestId => _focusRequestId;
  bool get isDirty =>
      _deletedSourceItemIds.isNotEmpty ||
      _rows.any((row) => row.rowState != ItemManagerDraftRowState.existing);
  bool get hasImportedRows =>
      _rows.any((row) => row.rowState == ItemManagerDraftRowState.imported);
  ItemManagerImportViewState? get importViewState => _importViewState;

  void discardChanges({int? selectedItemId}) {
    _rows
      ..clear()
      ..addAll(_baselineRows);
    _deletedSourceItemIds.clear();
    _deletedRowsBySourceItemId.clear();
    _importViewState = null;
    ItemManagerDraftRow? selectedRow;
    for (final row in _rows) {
      if (row.sourceItemId == selectedItemId) {
        selectedRow = row;
        break;
      }
    }
    final anchorRow = selectedRow ?? (_rows.isEmpty ? null : _rows.first);
    _selectedRowKeys
      ..clear()
      ..addAll(anchorRow == null ? const [] : [anchorRow.rowKey]);
    _anchorRowKey = anchorRow?.rowKey;
    _selectedColumnId = null;
    notifyListeners();
  }

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

  bool updateColumnValue(
    String rowKey, {
    required int columnId,
    required bool editable,
    required String dataString,
  }) {
    if (columnId <= 0) {
      throw ArgumentError.value(columnId, 'columnId', 'Must be positive.');
    }
    final rule = _validationRuleFor(columnId);
    final normalizedValue = _normalizeEditedColumnValue(rule, dataString);
    if (rule?.gs1Definition case final definition?) {
      if (normalizedValue.isNotEmpty && !definition.accepts(normalizedValue)) {
        return false;
      }
    }
    _updateRow(rowKey, (row) {
      final original = row.sourceItemId == null
          ? ''
          : scopedColumnContents.value(columnId, row.sourceItemId!);
      final drafts = Map<int, ItemManagerColumnDraft>.of(row.columnDrafts);
      if (!row.isNew && normalizedValue == original) {
        drafts.remove(columnId);
      } else {
        drafts[columnId] = ItemManagerColumnDraft(
          editable: editable,
          dataString: normalizedValue,
        );
      }
      _applyTenByEightDerivedValues(row, drafts, changedColumnId: columnId);
      _applyTimeBarcodeDerivedValues(row, drafts, changedColumnId: columnId);
      final changed = row.copyWith(columnDrafts: Map.unmodifiable(drafts));
      return _withCurrentState(changed);
    });
    return true;
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
      final row = _rows[emptyNameIndex];
      throw ItemManagerDraftValidationError(
        rowKey: row.rowKey,
        rowIndex: emptyNameIndex,
        columnId: ItemManagerFixedColumnIds.itemName,
        message: '${emptyNameIndex + 1}행의 품명을 입력해 주세요.',
      );
    }
    if (requireElement) {
      final emptyElementIndex = _rows.indexWhere(
        (row) => row.elementPlain.trim().isEmpty,
      );
      if (emptyElementIndex >= 0) {
        final row = _rows[emptyElementIndex];
        throw ItemManagerDraftValidationError(
          rowKey: row.rowKey,
          rowIndex: emptyElementIndex,
          columnId: ItemManagerFixedColumnIds.element,
          message: '${emptyElementIndex + 1}행의 주원료 값을 입력해 주세요.',
        );
      }
    }
    for (var rowIndex = 0; rowIndex < _rows.length; rowIndex += 1) {
      final row = _rows[rowIndex];
      for (final rule in validationRules) {
        final value = columnValue(row, rule.columnId).trim();
        if (rule.required && value.isEmpty) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName} 값을 입력해 주세요.',
          );
        }
        if (value.isNotEmpty &&
            rule.typeCode == TColumnType.TYPE_IMAGE &&
            _hasUnsupportedImageExtension(value)) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName}은 BMP 파일만 사용할 수 있습니다.',
          );
        }
        final barcodeType = rule.barcodeType;
        if (value.isNotEmpty &&
            barcodeType != null &&
            _requiresMeaningPreservingBarcodeValidation(rule) &&
            BarcodeDataHelper.normalizeMeaningPreservingForPrint(
                  barcodeType,
                  value,
                ) ==
                null) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName} 바코드 형식이 올바르지 않습니다.',
          );
        }
        if (value.isNotEmpty && !_isValidDateOrTimeValue(rule, value)) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName} 날짜/시간 형식 또는 범위가 올바르지 않습니다.',
          );
        }
        if (value.isNotEmpty && rule.timeBarcodeType > 0) {
          _validateTimeBarcodeSources(row, rowIndex, rule);
        }
        if (value.isNotEmpty &&
            rule.typeCode == TColumnType.TYPE_GS1_AI &&
            (rule.gs1Definition == null ||
                !rule.gs1Definition!.accepts(value))) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName} GS1 AI 형식이 올바르지 않습니다.',
          );
        }
        if (labelSizeName == '10*8' &&
            (rule.columnName == '현재수량' || rule.columnName == '총 수량') &&
            value.isNotEmpty &&
            int.tryParse(value) == null) {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 ${rule.columnName}은 정수로 입력해 주세요.',
          );
        }
        if (labelSizeName == '10*8' &&
            rule.columnName == '현재수량' &&
            value == '0') {
          throw _columnValidationError(
            row,
            rowIndex,
            rule,
            '${rowIndex + 1}행 현재수량은 0일 수 없습니다.',
          );
        }
      }
    }
  }

  ItemManagerDraftValidationError _columnValidationError(
    ItemManagerDraftRow row,
    int rowIndex,
    ItemManagerColumnValidationRule rule,
    String message,
  ) {
    return ItemManagerDraftValidationError(
      rowKey: row.rowKey,
      rowIndex: rowIndex,
      columnId: rule.columnId,
      message: message,
    );
  }

  void _applyTenByEightDerivedValues(
    ItemManagerDraftRow row,
    Map<int, ItemManagerColumnDraft> drafts, {
    required int changedColumnId,
  }) {
    if (labelSizeName != '10*8') return;
    final currentRule = _validationRuleNamed('현재수량');
    final totalRule = _validationRuleNamed('총 수량');
    final countRule = _validationRuleNamed('매수');
    final outputRule = _validationRuleNamed('발행수량');
    if (currentRule == null ||
        totalRule == null ||
        countRule == null ||
        outputRule == null ||
        (changedColumnId != currentRule.columnId &&
            changedColumnId != totalRule.columnId)) {
      return;
    }
    String value(ItemManagerColumnValidationRule rule) {
      final draft = drafts[rule.columnId];
      if (draft != null) return draft.dataString;
      final itemId = row.sourceItemId;
      return itemId == null
          ? ''
          : scopedColumnContents.value(rule.columnId, itemId);
    }

    final current = int.tryParse(value(currentRule));
    final total = int.tryParse(value(totalRule));
    if (current == null || current == 0 || total == null) return;
    final count = total ~/ current;
    _setDerivedDraft(row, drafts, countRule.columnId, '$count');
    _setDerivedDraft(row, drafts, outputRule.columnId, '1/$count');
  }

  void _applyTimeBarcodeDerivedValues(
    ItemManagerDraftRow row,
    Map<int, ItemManagerColumnDraft> drafts, {
    required int changedColumnId,
  }) {
    final changedRule = _validationRuleFor(changedColumnId);
    if (changedRule == null ||
        changedRule.typeCode != TColumnType.TYPE_BARCODE &&
            changedRule.typeCode != TColumnType.TYPE_VALIDDATE &&
            changedRule.typeCode != TColumnType.TYPE_VALIDTIME &&
            changedRule.typeCode != TColumnType.TYPE_MAKEDATE) {
      return;
    }
    final validDateRule = _validationRuleOfType(TColumnType.TYPE_VALIDDATE);
    final validTimeRule = _validationRuleOfType(TColumnType.TYPE_VALIDTIME);
    final makeDateRule = _validationRuleOfType(TColumnType.TYPE_MAKEDATE);

    String value(ItemManagerColumnValidationRule rule) {
      final draft = drafts[rule.columnId];
      if (draft != null) return draft.dataString;
      final itemId = row.sourceItemId;
      return itemId == null
          ? ''
          : scopedColumnContents.value(rule.columnId, itemId);
    }

    final offset = validDateRule == null
        ? null
        : int.tryParse(value(validDateRule).trim());
    if (offset == null) return;
    final current = _now();
    var baseDate = DateTime(current.year, current.month, current.day);
    if (makeDateRule != null) {
      final rawMakeDate = value(makeDateRule).trim();
      final makeDate = _parseMakeDate(rawMakeDate);
      if (makeDate == null && rawMakeDate.isNotEmpty) return;
      if (makeDate != null) baseDate = makeDate;
    }
    final validDate = baseDate.add(Duration(days: offset));

    for (final barcodeRule in validationRules.where(
      (rule) =>
          rule.typeCode == TColumnType.TYPE_BARCODE && rule.timeBarcodeType > 0,
    )) {
      if (changedRule.typeCode == TColumnType.TYPE_BARCODE &&
          changedColumnId != barcodeRule.columnId) {
        continue;
      }
      final suffix = _timeBarcodeSuffix(
        barcodeRule.timeBarcodeType,
        validDate,
        validTimeRule == null ? '' : value(validTimeRule).trim(),
      );
      if (suffix == null) continue;
      final barcode = value(barcodeRule);
      if (barcode.isEmpty) continue;
      final base = changedColumnId == barcodeRule.columnId
          ? barcode
          : barcode.length > suffix.length
          ? barcode.substring(0, barcode.length - suffix.length)
          : '';
      if (base.isEmpty) continue;
      _setDerivedDraft(row, drafts, barcodeRule.columnId, '$base$suffix');
    }
  }

  void _validateTimeBarcodeSources(
    ItemManagerDraftRow row,
    int rowIndex,
    ItemManagerColumnValidationRule barcodeRule,
  ) {
    final validDateRule = _validationRuleOfType(TColumnType.TYPE_VALIDDATE);
    if (validDateRule == null ||
        int.tryParse(columnValue(row, validDateRule.columnId).trim()) == null) {
      throw _columnValidationError(
        row,
        rowIndex,
        validDateRule ?? barcodeRule,
        '${rowIndex + 1}행 타임바코드 유통기한 값을 입력해 주세요.',
      );
    }
    if (barcodeRule.timeBarcodeType == 2 || barcodeRule.timeBarcodeType == 4) {
      final validTimeRule = _validationRuleOfType(TColumnType.TYPE_VALIDTIME);
      final validTime = validTimeRule == null
          ? ''
          : columnValue(row, validTimeRule.columnId).trim();
      if (validTimeRule == null ||
          !_isValidDateOrTimeValue(validTimeRule, validTime)) {
        throw _columnValidationError(
          row,
          rowIndex,
          validTimeRule ?? barcodeRule,
          '${rowIndex + 1}행 타임바코드 유통시한 값을 입력해 주세요.',
        );
      }
    }
  }

  ItemManagerColumnValidationRule? _validationRuleOfType(int typeCode) {
    for (final rule in validationRules) {
      if (rule.typeCode == typeCode) return rule;
    }
    return null;
  }

  ItemManagerColumnValidationRule? _validationRuleNamed(String name) {
    for (final rule in validationRules) {
      if (rule.columnName == name) return rule;
    }
    return null;
  }

  void _setDerivedDraft(
    ItemManagerDraftRow row,
    Map<int, ItemManagerColumnDraft> drafts,
    int columnId,
    String value,
  ) {
    final original = row.sourceItemId == null
        ? ''
        : scopedColumnContents.value(columnId, row.sourceItemId!);
    if (!row.isNew && value == original) {
      drafts.remove(columnId);
      return;
    }
    drafts[columnId] = ItemManagerColumnDraft(
      editable: true,
      dataString: value,
    );
  }

  ItemManagerColumnValidationRule? _validationRuleFor(int columnId) {
    for (final rule in validationRules) {
      if (rule.columnId == columnId) return rule;
    }
    return null;
  }

  void setSelection(
    Iterable<String> rowKeys, {
    String? anchorRowKey,
    int? columnId,
  }) {
    final validKeys = _rows.map((row) => row.rowKey).toSet();
    _selectedRowKeys
      ..clear()
      ..addAll(rowKeys.where(validKeys.contains));
    _anchorRowKey = anchorRowKey != null && validKeys.contains(anchorRowKey)
        ? anchorRowKey
        : (_selectedRowKeys.isEmpty ? null : _selectedRowKeys.last);
    _selectedColumnId = columnId;
    if (columnId != null) _focusRequestId += 1;
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
    {ItemManagerImportViewState? importViewState}
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
    _importViewState = importViewState;
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
      throw StateError('Draft row not found: $rowKey.');
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

String _normalizeEditedColumnValue(
  ItemManagerColumnValidationRule? rule,
  String value,
) {
  if (rule == null || !rule.useBarcodeCheckDigit || rule.barcodeType == null) {
    return value;
  }
  return BarcodeDataHelper.normalizeMeaningPreservingForPrint(
        rule.barcodeType!,
        value,
      ) ??
      value;
}

bool _requiresMeaningPreservingBarcodeValidation(
  ItemManagerColumnValidationRule rule,
) {
  return rule.barcodeType == BarcodeType.Itf || rule.useBarcodeCheckDigit;
}

bool _isValidDateOrTimeValue(
  ItemManagerColumnValidationRule rule,
  String value,
) {
  switch (rule.typeCode) {
    case TColumnType.TYPE_MAKEDATE:
      if (!RegExp(r'^\d{8}$').hasMatch(value)) return false;
      final year = int.parse(value.substring(0, 4));
      final month = int.parse(value.substring(4, 6));
      final day = int.parse(value.substring(6, 8));
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return false;
      }
      if (!rule.useDateRange) return true;
      final range = _parseDateRange(rule.dateRange);
      if (range == null) return false;
      final today = DateTime.now();
      final base = DateTime(today.year, today.month, today.day);
      return !parsed.isBefore(base.subtract(Duration(days: range.$1))) &&
          !parsed.isAfter(base.add(Duration(days: range.$2)));
    case TColumnType.TYPE_VALIDDATE:
      final offset = int.tryParse(value);
      if (offset == null) return false;
      if (!rule.useDateRange) return true;
      final range = _parseDateRange(rule.dateRange);
      return range != null && offset >= -range.$1 && offset <= range.$2;
    case TColumnType.TYPE_MAKETIME:
    case TColumnType.TYPE_VALIDTIME:
      if (!RegExp(r'^\d{4}$').hasMatch(value)) return false;
      final hour = int.parse(value.substring(0, 2));
      final minute = int.parse(value.substring(2, 4));
      return hour <= 23 && minute <= 59;
    default:
      return true;
  }
}

DateTime? _parseMakeDate(String value) {
  if (!RegExp(r'^\d{8}$').hasMatch(value)) return null;
  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(4, 6));
  final day = int.parse(value.substring(6, 8));
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day
      ? parsed
      : null;
}

String? _timeBarcodeSuffix(int type, DateTime validDate, String validTime) {
  final day = validDate.day.toString().padLeft(2, '0');
  final month = validDate.month.toString().padLeft(2, '0');
  final year = (validDate.year % 100).toString().padLeft(2, '0');
  return switch (type) {
    1 => '1$day$month',
    2 when RegExp(r'^\d{4}$').hasMatch(validTime) =>
      '2${validTime.substring(0, 2)}$day',
    4 when RegExp(r'^\d{4}$').hasMatch(validTime) =>
      '4$day${validTime.substring(0, 2)}',
    9 => '9$year$month$day',
    _ => null,
  };
}

(int, int)? _parseDateRange(String value) {
  final parts = value.split('|');
  if (parts.length != 2) return null;
  final before = int.tryParse(parts[0].trim());
  final after = int.tryParse(parts[1].trim());
  if (before == null || after == null || before < 0 || after < 0) return null;
  return (before, after);
}

bool _hasUnsupportedImageExtension(String value) {
  return RegExp(
    r'\.(?:png|jpe?g|gif|webp|svg|tiff?|ico)$',
    caseSensitive: false,
  ).hasMatch(value);
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
