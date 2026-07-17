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
      expect(ItemDAO.UpdateOrdersSql, contains('CONVERT(XML, @updatesXml)'));
      expect(ItemDAO.UpdateOrdersSql, contains("nodes('/updates/update')"));
      expect(ItemDAO.UpdateOrdersSql, isNot(contains('OPENJSON')));
      expect(ItemDAO.UpdateOrdersSql, contains('IF @@ROWCOUNT <>'));
      expect(ItemDAO.UpdateOrdersSql, contains('THROW 51002'));
    });

    test('save command keeps nullable mapping defaults in escaped XML', () {
      final command = ItemManagerSaveCommand(
        targetMarketIds: const [9, 10],
        deletedSourceItemIds: const [3],
        newRows: const [
          ItemManagerNewRowSave(
            draftRowKey: 'draft-1',
            labelSizeId: 4,
            itemName: '신규 & 품목',
            elementPlain: '<원문>',
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
      final newRows = params['newRowsXml']! as String;
      expect(params.keys, [
        'targetMarketIdsXml',
        'deletedItemIdsXml',
        'existingRowsXml',
        'newRowsXml',
        'columnValuesXml',
      ]);
      expect(
        params['targetMarketIdsXml'],
        '<markets><market id="9" /><market id="10" /></markets>',
      );
      expect(newRows, contains('gdsNo="0"'));
      expect(newRows, contains('printCount="1"'));
      expect(newRows, contains('linefeed="100"'));
      expect(newRows, contains('<dateSaleStart></dateSaleStart>'));
      expect(newRows, contains('<dateSaleEnd></dateSaleEnd>'));
      expect(newRows, contains('<dateStartDiscount></dateStartDiscount>'));
      expect(newRows, contains('<dateEndDiscount></dateEndDiscount>'));
      expect(newRows, contains('<itemName>신규 &amp; 품목</itemName>'));
      expect(newRows, contains('<elementPlain>&lt;원문&gt;</elementPlain>'));
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

    test('save SQL maps inserted ids and physically deletes legacy rows', () {
      expect(ItemManagerSaveDAO.saveSql, contains('SET NOCOUNT ON'));
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
        contains('DELETE C\n    FROM BM_RICH_COL_CONTENT C'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('DELETE UC\n    FROM BM_UPDATE_COL_CONTENT UC'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('DELETE U\n    FROM BM_UPDATE_ITEM U'),
      );
      expect(
        ItemManagerSaveDAO.saveSql,
        contains('DELETE I\n    FROM BM_RICH_ITEM I'),
      );
      expect(ItemManagerSaveDAO.saveSql, contains('BM_RICH_STATUS S'));
      expect(ItemManagerSaveDAO.saveSql, contains('Deleted item count mismatch.'));
      final deleteContent = ItemManagerSaveDAO.saveSql.indexOf(
        'DELETE C\n    FROM BM_RICH_COL_CONTENT C',
      );
      final deleteMapping = ItemManagerSaveDAO.saveSql.indexOf(
        'DELETE M\n    FROM BM_ITEM_OF_MARKET M',
      );
      final deleteUpdateContent = ItemManagerSaveDAO.saveSql.indexOf(
        'DELETE UC\n    FROM BM_UPDATE_COL_CONTENT UC',
      );
      final deleteUpdateItem = ItemManagerSaveDAO.saveSql.indexOf(
        'DELETE U\n    FROM BM_UPDATE_ITEM U',
      );
      final deleteItem = ItemManagerSaveDAO.saveSql.indexOf(
        'DELETE I\n    FROM BM_RICH_ITEM I',
      );
      expect(
        [
          deleteContent,
          deleteMapping,
          deleteUpdateContent,
          deleteUpdateItem,
          deleteItem,
        ],
        orderedEquals(
          [
            deleteContent,
            deleteMapping,
            deleteUpdateContent,
            deleteUpdateItem,
            deleteItem,
          ]..sort(),
        ),
      );
      expect(ItemManagerSaveDAO.saveSql, contains('MERGE BM_RICH_COL_CONTENT'));
      expect(
        ItemManagerSaveDAO.saveSql,
        contains("@ColumnValuesDocument.nodes('/values/value')"),
      );
      expect(ItemManagerSaveDAO.saveSql, isNot(contains('OPENJSON')));
      expect(ItemManagerSaveDAO.saveSql, isNot(contains('JSON_VALUE')));
      expect(ItemManagerSaveDAO.saveSql, isNot(contains('TRY_CONVERT')));
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
