import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/models/item_of_market.dart';

bool searchPrintModeBlocksTabSelection({
  required bool active,
  required Object? currentTab,
  required Object? requestedTab,
}) => active && currentTab != requestedTab;

ItemOfMarket? searchPrintFindBaselineItem(
  Iterable<ItemOfMarket> items,
  int itemId,
) {
  for (final item in items) {
    if (item.item.itemId == itemId) return item;
  }
  return null;
}

class SearchPrintResult {
  const SearchPrintResult({
    required this.brandId,
    required this.labelSizeId,
    required this.itemId,
  });

  final int brandId;
  final int labelSizeId;
  final int itemId;

  factory SearchPrintResult.fromMap(Map<String, dynamic> map) =>
      SearchPrintResult(
        brandId: int.parse(map['BRAND_ID'].toString()),
        labelSizeId: int.parse(map['LABELSIZE_ID'].toString()),
        itemId: int.parse(map['ITEM_ID'].toString()),
      );
}

class SearchPrintDAO extends DAO {
  static const String selectSql = '''
    SELECT
      C.RICH_BRAND_ID AS BRAND_ID,
      B.RICH_LABELSIZE_ID AS LABELSIZE_ID,
      A.RICH_ITEM_ID AS ITEM_ID
    FROM BM_RICH_COL_CONTENT A,
         BM_RICH_ITEM B,
         BM_RICH_BRAND C,
         BM_CUSTOMER D,
         BM_RICH_LABELSIZE_FORM E,
         BM_RICH_COLUMN F
    WHERE A.RICH_ITEM_ID=B.RICH_ITEM_ID
      AND C.RICH_CUSTOMER_ID=D.RICH_CUSTOMER_ID
      AND C.RICH_BRAND_ID=E.RICH_BRAND_ID
      AND B.RICH_LABELSIZE_ID=E.RICH_LABELSIZE_ID
      AND A.RICH_COLUMN_ID=F.RICH_COLUMN_ID
      AND B.RICH_LABELSIZE_ID=@labelSizeId
      AND (B.RICH_ITEM_NAME=@query
        OR (A.RICH_COL_CONTENT_DATA=@query AND F.RICH_SEARCH_PRINT=1))
    GROUP BY C.RICH_BRAND_ID, B.RICH_LABELSIZE_ID, A.RICH_ITEM_ID
  ''';

  static Future<SearchPrintResult?> selectFirst({
    required int labelSizeId,
    required String query,
  }) async {
    final result = await DbClient.instance.getDataWithParams(
      selectSql,
      {'labelSizeId': labelSizeId, 'query': query},
    );
    final row = DAO.getRowMapFromResult(result);
    return row == null ? null : SearchPrintResult.fromMap(row);
  }
}