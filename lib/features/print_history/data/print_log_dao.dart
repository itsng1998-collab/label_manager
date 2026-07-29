import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/print_history/domain/print_log.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class PrintLogQuerySpec {
  const PrintLogQuerySpec({required this.sql, required this.params});

  final String sql;
  final Map<String, dynamic> params;
}

class PrintLogDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_PRINT_LOG_ID), N'') AS LOG_ID,
      COALESCE(CONVERT(NVARCHAR(30), RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_NAME COLLATE ${DAO.CP949}), N'') AS USER_NAME,
      COALESCE(CONVERT(NVARCHAR(20), RICH_USER_GRADE), N'') AS USER_GRADE,
      COALESCE(CONVERT(NVARCHAR(20), RICH_MARKET_ID), N'') AS MARKET_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_MARKET_NAME COLLATE ${DAO.CP949}), N'') AS MARKET_NAME,
      COALESCE(CONVERT(NVARCHAR(20), RICH_CUSTOMER_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_CUSTOMER_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME,
      COALESCE(CONVERT(NVARCHAR(50), RICH_BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME,
      COALESCE(CONVERT(NVARCHAR(50), RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(100), RICH_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(20), RICH_PRINT_COUNT), N'') AS PRINT_COUNT,
      COALESCE(CONVERT(NVARCHAR(30), RICH_DATETIME, 120), N'') AS DATETIME,
      COALESCE(CONVERT(NVARCHAR(8), RICH_DATE_YYYYMMDD COLLATE ${DAO.CP949}), N'') AS DATE_YYYYMMDD,
      COALESCE(CONVERT(NVARCHAR(100), RICH_PRINTER COLLATE ${DAO.CP949}), N'') AS PRINTER,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_COLUMNS COLLATE ${DAO.CP949}), N'') AS COLUMNS,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_PRINT_CELLS COLLATE ${DAO.CP949}), N'') AS PRINT_CELLS,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_SAVE_IN_DB_CELLS COLLATE ${DAO.CP949}), N'') AS SAVE_IN_DB_CELLS,
      COALESCE(CONVERT(NVARCHAR(20), RICH_FORM_WIDTH), N'') AS FORM_WIDTH,
      COALESCE(CONVERT(NVARCHAR(20), RICH_FORM_HEIGHT), N'') AS FORM_HEIGHT,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_LEFT_MARGIN), N'') AS LEFT_MARGIN,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_RIGHT_MARGIN), N'') AS RIGHT_MARGIN,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_TOP_MARGIN), N'') AS TOP_MARGIN,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_LEFT_PUSH), N'') AS LEFT_PUSH,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_TOP_PUSH), N'') AS TOP_PUSH,
      COALESCE(CONVERT(NVARCHAR(30), RICH_PRINT_APPENDANT), N'') AS APPENDANT,
      COALESCE(CONVERT(NVARCHAR(20), RICH_ITEM_ID), N'') AS ITEM_ID
    FROM BM_RICH_PRINT_LOG
    WHERE RICH_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)
      AND CONVERT(VARCHAR(8), @endDate)
  ''';

  static const String sumSql = '''
    SELECT COALESCE(SUM(RICH_PRINT_COUNT), 0) AS PRINT_COUNT
    FROM BM_RICH_PRINT_LOG
    WHERE 1=1
  ''';

  static Future<List<PrintLog>> select({
    required String startDate,
    required String endDate,
    required PrintLogSearchType searchType,
    required String searchText,
    int? customerId,
  }) async {
    final spec = buildSelectQuery(
      startDate: startDate,
      endDate: endDate,
      searchType: searchType,
      searchText: searchText,
      customerId: customerId,
    );
    try {
      final result = await DbClient.instance.getDataWithParams(
        spec.sql,
        spec.params,
      );
      return DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => PrintLog.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static PrintLogQuerySpec buildSelectQuery({
    required String startDate,
    required String endDate,
    required PrintLogSearchType searchType,
    required String searchText,
    int? customerId,
  }) {
    final params = <String, dynamic>{
      'startDate': startDate,
      'endDate': endDate,
      'searchText': searchText,
    };
    final condition = switch (searchType) {
      PrintLogSearchType.itemName =>
        "AND RICH_ITEM_NAME LIKE N'%' + @searchText + N'%'",
      PrintLogSearchType.userId => 'AND RICH_USER_ID=@searchText',
      PrintLogSearchType.customerName => 'AND RICH_CUSTOMER_NAME=@searchText',
    };
    final customerCondition =
        customerId == null || searchType == PrintLogSearchType.customerName
        ? ''
        : 'AND RICH_CUSTOMER_ID=@customerId';
    if (customerCondition.isNotEmpty) params['customerId'] = customerId;
    return PrintLogQuerySpec(
      sql:
          '$selectSql $condition $customerCondition '
          'ORDER BY RICH_DATETIME ASC',
      params: params,
    );
  }

  static Future<int> selectPrintCountSum({
    String? startDate,
    String? endDate,
    String? customerName,
    String? labelSizeName,
  }) async {
    final spec = buildSumQuery(
      startDate: startDate,
      endDate: endDate,
      customerName: customerName,
      labelSizeName: labelSizeName,
    );
    try {
      final result = await DbClient.instance.getDataWithParams(
        spec.sql,
        spec.params,
      );
      final row = DAO.getRowMapFromResult(result);
      return int.tryParse((row?['PRINT_COUNT'] ?? '').toString()) ?? 0;
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static PrintLogQuerySpec buildSumQuery({
    String? startDate,
    String? endDate,
    String? customerName,
    String? labelSizeName,
  }) {
    final params = <String, dynamic>{};
    final conditions = <String>[];
    if (startDate != null && endDate != null) {
      conditions.add(
        'AND RICH_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate) '
        'AND CONVERT(VARCHAR(8), @endDate)',
      );
      params['startDate'] = startDate;
      params['endDate'] = endDate;
    }
    if (customerName != null) {
      conditions.add('AND RICH_CUSTOMER_NAME=@customerName');
      params['customerName'] = customerName;
    }
    if (labelSizeName != null) {
      conditions.add('AND RICH_LABELSIZE_NAME=@labelSizeName');
      params['labelSizeName'] = labelSizeName;
    }
    return PrintLogQuerySpec(
      sql: '$sumSql ${conditions.join(' ')}',
      params: params,
    );
  }
}
