import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/nutrition_type.dart';

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