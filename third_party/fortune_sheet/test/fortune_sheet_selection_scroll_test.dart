import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  testWidgets('canvas accepts keyboard input immediately after mount', (
    tester,
  ) async {
    const settings = FortuneSettings(
      showToolbar: false,
      showFormulaBar: false,
      showSheetTabs: false,
      statisticBarHeight: 0,
      rowHeaderWidth: 40,
      columnHeaderHeight: 20,
      defaultRowHeight: 20,
      defaultColWidth: 50,
      row: 4,
      column: 4,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 220,
          height: 160,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );
    await tester.pump();

    FortuneSheetPainter painter() {
      return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
          as FortuneSheetPainter;
    }

    expect(painter().selection.row, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(painter().selection.row, 1);
  });

  testWidgets(
    'wheel does not scroll into blank space when sheet fits viewport',
    (tester) async {
      const settings = FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        defaultRowHeight: 20,
        defaultColWidth: 50,
        row: 2,
        column: 2,
      );
      final workbook = FortuneWorkbook(
        settings: settings,
        sheets: [
          FortuneSheet(id: 's1', name: 'Sheet1', rowCount: 2, columnCount: 2),
        ],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: FortuneSheetCanvas(workbook: workbook),
          ),
        ),
      );

      FortuneSheetPainter painter() {
        return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
            as FortuneSheetPainter;
      }

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: topLeft + const Offset(80, 60),
          scrollDelta: const Offset(120, 120),
        ),
      );
      await tester.pump();

      expect(painter().scrollOffset, Offset.zero);
    },
  );

  testWidgets(
    'wheel scrolls vertically and horizontally when sheet overflows',
    (tester) async {
      const settings = FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        defaultRowHeight: 20,
        defaultColWidth: 50,
        row: 30,
        column: 20,
      );
      final workbook = FortuneWorkbook(
        settings: settings,
        sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 180,
            height: 120,
            child: FortuneSheetCanvas(workbook: workbook),
          ),
        ),
      );

      FortuneSheetPainter painter() {
        return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
            as FortuneSheetPainter;
      }

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: topLeft + const Offset(80, 60),
          scrollDelta: const Offset(0, 120),
        ),
      );
      await tester.pump();

      expect(painter().scrollOffset.dy, greaterThan(0));
      expect(painter().scrollOffset.dx, 0);

      await tester.pump(const Duration(milliseconds: 60));
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: topLeft + const Offset(80, 60),
          scrollDelta: const Offset(120, 0),
        ),
      );
      await tester.pump();

      expect(painter().scrollOffset.dx, greaterThan(0));
    },
  );

  testWidgets('sheet scrollbars can be dragged vertically and horizontally', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(220, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const settings = FortuneSettings(
      showToolbar: false,
      showFormulaBar: false,
      showSheetTabs: false,
      statisticBarHeight: 0,
      rowHeaderWidth: 40,
      columnHeaderHeight: 20,
      defaultRowHeight: 20,
      defaultColWidth: 50,
      row: 30,
      column: 20,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 220,
          height: 160,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
          as FortuneSheetPainter;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final verticalDrag = await tester.startGesture(
      topLeft + const Offset(216, 36),
    );
    await verticalDrag.moveBy(const Offset(0, 60));
    await verticalDrag.up();
    await tester.pump();

    expect(painter().scrollOffset.dy, greaterThan(0));
    expect(painter().scrollOffset.dx, 0);

    final horizontalDrag = await tester.startGesture(
      topLeft + const Offset(56, 156),
    );
    await horizontalDrag.moveBy(const Offset(80, 0));
    await horizontalDrag.up();
    await tester.pump();

    expect(painter().scrollOffset.dx, greaterThan(0));
  });

  testWidgets('held arrow key repeat keeps moving the selection', (
    tester,
  ) async {
    const settings = FortuneSettings(
      showToolbar: false,
      showFormulaBar: false,
      showSheetTabs: false,
      statisticBarHeight: 0,
      rowHeaderWidth: 40,
      columnHeaderHeight: 20,
      defaultRowHeight: 20,
      defaultColWidth: 50,
      row: 20,
      column: 8,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 220,
          height: 160,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
          as FortuneSheetPainter;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(65, 30));
    await tester.pump();

    expect(painter().selection.row, 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(painter().selection.row, 3);
  });

  testWidgets(
    'arrow key movement scrolls vertically to keep selection visible',
    (tester) async {
      tester.view.physicalSize = const Size(180, 120);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const settings = FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        defaultRowHeight: 20,
        defaultColWidth: 50,
        row: 20,
        column: 8,
      );
      final workbook = FortuneWorkbook(
        settings: settings,
        sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 180,
            height: 120,
            child: FortuneSheetCanvas(workbook: workbook),
          ),
        ),
      );

      FortuneSheetPainter painter() {
        return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
            as FortuneSheetPainter;
      }

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.tapAt(topLeft + const Offset(65, 110));
      await tester.pump();

      expect(painter().selection.row, 4);
      expect(painter().scrollOffset.dy, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      expect(painter().selection.row, 5);
      expect(painter().scrollOffset.dy, greaterThan(0));
    },
  );

  testWidgets(
    'arrow key movement scrolls horizontally to keep selection visible',
    (tester) async {
      tester.view.physicalSize = const Size(190, 120);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const settings = FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        defaultRowHeight: 20,
        defaultColWidth: 50,
        row: 8,
        column: 20,
      );
      final workbook = FortuneWorkbook(
        settings: settings,
        sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 190,
            height: 120,
            child: FortuneSheetCanvas(workbook: workbook),
          ),
        ),
      );

      FortuneSheetPainter painter() {
        return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
            as FortuneSheetPainter;
      }

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.tapAt(topLeft + const Offset(165, 30));
      await tester.pump();

      expect(painter().selection.column, 2);
      expect(painter().scrollOffset.dx, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(painter().selection.column, 3);
      expect(painter().scrollOffset.dx, greaterThan(0));
    },
  );
}
