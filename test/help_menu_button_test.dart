import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/features/help/presentation/help_menu_button.dart';
import 'package:label_manager/widgets/app_menu_bar.dart';

void main() {
  testWidgets('help menu shows legacy commands and current app version', (
    tester,
  ) async {
    final opened = <bool>[];
    appVersion = '9.8.7';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HelpMenuButton(onMenuOpenChanged: opened.add),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('helpMenuButton')));
    await tester.pumpAndSettle();

    expect(opened, [true]);
    expect(find.text('라벨매니저 정보'), findsOneWidget);
    expect(find.text('라벨지, 프린터 구매하기'), findsOneWidget);
    expect(find.text('원격 지원 프로그램 다운로드'), findsOneWidget);
    expect(find.text('ITSNG 자료실 바로가기'), findsOneWidget);
    for (final key in const [
      'helpAbout',
      'helpShop',
      'helpRemoteSupport',
      'helpDownloads',
    ]) {
      final item = tester.widget<MenuItemButton>(find.byKey(ValueKey(key)));
      expect(item.style, same(AppMenuBar.menuItemStyle));
      expect(
        item.style?.minimumSize?.resolve({}),
        const Size(64, AppMenuBar.menuItemHeight),
      );
    }

    await tester.tap(find.byKey(const ValueKey('helpAbout')));
    await tester.pumpAndSettle();

    expect(find.text('LabelManager 정보'), findsOneWidget);
    expect(find.text('LabelManager 버전 9.8.7'), findsOneWidget);
    expect(find.text('전화번호 : 02-3274-1776'), findsOneWidget);
    expect(opened, [true, false]);
  });

  testWidgets('help menu opens the legacy external links', (tester) async {
    final launched = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HelpMenuButton(
            urlLauncher: (uri) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    );

    const cases = <(String, String)>[
      ('helpShop', 'https://itsngshop.com/index.html'),
      (
        'helpRemoteSupport',
        'https://itsng.co.kr/%ED%8C%80%EB%B7%B0%EC%96%B412_QS.exe',
      ),
      (
        'helpDownloads',
        'https://itsng.co.kr/board/bbs/board.php?bo_table=down',
      ),
    ];
    for (final entry in cases) {
      await tester.tap(find.byKey(const ValueKey('helpMenuButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(entry.$1)));
      await tester.pumpAndSettle();
    }

    expect(launched.map((uri) => uri.toString()), [
      for (final entry in cases) entry.$2,
    ]);
  });
}
