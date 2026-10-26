import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:image/image.dart' as image;
import 'package:label_manager/features/label_sheet/application/label_sheet_barcode_renderer.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/home_page_manager.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

FortuneSheetPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(FortuneSheetCanvas),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<FortuneSheetPainter>()
    .single;

Finder _input(String name) => find.descendant(
  of: find.byKey(ValueKey('fortune-barcode-$name-input')),
  matching: find.byType(EditableText),
);

Future<void> _enter(WidgetTester tester, String name, String value) async {
  await tester.enterText(_input(name), value);
  await tester.pump();
}

Future<FortuneBarcodeRenderResult?> _renderBarcode(
  FortuneBarcodeRequest request,
) async {
  if (const bool.fromEnvironment('BARCODE_HEIGHT_NATIVE')) {
    return labelSheetBarcodeRenderer(request);
  }
  // Keep unit tests independent of the native encoder, but use production
  // geometry and PNG composition so visible ink height is still measured.
  final size = labelSheetBarcodeOutputSize(request);
  final bodyHeight = request.formatId == 'code128'
      ? labelSheetBarcodeEncodeHeight(request)
      : size.height;
  final body = image.Image(width: size.width, height: bodyHeight);
  for (var y = 0; y < bodyHeight; y++) {
    for (var x = 0; x < size.width; x++) {
      final value = x.isEven ? 0 : 255;
      body.setPixelRgb(x, y, value, value, value);
    }
  }
  final bytes = await labelSheetComposeBarcodePngForTesting(
    request,
    body,
    width: size.width,
    height: size.height,
    bodyHeight: bodyHeight,
  );
  return FortuneBarcodeRenderResult(
    bytes: bytes,
    pixelWidth: size.width,
    pixelHeight: size.height,
    bodyTop: 0,
    bodyHeight: bodyHeight,
  );
}

Future<FortuneSheetController> _pumpCanvas(
  WidgetTester tester,
  List<FortuneBarcodeRequest> requests, {
  bool millimeters = true,
  String format = 'code128',
  bool withPanel = false,
  List<FortuneImage> initialImages = const [],
  FortuneBarcodeRenderer renderer = _renderBarcode,
}) async {
  await tester.binding.setSurfaceSize(Size(withPanel ? 1200 : 900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = FortuneSheetController();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Row(children: [
      SizedBox(width: 900, child: FortuneSheetCanvas(
        controller: controller,
        workbook: FortuneWorkbook(
          settings: const FortuneSettings(
            toolbarItems: [fortuneToolbarBarcodeCommand],
          ),
          sheets: [
            FortuneSheet(
              id: 'label',
              name: 'Label',
              images: initialImages,
              extraFields: millimeters ? const {
                fortuneSheetGridClientWidthMmKey: 150,
                fortuneSheetGridClientHeightMmKey: 150,
              } : const {},
            ),
          ],
        ),
        barcodeObjectConnectionMode: FortuneObjectConnectionMode.structured,
        barcodeFormats: [
          FortuneBarcodeFormatOption(
            id: format,
            label: format,
            ratio: format == 'code128' ? 3 : 1,
          ),
        ],
        barcodeRenderer: (request) {
          requests.add(request);
          return renderer(request);
        },
      )),
      if (withPanel)
        SizedBox(width: 300, child: FortuneObjectLayerPanel(controller: controller)),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _tapDialog(
  WidgetTester tester,
  Rect Function(Rect) control,
) async {
  final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
  final rect = fortuneBarcodeDialogRect(const Size(900, 700));
  await tester.tapAt(topLeft + control(rect).center);
  await tester.pump();
}

Future<void> _openDialog(WidgetTester tester) async {
  final button = fortuneVisibleToolbarItemRects(
    900,
    items: const [fortuneToolbarBarcodeCommand],
  ).singleWhere((entry) => entry.key == fortuneToolbarBarcodeCommand);
  await tester.tapAt(
    tester.getTopLeft(find.byType(FortuneSheetCanvas)) + button.value.center,
  );
  await tester.pump();
  expect(_painter(tester).barcodeDialogOpen, isTrue);
  await _enter(tester, 'text', '1234');
}

Future<void> _confirm(WidgetTester tester) async {
  final controller = tester
      .widget<FortuneSheetCanvas>(find.byType(FortuneSheetCanvas))
      .controller!;
  final count = controller.getSheet(id: 'label')!.images.length;
  await tester.runAsync(() async {
    await _tapDialog(tester, fortuneBarcodeConfirmButtonRect);
    final timer = Stopwatch()..start();
    while (controller.getSheet(id: 'label')!.images.length == count) {
      if (timer.elapsed > const Duration(seconds: 5)) {
        fail('Barcode insertion did not complete.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

int _inkHeight(FortuneImage barcode) {
  final png = image.decodePng(base64Decode(barcode.src.split(',').last))!;
  var rows = 0;
  for (var y = 0; y < png.height; y++) {
    for (var x = 0; x < png.width; x++) {
      final pixel = png.getPixel(x, y);
      if (pixel.a > 0 && pixel.r < 128) {
        rows++;
        break;
      }
    }
  }
  return rows;
}

Future<void> _revealProperty(WidgetTester tester, Finder field) async {
  final list = find.descendant(
    of: find.byType(FortuneObjectLayerPanel),
    matching: find.byType(ListView),
  ).last;
  await tester.drag(list, const Offset(0, 1200));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    field, 100,
    scrollable: find.descendant(
      of: list, matching: find.byType(Scrollable),
    ).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _applyProperties(WidgetTester tester, FortuneSheetController controller) async {
  final apply = find.byKey(const ValueKey('fortune-object-property-apply'));
  await _revealProperty(tester, apply);
  await tester.runAsync(() async {
    await tester.tap(apply);
    final timer = Stopwatch()..start();
    while (controller.barcodePropertyRenderPending) {
      if (timer.elapsed > const Duration(seconds: 5)) {
        fail('Barcode property render did not finish.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('failed aspect-only apply keeps original metadata and retryable checkbox draft', (tester) async {
    final requests = <FortuneBarcodeRequest>[];
    var failRender = false;
    final controller = await _pumpCanvas(tester, requests, withPanel: true,
      renderer: (request) async => failRender ? null : await _renderBarcode(request));
    await _openDialog(tester);
    await _confirm(tester);
    final original = controller.getSheet(id: 'label')!.images.single;
    expect(original.extraFields['barcodeAspectLocked'], isTrue);
    controller.selectObject(FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, original.id));
    await tester.pumpAndSettle();
    final lock = find.byKey(const ValueKey('fortune-object-property-aspect-lock'));
    await _revealProperty(tester, lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();
    failRender = true;
    await _applyProperties(tester, controller);
    expect(find.text('바코드를 생성하지 못했습니다.'), findsOneWidget);
    expect(controller.objectSelection.activeImage!.extraFields['barcodeAspectLocked'], isTrue);
    await _revealProperty(tester, lock);
    expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
    failRender = false;
    await _applyProperties(tester, controller);
    expect(controller.objectSelection.activeImage!.extraFields['barcodeAspectLocked'], isFalse);
    expect(controller.objectSelection.activeImage!.width, original.width);
    expect(controller.objectSelection.activeImage!.height, original.height);
  });

  for (final format in ['code128', 'qrCode']) {
    for (final millimeters in [true, false]) {
      for (final locked in [true, false]) {
        testWidgets('insertion aspect=$locked persists for $format in ${millimeters ? 'mm' : 'px'}', (tester) async {
          final requests = <FortuneBarcodeRequest>[];
          final controller = await _pumpCanvas(tester, requests,
            format: format, millimeters: millimeters, withPanel: true);
          await _openDialog(tester);
          if (!locked) await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
          await _enter(tester, 'width', '20');
          await _enter(tester, 'height', '10');
          await _confirm(tester);
          final original = controller.getSheet(id: 'label')!.images.single;
          controller.selectObject(FortuneSheetObjectKey(
            FortuneSheetObjectKind.barcode, original.id));
          await tester.pumpAndSettle();
          final lock = find.byKey(const ValueKey('fortune-object-property-aspect-lock'));
          await _revealProperty(tester, lock);
          expect(tester.widget<CheckboxListTile>(lock).value, locked);
          final width = find.byKey(const ValueKey('fortune-object-property-width'));
          await _revealProperty(tester, width);
          await tester.enterText(width, '40');
          await tester.pump();
          await _applyProperties(tester, controller);
          final updated = controller.objectSelection.activeImage!;
          final expectedWidth = millimeters ? fortuneMillimetersToLogicalPixels(40) : 40.0;
          expect(updated.width, closeTo(expectedWidth, 0.005));
          expect(updated.height, closeTo(locked
              ? expectedWidth * original.height / original.width
              : original.height, 0.005));
          final restored = labelSheetDecodeWorkbookSave(
            labelSheetBuildSavePayload(_painter(tester).workbook).encodedWorkbook,
          ).activeSheet.images.single;
          expect(restored.extraFields['barcodeAspectLocked'], locked);
          expect(restored.extraFields['barcodeBarHeight'], updated.extraFields['barcodeBarHeight']);
        });
      }
    }
  }

  testWidgets('inserted unlocked barcode keeps aspect state in properties and saved workbook', (tester) async {
    final requests = <FortuneBarcodeRequest>[];
    final controller = await _pumpCanvas(tester, requests, withPanel: true);
    await _openDialog(tester);
    await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
    await _enter(tester, 'width', '20');
    await _enter(tester, 'height', '10');
    await _confirm(tester);
    final barcode = controller.getSheet(id: 'label')!.images.single;
    controller.selectObject(FortuneSheetObjectKey(
      FortuneSheetObjectKind.barcode, barcode.id,
    ));
    await tester.pumpAndSettle();
    final lock = find.byKey(const ValueKey('fortune-object-property-aspect-lock'));
    await _revealProperty(tester, lock);
    expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
    expect(barcode.extraFields['barcodeAspectLocked'], isFalse);
    await tester.tap(find.byTooltip('선택한 개체 복제'));
    await tester.pumpAndSettle();
    final duplicate = controller.objectSelection.activeImage!;
    expect(duplicate.id, isNot(barcode.id));
    expect(duplicate.extraFields['barcodeAspectLocked'], isFalse);
    controller.selectObject(FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, barcode.id));
    await tester.pumpAndSettle();
    controller.selectObject(FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, duplicate.id));
    await tester.pumpAndSettle();
    await _revealProperty(tester, lock);
    expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
    await tester.tap(lock);
    await tester.pumpAndSettle();
    expect(controller.objectSelection.activeImage!.extraFields['barcodeAspectLocked'], isFalse);
    await _applyProperties(tester, controller);
    expect(controller.objectSelection.activeImage!.extraFields['barcodeAspectLocked'], isTrue);
    expect(controller.getSheet(id: 'label')!.images.first.extraFields['barcodeAspectLocked'], isFalse);
    controller.handleUndo();
    await tester.pumpAndSettle();
    await _revealProperty(tester, lock);
    expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
    controller.handleRedo();
    await tester.pumpAndSettle();
    await _revealProperty(tester, lock);
    expect(tester.widget<CheckboxListTile>(lock).value, isTrue);
    final restored = labelSheetDecodeWorkbookSave(
      labelSheetBuildSavePayload(_painter(tester).workbook).encodedWorkbook,
    );
    expect(restored.activeSheet.images.first.extraFields['barcodeAspectLocked'], isFalse);
    expect(restored.activeSheet.images.last.extraFields['barcodeAspectLocked'], isTrue);
    final legacy = barcode.copyWith(
      id: 'legacy',
      extraFields: Map<String, Object?>.from(barcode.extraFields)..remove('barcodeAspectLocked'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final reloaded = await _pumpCanvas(tester, requests, withPanel: true,
      initialImages: [...restored.activeSheet.images, legacy]);
    for (final entry in {barcode.id: false, duplicate.id: true, 'legacy': true}.entries) {
      reloaded.selectObject(FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, entry.key));
      await tester.pumpAndSettle();
      await _revealProperty(tester, lock);
      expect(tester.widget<CheckboxListTile>(lock).value, entry.value);
    }
  });

  testWidgets('custom caption changes PNG text but not barcode ink or payload', (tester) async {
    FortuneBarcodeRequest request(String? caption) => FortuneBarcodeRequest(
      text: '12345679123', formatId: 'code128',
      width: 300, height: 150, rotation: 0, barHeight: 100,
      showHumanReadableText: true, humanReadableText: caption,
    );
    await tester.runAsync(() async {
      final original = await _renderBarcode(request(null));
      final custom = await _renderBarcode(request('2345'));
      final before = image.decodePng(original!.bytes)!;
      final after = image.decodePng(custom!.bytes)!;
      expect(after.width, before.width);
      expect(after.height, before.height);
      expect(custom.bodyHeight, original.bodyHeight);
      var captionDifferences = 0;
      for (var y = 0; y < after.height; y++) {
        for (var x = 0; x < after.width; x++) {
          final changed = after.getPixel(x, y).r != before.getPixel(x, y).r ||
              after.getPixel(x, y).a != before.getPixel(x, y).a;
          if (y < 100) {
            expect(changed, isFalse, reason: 'barcode body pixel $x,$y');
          } else if (changed) {
            captionDifferences++;
          }
        }
      }
      expect(captionDifferences, greaterThan(0));
    });
  });

  for (final millimeters in [true, false]) {
    testWidgets('property height sync keeps explicit overrides in ${millimeters ? 'mm' : 'px'}', (tester) async {
      final requests = <FortuneBarcodeRequest>[];
      final controller = await _pumpCanvas(
        tester, requests, millimeters: millimeters, withPanel: true,
      );
      await _openDialog(tester);
      await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
      await _enter(tester, 'width', '20');
      await _enter(tester, 'height', '10');
      await _confirm(tester);
      final original = controller.getSheet(id: 'label')!.images.single;
      controller.selectObject(FortuneSheetObjectKey(
        FortuneSheetObjectKind.barcode, original.id,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('선택한 개체 복제'));
      await tester.pumpAndSettle();
      final lock = find.byKey(const ValueKey('fortune-object-property-aspect-lock'));
      await _revealProperty(tester, lock);
      expect(tester.widget<CheckboxListTile>(lock).value, isFalse);

      Finder field(String name) => find.byKey(
        ValueKey('fortune-object-property-$name'),
      );
      Future<void> enter(String name, String value) async {
        await _revealProperty(tester, field(name));
        await tester.enterText(field(name), value);
        await tester.pumpAndSettle();
      }
      Future<void> expectBarText(String value) async {
        await _revealProperty(tester, field('barHeight'));
        expect(tester.widget<TextField>(field('barHeight')).controller!.text, value);
      }
      double pixels(double value) =>
          millimeters ? fortuneMillimetersToLogicalPixels(value) : value;
      void expectRendered(double width, double height, double bars) {
        final updated = controller.objectSelection.activeImage!;
        expect(updated.width, closeTo(pixels(width), 0.005));
        expect(updated.height, closeTo(pixels(height), 0.005));
        expect(requests.last.barHeight, closeTo(pixels(bars), 0.005));
        expect(updated.extraFields['barcodeBarHeight'], bars);
        expect(_inkHeight(updated), pixels(bars).round());
        expect(controller.getSheet(id: 'label')!.images.first.src, original.src);
      }

      await enter('height', '15');
      await expectBarText('15');
      await _applyProperties(tester, controller);
      expectRendered(20, 15, 15);
      await enter('height', '20');
      await enter('barHeight', '7');
      await _applyProperties(tester, controller);
      expectRendered(20, 20, 7);
      for (final invalid in ['', '0', '-1', 'NaN']) {
        await enter('height', invalid);
        await expectBarText('7');
      }
      await enter('height', '25');
      await expectBarText('25');
      await enter('barHeight', '8');
      await _applyProperties(tester, controller);
      expectRendered(20, 25, 8);
      await enter('width', '40');
      await expectBarText('8');
      await _applyProperties(tester, controller);
      expectRendered(40, 25, 8);

      await enter('width', '60');
      await _revealProperty(tester, lock);
      await tester.tap(lock);
      await tester.pumpAndSettle();
      await expectBarText('37.5');
      await _revealProperty(tester, lock);
      await tester.tap(lock);
      await tester.pumpAndSettle();
      await expectBarText('25');
      await _revealProperty(tester, lock);
      await tester.tap(lock);
      await tester.pumpAndSettle();
      await enter('barHeight', '9');
      await _applyProperties(tester, controller);
      expectRendered(60, 37.5, 9);
    });
  }

  for (final format in ['code128', 'qrCode']) {
    for (final millimeters in [true, false]) {
      testWidgets('barcode property aspect lock supports $format in ${millimeters ? 'mm' : 'px'}', (tester) async {
        final requests = <FortuneBarcodeRequest>[];
        final controller = await _pumpCanvas(
          tester, requests, format: format, millimeters: millimeters, withPanel: true,
        );
        await _openDialog(tester);
        await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
        await _enter(tester, 'width', '20');
        await _enter(tester, 'height', '10');
        await _confirm(tester);
        final original = _painter(tester).workbook.activeSheet.images.single;
        controller.selectObject(FortuneSheetObjectKey(
          FortuneSheetObjectKind.barcode, original.id,
        ));
        await tester.pumpAndSettle();
        final lock = find.byKey(const ValueKey('fortune-object-property-aspect-lock'));
        await _revealProperty(tester, lock);
        expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
        await tester.tap(lock);
        await tester.pumpAndSettle();
        expect(tester.widget<CheckboxListTile>(lock).value, isTrue);
        expect(tester.widget<CheckboxListTile>(lock).onChanged, isNotNull);

        Future<void> change(String name, String value, double width, double height) async {
          final field = find.byKey(ValueKey('fortune-object-property-$name'));
          await _revealProperty(tester, field);
          await tester.enterText(field, value);
          await tester.pumpAndSettle();
          await _applyProperties(tester, controller);
          double pixels(double size) => millimeters
              ? fortuneMillimetersToLogicalPixels(size) : size;
          final updated = controller.objectSelection.activeImage!;
          expect(updated.width, closeTo(pixels(width), 0.005));
          expect(updated.height, closeTo(pixels(height), 0.005));
          expect(requests.last.width, closeTo(pixels(width), 0.005));
          expect(requests.last.height, closeTo(pixels(height), 0.005));
          expect(updated.extraFields['barcodeBarHeight'],
              format == 'code128' ? height : 10);
          expect(requests.last.moduleScale, 3);
          expect(updated.extraFields['barcodeFormatId'], format);
        }

        await change('width', '40', 40, 20);
        await change('height', '15', 30, 15);
        await _revealProperty(tester, lock);
        final rendersBeforeToggle = requests.length;
        await tester.tap(lock);
        await tester.pumpAndSettle();
        expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
        expect(requests.length, rendersBeforeToggle);
        await change('width', '50', 50, 15);
        await _revealProperty(tester, lock);
        expect(tester.widget<CheckboxListTile>(lock).value, isFalse);
        await change('height', '25', 50, 25);
        await _revealProperty(tester, lock);
        await tester.tap(lock);
        await tester.pumpAndSettle();
        await change('width', '60', 60, 30);
        await change('rotation', '1', 60, 30);
        final payload = labelSheetBuildSavePayload(_painter(tester).workbook);
        final saved = labelSheetDecodeWorkbookSave(payload.encodedWorkbook).activeSheet.images.single;
        expect(saved.width, closeTo(requests.last.width, 0.005));
        expect(saved.height, closeTo(requests.last.height, 0.005));
        expect(saved.extraFields['rotation'], 1);
        controller.handleUndo();
        await tester.pumpAndSettle();
        expect(controller.objectSelection.activeImage!.extraFields['rotation'], 0);
        controller.handleRedo();
        await tester.pumpAndSettle();
        expect(controller.objectSelection.activeImage!.extraFields['rotation'], 1);
      });
    }
  }

  for (final imported in [false, true]) {
    test('barcode height units match preview and native print${imported ? ' for RTF import' : ''}', () async {
      final height = fortuneMillimetersToLogicalPixels(10);
      final barcode = FortuneImage(
        id: 'barcode',
        src: '',
        left: 10,
        top: 10,
        width: fortuneMillimetersToLogicalPixels(20),
        height: height,
        extraFields: {
          'fortuneBarcode': true,
          'barcodeText': '1234',
          'barcodeFormatId': 'code128',
          'barcodeBarHeight': imported ? height : 10,
          'rtfBarcodeDecoded': imported,
          'itemCodePreviewResolved': true,
          'barcodeShowText': false,
        },
      );
      final sheet = FortuneSheet(
        id: 'label',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 150,
          fortuneSheetGridClientHeightMmKey: 150,
        },
        images: [barcode],
      );
      expect(fortuneBarcodeBarHeightInLogicalPixels(barcode, geometryUsesMillimeters: true),
          closeTo(height, 0.001));
      FortuneBarcodeRequest? request;
      await debugRenderItemOutputPreviewBarcodesForTesting(
        FortuneWorkbook(sheets: [sheet]),
        renderer: (value) async {
          request = value;
          return _renderBarcode(value);
        },
      );
      expect(request!.barHeight, closeTo(height, 0.001));
      final preparation = prepareLabelSheetEzplPrint(
        sheet: sheet,
        settings: const FortuneSettings(),
        physicalSize: const FortuneSheetGridClientPhysicalSize(widthMm: 150, heightMm: 150),
        metrics: const LabelSheetPrintPageMetrics(labelWidthMm: 150, labelHeightMm: 150, dpi: 203.2),
        options: const LabelSheetPrintOptions(
          copies: 1, leftMarginMm: 0, topMarginMm: 0, extraAreaMm: 0,
          autoSpacingPercent: null, orientation: LabelSheetPrintOrientation.horizontal,
        ),
      );
      final command = preparation.descriptors.single.command;
      expect(command, contains(',80,0,0,1234\r\n'));
    });
  }

  for (final mode in ['mm', 'px', 'rtf']) {
    testWidgets('duplicated barcode rotation preserves ink and resize updates it in $mode', (tester) async {
      final millimeters = mode != 'px';
      final requests = <FortuneBarcodeRequest>[];
      final initialImages = <FortuneImage>[];
      if (mode == 'rtf') {
        final width = fortuneMillimetersToLogicalPixels(20);
        final height = fortuneMillimetersToLogicalPixels(10);
        final rendered = await tester.runAsync(() => _renderBarcode(FortuneBarcodeRequest(
          text: '1234', formatId: 'code128', width: width, height: height,
          rotation: 0, barHeight: height,
        )));
        initialImages.add(FortuneImage(
          id: 'rtf_barcode', src: 'data:image/png;base64,${base64Encode(rendered!.bytes)}',
          left: 10, top: 10, width: width, height: height,
          extraFields: {
            'fortuneBarcode': true, 'rtfBarcodeDecoded': true,
            'barcodeText': '1234', 'barcodeFormatId': 'code128',
            'barcodeBarHeight': height,
          },
        ));
      }
      final controller = await _pumpCanvas(
        tester, requests, millimeters: millimeters, withPanel: true,
        initialImages: initialImages,
      );
      if (initialImages.isEmpty) {
        await _openDialog(tester);
        await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
        await _enter(tester, 'width', '20');
        await _enter(tester, 'height', '10');
        await _confirm(tester);
      }
      final original = _painter(tester).workbook.activeSheet.images.single;
      controller.selectObject(FortuneSheetObjectKey(
        FortuneSheetObjectKind.barcode, original.id,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('선택한 개체 복제'));
      await tester.pumpAndSettle();
      final duplicate = controller.objectSelection.activeImage!;
      expect(duplicate.id, isNot(original.id));
      expect(duplicate.src, original.src);
      for (final angle in [1, 2]) {
        final list = find.descendant(
          of: find.byType(FortuneObjectLayerPanel), matching: find.byType(ListView),
        ).last;
        await tester.drag(list, const Offset(0, 1200));
        await tester.pumpAndSettle();
        final rotation = find.byKey(const ValueKey('fortune-object-property-rotation'));
        await tester.scrollUntilVisible(rotation, 100, scrollable: find.descendant(
          of: list, matching: find.byType(Scrollable),
        ).first);
        await tester.enterText(rotation, '$angle');
        await tester.pumpAndSettle();
        final apply = find.byKey(const ValueKey('fortune-object-property-apply'));
        await tester.drag(list, const Offset(0, -900));
        await tester.pumpAndSettle();
        await tester.ensureVisible(apply);
        await tester.pump();
        await tester.runAsync(() async {
          await tester.tap(apply);
          final timer = Stopwatch()..start();
          while (controller.barcodePropertyRenderPending) {
            if (timer.elapsed > const Duration(seconds: 5)) {
              fail('Barcode property render did not finish.');
            }
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pumpAndSettle();
        expect(requests.last.barHeight, closeTo(original.height, 0.001));
        final updated = controller.objectSelection.activeImage!;
        expect(updated.extraFields['rotation'], angle);
        expect((updated.width, updated.height), (original.width, original.height));
        expect(updated.extraFields['barcodeBarHeight'],
            closeTo(mode == 'rtf' ? original.height : 10, 0.001));
        expect(_inkHeight(updated), _inkHeight(original));
        final payload = labelSheetBuildSavePayload(_painter(tester).workbook);
        final saved = labelSheetDecodeWorkbookSave(payload.encodedWorkbook);
        expect(_inkHeight(saved.activeSheet.images.last), _inkHeight(original));
        expect(saved.activeSheet.images.first.src, original.src);
      }
      controller.handleUndo();
      await tester.pumpAndSettle();
      expect(controller.objectSelection.activeImage!.extraFields['rotation'], 1);
      controller.handleRedo();
      await tester.pumpAndSettle();
      expect(controller.objectSelection.activeImage!.extraFields['rotation'], 2);
      expect(_inkHeight(controller.objectSelection.activeImage!), _inkHeight(original));
      final heightField = find.byKey(
        const ValueKey('fortune-object-property-height'),
      );
      await _revealProperty(tester, heightField);
      await tester.enterText(heightField, '15');
      await tester.pumpAndSettle();
      await _applyProperties(tester, controller);
      final resized = controller.objectSelection.activeImage!;
      final expectedHeight = millimeters
          ? fortuneMillimetersToLogicalPixels(15) : 15.0;
      expect(requests.last.barHeight, closeTo(expectedHeight, 0.005));
      expect(resized.height, closeTo(expectedHeight, 0.005));
      expect(resized.width, closeTo(
        original.extraFields['barcodeAspectLocked'] == false
            ? original.width : expectedHeight * 2, 0.005));
      expect(resized.extraFields['barcodeBarHeight'],
          closeTo(mode == 'rtf' ? expectedHeight : 15, 0.005));
      final unrotated = image.decodePng(base64Decode(resized.src.split(',').last))!;
      expect(unrotated.height, expectedHeight.round());
      expect(_inkHeight(resized), expectedHeight.round());
      expect(resized.extraFields['rotation'], 2);
      final savedResize = labelSheetDecodeWorkbookSave(
        labelSheetBuildSavePayload(_painter(tester).workbook).encodedWorkbook,
      );
      expect(_inkHeight(savedResize.activeSheet.images.last), expectedHeight.round());
      expect(savedResize.activeSheet.images.first.src, original.src);
      controller.handleUndo();
      await tester.pumpAndSettle();
      expect(_inkHeight(controller.objectSelection.activeImage!), _inkHeight(original));
      controller.handleRedo();
      await tester.pumpAndSettle();
      expect(_inkHeight(controller.objectSelection.activeImage!), expectedHeight.round());
      expect(tester.takeException(), isNull);
    });
  }

  for (final millimeters in [true, false]) {
    testWidgets(
      'barcode insertion renders distinct 10 and 20 heights in ${millimeters ? 'mm' : 'px'}',
      (tester) async {
        final requests = <FortuneBarcodeRequest>[];
        final controller = await _pumpCanvas(
          tester, requests, millimeters: millimeters,
        );
        double pixels(double size) =>
            millimeters ? fortuneMillimetersToLogicalPixels(size) : size;
        for (final height in [10, 20]) {
          await _openDialog(tester);
          await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
          await _enter(tester, 'width', '20');
          await _enter(tester, 'height', '$height');
          expect(
            tester.widget<EditableText>(_input('bar-height')).controller.text,
            '$height',
          );
          await _confirm(tester);
          final inserted = _painter(tester).workbook.activeSheet.images.last;
          expect(inserted.width, closeTo(pixels(20), 0.001));
          expect(inserted.height, closeTo(pixels(height.toDouble()), 0.001));
          expect(inserted.extraFields['barcodeBarHeight'], height);
          expect(inserted.extraFields[fortuneBarcodeObjectIdExtraKey], isNull);
          expect(requests.last.barHeight, closeTo(inserted.height, 0.001));
          expect(_inkHeight(inserted), pixels(height.toDouble()).round());
        }
        final workbook = _painter(tester).workbook;
        expect(workbook.activeSheet.images, hasLength(2));
        final payload = labelSheetBuildSavePayload(workbook);
        final saved = labelSheetDecodeWorkbookSave(payload.encodedWorkbook);
        for (var index = 0; index < 2; index++) {
          final barcode = saved.activeSheet.images[index];
          expect(barcode.extraFields['barcodeBarHeight'], (index + 1) * 10);
          expect(_inkHeight(barcode), pixels((index + 1) * 10.0).round());
        }
        controller.handleUndo();
        await tester.pumpAndSettle();
        expect(_painter(tester).workbook.activeSheet.images, hasLength(1));
        controller.handleRedo();
        await tester.pumpAndSettle();
        expect(_painter(tester).workbook.activeSheet.images, hasLength(2));
        expect(_inkHeight(_painter(tester).workbook.activeSheet.images.last),
            pixels(20).round());
      },
    );
  }

  testWidgets('aspect-linked dimensions sync bar height but explicit height wins', (
    tester,
  ) async {
    final requests = <FortuneBarcodeRequest>[];
    await _pumpCanvas(tester, requests);
    await _openDialog(tester);
    await _enter(tester, 'width', '60');
    expect(tester.widget<EditableText>(_input('height')).controller.text, '20');
    expect(tester.widget<EditableText>(_input('bar-height')).controller.text, '20');
    await _enter(tester, 'height', '30');
    expect(tester.widget<EditableText>(_input('width')).controller.text, '90');
    expect(tester.widget<EditableText>(_input('bar-height')).controller.text, '30');
    await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
    await _enter(tester, 'width', '20');
    expect(tester.widget<EditableText>(_input('bar-height')).controller.text, '30');
    await _enter(tester, 'height', '20');
    await _enter(tester, 'bar-height', '7');
    await _enter(tester, 'height', '');
    await _enter(tester, 'height', '0');
    expect(tester.widget<EditableText>(_input('bar-height')).controller.text, '7');
    await _enter(tester, 'height', '20');
    await _enter(tester, 'bar-height', '7');
    await _confirm(tester);
    expect(requests.single.height, closeTo(fortuneMillimetersToLogicalPixels(20), 0.001));
    expect(requests.single.barHeight, closeTo(fortuneMillimetersToLogicalPixels(7), 0.001));
    final barcode = _painter(tester).workbook.activeSheet.images.single;
    expect(barcode.extraFields['barcodeBarHeight'], 7);
    expect(_inkHeight(barcode), fortuneMillimetersToLogicalPixels(7).round());
  });

  testWidgets('explicit bar height and human readable text survive save reload', (
    tester,
  ) async {
    final requests = <FortuneBarcodeRequest>[];
    await _pumpCanvas(tester, requests);
    await _openDialog(tester);
    await _tapDialog(tester, fortuneBarcodeLinkButtonRect);
    await _enter(tester, 'width', '20');
    await _enter(tester, 'height', '20');
    await _enter(tester, 'bar-height', '7');
    await _tapDialog(tester, fortuneBarcodeShowTextCheckboxRect);
    await _confirm(tester);
    expect(requests.single.showHumanReadableText, isTrue);
    expect(requests.single.barHeight, closeTo(fortuneMillimetersToLogicalPixels(7), 0.001));
    final payload = labelSheetBuildSavePayload(_painter(tester).workbook);
    final saved = labelSheetDecodeWorkbookSave(payload.encodedWorkbook);
    final barcode = saved.activeSheet.images.single;
    expect(barcode.extraFields['barcodeBarHeight'], 7);
    expect(barcode.extraFields['barcodeShowText'], isTrue);
    expect(barcode.extraFields['heightMm'], 20);
    expect(barcode.extraFields[fortuneBarcodeBodyHeightExtraKey],
        fortuneMillimetersToLogicalPixels(7).round());
    expect(barcode.extraFields[fortuneBarcodeBodyRatioExtraKey], lessThan(1));
    expect(image.decodePng(base64Decode(barcode.src.split(',').last))!.height,
        fortuneMillimetersToLogicalPixels(20).round());
  });

  testWidgets('QR dimensions preserve module scale without a bar height input', (
    tester,
  ) async {
    final requests = <FortuneBarcodeRequest>[];
    await _pumpCanvas(tester, requests, format: 'qrCode');
    await _openDialog(tester);
    await _enter(tester, 'width', '20');
    await _enter(tester, 'height', '30');
    expect(_input('bar-height'), findsNothing);
    expect(tester.widget<EditableText>(_input('width')).controller.text, '30');
    expect(tester.widget<EditableText>(_input('module-scale')).controller.text, '3');
    await _confirm(tester);
    final request = requests.single;
    expect(request.width, closeTo(fortuneMillimetersToLogicalPixels(30), 0.001));
    expect(request.height, request.width);
    expect(request.moduleScale, 3);
    expect(request.barHeight, closeTo(fortuneMillimetersToLogicalPixels(10), 0.001));
  });
}
