import 'package:flutter/material.dart';
import 'package:label_manager/models/item_of_market.dart';

class ItemOrderDialog extends StatefulWidget {
  const ItemOrderDialog({super.key, required this.items});

  final List<ItemOfMarket> items;

  @override
  State<ItemOrderDialog> createState() => _ItemOrderDialogState();
}

class _ItemOrderDialogState extends State<ItemOrderDialog> {
  late List<ItemOfMarket> _items;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  bool get _changed {
    for (var index = 0; index < _items.length; index++) {
      if (_items[index].item.itemId != widget.items[index].item.itemId) {
        return true;
      }
    }
    return false;
  }

  void _move(int offset) {
    final target = _selectedIndex + offset;
    if (target < 0 || target >= _items.length) return;
    setState(() {
      final item = _items.removeAt(_selectedIndex);
      _items.insert(target, item);
      _selectedIndex = target;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('품목 순서 변경'),
    content: SizedBox(
      width: 560,
      height: 420,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final selected = index == _selectedIndex;
                return ListTile(
                  key: ValueKey('item-order-${_items[index].item.itemId}'),
                  selected: selected,
                  leading: SizedBox(
                    width: 32,
                    child: Text('${index + 1}', textAlign: TextAlign.right),
                  ),
                  title: Text(
                    _items[index].item.itemName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const VerticalDivider(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                key: const ValueKey('item-order-up'),
                tooltip: '선택 품목 위로 이동',
                onPressed: _selectedIndex > 0 ? () => _move(-1) : null,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              const SizedBox(height: 12),
              IconButton.outlined(
                key: const ValueKey('item-order-down'),
                tooltip: '선택 품목 아래로 이동',
                onPressed: _selectedIndex < _items.length - 1
                    ? () => _move(1)
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('닫기'),
      ),
      FilledButton(
        onPressed: _changed ? () => Navigator.of(context).pop(_items) : null,
        child: const Text('적용'),
      ),
    ],
  );
}