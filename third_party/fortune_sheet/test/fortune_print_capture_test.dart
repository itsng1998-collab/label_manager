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

bool _isBlack(ByteData pixels, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return pixels.getUint8(offset) < 32 &&
      pixels.getUint8(offset + 1) < 32 &&
      pixels.getUint8(offset + 2) < 32;
}

bool _hasDarkPixelNear(ByteData pixels, int width, int height, int x, int y) {
  for (var dy = -2; dy <= 2; dy += 1) {
    final py = y + dy;
    if (py < 0 || py >= height) {
      continue;
    }
    for (var dx = -2; dx <= 2; dx += 1) {
      final px = x + dx;
      if (px < 0 || px >= width) {
        continue;
      }
      if (_isBlack(pixels, width, px, py)) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  test('output line height preserves stored value unless overridden', () {
    expect(fortuneOutputLineHeight(1.5, null), 1.5);
    expect(fortuneOutputLineHeight(1.5, 1), 1);
    expect(fortuneOutputLineHeight(1.5, 2), 2);
    expect(fortuneOutputLineHeight(null, null), isNull);
  });

  testWidgets('print capture excludes grid lines ruler guides and boundary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    final guidePositionMm = fortuneLogicalPixelsToMillimeters(20);
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        defaultRowHeight: 20,
        defaultColWidth: 20,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowCount: 2,
          columnCount: 2,
          showGridLines: true,
          borderInfo: const [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: ui.Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 1,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
          extraFields: {
            fortuneSheetGridClientWidthMmKey: 20,
            fortuneSheetGridClientHeightMmKey: 20,
            fortuneSheetRulerVisibleKey: true,
            fortuneSheetRulerGuidesKey: [
              {'id': 1, 'axis': 'vertical', 'positionMm': guidePositionMm},
              {'id': 2, 'axis': 'horizontal', 'positionMm': guidePositionMm},
            ],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 180,
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    final capture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 0,
          rowEnd: 1,
          columnStart: 0,
          columnEnd: 1,
        ),
        pixelRatio: 1,
        includeGridLines: false,
        includeCellBorders: false,
        includeRulerGuides: false,
        includeLabelAreaBoundary: false,
      ),
    );

    expect(capture, isNotNull);
    expect(capture!.pixelSize.width, greaterThan(20));
    expect(capture.pixelSize.height, greaterThan(20));
    final reversedCapture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 1,
          rowEnd: 0,
          columnStart: 1,
          columnEnd: 0,
        ),
      ),
    );
    expect(reversedCapture?.logicalSize, capture.logicalSize);
    final outsideCapture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 5,
          rowEnd: 6,
          columnStart: 5,
          columnEnd: 6,
        ),
      ),
    );
    expect(outsideCapture, isNull);

    final pixels = await tester.runAsync(() => _decodeRawRgba(capture.pngBytes));
    expect(pixels, isNotNull);

    final width = capture.pixelSize.width.toInt();
    final height = capture.pixelSize.height.toInt();
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;

    expect(_isWhite(pixels!, width, centerX, height ~/ 4), isTrue);
    expect(_isWhite(pixels, width, width ~/ 4, centerY), isTrue);
    expect(_isWhite(pixels, width, 0, centerY), isTrue);
    expect(_isWhite(pixels, width, centerX, 0), isTrue);
  });

  testWidgets('print capture includes cell borders when requested', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        defaultRowHeight: 20,
        defaultColWidth: 20,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowCount: 2,
          columnCount: 2,
          showGridLines: true,
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: ui.Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 1,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 180,
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    final capture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 0,
          rowEnd: 1,
          columnStart: 0,
          columnEnd: 1,
        ),
        pixelRatio: 1,
        includeGridLines: false,
        includeCellBorders: true,
        includeRulerGuides: false,
        includeLabelAreaBoundary: false,
      ),
    );

    expect(capture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    final width = capture!.pixelSize.width.toInt();
    final height = capture.pixelSize.height.toInt();

    expect(
      _hasDarkPixelNear(pixels!, width, height, width ~/ 2, height ~/ 4),
      isTrue,
    );
    expect(
      _hasDarkPixelNear(pixels, width, height, width ~/ 4, height ~/ 2),
      isTrue,
    );
  });

  testWidgets('print capture preserves merged cell outer borders', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        defaultRowHeight: 20,
        defaultColWidth: 20,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowCount: 2,
          columnCount: 2,
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              merge: FortuneCellMerge(
                row: 0,
                column: 0,
                rowSpan: 2,
                columnSpan: 2,
              ),
            ),
          },
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: ui.Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 1,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 180,
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    final capture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 0,
          rowEnd: 1,
          columnStart: 0,
          columnEnd: 1,
        ),
        pixelRatio: 1,
        includeGridLines: false,
        includeCellBorders: true,
        includeRulerGuides: false,
        includeLabelAreaBoundary: false,
      ),
    );

    expect(capture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    final width = capture!.pixelSize.width.toInt();
    final height = capture.pixelSize.height.toInt();

    expect(_hasDarkPixelNear(pixels!, width, height, width - 1, height ~/ 2), isTrue);
    expect(_hasDarkPixelNear(pixels, width, height, width ~/ 2, height - 1), isTrue);
  });

  testWidgets('print capture includes typed lines and shapes', (tester) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        defaultRowHeight: 20,
        defaultColWidth: 20,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowCount: 2,
          columnCount: 2,
          lines: [
            FortuneLine(
              id: 'line_1',
              x1: 2,
              y1: 10,
              x2: 18,
              y2: 10,
              strokeWidthMm: 1,
            ),
          ],
          shapes: [
            FortuneShape(
              id: 'shape_1',
              kind: FortuneShapeKind.rectangle,
              left: 24,
              top: 24,
              width: 10,
              height: 10,
              fillColor: '#000000',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 240,
          height: 180,
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
          ),
        ),
      ),
    );
    final capture = await tester.runAsync(
      () => controller.captureRangeAsPng(
        const FortuneRange(
          rowStart: 0,
          rowEnd: 1,
          columnStart: 0,
          columnEnd: 1,
        ),
        includeGridLines: false,
        includeCellBorders: false,
        includeLabelAreaBoundary: false,
      ),
    );
    expect(capture, isNotNull);
    final pixels = await tester.runAsync(() => _decodeRawRgba(capture!.pngBytes));
    expect(_hasDarkPixelNear(pixels!, capture!.pixelSize.width.toInt(), capture.pixelSize.height.toInt(), 10, 10), isTrue);
    expect(_isBlack(pixels, capture.pixelSize.width.toInt(), 29, 29), isTrue);
  });
}
