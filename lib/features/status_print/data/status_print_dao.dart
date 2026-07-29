import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/status_print/domain/status_print.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class StatusPrintDAO extends DAO {
  static String buildSelectQuery(StatusPrintQuerySpec spec) {
    final searchValue = spec.searchesElement
        ? 'COALESCE(CONVERT(NVARCHAR(MAX), S.RICH_PRINT_ITEM_ELEMENT COLLATE ${DAO.CP949}), N\'\')'
        : 'COALESCE(CONVERT(NVARCHAR(MAX), D.RICH_PRINT_COLUMN_DATA COLLATE ${DAO.CP949}), N\'\')';
    final buffer = StringBuffer('''
      SELECT DISTINCT
        COALESCE(CONVERT(NVARCHAR(100), S.RICH_STATUS_ID COLLATE ${DAO.CP949}), N'') AS STATUS_ID,
        S.RICH_PRINT_DATE AS PRINT_DATE,
        COALESCE(CONVERT(NVARCHAR(20), S.RICH_PRINT_COUNT), N'') AS PRINT_COUNT,
        COALESCE(CONVERT(NVARCHAR(300), S.RICH_PRINT_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
        COALESCE(CONVERT(NVARCHAR(MAX), S.RICH_PRINT_ITEM_ELEMENT COLLATE ${DAO.CP949}), N'') AS ITEM_ELEMENT,
        $searchValue AS SEARCH_VALUE,
        COALESCE(CONVERT(NVARCHAR(100), S.RICH_BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME,
        COALESCE(CONVERT(NVARCHAR(100), S.RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
        S.RICH_ID_CHANGE_DELETE_DATE AS ITEM_CHANGE_DELETE_DATE
      FROM BM_RICH_STATUS S
    ''');
    if (!spec.searchesElement) {
      buffer.write('''
        INNER JOIN BM_RICH_STATUS_DATA D ON D.RICH_STATUS_ID=S.RICH_STATUS_ID
      ''');
    }
    buffer.write('''
      WHERE S.RICH_CUSTOMER_ID=@customerId
        AND S.RICH_DATE_YYYYMMDD BETWEEN @startDate AND @endDate
    ''');
    if (spec.brandId != null) {
      buffer.write(' AND S.RICH_BRAND_ID=@brandId');
    }
    if (spec.labelSizeId != null) {
      buffer.write(' AND S.RICH_LABELSIZE_ID=@labelSizeId');
    }
    if (spec.searchesElement) {
      buffer.write(
        spec.exactMatch
            ? ' AND S.RICH_PRINT_ITEM_ELEMENT=@searchText'
            : ' AND S.RICH_PRINT_ITEM_ELEMENT LIKE @searchText',
      );
    } else {
      buffer.write(' AND D.RICH_COLUMN_NAME=@searchColumn');
      if (spec.searchText.isNotEmpty) {
        buffer.write(
          spec.exactMatch
              ? ' AND D.RICH_PRINT_COLUMN_DATA=@searchText'
              : ' AND D.RICH_PRINT_COLUMN_DATA LIKE @searchText',
        );
      }
    }
    if (spec.itemName.isNotEmpty) {
      buffer.write(' AND S.RICH_PRINT_ITEM_NAME LIKE @itemName');
    }
    buffer.write(' ORDER BY S.RICH_PRINT_DATE');
    return buffer.toString();
  }

  static Future<List<StatusPrintRow>> select(StatusPrintQuerySpec spec) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        buildSelectQuery(spec),
        spec.parameters,
      );
      return DAO.mapRows(result, StatusPrintRow.fromMap);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static const String selectDetailItemSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(300), RICH_PRINT_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_PRINT_ITEM_ELEMENT COLLATE ${DAO.CP949}), N'') AS ITEM_ELEMENT,
      RICH_ID_CHANGE_DELETE_DATE AS ITEM_CHANGE_DELETE_DATE
    FROM BM_RICH_STATUS
    WHERE RICH_STATUS_ID=@statusId
  ''';

  static const String selectDetailRowsSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(300), RICH_COLUMN_NAME COLLATE ${DAO.CP949}), N'') AS COLUMN_NAME,
      RICH_COLID_CHANGE_DELETE_DATE AS CHANGE_DELETE_DATE,
      COALESCE(CONVERT(NVARCHAR(MAX), RICH_PRINT_COLUMN_DATA COLLATE ${DAO.CP949}), N'') AS COLUMN_VALUE
    FROM BM_RICH_STATUS_DATA
    WHERE RICH_STATUS_ID=@statusId
  ''';

  static Future<StatusPrintDetail> selectDetail(String statusId) async {
    try {
      final itemResult = await DbClient.instance.getDataWithParams(
        selectDetailItemSql,
        {'statusId': statusId},
      );
      final detailResult = await DbClient.instance.getDataWithParams(
        selectDetailRowsSql,
        {'statusId': statusId},
      );
      final itemRows = DAO.getRowsFromResult(itemResult);
      final item = itemRows.isEmpty
          ? const <String, dynamic>{}
          : Map<String, dynamic>.from(itemRows.first as Map);
      return StatusPrintDetail(
        itemName: (item['ITEM_NAME'] ?? '').toString(),
        itemElement: (item['ITEM_ELEMENT'] ?? '').toString(),
        itemChangeDeleteDate: (item['ITEM_CHANGE_DELETE_DATE'] ?? '')
            .toString(),
        rows: DAO.mapRows(detailResult, StatusPrintDetailRow.fromMap),
      );
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }
}
