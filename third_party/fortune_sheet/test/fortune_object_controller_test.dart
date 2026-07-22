import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_object_layer_panel.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

const _testPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  test('connection choices dedupe options and mark stale current values', () {
    final choices = fortuneObjectConnectionChoices(
      options: const [
        FortuneObjectConnectionOption(value: ' Logo ', label: '회사 로고'),
        FortuneObjectConnectionOption(value: 'logo', label: '중복'),
      ],
      legacyIds: const [' LOGO ', 'Legacy'],
      currentValue: 'Missing',
    );

    expect(choices.map((choice) => choice.value), [
      '',
      'Logo',
      'Legacy',
      'Missing',
    ]);
    expect(choices[1].label, '회사 로고');
    expect(choices.last.label, '연결 끊김 (Missing)');
    expect(choices.last.stale, isTrue);
  });

  testWidgets(
    'controller publishes immutable exact object selection snapshots',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = FortuneSheetController();
      var notifications = 0;
      controller.addListener(() => notifications += 1);
      final workbook = FortuneWorkbook(
        settings: const FortuneSettings(
          showToolbar: false,
          showFormulaBar: false,
        ),
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            images: const [
              FortuneImage(
                id: 'image_1',
                src: 'data:image/png;base64,',
                left: 120,
                top: 50,
                width: 40,
                height: 30,
                extraFields: {'zOrder': 2.0},
              ),
            ],
            shapes: const [
              FortuneShape(
                id: 'rect_1',
                kind: FortuneShapeKind.rectangle,
                left: 100,
                top: 50,
                width: 80,
                height: 30,
                fillColor: '#FFFFFF',
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
              controller: controller,
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

      expect(notifications, 1);
      expect(controller.objectSelection.attached, isTrue);
      expect(controller.objectSelection.activeKey, isNull);
      expect(controller.objectSelection.selectedKeys, isEmpty);
      expect(() => controller.dispose(), throwsStateError);

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.tapAt(topLeft + const Offset(156, 85));
      await tester.pump();

      const key = FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'rect_1',
      );
      expect(notifications, 2);
      expect(controller.objectSelection.activeKey, key);
      expect(controller.objectSelection.selectedKeys, {key});
      expect(
        () => controller.objectSelection.selectedKeys.add(key),
        throwsUnsupportedError,
      );

      await tester.tapAt(topLeft + const Offset(186, 85));
      await tester.pump();

      const imageKey = FortuneSheetObjectKey(
        FortuneSheetObjectKind.image,
        'image_1',
      );
      expect(notifications, 3);
      expect(controller.objectSelection.activeKey, imageKey);
      expect(controller.objectSelection.selectedKeys, {imageKey});
      expect(controller.objectSelection.objects.map((object) => object.key), [
        key,
        imageKey,
      ]);
      expect(
        () => controller.objectSelection.objects.clear(),
        throwsUnsupportedError,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(notifications, 4);
      expect(controller.objectSelection.activeKey, key);
      expect(controller.objectSelection.selectedKeys, {key});

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(notifications, 5);
      expect(controller.objectSelection.activeKey, imageKey);
      expect(controller.objectSelection.selectedKeys, {imageKey});

      controller.selectObject(key);
      await tester.pump();
      expect(notifications, 6);
      expect(controller.objectSelection.activeKey, key);

      controller.sendSelectedObjectsToBack();
      await tester.pump();
      expect(notifications, 6);

      controller.bringSelectedObjectsToFront();
      await tester.pump();
      expect(notifications, 7);
      expect(controller.objectSelection.objects.map((object) => object.key), [
        imageKey,
        key,
      ]);

      controller.sendSelectedObjectsToBack();
      await tester.pump();
      expect(notifications, 8);
      expect(controller.objectSelection.objects.map((object) => object.key), [
        key,
        imageKey,
      ]);

      controller.deleteSelectedObjects();
      await tester.pump();
      expect(notifications, 9);
      expect(controller.objectSelection.activeKey, imageKey);
      expect(controller.objectSelection.selectedKeys, {imageKey});
      expect(painter().workbook.activeSheet.shapes, isEmpty);
      expect(painter().workbook.activeSheet.images, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(notifications, 10);
      expect(controller.objectSelection.attached, isFalse);
      expect(controller.objectSelection.activeKey, isNull);
      controller.dispose();
    },
  );

  testWidgets('object layer panel selects and deletes mixed typed objects', (
    tester,
  ) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, Object?>{'text': clipboardText};
        }
        return null;
      },
    );
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,',
              left: 20,
              top: 20,
              width: 30,
              height: 30,
              extraFields: {'zOrder': 2.0},
            ),
          ],
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 60,
              top: 20,
              width: 30,
              height: 30,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 700,
              child: FortuneSheetCanvas(
                workbook: workbook,
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 700,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );

    expect(find.text('이미지 image_1'), findsOneWidget);
    expect(find.text('사각형 rect_1'), findsOneWidget);

    await tester.tap(find.text('사각형 rect_1'));
    await tester.pump();
    expect(
      controller.objectSelection.activeKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('이미지 image_1'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.objectSelection.selectedKeys, {
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1'),
    });

    controller.duplicateSelectedObjects();
    await tester.pump();
    expect(
      controller.objectSelection.objects.map((object) => object.key),
      hasLength(4),
    );
    const duplicateImageKey = FortuneSheetObjectKey(
      FortuneSheetObjectKind.image,
      'image_2',
    );
    const duplicateShapeKey = FortuneSheetObjectKey(
      FortuneSheetObjectKind.rectangle,
      'rect_2',
    );
    expect(find.text('이미지 image_2'), findsOneWidget);
    expect(find.text('사각형 rect_2'), findsOneWidget);
    expect(controller.objectSelection.selectedKeys, {
      duplicateImageKey,
      duplicateShapeKey,
    });
    expect(controller.objectSelection.activeKey, duplicateImageKey);
    expect(
      controller.objectSelection.objects
          .map((object) => object.key)
          .toList(growable: false),
      [
        const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
        const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1'),
        duplicateShapeKey,
        duplicateImageKey,
      ],
    );

    await tester.tap(find.byTooltip('선택한 개체 삭제'));
    await tester.pump();
    expect(find.text('사각형 rect_2'), findsNothing);
    expect(find.text('이미지 image_2'), findsNothing);
    expect(find.text('사각형 rect_1'), findsOneWidget);
    expect(find.text('이미지 image_1'), findsOneWidget);
    expect(controller.objectSelection.selectedKeys, {
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1'),
    });

    await tester.tap(find.text('이미지 image_1'));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('이미지 image_2'), findsOneWidget);
    expect(controller.objectSelection.selectedKeys, {
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_2'),
    });

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('controller commits line and shape properties atomically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          lines: const [
            FortuneLine(id: 'line_1', x1: 10, y1: 20, x2: 40, y2: 50),
          ],
          shapes: const [
            FortuneShape(
              id: 'round_1',
              kind: FortuneShapeKind.roundedRectangle,
              left: 60,
              top: 20,
              width: 80,
              height: 40,
              fillColor: '#FFFFFF',
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
          child: FortuneSheetCanvas(workbook: workbook, controller: controller),
        ),
      ),
    );

    FortuneWorkbook paintedWorkbook() {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single
          .workbook;
    }

    const lineKey = FortuneSheetObjectKey(
      FortuneSheetObjectKind.line,
      'line_1',
    );
    controller.selectObject(lineKey);
    await tester.pump();
    expect(controller.objectSelection.activeLine?.id, 'line_1');
    expect(controller.objectSelection.activeShape, isNull);

    controller.updateSelectedLine(
      x1: 15,
      y1: -4,
      x2: 45,
      y2: 55,
      strokeColor: '#abcdef',
    );
    await tester.pump();
    var line = paintedWorkbook().activeSheet.lines.single;
    expect((line.x1, line.y1, line.x2, line.y2), (15, 0, 45, 55));
    expect(line.strokeColor, '#ABCDEF');

    controller.updateSelectedLine(
      x1: 15,
      y1: 0,
      x2: 45,
      y2: 55,
      strokeColor: '#ABCDEF',
    );
    controller.handleUndo();
    await tester.pump();
    line = paintedWorkbook().activeSheet.lines.single;
    expect((line.x1, line.y1, line.x2, line.y2), (10, 20, 40, 50));

    const shapeKey = FortuneSheetObjectKey(
      FortuneSheetObjectKind.roundedRectangle,
      'round_1',
    );
    controller.selectObject(shapeKey);
    await tester.pump();
    expect(controller.objectSelection.activeLine, isNull);
    expect(controller.objectSelection.activeShape?.id, 'round_1');

    controller.updateSelectedShape(
      top: -3,
      rotationDegrees: -45,
      fillColor: null,
      cornerRadiusMm: 8,
    );
    await tester.pump();
    var shape = paintedWorkbook().activeSheet.shapes.single;
    expect(shape.top, 0);
    expect(shape.rotationDegrees, 315);
    expect(shape.fillColor, isNull);
    expect(shape.cornerRadiusMm, 8);

    controller.updateSelectedShape(width: 1);
    controller.handleUndo();
    await tester.pump();
    shape = paintedWorkbook().activeSheet.shapes.single;
    expect(shape.top, 20);
    expect(shape.rotationDegrees, 0);
    expect(shape.fillColor, '#FFFFFF');
    expect(shape.cornerRadiusMm, 0);
  });

  testWidgets('controller commits image properties atomically', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,AA==',
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              extraFields: {
                fortuneImageObjectIdExtraKey: 'OLD',
                'crop': {'left': 0.1},
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
          child: FortuneSheetCanvas(workbook: workbook, controller: controller),
        ),
      ),
    );

    const key = FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1');
    controller.selectObject(key);
    controller.updateSelectedImage(
      left: -5,
      top: -3,
      width: 120,
      height: 60,
      rotationDegrees: -45,
      connectionId: ' NEW ',
    );
    await tester.pump();

    final image = controller.objectSelection.activeImage!;
    expect(
      (image.left, image.top, image.width, image.height),
      (-5, 0, 120, 60),
    );
    expect(image.extraFields['rotation'], 315);
    expect(image.extraFields[fortuneImageObjectIdExtraKey], 'NEW');
    expect(image.extraFields['crop'], {'left': 0.1});

    controller.updateSelectedImage(width: 1);
    controller.handleUndo();
    await tester.pump();
    final restored = controller.objectSelection.activeImage!;
    expect(
      (restored.left, restored.top, restored.width, restored.height),
      (20, 30, 80, 40),
    );
    expect(restored.extraFields[fortuneImageObjectIdExtraKey], 'OLD');
    expect(restored.extraFields['crop'], {'left': 0.1});
  });

  testWidgets('controller replaces image file only for the captured owner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();

    final picker = Completer<FortuneImagePickResult?>();
    var pickerCalls = 0;
    var throwPickerError = true;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'old-src',
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              extraFields: {
                fortuneImageObjectIdExtraKey: 'LOGO',
                'rotation': 90,
                'crop': {'left': 0.1},
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
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
            imagePicker: () {
              if (pickerCalls++ == 0) return picker.future;
              if (throwPickerError) throw StateError('picker failed');
              return Future<FortuneImagePickResult?>.value();
            },
          ),
        ),
      ),
    );
    const key = FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1');
    controller.selectObject(key);
    expect(controller.objectSelection.activeImage?.id, 'image_1');
    final replacement = controller.replaceSelectedImageFile();
    final replaced = await tester.runAsync(() async {
      picker.complete(
        FortuneImagePickResult(
          bytes: base64Decode(_testPngBase64),
          fileName: 'new.png',
          mimeType: 'image/png',
          width: 1,
          height: 1,
        ),
      );
      return replacement;
    });
    expect(replaced, isTrue);
    await tester.pump();

    final image = controller.objectSelection.activeImage!;
    expect(image.src, 'data:image/png;base64,$_testPngBase64');
    expect(
      (image.left, image.top, image.width, image.height),
      (20, 30, 80, 40),
    );
    expect(image.extraFields[fortuneImageObjectIdExtraKey], 'LOGO');
    expect(image.extraFields['rotation'], 90);
    expect(image.extraFields['crop'], {'left': 0.1});
    expect(
      (image.extraFields['originWidth'], image.extraFields['originHeight']),
      (1, 1),
    );
    expect(await controller.replaceSelectedImageFile(), isFalse);
    expect(controller.activeImagePickerFailed, isTrue);
    throwPickerError = false;
    expect(await controller.replaceSelectedImageFile(), isFalse);
    expect(controller.activeImagePickerFailed, isFalse);
  });

  testWidgets('controller renders selected barcode properties atomically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    FortuneBarcodeRequest? request;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'barcode_1',
              src: 'old-src',
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              extraFields: {
                'fortuneBarcode': true,
                fortuneBarcodeObjectIdExtraKey: 'OLD',
                'barcodeText': 'OLD-TEXT',
                'custom': {'keep': true},
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
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
            barcodeFormats: const [
              FortuneBarcodeFormatOption(id: 'CODE128', label: 'Code 128'),
            ],
            barcodeRenderer: (value) async {
              request = value;
              return FortuneBarcodeRenderResult(
                bytes: base64Decode(_testPngBase64),
                pixelWidth: 120,
                pixelHeight: 60,
                bodyTop: 2,
                bodyHeight: 44,
              );
            },
          ),
        ),
      ),
    );
    controller.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, 'barcode_1'),
    );
    final rendered = await controller.renderSelectedBarcode(
      text: '12345',
      formatId: 'CODE128',
      left: -5,
      top: -3,
      width: 120,
      height: 60,
      rotationDegrees: 405,
      moduleScale: 4,
      barHeight: 22,
      leadingText: 'L',
      trailingText: 'R',
      showHumanReadableText: true,
      humanReadableFontFamily: 'Pretendard',
      humanReadableFontSize: 16,
      connectionId: ' NEW ',
      preserveTemplateFormat: true,
    );
    await tester.pump();

    expect(rendered, isTrue);
    expect(
      (request?.text, request?.formatId, request?.rotation),
      ('12345', 'CODE128', 45),
    );
    expect((request?.moduleScale, request?.barHeight), (4, 22));
    expect((request?.leadingText, request?.trailingText), ('L', 'R'));
    expect(request?.showHumanReadableText, isTrue);
    expect(request?.humanReadableFontFamily, 'Pretendard');
    expect(request?.humanReadableFontSize, 16);

    var image = controller.objectSelection.activeImage!;
    expect(
      (image.left, image.top, image.width, image.height),
      (-5, 0, 120, 60),
    );
    expect(image.extraFields[fortuneBarcodeObjectIdExtraKey], 'NEW');
    expect(image.extraFields['barcodeFormatLabel'], 'Code 128');
    expect(image.extraFields['preserveTemplateBarcodeFormat'], isTrue);
    expect(image.extraFields['custom'], {'keep': true});
    expect(
      image.extraFields[fortuneBarcodeBodyRatioExtraKey],
      closeTo(44 / 60, 0.0001),
    );

    controller.handleUndo();
    await tester.pump();
    image = controller.objectSelection.activeImage!;
    expect(
      (image.left, image.top, image.width, image.height),
      (20, 30, 80, 40),
    );
    expect(image.extraFields['barcodeText'], 'OLD-TEXT');
  });

  testWidgets('barcode property render blocks a second pending request', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final mutationEnablement = <bool>[];
    controller.addListener(() {
      mutationEnablement.add(controller.objectMutationEnabled);
    });
    final renders = <Completer<FortuneBarcodeRenderResult?>>[];
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'barcode_1',
              src: 'old-src',
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              extraFields: {'fortuneBarcode': true, 'barcodeText': 'OLD'},
            ),
          ],
        ),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
          height: 700,
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
            barcodeRenderer: (_) {
              final completer = Completer<FortuneBarcodeRenderResult?>();
              renders.add(completer);
              return completer.future;
            },
          ),
        ),
      ),
    );
    controller.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.barcode, 'barcode_1'),
    );

    Future<bool> render(String text) => controller.renderSelectedBarcode(
      text: text,
      formatId: 'CODE128',
      left: 20,
      top: 30,
      width: 80,
      height: 40,
      rotationDegrees: 0,
      moduleScale: 3,
      barHeight: 10,
      leadingText: '',
      trailingText: '',
      showHumanReadableText: false,
      humanReadableFontFamily: null,
      humanReadableFontSize: 14,
      connectionId: '',
      preserveTemplateFormat: false,
    );

    final first = render('FIRST');
    final second = render('SECOND');
    expect(await second, isFalse);
    expect(renders, hasLength(1));
    expect(controller.barcodePropertyRenderPending, isTrue);
    expect(controller.objectMutationEnabled, isFalse);
    expect(controller.projectedCanUndo, isFalse);
    expect(controller.projectedCanRedo, isFalse);
    expect(mutationEnablement, contains(false));
    controller.updateSelectedImage(top: 99);
    controller.duplicateSelectedObjects();
    controller.handleUndo();
    controller.setCellValue(0, 0, 'blocked');
    controller.addSheet(id: 's3', name: 'Blocked');
    controller.activateSheet(id: 's2');
    controller.setZoomRatio(2);
    expect(controller.objectSelection.activeImage?.top, 30);
    expect(controller.getSheet(id: 's1')!.cells, isEmpty);
    expect(controller.getSheet(id: 's3'), isNull);
    expect(controller.objectSelection.sheetId, 's1');
    expect(controller.getSheet(id: 's1')!.zoomRatio, 1);
    renders[0].complete(
      FortuneBarcodeRenderResult(bytes: base64Decode(_testPngBase64)),
    );
    expect(await first, isTrue);
    expect(controller.barcodePropertyRenderPending, isFalse);
    expect(controller.objectMutationEnabled, isTrue);
    expect(mutationEnablement.last, isTrue);
    await tester.pump();

    expect(
      controller.objectSelection.activeImage?.extraFields['barcodeText'],
      'FIRST',
    );
  });

  testWidgets('controller copies cuts and pastes mixed selected objects', (
    tester,
  ) async {
    String? clipboardText;
    var delayClipboardWrites = false;
    var failNextClipboardWrite = false;
    final clipboardWrites = <Completer<void>>[];
    var clipboardReads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            final text =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
            if (failNextClipboardWrite) {
              failNextClipboardWrite = false;
              throw PlatformException(code: 'clipboard-write-failed');
            }
            if (delayClipboardWrites) {
              final completer = Completer<void>();
              clipboardWrites.add(completer);
              await completer.future;
            }
            clipboardText = text;
            return null;
          case 'Clipboard.getData':
            clipboardReads += 1;
            return clipboardText == null
                ? null
                : <String, Object?>{'text': clipboardText};
        }
        return null;
      },
    );
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,AA==',
              left: 10,
              top: 20,
              width: 30,
              height: 40,
              extraFields: {
                fortuneImageObjectIdExtraKey: 'LOGO',
                fortuneSheetObjectZOrderExtraKey: 1.0,
              },
            ),
          ],
          lines: const [
            FortuneLine(
              id: 'line_1',
              x1: 20,
              y1: 30,
              x2: 50,
              y2: 60,
              zOrder: 2,
            ),
          ],
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 30,
              top: 40,
              width: 50,
              height: 60,
              zOrder: 3,
            ),
          ],
        ),
        FortuneSheet(
          id: 's2',
          name: 'Sheet2',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,AA==',
              left: 100,
              top: 100,
              width: 20,
              height: 20,
            ),
          ],
          lines: const [
            FortuneLine(id: 'line_1', x1: 100, y1: 100, x2: 120, y2: 120),
          ],
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 100,
              top: 100,
              width: 20,
              height: 20,
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
            controller: controller,
            imageObjectConnectionMode: FortuneObjectConnectionMode.structured,
          ),
        ),
      ),
    );
    controller.selectAllObjects();
    expect(await controller.copySelectedObjects(), isTrue);
    expect(await controller.pasteObjects(), isTrue);
    await tester.pump();

    final snapshot = controller.objectSelection;
    expect(snapshot.selectedKeys, hasLength(3));
    expect(snapshot.selectedKeys.map((key) => key.kind).toSet(), {
      FortuneSheetObjectKind.image,
      FortuneSheetObjectKind.line,
      FortuneSheetObjectKind.rectangle,
    });
    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    final sheet = painter().workbook.activeSheet;
    expect(sheet.images, hasLength(2));
    expect(sheet.lines, hasLength(2));
    expect(sheet.shapes, hasLength(2));
    expect((sheet.images.last.left, sheet.images.last.top), (22, 32));
    expect(sheet.images.last.extraFields[fortuneImageObjectIdExtraKey], 'LOGO');
    expect(
      (
        sheet.lines.last.x1,
        sheet.lines.last.y1,
        sheet.lines.last.x2,
        sheet.lines.last.y2,
      ),
      (32, 42, 62, 72),
    );
    expect((sheet.shapes.last.left, sheet.shapes.last.top), (42, 52));

    controller.handleUndo();
    await tester.pump();
    expect(painter().workbook.activeSheet.images, hasLength(1));
    expect(painter().workbook.activeSheet.lines, hasLength(1));
    expect(painter().workbook.activeSheet.shapes, hasLength(1));

    controller.selectAllObjects();
    expect(await controller.cutSelectedObjects(), isTrue);
    await tester.pump();
    expect(painter().workbook.activeSheet.images, isEmpty);
    expect(painter().workbook.activeSheet.lines, isEmpty);
    expect(painter().workbook.activeSheet.shapes, isEmpty);
    expect(await controller.pasteObjects(), isTrue);
    await tester.pump();
    final restored = painter().workbook.activeSheet;
    expect(restored.images.single.id, 'image_1');
    expect((restored.images.single.left, restored.images.single.top), (10, 20));
    expect(restored.lines.single.id, 'line_1');
    expect((restored.lines.single.x1, restored.lines.single.y1), (20, 30));
    expect(restored.shapes.single.id, 'rect_1');
    expect((restored.shapes.single.left, restored.shapes.single.top), (30, 40));
    expect(await controller.pasteObjects(), isFalse);

    delayClipboardWrites = true;
    final firstCopy = controller.copySelectedObjects();
    final secondCopy = controller.copySelectedObjects();
    await tester.pump();
    expect(clipboardWrites, hasLength(1));
    clipboardWrites[0].complete();
    expect(await firstCopy, isFalse);
    await tester.pump();
    expect(clipboardWrites, hasLength(2));
    clipboardWrites[1].complete();
    expect(await secondCopy, isTrue);
    final stableMarker = clipboardText;

    final staleCopy = controller.copySelectedObjects();
    final failingCopy = controller.copySelectedObjects();
    await tester.pump();
    expect(clipboardWrites, hasLength(3));
    clipboardWrites[2].complete();
    expect(await staleCopy, isFalse);
    await tester.pump();
    expect(clipboardWrites, hasLength(4));
    delayClipboardWrites = false;
    clipboardWrites[3].completeError(
      PlatformException(code: 'clipboard-write-failed'),
    );
    expect(await failingCopy, isFalse);
    expect(clipboardText, stableMarker);
    expect(await controller.pasteObjects(), isTrue);

    clipboardText = null;
    delayClipboardWrites = true;
    final nullBaselineStaleCopy = controller.copySelectedObjects();
    final nullBaselineFailingCopy = controller.copySelectedObjects();
    await tester.pump();
    expect(clipboardWrites, hasLength(5));
    delayClipboardWrites = false;
    failNextClipboardWrite = true;
    clipboardWrites[4].complete();
    expect(await nullBaselineStaleCopy, isFalse);
    expect(await nullBaselineFailingCopy, isFalse);
    expect(clipboardText, isEmpty);

    clipboardText = 'external cell text';
    final readsBeforeFallback = clipboardReads;
    expect(await controller.pasteObjects(), isFalse);
    await tester.pump();
    expect(clipboardReads, readsBeforeFallback + 1);
    expect(
      painter().workbook.activeSheet.cells[const FortuneCellCoord(0, 0)]?.value,
      'external cell text',
    );

    controller.selectAllObjects();
    expect(await controller.cutSelectedObjects(), isTrue);
    await tester.pump();
    controller.handleUndo();
    await tester.pump();
    final restoredAfterUndo = painter().workbook.activeSheet;
    final imageCount = restoredAfterUndo.images.length;
    final lineCount = restoredAfterUndo.lines.length;
    final shapeCount = restoredAfterUndo.shapes.length;
    expect(await controller.pasteObjects(), isFalse);
    await tester.pump();
    expect(painter().workbook.activeSheet.images, hasLength(imageCount));
    expect(painter().workbook.activeSheet.lines, hasLength(lineCount));
    expect(painter().workbook.activeSheet.shapes, hasLength(shapeCount));

    controller.selectAllObjects();
    expect(await controller.cutSelectedObjects(), isTrue);
    controller.activateSheet(id: 's2');
    await tester.pump();
    expect(await controller.pasteObjects(), isTrue);
    await tester.pump();
    final crossSheet = painter().workbook.activeSheet;
    expect(crossSheet.id, 's2');
    expect(crossSheet.images.first.id, 'image_1');
    expect(
      (crossSheet.images.first.left, crossSheet.images.first.top),
      (100, 100),
    );
    expect(
      crossSheet.images.map((image) => image.id).toSet(),
      hasLength(imageCount + 1),
    );
    expect(
      crossSheet.lines.map((line) => line.id).toSet(),
      hasLength(lineCount + 1),
    );
    expect(
      crossSheet.shapes.map((shape) => shape.id).toSet(),
      hasLength(shapeCount + 1),
    );
    expect((crossSheet.images[1].left, crossSheet.images[1].top), (10, 20));
  });

  testWidgets('structured duplicate preserves connection id with no options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,',
              left: 20,
              top: 20,
              width: 30,
              height: 30,
              extraFields: {fortuneImageObjectIdExtraKey: 'logo'},
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
            controller: controller,
            imageObjectConnectionMode: FortuneObjectConnectionMode.structured,
          ),
        ),
      ),
    );
    controller.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1'),
    );
    controller.duplicateSelectedObjects();
    await tester.pump();

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    expect(painter.workbook.activeSheet.images, hasLength(2));
    expect(
      painter
          .workbook
          .activeSheet
          .images
          .last
          .extraFields[fortuneImageObjectIdExtraKey],
      'logo',
    );
  });

  testWidgets('object layer panel applies selected shape properties', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          shapes: const [
            FortuneShape(
              id: 'round_1',
              kind: FortuneShapeKind.roundedRectangle,
              left: 20,
              top: 20,
              width: 60,
              height: 40,
              fillColor: '#FFFFFF',
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 2000,
              child: FortuneSheetCanvas(
                workbook: workbook,
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 2000,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('둥근 사각형 round_1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-top')),
      '-5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-rotation')),
      '405',
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('fortune-object-property-no-fill')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pump();
    expect(
      controller.objectSelection.activeKey,
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.roundedRectangle,
        'round_1',
      ),
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('fortune-object-property-top')),
          )
          .controller
          ?.text,
      '-5',
    );
    String propertyText(String name) {
      return tester
          .widget<TextField>(
            find.byKey(ValueKey('fortune-object-property-$name')),
          )
          .controller!
          .text;
    }

    expect(propertyText('left'), '20');
    expect(propertyText('width'), '60');
    expect(propertyText('height'), '40');
    expect(propertyText('rotation'), '405');
    expect(propertyText('strokeWidth'), '0.5');
    expect(propertyText('strokeColor'), '#000000');
    expect(propertyText('cornerRadius'), '0');
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('fortune-object-property-no-fill')),
          )
          .value,
      isTrue,
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('fortune-object-property-apply')),
        )
        .onPressed!();
    await tester.pump();

    final shape = controller.objectSelection.activeShape!;
    expect(shape.top, 0);
    expect(shape.rotationDegrees, 45);
    expect(shape.fillColor, isNull);
  });

  testWidgets('object layer panel applies selected image properties', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'image_1',
              src: 'data:image/png;base64,AA==',
              left: 20,
              top: 30,
              width: 80,
              height: 40,
              extraFields: {
                fortuneImageObjectIdExtraKey: 'OLD',
                'crop': {'left': 0.1},
              },
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 2000,
              child: FortuneSheetCanvas(
                workbook: workbook,
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 2000,
              child: FortuneObjectLayerPanel(
                controller: controller,
                imageObjectIds: const ['NEW'],
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('이미지 image_1'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('fortune-object-property-aspect-lock')),
    );
    await tester.pump();
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('fortune-object-property-connectionId')),
        )
        .onChanged!('NEW');
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-top')),
      '-5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-width')),
      '120',
    );
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-rotation')),
      '405',
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('fortune-object-property-apply')),
        )
        .onPressed!();
    await tester.pump();

    final image = controller.objectSelection.activeImage!;
    expect((image.top, image.width, image.height), (0, 120, 40));
    expect(image.extraFields['rotation'], 45);
    expect(image.extraFields[fortuneImageObjectIdExtraKey], 'NEW');
    expect(image.extraFields['crop'], {'left': 0.1});
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('fortune-object-property-aspect-lock')),
          )
          .value,
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('fortune-object-property-aspect-lock')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-width')),
      '150',
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('fortune-object-property-apply')),
        )
        .onPressed!();
    await tester.pump();

    expect(
      (
        controller.objectSelection.activeImage!.width,
        controller.objectSelection.activeImage!.height,
      ),
      (150, 50),
    );
  });

  testWidgets('controller finalizes or discards the active property draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 1200,
              child: FortuneSheetCanvas(
                workbook: FortuneWorkbook(
                  settings: const FortuneSettings(
                    showToolbar: false,
                    showFormulaBar: false,
                  ),
                  sheets: [
                    FortuneSheet(
                      id: 's1',
                      name: 'Sheet1',
                      shapes: const [
                        FortuneShape(
                          id: 'shape_1',
                          kind: FortuneShapeKind.rectangle,
                          left: 10,
                          top: 10,
                          width: 40,
                          height: 20,
                        ),
                        FortuneShape(
                          id: 'shape_2',
                          kind: FortuneShapeKind.rectangle,
                          left: 70,
                          top: 10,
                          width: 30,
                          height: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 1200,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('사각형 shape_1'));
    await tester.pump();
    final widthField = find.byKey(
      const ValueKey('fortune-object-property-width'),
    );
    await tester.enterText(widthField, '75');
    expect(controller.hasActiveObjectPropertyDraft, isTrue);
    expect(
      controller.activePropertyDraftProjection,
      FortunePropertyDraftProjection.change,
    );
    expect(controller.projectedCanUndo, isTrue);
    expect(controller.projectedCanRedo, isFalse);

    expect(controller.finalizeActiveObjectPropertyDraft(), isTrue);
    await tester.pump();
    expect(controller.objectSelection.activeShape!.width, 75);
    expect(controller.hasActiveObjectPropertyDraft, isFalse);
    expect(controller.projectedCanUndo, isTrue);

    await tester.enterText(widthField, 'invalid');
    expect(
      controller.activePropertyDraftProjection,
      FortunePropertyDraftProjection.invalid,
    );
    expect(controller.projectedCanUndo, isTrue);
    expect(controller.projectedCanRedo, isFalse);
    expect(controller.finalizeActiveObjectPropertyDraft(), isTrue);
    await tester.pump();
    expect(controller.objectSelection.activeShape!.width, 75);
    expect(tester.widget<TextField>(widthField).controller!.text, '75');
    expect(controller.hasActiveObjectPropertyDraft, isFalse);

    controller.handleUndo();
    await tester.pump();
    expect(controller.objectSelection.activeShape!.width, 40);
    expect(controller.projectedCanUndo, isFalse);
    expect(controller.projectedCanRedo, isTrue);

    await tester.enterText(widthField, '80');
    expect(controller.projectedCanUndo, isTrue);
    expect(controller.projectedCanRedo, isFalse);

    controller.selectObject(
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'shape_2',
      ),
    );
    await tester.pump();
    expect(controller.hasActiveObjectPropertyDraft, isFalse);
    expect(controller.objectSelection.activeShape!.id, 'shape_2');
    controller.selectObject(
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'shape_1',
      ),
    );
    await tester.pump();
    expect(controller.objectSelection.activeShape!.width, 80);
    await tester.enterText(widthField, 'invalid');
    controller.selectObject(
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'shape_2',
      ),
    );
    await tester.pump();
    expect(controller.hasActiveObjectPropertyDraft, isFalse);
    expect(controller.objectSelection.activeShape!.id, 'shape_2');
    controller.selectObject(
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'shape_1',
      ),
    );
    await tester.pump();
    expect(controller.objectSelection.activeShape!.width, 80);
  });

  testWidgets('property Escape discards draft and ignores delayed submit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    var changeCount = 0;
    var opCount = 0;
    final listenerStates = <String>[];
    controller.addListener(() {
      listenerStates.add(
        '${controller.hasActiveObjectPropertyDraft}/'
        '${controller.activePropertyDraftProjection}',
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 1200,
              child: FortuneSheetCanvas(
                workbook: FortuneWorkbook(
                  settings: const FortuneSettings(
                    showToolbar: false,
                    showFormulaBar: false,
                  ),
                  sheets: [
                    FortuneSheet(
                      id: 's1',
                      name: 'Sheet1',
                      shapes: const [
                        FortuneShape(
                          id: 'shape_1',
                          kind: FortuneShapeKind.rectangle,
                          left: 10,
                          top: 10,
                          width: 40,
                          height: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                controller: controller,
                onChange: (_) => changeCount += 1,
                onOp: (_) => opCount += 1,
              ),
            ),
            SizedBox(
              width: 300,
              height: 1200,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('사각형 shape_1'));
    await tester.pump();
    final widthField = find.byKey(
      const ValueKey('fortune-object-property-width'),
    );

    await tester.enterText(widthField, '80');
    await tester.pump();
    changeCount = 0;
    opCount = 0;
    listenerStates.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<TextField>(widthField).controller!.text, '40');
    expect(controller.hasActiveObjectPropertyDraft, isFalse);
    expect(controller.objectSelection.activeShape!.width, 40);
    expect(controller.projectedCanUndo, isFalse);
    expect(changeCount, 0);
    expect(opCount, 0);
    expect(listenerStates, isEmpty);

    await tester.enterText(widthField, 'invalid');
    await tester.pump();
    final delayedSubmit = tester.widget<TextField>(widthField).onSubmitted!;
    listenerStates.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<TextField>(widthField).controller!.text, '40');
    final editable = tester.widget<EditableText>(
      find.descendant(of: widthField, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);

    delayedSubmit('invalid');
    await tester.pump();
    expect(tester.widget<TextField>(widthField).controller!.text, '40');
    expect(controller.hasActiveObjectPropertyDraft, isFalse);
    expect(controller.objectSelection.activeShape!.width, 40);
    expect(controller.projectedCanUndo, isFalse);
    expect(changeCount, 0);
    expect(opCount, 0);
    expect(listenerStates, isEmpty);
  });

  testWidgets('object layer rows drag selected objects by exact drop side', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 10,
              top: 10,
              width: 20,
              height: 20,
              zOrder: 1,
            ),
            FortuneShape(
              id: 'rect_2',
              kind: FortuneShapeKind.rectangle,
              left: 40,
              top: 10,
              width: 20,
              height: 20,
              zOrder: 2,
            ),
            FortuneShape(
              id: 'rect_3',
              kind: FortuneShapeKind.rectangle,
              left: 70,
              top: 10,
              width: 20,
              height: 20,
              zOrder: 3,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 700,
              child: FortuneSheetCanvas(
                workbook: workbook,
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 700,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );

    final source = find.byKey(
      const ValueKey('fortune-object-row-rectangle-rect_3'),
    );
    final target = find.byKey(
      const ValueKey('fortune-object-row-rectangle-rect_1'),
    );
    await tester.tap(source);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(source));
    await gesture.moveTo(tester.getBottomLeft(target) + const Offset(40, -2));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(controller.objectSelection.objects.map((object) => object.key), [
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_3'),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_2'),
    ]);
  });

  testWidgets('shape context menu opens the selected property panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var panelOpenRequests = 0;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 100,
              top: 50,
              width: 80,
              height: 30,
              fillColor: '#FFFFFF',
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
            onOpenObjectPanel: () => panelOpenRequests += 1,
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final canvasTopLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final contextGesture = await tester.startGesture(
      canvasTopLeft + const Offset(186, 85),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await contextGesture.up();
    await tester.pump();

    expect(painter().contextMenuItems, [
      fortuneContextEditRectangleCommand,
      '|',
      fortuneContextDuplicateImageCommand,
      fortuneContextDeleteImageCommand,
      '|',
      fortuneContextBringToFrontCommand,
      fortuneContextBringForwardCommand,
      fortuneContextSendBackwardCommand,
      fortuneContextSendToBackCommand,
    ]);
    final editRect = fortuneContextMenuItemRect(
      painter().contextMenuAt!,
      fortuneContextEditRectangleCommand,
      painter().contextMenuItems,
    )!;
    await tester.tapAt(canvasTopLeft + editRect.center);
    await tester.pump();

    expect(panelOpenRequests, 1);
    expect(painter().contextMenuAt, isNull);
  });

  testWidgets('shape context duplicate finalizes property draft first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            SizedBox(
              width: 600,
              height: 700,
              child: FortuneSheetCanvas(
                workbook: FortuneWorkbook(
                  settings: const FortuneSettings(
                    showToolbar: false,
                    showFormulaBar: false,
                  ),
                  sheets: [
                    FortuneSheet(
                      id: 's1',
                      name: 'Sheet1',
                      shapes: const [
                        FortuneShape(
                          id: 'rect_1',
                          kind: FortuneShapeKind.rectangle,
                          left: 100,
                          top: 50,
                          width: 80,
                          height: 30,
                          fillColor: '#FFFFFF',
                        ),
                      ],
                    ),
                  ],
                ),
                controller: controller,
              ),
            ),
            SizedBox(
              width: 300,
              height: 700,
              child: FortuneObjectLayerPanel(controller: controller),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('사각형 rect_1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-width')),
      '90',
    );

    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;

    final canvasTopLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.sendEventToBinding(
      PointerDownEvent(
        position: canvasTopLeft + const Offset(186, 85),
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    final duplicateRect = fortuneContextMenuItemRect(
      painter().contextMenuAt!,
      fortuneContextDuplicateImageCommand,
      painter().contextMenuItems,
    )!;
    await tester.tapAt(canvasTopLeft + duplicateRect.center);
    await tester.pump();

    expect(controller.getSheet()!.shapes.map((shape) => shape.width), [90, 90]);
    controller.handleUndo();
    await tester.pump();
    expect(controller.getSheet()!.shapes.map((shape) => shape.width), [90]);
    controller.handleUndo();
    await tester.pump();
    expect(controller.getSheet()!.shapes.map((shape) => shape.width), [80]);
  });

  testWidgets('shape active toolbar opens the selected property panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var panelOpenRequests = 0;
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 100,
              top: 50,
              width: 80,
              height: 30,
              fillColor: '#FFFFFF',
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
            onOpenObjectPanel: () => panelOpenRequests += 1,
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final canvasTopLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(canvasTopLeft + const Offset(186, 85));
    await tester.pump();

    const key = FortuneSheetObjectKey(
      FortuneSheetObjectKind.rectangle,
      'rect_1',
    );
    expect(painter().activeObjectKey, key);
    final items = fortuneActiveTypedObjectToolbarItems(key);
    final editRect = fortuneActiveImageToolbarItemRect(
      ui.Rect.fromLTWH(146, 70, 80, 30),
      const Size(900, 700),
      fortuneContextEditRectangleCommand,
      items,
    )!;
    await tester.tapAt(canvasTopLeft + editRect.center);
    await tester.pump();

    expect(panelOpenRequests, 1);
    expect(painter().activeObjectKey, key);
  });
}
