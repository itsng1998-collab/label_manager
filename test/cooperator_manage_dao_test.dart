import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';

void main() {
  test('cooperator row mapper normalizes string values', () {
    final mapped = cooperatorFromRow({
      'COOP_ID': 10,
      'NAME': null,
    });

    expect(mapped.id, '10');
    expect(mapped.name, isEmpty);
  });

  test('system password keeps startup calculation', () {
    expect(systemPasswordForDate(DateTime(2025, 2, 14)), '0020');
    expect(systemPasswordForDate(DateTime(2025, 12, 31)), '0067');
  });

  test('cooperator CRUD uses only verified columns and parameterized SQL', () {
    expect(CooperatorDAO.insertSql, contains('RICH_COOP_ID, RICH_NAME'));
    expect(CooperatorDAO.insertSql, contains('@cooperatorId'));
    expect(CooperatorDAO.insertSql, contains('@name'));
    expect(CooperatorDAO.insertSql, isNot(contains('RICH_COOP_GRADE')));

    expect(CooperatorDAO.updateSql, contains('RICH_COOP_ID=@cooperatorId'));
    expect(CooperatorDAO.updateSql, contains('RICH_NAME=@name'));
    expect(CooperatorDAO.updateSql, contains('RICH_COOP_ID=@oldCooperatorId'));

    expect(CooperatorDAO.deleteSql, contains('DELETE FROM BM_COOPERATOR'));
    expect(CooperatorDAO.deleteSql, contains('RICH_COOP_ID=@cooperatorId'));
    expect(CooperatorDAO.deleteSql, isNot(contains('BM_CUSTOMER')));
  });

  test('cooperator list keeps legacy database order', () {
    expect(CooperatorDAO.selectSql, isNot(contains('ORDER BY')));
  });
}