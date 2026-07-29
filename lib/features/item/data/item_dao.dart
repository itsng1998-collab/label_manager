import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class ItemDAO extends DAO {
  static const String updateElementSheetSql = '''
    UPDATE BM_RICH_ITEM
      SET RICH_ELEMENT=@element,
          RICH_ELEMENT_SHEET=@elementSheet
    WHERE RICH_ITEM_ID=@itemId
  ''';

  static const String autoMigrateElementSheetSql = '''
    UPDATE BM_RICH_ITEM
      SET RICH_ELEMENT=@element,
          RICH_ELEMENT_SHEET=@elementSheet
    WHERE RICH_ITEM_ID=@itemId
      AND (RICH_ELEMENT_SHEET IS NULL OR RICH_ELEMENT_SHEET='')
  ''';

  static const String updateOrdersSql = r'''
    DECLARE @UpdatesDocument XML = CONVERT(XML, @updatesXml);
    DECLARE @OrderUpdates TABLE (
      ITEM_ID INT NOT NULL PRIMARY KEY,
      ITEM_ORDER INT NOT NULL
    );
    INSERT INTO @OrderUpdates(ITEM_ID, ITEM_ORDER)
    SELECT
      N.value('@itemId', 'INT'),
      N.value('@itemOrder', 'INT')
    FROM @UpdatesDocument.nodes('/updates/update') X(N);

    UPDATE I SET RICH_ITEM_ORDER=U.ITEM_ORDER
    FROM BM_RICH_ITEM I
    INNER JOIN @OrderUpdates U ON U.ITEM_ID=I.RICH_ITEM_ID;

    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @OrderUpdates)
      THROW 51002, 'Item order update count mismatch.', 1;
  ''';

  static const String updateSearchReplaceElementSql = '''
    UPDATE BM_RICH_ITEM
       SET RICH_ELEMENT=@element,
           RICH_ELEMENT_SHEET=@elementSheet
     WHERE RICH_ITEM_ID=@itemId;
    IF @@ROWCOUNT<>1
      THROW 51008, 'Search and replace item update count mismatch.', 1;
  ''';

  static List<DbTransactionStatement> searchReplaceElementStatements(
    List<ItemElementSearchReplaceUpdate> updates,
  ) => [
    for (final update in updates)
      DbTransactionStatement(
        sql: updateSearchReplaceElementSql,
        params: {
          'itemId': update.itemId,
          'element': update.element,
          'elementSheet': update.elementSheet,
        },
      ),
  ];

  static Future<void> updateSearchReplaceElements(
    List<ItemElementSearchReplaceUpdate> updates,
  ) async {
    if (updates.isEmpty) return;
    await DbClient.instance.transaction(
      searchReplaceElementStatements(updates),
    );
  }

  static Future<void> updateElementSheetByItemId(
    int itemId,
    String element,
    String elementSheet,
  ) async {
    debugLog(
      '$START, itemId:$itemId, elementLength:${element.length}, elementSheetLength:${elementSheet.length}',
    );
    try {
      final result = await DbClient.instance.writeDataWithParams(
        updateElementSheetSql,
        {'itemId': itemId, 'element': element, 'elementSheet': elementSheet},
      );
      final affected = DAO.affectedRows(result);
      if (affected <= 0) {
        throw Exception('${runtimeLogTag()} Update failed for itemId:$itemId');
      }
      debugLog('$END, BM_RICH_ITEM Result: $result, affected:$affected');
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<bool> autoMigrateElementSheetByItemId(
    int itemId,
    String element,
    String elementSheet,
  ) async {
    debugLog(
      '$START, itemId:$itemId, elementLength:${element.length}, elementSheetLength:${elementSheet.length}',
    );
    try {
      final result = await DbClient.instance.writeDataWithParams(
        autoMigrateElementSheetSql,
        {'itemId': itemId, 'element': element, 'elementSheet': elementSheet},
      );
      final affected = DAO.affectedRows(result);
      debugLog('$END, BM_RICH_ITEM Result: $result, affected:$affected');
      return affected > 0;
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> updateOrders(List<ItemOrderUpdate> updates) async {
    if (updates.isEmpty) return;
    final itemIds = updates.map((update) => update.itemId).toSet();
    final orders = updates.map((update) => update.order).toSet();
    if (itemIds.length != updates.length ||
        itemIds.any((itemId) => itemId <= 0) ||
        orders.length != updates.length ||
        orders.any((order) => order <= 0)) {
      throw ArgumentError(
        'Item order updates require unique positive item ids.',
      );
    }

    debugLog('$START, itemOrderCount:${updates.length}');
    try {
      await DbClient.instance.transaction([
        DbTransactionStatement(
          sql: updateOrdersSql,
          params: {
            'updatesXml':
                '<updates>${[for (final update in updates) '<update itemId="${update.itemId}" itemOrder="${update.order}" />'].join()}</updates>',
          },
        ),
      ]);
      debugLog('$END, itemOrderCount:${updates.length}');
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }
}
