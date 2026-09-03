import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/core/user.dart';

void main() {
  test('direct password combines padded day and calculated value', () {
    expect(directPasswordForDate(DateTime(2025, 1, 2)), '0205');
    expect(directPasswordForDate(DateTime(2025, 12, 31)), '3167');
  });

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
        user: _user('coop-admin', UserGrade.COOP_ADMIN_USER, 'own'),
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
    expect(
      loginAuthenticationModeFor(
        user: _user('client', UserGrade.CLIENT_USER, 'own'),
        inputPassword: 'system',
        directPassword: 'direct',
        systemPassword: 'system',
      ),
      LoginAuthenticationMode.masterKey,
    );
    expect(
      loginAuthenticationModeFor(
        user: _user('SYSTEM', UserGrade.SYSTEM_ADMIN_USER, 'own'),
        inputPassword: 'system',
        directPassword: 'direct',
        systemPassword: 'system',
      ),
      LoginAuthenticationMode.masterKey,
    );
  });

  test('user credentials are visible for grade zero or one', () {
    expect(
      userCredentialsVisibleFor(
        userGrade: UserGrade.SYSTEM_ADMIN_USER,
        isFirstConnectByAdmin: false,
      ),
      isTrue,
    );
    expect(
      userCredentialsVisibleFor(
        userGrade: UserGrade.COOP_ADMIN_USER,
        isFirstConnectByAdmin: false,
      ),
      isTrue,
    );
    expect(
      userCredentialsVisibleFor(
        userGrade: UserGrade.MANAGER_USER,
        isFirstConnectByAdmin: false,
      ),
      isFalse,
    );
    expect(
      userCredentialsVisibleFor(
        userGrade: UserGrade.CLIENT_USER,
        isFirstConnectByAdmin: true,
      ),
      isTrue,
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

  test('user connect preserves the first admin login context', () {
    final session = AdminConnectSession.instance;
    session.beginLogin(LoginAuthenticationMode.firstAdmin);
    final admin = _user('admin', UserGrade.SYSTEM_ADMIN_USER, 'own');

    final first = userConnectSessionFor(
      currentUser: admin,
      currentCustomerId: 10,
      currentCustomerName: '원 거래처',
      session: session,
    );
    session.restore(first);
    final second = userConnectSessionFor(
      currentUser: _user('target', UserGrade.CLIENT_USER, 'pw'),
      currentCustomerId: 20,
      currentCustomerName: '대상 거래처',
      session: session,
    );

    expect(second.connectOrigin, admin);
    expect(second.connectOriginCustomerId, 10);
    expect(second.connectOriginCustomerName, '원 거래처');
    expect(second.isAdminConnect, isTrue);
    expect(second.isCoopAdminConnect, isTrue);
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
