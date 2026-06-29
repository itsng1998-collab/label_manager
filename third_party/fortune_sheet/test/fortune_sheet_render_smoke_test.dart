import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

import 'fortune_sheet_render_harness.dart';

FortuneWorkbook _emptyWorkbook() => FortuneWorkbook(
  sheets: [FortuneSheet(id: 'sheet_01', name: 'Sheet1')],
);

void main() {
  testWidgets('cell borders can paint over header overlap while scrolled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(220, 140);
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
      column: 5,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-outside',
              color: Color(0xff000000),
              style: 4,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 4,
                  columnStart: 0,
                  columnEnd: 2,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-header-overlap-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(220, 140),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 0, column: 0),
              scrollOffset: const Offset(1, 1),
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 42, 19), isTrue);
    expect(_isBlackPixel(pixels, 39, 22), isTrue);
    expect(_isBlackPixel(pixels, 42, 17), isFalse);
    expect(_isBlackPixel(pixels, 37, 22), isFalse);
    expect(_isBlackPixel(pixels, 189, 118), isFalse);
  });

  testWidgets('solid cell border corner paints over freeze handles', (
    tester,
  ) async {
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
      row: 8,
      column: 4,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 8,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-freeze-handle-corner-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(180, 120),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 7, column: 3),
              scrollOffset: const Offset(1, 1),
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
              toolbarBorderStyleStrokeWidths: const {8: 4},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 37, 17), isTrue);
    expect(_isBlackPixel(pixels, 38, 17), isTrue);
    expect(_isBlackPixel(pixels, 39, 17), isTrue);
    expect(_isBlackPixel(pixels, 40, 17), isTrue);
    expect(_isBlackPixel(pixels, 38, 18), isTrue);
    expect(_isBlackPixel(pixels, 39, 19), isTrue);
    expect(_isBlackPixel(pixels, 40, 20), isTrue);
    expect(_isBlackPixel(pixels, 35, 17), isFalse);
    expect(_isBlackPixel(pixels, 37, 15), isFalse);
  });

  testWidgets(
    'horizontal border without vertical join does not overrun header',
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
        row: 8,
        column: 4,
      );
      final workbook = FortuneWorkbook(
        settings: settings,
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            borderInfo: [
              FortuneBorderInfo(
                rangeType: 'range',
                borderType: 'border-top',
                color: Color(0xff000000),
                style: 8,
                ranges: [
                  FortuneRange(
                    rowStart: 0,
                    rowEnd: 0,
                    columnStart: 0,
                    columnEnd: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      const captureKey = ValueKey('border-header-no-vertical-join-capture');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: captureKey,
            child: CustomPaint(
              size: const Size(180, 120),
              painter: FortuneSheetPainter(
                workbook: workbook,
                selection: const FortuneSelection(row: 7, column: 3),
                scrollOffset: const Offset(1, 1),
                sheetTabScrollOffset: 0,
                textDirection: TextDirection.ltr,
                toolbarBorderStyleStrokeWidths: const {8: 4},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final pixels = await _capturePixels(tester, find.byKey(captureKey));

      expect(_isBlackPixel(pixels, 39, 17), isTrue);
      expect(_isBlackPixel(pixels, 40, 17), isTrue);
      expect(_isBlackPixel(pixels, 37, 17), isFalse);
      expect(_isBlackPixel(pixels, 38, 17), isFalse);
    },
  );

  testWidgets('one pixel border does not paint over scrolled headers', (
    tester,
  ) async {
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
      row: 8,
      column: 4,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-one-pixel-scrolled-header-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(180, 120),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 7, column: 3),
              scrollOffset: const Offset(1, 1),
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 42, 19), isFalse);
    expect(_isBlackPixel(pixels, 39, 22), isFalse);
  });

  testWidgets('one pixel cell borders join without gaps or overrun', (
    tester,
  ) async {
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
      rowHeaderWidth: 24,
      columnHeaderHeight: 24,
      defaultRowHeight: 20,
      defaultColWidth: 74,
      row: 10,
      column: 4,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
                FortuneRange(
                  rowStart: 5,
                  rowEnd: 7,
                  columnStart: 1,
                  columnEnd: 2,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-one-pixel-join-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(180, 120),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 9, column: 3),
              scrollOffset: Offset.zero,
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 23, 23), isTrue);
    expect(_isBlackPixel(pixels, 24, 23), isTrue);
    expect(_isBlackPixel(pixels, 23, 24), isTrue);
    expect(_isBlackPixel(pixels, 22, 23), isFalse);
    expect(_isBlackPixel(pixels, 23, 22), isFalse);
    expect(_isBlackPixel(pixels, 24, 24), isFalse);

    expect(_isBlackPixel(pixels, 98, 63), isTrue);
    expect(_isBlackPixel(pixels, 98, 64), isTrue);
    expect(_isBlackPixel(pixels, 98, 65), isTrue);
    expect(_isBlackPixel(pixels, 96, 65), isTrue);
    expect(_isBlackPixel(pixels, 100, 65), isTrue);
    expect(_isBlackPixel(pixels, 96, 63), isFalse);
    expect(_isBlackPixel(pixels, 100, 63), isFalse);
  });

  testWidgets('stored border widths do not affect other same style ranges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 220);
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
      row: 12,
      column: 5,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 8,
              strokeWidth: 2,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 8,
              strokeWidth: 4,
              ranges: [
                FortuneRange(
                  rowStart: 5,
                  rowEnd: 7,
                  columnStart: 1,
                  columnEnd: 2,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-width-isolation-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(240, 220),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 11, column: 4),
              scrollOffset: Offset.zero,
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
              toolbarBorderStyleStrokeWidths: const {8: 4},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 60, 19), isTrue);
    expect(_isBlackPixel(pixels, 60, 20), isTrue);
    expect(_isBlackPixel(pixels, 60, 18), isFalse);
    expect(_isBlackPixel(pixels, 60, 21), isFalse);

    expect(_isBlackPixel(pixels, 110, 123), isTrue);
    expect(_isBlackPixel(pixels, 110, 124), isTrue);
  });

  testWidgets('stored border widths stay isolated across border colors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 220);
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
      row: 12,
      column: 5,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff0000ff),
              style: 8,
              strokeWidth: 2,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xffff0000),
              style: 8,
              strokeWidth: 4,
              ranges: [
                FortuneRange(
                  rowStart: 5,
                  rowEnd: 7,
                  columnStart: 1,
                  columnEnd: 2,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-color-width-isolation-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(240, 220),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 11, column: 4),
              scrollOffset: Offset.zero,
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
              toolbarBorderStyleStrokeWidths: const {8: 4},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isPixelColor(pixels, 60, 19, const Color(0xff0000ff)), isTrue);
    expect(_isPixelColor(pixels, 60, 20, const Color(0xff0000ff)), isTrue);
    expect(_isPixelColor(pixels, 60, 18, const Color(0xff0000ff)), isFalse);
    expect(_isPixelColor(pixels, 60, 21, const Color(0xff0000ff)), isFalse);

    expect(_isPixelColor(pixels, 110, 123, const Color(0xffff0000)), isTrue);
    expect(_isPixelColor(pixels, 110, 124, const Color(0xffff0000)), isTrue);
  });

  testWidgets('cell border segments join at internal grid intersections', (
    tester,
  ) async {
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
      row: 6,
      column: 4,
    );
    final workbook = FortuneWorkbook(
      settings: settings,
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          borderInfo: [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 8,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 2,
                  columnStart: 0,
                  columnEnd: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    const captureKey = ValueKey('border-internal-join-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: CustomPaint(
            size: const Size(180, 120),
            painter: FortuneSheetPainter(
              workbook: workbook,
              selection: const FortuneSelection(row: 5, column: 3),
              scrollOffset: Offset.zero,
              sheetTabScrollOffset: 0,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final pixels = await _capturePixels(tester, find.byKey(captureKey));

    expect(_isBlackPixel(pixels, 40, 20), isTrue);
    expect(_isBlackPixel(pixels, 41, 20), isTrue);
    expect(_isBlackPixel(pixels, 40, 21), isTrue);
    expect(_isBlackPixel(pixels, 41, 21), isFalse);
    expect(_isBlackPixel(pixels, 141, 81), isTrue);
    expect(_isBlackPixel(pixels, 142, 81), isTrue);
    expect(_isBlackPixel(pixels, 141, 82), isTrue);
    expect(_isBlackPixel(pixels, 142, 82), isTrue);
    expect(_isBlackPixel(pixels, 143, 82), isFalse);
    expect(_isBlackPixel(pixels, 142, 84), isFalse);
    expect(_isBlackPixel(pixels, 90, 61), isTrue);
    expect(_isBlackPixel(pixels, 91, 61), isTrue);
    expect(_isBlackPixel(pixels, 90, 62), isTrue);
    expect(_isBlackPixel(pixels, 91, 62), isTrue);
    expect(_isBlackPixel(pixels, 89, 63), isFalse);
    expect(_isBlackPixel(pixels, 92, 63), isFalse);
  });

  testWidgets('sheet canvas has a stable golden capture', (tester) async {
    const captureKey = ValueKey('fortune-sheet-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 640,
              height: 420,
              child: FortuneSheetCanvas(workbook: _emptyWorkbook()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_sheet_empty'),
    );
  });

  testWidgets('wide toolbar has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(1669, 64);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-wide-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 1669,
              height: 44,
              child: FortuneSheetCanvas(workbook: _emptyWorkbook()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_wide'),
    );
  });

  testWidgets('narrow toolbar overflow has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 64);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-narrow-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 900,
              height: 44,
              child: FortuneSheetCanvas(workbook: _emptyWorkbook()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_narrow'),
    );
  });

  testWidgets('sort and filter toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(140, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-filter-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 140,
              height: 240,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarFilterCommand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_filter_popup'),
    );
  });

  testWidgets('comment toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(128, 150);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-comment-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 128,
              height: 150,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: FortuneWorkbook(
                    sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
                  ),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarCommentCommand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_comment_popup'),
    );
  });

  testWidgets('auto sum toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(180, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-autosum-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 180,
              height: 260,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarQuickFormulaPopupKey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_autosum_popup'),
    );
  });

  testWidgets('number format toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-format-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 280,
              height: 360,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarFormatCommand,
                  toolbarPopupSelectedIndex: fortuneToolbarFormatCommands
                      .indexOf(fortuneToolbarFormatAutomaticCommand),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_format_popup'),
    );
  });

  testWidgets('font toolbar popup has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(240, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-font-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 240,
              height: 360,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarFontPopupKey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_font_popup'),
    );
  });

  testWidgets('font size toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(120, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-font-size-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 120,
              height: 420,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarFontSizePopupKey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_font_size_popup'),
    );
  });

  testWidgets('location toolbar popup has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(260, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-toolbar-location-popup-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 260,
              height: 320,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  toolbarPopupKey: fortuneToolbarLocationConditionCommand,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_toolbar_location_popup'),
    );
  });

  testWidgets(
    'location column span message dialog has a stable golden capture',
    (tester) async {
      tester.view.physicalSize = const Size(360, 170);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const captureKey = ValueKey('fortune-location-column-message-capture');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: captureKey,
              child: SizedBox(
                width: 360,
                height: 170,
                child: CustomPaint(
                  painter: FortuneSheetPainter(
                    workbook: _emptyWorkbook(),
                    selection: const FortuneSelection(row: 0, column: 0),
                    scrollOffset: Offset.zero,
                    sheetTabScrollOffset: 0,
                    textDirection: TextDirection.ltr,
                    locationMessageDialogText:
                        'Please select at least two columns',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectFortuneSheetGolden(
        tester,
        find.byKey(captureKey),
        fortuneSheetGoldenPath('fortune_location_column_message_dialog'),
      );
    },
  );

  testWidgets('screenshot dialog has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(640, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-screenshot-dialog-capture');
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: 'Capture'),
            const FortuneCellCoord(0, 1): const FortuneCell(value: 'Preview'),
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 640,
              height: 430,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: workbook,
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  screenshotDialogOpen: true,
                  screenshotRange: const FortuneRange(
                    rowStart: 0,
                    rowEnd: 1,
                    columnStart: 0,
                    columnEnd: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_screenshot_dialog'),
    );
  });

  testWidgets('search dialog has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(720, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-search-dialog-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 720,
              height: 540,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  searchDialogOpen: true,
                  searchReplaceMode: true,
                  searchText: 'alpha',
                  replaceText: 'beta',
                  searchResults: const [
                    FortuneSearchResultView(
                      sheetIndex: 0,
                      sheetName: 'Sheet1',
                      row: 0,
                      column: 0,
                      value: 'alpha',
                    ),
                    FortuneSearchResultView(
                      sheetIndex: 0,
                      sheetName: 'Sheet1',
                      row: 1,
                      column: 1,
                      value: 'Alpha beta',
                    ),
                  ],
                  searchSelectedResultIndex: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_search_dialog'),
    );
  });

  testWidgets('search find dialog has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(625, 318);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-search-find-dialog-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 625,
              height: 318,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  searchDialogOpen: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_search_find_dialog'),
    );
  });

  testWidgets('formula search dialog has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-formula-search-dialog-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 420,
              height: 440,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  formulaSearchDialogOpen: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_formula_search_dialog'),
    );
  });

  testWidgets('data verification dialog has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(582, 458);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-data-verification-dialog-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 582,
              height: 458,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  dataVerificationDialogOpen: true,
                  dataVerificationDialogRangeText: 'A1',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_data_verification_dialog'),
    );
  });

  testWidgets('hyperlink dialog has a stable golden capture', (tester) async {
    tester.view.physicalSize = const Size(430, 280);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-hyperlink-dialog-capture');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 430,
              height: 280,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: _emptyWorkbook(),
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  textDirection: TextDirection.ltr,
                  hyperlinkDialogOpen: true,
                  hyperlinkDialogAddressText: 'https://',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_hyperlink_dialog'),
    );
  });

  testWidgets('active image selection box has a stable golden capture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(260, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const captureKey = ValueKey('fortune-active-image-capture');
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          images: const [
            FortuneImage(
              id: 'img1',
              src: '',
              left: 0,
              top: 0,
              width: 120,
              height: 80,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: captureKey,
            child: SizedBox(
              width: 260,
              height: 220,
              child: CustomPaint(
                painter: FortuneSheetPainter(
                  workbook: workbook,
                  selection: const FortuneSelection(row: 0, column: 0),
                  scrollOffset: Offset.zero,
                  sheetTabScrollOffset: 0,
                  activeImageId: 'img1',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectFortuneSheetGolden(
      tester,
      find.byKey(captureKey),
      fortuneSheetGoldenPath('fortune_active_image'),
    );
  });
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

bool _isBlackPixel(({ByteData data, int width}) pixels, int x, int y) {
  final offset = (y * pixels.width + x) * 4;
  return pixels.data.getUint8(offset) < 32 &&
      pixels.data.getUint8(offset + 1) < 32 &&
      pixels.data.getUint8(offset + 2) < 32 &&
      pixels.data.getUint8(offset + 3) > 240;
}

bool _isPixelColor(
  ({ByteData data, int width}) pixels,
  int x,
  int y,
  Color color,
) {
  final offset = (y * pixels.width + x) * 4;
  final argb = color.toARGB32();
  return pixels.data.getUint8(offset) == ((argb >> 16) & 0xff) &&
      pixels.data.getUint8(offset + 1) == ((argb >> 8) & 0xff) &&
      pixels.data.getUint8(offset + 2) == (argb & 0xff) &&
      pixels.data.getUint8(offset + 3) == ((argb >> 24) & 0xff);
}
