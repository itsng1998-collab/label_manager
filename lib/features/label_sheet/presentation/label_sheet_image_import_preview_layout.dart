import 'dart:math' as math;

import 'package:fortune_sheet/fortune_sheet.dart';

const double labelSheetImageImportPreviewHeight = 270;
const double labelSheetImageImportPreviewPadding = 12;
const double _labelSheetReadableTextPointSize = 9;
const double _labelSheetReadableTextPixels =
    _labelSheetReadableTextPointSize * (96 / 72);

class LabelSheetImageImportPreviewLayout {
  const LabelSheetImageImportPreviewLayout({
    required this.scale,
    required this.width,
    required this.height,
    required this.usesReadableScale,
  });

  final double scale;
  final double width;
  final double height;
  final bool usesReadableScale;
}

LabelSheetImageImportPreviewLayout labelSheetImageImportPreviewLayout({
  required int imageWidth,
  required int imageHeight,
  required double viewportWidth,
  required double viewportHeight,
  required FortuneSheetGridClientPhysicalSize physicalSize,
}) {
  final safeImageWidth = math.max(1, imageWidth).toDouble();
  final safeImageHeight = math.max(1, imageHeight).toDouble();
  final safeViewportWidth = math.max(1, viewportWidth);
  final safeViewportHeight = math.max(1, viewportHeight);
  final containScale = math.min(
    safeViewportWidth / safeImageWidth,
    safeViewportHeight / safeImageHeight,
  );
  final readableScale = _labelSheetImageImportReadableScale(
    imageWidth: safeImageWidth,
    imageHeight: safeImageHeight,
    physicalSize: physicalSize,
  );
  final usesReadableScale = containScale < readableScale;
  final scale = usesReadableScale ? readableScale : containScale;
  return LabelSheetImageImportPreviewLayout(
    scale: scale,
    width: safeImageWidth * scale,
    height: safeImageHeight * scale,
    usesReadableScale: usesReadableScale,
  );
}

double _labelSheetImageImportReadableScale({
  required double imageWidth,
  required double imageHeight,
  required FortuneSheetGridClientPhysicalSize physicalSize,
}) {
  final widthMm = math.max(1, physicalSize.widthMm).toDouble();
  final heightMm = math.max(1, physicalSize.heightMm).toDouble();
  final sourcePixelsPerMm = math.min(
    imageWidth / widthMm,
    imageHeight / heightMm,
  );
  final readablePixelsPerMm =
      _labelSheetReadableTextPixels /
      ((_labelSheetReadableTextPointSize / 72) * 25.4);
  return readablePixelsPerMm / math.max(0.01, sourcePixelsPerMm);
}
