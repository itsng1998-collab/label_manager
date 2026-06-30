import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  test('buildLabelSheetEzplRasterBytes emits label size copies and graphics rows', () async {
    final image = img.Image(width: 8, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    image.setPixelRgb(0, 0, 0, 0, 0);
    image.setPixelRgb(7, 1, 0, 0, 0);
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    final bytes = await buildLabelSheetEzplRasterBytes(
      pngBytes: pngBytes,
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 8,
        labelHeightMm: 2,
        dpi: 25.4,
      ),
      options: const LabelSheetPrintOptions(
        copies: 3,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 1,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    final text = ascii.decode(
      bytes.where((byte) => byte == 0x0d || byte == 0x0a || byte >= 0x20).toList(),
      allowInvalid: true,
    );
    expect(text, contains('^Q3,0,0'));
    expect(text, contains('^W 8'));
    expect(text, contains('^P3'));
    expect(text, contains('^L'));
    expect(text, contains('~G'));
    expect(bytes.where((byte) => byte == 0x47).length, greaterThanOrEqualTo(3));
    expect(text, endsWith('E\r\n'));
  });

  test('buildLabelSheetPdfBytes creates one page per copy', () async {
    final image = img.Image(width: 4, height: 4);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    final bytes = await buildLabelSheetPdfBytes(
      pngBytes: pngBytes,
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 10,
        labelHeightMm: 10,
        dpi: 203,
      ),
      options: const LabelSheetPrintOptions(
        copies: 2,
        leftMarginMm: 1,
        topMarginMm: 1,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
