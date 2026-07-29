import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as imglib;

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
    inferWidthFromLength: _labelSheetLinearBarcodeFormatIds.contains(
      request.formatId,
    ),
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
  bool inferWidthFromLength = false,
}) {
  final decodedWidth =
      inferWidthFromLength && height > 0 && data.lengthInBytes % height == 0
      ? math.max(1, data.lengthInBytes ~/ height)
      : width;
  return imglib.Image.fromBytes(
    width: decodedWidth,
    height: height,
    bytes: Uint8List.fromList(data).buffer,
    numChannels: 1,
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