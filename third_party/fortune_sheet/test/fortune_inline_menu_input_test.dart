import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

double snappedGuideMm(double sourceMm) {
  final snapped = sourceMm.roundToDouble();
  return snapped > sourceMm ? sourceMm.floorToDouble() : snapped;
}

double snappedGuideMmInsideArea(double sourceMm, double areaMm) {
  return snappedGuideMm(sourceMm > areaMm ? areaMm : sourceMm);
}

void main() {
  test('context menu row height and column width inputs align', () {
    const menuAt = Offset(0, 0);
    final rowHeightInput = fortuneContextMenuInlineInputRect(
      menuAt,
      fortuneContextSetRowHeightCommand,
      fortuneHeaderContextMenuItems,
    );
    final columnWidthInput = fortuneContextMenuInlineInputRect(
      menuAt,
      fortuneContextSetColumnWidthCommand,
      fortuneHeaderContextMenuItems,
    );
    final labelWidthInput = fortuneContextMenuInlineInputRect(
      menuAt,
      fortuneContextSetLabelWidthCommand,
      fortuneHeaderContextMenuItems,
    );
    final labelHeightInput = fortuneContextMenuInlineInputRect(
      menuAt,
      fortuneContextSetLabelHeightCommand,
      fortuneHeaderContextMenuItems,
    );

    expect(rowHeightInput, isNotNull);
    expect(columnWidthInput, isNotNull);
    expect(labelWidthInput, isNotNull);
    expect(labelHeightInput, isNotNull);
    expect(rowHeightInput!.left, columnWidthInput!.left);
    expect(rowHeightInput.width, columnWidthInput.width);
    expect(labelWidthInput!.left, columnWidthInput.left);
    expect(labelHeightInput!.left, columnWidthInput.left);
    expect(labelWidthInput.width, columnWidthInput.width);
    expect(labelHeightInput.width, columnWidthInput.width);
  });

  testWidgets('toolbar border style width inputs show default values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const toolbarItems = [
      fortuneToolbarUndoCommand,
      fortuneToolbarRedoCommand,
      '|',
      fortuneToolbarFontPopupKey,
      '|',
      fortuneToolbarFontSizePopupKey,
      '|',
      fortuneToolbarBoldCommand,
      fortuneToolbarItalicCommand,
      fortuneToolbarStrikeThroughCommand,
      fortuneToolbarUnderlineCommand,
      '|',
      fortuneToolbarFontColorPopupKey,
      fortuneToolbarBackgroundPopupKey,
      fortuneToolbarBorderPopupKey,
      fortuneToolbarMergePopupKey,
      '|',
      fortuneToolbarHorizontalAlignPopupKey,
      fortuneToolbarVerticalAlignPopupKey,
      fortuneToolbarTextWrapPopupKey,
      fortuneToolbarTextRotationPopupKey,
      '|',
      fortuneToolbarImageCommand,
    ];
    const settings = FortuneSettings(toolbarItems: toolbarItems);
    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook, settings: settings),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final borderRect = fortuneVisibleToolbarItemRects(
      640,
      items: toolbarItems,
    ).singleWhere((entry) => entry.key == fortuneToolbarBorderPopupKey).value;
    await tester.tapAt(
      topLeft + fortuneToolbarComboArrowRect(borderRect).center,
    );
    await tester.pump();

    final borderPopupLeft = fortuneToolbarPopupLeftFor(
      key: fortuneToolbarBorderPopupKey,
      itemRect: borderRect,
      viewportWidth: 640,
      popupWidth: fortuneToolbarPopupWidthFor(fortuneToolbarBorderPopupKey),
    );
    var styleMenuTop =
        fortuneToolbarPopupTop +
        fortuneToolbarPopupContentTopPaddingFor(fortuneToolbarBorderPopupKey);
    for (final command in fortuneToolbarBorderPopupCommands) {
      if (command == fortuneToolbarBorderStyleSubmenuKey) {
        break;
      }
      styleMenuTop += command == '|'
          ? fortuneToolbarMenuDividerHeight
          : fortuneToolbarPopupRowHeightFor(fortuneToolbarBorderPopupKey);
    }
    await tester.tapAt(
      topLeft +
          Offset(
            borderPopupLeft + fortuneToolbarBorderPopupWidth / 2,
            styleMenuTop +
                fortuneToolbarPopupRowHeightFor(fortuneToolbarBorderPopupKey) /
                    2,
          ),
    );
    await tester.pump();

    final rootPaint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .singleWhere((paint) => paint.painter is FortuneSheetPainter);
    expect(rootPaint.foregroundPainter, isNull);
    for (final style in fortuneToolbarBorderWidthEditableStyles) {
      final input = find.byKey(ValueKey('fortune-border-style-width-$style'));
      expect(input, findsOneWidget);
      expect(tester.widget<EditableText>(input).controller.text, '2');
    }
  });

  testWidgets('context menu inline input keeps editing keys in the input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final rowHeaderGesture = await tester.startGesture(
      topLeft + const Offset(20, 100),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rowHeaderGesture.up();
    await tester.pump();

    final rowHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-row-height'),
    );
    expect(rowHeightInput, findsOneWidget);

    await tester.tap(rowHeightInput);
    await tester.enterText(rowHeightInput, '31');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(painter().contextMenuAt, isNotNull);
    expect(painter().workbook.activeSheet.rowHeights.containsKey(0), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(tester.widget<EditableText>(rowHeightInput).controller.text, '1');
    expect(painter().contextMenuAt, isNotNull);
    expect(painter().workbook.activeSheet.rowHeights.containsKey(0), isFalse);

    await tester.enterText(rowHeightInput, '31');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(painter().contextMenuAt, isNull);
    expect(painter().workbook.activeSheet.rowHeights[0], 31);
    expect(painter().workbook.activeSheet.customHeight[0], 1);
  });

  testWidgets('context menu inline inputs move focus with tab and shift tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 100,
            fortuneSheetGridClientHeightMmKey: 100,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final cornerHeaderGesture = await tester.startGesture(
      topLeft + Offset(20, sheetTop + settings.columnHeaderHeight / 2),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cornerHeaderGesture.up();
    await tester.pump();

    final labelWidthInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-width'),
    );
    final labelHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-height'),
    );
    expect(labelWidthInput, findsOneWidget);
    expect(labelHeightInput, findsOneWidget);

    await tester.tap(labelWidthInput);
    await tester.pump();
    expect(tester.widget<EditableText>(labelWidthInput).focusNode.hasFocus, true);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      tester.widget<EditableText>(labelHeightInput).focusNode.hasFocus,
      true,
    );
    expect(painter().contextMenuAt, isNotNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(tester.widget<EditableText>(labelWidthInput).focusNode.hasFocus, true);
    expect(painter().contextMenuAt, isNotNull);
  });

  testWidgets('adjusted sheet context menu axis size input uses millimeters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowHeights: {0: fortuneMillimetersToLogicalPixels(7)},
          columnWidths: {0: fortuneMillimetersToLogicalPixels(18)},
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 100,
            fortuneSheetGridClientHeightMmKey: 100,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    expect(
      fortuneContextMenuAxisSizeUnitLabel(
        painter().workbook.activeSheet,
        const FortuneSheetLocale(),
      ),
      'mm',
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final rowHeaderGesture = await tester.startGesture(
      topLeft + const Offset(20, 100),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rowHeaderGesture.up();
    await tester.pump();

    final rowHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-row-height'),
    );
    expect(rowHeightInput, findsOneWidget);
    expect(tester.widget<EditableText>(rowHeightInput).controller.text, '7');

    await tester.tap(rowHeightInput);
    await tester.enterText(rowHeightInput, '9.5');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(
      painter().workbook.activeSheet.rowHeights[0],
      closeTo(fortuneMillimetersToLogicalPixels(9.5), 0.001),
    );

    final settings = painter().workbook.settings;
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final columnHeaderGesture = await tester.startGesture(
      topLeft +
          Offset(
            settings.rowHeaderWidth + 10,
            sheetTop + settings.columnHeaderHeight / 2,
          ),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await columnHeaderGesture.up();
    await tester.pump();

    final columnWidthInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-column-width'),
    );
    expect(columnWidthInput, findsOneWidget);
    expect(tester.widget<EditableText>(columnWidthInput).controller.text, '18');

    await tester.tap(columnWidthInput);
    await tester.enterText(columnWidthInput, '21');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(
      painter().workbook.activeSheet.columnWidths[0],
      closeTo(fortuneMillimetersToLogicalPixels(21), 0.001),
    );
    expect(painter().workbook.activeSheet.customWidth[0], 1);

    final cornerHeaderGesture = await tester.startGesture(
      topLeft + Offset(20, sheetTop + settings.columnHeaderHeight / 2),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cornerHeaderGesture.up();
    await tester.pump();

    final labelWidthInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-width'),
    );
    final labelHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-height'),
    );
    expect(labelWidthInput, findsOneWidget);
    expect(labelHeightInput, findsOneWidget);
    expect(tester.widget<EditableText>(labelWidthInput).controller.text, '100');
    expect(tester.widget<EditableText>(labelHeightInput).controller.text, '100');

    await tester.tap(labelWidthInput);
    await tester.enterText(labelWidthInput, '120');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(fortuneSheetGridClientWidthMm(painter().workbook.activeSheet), 120);
    expect(fortuneSheetGridClientHeightMm(painter().workbook.activeSheet), 100);

    final nextCornerHeaderGesture = await tester.startGesture(
      topLeft + Offset(20, sheetTop + settings.columnHeaderHeight / 2),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await nextCornerHeaderGesture.up();
    await tester.pump();

    final nextLabelHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-height'),
    );
    expect(nextLabelHeightInput, findsOneWidget);
    expect(
      tester.widget<EditableText>(nextLabelHeightInput).controller.text,
      '100',
    );

    await tester.tap(nextLabelHeightInput);
    await tester.enterText(nextLabelHeightInput, '75');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(fortuneSheetGridClientWidthMm(painter().workbook.activeSheet), 120);
    expect(fortuneSheetGridClientHeightMm(painter().workbook.activeSheet), 75);
  });

  testWidgets('context menu enter commits all changed inline inputs in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 100,
            fortuneSheetGridClientHeightMmKey: 100,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final cornerHeaderGesture = await tester.startGesture(
      topLeft + Offset(20, sheetTop + settings.columnHeaderHeight / 2),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cornerHeaderGesture.up();
    await tester.pump();

    final labelWidthInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-width'),
    );
    final labelHeightInput = find.byKey(
      const ValueKey('fortune-context-menu-input-set-label-height'),
    );
    expect(labelWidthInput, findsOneWidget);
    expect(labelHeightInput, findsOneWidget);

    await tester.tap(labelWidthInput);
    await tester.enterText(labelWidthInput, '120');
    await tester.tap(labelHeightInput);
    await tester.enterText(labelHeightInput, '75');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(painter().contextMenuAt, isNull);
    expect(fortuneSheetGridClientWidthMm(painter().workbook.activeSheet), 120);
    expect(fortuneSheetGridClientHeightMm(painter().workbook.activeSheet), 75);
  });

  testWidgets('adjusted sheet outside click closes toolbar dropdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 40,
            fortuneSheetGridClientHeightMmKey: 30,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final fontRect = fortuneVisibleToolbarItemRects(
      640,
    ).singleWhere((entry) => entry.key == fortuneToolbarFontPopupKey).value;
    await tester.tapAt(topLeft + fortuneToolbarComboArrowRect(fontRect).center);
    await tester.pump();

    expect(painter().toolbarPopupKey, fortuneToolbarFontPopupKey);

    await tester.tapAt(topLeft + const Offset(420, 220));
    await tester.pump();

    expect(painter().toolbarPopupKey, isNull);
    expect(painter().workbook.activeSheet.cells, isEmpty);
  });

  testWidgets('adjusted sheet ruler menu toggles guides stored by sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 60,
            fortuneSheetGridClientHeightMmKey: 40,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    Offset headerCornerMenuPoint() {
      final rulerInset = painter().sheetRulerVisible ? 1.0 : 0.0;
      return Offset(
        settings.rowHeaderWidth * (rulerInset + 0.5),
        sheetTop + settings.columnHeaderHeight * (rulerInset + 0.5),
      );
    }

    final cornerGesture = await tester.startGesture(
      topLeft + headerCornerMenuPoint(),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cornerGesture.up();
    await tester.pump();

    expect(painter().contextMenuAt, isNotNull);
    expect(
      painter().contextMenuItems,
      contains(fortuneContextShowGridLinesCommand),
    );
    expect(
      painter().contextMenuItems,
      contains(fortuneContextShowRulerCommand),
    );
    expect(
      painter().contextMenuItems.indexOf(fortuneContextShowGridLinesCommand),
      painter().contextMenuItems.indexOf(fortuneContextShowRulerCommand) - 1,
    );
    expect(
      painter().contextMenuCheckedItems,
      contains(fortuneContextShowGridLinesCommand),
    );
    expect(
      painter().contextMenuItems.indexOf(fortuneContextShowRulerCommand),
      lessThan(
        painter().contextMenuItems.indexOf(fortuneContextDeleteRowCommand),
      ),
    );
    expect(painter().sheetRulerVisible, isTrue);
    expect(painter().sheetRulerCornerSizeLabel, '60 x 40');
    expect(
      painter().contextMenuCheckedItems,
      contains(fortuneContextShowRulerCommand),
    );

    await tester.tapAt(
      topLeft +
          fortuneContextMenuItemCenter(
            painter().contextMenuAt!,
            fortuneContextShowGridLinesCommand,
            painter().contextMenuItems,
          ),
    );
    await tester.pump();

    expect(painter().workbook.activeSheet.showGridLines, isFalse);

    final gridToggleOffGesture = await tester.startGesture(
      topLeft + headerCornerMenuPoint(),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gridToggleOffGesture.up();
    await tester.pump();

    expect(
      painter().contextMenuCheckedItems,
      isNot(contains(fortuneContextShowGridLinesCommand)),
    );

    await tester.tapAt(
      topLeft +
          fortuneContextMenuItemCenter(
            painter().contextMenuAt!,
            fortuneContextShowGridLinesCommand,
            painter().contextMenuItems,
          ),
    );
    await tester.pump();

    expect(painter().workbook.activeSheet.showGridLines, isTrue);

    final gridToggleOnGesture = await tester.startGesture(
      topLeft + headerCornerMenuPoint(),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gridToggleOnGesture.up();
    await tester.pump();

    final headerCornerContextItems = [...painter().contextMenuItems];

    await tester.tapAt(
      topLeft +
          fortuneContextMenuItemCenter(
            painter().contextMenuAt!,
            fortuneContextShowRulerCommand,
            painter().contextMenuItems,
          ),
    );
    await tester.pump();

    expect(painter().sheetRulerVisible, isFalse);
    expect(painter().sheetRulerCornerSizeLabel, isNull);
    expect(
      painter().workbook.activeSheet.extraFields[fortuneSheetRulerVisibleKey],
      isFalse,
    );

    final rulerToggleOffGesture = await tester.startGesture(
      topLeft + headerCornerMenuPoint(),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rulerToggleOffGesture.up();
    await tester.pump();

    expect(
      painter().contextMenuCheckedItems,
      isNot(contains(fortuneContextShowRulerCommand)),
    );

    await tester.tapAt(
      topLeft +
          fortuneContextMenuItemCenter(
            painter().contextMenuAt!,
            fortuneContextShowRulerCommand,
            painter().contextMenuItems,
          ),
    );
    await tester.pump();

    expect(painter().sheetRulerVisible, isTrue);
    expect(painter().sheetRulerCornerSizeLabel, '60 x 40');
    expect(
      painter().workbook.activeSheet.extraFields[fortuneSheetRulerVisibleKey],
      isTrue,
    );
    final rulerCornerGesture = await tester.startGesture(
      topLeft +
          Offset(
            settings.rowHeaderWidth / 2,
            sheetTop + settings.columnHeaderHeight / 2,
          ),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rulerCornerGesture.up();
    await tester.pump();

    expect(painter().contextMenuAt, isNotNull);
    expect(painter().contextMenuItems, headerCornerContextItems);

    final headerLeft = settings.rowHeaderWidth;
    final headerTop = settings.columnHeaderHeight;
    final dataLeft = headerLeft + settings.rowHeaderWidth;
    final dataTop = headerTop + settings.columnHeaderHeight;

    final start =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(10.2),
          sheetTop + settings.columnHeaderHeight / 2,
        );
    final end =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(15.4),
          sheetTop + dataTop + 30,
        );
    final guideGesture = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await guideGesture.moveTo(end);
    await guideGesture.up();
    await tester.pump();

    final rawGuides =
        painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
            as List;
    expect(rawGuides, hasLength(1));
    expect(rawGuides.first['axis'], 'vertical');
    expect(rawGuides.first['positionMm'], 15.0);

    final selectGesture = await tester.startGesture(
      end,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await selectGesture.up();
    await tester.pump();

    expect(painter().sheetRulerSelectedGuideIndex, rawGuides.first['id']);

    await tester.tapAt(
      topLeft +
          Offset(
            dataLeft + fortuneMillimetersToLogicalPixels(25),
            sheetTop + dataTop + 30,
          ),
    );
    await tester.pump();

    expect(painter().sheetRulerSelectedGuideIndex, isNull);

    final reselectGesture = await tester.startGesture(
      end,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await reselectGesture.up();
    await tester.pump();

    expect(painter().sheetRulerSelectedGuideIndex, rawGuides.first['id']);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(
      painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey],
      isEmpty,
    );

    final metricsBeforeResize = painter().workbook.activeSheet.metrics(
      settings,
    );
    final columnResizeStart =
        topLeft +
        Offset(
          dataLeft + metricsBeforeResize.columnEnd(0),
          sheetTop + headerTop + settings.columnHeaderHeight / 2,
        );
    final columnResizeGesture = await tester.startGesture(
      columnResizeStart,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await columnResizeGesture.moveBy(const Offset(20, 0));
    await columnResizeGesture.up();
    await tester.pump();

    expect(
      painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey],
      isEmpty,
    );
    expect(
      painter().workbook.activeSheet.columnWidths[0],
      closeTo(settings.defaultColWidth + 20, 0.1),
    );

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: topLeft + Offset(dataLeft + 120, sheetTop + dataTop + 80),
        scrollDelta: Offset(fortuneMillimetersToLogicalPixels(10), 0),
      ),
    );
    await tester.pump();

    final scrollX = painter().scrollOffset.dx;
    expect(scrollX, greaterThan(0));

    final scrolledStart =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(5.2),
          sheetTop + settings.columnHeaderHeight / 2,
        );
    final scrolledEnd =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(10.4),
          sheetTop + dataTop + 30,
        );
    final scrolledGuideGesture = await tester.startGesture(
      scrolledStart,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await scrolledGuideGesture.moveTo(scrolledEnd);
    await scrolledGuideGesture.up();
    await tester.pump();

    final scrolledGuides =
        painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
            as List;
    expect(scrolledGuides, hasLength(1));
    expect(scrolledGuides.first['axis'], 'vertical');
    expect(
      scrolledGuides.first['positionMm'],
      closeTo(
        fortuneLogicalPixelsToMillimeters(
          scrollX + fortuneMillimetersToLogicalPixels(10.4),
        ).roundToDouble(),
        0.1,
      ),
    );

    final scrolledSelectGesture = await tester.startGesture(
      scrolledEnd,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await scrolledSelectGesture.up();
    await tester.pump();

    expect(painter().sheetRulerSelectedGuideIndex, scrolledGuides.first['id']);
  });

  testWidgets('adjusted sheet ruler guide drag stays inside adjusted area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 60,
            fortuneSheetGridClientHeightMmKey: 40,
            fortuneSheetRulerVisibleKey: true,
            fortuneSheetRulerGuidesKey: [
              {'id': 0, 'axis': 'vertical', 'positionMm': 10.0},
              {'id': 1, 'axis': 'horizontal', 'positionMm': 10.0},
            ],
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final settings = painter().workbook.settings;
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final dataLeft = settings.rowHeaderWidth * 2;
    final dataTop = sheetTop + settings.columnHeaderHeight * 2;
    final verticalStart =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(10),
          dataTop + fortuneMillimetersToLogicalPixels(20),
        );
    final verticalEnd =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(90),
          dataTop + fortuneMillimetersToLogicalPixels(20),
        );
    final verticalGesture = await tester.startGesture(
      verticalStart,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await verticalGesture.moveTo(verticalEnd);
    await verticalGesture.up();
    await tester.pump();

    var guides =
        painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
            as List;
    expect(guides.first['positionMm'], 60.0);

    final horizontalStart =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(20),
          dataTop + fortuneMillimetersToLogicalPixels(10),
        );
    final horizontalEnd =
        topLeft +
        Offset(
          dataLeft + fortuneMillimetersToLogicalPixels(20),
          dataTop + fortuneMillimetersToLogicalPixels(70),
        );
    final horizontalGesture = await tester.startGesture(
      horizontalStart,
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryMouseButton,
    );
    await horizontalGesture.moveTo(horizontalEnd);
    await horizontalGesture.up();
    await tester.pump();

    guides =
        painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
            as List;
    expect(guides[1]['positionMm'], 40.0);
  });

  testWidgets('adjusted sheet ruler uses row and column sheet totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FortuneWorkbook workbookForSize(
      int rows,
      int columns, {
      List<Map<String, Object?>> guides = const <Map<String, Object?>>[],
    }) {
      return FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            rowCount: rows,
            columnCount: columns,
            extraFields: {
              fortuneSheetGridClientWidthMmKey: 100,
              fortuneSheetGridClientHeightMmKey: 100,
              fortuneSheetRulerVisibleKey: true,
              fortuneSheetRulerGuidesKey: guides,
            },
          ),
        ],
      );
    }

    Future<void> pumpWorkbook(FortuneWorkbook workbook, String key) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 640,
            height: 760,
            child: FortuneSheetCanvas(key: ValueKey(key), workbook: workbook),
          ),
        ),
      );
      await tester.pump();
    }

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    Future<Map<String, Object?>> dragGuideAtSheetEnd(String axis) async {
      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      final settings = painter().workbook.settings;
      final metrics = painter().workbook.activeSheet.metrics(settings);
      final sheetTop =
          settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
      final dataLeft = settings.rowHeaderWidth * 2;
      final dataTop = settings.columnHeaderHeight * 2;
      final start = axis == 'vertical'
          ? topLeft +
                Offset(
                  dataLeft + fortuneMillimetersToLogicalPixels(10),
                  sheetTop + settings.columnHeaderHeight / 2,
                )
          : topLeft +
                Offset(
                  settings.rowHeaderWidth / 2,
                  sheetTop + dataTop + fortuneMillimetersToLogicalPixels(5),
                );
      final end = axis == 'vertical'
          ? topLeft +
                Offset(
                  dataLeft + metrics.columnTotalWidth + 80,
                  sheetTop + dataTop + 30,
                )
          : topLeft +
                Offset(
                  dataLeft + 30,
                  sheetTop + dataTop + metrics.rowTotalHeight + 80,
                );
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pump();
      final guides =
          painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
              as List;
      return Map<String, Object?>.from(guides.last as Map);
    }

    Future<Map<String, Object?>> dragHorizontalGuideAtSheetEnd() async {
      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      final settings = painter().workbook.settings;
      final metrics = painter().workbook.activeSheet.metrics(settings);
      final sheetTop =
          settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
      final dataLeft = settings.rowHeaderWidth * 2;
      final dataTop = settings.columnHeaderHeight * 2;
      final start =
          topLeft +
          Offset(
            settings.rowHeaderWidth / 2,
            sheetTop + dataTop + fortuneMillimetersToLogicalPixels(5),
          );
      final end =
          topLeft +
          Offset(
            dataLeft + 30,
            sheetTop + dataTop + metrics.rowTotalHeight + 80,
          );
      final gesture = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await gesture.moveTo(end);
      await gesture.up();
      await tester.pump();
      final guides =
          painter().workbook.activeSheet.extraFields[fortuneSheetRulerGuidesKey]
              as List;
      return Map<String, Object?>.from(guides.last as Map);
    }

    await pumpWorkbook(workbookForSize(2, 2), 'small-sheet');
    expect(painter().sheetRulerVisible, isTrue);

    final smallMetrics = painter().workbook.activeSheet.metrics(
      painter().workbook.settings,
    );
    final smallVerticalGuide = await dragGuideAtSheetEnd('vertical');
    expect(smallVerticalGuide['axis'], 'vertical');
    expect(
      smallVerticalGuide['positionMm'],
      closeTo(
        snappedGuideMm(
          fortuneLogicalPixelsToMillimeters(smallMetrics.columnTotalWidth),
        ),
        0.1,
      ),
    );

    await pumpWorkbook(
      workbookForSize(
        2,
        2,
        guides: const [
          {'id': 0, 'axis': 'horizontal', 'positionMm': 5.0},
        ],
      ),
      'small-sheet-horizontal',
    );

    final smallHorizontalGuide = await dragHorizontalGuideAtSheetEnd();
    expect(smallHorizontalGuide['axis'], 'horizontal');
    expect(
      smallHorizontalGuide['positionMm'],
      closeTo(
        snappedGuideMm(
          fortuneLogicalPixelsToMillimeters(smallMetrics.rowTotalHeight),
        ),
        0.1,
      ),
    );

    await pumpWorkbook(workbookForSize(4, 4), 'larger-sheet');

    final largerMetrics = painter().workbook.activeSheet.metrics(
      painter().workbook.settings,
    );
    final largerVerticalGuide = await dragGuideAtSheetEnd('vertical');
    expect(
      largerVerticalGuide['positionMm'],
      closeTo(
        snappedGuideMm(
          fortuneLogicalPixelsToMillimeters(largerMetrics.columnTotalWidth),
        ),
        0.1,
      ),
    );
    expect(
      largerVerticalGuide['positionMm'] as num,
      greaterThan(smallVerticalGuide['positionMm'] as num),
    );

    await pumpWorkbook(
      workbookForSize(
        4,
        4,
        guides: const [
          {'id': 0, 'axis': 'horizontal', 'positionMm': 5.0},
        ],
      ),
      'larger-sheet-horizontal',
    );

    final largerHorizontalGuide = await dragHorizontalGuideAtSheetEnd();
    expect(
      largerHorizontalGuide['positionMm'],
      closeTo(
        snappedGuideMmInsideArea(
          fortuneLogicalPixelsToMillimeters(largerMetrics.rowTotalHeight),
          100,
        ),
        0.1,
      ),
    );
    expect(
      largerHorizontalGuide['positionMm'] as num,
      greaterThan(smallHorizontalGuide['positionMm'] as num),
    );
  });

  testWidgets('adjusted sheet outside click closes context menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 40,
            fortuneSheetGridClientHeightMmKey: 30,
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
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

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final rowHeaderGesture = await tester.startGesture(
      topLeft + const Offset(20, 100),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rowHeaderGesture.up();
    await tester.pump();

    expect(painter().contextMenuAt, isNotNull);

    await tester.tapAt(topLeft + const Offset(420, 220));
    await tester.pump();

    expect(painter().contextMenuAt, isNull);
    expect(painter().workbook.activeSheet.rowHeights, isEmpty);
  });
}
