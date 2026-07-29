import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';

void main() {
  testWidgets('zoom toolbar follows controller and steps by ten', (
    tester,
  ) async {
    final controller = LabelSheetZoomController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LabelSheetZoomToolbar(controller: controller)),
      ),
    );

    controller.setZoomPercent(150);
    await tester.pump();
    expect(_zoomInputText(tester), '150');

    await tester.tap(find.text('-'));
    await tester.pump();
    expect(controller.value, 140);
    expect(_zoomInputText(tester), '140');

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(controller.value, 150);
    expect(_zoomInputText(tester), '150');
  });

  testWidgets('zoom toolbar clamps submitted input to controller bounds', (
    tester,
  ) async {
    final controller = LabelSheetZoomController(minPercent: 20, maxPercent: 500);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LabelSheetZoomToolbar(controller: controller)),
      ),
    );
    final input = find.byKey(const ValueKey('label-sheet-zoom-input'));

    await tester.enterText(input, '600');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.value, 500);
    expect(_zoomInputText(tester), '500');

    await tester.enterText(input, '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.value, 20);
    expect(_zoomInputText(tester), '20');
  });
}

String _zoomInputText(WidgetTester tester) => tester
    .widget<EditableText>(
      find.byKey(const ValueKey('label-sheet-zoom-input')),
    )
    .controller
    .text;
