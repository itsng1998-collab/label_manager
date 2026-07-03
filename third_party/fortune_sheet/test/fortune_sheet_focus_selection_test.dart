import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_app.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  testWidgets('selection highlight is painted only while sheet is focused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(180, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final unfocusedPixels = await _paintSelection(
      tester,
      sheetFocused: false,
    );
    expect(_countSelectionPixels(unfocusedPixels), 0);

    final focusedPixels = await _paintSelection(tester, sheetFocused: true);
    expect(_countSelectionPixels(focusedPixels), greaterThan(0));
  });

  testWidgets('controller can remove sheet focus after file import applies', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    const captureKey = ValueKey('fortune-sheet-app-focus-capture');
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        row: 4,
        column: 4,
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: FortuneSheetApp(
            workbook: workbook,
            controller: controller,
            showFormulaBar: false,
            showSheetTabs: false,
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(75, 55));
    await tester.pump();

    final focusedPixels = await _capturePixels(tester, find.byKey(captureKey));
    expect(_countSelectionPixels(focusedPixels), greaterThan(0));

    controller.updateSheet([
      FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        rowCount: 4,
        columnCount: 4,
      ),
    ]);
    controller.unfocusSheet();
    await tester.pump();

    final unfocusedPixels = await _capturePixels(
      tester,
      find.byKey(captureKey),
    );
    expect(_countSelectionPixels(unfocusedPixels), 0);
  });

  testWidgets('controller keeps selection hidden after the next frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    const captureKey = ValueKey('fortune-sheet-app-post-frame-focus-capture');
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        statisticBarHeight: 0,
        rowHeaderWidth: 40,
        columnHeaderHeight: 20,
        row: 4,
        column: 4,
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: FortuneSheetApp(
            workbook: workbook,
            controller: controller,
            showFormulaBar: false,
            showSheetTabs: false,
          ),
        ),
      ),
    );
    await tester.tapAt(const Offset(75, 55));
    await tester.pump();
    expect(
      _countSelectionPixels(await _capturePixels(tester, find.byKey(captureKey))),
      greaterThan(0),
    );

    controller.unfocusSheet();
    await tester.pump();
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));
    expect(_countSelectionPixels(pixels), 0);
  });
}

Future<({ByteData data, int width})> _paintSelection(
  WidgetTester tester, {
  required bool sheetFocused,
}) async {
  const captureKey = ValueKey('fortune-sheet-selection-focus-capture');
  const settings = FortuneSettings(
    showToolbar: false,
    showFormulaBar: false,
    showSheetTabs: false,
    statisticBarHeight: 0,
    rowHeaderWidth: 40,
    columnHeaderHeight: 20,
    defaultRowHeight: 24,
    defaultColWidth: 60,
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
      child: RepaintBoundary(
        key: captureKey,
        child: CustomPaint(
          size: const Size(180, 120),
          painter: FortuneSheetPainter(
            workbook: workbook,
            selection: const FortuneSelection(row: 0, column: 0),
            scrollOffset: Offset.zero,
            sheetTabScrollOffset: 0,
            textDirection: TextDirection.ltr,
            sheetFocused: sheetFocused,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _capturePixels(tester, find.byKey(captureKey));
}

Future<({ByteData data, int width})> _capturePixels(
  WidgetTester tester,
  Finder finder,
) async {
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(finder);
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  if (image == null) {
    fail('Failed to capture repaint boundary image.');
  }
  final data = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (data == null) {
    fail('Failed to read repaint boundary pixels.');
  }
  return (data: data, width: image.width);
}

int _countSelectionPixels(({ByteData data, int width}) pixels) {
  var count = 0;
  for (var offset = 0; offset < pixels.data.lengthInBytes; offset += 4) {
    if (pixels.data.getUint8(offset) == 0x01 &&
        pixels.data.getUint8(offset + 1) == 0x88 &&
        pixels.data.getUint8(offset + 2) == 0xfb &&
        pixels.data.getUint8(offset + 3) == 0xff) {
      count += 1;
    }
  }
  return count;
}
