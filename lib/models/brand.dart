// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

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

  static Future<void> updateByBrandId(
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

      final affected = DAO.affectedRows(res);
      final succeeded = affected > 0;

      if (!succeeded) {
        throw Exception('${runtimeLogTag()} Update failed for brandId:${brand.brandId}');
      }

      debugLog('$END, BM_RICH_BRAND Result: $res, affected:$affected, succeeded:$succeeded');
    }
    catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<Brand> insertByBrandName(
    int customerId,
    String brandName,
    int brandOrder,
  ) async {
    debugLog('$START, customerId:$customerId, brandName:$brandName, brandOrder:$brandOrder');

    try {
      final insertSql = '''
        SET XACT_ABORT ON;
        BEGIN TRY
          CREATE TABLE #InsertedBrand (
            BRAND_ID INT NOT NULL,
            CUSTOMER_ID INT NOT NULL,
            BRAND_NAME VARCHAR(50) NOT NULL
          );

          BEGIN TRANSACTION;

          UPDATE BM_RICH_BRAND
             SET RICH_BRAND_ORDER = RICH_BRAND_ORDER + 1
           WHERE RICH_CUSTOMER_ID=@customerId
             AND RICH_BRAND_ORDER >= @brandOrder;

          INSERT INTO BM_RICH_BRAND
            (RICH_CUSTOMER_ID, RICH_BRAND_NAME, RICH_BRAND_ORDER)
          OUTPUT
            INSERTED.RICH_BRAND_ID,
            INSERTED.RICH_CUSTOMER_ID,
            INSERTED.RICH_BRAND_NAME
          INTO #InsertedBrand
          VALUES
            (@customerId, @brandName, @brandOrder);

          COMMIT TRANSACTION;
          SET XACT_ABORT OFF;

          SELECT
            COALESCE(CONVERT(NVARCHAR(20), BRAND_ID), N'') AS BRAND_ID,
            COALESCE(CONVERT(NVARCHAR(20), CUSTOMER_ID), N'') AS CUSTOMER_ID,
            COALESCE(CONVERT(NVARCHAR(50), BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME
          FROM #InsertedBrand;
        END TRY
        BEGIN CATCH
          IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
          SET XACT_ABORT OFF;
          THROW;
        END CATCH
      ''';

      final res = await DbClient.instance.writeDataWithParams(
        insertSql,
        {
          'customerId': customerId,
          'brandName': brandName,
          'brandOrder': brandOrder,
        },
      );

      final inserted = DAO.mapRow(res, Brand.fromMap);
      if (inserted == null) {
        throw Exception('${runtimeLogTag()} Insert failed for brandName:$brandName');
      }

      final affected = DAO.affectedRows(res);
      debugLog('$END, BM_RICH_BRAND insert Result: $res, affected:$affected, inserted:$inserted');
      return inserted;
    }
    catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<void> deleteByBrandId(Brand brand) async {
    debugLog('$START, brandId:${brand.brandId}, customerId:${brand.customerId}, brandName:${brand.brandName}');

    try {
      final deleteSql = '''
        SET XACT_ABORT ON;
        BEGIN TRY
          CREATE TABLE #DeletedOrder (
            BRAND_ORDER INT NOT NULL
          );

          BEGIN TRANSACTION;

          DELETE FROM BM_RICH_BRAND
          OUTPUT DELETED.RICH_BRAND_ORDER INTO #DeletedOrder
           WHERE RICH_BRAND_ID=@brandId
             AND RICH_CUSTOMER_ID=@customerId;

          IF NOT EXISTS (SELECT 1 FROM #DeletedOrder)
            THROW 51010, 'Delete brand failed.', 1;

          UPDATE BM_RICH_BRAND
             SET RICH_BRAND_ORDER = RICH_BRAND_ORDER - 1
           WHERE RICH_CUSTOMER_ID=@customerId
             AND RICH_BRAND_ORDER > (SELECT TOP 1 BRAND_ORDER FROM #DeletedOrder);

          COMMIT TRANSACTION;
          SET XACT_ABORT OFF;
        END TRY
        BEGIN CATCH
          IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
          SET XACT_ABORT OFF;
          THROW;
        END CATCH
      ''';

      final res = await DbClient.instance.writeDataWithParams(
        deleteSql,
        {
          'brandId': brand.brandId,
          'customerId': brand.customerId,
        },
      );

      final affected = DAO.affectedRows(res);
      final succeeded = affected > 0;

      if (!succeeded) {
        throw Exception('${runtimeLogTag()} Delete affected no rows for brandId:${brand.brandId}');
      }

      debugLog('$END, BM_RICH_BRAND delete Result: $res, affected:$affected, succeeded:$succeeded');
    }
    catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }
}
