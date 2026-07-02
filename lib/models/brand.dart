// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class Brand {
  static List<Brand>? datas;

  final int brandId;
  final int customerId;
  final String brandName;

  const Brand({
    required this.brandId,
    required this.customerId,
    required this.brandName,
  });

  static void setDatas(List<Brand>? values) {
    datas = values;
  }

  factory Brand.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return Brand(
      brandId:    i('BRAND_ID'),
      customerId: i('CUSTOMER_ID'),
      brandName:  s('BRAND_NAME'),
    );
  }

  @override
  String toString() =>
    'BrandId: $brandId, CustomerId: $customerId, BrandName: $brandName';
}

class BrandDAO extends DAO {
  static const String SelectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_BRAND_ID), N'') AS BRAND_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_CUSTOMER_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME
    FROM BM_RICH_BRAND
  ''';

  // WHERE 절: Customer ID로 조회 (Integer)
  static const String WhereSqlCustomerId = '''
	  WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String OrderSqlByBrandrder = '''
	  ORDER BY RICH_BRAND_ORDER ASC
  ''';

  static Future<List<Brand>?> selectByCustomerIdByBrandOrder(int customerId) async {
    debugLog('$START, customerId:$customerId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlCustomerId $OrderSqlByBrandrder', { 'customerId': customerId }
      );

      final brands = DAO.mapRows(res, Brand.fromMap);
      Brand.setDatas(brands);

      debugLog(END);
      return brands;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<bool> updateByBrandId(
    Brand brand, String newBrandName
  ) async {
    debugLog('$START, brandId:${brand.brandId}, customerId:${brand.customerId}, brandName:${brand.brandName}, newBrandName:$newBrandName');

    try {
      final updateSql = '''
        UPDATE BM_RICH_BRAND
          SET RICH_CUSTOMER_ID=@customerId,
              RICH_BRAND_NAME=@brandName
        WHERE RICH_BRAND_ID=@brandId
      ''';

      final res = await DbClient.instance.writeDataWithParams(
        updateSql,
        {'customerId': brand.customerId, 'brandName': newBrandName, 'brandId': brand.brandId},
      );
      final affected = _affectedRows(res);
      final succeeded = affected > 0;

      debugLog('$END, BM_RICH_BRAND Result: $res, affected:$affected, succeeded:$succeeded');
      return succeeded;
    }
    catch (e) {
      debugLog('$END, $e');
      return false;
    }
  }

  static int _affectedRows(Object result) {
    final map = switch (result) {
      final String value => jsonDecode(value) as Map<String, dynamic>,
      final Map value => value,
      _ => const <String, dynamic>{},
    };
    final affected = map['affected'];
    return switch (affected) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }
}
