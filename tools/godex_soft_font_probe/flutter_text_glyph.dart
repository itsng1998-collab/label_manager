import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'pcl4_bitmap_font.dart';

Future<Pcl4BitmapGlyph> rasterizeTextAsPcl4Glyph({
  required String text,
  required int characterCode,
  required String fontFamily,
  required double fontPixelHeight,
  required bool bold,
  int? maximumWidth,
  int alphaThreshold = 64,
}) async {
  if (text.isEmpty || text.contains('\r') || text.contains('\n')) {
    throw ArgumentError.value(text, 'text', 'Must be one non-empty line.');
  }
  if (fontPixelHeight <= 0) {
    throw RangeError.value(fontPixelHeight, 'fontPixelHeight');
  }
  if (alphaThreshold < 1 || alphaThreshold > 255) {
    throw RangeError.range(alphaThreshold, 1, 255, 'alphaThreshold');
  }
  if (maximumWidth != null && maximumWidth < 1) {
    throw RangeError.range(maximumWidth, 1, 0xffff, 'maximumWidth');
  }
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: const ui.Color(0xffffffff),
        fontFamily: fontFamily,
        fontSize: fontPixelHeight,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final naturalWidth = painter.width.ceil().clamp(1, 0xffff);
  final width = maximumWidth == null || naturalWidth <= maximumWidth
      ? naturalWidth
      : maximumWidth;
  final height = painter.height.ceil().clamp(1, 0xffff);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (width < naturalWidth) {
    canvas.scale(width / naturalWidth, 1);
  }
  painter.paint(canvas, ui.Offset.zero);
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (data == null) throw StateError('Could not read rendered glyph pixels.');

  final stride = (width + 7) ~/ 8;
  final raster = Uint8List(stride * height);
  var paintedPixels = 0;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final alpha = data.getUint8((y * width + x) * 4 + 3);
      if (alpha < alphaThreshold) continue;
      raster[y * stride + x ~/ 8] |= 0x80 >> (x % 8);
      paintedPixels += 1;
    }
  }
  if (paintedPixels == 0) {
    throw StateError('Rendered glyph contains no painted pixels.');
  }
  return Pcl4BitmapGlyph(
    characterCode: characterCode,
    width: width,
    height: height,
    advance: width,
    topOffset: height,
    raster: raster,
  );
}
