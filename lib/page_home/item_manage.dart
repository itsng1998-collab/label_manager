import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/utils/log_context.dart';

class ItemManage extends StatefulWidget {
  final List<ItemOfMarket> items;
  final int? selectedIndex;
  final void Function(ItemOfMarket row, int index)? onRowSelected;
  final ValueChanged<Rect>? onTableRectChanged;

  const ItemManage({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onRowSelected,
    this.onTableRectChanged,
  });

  @override
  State<ItemManage> createState() => _ItemManageState();
}

class _ItemManageState extends State<ItemManage> {
  static const String _publishColumnId = 'publish';
  static const String _menuSelectAll = 'selectAll';
  static const String _menuClearSelection = 'clearSelection';
  static const String _menuCheckSelectedPublish = 'checkSelectedPublish';
  static const String _menuUncheckSelectedPublish = 'uncheckSelectedPublish';
  static const EdgeInsets _menuItemPadding = EdgeInsets.symmetric(horizontal: 12);
  static const Color _publishCheckedRowColor = Color(0xFFEAF4FF);

  final FortuneTableCheckboxController _publishCheckboxController =
      FortuneTableCheckboxController();
  final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();

  @override
  void didUpdateWidget(covariant ItemManage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publishCheckboxController.setCheckedRows(
      _publishColumnId,
      _publishCheckboxController
          .checkedRows(_publishColumnId)
          .where((index) => index < widget.items.length),
    );
    _selectionController.setSelectedRows(
      _selectionController.selectedRows.where(
        (index) => index < widget.items.length,
      ),
    );
  }

  @override
  void dispose() {
    _publishCheckboxController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    debugLog(
      'rows=${widget.items.length}, '
      'dynamicColumns=${TColumn.datas?.length ?? 0}, columns=${columns.length}',
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: _showTableContextMenu,
      child: FortuneTable<ItemOfMarket>(
        rows: widget.items,
        columns: columns,
        autoFitColumns: false,
        selectedIndex: widget.selectedIndex,
        selectionController: _selectionController,
        multiSelectionEnabled: true,
        onRowSelected: widget.onRowSelected,
        onRectChanged: widget.onTableRectChanged,
        rowColorBuilder: _rowColor,
      ),
    );
  }

  Color? _rowColor(ItemOfMarket row, int rowIndex, bool selected) {
    if (selected) return null;
    return _publishCheckboxController.isChecked(_publishColumnId, rowIndex)
        ? _publishCheckedRowColor
        : null;
  }

  Future<void> _showTableContextMenu(TapDownDetails details) async {
    final local = details.localPosition;
    if (local.dx < 40 || local.dy < 36) return;
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
        _disabledCountMenuItem('품목 추가'),
        _disabledCountMenuItem('품목 삽입'),
        const PopupMenuItem<String>(
          enabled: false,
          height: fortuneContextMenuRowHeight,
          padding: _menuItemPadding,
          child: Text('품목 삭제'),
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
    _handleContextMenuCommand(command);
  }

  PopupMenuItem<String> _disabledCountMenuItem(String label) {
    return PopupMenuItem<String>(
      enabled: false,
      height: fortuneContextMenuRowHeight,
      padding: _menuItemPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 38),
          Container(
            width: 36,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBDBDBD)),
            ),
            child: const Text('1'),
          ),
          const SizedBox(width: 4),
          const Text('개'),
        ],
      ),
    );
  }

  void _handleContextMenuCommand(String command) {
    switch (command) {
      case _menuSelectAll:
        _selectionController.selectAll(widget.items.length);
      case _menuClearSelection:
        _selectionController.clear();
      case _menuCheckSelectedPublish:
        _setSelectedPublishChecked(true);
      case _menuUncheckSelectedPublish:
        _setSelectedPublishChecked(false);
    }
  }

  void _setSelectedPublishChecked(bool checked) {
    final selectedRows = _selectionController.selectedRows;
    if (selectedRows.isEmpty) return;
    final checkedRows = _publishCheckboxController.checkedRows(_publishColumnId);
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
            text: (row) =>
                TColumnContent.get(c.columnId, row.item.itemId)?.dataString ??
                '',
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
      const FortuneTableColumn<ItemOfMarket>(
        id: 'itemName',
        header: '품명',
        initialWidth: 280,
        minWidth: 70,
        text: _itemName,
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
