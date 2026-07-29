// ignore_for_file: constant_identifier_names

import 'package:label_manager/models/user.dart';

enum LoginCondition {
  LOGIN(0),
  LOGOUT(1);

  final int code;
  const LoginCondition(this.code);

  static LoginCondition fromCode(int code) =>
      LoginCondition.values.firstWhere((value) => value.code == code);
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
