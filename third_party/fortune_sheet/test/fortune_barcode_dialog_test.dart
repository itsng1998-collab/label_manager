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

const List<String> _imageObjectContextMenuItems = [
  fortuneContextEditImageCommand,
  fortuneContextDuplicateImageCommand,
  fortuneContextDeleteImageCommand,
  '|',
  fortuneContextBringForwardCommand,
  fortuneContextSendBackwardCommand,
  fortuneContextBringToFrontCommand,
  fortuneContextSendToBackCommand,
];

const List<String> _barcodeObjectContextMenuItems = [
  fortuneContextEditBarcodeCommand,
  fortuneContextDuplicateImageCommand,
  fortuneContextDeleteImageCommand,
  '|',
  fortuneContextBringForwardCommand,
  fortuneContextSendBackwardCommand,
  fortuneContextBringToFrontCommand,
  fortuneContextSendToBackCommand,
];

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

Future<void> activateOpenContextMenuItem(
  WidgetTester tester,
  Offset canvasTopLeft,
  FortuneSheetPainter painter, {
  String? command,
}) async {
  expect(painter.contextMenuAt, isNotNull);
  final targetCommand = command ??
      painter.contextMenuItems.firstWhere((item) => item != '|');
  final itemRect = fortuneContextMenuItemRect(
    painter.contextMenuAt!,
    targetCommand,
    painter.contextMenuItems,
  );
  expect(itemRect, isNotNull);
  await tester.tapAt(
    canvasTopLeft + itemRect!.center,
  );
  await tester.pump();
}

void main() {
  test('image layer panel type labels distinguish images and barcodes', () {
    const image = FortuneImage(
      id: 'image-id',
      src: 'data:image/png;base64,empty',
      left: 0,
      top: 0,
      width: 10,
      height: 10,
      extraFields: {fortuneImageObjectIdExtraKey: '#IMAGE7'},
    );
    const barcode = FortuneImage(
      id: 'barcode-id',
      src: 'data:image/png;base64,empty',
      left: 0,
      top: 0,
      width: 10,
      height: 10,
      extraFields: {
        'fortuneBarcode': true,
        fortuneBarcodeObjectIdExtraKey: '#BARCODE2',
      },
    );
    const fallback = FortuneImage(
      id: 'fallback-id',
      src: 'data:image/png;base64,empty',
      left: 0,
      top: 0,
      width: 10,
      height: 10,
    );

    expect(fortuneImageLayerPanelTypeLabel(image), 'IMG');
    expect(fortuneImageLayerPanelTypeLabel(barcode), 'BAR');
    expect(fortuneImageLayerPanelLabel(image), '#IMAGE7');
    expect(fortuneImageLayerPanelLabel(barcode), '#BARCODE2');
    expect(fortuneImageLayerPanelLabel(fallback), 'fallback-id');
  });

  test('image layer panel type and label rects do not overlap', () {
    const row = Rect.fromLTWH(100, 200, 220, fortuneImageLayerPanelRowHeight);
    final type = fortuneImageLayerPanelTypeRect(row);
    final label = fortuneImageLayerPanelLabelRect(row);

    expect(type.left, greaterThanOrEqualTo(row.left));
    expect(type.right, lessThanOrEqualTo(row.right));
    expect(type.top, greaterThanOrEqualTo(row.top));
    expect(type.bottom, lessThanOrEqualTo(row.bottom));
    expect(label.left, greaterThanOrEqualTo(row.left));
    expect(label.right, lessThanOrEqualTo(row.right));
    expect(label.top, greaterThanOrEqualTo(row.top));
    expect(label.bottom, lessThanOrEqualTo(row.bottom));
    expect(type.right + fortuneImageLayerPanelTypeGap, label.left);
  });

  test('image layer panel action helpers expose shortcuts and boundaries', () {
    const images = [
      FortuneImage(
        id: 'back',
        src: 'data:image/png;base64,empty',
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        extraFields: {fortuneSheetObjectZOrderExtraKey: 1},
      ),
      FortuneImage(
        id: 'front',
        src: 'data:image/png;base64,empty',
        left: 0,
        top: 0,
        width: 10,
        height: 10,
        extraFields: {fortuneSheetObjectZOrderExtraKey: 2},
      ),
    ];

    expect(fortuneImageLayerPanelActionGlyph(fortuneContextDuplicateImageCommand), '⧉');
    expect(
      fortuneImageLayerPanelActionTooltip(fortuneContextDuplicateImageCommand),
      contains('Ctrl+D'),
    );
    expect(
      fortuneImageLayerPanelActionTooltip(fortuneContextBringToFrontCommand),
      contains('Ctrl+Home'),
    );
    expect(
      fortuneImageLayerPanelActionEnabled(
        images,
        'front',
        fortuneContextBringToFrontCommand,
      ),
      isFalse,
    );
    expect(
      fortuneImageLayerPanelActionEnabled(
        images,
        'front',
        fortuneContextSendBackwardCommand,
      ),
      isTrue,
    );
    expect(
      fortuneImageLayerPanelActionEnabled(
        images,
        'back',
        fortuneContextSendToBackCommand,
      ),
      isFalse,
    );
    expect(
      fortuneImageLayerPanelActionEnabled(
        images,
        'back',
        fortuneContextBringForwardCommand,
      ),
      isTrue,
    );
    expect(
      fortuneActiveImageToolbarItemEnabled(
        images,
        'front',
        fortuneContextBringToFrontCommand,
      ),
      isFalse,
    );
    expect(
      fortuneActiveImageToolbarItemEnabled(
        images,
        'front',
        fortuneContextToggleLayerPanelCommand,
      ),
      isTrue,
    );
  });

  test('barcode show-text option is centered between quiet-zone inputs', () {
    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    final objectId = fortuneBarcodeObjectIdInputRect(dialogRect);
    final format = fortuneBarcodeFormatComboRect(dialogRect);
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

    expect(objectId.bottom, lessThan(format.top));
    expect(format.bottom, lessThan(fontCombo.top));
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

  testWidgets('image insert dialog defaults object id from last image index', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(toolbarItems: [fortuneToolbarImageCommand]),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'img1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 10,
              height: 10,
              extraFields: const {fortuneImageObjectIdExtraKey: '#IMAGE3'},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
            fortuneToolbarImageCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    expect(painter().imageInsertDialogOpen, isTrue);
    expect(painter().imageObjectId, '#IMAGE4');
    expect(painter().imageObjectIdOptions, containsAll(['#IMAGE3', '#IMAGE4']));

    final dialogRect = fortuneImageInsertDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneImageObjectIdInputRect(dialogRect).centerRight - const Offset(12, 0),
    );
    await tester.pump();

    expect(painter().imageObjectIdMenuOpen, isTrue);
  });

  testWidgets('image insert stores next zOrder metadata', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(toolbarItems: [fortuneToolbarImageCommand]),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'img1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 10,
              height: 10,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 4},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            imagePicker: () async => FortuneImagePickResult(
              bytes: _transparentPng,
              fileName: 'picked.png',
              mimeType: 'image/png',
              width: 20,
              height: 20,
            ),
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
            fortuneToolbarImageCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    final dialogRect = fortuneImageInsertDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(topLeft + fortuneImageInsertFileButtonRect(dialogRect).center);
    await tester.pump();
    await tester.tapAt(topLeft + fortuneImageInsertConfirmButtonRect(dialogRect).center);
    await tester.pump();

    final images = painter().workbook.activeSheet.images;
    expect(images, hasLength(2));
    expect(images.last.extraFields[fortuneSheetObjectZOrderExtraKey], 5);
  });

  testWidgets('image right click opens edit context menu before dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'img1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageCenter = topLeft +
        Offset(
          settings.rowHeaderWidth + 25,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              25,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(painter().imageInsertDialogOpen, isFalse);
    expect(painter().contextMenuAt, isNotNull);
    expect(painter().contextMenuItems, _imageObjectContextMenuItems);

    await activateOpenContextMenuItem(
      tester,
      topLeft,
      painter(),
      command: fortuneContextEditImageCommand,
    );

    expect(painter().imageInsertDialogOpen, isTrue);
    expect(painter().imageInsertEditing, isTrue);
  });

  testWidgets('image right click uses zOrder before list order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageCenter = topLeft +
        Offset(
          settings.rowHeaderWidth + 25,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              25,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    await tester.sendEventToBinding(
      PointerUpEvent(position: imageCenter, kind: PointerDeviceKind.mouse),
    );
    await tester.pump();

    expect(painter().activeImageId, 'front');
    expect(painter().contextMenuItems, _imageObjectContextMenuItems);

    await activateOpenContextMenuItem(
      tester,
      topLeft,
      painter(),
      command: fortuneContextSendToBackCommand,
    );

    var imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );

    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    await tester.sendEventToBinding(
      PointerUpEvent(position: imageCenter, kind: PointerDeviceKind.mouse),
    );
    await tester.pump();

    expect(painter().activeImageId, 'back');
    await activateOpenContextMenuItem(
      tester,
      topLeft,
      painter(),
      command: fortuneContextBringToFrontCommand,
    );

    imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );
  });

  testWidgets('image context menu disables boundary movement commands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 2},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageCenter = topLeft +
        Offset(
          settings.rowHeaderWidth + 25,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              25,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: imageCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(painter().contextMenuAt, isNotNull);
    expect(
      painter().contextMenuDisabledItems,
      containsAll(<String>[
        fortuneContextBringForwardCommand,
        fortuneContextBringToFrontCommand,
      ]),
    );
    expect(
      painter().contextMenuDisabledItems,
      isNot(contains(fortuneContextSendToBackCommand)),
    );

    final disabledRect = fortuneContextMenuItemRect(
      painter().contextMenuAt!,
      fortuneContextBringToFrontCommand,
      painter().contextMenuItems,
    );
    expect(disabledRect, isNotNull);

    await tester.tapAt(topLeft + disabledRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(painter().contextMenuAt, isNotNull);
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1,
    );
  });

  testWidgets('image floating toolbar changes zOrder', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    expect(painter().activeImageId, 'front');

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(frontImage);
    final sendToBackRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextSendToBackCommand,
      toolbarItems,
    );
    expect(sendToBackRect, isNotNull);

    await tester.tapAt(topLeft + sendToBackRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );
  });

  testWidgets('image floating toolbar disabled action and hover tooltip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 2},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'front');

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(frontImage);
    final duplicateRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextDuplicateImageCommand,
      toolbarItems,
    );
    expect(duplicateRect, isNotNull);

    final duplicateCenter = topLeft + duplicateRect!.center;
    await tester.sendEventToBinding(PointerHoverEvent(position: duplicateCenter));
    await tester.pump();

    expect(
      painter().activeImageToolbarHoveredCommand,
      fortuneContextDuplicateImageCommand,
    );
    expect(painter().activeImageToolbarTooltipPosition, duplicateCenter - topLeft);

    await tester.sendEventToBinding(
      PointerHoverEvent(position: topLeft + const Offset(20, 20)),
    );
    await tester.pump();
    expect(painter().activeImageToolbarHoveredCommand, isNull);
    expect(painter().activeImageToolbarTooltipPosition, isNull);

    final bringToFrontRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextBringToFrontCommand,
      toolbarItems,
    );
    expect(bringToFrontRect, isNotNull);

    await tester.tapAt(topLeft + bringToFrontRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(painter().activeImageId, 'front');
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1,
    );
  });

  testWidgets('image floating toolbar opens layer panel and selects item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    expect(painter().activeImageId, 'front');

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(frontImage);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    expect(painter().imageLayerPanelOpen, isTrue);
    expect(
      fortuneImageLayerPanelItems(
        painter().workbook.activeSheet.images,
      ).map((image) => image.id),
      ['front', 'back'],
    );

    final backRowRect = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      2,
      1,
      top: settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          fortuneImageLayerPanelMargin,
    );
    expect(backRowRect, isNotNull);

    await tester.tapAt(topLeft + backRowRect!.center);
    await tester.pump();

    expect(painter().activeImageId, 'back');
  });

  testWidgets('image layer panel action moves selected item forward', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(frontImage);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final backRowRect = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      2,
      1,
      top: layerPanelTop,
    );
    expect(backRowRect, isNotNull);

    await tester.tapAt(topLeft + backRowRect!.center);
    await tester.pump();
    expect(painter().activeImageId, 'back');

    final moveForwardRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      2,
      fortuneContextBringForwardCommand,
      top: layerPanelTop,
    );
    expect(moveForwardRect, isNotNull);

    await tester.tapAt(topLeft + moveForwardRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(painter().activeImageId, 'back');
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
  });

  testWidgets('image layer panel action sends selected item to back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'front');

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(frontImage);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final sendToBackRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      2,
      fortuneContextSendToBackCommand,
      top: layerPanelTop,
    );
    expect(sendToBackRect, isNotNull);

    await tester.tapAt(topLeft + sendToBackRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(painter().activeImageId, 'front');
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );
  });

  testWidgets('image layer panel disabled movement action keeps order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 2},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'front');

    final frontImage = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'front',
    );
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(frontImage),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final bringToFrontRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      2,
      fortuneContextBringToFrontCommand,
      top: layerPanelTop,
    );
    expect(bringToFrontRect, isNotNull);

    await tester.tapAt(topLeft + bringToFrontRect!.center);
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    expect(painter().activeImageId, 'front');
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(
      imagesById['front']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2,
    );
    expect(
      imagesById['back']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1,
    );
  });

  testWidgets('image layer panel action hover exposes tooltip state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'image1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final image = painter().workbook.activeSheet.images.single;
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(image),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final duplicateRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      1,
      fortuneContextDuplicateImageCommand,
      top: layerPanelTop,
    );
    expect(duplicateRect, isNotNull);

    final duplicateCenter = topLeft + duplicateRect!.center;
    await tester.sendEventToBinding(
      PointerHoverEvent(position: duplicateCenter),
    );
    await tester.pump();

    expect(
      painter().imageLayerPanelHoveredActionCommand,
      fortuneContextDuplicateImageCommand,
    );
    expect(painter().imageLayerPanelTooltipPosition, duplicateCenter - topLeft);

    await tester.sendEventToBinding(
      PointerHoverEvent(position: topLeft + const Offset(20, 20)),
    );
    await tester.pump();

    expect(painter().imageLayerPanelHoveredActionCommand, isNull);
    expect(painter().imageLayerPanelTooltipPosition, isNull);
  });

  testWidgets('image layer panel scroll selects lower item', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index.toDouble(),
                top: index.toDouble(),
                width: 50,
                height: 50,
                extraFields: {fortuneSheetObjectZOrderExtraKey: index},
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth + 10,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          10,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    expect(painter().activeImageId, 'image10');

    final image = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'image10',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(image);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final panel = fortuneImageLayerPanelRect(
      const Size(900, 700),
      10,
      top: layerPanelTop,
    );
    final initialThumb = fortuneImageLayerPanelScrollbarThumbRect(
      const Size(900, 700),
      10,
      0,
      top: layerPanelTop,
    );
    expect(initialThumb, isNotNull);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: topLeft + panel.center,
        scrollDelta: Offset(0, fortuneImageLayerPanelRowHeight * 2),
      ),
    );
    await tester.pump();

    expect(
      painter().imageLayerPanelScrollOffset,
      fortuneImageLayerPanelRowHeight * 2,
    );
    final scrolledThumb = fortuneImageLayerPanelScrollbarThumbRect(
      const Size(900, 700),
      10,
      fortuneImageLayerPanelRowHeight * 2,
      top: layerPanelTop,
    );
    expect(scrolledThumb, isNotNull);
    expect(scrolledThumb!.top, greaterThan(initialThumb!.top));

    final image1RowRect = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      10,
      9,
      top: layerPanelTop,
      scrollOffset: fortuneImageLayerPanelRowHeight * 2,
    );
    expect(image1RowRect, isNotNull);

    await tester.tapAt(topLeft + image1RowRect!.center);
    await tester.pump();

    expect(painter().activeImageId, 'image1');
  });

  testWidgets('image layer panel scrollbar thumb drags scroll offset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index.toDouble(),
                top: index.toDouble(),
                width: 50,
                height: 50,
                extraFields: {fortuneSheetObjectZOrderExtraKey: index},
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth + 10,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          10,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final image = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'image10',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(image);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final thumb = fortuneImageLayerPanelScrollbarThumbRect(
      const Size(900, 700),
      10,
      0,
      top: layerPanelTop,
    );
    expect(thumb, isNotNull);

    final gesture = await tester.startGesture(topLeft + thumb!.center);
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(painter().imageLayerPanelOpen, isTrue);
    expect(painter().imageLayerPanelScrollOffset, greaterThan(0));
  });

  testWidgets('image layer panel row drag reorders layers', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index.toDouble(),
                top: index.toDouble(),
                width: 50,
                height: 50,
                extraFields: {fortuneSheetObjectZOrderExtraKey: index},
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth + 10,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          10,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'image10');

    final image = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'image10',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(image);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final sourceRow = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      10,
      0,
      top: layerPanelTop,
    );
    final targetRow = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      10,
      2,
      top: layerPanelTop,
    );
    expect(sourceRow, isNotNull);
    expect(targetRow, isNotNull);

    final gesture = await tester.startGesture(topLeft + sourceRow!.center);
    await gesture.moveTo(topLeft + targetRow!.center);
    await tester.pump();

    expect(painter().imageLayerPanelDraggingImageId, 'image10');
    expect(painter().imageLayerPanelDragTargetIndex, 2);

    await gesture.up();
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    final panelItems = fortuneImageLayerPanelItems(
      painter().workbook.activeSheet.images,
    );
    expect(painter().activeImageId, 'image10');
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(painter().imageLayerPanelDraggingImageId, isNull);
    expect(painter().imageLayerPanelDragTargetIndex, isNull);
    expect(panelItems.take(3).map((image) => image.id), [
      'image9',
      'image8',
      'image10',
    ]);
    expect(
      imagesById['image10']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      8.0,
    );
    expect(
      imagesById['image8']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      9.0,
    );
    expect(
      imagesById['image9']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      10.0,
    );
  });

  testWidgets('image layer panel row drag auto scrolls to lower rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index.toDouble(),
                top: index.toDouble(),
                width: 50,
                height: 50,
                extraFields: {fortuneSheetObjectZOrderExtraKey: index},
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth + 10,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          10,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'image10');

    final image = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'image10',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(image);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final panel = fortuneImageLayerPanelRect(
      const Size(900, 700),
      10,
      top: layerPanelTop,
    );
    final sourceRow = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      10,
      0,
      top: layerPanelTop,
    );
    expect(sourceRow, isNotNull);

    final bottomEdge = Offset(panel.center.dx, panel.bottom - 2);
    final gesture = await tester.startGesture(topLeft + sourceRow!.center);
    await gesture.moveTo(topLeft + bottomEdge);
    await tester.pump();
    await gesture.moveTo(topLeft + bottomEdge.translate(0, -1));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final imagesById = {
      for (final image in painter().workbook.activeSheet.images) image.id: image,
    };
    final panelItems = fortuneImageLayerPanelItems(
      painter().workbook.activeSheet.images,
    );
    expect(painter().activeImageId, 'image10');
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(
      painter().imageLayerPanelScrollOffset,
      fortuneImageLayerPanelMaxScrollOffset(10),
    );
    expect(panelItems.last.id, 'image10');
    expect(
      imagesById['image10']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      1.0,
    );
    expect(
      imagesById['image9']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      10.0,
    );
  });

  testWidgets('image layer panel row double click opens image edit dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'image1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {
                fortuneImageObjectIdExtraKey: '#IMAGE1',
                fortuneSheetObjectZOrderExtraKey: 1,
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final toolbarItems = fortuneActiveImageToolbarItems(
      painter().workbook.activeSheet.images.single,
    );
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final row = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      1,
      0,
      top: layerPanelTop,
    );
    expect(row, isNotNull);

    await tester.tapAt(topLeft + row!.center);
    await tester.pump();
    await tester.tapAt(topLeft + row.center);
    await tester.pump();

    expect(painter().imageInsertDialogOpen, isTrue);
    expect(painter().imageInsertEditing, isTrue);
    expect(painter().imageObjectId, '#IMAGE1');
    expect(painter().imageLayerPanelOpen, isFalse);
  });

  testWidgets('image layer panel row double click opens barcode edit dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'barcode1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {
                'fortuneBarcode': true,
                'barcodeText': '123456',
                fortuneBarcodeObjectIdExtraKey: '#BARCODE1',
                fortuneSheetObjectZOrderExtraKey: 1,
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final toolbarItems = fortuneActiveImageToolbarItems(
      painter().workbook.activeSheet.images.single,
    );
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final row = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      1,
      0,
      top: layerPanelTop,
    );
    expect(row, isNotNull);

    await tester.tapAt(topLeft + row!.center);
    await tester.pump();
    await tester.tapAt(topLeft + row.center);
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeEditing, isTrue);
    expect(painter().barcodeObjectId, '#BARCODE1');
    expect(painter().imageLayerPanelOpen, isFalse);
  });

  testWidgets('image layer panel keyboard selects and edits rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index.toDouble(),
                top: index.toDouble(),
                width: 50,
                height: 50,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#IMAGE$index',
                  fortuneSheetObjectZOrderExtraKey: index,
                },
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth + 10,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          10,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'image10');

    final toolbarItems = fortuneActiveImageToolbarItems(
      painter().workbook.activeSheet.images.last,
    );
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(painter().activeImageId, 'image9');

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(painter().activeImageId, 'image1');
    expect(
      painter().imageLayerPanelScrollOffset,
      fortuneImageLayerPanelMaxScrollOffset(10),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pump();
    expect(painter().activeImageId, 'image9');
    expect(painter().imageLayerPanelScrollOffset, fortuneImageLayerPanelRowHeight);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(painter().activeImageId, 'image1');
    expect(
      painter().imageLayerPanelScrollOffset,
      fortuneImageLayerPanelMaxScrollOffset(10),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(painter().activeImageId, 'image10');
    expect(painter().imageLayerPanelScrollOffset, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(painter().imageInsertDialogOpen, isTrue);
    expect(painter().imageInsertEditing, isTrue);
    expect(painter().imageObjectId, '#IMAGE10');
  });

  testWidgets('image layer panel escape closes panel', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'image1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(painter().workbook.activeSheet.images.single),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isFalse);
  });

  testWidgets('image layer panel delete action removes selected row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 3; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: 0,
                top: 0,
                width: 50,
                height: 50,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#IMAGE$index',
                  fortuneSheetObjectZOrderExtraKey: index,
                },
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'image3');

    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(painter().workbook.activeSheet.images.last),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    final deleteRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      3,
      fortuneContextDeleteImageCommand,
      top: settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          fortuneImageLayerPanelMargin,
    );
    expect(deleteRect, isNotNull);

    await tester.tapAt(topLeft + deleteRect!.center);
    await tester.pump();

    expect(painter().imageLayerPanelOpen, isTrue);
    expect(painter().activeImageId, 'image2');
    expect(
      painter().workbook.activeSheet.images.map((image) => image.id),
      ['image1', 'image2'],
    );
  });

  testWidgets('image layer panel delete key removes selected row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 3; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: 0,
                top: 0,
                width: 50,
                height: 50,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#IMAGE$index',
                  fortuneSheetObjectZOrderExtraKey: index,
                },
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(painter().workbook.activeSheet.images.last),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(painter().activeImageId, 'image2');

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(painter().imageLayerPanelOpen, isTrue);
    expect(painter().activeImageId, 'image1');
    expect(
      painter().workbook.activeSheet.images.map((image) => image.id),
      ['image1', 'image3'],
    );
  });

  testWidgets('image layer panel duplicate action copies selected row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 2; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: 0,
                top: 0,
                width: 50,
                height: 50,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#IMAGE$index',
                  fortuneSheetObjectZOrderExtraKey: index,
                },
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();
    expect(painter().activeImageId, 'image2');

    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(painter().workbook.activeSheet.images.last),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    final duplicateRect = fortuneImageLayerPanelActionRect(
      const Size(900, 700),
      2,
      fortuneContextDuplicateImageCommand,
      top: settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight +
          fortuneImageLayerPanelMargin,
    );
    expect(duplicateRect, isNotNull);

    await tester.tapAt(topLeft + duplicateRect!.center);
    await tester.pump();

    final images = painter().workbook.activeSheet.images;
    expect(images, hasLength(3));
    final duplicate = images.last;
    expect(duplicate.id, isNot('image2'));
    expect(painter().activeImageId, duplicate.id);
    expect(painter().imageLayerPanelOpen, isTrue);
    expect(duplicate.left, 12);
    expect(duplicate.top, 12);
    expect(duplicate.extraFields[fortuneImageObjectIdExtraKey], '#IMAGE3');
    expect(duplicate.extraFields[fortuneSheetObjectZOrderExtraKey], 3.0);
  });

  testWidgets('image layer panel keyboard commands duplicate and move row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 2; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: 0,
                top: 0,
                width: 50,
                height: 50,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#IMAGE$index',
                  fortuneSheetObjectZOrderExtraKey: index,
                },
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageRect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      50,
      50,
    );
    await tester.tapAt(topLeft + imageRect.center);
    await tester.pump();

    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      imageRect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      fortuneActiveImageToolbarItems(painter().workbook.activeSheet.images.last),
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();
    expect(painter().imageLayerPanelOpen, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    var images = painter().workbook.activeSheet.images;
    expect(images, hasLength(3));
    final duplicateId = painter().activeImageId;
    expect(duplicateId, isNotNull);
    final duplicate = images.firstWhere((image) => image.id == duplicateId);
    expect(duplicate.extraFields[fortuneImageObjectIdExtraKey], '#IMAGE3');
    expect(duplicate.extraFields[fortuneSheetObjectZOrderExtraKey], 3.0);
    expect(painter().imageLayerPanelOpen, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    images = painter().workbook.activeSheet.images;
    final imagesById = {for (final image in images) image.id: image};
    expect(painter().activeImageId, duplicateId);
    expect(
      imagesById[duplicateId]!.extraFields[fortuneSheetObjectZOrderExtraKey],
      2.0,
    );
    expect(
      imagesById['image2']!.extraFields[fortuneSheetObjectZOrderExtraKey],
      3.0,
    );
    expect(painter().imageLayerPanelOpen, isTrue);
  });

  testWidgets('barcode context menu duplicate copies barcode metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'barcode1',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {
                'fortuneBarcode': true,
                fortuneBarcodeObjectIdExtraKey: '#BARCODE1',
                fortuneSheetObjectZOrderExtraKey: 1,
                'barcodeText': '12345',
                'barcodeFormatId': 'code128',
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final barcodeCenter = topLeft +
        Offset(
          settings.rowHeaderWidth + 25,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              25,
        );
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: barcodeCenter,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    await tester.sendEventToBinding(
      PointerUpEvent(position: barcodeCenter, kind: PointerDeviceKind.mouse),
    );
    await tester.pump();

    expect(painter().activeImageId, 'barcode1');
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);

    await activateOpenContextMenuItem(
      tester,
      topLeft,
      painter(),
      command: fortuneContextDuplicateImageCommand,
    );

    final images = painter().workbook.activeSheet.images;
    expect(images, hasLength(2));
    final duplicate = images.last;
    expect(duplicate.id, isNot('barcode1'));
    expect(painter().activeImageId, duplicate.id);
    expect(duplicate.left, 12);
    expect(duplicate.top, 12);
    expect(duplicate.extraFields['fortuneBarcode'], isTrue);
    expect(duplicate.extraFields[fortuneBarcodeObjectIdExtraKey], '#BARCODE2');
    expect(duplicate.extraFields[fortuneSheetObjectZOrderExtraKey], 2.0);
    expect(duplicate.extraFields['barcodeText'], '12345');
  });

  testWidgets('image layer panel opens scrolled to active lower item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            for (var index = 1; index <= 10; index += 1)
              FortuneImage(
                id: 'image$index',
                src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
                left: index == 1 ? 0 : 120 + index * 55.0,
                top: index == 1 ? 0 : 60,
                width: 40,
                height: 40,
                extraFields: {fortuneSheetObjectZOrderExtraKey: index},
              ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final image1Rect = Rect.fromLTWH(
      settings.rowHeaderWidth,
      settings.effectiveToolbarHeight +
          settings.effectiveFormulaBarHeight +
          settings.columnHeaderHeight,
      40,
      40,
    );
    await tester.tapAt(topLeft + image1Rect.center);
    await tester.pump();

    expect(painter().activeImageId, 'image1');

    final image = painter().workbook.activeSheet.images.firstWhere(
      (image) => image.id == 'image1',
    );
    final toolbarItems = fortuneActiveImageToolbarItems(image);
    final layerButtonRect = fortuneActiveImageToolbarItemRect(
      image1Rect,
      const Size(900, 700),
      fortuneContextToggleLayerPanelCommand,
      toolbarItems,
    );
    expect(layerButtonRect, isNotNull);

    await tester.tapAt(topLeft + layerButtonRect!.center);
    await tester.pump();

    final expectedOffset = fortuneImageLayerPanelRowHeight * 2;
    expect(painter().imageLayerPanelScrollOffset, expectedOffset);

    final layerPanelTop = settings.effectiveToolbarHeight +
        settings.effectiveFormulaBarHeight +
        settings.columnHeaderHeight +
        fortuneImageLayerPanelMargin;
    final image1RowRect = fortuneImageLayerPanelItemRect(
      const Size(900, 700),
      10,
      9,
      top: layerPanelTop,
      scrollOffset: expectedOffset,
    );
    expect(image1RowRect, isNotNull);
    expect(image1RowRect!.contains(image1RowRect.center), isTrue);
  });

  testWidgets('tab cycles overlapping image selection', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings();
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: [
            FortuneImage(
              id: 'front',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 10},
            ),
            FortuneImage(
              id: 'back',
              src: 'data:image/png;base64,${base64Encode(_transparentPng)}',
              left: 0,
              top: 0,
              width: 50,
              height: 50,
              extraFields: const {fortuneSheetObjectZOrderExtraKey: 1},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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
    final imageCenter = topLeft +
        Offset(
          settings.rowHeaderWidth + 25,
          settings.effectiveToolbarHeight +
              settings.effectiveFormulaBarHeight +
              settings.columnHeaderHeight +
              25,
        );
    await tester.tapAt(imageCenter);
    await tester.pump();

    expect(painter().activeImageId, 'front');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(painter().activeImageId, 'back');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(painter().activeImageId, 'front');
  });

  testWidgets('barcode close button owns hover and pressed feedback', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
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

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    final closeCenter = topLeft + fortuneBarcodeCloseButtonRect(dialogRect).center;

    await tester.sendEventToBinding(PointerHoverEvent(position: closeCenter));
    await tester.pump();

    expect(painter().dialogCloseHoveredKey, 'barcode');
    expect(painter().barcodeHoveredControl, isNull);

    await tester.sendEventToBinding(
      PointerDownEvent(
        position: closeCenter,
        buttons: kPrimaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().dialogClosePressedKey, 'barcode');
    expect(painter().barcodePressedControl, isNull);

    await tester.sendEventToBinding(PointerUpEvent(position: closeCenter));
    await tester.pump();

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().dialogCloseHoveredKey, isNull);
    expect(painter().dialogClosePressedKey, isNull);
  });

  testWidgets('sheet dialog visibility callback follows barcode dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final visibility = <bool>[];
    final workbook = FortuneWorkbook(
      settings: FortuneSettings(
        toolbarItems: const [fortuneToolbarBarcodeCommand],
        onDialogVisibilityChanged: (open) {
          visibility.add(open);
        },
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
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
    await tester.pump();

    expect(painter().barcodeDialogOpen, isTrue);
    expect(visibility, [true]);

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeCloseButtonRect(dialogRect).center,
    );
    await tester.pump();
    await tester.pump();

    expect(painter().barcodeDialogOpen, isFalse);
    expect(visibility, [true, false]);
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

  testWidgets('barcode insert dialog tab cycles editable inputs', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(workbook: workbook),
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

    EditableText editor(String key) {
      final keyed = find.byKey(ValueKey(key));
      final child = find.descendant(
        of: keyed,
        matching: find.byType(EditableText),
      );
      return tester.widget<EditableText>(
        child.evaluate().isEmpty ? keyed : child,
      );
    }

    expect(editor('fortune-barcode-text-input').focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      editor('fortune-barcode-module-scale-input').focusNode.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      editor('fortune-barcode-bar-height-input').focusNode.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(editor('fortune-barcode-width-input').focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(
      editor('fortune-barcode-bar-height-input').focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('barcode insert stores object ID metadata', (tester) async {
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
                  barcodeObjectIds: const ['#BARCODE', '#QRCODE'],
                  barcodeRenderer: (request) async {
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

    expect(
      find.byKey(const ValueKey('fortune-barcode-object-id-input')),
      findsNothing,
    );
    expect(painter().barcodeObjectId, '#BARCODE');
    expect(painter().barcodeObjectIdOptions, ['#BARCODE', '#QRCODE']);

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeObjectIdInputRect(dialogRect).center,
    );
    await tester.pump();

    expect(painter().barcodeObjectIdMenuOpen, isTrue);
    expect(painter().barcodeObjectIdMenuSelectedIndex, 0);

    final objectIdMenu = fortuneBarcodeObjectIdMenuRect(dialogRect, 2);
    await tester.tapAt(
      topLeft +
          objectIdMenu.topLeft +
          const Offset(10, 1.5 * fortuneContextMenuRowHeight),
    );
    await tester.pump();

    expect(painter().barcodeObjectId, '#QRCODE');

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-barcode-text-input')),
        matching: find.byType(EditableText),
      ),
      '12345',
    );
    await tester.pump();

    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    final image = painter().workbook.activeSheet.images.single;
    expect(image.extraFields[fortuneBarcodeObjectIdExtraKey], '#QRCODE');
    expect(image.extraFields[fortuneSheetObjectZOrderExtraKey], 1);
    expect(image.extraFields[fortuneBarcodeBodyHeightExtraKey], greaterThan(0));
    expect(image.extraFields[fortuneBarcodeIdLabelPrintExcludedExtraKey], true);
  });

  test('barcode object ID label scales with resized barcode', () {
    const extraFields = <String, Object?>{
      'fortuneBarcode': true,
      fortuneBarcodeObjectIdExtraKey: 'ID',
      fortuneBarcodeBodyHeightExtraKey: 60,
      fortuneBarcodeBodyRatioExtraKey: 0.75,
      fortuneBarcodeIdLabelPrintExcludedExtraKey: true,
    };
    const originalImage = FortuneImage(
      id: 'original',
      src: 'missing-original',
      left: 20,
      top: 20,
      width: 120,
      height: 80,
      extraFields: extraFields,
    );
    const largeImage = FortuneImage(
      id: 'large',
      src: 'missing-large',
      left: 20,
      top: 20,
      width: 240,
      height: 160,
      extraFields: extraFields,
    );
    const smallImage = FortuneImage(
      id: 'small',
      src: 'missing-small',
      left: 170,
      top: 35,
      width: 60,
      height: 40,
      extraFields: extraFields,
    );

    final originalMetrics = fortuneBarcodeObjectIdLabelMetrics(
      const Rect.fromLTWH(20, 20, 120, 80),
      originalImage,
    );
    final largeMetrics = fortuneBarcodeObjectIdLabelMetrics(
      const Rect.fromLTWH(20, 20, 240, 160),
      largeImage,
    );
    final smallMetrics = fortuneBarcodeObjectIdLabelMetrics(
      const Rect.fromLTWH(170, 35, 60, 40),
      smallImage,
    );

    expect(originalMetrics, isNotNull);
    expect(largeMetrics, isNotNull);
    expect(smallMetrics, isNotNull);
    expect(
      largeMetrics!.bodyRect.height,
      greaterThan(originalMetrics!.bodyRect.height),
    );
    expect(
      smallMetrics!.bodyRect.height,
      lessThan(originalMetrics.bodyRect.height),
    );
    expect(
      originalMetrics.fontSize,
      closeTo(60 * 0.18 * fortuneBarcodeObjectIdLabelScale, 0.001),
    );
    expect(
      originalMetrics.boxRect.width,
      greaterThanOrEqualTo(120 * 0.18 * fortuneBarcodeObjectIdLabelScale),
    );
    expect(
      originalMetrics.boxRect.height,
      greaterThanOrEqualTo(60 * 0.12 * fortuneBarcodeObjectIdLabelScale),
    );
    expect(
      largeMetrics.boxRect.width,
      greaterThan(originalMetrics.boxRect.width),
    );
    expect(smallMetrics.boxRect.width, lessThan(originalMetrics.boxRect.width));
    expect(largeMetrics.fontSize, greaterThan(originalMetrics.fontSize));
    expect(smallMetrics.fontSize, lessThan(originalMetrics.fontSize));
    expect(smallMetrics.boxRect.width, lessThan(28));
    expect(smallMetrics.boxRect.height, lessThan(16));
  });

  test('barcode object ID label centers on rendered bar bounds', () {
    const image = FortuneImage(
      id: 'barcode',
      src: 'missing',
      left: 20,
      top: 20,
      width: 120,
      height: 80,
      extraFields: {
        'fortuneBarcode': true,
        fortuneBarcodeObjectIdExtraKey: 'ID',
        fortuneBarcodeBodyTopExtraKey: 8,
        fortuneBarcodeBodyHeightExtraKey: 48,
        fortuneBarcodeBodyRatioExtraKey: 0.6,
        fortuneBarcodeIdLabelPrintExcludedExtraKey: true,
        'originHeight': 80,
      },
    );

    final metrics = fortuneBarcodeObjectIdLabelMetrics(
      const Rect.fromLTWH(20, 20, 240, 160),
      image,
    );

    expect(metrics, isNotNull);
    expect(metrics!.bodyRect.top, closeTo(36, 0.001));
    expect(metrics.bodyRect.height, closeTo(96, 0.001));
    expect(
      metrics.boxRect.center.dy,
      closeTo(metrics.bodyRect.center.dy, 0.001),
    );
  });

  test('barcode image resize scales dialog height metadata', () {
    const image = FortuneImage(
      id: 'barcode',
      src: 'missing',
      left: 20,
      top: 20,
      width: 200,
      height: 100,
      extraFields: {
        'fortuneBarcode': true,
        'widthMm': 52.9166666667,
        'heightMm': 26.4583333333,
        'barcodeBarHeight': 10,
        'barcodeHumanReadableFontSize': 14,
        fortuneBarcodeBodyTopExtraKey: 2,
        fortuneBarcodeBodyHeightExtraKey: 60,
        fortuneBarcodeBodyRatioExtraKey: 0.6,
      },
    );

    final extraFields = fortuneImageResizeExtraFieldsForMetadata(
      image,
      width: 300,
      height: 150,
      usesMillimeters: true,
    );

    expect(extraFields['widthMm'], closeTo(79.375, 0.001));
    expect(extraFields['heightMm'], closeTo(39.6875, 0.001));
    expect(extraFields['barcodeBarHeight'], closeTo(15, 0.001));
    expect(extraFields['barcodeHumanReadableFontSize'], closeTo(21, 0.001));
    expect(extraFields[fortuneBarcodeBodyTopExtraKey], closeTo(3, 0.001));
    expect(extraFields[fortuneBarcodeBodyHeightExtraKey], closeTo(90, 0.001));
  });

  testWidgets('barcode edit dialog shows resized image height', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const barcodeImage = FortuneImage(
      id: 'barcode-1',
      src:
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
      left: 20,
      top: 20,
      width: 120,
      height: 150,
      extraFields: {
        'fortuneBarcode': true,
        fortuneBarcodeObjectIdExtraKey: '#BARCODE',
        'barcodeText': '12345',
        'barcodeFormatId': 'code128',
        'barcodeFormatLabel': 'Code128',
        'widthMm': 31.75,
        'heightMm': 26.4583333333,
        'barcodeBarHeight': 10,
        'barcodeModuleScale': 3,
        'barcodeHumanReadableFontSize': 14,
        'barcodeShowText': false,
      },
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [barcodeImage],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 100,
            fortuneSheetGridClientHeightMmKey: 100,
          },
        ),
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
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

    EditableText editableTextIn(String key) {
      return tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(EditableText),
        ),
      );
    }

    expect(painter().barcodeDialogOpen, isTrue);
    expect(
      editableTextIn('fortune-barcode-height-input').controller.text,
      '39.69',
    );
    expect(
      editableTextIn('fortune-barcode-bar-height-input').controller.text,
      '15',
    );
    expect(painter().barcodeTextFontSizeLabel, '21');
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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

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

  testWidgets('barcode edit updates object ID metadata', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
        fortuneBarcodeObjectIdExtraKey: 'OLD-ID',
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
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
            barcodeObjectIds: const ['OLD-ID', 'NEW-ID'],
            barcodeRenderer: (request) async {
              return FortuneBarcodeRenderResult(
                bytes: _transparentPng,
                pixelWidth: 120,
                pixelHeight: 60,
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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeObjectId, 'OLD-ID');
    expect(painter().barcodeObjectIdMenuSelectedIndex, 0);

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: true,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeObjectIdInputRect(dialogRect).center,
    );
    await tester.pump();

    expect(painter().barcodeObjectIdMenuOpen, isTrue);
    final objectIdMenu = fortuneBarcodeObjectIdMenuRect(dialogRect, 2);
    await tester.tapAt(
      topLeft +
          objectIdMenu.topLeft +
          const Offset(10, 1.5 * fortuneContextMenuRowHeight),
    );
    await tester.pump();

    expect(painter().barcodeObjectId, 'NEW-ID');

    await tester.tapAt(
      topLeft + fortuneBarcodeConfirmButtonRect(dialogRect).center,
    );
    await tester.pumpAndSettle();

    final updated = painter().workbook.activeSheet.images.single;
    expect(updated.extraFields[fortuneBarcodeObjectIdExtraKey], 'NEW-ID');
    expect(
      updated.extraFields[fortuneBarcodeIdLabelPrintExcludedExtraKey],
      true,
    );
  });

  testWidgets('barcode edit object ID menu scrolls to restored selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
        fortuneBarcodeObjectIdExtraKey: '#QRCODE-10',
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
              FortuneBarcodeFormatOption(id: 'code128', label: 'Code128'),
            ],
            barcodeObjectIds: const [
              '#BARCODE-0',
              '#BARCODE-1',
              '#BARCODE-2',
              '#BARCODE-3',
              '#BARCODE-4',
              '#BARCODE-5',
              '#BARCODE-6',
              '#BARCODE-7',
              '#BARCODE-8',
              '#BARCODE-9',
              '#QRCODE-10',
            ],
            barcodeRenderer: (_) async => FortuneBarcodeRenderResult(
              bytes: _transparentPng,
              pixelWidth: 120,
              pixelHeight: 60,
            ),
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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

    expect(painter().barcodeDialogOpen, isTrue);
    expect(painter().barcodeObjectId, '#QRCODE-10');
    expect(painter().barcodeObjectIdMenuSelectedIndex, 10);

    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: true,
    );
    await tester.tapAt(
      topLeft + fortuneBarcodeObjectIdInputRect(dialogRect).center,
    );
    await tester.pump();

    expect(painter().barcodeObjectIdMenuOpen, isTrue);
    expect(painter().barcodeObjectIdMenuSelectedIndex, 10);
    expect(painter().barcodeObjectIdMenuScrollOffset, greaterThan(0));
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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

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

    expect(painter().barcodeDialogOpen, isFalse);
    expect(painter().contextMenuItems, _barcodeObjectContextMenuItems);
    await activateOpenContextMenuItem(tester, topLeft, painter());

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
