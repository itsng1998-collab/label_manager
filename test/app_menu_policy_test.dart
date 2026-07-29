import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app_menu_policy.dart';
import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/data/user_dao.dart';

void main() {
  AppMenuCommandState state(
    AppMenuPolicyContext context,
    AppMenuCommandId id,
  ) => AppMenuPolicy(context).stateFor(id);

  test('logged-out state exposes only login and exit commands', () {
    const context = AppMenuPolicyContext();

    expect(state(context, AppMenuCommandId.login).visible, isTrue);
    expect(state(context, AppMenuCommandId.exit).visible, isTrue);
    expect(state(context, AppMenuCommandId.logout).visible, isFalse);
    expect(state(context, AppMenuCommandId.viewPrintHistory).visible, isFalse);
  });

  test('grade policies keep system, admin, and manager boundaries', () {
    const system = AppMenuPolicyContext(
      userGrade: UserGrade.SYSTEM_ADMIN_USER,
    );
    const coop = AppMenuPolicyContext(
      userGrade: UserGrade.COOP_ADMIN_USER,
    );
    const manager = AppMenuPolicyContext(
      userGrade: UserGrade.MANAGER_USER,
    );
    const client = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
    );

    expect(state(system, AppMenuCommandId.manageCooperators).visible, isTrue);
    expect(state(coop, AppMenuCommandId.manageCooperators).visible, isFalse);
    expect(state(coop, AppMenuCommandId.manageCustomers).visible, isTrue);
    expect(state(coop, AppMenuCommandId.manageMarkets).visible, isTrue);
    expect(state(manager, AppMenuCommandId.manageMarkets).visible, isFalse);
    expect(state(client, AppMenuCommandId.manageMarkets).visible, isFalse);
    expect(state(client, AppMenuCommandId.viewPrintHistory).visible, isTrue);
  });

  test('trusted session flags preserve distinct legacy permission edges', () {
    const firstAdminLogin = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
      isFirstConnectByAdmin: true,
    );
    const adminConnect = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
      isAdminConnect: true,
    );

    expect(
      state(firstAdminLogin, AppMenuCommandId.manageCustomers).visible,
      isTrue,
    );
    expect(
      state(firstAdminLogin, AppMenuCommandId.manageMarkets).visible,
      isFalse,
    );
    expect(
      state(firstAdminLogin, AppMenuCommandId.manageCooperators).visible,
      isFalse,
    );
    expect(state(adminConnect, AppMenuCommandId.manageCooperators).visible,
        isTrue);
    expect(state(adminConnect, AppMenuCommandId.manageMarkets).visible, isTrue);
  });

  test('session flags cannot authorize a logged-out state', () {
    const context = AppMenuPolicyContext(
      isAdminConnect: true,
      isCoopAdminConnect: true,
      isFirstConnectByAdmin: true,
    );

    expect(state(context, AppMenuCommandId.manageCooperators).visible, isFalse);
    expect(state(context, AppMenuCommandId.manageCustomers).visible, isFalse);
    expect(state(context, AppMenuCommandId.manageMarkets).visible, isFalse);
  });

  test('client database grade is evaluated before menu policy', () {
    final user = userFromRow({
      'USER_ID': 'client',
      'GRADE': UserGrade.CLIENT_USER.code,
    });
    final context = AppMenuPolicyContext(userGrade: user.grade);

    expect(user.grade, UserGrade.CLIENT_USER);
    expect(state(context, AppMenuCommandId.manageCooperators).visible, isFalse);
    expect(state(context, AppMenuCommandId.viewPrintHistory).visible, isTrue);
  });

  test('legacy inactive and unreachable commands stay hidden', () {
    const context = AppMenuPolicyContext(
      userGrade: UserGrade.SYSTEM_ADMIN_USER,
    );

    expect(state(context, AppMenuCommandId.tradeBoard).visible, isFalse);
    expect(state(context, AppMenuCommandId.ethernetSettings).visible, isFalse);
    expect(state(context, AppMenuCommandId.manageFixedColumns).visible, isFalse);
  });

  test('scale printer settings alone require a selected label size', () {
    const noLabelSize = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
    );
    const withLabelSize = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
      hasScaleOutputLabelSize: true,
    );

    final scaleDisabled =
        state(noLabelSize, AppMenuCommandId.scaleOutputPrinterSettings);
    expect(scaleDisabled.visible, isTrue);
    expect(scaleDisabled.enabled, isFalse);
    expect(
      scaleDisabled.disabledReason,
      AppMenuPolicy.scaleOutputLabelSizeRequired,
    );
    expect(
      state(noLabelSize, AppMenuCommandId.labelPrintSettings).enabled,
      isTrue,
    );
    expect(
      state(withLabelSize, AppMenuCommandId.scaleOutputPrinterSettings).enabled,
      isTrue,
    );
  });

  test('busy and context blocks disable visible commands without a reason', () {
    const context = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
      busyCommands: {AppMenuCommandId.labelPrintSettings},
      contextBlockedCommands: {AppMenuCommandId.editItemInfo},
    );

    final busy = state(context, AppMenuCommandId.labelPrintSettings);
    final blocked = state(context, AppMenuCommandId.editItemInfo);
    expect(busy.visible, isTrue);
    expect(busy.enabled, isFalse);
    expect(busy.disabledReason, isNull);
    expect(blocked.visible, isTrue);
    expect(blocked.enabled, isFalse);
    expect(blocked.disabledReason, isNull);
  });

  test('work block disables login, logout, and regular visible commands', () {
    const loggedOut = AppMenuPolicyContext(workBlocked: true);
    const loggedIn = AppMenuPolicyContext(
      userGrade: UserGrade.MANAGER_USER,
      workBlocked: true,
    );

    expect(state(loggedOut, AppMenuCommandId.login).enabled, isFalse);
    expect(state(loggedIn, AppMenuCommandId.logout).enabled, isFalse);
    expect(state(loggedIn, AppMenuCommandId.editItemInfo).enabled, isFalse);
  });

  test('editable is based on the actual grade, not session flags', () {
    const clientConnect = AppMenuPolicyContext(
      userGrade: UserGrade.CLIENT_USER,
      isAdminConnect: true,
    );
    const manager = AppMenuPolicyContext(
      userGrade: UserGrade.MANAGER_USER,
    );

    expect(
      AppMenuPolicy(clientConnect).allows(AppMenuPermission.editable),
      isFalse,
    );
    expect(
      AppMenuPolicy(manager).allows(AppMenuPermission.editable),
      isTrue,
    );
  });
}