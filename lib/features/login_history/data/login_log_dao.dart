import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_result_utils.dart';
import 'package:label_manager/features/login_history/domain/login_log.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:r_get_ip/r_get_ip.dart';

LoginLog loginLogFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();
  int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

  return LoginLog(
    logId: intValue('LOG_ID'),
    userId: stringValue('USER_ID'),
    userGrade: stringValue('USER_GRADE'),
    programVersion: stringValue('PROGRAM_VERSION'),
    customerId: intValue('CUSTOMER_ID'),
    customerName: stringValue('CUSTOMER_NAME'),
    loginDate: stringValue('LOGIN_DATE'),
    loginDateYYYYMMDD: stringValue('LOGIN_DATE_YYYYMMDD'),
    loginIP: stringValue('LOGIN_IP'),
    loginCondition: LoginCondition.fromCode(intValue('LOGIN_CONDITION')),
  );
}

class LoginLogDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), LOGIN_LOG_ID), N'') AS LOG_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_GRADE COLLATE ${DAO.CP949}), N'') AS USER_GRADE,
      COALESCE(CONVERT(NVARCHAR(50), PROGRAM_VERSION COLLATE ${DAO.CP949}), N'') AS PROGRAM_VERSION,
      COALESCE(CONVERT(NVARCHAR(20), CUST_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), CUST_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME,
      COALESCE(CONVERT(NVARCHAR(30), LOGIN_DATE, 120), N'') AS LOGIN_DATE,
      COALESCE(CONVERT(NVARCHAR(8), LOGIN_DATE_YYYYMMDD COLLATE ${DAO.CP949}), N'') AS LOGIN_DATE_YYYYMMDD,
      COALESCE(CONVERT(NVARCHAR(100), LOGIN_IP COLLATE ${DAO.CP949}), N'') AS LOGIN_IP,
      COALESCE(CONVERT(NVARCHAR(20), LOGIN_CONDITION), N'') AS LOGIN_CONDITION
    FROM BM_LOGIN_LOG
  ''';

  static const String whereSqlLogId = '''
    WHERE LOGIN_LOG_ID=@logId
  ''';

  static const String betweenDatesAndCustomerSql =
      '''
    $selectSql
    WHERE LOGIN_DATE_YYYYMMDD BETWEEN @startDate AND @endDate
      AND CUST_ID=@customerId
    ORDER BY LOGIN_DATE ASC
  ''';

  static const String insertSql =
      '''
    INSERT INTO BM_LOGIN_LOG
      (USER_ID,USER_GRADE,PROGRAM_VERSION,CUST_ID,CUST_NAME,
       LOGIN_DATE,LOGIN_DATE_YYYYMMDD,LOGIN_IP,LOGIN_CONDITION,LOGIN_OUTER_IP)
		VALUES
		  (CONVERT(NVARCHAR(30), CONVERT(VARCHAR(30), CONVERT(VARBINARY(100), @userId, 1)) COLLATE ${DAO.CP949}),
       CONVERT(NVARCHAR(20), CONVERT(VARCHAR(20), CONVERT(VARBINARY(100), @userGrade, 1)) COLLATE ${DAO.CP949}),
       CONVERT(NVARCHAR(50), CONVERT(VARCHAR(50), CONVERT(VARBINARY(150), @programVersion, 1)) COLLATE ${DAO.CP949}),
       @customerId,
       CONVERT(NVARCHAR(50), CONVERT(VARCHAR(50), CONVERT(VARBINARY(150), @customerName, 1)) COLLATE ${DAO.CP949}),
       @loginDate,
       CONVERT(NVARCHAR(8), CONVERT(VARCHAR(8), CONVERT(VARBINARY(30), @loginDateYYYYMMDD, 1)) COLLATE ${DAO.CP949}),
        CONVERT(NVARCHAR(100), CONVERT(VARCHAR(100), CONVERT(VARBINARY(100), @loginIP, 1)) COLLATE ${DAO.CP949}),
       @loginCondition,
        CONVERT(VARCHAR(48), CONNECTIONPROPERTY('client_net_address')))
  ''';

  static Future<LoginLog?> selectByLogId(int logId) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlLogId',
        {'logId': logId},
      );

      final row = DAO.getRowMapFromResult(result);
      return loginLogFromRow(row!);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static Future<List<LoginLog>> selectBetweenDatesAndCustomer({
    required String startDate,
    required String endDate,
    required int customerId,
  }) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        betweenDatesAndCustomerSql,
        {'startDate': startDate, 'endDate': endDate, 'customerId': customerId},
      );
      return DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => loginLogFromRow(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static Future<void> insertLoginLog({
    required String userId,
    required UserGrade userGrade,
    required int customerId,
    required String customerName,
    required LoginCondition loginCondition,
  }) async {
    debugLog(START);

    try {
      final now = DateTime.now();
      final localIp = await RGetIp.internalIP;
      final hexUserId = await stringToHexCp949(userId);
      final hexUserGrade = await stringToHexCp949(userGrade.label);
      final hexProgramVersion = await stringToHexCp949(appVersion);
      final hexCustomerName = await stringToHexCp949(customerName);
      final osLocale = ui.PlatformDispatcher.instance.locale.toString();
      final loginDate = DateFormat('yyyy-MM-dd HH:mm:ss', osLocale).format(now);
      final hexLoginDateYYYYMMDD = await stringToHexCp949(
        DateFormat('yyyyMMdd', osLocale).format(now),
      );
      final hexLoginIP = await stringToHexCp949(localIp!);

      await DbClient.instance.writeDataWithParams(insertSql, {
        'userId': hexUserId,
        'userGrade': hexUserGrade,
        'programVersion': hexProgramVersion,
        'customerId': customerId,
        'customerName': hexCustomerName,
        'loginDate': loginDate,
        'loginDateYYYYMMDD': hexLoginDateYYYYMMDD,
        'loginIP': hexLoginIP,
        'loginCondition': loginCondition.code,
      });

      debugLog(END);
    } catch (error) {
      debugLog('$error');
      throw Exception('${runtimeLogTag()} $error');
    }
  }

  static Future<void> insertExitLogoutLog(ExitLogoutLogSnapshot snapshot) =>
      insertLoginLog(
        userId: snapshot.userId,
        userGrade: snapshot.userGrade,
        customerId: snapshot.customerId,
        customerName: snapshot.customerName,
        loginCondition: LoginCondition.LOGOUT,
      );
}
