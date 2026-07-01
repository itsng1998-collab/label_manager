import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SwipeActionTableColumn<T> {
  const SwipeActionTableColumn({
    required this.header,
    required this.text,
    this.initialWidth = 120,
    this.minWidth = 60,
    this.fillRemaining = false,
    this.cellBuilder,
  });

  final String header;
  final String Function(T row) text;
  final double initialWidth;
  final double minWidth;
  final bool fillRemaining;
  final Widget Function(BuildContext context, T row, double width)? cellBuilder;
}

class SwipeActionTableAction<T> {
  const SwipeActionTableAction({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    this.onPressed,
    this.onRowPressed,
    this.isPressed,
    this.isEnabled,
  });

  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final void Function(T row, int index)? onRowPressed;
  final bool Function(T row, int index)? isPressed;
  final bool Function(T row, int index)? isEnabled;
}

class SwipeActionTable<T> extends StatefulWidget {
  const SwipeActionTable({
    super.key,
    required this.rows,
    required this.columns,
    this.rowSwipeEnabled = false,
    this.actions = const [],
    this.showActionsWhenEmpty = false,
    this.emptyActions,
    this.rowTooltip,
    this.keepRowContentOnSwipe = false,
    this.rowNumberWidth = 40,
    this.headerHeight = 36,
    this.rowHeight = 28,
    this.autoFitColumns = true,
    this.fillLastColumn = false,
    this.isRowContentInteractive,
    this.canSwipeRow,
  });

  final List<T> rows;
  final List<SwipeActionTableColumn<T>> columns;
  final bool rowSwipeEnabled;
  final List<SwipeActionTableAction<T>> actions;
  final bool showActionsWhenEmpty;
  final List<SwipeActionTableAction<T>>? emptyActions;
  final String? rowTooltip;
  final bool keepRowContentOnSwipe;
  final double rowNumberWidth;
  final double headerHeight;
  final double rowHeight;
  final bool autoFitColumns;
  final bool fillLastColumn;
  final bool Function(T row, int index)? isRowContentInteractive;
  final bool Function(T row, int index)? canSwipeRow;

  @override
  State<SwipeActionTable<T>> createState() => _SwipeActionTableState<T>();
}

class _SwipeActionTableState<T> extends State<SwipeActionTable<T>> {
  static const Color _headerColor = Color(0xFF0E2F66);
  static const Color _headerSeparatorColor = Color(0xFFBDBDBD);
  static const Color _bodySeparatorColor = Color(0xFFE6E8EB);
  static const double _actionWidth = 34.56;

  final ScrollController _hScrollHeader = ScrollController();
  final ScrollController _hScrollBody = ScrollController();
  final ScrollController _vScrollBody = ScrollController();
  final ScrollController _vScrollIndex = ScrollController();
  bool _syncingVertical = false;
  bool _syncingHorizontal = false;
  late List<double> _widths;
  int? _draggingIndex;
  int? _selectedIndex;
  int? _openActionIndex;
  String? _tableSignature;

  @override
  void initState() {
    super.initState();
    _widths = _initialWidths();
    _hScrollBody.addListener(_syncHorizontalFromBody);
    _hScrollHeader.addListener(_syncHorizontalFromHeader);
    _vScrollBody.addListener(_syncVerticalScrollFromBody);
    _vScrollIndex.addListener(_syncVerticalScrollFromIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoWidthsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SwipeActionTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns.length != widget.columns.length ||
        _initialWidthsChanged(oldWidget.columns, widget.columns)) {
      _widths = _initialWidths();
      _tableSignature = null;
    }
    if ((_selectedIndex ?? -1) >= widget.rows.length) {
      _selectedIndex = null;
    }
    if ((_openActionIndex ?? -1) >= widget.rows.length) {
      _openActionIndex = null;
    }
    _syncAutoWidthsIfNeeded();
  }

  @override
  void dispose() {
    _hScrollHeader.dispose();
    _hScrollBody.dispose();
    _vScrollBody.dispose();
    _vScrollIndex.dispose();
    super.dispose();
  }

  List<double> _initialWidths() {
    return [for (final column in widget.columns) column.initialWidth];
  }

  bool _initialWidthsChanged(
    List<SwipeActionTableColumn<T>> oldColumns,
    List<SwipeActionTableColumn<T>> newColumns,
  ) {
    for (var index = 0; index < oldColumns.length; index += 1) {
      if (oldColumns[index].initialWidth != newColumns[index].initialWidth) {
        return true;
      }
    }
    return false;
  }

  void _syncAutoWidthsIfNeeded() {
    if (!widget.autoFitColumns || widget.columns.isEmpty) {
      return;
    }
    final signature = _autoFitSignature();
    if (_tableSignature == signature) {
      return;
    }
    _tableSignature = signature;
    _widths = _autoFitWidths();
  }

  String _autoFitSignature() {
    return [
      for (final column in widget.columns) column.header,
      for (final row in widget.rows)
        for (final column in widget.columns) column.text(row),
    ].join('\u001f');
  }

  List<double> _autoFitWidths() {
    final scaler = MediaQuery.of(context).textScaler;
    const style = TextStyle(fontSize: 14);
    return List<double>.generate(widget.columns.length, (index) {
      final column = widget.columns[index];
      var maxWidth = _measureText(column.header, style, scaler) + 24;
      for (final row in widget.rows) {
        final width = _measureText(column.text(row), style, scaler) + 24;
        if (width > maxWidth) {
          maxWidth = width;
        }
      }
      return maxWidth < column.minWidth ? column.minWidth : maxWidth;
    });
  }

  static double _measureText(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.size.width;
  }

  void _startResize(int index) {
    setState(() => _draggingIndex = index);
  }

  void _updateResize(DragUpdateDetails details) {
    final index = _draggingIndex;
    if (index == null || index + 1 >= _widths.length) {
      return;
    }
    final leftMin = widget.columns[index].minWidth;
    final rightMin = widget.columns[index + 1].minWidth;
    final left = (_widths[index] + details.delta.dx).clamp(
      leftMin,
      double.infinity,
    );
    final right = (_widths[index + 1] - details.delta.dx).clamp(
      rightMin,
      double.infinity,
    );
    setState(() {
      _widths[index] = left;
      _widths[index + 1] = right;
    });
  }

  void _updateLastResize(DragUpdateDetails details) {
    final last = _widths.length - 1;
    setState(() {
      _widths[last] = (_widths[last] + details.delta.dx).clamp(
        widget.columns[last].minWidth,
        double.infinity,
      );
    });
  }

  void _endResize() {
    setState(() => _draggingIndex = null);
  }

  void _autoFitColumn(int index) {
    if (!widget.autoFitColumns) {
      return;
    }
    final scaler = MediaQuery.of(context).textScaler;
    const style = TextStyle(fontSize: 14);
    final column = widget.columns[index];
    var width = _measureText(column.header, style, scaler) + 24;
    for (final row in widget.rows) {
      final rowWidth = _measureText(column.text(row), style, scaler) + 24;
      if (rowWidth > width) {
        width = rowWidth;
      }
    }
    setState(() {
      _widths[index] = width < column.minWidth ? column.minWidth : width;
    });
  }

  void _syncVerticalScrollFromBody() {
    if (_syncingVertical) return;
    if (!_vScrollBody.hasClients || !_vScrollIndex.hasClients) return;
    _syncingVertical = true;
    _vScrollIndex.jumpTo(
      _vScrollBody.offset.clamp(
        _vScrollIndex.position.minScrollExtent,
        _vScrollIndex.position.maxScrollExtent,
      ),
    );
    _syncingVertical = false;
  }

  void _syncVerticalScrollFromIndex() {
    if (_syncingVertical) return;
    if (!_vScrollIndex.hasClients || !_vScrollBody.hasClients) return;
    _syncingVertical = true;
    _vScrollBody.jumpTo(
      _vScrollIndex.offset.clamp(
        _vScrollBody.position.minScrollExtent,
        _vScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingVertical = false;
  }

  void _syncHorizontalFromBody() {
    if (_syncingHorizontal) return;
    if (!_hScrollBody.hasClients || !_hScrollHeader.hasClients) return;
    _syncingHorizontal = true;
    _hScrollHeader.jumpTo(
      _hScrollBody.offset.clamp(
        _hScrollHeader.position.minScrollExtent,
        _hScrollHeader.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  void _syncHorizontalFromHeader() {
    if (_syncingHorizontal) return;
    if (!_hScrollHeader.hasClients || !_hScrollBody.hasClients) return;
    _syncingHorizontal = true;
    _hScrollBody.jumpTo(
      _hScrollHeader.offset.clamp(
        _hScrollBody.position.minScrollExtent,
        _hScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  List<double> _effectiveWidths(double viewportWidth) {
    final widths = List<double>.from(_widths);
    if (widths.isEmpty) {
      return widths;
    }
    final fillIndex = widget.columns.lastIndexWhere(
      (column) => column.fillRemaining,
    );
    final targetIndex = fillIndex >= 0
        ? fillIndex
        : (widget.fillLastColumn ? widths.length - 1 : -1);
    if (targetIndex < 0) {
      return widths;
    }
    final reserved = widget.rowNumberWidth +
        widths.asMap().entries.fold<double>(
          0,
          (sum, entry) => entry.key == targetIndex ? sum : sum + entry.value,
        );
    final remaining = viewportWidth - reserved;
    if (remaining > widths[targetIndex]) {
      widths[targetIndex] = remaining;
    }
    return widths;
  }

  Widget _buildHeader(List<double> widths) {
    const double handleWidth = 4.0;
    final lastIndex = widths.length - 1;
    return Container(
      color: _headerColor,
      height: widget.headerHeight,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(widths.length, (index) {
          final isLast = index == lastIndex;
          final cell = SizedBox(
            width: widths[index],
            child: Center(
              child: Text(
                widget.columns[index].header,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          return Stack(
            children: [
              cell,
              Positioned(
                right: -2,
                top: 0,
                bottom: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => _startResize(index),
                    onHorizontalDragUpdate: isLast
                        ? _updateLastResize
                        : _updateResize,
                    onHorizontalDragEnd: (_) => _endResize(),
                    onDoubleTap: () => _autoFitColumn(index),
                    child: SizedBox(
                      width: handleWidth,
                      child: Container(
                        width: 1,
                        height: double.infinity,
                        color: isLast ? Colors.transparent : _headerSeparatorColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRowNumberHeader() {
    return Container(
      width: widget.rowNumberWidth,
      height: widget.headerHeight,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: _headerColor,
        border: Border(right: BorderSide(color: _headerSeparatorColor)),
      ),
    );
  }

  Widget _buildRowNumberList() {
    return SizedBox(
      width: widget.rowNumberWidth,
      child: ListView.builder(
        controller: _vScrollIndex,
        itemCount: widget.rows.length,
        itemBuilder: (context, index) => _buildRowNumber(index),
      ),
    );
  }

  Widget _buildRowNumber(int index) {
    return Container(
      height: widget.rowHeight,
      decoration: const BoxDecoration(
        color: _headerColor,
        border: Border(
          right: BorderSide(color: _bodySeparatorColor),
          top: BorderSide(color: _bodySeparatorColor),
          bottom: BorderSide(color: _bodySeparatorColor),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCell(T row, int index, List<double> widths) {
    final column = widget.columns[index];
    final custom = column.cellBuilder;
    if (custom != null) {
      return custom(context, row, widths[index]);
    }
    return SizedBox(
      width: widths[index],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            column.text(row),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildActionRail(
    List<SwipeActionTableAction<T>> actions, {
    T? row,
    int? rowIndex,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in actions)
            Builder(
              builder: (context) {
                final isRowAction = row != null && rowIndex != null;
                final isEnabled = isRowAction
                  ? action.isEnabled?.call(row, rowIndex) ?? true
                  : true;
                final rawCallback = isRowAction && action.onRowPressed != null
                  ? () => action.onRowPressed!(row, rowIndex)
                  : action.onPressed;
                final callback = isEnabled ? rawCallback : null;
                final isPressed = isRowAction
                    ? action.isPressed?.call(row, rowIndex) ?? false
                    : false;
                final color = callback == null
                    ? action.backgroundColor.withValues(alpha: 0.45)
                    : action.backgroundColor;
                final backgroundColor = isPressed
                    ? Color.lerp(color, Colors.black, 0.16) ?? color
                    : color;
                return Tooltip(
                  message: action.tooltip,
                  child: SizedBox(
                    width: _actionWidth,
                    height: widget.rowHeight,
                    child: Material(
                      color: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: isPressed
                              ? const Border(
                                  top: BorderSide(color: Color(0xff4b5563)),
                                  left: BorderSide(color: Color(0xff4b5563)),
                                  right: BorderSide(color: Color(0xffcbd5e1)),
                                  bottom: BorderSide(color: Color(0xffcbd5e1)),
                                )
                              : null,
                        ),
                        child: Transform.translate(
                          offset: isPressed ? const Offset(1, 1) : Offset.zero,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              action.icon,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: callback,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(T row, int index, List<double> widths) {
    final contentWidth = widths.fold<double>(0, (sum, width) => sum + width);
    final actionsWidth = widget.actions.length * _actionWidth;
    final canSwipeRow = widget.canSwipeRow?.call(row, index) ?? true;
    final isOpen = widget.rowSwipeEnabled && canSwipeRow && _openActionIndex == index;
    final isRowContentInteractive =
        widget.isRowContentInteractive?.call(row, index) ?? false;
    final rowWidths = isRowContentInteractive &&
            isOpen &&
            widget.keepRowContentOnSwipe &&
            widths.isNotEmpty
        ? _withTrailingInset(widths, actionsWidth)
        : widths;
    final separators = List<double>.generate(
      rowWidths.length - 1,
      (separatorIndex) => rowWidths
          .sublist(0, separatorIndex + 1)
          .fold<double>(0, (sum, width) => sum + width),
    );
    final rowContent = SizedBox(
      width: contentWidth,
      height: widget.rowHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _selectedIndex == index
                  ? const Color(0xFFE3F2FD)
                  : (index.isEven ? Colors.white : const Color(0xFFF2F4F7)),
              border: const Border(bottom: BorderSide(color: _bodySeparatorColor)),
            ),
            child: Row(
              children: List.generate(
                widget.columns.length,
                (cellIndex) => _buildCell(row, cellIndex, rowWidths),
              ),
            ),
          ),
          for (final x in separators)
            Positioned(
              left: x - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: _bodySeparatorColor),
            ),
          if (!isRowContentInteractive)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => setState(() => _selectedIndex = index),
                ),
              ),
            ),
        ],
      ),
    );
    final foreground = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        isOpen && !widget.keepRowContentOnSwipe ? -actionsWidth : 0,
        0,
        0,
      ),
      child: rowContent,
    );
    return SizedBox(
      width: contentWidth,
      height: widget.rowHeight,
      child: ClipRect(
        child: Stack(
          children: [
            if (isRowContentInteractive)
              foreground
            else
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: widget.rowSwipeEnabled && canSwipeRow
                    ? (details) {
                        if (details.delta.dx < -2) {
                          setState(() => _openActionIndex = index);
                        } else if (details.delta.dx > 2) {
                          setState(() => _openActionIndex = null);
                        }
                      }
                    : null,
                child: foreground,
              ),
            if (widget.rowSwipeEnabled && widget.actions.isNotEmpty)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                top: 0,
                bottom: 0,
                right: isOpen ? 0 : -actionsWidth,
                width: actionsWidth,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 2) {
                      setState(() => _openActionIndex = null);
                    }
                  },
                  child: _buildActionRail(
                    widget.actions,
                    row: row,
                    rowIndex: index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<double> _withTrailingInset(List<double> widths, double inset) {
    final adjusted = List<double>.from(widths);
    adjusted[adjusted.length - 1] = (adjusted.last - inset).clamp(
      0,
      double.infinity,
    );
    return adjusted;
  }

  Widget _buildEmptyBody(List<double> widths) {
    final contentWidth = widths.fold<double>(0, (sum, width) => sum + width);
    final actions = widget.emptyActions ?? widget.actions;
    if (!widget.showActionsWhenEmpty || actions.isEmpty) {
      return SizedBox(width: contentWidth);
    }
    return SizedBox(
      width: contentWidth,
      height: widget.rowHeight,
      child: Stack(
        children: [
          Container(color: Colors.white),
          Positioned.fill(child: _buildActionRail(actions)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = _effectiveWidths(constraints.maxWidth);
        final contentWidth = widths.fold<double>(0, (sum, width) => sum + width);
        final horizontalViewportWidth = (constraints.maxWidth -
                widget.rowNumberWidth)
            .clamp(0, double.infinity);
        final hasHorizontalOverflow = contentWidth > horizontalViewportWidth + 0.5;
        return Column(
          children: [
            Row(
              children: [
                _buildRowNumberHeader(),
                Expanded(
                  child: MouseRegion(
                    cursor: _draggingIndex != null
                        ? SystemMouseCursors.resizeLeftRight
                        : MouseCursor.defer,
                    child: SingleChildScrollView(
                      controller: _hScrollHeader,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentWidth,
                        child: _buildHeader(widths),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  _buildRowNumberList(),
                  Expanded(
                    child: MouseRegion(
                      cursor: _draggingIndex != null
                          ? SystemMouseCursors.resizeLeftRight
                          : MouseCursor.defer,
                      child: _TableBodyTooltip(
                        message: widget.rowTooltip,
                        child: Scrollbar(
                          controller: _vScrollBody,
                          thumbVisibility: true,
                          child: Scrollbar(
                            controller: _hScrollBody,
                            thumbVisibility: hasHorizontalOverflow,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _hScrollBody,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: ListView.builder(
                                  controller: _vScrollBody,
                                  itemCount: widget.rows.isEmpty
                                      ? 1
                                      : widget.rows.length,
                                  itemBuilder: (context, index) {
                                    if (widget.rows.isEmpty) {
                                      return _buildEmptyBody(widths);
                                    }
                                    return _buildDataRow(
                                      widget.rows[index],
                                      index,
                                      widths,
                                    );
                                  },
                                ),
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
          ],
        );
      },
    );
  }
}

class _TableBodyTooltip extends StatefulWidget {
  const _TableBodyTooltip({required this.message, required this.child});

  final String? message;
  final Widget child;

  @override
  State<_TableBodyTooltip> createState() => _TableBodyTooltipState();
}

class _TableBodyTooltipState extends State<_TableBodyTooltip> {
  Timer? _showTimer;
  Timer? _hideTimer;
  OverlayEntry? _entry;
  Offset? _cursorGlobalPosition;

  @override
  void didUpdateWidget(covariant _TableBodyTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _hideTooltip();
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _entry?.remove();
    super.dispose();
  }

  void _scheduleTooltip() {
    final text = widget.message;
    final cursorGlobalPosition = _cursorGlobalPosition;
    if (text == null ||
        text.isEmpty ||
        cursorGlobalPosition == null ||
        _entry != null) {
      return;
    }
    _showTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _entry != null) {
        return;
      }
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) {
        return;
      }
      _entry = OverlayEntry(
        builder: (context) {
          final overlayBox = overlay.context.findRenderObject() as RenderBox?;
          final cursorGlobalPosition = _cursorGlobalPosition;
          if (overlayBox == null || cursorGlobalPosition == null) {
            return const SizedBox.shrink();
          }
          final position = overlayBox.globalToLocal(cursorGlobalPosition);
          return Positioned(
            left: position.dx + 12,
            top: position.dy + 18,
            child: IgnorePointer(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff303030),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(_entry!);
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), _hideTooltip);
    });
  }

  void _updateCursorPosition(PointerHoverEvent event) {
    _cursorGlobalPosition = event.position;
    _entry?.markNeedsBuild();
  }

  void _hideTooltip() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _showTimer = null;
    _hideTimer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.message;
    if (text == null || text.isEmpty) {
      return widget.child;
    }
    return MouseRegion(
      onEnter: (event) {
        _cursorGlobalPosition = event.position;
        _scheduleTooltip();
      },
      onHover: _updateCursorPosition,
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}