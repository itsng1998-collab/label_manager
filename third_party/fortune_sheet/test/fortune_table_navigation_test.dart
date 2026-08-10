import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  testWidgets('Enter and Tab move to the next editable cell across rows', (
    tester,
  ) async {
    final values = <List<String>>[
      ['A1', 'skip', 'C1'],
      ['A2', 'skip', 'C2'],
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 240,
            child: StatefulBuilder(
              builder: (context, setState) => FortuneTable<int>(
                rows: const [0, 1],
                columns: [
                  FortuneTableColumn<int>(
                    id: 'a',
                    header: 'A',
                    text: (row) => values[row][0],
                    onTextCommitted: (row, _, value) async {
                      setState(() => values[row][0] = value);
                    },
                  ),
                  FortuneTableColumn<int>(
                    id: 'skip',
                    header: 'skip',
                    text: (row) => values[row][1],
                  ),
                  FortuneTableColumn<int>(
                    id: 'c',
                    header: 'C',
                    text: (row) => values[row][2],
                    onTextCommitted: (row, _, value) async {
                      setState(() => values[row][2] = value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('A1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('A1'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'changed');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(values[0][0], 'changed');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'C1',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'A2',
    );
  });

  testWidgets('drag selection autoscrolls only beyond the table boundary', (
    tester,
  ) async {
    final selection = FortuneTableSelectionController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              height: 180,
              child: FortuneTable<int>(
                rows: List<int>.generate(30, (index) => index),
                columns: [
                  FortuneTableColumn<int>(
                    id: 'value',
                    header: '값',
                    text: (row) => 'row-$row',
                  ),
                ],
                selectionController: selection,
                multiSelectionEnabled: true,
              ),
            ),
          ),
        ),
      ),
    );

    final tableRect = tester.getRect(find.byType(FortuneTable<int>));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('row-0')),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(Offset(tableRect.center.dx, tableRect.bottom + 30));
    await tester.pump(const Duration(milliseconds: 320));
    await gesture.up();
    await tester.pump();

    expect(selection.selectedRows.length, greaterThan(4));
    expect(selection.selectedRows.first, 0);
  });
}