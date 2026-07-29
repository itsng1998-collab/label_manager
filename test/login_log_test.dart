import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login_history/data/login_log_dao.dart';
import 'package:label_manager/features/login_history/domain/login_log.dart';

void main() {
  test('LoginLog decodes the stored grade label without numeric coercion', () {
    final row = loginLogFromRow({
      'LOG_ID': '7',
      'USER_ID': 'user01',
      'USER_GRADE': '책임자',
      'PROGRAM_VERSION': '1.0.0',
      'CUSTOMER_ID': '3',
      'CUSTOMER_NAME': '거래처',
      'LOGIN_DATE': '2025-01-02 03:04:05',
      'LOGIN_DATE_YYYYMMDD': '20250102',
      'LOGIN_IP': '192.168.0.2',
      'LOGIN_CONDITION': '0',
    });

    expect(row.userGrade, '책임자');
    expect(row.loginCondition, LoginCondition.LOGIN);
  });

  test('history SQL keeps the legacy date, customer, and order contract', () {
    final sql = LoginLogDAO.betweenDatesAndCustomerSql;

    expect(sql, contains('LOGIN_DATE_YYYYMMDD BETWEEN @startDate AND @endDate'));
    expect(sql, contains('CUST_ID=@customerId'));
    expect(sql, contains('ORDER BY LOGIN_DATE ASC'));
    expect(sql, isNot(contains('OPENJSON')));
    expect(sql, isNot(contains('TRY_CONVERT')));
  });
}