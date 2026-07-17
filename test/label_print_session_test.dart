import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/label_print_page.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_print_settings_dialog.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';

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
    controller.requestCancel();
    expect(controller.cancellationRequested, isTrue);
    controller.endIssue();
    expect(controller.busy, isFalse);
    expect(controller.cancellationRequested, isFalse);
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
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '110');
    final zoomPositionBeforeDrag = tester.getTopLeft(zoomInput);

    await tester.drag(
      find.byKey(const ValueKey('label-print-splitter')),
      const Offset(120, 0),
    );
    await tester.pump();

    expect(tester.widget<EditableText>(zoomInput).controller.text, '110');
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
    expect(shiftedInputs, findsNWidgets(7));

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