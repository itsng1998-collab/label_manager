import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/update_item_column_content.dart';

void main() {
  group('[automatic item update column content]', () {
    test('maps update column content row', () {
      final value = UpdateItemColumnContent.fromMap({
        'UPDATE_COL_CONTENT_ID': '3',
        'COLUMN_ID': '7',
        'UPDATE_ITEM_ID': '10',
        'DATA_STRING': '값',
      });

      expect(value.updateColContentId, 3);
      expect(value.columnId, 7);
      expect(value.updateItemId, 10);
      expect(value.dataString, '값');
    });

    test('pending query SQL filters by label size and unapplied rows', () {
      expect(
        UpdateItemColumnContentDAO.selectPendingByLabelSizeIdSql,
        contains('U.RICH_LABELSIZE_ID=@labelSizeId'),
      );
      expect(
        UpdateItemColumnContentDAO.selectPendingByLabelSizeIdSql,
        contains('U.RICH_IS_APPLY=@isApply'),
      );
      expect(
        UpdateItemColumnContentDAO.selectPendingByLabelSizeIdSql,
        contains('ORDER BY U.RICH_UPDATE_ITEM_ORDER ASC'),
      );
    });
  });
}