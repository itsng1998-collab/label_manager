import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app_shortcut_blocker.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/widgets/app_menu_bar.dart';

void main() {
  setUp(AppShortcutBlocker.instance.reset);
  tearDown(AppShortcutBlocker.instance.reset);

  final visibleStates = {
    for (final command in appMenuCommands)
      command.id: AppMenuCommandState(
        visible: command.availability == AppMenuAvailability.active,
        enabled: true,
      ),
  };

  Future<void> pumpMenu(
    WidgetTester tester, {
    required Size size,
    ValueChanged<AppMenuCommandId>? onSelected,
    ValueChanged<bool>? onMenuOpenChanged,
    Map<AppMenuCommandId, AppMenuCommandState>? states,
    bool searchPrintModeActive = false,
    FocusNode? commandFocusNode,
    VoidCallback? onBodyTap,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: labelManagerTheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBodyTap,
            child: Focus(
              focusNode: commandFocusNode,
              child: const SizedBox.expand(),
            ),
          ),
          appBar: AppBar(
            title: AppMenuBar(
              title: const Text(
                '라벨 매니저 v123.456.789 긴 버전 문자열',
                overflow: TextOverflow.ellipsis,
              ),
              commandStates: states ?? visibleStates,
              onCommandSelected: onSelected ?? (_) {},
              onMenuOpenChanged: onMenuOpenChanged,
              searchPrintModeActive: searchPrintModeActive,
            ),
            actions: [
              IconButton(
                key: const ValueKey('server-status'),
                onPressed: () {},
                icon: const Icon(Icons.cloud_done),
              ),
              IconButton(
                key: const ValueKey('login-command'),
                onPressed: () {},
                icon: const Icon(Icons.login),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1200x800 shows three group buttons and fixed actions', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(1200, 800));

    expect(find.byKey(const ValueKey('app-menu-group-file')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-menu-group-search')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-menu-group-settings')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('app-menu-overflow')), findsNothing);
    expect(find.byKey(const ValueKey('server-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-command')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('600x720 shows overflow and keeps fixed actions', (tester) async {
    await pumpMenu(tester, size: const Size(600, 720));

    expect(find.byKey(const ValueKey('app-menu-overflow')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-menu-group-file')), findsNothing);
    expect(find.byKey(const ValueKey('app-menu-group-search')), findsNothing);
    expect(
      find.byKey(const ValueKey('app-menu-group-settings')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('server-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-command')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide command selection is delivered exactly once', (
    tester,
  ) async {
    final selected = <AppMenuCommandId>[];
    final menuStates = <bool>[];
    final events = <String>[];
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      onSelected: (id) {
        selected.add(id);
        events.add('selected');
      },
      onMenuOpenChanged: (open) {
        menuStates.add(open);
        events.add(open ? 'opened' : 'closed');
      },
    );

    await tester.tap(
      find.byKey(const ValueKey('app-menu-group-settings')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('app-menu-command-labelPrintSettings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(selected, [AppMenuCommandId.labelPrintSettings]);
    expect(menuStates, [true, false]);
    expect(events, ['opened', 'closed', 'selected']);
  });

  testWidgets('narrow overflow preserves group then command navigation', (
    tester,
  ) async {
    final selected = <AppMenuCommandId>[];
    await pumpMenu(
      tester,
      size: const Size(600, 720),
      onSelected: selected.add,
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-menu-overflow-group-search')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-menu-command-viewPrintHistory')),
    );
    await tester.pumpAndSettle();

    expect(selected, [AppMenuCommandId.viewPrintHistory]);
  });

  testWidgets('disabled reason is visible and command is not delivered', (
    tester,
  ) async {
    final selected = <AppMenuCommandId>[];
    final states = Map<AppMenuCommandId, AppMenuCommandState>.of(
      visibleStates,
    );
    states[AppMenuCommandId.scaleOutputPrinterSettings] =
        const AppMenuCommandState(
          visible: true,
          enabled: false,
          disabledReason: '라벨사이즈를 먼저 선택해주세요.',
        );
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      states: states,
      onSelected: selected.add,
    );

    await tester.tap(
      find.byKey(const ValueKey('app-menu-group-settings')),
    );
    await tester.pumpAndSettle();
    expect(find.text('라벨사이즈를 먼저 선택해주세요.'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('app-menu-command-scaleOutputPrinterSettings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
  });

  testWidgets('search print submenu keeps shortcut semantics and checked mode', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      searchPrintModeActive: true,
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-group-settings')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('app-menu-submenu-searchPrint')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('app-menu-submenu-searchPrint')),
    );
    await tester.pumpAndSettle();

    final mode = find.byKey(
      const ValueKey('app-menu-command-searchPrintMode'),
    );
    final settings = find.byKey(
      const ValueKey('app-menu-command-searchPrintSettings'),
    );
    expect(mode, findsOneWidget);
    expect(settings, findsOneWidget);
    expect(find.descendant(of: mode, matching: find.text('F12')), findsOneWidget);
    expect(find.descendant(of: mode, matching: find.byIcon(Icons.check)), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(
        const ValueKey('app-menu-command-semantics-searchPrintMode'),
      ),
    );
    expect(semantics.label, contains('검색출력모드'));
    expect(semantics.label, contains('F12'));
    semanticsHandle.dispose();
  });

  testWidgets('search print submenu supports enter and left navigation', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(1200, 800));
    await tester.tap(find.byKey(const ValueKey('app-menu-group-settings')));
    await tester.pumpAndSettle();
    final submenu = find.byKey(
      const ValueKey('app-menu-submenu-searchPrint'),
    );
    await tester.tap(submenu);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('app-menu-command-searchPrintMode')),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('app-menu-command-searchPrintMode')),
      findsNothing,
    );
    expect(submenu, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('app-menu-command-searchPrintMode')),
      findsOneWidget,
    );
  });

  testWidgets('menu lifetime blocks shortcuts until the popup closes', (
    tester,
  ) async {
    final owner = Object();
    var bodyTapCount = 0;
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      onBodyTap: () => bodyTapCount += 1,
      onMenuOpenChanged: (open) {
        if (open) {
          AppShortcutBlocker.instance.activate(owner);
        } else {
          AppShortcutBlocker.instance.deactivate(owner);
        }
      },
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();
    expect(AppShortcutBlocker.instance.isBlocked, isTrue);
    await tester.tapAt(const Offset(20, 200));
    await tester.pumpAndSettle();
    expect(AppShortcutBlocker.instance.isBlocked, isFalse);
    expect(bodyTapCount, 0);
  });

  testWidgets('menu items keep standard popup spacing in compact theme', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(1200, 800));

    await tester.tap(find.byKey(const ValueKey('app-menu-group-settings')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(
        find.byKey(
          const ValueKey('app-menu-command-labelPrintSettings'),
        ),
      ).height,
      kMinInteractiveDimension,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('app-menu-submenu-searchPrint')),
          )
          .height,
      kMinInteractiveDimension,
    );
  });

  testWidgets('hidden sections do not leave separators', (tester) async {
    final states = {
      for (final command in appMenuCommands)
        command.id: command.id == AppMenuCommandId.exit
            ? const AppMenuCommandState(visible: true, enabled: true)
            : const AppMenuCommandState.hidden(),
    };
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      states: states,
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();
    expect(find.byType(Divider), findsNothing);
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsOneWidget);
  });

  testWidgets('keyboard opens and escape restores group focus', (tester) async {
    await pumpMenu(tester, size: const Size(1200, 800));
    final trigger = find.byKey(const ValueKey('app-menu-group-file'));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(trigger)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(trigger)).hasFocus, isTrue);
  });

  testWidgets('space opens and arrow navigation executes one command', (
    tester,
  ) async {
    final selected = <AppMenuCommandId>[];
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      onSelected: selected.add,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, hasLength(1));
  });

  testWidgets('overflow right enters and left returns to group level', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(600, 720));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('app-menu-overflow-group-file')),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsNothing);
    expect(
      find.byKey(const ValueKey('app-menu-overflow-group-file')),
      findsOneWidget,
    );
  });

  testWidgets('command transfers focus after popup closes', (tester) async {
    final targetFocus = FocusNode(debugLabel: 'dialog-initial-focus');
    addTearDown(targetFocus.dispose);
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      commandFocusNode: targetFocus,
      onSelected: (_) => targetFocus.requestFocus(),
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-group-settings')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-menu-command-labelPrintSettings')),
    );
    await tester.pumpAndSettle();

    expect(targetFocus.hasFocus, isTrue);
  });

  testWidgets('collapsed menu keeps a single-line ellipsized title', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(600, 720));

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('라벨 매니저 v123.456.789 긴 버전 문자열'),
    );
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(find.byKey(const ValueKey('server-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-command')), findsOneWidget);
  });

  testWidgets('short viewport constrains overflow menus without layout errors', (
    tester,
  ) async {
    await pumpMenu(tester, size: const Size(600, 260));

    await tester.tap(find.byKey(const ValueKey('app-menu-overflow')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('app-menu-overflow-group-settings')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('app-menu-submenu-searchPrint')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}