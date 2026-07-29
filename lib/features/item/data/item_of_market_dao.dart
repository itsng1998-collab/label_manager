import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

ItemOfMarket itemOfMarketFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();
  int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
  double doubleValue(String key) => double.tryParse(stringValue(key)) ?? 0;
  DateTime dateValue(String key) =>
      DateTime.tryParse(stringValue(key)) ?? DateTime.now();

  return ItemOfMarket(
    marketId: intValue('P1_MARKET_ID'),
    item: Item(
      itemId: intValue('P2_ITEM_ID'),
      labelSizeId: intValue('P2_LABELSIZE_ID'),
      itemName: stringValue('P2_ITEM_NAME'),
      labelSizeName: stringValue('P4_LABELSIZE_NAME'),
      element: stringValue('P2_ELEMENT'),
      elementRTF: stringValue('P2_ELEMENT_RTF'),
      price: intValue('P2_PRICE'),
      order: intValue('P2_PRICE_ORDER'),
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: intValue('P3_ADDITIONAL_ITEM_ID'),
      itemId: intValue('P3_ITEM_ID'),
      element: stringValue('P3_ELEMENT'),
      elementRTF: stringValue('P3_ELEMENT_RTF'),
      price: intValue('P3_PRICE'),
    ),
    gdsNo: intValue('P1_GDS_NO'),
    dateSaleStart: dateValue('P1_SALE_START_DATE'),
    dateSaleEnd: dateValue('P1_SALE_END_DATE'),
    discountPercent: doubleValue('P1_DISCOUNT_PERCENT'),
    discountAmount: intValue('P1_DISCOUNT_AMOUNT'),
    dateStartDiscount: dateValue('P1_DISCOUNT_START_DATE'),
    dateEndDiscount: dateValue('P1_DISCOUNT_END_DATE'),
    useDefineElement: intValue('P1_USE_USER_DEFINE_ELEMENT') != 0,
    rtfText: stringValue('P1_USER_DEFINE_ELEMENT_RTF'),
    useLinefeed: intValue('P1_USE_LINEFEED') != 0,
    linefeed: intValue('P1_LINEFEED'),
    useScaleBarcode: intValue('P1_USE_SCALEBARCODE') != 0,
    printCount: intValue('P1_PRINT_COUNT'),
    useLabelSize: intValue('P1_USE_LABELSIZE') != 0,
    labelSizeWidth: intValue('P1_LABEL_SIZE_WIDTH'),
    labelSizeHeight: intValue('P1_LABEL_SIZE_HEIGHT'),
    useMargin: intValue('P1_USE_MARGIN') != 0,
    leftMargin: doubleValue('P1_LEFT_MARGIN'),
    rightMargin: doubleValue('P1_RIGHT_MARGIN'),
    topMargin: doubleValue('P1_TOP_MARGIN'),
    leftPush: doubleValue('P1_LEFT_PUSH'),
    topPush: doubleValue('P1_TOP_PUSH'),
  );
}

class ItemOfMarketDAO extends DAO {
  static const String updateItemInfoSql = '''
    UPDATE BM_ITEM_OF_MARKET
       SET RICH_USE_LINEFEED=@useLinefeed, RICH_LINEFEED=@linefeed,
           RICH_USE_SCALEBARCODE=@useScaleBarcode, RICH_PRINT_COUNT=@printCount,
           RICH_USE_LABELSIZE=@useLabelSize, RICH_LABELSIZE_WIDTH=@labelSizeWidth,
           RICH_LABELSIZE_HEIGHT=@labelSizeHeight, RICH_USE_MARGIN=@useMargin,
           RICH_LEFT_MARGIN=@leftMargin, RICH_RIGHT_MARGIN=@rightMargin,
           RICH_TOP_MARGIN=@topMargin, RICH_LEFT_PUSH=@leftPush,
           RICH_TOP_PUSH=@topPush
     WHERE RICH_MARKET_ID=@marketId AND RICH_ITEM_ID=@itemId;
    IF @@ROWCOUNT<>1
      THROW 51009, 'Item info update count mismatch.', 1;
  ''';

  static List<DbTransactionStatement> itemInfoUpdateStatements(
    List<ItemOfMarket> items,
  ) => [
    for (final item in items)
      DbTransactionStatement(
        sql: updateItemInfoSql,
        params: {
          'marketId': item.marketId,
          'itemId': item.item.itemId,
          'useLinefeed': item.useLinefeed ? 1 : 0,
          'linefeed': item.linefeed,
          'useScaleBarcode': item.useScaleBarcode ? 1 : 0,
          'printCount': item.printCount,
          'useLabelSize': item.useLabelSize ? 1 : 0,
          'labelSizeWidth': item.labelSizeWidth,
          'labelSizeHeight': item.labelSizeHeight,
          'useMargin': item.useMargin ? 1 : 0,
          'leftMargin': item.leftMargin,
          'rightMargin': item.rightMargin,
          'topMargin': item.topMargin,
          'leftPush': item.leftPush,
          'topPush': item.topPush,
        },
      ),
  ];

  static Future<void> updateItemInfoBatch(List<ItemOfMarket> items) async {
    if (items.isEmpty) return;
    await DbClient.instance.transaction(itemInfoUpdateStatements(items));
  }

  static const String selectSql =
      '''
    SELECT COALESCE(CONVERT(NVARCHAR(20), P1.RICH_MARKET_ID), N'') AS P1_MARKET_ID,
      COALESCE(CONVERT(NVARCHAR(20), P2.RICH_ITEM_ID), N'') AS P2_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(50), P2.RICH_LABELSIZE_ID), N'') AS P2_LABELSIZE_ID,
      COALESCE(CONVERT(NVARCHAR(100), P2.RICH_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS P2_ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(50), P4.RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS P4_LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(MAX), P2.RICH_ELEMENT COLLATE ${DAO.CP949}), N'') AS P2_ELEMENT,
      COALESCE(CONVERT(NVARCHAR(MAX), NULLIF(P2.RICH_ELEMENT_SHEET, '') COLLATE ${DAO.CP949}), CONVERT(NVARCHAR(MAX), P2.RICH_ELEMENT_RTF COLLATE ${DAO.CP949}), N'') AS P2_ELEMENT_RTF,
      COALESCE(CONVERT(NVARCHAR(20), P2.RICH_PRICE), N'') AS P2_PRICE,
      COALESCE(CONVERT(NVARCHAR(20), P2.RICH_ITEM_ORDER), N'') AS P2_PRICE_ORDER,
      COALESCE(CONVERT(NVARCHAR(20), P3.RICH_ADDITIONAL_ITEM_ID), N'') AS P3_ADDITIONAL_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(20), P3.RICH_ITEM_ID), N'') AS P3_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(MAX), P3.RICH_ELEMENT COLLATE ${DAO.CP949}), N'') AS P3_ELEMENT,
      COALESCE(CONVERT(NVARCHAR(MAX), P3.RICH_ELEMENT_RTF COLLATE ${DAO.CP949}), N'') AS P3_ELEMENT_RTF,
      COALESCE(CONVERT(NVARCHAR(20), P3.RICH_PRICE), N'') AS P3_PRICE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_GDS_NO), N'') AS P1_GDS_NO,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_SALE_START_DATE, 112), N'') AS P1_SALE_START_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_SALE_END_DATE, 112), N'') AS P1_SALE_END_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_DISCOUNT_PERCENT), N'') AS P1_DISCOUNT_PERCENT,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_DISCOUNT_AMOUNT), N'') AS P1_DISCOUNT_AMOUNT,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_DISCOUNT_START_DATE, 112), N'') AS P1_DISCOUNT_START_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_DISCOUNT_END_DATE, 112), N'') AS P1_DISCOUNT_END_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USE_USER_DEFINE_ELEMENT), N'') AS P1_USE_USER_DEFINE_ELEMENT,
      COALESCE(CONVERT(NVARCHAR(MAX), P1.RICH_USER_DEFINE_ELEMENT_RTF COLLATE ${DAO.CP949}), N'') AS P1_USER_DEFINE_ELEMENT_RTF,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USE_LINEFEED), N'') AS P1_USE_LINEFEED,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LINEFEED), N'') AS P1_LINEFEED,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USE_SCALEBARCODE), N'') AS P1_USE_SCALEBARCODE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_PRINT_COUNT), N'') AS P1_PRINT_COUNT,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USE_LABELSIZE), N'') AS P1_USE_LABELSIZE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LABELSIZE_WIDTH), N'') AS P1_LABEL_SIZE_WIDTH,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LABELSIZE_HEIGHT), N'') AS P1_LABEL_SIZE_HEIGHT,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USE_MARGIN), N'') AS P1_USE_MARGIN,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LEFT_MARGIN), N'') AS P1_LEFT_MARGIN,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_RIGHT_MARGIN), N'') AS P1_RIGHT_MARGIN,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_TOP_MARGIN), N'') AS P1_TOP_MARGIN,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LEFT_PUSH), N'') AS P1_LEFT_PUSH,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_TOP_PUSH), N'') AS P1_TOP_PUSH
    FROM BM_ITEM_OF_MARKET P1 INNER JOIN BM_RICH_ITEM P2 ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID
    LEFT OUTER JOIN BM_ADDITIONAL_ITEM P3 ON P1.RICH_ADDITIONAL_ITEM_ID=P3.RICH_ADDITIONAL_ITEM_ID
    INNER JOIN BM_RICH_LABELSIZE_FORM P4 ON P2.RICH_LABELSIZE_ID=P4.RICH_LABELSIZE_ID
  ''';
  static const String whereSqlMarketAndLabelSizeId =
      'WHERE P1.RICH_MARKET_ID=@marketId AND P2.RICH_LABELSIZE_ID=@labelSizeId';
  static const String orderByItemOrder =
      'ORDER BY P2.RICH_ITEM_ORDER, P2.RICH_ITEM_ID ASC';

  static Future<List<ItemOfMarket>?> selectByItemOfMarketAndLabelSizeId(
    int marketId,
    int labelSizeId,
  ) async {
    debugLog('$START, ItemOfMarketAndLabelSizeId:$marketId,$labelSizeId');
    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlMarketAndLabelSizeId $orderByItemOrder',
        {'marketId': marketId, 'labelSizeId': labelSizeId},
      );
      final items = DAO.mapRows(result, itemOfMarketFromRow);
      debugLog(END);
      return items;
    } catch (error) {
      debugLog('$END, $error');
      throw Exception(error);
    }
  }
}
