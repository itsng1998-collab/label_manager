// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_menu_controller.dart';
import 'core/admin_connect_resolver.dart';
import 'core/admin_connect_session.dart';
import 'core/app_shortcut_blocker.dart';
import 'core/lifecycle.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/auto_login_guard.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_connection_service.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/models/admin_access_log.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/last_connect.dart';
import 'database/db_connection_status_icon.dart';
import 'home_page_manager.dart';
import 'page_login/startup_dialog.dart';
import 'page_login/startup_db_helper.dart';
import 'utils/log_context.dart';
import 'widgets/app_menu_bar.dart';

// 사용자 로그인 및 앱 시작: 기본 프린터 설정 + 사용자 정보 입력
class HomePage extends StatefulWidget {
  final bool fromLogout; // 사용자 로그아웃으로 진입했는지 여부
  const HomePage({super.key, this.fromLogout = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StartupDbHelper _db = StartupDbHelper();
  final Object _appMenuShortcutBlockerOwner = Object();
  late final AppMenuController _appMenuController;
  LifecycleCallbacks? _lifecycleCallbacks;
  Future<void>? _disconnectLogoutFuture;
  bool _disconnectCleanupDone = false;
  bool _isExiting = false;
  bool _loggedIn = false;
  bool _contextSwitching = false;
  int _managerSessionGeneration = 0;
  Future<void>? _loginToServerDbFuture;
  LifecycleExitSnapshotProvider? _exitSnapshotProvider;
  // 선택 상태
  Brand? _selectedBrand;
  LabelSize? _selectedLabelSize;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    _appMenuController = AppMenuController();
    _appMenuController.attach(
      owner: this,
      handlers: {
        AppMenuCommandId.login: _openLogin,
        AppMenuCommandId.logout: () => _onLogout(false),
        AppMenuCommandId.exit: _requestExit,
      },
    );

    _lifecycleCallbacks = LifecycleCallbacks(
      onResumed: () async {
        if (_isExiting) return;
        if (!DbClient.instance.isConnected) {
          await _loginToServerDB();
        }
      },
      onDetached: () async {
        await _onLogout(true);
      },
      onExitRequested: () async {
        if (!await _guardExit('앱을 종료')) return false;
        await _onLogout(true);
        return true;
      },
    );
    LifecycleManager.instance.addObserver(_lifecycleCallbacks!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _loginToServerDB();
    });
  }

  // 로그아웃 유입이면 자동 표시하지 않음, 사용자 요청 시(앱바 로그인 아이콘) 열도록 함
  Future<void> _loginToServerDB() async {
    final pending = _loginToServerDbFuture;
    if (pending != null) return pending;
    late final Future<void> future;
    future = _connectAndShowLogin();
    _loginToServerDbFuture = future;
    try {
      await future;
    } finally {
      if (identical(_loginToServerDbFuture, future)) {
        _loginToServerDbFuture = null;
      }
    }
  }

  Future<void> _connectAndShowLogin() async {
    if (!(await _db.connectToServerDB(context))) {
      return;
    }
    if (!widget.fromLogout && !_loggedIn) {
      await _showStartupDialog();
    }
  }

  // 재연결 모달은 전역 오버레이(GlobalReconnectOverlay)가 담당하므로 여기서는 처리하지 않음
  Future<void> _showStartupDialog({bool forceNoticeClosed = false}) async {
    await StartupDialog.show(
      context,
      onLogin: _onLogin,
      serverName: _db.lastConnectInfo?.serverName,
      forceNoticeClosed: forceNoticeClosed,
    );
  }

  void _onLogin() {
    if (!mounted) return;
    if (!_loggedIn) {
      setState(() {
        _loggedIn = true;
      });
    }
    _updateMenuSession();
  }

  void _updateMenuSession() {
    final adminSession = AdminConnectSession.instance;
    _appMenuController.updateSession(
      userGrade: User.instance?.grade,
      isAdminConnect: adminSession.isAdminConnect,
      isCoopAdminConnect: adminSession.isCoopAdminConnect,
      isFirstConnectByAdmin: adminSession.isFirstConnectByAdmin,
    );
  }

  Future<void> _onLogout(bool isDisconnect) async {
    if (isDisconnect) {
      if (_disconnectCleanupDone) {
        debugLog('$START skipped, disconnect cleanup already done');
        return;
      }
      final pending = _disconnectLogoutFuture;
      if (pending != null) {
        debugLog('$START skipped, disconnect cleanup already running');
        return pending;
      }
      _isExiting = true;
      final future = _doLogout(isDisconnect).whenComplete(() {
        _disconnectCleanupDone = true;
        _disconnectLogoutFuture = null;
      });
      _disconnectLogoutFuture = future;
      return future;
    }

    if (!await _guardExit('로그아웃')) return;
    return _doLogout(isDisconnect);
  }

  Future<void> _openLogin() => DbClient.instance.isConnected
      ? _showStartupDialog()
      : _loginToServerDB();

  Future<void> _requestExit() async {
    final exitAllowed = await LifecycleManager.instance.notifyExitRequested();
    if (!exitAllowed) return;
    await Future.delayed(const Duration(milliseconds: 120));
    await SystemNavigator.pop();
  }

  Future<bool> _guardExit(String action) async {
    if (!mounted) return false;
    final ownerSnapshots = <LifecycleExitSnapshot>[];
    final provider = _exitSnapshotProvider;
    if (provider != null) {
      ownerSnapshots.add(await provider());
    }
    if (!mounted) return false;
    ownerSnapshots.addAll([
      if (ModalRoute.of(context)?.isCurrent == false)
        const LifecycleExitSnapshot(
          blockingReason: '열려 있는 설정창을 먼저 닫아주세요.',
        ),
    ]);
    final plan = await LifecycleManager.instance.collectExitPlan(
      ownerSnapshots: ownerSnapshots,
    );
    if (!mounted) return false;
    if (plan.blockingReasons.isNotEmpty) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('$action할 수 없습니다.'),
          content: Text(plan.blockingReasons.join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return false;
    }

    if (plan.dirtyWorks.isNotEmpty) {
      final names = plan.dirtyWorks.map((work) => work.name).join(', ');
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('$action할까요?'),
          content: Text('저장하지 않은 작업이 있습니다: $names'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('계속 편집'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(action),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return false;
      await plan.discardDirty();
    }
    await plan.closeParticipants();
    return true;
  }

  Future<void> _doLogout(bool isDisconnect) async {
    debugLog(START);

    User.instance = null;
    Market.instance = null;
    Customer.instance = null;
    Cooperator.instance = null;
    AutoLoginGuard.instance.reset();
    AdminConnectSession.instance.resetForLogout();
    _appMenuController.updateSession(
      userGrade: null,
      isFirstConnectByAdmin:
          AdminConnectSession.instance.isFirstConnectByAdmin,
    );

    if (isDisconnect == true) {
      DbConnectionService.instance.cancelReconnect();
      DbConnectionService.instance.detach();
      _db.dispose();
      await DbClient.instance.disconnect();
      await DbServerConnectInfoHelper.close();
    }

    if (mounted && _loggedIn) {
      setState(() {
        _loggedIn = false;
      });
    }

    debugLog(END);
  }

  Future<void> _onLabelSizeChanged(LabelSize? labelSize) async {
    debugLog(
      '$START, labelSizeId: ${labelSize?.labelSizeId}, labelSizeName: ${labelSize?.labelSizeName}',
    );
    try {
      final user = User.instance;
      if (user == null) return;

      final brand = _selectedBrand;
      if (brand == null || labelSize == null) {
        await LastConnectDAO.delete(user.userId);
        return;
      }

      await LastConnectDAO.upsert(
        LastConnect(
          userId: user.userId,
          brandId: brand.brandId,
          labelSizeId: labelSize.labelSizeId,
        ),
      );
    } catch (e) {
      debugLog('$END, $e');
    } finally {
      debugLog(END);
    }
  }

  Future<void> _connectToCustomer(Customer customer) async {
    final currentUser = User.instance;
    final currentMarket = Market.instance;
    final currentCustomer = Customer.instance;
    final currentCooperator = Cooperator.instance;
    if (currentUser == null ||
        currentMarket == null ||
        currentCustomer == null ||
        currentCooperator == null) {
      return;
    }

    final target = await resolveAdminConnectTarget(customer: customer);
    final targetCooperator = await CooperatorDAO.selectByCooperatorId(
      customer.cooperatorId,
    );
    if (targetCooperator == null) {
      throw StateError('접속할 협력업체가 없습니다.');
    }
    final adminSession = AdminConnectSession.instance;
    final nextFlags = adminConnectFlagsFor(
      currentGrade: currentUser.grade,
      isAdminConnect: adminSession.isAdminConnect,
      isCoopAdminConnect: adminSession.isCoopAdminConnect,
    );
    final previousSession = adminSession.snapshot();
    final origin = previousSession.connectOrigin ?? currentUser;
    final previousBrand = _selectedBrand;
    final previousLabelSize = _selectedLabelSize;

    setState(() {
      _contextSwitching = true;
      _selectedBrand = null;
      _selectedLabelSize = null;
    });
    await WidgetsBinding.instance.endOfFrame;

    adminSession.connectOrigin = origin;
    adminSession.isAdminConnect = nextFlags.isAdminConnect;
    adminSession.isCoopAdminConnect = nextFlags.isCoopAdminConnect;
    User.setInstance(target.user);
    Market.setInstance(target.market);
    Customer.setInstance(target.customer);
    Cooperator.setInstance(targetCooperator);
    _updateMenuSession();

    try {
      await AdminAccessLogDAO.insert(
        accessUserId: origin.userId,
        targetUserId: target.user.userId,
        targetCustomerId: target.customer.customerId,
      );
    } catch (error) {
      User.setInstance(currentUser);
      Market.setInstance(currentMarket);
      Customer.setInstance(currentCustomer);
      Cooperator.setInstance(currentCooperator);
      adminSession.restore(previousSession);
      _updateMenuSession();
      if (!mounted) return;
      setState(() {
        _contextSwitching = false;
        _selectedBrand = previousBrand;
        _selectedLabelSize = previousLabelSize;
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Text(error.toString()),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _contextSwitching = false;
      _managerSessionGeneration += 1;
    });
  }

  @override
  void dispose() {
    debugLog(START);
    final lifecycleCallbacks = _lifecycleCallbacks;
    if (lifecycleCallbacks != null) {
      LifecycleManager.instance.removeObserver(lifecycleCallbacks);
      _lifecycleCallbacks = null;
    }
    _appMenuController.detach(this);
    _appMenuController.dispose();
    AppShortcutBlocker.instance.deactivate(_appMenuShortcutBlockerOwner);
    _searchCtrl.dispose();
    super.dispose();
    debugLog(END);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _requestExit();
      },
      child: Scaffold(
        appBar: AppBar(
          notificationPredicate: (_) => false,
          title: AnimatedBuilder(
            animation: _appMenuController,
            builder: (context, child) => AppMenuBar(
              title: Text('$APP_TITLE v$appVersion'),
              commandStates: _appMenuController.commandStates,
              onCommandSelected: (id) {
                unawaited(_appMenuController.execute(id));
              },
              onMenuOpenChanged: (open) {
                if (open) {
                  AppShortcutBlocker.instance.activate(
                    _appMenuShortcutBlockerOwner,
                  );
                } else {
                  AppShortcutBlocker.instance.deactivate(
                    _appMenuShortcutBlockerOwner,
                  );
                }
              },
            ),
          ),
          centerTitle: false,
          actions: [
            const DbConnectionStatusIcon(),
            if (_loggedIn)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
                onPressed: () => _onLogout(false),
              )
            else
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: '로그인',
                onPressed: _openLogin,
              ),
            // IconButton(
            //   icon: const Icon(Icons.exit_to_app),
            //   tooltip: '종료',
            //   onPressed: _exitApp,
            // ),
            SizedBox(width: lmSize(10)),
          ],
        ),
        body: _loggedIn && !_contextSwitching
            ? HomePageManager(
                key: ValueKey(_managerSessionGeneration),
                appMenuController: _appMenuController,
                customerCooperatorSelectionEnabled:
                    User.instance?.grade == UserGrade.SYSTEM_ADMIN_USER ||
                  AdminConnectSession.instance.isAdminConnect,
                onCustomerAdminConnect: _connectToCustomer,
                selectedBrand: _selectedBrand,
                onBrandChanged: (v) {
                  setState(() => _selectedBrand = v);
                },
                selectedLabelSize: _selectedLabelSize,
                onLabelSizeChanged: (v) {
                  setState(() => _selectedLabelSize = v);
                  _onLabelSizeChanged(v);
                },
                onExitSnapshotProviderChanged: (provider) {
                  _exitSnapshotProvider = provider;
                },
              )
            : _buildLoggedOutBackground(),
      ),
    );
  }

  Widget _buildLoggedOutBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        image: isShowLogo
            ? const DecorationImage(
                image: AssetImage('assets/images/MainLogo.webp'),
                fit: BoxFit.none,
                colorFilter: ColorFilter.mode(
                  Color(0xFFF4F4F4),
                  BlendMode.multiply,
                ),
              )
            : null,
      ),
    );
  }
}
