import 'dart:async';

import 'package:flutter/material.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/features/label_sheet/application/common_label_connections.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/application/special_columns.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_barcode_renderer.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_page.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/utils/log_context.dart';

const double commonLabelRightPaneInitialWidth = 350.0;
const double commonLabelRightPaneMinWidth = 350.0;
const double commonLabelRowNumberWidth = 40.0;
const double commonLabelRequiredColumnWidth = 70.0;
const double _commonLabelFlexibleColumnMinWidth = 60.0;

@visibleForTesting
List<LabelRequiredCheckSave> commonLabelRequiredCheckSaves(
  List<TColumnBase> specialColumns,
  List<TColumn> columns,
) {
  final specialIdByKeyword = <String, int>{
    for (final value in SpecalKeyword.values)
      value.keyword.toUpperCase(): -(value.code + 1),
  };
  return <LabelRequiredCheckSave>[
    for (final column in specialColumns)
      (
        columnId: specialIdByKeyword[column.keyword.toUpperCase()]!,
        keyword: column.keyword,
        columnName: column.columnName,
        checked: column.useMissingKeywordCheck,
      ),
    for (final column in columns)
      (
        columnId: column.columnId,
        keyword: column.keyword,
        columnName: column.columnName,
        checked: column.useMissingKeywordCheck,
      ),
  ];
}

@visibleForTesting
List<double> commonLabelColumnWidthsForViewport(double viewportWidth) {
  final remainingWidth =
      viewportWidth - commonLabelRowNumberWidth - commonLabelRequiredColumnWidth;
  final flexibleWidth = remainingWidth / 2 < _commonLabelFlexibleColumnMinWidth
      ? _commonLabelFlexibleColumnMinWidth
      : remainingWidth / 2;
  return [flexibleWidth, flexibleWidth, commonLabelRequiredColumnWidth];
}

List<FortuneObjectConnectionOption> commonLabelBarcodeObjectOptionsFromColumns(
  Iterable<TColumnBase> columns,
) {
  final result = <FortuneObjectConnectionOption>[];
  final seen = <String>{};
  for (final column in columns) {
    if (column is! TColumn) continue;
    final typeCode = column.columnType.code;
    if (typeCode != TColumnType.TYPE_BARCODE &&
        typeCode != TColumnType.TYPE_QR_CODE &&
        typeCode != TColumnType.TYPE_GS1_BARCODE) {
      continue;
    }
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) continue;
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (!seen.add(objectId.toLowerCase())) continue;
    final formatId = _columnBarcodeFormatId(column);
    final formatLabel = labelSheetBarcodeFormats
        .where((format) => format.id == formatId)
        .map((format) => format.label)
        .firstOrNull;
    final name = column.columnName.trim().isEmpty
        ? keyword
        : column.columnName.trim();
    result.add(
      FortuneObjectConnectionOption(
        value: objectId,
        label: '$name ($objectId) · ${formatLabel ?? formatId}',
        formatId: formatId,
        formatLabel: formatLabel ?? formatId,
        showHumanReadableText: column.showBarcodeNum,
      ),
    );
  }
  return result;
}

String _columnBarcodeFormatId(TColumn column) {
  if (column.columnType.code == TColumnType.TYPE_QR_CODE &&
      column.barcodeType != BarcodeType.QrCode &&
      column.barcodeType != BarcodeType.MicroQrCode &&
      column.barcodeType != BarcodeType.DataMatrix) {
    return 'qrCode';
  }
  return switch (column.barcodeType) {
    BarcodeType.CodeEAN13 => 'ean13',
    BarcodeType.Code128 => 'code128',
    BarcodeType.Itf => 'itf',
    BarcodeType.DataMatrix => 'dataMatrix',
    BarcodeType.Code39 => 'code39',
    BarcodeType.QrCode => 'qrCode',
    BarcodeType.MicroQrCode => 'microQRCode',
    BarcodeType.UpcA => 'upca',
    BarcodeType.Code93 => 'code93',
    BarcodeType.CodeEAN8 => 'ean8',
  };
}

List<FortuneObjectConnectionOption> commonLabelImageObjectOptionsFromColumns(
  Iterable<TColumnBase> columns,
) {
  final result = <FortuneObjectConnectionOption>[];
  final seen = <String>{};
  for (final column in columns) {
    if (column.columnType.code != TColumnType.TYPE_IMAGE) continue;
    final keyword = column.keyword.trim();
    if (keyword.isEmpty) continue;
    final objectId = keyword.startsWith('#') ? keyword : '#$keyword';
    if (!seen.add(objectId.toLowerCase())) continue;
    final name = column.columnName.trim().isEmpty
        ? keyword
        : column.columnName.trim();
    result.add(
      FortuneObjectConnectionOption(
        value: objectId,
        label: '$name ($objectId)',
      ),
    );
  }
  return result;
}

@visibleForTesting
Widget commonLabelRequiredTableForTesting({
  required List<TColumnBase> columns,
  required VoidCallback onRequiredChanged,
  LabelSheetKeywordInsertController? keywordInsertController,
}) => _CommonLabelTable(
  columns: columns,
  keywordInsertController:
      keywordInsertController ?? LabelSheetKeywordInsertController(),
  onRequiredChanged: onRequiredChanged,
);

class CommonLabelManage extends StatefulWidget {
  final String title;
  final LabelSize? labelSize;
  final VoidCallback? onSheetReady;
  final ValueChanged<Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;
  final LabelSheetImageImportController? imageImportController;
  final LabelSheetEditingLifecycleController? editingLifecycleController;
  final ValueChanged<bool>? onSheetDirtyChanged;
  final ValueChanged<LabelSize>? onLabelSaved;
  final VoidCallback? onColumnEditRequested;
  const CommonLabelManage({
    super.key,
    required this.title,
    this.labelSize,
    this.onSheetReady,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
    this.imageImportController,
    this.editingLifecycleController,
    this.onSheetDirtyChanged,
    this.onLabelSaved,
    this.onColumnEditRequested,
  });

  @override
  State<CommonLabelManage> createState() => _CommonLabelManageState();
}

class _CommonLabelManageState extends State<CommonLabelManage> {
  double _rightFraction = 0;
  bool _rightWidthChangedByUser = false;
  static const double _handleWidth = 8;
  final LabelSheetKeywordInsertController _keywordInsertController =
      LabelSheetKeywordInsertController();

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
        final maxRight = totalWidth - minLeft - _handleWidth;
        final rightLower = maxRight < commonLabelRightPaneMinWidth
          ? maxRight
          : commonLabelRightPaneMinWidth;
        final columns = TColumn.datas ?? const <TColumn>[];
        final specialColumns = TColumnSpecial.datas ?? const <TColumnBase>[];
        final barcodeObjectIds = commonLabelBarcodeObjectIdsFor(
          specialColumns,
          columns,
        );
        final imageObjectIds = commonLabelImageObjectIdsFor(
          specialColumns,
          columns,
        );
        final barcodeObjectOptions =
            commonLabelBarcodeObjectOptionsFromColumns(columns);
        final imageObjectOptions = commonLabelImageObjectOptionsFromColumns(
          columns,
        );
        final requiredKeywords = commonLabelRequiredKeywordsFor(
          specialColumns,
          columns,
        );
        // 우측 폭 계산 및 하한선 적용
        final double rightWidth;
        if (_rightWidthChangedByUser) {
          rightWidth = (totalWidth * _rightFraction)
              .clamp(rightLower, maxRight)
              .toDouble();
        } else {
          rightWidth = commonLabelRightPaneInitialWidth
              .clamp(rightLower, maxRight)
              .toDouble();
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
                    imageObjectIds: imageObjectIds,
                    barcodeObjectIds: barcodeObjectIds,
                    imageObjectOptions: imageObjectOptions,
                    barcodeObjectOptions: barcodeObjectOptions,
                    requiredKeywords: requiredKeywords,
                    requiredChecks: commonLabelRequiredCheckSaves(
                      specialColumns,
                      columns,
                    ),
                    onSheetReady: widget.onSheetReady,
                    onGridRectChanged: widget.onGridRectChanged,
                    onBeforeSheetDialog: widget.onBeforeSheetDialog,
                    onSheetDialogClosed: widget.onSheetDialogClosed,
                    imageImportController: widget.imageImportController,
                    editingLifecycleController:
                      widget.editingLifecycleController,
                    keywordInsertController: _keywordInsertController,
                    onDirtyChanged: widget.onSheetDirtyChanged,
                    onSaved: widget.onLabelSaved,
                  ),
                ),
              ),
            ),
            VerticalPaneSplitter(
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
                keywordInsertController: _keywordInsertController,
                onColumnEditRequested: widget.onColumnEditRequested,
                onRequiredChanged: () {
                  widget.editingLifecycleController?.markDirty();
                  setState(() {});
                },
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
  final LabelSheetKeywordInsertController keywordInsertController;
  final VoidCallback? onColumnEditRequested;
  final VoidCallback onRequiredChanged;
  const _RightPane({
    required this.title,
    required this.columns,
    required this.keywordInsertController,
    required this.onRequiredChanged,
    this.onColumnEditRequested,
  });

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
        final columns = List<TColumnBase>.from(TColumn.datas ?? const []);

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
              child: _CommonLabelTable(
                columns: widget.columns,
                keywordInsertController: widget.keywordInsertController,
                onRequiredChanged: widget.onRequiredChanged,
              ),
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
                onPressed: widget.onColumnEditRequested,
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
                columns: columns,
                keywordInsertController: widget.keywordInsertController,
                onRequiredChanged: widget.onRequiredChanged,
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
  final LabelSheetKeywordInsertController keywordInsertController;
  final VoidCallback onRequiredChanged;
  const _CommonLabelTable({
    required this.columns,
    required this.keywordInsertController,
    required this.onRequiredChanged,
  });

  static const List<String> _baseHeaders = ['키워드', '이름', '필수등록'];

  static String _headerTitle(int idx) => _baseHeaders[idx];

  static String _cellText(TColumnBase row, int idx) {
    if (idx == 0) return row.keyword;
    if (idx == 1) return row.columnName;
    if (idx == 2) return row.useMissingKeywordCheck ? '예' : '';
    return '';
  }

  static double _minWidth(int idx) => idx == 2
      ? commonLabelRequiredColumnWidth
      : _commonLabelFlexibleColumnMinWidth;

  @override
  State<_CommonLabelTable> createState() => _CommonLabelTableState();
}

class _CommonLabelTableState extends State<_CommonLabelTable> {
  static const String _missingKeywordCheckColumnId = 'common_label_2';

  final FortuneTableCheckboxController _missingKeywordCheckController =
      FortuneTableCheckboxController();

  @override
  void initState() {
    super.initState();
    _syncMissingKeywordCheckController();
  }

  @override
  void didUpdateWidget(covariant _CommonLabelTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMissingKeywordCheckController();
  }

  @override
  void dispose() {
    _missingKeywordCheckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths = commonLabelColumnWidthsForViewport(
          constraints.maxWidth,
        );
        return FortuneTable<TColumnBase>(
          rows: widget.columns,
          columns: [
            for (var index = 0;
                index < _CommonLabelTable._baseHeaders.length;
                index += 1)
              FortuneTableColumn<TColumnBase>(
                id: 'common_label_$index',
                header: _CommonLabelTable._headerTitle(index),
                initialWidth: columnWidths[index],
                minWidth: _CommonLabelTable._minWidth(index),
                text: (row) => _CommonLabelTable._cellText(row, index),
                onDoubleTap: index == 0
                    ? (row, rowIndex) => widget.keywordInsertController
                      .insertAtCurrentContext('#${row.keyword}')
                    : null,
                dragData: index == 0
                    ? (row, rowIndex) =>
                          LabelSheetKeywordDragData('{#${row.keyword}}')
                    : null,
                dragFeedbackBuilder: index == 0
                    ? (context, row, rowIndex) => Material(
                        elevation: 4,
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text('{#${row.keyword}}'),
                        ),
                      )
                    : null,
                checkboxController:
                    index == 2 ? _missingKeywordCheckController : null,
                onCheckboxChangedAt: index == 2
                    ? (row, rowIndex, value) {
                        setState(() {
                          widget.columns[rowIndex].useMissingKeywordCheck =
                              value;
                        });
                        widget.onRequiredChanged();
                      }
                    : null,
              ),
          ],
          autoFitColumns: false,
          fillLastColumn: false,
          rowNumberWidth: commonLabelRowNumberWidth,
        );
      },
    );
  }

  void _syncMissingKeywordCheckController() {
    _missingKeywordCheckController.setCheckedRows(
      _missingKeywordCheckColumnId,
      [
        for (var index = 0; index < widget.columns.length; index += 1)
          if (widget.columns[index].useMissingKeywordCheck) index,
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
