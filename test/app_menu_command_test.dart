import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/app_menu_command.dart';

void main() {
  test('inventory has one runtime entry for every stable command ID', () {
    expect(appMenuCommands, hasLength(AppMenuCommandId.values.length));
    expect(
      appMenuCommands.map((command) => command.id).toSet(),
      AppMenuCommandId.values.toSet(),
    );
  });

  test('inventory preserves legacy order boundaries and popup ownership', () {
    expect(
      appMenuCommands
          .where((command) => command.group == AppMenuGroup.file)
          .map((command) => command.section),
      [1, 1, 1, 1, 2, 3, 3, 3],
    );
    expect(
      appMenuCommands
          .where((command) => command.group == AppMenuGroup.file)
          .map((command) => command.id),
      [
        AppMenuCommandId.manageCooperators,
        AppMenuCommandId.manageCustomers,
        AppMenuCommandId.manageMarkets,
        AppMenuCommandId.manageUsers,
        AppMenuCommandId.copyAdmin,
        AppMenuCommandId.login,
        AppMenuCommandId.logout,
        AppMenuCommandId.exit,
      ],
    );
    expect(
      appMenuCommands
          .where((command) => command.group == AppMenuGroup.search)
          .map((command) => command.section),
      [0, 1, 1, 1, 1, 1],
    );
    expect(appMenuCommand(AppMenuCommandId.login).renderInPopup, isTrue);
    expect(appMenuCommand(AppMenuCommandId.logout).renderInPopup, isTrue);
    expect(appMenuCommand(AppMenuCommandId.exit).renderInPopup, isTrue);
  });

  test('search print is the only preserved submenu relationship', () {
    final nested = appMenuCommands.where((command) => command.submenu != null);

    expect(
      nested.map((command) => command.id),
      [
        AppMenuCommandId.searchPrintMode,
        AppMenuCommandId.searchPrintSettings,
      ],
    );
    expect(
      nested.map((command) => command.submenu).toSet(),
      {AppMenuSubmenu.searchPrint},
    );
    expect(
      appMenuCommand(AppMenuCommandId.searchPrintMode).shortcutLabel,
      'F12',
    );
  });

  test('test fixture preserves legacy IDs outside runtime metadata', () {
    const legacyIds = <AppMenuCommandId, List<String>>{
      AppMenuCommandId.login: ['IDM_LOGIN'],
      AppMenuCommandId.logout: ['IDM_LOGOUT'],
      AppMenuCommandId.manageCooperators: ['IDM_COOP_MANAGE'],
      AppMenuCommandId.manageCustomers: ['IDM_CUST_MANAGE'],
      AppMenuCommandId.manageMarkets: ['IDM_MARKET_MANAGE'],
      AppMenuCommandId.manageUsers: ['IDM_USER_MANAGE'],
      AppMenuCommandId.copyAdmin: ['IDM_ADMIN_COPY'],
      AppMenuCommandId.exit: ['ID_APP_EXIT'],
      AppMenuCommandId.searchAndReplace: ['IDM_SEARCH_AND_REPLACE'],
      AppMenuCommandId.viewPrintHistory: ['IDM_PRINT_LOG'],
      AppMenuCommandId.viewLoginHistory: ['IDM_LOGIN_LOG'],
      AppMenuCommandId.viewContentHistory: ['IDM_CONTENT_SAVE_LOG'],
      AppMenuCommandId.viewCommonLabelHistory: ['IDM_COMMON_LABEL_LOG'],
      AppMenuCommandId.viewPrintStatistics: ['IDM_STATUS_PRINT'],
      AppMenuCommandId.editItemInfo: ['IDM_EDIT_ITEMINFO'],
      AppMenuCommandId.addNutritionType: ['IDM_NEW_NUTTYPE'],
      AppMenuCommandId.addNutritionTable: ['IDM_NEW_NUTBOX'],
      AppMenuCommandId.manageFixedColumns: [
        'IDM_FIX_COLUMN_MANAGER',
        'IDM_FIX_COLUMN_MANAGE',
      ],
      AppMenuCommandId.manageScale: ['IDM_SETUP_SCALE'],
      AppMenuCommandId.labelPrintSettings: ['IDM_SETUP_PRINT'],
      AppMenuCommandId.scaleOutputPrinterSettings: ['IDM_SETUP_PRINT'],
      AppMenuCommandId.tradeBoard: ['IDM_TRADE_BOARD'],
      AppMenuCommandId.ethernetSettings: ['IDM_SETUP_ETHENET'],
      AppMenuCommandId.updateNotice: ['IDM_UPDATE_NOTICE'],
      AppMenuCommandId.searchPrintMode: ['IDM_SEARCH_PRINT_MODE'],
      AppMenuCommandId.searchPrintSettings: ['IDM_SEARCH_PRINT_SETUP'],
    };

    expect(legacyIds.keys.toSet(), AppMenuCommandId.values.toSet());
  });
}