import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

TColumnContent columnContentFromRow(Map<String, dynamic> row) {
  return TColumnContent(
    colContentId: row['RICH_COL_CONTENT_ID'],
    columnId: row['RICH_COLUMN_ID'],
    itemId: row['RICH_ITEM_ID'],
    editable: row['RICH_EDITABLE'] != 0,
    dataString: row['RICH_COL_CONTENT_DATA'],
  );
}

class TColumnContentDAO extends DAO {
  static const selectByItemIdsSql =
      '''
    DECLARE @ItemIdsXmlValue XML = @itemIdsXml;
    DECLARE @ScopedItemIds TABLE (
      RICH_ITEM_ID INT NOT NULL PRIMARY KEY
    );
    INSERT INTO @ScopedItemIds (RICH_ITEM_ID)
    SELECT ItemIdNode.value('.', 'INT')
    FROM @ItemIdsXmlValue.nodes('/items/id') AS ItemIds(ItemIdNode);

    SELECT
      P1.RICH_COL_CONTENT_ID AS RICH_COL_CONTENT_ID,
      P1.RICH_COLUMN_ID AS RICH_COLUMN_ID,
      P1.RICH_ITEM_ID AS RICH_ITEM_ID,
      P1.RICH_EDITABLE AS RICH_EDITABLE,
      COALESCE(CONVERT(NVARCHAR(3000), P1.RICH_COL_CONTENT_DATA COLLATE ${DAO.CP949}), N'') AS RICH_COL_CONTENT_DATA
    FROM BM_RICH_COL_CONTENT P1
    INNER JOIN @ScopedItemIds S ON P1.RICH_ITEM_ID=S.RICH_ITEM_ID
    INNER JOIN BM_RICH_ITEM P2 ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID
    INNER JOIN BM_RICH_COLUMN P3 ON P1.RICH_COLUMN_ID=P3.RICH_COLUMN_ID
    ORDER BY P2.RICH_ITEM_ORDER, P2.RICH_ITEM_ID,
      P3.RICH_COLUMN_ORDER, P3.RICH_COLUMN_ID ASC
    OPTION (RECOMPILE)
  ''';

  static Future<TColumnContentScopedView> selectScopedByItemIds(
    Iterable<int> itemIds,
  ) async {
    final normalizedIds = itemIds.where((id) => id > 0).toSet().toList()
      ..sort();
    if (normalizedIds.isEmpty) {
      return TColumnContentScopedView(const {});
    }

    debugLog('$START, scopedItemCount:${normalizedIds.length}');
    try {
      final result = await DbClient.instance.getDataWithParams(
        selectByItemIdsSql,
        {'itemIdsXml': itemIdsXml(normalizedIds)},
      );
      final values = DAO.mapRowsByKey(
        result,
        columnContentFromRow,
        (item) => ColumnItemKey(columnId: item.columnId, itemId: item.itemId),
      );
      debugLog(END);
      return TColumnContentScopedView(values);
    } catch (error) {
      debugLog('$END, $error');
      throw Exception(error);
    }
  }

  static String itemIdsXml(Iterable<int> itemIds) {
    final normalizedIds = itemIds.where((id) => id > 0).toSet().toList()
      ..sort();
    return '<items>${normalizedIds.map((id) => '<id>$id</id>').join()}</items>';
  }
}
