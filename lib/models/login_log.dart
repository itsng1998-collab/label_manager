// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names

import 'dart:ui' as ui;

import 'package:intl/intl.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_result_utils.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:r_get_ip/r_get_ip.dart';
import 'dao.dart';
import 'user.dart';

enum LoginCondition {
	LOGIN(0),
	LOGOUT(1);

  final int code;
  const LoginCondition(this.code);
  static LoginCondition fromCode(int code) => LoginCondition.values.firstWhere((e) => e.code == code);
}

class LoginLog {
 	final int logId;
	final String userId;
  final String userGrade;
	final String programVersion;
	final int customerId;
	final String customerName;
	final String loginDate;
	final String loginDateYYYYMMDD;
	final String loginIP;
	final LoginCondition loginCondition;

  const LoginLog({
    required this.logId,
    required this.userId,
    required this.userGrade,
    required this.programVersion,
    required this.customerId,
    required this.customerName,
    required this.loginDate,
    required this.loginDateYYYYMMDD,
    required this.loginIP,
    required this.loginCondition,
  });

  factory LoginLog.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return LoginLog(
      logId:              i('LOG_ID'),
      userId:             s('USER_ID'),
      userGrade:          s('USER_GRADE'),
      programVersion:     s('PROGRAM_VERSION'),
      customerId:         i('CUSTOMER_ID'),
      customerName:       s('CUSTOMER_NAME'),
      loginDate:          s('LOGIN_DATE'),
      loginDateYYYYMMDD:  s('LOGIN_DATE_YYYYMMDD'),
      loginIP:            s('LOGIN_IP'),
      loginCondition:     LoginCondition.fromCode(i('LOGIN_CONDITION')),
    );
  }
}

class ExitLogoutLogSnapshot {
  const ExitLogoutLogSnapshot({
    required this.userId,
    required this.userGrade,
    required this.customerId,
    required this.customerName,
  });

  final String userId;
  final UserGrade userGrade;
  final int customerId;
  final String customerName;
}

ExitLogoutLogSnapshot? exitLogoutLogSnapshotFor({
  required bool loggedIn,
  required bool isDisconnect,
  required bool isMasterKeyLogin,
  required User? user,
  required int? customerId,
  required String? customerName,
}) {
  if (!loggedIn || !isDisconnect || isMasterKeyLogin) return null;
  if (user == null || customerId == null || customerName == null) return null;
  return ExitLogoutLogSnapshot(
    userId: user.userId,
    userGrade: user.grade,
    customerId: customerId,
    customerName: customerName,
  );
}

class LoginLogDAO extends DAO {
  static const String SelectSql = '''
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

  static const String WhereSqlLogId = '''
    WHERE LOGIN_LOG_ID=@logId
  ''';

  static const String BetweenDatesAndCustomerSql = '''
    $SelectSql
    WHERE LOGIN_DATE_YYYYMMDD BETWEEN @startDate AND @endDate
      AND CUST_ID=@customerId
    ORDER BY LOGIN_DATE ASC
  ''';

  static const String InsertSql = '''
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
			final res = await DbClient.instance.getDataWithParams(
				'$SelectSql $WhereSqlLogId', { 'logId': logId }
			);

      final map = DAO.getRowMapFromResult(res);
      return LoginLog.fromMap(map!);
    }
    catch (e) {
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<List<LoginLog>> selectBetweenDatesAndCustomer({
    required String startDate,
    required String endDate,
    required int customerId,
  }) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        BetweenDatesAndCustomerSql,
        {
          'startDate': startDate,
          'endDate': endDate,
          'customerId': customerId,
        },
      );
      return DAO.getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => LoginLog.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (e) {
      throw Exception('${runtimeLogTag()} $e');
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
      final hexLoginDateYYYYMMDD = await stringToHexCp949(DateFormat('yyyyMMdd', osLocale).format(now));
      final hexLoginIP = await stringToHexCp949(localIp!);

      await DbClient.instance.writeDataWithParams(
        InsertSql,
        {
          'userId': hexUserId,
          'userGrade': hexUserGrade,
          'programVersion': hexProgramVersion,
          'customerId': customerId,
          'customerName': hexCustomerName,
          'loginDate': loginDate,
          'loginDateYYYYMMDD': hexLoginDateYYYYMMDD,
          'loginIP': hexLoginIP,
          'loginCondition': loginCondition.code,
        },
      );

      debugLog(END);
    }
    catch (e) {
      debugLog('$e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> insertExitLogoutLog(
    ExitLogoutLogSnapshot snapshot,
  ) => insertLoginLog(
    userId: snapshot.userId,
    userGrade: snapshot.userGrade,
    customerId: snapshot.customerId,
    customerName: snapshot.customerName,
    loginCondition: LoginCondition.LOGOUT,
  );
}
