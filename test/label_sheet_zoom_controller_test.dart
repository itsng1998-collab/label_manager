import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';

void main() {
  test('zoom controller preserves default bounds', () {
    final controller = LabelSheetZoomController();
    addTearDown(controller.dispose);

    controller.setZoomPercent(500);
    expect(controller.value, labelSheetMaxZoomPercent);
    controller.setZoomPercent(0);
    expect(controller.value, labelSheetMinZoomPercent);
  });

  test('zoom controller accepts dialog-specific bounds', () {
    final controller = LabelSheetZoomController(
      initialPercent: 100,
      minPercent: 20,
      maxPercent: 500,
    );
    addTearDown(controller.dispose);

    controller.setZoomPercent(600);
    expect(controller.value, 500);
    controller.setZoomPercent(10);
    expect(controller.value, 20);
  });

  testWidgets('workbench preserves dialog-specific 500 percent zoom', (
    tester,
  ) async {
    final controller = LabelSheetZoomController(
      initialPercent: 500,
      minPercent: 20,
      maxPercent: 500,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelSheetWorkbench(
            initialWorkbook: FortuneWorkbook(
              sheets: [FortuneSheet(id: 'sheet1', name: 'Sheet 1')],
            ),
            hideToolbar: true,
            zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
            zoomController: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.value, 500);
  });
}