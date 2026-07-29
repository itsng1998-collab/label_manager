import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;

import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/core/table_search.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

class AutoItemUpdatePageController {
  Object? _owner;
  TableSearchResult Function(String query)? _search;
  VoidCallback? _resetSearch;
  Future<void> Function()? _commitEditing;
  bool Function()? _hasActiveEditing;

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
    required bool Function() hasActiveEditing,
  }) {
    _owner = owner;
    _search = search;
    _resetSearch = resetSearch;
    _commitEditing = commitEditing;
    _hasActiveEditing = hasActiveEditing;
  }

  void _detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
    _search = null;
    _resetSearch = null;
    _commitEditing = null;
    _hasActiveEditing = null;
  }
}

class AutoItemUpdatePage extends StatefulWidget {
  const AutoItemUpdatePage({
    super.key,
    required this.columns,
    this.draftController,
    this.controller,
    this.onEditingChanged,
    this.onTableRectChanged,
    this.sourceRows = const <AutoItemUpdateSourceSeed>[],
    this.sourceReady = false,
    this.commandBusy = false,
    this.canEdit = true,
    this.onDeleteRows,
    this.onApplyStagedRows,
    this.onRefresh,
    this.onCancelDraft,
    this.onSaveDraft,
  });

  final List<TColumn> columns;
  final AutoItemUpdateDraftController? draftController;
  final AutoItemUpdatePageController? controller;
  final VoidCallback? onEditingChanged;
  final ValueChanged<Rect>? onTableRectChanged;
  final List<AutoItemUpdateSourceSeed> sourceRows;
  final bool sourceReady;
  final bool commandBusy;
  final bool canEdit;
  final Future<void> Function(Iterable<String> rowKeys)? onDeleteRows;
  final Future<void> Function()? onApplyStagedRows;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onCancelDraft;
  final Future<void> Function()? onSaveDraft;

  @override
  State<AutoItemUpdatePage> createState() => _AutoItemUpdatePageState();
}

class _AutoItemUpdatePageState extends State<AutoItemUpdatePage> {
  static const String _menuAdd = 'add';
  static const String _menuDelete = 'delete';
  static const String _menuDeleteSelected = 'deleteSelected';
  static const String _menuRefresh = 'refresh';
  static const Color _addedRowColor = Color(0xFFEAF7EE);
  static const Color _modifiedRowColor = Color(0xFFFFF6DF);
  static const Color _stagedRowColor = Color(0xFFEAF4FF);
  static const double _sourceMinWidth = 240;
  static const double _railWidth = 48;
  static const double _targetMinWidth = 480;
  static const EdgeInsets _menuItemPadding = EdgeInsets.symmetric(horizontal: 12);
  static const double _sourceHeaderHeight = 36;
  static const double _sourceRowHeight = 28;
  static const Color _sourceRowSelectedColor = Color(0xFFDCEBFF);
  static const Color _targetDropZoneColor = Color(0x22007ACC);
  static const double _sourcePointerMoveThreshold = 8;
  static const Duration _sourceRowDragStartDelay = Duration(milliseconds: 80);

  static String _sourceItemName(AutoItemUpdateSourceSeed row) => row.itemName;

  final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();
  final FortuneTableFocusController _focusController =
      FortuneTableFocusController();
  final FortuneTableEditingController _editingController =
      FortuneTableEditingController();
    final FocusNode _sourcePaneFocusNode = FocusNode();
  final GlobalKey _sourceTableViewportKey = GlobalKey();
  bool _contextMenuOpen = false;
  bool _targetDropActive = false;
  bool _sourceAppendBusy = false;
  final Set<int> _selectedSourceItemIds = <int>{};
  int? _sourceAnchorIndex;
  String _activeSearchColumnId = 'itemName';
  int _searchStartIndex = 0;
  Offset? _sourcePointerDownPosition;
  bool _sourcePointerMoved = false;
  bool _deferSourceSingleSelection = false;
  int? _deferredSourceSelectionIndex;

  @override
  void initState() {
    super.initState();
    widget.draftController?.addListener(_handleDraftChanged);
    _selectionController.addListener(_handleSelectionChanged);
    _editingController.addListener(_handleEditingChanged);
    _attachController();
    _syncDraftSelection();
  }

  @override
  void didUpdateWidget(covariant AutoItemUpdatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftController != widget.draftController) {
      oldWidget.draftController?.removeListener(_handleDraftChanged);
      widget.draftController?.addListener(_handleDraftChanged);
      _syncDraftSelection();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      _attachController();
    }
  }

  void _attachController() {
    widget.controller?._attach(
      owner: this,
      search: _search,
      resetSearch: () => _searchStartIndex = 0,
      commitEditing: _editingController.commitEditing,
      hasActiveEditing: () => _editingController.hasActiveEditing,
    );
  }

  void _handleEditingChanged() {
    widget.onEditingChanged?.call();
  }

  void _syncDraftSelection() {
    final controller = widget.draftController;
    if (controller == null) {
      _selectionController.clear();
      return;
    }
    final indexes = <int>[];
    for (var index = 0; index < controller.rows.length; index += 1) {
      if (controller.selectedRowKeys.contains(controller.rows[index].rowKey)) {
        indexes.add(index);
      }
    }
    _selectionController.setSelectedRows(indexes);
  }

  @override
  void dispose() {
    widget.draftController?.removeListener(_handleDraftChanged);
    _selectionController.removeListener(_handleSelectionChanged);
    _editingController.removeListener(_handleEditingChanged);
    _selectionController.dispose();
    _focusController.dispose();
    _sourcePaneFocusNode.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  void _handleDraftChanged() {
    if (!mounted) {
      return;
    }
    final controller = widget.draftController;
    _syncDraftSelection();
    if (controller?.addModeOpen != true && _selectedSourceItemIds.isNotEmpty) {
      _selectedSourceItemIds.clear();
      _sourceAnchorIndex = null;
    }
    setState(() {});
  }

  void _handleSelectionChanged() {
    final controller = widget.draftController;
    if (controller == null) {
      return;
    }
    final selectedKeys = _selectedTargetRowKeys(controller).toList(growable: false);
    controller.setSelection(selectedKeys);
  }

  Set<String> _selectedTargetRowKeys(AutoItemUpdateDraftController controller) {
    final selectedKeys = <String>{};
    for (final index in _selectionController.selectedRows) {
      if (index >= 0 && index < controller.rows.length) {
        selectedKeys.add(controller.rows[index].rowKey);
      }
    }
    return selectedKeys;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.draftController;
    final rows = controller?.rows ?? const <AutoItemUpdateDraftRow>[];
    final popupEnabled = controller?.addModeOpen != true;
    return Column(
      children: [
        Expanded(
          child: controller?.addModeOpen == true
              ? _buildAddModeLayout(rows)
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapDown: popupEnabled
                      ? (details) => _showContextMenu(details)
                      : null,
                  child: _buildTargetTable(rows),
                ),
        ),
        _buildCommandFooter(),
      ],
    );
  }

  Widget _buildAddModeLayout(List<AutoItemUpdateDraftRow> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = _sourceMinWidth + _railWidth + _targetMinWidth;
        final contentWidth = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: contentWidth,
            child: Row(
              children: [
                SizedBox(width: _sourceMinWidth, child: _buildSourcePane()),
                SizedBox(width: _railWidth, child: _buildAddModeRail()),
                SizedBox(
                  width: contentWidth - _sourceMinWidth - _railWidth,
                  child: _buildTargetTable(rows),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourcePane() {
    return Focus(
      focusNode: _sourcePaneFocusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        final keys = HardwareKeyboard.instance.logicalKeysPressed;
        final isSelectAll = event.logicalKey == LogicalKeyboardKey.keyA &&
            (keys.contains(LogicalKeyboardKey.controlLeft) ||
                keys.contains(LogicalKeyboardKey.controlRight) ||
                keys.contains(LogicalKeyboardKey.metaLeft) ||
                keys.contains(LogicalKeyboardKey.metaRight));
        if (!isSelectAll) {
          return KeyEventResult.ignored;
        }
        _selectAllSourceRows();
        return KeyEventResult.handled;
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE6E8EB))),
        ),
        child: widget.sourceReady
            ? _buildSourceList()
            : const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '품목관리 원본 목록을 아직 준비하지 못했습니다.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
      ),
    );
  }

  bool get _busy => widget.commandBusy || _sourceAppendBusy;

  Future<void> _appendSelectedSourceItems() async {
    final selected = [
      for (final source in widget.sourceRows)
        if (_selectedSourceItemIds.contains(source.itemId)) source,
    ];
    await _appendSourceItems(selected);
  }

  Future<void> _appendSourceItems(List<AutoItemUpdateSourceSeed> sources) async {
    final controller = widget.draftController;
    if (controller == null || !widget.sourceReady || sources.isEmpty || _busy) {
      return;
    }
    setState(() {
      _sourceAppendBusy = true;
    });
    try {
      controller.stageAppendItems(sources);
      if (widget.onApplyStagedRows case final onApply?) {
        await onApply();
      } else {
        controller.applyStagedRows();
      }
      _selectedSourceItemIds.clear();
      _sourceAnchorIndex = null;
    } catch (error) {
      _showWarning('품목 추가 적용에 실패했습니다.\n$error');
    } finally {
      if (mounted) {
        setState(() {
          _sourceAppendBusy = false;
        });
      }
    }
  }

  Future<void> _handleFooterCancel() async {
    final controller = widget.draftController;
    if (controller == null || _busy || !widget.canEdit) {
      return;
    }
    if (controller.addModeOpen == true && controller.isDirty != true) {
      controller.cancelStagedRows();
      _selectedSourceItemIds.clear();
      _sourceAnchorIndex = null;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    await widget.onCancelDraft?.call();
  }

  void _closeSourcePane() {
    final controller = widget.draftController;
    if (controller == null || _busy) {
      return;
    }
    controller.cancelStagedRows();
    _selectedSourceItemIds.clear();
    _sourceAnchorIndex = null;
    if (mounted) {
      setState(() {});
    }
  }

  Set<int> _blockedSourceItemIds() {
    final controller = widget.draftController;
    if (controller == null) {
      return const <int>{};
    }
    return {
      for (final row in controller.rows) row.sourceItemId,
    };
  }

  bool _canSelectSourceRow(AutoItemUpdateSourceSeed row) {
    return !_blockedSourceItemIds().contains(row.itemId);
  }

  bool _sourceSelectionModifierPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight) ||
        keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _applySingleSourceSelection(int index) {
    if (index < 0 || index >= widget.sourceRows.length) {
      return;
    }
    final source = widget.sourceRows[index];
    if (!_canSelectSourceRow(source)) {
      return;
    }
    _selectedSourceItemIds
      ..clear()
      ..add(source.itemId);
    _sourceAnchorIndex = index;
    if (mounted) {
      setState(() {});
    }
  }

  void _selectAllSourceRows() {
    if (!widget.sourceReady || _busy) {
      return;
    }
    final selectableRows = [
      for (var index = 0; index < widget.sourceRows.length; index += 1)
        if (_canSelectSourceRow(widget.sourceRows[index]))
          (index: index, itemId: widget.sourceRows[index].itemId),
    ];
    if (selectableRows.isEmpty) {
      return;
    }
    _selectedSourceItemIds
      ..clear()
      ..addAll(selectableRows.map((entry) => entry.itemId));
    _sourceAnchorIndex = selectableRows.first.index;
    if (!_sourcePaneFocusNode.hasFocus) {
      _sourcePaneFocusNode.requestFocus();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSourcePointerDown(
    AutoItemUpdateSourceSeed row,
    int index,
    PointerDownEvent event,
  ) {
    if (!_canSelectSourceRow(row) || _busy) {
      return;
    }
    _sourcePointerDownPosition = event.position;
    _sourcePointerMoved = false;
    _deferSourceSingleSelection =
      !_sourceSelectionModifierPressed() &&
      _selectedSourceItemIds.length > 1 &&
      _selectedSourceItemIds.contains(row.itemId);
    _deferredSourceSelectionIndex = _deferSourceSingleSelection ? index : null;
  }

  void _handleSourcePointerMove(
    AutoItemUpdateSourceSeed row,
    int index,
    PointerMoveEvent event,
  ) {
    final pointerDownPosition = _sourcePointerDownPosition;
    if (pointerDownPosition == null || _busy) {
      return;
    }
    final delta = event.position - pointerDownPosition;
    if (!_sourcePointerMoved &&
        (delta.dx.abs() >= _sourcePointerMoveThreshold ||
            delta.dy.abs() >= _sourcePointerMoveThreshold)) {
      _sourcePointerMoved = true;
    }
  }

  void _handleSourcePointerUp(
    AutoItemUpdateSourceSeed row,
    int index,
    PointerUpEvent event,
  ) {
    if (_deferSourceSingleSelection &&
        _deferredSourceSelectionIndex == index &&
        !_sourcePointerMoved) {
      _applySingleSourceSelection(index);
    }
    _sourcePointerDownPosition = null;
    _sourcePointerMoved = false;
    _deferSourceSingleSelection = false;
    _deferredSourceSelectionIndex = null;
  }

  Widget _buildSourceList() {
    final blockedItemIds = _blockedSourceItemIds();
    return KeyedSubtree(
      key: _sourceTableViewportKey,
      child: SwipeActionTable<AutoItemUpdateSourceSeed>(
        key: const Key('auto-item-update-source-table'),
        rows: widget.sourceRows,
        rowNumberWidth: 0,
        headerHeight: _sourceHeaderHeight,
        rowHeight: _sourceRowHeight,
        autoFitColumns: false,
        fillLastColumn: true,
        rowDragStartBehavior: SwipeActionTableRowDragStartBehavior.longPress,
        rowDragStartDelay: _sourceRowDragStartDelay,
        selectedIndex: _selectedSourceIndex(),
        rowColorBuilder: (row, index, selected) {
          if (blockedItemIds.contains(row.itemId)) {
            return index.isEven ? const Color(0xFFF5F5F5) : const Color(0xFFEDEDED);
          }
          if (_selectedSourceItemIds.contains(row.itemId)) {
            return _sourceRowSelectedColor;
          }
          return index.isEven ? Colors.white : const Color(0xFFF2F4F7);
        },
        onRowSelected: (_, index) => _selectSourceRow(index),
        onRowPointerDown: _handleSourcePointerDown,
        onRowPointerMove: _handleSourcePointerMove,
        onRowPointerUp: _handleSourcePointerUp,
        rowDragDataBuilder: (row, index) =>
            widget.sourceReady && !_busy && _canSelectSourceRow(row)
                ? _dragPayloadForSourceRow(row, index)
                : null,
        rowDragFeedbackBuilder: (row, index, defaultFeedback) =>
            _buildSourceDragFeedback(
              _dragPayloadForSourceRow(row, index),
              defaultFeedback,
            ),
        onRowDragStarted: (row, index) {
          if (!_canSelectSourceRow(row)) {
            return;
          }
          _deferSourceSingleSelection = false;
          _deferredSourceSelectionIndex = null;
          if (!_sourcePaneFocusNode.hasFocus) {
            _sourcePaneFocusNode.requestFocus();
          }
          final payload = _dragPayloadForSourceRow(row, index);
          _selectedSourceItemIds
            ..clear()
            ..addAll(payload.itemIds);
          _sourceAnchorIndex = index;
          if (mounted) {
            setState(() {});
          }
        },
        columns: [
          SwipeActionTableColumn<AutoItemUpdateSourceSeed>(
            header: '원본 품목명',
            text: _sourceItemName,
            fillRemaining: true,
            headerTrailing: IconButton(
              key: const Key('auto-item-update-source-close-button'),
              tooltip: '원본 품목 영역 닫기',
              onPressed: _busy ? null : _closeSourcePane,
              icon: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFFB8BEC8),
              ),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ),
        ],
      ),
    );
  }

  _AutoItemUpdateSourceDragPayload _dragPayloadForSourceRow(
    AutoItemUpdateSourceSeed row,
    int index,
  ) {
    final useSelectedGroup = _selectedSourceItemIds.contains(row.itemId);
    final rows = useSelectedGroup
        ? [
            for (final source in widget.sourceRows)
              if (_selectedSourceItemIds.contains(source.itemId)) source,
          ]
        : [row];
    return _AutoItemUpdateSourceDragPayload(
      rows: rows,
      itemIds: rows.map((entry) => entry.itemId).toSet(),
      anchorIndex: index,
    );
  }

  Widget _buildSourceDragFeedback(
    _AutoItemUpdateSourceDragPayload payload,
    Widget defaultFeedback,
  ) {
    if (payload.rows.length <= 1) {
      return defaultFeedback;
    }
    final previewRows = payload.rows.take(3).toList(growable: false);
    final previewHeight = _sourceRowHeight + (previewRows.length - 1) * 8 + 6;
    return SizedBox(
      width: _sourceMinWidth,
      height: previewHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = previewRows.length - 1; index >= 0; index -= 1)
            Positioned(
              top: index * 8,
              left: index * 6,
              right: 0,
              child: Opacity(
                opacity: 1 - index * 0.14,
                child: _buildSourceDragFeedbackCard(
                  label: previewRows[index].itemName,
                  isTop: index == 0,
                  extraCount:
                      index == 0 ? payload.rows.length - previewRows.length : 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceDragFeedbackCard({
    required String label,
    required bool isTop,
    required int extraCount,
  }) {
    return Container(
      height: _sourceRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isTop ? Colors.white : const Color(0xFFF6F8FB),
        border: Border.all(color: const Color(0xFFD1D9E0)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 14, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              extraCount > 0 ? '$label 외 $extraCount건' : label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
    );
  }

  int? _selectedSourceIndex() {
    if (_sourceAnchorIndex != null &&
        _sourceAnchorIndex! >= 0 &&
        _sourceAnchorIndex! < widget.sourceRows.length &&
        _selectedSourceItemIds.contains(
          widget.sourceRows[_sourceAnchorIndex!].itemId,
        )) {
      return _sourceAnchorIndex;
    }
    for (var index = 0; index < widget.sourceRows.length; index += 1) {
      if (_selectedSourceItemIds.contains(widget.sourceRows[index].itemId)) {
        return index;
      }
    }
    return null;
  }

  void _selectSourceRow(int index) {
    if (index < 0 || index >= widget.sourceRows.length) {
      return;
    }
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final source = widget.sourceRows[index];
    if (!_canSelectSourceRow(source)) {
      return;
    }
    if (_deferSourceSingleSelection &&
        _deferredSourceSelectionIndex == index &&
        !_sourcePointerMoved) {
      return;
    }
    if (!_sourcePaneFocusNode.hasFocus) {
      _sourcePaneFocusNode.requestFocus();
    }
    final next = <int>{..._selectedSourceItemIds};
    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      final anchorIndex = _sourceAnchorIndex ?? index;
      final start = anchorIndex < index ? anchorIndex : index;
      final end = anchorIndex > index ? anchorIndex : index;
      next
        ..clear()
        ..addAll([
          for (var rowIndex = start; rowIndex <= end; rowIndex += 1)
            widget.sourceRows[rowIndex].itemId,
        ]);
    } else if (keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight)) {
      if (!next.add(source.itemId)) {
        next.remove(source.itemId);
      }
      _sourceAnchorIndex = index;
    } else {
      next
        ..clear()
        ..add(source.itemId);
      _sourceAnchorIndex = index;
    }
    _selectedSourceItemIds
      ..clear()
      ..addAll(next);
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildAddModeRail() {
    final enabled =
        widget.sourceReady && !_busy && _selectedSourceItemIds.isNotEmpty;
    return Center(
      child: Tooltip(
        message: '선택 품목 추가',
        child: IconButton(
          onPressed: enabled ? _appendSelectedSourceItems : null,
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }

  Widget _buildTargetTable(List<AutoItemUpdateDraftRow> rows) {
    final controller = widget.draftController;
    final table = FortuneTable<AutoItemUpdateDraftRow>(
      rows: rows,
      columns: _columns(),
      autoFitColumns: false,
      multiSelectionEnabled: true,
      selectionController: _selectionController,
      focusController: _focusController,
      editingController: _editingController,
      onCellActivated: (_, _, columnId) {
        if (_activeSearchColumnId != columnId) {
          _searchStartIndex = 0;
        }
        _activeSearchColumnId = columnId;
      },
      onSelectionFocusChanged: (row, _) {
        if (controller == null) {
          return;
        }
        controller.setSelection(
          _selectedTargetRowKeys(controller),
          anchorRowKey: row.rowKey,
        );
      },
      onRowSecondaryTapDown: controller?.addModeOpen == true
          ? null
          : (row, _, details) => _showContextMenu(
              details,
              rowKey: row.rowKey,
            ),
      onRectChanged: widget.onTableRectChanged,
      rowColorBuilder: _rowColor,
    );
    if (controller?.addModeOpen != true) {
      return table;
    }
    return DragTarget<_AutoItemUpdateSourceDragPayload>(
      onWillAcceptWithDetails: (details) => widget.sourceReady && !_busy,
      onMove: (_) {
        if (_targetDropActive || !mounted) {
          return;
        }
        setState(() {
          _targetDropActive = true;
        });
      },
      onLeave: (_) {
        if (!_targetDropActive || !mounted) {
          return;
        }
        setState(() {
          _targetDropActive = false;
        });
      },
      onAcceptWithDetails: (details) {
        _targetDropActive = false;
        _appendSourceItems(details.data.rows);
        if (mounted) {
          setState(() {});
        }
      },
      builder: (context, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: _targetDropActive
                ? const Color(0xFF007ACC)
                : Colors.transparent,
            width: 2,
          ),
          color: _targetDropActive ? _targetDropZoneColor : Colors.transparent,
        ),
        child: table,
      ),
    );
  }

  TableSearchResult _search(String query) {
    final controller = widget.draftController;
    final rows = controller?.rows ?? const <AutoItemUpdateDraftRow>[];
    final columns = _columns();
    final columnIndex = columns.indexWhere(
      (column) => column.id == _activeSearchColumnId,
    );
    if (rows.isEmpty || columnIndex < 0) {
      return TableSearchResult.unavailable;
    }
    final column = columns[columnIndex];
    for (var index = _searchStartIndex; index < rows.length; index += 1) {
      if (!column.text(rows[index]).contains(query)) continue;
      final row = rows[index];
      _searchStartIndex = index + 1;
      _selectionController.setSelectedRows([index]);
      controller?.setSelection({row.rowKey}, anchorRowKey: row.rowKey);
      _focusController.focusCell(index, column.id);
      return TableSearchResult.found;
    }
    return TableSearchResult.reachedEnd;
  }

  Future<void> _showContextMenu(
    TapDownDetails details, {
    String? rowKey,
  }) async {
    if (widget.draftController?.addModeOpen == true) {
      return;
    }
    if (_contextMenuOpen) {
      return;
    }
    _contextMenuOpen = true;
    try {
      final controller = widget.draftController;
      if (controller != null && rowKey != null) {
        final selected = controller.selectedRowKeys;
        if (!selected.contains(rowKey)) {
          controller.setSelection([rowKey], anchorRowKey: rowKey);
        }
      }
      final selectedKeys = controller == null
          ? const <String>{}
          : (_selectedTargetRowKeys(controller).isNotEmpty
              ? _selectedTargetRowKeys(controller)
              : controller.selectedRowKeys);
      final hasContextRow = rowKey != null;
      final canAdd =
          widget.canEdit && !widget.commandBusy && controller?.addModeOpen != true;
      final canDelete =
          widget.canEdit &&
          !widget.commandBusy &&
          controller?.addModeOpen != true &&
          hasContextRow;
      final canDeleteSelected =
          widget.canEdit &&
          !widget.commandBusy &&
          controller?.addModeOpen != true &&
          hasContextRow &&
          selectedKeys.isNotEmpty;
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
          PopupMenuItem<String>(
            value: _menuAdd,
            enabled: canAdd,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: const Text('자동갱신 품목추가'),
          ),
          PopupMenuItem<String>(
            value: _menuDelete,
            enabled: canDelete,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: const Text('품목삭제'),
          ),
          PopupMenuItem<String>(
            value: _menuDeleteSelected,
            enabled: canDeleteSelected,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: const Text('블럭선택 품목삭제'),
          ),
          const PopupMenuDivider(height: fortuneContextMenuDividerHeight),
          PopupMenuItem<String>(
            value: _menuRefresh,
            enabled: !widget.commandBusy,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: const Text('새로 고침'),
          ),
        ],
      );
      if (!mounted || command == null) {
        return;
      }
      if (command == _menuAdd) {
        if (!await _flushContextMenuEditing('자동갱신 품목추가')) {
          return;
        }
        controller?.startAddMode();
      } else if (command == _menuDelete) {
        if (!await _flushContextMenuEditing('품목삭제')) {
          return;
        }
        if (rowKey != null) {
          await widget.onDeleteRows?.call({rowKey});
        }
      } else if (command == _menuDeleteSelected) {
        if (!await _flushContextMenuEditing('블럭선택 품목삭제')) {
          return;
        }
        await widget.onDeleteRows?.call(selectedKeys);
      } else if (command == _menuRefresh) {
        await widget.onRefresh?.call();
      }
    } finally {
      _contextMenuOpen = false;
    }
  }

  Future<bool> _flushContextMenuEditing(String actionLabel) async {
    try {
      await _editingController.commitEditing();
    } catch (_) {
      _showWarning('$actionLabel 전에 현재 편집을 완료해 주세요.');
      return false;
    }
    if (_editingController.hasActiveEditing) {
      _showWarning('$actionLabel 전에 현재 편집을 완료해 주세요.');
      return false;
    }
    return true;
  }

  List<FortuneTableColumn<AutoItemUpdateDraftRow>> _columns() {
    return [
      const FortuneTableColumn<AutoItemUpdateDraftRow>(
        id: 'rowNumber',
        header: '번호',
        text: _rowNumberText,
        initialWidth: 60,
        minWidth: 60,
      ),
      const FortuneTableColumn<AutoItemUpdateDraftRow>(
        id: 'itemName',
        header: '품목명',
        text: _itemNameText,
        initialWidth: 180,
        minWidth: 140,
      ),
      FortuneTableColumn<AutoItemUpdateDraftRow>(
        id: 'applyDate',
        header: '갱신날짜',
        text: (row) => formatAutoItemUpdateDate(row.applyDate),
        initialWidth: 120,
        minWidth: 110,
        isTextEditable: (_, _) => widget.canEdit && !widget.commandBusy,
        onTextCommitted: _commitApplyDate,
      ),
      for (final column in widget.columns)
        FortuneTableColumn<AutoItemUpdateDraftRow>(
          id: 'dyn_${column.columnId}',
          header: column.columnName,
          text: (row) =>
              widget.draftController?.columnValue(row, column.columnId) ?? '',
          initialWidth: 130,
          minWidth: 100,
          isTextEditable: (_, _) => widget.canEdit && !widget.commandBusy,
          onTextCommitted: (row, _, value) => _commitCellValue(
            row,
            column.columnId,
            value,
          ),
        ),
    ];
  }

  Future<void> _commitApplyDate(
    AutoItemUpdateDraftRow row,
    int rowIndex,
    String value,
  ) async {
    final applied = widget.draftController?.updateApplyDate(row.rowKey, value) ?? false;
    if (!applied) {
      _showWarning('갱신날짜는 오늘 날짜 이후의 yyyyMMdd 형식만 입력할 수 있습니다.');
    }
  }

  Future<void> _commitCellValue(
    AutoItemUpdateDraftRow row,
    int columnId,
    String value,
  ) async {
    widget.draftController?.updateCellValue(
      row.rowKey,
      columnId: columnId,
      editable: true,
      dataString: value,
    );
  }

  void _showWarning(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCommandFooter() {
    final controller = widget.draftController;
    final cancelEnabled = widget.canEdit &&
        !_busy &&
        ((controller?.isDirty == true) || controller?.addModeOpen == true);
    final saveEnabled = widget.canEdit && !_busy && controller?.isDirty == true;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EB))),
      ),
      child: Row(
        children: [
          if (_busy) ...[
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
            onPressed: cancelEnabled ? _handleFooterCancel : null,
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: saveEnabled && widget.onSaveDraft != null
                ? widget.onSaveDraft
                : null,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Color? _rowColor(AutoItemUpdateDraftRow row, int rowIndex, bool selected) {
    if (selected) {
      return null;
    }
    return switch (row.rowState) {
      AutoItemUpdateRowState.added => _addedRowColor,
      AutoItemUpdateRowState.modified => _modifiedRowColor,
      AutoItemUpdateRowState.staged => _stagedRowColor,
      AutoItemUpdateRowState.existing => null,
    };
  }
}

class _AutoItemUpdateSourceDragPayload {
  const _AutoItemUpdateSourceDragPayload({
    required this.rows,
    required this.itemIds,
    required this.anchorIndex,
  });

  final List<AutoItemUpdateSourceSeed> rows;
  final Set<int> itemIds;
  final int anchorIndex;
}


String _rowNumberText(AutoItemUpdateDraftRow row) =>
    '${row.originalIndex + 1}';

String _itemNameText(AutoItemUpdateDraftRow row) => row.itemName;
