import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

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

double _mmToPdfPoints(num millimeters) =>
    millimeters * PdfPageFormat.mm;
