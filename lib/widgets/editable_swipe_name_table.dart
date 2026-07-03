import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'swipe_action_table.dart';

class EditableSwipeNameTable<T> extends StatelessWidget {
  const EditableSwipeNameTable({
    super.key,
    required this.rows,
    required this.header,
    required this.text,
    required this.editController,
    required this.editFocusNode,
    required this.editingIndex,
    required this.insertActionIndex,
    required this.inserting,
    required this.canSubmit,
    required this.onToggleEdit,
    required this.onToggleInsert,
    required this.onCancelEdit,
    required this.onSubmitEdit,
    this.onEmptyInsert,
    this.onDeleteRow,
    this.onNameDoubleTap,
    this.enabled = true,
    this.fillLastColumn = true,
    this.autoFitColumns = false,
    this.rowSwipeEnabled = true,
    this.keepRowContentOnSwipe = true,
    this.showActionsWhenEmpty = true,
    this.rowTooltip,
    this.rowNumberText,
    this.rowReorderEnabled = false,
    this.selectedIndex,
    this.onRowSelected,
    this.onRowReorder,
    this.headerTrailingBuilder,
    this.initialWidth = 220,
    this.minWidth = 120,
  });

  final List<T> rows;
  final String header;
  final String Function(T row) text;
  final TextEditingController editController;
  final FocusNode editFocusNode;
  final int? editingIndex;
  final int? insertActionIndex;
  final bool inserting;
  final bool canSubmit;
  final void Function(T row, int index) onToggleEdit;
  final void Function(T row, int index) onToggleInsert;
  final VoidCallback onCancelEdit;
  final ValueChanged<String> onSubmitEdit;
  final VoidCallback? onEmptyInsert;
  final void Function(T row, int index)? onDeleteRow;
  final void Function(T row, int index)? onNameDoubleTap;
  final bool enabled;
  final bool fillLastColumn;
  final bool autoFitColumns;
  final bool rowSwipeEnabled;
  final bool keepRowContentOnSwipe;
  final bool showActionsWhenEmpty;
  final String? rowTooltip;
  final String Function(T row, int index)? rowNumberText;
  final bool rowReorderEnabled;
  final int? selectedIndex;
  final void Function(T row, int index)? onRowSelected;
  final void Function(int fromIndex, int toIndex)? onRowReorder;
  final Widget Function(BuildContext context, bool hasInlineEditor)?
      headerTrailingBuilder;
  final double initialWidth;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return SwipeActionTable<T>(
      rows: rows,
      fillLastColumn: fillLastColumn,
      autoFitColumns: autoFitColumns,
      rowSwipeEnabled: rowSwipeEnabled,
      keepRowContentOnSwipe: keepRowContentOnSwipe,
      rowTooltip: rowTooltip,
      showActionsWhenEmpty: showActionsWhenEmpty,
      isRowContentInteractive: (_, index) => editingIndex == index,
      canSwipeRow: (_, index) => editingIndex == null || editingIndex == index,
      actions: _rowActions(),
      emptyActions: _emptyActions(),
      rowNumberText: rowNumberText,
      rowReorderEnabled: rowReorderEnabled,
      selectedIndex: selectedIndex,
      onRowSelected: onRowSelected,
      onRowReorder: onRowReorder,
      columns: [
        SwipeActionTableColumn<T>(
          header: header,
          initialWidth: initialWidth,
          minWidth: minWidth,
          fillRemaining: true,
          text: text,
          cellBuilder: _buildNameCell,
          headerTrailingBuilder: headerTrailingBuilder,
          onDoubleTap: onNameDoubleTap,
        ),
      ],
    );
  }

  List<SwipeActionTableAction<T>> _rowActions() {
    return [
      SwipeActionTableAction<T>(
        icon: Icons.edit,
        tooltip: '수정',
        backgroundColor: const Color(0xFF0E2F66),
        onRowPressed: onToggleEdit,
        isPressed: (_, index) => !inserting && editingIndex == index,
        isEnabled: (_, _) => enabled && !inserting,
      ),
      SwipeActionTableAction<T>(
        icon: Icons.add,
        tooltip: '삽입',
        backgroundColor: const Color(0xff0277bd),
        onRowPressed: onToggleInsert,
        isPressed: (_, index) => inserting && insertActionIndex == index,
        isEnabled: (_, index) =>
            enabled &&
            (editingIndex == null ||
                (inserting && insertActionIndex == index)),
      ),
      SwipeActionTableAction<T>(
        icon: Icons.delete,
        tooltip: '삭제',
        backgroundColor: const Color(0xffc62828),
        onRowPressed: onDeleteRow,
        isEnabled: (_, _) => enabled && editingIndex == null && onDeleteRow != null,
      ),
    ];
  }

  List<SwipeActionTableAction<T>> _emptyActions() {
    return [
      SwipeActionTableAction<T>(
        icon: Icons.edit,
        tooltip: '수정',
        backgroundColor: const Color(0xff9ca3af),
      ),
      SwipeActionTableAction<T>(
        icon: Icons.add,
        tooltip: '삽입',
        backgroundColor: const Color(0xff0277bd),
        onPressed: enabled ? onEmptyInsert : null,
      ),
      SwipeActionTableAction<T>(
        icon: Icons.delete,
        tooltip: '삭제',
        backgroundColor: const Color(0xffb4bac3),
      ),
    ];
  }

  Widget _buildNameCell(BuildContext context, T row, double width) {
    final rowIndex = rows.indexWhere((candidate) => identical(candidate, row));
    if (rowIndex != editingIndex) {
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text(row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    return _InlineNameEditCell(
      width: width,
      controller: editController,
      focusNode: editFocusNode,
      canSubmit: canSubmit,
      onCancel: onCancelEdit,
      onSubmit: onSubmitEdit,
    );
  }
}

class _InlineNameEditCell extends StatelessWidget {
  const _InlineNameEditCell({
    required this.width,
    required this.controller,
    required this.focusNode,
    required this.canSubmit,
    required this.onCancel,
    required this.onSubmit,
  });

  final double width;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSubmit;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            onCancel();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (!canSubmit) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xfff0f4ff),
                  border: Border.all(
                    color: const Color(0xFF0E2F66),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(
                      left: 6,
                      right: 28,
                      top: 0,
                      bottom: 0,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSubmit(controller.text),
                ),
              ),
            ),
            Positioned(
              top: 3,
              right: 3,
              bottom: 3,
              width: 22,
              child: Tooltip(
                message: '변경 적용',
                child: MouseRegion(
                  cursor: canSubmit
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: canSubmit ? () => onSubmit(controller.text) : null,
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
}