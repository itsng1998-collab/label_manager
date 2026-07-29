import 'package:label_manager/features/label_column/domain/label_column_candidates.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';

enum LabelColumnEditMode { normal, reorder, userItemEdit }

class LabelColumnDialogSaveCommand {
  const LabelColumnDialogSaveCommand({
    required this.labelSizeId,
    required this.customerId,
    required this.labelColumns,
    required this.customerColumns,
  });

  final int labelSizeId;
  final int customerId;
  final LabelColumnSaveCommand? labelColumns;
  final CustomerColumnSaveCommand? customerColumns;
}

class LabelColumnSaveCommittedException implements Exception {
  const LabelColumnSaveCommittedException(
    this.message, {
    this.outcomeUnknown = false,
  });

  final String message;
  final bool outcomeUnknown;

  @override
  String toString() => message;
}

abstract final class LabelColumnLimits {
  static const int keywordBytes = 100;
  static const int columnNameBytes = 50;
  static const int titleBytes = 20;

  static const Set<String> reservedKeywords = {
    'ITEMNAME',
    'ELEMENT',
    'SWEIGHT',
    'SPRICE',
  };

  static const Set<int> initialApplyRequiredTypeCodes = {
    TColumnType.TYPE_BARCODE,
    TColumnType.TYPE_IMAGE,
    TColumnType.TYPE_QR_CODE,
    TColumnType.TYPE_GS1_AI,
    TColumnType.TYPE_GS1_BARCODE,
  };
}

class LabelColumnDraft {
  const LabelColumnDraft({
    required this.key,
    required this.column,
    required this.isNew,
  });

  factory LabelColumnDraft.fromColumn(TColumn column) {
    return LabelColumnDraft(
      key: 'column:${column.columnId}',
      column: column,
      isNew: false,
    );
  }

  factory LabelColumnDraft.fromCandidate({
    required String draftKey,
    required int labelSizeId,
    required int order,
    required TColumnType columnType,
    required String keyword,
    required String columnName,
  }) {
    return LabelColumnDraft(
      key: draftKey,
      isNew: true,
      column: TColumn(
        columnType: columnType,
        keyword: keyword.trim().toUpperCase(),
        columnName: columnName.trim(),
        useMissingKeywordCheck: false,
        useMinColumnCheck: false,
        columnId: 0,
        labelSizeId: labelSizeId,
        order: order,
        width: 0,
        height: 0,
        barcodeType: BarcodeType.Code128,
        useBarcodeCheckDigit: true,
        showBarcodeNum: true,
        showQRCodeText: false,
        qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
        useUserDefineQRData: false,
        userDefineQRData: '',
        userDefineQRText: '',
        pixelSize: 0,
        title: '',
        visible: false,
        qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
        natriumJoinString: '',
        qrTextFontSize: 10,
        qrTextFontName: '',
        qrCodeScalePercent: 100,
        timeBarcodeType: 0,
        autoInc: false,
        autoIncSize: 0,
        autoIncSave: false,
        autoIncRange: 0,
        autoIncZeroDel: false,
        autoIncUpdate: false,
        searchPrint: false,
        userDefineBarcodeText: '',
        lineCheck: 0,
        lineSize: 0,
        gs1ai: '01',
        formatOption: -1,
        useGS1Code: false,
        containColumns: '',
        showGS1Code: false,
        rotate: 0,
        useDateRange: false,
        dateRange: '',
      ),
    );
  }

  final String key;
  final TColumn column;
  final bool isNew;

  LabelColumnDraft copyWith({TColumn? column}) {
    return LabelColumnDraft(
      key: key,
      column: column ?? this.column,
      isNew: isNew,
    );
  }

  bool hasSamePersistedValues(LabelColumnDraft other) {
    final left = persistedValues;
    final right = other.persistedValues;
    return left.length == right.length &&
        left.entries.every((entry) => right[entry.key] == entry.value);
  }

  Map<String, Object> get persistedValues => {
    'type': column.columnType.code,
    'keyword': column.keyword,
    'name': column.columnName,
    'check': column.useMissingKeywordCheck,
    'order': column.order,
    'width': column.width,
    'height': column.height,
    'barcodeType': column.barcodeType.dbName,
    'checkDigit': column.useBarcodeCheckDigit,
    'showBarcodeNum': column.showBarcodeNum,
    'showQRCodeText': column.showQRCodeText,
    'qrTextAlignment': column.qrTextAlignment.code,
    'useUserQrData': column.useUserDefineQRData,
    'userQrData': column.userDefineQRData,
    'userQrText': column.userDefineQRText,
    'pixelSize': column.pixelSize,
    'title': column.title,
    'visible': column.visible,
    'qrCreateType': column.qrCodeCreateType.code,
    'natrium': column.natriumJoinString,
    'qrTextSize': column.qrTextFontSize,
    'qrTextFont': column.qrTextFontName,
    'qrScale': column.qrCodeScalePercent,
    'timeBarcodeType': column.timeBarcodeType,
    'autoInc': column.autoInc,
    'autoIncSize': column.autoIncSize,
    'autoIncSave': column.autoIncSave,
    'autoIncRange': column.autoIncRange,
    'autoIncZeroDel': column.autoIncZeroDel,
    'autoIncUpdate': column.autoIncUpdate,
    'searchPrint': column.searchPrint,
    'barcodeText': column.userDefineBarcodeText,
    'lineCheck': column.lineCheck,
    'lineSize': column.lineSize,
    'gs1ai': column.gs1ai,
    'formatOption': column.formatOption,
    'useGs1': column.useGS1Code,
    'contains': column.containColumns,
    'showGs1': column.showGS1Code,
    'rotate': column.rotate,
    'useDateRange': column.useDateRange,
    'dateRange': column.dateRange,
  };
}

class LabelColumnValidationException implements Exception {
  const LabelColumnValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LabelColumnSaveCommand {
  const LabelColumnSaveCommand({
    required this.labelSizeId,
    required this.originalColumnsById,
    required this.newColumns,
    required this.updatedColumns,
    required this.changedKeysByColumnId,
    required this.deletedColumnIds,
    required this.orderedKeys,
  });

  final int labelSizeId;
  final Map<int, LabelColumnDraft> originalColumnsById;
  final List<LabelColumnDraft> newColumns;
  final List<LabelColumnDraft> updatedColumns;
  final Map<int, Set<String>> changedKeysByColumnId;
  final Set<int> deletedColumnIds;
  final List<String> orderedKeys;
}

class LabelColumnSaveResult {
  const LabelColumnSaveResult(this.columnIdsByDraftKey);

  final Map<String, int> columnIdsByDraftKey;
}

class LabelColumnEditSession {
  LabelColumnEditSession._({
    required this.labelSizeId,
    required this.originalColumns,
    required this.workingColumns,
    required this.deletedColumnIds,
    required this.pendingInitialApplyColumnKeys,
    required this.selectedColumnKey,
    required this.propertyBaseline,
    required this.propertyDraft,
    required this.mode,
    required this.reorderSnapshot,
  });

  factory LabelColumnEditSession.fromColumns({
    required int labelSizeId,
    required List<TColumn> columns,
  }) {
    if (labelSizeId <= 0) {
      throw ArgumentError.value(labelSizeId, 'labelSizeId');
    }
    final drafts = [for (final column in columns) LabelColumnDraft.fromColumn(column)];
    for (final draft in drafts) {
      if (draft.column.labelSizeId != labelSizeId) {
        throw ArgumentError('Column does not belong to label size $labelSizeId.');
      }
    }
    return LabelColumnEditSession._(
      labelSizeId: labelSizeId,
      originalColumns: List.unmodifiable(drafts),
      workingColumns: List.unmodifiable(drafts),
      deletedColumnIds: const {},
      pendingInitialApplyColumnKeys: const {},
      selectedColumnKey: drafts.isEmpty ? null : drafts.first.key,
      propertyBaseline: null,
      propertyDraft: null,
      mode: LabelColumnEditMode.normal,
      reorderSnapshot: const [],
    );
  }

  final int labelSizeId;
  final List<LabelColumnDraft> originalColumns;
  final List<LabelColumnDraft> workingColumns;
  final Set<int> deletedColumnIds;
  final Set<String> pendingInitialApplyColumnKeys;
  final String? selectedColumnKey;
  final LabelColumnDraft? propertyBaseline;
  final LabelColumnDraft? propertyDraft;
  final LabelColumnEditMode mode;
  final List<String> reorderSnapshot;

  bool get propertyDirty => propertyBaseline != null &&
      propertyDraft != null &&
      !propertyBaseline!.hasSamePersistedValues(propertyDraft!);

  bool get workingDirty {
    if (deletedColumnIds.isNotEmpty ||
        workingColumns.length != originalColumns.length) {
      return true;
    }
    final originals = {for (final row in originalColumns) row.key: row};
    return workingColumns.any((row) {
      final original = originals[row.key];
      return original == null || !original.hasSamePersistedValues(row);
    });
  }

  LabelColumnDraft? get selectedColumn => _byKey(selectedColumnKey);

  LabelColumnEditSession select(String key) {
    _requireNoPendingProperty();
    if (_byKey(key) == null) throw ArgumentError.value(key, 'key');
    return _copy(selectedColumnKey: key, clearProperty: true);
  }

  LabelColumnEditSession beginPropertyEdit() {
    final selected = selectedColumn;
    if (selected == null) return this;
    return _copy(propertyBaseline: selected, propertyDraft: selected);
  }

  LabelColumnEditSession updatePropertyDraft(LabelColumnDraft draft) {
    final baseline = propertyBaseline;
    if (baseline == null || draft.key != baseline.key) {
      throw StateError('Property editing has not started for ${draft.key}.');
    }
    return _copy(propertyDraft: draft);
  }

  LabelColumnEditSession applyProperty() {
    final draft = propertyDraft;
    if (draft == null) return this;
    validateDraft(draft, replacingKey: draft.key);
    final rows = [
      for (final row in workingColumns) row.key == draft.key ? draft : row,
    ];
    final pending = {...pendingInitialApplyColumnKeys}..remove(draft.key);
    return _copy(
      workingColumns: rows,
      pendingInitialApplyColumnKeys: pending,
      clearProperty: true,
    );
  }

  LabelColumnEditSession cancelProperty() {
    final baseline = propertyBaseline;
    if (baseline == null) return this;
    if (baseline.isNew && pendingInitialApplyColumnKeys.contains(baseline.key)) {
      return remove(baseline.key, allowPendingProperty: true);
    }
    return _copy(clearProperty: true);
  }

  LabelColumnEditSession add(LabelColumnDraft draft) {
    _requireNoPendingProperty();
    if (!draft.isNew || draft.column.labelSizeId != labelSizeId) {
      throw ArgumentError('Only a new draft for label size $labelSizeId can be added.');
    }
    if (_byKey(draft.key) != null) {
      throw ArgumentError('Duplicate draft key: ${draft.key}');
    }
    validateDraft(draft);
    final normalized = draft.copyWith(
      column: draft.column.copyWith(order: workingColumns.length + 1),
    );
    final pending = {...pendingInitialApplyColumnKeys};
    if (LabelColumnLimits.initialApplyRequiredTypeCodes.contains(
      normalized.column.columnType.code,
    )) {
      pending.add(normalized.key);
    }
    return _copy(
      workingColumns: [...workingColumns, normalized],
      pendingInitialApplyColumnKeys: pending,
      selectedColumnKey: normalized.key,
      propertyBaseline: normalized,
      propertyDraft: normalized,
    );
  }

  LabelColumnEditSession remove(
    String key, {
    bool allowPendingProperty = false,
  }) {
    if (!allowPendingProperty) _requireNoPendingProperty();
    final target = _byKey(key);
    if (target == null) return this;
    final rows = workingColumns.where((row) => row.key != key).toList();
    final normalized = _normalizeOrders(rows);
    final deleted = {...deletedColumnIds};
    if (!target.isNew) deleted.add(target.column.columnId);
    final pending = {...pendingInitialApplyColumnKeys}..remove(key);
    final nextSelection = normalized.isEmpty
        ? null
        : normalized[(workingColumns.indexOf(target)).clamp(0, normalized.length - 1)].key;
    return _copy(
      workingColumns: normalized,
      deletedColumnIds: deleted,
      pendingInitialApplyColumnKeys: pending,
      selectedColumnKey: nextSelection,
      clearProperty: true,
    );
  }

  LabelColumnEditSession enterReorder() {
    _requireNoPendingProperty();
    return _copy(
      mode: LabelColumnEditMode.reorder,
      reorderSnapshot: [for (final row in workingColumns) row.key],
    );
  }

  LabelColumnEditSession reorder(String key, int targetIndex) {
    if (mode != LabelColumnEditMode.reorder) {
      throw StateError('Reorder mode is not active.');
    }
    final rows = [...workingColumns];
    final sourceIndex = rows.indexWhere((row) => row.key == key);
    if (sourceIndex < 0) throw ArgumentError.value(key, 'key');
    final row = rows.removeAt(sourceIndex);
    rows.insert(targetIndex.clamp(0, rows.length), row);
    return _copy(
      workingColumns: _normalizeOrders(rows),
      selectedColumnKey: key,
    );
  }

  LabelColumnEditSession cancelReorder() {
    if (mode != LabelColumnEditMode.reorder) return this;
    final byKey = {for (final row in workingColumns) row.key: row};
    final restored = [for (final key in reorderSnapshot) if (byKey[key] != null) byKey[key]!];
    return _copy(
      workingColumns: _normalizeOrders(restored),
      mode: LabelColumnEditMode.normal,
      reorderSnapshot: const [],
    );
  }

  LabelColumnEditSession applyReorder() {
    if (mode != LabelColumnEditMode.reorder) return this;
    return _copy(
      workingColumns: _normalizeOrders(workingColumns),
      mode: LabelColumnEditMode.normal,
      reorderSnapshot: const [],
    );
  }

  LabelColumnEditSession enterUserItemEdit() {
    _requireNoPendingProperty();
    if (mode != LabelColumnEditMode.normal) {
      throw StateError('Another exclusive edit mode is already active.');
    }
    return _copy(mode: LabelColumnEditMode.userItemEdit);
  }

  LabelColumnEditSession exitUserItemEdit() {
    if (mode != LabelColumnEditMode.userItemEdit) return this;
    return _copy(mode: LabelColumnEditMode.normal);
  }

  void validateDraft(LabelColumnDraft draft, {String? replacingKey}) {
    final keyword = draft.column.keyword.trim();
    final name = draft.column.columnName.trim();
    if (keyword.isEmpty) {
      throw const LabelColumnValidationException('키워드를 입력하세요.');
    }
    if (name.isEmpty) {
      throw const LabelColumnValidationException('항목명을 입력하세요.');
    }
    final normalized = keyword.toUpperCase();
    final original = originalColumns.where((row) => row.key == draft.key).firstOrNull;
    final keywordChanged = original == null ||
        original.column.keyword.trim().toUpperCase() != normalized;
    if (keywordChanged && LabelColumnLimits.reservedKeywords.contains(normalized)) {
      throw LabelColumnValidationException('예약 키워드는 사용할 수 없습니다: $keyword');
    }
    if (keywordChanged &&
        workingColumns.any(
          (row) => row.key != replacingKey &&
              row.column.keyword.trim().toUpperCase() == normalized,
        )) {
      throw LabelColumnValidationException('중복 키워드입니다: $keyword');
    }
  }

  LabelColumnSaveCommand toSaveCommand() {
    _requireNoPendingProperty();
    if (pendingInitialApplyColumnKeys.isNotEmpty) {
      throw const LabelColumnValidationException('최초 적용하지 않은 항목이 있습니다.');
    }
    for (final row in workingColumns) {
      validateDraft(row, replacingKey: row.key);
      if (row.column.labelSizeId != labelSizeId) {
        throw const LabelColumnValidationException('다른 라벨 크기의 항목이 포함되어 있습니다.');
      }
    }
    final originals = {for (final row in originalColumns) row.key: row};
    final changedKeysByColumnId = <int, Set<String>>{};
    final updatedColumns = <LabelColumnDraft>[];
    for (final row in workingColumns.where((row) => !row.isNew)) {
      final original = originals[row.key];
      if (original == null) continue;
      final changedKeys = <String>{
        for (final entry in row.persistedValues.entries)
          if (original.persistedValues[entry.key] != entry.value) entry.key,
      };
      if (changedKeys.isEmpty) continue;
      updatedColumns.add(row);
      changedKeysByColumnId[row.column.columnId] = Set.unmodifiable(changedKeys);
    }
    return LabelColumnSaveCommand(
      labelSizeId: labelSizeId,
      originalColumnsById: Map.unmodifiable({
        for (final row in originalColumns) row.column.columnId: row,
      }),
      newColumns: List.unmodifiable(workingColumns.where((row) => row.isNew)),
      updatedColumns: List.unmodifiable(updatedColumns),
      changedKeysByColumnId: Map.unmodifiable(changedKeysByColumnId),
      deletedColumnIds: Set.unmodifiable(deletedColumnIds),
      orderedKeys: List.unmodifiable([for (final row in workingColumns) row.key]),
    );
  }

  LabelColumnDraft? _byKey(String? key) {
    if (key == null) return null;
    for (final row in workingColumns) {
      if (row.key == key) return row;
    }
    return null;
  }

  void _requireNoPendingProperty() {
    if (propertyDirty ||
        (propertyBaseline != null &&
            pendingInitialApplyColumnKeys.contains(propertyBaseline!.key))) {
      throw StateError('Apply or cancel the pending property edit first.');
    }
  }

  static List<LabelColumnDraft> _normalizeOrders(
    List<LabelColumnDraft> rows,
  ) {
    return [
      for (var index = 0; index < rows.length; index += 1)
        rows[index].copyWith(column: rows[index].column.copyWith(order: index + 1)),
    ];
  }

  LabelColumnEditSession _copy({
    List<LabelColumnDraft>? workingColumns,
    Set<int>? deletedColumnIds,
    Set<String>? pendingInitialApplyColumnKeys,
    String? selectedColumnKey,
    LabelColumnDraft? propertyBaseline,
    LabelColumnDraft? propertyDraft,
    LabelColumnEditMode? mode,
    List<String>? reorderSnapshot,
    bool clearProperty = false,
  }) {
    return LabelColumnEditSession._(
      labelSizeId: labelSizeId,
      originalColumns: originalColumns,
      workingColumns: List.unmodifiable(workingColumns ?? this.workingColumns),
      deletedColumnIds: Set.unmodifiable(deletedColumnIds ?? this.deletedColumnIds),
      pendingInitialApplyColumnKeys: Set.unmodifiable(
        pendingInitialApplyColumnKeys ?? this.pendingInitialApplyColumnKeys,
      ),
      selectedColumnKey: selectedColumnKey ?? this.selectedColumnKey,
      propertyBaseline: clearProperty
          ? null
          : propertyBaseline ?? this.propertyBaseline,
      propertyDraft: clearProperty ? null : propertyDraft ?? this.propertyDraft,
      mode: mode ?? this.mode,
      reorderSnapshot: List.unmodifiable(reorderSnapshot ?? this.reorderSnapshot),
    );
  }
}