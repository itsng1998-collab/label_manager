import 'dart:math';
import 'package:flutter/material.dart';
import 'package:label_manager/core/ui_scale.dart';

/// 열 메타데이터
class ResizableTableColumn<T> {
  final String id;
  final String title;
  final double width;
  final double minWidth;
  final String Function(T row)? textAccessor;
  final Widget Function(BuildContext context, T row, int rowIndex)? cellBuilder;

  const ResizableTableColumn({
    required this.id,
    required this.title,
    required this.width,
    this.minWidth = 60,
    this.textAccessor,
    this.cellBuilder,
  });
}

/// 공통 리사이즈 가능 테이블
class ResizableTable<T> extends StatefulWidget {
  final List<T> rows;
  final List<ResizableTableColumn<T>> columns;
  final int? checkboxColumnIndex;
  final double rowNumberWidth;
  final double headerHeight;
  final double rowHeight;

  const ResizableTable({
    super.key,
    required this.rows,
    required this.columns,
    this.checkboxColumnIndex,
    this.rowNumberWidth = 40 * labelManagerUiScale,
    this.headerHeight = 36 * labelManagerUiScale,
    this.rowHeight = 28 * labelManagerUiScale,
  });

  @override
  State<ResizableTable<T>> createState() => _ResizableTableState<T>();
}

class _ResizableTableState<T> extends State<ResizableTable<T>> {
  static const Color _headerSeparatorColor = Color(0xFFBDBDBD);
  static const Color _bodySeparatorColor = Color(0xFFE6E8EB);

  late List<ResizableTableColumn<T>> _columns;
  late List<double> _widths;
  late List<bool> _checked;
  int? _draggingIndex;
  int? _selectedIndex;
  bool _syncingVertical = false;
  bool _syncingHorizontal = false;

  final ScrollController _hScrollHeader = ScrollController();
  final ScrollController _hScrollBody = ScrollController();
  final ScrollController _vScrollBody = ScrollController();
  final ScrollController _vScrollIndex = ScrollController();

  @override
  void initState() {
    super.initState();
    _columns = List<ResizableTableColumn<T>>.from(widget.columns);
    _widths = _buildWidths(_columns);
    _checked = List<bool>.filled(widget.rows.length, false);
    _hScrollBody.addListener(_syncHorizontalFromBody);
    _hScrollHeader.addListener(_syncHorizontalFromHeader);
    _vScrollBody.addListener(_syncVerticalScrollFromBody);
    _vScrollIndex.addListener(_syncVerticalScrollFromIndex);
  }

  @override
  void didUpdateWidget(covariant ResizableTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_columnsChanged(oldWidget.columns, widget.columns)) {
      _columns = List<ResizableTableColumn<T>>.from(widget.columns);
      _widths = _buildWidths(_columns);
    }
    if (oldWidget.rows.length != widget.rows.length) {
      _checked = List<bool>.filled(widget.rows.length, false);
    }
  }

  @override
  void dispose() {
    _hScrollHeader.dispose();
    _hScrollBody.dispose();
    _vScrollBody.dispose();
    _vScrollIndex.dispose();
    super.dispose();
  }

  bool _columnsChanged(
    List<ResizableTableColumn<T>> prev,
    List<ResizableTableColumn<T>> next,
  ) {
    if (prev.length != next.length) return true;
    for (var i = 0; i < prev.length; i++) {
      final a = prev[i];
      final b = next[i];
      if (a.id != b.id ||
          a.width != b.width ||
          a.minWidth != b.minWidth ||
          a.title != b.title) {
        return true;
      }
    }
    return false;
  }

  List<double> _buildWidths(List<ResizableTableColumn<T>> cols) {
    return cols
        .map((c) => max(c.width, c.minWidth))
        .toList(growable: false);
  }

  double _minWidth(int idx) => _columns[idx].minWidth;

  void _startResize(int index) {
    setState(() => _draggingIndex = index);
  }

  void _updateResize(DragUpdateDetails d) {
    final idx = _draggingIndex;
    if (idx == null) return;
    final minLeft = _minWidth(idx);
    final minRight = _minWidth(idx + 1);
    final delta = d.delta.dx;
    final left = (_widths[idx] + delta).clamp(minLeft, double.infinity);
    final right = (_widths[idx + 1] - delta).clamp(minRight, double.infinity);
    setState(() {
      _widths[idx] = left;
      _widths[idx + 1] = right;
    });
  }

  void _updateLastResize(DragUpdateDetails d) {
    final last = _widths.length - 1;
    setState(() {
      _widths[last] = (_widths[last] + d.delta.dx).clamp(
        _minWidth(last),
        double.infinity,
      );
    });
  }

  void _endResize() {
    setState(() => _draggingIndex = null);
  }

  void _autoFitColumn(int idx) {
    double measureText(String text, TextStyle style, TextScaler scaler) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      return tp.size.width;
    }

    final scaler = MediaQuery.of(context).textScaler;
    const style = TextStyle(fontSize: 14);
    double maxW = measureText(_columns[idx].title, style, scaler) + 16;
    final accessor = _columns[idx].textAccessor;
    if (accessor != null) {
      for (final row in widget.rows) {
        final val = accessor(row);
        maxW = max(maxW, measureText(val, style, scaler) + 16);
      }
    }
    maxW = max(maxW, _minWidth(idx));
    setState(() => _widths[idx] = maxW);
  }

  void _syncVerticalScrollFromBody() {
    if (_syncingVertical) return;
    if (!_vScrollBody.hasClients || !_vScrollIndex.hasClients) return;
    _syncingVertical = true;
    final target = _vScrollBody.offset.clamp(
      _vScrollIndex.position.minScrollExtent,
      _vScrollIndex.position.maxScrollExtent,
    );
    _vScrollIndex.jumpTo(target.toDouble());
    _syncingVertical = false;
  }

  void _syncVerticalScrollFromIndex() {
    if (_syncingVertical) return;
    if (!_vScrollIndex.hasClients || !_vScrollBody.hasClients) return;
    _syncingVertical = true;
    final target = _vScrollIndex.offset.clamp(
      _vScrollBody.position.minScrollExtent,
      _vScrollBody.position.maxScrollExtent,
    );
    _vScrollBody.jumpTo(target.toDouble());
    _syncingVertical = false;
  }

  void _syncHorizontalFromBody() {
    if (_syncingHorizontal) return;
    if (!_hScrollBody.hasClients || !_hScrollHeader.hasClients) return;
    _syncingHorizontal = true;
    final target = _hScrollBody.offset.clamp(
      _hScrollHeader.position.minScrollExtent,
      _hScrollHeader.position.maxScrollExtent,
    );
    _hScrollHeader.jumpTo(target.toDouble());
    _syncingHorizontal = false;
  }

  void _syncHorizontalFromHeader() {
    if (_syncingHorizontal) return;
    if (!_hScrollHeader.hasClients || !_hScrollBody.hasClients) return;
    _syncingHorizontal = true;
    final target = _hScrollHeader.offset.clamp(
      _hScrollBody.position.minScrollExtent,
      _hScrollBody.position.maxScrollExtent,
    );
    _hScrollBody.jumpTo(target.toDouble());
    _syncingHorizontal = false;
  }

  Widget _buildHeader() {
    const double handleWidth = 4.0;
    final lastIndex = _widths.length - 1;
    return Container(
      color: const Color(0xFF0E2F66),
      height: widget.headerHeight,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(_widths.length, (i) {
          final isLast = i == lastIndex;
          final cell = SizedBox(
            width: _widths[i],
            child: Center(
              child: Text(
                _columns[i].title,
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
                    onHorizontalDragStart: (_) => _startResize(i),
                    onHorizontalDragUpdate: isLast
                        ? _updateLastResize
                        : _updateResize,
                    onHorizontalDragEnd: (_) => _endResize(),
                    onDoubleTap: () => _autoFitColumn(i),
                    child: SizedBox(
                      width: handleWidth,
                      child: Container(
                        width: 1,
                        height: double.infinity,
                        color: isLast
                            ? Colors.transparent
                            : _headerSeparatorColor,
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
      decoration: BoxDecoration(
        color: const Color(0xFF0E2F66),
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
        itemBuilder: (context, index) {
          return Container(
            height: widget.rowHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF0E2F66),
              border: Border(
                right: BorderSide(color: _bodySeparatorColor),
                top: const BorderSide(color: Color(0xFFE6E8EB)),
                bottom: const BorderSide(color: Color(0xFFE6E8EB)),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCell(int columnIndex, T row, int rowIndex) {
    final col = _columns[columnIndex];
    final isCheckbox = widget.checkboxColumnIndex != null &&
        widget.checkboxColumnIndex == columnIndex;

    if (isCheckbox) {
      return Transform.scale(
        scale: 0.9,
        child: Checkbox(
          value: _checked[rowIndex],
          onChanged: (v) =>
              setState(() => _checked[rowIndex] = v ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (col.cellBuilder != null) {
      return col.cellBuilder!(context, row, rowIndex);
    }

    final text = col.textAccessor?.call(row) ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_columns.isEmpty) return const SizedBox.shrink();
    final contentWidth = _widths.reduce((a, b) => a + b);
    final separators = List<double>.generate(
      _widths.length - 1,
      (i) => _widths.sublist(0, i + 1).reduce((a, b) => a + b),
    );

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
                  child: SizedBox(width: contentWidth, child: _buildHeader()),
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
                  child: Scrollbar(
                    controller: _hScrollBody,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _hScrollBody,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentWidth,
                        child: ListView.builder(
                          controller: _vScrollBody,
                          itemCount: widget.rows.length,
                          itemBuilder: (context, index) {
                            final row = widget.rows[index];
                            return SizedBox(
                              height: widget.rowHeight,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _selectedIndex == index
                                          ? const Color(0xFFE3F2FD)
                                          : (index.isEven
                                                ? Colors.white
                                                : const Color(0xFFF2F4F7)),
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE6E8EB),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: List.generate(
                                        _columns.length,
                                        (colIdx) => SizedBox(
                                          width: _widths[colIdx],
                                          child: _buildCell(
                                            colIdx,
                                            row,
                                            index,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...separators.map(
                                    (x) => Positioned(
                                      left: x - 1,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 1,
                                        color: _bodySeparatorColor,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    left: _widths.first,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        hoverColor: Colors.transparent,
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () => setState(
                                          () => _selectedIndex = index,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
  }
}
