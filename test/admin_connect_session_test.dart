import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/models/user.dart';

void main() {
  test('login authentication separates first admin and master key', () {
    expect(
      loginAuthenticationModeFor(
        user: _user('SYSTEM', UserGrade.SYSTEM_ADMIN_USER, 'own'),
        inputPassword: 'direct',
        directPassword: 'direct',
        systemPassword: 'system',
      ),
      LoginAuthenticationMode.firstAdmin,
    );
    expect(
      loginAuthenticationModeFor(
        user: _user('admin', UserGrade.SYSTEM_ADMIN_USER, 'own'),
        inputPassword: 'own',
        directPassword: 'direct',
        systemPassword: 'system',
      ),
      LoginAuthenticationMode.firstAdmin,
    );
    expect(
      loginAuthenticationModeFor(
        user: _user('client', UserGrade.CLIENT_USER, 'own'),
        inputPassword: 'direct',
        directPassword: 'direct',
        systemPassword: 'system',
      ),
      LoginAuthenticationMode.masterKey,
    );
  });

  test('logout keeps first admin but clears transient connect state', () {
    final session = AdminConnectSession.instance;
    session.beginLogin(LoginAuthenticationMode.firstAdmin);
    session.connectOrigin = _user('admin', UserGrade.SYSTEM_ADMIN_USER, 'own');
    session.isAdminConnect = true;
    session.resetForLogout();

    expect(session.isFirstConnectByAdmin, isTrue);
    expect(session.connectOrigin, isNull);
    expect(session.isAdminConnect, isFalse);
    expect(session.isMasterKeyLogin, isFalse);
  });

}

User _user(String id, UserGrade grade, String password) => User(
  userId: id,
  marketId: 1,
  name: id,
  pwd: password,
  grade: grade,
  marketName: '',
  customerName: '',
);
