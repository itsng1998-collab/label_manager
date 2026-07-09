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
  final Set<int> _checkedRowIndexes = <int>{};

  @override
  void didUpdateWidget(covariant ItemManage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkedRowIndexes.removeWhere((index) => index >= widget.items.length);
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    debugLog(
      'rows=${widget.items.length}, '
      'dynamicColumns=${TColumn.datas?.length ?? 0}, columns=${columns.length}',
    );
    return FortuneTable<ItemOfMarket>(
      rows: widget.items,
      columns: columns,
      autoFitColumns: false,
      selectedIndex: widget.selectedIndex,
      onRowSelected: widget.onRowSelected,
      onRectChanged: widget.onTableRectChanged,
    );
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
        id: 'publish',
        header: '발행',
        initialWidth: 40,
        minWidth: 40,
        text: _empty,
        checkboxValueAt: (row, rowIndex) => _checkedRowIndexes.contains(rowIndex),
        onCheckboxChangedAt: (row, rowIndex, value) {
          setState(() {
            if (value) {
              _checkedRowIndexes.add(rowIndex);
            } else {
              _checkedRowIndexes.remove(rowIndex);
            }
          });
        },
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
