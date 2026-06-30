import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_ai_import.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_import_model.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool labelSheetWriteRtfOpenXmlTestFileEnabled = false;
const String labelSheetImportImageToolbarCommand = 'label-sheet-import-image';
const String labelSheetSaveToolbarCommand = 'label-sheet-save';
const String labelSheetPrintToolbarCommand = 'label-sheet-print';
const int labelSheetDefaultZoomPercent = 100;
const int labelSheetMinZoomPercent = 10;
const int labelSheetMaxZoomPercent = 400;
const String _labelSheetCopilotTokenPrefsKey = 'label_sheet_copilot_token';
const String _labelSheetCopilotModelPrefsKey = 'label_sheet_copilot_model';

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

List<String> labelSheetContextMenuItems(List<String> base) {
  final visible = fortuneMenuItemsWithout(
    base,
    labelSheetHiddenContextMenuItems,
  );
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
  final widthMm = common?.width ?? 100;
  final heightMm = common?.height ?? 100;
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

FortuneSettings labelSheetSettings(
  FortuneSettings base, {
  VoidCallback? onImportLabelImage,
  FutureOr<void> Function()? onSave,
  VoidCallback? onPrint,
  bool saveEnabled = true,
  String importImageTooltip = 'Import label image',
  String saveTooltip = 'Save',
  String printTooltip = 'Print',
}) {
  return base.copyWith(
    toolbarItems: labelSheetToolbarItems,
    customToolbarItems: [
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
    headerContextMenu: labelSheetContextMenuItems(base.headerContextMenu),
    sheetTabContextMenu: labelSheetContextMenuItems(base.sheetTabContextMenu),
    filterContextMenu: labelSheetContextMenuItems(base.filterContextMenu),
  );
}

class LabelSheetWorkbench extends StatefulWidget {
  const LabelSheetWorkbench({
    this.initialWorkbook,
    this.labelSize,
    this.labelRtf,
    this.barcodeObjectIds = const <String>[],
    this.onInitialLoadComplete,
    this.onGridRectChanged,
    this.onSave,
    super.key,
  });

  final FortuneWorkbook? initialWorkbook;
  final LabelSize? labelSize;
  final String? labelRtf;
  final List<String> barcodeObjectIds;
  final VoidCallback? onInitialLoadComplete;
  final ValueChanged<ui.Rect>? onGridRectChanged;
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
  int? _zoomEditOriginalPercent;
  bool _zoomCommitPendingBlur = false;
  late FortuneSheetLocale _locale = _localeForPlatform();
  late FortuneWorkbook _latestWorkbook = _fallbackWorkbook;
  int _zoomPercent = labelSheetDefaultZoomPercent;
  bool _isDirty = false;
  bool _rtfSnackBarVisible = false;
  bool _rtfImportMarkedDirty = false;
  bool _initialLoadCompleteNotified = false;
  bool _printSettingsDialogOpen = false;
  String _printAutoSpacing = 'none';
  String _printOrientation = 'horizontal';
  String _printSelectedPrinterName = '';

  FortuneWorkbook get _baseWorkbook =>
      widget.initialWorkbook ??
      FortuneWorkbook(
        sheets: [FortuneSheet(id: 'label_sheet_01', name: 'Labels')],
      );

  FortuneSettings _sheetSettings(FortuneWorkbook workbook) =>
      labelSheetSettings(
        workbook.settings,
        onImportLabelImage: _handleImportLabelImage,
        onSave: _handleSave,
        onPrint: _handlePrint,
        saveEnabled: _isDirty,
        importImageTooltip: _labelSheetImportImageTooltip(),
        saveTooltip: _labelSheetSaveTooltip(),
        printTooltip: _labelSheetPrintTooltip(),
      );

  FortuneSheetGridClientPhysicalSize? get _gridClientSize {
    final common = widget.labelSize?.labelSizeCommon;
    if (common == null) {
      return const FortuneSheetGridClientPhysicalSize(
        widthMm: 100,
        heightMm: 100,
      );
    }
    return FortuneSheetGridClientPhysicalSize(
      widthMm: common.width,
      heightMm: common.height,
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
    if (_rtfSnackBarVisible) {
      _rtfSnackBarVisible = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      if (visible) {
        showSnackBar(
          context,
          'RTF를 변환 중입니다...',
          type: SnackBarType.inProgress,
          duration: const Duration(days: 1),
        );
      } else {
        messenger.hideCurrentSnackBar();
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
    if (action.saveToken) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_labelSheetCopilotTokenPrefsKey, action.token);
      await prefs.setString(_labelSheetCopilotModelPrefsKey, action.model);
    }
    LabelSheetImageImportDraft? draft;
    if (action.useCopilot) {
      draft = action.draft;
      if (draft == null) {
        return;
      }
    } else {
      draft = labelSheetAnalyzeImageImport(
        bytes,
        sheet: sheet,
        mimeType: mimeType,
        fileName: file.name,
      );
    }
    if (draft == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 분석할 수 없습니다.')));
      }
      return;
    }
    const settings = FortuneSettings();
    final clearedSheet = labelSheetClearBeforeImageImport(
      sheet,
      rowCount: settings.row,
      columnCount: settings.column,
    );
    _controller.updateSheet([
      labelSheetApplyImageImportDraft(
        clearedSheet,
        draft,
        minRowCount: settings.row,
        minColumnCount: settings.column,
      ),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${action.useCopilot ? 'AI' : '기본'} 라벨 이미지 분석 완료: '
            '${draft.rowHeights.length}행 x '
            '${draft.columnWidths.length}열',
          ),
        ),
      );
    }
  }

  void _handlePrint() {
    fortuneSheetDebugLog('label sheet print toolbar click');
    setState(() {
      _printSettingsDialogOpen = true;
    });
  }

  void _closePrintSettingsDialog() {
    if (!_printSettingsDialogOpen) {
      return;
    }
    setState(() {
      _printSettingsDialogOpen = false;
    });
  }

  Future<void> _handleSelectPrinter() async {
    final printerName = Platform.isWindows
        ? await RawPrinterWin32.showPrinterSetupDialog()
        : (await Printing.pickPrinter(context: context, title: '프린터 선택'))
              ?.name;
    if (!mounted || printerName == null || printerName.isEmpty) {
      return;
    }
    setState(() {
      _printSelectedPrinterName = printerName;
    });
  }

  Future<void> _handleSave() async {
    fortuneSheetDebugLog('label sheet save toolbar click');
    final callback = widget.onSave;
    if (callback == null) {
      return;
    }
    final sheets = _controller.getAllSheets();
    final workbook = sheets == null
        ? _latestWorkbook
        : _latestWorkbook.copyWith(sheets: sheets);
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(workbook.activeSheet) ??
        _gridClientSize ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    final encoded = labelSheetEncodeWorkbookSave(
      labelSheetWorkbookForPrintAreaSave(workbook),
    );
    try {
      await Future<void>.sync(
        () => callback(
          physicalSize.widthMm,
          physicalSize.heightMm,
          encoded,
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

  Widget _buildZoomToolbarOverlay() {
    return Positioned(
      top: 6,
      right: 12,
      height: 29,
      child: ColoredBox(
        color: const Color(0xfffafafc),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
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
      ),
    );
  }

  Future<_LabelImageImportAction?> _showLabelImageImportDialog({
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
    required FortuneSheet sheet,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return null;
    }
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(sheet) ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    return showDialog<_LabelImageImportAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LabelImageImportDialog(
        bytes: bytes,
        mimeType: mimeType,
        fileName: fileName,
        sheet: sheet,
        physicalSize: physicalSize,
        initialToken: prefs.getString(_labelSheetCopilotTokenPrefsKey) ?? '',
        initialModel:
            prefs.getString(_labelSheetCopilotModelPrefsKey) ??
            labelSheetDefaultCopilotModel,
      ),
    );
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
            final convertingRtf =
                labelSheetLooksLikeRichEditRtf(widget.labelRtf) &&
                snapshot.connectionState != ConnectionState.done;
            _syncRtfSnackBar(convertingRtf);
            if (!convertingRtf &&
                snapshot.connectionState == ConnectionState.done) {
              _markRtfImportDirtyIfNeeded(workbook);
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
              },
              onOp: (ops) {
                if (ops.isEmpty || !mounted) {
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
            return Stack(
              fit: StackFit.expand,
              children: [
                sheet,
                _buildZoomToolbarOverlay(),
                if (_printSettingsDialogOpen) _buildPrintSettingsDialog(),
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
            );
          },
        );
      },
    );
  }

  Widget _buildPrintSettingsDialog() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Center(
          child: GestureDetector(
            onTap: () {},
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
              },
              onOrientationChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _printOrientation = value;
                });
              },
              onSelectPrinter: _handleSelectPrinter,
              onClose: _closePrintSettingsDialog,
            ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback();
    });
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
    required this.initialToken,
    required this.initialModel,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final FortuneSheet sheet;
  final FortuneSheetGridClientPhysicalSize physicalSize;
  final String initialToken;
  final String initialModel;

  @override
  State<_LabelImageImportDialog> createState() =>
      _LabelImageImportDialogState();
}

class _LabelImageImportDialogState extends State<_LabelImageImportDialog> {
  late final TextEditingController _tokenController = TextEditingController(
    text: widget.initialToken,
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.initialModel,
  );
  late final TextEditingController _promptController = TextEditingController(
    text:
        '현재 조정 시트 ${widget.physicalSize.widthMm}x'
        '${widget.physicalSize.heightMm}mm 크기 안에 들어오도록 라벨 이미지를 '
        '편집 가능한 시트로 변환해줘. 모든 치수는 mm 기준으로 유지하고, '
        '사용자가 나중에 수정할 수 있게 텍스트와 병합 셀을 가능한 한 분리하고, '
        '표는 셀의 테두리로 해줘.',
  );
  bool _saveToken = false;
  bool _analyzing = false;
  String? _errorLog;

  @override
  void dispose() {
    _tokenController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      elevation: 8,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x22000000)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '라벨 이미지 가져오기',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    visualDensity: VisualDensity.compact,
                    onPressed: _analyzing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
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
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
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
                      _compactTextField(
                        controller: _tokenController,
                        labelText: 'GitHub Token',
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _labelSheetSelectedCopilotModelValue(
                          _modelController.text,
                          labelSheetCopilotModels,
                        ),
                        isExpanded: true,
                        decoration: _compactInputDecoration(
                          'GitHub Copilot Model',
                        ),
                        items: [
                          for (final model in labelSheetCopilotModels)
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
                        minLines: 4,
                        maxLines: 6,
                        alignLabelWithHint: true,
                      ),
                      _ErrorLogPanel(message: _errorLog),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _saveToken,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              setState(() {
                                _saveToken = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text('GitHub token과 model을 이 PC에 저장'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _analyzing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _analyzing ? null : _applyCopilotAnalysis,
                    child: Text(_analyzing ? 'AI 분석 중...' : 'AI 분석 적용'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    bool alignLabelWithHint = false,
    int? minLines,
    int? maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      decoration: _compactInputDecoration(
        labelText,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }

  Future<void> _applyCopilotAnalysis() async {
    setState(() {
      _analyzing = true;
      _errorLog = null;
    });
    try {
      final draft = await labelSheetAnalyzeImageWithCopilot(
        LabelSheetCopilotImportRequest(
          token: _tokenController.text.trim(),
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
          useCopilot: true,
          token: _tokenController.text.trim(),
          model: _modelController.text.trim(),
          prompt: _promptController.text,
          saveToken: _saveToken,
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
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('label-sheet-print-settings-dialog'),
      width: 506,
      height: 226,
      decoration: BoxDecoration(
        color: const Color(0xfff6f6f6),
        border: Border.all(color: const Color(0xffc8c8c8)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            const Positioned(
              left: 12,
              top: 7,
              child: Text(
                '프린터 설정',
                style: TextStyle(fontSize: 13, color: Color(0xff111111)),
              ),
            ),
            Positioned(
              right: 5,
              top: 4,
              child: SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 14,
                  icon: const _PrintDialogCloseIcon(),
                  onPressed: onClose,
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 33,
              width: 292,
              height: 52,
              child: _PrintDialogGroup(
                title: '여백',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 7),
                    const _PrintDialogCenteredLabel('왼쪽'),
                    const SizedBox(width: 8),
                    _PrintDialogInput(controller: leftMarginController),
                    const SizedBox(width: 8),
                    const _PrintDialogCenteredLabel('mm'),
                    const SizedBox(width: 24),
                    const _PrintDialogCenteredLabel('위쪽'),
                    const SizedBox(width: 8),
                    _PrintDialogInput(controller: topMarginController),
                    const SizedBox(width: 8),
                    const _PrintDialogCenteredLabel('mm'),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 320,
              top: 33,
              width: 168,
              height: 52,
              child: _PrintDialogGroup(
                title: '자동줄간격',
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: autoSpacing,
                            isExpanded: true,
                            style: _labelStyle,
                            items: _autoSpacingItems,
                            onChanged: onAutoSpacingChanged,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const _PrintDialogCenteredLabel('%'),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 18,
              top: 94,
              child: Text('발행 프린터', style: _sectionStyle),
            ),
            Positioned(
              left: 93,
              top: 94,
              width: 300,
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedPrinterName,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle,
                ),
              ),
            ),
            Positioned(
              right: 17,
              top: 91,
              width: 94,
              height: 30,
              child: _PrintDialogButton(
                label: '프린터 선택',
                onPressed: onSelectPrinter,
              ),
            ),
            Positioned(
              left: 86,
              top: 119,
              child: Row(
                children: [
                  const Text('추가 영역', style: _labelStyle),
                  const SizedBox(width: 8),
                  _PrintDialogInput(controller: extraAreaController),
                  const SizedBox(width: 8),
                  const Text('mm', style: _labelStyle),
                ],
              ),
            ),
            Positioned(
              left: 300,
              top: 121,
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
              left: 20,
              top: 157,
              child: Text(
                '매수',
                style: TextStyle(fontSize: 30, color: Color(0xff000000)),
              ),
            ),
            Positioned(
              left: 100,
              top: 149,
              width: 84,
              height: 56,
              child: _PrintDialogInput(
                controller: copiesController,
                fontSize: 30,
                contentPadding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
              ),
            ),
            Positioned(
              left: 206,
              bottom: 8,
              width: 84,
              height: 30,
              child: _PrintDialogButton(label: '발행', onPressed: () {}),
            ),
            Positioned(
              left: 295,
              bottom: 8,
              width: 84,
              height: 30,
              child: _PrintDialogButton(label: '적용', onPressed: () {}),
            ),
            Positioned(
              left: 384,
              bottom: 8,
              width: 84,
              height: 30,
              child: _PrintDialogButton(label: '닫기', onPressed: onClose),
            ),
          ],
        ),
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 13,
    color: Color(0xff111111),
  );

  static const _sectionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xff111111),
  );

  static final List<DropdownMenuItem<String>> _autoSpacingItems = [
    const DropdownMenuItem(value: 'none', child: Text('간격조정 없음')),
    for (var value = 80; value <= 300; value += 5)
      DropdownMenuItem(value: '$value', child: Text('$value')),
  ];
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
          top: 0,
          child: ColoredBox(
            color: const Color(0xfff6f6f6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(title, style: _LabelSheetPrintSettingsDialog._labelStyle),
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
    this.contentPadding = const EdgeInsets.fromLTRB(5, 2, 5, 3),
  });

  final TextEditingController controller;
  final double fontSize;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fontSize > 20 ? 84 : 56,
      height: fontSize > 20 ? 56 : 28,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
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

String? _labelSheetSelectedCopilotModelValue(
  String current,
  List<LabelSheetCopilotModelInfo> models,
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
    required this.useCopilot,
    required this.token,
    required this.model,
    required this.prompt,
    required this.saveToken,
    this.draft,
  });

  final bool useCopilot;
  final String token;
  final String model;
  final String prompt;
  final bool saveToken;
  final LabelSheetImageImportDraft? draft;
}
