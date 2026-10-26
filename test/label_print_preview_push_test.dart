import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:image/image.dart' as img;
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/label_print/application/label_print_pipeline.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/presentation/label_print_page.dart';
import 'package:label_manager/features/label_print/presentation/label_print_settings_dialog.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/home_page_manager.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/widgets/label_print_settings_panel.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _colors = [
  Color(0xffff0000),
  Color(0xff00ff00),
  Color(0xff0000ff),
  Color(0xffffff00),
  Color(0xffff00ff),
];

LabelPrintSettingsSnapshot _settings(double left, double top) =>
    LabelPrintSettingsSnapshot(
      printerName: 'Preview test',
      leftMarginMm: 0,
      rightMarginMm: 0,
      topMarginMm: 0,
      leftPushMm: left,
      topPushMm: top,
      lineSpacingPercent: null,
      extraAreaMm: 0,
      orientation: LabelPrintOrientation.horizontal,
    );

ItemOfMarket _item(int id, {bool overrides = false}) => ItemOfMarket(
  marketId: 1,
  item: Item(
    itemId: id,
    labelSizeId: 1,
    itemName: 'Item $id',
    labelSizeName: 'Label',
    element: '',
    elementRTF: '',
    price: 0,
    order: id,
  ),
  additionalItem: AdditionalItem(
    AdditionalItemId: 0,
    itemId: id,
    element: '',
    elementRTF: '',
    price: 0,
  ),
  gdsNo: 0,
  dateSaleStart: DateTime(2026),
  dateSaleEnd: DateTime(2026),
  discountPercent: 0,
  discountAmount: 0,
  dateStartDiscount: DateTime(2026),
  dateEndDiscount: DateTime(2026),
  useDefineElement: false,
  rtfText: '',
  useLinefeed: false,
  linefeed: 0,
  useScaleBarcode: false,
  printCount: 1,
  useLabelSize: false,
  labelSizeWidth: 80,
  labelSizeHeight: 60,
  useMargin: overrides,
  leftMargin: 1.5,
  rightMargin: 0,
  topMargin: 3,
  leftPush: -1,
  topPush: 0.5,
);

String _solidImage(int r, int g, int b) {
  final image = img.Image(width: 8, height: 8);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
}

FortuneWorkbook _workbook() => FortuneWorkbook(
  sheets: [
    FortuneSheet(
      id: 'label',
      name: 'Label',
      rowCount: 12,
      columnCount: 4,
      showGridLines: false,
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 80,
        fortuneSheetGridClientHeightMmKey: 60,
      },
      cells: {
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: 'TEXT',
          background: Color(0xffff0000),
        ),
      },
      shapes: const [
        FortuneShape(
          id: 'shape',
          kind: FortuneShapeKind.rectangle,
          left: 40,
          top: 85,
          width: 20,
          height: 15,
          fillColor: '#00ff00',
          strokeColor: '#00ff00',
        ),
      ],
      lines: const [
        FortuneLine(
          id: 'line',
          x1: 100,
          y1: 100,
          x2: 120,
          y2: 100,
          strokeWidthMm: 1,
          strokeColor: '#0000ff',
        ),
      ],
      images: [
        FortuneImage(
          id: 'image',
          src: _solidImage(255, 255, 0),
          left: 30,
          top: 120,
          width: 15,
          height: 10,
        ),
        FortuneImage(
          id: 'barcode',
          src: _solidImage(255, 0, 255),
          left: 110,
          top: 120,
          width: 15,
          height: 10,
          extraFields: const {'fortuneBarcode': true},
        ),
      ],
    ),
  ],
);

Finder get _paintFinder => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is FortuneSheetPainter,
);

FortuneSheetPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_paintFinder).painter! as FortuneSheetPainter;

Future<img.Image> _raster(WidgetTester tester) async {
  final recorder = ui.PictureRecorder();
  final size = tester.getSize(_paintFinder);
  _painter(tester).paint(Canvas(recorder), size);
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

Rect _bounds(img.Image image, bool Function(img.Pixel) matches) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (final pixel in image) {
    if (!matches(pixel)) continue;
    left = math.min(left, pixel.x);
    top = math.min(top, pixel.y);
    right = math.max(right, pixel.x);
    bottom = math.max(bottom, pixel.y);
  }
  expect(right, greaterThanOrEqualTo(0), reason: 'Expected visible marker');
  return Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

Rect _colorBounds(img.Image image, Color color) => _bounds(
  image,
  (pixel) =>
      pixel.r == color.r * 255 &&
      pixel.g == color.g * 255 &&
      pixel.b == color.b * 255,
);

void _expectTranslation(Rect before, Rect after, Offset offset) {
  expect(after.left - before.left, closeTo(offset.dx, 1));
  expect(after.top - before.top, closeTo(offset.dy, 1));
  expect(after.width, closeTo(before.width, 1));
  expect(after.height, closeTo(before.height, 1));
}

Future<void> _waitForImages(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump();
    if (_painter(tester).decodedImages.length == 2) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  fail('Preview images did not finish decoding');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('changing only a preview offset requests repaint', () {
    final workbook = _workbook();
    const selection = FortuneSelection(row: 0, column: 0);
    FortuneSheetPainter painter(Offset? offset, {Rect? clip}) => FortuneSheetPainter(
      workbook: workbook,
      selection: selection,
      scrollOffset: Offset.zero,
      sheetTabScrollOffset: 0,
      textDirection: TextDirection.ltr,
      outputPreviewOffset: offset,
      outputPreviewClipRect: clip,
    );
    expect(
      painter(const Offset(5, -5)).shouldRepaint(painter(Offset.zero)),
      isTrue,
    );
    expect(painter(Offset.zero).shouldRepaint(painter(Offset.zero)), isFalse);
    expect(painter(null).shouldRepaint(painter(Offset.zero)), isTrue);
    expect(
      painter(Offset.zero, clip: const Rect.fromLTWH(0, 0, 70, 60))
          .shouldRepaint(
            painter(Offset.zero, clip: const Rect.fromLTWH(0, 0, 80, 60)),
          ),
      isTrue,
    );
  });

  testWidgets('pushes scale with zoom and clip only print preview content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final zoom = LabelSheetZoomController();
    addTearDown(zoom.dispose);
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 'clip',
          name: 'Clip',
          rowCount: 20,
          columnCount: 8,
          showGridLines: false,
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 80,
            fortuneSheetGridClientHeightMmKey: 60,
          },
          shapes: const [
            FortuneShape(
              id: 'center',
              kind: FortuneShapeKind.rectangle,
              left: 40,
              top: 40,
              width: 20,
              height: 20,
              fillColor: '#ff0000',
              strokeColor: '#ff0000',
            ),
            FortuneShape(
              id: 'edge',
              kind: FortuneShapeKind.rectangle,
              left: 290,
              top: 100,
              width: 30,
              height: 20,
              fillColor: '#00ff00',
              strokeColor: '#00ff00',
            ),
          ],
        ),
      ],
    );
    Widget preview(LabelSheetPrintOptions? options) => MaterialApp(
      home: Scaffold(
        body: LabelOutputPreview(
          workbook: workbook,
          hintText: null,
          identityKey: 'clip',
          labelSize: const LabelSize(
            labelSizeId: 1,
            brandId: 1,
            labelSizeName: 'Label',
            labelSizeCommon: LabelSizeCommon(width: 80, height: 60, rtf: ''),
          ),
          imageObjectIds: const [],
          barcodeObjectIds: const [],
          printOptions: options,
          zoomController: zoom,
        ),
      ),
    );
    LabelSheetPrintOptions options(double x, double y) =>
        labelPrintOptionsForRow(
          LabelPrintRowDraft.fromBaseline(
            item: _item(1),
            labelSize: const LabelSize(
              labelSizeId: 1,
              brandId: 1,
              labelSizeName: 'Label',
              labelSizeCommon: LabelSizeCommon(width: 80, height: 60, rtf: ''),
            ),
            copies: 1,
            settings: _settings(x, y),
          ),
          _settings(x, y),
        );
    for (final percent in [100, 200]) {
      await tester.pumpWidget(preview(options(0, 0)));
      zoom.setZoomPercent(percent);
      await tester.pumpAndSettle();
      final baseline = await _raster(tester);
      final clippedWidth = _colorBounds(baseline, _colors[1]).width;
      expect(_painter(tester).workbook.activeSheet.zoomRatio, percent / 100);
      await tester.pumpWidget(preview(options(5, 5)));
      await tester.pumpAndSettle();
      final shifted = await _raster(tester);
      expect(_painter(tester).workbook.activeSheet.zoomRatio, percent / 100);
      final pixels = fortuneMillimetersToLogicalPixels(5) * percent / 100;
      _expectTranslation(
        _colorBounds(baseline, _colors[0]),
        _colorBounds(shifted, _colors[0]),
        Offset(pixels, pixels),
      );
      expect(
        shifted.where(
          (pixel) => pixel.g == 255 && pixel.r == 0 && pixel.b == 0,
        ),
        isEmpty,
      );
      for (final mm in const [
        Offset(100, 0),
        Offset(-100, 0),
        Offset(0, 100),
        Offset(0, -100),
      ]) {
        await tester.pumpWidget(preview(options(mm.dx, mm.dy)));
        await tester.pumpAndSettle();
        final outside = await _raster(tester);
        expect(
          outside.where(
            (pixel) =>
                (pixel.r == 255 && pixel.g == 0 && pixel.b == 0) ||
                (pixel.g == 255 && pixel.r == 0 && pixel.b == 0),
          ),
          isEmpty,
        );
      }
      await tester.pumpWidget(preview(null));
      await tester.pumpAndSettle();
      expect(_painter(tester).outputPreviewOffset, isNull);
      expect(
        _colorBounds(await _raster(tester), _colors[1]).width,
        greaterThan(clippedWidth),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all signed pushes repaint every content kind, not rulers or capture',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final workbook = _workbook();
      final labelSize = LabelSize(
        labelSizeId: 1,
        brandId: 1,
        labelSizeName: 'Label',
        labelSizeCommon: LabelSizeCommon(
          width: 80,
          height: 60,
          rtf: labelSheetEncodeWorkbookSave(workbook),
        ),
      );
      final session = LabelPrintSessionController(settings: _settings(0, 0));
      addTearDown(session.dispose);
      final capture = LabelSheetOutputCaptureController();
      session.syncCheckedItems(
        baselineItems: [_item(1), _item(2, overrides: true)],
        checkedItemIds: const {1, 2},
        createRow: (item) => LabelPrintRowDraft.fromBaseline(
          item: item,
          labelSize: labelSize,
          copies: 1,
          settings: session.settings,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => LabelPrintPage(
                controller: session,
                previewBuilder: (row, zoom) =>
                    debugItemOutputPreviewTabForTesting(
                      item: row.item,
                      labelSize: labelSize,
                      elementWorkbook: workbook,
                      renderer: (_) async =>
                          throw StateError('Unexpected barcode encoding'),
                      printOptions: labelPrintOptionsForRow(
                        row,
                        session.settings,
                      ),
                      outputCaptureController: capture,
                      zoomController: zoom,
                    ),
                onPrinterSettings: () async {
                  final result = await showLabelPrintSettingsDialog(
                    context: context,
                    initial: session.settings,
                    showPdfSingleFileOption: false,
                  );
                  if (result != null) session.applySettings(result);
                },
                onIssue: () {},
                onCancelIssue: () {},
                busy: false,
              ),
            ),
          ),
        ),
      );
      await _waitForImages(tester);
      final baseline = await _raster(tester);
      final baselineBounds = [
        for (final color in _colors) _colorBounds(baseline, color),
      ];
      final initial = _painter(tester);
      final initialZoom = initial.workbook.activeSheet.zoomRatio;
      expect(initial.outputPreviewOffset, Offset.zero);
      final baselineCapture = await tester.runAsync(
        () => capture.capture(dpi: 96, lineSpacingPercent: null),
      );
      expect(baselineCapture, isNotNull);

      await tester.tap(find.text('프린터 설정'));
      await tester.pumpAndSettle();
      final panel = tester.widget<LabelPrintSettingsPanel>(
        find.byType(LabelPrintSettingsPanel),
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditableText &&
              widget.controller == panel.leftPushController,
        ),
        '5',
      );
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is EditableText &&
              widget.controller == panel.topPushController,
        ),
        '-5',
      );
      await tester.tap(find.text('적용'));
      await tester.pumpAndSettle();
      expect(session.settings.leftPushMm, 5);
      expect(session.settings.topPushMm, -5);

      for (final mm in const [
        Offset(5, -5),
        Offset(5, 0),
        Offset(-5, 0),
        Offset(0, 5),
        Offset(0, -5),
        Offset(-5, 5),
        Offset.zero,
      ]) {
        session.applySettings(_settings(mm.dx, mm.dy));
        await tester.pumpAndSettle();
        final current = _painter(tester);
        expect(
          current.outputPreviewOffset,
          Offset(
            fortuneMillimetersToLogicalPixels(mm.dx),
            fortuneMillimetersToLogicalPixels(mm.dy),
          ),
        );
        expect(current.workbook.activeSheet.zoomRatio, initialZoom);
        expect(
          current.sheetRulerCornerSizeLabel,
          initial.sheetRulerCornerSizeLabel,
        );
        final screen = await _raster(tester);
        final offset = current.outputPreviewOffset! * initialZoom;
        for (var index = 0; index < _colors.length; index++) {
          _expectTranslation(
            baselineBounds[index],
            _colorBounds(screen, _colors[index]),
            offset,
          );
        }
        final rulerHeight = current.workbook.settings.columnHeaderHeight
            .toInt();
        final rulerWidth = current.workbook.settings.rowHeaderWidth.toInt();
        for (var y = 0; y < rulerHeight; y++) {
          for (var x = 0; x < screen.width; x++) {
            expect(
              screen.getPixel(x, y).toList(),
              baseline.getPixel(x, y).toList(),
            );
          }
        }
        for (var y = 0; y < screen.height; y++) {
          for (var x = 0; x < rulerWidth; x++) {
            expect(
              screen.getPixel(x, y).toList(),
              baseline.getPixel(x, y).toList(),
            );
          }
        }
        final raw = await tester.runAsync(
          () => capture.capture(dpi: 96, lineSpacingPercent: null),
        );
        expect(raw!.pngBytes, baselineCapture!.pngBytes);
        expect(raw.sheet.images.first.left, 30);
        expect(raw.sheet.images.first.top, 120);
      }

      session.applySettings(_settings(5, 5));
      await tester.pumpAndSettle();
      final raw = await tester.runAsync(
        () => capture.capture(dpi: 96, lineSpacingPercent: null),
      );
      const metrics = LabelSheetPrintPageMetrics(
        labelWidthMm: 80,
        labelHeightMm: 60,
        dpi: 96,
      );
      img.Image driverImage(LabelSheetWindowsDriverPage page) =>
          img.Image.fromBytes(
            width: page.width,
            height: page.height,
            bytes: page.bgraBytes.buffer,
            numChannels: 4,
            order: img.ChannelOrder.bgra,
          );
      final basePage = prepareLabelSheetWindowsDriverPage(
        pngBytes: baselineCapture!.pngBytes,
        metrics: metrics,
        options: labelPrintOptionsForRow(
          session.rows.first.copyWith(leftPushMm: 0, topPushMm: 0),
          _settings(0, 0),
        ),
      );
      final page = prepareLabelSheetWindowsDriverPage(
        pngBytes: raw!.pngBytes,
        metrics: metrics,
        options: labelPrintOptionsForRow(session.rows.first, session.settings),
      );
      _expectTranslation(
        _bounds(driverImage(basePage), (pixel) => pixel.r == 0),
        _bounds(driverImage(page), (pixel) => pixel.r == 0),
        const Offset(19, 19),
      );

      session.selectItem(2);
      await tester.pumpAndSettle();
      await _waitForImages(tester);
      expect(
        _painter(tester).outputPreviewOffset,
        Offset(
          fortuneMillimetersToLogicalPixels(0.5),
          fortuneMillimetersToLogicalPixels(3.5),
        ),
      );
      session.applySettings(_settings(-3, -4));
      await tester.pumpAndSettle();
      expect(
        _painter(tester).outputPreviewOffset,
        Offset(
          fortuneMillimetersToLogicalPixels(0.5),
          fortuneMillimetersToLogicalPixels(3.5),
        ),
      );
      session.selectItem(1);
      session.updateRow(
        1,
        (row) => row.copyWith(
          leftPushMm: 7,
          topPushMm: -6,
          leftPushSource: LabelPrintValueSource.sessionEdited,
          topPushSource: LabelPrintValueSource.sessionEdited,
        ),
      );
      session.applySettings(_settings(1, 2));
      await tester.pumpAndSettle();
      await _waitForImages(tester);
      expect(
        _painter(tester).outputPreviewOffset,
        Offset(
          fortuneMillimetersToLogicalPixels(7),
          fortuneMillimetersToLogicalPixels(-6),
        ),
      );
      expect(_painter(tester).workbook.activeSheet.zoomRatio, initialZoom);
      expect(tester.takeException(), isNull);
    },
  );
}
