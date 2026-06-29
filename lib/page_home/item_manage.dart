import 'dart:math';
import 'package:flutter/material.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/widgets/resizable_table.dart';

class ItemManage extends StatelessWidget {
  final List<ItemOfMarket> items;
  const ItemManage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    debugLog(
      'rows=${items.length}, '
      'dynamicColumns=${TColumn.datas?.length ?? 0}, columns=${columns.length}',
    );
    return ResizableTable<ItemOfMarket>(
      rows: items,
      columns: columns,
      checkboxColumnIndex: 0,
    );
  }

  List<ResizableTableColumn<ItemOfMarket>> get _columns {
    final extras = List<TColumn>.from(TColumn.datas ?? const <TColumn>[]);
    final extraColumns = extras
        .map(
          (c) => ResizableTableColumn<ItemOfMarket>(
            id: 'dyn_${c.columnId}',
            title: c.columnName,
            width: max(c.width.toDouble(), 70),
            minWidth: 70,
            textAccessor: (row) =>
                TColumnContent.get(c.columnId, row.item.itemId)?.dataString ??
                '',
          ),
        )
        .toList();

    return [
      const ResizableTableColumn<ItemOfMarket>(
        id: 'publish',
        title: '발행',
        width: 40,
        minWidth: 40,
        textAccessor: _empty,
      ),
      const ResizableTableColumn<ItemOfMarket>(
        id: 'labelSize',
        title: '라벨크기',
        width: 100,
        minWidth: 60,
        textAccessor: _labelSize,
      ),
      const ResizableTableColumn<ItemOfMarket>(
        id: 'itemName',
        title: '품명',
        width: 280,
        minWidth: 70,
        textAccessor: _itemName,
      ),
      const ResizableTableColumn<ItemOfMarket>(
        id: 'element',
        title: '주원료',
        width: 180,
        minWidth: 70,
        textAccessor: _element,
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
