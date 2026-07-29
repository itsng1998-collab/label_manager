import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';

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

  test('zoom controller delegates only while the same setter is bound', () {
    final controller = LabelSheetZoomController();
    addTearDown(controller.dispose);
    final delegated = <int>[];
    void boundSetter(int percent) => delegated.add(percent);
    void otherSetter(int percent) {}

    controller.bindZoomSetter(boundSetter);
    controller.setZoomPercent(450);
    controller.unbindZoomSetter(otherSetter);
    controller.setZoomPercent(460);

    expect(delegated, [450, 460]);
    expect(controller.value, labelSheetDefaultZoomPercent);

    controller.unbindZoomSetter(boundSetter);
    controller.setZoomPercent(450);

    expect(delegated, [450, 460]);
    expect(controller.value, labelSheetMaxZoomPercent);
  });

  test('zoom controller applies initial auto fit once', () {
    final controller = LabelSheetZoomController();
    addTearDown(controller.dispose);

    controller.applyInitialAutoFit(150);
    controller.applyInitialAutoFit(200);

    expect(controller.value, 150);
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