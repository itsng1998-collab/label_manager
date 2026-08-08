import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:image/image.dart' as img;
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('80x60mm label units resolve to 640x480 dots at 203.2dpi', () {
    const physicalSize = fs.FortuneSheetGridClientPhysicalSize(
      widthMm: 80,
      heightMm: 60,
    );
    final geometry = resolveLabelSheetHybridPrintGeometry(
      sheet: fs.FortuneSheet(id: 'sheet', name: 'Sheet', zoomRatio: 1),
      settings: const fs.FortuneSettings(),
      physicalSize: physicalSize,
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 80,
        labelHeightMm: 60,
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
    );

    expect(
      physicalSize.logicalSize.width,
      closeTo(80 * fs.fortuneSheetLogicalPixelsPerInch / 25.4, 1e-9),
    );
    expect(
      physicalSize.logicalSize.height,
      closeTo(60 * fs.fortuneSheetLogicalPixelsPerInch / 25.4, 1e-9),
    );
    final printerBounds = geometry.transform.logicalRectToPrinterDots(
      Offset.zero & physicalSize.logicalSize,
    );
    expect(printerBounds.left, closeTo(0, 1e-9));
    expect(printerBounds.top, closeTo(0, 1e-9));
    expect(printerBounds.right, closeTo(640, 1e-9));
    expect(printerBounds.bottom, closeTo(480, 1e-9));
    expect(geometry.metrics.dotsFromMm(80), 640);
    expect(geometry.metrics.dotsFromMm(60), 480);
  });

  test('Windows hybrid approves plain and inline cell text', () {
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

    expect(preparation.descriptors, hasLength(2));
    final descriptor = preparation.descriptors.firstWhere(
      (value) => value.candidateToken == 'text:0:0',
    );
    expect(descriptor.text, '원재료');
    expect(descriptor.fontFamily, 'Arial');
    expect(descriptor.fontPixelHeight, greaterThan(0));
    expect(descriptor.bold, isTrue);
    expect(descriptor.colorArgb, 0xff123456);
    expect(descriptor.horizontalAlign, '1');
    expect(descriptor.verticalAlign, '1');
    expect(descriptor.wrap, isFalse);
    expect(
      preparation.plan.approvedCellTextCoords,
      {
        const fs.FortuneCellCoord(0, 0),
        const fs.FortuneCellCoord(0, 1),
      },
    );
    expect(
      preparation.descriptors.firstWhere(
        (value) => value.candidateToken == 'text:0:1',
      ).text,
      '서식',
    );
    expect(descriptor.toChannelMap()['text'], '원재료');
    expect(descriptor.toChannelMap()['colorArgb'], 0xff123456);
  });

  test('Windows hybrid applies forced line spacing to native text layout', () {
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

    expect(preparation.descriptors, hasLength(1));
    expect(
      preparation.plan.approvedCellTextCoords,
      {const fs.FortuneCellCoord(0, 0)},
    );
  });

  test('Windows hybrid moves solid black cell borders to native descriptors', () {
    final preparation = prepareLabelSheetWindowsHybridPrint(
      sheet: fs.FortuneSheet(
        id: 'sheet',
        name: 'Sheet',
        rowCount: 10,
        columnCount: 10,
        borderInfo: const [
          fs.FortuneBorderInfo(
            rangeType: 'range',
            borderType: 'border-all',
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
      lineSpacingPercent: null,
    );

    expect(preparation.borderDescriptors, isNotEmpty);
    expect(
      preparation.plan.approvedCellBorderEdgeKeys,
      hasLength(preparation.borderDescriptors.length),
    );
    expect(
      preparation.borderDescriptors.every(
        (descriptor) => descriptor.horizontal
            ? descriptor.bottom - descriptor.top == 1
            : descriptor.right - descriptor.left == 1,
      ),
      isTrue,
    );
    expect(
      preparation.borderDescriptors.map(
        (descriptor) => descriptor.toChannelMap()['horizontal'],
      ),
      containsAll(<bool>[true, false]),
    );
    expect(
      preparation.borderDescriptors.map(
        (descriptor) => descriptor.thicknessDots,
      ),
      everyElement(2),
    );
    expect(
      preparation.borderDescriptors.map(
        (descriptor) => descriptor.toChannelMap()['thicknessDots'],
      ),
      everyElement(2),
    );
    for (final horizontal in <bool>[true, false]) {
      final descriptors = preparation.borderDescriptors.where(
        (descriptor) => descriptor.horizontal == horizontal,
      );
      final boundaries = <int, Set<int>>{};
      for (final descriptor in descriptors) {
        boundaries
            .putIfAbsent(descriptor.boundaryIndex, () => <int>{})
            .add(horizontal ? descriptor.top : descriptor.left);
      }
      expect(boundaries.values, everyElement(hasLength(1)));
    }
  });

  test('Windows hybrid output geometry ignores preview zoom', () {
    const settings = fs.FortuneSettings();
    const physicalSize = fs.FortuneSheetGridClientPhysicalSize(
      widthMm: 80,
      heightMm: 60,
    );
    const metrics = LabelSheetPrintPageMetrics(
      labelWidthMm: 80,
      labelHeightMm: 60,
      dpi: 203.2,
    );
    const options = LabelSheetPrintOptions(
      copies: 1,
      leftMarginMm: 0,
      topMarginMm: 0,
      extraAreaMm: 0,
      autoSpacingPercent: null,
      orientation: LabelSheetPrintOrientation.horizontal,
    );
    fs.FortuneSheet sheet(double zoomRatio) => fs.FortuneSheet(
      id: 'sheet',
      name: 'Sheet',
      zoomRatio: zoomRatio,
      rowHeights: const {0: 200, 1: 200},
      columnWidths: const {0: 280, 1: 280},
      cells: {
        const fs.FortuneCellCoord(1, 1): const fs.FortuneCell(
          value: '오른쪽 아래',
        ),
      },
    );

    final normal = prepareLabelSheetWindowsHybridPrint(
      sheet: sheet(1),
      settings: settings,
      physicalSize: physicalSize,
      metrics: metrics,
      options: options,
      lineSpacingPercent: null,
    );
    final zoomed = prepareLabelSheetWindowsHybridPrint(
      sheet: sheet(1.5),
      settings: settings,
      physicalSize: physicalSize,
      metrics: metrics,
      options: options,
      lineSpacingPercent: null,
    );

    expect(zoomed.plan.sheet.zoomRatio, 1);
    expect(zoomed.geometry.range.rowStart, normal.geometry.range.rowStart);
    expect(zoomed.geometry.range.rowEnd, normal.geometry.range.rowEnd);
    expect(
      zoomed.geometry.range.columnStart,
      normal.geometry.range.columnStart,
    );
    expect(zoomed.geometry.range.columnEnd, normal.geometry.range.columnEnd);
    expect(
      zoomed.geometry.transform.sourceLogicalBounds,
      normal.geometry.transform.sourceLogicalBounds,
    );
    expect(
      zoomed.descriptors.map((descriptor) => descriptor.toChannelMap()),
      normal.descriptors.map((descriptor) => descriptor.toChannelMap()),
    );
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

  test('vertical physical layout rotates content and swaps page size', () {
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

    expect(layout.pageWidthMm, 40);
    expect(layout.pageHeightMm, 62);
    expect(layout.contentWidthMm, 30);
    expect(layout.contentHeightMm, 50);
    expect(layout.clipRightMm, 40);
    expect(layout.clipBottomMm, 60);
  });

  test('Windows driver page thresholds final printer grid to monochrome', () {
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
    expect(page.inkPixels, 1);
    expect(page.antialiasPixels, 0);
    expect(page.bgraBytes.sublist(0, 4), [0, 0, 0, 255]);
    expect(page.bgraBytes.sublist(4, 8), [255, 255, 255, 255]);
    expect(page.luminanceHistogram.reduce((left, right) => left + right), 2);
    expect(page.coverageInkEquivalent, closeTo(0.8706, 0.001));
    expect(page.rasterMapping, 'averageResize');
    expect(page.nonWhitePixels, 1);
    expect(page.isolatedInkPixels, 1);
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

  test(
    'Godex EZPL keeps Korean text in raster fallback until Asian font is available',
    () async {
    const options = LabelSheetPrintOptions(
      copies: 1,
      leftMarginMm: 0,
      topMarginMm: 0,
      extraAreaMm: 0,
      autoSpacingPercent: null,
      orientation: LabelSheetPrintOrientation.horizontal,
    );
    final preparation = prepareLabelSheetEzplPrint(
      sheet: fs.FortuneSheet(
        id: 'ezpl-text',
        name: 'EZPL Text',
        rowCount: 2,
        columnCount: 2,
        defaultRowHeight: 32,
        defaultColWidth: 100,
        cells: <fs.FortuneCellCoord, fs.FortuneCell>{
          fs.FortuneCellCoord(0, 0): fs.FortuneCell(
            value: '원재료명 한글 출력',
            fontSize: 10,
            bold: true,
          ),
        },
      ),
      settings: const fs.FortuneSettings(defaultFontSize: 10),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 30,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 30,
        labelHeightMm: 10,
        dpi: 203.2,
      ),
      options: options,
    );

    expect(
      preparation.descriptors.where(
        (descriptor) =>
            descriptor.kind == fs.FortuneNativeCandidateKind.cellText,
      ),
      isEmpty,
    );
    expect(preparation.plan.approvedCandidateTokens, isEmpty);
    expect(
      preparation.textRejectionCounts,
      containsPair('koreanAsianFontUnavailable', 1),
    );

    final blank = img.Image(width: 240, height: 80);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    final bytes = await buildLabelSheetPlannedEzplBytes(
      filteredPngBytes: Uint8List.fromList(img.encodePng(blank)),
      metrics: preparation.geometry.metrics,
      options: options,
      plan: preparation.plan,
      descriptors: preparation.descriptors,
    );
    final payload = utf8.decode(bytes, allowMalformed: true);

    expect(payload, startsWith('^Q10,0,0\r\n^W 30\r\n^P1\r\n^L\r\nQ0,0,30,80\r\n'));
    expect(payload, isNot(contains('AT,')));
    expect(payload, isNot(contains('원재료명 한글 출력')));
    expect(payload, endsWith('E\r\n'));
    },
  );

  test('Godex EZPL uses provisioned AZ1 Korean font with CP949 data', () async {
    const charsetChannel = MethodChannel('charset_converter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(charsetChannel, (call) async {
          expect(call.method, 'encode');
          final arguments = call.arguments as Map<Object?, Object?>;
          expect(arguments['charset'], '949');
          return _encodeTestCp949(arguments['data']! as String);
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(charsetChannel, null),
    );
    const options = LabelSheetPrintOptions(
      copies: 1,
      leftMarginMm: 0,
      topMarginMm: 0,
      extraAreaMm: 0,
      autoSpacingPercent: null,
      orientation: LabelSheetPrintOrientation.horizontal,
    );
    final preparation = prepareLabelSheetEzplPrint(
      sheet: fs.FortuneSheet(
        id: 'ezpl-korean',
        name: 'EZPL Korean',
        rowCount: 2,
        columnCount: 2,
        defaultRowHeight: 32,
        defaultColWidth: 100,
        cells: <fs.FortuneCellCoord, fs.FortuneCell>{
          fs.FortuneCellCoord(0, 0): fs.FortuneCell(
            value: '원재료명 PET',
            fontSize: 10,
          ),
        },
      ),
      settings: const fs.FortuneSettings(defaultFontSize: 10),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 30,
        heightMm: 10,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 30,
        labelHeightMm: 10,
        dpi: 203.2,
      ),
      options: options,
      koreanAsianFontAvailable: true,
    );

    final descriptor = preparation.descriptors.singleWhere(
      (descriptor) =>
          descriptor.kind == fs.FortuneNativeCandidateKind.cellText,
    );
    expect(descriptor.koreanAsian, isTrue);
    expect(descriptor.utf8, isFalse);
    expect(descriptor.command, contains('AZ1,'));
    expect(descriptor.command, contains('원재료명 PET'));
    expect(preparation.textRejectionCounts, isEmpty);

    final blank = img.Image(width: 240, height: 80);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    final bytes = await buildLabelSheetPlannedEzplBytes(
      filteredPngBytes: Uint8List.fromList(img.encodePng(blank)),
      metrics: preparation.geometry.metrics,
      options: options,
      plan: preparation.plan,
      descriptors: preparation.descriptors,
    );
    final cp949Text = _encodeTestCp949('원재료명 PET');
    final patternHeader = ascii.encode('Q0,0,30,80\r\n');
    final patternHeaderStart = _indexOfBytes(bytes, patternHeader);
    final patternDataEnd = patternHeaderStart + patternHeader.length + 30 * 80;

    expect(patternHeaderStart, greaterThanOrEqualTo(0));
    expect(bytes.sublist(patternDataEnd, patternDataEnd + 2), <int>[0x0d, 0x0a]);
    expect(
      bytes.sublist(patternDataEnd + 2, patternDataEnd + 6),
      ascii.encode('AZ1,'),
    );
    expect(_containsBytes(bytes, ascii.encode('AZ1,')), isTrue);
    expect(_containsBytes(bytes, cp949Text), isTrue);
    expect(_containsBytes(bytes, utf8.encode('원재료명 PET')), isFalse);
  });

  test('Godex EZPL hybrid uses contiguous Q pattern data', () async {
    final blank = img.Image(width: 640, height: 8);
    img.fill(blank, color: img.ColorRgb8(255, 255, 255));
    blank.setPixelRgb(0, 0, 0, 0, 0);
    const metrics = LabelSheetPrintPageMetrics(
      labelWidthMm: 80,
      labelHeightMm: 1,
      dpi: 203.2,
    );
    const options = LabelSheetPrintOptions(
      copies: 1,
      leftMarginMm: 0,
      topMarginMm: 0,
      extraAreaMm: 0,
      autoSpacingPercent: null,
      orientation: LabelSheetPrintOrientation.horizontal,
    );
    final preparation = prepareLabelSheetEzplPrint(
      sheet: fs.FortuneSheet(id: 'raster-polarity', name: 'Raster'),
      settings: const fs.FortuneSettings(),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 80,
        heightMm: 1,
      ),
      metrics: metrics,
      options: options,
    );
    String? diagnostics;
    final bytes = await buildLabelSheetPlannedEzplBytes(
      filteredPngBytes: Uint8List.fromList(img.encodePng(blank)),
      metrics: metrics,
      options: options,
      plan: preparation.plan,
      descriptors: preparation.descriptors,
      onDiagnostics: (value) => diagnostics = value,
    );
    final payloadPrefix = ascii.encode(
      '^Q1,0,0\r\n^W 80\r\n^P1\r\n^L\r\nQ0,0,80,8\r\n',
    );
    final patternDataStart = payloadPrefix.length;
    const bytesPerRow = 80;

    expect(bytes.sublist(0, patternDataStart), payloadPrefix);
    final firstRow = bytes.sublist(
      patternDataStart,
      patternDataStart + bytesPerRow,
    );
    expect(firstRow.first, 0x7f);
    expect(firstRow.skip(1), everyElement(0xff));
    final secondRowStart = patternDataStart + bytesPerRow;
    expect(
      bytes.sublist(secondRowStart, secondRowStart + bytesPerRow),
      everyElement(0xff),
    );
    final patternDataEnd = patternDataStart + bytesPerRow * 8;
    expect(bytes.sublist(patternDataEnd, patternDataEnd + 2), <int>[0x0d, 0x0a]);
    expect(bytes.sublist(bytes.length - 3), ascii.encode('E\r\n'));
    expect(diagnostics, contains('polarity=zeroBlackOneWhite'));
    expect(diagnostics, contains('framing=QPatternContiguous'));
    expect(
      diagnostics,
      contains('commandOrder=setup>^L>QPattern+native>E formatCount=1'),
    );
    expect(diagnostics, contains('rowBytes=80 rows=8'));
    expect(diagnostics, contains('inkDots=1/5120'));
    expect(diagnostics, contains('whiteDots=5119'));
    expect(diagnostics, contains('rowsWithInk=1'));
    expect(diagnostics, contains('patternDataBytes=640'));
    expect(diagnostics, contains('patternBytes=zero:0,full:639,mixed:1'));
    expect(diagnostics, contains(RegExp(r'patternFnv64=[0-9a-f]{16}')));
    expect(diagnostics, contains('native=AT:0,AZ1:0,geometry:0'));
    expect(diagnostics, contains('payloadBytes=${bytes.length}'));
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

bool _containsBytes(List<int> source, List<int> pattern) {
  return _indexOfBytes(source, pattern) >= 0;
}

int _indexOfBytes(List<int> source, List<int> pattern) {
  if (pattern.isEmpty || pattern.length > source.length) return -1;
  for (var start = 0; start <= source.length - pattern.length; start += 1) {
    var matches = true;
    for (var offset = 0; offset < pattern.length; offset += 1) {
      if (source[start + offset] != pattern[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return start;
  }
  return -1;
}

Uint8List _encodeTestCp949(String input) {
  const koreanText = '원재료명 PET';
  const koreanBytes = <int>[
    0xbf,
    0xf8,
    0xc0,
    0xe7,
    0xb7,
    0xe1,
    0xb8,
    0xed,
    0x20,
    0x50,
    0x45,
    0x54,
  ];
  final offset = input.indexOf(koreanText);
  if (offset < 0) return Uint8List.fromList(ascii.encode(input));
  return Uint8List.fromList(<int>[
    ...ascii.encode(input.substring(0, offset)),
    ...koreanBytes,
    ...ascii.encode(input.substring(offset + koreanText.length)),
  ]);
}
