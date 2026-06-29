import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_canvas.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';

void main() {
  testWidgets('active cell editor cursor is black', (tester) async {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 360,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(83, 100));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.cursorColor, const Color(0xff000000));
  });
}
