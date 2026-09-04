import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/application/startup_login_service.dart';
import 'package:label_manager/features/login/application/user_access_service.dart';
import 'package:label_manager/features/login/presentation/startup_dialog.dart';
import 'package:label_manager/widgets/notice_display.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('startup dialog coalesces concurrent show requests', (
    tester,
  ) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final first = StartupDialog.show(
      hostContext,
      onLogin: () {},
      forceNoticeClosed: true,
    );
    final second = StartupDialog.show(
      hostContext,
      onLogin: () {},
      forceNoticeClosed: true,
    );
    await tester.pump();

    expect(find.byType(StartupDialog), findsOneWidget);

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await Future.wait([first, second]);

    final third = StartupDialog.show(
      hostContext,
      onLogin: () {},
      forceNoticeClosed: true,
    );
    await tester.pump();
    expect(find.byType(StartupDialog), findsOneWidget);

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await third;
  });

  testWidgets('startup login failure message uses red text', (tester) async {
    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final dialog = StartupDialog.show(
      hostContext,
      onLogin: () {},
      forceNoticeClosed: true,
    );
    await tester.pump();

    final message = tester.widget<Text>(
      find.byKey(const ValueKey('startup-login-info-text')),
    );
    expect(message.style?.color, Colors.red);

    Navigator.of(hostContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await dialog;
  });

  testWidgets('startup login failure keeps dialog open', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': 'user',
      'save_id': true,
    });
    var loginCallbackCalled = false;
    const user = User(
      userId: 'user',
      marketId: 1,
      name: '사용자',
      pwd: 'pw',
      grade: UserGrade.CLIENT_USER,
      marketName: '지점',
      customerName: '거래처',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            forceNoticeClosed: true,
            onLogin: () => loginCallbackCalled = true,
            loginService: StartupLoginService(
              loadNotice: (_) async => '',
              loadUser: (_) async => user,
            ),
            userAccessService: UserAccessService(
              loadAccessData: (_) async => null,
              readLocalValue: () async => '',
              saveAccessData: (_, _) async => throw StateError('접속 정보 저장 실패'),
              writeLocalValue: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(4), 'pw');
    final loginButton = find.widgetWithText(ElevatedButton, '로그인');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.byType(StartupDialog), findsOneWidget);
    expect(find.textContaining('접속 정보 저장 실패'), findsOneWidget);
    expect(loginCallbackCalled, isFalse);
  });

  testWidgets('startup notice restores equal content and image widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: NoticeDisplayPanel(
              version: '1.0.0',
              content: '',
              contentFlex: startupNoticeContentFlex,
              adFlex: startupNoticeAdFlex,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final contentWidth = tester
        .getSize(find.byKey(const ValueKey('notice-content-area')))
        .width;
    final imageWidth = tester
        .getSize(find.byKey(const ValueKey('notice-ad-area')))
        .width;
    expect(imageWidth, moreOrLessEquals(contentWidth));
  });

  testWidgets('shared notice panel keeps editor content ratio by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: NoticeDisplayPanel(version: '1.0.0', content: ''),
          ),
        ),
      ),
    );
    await tester.pump();

    final contentWidth = tester
        .getSize(find.byKey(const ValueKey('notice-content-area')))
        .width;
    final imageWidth = tester
        .getSize(find.byKey(const ValueKey('notice-ad-area')))
        .width;
    expect(contentWidth, moreOrLessEquals(imageWidth * 2));
  });
}