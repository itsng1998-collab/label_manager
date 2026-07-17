import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/page_login/startup_dialog.dart';
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
}