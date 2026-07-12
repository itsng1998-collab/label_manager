import 'package:flutter/material.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

class ItemOrderDialog extends StatefulWidget {
  const ItemOrderDialog({super.key, required this.items, this.selectedItemId});

  final List<ItemOfMarket> items;
  final int? selectedItemId;

  @override
  State<ItemOrderDialog> createState() => _ItemOrderDialogState();
}

class _ItemOrderDialogState extends State<ItemOrderDialog> {
  final TextEditingController _unusedEditController = TextEditingController();
  final FocusNode _unusedEditFocusNode = FocusNode();
  late List<ItemOfMarket> _items;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
    final selectedIndex = _items.indexWhere(
      (value) => value.item.itemId == widget.selectedItemId,
    );
    if (selectedIndex >= 0) _selectedIndex = selectedIndex;
  }

  @override
  void dispose() {
    _unusedEditController.dispose();
    _unusedEditFocusNode.dispose();
    super.dispose();
  }

  bool get _changed {
    for (var index = 0; index < _items.length; index++) {
      if (_items[index].item.itemId != widget.items[index].item.itemId) {
        return true;
      }
    }
    return false;
  }

  void _moveRow(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= _items.length ||
        toIndex < 0 ||
        toIndex >= _items.length) {
      return;
    }
    setState(() {
      final movingItem = _items[fromIndex];
      if ((fromIndex - toIndex).abs() == 1) {
        _items[fromIndex] = _items[toIndex];
        _items[toIndex] = movingItem;
        _selectedIndex = toIndex;
        return;
      }
      final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
      if (insertIndex == fromIndex) return;
      _items.removeAt(fromIndex);
      _items.insert(insertIndex, movingItem);
      _selectedIndex = insertIndex;
    });
  }

  void _moveSelected(int offset) {
    _moveRow(_selectedIndex, _selectedIndex + offset);
  }

  String _originalRowNumber(ItemOfMarket item, int _) {
    final originalIndex = widget.items.indexWhere(
      (original) => original.item.itemId == item.item.itemId,
    );
    return '${originalIndex + 1}';
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
            child: EditableSwipeNameTable<ItemOfMarket>(
              rows: _items,
              header: '품목 이름',
              text: (item) => item.item.itemName,
              editController: _unusedEditController,
              editFocusNode: _unusedEditFocusNode,
              editingIndex: null,
              insertActionIndex: null,
              inserting: false,
              canSubmit: false,
              onToggleEdit: (_, _) {},
              onToggleInsert: (_, _) {},
              onCancelEdit: () {},
              onSubmitEdit: (_) {},
              enabled: false,
              fillLastColumn: true,
              autoFitColumns: false,
              rowSwipeEnabled: false,
              keepRowContentOnSwipe: true,
              rowTooltip: '행 드래그로 품목 순서를 변경합니다',
              rowNumberText: _originalRowNumber,
              rowReorderEnabled: true,
              selectedIndex: _selectedIndex,
              onRowSelected: (_, index) =>
                  setState(() => _selectedIndex = index),
              onRowReorder: _moveRow,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ItemOrderMoveButton(
                  key: const ValueKey('item-order-up'),
                  icon: Icons.keyboard_arrow_up,
                  tooltip: '선택 행 위로 이동',
                  enabled: _selectedIndex > 0,
                  onPressed: () => _moveSelected(-1),
                ),
                const SizedBox(height: 8),
                _ItemOrderMoveButton(
                  key: const ValueKey('item-order-down'),
                  icon: Icons.keyboard_arrow_down,
                  tooltip: '선택 행 아래로 이동',
                  enabled: _selectedIndex < _items.length - 1,
                  onPressed: () => _moveSelected(1),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: _changed ? () => Navigator.of(context).pop(_items) : null,
        child: const Text('적용'),
      ),
    ],
  );
}

class _ItemOrderMoveButton extends StatelessWidget {
  const _ItemOrderMoveButton({
    super.key,
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
              color: enabled
                  ? const Color(0xFF0E2F66)
                  : const Color(0xFFC7C7C7),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Icon(icon, size: 22),
        ),
      ),
    );
  }
}