import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;

import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

class AutoItemUpdatePageController {
  Object? _owner;
  Future<void> Function()? _commitEditing;
  bool Function()? _hasActiveEditing;

  bool get hasActiveEditing => _hasActiveEditing?.call() ?? false;

  Future<void> commitEditing() async {
    await _commitEditing?.call();
  }

  void _attach({
    required Object owner,
    required Future<void> Function() commitEditing,
    required bool Function() hasActiveEditing,
  }) {
    _owner = owner;
    _commitEditing = commitEditing;
    _hasActiveEditing = hasActiveEditing;
  }

  void _detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
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
    this.onTableRectChanged,
    this.sourceRows = const <AutoItemUpdateSourceSeed>[],
    this.sourceReady = false,
    this.commandBusy = false,
    this.canEdit = true,
    this.onBeforeApplyDateChange,
    this.onBeforeCellChange,
    this.onDeleteRows,
    this.onApplyStagedRows,
    this.onRefresh,
    this.onCancelDraft,
    this.onSaveDraft,
  });

  final List<TColumn> columns;
  final AutoItemUpdateDraftController? draftController;
  final AutoItemUpdatePageController? controller;
  final ValueChanged<Rect>? onTableRectChanged;
  final List<AutoItemUpdateSourceSeed> sourceRows;
  final bool sourceReady;
  final bool commandBusy;
  final bool canEdit;
  final Future<void> Function(AutoItemUpdateDraftRow row)? onBeforeApplyDateChange;
  final Future<void> Function(AutoItemUpdateDraftRow row, int columnId)? onBeforeCellChange;
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
  static const String _menuInputDate = 'inputDate';
  static const String _menuFindItem = 'findItem';
  static const String _menuRefresh = 'refresh';
  static const Color _addedRowColor = Color(0xFFEAF7EE);
  static const Color _modifiedRowColor = Color(0xFFFFF6DF);
  static const Color _stagedRowColor = Color(0xFFEAF4FF);
  static const double _sourceMinWidth = 240;
  static const double _railWidth = 48;
  static const double _targetMinWidth = 480;
  static const double _sourceHeaderHeight = 36;
  static const double _sourceRowHeight = 28;
  static const Color _sourceRowSelectedColor = Color(0xFFDCEBFF);
  static const Color _targetDropZoneColor = Color(0x22007ACC);

  static String _sourceItemName(AutoItemUpdateSourceSeed row) => row.itemName;

  final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();
  final FortuneTableFocusController _focusController =
      FortuneTableFocusController();
  final FortuneTableEditingController _editingController =
      FortuneTableEditingController();
  bool _contextMenuOpen = false;
  bool _targetDropActive = false;
  final Set<int> _selectedSourceItemIds = <int>{};
  int? _sourceAnchorIndex;

  @override
  void initState() {
    super.initState();
    widget.draftController?.addListener(_handleDraftChanged);
    _selectionController.addListener(_handleSelectionChanged);
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
      commitEditing: _editingController.commitEditing,
      hasActiveEditing: () => _editingController.hasActiveEditing,
    );
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
    _selectionController.dispose();
    _focusController.dispose();
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
                SizedBox(
                  width: _sourceMinWidth,
                  child: _buildSourcePane(),
                ),
                SizedBox(
                  width: _railWidth,
                  child: _buildAddModeRail(),
                ),
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
    final controller = widget.draftController;
    final canApply =
        widget.sourceReady && !widget.commandBusy && controller?.hasStagedRows == true;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE6E8EB))),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            child: Center(
              child: Text(
                '원본 품목',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
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
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE6E8EB))),
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: widget.commandBusy ? null : _cancelAddMode,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: canApply ? _applyAddMode : null,
                  child: const Text('적용'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList() {
    return SwipeActionTable<AutoItemUpdateSourceSeed>(
      key: const Key('auto-item-update-source-table'),
      rows: widget.sourceRows,
      rowNumberWidth: 0,
      headerHeight: _sourceHeaderHeight,
      rowHeight: _sourceRowHeight,
      autoFitColumns: false,
      fillLastColumn: true,
      selectedIndex: _selectedSourceIndex(),
      rowColorBuilder: (row, index, selected) {
        if (_selectedSourceItemIds.contains(row.itemId)) {
          return _sourceRowSelectedColor;
        }
        return index.isEven ? Colors.white : const Color(0xFFF2F4F7);
      },
      onRowSelected: (_, index) => _selectSourceRow(index),
      rowDragDataBuilder: (row, index) =>
          widget.sourceReady && !widget.commandBusy
          ? _dragPayloadForSourceRow(row, index)
          : null,
      onRowDragStarted: (row, index) {
        final payload = _dragPayloadForSourceRow(row, index);
        _selectedSourceItemIds
          ..clear()
          ..addAll(payload.itemIds);
        _sourceAnchorIndex = index;
        if (mounted) {
          setState(() {});
        }
      },
      columns: const [
        SwipeActionTableColumn<AutoItemUpdateSourceSeed>(
          header: '품목명',
          text: _sourceItemName,
          fillRemaining: true,
        ),
      ],
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

  int? _selectedSourceIndex() {
    if (_sourceAnchorIndex != null &&
        _sourceAnchorIndex! >= 0 &&
        _sourceAnchorIndex! < widget.sourceRows.length &&
        _selectedSourceItemIds.contains(widget.sourceRows[_sourceAnchorIndex!].itemId)) {
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
      if (next.isEmpty || (next.length == 1 && next.contains(source.itemId))) {
        next
          ..clear()
          ..add(source.itemId);
      } else if (next.contains(source.itemId)) {
        next
          ..clear()
          ..add(source.itemId);
      } else {
        next.add(source.itemId);
      }
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
        widget.sourceReady && !widget.commandBusy && _selectedSourceItemIds.isNotEmpty;
    return Center(
      child: Tooltip(
        message: '선택 품목 추가',
        child: IconButton(
          onPressed: enabled ? _stageSelectedSourceItems : null,
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
      onRowSelected: (row, _) {
        controller?.setSelection([row.rowKey], anchorRowKey: row.rowKey);
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
      onWillAcceptWithDetails: (details) => widget.sourceReady && !widget.commandBusy,
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
        _stageSourceItems(details.data.rows);
        if (mounted) {
          setState(() {});
        }
      },
      builder: (context, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: _targetDropActive ? const Color(0xFF007ACC) : Colors.transparent,
            width: 2,
          ),
          color: _targetDropActive ? _targetDropZoneColor : Colors.transparent,
        ),
        child: table,
      ),
    );
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
            child: const Text('자동갱신 품목추가'),
          ),
          PopupMenuItem<String>(
            value: _menuDelete,
            enabled: canDelete,
            child: const Text('품목삭제'),
          ),
          PopupMenuItem<String>(
            value: _menuDeleteSelected,
            enabled: canDeleteSelected,
            child: const Text('블럭선택 품목삭제'),
          ),
          PopupMenuItem<String>(
            value: _menuInputDate,
            enabled: controller?.addModeOpen != true && hasContextRow,
            child: const Text('블럭선택 날짜입력'),
          ),
          PopupMenuItem<String>(
            value: _menuFindItem,
            enabled: controller?.addModeOpen != true && hasContextRow,
            child: const Text('품목찾기'),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: _menuRefresh,
            enabled: !widget.commandBusy,
            child: const Text('새로 고침'),
          ),
        ],
      );
      if (!mounted || command == null) {
        return;
      }
      if (command == _menuAdd) {
        controller?.startAddMode();
      } else if (command == _menuDelete) {
        if (rowKey != null) {
          await widget.onDeleteRows?.call({rowKey});
        }
      } else if (command == _menuDeleteSelected) {
        await widget.onDeleteRows?.call(selectedKeys);
      } else if (command == _menuRefresh) {
        await widget.onRefresh?.call();
      }
    } finally {
      _contextMenuOpen = false;
    }
  }

  void _stageSelectedSourceItems() {
    final controller = widget.draftController;
    if (controller == null || !widget.sourceReady) {
      return;
    }
    final selected = [
      for (final source in widget.sourceRows)
        if (_selectedSourceItemIds.contains(source.itemId)) source,
    ];
    _stageSourceItems(selected);
  }

  void _stageSourceItems(List<AutoItemUpdateSourceSeed> sources) {
    final controller = widget.draftController;
    if (controller == null || !widget.sourceReady || sources.isEmpty) {
      return;
    }
    controller.stageAppendItems(sources);
  }

  Future<void> _cancelAddMode() async {
    final controller = widget.draftController;
    if (controller == null || widget.commandBusy) {
      return;
    }
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: const Text('자동갱신 품목 추가를 취소할까요?'),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('계속 편집')),
          FilledButton(onPressed: () => close(true), child: const Text('취소')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    controller.cancelStagedRows();
    _selectedSourceItemIds.clear();
    _sourceAnchorIndex = null;
  }

  Future<void> _applyAddMode() async {
    final controller = widget.draftController;
    if (controller == null || controller.hasStagedRows != true || widget.commandBusy) {
      return;
    }
    final confirmed = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        content: const Text('선택 품목을 자동품목갱신에 적용할까요?'),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          FilledButton(onPressed: () => close(true), child: const Text('적용')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.onApplyStagedRows?.call();
      _selectedSourceItemIds.clear();
      _sourceAnchorIndex = null;
    } catch (error) {
      _showWarning('품목 추가 적용에 실패했습니다.\n$error');
    }
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
    try {
      await widget.onBeforeApplyDateChange?.call(row);
    } catch (error) {
      _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
      return;
    }
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
    try {
      await widget.onBeforeCellChange?.call(row, columnId);
    } catch (error) {
      _showWarning('변경 취소용 백업을 저장하지 못했습니다.\n$error');
      return;
    }
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
    final dirtyEnabled =
        widget.canEdit &&
        !widget.commandBusy &&
        controller?.isDirty == true &&
        controller?.addModeOpen != true;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EB))),
      ),
      child: Row(
        children: [
          if (widget.commandBusy) ...[
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
