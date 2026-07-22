import 'dart:math' as math;
import 'dart:ui';

import 'fortune_border_compute.dart';
import 'fortune_sheet_model.dart' hide Rect;
import 'fortune_sheet_painter.dart';

enum FortuneNativeCandidateKind { barcode, line, rectangle, cellBorder }

enum FortuneCellBorderEdgeAxis { vertical, horizontal }

class FortuneCellBorderEdgeKey {
  const FortuneCellBorderEdgeKey({
    required this.axis,
    required this.row,
    required this.column,
  });

  final FortuneCellBorderEdgeAxis axis;
  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is FortuneCellBorderEdgeKey &&
      axis == other.axis &&
      row == other.row &&
      column == other.column;

  @override
  int get hashCode => Object.hash(axis, row, column);
}

class FortunePrintTransform {
  const FortunePrintTransform({
    required this.sourceLogicalBounds,
    required this.dpi,
    required this.contentLeftMm,
    required this.contentTopMm,
    required this.clipRightMm,
    required this.clipBottomMm,
    required this.nativeAllowed,
  });

  final Rect sourceLogicalBounds;
  final double dpi;
  final double contentLeftMm;
  final double contentTopMm;
  final double clipRightMm;
  final double clipBottomMm;
  final bool nativeAllowed;

  double get dotsPerLogicalPixel => dpi / fortuneSheetLogicalPixelsPerInch;
  double get dotsPerMillimeter => dpi / 25.4;

  Rect logicalRectToPrinterDots(Rect rect) {
    final scale = dotsPerLogicalPixel;
    return Rect.fromLTRB(
      contentLeftMm * dotsPerMillimeter +
          (rect.left - sourceLogicalBounds.left) * scale,
      contentTopMm * dotsPerMillimeter +
          (rect.top - sourceLogicalBounds.top) * scale,
      contentLeftMm * dotsPerMillimeter +
          (rect.right - sourceLogicalBounds.left) * scale,
      contentTopMm * dotsPerMillimeter +
          (rect.bottom - sourceLogicalBounds.top) * scale,
    );
  }

  Rect get printerClipDots => Rect.fromLTRB(
    0,
    0,
    clipRightMm * dotsPerMillimeter,
    clipBottomMm * dotsPerMillimeter,
  );
}

class FortuneNativeCandidate {
  const FortuneNativeCandidate({
    required this.token,
    required this.kind,
    this.objectKey,
    this.cellBorderEdgeKey,
    required this.logicalPaintedFootprint,
    required this.printerPaintedFootprint,
  });

  final String token;
  final FortuneNativeCandidateKind kind;
  final FortuneSheetObjectKey? objectKey;
  final FortuneCellBorderEdgeKey? cellBorderEdgeKey;
  final Rect logicalPaintedFootprint;
  final Rect printerPaintedFootprint;
}

class FortuneNativeCandidateApproval {
  const FortuneNativeCandidateApproval({
    required this.candidateToken,
    required this.predictedPaintedFootprint,
  });

  final String candidateToken;
  final Rect predictedPaintedFootprint;
}

class FortuneHybridRenderPlan {
  FortuneHybridRenderPlan({
    required this.settings,
    required this.sheet,
    required this.range,
    required this.transform,
    required Iterable<FortuneNativeCandidate> candidates,
    required Iterable<String> approvedCandidateTokens,
    required Iterable<FortuneSheetObjectKey> approvedObjectKeys,
    required Iterable<FortuneCellBorderEdgeKey> approvedCellBorderEdgeKeys,
  }) : candidates = List.unmodifiable(candidates),
       approvedCandidateTokens = Set.unmodifiable(approvedCandidateTokens),
       approvedObjectKeys = Set.unmodifiable(approvedObjectKeys),
       approvedCellBorderEdgeKeys = Set.unmodifiable(
         approvedCellBorderEdgeKeys,
       );

  final FortuneSheet sheet;
  final FortuneSettings settings;
  final FortuneRange range;
  final FortunePrintTransform transform;
  final List<FortuneNativeCandidate> candidates;
  final Set<String> approvedCandidateTokens;
  final Set<FortuneSheetObjectKey> approvedObjectKeys;
  final Set<FortuneCellBorderEdgeKey> approvedCellBorderEdgeKeys;
}

List<FortuneNativeCandidate> fortuneBuildNativeCandidates({
  required FortuneSettings settings,
  required FortuneSheet sheet,
  required FortuneRange range,
  required FortunePrintTransform transform,
}) {
  if (!transform.nativeAllowed || !transform.dpi.isFinite || transform.dpi <= 0) {
    return const [];
  }
  final objects = fortuneSheetObjectsInPaintOrder(sheet);
  final footprints = [
    for (final object in objects) _objectPaintedFootprint(sheet, object),
  ];
  final rawFootprints = fortuneRawShapeOverlays(sheet)
      .map((overlay) {
        if (overlay.kind != 'line') return overlay.rect;
        final strokeRadius = math.max(1, overlay.strokeWidth) / 2;
        return overlay.rect.inflate(strokeRadius);
      })
      .toList(growable: false);
  final candidates = <FortuneNativeCandidate>[];
  for (var index = 0; index < objects.length; index += 1) {
    final object = objects[index];
    final kind = _nativeKind(sheet, object);
    if (kind == null) continue;
    final footprint = footprints[index];
    final obscuresLaterObject = footprints
        .skip(index + 1)
        .any((later) => later.overlaps(footprint));
    if (obscuresLaterObject || rawFootprints.any((raw) => raw.overlaps(footprint))) {
      continue;
    }
    final printerFootprint = transform.logicalRectToPrinterDots(footprint);
    final clipped = printerFootprint.intersect(transform.printerClipDots);
    if (!_sameRect(clipped, printerFootprint)) continue;
    candidates.add(
      FortuneNativeCandidate(
        token: 'object:${object.key.kind.name}:${object.key.id}:$index',
        kind: kind,
        objectKey: object.key,
        logicalPaintedFootprint: footprint,
        printerPaintedFootprint: printerFootprint,
      ),
    );
  }
  candidates.addAll(
    _buildCellBorderCandidates(
      settings: settings,
      sheet: sheet,
      range: range,
      transform: transform,
      objectFootprints: footprints,
      rawOverlayFootprints: rawFootprints,
    ),
  );
  return List.unmodifiable(candidates);
}

FortuneHybridRenderPlan fortuneFinalizeHybridRenderPlan({
  required FortuneSettings settings,
  required FortuneSheet sheet,
  required FortuneRange range,
  required FortunePrintTransform transform,
  required Iterable<FortuneNativeCandidate> candidates,
  required Iterable<FortuneNativeCandidateApproval> approvals,
}) {
  final candidateList = List<FortuneNativeCandidate>.unmodifiable(candidates);
  final candidatesByToken = {
    for (final candidate in candidateList) candidate.token: candidate,
  };
  final approvalCounts = <String, int>{};
  final approvalByToken = <String, FortuneNativeCandidateApproval>{};
  for (final approval in approvals) {
    approvalCounts.update(
      approval.candidateToken,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    approvalByToken[approval.candidateToken] = approval;
  }
  final approvedTokens = <String>{};
  final approvedKeys = <FortuneSheetObjectKey>{};
  final approvedEdgeKeys = <FortuneCellBorderEdgeKey>{};
  for (final entry in candidatesByToken.entries) {
    if (approvalCounts[entry.key] != 1) continue;
    final approval = approvalByToken[entry.key]!;
    if (!_rectWithinTolerance(
      approval.predictedPaintedFootprint,
      entry.value.printerPaintedFootprint,
      0.5,
    )) {
      continue;
    }
    approvedTokens.add(entry.key);
    if (entry.value.objectKey case final objectKey?) {
      approvedKeys.add(objectKey);
    }
    if (entry.value.cellBorderEdgeKey case final edgeKey?) {
      approvedEdgeKeys.add(edgeKey);
    }
  }
  return FortuneHybridRenderPlan(
    settings: settings,
    sheet: sheet,
    range: range,
    transform: transform,
    candidates: candidateList,
    approvedCandidateTokens: approvedTokens,
    approvedObjectKeys: approvedKeys,
    approvedCellBorderEdgeKeys: approvedEdgeKeys,
  );
}

List<FortuneNativeCandidate> _buildCellBorderCandidates({
  required FortuneSettings settings,
  required FortuneSheet sheet,
  required FortuneRange range,
  required FortunePrintTransform transform,
  required List<Rect> objectFootprints,
  required List<Rect> rawOverlayFootprints,
}) {
  final metrics = sheet.metrics(settings);
  final borders = FortuneBorderCompute.computeRange(sheet, range);
  final edges = <
    FortuneCellBorderEdgeKey,
    ({FortuneBorderSide side, Rect footprint})
  >{};

  void addEdge({
    required FortuneCellBorderEdgeKey key,
    required FortuneBorderSide? side,
    required Offset start,
    required Offset end,
  }) {
    if (side == null ||
        side.style != 1 ||
      side.color.toARGB32() != 0xff000000) {
      return;
    }
    final halfStroke = (side.strokeWidth ?? 1) / 2;
    final footprint = start.dy == end.dy
        ? Rect.fromLTRB(start.dx, start.dy - halfStroke, end.dx, end.dy + halfStroke)
        : Rect.fromLTRB(start.dx - halfStroke, start.dy, end.dx + halfStroke, end.dy);
    edges.putIfAbsent(key, () => (side: side, footprint: footprint));
  }

  for (final entry in borders.entries) {
    final row = entry.key.row;
    final column = entry.key.column;
    final left = metrics.columnStart(column);
    final right = metrics.columnEnd(column);
    final top = metrics.rowStart(row);
    final bottom = metrics.rowEnd(row);
    addEdge(
      key: FortuneCellBorderEdgeKey(
        axis: FortuneCellBorderEdgeAxis.horizontal,
        row: row,
        column: column,
      ),
      side: entry.value.top,
      start: Offset(left, top),
      end: Offset(right, top),
    );
    addEdge(
      key: FortuneCellBorderEdgeKey(
        axis: FortuneCellBorderEdgeAxis.vertical,
        row: row,
        column: column + 1,
      ),
      side: entry.value.right,
      start: Offset(right, top),
      end: Offset(right, bottom),
    );
    addEdge(
      key: FortuneCellBorderEdgeKey(
        axis: FortuneCellBorderEdgeAxis.horizontal,
        row: row + 1,
        column: column,
      ),
      side: entry.value.bottom,
      start: Offset(left, bottom),
      end: Offset(right, bottom),
    );
    addEdge(
      key: FortuneCellBorderEdgeKey(
        axis: FortuneCellBorderEdgeAxis.vertical,
        row: row,
        column: column,
      ),
      side: entry.value.left,
      start: Offset(left, top),
      end: Offset(left, bottom),
    );
  }

  final candidates = <FortuneNativeCandidate>[];
  var index = 0;
  for (final entry in edges.entries) {
    final logicalFootprint = entry.value.footprint;
    if (objectFootprints.any((object) => object.overlaps(logicalFootprint)) ||
        rawOverlayFootprints.any((raw) => raw.overlaps(logicalFootprint))) {
      continue;
    }
    final printerFootprint = transform.logicalRectToPrinterDots(
      logicalFootprint,
    );
    if (!_sameRect(
      printerFootprint.intersect(transform.printerClipDots),
      printerFootprint,
    )) {
      continue;
    }
    candidates.add(
      FortuneNativeCandidate(
        token: 'border:${entry.key.axis.name}:${entry.key.row}:'
            '${entry.key.column}:${index++}',
        kind: FortuneNativeCandidateKind.cellBorder,
        cellBorderEdgeKey: entry.key,
        logicalPaintedFootprint: logicalFootprint,
        printerPaintedFootprint: printerFootprint,
      ),
    );
  }
  return candidates;
}

FortuneNativeCandidateKind? _nativeKind(
  FortuneSheet sheet,
  FortuneSheetObjectRef object,
) {
  if (object.key.kind == FortuneSheetObjectKind.barcode) {
    return FortuneNativeCandidateKind.barcode;
  }
  if (object.key.kind == FortuneSheetObjectKind.line) {
    final line = sheet.lines[object.sourceIndex - sheet.images.length];
    final axisAligned = line.x1 == line.x2 || line.y1 == line.y2;
    return axisAligned &&
            line.strokeStyle == FortuneStrokeStyle.solid &&
            line.strokeColor.toUpperCase() == '#000000'
        ? FortuneNativeCandidateKind.line
        : null;
  }
  if (object.key.kind == FortuneSheetObjectKind.rectangle) {
    final shape = sheet.shapes[
      object.sourceIndex - sheet.images.length - sheet.lines.length
    ];
    return shape.rotationDegrees % 360 == 0 &&
            shape.fillColor == null &&
            shape.strokeStyle == FortuneStrokeStyle.solid &&
            shape.strokeColor.toUpperCase() == '#000000'
        ? FortuneNativeCandidateKind.rectangle
        : null;
  }
  return null;
}

Rect _objectPaintedFootprint(
  FortuneSheet sheet,
  FortuneSheetObjectRef object,
) {
  if (object.sourceIndex < sheet.images.length) {
    final image = sheet.images[object.sourceIndex];
    final imageRect = Rect.fromLTWH(
      image.left,
      image.top,
      image.width,
      image.height,
    );
    if (object.key.kind == FortuneSheetObjectKind.barcode) {
      final bodyTop = _extraDouble(
        image.extraFields[fortuneBarcodeBodyTopExtraKey],
        0,
      );
      final bodyHeight = _extraDouble(
        image.extraFields[fortuneBarcodeBodyHeightExtraKey],
        image.height,
      );
      final bodyRect = Rect.fromLTWH(
        image.left,
        image.top + bodyTop,
        image.width,
        bodyHeight,
      );
      return fortuneRotatedRectBounds(
        bodyRect,
        imageRect.center,
        fortuneImageRotationDegrees(image),
      );
    }
    return fortuneRotatedRectBounds(
      imageRect,
      imageRect.center,
      fortuneImageRotationDegrees(image),
    );
  }
  final lineIndex = object.sourceIndex - sheet.images.length;
  if (lineIndex < sheet.lines.length) {
    final line = sheet.lines[lineIndex];
    final halfStroke =
        fortuneMillimetersToLogicalPixels(line.strokeWidthMm) / 2;
    final dx = line.x2 - line.x1;
    final dy = line.y2 - line.y1;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) {
      return Rect.fromLTWH(line.x1, line.y1, 0, 0);
    }
    final xPadding = halfStroke * dy.abs() / length;
    final yPadding = halfStroke * dx.abs() / length;
    return Rect.fromLTRB(
      math.min(line.x1, line.x2) - xPadding,
      math.min(line.y1, line.y2) - yPadding,
      math.max(line.x1, line.x2) + xPadding,
      math.max(line.y1, line.y2) + yPadding,
    );
  }
  final shape = sheet.shapes[lineIndex - sheet.lines.length];
  final halfStroke =
      fortuneMillimetersToLogicalPixels(shape.strokeWidthMm) / 2;
  final rect = Rect.fromLTWH(shape.left, shape.top, shape.width, shape.height);
    final strokeBounds = shape.kind == FortuneShapeKind.rectangle
      ? rect.inflate(halfStroke)
      : rect;
    if (shape.rotationDegrees % 360 == 0) {
    return shape.kind == FortuneShapeKind.rectangle
      ? strokeBounds
      : rect.inflate(halfStroke);
    }
  final radians = shape.rotationDegrees * math.pi / 180;
  final rotatedWidth =
      strokeBounds.width * math.cos(radians).abs() +
      strokeBounds.height * math.sin(radians).abs();
  final rotatedHeight =
      strokeBounds.width * math.sin(radians).abs() +
      strokeBounds.height * math.cos(radians).abs();
    final rotatedBounds = Rect.fromCenter(
    center: rect.center,
    width: rotatedWidth,
    height: rotatedHeight,
    );
    return shape.kind == FortuneShapeKind.rectangle
      ? rotatedBounds
      : rotatedBounds.inflate(halfStroke);
}

double _extraDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool _sameRect(Rect left, Rect right) => _rectWithinTolerance(left, right, 1e-9);

bool _rectWithinTolerance(Rect left, Rect right, double tolerance) {
  return (left.left - right.left).abs() <= tolerance &&
      (left.top - right.top).abs() <= tolerance &&
      (left.right - right.right).abs() <= tolerance &&
      (left.bottom - right.bottom).abs() <= tolerance;
}