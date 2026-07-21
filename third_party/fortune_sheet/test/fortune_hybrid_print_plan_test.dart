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
      sheet: sheet,
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
      sheet: sheet,
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
}