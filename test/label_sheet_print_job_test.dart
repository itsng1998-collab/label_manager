import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:image/image.dart' as img;
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  test('print options normalize UI input values', () {
    final options = labelSheetPrintOptionsFromInput(
      copies: ' 3 ',
      leftMarginMm: '-1.5',
      topMarginMm: 'invalid',
      extraAreaMm: ' 2.5 ',
      autoSpacing: '120',
      orientation: 'vertical',
    );

    expect(options.copies, 3);
    expect(options.leftMarginMm, 0);
    expect(options.topMarginMm, 0);
    expect(options.extraAreaMm, 2.5);
    expect(options.autoSpacingPercent, 120);
    expect(options.orientation, LabelSheetPrintOrientation.vertical);

    final fallback = labelSheetPrintOptionsFromInput(
      copies: '0',
      leftMarginMm: '',
      topMarginMm: '',
      extraAreaMm: '',
      autoSpacing: 'none',
      orientation: 'unknown',
    );

    expect(fallback.copies, 1);
    expect(fallback.autoSpacingPercent, isNull);
    expect(fallback.orientation, LabelSheetPrintOrientation.horizontal);
  });

  test('print range uses physical size with custom and default axes', () {
    final range = labelSheetPrintRange(
      fs.FortuneSheet(
        id: 'sheet',
        name: 'Sheet',
        rowHeights: const <int, double>{0: 20},
        columnWidths: const <int, double>{0: 30},
        defaultRowHeight: 10,
        defaultColWidth: 5,
      ),
      const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 10,
        heightMm: 10,
      ),
    );

    expect(range.rowStart, 0);
    expect(range.rowEnd, 2);
    expect(range.columnStart, 0);
    expect(range.columnEnd, 2);
  });

  test('hybrid geometry resolves source metrics and print transform', () {
    final geometry = resolveLabelSheetHybridPrintGeometry(
      sheet: fs.FortuneSheet(
        id: 'sheet',
        name: 'Sheet',
        rowHeights: const <int, double>{0: 20},
        columnWidths: const <int, double>{0: 30},
        defaultRowHeight: 10,
        defaultColWidth: 5,
      ),
      settings: const fs.FortuneSettings(),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 10,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 10,
        labelHeightMm: 10,
        dpi: 203,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 2,
        topMarginMm: 3,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    expect(geometry.range.rowEnd, 2);
    expect(geometry.range.columnEnd, 2);
    expect(
      geometry.transform.sourceLogicalBounds,
      Rect.fromLTWH(
        0,
        0,
        fs.fortuneMillimetersToLogicalPixels(10),
        fs.fortuneMillimetersToLogicalPixels(10),
      ),
    );
    expect(geometry.metrics.sourceWidthMm, 10);
    expect(geometry.metrics.sourceHeightMm, 10);
    expect(geometry.transform.contentLeftMm, 2);
    expect(geometry.transform.contentTopMm, 3);
    expect(geometry.transform.clipRightMm, 10);
    expect(geometry.transform.clipBottomMm, 10);
    expect(geometry.transform.nativeAllowed, isTrue);
  });

  test('Windows hybrid approves only plain cell text', () {
    final sheet = fs.FortuneSheet(
      id: 'sheet',
      name: 'Sheet',
      cells: {
        const fs.FortuneCellCoord(0, 0): const fs.FortuneCell(
          value: '원재료',
          fontFamily: 'Arial',
          fontSize: 10,
          bold: true,
          foreground: Color(0xff123456),
          horizontalAlign: '2',
          verticalAlign: '2',
          textWrap: '2',
        ),
        const fs.FortuneCellCoord(0, 1): const fs.FortuneCell(
          inlineRuns: [fs.FortuneInlineTextRun(text: '서식')],
        ),
        const fs.FortuneCellCoord(0, 2): const fs.FortuneCell(
          value: '회전',
          textRotation: '45',
        ),
        const fs.FortuneCellCoord(0, 3): const fs.FortuneCell(
          value: '세로',
          textRotationMode: '3',
        ),
        const fs.FortuneCellCoord(0, 4): const fs.FortuneCell(
          value: '넘침',
          textWrap: '1',
        ),
        const fs.FortuneCellCoord(0, 5): const fs.FortuneCell(
          value: '균등',
          horizontalAlign: '3',
        ),
        const fs.FortuneCellCoord(0, 6): const fs.FortuneCell(
          value: '위치',
          extraFields: {fs.fortuneCellTextOffsetYExtraKey: 2},
        ),
      },
      defaultRowHeight: 24,
      defaultColWidth: 40,
    );

    final preparation = prepareLabelSheetWindowsHybridPrint(
      sheet: sheet,
      settings: const fs.FortuneSettings(),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 80,
        heightMm: 20,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 80,
        labelHeightMm: 20,
        dpi: 203.2,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
      lineSpacingPercent: null,
    );

    expect(preparation.descriptors, hasLength(1));
    final descriptor = preparation.descriptors.single;
    expect(descriptor.text, '원재료');
    expect(descriptor.fontFamily, 'Arial');
    expect(descriptor.fontPixelHeight, greaterThan(0));
    expect(descriptor.bold, isTrue);
    expect(descriptor.colorArgb, 0xff123456);
    expect(descriptor.horizontalAlign, '2');
    expect(descriptor.verticalAlign, '2');
    expect(descriptor.wrap, isTrue);
    expect(
      preparation.plan.approvedCellTextCoords,
      {const fs.FortuneCellCoord(0, 0)},
    );
    expect(descriptor.toChannelMap()['text'], '원재료');
    expect(descriptor.toChannelMap()['colorArgb'], 0xff123456);
  });

  test('Windows hybrid keeps all text in raster when line spacing is forced', () {
    final preparation = prepareLabelSheetWindowsHybridPrint(
      sheet: fs.FortuneSheet(
        id: 'sheet',
        name: 'Sheet',
        cells: {
          const fs.FortuneCellCoord(0, 0): const fs.FortuneCell(value: '원재료'),
        },
      ),
      settings: const fs.FortuneSettings(),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 20,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 20,
        labelHeightMm: 10,
        dpi: 203.2,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
      lineSpacingPercent: 120,
    );

    expect(preparation.descriptors, isEmpty);
    expect(preparation.plan.approvedCellTextCoords, isEmpty);
  });

  test('Windows hybrid keeps text in raster for vertical page output', () {
    final preparation = prepareLabelSheetWindowsHybridPrint(
      sheet: fs.FortuneSheet(
        id: 'sheet',
        name: 'Sheet',
        cells: {
          const fs.FortuneCellCoord(0, 0): const fs.FortuneCell(value: '원재료'),
        },
      ),
      settings: const fs.FortuneSettings(),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 20,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 20,
        labelHeightMm: 10,
        dpi: 203.2,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.vertical,
      ),
      lineSpacingPercent: null,
    );

    expect(preparation.descriptors, isEmpty);
    expect(preparation.plan.approvedCellTextCoords, isEmpty);
  });

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

  test('EZPL raster preserves supersampled text edge luminance', () async {
    final image = img.Image(width: 8, height: 1);
    for (var x = 0; x < image.width; x += 1) {
      final luminance = x.isEven ? 200 : 201;
      image.setPixelRgb(x, 0, luminance, luminance, luminance);
    }

    final bytes = await buildLabelSheetEzplRasterBytes(
      pngBytes: Uint8List.fromList(img.encodePng(image)),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 8,
        labelHeightMm: 1,
        dpi: 25.4,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    final graphicMarker = bytes.indexOf(0x7e);
    expect(graphicMarker, isNonNegative);
    expect(bytes.sublist(graphicMarker, graphicMarker + 4), ascii.encode('~G\r\n'));
    expect(bytes[graphicMarker + 4], 0x47);
    expect(bytes[graphicMarker + 5], 1);
    expect(bytes[graphicMarker + 6], 0xaa);
  });

  test('Windows driver page preserves final printer grid grayscale', () {
    final image = img.Image(width: 4, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    image
      ..setPixelRgb(0, 0, 0, 0, 0)
      ..setPixelRgb(1, 0, 0, 0, 0)
      ..setPixelRgb(0, 1, 0, 0, 0);
    for (var y = 0; y < 2; y += 1) {
      for (var x = 2; x < 4; x += 1) {
        image.setPixelRgb(x, y, 225, 225, 225);
      }
    }

    final page = prepareLabelSheetWindowsDriverPage(
      pngBytes: Uint8List.fromList(img.encodePng(image)),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 2,
        labelHeightMm: 1,
        sourceWidthMm: 2,
        sourceHeightMm: 1,
        dpi: 25.4,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    expect((page.width, page.height), (2, 1));
    expect(page.bgraBytes, hasLength(2 * 1 * 4));
    expect(page.inkPixels, 0);
    expect(page.antialiasPixels, 2);
    expect(page.bgraBytes.sublist(0, 4), [63, 63, 63, 255]);
    expect(page.bgraBytes.sublist(4, 8), [225, 225, 225, 255]);
    expect(page.luminanceHistogram.reduce((left, right) => left + right), 2);
    expect(page.coverageInkEquivalent, closeTo(0.8706, 0.001));
    expect(page.rasterMapping, 'averageResize');
    expect(page.nonWhitePixels, 2);
    expect(page.isolatedInkPixels, 0);
  });

  test('Windows driver page crops one-pixel capture overflow', () {
    final image = img.Image(width: 3, height: 2);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < 2; y += 1) {
      image.setPixelRgb(0, y, 0, 0, 0);
      image.setPixelRgb(2, y, 0, 0, 0);
    }

    final page = prepareLabelSheetWindowsDriverPage(
      pngBytes: Uint8List.fromList(img.encodePng(image)),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 2,
        labelHeightMm: 1,
        sourceWidthMm: 2,
        sourceHeightMm: 1,
        dpi: 25.4,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
    );

    expect(page.inputWidth, 3);
    expect(page.inputHeight, 2);
    expect(page.rasterMapping, 'cropCeilOverflow');
    expect(page.inkPixels, 1);
    expect(page.bgraBytes, [0, 0, 0, 255, 255, 255, 255, 255]);
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
      borderInfo: const [
        fs.FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-right',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            fs.FortuneRange(
              rowStart: 0,
              rowEnd: 0,
              columnStart: 0,
              columnEnd: 0,
            ),
          ],
        ),
      ],
    );
    const settings = fs.FortuneSettings(
      defaultRowHeight: 20,
      defaultColWidth: 20,
    );
    const options = LabelSheetPrintOptions(
      copies: 1,
      leftMarginMm: 0,
      topMarginMm: 0,
      extraAreaMm: 0,
      autoSpacingPercent: null,
      orientation: LabelSheetPrintOrientation.horizontal,
    );
    final preparation = prepareLabelSheetHybridPrint(
      sheet: sheet,
      settings: settings,
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 10,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 20,
        labelHeightMm: 20,
        dpi: 96,
      ),
      options: options,
    );
    final image = img.Image(width: 40, height: 40);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final bytes = await buildLabelSheetPlannedHybridEzplBytes(
      filteredPngBytes: Uint8List.fromList(img.encodePng(image)),
      metrics: preparation.geometry.metrics,
      options: options,
      plan: preparation.plan,
      descriptors: preparation.descriptors,
    );
    final text = ascii.decode(bytes, allowInvalid: true);
    expect(preparation.plan.approvedCandidateTokens, hasLength(2));
    for (final descriptor in preparation.descriptors) {
      expect(text, contains(descriptor.command));
    }
    expect(text, endsWith('E\r\n'));
  });

  test('barcode preflight approves only an exact deterministic footprint', () {
    fs.FortuneSheet barcodeSheet(double width) => fs.FortuneSheet(
      id: 'barcode',
      name: 'Barcode',
      rowCount: 1,
      columnCount: 1,
      images: [
        fs.FortuneImage(
          id: 'barcode-1',
          src: '',
          left: 2,
          top: 3,
          width: width,
          height: 10,
          extraFields: const {
            'fortuneBarcode': true,
            'barcodeText': 'A',
            'barcodeFormatId': 'code128',
            'barcodeModuleScale': 1,
            'barcodeBarHeight': 10,
            'barcodeShowText': false,
            'barcodeBodyTop': 0,
            'barcodeBodyHeight': 10,
          },
        ),
      ],
    );
    const settings = fs.FortuneSettings(
      defaultRowHeight: 20,
      defaultColWidth: 100,
    );
    const range = fs.FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 0,
    );
    const transform = fs.FortunePrintTransform(
      sourceLogicalBounds: Rect.fromLTWH(0, 0, 100, 20),
      dpi: 96,
      contentLeftMm: 0,
      contentTopMm: 0,
      clipRightMm: 30,
      clipBottomMm: 10,
      nativeAllowed: true,
    );

    fs.FortuneHybridRenderPlan buildPlan(double width) {
      final sheet = barcodeSheet(width);
      final candidates = fs.fortuneBuildNativeCandidates(
        settings: settings,
        sheet: sheet,
        range: range,
        transform: transform,
      );
      final descriptors = preflightLabelSheetEzplCandidates(
        sheet: sheet,
        transform: transform,
        candidates: candidates,
      );
      return fs.fortuneFinalizeHybridRenderPlan(
        settings: settings,
        sheet: sheet,
        range: range,
        transform: transform,
        candidates: candidates,
        approvals: descriptors.map((descriptor) => descriptor.approval),
      );
    }

    expect(buildPlan(46).approvedCandidateTokens, hasLength(1));
    expect(buildPlan(47).approvedCandidateTokens, isEmpty);
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
