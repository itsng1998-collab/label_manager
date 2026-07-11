import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/user.dart';

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
}