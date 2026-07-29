import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

User userFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();
  int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

  return User(
    userId: stringValue('USER_ID'),
    marketId: intValue('MARKET_ID'),
    name: stringValue('NAME'),
    pwd: stringValue('PASSWORD'),
    grade: UserGrade.fromCode(intValue('GRADE')),
    marketName: stringValue('MARKET_NAME'),
    customerName: stringValue('CUSTOMER_NAME'),
  );
}

class UserDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(30), P1.RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_MARKET_ID), N'') as MARKET_ID,
      COALESCE(CONVERT(NVARCHAR(50), P1.RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_PWD COLLATE ${DAO.CP949}), N'') AS PASSWORD,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USER_GRADE), N'') AS GRADE,
      COALESCE(CONVERT(NVARCHAR(50), P2.RICH_NAME COLLATE ${DAO.CP949}), N'') AS MARKET_NAME,
      COALESCE(CONVERT(NVARCHAR(50), P3.RICH_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME
    FROM BM_USER P1
    INNER JOIN BM_MARKET P2 ON P1.RICH_MARKET_ID=P2.RICH_MARKET_ID
    INNER JOIN BM_CUSTOMER P3 ON P2.RICH_CUSTOMER_ID=P3.RICH_CUSTOMER_ID
    INNER JOIN BM_COOPERATOR P4 ON P3.RICH_COOP_ID=P4.RICH_COOP_ID
  ''';

  static const String whereSqlUserId =
      '''
    WHERE LTRIM(RTRIM(CONVERT(NVARCHAR(30),P1.RICH_USER_ID COLLATE ${DAO.CP949}))) =
          LTRIM(RTRIM(CONVERT(NVARCHAR(30),@userId)))
  ''';

  static Future<User?> selectByUserId(String userId) async {
    debugLog('$START, userId:$userId');
    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlUserId',
        {'userId': userId},
      );
      final row = DAO.getRowMapFromResult(result);
      debugLog(END);
      return userFromRow(row!);
    } catch (error) {
      debugLog('$END, $error');
      throw Exception('${runtimeLogTag()} $error');
    }
  }
}
