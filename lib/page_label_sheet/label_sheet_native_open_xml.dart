import 'dart:io';

import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as image;
import 'package:label_manager/page_label_sheet/label_sheet_open_xml_export.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/utils/log_context.dart';

const MethodChannel labelSheetNativeOpenXmlChannel = MethodChannel(
  'label_manager/rtf_open_xml',
);

class LabelSheetNativeRtfImage {
  const LabelSheetNativeRtfImage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;
  final Uint8List rgba;
}

class LabelSheetNativeRtfPngImage {
  const LabelSheetNativeRtfPngImage({
    required this.width,
    required this.height,
    required this.bytes,
    this.scale = 1.0,
  });

  final int width;
  final int height;
  final Uint8List bytes;
  final double scale;
}

Future<File?> labelSheetWriteRtfNativeOpenXmlFile(
  String rtf, {
  required FortuneSheetGridClientPhysicalSize physicalSize,
  String path = labelSheetOpenXmlTestPath,
}) async {
  try {
    final result = await labelSheetNativeOpenXmlChannel
        .invokeMapMethod<String, Object?>('writeRtfOpenXml', <String, Object?>{
          'rtf': rtf,
          'path': path,
          'widthMm': physicalSize.widthMm,
          'heightMm': physicalSize.heightMm,
        });
    if (result == null || result['ok'] != true) {
      final reason = result?['reason'];
      if (reason != null) {
        debugLog('skipped: $reason');
      }
      return null;
    }
    final outputPath = result['path'] as String?;
    if (outputPath == null || outputPath.isEmpty) {
      return null;
    }
    final file = File(outputPath);
    return await file.exists() ? file : null;
  } on MissingPluginException catch (error) {
    debugLog('missing plugin: $error');
    return null;
  } on PlatformException catch (error) {
    debugLog('platform error: ${error.message ?? error.code}');
    return null;
  }
}

Future<String?> labelSheetConvertRtfNativeHtml(
  String rtf, {
  String debugDir = '.tmp',
}) async {
  try {
    final result = await labelSheetNativeOpenXmlChannel
        .invokeMapMethod<String, Object?>('convertRtfHtml', <String, Object?>{
          'rtf': rtf,
          'debugDir': debugDir,
        });
    if (result == null || result['ok'] != true) {
      final reason = result?['reason'];
      if (reason != null) {
        debugLog('html skipped: $reason');
      }
      return null;
    }
    final html = result['html'] as String?;
    return html == null || html.isEmpty ? null : html;
  } on MissingPluginException catch (error) {
    debugLog('html missing plugin: $error');
    return null;
  } on PlatformException catch (error) {
    debugLog('html platform error: ${error.message ?? error.code}');
    return null;
  }
}

Future<LabelSheetNativeRtfImage?> labelSheetCaptureRtfNativeImage(
  String rtf, {
  int width = 400,
  int height = 300,
  int widthMm = 100,
  int heightMm = 100,
  double renderScale = 1.0,
  bool trimWhitespace = true,
}) async {
  if (!Platform.isWindows ||
      rtf.isEmpty ||
      !labelSheetLooksLikeRichEditRtf(rtf)) {
    return null;
  }
  try {
    debugLog(
      'capture request '
      'px=${width}x$height mm=${widthMm}x$heightMm scale=${renderScale.toStringAsFixed(2)} '
      'rtfLen=${rtf.length} hash=${rtf.hashCode}',
    );
    final result = await labelSheetNativeOpenXmlChannel
        .invokeMapMethod<String, Object?>('captureRtfImage', <String, Object?>{
          'rtf': rtf,
          'width': width,
          'height': height,
          'widthMm': widthMm,
          'heightMm': heightMm,
          'renderScale': renderScale,
        });
    if (result == null || result['ok'] != true) {
      final reason = result?['reason'];
      if (reason != null) {
        debugLog('capture skipped: $reason');
      }
      final diagnostics = result?['diagnostics'];
      if (diagnostics is String && diagnostics.isNotEmpty) {
        debugLog('capture diagnostics $diagnostics');
      }
      return null;
    }
    final capturedWidth = result['width'] as int?;
    final capturedHeight = result['height'] as int?;
    final data = result['rgba'];
    if (capturedWidth == null ||
        capturedHeight == null ||
        data is! Uint8List ||
        data.isEmpty) {
      return null;
    }
    final renderer = result['renderer'];
    if (renderer is String && renderer.isNotEmpty) {
      debugLog('capture renderer=$renderer');
    }
    final diagnostics = result['diagnostics'];
    if (diagnostics is String && diagnostics.isNotEmpty) {
      debugLog('capture diagnostics $diagnostics');
    }
    final captured = LabelSheetNativeRtfImage(
      width: capturedWidth,
      height: capturedHeight,
      rgba: data,
    );
    debugLog(
      'capture rgba received '
      '${captured.width}x${captured.height} bytes=${captured.rgba.length} '
      'trim=$trimWhitespace',
    );
    return trimWhitespace ? _trimRtfImageWhitespace(captured) : captured;
  } on MissingPluginException catch (error) {
    debugLog('capture missing plugin: $error');
    return null;
  } on PlatformException catch (error) {
    debugLog('capture platform error: ${error.message ?? error.code}');
    return null;
  }
}

LabelSheetNativeRtfImage _trimRtfImageWhitespace(
  LabelSheetNativeRtfImage source,
) {
  final width = source.width;
  final height = source.height;
  final rgba = source.rgba;
  if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
    return source;
  }

  int minX = width;
  int minY = height;
  int maxX = -1;
  int maxY = -1;
  var inkPixels = 0;
  var leftEdgeInk = 0;
  var topEdgeInk = 0;
  var rightEdgeInk = 0;
  var bottomEdgeInk = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final offset = (y * width + x) * 4;
      final red = rgba[offset];
      final green = rgba[offset + 1];
      final blue = rgba[offset + 2];
      final alpha = rgba[offset + 3];
      if (alpha > 16 && (red < 245 || green < 245 || blue < 245)) {
        inkPixels += 1;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
        if (x == 0) leftEdgeInk += 1;
        if (y == 0) topEdgeInk += 1;
        if (x == width - 1) rightEdgeInk += 1;
        if (y == height - 1) bottomEdgeInk += 1;
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    debugLog(
      'capture trim skipped empty ink '
      '${width}x$height pixels=$inkPixels',
    );
    return source;
  }

  const margin = 4;
  final rawMinX = minX;
  final rawMinY = minY;
  final rawMaxX = maxX;
  final rawMaxY = maxY;
  minX = (minX - margin).clamp(0, width - 1);
  minY = (minY - margin).clamp(0, height - 1);
  maxX = (maxX + margin).clamp(0, width - 1);
  maxY = (maxY + margin).clamp(0, height - 1);
  final croppedWidth = maxX - minX + 1;
  final croppedHeight = maxY - minY + 1;
  if (croppedWidth == width && croppedHeight == height) {
    debugLog(
      'capture trim skipped full image '
      '${width}x$height rawBounds=$rawMinX,$rawMinY,$rawMaxX,$rawMaxY '
      'ink=$inkPixels edge=$leftEdgeInk,$topEdgeInk,$rightEdgeInk,$bottomEdgeInk '
      'margin=$margin',
    );
    return source;
  }

  final cropped = Uint8List(croppedWidth * croppedHeight * 4);
  for (var y = 0; y < croppedHeight; y++) {
    final sourceOffset = ((minY + y) * width + minX) * 4;
    final targetOffset = y * croppedWidth * 4;
    cropped.setRange(
      targetOffset,
      targetOffset + croppedWidth * 4,
      rgba,
      sourceOffset,
    );
  }
  debugLog(
    'capture trim '
    '${width}x$height -> ${croppedWidth}x$croppedHeight '
    'rawBounds=$rawMinX,$rawMinY,$rawMaxX,$rawMaxY '
    'bounds=$minX,$minY,$maxX,$maxY ink=$inkPixels '
    'edge=$leftEdgeInk,$topEdgeInk,$rightEdgeInk,$bottomEdgeInk margin=$margin',
  );
  return LabelSheetNativeRtfImage(
    width: croppedWidth,
    height: croppedHeight,
    rgba: cropped,
  );
}

Future<LabelSheetNativeRtfPngImage?> labelSheetCaptureRtfNativePngImage(
  String rtf, {
  int width = 400,
  int height = 300,
  int widthMm = 100,
  int heightMm = 100,
  double renderScale = 1.0,
  bool trimWhitespace = true,
}) async {
  final captured = await labelSheetCaptureRtfNativeImage(
    rtf,
    width: width,
    height: height,
    widthMm: widthMm,
    heightMm: heightMm,
    renderScale: renderScale,
    trimWhitespace: trimWhitespace,
  );
  if (captured == null) {
    return null;
  }
  final bitmap = image.Image.fromBytes(
    width: captured.width,
    height: captured.height,
    bytes: captured.rgba.buffer,
    numChannels: 4,
    order: image.ChannelOrder.rgba,
  );
  final pngBytes = Uint8List.fromList(image.encodePng(bitmap));
  debugLog(
    'capture png encoded '
    '${captured.width}x${captured.height} bytes=${pngBytes.length} '
    'scale=${renderScale.toStringAsFixed(2)} trim=$trimWhitespace',
  );
  return LabelSheetNativeRtfPngImage(
    width: captured.width,
    height: captured.height,
    bytes: pngBytes,
    scale: renderScale,
  );
}

Future<Uint8List?> labelSheetCaptureRtfNativePng(
  String rtf, {
  int width = 400,
  int height = 300,
  int widthMm = 100,
  int heightMm = 100,
  double renderScale = 1.0,
  bool trimWhitespace = true,
}) async {
  final captured = await labelSheetCaptureRtfNativePngImage(
    rtf,
    width: width,
    height: height,
    widthMm: widthMm,
    heightMm: heightMm,
    renderScale: renderScale,
    trimWhitespace: trimWhitespace,
  );
  return captured?.bytes;
}
