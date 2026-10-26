import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_type.dart';

LabelColumnSaveCommand nutritionTableColumnSaveCommand({
  required int labelSizeId,
  required List<TColumn> columns,
  required List<NutritionTypeColumn> nutritionColumns,
}) {
  if (nutritionColumns.isEmpty) {
    throw StateError('선택한 영양성분 형식에 등록된 키워드가 없습니다.');
  }
  final type = TColumnType.getFromCode(TColumnType.TYPE_NUT);
  if (type.code != TColumnType.TYPE_NUT) {
    throw StateError('영양성분 항목 종류를 찾을 수 없습니다.');
  }
  final originals = LabelColumnEditSession.fromColumns(
    labelSizeId: labelSizeId,
    columns: columns,
  ).toSaveCommand().originalColumnsById.values;
  var session = LabelColumnEditSession.fromColumns(
    labelSizeId: labelSizeId,
    columns: [for (final original in originals) original.column],
  );
  for (var index = 0; index < nutritionColumns.length; index++) {
    final column = nutritionColumns[index];
    session = session
        .add(
          LabelColumnDraft.fromCandidate(
            draftKey: 'nutrition:$index',
            labelSizeId: labelSizeId,
            order: session.workingColumns.length + 1,
            columnType: type,
            keyword: column.keyword,
            columnName: column.name,
          ),
        )
        .applyProperty();
  }
  return session.toSaveCommand();
}
