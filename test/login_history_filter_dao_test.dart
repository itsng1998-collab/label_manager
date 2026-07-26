import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';

void main() {
  test('login history selector queries keep DAO return order', () {
    expect(CooperatorDAO.SelectSql, isNot(contains('ORDER BY')));
    expect(CustomerDAO.SelectSql, isNot(contains('ORDER BY')));
    expect(CustomerDAO.WhereSqlCooperatorId, contains('@cooperatorId'));
  });
}