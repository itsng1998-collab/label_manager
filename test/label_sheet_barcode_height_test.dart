import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:image/image.dart' as image;
import 'package:label_manager/features/label_sheet/application/label_sheet_barcode_renderer.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';

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
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = FortuneSheetController();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: FortuneSheetCanvas(
        controller: controller,
        workbook: FortuneWorkbook(
          settings: const FortuneSettings(
            toolbarItems: [fortuneToolbarBarcodeCommand],
          ),
          sheets: [
            FortuneSheet(
              id: 'label',
              name: 'Label',
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
          return _renderBarcode(request);
        },
      ),
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

void main() {
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
