import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/data/user_dao.dart';

void main() {
  test('client users are read-only while other grades can edit', () {
    for (final grade in UserGrade.values) {
      final user = User(
        userId: 'user',
        marketId: 1,
        name: '사용자',
        pwd: '',
        grade: grade,
        marketName: '매장',
        customerName: '고객',
      );

      final legacyEditable = grade != UserGrade.CLIENT_USER;
      expect(user.canEditItemDetails, legacyEditable);
      expect(user.canManageItemStructure, legacyEditable);
      expect(user.canAccessCommonLabelManagement, legacyEditable);
      expect(user.canEdit, legacyEditable);
    }
  });

  test('users keep the database grade', () {
    final user = userFromRow(const {
      'USER_ID': 'tester02',
      'MARKET_ID': 1,
      'NAME': '테스트 사용자',
      'PASSWORD': '',
      'GRADE': 0,
      'MARKET_NAME': '매장',
      'CUSTOMER_NAME': '고객',
    });

    expect(user.grade, UserGrade.SYSTEM_ADMIN_USER);
    expect(user.canEdit, isTrue);
  });
}