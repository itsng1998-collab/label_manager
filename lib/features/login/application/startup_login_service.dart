import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/login/data/user_dao.dart';
import 'package:label_manager/features/login_history/data/login_log_dao.dart';
import 'package:label_manager/features/login_history/domain/login_log.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/features/update_notice/data/notice_dao.dart';

typedef StartupNoticeLoader = Future<String> Function(String userId);
typedef StartupUserLoader = Future<User?> Function(String userId);
typedef StartupMarketLoader = Future<Market?> Function(int marketId);
typedef StartupCustomerLoader = Future<Customer?> Function(int customerId);
typedef StartupCooperatorLoader =
    Future<Cooperator?> Function(String cooperatorId);
typedef StartupLoginLogWriter =
    Future<void> Function(User user, Customer customer);

class StartupUserLookupResult {
  const StartupUserLookupResult({required this.notice, required this.user});

  final String notice;
  final User? user;
}

class StartupLoginService {
  StartupLoginService({
    StartupNoticeLoader? loadNotice,
    StartupUserLoader? loadUser,
    StartupMarketLoader? loadMarket,
    StartupCustomerLoader? loadCustomer,
    StartupCooperatorLoader? loadCooperator,
    StartupLoginLogWriter? writeLoginLog,
  }) : _loadNotice = loadNotice ?? NoticeDAO.selectByUserId,
       _loadUser = loadUser ?? UserDAO.selectByUserId,
       _loadMarket = loadMarket ?? MarketDAO.selectByMarketId,
       _loadCustomer = loadCustomer ?? CustomerDAO.selectByCustomerId,
       _loadCooperator = loadCooperator ?? CooperatorDAO.selectByCooperatorId,
       _writeLoginLog = writeLoginLog ?? _defaultWriteLoginLog;

  final StartupNoticeLoader _loadNotice;
  final StartupUserLoader _loadUser;
  final StartupMarketLoader _loadMarket;
  final StartupCustomerLoader _loadCustomer;
  final StartupCooperatorLoader _loadCooperator;
  final StartupLoginLogWriter _writeLoginLog;

  Future<StartupUserLookupResult> lookupUser(String userId) async {
    final notice = await _loadNotice(userId);
    final user = await _loadUser(userId);
    return StartupUserLookupResult(notice: notice, user: user);
  }

  Future<void> login({
    required User user,
    required LoginAuthenticationMode authenticationMode,
  }) async {
    final market = await _loadMarket(user.marketId);
    if (market == null) {
      throw StateError('지점 정보를 찾을 수 없습니다.');
    }

    final customer = await _loadCustomer(market.customerId);
    if (customer == null) {
      throw StateError('거래처 정보를 찾을 수 없습니다.');
    }

    final cooperator = await _loadCooperator(customer.cooperatorId);
    if (cooperator == null) {
      throw StateError('협력업체 정보를 찾을 수 없습니다.');
    }

    Market.setInstance(market);
    Customer.setInstance(customer);
    Cooperator.setInstance(cooperator);
    User.setInstance(user);
    AdminConnectSession.instance.beginLogin(authenticationMode);

    if (authenticationMode != LoginAuthenticationMode.masterKey) {
      await _writeLoginLog(user, customer);
    }
  }

  void clearSession() {
    User.setInstance(null);
    Market.setInstance(null);
    Customer.setInstance(null);
    Cooperator.setInstance(null);
  }

  static Future<void> _defaultWriteLoginLog(User user, Customer customer) =>
      LoginLogDAO.insertLoginLog(
        userId: user.userId,
        userGrade: user.grade,
        customerId: customer.customerId,
        customerName: customer.customerName,
        loginCondition: LoginCondition.LOGIN,
      );
}
