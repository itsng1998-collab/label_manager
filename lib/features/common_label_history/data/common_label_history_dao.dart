import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/common_label_history/domain/common_label_history.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class CommonLabelHistoryDAO extends DAO {
  static const String selectBetweenDatesAndCustomerSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), A.RICH_MOD_LOG_ID), N'') AS LOG_ID,
      COALESCE(CONVERT(NVARCHAR(30), A.RICH_MOD_DATETIME, 120), N'') AS MODIFIED_AT,
      COALESCE(CONVERT(NVARCHAR(30), A.RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(50), B.RICH_BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME,
      COALESCE(CONVERT(NVARCHAR(50), A.RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(20), A.RICH_FORM_WIDTH), N'') AS BEFORE_WIDTH,
      COALESCE(CONVERT(NVARCHAR(20), A.RICH_FORM_HEIGHT), N'') AS BEFORE_HEIGHT,
      COALESCE(CONVERT(NVARCHAR(MAX), A.RICH_FORM_DATA COLLATE ${DAO.CP949}), N'') AS BEFORE_FORM_DATA,
      COALESCE(CONVERT(NVARCHAR(MAX), A.RICH_FORM_SHEET), N'') AS BEFORE_FORM_SHEET,
      COALESCE(CONVERT(NVARCHAR(20), A.RICH_ALTER_FORM_WIDTH), N'') AS AFTER_WIDTH,
      COALESCE(CONVERT(NVARCHAR(20), A.RICH_ALTER_FORM_HEIGHT), N'') AS AFTER_HEIGHT,
      COALESCE(CONVERT(NVARCHAR(MAX), A.RICH_ALTER_FORM_DATA COLLATE ${DAO.CP949}), N'') AS AFTER_FORM_DATA,
      COALESCE(CONVERT(NVARCHAR(MAX), A.RICH_ALTER_FORM_SHEET), N'') AS AFTER_FORM_SHEET,
      COALESCE(CONVERT(NVARCHAR(100), A.RICH_INNER_IP COLLATE ${DAO.CP949}), N'') AS INNER_IP,
      COALESCE(CONVERT(NVARCHAR(48), A.RICH_OUTER_IP COLLATE ${DAO.CP949}), N'') AS OUTER_IP
    FROM BM_RICH_LABELSIZE_FORM_LOG A
    INNER JOIN BM_RICH_BRAND B ON A.RICH_BRAND_ID=B.RICH_BRAND_ID
    WHERE A.RICH_MOD_DATE BETWEEN @startDate AND @endDate
      AND B.RICH_CUSTOMER_ID=@customerId
  ''';

  static Future<List<CommonLabelHistory>> selectBetweenDatesAndCustomer({
    required String startDate,
    required String endDate,
    required int customerId,
  }) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        selectBetweenDatesAndCustomerSql,
        {'startDate': startDate, 'endDate': endDate, 'customerId': customerId},
      );
      return DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map(
            (row) => CommonLabelHistory.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }
}
