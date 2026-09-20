import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/login/application/startup_login_service.dart';
import 'package:label_manager/features/login/application/user_access_service.dart';
import 'package:label_manager/features/login/presentation/startup_dialog.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/features/update_notice/domain/notice.dart';
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
              loadNotice: (_) async => const Notice(message: '', state: 0),
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

  testWidgets('startup login begins before progress snackbar is visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      User.setInstance(null);
      Market.setInstance(null);
      Customer.setInstance(null);
      Cooperator.setInstance(null);
      AdminConnectSession.instance.resetForLogout();
    });
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': User.SYSTEM,
      'save_id': true,
    });
    var loginStarted = false;
    const user = User(
      userId: User.SYSTEM,
      marketId: 1,
      name: '시스템',
      pwd: '',
      grade: UserGrade.SYSTEM_ADMIN_USER,
      marketName: '지점',
      customerName: '거래처',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            forceNoticeClosed: true,
            onLogin: () {},
            loginService: StartupLoginService(
              loadNotice: (_) async => const Notice(message: '', state: 0),
              loadUser: (_) async => user,
              loadMarket: (_) async {
                loginStarted = true;
                return const Market(
                  marketId: 1,
                  customerId: 1,
                  name: '지점',
                );
              },
              loadCustomer: (_) async => const Customer(
                customerId: 1,
                cooperatorId: 'C1',
                customerName: '거래처',
              ),
              loadCooperator: (_) async => const Cooperator(
                id: 'C1',
                name: '협력업체',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).at(4),
      systemPasswordForDate(),
    );
    final loginButton = find.widgetWithText(ElevatedButton, '로그인');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);

    expect(loginStarted, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('startup notice stays closed when database state is suppressed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': 'user',
      'save_id': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            onLogin: () {},
            loginService: _noticeService(
              const Notice(message: '업데이트 공지', state: 1),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NoticeDisplayPanel), findsNothing);
    expect(find.text('다음 업데이트까지 이 창 보지 않음'), findsNothing);
  });

  testWidgets('startup notice reopens when database state is reset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': 'user',
      'save_id': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            onLogin: () {},
            loginService: _noticeService(
              const Notice(message: '새 업데이트 공지', state: 0),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NoticeDisplayPanel), findsOneWidget);
  });

  testWidgets('saved id does not replace edited id when notice closes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': '3575',
      'save_id': true,
    });
    final lookedUpIds = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            onLogin: () {},
            loginService: StartupLoginService(
              loadNotice: (userId) async => Notice(
                message: '업데이트 공지',
                state: userId == 'TESTER1' ? 1 : 0,
              ),
              loadUser: (userId) async {
                lookedUpIds.add(userId);
                return User(
                  userId: userId,
                  marketId: 1,
                  name: '사용자',
                  pwd: 'pw',
                  grade: UserGrade.CLIENT_USER,
                  marketName: '지점',
                  customerName: '거래처',
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final userIdField = find.byKey(
      const ValueKey('startup-login-user-id'),
    );
    await tester.enterText(userIdField, 'TESTER1');
    await tester.tap(find.byKey(const ValueKey('startup-login-password')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(userIdField).controller?.text,
      'TESTER1',
    );
    final editedLookupIndex = lookedUpIds.indexOf('TESTER1');
    expect(editedLookupIndex, greaterThanOrEqualTo(0));
    expect(lookedUpIds.where((userId) => userId == 'TESTER1'), hasLength(1));
    expect(
      lookedUpIds.skip(editedLookupIndex + 1),
      isNot(contains('3575')),
    );
    expect(find.byType(NoticeDisplayPanel), findsNothing);
  });

  test('notice confirmation resets only when user id changes', () {
    expect(didNoticeUserChange('3575', 'TESTER1'), isTrue);
    expect(didNoticeUserChange(' tester1 ', 'TESTER1'), isFalse);
    expect(didNoticeUserChange(null, 'TESTER1'), isFalse);
  });

  testWidgets('notice confirmation saves suppression before closing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': 'user',
      'save_id': true,
    });
    final writes = <(String, bool)>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            onLogin: () {},
            loginService: _noticeService(
              const Notice(message: '업데이트 공지', state: 0),
              writeNoticeState: (userId, dontShowAgain) async {
                writes.add((userId, dontShowAgain));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('startup-notice-suppress-checkbox')),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pumpAndSettle();

    expect(writes, [('user', true)]);
    expect(find.byType(NoticeDisplayPanel), findsNothing);
  });

  testWidgets('notice remains open when suppression save fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_id': 'user',
      'save_id': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StartupDialog(
            onLogin: () {},
            loginService: _noticeService(
              const Notice(message: '업데이트 공지', state: 0),
              writeNoticeState: (_, _) async {
                throw StateError('공지 상태 저장 실패');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('startup-notice-suppress-checkbox')),
    );
    await tester.tap(find.widgetWithText(ElevatedButton, '확인'));
    await tester.pump();

    expect(find.byType(NoticeDisplayPanel), findsOneWidget);
    expect(find.text('공지 설정 저장에 실패했습니다.'), findsOneWidget);
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

StartupLoginService _noticeService(
  Notice notice, {
  StartupNoticeStateWriter? writeNoticeState,
}) => StartupLoginService(
  loadNotice: (_) async => notice,
  loadUser: (_) async => const User(
    userId: 'user',
    marketId: 1,
    name: '사용자',
    pwd: 'pw',
    grade: UserGrade.CLIENT_USER,
    marketName: '지점',
    customerName: '거래처',
  ),
  writeNoticeState: writeNoticeState ?? (_, _) async {},
);