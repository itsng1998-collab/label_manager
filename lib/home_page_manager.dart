import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' show max, min, pi;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tabbed_view/tabbed_view.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/app_menu_controller.dart';
import 'package:label_manager/core/app_shortcut_blocker.dart';
import 'package:label_manager/core/auto_login_guard.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/features/item/application/item_manager_session_loader.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/item/application/item_manager_save_service.dart';
import 'package:label_manager/features/item/application/item_manager_order_service.dart';
import 'package:label_manager/features/item/application/item_manager_xlsx.dart';
import 'package:label_manager/features/item/domain/item_manager_rules.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/presentation/item_manage.dart';
import 'package:label_manager/features/item/presentation/item_order_dialog.dart';
import 'package:label_manager/features/automatic_item_update/application/automatic_item_update_loader.dart';
import 'package:label_manager/features/automatic_item_update/application/automatic_item_update_save_service.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';
import 'package:label_manager/features/automatic_item_update/presentation/automatic_item_update_page.dart';
import 'package:label_manager/features/gs1/application/gs1_ai_definitions.dart';
import 'package:label_manager/features/gs1/data/gs1_ai_dao.dart';
import 'package:label_manager/features/label_column/application/column_type_loader.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/label_column/application/special_columns.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';
import 'package:label_manager/features/last_connect/data/last_connect_dao.dart';
import 'package:label_manager/features/brand/data/brand_dao.dart';
import 'package:label_manager/features/brand/domain/brand.dart';
import 'package:label_manager/features/label_column/data/column_dao.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/domain/label_print_auto_increment.dart';
import 'package:label_manager/features/label_print/presentation/label_print_page.dart';
import 'package:label_manager/features/scale_output/application/scale_output.dart';
import 'package:label_manager/features/scale_output/data/db_scale_connect_info.dart';
import 'package:label_manager/features/scale_output/presentation/scale_output_page.dart';
import 'package:label_manager/features/search_print/application/search_print_command.dart';
import 'package:label_manager/features/search_print/data/search_print.dart';
import 'package:label_manager/features/search_print/domain/search_print.dart';
import 'package:label_manager/features/search_print/domain/search_print_settings.dart';
import 'package:label_manager/features/search_print/presentation/search_print_settings_dialog.dart';
import 'package:label_manager/printing/label_print_pipeline.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/printing/label_print_persistence.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_column/application/label_column_save_service.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/core/app_menu_command.dart';
import 'package:label_manager/features/update_notice/data/notice_dao.dart';
import 'package:label_manager/features/update_notice/domain/notice.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/label_sheet_ai_import_temp.dart';
import 'package:label_manager/features/label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/features/label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/features/label_sheet/label_sheet_rtf_preview_debug.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/item_manager_debug_log.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/core/table_search.dart';
import 'package:label_manager/features/label_print/domain/item_code_data_resolver.dart';
import 'package:label_manager/features/date_setup/presentation/date_type_setup_dialog.dart';
import 'package:label_manager/features/label_sheet/application/common_label_connections.dart';
import 'package:label_manager/features/label_sheet/presentation/common_label_manage.dart';
import 'package:label_manager/features/label_sheet/presentation/rtf_preview_ai_convert_button.dart';
import 'package:label_manager/features/cooperator/presentation/cooperator_manager_dialog.dart';
import 'package:label_manager/features/customer/presentation/customer_manager_dialog.dart';
import 'package:label_manager/features/market/presentation/market_manager_dialog.dart';
import 'package:label_manager/features/managed_user/presentation/user_manager_dialog.dart';
import 'package:label_manager/features/admin_copy/presentation/admin_copy_dialog.dart';
import 'package:label_manager/features/search_and_replace/domain/search_and_replace.dart';
import 'package:label_manager/features/search_and_replace/presentation/search_and_replace_dialog.dart';
import 'package:label_manager/features/item/presentation/item_info_dialog.dart';
import 'package:label_manager/features/nutrition/presentation/nutrition_type_dialog.dart';
import 'package:label_manager/features/nutrition/presentation/nutrition_box_dialog.dart';
import 'package:label_manager/features/update_notice/presentation/update_notice_dialog.dart';
import 'package:label_manager/features/label_column/presentation/label_column_edit_dialog.dart';
import 'package:label_manager/features/common_label_history/presentation/common_label_history_dialog.dart';
import 'package:label_manager/features/content_save_history/presentation/content_save_history_dialog.dart';
import 'package:label_manager/widgets/preview_floating_window.dart';
import 'package:label_manager/features/print_history/presentation/print_history_dialog.dart';
import 'package:label_manager/features/status_print/presentation/status_print_dialog.dart';
import 'package:label_manager/features/login_history/presentation/login_history_page.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_print_settings_dialog.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

bool itemManagerSearchVisibleForTab(Object? tabValue) =>
  tabValue == 'items' ||
  tabValue == 'label_print' ||
  tabValue == 'auto_update' ||
  tabValue == 'scale_output';

@visibleForTesting
Object? homeTabShortcutValue({
  required LogicalKeyboardKey key,
  required bool editing,
  required bool modifierPressed,
}) {
  if (editing || modifierPressed) return null;
  return switch (key) {
    LogicalKeyboardKey.f1 => 'items',
    LogicalKeyboardKey.f2 => 'common_label',
    LogicalKeyboardKey.f3 => 'label_print',
    _ => null,
  };
}

@visibleForTesting
bool labelPrintTabSelectionBlocked({
  required bool hasActiveEditing,
  required bool itemDraftCommandBusy,
  required bool itemDraftDirty,
}) => hasActiveEditing || itemDraftCommandBusy || itemDraftDirty;

@visibleForTesting
bool appMenuWorkBlocked({
  required int itemManagerQueryDepth,
  required bool itemEditing,
  required bool autoItemUpdateEditing,
  required bool scaleOutputEditing,
}) =>
    itemManagerQueryDepth > 0 ||
    itemEditing ||
    autoItemUpdateEditing ||
    scaleOutputEditing;

bool homeTabTapBlocked({
  required Object? currentTabValue,
  required bool itemDraftContextChangeBlocked,
  required bool autoItemUpdateContextChangeBlocked,
}) => switch (currentTabValue) {
  'items' => itemDraftContextChangeBlocked,
  'auto_update' => autoItemUpdateContextChangeBlocked,
  _ => false,
};

bool homeTabVisibleForUser({
  required Object? tabValue,
  required bool canEdit,
}) => switch (tabValue) {
  'common_label' || 'auto_update' => canEdit,
  _ => true,
};

@visibleForTesting
bool debugHomeTabVisibleForUserForTesting({
  required Object? tabValue,
  required bool canEdit,
}) => homeTabVisibleForUser(tabValue: tabValue, canEdit: canEdit);

@visibleForTesting
bool debugHomeTabTapBlockedForTesting({
  required Object? currentTabValue,
  required bool itemDraftContextChangeBlocked,
  required bool autoItemUpdateContextChangeBlocked,
}) => homeTabTapBlocked(
  currentTabValue: currentTabValue,
  itemDraftContextChangeBlocked: itemDraftContextChangeBlocked,
  autoItemUpdateContextChangeBlocked: autoItemUpdateContextChangeBlocked,
);

const Duration itemManagerLoadProgressDuration = Duration(days: 1);
const String itemManagerLoadFailureMessage =
    '품목 데이터를 불러오지 못했습니다. 네트워크 연결을 확인한 뒤 다시 시도해 주세요.';
const double _blockedHomeTabTapOverlayHeight = 44;

@visibleForTesting
bool commonLabelSheetDirtyChangeBelongsToCurrentSession({
  required int? sourceLabelSizeId,
  required int? currentLabelSizeId,
}) => sourceLabelSizeId == currentLabelSizeId;

@visibleForTesting
LabelSize? commonLabelSavedSessionValue({
  required LabelSize? current,
  required LabelSize saved,
}) => current?.labelSizeId == saved.labelSizeId ? saved : current;

@visibleForTesting
String homeLabelContentKey(LabelSize? labelSize, int setupRevision) {
  final formData = labelSize?.labelSizeCommon?.rtf ?? '';
  return '${labelSize?.labelSizeId ?? 'none'}:'
      '${labelSize?.labelSizeCommon?.width ?? 0}:'
      '${labelSize?.labelSizeCommon?.height ?? 0}:'
      '${formData.length}:${formData.hashCode}:$setupRevision';
}

Future<void> showItemManagerLoadFailureDialog(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('품목 조회 오류'),
      content: const Text(itemManagerLoadFailureMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class HomePageManagerController {
  Object? _owner;
  Future<void> Function()? _openScaleConnectSettings;
  Future<void> Function()? _openLabelPrintSettings;
  Future<void> Function()? _openScaleOutputPrinterSettings;
  ValueChanged<bool>? _appMenuOpenChanged;

  void attach({
    required Object owner,
    required Future<void> Function() openScaleConnectSettings,
    required Future<void> Function() openLabelPrintSettings,
    required Future<void> Function() openScaleOutputPrinterSettings,
    required ValueChanged<bool> appMenuOpenChanged,
  }) {
    _owner = owner;
    _openScaleConnectSettings = openScaleConnectSettings;
    _openLabelPrintSettings = openLabelPrintSettings;
    _openScaleOutputPrinterSettings = openScaleOutputPrinterSettings;
    _appMenuOpenChanged = appMenuOpenChanged;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _openScaleConnectSettings = null;
    _openLabelPrintSettings = null;
    _openScaleOutputPrinterSettings = null;
    _appMenuOpenChanged = null;
  }

  Future<void> openScaleConnectSettings() async {
    await _openScaleConnectSettings?.call();
  }

  Future<void> openLabelPrintSettings() async {
    await _openLabelPrintSettings?.call();
  }

  Future<void> openScaleOutputPrinterSettings() async {
    await _openScaleOutputPrinterSettings?.call();
  }

  void appMenuOpenChanged(bool isOpen) {
    _appMenuOpenChanged?.call(isOpen);
  }
}

/// 로그인 이후 메인 UI
class HomePageManager extends StatefulWidget {
  final AppMenuController appMenuController;
  final HomePageManagerController controller;
  final bool searchPrintModeActive;
  final VoidCallback onToggleSearchPrintMode;
  final bool adminCopyCooperatorSelectionEnabled;
  final bool customerCooperatorSelectionEnabled;
  final bool marketCooperatorSelectionEnabled;
  final bool userCooperatorSelectionEnabled;
  final bool userCustomerSelectionEnabled;
  final bool userMarketSelectionEnabled;
  final bool userCredentialsVisible;
  final Brand? selectedBrand;
  final ValueChanged<Brand?> onBrandChanged;
  final LabelSize? selectedLabelSize;
  final ValueChanged<LabelSize?> onLabelSizeChanged;
  final ValueChanged<LifecycleExitSnapshotProvider?>?
  onExitSnapshotProviderChanged;

  const HomePageManager({
    super.key,
    required this.appMenuController,
    required this.controller,
    required this.searchPrintModeActive,
    required this.onToggleSearchPrintMode,
    required this.adminCopyCooperatorSelectionEnabled,
    required this.customerCooperatorSelectionEnabled,
    required this.marketCooperatorSelectionEnabled,
    required this.userCooperatorSelectionEnabled,
    required this.userCustomerSelectionEnabled,
    required this.userMarketSelectionEnabled,
    required this.userCredentialsVisible,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.selectedLabelSize,
    required this.onLabelSizeChanged,
    this.onExitSnapshotProviderChanged,
  });

  @override
  State<HomePageManager> createState() => _HomePageManagerState();
}

@visibleForTesting
class ItemElementCommitQueue {
  Future<void> _tail = Future<void>.value();
  Object? _lastError;
  StackTrace? _lastStackTrace;

  Future<void> enqueue(Future<void> Function() commit) {
    final operation = _tail.then((_) => commit());
    _tail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _lastError = error;
        _lastStackTrace = stackTrace;
      },
    );
    return operation;
  }

  Future<void> wait() async {
    await _tail;
    final error = _lastError;
    if (error != null) {
      final stackTrace = _lastStackTrace ?? StackTrace.current;
      _lastError = null;
      _lastStackTrace = null;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

@visibleForTesting
class SettingsOperationGate {
  bool _submitting = false;

  bool get submitting => _submitting;

  Future<void> run(Future<void> Function() submit) async {
    if (_submitting) return;
    _submitting = true;
    try {
      await submit();
    } finally {
      _submitting = false;
    }
  }
}

@visibleForTesting
Future<Object?> runSettingsWriteThenReload<T>({
  required Future<T> Function() write,
  required void Function(T value) onCommitted,
  required Future<void> Function(T value) reload,
}) async {
  final value = await write();
  onCommitted(value);
  try {
    await reload(value);
    return null;
  } catch (error) {
    return error;
  }
}

class _HomePageManagerState extends State<HomePageManager> {
  static const double _rtfPreviewInitialReadableScale = 1.0;
  static const double _itemPreviewScrollbarThicknessFallback = 8.0;
  static const double _itemPreviewTableInset = 10.0;

  late TabbedViewController _tabController;
  Object? _searchPrintModeLockedTabValue;
  final TextEditingController _tabSearchController = TextEditingController();
  final ItemManageController _itemManageController = ItemManageController();
  final AutoItemUpdatePageController _autoItemUpdatePageController =
      AutoItemUpdatePageController();
  final LabelPrintSessionController _labelPrintSessionController =
      LabelPrintSessionController();
  final LabelSheetOutputCaptureController _labelPrintCaptureController =
      LabelSheetOutputCaptureController();
    final ScaleOutputPageController _scaleOutputPageController =
      ScaleOutputPageController();
    final ScaleOutputSessionController _scaleOutputSessionController =
      ScaleOutputSessionController();
    final LabelSheetOutputCaptureController _scaleOutputCaptureController =
      LabelSheetOutputCaptureController();
      final LabelSheetZoomController _itemOutputPreviewZoomController =
        LabelSheetZoomController();
      final LabelSheetZoomController _itemElementPreviewZoomController =
        LabelSheetZoomController();
    final ScaleConnectionService _scaleConnectionService =
      ScaleConnectionService();
  LabelPrintUnit? _labelPrintRenderUnit;
  DateTime? _labelPrintRenderReferenceAt;
    ScaleOutputUnit? _scaleOutputRenderUnit;
    DateTime? _scaleOutputRenderReferenceAt;
  final GlobalKey _itemPreviewButtonKey = GlobalKey();
  final GlobalKey _commonLabelPreviewButtonKey = GlobalKey();
  final GlobalKey _rtfPreviewBoxKey = GlobalKey();
  int? _labelSizesBrandId;
  int _labelLoadToken = 0;
  bool _itemManagerLoadFailureDialogVisible = false;
  int _itemManagerReadyGeneration = 0;
  Completer<void>? _itemManagerReadyCompleter;
  int? _labelDialogBrandChangeInFlightId;
  bool _labelDialogBrandChangeInFlight = false;
  int _rtfPreviewCaptureGeneration = 0;
  int _rtfPreviewResizeFinalizeToken = 0;
  PreviewFloatingWindow? _itemPreviewWindow;
  PreviewFloatingWindow? _commonLabelPreviewWindow;
  final LabelSheetImageImportController _commonLabelImageImportController =
      LabelSheetImageImportController();
  final LabelSheetEditingLifecycleController
  _commonLabelEditingLifecycleController =
      LabelSheetEditingLifecycleController();
  Timer? _rtfPreviewResizeDebounce;
  Timer? _rtfPreviewResizeFinalizeTimer;
  Timer? _scaleAutoPrintTimer;
  List<Brand> _brands = const <Brand>[];
  List<TabData> _tabs = const <TabData>[];
  LabelSize? _currentLabelSize;
  String? _rtfPreviewReadyKey;
  String? _rtfPreviewTargetKey;
  String? _rtfPreviewWindowKey;
  Size? _rtfPreviewTargetContentSize;
  Size? _rtfPreviewRefreshedTargetContentSize;
  Size? _rtfPreviewLastResolvedImageSize;
  LabelSheetNativeRtfPngImage? _rtfPreviewLastNativeImage;
  String? _rtfPreviewLastNativeImageKey;
  Rect? _itemTableRect;
  Rect? _commonLabelGridRect;
  ItemOfMarket? _selectedItemOfMarket;
  int? _selectedItemIndex;
  ItemManagerDraftController? _itemDraftController;
  AutoItemUpdateDraftController? _autoItemUpdateDraftController;
  Set<int> _publishCheckedItemIds = const <int>{};
  bool _scaleOutputShowAllRows = true;
  bool _scaleOutputRowsDirty = true;
  List<int> _itemDraftTargetMarketIds = const [];
  int? _itemDraftLoadedCustomerId;
  int? _itemDraftLoadedBrandId;
  int? _itemDraftLoadedLabelSizeId;
  int? _itemDraftLoadedMarketId;
  String _itemDraftEmptyElementPayload = '';
  bool _rtfPreviewHasResolvedImage = false;
  bool _autoSelectedCommonLabelOnce = false;
  bool _commonLabelTabActivated = false;
  bool _itemPreviewAlignedToTable = false;
  bool _itemPreviewClosedByUser = false;
  bool _commonLabelPreviewClosedByUser = false;
  bool _commonLabelPreviewHiddenForSheetDialog = false;
  bool _commonLabelPreviewMovedByUser = false;
  bool _itemDraftCommandBusy = false;
  bool _autoItemUpdateCommandBusy = false;
  bool _commonLabelSheetDirty = false;
  bool _labelColumnEditCommandBusy = false;
  int _itemManagerQueryDepth = 0;
  final ItemElementCommitQueue _itemElementCommitQueue =
      ItemElementCommitQueue();
  final CooperatorManagerController _cooperatorManagerController =
      CooperatorManagerController();
  final CustomerManagerController _customerManagerController =
      CustomerManagerController();
    final MarketManagerController _marketManagerController =
      MarketManagerController();
  final UserManagerController _userManagerController = UserManagerController();
  final AdminCopyController _adminCopyController = AdminCopyController();
  final SearchAndReplaceController _searchAndReplaceController =
      SearchAndReplaceController();
  final ItemInfoController _itemInfoController = ItemInfoController();
  final NutritionTypeDialogController _nutritionTypeDialogController =
      NutritionTypeDialogController();
  final NutritionBoxDialogController _nutritionBoxDialogController =
      NutritionBoxDialogController();
    final UpdateNoticeDialogController _updateNoticeDialogController =
      UpdateNoticeDialogController();
    final SearchPrintSettingsDialogController
    _searchPrintSettingsDialogController = SearchPrintSettingsDialogController();
  bool _lastReportedItemDraftDirty = false;
  int _labelSetupRevision = 0;
  bool _suppressNextBrandDidUpdateLabelLoad = false;
  int _itemDraftCancelTraceSequence = 0;
  int? _lastItemDraftCancelTraceId;

  static const String _itemDraftCancelDebugVersion =
      'item-draft-cancel-debug-v1';

  OverlayEntry? _brandSettingsOverlayEntry;
  OverlayEntry? _cooperatorManagerOverlayEntry;
  LifecycleParticipant? _cooperatorManagerLifecycleParticipant;
  OverlayEntry? _customerManagerOverlayEntry;
  LifecycleParticipant? _customerManagerLifecycleParticipant;
  OverlayEntry? _marketManagerOverlayEntry;
  LifecycleParticipant? _marketManagerLifecycleParticipant;
  OverlayEntry? _userManagerOverlayEntry;
  LifecycleParticipant? _userManagerLifecycleParticipant;
  OverlayEntry? _adminCopyOverlayEntry;
  LifecycleParticipant? _adminCopyLifecycleParticipant;
  OverlayEntry? _searchAndReplaceOverlayEntry;
  LifecycleParticipant? _searchAndReplaceLifecycleParticipant;
  OverlayEntry? _itemInfoOverlayEntry;
  LifecycleParticipant? _itemInfoLifecycleParticipant;
  OverlayEntry? _nutritionTypeOverlayEntry;
  LifecycleParticipant? _nutritionTypeLifecycleParticipant;
  OverlayEntry? _nutritionBoxOverlayEntry;
  LifecycleParticipant? _nutritionBoxLifecycleParticipant;
  OverlayEntry? _updateNoticeOverlayEntry;
  LifecycleParticipant? _updateNoticeLifecycleParticipant;
  OverlayEntry? _searchPrintSettingsOverlayEntry;
  LifecycleParticipant? _searchPrintSettingsLifecycleParticipant;
  OverlayEntry? _labelSettingsOverlayEntry;
  OverlayEntry? _labelColumnEditOverlayEntry;
  OverlayEntry? _printHistoryOverlayEntry;
  LifecycleParticipant? _printHistoryLifecycleParticipant;
  OverlayEntry? _contentSaveHistoryOverlayEntry;
  LifecycleParticipant? _contentSaveHistoryLifecycleParticipant;
  OverlayEntry? _commonLabelHistoryOverlayEntry;
  LifecycleParticipant? _commonLabelHistoryLifecycleParticipant;
  OverlayEntry? _statusPrintOverlayEntry;
  LifecycleParticipant? _statusPrintLifecycleParticipant;
  OverlayEntry? _loginHistoryOverlayEntry;
  LifecycleParticipant? _loginHistoryLifecycleParticipant;
  OverlayEntry? _labelPrintProgressOverlayEntry;
  OverlayEntry? _scaleOutputProgressOverlayEntry;
  // 브랜드 설정 다이얼로그에서 브랜드를 선택한 후 라벨 시트 로드가 완료될 때까지
  // 다이얼로그의 더블클릭을 차단하기 위한 플래그.
  final ValueNotifier<bool> _brandDialogBusyNotifier = ValueNotifier(false);

  bool get _isAutoLoginMode => AutoLoginGuard.instance.enabled;

  void _handleItemDraftDirtyChanged() {
    final dirty = _itemDraftController?.isDirty == true;
    _logItemDraftCancelDebug(
      'dirtyChanged observed=$dirty previous=$_lastReportedItemDraftDirty',
      traceId: _lastItemDraftCancelTraceId,
    );
    if (dirty == _lastReportedItemDraftDirty) return;
    _lastReportedItemDraftDirty = dirty;
    if (mounted) setState(() {});
  }

  LifecycleExitSnapshot _createExitSnapshot() {
    String? blockingReason;
    if (_labelPrintSessionController.busy ||
        _itemDraftCommandBusy ||
        _autoItemUpdateCommandBusy ||
        _labelColumnEditCommandBusy) {
      blockingReason = '현재 저장 또는 발행 작업이 끝난 뒤 다시 시도해주세요.';
    } else if (_scaleOutputSessionController.busy ||
        _scaleOutputSessionController.connectionState ==
            ScaleOutputConnectionState.connecting) {
      blockingReason = '저울 발행 또는 연결 작업이 끝난 뒤 다시 시도해주세요.';
    } else if (_itemManageController.hasActiveEditing ||
        _autoItemUpdatePageController.hasActiveEditing ||
        _scaleOutputPageController.hasActiveEditing) {
      blockingReason = '현재 셀 편집을 완료하거나 취소한 뒤 다시 시도해주세요.';
    }

    return LifecycleExitSnapshot(
      blockingReason: blockingReason,
      dirtyWorks: [
        if (_itemDraftController?.isDirty == true)
          LifecycleDirtyWork(name: '품목관리', discard: _discardItemDraftForExit),
        if (_autoItemUpdateDraftController?.isDirty == true ||
            _autoItemUpdateDraftController?.addModeOpen == true)
          LifecycleDirtyWork(
            name: '자동품목갱신',
            discard: _discardAutoItemUpdateDraftForExit,
          ),
        if (_commonLabelSheetDirty)
          LifecycleDirtyWork(
            name: '공용라벨관리',
            discard: _discardCommonLabelDraftForExit,
          ),
      ],
    );
  }

  Future<void> _discardItemDraftForExit() async {
    _disposeItemDraftController();
  }

  Future<void> _discardAutoItemUpdateDraftForExit() async {
    _disposeAutoItemUpdateDraftController();
  }

  Future<void> _discardCommonLabelDraftForExit() async {
    _commonLabelSheetDirty = false;
  }

  void _handleAutoItemUpdateDraftChanged() {
    if (!mounted) {
      return;
    }
    if (_selectedTabValue() == 'auto_update') {
      _showItemPreviewWindow();
    }
    setState(() {});
  }

  void _handleScaleOutputChanged() {
    if (!mounted) {
      return;
    }
    _syncAppMenuWorkState();
    setState(() {});
  }

  void _handleLabelPrintChanged() {
    if (!mounted) return;
    _syncAppMenuWorkState();
  }

  void _attachAppMenuCommands() {
    widget.appMenuController.attach(
      owner: this,
      handlers: {
        AppMenuCommandId.manageCooperators: _openCooperatorManagerDialog,
        AppMenuCommandId.manageCustomers: _openCustomerManagerDialog,
        AppMenuCommandId.manageMarkets: _openMarketManagerDialog,
        AppMenuCommandId.manageUsers: _openUserManagerDialog,
        AppMenuCommandId.copyAdmin: _openAdminCopyDialog,
        AppMenuCommandId.searchAndReplace: _openSearchAndReplaceDialog,
        AppMenuCommandId.editItemInfo: _openItemInfoDialog,
        AppMenuCommandId.addNutritionType: _openNutritionTypeDialog,
        AppMenuCommandId.addNutritionTable: _openNutritionBoxDialog,
        AppMenuCommandId.manageScale:
            widget.controller.openScaleConnectSettings,
        AppMenuCommandId.labelPrintSettings:
          widget.controller.openLabelPrintSettings,
        AppMenuCommandId.scaleOutputPrinterSettings:
          widget.controller.openScaleOutputPrinterSettings,
        AppMenuCommandId.updateNotice: _openUpdateNoticeDialog,
        AppMenuCommandId.searchPrintMode: widget.onToggleSearchPrintMode,
        AppMenuCommandId.searchPrintSettings:
          _openSearchPrintSettingsDialog,
        AppMenuCommandId.viewPrintHistory: _openPrintHistoryDialog,
        AppMenuCommandId.viewContentHistory: _openContentSaveHistoryDialog,
        AppMenuCommandId.viewCommonLabelHistory: _openCommonLabelHistoryDialog,
        AppMenuCommandId.viewPrintStatistics: _openStatusPrintDialog,
        AppMenuCommandId.viewLoginHistory: _openLoginHistoryDialog,
      },
    );
    _syncAppMenuWorkState();
  }

  void _syncAppMenuWorkState() {
    widget.appMenuController.updateWorkState(
      hasScaleOutputLabelSize: _effectiveLabelSize != null,
      workBlocked: appMenuWorkBlocked(
        itemManagerQueryDepth: _itemManagerQueryDepth,
        itemEditing: _itemManageController.hasActiveEditing,
        autoItemUpdateEditing: _autoItemUpdatePageController.hasActiveEditing,
        scaleOutputEditing: _scaleOutputPageController.hasActiveEditing,
      ),
      busyCommands: {
        if (_labelPrintSessionController.busy)
          AppMenuCommandId.labelPrintSettings,
        if (_scaleOutputSessionController.busy)
          AppMenuCommandId.scaleOutputPrinterSettings,
      },
    );
  }

  void _handlePageEditingChanged() {
    _syncAppMenuWorkState();
  }

  void _logItemDraftCancelDebug(String event, {int? traceId}) {
    final controller = _itemDraftController;
    final stateCounts = <ItemManagerDraftRowState, int>{};
    if (controller != null) {
      for (final row in controller.rows) {
        stateCounts.update(
          row.rowState,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    debugLog(
      '[$_itemDraftCancelDebugVersion] '
      'trace=${traceId ?? '-'} event=$event '
      'controller=${controller == null ? 'null' : identityHashCode(controller)} '
      'dirty=${controller?.isDirty} imported=${controller?.hasImportedRows} '
      'rows=${controller?.rows.length ?? 0} states=$stateCounts '
      'deleted=${controller?.deletedSourceItemIds.length ?? 0} '
      'busy=$_itemDraftCommandBusy '
      'mounted=$mounted selectedTab=${_selectedTabValue()}',
    );
  }

  void _disposeItemDraftController() {
    _itemDraftController?.removeListener(_handleItemDraftDirtyChanged);
    _itemDraftController?.dispose();
    _itemDraftController = null;
    _itemDraftLoadedCustomerId = null;
    _itemDraftLoadedBrandId = null;
    _itemDraftLoadedLabelSizeId = null;
    _itemDraftLoadedMarketId = null;
    _handleItemDraftDirtyChanged();
  }

  void _disposeAutoItemUpdateDraftController() {
    _autoItemUpdateDraftController?.removeListener(
      _handleAutoItemUpdateDraftChanged,
    );
    _autoItemUpdateDraftController?.dispose();
    _autoItemUpdateDraftController = null;
  }

  Future<bool> _reloadAutoItemUpdateDraftFromDatabase({
    String? selectedRowKey,
    int? fallbackIndex,
    bool rebuildTabs = true,
  }) async {
    final labelSize = _currentLabelSize;
    final market = Market.instance;
    if (labelSize == null || market == null) {
      return false;
    }
    final controller = await loadAutoItemUpdateDraft(
      labelSizeId: labelSize.labelSizeId,
      marketId: market.marketId,
      selectedRowKey: selectedRowKey,
      fallbackIndex: fallbackIndex,
    );
    _replaceAutoItemUpdateDraftController(
      controller,
      rebuildTabs: rebuildTabs,
    );
    return true;
  }

  Future<bool> _loadAutoItemUpdateDraftFromDatabase({
    bool rebuildTabs = true,
  }) async {
    final labelSize = _currentLabelSize;
    final market = Market.instance;
    if (labelSize == null || market == null) {
      return false;
    }
    final controller = await loadAutoItemUpdateDraft(
      labelSizeId: labelSize.labelSizeId,
      marketId: market.marketId,
    );
    _replaceAutoItemUpdateDraftController(
      controller,
      rebuildTabs: rebuildTabs,
    );
    return true;
  }

  void _replaceAutoItemUpdateDraftController(
    AutoItemUpdateDraftController controller, {
    required bool rebuildTabs,
  }) {
    _autoItemUpdateDraftController?.removeListener(
      _handleAutoItemUpdateDraftChanged,
    );
    _autoItemUpdateDraftController?.dispose();
    _autoItemUpdateDraftController = controller;
    _autoItemUpdateDraftController!.addListener(
      _handleAutoItemUpdateDraftChanged,
    );
    if (!mounted) {
      return;
    }
    if (rebuildTabs) {
      _resetTabs();
    }
    setState(() {});
  }

  Future<bool> _ensureAutoItemUpdateDraftLoaded() async {
    if (_autoItemUpdateDraftController != null) {
      return true;
    }
    try {
      return await _loadAutoItemUpdateDraftFromDatabase();
    } catch (error) {
      if (mounted) {
        _showItemDraftError('자동품목갱신 불러오기 실패', error);
      }
      return false;
    }
  }

  Future<bool> _flushAutoItemUpdateEdits(String errorTitle) async {
    setState(() => _autoItemUpdateCommandBusy = true);
    try {
      await _autoItemUpdatePageController.commitEditing();
      if (_autoItemUpdatePageController.hasActiveEditing) {
        if (mounted) {
          _showItemDraftError(errorTitle, '현재 편집을 완료한 뒤 다시 시도해 주세요.');
        }
        return false;
      }
      return true;
    } catch (error) {
      if (mounted) _showItemDraftError(errorTitle, error);
      return false;
    } finally {
      if (mounted) setState(() => _autoItemUpdateCommandBusy = false);
    }
  }

  Future<void> _deleteAutoItemUpdateRows(Iterable<String> rowKeys) async {
    final controller = _autoItemUpdateDraftController;
    if (controller == null ||
        _autoItemUpdateCommandBusy ||
        User.instance?.canEdit != true) {
      return;
    }
    final keys = rowKeys.toSet();
    if (keys.isEmpty) {
      return;
    }
    final rows = [
      for (final row in controller.rows)
        if (keys.contains(row.rowKey)) row,
    ];
    if (rows.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('자동품목갱신 삭제'),
        content: Text(
          rows.length == 1
              ? "선택한 '${rows.first.itemName}'를 삭제할까요?"
              : "선택한 '${rows.first.itemName}' 외 ${rows.length - 1}개 항목을 삭제할까요?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      controller.deleteRows(keys);
      _resetTabs();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) _showItemDraftError('자동품목갱신 삭제 실패', error);
    }
  }

  Future<void> _refreshAutoItemUpdateDraft() async {
    final controller = _autoItemUpdateDraftController;
    if (controller == null || _autoItemUpdateCommandBusy) {
      return;
    }
    if (!await _flushAutoItemUpdateEdits('자동품목갱신 새로 고침')) return;
    final anchorRowKey = controller.anchorRowKey;
    final fallbackIndex = anchorRowKey == null
        ? null
        : controller.rows.indexWhere((row) => row.rowKey == anchorRowKey);
    var reloaded = false;
    setState(() => _autoItemUpdateCommandBusy = true);
    try {
      reloaded = await _reloadAutoItemUpdateDraftFromDatabase(
        selectedRowKey: anchorRowKey,
        fallbackIndex: fallbackIndex,
        rebuildTabs: false,
      );
      if (!reloaded && mounted) {
        _showItemDraftError('자동품목갱신 새로 고침 실패', '자동품목갱신 목록을 다시 불러오지 못했습니다.');
      }
    } catch (error) {
      if (mounted) _showItemDraftError('자동품목갱신 새로 고침 실패', error);
    } finally {
      if (mounted) {
        setState(() => _autoItemUpdateCommandBusy = false);
        if (reloaded) {
          _resetTabs();
        }
      }
    }
  }

  Future<void> _cancelAutoItemUpdateDraft() async {
    final controller = _autoItemUpdateDraftController;
    if (controller == null ||
        !controller.isDirty ||
        _autoItemUpdateCommandBusy) {
      return;
    }
    if (!await _flushAutoItemUpdateEdits('자동품목갱신 변경 취소 확인')) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('자동품목갱신 변경 취소'),
        content: const Text('변경 내용을 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('변경 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final selectedRowKey = controller.anchorRowKey;
    final fallbackIndex = selectedRowKey == null
        ? null
        : controller.rows.indexWhere((row) => row.rowKey == selectedRowKey);
    var reloaded = false;
    setState(() => _autoItemUpdateCommandBusy = true);
    try {
      reloaded = await _reloadAutoItemUpdateDraftFromDatabase(
        selectedRowKey: selectedRowKey,
        fallbackIndex: fallbackIndex,
        rebuildTabs: false,
      );
      if (!reloaded && mounted) {
        _showItemDraftError('자동품목갱신 변경 취소 실패', '자동품목갱신 목록을 다시 불러오지 못했습니다.');
      }
    } catch (error) {
      if (mounted) _showItemDraftError('자동품목갱신 변경 취소 실패', error);
    } finally {
      if (mounted) {
        setState(() => _autoItemUpdateCommandBusy = false);
        if (reloaded) {
          _resetTabs();
        }
      }
    }
  }

  Future<void> _saveAutoItemUpdateDraft() async {
    final controller = _autoItemUpdateDraftController;
    if (controller == null ||
        User.instance?.canEdit != true ||
        !controller.isDirty ||
        _autoItemUpdateCommandBusy) {
      return;
    }
    if (!await _flushAutoItemUpdateEdits('자동품목갱신 저장 확인')) return;
    if (!mounted || !controller.isDirty) return;
    try {
      controller.validateForSave();
    } on AutoItemUpdateDraftValidationError catch (error) {
      controller.setSelection([error.rowKey], anchorRowKey: error.rowKey);
      _showItemDraftError('자동품목갱신 저장 확인', error);
      return;
    } catch (error) {
      _showItemDraftError('자동품목갱신 저장 확인', error);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('자동품목갱신 저장'),
        content: const Text('자동품목갱신 변경 사항을 저장할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var reloaded = false;
    setState(() => _autoItemUpdateCommandBusy = true);
    try {
      final execution = await executeAutoItemUpdateSave(
        controller: controller,
      );
      reloaded = await _reloadAutoItemUpdateDraftFromDatabase(
        selectedRowKey: execution.selectedRowKey,
        fallbackIndex: execution.selectedRowIndex < 0
            ? null
            : execution.selectedRowIndex,
        rebuildTabs: false,
      );
      if (!reloaded) {
        _disposeAutoItemUpdateDraftController();
        _resetTabs();
        throw StateError('DB 저장은 완료됐지만 자동품목갱신 목록을 다시 불러오지 못했습니다.');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('자동품목갱신 변경 사항을 저장했습니다.')));
      }
    } catch (error) {
      if (mounted) _showItemDraftError('자동품목갱신 저장 실패', error);
    } finally {
      if (mounted) {
        setState(() => _autoItemUpdateCommandBusy = false);
        if (reloaded) {
          _resetTabs();
        }
      }
    }
  }

  List<AutoItemUpdateSourceSeed> _autoItemUpdateSourceRows() {
    final controller = _itemDraftController;
    final currentMarketId = Market.instance?.marketId;
    final customerId = Customer.instance?.customerId;
    final labelSizeId = _currentLabelSize?.labelSizeId;
    final brandId = _currentLabelSize?.brandId;
    final sourceReady =
        controller != null &&
        currentMarketId != null &&
        customerId != null &&
        labelSizeId != null &&
        brandId != null &&
        _itemDraftLoadedCustomerId == customerId &&
        _itemDraftLoadedBrandId == brandId &&
        _itemDraftLoadedLabelSizeId == labelSizeId &&
        _itemDraftLoadedMarketId == currentMarketId;
    if (!sourceReady) {
      return const [];
    }
    final columns = TColumn.datas ?? const <TColumn>[];
    return [
      for (final row in controller.rows)
        if (row.sourceItemId != null)
          AutoItemUpdateSourceSeed(
            itemId: row.sourceItemId!,
            itemName: row.itemName,
            labelSizeId: labelSizeId,
            element: row.elementPlain,
            elementRtf: row.elementPayload,
            price: row.itemPrice,
            currentMarketId: currentMarketId,
            columnValues: {
              for (final column in columns)
                column.columnId: (
                  editable: column.editableCellNum > 0,
                  dataString: controller.columnValue(row, column.columnId),
                ),
            },
          ),
    ];
  }

  bool get _autoItemUpdateSourceReady {
    final customerId = Customer.instance?.customerId;
    final labelSize = _currentLabelSize;
    final marketId = Market.instance?.marketId;
    return _itemDraftController != null &&
        customerId != null &&
        labelSize != null &&
        marketId != null &&
        _itemDraftLoadedCustomerId == customerId &&
        _itemDraftLoadedBrandId == labelSize.brandId &&
        _itemDraftLoadedLabelSizeId == labelSize.labelSizeId &&
        _itemDraftLoadedMarketId == marketId;
  }

  LabelSize? get _effectiveLabelSize => _currentLabelSize;
  String get _labelContentKey =>
      homeLabelContentKey(_effectiveLabelSize, _labelSetupRevision);

  List<DropdownMenuItem<Brand>> _brandDropdownItems(List<Brand> brands) =>
      brands
          .map(
            (brand) => DropdownMenuItem<Brand>(
              value: brand,
              child: Text(brand.brandName, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList();

  Brand? _resolveSelectedBrand(List<Brand> brands, Brand? selectedBrand) {
    if (selectedBrand == null) return null;
    for (final brand in brands) {
      if (brand.brandId == selectedBrand.brandId) {
        return brand;
      }
    }
    return null;
  }

  List<DropdownMenuItem<LabelSize>> _labelSizeDropdownItems(
    List<LabelSize> labelSizes,
  ) => labelSizes
      .map(
        (label) => DropdownMenuItem<LabelSize>(
          value: label,
          child: Text(label.labelSizeName, overflow: TextOverflow.ellipsis),
        ),
      )
      .toList();

  LabelSize? _resolveSelectedLabelSize(
    List<LabelSize> labelSizes,
    LabelSize? selectedLabelSize,
  ) {
    if (selectedLabelSize == null) return null;
    for (final label in labelSizes) {
      if (label.labelSizeId == selectedLabelSize.labelSizeId) {
        return label;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _currentLabelSize = widget.selectedLabelSize;
    _tabController = _createTabController();
    if (widget.searchPrintModeActive) {
      _searchPrintModeLockedTabValue = _selectedTabValue();
    }
    _labelPrintSessionController.addListener(_handleLabelPrintChanged);
    _scaleOutputSessionController.addListener(_handleScaleOutputChanged);
    widget.controller.attach(
      owner: this,
      openScaleConnectSettings: _openScaleConnectSettings,
      openLabelPrintSettings: _openLabelPrintSettings,
      openScaleOutputPrinterSettings: _openScaleOutputPrinterSettings,
      appMenuOpenChanged: _handleAppMenuOpenChanged,
    );
    _attachAppMenuCommands();
    widget.onExitSnapshotProviderChanged?.call(_createExitSnapshot);
    HardwareKeyboard.instance.addHandler(_handleTabShortcutKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadBrands();
    });
  }

  @override
  void didUpdateWidget(covariant HomePageManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchPrintModeActive != widget.searchPrintModeActive) {
      _searchPrintModeLockedTabValue = widget.searchPrintModeActive
          ? _selectedTabValue()
          : null;
    }
    if (oldWidget.onExitSnapshotProviderChanged !=
        widget.onExitSnapshotProviderChanged) {
      oldWidget.onExitSnapshotProviderChanged?.call(null);
      widget.onExitSnapshotProviderChanged?.call(_createExitSnapshot);
    }
    if (!identical(oldWidget.appMenuController, widget.appMenuController)) {
      oldWidget.appMenuController.detach(this);
      _attachAppMenuCommands();
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detach(this);
      widget.controller.attach(
        owner: this,
        openScaleConnectSettings: _openScaleConnectSettings,
        openLabelPrintSettings: _openLabelPrintSettings,
        openScaleOutputPrinterSettings: _openScaleOutputPrinterSettings,
        appMenuOpenChanged: _handleAppMenuOpenChanged,
      );
      _attachAppMenuCommands();
    }
    if (oldWidget.selectedLabelSize?.labelSizeId !=
        widget.selectedLabelSize?.labelSizeId) {
      _currentLabelSize = widget.selectedLabelSize;
      _syncAppMenuWorkState();
    }
    if (oldWidget.selectedBrand?.brandId != widget.selectedBrand?.brandId) {
      if (_suppressNextBrandDidUpdateLabelLoad &&
          oldWidget.selectedBrand == null &&
          widget.selectedBrand != null) {
        _suppressNextBrandDidUpdateLabelLoad = false;
        debugLog(
          'skip label load for restored initial brandId=${widget.selectedBrand?.brandId}',
        );
        return;
      }
      if (_labelDialogBrandChangeInFlight &&
          _labelDialogBrandChangeInFlightId == widget.selectedBrand?.brandId) {
        debugLog(
          'skip duplicate label load for labelSettings brand change brandId=${widget.selectedBrand?.brandId}',
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // showProgress: true → 브랜드 변경 시 스낙바 표시
        _scheduleLabelSizeLoad(
          widget.selectedBrand,
          selectFirstLabel: true,
          showProgress: true,
        );
      });
    }
  }

  Brand? _findBrandByName(String? brandName) {
    if (brandName == null) return null;
    final brands = _brands.isNotEmpty
        ? _brands
        : Brand.datas ?? const <Brand>[];
    for (final brand in brands) {
      if (brand.brandName == brandName) {
        return brand;
      }
    }
    return null;
  }

  Brand? _findBrandById(int? brandId) {
    if (brandId == null) return null;
    final brands = _brands.isNotEmpty
        ? _brands
        : Brand.datas ?? const <Brand>[];
    for (final brand in brands) {
      if (brand.brandId == brandId) {
        return brand;
      }
    }
    return null;
  }

  Future<void> _loadBrands() async {
    void afterSnackBarVisible() async {
      try {
        debugLog(START);
        await initializeColumnTypes();
        Gs1AiDefinitions.set(await Gs1AiDAO.selectAll());
        final brands = await BrandDAO.selectByCustomerIdByBrandOrder(
          Customer.instance!.customerId,
        );
        if (!mounted) return;

        final prevBrands = Brand.datas ?? <Brand>[];
        final listEq = const ListEquality<Brand>();
        final changed =
            prevBrands.length != brands!.length ||
            !listEq.equals(prevBrands, brands);
        _brands = List<Brand>.from(brands);
        if (changed) {
          debugLog(
            'brandsChanged reload prevLen=${prevBrands.length} newLen=${brands.length}',
          );
          setState(() {});
          _brandSettingsOverlayEntry?.markNeedsBuild();
        }

        final resolved = _resolveSelectedBrand(brands, widget.selectedBrand);
        final lastConnect = User.instance == null
            ? null
            : await LastConnectDAO.selectByUserId(User.instance!.userId);
        final restored = _findBrandIn(brands, lastConnect?.brandId);
        final fallback = brands.isNotEmpty ? brands.first : null;
        final targetBrand =
            resolved ?? restored ?? fallback ?? widget.selectedBrand;

        if (resolved == null && targetBrand != null) {
          _suppressNextBrandDidUpdateLabelLoad = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onBrandChanged(targetBrand);
          });
        }

        await _scheduleLabelSizeLoad(
          targetBrand,
          preferredLabelSizeId: restored == null
              ? null
              : lastConnect?.labelSizeId,
        );
      } catch (error) {
        debugLog('$error');
        _showItemManagerLoadFailure();
      } finally {
        debugLog(END);
      }
    }

    showSnackBar(
      context,
      '브랜드 데이터를 불러오고 있습니다...',
      type: SnackBarType.inProgress,
      duration: itemManagerLoadProgressDuration,
      onVisible: afterSnackBarVisible,
    );
  }

  Brand? _findBrandIn(List<Brand> brands, int? brandId) {
    if (brandId == null) return null;
    for (final brand in brands) {
      if (brand.brandId == brandId) {
        return brand;
      }
    }
    return null;
  }

  LabelSize? _findLabelSizeIn(List<LabelSize> labelSizes, int? labelSizeId) {
    if (labelSizeId == null) return null;
    for (final labelSize in labelSizes) {
      if (labelSize.labelSizeId == labelSizeId) {
        return labelSize;
      }
    }
    return null;
  }

  void _handleBrandChanged(Brand? brand) {
    // 드롭다운에서의 브랜드 선택은 사용자의 의도적 행위이므로
    // autoLogin 가드(_isAutoLoginMode)와 무관하게 반영한다.
    // (다이얼로그 더블클릭의 _handleBrandSelectedFromDialog 와 동일한 원칙)
    debugLog(
      'handleBrandChanged brandId=${brand?.brandId} autoLogin=$_isAutoLoginMode',
    );
    if (_blockHomeDataContextChange()) return;
    widget.onBrandChanged(brand);
  }

  Future<void> _handleHeaderLabelSizeChanged(LabelSize? labelSize) async {
    if (_blockHomeDataContextChange()) {
      return;
    }
    await _handleLabelSizeChanged(labelSize, skipDraftContextGuard: true);
  }

  // 브랜드 설정 다이얼로그에서의 명시적 브랜드 선택(더블클릭)은 사용자의 의도적
  // 행위이므로 자동로그인 가드(_isAutoLoginMode)와 무관하게 반영한다.
  // 근거: .tmp/log/app_2026-07-01_17-13-52.log — 더블탭/핸들러는 정상 도달하나
  // _handleBrandChanged 의 autoLogin=true 가드에서 선택이 무시되어 무반응이었음.
  void _handleBrandSelectedFromDialog(Brand? brand) {
    if (_blockHomeDataContextChange()) return;
    _brandDialogBusyNotifier.value = true;
    widget.onBrandChanged(brand);
  }

  Future<void> _handleBrandChangedFromLabelDialog(Brand? brand) async {
    debugLog(
      'labelSettings brandChanged brandId=${brand?.brandId} name=${brand?.brandName}',
    );
    if (_blockHomeDataContextChange()) return;
    _labelDialogBrandChangeInFlight = true;
    _labelDialogBrandChangeInFlightId = brand?.brandId;
    try {
      widget.onBrandChanged(brand);
      await _scheduleLabelSizeLoad(
        brand,
        selectFirstLabel: true,
        showProgress: true,
      );
      _labelSettingsOverlayEntry?.markNeedsBuild();
    } finally {
      if (_labelDialogBrandChangeInFlightId == brand?.brandId) {
        _labelDialogBrandChangeInFlight = false;
        _labelDialogBrandChangeInFlightId = null;
      }
    }
  }

  Future<List<Brand>> _handleBrandsChangedFromDialog({
    Brand? preferredSelectedBrand,
    bool updateSelection = false,
  }) async {
    final customerId = Customer.instance?.customerId;
    if (customerId == null) {
      throw Exception('${runtimeLogTag()} 브랜드를 갱신할 고객을 찾을 수 없습니다.');
    }

    final previousSelectedBrand =
        preferredSelectedBrand ?? widget.selectedBrand;
    debugLog(
      'brandSettings reload start customerId=$customerId '
      'selectedBrandId=${previousSelectedBrand?.brandId} '
      'updateSelection=$updateSelection',
    );

    final reloadedBrands =
        await BrandDAO.selectByCustomerIdByBrandOrder(customerId) ?? <Brand>[];
    if (!mounted) {
      return reloadedBrands;
    }

    Brand.setDatas(reloadedBrands);
    _brands = List<Brand>.from(reloadedBrands);
    final resolvedSelected = _resolveSelectedBrand(
      reloadedBrands,
      previousSelectedBrand,
    );
    setState(() {});
    _brandSettingsOverlayEntry?.markNeedsBuild();
    if (updateSelection) {
      _brandDialogBusyNotifier.value = true;
      widget.onBrandChanged(resolvedSelected);
    }
    debugLog(
      'brandSettings reload completed brands=${reloadedBrands.length} '
      'selectedBrandId=${resolvedSelected?.brandId}',
    );
    return reloadedBrands;
  }

  void _handleBrandsCommittedFromDialog(List<Brand> brands) {
    Brand.setDatas(brands);
    _brands = List<Brand>.from(brands);
    if (mounted) setState(() {});
    _brandSettingsOverlayEntry?.markNeedsBuild();
  }

  Future<void> _scheduleLabelSizeLoad(
    Brand? brand, {
    bool selectFirstLabel = false,
    int? preferredLabelSizeId,
    // true 이면 로드 중 스낙바 '브랜드 데이터를 불러오고 있습니다...' 표시.
    // _loadBrands()는 이미 자체 스낙바를 관리하므로 false(기본값)를 사용한다.
    bool showProgress = false,
  }) async {
    if (_labelPrintSessionController.busy) {
      _blockItemDraftContextChange();
      return;
    }
    if (showProgress && mounted) {
      // 이전 스낵바(RTF 변환 중 등)가 큐에 남아 있으면 모두 제거한 뒤 표시한다.
      // clearSnackBars() 를 먼저 호출하지 않으면 기존 스낵바가 현재 표시 중일 때
      // 새 스낵바가 큐에 쌓이고, finally 의 hideCurrentSnackBar() 가 기존 것만
      // 닫아 '브랜드 데이터...' 가 큐에서 다시 나타나 무한 표시되는 버그가 생긴다.
      ScaffoldMessenger.of(context).clearSnackBars();
      showSnackBar(
        context,
        '브랜드 데이터를 불러오고 있습니다...',
        type: SnackBarType.inProgress,
        duration: itemManagerLoadProgressDuration,
      );
    }
    try {
      debugLog(START);

      final target =
          brand ??
          _findBrandById(widget.selectedBrand?.brandId) ??
          _findBrandByName(widget.selectedBrand?.brandName);

      if (target == null) {
        _labelSizesBrandId = null;
        LabelSize.setDatas(<LabelSize>[]);
        setState(() {});
        _labelSettingsOverlayEntry?.markNeedsBuild();
        await _handleLabelSizeChanged(null);
        return;
      }

      if (_labelSizesBrandId == target.brandId && LabelSize.datas != null) {
        final current = LabelSize.datas ?? const <LabelSize>[];

        if (current.isEmpty) {
          await _handleLabelSizeChanged(null);
        } else if (selectFirstLabel) {
          await _handleLabelSizeChanged(current.first);
        } else {
          final preferred = _findLabelSizeIn(current, preferredLabelSizeId);
          final resolved = _resolveSelectedLabelSize(
            current,
            widget.selectedLabelSize,
          );

          final fallback = current.isNotEmpty ? current.first : null;

          final selected = preferred ?? resolved ?? fallback;

          if (selected != null) {
            await _handleLabelSizeChanged(selected);
          }
        }

        return;
      }

      final token = ++_labelLoadToken;
      _labelSizesBrandId = null;
      LabelSize.setDatas(<LabelSize>[]);
      setState(() {});
      _labelSettingsOverlayEntry?.markNeedsBuild();

      final labelSizes = await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(
        target.brandId,
      );

      if (!mounted || token != _labelLoadToken) return;
      LabelSize.setDatas(labelSizes);
      _labelSizesBrandId = target.brandId;
      setState(() {});
      _labelSettingsOverlayEntry?.markNeedsBuild();

      if (labelSizes!.isEmpty) {
        await _handleLabelSizeChanged(null);
        return;
      }

      final preferred = _findLabelSizeIn(labelSizes, preferredLabelSizeId);
      final resolved = _resolveSelectedLabelSize(
        labelSizes,
        widget.selectedLabelSize,
      );

      final fallback = labelSizes.isNotEmpty ? labelSizes.first : null;
      final selected = selectFirstLabel
          ? fallback
          : preferred ?? resolved ?? fallback ?? widget.selectedLabelSize;
      await _handleLabelSizeChanged(selected);
    } catch (error) {
      debugLog('$error');
      _showItemManagerLoadFailure();
    } finally {
      debugLog(END);
      // 다이얼로그 더블클릭 차단 해제: 로드가 완료(또는 중단)될 때 항상 해제한다.
      _brandDialogBusyNotifier.value = false;
      // 스낵바 닫기는 시트가 실제로 준비된 시점(_handleCommonLabelSheetReady)에 수행한다.
      // 여기서 hideCurrentSnackBar() 를 호출하면 아직 DB 조회/_resetTabs 가 진행 중인
      // 상태에서 스낵바가 사라지거나, RTF 변환 스낵바로 전환되기 전에 닫혀버린다.
    }
  }

  Future<bool> _handleLabelSizeChanged(
    LabelSize? labelSize, {
    bool forceReload = false,
    bool skipDraftContextGuard = false,
  }) async {
    _itemManagerQueryDepth += 1;
    _syncAppMenuWorkState();
    final trace = ItemManagerDebugLog.nextTrace('sessionLoad');
    ItemManagerDebugLog.event(
      'sessionLoad',
      'started',
      trace: trace,
      fields: {
        'labelSizeId': labelSize?.labelSizeId,
        'forceReload': forceReload,
        'currentLabelSizeId': _currentLabelSize?.labelSizeId,
      },
    );
    try {
      debugLog(START);

      if (_labelPrintSessionController.busy) {
        _blockItemDraftContextChange();
        widget.onLabelSizeChanged(_currentLabelSize);
        ItemManagerDebugLog.event(
          'sessionLoad',
          'blockedByLabelPrint',
          trace: trace,
        );
        return false;
      }

      if ((forceReload ||
              labelSize?.labelSizeId != _currentLabelSize?.labelSizeId) &&
          !_commonLabelEditingLifecycleController
              .prepareForOwnerReplacement()) {
        widget.onLabelSizeChanged(_currentLabelSize);
        ItemManagerDebugLog.event(
          'sessionLoad',
          'blockedByLabelSheetRender',
          trace: trace,
        );
        return false;
      }

      if (!forceReload &&
          !skipDraftContextGuard &&
          labelSize?.labelSizeId != _currentLabelSize?.labelSizeId &&
          _blockHomeDataContextChange()) {
        widget.onLabelSizeChanged(_currentLabelSize);
        ItemManagerDebugLog.event(
          'sessionLoad',
          'blockedByDraft',
          trace: trace,
        );
        return false;
      }

      final currentLabelSizeId = _currentLabelSize?.labelSizeId;
      final selectedLabelSizeId = widget.selectedLabelSize?.labelSizeId;
      if (!forceReload &&
          labelSize?.labelSizeId == currentLabelSizeId &&
          labelSize?.labelSizeId == selectedLabelSizeId) {
        debugLog('skip unchanged labelSizeId=${labelSize?.labelSizeId}');
        ItemManagerDebugLog.event(
          'sessionLoad',
          'skippedUnchanged',
          trace: trace,
        );
        return true;
      }

      if (labelSize == null) {
        _disposeItemDraftController();
        _disposeAutoItemUpdateDraftController();
        _itemDraftTargetMarketIds = const [];
        _itemDraftEmptyElementPayload = '';
        _currentLabelSize = null;
        _rtfPreviewReadyKey = null;
        _commonLabelTabActivated = false;
        _commonLabelSheetDirty = false;
        _commonLabelPreviewClosedByUser = false;
        widget.onLabelSizeChanged(null);
        ItemOfMarket.datas = <ItemOfMarket>[];
        _publishCheckedItemIds = const <int>{};
        _scaleOutputShowAllRows = true;
        _scaleOutputRowsDirty = true;
        _selectedItemOfMarket = null;
        _selectedItemIndex = null;
        _itemPreviewClosedByUser = false;
        _resetTabs();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        ItemManagerDebugLog.event('sessionLoad', 'cleared', trace: trace);
        return true;
      }

      final customer = Customer.instance;
      final market = Market.instance;
      final session = await loadItemManagerSession(
        labelSize: labelSize,
        customer: customer,
        market: market,
        user: User.instance,
      );
      final emptyElementPayload = labelSheetEncodeWorkbookSave(
        _itemElementWorkbook('', labelSize),
      );

      _disposeItemDraftController();
      _disposeAutoItemUpdateDraftController();
      _currentLabelSize = labelSize;
      _itemDraftTargetMarketIds = session.targetMarketIds;
      _rtfPreviewReadyKey = null;
      _commonLabelTabActivated = false;
      _commonLabelSheetDirty = false;
      _itemPreviewClosedByUser = false;
      _commonLabelPreviewClosedByUser = false;
      TColumn.datas = session.columns;
      TColumnContent.datas = session.scopedColumnContents.values;
      TColumnSpecial.datas = session.specialColumns;
      ItemOfMarket.datas = session.items;
      _publishCheckedItemIds = const <int>{};
      _scaleOutputShowAllRows = true;
      _scaleOutputRowsDirty = true;
      widget.onLabelSizeChanged(labelSize);
      _itemDraftController = session.draftController;
      _itemDraftController!.addListener(_handleItemDraftDirtyChanged);
      _itemDraftLoadedCustomerId = customer!.customerId;
      _itemDraftLoadedBrandId = labelSize.brandId;
      _itemDraftLoadedLabelSizeId = labelSize.labelSizeId;
      _itemDraftLoadedMarketId = market!.marketId;
      _itemDraftEmptyElementPayload = emptyElementPayload;
      _labelPrintSessionController.applySettings(
        await loadLabelPrintSettingsSnapshot(),
      );
      _scaleOutputSessionController.applySettings(
        await ScaleOutputPrintSettingsStore.load(labelSize.labelSizeId),
      );
      _scaleOutputSessionController.updateConnectInfo(
        await DbScaleConnectInfoHelper.loadConnectInfo(),
      );
      _syncLabelPrintRows();
      _selectInitialItemOfMarket();
      debugLog(
        'loaded labelSizeId=${labelSize.labelSizeId}, '
        'columns=${TColumn.datas?.length ?? 0}, '
        'contents=${TColumnContent.datas?.length ?? 0}, '
        'specials=${TColumnSpecial.datas?.length ?? 0}, '
        'items=${ItemOfMarket.datas?.length ?? 0}',
      );
      final renderReady = await _resetTabsAndWaitForItemManager(trace);
      if (!renderReady) {
        ItemManagerDebugLog.event(
          'sessionLoad',
          'renderCancelled',
          trace: trace,
        );
        return false;
      }
      ItemManagerDebugLog.event(
        'sessionLoad',
        'completed',
        trace: trace,
        fields: {
          'labelSizeId': labelSize.labelSizeId,
          'items': session.items.length,
          'columns': session.columns.length,
          'contents': session.scopedColumnContents.values.length,
          'autoUpdates': _autoItemUpdateDraftController?.rows.length ?? 0,
          'targetMarkets': session.targetMarketIds.length,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      return true;
    } catch (e) {
      debugLog('$e');
      ItemManagerDebugLog.event(
        'sessionLoad',
        'failed',
        trace: trace,
        fields: {'error': e.runtimeType},
      );
      _showItemManagerLoadFailure();
      return false;
    } finally {
      _itemManagerQueryDepth -= 1;
      _syncAppMenuWorkState();
      debugLog(END);
    }
  }

  void _showItemManagerLoadFailure() {
    if (!mounted || _itemManagerLoadFailureDialogVisible) return;
    _itemManagerLoadFailureDialogVisible = true;
    unawaited(
      showItemManagerLoadFailureDialog(context).whenComplete(() {
        _itemManagerLoadFailureDialogVisible = false;
      }),
    );
  }

  bool _blockItemDraftContextChange() {
    if (_labelPrintSessionController.busy) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('라벨 발행이 끝난 뒤 변경해 주세요.')));
      }
      return true;
    }
    if (_itemDraftCommandBusy) {
      _logItemDraftCancelDebug(
        'contextChange blocked reason=commandBusy',
        traceId: _lastItemDraftCancelTraceId,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재 작업이 끝난 뒤 변경해 주세요.')));
      }
      return true;
    }
    if (_itemManageController.hasActiveEditing) {
      _logItemDraftCancelDebug(
        'contextChange blocked reason=activeEditing',
        traceId: _lastItemDraftCancelTraceId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('품목 편집을 완료하거나 취소한 뒤 변경해 주세요.')),
        );
      }
      return true;
    }
    if (_itemDraftController?.isDirty != true) {
      _logItemDraftCancelDebug(
        'contextChange allowed',
        traceId: _lastItemDraftCancelTraceId,
      );
      return false;
    }
    _logItemDraftCancelDebug(
      'contextChange blocked reason=dirty',
      traceId: _lastItemDraftCancelTraceId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 완료 또는 변경 취소 확정 후 변경해 주세요.')),
      );
    }
    return true;
  }

  bool _blockAutoItemUpdateContextChange() {
    if (_labelPrintSessionController.busy) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('라벨 발행이 끝난 뒤 변경해 주세요.')));
      }
      return true;
    }
    if (_autoItemUpdateCommandBusy) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재 작업이 끝난 뒤 변경해 주세요.')));
      }
      return true;
    }
    final controller = _autoItemUpdateDraftController;
    if (_autoItemUpdatePageController.hasActiveEditing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자동품목갱신 편집을 완료하거나 취소한 뒤 변경해 주세요.')),
        );
      }
      return true;
    }
    if (controller?.isDirty != true && controller?.addModeOpen != true) {
      return false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자동품목갱신 편집 내용을 저장하거나 취소한 뒤 변경해 주세요.')),
      );
    }
    return true;
  }

  bool _blockLabelPrintTabSelection() {
    final blocked = labelPrintTabSelectionBlocked(
      hasActiveEditing: _itemManageController.hasActiveEditing,
      itemDraftCommandBusy: _itemDraftCommandBusy,
      itemDraftDirty: _itemDraftController?.isDirty == true,
    );
    if (!blocked) return false;
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('품목 편집 내용을 저장하거나 취소한 뒤 라벨출력을 이용해 주세요.')),
        );
    }
    return true;
  }

  bool _blockScaleOutputTabSelection() {
    final blocked = labelPrintTabSelectionBlocked(
      hasActiveEditing: _itemManageController.hasActiveEditing,
      itemDraftCommandBusy: _itemDraftCommandBusy,
      itemDraftDirty: _itemDraftController?.isDirty == true,
    );
    if (!blocked) return false;
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('품목 편집 내용을 저장하거나 취소한 뒤 저울출력을 이용해 주세요.')),
        );
    }
    return true;
  }

  bool get _itemDraftContextChangeBlocked =>
      _labelPrintSessionController.busy ||
      _itemManageController.hasActiveEditing ||
      _itemDraftCommandBusy ||
      _itemDraftController?.isDirty == true;

  bool get _autoItemUpdateContextChangeBlocked =>
      _labelPrintSessionController.busy ||
      _autoItemUpdateCommandBusy ||
      _autoItemUpdatePageController.hasActiveEditing ||
      _autoItemUpdateDraftController?.isDirty == true ||
      _autoItemUpdateDraftController?.addModeOpen == true;

    bool get _scaleOutputContextChangeBlocked =>
      _scaleOutputSessionController.busy ||
      _scaleOutputPageController.hasActiveEditing ||
      _scaleOutputSessionController.connectionState ==
        ScaleOutputConnectionState.connecting;

  bool get _homeDataContextChangeBlocked =>
      _itemDraftContextChangeBlocked ||
      _autoItemUpdateContextChangeBlocked ||
      _scaleOutputContextChangeBlocked;

  bool get _shouldBlockCurrentTabTap => homeTabTapBlocked(
    currentTabValue: _selectedTabValue(),
    itemDraftContextChangeBlocked: _itemDraftContextChangeBlocked,
    autoItemUpdateContextChangeBlocked: _autoItemUpdateContextChangeBlocked,
  );

  void _handleBlockedTabTap() {
    final currentTabValue = _selectedTabValue();
    switch (currentTabValue) {
      case 'items':
        _blockItemDraftContextChange();
        return;
      case 'auto_update':
        _blockAutoItemUpdateContextChange();
        return;
      case 'scale_output':
        _blockScaleOutputContextChange();
        return;
      default:
        return;
    }
  }

  bool _blockHomeDataContextChange() {
    if (_itemDraftContextChangeBlocked) {
      return _blockItemDraftContextChange();
    }
    if (_autoItemUpdateContextChangeBlocked) {
      return _blockAutoItemUpdateContextChange();
    }
    if (_scaleOutputContextChangeBlocked) {
      return _blockScaleOutputContextChange();
    }
    return false;
  }

  bool _blockScaleOutputContextChange() {
    if (_scaleOutputSessionController.busy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저울 라벨 발행이 끝난 뒤 변경해 주세요.')),
        );
      }
      return true;
    }
    if (_scaleOutputSessionController.connectionState ==
        ScaleOutputConnectionState.connecting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저울 연결 처리가 끝난 뒤 변경해 주세요.')),
        );
      }
      return true;
    }
    if (_scaleOutputPageController.hasActiveEditing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저울출력 편집을 완료한 뒤 변경해 주세요.')),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _cancelItemDraft() async {
    final commonTrace = ItemManagerDebugLog.nextTrace('cancel');
    final controller = _itemDraftController;
    final traceId = ++_itemDraftCancelTraceSequence;
    _lastItemDraftCancelTraceId = traceId;
    _logItemDraftCancelDebug(
      'cancel requested eligible=${controller != null && controller.isDirty && !_itemDraftCommandBusy}',
      traceId: traceId,
    );
    ItemManagerDebugLog.event(
      'cancel',
      'requested',
      trace: commonTrace,
      fields: {
        'cancelTrace': traceId,
        'controller': controller != null,
        'dirty': controller?.isDirty,
        'busy': _itemDraftCommandBusy,
      },
    );
    if (controller == null || !controller.isDirty || _itemDraftCommandBusy) {
      ItemManagerDebugLog.event('cancel', 'blocked', trace: commonTrace);
      return;
    }
    if (!await _flushItemDraftEdits('변경 취소 확인')) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('변경 취소'),
        content: const Text('변경 내용을 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('변경 취소'),
          ),
        ],
      ),
    );
    try {
      _logItemDraftCancelDebug(
        'cancel dialog completed confirmed=$confirmed',
        traceId: traceId,
      );
      if (confirmed != true || !mounted) return;
      final selectedItemId = _selectedItemOfMarket?.item.itemId;
      final fallbackIndex = _selectedItemIndex;
      _logItemDraftCancelDebug(
        'cancel branch=reload start selectedItemId=$selectedItemId fallbackIndex=$fallbackIndex',
        traceId: traceId,
      );
      final reloaded = await _reloadItemDraftFromDatabase(
        selectedItemId: selectedItemId,
        fallbackIndex: fallbackIndex,
      );
      _logItemDraftCancelDebug(
        'cancel branch=reload completed loaded=$reloaded',
        traceId: traceId,
      );
      if (!reloaded) {
        return;
      }
    } finally {
      _logItemDraftCancelDebug(
        'cancel finished originalController=${identityHashCode(controller)} currentController=${_itemDraftController == null ? 'null' : identityHashCode(_itemDraftController!)}',
        traceId: traceId,
      );
      ItemManagerDebugLog.event(
        'cancel',
        'finished',
        trace: commonTrace,
        fields: {
          'cancelTrace': traceId,
          'currentDirty': _itemDraftController?.isDirty,
        },
      );
    }
  }

  Future<void> _saveItemDraft() async {
    final trace = ItemManagerDebugLog.nextTrace('save');
    final controller = _itemDraftController;
    final labelSize = _currentLabelSize;
    if (controller == null ||
        labelSize == null ||
        User.instance?.canEdit != true ||
        !controller.isDirty ||
        _itemDraftCommandBusy) {
      ItemManagerDebugLog.event(
        'save',
        'blocked',
        trace: trace,
        fields: {
          'controller': controller != null,
          'labelSize': labelSize?.labelSizeId,
          'canEdit': User.instance?.canEdit,
          'dirty': controller?.isDirty,
          'busy': _itemDraftCommandBusy,
        },
      );
      return;
    }
    if (!await _flushItemDraftEdits('품목 저장 확인')) return;
    if (!mounted || !controller.isDirty) return;
    ItemManagerDebugLog.event(
      'save',
      'validationStarted',
      trace: trace,
      fields: {
        'rows': controller.rows.length,
        'deleted': controller.deletedSourceItemIds.length,
      },
    );
    try {
      controller.validateForSave();
    } on ItemManagerDraftValidationError catch (error) {
      controller.setSelection(
        [error.rowKey],
        anchorRowKey: error.rowKey,
        columnId: error.columnId,
      );
      _showItemDraftError('품목 저장 확인', error);
      ItemManagerDebugLog.event(
        'save',
        'validationRejected',
        trace: trace,
        fields: {'rowKey': error.rowKey, 'columnId': error.columnId},
      );
      return;
    } catch (error) {
      _showItemDraftError('품목 저장 확인', error);
      ItemManagerDebugLog.event(
        'save',
        'validationFailed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('품목 저장'),
        content: Text(
          itemManagerSaveConfirmationMessage(
            hasDeletedItems: controller.deletedSourceItemIds.isNotEmpty,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    ItemManagerDebugLog.event(
      'save',
      'confirmCompleted',
      trace: trace,
      fields: {'confirmed': confirmed, 'mounted': mounted},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _itemDraftCommandBusy = true);
    var dbSaveCompleted = false;
    try {
      final execution = await executeItemManagerSave(
        controller: controller,
        labelSizeId: labelSize.labelSizeId,
        targetMarketIds: _itemDraftTargetMarketIds,
      );
      ItemManagerDebugLog.event(
        'save',
        'commandBuilt',
        trace: trace,
        fields: {
          'existing': execution.command.existingRows.length,
          'new': execution.command.newRows.length,
          'deleted': execution.command.deletedSourceItemIds.length,
          'columns': execution.command.columnValues.length,
          'targetMarkets': execution.command.targetMarketIds.length,
        },
      );
      dbSaveCompleted = true;
      ItemManagerDebugLog.event(
        'save',
        'transactionCompleted',
        trace: trace,
        fields: {
          'inserted': execution.result.insertedItemIdsByDraftKey.length,
        },
      );
      final reloaded = await _reloadItemDraftFromDatabase(
        selectedItemId: execution.selectedItemId,
        fallbackIndex: execution.selectedRowIndex < 0
            ? null
            : execution.selectedRowIndex,
      );
      if (!reloaded) {
        _disposeItemDraftController();
        ItemOfMarket.datas = const [];
        _selectedItemOfMarket = null;
        _selectedItemIndex = null;
        _resetTabs();
        throw StateError('DB 저장은 완료됐지만 품목 목록을 다시 불러오지 못했습니다.');
      }
      ItemManagerDebugLog.event('save', 'completed', trace: trace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('품목관리 변경 사항을 저장했습니다.')));
      }
    } catch (error) {
      ItemManagerDebugLog.event(
        'save',
        'failed',
        trace: trace,
        fields: {
          'error': error.runtimeType,
          'dbSaveCompleted': dbSaveCompleted,
        },
      );
      if (mounted) _showItemDraftError('품목 저장 실패', error);
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
      ItemManagerDebugLog.event(
        'save',
        'finished',
        trace: trace,
        fields: {'mounted': mounted},
      );
    }
  }

  Future<bool> _flushItemDraftEdits(String errorTitle) async {
    setState(() => _itemDraftCommandBusy = true);
    try {
      await _itemManageController.commitEditing();
      await _itemElementCommitQueue.wait();
      return true;
    } catch (error) {
      if (mounted) _showItemDraftError(errorTitle, error);
      return false;
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
    }
  }

  List<ItemManagerXlsxColumn> _itemManagerXlsxColumns() => [
    for (final column in TColumn.datas ?? const <TColumn>[])
      ItemManagerXlsxColumn(
        columnId: column.columnId,
        name: column.columnName,
        editable: column.editableCellNum > 0,
        typeCode: column.columnType.code,
      ),
  ];

  Future<void> _importItemManagerXlsx() async {
    final trace = ItemManagerDebugLog.nextTrace('xlsxImport');
    final controller = _itemDraftController;
    if (controller == null ||
        User.instance?.canEdit != true ||
        _itemManageController.hasActiveEditing ||
        controller.isDirty ||
        _itemDraftCommandBusy) {
      ItemManagerDebugLog.event('xlsxImport', 'blocked', trace: trace);
      return;
    }
    const xlsxGroup = XTypeGroup(
      label: 'Excel Workbook',
      extensions: ['xlsx'],
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ],
    );
    final file = await openFile(acceptedTypeGroups: const [xlsxGroup]);
    if (file == null || !mounted) {
      ItemManagerDebugLog.event('xlsxImport', 'pickerCancelled', trace: trace);
      return;
    }
    final extension = p.extension(file.path).toLowerCase();
    if (extension != '.xlsx') {
      _showItemDraftError('Excel 가져오기', '지원하지 않는 형식입니다. .xlsx 파일을 선택해 주세요.');
      ItemManagerDebugLog.event(
        'xlsxImport',
        'unsupportedExtension',
        trace: trace,
      );
      return;
    }
    setState(() => _itemDraftCommandBusy = true);
    try {
      final bytes = await file.readAsBytes();
      ItemManagerDebugLog.event(
        'xlsxImport',
        'parseStarted',
        trace: trace,
        fields: {'bytes': bytes.length},
      );
      if (!mounted) return;
      final result = itemManagerImportXlsxBytes(
        bytes,
        columns: _itemManagerXlsxColumns(),
        emptyElementPayload: _itemDraftEmptyElementPayload,
      );
      ItemManagerDebugLog.event(
        'xlsxImport',
        'parsed',
        trace: trace,
        fields: {
          'rows': result.rows.length,
          'warnings': result.warnings.length,
        },
      );
      if (result.warnings.isNotEmpty) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Excel 가져오기 확인'),
            content: Text(result.warnings.join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('계속'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) {
          ItemManagerDebugLog.event(
            'xlsxImport',
            'warningCancelled',
            trace: trace,
          );
          return;
        }
      }
      final imported = controller.replaceAllWithImportedRows(result.rows);
      final labelSize = _currentLabelSize;
      final marketId = Market.instance?.marketId;
      if (labelSize != null && marketId != null) {
        _selectedItemIndex = 0;
        _selectedItemOfMarket = imported.first.toPreviewItem(
          marketId: marketId,
          labelSizeId: labelSize.labelSizeId,
          labelSizeName: labelSize.labelSizeName,
        );
      }
      _resetTabs();
      ItemManagerDebugLog.event(
        'xlsxImport',
        'completed',
        trace: trace,
        fields: {'rows': imported.length},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imported.length}개 품목을 가져왔습니다. 저장 전 내용을 확인해 주세요.'),
          ),
        );
      }
    } catch (error) {
      ItemManagerDebugLog.event(
        'xlsxImport',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      if (mounted) _showItemDraftError('Excel 가져오기 실패', error);
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
    }
  }

  Future<void> _exportItemManagerXlsx() async {
    final trace = ItemManagerDebugLog.nextTrace('xlsxExport');
    final controller = _itemDraftController;
    if (controller == null ||
        _itemManageController.hasActiveEditing ||
        controller.isDirty ||
        _itemDraftCommandBusy) {
      return;
    }
    if (controller.rows.isEmpty) {
      _showItemDraftError('Excel 내보내기', 'Excel로 저장할 데이터가 없습니다.');
      return;
    }
    const xlsxGroup = XTypeGroup(
      label: 'Excel Workbook',
      extensions: ['xlsx'],
      mimeTypes: [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ],
    );
    final location = await getSaveLocation(
      acceptedTypeGroups: const [xlsxGroup],
      suggestedName: '${_currentLabelSize?.labelSizeName ?? '품목관리'}.xlsx',
    );
    if (location == null || !mounted) {
      ItemManagerDebugLog.event('xlsxExport', 'pickerCancelled', trace: trace);
      return;
    }
    var path = location.path;
    final extension = p.extension(path).toLowerCase();
    if (extension.isEmpty) {
      path = '$path.xlsx';
    } else if (extension != '.xlsx') {
      _showItemDraftError('Excel 내보내기', '지원하지 않는 형식입니다. .xlsx 파일로 저장해 주세요.');
      return;
    }
    setState(() => _itemDraftCommandBusy = true);
    try {
      final columns = _itemManagerXlsxColumns();
      final bytes = itemManagerExportXlsxBytes(
        rows: controller.rows,
        columns: columns,
        columnValue: (row, column) =>
            controller.columnValue(row, column.columnId),
      );
      ItemManagerDebugLog.event(
        'xlsxExport',
        'writeStarted',
        trace: trace,
        fields: {
          'rows': controller.rows.length,
          'columns': columns.length,
          'bytes': bytes.length,
        },
      );
      await File(path).writeAsBytes(bytes, flush: true);
      ItemManagerDebugLog.event('xlsxExport', 'completed', trace: trace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel 파일을 저장했습니다: ${p.basename(path)}')),
        );
      }
    } catch (error) {
      ItemManagerDebugLog.event(
        'xlsxExport',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      if (mounted) _showItemDraftError('Excel 내보내기 실패', error);
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
    }
  }

  Future<void> _showItemQrData(ItemManagerDraftRow row) async {
    final trace = ItemManagerDebugLog.nextTrace('qrViewer');
    final referenceAt = DateTime.now();
    final controller = _itemDraftController;
    if (controller == null ||
        !controller.rows.any((item) => item.rowKey == row.rowKey)) {
      return;
    }
    final columns = [
      for (final column in TColumn.datas ?? const <TColumn>[])
        ItemCodeColumnSpec.fromColumn(column),
    ];
    String columnValue(int columnId) => controller.columnValue(row, columnId);
    final results = ItemCodeDataResolver(
      itemName: row.itemName,
      columns: columns,
      columnValue: columnValue,
      tokenColumnValue: (column) => itemCodeTokenColumnValue(
        column: column,
        columns: columns,
        columnValue: columnValue,
        referenceAt: referenceAt,
      ),
      gs1Definitions: Gs1AiDefinitions.values,
    ).resolveViewerData();
    ItemManagerDebugLog.event(
      'qrViewer',
      'resolved',
      trace: trace,
      fields: {
        'rowKey': row.rowKey,
        'sourceItemId': row.sourceItemId,
        'columns': columns.length,
        'results': results.length,
        'errors': results.where((result) => result.error != null).length,
      },
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR코드 데이터 보기'),
        content: SizedBox(
          width: 560,
          child: results.isEmpty
              ? const Text('표시할 QR코드 또는 텍스트 연동 데이터가 없습니다.')
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 20),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.column.columnName,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            result.error ??
                                (result.data.isEmpty ? '데이터 없음' : result.data),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeItemOrder() async {
    final trace = ItemManagerDebugLog.nextTrace('itemOrder');
    final labelSize = _effectiveLabelSize;
    final market = Market.instance;
    final controller = _itemDraftController;
    if (labelSize == null ||
        market == null ||
        controller == null ||
        User.instance?.canEdit != true ||
        controller.isDirty ||
        _itemDraftCommandBusy) {
      ItemManagerDebugLog.event('itemOrder', 'blocked', trace: trace);
      return;
    }
    final selectedItemId = _selectedItemOfMarket?.item.itemId;
    final selectedItemIndex = _selectedItemIndex;
    setState(() => _itemDraftCommandBusy = true);
    try {
      final storedItems = await loadItemManagerOrder(
        marketId: market.marketId,
        labelSizeId: labelSize.labelSizeId,
      );
      ItemManagerDebugLog.event(
        'itemOrder',
        'loaded',
        trace: trace,
        fields: {'items': storedItems.length},
      );
      if (!mounted || storedItems.length < 2) return;
      final ordered = await showDialog<List<ItemOfMarket>>(
        context: context,
        builder: (_) =>
            ItemOrderDialog(items: storedItems, selectedItemId: selectedItemId),
      );
      if (!mounted || ordered == null) {
        ItemManagerDebugLog.event('itemOrder', 'dialogCancelled', trace: trace);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('품목 순서 저장'),
          content: const Text(
            '변경된 품목 순서를 저장할까요?\n\n'
            '순서는 품목에 저장되므로 같은 라벨의 품목을 공유하는 다른 매장 표시 순서에도 영향을 줄 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('저장'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) {
        ItemManagerDebugLog.event('itemOrder', 'saveCancelled', trace: trace);
        return;
      }
      await saveItemManagerOrder(orderedItems: ordered);
      ItemManagerDebugLog.event(
        'itemOrder',
        'updateCompleted',
        trace: trace,
        fields: {'items': ordered.length},
      );
      if (!mounted) return;
      final reloaded = await _reloadItemDraftFromDatabase(
        selectedItemId: selectedItemId,
        fallbackIndex: selectedItemIndex,
      );
      if (!reloaded) {
        throw StateError('품목 순서는 저장됐지만 목록을 다시 불러오지 못했습니다.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품목 순서를 저장했습니다.')));
    } catch (error) {
      ItemManagerDebugLog.event(
        'itemOrder',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      if (mounted) _showItemDraftError('품목 순서 변경 실패', error);
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
    }
  }

  Future<bool> _reloadItemDraftFromDatabase({
    int? selectedItemId,
    int? fallbackIndex,
  }) async {
    final trace = ItemManagerDebugLog.nextTrace('reload');
    final labelSize = _currentLabelSize;
    if (labelSize == null) {
      ItemManagerDebugLog.event('reload', 'missingLabelSize', trace: trace);
      return false;
    }
    ItemManagerDebugLog.event(
      'reload',
      'started',
      trace: trace,
      fields: {
        'labelSizeId': labelSize.labelSizeId,
        'selectedItemId': selectedItemId,
        'fallbackIndex': fallbackIndex,
      },
    );
    final loaded = await _handleLabelSizeChanged(labelSize, forceReload: true);
    if (!loaded) {
      ItemManagerDebugLog.event('reload', 'loadFailed', trace: trace);
      return false;
    }
    final items = ItemOfMarket.datas ?? const <ItemOfMarket>[];
    final index = resolveItemManagerReloadSelectionIndex(
      items,
      selectedItemId: selectedItemId,
      fallbackIndex: fallbackIndex,
    );
    if (index == null) {
      ItemManagerDebugLog.event(
        'reload',
        'completedWithoutSelection',
        trace: trace,
      );
      return true;
    }
    _selectedItemIndex = index;
    _selectedItemOfMarket = items[index];
    final restoredItemId = items[index].item.itemId;
    _itemDraftController?.setSelection([
      'item:$restoredItemId',
    ], anchorRowKey: 'item:$restoredItemId');
    _resetTabs();
    ItemManagerDebugLog.event(
      'reload',
      'completed',
      trace: trace,
      fields: {'restoredItemId': restoredItemId, 'index': index},
    );
    return true;
  }

  void _showItemDraftError(String title, Object error) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _resetTabs({bool syncPreview = true}) {
    final selectedTabValue = _selectedTabValue();
    debugLog(
      'selectedTabValue=$selectedTabValue, '
      'labelContentKey=$_labelContentKey, items=${ItemOfMarket.datas?.length ?? 0}',
    );
    _tabController = _createTabController();
    _restoreSelectedTab(selectedTabValue);
    setState(() {});
    if (syncPreview) {
      _syncPreviewWindowWithSelectedTab();
    }
    _maybeAutoSelectCommonLabel();
  }

  Future<bool> _resetTabsAndWaitForItemManager(String trace) async {
    final previous = _itemManagerReadyCompleter;
    if (previous != null && !previous.isCompleted) previous.complete();
    final generation = ++_itemManagerReadyGeneration;
    final completer = Completer<void>();
    _itemManagerReadyCompleter = completer;
    ItemManagerDebugLog.event(
      'sessionLoad',
      'renderWaiting',
      trace: trace,
      fields: {'generation': generation},
    );
    _resetTabs(syncPreview: false);
    await completer.future;
    if (!mounted || generation != _itemManagerReadyGeneration) return false;
    final finalFrame = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => finalFrame.complete());
    WidgetsBinding.instance.ensureVisualUpdate();
    await finalFrame.future;
    if (!mounted || generation != _itemManagerReadyGeneration) return false;
    ItemManagerDebugLog.event(
      'sessionLoad',
      'renderReady',
      trace: trace,
      fields: {'generation': generation},
    );
    if (identical(_itemManagerReadyCompleter, completer)) {
      _itemManagerReadyCompleter = null;
    }
    _syncPreviewWindowWithSelectedTab();
    return true;
  }

  void _handleItemManagerReady(int generation) {
    if (generation != _itemManagerReadyGeneration) return;
    final completer = _itemManagerReadyCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  Object? _selectedTabValue() {
    final selectedIndex = _tabController.selectedIndex;
    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= _tabs.length) {
      return null;
    }
    return _tabs[selectedIndex].value;
  }

  void _restoreSelectedTab(Object? selectedTabValue) {
    if (selectedTabValue == null) {
      return;
    }
    final index = _tabs.indexWhere((tab) => tab.value == selectedTabValue);
    if (index < 0) {
      return;
    }
    _tabController.selectedIndex = index;
  }

  void _syncPreviewWindowWithSelectedTab() {
    final selectedIndex = _tabController.selectedIndex;
    final selectedTab =
        selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < _tabs.length
        ? _tabs[selectedIndex]
        : null;
    if (selectedTab?.value == 'items' || selectedTab?.value == 'auto_update') {
      _showItemPreviewWindow();
    } else if (selectedTab?.value == 'common_label') {
      if (_activateCommonLabelTabIfNeeded()) {
        return;
      }
      _showRtfPreviewWindow();
    } else if (selectedTab?.value == 'scale_output') {
      _ensureScaleOutputRowsSynced();
      _hideFloatingWindows();
    } else {
      _hideFloatingWindows();
    }
  }

  TabbedViewController _createTabController() {
    _tabs = _buildTabs();
    return TabbedViewController(_tabs, onTabSelection: _onTabSelection);
  }

  void _onTabSelection(int? index, TabData? tab) {
    _logItemDraftCancelDebug(
      'tabSelection requested index=$index value=${tab?.value}',
      traceId: _lastItemDraftCancelTraceId,
    );
    final currentTabValue = _selectedTabValue();
    if (searchPrintModeBlocksTabSelection(
      active: widget.searchPrintModeActive,
      currentTab: _searchPrintModeLockedTabValue,
      requestedTab: tab?.value,
    )) {
      final revertIndex = _tabs.indexWhere(
        (candidate) => candidate.value == _searchPrintModeLockedTabValue,
      );
      if (revertIndex >= 0 && _tabController.selectedIndex != revertIndex) {
        _tabController.selectedIndex = revertIndex;
      }
      return;
    }
    final leavingItems = currentTabValue == 'items' && tab?.value != 'items';
    final leavingAutoUpdate =
        currentTabValue == 'auto_update' && tab?.value != 'auto_update';
    final leavingScaleOutput =
        currentTabValue == 'scale_output' && tab?.value != 'scale_output';
    final blocked = switch ((
      leavingItems,
      leavingAutoUpdate,
      leavingScaleOutput,
      tab?.value,
    )) {
      (true, _, _, 'label_print') => _blockLabelPrintTabSelection(),
      (true, _, _, 'scale_output') => _blockScaleOutputTabSelection(),
      (true, _, _, _) => _blockItemDraftContextChange(),
      (_, true, _, _) => _blockAutoItemUpdateContextChange(),
      (_, _, true, _) => _blockScaleOutputContextChange(),
      _ => false,
    };
    if (blocked) {
      final revertIndex = _tabs.indexWhere(
        (candidate) => candidate.value == currentTabValue,
      );
      if (revertIndex >= 0 && _tabController.selectedIndex != revertIndex) {
        _tabController.selectedIndex = revertIndex;
      }
      if (currentTabValue == 'items' || currentTabValue == 'auto_update') {
        _showItemPreviewWindow();
      } else if (currentTabValue == 'common_label') {
        _showRtfPreviewWindow();
      }
      _logItemDraftCancelDebug(
        'tabSelection reverted requested=${tab?.value} revertValue=$currentTabValue',
        traceId: _lastItemDraftCancelTraceId,
      );
      return;
    }
    if (tab?.value == 'items' || tab?.value == 'auto_update') {
      _showItemPreviewWindow();
    } else if (tab?.value == 'common_label') {
      if (_activateCommonLabelTabIfNeeded()) {
        return;
      }
      _showRtfPreviewWindow();
    } else if (tab?.value == 'scale_output') {
      _ensureScaleOutputRowsSynced();
      _hideFloatingWindows();
    } else {
      _hideFloatingWindows();
    }
    if (mounted) {
      setState(() {});
    }
    if (tab?.value == 'auto_update' && _autoItemUpdateDraftController == null) {
      unawaited(_ensureAutoItemUpdateDraftLoaded());
    }
    _logItemDraftCancelDebug(
      'tabSelection completed value=${tab?.value}',
      traceId: _lastItemDraftCancelTraceId,
    );
  }

  void _openBrandSettingsDialog() {
    debugLog(
      'brandSettings overlay open requested exists=${_brandSettingsOverlayEntry != null}',
    );
    if (_brandSettingsOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // Brand settings are modeless OverlayEntry dialogs. Confirm/warning
      // dialogs launched inside must use showBlockingModelessOverlayDialog.
      builder: (_) => BlockingModelessDialog(
        child: _BrandSettingsDialog(
          brands: _brands.isNotEmpty ? _brands : Brand.datas ?? const <Brand>[],
          selectedBrand: widget.selectedBrand,
          onBrandSelected: _handleBrandSelectedFromDialog,
          onBrandsChanged: _handleBrandsChangedFromDialog,
          onBrandsCommitted: _handleBrandsCommittedFromDialog,
          onClose: _closeBrandSettingsDialog,
          busyNotifier: _brandDialogBusyNotifier,
        ),
      ),
    );
    _brandSettingsOverlayEntry = entry;
    Overlay.of(context).insert(entry);
    debugLog('brandSettings overlay inserted mounted=${entry.mounted}');
  }

  void _openLabelSettingsDialog() {
    debugLog(
      'labelSettings overlay open requested exists=${_labelSettingsOverlayEntry != null}',
    );
    if (_labelSettingsOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // Label settings are modeless OverlayEntry dialogs. The order-apply
      // confirmation must be inserted into the root overlay, not showDialog.
      builder: (_) => BlockingModelessDialog(
        child: _LabelSettingsDialog(
          brands: _brands.isNotEmpty ? _brands : Brand.datas ?? const <Brand>[],
          selectedBrand: widget.selectedBrand,
          brandId:
              widget.selectedBrand?.brandId ??
              _effectiveLabelSize?.brandId ??
              _labelSizesBrandId,
          currentLabelSizeId: () => _effectiveLabelSize?.labelSizeId,
          labels: LabelSize.datas ?? const <LabelSize>[],
          onBrandChanged: _handleBrandChangedFromLabelDialog,
          onLabelSelected: _handleLabelSizeChanged,
          onLabelsChanged: _handleLabelsChangedFromDialog,
          onLabelsCommitted: _handleLabelsCommittedFromDialog,
          onClose: _closeLabelSettingsDialog,
        ),
      ),
    );
    _labelSettingsOverlayEntry = entry;
    Overlay.of(context).insert(entry);
    debugLog('labelSettings overlay inserted mounted=${entry.mounted}');
  }

  void _openLabelColumnEditDialog() {
    final labelSize = _effectiveLabelSize;
    final customerId = Customer.instance?.customerId;
    if (_labelColumnEditOverlayEntry != null) return;
    if (labelSize == null ||
        customerId == null ||
        User.instance?.canEdit != true ||
        _itemDraftCommandBusy ||
        _labelColumnEditCommandBusy ||
        _itemDraftController?.isDirty == true ||
        _commonLabelSheetDirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미저장 작업을 저장하거나 취소한 뒤 항목을 편집하세요.')),
      );
      return;
    }

    final targetLabelSizeId = labelSize.labelSizeId;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: LabelColumnEditDialog(
          labelSizeId: targetLabelSizeId,
          customerId: customerId,
          initialColumns: List<TColumn>.unmodifiable(
            TColumn.datas ?? const <TColumn>[],
          ),
          canSave: () async =>
              mounted &&
              User.instance?.canEdit == true &&
              _effectiveLabelSize?.labelSizeId == targetLabelSizeId &&
              !_itemDraftCommandBusy &&
              !_labelColumnEditCommandBusy &&
              _itemDraftController?.isDirty != true &&
              !_commonLabelSheetDirty,
          onSave: _saveLabelColumnsAndReload,
          onClose: _closeLabelColumnEditDialog,
        ),
      ),
    );
    _labelColumnEditOverlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  Future<void> _saveLabelColumnsAndReload(
    LabelColumnDialogSaveCommand command,
  ) async {
    final labelSize = _effectiveLabelSize;
    final customerId = Customer.instance?.customerId;
    if (labelSize == null ||
        customerId == null ||
        command.labelSizeId != labelSize.labelSizeId ||
        command.customerId != customerId ||
        User.instance?.canEdit != true ||
        _itemDraftCommandBusy ||
        _labelColumnEditCommandBusy ||
        _itemDraftController?.isDirty == true ||
        _commonLabelSheetDirty) {
      throw StateError('현재 상태에서는 라벨 항목을 저장할 수 없습니다.');
    }

    setState(() => _labelColumnEditCommandBusy = true);
    try {
      await executeLabelColumnSaveAndReload(
        command,
        reload: () => _handleLabelSizeChanged(labelSize, forceReload: true),
      );
    } finally {
      if (mounted) setState(() => _labelColumnEditCommandBusy = false);
    }
  }

  bool _handleTabShortcutKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    final key = event.logicalKey;
    final isHomeTabShortcutKey =
        key == LogicalKeyboardKey.f1 ||
        key == LogicalKeyboardKey.f2 ||
        key == LogicalKeyboardKey.f3 ||
      key == LogicalKeyboardKey.f5 ||
      key == LogicalKeyboardKey.f12;
    if (isHomeTabShortcutKey &&
      (AppShortcutBlocker.instance.isBlocked ||
        ModalRoute.of(context)?.isCurrent == false)) {
      debugLog('home shortcut blocked key=$key blockingSurface=true');
      return true;
    }
    final keyboard = HardwareKeyboard.instance;
    if (searchPrintModeShortcutPressed(
      key: key,
      modifierPressed:
        keyboard.isAltPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed,
    )) {
      widget.onToggleSearchPrintMode();
      return true;
    }
    if (widget.searchPrintModeActive &&
        (key == LogicalKeyboardKey.f1 ||
            key == LogicalKeyboardKey.f2 ||
            key == LogicalKeyboardKey.f3)) {
      return true;
    }
    if (key == LogicalKeyboardKey.f5 &&
        !keyboard.isAltPressed &&
        !keyboard.isControlPressed &&
        !keyboard.isMetaPressed &&
        !keyboard.isShiftPressed &&
        !_autoItemUpdatePageController.hasActiveEditing &&
        _selectedTabValue() == 'auto_update') {
      debugLog('home tab shortcut handled key=$key target=auto_update_refresh');
      unawaited(_refreshAutoItemUpdateDraft());
      return true;
    }
    final tabValue = homeTabShortcutValue(
      key: key,
      editing: _itemManageController.hasActiveEditing,
      modifierPressed:
          keyboard.isAltPressed ||
          keyboard.isControlPressed ||
          keyboard.isMetaPressed ||
          keyboard.isShiftPressed,
    );
    if (tabValue == null) {
      if (isHomeTabShortcutKey) {
        debugLog(
          'home tab shortcut ignored key=$key '
          'editing=${_itemManageController.hasActiveEditing} '
          'modifiers='
          '${keyboard.isAltPressed || keyboard.isControlPressed || keyboard.isMetaPressed || keyboard.isShiftPressed}',
        );
      }
      return false;
    }
    final index = _tabs.indexWhere((tab) => tab.value == tabValue);
    if (index < 0) {
      debugLog('home tab shortcut ignored key=$key reason=tabMissing target=$tabValue');
      return false;
    }
    if (_tabController.selectedIndex != index) {
      debugLog(
        'home tab shortcut handled key=$key current=${_selectedTabValue()} '
        'target=$tabValue index=$index',
      );
      _tabController.selectedIndex = index;
      _onTabSelection(index, _tabs[index]);
    } else {
      debugLog('home tab shortcut handled key=$key target=$tabValue alreadySelected=true');
    }
    return true;
  }

  void _closeLabelColumnEditDialog() {
    _labelColumnEditOverlayEntry?.remove();
    _labelColumnEditOverlayEntry = null;
  }

  void _closeLoginHistoryDialog() {
    _loginHistoryOverlayEntry?.remove();
    _loginHistoryOverlayEntry = null;
    final participant = _loginHistoryLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _loginHistoryLifecycleParticipant = null;
    }
  }

  void _closeCooperatorManagerDialog() {
    _cooperatorManagerOverlayEntry?.remove();
    _cooperatorManagerOverlayEntry = null;
    final participant = _cooperatorManagerLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _cooperatorManagerLifecycleParticipant = null;
    }
  }

  void _closeCustomerManagerDialog() {
    _customerManagerOverlayEntry?.remove();
    _customerManagerOverlayEntry = null;
    final participant = _customerManagerLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _customerManagerLifecycleParticipant = null;
    }
  }

  void _openCustomerManagerDialog() {
    if (_customerManagerOverlayEntry != null) return;
    final cooperator = Cooperator.instance;
    if (cooperator == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _customerManagerController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '거래처 관리',
            width: 820,
            height: 660,
            onClose: _closeCustomerManagerDialog,
            closeEnabled:
                !_customerManagerController.activeEditing &&
                !_customerManagerController.writeBusy,
            child: child!,
          ),
          child: CustomerManagerDialogContent(
            controller: _customerManagerController,
            onClose: _closeCustomerManagerDialog,
            initialCooperator: cooperator,
            cooperatorSelectionEnabled:
                widget.customerCooperatorSelectionEnabled,
          ),
        ),
      ),
    );
    _customerManagerOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _customerManagerController.snapshot,
      close: _closeCustomerManagerDialog,
    );
    _customerManagerLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closeMarketManagerDialog() {
    _marketManagerOverlayEntry?.remove();
    _marketManagerOverlayEntry = null;
    final participant = _marketManagerLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _marketManagerLifecycleParticipant = null;
    }
  }

  void _openMarketManagerDialog() {
    if (_marketManagerOverlayEntry != null) return;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _marketManagerController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '지점 관리',
            width: 900,
            height: 660,
            onClose: _closeMarketManagerDialog,
            closeEnabled:
                !_marketManagerController.activeEditing &&
                !_marketManagerController.writeBusy,
            child: child!,
          ),
          child: MarketManagerDialogContent(
            controller: _marketManagerController,
            onClose: _closeMarketManagerDialog,
            initialCooperator: cooperator,
            initialCustomer: customer,
            cooperatorSelectionEnabled:
                widget.marketCooperatorSelectionEnabled,
          ),
        ),
      ),
    );
    _marketManagerOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _marketManagerController.snapshot,
      close: _closeMarketManagerDialog,
    );
    _marketManagerLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closeUserManagerDialog() {
    _userManagerOverlayEntry?.remove();
    _userManagerOverlayEntry = null;
    final participant = _userManagerLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _userManagerLifecycleParticipant = null;
    }
  }

  void _openUserManagerDialog() {
    if (_userManagerOverlayEntry != null) return;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    final market = Market.instance;
    if (cooperator == null || customer == null || market == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _userManagerController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '사용자 관리',
            width: 1180,
            height: 760,
            onClose: _closeUserManagerDialog,
            closeEnabled:
                !_userManagerController.activeEditing &&
                !_userManagerController.writeBusy,
            child: child!,
          ),
          child: UserManagerDialogContent(
            controller: _userManagerController,
            onClose: _closeUserManagerDialog,
            initialCooperator: cooperator,
            initialCustomer: customer,
            initialMarket: market,
            cooperatorSelectionEnabled:
                widget.userCooperatorSelectionEnabled,
            customerSelectionEnabled: widget.userCustomerSelectionEnabled,
            marketSelectionEnabled: widget.userMarketSelectionEnabled,
            showCredentials: widget.userCredentialsVisible,
          ),
        ),
      ),
    );
    _userManagerOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _userManagerController.snapshot,
      close: _closeUserManagerDialog,
    );
    _userManagerLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closeAdminCopyDialog() {
    _adminCopyOverlayEntry?.remove();
    _adminCopyOverlayEntry = null;
    final participant = _adminCopyLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _adminCopyLifecycleParticipant = null;
    }
  }

  void _openAdminCopyDialog() {
    if (_adminCopyOverlayEntry != null) return;
    final cooperator = Cooperator.instance;
    if (cooperator == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _adminCopyController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '관리자 복사',
            width: 820,
            height: 448,
            onClose: _closeAdminCopyDialog,
            closeEnabled: !_adminCopyController.writeBusy,
            child: child!,
          ),
          child: AdminCopyDialogContent(
            controller: _adminCopyController,
            initialCooperator: cooperator,
            cooperatorSelectionEnabled:
                widget.adminCopyCooperatorSelectionEnabled,
            onCommitted: _handleAdminCopyCommitted,
            onCommitOutcomeUnknown: _closeAdminCopyDialog,
            onClose: _closeAdminCopyDialog,
          ),
        ),
      ),
    );
    _adminCopyOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _adminCopyController.snapshot,
      close: _closeAdminCopyDialog,
    );
    _adminCopyLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  Future<void> _handleAdminCopyCommitted() async {
    final currentBrandId = widget.selectedBrand?.brandId;
    final currentLabelSizeId = _currentLabelSize?.labelSizeId;
    _closeAdminCopyDialog();
    try {
      final customer = Customer.instance;
      if (customer == null) {
        throw StateError('현재 거래처 정보가 없습니다.');
      }
      final brands =
          await BrandDAO.selectByCustomerIdByBrandOrder(customer.customerId) ??
          const <Brand>[];
      Brand.setDatas(brands);
      _brands = List<Brand>.from(brands);
      final currentBrand = brands.firstWhereOrNull(
        (value) => value.brandId == currentBrandId,
      );
      widget.onBrandChanged(currentBrand);
      if (currentBrand == null) {
        final cleared = await _handleLabelSizeChanged(
          null,
          forceReload: true,
          skipDraftContextGuard: true,
        );
        if (!cleared) throw StateError('현재 라벨 정보를 다시 불러오지 못했습니다.');
        return;
      }
      final labelSizes =
          await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(
            currentBrand.brandId,
          ) ??
          const <LabelSize>[];
      LabelSize.setDatas(labelSizes);
      _labelSizesBrandId = currentBrand.brandId;
      final currentLabelSize = labelSizes.firstWhereOrNull(
        (value) => value.labelSizeId == currentLabelSizeId,
      );
      final reloaded = await _handleLabelSizeChanged(
        currentLabelSize,
        forceReload: true,
        skipDraftContextGuard: true,
      );
      if (!reloaded) {
        throw StateError('현재 라벨 정보를 다시 불러오지 못했습니다.');
      }
    } catch (error) {
      if (mounted) {
        _showItemDraftError('저장은 완료됐지만 화면 갱신에 실패했습니다.', error);
      }
    }
  }

  Future<void> _requestCloseSearchAndReplaceDialog() async {
    if (_searchAndReplaceController.writeBusy ||
        _searchAndReplaceController.activeEditing) {
      return;
    }
    if (_searchAndReplaceController.dirty) {
      final discard = await showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (context, close) => AlertDialog(
          title: const Text('검색 및 치환'),
          content: const Text('저장하지 않은 변경내용을 버리시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => close(true),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (discard != true) return;
      final snapshot = _searchAndReplaceController.snapshot();
      for (final work in snapshot.dirtyWorks) {
        await work.discard();
      }
    }
    _closeSearchAndReplaceDialog();
  }

  void _closeSearchAndReplaceDialog() {
    _searchAndReplaceOverlayEntry?.remove();
    _searchAndReplaceOverlayEntry = null;
    final participant = _searchAndReplaceLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _searchAndReplaceLifecycleParticipant = null;
    }
  }

  void _openSearchAndReplaceDialog([String initialSearchText = '']) {
    if (_searchAndReplaceOverlayEntry != null) return;
    final customerId = Customer.instance?.customerId;
    if (customerId == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _searchAndReplaceController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '검색 및 치환',
            width: 1120,
            height: 720,
            onClose: _requestCloseSearchAndReplaceDialog,
            closeEnabled:
                !_searchAndReplaceController.writeBusy &&
                !_searchAndReplaceController.activeEditing,
            child: child!,
          ),
          child: SearchAndReplaceDialogContent(
            controller: _searchAndReplaceController,
            customerId: customerId,
            editable: User.instance?.canEdit == true,
            initialSearchText: initialSearchText,
            onMoveToEdit: _moveFromSearchAndReplaceToEdit,
            onMoveToPrint: _moveFromSearchAndReplaceToPrint,
            onSaved: _reloadSearchAndReplaceCurrentContext,
            onCommitOutcomeUnknown: _closeSearchAndReplaceDialog,
          ),
        ),
      ),
    );
    _searchAndReplaceOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _searchAndReplaceController.snapshot,
      close: _closeSearchAndReplaceDialog,
    );
    _searchAndReplaceLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  Future<void> _reloadSearchAndReplaceCurrentContext() async {
    final labelSize = _effectiveLabelSize;
    if (labelSize == null) return;
    final loaded = await _handleLabelSizeChanged(labelSize, forceReload: true);
    if (!loaded) throw StateError('현재 라벨 정보를 다시 불러오지 못했습니다.');
  }

  Future<void> _loadSearchAndReplaceTarget(
    int brandId,
    int labelSizeId,
  ) async {
    final customerId = Customer.instance?.customerId;
    if (customerId == null) throw StateError('현재 거래처 정보가 없습니다.');
    final brands =
        await BrandDAO.selectByCustomerIdByBrandOrder(customerId) ??
        const <Brand>[];
    final brand = brands.firstWhereOrNull((value) => value.brandId == brandId);
    if (brand == null) throw StateError('이동할 브랜드를 찾을 수 없습니다.');
    Brand.setDatas(brands);
    _brands = List<Brand>.from(brands);
    widget.onBrandChanged(brand);

    final labelSizes =
        await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(brandId) ??
        const <LabelSize>[];
    final labelSize = labelSizes.firstWhereOrNull(
      (value) => value.labelSizeId == labelSizeId,
    );
    if (labelSize == null) throw StateError('이동할 라벨 크기를 찾을 수 없습니다.');
    LabelSize.setDatas(labelSizes);
    _labelSizesBrandId = brandId;
    final loaded = await _handleLabelSizeChanged(labelSize, forceReload: true);
    if (!loaded) throw StateError('이동할 품목 정보를 불러오지 못했습니다.');
  }

  void _selectHomeTab(Object value) {
    final index = _tabs.indexWhere((tab) => tab.value == value);
    if (index < 0 || _tabController.selectedIndex == index) return;
    _tabController.selectedIndex = index;
    _onTabSelection(index, _tabs[index]);
  }

  Future<void> _moveFromSearchAndReplaceToEdit(
    SearchReplaceEditTarget target,
  ) async {
    await _loadSearchAndReplaceTarget(target.brandId, target.labelSizeId);
    final items = ItemOfMarket.datas ?? const <ItemOfMarket>[];
    final index = items.indexWhere((value) => value.item.itemId == target.itemId);
    if (index < 0) throw StateError('이동할 품목을 찾을 수 없습니다.');
    _selectedItemIndex = index;
    _selectedItemOfMarket = items[index];
    _itemDraftController?.setSelection([
      'item:${target.itemId}',
    ], anchorRowKey: 'item:${target.itemId}');
    _searchAndReplaceController.setDirty(false);
    _closeSearchAndReplaceDialog();
    _selectHomeTab('items');
    if (mounted) setState(() {});
  }

  Future<void> _moveFromSearchAndReplaceToPrint(
    SearchReplacePrintTarget target,
  ) async {
    await _loadSearchAndReplaceTarget(target.brandId, target.labelSizeId);
    _publishCheckedItemIds = Set<int>.unmodifiable(target.itemIds);
    _syncLabelPrintRows();
    _searchAndReplaceController.setDirty(false);
    _closeSearchAndReplaceDialog();
    _selectHomeTab('label_print');
    if (mounted) setState(() {});
  }

  Future<void> _requestCloseItemInfoDialog() async {
    if (_itemInfoController.writeBusy) return;
    if (_itemInfoController.dirty) {
      final discard = await showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (context, close) => AlertDialog(
          title: const Text('품목별 정보 편집'),
          content: const Text('저장하지 않은 변경내용을 버리시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => close(true),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (discard != true) return;
      _itemInfoController.discard();
    }
    _closeItemInfoDialog();
  }

  void _closeItemInfoDialog() {
    _itemInfoOverlayEntry?.remove();
    _itemInfoOverlayEntry = null;
    final participant = _itemInfoLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _itemInfoLifecycleParticipant = null;
    }
  }

  Future<void> _requestCloseNutritionTypeDialog() async {
    if (_nutritionTypeDialogController.writeBusy ||
        _nutritionTypeDialogController.activeEditing) {
      return;
    }
    final snapshot = _nutritionTypeDialogController.snapshot();
    if (snapshot.dirtyWorks.isNotEmpty) {
      final discard = await showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (context, close) => AlertDialog(
          title: const Text('영양성분 형식추가'),
          content: const Text('저장하지 않은 변경내용을 버리시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => close(true),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (discard != true) {
        return;
      }
      for (final work in snapshot.dirtyWorks) {
        await work.discard();
      }
    }
    _closeNutritionTypeDialog();
  }

  void _closeNutritionTypeDialog() {
    _nutritionTypeOverlayEntry?.remove();
    _nutritionTypeOverlayEntry = null;
    final participant = _nutritionTypeLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _nutritionTypeLifecycleParticipant = null;
    }
  }

  void _openNutritionTypeDialog() {
    if (_nutritionTypeOverlayEntry != null) {
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _nutritionTypeDialogController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '영양성분 형식추가',
            width: 980,
            height: 720,
            onClose: _requestCloseNutritionTypeDialog,
            closeEnabled: !_nutritionTypeDialogController.writeBusy,
            child: child!,
          ),
          child: NutritionTypeDialogContent(
            controller: _nutritionTypeDialogController,
            onCommitOutcomeUnknown: _closeNutritionTypeDialog,
          ),
        ),
      ),
    );
    _nutritionTypeOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _nutritionTypeDialogController.snapshot,
      close: _closeNutritionTypeDialog,
    );
    _nutritionTypeLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  Future<void> _requestCloseNutritionBoxDialog() async {
    if (_nutritionBoxDialogController.writeBusy ||
        _nutritionBoxDialogController.activeEditing) {
      return;
    }
    final snapshot = _nutritionBoxDialogController.snapshot();
    if (snapshot.dirtyWorks.isNotEmpty) {
      final discard = await showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (context, close) => AlertDialog(
          title: const Text('영양성분표 추가'),
          content: const Text('저장하지 않은 변경내용을 버리시겠습니까?'),
          actions: [
            TextButton(onPressed: () => close(false), child: const Text('취소')),
            FilledButton(onPressed: () => close(true), child: const Text('확인')),
          ],
        ),
      );
      if (discard != true) return;
      for (final work in snapshot.dirtyWorks) {
        await work.discard();
      }
    }
    _closeNutritionBoxDialog();
  }

  void _closeNutritionBoxDialog() {
    _nutritionBoxOverlayEntry?.remove();
    _nutritionBoxOverlayEntry = null;
    final participant = _nutritionBoxLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _nutritionBoxLifecycleParticipant = null;
    }
  }

  void _openNutritionBoxDialog() {
    if (_nutritionBoxOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _nutritionBoxDialogController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '영양성분표 추가',
            width: 1100,
            height: 760,
            onClose: _requestCloseNutritionBoxDialog,
            closeEnabled: !_nutritionBoxDialogController.writeBusy,
            child: child!,
          ),
          child: NutritionBoxDialogContent(
            controller: _nutritionBoxDialogController,
            onCommitOutcomeUnknown: _closeNutritionBoxDialog,
          ),
        ),
      ),
    );
    _nutritionBoxOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _nutritionBoxDialogController.snapshot,
      close: _closeNutritionBoxDialog,
    );
    _nutritionBoxLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _openItemInfoDialog() {
    if (_itemInfoOverlayEntry != null) return;
    final hasContext =
        widget.selectedBrand != null && _effectiveLabelSize != null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _itemInfoController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '품목별 정보 편집',
            width: 1320,
            height: 720,
            onClose: _requestCloseItemInfoDialog,
            closeEnabled: !_itemInfoController.writeBusy,
            child: child!,
          ),
          child: ItemInfoDialogContent(
            controller: _itemInfoController,
            marketId: hasContext ? Market.instance?.marketId : null,
            labelSizeId: hasContext ? _effectiveLabelSize?.labelSizeId : null,
            onCommitted: _handleItemInfoCommitted,
            onCommitOutcomeUnknown: _closeItemInfoDialog,
            onClose: _requestCloseItemInfoDialog,
          ),
        ),
      ),
    );
    _itemInfoOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _itemInfoController.snapshot,
      close: _closeItemInfoDialog,
    );
    _itemInfoLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _handleItemInfoCommitted(List<ItemOfMarket> items) {
    ItemOfMarket.setDatas(List.unmodifiable(items));
    _syncLabelPrintRows();
    _scaleOutputRowsDirty = true;
    if (mounted) setState(() {});
  }

  void _openCooperatorManagerDialog() {
    if (_cooperatorManagerOverlayEntry != null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: AnimatedBuilder(
          animation: _cooperatorManagerController,
          builder: (context, child) => BlockingModelessDialogFrame(
            title: '협력업체 관리',
            width: 760,
            height: 620,
            onClose: _closeCooperatorManagerDialog,
            closeEnabled:
                !_cooperatorManagerController.activeEditing &&
                !_cooperatorManagerController.writeBusy,
            child: child!,
          ),
          child: CooperatorManagerDialogContent(
            controller: _cooperatorManagerController,
            onClose: _closeCooperatorManagerDialog,
          ),
        ),
      ),
    );
    _cooperatorManagerOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: _cooperatorManagerController.snapshot,
      close: _closeCooperatorManagerDialog,
    );
    _cooperatorManagerLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closePrintHistoryDialog() {
    _printHistoryOverlayEntry?.remove();
    _printHistoryOverlayEntry = null;
    final participant = _printHistoryLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _printHistoryLifecycleParticipant = null;
    }
  }

  void _closeContentSaveHistoryDialog() {
    _contentSaveHistoryOverlayEntry?.remove();
    _contentSaveHistoryOverlayEntry = null;
    final participant = _contentSaveHistoryLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _contentSaveHistoryLifecycleParticipant = null;
    }
  }

  void _closeCommonLabelHistoryDialog() {
    _commonLabelHistoryOverlayEntry?.remove();
    _commonLabelHistoryOverlayEntry = null;
    final participant = _commonLabelHistoryLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _commonLabelHistoryLifecycleParticipant = null;
    }
  }

  void _closeStatusPrintDialog() {
    _statusPrintOverlayEntry?.remove();
    _statusPrintOverlayEntry = null;
    final participant = _statusPrintLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _statusPrintLifecycleParticipant = null;
    }
  }

  void _openStatusPrintDialog() {
    if (_statusPrintOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (user == null || cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: BlockingModelessDialogFrame(
          title: '발행 통계 조회',
          width: 1480,
          height: 780,
          onClose: _closeStatusPrintDialog,
          child: StatusPrintDialogContent(
            userGrade: user.grade,
            initialCooperator: cooperator,
            initialCustomer: customer,
          ),
        ),
      ),
    );
    _statusPrintOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: () => const LifecycleExitSnapshot(),
      close: _closeStatusPrintDialog,
    );
    _statusPrintLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _openCommonLabelHistoryDialog() {
    if (_commonLabelHistoryOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (user == null || cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: BlockingModelessDialogFrame(
          title: '공용라벨 수정 이력 보기',
          width: 1420,
          height: 820,
          onClose: _closeCommonLabelHistoryDialog,
          child: CommonLabelHistoryDialogContent(
            userGrade: user.grade,
            initialCooperator: cooperator,
            initialCustomer: customer,
          ),
        ),
      ),
    );
    _commonLabelHistoryOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: () => const LifecycleExitSnapshot(),
      close: _closeCommonLabelHistoryDialog,
    );
    _commonLabelHistoryLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _openContentSaveHistoryDialog() {
    if (_contentSaveHistoryOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (user == null || cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: BlockingModelessDialogFrame(
          title: '데이터내용 이력 조회',
          width: 1120,
          height: 720,
          onClose: _closeContentSaveHistoryDialog,
          child: ContentSaveHistoryDialogContent(
            userGrade: user.grade,
            initialCooperator: cooperator,
            initialCustomer: customer,
          ),
        ),
      ),
    );
    _contentSaveHistoryOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: () => const LifecycleExitSnapshot(),
      close: _closeContentSaveHistoryDialog,
    );
    _contentSaveHistoryLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _openPrintHistoryDialog() {
    if (_printHistoryOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (user == null || cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: BlockingModelessDialogFrame(
          title: '발행내역 보기',
          width: 1320,
          height: 760,
          onClose: _closePrintHistoryDialog,
          child: PrintHistoryDialogContent(
            userGrade: user.grade,
            initialCooperator: cooperator,
            initialCustomer: customer,
          ),
        ),
      ),
    );
    _printHistoryOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: () => const LifecycleExitSnapshot(),
      close: _closePrintHistoryDialog,
    );
    _printHistoryLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _openLoginHistoryDialog() {
    if (_loginHistoryOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    final customer = Customer.instance;
    if (user == null || cooperator == null || customer == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => BlockingModelessDialog(
        child: BlockingModelessDialogFrame(
          title: '사용자 접속 이력 보기',
          width: 1120,
          height: 720,
          onClose: _closeLoginHistoryDialog,
          child: LoginHistoryDialogContent(
            userGrade: user.grade,
            initialCooperator: cooperator,
            initialCustomer: customer,
          ),
        ),
      ),
    );
    _loginHistoryOverlayEntry = entry;
    final participant = LifecycleParticipant(
      snapshot: () => const LifecycleExitSnapshot(),
      close: _closeLoginHistoryDialog,
    );
    _loginHistoryLifecycleParticipant = participant;
    LifecycleManager.instance.addParticipant(participant);
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  Future<void> _openDateTypeSetupDialog() async {
    final trace = ItemManagerDebugLog.nextTrace('dateSetup');
    final labelSize = _effectiveLabelSize;
    final setup = labelSize?.labelSizeSetup;
    if (labelSize == null ||
        setup == null ||
        _itemDraftCommandBusy ||
        _itemDraftController?.isDirty == true) {
      ItemManagerDebugLog.event('dateSetup', 'blocked', trace: trace);
      return;
    }
    final update = await showDialog<LabelSizeDateSetupUpdate>(
      context: context,
      builder: (_) => DateTypeSetupDialog(
        initialSetup: setup,
        showInvalidValueWarning: labelSize.hasInvalidDateSetupValues,
        readOnly: User.instance?.canEdit != true,
      ),
    );
    if (!mounted || update == null || User.instance?.canEdit != true) {
      ItemManagerDebugLog.event('dateSetup', 'dialogCancelled', trace: trace);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('날짜 타입 설정 저장'),
        content: const Text('변경한 날짜 및 시간 형식을 적용할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      ItemManagerDebugLog.event('dateSetup', 'saveCancelled', trace: trace);
      return;
    }
    setState(() => _itemDraftCommandBusy = true);
    try {
      final saved = await LabelSizeDAO.updateDateSetup(
        labelSize.labelSizeId,
        update,
      );
      ItemManagerDebugLog.event(
        'dateSetup',
        'updateCompleted',
        trace: trace,
        fields: {'labelSizeId': labelSize.labelSizeId},
      );
      if (!mounted) return;
      LabelSize.replaceCachedDateSetup(saved);
      _currentLabelSize = saved;
      widget.onLabelSizeChanged(saved);
      _labelSetupRevision++;
      _resetTabs();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('날짜 타입 설정을 저장했습니다.')));
    } catch (error) {
      ItemManagerDebugLog.event(
        'dateSetup',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      if (mounted) _showItemDraftError('날짜 타입 설정 저장 실패', error);
    } finally {
      if (mounted) setState(() => _itemDraftCommandBusy = false);
    }
  }

  Future<List<LabelSize>> _handleLabelsChangedFromDialog({
    LabelSize? preferredSelectedLabel,
    bool updateSelection = false,
  }) async {
    final brandId =
        widget.selectedBrand?.brandId ??
        _effectiveLabelSize?.brandId ??
        _labelSizesBrandId;
    final previousSelectedLabel =
        preferredSelectedLabel ??
        _effectiveLabelSize ??
        widget.selectedLabelSize;
    debugLog(
      'labelSettings reload start brandId=$brandId '
      'selectedLabelSizeId=${previousSelectedLabel?.labelSizeId} '
      'updateSelection=$updateSelection',
    );

    if (brandId == null) {
      throw Exception('${runtimeLogTag()} 라벨을 갱신할 브랜드를 찾을 수 없습니다.');
    }

    final reloadedLabels =
        await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(brandId) ??
        <LabelSize>[];
    if (!mounted) {
      return reloadedLabels;
    }

    LabelSize.setDatas(reloadedLabels);
    _labelSizesBrandId = brandId;
    final resolvedSelected = _resolveSelectedLabelSize(
      reloadedLabels,
      previousSelectedLabel,
    );
    if (updateSelection) {
      await _handleLabelSizeChanged(resolvedSelected);
    } else if (resolvedSelected != null) {
      _currentLabelSize = resolvedSelected;
    } else if (reloadedLabels.isEmpty) {
      _currentLabelSize = null;
    }
    setState(() {});
    _labelSettingsOverlayEntry?.markNeedsBuild();
    debugLog(
      'labelSettings reload completed '
      'labels=${reloadedLabels.length} selectedLabelSizeId=${resolvedSelected?.labelSizeId}',
    );
    return reloadedLabels;
  }

  void _handleLabelsCommittedFromDialog(List<LabelSize> labels) {
    LabelSize.setDatas(labels);
    final currentLabelSizeId = _currentLabelSize?.labelSizeId;
    if (currentLabelSizeId != null) {
      _currentLabelSize = _findLabelSizeIn(labels, currentLabelSizeId);
    }
    if (mounted) setState(() {});
    _labelSettingsOverlayEntry?.markNeedsBuild();
  }

  void _handleCommonLabelSaved(LabelSize saved) {
    final current = _currentLabelSize;
    if (current?.labelSizeId != saved.labelSizeId) {
      debugLog(
        'commonLabel saved ignored currentLabelSizeId=${current?.labelSizeId} '
        'savedLabelSizeId=${saved.labelSizeId}',
      );
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentLabelSize?.labelSizeId != saved.labelSizeId) {
        return;
      }
      _currentLabelSize = commonLabelSavedSessionValue(
        current: _currentLabelSize,
        saved: saved,
      );
      _commonLabelSheetDirty = false;
      _rtfPreviewReadyKey = null;
      widget.onLabelSizeChanged(saved);
      _resetTabs();
      debugLog(
        'commonLabel saved propagated labelSizeId=${saved.labelSizeId} '
        'contentKey=$_labelContentKey',
      );
    });
  }

  void _closeBrandSettingsDialog() {
    debugLog(
      'brandSettings overlay close requested exists=${_brandSettingsOverlayEntry != null}',
    );
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
    debugLog('brandSettings overlay closed');
  }

  void _closeLabelSettingsDialog() {
    debugLog(
      'labelSettings overlay close requested exists=${_labelSettingsOverlayEntry != null}',
    );
    _labelSettingsOverlayEntry?.remove();
    _labelSettingsOverlayEntry = null;
    debugLog('labelSettings overlay closed');
  }

  bool _activateCommonLabelTabIfNeeded() {
    if (_commonLabelTabActivated) {
      return false;
    }
    final selectedTabValue = _selectedTabValue() ?? 'common_label';
    _commonLabelTabActivated = true;
    _rtfPreviewReadyKey = null;
    _tabController = _createTabController();
    _restoreSelectedTab(selectedTabValue);
    setState(() {});
    return true;
  }

  void _maybeAutoSelectCommonLabel() {
    if (!_isAutoLoginMode || _autoSelectedCommonLabelOnce) return;
    _autoSelectedCommonLabelOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectCommonLabelTab();
    });
  }

  void _selectCommonLabelTab() {
    if (_tabs.length <= 1) return;
    final idx = _tabs.indexWhere((tab) => tab.value == 'common_label');
    if (idx < 0) return;
    if (_tabController.selectedIndex == idx) return;
    _tabController.selectedIndex = idx;
    _onTabSelection(idx, _tabs[idx]);
  }

  void _handlePublishCheckedItemIdsChanged(Set<int> itemIds) {
    if (const SetEquality<int>().equals(_publishCheckedItemIds, itemIds)) {
      return;
    }
    setState(() {
      _publishCheckedItemIds = Set<int>.unmodifiable(itemIds);
    });
    _syncLabelPrintRows();
    _scaleOutputRowsDirty = true;
    if (_selectedTabValue() == 'scale_output') {
      _ensureScaleOutputRowsSynced();
    }
  }

  Future<void> _handleItemManagerMinColumnCheckChanged(
    TColumnBase column,
    bool checked,
  ) async {
    final labelSizeId = _effectiveLabelSize?.labelSizeId;
    if (labelSizeId == null) {
      throw StateError('현재 라벨이 선택되지 않아 최소표시 설정을 저장할 수 없습니다.');
    }
    if (column is TColumn) {
      await TColumnDAO.updateMinColumnCheck(
        labelSizeId: labelSizeId,
        column: column,
        checked: checked,
      );
      return;
    }
    if (column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword) {
      await TColumnSpecial.updateElementMinColumnCheck(
        labelSizeId: labelSizeId,
        checked: checked,
      );
      return;
    }
    throw StateError('지원하지 않는 최소표시 컬럼입니다: ${column.keyword}');
  }

  void _syncLabelPrintRows() {
    final labelSize = _effectiveLabelSize;
    final draftController = _itemDraftController;
    final items = ItemOfMarket.datas ?? const <ItemOfMarket>[];
    if (labelSize == null || draftController == null) {
      _labelPrintSessionController.syncCheckedItems(
        baselineItems: const <ItemOfMarket>[],
        checkedItemIds: const <int>{},
        createRow: (_) => throw StateError('라벨출력 baseline이 없습니다.'),
      );
      return;
    }
    final columns = TColumn.datas ?? const <TColumn>[];
    _labelPrintSessionController.syncCheckedItems(
      baselineItems: items,
      checkedItemIds: _publishCheckedItemIds,
      createRow: (item) => LabelPrintRowDraft.fromBaseline(
        item: item,
        labelSize: labelSize,
        copies: resolveLabelPrintCopies(
          item: item,
          columns: columns,
          columnContents: draftController.scopedColumnContents,
        ),
        settings: _labelPrintSessionController.settings,
      ),
    );
  }

  void _ensureScaleOutputRowsSynced() {
    if (!_scaleOutputRowsDirty) {
      return;
    }
    _syncScaleOutputRows();
    _scaleOutputRowsDirty = false;
  }

  void _syncScaleOutputRows() {
    final labelSize = _effectiveLabelSize;
    final draftController = _itemDraftController;
    final items = ItemOfMarket.datas ?? const <ItemOfMarket>[];
    if (labelSize == null || draftController == null) {
      _scaleOutputSessionController.syncCheckedItems(
        baselineItems: const <ItemOfMarket>[],
        checkedItemIds: const <int>{},
        createRow: (_) => throw StateError('저울출력 baseline이 없습니다.'),
      );
      return;
    }
    final columns = TColumn.datas ?? const <TColumn>[];
    final weightColumnId = scaleOutputColumnIdForKeyword(columns, 'WEIGHT');
    final priceBaseColumnId = scaleOutputColumnIdForKeyword(columns, 'TPRICE');
    final visibleItemIds = scaleOutputVisibleItemIds(
      showAllRows: _scaleOutputShowAllRows,
      baselineItems: items,
      checkedItemIds: _publishCheckedItemIds,
    );
    _scaleOutputSessionController.syncCheckedItems(
      baselineItems: items,
      checkedItemIds: visibleItemIds,
      createRow: (item) => ScaleOutputRowDraft.fromBaseline(
        item: item,
        labelSize: labelSize,
        copies: resolveLabelPrintCopies(
          item: item,
          columns: columns,
          columnContents: draftController.scopedColumnContents,
        ),
        settings: _scaleOutputSessionController.settings,
        defaultWeightText: weightColumnId == null
            ? ''
            : draftController.scopedColumnContents.value(
                weightColumnId,
                item.item.itemId,
              ),
        priceBaseText: priceBaseColumnId == null
            ? ''
            : draftController.scopedColumnContents.value(
                priceBaseColumnId,
                item.item.itemId,
              ),
      ),
    );
  }

  void _reloadScaleOutputAllRows() {
    if (!_scaleOutputShowAllRows) {
      setState(() {
        _scaleOutputShowAllRows = true;
      });
    }
    _scaleOutputRowsDirty = true;
    _syncScaleOutputRows();
    _scaleOutputRowsDirty = false;
  }

  void _reloadScaleOutputSelectedRows() {
    if (_scaleOutputShowAllRows) {
      setState(() {
        _scaleOutputShowAllRows = false;
      });
    }
    _scaleOutputRowsDirty = true;
    _syncScaleOutputRows();
    _scaleOutputRowsDirty = false;
  }

  List<TabData> _buildTabs() {
    final itemManagerReadyGeneration = _itemManagerReadyGeneration;
    final commonLabelSizeId = _effectiveLabelSize?.labelSizeId;
    debugLog(
      'labelContentKey=$_labelContentKey, '
      'labelSizeId=${_effectiveLabelSize?.labelSizeId}, '
      'items=${ItemOfMarket.datas?.length ?? 0}, '
      'columns=${TColumn.datas?.length ?? 0}',
    );
    return [
      TabData(
        value: 'items',
        text: '품목관리(F1)',
        content: ItemManage(
          key: ValueKey('items:$_labelContentKey'),
          controller: _itemManageController,
          onEditingChanged: _handlePageEditingChanged,
          onReady: () => _handleItemManagerReady(itemManagerReadyGeneration),
          items: ItemOfMarket.datas ?? const <ItemOfMarket>[],
          selectedIndex: _selectedItemIndex,
          onRowSelected: _handleItemRowSelected,
          onTableRectChanged: _handleItemTableRectChanged,
          draftController: _itemDraftController,
          labelSize: _effectiveLabelSize,
          marketId: Market.instance?.marketId,
          emptyElementPayload: _itemDraftEmptyElementPayload,
          onExcelImport: User.instance?.canEdit != true
              ? null
              : _importItemManagerXlsx,
          onExcelExport: _exportItemManagerXlsx,
          onQrDataView: _showItemQrData,
          onItemOrderChange:
              _effectiveLabelSize != null &&
                  User.instance?.canEdit == true &&
                  (ItemOfMarket.datas?.length ?? 0) >= 2
              ? _changeItemOrder
              : null,
          itemOrderDisabledReason: User.instance?.canEdit != true
              ? '편집 권한이 없습니다.'
              : (ItemOfMarket.datas?.length ?? 0) < 2
              ? '순서를 바꾸려면 품목이 2개 이상 필요합니다.'
              : null,
          onCancelDraft: _cancelItemDraft,
          onSaveDraft: _saveItemDraft,
          commandBusy: _itemDraftCommandBusy,
          canEdit: User.instance?.canManageItemStructure == true,
          onPublishCheckedItemIdsChanged: _handlePublishCheckedItemIdsChanged,
          onMinColumnCheckChanged: _handleItemManagerMinColumnCheckChanged,
        ),
        closable: false,
        keepAlive: true,
      ),
      if (homeTabVisibleForUser(
        tabValue: 'common_label',
        canEdit: User.instance?.canEdit == true,
      ))
        TabData(
          value: 'common_label',
          text: '공용라벨관리(F2)',
          content: _commonLabelTabActivated
              ? CommonLabelManage(
                  key: ValueKey('common_label:$_labelContentKey'),
                  title: '공용라벨관리',
                  labelSize: _effectiveLabelSize,
                  onSheetReady: _handleCommonLabelSheetReady,
                  onGridRectChanged: _handleCommonLabelGridRectChanged,
                  onBeforeSheetDialog: _handleCommonLabelSheetDialogOpening,
                  onSheetDialogClosed: _handleCommonLabelSheetDialogClosed,
                  imageImportController: _commonLabelImageImportController,
                  editingLifecycleController:
                      _commonLabelEditingLifecycleController,
                    onLabelSaved: _handleCommonLabelSaved,
                  onSheetDirtyChanged: (dirty) {
                    final currentLabelSizeId = _effectiveLabelSize?.labelSizeId;
                    if (!commonLabelSheetDirtyChangeBelongsToCurrentSession(
                      sourceLabelSizeId: commonLabelSizeId,
                      currentLabelSizeId: currentLabelSizeId,
                    )) {
                      debugLog(
                        'commonLabel dirty ignored '
                        'sourceLabelSizeId=$commonLabelSizeId '
                        'currentLabelSizeId=$currentLabelSizeId '
                        'dirty=$dirty',
                      );
                      return;
                    }
                    debugLog(
                      'commonLabel dirty changed '
                      'labelSizeId=$commonLabelSizeId dirty=$dirty',
                    );
                    _commonLabelSheetDirty = dirty;
                  },
                  onColumnEditRequested: _openLabelColumnEditDialog,
                )
              : const SizedBox.shrink(),
          closable: false,
          keepAlive: true,
        ),
      if (Platform.isWindows)
        TabData(
          value: 'label_print',
          text: '라벨출력(F3)',
          content: LabelPrintPage(
            controller: _labelPrintSessionController,
            previewBuilder: _buildLabelPrintPreview,
            onPrinterSettings: _openLabelPrintSettings,
            onIssue: _issueLabelPrint,
            onCancelIssue: _cancelLabelPrint,
            busy: _labelPrintSessionController.busy,
          ),
          closable: false,
          keepAlive: true,
        ),
      if (homeTabVisibleForUser(
        tabValue: 'auto_update',
        canEdit: User.instance?.canEdit == true,
      ))
        TabData(
          value: 'auto_update',
          text: '자동품목갱신',
          content: AutoItemUpdatePage(
            columns: TColumn.datas ?? const <TColumn>[],
            draftController: _autoItemUpdateDraftController,
            controller: _autoItemUpdatePageController,
            onEditingChanged: _handlePageEditingChanged,
            onTableRectChanged: _handleItemTableRectChanged,
            sourceRows: _autoItemUpdateSourceRows(),
            sourceReady: _autoItemUpdateSourceReady,
            commandBusy: _autoItemUpdateCommandBusy,
            canEdit: User.instance?.canEdit == true,
            onDeleteRows: _deleteAutoItemUpdateRows,
            onRefresh: _refreshAutoItemUpdateDraft,
            onCancelDraft: _cancelAutoItemUpdateDraft,
            onSaveDraft: _saveAutoItemUpdateDraft,
          ),
          closable: false,
          keepAlive: true,
        ),
      TabData(
        value: 'scale_output',
        text: '저울출력',
        content: ScaleOutputPage(
          controller: _scaleOutputSessionController,
          pageController: _scaleOutputPageController,
          onEditingChanged: _handlePageEditingChanged,
          previewBuilder: _buildScaleOutputPreview,
          onPrinterSettings: _openScaleOutputPrinterSettings,
          onScaleSettings: _openScaleConnectSettings,
          onReloadAll: _reloadScaleOutputAllRows,
          onReloadSelected: _reloadScaleOutputSelectedRows,
          onIssue: _issueScaleOutput,
          onCancelIssue: _cancelScaleOutput,
          onConnect: _connectScaleOutput,
          onDisconnect: _disconnectScaleOutput,
          useScale: _effectiveLabelSize?.labelSizeSetup?.useScale ?? false,
          busy: _scaleOutputSessionController.busy,
        ),
        closable: false,
        keepAlive: true,
      ),
    ];
  }

  TabbedViewThemeData _buildTabbedTheme() {
    final theme = TabbedViewThemeData.minimalist(
      brightness: Brightness.light,
      colorSet: Colors.grey,
      fontSize: 14,
      tabRadius: 3,
    );

    theme.tabsArea
      ..color = const Color(0xFFF7F8FA)
      ..border = const BorderSide(color: Color(0xFFE6E6E6))
      ..initialGap = 0
      ..middleGap = 4
      ..buttonsGap = 0
      ..buttonColor = Colors.transparent
      ..hoveredButtonColor = Colors.transparent
      ..disabledButtonColor = Colors.transparent;

    theme.tab
      ..padding = const EdgeInsets.fromLTRB(18, 9.5, 18, 9.5)
      ..paddingWithoutButton = const EdgeInsets.fromLTRB(18, 9.5, 18, 9.5)
      ..textStyle = const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1F2429),
      )
      ..buttonsGap = 0
      ..buttonColor = Colors.transparent
      ..hoveredButtonColor = Colors.transparent
      ..disabledButtonColor = Colors.transparent
      ..buttonPadding = EdgeInsets.zero;

    theme.contentArea
      ..color = Colors.white
      ..padding = EdgeInsets.zero;

    theme.divider = const BorderSide(color: Color(0xFFE6E6E6));
    theme.isDividerWithinTabArea = true;

    return theme;
  }

  void _showItemPreviewWindow() {
    _commonLabelPreviewWindow?.hide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedTabValue = _selectedTabValue();
      if (selectedTabValue != 'items' && selectedTabValue != 'auto_update') {
        return;
      }
      _commonLabelPreviewWindow?.hide();
      ItemOfMarket? selected;
      String? rowIdentity;
      DateTime? referenceAt;
      Map<int, String>? projectedColumnValues;
      late Future<void> Function(String, String, String) onElementCommitted;
      late bool Function() canSelectOutputPreview;
      late bool canEdit;
      if (selectedTabValue == 'auto_update') {
        final row = _selectedAutoItemUpdateRow();
        if (row != null) {
          selected = _autoItemUpdatePreviewItem(row, _effectiveLabelSize);
          rowIdentity = row.rowKey;
          referenceAt = row.applyDate;
          projectedColumnValues = _autoItemUpdateProjectedColumnValues(row);
        }
        onElementCommitted = _commitAutoItemUpdateElementDraft;
        canSelectOutputPreview = () => true;
        canEdit = User.instance?.canEdit == true && !_autoItemUpdateCommandBusy;
      } else {
        selected = _selectedItemOfMarket;
        if (selected != null) {
          rowIdentity =
              _itemDraftController?.anchorRowKey ??
              'item:${selected.item.itemId}';
          referenceAt = DateTime.now();
          projectedColumnValues = _baselineOutputProjectedColumnValues(
            itemId: selected.item.itemId,
            referenceAt: referenceAt,
          );
        }
        onElementCommitted = _commitItemElementDraft;
        canSelectOutputPreview = () => !_blockItemDraftContextChange();
        canEdit =
            User.instance?.canEditItemDetails == true && !_itemDraftCommandBusy;
      }
      if (selected == null) {
        _itemPreviewWindow?.hide();
        return;
      }
      if (_itemPreviewClosedByUser) {
        _itemPreviewWindow?.hide();
        setState(() {});
        return;
      }
      final child = _ItemPreviewPanel(
        key: const ValueKey('item-preview'),
        item: selected,
        rowIdentity: rowIdentity ?? 'item:${selected.item.itemId}',
        labelSize: _effectiveLabelSize,
        referenceAt: referenceAt,
        projectedColumnValues: projectedColumnValues,
        elementPreviewZoomController: _itemElementPreviewZoomController,
        outputPreviewZoomController: _itemOutputPreviewZoomController,
        onElementCommitted: onElementCommitted,
        canSelectOutputPreview: canSelectOutputPreview,
        canEdit: canEdit,
      );
      if (_itemPreviewWindow == null) {
        _itemPreviewAlignedToTable = false;
        _itemPreviewWindow = PreviewFloatingWindow(
          initialSize: const Size(670, 470),
          minSize: const Size(420, 280),
          onCloseRequested: _handleItemPreviewCloseRequested,
          usePortalHost: true,
        );
      }
      _itemPreviewWindow!
        ..setTooltip(null)
        ..setChild(child)
        ..show(context);
      _alignItemPreviewWindowToTableIfNeeded();
      setState(() {});
    });
  }

  void _handleItemTableRectChanged(Rect rect) {
    _itemTableRect = rect;
    _alignItemPreviewWindowToTableIfNeeded();
  }

  void _alignItemPreviewWindowToTableIfNeeded() {
    final window = _itemPreviewWindow;
    final tableRect = _itemTableRect;
    if (!mounted ||
        _itemPreviewAlignedToTable ||
        window == null ||
        !window.isVisible ||
        tableRect == null) {
      return;
    }
    final scrollbarThickness =
        ScrollbarTheme.of(context).thickness?.resolve(const <WidgetState>{}) ??
        _itemPreviewScrollbarThicknessFallback;
    window.alignBottomRightTo(
      context,
      tableRect.bottomRight -
          Offset(
            scrollbarThickness + _itemPreviewTableInset,
            scrollbarThickness + _itemPreviewTableInset,
          ),
    );
    _itemPreviewAlignedToTable = true;
  }

  void _selectInitialItemOfMarket() {
    final items = ItemOfMarket.datas ?? const <ItemOfMarket>[];
    if (items.isEmpty) {
      _selectedItemOfMarket = null;
      _selectedItemIndex = null;
      return;
    }
    _selectedItemIndex = 0;
    _selectedItemOfMarket = items.first;
    _itemDraftController?.setSelection([
      'item:${items.first.item.itemId}',
    ], anchorRowKey: 'item:${items.first.item.itemId}');
  }

  void _handleItemRowSelected(ItemOfMarket row, int index) {
    _selectedItemOfMarket = row;
    _selectedItemIndex = index;
    if (mounted) {
      setState(() {});
    }
    if (_selectedTabValue() == 'items') {
      _showItemPreviewWindow();
    }
  }

  Future<void> _commitItemElementDraft(
    String rowKey,
    String elementPlain,
    String elementPayload,
  ) async {
    if (User.instance?.canEdit != true || _itemDraftCommandBusy) {
      throw StateError('품목 편집 권한이 없습니다.');
    }
    await _itemElementCommitQueue.enqueue(
      () => _applyItemElementDraft(rowKey, elementPlain, elementPayload),
    );
  }

  Future<void> _applyItemElementDraft(
    String rowKey,
    String elementPlain,
    String elementPayload,
  ) async {
    final controller = _itemDraftController;
    if (controller == null) {
      throw StateError('품목 draft가 없습니다.');
    }
    controller.updateElement(
      rowKey,
      elementPlain: elementPlain,
      elementPayload: elementPayload,
    );
    final draft = controller.rows.firstWhere((row) => row.rowKey == rowKey);
    final labelSize = _currentLabelSize;
    final marketId = Market.instance?.marketId;
    if (labelSize != null && marketId != null) {
      _selectedItemOfMarket = draft.toPreviewItem(
        marketId: marketId,
        labelSizeId: labelSize.labelSizeId,
        labelSizeName: labelSize.labelSizeName,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleItemPreviewCloseRequested() async {
    final window = _itemPreviewWindow;
    if (window == null || !window.isVisible) return;
    final target = _itemPreviewButtonRect() ?? window.rect.center & Size.zero;
    await window.hideToRect(target.inflate(1));
    if (!mounted) return;
    _itemPreviewClosedByUser = true;
    setState(() {});
  }

  Rect? _itemPreviewButtonRect() {
    final context = _itemPreviewButtonKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  void _restoreItemPreviewWindow() {
    if (!_itemPreviewSupportedTab(_selectedTabValue())) return;
    _itemPreviewClosedByUser = false;
    setState(() {});
    _showItemPreviewWindow();
  }

  void _showRtfPreviewWindow() {
    _itemPreviewWindow?.hide();
    if (!_commonLabelTabActivated) {
      _commonLabelPreviewWindow?.hide();
      return;
    }
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    if (!Platform.isWindows || !labelSheetLooksLikeRichEditRtf(rtf)) {
      _commonLabelPreviewWindow?.hide();
      return;
    }
    final readyKey = _rtfPreviewKey(_effectiveLabelSize, rtf!);
    if (_rtfPreviewReadyKey != readyKey) {
      _commonLabelPreviewWindow?.hide();
      return;
    }
    if (_rtfPreviewTargetKey != readyKey) {
      _rtfPreviewResizeDebounce?.cancel();
      _rtfPreviewResizeFinalizeTimer?.cancel();
      _rtfPreviewTargetKey = readyKey;
      _rtfPreviewTargetContentSize = null;
      _rtfPreviewRefreshedTargetContentSize = null;
      _rtfPreviewLastResolvedImageSize = null;
      _rtfPreviewLastNativeImage = null;
      _rtfPreviewLastNativeImageKey = null;
      _rtfPreviewHasResolvedImage = false;
      _rtfPreviewWindowKey = null;
      _commonLabelPreviewMovedByUser = false;
      _commonLabelPreviewWindow?.dispose();
      _commonLabelPreviewWindow = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentRtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
      if (_selectedTabValue() != 'common_label' ||
          !Platform.isWindows ||
          !labelSheetLooksLikeRichEditRtf(currentRtf) ||
          _rtfPreviewReadyKey !=
              _rtfPreviewKey(_effectiveLabelSize, currentRtf!)) {
        _commonLabelPreviewWindow?.hide();
        return;
      }
      _itemPreviewWindow?.hide();
      if (_commonLabelPreviewClosedByUser) {
        _commonLabelPreviewWindow?.hide();
        setState(() {});
        return;
      }
      final shouldRebuildPreview = _rtfPreviewWindowKey != readyKey;
      final preview = shouldRebuildPreview
          ? _buildRtfPreview(currentRtf)
          : null;
      _commonLabelPreviewWindow ??= PreviewFloatingWindow(
        initialSize: Size(
          LabelSheetRtfPreview.pixelsForMm(
                _effectiveLabelSize?.labelSizeCommon?.width ?? 100,
              ) +
              8,
          LabelSheetRtfPreview.pixelsForMm(
                _effectiveLabelSize?.labelSizeCommon?.height ?? 100,
              ) +
              8,
        ),
        tooltip: 'RTF 미리보기: 저장 포맷이 RTF이면 보이고 수정 후 저장하면 보이지 않음',
        onRectChanged: _handleRtfPreviewWindowRectChanged,
        onMoved: _handleCommonLabelPreviewMoved,
        onResizeCompleted: _handleRtfPreviewWindowResizeCompleted,
        onCloseRequested: _handleCommonLabelPreviewCloseRequested,
        headerAction: RtfPreviewAiConvertButton(
          onPressed: () => unawaited(_handleRtfPreviewAiConvert()),
        ),
        usePortalHost: true,
      );
      if (shouldRebuildPreview) {
        _rtfPreviewWindowKey = readyKey;
        _commonLabelPreviewWindow!
          ..setTooltip('RTF 미리보기: 저장 포맷이 RTF이면 보이고 수정 후 저장하면 보이지 않음')
          ..setChild(preview);
      }
      _commonLabelPreviewWindow!.show(context, child: preview);
      setState(() {});
      _alignCommonLabelPreviewWindowToGrid();
    });
  }

  Future<void> _handleCommonLabelPreviewCloseRequested() async {
    final window = _commonLabelPreviewWindow;
    if (window == null || !window.isVisible) return;
    final target =
        _commonLabelPreviewButtonRect() ?? window.rect.center & Size.zero;
    await window.hideToRect(target.inflate(1));
    if (!mounted) return;
    _commonLabelPreviewClosedByUser = true;
    setState(() {});
  }

  Rect? _commonLabelPreviewButtonRect() {
    final context = _commonLabelPreviewButtonKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  void _restoreCommonLabelPreviewWindow() {
    if (_selectedTabValue() != 'common_label') return;
    _commonLabelPreviewClosedByUser = false;
    setState(() {});
    _showRtfPreviewWindow();
  }

  Future<void> _handleRtfPreviewAiConvert() async {
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    if (!mounted || !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    final rtfText = rtf!;
    final labelCommon = _effectiveLabelSize?.labelSizeCommon;
    final widthMm = labelCommon?.width ?? 100;
    final heightMm = labelCommon?.height ?? 100;
    final previewKey = _rtfPreviewKey(_effectiveLabelSize, rtfText);
    var capture = _rtfPreviewLastNativeImageKey == previewKey
        ? _rtfPreviewLastNativeImage
        : null;
    capture ??= await LabelSheetRtfPreview.captureNativeOriginal(
      rtfText,
      widthMm: widthMm,
      heightMm: heightMm,
    );
    if (!mounted) {
      return;
    }
    if (capture == null || capture.bytes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('RTF 미리보기 이미지를 만들 수 없습니다.')));
      return;
    }
    final directory = await labelSheetAiImportTempDirectory().create(
      recursive: true,
    );
    final fileName =
        'label_manager_rtf_ai_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(capture.bytes, flush: true);
    if (!mounted) {
      return;
    }
    await _commonLabelImageImportController.openWithImageFile(
      bytes: capture.bytes,
      fileName: fileName,
      filePath: file.path,
      mimeType: 'image/png',
    );
  }

  Future<void> _handleCommonLabelSheetDialogOpening() async {
    if (_selectedTabValue() != 'common_label') return;
    final window = _commonLabelPreviewWindow;
    if (window == null || !window.isVisible) return;

    _commonLabelPreviewHiddenForSheetDialog = true;
    _commonLabelPreviewClosedByUser = true;
    window.hide();
    setState(() {});
    await WidgetsBinding.instance.endOfFrame;
  }

  void _handleCommonLabelSheetDialogClosed() {
    if (!_commonLabelPreviewHiddenForSheetDialog) return;
    _commonLabelPreviewHiddenForSheetDialog = false;
    _commonLabelPreviewClosedByUser = false;
    if (!mounted) return;
    setState(() {});
    if (_selectedTabValue() == 'common_label') {
      _showRtfPreviewWindow();
    }
  }

  Widget _buildRtfPreview(String rtf) {
    final targetSize = _rtfPreviewTargetContentSize;
    final targetWidth = targetSize?.width.round();
    final targetHeight = targetSize?.height.round();
    return SizedBox.expand(
      key: _rtfPreviewBoxKey,
      child: LabelSheetRtfPreview(
        key: ValueKey(
          'rtf-preview:${_effectiveLabelSize?.labelSizeId}:${rtf.hashCode}',
        ),
        rtf: rtf,
        width: targetWidth,
        height: targetHeight,
        captureGeneration: _rtfPreviewCaptureGeneration,
        widthMm: _effectiveLabelSize?.labelSizeCommon?.width ?? 100,
        heightMm: _effectiveLabelSize?.labelSizeCommon?.height ?? 100,
        onNativeImageResolved: (nativeImage) {
          _rtfPreviewLastNativeImage = nativeImage;
          _rtfPreviewLastNativeImageKey = _rtfPreviewKey(
            _effectiveLabelSize,
            rtf,
          );
        },
        onImageSizeResolved: (imageSize) {
          _rtfPreviewHasResolvedImage = true;
          _rtfPreviewLastResolvedImageSize = imageSize;
          labelSheetRtfPreviewDebugLog(
            'rtf preview image resolved '
            'image=${imageSize.width.round()}x${imageSize.height.round()} '
            'target=${_rtfPreviewTargetContentSize == null ? 'auto' : '${_rtfPreviewTargetContentSize!.width.round()}x${_rtfPreviewTargetContentSize!.height.round()}'}',
          );
          final window = _commonLabelPreviewWindow;
          if (!mounted ||
              window == null ||
              _rtfPreviewTargetContentSize != null) {
            return;
          }
          const padding = LabelSheetRtfPreview.defaultPadding;
          window.setSize(
            context,
            Size(
              imageSize.width * _rtfPreviewInitialReadableScale +
                  padding.horizontal,
              imageSize.height * _rtfPreviewInitialReadableScale +
                  padding.vertical,
            ),
          );
          _alignCommonLabelPreviewWindowToGrid();
        },
      ),
    );
  }

  void _handleCommonLabelGridRectChanged(Rect rect) {
    _commonLabelGridRect = rect;
    if (_selectedTabValue() == 'common_label' &&
        !_commonLabelPreviewMovedByUser) {
      _alignCommonLabelPreviewWindowToGrid();
    }
  }

  void _alignCommonLabelPreviewWindowToGrid() {
    final window = _commonLabelPreviewWindow;
    final gridRect = _commonLabelGridRect;
    if (!mounted ||
        _commonLabelPreviewMovedByUser ||
        window == null ||
        !window.isVisible ||
        gridRect == null) {
      return;
    }
    window.alignBottomRightTo(context, gridRect.bottomRight);
  }

  void _handleCommonLabelPreviewMoved(Rect rect) {
    if (_commonLabelPreviewMovedByUser) return;
    _commonLabelPreviewMovedByUser = true;
    debugLog('common label preview moved by user rect=$rect');
  }

  void _handleRtfPreviewWindowRectChanged(
    Rect rect, {
    required bool isResizing,
  }) {
    if (!isResizing) {
      return;
    }
    _updateRtfPreviewTargetFromRect(rect, isResizing: isResizing);
  }

  void _handleRtfPreviewWindowResizeCompleted(Rect rect) {
    final target = _rtfPreviewContentSizeForRect(rect);
    final refreshedTarget = _rtfPreviewRefreshedTargetContentSize;
    final alreadyRefreshed = _isSameRoundedSize(refreshedTarget, target);
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeDebounce = null;
    _rtfPreviewTargetContentSize = target;
    labelSheetRtfPreviewDebugLog(
      'rtf preview resize completed '
      'target=${target.width.round()}x${target.height.round()} '
      'refreshed=${refreshedTarget == null ? 'none' : '${refreshedTarget.width.round()}x${refreshedTarget.height.round()}'} '
      'imageResolved=$_rtfPreviewHasResolvedImage '
      'image=${_rtfPreviewLastResolvedImageSize == null ? 'none' : '${_rtfPreviewLastResolvedImageSize!.width.round()}x${_rtfPreviewLastResolvedImageSize!.height.round()}'} '
      'force=${!alreadyRefreshed}',
    );
    _scheduleRtfPreviewResizeFinalRecapture(rect);
  }

  Size _rtfPreviewContentSizeForRect(Rect rect) {
    const padding = LabelSheetRtfPreview.defaultPadding;
    return Size(
      (rect.width - padding.horizontal).clamp(1.0, double.infinity),
      (rect.height - padding.vertical).clamp(1.0, double.infinity),
    );
  }

  bool _isSameRoundedSize(Size? left, Size right) {
    return left != null &&
        left.width.round() == right.width.round() &&
        left.height.round() == right.height.round();
  }

  void _updateRtfPreviewTargetFromRect(
    Rect rect, {
    required bool isResizing,
    bool force = false,
    String reason = 'rect',
  }) {
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    if (!mounted ||
        !Platform.isWindows ||
        !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    final next = _rtfPreviewContentSizeForRect(rect);
    final current = _rtfPreviewTargetContentSize;
    if (!force && _isSameRoundedSize(current, next)) {
      return;
    }
    _rtfPreviewTargetContentSize = next;
    labelSheetRtfPreviewDebugLog(
      'rtf preview target logical='
      '${next.width.round()}x${next.height.round()} resizing=$isResizing '
      'force=$force reason=$reason rect=${rect.width.toStringAsFixed(1)}x${rect.height.toStringAsFixed(1)}',
    );
    if (isResizing) {
      _rtfPreviewResizeDebounce?.cancel();
      _rtfPreviewResizeDebounce = null;
      return;
    }
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeDebounce = null;
    _refreshRtfPreviewChild(reason: reason);
  }

  void _scheduleRtfPreviewResizeFinalRecapture(Rect resizeEndRect) {
    final token = ++_rtfPreviewResizeFinalizeToken;
    _rtfPreviewResizeFinalizeTimer?.cancel();
    _rtfPreviewResizeFinalizeTimer = Timer(const Duration(milliseconds: 180), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || token != _rtfPreviewResizeFinalizeToken) {
          return;
        }
        final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
        final window = _commonLabelPreviewWindow;
        if (window == null ||
            !window.isVisible ||
            !labelSheetLooksLikeRichEditRtf(rtf)) {
          return;
        }
        const padding = LabelSheetRtfPreview.defaultPadding;
        final rectTarget = Size(
          (resizeEndRect.width - padding.horizontal).clamp(
            1.0,
            double.infinity,
          ),
          (resizeEndRect.height - padding.vertical).clamp(1.0, double.infinity),
        );
        final renderObject = _rtfPreviewBoxKey.currentContext
            ?.findRenderObject();
        Size? measuredTarget;
        if (renderObject is RenderBox && renderObject.hasSize) {
          measuredTarget = Size(
            (renderObject.size.width - padding.horizontal).clamp(
              1.0,
              double.infinity,
            ),
            (renderObject.size.height - padding.vertical).clamp(
              1.0,
              double.infinity,
            ),
          );
        }
        final current = _rtfPreviewTargetContentSize;
        final next = measuredTarget ?? rectTarget;
        final currentDeltaWidth = current == null
            ? double.infinity
            : (current.width - next.width).abs();
        final currentDeltaHeight = current == null
            ? double.infinity
            : (current.height - next.height).abs();
        final refreshedTarget = _rtfPreviewRefreshedTargetContentSize;
        if (_rtfPreviewHasResolvedImage) {
          labelSheetRtfPreviewDebugLog(
            'rtf preview resize final recapture skipped existing image '
            'rectTarget=${rectTarget.width.round()}x${rectTarget.height.round()} '
            'measuredTarget=${measuredTarget == null ? 'none' : '${measuredTarget.width.round()}x${measuredTarget.height.round()}'} '
            'current=${current == null ? 'none' : '${current.width.round()}x${current.height.round()}'} '
            'refreshed=${refreshedTarget == null ? 'none' : '${refreshedTarget.width.round()}x${refreshedTarget.height.round()}'} '
            'image=${_rtfPreviewLastResolvedImageSize == null ? 'none' : '${_rtfPreviewLastResolvedImageSize!.width.round()}x${_rtfPreviewLastResolvedImageSize!.height.round()}'}',
          );
          return;
        }
        final shouldUseMeasuredTarget =
            current == null ||
            currentDeltaWidth > 2.0 ||
            currentDeltaHeight > 2.0;
        final recaptureTarget = shouldUseMeasuredTarget ? next : current;
        final shouldRecapture = !_isSameRoundedSize(
          refreshedTarget,
          recaptureTarget,
        );
        labelSheetRtfPreviewDebugLog(
          'rtf preview resize final recapture '
          'rectTarget=${rectTarget.width.round()}x${rectTarget.height.round()} '
          'measuredTarget=${measuredTarget == null ? 'none' : '${measuredTarget.width.round()}x${measuredTarget.height.round()}'} '
          'current=${current == null ? 'none' : '${current.width.round()}x${current.height.round()}'} '
          'delta=${currentDeltaWidth.toStringAsFixed(1)}x${currentDeltaHeight.toStringAsFixed(1)} '
          'refreshed=${refreshedTarget == null ? 'none' : '${refreshedTarget.width.round()}x${refreshedTarget.height.round()}'} '
          'recapture=$shouldRecapture',
        );
        if (!shouldRecapture) {
          return;
        }
        _rtfPreviewTargetContentSize = recaptureTarget;
        _refreshRtfPreviewChild(reason: 'resizeEndSettled');
      });
    });
  }

  void _refreshRtfPreviewChild({required String reason}) {
    _rtfPreviewResizeDebounce = null;
    if (!mounted || _selectedTabValue() != 'common_label') return;
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    final window = _commonLabelPreviewWindow;
    if (window == null ||
        !window.isVisible ||
        !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    _rtfPreviewCaptureGeneration += 1;
    final target = _rtfPreviewTargetContentSize;
    _rtfPreviewRefreshedTargetContentSize = target;
    _rtfPreviewHasResolvedImage = false;
    _rtfPreviewLastResolvedImageSize = null;
    _rtfPreviewLastNativeImage = null;
    _rtfPreviewLastNativeImageKey = null;
    labelSheetRtfPreviewDebugLog(
      'rtf preview recapture child refresh reason=$reason '
      'generation=$_rtfPreviewCaptureGeneration '
      'target=${target == null ? 'auto' : '${target.width.round()}x${target.height.round()}'}',
    );
    window.setChild(_buildRtfPreview(rtf!));
  }

  void _hideFloatingWindows() {
    _itemPreviewWindow?.hide();
    _commonLabelPreviewWindow?.hide();
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeDebounce = null;
    _rtfPreviewResizeFinalizeTimer?.cancel();
    _rtfPreviewResizeFinalizeTimer = null;
  }

  void _handleTopDropdownMenuStateChanged(bool isOpen) {
    final selectedTab = _selectedTabValue();
    final window = _commonLabelPreviewWindow;
    debugLog(
      'top dropdown menu state isOpen=$isOpen '
      'tab=$selectedTab previewVisible=${window?.isVisible ?? false} '
      'previewRouteId=${window?.debugRouteId ?? 'none'}',
    );
    if (!isOpen || selectedTab != 'common_label') {
      return;
    }
    window?.keepBelowRoutePopups(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postFrameTab = _selectedTabValue();
      final postFrameWindow = _commonLabelPreviewWindow;
      debugLog(
        'top dropdown menu postFrame '
        'mounted=$mounted tab=$postFrameTab '
        'previewVisible=${postFrameWindow?.isVisible ?? false} '
        'previewRouteId=${postFrameWindow?.debugRouteId ?? 'none'}',
      );
      if (!mounted || postFrameTab != 'common_label') return;
      postFrameWindow?.keepBelowRoutePopups(context);
    });
  }

  void _handleAppMenuOpenChanged(bool isOpen) {
    if (!isOpen) return;
    _keepFloatingPreviewsBelowRoutePopups();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keepFloatingPreviewsBelowRoutePopups();
    });
  }

  void _keepFloatingPreviewsBelowRoutePopups() {
    _itemPreviewWindow?.keepBelowRoutePopups(context);
    _commonLabelPreviewWindow?.keepBelowRoutePopups(context);
  }

  String _rtfPreviewKey(LabelSize? labelSize, String rtf) =>
      '${labelSize?.labelSizeId ?? 'none'}:${rtf.length}:${rtf.hashCode}';

  void _handleCommonLabelSheetReady() {
    // 브랜드 변경으로 표시된 '브랜드 데이터를 불러오고 있습니다...' 스낵바를
    // 시트가 실제로 준비된 시점에 닫는다(RTF 여부 무관).
    // RTF 있을 경우: '브랜드 데이터...' → (RTF 시작 시 clearSnackBars) →
    //   'RTF를 변환 중입니다...' → 이 시점엔 RTF 스낵바를 닫음.
    // RTF 없을 경우: '브랜드 데이터...' → 이 시점에 닫음.
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    if (!_commonLabelTabActivated) {
      return;
    }
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    if (!Platform.isWindows || !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    _rtfPreviewReadyKey = _rtfPreviewKey(_effectiveLabelSize, rtf!);
    if (_selectedTabValue() == 'common_label') {
      _showRtfPreviewWindow();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleTabShortcutKeyEvent);
    widget.appMenuController.detach(this);
    widget.controller.detach(this);
    widget.onExitSnapshotProviderChanged?.call(null);
    final readyCompleter = _itemManagerReadyCompleter;
    if (readyCompleter != null && !readyCompleter.isCompleted) {
      readyCompleter.complete();
    }
    _itemDraftController?.removeListener(_handleItemDraftDirtyChanged);
    _itemDraftController?.dispose();
    _autoItemUpdateDraftController?.dispose();
    _closeLabelPrintProgressDialog();
    _closeScaleOutputProgressDialog();
    unawaited(_scaleConnectionService.disconnect());
    _labelPrintSessionController.removeListener(_handleLabelPrintChanged);
    _labelPrintSessionController.dispose();
    _scaleOutputSessionController.removeListener(_handleScaleOutputChanged);
    _scaleOutputSessionController.dispose();
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeFinalizeTimer?.cancel();
    _scaleAutoPrintTimer?.cancel();
    _itemPreviewWindow?.dispose();
    _commonLabelPreviewWindow?.dispose();
    _itemElementPreviewZoomController.dispose();
    _itemOutputPreviewZoomController.dispose();
    _tabController.dispose();
    _tabSearchController.dispose();
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
    _labelSettingsOverlayEntry?.remove();
    _labelSettingsOverlayEntry = null;
    _labelColumnEditOverlayEntry?.remove();
    _labelColumnEditOverlayEntry = null;
    _closePrintHistoryDialog();
    _closeContentSaveHistoryDialog();
    _closeCommonLabelHistoryDialog();
    _closeStatusPrintDialog();
    _closeLoginHistoryDialog();
    _closeCooperatorManagerDialog();
    _cooperatorManagerController.dispose();
    _closeCustomerManagerDialog();
    _customerManagerController.dispose();
    _closeMarketManagerDialog();
    _marketManagerController.dispose();
    _closeUserManagerDialog();
    _userManagerController.dispose();
    _closeAdminCopyDialog();
    _adminCopyController.dispose();
    _closeSearchAndReplaceDialog();
    _searchAndReplaceController.dispose();
    _closeItemInfoDialog();
    _itemInfoController.dispose();
    _closeNutritionTypeDialog();
    _nutritionTypeDialogController.dispose();
    _closeNutritionBoxDialog();
    _nutritionBoxDialogController.dispose();
    _closeUpdateNoticeDialog();
    _updateNoticeDialogController.dispose();
    _closeSearchPrintSettingsDialog();
    _searchPrintSettingsDialogController.dispose();
    _brandDialogBusyNotifier.dispose();
    super.dispose();
  }

  Future<void> _onTabSearch() async {
    final query = _tabSearchController.text.trim();
    if (widget.searchPrintModeActive) {
      try {
        await runSearchPrintInputCommand(
          controller: _tabSearchController,
          issue: _issueSearchPrint,
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('검색출력 실패: $error')));
        }
      }
      return;
    }
    _openSearchAndReplaceDialog(query);
    return;
    // 검색출력모드는 5.3.10에서 이 아래 기존 tab-local 검색과 분기한다.
    // ignore: dead_code
    final selectedTabValue = _selectedTabValue();
    if (selectedTabValue == 'label_print') {
      final found = _labelPrintSessionController.selectNextExact(query, (
        row,
      ) sync* {
        yield row.item.item.itemName;
        final draftController = _itemDraftController;
        if (draftController == null) return;
        for (final column in TColumn.datas ?? const <TColumn>[]) {
          if (column.searchPrint) {
            yield draftController.scopedColumnContents.value(
              column.columnId,
              row.itemId,
            );
          }
        }
      });
      if (found || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('검색'),
          content: const Text('일치하는 출력 품목이 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    final result = switch (selectedTabValue) {
      'items' => _itemManageController.search(query),
      'auto_update' => _autoItemUpdatePageController.search(query),
      'scale_output' => _scaleOutputPageController.search(query),
      _ => TableSearchResult.unavailable,
    };
    if (result == TableSearchResult.found || !mounted) return;
    if (result == TableSearchResult.unavailable) {
      final content = switch (selectedTabValue) {
        'auto_update' => '검색할 자동갱신 품목이 없습니다.',
        'scale_output' => '검색할 저울출력 품목이 없습니다.',
        _ => '일치하는 품목이 없습니다.',
      };
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('검색'),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    final restart = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('검색'),
        content: const Text('마지막까지 검색하였습니다. 처음부터 검색하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (restart != true) return;
    switch (selectedTabValue) {
      case 'items':
        _itemManageController.resetSearch();
      case 'auto_update':
        _autoItemUpdatePageController.resetSearch();
      case 'scale_output':
        _scaleOutputPageController.resetSearch();
    }
  }

  Widget _buildLabelPrintPreview(
    LabelPrintRowDraft row,
    LabelSheetZoomController zoomController,
  ) {
    final columns = TColumn.datas ?? const <TColumn>[];
    final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
    final renderUnit = _labelPrintRenderUnit?.row.itemId == row.itemId
        ? _labelPrintRenderUnit
        : null;
    final referenceAt = renderUnit == null
        ? DateTime.now()
        : _labelPrintRenderReferenceAt!;
    final projectedColumnValues =
        renderUnit?.projectedColumnValues ??
        _baselineOutputProjectedColumnValues(
          itemId: row.itemId,
          referenceAt: referenceAt,
        );
    return _ItemOutputPreviewTab(
      key: ValueKey('label-print-preview:${row.itemId}'),
      item: row.item,
      elementText: row.item.item.element,
      elementWorkbook: _itemElementFormStateFor(
        row.item,
        _effectiveLabelSize,
      ).workbook,
      labelSize: _effectiveLabelSize,
      imageObjectIds: _itemPreviewImageObjectIdsFor([
        ...specialColumns,
        ...columns,
      ]),
      barcodeObjectIds: _itemPreviewBarcodeObjectIdsFor([
        ...specialColumns,
        ...columns,
      ]),
      outputCaptureController: _labelPrintCaptureController,
      referenceAt: referenceAt,
      projectedColumnValues: projectedColumnValues,
      zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
      zoomController: zoomController,
    );
  }

  Map<int, String> _scaleOutputProjectedColumnValues(
    ScaleOutputRowDraft row, {
    ScaleOutputUnit? renderUnit,
    required DateTime referenceAt,
  }) {
    final base = renderUnit?.projectedColumnValues ??
        _baselineOutputProjectedColumnValues(
          itemId: row.itemId,
          referenceAt: referenceAt,
        );
    return <int, String>{
      ...base,
      ...scaleOutputProjectedSpecialValues(
        item: row.item,
        weightText: renderUnit?.row.weightText ?? row.weightText,
        priceText: renderUnit?.row.priceText ?? row.priceText,
      ),
    };
  }

  Widget _buildScaleOutputPreview(
    ScaleOutputRowDraft row,
    LabelSheetZoomController zoomController,
  ) {
    final columns = TColumn.datas ?? const <TColumn>[];
    final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
    final renderUnit = _scaleOutputRenderUnit?.row.itemId == row.itemId
        ? _scaleOutputRenderUnit
        : null;
    final referenceAt = renderUnit == null
        ? DateTime.now()
        : _scaleOutputRenderReferenceAt!;
    final projectedColumnValues = _scaleOutputProjectedColumnValues(
      row,
      renderUnit: renderUnit,
      referenceAt: referenceAt,
    );
    return _ItemOutputPreviewTab(
      key: ValueKey('scale-output-preview:${row.itemId}:${row.weightText}:${row.priceText}'),
      item: row.item,
      elementText: row.item.item.element,
      elementWorkbook: _itemElementFormStateFor(
        row.item,
        _effectiveLabelSize,
      ).workbook,
      labelSize: _effectiveLabelSize,
      imageObjectIds: _itemPreviewImageObjectIdsFor([
        ...specialColumns,
        ...columns,
      ]),
      barcodeObjectIds: _itemPreviewBarcodeObjectIdsFor([
        ...specialColumns,
        ...columns,
      ]),
      outputCaptureController: _scaleOutputCaptureController,
      referenceAt: referenceAt,
      projectedColumnValues: projectedColumnValues,
      zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
      zoomController: zoomController,
    );
  }

  Map<int, String> _baselineOutputProjectedColumnValues({
    required int itemId,
    required DateTime referenceAt,
  }) => projectLabelPrintColumnValues(
    itemId: itemId,
    copyIndex: 0,
    columns: TColumn.datas ?? const <TColumn>[],
    columnContents:
        TColumnContent.datas ?? const <ColumnItemKey, TColumnContent>{},
    referenceAt: referenceAt,
  );

  Future<void> _openLabelPrintSettings() async {
    final persisted = await loadLabelPrintSettingsSnapshot();
    if (!mounted) return;
    final settings = await showLabelPrintSettingsDialog(
      context: context,
      initial: persisted,
    );
    if (!mounted || settings == null) return;
    await saveLabelPrintSettingsSnapshot(settings);
    if (!mounted) return;
    _labelPrintSessionController.applySettings(settings);
  }

  Future<void> _openScaleOutputPrinterSettings() async {
    final labelSizeId = _effectiveLabelSize?.labelSizeId;
    if (labelSizeId == null) return;
    final settings = await showLabelPrintSettingsDialog(
      context: context,
      initial: _scaleOutputSessionController.settings,
    );
    if (!mounted || settings == null) return;
    await ScaleOutputPrintSettingsStore.save(labelSizeId, settings);
    if (!mounted) return;
    _scaleOutputSessionController.applySettings(settings);
  }

  Future<void> _openScaleConnectSettings() async {
    await _scaleConnectionService.disconnect();
    if (!mounted) return;
    _scaleOutputSessionController.setConnectionState(
      ScaleOutputConnectionState.disconnected,
      statusText: '연결 안 됨',
    );
    final persisted = await DbScaleConnectInfoHelper.loadConnectInfo();
    if (!mounted) return;
    final settings = await showScaleConnectSettingsDialog(
      context: context,
      initial: persisted,
    );
    if (!mounted || settings == null) return;
    await DbScaleConnectInfoHelper.saveConnectInfo(settings);
    if (!mounted) return;
    _scaleOutputSessionController.updateConnectInfo(settings);
  }

  Future<void> _requestCloseUpdateNoticeDialog() async {
    final snapshot = _updateNoticeDialogController.snapshot();
    if (snapshot.blockingReason != null) return;
    if (snapshot.dirtyWorks.isNotEmpty) {
      final discard = await showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (_, close) => AlertDialog(
          title: const Text('업데이트 메시지'),
          content: const Text('저장하지 않은 변경내용을 버리시겠습니까?'),
          actions: [
            TextButton(onPressed: () => close(false), child: const Text('취소')),
            FilledButton(onPressed: () => close(true), child: const Text('확인')),
          ],
        ),
      );
      if (discard != true) return;
      for (final work in snapshot.dirtyWorks) {
        await work.discard();
      }
    }
    _closeUpdateNoticeDialog();
  }

  void _closeUpdateNoticeDialog() {
    _updateNoticeOverlayEntry?.remove();
    _updateNoticeOverlayEntry = null;
    _updateNoticeDialogController.discard();
    final participant = _updateNoticeLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _updateNoticeLifecycleParticipant = null;
    }
  }

  Future<void> _openUpdateNoticeDialog() async {
    if (_updateNoticeOverlayEntry != null) return;
    final user = User.instance;
    final cooperator = Cooperator.instance;
    if (user == null || cooperator == null) return;

    try {
      final notice = await NoticeDAO.selectNoticeByUserId(user.userId);
      final isAdministrator =
          user.grade == UserGrade.SYSTEM_ADMIN_USER ||
          user.grade == UserGrade.COOP_ADMIN_USER;
      final targetUsers = isAdministrator
          ? await NoticeDAO.selectTargetUsers(cooperator.id)
          : const <NoticeTargetUser>[];
      if (!mounted) return;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => BlockingModelessDialog(
          child: UpdateNoticeDialog(
          controller: _updateNoticeDialogController,
          user: user,
          notice: notice,
          targetUsers: targetUsers,
          onClose: _requestCloseUpdateNoticeDialog,
          onCommitOutcomeUnknown: _closeUpdateNoticeDialog,
          onSave: (request) async {
            switch (request.target) {
              case UpdateNoticeSaveTarget.selectedUsers:
                await NoticeDAO.updateSelectedUsers(
                  userIds: request.selectedUserIds,
                  message: request.message!,
                );
              case UpdateNoticeSaveTarget.allCooperators:
                await NoticeDAO.updateAll(request.message!);
              case UpdateNoticeSaveTarget.currentCooperator:
                await NoticeDAO.updateCooperator(
                  cooperatorId: cooperator.id,
                  message: request.message!,
                );
              case UpdateNoticeSaveTarget.currentUser:
                await NoticeDAO.updateUserState(
                  userId: user.userId,
                  dontShowAgain: request.dontShowAgain,
                );
            }
          },
        ),
      ),
      );
      _updateNoticeOverlayEntry = entry;
      final participant = LifecycleParticipant(
        snapshot: _updateNoticeDialogController.snapshot,
        close: _closeUpdateNoticeDialog,
      );
      _updateNoticeLifecycleParticipant = participant;
      LifecycleManager.instance.addParticipant(participant);
      Overlay.of(context, rootOverlay: true).insert(entry);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('업데이트 메시지를 불러오지 못했습니다.\n$error')),
        );
    }
  }

  void _closeSearchPrintSettingsDialog() {
    _searchPrintSettingsOverlayEntry?.remove();
    _searchPrintSettingsOverlayEntry = null;
    _searchPrintSettingsDialogController.discard();
    final participant = _searchPrintSettingsLifecycleParticipant;
    if (participant != null) {
      LifecycleManager.instance.removeParticipant(participant);
      _searchPrintSettingsLifecycleParticipant = null;
    }
  }

  Future<void> _openSearchPrintSettingsDialog() async {
    if (_searchPrintSettingsOverlayEntry != null) return;
    final customer = Customer.instance;
    if (customer == null) return;
    try {
      final brands =
          await BrandDAO.selectByCustomerIdByBrandOrder(customer.customerId) ??
          const <Brand>[];
      if (!mounted) return;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => BlockingModelessDialog(
          child: SearchPrintSettingsDialog(
          controller: _searchPrintSettingsDialogController,
          brands: brands,
          initialBrand: widget.selectedBrand,
          initialLabelSize: _effectiveLabelSize,
          loadLabelSizes: (brandId) async =>
              await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(brandId) ??
              const <LabelSize>[],
          loadColumns: (labelSizeId) async =>
              await TColumnDAO.selectByLabelSizeId(labelSizeId) ??
              const <TColumn>[],
          apply: ({
            required labelSizeId,
            required originalColumns,
            required workingColumns,
          }) async {
            final command = buildSearchPrintSettingsSaveCommand(
              labelSizeId: labelSizeId,
              customerId: customer.customerId,
              originalColumns: originalColumns,
              workingColumns: workingColumns,
            );
            List<TColumn>? reloaded;
            await executeLabelColumnSaveAndReload(
              command,
              reload: () async {
                reloaded = await TColumnDAO.selectByLabelSizeId(labelSizeId);
                return reloaded != null;
              },
            );
            return reloaded!;
          },
          onClose: _closeSearchPrintSettingsDialog,
        ),
      ),
      );
      _searchPrintSettingsOverlayEntry = entry;
      final participant = LifecycleParticipant(
        snapshot: _searchPrintSettingsDialogController.snapshot,
        close: _closeSearchPrintSettingsDialog,
      );
      _searchPrintSettingsLifecycleParticipant = participant;
      LifecycleManager.instance.addParticipant(participant);
      Overlay.of(context, rootOverlay: true).insert(entry);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('검색출력 설정을 불러오지 못했습니다.\n$error')),
        );
    }
  }

  Future<void> _connectScaleOutput() async {
    final info = _scaleOutputSessionController.connectInfo;
    _scaleOutputSessionController.setConnectionState(
      ScaleOutputConnectionState.connecting,
      statusText: '연결 중',
      portName: info.portName,
    );
    try {
      final connected = await _scaleConnectionService.connect(
        info: info,
        onWeight: (rawWeight) {
          if (!mounted) return;
          _handleScaleIncomingWeight(rawWeight);
        },
      );
      if (!mounted || !connected) return;
      _scaleOutputSessionController.setConnectionState(
        ScaleOutputConnectionState.connected,
        statusText: '연결됨',
        portName: info.portName,
      );
    } catch (error) {
      if (!mounted) return;
      _scaleOutputSessionController.setConnectionState(
        ScaleOutputConnectionState.error,
        statusText: '$error',
        portName: info.portName,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('저울 연결에 실패했습니다: $error')));
    }
  }

  Future<void> _disconnectScaleOutput() async {
    await _scaleConnectionService.disconnect();
    if (!mounted) return;
    _scaleOutputSessionController.setConnectionState(
      ScaleOutputConnectionState.disconnected,
      statusText: '연결 안 됨',
      portName: _scaleOutputSessionController.connectInfo.portName,
    );
  }

  void _handleScaleIncomingWeight(String rawWeight) {
    final reading = scaleOutputParseIncomingReading(rawWeight);
    _scaleOutputSessionController.applyIncomingWeight(
      reading?.weight ?? rawWeight,
    );
    if (reading == null ||
        !_scaleOutputSessionController.connectInfo.autoPrint ||
        !scaleOutputIsStablePositiveReading(reading) ||
        _scaleAutoPrintTimer != null) {
      return;
    }
    _scaleAutoPrintTimer = Timer(const Duration(seconds: 5), () {
      _scaleAutoPrintTimer = null;
      if (!mounted || !_scaleOutputSessionController.isConnected) return;
      unawaited(_issueScaleOutput());
    });
  }

  Future<void> _issueSearchPrint(String query) async {
    if (query.isEmpty) throw StateError('검색할 데이터가 없습니다.');
    final labelSize = _effectiveLabelSize;
    if (labelSize == null) throw StateError('현재 라벨을 확인할 수 없습니다.');
    final result = await SearchPrintDAO.selectFirst(
      labelSizeId: labelSize.labelSizeId,
      query: query,
    );
    if (result == null) throw StateError('일치하는 품목이 없습니다.');
    final item = searchPrintFindBaselineItem(
      ItemOfMarket.datas ?? const <ItemOfMarket>[],
      result.itemId,
    );
    final draftController = _itemDraftController;
    if (item == null || draftController == null) {
      throw StateError('발행할 품목 정보를 확인할 수 없습니다.');
    }
    final row = LabelPrintRowDraft.fromBaseline(
      item: item,
      labelSize: labelSize,
      copies: resolveLabelPrintCopies(
        item: item,
        columns: TColumn.datas ?? const <TColumn>[],
        columnContents: draftController.scopedColumnContents,
      ),
      settings: _labelPrintSessionController.settings,
    );
    await _issueLabelPrint(rowsOverride: [row]);
  }

  Future<void> _issueLabelPrint({
    List<LabelPrintRowDraft>? rowsOverride,
  }) async {
    final rowsSnapshot = rowsOverride == null
        ? null
        : _labelPrintSessionController.replaceRowsForIssue(rowsOverride);
    if (!_labelPrintSessionController.beginIssue()) {
      if (rowsSnapshot != null) {
        _labelPrintSessionController.restoreRowsAfterIssue(rowsSnapshot);
      }
      return;
    }
    final originalSelection = _labelPrintSessionController.selectedItemId;
    final requestedAt = DateTime.now();
    _labelPrintRenderReferenceAt = requestedAt;
    try {
      final settings = _labelPrintSessionController.settings;
      final commandUser = User.instance;
      final commandMarket = Market.instance;
      final commandCustomer = Customer.instance;
      final commandBrand = widget.selectedBrand;
      final commandLabelSize = _effectiveLabelSize;
      if (commandUser == null ||
          commandMarket == null ||
          commandCustomer == null ||
          commandBrand == null ||
          commandLabelSize == null) {
        throw StateError('라벨 발행 기준 정보를 확인할 수 없습니다.');
      }
      final printerName = settings.printerName?.trim() ?? '';
      final printers = await Printing.listPrinters();
      final printer = printers.firstWhereOrNull(
        (candidate) =>
            candidate.name.trim().toLowerCase() == printerName.toLowerCase(),
      );
      if (printer == null) {
        throw StateError('발행할 프린터를 찾을 수 없습니다.');
      }
      final profile = detectPrinterProfile(printer);
      final portName = Platform.isWindows
          ? await RawPrinterWin32.queryPrinterPortName(printer)
          : null;
      final backend = resolveLabelPrintBackend(
        language: profile.language,
        portName: portName,
      );
      final printerDpi = Platform.isWindows
          ? await RawPrinterWin32.queryPrinterDpi(printer)
          : null;
      final dpi = printerDpi?.toDouble() ?? profile.dpi ?? 203;
      final rows = _labelPrintSessionController.rows;
      final columns = List<TColumn>.unmodifiable(
        [...TColumn.datas ?? const <TColumn>[]]..sort((left, right) {
          final order = left.order.compareTo(right.order);
          return order != 0 ? order : left.columnId.compareTo(right.columnId);
        }),
      );
      final columnContents = Map<ColumnItemKey, TColumnContent>.unmodifiable(
        TColumnContent.datas ?? const <ColumnItemKey, TColumnContent>{},
      );
      final units = expandLabelPrintUnits(
        rows,
        columns: columns,
        columnContents: columnContents,
        referenceAt: requestedAt,
      );
      if (units.isEmpty) {
        throw StateError('전체 발행매수는 1 이상이어야 합니다.');
      }

      _labelPrintSessionController.reportIssueUnit(
        unitNumber: 1,
        totalUnits: units.length,
      );
      _openLabelPrintProgressDialog();

      final renderedPages = <LabelPrintUnit, LabelSheetRenderedPage>{};
      final hybridCaptures = <LabelPrintUnit, LabelSheetHybridEzplCapture>{};
      final resolvedMetrics = <LabelPrintUnit, LabelSheetPrintPageMetrics>{};
      for (var unitIndex = 0; unitIndex < units.length; unitIndex += 1) {
        if (_labelPrintSessionController.cancellationRequested) {
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('라벨 발행을 취소했습니다. 접수 매수: 0')),
              );
          }
          return;
        }
        _labelPrintSessionController.reportIssueUnit(
          unitNumber: unitIndex + 1,
          totalUnits: units.length,
        );
        final unit = units[unitIndex];
        _labelPrintRenderUnit = unit;
        _labelPrintSessionController.selectItem(unit.row.itemId);
        _labelPrintSessionController.refreshPreview();
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        final options = _labelPrintOptions(unit.row, settings);
        late final fs.FortuneSheet capturedSheet;
        late final LabelSheetPrintPageMetrics metrics;
        if (backend == LabelPrintBackend.pdf) {
          final capture = await _labelPrintCaptureController.capture(
            dpi: dpi,
            lineSpacingPercent: unit.row.lineSpacingPercent,
          );
          if (capture == null) {
            throw StateError(
              '${unit.row.item.item.itemName} 라벨 이미지를 생성할 수 없습니다.',
            );
          }
          capturedSheet = capture.sheet;
          metrics = LabelSheetPrintPageMetrics(
            labelWidthMm: unit.row.widthMm,
            labelHeightMm: unit.row.heightMm,
            sourceWidthMm: capture.sourceWidthMm,
            sourceHeightMm: capture.sourceHeightMm,
            dpi: dpi,
          );
          renderedPages[unit] = LabelSheetRenderedPage(
            pngBytes: capture.pngBytes,
            metrics: metrics,
            options: options,
          );
        } else {
          final hybrid = await _labelPrintCaptureController.captureHybridEzpl(
            metrics: LabelSheetPrintPageMetrics(
              labelWidthMm: unit.row.widthMm,
              labelHeightMm: unit.row.heightMm,
              dpi: dpi,
            ),
            options: options,
            lineSpacingPercent: unit.row.lineSpacingPercent,
          );
          if (hybrid == null) {
            throw StateError(
              '${unit.row.item.item.itemName} 라벨 이미지를 생성할 수 없습니다.',
            );
          }
          capturedSheet = hybrid.sheet;
          metrics = hybrid.metrics;
          hybridCaptures[unit] = hybrid;
        }
        final errors = capturedSheet.images
            .map(
              (image) => image.extraFields['itemCodeError']?.toString().trim(),
            )
            .whereType<String>()
            .where((message) => message.isNotEmpty)
            .toList();
        if (errors.isNotEmpty) {
          throw StateError(
            '${unit.row.item.item.itemName} ${unit.copyIndex + 1}번째 라벨: ${errors.first}',
          );
        }
        if (!LabelSheetPrintLayout.resolve(
          metrics: metrics,
          options: options,
        ).hasContentIntersection) {
          throw StateError(
            '${unit.row.item.item.itemName}의 출력 영역과 라벨 영역이 겹치지 않습니다.',
          );
        }
        resolvedMetrics[unit] = metrics;
      }

      final groups = groupAdjacentLabelPrintUnits(units, (unit) {
        final metrics = resolvedMetrics[unit]!;
        return LabelPhysicalPageSpec(
          widthMm: unit.row.widthMm,
          heightMm: unit.row.heightMm,
          sourceWidthMm: metrics.effectiveSourceWidthMm,
          sourceHeightMm: metrics.effectiveSourceHeightMm,
          dpi: dpi,
          backend: backend,
        );
      });
      final payloads = <LabelPrintJobGroup, List<int>>{};
      for (final group in groups) {
        if (backend == LabelPrintBackend.pdf) {
          payloads[group] = await buildLabelSheetPdfGroupBytes([
            for (final unit in group.units) renderedPages[unit]!,
          ]);
        } else {
          final bytes = BytesBuilder(copy: false);
          for (final unit in group.units) {
            bytes.add(hybridCaptures[unit]!.bytes);
          }
          payloads[group] = bytes.takeBytes();
        }
      }

      final acceptedUnits = <LabelPrintUnit>[];
      Object? dispatchError;
      for (final group in groups) {
        if (_labelPrintSessionController.cancellationRequested) break;
        final payload = Uint8List.fromList(payloads[group]!);
        var accepted = false;
        try {
          accepted = switch (backend) {
            LabelPrintBackend.pdf => await Printing.directPrintPdf(
              printer: printer,
              name: 'ITSnG_Label_${requestedAt.millisecondsSinceEpoch}',
              format: PdfPageFormat(
                group.pageSpec.widthMm * PdfPageFormat.mm,
                (group.pageSpec.heightMm + settings.extraAreaMm) *
                    PdfPageFormat.mm,
                marginAll: 0,
              ),
              dynamicLayout: false,
              onLayout: (_) async => payload,
            ),
            LabelPrintBackend.ezplRaw => await (() async {
              await RawPrinterWin32.sendRaw(printer, payload);
              return true;
            })(),
          };
          if (!accepted) dispatchError = StateError('프린터가 인쇄 요청을 접수하지 않았습니다.');
        } catch (error) {
          dispatchError = error;
        }
        if (!accepted) break;
        acceptedUnits.addAll(group.units);
      }

      final autoIncrementValues = buildAcceptedAutoIncrementValues(
        acceptedUnits: acceptedUnits,
        columns: columns,
        columnContents: columnContents,
        referenceAt: requestedAt,
      );
      final historyParents =
          labelPrintHistoryEnabledForUserId(
            commandUser.userId,
            systemUserId: User.SYSTEM,
          )
          ? buildLabelPrintHistoryParents(
              acceptedUnits: acceptedUnits,
              columns: columns,
              columnContents: columnContents,
              context: LabelPrintHistoryContext(
                userId: commandUser.userId,
                userName: commandUser.name,
                userGradeCode: commandUser.grade.code,
                userGradeLabel: commandUser.grade.label,
                marketId: commandMarket.marketId,
                marketName: commandMarket.name,
                customerId: commandCustomer.customerId,
                customerName: commandCustomer.customerName,
                brandId: commandBrand.brandId,
                brandName: commandBrand.brandName,
                labelSizeId: commandLabelSize.labelSizeId,
                labelSizeName: commandLabelSize.labelSizeName,
                printerName: printer.name,
                extraAreaMm: settings.extraAreaMm,
              ),
            )
          : const <Map<String, Object?>>[];
      final persistence = await LabelPrintPersistenceService().save(
        values: autoIncrementValues,
        historyParents: historyParents,
      );
      if (persistence.state == LabelPrintPersistenceState.succeeded &&
          persistence.committedAutoIncrementValues.isNotEmpty) {
        final nextContents = <ColumnItemKey, TColumnContent>{...columnContents};
        for (final entry in persistence.committedAutoIncrementValues.entries) {
          final previous = nextContents[entry.key];
          if (previous == null) continue;
          nextContents[entry.key] = TColumnContent(
            colContentId: previous.colContentId,
            columnId: previous.columnId,
            itemId: previous.itemId,
            editable: previous.editable,
            dataString: entry.value,
          );
        }
        final scopedView = TColumnContentScopedView(nextContents);
        TColumnContent.setDatas(scopedView.values);
        _itemDraftController?.replaceBaselineColumnContents(scopedView);
        _labelPrintSessionController.applyCommittedAutoIncrementValues(
          columns: columns,
          values: persistence.committedAutoIncrementValues,
        );
      }
      if (!mounted) return;
      final message = switch (persistence.state) {
        LabelPrintPersistenceState.failed =>
          '인쇄 작업은 접수되었으나 ${_labelPrintPersistenceTarget(autoIncrementValues, historyParents)}을 저장하지 못했습니다: ${persistence.error}',
        LabelPrintPersistenceState.outcomeUnknown =>
          '인쇄 작업은 접수되었으나 ${_labelPrintPersistenceTarget(autoIncrementValues, historyParents)}의 저장 결과를 확인할 수 없습니다: ${persistence.error}',
        _
            when _labelPrintSessionController.cancellationRequested &&
                acceptedUnits.length < units.length =>
          '라벨 발행을 취소했습니다. 접수 매수: ${acceptedUnits.length}',
        _ when dispatchError != null && acceptedUnits.isNotEmpty =>
          '라벨 일부만 접수되었습니다. 접수 매수: ${acceptedUnits.length}, 오류: $dispatchError',
        _ when dispatchError != null => '라벨 발행에 실패했습니다: $dispatchError',
        _ => '라벨 발행을 완료했습니다. 접수 매수: ${acceptedUnits.length}',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('라벨 발행에 실패했습니다: $error')));
      }
    } finally {
      _closeLabelPrintProgressDialog();
      _labelPrintRenderUnit = null;
      _labelPrintRenderReferenceAt = null;
      if (originalSelection != null) {
        _labelPrintSessionController.selectItem(originalSelection);
      }
      _labelPrintSessionController.endIssue();
      if (rowsSnapshot != null) {
        _labelPrintSessionController.restoreRowsAfterIssue(rowsSnapshot);
      }
    }
  }

  void _cancelLabelPrint() => _labelPrintSessionController.requestCancel();

  Future<void> _issueScaleOutput() async {
    if (!_scaleOutputSessionController.beginIssue()) return;
    final useScale = _effectiveLabelSize?.labelSizeSetup?.useScale ?? false;
    final selectedRow = _scaleOutputSessionController.selectedRow;
    if (selectedRow == null) {
      _scaleOutputSessionController.endIssue();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('발행할 품목을 선택해 주세요.')));
      }
      return;
    }
    if (useScale) {
      final needsConfirm = scaleOutputNeedsIssueConfirmation(
        useScale: useScale,
        isConnected: _scaleOutputSessionController.isConnected,
        weightText: selectedRow.weightText,
      );
      if (needsConfirm) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('발행 확인'),
            content: const Text('저울이 연결되지 않았거나 중량이 비어 있습니다. 계속 발행하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          _scaleOutputSessionController.endIssue();
          return;
        }
      }
    }

    final originalSelection = _scaleOutputSessionController.selectedItemId;
    final requestedAt = DateTime.now();
    _scaleOutputRenderReferenceAt = requestedAt;
    try {
      final settings = _scaleOutputSessionController.settings;
      final commandUser = User.instance;
      final commandMarket = Market.instance;
      final commandCustomer = Customer.instance;
      final commandBrand = widget.selectedBrand;
      final commandLabelSize = _effectiveLabelSize;
      if (commandUser == null ||
          commandMarket == null ||
          commandCustomer == null ||
          commandBrand == null ||
          commandLabelSize == null) {
        throw StateError('저울출력 기준 정보를 확인할 수 없습니다.');
      }
      final printerName = settings.printerName?.trim() ?? '';
      final printers = await Printing.listPrinters();
      final printer = printers.firstWhereOrNull(
        (candidate) =>
            candidate.name.trim().toLowerCase() == printerName.toLowerCase(),
      );
      if (printer == null) {
        throw StateError('발행할 프린터를 찾을 수 없습니다.');
      }
      final profile = detectPrinterProfile(printer);
      final portName = Platform.isWindows
          ? await RawPrinterWin32.queryPrinterPortName(printer)
          : null;
      final backend = resolveLabelPrintBackend(
        language: profile.language,
        portName: portName,
      );
      final printerDpi = Platform.isWindows
          ? await RawPrinterWin32.queryPrinterDpi(printer)
          : null;
      final dpi = printerDpi?.toDouble() ?? profile.dpi ?? 203;
      final columns = List<TColumn>.unmodifiable(
        [...TColumn.datas ?? const <TColumn>[]]..sort((left, right) {
          final order = left.order.compareTo(right.order);
          return order != 0 ? order : left.columnId.compareTo(right.columnId);
        }),
      );
      final columnContents = Map<ColumnItemKey, TColumnContent>.unmodifiable(
        TColumnContent.datas ?? const <ColumnItemKey, TColumnContent>{},
      );
      final units = expandScaleOutputUnits(
        [selectedRow],
        referenceAt: requestedAt,
        columns: columns,
        columnContents: columnContents,
      );
      if (units.isEmpty) {
        throw StateError('전체 발행매수는 1 이상이어야 합니다.');
      }

      _scaleOutputSessionController.reportIssueUnit(
        unitNumber: 1,
        totalUnits: units.length,
      );
      _openScaleOutputProgressDialog();

      final renderedPages = <ScaleOutputUnit, LabelSheetRenderedPage>{};
      final hybridCaptures = <ScaleOutputUnit, LabelSheetHybridEzplCapture>{};
      final resolvedMetrics = <ScaleOutputUnit, LabelSheetPrintPageMetrics>{};
      for (var unitIndex = 0; unitIndex < units.length; unitIndex += 1) {
        if (_scaleOutputSessionController.cancellationRequested) {
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('저울 라벨 발행을 취소했습니다. 접수 매수: 0')),
              );
          }
          return;
        }
        _scaleOutputSessionController.reportIssueUnit(
          unitNumber: unitIndex + 1,
          totalUnits: units.length,
        );
        final unit = units[unitIndex];
        _scaleOutputRenderUnit = unit;
        _scaleOutputSessionController.selectItem(unit.row.itemId);
        _scaleOutputSessionController.refreshPreview();
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        final options = _scaleOutputPrintOptions(unit.row, settings);
        late final fs.FortuneSheet capturedSheet;
        late final LabelSheetPrintPageMetrics metrics;
        if (backend == LabelPrintBackend.pdf) {
          final capture = await _scaleOutputCaptureController.capture(
            dpi: dpi,
            lineSpacingPercent: unit.row.lineSpacingPercent,
          );
          if (capture == null) {
            throw StateError(
              '${unit.row.item.item.itemName} 라벨 이미지를 생성할 수 없습니다.',
            );
          }
          capturedSheet = capture.sheet;
          metrics = LabelSheetPrintPageMetrics(
            labelWidthMm: unit.row.widthMm,
            labelHeightMm: unit.row.heightMm,
            sourceWidthMm: capture.sourceWidthMm,
            sourceHeightMm: capture.sourceHeightMm,
            dpi: dpi,
          );
          renderedPages[unit] = LabelSheetRenderedPage(
            pngBytes: capture.pngBytes,
            metrics: metrics,
            options: options,
          );
        } else {
          final hybrid = await _scaleOutputCaptureController.captureHybridEzpl(
            metrics: LabelSheetPrintPageMetrics(
              labelWidthMm: unit.row.widthMm,
              labelHeightMm: unit.row.heightMm,
              dpi: dpi,
            ),
            options: options,
            lineSpacingPercent: unit.row.lineSpacingPercent,
          );
          if (hybrid == null) {
            throw StateError(
              '${unit.row.item.item.itemName} 라벨 이미지를 생성할 수 없습니다.',
            );
          }
          capturedSheet = hybrid.sheet;
          metrics = hybrid.metrics;
          hybridCaptures[unit] = hybrid;
        }
        final errors = capturedSheet.images
            .map(
              (image) => image.extraFields['itemCodeError']?.toString().trim(),
            )
            .whereType<String>()
            .where((message) => message.isNotEmpty)
            .toList();
        if (errors.isNotEmpty) {
          throw StateError(
            '${unit.row.item.item.itemName} ${unit.copyIndex + 1}번째 라벨: ${errors.first}',
          );
        }
        if (!LabelSheetPrintLayout.resolve(
          metrics: metrics,
          options: options,
        ).hasContentIntersection) {
          throw StateError(
            '${unit.row.item.item.itemName}의 출력 영역과 라벨 영역이 겹치지 않습니다.',
          );
        }
        resolvedMetrics[unit] = metrics;
      }

      final labelUnits = [for (final unit in units) unit.toLabelPrintUnit()];
      final groups = groupAdjacentLabelPrintUnits(labelUnits, (unit) {
        final sourceUnit = units[labelUnits.indexOf(unit)];
        final metrics = resolvedMetrics[sourceUnit]!;
        return LabelPhysicalPageSpec(
          widthMm: sourceUnit.row.widthMm,
          heightMm: sourceUnit.row.heightMm,
          sourceWidthMm: metrics.effectiveSourceWidthMm,
          sourceHeightMm: metrics.effectiveSourceHeightMm,
          dpi: dpi,
          backend: backend,
        );
      });
      final payloads = <LabelPrintJobGroup, List<int>>{};
      final groupSourceUnits = <LabelPrintJobGroup, List<ScaleOutputUnit>>{};
      var unitCursor = 0;
      for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
        final group = groups[groupIndex];
        final sourceUnits = units.sublist(unitCursor, unitCursor + group.units.length);
        unitCursor += group.units.length;
        groupSourceUnits[group] = sourceUnits;
        if (backend == LabelPrintBackend.pdf) {
          payloads[group] = await buildLabelSheetPdfGroupBytes([
            for (final unit in sourceUnits) renderedPages[unit]!,
          ]);
        } else {
          final bytes = BytesBuilder(copy: false);
          for (final unit in sourceUnits) {
            bytes.add(hybridCaptures[unit]!.bytes);
          }
          payloads[group] = bytes.takeBytes();
        }
      }

      final acceptedUnits = <ScaleOutputUnit>[];
      Object? dispatchError;
      for (var groupIndex = 0; groupIndex < groups.length; groupIndex += 1) {
        if (_scaleOutputSessionController.cancellationRequested) break;
        final group = groups[groupIndex];
        final sourceUnits = groupSourceUnits[group]!;
        final payload = Uint8List.fromList(payloads[group]!);
        var accepted = false;
        try {
          accepted = switch (backend) {
            LabelPrintBackend.pdf => await Printing.directPrintPdf(
              printer: printer,
              name: 'ITSnG_Scale_${requestedAt.millisecondsSinceEpoch}',
              format: PdfPageFormat(
                group.pageSpec.widthMm * PdfPageFormat.mm,
                (group.pageSpec.heightMm + settings.extraAreaMm) *
                    PdfPageFormat.mm,
                marginAll: 0,
              ),
              dynamicLayout: false,
              onLayout: (_) async => payload,
            ),
            LabelPrintBackend.ezplRaw => await (() async {
              await RawPrinterWin32.sendRaw(printer, payload);
              return true;
            })(),
          };
          if (!accepted) {
            dispatchError = StateError('프린터가 인쇄 요청을 접수하지 않았습니다.');
          }
        } catch (error) {
          dispatchError = error;
        }
        if (!accepted) break;
        acceptedUnits.addAll(sourceUnits);
      }

      final acceptedLabelUnits = [for (final unit in acceptedUnits) unit.toLabelPrintUnit()];
      final autoIncrementValues = buildAcceptedAutoIncrementValues(
        acceptedUnits: acceptedLabelUnits,
        columns: columns,
        columnContents: columnContents,
        referenceAt: requestedAt,
      );
      final historyParents = labelPrintHistoryEnabledForUserId(
            commandUser.userId,
            systemUserId: User.SYSTEM,
          )
          ? buildLabelPrintHistoryParents(
              acceptedUnits: acceptedLabelUnits,
              columns: columns,
              columnContents: columnContents,
              context: LabelPrintHistoryContext(
                userId: commandUser.userId,
                userName: commandUser.name,
                userGradeCode: commandUser.grade.code,
                userGradeLabel: commandUser.grade.label,
                marketId: commandMarket.marketId,
                marketName: commandMarket.name,
                customerId: commandCustomer.customerId,
                customerName: commandCustomer.customerName,
                brandId: commandBrand.brandId,
                brandName: commandBrand.brandName,
                labelSizeId: commandLabelSize.labelSizeId,
                labelSizeName: commandLabelSize.labelSizeName,
                printerName: printer.name,
                extraAreaMm: settings.extraAreaMm,
              ),
            )
          : const <Map<String, Object?>>[];
      final persistence = await LabelPrintPersistenceService().save(
        values: autoIncrementValues,
        historyParents: historyParents,
      );
      if (persistence.state == LabelPrintPersistenceState.succeeded &&
          persistence.committedAutoIncrementValues.isNotEmpty) {
        final nextContents = <ColumnItemKey, TColumnContent>{...columnContents};
        for (final entry in persistence.committedAutoIncrementValues.entries) {
          final previous = nextContents[entry.key];
          if (previous == null) continue;
          nextContents[entry.key] = TColumnContent(
            colContentId: previous.colContentId,
            columnId: previous.columnId,
            itemId: previous.itemId,
            editable: previous.editable,
            dataString: entry.value,
          );
        }
        final scopedView = TColumnContentScopedView(nextContents);
        TColumnContent.setDatas(scopedView.values);
        _itemDraftController?.replaceBaselineColumnContents(scopedView);
      }
      if (!mounted) return;
      final message = switch (persistence.state) {
        LabelPrintPersistenceState.failed =>
          '인쇄 작업은 접수되었으나 ${_labelPrintPersistenceTarget(autoIncrementValues, historyParents)}을 저장하지 못했습니다: ${persistence.error}',
        LabelPrintPersistenceState.outcomeUnknown =>
          '인쇄 작업은 접수되었으나 ${_labelPrintPersistenceTarget(autoIncrementValues, historyParents)}의 저장 결과를 확인할 수 없습니다: ${persistence.error}',
        _
            when _scaleOutputSessionController.cancellationRequested &&
                acceptedUnits.length < units.length =>
          '저울 라벨 발행을 취소했습니다. 접수 매수: ${acceptedUnits.length}',
        _ when dispatchError != null && acceptedUnits.isNotEmpty =>
          '저울 라벨 일부만 접수되었습니다. 접수 매수: ${acceptedUnits.length}, 오류: $dispatchError',
        _ when dispatchError != null => '저울 라벨 발행에 실패했습니다: $dispatchError',
        _ => '저울 라벨 발행을 완료했습니다. 접수 매수: ${acceptedUnits.length}',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('저울 라벨 발행에 실패했습니다: $error')),
          );
      }
    } finally {
      _closeScaleOutputProgressDialog();
      _scaleOutputRenderUnit = null;
      _scaleOutputRenderReferenceAt = null;
      if (originalSelection != null) {
        _scaleOutputSessionController.selectItem(originalSelection);
      }
      _scaleOutputSessionController.endIssue();
    }
  }

  void _cancelScaleOutput() => _scaleOutputSessionController.requestCancel();

  void _openLabelPrintProgressDialog() {
    if (_labelPrintProgressOverlayEntry != null) return;
    final entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: LabelPrintProgressDialog(
          controller: _labelPrintSessionController,
          onCancel: _cancelLabelPrint,
        ),
      ),
    );
    _labelPrintProgressOverlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closeLabelPrintProgressDialog() {
    _labelPrintProgressOverlayEntry?.remove();
    _labelPrintProgressOverlayEntry = null;
  }

  void _openScaleOutputProgressDialog() {
    if (_scaleOutputProgressOverlayEntry != null) return;
    final entry = OverlayEntry(
      builder: (_) => BlockingModelessDialog(
        child: ScaleOutputProgressDialog(
          controller: _scaleOutputSessionController,
          onCancel: _cancelScaleOutput,
        ),
      ),
    );
    _scaleOutputProgressOverlayEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  void _closeScaleOutputProgressDialog() {
    _scaleOutputProgressOverlayEntry?.remove();
    _scaleOutputProgressOverlayEntry = null;
  }

  String _labelPrintPersistenceTarget(
    Map<ColumnItemKey, String> values,
    List<Map<String, Object?>> historyParents,
  ) {
    if (values.isNotEmpty && historyParents.isNotEmpty) {
      return '자동증가 값과 발행 이력';
    }
    return values.isNotEmpty ? '자동증가 값' : '발행 이력';
  }

  LabelSheetPrintOptions _labelPrintOptions(
    LabelPrintRowDraft row,
    LabelPrintSettingsSnapshot settings,
  ) => LabelSheetPrintOptions(
    copies: 1,
    leftMarginMm: row.leftMarginMm,
    rightMarginMm: row.rightMarginMm,
    topMarginMm: row.topMarginMm,
    leftPushMm: row.leftPushMm,
    topPushMm: row.topPushMm,
    extraAreaMm: settings.extraAreaMm,
    autoSpacingPercent: row.lineSpacingPercent,
    orientation: settings.orientation == LabelPrintOrientation.vertical
        ? LabelSheetPrintOrientation.vertical
        : LabelSheetPrintOrientation.horizontal,
  );

  LabelSheetPrintOptions _scaleOutputPrintOptions(
    ScaleOutputRowDraft row,
    LabelPrintSettingsSnapshot settings,
  ) => LabelSheetPrintOptions(
    copies: 1,
    leftMarginMm: row.leftMarginMm,
    rightMarginMm: row.rightMarginMm,
    topMarginMm: row.topMarginMm,
    leftPushMm: row.leftPushMm,
    topPushMm: row.topPushMm,
    extraAreaMm: settings.extraAreaMm,
    autoSpacingPercent: row.lineSpacingPercent,
    orientation: settings.orientation == LabelPrintOrientation.vertical
        ? LabelSheetPrintOrientation.vertical
        : LabelSheetPrintOrientation.horizontal,
  );

  Widget _buildTabTrailing(BuildContext context) {
    final double fieldWidth = lmSize(isDesktop ? 260.0 : 200.0);
    final double fieldHeight = lmSize(37.0);
    final theme = Theme.of(context);
    final Color buttonColor = theme.colorScheme.secondaryFixed;
    final Color onButtonColor = theme.colorScheme.onSecondaryFixed;

    return SizedBox(
      height: fieldHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildItemPreviewButton(context),
          _buildCommonLabelPreviewButton(context),
          if (searchPrintInputVisible(
            active: widget.searchPrintModeActive,
            standardVisible: itemManagerSearchVisibleForTab(
              _selectedTabValue(),
            ),
          )) ...[
            Transform.translate(
              offset: const Offset(0, -1),
              child: SizedBox(
                width: fieldWidth,
                child: TextField(
                  key: const ValueKey('item-manager-search-field'),
                  controller: _tabSearchController,
                  style: const TextStyle(fontSize: 13),
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onTabSearch(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '검색어 입력',
                    contentPadding: lmInsetsSymmetric(
                      horizontal: 12,
                      vertical: isDesktop ? 8 : 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: lmSize(8)),
            Transform.translate(
              offset: const Offset(0, -1),
              child: SizedBox(
                height: fieldHeight - lmSize(10),
                child: FilledButton.icon(
                  key: const ValueKey('item-manager-search-button'),
                  onPressed: _onTabSearch,
                  icon: Icon(
                    widget.searchPrintModeActive ? Icons.print : Icons.search,
                    size: lmSize(14),
                    color: onButtonColor,
                  ),
                  label: Text(
                    searchPrintButtonLabel(widget.searchPrintModeActive),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onButtonColor,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: lmInsetsSymmetric(horizontal: 10),
                    minimumSize: Size(0, fieldHeight - lmSize(10)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCommonLabelPreviewButton(BuildContext context) {
    final selected = _selectedTabValue() == 'common_label';
    final window = _commonLabelPreviewWindow;
    final shouldShow =
        selected &&
        _commonLabelPreviewClosedByUser &&
        window != null &&
        !window.isVisible;
    final shouldKeepSlot = selected && window != null;
    final button = _PreviewRestoreButton(
      key: _commonLabelPreviewButtonKey,
      visible: shouldShow,
      tooltip: '공용라벨 미리보기 열기',
      onPressed: _restoreCommonLabelPreviewWindow,
    );
    if (!shouldKeepSlot) {
      return SizedBox(key: _commonLabelPreviewButtonKey, width: 0, height: 0);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        SizedBox(width: lmSize(8)),
      ],
    );
  }

  Widget _buildItemPreviewButton(BuildContext context) {
    final selectedTabValue = _selectedTabValue();
    final selected = _itemPreviewSupportedTab(selectedTabValue);
    final window = _itemPreviewWindow;
    final shouldShow = _itemPreviewRestoreButtonShouldShow(selectedTabValue);
    final shouldKeepSlot = selected && window != null;
    final button = _PreviewRestoreButton(
      key: _itemPreviewButtonKey,
      visible: shouldShow,
      tooltip: _itemPreviewRestoreTooltip(selectedTabValue),
      onPressed: _restoreItemPreviewWindow,
    );
    if (!shouldKeepSlot) {
      return SizedBox(key: _itemPreviewButtonKey, width: 0, height: 0);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        SizedBox(width: lmSize(8)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = _brands.isNotEmpty
        ? _brands
        : Brand.datas ?? const <Brand>[];
    final brandItems = _brandDropdownItems(brands);
    final resolvedBrand = _resolveSelectedBrand(brands, widget.selectedBrand);
    final labelSizes = LabelSize.datas ?? const <LabelSize>[];
    final labelItems = _labelSizeDropdownItems(labelSizes);
    final resolvedLabel = _resolveSelectedLabelSize(
      labelSizes,
      _effectiveLabelSize,
    );
    final canEdit = User.instance?.canEdit == true;
    final settingsEnabled = canEdit && _selectedTabValue() == 'common_label';
    final dateSettingsEnabled = _itemManagerDateSettingsEnabled(
      selectedTabValue: _selectedTabValue(),
      hasDateSetup: resolvedLabel?.labelSizeSetup != null,
      commandBusy: _itemDraftCommandBusy,
      draftDirty: _itemDraftController?.isDirty == true,
      canEdit: canEdit,
    );

    final tabbedView = TabbedViewTheme(
      data: _buildTabbedTheme(),
      child: TabbedView(
        controller: _tabController,
        tabReorderEnabled: false,
        trailing: _buildTabTrailing(context),
      ),
    );

    final result = Column(
      children: [
        Padding(
          padding: lmInsetsOnly(left: 12, right: 12, bottom: 8),
          child: Card(
            elevation: 2,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFE6E6E6)),
            ),
            child: _TopControlArea(
              onBrandChanged: _handleBrandChanged,
              onLabelSizeChanged: _handleHeaderLabelSizeChanged,
              onDropdownMenuStateChanged: _handleTopDropdownMenuStateChanged,
              dropdownChangeBlocked: _homeDataContextChangeBlocked,
              onBlockedDropdownTap: _blockHomeDataContextChange,
              showSettingsControls: canEdit,
              settingsEnabled: settingsEnabled,
              onBrandSettingsPressed: settingsEnabled
                  ? _openBrandSettingsDialog
                  : null,
              onLabelSettingsPressed: settingsEnabled
                  ? _openLabelSettingsDialog
                  : null,
              onDateSettingsPressed: dateSettingsEnabled
                  ? _openDateTypeSetupDialog
                  : null,
              brandItems: brandItems,
              resolvedBrand: resolvedBrand,
              labelItems: labelItems,
              resolvedLabel: resolvedLabel,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: lmInsetsOnly(left: 12, right: 12, bottom: 12),
            child: Card(
              elevation: 2,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE6E6E6)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(child: tabbedView),
                        if (_shouldBlockCurrentTabTap)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: lmSize(_blockedHomeTabTapOverlayHeight),
                            child: _PointerBarrierExceptGlobalKey(
                              passthroughKey:
                                  _itemPreviewRestoreButtonShouldShow(
                                    _selectedTabValue(),
                                  ) &&
                                      _selectedTabValue() == 'auto_update'
                                  ? _itemPreviewButtonKey
                                  : null,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _handleBlockedTabTap,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    Widget hostedResult = result;
    final itemPreviewWindow = _itemPreviewWindow;
    if (itemPreviewWindow != null) {
      hostedResult = itemPreviewWindow.wrapPortalHost(child: hostedResult);
    }
    final commonLabelPreviewWindow = _commonLabelPreviewWindow;
    if (commonLabelPreviewWindow != null) {
      hostedResult = commonLabelPreviewWindow.wrapPortalHost(
        child: hostedResult,
      );
    }
    return hostedResult;
  }

  bool _itemPreviewRestoreButtonShouldShow(Object? selectedTabValue) {
    final window = _itemPreviewWindow;
    return _itemPreviewSupportedTab(selectedTabValue) &&
        _itemPreviewClosedByUser &&
        window != null &&
        !window.isVisible;
  }

  AutoItemUpdateDraftRow? _selectedAutoItemUpdateRow() {
    final controller = _autoItemUpdateDraftController;
    final anchorRowKey = controller?.anchorRowKey;
    if (controller == null || anchorRowKey == null) {
      return null;
    }
    for (final row in controller.rows) {
      if (row.rowKey == anchorRowKey) {
        return row;
      }
    }
    return null;
  }

  ItemOfMarket _autoItemUpdatePreviewItem(
    AutoItemUpdateDraftRow row,
    LabelSize? labelSize,
  ) {
    final matched = ItemOfMarket.datas?.firstWhereOrNull(
      (item) => item.item.itemId == row.sourceItemId,
    );
    final previewItem = Item(
      itemId: row.sourceItemId,
      labelSizeId: labelSize?.labelSizeId ?? row.labelSizeId,
      itemName: row.itemName,
      labelSizeName:
          labelSize?.labelSizeName ?? matched?.item.labelSizeName ?? '',
      element: row.element,
      elementRTF: row.elementRtf,
      price: row.price,
      order: matched?.item.order ?? 0,
    );
    if (matched != null) {
      return matched.copyWith(item: previewItem);
    }
    final now = DateTime.now();
    return ItemOfMarket(
      marketId: row.currentMarketId,
      item: previewItem,
      additionalItem: AdditionalItem(
        AdditionalItemId: 0,
        itemId: row.sourceItemId,
        element: '',
        elementRTF: '',
        price: 0,
      ),
      gdsNo: 0,
      dateSaleStart: now,
      dateSaleEnd: now,
      discountPercent: 0,
      discountAmount: 0,
      dateStartDiscount: now,
      dateEndDiscount: now,
      useDefineElement: false,
      rtfText: '',
      useLinefeed: false,
      linefeed: 100,
      useScaleBarcode: false,
      printCount: 1,
      useLabelSize: false,
      labelSizeWidth: 0,
      labelSizeHeight: 0,
      useMargin: false,
      leftMargin: 0,
      rightMargin: 0,
      topMargin: 0,
      leftPush: 0,
      topPush: 0,
    );
  }

  Map<int, String> _autoItemUpdateProjectedColumnValues(
    AutoItemUpdateDraftRow row,
  ) {
    final controller = _autoItemUpdateDraftController;
    if (controller == null) {
      return const <int, String>{};
    }
    return {
      for (final column in TColumn.datas ?? const <TColumn>[])
        column.columnId: controller.columnValue(row, column.columnId),
    };
  }

  Future<void> _commitAutoItemUpdateElementDraft(
    String rowKey,
    String elementPlain,
    String elementPayload,
  ) async {
    if (User.instance?.canEdit != true || _autoItemUpdateCommandBusy) {
      throw StateError('자동품목갱신 편집 권한이 없습니다.');
    }
    final controller = _autoItemUpdateDraftController;
    if (controller == null) {
      throw StateError('자동품목갱신 draft가 없습니다.');
    }
    controller.updateElement(
      rowKey,
      element: elementPlain,
      elementRtf: elementPayload,
    );
  }
}

class _PreviewRestoreButton extends StatefulWidget {
  const _PreviewRestoreButton({
    super.key,
    required this.visible,
    required this.tooltip,
    required this.onPressed,
  });

  final bool visible;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_PreviewRestoreButton> createState() => _PreviewRestoreButtonState();
}

class _PreviewRestoreButtonState extends State<_PreviewRestoreButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _pressed
        ? const Color(0xFFDADCE0)
        : _hovered
        ? const Color(0xFFF1F3F4)
        : Colors.white;
    final foreground = _pressed
        ? const Color(0xFF202124)
        : _hovered
        ? const Color(0xFF3C4043)
        : const Color(0xFF3B4652);
    return Visibility(
      visible: widget.visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: Tooltip(
        key: ValueKey('preview-restore-tooltip:${widget.tooltip}'),
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: lmSize(28),
              height: lmSize(28),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _hovered
                      ? const Color(0xFF9AA0A6)
                      : const Color(0xFFCED4DA),
                ),
                boxShadow: _hovered
                    ? const [
                        BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(Icons.preview, size: lmSize(17), color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

class _PointerBarrierExceptGlobalKey extends SingleChildRenderObjectWidget {
  const _PointerBarrierExceptGlobalKey({
    required this.passthroughKey,
    required super.child,
  });

  final GlobalKey? passthroughKey;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPointerBarrierExceptGlobalKey(passthroughKey);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPointerBarrierExceptGlobalKey renderObject,
  ) {
    renderObject.passthroughKey = passthroughKey;
  }
}

class _RenderPointerBarrierExceptGlobalKey extends RenderProxyBox {
  _RenderPointerBarrierExceptGlobalKey(this.passthroughKey);

  GlobalKey? passthroughKey;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final passthroughRenderObject = passthroughKey
        ?.currentContext
        ?.findRenderObject();
    if (passthroughRenderObject is RenderBox &&
        passthroughRenderObject.attached) {
      final passthroughRect =
          passthroughRenderObject.localToGlobal(Offset.zero) &
          passthroughRenderObject.size;
      if (passthroughRect.contains(localToGlobal(position))) {
        return false;
      }
    }
    return super.hitTest(result, position: position);
  }
}

bool _itemPreviewSupportedTab(Object? tabValue) =>
  tabValue == 'items' || tabValue == 'auto_update';

String _itemPreviewRestoreTooltip(Object? tabValue) =>
  tabValue == 'auto_update' ? '자동품목갱신 미리보기 열기' : '품목관리 미리보기 열기';

@visibleForTesting
bool debugItemPreviewSupportedTabForTesting(Object? tabValue) =>
  _itemPreviewSupportedTab(tabValue);

@visibleForTesting
String debugItemPreviewRestoreTooltipForTesting(Object? tabValue) =>
  _itemPreviewRestoreTooltip(tabValue);

@visibleForTesting
Widget debugPreviewRestoreButtonForTesting({
  required String tooltip,
  bool visible = true,
  VoidCallback? onPressed,
}) => _PreviewRestoreButton(
  visible: visible,
  tooltip: tooltip,
  onPressed: onPressed ?? () {},
);

@visibleForTesting
Widget debugPointerBarrierExceptForTesting({
  required GlobalKey passthroughKey,
  required Widget child,
}) => _PointerBarrierExceptGlobalKey(
  passthroughKey: passthroughKey,
  child: child,
);

class _TopControlArea extends StatelessWidget {
  final ValueChanged<Brand?> onBrandChanged;
  final ValueChanged<LabelSize?> onLabelSizeChanged;
  final ValueChanged<bool> onDropdownMenuStateChanged;
  final bool dropdownChangeBlocked;
  final VoidCallback onBlockedDropdownTap;
  final bool showSettingsControls;
  final bool settingsEnabled;
  final VoidCallback? onBrandSettingsPressed;
  final VoidCallback? onLabelSettingsPressed;
  final VoidCallback? onDateSettingsPressed;
  final List<DropdownMenuItem<Brand>> brandItems;
  final Brand? resolvedBrand;
  final List<DropdownMenuItem<LabelSize>> labelItems;
  final LabelSize? resolvedLabel;

  const _TopControlArea({
    required this.onBrandChanged,
    required this.onLabelSizeChanged,
    required this.onDropdownMenuStateChanged,
    required this.dropdownChangeBlocked,
    required this.onBlockedDropdownTap,
    required this.showSettingsControls,
    required this.settingsEnabled,
    required this.onBrandSettingsPressed,
    required this.onLabelSettingsPressed,
    required this.onDateSettingsPressed,
    required this.brandItems,
    required this.resolvedBrand,
    required this.labelItems,
    required this.resolvedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final labelMenuEnabled =
        onLabelSettingsPressed != null || onDateSettingsPressed != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Colors.transparent,
          padding: lmInsetsAll(8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: lmSize(isDesktop ? 250 : 200),
                      child: Container(
                        padding: lmInsetsSymmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCED4DA)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${Customer.instance?.customerName ?? ''} (${User.instance?.userId ?? ''})',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: lmSize(12)),
                    Row(
                      children: [
                        _DropdownField<Brand>(
                          label: '브랜드',
                          value: resolvedBrand,
                          items: brandItems,
                          onChanged: brandItems.isEmpty ? null : onBrandChanged,
                          onMenuStateChange: onDropdownMenuStateChanged,
                          blocked: dropdownChangeBlocked,
                          onBlockedTap: onBlockedDropdownTap,
                          width: isDesktop ? 220 : 150,
                          labelWidth: 48,
                        ),
                        if (showSettingsControls) ...[
                          SizedBox(width: lmSize(6)),
                          SizedBox(
                            height: lmSize(36),
                            child: OutlinedButton(
                              key: const ValueKey('brand-settings-button'),
                              onPressed: onBrandSettingsPressed,
                              style: OutlinedButton.styleFrom(
                                minimumSize: lmSize2(60, 36),
                                padding: lmInsetsSymmetric(horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                '설정',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(width: lmSize(10)),
                        _DropdownField<LabelSize>(
                          label: '라벨',
                          value: resolvedLabel,
                          items: labelItems,
                          onChanged: labelItems.isEmpty
                              ? null
                              : onLabelSizeChanged,
                          onMenuStateChange: onDropdownMenuStateChanged,
                          blocked: dropdownChangeBlocked,
                          onBlockedTap: onBlockedDropdownTap,
                          width: isDesktop ? 220 : 150,
                          labelWidth: 48,
                        ),
                        if (showSettingsControls) ...[
                          SizedBox(width: lmSize(6)),
                          SizedBox(
                            height: lmSize(36),
                            child: PopupMenuButton<String>(
                              enabled: labelMenuEnabled,
                              tooltip: '라벨 설정',
                              onSelected: (value) {
                                if (value == 'label') {
                                  onLabelSettingsPressed?.call();
                                } else if (value == 'date') {
                                  onDateSettingsPressed?.call();
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'label',
                                  enabled: onLabelSettingsPressed != null,
                                  child: const Text('라벨 설정...'),
                                ),
                                PopupMenuItem(
                                  value: 'date',
                                  enabled: onDateSettingsPressed != null,
                                  child: const Text('날짜 타입 설정...'),
                                ),
                              ],
                              child: IgnorePointer(
                                child: OutlinedButton.icon(
                                  onPressed: labelMenuEnabled ? () {} : null,
                                  icon: const Icon(Icons.settings, size: 16),
                                  label: const Text(
                                    '설정',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: lmSize2(72, 36),
                                    padding: lmInsetsSymmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: lmSize(isDesktop ? 450 : 370),
                      ),
                      child: Container(
                        width: lmSize(isDesktop ? 430 : 350),
                        height: lmSize(36),
                        padding: lmInsetsSymmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context).cardColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: isShowLogo
                            ? Image.asset(
                                'assets/images/LogoPhone.webp',
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<bool>? onMenuStateChange;
  final bool blocked;
  final VoidCallback? onBlockedTap;
  final bool useRootNavigator;
  final double width;
  final double labelWidth;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.onMenuStateChange,
    this.blocked = false,
    this.onBlockedTap,
    this.useRootNavigator = true,
    this.width = 170,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null && items.isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: lmSize(labelWidth),
          child: Text(
            '$label:',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        SizedBox(width: lmSize(6)),
        SizedBox(
          width: lmSize(width),
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: blocked,
                child: DropdownButtonFormField2<T>(
                  value: value,
                  items: items,
                  onChanged: enabled ? onChanged : null,
                  onMenuStateChange: onMenuStateChange,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  isExpanded: true,
                  buttonStyleData: ButtonStyleData(
                    height: lmSize(28),
                    padding: lmInsetsSymmetric(horizontal: 2),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    useRootNavigator: useRootNavigator,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  menuItemStyleData: MenuItemStyleData(height: lmSize(28)),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: enabled ? Colors.white : const Color(0xFFE9ECEF),
                    contentPadding: lmInsetsSymmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFFCED4DA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
              ),
              if (blocked)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBlockedTap,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelessDropdownField<T> extends StatefulWidget {
  const _ModelessDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.debugLabel,
    this.menuBoundaryKey,
    this.onChanged,
    this.width = 170,
    this.labelWidth = 80,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String debugLabel;
  final GlobalKey? menuBoundaryKey;
  final double width;
  final double labelWidth;

  @override
  State<_ModelessDropdownField<T>> createState() =>
      _ModelessDropdownFieldState<T>();
}

class _ModelessDropdownFieldState<T> extends State<_ModelessDropdownField<T>> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _menuEntry;

  bool get _enabled => widget.onChanged != null && widget.items.isNotEmpty;

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) {
        return item;
      }
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant _ModelessDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _removeMenu('disabledByUpdate');
    }
  }

  @override
  void dispose() {
    _removeMenu('dispose', rebuild: false);
    super.dispose();
  }

  void _toggleMenu() {
    if (!_enabled) {
      debugLog(
        '${widget.debugLabel} open blocked enabled=$_enabled items=${widget.items.length}',
      );
      return;
    }
    if (_menuEntry != null) {
      _removeMenu('toggleClose');
      return;
    }
    _showMenu();
  }

  void _showMenu() {
    final buttonContext = _buttonKey.currentContext;
    if (buttonContext == null) {
      debugLog('${widget.debugLabel} open blocked missingButtonContext');
      return;
    }
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) {
      debugLog(
        '${widget.debugLabel} open blocked renderObject=${renderObject.runtimeType}',
      );
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final buttonTopLeft = renderObject.localToGlobal(Offset.zero);
    final buttonRect = buttonTopLeft & renderObject.size;
    final screenSize = MediaQuery.sizeOf(context);
    final itemHeight = lmSize(28);
    final desiredMenuHeight = itemHeight * widget.items.length;
    final belowTop = buttonRect.bottom + lmSize(2);
    final boundaryRect = _resolveMenuBoundaryRect(screenSize);
    final availableBelow = max(0.0, boundaryRect.bottom - belowTop);
    final availableAbove = max(
      0.0,
      buttonRect.top - boundaryRect.top - lmSize(2),
    );
    final useBelow =
        availableBelow >= desiredMenuHeight || availableBelow >= availableAbove;
    final availableHeight = useBelow ? availableBelow : availableAbove;
    final menuHeight = max(itemHeight, min(desiredMenuHeight, availableHeight));
    final menuTop = useBelow
        ? belowTop
        : max(boundaryRect.top, buttonRect.top - menuHeight - lmSize(2));
    final maxMenuLeft = max(0.0, screenSize.width - buttonRect.width);
    final menuLeft = min(max(buttonRect.left, 0.0), maxMenuLeft);

    debugLog(
      '${widget.debugLabel} open items=${widget.items.length} '
      'value=${widget.value} rect=$buttonRect boundary=$boundaryRect '
      'desiredHeight=$desiredMenuHeight menuHeight=$menuHeight '
      'below=$availableBelow above=$availableAbove top=$menuTop left=$menuLeft',
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _removeMenu('outsideTap'),
            ),
          ),
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: buttonRect.width,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(4),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: menuHeight),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    final selected = item.value == widget.value;
                    return InkWell(
                      onTap: item.enabled
                          ? () {
                              debugLog(
                                '${widget.debugLabel} select index=$index value=${item.value}',
                              );
                              _removeMenu('select');
                              widget.onChanged?.call(item.value);
                            }
                          : null,
                      child: Container(
                        height: itemHeight,
                        color: selected
                            ? const Color(0xFFE8F0FE)
                            : Colors.transparent,
                        padding: lmInsetsSymmetric(horizontal: 10),
                        alignment: Alignment.centerLeft,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          child: item.child,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    _menuEntry = entry;
    overlay.insert(entry);
    if (mounted) {
      setState(() {});
    }
  }

  Rect _resolveMenuBoundaryRect(Size screenSize) {
    final boundaryContext = widget.menuBoundaryKey?.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      return topLeft & renderObject.size;
    }
    return Offset.zero & screenSize;
  }

  void _removeMenu(String reason, {bool rebuild = true}) {
    final entry = _menuEntry;
    if (entry == null) return;
    debugLog(
      '${widget.debugLabel} close reason=$reason mounted=${entry.mounted}',
    );
    _menuEntry = null;
    if (entry.mounted) {
      entry.remove();
    }
    if (mounted && rebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedItem;
    final borderColor = _menuEntry != null
        ? const Color(0xFF3B82F6)
        : const Color(0xFFCED4DA);
    final textOpacity = _enabled ? 1.0 : 0.55;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: lmSize(widget.labelWidth),
          child: Text(
            '${widget.label}:',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        SizedBox(width: lmSize(6)),
        SizedBox(
          width: lmSize(widget.width),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: _buttonKey,
              onTap: _enabled ? _toggleMenu : null,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: lmSize(28),
                padding: lmInsetsSymmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _enabled ? Colors.white : const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: textOpacity,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          child: selectedItem?.child ?? const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Icon(
                      _menuEntry != null
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: _enabled
                          ? const Color(0xFF5F6368)
                          : const Color(0xFF9AA0A6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemPreviewPanel extends StatefulWidget {
  const _ItemPreviewPanel({
    super.key,
    required this.item,
    required this.rowIdentity,
    required this.onElementCommitted,
    required this.canSelectOutputPreview,
    this.labelSize,
    this.referenceAt,
    this.projectedColumnValues,
    this.elementPreviewZoomController,
    this.outputPreviewZoomController,
    this.canEdit = true,
  });

  final ItemOfMarket item;
  final String rowIdentity;
  final LabelSize? labelSize;
  final DateTime? referenceAt;
  final Map<int, String>? projectedColumnValues;
  final LabelSheetZoomController? elementPreviewZoomController;
  final LabelSheetZoomController? outputPreviewZoomController;
  final Future<void> Function(
    String rowIdentity,
    String elementPlain,
    String elementPayload,
  )
  onElementCommitted;
  final bool Function() canSelectOutputPreview;
  final bool canEdit;

  @override
  State<_ItemPreviewPanel> createState() => _ItemPreviewPanelState();
}

class _ItemPreviewPanelState extends State<_ItemPreviewPanel> {
  late _ItemElementFormState _elementForm = _itemElementFormStateFor(
    widget.item,
    widget.labelSize,
  );
  late String _elementText = _elementForm.text;
  int _elementRtfConversionGeneration = 0;
    late final bool _ownsElementPreviewZoomController =
      widget.elementPreviewZoomController == null;
    late final LabelSheetZoomController _elementPreviewZoomController =
      widget.elementPreviewZoomController ?? LabelSheetZoomController();
    late final bool _ownsOutputPreviewZoomController =
      widget.outputPreviewZoomController == null;
    late final LabelSheetZoomController _outputPreviewZoomController =
      widget.outputPreviewZoomController ?? LabelSheetZoomController();
  late final TabbedViewController _controller = TabbedViewController(
    _buildTabs(),
    onTabSelection: _handleTabSelection,
  );

  void _handleTabSelection(int? index, TabData? tab) {
    if (tab?.value != 'item_output_preview' ||
        widget.canSelectOutputPreview()) {
      return;
    }
    _controller.selectTabByValue('item_element');
  }

  @override
  void initState() {
    super.initState();
    _startElementRtfConversionIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ItemPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemChanged = oldWidget.rowIdentity != widget.rowIdentity;
    final labelSizeChanged =
        oldWidget.labelSize?.labelSizeId != widget.labelSize?.labelSizeId;
    if (itemChanged || labelSizeChanged) {
      _elementForm = _itemElementFormStateFor(widget.item, widget.labelSize);
      _elementText = _elementForm.text;
    }
    _replaceTabsPreservingSelection();
    if (itemChanged || labelSizeChanged) {
      _startElementRtfConversionIfNeeded();
    }
  }

  void _startElementRtfConversionIfNeeded() {
    final payload = widget.item.item.elementRTF.trim();
    final generation = ++_elementRtfConversionGeneration;
    if (!labelSheetLooksLikeRichEditRtf(payload)) {
      return;
    }
    if (labelSheetTryDecodeWorkbookSave(payload) != null) {
      return;
    }
    unawaited(
      _itemElementWorkbookFromRichEditRtfAsync(payload, widget.labelSize)
          .then((workbook) {
            if (!mounted || generation != _elementRtfConversionGeneration) {
              return;
            }
            if (workbook == null) {
              return;
            }
            setState(() {
              _elementForm = _itemElementFormStateFromWorkbook(
                workbook,
                sourceHash: payload.hashCode,
                convertedFromRtf: true,
              );
              _elementText = _elementForm.text;
            });
            _replaceTabsPreservingSelection();
          })
          .catchError((Object error, StackTrace stackTrace) {
            debugLog(
              'item element RTF async conversion failed itemId=${widget.item.item.itemId}, error=$error\n$stackTrace',
            );
          }),
    );
  }

  @override
  void dispose() {
    _elementRtfConversionGeneration += 1;
    _controller.dispose();
    if (_ownsElementPreviewZoomController) {
      _elementPreviewZoomController.dispose();
    }
    if (_ownsOutputPreviewZoomController) {
      _outputPreviewZoomController.dispose();
    }
    super.dispose();
  }

  void _handleElementWorkbookChanged(fs.FortuneWorkbook workbook) {
    if (!widget.canEdit) return;
    if (_itemElementWorkbookContentEquals(_elementForm.workbook, workbook)) {
      return;
    }
    final next = _itemElementTextFromWorkbook(workbook);
    final encodedWorkbook = labelSheetEncodeWorkbookSave(workbook);
    if (next == _elementText &&
        encodedWorkbook == _elementForm.encodedWorkbook) {
      return;
    }
    setState(() {
      _elementText = next;
      _elementForm = _elementForm.copyWith(
        workbook: workbook,
        encodedWorkbook: encodedWorkbook,
        text: next,
        convertedFromRtf: false,
      );
    });
    _updateOutputPreviewTabContent();
    unawaited(
      widget
          .onElementCommitted(widget.rowIdentity, next, encodedWorkbook)
          .catchError((Object error, StackTrace stackTrace) {
            debugLog(
              'item element draft auto commit failed '
              'rowIdentity=${widget.rowIdentity}, error=$error\n$stackTrace',
            );
          }),
    );
  }

  Future<void> _handleElementSheetSave(
    BuildContext context,
    int width,
    int height,
    String encodedWorkbook,
  ) async {
    debugLog(START);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('주원료 및 함량을 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      debugLog(
        'saveItemElementSheet cancelledByUser itemId=${widget.item.item.itemId} keepEditing',
      );
      return;
    }

    final workbook = labelSheetTryDecodeWorkbookSave(encodedWorkbook);
    final elementText = workbook == null
        ? _elementText
        : _itemElementTextFromWorkbook(workbook);

    try {
      await widget.onElementCommitted(
        widget.rowIdentity,
        elementText,
        encodedWorkbook,
      );
      if (mounted && workbook != null) {
        setState(() {
          _elementText = elementText;
          _elementForm = _elementForm.copyWith(
            workbook: workbook,
            encodedWorkbook: encodedWorkbook,
            text: elementText,
            convertedFromRtf: false,
          );
        });
        _updateOutputPreviewTabContent();
      }
      debugLog(
        '$END - item element draft committed rowItemId=${widget.item.item.itemId}',
      );
    } catch (e) {
      debugLog('$END - item element draft commit failed, error=$e');
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
          builder: (dialogContext) => AlertDialog(
            title: const Text('주원료 및 함량 저장 실패'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      rethrow;
    }
  }

  void _replaceTabsPreservingSelection() {
    final selectedValue = _controller.selectedTab?.value;
    _controller.setTabs(_buildTabs());
    if (selectedValue != null) {
      _controller.selectTabByValue(selectedValue);
    }
  }

  void _updateOutputPreviewTabContent() {
    final tab = _controller.getTabByValue('item_output_preview');
    if (tab == null) return;
    tab.content = _buildItemOutputPreviewTab();
  }

  List<TabData> _buildTabs() {
    final columns = TColumn.datas ?? const <TColumn>[];
    final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
    final imageObjectIds = _itemPreviewImageObjectIdsFor([
      ...specialColumns,
      ...columns,
    ]);
    final barcodeObjectIds = _itemPreviewBarcodeObjectIdsFor([
      ...specialColumns,
      ...columns,
    ]);
    return [
      TabData(
        value: 'item_element',
        text: '주원료 및 함량',
        content: _ItemElementPreviewTab(
          item: widget.item,
          labelSize: widget.labelSize,
          elementForm: _elementForm,
          zoomController: _elementPreviewZoomController,
          canEdit: widget.canEdit,
          onWorkbookChanged: _handleElementWorkbookChanged,
          onSave: _handleElementSheetSave,
        ),
        closable: false,
        keepAlive: true,
      ),
      TabData(
        value: 'item_output_preview',
        text: '출력내용 미리보기',
        content: _buildItemOutputPreviewTab(
          imageObjectIds: imageObjectIds,
          barcodeObjectIds: barcodeObjectIds,
        ),
        closable: false,
        keepAlive: true,
      ),
    ];
  }

  _ItemOutputPreviewTab _buildItemOutputPreviewTab({
    List<String>? imageObjectIds,
    List<String>? barcodeObjectIds,
  }) {
    final columns = TColumn.datas ?? const <TColumn>[];
    final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
    final resolvedImageObjectIds =
        imageObjectIds ??
        _itemPreviewImageObjectIdsFor([...specialColumns, ...columns]);
    final resolvedBarcodeObjectIds =
        barcodeObjectIds ??
        _itemPreviewBarcodeObjectIdsFor([...specialColumns, ...columns]);
    return _ItemOutputPreviewTab(
      key: ValueKey(
        'item-output-tab:${widget.item.item.itemId}:${_elementForm.encodedWorkbook.hashCode}',
      ),
      item: widget.item,
      labelSize: widget.labelSize,
      elementText: _elementText,
      elementWorkbook: _elementForm.workbook,
      referenceAt: widget.referenceAt,
      projectedColumnValues: widget.projectedColumnValues,
      imageObjectIds: resolvedImageObjectIds,
      barcodeObjectIds: resolvedBarcodeObjectIds,
      zoomController: _outputPreviewZoomController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabbedViewTheme(
        data: _itemPreviewTabbedTheme(),
        child: TabbedView(controller: _controller, tabReorderEnabled: false),
      ),
    );
  }
}

TabbedViewThemeData _itemPreviewTabbedTheme() {
  final theme = TabbedViewThemeData.minimalist(
    brightness: Brightness.light,
    colorSet: Colors.grey,
    fontSize: 14,
    tabRadius: 3,
  );

  theme.tabsArea
    ..color = const Color(0xFFF7F8FA)
    ..border = const BorderSide(color: Color(0xFFE6E6E6))
    ..initialGap = 0
    ..middleGap = 4
    ..buttonsGap = 0
    ..buttonColor = Colors.transparent
    ..hoveredButtonColor = Colors.transparent
    ..disabledButtonColor = Colors.transparent;

  theme.tab
    ..padding = const EdgeInsets.fromLTRB(18, 9.5, 18, 9.5)
    ..paddingWithoutButton = const EdgeInsets.fromLTRB(18, 9.5, 18, 9.5)
    ..textStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF1F2429),
    )
    ..buttonsGap = 0
    ..buttonColor = Colors.transparent
    ..hoveredButtonColor = Colors.transparent
    ..disabledButtonColor = Colors.transparent
    ..buttonPadding = EdgeInsets.zero;

  theme.contentArea
    ..color = Colors.white
    ..padding = EdgeInsets.zero;

  theme.divider = const BorderSide(color: Color(0xFFE6E6E6));
  theme.isDividerWithinTabArea = true;

  return theme;
}

class _ItemElementPreviewTab extends StatelessWidget {
  const _ItemElementPreviewTab({
    required this.item,
    required this.labelSize,
    required this.elementForm,
    required this.zoomController,
    required this.canEdit,
    required this.onWorkbookChanged,
    required this.onSave,
  });

  final ItemOfMarket item;
  final LabelSize? labelSize;
  final _ItemElementFormState elementForm;
  final LabelSheetZoomController zoomController;
  final bool canEdit;
  final ValueChanged<fs.FortuneWorkbook> onWorkbookChanged;
  final Future<void> Function(
    BuildContext context,
    int width,
    int height,
    String encodedWorkbook,
  )
  onSave;

  @override
  Widget build(BuildContext context) {
    final workbook = canEdit
        ? elementForm.workbook
        : elementForm.workbook.copyWith(
            sheets: [
              for (final sheet in elementForm.workbook.sheets)
                sheet.copyWith(authority: const <String, Object?>{'sheet': 1}),
            ],
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          zoomController.applyInitialAutoFit(
            labelOutputPreviewFitWidthZoomPercent(
              viewportWidth: constraints.maxWidth,
              sheet: workbook.activeSheet,
              fallbackLabelWidthMm: labelSize?.labelSizeCommon?.width.toDouble(),
            ),
          );
        }
        return LabelSheetWorkbench(
          key: ValueKey(
            'item-element:${labelSize?.labelSizeId ?? 'none'}:${item.item.itemId}:${elementForm.sourceHash}',
          ),
          initialWorkbook: workbook,
          labelSize: labelSize,
          initialDirty: canEdit && elementForm.convertedFromRtf,
          toolbarItems: canEdit ? _itemElementToolbarItems : const <String>[],
          hideToolbar: !canEdit,
          hideRowColumnHeaderLabels: true,
          hideSelectionHighlight: true,
          rulerCornerSizeLabelUsesAsterisk: true,
          disableSheetRulerGuideInteraction: true,
          hideStatisticBar: true,
          limitCellActionsToClipboardAndClear: true,
          canEditObjects: canEdit,
          showObjectPanelOpenButton: false,
          zoomToolbarPlacement:
              LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
          zoomController: zoomController,
          onUserWorkbookChanged: canEdit ? onWorkbookChanged : null,
          onUserWorkbookChangedShouldNotify: canEdit
              ? (previous, current) =>
                    !_itemElementWorkbookContentEquals(previous, current)
              : null,
          onSave: canEdit
              ? (width, height, encodedWorkbook) => onSave(
                  context,
                  width,
                  height,
                  encodedWorkbook,
                ).then((_) => LabelSheetSaveResult.applied)
              : null,
        );
      },
    );
  }
}

const List<String> _itemElementToolbarItems = [
  fs.fortuneToolbarFontPopupKey,
  fs.fortuneToolbarFontSizePopupKey,
  fs.fortuneToolbarBoldCommand,
  fs.fortuneToolbarItalicCommand,
  fs.fortuneToolbarStrikeThroughCommand,
  fs.fortuneToolbarUnderlineCommand,
  fs.fortuneToolbarFontColorPopupKey,
  fs.fortuneToolbarBackgroundPopupKey,
  fs.fortuneToolbarHorizontalAlignPopupKey,
  fs.fortuneToolbarVerticalAlignPopupKey,
  fs.fortuneToolbarTextWrapPopupKey,
  fs.fortuneToolbarTextRotationPopupKey,
];

const Set<String> _itemElementViewStateKeys = {
  'm',
  'status',
  'luckysheet_select_save',
  'luckysheet_selection_range',
  'visibledatarow',
  'visibledatacolumn',
};

bool _itemElementWorkbookContentEquals(
  fs.FortuneWorkbook previous,
  fs.FortuneWorkbook current,
) {
  final previousJson = labelSheetSanitizeWorkbookSaveJson(
    fs.FortuneSheetCodec.workbookToJson(previous),
  );
  final currentJson = labelSheetSanitizeWorkbookSaveJson(
    fs.FortuneSheetCodec.workbookToJson(current),
  );
  _removeItemElementViewState(previousJson);
  _removeItemElementViewState(currentJson);
  return const DeepCollectionEquality().equals(previousJson, currentJson);
}

void _removeItemElementViewState(Object? value) {
  if (value is Map) {
    for (final key in _itemElementViewStateKeys) {
      value.remove(key);
    }
    for (final child in value.values) {
      _removeItemElementViewState(child);
    }
  } else if (value is List) {
    for (final child in value) {
      _removeItemElementViewState(child);
    }
  }
}

bool _itemManagerDateSettingsEnabled({
  required Object? selectedTabValue,
  required bool hasDateSetup,
  required bool commandBusy,
  required bool draftDirty,
  required bool canEdit,
}) =>
    canEdit &&
    selectedTabValue == 'items' &&
    hasDateSetup &&
    !commandBusy &&
    !draftDirty;

List<String> _itemPreviewImageObjectIdsFor(Iterable<TColumnBase> columns) {
  return commonLabelImageObjectIdsFromColumns(columns);
}

List<String> _itemPreviewBarcodeObjectIdsFor(Iterable<TColumnBase> columns) {
  return commonLabelBarcodeObjectIdsFromColumns(columns);
}

class _ItemOutputPreviewTab extends StatelessWidget {
  const _ItemOutputPreviewTab({
    super.key,
    required this.item,
    required this.elementText,
    required this.elementWorkbook,
    required this.imageObjectIds,
    required this.barcodeObjectIds,
    this.labelSize,
    this.outputCaptureController,
    this.referenceAt,
    this.projectedColumnValues,
    this.zoomToolbarPlacement =
        LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
    this.zoomController,
  });

  final ItemOfMarket item;
  final String elementText;
  final fs.FortuneWorkbook elementWorkbook;
  final LabelSize? labelSize;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final LabelSheetOutputCaptureController? outputCaptureController;
  final DateTime? referenceAt;
  final Map<int, String>? projectedColumnValues;
  final LabelSheetZoomToolbarPlacement zoomToolbarPlacement;
  final LabelSheetZoomController? zoomController;

  @override
  Widget build(BuildContext context) {
    final previewAt = referenceAt ?? DateTime.now();
    final preview = _itemOutputPreview(
      labelSize: labelSize,
      item: item,
      elementText: elementText,
      elementWorkbook: elementWorkbook,
      referenceAt: previewAt,
      projectedColumnValues: projectedColumnValues,
    );
    return LabelOutputPreview(
      workbook: preview.workbook,
      hintText: preview.hintText,
      identityKey:
          'item-output:${labelSize?.labelSizeId ?? 'none'}:${item.item.itemId}:'
          '${itemOutputPreviewWorkbookFingerprint(preview.workbook)}',
      labelSize: labelSize,
      imageObjectIds: imageObjectIds,
      barcodeObjectIds: barcodeObjectIds,
      outputCaptureController: outputCaptureController,
      zoomToolbarPlacement: zoomToolbarPlacement,
      zoomController: zoomController,
      autoFitWidth: true,
    );
  }
}

@visibleForTesting
int itemOutputPreviewWorkbookFingerprint(fs.FortuneWorkbook? workbook) {
  if (workbook == null) return 0;
  final json = labelSheetSanitizeWorkbookSaveJson(
    fs.FortuneSheetCodec.workbookToJson(workbook),
  );
  return jsonEncode(json).hashCode;
}

@visibleForTesting
Widget debugItemPreviewPanelForTesting({
  required ItemOfMarket item,
  LabelSize? labelSize,
  String? rowIdentity,
  DateTime? referenceAt,
  Map<int, String>? projectedColumnValues,
  LabelSheetZoomController? elementPreviewZoomController,
  LabelSheetZoomController? outputPreviewZoomController,
  Future<void> Function(
    String rowIdentity,
    String elementPlain,
    String elementPayload,
  )?
  onElementCommitted,
  bool Function()? canSelectOutputPreview,
  bool canEdit = true,
}) => _ItemPreviewPanel(
  item: item,
  rowIdentity: rowIdentity ?? 'item:${item.item.itemId}',
  labelSize: labelSize,
  referenceAt: referenceAt,
  projectedColumnValues: projectedColumnValues,
  elementPreviewZoomController: elementPreviewZoomController,
  outputPreviewZoomController: outputPreviewZoomController,
  onElementCommitted: onElementCommitted ?? (_, _, _) async {},
  canSelectOutputPreview: canSelectOutputPreview ?? () => true,
  canEdit: canEdit,
);

@visibleForTesting
Widget debugTopControlAreaForTesting({
  VoidCallback? onLabelSettingsPressed,
  VoidCallback? onDateSettingsPressed,
  List<Brand> brands = const [],
  Brand? selectedBrand,
  ValueChanged<Brand?>? onBrandChanged,
  List<LabelSize> labelSizes = const [],
  LabelSize? selectedLabelSize,
  ValueChanged<LabelSize?>? onLabelSizeChanged,
  bool dropdownChangeBlocked = false,
  bool showSettingsControls = true,
  VoidCallback? onBlockedDropdownTap,
}) => Material(
  child: SizedBox(
    width: 1400,
    child: _TopControlArea(
      onBrandChanged: onBrandChanged ?? (_) {},
      onLabelSizeChanged: onLabelSizeChanged ?? (_) {},
      onDropdownMenuStateChanged: (_) {},
      dropdownChangeBlocked: dropdownChangeBlocked,
      onBlockedDropdownTap: onBlockedDropdownTap ?? () {},
      showSettingsControls: showSettingsControls,
      settingsEnabled: false,
      onBrandSettingsPressed: null,
      onLabelSettingsPressed: onLabelSettingsPressed,
      onDateSettingsPressed: onDateSettingsPressed,
      brandItems: [
        for (final brand in brands)
          DropdownMenuItem(value: brand, child: Text(brand.brandName)),
      ],
      resolvedBrand: selectedBrand,
      labelItems: [
        for (final labelSize in labelSizes)
          DropdownMenuItem(
            value: labelSize,
            child: Text(labelSize.labelSizeName),
          ),
      ],
      resolvedLabel: selectedLabelSize,
    ),
  ),
);

@visibleForTesting
bool debugItemManagerDateSettingsEnabledForTesting({
  required Object? selectedTabValue,
  bool hasDateSetup = true,
  bool commandBusy = false,
  bool draftDirty = false,
  bool canEdit = true,
}) => _itemManagerDateSettingsEnabled(
  selectedTabValue: selectedTabValue,
  hasDateSetup: hasDateSetup,
  commandBusy: commandBusy,
  draftDirty: draftDirty,
  canEdit: canEdit,
);

@visibleForTesting
bool debugItemElementWorkbookContentEqualsForTesting(
  fs.FortuneWorkbook previous,
  fs.FortuneWorkbook current,
) => _itemElementWorkbookContentEquals(previous, current);

@visibleForTesting
({fs.FortuneWorkbook? workbook, String? hintText})
debugItemOutputPreviewForTesting({
  required LabelSize? labelSize,
  required ItemOfMarket item,
  required String elementText,
  fs.FortuneWorkbook? elementWorkbook,
  DateTime? referenceAt,
  Map<int, String>? projectedColumnValues,
}) => _itemOutputPreview(
  labelSize: labelSize,
  item: item,
  elementText: elementText,
  elementWorkbook: elementWorkbook,
  referenceAt: referenceAt ?? DateTime.now(),
  projectedColumnValues: projectedColumnValues,
);

@visibleForTesting
List<({String text, bool error})> debugItemCodePreviewMessagesForTesting(
  fs.FortuneWorkbook workbook,
) => labelOutputPreviewMessages(workbook);

@visibleForTesting
String debugItemCodeErrorPlaceholderForTesting() =>
    _itemCodeErrorPlaceholderDataUri();

@visibleForTesting
fs.FortuneWorkbook debugMaterializeItemImagesForTesting(
  fs.FortuneWorkbook workbook,
  Map<String, String> replacements,
  {fs.FortuneCell? elementCell}
) => workbook.copyWith(
  sheets: [
    for (final sheet in workbook.sheets)
      _replaceSheetKeywords(
        sheet,
        replacements,
        elementCell: elementCell,
        imageKeywords: const <String>{},
      ),
  ],
);

({fs.FortuneWorkbook? workbook, String? hintText}) _itemOutputPreview({
  required LabelSize? labelSize,
  required ItemOfMarket item,
  required String elementText,
  fs.FortuneWorkbook? elementWorkbook,
  required DateTime referenceAt,
  Map<int, String>? projectedColumnValues,
}) {
  final encodedWorkbook = labelSize?.labelSizeCommon?.rtf;
  if (labelSheetLooksLikeRichEditRtf(encodedWorkbook)) {
    return (workbook: null, hintText: '* 라벨을 편집 저장 후 가능합니다.');
  }
  if (encodedWorkbook != null && encodedWorkbook.trim().isNotEmpty) {
    final workbook = labelSheetTryDecodeWorkbookSave(encodedWorkbook);
    if (workbook == null) {
      return (workbook: null, hintText: '* 저장된 라벨에 문제가 있습니다.');
    }
    final columns = [
      for (final column in TColumn.datas ?? const <TColumn>[])
        ItemCodeColumnSpec.fromColumn(column),
    ];
    String columnValue(int columnId) =>
        projectedColumnValues?[columnId] ??
        TColumnContent.get(columnId, item.item.itemId)?.dataString ??
        '';
    return (
      workbook: _replaceItemPreviewKeywords(
        _itemOutputPreviewPrivateWorkbook(workbook, labelSize),
        _itemOutputPreviewReplacements(
          item: item,
          elementText: elementText,
          columnValue: columnValue,
        ),
        codeDataResolver: ItemCodeDataResolver(
          itemName: item.item.itemName,
          columns: columns,
          columnValue: columnValue,
          tokenColumnValue: (column) => itemCodeTokenColumnValue(
            column: column,
            columns: columns,
            columnValue: columnValue,
            referenceAt: referenceAt,
          ),
          gs1Definitions: Gs1AiDefinitions.values,
        ),
        elementCell: _itemElementCellFromWorkbook(
          elementWorkbook ?? _itemElementWorkbook(elementText, labelSize),
        ),
        imageKeywords: _itemOutputPreviewImageKeywords(),
      ),
      hintText: null,
    );
  }
  return (workbook: null, hintText: null);
}

class _ItemElementFormState {
  const _ItemElementFormState({
    required this.workbook,
    required this.encodedWorkbook,
    required this.text,
    required this.sourceHash,
    required this.convertedFromRtf,
  });

  final fs.FortuneWorkbook workbook;
  final String encodedWorkbook;
  final String text;
  final int sourceHash;
  final bool convertedFromRtf;

  _ItemElementFormState copyWith({
    fs.FortuneWorkbook? workbook,
    String? encodedWorkbook,
    String? text,
    int? sourceHash,
    bool? convertedFromRtf,
  }) {
    return _ItemElementFormState(
      workbook: workbook ?? this.workbook,
      encodedWorkbook: encodedWorkbook ?? this.encodedWorkbook,
      text: text ?? this.text,
      sourceHash: sourceHash ?? this.sourceHash,
      convertedFromRtf: convertedFromRtf ?? this.convertedFromRtf,
    );
  }
}

_ItemElementFormState _itemElementFormStateFor(
  ItemOfMarket item,
  LabelSize? labelSize,
) {
  final payload = item.item.elementRTF.trim();
  final savedWorkbook = labelSheetTryDecodeWorkbookSave(payload);
  if (savedWorkbook != null) {
    return _itemElementFormStateFromWorkbook(
      labelSheetWorkbook(savedWorkbook, labelSize: labelSize),
      sourceHash: payload.hashCode,
      convertedFromRtf: false,
    );
  }
  return _itemElementFormStateFromWorkbook(
    _itemElementWorkbook(item.item.element, labelSize),
    sourceHash: payload.isNotEmpty
        ? payload.hashCode
        : item.item.element.hashCode,
    convertedFromRtf: false,
  );
}

_ItemElementFormState _itemElementFormStateFromWorkbook(
  fs.FortuneWorkbook workbook, {
  required int sourceHash,
  required bool convertedFromRtf,
}) {
  return _ItemElementFormState(
    workbook: workbook,
    encodedWorkbook: labelSheetEncodeWorkbookSave(workbook),
    text: _itemElementTextFromWorkbook(workbook),
    sourceHash: sourceHash,
    convertedFromRtf: convertedFromRtf,
  );
}

String _itemElementTextFromWorkbook(fs.FortuneWorkbook workbook) {
  return _itemElementCellFromWorkbook(workbook)?.renderedText ?? '';
}

fs.FortuneCell? _itemElementCellFromWorkbook(fs.FortuneWorkbook workbook) {
  if (workbook.sheets.isEmpty) return null;
  return workbook.sheets.first.cells[const fs.FortuneCellCoord(0, 0)];
}

@visibleForTesting
Future<fs.FortuneWorkbook?> debugItemElementWorkbookFromRichEditRtfForTesting(
  String rtf,
  LabelSize? labelSize,
) => _itemElementWorkbookFromRichEditRtfAsync(rtf, labelSize);

@visibleForTesting
fs.FortuneWorkbook debugItemElementWorkbookForOutputTesting(
  ItemOfMarket item,
  LabelSize? labelSize,
) => _itemElementFormStateFor(item, labelSize).workbook;

Future<fs.FortuneWorkbook?> _itemElementWorkbookFromRichEditRtfAsync(
  String rtf,
  LabelSize? labelSize,
) async {
  final base = _itemElementWorkbook('', labelSize);
  if (base.sheets.isEmpty) return null;
  final draft = await labelSheetDraftFromRichEditRtfAsync(
    rtf,
    sheet: base.sheets.first,
  );
  if (draft == null || draft.cells.isEmpty) return null;
  final cell = _itemElementSingleCellFromDraftCells(draft.cells);
  if (cell == null || cell.renderedText.trim().isEmpty) return null;
  return _itemElementWorkbookFromCell(cell, labelSize);
}

fs.FortuneWorkbook _itemElementWorkbookFromCell(
  fs.FortuneCell cell,
  LabelSize? labelSize,
) {
  final base = _itemElementWorkbook('', labelSize);
  final sheet = base.sheets.first;
  return base.copyWith(
    sheets: [
      sheet.copyWith(
        cells: {
          const fs.FortuneCellCoord(0, 0): cell.copyWith(
            textWrap: '2',
            rawTextWrap: '2',
            hasRawTextWrap: true,
            verticalAlign: '1',
            rawVerticalAlign: '1',
            hasRawVerticalAlign: true,
          ),
        },
      ),
    ],
  );
}

fs.FortuneCell? _itemElementSingleCellFromDraftCells(
  Map<fs.FortuneCellCoord, fs.FortuneCell> cells,
) {
  final entries =
      cells.entries
          .where((entry) => entry.value.renderedText.trim().isNotEmpty)
          .toList()
        ..sort((a, b) {
          final row = a.key.row.compareTo(b.key.row);
          return row != 0 ? row : a.key.column.compareTo(b.key.column);
        });
  if (entries.isEmpty) return null;

  final runs = <fs.FortuneInlineTextRun>[];
  fs.FortuneCell? baseCell;
  int? currentRow;
  var firstInRow = true;
  for (final entry in entries) {
    baseCell ??= entry.value;
    if (currentRow != entry.key.row) {
      if (currentRow != null) {
        runs.add(const fs.FortuneInlineTextRun(text: '\n'));
      }
      currentRow = entry.key.row;
      firstInRow = true;
    } else if (!firstInRow) {
      runs.add(const fs.FortuneInlineTextRun(text: '\t'));
    }
    runs.addAll(_itemInlineRunsFromCell(entry.value));
    firstInRow = false;
  }
  final trimmedRuns = _trimItemElementBoundaryRuns(runs);
  if (trimmedRuns.isEmpty) return null;
  return _itemRichTextCell(
    trimmedRuns,
    base: baseCell,
    extraFields: baseCell?.extraFields,
  );
}

List<fs.FortuneInlineTextRun> _trimItemElementBoundaryRuns(
  List<fs.FortuneInlineTextRun> runs,
) {
  var start = 0;
  var startOffset = 0;
  while (start < runs.length) {
    final text = runs[start].text;
    while (startOffset < text.length &&
        _isItemElementBoundaryWhitespace(text.codeUnitAt(startOffset))) {
      startOffset += 1;
    }
    if (startOffset < text.length) break;
    start += 1;
    startOffset = 0;
  }
  if (start >= runs.length) return const <fs.FortuneInlineTextRun>[];

  var end = runs.length - 1;
  var endOffset = runs[end].text.length;
  while (end >= start) {
    final text = runs[end].text;
    while (endOffset > 0 &&
        _isItemElementBoundaryWhitespace(text.codeUnitAt(endOffset - 1))) {
      endOffset -= 1;
    }
    if (endOffset > 0) break;
    end -= 1;
    if (end < start) return const <fs.FortuneInlineTextRun>[];
    endOffset = runs[end].text.length;
  }

  return [
    for (var index = start; index <= end; index += 1)
      runs[index].copyWith(
        text: runs[index].text.substring(
          index == start ? startOffset : 0,
          index == end ? endOffset : runs[index].text.length,
        ),
      ),
  ].where((run) => run.text.isNotEmpty).toList(growable: false);
}

bool _isItemElementBoundaryWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d ||
      codeUnit == 0x00a0;
}

fs.FortuneWorkbook _itemElementWorkbook(
  String elementText,
  LabelSize? labelSize,
) {
  final printAreaSize = _itemElementPrintAreaSize(labelSize);
  final columnWidth = max(1.0, printAreaSize.width - 1.0);
  final rowHeight = max(1.0, printAreaSize.height - 1.0);
  return fs.FortuneWorkbook(
    sheets: [
      fs.FortuneSheet(
        id: 'item_element',
        name: '주원료 및 함량',
        rowCount: 1,
        columnCount: 1,
        rowHeights: {0: rowHeight},
        columnWidths: {0: columnWidth},
        customHeight: const {0: 1},
        customWidth: const {0: 1},
        zoomRatio: 1,
        cells: {
          const fs.FortuneCellCoord(0, 0): _itemTextCell(
            elementText,
          ).copyWith(textWrap: '2', verticalAlign: '1'),
        },
        showGridLines: false,
      ),
    ],
  );
}

Size _itemElementPrintAreaSize(LabelSize? labelSize) {
  final common = labelSize?.labelSizeCommon;
  final widthMm = common?.width != null && common!.width > 0
      ? common.width
      : 100;
  final heightMm = common?.height != null && common!.height > 0
      ? common.height
      : 100;
  return Size(
    fs.fortuneMillimetersToLogicalPixels(widthMm),
    fs.fortuneMillimetersToLogicalPixels(heightMm),
  );
}

fs.FortuneWorkbook _itemOutputPreviewPrivateWorkbook(
  fs.FortuneWorkbook workbook,
  LabelSize? labelSize,
) {
  final source = workbook.sheets.isEmpty
      ? fs.FortuneSheet(id: 'item_output_preview_source', name: 'Labels')
      : workbook.sheets[workbook.activeSheetIndex.clamp(
          0,
          workbook.sheets.length - 1,
        )];
  final labelName = labelSize?.labelSizeName.trim();
  final sourceName = source.name.trim();
  final name = labelName?.isNotEmpty == true
      ? labelName!
      : sourceName.isEmpty
      ? 'Labels'
      : sourceName;
  return workbook.copyWith(
    sheets: [
      source.copyWith(
        id: 'item_output_preview_sheet_01',
        name: name,
        order: 0,
        hide: null,
        status: 1,
        showGridLines: false,
      ),
    ],
    activeSheetIndex: 0,
  );
}

Map<String, String> _itemOutputPreviewReplacements({
  required ItemOfMarket item,
  required String elementText,
  String Function(int columnId)? columnValue,
}) {
  return <String, String>{
    '#ITEMNAME': item.item.itemName,
    '#ELEMENT': elementText,
    for (final column in TColumn.datas ?? const <TColumn>[])
      '#${column.keyword}':
          columnValue?.call(column.columnId) ??
          TColumnContent.get(column.columnId, item.item.itemId)?.dataString ??
          '',
    for (final special in TColumnSpecial.datas ?? const <TColumnBase>[])
      if (scaleOutputSpecialColumnIdForKeyword(special.keyword) case final columnId?)
        '#${special.keyword}': columnValue?.call(columnId) ?? '',
  };
}

Set<String> _itemOutputPreviewImageKeywords() {
  return <String>{
    for (final column in TColumn.datas ?? const <TColumn>[])
      if (column.columnType.code == TColumnType.TYPE_IMAGE)
        '#${column.keyword}'.toLowerCase(),
  };
}

fs.FortuneWorkbook _replaceItemPreviewKeywords(
  fs.FortuneWorkbook workbook,
  Map<String, String> replacements, {
  ItemCodeDataResolver? codeDataResolver,
  fs.FortuneCell? elementCell,
  required Set<String> imageKeywords,
}) {
  final nextSheets = [
    for (final sheet in workbook.sheets)
      _replaceSheetKeywords(
        sheet,
        replacements,
        codeDataResolver: codeDataResolver,
        elementCell: elementCell,
        imageKeywords: imageKeywords,
      ),
  ];
  return workbook.copyWith(sheets: nextSheets);
}

fs.FortuneSheet _replaceSheetKeywords(
  fs.FortuneSheet sheet,
  Map<String, String> replacements, {
  ItemCodeDataResolver? codeDataResolver,
  fs.FortuneCell? elementCell,
  required Set<String> imageKeywords,
}) {
  final nextCells = <fs.FortuneCellCoord, fs.FortuneCell>{};
  final insertedImages = <fs.FortuneImage>[];
  final nextRowHeights = <int, double>{...sheet.rowHeights};
  final nextCustomHeight = <int, double>{...sheet.customHeight};
  for (final entry in sheet.cells.entries) {
    final imageReplacement = _itemImageReplacementForCell(
      sheet,
      entry.key,
      entry.value,
      replacements,
      imageKeywords,
    );
    if (imageReplacement != null) {
      final image = imageReplacement.image;
      if (image != null) {
        insertedImages.add(image);
      }
      nextCells[entry.key] = imageReplacement.cell;
      continue;
    }
    final containsElementKeyword = entry.value.renderedText.contains(
      '#ELEMENT',
    );
    final nextCell = _replaceCellKeywords(
      entry.value,
      replacements,
      elementCell: elementCell,
    );
    nextCells[entry.key] = nextCell;
    if (elementCell != null && containsElementKeyword) {
      final rowHeight = _itemPreviewRequiredRowHeight(
        nextCell,
        _itemCellRect(sheet, entry.key).width,
      );
      if (rowHeight != null &&
          rowHeight >
              (nextRowHeights[entry.key.row] ?? sheet.defaultRowHeight ?? 19)) {
        nextRowHeights[entry.key.row] = rowHeight;
        nextCustomHeight[entry.key.row] = 1;
      }
    }
  }
  final nextImages = <fs.FortuneImage>[];
  for (final image in sheet.images) {
    final materializedImage = _replaceImageKeywords(
      image,
      replacements,
      codeDataResolver: codeDataResolver,
    );
    if (materializedImage != null) {
      nextImages.add(materializedImage);
    }
  }
  nextImages.addAll(insertedImages);
  final rowShifts = _itemPreviewRowShifts(sheet, nextRowHeights);
  return sheet.copyWith(
    cells: nextCells,
    images: [
      for (final image in nextImages)
        image.copyWith(top: _itemPreviewShiftedY(image.top, rowShifts)),
    ],
    lines: [
      for (final line in sheet.lines)
        line.copyWith(
          y1: _itemPreviewShiftedY(line.y1, rowShifts),
          y2: _itemPreviewShiftedY(line.y2, rowShifts),
        ),
    ],
    shapes: [
      for (final shape in sheet.shapes)
        shape.copyWith(top: _itemPreviewShiftedY(shape.top, rowShifts)),
    ],
    rowHeights: nextRowHeights,
    customHeight: nextCustomHeight,
  );
}

List<({double boundary, double delta})> _itemPreviewRowShifts(
  fs.FortuneSheet sheet,
  Map<int, double> nextRowHeights,
) {
  final shifts = <({double boundary, double delta})>[];
  for (final entry in nextRowHeights.entries) {
    final previousHeight =
        sheet.rowHeights[entry.key] ?? sheet.defaultRowHeight ?? 19;
    final delta = entry.value - previousHeight;
    if (delta <= 0) continue;
    final boundary = _itemCellRect(
      sheet,
      fs.FortuneCellCoord(entry.key, 0),
    ).bottom;
    shifts.add((boundary: boundary, delta: delta));
  }
  return shifts;
}

double _itemPreviewShiftedY(
  double value,
  List<({double boundary, double delta})> shifts,
) {
  var result = value;
  for (final shift in shifts) {
    if (value >= shift.boundary) {
      result += shift.delta;
    }
  }
  return result;
}

({fs.FortuneCell cell, fs.FortuneImage? image})? _itemImageReplacementForCell(
  fs.FortuneSheet sheet,
  fs.FortuneCellCoord coord,
  fs.FortuneCell cell,
  Map<String, String> replacements,
  Set<String> imageKeywords,
) {
  final text = cell.renderedText;
  for (final entry in replacements.entries) {
    if (!imageKeywords.contains(entry.key.toLowerCase()) ||
        !text.contains(entry.key)) {
      continue;
    }
    final src = _itemImageDataUri(entry.value);
    if (src == null) {
      return (
        cell: _itemTextCell(text.replaceAll(entry.key, ''), base: cell),
        image: null,
      );
    }
    final rect = _itemCellRect(sheet, coord);
    final image = fs.FortuneImage(
      id: 'item-image-${sheet.id}-${coord.row}-${coord.column}-${entry.key.replaceAll('#', '')}',
      src: src,
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      extraFields: {
        fs.fortuneImageObjectIdExtraKey: entry.key,
        'fileName': entry.value,
      },
    );
    return (
      cell: _itemTextCell(text.replaceAll(entry.key, ''), base: cell),
      image: image,
    );
  }
  return null;
}

Rect _itemCellRect(fs.FortuneSheet sheet, fs.FortuneCellCoord coord) {
  double offsetFor(int count, double Function(int index) sizeFor) {
    var offset = 0.0;
    for (var index = 0; index < count; index += 1) {
      offset += sizeFor(index);
    }
    return offset;
  }

  final width = sheet.columnWidths[coord.column] ?? sheet.defaultColWidth ?? 73;
  final height = sheet.rowHeights[coord.row] ?? sheet.defaultRowHeight ?? 19;
  return Rect.fromLTWH(
    offsetFor(
      coord.column,
      (index) => sheet.columnWidths[index] ?? sheet.defaultColWidth ?? 73,
    ),
    offsetFor(
      coord.row,
      (index) => sheet.rowHeights[index] ?? sheet.defaultRowHeight ?? 19,
    ),
    width,
    height,
  );
}

double? _itemPreviewRequiredRowHeight(fs.FortuneCell cell, double columnWidth) {
  if (cell.renderedText.isEmpty || columnWidth <= 0) {
    return null;
  }
  final painter =
      TextPainter(
        text: _itemPreviewTextSpan(cell),
        maxLines: cell.normalizedTextWrap == '2' ? null : 1,
        textDirection: TextDirection.ltr,
        ellipsis: cell.normalizedTextWrap == '2' ? null : '',
      )..layout(
        maxWidth: cell.normalizedTextWrap == '2'
            ? max(1.0, columnWidth)
            : double.infinity,
      );
  return max(4.0, painter.height + 6.0);
}

TextSpan _itemPreviewTextSpan(fs.FortuneCell cell) {
  final baseStyle = _itemPreviewTextStyle(
    fontSize: cell.fontSize ?? 10,
    fontFamily: cell.fontFamily,
    bold: cell.bold,
    italic: cell.italic,
    foreground: cell.foreground,
    extraFields: cell.extraFields,
  );
  final runs = cell.inlineRuns;
  if (runs == null || runs.isEmpty) {
    return TextSpan(text: cell.renderedText, style: baseStyle);
  }
  return TextSpan(
    style: baseStyle,
    children: [
      for (final run in runs)
        TextSpan(
          text: run.text,
          style: _itemPreviewTextStyle(
            fontSize: run.fontSize ?? cell.fontSize ?? 10,
            fontFamily: run.fontFamily ?? cell.fontFamily,
            bold: run.bold ?? cell.bold,
            italic: run.italic ?? cell.italic,
            foreground: run.foreground ?? cell.foreground,
            extraFields: run.extraFields,
          ),
        ),
    ],
  );
}

TextStyle _itemPreviewTextStyle({
  required double fontSize,
  required String? fontFamily,
  required bool bold,
  required bool italic,
  required Color foreground,
  required Map<String, Object?> extraFields,
}) {
  final lineHeight = _itemPreviewDoubleExtra(extraFields, 'lineHeight');
  return TextStyle(
    color: foreground,
    fontSize: fontSize,
    fontFamily: fontFamily,
    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    height: lineHeight != null && lineHeight.isFinite && lineHeight > 0
        ? lineHeight
        : 1.2,
    letterSpacing: _itemPreviewDoubleExtra(extraFields, 'letterSpacing'),
  );
}

double? _itemPreviewDoubleExtra(Map<String, Object?> extraFields, String key) {
  final value = extraFields[key];
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

fs.FortuneImage? _replaceImageKeywords(
  fs.FortuneImage image,
  Map<String, String> replacements, {
  ItemCodeDataResolver? codeDataResolver,
}) {
  final extraFields = Map<String, Object?>.from(image.extraFields);
  if (extraFields['fortuneBarcode'] == true) {
    final objectId = '${extraFields[fs.fortuneBarcodeObjectIdExtraKey] ?? ''}'
        .trim()
        .toLowerCase();
    final preserveTemplateFormat =
        extraFields['preserveTemplateBarcodeFormat'] == true;
    final resolved = codeDataResolver?.resolveObject(
      objectId,
      templateFormatId: '${extraFields['barcodeFormatId'] ?? ''}',
      preserveTemplateBarcodeFormat: preserveTemplateFormat,
    );
    if (resolved != null) {
      final metadata = itemCodeBarcodeMetadata(
        extraFields,
        resolved,
        preserveTemplateBarcodeFormat: preserveTemplateFormat,
      );
      return image.copyWith(
        src: resolved.error == null
            ? image.src
            : _itemCodeErrorPlaceholderDataUri(),
        extraFields: metadata,
      );
    }
    for (final entry in replacements.entries) {
      if (entry.key.toLowerCase() != objectId) continue;
      extraFields['barcodeText'] = entry.value;
      return image.copyWith(extraFields: extraFields);
    }
  }
  final objectId = '${extraFields[fs.fortuneImageObjectIdExtraKey] ?? ''}'
      .trim()
      .toLowerCase();
  if (objectId.isNotEmpty) {
    for (final entry in replacements.entries) {
      if (entry.key.toLowerCase() != objectId) continue;
      final src = _itemImageDataUri(entry.value);
      if (src == null) return null;
      return image.copyWith(src: src, extraFields: extraFields);
    }
    return null;
  }
  return image.copyWith();
}

String _itemCodeErrorPlaceholderDataUri() {
  const svg =
      '''<svg xmlns="http://www.w3.org/2000/svg" width="240" height="120" viewBox="0 0 240 120">
<rect width="240" height="120" fill="#fff4f4" stroke="#b3261e" stroke-width="4"/>
<path d="M88 36l64 48M152 36L88 84" stroke="#b3261e" stroke-width="8"/>
<text x="120" y="108" text-anchor="middle" font-family="sans-serif" font-size="14" fill="#b3261e">BARCODE ERROR</text>
</svg>''';
  return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(svg))}';
}

String? _itemImageDataUri(String fileNameWithoutExtension) {
  final value = fileNameWithoutExtension.trim();
  if (value.isEmpty) return null;
  final file = File('C:\\ITS\\LabelManager\\bmp files\\$value.bmp');
  if (!file.existsSync()) return null;
  final bytes = file.readAsBytesSync();
  return 'data:image/bmp;base64,${base64Encode(bytes)}';
}

fs.FortuneCell _replaceCellKeywords(
  fs.FortuneCell cell,
  Map<String, String> replacements, {
  fs.FortuneCell? elementCell,
}) {
  final afterElement = elementCell == null
      ? cell
      : _replaceElementKeywordInCell(cell, elementCell);
  final target = afterElement;
  final targetRuns = target.inlineRuns;
  if (targetRuns != null && targetRuns.isNotEmpty) {
    var changed = false;
    final nextRuns = [
      for (final run in targetRuns)
        run.copyWith(
          text: _replaceKeywordText(
            run.text,
            replacements,
            onChanged: () => changed = true,
          ),
        ),
    ];
    return changed ? target.copyWith(inlineRuns: nextRuns) : target.copyWith();
  }
  var changed = false;
  final text = _replaceKeywordText(
    target.renderedText,
    replacements,
    onChanged: () => changed = true,
  );
  if (!changed) {
    return target.copyWith();
  }
  return _itemTextCell(text, base: target);
}

fs.FortuneCell _replaceElementKeywordInCell(
  fs.FortuneCell cell,
  fs.FortuneCell elementCell,
) {
  const keyword = '#ELEMENT';
  if (!cell.renderedText.contains(keyword)) {
    return cell.copyWith();
  }
  final elementRuns = _itemInlineRunsFromCell(elementCell);
  if (elementRuns.isEmpty) {
    return _itemTextCell(cell.renderedText.replaceAll(keyword, ''), base: cell);
  }
  final nextRuns = <fs.FortuneInlineTextRun>[];
  var changed = false;
  for (final run in _itemInlineRunsFromCell(cell)) {
    var rest = run.text;
    while (true) {
      final index = rest.indexOf(keyword);
      if (index < 0) {
        if (rest.isNotEmpty) {
          nextRuns.add(run.copyWith(text: rest));
        }
        break;
      }
      final prefix = rest.substring(0, index);
      if (prefix.isNotEmpty) {
        nextRuns.add(run.copyWith(text: prefix));
      }
      nextRuns.addAll(elementRuns.map((source) => source.copyWith()));
      rest = rest.substring(index + keyword.length);
      changed = true;
    }
  }
  if (!changed) {
    return cell.copyWith();
  }
  return _itemRichTextCell(
    nextRuns,
    base: cell,
    extraFields: {...cell.extraFields, ...elementCell.extraFields},
  ).copyWith(textWrap: '2', rawTextWrap: '2', hasRawTextWrap: true);
}

List<fs.FortuneInlineTextRun> _itemInlineRunsFromCell(fs.FortuneCell cell) {
  final runs = cell.inlineRuns;
  if (runs != null && runs.isNotEmpty) {
    return [for (final run in runs) run.copyWith()];
  }
  final text = cell.renderedText;
  if (text.isEmpty) return const <fs.FortuneInlineTextRun>[];
  return [
    fs.FortuneInlineTextRun(
      text: text,
      foreground: cell.foreground,
      rawForeground: cell.rawForeground,
      hasRawForeground: cell.hasRawForeground,
      bold: cell.bold,
      rawBold: cell.rawBold,
      hasRawBold: cell.hasRawBold,
      italic: cell.italic,
      rawItalic: cell.rawItalic,
      hasRawItalic: cell.hasRawItalic,
      strikeThrough: cell.strikeThrough,
      rawStrikeThrough: cell.rawStrikeThrough,
      hasRawStrikeThrough: cell.hasRawStrikeThrough,
      underline: cell.underline,
      rawUnderline: cell.rawUnderline,
      hasRawUnderline: cell.hasRawUnderline,
      fontSize: cell.fontSize,
      rawFontSize: cell.rawFontSize,
      hasRawFontSize: cell.hasRawFontSize,
      fontFamily: cell.fontFamily,
      rawFontFamily: cell.rawFontFamily,
      hasRawFontFamily: cell.hasRawFontFamily,
      extraFields: cell.extraFields,
    ),
  ];
}

fs.FortuneCell _itemRichTextCell(
  List<fs.FortuneInlineTextRun> runs, {
  fs.FortuneCell? base,
  Map<String, Object?>? extraFields,
}) {
  final text = runs.map((run) => run.text).join();
  final source = base ?? const fs.FortuneCell();
  return source.copyWith(
    value: text,
    displayValue: text,
    rawDisplayValue: text,
    hasRawDisplayValue: text.isNotEmpty,
    formula: null,
    rawFormula: null,
    hasRawFormula: false,
    inlineRuns: [for (final run in runs) run.copyWith()],
    extraFields: extraFields ?? source.extraFields,
  );
}

String _replaceKeywordText(
  String value,
  Map<String, String> replacements, {
  required VoidCallback onChanged,
}) {
  var next = value;
  for (final entry in replacements.entries) {
    if (!next.contains(entry.key)) continue;
    next = next.replaceAll(entry.key, entry.value);
    onChanged();
  }
  return next;
}

fs.FortuneCell _itemTextCell(String text, {fs.FortuneCell? base}) {
  final source = base ?? const fs.FortuneCell();
  return source.copyWith(
    value: text,
    displayValue: text,
    rawDisplayValue: text,
    hasRawDisplayValue: text.isNotEmpty,
    formula: null,
    rawFormula: null,
    hasRawFormula: false,
    inlineRuns: null,
  );
}

class _LabelSettingsDialog extends StatefulWidget {
  const _LabelSettingsDialog({
    required this.brands,
    required this.selectedBrand,
    required this.brandId,
    required this.currentLabelSizeId,
    required this.labels,
    required this.onBrandChanged,
    required this.onLabelSelected,
    required this.onLabelsChanged,
    required this.onLabelsCommitted,
    required this.onClose,
  });

  final List<Brand> brands;
  final Brand? selectedBrand;
  final int? brandId;
  final int? Function() currentLabelSizeId;
  final List<LabelSize> labels;
  final Future<void> Function(Brand?) onBrandChanged;
  final Future<void> Function(LabelSize?) onLabelSelected;
  final Future<List<LabelSize>> Function({
    LabelSize? preferredSelectedLabel,
    bool updateSelection,
  })
  onLabelsChanged;
  final ValueChanged<List<LabelSize>> onLabelsCommitted;
  final VoidCallback onClose;

  @override
  State<_LabelSettingsDialog> createState() => _LabelSettingsDialogState();
}

class _LabelSettingsDialogState extends State<_LabelSettingsDialog> {
  static const double _dialogWidth = 500;

  late List<LabelSize> _labels;
  late List<LabelSize> _originalLabels;
  final GlobalKey _dialogContentKey = GlobalKey();
  final TextEditingController _labelNameEditController =
      TextEditingController();
  final FocusNode _labelNameEditFocusNode = FocusNode();
  int? _editingIndex;
  int? _insertActionIndex;
  bool _orderEditMode = false;
  bool _applyingOrderChanges = false;
  bool _insertingLabel = false;
  bool _selectingLabel = false;
  bool _changingBrand = false;
  bool _submittingLabelNameEdit = false;
  bool _deletingLabel = false;
  bool _labelUseScaleEditValue = false;
  int? _selectedBrandId;
  int? _selectedLabelSizeId;

  @override
  void initState() {
    super.initState();
    _labels = List<LabelSize>.from(widget.labels);
    _originalLabels = List<LabelSize>.from(widget.labels);
    _selectedBrandId = widget.selectedBrand?.brandId ?? widget.brandId;
    _labelNameEditController.addListener(_handleLabelNameEditChanged);
  }

  @override
  void didUpdateWidget(covariant _LabelSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBrand?.brandId != widget.selectedBrand?.brandId ||
        oldWidget.brandId != widget.brandId) {
      _selectedBrandId = widget.selectedBrand?.brandId ?? widget.brandId;
    }
    if (!identical(oldWidget.labels, widget.labels) && !_hasOrderChanges) {
      final newLabels = List<LabelSize>.from(widget.labels);
      final editingIndex = _editingIndex;
      final outOfRange =
          editingIndex != null && editingIndex >= newLabels.length;
      _labels = newLabels;
      _originalLabels = List<LabelSize>.from(widget.labels);
      if (outOfRange) {
        _cancelLabelNameEdit();
      }
    }
  }

  @override
  void dispose() {
    _labelNameEditController.removeListener(_handleLabelNameEditChanged);
    _labelNameEditController.dispose();
    _labelNameEditFocusNode.dispose();
    super.dispose();
  }

  bool get _hasOrderChanges {
    if (_labels.length != _originalLabels.length) {
      return true;
    }
    for (var index = 0; index < _labels.length; index += 1) {
      final label = _labels[index];
      final originalLabel = _originalLabels[index];
      if (!identical(label, originalLabel) ||
          label.labelSizeId != originalLabel.labelSizeId ||
          label.labelSizeName != originalLabel.labelSizeName) {
        return true;
      }
    }
    return false;
  }

  bool get _hasLabelActionInProgress =>
      _editingIndex != null ||
      _orderEditMode ||
      _applyingOrderChanges ||
      _insertingLabel ||
      _selectingLabel ||
      _changingBrand ||
      _submittingLabelNameEdit ||
      _deletingLabel;

  Brand? get _selectedBrand {
    final selectedBrandId = _selectedBrandId;
    if (selectedBrandId == null) return null;
    for (final brand in widget.brands) {
      if (brand.brandId == selectedBrandId) {
        return brand;
      }
    }
    return null;
  }

  List<DropdownMenuItem<Brand>> get _brandItems => widget.brands
      .map(
        (brand) => DropdownMenuItem<Brand>(
          value: brand,
          child: Text(brand.brandName, overflow: TextOverflow.ellipsis),
        ),
      )
      .toList();

  int? get _selectedLabelIndex {
    final selectedLabelSizeId = _selectedLabelSizeId;
    if (selectedLabelSizeId == null) return null;
    final index = _labels.indexWhere(
      (label) => label.labelSizeId == selectedLabelSizeId,
    );
    return index >= 0 ? index : null;
  }

  bool get _canMoveSelectedLabelUp {
    final index = _selectedLabelIndex;
    return _orderEditMode && index != null && index > 0;
  }

  bool get _canMoveSelectedLabelDown {
    final index = _selectedLabelIndex;
    return _orderEditMode && index != null && index < _labels.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    debugLog(
      'labelSettingsDialog build labels=${_labels.length} orderChanged=$_hasOrderChanges',
    );
    return BlockingModelessDialogFrame(
      title: '라벨 설정',
      width: _dialogWidth,
      height: dialogHeight,
      closeIcon: const _BrandDialogCloseIcon(),
      onClose: widget.onClose,
      closeEnabled:
          !_changingBrand &&
          !_submittingLabelNameEdit &&
          !_deletingLabel &&
          !_applyingOrderChanges,
      footer: _orderEditMode ? _buildOrderEditFooter() : null,
      child: KeyedSubtree(
        key: _dialogContentKey,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrandSelector(),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildLabelTable()),
                    if (_orderEditMode) ...[
                      const SizedBox(width: 6),
                      _buildOrderMoveRail(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSelector() {
    final enabled = _brandItems.isNotEmpty && !_hasLabelActionInProgress;
    return Row(
      children: [
        _ModelessDropdownField<Brand>(
          label: '브랜드',
          value: _selectedBrand,
          items: _brandItems,
          onChanged: enabled ? _handleBrandDropdownChanged : null,
          debugLabel: 'labelSettings.brandDropdown',
          menuBoundaryKey: _dialogContentKey,
          width: 260,
          labelWidth: 54,
        ),
        if (_changingBrand) ...[
          const SizedBox(width: 8),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Future<void> _handleBrandDropdownChanged(Brand? brand) async {
    debugLog(
      'labelSettings brandDropdown changed brandId=${brand?.brandId} '
      'editingIndex=$_editingIndex orderEditMode=$_orderEditMode changing=$_changingBrand',
    );
    if (brand == null || _hasLabelActionInProgress) {
      debugLog(
        'labelSettings brandDropdown blocked brandId=${brand?.brandId} '
        'editingIndex=$_editingIndex orderEditMode=$_orderEditMode changing=$_changingBrand',
      );
      return;
    }
    if (brand.brandId == _selectedBrandId) {
      return;
    }

    final previousBrandId = _selectedBrandId;
    setState(() {
      _changingBrand = true;
      _selectedBrandId = brand.brandId;
    });
    try {
      await widget.onBrandChanged(brand);
    } catch (e) {
      debugLog('labelSettings brandDropdown failed error=$e');
      if (!mounted) return;
      setState(() => _selectedBrandId = previousBrandId);
      await showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (dialogContext, close) => AlertDialog(
          title: const Text('브랜드 변경 실패'),
          content: const Text('브랜드 변경 중 오류가 발생했습니다.'),
          actions: [
            TextButton(onPressed: () => close(null), child: const Text('확인')),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _changingBrand = false);
      }
    }
  }

  Widget _buildOrderEditFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            '순서 변경',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            height: 30,
            child: _LabelSettingsFooterButton(
              label: '취소',
              onPressed: _cancelOrderChanges,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 84,
            height: 30,
            child: _LabelSettingsFooterButton(
              label: '적용',
              onPressed: _applyingOrderChanges || !_hasOrderChanges
                  ? null
                  : _applyOrderChanges,
            ),
          ),
        ],
      ),
    );
  }

  static String _labelNameText(LabelSize label) => label.labelSizeName;

  Widget _buildLabelTable() {
    return EditableSwipeNameTable<LabelSize>(
      rows: _labels,
      header: '라벨 이름',
      text: _labelNameText,
      editController: _labelNameEditController,
      editFocusNode: _labelNameEditFocusNode,
      editingIndex: _editingIndex,
      insertActionIndex: _insertActionIndex,
      inserting: _insertingLabel,
      canSubmit: _canSubmitLabelNameEdit,
      onToggleEdit: _toggleLabelNameEdit,
      onToggleInsert: _toggleLabelInsert,
      onEmptyInsert: _orderEditMode
          ? null
          : () => _startLabelInsertAt(0, actionIndex: null),
      onCancelEdit: _cancelLabelNameEdit,
      onSubmitEdit: _submitLabelNameEdit,
      onDeleteRow: _deleteLabel,
      onNameDoubleTap: _handleLabelNameDoubleTap,
      inlineTrailingBuilder: _buildLabelInlineTrailing,
      enabled: !_orderEditMode && !_submittingLabelNameEdit && !_deletingLabel,
      fillLastColumn: true,
      autoFitColumns: false,
      rowSwipeEnabled: !_orderEditMode,
      keepRowContentOnSwipe: true,
      rowTooltip: _orderEditMode
          ? '순서 변경 중에는 스와이프 수정/삽입/삭제를 사용할 수 없습니다'
          : '행 드래그로 순서 변경, 컬럼 왼쪽 스와이프 수정/삽입/삭제',
      showActionsWhenEmpty: true,
      rowNumberText: _labelRowNumberText,
      rowReorderEnabled: _orderEditMode,
      selectedIndex: _selectedLabelIndex,
      onRowSelected: _handleLabelRowSelected,
      onRowReorder: _moveLabelRow,
      headerTrailingBuilder: (context, hasInlineEditor) =>
          _OrderModeHeaderButton(
            enabled:
                !_orderEditMode && !_applyingOrderChanges && !hasInlineEditor,
            onPressed: _startOrderEditMode,
          ),
    );
  }

  Widget _buildOrderMoveRail() {
    return SizedBox(
      width: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OrderMoveButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: '선택 행 위로 이동',
            enabled: _canMoveSelectedLabelUp && !_applyingOrderChanges,
            onPressed: _moveSelectedLabelUp,
          ),
          const SizedBox(height: 8),
          _OrderMoveButton(
            icon: Icons.keyboard_arrow_down,
            tooltip: '선택 행 아래로 이동',
            enabled: _canMoveSelectedLabelDown && !_applyingOrderChanges,
            onPressed: _moveSelectedLabelDown,
          ),
        ],
      ),
    );
  }

  String _labelRowNumberText(LabelSize label, int index) {
    final originalIndex = _originalLabels.indexWhere(
      (original) => identical(original, label),
    );
    if (originalIndex >= 0) {
      return '${originalIndex + 1}';
    }
    final fallbackIndex = _originalLabels.indexWhere(
      (original) =>
          original.labelSizeId == label.labelSizeId &&
          original.labelSizeName == label.labelSizeName,
    );
    return fallbackIndex >= 0 ? '${fallbackIndex + 1}' : '${index + 1}';
  }

  void _toggleLabelInsert(LabelSize label, int index) {
    if (_insertingLabel && _insertActionIndex == index) {
      debugLog('labelInsert cancelByToggle index=$index');
      _cancelLabelNameEdit();
      return;
    }
    _startLabelInsertAt(index + 1, actionIndex: index);
  }

  void _startLabelInsertAt(int index, {required int? actionIndex}) {
    if (_editingIndex != null || _orderEditMode) {
      debugLog(
        'labelInsert blocked editingIndex=$_editingIndex orderEditMode=$_orderEditMode inserting=$_insertingLabel',
      );
      return;
    }
    final insertIndex = index.clamp(0, _labels.length);
    final brandId =
        widget.brandId ?? (_labels.isNotEmpty ? _labels.first.brandId : 0);
    if (brandId <= 0) {
      debugLog('labelInsert blocked brandId=$brandId');
      return;
    }
    debugLog('labelInsert start index=$insertIndex brandId=$brandId');
    setState(() {
      _insertingLabel = true;
      _editingIndex = insertIndex;
      _insertActionIndex = actionIndex;
      _labelUseScaleEditValue = false;
      _labels.insert(
        insertIndex,
        LabelSize(labelSizeId: 0, brandId: brandId, labelSizeName: ''),
      );
      _labelNameEditController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_insertingLabel || _editingIndex != insertIndex) {
        debugLog(
          'labelInsert focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$insertIndex inserting=$_insertingLabel',
        );
        return;
      }
      debugLog('labelInsert focusRequest index=$insertIndex');
      _labelNameEditFocusNode.requestFocus();
    });
  }

  void _toggleLabelNameEdit(LabelSize label, int index) {
    if (_insertingLabel || _orderEditMode) {
      debugLog(
        'labelNameEdit blocked inserting=$_insertingLabel orderEditMode=$_orderEditMode index=$index',
      );
      return;
    }
    if (_editingIndex == index) {
      debugLog('labelNameEdit cancelByToggle index=$index');
      _cancelLabelNameEdit();
      return;
    }
    debugLog(
      'labelNameEdit start index=$index labelSizeId=${label.labelSizeId} name=${label.labelSizeName}',
    );
    setState(() {
      _editingIndex = index;
      _labelUseScaleEditValue = label.labelSizeSetup?.useScale ?? false;
      _labelNameEditController.value = TextEditingValue(
        text: label.labelSizeName,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: label.labelSizeName.length,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingIndex != index) {
        debugLog(
          'labelNameEdit focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$index',
        );
        return;
      }
      debugLog('labelNameEdit focusRequest index=$index');
      _labelNameEditFocusNode.requestFocus();
    });
  }

  void _cancelLabelNameEdit() {
    if (_editingIndex == null) {
      return;
    }
    debugLog(
      'labelNameEdit cancelled index=$_editingIndex text=${_labelNameEditController.text}',
    );
    _labelNameEditFocusNode.unfocus();
    setState(() {
      if (_insertingLabel && _editingIndex! < _labels.length) {
        _labels.removeAt(_editingIndex!);
      }
      _insertingLabel = false;
      _submittingLabelNameEdit = false;
      _insertActionIndex = null;
      _editingIndex = null;
      _labelUseScaleEditValue = false;
      _labelNameEditController.clear();
    });
  }

  Widget _buildLabelInlineTrailing(
    BuildContext context,
    LabelSize label,
    int index,
  ) {
    return _LabelScaleInlineControl(
      value: _labelUseScaleEditValue,
      onChanged: (value) => _handleLabelUseScaleEditChanged(value ?? false),
    );
  }

  void _handleLabelUseScaleEditChanged(bool value) {
    if (_editingIndex == null || !mounted) {
      return;
    }
    debugLog(
      'labelNameEdit useScaleChanged index=$_editingIndex value=$value canSubmit=$_canSubmitLabelNameEdit',
    );
    setState(() => _labelUseScaleEditValue = value);
  }

  void _handleLabelNameEditChanged() {
    if (_editingIndex == null || !mounted) {
      return;
    }
    debugLog(
      'labelNameEdit textChanged index=$_editingIndex text=${_labelNameEditController.text} canSubmit=$_canSubmitLabelNameEdit',
    );
    setState(() {});
  }

  bool get _canSubmitLabelNameEdit {
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _labels.length) {
      return false;
    }
    final nextName = _labelNameEditController.text.trim();
    if (nextName.isEmpty) {
      return false;
    }
    if (_submittingLabelNameEdit) {
      return false;
    }
    if (_insertingLabel) {
      return true;
    }
    final label = _labels[editingIndex];
    return nextName != label.labelSizeName.trim() ||
        _labelUseScaleEditValue != (label.labelSizeSetup?.useScale ?? false);
  }

  Future<void> _submitLabelNameEdit(String value) async {
    debugLog(
      'labelNameEdit submit pendingImplementation index=$_editingIndex '
      'value=$value useScale=$_labelUseScaleEditValue '
      'canSubmit=$_canSubmitLabelNameEdit inserting=$_insertingLabel',
    );
    if (!_canSubmitLabelNameEdit) {
      debugLog('labelNameEdit submitSkipped canSubmit=false');
      return;
    }
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _labels.length) {
      debugLog(
        'labelNameEdit submitSkipped editingIndex=$editingIndex outOfRange',
      );
      return;
    }
    if (_insertingLabel) {
      await _insertLabelName(editingIndex, value.trim());
      return;
    }
    await _updateLabelNameAndScale(_labels[editingIndex], value.trim());
  }

  Future<void> _updateLabelNameAndScale(
    LabelSize label,
    String labelName,
  ) async {
    final editingIndex = _editingIndex;
    debugLog(
      'updateLabelNameAndScale start editingIndex=$editingIndex '
      'labelSizeId=${label.labelSizeId} old=${label.labelSizeName} '
      'new=$labelName useScale=$_labelUseScaleEditValue',
    );

    if (editingIndex == null || editingIndex >= _labels.length) {
      debugLog(
        'updateLabelNameAndScale aborted editingIndex=null or out of range',
      );
      return;
    }

    debugLog(
      'updateLabelNameAndScale confirm dialog labelSizeId=${label.labelSizeId} '
      'old=${label.labelSizeName} new=$labelName useScale=$_labelUseScaleEditValue',
    );
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: Text("'$labelName' 명으로 변경하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );

    if (!mounted) {
      debugLog('updateLabelNameAndScale aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog(
        'updateLabelNameAndScale cancelledByUser labelSizeId=${label.labelSizeId} keepEditing',
      );
      _labelNameEditFocusNode.requestFocus();
      return;
    }

    final useScale = _labelUseScaleEditValue;
    setState(() => _submittingLabelNameEdit = true);

    try {
      await LabelSizeDAO.updateNameAndScale(
        label.labelSizeId,
        labelName,
        useScale,
      );
    } catch (e) {
      debugLog(
        'updateLabelNameAndScale failed labelSizeId=${label.labelSizeId} error=$e',
      );
      if (mounted) {
        await showBlockingModelessOverlayDialog<void>(
          context: context,
          builder: (dialogContext, close) => AlertDialog(
            title: const Text('라벨 수정 실패'),
            content: const Text('라벨 수정에 실패했습니다.'),
            actions: [
              TextButton(onPressed: () => close(null), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) {
          setState(() => _submittingLabelNameEdit = false);
          _labelNameEditFocusNode.requestFocus();
        }
      }
      return;
    }

    if (!mounted) return;
    final updatedLabel = label.copyWith(
      labelSizeName: labelName,
      labelSizeSetup: label.labelSizeSetup?.copyWith(useScale: useScale),
    );
    setState(() {
      _labels[editingIndex] = updatedLabel;
      _originalLabels = List<LabelSize>.from(_labels);
      _editingIndex = null;
      _labelUseScaleEditValue = false;
      _labelNameEditController.clear();
    });
    widget.onLabelsCommitted(List<LabelSize>.from(_labels));

    try {
      final reloadedLabels = await widget.onLabelsChanged();
      if (mounted) {
        setState(() {
          _labels = List<LabelSize>.from(reloadedLabels);
          _originalLabels = List<LabelSize>.from(reloadedLabels);
        });
      }
    } catch (e) {
      debugLog(
        'updateLabelNameAndScale reload failed labelSizeId=${label.labelSizeId} error=$e',
      );
      if (mounted) await _showLabelReloadFailureDialog();
    } finally {
      if (mounted) {
        setState(() => _submittingLabelNameEdit = false);
      }
    }

    debugLog(
      'updateLabelNameAndScale done labelSizeId=${label.labelSizeId} name=$labelName useScale=$useScale',
    );
  }

  Future<void> _insertLabelName(int insertIndex, String labelName) async {
    final brandId = widget.brandId;
    debugLog(
      'insertLabelName start index=$insertIndex brandId=$brandId name=$labelName useScale=$_labelUseScaleEditValue',
    );
    if (!_insertingLabel ||
        _editingIndex != insertIndex ||
        brandId == null ||
        brandId <= 0) {
      debugLog(
        'insertLabelName aborted inserting=$_insertingLabel editingIndex=$_editingIndex expected=$insertIndex brandId=$brandId',
      );
      return;
    }

    setState(() => _submittingLabelNameEdit = true);
    debugLog(
      'insertLabelName confirmDialog show index=$insertIndex name=$labelName',
    );
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: Text("'$labelName' 라벨을 추가하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
    debugLog(
      'insertLabelName confirmDialog result=$confirmed index=$insertIndex',
    );

    if (!mounted) {
      debugLog('insertLabelName aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog(
        'insertLabelName cancelledByUser index=$insertIndex keepEditing',
      );
      setState(() => _submittingLabelNameEdit = false);
      _labelNameEditFocusNode.requestFocus();
      return;
    }

    showSnackBar(
      context,
      '라벨을 추가 중입니다...',
      type: SnackBarType.inProgress,
      duration: const Duration(days: 1),
    );

    LabelSize? inserted;
    try {
      final reloadError = await runSettingsWriteThenReload<LabelSize>(
        write: () => LabelSizeDAO.insert(
          brandId,
          labelName,
          _labelUseScaleEditValue,
          insertIndex + 1,
        ),
        onCommitted: (value) {
          inserted = value;
          if (!mounted) return;
          setState(() {
            _labels[insertIndex] = value;
            _originalLabels = List<LabelSize>.from(_labels);
            _insertingLabel = false;
            _insertActionIndex = null;
            _editingIndex = null;
            _labelUseScaleEditValue = false;
            _labelNameEditController.clear();
          });
          widget.onLabelsCommitted(List<LabelSize>.from(_labels));
        },
        reload: (value) async {
          final reloadedLabels = await widget.onLabelsChanged();
          if (mounted) {
            setState(() {
              _labels = List<LabelSize>.from(reloadedLabels);
              _originalLabels = List<LabelSize>.from(reloadedLabels);
            });
          }
        },
      );
      if (reloadError != null && mounted) {
        debugLog(
          'insertLabelName reload failed index=$insertIndex error=$reloadError',
        );
        await _showLabelReloadFailureDialog();
      }
    } catch (e) {
      debugLog('insertLabelName failed index=$insertIndex error=$e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await showBlockingModelessOverlayDialog<void>(
          context: context,
          builder: (dialogContext, close) => AlertDialog(
            title: const Text('라벨 추가 실패'),
            content: const Text('라벨 추가에 실패했습니다.'),
            actions: [
              TextButton(onPressed: () => close(null), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) {
          _labelNameEditFocusNode.requestFocus();
        }
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _submittingLabelNameEdit = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }

    final committed = inserted!;
    debugLog(
      'insertLabelName done labelSizeId=${committed.labelSizeId} index=$insertIndex name=${committed.labelSizeName}',
    );
  }

  Future<void> _deleteLabel(LabelSize label, int index) async {
    debugLog(
      'deleteLabel start index=$index labelSizeId=${label.labelSizeId} name=${label.labelSizeName} editingIndex=$_editingIndex orderEditMode=$_orderEditMode',
    );
    if (_editingIndex != null ||
        _orderEditMode ||
        _deletingLabel ||
        index < 0 ||
        index >= _labels.length) {
      debugLog(
        'deleteLabel aborted editingIndex=$_editingIndex orderEditMode=$_orderEditMode index=$index len=${_labels.length}',
      );
      return;
    }

    debugLog('deleteLabel confirmDialog show labelSizeId=${label.labelSizeId}');
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: Text("'${label.labelSizeName}' 라벨을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
    debugLog(
      'deleteLabel confirmDialog result=$confirmed labelSizeId=${label.labelSizeId}',
    );

    if (!mounted) {
      debugLog('deleteLabel aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog('deleteLabel cancelledByUser labelSizeId=${label.labelSizeId}');
      return;
    }

    final wasSelected = widget.currentLabelSizeId() == label.labelSizeId;
    final nextSelectedLabel = wasSelected
        ? _resolveLabelAfterDelete(index)
        : null;

    try {
      setState(() => _deletingLabel = true);
      try {
        await LabelSizeDAO.deleteByLabelSizeId(label.labelSizeId);
      } catch (e) {
        debugLog(
          'deleteLabel failed labelSizeId=${label.labelSizeId} error=$e',
        );
        if (mounted) {
          await showBlockingModelessOverlayDialog<void>(
            context: context,
            builder: (dialogContext, close) => AlertDialog(
              title: const Text('라벨 삭제 실패'),
              content: const Text('라벨 삭제에 실패했습니다.'),
              actions: [
                TextButton(
                  onPressed: () => close(null),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final currentIndex = _labels.indexWhere(
        (value) => value.labelSizeId == label.labelSizeId,
      );
      if (currentIndex >= 0) {
        setState(() {
          _labels.removeAt(currentIndex);
          _originalLabels = List<LabelSize>.from(_labels);
          _selectedLabelSizeId = null;
        });
        widget.onLabelsCommitted(List<LabelSize>.from(_labels));
      }

      try {
        final reloadedLabels = await widget.onLabelsChanged(
          preferredSelectedLabel: nextSelectedLabel,
          updateSelection: wasSelected,
        );
        if (mounted) {
          setState(() {
            _labels = List<LabelSize>.from(reloadedLabels);
            _originalLabels = List<LabelSize>.from(reloadedLabels);
          });
        }
      } catch (e) {
        debugLog(
          'deleteLabel reload failed labelSizeId=${label.labelSizeId} error=$e',
        );
        if (mounted) await _showLabelReloadFailureDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _deletingLabel = false);
      }
    }

    debugLog(
      'deleteLabel done labelSizeId=${label.labelSizeId} index=$index wasSelected=$wasSelected nextSelectedLabelSizeId=${nextSelectedLabel?.labelSizeId}',
    );
  }

  LabelSize? _resolveLabelAfterDelete(int deletedIndex) {
    final nextLabels = List<LabelSize>.from(_labels)..removeAt(deletedIndex);
    if (nextLabels.isEmpty) {
      return null;
    }
    final nextIndex = deletedIndex < nextLabels.length
        ? deletedIndex
        : nextLabels.length - 1;
    return nextLabels[nextIndex];
  }

  void _handleLabelRowSelected(LabelSize label, int index) {
    if (_deletingLabel || _selectedLabelSizeId == label.labelSizeId) {
      return;
    }
    debugLog(
      'labelSettings rowSelected index=$index labelSizeId=${label.labelSizeId}',
    );
    setState(() => _selectedLabelSizeId = label.labelSizeId);
  }

  Future<void> _handleLabelNameDoubleTap(LabelSize label, int index) async {
    debugLog(
      'labelNameDoubleTap index=$index editingIndex=$_editingIndex orderEditMode=$_orderEditMode selecting=$_selectingLabel labelSizeId=${label.labelSizeId} name=${label.labelSizeName}',
    );
    if (_editingIndex != null ||
        _orderEditMode ||
        _selectingLabel ||
        _deletingLabel) {
      debugLog(
        'labelNameDoubleTap blocked editingIndex=$_editingIndex orderEditMode=$_orderEditMode selecting=$_selectingLabel',
      );
      return;
    }
    debugLog('labelNameDoubleTap selectLabel labelSizeId=${label.labelSizeId}');
    setState(() => _selectingLabel = true);
    try {
      await widget.onLabelSelected(label);
    } finally {
      if (mounted) {
        setState(() => _selectingLabel = false);
      }
    }
  }

  void _startOrderEditMode() {
    if (_editingIndex != null ||
        _applyingOrderChanges ||
        _orderEditMode ||
        _deletingLabel) {
      debugLog(
        'labelSettings reorder startBlocked editingIndex=$_editingIndex applying=$_applyingOrderChanges orderEditMode=$_orderEditMode',
      );
      return;
    }
    debugLog('labelSettings reorder start labels=${_labels.length}');
    Tooltip.dismissAllToolTips();
    setState(() {
      _orderEditMode = true;
      _selectedLabelSizeId = _labels.isNotEmpty
          ? _labels.first.labelSizeId
          : null;
    });
  }

  void _moveLabelRow(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= _labels.length ||
        toIndex < 0 ||
        toIndex >= _labels.length) {
      return;
    }
    if ((fromIndex - toIndex).abs() == 1) {
      debugLog('labelSettings reorder swap from=$fromIndex to=$toIndex');
      setState(() {
        final movingLabel = _labels[fromIndex];
        _labels[fromIndex] = _labels[toIndex];
        _labels[toIndex] = movingLabel;
        _selectedLabelSizeId = movingLabel.labelSizeId;
      });
      return;
    }
    final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
    if (insertIndex == fromIndex) {
      return;
    }
    debugLog(
      'labelSettings reorder from=$fromIndex to=$toIndex insert=$insertIndex',
    );
    setState(() {
      final label = _labels.removeAt(fromIndex);
      _labels.insert(insertIndex, label);
      _selectedLabelSizeId = label.labelSizeId;
    });
  }

  void _moveSelectedLabelUp() {
    final index = _selectedLabelIndex;
    if (index == null || index <= 0) return;
    _moveLabelRow(index, index - 1);
  }

  void _moveSelectedLabelDown() {
    final index = _selectedLabelIndex;
    if (index == null || index >= _labels.length - 1) return;
    _moveLabelRow(index, index + 1);
  }

  void _cancelOrderChanges() {
    debugLog('labelSettings reorder cancel');
    if (_applyingOrderChanges) return;
    setState(() {
      _labels = List<LabelSize>.from(_originalLabels);
      _orderEditMode = false;
      _selectedLabelSizeId = null;
    });
  }

  Future<void> _applyOrderChanges() async {
    debugLog(
      'labelSettings reorder apply pending labels=${_labels.length} '
      'original=${_originalLabels.length} applying=$_applyingOrderChanges '
      'hasChanges=$_hasOrderChanges mounted=$mounted selected=$_selectedLabelSizeId',
    );
    if (_applyingOrderChanges || !_hasOrderChanges) {
      debugLog(
        'labelSettings reorder apply skipped applying=$_applyingOrderChanges '
        'hasChanges=$_hasOrderChanges',
      );
      return;
    }

    debugLog('labelSettings reorder apply confirmDialog show rootOverlay');
    // This dialog is opened from a modeless OverlayEntry. Keep it on the root
    // overlay so the user can see and click it above the label settings dialog.
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: const Text('라벨 순서 변경을 적용하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              debugLog(
                'labelSettings reorder apply confirmDialog cancelPressed',
              );
              close(false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              debugLog('labelSettings reorder apply confirmDialog okPressed');
              close(true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
    debugLog(
      'labelSettings reorder apply confirmDialog result=$confirmed mounted=$mounted',
    );

    if (!mounted) {
      debugLog(
        'labelSettings reorder apply aborted unmounted after confirmDialog',
      );
      return;
    }

    if (confirmed != true) {
      debugLog('labelSettings reorder apply cancelledByUser keepEditing');
      return;
    }

    debugLog(
      'labelSettings reorder apply confirmed startSave labels=${_labels.length}',
    );
    setState(() {
      _applyingOrderChanges = true;
    });
    showSnackBar(
      context,
      '라벨 순서를 저장 중입니다...',
      type: SnackBarType.inProgress,
      duration: const Duration(days: 1),
    );

    try {
      final orderedLabels = List<LabelSize>.from(_labels);
      debugLog(
        'labelSettings reorder apply updateOrders start '
        'ids=${orderedLabels.map((label) => label.labelSizeId).join(',')}',
      );
      await LabelSizeDAO.updateOrders([
        for (var index = 0; index < orderedLabels.length; index += 1)
          LabelSizeOrderUpdate(
            labelSizeId: orderedLabels[index].labelSizeId,
            labelSizeOrder: index + 1,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _originalLabels = List<LabelSize>.from(_labels);
        _orderEditMode = false;
        _selectedLabelSizeId = null;
      });
      widget.onLabelsCommitted(List<LabelSize>.from(_labels));
      debugLog('labelSettings reorder apply updateOrders done reloadStart');
    } catch (e) {
      debugLog('labelSettings reorder apply failed error=$e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        debugLog('labelSettings reorder apply failureDialog show rootOverlay');
        await showBlockingModelessOverlayDialog<void>(
          context: context,
          builder: (dialogContext, close) => AlertDialog(
            title: const Text('라벨 순서 저장 실패'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  debugLog(
                    'labelSettings reorder apply failureDialog okPressed',
                  );
                  close(null);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
        debugLog('labelSettings reorder apply failureDialog closed');
      }
      if (mounted) {
        setState(() => _applyingOrderChanges = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      return;
    }

    try {
      final appliedLabels = await widget.onLabelsChanged();
      debugLog(
        'labelSettings reorder apply reload done labels=${appliedLabels.length} '
        'mounted=$mounted',
      );
      if (mounted) {
        setState(() {
          _labels = List<LabelSize>.from(appliedLabels);
          _originalLabels = List<LabelSize>.from(appliedLabels);
        });
      }
      debugLog(
        'labelSettings reorder apply completed labels=${appliedLabels.length}',
      );
    } catch (e) {
      debugLog('labelSettings reorder reload failed error=$e');
      if (mounted) await _showLabelReloadFailureDialog();
    } finally {
      if (mounted) {
        debugLog('labelSettings reorder apply cleanup mounted=true');
        setState(() {
          _applyingOrderChanges = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      } else {
        debugLog('labelSettings reorder apply cleanup skipped mounted=false');
      }
    }
  }

  Future<void> _showLabelReloadFailureDialog() {
    return showBlockingModelessOverlayDialog<void>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        title: const Text('라벨 목록 갱신 실패'),
        content: const Text('저장은 완료됐지만 라벨 목록 갱신에 실패했습니다.'),
        actions: [
          TextButton(onPressed: () => close(null), child: const Text('확인')),
        ],
      ),
    );
  }
}

class _LabelSettingsFooterButton extends StatelessWidget {
  const _LabelSettingsFooterButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F3F4),
        foregroundColor: const Color(0xff111111),
        side: const BorderSide(color: Color(0xffc7c7c7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _OrderModeHeaderButton extends StatelessWidget {
  const _OrderModeHeaderButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '순서 변경',
      child: SizedBox(
        width: 24,
        height: 24,
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 14,
          icon: Icon(
            Icons.swap_vert,
            size: 18,
            color: enabled ? Colors.white : const Color(0x80FFFFFF),
          ),
          onPressed: enabled ? onPressed : null,
        ),
      ),
    );
  }
}

class _OrderMoveButton extends StatelessWidget {
  const _OrderMoveButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 34,
        height: 34,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: enabled ? Colors.white : const Color(0xFFF1F3F4),
            foregroundColor: const Color(0xFF0E2F66),
            disabledForegroundColor: const Color(0xFF9CA3AF),
            side: BorderSide(
              color: enabled
                  ? const Color(0xFF0E2F66)
                  : const Color(0xFFC7C7C7),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _LabelScaleInlineControl extends StatelessWidget {
  const _LabelScaleInlineControl({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    const controlSize = 18.0;
    const checkboxSlotSize = 14.0;
    const checkboxScale = 0.78;
    return Tooltip(
      message: '전자저울 사용',
      child: Padding(
        padding: const EdgeInsets.only(left: 2, right: 3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0xCCFFFFFF),
                blurRadius: 1,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: SizedBox(
            height: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: SizedBox.square(
                    dimension: controlSize,
                    child: Center(child: _ScaleIcon(size: controlSize)),
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: checkboxSlotSize,
                  height: checkboxSlotSize,
                  child: Transform.scale(
                    scale: checkboxScale,
                    child: Checkbox(
                      value: value,
                      onChanged: onChanged,
                      activeColor: const Color(0xFF0E2F66),
                      checkColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF0E2F66)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleIcon extends StatelessWidget {
  const _ScaleIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ScaleIconPainter());
  }
}

class _ScaleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0E2F66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final detailPaint = Paint()
      ..color = const Color(0xFF0E2F66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = const Color(0x220E2F66)
      ..style = PaintingStyle.fill;

    final platform = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.16,
        size.width * 0.52,
        size.height * 0.16,
      ),
      Radius.circular(size.width * 0.04),
    );
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.13,
        size.height * 0.32,
        size.width * 0.74,
        size.height * 0.46,
      ),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(platform, fill);
    canvas.drawRRect(platform, paint);
    canvas.drawRRect(baseRect, fill);
    canvas.drawRRect(baseRect, paint);

    final dialCenter = Offset(size.width * 0.5, size.height * 0.58);
    canvas.drawArc(
      Rect.fromCenter(
        center: dialCenter,
        width: size.width * 0.42,
        height: size.height * 0.3,
      ),
      pi,
      pi,
      false,
      detailPaint,
    );
    canvas.drawLine(
      dialCenter,
      Offset(size.width * 0.61, size.height * 0.48),
      detailPaint,
    );
    canvas.drawCircle(
      dialCenter,
      1.1,
      Paint()..color = const Color(0xFF0E2F66),
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.82),
      Offset(size.width * 0.72, size.height * 0.82),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.88),
      Offset(size.width * 0.72, size.height * 0.88),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScaleIconPainter oldDelegate) => false;
}

class _BrandSettingsDialog extends StatefulWidget {
  const _BrandSettingsDialog({
    required this.brands,
    required this.selectedBrand,
    required this.onBrandSelected,
    required this.onBrandsChanged,
    required this.onBrandsCommitted,
    required this.onClose,
    required this.busyNotifier,
  });

  final List<Brand> brands;
  final Brand? selectedBrand;
  final ValueChanged<Brand?> onBrandSelected;
  final Future<List<Brand>> Function({
    Brand? preferredSelectedBrand,
    bool updateSelection,
  })
  onBrandsChanged;
  final ValueChanged<List<Brand>> onBrandsCommitted;
  final VoidCallback onClose;

  /// 브랜드 선택 후 라벨 시트 로드가 완료될 때까지 true. 더블클릭 차단에 사용.
  final ValueNotifier<bool> busyNotifier;

  @override
  State<_BrandSettingsDialog> createState() => _BrandSettingsDialogState();
}

class _BrandSettingsDialogState extends State<_BrandSettingsDialog> {
  static const double _dialogWidth = 500;

  late List<Brand> _brands;
  late List<Brand> _originalBrands;
  final TextEditingController _brandNameEditController =
      TextEditingController();
  final FocusNode _brandNameEditFocusNode = FocusNode();
  int? _editingIndex;
  int? _insertActionIndex;
  bool _insertingBrand = false;
  bool _orderEditMode = false;
  bool _applyingOrderChanges = false;
  int? _selectedBrandId;
  final SettingsOperationGate _submissionGate = SettingsOperationGate();

  @override
  void initState() {
    super.initState();
    _brands = List<Brand>.from(widget.brands);
    _originalBrands = List<Brand>.from(widget.brands);
    _brandNameEditController.addListener(_handleBrandNameEditChanged);
  }

  @override
  void didUpdateWidget(covariant _BrandSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.brands, widget.brands)) {
      final newBrands = List<Brand>.from(widget.brands);
      final editingIndex = _editingIndex;
      final outOfRange =
          editingIndex != null && editingIndex >= newBrands.length;
      debugLog(
        'brandSettingsDialog didUpdateWidget brandsChanged'
        ' editingIndex=$editingIndex prevLen=${_brands.length} newLen=${newBrands.length}'
        ' outOfRange=$outOfRange',
      );
      _brands = newBrands;
      if (!_orderEditMode) {
        _originalBrands = List<Brand>.from(newBrands);
      }
      // 편집 인덱스가 새 목록 범위를 벗어난 경우에만 편집을 취소한다.
      // 그 외 브랜드 갱신(외부 새로고침)으로는 편집이 취소되지 않도록 한다.
      if (outOfRange) {
        _cancelBrandNameEdit();
      }
    }
  }

  @override
  void dispose() {
    _brandNameEditController.removeListener(_handleBrandNameEditChanged);
    _brandNameEditController.dispose();
    _brandNameEditFocusNode.dispose();
    super.dispose();
  }

  Future<T?> _showBrandOverlayDialog<T>(
    Widget Function(BuildContext context, void Function(T? result) close)
    builder,
  ) async {
    debugLog(
      'brandSettings overlayDialog show type=$T mounted=$mounted '
      'editingIndex=$_editingIndex inserting=$_insertingBrand len=${_brands.length}',
    );
    final result = await showBlockingModelessOverlayDialog<T>(
      context: context,
      builder: builder,
    );
    debugLog(
      'brandSettings overlayDialog result type=$T result=$result mounted=$mounted',
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    // 예상치 못한 리빌드 원인 추적용. buildCell 보다 먼저 출력되면
    // 다이얼로그 전체가 리빌드된 것임(InheritedWidget 의존성 변화 등).
    debugLog(
      'brandSettingsDialog build editingIndex=$_editingIndex dialogHeight=$dialogHeight',
    );
    return BlockingModelessDialogFrame(
      title: '브랜드 설정',
      width: _dialogWidth,
      height: dialogHeight,
      closeIcon: const _BrandDialogCloseIcon(),
      onClose: widget.onClose,
      closeEnabled: !_submissionGate.submitting && !_applyingOrderChanges,
      footer: _orderEditMode ? _buildBrandOrderEditFooter() : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: EditableSwipeNameTable<Brand>(
                rows: _brands,
                header: '브랜드 이름',
                text: _brandNameText,
                editController: _brandNameEditController,
                editFocusNode: _brandNameEditFocusNode,
                editingIndex: _editingIndex,
                insertActionIndex: _insertActionIndex,
                inserting: _insertingBrand,
                canSubmit: _canSubmitBrandNameEdit,
                onToggleEdit: _toggleBrandNameEdit,
                onToggleInsert: _toggleBrandInsert,
                onEmptyInsert: _orderEditMode
                    ? null
                    : () => _startBrandInsertAt(0, actionIndex: null),
                onCancelEdit: _cancelBrandNameEdit,
                onSubmitEdit: _submitBrandNameEdit,
                onDeleteRow: _deleteBrand,
                onNameDoubleTap: _handleBrandNameDoubleTap,
                fillLastColumn: true,
                autoFitColumns: false,
                rowSwipeEnabled: !_orderEditMode,
                rowReorderEnabled: _orderEditMode,
                selectedIndex: _selectedBrandIndex,
                onRowSelected: _handleBrandRowSelected,
                onRowReorder: _moveBrandRow,
                enabled:
                    !_submissionGate.submitting &&
                    !_applyingOrderChanges &&
                    !_orderEditMode,
                keepRowContentOnSwipe: true,
                rowTooltip: _orderEditMode
                    ? '순서 변경 중에는 스와이프 수정/삽입/삭제를 사용할 수 없습니다'
                    : '행 드래그로 순서 변경, 컬럼 왼쪽 스와이프 수정/삽입/삭제',
                showActionsWhenEmpty: true,
                rowNumberText: _brandRowNumberText,
                headerTrailingBuilder: (context, hasInlineEditor) =>
                    _OrderModeHeaderButton(
                      enabled:
                          !_orderEditMode &&
                          !_submissionGate.submitting &&
                          !hasInlineEditor,
                      onPressed: _startBrandOrderEditMode,
                    ),
              ),
            ),
            if (_orderEditMode) ...[
              const SizedBox(width: 6),
              _buildBrandOrderMoveRail(),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasBrandOrderChanges {
    if (_brands.length != _originalBrands.length) return true;
    for (var index = 0; index < _brands.length; index += 1) {
      if (_brands[index].brandId != _originalBrands[index].brandId) {
        return true;
      }
    }
    return false;
  }

  int? get _selectedBrandIndex {
    final selectedBrandId = _selectedBrandId;
    if (selectedBrandId == null) return null;
    final index = _brands.indexWhere(
      (brand) => brand.brandId == selectedBrandId,
    );
    return index >= 0 ? index : null;
  }

  void _startBrandOrderEditMode() {
    if (_editingIndex != null ||
        _submissionGate.submitting ||
        _applyingOrderChanges ||
        _orderEditMode) {
      return;
    }
    setState(() {
      _orderEditMode = true;
      _selectedBrandId = _brands.isNotEmpty ? _brands.first.brandId : null;
    });
  }

  void _handleBrandRowSelected(Brand brand, int index) {
    if (!_orderEditMode || _applyingOrderChanges) return;
    setState(() => _selectedBrandId = brand.brandId);
  }

  void _moveBrandRow(int fromIndex, int toIndex) {
    if (!_orderEditMode ||
        _applyingOrderChanges ||
        fromIndex < 0 ||
        fromIndex >= _brands.length ||
        toIndex < 0 ||
        toIndex >= _brands.length) {
      return;
    }
    if ((fromIndex - toIndex).abs() == 1) {
      setState(() {
        final movingBrand = _brands[fromIndex];
        _brands[fromIndex] = _brands[toIndex];
        _brands[toIndex] = movingBrand;
        _selectedBrandId = movingBrand.brandId;
      });
      return;
    }
    final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
    if (insertIndex == fromIndex) return;
    setState(() {
      final brand = _brands.removeAt(fromIndex);
      _brands.insert(insertIndex, brand);
      _selectedBrandId = brand.brandId;
    });
  }

  void _moveSelectedBrandUp() {
    final index = _selectedBrandIndex;
    if (index == null || index <= 0) return;
    _moveBrandRow(index, index - 1);
  }

  void _moveSelectedBrandDown() {
    final index = _selectedBrandIndex;
    if (index == null || index >= _brands.length - 1) return;
    _moveBrandRow(index, index + 1);
  }

  void _cancelBrandOrderChanges() {
    if (_applyingOrderChanges) return;
    setState(() {
      _brands = List<Brand>.from(_originalBrands);
      _orderEditMode = false;
      _selectedBrandId = null;
    });
  }

  Widget _buildBrandOrderEditFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            '순서 변경',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            height: 30,
            child: _LabelSettingsFooterButton(
              label: '취소',
              onPressed: _applyingOrderChanges
                  ? null
                  : _cancelBrandOrderChanges,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 84,
            height: 30,
            child: _LabelSettingsFooterButton(
              label: '적용',
              onPressed: _applyingOrderChanges || !_hasBrandOrderChanges
                  ? null
                  : _applyBrandOrderChanges,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandOrderMoveRail() {
    final selectedIndex = _selectedBrandIndex;
    return SizedBox(
      width: 38,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OrderMoveButton(
            icon: Icons.keyboard_arrow_up,
            tooltip: '선택 행 위로 이동',
            enabled:
                !_applyingOrderChanges &&
                selectedIndex != null &&
                selectedIndex > 0,
            onPressed: _moveSelectedBrandUp,
          ),
          const SizedBox(height: 8),
          _OrderMoveButton(
            icon: Icons.keyboard_arrow_down,
            tooltip: '선택 행 아래로 이동',
            enabled:
                !_applyingOrderChanges &&
                selectedIndex != null &&
                selectedIndex < _brands.length - 1,
            onPressed: _moveSelectedBrandDown,
          ),
        ],
      ),
    );
  }

  Future<void> _applyBrandOrderChanges() async {
    if (_applyingOrderChanges || !_hasBrandOrderChanges) return;
    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: const Text('브랜드 순서 변경을 적용하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    setState(() => _applyingOrderChanges = true);
    try {
      await BrandDAO.updateOrders([
        for (var index = 0; index < _brands.length; index += 1)
          BrandOrderUpdate(
            brandId: _brands[index].brandId,
            brandOrder: index + 1,
          ),
      ]);
      if (!mounted) return;
      setState(() {
        _originalBrands = List<Brand>.from(_brands);
        _orderEditMode = false;
        _selectedBrandId = null;
      });
      widget.onBrandsCommitted(List<Brand>.from(_brands));
      try {
        final reloadedBrands = await _reloadBrandsChanged(
          updateSelection: false,
        );
        if (mounted) {
          setState(() {
            _brands = List<Brand>.from(reloadedBrands);
            _originalBrands = List<Brand>.from(reloadedBrands);
          });
        }
      } catch (error) {
        if (mounted) await _showBrandReloadFailureDialog();
      }
    } catch (error) {
      if (mounted) {
        await _showBrandOverlayDialog<void>(
          (dialogContext, close) => AlertDialog(
            title: const Text('브랜드 순서 저장 실패'),
            content: const Text('브랜드 순서 저장에 실패했습니다.'),
            actions: [
              TextButton(onPressed: () => close(null), child: const Text('확인')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applyingOrderChanges = false);
    }
  }

  static String _brandNameText(Brand brand) => brand.brandName;

  String _brandRowNumberText(Brand brand, int index) {
    if (!_insertingBrand) {
      return '${index + 1}';
    }
    final editingIndex = _editingIndex;
    if (editingIndex == null) {
      return '${index + 1}';
    }
    if (index == editingIndex) {
      return '';
    }
    if (index > editingIndex) {
      return '$index';
    }
    return '${index + 1}';
  }

  void _handleBrandNameDoubleTap(Brand brand, int index) {
    debugLog(
      'brandNameDoubleTap index=$index editingIndex=$_editingIndex busy=${widget.busyNotifier.value} brandId=${brand.brandId} name=${brand.brandName}',
    );
    if (_editingIndex != null ||
        widget.busyNotifier.value ||
        _submissionGate.submitting) {
      debugLog(
        'brandNameDoubleTap blocked editingIndex=$_editingIndex busy=${widget.busyNotifier.value}',
      );
      return;
    }
    debugLog('brandNameDoubleTap selectBrand brandId=${brand.brandId}');
    widget.onBrandSelected(brand);
  }

  void _toggleBrandInsert(Brand brand, int index) {
    if (_insertingBrand && _insertActionIndex == index) {
      debugLog('brandInsert cancelByToggle index=$index');
      _cancelBrandNameEdit();
      return;
    }
    _startBrandInsertAt(index + 1, actionIndex: index);
  }

  void _startBrandInsertAt(int index, {required int? actionIndex}) {
    if (_editingIndex != null) {
      debugLog(
        'brandInsert blocked editingIndex=$_editingIndex inserting=$_insertingBrand',
      );
      return;
    }
    final insertIndex = index.clamp(0, _brands.length);
    final customerId = Customer.instance?.customerId;
    if (customerId == null) {
      debugLog('brandInsert blocked customerId=null');
      return;
    }
    debugLog('brandInsert start index=$insertIndex customerId=$customerId');
    setState(() {
      _insertingBrand = true;
      _editingIndex = insertIndex;
      _insertActionIndex = actionIndex;
      _brands.insert(
        insertIndex,
        Brand(brandId: 0, customerId: customerId, brandName: ''),
      );
      _brandNameEditController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_insertingBrand || _editingIndex != insertIndex) {
        debugLog(
          'brandInsert focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$insertIndex inserting=$_insertingBrand',
        );
        return;
      }
      debugLog('brandInsert focusRequest index=$insertIndex');
      _brandNameEditFocusNode.requestFocus();
    });
  }

  void _toggleBrandNameEdit(Brand brand, int index) {
    if (_insertingBrand) {
      debugLog('brandNameEdit blocked inserting=true index=$index');
      return;
    }
    if (_editingIndex == index) {
      debugLog('brandNameEdit cancelByToggle index=$index');
      _cancelBrandNameEdit();
      return;
    }
    debugLog(
      'brandNameEdit start index=$index brandId=${brand.brandId} name=${brand.brandName}',
    );
    setState(() {
      _editingIndex = index;
      // .text 와 .selection 을 따로 할당하면 리스너가 두 번 발생한다.
      // .value 에 TextEditingValue 를 한 번에 설정해 리스너를 1회만 발생시킨다.
      _brandNameEditController.value = TextEditingValue(
        text: brand.brandName,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: brand.brandName.length,
        ),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingIndex != index) {
        debugLog(
          'brandNameEdit focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$index',
        );
        return;
      }
      debugLog('brandNameEdit focusRequest index=$index');
      _brandNameEditFocusNode.requestFocus();
    });
  }

  void _cancelBrandNameEdit() {
    if (_editingIndex == null) {
      return;
    }
    debugLog(
      'brandNameEdit cancelled index=$_editingIndex text=${_brandNameEditController.text}',
    );
    // 포커스를 명시적으로 해제하지 않으면 FocusNode 가 트리에서 분리된 후에도
    // 포커스를 유지해 이후 키보드 입력이 소실될 수 있다.
    _brandNameEditFocusNode.unfocus();
    setState(() {
      if (_insertingBrand && _editingIndex! < _brands.length) {
        _brands.removeAt(_editingIndex!);
      }
      _insertingBrand = false;
      _insertActionIndex = null;
      _editingIndex = null;
      _brandNameEditController.clear();
    });
  }

  void _handleBrandNameEditChanged() {
    if (_editingIndex == null || !mounted) {
      return;
    }
    debugLog(
      'brandNameEdit textChanged index=$_editingIndex text=${_brandNameEditController.text} canSubmit=$_canSubmitBrandNameEdit',
    );
    setState(() {});
  }

  bool get _canSubmitBrandNameEdit {
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _brands.length) {
      return false;
    }
    if (_submissionGate.submitting) {
      return false;
    }
    final nextName = _brandNameEditController.text.trim();
    if (nextName.isEmpty) {
      return false;
    }
    if (_insertingBrand) {
      return true;
    }
    return nextName != _brands[editingIndex].brandName.trim();
  }

  Future<List<Brand>> _reloadBrandsChanged({
    Brand? selectedBrand,
    required bool updateSelection,
  }) {
    return widget.onBrandsChanged(
      preferredSelectedBrand: selectedBrand,
      updateSelection: updateSelection,
    );
  }

  Future<void> _submitBrandNameEdit(String value) async {
    debugLog(
      'brandNameEdit submit index=$_editingIndex value=$value canSubmit=$_canSubmitBrandNameEdit',
    );
    if (!_canSubmitBrandNameEdit) {
      debugLog('brandNameEdit submitSkipped canSubmit=false');
      return;
    }
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _brands.length) {
      debugLog(
        'brandNameEdit submitSkipped editingIndex=$editingIndex outOfRange',
      );
      return;
    }
    await _submissionGate.run(() async {
      if (mounted) setState(() {});
      if (_insertingBrand) {
        await _insertBrandName(editingIndex, value.trim());
        return;
      }
      await _updateBrandName(_brands[editingIndex], value.trim());
    });
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _insertBrandName(int insertIndex, String brandName) async {
    final customerId = Customer.instance?.customerId;
    debugLog(
      'insertBrandName start index=$insertIndex customerId=$customerId name=$brandName',
    );
    if (!_insertingBrand ||
        _editingIndex != insertIndex ||
        customerId == null) {
      debugLog(
        'insertBrandName aborted inserting=$_insertingBrand editingIndex=$_editingIndex expected=$insertIndex customerId=$customerId',
      );
      return;
    }

    debugLog(
      'insertBrandName confirmDialog show index=$insertIndex name=$brandName',
    );
    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'$brandName' 브랜드를 추가하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
    debugLog(
      'insertBrandName confirmDialog result=$confirmed index=$insertIndex',
    );

    if (!mounted) {
      debugLog('insertBrandName aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog(
        'insertBrandName cancelledByUser index=$insertIndex keepEditing',
      );
      _brandNameEditFocusNode.requestFocus();
      return;
    }

    Brand? inserted;
    try {
      final reloadError = await runSettingsWriteThenReload<Brand>(
        write: () =>
            BrandDAO.insertByBrandName(customerId, brandName, insertIndex + 1),
        onCommitted: (value) {
          inserted = value;
          if (!mounted) return;
          setState(() {
            _brands[insertIndex] = value;
            _insertingBrand = false;
            _insertActionIndex = null;
            _editingIndex = null;
            _brandNameEditController.clear();
          });
          widget.onBrandsCommitted(List<Brand>.from(_brands));
        },
        reload: (value) async {
          final reloadedBrands = await _reloadBrandsChanged(
            selectedBrand: value,
            updateSelection: false,
          );
          if (mounted) {
            setState(() => _brands = List<Brand>.from(reloadedBrands));
          }
        },
      );
      if (reloadError != null && mounted) {
        debugLog(
          'insertBrandName reload failed index=$insertIndex error=$reloadError',
        );
        await _showBrandReloadFailureDialog();
      }
    } catch (e) {
      debugLog('insertBrandName failed index=$insertIndex error=$e');
      if (mounted) {
        await _showBrandOverlayDialog<void>(
          (dialogContext, close) => AlertDialog(
            title: const Text('브랜드 추가 실패'),
            content: const Text('브랜드 추가에 실패했습니다.'),
            actions: [
              TextButton(onPressed: () => close(null), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) {
          _brandNameEditFocusNode.requestFocus();
        }
      }
      return;
    }

    final committed = inserted!;
    debugLog(
      'insertBrandName done brandId=${committed.brandId} index=$insertIndex name=${committed.brandName}',
    );
  }

  Future<void> _updateBrandName(Brand brand, String brandName) async {
    final editingIndex = _editingIndex;
    debugLog(
      'updateBrandName start editingIndex=$editingIndex '
      'brandId=${brand.brandId} old=${brand.brandName} new=$brandName',
    );

    if (editingIndex == null || editingIndex >= _brands.length) {
      debugLog('updateBrandName aborted editingIndex=null or out of range');
      return;
    }

    debugLog(
      'updateBrandName confirm dialog brandId=${brand.brandId} old=${brand.brandName} new=$brandName',
    );

    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'$brandName' 명으로 변경하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );

    if (!mounted) {
      debugLog('updateBrandName aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      // 확인 다이얼로그에서 취소 → 편집 모드를 유지한다.
      // 사용자가 입력한 내용을 보존해 다시 수정하거나 ESC/Enter 로 직접 닫을 수 있도록 한다.
      debugLog(
        'updateBrandName cancelledByUser brandId=${brand.brandId} keepEditing',
      );
      _brandNameEditFocusNode.requestFocus();
      return;
    }

    debugLog(
      'updateBrandName confirmed brandId=${brand.brandId} old=${brand.brandName} new=$brandName',
    );
    try {
      await BrandDAO.updateByBrandId(brand, brandName);
    } catch (e) {
      debugLog('updateBrandName failed brandId=${brand.brandId} error=$e');
      if (mounted) {
        await _showBrandOverlayDialog<void>(
          (dialogContext, close) => AlertDialog(
            title: const Text('브랜드 이름 변경 실패'),
            content: const Text('브랜드 이름 변경에 실패했습니다.'),
            actions: [
              TextButton(onPressed: () => close(null), child: const Text('확인')),
            ],
          ),
        );
        if (mounted) {
          _brandNameEditFocusNode.requestFocus();
        }
      }
      return;
    }

    if (!mounted) return;
    final updatedBrand = Brand(
      brandId: brand.brandId,
      customerId: brand.customerId,
      brandName: brandName,
    );
    setState(() {
      _brands[editingIndex] = updatedBrand;
      _editingIndex = null;
      _brandNameEditController.clear();
    });
    widget.onBrandsCommitted(List<Brand>.from(_brands));

    try {
      final reloadedBrands = await _reloadBrandsChanged(
        selectedBrand: updatedBrand,
        updateSelection: widget.selectedBrand?.brandId == updatedBrand.brandId,
      );
      if (mounted) {
        setState(() => _brands = List<Brand>.from(reloadedBrands));
      }
    } catch (e) {
      debugLog(
        'updateBrandName reload failed brandId=${brand.brandId} error=$e',
      );
      if (mounted) {
        await _showBrandReloadFailureDialog();
      }
    }

    debugLog(
      'updateBrandName done brandId=${brand.brandId} newName=$brandName',
    );
  }

  Future<void> _showBrandReloadFailureDialog() {
    return _showBrandOverlayDialog<void>(
      (dialogContext, close) => AlertDialog(
        title: const Text('브랜드 목록 갱신 실패'),
        content: const Text('저장은 완료됐지만 브랜드 목록 갱신에 실패했습니다.'),
        actions: [
          TextButton(onPressed: () => close(null), child: const Text('확인')),
        ],
      ),
    );
  }

  Future<void> _deleteBrand(Brand brand, int index) async {
    debugLog(
      'deleteBrand start index=$index brandId=${brand.brandId} name=${brand.brandName} editingIndex=$_editingIndex',
    );
    if (_editingIndex != null || index < 0 || index >= _brands.length) {
      debugLog(
        'deleteBrand aborted editingIndex=$_editingIndex index=$index len=${_brands.length}',
      );
      return;
    }

    debugLog('deleteBrand confirmDialog show brandId=${brand.brandId}');
    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'${brand.brandName}' 브랜드를 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          TextButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
    debugLog(
      'deleteBrand confirmDialog result=$confirmed brandId=${brand.brandId}',
    );

    if (!mounted) {
      debugLog('deleteBrand aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog('deleteBrand cancelledByUser brandId=${brand.brandId}');
      return;
    }

    await _submissionGate.run(() async {
      if (mounted) setState(() {});
      try {
        await BrandDAO.deleteByBrandId(brand);
      } catch (e) {
        debugLog('deleteBrand failed brandId=${brand.brandId} error=$e');
        if (mounted) {
          await _showBrandOverlayDialog<void>(
            (dialogContext, close) => AlertDialog(
              title: const Text('브랜드 삭제 실패'),
              content: const Text('브랜드 삭제에 실패했습니다.'),
              actions: [
                TextButton(
                  onPressed: () => close(null),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final currentIndex = _brands.indexWhere(
        (value) => value.brandId == brand.brandId,
      );
      if (currentIndex < 0) return;
      final wasSelected = widget.selectedBrand?.brandId == brand.brandId;
      final nextSelectedBrand = wasSelected
          ? _resolveBrandAfterDelete(currentIndex)
          : widget.selectedBrand;
      setState(() => _brands.removeAt(currentIndex));
      widget.onBrandsCommitted(List<Brand>.from(_brands));

      try {
        final reloadedBrands = await _reloadBrandsChanged(
          selectedBrand: nextSelectedBrand,
          updateSelection: wasSelected,
        );
        if (!mounted) return;
        setState(() => _brands = List<Brand>.from(reloadedBrands));
        debugLog(
          'deleteBrand done brandId=${brand.brandId} index=$currentIndex',
        );
      } catch (e) {
        debugLog('deleteBrand reload failed brandId=${brand.brandId} error=$e');
        if (mounted) {
          await _showBrandReloadFailureDialog();
        }
      }
    });
    if (mounted) setState(() {});
  }

  Brand? _resolveBrandAfterDelete(int deletedIndex) {
    final nextBrands = List<Brand>.from(_brands)..removeAt(deletedIndex);
    if (nextBrands.isEmpty) {
      return null;
    }
    final nextIndex = deletedIndex < nextBrands.length
        ? deletedIndex
        : nextBrands.length - 1;
    return nextBrands[nextIndex];
  }
}

class _BrandDialogCloseIcon extends StatelessWidget {
  const _BrandDialogCloseIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _BrandDialogCloseIconPainter(),
    );
  }
}

class _BrandDialogCloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glyphRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 11,
      height: 11,
    );
    final paint = Paint()
      ..color = const Color(0xff9a9a9a)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(glyphRect.topLeft, glyphRect.bottomRight, paint);
    canvas.drawLine(glyphRect.topRight, glyphRect.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _BrandDialogCloseIconPainter oldDelegate) {
    return false;
  }
}
