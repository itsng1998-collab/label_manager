import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/automatic_item_update/data/update_item.dart';
import 'package:label_manager/features/automatic_item_update/domain/update_item.dart';

void main() {
  group('[automatic item update dao]', () {
    test('maps apply date and isApply without fallback', () {
      final item = UpdateItem.fromMap({
        'UPDATE_ITEM_ID': '10',
        'ITEM_ID': '20',
        'ITEM_NAME': '품목',
        'LABEL_SIZE_ID': '4',
        'ELEMENT': '주원료',
        'ELEMENT_RTF': r'{\rtf1 element}',
        'PRICE': '1000',
        'APPLY_DATE': '20260725',
        'IS_APPLY': '0',
      });

      expect(item.updateItemId, 10);
      expect(item.itemId, 20);
      expect(item.applyDate, DateTime(2026, 7, 25));
      expect(item.isApply, isFalse);
    });

    test('invalid apply date throws instead of using DateTime.now fallback', () {
      expect(
        () => UpdateItem.fromMap({
          'UPDATE_ITEM_ID': '10',
          'ITEM_ID': '20',
          'ITEM_NAME': '품목',
          'LABEL_SIZE_ID': '4',
          'ELEMENT': '주원료',
          'ELEMENT_RTF': r'{\rtf1 element}',
          'PRICE': '1000',
          'APPLY_DATE': 'invalid',
          'IS_APPLY': '1',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('pending query SQL filters by label size and unapplied rows', () {
      expect(UpdateItemDAO.SelectPendingByLabelSizeIdSql, contains('P1.RICH_LABELSIZE_ID=@labelSizeId'));
      expect(UpdateItemDAO.SelectPendingByLabelSizeIdSql, contains('P1.RICH_IS_APPLY=@isApply'));
      expect(
        UpdateItemDAO.SelectPendingByLabelSizeIdSql,
        contains('ORDER BY P1.RICH_UPDATE_ITEM_ID ASC'),
      );
      expect(
        UpdateItemDAO.SelectPendingByLabelSizeIdSql,
        isNot(contains('RICH_UPDATE_ITEM_ORDER')),
      );
      expect(UpdateItemDAO.pendingByLabelSizeParams(4), {
        'labelSizeId': 4,
        'isApply': 0,
      });
    });

    test('apply date parser accepts yyyyMMdd only', () {
      expect(parseUpdateItemApplyDate('20260725'), DateTime(2026, 7, 25));
      expect(parseUpdateItemApplyDate('2026-07-25'), isNull);
      expect(parseUpdateItemApplyDate('20260230'), isNull);
    });
  });
}