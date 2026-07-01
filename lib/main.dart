import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app.dart';
import 'core/bootstrap.dart';
import 'core/lifecycle.dart';
import 'core/ui_scale.dart';
import 'database/db_reconnect_overlay.dart';
import 'package:label_manager/utils/debug_logger.dart';
import 'home_page.dart';
import 'printing/label_printer_preferences.dart';

typedef DebugPrintCallback = void Function(String? message, {int? wrapWidth});
DebugPrintCallback gDebugPrint = debugPrint;
IOSink? gSink;

Future<void> main(List<String> args) async {
  // 로그파일 및 디버그프린트 초기화
  await DebugLogger.ensureInitialized();
  DebugLogger.setVersion('FSDBG-2026-07-01-cell-edit-log');

  // Widgets 초기화는 모든 플랫폼 공통으로 필요하다.
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 시작 시 라이프사이클 옵저버를 1회 등록
  LifecycleManager.instance.ensureInitialized();

  unawaited(LabelPrinterPreferences.removePreferredPrinterIfMissing());

  // 한국어 로케일용 날짜/시간 포맷터 초기화
  await initializeDateFormatting('ko_KR');

  // 데스크톱 환경에서는 지정한 디스플레이로 이동 후 최대화.
  if (Platform.isWindows || Platform.isMacOS) {
    //final requestedDisplay = resolveDisplayIndex(args);
    await initDesktopWindow(targetIndex: 0); //requestedDisplay ?? 0);

    // 창 닫기(X) 시 우리 정리 로직을 먼저 수행할 수 있도록 보장
    await windowManager.setPreventClose(true);
    windowManager.addListener(_AppWindowListener());

    isDesktop = true;
  }

  // 앱 정보를 조회해 전역에 보관한다.
  final info = await PackageInfo.fromPlatform();
  appPackageName = info.packageName;
  appVersion = info.version;

  // 공통 StartUp 페이지를 표시한다.
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => withLabelManagerCompactUi(
        context,
        DbReconnectOverlay(child: child),
      ),
      home: const HomePage(),
      theme: labelManagerTheme(
        ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    ),
  );
}

class _AppWindowListener extends WindowListener {
  bool _closing = false;

  @override
  void onWindowClose() async {
    if (_closing) {
      DebugLogger.log('Window close ignored: shutdown already in progress');
      return;
    }

    final isPrevent = await windowManager.isPreventClose();
    if (isPrevent) {
      _closing = true;
      DebugLogger.log('Window close start');
      // 앱 전역 종료 요청 브로드캐스트(비동기 정리 작업이 있다면 여기서 시작)
      await LifecycleManager.instance.notifyExitRequested().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          DebugLogger.log('Window close cleanup timed out');
        },
      );
      // 짧은 딜레이로 즉시 종료로 인한 정리 누락을 완화(필요시 조정)
      await Future.delayed(const Duration(milliseconds: 120));
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
      DebugLogger.log('Window close post start');
      await windowManager.close();
    }
  }
}
