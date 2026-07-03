import 'dart:async';
import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/auto_login_guard.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/column_special.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview_debug.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/page_home/item_manage.dart';
import 'package:label_manager/page_home/common_label_manage.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

/// 로그인 이후 메인 UI
class HomePageManager extends StatefulWidget {
  final Brand? selectedBrand;
  final ValueChanged<Brand?> onBrandChanged;
  final LabelSize? selectedLabelSize;
  final ValueChanged<LabelSize?> onLabelSizeChanged;

  const HomePageManager({
    super.key,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.selectedLabelSize,
    required this.onLabelSizeChanged,
  });

  @override
  State<HomePageManager> createState() => _HomePageManagerState();
}

class _HomePageManagerState extends State<HomePageManager> {
  static const double _rtfPreviewInitialReadableScale = 1.0;

  late TabbedViewController _tabController;
  final TextEditingController _tabSearchController = TextEditingController();
  final GlobalKey _commonLabelPreviewButtonKey = GlobalKey();
  final GlobalKey _rtfPreviewBoxKey = GlobalKey();
  int? _labelSizesBrandId;
  int _labelLoadToken = 0;
  int _rtfPreviewCaptureGeneration = 0;
  int _rtfPreviewResizeFinalizeToken = 0;
  PreviewFloatingWindow? _itemPreviewWindow;
  PreviewFloatingWindow? _commonLabelPreviewWindow;
  Timer? _rtfPreviewResizeDebounce;
  Timer? _rtfPreviewResizeFinalizeTimer;
  List<TabData> _tabs = const <TabData>[];
  LabelSize? _currentLabelSize;
  String? _rtfPreviewReadyKey;
  String? _rtfPreviewTargetKey;
  String? _rtfPreviewWindowKey;
  Size? _rtfPreviewTargetContentSize;
  Size? _rtfPreviewRefreshedTargetContentSize;
  Size? _rtfPreviewLastResolvedImageSize;
  Rect? _commonLabelGridRect;
  bool _rtfPreviewHasResolvedImage = false;
  bool _autoSelectedCommonLabelOnce = false;
  bool _commonLabelTabActivated = false;
  bool _commonLabelPreviewClosedByUser = false;
  bool _commonLabelPreviewHiddenForSheetDialog = false;

  OverlayEntry? _brandSettingsOverlayEntry;
  OverlayEntry? _labelSettingsOverlayEntry;
  // 브랜드 설정 다이얼로그에서 브랜드를 선택한 후 라벨 시트 로드가 완료될 때까지
  // 다이얼로그의 더블클릭을 차단하기 위한 플래그.
  final ValueNotifier<bool> _brandDialogBusyNotifier = ValueNotifier(false);

  bool get _isAutoLoginMode => AutoLoginGuard.instance.enabled;
  LabelSize? get _effectiveLabelSize => _currentLabelSize;
  String get _labelContentKey {
    final labelSize = _effectiveLabelSize;
    return '${labelSize?.labelSizeId ?? 'none'}:'
        '${labelSize?.labelSizeCommon?.width ?? 0}:'
        '${labelSize?.labelSizeCommon?.height ?? 0}';
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
    final brands = Brand.datas ?? const <Brand>[];
    for (final brand in brands) {
      if (brand.brandName == brandName) {
        return brand;
      }
    }
    return null;
  }

  Brand? _findBrandById(int? brandId) {
    if (brandId == null) return null;
    final brands = Brand.datas ?? const <Brand>[];
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
        final brands = await BrandDAO.selectByCustomerIdByBrandOrder(
          Customer.instance!.customerId,
        );
        if (!mounted) return;

        final prevBrands = Brand.datas ?? <Brand>[];
        final listEq = const ListEquality<Brand>();
        final changed =
            prevBrands.length != brands!.length ||
            !listEq.equals(prevBrands, brands);
        if (changed) {
          debugLog('brandsChanged reload prevLen=${prevBrands.length} newLen=${brands.length}');
          setState(() {});
          _brandSettingsOverlayEntry?.markNeedsBuild();
        }

        final resolved = _resolveSelectedBrand(brands, widget.selectedBrand);
        final fallback = brands.isNotEmpty ? brands.first : null;

        if (resolved == null && fallback != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onBrandChanged(fallback);
          });
        }

        final targetBrand = resolved ?? fallback ?? widget.selectedBrand;
        await _scheduleLabelSizeLoad(targetBrand);
      } finally {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
        debugLog(END);
      }
    }

    showSnackBar(
      context,
      '브랜드 데이터를 불러오고 있습니다...',
      type: SnackBarType.inProgress,
      onVisible: afterSnackBarVisible,
    );
  }

  void _handleBrandChanged(Brand? brand) {
    // 드롭다운에서의 브랜드 선택은 사용자의 의도적 행위이므로
    // autoLogin 가드(_isAutoLoginMode)와 무관하게 반영한다.
    // (다이얼로그 더블클릭의 _handleBrandSelectedFromDialog 와 동일한 원칙)
    debugLog('handleBrandChanged brandId=${brand?.brandId} autoLogin=$_isAutoLoginMode');
    widget.onBrandChanged(brand);
  }

  // 브랜드 설정 다이얼로그에서의 명시적 브랜드 선택(더블클릭)은 사용자의 의도적
  // 행위이므로 자동로그인 가드(_isAutoLoginMode)와 무관하게 반영한다.
  // 근거: .tmp/log/app_2026-07-01_17-13-52.log — 더블탭/핸들러는 정상 도달하나
  // _handleBrandChanged 의 autoLogin=true 가드에서 선택이 무시되어 무반응이었음.
  void _handleBrandSelectedFromDialog(Brand? brand) {
    _brandDialogBusyNotifier.value = true;
    widget.onBrandChanged(brand);
  }

  void _handleBrandsChangedFromDialog(
    List<Brand> brands,
    Brand? selectedBrand, {
    required bool updateSelection,
  }) {
    Brand.setDatas(brands);
    setState(() {});
    _brandSettingsOverlayEntry?.markNeedsBuild();
    if (updateSelection) {
      _brandDialogBusyNotifier.value = true;
      widget.onBrandChanged(selectedBrand);
    }
  }

  Future<void> _scheduleLabelSizeLoad(
    Brand? brand, {
    bool selectFirstLabel = false,
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
        duration: const Duration(days: 1),
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
        _handleLabelSizeChanged(null);
        return;
      }

      if (_labelSizesBrandId == target.brandId && LabelSize.datas != null) {
        final current = LabelSize.datas ?? const <LabelSize>[];

        if (current.isEmpty) {
          _handleLabelSizeChanged(null);
        } else if (selectFirstLabel) {
          _handleLabelSizeChanged(current.first);
        } else {
          final resolved = _resolveSelectedLabelSize(
            current,
            widget.selectedLabelSize,
          );

          final fallback = current.isNotEmpty ? current.first : null;

          if (resolved == null && fallback != null) {
            _handleLabelSizeChanged(fallback);
          }
        }

        return;
      }

      final token = ++_labelLoadToken;
      _labelSizesBrandId = null;
      LabelSize.setDatas(<LabelSize>[]);
      setState(() {});

      final labelSizes = await LabelSizeDAO.selectByBrandIdByLabelSizeOrder(
        target.brandId,
      );

      if (!mounted || token != _labelLoadToken) return;
      LabelSize.setDatas(labelSizes);
      _labelSizesBrandId = target.brandId;
      setState(() {});

      if (labelSizes!.isEmpty) {
        _handleLabelSizeChanged(null);
        return;
      }

      final resolved = _resolveSelectedLabelSize(
        labelSizes,
        widget.selectedLabelSize,
      );

      final fallback = labelSizes.isNotEmpty ? labelSizes.first : null;
      final selected = selectFirstLabel
          ? fallback
          : resolved ?? fallback ?? widget.selectedLabelSize;
      _handleLabelSizeChanged(selected);
    } finally {
      debugLog(END);
      // 다이얼로그 더블클릭 차단 해제: 로드가 완료(또는 중단)될 때 항상 해제한다.
      _brandDialogBusyNotifier.value = false;
      // 스낵바 닫기는 시트가 실제로 준비된 시점(_handleCommonLabelSheetReady)에 수행한다.
      // 여기서 hideCurrentSnackBar() 를 호출하면 아직 DB 조회/_resetTabs 가 진행 중인
      // 상태에서 스낵바가 사라지거나, RTF 변환 스낵바로 전환되기 전에 닫혀버린다.
    }
  }

  Future<void> _handleLabelSizeChanged(LabelSize? labelSize) async {
    try {
      debugLog(START);

      final currentLabelSizeId = _currentLabelSize?.labelSizeId;
      final selectedLabelSizeId = widget.selectedLabelSize?.labelSizeId;
      if (labelSize?.labelSizeId == currentLabelSizeId &&
          labelSize?.labelSizeId == selectedLabelSizeId) {
        debugLog('skip unchanged labelSizeId=${labelSize?.labelSizeId}');
        return;
      }

      if (labelSize == null) {
        _currentLabelSize = null;
        _rtfPreviewReadyKey = null;
        _commonLabelTabActivated = false;
        _commonLabelPreviewClosedByUser = false;
        widget.onLabelSizeChanged(null);
        ItemOfMarket.datas = <ItemOfMarket>[];
        _resetTabs();
        return;
      }

      _currentLabelSize = labelSize;
      _rtfPreviewReadyKey = null;
      _commonLabelTabActivated = false;
      _commonLabelPreviewClosedByUser = false;
      widget.onLabelSizeChanged(labelSize);
      TColumn.datas = await TColumnDAO.selectByLabelSizeId(labelSize.labelSizeId);
      TColumnContent.datas = await TColumnContentDAO.selectByLabelSizeId(
        labelSize.labelSizeId,
      );
      TColumnSpecial.datas = await TColumnSpecial.selectByLabelSizeId(
        labelSize.labelSizeId,
      );
      ItemOfMarket.datas =
          await ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId(
            Market.instance!.marketId,
            labelSize.labelSizeId,
          );
      debugLog(
        'loaded labelSizeId=${labelSize.labelSizeId}, '
        'columns=${TColumn.datas?.length ?? 0}, '
        'contents=${TColumnContent.datas?.length ?? 0}, '
        'specials=${TColumnSpecial.datas?.length ?? 0}, '
        'items=${ItemOfMarket.datas?.length ?? 0}',
      );
      _resetTabs();
    } catch (e) {
      debugLog('$e');
    } finally {
      debugLog(END);
    }
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
  }

  void _openBrandSettingsDialog() {
    debugLog('brandSettings overlay open requested exists=${_brandSettingsOverlayEntry != null}');
    if (_brandSettingsOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // Brand settings are modeless OverlayEntry dialogs. Confirm/warning
      // dialogs launched inside must use showBlockingModelessOverlayDialog.
      builder: (_) => BlockingModelessDialog(
        child: _BrandSettingsDialog(
          brands: Brand.datas ?? const <Brand>[],
          selectedBrand: widget.selectedBrand,
          onBrandSelected: _handleBrandSelectedFromDialog,
          onBrandsChanged: _handleBrandsChangedFromDialog,
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
    debugLog('labelSettings overlay open requested exists=${_labelSettingsOverlayEntry != null}');
    if (_labelSettingsOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      // Label settings are modeless OverlayEntry dialogs. The order-apply
      // confirmation must be inserted into the root overlay, not showDialog.
      builder: (_) => BlockingModelessDialog(
        child: _LabelSettingsDialog(
          labels: LabelSize.datas ?? const <LabelSize>[],
          onOrderSaved: _handleLabelOrderSaved,
          onClose: _closeLabelSettingsDialog,
        ),
      ),
    );
    _labelSettingsOverlayEntry = entry;
    Overlay.of(context).insert(entry);
    debugLog('labelSettings overlay inserted mounted=${entry.mounted}');
  }

  Future<List<LabelSize>> _handleLabelOrderSaved() async {
    final brandId =
      widget.selectedBrand?.brandId ??
      _effectiveLabelSize?.brandId ??
      _labelSizesBrandId;
    final previousSelectedLabel =
      _effectiveLabelSize ?? widget.selectedLabelSize;
    debugLog(
      'labelSettings reorder reload start brandId=$brandId '
      'selectedLabelSizeId=${previousSelectedLabel?.labelSizeId}',
    );

    if (brandId == null) {
      throw Exception('${runtimeLogTag()} 라벨 순서를 저장할 브랜드를 찾을 수 없습니다.');
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
    if (resolvedSelected != null) {
      _currentLabelSize = resolvedSelected;
    }
    setState(() {});
    _labelSettingsOverlayEntry?.markNeedsBuild();
    debugLog(
      'labelSettings reorder reload completed '
      'labels=${reloadedLabels.length} selectedLabelSizeId=${resolvedSelected?.labelSizeId}',
    );
    return reloadedLabels;
  }

  void _closeBrandSettingsDialog() {
    debugLog('brandSettings overlay close requested exists=${_brandSettingsOverlayEntry != null}');
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
    debugLog('brandSettings overlay closed');
  }

  void _closeLabelSettingsDialog() {
    debugLog('labelSettings overlay close requested exists=${_labelSettingsOverlayEntry != null}');
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
          items: ItemOfMarket.datas ?? const <ItemOfMarket>[],
        ),
        closable: false,
        keepAlive: true,
      ),
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
      _itemPreviewWindow?.hide();
    });
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
      _rtfPreviewHasResolvedImage = false;
      _rtfPreviewWindowKey = null;
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
      final preview = shouldRebuildPreview ? _buildRtfPreview(currentRtf) : null;
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
        onResizeCompleted: _handleRtfPreviewWindowResizeCompleted,
        onCloseRequested: _handleCommonLabelPreviewCloseRequested,
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
    final target = _commonLabelPreviewButtonRect() ?? window.rect.center & Size.zero;
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
    if (_selectedTabValue() == 'common_label') {
      _alignCommonLabelPreviewWindowToGrid();
    }
  }

  void _alignCommonLabelPreviewWindowToGrid() {
    final window = _commonLabelPreviewWindow;
    final gridRect = _commonLabelGridRect;
    if (!mounted || window == null || !window.isVisible || gridRect == null) {
      return;
    }
    window.alignBottomRightTo(context, gridRect.bottomRight);
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
        (resizeEndRect.width - padding.horizontal).clamp(1.0, double.infinity),
        (resizeEndRect.height - padding.vertical).clamp(1.0, double.infinity),
      );
      final renderObject = _rtfPreviewBoxKey.currentContext?.findRenderObject();
      Size? measuredTarget;
      if (renderObject is RenderBox && renderObject.hasSize) {
        measuredTarget = Size(
          (renderObject.size.width - padding.horizontal).clamp(1.0, double.infinity),
          (renderObject.size.height - padding.vertical).clamp(1.0, double.infinity),
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
      final shouldUseMeasuredTarget = current == null ||
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

  void _onTabSearch() {
    final query = _tabSearchController.text.trim();
    if (query.isEmpty) return;
    // TODO: 검색 로직
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
          _buildCommonLabelPreviewButton(context),
          Transform.translate(
            offset: const Offset(0, -1),
            child: SizedBox(
              width: fieldWidth,
              child: TextField(
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
                onPressed: _onTabSearch,
                icon: Icon(Icons.search, size: lmSize(14), color: onButtonColor),
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCommonLabelPreviewButton(BuildContext context) {
    final selected = _selectedTabValue() == 'common_label';
    final window = _commonLabelPreviewWindow;
    final shouldShow = selected &&
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
      children: [button, SizedBox(width: lmSize(8))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = Brand.datas ?? const <Brand>[];
    final brandItems = _brandDropdownItems(brands);
    final resolvedBrand = _resolveSelectedBrand(brands, widget.selectedBrand);
    final labelSizes = LabelSize.datas ?? const <LabelSize>[];
    final labelItems = _labelSizeDropdownItems(labelSizes);
    final resolvedLabel = _resolveSelectedLabelSize(
      labelSizes,
      _effectiveLabelSize,
    );
    final settingsEnabled = _selectedTabValue() == 'common_label';

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
              onLabelSizeChanged: _handleLabelSizeChanged,
              onDropdownMenuStateChanged: _handleTopDropdownMenuStateChanged,
                settingsEnabled: settingsEnabled,
                onBrandSettingsPressed: settingsEnabled
                  ? _openBrandSettingsDialog
                  : null,
                onLabelSettingsPressed: settingsEnabled
                  ? _openLabelSettingsDialog
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
  final bool settingsEnabled;
  final VoidCallback? onBrandSettingsPressed;
  final VoidCallback? onLabelSettingsPressed;
  final List<DropdownMenuItem<Brand>> brandItems;
  final Brand? resolvedBrand;
  final List<DropdownMenuItem<LabelSize>> labelItems;
  final LabelSize? resolvedLabel;

  const _TopControlArea({
    required this.onBrandChanged,
    required this.onLabelSizeChanged,
    required this.onDropdownMenuStateChanged,
    required this.settingsEnabled,
    required this.onBrandSettingsPressed,
    required this.onLabelSettingsPressed,
    required this.brandItems,
    required this.resolvedBrand,
    required this.labelItems,
    required this.resolvedLabel,
  });

  @override
  Widget build(BuildContext context) {
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
                        padding: lmInsetsSymmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
                              padding: lmInsetsSymmetric(
                                horizontal: 8,
                              ),
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
                          width: isDesktop ? 220 : 150,
                          labelWidth: 48,
                        ),
                        SizedBox(width: lmSize(6)),
                        SizedBox(
                          height: lmSize(36),
                          child: OutlinedButton(
                            onPressed: onLabelSettingsPressed,
                            style: OutlinedButton.styleFrom(
                              minimumSize: lmSize2(60, 36),
                              padding: lmInsetsSymmetric(
                                horizontal: 8,
                              ),
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
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: lmSize(isDesktop ? 450 : 370),
                      ),
                      child: Container(
                        width: lmSize(isDesktop ? 430 : 350),
                        height: lmSize(36),
                        padding: lmInsetsSymmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
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
  final double width;
  final double labelWidth;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.onMenuStateChange,
    this.width = 170,
    this.labelWidth = 80,
  });

  @override
  Widget build(BuildContext context) {
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
          child: DropdownButtonFormField2<T>(
            value: value,
            items: items,
            onChanged: (onChanged != null && items.isNotEmpty)
                ? onChanged
                : null,
            onMenuStateChange: onMenuStateChange,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            isExpanded: true,
            buttonStyleData: ButtonStyleData(
              height: lmSize(28),
              padding: lmInsetsSymmetric(horizontal: 2),
            ),
            dropdownStyleData: DropdownStyleData(
              useRootNavigator: true,
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
      ],
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title (준비 중)'));
  }
}

class _LabelSettingsDialog extends StatefulWidget {
  const _LabelSettingsDialog({
    required this.labels,
    required this.onOrderSaved,
    required this.onClose,
  });

  final List<LabelSize> labels;
  final Future<List<LabelSize>> Function() onOrderSaved;
  final VoidCallback onClose;

  @override
  State<_LabelSettingsDialog> createState() => _LabelSettingsDialogState();
}

class _LabelSettingsDialogState extends State<_LabelSettingsDialog> {
  static const double _dialogWidth = 500;

  late List<LabelSize> _labels;
  late List<LabelSize> _originalLabels;
  final TextEditingController _labelNameEditController =
      TextEditingController();
  final FocusNode _labelNameEditFocusNode = FocusNode();
  int? _editingIndex;
  int? _insertActionIndex;
  bool _orderEditMode = false;
  bool _applyingOrderChanges = false;
  bool _insertingLabel = false;
  int? _selectedLabelSizeId;

  @override
  void initState() {
    super.initState();
    _labels = List<LabelSize>.from(widget.labels);
    _originalLabels = List<LabelSize>.from(widget.labels);
    _labelNameEditController.addListener(_handleLabelNameEditChanged);
  }

  @override
  void didUpdateWidget(covariant _LabelSettingsDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.labels, widget.labels) && !_hasOrderChanges) {
      final newLabels = List<LabelSize>.from(widget.labels);
      final editingIndex = _editingIndex;
      final outOfRange = editingIndex != null && editingIndex >= newLabels.length;
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
    debugLog('labelSettingsDialog build labels=${_labels.length} orderChanged=$_hasOrderChanges');
    return BlockingModelessDialogFrame(
      title: '라벨 설정',
      width: _dialogWidth,
      height: dialogHeight,
      closeIcon: const _BrandDialogCloseIcon(),
      onClose: widget.onClose,
      footer: _orderEditMode ? _buildOrderEditFooter() : null,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
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
    );
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
      onEmptyInsert: _orderEditMode ? null : () => _startLabelInsertAt(0, actionIndex: null),
      onCancelEdit: _cancelLabelNameEdit,
      onSubmitEdit: _submitLabelNameEdit,
      enabled: !_orderEditMode,
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
        enabled: !_orderEditMode && !_applyingOrderChanges && !hasInlineEditor,
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
    final originalIndex = _originalLabels.indexWhere((original) => identical(original, label));
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
      debugLog('labelInsert blocked editingIndex=$_editingIndex orderEditMode=$_orderEditMode inserting=$_insertingLabel');
      return;
    }
    final insertIndex = index.clamp(0, _labels.length);
    final brandId = _labels.isNotEmpty ? _labels.first.brandId : 0;
    debugLog('labelInsert start index=$insertIndex brandId=$brandId');
    setState(() {
      _insertingLabel = true;
      _editingIndex = insertIndex;
      _insertActionIndex = actionIndex;
      _labels.insert(
        insertIndex,
        LabelSize(labelSizeId: 0, brandId: brandId, labelSizeName: ''),
      );
      _labelNameEditController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_insertingLabel || _editingIndex != insertIndex) {
        debugLog('labelInsert focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$insertIndex inserting=$_insertingLabel');
        return;
      }
      debugLog('labelInsert focusRequest index=$insertIndex');
      _labelNameEditFocusNode.requestFocus();
    });
  }

  void _toggleLabelNameEdit(LabelSize label, int index) {
    if (_insertingLabel || _orderEditMode) {
      debugLog('labelNameEdit blocked inserting=$_insertingLabel orderEditMode=$_orderEditMode index=$index');
      return;
    }
    if (_editingIndex == index) {
      debugLog('labelNameEdit cancelByToggle index=$index');
      _cancelLabelNameEdit();
      return;
    }
    debugLog('labelNameEdit start index=$index labelSizeId=${label.labelSizeId} name=${label.labelSizeName}');
    setState(() {
      _editingIndex = index;
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
        debugLog('labelNameEdit focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$index');
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
    debugLog('labelNameEdit cancelled index=$_editingIndex text=${_labelNameEditController.text}');
    _labelNameEditFocusNode.unfocus();
    setState(() {
      if (_insertingLabel && _editingIndex! < _labels.length) {
        _labels.removeAt(_editingIndex!);
      }
      _insertingLabel = false;
      _insertActionIndex = null;
      _editingIndex = null;
      _labelNameEditController.clear();
    });
  }

  void _handleLabelNameEditChanged() {
    if (_editingIndex == null || !mounted) {
      return;
    }
    debugLog('labelNameEdit textChanged index=$_editingIndex text=${_labelNameEditController.text} canSubmit=$_canSubmitLabelNameEdit');
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
    if (_insertingLabel) {
      return true;
    }
    return nextName != _labels[editingIndex].labelSizeName.trim();
  }

  void _submitLabelNameEdit(String value) {
    debugLog('labelNameEdit submit pendingImplementation index=$_editingIndex value=$value canSubmit=$_canSubmitLabelNameEdit inserting=$_insertingLabel');
    if (!_canSubmitLabelNameEdit) {
      debugLog('labelNameEdit submitSkipped canSubmit=false');
      return;
    }
  }

  void _handleLabelRowSelected(LabelSize label, int index) {
    if (_selectedLabelSizeId == label.labelSizeId) {
      return;
    }
    debugLog('labelSettings rowSelected index=$index labelSizeId=${label.labelSizeId}');
    setState(() => _selectedLabelSizeId = label.labelSizeId);
  }

  void _startOrderEditMode() {
    if (_editingIndex != null || _applyingOrderChanges || _orderEditMode) {
      debugLog('labelSettings reorder startBlocked editingIndex=$_editingIndex applying=$_applyingOrderChanges orderEditMode=$_orderEditMode');
      return;
    }
    debugLog('labelSettings reorder start labels=${_labels.length}');
    setState(() {
      _orderEditMode = true;
      _selectedLabelSizeId = _labels.isNotEmpty ? _labels.first.labelSizeId : null;
    });
  }

  void _moveLabelRow(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= _labels.length || toIndex < 0 || toIndex >= _labels.length) {
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
    debugLog('labelSettings reorder from=$fromIndex to=$toIndex insert=$insertIndex');
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
              debugLog('labelSettings reorder apply confirmDialog cancelPressed');
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
    debugLog('labelSettings reorder apply confirmDialog result=$confirmed mounted=$mounted');

    if (!mounted) {
      debugLog('labelSettings reorder apply aborted unmounted after confirmDialog');
      return;
    }

    if (confirmed != true) {
      debugLog('labelSettings reorder apply cancelledByUser');
      _cancelOrderChanges();
      return;
    }

    debugLog('labelSettings reorder apply confirmed startSave labels=${_labels.length}');
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
      debugLog('labelSettings reorder apply updateOrders done reloadStart');
      final appliedLabels = await widget.onOrderSaved();
      debugLog(
        'labelSettings reorder apply reload done labels=${appliedLabels.length} '
        'mounted=$mounted',
      );
      if (!mounted) {
        debugLog('labelSettings reorder apply aborted unmounted after reload');
        return;
      }
      setState(() {
        _labels = List<LabelSize>.from(appliedLabels);
        _originalLabels = List<LabelSize>.from(appliedLabels);
        _orderEditMode = false;
        _selectedLabelSizeId = null;
      });
      debugLog(
        'labelSettings reorder apply completed labels=${appliedLabels.length}',
      );
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
                  debugLog('labelSettings reorder apply failureDialog okPressed');
                  close(null);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
        debugLog('labelSettings reorder apply failureDialog closed');
      }
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
}

class _LabelSettingsFooterButton extends StatelessWidget {
  const _LabelSettingsFooterButton({required this.label, required this.onPressed});

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
              color: enabled ? const Color(0xFF0E2F66) : const Color(0xFFC7C7C7),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _BrandSettingsDialog extends StatefulWidget {
  const _BrandSettingsDialog({
    required this.brands,
    required this.selectedBrand,
    required this.onBrandSelected,
    required this.onBrandsChanged,
    required this.onClose,
    required this.busyNotifier,
  });

  final List<Brand> brands;
  final Brand? selectedBrand;
  final ValueChanged<Brand?> onBrandSelected;
  final void Function(
    List<Brand> brands,
    Brand? selectedBrand, {
    required bool updateSelection,
  }) onBrandsChanged;
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
      final outOfRange = editingIndex != null && editingIndex >= newBrands.length;
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
    debugLog('brandSettings overlayDialog result type=$T result=$result mounted=$mounted');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    // 예상치 못한 리빌드 원인 추적용. buildCell 보다 먼저 출력되면
    // 다이얼로그 전체가 리빌드된 것임(InheritedWidget 의존성 변화 등).
    debugLog('brandSettingsDialog build editingIndex=$_editingIndex dialogHeight=$dialogHeight');
    return BlockingModelessDialogFrame(
      title: '브랜드 설정',
      width: _dialogWidth,
      height: dialogHeight,
      closeIcon: const _BrandDialogCloseIcon(),
      onClose: widget.onClose,
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
    debugLog('brandNameDoubleTap index=$index editingIndex=$_editingIndex busy=${widget.busyNotifier.value} brandId=${brand.brandId} name=${brand.brandName}');
    if (_editingIndex != null || widget.busyNotifier.value) {
      debugLog('brandNameDoubleTap blocked editingIndex=$_editingIndex busy=${widget.busyNotifier.value}');
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
      debugLog('brandInsert blocked editingIndex=$_editingIndex inserting=$_insertingBrand');
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
        debugLog('brandInsert focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$insertIndex inserting=$_insertingBrand');
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
    debugLog('brandNameEdit start index=$index brandId=${brand.brandId} name=${brand.brandName}');
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
        debugLog('brandNameEdit focusRequest skipped mounted=$mounted editingIndex=$_editingIndex expected=$index');
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
    debugLog('brandNameEdit cancelled index=$_editingIndex text=${_brandNameEditController.text}');
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
    debugLog('brandNameEdit textChanged index=$_editingIndex text=${_brandNameEditController.text} canSubmit=$_canSubmitBrandNameEdit');
    setState(() {});
  }

  bool get _canSubmitBrandNameEdit {
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _brands.length) {
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

  void _publishBrandsChanged({
    Brand? selectedBrand,
    required bool updateSelection,
  }) {
    final nextBrands = List<Brand>.from(_brands);
    Brand.setDatas(nextBrands);
    widget.onBrandsChanged(
      nextBrands,
      selectedBrand,
      updateSelection: updateSelection,
    );
  }

  Future<void> _submitBrandNameEdit(String value) async {
    debugLog('brandNameEdit submit index=$_editingIndex value=$value canSubmit=$_canSubmitBrandNameEdit');
    if (!_canSubmitBrandNameEdit) {
      debugLog('brandNameEdit submitSkipped canSubmit=false');
      return;
    }
    final editingIndex = _editingIndex;
    if (editingIndex == null || editingIndex >= _brands.length) {
      debugLog('brandNameEdit submitSkipped editingIndex=$editingIndex outOfRange');
      return;
    }
    if (_insertingBrand) {
      await _insertBrandName(editingIndex, value.trim());
      return;
    }
    await _updateBrandName(_brands[editingIndex], value.trim());
  }

  Future<void> _insertBrandName(int insertIndex, String brandName) async {
    final customerId = Customer.instance?.customerId;
    debugLog('insertBrandName start index=$insertIndex customerId=$customerId name=$brandName');
    if (!_insertingBrand || _editingIndex != insertIndex || customerId == null) {
      debugLog('insertBrandName aborted inserting=$_insertingBrand editingIndex=$_editingIndex expected=$insertIndex customerId=$customerId');
      return;
    }

    debugLog('insertBrandName confirmDialog show index=$insertIndex name=$brandName');
    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'$brandName' 브랜드를 추가하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => close(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => close(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    debugLog('insertBrandName confirmDialog result=$confirmed index=$insertIndex');

    if (!mounted) {
      debugLog('insertBrandName aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog('insertBrandName cancelledByUser index=$insertIndex keepEditing');
      _brandNameEditFocusNode.requestFocus();
      return;
    }

    Brand inserted;
    try {
      inserted = await BrandDAO.insertByBrandName(
        customerId,
        brandName,
        insertIndex + 1,
      );
    } catch (e) {
      debugLog('insertBrandName failed index=$insertIndex error=$e');
      if (mounted) {
        await _showBrandOverlayDialog<void>(
          (dialogContext, close) => AlertDialog(
            title: const Text('브랜드 추가 실패'),
            content: const Text('브랜드 추가에 실패했습니다.'),
            actions: [
              TextButton(
                onPressed: () => close(null),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (mounted) {
          _brandNameEditFocusNode.requestFocus();
        }
      }
      return;
    }

    if (!mounted) {
      debugLog('insertBrandName aborted unmounted after insert');
      return;
    }

    if (!_insertingBrand || _editingIndex != insertIndex) {
      debugLog('insertBrandName skippedStateUpdate editingIndexChanged inserting=$_insertingBrand editingIndex=$_editingIndex expected=$insertIndex');
      return;
    }

    setState(() {
      _brands
        ..removeAt(insertIndex)
        ..insert(insertIndex, inserted);
      _brands = List<Brand>.from(_brands);
      _insertingBrand = false;
      _insertActionIndex = null;
      _editingIndex = null;
      _brandNameEditController.clear();
    });
    _publishBrandsChanged(updateSelection: false);

    debugLog('insertBrandName done brandId=${inserted.brandId} index=$insertIndex name=${inserted.brandName}');
  }

  Future<void> _deleteBrand(Brand brand, int index) async {
    debugLog('deleteBrand start index=$index brandId=${brand.brandId} name=${brand.brandName} editingIndex=$_editingIndex');
    if (_editingIndex != null || index < 0 || index >= _brands.length) {
      debugLog('deleteBrand aborted editingIndex=$_editingIndex index=$index len=${_brands.length}');
      return;
    }

    debugLog('deleteBrand confirmDialog show brandId=${brand.brandId}');
    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'${brand.brandName}' 브랜드를 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => close(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => close(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    debugLog('deleteBrand confirmDialog result=$confirmed brandId=${brand.brandId}');

    if (!mounted) {
      debugLog('deleteBrand aborted unmounted after dialog');
      return;
    }

    if (confirmed != true) {
      debugLog('deleteBrand cancelledByUser brandId=${brand.brandId}');
      return;
    }

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

    if (!mounted) {
      debugLog('deleteBrand aborted unmounted after delete');
      return;
    }

    final currentIndex = _brands.indexWhere((value) => value.brandId == brand.brandId);
    if (currentIndex < 0) {
      debugLog('deleteBrand skippedStateUpdate missing brandId=${brand.brandId}');
      return;
    }

    final wasSelected = widget.selectedBrand?.brandId == brand.brandId;
    final nextSelectedBrand = wasSelected
        ? _resolveBrandAfterDelete(currentIndex)
        : widget.selectedBrand;

    setState(() {
      _brands = List<Brand>.from(_brands)..removeAt(currentIndex);
    });
    _publishBrandsChanged(
      selectedBrand: nextSelectedBrand,
      updateSelection: wasSelected,
    );

    debugLog('deleteBrand done brandId=${brand.brandId} index=$currentIndex');
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

    debugLog('updateBrandName confirm dialog brandId=${brand.brandId} old=${brand.brandName} new=$brandName');

    final confirmed = await _showBrandOverlayDialog<bool>(
      (dialogContext, close) => AlertDialog(
        content: Text("'$brandName' 명으로 변경하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => close(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => close(true),
            child: const Text('확인'),
          ),
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
      debugLog('updateBrandName cancelledByUser brandId=${brand.brandId} keepEditing');
      _brandNameEditFocusNode.requestFocus();
      return;
    }

    debugLog('updateBrandName confirmed brandId=${brand.brandId} old=${brand.brandName} new=$brandName');
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
              TextButton(
                onPressed: () => close(null),
                child: const Text('확인'),
              ),
            ],
          ),
        );
        if (mounted) {
          _brandNameEditFocusNode.requestFocus();
        }
      }
      return;
    }

    debugLog('updateBrandName result succeeded=true editingIndexNow=$_editingIndex expectedIndex=$editingIndex');

    if (_editingIndex != editingIndex) {
      debugLog('updateBrandName skippedStateUpdate editingIndexChanged');
      return;
    }

    setState(() {
      _brands[editingIndex] = Brand(
        brandId: brand.brandId,
        customerId: brand.customerId,
        brandName: brandName,
      );
      _editingIndex = null;
      _brandNameEditController.clear();
    });
    final updatedBrand = _brands[editingIndex];
    _publishBrandsChanged(
      selectedBrand: updatedBrand,
      updateSelection: widget.selectedBrand?.brandId == updatedBrand.brandId,
    );

    debugLog('updateBrandName done brandId=${brand.brandId} newName=$brandName');
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
