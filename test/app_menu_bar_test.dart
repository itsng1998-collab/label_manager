import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app_shortcut_blocker.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
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
              trailing: const SizedBox.square(
                key: ValueKey('server-status'),
                dimension: 32,
              ),
              trailingWidth: 32,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1200x800 shows three group buttons and server status', (
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
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('app-menu-group-settings')),
    );
    final serverRect = tester.getRect(
      find.byKey(const ValueKey('server-status')),
    );
    expect(serverRect.left, settingsRect.right);
    expect(tester.takeException(), isNull);
  });

  testWidgets('600x720 shows overflow and keeps server status', (tester) async {
    await pumpMenu(tester, size: const Size(600, 720));

    expect(find.byKey(const ValueKey('app-menu-overflow')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-menu-group-file')), findsNothing);
    expect(find.byKey(const ValueKey('app-menu-group-search')), findsNothing);
    expect(
      find.byKey(const ValueKey('app-menu-group-settings')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('server-status')), findsOneWidget);
    final overflowAnchor = tester.widget<MenuAnchor>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('app-menu-overflow')),
            matching: find.byType(MenuAnchor),
          )
          .first,
    );
    expect(overflowAnchor.useRootOverlay, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file popup shows only the session login command', (
    tester,
  ) async {
    Map<AppMenuCommandId, AppMenuCommandState> sessionStates({
      required bool loggedIn,
    }) => {
      for (final command in appMenuCommands)
        command.id: command.id == AppMenuCommandId.login
            ? AppMenuCommandState(visible: !loggedIn, enabled: !loggedIn)
            : command.id == AppMenuCommandId.logout
            ? AppMenuCommandState(visible: loggedIn, enabled: loggedIn)
            : command.id == AppMenuCommandId.exit
            ? const AppMenuCommandState(visible: true, enabled: true)
            : const AppMenuCommandState.hidden(),
    };

    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      states: sessionStates(loggedIn: false),
    );
    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-menu-command-logout')), findsNothing);
    expect(
      tester.getRect(
        find.byKey(const ValueKey('app-menu-command-login')),
      ).bottom,
      tester.getRect(
        find.byKey(const ValueKey('app-menu-command-exit')),
      ).top,
    );
    expect(find.byType(Divider), findsNothing);
    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();

    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      states: sessionStates(loggedIn: true),
    );
    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-login')), findsNothing);
    expect(
      find.byKey(const ValueKey('app-menu-command-logout')),
      findsOneWidget,
    );
    expect(
      tester.getRect(
        find.byKey(const ValueKey('app-menu-command-logout')),
      ).bottom,
      tester.getRect(
        find.byKey(const ValueKey('app-menu-command-exit')),
      ).top,
    );
    expect(find.byType(Divider), findsNothing);
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
    expect(bodyTapCount, 1);
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
    final commandItem = tester.widget<MenuItemButton>(
      find.byKey(
        const ValueKey('app-menu-command-labelPrintSettings'),
      ),
    );
    final submenuItem = tester.widget<SubmenuButton>(
      find.byKey(const ValueKey('app-menu-submenu-searchPrint')),
    );
    expect(
      commandItem.style?.padding?.resolve(<WidgetState>{}),
      const EdgeInsets.symmetric(horizontal: 12),
    );
    expect(
      submenuItem.style?.padding?.resolve(<WidgetState>{}),
      const EdgeInsets.symmetric(horizontal: 12),
    );
  });

  testWidgets('opening another group replaces the previous popup', (
    tester,
  ) async {
    final menuStates = <bool>[];
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      onMenuOpenChanged: menuStates.add,
    );

    await tester.tap(find.byKey(const ValueKey('app-menu-group-file')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-menu-group-search')));
    await tester.pump();
    expect(find.byKey(const ValueKey('app-menu-command-exit')), findsNothing);
    expect(
      find.byKey(const ValueKey('app-menu-command-viewPrintHistory')),
      findsOneWidget,
    );
    expect(menuStates, [true]);
  });

  testWidgets('root group menus use the root overlay', (tester) async {
    await pumpMenu(tester, size: const Size(1200, 800));

    for (final group in AppMenuGroup.values) {
      final anchor = tester.widget<MenuAnchor>(
        find
            .ancestor(
              of: find.byKey(ValueKey('app-menu-group-${group.name}')),
              matching: find.byType(MenuAnchor),
            )
            .first,
      );
      expect(anchor.useRootOverlay, isTrue);
    }
  });

  testWidgets('root menu stays above a floating preview route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final selected = <AppMenuCommandId>[];
    final window = PreviewFloatingWindow(
      initialSize: const Size(320, 360),
      usePortalHost: true,
      child: const ColoredBox(
        key: ValueKey('floating-preview-content'),
        color: Colors.red,
      ),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: labelManagerTheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: window.wrapPortalHost(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  window.show(context);
                  window.alignBottomRightTo(
                    context,
                    const Offset(1200, 416),
                  );
                },
                child: const Text('show preview'),
              ),
            ),
            appBar: AppBar(
              title: AppMenuBar(
                title: const Text('라벨 매니저'),
                commandStates: visibleStates,
                onCommandSelected: selected.add,
                onMenuOpenChanged: (open) {
                  if (open) {
                    window.keepBelowRoutePopups(
                      tester.element(find.byType(Scaffold)),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show preview'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('app-menu-group-settings')));
    await tester.pumpAndSettle();

    final command = find.byKey(
      const ValueKey('app-menu-command-labelPrintSettings'),
    );
    expect(
      tester.getRect(command).overlaps(
        tester.getRect(find.byKey(const ValueKey('floating-preview-content'))),
      ),
      isTrue,
    );
    await tester.tap(command);
    await tester.pumpAndSettle();
    expect(selected, [AppMenuCommandId.labelPrintSettings]);
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