import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_border_compute.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  testWidgets('toolbar border color preserves existing stroke width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
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
          borderInfo: const [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: fortuneToolbarBorderAllCommand,
              color: Color(0xff000000),
              style: 1,
              strokeWidth: 2,
              ranges: [
                FortuneRange(
                  rowStart: 0,
                  rowEnd: 0,
                  columnStart: 0,
                  columnEnd: 0,
                  rowFocus: 0,
                  columnFocus: 0,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 1200,
          height: 800,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .singleWhere((paint) => paint.painter is FortuneSheetPainter)
              .painter!
          as FortuneSheetPainter;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(
      topLeft + _toolbarItemArrowCenter(fortuneToolbarBorderPopupKey),
    );
    await tester.pump();

    final popupLeft = _toolbarPopupLeftForKey(fortuneToolbarBorderPopupKey);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: topLeft + const Offset(2, 2));
    await mouse.moveTo(
      topLeft +
          _toolbarPopupItemCenterForKey(
            popupLeft: popupLeft,
            toolbarKey: fortuneToolbarBorderPopupKey,
            itemIndex: fortuneToolbarBorderPopupCommands.indexOf(
              fortuneToolbarBorderColorSubmenuKey,
            ),
          ),
    );
    await tester.pump();
    await tester.tapAt(
      topLeft +
          _borderColorPaletteItemCenter(popupLeft: popupLeft, hex: '#c00c00'),
    );
    await tester.pump();

    final borders = FortuneBorderCompute.compute(
      painter().workbook.activeSheet,
    );
    final cellBorders = borders[const FortuneCellCoord(0, 0)]!;
    expect(cellBorders.top?.color, const Color(0xffc00c00));
    expect(cellBorders.right?.color, const Color(0xffc00c00));
    expect(cellBorders.bottom?.color, const Color(0xffc00c00));
    expect(cellBorders.left?.color, const Color(0xffc00c00));
    expect(cellBorders.top?.strokeWidth, 2);
    expect(cellBorders.right?.strokeWidth, 2);
    expect(cellBorders.bottom?.strokeWidth, 2);
    expect(cellBorders.left?.strokeWidth, 2);
  });
}

Offset _toolbarItemArrowCenter(String key, {double width = 1200}) {
  for (final entry in fortuneVisibleToolbarItemRects(width)) {
    if (entry.key == key) {
      return fortuneToolbarComboArrowRect(entry.value).center;
    }
  }
  fail('toolbar item not found: $key');
}

Offset _toolbarPopupItemCenterForKey({
  required double popupLeft,
  required String toolbarKey,
  required int itemIndex,
}) {
  final options = toolbarKey == fortuneToolbarFreezePopupKey
      ? fortuneFreezeMenuItems
      : fortuneToolbarPopupItems[toolbarKey];
  final top = options == null
      ? fortuneToolbarPopupTop +
            fortuneToolbarPopupContentTopPaddingFor(toolbarKey) +
            fortuneToolbarPopupRowHeightFor(toolbarKey) * itemIndex
      : _toolbarPopupItemTopForKey(
          toolbarKey: toolbarKey,
          options: options,
          itemIndex: itemIndex,
        );
  final itemHeight = options != null && options[itemIndex] == '|'
      ? fortuneToolbarMenuDividerHeight
      : fortuneToolbarPopupRowHeightFor(toolbarKey);
  return Offset(popupLeft + 20, top + itemHeight / 2);
}

double _toolbarPopupItemTopForKey({
  required String toolbarKey,
  required List<String> options,
  required int itemIndex,
}) {
  var top =
      fortuneToolbarPopupTop +
      fortuneToolbarPopupContentTopPaddingFor(toolbarKey);
  for (var index = 0; index < itemIndex && index < options.length; index += 1) {
    top += options[index] == '|'
        ? fortuneToolbarMenuDividerHeight
        : fortuneToolbarPopupRowHeightFor(toolbarKey);
  }
  return top;
}

double _toolbarPopupLeftForKey(String toolbarKey, {double width = 1200}) {
  Rect? itemRect;
  for (final entry in fortuneVisibleToolbarItemRects(width)) {
    if (entry.key == toolbarKey) {
      itemRect = entry.value;
      break;
    }
  }
  return fortuneToolbarPopupLeftFor(
    key: toolbarKey,
    itemRect: itemRect,
    viewportWidth: width,
    popupWidth: fortuneToolbarPopupWidthFor(toolbarKey),
  );
}

Offset _borderColorPaletteItemCenter({
  required double popupLeft,
  required String hex,
  double viewportWidth = 1200,
}) {
  final topLevelWidth = fortuneToolbarPopupWidthFor(
    fortuneToolbarBorderPopupKey,
  );
  final desiredLeft = popupLeft + topLevelWidth;
  final left = desiredLeft + fortuneToolbarFontColorPopupWidth > viewportWidth
      ? math.max(
          fortuneToolbarPopupViewportMargin,
          popupLeft - fortuneToolbarFontColorPopupWidth,
        )
      : desiredLeft;
  final submenuTop =
      fortuneToolbarPopupTop +
      fortuneToolbarPopupHeightFor(
        fortuneToolbarBorderPopupKey,
        fortuneToolbarBorderPopupCommands,
      ) -
      fortuneToolbarFontColorPopupHeight;
  for (var row = 0; row < fortuneToolbarColorPickerPalette.length; row += 1) {
    final colors = fortuneToolbarColorPickerPalette[row];
    for (var column = 0; column < colors.length; column += 1) {
      if (colors[column] == hex) {
        final step =
            fortuneToolbarColorPickerItemSize +
            fortuneToolbarColorPickerItemMargin * 2;
        return Offset(
          left +
              fortuneToolbarColorPickerPadding +
              column * step +
              fortuneToolbarColorPickerItemMargin +
              fortuneToolbarColorPickerItemSize / 2,
          submenuTop +
              fortuneToolbarFontColorPickerTop +
              fortuneToolbarColorPickerPadding +
              row * step +
              fortuneToolbarColorPickerItemMargin +
              fortuneToolbarColorPickerItemSize / 2,
        );
      }
    }
  }
  fail('border color palette item not found: $hex');
}
