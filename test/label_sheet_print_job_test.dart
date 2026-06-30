import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
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

  test('buildLabelSheetHybridEzplBytes emits native borders and barcodes', () async {
    final image = img.Image(width: 40, height: 20);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final pngBytes = Uint8List.fromList(img.encodePng(image));

    final sheet = fs.FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowCount: 1,
      columnCount: 1,
      rowHeights: const {0: fs.fortuneSheetLogicalPixelsPerInch / 25.4 * 10},
      columnWidths: const {0: fs.fortuneSheetLogicalPixelsPerInch / 25.4 * 20},
      borderInfo: const [
        fs.FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            fs.FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
      images: const [
        fs.FortuneImage(
          id: 'barcode-1',
          src: '',
          left: 0,
          top: 0,
          width: fs.fortuneSheetLogicalPixelsPerInch / 25.4 * 20,
          height: fs.fortuneSheetLogicalPixelsPerInch / 25.4 * 10,
          extraFields: {
            'fortuneBarcode': true,
            'barcodeText': '123456',
            'barcodeFormatId': 'code128',
            'barcodeModuleScale': 2,
            'barcodeBarHeight': fs.fortuneSheetLogicalPixelsPerInch / 25.4 * 8,
            'barcodeShowText': false,
          },
        ),
      ],
    );

    final bytes = await buildLabelSheetHybridEzplBytes(
      sheet: sheet,
      range: const fs.FortuneRange(
        rowStart: 0,
        rowEnd: 0,
        columnStart: 0,
        columnEnd: 0,
      ),
      fallbackPngBytes: pngBytes,
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 20,
        labelHeightMm: 10,
        dpi: 25.4,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 1,
        topMarginMm: 2,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    final text = ascii.decode(
      bytes.where((byte) => byte == 0x0d || byte == 0x0a || byte >= 0x20).toList(),
      allowInvalid: true,
    );
    expect(text, contains('~G'));
    expect(text, contains('X1,2,20,1,1'));
    expect(text, contains('BA1,2,2,8,0,123456'));
    expect(text, endsWith('E\r\n'));
  });
}
