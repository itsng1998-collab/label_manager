import 'dart:ui';
import 'dart:ui' as ui show Rect;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_codec.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

Offset _toolbarItemCenter(
  String key, {
  required double width,
  required List<String> items,
}) {
  for (final entry in fortuneVisibleToolbarItemRects(width, items: items)) {
    if (entry.key == key) {
      return entry.value.center;
    }
  }
  fail('toolbar item not found: $key');
}

ui.Rect _toolbarItemRect(
  String key, {
  required double width,
  required List<String> items,
}) {
  for (final entry in fortuneVisibleToolbarItemRects(width, items: items)) {
    if (entry.key == key) {
      return entry.value;
    }
  }
  fail('toolbar item not found: $key');
}

void main() {
  testWidgets('line and shape tools keep precise cursor until used or escaped', (
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
        toolbarItems: [
          fortuneToolbarLineCommand,
          fortuneToolbarRectangleCommand,
          fortuneToolbarRoundedRectangleCommand,
          fortuneToolbarEllipseCommand,
        ],
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

    MouseCursor cursor() => tester
        .widget<MouseRegion>(
          find.descendant(
            of: find.byType(FortuneSheetCanvas),
            matching: find.byType(MouseRegion),
          ).first,
        )
        .cursor;
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
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: topLeft + const Offset(120, 120));

    for (final command in [
      fortuneToolbarLineCommand,
      fortuneToolbarRectangleCommand,
      fortuneToolbarRoundedRectangleCommand,
      fortuneToolbarEllipseCommand,
    ]) {
      await tester.tapAt(
        topLeft +
            _toolbarItemCenter(
              command,
              width: 900,
              items: workbook.settings.toolbarItems,
            ),
      );
      await tester.pump();
      await mouse.moveTo(topLeft + const Offset(150, 150));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.precise);
      expect(painter().toolbarActiveKeys, contains(command));

      await mouse.moveTo(topLeft + const Offset(220, 180));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.precise);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(cursor(), SystemMouseCursors.basic);
      expect(painter().toolbarActiveKeys, isEmpty);
    }

    await tester.tapAt(
      topLeft +
          _toolbarItemCenter(
            fortuneToolbarEllipseCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();
    await tester.dragFrom(
      topLeft + const Offset(150, 150),
      const Offset(50, 30),
    );
    await tester.pump();
    expect(cursor(), SystemMouseCursors.basic);
    await mouse.removePointer();
  });

  testWidgets('shape popup selection immediately starts insertion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const toolbarItems = [fortuneToolbarShapeCommand];
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(toolbarItems: toolbarItems),
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
    MouseCursor cursor() => tester
        .widget<MouseRegion>(
          find.descendant(
            of: find.byType(FortuneSheetCanvas),
            matching: find.byType(MouseRegion),
          ).first,
        )
        .cursor;

    expect(fortuneToolbarShapePopupCommands, [
      fortuneToolbarRectangleCommand,
      fortuneToolbarRoundedRectangleCommand,
      fortuneToolbarEllipseCommand,
    ]);
    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final toolbarRect = _toolbarItemRect(
      fortuneToolbarShapeCommand,
      width: 900,
      items: toolbarItems,
    );
    await tester.tapAt(
      topLeft + fortuneToolbarComboArrowRect(toolbarRect).center,
    );
    await tester.pump();
    final popupWidth = fortuneToolbarPopupWidthFor(
      fortuneToolbarShapeCommand,
    );
    final popupLeft = fortuneToolbarPopupLeftFor(
      key: fortuneToolbarShapeCommand,
      itemRect: toolbarRect,
      viewportWidth: 900,
      popupWidth: popupWidth,
    );
    final roundedRectangleIndex = fortuneToolbarShapePopupCommands.indexOf(
      fortuneToolbarRoundedRectangleCommand,
    );
    await tester.tapAt(
      topLeft +
          Offset(
            popupLeft + popupWidth / 2,
            fortuneToolbarPopupTop +
                fortuneToolbarPopupContentTopPaddingFor(
                  fortuneToolbarShapeCommand,
                ) +
                fortuneToolbarPopupRowHeightFor(fortuneToolbarShapeCommand) *
                    (roundedRectangleIndex + 0.5),
          ),
    );
    await tester.pump();

    expect(cursor(), SystemMouseCursors.precise);
    expect(painter().toolbarActiveKeys, {fortuneToolbarShapeCommand});
    await tester.dragFrom(
      topLeft + const Offset(150, 150),
      const Offset(50, 30),
    );
    await tester.pump();
    final shape = painter().workbook.activeSheet.shapes.single;
    expect(shape.kind, FortuneShapeKind.roundedRectangle);
    expect(shape.cornerRadiusMm, closeTo(fortuneLogicalPixelsToMillimeters(6), 1e-9));
    expect(
      fortuneMillimetersToLogicalPixels(shape.strokeWidthMm),
      closeTo(1, 1e-9),
    );
    expect(cursor(), SystemMouseCursors.basic);
    expect(painter().toolbarActiveKeys, isEmpty);
  });

  testWidgets('line toolbar drag inserts one topmost line and exits mode', (
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
        toolbarItems: [fortuneToolbarLineCommand],
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          shapes: const [
            FortuneShape(
              id: 'rect_1',
              kind: FortuneShapeKind.rectangle,
              left: 0,
              top: 0,
              width: 10,
              height: 10,
              zOrder: 4,
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
          _toolbarItemCenter(
            fortuneToolbarLineCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();

    await tester.dragFrom(topLeft + const Offset(100, 100), const Offset(80, 40));
    await tester.pump();

    final line = painter().workbook.activeSheet.lines.single;
    expect(line.id, 'line_1');
    expect(line.zOrder, 5);
    expect(line.x2, greaterThan(line.x1));
    expect(line.y2, greaterThan(line.y1));
    expect(
      fortuneMillimetersToLogicalPixels(line.strokeWidthMm),
      closeTo(1, 1e-9),
    );
    expect(painter().toolbarActiveKeys, isEmpty);

    await tester.dragFrom(topLeft + const Offset(120, 140), const Offset(60, 30));
    await tester.pump();

    expect(painter().workbook.activeSheet.lines, hasLength(1));
  });

  testWidgets('short line drag keeps insertion mode and escape cancels it', (
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
        toolbarItems: [fortuneToolbarLineCommand],
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
          _toolbarItemCenter(
            fortuneToolbarLineCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();
    await tester.dragFrom(topLeft + const Offset(100, 100), const Offset(1, 0));
    await tester.pump();

    expect(painter().workbook.activeSheet.lines, isEmpty);

    await tester.dragFrom(topLeft + const Offset(100, 100), const Offset(40, 0));
    await tester.pump();
    expect(painter().workbook.activeSheet.lines, hasLength(1));

    await tester.tapAt(
      topLeft +
          _toolbarItemCenter(
            fortuneToolbarLineCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.dragFrom(topLeft + const Offset(100, 120), const Offset(40, 0));
    await tester.pump();

    expect(painter().workbook.activeSheet.lines, hasLength(1));
  });

  testWidgets('line insertion keeps the actual release outside data bounds', (
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
        toolbarItems: [fortuneToolbarLineCommand],
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
          _toolbarItemCenter(
            fortuneToolbarLineCommand,
            width: 900,
            items: workbook.settings.toolbarItems,
          ),
    );
    await tester.pump();
    await tester.dragFrom(
      topLeft + const Offset(100, 120),
      const Offset(-90, 0),
    );
    await tester.pump();

    final line = painter().workbook.activeSheet.lines.single;
    expect(line.x2, lessThan(0));
  });

  testWidgets('shape combo primary drag inserts the committed preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const toolbarItems = [fortuneToolbarShapeCommand];
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(toolbarItems: toolbarItems),
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
          _toolbarItemCenter(
            fortuneToolbarShapeCommand,
            width: 900,
            items: toolbarItems,
          ),
    );
    await tester.pump();
    await tester.dragFrom(
      topLeft + const Offset(100, 100),
      const Offset(50, 30),
    );
    await tester.pump();

    final shapes = painter().workbook.activeSheet.shapes;
    expect(shapes.map((shape) => shape.kind), [FortuneShapeKind.rectangle]);
    expect(shapes.map((shape) => shape.id), ['rect_1']);
    expect(shapes.map((shape) => shape.zOrder), [1]);
    expect(shapes.every((shape) => shape.width > 0 && shape.height > 0), isTrue);
  });

  testWidgets('filled shape body click selects its exact typed key', (
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
              left: 50,
              top: 50,
              width: 40,
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

    final before = FortuneSheetCodec.workbookToJson(painter().workbook);
    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(116, 85));
    await tester.pump();

    expect(
      painter().activeObjectKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
    );
    expect(FortuneSheetCodec.workbookToJson(painter().workbook), before);

    await tester.dragFrom(
      topLeft + const Offset(116, 85),
      const Offset(20, 10),
    );
    await tester.pump();

    final moved = painter().workbook.activeSheet.shapes.single;
    expect(moved.left, 70);
    expect(moved.top, 60);
    expect(moved.width, 40);
    expect(moved.height, 30);
    expect(moved.zOrder, 0);

    final beforeResize = FortuneSheetCodec.workbookToJson(painter().workbook);
    final resizeGesture = await tester.startGesture(
      topLeft + const Offset(156, 110),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await resizeGesture.moveBy(const Offset(20, 10));
    await tester.pump();

    expect(FortuneSheetCodec.workbookToJson(painter().workbook), beforeResize);
    var draft = painter().objectGestureShapeDraft;
    expect((draft?.width, draft?.height), (60, 40));

    await resizeGesture.up();
    await tester.pump();
    var resized = painter().workbook.activeSheet.shapes.single;
    expect((resized.left, resized.top), (70, 60));
    expect((resized.width, resized.height), (60, 40));

    final beforeRotation = FortuneSheetCodec.workbookToJson(painter().workbook);
    final rotationGesture = await tester.startGesture(
      topLeft + const Offset(146, 60),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await rotationGesture.moveBy(const Offset(40, 40));
    await tester.pump();

    expect(FortuneSheetCodec.workbookToJson(painter().workbook), beforeRotation);
    draft = painter().objectGestureShapeDraft;
    expect(draft?.rotationDegrees, closeTo(90, 1e-8));

    await rotationGesture.up();
    await tester.pump();
    resized = painter().workbook.activeSheet.shapes.single;
    expect(resized.rotationDegrees, closeTo(90, 1e-8));
  });

  testWidgets('Shift shape resize stops before top-boundary re-entry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 900,
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
                      left: 500,
                      top: 10,
                      width: 100,
                      height: 40,
                      fillColor: '#FFFFFF',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;

    final canvasTopLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(canvasTopLeft + const Offset(596, 50));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final resize = await tester.startGesture(
      canvasTopLeft + const Offset(546, 30),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await resize.moveTo(canvasTopLeft + const Offset(146, 70));
    await tester.pump();

    final draft = painter().objectGestureShapeDraft!;
    expect(draft.left, closeTo(475, 1e-6));
    expect(draft.top, closeTo(0, 1e-6));
    expect(draft.width, closeTo(125, 1e-6));
    expect(draft.height, closeTo(50, 1e-6));

    await resize.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    final committed = painter().workbook.activeSheet.shapes.single;
    expect(committed.left, closeTo(475, 1e-6));
    expect(committed.top, closeTo(0, 1e-6));
    expect(committed.width, closeTo(125, 1e-6));
    expect(committed.height, closeTo(50, 1e-6));
  });

  testWidgets('active line endpoint drag is transient and commits one endpoint', (
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
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          lines: const [
            FortuneLine(
              id: 'line_1',
              x1: 50,
              y1: 50,
              x2: 90,
              y2: 80,
              zOrder: 3,
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
    await tester.tapAt(topLeft + const Offset(116, 85));
    await tester.pump();
    expect(
      painter().activeObjectKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );

    final before = FortuneSheetCodec.workbookToJson(painter().workbook);
    final gesture = await tester.startGesture(
      topLeft + const Offset(96, 70),
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -50));
    await tester.pump();

    expect(FortuneSheetCodec.workbookToJson(painter().workbook), before);
    final draft = painter().objectGestureLineDraft;
    expect((draft?.x1, draft?.y1, draft?.x2, draft?.y2), (30, 0, 90, 80));

    await gesture.up();
    await tester.pump();

    final moved = painter().workbook.activeSheet.lines.single;
    expect((moved.x1, moved.y1), (30, 0));
    expect((moved.x2, moved.y2), (90, 80));
    expect(moved.zOrder, 3);

    final beforeClamp = FortuneSheetCodec.workbookToJson(painter().workbook);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FortuneSheetCodec.workbookToJson(painter().workbook), beforeClamp);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    var keyboardMoved = painter().workbook.activeSheet.lines.single;
    expect((keyboardMoved.x1, keyboardMoved.x2), (29, 89));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    keyboardMoved = painter().workbook.activeSheet.lines.single;
    expect((keyboardMoved.x1, keyboardMoved.x2), (30, 90));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    keyboardMoved = painter().workbook.activeSheet.lines.single;
    expect((keyboardMoved.y1, keyboardMoved.y2), (10, 90));
  });

  testWidgets('read-only line drag and modifier handle toggle do not mutate', (
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
        allowEdit: false,
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          lines: const [
            FortuneLine(id: 'line_1', x1: 50, y1: 50, x2: 90, y2: 80),
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
    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(116, 85));
    await tester.pump();
    final before = FortuneSheetCodec.workbookToJson(painter().workbook);

    await tester.dragFrom(
      topLeft + const Offset(96, 70),
      const Offset(20, 20),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(FortuneSheetCodec.workbookToJson(painter().workbook), before);
    expect(painter().objectGestureLineDraft, isNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(topLeft + const Offset(96, 70));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      painter().activeObjectKey,
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    expect(painter().objectGestureLineDraft, isNull);
    expect(FortuneSheetCodec.workbookToJson(painter().workbook), before);
  });

  testWidgets('overlapping line endpoints drag the nearest endpoint', (
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
        showToolbar: false,
        showFormulaBar: false,
      ),
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          lines: const [
            FortuneLine(id: 'line_1', x1: 50, y1: 50, x2: 54, y2: 50),
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
    FortuneSheetPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(98, 70));
    await tester.pump();

    await tester.dragFrom(
      topLeft + const Offset(100, 70),
      const Offset(20, 10),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    final line = painter().workbook.activeSheet.lines.single;
    expect((line.x1, line.y1), (50, 50));
    expect((line.x2, line.y2), (74, 60));
  });
}