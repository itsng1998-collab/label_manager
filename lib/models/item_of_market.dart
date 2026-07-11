// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';
import 'item.dart';
import 'additional_item.dart';

class ItemMarketMappingFingerprints {
  ItemMarketMappingFingerprints(Map<int, Iterable<int>> values)
    : _values = Map.unmodifiable(<int, List<int>>{
        for (final entry in values.entries)
          entry.key: List.unmodifiable(entry.value.toList()..sort()),
      });

  factory ItemMarketMappingFingerprints.fromRows(
    Iterable<Map<String, dynamic>> rows,
  ) {
    final values = <int, List<int>>{};
    for (final row in rows) {
      final itemId = _mappingFingerprintInt(row['ITEM_ID']);
      final marketId = _mappingFingerprintInt(row['MARKET_ID']);
      if (itemId <= 0 || marketId <= 0) continue;
      values.putIfAbsent(itemId, () => []).add(marketId);
    }
    return ItemMarketMappingFingerprints(values);
  }

  final Map<int, List<int>> _values;

  List<int> marketIdsFor(int itemId) => _values[itemId] ?? const [];

  Map<String, List<int>> toJsonForItems(Iterable<int> itemIds) => {
    for (final itemId in itemIds.toSet().toList()..sort())
      '$itemId': marketIdsFor(itemId),
  };

  bool matchesForItems(
    ItemMarketMappingFingerprints other,
    Iterable<int> itemIds,
  ) {
    for (final itemId in itemIds) {
      if (!listEquals(marketIdsFor(itemId), other.marketIdsFor(itemId))) {
        return false;
      }
    }
    return true;
  }
}

int _mappingFingerprintInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  _ => int.tryParse('$value') ?? 0,
};

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

  ItemOfMarket copyWith({Item? item}) {
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
      useLinefeed: useLinefeed,
      linefeed: linefeed,
      useScaleBarcode: useScaleBarcode,
      printCount: printCount,
      useLabelSize: useLabelSize,
      labelSizeWidth: labelSizeWidth,
      labelSizeHeight: labelSizeHeight,
      useMargin: useMargin,
      leftMargin: leftMargin,
      rightMargin: rightMargin,
      topMargin: topMargin,
      leftPush: leftPush,
      topPush: topPush,
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

class ItemOfMarketRawSnapshot {
  final int marketId;
  final int itemId;
  final int? additionalItemId;
  final int? gdsNo;
  final DateTime? dateSaleStart;
  final DateTime? dateSaleEnd;
  final double? discountPercent;
  final int? discountAmount;
  final DateTime? dateStartDiscount;
  final DateTime? dateEndDiscount;
  final bool? useDefineElement;
  final String? rtfText;
  final bool? useLinefeed;
  final int? linefeed;
  final bool? useScaleBarcode;
  final int? printCount;
  final bool? useLabelSize;
  final int? labelSizeWidth;
  final int? labelSizeHeight;
  final bool? useMargin;
  final double? leftMargin;
  final double? rightMargin;
  final double? topMargin;
  final double? leftPush;
  final double? topPush;

  const ItemOfMarketRawSnapshot({
    required this.marketId,
    required this.itemId,
    required this.additionalItemId,
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

  factory ItemOfMarketRawSnapshot.fromMap(Map<String, dynamic> map) {
    int? nullableInt(String key) {
      final value = map[key];
      if (value == null) return null;
      return value is int ? value : int.tryParse(value.toString());
    }

    double? nullableDouble(String key) {
      final value = map[key];
      if (value == null) return null;
      return value is num
          ? value.toDouble()
          : double.tryParse(value.toString());
    }

    DateTime? nullableDate(String key) {
      final value = map[key];
      if (value == null) return null;
      return value is DateTime ? value : DateTime.tryParse(value.toString());
    }

    bool? nullableBool(String key) {
      final value = nullableInt(key);
      return value == null ? null : value != 0;
    }

    return ItemOfMarketRawSnapshot(
      marketId: nullableInt('MARKET_ID') ?? 0,
      itemId: nullableInt('ITEM_ID') ?? 0,
      additionalItemId: nullableInt('ADDITIONAL_ITEM_ID'),
      gdsNo: nullableInt('GDS_NO'),
      dateSaleStart: nullableDate('SALE_START_DATE'),
      dateSaleEnd: nullableDate('SALE_END_DATE'),
      discountPercent: nullableDouble('DISCOUNT_PERCENT'),
      discountAmount: nullableInt('DISCOUNT_AMOUNT'),
      dateStartDiscount: nullableDate('DISCOUNT_START_DATE'),
      dateEndDiscount: nullableDate('DISCOUNT_END_DATE'),
      useDefineElement: nullableBool('USE_USER_DEFINE_ELEMENT'),
      rtfText: map['USER_DEFINE_ELEMENT_RTF'] as String?,
      useLinefeed: nullableBool('USE_LINEFEED'),
      linefeed: nullableInt('LINEFEED'),
      useScaleBarcode: nullableBool('USE_SCALEBARCODE'),
      printCount: nullableInt('PRINT_COUNT'),
      useLabelSize: nullableBool('USE_LABELSIZE'),
      labelSizeWidth: nullableInt('LABEL_SIZE_WIDTH'),
      labelSizeHeight: nullableInt('LABEL_SIZE_HEIGHT'),
      useMargin: nullableBool('USE_MARGIN'),
      leftMargin: nullableDouble('LEFT_MARGIN'),
      rightMargin: nullableDouble('RIGHT_MARGIN'),
      topMargin: nullableDouble('TOP_MARGIN'),
      leftPush: nullableDouble('LEFT_PUSH'),
      topPush: nullableDouble('TOP_PUSH'),
    );
  }
}

class ItemOfMarketDAO extends DAO {
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

  static const String SelectRawSnapshotSql =
      '''
    SELECT
      P1.RICH_MARKET_ID AS MARKET_ID,
      P1.RICH_ITEM_ID AS ITEM_ID,
      P1.RICH_ADDITIONAL_ITEM_ID AS ADDITIONAL_ITEM_ID,
      P1.RICH_GDS_NO AS GDS_NO,
      P1.RICH_SALE_START_DATE AS SALE_START_DATE,
      P1.RICH_SALE_END_DATE AS SALE_END_DATE,
      P1.RICH_DISCOUNT_PERCENT AS DISCOUNT_PERCENT,
      P1.RICH_DISCOUNT_AMOUNT AS DISCOUNT_AMOUNT,
      P1.RICH_DISCOUNT_START_DATE AS DISCOUNT_START_DATE,
      P1.RICH_DISCOUNT_END_DATE AS DISCOUNT_END_DATE,
      P1.RICH_USE_USER_DEFINE_ELEMENT AS USE_USER_DEFINE_ELEMENT,
      CONVERT(NVARCHAR(MAX), P1.RICH_USER_DEFINE_ELEMENT_RTF COLLATE ${DAO.CP949}) AS USER_DEFINE_ELEMENT_RTF,
      P1.RICH_USE_LINEFEED AS USE_LINEFEED,
      P1.RICH_LINEFEED AS LINEFEED,
      P1.RICH_USE_SCALEBARCODE AS USE_SCALEBARCODE,
      P1.RICH_PRINT_COUNT AS PRINT_COUNT,
      P1.RICH_USE_LABELSIZE AS USE_LABELSIZE,
      P1.RICH_LABELSIZE_WIDTH AS LABEL_SIZE_WIDTH,
      P1.RICH_LABELSIZE_HEIGHT AS LABEL_SIZE_HEIGHT,
      P1.RICH_USE_MARGIN AS USE_MARGIN,
      P1.RICH_LEFT_MARGIN AS LEFT_MARGIN,
      P1.RICH_RIGHT_MARGIN AS RIGHT_MARGIN,
      P1.RICH_TOP_MARGIN AS TOP_MARGIN,
      P1.RICH_LEFT_PUSH AS LEFT_PUSH,
      P1.RICH_TOP_PUSH AS TOP_PUSH
    FROM BM_ITEM_OF_MARKET P1
    INNER JOIN BM_RICH_ITEM P2 ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID
  ''';

  static const String SelectMappingFingerprintsSql = '''
    DECLARE @ScopedItemIds XML = @itemIdsXml;
    WITH ScopedItemIds AS (
      SELECT ItemIdNode.value('.', 'INT') AS RICH_ITEM_ID
      FROM @ScopedItemIds.nodes('/items/id') AS ItemIds(ItemIdNode)
    )
    SELECT
      P1.RICH_ITEM_ID AS ITEM_ID,
      P1.RICH_MARKET_ID AS MARKET_ID
    FROM BM_ITEM_OF_MARKET P1
    INNER JOIN ScopedItemIds S ON P1.RICH_ITEM_ID=S.RICH_ITEM_ID
    ORDER BY P1.RICH_ITEM_ID, P1.RICH_MARKET_ID
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

  static Future<List<ItemOfMarketRawSnapshot>?>
  selectRawSnapshotsByMarketAndLabelSizeId(
    int marketId,
    int labelSizeId,
  ) async {
    debugLog('$START, rawSnapshot:$marketId,$labelSizeId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectRawSnapshotSql $WhereSqlMarketAndLabelSizeId $OrderByItemOrder',
        {'marketId': marketId, 'labelSizeId': labelSizeId},
      );
      final snapshots = DAO.mapRows(res, ItemOfMarketRawSnapshot.fromMap);
      debugLog(END);
      return snapshots;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }

  static Future<ItemMarketMappingFingerprints>
  selectMappingFingerprintsByItemIds(Iterable<int> itemIds) async {
    final normalizedIds = itemIds.where((id) => id > 0).toSet().toList()
      ..sort();
    if (normalizedIds.isEmpty) {
      return ItemMarketMappingFingerprints(const {});
    }
    final itemIdsXml =
        '<items>${normalizedIds.map((id) => '<id>$id</id>').join()}</items>';
    final result = await DbClient.instance.getDataWithParams(
      SelectMappingFingerprintsSql,
      {'itemIdsXml': itemIdsXml},
    );
    return ItemMarketMappingFingerprints.fromRows(
      DAO.getRowsFromResult(result).cast<Map<String, dynamic>>(),
    );
  }
}
