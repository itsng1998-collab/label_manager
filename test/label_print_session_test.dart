import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/features/label_print/presentation/label_print_page.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_print_settings_dialog.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('line spacing parser keeps null distinct from explicit 100', () {
    expect(parseLabelPrintLineSpacing(''), isNull);
    expect(parseLabelPrintLineSpacing(' 0 '), isNull);
    expect(parseLabelPrintLineSpacing('100'), 100);
    expect(() => parseLabelPrintLineSpacing('29'), throwsFormatException);
    expect(() => parseLabelPrintLineSpacing('301'), throwsFormatException);
    expect(() => parseLabelPrintLineSpacing('abc'), throwsFormatException);
  });

  test('label print settings use legacy line spacing defaults', () {
    expect(
      const LabelPrintSettingsSnapshot.empty().lineSpacingPercent,
      100,
    );
    final items = LabelSheetPrintSettingsDialog.buildAutoSpacingItems(
      minimum: 80,
      step: 5,
      includePercent: true,
    );
    expect(
      items.map((item) => item.value),
      ['none', for (var value = 80; value <= 300; value += 5) '$value'],
    );
  });

  test('preview projection fingerprint is stable by content', () {
    expect(
      labelOutputPreviewValuesFingerprint(const {2: 'B', 1: 'A'}),
      labelOutputPreviewValuesFingerprint(<int, String>{1: 'A', 2: 'B'}),
    );
    expect(
      labelOutputPreviewValuesFingerprint(const {1: 'A'}),
      isNot(labelOutputPreviewValuesFingerprint(const {1: 'B'})),
    );
  });

  test('issue lifecycle blocks duplicates and resets cancellation', () {
    final controller = LabelPrintSessionController();

    expect(controller.beginIssue(), isTrue);
    expect(controller.busy, isTrue);
    expect(controller.beginIssue(), isFalse);
    controller.reportIssueUnit(unitNumber: 2, totalUnits: 3);
    expect(controller.issueUnitNumber, 2);
    expect(controller.issueTotalUnits, 3);
    controller.requestCancel();
    expect(controller.cancellationRequested, isTrue);
    controller.endIssue();
    expect(controller.busy, isFalse);
    expect(controller.cancellationRequested, isFalse);
    expect(controller.issueUnitNumber, 0);
    expect(controller.issueTotalUnits, 0);
  });

  testWidgets('print progress dialog updates and requests cancellation', (
    tester,
  ) async {
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    controller.beginIssue();
    controller.reportIssueUnit(unitNumber: 1, totalUnits: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialog(
          child: LabelPrintProgressDialog(
            controller: controller,
            onCancel: controller.requestCancel,
          ),
        ),
      ),
    );

    expect(find.text('1/3번째를 발행중입니다...'), findsOneWidget);
    controller.reportIssueUnit(unitNumber: 2, totalUnits: 3);
    await tester.pump();
    expect(find.text('2/3번째를 발행중입니다...'), findsOneWidget);

    await tester.tap(find.text('취소'));
    expect(controller.cancellationRequested, isTrue);
  });

  const labelSize = LabelSize(
    labelSizeId: 1,
    brandId: 1,
    labelSizeName: '중형',
    labelSizeCommon: LabelSizeCommon(width: 60, height: 40, rtf: ''),
  );

  LabelPrintRowDraft createRow(ItemOfMarket item) =>
      LabelPrintRowDraft.fromBaseline(
        item: item,
        labelSize: labelSize,
        copies: item.printCount,
        settings: const LabelPrintSettingsSnapshot.empty(),
      );

  test('transient issue rows restore edited session rows and selection', () {
    final first = _item(10, '첫째', copies: 1);
    final second = _item(20, '둘째', copies: 2);
    final transient = _item(30, '검색 품목', copies: 3);
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    controller.syncCheckedItems(
      baselineItems: [first, second],
      checkedItemIds: const <int>{10, 20},
      createRow: createRow,
    );
    controller.editCopies(10, 7);
    controller.selectItem(20);

    final snapshot = controller.replaceRowsForIssue([createRow(transient)]);
    expect(controller.rows.single.itemId, 30);
    expect(controller.selectedItemId, 30);

    controller.restoreRowsAfterIssue(snapshot);
    expect(controller.rows.map((row) => row.itemId), [10, 20]);
    expect(controller.rows.first.copies, 7);
    expect(controller.selectedItemId, 20);
  });

  test('session keeps baseline order and discards unchecked row edits', () {
    final first = _item(10, '첫째', copies: 1);
    final second = _item(20, '둘째', copies: 2);
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);

    controller.syncCheckedItems(
      baselineItems: [first, second],
      checkedItemIds: const <int>{20, 10},
      createRow: createRow,
    );
    expect(controller.rows.map((row) => row.itemId), [10, 20]);
    expect(controller.selectedItemId, 10);

    controller.editCopies(10, 7);
    controller.syncCheckedItems(
      baselineItems: [second, first],
      checkedItemIds: const <int>{10, 20},
      createRow: createRow,
    );
    expect(controller.rows.map((row) => row.itemId), [20, 10]);
    expect(controller.rows.last.copies, 7);
    expect(controller.rows.last.copiesSource, LabelPrintValueSource.sessionEdited);

    controller.syncCheckedItems(
      baselineItems: [first, second],
      checkedItemIds: const <int>{20},
      createRow: createRow,
    );
    controller.syncCheckedItems(
      baselineItems: [first, second],
      checkedItemIds: const <int>{10, 20},
      createRow: createRow,
    );
    expect(controller.rows.first.copies, 1);
    expect(controller.rows.first.copiesSource, LabelPrintValueSource.itemBaseline);
  });

  test('row baseline tracks item and fallback sources field by field', () {
    final fallback = createRow(_item(10, '기본', copies: 1));
    expect(fallback.widthMm, 60);
    expect(fallback.widthSource, LabelPrintValueSource.labelSizeFallback);
    expect(fallback.leftMarginSource, LabelPrintValueSource.preferenceFallback);

    final overridden = LabelPrintRowDraft.fromBaseline(
      item: _item(20, '재정의', copies: 2, useOverrides: true),
      labelSize: labelSize,
      copies: 2,
      settings: const LabelPrintSettingsSnapshot.empty(),
    );
    expect(overridden.widthMm, 55);
    expect(overridden.widthSource, LabelPrintValueSource.itemOverride);
    expect(overridden.leftMarginMm, 1.5);
    expect(overridden.lineSpacingPercent, isNull);
    expect(overridden.lineSpacingSource, LabelPrintValueSource.itemOverride);
  });

  test('exact search starts after selection and wraps in baseline order', () {
    final first = _item(10, '같은 품목', copies: 1);
    final second = _item(20, '다른 품목', copies: 1);
    final third = _item(30, '같은 품목', copies: 1);
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    controller.syncCheckedItems(
      baselineItems: [first, second, third],
      checkedItemIds: const <int>{10, 20, 30},
      createRow: createRow,
    );

    expect(
      controller.selectNextExact(' 같은 품목 ', (row) => [row.item.item.itemName]),
      isTrue,
    );
    expect(controller.selectedItemId, 30);
    expect(
      controller.selectNextExact('같은 품목', (row) => [row.item.item.itemName]),
      isTrue,
    );
    expect(controller.selectedItemId, 10);
    expect(controller.selectNextExact('같', (row) => [row.item.item.itemName]), isFalse);
  });

  test('settings update only preference fallback row values', () {
    final fallback = _item(10, '기본', copies: 1);
    final overridden = _item(20, '재정의', copies: 1, useOverrides: true);
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    controller.syncCheckedItems(
      baselineItems: [fallback, overridden],
      checkedItemIds: const <int>{10, 20},
      createRow: createRow,
    );
    controller.updateRow(
      10,
      (row) => row.copyWith(
        topMarginMm: 9,
        topMarginSource: LabelPrintValueSource.sessionEdited,
      ),
    );

    controller.applySettings(
      const LabelPrintSettingsSnapshot(
        printerName: 'Godex G500',
        leftMarginMm: 4,
        rightMarginMm: 5,
        topMarginMm: 6,
        leftPushMm: -2,
        topPushMm: 3,
        lineSpacingPercent: 125,
        extraAreaMm: 2,
        orientation: LabelPrintOrientation.vertical,
      ),
    );

    expect(controller.rows[0].leftMarginMm, 4);
    expect(controller.rows[0].topMarginMm, 9);
    expect(controller.rows[0].lineSpacingPercent, 125);
    expect(controller.rows[1].leftMarginMm, 1.5);
    expect(controller.rows[1].lineSpacingPercent, isNull);
    expect(controller.settings.printerName, 'Godex G500');
  });

  testWidgets('issue command stays left and splitter resizes panes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelPrintPage(
            controller: controller,
            previewBuilder: (_, _) => const SizedBox(),
            onPrinterSettings: () {},
            onIssue: () {},
            onCancelIssue: () {},
            busy: false,
          ),
        ),
      ),
    );

    final settingsCenter = tester.getCenter(find.text('프린터 설정'));
    final issueCenter = tester.getCenter(find.text('발행'));
    expect(issueCenter.dx, greaterThan(settingsCenter.dx));
    expect(issueCenter.dx, lessThan(600));

    final splitter = find.byKey(const ValueKey('label-print-splitter'));
    expect(tester.widget(splitter), isA<VerticalPaneSplitter>());
    final before = tester.getCenter(splitter).dx;
    await tester.drag(splitter, const Offset(120, 0));
    await tester.pump();
    expect(tester.getCenter(splitter).dx, closeTo(before + 120, 1));
  });

  testWidgets('issue command is disabled when print table is empty', (
    tester,
  ) async {
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelPrintPage(
            controller: controller,
            previewBuilder: (_, _) => const SizedBox(),
            onPrinterSettings: () {},
            onIssue: () {},
            onCancelIssue: () {},
            busy: false,
          ),
        ),
      ),
    );

    final issueButton = tester.widget<FilledButton>(
      find.ancestor(of: find.text('발행'), matching: find.byType(FilledButton)),
    );
    expect(issueButton.onPressed, isNull);
  });

  testWidgets('issue progress scrolls the selected print row into view', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    final items = List<ItemOfMarket>.generate(
      100,
      (index) => _item(index + 1, '발행행-$index', copies: 1),
    );
    controller.syncCheckedItems(
      baselineItems: items,
      checkedItemIds: items.map((item) => item.item.itemId).toSet(),
      createRow: createRow,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelPrintPage(
            controller: controller,
            previewBuilder: (_, _) => const SizedBox(),
            onPrinterSettings: () {},
            onIssue: () {},
            onCancelIssue: () {},
            busy: false,
          ),
        ),
      ),
    );

    expect(find.text('발행행-80'), findsNothing);
    controller.beginIssue();
    controller.reportIssueUnit(unitNumber: 1, totalUnits: 100);
    controller.selectItem(81);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('발행행-80'), findsOneWidget);
  });

  testWidgets('label print splitter keeps preview zoom', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = LabelPrintSessionController();
    addTearDown(controller.dispose);
    final item = _item(10, '미리보기', copies: 1);
    controller.syncCheckedItems(
      baselineItems: [item],
      checkedItemIds: const {10},
      createRow: createRow,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelPrintPage(
            controller: controller,
            previewBuilder: (_, zoomController) {
              final projected = <int, String>{1: '고정 값'};
              return LabelOutputPreview(
                workbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 'sheet', name: '라벨')],
                ),
                hintText: null,
                identityKey:
                    'preview:${labelOutputPreviewValuesFingerprint(projected)}',
                imageObjectIds: const [],
                barcodeObjectIds: const [],
                zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
                zoomController: zoomController,
              );
            },
            onPrinterSettings: () {},
            onIssue: () {},
            onCancelIssue: () {},
            busy: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final zoomInput = find.byKey(const ValueKey('label-sheet-zoom-input'));
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '160');
    final zoomPositionBeforeDrag = tester.getTopLeft(zoomInput);

    await tester.drag(
      find.byKey(const ValueKey('label-print-splitter')),
      const Offset(120, 0),
    );
    await tester.pump();

    expect(tester.widget<EditableText>(zoomInput).controller.text, '160');
    expect(tester.getTopLeft(zoomInput), zoomPositionBeforeDrag);
    final zoomToolbar = find.byKey(
      const ValueKey('label-sheet-zoom-toolbar'),
    );
    final page = find.byType(LabelPrintPage);
    expect(
      tester.getCenter(zoomToolbar).dy,
      closeTo(tester.getBottomRight(page).dy - 24, 0.1),
    );
    expect(
      tester.getTopRight(zoomToolbar).dx,
      closeTo(tester.getTopRight(page).dx - 12, 0.1),
    );
  });

  testWidgets('label print zoom defaults to 150 and survives row changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = LabelPrintSessionController();
    final captureController = LabelSheetOutputCaptureController();
    addTearDown(controller.dispose);
    final first = _item(10, '첫 번째', copies: 1);
    final second = _item(20, '두 번째', copies: 1);
    controller.syncCheckedItems(
      baselineItems: [first, second],
      checkedItemIds: const {10, 20},
      createRow: createRow,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelPrintPage(
            controller: controller,
            previewBuilder: (row, zoomController) => LabelOutputPreview(
              workbook: FortuneWorkbook(
                sheets: [
                  FortuneSheet(
                    id: 'sheet-${row.itemId}',
                    name: '라벨',
                    zoomRatio: row.itemId == 10 ? 0.8 : 2.0,
                    cells: {
                      const FortuneCellCoord(0, 0): FortuneCell(
                        value: '내용-${row.itemId}',
                      ),
                    },
                  ),
                ],
              ),
              hintText: null,
              identityKey: 'preview:${row.itemId}',
              imageObjectIds: const [],
              barcodeObjectIds: const [],
              outputCaptureController: captureController,
              zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
              zoomController: zoomController,
            ),
            onPrinterSettings: () {},
            onIssue: () {},
            onCancelIssue: () {},
            busy: false,
          ),
        ),
      ),
    );
    expect(
      captureController
          .debugActiveSheet
          ?.cells[const FortuneCellCoord(0, 0)]
          ?.value,
      '내용-10',
    );
    expect(captureController.debugActiveSheet?.zoomRatio, 1.5);
    await tester.pump();
    await tester.pump();
    final hybrid = await tester.runAsync(
      () => captureController.captureHybridEzpl(
        metrics: const LabelSheetPrintPageMetrics(
          labelWidthMm: 60,
          labelHeightMm: 40,
          dpi: 96,
        ),
        options: const LabelSheetPrintOptions(
          copies: 1,
          leftMarginMm: 0,
          topMarginMm: 0,
          extraAreaMm: 0,
          autoSpacingPercent: null,
          orientation: LabelSheetPrintOrientation.horizontal,
        ),
        lineSpacingPercent: null,
      ),
    );
    expect(hybrid, isNotNull);
    expect(hybrid!.bytes, isNotEmpty);
    expect(hybrid.metrics.sourceWidthMm, isNotNull);
    expect(hybrid.metrics.sourceHeightMm, isNotNull);
    expect(hybrid.sheet.id, 'sheet-10');

    final zoomInput = find.byKey(const ValueKey('label-sheet-zoom-input'));
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '160');

    await tester.tap(find.text('두 번째'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-print-preview-slot:20')),
      findsOneWidget,
    );
    expect(tester.widget<EditableText>(zoomInput).controller.text, '160');
    expect(
      captureController
          .debugActiveSheet
          ?.cells[const FortuneCellCoord(0, 0)]
          ?.value,
      '내용-20',
    );
    expect(captureController.debugActiveSheet?.zoomRatio, 1.6);
    await tester.pump();

    await tester.tap(find.text('첫 번째'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-print-preview-slot:10')),
      findsOneWidget,
    );
    expect(tester.widget<EditableText>(zoomInput).controller.text, '160');
    expect(
      captureController
          .debugActiveSheet
          ?.cells[const FortuneCellCoord(0, 0)]
          ?.value,
      '내용-10',
    );
    expect(captureController.debugActiveSheet?.zoomRatio, 1.6);
    await tester.pump();
  });

  testWidgets('output capture controller rejects a second attached owner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final captureController = LabelSheetOutputCaptureController();
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(
              child: LabelSheetWorkbench(
                initialWorkbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 'first', name: 'First')],
                ),
                outputCaptureController: captureController,
              ),
            ),
            Expanded(
              child: LabelSheetWorkbench(
                initialWorkbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 'second', name: 'Second')],
                ),
                outputCaptureController: captureController,
              ),
            ),
          ],
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(captureController.isAttached, isTrue);
    expect(captureController.debugActiveSheet?.id, 'first');
  });

  testWidgets('output capture controller allows remount with same owner token', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final captureController = LabelSheetOutputCaptureController();

    Widget buildWorkbench(Key key, String sheetId) {
      return MaterialApp(
        home: LabelSheetWorkbench(
          key: key,
          initialWorkbook: FortuneWorkbook(
            sheets: [FortuneSheet(id: sheetId, name: 'Sheet')],
          ),
          outputCaptureController: captureController,
          outputCaptureOwnerToken: 'same-owner',
        ),
      );
    }

    await tester.pumpWidget(buildWorkbench(const ValueKey('first'), 'first'));
    expect(tester.takeException(), isNull);
    expect(captureController.debugActiveSheet?.id, 'first');

    await tester.pumpWidget(buildWorkbench(const ValueKey('second'), 'second'));
    expect(tester.takeException(), isNull);
    expect(captureController.isAttached, isTrue);
    expect(captureController.debugActiveSheet?.id, 'second');
  });

  testWidgets('started output capture survives workbench detach', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final captureController = LabelSheetOutputCaptureController();
    await tester.pumpWidget(
      MaterialApp(
        home: LabelSheetWorkbench(
          initialWorkbook: FortuneWorkbook(
            sheets: [
              FortuneSheet(
                id: 'captured',
                name: 'Captured',
                cells: {
                  const FortuneCellCoord(0, 0): const FortuneCell(
                    value: 'snapshot',
                  ),
                },
              ),
            ],
          ),
          outputCaptureController: captureController,
          outputCaptureOwnerToken: 'capture-owner',
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final captureFuture = captureController.capture(
      dpi: 96,
      lineSpacingPercent: null,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(captureController.isAttached, isFalse);

    final capture = await tester.runAsync(() => captureFuture);
    expect(capture, isNotNull);
    expect(capture!.sheet.id, 'captured');
    expect(capture.pngBytes, isNotEmpty);
  });

  testWidgets('label output preview accepts external zoom controller', (
    tester,
  ) async {
    final zoomController = LabelSheetZoomController();
    addTearDown(zoomController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelOutputPreview(
            workbook: FortuneWorkbook(
              sheets: [FortuneSheet(id: 'sheet', name: '라벨')],
            ),
            hintText: null,
            identityKey: 'label-print-test',
            imageObjectIds: const [],
            barcodeObjectIds: const [],
            zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
            zoomController: zoomController,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.widget<LabelSheetWorkbench>(find.byType(LabelSheetWorkbench))
          .zoomController,
      same(zoomController),
    );
  });

  testWidgets('printer settings uses common label dialog styling', (
    tester,
  ) async {
    late BuildContext dialogContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dialogContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final result = showLabelPrintSettingsDialog(
      context: dialogContext,
      initial: const LabelPrintSettingsSnapshot(
        printerName: 'Microsoft Print to PDF',
        leftMarginMm: 1,
        rightMarginMm: 2,
        topMarginMm: 3,
        leftPushMm: 0,
        topPushMm: 0,
        lineSpacingPercent: 100,
        extraAreaMm: 0,
        orientation: LabelPrintOrientation.horizontal,
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-print-settings-dialog')),
      findsOneWidget,
    );
    expect(find.byType(LabelSheetPrintSettingsDialog), findsOneWidget);
    expect(find.text('여백'), findsOneWidget);
    expect(find.text('출력 조정'), findsOneWidget);
    expect(find.text('자동줄간격'), findsOneWidget);
    expect(find.text('출력 방향'), findsOneWidget);
    expect(find.text('발행 프린터'), findsOneWidget);
    final dialog = find.byKey(const ValueKey('label-print-settings-dialog'));
    final editableTexts = find.descendant(
      of: dialog,
      matching: find.byType(EditableText),
    );
    expect(editableTexts, findsNWidgets(6));
    final shiftedInputs = find.descendant(
      of: dialog,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Transform &&
            widget.transform.getTranslation().y == 4,
      ),
    );
    expect(shiftedInputs, findsNWidgets(6));
    final printerLabel = find.text('발행 프린터');
    final printerValue = find.byKey(
      const ValueKey('label-print-printer-value'),
    );
    final printerSelect = find.byKey(
      const ValueKey('label-print-printer-select'),
    );
    expect(
      tester.getCenter(printerLabel).dy,
      closeTo(tester.getCenter(printerValue).dy, 0.1),
    );
    expect(
      tester.getCenter(printerSelect).dy,
      closeTo(tester.getCenter(printerValue).dy, 0.1),
    );

    await tester.tap(find.text('100 %'));
    await tester.pumpAndSettle();
    expect(find.text('간격조정 없음'), findsWidgets);
    expect(find.text('80 %'), findsOneWidget);
    expect(find.text('85 %'), findsOneWidget);
    expect(find.text('81 %'), findsNothing);
    await tester.tap(find.text('100 %').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pump();
    expect(await result, isNull);
  });
}

ItemOfMarket _item(
  int itemId,
  String name, {
  required int copies,
  bool useOverrides = false,
}) => ItemOfMarket(
  marketId: 1,
  item: Item(
    itemId: itemId,
    labelSizeId: 1,
    itemName: name,
    labelSizeName: '중형',
    element: '',
    elementRTF: '',
    price: 0,
    order: itemId,
  ),
  additionalItem: AdditionalItem(
    AdditionalItemId: 0,
    itemId: itemId,
    element: '',
    elementRTF: '',
    price: 0,
  ),
  gdsNo: 0,
  dateSaleStart: DateTime(2026),
  dateSaleEnd: DateTime(2026),
  discountPercent: 0,
  discountAmount: 0,
  dateStartDiscount: DateTime(2026),
  dateEndDiscount: DateTime(2026),
  useDefineElement: false,
  rtfText: '',
  useLinefeed: useOverrides,
  linefeed: 0,
  useScaleBarcode: false,
  printCount: copies,
  useLabelSize: useOverrides,
  labelSizeWidth: 55,
  labelSizeHeight: 35,
  useMargin: useOverrides,
  leftMargin: 1.5,
  rightMargin: 2,
  topMargin: 3,
  leftPush: -1,
  topPush: 0.5,
);