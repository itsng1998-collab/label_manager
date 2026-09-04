import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login/data/user_access_dao.dart';

void main() {
  test('사용자 PC 접속 저장 SQL은 서버 시각 토큰과 이력을 함께 저장한다', () {
    expect(UserAccessDAO.saveSql, contains('BM_USER_ACCESS'));
    expect(UserAccessDAO.saveSql, contains('BM_USER_ACCESS_LOG'));
    expect(UserAccessDAO.saveSql, contains('CONVERT(CHAR(8), GETDATE(), 112)'));
    expect(UserAccessDAO.saveSql, contains('SET NOCOUNT ON'));
    expect(UserAccessDAO.saveSql, isNot(contains('FORMAT(')));
    expect(UserAccessDAO.saveSql, isNot(contains('ACCESS_DATE')));
    expect(UserAccessDAO.saveSql, isNot(contains('ACCESS_DATETIME')));
    expect(
      UserAccessDAO.saveSql,
      contains('INSERT INTO BM_USER_ACCESS_LOG\n    SELECT USER_ID'),
    );
  });
}