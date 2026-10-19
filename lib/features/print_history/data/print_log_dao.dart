import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/print_history/domain/print_log.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/regression_debug_log.dart';

class PrintLogQuerySpec {
  const PrintLogQuerySpec({required this.sql, required this.params});

  final String sql;
  final Map<String, dynamic> params;
}

class PrintLogDAO extends DAO {
  static const String queryIndexCheckSql = '''
    SELECT CASE WHEN EXISTS (
      SELECT 1 FROM sys.indexes i
      WHERE i.object_id=OBJECT_ID(N'BM_RICH_PRINT_LOG', N'U')
        AND i.name=N'IX_BM_RICH_PRINT_LOG_CustomerDate'
        AND i.is_disabled=0 AND i.is_hypothetical=0 AND i.has_filter=0
        AND EXISTS (
          SELECT 1 FROM sys.index_columns ic
          JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
          WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id
            AND ic.key_ordinal=1 AND c.name=N'RICH_CUSTOMER_ID'
        )
        AND EXISTS (
          SELECT 1 FROM sys.index_columns ic
          JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
          WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id
            AND ic.key_ordinal=2 AND c.name=N'RICH_DATE_YYYYMMDD'
        )
        AND EXISTS (
          SELECT 1 FROM sys.index_columns ic
          JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
          WHERE ic.object_id=i.object_id AND ic.index_id=i.index_id
            AND c.name=N'RICH_DATETIME'
        )
    ) THEN 1 ELSE 0 END AS INDEX_READY;
  ''';

  static const String createQueryIndexSql = '''
    SET NOCOUNT ON;
    DECLARE @objectId INT=OBJECT_ID(N'BM_RICH_PRINT_LOG', N'U');
    IF @objectId IS NULL
    BEGIN
      RAISERROR(N'발행내역 테이블을 찾을 수 없습니다.', 16, 1);
      RETURN;
    END;
    BEGIN TRY
      IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id=@objectId AND name=N'IX_BM_RICH_PRINT_LOG_CustomerDate'
      )
      BEGIN
        DECLARE @sql NVARCHAR(MAX)=
          N'CREATE NONCLUSTERED INDEX [IX_BM_RICH_PRINT_LOG_CustomerDate] ON ' +
          QUOTENAME(OBJECT_SCHEMA_NAME(@objectId)) + N'.' +
          QUOTENAME(OBJECT_NAME(@objectId)) +
          N' ([RICH_CUSTOMER_ID], [RICH_DATE_YYYYMMDD]) INCLUDE ([RICH_DATETIME]);';
        EXEC sys.sp_executesql @sql;
      END;
    END TRY
    BEGIN CATCH
      -- Another session may have created the index; verify its state afterwards.
      IF ERROR_NUMBER()<>1913
        THROW;
    END CATCH;
  ''';

  static Future<void> ensureQueryIndex({
    void Function()? onCreating,
    Future<Object> Function(String sql)? read,
    Future<Object> Function(String sql)? write,
  }) async {
    final readData = read ?? DbClient.instance.getData;
    final writeData = write ?? DbClient.instance.writeData;
    final watch = Stopwatch()..start();
    RegressionDebugLog.event('printHistoryQuery', 'indexCheckStarted');
    if (printHistoryQueryIndexReady(await readData(queryIndexCheckSql))) {
      RegressionDebugLog.event(
        'printHistoryQuery',
        'indexReady',
        fields: {'created': false, 'elapsedMs': watch.elapsedMilliseconds},
      );
      return;
    }
    onCreating?.call();
    RegressionDebugLog.event('printHistoryQuery', 'indexCreating');
    await writeData(createQueryIndexSql);
    if (!printHistoryQueryIndexReady(await readData(queryIndexCheckSql))) {
      throw StateError('발행내역 조회 인덱스가 준비되지 않았습니다. 인덱스 상태와 권한을 확인해주세요.');
    }
    RegressionDebugLog.event(
      'printHistoryQuery',
      'indexReady',
      fields: {'created': true, 'elapsedMs': watch.elapsedMilliseconds},
    );
  }

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

  static const String summarySql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(50), RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      SUM(RICH_PRINT_COUNT) AS TOTAL_PRINT_COUNT,
      SUM(CASE WHEN RICH_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)
        AND CONVERT(VARCHAR(8), @endDate) THEN RICH_PRINT_COUNT ELSE 0 END) AS PERIOD_PRINT_COUNT
    FROM BM_RICH_PRINT_LOG
    WHERE 1=1
  ''';

  static const String detailSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_COLUMNS COLLATE ${DAO.CP949}), N'') AS COLUMNS,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_PRINT_CELLS COLLATE ${DAO.CP949}), N'') AS PRINT_CELLS,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_SAVE_IN_DB_CELLS COLLATE ${DAO.CP949}), N'') AS SAVE_IN_DB_CELLS
    FROM BM_RICH_PRINT_LOG
    WHERE RICH_PRINT_LOG_ID=@logId
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
    };
    final condition = switch (searchType) {
      PrintLogSearchType.itemName when searchText.isEmpty => '',
      PrintLogSearchType.itemName =>
        "AND RICH_ITEM_NAME LIKE N'%' + @searchText + N'%'",
      PrintLogSearchType.userId => 'AND RICH_USER_ID=@searchText',
      PrintLogSearchType.customerName => 'AND RICH_CUSTOMER_NAME=@searchText',
    };
    if (condition.isNotEmpty) params['searchText'] = searchText;
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

  static Future<List<PrintLogSummary>> selectSummary({
    required String startDate,
    required String endDate,
    String? customerName,
  }) async {
    final spec = buildSummaryQuery(
      startDate: startDate,
      endDate: endDate,
      customerName: customerName,
    );
    try {
      final result = await DbClient.instance.getDataWithParams(
        spec.sql,
        spec.params,
      );
      return DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map(
            (row) => PrintLogSummary.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static Future<PrintLogDetail?> selectDetail(int logId) async {
    final spec = buildDetailQuery(logId);
    try {
      final result = await DbClient.instance.getDataWithParams(
        spec.sql,
        spec.params,
      );
      final row = DAO.getRowMapFromResult(result);
      return row == null ? null : PrintLogDetail.fromMap(row);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static PrintLogQuerySpec buildDetailQuery(int logId) => PrintLogQuerySpec(
    sql: detailSql,
    params: {'logId': logId},
  );

  static PrintLogQuerySpec buildSummaryQuery({
    required String startDate,
    required String endDate,
    String? customerName,
  }) {
    final params = <String, dynamic>{
      'startDate': startDate,
      'endDate': endDate,
    };
    final customerCondition = customerName == null
        ? ''
        : 'AND RICH_CUSTOMER_NAME=@customerName';
    if (customerName != null) params['customerName'] = customerName;
    return PrintLogQuerySpec(
      sql:
          '$summarySql $customerCondition '
          'GROUP BY RICH_LABELSIZE_NAME ORDER BY RICH_LABELSIZE_NAME',
      params: params,
    );
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

bool printHistoryQueryIndexReady(Object result) {
  final row = DAO.getRowMapFromResult(result)!;
  return switch (row['INDEX_READY']) {
    1 || '1' || true => true,
    0 || '0' || false => false,
    _ => throw FormatException('발행내역 인덱스 확인 결과가 올바르지 않습니다.'),
  };
}
