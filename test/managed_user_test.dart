import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/managed_user.dart';
import 'package:label_manager/models/user.dart';

void main() {
  test('managed row preserves database grade and plain password', () {
    final row = ManagedUser.fromMap({
      'USER_ID': 'manager',
      'MARKET_ID': 10,
      'NAME': '테스터',
      'PASSWORD': 'plain',
      'GRADE': UserGrade.MANAGER_USER.code,
      'MARKET_NAME': '지점',
      'CUSTOMER_NAME': '거래처',
    });

    expect(row.grade, UserGrade.MANAGER_USER);
    expect(row.password, 'plain');
  });

  test(
    'managed queries exclude system admin and only coop view is ordered',
    () {
      expect(ManagedUserDAO.WhereMarketSql, contains('RICH_USER_GRADE<>0'));
      expect(ManagedUserDAO.WhereMarketSql, isNot(contains('ORDER BY')));
      expect(
        ManagedUserDAO.WhereCooperatorSql,
        contains('ORDER BY P3.RICH_CUSTOMER_ID, P2.RICH_MARKET_ID'),
      );
    },
  );

  test(
    'managed CRUD stores only legacy fields without credential conversion',
    () {
      expect(ManagedUserDAO.InsertSql, contains('RICH_PWD'));
      expect(ManagedUserDAO.InsertSql, contains('RICH_USER_GRADE'));
      expect(ManagedUserDAO.UpdateSql, contains('@originalUserId'));
      expect(ManagedUserDAO.DeleteSql, contains('DELETE FROM BM_USER'));
      expect(ManagedUserDAO.InsertSql, isNot(contains('HASH')));
    },
  );
}
