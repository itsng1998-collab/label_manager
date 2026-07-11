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

  Item copyWith({String? element, String? elementRTF}) {
    return Item(
      itemId: itemId,
      labelSizeId: labelSizeId,
      itemName: itemName,
      labelSizeName: labelSizeName,
      element: element ?? this.element,
      elementRTF: elementRTF ?? this.elementRTF,
      price: price,
      order: order,
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

  static const String UpdateOrderSql = '''
    UPDATE BM_RICH_ITEM
      SET RICH_ITEM_ORDER=@order
    WHERE RICH_ITEM_ID=@itemId
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
    if (itemIds.length != updates.length || itemIds.contains(0)) {
      throw ArgumentError('Item order updates require unique positive item ids.');
    }

    debugLog('$START, itemOrderCount:${updates.length}');
    try {
      final results = await DbClient.instance.transaction(
        updates
            .map(
              (update) => DbTransactionStatement(
                sql: UpdateOrderSql,
                params: {'itemId': update.itemId, 'order': update.order},
              ),
            )
            .toList(growable: false),
      );
      if (results.length != updates.length ||
          results.any((result) => DAO.affectedRows(result) != 1)) {
        throw Exception('${runtimeLogTag()} Item order update affected mismatch');
      }
      debugLog('$END, itemOrderCount:${updates.length}');
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }
}
