import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/login/application/startup_login_service.dart';
import 'package:label_manager/features/market/domain/market.dart';

void main() {
  const user = User(
    userId: 'user',
    marketId: 10,
    name: '사용자',
    pwd: 'password',
    grade: UserGrade.CLIENT_USER,
    marketName: '지점',
    customerName: '거래처',
  );
  const market = Market(marketId: 10, customerId: 20, name: '지점');
  const customer = Customer(
    customerId: 20,
    cooperatorId: 'C30',
    customerName: '거래처',
  );
  const cooperator = Cooperator(id: 'C30', name: '협력업체');

  tearDown(() {
    User.setInstance(null);
    Market.setInstance(null);
    Customer.setInstance(null);
    Cooperator.setInstance(null);
    AdminConnectSession.instance.resetForLogout();
  });

  test('lookup loads notice before user', () async {
    final calls = <String>[];
    final service = _service(
      loadNotice: (userId) async {
        calls.add('notice:$userId');
        return '공지';
      },
      loadUser: (userId) async {
        calls.add('user:$userId');
        return user;
      },
    );

    final result = await service.lookupUser('user');

    expect(calls, ['notice:user', 'user:user']);
    expect(result.notice, '공지');
    expect(result.user, same(user));
  });

  test('regular login loads organization and applies session', () async {
    final calls = <String>[];
    final service = _service(
      loadMarket: (marketId) async {
        calls.add('market:$marketId');
        return market;
      },
      loadCustomer: (customerId) async {
        calls.add('customer:$customerId');
        return customer;
      },
      loadCooperator: (cooperatorId) async {
        calls.add('cooperator:$cooperatorId');
        return cooperator;
      },
      writeLoginLog: (loggedUser, loggedCustomer) async {
        expect(loggedUser, same(user));
        expect(loggedCustomer, same(customer));
        calls.add('log');
      },
    );

    await service.login(
      user: user,
      authenticationMode: LoginAuthenticationMode.regular,
    );

    expect(calls, ['market:10', 'customer:20', 'cooperator:C30', 'log']);
    expect(User.instance, same(user));
    expect(Market.instance, same(market));
    expect(Customer.instance, same(customer));
    expect(Cooperator.instance, same(cooperator));
    expect(AdminConnectSession.instance.isMasterKeyLogin, isFalse);
  });

  test('master key login skips login history', () async {
    var logCalled = false;
    final service = _service(writeLoginLog: (_, _) async => logCalled = true);

    await service.login(
      user: user,
      authenticationMode: LoginAuthenticationMode.masterKey,
    );

    expect(logCalled, isFalse);
    expect(AdminConnectSession.instance.isMasterKeyLogin, isTrue);
  });
}

StartupLoginService _service({
  StartupNoticeLoader? loadNotice,
  StartupUserLoader? loadUser,
  StartupMarketLoader? loadMarket,
  StartupCustomerLoader? loadCustomer,
  StartupCooperatorLoader? loadCooperator,
  StartupLoginLogWriter? writeLoginLog,
}) => StartupLoginService(
  loadNotice: loadNotice ?? (_) async => '',
  loadUser: loadUser ?? (_) async => null,
  loadMarket:
      loadMarket ??
      (_) async => const Market(marketId: 10, customerId: 20, name: '지점'),
  loadCustomer:
      loadCustomer ??
      (_) async => const Customer(
        customerId: 20,
        cooperatorId: 'C30',
        customerName: '거래처',
      ),
  loadCooperator:
      loadCooperator ?? (_) async => const Cooperator(id: 'C30', name: '협력업체'),
  writeLoginLog: writeLoginLog ?? (_, _) async {},
);
