import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_border_compute.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  testWidgets('toolbar border preserves mixed merged selection edges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const horizontalMerge = FortuneCellMerge(
      row: 1,
      column: 1,
      columnSpan: 2,
    );
    const verticalMerge = FortuneCellMerge(
      row: 2,
      column: 3,
      rowSpan: 2,
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(1, 1): const FortuneCell(
              value: 'B2:C2',
              merge: horizontalMerge,
            ),
            const FortuneCellCoord(1, 2): const FortuneCell(
              merge: FortuneCellMerge(row: 1, column: 1),
            ),
            const FortuneCellCoord(2, 3): const FortuneCell(
              value: 'D3:D4',
              merge: verticalMerge,
            ),
            const FortuneCellCoord(3, 3): const FortuneCell(
              merge: FortuneCellMerge(row: 2, column: 3),
            ),
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 1200,
          height: 360,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.dragFrom(
      topLeft + const Offset(156, 119),
      const Offset(146, 38),
    );
    await tester.pump();

    final itemRect = fortuneVisibleToolbarItemRects(1200)
        .singleWhere((entry) => entry.key == fortuneToolbarBorderPopupKey)
        .value;
    await tester.tapAt(
      topLeft + fortuneToolbarComboArrowRect(itemRect).center,
    );
    await tester.pump();

    final options = fortuneToolbarPopupItems[fortuneToolbarBorderPopupKey]!;
    final itemIndex = options.indexOf(fortuneToolbarBorderAllCommand);
    final popupLeft = fortuneToolbarPopupLeftFor(
      key: fortuneToolbarBorderPopupKey,
      itemRect: itemRect,
      viewportWidth: 1200,
      popupWidth: fortuneToolbarPopupWidthFor(fortuneToolbarBorderPopupKey),
    );
    await tester.tapAt(
      topLeft +
          Offset(
            popupLeft + 20,
            fortuneToolbarPopupTop +
                fortuneToolbarPopupContentTopPaddingFor(
                  fortuneToolbarBorderPopupKey,
                ) +
                fortuneToolbarPopupRowHeightFor(
                      fortuneToolbarBorderPopupKey,
                    ) *
                    itemIndex +
                fortuneToolbarPopupRowHeightFor(
                      fortuneToolbarBorderPopupKey,
                    ) /
                    2,
          ),
    );
    await tester.pump();

    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is FortuneSheetPainter,
      ),
    );
    final sheet = (paint.painter! as FortuneSheetPainter).workbook.activeSheet;
    final range = sheet.borderInfo.single.ranges.single;
    expect(range.rowStart, 1);
    expect(range.rowEnd, 3);
    expect(range.columnStart, 1);
    expect(range.columnEnd, 3);

    final borders = FortuneBorderCompute.compute(sheet);
    expect(borders[const FortuneCellCoord(3, 1)]?.left, isNotNull);
    expect(borders[const FortuneCellCoord(3, 1)]?.bottom, isNotNull);
    expect(borders[const FortuneCellCoord(3, 2)]?.bottom, isNotNull);
  });
}
