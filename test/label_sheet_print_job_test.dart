import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:image/image.dart' as img;
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  test('physical layout keeps source size and applies margin push and clip', () {
    final layout = LabelSheetPrintLayout.resolve(
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 60,
        labelHeightMm: 40,
        sourceWidthMm: 50,
        sourceHeightMm: 30,
        dpi: 203,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 3,
        rightMarginMm: 5,
        topMarginMm: 2,
        leftPushMm: -1,
        topPushMm: 1,
        extraAreaMm: 4,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    expect(layout.pageWidthMm, 60);
    expect(layout.pageHeightMm, 44);
    expect(layout.contentLeftMm, 2);
    expect(layout.contentTopMm, 3);
    expect(layout.contentWidthMm, 50);
    expect(layout.contentHeightMm, 30);
    expect(layout.clipRightMm, 55);
    expect(layout.clipBottomMm, 40);
    expect(layout.intersectionWidthMm, 50);
    expect(layout.intersectionHeightMm, 30);
    expect(layout.hasContentIntersection, isTrue);
  });

  test('vertical physical layout rotates content without swapping page size', () {
    final layout = LabelSheetPrintLayout.resolve(
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 60,
        labelHeightMm: 40,
        sourceWidthMm: 50,
        sourceHeightMm: 30,
        dpi: 203,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 2,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.vertical,
      ),
    );

    expect(layout.pageWidthMm, 60);
    expect(layout.pageHeightMm, 42);
    expect(layout.contentWidthMm, 30);
    expect(layout.contentHeightMm, 50);
  });

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

  test('planned Hybrid output encodes only package-approved descriptors', () async {
    final sheet = fs.FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowCount: 2,
      columnCount: 2,
      lines: const [
        fs.FortuneLine(
          id: 'line_1',
          x1: 2,
          y1: 10,
          x2: 18,
          y2: 10,
          strokeWidthMm: 1,
        ),
      ],
    );
    const transform = fs.FortunePrintTransform(
      sourceLogicalBounds: Rect.fromLTWH(0, 0, 40, 40),
      dpi: 96,
      contentLeftMm: 0,
      contentTopMm: 0,
      clipRightMm: 20,
      clipBottomMm: 20,
      nativeAllowed: true,
    );
    final candidates = fs.fortuneBuildNativeCandidates(
      sheet: sheet,
      transform: transform,
    );
    final descriptors = preflightLabelSheetEzplCandidates(
      sheet: sheet,
      transform: transform,
      candidates: candidates,
    );
    final plan = fs.fortuneFinalizeHybridRenderPlan(
      settings: const fs.FortuneSettings(
        defaultRowHeight: 20,
        defaultColWidth: 20,
      ),
      sheet: sheet,
      range: const fs.FortuneRange(
        rowStart: 0,
        rowEnd: 1,
        columnStart: 0,
        columnEnd: 1,
      ),
      transform: transform,
      candidates: candidates,
      approvals: descriptors.map((descriptor) => descriptor.approval),
    );
    final image = img.Image(width: 40, height: 40);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final bytes = await buildLabelSheetPlannedHybridEzplBytes(
      filteredPngBytes: Uint8List.fromList(img.encodePng(image)),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 20,
        labelHeightMm: 20,
        sourceWidthMm: 10.5833333333,
        sourceHeightMm: 10.5833333333,
        dpi: 96,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
      plan: plan,
      descriptors: descriptors,
    );
    final text = ascii.decode(bytes, allowInvalid: true);
    expect(plan.approvedCandidateTokens, hasLength(1));
    expect(text, contains(descriptors.single.command));
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
    expect(text, contains('R1,2,21,3,1,1'));
    expect(text, contains('BQ1,2,2,5,8,0,0,123456'));
    expect(text, endsWith('E\r\n'));
  });
}
