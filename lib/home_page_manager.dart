import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' show max, min, pi;

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:tabbed_view/tabbed_view.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/auto_login_guard.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/column_special.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/gs1_ai.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft_backup.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_manager_save.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/last_connect.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_ai_import_temp.dart';
import 'package:label_manager/page_label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview_debug.dart';
import 'package:label_manager/utils/debug_logger.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/item_manager_debug_log.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/page_home/item_manage.dart';
import 'package:label_manager/page_home/item_code_data_resolver.dart';
import 'package:label_manager/page_home/item_manager_xlsx.dart';
import 'package:label_manager/page_home/date_type_setup_dialog.dart';
import 'package:label_manager/page_home/item_order_dialog.dart';
import 'package:label_manager/page_home/common_label_manage.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

bool itemManagerSearchVisibleForTab(Object? tabValue) => tabValue == 'items';

const Duration itemManagerLoadProgressDuration = Duration(days: 1);
const String itemManagerLoadFailureMessage =
    '품목 데이터를 불러오지 못했습니다. 네트워크 연결을 확인한 뒤 다시 시도해 주세요.';

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

/// 로그인 이후 메인 UI
class HomePageManager extends StatefulWidget {
  final Brand? selectedBrand;
  final ValueChanged<Brand?> onBrandChanged;
  final LabelSize? selectedLabelSize;
  final ValueChanged<LabelSize?> onLabelSizeChanged;
  final ValueChanged<bool>? onItemDraftDirtyChanged;

  const HomePageManager({
    super.key,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.selectedLabelSize,
    required this.onLabelSizeChanged,
    this.onItemDraftDirtyChanged,
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
  final TextEditingController _tabSearchController = TextEditingController();
  final ItemManageController _itemManageController = ItemManageController();
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
  Timer? _rtfPreviewResizeDebounce;
  Timer? _rtfPreviewResizeFinalizeTimer;
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
  ItemManagerDraftBackupStore? _itemDraftBackup;
  List<int> _itemDraftTargetMarketIds = const [];
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
  final ItemElementCommitQueue _itemElementCommitQueue =
      ItemElementCommitQueue();
  bool _lastReportedItemDraftDirty = false;
  int _labelSetupRevision = 0;
  bool _suppressNextBrandDidUpdateLabelLoad = false;
  int _itemDraftCancelTraceSequence = 0;
  int? _lastItemDraftCancelTraceId;

  static const String _itemDraftCancelDebugVersion =
      'item-draft-cancel-debug-v1';

  OverlayEntry? _brandSettingsOverlayEntry;
  OverlayEntry? _labelSettingsOverlayEntry;
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
    widget.onItemDraftDirtyChanged?.call(dirty);
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
    _handleItemDraftDirtyChanged();
  }

  Future<ItemManagerDraftBackupStore> _ensureItemDraftBackup() async {
    final backup = _itemDraftBackup;
    final controller = _itemDraftController;
    if (backup == null || controller == null) {
      throw StateError('품목관리 임시 백업 세션이 없습니다.');
    }
    await backup.start(
      selectedRowKeys: controller.baselineSelectedRowKeys,
      anchorRowKey: controller.baselineAnchorRowKey,
    );
    return backup;
  }

  Future<void> _backupItemName(ItemManagerDraftRow row) async {
    if (row.sourceItemId == null) return;
    await (await _ensureItemDraftBackup()).captureItemName(row);
  }

  Future<void> _backupItemColumn(
    ItemManagerDraftRow row,
    int columnId,
  ) async {
    if (row.sourceItemId == null) return;
    final controller = _itemDraftController!;
    await (await _ensureItemDraftBackup()).captureCells(
      row: row,
      columnIds: controller.affectedColumnIds(columnId),
      columnContents: controller.scopedColumnContents,
    );
  }

  Future<void> _backupItemOrders(Iterable<ItemManagerDraftRow> rows) async {
    if (!rows.any((row) => row.sourceItemId != null)) return;
    await (await _ensureItemDraftBackup()).captureOrders(rows);
  }

  Future<void> _backupDeletedItemRows(
    Iterable<ItemManagerDraftRow> rows,
  ) async {
    if (!rows.any((row) => row.sourceItemId != null)) return;
    await (await _ensureItemDraftBackup()).captureDeletedRows(
      rows: rows,
      columnContents: _itemDraftController!.scopedColumnContents,
    );
  }

  Future<void> _recordAddedItemRows(Iterable<String> rowKeys) async {
    await (await _ensureItemDraftBackup()).recordAddedRows(rowKeys);
  }

  LabelSize? get _effectiveLabelSize => _currentLabelSize;
  String get _labelContentKey {
    final labelSize = _effectiveLabelSize;
    return '${labelSize?.labelSizeId ?? 'none'}:'
        '${labelSize?.labelSizeCommon?.width ?? 0}:'
        '${labelSize?.labelSizeCommon?.height ?? 0}:'
        '$_labelSetupRevision';
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _loadBrands();
    });
  }

  @override
  void didUpdateWidget(covariant HomePageManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLabelSize?.labelSizeId !=
        widget.selectedLabelSize?.labelSizeId) {
      _currentLabelSize = widget.selectedLabelSize;
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
        await TColumnType.init();
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
    widget.onBrandChanged(brand);
  }

  Future<void> _handleHeaderLabelSizeChanged(LabelSize? labelSize) async {
    await _handleLabelSizeChanged(labelSize, skipDraftContextGuard: true);
  }

  // 브랜드 설정 다이얼로그에서의 명시적 브랜드 선택(더블클릭)은 사용자의 의도적
  // 행위이므로 자동로그인 가드(_isAutoLoginMode)와 무관하게 반영한다.
  // 근거: .tmp/log/app_2026-07-01_17-13-52.log — 더블탭/핸들러는 정상 도달하나
  // _handleBrandChanged 의 autoLogin=true 가드에서 선택이 무시되어 무반응이었음.
  void _handleBrandSelectedFromDialog(Brand? brand) {
    if (_blockItemDraftContextChange()) return;
    _brandDialogBusyNotifier.value = true;
    widget.onBrandChanged(brand);
  }

  Future<void> _handleBrandChangedFromLabelDialog(Brand? brand) async {
    debugLog(
      'labelSettings brandChanged brandId=${brand?.brandId} name=${brand?.brandName}',
    );
    if (_blockItemDraftContextChange()) return;
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

      if (!forceReload &&
          !skipDraftContextGuard &&
          labelSize?.labelSizeId != _currentLabelSize?.labelSizeId &&
          _blockItemDraftContextChange()) {
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
        await _itemDraftBackup?.close();
        _itemDraftBackup = null;
        _disposeItemDraftController();
        _itemDraftTargetMarketIds = const [];
        _itemDraftEmptyElementPayload = '';
        _currentLabelSize = null;
        _rtfPreviewReadyKey = null;
        _commonLabelTabActivated = false;
        _commonLabelPreviewClosedByUser = false;
        widget.onLabelSizeChanged(null);
        ItemOfMarket.datas = <ItemOfMarket>[];
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
      final user = User.instance;
      if (customer == null || market == null || user == null) {
        throw StateError('품목관리 편집 세션의 로그인 정보가 없습니다.');
      }
      if (market.customerId != customer.customerId) {
        throw StateError('현재 거래처와 로그인 고객 정보가 일치하지 않습니다.');
      }
      final targetMarkets =
          await MarketDAO.selectByCustomerId(customer.customerId) ??
          const <Market>[];
      if (targetMarkets.isEmpty ||
          !targetMarkets.any((value) => value.marketId == market.marketId)) {
        throw StateError('저장 대상 market 목록에서 현재 market을 찾을 수 없습니다.');
      }
      final targetMarketIds = targetMarkets
          .map((value) => value.marketId)
          .toList(growable: false);
      final columns =
          await TColumnDAO.selectByLabelSizeId(labelSize.labelSizeId) ??
          const <TColumn>[];
      final specialColumns =
          await TColumnSpecial.selectByLabelSizeId(labelSize.labelSizeId) ??
          const <TColumnBase>[];
      final items =
          await ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId(
            Market.instance!.marketId,
            labelSize.labelSizeId,
          ) ??
          const <ItemOfMarket>[];
      final rawSnapshots =
          await ItemOfMarketDAO.selectRawSnapshotsByMarketAndLabelSizeId(
            market.marketId,
            labelSize.labelSizeId,
          ) ??
          const <ItemOfMarketRawSnapshot>[];
      final scopedColumnContents =
          await TColumnContentDAO.selectScopedByItemIds(
            items.map((item) => item.item.itemId),
          );
      final nextController = ItemManagerDraftController.fromItems(
        items: items,
        rawSnapshots: {
          for (final snapshot in rawSnapshots) snapshot.itemId: snapshot,
        },
        scopedColumnContents: scopedColumnContents,
        validationRules: [
          for (final column in columns)
            ItemManagerColumnValidationRule(
              columnId: column.columnId,
              columnName: column.columnName,
              typeCode: column.columnType.code,
              required: column.useMissingKeywordCheck,
              barcodeType: column.barcodeType,
              useBarcodeCheckDigit: column.useBarcodeCheckDigit,
              useDateRange: column.useDateRange,
              dateRange: column.dateRange,
              gs1Definition: _itemManagerGs1Definition(column),
              timeBarcodeType: column.timeBarcodeType,
            ),
        ],
        requireElement:
            specialColumns
                .firstWhereOrNull(
                  (column) =>
                      column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword,
                )
                ?.useMissingKeywordCheck ==
            true,
        labelSizeName: labelSize.labelSizeName,
      );
      final emptyElementPayload = labelSheetEncodeWorkbookSave(
        _itemElementWorkbook('', labelSize),
      );

      try {
        await _itemDraftBackup?.close();
      } catch (_) {
        nextController.dispose();
        rethrow;
      }
      _itemDraftBackup = null;
      _disposeItemDraftController();
      _currentLabelSize = labelSize;
      _itemDraftTargetMarketIds = targetMarketIds;
      _rtfPreviewReadyKey = null;
      _commonLabelTabActivated = false;
      _itemPreviewClosedByUser = false;
      _commonLabelPreviewClosedByUser = false;
      TColumn.datas = columns;
      TColumnContent.datas = scopedColumnContents.values;
      TColumnSpecial.datas = specialColumns;
      ItemOfMarket.datas = items;
      widget.onLabelSizeChanged(labelSize);
      _itemDraftController = nextController;
      _itemDraftController!.addListener(_handleItemDraftDirtyChanged);
      _itemDraftEmptyElementPayload = emptyElementPayload;
      _itemDraftBackup = ItemManagerDraftBackupStore(
        metadata: ItemManagerDraftBackupMetadata(
          draftKey: itemManagerDraftKey(
            userId: user.userId,
            customerId: customer.customerId,
            brandId: labelSize.brandId,
            labelSizeId: labelSize.labelSizeId,
          ),
          userId: user.userId,
          customerId: customer.customerId,
          brandId: labelSize.brandId,
          labelSizeId: labelSize.labelSizeId,
          currentMarketId: market.marketId,
        ),
      );
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
          'items': items.length,
          'columns': columns.length,
          'contents': scopedColumnContents.values.length,
          'targetMarkets': targetMarketIds.length,
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

    bool get _itemDraftContextChangeBlocked =>
      _itemDraftCommandBusy || _itemDraftController?.isDirty == true;

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
      try {
        _logItemDraftCancelDebug(
          'cancel branch=sqlite restore start backup=${_itemDraftBackup != null}',
          traceId: traceId,
        );
        final backup = _itemDraftBackup;
        if (backup == null) {
          throw StateError('변경 취소용 SQLite 백업이 없습니다.');
        }
        final snapshot = await backup.readSnapshot();
        controller.restoreBackup(
          fullImport: snapshot.mode == ItemManagerDraftBackupMode.fullImport,
          itemNames: snapshot.itemNames,
          elements: snapshot.elements,
          cells: snapshot.cells,
          orders: snapshot.orders,
          addedRowKeys: snapshot.addedRowKeys,
          deletedRows: snapshot.deletedRows,
          deletedColumns: snapshot.deletedColumns,
          selectedRowKeys: snapshot.selectedRowKeys,
          anchorRowKey: snapshot.anchorRowKey,
        );
        await backup.clear();
        _logItemDraftCancelDebug(
          'cancel branch=sqlite restore completed',
          traceId: traceId,
        );
      } catch (error) {
        debugLog(
          '[$_itemDraftCancelDebugVersion] trace=$traceId '
          'event=sqlite restore failed error=$error',
        );
        if (mounted) _showItemDraftError('변경 취소 실패', error);
        return;
      }
      final anchorRowKey = controller.anchorRowKey;
      final selectedIndex = anchorRowKey == null
          ? -1
          : controller.rows.indexWhere((row) => row.rowKey == anchorRowKey);
      if (selectedIndex >= 0) {
        _selectedItemIndex = selectedIndex;
        _selectedItemOfMarket = controller.rows[selectedIndex].source;
      } else {
        _selectedItemIndex = null;
        _selectedItemOfMarket = null;
      }
      _resetTabs();
      setState(() {});
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

    final selectedKey = controller.anchorRowKey;
    final selectedRowIndex = selectedKey == null
        ? -1
        : controller.rows.indexWhere((row) => row.rowKey == selectedKey);
    final selectedRow = selectedRowIndex < 0
        ? null
        : controller.rows[selectedRowIndex];
    setState(() => _itemDraftCommandBusy = true);
    var dbSaveCompleted = false;
    try {
      final command = controller.toSaveCommand(
        labelSizeId: labelSize.labelSizeId,
        targetMarketIds: _itemDraftTargetMarketIds,
      );
      ItemManagerDebugLog.event(
        'save',
        'commandBuilt',
        trace: trace,
        fields: {
          'existing': command.existingRows.length,
          'new': command.newRows.length,
          'deleted': command.deletedSourceItemIds.length,
          'columns': command.columnValues.length,
          'targetMarkets': command.targetMarketIds.length,
        },
      );
      final result = await ItemManagerSaveDAO.save(command);
      dbSaveCompleted = true;
      try {
        await _itemDraftBackup?.clear();
      } catch (error, stackTrace) {
        DebugLogger.log(
          'Item draft backup cleanup failed after DB save: '
          '$error\n$stackTrace',
        );
      }
      ItemManagerDebugLog.event(
        'save',
        'transactionCompleted',
        trace: trace,
        fields: {'inserted': result.insertedItemIdsByDraftKey.length},
      );
      final selectedItemId = resolveItemManagerSavedSelectionItemId(
        selectedRow: selectedRow,
        insertedItemIdsByDraftKey: result.insertedItemIdsByDraftKey,
      );
      final reloaded = await _reloadItemDraftFromDatabase(
        selectedItemId: selectedItemId,
        fallbackIndex: selectedRowIndex < 0 ? null : selectedRowIndex,
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
      await (await _ensureItemDraftBackup()).captureFullImport(controller);
      final imported = controller.replaceAllWithImportedRows(
        result.rows,
        importViewState: ItemManagerImportViewState(
          selectedItemId: _selectedItemOfMarket?.item.itemId,
          selectedIndex: _selectedItemIndex,
        ),
      );
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
    if (controller == null || controller.isDirty || _itemDraftCommandBusy) {
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
      final storedItems =
          await ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId(
            market.marketId,
            labelSize.labelSizeId,
          ) ??
          const <ItemOfMarket>[];
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
      await ItemDAO.updateOrders([
        for (var index = 0; index < ordered.length; index++)
          ItemOrderUpdate(itemId: ordered[index].item.itemId, order: index + 1),
      ]);
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

  void _resetTabs() {
    final selectedTabValue = _selectedTabValue();
    debugLog(
      'selectedTabValue=$selectedTabValue, '
      'labelContentKey=$_labelContentKey, items=${ItemOfMarket.datas?.length ?? 0}',
    );
    _tabController = _createTabController();
    _restoreSelectedTab(selectedTabValue);
    setState(() {});
    _syncPreviewWindowWithSelectedTab();
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
    _resetTabs();
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
    if (selectedTab?.value == 'items') {
      _showItemPreviewWindow();
    } else if (selectedTab?.value == 'common_label') {
      if (_activateCommonLabelTabIfNeeded()) {
        return;
      }
      _showRtfPreviewWindow();
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
    if (tab?.value != 'items' && _blockItemDraftContextChange()) {
      final itemIndex = _tabs.indexWhere(
        (candidate) => candidate.value == 'items',
      );
      if (itemIndex >= 0 && _tabController.selectedIndex != itemIndex) {
        _tabController.selectedIndex = itemIndex;
      }
      _showItemPreviewWindow();
      _logItemDraftCancelDebug(
        'tabSelection reverted requested=${tab?.value} itemIndex=$itemIndex',
        traceId: _lastItemDraftCancelTraceId,
      );
      return;
    }
    if (tab?.value == 'items') {
      _showItemPreviewWindow();
    } else if (tab?.value == 'common_label') {
      if (_activateCommonLabelTabIfNeeded()) {
        return;
      }
      _showRtfPreviewWindow();
    } else {
      _hideFloatingWindows();
    }
    if (mounted) {
      setState(() {});
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

  List<TabData> _buildTabs() {
    final itemManagerReadyGeneration = _itemManagerReadyGeneration;
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
          onReady: () =>
            _handleItemManagerReady(itemManagerReadyGeneration),
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
          onBeforeItemNameChange: _backupItemName,
          onBeforeColumnChange: _backupItemColumn,
          onBeforeRowsReordered: _backupItemOrders,
          onBeforeRowsDeleted: _backupDeletedItemRows,
          onRowsAdded: _recordAddedItemRows,
          commandBusy: _itemDraftCommandBusy,
          canEdit: User.instance?.canManageItemStructure == true,
        ),
        closable: false,
        keepAlive: true,
      ),
      if (User.instance?.canAccessCommonLabelManagement == true)
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
                )
              : const SizedBox.shrink(),
          closable: false,
          keepAlive: true,
        ),
      TabData(
        value: 'label_print',
        text: '라벨출력(F3)',
        content: const _PlaceholderTab(title: '라벨출력'),
        closable: false,
        keepAlive: true,
      ),
      TabData(
        value: 'auto_update',
        text: '자동품목갱신',
        content: const _PlaceholderTab(title: '자동품목갱신'),
        closable: false,
        keepAlive: true,
      ),
      TabData(
        value: 'scale_output',
        text: '저울출력',
        content: const _PlaceholderTab(title: '저울출력'),
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
      if (_selectedTabValue() != 'items') return;
      _commonLabelPreviewWindow?.hide();
      final selected = _selectedItemOfMarket;
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
        rowIdentity:
            _itemDraftController?.anchorRowKey ??
            'item:${selected.item.itemId}',
        labelSize: _effectiveLabelSize,
        onElementCommitted: _commitItemElementDraft,
        canSelectOutputPreview: () => !_blockItemDraftContextChange(),
        canEdit:
          User.instance?.canEditItemDetails == true &&
          !_itemDraftCommandBusy,
      );
      if (_itemPreviewWindow == null) {
        _itemPreviewAlignedToTable = false;
        _itemPreviewWindow = PreviewFloatingWindow(
          initialSize: const Size(670, 470),
          minSize: const Size(420, 280),
          onCloseRequested: _handleItemPreviewCloseRequested,
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
    final row = controller.rows.firstWhere((row) => row.rowKey == rowKey);
    if (row.sourceItemId != null) {
      await (await _ensureItemDraftBackup()).captureElement(row);
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
    if (_selectedTabValue() != 'items') return;
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
        headerAction: _RtfPreviewAiConvertButton(
          onPressed: () => unawaited(_handleRtfPreviewAiConvert()),
        ),
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
    final readyCompleter = _itemManagerReadyCompleter;
    if (readyCompleter != null && !readyCompleter.isCompleted) {
      readyCompleter.complete();
    }
    widget.onItemDraftDirtyChanged?.call(false);
    unawaited(_itemDraftBackup?.close() ?? Future<void>.value());
    _itemDraftController?.removeListener(_handleItemDraftDirtyChanged);
    _itemDraftController?.dispose();
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeFinalizeTimer?.cancel();
    _itemPreviewWindow?.dispose();
    _commonLabelPreviewWindow?.dispose();
    _tabController.dispose();
    _tabSearchController.dispose();
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
    _labelSettingsOverlayEntry?.remove();
    _labelSettingsOverlayEntry = null;
    _brandDialogBusyNotifier.dispose();
    super.dispose();
  }

  Future<void> _onTabSearch() async {
    final query = _tabSearchController.text.trim();
    if (query.isEmpty || _selectedTabValue() != 'items') return;
    final result = _itemManageController.search(query);
    if (result == ItemManageSearchResult.found || !mounted) return;
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
    if (restart == true) _itemManageController.resetSearch();
  }

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
          if (itemManagerSearchVisibleForTab(_selectedTabValue())) ...[
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
                    Icons.search,
                    size: lmSize(14),
                    color: onButtonColor,
                  ),
                  label: Text(
                    '검색',
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
    final selected = _selectedTabValue() == 'items';
    final window = _itemPreviewWindow;
    final shouldShow =
        selected &&
        _itemPreviewClosedByUser &&
        window != null &&
        !window.isVisible;
    final shouldKeepSlot = selected && window != null;
    final button = _PreviewRestoreButton(
      key: _itemPreviewButtonKey,
      visible: shouldShow,
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
    final settingsEnabled = _selectedTabValue() == 'common_label';
    final dateSettingsEnabled = _itemManagerDateSettingsEnabled(
      selectedTabValue: _selectedTabValue(),
      hasDateSetup: resolvedLabel?.labelSizeSetup != null,
      commandBusy: _itemDraftCommandBusy,
      draftDirty: _itemDraftController?.isDirty == true,
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
              dropdownChangeBlocked: _itemDraftContextChangeBlocked,
              onBlockedDropdownTap: _blockItemDraftContextChange,
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
              child: Column(children: [Expanded(child: tabbedView)]),
            ),
          ),
        ),
      ],
    );
    return result;
  }
}

class _PreviewRestoreButton extends StatefulWidget {
  const _PreviewRestoreButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
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
    );
  }
}

class _TopControlArea extends StatelessWidget {
  final ValueChanged<Brand?> onBrandChanged;
  final ValueChanged<LabelSize?> onLabelSizeChanged;
  final ValueChanged<bool> onDropdownMenuStateChanged;
  final bool dropdownChangeBlocked;
  final VoidCallback onBlockedDropdownTap;
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
                        SizedBox(width: lmSize(6)),
                        SizedBox(
                          height: lmSize(36),
                          child: OutlinedButton(
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
                    contentPadding: lmInsetsSymmetric(horizontal: 4, vertical: 10),
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

Gs1AiDefinition? _itemManagerGs1Definition(TColumn column) {
  if (column.columnType.code != TColumnType.TYPE_GS1_AI) return null;
  final ai = column.gs1ai;
  final definitionCode = column.formatOption == -1
      ? ai
      : ai.length >= 2
      ? ai.substring(0, ai.length - 1)
      : '';
  return Gs1AiDefinitions.values[definitionCode];
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title (준비 중)'));
  }
}

class _RtfPreviewAiConvertButton extends StatefulWidget {
  const _RtfPreviewAiConvertButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RtfPreviewAiConvertButton> createState() =>
      _RtfPreviewAiConvertButtonState();
}

class _RtfPreviewAiConvertButtonState
    extends State<_RtfPreviewAiConvertButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _pressed
        ? const Color(0xFF9AA0A6)
        : _hovered
        ? const Color(0xFFDADCE0)
        : Colors.transparent;
    final textColor = _pressed
        ? const Color(0xFF202124)
        : _hovered
        ? const Color(0xFF3C4043)
        : const Color(0xFF5F6368);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: true,
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
        child: SizedBox(
          height: 14,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              'AI 변환',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
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
    this.canEdit = true,
  });

  final ItemOfMarket item;
  final String rowIdentity;
  final LabelSize? labelSize;
  final Future<void> Function(
    String rowIdentity,
    String elementPlain,
    String elementPayload,
  ) onElementCommitted;
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
          .catchError((
        Object error,
        StackTrace stackTrace,
      ) {
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
      imageObjectIds: resolvedImageObjectIds,
      barcodeObjectIds: resolvedBarcodeObjectIds,
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
    required this.canEdit,
    required this.onWorkbookChanged,
    required this.onSave,
  });

  final ItemOfMarket item;
  final LabelSize? labelSize;
  final _ItemElementFormState elementForm;
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
      zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
      onUserWorkbookChanged: canEdit ? onWorkbookChanged : null,
      onUserWorkbookChangedShouldNotify: canEdit
          ? (previous, current) =>
            !_itemElementWorkbookContentEquals(previous, current)
          : null,
      onSave: canEdit
          ? (width, height, encodedWorkbook) =>
                onSave(context, width, height, encodedWorkbook)
          : null,
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
}) =>
    selectedTabValue == 'items' &&
    hasDateSetup &&
    !commandBusy &&
    !draftDirty;

List<String> _itemPreviewImageObjectIdsFor(Iterable<TColumnBase> columns) {
  final result = <String>[];
  final seen = <String>{};
  for (final column in columns) {
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) continue;
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (seen.add(objectId.toLowerCase())) {
      result.add(objectId);
    }
  }
  return result;
}

List<String> _itemPreviewBarcodeObjectIdsFor(Iterable<TColumnBase> columns) {
  final result = <String>[];
  final seen = <String>{};
  for (final column in columns) {
    final keyword = column.keyword.trim();
    final lower = keyword.toLowerCase();
    if (keyword.isEmpty ||
        (!lower.contains('barcode') && !lower.contains('qrcode'))) {
      continue;
    }
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (seen.add(objectId.toLowerCase())) {
      result.add(objectId);
    }
  }
  return result.isEmpty ? const ['#BARCODE'] : result;
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
  });

  final ItemOfMarket item;
  final String elementText;
  final fs.FortuneWorkbook elementWorkbook;
  final LabelSize? labelSize;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;

  @override
  Widget build(BuildContext context) {
    final preview = _itemOutputPreview(
      labelSize: labelSize,
      item: item,
      elementText: elementText,
      elementWorkbook: elementWorkbook,
    );
    if (preview.hintText != null) {
      return _ItemOutputPreviewHint(preview.hintText!);
    }
    final workbook = preview.workbook;
    if (workbook == null) {
      return const _ItemOutputPreviewHint('현재 공용라벨 시트가 없습니다.');
    }
    final messages = _itemCodePreviewMessages(workbook);
    return Column(
      children: [
        if (messages.isNotEmpty) _ItemCodePreviewMessages(messages: messages),
        Expanded(
          child: LabelSheetWorkbench(
            key: ValueKey(
              'item-output:${labelSize?.labelSizeId ?? 'none'}:${item.item.itemId}',
            ),
            initialWorkbook: workbook,
            labelSize: labelSize,
            imageObjectIds: imageObjectIds,
            barcodeObjectIds: barcodeObjectIds,
            hideToolbar: true,
            hideRowColumnHeaderLabels: true,
            hideSelectionHighlight: true,
            rulerCornerSizeLabelUsesAsterisk: true,
            disableSheetRulerGuideInteraction: true,
            hideStatisticBar: true,
            copyOnlyContextMenu: true,
            zoomToolbarPlacement:
                LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
          ),
        ),
      ],
    );
  }
}

class _ItemCodePreviewMessages extends StatelessWidget {
  const _ItemCodePreviewMessages({required this.messages});

  final List<({String text, bool error})> messages;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxHeight: 96),
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListView.separated(
      shrinkWrap: true,
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              message.error ? Icons.error_outline : Icons.warning_amber,
              size: 16,
              color: message.error
                  ? Theme.of(context).colorScheme.error
                  : Colors.orange.shade800,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    ),
  );
}

List<({String text, bool error})> _itemCodePreviewMessages(
  fs.FortuneWorkbook workbook,
) {
  final messages = <({String text, bool error})>[];
  final seen = <String>{};
  for (final sheet in workbook.sheets) {
    for (final image in sheet.images) {
      final warning = image.extraFields['itemCodeWarning']?.toString().trim();
      final error = image.extraFields['itemCodeError']?.toString().trim();
      if (warning != null && warning.isNotEmpty && seen.add('w:$warning')) {
        messages.add((text: warning, error: false));
      }
      if (error != null && error.isNotEmpty && seen.add('e:$error')) {
        messages.add((text: error, error: true));
      }
    }
  }
  return messages;
}

class _ItemOutputPreviewHint extends StatelessWidget {
  const _ItemOutputPreviewHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF5F6368),
        ),
      ),
    );
  }
}

@visibleForTesting
Widget debugItemPreviewPanelForTesting({
  required ItemOfMarket item,
  LabelSize? labelSize,
  String? rowIdentity,
  Future<void> Function(
    String rowIdentity,
    String elementPlain,
    String elementPayload,
  )? onElementCommitted,
  bool Function()? canSelectOutputPreview,
  bool canEdit = true,
}) => _ItemPreviewPanel(
  item: item,
  rowIdentity: rowIdentity ?? 'item:${item.item.itemId}',
  labelSize: labelSize,
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
}) => _itemManagerDateSettingsEnabled(
  selectedTabValue: selectedTabValue,
  hasDateSetup: hasDateSetup,
  commandBusy: commandBusy,
  draftDirty: draftDirty,
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
}) => _itemOutputPreview(
  labelSize: labelSize,
  item: item,
  elementText: elementText,
  elementWorkbook: elementWorkbook,
);

@visibleForTesting
List<({String text, bool error})> debugItemCodePreviewMessagesForTesting(
  fs.FortuneWorkbook workbook,
) => _itemCodePreviewMessages(workbook);

@visibleForTesting
String debugItemCodeErrorPlaceholderForTesting() =>
    _itemCodeErrorPlaceholderDataUri();

({fs.FortuneWorkbook? workbook, String? hintText}) _itemOutputPreview({
  required LabelSize? labelSize,
  required ItemOfMarket item,
  required String elementText,
  fs.FortuneWorkbook? elementWorkbook,
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
        TColumnContent.get(columnId, item.item.itemId)?.dataString ?? '';
    return (
      workbook: _replaceItemPreviewKeywords(
        _itemOutputPreviewPrivateWorkbook(workbook, labelSize),
        _itemOutputPreviewReplacements(item: item, elementText: elementText),
        codeDataResolver: ItemCodeDataResolver(
          itemName: item.item.itemName,
          columns: columns,
          columnValue: columnValue,
          tokenColumnValue: (column) => itemCodeTokenColumnValue(
            column: column,
            columns: columns,
            columnValue: columnValue,
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
}) {
  return <String, String>{
    '#ITEMNAME': item.item.itemName,
    '#ELEMENT': elementText,
    for (final column in TColumn.datas ?? const <TColumn>[])
      '#${column.keyword}':
          TColumnContent.get(column.columnId, item.item.itemId)?.dataString ??
          '',
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
  final nextImages = [
    for (final image in sheet.images)
      _replaceImageKeywords(
        image,
        replacements,
        codeDataResolver: codeDataResolver,
      ),
    ...insertedImages,
  ];
  return sheet.copyWith(
    cells: nextCells,
    images: nextImages,
    rowHeights: nextRowHeights,
    customHeight: nextCustomHeight,
  );
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

fs.FortuneImage _replaceImageKeywords(
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
      if (src == null) break;
      return image.copyWith(src: src, extraFields: extraFields);
    }
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
        enabled:
          !_orderEditMode && !_submittingLabelNameEdit && !_deletingLabel,
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
  final TextEditingController _brandNameEditController =
      TextEditingController();
  final FocusNode _brandNameEditFocusNode = FocusNode();
  int? _editingIndex;
  int? _insertActionIndex;
  bool _insertingBrand = false;
  final SettingsOperationGate _submissionGate = SettingsOperationGate();

  @override
  void initState() {
    super.initState();
    _brands = List<Brand>.from(widget.brands);
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
      closeEnabled: !_submissionGate.submitting,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
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
          onEmptyInsert: () => _startBrandInsertAt(0, actionIndex: null),
          onCancelEdit: _cancelBrandNameEdit,
          onSubmitEdit: _submitBrandNameEdit,
          onDeleteRow: _deleteBrand,
          onNameDoubleTap: _handleBrandNameDoubleTap,
          fillLastColumn: true,
          autoFitColumns: false,
          rowSwipeEnabled: true,
          enabled: !_submissionGate.submitting,
          keepRowContentOnSwipe: true,
          rowTooltip: '컬럼 왼쪽 스와이프 수정/삽입/삭제',
          showActionsWhenEmpty: true,
          rowNumberText: _brandRowNumberText,
        ),
      ),
    );
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
        write: () => BrandDAO.insertByBrandName(
          customerId,
          brandName,
          insertIndex + 1,
        ),
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
