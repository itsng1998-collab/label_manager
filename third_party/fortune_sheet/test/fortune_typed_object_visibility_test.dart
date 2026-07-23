import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  test('mixed image barcode and line objects remain visible', () async {
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          showGridLines: false,
          images: const [
            FortuneImage(
              id: 'image_1',
              src: '',
              left: 10,
              top: 10,
              width: 40,
              height: 30,
              extraFields: {fortuneSheetObjectZOrderExtraKey: 1.0},
            ),
            FortuneImage(
              id: 'barcode_1',
              src: '',
              left: 60,
              top: 10,
              width: 40,
              height: 30,
              extraFields: {
                'fortuneBarcode': true,
                fortuneSheetObjectZOrderExtraKey: 2.0,
              },
            ),
          ],
          lines: const [
            FortuneLine(
              id: 'line_1',
              x1: 10,
              y1: 55,
              x2: 100,
              y2: 55,
              strokeColor: '#FF0000',
              zOrder: 3,
            ),
          ],
        ),
      ],
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    FortuneSheetPainter(
      workbook: workbook,
      selection: const FortuneSelection(row: 10, column: 10),
      scrollOffset: Offset.zero,
      sheetTabScrollOffset: 0,
      textDirection: TextDirection.ltr,
    ).paint(canvas, const Size(180, 120));
    final image = await recorder.endRecording().toImage(180, 120);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

    int nonWhitePixels(ui.Rect rect) {
      var count = 0;
      for (var y = rect.top.floor(); y < rect.bottom.ceil(); y += 1) {
        for (var x = rect.left.floor(); x < rect.right.ceil(); x += 1) {
          final offset = ((y * image.width) + x) * 4;
          final red = bytes.getUint8(offset);
          final green = bytes.getUint8(offset + 1);
          final blue = bytes.getUint8(offset + 2);
          if (red < 245 || green < 245 || blue < 245) {
            count += 1;
          }
        }
      }
      return count;
    }

    expect(
      nonWhitePixels(const ui.Rect.fromLTWH(48, 30, 40, 30)),
      greaterThan(100),
    );
    expect(
      nonWhitePixels(const ui.Rect.fromLTWH(98, 30, 40, 30)),
      greaterThan(100),
    );
    expect(
      nonWhitePixels(const ui.Rect.fromLTWH(48, 73, 90, 5)),
      greaterThan(40),
    );
  });
}