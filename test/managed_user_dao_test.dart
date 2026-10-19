import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/features/managed_user/data/managed_user_dao.dart';

void main() {
  for (final asJson in [false, true]) {
    Object result(List<Map<String, dynamic>> rows) {
      final value = <String, dynamic>{
        'columns': ['USER_ID', 'MARKET_ID', 'NAME', 'PASSWORD', 'GRADE'],
        'rows': rows,
        'affected': 0,
      };
      return asJson ? jsonEncode(value) : value;
    }

    test('managed user lookup accepts missing ID (json=$asJson)', () {
      final empty = result([]);

      expect(managedUserFromLookupResult(empty), isNull);
      expect(() => DAO.getRowMapFromResult(empty), throwsStateError);
    });

    test('managed user lookup maps existing ID (json=$asJson)', () {
      final user = managedUserFromLookupResult(result([
        {
          'USER_ID': 'existing',
          'MARKET_ID': '528',
          'NAME': 'Existing user',
          'PASSWORD': 'test-password',
          'GRADE': UserGrade.MANAGER_USER.code,
          'MARKET_NAME': 'Market',
          'CUSTOMER_NAME': 'Customer',
        },
      ]))!;

      expect(user.userId, 'existing');
      expect(user.marketId, 528);
      expect(user.name, 'Existing user');
      expect(user.password, 'test-password');
      expect(user.grade, UserGrade.MANAGER_USER);
      expect(user.marketName, 'Market');
      expect(user.customerName, 'Customer');
    });
  }

  test('managed user lookup does not mask invalid database responses', () {
    expect(() => managedUserFromLookupResult('invalid json'),
        throwsFormatException);
    expect(() => managedUserFromLookupResult(1), throwsArgumentError);
  });
}
