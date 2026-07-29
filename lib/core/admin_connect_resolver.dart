import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/login/data/user_dao.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/features/market/domain/market.dart';

typedef AdminConnectMarketLoader = Future<List<Market>> Function(
  int customerId,
);
typedef AdminConnectUserLoader = Future<List<User>> Function(int marketId);

class AdminConnectTarget {
  const AdminConnectTarget({
    required this.customer,
    required this.market,
    required this.user,
  });

  final Customer customer;
  final Market market;
  final User user;
}

class AdminConnectResolverDAO extends DAO {
  static const String whereSqlMarketId = '''
    WHERE P1.RICH_MARKET_ID=@marketId
  ''';

  static Future<List<User>> selectUsersByMarketId(int marketId) async {
    final result = await DbClient.instance.getDataWithParams(
      '${UserDAO.selectSql} $whereSqlMarketId',
      {'marketId': marketId},
    );
    return DAO.mapRows(result, userFromRow);
  }
}

Future<AdminConnectTarget> resolveAdminConnectTarget({
  required Customer customer,
  AdminConnectMarketLoader loadMarkets = MarketDAO.selectForAdminConnect,
  AdminConnectUserLoader loadUsers =
      AdminConnectResolverDAO.selectUsersByMarketId,
}) async {
  final markets = await loadMarkets(customer.customerId);
  if (markets.isEmpty) {
    throw StateError('접속할 지점이 없습니다.');
  }
  final market = markets.first;
  final users = await loadUsers(market.marketId);
  for (final user in users) {
    if (user.grade == UserGrade.MANAGER_USER) {
      return AdminConnectTarget(customer: customer, market: market, user: user);
    }
  }
  throw StateError('접속할 책임자 사용자가 없습니다.');
}

class AdminConnectFlags {
  const AdminConnectFlags({
    required this.isAdminConnect,
    required this.isCoopAdminConnect,
  });

  final bool isAdminConnect;
  final bool isCoopAdminConnect;
}

AdminConnectFlags adminConnectFlagsFor({
  required UserGrade currentGrade,
  required bool isAdminConnect,
  required bool isCoopAdminConnect,
}) {
  if (currentGrade == UserGrade.SYSTEM_ADMIN_USER || isAdminConnect) {
    return const AdminConnectFlags(
      isAdminConnect: true,
      isCoopAdminConnect: false,
    );
  }
  if (currentGrade == UserGrade.COOP_ADMIN_USER || isCoopAdminConnect) {
    return const AdminConnectFlags(
      isAdminConnect: false,
      isCoopAdminConnect: true,
    );
  }
  return const AdminConnectFlags(
    isAdminConnect: false,
    isCoopAdminConnect: false,
  );
}