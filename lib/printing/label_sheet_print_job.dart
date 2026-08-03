import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const double labelSheetEzplRasterCaptureScale = 2;
const num _labelSheetEzplInkLuminanceThreshold = 200;
class LabelSheetWindowsDriverPage {
  const LabelSheetWindowsDriverPage({
    required this.bgraBytes,
    required this.width,
    required this.height,
    required this.inputWidth,
    required this.inputHeight,
    required this.rasterMapping,
    required this.inkPixels,
    required this.nonWhitePixels,
    required this.antialiasPixels,
    required this.luminanceHistogram,
    required this.coverageInkEquivalent,
    required this.isolatedInkPixels,
  });

  final Uint8List bgraBytes;
  final int width;
  final int height;
  final int inputWidth;
  final int inputHeight;
  final String rasterMapping;
  final int inkPixels;
  final int nonWhitePixels;
  final int antialiasPixels;
  final List<int> luminanceHistogram;
  final double coverageInkEquivalent;
  final int isolatedInkPixels;

  int get totalPixels => width * height;
  double get inkPercent => totalPixels == 0 ? 0 : inkPixels * 100 / totalPixels;
  double get antialiasPercent =>
      totalPixels == 0 ? 0 : antialiasPixels * 100 / totalPixels;
}

LabelSheetWindowsDriverPage prepareLabelSheetWindowsDriverPage({
  required Uint8List pngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final source = img.decodePng(pngBytes);
  if (source == null) {
    throw StateError('라벨 이미지를 Windows 프린터 출력 이미지로 변환할 수 없습니다.');
  }
  final layout = LabelSheetPrintLayout.resolve(metrics: metrics, options: options);
  int renderDots(num millimeters) =>
      math.max(0, (millimeters * metrics.dpi / 25.4).round());
  final page = img.Image(
    width: renderDots(layout.pageWidthMm),
    height: renderDots(layout.pageHeightMm),
  );
  img.fill(page, color: img.ColorRgb8(255, 255, 255));
  final oriented = options.rotateQuarterTurns
      ? img.copyRotate(source, angle: 90)
      : source;
  final contentWidth = renderDots(layout.contentWidthMm);
  final contentHeight = renderDots(layout.contentHeightMm);
  late final img.Image content;
  late final String rasterMapping;
  if (oriented.width == contentWidth && oriented.height == contentHeight) {
    content = oriented;
    rasterMapping = 'direct';
  } else if (oriented.width >= contentWidth &&
      oriented.width <= contentWidth + 1 &&
      oriented.height >= contentHeight &&
      oriented.height <= contentHeight + 1) {
    content = img.copyCrop(
      oriented,
      x: 0,
      y: 0,
      width: contentWidth,
      height: contentHeight,
    );
    rasterMapping = 'cropCeilOverflow';
  } else {
    content = img.copyResize(
      oriented,
      width: contentWidth,
      height: contentHeight,
      interpolation: img.Interpolation.average,
    );
    rasterMapping = 'averageResize';
  }
  img.compositeImage(
    page,
    content,
    dstX: (layout.contentLeftMm * metrics.dpi / 25.4).round(),
    dstY: (layout.contentTopMm * metrics.dpi / 25.4).round(),
  );
  final clipRight = renderDots(layout.clipRightMm);
  if (clipRight < page.width) {
    img.fillRect(
      page,
      x1: math.max(0, clipRight),
      y1: 0,
      x2: page.width - 1,
      y2: page.height - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  final clipBottom = renderDots(layout.clipBottomMm);
  if (clipBottom < page.height) {
    img.fillRect(
      page,
      x1: 0,
      y1: math.max(0, clipBottom),
      x2: page.width - 1,
      y2: page.height - 1,
      color: img.ColorRgb8(255, 255, 255),
    );
  }
  final pixelCount = page.width * page.height;
  final bgraBytes = Uint8List(pixelCount * 4);
  var antialiasPixels = 0;
  var nonWhitePixels = 0;
  final luminanceHistogram = List<int>.filled(8, 0);
  var coverageInkEquivalent = 0.0;
  var inkPixels = 0;
  var pixelIndex = 0;
  for (final pixel in page) {
    final luminance = img.getLuminance(pixel);
    if (luminance > 0 && luminance < 255) antialiasPixels += 1;
    if (luminance < 255) nonWhitePixels += 1;
    luminanceHistogram[math.min(7, luminance.toInt() ~/ 32)] += 1;
    coverageInkEquivalent += (255 - luminance) / 255;
    final value = luminance.round().clamp(0, 255);
    if (value == 0) {
      inkPixels += 1;
    }
    final offset = pixelIndex * 4;
    bgraBytes[offset] = value;
    bgraBytes[offset + 1] = value;
    bgraBytes[offset + 2] = value;
    bgraBytes[offset + 3] = 255;
    pixelIndex += 1;
  }
  var isolatedInkPixels = 0;
  bool isInk(int x, int y) =>
      bgraBytes[(y * page.width + x) * 4] == 0;
  for (var y = 0; y < page.height; y += 1) {
    for (var x = 0; x < page.width; x += 1) {
      if (!isInk(x, y)) continue;
      var hasInkNeighbor = false;
      for (var neighborY = math.max(0, y - 1);
          neighborY <= math.min(page.height - 1, y + 1);
          neighborY += 1) {
        for (var neighborX = math.max(0, x - 1);
            neighborX <= math.min(page.width - 1, x + 1);
            neighborX += 1) {
          if ((neighborX != x || neighborY != y) &&
              isInk(neighborX, neighborY)) {
            hasInkNeighbor = true;
          }
        }
      }
      if (!hasInkNeighbor) isolatedInkPixels += 1;
    }
  }
  return LabelSheetWindowsDriverPage(
    bgraBytes: bgraBytes,
    width: page.width,
    height: page.height,
    inputWidth: oriented.width,
    inputHeight: oriented.height,
    rasterMapping: rasterMapping,
    inkPixels: inkPixels,
    nonWhitePixels: nonWhitePixels,
    antialiasPixels: antialiasPixels,
    luminanceHistogram: List<int>.unmodifiable(luminanceHistogram),
    coverageInkEquivalent: coverageInkEquivalent,
    isolatedInkPixels: isolatedInkPixels,
  );
}

class LabelSheetPrintOptions {
  const LabelSheetPrintOptions({
    required this.copies,
    required this.leftMarginMm,
    this.rightMarginMm = 0,
    required this.topMarginMm,
    this.leftPushMm = 0,
    this.topPushMm = 0,
    required this.extraAreaMm,
    required this.autoSpacingPercent,
    required this.orientation,
  });

  final int copies;
  final double leftMarginMm;
  final double rightMarginMm;
  final double topMarginMm;
  final double leftPushMm;
  final double topPushMm;
  final double extraAreaMm;
  final int? autoSpacingPercent;
  final LabelSheetPrintOrientation orientation;

  bool get rotateQuarterTurns => orientation == LabelSheetPrintOrientation.vertical;
}

enum LabelSheetPrintOrientation { horizontal, vertical }

LabelSheetPrintOptions labelSheetPrintOptionsFromInput({
  required String copies,
  required String leftMarginMm,
  required String topMarginMm,
  required String extraAreaMm,
  required String autoSpacing,
  required String orientation,
}) {
  double nonNegativeDouble(String value) =>
      math.max(0, double.tryParse(value.trim()) ?? 0);

  return LabelSheetPrintOptions(
    copies: math.max(1, int.tryParse(copies.trim()) ?? 1),
    leftMarginMm: nonNegativeDouble(leftMarginMm),
    topMarginMm: nonNegativeDouble(topMarginMm),
    extraAreaMm: nonNegativeDouble(extraAreaMm),
    autoSpacingPercent: autoSpacing == 'none'
        ? null
        : int.tryParse(autoSpacing),
    orientation: orientation == 'vertical'
        ? LabelSheetPrintOrientation.vertical
        : LabelSheetPrintOrientation.horizontal,
  );
}

class LabelSheetPrintPageMetrics {
  const LabelSheetPrintPageMetrics({
    required this.labelWidthMm,
    required this.labelHeightMm,
    required this.dpi,
    this.sourceWidthMm,
    this.sourceHeightMm,
  });

  final int labelWidthMm;
  final int labelHeightMm;
  final double dpi;
  final double? sourceWidthMm;
  final double? sourceHeightMm;

  double get pageWidthMm => labelWidthMm.toDouble();
  double get effectiveSourceWidthMm => sourceWidthMm ?? labelWidthMm.toDouble();
  double get effectiveSourceHeightMm =>
      sourceHeightMm ?? labelHeightMm.toDouble();
  double pageHeightMm(LabelSheetPrintOptions options) =>
      labelHeightMm + math.max(0, options.extraAreaMm);

  int dotsFromMm(num millimeters) =>
      math.max(0, (millimeters * dpi / 25.4).round());

  int signedDotsFromMm(num millimeters) =>
      (millimeters * dpi / 25.4).round();
}

FortuneRange labelSheetPrintRange(
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

class LabelSheetHybridPrintGeometry {
  const LabelSheetHybridPrintGeometry({
    required this.range,
    required this.metrics,
    required this.transform,
  });

  final FortuneRange range;
  final LabelSheetPrintPageMetrics metrics;
  final FortunePrintTransform transform;
}

LabelSheetHybridPrintGeometry resolveLabelSheetHybridPrintGeometry({
  required FortuneSheet sheet,
  required FortuneSettings settings,
  required FortuneSheetGridClientPhysicalSize physicalSize,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final range = labelSheetPrintRange(sheet, physicalSize);
  final sheetMetrics = sheet.metrics(settings);
  final rowStart = math.min(range.rowStart, range.rowEnd);
  final rowEnd = math.max(range.rowStart, range.rowEnd);
  final columnStart = math.min(range.columnStart, range.columnEnd);
  final columnEnd = math.max(range.columnStart, range.columnEnd);
  final sourceBounds = ui.Rect.fromLTRB(
    sheetMetrics.columnStart(columnStart),
    sheetMetrics.rowStart(rowStart),
    math.min(
      sheetMetrics.columnEnd(columnEnd),
      physicalSize.logicalSize.width,
    ),
    math.min(
      sheetMetrics.rowEnd(rowEnd),
      physicalSize.logicalSize.height,
    ),
  );
  final resolvedMetrics = LabelSheetPrintPageMetrics(
    labelWidthMm: metrics.labelWidthMm,
    labelHeightMm: metrics.labelHeightMm,
    dpi: metrics.dpi,
    sourceWidthMm: physicalSize.widthMm.toDouble(),
    sourceHeightMm: physicalSize.heightMm.toDouble(),
  );
  final layout = LabelSheetPrintLayout.resolve(
    metrics: resolvedMetrics,
    options: options,
  );
  return LabelSheetHybridPrintGeometry(
    range: range,
    metrics: resolvedMetrics,
    transform: FortunePrintTransform(
      sourceLogicalBounds: sourceBounds,
      dpi: resolvedMetrics.dpi,
      contentLeftMm: layout.contentLeftMm,
      contentTopMm: layout.contentTopMm,
      clipRightMm: layout.clipRightMm,
      clipBottomMm: layout.clipBottomMm,
      nativeAllowed: !options.rotateQuarterTurns,
    ),
  );
}

class LabelSheetHybridPrintPreparation {
  const LabelSheetHybridPrintPreparation({
    required this.geometry,
    required this.descriptors,
    required this.plan,
    required this.renderedTextCells,
    required this.dynamicTextMaterialized,
    required this.textCandidateExclusionCounts,
    required this.textRejectionCounts,
  });

  final LabelSheetHybridPrintGeometry geometry;
  final List<LabelSheetEzplNativeDescriptor> descriptors;
  final FortuneHybridRenderPlan plan;
  final int renderedTextCells;
  final int dynamicTextMaterialized;
  final Map<String, int> textCandidateExclusionCounts;
  final Map<String, int> textRejectionCounts;
}

LabelSheetHybridPrintPreparation prepareLabelSheetHybridPrint({
  required FortuneSheet sheet,
  required FortuneSettings settings,
  required FortuneSheetGridClientPhysicalSize physicalSize,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
  int? lineSpacingPercent,
}) {
  final printSheet = fortuneSheetMaterializeDynamicComputedText(sheet);
  final dynamicTextMaterialized = printSheet.cells.entries.where((entry) {
    return sheet.cells[entry.key]?.renderedText != entry.value.renderedText;
  }).length;
  final geometry = resolveLabelSheetHybridPrintGeometry(
    sheet: printSheet,
    settings: settings,
    physicalSize: physicalSize,
    metrics: metrics,
    options: options,
  );
  final candidateDiagnostics = FortuneNativeCandidateDiagnostics();
  final candidates = fortuneBuildNativeCandidates(
    settings: settings,
    sheet: printSheet,
    range: geometry.range,
    transform: geometry.transform,
    diagnostics: candidateDiagnostics,
  );
  final textRejectionCounts = <String, int>{};
  final descriptors = preflightLabelSheetEzplCandidates(
    sheet: printSheet,
    settings: settings,
    transform: geometry.transform,
    candidates: candidates,
    lineSpacingPercent: lineSpacingPercent,
    textRejectionCounts: textRejectionCounts,
  );
  final plan = fortuneFinalizeHybridRenderPlan(
    settings: settings,
    sheet: printSheet,
    range: geometry.range,
    transform: geometry.transform,
    candidates: candidates,
    approvals: descriptors.map((descriptor) => descriptor.approval),
  );
  return LabelSheetHybridPrintPreparation(
    geometry: geometry,
    descriptors: descriptors,
    plan: plan,
    renderedTextCells: printSheet.cells.values
        .where((cell) => cell.renderedText.isNotEmpty)
        .length,
    dynamicTextMaterialized: dynamicTextMaterialized,
    textCandidateExclusionCounts: candidateDiagnostics.cellTextExcluded,
    textRejectionCounts: Map.unmodifiable(textRejectionCounts),
  );
}

class LabelSheetPrintLayout {
  const LabelSheetPrintLayout({
    required this.pageWidthMm,
    required this.pageHeightMm,
    required this.contentLeftMm,
    required this.contentTopMm,
    required this.contentWidthMm,
    required this.contentHeightMm,
    required this.clipRightMm,
    required this.clipBottomMm,
  });

  factory LabelSheetPrintLayout.resolve({
    required LabelSheetPrintPageMetrics metrics,
    required LabelSheetPrintOptions options,
  }) {
    final rotated = options.rotateQuarterTurns;
    return LabelSheetPrintLayout(
      pageWidthMm: metrics.pageWidthMm,
      pageHeightMm: metrics.pageHeightMm(options),
      contentLeftMm: options.leftMarginMm + options.leftPushMm,
      contentTopMm: options.topMarginMm + options.topPushMm,
      contentWidthMm: rotated
          ? metrics.effectiveSourceHeightMm
          : metrics.effectiveSourceWidthMm,
      contentHeightMm: rotated
          ? metrics.effectiveSourceWidthMm
          : metrics.effectiveSourceHeightMm,
      clipRightMm: metrics.pageWidthMm - options.rightMarginMm,
      clipBottomMm: metrics.labelHeightMm.toDouble(),
    );
  }

  final double pageWidthMm;
  final double pageHeightMm;
  final double contentLeftMm;
  final double contentTopMm;
  final double contentWidthMm;
  final double contentHeightMm;
  final double clipRightMm;
  final double clipBottomMm;

  double get intersectionWidthMm => math.max(
    0,
    math.min(contentLeftMm + contentWidthMm, clipRightMm) -
        math.max(contentLeftMm, 0),
  );

  double get intersectionHeightMm => math.max(
    0,
    math.min(contentTopMm + contentHeightMm, clipBottomMm) -
        math.max(contentTopMm, 0),
  );

  bool get hasContentIntersection =>
      clipRightMm > 0 && intersectionWidthMm > 0 && intersectionHeightMm > 0;
}

class LabelSheetRenderedPage {
  const LabelSheetRenderedPage({
    required this.pngBytes,
    required this.metrics,
    required this.options,
  });

  final Uint8List pngBytes;
  final LabelSheetPrintPageMetrics metrics;
  final LabelSheetPrintOptions options;
}

class LabelSheetWindowsTextDescriptor {
  const LabelSheetWindowsTextDescriptor({
    required this.candidateToken,
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.fontFamily,
    required this.fontPixelHeight,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikeThrough,
    required this.colorArgb,
    required this.horizontalAlign,
    required this.verticalAlign,
    required this.wrap,
    required this.predictedPaintedFootprint,
  });

  final String candidateToken;
  final String text;
  final int left;
  final int top;
  final int right;
  final int bottom;
  final String fontFamily;
  final int fontPixelHeight;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final int colorArgb;
  final String horizontalAlign;
  final String verticalAlign;
  final bool wrap;
  final ui.Rect predictedPaintedFootprint;

  FortuneNativeCandidateApproval get approval =>
      FortuneNativeCandidateApproval(
        candidateToken: candidateToken,
        predictedPaintedFootprint: predictedPaintedFootprint,
      );

  Map<String, Object?> toChannelMap() => <String, Object?>{
    'text': text,
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
    'fontFamily': fontFamily,
    'fontPixelHeight': fontPixelHeight,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikeThrough': strikeThrough,
    'colorArgb': colorArgb,
    'horizontalAlign': horizontalAlign,
    'verticalAlign': verticalAlign,
    'wrap': wrap,
  };
}

class LabelSheetWindowsHybridPreparation {
  const LabelSheetWindowsHybridPreparation({
    required this.geometry,
    required this.descriptors,
    required this.plan,
  });

  final LabelSheetHybridPrintGeometry geometry;
  final List<LabelSheetWindowsTextDescriptor> descriptors;
  final FortuneHybridRenderPlan plan;
}

LabelSheetWindowsHybridPreparation prepareLabelSheetWindowsHybridPrint({
  required FortuneSheet sheet,
  required FortuneSettings settings,
  required FortuneSheetGridClientPhysicalSize physicalSize,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
  required int? lineSpacingPercent,
}) {
  final geometry = resolveLabelSheetHybridPrintGeometry(
    sheet: sheet,
    settings: settings,
    physicalSize: physicalSize,
    metrics: metrics,
    options: options,
  );
  final candidates = fortuneBuildNativeCandidates(
    settings: settings,
    sheet: sheet,
    range: geometry.range,
    transform: geometry.transform,
  );
  final descriptors = <LabelSheetWindowsTextDescriptor>[];
  if (lineSpacingPercent == null &&
      options.orientation == LabelSheetPrintOrientation.horizontal) {
    for (final candidate in candidates) {
      if (candidate.kind != FortuneNativeCandidateKind.cellText ||
          candidate.cellCoord == null) {
        continue;
      }
      final cell = sheet.cells[candidate.cellCoord!];
      if (cell == null ||
          cell.renderedText.isEmpty ||
          cell.inlineRuns?.isNotEmpty == true ||
          cell.isVerticalText ||
          cell.normalizedTextRotation != 0 ||
          cell.normalizedTextWrap == '1' ||
          cell.normalizedHorizontalAlign == '3' ||
          cell.extraFields[fortuneCellTextOffsetYExtraKey] != null) {
        continue;
      }
      final target = candidate.printerPaintedFootprint;
      final left = target.left.round();
      final top = target.top.round();
      final right = target.right.round();
      final bottom = target.bottom.round();
      if (right <= left || bottom <= top) continue;
      final predicted = ui.Rect.fromLTRB(
        left.toDouble(),
        top.toDouble(),
        right.toDouble(),
        bottom.toDouble(),
      );
      descriptors.add(
        LabelSheetWindowsTextDescriptor(
          candidateToken: candidate.token,
          text: cell.renderedText,
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          fontFamily: fortuneResolveFontFamily(
            cell.fontFamily,
            settings.fontFamilies,
          ),
          fontPixelHeight: math.max(
            1,
            ((cell.fontSize ?? settings.defaultFontSize) *
                    geometry.transform.dotsPerLogicalPixel)
                .round(),
          ),
          bold: cell.bold,
          italic: cell.italic,
          underline: cell.underline,
          strikeThrough: cell.strikeThrough,
          colorArgb: cell.foreground.toARGB32(),
          horizontalAlign: cell.normalizedHorizontalAlign,
          verticalAlign: cell.normalizedVerticalAlign,
          wrap: cell.normalizedTextWrap == '2',
          predictedPaintedFootprint: predicted,
        ),
      );
    }
  }
  final plan = fortuneFinalizeHybridRenderPlan(
    settings: settings,
    sheet: sheet,
    range: geometry.range,
    transform: geometry.transform,
    candidates: candidates,
    approvals: descriptors.map((descriptor) => descriptor.approval),
  );
  return LabelSheetWindowsHybridPreparation(
    geometry: geometry,
    descriptors: List.unmodifiable(descriptors),
    plan: plan,
  );
}

class LabelSheetEzplNativeDescriptor {
  const LabelSheetEzplNativeDescriptor({
    required this.candidateToken,
    required this.command,
    required this.predictedPaintedFootprint,
    this.utf8 = false,
    this.textCharacters = 0,
    this.fontHeightDots,
    this.lineCount = 0,
    this.textLineFootprints = const <ui.Rect>[],
  });

  final String candidateToken;
  final String command;
  final ui.Rect predictedPaintedFootprint;
  final bool utf8;
  final int textCharacters;
  final int? fontHeightDots;
  final int lineCount;
  final List<ui.Rect> textLineFootprints;

  FortuneNativeCandidateApproval get approval =>
      FortuneNativeCandidateApproval(
        candidateToken: candidateToken,
        predictedPaintedFootprint: predictedPaintedFootprint,
      );
}

List<LabelSheetEzplNativeDescriptor> preflightLabelSheetEzplCandidates({
  required FortuneSheet sheet,
  required FortuneSettings settings,
  required FortunePrintTransform transform,
  required Iterable<FortuneNativeCandidate> candidates,
  int? lineSpacingPercent,
  Map<String, int>? textRejectionCounts,
}) {
  final descriptors = <LabelSheetEzplNativeDescriptor>[];
  for (final candidate in candidates) {
    if (candidate.kind == FortuneNativeCandidateKind.barcode) {
      final descriptor = _preflightEzplBarcodeCandidate(
        sheet: sheet,
        transform: transform,
        candidate: candidate,
      );
      if (descriptor != null) descriptors.add(descriptor);
      continue;
    }
    if (candidate.kind == FortuneNativeCandidateKind.cellText) {
      final descriptor = _preflightEzplTextCandidate(
        sheet: sheet,
        settings: settings,
        transform: transform,
        candidate: candidate,
        lineSpacingPercent: lineSpacingPercent,
        onRejected: (reason) {
          textRejectionCounts?.update(
            reason,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        },
      );
      if (descriptor != null) descriptors.add(descriptor);
      continue;
    }
    final strokeWidthMm = switch (candidate.kind) {
      FortuneNativeCandidateKind.line => sheet.lines
          .where((line) => line.id == candidate.objectKey!.id)
          .map((line) => line.strokeWidthMm)
          .firstOrNull,
      FortuneNativeCandidateKind.rectangle => sheet.shapes
          .where((shape) {
            return shape.id == candidate.objectKey!.id &&
                fortuneShapeObjectKind(shape) == candidate.objectKey!.kind;
          })
          .map((shape) => shape.strokeWidthMm)
          .firstOrNull,
      FortuneNativeCandidateKind.barcode => null,
      FortuneNativeCandidateKind.cellBorder =>
        math.min(
              candidate.printerPaintedFootprint.width,
              candidate.printerPaintedFootprint.height,
            ) /
            transform.dotsPerMillimeter,
          FortuneNativeCandidateKind.cellText => null,
    };
    if (strokeWidthMm == null) continue;
    final strokeDots = math.max(
      1,
      (strokeWidthMm * transform.dotsPerMillimeter).round(),
    );
    final target = candidate.printerPaintedFootprint;
    final left = target.left.round();
    final top = target.top.round();
    final right = target.right.round();
    final bottom = target.bottom.round();
    if (left < 0 || top < 0 || right <= left || bottom <= top) {
      continue;
    }
    final predicted = ui.Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right.toDouble(),
      bottom.toDouble(),
    );
    descriptors.add(
      LabelSheetEzplNativeDescriptor(
        candidateToken: candidate.token,
        command: 'R$left,$top,$right,$bottom,$strokeDots,$strokeDots\r\n',
        predictedPaintedFootprint: predicted,
      ),
    );
  }
  return List.unmodifiable(descriptors);
}

LabelSheetEzplNativeDescriptor? _preflightEzplTextCandidate({
  required FortuneSheet sheet,
  required FortuneSettings settings,
  required FortunePrintTransform transform,
  required FortuneNativeCandidate candidate,
  required int? lineSpacingPercent,
  required void Function(String reason) onRejected,
}) {
  final coord = candidate.cellCoord;
  final cell = coord == null ? null : sheet.cells[coord];
  final rejectionReason = cell == null
      ? 'missingCell'
      : cell.renderedText.isEmpty
      ? 'emptyText'
      : cell.inlineRuns?.isNotEmpty == true
      ? 'inlineRuns'
      : cell.isVerticalText
      ? 'verticalText'
      : cell.normalizedTextRotation != 0
      ? 'rotatedText'
      : cell.normalizedTextWrap == '1'
      ? 'overflowText'
      : cell.normalizedHorizontalAlign == '3'
      ? 'justifyText'
      : cell.strikeThrough
      ? 'strikeThrough'
      : cell.foreground.toARGB32() != 0xff000000
      ? 'nonBlackText'
      : cell.extraFields[fortuneCellTextOffsetYExtraKey] != null
      ? 'customOffsetY'
      : null;
  if (rejectionReason != null) {
    onRejected(rejectionReason);
    return null;
  }
  final resolvedCell = cell!;
  final target = candidate.printerPaintedFootprint;
  final layout = fortuneLayoutCellText(
    settings: settings,
    cell: resolvedCell,
    logicalBounds:
      candidate.logicalTextLayoutBounds ?? candidate.logicalPaintedFootprint,
    outputLineHeightMultiplier: lineSpacingPercent == null
        ? null
        : lineSpacingPercent / 100,
  );
  if (layout == null || layout.painter.didExceedMaxLines) {
    onRejected('textLayout');
    return null;
  }
  final layoutBounds =
      candidate.logicalTextLayoutBounds ?? candidate.logicalPaintedFootprint;
  const layoutTolerance = 0.5;
  for (final line in layout.lines) {
    if (line.logicalLeft < layoutBounds.left - layoutTolerance ||
        line.logicalLeft + line.logicalWidth >
            layoutBounds.right + layoutTolerance) {
      onRejected('widthOverflow');
      return null;
    }
    if (line.logicalTop < layoutBounds.top - layoutTolerance ||
        line.logicalTop + line.logicalHeight >
            layoutBounds.bottom + layoutTolerance) {
      onRejected('heightOverflow');
      return null;
    }
  }
  final fontHeight = math.max(
    8,
    (layout.fontSize * transform.dotsPerLogicalPixel)
        .round(),
  );
  final style = StringBuffer('0');
  if (resolvedCell.bold) style.write('B');
  if (resolvedCell.italic) style.write('T');
  if (resolvedCell.underline) style.write('U');
  style.write('E');
  final command = StringBuffer();
  final textLineFootprints = <ui.Rect>[];
  for (final line in layout.lines) {
    final lineDots = transform.logicalRectToPrinterDots(
      ui.Rect.fromLTWH(
        line.logicalLeft,
        line.logicalTop,
        line.logicalWidth,
        line.logicalHeight,
      ),
    );
    final left = lineDots.left.round();
    final top = lineDots.top.round();
    textLineFootprints.add(lineDots);
    command.write(
      'AT,$left,$top,$fontHeight,$fontHeight,0,'
      '$style,0,0,${_escapeEzplText(line.text)}\r\n',
    );
  }
  return LabelSheetEzplNativeDescriptor(
    candidateToken: candidate.token,
    command: command.toString(),
    predictedPaintedFootprint: target,
    utf8: true,
    textCharacters: resolvedCell.renderedText.runes.length,
    fontHeightDots: fontHeight,
    lineCount: layout.lines.length,
    textLineFootprints: List.unmodifiable(textLineFootprints),
  );
}

LabelSheetEzplNativeDescriptor? _preflightEzplBarcodeCandidate({
  required FortuneSheet sheet,
  required FortunePrintTransform transform,
  required FortuneNativeCandidate candidate,
}) {
  final key = candidate.objectKey;
  if (key == null) return null;
  final image = sheet.images
      .where((image) => image.id == key.id && image.extraFields['fortuneBarcode'] == true)
      .firstOrNull;
  if (image == null || image.extraFields['barcodeShowText'] == true) return null;
  if (_metadataDouble(image.extraFields['rotation'], 0).abs() > 0.001) {
    return null;
  }
  final text = image.extraFields['barcodeText']?.toString().trim() ?? '';
  final format = image.extraFields['barcodeFormatId']?.toString() ?? '';
  final command = _ezplBarcodeCommandForFormat(format);
  final narrow = math.max(
    1,
    _metadataDouble(image.extraFields['barcodeModuleScale'], 2).round(),
  );
  final wide = math.max(narrow + 1, (narrow * 2.5).round());
  final width = _ezplBarcodePaintedWidth(
    format: format,
    text: text,
    narrow: narrow,
    wide: wide,
  );
  if (command == null || width == null || text.isEmpty) return null;
  final height = math.max(
    8,
    (_metadataDouble(
          image.extraFields['barcodeBarHeight'],
          image.height,
        ) *
        transform.dotsPerLogicalPixel).round(),
  );
  final target = candidate.printerPaintedFootprint;
  final left = target.left.round();
  final top = target.top.round();
  final predicted = ui.Rect.fromLTWH(
    left.toDouble(),
    top.toDouble(),
    width.toDouble(),
    height.toDouble(),
  );
  return LabelSheetEzplNativeDescriptor(
    candidateToken: candidate.token,
    command: '$command$left,$top,$narrow,$wide,$height,0,0,'
        '${_escapeEzplText(text)}\r\n',
    predictedPaintedFootprint: predicted,
  );
}

int? _ezplBarcodePaintedWidth({
  required String format,
  required String text,
  required int narrow,
  required int wide,
}) {
  final normalized = format.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (normalized.contains('ean13')) {
    return RegExp(r'^\d{12,13}$').hasMatch(text) ? 95 * narrow : null;
  }
  if (normalized.contains('ean8')) {
    return RegExp(r'^\d{7,8}$').hasMatch(text) ? 67 * narrow : null;
  }
  if (normalized.contains('code128')) {
    if (!text.codeUnits.every((code) => code >= 32 && code <= 126)) return null;
    final dataCodewords = RegExp(r'^\d+$').hasMatch(text) && text.length.isEven
        ? text.length ~/ 2
        : text.length;
    return (11 * (dataCodewords + 2) + 13) * narrow;
  }
  if (normalized.contains('code39')) {
    if (!RegExp(r'^[0-9A-Z .\-$/+%]+$').hasMatch(text)) return null;
    final symbols = text.length + 2;
    return symbols * (3 * wide + 6 * narrow) + (symbols - 1) * narrow;
  }
  return null;
}

Future<Uint8List> buildLabelSheetPlannedHybridEzplBytes({
  required Uint8List filteredPngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
  required FortuneHybridRenderPlan plan,
  required Iterable<LabelSheetEzplNativeDescriptor> descriptors,
}) async {
  final source = img.decodePng(filteredPngBytes);
  if (source == null) {
    throw StateError('라벨 이미지를 EZPL 출력 이미지로 변환할 수 없습니다.');
  }
  final descriptorByToken = <String, LabelSheetEzplNativeDescriptor>{};
  for (final descriptor in descriptors) {
    if (!plan.approvedCandidateTokens.contains(descriptor.candidateToken) ||
        descriptorByToken.containsKey(descriptor.candidateToken)) {
      continue;
    }
    descriptorByToken[descriptor.candidateToken] = descriptor;
  }
  final layout = LabelSheetPrintLayout.resolve(
    metrics: metrics,
    options: options,
  );
  final raster = img.Image(
    width: metrics.dotsFromMm(metrics.pageWidthMm),
    height: metrics.dotsFromMm(metrics.pageHeightMm(options)),
  );
  img.fill(raster, color: img.ColorRgb8(255, 255, 255));
  final content = _prepareRasterContent(
    source: source,
    metrics: metrics,
    options: options,
  );
  img.compositeImage(
    raster,
    content,
    dstX: metrics.signedDotsFromMm(layout.contentLeftMm),
    dstY: metrics.signedDotsFromMm(layout.contentTopMm),
  );
  _clipRasterToLabelArea(raster, metrics: metrics, options: options);
  final commands = BytesBuilder(copy: false)
    ..add(ascii.encode('^Q${metrics.pageHeightMm(options).round()},0,0\r\n'))
    ..add(ascii.encode('^W ${metrics.pageWidthMm.round()}\r\n'))
    ..add(ascii.encode('^P${options.copies}\r\n'))
    ..add(ascii.encode('^L\r\n'));
  _addEzplRasterGraphic(commands, raster);
  for (final candidate in plan.candidates) {
    final descriptor = descriptorByToken[candidate.token];
    if (descriptor != null) {
      commands.add(
        descriptor.utf8
        ? utf8.encode(descriptor.command)
        : ascii.encode(descriptor.command),
      );
    }
  }
  commands.add(ascii.encode('E\r\n'));
  return commands.takeBytes();
}

Future<Uint8List> buildLabelSheetPdfGroupBytes(
  List<LabelSheetRenderedPage> pages,
) async {
  final document = pw.Document();
  for (final page in pages) {
    final layout = LabelSheetPrintLayout.resolve(
      metrics: page.metrics,
      options: page.options,
    );
    final image = pw.MemoryImage(page.pngBytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          _mmToPdfPoints(layout.pageWidthMm),
          _mmToPdfPoints(layout.pageHeightMm),
          marginAll: 0,
        ),
        build: (_) => _buildPdfPageContent(
          image: image,
          metrics: page.metrics,
          options: page.options,
        ),
      ),
    );
  }
  return document.save();
}

Future<Uint8List> buildLabelSheetEzplGroupBytes(
  List<LabelSheetRenderedPage> pages,
) async {
  final result = BytesBuilder(copy: false);
  for (final page in pages) {
    result.add(
      await buildLabelSheetEzplRasterBytes(
        pngBytes: page.pngBytes,
        metrics: page.metrics,
        options: page.options,
      ),
    );
  }
  return result.takeBytes();
}

Future<Uint8List> buildLabelSheetPdfBytes({
  required Uint8List pngBytes,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) async {
  final layout = LabelSheetPrintLayout.resolve(
    metrics: metrics,
    options: options,
  );
  final pageWidth = _mmToPdfPoints(layout.pageWidthMm);
  final pageHeight = _mmToPdfPoints(layout.pageHeightMm);
  final document = pw.Document();
  final image = pw.MemoryImage(pngBytes);

  for (var copy = 0; copy < options.copies; copy += 1) {
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
        build: (_) => _buildPdfPageContent(
          image: image,
          metrics: metrics,
          options: options,
        ),
      ),
    );
  }

  return document.save();
}

pw.Widget _buildPdfPageContent({
  required pw.MemoryImage image,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final layout = LabelSheetPrintLayout.resolve(
    metrics: metrics,
    options: options,
  );
  return pw.Stack(
    children: [
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.SizedBox(
          width: _mmToPdfPoints(math.max(0, layout.clipRightMm)),
          height: _mmToPdfPoints(metrics.labelHeightMm),
          child: pw.ClipRect(
            child: pw.Stack(
              children: [
                pw.Positioned(
                  left: _mmToPdfPoints(layout.contentLeftMm),
                  top: _mmToPdfPoints(layout.contentTopMm),
                  child: pw.Transform.rotateBox(
                    angle: options.rotateQuarterTurns ? math.pi / 2 : 0,
                    child: pw.Image(
                      image,
                      width: _mmToPdfPoints(metrics.effectiveSourceWidthMm),
                      height: _mmToPdfPoints(metrics.effectiveSourceHeightMm),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
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

  final layout = LabelSheetPrintLayout.resolve(
    metrics: metrics,
    options: options,
  );
  final labelWidthDots = metrics.dotsFromMm(metrics.labelWidthMm);
  final pageWidthDots = labelWidthDots;
  final pageHeightDots = metrics.dotsFromMm(metrics.pageHeightMm(options));
  final leftDots = metrics.signedDotsFromMm(layout.contentLeftMm);
  final topDots = metrics.signedDotsFromMm(layout.contentTopMm);
  final content = _prepareRasterContent(
    source: source,
    metrics: metrics,
    options: options,
  );
  final raster = img.Image(width: pageWidthDots, height: pageHeightDots);
  img.fill(raster, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(raster, content, dstX: leftDots, dstY: topDots);
  _clipRasterToLabelArea(
    raster,
    metrics: metrics,
    options: options,
  );

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
      if (luminance <= _labelSheetEzplInkLuminanceThreshold) {
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

img.Image _prepareRasterContent({
  required img.Image source,
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final oriented = options.rotateQuarterTurns
      ? img.copyRotate(source, angle: 90)
      : source;
  final layout = LabelSheetPrintLayout.resolve(
    metrics: metrics,
    options: options,
  );
  return img.copyResize(
    oriented,
    width: metrics.dotsFromMm(layout.contentWidthMm),
    height: metrics.dotsFromMm(layout.contentHeightMm),
    interpolation: img.Interpolation.average,
  );
}

void _clipRasterToLabelArea(
  img.Image raster, {
  required LabelSheetPrintPageMetrics metrics,
  required LabelSheetPrintOptions options,
}) {
  final white = img.ColorRgb8(255, 255, 255);
  final clipRight = metrics.signedDotsFromMm(
    metrics.pageWidthMm - options.rightMarginMm,
  );
  if (clipRight < raster.width) {
    img.fillRect(
      raster,
      x1: math.max(0, clipRight),
      y1: 0,
      x2: raster.width - 1,
      y2: raster.height - 1,
      color: white,
    );
  }
  final labelBottom = metrics.dotsFromMm(metrics.labelHeightMm);
  if (labelBottom < raster.height) {
    img.fillRect(
      raster,
      x1: 0,
      y1: labelBottom,
      x2: raster.width - 1,
      y2: raster.height - 1,
      color: white,
    );
  }
}

void _addEzplRasterGraphic(BytesBuilder commands, img.Image raster) {
  final bytesPerRow = (raster.width + 7) ~/ 8;
  commands.add(ascii.encode('~G\r\n'));

  for (var y = 0; y < raster.height; y += 1) {
    final row = Uint8List(bytesPerRow);
    for (var x = 0; x < raster.width; x += 1) {
      final pixel = raster.getPixel(x, y);
      final luminance = img.getLuminance(pixel);
      if (luminance <= _labelSheetEzplInkLuminanceThreshold) {
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

String _escapeEzplText(String value) {
  return value.replaceAll('\r', ' ').replaceAll('\n', ' ');
}

double _mmToPdfPoints(num millimeters) =>
    millimeters * PdfPageFormat.mm;
