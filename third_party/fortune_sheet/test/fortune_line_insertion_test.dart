import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
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

void main() {
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
}