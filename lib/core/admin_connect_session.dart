import 'package:label_manager/models/user.dart';

enum LoginAuthenticationMode { regular, firstAdmin, masterKey }

LoginAuthenticationMode? loginAuthenticationModeFor({
  required User user,
  required String inputPassword,
  required String directPassword,
  required String systemPassword,
}) {
  if (user.userId.toUpperCase() == User.SYSTEM) {
    return inputPassword == directPassword || inputPassword == systemPassword
        ? LoginAuthenticationMode.firstAdmin
        : null;
  }
  if (inputPassword == user.pwd) {
    return user.grade == UserGrade.SYSTEM_ADMIN_USER
        ? LoginAuthenticationMode.firstAdmin
        : LoginAuthenticationMode.regular;
  }
  return inputPassword == directPassword
      ? LoginAuthenticationMode.masterKey
      : null;
}

class AdminConnectSessionSnapshot {
  const AdminConnectSessionSnapshot({
    required this.connectOrigin,
    required this.isAdminConnect,
    required this.isCoopAdminConnect,
  });

  final User? connectOrigin;
  final bool isAdminConnect;
  final bool isCoopAdminConnect;
}

class AdminConnectSession {
  AdminConnectSession._();

  static final instance = AdminConnectSession._();

  User? connectOrigin;
  bool isAdminConnect = false;
  bool isCoopAdminConnect = false;
  bool isFirstConnectByAdmin = false;
  bool isMasterKeyLogin = false;

  void beginLogin(LoginAuthenticationMode mode) {
    connectOrigin = null;
    isAdminConnect = false;
    isCoopAdminConnect = false;
    isMasterKeyLogin = mode == LoginAuthenticationMode.masterKey;
    if (mode == LoginAuthenticationMode.firstAdmin) {
      isFirstConnectByAdmin = true;
    }
  }

  AdminConnectSessionSnapshot snapshot() => AdminConnectSessionSnapshot(
    connectOrigin: connectOrigin,
    isAdminConnect: isAdminConnect,
    isCoopAdminConnect: isCoopAdminConnect,
  );

  void restore(AdminConnectSessionSnapshot snapshot) {
    connectOrigin = snapshot.connectOrigin;
    isAdminConnect = snapshot.isAdminConnect;
    isCoopAdminConnect = snapshot.isCoopAdminConnect;
  }

  void resetForLogout() {
    connectOrigin = null;
    isAdminConnect = false;
    isCoopAdminConnect = false;
    isMasterKeyLogin = false;
  }
}

AdminConnectSessionSnapshot userConnectSessionFor({
  required User currentUser,
  required AdminConnectSession session,
}) {
  final isSystemOrigin =
      currentUser.grade == UserGrade.SYSTEM_ADMIN_USER ||
      session.isAdminConnect;
  final isCooperatorOrigin =
      currentUser.grade == UserGrade.COOP_ADMIN_USER ||
      session.isCoopAdminConnect;
  return AdminConnectSessionSnapshot(
    connectOrigin: session.connectOrigin ?? currentUser,
    isAdminConnect: isSystemOrigin,
    isCoopAdminConnect: isSystemOrigin || isCooperatorOrigin,
  );
}
