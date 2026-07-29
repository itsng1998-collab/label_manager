import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/content_save_history/domain/content_save_log.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class ContentSaveLogDAO extends DAO {
  static const String selectBetweenDatesAndCustomerSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), CONTENT_SAVE_LOG_ID), N'') AS LOG_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_GRADE COLLATE ${DAO.CP949}), N'') AS USER_GRADE,
      COALESCE(CONVERT(NVARCHAR(20), CUST_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), CUST_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME,
      COALESCE(CONVERT(NVARCHAR(50), LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(100), ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(20), GDS_NO), N'') AS GDS_NO,
      COALESCE(CONVERT(NVARCHAR(MAX), CONTENT_COLUMNS COLLATE ${DAO.CP949}), N'') AS CONTENT_COLUMNS,
      COALESCE(CONVERT(NVARCHAR(MAX), CONTENTS COLLATE ${DAO.CP949}), N'') AS CONTENTS,
      COALESCE(CONVERT(NVARCHAR(30), SAVE_DATE, 120), N'') AS SAVE_DATE,
      COALESCE(CONVERT(NVARCHAR(8), SAVE_DATE_YYYYMMDD COLLATE ${DAO.CP949}), N'') AS SAVE_DATE_YYYYMMDD,
      COALESCE(CONVERT(NVARCHAR(100), SAVE_IP COLLATE ${DAO.CP949}), N'') AS SAVE_IP,
      COALESCE(CONVERT(NVARCHAR(20), SAVE_STATUS), N'') AS SAVE_STATUS,
      COALESCE(CONVERT(NVARCHAR(MAX), ELEMENT_DATA COLLATE ${DAO.CP949}), N'') AS ELEMENT_DATA
    FROM BM_CONTENT_SAVE_LOG
    WHERE SAVE_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)
      AND CONVERT(VARCHAR(8), @endDate)
      AND CUST_ID=@customerId
    ORDER BY SAVE_DATE ASC
  ''';

  static Future<List<ContentSaveLog>> selectBetweenDatesAndCustomer({
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
          .map((row) => ContentSaveLog.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }
}
