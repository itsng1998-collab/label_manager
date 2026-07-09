import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class FortuneTableCheckboxController extends ChangeNotifier {
  final Map<String, Set<int>> _checkedRowsByColumn = <String, Set<int>>{};

  bool isChecked(String columnId, int rowIndex) {
    return _checkedRowsByColumn[columnId]?.contains(rowIndex) ?? false;
  }

  Set<int> checkedRows(String columnId) {
    return Set<int>.unmodifiable(_checkedRowsByColumn[columnId] ?? const <int>{});
  }

  void setChecked(String columnId, int rowIndex, bool checked) {
    final rows = _checkedRowsByColumn.putIfAbsent(columnId, () => <int>{});
    final changed = checked ? rows.add(rowIndex) : rows.remove(rowIndex);
    if (!changed) return;
    if (rows.isEmpty) {
      _checkedRowsByColumn.remove(columnId);
    }
    notifyListeners();
  }

  void toggleChecked(String columnId, int rowIndex) {
    setChecked(columnId, rowIndex, !isChecked(columnId, rowIndex));
  }

  void setCheckedRows(String columnId, Iterable<int> rowIndexes) {
    final nextRows = rowIndexes.toSet();
    final currentRows = _checkedRowsByColumn[columnId] ?? const <int>{};
    if (currentRows.length == nextRows.length &&
        currentRows.every(nextRows.contains)) {
      return;
    }
    if (nextRows.isEmpty) {
      _checkedRowsByColumn.remove(columnId);
    } else {
      _checkedRowsByColumn[columnId] = nextRows;
    }
    notifyListeners();
  }

  void clearColumn(String columnId) {
    if (_checkedRowsByColumn.remove(columnId) == null) return;
    notifyListeners();
  }

  void clear() {
    if (_checkedRowsByColumn.isEmpty) return;
    _checkedRowsByColumn.clear();
    notifyListeners();
  }
}

class FortuneTableColumn<T> {
  const FortuneTableColumn({
    required this.id,
    required this.header,
    required this.text,
    this.initialWidth = 120,
    this.minWidth = 60,
    this.checkboxValue,
    this.checkboxValueAt,
    this.checkboxController,
    this.onCheckboxChanged,
    this.onCheckboxChangedAt,
    this.fillRemaining = false,
  });

  final String id;
  final String header;
  final String Function(T row) text;
  final double initialWidth;
  final double minWidth;
  final bool Function(T row)? checkboxValue;
  final bool Function(T row, int rowIndex)? checkboxValueAt;
    final FortuneTableCheckboxController? checkboxController;
  final void Function(T row, bool value)? onCheckboxChanged;
  final void Function(T row, int rowIndex, bool value)? onCheckboxChangedAt;
  final bool fillRemaining;

  bool get isCheckbox =>
      checkboxValue != null ||
      checkboxValueAt != null ||
      checkboxController != null ||
      onCheckboxChanged != null ||
      onCheckboxChangedAt != null;
}

class FortuneTable<T> extends StatefulWidget {
  const FortuneTable({
    super.key,
    required this.rows,
    required this.columns,
    this.selectedIndex,
    this.onRowSelected,
    this.onRectChanged,
    this.rowNumberWidth = 40,
    this.headerHeight = 36,
    this.rowHeight = 28,
    this.autoFitColumns = true,
    this.fillLastColumn = false,
    this.dragScrollEnabled = true,
  });

  final List<T> rows;
  final List<FortuneTableColumn<T>> columns;
  final int? selectedIndex;
  final void Function(T row, int index)? onRowSelected;
  final ValueChanged<Rect>? onRectChanged;
  final double rowNumberWidth;
  final double headerHeight;
  final double rowHeight;
  final bool autoFitColumns;
  final bool fillLastColumn;
  final bool dragScrollEnabled;

  @override
  State<FortuneTable<T>> createState() => _FortuneTableState<T>();
}

class _FortuneTableScrollBehavior extends MaterialScrollBehavior {
  const _FortuneTableScrollBehavior({required this.dragScrollEnabled});

  final bool dragScrollEnabled;

  @override
  Set<PointerDeviceKind> get dragDevices {
    if (!dragScrollEnabled) {
      return super.dragDevices;
    }
    return {
      ...super.dragDevices,
      PointerDeviceKind.mouse,
      PointerDeviceKind.touch,
    };
  }
}

class _FortuneTableState<T> extends State<FortuneTable<T>> {
  static const Color _headerColor = Color(0xFF0E2F66);
  static const Color _headerSeparatorColor = Color(0xFFBDBDBD);
  static const Color _bodySeparatorColor = Color(0xFFE6E8EB);
  static const Color _selectedRowColor = Color(0xFFE3F2FD);
  static const Color _alternateRowColor = Color(0xFFF2F4F7);
  static const Color _checkboxBorderColor = Color(0xffb7b7b7);
  static const Color _checkboxCheckColor = Color(0xff0188fb);
  static const double _checkboxSize = 13.0;

  final ScrollController _hScrollHeader = ScrollController();
  final ScrollController _hScrollBody = ScrollController();
  final ScrollController _vScrollBody = ScrollController();
  final ScrollController _vScrollIndex = ScrollController();
  bool _syncingHorizontal = false;
  bool _syncingVertical = false;
  late List<double> _widths;
  Set<FortuneTableCheckboxController> _checkboxControllers =
      <FortuneTableCheckboxController>{};
  int? _selectedIndex;
  Rect? _lastReportedRect;
  String? _tableSignature;

  @override
  void initState() {
    super.initState();
    _widths = _initialWidths();
    _selectedIndex = widget.selectedIndex;
    _syncCheckboxControllerListeners(<FortuneTableColumn<T>>[]);
    _hScrollBody.addListener(_syncHorizontalFromBody);
    _hScrollHeader.addListener(_syncHorizontalFromHeader);
    _vScrollBody.addListener(_syncVerticalFromBody);
    _vScrollIndex.addListener(_syncVerticalFromIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoWidthsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FortuneTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns.length != widget.columns.length ||
        _initialWidthsChanged(oldWidget.columns, widget.columns)) {
      _widths = _initialWidths();
      _tableSignature = null;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if ((_selectedIndex ?? -1) >= widget.rows.length) {
      _selectedIndex = null;
    }
    _syncCheckboxControllerListeners(oldWidget.columns);
    _syncAutoWidthsIfNeeded();
  }

  @override
  void dispose() {
    for (final controller in _checkboxControllers) {
      controller.removeListener(_handleCheckboxControllerChanged);
    }
    _hScrollHeader.dispose();
    _hScrollBody.dispose();
    _vScrollBody.dispose();
    _vScrollIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRectReport();
    return LayoutBuilder(
      builder: (context, constraints) {
        final widths = _effectiveWidths(constraints.maxWidth);
        final bodyWidth = widths.fold<double>(0, (sum, width) => sum + width);
        final horizontalViewportWidth = (constraints.maxWidth -
            widget.rowNumberWidth)
          .clamp(0, double.infinity)
          .toDouble();
        final bodyViewportHeight = (constraints.maxHeight - widget.headerHeight)
          .clamp(0, double.infinity)
          .toDouble();
        final hasHorizontalOverflow =
          bodyWidth > horizontalViewportWidth + 0.5;
        final hasVerticalOverflow =
          widget.rows.length * widget.rowHeight > bodyViewportHeight + 0.5;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerSignal: _handlePointerSignal,
          onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    _rowHeaderCell('', _headerColor, widget.headerHeight),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _hScrollHeader,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: bodyWidth,
                          height: widget.headerHeight,
                          child: _buildHeader(widths),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: widget.rowNumberWidth,
                        child: ScrollConfiguration(
                          behavior: const _FortuneTableScrollBehavior(
                            dragScrollEnabled: false,
                          ),
                          child: ListView.builder(
                            controller: _vScrollIndex,
                            itemExtent: widget.rowHeight,
                            itemCount: widget.rows.length,
                            itemBuilder: (context, index) =>
                                _scrollSignalBoundary(
                              _rowHeaderCell(
                                '${index + 1}',
                                _headerColor,
                                widget.rowHeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: _FortuneTableScrollBehavior(
                            dragScrollEnabled: widget.dragScrollEnabled,
                          ),
                          child: RawScrollbar(
                            controller: _vScrollBody,
                            thumbVisibility: hasVerticalOverflow,
                            thickness: 8,
                            radius: Radius.zero,
                            notificationPredicate: (notification) =>
                                notification.metrics.axis == Axis.vertical,
                            child: RawScrollbar(
                              controller: _hScrollBody,
                              thumbVisibility: hasHorizontalOverflow,
                              thickness: 8,
                              radius: Radius.zero,
                              notificationPredicate: (notification) =>
                                  notification.metrics.axis == Axis.horizontal,
                              child: SingleChildScrollView(
                                controller: _hScrollBody,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: bodyWidth,
                                  child: ListView.builder(
                                    controller: _vScrollBody,
                                    itemExtent: widget.rowHeight,
                                    itemCount: widget.rows.length,
                                    itemBuilder: (context, rowIndex) =>
                                        _scrollSignalBoundary(
                                      _buildRow(
                                        widget.rows[rowIndex],
                                        rowIndex,
                                        widths,
                                      ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _scrollSignalBoundary(Widget child) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerSignal,
      onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
      child: child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      if (event is PointerScrollEvent) {
        _handlePointerScroll(event.scrollDelta);
      }
    });
  }

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    _handlePointerScroll(event.panDelta);
  }

  void _handlePointerScroll(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      _jumpBy(_hScrollBody, delta.dx);
      return;
    }
    _jumpBy(_vScrollBody, delta.dy);
  }

  void _jumpBy(ScrollController controller, double delta) {
    if (!controller.hasClients || delta == 0) return;
    final position = controller.position;
    controller.jumpTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  List<double> _initialWidths() {
    return [
      for (final column in widget.columns)
        math.max(column.initialWidth, column.minWidth),
    ];
  }

  bool _initialWidthsChanged(
    List<FortuneTableColumn<T>> oldColumns,
    List<FortuneTableColumn<T>> newColumns,
  ) {
    for (var index = 0; index < oldColumns.length; index += 1) {
      if (oldColumns[index].initialWidth != newColumns[index].initialWidth ||
          oldColumns[index].minWidth != newColumns[index].minWidth ||
          oldColumns[index].fillRemaining != newColumns[index].fillRemaining) {
        return true;
      }
    }
    return false;
  }

  void _syncAutoWidthsIfNeeded() {
    if (!widget.autoFitColumns || widget.columns.isEmpty) return;
    final signature = _autoFitSignature();
    if (_tableSignature == signature) return;
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
        if (width > maxWidth) maxWidth = width;
      }
      return maxWidth < column.minWidth ? column.minWidth : maxWidth;
    });
  }

  double _measureText(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.size.width;
  }

  List<double> _effectiveWidths(double viewportWidth) {
    final widths = List<double>.from(_widths);
    if (widths.isEmpty) return widths;
    final fillIndex = widget.columns.lastIndexWhere(
      (column) => column.fillRemaining,
    );
    final targetIndex = fillIndex >= 0
        ? fillIndex
        : (widget.fillLastColumn ? widths.length - 1 : -1);
    if (targetIndex < 0) return widths;
    final reserved = widget.rowNumberWidth +
        widths.asMap().entries.fold<double>(
          0,
          (sum, entry) => entry.key == targetIndex ? sum : sum + entry.value,
        );
    final remaining = viewportWidth - reserved;
    if (remaining > widths[targetIndex]) widths[targetIndex] = remaining;
    return widths;
  }

  Widget _buildHeader(List<double> widths) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widths.length, (index) {
        return Container(
          width: widths[index],
          decoration: const BoxDecoration(
            color: _headerColor,
            border: Border(
              right: BorderSide(color: _headerSeparatorColor),
              bottom: BorderSide(color: _headerSeparatorColor),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            widget.columns[index].header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRow(T row, int rowIndex, List<double> widths) {
    final selected = _selectedIndex == rowIndex;
    final color = _rowColor(rowIndex, selected);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _selectRow(row, rowIndex),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(widths.length, (columnIndex) {
          return _buildCell(row, rowIndex, columnIndex, widths[columnIndex], color);
        }),
      ),
    );
  }

  Widget _buildCell(
    T row,
    int rowIndex,
    int columnIndex,
    double width,
    Color color,
  ) {
    final column = widget.columns[columnIndex];
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          right: BorderSide(color: _bodySeparatorColor),
          bottom: BorderSide(color: _bodySeparatorColor),
        ),
      ),
      alignment: column.isCheckbox ? Alignment.center : Alignment.centerLeft,
      padding: column.isCheckbox
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8),
      child: column.isCheckbox
          ? _FortuneTableCheckbox(
              key: ValueKey('fortune_table_checkbox_${column.id}_$rowIndex'),
              value: column.checkboxController?.isChecked(column.id, rowIndex) ??
                  column.checkboxValueAt?.call(row, rowIndex) ??
                  column.checkboxValue?.call(row) ??
                  false,
              onChanged: (value) {
                _selectRow(row, rowIndex);
                column.checkboxController?.setChecked(
                  column.id,
                  rowIndex,
                  value,
                );
                final onCheckboxChangedAt = column.onCheckboxChangedAt;
                if (onCheckboxChangedAt != null) {
                  onCheckboxChangedAt(row, rowIndex, value);
                } else {
                  column.onCheckboxChanged?.call(row, value);
                }
              },
            )
          : Text(
              column.text(row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF202124)),
            ),
    );
  }

  Widget _rowHeaderCell(String text, Color color, double height) {
    return Container(
      width: widget.rowNumberWidth,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          right: BorderSide(color: _headerSeparatorColor),
          bottom: BorderSide(color: _bodySeparatorColor),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Color _rowColor(int rowIndex, bool selected) {
    if (selected) return _selectedRowColor;
    return rowIndex.isEven ? Colors.white : _alternateRowColor;
  }

  void _selectRow(T row, int rowIndex) {
    if (_selectedIndex != rowIndex) {
      setState(() => _selectedIndex = rowIndex);
    }
    widget.onRowSelected?.call(row, rowIndex);
  }

  void _syncCheckboxControllerListeners(
    List<FortuneTableColumn<T>> oldColumns,
  ) {
    final nextControllers = widget.columns
        .map((column) => column.checkboxController)
        .whereType<FortuneTableCheckboxController>()
        .toSet();
    final oldControllers = oldColumns
        .map((column) => column.checkboxController)
        .whereType<FortuneTableCheckboxController>()
        .toSet();

    for (final controller in oldControllers.difference(nextControllers)) {
      controller.removeListener(_handleCheckboxControllerChanged);
    }
    for (final controller in nextControllers.difference(_checkboxControllers)) {
      controller.addListener(_handleCheckboxControllerChanged);
    }
    _checkboxControllers = nextControllers;
  }

  void _handleCheckboxControllerChanged() {
    if (!mounted) return;
    setState(() {});
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
    if (!_hScrollBody.hasClients || !_hScrollHeader.hasClients) return;
    _syncingHorizontal = true;
    _hScrollBody.jumpTo(
      _hScrollHeader.offset.clamp(
        _hScrollBody.position.minScrollExtent,
        _hScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  void _syncVerticalFromBody() {
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

  void _syncVerticalFromIndex() {
    if (_syncingVertical) return;
    if (!_vScrollBody.hasClients || !_vScrollIndex.hasClients) return;
    _syncingVertical = true;
    _vScrollBody.jumpTo(
      _vScrollIndex.offset.clamp(
        _vScrollBody.position.minScrollExtent,
        _vScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingVertical = false;
  }

  void _scheduleRectReport() {
    if (widget.onRectChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.onRectChanged == null) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final last = _lastReportedRect;
      if (last != null && _sameRect(last, rect)) return;
      _lastReportedRect = rect;
      widget.onRectChanged?.call(rect);
    });
  }

  bool _sameRect(Rect left, Rect right) {
    return (left.left - right.left).abs() < 0.5 &&
        (left.top - right.top).abs() < 0.5 &&
        (left.width - right.width).abs() < 0.5 &&
        (left.height - right.height).abs() < 0.5;
  }
}

class _FortuneTableCheckbox extends StatelessWidget {
  const _FortuneTableCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox.square(
        dimension: _FortuneTableState._checkboxSize + 10,
        child: Center(
          child: CustomPaint(
            size: const Size.square(_FortuneTableState._checkboxSize),
            painter: _FortuneTableCheckboxPainter(value),
          ),
        ),
      ),
    );
  }
}

class _FortuneTableCheckboxPainter extends CustomPainter {
  const _FortuneTableCheckboxPainter(this.checked);

  final bool checked;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(
      rect.deflate(0.5),
      Paint()
        ..color = _FortuneTableState._checkboxBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (!checked) return;
    final path = Path()
      ..moveTo(rect.left + 3, rect.center.dy)
      ..lineTo(rect.left + 5.5, rect.bottom - 3)
      ..lineTo(rect.right - 3, rect.top + 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = _FortuneTableState._checkboxCheckColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FortuneTableCheckboxPainter oldDelegate) {
    return oldDelegate.checked != checked;
  }
}