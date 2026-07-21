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

    await tester.tap(find.byTooltip('선택한 개체 삭제'));
    await tester.pump();
    expect(find.text('사각형 rect_1'), findsNothing);
    expect(find.text('이미지 image_1'), findsNothing);
    expect(controller.objectSelection.selectedKeys, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}