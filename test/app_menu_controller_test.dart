import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app_menu_controller.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/models/user.dart';

void main() {
  test('only attached commands are exposed through policy state', () {
    final controller = AppMenuController();
    final owner = Object();
    controller.attach(
      owner: owner,
      handlers: {
        AppMenuCommandId.exit: () {},
        AppMenuCommandId.viewPrintHistory: () {},
      },
    );

    expect(controller.commandStates[AppMenuCommandId.exit]!.visible, isTrue);
    expect(
      controller.commandStates[AppMenuCommandId.viewPrintHistory]!.visible,
      isFalse,
    );

    controller.updateSession(userGrade: UserGrade.CLIENT_USER);
    expect(
      controller.commandStates[AppMenuCommandId.viewPrintHistory]!.visible,
      isTrue,
    );
    expect(
      controller.commandStates[AppMenuCommandId.labelPrintSettings]!.visible,
      isFalse,
    );
  });

  test('detach removes commands owned by that owner', () {
    final controller = AppMenuController();
    final homeOwner = Object();
    final managerOwner = Object();
    controller.attach(
      owner: homeOwner,
      handlers: {AppMenuCommandId.exit: () {}},
    );
    controller.attach(
      owner: managerOwner,
      handlers: {AppMenuCommandId.manageScale: () {}},
    );
    controller.updateSession(userGrade: UserGrade.CLIENT_USER);

    controller.detach(managerOwner);

    expect(controller.commandStates[AppMenuCommandId.exit]!.visible, isTrue);
    expect(
      controller.commandStates[AppMenuCommandId.manageScale]!.visible,
      isFalse,
    );
  });

  test('same command cannot execute twice while its handler is pending', () async {
    final controller = AppMenuController();
    final owner = Object();
    final pending = Completer<void>();
    var callCount = 0;
    controller.attach(
      owner: owner,
      handlers: {
        AppMenuCommandId.exit: () {
          callCount += 1;
          return pending.future;
        },
      },
    );

    final first = controller.execute(AppMenuCommandId.exit);
    final second = controller.execute(AppMenuCommandId.exit);

    expect(callCount, 1);
    expect(controller.commandStates[AppMenuCommandId.exit]!.enabled, isFalse);
    pending.complete();
    await Future.wait([first, second]);
    expect(controller.commandStates[AppMenuCommandId.exit]!.enabled, isTrue);
  });

  test('work state updates printer availability without widening access', () {
    final controller = AppMenuController();
    controller.attach(
      owner: Object(),
      handlers: {
        AppMenuCommandId.labelPrintSettings: () {},
        AppMenuCommandId.scaleOutputPrinterSettings: () {},
      },
    );
    controller.updateSession(userGrade: UserGrade.CLIENT_USER);

    expect(
      controller
          .commandStates[AppMenuCommandId.scaleOutputPrinterSettings]!
          .enabled,
      isFalse,
    );
    expect(
      controller.commandStates[AppMenuCommandId.labelPrintSettings]!.enabled,
      isTrue,
    );

    controller.updateWorkState(hasScaleOutputLabelSize: true);
    expect(
      controller
          .commandStates[AppMenuCommandId.scaleOutputPrinterSettings]!
          .enabled,
      isTrue,
    );
  });
}