import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  testWidgets('committing multiline edit in merged cell keeps row height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = FortuneSheetController();
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(1, 1): const FortuneCell(
              value: 'start',
              textWrap: '2',
              merge: FortuneCellMerge(
                row: 1,
                column: 1,
                rowSpan: 2,
                columnSpan: 2,
              ),
            ),
            const FortuneCellCoord(1, 2): const FortuneCell(
              merge: FortuneCellMerge(row: 1, column: 1),
            ),
            const FortuneCellCoord(2, 1): const FortuneCell(
              merge: FortuneCellMerge(row: 1, column: 1),
            ),
            const FortuneCellCoord(2, 2): const FortuneCell(
              merge: FortuneCellMerge(row: 1, column: 1),
            ),
          },
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 640,
                height: 760,
                child: FortuneSheetCanvas(
                  workbook: workbook,
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester.widget<CustomPaint>(find.byType(CustomPaint)).painter!
          as FortuneSheetPainter;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(40, 60));
    await tester.pump();
    controller.setSelection(const [
      FortuneRange(rowStart: 1, rowEnd: 1, columnStart: 1, columnEnd: 1),
    ]);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    tester.testTextInput.enterText(
      'ABCDEFGHIJKLMN\nABCDEFGHIJKLMN\nABCDEFGHIJKLMN\nABCDEFGHIJKLMN',
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    final sheet = painter().workbook.activeSheet;
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      contains('\n'),
    );
    expect(sheet.rowHeights.containsKey(1), isFalse);
    expect(sheet.customHeight.containsKey(1), isFalse);
    expect(sheet.columnWidths.containsKey(1), isFalse);
    expect(sheet.customWidth.containsKey(1), isFalse);
  });
}
