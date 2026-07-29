// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/automatic_item_update/domain/update_item.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class UpdateItemDAO extends DAO {
  static const String SelectSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_UPDATE_ITEM_ID), N'') AS UPDATE_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_ITEM_ID), N'') AS ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(100), P2.RICH_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LABELSIZE_ID), N'') AS LABEL_SIZE_ID,
      COALESCE(CONVERT(NVARCHAR(MAX), P1.RICH_ELEMENT COLLATE ${DAO.CP949}), N'') AS ELEMENT,
      COALESCE(CONVERT(NVARCHAR(MAX), P1.RICH_ELEMENT_RTF COLLATE ${DAO.CP949}), N'') AS ELEMENT_RTF,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_PRICE), N'') AS PRICE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_APPLY_DATE, 112), N'') AS APPLY_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_IS_APPLY), N'') AS IS_APPLY
     FROM BM_UPDATE_ITEM P1
    INNER JOIN BM_RICH_ITEM P2
       ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID



  ''';

  static const String WhereSqlByLabelSizeId = '''
	  WHERE P1.RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String AndSqlByIsApply = '''
	  AND P1.RICH_IS_APPLY=@isApply
  ''';

  static const String AndSqlBeforeTheDate = '''
	  AND CONVERT(VARCHAR,P1.RICH_APPLY_DATE,112)<='%s'
  ''';




  static const String OrderSqlByUpdateItemrder = '''
	  ORDER BY P1.RICH_UPDATE_ITEM_ID ASC
  ''';

  static const String SelectPendingByLabelSizeIdSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_UPDATE_ITEM_ID), N'') AS UPDATE_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_ITEM_ID), N'') AS ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(100), P2.RICH_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_LABELSIZE_ID), N'') AS LABEL_SIZE_ID,
      COALESCE(CONVERT(NVARCHAR(MAX), P1.RICH_ELEMENT COLLATE ${DAO.CP949}), N'') AS ELEMENT,
      COALESCE(CONVERT(NVARCHAR(MAX), P1.RICH_ELEMENT_RTF COLLATE ${DAO.CP949}), N'') AS ELEMENT_RTF,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_PRICE), N'') AS PRICE,
      COALESCE(CONVERT(NVARCHAR(8), P1.RICH_APPLY_DATE, 112), N'') AS APPLY_DATE,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_IS_APPLY), N'') AS IS_APPLY
    FROM BM_UPDATE_ITEM P1
    INNER JOIN BM_RICH_ITEM P2
      ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID
    WHERE P1.RICH_LABELSIZE_ID=@labelSizeId
      AND P1.RICH_IS_APPLY=@isApply
    ORDER BY P1.RICH_UPDATE_ITEM_ID ASC
  ''';

  static const String SelectServerTodaySql = '''
    SELECT CONVERT(CHAR(8), GETDATE(), 112) AS SERVER_TODAY
  ''';

  static Map<String, dynamic> pendingByLabelSizeParams(int labelSizeId) => {
    'labelSizeId': labelSizeId,
    'isApply': 0,
  };

  static Future<List<UpdateItem>> selectPendingByLabelSizeId(
    int labelSizeId,
  ) async {
    if (labelSizeId <= 0) {
      throw ArgumentError.value(labelSizeId, 'labelSizeId', 'Must be positive.');
    }
    debugLog('$START, labelSizeId:$labelSizeId, isApply:0');
    try {
      final res = await DbClient.instance.getDataWithParams(
        SelectPendingByLabelSizeIdSql,
        pendingByLabelSizeParams(labelSizeId),
      );
      final updateItems = DAO.mapRows(res, UpdateItem.fromMap);
      debugLog(END);
      return updateItems;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<DateTime> selectServerToday() async {
    debugLog(START);
    try {
      final res = await DbClient.instance.getData(SelectServerTodaySql);
      final rows = DAO.getRowsFromResult(res);
      if (rows.isEmpty) {
        throw StateError('Server today query returned no rows.');
      }
      final text = (rows.first as Map<String, dynamic>)['SERVER_TODAY']
          ?.toString()
          .trim();
      final date = text == null ? null : parseUpdateItemApplyDate(text);
      if (date == null) {
        throw FormatException('Invalid SERVER_TODAY: $text');
      }
      debugLog(END);
      return date;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<List<UpdateItem>?> selectByCustomerIdByUpdateItemOrder(
    int customerId,
  ) async {
    debugLog('$START, customerId:$customerId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql   $OrderSqlByUpdateItemrder',
        { 'customerId': customerId }
      );

      final updateItems = DAO.mapRows(res, UpdateItem.fromMap);

      debugLog(END);
      return updateItems;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }
}
