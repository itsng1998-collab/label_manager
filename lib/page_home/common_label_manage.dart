import 'dart:async';

import 'package:flutter/material.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_special.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_fortune_sheet/fortune_sheet_page.dart';
import 'package:label_manager/utils/log_context.dart';

@visibleForTesting
List<String> commonLabelBarcodeObjectIdsFor(
  List<TColumnBase> specialColumns,
  List<TColumn> columns,
) {
  final result = <String>[];
  final seen = <String>{};
  for (final column in [...specialColumns, ...columns]) {
    final keyword = column.keyword.trim();
    final lower = keyword.toLowerCase();
    if (keyword.isEmpty ||
        (!lower.contains('barcode') && !lower.contains('qrcode'))) {
      continue;
    }
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (seen.add(objectId.toLowerCase())) {
      result.add(objectId);
    }
  }
  return result.isEmpty ? const ['#BARCODE'] : result;
}

class CommonLabelManage extends StatefulWidget {
  final String title;
  final LabelSize? labelSize;
  final VoidCallback? onSheetReady;
  final ValueChanged<Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;
  const CommonLabelManage({
    super.key,
    required this.title,
    this.labelSize,
    this.onSheetReady,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
  });

  @override
  State<CommonLabelManage> createState() => _CommonLabelManageState();
}

class _CommonLabelManageState extends State<CommonLabelManage> {
  // 초기 분할: 좌측이 더 넓게(우측 약 40%)
  double _rightFraction = 0.2;
  bool _rightWidthChangedByUser = false;
  static const double _handleWidth = 8;

  @override
  Widget build(BuildContext context) {
    debugLog(
      'labelSizeId=${widget.labelSize?.labelSizeId}, '
      'specials=${TColumnSpecial.datas?.length ?? 0}, '
      'columns=${TColumn.datas?.length ?? 0}',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final minLeft = totalWidth * (4 / 7); // 좌측 최소 4/7 비율(≈4:3)
        final minRight = 160.0; // 우측이 0이 되지 않도록 기본 여유
        final maxRight = totalWidth - minLeft - _handleWidth;
        final rightLower = maxRight < minRight ? maxRight : minRight;
        final columns = TColumn.datas ?? const <TColumn>[];
        final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
        final barcodeObjectIds = commonLabelBarcodeObjectIdsFor(
          specialColumns,
          columns,
        );
        final fitRightWidth = [
          _CommonLabelTableState.tableWidthFor(context, specialColumns),
          _CommonLabelTableState.tableWidthFor(context, columns),
          minRight,
        ].reduce((a, b) => a > b ? a : b).clamp(rightLower, maxRight);

        // 우측 폭 계산 및 하한선 적용
        final double rightWidth;
        if (_rightWidthChangedByUser) {
          rightWidth = (totalWidth * _rightFraction)
              .clamp(rightLower, maxRight)
              .toDouble();
        } else {
          rightWidth = fitRightWidth.toDouble();
        }
        final leftWidth = totalWidth - rightWidth - _handleWidth;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftWidth,
              child: _Pane(
                title: '${widget.title} - 좌측',
                icon: Icons.folder_open,
                hideHeader: true,
                child: ClipRect(
                  child: FortuneSheetPage(
                    labelSize: widget.labelSize,
                    barcodeObjectIds: barcodeObjectIds,
                    onSheetReady: widget.onSheetReady,
                    onGridRectChanged: widget.onGridRectChanged,
                    onBeforeSheetDialog: widget.onBeforeSheetDialog,
                    onSheetDialogClosed: widget.onSheetDialogClosed,
                  ),
                ),
              ),
            ),
            _Splitter(
              width: _handleWidth,
              onDrag: (dx) {
                setState(() {
                  final currentRight = _rightWidthChangedByUser
                      ? totalWidth * _rightFraction
                      : rightWidth;
                  final nextRight = (currentRight - dx).clamp(
                    rightLower,
                    maxRight,
                  );
                  _rightWidthChangedByUser = true;
                  _rightFraction = nextRight / totalWidth;
                });
              },
            ),
            SizedBox(
              width: rightWidth,
              child: _RightPane(
                title: '${widget.title} - 우측',
                columns: specialColumns,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RightPane extends StatefulWidget {
  final String title;
  final List<TColumnBase> columns;
  const _RightPane({required this.title, required this.columns});

  @override
  State<_RightPane> createState() => _RightPaneState();
}

class _RightPaneState extends State<_RightPane> {
  static const double _handleHeight = 8.0;
  double _topFraction = 0.3;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        const double minTop = 120;
        const double minBottom = 100;

        var topHeight = totalHeight * _topFraction;
        topHeight = topHeight.clamp(
          minTop,
          totalHeight - minBottom - _handleHeight,
        );
        final bottomHeight = totalHeight - topHeight - _handleHeight;

        return Column(
          children: [
            _Pane(
              title: '특별 항목',
              icon: Icons.checklist,
              height: topHeight,
              child: _CommonLabelTable(columns: widget.columns),
            ),
            _HSplitter(
              height: _handleHeight,
              onDrag: (dy) {
                setState(() {
                  final currentTop = totalHeight * _topFraction;
                  final nextTop = (currentTop + dy).clamp(
                    minTop,
                    totalHeight - minBottom - _handleHeight,
                  );
                  _topFraction = nextTop / totalHeight;
                });
              },
            ),
            _Pane(
              title: '사용 항목',
              icon: Icons.checklist,
              height: bottomHeight,
              action: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('항목 편집'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              child: _CommonLabelTable(
                columns: List<TColumnBase>.from(TColumn.datas ?? const []),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommonLabelTable extends StatefulWidget {
  final List<TColumnBase> columns;
  const _CommonLabelTable({required this.columns});

  @override
  State<_CommonLabelTable> createState() => _CommonLabelTableState();
}

class _CommonLabelTableState extends State<_CommonLabelTable> {
  static const List<double> _baseWidths = [110, 140, 70];
  static const List<String> _baseHeaders = ['키워드', '이름', '필수등록'];
  static const Color _headerSeparatorColor = Color(0xFFBDBDBD);
  static const Color _bodySeparatorColor = Color(0xFFE6E8EB);
  static const double _headerHeight = 36;
  static const double _rowHeight = 28;
  static const double _rowNumberWidth = 40;

  final ScrollController _hScrollHeader = ScrollController();
  final ScrollController _hScrollBody = ScrollController();
  final ScrollController _vScrollBody = ScrollController();
  final ScrollController _vScrollIndex = ScrollController();
  bool _syncingVertical = false;
  bool _syncingHorizontal = false;
  late List<double> _widths;
  int? _draggingIndex;
  int? _selectedIndex;
  String? _columnsSignature;

  @override
  void initState() {
    super.initState();
    _widths = List<double>.from(_baseWidths);
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
  void didUpdateWidget(covariant _CommonLabelTable oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _syncAutoWidthsIfNeeded() {
    final signature = _columnsAutoFitSignature();
    if (_columnsSignature == signature) {
      return;
    }
    _columnsSignature = signature;
    _widths = _autoFitWidths();
  }

  String _columnsAutoFitSignature() {
    return widget.columns
        .map(
          (column) =>
              '${column.keyword}\u001f${column.columnName}\u001f${column.useMissingKeywordCheck}',
        )
        .join('\u001e');
  }

  List<double> _autoFitWidths() {
    final scaler = MediaQuery.of(context).textScaler;
    return List<double>.generate(
      _baseHeaders.length,
      (index) => _autoFitWidth(index, scaler),
    );
  }

  double _autoFitWidth(int index, TextScaler scaler) {
    return autoFitWidth(index, widget.columns, scaler);
  }

  static double tableWidthFor(BuildContext context, List<TColumnBase> columns) {
    final scaler = MediaQuery.of(context).textScaler;
    return _rowNumberWidth +
        List<double>.generate(
          _baseHeaders.length,
          (index) => autoFitWidth(index, columns, scaler),
        ).reduce((a, b) => a + b);
  }

  static double autoFitWidth(
    int index,
    List<TColumnBase> columns,
    TextScaler scaler,
  ) {
    const style = TextStyle(fontSize: 14);
    var maxWidth = _measureText(_headerTitle(index), style, scaler) + 24;
    for (final row in columns) {
      final text = _cellText(row, index);
      maxWidth = maxWidth > _measureText(text, style, scaler) + 24
          ? maxWidth
          : _measureText(text, style, scaler) + 24;
    }
    return maxWidth < _minWidth(index) ? _minWidth(index) : maxWidth;
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

  void _autoFitColumn(int idx) {
    final scaler = MediaQuery.of(context).textScaler;
    setState(() => _widths[idx] = _autoFitWidth(idx, scaler));
  }

  static String _headerTitle(int idx) => _baseHeaders[idx];

  static String _cellText(TColumnBase row, int idx) {
    if (idx == 0) return row.keyword;
    if (idx == 1) return row.columnName;
    if (idx == 2) return row.useMissingKeywordCheck ? '예' : '';
    return '';
  }

  static double _minWidth(int idx) => idx < _baseWidths.length ? 60.0 : 70.0;

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
      height: _headerHeight,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(_widths.length, (i) {
          final isLast = i == lastIndex;
          final cell = SizedBox(
            width: _widths[i],
            child: Center(
              child: Text(
                _headerTitle(i),
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
      width: _rowNumberWidth,
      height: _headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0E2F66),
        border: Border(right: BorderSide(color: _headerSeparatorColor)),
      ),
    );
  }

  Widget _buildRowNumberList() {
    return SizedBox(
      width: _rowNumberWidth,
      child: ListView.builder(
        controller: _vScrollIndex,
        itemCount: widget.columns.length,
        itemBuilder: (context, index) {
          return Container(
            height: _rowHeight,
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

  Widget _buildCell(TColumnBase row, int idx) {
    if (idx == 2) {
      return SizedBox(
        width: _widths[idx],
        child: Center(
          child: Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: row.useMissingKeywordCheck,
              onChanged: (v) {
                setState(() {
                  row.useMissingKeywordCheck = v ?? false;
                });
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      );
    }
    return _BodyCell(text: _cellText(row, idx), width: _widths[idx]);
  }

  @override
  Widget build(BuildContext context) {
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
                          itemCount: widget.columns.length,
                          itemBuilder: (context, index) {
                            final row = widget.columns[index];
                            return SizedBox(
                              height: _rowHeight,
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
                                        _baseHeaders.length,
                                        (i) => _buildCell(row, i),
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
                                    right: _widths.last,
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

class _BodyCell extends StatelessWidget {
  final String text;
  final double width;
  const _BodyCell({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final double? height;
  final bool hideHeader;
  final Widget? action;
  const _Pane({
    required this.title,
    required this.icon,
    required this.child,
    this.height,
    this.hideHeader = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hideHeader)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (action != null) ...[const SizedBox(width: 8), action!],
                  ],
                ),
              ),
            Expanded(child: ClipRect(child: child)),
          ],
        ),
      ),
    );
  }
}

class _HSplitter extends StatelessWidget {
  final double height;
  final ValueChanged<double> onDrag;
  const _HSplitter({required this.height, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 2,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Splitter extends StatelessWidget {
  final double width;
  final ValueChanged<double> onDrag;
  const _Splitter({required this.width, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
