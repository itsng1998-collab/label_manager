import 'dart:async';

import 'package:flutter/material.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_special.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_label_sheet/label_sheet_page.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

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
          _CommonLabelTable.tableWidthFor(context, specialColumns),
          _CommonLabelTable.tableWidthFor(context, columns),
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
                  child: LabelSheetPage(
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

class _CommonLabelTable extends StatelessWidget {
  final List<TColumnBase> columns;
  const _CommonLabelTable({required this.columns});

  static const List<double> _baseWidths = [110, 140, 70];
  static const List<String> _baseHeaders = ['키워드', '이름', '필수등록'];
  static const double _rowNumberWidth = 40;

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

  static String _headerTitle(int idx) => _baseHeaders[idx];

  static String _cellText(TColumnBase row, int idx) {
    if (idx == 0) return row.keyword;
    if (idx == 1) return row.columnName;
    if (idx == 2) return row.useMissingKeywordCheck ? '예' : '';
    return '';
  }

  static double _minWidth(int idx) => idx < _baseWidths.length ? 60.0 : 70.0;

  @override
  Widget build(BuildContext context) {
    return SwipeActionTable<TColumnBase>(
      rows: columns,
      columns: [
        for (var index = 0; index < _baseHeaders.length; index += 1)
          SwipeActionTableColumn<TColumnBase>(
            header: _headerTitle(index),
            initialWidth: _baseWidths[index],
            minWidth: _minWidth(index),
            text: (row) => _cellText(row, index),
            cellBuilder: index == 2
                ? (context, row, width) => SizedBox(
                    width: width,
                    child: StatefulBuilder(
                      builder: (context, setCellState) {
                        return Center(
                          child: Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: row.useMissingKeywordCheck,
                              onChanged: (value) {
                                setCellState(() {
                                  row.useMissingKeywordCheck = value ?? false;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : null,
          ),
      ],
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
