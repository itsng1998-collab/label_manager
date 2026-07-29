import 'package:flutter/foundation.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/models/column.dart';

class SearchPrintSettingsDraft extends ChangeNotifier {
  SearchPrintSettingsDraft(List<TColumn> columns)
    : _original = List<TColumn>.unmodifiable(columns),
      _working = List<TColumn>.from(columns);

  List<TColumn> _original;
  List<TColumn> _working;

  List<TColumn> get columns => List<TColumn>.unmodifiable(_working);

  bool get isDirty {
    if (_original.length != _working.length) return true;
    for (var index = 0; index < _working.length; index += 1) {
      if (_original[index].columnId != _working[index].columnId ||
          _original[index].searchPrint != _working[index].searchPrint) {
        return true;
      }
    }
    return false;
  }

  void setSearchPrint(int columnId, bool value) {
    final index = _working.indexWhere((column) => column.columnId == columnId);
    if (index < 0 || _working[index].searchPrint == value) return;
    _working[index] = _working[index].copyWith(searchPrint: value);
    notifyListeners();
  }

  void setAll(bool value) {
    final changed = _working.any((column) => column.searchPrint != value);
    if (!changed) return;
    _working = [
      for (final column in _working)
        if (column.searchPrint == value)
          column
        else ...[
          column.copyWith(searchPrint: value),
        ],
    ];
    notifyListeners();
  }

  void replaceCommitted(List<TColumn> columns) {
    _original = List<TColumn>.unmodifiable(columns);
    _working = List<TColumn>.from(columns);
    notifyListeners();
  }
}

LabelColumnDialogSaveCommand buildSearchPrintSettingsSaveCommand({
  required int labelSizeId,
  required int customerId,
  required List<TColumn> originalColumns,
  required List<TColumn> workingColumns,
}) {
  final originalDrafts = [
    for (final column in originalColumns) LabelColumnDraft.fromColumn(column),
  ];
  final workingDrafts = [
    for (final column in workingColumns) LabelColumnDraft.fromColumn(column),
  ];
  if (originalDrafts.length != workingDrafts.length) {
    throw StateError('검색출력 설정 column snapshot이 일치하지 않습니다.');
  }
  final originalIds = originalDrafts.map((draft) => draft.column.columnId);
  final workingIds = workingDrafts.map((draft) => draft.column.columnId);
  if (!listEquals(originalIds.toList(), workingIds.toList())) {
    throw StateError('검색출력 설정 column 순서가 일치하지 않습니다.');
  }

  return LabelColumnDialogSaveCommand(
    labelSizeId: labelSizeId,
    customerId: customerId,
    labelColumns: LabelColumnSaveCommand(
      labelSizeId: labelSizeId,
      originalColumnsById: {
        for (final draft in originalDrafts) draft.column.columnId: draft,
      },
      newColumns: const [],
      updatedColumns: workingDrafts,
      changedKeysByColumnId: {
        for (final draft in workingDrafts)
          draft.column.columnId: Set<String>.unmodifiable(
            draft.persistedValues.keys,
          ),
      },
      deletedColumnIds: const {},
      orderedKeys: [for (final draft in workingDrafts) draft.key],
    ),
    customerColumns: null,
  );
}