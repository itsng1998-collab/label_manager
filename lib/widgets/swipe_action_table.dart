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
    this.headerTrailing,
    this.headerTrailingBuilder,
    this.cellBuilder,
    this.onDoubleTap,
  }) : assert(
         headerTrailing == null || headerTrailingBuilder == null,
         'headerTrailing and headerTrailingBuilder cannot both be set.',
       );

  final String header;
  final String Function(T row) text;
  final double initialWidth;
  final double minWidth;
  final bool fillRemaining;
  final Widget? headerTrailing;
  final Widget Function(BuildContext context, bool hasInteractiveRow)?
      headerTrailingBuilder;
  final Widget Function(BuildContext context, T row, double width)? cellBuilder;
  final void Function(T row, int index)? onDoubleTap;
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
    this.rowReorderEnabled = false,
    this.isRowContentInteractive,
    this.canSwipeRow,
    this.rowNumberText,
    this.selectedIndex,
    this.onRowSelected,
    this.onRowReorder,
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
  final bool rowReorderEnabled;
  final bool Function(T row, int index)? isRowContentInteractive;
  final bool Function(T row, int index)? canSwipeRow;
  final String Function(T row, int index)? rowNumberText;
  final int? selectedIndex;
  final void Function(T row, int index)? onRowSelected;
  final void Function(int fromIndex, int toIndex)? onRowReorder;

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
  int? _rowDraggingIndex;
  int? _rowDropTargetIndex;
  int? _selectedIndex;
  int? _openActionIndex;
  int? _lastPointerDownRowIndex;
  int? _lastPointerDownColumnIndex;
  DateTime? _lastPointerDownAt;
  String? _tableSignature;

  @override
  void initState() {
    super.initState();
    _widths = _initialWidths();
    _selectedIndex = widget.selectedIndex;
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
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if ((_openActionIndex ?? -1) >= widget.rows.length) {
      _openActionIndex = null;
    }
    if ((_rowDraggingIndex ?? -1) >= widget.rows.length) {
      _rowDraggingIndex = null;
    }
    if ((_rowDropTargetIndex ?? -1) >= widget.rows.length) {
      _rowDropTargetIndex = null;
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

  void _startRowDrag(int index) {
    setState(() {
      _rowDraggingIndex = index;
      _rowDropTargetIndex = null;
      _openActionIndex = null;
    });
  }

  void _updateRowDropTarget(int index) {
    final draggingIndex = _rowDraggingIndex;
    if (draggingIndex == null || draggingIndex == index) {
      return;
    }
    if (_rowDropTargetIndex != index) {
      setState(() => _rowDropTargetIndex = index);
    }
  }

  void _clearRowDropTarget(int index) {
    if (_rowDropTargetIndex == index) {
      setState(() => _rowDropTargetIndex = null);
    }
  }

  void _endRowDrag() {
    if (_rowDraggingIndex != null || _rowDropTargetIndex != null) {
      setState(() {
        _rowDraggingIndex = null;
        _rowDropTargetIndex = null;
      });
    }
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
    final hasInteractiveRow = _hasInteractiveRow;
    return Container(
      color: _headerColor,
      height: widget.headerHeight,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(widths.length, (index) {
          final isLast = index == lastIndex;
          final column = widget.columns[index];
          final headerTrailing =
              column.headerTrailingBuilder?.call(context, hasInteractiveRow) ??
              column.headerTrailing;
          final cell = SizedBox(
            width: widths[index],
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 6,
                      right: headerTrailing == null ? 6 : 34,
                    ),
                    child: Text(
                      column.header,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (headerTrailing != null)
                  Positioned(
                    top: 0,
                    right: 5,
                    bottom: 0,
                    child: Center(child: headerTrailing),
                  ),
              ],
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

  bool get _hasInteractiveRow {
    final isRowContentInteractive = widget.isRowContentInteractive;
    if (isRowContentInteractive == null) {
      return false;
    }
    for (var index = 0; index < widget.rows.length; index += 1) {
      if (isRowContentInteractive(widget.rows[index], index)) {
        return true;
      }
    }
    return false;
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

  Widget _buildRowNumberList(List<double> widths) {
    return SizedBox(
      width: widget.rowNumberWidth,
      child: ListView.builder(
        controller: _vScrollIndex,
        itemCount: widget.rows.length,
        itemBuilder: (context, index) => _buildRowNumber(index, widths),
      ),
    );
  }

  Widget _buildRowNumberBox(int index) {
    final rowNumberText =
        widget.rowNumberText?.call(widget.rows[index], index) ?? '${index + 1}';
    return Container(
      width: widget.rowNumberWidth,
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
        rowNumberText,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRowNumber(int index, List<double> widths) {
    final rowNumber = _buildRowNumberBox(index);
    final onRowReorder = widget.onRowReorder;
    if (!widget.rowReorderEnabled || onRowReorder == null) {
      return rowNumber;
    }
    final dataFeedback = _buildDataRowFeedback(widget.rows[index], index, widths);
    return _buildRowReorderTarget(
      index: index,
      width: widget.rowNumberWidth,
      child: rowNumber,
      feedback: _buildWholeRowFeedback(index, dataFeedback),
    );
  }

  Widget _buildWholeRowFeedback(int index, Widget dataRow) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRowNumberBox(index),
        dataRow,
      ],
    );
  }

  Widget _buildDataRowFeedback(T row, int index, List<double> widths) {
    final contentWidth = widths.fold<double>(0, (sum, width) => sum + width);
    return SizedBox(
      width: contentWidth,
      height: widget.rowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? const Color(0xFFE3F2FD)
              : (index.isEven ? Colors.white : const Color(0xFFF2F4F7)),
          border: const Border(bottom: BorderSide(color: _bodySeparatorColor)),
        ),
        child: Row(
          children: List.generate(
            widget.columns.length,
            (cellIndex) => _buildCell(row, cellIndex, widths),
          ),
        ),
      ),
    );
  }

  Widget _buildRowReorderTarget({
    required int index,
    required double width,
    required Widget child,
    required Widget feedback,
  }) {
    final onRowReorder = widget.onRowReorder;
    if (!widget.rowReorderEnabled || onRowReorder == null) {
      return child;
    }
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onMove: (_) => _updateRowDropTarget(index),
      onLeave: (_) => _clearRowDropTarget(index),
      onAcceptWithDetails: (details) {
        _acceptRowReorder(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        final draggingIndex = _rowDraggingIndex;
        final isDraggingRow = draggingIndex == index;
        final visibleChild = Opacity(
          opacity: isDraggingRow ? 0.35 : 1,
          child: child,
        );
        final showDropGap = draggingIndex != null &&
            _rowDropTargetIndex == index &&
            draggingIndex != index;
        final decorated = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              width: width,
              height: showDropGap ? widget.rowHeight : 0,
              decoration: const BoxDecoration(
                color: Color(0x1A0E2F66),
                border: Border(
                  top: BorderSide(color: Color(0xFF0E2F66), width: 2),
                ),
              ),
            ),
            visibleChild,
          ],
        );
        return Draggable<int>(
          data: index,
          axis: Axis.vertical,
          onDragStarted: () => _startRowDrag(index),
          onDragEnd: (_) => _endRowDrag(),
          onDraggableCanceled: (_, _) => _endRowDrag(),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(opacity: 0.82, child: feedback),
          ),
          childWhenDragging: child,
          child: decorated,
        );
      },
    );
  }

  void _acceptRowReorder(int fromIndex, int toIndex) {
    final onRowReorder = widget.onRowReorder;
    if (onRowReorder == null) {
      _endRowDrag();
      return;
    }
    if (fromIndex != toIndex) {
      onRowReorder(fromIndex, toIndex);
    }
    _endRowDrag();
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

  int? _columnIndexAt(double x, List<double> widths) {
    if (x < 0) {
      return null;
    }
    var left = 0.0;
    for (var columnIndex = 0; columnIndex < widths.length; columnIndex++) {
      final right = left + widths[columnIndex];
      if (x >= left && x <= right) {
        return columnIndex;
      }
      left = right;
    }
    return null;
  }

  void _handleRowPointerDown(
    T row,
    int rowIndex,
    List<double> widths,
    Offset local,
  ) {
    final columnIndex = _columnIndexAt(local.dx, widths);
    final now = DateTime.now();
    final lastPointerDownAt = _lastPointerDownAt;
    final isDoubleTap =
        columnIndex != null &&
        _lastPointerDownRowIndex == rowIndex &&
        _lastPointerDownColumnIndex == columnIndex &&
        lastPointerDownAt != null &&
        now.difference(lastPointerDownAt) <= const Duration(milliseconds: 500);

    setState(() => _selectedIndex = rowIndex);
    widget.onRowSelected?.call(row, rowIndex);

    if (!isDoubleTap) {
      debugPrint('[SwipeTable] pointerDown row=$rowIndex col=$columnIndex single lastRow=$_lastPointerDownRowIndex lastCol=$_lastPointerDownColumnIndex');
      _lastPointerDownRowIndex = rowIndex;
      _lastPointerDownColumnIndex = columnIndex;
      _lastPointerDownAt = now;
      return;
    }

    debugPrint('[SwipeTable] pointerDown row=$rowIndex col=$columnIndex DOUBLE_TAP');
    _lastPointerDownRowIndex = null;
    _lastPointerDownColumnIndex = null;
    _lastPointerDownAt = null;
    final onDoubleTap = widget.columns[columnIndex].onDoubleTap;
    if (onDoubleTap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('[SwipeTable] onDoubleTap postFrameCallback row=$rowIndex col=$columnIndex');
          onDoubleTap(row, rowIndex);
        }
      });
    }
  }

  Widget _buildActionRail(
    List<SwipeActionTableAction<T>> actions, {
    T? row,
    int? rowIndex,
  }) {
    // Container 래퍼 제거 → Align 사용. Container(BoxDecoration.border) 가
    // AnimatedPositioned(width: actionsWidth) 결합 시 1px RenderFlex 오버플로 유발.
    // 구분선은 버튼 자체의 border 로 처리: 첫 버튼 left, 비마지막 버튼 right.
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++)
            Builder(
              builder: (context) {
                final action = actions[i];
                final isFirst = i == 0;
                final isLast = i == actions.length - 1;
                final isRowAction = row != null && rowIndex != null;
                final isEnabled = isRowAction
                  ? action.isEnabled?.call(row, rowIndex) ?? true
                  : true;
                final rawCallback = isRowAction && action.onRowPressed != null
                  ? () {
                      debugPrint('[SwipeTable] action pressed row=$rowIndex tooltip=${action.tooltip}');
                      action.onRowPressed!(row, rowIndex);
                    }
                  : action.onPressed != null
                      ? () {
                          debugPrint('[SwipeTable] action pressed (global) tooltip=${action.tooltip}');
                          action.onPressed!();
                        }
                      : null;
                final callback = isEnabled ? rawCallback : null;
                final isPressed = isRowAction
                    ? action.isPressed?.call(row, rowIndex) ?? false
                    : false;
                final backgroundColor = isPressed
                    ? (Color.lerp(action.backgroundColor, Colors.black, 0.22) ?? action.backgroundColor)
                    : action.backgroundColor;
                // 셀-레일 구분선: 첫 버튼 left border
                // 버튼 사이 구분선: 비마지막 버튼 right border
                // border 는 strokeAlignInside 라 레이아웃 폭에 영향 없음
                final Border? buttonBorder;
                if (isFirst && !isLast) {
                  buttonBorder = const Border(
                    left: BorderSide(color: Color(0xffd1d5db)),
                    right: BorderSide(color: Color(0x30000000)),
                  );
                } else if (isFirst) {
                  buttonBorder = const Border(
                    left: BorderSide(color: Color(0xffd1d5db)),
                  );
                } else if (!isLast) {
                  buttonBorder = const Border(
                    right: BorderSide(color: Color(0x30000000)),
                  );
                } else {
                  buttonBorder = null;
                }
                // disabled 는 전체 Opacity 로 처리해 색상 정체성 유지
                return IgnorePointer(
                  ignoring: !isEnabled,
                  child: Opacity(
                    opacity: isEnabled ? 1.0 : 0.38,
                    child: Tooltip(
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
                              border: buttonBorder,
                            ),
                            child: Transform.translate(
                              offset: isPressed ? const Offset(0, 1) : Offset.zero,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  action.icon,
                                  size: 17,
                                  color: Colors.white,
                                ),
                                onPressed: callback,
                              ),
                            ),
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
    final isRowContentInteractive =
        widget.isRowContentInteractive?.call(row, index) ?? false;
    // 편집 중인 행도 스와이프 상태이면 액션 레일을 유지한다.
    // 레일이 열린 채 편집 진입 시 _withTrailingInset 으로 셀 폭을 줄여
    // 제출 버튼(←)과 액션 레일이 함께 보이도록 한다.
    final isOpen = widget.rowSwipeEnabled &&
        canSwipeRow &&
        _openActionIndex == index;
    debugPrint('[SwipeTable] buildDataRow row=$index isOpen=$isOpen'
        ' isInteractive=$isRowContentInteractive openIdx=$_openActionIndex');
    // isOpen 이고 keepRowContentOnSwipe 이면 마지막 컬럼 폭을 레일 폭만큼 줄인다.
    final rowWidths = isOpen &&
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
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) => _handleRowPointerDown(
                  row,
                  index,
                  rowWidths,
                  event.localPosition,
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
    final rowBox = SizedBox(
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
                          if (_openActionIndex != index) {
                            debugPrint('[SwipeTable] swipe open row=$index (prev=$_openActionIndex)');
                            setState(() => _openActionIndex = index);
                          }
                        } else if (details.delta.dx > 2) {
                          if (_openActionIndex == index) {
                            debugPrint('[SwipeTable] swipe close row=$index');
                            setState(() => _openActionIndex = null);
                          }
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
                      if (_openActionIndex == index) {
                        debugPrint('[SwipeTable] swipe close (rail) row=$index');
                        setState(() => _openActionIndex = null);
                      }
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
    final onRowReorder = widget.onRowReorder;
    if (!widget.rowReorderEnabled || onRowReorder == null || isRowContentInteractive) {
      return rowBox;
    }
    return _buildRowReorderTarget(
      index: index,
      width: contentWidth,
      child: rowBox,
      feedback: _buildWholeRowFeedback(index, rowBox),
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
        final bodyViewportHeight = (constraints.maxHeight - widget.headerHeight)
          .clamp(0, double.infinity)
          .toDouble();
        final visibleRowCount = widget.rows.isEmpty
          ? (widget.showActionsWhenEmpty ? 1 : 0)
          : widget.rows.length;
        final rowAreaHeight = visibleRowCount * widget.rowHeight;
        final visibleBodyHeight = rowAreaHeight < bodyViewportHeight
          ? rowAreaHeight
          : bodyViewportHeight;
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
                  _buildRowNumberList(widths),
                  Expanded(
                    child: MouseRegion(
                      cursor: _draggingIndex != null
                          ? SystemMouseCursors.resizeLeftRight
                          : MouseCursor.defer,
                      child: _TableBodyTooltip(
                        message: widget.rowTooltip,
                        visibleBodyHeight: visibleBodyHeight,
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
  const _TableBodyTooltip({
    required this.message,
    required this.visibleBodyHeight,
    required this.child,
  });

  final String? message;
  final double visibleBodyHeight;
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
      _scheduleTooltip();
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
    if (!_isWithinVisibleBody(event.localPosition)) {
      _hideTooltip();
      return;
    }
    _cursorGlobalPosition = event.position;
    _entry?.markNeedsBuild();
    _scheduleTooltip();
  }

  bool _isWithinVisibleBody(Offset localPosition) {
    return widget.visibleBodyHeight > 0 &&
        localPosition.dy >= 0 &&
        localPosition.dy <= widget.visibleBodyHeight;
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
        if (!_isWithinVisibleBody(event.localPosition)) {
          return;
        }
        _cursorGlobalPosition = event.position;
        _scheduleTooltip();
      },
      onHover: _updateCursorPosition,
      onExit: (_) => _hideTooltip(),
      child: widget.child,
    );
  }
}
