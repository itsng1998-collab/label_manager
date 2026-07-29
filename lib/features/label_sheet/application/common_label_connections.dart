import 'package:label_manager/features/label_sheet/domain/label_sheet_required_keyword.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_type.dart';

List<String> commonLabelBarcodeObjectIdsFor(
  List<TColumnBase> specialColumns,
  List<TColumn> columns,
) {
  return commonLabelBarcodeObjectIdsFromColumns([
    ...specialColumns,
    ...columns,
  ]);
}

List<String> commonLabelBarcodeObjectIdsFromColumns(
  Iterable<TColumnBase> columns,
) {
  final result = <String>[];
  final seen = <String>{};
  for (final column in columns) {
    final typeCode = column.columnType.code;
    if (typeCode != TColumnType.TYPE_BARCODE &&
        typeCode != TColumnType.TYPE_QR_CODE &&
        typeCode != TColumnType.TYPE_GS1_BARCODE) {
      continue;
    }
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) continue;
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (seen.add(objectId.toLowerCase())) {
      result.add(objectId);
    }
  }
  return result.isEmpty ? const ['#BARCODE'] : result;
}

List<String> commonLabelImageObjectIdsFor(
  List<TColumnBase> specialColumns,
  List<TColumn> columns,
) {
  return commonLabelImageObjectIdsFromColumns([...specialColumns, ...columns]);
}

List<String> commonLabelImageObjectIdsFromColumns(
  Iterable<TColumnBase> columns,
) {
  final result = <String>[];
  final seen = <String>{};
  for (final column in columns) {
    if (column.columnType.code != TColumnType.TYPE_IMAGE) continue;
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) {
      continue;
    }
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (seen.add(objectId.toLowerCase())) {
      result.add(objectId);
    }
  }
  return result;
}

List<LabelSheetRequiredKeyword> commonLabelRequiredKeywordsFor(
  List<TColumnBase> specialColumns,
  List<TColumn> columns,
) {
  return commonLabelRequiredKeywordsFromColumns([
    ...specialColumns,
    ...columns,
  ]);
}

List<LabelSheetRequiredKeyword> commonLabelRequiredKeywordsFromColumns(
  Iterable<TColumnBase> columns,
) {
  final result = <LabelSheetRequiredKeyword>[];
  final seen = <String>{};
  for (final column in columns) {
    if (!column.useMissingKeywordCheck) {
      continue;
    }
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) {
      continue;
    }
    if (seen.add(keyword.toLowerCase())) {
      result.add(
        LabelSheetRequiredKeyword(
          keyword: keyword,
          itemName: column.columnName.trim().isEmpty
              ? keyword
              : column.columnName.trim(),
        ),
      );
    }
  }
  return result;
}
