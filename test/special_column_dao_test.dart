import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_column/data/special_column_dao.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';

void main() {
  test('special keyword order keeps the fixed item column contract', () {
    expect(SpecalKeyword.values.map((value) => value.keyword), [
      'ITEMNAME',
      'ELEMENT',
      'SWEIGHT',
      'SPRICE',
    ]);
  });

  test(
    'special column SQL keeps scoped checks and compatibility 100 syntax',
    () {
      final sql = [
        SpecialColumnDAO.selectCheckSql,
        SpecialColumnDAO.selectElementMinCheckSql,
        SpecialColumnDAO.updateElementMinColumnCheckSql,
      ].join('\n');

      expect(sql, contains('RICH_LABELSIZE_ID=@labelSizeId'));
      expect(sql, contains('RICH_KEYWORD=@keyword'));
      expect(sql, contains('MERGE BM_RICH_COL_MIN'));
      expect(sql, contains('WHEN MATCHED THEN'));
      expect(sql, contains('WHEN NOT MATCHED THEN'));
      expect(sql, isNot(contains('OPENJSON')));
      expect(sql, isNot(contains('TRY_CONVERT')));
      expect(sql, isNot(contains('STRING_SPLIT')));
    },
  );
}
