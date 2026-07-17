// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class Item {
	final int itemId;
	final int labelSizeId;
	final String itemName;
	final String labelSizeName;
	final String element;
	final String elementRTF;
	final int price;
	final int order;

  const Item({
    required this.itemId,
    required this.labelSizeId,
    required this.itemName,
    required this.labelSizeName,
    required this.element,
    required this.elementRTF,
    required this.price,
    required this.order
  });

  Item copyWith({
    String? itemName,
    String? element,
    String? elementRTF,
    int? order,
  }) {
    return Item(
      itemId: itemId,
      labelSizeId: labelSizeId,
      itemName: itemName ?? this.itemName,
      labelSizeName: labelSizeName,
      element: element ?? this.element,
      elementRTF: elementRTF ?? this.elementRTF,
      price: price,
      order: order ?? this.order,
    );
  }

  @override
  String toString() =>
    'itemId: $itemId, labelSizeId: $labelSizeId, itemName: $itemName, labelSizeName: $labelSizeName, '
    'element: $element, elementRTF: $elementRTF, price: $price, order: $order';
}

class ItemOrderUpdate {
  final int itemId;
  final int order;

  const ItemOrderUpdate({required this.itemId, required this.order});
}

class ItemDAO extends DAO {
  static const String UpdateElementSheetSql = '''
    UPDATE BM_RICH_ITEM
      SET RICH_ELEMENT=@element,
          RICH_ELEMENT_SHEET=@elementSheet
    WHERE RICH_ITEM_ID=@itemId
  ''';

  static const String AutoMigrateElementSheetSql = '''
    UPDATE BM_RICH_ITEM
      SET RICH_ELEMENT=@element,
          RICH_ELEMENT_SHEET=@elementSheet
    WHERE RICH_ITEM_ID=@itemId
      AND (RICH_ELEMENT_SHEET IS NULL OR RICH_ELEMENT_SHEET='')
  ''';

  static const String UpdateOrdersSql = r'''
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

  static Future<void> updateElementSheetByItemId(
    int itemId,
    String element,
    String elementSheet,
  ) async {
    debugLog('$START, itemId:$itemId, elementLength:${element.length}, elementSheetLength:${elementSheet.length}');

    try {
      final res = await DbClient.instance.writeDataWithParams(
        UpdateElementSheetSql,
        {
          'itemId': itemId,
          'element': element,
          'elementSheet': elementSheet,
        },
      );
      final affected = DAO.affectedRows(res);
      if (affected <= 0) {
        throw Exception('${runtimeLogTag()} Update failed for itemId:$itemId');
      }
      debugLog('$END, BM_RICH_ITEM Result: $res, affected:$affected');
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<bool> autoMigrateElementSheetByItemId(
    int itemId,
    String element,
    String elementSheet,
  ) async {
    debugLog('$START, itemId:$itemId, elementLength:${element.length}, elementSheetLength:${elementSheet.length}');

    try {
      final res = await DbClient.instance.writeDataWithParams(
        AutoMigrateElementSheetSql,
        {
          'itemId': itemId,
          'element': element,
          'elementSheet': elementSheet,
        },
      );
      final affected = DAO.affectedRows(res);
      debugLog('$END, BM_RICH_ITEM Result: $res, affected:$affected');
      return affected > 0;
    } catch (e) {
      debugLog('$END, $e');
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
      throw ArgumentError('Item order updates require unique positive item ids.');
    }

    debugLog('$START, itemOrderCount:${updates.length}');
    try {
      await DbClient.instance.transaction([
        DbTransactionStatement(
          sql: UpdateOrdersSql,
          params: {
            'updatesXml': '<updates>${[
              for (final update in updates)
                '<update itemId="${update.itemId}" '
                    'itemOrder="${update.order}" />',
            ].join()}</updates>',
          },
        ),
      ]);
      debugLog('$END, itemOrderCount:${updates.length}');
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }
}
