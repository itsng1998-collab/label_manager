import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

Customer customerFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();
  int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

  return Customer(
    customerId: intValue('CUSTOMER_ID'),
    cooperatorId: stringValue('COOP_ID'),
    customerName: stringValue('NAME'),
  );
}

class CustomerDAO extends DAO {
  static const String selectSql =
      '''
		SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_CUSTOMER_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(30), RICH_COOP_ID COLLATE ${DAO.CP949}), N'') AS COOP_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME
		FROM BM_CUSTOMER
  ''';

  // WHERE 절: Customer ID로 조회 (Integer)
  static const String whereSqlCustomerId = '''
	  WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String whereSqlCooperatorId =
      '''
    WHERE LTRIM(RTRIM(CONVERT(NVARCHAR(30),RICH_COOP_ID COLLATE ${DAO.CP949}))) =
          LTRIM(RTRIM(CONVERT(NVARCHAR(30),@cooperatorId)))
  ''';

  static const String insertSql = '''
    INSERT INTO BM_CUSTOMER (RICH_COOP_ID, RICH_NAME)
    VALUES (@cooperatorId, @customerName)
  ''';

  static const String updateSql = '''
    UPDATE BM_CUSTOMER
       SET RICH_COOP_ID=@cooperatorId,
           RICH_NAME=@customerName
     WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String deleteSql = '''
    DELETE FROM BM_CUSTOMER
     WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static Future<List<Customer>> selectByCooperatorId(
    String cooperatorId,
  ) async {
    debugLog('$START, cooperatorId:$cooperatorId');
    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlCooperatorId',
        {'cooperatorId': cooperatorId},
      );
      final rows = DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => customerFromRow(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      debugLog(END);
      return rows;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<Customer?> selectByCustomerId(int customerId) async {
    debugLog('$START, customerId:$customerId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlCustomerId',
        {'customerId': customerId},
      );

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return customerFromRow(map!);
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> insert(Customer customer) async {
    final result = await DbClient.instance.writeDataWithParams(insertSql, {
      'cooperatorId': customer.cooperatorId,
      'customerName': customer.customerName,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('${runtimeLogTag()} Insert failed for customer');
    }
  }

  static Future<void> update(Customer customer) async {
    final result = await DbClient.instance.writeDataWithParams(updateSql, {
      'customerId': customer.customerId,
      'cooperatorId': customer.cooperatorId,
      'customerName': customer.customerName,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception(
        '${runtimeLogTag()} Update failed for customerId:${customer.customerId}',
      );
    }
  }

  static Future<void> delete(int customerId) async {
    final result = await DbClient.instance.writeDataWithParams(deleteSql, {
      'customerId': customerId,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception(
        '${runtimeLogTag()} Delete failed for customerId:$customerId',
      );
    }
  }
}
