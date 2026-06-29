// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
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
      marketId:   i('MARKET_ID'),
      customerId: i('CUSTOMER_ID'),
      name:       s('NAME'),
    );
  }

  @override
  String toString() =>
    'MarketId: $marketId, CustomerId: $customerId, Name: $name';
}

class MarketDAO extends DAO {
  static const String SelectSql = '''
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

  static Future<Market?> getByMarketId(int marketId) async {
    debugLog('$START, marketId:$marketId');

    try {
			final res = await DbClient.instance.getDataWithParams(
				'$SelectSql $WhereSqlMarketId', { 'marketId': marketId }
			);

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return Market.fromMap(map!);
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }
}
