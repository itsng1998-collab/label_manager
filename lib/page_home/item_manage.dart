import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/utils/log_context.dart';

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
  final bool commandBusy;

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
    this.commandBusy = false,
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

  final FortuneTableCheckboxController _publishCheckboxController =
      FortuneTableCheckboxController();
  final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();
  final TextEditingController _addCountController = TextEditingController(
    text: '1',
  );
  final TextEditingController _insertCountController = TextEditingController(
    text: '1',
  );
  List<ItemManagerDraftRow> _displayDraftRows = const [];
  Map<ItemOfMarket, ItemManagerDraftRow> _draftByDisplayItem = Map.identity();
  ItemManagerDraftRow? _contextMenuDraftRow;

  @override
  void initState() {
    super.initState();
    widget.draftController?.addListener(_handleDraftChanged);
  }

  @override
  void didUpdateWidget(covariant ItemManage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftController != widget.draftController) {
      oldWidget.draftController?.removeListener(_handleDraftChanged);
      widget.draftController?.addListener(_handleDraftChanged);
    }
    final rowCount = widget.draftController?.rows.length ?? widget.items.length;
    _publishCheckboxController.setCheckedRows(
      _publishColumnId,
      _publishCheckboxController
          .checkedRows(_publishColumnId)
          .where((index) => index < rowCount),
    );
    _selectionController.setSelectedRows(
      _selectionController.selectedRows.where((index) => index < rowCount),
    );
  }

  void _handleDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.draftController?.removeListener(_handleDraftChanged);
    _addCountController.dispose();
    _insertCountController.dispose();
    _publishCheckboxController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              autoFitColumns: false,
              selectedIndex: widget.selectedIndex,
              selectionController: _selectionController,
              multiSelectionEnabled: true,
              onRowSelected: _handleRowSelected,
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

  Widget _buildCommandFooter() {
    final dirty = widget.draftController?.isDirty == true;
    final cleanEnabled = !widget.commandBusy && !dirty;
    final dirtyEnabled = !widget.commandBusy && dirty;
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
            onPressed: cleanEnabled && widget.onExcelImport != null
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
      widget.draftController?.setSelection([
        draft.rowKey,
      ], anchorRowKey: draft.rowKey);
    }
    widget.onRowSelected?.call(row, index);
  }

  Color? _rowColor(ItemOfMarket row, int rowIndex, bool selected) {
    if (selected) return null;
    return _publishCheckboxController.isChecked(_publishColumnId, rowIndex)
        ? _publishCheckedRowColor
        : null;
  }

  Future<void> _showTableContextMenu(
    ItemOfMarket row,
    int rowIndex,
    TapDownDetails details,
  ) async {
    _contextMenuDraftRow = _draftByDisplayItem[row];
    await _showContextMenu(details);
  }

  Future<void> _showEmptyTableContextMenu(TapDownDetails details) async {
    _contextMenuDraftRow = null;
    await _showContextMenu(details);
  }

  Future<void> _showContextMenu(TapDownDetails details) async {
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
          label: '품목 추가',
          command: _menuAdd,
          controller: _addCountController,
          enabled: widget.draftController != null,
        ),
        _countMenuItem(
          label: '품목 삽입',
          command: _menuInsert,
          controller: _insertCountController,
          enabled:
              widget.draftController != null &&
              _selectionController.hasSelection,
        ),
        PopupMenuItem<String>(
          value: _menuDelete,
          enabled:
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
                  style: const TextStyle(fontSize: 11, color: Color(0xFF777777)),
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
        const PopupMenuItem<String>(
          value: _menuSelectAll,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('전체 선택'),
        ),
        const PopupMenuItem<String>(
          value: _menuClearSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('전체 선택 해제'),
        ),
        const PopupMenuDivider(height: fortuneContextMenuDividerHeight),
        PopupMenuItem<String>(
          value: _menuCheckSelectedPublish,
          enabled: _selectionController.hasSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: const Text('블럭 선택 발행 체크'),
        ),
        PopupMenuItem<String>(
          value: _menuUncheckSelectedPublish,
          enabled: _selectionController.hasSelection,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: const Text('블럭 선택 발행 체크 해제'),
        ),
      ],
    );
    if (!mounted || command == null) return;
    await _handleContextMenuCommand(command);
  }

  PopupMenuItem<String> _countMenuItem({
    required String label,
    required String command,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return PopupMenuItem<String>(
      enabled: false,
      height: fortuneContextMenuRowHeight,
      padding: _menuItemPadding,
      child: Builder(
        builder: (menuContext) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: enabled
                  ? () => Navigator.of(menuContext).pop(command)
                  : null,
              child: SizedBox(width: 102, child: Text(label)),
            ),
            SizedBox(
              width: 44,
              height: 26,
              child: TextField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: enabled
                    ? (_) => Navigator.of(menuContext).pop(command)
                    : null,
              ),
            ),
            const SizedBox(width: 4),
            const Text('개'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContextMenuCommand(String command) async {
    switch (command) {
      case _menuAdd:
        _addDraftRows(_addCountController.text);
      case _menuInsert:
        _insertDraftRows(_insertCountController.text);
      case _menuDelete:
        await _deleteSelectedDraftRows();
      case _menuItemOrder:
        await widget.onItemOrderChange?.call();
      case _menuQrDataView:
        final row = _contextMenuDraftRow;
        if (row != null) await widget.onQrDataView?.call(row);
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

  void _addDraftRows(String rawCount) {
    final count = _parseCount(rawCount);
    if (count == null) return;
    try {
      final added = widget.draftController!.addRows(
        count,
        emptyElementPayload: widget.emptyElementPayload,
      );
      _selectDraftRows(added);
    } on StateError catch (error) {
      _showWarning(error.message);
    }
  }

  void _insertDraftRows(String rawCount) {
    final count = _parseCount(rawCount);
    if (count == null) return;
    final controller = widget.draftController!;
    final selectedIndexes = _selectionController.selectedRows.toList()..sort();
    final anchorKey =
        controller.anchorRowKey ??
        (selectedIndexes.isEmpty
            ? null
            : controller.rows[selectedIndexes.last].rowKey);
    if (anchorKey == null) {
      _showWarning('삽입할 기준 품목을 선택해 주세요.');
      return;
    }
    try {
      final added = controller.insertRowsAfter(
        anchorKey,
        count,
        emptyElementPayload: widget.emptyElementPayload,
      );
      _selectDraftRows(added);
    } on StateError catch (error) {
      _showWarning(error.message);
    }
  }

  Future<void> _deleteSelectedDraftRows() async {
    final controller = widget.draftController!;
    final selectedIndexes =
        _selectionController.selectedRows
            .where((index) => index >= 0 && index < controller.rows.length)
            .toList()
          ..sort();
    if (selectedIndexes.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('품목 삭제'),
        content: Text('선택한 ${selectedIndexes.length}개 품목을 삭제할까요?'),
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
    if (confirmed != true || !mounted) return;
    final rowKeys = selectedIndexes
        .map((index) => controller.rows[index].rowKey)
        .toList(growable: false);
    final nextKey = controller.deleteRows(rowKeys);
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

  void _setSelectedPublishChecked(bool checked) {
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

  List<FortuneTableColumn<ItemOfMarket>> get _columns {
    final extras = List<TColumn>.from(TColumn.datas ?? const <TColumn>[]);
    final extraColumns = extras
        .map(
          (c) => FortuneTableColumn<ItemOfMarket>(
            id: 'dyn_${c.columnId}',
            header: c.columnName,
            initialWidth: max(c.width.toDouble(), 70),
            minWidth: 70,
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
              if (draft == null) return false;
              if (draft.isNew) return true;
              return widget.draftController!.scopedColumnContents
                      .get(c.columnId, draft.sourceItemId!)
                      ?.editable ??
                  false;
            },
            onTextCommitted: (row, _, value) {
              final draft = _draftByDisplayItem[row];
              if (draft == null) return;
              final editable =
                  draft.isNew ||
                  (widget.draftController!.scopedColumnContents
                          .get(c.columnId, draft.sourceItemId!)
                          ?.editable ??
                      false);
              if (!editable) return;
              widget.draftController!.updateColumnValue(
                draft.rowKey,
                columnId: c.columnId,
                editable: editable,
                dataString: value,
              );
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
        checkboxController: _publishCheckboxController,
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
        isTextEditable: (row, _) => _draftByDisplayItem.containsKey(row),
        onTextCommitted: (row, _, value) {
          final draft = _draftByDisplayItem[row];
          if (draft == null) return;
          widget.draftController!.updateItemName(draft.rowKey, value);
        },
      ),
      const FortuneTableColumn<ItemOfMarket>(
        id: 'element',
        header: '주원료',
        initialWidth: 180,
        minWidth: 70,
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
