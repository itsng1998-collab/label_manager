import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_column/data/special_column_dao.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';

void main() {
  test('SQL BIT false를 특별항목 체크 해제로 복원한다', () {
    expect(specialColumnCheckValue(false), isFalse);
    expect(specialColumnCheckValue(true), isTrue);
    expect(specialColumnCheckValue(0), isFalse);
    expect(specialColumnCheckValue(1), isTrue);
    expect(specialColumnCheckValue('0'), isFalse);
    expect(specialColumnCheckValue('1'), isTrue);
  });

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
