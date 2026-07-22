import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

Future<ByteData> _decodeRawRgba(Uint8List pngBytes) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  final frame = await codec.getNextFrame();
  final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();
  return bytes!;
}

bool _isWhite(ByteData pixels, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return pixels.getUint8(offset) > 245 &&
      pixels.getUint8(offset + 1) > 245 &&
      pixels.getUint8(offset + 2) > 245;
}

int _countNonWhitePixels(ByteData pixels, int width, ui.Rect rect) {
  var count = 0;
  for (var y = rect.top.floor(); y < rect.bottom.ceil(); y += 1) {
    for (var x = rect.left.floor(); x < rect.right.ceil(); x += 1) {
      if (!_isWhite(pixels, width, x, y)) count += 1;
    }
  }
  return count;
}

void main() {
  const settings = FortuneSettings(
    defaultRowHeight: 20,
    defaultColWidth: 20,
  );
  final sheet = FortuneSheet(
    id: 's1',
    name: 'Sheet1',
    rowCount: 2,
    columnCount: 2,
    lines: const [
      FortuneLine(
        id: 'shared',
        x1: 2,
        y1: 10,
        x2: 18,
        y2: 10,
        strokeWidthMm: 1,
      ),
    ],
    shapes: const [
      FortuneShape(
        id: 'shared',
        kind: FortuneShapeKind.rectangle,
        left: 24,
        top: 24,
        width: 10,
        height: 10,
        fillColor: '#000000',
      ),
    ],
  );
  const range = FortuneRange(
    rowStart: 0,
    rowEnd: 1,
    columnStart: 0,
    columnEnd: 1,
  );
  const transform = FortunePrintTransform(
    sourceLogicalBounds: ui.Rect.fromLTWH(0, 0, 40, 40),
    dpi: 203,
    contentLeftMm: 0,
    contentTopMm: 0,
    clipRightMm: 100,
    clipBottomMm: 100,
    nativeAllowed: true,
  );

  test('duplicate candidate approvals remain raster fallback', () {
    final candidate = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: sheet,
      range: range,
      transform: transform,
    ).single;
    final approval = FortuneNativeCandidateApproval(
      candidateToken: candidate.token,
      predictedPaintedFootprint: candidate.printerPaintedFootprint,
    );
    final plan = fortuneFinalizeHybridRenderPlan(
      settings: settings,
      sheet: sheet,
      range: range,
      transform: transform,
      candidates: [candidate],
      approvals: [approval, approval],
    );
    expect(plan.approvedCandidateTokens, isEmpty);
    expect(plan.approvedObjectKeys, isEmpty);
  });

  test('native line footprint preserves butt endpoints', () {
    final lineSheet = FortuneSheet(
      id: 'line',
      name: 'Line',
      rowCount: 2,
      columnCount: 2,
      lines: const [
        FortuneLine(
          id: 'line_1',
          x1: 10,
          y1: 20,
          x2: 30,
          y2: 20,
          strokeWidthMm: 1,
        ),
      ],
    );

    final candidate = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: lineSheet,
      range: range,
      transform: transform,
    ).single;

    expect(candidate.logicalPaintedFootprint.left, 10);
    expect(candidate.logicalPaintedFootprint.right, 30);
  });

  test('rotated rectangle miter blocks a lower native line candidate', () {
    final strokeWidthMm = fortuneLogicalPixelsToMillimeters(10);
    final overlapSheet = FortuneSheet(
      id: 'miter-overlap',
      name: 'Miter overlap',
      rowCount: 5,
      columnCount: 5,
      lines: const [
        FortuneLine(
          id: 'native-line',
          x1: 28.9,
          y1: 50,
          x2: 30,
          y2: 50,
          strokeWidthMm: 0.1,
          zOrder: 0,
        ),
      ],
      shapes: [
        FortuneShape(
          id: 'upper-rectangle',
          kind: FortuneShapeKind.rectangle,
          left: 40,
          top: 40,
          width: 20,
          height: 20,
          rotationDegrees: 45,
          strokeWidthMm: strokeWidthMm,
          zOrder: 1,
        ),
      ],
    );
    const overlapTransform = FortunePrintTransform(
      sourceLogicalBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
      dpi: 203,
      contentLeftMm: 0,
      contentTopMm: 0,
      clipRightMm: 100,
      clipBottomMm: 100,
      nativeAllowed: true,
    );

    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: overlapSheet,
      range: const FortuneRange(
        rowStart: 0,
        rowEnd: 4,
        columnStart: 0,
        columnEnd: 4,
      ),
      transform: overlapTransform,
    );

    expect(candidates, isEmpty);
  });

  test('raw line round-cap footprint blocks overlapping native candidate', () {
    final overlapSheet = FortuneSheet(
      id: 'raw-line-overlap',
      name: 'Raw line overlap',
      rowCount: 5,
      columnCount: 5,
      lines: const [
        FortuneLine(
          id: 'native-line',
          x1: 15,
          y1: 18,
          x2: 19,
          y2: 18,
          strokeWidthMm: 0.1,
        ),
      ],
      extraFields: const {
        'shapes': [
          {
            'type': 'line',
            'left': 20,
            'top': 20,
            'width': 10,
            'height': 0,
            'strokeColor': '#000000',
            'strokeWidth': 10,
          },
        ],
      },
    );

    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: overlapSheet,
      range: const FortuneRange(
        rowStart: 0,
        rowEnd: 4,
        columnStart: 0,
        columnEnd: 4,
      ),
      transform: const FortunePrintTransform(
        sourceLogicalBounds: ui.Rect.fromLTWH(0, 0, 100, 100),
        dpi: 203,
        contentLeftMm: 0,
        contentTopMm: 0,
        clipRightMm: 100,
        clipBottomMm: 100,
        nativeAllowed: true,
      ),
    );

    expect(candidates, isEmpty);
  });

  test('adjacent border aliases share one physical edge candidate', () {
    final borderSheet = FortuneSheet(
      id: 'border',
      name: 'Border',
      rowCount: 1,
      columnCount: 2,
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-right',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 0,
              columnEnd: 0,
            ),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-left',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 1,
              columnEnd: 1,
            ),
          ],
        ),
      ],
    );
    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: borderSheet,
      range: const FortuneRange(
        rowStart: 0,
        rowEnd: 0,
        columnStart: 0,
        columnEnd: 1,
      ),
      transform: transform,
    ).where((candidate) => candidate.kind == FortuneNativeCandidateKind.cellBorder);

    expect(candidates, hasLength(1));
    expect(
      candidates.single.cellBorderEdgeKey,
      const FortuneCellBorderEdgeKey(
        axis: FortuneCellBorderEdgeAxis.vertical,
        row: 0,
        column: 1,
      ),
    );
  });

  test('border under a typed object remains raster fallback', () {
    final overlapSheet = FortuneSheet(
      id: 'overlap',
      name: 'Overlap',
      rowCount: 1,
      columnCount: 1,
      lines: const [
        FortuneLine(id: 'line', x1: 2, y1: 20, x2: 18, y2: 20),
      ],
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-bottom',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 0,
              columnEnd: 0,
            ),
          ],
        ),
      ],
    );
    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: overlapSheet,
      range: const FortuneRange(
        rowStart: 0,
        rowEnd: 0,
        columnStart: 0,
        columnEnd: 0,
      ),
      transform: transform,
    );

    expect(
      candidates.where(
        (candidate) => candidate.kind == FortuneNativeCandidateKind.cellBorder,
      ),
      isEmpty,
    );
  });

  test('border under a raw overlay remains raster fallback', () {
    final overlapSheet = FortuneSheet(
      id: 'raw-overlap',
      name: 'Raw overlap',
      rowCount: 1,
      columnCount: 1,
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-bottom',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 0,
              columnEnd: 0,
            ),
          ],
        ),
      ],
      extraFields: const {
        'shapes': [
          {
            'type': 'rect',
            'left': 2,
            'top': 18,
            'width': 16,
            'height': 4,
            'fillColor': '#FFFFFF',
          },
        ],
      },
    );

    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: overlapSheet,
      range: const FortuneRange(
        rowStart: 0,
        rowEnd: 0,
        columnStart: 0,
        columnEnd: 0,
      ),
      transform: transform,
    );

    expect(
      candidates.where(
        (candidate) => candidate.kind == FortuneNativeCandidateKind.cellBorder,
      ),
      isEmpty,
    );
  });

  testWidgets('filtered capture omits only approved exact typed key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FortuneSheetCanvas(
          workbook: FortuneWorkbook(settings: settings, sheets: [sheet]),
          controller: controller,
        ),
      ),
    );
    final candidate = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: sheet,
      range: range,
      transform: transform,
    ).single;
    final plan = fortuneFinalizeHybridRenderPlan(
      settings: settings,
      sheet: sheet,
      range: range,
      transform: transform,
      candidates: [candidate],
      approvals: [
        FortuneNativeCandidateApproval(
          candidateToken: candidate.token,
          predictedPaintedFootprint: candidate.printerPaintedFootprint,
        ),
      ],
    );
    final capture = await tester.runAsync(
      () => controller.captureHybridPlanAsPng(plan),
    );
    expect(capture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    final width = capture!.pixelSize.width.toInt();
    expect(_isWhite(pixels!, width, 10, 10), isTrue);
    expect(_isWhite(pixels, width, 29, 29), isFalse);
    expect(capture.sheet, same(sheet));
    expect(capture.range.rowEnd, 1);
  });

  testWidgets('hybrid capture uses snapshot settings for checkbox text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const liveSettings = FortuneSettings(
      defaultRowHeight: 40,
      defaultColWidth: 100,
      defaultFontSize: 4,
    );
    const snapshotSettings = FortuneSettings(
      defaultRowHeight: 40,
      defaultColWidth: 100,
      defaultFontSize: 12,
    );
    final captureSheet = FortuneSheet(
      id: 'snapshot',
      name: 'Snapshot',
      rowCount: 1,
      columnCount: 1,
      defaultRowHeight: 40,
      defaultColWidth: 100,
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: 'Wide',
          foreground: Color(0xff0000ff),
        ),
      },
      dataVerification: const {
        '0_0': {'type': 'checkbox', 'checked': true},
      },
    );
    const captureRange = FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 0,
    );
    const captureTransform = FortunePrintTransform(
      sourceLogicalBounds: ui.Rect.fromLTWH(0, 0, 100, 40),
      dpi: 203,
      contentLeftMm: 0,
      contentTopMm: 0,
      clipRightMm: 100,
      clipBottomMm: 100,
      nativeAllowed: true,
    );
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FortuneSheetCanvas(
          workbook: FortuneWorkbook(
            settings: liveSettings,
            sheets: [captureSheet],
          ),
          controller: controller,
        ),
      ),
    );
    final plan = fortuneFinalizeHybridRenderPlan(
      settings: snapshotSettings,
      sheet: captureSheet,
      range: captureRange,
      transform: captureTransform,
      candidates: const [],
      approvals: const [],
    );
    final liveSizePlan = fortuneFinalizeHybridRenderPlan(
      settings: liveSettings,
      sheet: captureSheet,
      range: captureRange,
      transform: captureTransform,
      candidates: const [],
      approvals: const [],
    );

    final capture = await tester.runAsync(
      () => controller.captureHybridPlanAsPng(plan, pixelRatio: 1),
    );
    final liveSizeCapture = await tester.runAsync(
      () => controller.captureHybridPlanAsPng(liveSizePlan, pixelRatio: 1),
    );
    expect(capture, isNotNull);
    expect(liveSizeCapture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    final liveSizePixels = await tester.runAsync(
      () => _decodeRawRgba(liveSizeCapture!.pngBytes),
    );
    const labelRect = ui.Rect.fromLTWH(14, 0, 80, 40);
    expect(
      _countNonWhitePixels(
        pixels!,
        capture!.pixelSize.width.toInt(),
        labelRect,
      ),
      greaterThan(
        _countNonWhitePixels(
              liveSizePixels!,
              liveSizeCapture!.pixelSize.width.toInt(),
              labelRect,
            ) +
            8,
      ),
    );
  });

  testWidgets('filtered capture omits an approved physical border edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final borderSheet = FortuneSheet(
      id: 'border-capture',
      name: 'Border capture',
      rowCount: 1,
      columnCount: 2,
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-right',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 0,
              columnEnd: 0,
            ),
          ],
        ),
      ],
    );
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FortuneSheetCanvas(
          workbook: FortuneWorkbook(
            settings: settings,
            sheets: [borderSheet],
          ),
          controller: controller,
        ),
      ),
    );
    const borderRange = FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 1,
    );
    final candidate = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: borderSheet,
      range: borderRange,
      transform: transform,
    ).single;
    final plan = fortuneFinalizeHybridRenderPlan(
      settings: settings,
      sheet: borderSheet,
      range: borderRange,
      transform: transform,
      candidates: [candidate],
      approvals: [
        FortuneNativeCandidateApproval(
          candidateToken: candidate.token,
          predictedPaintedFootprint: candidate.printerPaintedFootprint,
        ),
      ],
    );

    final capture = await tester.runAsync(
      () => controller.captureHybridPlanAsPng(plan),
    );
    expect(capture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    expect(_isWhite(pixels!, capture!.pixelSize.width.toInt(), 20, 10), isTrue);
  });
}