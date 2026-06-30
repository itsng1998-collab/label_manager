import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LabelSheetPrintOptions {
  const LabelSheetPrintOptions({
    required this.copies,
    required this.leftMarginMm,
    required this.topMarginMm,
    required this.extraAreaMm,
    required this.autoSpacingPercent,
    required this.orientation,
  });

  final int copies;
  final double leftMarginMm;
  final double topMarginMm;
  final double extraAreaMm;
  final int? autoSpacingPercent;
  final LabelSheetPrintOrientation orientation;

  bool get rotateQuarterTurns => orientation == LabelSheetPrintOrientation.vertical;
}

enum LabelSheetPrintOrientation { horizontal, vertical }

class LabelSheetPrintPageMetrics {
  const LabelSheetPrintPageMetrics({
    required this.labelWidthMm,
    required this.labelHeightMm,
    required this.dpi,
  });

  final int labelWidthMm;
  final int labelHeightMm;
  final double dpi;

  double get pageWidthMm => labelWidthMm.toDouble();
  double pageHeightMm(LabelSheetPrintOptions options) =>
      labelHeightMm + math.max(0, options.extraAreaMm);

  int dotsFromMm(num millimeters) =>
      math.max(0, (millimeters * dpi / 25.4).round());
}

Future<Uint8List> buildLabelSheetPdfBytes({
  required Uint8List pngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) async {
  final pageWidthMm = metrics.pageWidthMm;
  final pageHeightMm = metrics.pageHeightMm(options);
  final pageWidth = _mmToPdfPoints(pageWidthMm);
  final pageHeight = _mmToPdfPoints(pageHeightMm);
  final imageWidth = _mmToPdfPoints(metrics.labelWidthMm);
  final imageHeight = _mmToPdfPoints(metrics.labelHeightMm);
  final left = _mmToPdfPoints(options.leftMarginMm);
  final top = _mmToPdfPoints(options.topMarginMm);
  final document = pw.Document();
  final image = pw.MemoryImage(pngBytes);

  for (var copy = 0; copy < options.copies; copy += 1) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
        build: (_) => pw.Stack(
          children: [
            pw.Positioned(
              left: left,
              top: top,
              child: pw.Transform.rotateBox(
                angle: options.rotateQuarterTurns ? math.pi / 2 : 0,
                child: pw.Image(
                  image,
                  width: imageWidth,
                  height: imageHeight,
                  fit: pw.BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return document.save();
}

Future<Uint8List> buildLabelSheetEzplRasterBytes({
  required Uint8List pngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) async {
  final source = img.decodePng(pngBytes);
  if (source == null) {
    throw StateError('라벨 이미지를 EZPL 출력 이미지로 변환할 수 없습니다.');
  }

  final labelWidthDots = metrics.dotsFromMm(metrics.labelWidthMm);
  final labelHeightDots = metrics.dotsFromMm(metrics.labelHeightMm);
  final pageWidthDots = labelWidthDots;
  final pageHeightDots = metrics.dotsFromMm(metrics.pageHeightMm(options));
  final leftDots = metrics.dotsFromMm(options.leftMarginMm);
  final topDots = metrics.dotsFromMm(options.topMarginMm);
  final content = img.copyResize(
    source,
    width: labelWidthDots,
    height: labelHeightDots,
    interpolation: img.Interpolation.average,
  );
  final raster = img.Image(width: pageWidthDots, height: pageHeightDots);
  img.fill(raster, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(raster, content, dstX: leftDots, dstY: topDots);

  final bytesPerRow = (pageWidthDots + 7) ~/ 8;
  final commands = BytesBuilder(copy: false)
    ..add(ascii.encode('^Q${metrics.pageHeightMm(options).round()},0,0\r\n'))
    ..add(ascii.encode('^W ${metrics.pageWidthMm.round()}\r\n'))
    ..add(ascii.encode('^P${options.copies}\r\n'))
    ..add(ascii.encode('^L\r\n'))
    ..add(ascii.encode('~G\r\n'));

  for (var y = 0; y < raster.height; y += 1) {
    final row = Uint8List(bytesPerRow);
    for (var x = 0; x < raster.width; x += 1) {
      final pixel = raster.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance < 160) {
        row[x ~/ 8] |= 1 << (7 - (x % 8));
      }
    }
    commands
      ..addByte(0x47)
      ..addByte(bytesPerRow)
      ..add(row)
      ..add(const [0x0d, 0x0a]);
  }
  commands.add(ascii.encode('E\r\n'));
  return commands.takeBytes();
}

Future<Uint8List> buildLabelSheetHybridEzplBytes({
  required FortuneSheet sheet,
  required FortuneRange range,
  required Uint8List fallbackPngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) async {
  final source = img.decodePng(fallbackPngBytes);
  if (source == null) {
    throw StateError('라벨 이미지를 EZPL 출력 이미지로 변환할 수 없습니다.');
  }

  final labelWidthDots = metrics.dotsFromMm(metrics.labelWidthMm);
  final labelHeightDots = metrics.dotsFromMm(metrics.labelHeightMm);
  final pageWidthDots = labelWidthDots;
  final pageHeightDots = metrics.dotsFromMm(metrics.pageHeightMm(options));
  final leftDots = metrics.dotsFromMm(options.leftMarginMm);
  final topDots = metrics.dotsFromMm(options.topMarginMm);
  final content = img.copyResize(
    source,
    width: labelWidthDots,
    height: labelHeightDots,
    interpolation: img.Interpolation.average,
  );
  _clearNativeBarcodeFallbackAreas(content, sheet, metrics);
  final raster = img.Image(width: pageWidthDots, height: pageHeightDots);
  img.fill(raster, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(raster, content, dstX: leftDots, dstY: topDots);

  final commands = BytesBuilder(copy: false)
    ..add(ascii.encode('^Q${metrics.pageHeightMm(options).round()},0,0\r\n'))
    ..add(ascii.encode('^W ${metrics.pageWidthMm.round()}\r\n'))
    ..add(ascii.encode('^P${options.copies}\r\n'))
    ..add(ascii.encode('^L\r\n'));

  _addEzplRasterGraphic(commands, raster);
  _addHybridSheetBorders(
    commands,
    sheet: sheet,
    range: range,
    metrics: metrics,
    options: options,
  );
  _addHybridSheetBarcodes(
    commands,
    sheet: sheet,
    metrics: metrics,
    options: options,
  );

  commands.add(ascii.encode('E\r\n'));
  return commands.takeBytes();
}

void _addEzplRasterGraphic(BytesBuilder commands, img.Image raster) {
  final bytesPerRow = (raster.width + 7) ~/ 8;
  commands.add(ascii.encode('~G\r\n'));

  for (var y = 0; y < raster.height; y += 1) {
    final row = Uint8List(bytesPerRow);
    for (var x = 0; x < raster.width; x += 1) {
      final pixel = raster.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance < 160) {
        row[x ~/ 8] |= 1 << (7 - (x % 8));
      }
    }
    commands
      ..addByte(0x47)
      ..addByte(bytesPerRow)
      ..add(row)
      ..add(const [0x0d, 0x0a]);
  }
}

void _addHybridSheetBorders(
  BytesBuilder commands, {
  required FortuneSheet sheet,
  required FortuneRange range,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final sheetMetrics = sheet.metrics(defaultSettings);
  final borders = FortuneBorderCompute.computeRange(sheet, range);
  for (final entry in borders.entries) {
    final coord = entry.key;
    final cellBorders = entry.value;
    final left = _logicalToDots(
      sheetMetrics.columnStart(coord.column),
      metrics,
      offsetMm: options.leftMarginMm,
    );
    final right = _logicalToDots(
      sheetMetrics.columnEnd(coord.column),
      metrics,
      offsetMm: options.leftMarginMm,
    );
    final top = _logicalToDots(
      sheetMetrics.rowStart(coord.row),
      metrics,
      offsetMm: options.topMarginMm,
    );
    final bottom = _logicalToDots(
      sheetMetrics.rowEnd(coord.row),
      metrics,
      offsetMm: options.topMarginMm,
    );
    _addEzplBorderLine(commands, left, top, right, top, cellBorders.top, metrics);
    _addEzplBorderLine(
      commands,
      right,
      top,
      right,
      bottom,
      cellBorders.right,
      metrics,
    );
    _addEzplBorderLine(
      commands,
      left,
      bottom,
      right,
      bottom,
      cellBorders.bottom,
      metrics,
    );
    _addEzplBorderLine(
      commands,
      left,
      top,
      left,
      bottom,
      cellBorders.left,
      metrics,
    );
  }
}

void _addEzplBorderLine(
  BytesBuilder commands,
  int x1,
  int y1,
  int x2,
  int y2,
  FortuneBorderSide? side,
  LabelSheetPrintPageMetrics metrics,
) {
  if (side == null || side.style == 0) {
    return;
  }
  final width = _borderStrokeDots(side, metrics);
  final left = math.min(x1, x2);
  final top = math.min(y1, y2);
  final boxWidth = math.max(width, (x2 - x1).abs());
  final boxHeight = math.max(width, (y2 - y1).abs());
  commands.add(
    ascii.encode('R$left,$top,${left + boxWidth},${top + boxHeight},$width,$width\r\n'),
  );
}

int _borderStrokeDots(
  FortuneBorderSide side,
  LabelSheetPrintPageMetrics metrics,
) {
  final logicalWidth = side.strokeWidth ?? _borderStyleLogicalWidth(side.style);
  final mm = fortuneLogicalPixelsToMillimeters(logicalWidth);
  return math.max(1, metrics.dotsFromMm(mm));
}

double _borderStyleLogicalWidth(int style) {
  switch (style) {
    case 2:
    case 3:
      return 2;
    case 4:
    case 5:
      return 3;
    default:
      return 1;
  }
}

void _addHybridSheetBarcodes(
  BytesBuilder commands, {
  required FortuneSheet sheet,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  for (final image in sheet.images) {
    if (image.extraFields['fortuneBarcode'] != true) {
      continue;
    }
    final text = image.extraFields['barcodeText']?.toString().trim() ?? '';
    if (text.isEmpty) {
      continue;
    }
    final format = image.extraFields['barcodeFormatId']?.toString() ?? '';
    final command = _ezplBarcodeCommandForFormat(format);
    if (command == null) {
      continue;
    }
    final rotation = _metadataDouble(image.extraFields['rotation'], 0);
    if (rotation.abs() > 0.001) {
      continue;
    }
    final x = _logicalToDots(image.left, metrics, offsetMm: options.leftMarginMm);
    final y = _logicalToDots(image.top, metrics, offsetMm: options.topMarginMm);
    final narrow = math.max(
      1,
      _metadataDouble(image.extraFields['barcodeModuleScale'], 2).round(),
    );
    final wide = math.max(narrow + 1, (narrow * 2.5).round());
    final height = math.max(
      8,
      metrics.dotsFromMm(
        fortuneLogicalPixelsToMillimeters(
          _metadataDouble(image.extraFields['barcodeBarHeight'], image.height),
        ),
      ),
    );
    final humanReadable = image.extraFields['barcodeShowText'] == true ? '1' : '0';
    final escaped = _escapeEzplText(text);
    commands.add(
      ascii.encode('$command$x,$y,$narrow,$wide,$height,0,$humanReadable,$escaped\r\n'),
    );
  }
}

void _clearNativeBarcodeFallbackAreas(
  img.Image content,
  FortuneSheet sheet,
  LabelSheetPrintPageMetrics metrics,
) {
  for (final image in sheet.images) {
    if (!_canRenderNativeBarcode(image)) {
      continue;
    }
    final left = _logicalToDots(image.left, metrics).clamp(0, content.width);
    final top = _logicalToDots(image.top, metrics).clamp(0, content.height);
    final right = _logicalToDots(
      image.left + image.width,
      metrics,
    ).clamp(0, content.width);
    final bottom = _logicalToDots(
      image.top + image.height,
      metrics,
    ).clamp(0, content.height);
    if (right <= left || bottom <= top) {
      continue;
    }
    img.fillRect(
      content,
      x1: left,
      y1: top,
      x2: right - 1,
      y2: bottom - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
}

bool _canRenderNativeBarcode(FortuneImage image) {
  if (image.extraFields['fortuneBarcode'] != true) {
    return false;
  }
  final text = image.extraFields['barcodeText']?.toString().trim() ?? '';
  if (text.isEmpty) {
    return false;
  }
  final format = image.extraFields['barcodeFormatId']?.toString() ?? '';
  if (_ezplBarcodeCommandForFormat(format) == null) {
    return false;
  }
  final rotation = _metadataDouble(image.extraFields['rotation'], 0);
  return rotation.abs() <= 0.001;
}

String? _ezplBarcodeCommandForFormat(String format) {
  final normalized = format.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized.contains('code128')) {
    return 'BQ';
  }
  if (normalized.contains('code39')) {
    return 'BA';
  }
  if (normalized.contains('ean13')) {
    return 'BE';
  }
  if (normalized.contains('ean8')) {
    return 'BB';
  }
  return null;
}

double _metadataDouble(Object? value, double fallback) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

int _logicalToDots(
  num logicalPixels,
  LabelSheetPrintPageMetrics metrics, {
  double offsetMm = 0,
}) {
  return metrics.dotsFromMm(
    offsetMm + fortuneLogicalPixelsToMillimeters(logicalPixels),
  );
}

String _escapeEzplText(String value) {
  return value.replaceAll('\r', ' ').replaceAll('\n', ' ');
}

double _mmToPdfPoints(num millimeters) =>
    millimeters * PdfPageFormat.mm;
