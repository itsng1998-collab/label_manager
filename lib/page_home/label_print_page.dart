import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';

int? parseLabelPrintLineSpacing(String text) {
  final normalized = text.trim();
  if (normalized.isEmpty || normalized == '0') return null;
  final value = int.tryParse(normalized);
  if (value == null || value < 30 || value > 300) {
    throw const FormatException('줄간격은 0 또는 30~300 정수여야 합니다.');
  }
  return value;
}

class LabelPrintPage extends StatefulWidget {
  const LabelPrintPage({
    super.key,
    required this.controller,
    required this.previewBuilder,
    required this.onPrinterSettings,
    required this.onIssue,
    required this.onCancelIssue,
    required this.busy,
  });

  final LabelPrintSessionController controller;
  final Widget Function(LabelPrintRowDraft row) previewBuilder;
  final VoidCallback onPrinterSettings;
  final VoidCallback onIssue;
  final VoidCallback onCancelIssue;
  final bool busy;

  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> {
  static const double _splitterWidth = 7;
  static const double _minimumPaneWidth = 280;

  final FortuneTableEditingController _editingController =
      FortuneTableEditingController();
  final LayerLink _zoomToolbarAnchorLink = LayerLink();
  double _tableFraction = 0.6;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(covariant LabelPrintPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChanged);
      widget.controller.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.controller.rows;
    final selectedIndex = rows.indexWhere(
      (row) => row.itemId == widget.controller.selectedItemId,
    );
    final table = FortuneTable<LabelPrintRowDraft>(
      rows: rows,
      columns: _columns,
      autoFitColumns: false,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      editingController: _editingController,
      onRowSelected: (row, _) => widget.controller.selectItem(row.itemId),
    );
    final selected = selectedIndex < 0 ? null : rows[selectedIndex];
    final preview = selected == null
        ? const Center(child: Text('발행할 품목을 선택하세요.'))
        : widget.previewBuilder(selected);

    return LabelSheetZoomToolbarAnchor(
      link: _zoomToolbarAnchorLink,
      child: Column(
        children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    Expanded(child: table),
                    const Divider(height: 1),
                    Expanded(child: preview),
                  ],
                );
              }
              final availableWidth = constraints.maxWidth - _splitterWidth;
              final minimumFraction = _minimumPaneWidth / availableWidth;
              final maximumFraction = 1 - minimumFraction;
              final tableFraction = _tableFraction.clamp(
                minimumFraction,
                maximumFraction,
              );
              return Row(
                children: [
                  SizedBox(width: availableWidth * tableFraction, child: table),
                  VerticalPaneSplitter(
                    key: const ValueKey('label-print-splitter'),
                    width: _splitterWidth,
                    onDrag: (delta) {
                      setState(() {
                        _tableFraction = (_tableFraction +
                                delta / availableWidth)
                            .clamp(minimumFraction, maximumFraction);
                      });
                    },
                  ),
                  Expanded(child: preview),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        _commandBar(),
        ],
      ),
    );
  }

  Widget _commandBar() => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: widget.busy ? null : widget.onPrinterSettings,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('프린터 설정'),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Tooltip(
              message: widget.controller.settings.printerName ?? '선택된 프린터 없음',
              child: Text(
                widget.controller.settings.printerName ?? '선택된 프린터 없음',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: widget.busy ? widget.onCancelIssue : widget.onIssue,
            icon: Icon(widget.busy ? Icons.stop : Icons.print, size: 18),
            label: Text(widget.busy ? '발행 취소' : '발행'),
          ),
          const Spacer(),
          CompositedTransformTarget(
            link: _zoomToolbarAnchorLink,
            child: const SizedBox(
              key: ValueKey('label-print-zoom-anchor'),
              width: 1,
              height: 29,
            ),
          ),
        ],
      ),
    ),
  );

  List<FortuneTableColumn<LabelPrintRowDraft>> get _columns => [
    _integerColumn(
      id: 'copies',
      header: '발행매수',
      text: (row) => '${row.copies}',
      minimum: 0,
      update: (row, value) => row.copyWith(
        copies: value,
        copiesSource: LabelPrintValueSource.sessionEdited,
      ),
    ),
    FortuneTableColumn(
      id: 'labelSize',
      header: '라벨크기명',
      initialWidth: 100,
      text: (row) => row.item.item.labelSizeName,
    ),
    FortuneTableColumn(
      id: 'itemName',
      header: '품명',
      initialWidth: 180,
      text: (row) => row.item.item.itemName,
    ),
    _integerColumn(
      id: 'width',
      header: '출력 폭',
      text: (row) => '${row.widthMm}',
      minimum: 1,
      update: (row, value) => row.copyWith(
        widthMm: value,
        widthSource: LabelPrintValueSource.sessionEdited,
      ),
    ),
    _integerColumn(
      id: 'height',
      header: '출력 높이',
      text: (row) => '${row.heightMm}',
      minimum: 1,
      update: (row, value) => row.copyWith(
        heightMm: value,
        heightSource: LabelPrintValueSource.sessionEdited,
      ),
    ),
    _doubleColumn('leftMargin', '왼쪽 여백', (row) => row.leftMarginMm,
        (row, value) => row.copyWith(
          leftMarginMm: value,
          leftMarginSource: LabelPrintValueSource.sessionEdited,
        )),
    _doubleColumn('rightMargin', '오른쪽 여백', (row) => row.rightMarginMm,
        (row, value) => row.copyWith(
          rightMarginMm: value,
          rightMarginSource: LabelPrintValueSource.sessionEdited,
        )),
    _doubleColumn('topMargin', '위쪽 여백', (row) => row.topMarginMm,
        (row, value) => row.copyWith(
          topMarginMm: value,
          topMarginSource: LabelPrintValueSource.sessionEdited,
        )),
    _doubleColumn('leftPush', '왼쪽 밀기', (row) => row.leftPushMm,
        (row, value) => row.copyWith(
          leftPushMm: value,
          leftPushSource: LabelPrintValueSource.sessionEdited,
        ), signed: true),
    _doubleColumn('topPush', '위쪽 밀기', (row) => row.topPushMm,
        (row, value) => row.copyWith(
          topPushMm: value,
          topPushSource: LabelPrintValueSource.sessionEdited,
        ), signed: true),
    FortuneTableColumn(
      id: 'lineSpacing',
      header: '줄간격',
      initialWidth: 80,
      text: (row) => '${row.lineSpacingPercent ?? 0}',
      isTextEditable: (_, _) => !widget.busy,
      onTextCommitted: (row, _, value) async {
        int? parsed;
        try {
          parsed = parseLabelPrintLineSpacing(value);
        } on FormatException catch (error) {
          _showInvalid(error.message);
          return;
        }
        widget.controller.updateRow(
          row.itemId,
          (current) => current.copyWith(
            lineSpacingPercent: parsed,
            lineSpacingSource: LabelPrintValueSource.sessionEdited,
          ),
        );
      },
    ),
  ];

  FortuneTableColumn<LabelPrintRowDraft> _integerColumn({
    required String id,
    required String header,
    required String Function(LabelPrintRowDraft row) text,
    required int minimum,
    required LabelPrintRowDraft Function(LabelPrintRowDraft row, int value)
        update,
  }) => FortuneTableColumn(
    id: id,
    header: header,
    initialWidth: 80,
    text: text,
    isTextEditable: (_, _) => !widget.busy,
    onTextCommitted: (row, _, value) async {
      final parsed = int.tryParse(value.trim());
      if (parsed == null || parsed < minimum) {
        _showInvalid('$header 값이 올바르지 않습니다.');
        return;
      }
      widget.controller.updateRow(row.itemId, (current) => update(current, parsed));
    },
  );

  FortuneTableColumn<LabelPrintRowDraft> _doubleColumn(
    String id,
    String header,
    double Function(LabelPrintRowDraft row) value,
    LabelPrintRowDraft Function(LabelPrintRowDraft row, double value) update, {
    bool signed = false,
  }) => FortuneTableColumn(
    id: id,
    header: header,
    initialWidth: 85,
    text: (row) => '${value(row)}',
    isTextEditable: (_, _) => !widget.busy,
    onTextCommitted: (row, _, text) async {
      final parsed = double.tryParse(text.trim());
      if (parsed == null || !parsed.isFinite || (!signed && parsed < 0)) {
        _showInvalid('$header 값이 올바르지 않습니다.');
        return;
      }
      widget.controller.updateRow(row.itemId, (current) => update(current, parsed));
    },
  );

  void _showInvalid(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
