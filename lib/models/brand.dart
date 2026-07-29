// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/last_connect/data/last_connect_dao.dart';
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

class BrandOrderUpdate {
  final int brandId;
  final int brandOrder;

  const BrandOrderUpdate({required this.brandId, required this.brandOrder});
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
        SET NOCOUNT ON;
        BEGIN TRY
          CREATE TABLE #InsertedBrand (
            BRAND_ID INT NOT NULL,
            CUSTOMER_ID INT NOT NULL,
            BRAND_NAME VARCHAR(50) NOT NULL
          );

          BEGIN TRANSACTION;

          INSERT INTO BM_RICH_BRAND
            (RICH_CUSTOMER_ID, RICH_BRAND_NAME, RICH_BRAND_ORDER)
          OUTPUT
            INSERTED.RICH_BRAND_ID,
            INSERTED.RICH_CUSTOMER_ID,
            INSERTED.RICH_BRAND_NAME
          INTO #InsertedBrand (BRAND_ID, CUSTOMER_ID, BRAND_NAME)
          VALUES
            (@customerId, @brandName, @brandOrder);

          UPDATE BM_RICH_BRAND
             SET RICH_BRAND_ORDER = RICH_BRAND_ORDER + 1
           WHERE RICH_CUSTOMER_ID=@customerId
             AND RICH_BRAND_ORDER >= @brandOrder
             AND RICH_BRAND_ID NOT IN (SELECT BRAND_ID FROM #InsertedBrand);

          COMMIT TRANSACTION;
          SET NOCOUNT OFF;
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
          SET NOCOUNT OFF;
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
        SET NOCOUNT ON;
        BEGIN TRY
          DECLARE @brandAffected INT = 0;

          BEGIN TRANSACTION;

          ${LastConnectDAO.deleteSqlByBrandId};

          DELETE FROM BM_RICH_BRAND
           WHERE RICH_BRAND_ID=@brandId;
          SET @brandAffected = @@ROWCOUNT;

          IF @brandAffected <= 0
            THROW 51010, 'Delete brand failed.', 1;

          COMMIT TRANSACTION;
          SET NOCOUNT OFF;
          SET XACT_ABORT OFF;

          SELECT @brandAffected AS AFFECTED;
        END TRY
        BEGIN CATCH
          IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
          SET NOCOUNT OFF;
          SET XACT_ABORT OFF;
          THROW;
        END CATCH
      ''';

      final res = await DbClient.instance.writeDataWithParams(
        deleteSql,
        {
          'brandId': brand.brandId,
        },
      );

      final row = DAO.getRowMapFromResult(res);
      final affected = int.tryParse((row?['AFFECTED'] ?? '0').toString()) ?? 0;
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

  static Future<void> updateOrders(List<BrandOrderUpdate> orderUpdates) async {
    debugLog('$START, brandOrderUpdates:${orderUpdates.length}');

    if (orderUpdates.isEmpty) {
      debugLog('$END, empty brandOrderUpdates');
      return;
    }

    try {
      final updateStatements = StringBuffer();
      final params = <String, Object?>{};
      final affectedVariables = <String>[];
      for (var index = 0; index < orderUpdates.length; index += 1) {
        final update = orderUpdates[index];
        final brandIdParam = 'brandId$index';
        final brandOrderParam = 'brandOrder$index';
        final affectedVariable = '@affected$index';
        affectedVariables.add(affectedVariable);
        updateStatements.writeln('''
          DECLARE $affectedVariable INT = 0;
          UPDATE BM_RICH_BRAND
             SET RICH_BRAND_ORDER=@$brandOrderParam
           WHERE RICH_BRAND_ID=@$brandIdParam;
          SET $affectedVariable = @@ROWCOUNT;
          IF $affectedVariable <= 0
            THROW 51030, 'Update brand order failed.', 1;
        ''');
        params[brandIdParam] = update.brandId;
        params[brandOrderParam] = update.brandOrder;
      }
      final affectedExpression = affectedVariables.join(' + ');

      final updateOrderTransactionSql = '''
        SET XACT_ABORT ON;
        SET NOCOUNT ON;
        BEGIN TRY
          BEGIN TRANSACTION;

          $updateStatements

          COMMIT TRANSACTION;
          SET NOCOUNT OFF;
          SET XACT_ABORT OFF;

          SELECT $affectedExpression AS AFFECTED;
        END TRY
        BEGIN CATCH
          IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
          SET NOCOUNT OFF;
          SET XACT_ABORT OFF;
          THROW;
        END CATCH
      ''';

      final res = await DbClient.instance.writeDataWithParams(
        updateOrderTransactionSql,
        params,
      );
      if (DAO.affectedRows(res) <= 0) {
        throw Exception('${runtimeLogTag()} Update brand order affected no rows');
      }

      debugLog('$END, BM_RICH_BRAND order Result: $res');
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }
}
