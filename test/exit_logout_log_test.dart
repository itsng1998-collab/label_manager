import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/login_log.dart';
import 'package:label_manager/models/user.dart';

void main() {
  const user = User(
    userId: 'target',
    marketId: 10,
    name: '대상 사용자',
    pwd: 'pw',
    grade: UserGrade.MANAGER_USER,
    marketName: '대상 지점',
    customerName: '대상 거래처',
  );

  test('app exit captures current target session for LOGOUT', () {
    final snapshot = exitLogoutLogSnapshotFor(
      loggedIn: true,
      isDisconnect: true,
      isMasterKeyLogin: false,
      user: user,
      customerId: 20,
      customerName: '대상 거래처',
    );

    expect(snapshot?.userId, 'target');
    expect(snapshot?.userGrade, UserGrade.MANAGER_USER);
    expect(snapshot?.customerId, 20);
    expect(snapshot?.customerName, '대상 거래처');
  });

  test('master-key app exit does not create LOGOUT snapshot', () {
    expect(
      exitLogoutLogSnapshotFor(
        loggedIn: true,
        isDisconnect: true,
        isMasterKeyLogin: true,
        user: user,
        customerId: 20,
        customerName: '대상 거래처',
      ),
      isNull,
    );
  });

  test('explicit logout does not use app-exit LOGOUT rule', () {
    expect(
      exitLogoutLogSnapshotFor(
        loggedIn: true,
        isDisconnect: false,
        isMasterKeyLogin: false,
        user: user,
        customerId: 20,
        customerName: '대상 거래처',
      ),
      isNull,
    );
  });
}