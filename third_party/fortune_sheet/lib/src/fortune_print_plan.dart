import 'dart:math' as math;
import 'dart:ui';

import 'fortune_sheet_model.dart' hide Rect;
import 'fortune_sheet_painter.dart';

enum FortuneNativeCandidateKind { barcode, line, rectangle }

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
    required this.objectKey,
    required this.logicalPaintedFootprint,
    required this.printerPaintedFootprint,
  });

  final String token;
  final FortuneNativeCandidateKind kind;
  final FortuneSheetObjectKey objectKey;
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
  }) : candidates = List.unmodifiable(candidates),
       approvedCandidateTokens = Set.unmodifiable(approvedCandidateTokens),
       approvedObjectKeys = Set.unmodifiable(approvedObjectKeys);

  final FortuneSheet sheet;
  final FortuneSettings settings;
  final FortuneRange range;
  final FortunePrintTransform transform;
  final List<FortuneNativeCandidate> candidates;
  final Set<String> approvedCandidateTokens;
  final Set<FortuneSheetObjectKey> approvedObjectKeys;
}

List<FortuneNativeCandidate> fortuneBuildNativeCandidates({
  required FortuneSheet sheet,
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
      .map((overlay) => overlay.rect)
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
    approvedKeys.add(entry.value.objectKey);
  }
  return FortuneHybridRenderPlan(
    settings: settings,
    sheet: sheet,
    range: range,
    transform: transform,
    candidates: candidateList,
    approvedCandidateTokens: approvedTokens,
    approvedObjectKeys: approvedKeys,
  );
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
    return Rect.fromLTWH(image.left, image.top, image.width, image.height);
  }
  final lineIndex = object.sourceIndex - sheet.images.length;
  if (lineIndex < sheet.lines.length) {
    final line = sheet.lines[lineIndex];
    final halfStroke =
        fortuneMillimetersToLogicalPixels(line.strokeWidthMm) / 2;
    return Rect.fromPoints(
      Offset(line.x1, line.y1),
      Offset(line.x2, line.y2),
    ).inflate(halfStroke);
  }
  final shape = sheet.shapes[lineIndex - sheet.lines.length];
  final halfStroke =
      fortuneMillimetersToLogicalPixels(shape.strokeWidthMm) / 2;
  final rect = Rect.fromLTWH(shape.left, shape.top, shape.width, shape.height);
  if (shape.rotationDegrees % 360 == 0) return rect.inflate(halfStroke);
  final radians = shape.rotationDegrees * math.pi / 180;
  final rotatedWidth =
      rect.width * math.cos(radians).abs() + rect.height * math.sin(radians).abs();
  final rotatedHeight =
      rect.width * math.sin(radians).abs() + rect.height * math.cos(radians).abs();
  return Rect.fromCenter(
    center: rect.center,
    width: rotatedWidth,
    height: rotatedHeight,
  ).inflate(halfStroke);
}

bool _sameRect(Rect left, Rect right) => _rectWithinTolerance(left, right, 1e-9);

bool _rectWithinTolerance(Rect left, Rect right, double tolerance) {
  return (left.left - right.left).abs() <= tolerance &&
      (left.top - right.top).abs() <= tolerance &&
      (left.right - right.right).abs() <= tolerance &&
      (left.bottom - right.bottom).abs() <= tolerance;
}