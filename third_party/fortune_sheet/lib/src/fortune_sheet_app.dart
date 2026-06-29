import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'fortune_sheet_canvas.dart';
import 'fortune_sheet_codec.dart';
import 'fortune_sheet_model.dart';
import 'fortune_sheet_painter.dart';

class FortuneSheetApp extends StatefulWidget {
  const FortuneSheetApp({
    this.workbook,
    this.settings,
    this.showFormulaBar,
    this.showSheetTabs,
    this.gridClientSize,
    this.controller,
    this.imagePicker,
    this.barcodeRenderer,
    this.barcodeFormats = const <FortuneBarcodeFormatOption>[],
    this.barcodeObjectIds = const <String>[],
    this.onChange,
    this.onOp,
    this.locale = const FortuneSheetLocale(),
    super.key,
  });

  final FortuneWorkbook? workbook;
  final FortuneSettings? settings;
  final bool? showFormulaBar;
  final bool? showSheetTabs;
  final FortuneSheetGridClientPhysicalSize? gridClientSize;
  final FortuneSheetController? controller;
  final FortuneImagePicker? imagePicker;
  final FortuneBarcodeRenderer? barcodeRenderer;
  final List<FortuneBarcodeFormatOption> barcodeFormats;
  final List<String> barcodeObjectIds;
  final ValueChanged<FortuneWorkbook>? onChange;
  final FortuneOpCallback? onOp;
  final FortuneSheetLocale locale;

  @override
  State<FortuneSheetApp> createState() => _FortuneSheetAppState();
}

class _FortuneSheetAppState extends State<FortuneSheetApp> {
  late FortuneWorkbook _fallbackWorkbook = FortuneWorkbook(
    sheets: [FortuneSheet(id: 'sheet_01', name: 'Sheet1')],
  );
  late bool _initialGridClientSizeApplied = false;

  FortuneWorkbook _effectiveWorkbookForCallback() {
    final workbook = widget.workbook ?? _fallbackWorkbook;
    final effectiveSettings = _effectiveSettings(workbook);
    final effectiveWorkbook = effectiveSettings == workbook.settings
        ? workbook
        : workbook.copyWith(settings: effectiveSettings);
    return FortuneSheetCodec.workbookFromJson(
      FortuneSheetCodec.workbookToJson(effectiveWorkbook),
      settings: effectiveWorkbook.settings,
    );
  }

  void _notifyCurrentWorkbookAfterFrame(
    ValueChanged<FortuneWorkbook> onChange,
  ) {
    final workbook = _effectiveWorkbookForCallback();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.onChange != onChange) {
        return;
      }
      onChange(workbook);
    });
  }

  void _handleWorkbookChanged(FortuneWorkbook workbook) {
    if (_workbookDataChanged(_fallbackWorkbook, workbook)) {
      final currentJson = FortuneSheetCodec.workbookToJson(workbook);
      _fallbackWorkbook = FortuneSheetCodec.workbookFromJson({
        'data': currentJson['data'],
      }, settings: _fallbackWorkbook.settings);
    }
    widget.onChange?.call(workbook);
  }

  FortuneWorkbook _workbookWithInitialGridClientSize(FortuneWorkbook workbook) {
    final gridClientSize = widget.gridClientSize;
    if (_initialGridClientSizeApplied || gridClientSize == null) {
      return workbook;
    }
    _initialGridClientSizeApplied = true;
    return resizeSheetGridClientArea(
      workbook,
      gridClientSize.widthMm,
      gridClientSize.heightMm,
    );
  }

  bool _workbookDataChanged(
    FortuneWorkbook previousWorkbook,
    FortuneWorkbook workbook,
  ) {
    final previousJson = FortuneSheetCodec.workbookToJson(previousWorkbook);
    final currentJson = FortuneSheetCodec.workbookToJson(workbook);
    return jsonEncode(previousJson['data']) != jsonEncode(currentJson['data']);
  }

  @override
  void didUpdateWidget(covariant FortuneSheetApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final onChangeReplaced =
        oldWidget.onChange != null &&
        widget.onChange != null &&
        oldWidget.onChange != widget.onChange;
    if (onChangeReplaced &&
        oldWidget.workbook == widget.workbook &&
        oldWidget.settings == widget.settings &&
        oldWidget.showFormulaBar == widget.showFormulaBar &&
        oldWidget.showSheetTabs == widget.showSheetTabs &&
        oldWidget.gridClientSize == widget.gridClientSize) {
      _notifyCurrentWorkbookAfterFrame(widget.onChange!);
    }
  }

  FortuneSettings _effectiveSettings(FortuneWorkbook workbook) {
    final settings = widget.settings ?? workbook.settings;
    final showFormulaBar = widget.showFormulaBar;
    final showSheetTabs = widget.showSheetTabs;
    return showFormulaBar == null && showSheetTabs == null
        ? settings
        : settings.copyWith(
            showFormulaBar: showFormulaBar,
            showSheetTabs: showSheetTabs,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FortuneSheetCanvas(
        workbook: _workbookWithInitialGridClientSize(
          widget.workbook ?? _fallbackWorkbook,
        ),
        settings: widget.settings,
        showFormulaBar: widget.showFormulaBar,
        showSheetTabs: widget.showSheetTabs,
        controller: widget.controller,
        imagePicker: widget.imagePicker,
        barcodeRenderer: widget.barcodeRenderer,
        barcodeFormats: widget.barcodeFormats,
        barcodeObjectIds: widget.barcodeObjectIds,
        onChange: widget.workbook == null
            ? _handleWorkbookChanged
            : widget.onChange,
        onOp: widget.onOp,
        locale: widget.locale,
      ),
    );
  }
}
