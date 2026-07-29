import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';

void main() {
  test('login history selector queries keep DAO return order', () {
    expect(CooperatorDAO.selectSql, isNot(contains('ORDER BY')));
    expect(CustomerDAO.selectSql, isNot(contains('ORDER BY')));
    expect(CustomerDAO.whereSqlCooperatorId, contains('@cooperatorId'));
  });
}