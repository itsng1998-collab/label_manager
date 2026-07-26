// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class Customer {
  static Customer? instance;

  final int customerId;
  final String cooperatorId;
	final String customerName;

  const Customer({
    required this.customerId,
    required this.cooperatorId,
    required this.customerName,
  });

  static void setInstance(Customer? customer) {
    instance = customer;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return Customer(
      customerId:   i('CUSTOMER_ID'),
      cooperatorId: s('COOP_ID'),
      customerName: s('NAME'),
    );
  }

  @override
  String toString() =>
    'CustomerId: $customerId, CoopId: $cooperatorId, CustomerName: $customerName';
}

class CustomerDAO extends DAO {
  static const String SelectSql = '''
		SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_CUSTOMER_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(30), RICH_COOP_ID COLLATE ${DAO.CP949}), N'') AS COOP_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME
		FROM BM_CUSTOMER
  ''';

  // WHERE 절: Customer ID로 조회 (Integer)
  static const String WhereSqlCustomerId = '''
	  WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String WhereSqlCooperatorId = '''
    WHERE LTRIM(RTRIM(CONVERT(NVARCHAR(30),RICH_COOP_ID COLLATE ${DAO.CP949}))) =
          LTRIM(RTRIM(CONVERT(NVARCHAR(30),@cooperatorId)))
  ''';

  static const String InsertSql = '''
    INSERT INTO BM_CUSTOMER (RICH_COOP_ID, RICH_NAME)
    VALUES (@cooperatorId, @customerName)
  ''';

  static const String UpdateSql = '''
    UPDATE BM_CUSTOMER
       SET RICH_COOP_ID=@cooperatorId,
           RICH_NAME=@customerName
     WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static const String DeleteSql = '''
    DELETE FROM BM_CUSTOMER
     WHERE RICH_CUSTOMER_ID=@customerId
  ''';

  static Future<List<Customer>> selectByCooperatorId(
    String cooperatorId,
  ) async {
    debugLog('$START, cooperatorId:$cooperatorId');
    try {
      final result = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlCooperatorId',
        {'cooperatorId': cooperatorId},
      );
      final rows = DAO.getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => Customer.fromMap(Map<String, dynamic>.from(row)))
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
				'$SelectSql $WhereSqlCustomerId', { 'customerId': customerId }
			);

      final map = DAO.getRowMapFromResult(res);
  
      debugLog(END);
      return Customer.fromMap(map!);
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> insert(Customer customer) async {
    final result = await DbClient.instance.writeDataWithParams(InsertSql, {
      'cooperatorId': customer.cooperatorId,
      'customerName': customer.customerName,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('${runtimeLogTag()} Insert failed for customer');
    }
  }

  static Future<void> update(Customer customer) async {
    final result = await DbClient.instance.writeDataWithParams(UpdateSql, {
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
    final result = await DbClient.instance.writeDataWithParams(DeleteSql, {
      'customerId': customerId,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception(
        '${runtimeLogTag()} Delete failed for customerId:$customerId',
      );
    }
  }
}
