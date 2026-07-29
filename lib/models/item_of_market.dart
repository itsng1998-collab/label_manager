// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class ItemOfMarket {
  static List<ItemOfMarket>? datas;

  final int marketId;
  final Item item;
  final AdditionalItem additionalItem;
  final int gdsNo; // 호출번호
  final DateTime dateSaleStart;
  final DateTime dateSaleEnd;
  final double discountPercent;
  final int discountAmount;
  final DateTime dateStartDiscount;
  final DateTime dateEndDiscount;
  final bool useDefineElement; // 사용자 지정
  final String rtfText;
  final bool useLinefeed;
  final int linefeed;
  final bool useScaleBarcode;
  final int printCount;
  final bool useLabelSize;
  final int labelSizeWidth;
  final int labelSizeHeight;
  final bool useMargin;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;

  const ItemOfMarket({
    required this.marketId,
    required this.item,
    required this.additionalItem,
    required this.gdsNo,
    required this.dateSaleStart,
    required this.dateSaleEnd,
    required this.discountPercent,
    required this.discountAmount,
    required this.dateStartDiscount,
    required this.dateEndDiscount,
    required this.useDefineElement,
    required this.rtfText,
    required this.useLinefeed,
    required this.linefeed,
    required this.useScaleBarcode,
    required this.printCount,
    required this.useLabelSize,
    required this.labelSizeWidth,
    required this.labelSizeHeight,
    required this.useMargin,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.leftPush,
    required this.topPush,
  });

  static void setDatas(List<ItemOfMarket>? values) {
    datas = values;
  }

  ItemOfMarket copyWith({
    Item? item,
    bool? useLinefeed,
    int? linefeed,
    bool? useScaleBarcode,
    int? printCount,
    bool? useLabelSize,
    int? labelSizeWidth,
    int? labelSizeHeight,
    bool? useMargin,
    double? leftMargin,
    double? rightMargin,
    double? topMargin,
    double? leftPush,
    double? topPush,
  }) {
    return ItemOfMarket(
      marketId: marketId,
      item: item ?? this.item,
      additionalItem: additionalItem,
      gdsNo: gdsNo,
      dateSaleStart: dateSaleStart,
      dateSaleEnd: dateSaleEnd,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      dateStartDiscount: dateStartDiscount,
      dateEndDiscount: dateEndDiscount,
      useDefineElement: useDefineElement,
      rtfText: rtfText,
      useLinefeed: useLinefeed ?? this.useLinefeed,
      linefeed: linefeed ?? this.linefeed,
      useScaleBarcode: useScaleBarcode ?? this.useScaleBarcode,
      printCount: printCount ?? this.printCount,
      useLabelSize: useLabelSize ?? this.useLabelSize,
      labelSizeWidth: labelSizeWidth ?? this.labelSizeWidth,
      labelSizeHeight: labelSizeHeight ?? this.labelSizeHeight,
      useMargin: useMargin ?? this.useMargin,
      leftMargin: leftMargin ?? this.leftMargin,
      rightMargin: rightMargin ?? this.rightMargin,
      topMargin: topMargin ?? this.topMargin,
      leftPush: leftPush ?? this.leftPush,
      topPush: topPush ?? this.topPush,
    );
  }

  factory ItemOfMarket.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;
    double f(String key) => double.tryParse(s(key)) ?? 0;

    return ItemOfMarket(
      marketId: i('P1_MARKET_ID'),
      item: Item(
        itemId: i('P2_ITEM_ID'),
        labelSizeId: i('P2_LABELSIZE_ID'),
        itemName: s('P2_ITEM_NAME'),
        labelSizeName: s('P4_LABELSIZE_NAME'),
        element: s('P2_ELEMENT'),
        elementRTF: s('P2_ELEMENT_RTF'),
        price: i('P2_PRICE'),
        order: i('P2_PRICE_ORDER'),
      ),
      additionalItem: AdditionalItem(
        AdditionalItemId: i('P3_ADDITIONAL_ITEM_ID'),
        itemId: i('P3_ITEM_ID'),
        element: s('P3_ELEMENT'),
        elementRTF: s('P3_ELEMENT_RTF'),
        price: i('P3_PRICE'),
      ),
      gdsNo: i('P1_GDS_NO'),
      dateSaleStart:
          DateTime.tryParse(s('P1_SALE_START_DATE')) ?? DateTime.now(),
      dateSaleEnd: DateTime.tryParse(s('P1_SALE_END_DATE')) ?? DateTime.now(),
      discountPercent: f('P1_DISCOUNT_PERCENT'),
      discountAmount: i('P1_DISCOUNT_AMOUNT'),
      dateStartDiscount:
          DateTime.tryParse(s('P1_DISCOUNT_START_DATE')) ?? DateTime.now(),
      dateEndDiscount:
          DateTime.tryParse(s('P1_DISCOUNT_END_DATE')) ?? DateTime.now(),
      useDefineElement: i('P1_USE_USER_DEFINE_ELEMENT') != 0,
      rtfText: s('P1_USER_DEFINE_ELEMENT_RTF'),
      useLinefeed: i('P1_USE_LINEFEED') != 0,
      linefeed: i('P1_LINEFEED'),
      useScaleBarcode: i('P1_USE_SCALEBARCODE') != 0,
      printCount: i('P1_PRINT_COUNT'),
      useLabelSize: i('P1_USE_LABELSIZE') != 0,
      labelSizeWidth: i('P1_LABEL_SIZE_WIDTH'),
      labelSizeHeight: i('P1_LABEL_SIZE_HEIGHT'),
      useMargin: i('P1_USE_MARGIN') != 0,
      leftMargin: f('P1_LEFT_MARGIN'),
      rightMargin: f('P1_RIGHT_MARGIN'),
      topMargin: f('P1_TOP_MARGIN'),
      leftPush: f('P1_LEFT_PUSH'),
      topPush: f('P1_TOP_PUSH'),
    );
  }

  @override
  String toString() =>
      'marketId: $marketId, gdsNo: $gdsNo, dateSaleStart: $dateSaleStart, dateSaleEnd: $dateSaleEnd, '
      'discountPercent: $discountPercent, discountAmount: $discountAmount, dateStartDiscount: $dateStartDiscount, '
      'dateEndDiscount: $dateEndDiscount, useDefineElement: $useDefineElement, rtfText: $rtfText, '
      'useLinefeed: $useLinefeed, linefeed: $linefeed, useScaleBarcode: $useScaleBarcode, '
      'printCount: $printCount, useLabelSize: $useLabelSize, labelSizeWidth: $labelSizeWidth, '
      'labelSizeHeight: $labelSizeHeight, useMargin: $useMargin, leftMargin: $leftMargin, '
      'rightMargin: $rightMargin, topMargin: $topMargin, leftPush: $leftPush, topPush: $topPush';
}

class ItemOfMarketDAO extends DAO {
  static const String UpdateItemInfoSql = '''
    UPDATE BM_ITEM_OF_MARKET
       SET RICH_USE_LINEFEED=@useLinefeed,
           RICH_LINEFEED=@linefeed,
           RICH_USE_SCALEBARCODE=@useScaleBarcode,
           RICH_PRINT_COUNT=@printCount,
           RICH_USE_LABELSIZE=@useLabelSize,
           RICH_LABELSIZE_WIDTH=@labelSizeWidth,
           RICH_LABELSIZE_HEIGHT=@labelSizeHeight,
           RICH_USE_MARGIN=@useMargin,
           RICH_LEFT_MARGIN=@leftMargin,
           RICH_RIGHT_MARGIN=@rightMargin,
           RICH_TOP_MARGIN=@topMargin,
           RICH_LEFT_PUSH=@leftPush,
           RICH_TOP_PUSH=@topPush
     WHERE RICH_MARKET_ID=@marketId
       AND RICH_ITEM_ID=@itemId;
    IF @@ROWCOUNT<>1
      THROW 51009, 'Item info update count mismatch.', 1;
  ''';

  static List<DbTransactionStatement> itemInfoUpdateStatements(
    List<ItemOfMarket> items,
  ) => [
    for (final item in items)
      DbTransactionStatement(
        sql: UpdateItemInfoSql,
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

  static const String SelectSql =
      '''
		SELECT 
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_MARKET_ID), N'') AS P1_MARKET_ID,
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
		FROM BM_ITEM_OF_MARKET P1 
		INNER JOIN BM_RICH_ITEM P2 
		ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID 
		LEFT OUTER JOIN BM_ADDITIONAL_ITEM P3 
		ON P1.RICH_ADDITIONAL_ITEM_ID=P3.RICH_ADDITIONAL_ITEM_ID 
		INNER JOIN BM_RICH_LABELSIZE_FORM P4 
		ON P2.RICH_LABELSIZE_ID=P4.RICH_LABELSIZE_ID
	''';

  // WHERE 절: ItemOfMarket Market/LabelSize ID로 조회 (Integer)
  static const String WhereSqlMarketAndLabelSizeId = '''
		WHERE P1.RICH_MARKET_ID=@marketId AND P2.RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String OrderByItemOrder = '''
    ORDER BY P2.RICH_ITEM_ORDER, P2.RICH_ITEM_ID ASC
  ''';

  static Future<List<ItemOfMarket>?> selectByItemOfMarketAndLabelSizeId(
    int marketId,
    int labelSizeId,
  ) async {
    debugLog('$START, ItemOfMarketAndLabelSizeId:$marketId,$labelSizeId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlMarketAndLabelSizeId $OrderByItemOrder',
        {'marketId': marketId, 'labelSizeId': labelSizeId},
      );

      final itemOfMarkets = DAO.mapRows(res, ItemOfMarket.fromMap);

      debugLog(END);
      return itemOfMarkets;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }
}
