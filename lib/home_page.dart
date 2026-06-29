// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/lifecycle.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/auto_login_guard.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_connection_service.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/label_size.dart';
import 'database/db_connection_status_icon.dart';
import 'home_page_manager.dart';
import 'page_login/startup_dialog.dart';
import 'page_login/startup_db_helper.dart';
import 'utils/log_context.dart';

// 사용자 로그인 및 앱 시작: 기본 프린터 설정 + 사용자 정보 입력
class HomePage extends StatefulWidget {
  final bool fromLogout; // 사용자 로그아웃으로 진입했는지 여부
  const HomePage({super.key, this.fromLogout = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StartupDbHelper _db = StartupDbHelper();
  LifecycleCallbacks? _lifecycleCallbacks;
  Future<void>? _disconnectLogoutFuture;
  bool _disconnectCleanupDone = false;
  bool _isExiting = false;
  bool _loggedIn = false;
  // 선택 상태
  Brand? _selectedBrand;
  LabelSize? _selectedLabelSize;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

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
        await _onLogout(true);
      },
    );
    LifecycleManager.instance.addObserver(_lifecycleCallbacks!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _loginToServerDB();
    });
  }

  // 로그아웃 유입이면 자동 표시하지 않음, 사용자 요청 시(앱바 로그인 아이콘) 열도록 함
  Future<void> _loginToServerDB() async {
    if (!(await _db.connectToServerDB(context))) {
      return;
    }
    if (!widget.fromLogout) {
      _showStartupDialog();
    }
  }

  // 재연결 모달은 전역 오버레이(GlobalReconnectOverlay)가 담당하므로 여기서는 처리하지 않음
  void _showStartupDialog({bool forceNoticeClosed = false}) async {
    await StartupDialog.show(
      context, onLogin: _onLogin,
      serverName: _db.lastConnectInfo?.serverName,
      forceNoticeClosed: forceNoticeClosed,
    );
  }

  void _onLogin() {
    if (!mounted) return;
    if (!_loggedIn) {
      setState(() { _loggedIn = true; });
    }
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

    return _doLogout(isDisconnect);
  }

  Future<void> _doLogout(bool isDisconnect) async {
    debugLog(START);

    User.instance = null;
    Market.instance = null;
    Customer.instance = null;
    Cooperator.instance = null;
    AutoLoginGuard.instance.reset();

    if (isDisconnect == true) {
      DbConnectionService.instance.cancelReconnect();
      DbConnectionService.instance.detach();
      _db.dispose();
      await DbClient.instance.disconnect();
      await DbServerConnectInfoHelper.close();
    }

    if (mounted && _loggedIn) {
      setState(() { _loggedIn = false; });
    }

    debugLog(END);
  }

  Future<void> _onLabelSizeChanged(LabelSize? labelSize) async {
    debugLog(
      '$START, labelSizeId: ${labelSize?.labelSizeId}, labelSizeName: ${labelSize?.labelSizeName}',
    );
    debugLog(END);
  }

  @override
  void dispose() {
    debugLog(START);
    final lifecycleCallbacks = _lifecycleCallbacks;
    if (lifecycleCallbacks != null) {
      LifecycleManager.instance.removeObserver(lifecycleCallbacks);
      _lifecycleCallbacks = null;
    }
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
        // 데스크톱의 창 닫기와 동일한 로직으로 종료 처리
        await LifecycleManager.instance.notifyExitRequested();
        // 짧은 딜레이로 정리(예: DB연결 해제) 누락 완화
        await Future.delayed(const Duration(milliseconds: 120));
        await SystemNavigator.pop(); // 앱 완전 종료
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$APP_TITLE v$appVersion'),
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
                onPressed: () => DbClient.instance.isConnected
                  ? _showStartupDialog() : _loginToServerDB(),
              ),
            // IconButton(
            //   icon: const Icon(Icons.exit_to_app),
            //   tooltip: '종료',
            //   onPressed: _exitApp,
            // ),
            SizedBox(width: lmSize(10)),
          ],
        ),
        body: _loggedIn
          ? HomePageManager(
            selectedBrand: _selectedBrand,
            onBrandChanged: (v) {
              setState(() => _selectedBrand = v);
            },
            selectedLabelSize: _selectedLabelSize,
            onLabelSizeChanged: (v) {
              setState(() => _selectedLabelSize = v);
              _onLabelSizeChanged(v);
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
        image: isShowLogo ? const DecorationImage(
          image: AssetImage('assets/images/MainLogo.webp'),
          fit: BoxFit.none,
          colorFilter: ColorFilter.mode(Color(0xFFF4F4F4), BlendMode.multiply),
        ) : null,
      ),
    );
  }
}
