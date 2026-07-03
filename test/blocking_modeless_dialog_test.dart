import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

void main() {
  testWidgets('frame renders shared title bar body footer and close action', (
    tester,
  ) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialogFrame(
          title: '공통 설정',
          width: 240,
          height: 160,
          onClose: () => closeCount += 1,
          footer: const Text('footer'),
          child: const Text('body'),
        ),
      ),
    );

    expect(find.text('공통 설정'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.text('footer'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    expect(closeCount, 1);
  });

  testWidgets('blocks pointer events outside dialog content', (tester) async {
    var outsideTapCount = 0;
    var insideTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => outsideTapCount += 1,
              ),
            ),
            BlockingModelessDialog(
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => insideTapCount += 1,
                    child: const Text('inside'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.tap(find.text('inside'));

    expect(outsideTapCount, 0);
    expect(insideTapCount, 1);
  });

  testWidgets('blocks key events from focused widget behind overlay', (
    tester,
  ) async {
    var outsideKeyCount = 0;
    final outsideFocus = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Focus(
              focusNode: outsideFocus,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  outsideKeyCount += 1;
                }
                return KeyEventResult.handled;
              },
              child: const SizedBox.expand(),
            ),
            const BlockingModelessDialog(
              child: Center(child: Text('dialog')),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);

    expect(outsideKeyCount, 0);

    outsideFocus.dispose();
  });
}