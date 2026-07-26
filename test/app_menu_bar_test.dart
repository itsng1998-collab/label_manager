import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/widgets/app_menu_bar.dart';

void main() {
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
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: AppMenuBar(
              title: const Text(
                '라벨 매니저 v123.456.789 긴 버전 문자열',
                overflow: TextOverflow.ellipsis,
              ),
              commandStates: states ?? visibleStates,
              onCommandSelected: onSelected ?? (_) {},
              onMenuOpenChanged: onMenuOpenChanged,
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
    await pumpMenu(
      tester,
      size: const Size(1200, 800),
      onSelected: selected.add,
      onMenuOpenChanged: menuStates.add,
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
}