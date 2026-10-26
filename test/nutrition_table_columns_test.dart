import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_column/data/label_column_save.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';
import 'package:label_manager/features/nutrition/application/nutrition_table_columns.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_type.dart';

const nutritionType = TColumnType(
  code: TColumnType.TYPE_NUT,
  name: '영양성분',
  order: 8,
);
const baseType = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 0);

TColumn existingColumn(String keyword) => LabelColumnDraft.fromCandidate(
  draftKey: 'existing',
  labelSizeId: 10,
  order: 1,
  columnType: baseType,
  keyword: keyword,
  columnName: '기존 항목',
).column.copyWith(columnId: 1);

void main() {
  setUp(() {
    final types = TColumnType.datas;
    addTearDown(() => TColumnType.datas = types);
    TColumnType.datas = [baseType, nutritionType];
  });

  final nutritionColumns = [
    for (var index = 1; index <= 17; index++)
      NutritionTypeColumn(
        id: index,
        keyword: 'N${index.toString().padLeft(2, '0')}',
        name: '성분 $index',
      ),
  ];

  test('selected nutrition type registers all 17 definitions in order', () {
    final command = nutritionTableColumnSaveCommand(
      labelSizeId: 10,
      columns: [],
      nutritionColumns: nutritionColumns,
    );
    expect(command.newColumns, hasLength(17));
    expect(
      command.newColumns.map((row) => row.column.keyword),
      nutritionColumns.map((row) => row.keyword),
    );
    expect(
      command.newColumns.map((row) => row.column.columnName),
      nutritionColumns.map((row) => row.name),
    );
    expect(
      command.newColumns.every(
        (row) =>
            row.column.columnType.code == TColumnType.TYPE_NUT &&
            row.column.labelSizeId == 10 &&
            !row.column.useMissingKeywordCheck,
      ),
      isTrue,
    );
    expect(
      command.newColumns.map((row) => row.column.order),
      List.generate(17, (index) => index + 1),
    );
    expect(command.updatedColumns, isEmpty);
    expect(command.deletedColumnIds, isEmpty);

    final statement = LabelColumnSaveDao.buildSaveStatement(
      command,
      const LabelColumnSchemaCapabilities(
        hasCoreSchema: true,
        hasMainMissingKeywordCheck: true,
        hasContentEditable: true,
        hasUpdateContent: true,
        hasStatusData: false,
      ),
    );
    expect(statement.sql, contains('INSERT BM_RICH_COL_CONTENT'));
    expect(statement.sql, contains('INSERT BM_UPDATE_COL_CONTENT'));
    expect(statement.sql, contains("THROW 51115,"));
    expect(statement.sql, contains('OUTPUT INSERTED.RICH_COLUMN_ID'));
    expect(statement.params['commandXml'], contains('<keyword>N17</keyword>'));
  });

  test(
    'registering nutrition does not persist unrelated local check or image drafts',
    () {
      final loaded = existingColumn('IMAGE').copyWith(
        columnType: const TColumnType(
          code: TColumnType.TYPE_IMAGE,
          name: '이미지',
          order: 4,
        ),
        width: 30,
        height: 20,
        persistedWidth: 30,
        persistedHeight: 20,
        persistedMainMissingKeywordCheck: true,
      );
      final local = loaded.copyWith(width: 31, height: 22);
      local.useMissingKeywordCheck = true;
      final command = nutritionTableColumnSaveCommand(
        labelSizeId: 10,
        columns: [local],
        nutritionColumns: nutritionColumns,
      );
      expect(command.updatedColumns, isEmpty);
      expect(command.changedKeysByColumnId, isEmpty);
      expect(command.originalColumnsById[1]!.column.width, 30);
      expect(command.originalColumnsById[1]!.column.height, 20);
      expect(
        command.originalColumnsById[1]!.column.useMissingKeywordCheck,
        isFalse,
      );
      expect(
        command.originalColumnsById[1]!.column.persistedMainMissingKeywordCheck,
        isTrue,
      );
      expect(command.newColumns.first.column.order, 2);
      expect(local.width, 31);
      expect(local.height, 22);
      expect(local.useMissingKeywordCheck, isTrue);
    },
  );

  test('existing or repeated keywords reject the entire insertion', () {
    for (final column in [existingColumn('N01'), existingColumn('n17')]) {
      expect(
        () => nutritionTableColumnSaveCommand(
          labelSizeId: 10,
          columns: [column],
          nutritionColumns: nutritionColumns,
        ),
        throwsA(isA<LabelColumnValidationException>()),
      );
    }
    expect(
      () => nutritionTableColumnSaveCommand(
        labelSizeId: 10,
        columns: [],
        nutritionColumns: [nutritionColumns.first, nutritionColumns.first],
      ),
      throwsA(isA<LabelColumnValidationException>()),
    );
  });

  test('empty definitions and missing nutrition type explicitly fail', () {
    expect(
      () => nutritionTableColumnSaveCommand(
        labelSizeId: 10,
        columns: [],
        nutritionColumns: [],
      ),
      throwsStateError,
    );
    TColumnType.datas = [baseType];
    expect(
      () => nutritionTableColumnSaveCommand(
        labelSizeId: 10,
        columns: [],
        nutritionColumns: nutritionColumns,
      ),
      throwsStateError,
    );
  });
}
