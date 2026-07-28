import 'package:label_manager/models/app_menu_command.dart';
import 'package:label_manager/models/user.dart';

class AppMenuPolicyContext {
  const AppMenuPolicyContext({
    this.userGrade,
    this.isAdminConnect = false,
    this.isCoopAdminConnect = false,
    this.isFirstConnectByAdmin = false,
    this.workBlocked = false,
    this.busyCommands = const <AppMenuCommandId>{},
    this.contextBlockedCommands = const <AppMenuCommandId>{},
    this.hasScaleOutputLabelSize = false,
  });

  final UserGrade? userGrade;
  final bool isAdminConnect;
  final bool isCoopAdminConnect;
  final bool isFirstConnectByAdmin;
  final bool workBlocked;
  final Set<AppMenuCommandId> busyCommands;
  final Set<AppMenuCommandId> contextBlockedCommands;
  final bool hasScaleOutputLabelSize;

  bool get isLoggedIn => userGrade != null;
}

class AppMenuPolicy {
  const AppMenuPolicy(this.context);

  static const scaleOutputLabelSizeRequired =
      '라벨사이즈를 먼저 선택해주세요.';

  final AppMenuPolicyContext context;

  bool allows(AppMenuPermission permission) {
    if (permission == AppMenuPermission.always) {
      return true;
    }
    if (!context.isLoggedIn) {
      return false;
    }

    final grade = context.userGrade!;
    switch (permission) {
      case AppMenuPermission.always:
        return true;
      case AppMenuPermission.loggedIn:
        return true;
      case AppMenuPermission.editable:
        return grade != UserGrade.CLIENT_USER;
      case AppMenuPermission.systemAdminCommand:
        return grade == UserGrade.SYSTEM_ADMIN_USER ||
            context.isAdminConnect;
      case AppMenuPermission.adminCommand:
        return grade == UserGrade.SYSTEM_ADMIN_USER ||
            grade == UserGrade.COOP_ADMIN_USER ||
            context.isAdminConnect ||
            context.isCoopAdminConnect ||
            context.isFirstConnectByAdmin;
      case AppMenuPermission.managerCommand:
        return grade == UserGrade.SYSTEM_ADMIN_USER ||
            grade == UserGrade.COOP_ADMIN_USER ||
            context.isAdminConnect ||
            context.isCoopAdminConnect;
    }
  }

  AppMenuCommandState stateFor(AppMenuCommandId id) {
    final command = appMenuCommand(id);
    if (command.availability != AppMenuAvailability.active) {
      return const AppMenuCommandState.hidden();
    }
    if (id == AppMenuCommandId.login) {
      return AppMenuCommandState(
        visible: !context.isLoggedIn,
        enabled: !context.isLoggedIn && !context.workBlocked,
      );
    }
    if (id == AppMenuCommandId.logout) {
      return AppMenuCommandState(
        visible: context.isLoggedIn,
        enabled: context.isLoggedIn && !context.workBlocked,
      );
    }
    if (!allows(command.permission)) {
      return const AppMenuCommandState.hidden();
    }

    if (id == AppMenuCommandId.scaleOutputPrinterSettings &&
        !context.hasScaleOutputLabelSize) {
      return const AppMenuCommandState(
        visible: true,
        enabled: false,
        disabledReason: scaleOutputLabelSizeRequired,
      );
    }

    final enabled =
        !context.workBlocked &&
        !context.busyCommands.contains(id) &&
        !context.contextBlockedCommands.contains(id);
    return AppMenuCommandState(visible: true, enabled: enabled);
  }
}