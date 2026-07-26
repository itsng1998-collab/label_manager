import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app_shortcut_blocker.dart';

void main() {
  setUp(AppShortcutBlocker.instance.reset);
  tearDown(AppShortcutBlocker.instance.reset);

  testWidgets('blocking scope is active only while mounted', (tester) async {
    await tester.pumpWidget(
      const AppShortcutBlockingScope(child: SizedBox()),
    );
    expect(AppShortcutBlocker.instance.isBlocked, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(AppShortcutBlocker.instance.isBlocked, isFalse);
  });

  testWidgets('nested scopes keep blocking until the last scope is removed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AppShortcutBlockingScope(
        child: AppShortcutBlockingScope(child: SizedBox()),
      ),
    );
    expect(AppShortcutBlocker.instance.isBlocked, isTrue);

    await tester.pumpWidget(
      const AppShortcutBlockingScope(child: SizedBox()),
    );
    expect(AppShortcutBlocker.instance.isBlocked, isTrue);

    await tester.pumpWidget(const SizedBox());
    expect(AppShortcutBlocker.instance.isBlocked, isFalse);
  });
}