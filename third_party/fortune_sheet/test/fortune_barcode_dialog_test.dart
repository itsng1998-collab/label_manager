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
  '|',
  fortuneContextDuplicateImageCommand,
  fortuneContextDeleteImageCommand,
  '|',
  fortuneContextBringToFrontCommand,
  fortuneContextBringForwardCommand,
  fortuneContextSendBackwardCommand,
  fortuneContextSendToBackCommand,
];

const List<String> _barcodeObjectContextMenuItems = [
  fortuneContextEditBarcodeCommand,
  '|',
  fortuneContextDuplicateImageCommand,
  fortuneContextDeleteImageCommand,
  '|',
  fortuneContextBringToFrontCommand,
  fortuneContextBringForwardCommand,
  fortuneContextSendBackwardCommand,
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
  final targetCommand =
      command ?? painter.contextMenuItems.firstWhere((item) => item != '|');
  final itemRect = fortuneContextMenuItemRect(
    painter.contextMenuAt!,
    targetCommand,
    painter.contextMenuItems,
  );
  expect(itemRect, isNotNull);
  await tester.tapAt(canvasTopLeft + itemRect!.center);
  await tester.pump();
}

void main() {
  test('image and barcode dialogs place cancel before confirm', () {
    const imageRect = Rect.fromLTWH(100, 80, 420, 380);
    const barcodeRect = Rect.fromLTWH(120, 60, 500, 440);

    final imageCancel = fortuneImageInsertCancelButtonRect(imageRect);
    final imageConfirm = fortuneImageInsertConfirmButtonRect(imageRect);
    final barcodeCancel = fortuneBarcodeCancelButtonRect(barcodeRect);
    final barcodeConfirm = fortuneBarcodeConfirmButtonRect(barcodeRect);

    expect(imageCancel.right, lessThan(imageConfirm.left));
    expect(imageCancel.top, imageConfirm.top);
    expect(barcodeCancel.right, lessThan(barcodeConfirm.left));
    expect(barcodeCancel.top, barcodeConfirm.top);
  });

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

    expect(
      fortuneImageLayerPanelActionGlyph(fortuneContextDuplicateImageCommand),
      '⧉',
    );
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
      fortuneImageLayerPanelActionEnabled(
        images,
        'front',
        fortuneContextBringToFrontCommand,
        selectedImageIds: {'front', 'back'},
      ),
      isFalse,
    );
    expect(
      fortuneImageLayerPanelActionEnabled(
        images,
        'front',
        fortuneContextSendToBackCommand,
        selectedImageIds: {'front', 'back'},
      ),
      isFalse,
    );
    final fourImages = [
      for (var index = 1; index <= 4; index += 1)
        FortuneImage(
          id: 'image$index',
          src: 'data:image/png;base64,empty',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          extraFields: {fortuneSheetObjectZOrderExtraKey: index},
        ),
    ];
    expect(
      fortuneImageLayerPanelActionEnabled(
        fourImages,
        'image4',
        fortuneContextBringToFrontCommand,
        selectedImageIds: {'image4', 'image2'},
      ),
      isTrue,
    );
    for (final command in [
      fortuneContextBringToFrontCommand,
      fortuneContextBringForwardCommand,
      fortuneContextSendBackwardCommand,
      fortuneContextSendToBackCommand,
    ]) {
      expect(
        fortuneImageLayerPanelActionEnabled(
          fourImages,
          'image4',
          command,
          selectedImageIds: {'image4', 'image3', 'image2', 'image1'},
        ),
        isFalse,
      );
    }
    expect(
      fortuneImageLayerPanelActionEnabled(
        fourImages,
        'image3',
        fortuneContextBringToFrontCommand,
        selectedImageIds: {'image4', 'image3'},
      ),
      isFalse,
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
    expect(
      fortuneActiveImageToolbarItemEnabled(
        images,
        'back',
        fortuneContextDeleteImageCommand,
        allowEdit: false,
      ),
      isFalse,
    );
    expect(
      fortuneActiveImageToolbarItemEnabled(
        images,
        'back',
        fortuneContextToggleLayerPanelCommand,
        allowEdit: false,
      ),
      isTrue,
    );
  });

  test('image context menu shortcut labels fit beside item labels', () {
    const expectedShortcuts = {
      fortuneContextDuplicateImageCommand: 'Ctrl+D',
      fortuneContextDeleteImageCommand: 'Del',
      fortuneContextBringForwardCommand: 'Ctrl+↑',
      fortuneContextSendBackwardCommand: 'Ctrl+↓',
      fortuneContextBringToFrontCommand: 'Ctrl+Home',
      fortuneContextSendToBackCommand: 'Ctrl+End',
    };

    for (final entry in expectedShortcuts.entries) {
      expect(fortuneContextMenuShortcutLabel(entry.key), entry.value);
    }
    expect(
      fortuneContextMenuShortcutLabel(fortuneContextEditImageCommand),
      isEmpty,
    );
    expect(
      fortuneContextMenuShortcutLabel(fortuneContextEditBarcodeCommand),
      isEmpty,
    );

    final row = fortuneContextMenuItemRect(
      const Offset(40, 80),
      fortuneContextDuplicateImageCommand,
      _imageObjectContextMenuItems,
    );
    expect(row, isNotNull);
    final label = fortuneContextMenuLabelRect(row!);
    final shortcut = fortuneContextMenuShortcutRect(row);

    expect(label.left, greaterThanOrEqualTo(row.left));
    expect(label.right, lessThanOrEqualTo(shortcut.left));
    expect(shortcut.right, lessThanOrEqualTo(row.right));
    expect(label.top, row.top);
    expect(shortcut.top, row.top);
    expect(label.height, row.height);
    expect(shortcut.height, row.height);
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

  test('barcode format menu uses remaining dialog height', () {
    final dialogRect = fortuneBarcodeDialogRect(
      const Size(900, 700),
      editing: false,
    );
    final combo = fortuneBarcodeFormatComboRect(dialogRect);
    final menu = fortuneBarcodeFormatMenuRect(dialogRect, 20);

    expect(menu.top, combo.bottom + 2);
    expect(menu.bottom, dialogRect.bottom);
    expect(
      fortuneBarcodeFormatMenuMaxScrollOffset(dialogRect, 20),
      20 * fortuneContextMenuRowHeight - menu.height,
    );

    final shortMenu = fortuneBarcodeFormatMenuRect(dialogRect, 2);
    expect(shortMenu.height, 2 * fortuneContextMenuRowHeight);
    expect(fortuneBarcodeFormatMenuMaxScrollOffset(dialogRect, 2), 0);
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
    expect(painter().barcodeFormatMenuScrollOffset, 0);
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
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarImageCommand],
      ),
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
      topLeft +
          fortuneImageObjectIdInputRect(dialogRect).centerRight -
          const Offset(12, 0),
    );
    await tester.pump();

    expect(painter().imageObjectIdMenuOpen, isTrue);
  });

  testWidgets(
    'image insert object ID menu includes provided IDs and fills dialog',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final workbook = FortuneWorkbook(
        settings: const FortuneSettings(
          toolbarItems: [fortuneToolbarImageCommand],
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
              imageObjectIds: const [
                '#ITEMNAME',
                '#ELEMENT',
                '#SWEIGHT',
                '#SPRICE',
                '#ORIGIN',
                '#PRICE',
                '#BARCODE_ID',
                '#QRCODE_ID',
                '#MEMO',
                '#ETC',
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
              fortuneToolbarImageCommand,
              width: 900,
              items: workbook.settings.toolbarItems,
            ),
      );
      await tester.pump();

      expect(painter().imageObjectIdOptions.take(11), [
        '#IMAGE1',
        '#ITEMNAME',
        '#ELEMENT',
        '#SWEIGHT',
        '#SPRICE',
        '#ORIGIN',
        '#PRICE',
        '#BARCODE_ID',
        '#QRCODE_ID',
        '#MEMO',
        '#ETC',
      ]);

      final dialogRect = fortuneImageInsertDialogRect(
        const Size(900, 700),
        editing: false,
      );
      await tester.tapAt(
        topLeft +
            fortuneImageObjectIdInputRect(dialogRect).centerRight -
            const Offset(12, 0),
      );
      await tester.pump();

      final menuRect = fortuneImageObjectIdMenuRect(
        dialogRect,
        painter().imageObjectIdOptions.length,
      );
      expect(painter().imageObjectIdMenuOpen, isTrue);
      expect(menuRect.bottom, dialogRect.bottom);
      expect(
        menuRect.height,
        lessThan(
          painter().imageObjectIdOptions.length * fortuneContextMenuRowHeight,
        ),
      );

      await tester.tapAt(
        topLeft +
            menuRect.topLeft +
            const Offset(10, 1.5 * fortuneContextMenuRowHeight),
      );
      await tester.pump();

      expect(painter().imageObjectId, '#ITEMNAME');
      expect(painter().imageObjectIdMenuOpen, isFalse);

      await tester.tapAt(
        topLeft +
            fortuneImageObjectIdInputRect(dialogRect).centerRight -
            const Offset(12, 0),
      );
      await tester.pump();

      expect(painter().imageObjectIdOptions.first, '#IMAGE1');
      expect(painter().imageObjectIdOptions[1], '#ITEMNAME');
    },
  );

  testWidgets('image insert stores next zOrder metadata', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        toolbarItems: [fortuneToolbarImageCommand],
      ),
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
    await tester.tapAt(
      topLeft + fortuneImageInsertFileButtonRect(dialogRect).center,
    );
    await tester.pump();
    await tester.tapAt(
      topLeft + fortuneImageInsertConfirmButtonRect(dialogRect).center,
    );
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

    FortuneObjectPanelOpenRequest? panelRequest;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            onOpenObjectPanelRequest: (request) => panelRequest = request,
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
    final imageCenter =
        topLeft +
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

    expect(painter().imageInsertDialogOpen, isFalse);
    expect(panelRequest?.sheetId, 's1');
    expect(
      panelRequest?.objectKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'img1'),
    );
    expect(panelRequest?.propertyField, 'connectionId');
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
    final imageCenter =
        topLeft +
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
      for (final image in painter().workbook.activeSheet.images)
        image.id: image,
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
      for (final image in painter().workbook.activeSheet.images)
        image.id: image,
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
    final imageCenter =
        topLeft +
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
      for (final image in painter().workbook.activeSheet.images)
        image.id: image,
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
    await tester.sendEventToBinding(
      PointerHoverEvent(position: duplicateCenter),
    );
    await tester.pump();

    expect(
      painter().activeImageToolbarHoveredCommand,
      fortuneContextDuplicateImageCommand,
    );
    expect(
      painter().activeImageToolbarTooltipPosition,
      duplicateCenter - topLeft,
    );

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
      for (final image in painter().workbook.activeSheet.images)
        image.id: image,
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

  testWidgets('image floating toolbar object panel command is no-op without host callback', (
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

    expect(painter().activeImageId, 'front');
    expect(painter().selectedImageIds, {'front'});
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
    final barcodeCenter =
        topLeft +
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

  testWidgets('image floating toolbar requests generic object panel open for selected image', (
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

    FortuneObjectPanelOpenRequest? panelRequest;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            onOpenObjectPanelRequest: (request) => panelRequest = request,
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

    expect(panelRequest?.sheetId, 's1');
    expect(
      panelRequest?.objectKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image1'),
    );
    expect(panelRequest?.propertyField, isNull);
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
    final imageCenter =
        topLeft +
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
    final closeCenter =
        topLeft + fortuneBarcodeCloseButtonRect(dialogRect).center;

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

    expect(editor('fortune-barcode-width-input').focusNode.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(
      editor('fortune-barcode-module-scale-input').focusNode.hasFocus,
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
    expect(editableTexts, hasLength(7));
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

  testWidgets(
    'structured barcode option inserts linked barcode without value input',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      FortuneBarcodeRequest? captured;
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
                FortuneBarcodeFormatOption(id: 'ean13', label: 'EAN13'),
              ],
              barcodeObjectOptions: const [
                FortuneObjectConnectionOption(
                  value: '#ITEM_CODE',
                  label: '품목 코드 (#ITEM_CODE) · EAN13',
                  formatId: 'ean13',
                  formatLabel: 'EAN13',
                  showHumanReadableText: true,
                ),
              ],
              barcodeRenderer: (request) async {
                captured = request;
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

      FortuneSheetPainter painter() => tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FortuneSheetCanvas),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;

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
      final rect = fortuneBarcodeDialogRect(const Size(900, 700));
      await tester.tapAt(
        topLeft +
            fortuneBarcodeObjectIdInputRect(rect).centerRight -
            const Offset(12, 0),
      );
      await tester.pump();
      await tester.tapAt(
        topLeft +
            fortuneBarcodeObjectIdMenuRect(rect, 2).topLeft +
            const Offset(10, 1.5 * fortuneContextMenuRowHeight),
      );
      await tester.pump();

      expect(painter().barcodeObjectId, '품목 코드 (#ITEM_CODE) · EAN13');
      expect(painter().barcodeLinked, isTrue);
      expect(painter().barcodeFormatLabel, 'EAN13');
      expect(painter().barcodeShowHumanReadableText, isTrue);
      expect(
        find.byKey(const ValueKey('fortune-barcode-text-input')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fortune-barcode-module-scale-input')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fortune-barcode-bar-height-input')),
        findsOneWidget,
      );

      await tester.tapAt(
        topLeft + fortuneBarcodeConfirmButtonRect(rect).center,
      );
      await tester.pump();

      expect(captured?.formatId, 'ean13');
      expect(captured?.showHumanReadableText, isTrue);
      expect(
        painter()
            .workbook
            .activeSheet
            .images
            .single
            .extraFields[fortuneBarcodeObjectIdExtraKey],
        '#ITEM_CODE',
      );
    },
  );

  testWidgets('structured image option inserts linked image without file', (
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
        toolbarItems: [fortuneToolbarImageCommand],
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
            imageObjectOptions: const [
              FortuneObjectConnectionOption(
                value: '#ITEM_IMAGE',
                label: '품목 이미지 (#ITEM_IMAGE) · 이미지',
              ),
            ],
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(FortuneSheetCanvas),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;

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
    final rect = fortuneImageInsertDialogRect(const Size(900, 700));
    await tester.tapAt(
      topLeft +
          fortuneImageObjectIdInputRect(rect).centerRight -
          const Offset(12, 0),
    );
    await tester.pump();
    await tester.tapAt(
      topLeft +
          fortuneImageObjectIdMenuRect(rect, 2).topLeft +
          const Offset(10, 1.5 * fortuneContextMenuRowHeight),
    );
    await tester.pump();

    expect(painter().imageLinked, isTrue);
    expect(painter().imageModeAvailable, isTrue);
    expect(painter().imageInsertHasFile, isFalse);
    await tester.tapAt(topLeft + fortuneImageFixedModeRect(rect).center);
    await tester.pump();
    expect(painter().imageLinked, isFalse);
    await tester.tapAt(topLeft + fortuneImageLinkedModeRect(rect).center);
    await tester.pump();
    expect(painter().imageLinked, isTrue);
    await tester.tapAt(
      topLeft + fortuneImageInsertConfirmButtonRect(rect).center,
    );
    await tester.pump();

    expect(
      painter()
          .workbook
          .activeSheet
          .images
          .single
          .extraFields[fortuneImageObjectIdExtraKey],
      '#ITEM_IMAGE',
    );
  });
}
