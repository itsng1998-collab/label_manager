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
  testWidgets('print capture excludes grid borders and label area boundary', (
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
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 20,
            fortuneSheetGridClientHeightMmKey: 20,
            fortuneSheetRulerVisibleKey: true,
            fortuneSheetRulerGuidesKey: [
              {'id': 1, 'axis': 'vertical', 'positionMm': 10.0},
              {'id': 2, 'axis': 'horizontal', 'positionMm': 10.0},
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
        includeLabelAreaBoundary: false,
      ),
    );

    expect(capture, isNotNull);
    expect(capture!.pixelSize.width, greaterThan(20));
    expect(capture.pixelSize.height, greaterThan(20));

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
}
