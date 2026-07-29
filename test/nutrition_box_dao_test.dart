import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/nutrition/data/nutrition_box_dao.dart';

void main() {
  test('manager query joins type and keeps legacy type id order', () {
    expect(NutritionBoxDAO.selectSql, contains('INNER JOIN BM_RICH_NUTTYPE'));
    expect(NutritionBoxDAO.selectSql, contains('ORDER BY T.RICH_NUTTYPE_ID'));
    expect(NutritionBoxDAO.selectSql, isNot(contains('RICH_NUTBOX_ID ASC')));
  });

  test('insert stores only four active fields including empty RTF', () {
    final statement = NutritionBoxDAO.insertStatement(
      typeId: 3,
      name: '기본 표',
      rtf: '',
      width: -1,
    );
    expect(statement.params, {
      'typeId': 3,
      'name': '기본 표',
      'rtf': '',
      'width': -1,
    });
    expect(statement.sql, contains('RICH_NUTBOX_TYPE'));
    expect(statement.sql, contains('RICH_NUTBOX_NAME'));
    expect(statement.sql, contains('RICH_NUTBOX_DATA'));
    expect(statement.sql, contains('RICH_NUTBOX_WIDTH'));
  });

  test('update and delete target exactly one selected box', () {
    final update = NutritionBoxDAO.updateStatement(
      boxId: 9,
      typeId: 3,
      name: '수정 표',
      rtf: r'{\rtf1 test}',
      width: 120,
    );
    expect(update.params['boxId'], 9);
    expect(update.sql, contains('IF @@ROWCOUNT<>1'));
    final delete = NutritionBoxDAO.deleteStatement(9);
    expect(delete.params, {'boxId': 9});
    expect(delete.sql, isNot(contains('BM_RICH_NUTCOLUMN')));
    expect(delete.sql, isNot(contains('BM_RICH_NUTTYPE')));
  });
}