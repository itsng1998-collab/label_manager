import 'package:flutter/widgets.dart';

enum AppMenuGroup { file, search, settings }

enum AppMenuSubmenu { searchPrint }

enum AppMenuCommandId {
  login,
  logout,
  manageCooperators,
  manageCustomers,
  manageMarkets,
  manageUsers,
  copyAdmin,
  exit,
  searchAndReplace,
  viewPrintHistory,
  viewLoginHistory,
  viewContentHistory,
  viewCommonLabelHistory,
  viewPrintStatistics,
  editItemInfo,
  addNutritionType,
  addNutritionTable,
  manageFixedColumns,
  manageScale,
  labelPrintSettings,
  scaleOutputPrinterSettings,
  tradeBoard,
  ethernetSettings,
  updateNotice,
  searchPrintMode,
  searchPrintSettings,
}

enum AppMenuPermission {
  always,
  loggedIn,
  editable,
  systemAdminCommand,
  adminCommand,
  managerCommand,
}

enum AppMenuAvailability { active, legacyInactive, legacyUnreachable }

class AppMenuCommandMetadata {
  const AppMenuCommandMetadata({
    required this.id,
    required this.group,
    required this.label,
    required this.permission,
    required this.section,
    this.availability = AppMenuAvailability.active,
    this.submenu,
    this.icon,
    this.shortcutLabel,
    this.renderInPopup = true,
  });

  final AppMenuCommandId id;
  final AppMenuGroup group;
  final String label;
  final AppMenuPermission permission;
  final int section;
  final AppMenuAvailability availability;
  final AppMenuSubmenu? submenu;
  final IconData? icon;
  final String? shortcutLabel;
  final bool renderInPopup;
}

class AppMenuCommandState {
  const AppMenuCommandState({
    required this.visible,
    required this.enabled,
    this.disabledReason,
  });

  const AppMenuCommandState.hidden()
      : visible = false,
        enabled = false,
        disabledReason = null;

  final bool visible;
  final bool enabled;
  final String? disabledReason;
}

const appMenuCommands = <AppMenuCommandMetadata>[
  AppMenuCommandMetadata(
    id: AppMenuCommandId.login,
    group: AppMenuGroup.file,
    label: '로그인',
    permission: AppMenuPermission.always,
    section: 0,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.logout,
    group: AppMenuGroup.file,
    label: '로그아웃',
    permission: AppMenuPermission.loggedIn,
    section: 0,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageCooperators,
    group: AppMenuGroup.file,
    label: '협력업체 관리',
    permission: AppMenuPermission.systemAdminCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageCustomers,
    group: AppMenuGroup.file,
    label: '거래처 관리',
    permission: AppMenuPermission.adminCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageMarkets,
    group: AppMenuGroup.file,
    label: '지점 관리',
    permission: AppMenuPermission.managerCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageUsers,
    group: AppMenuGroup.file,
    label: '사용자 관리',
    permission: AppMenuPermission.managerCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.copyAdmin,
    group: AppMenuGroup.file,
    label: '관리자 복사',
    permission: AppMenuPermission.adminCommand,
    section: 2,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.exit,
    group: AppMenuGroup.file,
    label: '종료',
    permission: AppMenuPermission.always,
    section: 3,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.searchAndReplace,
    group: AppMenuGroup.search,
    label: '검색 및 치환',
    permission: AppMenuPermission.managerCommand,
    section: 0,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.viewPrintHistory,
    group: AppMenuGroup.search,
    label: '발행내역 보기',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.viewLoginHistory,
    group: AppMenuGroup.search,
    label: '사용자 접속 이력 보기',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.viewContentHistory,
    group: AppMenuGroup.search,
    label: '데이터내용 이력 조회',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.viewCommonLabelHistory,
    group: AppMenuGroup.search,
    label: '공용라벨 수정 이력 보기',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.viewPrintStatistics,
    group: AppMenuGroup.search,
    label: '발행 통계 조회',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.editItemInfo,
    group: AppMenuGroup.settings,
    label: '품목별 정보 편집',
    permission: AppMenuPermission.loggedIn,
    section: 0,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.addNutritionType,
    group: AppMenuGroup.settings,
    label: '영양성분 형식추가',
    permission: AppMenuPermission.adminCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.addNutritionTable,
    group: AppMenuGroup.settings,
    label: '영양성분표 추가',
    permission: AppMenuPermission.adminCommand,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageFixedColumns,
    group: AppMenuGroup.settings,
    label: '고정 항목 관리',
    permission: AppMenuPermission.systemAdminCommand,
    section: 1,
    availability: AppMenuAvailability.legacyUnreachable,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.manageScale,
    group: AppMenuGroup.settings,
    label: '전자저울 관리',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.labelPrintSettings,
    group: AppMenuGroup.settings,
    label: '라벨출력 프린터 설정',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.scaleOutputPrinterSettings,
    group: AppMenuGroup.settings,
    label: '저울출력 프린터 설정',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.tradeBoard,
    group: AppMenuGroup.settings,
    label: '거래게시판',
    permission: AppMenuPermission.loggedIn,
    section: 1,
    availability: AppMenuAvailability.legacyInactive,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.ethernetSettings,
    group: AppMenuGroup.settings,
    label: '이더넷 설정',
    permission: AppMenuPermission.loggedIn,
    section: 1,
    availability: AppMenuAvailability.legacyInactive,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.updateNotice,
    group: AppMenuGroup.settings,
    label: '업데이트 메시지',
    permission: AppMenuPermission.loggedIn,
    section: 1,
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.searchPrintMode,
    group: AppMenuGroup.settings,
    label: '검색출력모드',
    permission: AppMenuPermission.loggedIn,
    section: 1,
    submenu: AppMenuSubmenu.searchPrint,
    shortcutLabel: 'F12',
  ),
  AppMenuCommandMetadata(
    id: AppMenuCommandId.searchPrintSettings,
    group: AppMenuGroup.settings,
    label: '설정',
    permission: AppMenuPermission.loggedIn,
    section: 1,
    submenu: AppMenuSubmenu.searchPrint,
  ),
];

AppMenuCommandMetadata appMenuCommand(AppMenuCommandId id) =>
    appMenuCommands.firstWhere((command) => command.id == id);