import 'dart:async';
import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/page_home/item_manage.dart';
import 'package:label_manager/page_home/common_label_manage.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
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
  int? _labelSizesBrandId;
  int _labelLoadToken = 0;
  PreviewFloatingWindow? _itemPreviewWindow;
  PreviewFloatingWindow? _commonLabelPreviewWindow;
  Timer? _rtfPreviewResizeDebounce;
  List<TabData> _tabs = const <TabData>[];
  LabelSize? _currentLabelSize;
  String? _rtfPreviewReadyKey;
  String? _rtfPreviewTargetKey;
  String? _rtfPreviewWindowKey;
  Size? _rtfPreviewTargetContentSize;
  Rect? _commonLabelGridRect;
  bool _autoSelectedCommonLabelOnce = false;
  bool _commonLabelTabActivated = false;
  bool _commonLabelPreviewClosedByUser = false;
  bool _commonLabelPreviewHiddenForSheetDialog = false;

  OverlayEntry? _brandSettingsOverlayEntry;
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
    if (_brandSettingsOverlayEntry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BrandSettingsDialog(
        brands: Brand.datas ?? const <Brand>[],
        onBrandSelected: _handleBrandSelectedFromDialog,
        onClose: _closeBrandSettingsDialog,
        busyNotifier: _brandDialogBusyNotifier,
      ),
    );
    _brandSettingsOverlayEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _closeBrandSettingsDialog() {
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
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
      _rtfPreviewTargetKey = readyKey;
      _rtfPreviewTargetContentSize = null;
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
    return LabelSheetRtfPreview(
      key: ValueKey(
        'rtf-preview:${_effectiveLabelSize?.labelSizeId}:${rtf.hashCode}',
      ),
      rtf: rtf,
      width: targetWidth,
      height: targetHeight,
      widthMm: _effectiveLabelSize?.labelSizeCommon?.width ?? 100,
      heightMm: _effectiveLabelSize?.labelSizeCommon?.height ?? 100,
      onImageSizeResolved: (imageSize) {
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
    _updateRtfPreviewTargetFromRect(rect, isResizing: false, force: true);
  }

  void _updateRtfPreviewTargetFromRect(
    Rect rect, {
    required bool isResizing,
    bool force = false,
  }) {
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    if (!mounted ||
        !Platform.isWindows ||
        !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    const padding = LabelSheetRtfPreview.defaultPadding;
    final next = Size(
      (rect.width - padding.horizontal).clamp(1.0, double.infinity),
      (rect.height - padding.vertical).clamp(1.0, double.infinity),
    );
    final current = _rtfPreviewTargetContentSize;
    if (!force &&
        current != null &&
        current.width.round() == next.width.round() &&
        current.height.round() == next.height.round()) {
      return;
    }
    _rtfPreviewTargetContentSize = next;
    debugLog(
      'rtf preview target logical='
      '${next.width.round()}x${next.height.round()} resizing=$isResizing force=$force',
    );
    if (isResizing) {
      _rtfPreviewResizeDebounce?.cancel();
      _rtfPreviewResizeDebounce = Timer(
        const Duration(milliseconds: 150),
        _refreshRtfPreviewChild,
      );
      return;
    }
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeDebounce = null;
    _refreshRtfPreviewChild();
  }

  void _refreshRtfPreviewChild() {
    _rtfPreviewResizeDebounce = null;
    if (!mounted || _selectedTabValue() != 'common_label') return;
    final rtf = _effectiveLabelSize?.labelSizeCommon?.rtf;
    final window = _commonLabelPreviewWindow;
    if (window == null ||
        !window.isVisible ||
        !labelSheetLooksLikeRichEditRtf(rtf)) {
      return;
    }
    debugLog('rtf preview recapture child refresh');
    window.setChild(_buildRtfPreview(rtf!));
  }

  void _hideFloatingWindows() {
    _itemPreviewWindow?.hide();
    _commonLabelPreviewWindow?.hide();
    _rtfPreviewResizeDebounce?.cancel();
    _rtfPreviewResizeDebounce = null;
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
    _itemPreviewWindow?.dispose();
    _commonLabelPreviewWindow?.dispose();
    _tabController.dispose();
    _tabSearchController.dispose();
    _brandSettingsOverlayEntry?.remove();
    _brandSettingsOverlayEntry = null;
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
                onLabelSettingsPressed: settingsEnabled ? () {} : null,
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

class _BrandSettingsDialog extends StatefulWidget {
  const _BrandSettingsDialog({
    required this.brands,
    required this.onBrandSelected,
    required this.onClose,
    required this.busyNotifier,
  });

  final List<Brand> brands;
  final ValueChanged<Brand?> onBrandSelected;
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

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    // 예상치 못한 리빌드 원인 추적용. buildCell 보다 먼저 출력되면
    // 다이얼로그 전체가 리빌드된 것임(InheritedWidget 의존성 변화 등).
    debugLog('brandSettingsDialog build editingIndex=$_editingIndex dialogHeight=$dialogHeight');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: _dialogWidth,
          height: dialogHeight,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xffece6f0),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '브랜드 설정',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: '닫기',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: const _BrandDialogCloseIcon(),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: SwipeActionTable<Brand>(
                      rows: _brands,
                      fillLastColumn: true,
                      autoFitColumns: false,
                      rowSwipeEnabled: true,
                      keepRowContentOnSwipe: true,
                      rowTooltip: '컬럼 왼쪽 스와이프 수정/삽입/삭제',
                      showActionsWhenEmpty: true,
                      isRowContentInteractive: (_, index) => _editingIndex == index,
                      canSwipeRow: (_, index) =>
                          _editingIndex == null || _editingIndex == index,
                      actions: _brandRowActions(),
                      emptyActions: _brandEmptyActions(),
                      columns: [
                        SwipeActionTableColumn<Brand>(
                          header: '브랜드 이름',
                          initialWidth: 220,
                          minWidth: 120,
                          fillRemaining: true,
                          text: _brandNameText,
                          cellBuilder: _buildBrandNameCell,
                          onDoubleTap: _handleBrandNameDoubleTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _brandNameText(Brand brand) => brand.brandName;

  void _handleBrandNameDoubleTap(Brand brand, int index) {
    debugLog('brandNameDoubleTap index=$index editingIndex=$_editingIndex busy=${widget.busyNotifier.value} brandId=${brand.brandId} name=${brand.brandName}');
    if (_editingIndex != null || widget.busyNotifier.value) {
      debugLog('brandNameDoubleTap blocked editingIndex=$_editingIndex busy=${widget.busyNotifier.value}');
      return;
    }
    debugLog('brandNameDoubleTap selectBrand brandId=${brand.brandId}');
    widget.onBrandSelected(brand);
  }

  List<SwipeActionTableAction<Brand>> _brandRowActions() {
    return [
      SwipeActionTableAction<Brand>(
        icon: Icons.edit,
        tooltip: '수정',
        // 테이블 헤더 색상과 통일 → 편집 진입/취소 버튼임을 직관적으로 전달
        backgroundColor: const Color(0xFF0E2F66),
        onRowPressed: _toggleBrandNameEdit,
        isPressed: (_, index) => _editingIndex == index,
      ),
      SwipeActionTableAction<Brand>(
        icon: Icons.add,
        tooltip: '삽입',
        backgroundColor: const Color(0xff0277bd),
        onPressed: _noop,
        isEnabled: (_, _) => _editingIndex == null,
      ),
      SwipeActionTableAction<Brand>(
        icon: Icons.delete,
        tooltip: '삭제',
        backgroundColor: const Color(0xffc62828),
        onPressed: _noop,
        isEnabled: (_, _) => _editingIndex == null,
      ),
    ];
  }

  static List<SwipeActionTableAction<Brand>> _brandEmptyActions() {
    return const [
      SwipeActionTableAction<Brand>(
        icon: Icons.edit,
        tooltip: '수정',
        backgroundColor: Color(0xff9ca3af),
      ),
      SwipeActionTableAction<Brand>(
        icon: Icons.add,
        tooltip: '삽입',
        backgroundColor: Color(0xffa7b0bd),
        onPressed: _noop,
      ),
      SwipeActionTableAction<Brand>(
        icon: Icons.delete,
        tooltip: '삭제',
        backgroundColor: Color(0xffb4bac3),
      ),
    ];
  }

  Widget _buildBrandNameCell(BuildContext context, Brand brand, double width) {
    if (!_isEditingBrand(brand)) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              brand.brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    final canSubmit = _canSubmitBrandNameEdit;
    debugLog('brandNameEdit buildCell index=$_editingIndex brandId=${brand.brandId} canSubmit=$canSubmit width=$width size=${MediaQuery.sizeOf(context)}');
    return SizedBox(
      width: width,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            debugLog('brandNameEdit cancelByEscape index=$_editingIndex');
            _cancelBrandNameEdit();
            return KeyEventResult.handled;
          }
          // 변경 없는 상태에서 Enter → 취소(닫기).
          // canSubmit=false 인 채로 Enter를 눌러도 아무 반응이 없으면 사용자가
          // 편집을 닫을 수 없어 혼란스럽다. Escape 와 동일하게 취소 처리한다.
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (!_canSubmitBrandNameEdit) {
              debugLog('brandNameEdit cancelByEnterNoChange index=$_editingIndex text=${_brandNameEditController.text}');
              _cancelBrandNameEdit();
              return KeyEventResult.handled;
            }
            // canSubmit=true 이면 TextField 의 onSubmitted 에서 처리한다.
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              // OutlineInputBorder 는 2px inset 렌더링으로 셀 경계와 갭이 생기므로
              // DecoratedBox(BoxDecoration) + InputBorder.none 으로 edge-to-edge 처리.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // 테이블 헤더(0xFF0E2F66)와 같은 색으로 통일해 편집 상태를 명확하게 표시
                  color: const Color(0xfff0f4ff),
                  border: Border.all(
                    color: const Color(0xFF0E2F66),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _brandNameEditController,
                  focusNode: _brandNameEditFocusNode,
                  autofocus: true,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(left: 6, right: 28, top: 0, bottom: 0),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  onSubmitted: (v) {
                    debugLog('brandNameEdit submitByEnter index=$_editingIndex text=${_brandNameEditController.text} paramValue=$v canSubmit=$_canSubmitBrandNameEdit');
                    // onSubmitted 의 v 는 IME 조합 중 Enter 시 컨트롤러 값과 다를 수 있으므로
                    // 컨트롤러 text 를 직접 사용한다.
                    _submitBrandNameEdit(_brandNameEditController.text);
                  },
                ),
              ),
            ),
            Positioned(
              top: 3,
              right: 3,
              bottom: 3,
              width: 22,
              // canSubmit=true → 헤더 색상 미니 버튼(흰 아이콘)으로 submit 유도
              // canSubmit=false → 투명 배경에 회색 아이콘으로 비활성 표시
              child: Tooltip(
                message: '변경 적용',
                child: MouseRegion(
                  cursor: canSubmit
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canSubmit
                        ? () {
                            debugLog('brandNameEdit submitByButton index=$_editingIndex text=${_brandNameEditController.text} canSubmit=$_canSubmitBrandNameEdit');
                            _submitBrandNameEdit(_brandNameEditController.text);
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      decoration: BoxDecoration(
                        color: canSubmit
                            ? const Color(0xFF0E2F66)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.keyboard_return,
                          size: 15,
                          color: canSubmit
                              ? Colors.white
                              : const Color(0xffb0bec5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isEditingBrand(Brand brand) {
    final editingIndex = _editingIndex;
    return editingIndex != null &&
        editingIndex >= 0 &&
        editingIndex < _brands.length &&
        identical(_brands[editingIndex], brand);
  }

  void _toggleBrandNameEdit(Brand brand, int index) {
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
    return nextName != _brands[editingIndex].brandName.trim();
  }

  Future<void> _submitBrandNameEdit(String value) async {
    debugLog('brandNameEdit submit index=$_editingIndex value=$value canSubmit=$_canSubmitBrandNameEdit');
    if (!_canSubmitBrandNameEdit) {
      debugLog('brandNameEdit submitSkipped canSubmit=false');
      return;
    }
    await _updateBrandName(value.trim());
  }

  Future<void> _updateBrandName(String brandName) async {
    final editingIndex = _editingIndex;
    debugLog('updateBrandName start editingIndex=$editingIndex brandName=$brandName');
    if (editingIndex == null || editingIndex >= _brands.length) {
      debugLog('updateBrandName aborted editingIndex=null or out of range');
      return;
    }
    final brand = _brands[editingIndex];
    debugLog('updateBrandName confirm dialog brandId=${brand.brandId} old=${brand.brandName} new=$brandName');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text("'$brandName' 명으로 변경하시겠습니까?"),
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
    // TODO: 실제 CRUD 호출 후 결과에 따라 아래 setState 실행 여부를 결정한다.
    const updateSucceeded = true;
    debugLog('updateBrandName result succeeded=$updateSucceeded editingIndexNow=$_editingIndex expectedIndex=$editingIndex');
    if (!updateSucceeded || _editingIndex != editingIndex) {
      debugLog('updateBrandName skippedStateUpdate succeeded=$updateSucceeded');
      return;
    }
    setState(() {
      _brands[editingIndex] = Brand(
        brandId: brand.brandId,
        customerId: brand.customerId,
        brandName: brandName,
      );
      Brand.setDatas(List<Brand>.from(_brands));
      _editingIndex = null;
      _brandNameEditController.clear();
    });
    debugLog('updateBrandName done brandId=${brand.brandId} newName=$brandName');
  }

  static void _noop() {}
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
