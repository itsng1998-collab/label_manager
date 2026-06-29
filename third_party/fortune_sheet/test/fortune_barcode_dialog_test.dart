import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show
        AdaptiveTextSelectionToolbar,
        DesktopTextSelectionToolbarButton,
        MaterialApp,
        ThemeData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

final Uint8List _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
);

Offset toolbarItemCenter(
  String key, {
  double width = 1200,
  List<String> items = fortuneToolbarItems,
}) {
  for (final entry in fortuneVisibleToolbarItemRects(width, items: items)) {
    if (entry.key == key) {
      return entry.value.center;
    }
  }
  fail('toolbar item not found: $key');
}

void main() {
  test('barcode show-text option is centered between quiet-zone inputs', () {
    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    final leading = fortuneBarcodeLeadingQuietZoneInputRect(dialogRect);
    final trailing = fortuneBarcodeTrailingQuietZoneInputRect(dialogRect);
    final fontCombo = fortuneBarcodeTextFontComboRect(dialogRect);
    final fontSizeCombo = fortuneBarcodeTextFontSizeComboRect(dialogRect);
    final checkbox = fortuneBarcodeShowTextCheckboxRect(dialogRect);
    final label = fortuneBarcodeShowTextLabelRect(dialogRect);
    final optionGroup = Rect.fromLTRB(
      checkbox.left,
      checkbox.top,
      label.right,
      checkbox.bottom,
    );

    expect(trailing.top, leading.top);
    expect(fontCombo.bottom, lessThan(leading.top));
    expect(fontSizeCombo.bottom, lessThan(trailing.top));
    expect(fontSizeCombo.overlaps(trailing), isFalse);
    expect(checkbox.right, lessThan(label.left));
    expect(label.right, lessThan(trailing.left));
    expect(optionGroup.left, greaterThan(leading.right));
    expect(
      optionGroup.center.dx,
      closeTo((leading.right + trailing.left) / 2, 0.001),
    );
  });

  test('barcode text font menu uses toolbar font popup width', () {
    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    const labels = [
      'D2Coding',
      'Noto Sans KR',
      'Noto Serif KR',
      'NanumGothicCoding',
    ];
    final menu = fortuneBarcodeTextFontMenuRect(
      dialogRect,
      labels.length,
      labels: labels,
    );

    expect(menu.width, fortuneToolbarFontPopupWidthForLabels(labels));
    expect(menu.width, greaterThan(fortuneBarcodeDialogTextFontWidth));
  });

  testWidgets('barcode insert dialog defaults format menu to Code128', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarBarcodeCommand],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );
    final formats = [
      for (var index = 0; index < 10; index += 1)
        FortuneBarcodeFormatOption(id: 'fmt$index', label: 'Format $index'),
      const FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
      const FortuneBarcodeFormatOption(id: 'qrCode', label: 'QR Code'),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: formats,
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft +
          toolbarItemCenter(
            fortuneToolbarBarcodeCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeFormatLabel, 'Code128');

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeFormatComboRect(dialogRect).center,
    );
    await tester.pump();

    expect(painter().barcodeFormatMenuOpen, isTrue);
    expect(painter().barcodeFormatMenuSelectedIndex, 10);
    expect(painter().barcodeFormatMenuScrollOffset, greaterThan(0));
  });

  testWidgets('barcode insert button follows text value presence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var renderCount = 0;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarBarcodeCommand],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 900,
                height: 700,
                child: FortuneSheetCanvas(
                  workbook: workbook,
                  barcodeFormats: const [
                    FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
                  ],
                  barcodeRenderer: (request) async {
                    renderCount += 1;
                    return FortuneBarcodeRenderResult(
                      bytes: _transparentPng,
                      pixelWidth: 120,
                      pixelHeight: 60,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft +
          toolbarItemCenter(
            fortuneToolbarBarcodeCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeCanConfirm, isFalse);

    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pump();

    expect(renderCount, 0);
    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeCanConfirm, isFalse);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-text-input')),
        matching: find.byType(EditableText),
      ),
      '12345',
    );
    await tester.pump();

    expect(painter().barcodeCanConfirm, isTrue);

    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    expect(renderCount, 1);
    expect(painter().barcodeDialogOpen, isFalse);
  });

  testWidgets('barcode dialog forwards leading and trailing text values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneBarcodeRequest? capturedRequest;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarBarcodeCommand],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 900,
                height: 700,
                child: FortuneSheetCanvas(
                  workbook: workbook,
                  barcodeFormats: const [
                    FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
                  ],
                  barcodeRenderer: (request) async {
                    capturedRequest = request;
                    return FortuneBarcodeRenderResult(
                      bytes: _transparentPng,
                      pixelWidth: 120,
                      pixelHeight: 60,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    EditableText editableTextIn(String key) {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ),
      );
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft +
          toolbarItemCenter(
            fortuneToolbarBarcodeCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    expect(
      editableTextIn(
        'fortune-barcode-leading-quiet-zone-input',
      ).controller.text,
      isEmpty,
    );
    expect(
      editableTextIn(
        'fortune-barcode-trailing-quiet-zone-input',
      ).controller.text,
      isEmpty,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-text-input')),
        matching: find.byType(EditableText),
      ),
      '12345',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(
          const ValueKey('fortune-barcode-leading-quiet-zone-input'),
        ),
        matching: find.byType(EditableText),
      ),
      'PRE-',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(
          const ValueKey('fortune-barcode-trailing-quiet-zone-input'),
        ),
        matching: find.byType(EditableText),
      ),
      '-END',
    );
    await tester.pump();

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pump();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.leadingText, 'PRE-');
    expect(capturedRequest!.trailingText, '-END');
  });

  testWidgets('barcode dialog applies human-readable text font settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneBarcodeRequest? capturedRequest;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarBarcodeCommand],
        fontFamilies: ['Arial', 'D2Coding', 'Noto Sans KR'],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 900,
                height: 700,
                child: FortuneSheetCanvas(
                  workbook: workbook,
                  barcodeFormats: const [
                    FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
                  ],
                  barcodeRenderer: (request) async {
                    capturedRequest = request;
                    return FortuneBarcodeRenderResult(
                      bytes: _transparentPng,
                      pixelWidth: 120,
                      pixelHeight: 60,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft +
          toolbarItemCenter(
            fortuneToolbarBarcodeCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    expect(painter().barcodeTextFontFamilyOptions, [
      'Arial',
      'D2Coding',
      'Noto Sans KR',
    ]);
    expect(painter().barcodeTextFontFamilyLabel, 'Arial');
    expect(painter().barcodeTextFontSizeLabel, '14');

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeTextFontComboRect(dialogRect).center,
    );
    await tester.pump();
    expect(painter().barcodeTextFontMenuOpen, isTrue);
    await tester.tapAt(
      topLeft +
          fortuneBarcodeTextFontMenuRect(dialogRect, 3).topLeft +
          const Offset(8, fortuneContextMenuRowHeight * 1.5),
    );
    await tester.pump();
    expect(painter().barcodeTextFontFamilyLabel, 'D2Coding');

    await tester.tapAt(
      topLeft + fortuneBarcodeTextFontSizeComboRect(dialogRect).center,
    );
    await tester.pump();
    expect(painter().barcodeTextFontSizeMenuOpen, isTrue);
    await tester.tapAt(
      topLeft +
          fortuneBarcodeTextFontSizeMenuRect(
            dialogRect,
            fortuneToolbarFontSizeCommands.length,
          ).topLeft +
          const Offset(8, fortuneContextMenuRowHeight * 5.5),
    );
    await tester.pump();
    expect(painter().barcodeTextFontSizeLabel, '18');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-text-input')),
        matching: find.byType(EditableText),
      ),
      '1234567890',
    );
    await tester.pump();
    await tester.tapAt(
      topLeft + fortuneBarcodeShowTextCheckboxRect(dialogRect).center,
    );
    await tester.pump();
    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.showHumanReadableText, isTrue);
    expect(capturedRequest!.humanReadableFontFamily, 'D2Coding');
    expect(capturedRequest!.humanReadableFontSize, 18);
    final image = painter().workbook.activeSheet.images.single;
    expect(image.extraFields['barcodeHumanReadableFontFamily'], 'D2Coding');
    expect(image.extraFields['barcodeHumanReadableFontSize'], 18);
  });

  testWidgets('barcode edit preserves format when only other values change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneBarcodeRequest? capturedRequest;
    const barcodeImage = FortuneImage(
      id: 'barcode-1',
      src:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
      left: 20,
      top: 20,
      width: 120,
      height: 60,
      extraFields: {
        'fortuneBarcode': true,
        'barcodeText': '12345',
        'barcodeFormatId': 'code128',
        'barcodeFormatLabel': 'Code128',
        'barcodeModuleScale': 3,
        'barcodeBarHeight': 10,
      },
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', images: const [barcodeImage]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(id: 'qrCode', label: 'QR Code'),
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
            barcodeRenderer: (request) async {
              capturedRequest = request;
              return FortuneBarcodeRenderResult(
                bytes: _transparentPng,
                pixelWidth: 120,
                pixelHeight: 80,
              );
            },
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final imageCenter =
        topLeft +
        Offset(
          settings.rowHeaderWidth + barcodeImage.left + barcodeImage.width / 2,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              barcodeImage.top +
              barcodeImage.height / 2,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.sendEventToBinding(PointerUpEvent(position: imageCenter));
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeFormatLabel, 'Code128');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-height-input')),
        matching: find.byType(EditableText),
      ),
      '80',
    );
    await tester.pump();

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: true,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.formatId, 'code128');
    final updated = painter().workbook.activeSheet.images.single;
    expect(updated.extraFields['barcodeFormatId'], 'code128');
    expect(updated.extraFields['barcodeFormatLabel'], 'Code128');
    expect(updated.height, 80);
  });

  testWidgets('barcode edit keeps existing size when only text font changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneBarcodeRequest? capturedRequest;
    const barcodeImage = FortuneImage(
      id: 'barcode-1',
      src:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
      left: 20,
      top: 20,
      width: 300,
      height: 52,
      extraFields: {
        'fortuneBarcode': true,
        'barcodeText': '1234567890',
        'barcodeFormatId': 'code128',
        'barcodeFormatLabel': 'Code128',
        'barcodeModuleScale': 3,
        'barcodeBarHeight': 10,
        'barcodeLeadingText': 'aa',
        'barcodeTrailingText': 'bb',
        'barcodeShowText': true,
        'barcodeHumanReadableFontFamily': 'D2Coding',
        'barcodeHumanReadableFontSize': 14,
      },
    );
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        fontFamilies: ['D2Coding', 'Noto Sans KR'],
      ),
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', images: const [barcodeImage]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(
                id: 'code128',
                label: 'Code128',
                ratio: 2,
              ),
            ],
            barcodeRenderer: (request) async {
              capturedRequest = request;
              return FortuneBarcodeRenderResult(
                bytes: _transparentPng,
                pixelWidth: request.width.round(),
                pixelHeight: request.height.round(),
              );
            },
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    EditableText editableText(String key) {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ),
      );
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final imageCenter =
        topLeft +
        Offset(
          settings.rowHeaderWidth + barcodeImage.left + barcodeImage.width / 2,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              barcodeImage.top +
              barcodeImage.height / 2,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.sendEventToBinding(PointerUpEvent(position: imageCenter));
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(editableText('fortune-barcode-width-input').controller.text, '300');
    expect(editableText('fortune-barcode-height-input').controller.text, '52');

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: true,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeTextFontComboRect(dialogRect).center,
    );
    await tester.pump();
    await tester.tapAt(
      topLeft +
          fortuneBarcodeTextFontMenuRect(
            dialogRect,
            2,
            labels: const ['D2Coding', 'Noto Sans KR'],
          ).topLeft +
          const Offset(8, fortuneContextMenuRowHeight * 1.5),
    );
    await tester.pump();
    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.width, 300);
    expect(capturedRequest!.height, 52);
    expect(capturedRequest!.humanReadableFontFamily, 'Noto Sans KR');
    final updated = painter().workbook.activeSheet.images.single;
    expect(updated.width, 300);
    expect(updated.height, 52);
    expect(
      updated.extraFields['barcodeHumanReadableFontFamily'],
      'Noto Sans KR',
    );
  });

  testWidgets('barcode edit defaults missing metadata to Code128', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneBarcodeRequest? capturedRequest;
    const barcodeImage = FortuneImage(
      id: 'barcode-1',
      src:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
      left: 20,
      top: 20,
      width: 120,
      height: 60,
      extraFields: {
        'fortuneBarcode': true,
        'barcodeText': 'aa1234567890bb',
        'barcodeModuleScale': 3,
        'barcodeBarHeight': 10,
      },
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', images: const [barcodeImage]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(id: 'qrCode', label: 'QR Code'),
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
            barcodeRenderer: (request) async {
              capturedRequest = request;
              return FortuneBarcodeRenderResult(
                bytes: _transparentPng,
                pixelWidth: 120,
                pixelHeight: 80,
              );
            },
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final imageCenter =
        topLeft +
        Offset(
          settings.rowHeaderWidth + barcodeImage.left + barcodeImage.width / 2,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              barcodeImage.top +
              barcodeImage.height / 2,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.sendEventToBinding(PointerUpEvent(position: imageCenter));
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeFormatLabel, 'Code128');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-bar-height-input')),
        matching: find.byType(EditableText),
      ),
      '14',
    );
    await tester.pump();

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: true,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.formatId, 'code128');
    expect(capturedRequest!.barHeight, 14);
    final updated = painter().workbook.activeSheet.images.single;
    expect(updated.extraFields['barcodeFormatId'], 'code128');
    expect(updated.extraFields['barcodeFormatLabel'], 'Code128');
    expect(updated.extraFields['barcodeBarHeight'], 14);
  });

  testWidgets('barcode dialog inputs support standard edit shortcuts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var clipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboardText = (call.arguments as Map)['text'] as String;
            return null;
          case 'Clipboard.getData':
            return <String, Object?>{'text': clipboardText};
        }
        return null;
      },
    );
    addTearDown(() {
      ContextMenuController.removeAny();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarBarcodeCommand],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 900,
                height: 700,
                child: FortuneSheetCanvas(
                  workbook: workbook,
                  locale: FortuneSheetLocale.korean,
                  barcodeFormats: const [
                    FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
                  ],
                  barcodeRenderer: (_) async => FortuneBarcodeRenderResult(
                    bytes: _transparentPng,
                    pixelWidth: 120,
                    pixelHeight: 60,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft +
          toolbarItemCenter(
            fortuneToolbarBarcodeCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    final editableTexts = tester.widgetList<EditableText>(
      find.descendant(
        of: find.byType(FortuneSheetCanvas),
        matching: find.byType(EditableText),
      ),
    );
    expect(editableTexts, hasLength(8));
    for (final editableText in editableTexts) {
      expect(editableText.selectionControls, isNotNull);
      expect(editableText.contextMenuBuilder, isNotNull);
    }

    final textInput = find.descendant(
      of: find.byKey(const ValueKey('fortune-barcode-text-input')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(textInput, '12345');
    await tester.pump();

    final textEditableBeforeCopy = tester.widget<EditableText>(textInput);
    expect(textEditableBeforeCopy.focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA, platform: 'windows');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA, platform: 'windows');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC, platform: 'windows');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC, platform: 'windows');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX, platform: 'windows');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX, platform: 'windows');
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.pump();

    expect(clipboardText, '12345');
    expect(tester.widget<EditableText>(textInput).controller.text, isEmpty);

    clipboardText = '67890';
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyV, platform: 'windows');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyV, platform: 'windows');
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.controlLeft,
      platform: 'windows',
    );
    await tester.pump();

    final textEditable = tester.widget<EditableText>(textInput);
    expect(textEditable.controller.text, '67890');
    DesktopTextSelectionToolbarButton toolbarButton(String label) {
      return tester.widget<DesktopTextSelectionToolbarButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(DesktopTextSelectionToolbarButton),
        ),
      );
    }

    textEditable.controller.selection = const TextSelection.collapsed(
      offset: 1,
    );
    final textRect = tester.getRect(textInput);
    final collapsedGesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await collapsedGesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    expect(find.text('잘라내기'), findsOneWidget);
    final disabledCutButton = toolbarButton('잘라내기');
    expect(disabledCutButton.onPressed, isNull);

    ContextMenuController.removeAny();

    textEditable.controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    final gesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(textEditable.focusNode.hasFocus, isTrue);
    expect(textEditable.controller.selection.textInside('67890'), '67890');
    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    expect(find.text('잘라내기'), findsOneWidget);
    expect(find.text('복사'), findsOneWidget);
    expect(find.text('붙여넣기'), findsOneWidget);
    expect(find.text('전체 선택'), findsOneWidget);

    final trailingInput = find.byKey(
      const ValueKey('fortune-barcode-trailing-quiet-zone-input'),
    );
    await tester.tapAt(tester.getCenter(trailingInput));
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

    textEditable.controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    clipboardText = '';
    final reopenGesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await reopenGesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

    expect(toolbarButton('붙여넣기').onPressed, isNull);
    await tester.pump();
    expect(tester.widget<EditableText>(textInput).controller.text, '67890');

    ContextMenuController.removeAny();
    textEditable.controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    final copyGesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await copyGesture.up();
    await tester.pumpAndSettle();

    toolbarButton('복사').onPressed!();
    await tester.pump();
    expect(clipboardText, '67890');
    expect(tester.widget<EditableText>(textInput).controller.text, '67890');

    textEditable.controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 5,
    );
    final cutGesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cutGesture.up();
    await tester.pumpAndSettle();

    toolbarButton('잘라내기').onPressed!();
    await tester.pump();
    expect(clipboardText, '67890');
    expect(tester.widget<EditableText>(textInput).controller.text, isEmpty);

    clipboardText = 'PASTE';
    final pasteGesture = await tester.startGesture(
      textRect.center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await pasteGesture.up();
    await tester.pumpAndSettle();

    toolbarButton('붙여넣기').onPressed!();
    await tester.pump();
    expect(tester.widget<EditableText>(textInput).controller.text, 'PASTE');
  });
}
