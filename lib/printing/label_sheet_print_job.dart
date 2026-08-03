import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    this.widthAppendMm = 0,
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
  final double widthAppendMm;
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
  String widthAppendMm = '0',
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
    widthAppendMm: nonNegativeDouble(widthAppendMm),
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

  double pageWidthMm(LabelSheetPrintOptions options) =>
      options.rotateQuarterTurns
      ? labelHeightMm.toDouble()
      : labelWidthMm.toDouble();
  double get effectiveSourceWidthMm => sourceWidthMm ?? labelWidthMm.toDouble();
  double get effectiveSourceHeightMm =>
      sourceHeightMm ?? labelHeightMm.toDouble();
  double pageHeightMm(LabelSheetPrintOptions options) =>
      (options.rotateQuarterTurns ? labelWidthMm : labelHeightMm).toDouble() +
      math.max(0, options.extraAreaMm);

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
    final pageWidthMm = metrics.pageWidthMm(options);
    final pageHeightMm = metrics.pageHeightMm(options);
    return LabelSheetPrintLayout(
      pageWidthMm: pageWidthMm,
      pageHeightMm: pageHeightMm,
      contentLeftMm: options.leftMarginMm + options.leftPushMm,
      contentTopMm: options.topMarginMm + options.topPushMm,
      contentWidthMm: rotated
          ? metrics.effectiveSourceHeightMm
          : metrics.effectiveSourceWidthMm,
      contentHeightMm: rotated
          ? metrics.effectiveSourceWidthMm
          : metrics.effectiveSourceHeightMm,
      clipRightMm: pageWidthMm - options.rightMarginMm,
      clipBottomMm: rotated
          ? metrics.labelWidthMm.toDouble()
          : metrics.labelHeightMm.toDouble(),
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
  final approvedTextCandidates = <String, FortuneNativeCandidate>{};
  if (options.orientation == LabelSheetPrintOrientation.horizontal) {
    for (final candidate in candidates) {
      if (candidate.kind != FortuneNativeCandidateKind.cellText ||
          candidate.cellCoord == null) {
        continue;
      }
      final cell = sheet.cells[candidate.cellCoord!];
      if (cell == null ||
          cell.renderedText.isEmpty ||
          !_windowsInlineRunsSupported(cell) ||
          cell.isVerticalText ||
          cell.normalizedTextRotation != 0 ||
          cell.normalizedTextWrap == '1' ||
          cell.normalizedHorizontalAlign == '3' ||
          cell.extraFields[fortuneCellTextOffsetYExtraKey] != null) {
        continue;
      }
      final layout = fortuneLayoutCellText(
        settings: settings,
        cell: cell,
        logicalBounds:
            candidate.logicalTextLayoutBounds ??
            candidate.logicalPaintedFootprint,
        textSpan: _labelSheetCellTextSpan(
          cell,
          settings,
          outputLineHeightMultiplier: lineSpacingPercent == null
              ? null
              : lineSpacingPercent / 100,
        ),
        outputLineHeightMultiplier: lineSpacingPercent == null
            ? null
            : lineSpacingPercent / 100,
      );
      if (layout == null || layout.painter.didExceedMaxLines) continue;
      final fragments = _labelSheetTextFragments(cell, layout, settings);
      if (fragments.isEmpty) continue;
      for (final fragment in fragments) {
        final target = geometry.transform.logicalRectToPrinterDots(
          ui.Rect.fromLTWH(
            fragment.logicalLeft,
            fragment.logicalTop,
            fragment.logicalWidth,
            fragment.logicalHeight,
          ),
        );
        final left = target.left.round();
        final top = target.top.round();
        final right = target.right.round();
        final bottom = target.bottom.round();
        if (right <= left || bottom <= top) continue;
        descriptors.add(
          LabelSheetWindowsTextDescriptor(
            candidateToken: candidate.token,
            text: fragment.text,
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            fontFamily: fragment.fontFamily,
          fontPixelHeight: math.max(
            1,
              (fragment.fontSize * geometry.transform.dotsPerLogicalPixel)
                  .round(),
          ),
            bold: fragment.bold,
            italic: fragment.italic,
            underline: fragment.underline,
            strikeThrough: fragment.strikeThrough,
            colorArgb: fragment.colorArgb,
            horizontalAlign: '1',
            verticalAlign: '1',
            wrap: false,
            predictedPaintedFootprint: candidate.printerPaintedFootprint,
          ),
        );
      }
      if (descriptors.any(
        (descriptor) => descriptor.candidateToken == candidate.token,
      )) {
        approvedTextCandidates[candidate.token] = candidate;
      }
    }
  }
  final plan = fortuneFinalizeHybridRenderPlan(
    settings: settings,
    sheet: sheet,
    range: geometry.range,
    transform: geometry.transform,
    candidates: candidates,
    approvals: approvedTextCandidates.values.map(
      (candidate) => FortuneNativeCandidateApproval(
        candidateToken: candidate.token,
        predictedPaintedFootprint: candidate.printerPaintedFootprint,
      ),
    ),
  );
  return LabelSheetWindowsHybridPreparation(
    geometry: geometry,
    descriptors: List.unmodifiable(descriptors),
    plan: plan,
  );
}

bool _windowsInlineRunsSupported(FortuneCell cell) {
  final runs = cell.inlineRuns;
  if (runs == null || runs.isEmpty) return true;
  if (runs.map((run) => run.text).join() != cell.renderedText) return false;
  return runs.every(
    (run) =>
        run.extraFields['bg'] == null &&
        run.extraFields['script'] == null &&
        run.extraFields['fontScale'] == null &&
        run.extraFields['letterSpacing'] == null &&
        (run.fontSize == null ||
            (run.fontSize!.isFinite && run.fontSize! > 0)),
  );
}

InlineSpan _labelSheetCellTextSpan(
  FortuneCell cell,
  FortuneSettings settings, {
  double? outputLineHeightMultiplier,
}) {
  final fontSize = cell.fontSize ?? settings.defaultFontSize;
  final cellLineHeight = _labelSheetOutputLineHeight(
    cell.extraFields,
    outputLineHeightMultiplier,
  );
  final resolvedFamily = fortuneResolveFontFamily(
    cell.fontFamily,
    settings.fontFamilies,
  );
  final baseStyle = TextStyle(
    fontSize: fontSize,
    fontFamily: resolvedFamily,
    fontWeight: cell.bold ? FontWeight.w700 : FontWeight.w400,
    fontStyle: cell.italic ? FontStyle.italic : FontStyle.normal,
    height: cellLineHeight,
  );
  final runs = cell.inlineRuns;
  if (runs == null || runs.isEmpty) {
    return TextSpan(text: cell.renderedText, style: baseStyle);
  }
  return TextSpan(
    style: baseStyle,
    children: [
      for (final run in runs)
        TextSpan(
          text: run.text,
          style: baseStyle.copyWith(
            fontSize: run.fontSize ?? fontSize,
            fontFamily: fortuneResolveFontFamily(
              run.fontFamily,
              settings.fontFamilies,
              fallback: resolvedFamily,
            ),
            fontWeight: (run.bold ?? cell.bold)
                ? FontWeight.w700
                : FontWeight.w400,
            fontStyle: (run.italic ?? cell.italic)
                ? FontStyle.italic
                : FontStyle.normal,
            height: _labelSheetOutputLineHeight(
              run.extraFields,
              outputLineHeightMultiplier,
              fallback: cellLineHeight,
            ),
          ),
        ),
    ],
  );
}

double? _labelSheetOutputLineHeight(
  Map<String, Object?> extraFields,
  double? override, {
  double? fallback,
}) {
  if (override != null && override.isFinite && override > 0) return override;
  final raw = extraFields['lineHeight'];
  final stored = raw is num ? raw.toDouble() : double.tryParse('$raw');
  return stored != null && stored.isFinite && stored > 0 ? stored : fallback;
}

class _LabelSheetTextFragment {
  const _LabelSheetTextFragment({
    required this.text,
    required this.logicalLeft,
    required this.logicalTop,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.fontSize,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikeThrough,
    required this.fontFamily,
    required this.colorArgb,
  });

  final String text;
  final double logicalLeft;
  final double logicalTop;
  final double logicalWidth;
  final double logicalHeight;
  final double fontSize;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final String fontFamily;
  final int colorArgb;
}

List<_LabelSheetTextFragment> _labelSheetTextFragments(
  FortuneCell cell,
  FortuneNativeCellTextLayout layout,
  FortuneSettings settings,
) {
  final runs = cell.inlineRuns;
  if (runs == null || runs.isEmpty) {
    return [
      for (final line in layout.lines)
        _LabelSheetTextFragment(
          text: line.text,
          logicalLeft: line.logicalLeft,
          logicalTop: line.logicalTop,
          logicalWidth: line.logicalWidth,
          logicalHeight: line.logicalHeight,
          fontSize: layout.fontSize,
          bold: cell.bold,
          italic: cell.italic,
          underline: cell.underline,
          strikeThrough: cell.strikeThrough,
          fontFamily: fortuneResolveFontFamily(
            cell.fontFamily,
            settings.fontFamilies,
          ),
          colorArgb: cell.foreground.toARGB32(),
        ),
    ];
  }
  final fragments = <_LabelSheetTextFragment>[];
  var runStart = 0;
  for (final run in runs) {
    final runEnd = runStart + run.text.length;
    for (final line in layout.lines) {
      final start = math.max(runStart, line.textStart);
      var end = math.min(runEnd, line.textEnd);
      while (end > start &&
          (cell.renderedText.codeUnitAt(end - 1) == 0x0a ||
              cell.renderedText.codeUnitAt(end - 1) == 0x0d)) {
        end -= 1;
      }
      if (end <= start) continue;
      final boxes = layout.painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        boxHeightStyle: ui.BoxHeightStyle.strut,
        boxWidthStyle: ui.BoxWidthStyle.tight,
      );
      if (boxes.isEmpty) continue;
      final left = boxes.map((box) => box.left).reduce(math.min);
      final top = boxes.map((box) => box.top).reduce(math.min);
      final right = boxes.map((box) => box.right).reduce(math.max);
      final bottom = boxes.map((box) => box.bottom).reduce(math.max);
      fragments.add(
        _LabelSheetTextFragment(
          text: cell.renderedText.substring(start, end),
          logicalLeft: layout.paintOffset.dx + left,
          logicalTop: layout.paintOffset.dy + top,
          logicalWidth: right - left,
          logicalHeight: bottom - top,
          fontSize: run.fontSize ?? cell.fontSize ?? layout.fontSize,
          bold: run.bold ?? cell.bold,
          italic: run.italic ?? cell.italic,
          underline: run.underline ?? cell.underline,
          strikeThrough: run.strikeThrough ?? cell.strikeThrough,
          fontFamily: fortuneResolveFontFamily(
            run.fontFamily ?? cell.fontFamily,
            settings.fontFamilies,
          ),
          colorArgb: (run.foreground ?? cell.foreground).toARGB32(),
        ),
      );
    }
    runStart = runEnd;
  }
  return fragments;
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

double _mmToPdfPoints(num millimeters) =>
    millimeters * PdfPageFormat.mm;
