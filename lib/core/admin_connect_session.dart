import 'package:label_manager/core/user.dart';

enum LoginAuthenticationMode { regular, firstAdmin, masterKey }

bool isAdministratorGrade(UserGrade? grade) =>
    grade == UserGrade.SYSTEM_ADMIN_USER ||
    grade == UserGrade.COOP_ADMIN_USER;

bool userCredentialsVisibleFor({
  required UserGrade? userGrade,
  required bool isFirstConnectByAdmin,
}) =>
    isAdministratorGrade(userGrade) || isFirstConnectByAdmin;

LoginAuthenticationMode? loginAuthenticationModeFor({
  required User user,
  required String inputPassword,
  required String directPassword,
  required String systemPassword,
}) {
  if (user.userId.toUpperCase() == User.SYSTEM) {
    if (inputPassword == systemPassword) {
      return LoginAuthenticationMode.masterKey;
    }
    return inputPassword == directPassword
        ? LoginAuthenticationMode.firstAdmin
        : null;
  }
  if (inputPassword == user.pwd) {
    return isAdministratorGrade(user.grade)
        ? LoginAuthenticationMode.firstAdmin
        : LoginAuthenticationMode.regular;
  }
  return inputPassword == directPassword || inputPassword == systemPassword
      ? LoginAuthenticationMode.masterKey
      : null;
}

class AdminConnectSessionSnapshot {
  const AdminConnectSessionSnapshot({
    required this.connectOrigin,
    required this.connectOriginCustomerId,
    required this.connectOriginCustomerName,
    required this.isAdminConnect,
    required this.isCoopAdminConnect,
  });

  final User? connectOrigin;
  final int? connectOriginCustomerId;
  final String? connectOriginCustomerName;
  final bool isAdminConnect;
  final bool isCoopAdminConnect;
}

class AdminConnectSession {
  AdminConnectSession._();

  static final instance = AdminConnectSession._();

  User? connectOrigin;
  int? connectOriginCustomerId;
  String? connectOriginCustomerName;
  bool isAdminConnect = false;
  bool isCoopAdminConnect = false;
  bool isFirstConnectByAdmin = false;
  bool isMasterKeyLogin = false;

  void beginLogin(LoginAuthenticationMode mode) {
    connectOrigin = null;
    connectOriginCustomerId = null;
    connectOriginCustomerName = null;
    isAdminConnect = false;
    isCoopAdminConnect = false;
    isMasterKeyLogin = mode == LoginAuthenticationMode.masterKey;
    if (mode == LoginAuthenticationMode.firstAdmin) {
      isFirstConnectByAdmin = true;
    }
  }

  AdminConnectSessionSnapshot snapshot() => AdminConnectSessionSnapshot(
    connectOrigin: connectOrigin,
    connectOriginCustomerId: connectOriginCustomerId,
    connectOriginCustomerName: connectOriginCustomerName,
    isAdminConnect: isAdminConnect,
    isCoopAdminConnect: isCoopAdminConnect,
  );

  void restore(AdminConnectSessionSnapshot snapshot) {
    connectOrigin = snapshot.connectOrigin;
    connectOriginCustomerId = snapshot.connectOriginCustomerId;
    connectOriginCustomerName = snapshot.connectOriginCustomerName;
    isAdminConnect = snapshot.isAdminConnect;
    isCoopAdminConnect = snapshot.isCoopAdminConnect;
  }

  void resetForLogout() {
    connectOrigin = null;
    connectOriginCustomerId = null;
    connectOriginCustomerName = null;
    isAdminConnect = false;
    isCoopAdminConnect = false;
    isMasterKeyLogin = false;
  }
}

AdminConnectSessionSnapshot userConnectSessionFor({
  required User currentUser,
  required int currentCustomerId,
  required String currentCustomerName,
  required AdminConnectSession session,
}) {
  final isSystemOrigin =
      currentUser.grade == UserGrade.SYSTEM_ADMIN_USER ||
      session.isAdminConnect;
  return AdminConnectSessionSnapshot(
    connectOrigin: session.connectOrigin ?? currentUser,
    connectOriginCustomerId:
        session.connectOriginCustomerId ?? currentCustomerId,
    connectOriginCustomerName:
        session.connectOriginCustomerName ?? currentCustomerName,
    isAdminConnect: isSystemOrigin,
    isCoopAdminConnect: isSystemOrigin,
  );
}
