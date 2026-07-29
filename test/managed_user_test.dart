import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/managed_user/data/managed_user_dao.dart';
import 'package:label_manager/features/managed_user/domain/managed_user.dart';
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
      expect(ManagedUserDAO.whereMarketSql, contains('RICH_USER_GRADE<>0'));
      expect(ManagedUserDAO.whereMarketSql, isNot(contains('ORDER BY')));
      expect(
        ManagedUserDAO.whereCooperatorSql,
        contains('ORDER BY P3.RICH_CUSTOMER_ID, P2.RICH_MARKET_ID'),
      );
    },
  );

  test(
    'managed CRUD stores only legacy fields without credential conversion',
    () {
      expect(ManagedUserDAO.insertSql, contains('RICH_PWD'));
      expect(ManagedUserDAO.insertSql, contains('RICH_USER_GRADE'));
      expect(ManagedUserDAO.updateSql, contains('@originalUserId'));
      expect(ManagedUserDAO.deleteSql, contains('DELETE FROM BM_USER'));
      expect(ManagedUserDAO.insertSql, isNot(contains('HASH')));
    },
  );
}
