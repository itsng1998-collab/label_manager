import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';

import 'dao.dart';

enum PrintLogSearchType { itemName, userId, customerName }

class PrintLogQuerySpec {
  const PrintLogQuerySpec({required this.sql, required this.params});

  final String sql;
  final Map<String, dynamic> params;
}

class PrintLog {
  const PrintLog({
    required this.logId,
    required this.userId,
    required this.userName,
    required this.userGrade,
    required this.marketId,
    required this.marketName,
    required this.customerId,
    required this.customerName,
    required this.brandName,
    required this.labelSizeName,
    required this.itemName,
    required this.printCount,
    required this.dateTime,
    required this.dateYYYYMMDD,
    required this.printerName,
    required this.columnsWire,
    required this.printCellsWire,
    required this.savedCellsWire,
    required this.formWidth,
    required this.formHeight,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.leftPush,
    required this.topPush,
    required this.appendant,
    required this.itemId,
  });

  final int logId;
  final String userId;
  final String userName;
  final int userGrade;
  final int marketId;
  final String marketName;
  final int customerId;
  final String customerName;
  final String brandName;
  final String labelSizeName;
  final String itemName;
  final int printCount;
  final String dateTime;
  final String dateYYYYMMDD;
  final String printerName;
  final String columnsWire;
  final String printCellsWire;
  final String savedCellsWire;
  final int formWidth;
  final int formHeight;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;
  final double appendant;
  final int itemId;

  factory PrintLog.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    double doubleValue(String key) => double.tryParse(stringValue(key)) ?? 0;

    return PrintLog(
      logId: intValue('LOG_ID'),
      userId: stringValue('USER_ID'),
      userName: stringValue('USER_NAME'),
      userGrade: intValue('USER_GRADE'),
      marketId: intValue('MARKET_ID'),
      marketName: stringValue('MARKET_NAME'),
      customerId: intValue('CUSTOMER_ID'),
      customerName: stringValue('CUSTOMER_NAME'),
      brandName: stringValue('BRAND_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      itemName: stringValue('ITEM_NAME'),
      printCount: intValue('PRINT_COUNT'),
      dateTime: stringValue('DATETIME'),
      dateYYYYMMDD: stringValue('DATE_YYYYMMDD'),
      printerName: stringValue('PRINTER'),
      columnsWire: stringValue('COLUMNS'),
      printCellsWire: stringValue('PRINT_CELLS'),
      savedCellsWire: stringValue('SAVE_IN_DB_CELLS'),
      formWidth: intValue('FORM_WIDTH'),
      formHeight: intValue('FORM_HEIGHT'),
      leftMargin: doubleValue('LEFT_MARGIN'),
      rightMargin: doubleValue('RIGHT_MARGIN'),
      topMargin: doubleValue('TOP_MARGIN'),
      leftPush: doubleValue('LEFT_PUSH'),
      topPush: doubleValue('TOP_PUSH'),
      appendant: doubleValue('APPENDANT'),
      itemId: intValue('ITEM_ID'),
    );
  }

  List<String> get columnNames => _splitWire(columnsWire);
  List<String> get printCells => _splitWire(printCellsWire);
  List<String> get savedCells => _splitWire(savedCellsWire);

  static List<String> _splitWire(String value) {
    final parts = value.split('|');
    if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
    return parts;
  }
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
    WHERE RICH_DATE_YYYYMMDD BETWEEN @startDate AND @endDate
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
      conditions.add('AND RICH_DATE_YYYYMMDD BETWEEN @startDate AND @endDate');
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
