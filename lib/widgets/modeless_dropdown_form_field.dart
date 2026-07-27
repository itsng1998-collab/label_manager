import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModelessDropdownFormField<T> extends StatefulWidget {
  const ModelessDropdownFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.focusNode,
    this.isExpanded = false,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final bool isExpanded;

  @override
  State<ModelessDropdownFormField<T>> createState() =>
      _ModelessDropdownFormFieldState<T>();
}

class _ModelessDropdownFormFieldState<T>
    extends State<ModelessDropdownFormField<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final FocusNode _internalFocusNode = FocusNode();
  OverlayEntry? _menuEntry;

  bool get _enabled => widget.onChanged != null && widget.items.isNotEmpty;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.initialValue) return item;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant ModelessDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _removeMenu();
  }

  @override
  void dispose() {
    _removeMenu(rebuild: false);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (!_enabled) return;
    _focusNode.requestFocus();
    if (_menuEntry != null) {
      _removeMenu();
      return;
    }
    final fieldContext = _fieldKey.currentContext;
    final renderObject = fieldContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final fieldRect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final screenSize = MediaQuery.sizeOf(context);
    const itemHeight = 48.0;
    final desiredHeight = itemHeight * widget.items.length;
    final availableBelow = screenSize.height - fieldRect.bottom - 4;
    final availableAbove = fieldRect.top - 4;
    final useBelow =
        availableBelow >= desiredHeight || availableBelow >= availableAbove;
    final availableHeight = useBelow ? availableBelow : availableAbove;
    final menuHeight = max(itemHeight, min(desiredHeight, availableHeight));
    final menuTop = useBelow
        ? fieldRect.bottom + 2
        : max(0.0, fieldRect.top - menuHeight - 2);
    final menuLeft = min(
      max(0.0, fieldRect.left),
      max(0.0, screenSize.width - fieldRect.width),
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeMenu,
            ),
          ),
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: fieldRect.width,
            child: Material(
              color: Colors.white,
              elevation: 8,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: menuHeight),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return InkWell(
                      onTap: item.enabled
                          ? () {
                              _removeMenu();
                              widget.onChanged?.call(item.value);
                            }
                          : null,
                      child: SizedBox(
                        height: itemHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: item.child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    _menuEntry = entry;
    overlay.insert(entry);
    setState(() {});
  }

  void _removeMenu({bool rebuild = true}) {
    final entry = _menuEntry;
    if (entry == null) return;
    _menuEntry = null;
    if (entry.mounted) entry.remove();
    if (mounted && rebuild) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (_menuEntry != null &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _removeMenu();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        key: _fieldKey,
        onTap: _enabled ? _toggleMenu : null,
        child: InputDecorator(
          isEmpty: _selectedItem == null,
          isFocused: _menuEntry != null,
          decoration: widget.decoration.copyWith(
            enabled: _enabled,
            suffixIcon: Icon(
              _menuEntry == null
                  ? Icons.arrow_drop_down
                  : Icons.arrow_drop_up,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: true,
            fillColor: _enabled ? Colors.white : const Color(0xFFE9ECEF),
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyLarge!,
            overflow: TextOverflow.ellipsis,
            child: _selectedItem?.child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}