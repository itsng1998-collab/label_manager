import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_resolver.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/data/user_dao.dart';

void main() {
  const customer = Customer(
    customerId: 10,
    cooperatorId: 'COOP',
    customerName: '거래처',
  );

  test('customer CRUD follows verified schema without ordering', () {
    expect(CustomerDAO.insertSql, contains('RICH_COOP_ID, RICH_NAME'));
    expect(CustomerDAO.insertSql, isNot(contains('RICH_CUSTOMER_ID,')));
    expect(CustomerDAO.insertSql, isNot(contains('RICH_ETC')));
    expect(CustomerDAO.updateSql, contains('RICH_CUSTOMER_ID=@customerId'));
    expect(CustomerDAO.deleteSql, contains('DELETE FROM BM_CUSTOMER'));
    expect(CustomerDAO.deleteSql, isNot(contains('BM_MARKET')));
    expect(CustomerDAO.selectSql, isNot(contains('ORDER BY')));
  });

  test('admin connect queries keep legacy ordering', () {
    expect(
      MarketDAO.selectSql + MarketDAO.whereSqlCustomerId,
      isNot(contains('ORDER BY')),
    );
    expect(
      UserDAO.selectSql + AdminConnectResolverDAO.whereSqlMarketId,
      isNot(contains('ORDER BY')),
    );
  });

  test('admin connect selects first market and first grade 2 user', () async {
    final target = await resolveAdminConnectTarget(
      customer: customer,
      loadMarkets: (_) async => const [
        Market(marketId: 20, customerId: 10, name: '첫 지점'),
        Market(marketId: 21, customerId: 10, name: '둘째 지점'),
      ],
      loadUsers: (_) async => [
        _user('client', UserGrade.CLIENT_USER),
        _user('manager-1', UserGrade.MANAGER_USER),
        _user('manager-2', UserGrade.MANAGER_USER),
      ],
    );

    expect(target.market.marketId, 20);
    expect(target.user.userId, 'manager-1');
  });

  test('admin connect stops before context when market or manager is absent', () async {
    await expectLater(
      resolveAdminConnectTarget(
        customer: customer,
        loadMarkets: (_) async => const [],
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      resolveAdminConnectTarget(
        customer: customer,
        loadMarkets: (_) async => const [
          Market(marketId: 20, customerId: 10, name: '지점'),
        ],
        loadUsers: (_) async => [_user('client', UserGrade.CLIENT_USER)],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('admin connect preserves system or cooperator administrator origin', () {
    final system = adminConnectFlagsFor(
      currentGrade: UserGrade.SYSTEM_ADMIN_USER,
      isAdminConnect: false,
      isCoopAdminConnect: false,
    );
    expect(system.isAdminConnect, isTrue);
    expect(system.isCoopAdminConnect, isFalse);

    final cooperative = adminConnectFlagsFor(
      currentGrade: UserGrade.MANAGER_USER,
      isAdminConnect: false,
      isCoopAdminConnect: true,
    );
    expect(cooperative.isAdminConnect, isFalse);
    expect(cooperative.isCoopAdminConnect, isTrue);
  });
}

User _user(String id, UserGrade grade) => User(
  userId: id,
  marketId: 20,
  name: id,
  pwd: '',
  grade: grade,
  marketName: '지점',
  customerName: '거래처',
);