import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_object_layer_panel.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  testWidgets('controller publishes immutable exact object selection snapshots', (
    tester,
  ) async {
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
  });

  testWidgets('object layer panel selects and deletes mixed typed objects', (
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
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'rect_1',
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.text('이미지 image_1'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.objectSelection.selectedKeys, {
      const FortuneSheetObjectKey(
        FortuneSheetObjectKind.rectangle,
        'rect_1',
      ),
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
        const FortuneSheetObjectKey(
          FortuneSheetObjectKind.rectangle,
          'rect_1',
        ),
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
          child: FortuneSheetCanvas(
            workbook: workbook,
            controller: controller,
          ),
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
}