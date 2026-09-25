import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_manager/utils/regression_debug_log.dart';

const double modelessDropdownFieldHeight = 40;
const double modelessDropdownMenuItemHeight = 28;

class ModelessDropdownFormField<T> extends StatefulWidget {
  const ModelessDropdownFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.focusNode,
    this.isExpanded = false,
    this.searchTextForValue,
    this.searchHintText = '검색',
    this.debugLabel,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final bool isExpanded;
  final String Function(T value)? searchTextForValue;
  final String searchHintText;
  final String? debugLabel;

  @override
  State<ModelessDropdownFormField<T>> createState() =>
      _ModelessDropdownFormFieldState<T>();
}

class _ModelessDropdownFormFieldState<T>
    extends State<ModelessDropdownFormField<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final FocusNode _internalFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _menuEntry;
  bool _menuRefreshScheduled = false;

  bool get _enabled => widget.onChanged != null && widget.items.isNotEmpty;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  List<DropdownMenuItem<T>> get _visibleItems {
    final searchTextForValue = widget.searchTextForValue;
    final query = _searchController.text.trim().toLowerCase();
    if (searchTextForValue == null || query.isEmpty) return widget.items;
    return widget.items.where((item) {
      final value = item.value;
      return value != null &&
          searchTextForValue(value).trim().toLowerCase().contains(query);
    }).toList(growable: false);
  }

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.initialValue) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshMenu);
  }

  @override
  void didUpdateWidget(covariant ModelessDropdownFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _removeMenu(rebuild: false);
      return;
    }
    _scheduleMenuRefresh();
  }

  @override
  void dispose() {
    _removeMenu(rebuild: false);
    _searchController
      ..removeListener(_refreshMenu)
      ..dispose();
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _refreshMenu() {
    _menuEntry?.markNeedsBuild();
    final debugLabel = widget.debugLabel;
    if (debugLabel != null) {
      RegressionDebugLog.event(
        'dropdownSearch',
        'queryChanged',
        fields: {
          'control': debugLabel,
          'query': _searchController.text,
          'matches': _visibleItems.length,
          'total': widget.items.length,
        },
      );
    }
  }

  void _scheduleMenuRefresh() {
    final entry = _menuEntry;
    if (entry == null || _menuRefreshScheduled) return;
    _menuRefreshScheduled = true;
    final debugLabel = widget.debugLabel;
    if (debugLabel != null) {
      RegressionDebugLog.event(
        'dropdownSearch',
        'refreshScheduled',
        fields: {
          'control': debugLabel,
          'phase': WidgetsBinding.instance.schedulerPhase.name,
          'total': widget.items.length,
        },
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuRefreshScheduled = false;
      if (!mounted || _menuEntry != entry || !entry.mounted) {
        if (debugLabel != null) {
          RegressionDebugLog.event(
            'dropdownSearch',
            'refreshSkipped',
            fields: {
              'control': debugLabel,
              'mounted': mounted,
              'sameEntry': _menuEntry == entry,
              'entryMounted': entry.mounted,
            },
          );
        }
        return;
      }
      entry.markNeedsBuild();
      if (debugLabel != null) {
        RegressionDebugLog.event(
          'dropdownSearch',
          'refreshApplied',
          fields: {'control': debugLabel, 'total': widget.items.length},
        );
      }
    });
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
    const itemHeight = modelessDropdownMenuItemHeight;
    final searchHeight = widget.searchTextForValue == null ? 0.0 : 48.0;
    final desiredHeight = searchHeight + itemHeight * widget.items.length;
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
                child: _buildMenu(itemHeight),
              ),
            ),
          ),
        ],
      ),
    );
    _menuEntry = entry;
    overlay.insert(entry);
    final debugLabel = widget.debugLabel;
    if (debugLabel != null) {
      RegressionDebugLog.event(
        'dropdownSearch',
        'opened',
        fields: {'control': debugLabel, 'total': widget.items.length},
      );
    }
    setState(() {});
  }

  Widget _buildMenu(double itemHeight) {
    final items = _visibleItems;
    final list = items.isEmpty
        ? const Center(child: Text('검색 결과가 없습니다.'))
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                key: ValueKey('modeless-dropdown-menu-item-$index'),
                onTap: item.enabled
                    ? () {
                        final debugLabel = widget.debugLabel;
                        if (debugLabel != null) {
                          RegressionDebugLog.event(
                            'dropdownSearch',
                            'itemSelected',
                            fields: {
                              'control': debugLabel,
                              'query': _searchController.text,
                              'value': item.value,
                              'visibleIndex': index,
                              'matches': items.length,
                            },
                          );
                        }
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
          );
    if (widget.searchTextForValue == null) return list;
    return SizedBox(
      height: double.infinity,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: SizedBox(
              height: 36,
              child: TextField(
                key: const ValueKey('modeless-dropdown-search-field'),
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.searchHintText,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }

  void _removeMenu({bool rebuild = true}) {
    final entry = _menuEntry;
    if (entry == null) return;
    _menuEntry = null;
    if (entry.mounted) entry.remove();
    _searchController.clear();
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
            isDense: true,
            constraints: const BoxConstraints.tightFor(
              height: modelessDropdownFieldHeight,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            child: Align(
              key: const ValueKey('modeless-dropdown-selected-item'),
              alignment: Alignment.centerLeft,
              child: _selectedItem?.child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}