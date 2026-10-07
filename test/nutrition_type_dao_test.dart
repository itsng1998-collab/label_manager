import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/nutrition/data/nutrition_type_dao.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_type.dart';

void main() {
  const columns = [
    NutritionTypeColumn(id: 0, keyword: 'N01', name: '열량 & 에너지'),
    NutritionTypeColumn(id: 0, keyword: 'N03', name: ''),
  ];

  test('insert captures generated parent id without MAX lookup', () {
    final statement = NutritionTypeDAO.insertStatement('기본형', columns);
    expect(statement.sql, contains('OUTPUT INSERTED.RICH_NUTTYPE_ID'));
    expect(statement.sql, isNot(contains('MAX(')));
    expect(statement.sql, contains("@Details.nodes('/columns/column')"));
    expect(statement.params['detailsXml'], contains('name="열량 &amp; 에너지"'));
    expect(statement.params['detailsXml'], contains('keyword="N03" name=""'));
  });

  test('update replaces detail after parent update in one statement', () {
    final statement = NutritionTypeDAO.updateStatement(7, '수정형', columns);
    final update = statement.sql.indexOf('UPDATE BM_RICH_NUTTYPE');
    final delete = statement.sql.indexOf('DELETE FROM BM_RICH_NUTCOLUMN');
    final insert = statement.sql.indexOf('INSERT INTO BM_RICH_NUTCOLUMN');
    expect(update, lessThan(delete));
    expect(delete, lessThan(insert));
    expect(statement.params['typeId'], 7);
  });

  test('delete follows nutbox column type order', () {
    final sql = NutritionTypeDAO.deleteStatement(9).sql;
    final boxes = sql.indexOf('DELETE FROM BM_RICH_NUTBOX');
    final columns = sql.indexOf('DELETE FROM BM_RICH_NUTCOLUMN');
    final type = sql.indexOf('DELETE FROM BM_RICH_NUTTYPE');
    expect(boxes, lessThan(columns));
    expect(columns, lessThan(type));
    expect(sql, contains('IF @@ROWCOUNT<>1'));
  });

  test('delete suppresses empty child rowcounts and returns explicit result', () {
    final statement = NutritionTypeDAO.deleteStatement(16);
    final sql = statement.sql;
    expect(sql.trimLeft(), startsWith('SET NOCOUNT ON;'));
    expect(sql.trimRight(), endsWith('SELECT 1 AS DELETED_COUNT;'));
    expect(statement.params, {'typeId': 16});
    expect(sql, contains('IF @@ROWCOUNT<>1'));
    expect(sql, contains("THROW 51011, 'Nutrition type delete count mismatch.', 1;"));
    expect(
      sql.indexOf('SELECT 1 AS DELETED_COUNT;'),
      greaterThan(sql.indexOf('THROW 51011')),
    );
    for (final unsupported in [
      'OPENJSON',
      'JSON_VALUE',
      'TRY_CONVERT',
      'STRING_SPLIT',
      'STRING_AGG',
      'ALTER TABLE',
    ]) {
      expect(sql.toUpperCase(), isNot(contains(unsupported)));
    }
  });

  test('manager list stays unordered while templates and details use id order', () {
    expect(NutritionTypeDAO.selectTypesSql, isNot(contains('ORDER BY')));
    expect(
      NutritionTypeDAO.selectTypesByIdSql,
      contains('ORDER BY RICH_NUTTYPE_ID'),
    );
    expect(
      NutritionTypeDAO.selectColumnsSql,
      contains('ORDER BY RICH_NUTCOL_ID'),
    );
  });
}