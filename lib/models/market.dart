// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class Market {
  static Market? instance;

  final int marketId;
  final int customerId;
  final String name;

  const Market({
    required this.marketId,
    required this.customerId,
    required this.name,
  });

  static void setInstance(Market? market) {
    instance = market;
  }

  factory Market.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return Market(
      marketId: i('MARKET_ID'),
      customerId: i('CUSTOMER_ID'),
      name: s('NAME'),
    );
  }

  @override
  String toString() =>
      'MarketId: $marketId, CustomerId: $customerId, Name: $name';
}

class MarketDAO extends DAO {
  static const String SelectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_MARKET_ID), N'') AS MARKET_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_CUSTOMER_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME,
      COALESCE(CONVERT(NVARCHAR(20), RICH_ETC COLLATE ${DAO.CP949}), N'') AS ETC
    FROM BM_MARKET
  ''';

  // WHERE 절: Market ID로 조회 (Integer)
  static const String WhereSqlMarketId = '''
	  WHERE RICH_MARKET_ID=@marketId
  ''';

  static const String WhereSqlCustomerId = '''
    WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String OrderByMarketId = '''
    ORDER BY RICH_MARKET_ID ASC
  ''';

  static const String InsertWithItemMappingsSql = '''
    DECLARE @InsertedMarket TABLE (MARKET_ID INT NOT NULL);

    INSERT INTO BM_MARKET (RICH_CUSTOMER_ID, RICH_NAME)
    OUTPUT INSERTED.RICH_MARKET_ID INTO @InsertedMarket(MARKET_ID)
    VALUES (@customerId, @marketName);

    INSERT INTO BM_ITEM_OF_MARKET (
      RICH_MARKET_ID, RICH_ITEM_ID, RICH_ADDITIONAL_ITEM_ID,
      RICH_GDS_NO, RICH_SALE_START_DATE, RICH_SALE_END_DATE,
      RICH_DISCOUNT_PERCENT, RICH_DISCOUNT_AMOUNT,
      RICH_DISCOUNT_START_DATE, RICH_DISCOUNT_END_DATE,
      RICH_USE_USER_DEFINE_ELEMENT, RICH_USER_DEFINE_ELEMENT_RTF,
      RICH_USE_LINEFEED, RICH_LINEFEED, RICH_USE_SCALEBARCODE,
      RICH_PRINT_COUNT, RICH_USE_LABELSIZE, RICH_LABELSIZE_WIDTH,
      RICH_LABELSIZE_HEIGHT, RICH_USE_MARGIN, RICH_LEFT_MARGIN,
      RICH_RIGHT_MARGIN, RICH_TOP_MARGIN, RICH_LEFT_PUSH, RICH_TOP_PUSH
    )
    SELECT M.MARKET_ID, I.RICH_ITEM_ID, NULL,
      0, NULL, NULL, 0, 0, NULL, NULL,
      0, '', 0, 100, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
    FROM @InsertedMarket M
    INNER JOIN BM_RICH_ITEM I ON 1=1
    INNER JOIN BM_RICH_LABELSIZE_FORM L
      ON I.RICH_LABELSIZE_ID=L.RICH_LABELSIZE_ID
    INNER JOIN BM_RICH_BRAND B
      ON L.RICH_BRAND_ID=B.RICH_BRAND_ID
    WHERE B.RICH_CUSTOMER_ID=@customerId;

    SELECT MARKET_ID FROM @InsertedMarket;
  ''';

  static const String UpdateSql = '''
    UPDATE BM_MARKET
       SET RICH_CUSTOMER_ID=@customerId,
           RICH_NAME=@marketName
     WHERE RICH_MARKET_ID=@marketId
  ''';

  static const String DeleteItemMappingsSql = '''
    DELETE FROM BM_ITEM_OF_MARKET
     WHERE RICH_MARKET_ID=@marketId
  ''';

  static const String DeleteSql = '''
    DELETE FROM BM_MARKET
     WHERE RICH_MARKET_ID=@marketId
  ''';

  static Future<Market?> selectByMarketId(int marketId) async {
    debugLog('$START, marketId:$marketId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlMarketId',
        {'marketId': marketId},
      );

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return Market.fromMap(map!);
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<List<Market>?> selectByCustomerId(int customerId) async {
    debugLog('$START, customerId:$customerId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlCustomerId $OrderByMarketId',
        {'customerId': customerId},
      );
      final markets = DAO.mapRows(res, Market.fromMap);
      debugLog(END);
      return markets;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<List<Market>> selectForAdminConnect(int customerId) async {
    final result = await DbClient.instance.getDataWithParams(
      '$SelectSql $WhereSqlCustomerId',
      {'customerId': customerId},
    );
    return DAO.mapRows(result, Market.fromMap);
  }

  static Future<int> insertWithItemMappings(Market market) async {
    final results = await DbClient.instance.transaction([
      DbTransactionStatement(
        sql: InsertWithItemMappingsSql,
        params: {'customerId': market.customerId, 'marketName': market.name},
        returnsRows: true,
      ),
    ]);
    final row = DAO.getRowMapFromResult(results.single);
    final marketId = int.tryParse((row?['MARKET_ID'] ?? '').toString());
    if (marketId == null) {
      throw Exception('${runtimeLogTag()} Insert failed for market');
    }
    return marketId;
  }

  static Future<void> update(Market market) async {
    final result = await DbClient.instance.writeDataWithParams(UpdateSql, {
      'marketId': market.marketId,
      'customerId': market.customerId,
      'marketName': market.name,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception(
        '${runtimeLogTag()} Update failed for marketId:${market.marketId}',
      );
    }
  }

  static Future<void> deleteWithItemMappings(int marketId) async {
    final results = await DbClient.instance.transaction([
      DbTransactionStatement(
        sql: DeleteItemMappingsSql,
        params: {'marketId': marketId},
      ),
      DbTransactionStatement(sql: DeleteSql, params: {'marketId': marketId}),
    ]);
    if (DAO.affectedRows(results.last) <= 0) {
      throw Exception(
        '${runtimeLogTag()} Delete failed for marketId:$marketId',
      );
    }
  }
}
