import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_label_sheet/label_sheet_ai_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_ai_import_temp.dart';
import 'package:label_manager/page_label_sheet/label_sheet_import_model.dart';
import 'package:label_manager/page_label_sheet/label_sheet_open_xml_export.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_xlsx_import.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool labelSheetWriteRtfOpenXmlTestFileEnabled = false;
const String labelSheetSaveToolbarCommand = 'label-sheet-save';
const String labelSheetPrintToolbarCommand = 'label-sheet-print';
const int labelSheetDefaultZoomPercent = 100;
const int labelSheetMinZoomPercent = 10;
const int labelSheetMaxZoomPercent = 400;

enum LabelSheetZoomToolbarPlacement {
  sheetToolbarEnd,
  previewTabAreaEnd,
  hidden,
}

const int _labelSheetDefaultPhysicalWidthMm = 100;
const int _labelSheetDefaultPhysicalHeightMm = 100;

int _labelSheetPositivePhysicalSizeOrDefault(int? value, int fallback) {
  return value != null && value > 0 ? value : fallback;
}

const String _labelSheetGeminiApiKeyPrefsKey = 'label_sheet_gemini_api_key';
const String _labelSheetGeminiModelPrefsKey = 'label_sheet_gemini_model';
const String _labelFileDirectoryPrefsKey = 'label_file_directory';
const double _labelSheetImportMinReadableFontHeightMm = 2.5;

const List<String> labelSheetToolbarItems = [
  labelSheetSaveToolbarCommand,
  labelSheetPrintToolbarCommand,
  '|',
  fortuneToolbarFontPopupKey,
  '|',
  fortuneToolbarFontSizePopupKey,
  '|',
  fortuneToolbarBoldCommand,
  fortuneToolbarItalicCommand,
  fortuneToolbarStrikeThroughCommand,
  fortuneToolbarUnderlineCommand,
  '|',
  fortuneToolbarFontColorPopupKey,
  fortuneToolbarBackgroundPopupKey,
  fortuneToolbarBorderPopupKey,
  fortuneToolbarMergePopupKey,
  '|',
  fortuneToolbarHorizontalAlignPopupKey,
  fortuneToolbarVerticalAlignPopupKey,
  fortuneToolbarTextWrapPopupKey,
  fortuneToolbarTextRotationPopupKey,
  '|',
  fortuneToolbarImageCommand,
  fortuneToolbarBarcodeCommand,
];

const Map<String, int> _labelSheetBarcodeFormatValues = {
  'qrCode': zxing.Format.qrCode,
  'microQRCode': zxing.Format.microQRCode,
  'dataMatrix': zxing.Format.dataMatrix,
  'aztec': zxing.Format.aztec,
  'codabar': zxing.Format.codabar,
  'code39': zxing.Format.code39,
  'code93': zxing.Format.code93,
  'code128': zxing.Format.code128,
  'ean8': zxing.Format.ean8,
  'ean13': zxing.Format.ean13,
  'itf': zxing.Format.itf,
  'upca': zxing.Format.upca,
  'upce': zxing.Format.upce,
};

const Set<String> _labelSheetLinearBarcodeFormatIds = {
  'codabar',
  'code39',
  'code93',
  'code128',
  'ean8',
  'ean13',
  'itf',
  'upca',
  'upce',
};

final List<FortuneBarcodeFormatOption> labelSheetBarcodeFormats = [
  for (final entry in _labelSheetBarcodeFormatValues.entries)
    FortuneBarcodeFormatOption(
      id: entry.key,
      label: entry.value.name,
      ratio: entry.value.ratio,
    ),
];

({int width, int height}) labelSheetBarcodeOutputSize(
  FortuneBarcodeRequest request,
) {
  final geometry = _labelSheetBarcodeGeometry(request);
  return (width: geometry.width, height: geometry.height);
}

const Set<String> labelSheetHiddenContextMenuItems = {
  fortuneContextSortCommand,
  fortuneContextOrderAzCommand,
  fortuneContextOrderZaCommand,
  fortuneToolbarFilterCommand,
  fortuneToolbarLinkCommand,
  fortuneFilterSortAscCommand,
  fortuneFilterSortDescCommand,
};

List<String> labelSheetContextMenuItems(
  List<String> base, {
  bool includeImportLabelImage = false,
}) {
  var visible = fortuneMenuItemsWithout(base, labelSheetHiddenContextMenuItems);
  if (includeImportLabelImage &&
      !visible.contains(fortuneContextImportLabelImageCommand)) {
    final loadCommonLabelIndex = visible.indexOf(
      fortuneContextLoadCommonLabelCommand,
    );
    final insertIndex = loadCommonLabelIndex < 0
        ? visible.length
        : loadCommonLabelIndex + 1;
    visible = [
      ...visible.take(insertIndex),
      fortuneContextImportLabelImageCommand,
      ...visible.skip(insertIndex),
    ];
  }
  if (visible.contains(fortuneToolbarBarcodeCommand)) {
    return visible;
  }
  final imageIndex = visible.indexOf(fortuneToolbarImageCommand);
  if (imageIndex < 0) {
    return visible;
  }
  return [
    ...visible.take(imageIndex + 1),
    fortuneToolbarBarcodeCommand,
    ...visible.skip(imageIndex + 1),
  ];
}

Future<FortuneBarcodeRenderResult?> labelSheetBarcodeRenderer(
  FortuneBarcodeRequest request,
) async {
  final format = _labelSheetBarcodeFormatValues[request.formatId];
  if (format == null) {
    return null;
  }
  final geometry = _labelSheetBarcodeGeometry(request);
  final width = geometry.width;
  final height = geometry.height;
  final bodyHeight = geometry.bodyHeight;
  final drawableWidth = geometry.drawableWidth;
  final sourceWidth = labelSheetBarcodeEncodeWidth(request);
  fortuneSheetDebugLog(
    'label barcode render requestFormat=${request.formatId} '
    'zxingFormat=${format.name} width=${request.width} height=${request.height} '
    'barHeight=${request.barHeight} moduleScale=${request.moduleScale} '
    'textFont=${request.humanReadableFontFamily}/${request.humanReadableFontSize} '
    'output=$width x $height bodyHeight=$bodyHeight '
    'sourceWidth=$sourceWidth drawableWidth=$drawableWidth',
  );
  final result = zxing.zx.encodeBarcode(
    contents: request.text,
    params: zxing.EncodeParams(
      format: format,
      width: sourceWidth,
      height: bodyHeight,
      margin: 0,
      eccLevel: zxing.EccLevel.low,
    ),
  );
  final data = result.data;
  if (!result.isValid || data == null) {
    return null;
  }
  final barcode = labelSheetDecodeEncodedBarcodeImage(
    data,
    width: sourceWidth,
    height: bodyHeight,
  );
  final scaledBarcode = imglib.copyResize(
    barcode,
    width: drawableWidth,
    height: bodyHeight,
    interpolation: imglib.Interpolation.nearest,
  );
  final bodyBounds = _labelSheetBarcodeInkVerticalBounds(scaledBarcode);
  final pngBytes = await _labelSheetComposeBarcodePng(
    request,
    scaledBarcode,
    width: width,
    height: height,
    bodyHeight: bodyHeight,
  );
  return FortuneBarcodeRenderResult(
    bytes: pngBytes,
    mimeType: 'image/png',
    pixelWidth: width,
    pixelHeight: height,
    bodyTop: bodyBounds.top,
    bodyHeight: bodyBounds.height,
  );
}

({int top, int height}) _labelSheetBarcodeInkVerticalBounds(
  imglib.Image barcode,
) {
  var top = -1;
  var bottom = -1;
  for (var y = 0; y < barcode.height; y += 1) {
    var hasInk = false;
    for (var x = 0; x < barcode.width; x += 1) {
      if (barcode.getPixel(x, y).r < 128) {
        hasInk = true;
        break;
      }
    }
    if (hasInk) {
      top = top < 0 ? y : top;
      bottom = y;
    }
  }
  if (top < 0 || bottom < top) {
    return (top: 0, height: math.max(1, barcode.height));
  }
  return (top: top, height: math.max(1, bottom - top + 1));
}

@visibleForTesting
int labelSheetBarcodeEncodeWidth(FortuneBarcodeRequest request) {
  final geometry = _labelSheetBarcodeGeometry(request);
  if (_labelSheetLinearBarcodeFormatIds.contains(request.formatId)) {
    return geometry.drawableWidth;
  }
  return geometry.sourceWidth;
}

@visibleForTesting
imglib.Image labelSheetDecodeEncodedBarcodeImage(
  Uint8List data, {
  required int width,
  required int height,
}) {
  final pixelCount = math.max(1, width * height);
  var numChannels = 1;
  if (data.lengthInBytes % pixelCount == 0) {
    final inferredChannels = data.lengthInBytes ~/ pixelCount;
    if (inferredChannels >= 1 && inferredChannels <= 4) {
      numChannels = inferredChannels;
    }
  }
  return imglib.Image.fromBytes(
    width: width,
    height: height,
    bytes: Uint8List.fromList(data).buffer,
    numChannels: numChannels,
  );
}

String _labelSheetBarcodeDisplayText(FortuneBarcodeRequest request) {
  return '${request.leadingText}${request.text}${request.trailingText}';
}

Future<Uint8List> _labelSheetComposeBarcodePng(
  FortuneBarcodeRequest request,
  imglib.Image scaledBarcode, {
  required int width,
  required int height,
  required int bodyHeight,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final barPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  for (var y = 0; y < bodyHeight; y += 1) {
    var runStart = -1;
    for (var x = 0; x < width; x += 1) {
      final isBlack = scaledBarcode.getPixel(x, y).r < 128;
      if (isBlack && runStart < 0) {
        runStart = x;
      } else if (!isBlack && runStart >= 0) {
        canvas.drawRect(
          ui.Rect.fromLTWH(
            runStart.toDouble(),
            y.toDouble(),
            (x - runStart).toDouble(),
            1,
          ),
          barPaint,
        );
        runStart = -1;
      }
    }
    if (runStart >= 0) {
      canvas.drawRect(
        ui.Rect.fromLTWH(
          runStart.toDouble(),
          y.toDouble(),
          (width - runStart).toDouble(),
          1,
        ),
        barPaint,
      );
    }
  }

  if (request.showHumanReadableText) {
    final textPainter = _labelSheetBarcodeTextPainter(request)..layout();
    final left = math.max(0.0, (width - textPainter.width) / 2);
    final top = math.max(bodyHeight.toDouble(), height - textPainter.height);
    textPainter.paint(canvas, ui.Offset(left, top));
  }

  final picture = recorder.endRecording();
  try {
    final rendered = await picture.toImage(width, height);
    try {
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      rendered.dispose();
    }
  } finally {
    picture.dispose();
  }
}

@visibleForTesting
Future<Uint8List> labelSheetComposeBarcodePngForTesting(
  FortuneBarcodeRequest request,
  imglib.Image scaledBarcode, {
  required int width,
  required int height,
  required int bodyHeight,
}) {
  return _labelSheetComposeBarcodePng(
    request,
    scaledBarcode,
    width: width,
    height: height,
    bodyHeight: bodyHeight,
  );
}

TextPainter _labelSheetBarcodeTextPainter(FortuneBarcodeRequest request) {
  final fontFamily = request.humanReadableFontFamily?.trim();
  return TextPainter(
    text: TextSpan(
      text: _labelSheetBarcodeDisplayText(request),
      style: TextStyle(
        color: Colors.black,
        fontFamily: fontFamily == null || fontFamily.isEmpty
            ? null
            : fontFamily,
        fontSize: request.humanReadableFontSize.clamp(1, 256).toDouble(),
        height: 1,
      ),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  );
}

({int width, int height}) _labelSheetBarcodeTextMetrics(
  FortuneBarcodeRequest request,
) {
  final textPainter = _labelSheetBarcodeTextPainter(request)..layout();
  return (
    width: math.max(1, textPainter.width.ceil()),
    height: math.max(1, textPainter.height.ceil()),
  );
}

_LabelSheetBarcodeGeometry _labelSheetBarcodeGeometry(
  FortuneBarcodeRequest request,
) {
  final moduleScale = request.moduleScale.round().clamp(1, 16);
  final textMetrics = request.showHumanReadableText
      ? _labelSheetBarcodeTextMetrics(request)
      : (width: 0, height: 0);
  final textHeight = textMetrics.height;
  final barcodeHeight = request.barHeight.round().clamp(1, 4096);
  final contentWidth = math.max(1, request.text.length * 10 * moduleScale);
  final displayTextWidth = request.showHumanReadableText
      ? textMetrics.width
      : 0;
  final requestedWidth = request.width.round();
  final requestedHeight = request.height.round();
  final width = requestedWidth > 0
      ? requestedWidth.clamp(1, 4096)
      : math.min(4096, math.max(contentWidth, displayTextWidth));
  final height = requestedHeight > 0
      ? requestedHeight.clamp(1, 4096)
      : math.min(
          4096,
          barcodeHeight + (request.showHumanReadableText ? textHeight : 0),
        );
  final bodyHeight = math.max(
    1,
    math.min(
      barcodeHeight,
      height - (request.showHumanReadableText ? textHeight : 0),
    ),
  );
  final drawableWidth = math.max(1, width);
  final sourceWidth = math.max(1, (drawableWidth / moduleScale).round());
  return _LabelSheetBarcodeGeometry(
    width: width,
    height: height,
    bodyHeight: bodyHeight,
    drawableWidth: drawableWidth,
    sourceWidth: sourceWidth,
  );
}

class _LabelSheetBarcodeGeometry {
  const _LabelSheetBarcodeGeometry({
    required this.width,
    required this.height,
    required this.bodyHeight,
    required this.drawableWidth,
    required this.sourceWidth,
  });

  final int width;
  final int height;
  final int bodyHeight;
  final int drawableWidth;
  final int sourceWidth;
}

LabelSheetImageImportDraft? labelSheetAnalyzeImageImport(
  Uint8List bytes, {
  required FortuneSheet sheet,
  required String mimeType,
  required String fileName,
}) {
  final decoded = imglib.decodeImage(bytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return null;
  }
  final analysisImage = _labelSheetAnalysisImage(decoded);
  final columnLines = _labelSheetDetectGridLines(
    analysisImage,
    axis: _LabelSheetGridAxis.vertical,
  );
  final rowLines = _labelSheetDetectGridLines(
    analysisImage,
    axis: _LabelSheetGridAxis.horizontal,
  );
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final logicalSize = physicalSize.logicalSize;
  final columnWidths = _labelSheetSegmentSizes(
    columnLines,
    sourceLength: analysisImage.width,
    targetLength: logicalSize.width,
  );
  final rowHeights = _labelSheetSegmentSizes(
    rowLines,
    sourceLength: analysisImage.height,
    targetLength: logicalSize.height,
  );
  if (columnWidths.isEmpty || rowHeights.isEmpty) {
    return null;
  }
  final sourceWidth = decoded.width;
  final sourceHeight = decoded.height;
  return LabelSheetImageImportDraft(
    imageWidth: sourceWidth,
    imageHeight: sourceHeight,
    rowLines: rowLines,
    columnLines: columnLines,
    rowHeights: rowHeights,
    columnWidths: columnWidths,
    images: const <FortuneImage>[],
  );
}

imglib.Image _labelSheetAnalysisImage(imglib.Image source) {
  const maxAnalysisSide = 1400;
  final longestSide = math.max(source.width, source.height);
  if (longestSide <= maxAnalysisSide) {
    return source;
  }
  final scale = maxAnalysisSide / longestSide;
  return imglib.copyResize(
    source,
    width: math.max(1, (source.width * scale).round()),
    height: math.max(1, (source.height * scale).round()),
    interpolation: imglib.Interpolation.average,
  );
}

enum _LabelSheetGridAxis { horizontal, vertical }

List<int> _labelSheetDetectGridLines(
  imglib.Image image, {
  required _LabelSheetGridAxis axis,
}) {
  final length = axis == _LabelSheetGridAxis.vertical
      ? image.width
      : image.height;
  final crossLength = axis == _LabelSheetGridAxis.vertical
      ? image.height
      : image.width;
  final ratios = <double>[];
  for (var index = 0; index < length; index += 1) {
    var darkCount = 0;
    for (var cross = 0; cross < crossLength; cross += 1) {
      final pixel = axis == _LabelSheetGridAxis.vertical
          ? image.getPixel(index, cross)
          : image.getPixel(cross, index);
      final luminance = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
      if (luminance < 112 && pixel.a > 16) {
        darkCount += 1;
      }
    }
    ratios.add(darkCount / crossLength);
  }

  final candidates = <int>[];
  var runStart = -1;
  for (var index = 0; index < ratios.length; index += 1) {
    final isLine = ratios[index] >= 0.22;
    if (isLine && runStart < 0) {
      runStart = index;
    } else if (!isLine && runStart >= 0) {
      candidates.add(((runStart + index - 1) / 2).round());
      runStart = -1;
    }
  }
  if (runStart >= 0) {
    candidates.add(((runStart + ratios.length - 1) / 2).round());
  }

  final minGap = math.max(3, (length * 0.006).round());
  final lines = <int>[0];
  for (final candidate in candidates) {
    if (candidate <= minGap || candidate >= length - minGap) {
      continue;
    }
    if (candidate - lines.last < minGap) {
      lines[lines.length - 1] = ((lines.last + candidate) / 2).round();
    } else {
      lines.add(candidate);
    }
  }
  if (length - 1 - lines.last >= minGap) {
    lines.add(length - 1);
  } else {
    lines[lines.length - 1] = length - 1;
  }

  const maxSegments = 120;
  if (lines.length > maxSegments + 1) {
    final step = (lines.length - 1) / maxSegments;
    final reduced = <int>{
      for (var index = 0; index <= maxSegments; index += 1)
        lines[(index * step).round().clamp(0, lines.length - 1)],
    }.toList()..sort();
    return reduced;
  }
  return lines;
}

Map<int, double> _labelSheetSegmentSizes(
  List<int> lines, {
  required int sourceLength,
  required double targetLength,
}) {
  if (lines.length < 2 || sourceLength <= 0 || targetLength <= 0) {
    return const <int, double>{};
  }
  final sizes = <int, double>{};
  for (var index = 0; index < lines.length - 1; index += 1) {
    final start = lines[index];
    final end = lines[index + 1];
    final segment = math.max(1, end - start);
    sizes[index] = math.max(4.0, segment / sourceLength * targetLength);
  }
  return sizes;
}

FortuneWorkbook labelSheetWorkbook(
  FortuneWorkbook base, {
  LabelSize? labelSize,
  String? labelRtf,
}) {
  if (base.sheets.isEmpty) {
    return base;
  }
  final common = labelSize?.labelSizeCommon;
  final widthMm = _labelSheetPositivePhysicalSizeOrDefault(
    common?.width,
    _labelSheetDefaultPhysicalWidthMm,
  );
  final heightMm = _labelSheetPositivePhysicalSizeOrDefault(
    common?.height,
    _labelSheetDefaultPhysicalHeightMm,
  );
  final activeIndex = base.activeSheetIndex.clamp(0, base.sheets.length - 1);
  final sheets = [
    for (var index = 0; index < base.sheets.length; index += 1)
      index == activeIndex
          ? _labelSheetSizedSheet(
              base.sheets[index],
              labelSize: labelSize,
              widthMm: widthMm,
              heightMm: heightMm,
              labelRtf: labelRtf,
            )
          : base.sheets[index].copyWith(),
  ];
  return base.copyWith(sheets: sheets);
}

Future<FortuneWorkbook> labelSheetWorkbookWithRtf(
  FortuneWorkbook base, {
  LabelSize? labelSize,
  String? labelRtf,
}) async {
  final sized = labelSheetWorkbook(
    base,
    labelSize: labelSize,
    labelRtf: labelRtf,
  );
  if (sized.sheets.isEmpty || !labelSheetLooksLikeRichEditRtf(labelRtf)) {
    return sized;
  }
  final activeIndex = sized.activeSheetIndex.clamp(0, sized.sheets.length - 1);
  final activeSheet = sized.sheets[activeIndex];
  final draft = await labelSheetDraftFromRichEditRtfAsync(
    labelRtf!,
    sheet: activeSheet,
    barcodeRenderer: labelSheetBarcodeRenderer,
  );
  if (draft == null) {
    return sized;
  }
  if (labelSheetWriteRtfOpenXmlTestFileEnabled) {
    try {
      final file = await labelSheetWriteRichEditRtfOpenXmlTestFile(
        labelRtf,
        sheet: activeSheet,
        barcodeRenderer: labelSheetBarcodeRenderer,
      );
      if (file == null) {
        fortuneSheetDebugLog('label RTF Open XML test file skipped');
      } else {
        fortuneSheetDebugLog(
          'label RTF Open XML test file written: ${file.path}',
        );
      }
    } catch (error, stackTrace) {
      fortuneSheetDebugLog(
        'label RTF Open XML test file failed: $error\n$stackTrace',
      );
    }
  }
  final importedSheet = labelSheetApplyImageImportDraft(
    activeSheet,
    draft,
    minRowCount: sized.settings.row,
    minColumnCount: sized.settings.column,
  );
  final importedExtraFields = {
    ...importedSheet.extraFields,
    'labelRtfImportSource': true,
  };
  final sheets = [
    for (var index = 0; index < sized.sheets.length; index += 1)
      index == activeIndex
          ? importedSheet.copyWith(extraFields: importedExtraFields)
          : sized.sheets[index].copyWith(),
  ];
  return sized.copyWith(sheets: sheets);
}

FortuneSheet _labelSheetSizedSheet(
  FortuneSheet sheet, {
  required LabelSize? labelSize,
  required int widthMm,
  required int heightMm,
  required String? labelRtf,
}) {
  final extraFields = {
    ...sheet.extraFields,
    fortuneSheetGridClientWidthMmKey: widthMm,
    fortuneSheetGridClientHeightMmKey: heightMm,
  };
  if (labelSheetLooksLikeRichEditRtf(labelRtf)) {
    extraFields.remove('labelRtfImportSource');
  }
  return sheet.copyWith(
    name: labelSize?.labelSizeName ?? sheet.name,
    extraFields: extraFields,
  );
}

FortuneSheet _labelSheetWithPreservedGridClientSize(
  FortuneSheet importedSheet,
  FortuneSheet currentSheet,
) {
  if (fortuneSheetGridClientPhysicalSize(importedSheet) != null) {
    return importedSheet.copyWith();
  }
  final currentSize = fortuneSheetGridClientPhysicalSize(currentSheet);
  if (currentSize == null) {
    return importedSheet.copyWith();
  }
  return importedSheet.copyWith(
    extraFields: {
      ...importedSheet.extraFields,
      fortuneSheetGridClientWidthMmKey: currentSize.widthMm,
      fortuneSheetGridClientHeightMmKey: currentSize.heightMm,
    },
  );
}

// 변환 규칙 C(스케일): 물리 라벨 크기에 맞춰 폭 우선으로 스케일하고, 폭 대비 비율로
// 높이를 맞춘다(규칙 5). 폭 기준 축소로 문자가 실물 프린트 기준 최소 가독 크기(규칙 7)를
// 밑돌면 인쇄 영역을 벗어나더라도 다시 키운다(규칙 6). 세부 규칙은
// label_sheet_xlsx_import.dart 상단 규칙 주석 참조.
FortuneSheet _labelSheetScaledToPhysicalWidth(
  FortuneSheet sheet, {
  required FortuneSheet currentSheet,
}) {
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      fortuneSheetGridClientPhysicalSize(currentSheet);
  if (physicalSize == null) {
    return sheet.copyWith();
  }
  final sourceWidth = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.columnWidths,
    sheet.columnCount,
    sheet.defaultColWidth,
  );
  final sourceHeight = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.rowHeights,
    sheet.rowCount,
    sheet.defaultRowHeight,
  );
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    return sheet.copyWith();
  }
  final targetWidth = physicalSize.logicalSize.width;
  final widthScale = _labelSheetAxisScaleForTarget(
    sourceWidth,
    targetWidth,
    sheet.columnCount,
  );
  final minFontSize = _labelSheetMinimumFontSize(sheet);
  final minReadableFontSize = fortuneMillimetersToLogicalPixels(
    _labelSheetImportMinReadableFontHeightMm,
  );
  final readableScale = minFontSize == null || minFontSize <= 0
      ? widthScale
      : minReadableFontSize / minFontSize;
  final scale = math.max(widthScale, readableScale);
  final scaledSheet = _labelSheetScaleSheet(sheet, scale);
  final scaledWidth = _labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.columnWidths,
    scaledSheet.columnCount,
    scaledSheet.defaultColWidth,
  );
  final scaledHeight = _labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.rowHeights,
    scaledSheet.rowCount,
    scaledSheet.defaultRowHeight,
  );
  final scaledMinFontSize = _labelSheetMinimumFontSize(scaledSheet);
  final overflowLogical = scaledWidth - targetWidth;
  final overflowMm = overflowLogical <= 0
      ? 0.0
      : overflowLogical / fortuneMillimetersToLogicalPixels(1);
  debugLog(
    'label sheet import physical scale '
    'sourceLogical=${sourceWidth}x$sourceHeight '
    'targetWidth=$targetWidth physicalSizeMm=${physicalSize.widthMm}x${physicalSize.heightMm} '
    'widthScale=$widthScale readableScale=$readableScale scale=$scale '
    'minFontSize=$minFontSize scaledMinFontSize=$scaledMinFontSize '
    'minReadableMm=$_labelSheetImportMinReadableFontHeightMm '
    'minReadableLogical=$minReadableFontSize '
    'scaledLogical=${scaledWidth}x$scaledHeight overflowWidth=${scaledWidth > targetWidth} '
    'overflowLogical=$overflowLogical overflowMm=$overflowMm',
    skipFrames: 1,
  );
  return scaledSheet;
}

FortuneSheet _labelSheetScaleSheet(FortuneSheet sheet, double scale) {
  if (!scale.isFinite || scale <= 0) {
    return sheet.copyWith();
  }
  return sheet.copyWith(
    rowHeights: _labelSheetScaleAxis(sheet.rowHeights, scale),
    columnWidths: _labelSheetScaleAxis(sheet.columnWidths, scale),
    defaultRowHeight: _labelSheetScaleNullable(sheet.defaultRowHeight, scale),
    defaultColWidth: _labelSheetScaleNullable(sheet.defaultColWidth, scale),
    cells: {
      for (final entry in sheet.cells.entries)
        entry.key: _labelSheetScaleCell(entry.value, scale),
    },
  );
}

Map<int, double> _labelSheetScaleAxis(Map<int, double> values, double scale) {
  return {
    for (final entry in values.entries)
      entry.key: math.max(1.0, entry.value * scale),
  };
}

double? _labelSheetScaleNullable(double? value, double scale) {
  if (value == null) {
    return null;
  }
  return math.max(1.0, value * scale);
}

FortuneCell _labelSheetScaleCell(FortuneCell cell, double scale) {
  return cell.copyWith(
    fontSize: _labelSheetScaleNullable(cell.fontSize, scale),
    inlineRuns: cell.inlineRuns
        ?.map((run) => _labelSheetScaleInlineRun(run, scale))
        .toList(),
    extraFields: _labelSheetScaleTextExtraFields(cell.extraFields, scale),
  );
}

FortuneInlineTextRun _labelSheetScaleInlineRun(
  FortuneInlineTextRun run,
  double scale,
) {
  return run.copyWith(
    fontSize: _labelSheetScaleNullable(run.fontSize, scale),
    extraFields: _labelSheetScaleTextExtraFields(run.extraFields, scale),
  );
}

Map<String, Object?> _labelSheetScaleTextExtraFields(
  Map<String, Object?> values,
  double scale,
) {
  final scaled = <String, Object?>{...values};
  final letterSpacing = _labelSheetNumber(values['letterSpacing']);
  if (letterSpacing != null) {
    scaled['letterSpacing'] = letterSpacing * scale;
  }
  return scaled;
}

double? _labelSheetNumber(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

double? _labelSheetMinimumFontSize(FortuneSheet sheet) {
  double? minFontSize;
  void add(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return;
    }
    minFontSize = minFontSize == null ? value : math.min(minFontSize!, value);
  }

  for (final cell in sheet.cells.values) {
    add(cell.fontSize);
    for (final run in cell.inlineRuns ?? const <FortuneInlineTextRun>[]) {
      add(run.fontSize);
    }
  }
  return minFontSize;
}

double _labelSheetAxisLogicalTotalSizeForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize,
) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return _labelSheetAxisLogicalTotalSize(sizes);
  }
  final fallback = defaultSize ?? 0;
  var total = 0.0;
  for (var index = 0; index < resolvedCount; index += 1) {
    total += (sizes[index] ?? fallback) + 1;
  }
  return total;
}

double _labelSheetAxisScaleForTarget(
  double sourceTotal,
  double targetTotal,
  int? count,
) {
  if (sourceTotal <= 0 || targetTotal <= 0) {
    return 1;
  }
  final gridLineCount = math.max(0, count ?? 0);
  final sourceContent = math.max(1.0, sourceTotal - gridLineCount);
  final targetContent = math.max(1.0, targetTotal - gridLineCount);
  return targetContent / sourceContent;
}

int _labelSheetAxisCount(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return 0;
  }
  return sizes.keys.reduce(math.max) + 1;
}

void _logImportedSheetApplySample(FortuneSheet sheet) {
  final gridSize = fortuneSheetGridClientPhysicalSize(sheet);
  final columnLogicalWidth = _labelSheetAxisLogicalTotalSize(
    sheet.columnWidths,
  );
  final rowLogicalHeight = _labelSheetAxisLogicalTotalSize(sheet.rowHeights);
  final countedColumnLogicalWidth = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.columnWidths,
    sheet.columnCount,
    sheet.defaultColWidth,
  );
  final countedRowLogicalHeight = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.rowHeights,
    sheet.rowCount,
    sheet.defaultRowHeight,
  );
  final zoomRatio = sheet.zoomRatio <= 0 ? 1.0 : sheet.zoomRatio;
  final valueSamples = <String>[];
  final anchorSamples = <String>[];
  final coveredSamples = <String>[];
  for (final entry
      in sheet.cells.entries.toList()..sort((left, right) {
        final rowCompare = left.key.row.compareTo(right.key.row);
        return rowCompare == 0
            ? left.key.column.compareTo(right.key.column)
            : rowCompare;
      })) {
    final coord = entry.key;
    final cell = entry.value;
    final value = cell.displayValue ?? cell.value;
    if (value.isNotEmpty && valueSamples.length < 40) {
      valueSamples.add(
        '${_labelSheetCoordLabel(coord.row, coord.column)}=${_labelSheetLogText(value)}',
      );
    }
    final merge = cell.merge;
    if (merge == null) {
      continue;
    }
    final sample =
        '${_labelSheetCoordLabel(coord.row, coord.column)}->'
        '${_labelSheetCoordLabel(merge.row, merge.column)} '
        'span=${merge.rowSpan}x${merge.columnSpan} '
        'value=${_labelSheetLogText(value)} '
        'bg=${cell.background} fc=${cell.foreground}';
    if (merge.row == coord.row && merge.column == coord.column) {
      if (anchorSamples.length < 40) {
        anchorSamples.add(sample);
      }
    } else if (coveredSamples.length < 40) {
      coveredSamples.add(sample);
    }
  }
  debugLog(
    'label sheet import apply sample '
    'rows=${sheet.rowCount} columns=${sheet.columnCount} '
    'cells=${sheet.cells.length} borders=${sheet.borderInfo.length} '
    'zoomRatio=${sheet.zoomRatio} '
    'columnLogicalWidth=$columnLogicalWidth '
    'countedColumnLogicalWidth=$countedColumnLogicalWidth '
    'columnVisibleWidth=${columnLogicalWidth * zoomRatio} '
    'rowLogicalHeight=$rowLogicalHeight '
    'countedRowLogicalHeight=$countedRowLogicalHeight '
    'rowVisibleHeight=${rowLogicalHeight * zoomRatio} '
    'gridWidthMm=${gridSize?.widthMm} gridHeightMm=${gridSize?.heightMm} '
    'values=${valueSamples.join(' | ')} '
    'mergeAnchors=${anchorSamples.join(' | ')} '
    'mergeCovered=${coveredSamples.join(' | ')}',
    skipFrames: 1,
  );
  debugLog(
    'label sheet import apply axis '
    'rowHeights=${_labelSheetAxisSample(sheet.rowHeights)} '
    'columnWidths=${_labelSheetAxisSample(sheet.columnWidths)} '
    'rowBoundaries=${_labelSheetAxisBoundarySample(sheet.rowHeights)} '
    'columnBoundaries=${_labelSheetAxisBoundarySample(sheet.columnWidths)} '
    'rowBoundariesCounted=${_labelSheetAxisBoundarySampleForCount(sheet.rowHeights, sheet.rowCount, sheet.defaultRowHeight)} '
    'columnBoundariesCounted=${_labelSheetAxisBoundarySampleForCount(sheet.columnWidths, sheet.columnCount, sheet.defaultColWidth)}',
    skipFrames: 1,
  );
  _logLabelSheetChunks(
    'label sheet import apply row heights',
    _labelSheetAxisSamples(sheet.rowHeights),
  );
  _logLabelSheetChunks(
    'label sheet import apply column widths',
    _labelSheetAxisSamples(sheet.columnWidths),
  );
  _logLabelSheetChunks(
    'label sheet import apply row boundaries counted',
    _labelSheetAxisBoundarySamplesForCount(
      sheet.rowHeights,
      sheet.rowCount,
      sheet.defaultRowHeight,
    ),
  );
  _logLabelSheetChunks(
    'label sheet import apply column boundaries counted',
    _labelSheetAxisBoundarySamplesForCount(
      sheet.columnWidths,
      sheet.columnCount,
      sheet.defaultColWidth,
    ),
  );
  _logLabelSheetChunks(
    'label sheet import apply merge sizes',
    _labelSheetMergeSizeSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply text layout',
    _labelSheetTextLayoutSamples(sheet),
  );
  debugLog(
    'label sheet import apply border summary '
    'borderInfo=${sheet.borderInfo.length} '
    'hasRawBorderInfo=${sheet.hasRawBorderInfo} '
    'rawBorderInfoType=${sheet.rawBorderInfo.runtimeType} '
    'computedBorders=${FortuneBorderCompute.compute(sheet).length}',
    skipFrames: 1,
  );
  _logLabelSheetChunks(
    'label sheet import apply border info',
    _labelSheetBorderInfoSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply border info rows',
    _labelSheetBorderInfoRowSummarySamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed borders',
    _labelSheetComputedBorderSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed blank borders',
    _labelSheetComputedBlankBorderSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed border rows',
    _labelSheetComputedBorderRowSummarySamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed border row cells',
    _labelSheetComputedBorderRowCellSummarySamples(sheet),
  );
  debugLog(
    'label sheet import apply scale '
    'logicalSize=${columnLogicalWidth}x$rowLogicalHeight '
    'countedLogicalSize=${countedColumnLogicalWidth}x$countedRowLogicalHeight '
    'visibleSize=${columnLogicalWidth * zoomRatio}x${rowLogicalHeight * zoomRatio} '
    'countedVisibleSize=${countedColumnLogicalWidth * zoomRatio}x${countedRowLogicalHeight * zoomRatio} '
    'physicalSizeMm=${gridSize?.widthMm}x${gridSize?.heightMm} '
    'logicalPerMm=${_labelSheetLogicalPerMm(columnLogicalWidth, gridSize?.widthMm)}x'
    '${_labelSheetLogicalPerMm(rowLogicalHeight, gridSize?.heightMm)} '
    'countedLogicalPerMm=${_labelSheetLogicalPerMm(countedColumnLogicalWidth, gridSize?.widthMm)}x'
    '${_labelSheetLogicalPerMm(countedRowLogicalHeight, gridSize?.heightMm)}',
    skipFrames: 1,
  );
}

double _labelSheetAxisLogicalTotalSize(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return 0;
  }
  return sizes.values.fold<double>(0, (sum, size) => sum + size + 1);
}

String _labelSheetAxisSample(Map<int, double> sizes, {int limit = 24}) {
  if (sizes.isEmpty) {
    return '-';
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return entries
      .take(limit)
      .map((entry) => '${entry.key}:${entry.value}')
      .join('|');
}

List<String> _labelSheetAxisSamples(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return const <String>['-'];
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return [for (final entry in entries) '${entry.key}:${entry.value}'];
}

String _labelSheetAxisBoundarySample(Map<int, double> sizes, {int limit = 24}) {
  if (sizes.isEmpty) {
    return '-';
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  var position = 0.0;
  final samples = <String>[];
  for (final entry in entries.take(limit)) {
    position += entry.value + 1;
    samples.add('${entry.key}:$position');
  }
  return samples.join('|');
}

String _labelSheetAxisBoundarySampleForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize, {
  int limit = 30,
}) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return '-';
  }
  var position = 0.0;
  final fallback = defaultSize ?? 0;
  final samples = <String>[];
  final sampleCount = math.min(resolvedCount, limit);
  for (var index = 0; index < sampleCount; index += 1) {
    final size = sizes[index] ?? fallback;
    position += size + 1;
    samples.add('$index:$position($size)');
  }
  if (resolvedCount > limit) {
    samples.add('...count=$resolvedCount');
  }
  return samples.join('|');
}

List<String> _labelSheetAxisBoundarySamplesForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize,
) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return const <String>['-'];
  }
  var position = 0.0;
  final fallback = defaultSize ?? 0;
  final samples = <String>[];
  for (var index = 0; index < resolvedCount; index += 1) {
    final size = sizes[index] ?? fallback;
    position += size + 1;
    samples.add('$index:$position($size)');
  }
  return samples;
}

List<String> _labelSheetMergeSizeSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  final entries = sheet.cells.entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  for (final entry in entries) {
    final merge = entry.value.merge;
    if (merge == null ||
        merge.row != entry.key.row ||
        merge.column != entry.key.column) {
      continue;
    }
    final width = _labelSheetAxisRangeLogicalSize(
      sheet.columnWidths,
      merge.column,
      merge.columnSpan,
      sheet.defaultColWidth,
    );
    final height = _labelSheetAxisRangeLogicalSize(
      sheet.rowHeights,
      merge.row,
      merge.rowSpan,
      sheet.defaultRowHeight,
    );
    final value = entry.value.displayValue ?? entry.value.value;
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'span=${merge.rowSpan}x${merge.columnSpan} logical=${width}x$height '
      'value=${_labelSheetLogText(value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetTextLayoutSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  final entries = sheet.cells.entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  for (final entry in entries) {
    final cell = entry.value;
    final value = cell.displayValue ?? cell.value;
    if (value.isEmpty) {
      continue;
    }
    final merge = cell.merge;
    final isCovered =
        merge != null &&
        (merge.row != entry.key.row || merge.column != entry.key.column);
    if (isCovered) {
      continue;
    }
    final row = merge?.row ?? entry.key.row;
    final column = merge?.column ?? entry.key.column;
    final rowSpan = merge?.rowSpan ?? 1;
    final columnSpan = merge?.columnSpan ?? 1;
    final width = _labelSheetAxisRangeLogicalSize(
      sheet.columnWidths,
      column,
      columnSpan,
      sheet.defaultColWidth,
    );
    final height = _labelSheetAxisRangeLogicalSize(
      sheet.rowHeights,
      row,
      rowSpan,
      sheet.defaultRowHeight,
    );
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'len=${value.length} lines=${_labelSheetLineCount(value)} '
      'span=${rowSpan}x$columnSpan logical=${width}x$height '
      'fs=${cell.fontSize} bold=${cell.bold} wrap=${cell.textWrap} '
      'ha=${cell.horizontalAlign} va=${cell.verticalAlign} '
      'value=${_labelSheetLogText(value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetBorderInfoSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  for (final info in sheet.borderInfo) {
    for (final range in info.ranges) {
      samples.add(
        '${info.borderType} range=${_labelSheetRangeLogText(range)} '
        'style=${info.style} stroke=${info.strokeWidth} '
        'color=${info.color}',
      );
      if (samples.length >= limit) {
        return samples;
      }
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetComputedBorderSamples(
  FortuneSheet sheet, {
  int limit = 1000,
}) {
  final computed = FortuneBorderCompute.compute(sheet).entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  final samples = <String>[];
  for (final entry in computed) {
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      '${_labelSheetCellBordersLogText(entry.value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetComputedBlankBorderSamples(
  FortuneSheet sheet, {
  int limit = 400,
}) {
  final computed = FortuneBorderCompute.compute(sheet).entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  final samples = <String>[];
  for (final entry in computed) {
    final cell = sheet.cells[entry.key];
    final value = cell?.displayValue ?? cell?.value ?? '';
    final merge = cell?.merge;
    final isMergeCovered =
        merge != null &&
        (merge.row != entry.key.row || merge.column != entry.key.column);
    if (value.isNotEmpty || isMergeCovered) {
      continue;
    }
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'state=${_labelSheetComputedBorderCellState(sheet, entry.key)} '
      '${_labelSheetCellBordersLogText(entry.value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetBorderInfoRowSummarySamples(FortuneSheet sheet) {
  final countsByRow = <int, Map<String, int>>{};
  for (final info in sheet.borderInfo) {
    for (final range in info.ranges) {
      for (var row = range.rowStart; row <= range.rowEnd; row += 1) {
        final counts = countsByRow.putIfAbsent(row, () => <String, int>{});
        final key =
            '${info.borderType}/style=${info.style}/stroke=${info.strokeWidth}';
        counts[key] =
            (counts[key] ?? 0) + range.columnEnd - range.columnStart + 1;
      }
    }
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

List<String> _labelSheetComputedBorderRowSummarySamples(FortuneSheet sheet) {
  final countsByRow = <int, Map<String, int>>{};
  final computed = FortuneBorderCompute.compute(sheet);
  for (final entry in computed.entries) {
    final counts = countsByRow.putIfAbsent(
      entry.key.row,
      () => <String, int>{},
    );
    _labelSheetCountComputedBorderSide(counts, 'top', entry.value.top);
    _labelSheetCountComputedBorderSide(counts, 'right', entry.value.right);
    _labelSheetCountComputedBorderSide(counts, 'bottom', entry.value.bottom);
    _labelSheetCountComputedBorderSide(counts, 'left', entry.value.left);
    _labelSheetCountComputedBorderSide(counts, 'slash', entry.value.slash);
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

List<String> _labelSheetComputedBorderRowCellSummarySamples(
  FortuneSheet sheet,
) {
  final countsByRow = <int, Map<String, int>>{};
  final computed = FortuneBorderCompute.compute(sheet);
  for (final coord in computed.keys) {
    final counts = countsByRow.putIfAbsent(coord.row, () => <String, int>{});
    final state = _labelSheetComputedBorderCellState(sheet, coord);
    counts[state] = (counts[state] ?? 0) + 1;
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

String _labelSheetComputedBorderCellState(
  FortuneSheet sheet,
  FortuneCellCoord coord,
) {
  final cell = sheet.cells[coord];
  if (cell == null) {
    return 'noCell';
  }
  final value = cell.displayValue ?? cell.value;
  final merge = cell.merge;
  if (merge != null &&
      (merge.row != coord.row || merge.column != coord.column)) {
    return value.isEmpty ? 'mergeCoveredBlank' : 'mergeCoveredValue';
  }
  if (merge != null) {
    return value.isEmpty ? 'mergeAnchorBlank' : 'mergeAnchorValue';
  }
  return value.isEmpty ? 'blank' : 'value';
}

void _labelSheetCountComputedBorderSide(
  Map<String, int> counts,
  String sideName,
  FortuneBorderSide? side,
) {
  if (side == null) {
    return;
  }
  final key = '$sideName/style=${side.style}/stroke=${side.strokeWidth}';
  counts[key] = (counts[key] ?? 0) + 1;
}

List<String> _labelSheetBorderRowSummaryLogSamples(
  Map<int, Map<String, int>> countsByRow,
) {
  if (countsByRow.isEmpty) {
    return const <String>['-'];
  }
  final samples = <String>[];
  for (final row in countsByRow.keys.toList()..sort()) {
    final counts = countsByRow[row]!;
    final summary = counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    samples.add(
      '${_labelSheetCoordLabel(row, 0).replaceFirst('A', 'row')} '
      '${summary.map((entry) => '${entry.key}:${entry.value}').join(',')}',
    );
  }
  return samples;
}

String _labelSheetRangeLogText(FortuneRange range) {
  return '${_labelSheetCoordLabel(range.rowStart, range.columnStart)}:'
      '${_labelSheetCoordLabel(range.rowEnd, range.columnEnd)} '
      'focus=${range.rowFocus},${range.columnFocus}';
}

String _labelSheetCellBordersLogText(FortuneCellBorders borders) {
  final sides = <String>[];
  if (borders.top != null) {
    sides.add('top=${_labelSheetBorderSideLogText(borders.top!)}');
  }
  if (borders.right != null) {
    sides.add('right=${_labelSheetBorderSideLogText(borders.right!)}');
  }
  if (borders.bottom != null) {
    sides.add('bottom=${_labelSheetBorderSideLogText(borders.bottom!)}');
  }
  if (borders.left != null) {
    sides.add('left=${_labelSheetBorderSideLogText(borders.left!)}');
  }
  if (borders.slash != null) {
    sides.add('slash=${_labelSheetBorderSideLogText(borders.slash!)}');
  }
  return sides.isEmpty ? '-' : sides.join(',');
}

String _labelSheetBorderSideLogText(FortuneBorderSide side) {
  return 'style=${side.style}/stroke=${side.strokeWidth}/color=${side.color}';
}

void _logLabelSheetChunks(String prefix, List<String> samples) {
  const maxChunkLength = 1200;
  var chunk = StringBuffer();
  var chunkIndex = 1;
  var sampleIndex = 0;
  void flush() {
    if (chunk.isEmpty) {
      return;
    }
    debugLog(
      '$prefix chunk=$chunkIndex sampleStart=$sampleIndex ${chunk.toString()}',
      skipFrames: 1,
    );
    chunk = StringBuffer();
    chunkIndex += 1;
  }

  for (var index = 0; index < samples.length; index += 1) {
    final sample = samples[index];
    final next = chunk.isEmpty ? sample : ' | $sample';
    if (chunk.isNotEmpty && chunk.length + next.length > maxChunkLength) {
      flush();
      sampleIndex = index;
    }
    if (chunk.isEmpty) {
      chunk.write(sample);
    } else {
      chunk.write(next);
    }
  }
  flush();
}

double _labelSheetAxisRangeLogicalSize(
  Map<int, double> sizes,
  int start,
  int span,
  double? defaultSize,
) {
  var total = 0.0;
  final fallback = defaultSize ?? 0;
  for (var index = start; index < start + span; index += 1) {
    total += (sizes[index] ?? fallback) + 1;
  }
  return total;
}

String _labelSheetLogicalPerMm(double logicalSize, num? mm) {
  if (mm == null || mm <= 0) {
    return '-';
  }
  return (logicalSize / mm.toDouble()).toStringAsFixed(4);
}

String _labelSheetCoordLabel(int row, int column) {
  var value = column + 1;
  final letters = StringBuffer();
  while (value > 0) {
    value -= 1;
    letters.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return '${letters.toString().split('').reversed.join()}${row + 1}';
}

String _labelSheetLogText(String value) {
  final singleLine = value.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
  return singleLine.length <= 60
      ? singleLine
      : '${singleLine.substring(0, 60)}...';
}

int _labelSheetLineCount(String value) {
  if (value.isEmpty) {
    return 0;
  }
  return '\n'.allMatches(value).length + 1;
}

FortuneSettings labelSheetSettings(
  FortuneSettings base, {
  VoidCallback? onImportLabelImage,
  FutureOr<void> Function()? onSave,
  FutureOr<void> Function()? onImportLabelFile,
  FutureOr<void> Function()? onExportLabelFile,
  Set<String> Function()? contextMenuDisabledItemsBuilder,
  VoidCallback? onPrint,
  FortuneDialogVisibilityChanged? onDialogVisibilityChanged,
  bool saveEnabled = true,
  String importImageTooltip = 'Import label image',
  String saveTooltip = 'Save',
  String printTooltip = 'Print',
  List<String>? toolbarItems,
  bool hideRowColumnHeaders = false,
  bool hideRowColumnHeaderLabels = false,
  bool hideSelectionHighlight = false,
  bool singleClickCellEdit = false,
  bool hidePrintAreaBoundary = false,
  bool fitSingleCellToViewport = false,
  bool rulerCornerSizeLabelUsesAsterisk = false,
  bool disableSheetRulerGuideInteraction = false,
  bool hideStatisticBar = false,
}) {
  final resolvedToolbarItems = toolbarItems ?? labelSheetToolbarItems;
  return base.copyWith(
    toolbarItems: resolvedToolbarItems,
    rowHeaderWidth: hideRowColumnHeaders ? 0 : null,
    columnHeaderHeight: hideRowColumnHeaders ? 0 : null,
    hideRowColumnHeaderLabels: hideRowColumnHeaderLabels,
    hideSelectionHighlight: hideSelectionHighlight,
    singleClickCellEdit: singleClickCellEdit,
    hidePrintAreaBoundary: hidePrintAreaBoundary,
    fitSingleCellToViewport: fitSingleCellToViewport,
    rulerCornerSizeLabelUsesAsterisk: rulerCornerSizeLabelUsesAsterisk,
    disableSheetRulerGuideInteraction: disableSheetRulerGuideInteraction,
    statisticBarHeight: hideStatisticBar ? 0 : null,
    customToolbarItems: [
      if (resolvedToolbarItems.contains(labelSheetSaveToolbarCommand))
        FortuneCustomToolbarItem(
          key: labelSheetSaveToolbarCommand,
          tooltip: saveTooltip,
          iconName: 'save',
          disabled: !saveEnabled,
          onClick: (_) {
            final callback = onSave;
            if (callback == null) {
              fortuneSheetDebugLog('label sheet save toolbar click');
              return;
            }
            unawaited(Future<void>.sync(callback));
          },
        ),
      if (resolvedToolbarItems.contains(labelSheetPrintToolbarCommand))
        FortuneCustomToolbarItem(
          key: labelSheetPrintToolbarCommand,
          tooltip: printTooltip,
          iconName: 'print',
          onClick: (_) {
            final callback = onPrint;
            if (callback == null) {
              fortuneSheetDebugLog('label sheet print toolbar click');
              return;
            }
            callback();
          },
        ),
    ],
    cellContextMenu: labelSheetContextMenuItems(base.cellContextMenu),
    headerContextMenu: labelSheetContextMenuItems(
      base.headerContextMenu,
      includeImportLabelImage: true,
    ),
    sheetTabContextMenu: labelSheetContextMenuItems(base.sheetTabContextMenu),
    filterContextMenu: labelSheetContextMenuItems(base.filterContextMenu),
    onDialogVisibilityChanged: onDialogVisibilityChanged,
    onContextMenuCommand: (command) {
      if (command == fortuneContextImportLabelImageCommand) {
        final callback = onImportLabelImage;
        if (callback == null) {
          fortuneSheetDebugLog('label sheet import image context click');
          return null;
        }
        callback();
        return null;
      }
      if (command == fortuneContextImportLabelFileCommand) {
        final callback = onImportLabelFile;
        if (callback == null) {
          fortuneSheetDebugLog('label sheet import label file context click');
          return null;
        }
        return callback();
      }
      if (command != fortuneContextExportLabelFileCommand) {
        return null;
      }
      final callback = onExportLabelFile;
      if (callback == null) {
        fortuneSheetDebugLog('label sheet export label file context click');
        return null;
      }
      return callback();
    },
    contextMenuDisabledItemsBuilder: contextMenuDisabledItemsBuilder,
  );
}

class LabelSheetWorkbench extends StatefulWidget {
  const LabelSheetWorkbench({
    this.initialWorkbook,
    this.labelSize,
    this.labelRtf,
    this.imageObjectIds = const <String>[],
    this.barcodeObjectIds = const <String>[],
    this.toolbarItems,
    this.hideRowColumnHeaders = false,
    this.hideRowColumnHeaderLabels = false,
    this.hideSelectionHighlight = false,
    this.singleClickCellEdit = false,
    this.hidePrintAreaBoundary = false,
    this.fitSingleCellToViewport = false,
    this.rulerCornerSizeLabelUsesAsterisk = false,
    this.disableSheetRulerGuideInteraction = false,
    this.hideStatisticBar = false,
    this.zoomToolbarPlacement = LabelSheetZoomToolbarPlacement.sheetToolbarEnd,
    this.onInitialLoadComplete,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
    this.printerListProvider,
    this.onWorkbookChanged,
    this.onSave,
    super.key,
  });

  final FortuneWorkbook? initialWorkbook;
  final LabelSize? labelSize;
  final String? labelRtf;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final List<String>? toolbarItems;
  final bool hideRowColumnHeaders;
  final bool hideRowColumnHeaderLabels;
  final bool hideSelectionHighlight;
  final bool singleClickCellEdit;
  final bool hidePrintAreaBoundary;
  final bool fitSingleCellToViewport;
  final bool rulerCornerSizeLabelUsesAsterisk;
  final bool disableSheetRulerGuideInteraction;
  final bool hideStatisticBar;
  final LabelSheetZoomToolbarPlacement zoomToolbarPlacement;
  final VoidCallback? onInitialLoadComplete;
  final ValueChanged<ui.Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;
  final LabelPrinterListProvider? printerListProvider;
  final ValueChanged<FortuneWorkbook>? onWorkbookChanged;
  final FutureOr<void> Function(
    int widthMm,
    int heightMm,
    String encodedWorkbook,
  )?
  onSave;

  @override
  State<LabelSheetWorkbench> createState() => _LabelSheetWorkbenchState();
}

class _LabelSheetWorkbenchState extends State<LabelSheetWorkbench>
    with WidgetsBindingObserver {
  late final FortuneWorkbook _fallbackWorkbook = labelSheetWorkbook(
    _baseWorkbook,
    labelSize: widget.labelSize,
    labelRtf: widget.labelRtf,
  );
  late final Future<FortuneWorkbook> _initialWorkbook =
      labelSheetWorkbookWithRtf(
        _baseWorkbook,
        labelSize: widget.labelSize,
        labelRtf: widget.labelRtf,
      );
  late final FortuneSheetController _controller = FortuneSheetController();
  late final TextEditingController _zoomController = TextEditingController(
    text: '$labelSheetDefaultZoomPercent',
  );
  late final TextEditingController _printLeftMarginController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printTopMarginController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printExtraAreaController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printCopiesController =
      TextEditingController(text: '1');
  late final FocusNode _zoomFocusNode = FocusNode();
  final LayerLink _zoomToolbarLayerLink = LayerLink();
  OverlayEntry? _zoomToolbarOverlayEntry;
  int? _zoomEditOriginalPercent;
  bool _zoomCommitPendingBlur = false;
  late FortuneSheetLocale _locale = _localeForPlatform();
  late FortuneWorkbook _latestWorkbook = _fallbackWorkbook;
  int _zoomPercent = labelSheetDefaultZoomPercent;
  bool _isDirty = false;
  bool _rtfSnackBarVisible = false;
  int _rtfSnackBarGeneration = 0;
  bool _rtfImportMarkedDirty = false;
  bool _initialLoadCompleteNotified = false;
  bool _initialWorkbookOpsSettled = false;
  bool _printSettingsDialogOpen = false;
  BuildContext? _printSettingsDialogContext;
  VoidCallback? _rebuildPrintSettingsDialog;
  String _printAutoSpacing = 'none';
  String _printOrientation = 'horizontal';
  String _printSelectedPrinterName = '';

  FortuneWorkbook get _baseWorkbook =>
      widget.initialWorkbook ??
      FortuneWorkbook(
        sheets: [FortuneSheet(id: 'label_sheet_01', name: 'Labels')],
      );

  FortuneSettings _sheetSettings(
    FortuneWorkbook workbook,
  ) => labelSheetSettings(
    workbook.settings,
    onImportLabelImage: _handleImportLabelImage,
    onSave: _handleSave,
    onImportLabelFile: _handleImportLabelFile,
    onExportLabelFile: _handleExportLabelFile,
    contextMenuDisabledItemsBuilder: _labelFileContextMenuDisabledItems,
    onPrint: _handlePrint,
    onDialogVisibilityChanged: _handleFortuneDialogVisibilityChanged,
    saveEnabled: _isDirty,
    importImageTooltip: _labelSheetImportImageTooltip(),
    saveTooltip: _labelSheetSaveTooltip(),
    printTooltip: _labelSheetPrintTooltip(),
    toolbarItems: widget.toolbarItems,
    hideRowColumnHeaders: widget.hideRowColumnHeaders,
    hideRowColumnHeaderLabels: widget.hideRowColumnHeaderLabels,
    hideSelectionHighlight: widget.hideSelectionHighlight,
    singleClickCellEdit: widget.singleClickCellEdit,
    hidePrintAreaBoundary: widget.hidePrintAreaBoundary,
    fitSingleCellToViewport: widget.fitSingleCellToViewport,
    rulerCornerSizeLabelUsesAsterisk: widget.rulerCornerSizeLabelUsesAsterisk,
    disableSheetRulerGuideInteraction: widget.disableSheetRulerGuideInteraction,
    hideStatisticBar: widget.hideStatisticBar,
  );

  FortuneSheetGridClientPhysicalSize? get _gridClientSize {
    final common = widget.labelSize?.labelSizeCommon;
    if (common == null) {
      return const FortuneSheetGridClientPhysicalSize(
        widthMm: _labelSheetDefaultPhysicalWidthMm,
        heightMm: _labelSheetDefaultPhysicalHeightMm,
      );
    }
    return FortuneSheetGridClientPhysicalSize(
      widthMm: _labelSheetPositivePhysicalSizeOrDefault(
        common.width,
        _labelSheetDefaultPhysicalWidthMm,
      ),
      heightMm: _labelSheetPositivePhysicalSizeOrDefault(
        common.height,
        _labelSheetDefaultPhysicalHeightMm,
      ),
    );
  }

  void _notifyGridRectChanged(
    Size size,
    FortuneWorkbook workbook,
    FortuneSettings settings,
  ) {
    final callback = widget.onGridRectChanged;
    if (callback == null) {
      return;
    }
    final gridRect = _gridRect(size, workbook, settings);
    if (gridRect == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) {
        return;
      }
      callback(gridRect.shift(box.localToGlobal(Offset.zero)));
    });
  }

  ui.Rect? _gridRect(
    Size size,
    FortuneWorkbook workbook,
    FortuneSettings settings,
  ) {
    final sheet = workbook.activeSheet;
    if (fortuneSheetGridClientPhysicalSize(sheet) == null) {
      return null;
    }
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final footerHeight =
        settings.effectiveSheetBarHeight + settings.statisticBarHeight;
    final dataLeft = settings.rowHeaderWidth * 2;
    final dataTop = settings.columnHeaderHeight * 2;
    final metrics = sheet.metrics(settings);
    var dataWidth = math.max(0.0, size.width - dataLeft);
    var dataHeight = math.max(
      0.0,
      size.height - sheetTop - footerHeight - dataTop,
    );
    var vertical = metrics.rowTotalHeight > dataHeight;
    var horizontal = metrics.columnTotalWidth > dataWidth;
    if (vertical) {
      dataWidth = math.max(0.0, dataWidth - fortuneSheetScrollbarThickness);
    }
    if (horizontal) {
      dataHeight = math.max(0.0, dataHeight - fortuneSheetScrollbarThickness);
    }
    if (!vertical && metrics.rowTotalHeight > dataHeight) {
      dataWidth = math.max(0.0, dataWidth - fortuneSheetScrollbarThickness);
    }
    if (!horizontal && metrics.columnTotalWidth > dataWidth) {
      dataHeight = math.max(0.0, dataHeight - fortuneSheetScrollbarThickness);
    }
    final width = math.min(math.max(0.0, metrics.columnTotalWidth), dataWidth);
    final height = math.min(math.max(0.0, metrics.rowTotalHeight), dataHeight);
    if (width <= 0 || height <= 0) {
      return null;
    }
    return ui.Rect.fromLTWH(dataLeft, sheetTop + dataTop, width, height);
  }

  @override
  void initState() {
    super.initState();
    _zoomFocusNode
      ..addListener(_handleZoomFocusChanged)
      ..onKeyEvent = _handleZoomInputKeyEvent;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _removeZoomToolbarFloatingOverlay();
    if (_rtfSnackBarVisible) {
      _rtfSnackBarVisible = false;
      final generation = ++_rtfSnackBarGeneration;
      fortuneSheetDebugLog(
        'rtf snackbar dispose hide generation=$generation '
        'labelSizeId=${widget.labelSize?.labelSizeId} '
        'rtfLen=${widget.labelRtf?.length ?? 0} '
        'rtfHash=${widget.labelRtf?.hashCode ?? 0}',
      );
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
    _zoomController.dispose();
    _printLeftMarginController.dispose();
    _printTopMarginController.dispose();
    _printExtraAreaController.dispose();
    _printCopiesController.dispose();
    _zoomFocusNode.removeListener(_handleZoomFocusChanged);
    _zoomFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LabelSheetWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoomToolbarPlacement != widget.zoomToolbarPlacement &&
        widget.zoomToolbarPlacement !=
            LabelSheetZoomToolbarPlacement.previewTabAreaEnd) {
      _removeZoomToolbarFloatingOverlay();
    }
  }

  void _setLabelSheetZoomPercent(int percent) {
    final clamped = percent.clamp(
      labelSheetMinZoomPercent,
      labelSheetMaxZoomPercent,
    );
    if (_zoomController.text != '$clamped') {
      _zoomController.text = '$clamped';
      _zoomController.selection = TextSelection.collapsed(
        offset: _zoomController.text.length,
      );
    }
    if (_zoomPercent == clamped) {
      return;
    }
    setState(() {
      _zoomPercent = clamped;
    });
    _controller.setZoomRatio(clamped / 100);
  }

  void _syncLabelSheetZoomPercent(FortuneWorkbook workbook) {
    if (_zoomFocusNode.hasFocus) {
      return;
    }
    final percent = _labelSheetZoomPercentForWorkbook(workbook);
    if (_zoomPercent == percent && _zoomController.text == '$percent') {
      return;
    }
    _zoomPercent = percent;
    if (_zoomController.text != '$percent') {
      _zoomController.text = '$percent';
      _zoomController.selection = TextSelection.collapsed(
        offset: _zoomController.text.length,
      );
    }
  }

  int _labelSheetZoomPercentForWorkbook(FortuneWorkbook workbook) {
    final zoomRatio = workbook.activeSheet.zoomRatio <= 0
        ? 1.0
        : workbook.activeSheet.zoomRatio;
    return (zoomRatio * 100).round().clamp(
      labelSheetMinZoomPercent,
      labelSheetMaxZoomPercent,
    );
  }

  void _stepLabelSheetZoom(int deltaPercent) {
    final current = int.tryParse(_zoomController.text) ?? _zoomPercent;
    _setLabelSheetZoomPercent(current + deltaPercent);
  }

  void _commitLabelSheetZoomInput() {
    final value = int.tryParse(_zoomController.text);
    _zoomCommitPendingBlur = true;
    _setLabelSheetZoomPercent(value ?? labelSheetDefaultZoomPercent);
    _zoomFocusNode.unfocus();
  }

  void _handleZoomFocusChanged() {
    if (_zoomFocusNode.hasFocus) {
      _zoomEditOriginalPercent = _zoomPercent;
      _zoomCommitPendingBlur = false;
      return;
    }
    if (_zoomCommitPendingBlur) {
      _zoomCommitPendingBlur = false;
      _zoomEditOriginalPercent = null;
      return;
    }
    _restoreLabelSheetZoomInput();
  }

  KeyEventResult _handleZoomInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _restoreLabelSheetZoomInput();
    node.unfocus();
    return KeyEventResult.handled;
  }

  void _restoreLabelSheetZoomInput() {
    final restored = _zoomEditOriginalPercent ?? _zoomPercent;
    _zoomEditOriginalPercent = null;
    _zoomCommitPendingBlur = false;
    if (_zoomController.text == '$restored') {
      return;
    }
    _zoomController.text = '$restored';
    _zoomController.selection = TextSelection.collapsed(
      offset: _zoomController.text.length,
    );
  }

  void _syncRtfSnackBar(bool visible) {
    if (_rtfSnackBarVisible == visible) {
      return;
    }
    _rtfSnackBarVisible = visible;
    final generation = ++_rtfSnackBarGeneration;
    fortuneSheetDebugLog(
      'rtf snackbar sync visible=$visible generation=$generation '
      'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId} '
      'rtfLen=${widget.labelRtf?.length ?? 0} '
      'rtfHash=${widget.labelRtf?.hashCode ?? 0}',
    );
    // messenger 를 addPostFrameCallback 실행 전에 캡처한다.
    // 콜백 실행 시점에 위젯이 파기(dispose)되어 mounted=false 이더라도
    // hide(visible=false) 는 반드시 수행해야 스낵바가 무한 표시되지 않는다.
    final capturedMessenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _rtfSnackBarGeneration) {
        fortuneSheetDebugLog(
          'rtf snackbar postFrame stale visible=$visible '
          'generation=$generation current=$_rtfSnackBarGeneration '
          'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        return;
      }
      if (visible) {
        // SHOW: 위젯이 살아 있어야 context 로 showSnackBar 를 호출할 수 있다.
        if (!mounted) {
          fortuneSheetDebugLog(
            'rtf snackbar show skipped unmounted generation=$generation '
            'labelSizeId=${widget.labelSize?.labelSizeId}',
          );
          return;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          fortuneSheetDebugLog(
            'rtf snackbar show skipped noMessenger generation=$generation '
            'labelSizeId=${widget.labelSize?.labelSizeId}',
          );
          return;
        }
        fortuneSheetDebugLog(
          'rtf snackbar show generation=$generation '
          'labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        messenger.clearSnackBars();
        showSnackBar(
          context,
          'RTF를 변환 중입니다...',
          type: SnackBarType.inProgress,
          duration: const Duration(days: 1),
        );
      } else {
        // HIDE: 위젯이 파기된 후에도 반드시 스낵바를 닫아야 한다.
        // mounted 체크 없이 캡처된 messenger 로 직접 닫는다.
        fortuneSheetDebugLog(
          'rtf snackbar hide generation=$generation '
          'hasMessenger=${capturedMessenger != null} '
          'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        capturedMessenger?.hideCurrentSnackBar();
      }
    });
  }

  void _markRtfImportDirtyIfNeeded(FortuneWorkbook workbook) {
    if (_rtfImportMarkedDirty || _isDirty) {
      return;
    }
    if (!labelSheetLooksLikeRichEditRtf(widget.labelRtf)) {
      return;
    }
    if (!_workbookHasRtfImportSource(workbook)) {
      return;
    }
    _rtfImportMarkedDirty = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDirty) {
        return;
      }
      setState(() {
        _isDirty = true;
      });
    });
  }

  bool _workbookHasRtfImportSource(FortuneWorkbook workbook) {
    if (workbook.sheets.isEmpty) {
      return false;
    }
    final activeIndex = workbook.activeSheetIndex.clamp(
      0,
      workbook.sheets.length - 1,
    );
    return workbook.sheets[activeIndex].extraFields['labelRtfImportSource'] ==
        true;
  }

  bool _opsClearSheet(List<FortuneOp> ops) {
    return ops.any((op) => op['op'] == 'clearSheet');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {
      _locale = FortuneSheetLocale.forLocale(
        locales?.isNotEmpty == true
            ? locales!.first
            : WidgetsBinding.instance.platformDispatcher.locale,
      );
    });
  }

  FortuneSheetLocale _localeForPlatform() {
    return FortuneSheetLocale.forLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  String _labelSheetImportImageTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '라벨 이미지 가져오기' : 'Import label image';
  }

  String _labelSheetPrintTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '인쇄' : 'Print';
  }

  String _labelSheetSaveTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '저장' : 'Save';
  }

  Future<void> _handleImportLabelImage() async {
    const imageGroup = XTypeGroup(
      label: 'Label image',
      extensions: <String>['png', 'jpg', 'jpeg', 'bmp', 'webp'],
      mimeTypes: <String>['image/*'],
    );
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[imageGroup],
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || !mounted) {
      return;
    }
    final sheet = _controller.getSheet();
    if (sheet == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('활성 라벨 시트를 찾을 수 없습니다.')));
      }
      return;
    }
    final mimeType = _labelSheetMimeTypeForName(file.name);
    final action = await _showLabelImageImportDialog(
      bytes: bytes,
      mimeType: mimeType,
      fileName: file.name,
      sheet: sheet,
    );
    if (!mounted || action == null) {
      return;
    }
    if (action.saveCredentials) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_labelSheetGeminiApiKeyPrefsKey, action.apiKey);
      await prefs.setString(_labelSheetGeminiModelPrefsKey, action.model);
    }
    final draft = action.draft;
    if (draft == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 분석할 수 없습니다.')));
      }
      return;
    }
    try {
      final xlsxFile = await _writeLabelImageImportXlsxFile(draft, file.name);
      final xlsxName = p.basename(xlsxFile.path);
      final importedWorkbook = await _readImportedLabelWorkbook(
        XFile(
          xlsxFile.path,
          name: xlsxName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      await _applyImportedLabelWorkbook(
        importedWorkbook,
        fileName: xlsxName,
        filePath: xlsxFile.path,
        updateImportDirectory: false,
        successMessage: 'AI 분석 결과를 엑셀로 가져왔습니다: $xlsxName',
      );
    } catch (e, stackTrace) {
      debugLog(
        'label image import xlsx auto import failed: '
        'name=${file.name} error=$e\n$stackTrace',
        skipFrames: 1,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 분석 결과를 엑셀로 가져올 수 없습니다.')),
      );
    }
  }

  Future<File> _writeLabelImageImportXlsxFile(
    LabelSheetImageImportDraft draft,
    String sourceFileName,
  ) async {
    final baseName = p.basenameWithoutExtension(sourceFileName).trim();
    final safeBaseName = baseName.isEmpty
        ? 'label_image'
        : baseName.replaceAll(RegExp(r'[^0-9A-Za-z가-힣._-]+'), '_');
    final directory = await labelSheetAiImportTempDirectory().create(
      recursive: true,
    );
    final path = p.join(
      directory.path,
      'label_manager_ai_import_${DateTime.now().microsecondsSinceEpoch}_$safeBaseName.xlsx',
    );
    return labelSheetWriteDraftOpenXmlTestFile(draft, path: path);
  }

  void _handlePrint() {
    unawaited(_openPrintSettingsDialog());
  }

  Future<void> _openPrintSettingsDialog() async {
    fortuneSheetDebugLog('label sheet print toolbar click');
    if (_printSettingsDialogOpen) {
      return;
    }
    await _notifyBeforeSheetDialog();
    if (!mounted) {
      return;
    }
    final preferredPrintSettings =
        await LabelPrinterPreferences.loadPreferredPrintSettings(
          listPrinters: widget.printerListProvider,
        );
    if (!mounted) {
      return;
    }
    _applyPrintSettingsPreference(preferredPrintSettings);
    setState(() {
      _printSettingsDialogOpen = true;
    });
    fortuneSheetDebugLog('label sheet print dialog route show');
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            _printSettingsDialogContext = dialogContext;
            _rebuildPrintSettingsDialog = () => setDialogState(() {});
            return _buildPrintSettingsDialog();
          },
        );
      },
    );
    _printSettingsDialogContext = null;
    _rebuildPrintSettingsDialog = null;
    if (mounted && _printSettingsDialogOpen) {
      setState(() {
        _printSettingsDialogOpen = false;
      });
      widget.onSheetDialogClosed?.call();
    }
  }

  void _applyPrintSettingsPreference(
    LabelSheetPreferredPrintSettings? settings,
  ) {
    _printLeftMarginController.text = settings?.leftMargin ?? '0.0';
    _printTopMarginController.text = settings?.topMargin ?? '0.0';
    _printExtraAreaController.text = settings?.extraArea ?? '0.0';
    _printCopiesController.text = '1';
    _printAutoSpacing = settings?.autoSpacing ?? 'none';
    _printOrientation = settings?.orientation ?? 'horizontal';
    _printSelectedPrinterName = settings?.printerName ?? '';
  }

  LabelSheetPreferredPrintSettings? _currentPrintSettingsPreference() {
    final printerName = _printSelectedPrinterName.trim();
    if (printerName.isEmpty) {
      return null;
    }
    return LabelSheetPreferredPrintSettings(
      printerName: printerName,
      leftMargin: _printLeftMarginController.text,
      topMargin: _printTopMarginController.text,
      autoSpacing: _printAutoSpacing,
      extraArea: _printExtraAreaController.text,
      orientation: _printOrientation,
    );
  }

  Future<void> _handleApplyPrintSettings() async {
    final settings = _currentPrintSettingsPreference();
    if (settings == null) {
      return;
    }
    await LabelPrinterPreferences.savePreferredPrintSettings(settings);
  }

  Future<void> _handleIssuePrintSettings() async {
    final printer = await _selectedPrintSettingsPrinter();
    if (!mounted) {
      return;
    }
    if (printer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('발행할 프린터를 선택하세요.')));
      return;
    }
    final sheet = _controller.getSheet();
    final physicalSize = sheet == null
        ? null
        : fortuneSheetGridClientPhysicalSize(sheet);
    if (sheet == null || physicalSize == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 출력 영역을 찾을 수 없습니다.')));
      return;
    }

    final options = _currentPrintOptions();
    final dpi = await _printDpiForPrinter(printer);
    final capture = await _controller.captureRangeAsPng(
      _labelSheetPrintRange(sheet, physicalSize),
      pixelRatio: dpi / fortuneSheetLogicalPixelsPerInch,
      includeGridLines: false,
      includeCellBorders: true,
      includeRulerGuides: false,
      includeLabelAreaBoundary: false,
    );
    if (!mounted) {
      return;
    }
    if (capture == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 생성할 수 없습니다.')));
      return;
    }

    final metrics = LabelSheetPrintPageMetrics(
      labelWidthMm: physicalSize.widthMm,
      labelHeightMm: physicalSize.heightMm,
      dpi: dpi,
    );
    final pdfBytes = await buildLabelSheetPdfBytes(
      pngBytes: capture.pngBytes,
      metrics: metrics,
      options: options,
    );
    final profile = detectPrinterProfile(printer);
    var printed = false;
    if (profile.canSendRaw && profile.language == PrinterLanguage.ezpl) {
      try {
        final ezplBytes = await buildLabelSheetHybridEzplBytes(
          sheet: sheet,
          range: _labelSheetPrintRange(sheet, physicalSize),
          fallbackPngBytes: capture.pngBytes,
          metrics: metrics,
          options: options,
        );
        await RawPrinterWin32.sendRaw(printer, ezplBytes);
        printed = true;
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('EZPL 출력 실패, 일반 인쇄창으로 전환합니다: $error')),
          );
        }
      }
    }
    if (printed || !mounted) {
      return;
    }
    await Printing.directPrintPdf(
      printer: printer,
      name: 'ITSnG_Label_${DateTime.now().millisecondsSinceEpoch}',
      onLayout: (_) async => pdfBytes,
    );
  }

  Future<Printer?> _selectedPrintSettingsPrinter() async {
    final selectedName = _printSelectedPrinterName.trim();
    if (selectedName.isEmpty) {
      return null;
    }
    final printers =
        await (widget.printerListProvider ?? Printing.listPrinters)();
    final normalizedSelected = selectedName.toLowerCase();
    for (final printer in printers) {
      if (printer.name.trim().toLowerCase() == normalizedSelected) {
        return printer;
      }
    }
    return null;
  }

  Future<double> _printDpiForPrinter(Printer printer) async {
    if (Platform.isWindows) {
      final dpi = await RawPrinterWin32.queryPrinterDpi(printer);
      if (dpi != null && dpi > 0) {
        return dpi.toDouble();
      }
    }
    return detectPrinterProfile(printer).dpi ?? 203;
  }

  LabelSheetPrintOptions _currentPrintOptions() {
    return LabelSheetPrintOptions(
      copies: math.max(
        1,
        int.tryParse(_printCopiesController.text.trim()) ?? 1,
      ),
      leftMarginMm: _doubleFromPrintInput(_printLeftMarginController.text),
      topMarginMm: _doubleFromPrintInput(_printTopMarginController.text),
      extraAreaMm: _doubleFromPrintInput(_printExtraAreaController.text),
      autoSpacingPercent: _printAutoSpacing == 'none'
          ? null
          : int.tryParse(_printAutoSpacing),
      orientation: _printOrientation == 'vertical'
          ? LabelSheetPrintOrientation.vertical
          : LabelSheetPrintOrientation.horizontal,
    );
  }

  double _doubleFromPrintInput(String value) {
    return math.max(0, double.tryParse(value.trim()) ?? 0);
  }

  FortuneRange _labelSheetPrintRange(
    FortuneSheet sheet,
    FortuneSheetGridClientPhysicalSize physicalSize,
  ) {
    final logicalSize = physicalSize.logicalSize;
    return FortuneRange(
      rowStart: 0,
      rowEnd: _lastPrintIndexForExtent(
        logicalSize.height,
        lengthForIndex: (row) =>
            sheet.rowHeights[row] ?? sheet.defaultRowHeight ?? 19,
      ),
      columnStart: 0,
      columnEnd: _lastPrintIndexForExtent(
        logicalSize.width,
        lengthForIndex: (column) =>
            sheet.columnWidths[column] ?? sheet.defaultColWidth ?? 73,
      ),
    );
  }

  int _lastPrintIndexForExtent(
    double extent, {
    required double Function(int index) lengthForIndex,
  }) {
    if (extent <= 0) {
      return 0;
    }
    var offset = 0.0;
    var index = 0;
    while (offset < extent) {
      offset += lengthForIndex(index);
      if (offset >= extent) {
        return index;
      }
      index += 1;
    }
    return index;
  }

  void _closePrintSettingsDialog() {
    if (!_printSettingsDialogOpen) {
      return;
    }
    fortuneSheetDebugLog('label sheet print dialog close');
    setState(() {
      _printSettingsDialogOpen = false;
    });
    final dialogContext = _printSettingsDialogContext;
    if (dialogContext != null) {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    }
    widget.onSheetDialogClosed?.call();
  }

  Future<void> _notifyBeforeSheetDialog() async {
    _controller.clearHoverState();
    final callback = widget.onBeforeSheetDialog;
    if (callback != null) {
      await Future<void>.sync(callback);
    }
  }

  void _handleFortuneDialogVisibilityChanged(bool open) {
    if (open) {
      unawaited(_notifyBeforeSheetDialog());
      return;
    }
    widget.onSheetDialogClosed?.call();
  }

  Future<void> _handleSelectPrinter() async {
    final printerName = Platform.isWindows
        ? await RawPrinterWin32.showPrinterSetupDialog()
        : (await Printing.pickPrinter(context: context, title: '프린터 선택'))?.name;
    if (!mounted || printerName == null || printerName.isEmpty) {
      return;
    }
    setState(() {
      _printSelectedPrinterName = printerName;
    });
    _rebuildPrintSettingsDialog?.call();
  }

  Future<void> _handleSave() async {
    fortuneSheetDebugLog('label sheet save toolbar click');
    final callback = widget.onSave;
    if (callback == null) {
      return;
    }
    final payload = _encodedWorkbookForCurrentLabelFile();
    try {
      await Future<void>.sync(
        () => callback(
          payload.widthMm,
          payload.heightMm,
          payload.encodedWorkbook,
        ),
      );
    } catch (e) {
      fortuneSheetDebugLog('label sheet save failed: $e');
      return;
    }
    if (mounted) {
      setState(() {
        _isDirty = false;
      });
    }
  }

  ({int widthMm, int heightMm, String encodedWorkbook})
  _encodedWorkbookForCurrentLabelFile() {
    final workbook = _currentWorkbookForLabelFile();
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(workbook.activeSheet) ??
        _gridClientSize ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    return (
      widthMm: physicalSize.widthMm,
      heightMm: physicalSize.heightMm,
      encodedWorkbook: labelSheetEncodeWorkbookSave(
        labelSheetWorkbookForPrintAreaSave(workbook),
      ),
    );
  }

  FortuneWorkbook _currentWorkbookForLabelFile() {
    final sheets = _controller.getAllSheets();
    return sheets == null
        ? _latestWorkbook
        : _latestWorkbook.copyWith(sheets: sheets);
  }

  Set<String> _labelFileContextMenuDisabledItems() {
    return _currentLabelFileHasContent()
        ? const <String>{}
        : const <String>{fortuneContextExportLabelFileCommand};
  }

  bool _currentLabelFileHasContent() {
    final workbook = labelSheetWorkbookForPrintAreaSave(
      _currentWorkbookForLabelFile(),
    );
    final sheet = workbook.activeSheet;
    return sheet.cells.isNotEmpty ||
        sheet.borderInfo.isNotEmpty ||
        sheet.images.isNotEmpty ||
        sheet.dataVerification.isNotEmpty ||
        sheet.hyperlinks.isNotEmpty;
  }

  Future<void> _handleExportLabelFile() async {
    fortuneSheetDebugLog('label sheet export label file context click');
    if (!_currentLabelFileHasContent()) {
      return;
    }
    const labelFileGroup = XTypeGroup(
      label: 'Label Manager Sheet',
      extensions: <String>['lms'],
      mimeTypes: <String>['application/octet-stream'],
    );
    final prefs = await SharedPreferences.getInstance();
    final initialDirectory = prefs.getString(_labelFileDirectoryPrefsKey);
    final suggestedName = _suggestedLabelFileName();
    final location = await getSaveLocation(
      acceptedTypeGroups: const <XTypeGroup>[labelFileGroup],
      suggestedName: suggestedName,
      initialDirectory: initialDirectory?.isNotEmpty == true
          ? initialDirectory
          : null,
    );
    if (location == null) {
      return;
    }
    final path = _ensureLabelFileExtension(location.path);
    final payload = _encodedWorkbookForCurrentLabelFile();
    await File(path).writeAsString(payload.encodedWorkbook, flush: true);
    final directory = p.dirname(path);
    if (directory.isNotEmpty) {
      await prefs.setString(_labelFileDirectoryPrefsKey, directory);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('라벨 파일을 내보냈습니다: ${p.basename(path)}')),
    );
  }

  Future<void> _handleImportLabelFile() async {
    fortuneSheetDebugLog('label sheet import label file context click');
    debugLog('label sheet import picker open', skipFrames: 1);
    const labelFileGroup = XTypeGroup(
      label: 'Label Manager Sheet / Excel Workbook',
      extensions: <String>['lms', 'xlsx'],
      mimeTypes: <String>['application/octet-stream'],
    );
    final prefs = await SharedPreferences.getInstance();
    final initialDirectory = prefs.getString(_labelFileDirectoryPrefsKey);
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[labelFileGroup],
      initialDirectory: initialDirectory?.isNotEmpty == true
          ? initialDirectory
          : null,
    );
    if (file == null) {
      debugLog('label sheet import picker canceled', skipFrames: 1);
      return;
    }
    debugLog(
      'label sheet import file selected '
      'name=${file.name} path=${file.path} '
      'pathExt=${p.extension(file.path)} nameExt=${p.extension(file.name)}',
      skipFrames: 1,
    );
    await _importLabelFileFromXFile(file, prefs: prefs);
  }

  Future<void> _importLabelFileFromXFile(
    XFile file, {
    SharedPreferences? prefs,
    bool updateImportDirectory = true,
    String? successMessage,
  }) async {
    FortuneWorkbook importedWorkbook;
    try {
      importedWorkbook = await _readImportedLabelWorkbook(file);
    } catch (e, stackTrace) {
      debugLog(
        'label sheet import label file failed: '
        'name=${file.name} path=${file.path} error=$e\n$stackTrace',
        skipFrames: 1,
      );
      fortuneSheetDebugLog(
        'label sheet import label file failed: '
        'name=${file.name} path=${file.path} error=$e\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일을 읽을 수 없습니다.')));
      return;
    }
    if (importedWorkbook.sheets.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일에 시트가 없습니다.')));
      return;
    }
    await _applyImportedLabelWorkbook(
      importedWorkbook,
      fileName: file.name,
      filePath: file.path,
      prefs: prefs,
      updateImportDirectory: updateImportDirectory,
      successMessage: successMessage,
    );
  }

  Future<void> _applyImportedLabelWorkbook(
    FortuneWorkbook importedWorkbook, {
    required String fileName,
    required String filePath,
    SharedPreferences? prefs,
    bool updateImportDirectory = true,
    String? successMessage,
  }) async {
    if (importedWorkbook.sheets.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일에 시트가 없습니다.')));
      return;
    }
    if (updateImportDirectory && filePath.isNotEmpty) {
      final directory = p.dirname(filePath);
      if (directory.isNotEmpty) {
        final targetPrefs = prefs ?? await SharedPreferences.getInstance();
        await targetPrefs.setString(_labelFileDirectoryPrefsKey, directory);
      }
    }
    final importExtension =
        (p.extension(filePath).isNotEmpty
                ? p.extension(filePath)
                : p.extension(fileName))
            .toLowerCase();
    final scaleToPhysicalWidth = importExtension == '.xlsx';
    final currentSheet = _currentWorkbookForLabelFile().activeSheet;
    final rawImportedGridSize = fortuneSheetGridClientPhysicalSize(
      importedWorkbook.activeSheet,
    );
    final currentGridSize = fortuneSheetGridClientPhysicalSize(currentSheet);
    final sizedImportedSheet = _labelSheetWithPreservedGridClientSize(
      importedWorkbook.activeSheet.copyWith(
        id: currentSheet.id,
        name: currentSheet.name,
        order: currentSheet.order,
        zoomRatio: 1,
        rawZoomRatio: null,
        hasRawZoomRatio: false,
      ),
      currentSheet,
    );
    final importedSheet = scaleToPhysicalWidth
        ? _labelSheetScaledToPhysicalWidth(
            sizedImportedSheet,
            currentSheet: currentSheet,
          )
        : sizedImportedSheet;
    final importedGridSize = fortuneSheetGridClientPhysicalSize(importedSheet);
    debugLog(
      'label sheet import apply sheet '
      'rows=${importedSheet.rowCount} columns=${importedSheet.columnCount} '
      'cells=${importedSheet.cells.length} '
      'scaleToPhysicalWidth=$scaleToPhysicalWidth '
      'sourceGridWidthMm=${rawImportedGridSize?.widthMm} '
      'sourceGridHeightMm=${rawImportedGridSize?.heightMm} '
      'currentGridWidthMm=${currentGridSize?.widthMm} '
      'currentGridHeightMm=${currentGridSize?.heightMm} '
      'gridWidthMm=${importedGridSize?.widthMm} '
      'gridHeightMm=${importedGridSize?.heightMm}',
      skipFrames: 1,
    );
    _logImportedSheetApplySample(importedSheet);
    _controller.clearSheet(
      id: currentSheet.id,
      rowCount: importedSheet.rowCount,
      columnCount: importedSheet.columnCount,
    );
    _controller.updateSheet(<FortuneSheet>[importedSheet]);
    _setLabelSheetZoomPercent(100);
    _controller.unfocusSheet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.unfocusSheet();
    });
    if (!mounted) {
      return;
    }
    setState(() {
      _isDirty = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage ?? '라벨 파일을 가져왔습니다: $fileName')),
    );
  }

  Future<FortuneWorkbook> _readImportedLabelWorkbook(XFile file) async {
    final extension = _importedLabelFileExtension(file);
    debugLog(
      'label sheet import read start '
      'name=${file.name} path=${file.path} extension=$extension',
      skipFrames: 1,
    );
    if (extension == '.xlsx') {
      final bytes = await file.readAsBytes();
      debugLog(
        'label sheet import read xlsx by extension bytes=${bytes.length}',
        skipFrames: 1,
      );
      return labelSheetNormalizeWorkbookForCurrentSaveFormat(
        labelSheetWorkbookFromXlsxBytes(bytes),
      );
    }
    if (extension == '.lms') {
      debugLog('label sheet import read lms by extension', skipFrames: 1);
      return labelSheetDecodeWorkbookSaveBytes(await file.readAsBytes());
    }
    final bytes = await file.readAsBytes();
    debugLog(
      'label sheet import read unknown extension bytes=${bytes.length}',
      skipFrames: 1,
    );
    if (labelSheetLooksLikeXlsx(bytes)) {
      debugLog('label sheet import detected xlsx by bytes', skipFrames: 1);
      return labelSheetNormalizeWorkbookForCurrentSaveFormat(
        labelSheetWorkbookFromXlsxBytes(bytes),
      );
    }
    debugLog(
      'label sheet import fallback to lms decode by bytes',
      skipFrames: 1,
    );
    return labelSheetDecodeWorkbookSaveBytes(bytes);
  }

  String _importedLabelFileExtension(XFile file) {
    final pathExtension = p.extension(file.path).toLowerCase();
    if (pathExtension.isNotEmpty) {
      return pathExtension;
    }
    return p.extension(file.name).toLowerCase();
  }

  String _suggestedLabelFileName() {
    final name = widget.labelSize?.labelSizeName.trim();
    return _ensureLabelFileExtension(
      name?.isNotEmpty == true ? name! : 'label',
    );
  }

  String _ensureLabelFileExtension(String path) {
    return p.extension(path).toLowerCase() == '.lms'
        ? path
        : p.setExtension(path, '.lms');
  }

  Widget _buildZoomToolbarOverlay() {
    if (widget.zoomToolbarPlacement == LabelSheetZoomToolbarPlacement.hidden) {
      return const SizedBox.shrink();
    }
    final inPreviewTabArea =
        widget.zoomToolbarPlacement ==
        LabelSheetZoomToolbarPlacement.previewTabAreaEnd;
    if (inPreviewTabArea) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 6,
      right: 12,
      height: 29,
      child: _buildZoomToolbarControls(inPreviewTabArea: false),
    );
  }

  Widget _buildZoomToolbarControls({required bool inPreviewTabArea}) {
    return ColoredBox(
      color: inPreviewTabArea
          ? const Color(0xFFF7F8FA)
          : const Color(0xfffafafc),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelSheetZoomButton(
            label: '-',
            onPressed: () => _stepLabelSheetZoom(-10),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 42,
            height: 25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xffffffff),
                border: Border.all(color: const Color(0xffd4d4d4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: EditableText(
                  key: const ValueKey('label-sheet-zoom-input'),
                  controller: _zoomController,
                  focusNode: _zoomFocusNode,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: Color(0xff222222),
                  ),
                  cursorColor: const Color(0xff0188fb),
                  cursorOffset: Offset.zero,
                  backgroundCursorColor: const Color(0x330188fb),
                  maxLines: 1,
                  onSubmitted: (_) => _commitLabelSheetZoomInput(),
                  onEditingComplete: _commitLabelSheetZoomInput,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            '%',
            style: TextStyle(fontSize: 13, color: Color(0xff222222)),
          ),
          const SizedBox(width: 4),
          _LabelSheetZoomButton(
            label: '+',
            onPressed: () => _stepLabelSheetZoom(10),
          ),
        ],
      ),
    );
  }

  void _syncZoomToolbarFloatingOverlay() {
    if (widget.zoomToolbarPlacement !=
        LabelSheetZoomToolbarPlacement.previewTabAreaEnd) {
      _removeZoomToolbarFloatingOverlay();
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final entry = _zoomToolbarOverlayEntry;
    if (entry != null) {
      entry.markNeedsBuild();
      return;
    }
    _zoomToolbarOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: CompositedTransformFollower(
            link: _zoomToolbarLayerLink,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(-12, -34),
            showWhenUnlinked: false,
            child: Align(
              alignment: Alignment.topRight,
              widthFactor: 1,
              heightFactor: 1,
              child: SizedBox(
                height: 29,
                child: _buildZoomToolbarControls(inPreviewTabArea: true),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_zoomToolbarOverlayEntry!);
  }

  void _removeZoomToolbarFloatingOverlay() {
    _zoomToolbarOverlayEntry?.remove();
    _zoomToolbarOverlayEntry = null;
  }

  Future<_LabelImageImportAction?> _showLabelImageImportDialog({
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
    required FortuneSheet sheet,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _notifyBeforeSheetDialog();
    if (!mounted) {
      return null;
    }
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(sheet) ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    try {
      return await showDialog<_LabelImageImportAction>(
        context: context,
        barrierDismissible: false,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        builder: (_) => _LabelImageImportDialog(
          bytes: bytes,
          mimeType: mimeType,
          fileName: fileName,
          sheet: sheet,
          physicalSize: physicalSize,
          initialApiKey: prefs.getString(_labelSheetGeminiApiKeyPrefsKey) ?? '',
          initialModel:
              prefs.getString(_labelSheetGeminiModelPrefsKey) ??
              labelSheetDefaultGeminiModel,
        ),
      );
    } finally {
      widget.onSheetDialogClosed?.call();
    }
  }

  static String _labelSheetMimeTypeForName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'bmp' => 'image/bmp',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<FortuneWorkbook>(
          future: _initialWorkbook,
          initialData: _fallbackWorkbook,
          builder: (context, snapshot) {
            final workbook = snapshot.data ?? _fallbackWorkbook;
            final sheetSettings = _sheetSettings(workbook);
            if (!_isDirty) {
              _latestWorkbook = workbook.copyWith(settings: sheetSettings);
            }
            _syncLabelSheetZoomPercent(workbook);
            final convertingRtf =
                labelSheetLooksLikeRichEditRtf(widget.labelRtf) &&
                snapshot.connectionState != ConnectionState.done;
            _syncRtfSnackBar(convertingRtf);
            if (!convertingRtf &&
                snapshot.connectionState == ConnectionState.done) {
              _markRtfImportDirtyIfNeeded(workbook);
              if (!_initialWorkbookOpsSettled) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _initialWorkbookOpsSettled = true;
                  }
                });
              }
              if (!labelSheetLooksLikeRichEditRtf(widget.labelRtf) ||
                  _workbookHasRtfImportSource(workbook)) {
                _notifyInitialLoadComplete();
              }
            }
            final sheet = FortuneSheetApp(
              workbook: workbook,
              settings: sheetSettings,
              controller: _controller,
              onChange: (workbook) {
                _latestWorkbook = workbook;
                _syncLabelSheetZoomPercent(workbook);
                widget.onWorkbookChanged?.call(workbook);
              },
              onOp: (ops) {
                if (ops.isEmpty || !mounted) {
                  return;
                }
                if (!_initialWorkbookOpsSettled) {
                  return;
                }
                if (_opsClearSheet(ops)) {
                  if (_isDirty) {
                    setState(() {
                      _isDirty = false;
                    });
                  }
                  return;
                }
                if (_isDirty) {
                  return;
                }
                setState(() {
                  _isDirty = true;
                });
              },
              locale: _locale,
              barcodeRenderer: labelSheetBarcodeRenderer,
              barcodeFormats: labelSheetBarcodeFormats,
              imageObjectIds: widget.imageObjectIds,
              barcodeObjectIds: widget.barcodeObjectIds,
              gridClientSize: _gridClientSize,
              showFormulaBar: false,
              showSheetTabs: false,
            );
            _notifyGridRectChanged(
              constraints.biggest,
              workbook,
              sheetSettings,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _syncZoomToolbarFloatingOverlay();
              }
            });
            return CompositedTransformTarget(
              link: _zoomToolbarLayerLink,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  sheet,
                  _buildZoomToolbarOverlay(),
                  if (convertingRtf)
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        child: AbsorbPointer(
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrintSettingsDialog() {
    return BlockingModelessDialog(
      child: BlockingModelessDialogFrame(
        title: '프린터 설정',
        width: 526,
        height: 236,
        closeIcon: const _PrintDialogCloseIcon(),
        onClose: _closePrintSettingsDialog,
        child: _ClosedLoopDialogFocus(
          child: _LabelSheetPrintSettingsDialog(
            leftMarginController: _printLeftMarginController,
            topMarginController: _printTopMarginController,
            extraAreaController: _printExtraAreaController,
            copiesController: _printCopiesController,
            autoSpacing: _printAutoSpacing,
            orientation: _printOrientation,
            selectedPrinterName: _printSelectedPrinterName,
            onAutoSpacingChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _printAutoSpacing = value;
              });
              _rebuildPrintSettingsDialog?.call();
            },
            onOrientationChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _printOrientation = value;
              });
              _rebuildPrintSettingsDialog?.call();
            },
            onSelectPrinter: _handleSelectPrinter,
            onIssue: () => unawaited(_handleIssuePrintSettings()),
            onApply: () => unawaited(_handleApplyPrintSettings()),
            onClose: _closePrintSettingsDialog,
          ),
        ),
      ),
    );
  }

  void _notifyInitialLoadComplete() {
    if (_initialLoadCompleteNotified) {
      return;
    }
    _initialLoadCompleteNotified = true;
    final callback = widget.onInitialLoadComplete;
    if (callback == null) {
      return;
    }
    // messenger 를 캡처해 위젯 파기 후에도 스낵바를 닫을 수 있도록 한다.
    final capturedMessenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 스낵바 닫기는 mounted 무관하게 항상 수행한다.
      capturedMessenger?.hideCurrentSnackBar();
      if (!mounted) return;
      callback();
    });
  }
}

class _ClosedLoopDialogFocus extends StatelessWidget {
  const _ClosedLoopDialogFocus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Builder(
        builder: (dialogFocusContext) {
          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
              SingleActivator(LogicalKeyboardKey.tab, shift: true):
                  PreviousFocusIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (intent) {
                    _moveFocusWithinDialog(dialogFocusContext, forward: true);
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (intent) {
                    _moveFocusWithinDialog(dialogFocusContext, forward: false);
                    return null;
                  },
                ),
              },
              child: FocusTraversalGroup(child: child),
            ),
          );
        },
      ),
    );
  }

  static void _moveFocusWithinDialog(
    BuildContext context, {
    required bool forward,
  }) {
    final scope = FocusScope.of(context);
    final nodes = scope.traversalDescendants
        .where((node) => node.canRequestFocus && !node.skipTraversal)
        .toList(growable: false);
    if (nodes.isEmpty) {
      return;
    }
    final current = FocusManager.instance.primaryFocus;
    var index = current == null ? -1 : nodes.indexOf(current);
    if (index < 0 && current != null) {
      index = nodes.indexWhere((node) => current.ancestors.contains(node));
    }
    final targetIndex = forward
        ? (index + 1) % nodes.length
        : (index <= 0 ? nodes.length - 1 : index - 1);
    nodes[targetIndex].requestFocus();
  }
}

class _LabelSheetZoomButton extends StatefulWidget {
  const _LabelSheetZoomButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_LabelSheetZoomButton> createState() => _LabelSheetZoomButtonState();
}

class _LabelSheetZoomButtonState extends State<_LabelSheetZoomButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _pressed
        ? const Color(0xffdfe5f2)
        : _hovered
        ? const Color(0xffedf2fb)
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(3),
          ),
          child: SizedBox(
            width: 23,
            height: 25,
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1,
                  color: Color(0xff5f6368),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelImageImportDialog extends StatefulWidget {
  const _LabelImageImportDialog({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    required this.sheet,
    required this.physicalSize,
    required this.initialApiKey,
    required this.initialModel,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final FortuneSheet sheet;
  final FortuneSheetGridClientPhysicalSize physicalSize;
  final String initialApiKey;
  final String initialModel;

  @override
  State<_LabelImageImportDialog> createState() =>
      _LabelImageImportDialogState();
}

class _LabelImageImportDialogState extends State<_LabelImageImportDialog> {
  late final TextEditingController _apiKeyController = TextEditingController(
    text: widget.initialApiKey,
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.initialModel,
  );
  late final TextEditingController _promptController = TextEditingController(
    text: '',
  );
  bool _saveCredentials = false;
  bool _analyzing = false;
  String? _errorLog;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.78;
    return BlockingModelessDialogFrame(
      title: '라벨 이미지 가져오기',
      width: 640,
      height: dialogHeight,
      closeIcon: const _LabelImageImportCloseIcon(),
      onClose: _analyzing ? () {} : () => Navigator.of(context).pop(),
      footer: _buildFooter(),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.fileName} · 현재 시트 '
                '${widget.physicalSize.widthMm} x '
                '${widget.physicalSize.heightMm} mm',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: widgets.Image.memory(
                      widget.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ApiKeyPasteOnlyTextField(
                controller: _apiKeyController,
                enabled: !_analyzing,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _labelSheetSelectedGeminiModelValue(
                  _modelController.text,
                  labelSheetGeminiModels,
                ),
                isExpanded: true,
                decoration: _compactInputDecoration('Gemini Model'),
                items: [
                  for (final model in labelSheetGeminiModels)
                    DropdownMenuItem(
                      value: model.modelId,
                      child: Text(model.menuLabel),
                    ),
                ],
                onChanged: _analyzing
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _modelController.text = value;
                      },
              ),
              const SizedBox(height: 12),
              _compactTextField(
                controller: _promptController,
                labelText: '변환 프롬프트(mm 기준)',
                enabled: !_analyzing,
                minLines: 4,
                maxLines: 6,
                alignLabelWithHint: true,
              ),
              _ErrorLogPanel(message: _errorLog),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _saveCredentials,
                    visualDensity: VisualDensity.compact,
                    onChanged: _analyzing
                        ? null
                        : (value) {
                            setState(() {
                              _saveCredentials = value ?? false;
                            });
                          },
                  ),
                  const Expanded(
                    child: Text('Gemini API Key와 model을 이 PC에 저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 84,
            height: 30,
            child: _LabelImageImportFooterButton(
              label: '취소',
              onPressed: _analyzing ? null : () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 112,
            height: 30,
            child: _LabelImageImportFooterButton(
              label: _analyzing ? '분석 중...' : 'AI 분석 적용',
              onPressed: _analyzing ? null : _applyGeminiAnalysis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactTextField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    bool obscureText = false,
    bool alignLabelWithHint = false,
    int? minLines,
    int? maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      decoration: _compactInputDecoration(
        labelText,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }

  Future<void> _applyGeminiAnalysis() async {
    setState(() {
      _analyzing = true;
      _errorLog = null;
    });
    try {
      final draft = await labelSheetAnalyzeImageWithGemini(
        LabelSheetGeminiImportRequest(
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim(),
          prompt: _promptController.text,
          imageBytes: widget.bytes,
          mimeType: widget.mimeType,
          fileName: widget.fileName,
          sheet: widget.sheet,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        _LabelImageImportAction(
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim(),
          saveCredentials: _saveCredentials,
          draft: draft,
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _analyzing = false;
        _errorLog = '$error';
      });
    }
  }
}

class _BlockedApiKeyClipboardIntent extends Intent {
  const _BlockedApiKeyClipboardIntent();
}

class _ApiKeyPasteOnlyTextField extends StatelessWidget {
  const _ApiKeyPasteOnlyTextField({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, control: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
            const _BlockedApiKeyClipboardIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BlockedApiKeyClipboardIntent:
              CallbackAction<_BlockedApiKeyClipboardIntent>(
                onInvoke: (_) => null,
              ),
        },
        child: TextField(
          controller: controller,
          enabled: enabled,
          obscureText: true,
          enableInteractiveSelection: true,
          contextMenuBuilder: _apiKeyPasteOnlyContextMenuBuilder,
          decoration: _compactInputDecoration('Gemini API Key'),
        ),
      ),
    );
  }
}

Widget _apiKeyPasteOnlyContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final buttonItems = editableTextState.contextMenuButtonItems
      .where(
        (item) =>
            item.type != ContextMenuButtonType.copy &&
            item.type != ContextMenuButtonType.cut,
      )
      .toList(growable: false);
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

class _LabelImageImportFooterButton extends StatelessWidget {
  const _LabelImageImportFooterButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F3F4),
        foregroundColor: const Color(0xff111111),
        side: const BorderSide(color: Color(0xffc7c7c7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _LabelImageImportCloseIcon extends StatelessWidget {
  const _LabelImageImportCloseIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _LabelImageImportCloseIconPainter(),
    );
  }
}

class _LabelImageImportCloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glyphRect = ui.Rect.fromCenter(
      center: ui.Offset(size.width / 2, size.height / 2),
      width: 11,
      height: 11,
    );
    final paint = Paint()
      ..color = const Color(0xff9a9a9a)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(glyphRect.topLeft, glyphRect.bottomRight, paint);
    canvas.drawLine(glyphRect.topRight, glyphRect.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _LabelImageImportCloseIconPainter oldDelegate) {
    return false;
  }
}

class _LabelSheetPrintSettingsDialog extends StatelessWidget {
  const _LabelSheetPrintSettingsDialog({
    required this.leftMarginController,
    required this.topMarginController,
    required this.extraAreaController,
    required this.copiesController,
    required this.autoSpacing,
    required this.orientation,
    required this.selectedPrinterName,
    required this.onAutoSpacingChanged,
    required this.onOrientationChanged,
    required this.onSelectPrinter,
    required this.onIssue,
    required this.onApply,
    required this.onClose,
  });

  final TextEditingController leftMarginController;
  final TextEditingController topMarginController;
  final TextEditingController extraAreaController;
  final TextEditingController copiesController;
  final String autoSpacing;
  final String orientation;
  final String selectedPrinterName;
  final ValueChanged<String?> onAutoSpacingChanged;
  final ValueChanged<String?> onOrientationChanged;
  final VoidCallback onSelectPrinter;
  final VoidCallback onIssue;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('label-sheet-print-settings-dialog'),
      width: 526,
      height: 200,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 8,
            width: 300,
            height: 58,
            child: _PrintDialogGroup(
              title: '여백',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 7),
                  const _PrintDialogCenteredLabel('왼쪽'),
                  const SizedBox(width: 8),
                  _PrintDialogShiftedDown(
                    child: _PrintDialogInput(controller: leftMarginController),
                  ),
                  const SizedBox(width: 8),
                  const _PrintDialogCenteredLabel('mm'),
                  const SizedBox(width: 24),
                  const _PrintDialogCenteredLabel('위쪽'),
                  const SizedBox(width: 8),
                  _PrintDialogShiftedDown(
                    child: _PrintDialogInput(controller: topMarginController),
                  ),
                  const SizedBox(width: 8),
                  const _PrintDialogCenteredLabel('mm'),
                ],
              ),
            ),
          ),
          Positioned(
            left: 336,
            top: 8,
            width: 168,
            height: 58,
            child: _PrintDialogGroup(
              title: '자동줄간격',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  SizedBox(
                    width: _autoSpacingDropdownWidth,
                    height: _compactDropdownHeight,
                    child: DropdownButton2<String>(
                      value: autoSpacing,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      style: _labelStyle,
                      items: _autoSpacingItems,
                      onChanged: onAutoSpacingChanged,
                      buttonStyleData: const ButtonStyleData(
                        height: _compactDropdownHeight,
                        padding: EdgeInsets.zero,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 260,
                        useRootNavigator: true,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: _compactDropdownMenuItemHeight,
                        padding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      iconStyleData: const IconStyleData(
                        iconSize: 18,
                        iconEnabledColor: Color(0xff6a6a6a),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const _PrintDialogCenteredLabel('%'),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 24,
            top: 81,
            child: Text('발행 프린터', style: _sectionStyle),
          ),
          Positioned(
            left: 107,
            top: 74,
            width: 291,
            height: 30,
            child: _PrintDialogInsetValue(value: selectedPrinterName),
          ),
          Positioned(
            right: 22,
            top: 74,
            width: 94,
            height: 30,
            child: _PrintDialogButton(
              label: '프린터 선택',
              onPressed: onSelectPrinter,
            ),
          ),
          Positioned(
            left: 104,
            top: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _PrintDialogCenteredLabel('추가 영역'),
                const SizedBox(width: 8),
                _PrintDialogShiftedDown(
                  child: _PrintDialogInput(controller: extraAreaController),
                ),
                const SizedBox(width: 8),
                const _PrintDialogCenteredLabel('mm'),
              ],
            ),
          ),
          Positioned(
            left: 322,
            top: 118,
            child: Row(
              children: [
                _PrintDialogRadio(
                  label: '가로',
                  value: 'horizontal',
                  groupValue: orientation,
                  onChanged: onOrientationChanged,
                ),
                const SizedBox(width: 18),
                _PrintDialogRadio(
                  label: '세로',
                  value: 'vertical',
                  groupValue: orientation,
                  onChanged: onOrientationChanged,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 24,
            top: 149,
            child: Text(
              '매수',
              style: TextStyle(fontSize: 30, color: Color(0xff000000)),
            ),
          ),
          Positioned(
            left: 91,
            top: 151,
            width: 84,
            height: 38,
            child: _PrintDialogInput(
              controller: copiesController,
              fontSize: 23,
              height: 38,
              contentPadding: const EdgeInsets.fromLTRB(8, 3, 8, 5),
            ),
          ),
          Positioned(
            left: 245,
            bottom: 12,
            width: 84,
            height: 30,
            child: _PrintDialogButton(label: '취소', onPressed: onClose),
          ),
          Positioned(
            left: 334,
            bottom: 12,
            width: 84,
            height: 30,
            child: _PrintDialogButton(label: '적용', onPressed: onApply),
          ),
          Positioned(
            left: 423,
            bottom: 12,
            width: 84,
            height: 30,
            child: _PrintDialogButton(label: '발행', onPressed: onIssue),
          ),
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(fontSize: 13, color: Color(0xff111111));

  static const _sectionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xff111111),
  );
  static const double _compactDropdownHeight = 28;
  static const double _compactDropdownMenuItemHeight = 28;
  static const double _autoSpacingDropdownWidth = 117;

  static final List<DropdownMenuItem<String>> _autoSpacingItems = [
    const DropdownMenuItem(
      value: 'none',
      child: _PrintDialogDropdownItemLabel('간격조정 없음'),
    ),
    for (var value = 80; value <= 300; value += 5)
      DropdownMenuItem(
        value: '$value',
        child: _PrintDialogDropdownItemLabel('$value'),
      ),
  ];
}

class _PrintDialogDropdownItemLabel extends StatelessWidget {
  const _PrintDialogDropdownItemLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: _LabelSheetPrintSettingsDialog._labelStyle),
      ),
    );
  }
}

class _PrintDialogCloseIcon extends StatelessWidget {
  const _PrintDialogCloseIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _PrintDialogCloseIconPainter(),
    );
  }
}

class _PrintDialogCloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glyphRect = ui.Rect.fromCenter(
      center: ui.Offset(size.width / 2, size.height / 2),
      width: 11,
      height: 11,
    );
    final paint = Paint()
      ..color = const Color(0xff9a9a9a)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(glyphRect.topLeft, glyphRect.bottomRight, paint);
    canvas.drawLine(glyphRect.topRight, glyphRect.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant _PrintDialogCloseIconPainter oldDelegate) {
    return false;
  }
}

class _PrintDialogCenteredLabel extends StatelessWidget {
  const _PrintDialogCenteredLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: Text(label, style: _LabelSheetPrintSettingsDialog._labelStyle),
      ),
    );
  }
}

class _PrintDialogShiftedDown extends StatelessWidget {
  const _PrintDialogShiftedDown({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(offset: const Offset(0, 3), child: child);
  }
}

class _PrintDialogInsetValue extends StatelessWidget {
  const _PrintDialogInsetValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffd4d4d4)),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: _LabelSheetPrintSettingsDialog._labelStyle,
          ),
        ),
      ),
    );
  }
}

class _PrintDialogGroup extends StatelessWidget {
  const _PrintDialogGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 6,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd8d8d8)),
            ),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
        Positioned(
          left: 8,
          top: -3,
          child: ColoredBox(
            color: const Color(0xffece6f0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                style: _LabelSheetPrintSettingsDialog._labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrintDialogInput extends StatelessWidget {
  const _PrintDialogInput({
    required this.controller,
    this.fontSize = 13,
    this.height,
    this.contentPadding = const EdgeInsets.fromLTRB(5, 2, 5, 3),
  });

  final TextEditingController controller;
  final double fontSize;
  final double? height;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fontSize > 20 ? 84 : 56,
      height: height ?? (fontSize > 20 ? 56 : 28),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: fontSize, color: const Color(0xff111111)),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xffffffff),
          contentPadding: contentPadding,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffc7c7c7)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff0067c0), width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _PrintDialogButton extends StatelessWidget {
  const _PrintDialogButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xffffffff),
        foregroundColor: const Color(0xff111111),
        side: const BorderSide(color: Color(0xffc7c7c7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _PrintDialogRadio extends StatelessWidget {
  const _PrintDialogRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xff0067c0)
                    : const Color(0xff7a7a7a),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff0067c0),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Text(label, style: _LabelSheetPrintSettingsDialog._labelStyle),
        ],
      ),
    );
  }
}

InputDecoration _compactInputDecoration(
  String labelText, {
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: labelText,
    alignLabelWithHint: alignLabelWithHint,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
}

class _ErrorLogPanel extends StatelessWidget {
  const _ErrorLogPanel({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

String? _labelSheetSelectedGeminiModelValue(
  String current,
  List<LabelSheetGeminiModelInfo> models,
) {
  for (final model in models) {
    if (model.modelId == current) {
      return model.modelId;
    }
  }
  return null;
}

class _LabelImageImportAction {
  const _LabelImageImportAction({
    required this.apiKey,
    required this.model,
    required this.saveCredentials,
    this.draft,
  });

  final String apiKey;
  final String model;
  final bool saveCredentials;
  final LabelSheetImageImportDraft? draft;
}
