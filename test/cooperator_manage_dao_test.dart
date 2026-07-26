import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/models/cooperator.dart';

void main() {
  test('system password keeps startup calculation', () {
    expect(systemPasswordForDate(DateTime(2025, 2, 14)), '0020');
    expect(systemPasswordForDate(DateTime(2025, 12, 31)), '0067');
  });

  test('cooperator CRUD uses only verified columns and parameterized SQL', () {
    expect(CooperatorDAO.InsertSql, contains('RICH_COOP_ID, RICH_NAME'));
    expect(CooperatorDAO.InsertSql, contains('@cooperatorId'));
    expect(CooperatorDAO.InsertSql, contains('@name'));
    expect(CooperatorDAO.InsertSql, isNot(contains('RICH_COOP_GRADE')));

    expect(CooperatorDAO.UpdateSql, contains('RICH_COOP_ID=@cooperatorId'));
    expect(CooperatorDAO.UpdateSql, contains('RICH_NAME=@name'));
    expect(CooperatorDAO.UpdateSql, contains('RICH_COOP_ID=@oldCooperatorId'));

    expect(CooperatorDAO.DeleteSql, contains('DELETE FROM BM_COOPERATOR'));
    expect(CooperatorDAO.DeleteSql, contains('RICH_COOP_ID=@cooperatorId'));
    expect(CooperatorDAO.DeleteSql, isNot(contains('BM_CUSTOMER')));
  });

  test('cooperator list keeps legacy database order', () {
    expect(CooperatorDAO.SelectSql, isNot(contains('ORDER BY')));
  });
}