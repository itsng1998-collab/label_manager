import 'package:flutter/material.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/domain/item_manager_rules.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/application/special_columns.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/features/item/presentation/item_manager_table_dimensions.dart';
import 'package:label_manager/core/table_search.dart';
import 'package:label_manager/utils/item_manager_debug_log.dart';
import 'package:label_manager/utils/log_context.dart';

class ItemManageController {
  Object? _owner;
  TableSearchResult Function(String query)? _search;
  VoidCallback? _resetSearch;
  Future<void> Function()? _commitEditing;
  Set<int> Function()? _publishCheckedItemIds;
  bool Function()? _hasActiveEditing;

  Set<int> get publishCheckedItemIds =>
      Set<int>.unmodifiable(_publishCheckedItemIds?.call() ?? const <int>{});

  bool get hasActiveEditing => _hasActiveEditing?.call() ?? false;

    TableSearchResult search(String query) =>
      _search?.call(query) ?? TableSearchResult.unavailable;

  void resetSearch() => _resetSearch?.call();

  Future<void> commitEditing() async {
    await _commitEditing?.call();
  }

  void _attach({
    required Object owner,
    required TableSearchResult Function(String query) search,
    required VoidCallback resetSearch,
    required Future<void> Function() commitEditing,
    required Set<int> Function() publishCheckedItemIds,
    required bool Function() hasActiveEditing,
  }) {
    _owner = owner;
    _search = search;
    _resetSearch = resetSearch;
    _commitEditing = commitEditing;
    _publishCheckedItemIds = publishCheckedItemIds;
    _hasActiveEditing = hasActiveEditing;
  }

  void _detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _search = null;
    _resetSearch = null;
    _commitEditing = null;
    _publishCheckedItemIds = null;
    _hasActiveEditing = null;
  }
}

class ItemManage extends StatefulWidget {
  final List<ItemOfMarket> items;
  final int? selectedIndex;
  final void Function(ItemOfMarket row, int index)? onRowSelected;
  final ValueChanged<Rect>? onTableRectChanged;
  final ItemManagerDraftController? draftController;
  final LabelSize? labelSize;
  final int? marketId;
  final String emptyElementPayload;
  final Future<void> Function()? onExcelImport;
  final Future<void> Function()? onExcelExport;
  final Future<void> Function(ItemManagerDraftRow row)? onQrDataView;
  final Future<void> Function()? onItemOrderChange;
  final String? itemOrderDisabledReason;
  final Future<void> Function()? onCancelDraft;
  final Future<void> Function()? onSaveDraft;
  final Future<void> Function(ItemManagerDraftRow row)? onBeforeItemNameChange;
  final Future<void> Function(ItemManagerDraftRow row, int columnId)?
  onBeforeColumnChange;
  final Future<void> Function(Iterable<ItemManagerDraftRow> rows)?
  onBeforeRowsReordered;
  final Future<void> Function(Iterable<ItemManagerDraftRow> rows)?
  onBeforeRowsDeleted;
  final Future<void> Function(Iterable<String> rowKeys)? onRowsAdded;
  final bool commandBusy;
  final bool canEdit;
  final ItemManageController? controller;
  final VoidCallback? onEditingChanged;
  final ValueChanged<Set<int>>? onPublishCheckedItemIdsChanged;
  final Future<void> Function(TColumnBase column, bool checked)?
  onMinColumnCheckChanged;
  final VoidCallback? onReady;

  const ItemManage({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onRowSelected,
    this.onTableRectChanged,
    this.draftController,
    this.labelSize,
    this.marketId,
    this.emptyElementPayload = '',
    this.onExcelImport,
    this.onExcelExport,
    this.onQrDataView,
    this.onItemOrderChange,
    this.itemOrderDisabledReason,
    this.onCancelDraft,
    this.onSaveDraft,
    this.onBeforeItemNameChange,
    this.onBeforeColumnChange,
    this.onBeforeRowsReordered,
    this.onBeforeRowsDeleted,
    this.onRowsAdded,
    this.commandBusy = false,
    this.canEdit = true,
    this.controller,
    this.onEditingChanged,
    this.onPublishCheckedItemIdsChanged,
    this.onMinColumnCheckChanged,
    this.onReady,
  });

  @override
  State<ItemManage> createState() => _ItemManageState();
}

class _ItemManageState extends State<ItemManage> {
  static const String _publishColumnId = 'publish';
  static const String _menuSelectAll = 'selectAll';
  static const String _menuAdd = 'add';
  static const String _menuInsert = 'insert';
  static const String _menuDelete = 'delete';
  static const String _menuItemOrder = 'itemOrder';
  static const String _menuQrDataView = 'qrDataView';
  static const String _menuClearSelection = 'clearSelection';
  static const String _menuCheckSelectedPublish = 'checkSelectedPublish';
  static const String _menuUncheckSelectedPublish = 'uncheckSelectedPublish';
  static const EdgeInsets _menuItemPadding = EdgeInsets.symmetric(
    horizontal: 12,
  );
  static const Color _publishCheckedRowColor = Color(0xFFEAF4FF);
  static const Color _addedRowColor = Color(0xFFEAF7EE);
  static const Color _modifiedRowColor = Color(0xFFFFF6DF);
  static const double _minimizedHeaderColumnWidth = 70;

  final FortuneTableCheckboxController _publishCheckboxController =
      FortuneTableCheckboxController();
  final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();
  final FortuneTableFocusController _focusController =
      FortuneTableFocusController();
    final FortuneTableEditingController _editingController =
      FortuneTableEditingController();
  final TextEditingController _addCountController = TextEditingController(
    text: '1',
  );
  final TextEditingController _insertCountController = TextEditingController(
    text: '1',
  );
  List<ItemManagerDraftRow> _displayDraftRows = const [];
  Map<ItemOfMarket, ItemManagerDraftRow> _draftByDisplayItem = Map.identity();
  final Set<int> _publishCheckedItemIds = <int>{};
  ItemManagerDraftRow? _contextMenuDraftRow;
  int _lastFocusRequestId = 0;
  bool _projectingPublishChecks = false;
  bool _projectingSelection = false;
  bool _contextMenuOpen = false;
  String _activeSearchColumnId = 'itemName';
  int _searchStartIndex = 0;
  bool _readyScheduled = false;
  bool _headerMinCheckBusy = false;

  @override
  void initState() {
    super.initState();
    _publishCheckboxController.addListener(_handlePublishChecksChanged);
    _selectionController.addListener(_handleSelectionChanged);
    _editingController.addListener(_handleEditingStateChanged);
    widget.draftController?.addListener(_handleDraftChanged);
    _attachController();
  }

  @override
  void didUpdateWidget(covariant ItemManage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftController != widget.draftController) {
      oldWidget.draftController?.removeListener(_handleDraftChanged);
      widget.draftController?.addListener(_handleDraftChanged);
      _publishCheckedItemIds.clear();
      _publishCheckboxController.clearColumn(_publishColumnId);
      _notifyPublishCheckedItemIdsChanged();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      _attachController();
    }
    if (!identical(oldWidget.onReady, widget.onReady)) {
      _readyScheduled = false;
    }
    _projectPublishChecks();
    final rowCount = widget.draftController?.rows.length ?? widget.items.length;
    _selectionController.setSelectedRows(
      _selectionController.selectedRows.where((index) => index < rowCount),
    );
  }

  void _handleEditingStateChanged() {
    if (mounted) setState(() {});
    widget.onEditingChanged?.call();
  }

  void _handleDraftChanged() {
    final controller = widget.draftController;
    if (controller != null) {
      final existingItemIds = <int>{
        for (final row in controller.rows)
          if (row.sourceItemId != null) row.sourceItemId!,
      };
      final checkedCount = _publishCheckedItemIds.length;
      _publishCheckedItemIds.removeWhere(
        (itemId) => !existingItemIds.contains(itemId),
      );
      if (_publishCheckedItemIds.length != checkedCount) {
        _notifyPublishCheckedItemIdsChanged();
      }
      final indexes = <int>[];
      for (var index = 0; index < controller.rows.length; index += 1) {
        if (controller.selectedRowKeys.contains(
          controller.rows[index].rowKey,
        )) {
          indexes.add(index);
        }
      }
      _projectingSelection = true;
      _selectionController.setSelectedRows(indexes);
      _projectingSelection = false;
      if (controller.focusRequestId != _lastFocusRequestId &&
          indexes.isNotEmpty) {
        _lastFocusRequestId = controller.focusRequestId;
        final columnId = switch (controller.selectedColumnId) {
          ItemManagerFixedColumnIds.itemName => 'itemName',
          ItemManagerFixedColumnIds.element => 'element',
          final int value when value > 0 => 'dyn_$value',
          _ => null,
        };
        if (columnId != null) {
          _focusController.focusCell(indexes.first, columnId);
        }
      }
      _projectPublishChecks();
    }
    if (mounted) setState(() {});
  }

  void _handlePublishChecksChanged() {
    if (_projectingPublishChecks) return;
    final rows = widget.draftController?.rows;
    _publishCheckedItemIds.clear();
    for (final index in _publishCheckboxController.checkedRows(
      _publishColumnId,
    )) {
      final itemId = rows != null
          ? (index < rows.length ? rows[index].sourceItemId : null)
          : (index < widget.items.length
                ? widget.items[index].item.itemId
                : null);
      if (itemId != null) _publishCheckedItemIds.add(itemId);
    }
    _notifyPublishCheckedItemIdsChanged();
  }

  void _notifyPublishCheckedItemIdsChanged() {
    widget.onPublishCheckedItemIdsChanged?.call(
      Set<int>.unmodifiable(_publishCheckedItemIds),
    );
  }

  void _handleSelectionChanged() {
    if (_projectingSelection) return;
    final controller = widget.draftController;
    if (controller == null) return;
    final rowKeys = <String>[];
    for (final index in _selectionController.selectedRows) {
      if (index >= 0 && index < controller.rows.length) {
        rowKeys.add(controller.rows[index].rowKey);
      }
    }
    controller.setSelection(rowKeys);
  }

  void _projectPublishChecks() {
    final rows = widget.draftController?.rows;
    if (rows == null) return;
    final indexes = <int>[];
    for (var index = 0; index < rows.length; index += 1) {
      final itemId = rows[index].sourceItemId;
      if (itemId != null && _publishCheckedItemIds.contains(itemId)) {
        indexes.add(index);
      }
    }
    _projectingPublishChecks = true;
    _publishCheckboxController.setCheckedRows(_publishColumnId, indexes);
    _projectingPublishChecks = false;
  }

  @override
  void dispose() {
    widget.draftController?.removeListener(_handleDraftChanged);
    _publishCheckboxController.removeListener(_handlePublishChecksChanged);
    _selectionController.removeListener(_handleSelectionChanged);
    _editingController.removeListener(_handleEditingStateChanged);
    _addCountController.dispose();
    _insertCountController.dispose();
    _publishCheckboxController.dispose();
    _selectionController.dispose();
    _focusController.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  void _attachController() {
    widget.controller?._attach(
      owner: this,
      search: _search,
      resetSearch: () => _searchStartIndex = 0,
      commitEditing: _editingController.commitEditing,
      publishCheckedItemIds: () => _publishCheckedItemIds,
      hasActiveEditing: () => _editingController.hasActiveEditing,
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleReady();
    final displayItems = _resolveDisplayItems();
    final columns = _columns;
    debugLog(
      'rows=${displayItems.length}, '
      'dynamicColumns=${TColumn.datas?.length ?? 0}, columns=${columns.length}',
    );
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onSecondaryTapDown: _showEmptyTableContextMenu,
            child: FortuneTable<ItemOfMarket>(
              rows: displayItems,
              columns: columns,
              autoFitColumns: true,
              headerTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
              headerMaxLines: 2,
              headerWrapAfterCharacters: 2,
              headerLineSpacingReduction: 2,
              headerCheckboxPadding: 1,
              headerCheckboxLabelGap: 1,
              selectedIndex: widget.selectedIndex,
              selectionController: _selectionController,
              focusController: _focusController,
              editingController: _editingController,
              multiSelectionEnabled: true,
              onRowSelected: _handleRowSelected,
              onCellActivated: (_, _, columnId) {
                if (_activeSearchColumnId != columnId) {
                  _searchStartIndex = 0;
                }
                _activeSearchColumnId = columnId;
              },
              onRowSecondaryTapDown: _showTableContextMenu,
              onRectChanged: widget.onTableRectChanged,
              rowColorBuilder: _rowColor,
            ),
          ),
        ),
        _buildCommandFooter(),
      ],
    );
  }

  void _scheduleReady() {
    if (_readyScheduled || widget.onReady == null) return;
    final onReady = widget.onReady!;
    _readyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onReady();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  TableSearchResult _search(String query) {
    final rows = _resolveDisplayItems();
    final columns = _columns;
    final columnIndex = columns.indexWhere(
      (column) => column.id == _activeSearchColumnId,
    );
    if (rows.isEmpty || columnIndex < 0) {
      return TableSearchResult.unavailable;
    }
    final column = columns[columnIndex];
    for (var index = _searchStartIndex; index < rows.length; index += 1) {
      if (!column.text(rows[index]).contains(query)) continue;
      _searchStartIndex = index + 1;
      _selectionController.setSelectedRows([index]);
      final draft = _draftByDisplayItem[rows[index]];
      if (draft != null) {
        widget.draftController?.setSelection(
          [draft.rowKey],
          anchorRowKey: draft.rowKey,
        );
      }
      _focusController.focusCell(index, column.id);
      widget.onRowSelected?.call(rows[index], index);
      return TableSearchResult.found;
    }
    return TableSearchResult.reachedEnd;
  }

  Widget _buildCommandFooter() {
    if (!widget.canEdit) {
      return const SizedBox.shrink();
    }
    final dirty = widget.draftController?.isDirty == true;
    final cleanEnabled =
      !widget.commandBusy && !dirty && !_editingController.hasActiveEditing;
    final dirtyEnabled =
        widget.canEdit &&
        !widget.commandBusy && dirty;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EB))),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed:
                widget.canEdit && cleanEnabled && widget.onExcelImport != null
                ? widget.onExcelImport
                : null,
            child: const Text('엑셀 가져오기'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: cleanEnabled && widget.onExcelExport != null
                ? widget.onExcelExport
                : null,
            child: const Text('엑셀 내보내기'),
          ),
          if (widget.commandBusy) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            const Text('처리 중'),
          ],
          const Spacer(),
          OutlinedButton(
            onPressed: dirtyEnabled && widget.onCancelDraft != null
                ? widget.onCancelDraft
                : null,
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: dirtyEnabled && widget.onSaveDraft != null
                ? widget.onSaveDraft
                : null,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  List<ItemOfMarket> _resolveDisplayItems() {
    final controller = widget.draftController;
    final labelSize = widget.labelSize;
    final marketId = widget.marketId;
    if (controller == null || labelSize == null || marketId == null) {
      _displayDraftRows = const [];
      _draftByDisplayItem = Map.identity();
      return widget.items;
    }
    _displayDraftRows = controller.rows;
    final displayItems = <ItemOfMarket>[];
    final draftByDisplayItem =
        Map<ItemOfMarket, ItemManagerDraftRow>.identity();
    for (final row in _displayDraftRows) {
      final display = row.toPreviewItem(
        marketId: marketId,
        labelSizeId: labelSize.labelSizeId,
        labelSizeName: labelSize.labelSizeName,
      );
      displayItems.add(display);
      draftByDisplayItem[display] = row;
    }
    _draftByDisplayItem = draftByDisplayItem;
    return displayItems;
  }

  void _handleRowSelected(ItemOfMarket row, int index) {
    final draft = _draftByDisplayItem[row];
    if (draft != null) {
      final controller = widget.draftController!;
      final selectedKeys = <String>[];
      for (final selectedIndex in _selectionController.selectedRows) {
        if (selectedIndex >= 0 && selectedIndex < controller.rows.length) {
          selectedKeys.add(controller.rows[selectedIndex].rowKey);
        }
      }
      controller.setSelection(selectedKeys, anchorRowKey: draft.rowKey);
    }
    widget.onRowSelected?.call(row, index);
  }

  Color? _rowColor(ItemOfMarket row, int rowIndex, bool selected) {
    if (selected) return null;
    final draft = _draftByDisplayItem[row];
    if (draft?.rowState == ItemManagerDraftRowState.added ||
        draft?.rowState == ItemManagerDraftRowState.imported) {
      return _addedRowColor;
    }
    if (draft?.rowState == ItemManagerDraftRowState.modified) {
      return _modifiedRowColor;
    }
    return _publishCheckboxController.isChecked(_publishColumnId, rowIndex)
        ? _publishCheckedRowColor
        : null;
  }

  Future<void> _showTableContextMenu(
    ItemOfMarket row,
    int rowIndex,
    TapDownDetails details,
  ) async {
    await _showContextMenu(details, draftRow: _draftByDisplayItem[row]);
  }

  Future<void> _showEmptyTableContextMenu(TapDownDetails details) async {
    await _showContextMenu(details);
  }

  Future<void> _showContextMenu(
    TapDownDetails details, {
    ItemManagerDraftRow? draftRow,
  }) async {
    if (_contextMenuOpen) {
      ItemManagerDebugLog.event(
        'contextMenuPopup',
        'duplicateOpeningIgnored',
        fields: {
          'x': details.globalPosition.dx.round(),
          'y': details.globalPosition.dy.round(),
        },
      );
      return;
    }
    _contextMenuOpen = true;
    _contextMenuDraftRow = draftRow;
    try {
      await _showContextMenuRoute(details);
    } finally {
      _contextMenuOpen = false;
    }
  }

  Future<void> _showContextMenuRoute(TapDownDetails details) async {
    final menuRouteMarkerKey = GlobalKey();
    final menuRouteEndKey = GlobalKey();
    final menuTapRegionGroupId = Object();
    final popupTrace = ItemManagerDebugLog.nextTrace('contextMenuPopup');
    ItemManagerDebugLog.event(
      'contextMenuPopup',
      'opening',
      trace: popupTrace,
      fields: {
        'version': ItemManagerDebugLog.version,
        'x': details.globalPosition.dx.round(),
        'y': details.globalPosition.dy.round(),
      },
    );
    final mutationEnabled = widget.canEdit && !widget.commandBusy;
    final publishSelectionEnabled =
      !widget.commandBusy && widget.draftController?.isDirty != true;
    final orderDisabledReason = widget.draftController?.isDirty == true
        ? '저장 완료 또는 변경 취소 확정 후 순서 변경을 실행해 주세요.'
        : widget.commandBusy
        ? '현재 작업이 끝난 후 실행해 주세요.'
        : widget.itemOrderDisabledReason;
    final command = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        _countMenuItem(
          key: menuRouteMarkerKey,
          label: '품목 추가',
          command: _menuAdd,
          controller: _addCountController,
          enabled: mutationEnabled && widget.draftController != null,
          tapRegionGroupId: menuTapRegionGroupId,
          onTapOutside: (event, menuContext) =>
              _dismissContextMenuOnOutsideTap(
                event,
                menuContext,
                menuRouteMarkerKey,
                menuRouteEndKey,
                popupTrace,
                _menuAdd,
              ),
        ),
        _countMenuItem(
          label: '품목 삽입',
          command: _menuInsert,
          controller: _insertCountController,
          enabled:
              mutationEnabled &&
              widget.draftController != null &&
              _selectionController.hasSelection,
          tapRegionGroupId: menuTapRegionGroupId,
          onTapOutside: (event, menuContext) =>
              _dismissContextMenuOnOutsideTap(
                event,
                menuContext,
                menuRouteMarkerKey,
                menuRouteEndKey,
                popupTrace,
                _menuInsert,
              ),
        ),
        PopupMenuItem<String>(
          value: _menuDelete,
          enabled:
              mutationEnabled &&
              widget.draftController != null &&
              _selectionController.hasSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('품목 삭제'),
        ),
        PopupMenuItem<String>(
          value: _menuItemOrder,
          enabled:
              widget.onItemOrderChange != null && orderDisabledReason == null,
          height: orderDisabledReason == null
              ? fortuneContextMenuRowHeight
              : fortuneContextMenuRowHeight + 18,
          padding: _menuItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('순서 변경'),
              if (orderDisabledReason case final reason?)
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777777),
                  ),
                ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: _menuQrDataView,
          enabled: _contextMenuDraftRow != null && widget.onQrDataView != null,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: const Text('QR코드 데이터 보기'),
        ),
        const PopupMenuDivider(height: fortuneContextMenuDividerHeight),
        PopupMenuItem<String>(
          value: _menuSelectAll,
          enabled: mutationEnabled,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('전체 선택'),
        ),
        PopupMenuItem<String>(
          value: _menuClearSelection,
          enabled: mutationEnabled,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('전체 선택 해제'),
        ),
        const PopupMenuDivider(height: fortuneContextMenuDividerHeight),
        PopupMenuItem<String>(
          value: _menuCheckSelectedPublish,
          enabled: publishSelectionEnabled && _selectionController.hasSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: const Text('블럭 선택 발행 체크'),
        ),
        PopupMenuItem<String>(
          key: menuRouteEndKey,
          value: _menuUncheckSelectedPublish,
          enabled: publishSelectionEnabled && _selectionController.hasSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: const Text('블럭 선택 발행 체크 해제'),
        ),
      ],
    );
    ItemManagerDebugLog.event(
      'contextMenuPopup',
      'routeCompleted',
      trace: popupTrace,
      fields: {
        'command': command,
        'markerMounted': menuRouteMarkerKey.currentContext != null,
        'focus': FocusManager.instance.primaryFocus?.debugLabel,
      },
    );
    if (!mounted || command == null) return;
    while (mounted && menuRouteMarkerKey.currentContext != null) {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    ItemManagerDebugLog.event(
      'contextMenuPopup',
      'dispatchReady',
      trace: popupTrace,
      fields: {'command': command},
    );
    await _handleContextMenuCommand(command);
  }

  PopupMenuItem<String> _countMenuItem({
    Key? key,
    required String label,
    required String command,
    required TextEditingController controller,
    required bool enabled,
    required Object tapRegionGroupId,
    required void Function(PointerDownEvent event, BuildContext menuContext)
    onTapOutside,
  }) {
    return PopupMenuItem<String>(
      key: key,
      enabled: false,
      height: fortuneContextMenuRowHeight,
      padding: _menuItemPadding,
      child: Builder(
        builder: (menuContext) {
          final textColor = enabled
              ? Theme.of(menuContext).colorScheme.onSurface
              : Theme.of(menuContext).disabledColor;
          final textStyle = TextStyle(color: textColor);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                mouseCursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onTap: enabled
                    ? () => Navigator.of(menuContext).pop(command)
                    : null,
                child: SizedBox(
                  width: 102,
                  child: Text(label, style: textStyle),
                ),
              ),
              SizedBox(
                width: 44,
                height: 26,
                child: TextField(
                  groupId: tapRegionGroupId,
                  controller: controller,
                  enabled: enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 5),
                    border: OutlineInputBorder(),
                  ),
                  onTapOutside: (event) => onTapOutside(event, menuContext),
                  onSubmitted: enabled
                      ? (_) => Navigator.of(menuContext).pop(command)
                      : null,
                ),
              ),
              const SizedBox(width: 4),
              Text('개', style: textStyle),
            ],
          );
        },
      ),
    );
  }

  void _dismissContextMenuOnOutsideTap(
    PointerDownEvent event,
    BuildContext menuContext,
    GlobalKey firstItemKey,
    GlobalKey lastItemKey,
    String trace,
    String sourceCommand,
  ) {
    final firstBox =
        firstItemKey.currentContext?.findRenderObject() as RenderBox?;
    final lastBox = lastItemKey.currentContext?.findRenderObject() as RenderBox?;
    if (firstBox == null || lastBox == null) {
      ItemManagerDebugLog.event(
        'contextMenuPopup',
        'tapOutsideMissingBounds',
        trace: trace,
        fields: {
          'source': sourceCommand,
          'firstBox': firstBox != null,
          'lastBox': lastBox != null,
          'x': event.position.dx.round(),
          'y': event.position.dy.round(),
        },
      );
      Navigator.of(menuContext).pop();
      return;
    }
    final menuRect = _globalRect(firstBox).expandToInclude(_globalRect(lastBox));
    final inside = menuRect.contains(event.position);
    ItemManagerDebugLog.event(
      'contextMenuPopup',
      'tapOutside',
      trace: trace,
      fields: {
        'source': sourceCommand,
        'kind': event.kind.name,
        'buttons': event.buttons,
        'x': event.position.dx.round(),
        'y': event.position.dy.round(),
        'menuLeft': menuRect.left.round(),
        'menuTop': menuRect.top.round(),
        'menuRight': menuRect.right.round(),
        'menuBottom': menuRect.bottom.round(),
        'inside': inside,
        'focus': FocusManager.instance.primaryFocus?.debugLabel,
      },
    );
    if (inside) return;
    Navigator.of(menuContext).pop();
  }

  Rect _globalRect(RenderBox box) {
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _handleContextMenuCommand(String command) async {
    final trace = ItemManagerDebugLog.nextTrace('contextMenu');
    ItemManagerDebugLog.event(
      'contextMenu',
      'requested',
      trace: trace,
      fields: {
        'command': command,
        'busy': widget.commandBusy,
        'selected': _selectionController.selectedRows.length,
      },
    );
    if (widget.commandBusy) {
      ItemManagerDebugLog.event('contextMenu', 'blocked', trace: trace);
      return;
    }
    switch (command) {
      case _menuAdd:
        await _addDraftRows(_addCountController.text);
      case _menuInsert:
        await _insertDraftRows(_insertCountController.text);
      case _menuDelete:
        await _deleteSelectedDraftRows();
      case _menuItemOrder:
        await widget.onItemOrderChange?.call();
      case _menuQrDataView:
        final row = _contextMenuDraftRow;
        final targetExists =
            row != null &&
            (widget.draftController?.rows.any(
                  (current) => current.rowKey == row.rowKey,
                ) ??
                false);
        if (targetExists) await widget.onQrDataView?.call(row);
      case _menuSelectAll:
        _selectionController.selectAll(
          widget.draftController?.rows.length ?? widget.items.length,
        );
      case _menuClearSelection:
        _selectionController.clear();
        widget.draftController?.setSelection(const []);
      case _menuCheckSelectedPublish:
        _setSelectedPublishChecked(true);
      case _menuUncheckSelectedPublish:
        _setSelectedPublishChecked(false);
    }
  }

  Future<void> _addDraftRows(String rawCount) async {
    final trace = ItemManagerDebugLog.nextTrace('addRows');
    final count = _parseCount(rawCount);
    if (count == null) {
      ItemManagerDebugLog.event('addRows', 'invalidCount', trace: trace);
      return;
    }
    try {
      final added = widget.draftController!.addRows(
        count,
        emptyElementPayload: widget.emptyElementPayload,
      );
      try {
        await widget.onRowsAdded?.call(added.map((row) => row.rowKey));
      } catch (error) {
        widget.draftController!.deleteRows(added.map((row) => row.rowKey));
        rethrow;
      }
      _selectDraftRows(added);
      _focusFirstDraftRowAfterBuild(added);
      ItemManagerDebugLog.event(
        'addRows',
        'completed',
        trace: trace,
        fields: {
          'count': added.length,
          'rows': widget.draftController!.rows.length,
        },
      );
    } catch (error) {
      ItemManagerDebugLog.event(
        'addRows',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      _showWarning(error is StateError ? error.message : '$error');
    }
  }

  Future<void> _insertDraftRows(String rawCount) async {
    final trace = ItemManagerDebugLog.nextTrace('insertRows');
    final count = _parseCount(rawCount);
    if (count == null) {
      ItemManagerDebugLog.event('insertRows', 'invalidCount', trace: trace);
      return;
    }
    final controller = widget.draftController!;
    final selectedIndexes = _selectionController.selectedRows.toList()..sort();
    final anchorKey =
        controller.anchorRowKey ??
        (selectedIndexes.isEmpty
            ? null
            : controller.rows[selectedIndexes.last].rowKey);
    if (anchorKey == null) {
      ItemManagerDebugLog.event('insertRows', 'missingAnchor', trace: trace);
      _showWarning('삽입할 기준 품목을 선택해 주세요.');
      return;
    }
    try {
      final anchorIndex = controller.rows.indexWhere(
        (row) => row.rowKey == anchorKey,
      );
      await widget.onBeforeRowsReordered?.call(
        controller.rows.skip(anchorIndex + 1),
      );
      final added = controller.insertRowsAfter(
        anchorKey,
        count,
        emptyElementPayload: widget.emptyElementPayload,
      );
      try {
        await widget.onRowsAdded?.call(added.map((row) => row.rowKey));
      } catch (error) {
        controller.deleteRows(added.map((row) => row.rowKey));
        rethrow;
      }
      _selectDraftRows(added);
      ItemManagerDebugLog.event(
        'insertRows',
        'completed',
        trace: trace,
        fields: {
          'count': added.length,
          'anchor': anchorKey,
          'rows': controller.rows.length,
        },
      );
    } catch (error) {
      ItemManagerDebugLog.event(
        'insertRows',
        'failed',
        trace: trace,
        fields: {'error': error.runtimeType},
      );
      _showWarning(error is StateError ? error.message : '$error');
    }
  }

  Future<void> _deleteSelectedDraftRows() async {
    final trace = ItemManagerDebugLog.nextTrace('deleteRows');
    final controller = widget.draftController!;
    final selectedIndexes =
        _selectionController.selectedRows
            .where((index) => index >= 0 && index < controller.rows.length)
            .toList()
          ..sort();
    if (selectedIndexes.isEmpty) {
      ItemManagerDebugLog.event('deleteRows', 'emptySelection', trace: trace);
      return;
    }
    ItemManagerDebugLog.event(
      'deleteRows',
      'confirmShown',
      trace: trace,
      fields: {'count': selectedIndexes.length},
    );
    final confirmationMessage = itemManagerDeleteConfirmationMessage(
      firstItemName: controller.rows[selectedIndexes.first].itemName,
      selectedCount: selectedIndexes.length,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('품목 삭제'),
        content: Text(confirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 편집'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    ItemManagerDebugLog.event(
      'deleteRows',
      'confirmCompleted',
      trace: trace,
      fields: {'confirmed': confirmed, 'mounted': mounted},
    );
    if (confirmed != true || !mounted) return;
    final rowKeys = selectedIndexes
        .map((index) => controller.rows[index].rowKey)
        .toList(growable: false);
    final selectedRows = selectedIndexes
        .map((index) => controller.rows[index])
        .toList(growable: false);
    try {
      await widget.onBeforeRowsDeleted?.call(selectedRows);
      await widget.onBeforeRowsReordered?.call(
        controller.rows.skip(selectedIndexes.first),
      );
    } catch (error) {
      if (mounted) _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
      return;
    }
    final nextKey = controller.deleteRows(rowKeys);
    ItemManagerDebugLog.event(
      'deleteRows',
      'completed',
      trace: trace,
      fields: {
        'count': rowKeys.length,
        'rows': controller.rows.length,
        'deletedExisting': controller.deletedSourceItemIds.length,
        'nextKey': nextKey,
      },
    );
    if (nextKey == null) {
      _selectionController.clear();
      return;
    }
    final nextIndex = controller.rows.indexWhere(
      (row) => row.rowKey == nextKey,
    );
    if (nextIndex >= 0) {
      _selectionController.setSelectedRows([nextIndex]);
      _notifySelectedDraftRow(controller.rows[nextIndex], nextIndex);
    }
  }

  int? _parseCount(String rawCount) {
    final count = int.tryParse(rawCount.trim());
    if (count == null || count < 1) {
      _showWarning('개수는 1 이상의 숫자로 입력해 주세요.');
      return null;
    }
    return count;
  }

  void _selectDraftRows(List<ItemManagerDraftRow> rows) {
    final controller = widget.draftController!;
    final rowKeys = rows.map((row) => row.rowKey).toSet();
    final indexes = <int>[];
    for (var index = 0; index < controller.rows.length; index++) {
      if (rowKeys.contains(controller.rows[index].rowKey)) indexes.add(index);
    }
    _selectionController.setSelectedRows(indexes);
    if (indexes.isNotEmpty) {
      _notifySelectedDraftRow(controller.rows[indexes.first], indexes.first);
    }
  }

  void _focusFirstDraftRowAfterBuild(List<ItemManagerDraftRow> rows) {
    if (rows.isEmpty) return;
    final firstRowKey = rows.first.rowKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rowIndex = widget.draftController?.rows.indexWhere(
        (row) => row.rowKey == firstRowKey,
      );
      if (rowIndex == null || rowIndex < 0) return;
      _focusController.focusCell(rowIndex, 'itemName');
    });
  }

  void _notifySelectedDraftRow(ItemManagerDraftRow row, int index) {
    final labelSize = widget.labelSize!;
    widget.onRowSelected?.call(
      row.toPreviewItem(
        marketId: widget.marketId!,
        labelSizeId: labelSize.labelSizeId,
        labelSizeName: labelSize.labelSizeName,
      ),
      index,
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canEditDynamicColumn(ItemManagerDraftRow? draft) {
    return itemManagerCanPersistDynamicCell(
      canManageItemStructure: widget.canEdit,
      commandBusy: widget.commandBusy,
      hasDraftRow: draft != null,
    );
  }

  Future<void> _selectBmpImage(ItemOfMarket row, TColumn column) async {
    final draft = _draftByDisplayItem[row];
    if (!_canEditDynamicColumn(draft)) return;
    final targetDraft = draft!;
    const bmpGroup = XTypeGroup(label: 'BMP 이미지', extensions: <String>['bmp']);
    final file = await openFile(acceptedTypeGroups: const [bmpGroup]);
    if (file == null || !mounted) return;
    final fileName = file.name.replaceFirst(
      RegExp(r'\.bmp$', caseSensitive: false),
      '',
    );
    try {
      await widget.onBeforeColumnChange?.call(targetDraft, column.columnId);
    } catch (error) {
      if (mounted) _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
      return;
    }
    widget.draftController!.updateColumnValue(
      targetDraft.rowKey,
      columnId: column.columnId,
      editable: true,
      dataString: fileName,
    );
    _showWarning(
      '경로는 저장되지 않고 파일명만 저장됩니다. 같은 파일명이 여러 위치에 있으면 출력 환경에 따라 다른 이미지가 사용될 수 있습니다.',
    );
  }

  void _setSelectedPublishChecked(bool checked) {
    if (widget.commandBusy || widget.draftController?.isDirty == true) {
      return;
    }
    final selectedRows = _selectionController.selectedRows;
    if (selectedRows.isEmpty) return;
    final checkedRows = _publishCheckboxController.checkedRows(
      _publishColumnId,
    );
    final nextRows = checked
        ? <int>{...checkedRows, ...selectedRows}
        : checkedRows.difference(selectedRows);
    _publishCheckboxController.setCheckedRows(_publishColumnId, nextRows);
  }

  Future<void> _toggleMinColumnCheck(TColumnBase column, bool checked) async {
    if (_headerMinCheckBusy || widget.commandBusy) {
      return;
    }
    final onChanged = widget.onMinColumnCheckChanged;
    if (onChanged == null) {
      return;
    }
    final previous = column.useMinColumnCheck;
    setState(() {
      _headerMinCheckBusy = true;
      column.useMinColumnCheck = checked;
    });
    try {
      await onChanged(column, checked);
    } catch (error) {
      if (mounted) {
        setState(() {
          column.useMinColumnCheck = previous;
        });
        _showWarning('헤더 최소표시 설정을 저장하지 못했습니다.\n$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _headerMinCheckBusy = false;
        });
      }
    }
  }

  TColumnBase? get _elementColumn {
    for (final column in TColumnSpecial.datas ?? const <TColumnBase>[]) {
      if (column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword) {
        return column;
      }
    }
    return null;
  }

  double _dynamicColumnWidth(TColumn column) =>
    column.useMinColumnCheck ? _minimizedHeaderColumnWidth : 70;

  double _elementColumnWidth(TColumnBase? column) =>
      column?.useMinColumnCheck == true
      ? _minimizedHeaderColumnWidth
      : itemManagerExpandedElementColumnWidth;

  List<FortuneTableColumn<ItemOfMarket>> get _columns {
    final publishSelectionEnabled =
      !widget.commandBusy && widget.draftController?.isDirty != true;
    final extras = List<TColumn>.from(TColumn.datas ?? const <TColumn>[]);
    final elementColumn = _elementColumn;
    final extraColumns = extras
        .map(
          (c) => FortuneTableColumn<ItemOfMarket>(
            id: 'dyn_${c.columnId}',
            header: c.columnName,
            initialWidth: _dynamicColumnWidth(c),
            minWidth: _minimizedHeaderColumnWidth,
            autoFit: !c.useMinColumnCheck,
            headerCheckboxValue: c.useMinColumnCheck,
            headerCheckboxEnabled: !_headerMinCheckBusy && !widget.commandBusy,
            onHeaderCheckboxChanged:
                (checked) => _toggleMinColumnCheck(c, checked),
            text: (row) {
              final draft = _draftByDisplayItem[row];
              if (draft != null) {
                return widget.draftController!.columnValue(draft, c.columnId);
              }
              return TColumnContent.get(
                    c.columnId,
                    row.item.itemId,
                  )?.dataString ??
                  '';
            },
            isTextEditable: (row, _) {
              final draft = _draftByDisplayItem[row];
              return c.columnType.code != TColumnType.TYPE_IMAGE &&
                  _canEditDynamicColumn(draft);
            },
            onDoubleTap:
              widget.canEdit && c.columnType.code == TColumnType.TYPE_IMAGE
                ? (row, _) => _selectBmpImage(row, c)
                : null,
            onTextCommitted: (row, _, value) async {
              final draft = _draftByDisplayItem[row];
              if (draft == null) return;
              final editable = draft.isNew ||
                (widget.draftController!.scopedColumnContents
                    .get(c.columnId, draft.sourceItemId!)
                    ?.editable ??
                  false);
              try {
                await widget.onBeforeColumnChange?.call(draft, c.columnId);
              } catch (error) {
                if (mounted) {
                  _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
                }
                return;
              }
              final applied = widget.draftController!.updateColumnValue(
                draft.rowKey,
                columnId: c.columnId,
                editable: editable,
                dataString: value,
              );
              ItemManagerDebugLog.event(
                'editColumn',
                applied ? 'completed' : 'validationRejected',
                fields: {
                  'rowKey': draft.rowKey,
                  'sourceItemId': draft.sourceItemId,
                  'columnId': c.columnId,
                  'length': value.length,
                },
              );
              if (!applied) {
                _showWarning('${c.columnName} 값이 GS1 AI 형식과 일치하지 않습니다.');
              }
            },
          ),
        )
        .toList();

    return [
      FortuneTableColumn<ItemOfMarket>(
        id: _publishColumnId,
        header: '발행',
        initialWidth: 40,
        minWidth: 40,
        text: _empty,
        checkboxController: !publishSelectionEnabled
            ? null
            : _publishCheckboxController,
        checkboxValueAt: !publishSelectionEnabled
            ? (_, rowIndex) => _publishCheckboxController.isChecked(
                _publishColumnId,
                rowIndex,
              )
            : null,
      ),
      const FortuneTableColumn<ItemOfMarket>(
        id: 'labelSize',
        header: '라벨크기',
        initialWidth: 100,
        minWidth: 60,
        text: _labelSize,
      ),
      FortuneTableColumn<ItemOfMarket>(
        id: 'itemName',
        header: '품명',
        initialWidth: 280,
        minWidth: 70,
        text: _itemName,
        isTextEditable: (row, _) =>
            widget.canEdit &&
            !widget.commandBusy &&
            _draftByDisplayItem.containsKey(row),
        onTextCommitted: (row, _, value) async {
          final draft = _draftByDisplayItem[row];
          if (draft == null) return;
          try {
            await widget.onBeforeItemNameChange?.call(draft);
          } catch (error) {
            if (mounted) {
              _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
            }
            return;
          }
          widget.draftController!.updateItemName(draft.rowKey, value);
          ItemManagerDebugLog.event(
            'editItemName',
            'completed',
            fields: {
              'rowKey': draft.rowKey,
              'sourceItemId': draft.sourceItemId,
              'length': value.length,
            },
          );
        },
      ),
      FortuneTableColumn<ItemOfMarket>(
        id: 'element',
        header: '주원료',
        initialWidth: _elementColumnWidth(elementColumn),
        minWidth: _minimizedHeaderColumnWidth,
        autoFit: false,
        headerCheckboxValue: elementColumn?.useMinColumnCheck,
        headerCheckboxEnabled: !_headerMinCheckBusy && !widget.commandBusy,
        onHeaderCheckboxChanged: elementColumn == null
            ? null
            : (checked) => _toggleMinColumnCheck(elementColumn, checked),
        text: _element,
      ),
      ...extraColumns,
    ];
  }
}

// 단순 텍스트 추출 헬퍼
String _empty(ItemOfMarket row) => '';
String _labelSize(ItemOfMarket row) => row.item.labelSizeName;
String _itemName(ItemOfMarket row) => row.item.itemName;
String _element(ItemOfMarket row) => row.item.element;
