import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:image/image.dart' as img;
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _settings = fs.FortuneSettings();
const _physical = fs.FortuneSheetGridClientPhysicalSize(
  widthMm: 80,
  heightMm: 60,
);
const _metrics = LabelSheetPrintPageMetrics(
  labelWidthMm: 80,
  labelHeightMm: 60,
  dpi: 203.2,
);

LabelSheetPrintOptions _options({
  double left = 0,
  double right = 0,
  double top = 0,
  double push = 0,
  double pushTop = 0,
  int? spacing,
  bool rotate = false,
}) => LabelSheetPrintOptions(
  copies: 1,
  leftMarginMm: left,
  rightMarginMm: right,
  topMarginMm: top,
  leftPushMm: push,
  topPushMm: pushTop,
  extraAreaMm: 0,
  autoSpacingPercent: spacing,
  orientation: rotate
      ? LabelSheetPrintOrientation.vertical
      : LabelSheetPrintOrientation.horizontal,
);

fs.FortuneSheet _sheet() {
  final width = fs.fortuneMillimetersToLogicalPixels(80);
  final text = List.filled(
    6,
    'Margin reflows text without shrinking fonts.',
  ).join(' ');
  final cell = fs.FortuneCell(
    value: text,
    fontSize: 10,
    fontFamily: 'Arial',
    textWrap: '2',
    verticalAlign: '0',
    extraFields: const {'lineHeight': 1.0},
  );
  final layout = fs.fortuneLayoutCellText(
    settings: _settings,
    cell: cell,
    logicalBounds: ui.Rect.fromLTWH(0, 0, width, double.maxFinite),
    textSpan: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: fs.fortuneResolveFontFamily(
          'Arial',
          _settings.fontFamilies,
        ),
        fontSize: 10,
        height: 1,
      ),
    ),
  )!;
  return fs.FortuneSheet(
    id: 'margin',
    name: 'Margin',
    rowCount: 8,
    columnCount: 1,
    defaultColWidth: width - 1,
    defaultRowHeight: 20,
    rowHeights: {0: layout.painter.height},
    showGridLines: false,
    extraFields: const {
      fs.fortuneSheetGridClientWidthMmKey: 80,
      fs.fortuneSheetGridClientHeightMmKey: 60,
    },
    cells: {
      const fs.FortuneCellCoord(0, 0): cell,
      const fs.FortuneCellCoord(1, 0): const fs.FortuneCell(
        value: 'After paragraph',
        fontSize: 10,
        textWrap: '2',
      ),
    },
    shapes: const [
      fs.FortuneShape(
        id: 'fixed',
        kind: fs.FortuneShapeKind.rectangle,
        left: 250,
        top: 160,
        width: 40,
        height: 10,
        fillColor: '#ff0000',
      ),
    ],
  );
}

LabelSheetWindowsHybridPreparation _prepare(
  fs.FortuneSheet sheet,
  LabelSheetPrintOptions options,
) => prepareLabelSheetWindowsHybridPrint(
  sheet: sheet,
  settings: _settings,
  physicalSize: _physical,
  metrics: _metrics,
  options: options,
  lineSpacingPercent: options.autoSpacingPercent,
);

Future<img.Image> _previewPixels(WidgetTester tester) async {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint && widget.painter is fs.FortuneSheetPainter,
  );
  final painter = tester.widget<CustomPaint>(finder).painter!;
  final size = tester.getSize(finder);
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  try {
    return (await tester.runAsync(() async {
      final image = await picture.toImage(
        size.width.ceil(),
        size.height.ceil(),
      );
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return img.decodePng(bytes!.buffer.asUint8List())!;
      } finally {
        image.dispose();
      }
    }))!;
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('10mm margin reflows at 70mm; 10mm push keeps 80mm text width', () {
    final source = _sheet();
    final baseline = _prepare(source, _options());
    final margin = _prepare(source, _options(left: 10));
    final push = _prepare(source, _options(push: 10));
    expect(push.plan.sheet.defaultColWidth, source.defaultColWidth);
    expect(push.plan.sheet.rowHeights, source.rowHeights);
    expect(
      margin.plan.sheet.defaultColWidth! + 1,
      closeTo(fs.fortuneMillimetersToLogicalPixels(70), 0.001),
    );
    expect(margin.plan.sheet.rowHeights[0], greaterThan(source.rowHeights[0]!));
    final originalText = baseline.descriptors.first;
    expect(
      margin.descriptors.first.fontPixelHeight,
      originalText.fontPixelHeight,
    );
    expect(
      push.descriptors.first.fontPixelHeight,
      originalText.fontPixelHeight,
    );
    expect(
      margin.descriptors.first.left - originalText.left,
      closeTo(_metrics.dotsFromMm(10), 1),
    );
    expect(
      push.descriptors.first.left - originalText.left,
      closeTo(_metrics.dotsFromMm(10), 1),
    );
    expect(margin.plan.sheet.shapes.single.width, 40);
    expect(margin.plan.sheet.shapes.single.left, 250);
    expect(source.rowHeights, baseline.plan.sheet.rowHeights);
    expect(
      source.defaultColWidth! + 1,
      fs.fortuneMillimetersToLogicalPixels(80),
    );
  });

  test('right and combined margins reduce width; top only changes origin', () {
    final source = _sheet();
    final right = _prepare(source, _options(right: 10));
    final both = _prepare(source, _options(left: 10, right: 5));
    final top = _prepare(source, _options(top: 10));
    final baseline = _prepare(source, _options());
    expect(
      right.plan.sheet.defaultColWidth! + 1,
      closeTo(fs.fortuneMillimetersToLogicalPixels(70), 0.001),
    );
    expect(
      both.plan.sheet.defaultColWidth! + 1,
      closeTo(fs.fortuneMillimetersToLogicalPixels(65), 0.001),
    );
    expect(right.descriptors.first.left, baseline.descriptors.first.left);
    expect(top.plan.sheet.defaultColWidth, source.defaultColWidth);
    expect(top.plan.sheet.rowHeights, source.rowHeights);
    expect(
      top.descriptors.first.top - baseline.descriptors.first.top,
      closeTo(_metrics.dotsFromMm(10), 1),
    );
    for (final spacing in [80, 300]) {
      final options = _options(left: 10, spacing: spacing);
      final windows = _prepare(source, options);
      final ezpl = prepareLabelSheetEzplPrint(
        sheet: source,
        settings: _settings,
        physicalSize: _physical,
        metrics: _metrics,
        options: options,
        lineSpacingPercent: spacing,
      );
      expect(ezpl.plan.sheet.columnWidths, windows.plan.sheet.columnWidths);
      expect(
        ezpl.plan.sheet.defaultColWidth,
        windows.plan.sheet.defaultColWidth,
      );
      expect(ezpl.plan.sheet.rowHeights, windows.plan.sheet.rowHeights);
      expect(
        windows.plan.sheet.cells[const fs.FortuneCellCoord(0, 0)]!.fontSize,
        source.cells[const fs.FortuneCellCoord(0, 0)]!.fontSize,
      );
    }
  });

  test(
    'invalid margin area fails explicitly and rotated margins use text axis',
    () {
      final source = _sheet();
      for (final options in [
        _options(left: 80),
        _options(left: 70, right: 10, push: -10),
        _options(top: 60),
        _options(left: double.nan),
        _options(right: double.infinity),
        _options(top: -1),
      ]) {
        expect(() => _prepare(source, options), throwsFormatException);
      }
      final rotated = _prepare(source, _options(top: 10, rotate: true));
      expect(
        rotated.plan.sheet.defaultColWidth! + 1,
        closeTo(fs.fortuneMillimetersToLogicalPixels(70), 0.001),
      );
    },
  );

  test('margin narrows table columns without changing fixed row heights', () {
    final source = _sheet().copyWith(
      columnCount: 2,
      defaultColWidth: fs.fortuneMillimetersToLogicalPixels(40) - 1,
      rowHeights: {0: 24},
      cells: {
        const fs.FortuneCellCoord(0, 0): const fs.FortuneCell(
          value: 'Nutrition',
          fontSize: 10,
          textWrap: '2',
        ),
        const fs.FortuneCellCoord(0, 1): const fs.FortuneCell(
          value: 'Amount',
          fontSize: 10,
          textWrap: '2',
        ),
      },
    );
    final margin = _prepare(
      source,
      _options(left: 10, spacing: 300),
    ).plan.sheet;
    expect(
      (margin.defaultColWidth! + 1) * 2,
      closeTo(fs.fortuneMillimetersToLogicalPixels(70), 0.001),
    );
    expect(margin.rowHeights[0], 24);
    expect(
      margin.cells[const fs.FortuneCellCoord(0, 0)]!.extraFields['lineHeight'],
      1.15,
    );
  });

  test(
    'reflow moves RTF flow images but preserves fixed object dimensions',
    () {
      final paragraph = _sheet();
      final source = paragraph.copyWith(
        images: [
          for (final flow in [true, false])
            fs.FortuneImage(
              id: '$flow',
              src: '',
              left: 10,
              top: paragraph.rowHeights[0]! + 1,
              width: 12,
              height: 6,
              extraFields: flow ? const {'rtfPicture': true} : const {},
            ),
        ],
      );
      final margin = _prepare(source, _options(left: 10)).plan.sheet;
      expect(margin.images.first.top, greaterThan(source.images.first.top));
      expect(margin.images.last.top, source.images.last.top);
      for (final image in margin.images) {
        expect(image.width, 12);
        expect(image.height, 6);
        expect(image.left, 10);
      }
    },
  );

  testWidgets(
    'preview, raster and driver captures format margins exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = _sheet();
      final workbook = fs.FortuneWorkbook(sheets: [source]);
      final capture = LabelSheetOutputCaptureController();
      final zoom = LabelSheetZoomController();
      addTearDown(zoom.dispose);
      Widget preview(LabelSheetPrintOptions options) => MaterialApp(
        home: Scaffold(
          body: LabelOutputPreview(
            workbook: workbook,
            hintText: null,
            identityKey: 'margin-preview',
            labelSize: const LabelSize(
              labelSizeId: 1,
              brandId: 1,
              labelSizeName: 'Margin',
              labelSizeCommon: LabelSizeCommon(width: 80, height: 60, rtf: ''),
            ),
            imageObjectIds: const [],
            barcodeObjectIds: const [],
            printOptions: options,
            outputCaptureController: capture,
            zoomController: zoom,
          ),
        ),
      );
      await tester.pumpWidget(preview(_options()));
      await tester.pumpAndSettle();
      zoom.setZoomPercent(150);
      await tester.pumpAndSettle();
      final originalWidth = source.defaultColWidth;
      final baselineRaster = await tester.runAsync(
        () => capture.capture(
          dpi: _metrics.dpi,
          lineSpacingPercent: null,
          options: _options(),
        ),
      );
      for (final options in [
        _options(left: 10),
        _options(push: 10),
        _options(right: 10),
        _options(),
      ]) {
        await tester.pumpWidget(preview(options));
        await tester.pumpAndSettle();
        final expected = _prepare(source, options).plan.sheet;
        expect(
          capture.debugActiveSheet!.defaultColWidth,
          expected.defaultColWidth,
        );
        expect(capture.debugActiveSheet!.rowHeights, expected.rowHeights);
        expect(zoom.value, 150);
        final pixels = await _previewPixels(tester);
        final red = pixels.where(
          (pixel) => pixel.r == 255 && pixel.g == 0 && pixel.b == 0,
        );
        final xs = red.map((pixel) => pixel.x).toList()..sort();
        expect(xs, isNotEmpty);
        final visibleWidth =
            fs.fortuneMillimetersToLogicalPixels(
              80 -
                  options.rightMarginMm -
                  options.leftMarginMm -
                  options.leftPushMm,
            ) -
            250;
        expect(
          xs.last - xs.first + 1,
          closeTo(visibleWidth.clamp(0, 40) * 1.5, 2),
        );
        final driver = await tester.runAsync(
          () => capture.captureWindowsDriver(
            metrics: _metrics,
            options: options,
            lineSpacingPercent: null,
          ),
        );
        final raster = await tester.runAsync(
          () => capture.capture(
            dpi: _metrics.dpi,
            lineSpacingPercent: null,
            options: options,
          ),
        );
        final ezpl = await tester.runAsync(
          () => capture.captureEzpl(
            metrics: _metrics,
            options: options,
            lineSpacingPercent: null,
          ),
        );
        expect(driver!.sheet.defaultColWidth, expected.defaultColWidth);
        expect(raster!.sheet.defaultColWidth, expected.defaultColWidth);
        expect(ezpl!.sheet.defaultColWidth, expected.defaultColWidth);
        expect(driver.sheet.rowHeights, expected.rowHeights);
        expect(raster.sheet.rowHeights, expected.rowHeights);
        expect(ezpl.sheet.rowHeights, expected.rowHeights);
        expect(raster.sourceWidthMm, closeTo(80, 0.2));
        if (options.leftMarginMm == 0 && options.rightMarginMm == 0) {
          expect(raster.pngBytes, orderedEquals(baselineRaster!.pngBytes));
        } else {
          expect(
            raster.pngBytes,
            isNot(orderedEquals(baselineRaster!.pngBytes)),
          );
        }
        final pdf = await buildLabelSheetPdfBytes(
          pngBytes: raster.pngBytes,
          metrics: _metrics,
          options: options,
        );
        expect(pdf, isNotEmpty);
        expect(source.defaultColWidth, originalWidth);
      }
      await tester.pumpWidget(preview(_options(left: 80)));
      await tester.pumpAndSettle();
      expect(find.text('여백을 제외한 인쇄 영역이 없습니다.'), findsOneWidget);
      expect(capture.isAttached, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
