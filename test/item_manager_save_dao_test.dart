import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_save.dart';

void main() {
  group('[transaction/DAO]', () {
    test('item order update validates identities before DB access', () async {
      await expectLater(
        ItemDAO.updateOrders(const [
          ItemOrderUpdate(itemId: 1, order: 1),
          ItemOrderUpdate(itemId: 1, order: 2),
        ]),
        throwsArgumentError,
      );
      await expectLater(
        ItemDAO.updateOrders(const [ItemOrderUpdate(itemId: 0, order: 1)]),
        throwsArgumentError,
      );
      await expectLater(
        ItemDAO.updateOrders(const [
          ItemOrderUpdate(itemId: 1, order: 1),
          ItemOrderUpdate(itemId: 2, order: 1),
        ]),
        throwsArgumentError,
      );
      expect(ItemDAO.UpdateOrdersSql, contains('OPENJSON(@updatesJson)'));
      expect(ItemDAO.UpdateOrdersSql, contains('IF @@ROWCOUNT <>'));
      expect(ItemDAO.UpdateOrdersSql, contains('THROW 51002'));
    });

    test('save command keeps nullable mapping defaults in JSON', () {
      final command = ItemManagerSaveCommand(
        targetMarketIds: const [9, 10],
        deletedSourceItemIds: const [3],
        newRows: const [
          ItemManagerNewRowSave(
            draftRowKey: 'draft-1',
            labelSizeId: 4,
            itemName: '신규 품목',
            elementPlain: '',
            elementSheet: '{}',
            order: 1,
          ),
        ],
        columnValues: const [
          ItemManagerColumnValueSave(
            draftRowKey: 'draft-1',
            columnId: 7,
            dataString: '00123',
          ),
        ],
      );

      final params = command.toSqlParams();
      final rows = jsonDecode(params['newRowsJson']! as String) as List;
      final row = rows.single as Map<String, dynamic>;
      expect(row['dateSaleStart'], isNull);
      expect(row['dateSaleEnd'], isNull);
      expect(row['dateStartDiscount'], isNull);
      expect(row['dateEndDiscount'], isNull);
      expect(row['gdsNo'], 0);
      expect(row['printCount'], 1);
      expect(row['linefeed'], 100);
      expect(jsonDecode(params['targetMarketIdsJson']! as String), [9, 10]);
    });

    test('save command validates row identities before DB access', () {
      expect(
        () => const ItemManagerSaveCommand(
          targetMarketIds: [],
          newRows: [
            ItemManagerNewRowSave(
              draftRowKey: 'draft-1',
              labelSizeId: 4,
              itemName: '신규',
              elementPlain: '',
              elementSheet: '{}',
              order: 1,
            ),
          ],
        ).toSqlParams(),
        throwsArgumentError,
      );
      expect(
        () => const ItemManagerSaveCommand(
          targetMarketIds: [1],
          columnValues: [
            ItemManagerColumnValueSave(
              sourceItemId: 2,
              draftRowKey: 'draft-1',
              columnId: 3,
              dataString: '',
            ),
          ],
        ).toSqlParams(),
        throwsArgumentError,
      );
    });

    test('save SQL maps inserted ids and deletes only market mappings', () {
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('OUTPUT INSERTED.RICH_ITEM_ID INTO @CapturedItem'),
      );
      expect(ItemManagerSaveDAO.saveSql, contains('WHILE @RowNo <= @RowCount'));
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('INSERT INTO BM_ITEM_OF_MARKET'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains(
          'SELECT M.MARKET_ID, I.ITEM_ID, NULL,\n'
          '      N.GDS_NO, N.SALE_START_DATE, N.SALE_END_DATE,',
        ),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('N.DISCOUNT_START_DATE, N.DISCOUNT_END_DATE,'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('DELETE M\n    FROM BM_ITEM_OF_MARKET M'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        isNot(contains('DELETE FROM BM_RICH_ITEM')),
      );
      expect(ItemManagerSaveDAO.saveSql, contains('MERGE BM_RICH_COL_CONTENT'));
      expect(ItemManagerSaveDAO.saveSql, contains(r"'$.draftRowKey'"));
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('Inserted item id mapping count mismatch.'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('Inserted item id mapping key mismatch.'),
      );
      expect(ItemManagerSaveDAO.saveSql, contains('EXCEPT'));
    });
  });
}
