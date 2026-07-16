import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/label_print_page.dart';

void main() {
  test('line spacing parser keeps null distinct from explicit 100', () {
    expect(parseLabelPrintLineSpacing(''), isNull);
    expect(parseLabelPrintLineSpacing(' 0 '), isNull);
    expect(parseLabelPrintLineSpacing('100'), 100);
    expect(() => parseLabelPrintLineSpacing('29'), throwsFormatException);
    expect(() => parseLabelPrintLineSpacing('301'), throwsFormatException);
    expect(() => parseLabelPrintLineSpacing('abc'), throwsFormatException);
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