import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/models/scale_output.dart';
import 'package:label_manager/page_home/scale_output_page.dart';

void main() {
  test('weight text strips units and spaces', () {
    expect(scaleOutputNormalizedWeightText(' 1.25 kg '), '1.25');
    expect(scaleOutputNormalizedWeightText('500 g'), '500');
    expect(scaleOutputNormalizedWeightText('  3.0  '), '3.0');
    expect(scaleOutputNormalizedWeightText(''), '');
  });

  test('price text follows legacy unit conversion and rounding', () {
    expect(
      scaleOutputComputePriceText(rawWeightText: '1.23kg', priceBaseText: '450'),
      '5540',
    );
    expect(
      scaleOutputComputePriceText(rawWeightText: '250g', priceBaseText: '800'),
      '2000',
    );
    expect(
      scaleOutputComputePriceText(rawWeightText: 'bad', priceBaseText: '800'),
      isNull,
    );
  });

  test('price text strips non-digit characters', () {
    expect(scaleOutputNormalizedPriceText('1,200원'), '1200');
    expect(scaleOutputNormalizedPriceText(' 30 00 '), '3000');
    expect(scaleOutputNormalizedPriceText('abc'), '');
  });

  test('serial settings accept only supported values', () {
    expect(scaleOutputIsSupportedBaudRate(9600), isTrue);
    expect(scaleOutputIsSupportedBaudRate(48000), isFalse);
    expect(scaleOutputIsSupportedDataBit(8), isTrue);
    expect(scaleOutputIsSupportedDataBit(9), isFalse);
    expect(scaleOutputIsSupportedStopBit(1), isTrue);
    expect(scaleOutputIsSupportedStopBit(3), isFalse);
  });

  test('scale issue blocks only multi-row scale jobs', () {
    expect(scaleOutputBlocksMultiIssue(useScale: true, rowCount: 2), isTrue);
    expect(scaleOutputBlocksMultiIssue(useScale: true, rowCount: 1), isFalse);
    expect(scaleOutputBlocksMultiIssue(useScale: false, rowCount: 3), isFalse);
  });

  test('scale issue confirmation is needed only for disconnected or empty weight', () {
    expect(
      scaleOutputNeedsIssueConfirmation(
        useScale: true,
        isConnected: false,
        weightText: '1.0',
      ),
      isTrue,
    );
    expect(
      scaleOutputNeedsIssueConfirmation(
        useScale: true,
        isConnected: true,
        weightText: '',
      ),
      isTrue,
    );
    expect(
      scaleOutputNeedsIssueConfirmation(
        useScale: true,
        isConnected: true,
        weightText: '1.0',
      ),
      isFalse,
    );
    expect(
      scaleOutputNeedsIssueConfirmation(
        useScale: false,
        isConnected: false,
        weightText: '',
      ),
      isFalse,
    );
  });

  test('scale output shows all baseline rows by default', () {
    expect(
      scaleOutputVisibleItemIds(
        showAllRows: true,
        baselineItems: [_item(), _item(itemId: 2, itemName: 'Second Item')],
        checkedItemIds: const <int>{2},
      ),
      <int>{1, 2},
    );
    expect(
      scaleOutputVisibleItemIds(
        showAllRows: false,
        baselineItems: [_item(), _item(itemId: 2, itemName: 'Second Item')],
        checkedItemIds: const <int>{2},
      ),
      <int>{2},
    );
  });

  test('incoming weight updates selected row weight and price', () {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(),
    );

    controller.applyIncomingWeight('1.25kg');

    expect(controller.selectedRow?.weightText, '1.25');
    expect(controller.selectedRow?.priceText, '5630');
    expect(controller.lastReceivedWeightRaw, '1.25kg');
  });

  test('manual price input is normalized before storing', () {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(),
    );

    controller.updateSelectedPrice('1,200원');

    expect(controller.selectedRow?.priceText, '1200');
  });

  test('sync refreshes baseline fields while preserving current weight and price', () {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(copies: 1, widthMm: 100, priceBaseText: '450'),
    );
    controller.updateSelectedWeight('1.5kg');
    controller.updateSelectedPrice('1,200원');

    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(copies: 3, widthMm: 120, priceBaseText: '900'),
    );

    expect(controller.selectedRow?.copies, 3);
    expect(controller.selectedRow?.widthMm, 120);
    expect(controller.selectedRow?.priceBaseText, '900');
    expect(controller.selectedRow?.weightText, '1.5');
    expect(controller.selectedRow?.priceText, '1200');
  });

  testWidgets('scale settings button is disabled while connected', (tester) async {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(),
    );
    controller.setConnectionState(
      ScaleOutputConnectionState.connected,
      statusText: '연결됨',
      portName: 'COM1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScaleOutputPage(
            controller: controller,
            previewBuilder: (_, __) => const SizedBox.shrink(),
            onPrinterSettings: () {},
            onScaleSettings: () {},
            onReloadAll: () {},
            onReloadSelected: () {},
            onIssue: () {},
            onCancelIssue: () {},
            onConnect: () {},
            onDisconnect: () {},
            useScale: true,
          ),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '저울 설정'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('preview switches immediately when selection changes', (tester) async {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item(), _item(itemId: 2, itemName: 'Second Item')],
      checkedItemIds: const {1, 2},
      createRow: (item) => _row(item: item),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScaleOutputPage(
            controller: controller,
            previewBuilder: (row, _) => Text('preview:${row.itemId}:${row.item.item.itemName}'),
            onPrinterSettings: () {},
            onScaleSettings: () {},
            onReloadAll: () {},
            onReloadSelected: () {},
            onIssue: () {},
            onCancelIssue: () {},
            onConnect: () {},
            onDisconnect: () {},
            useScale: true,
          ),
        ),
      ),
    );

    expect(find.text('preview:1:Scale Item'), findsOneWidget);

    controller.selectItem(2);
    await tester.pump();

    expect(find.text('preview:2:Second Item'), findsOneWidget);
    expect(find.text('preview:1:Scale Item'), findsNothing);
  });

  testWidgets('printer label updates when settings change', (tester) async {
    final controller = ScaleOutputSessionController(
      settings: const LabelPrintSettingsSnapshot.empty(),
    );
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScaleOutputPage(
            controller: controller,
            previewBuilder: (_, __) => const SizedBox.shrink(),
            onPrinterSettings: () {},
            onScaleSettings: () {},
            onReloadAll: () {},
            onReloadSelected: () {},
            onIssue: () {},
            onCancelIssue: () {},
            onConnect: () {},
            onDisconnect: () {},
            useScale: false,
          ),
        ),
      ),
    );

    expect(find.text('선택된 프린터 없음'), findsOneWidget);

    controller.applySettings(
      const LabelPrintSettingsSnapshot(
        printerName: 'Zebra-01',
        leftMarginMm: 0,
        rightMarginMm: 0,
        topMarginMm: 0,
        leftPushMm: 0,
        topPushMm: 0,
        lineSpacingPercent: 100,
        extraAreaMm: 0,
        orientation: LabelPrintOrientation.horizontal,
      ),
    );
    await tester.pump();

    expect(find.text('Zebra-01'), findsOneWidget);
    expect(find.text('선택된 프린터 없음'), findsNothing);
  });

  testWidgets('scale output context menu matches legacy commands and spacing', (
    tester,
  ) async {
    final controller = ScaleOutputSessionController();
    controller.syncCheckedItems(
      baselineItems: [_item()],
      checkedItemIds: const {1},
      createRow: (_) => _row(),
    );
    var reloadAllCount = 0;
    var reloadSelectedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScaleOutputPage(
            controller: controller,
            previewBuilder: (_, __) => const SizedBox.shrink(),
            onPrinterSettings: () {},
            onScaleSettings: () {},
            onReloadAll: () => reloadAllCount += 1,
            onReloadSelected: () => reloadSelectedCount += 1,
            onIssue: () {},
            onCancelIssue: () {},
            onConnect: () {},
            onDisconnect: () {},
            useScale: true,
          ),
        ),
      ),
    );

    final table = find.byType(FortuneTable<ScaleOutputRowDraft>);
    await tester.tapAt(tester.getCenter(table), buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();

    expect(find.text('전체내용 다시가져오기'), findsOneWidget);
    expect(find.text('선택내용 다시가져오기'), findsOneWidget);

    final reloadAllItem = tester.widget<PopupMenuItem<String>>(
      find.ancestor(
        of: find.text('전체내용 다시가져오기'),
        matching: find.byType(PopupMenuItem<String>),
      ),
    );
    final reloadSelectedItem = tester.widget<PopupMenuItem<String>>(
      find.ancestor(
        of: find.text('선택내용 다시가져오기'),
        matching: find.byType(PopupMenuItem<String>),
      ),
    );
    expect(reloadAllItem.height, fortuneContextMenuRowHeight);
    expect(reloadSelectedItem.height, fortuneContextMenuRowHeight);
    expect(reloadSelectedItem.enabled, isFalse);

    await tester.tap(find.text('전체내용 다시가져오기'));
    await tester.pumpAndSettle();

    expect(reloadAllCount, 1);
    expect(reloadSelectedCount, 0);
  });
}

ItemOfMarket _item({
  int itemId = 1,
  String itemName = 'Scale Item',
}) => ItemOfMarket(
  marketId: 1,
  item: Item(
    itemId: itemId,
    labelSizeId: 1,
    itemName: itemName,
    labelSizeName: 'LS',
    element: 'Element',
    elementRTF: '',
    price: 0,
    order: itemId,
  ),
  additionalItem: const AdditionalItem(
    AdditionalItemId: 1,
    itemId: 1,
    element: '',
    elementRTF: '',
    price: 0,
  ),
  gdsNo: 0,
  dateSaleStart: DateTime(2026, 1, 1),
  dateSaleEnd: DateTime(2026, 12, 31),
  discountPercent: 0,
  discountAmount: 0,
  dateStartDiscount: DateTime(2026, 1, 1),
  dateEndDiscount: DateTime(2026, 12, 31),
  useDefineElement: false,
  rtfText: '',
  useLinefeed: false,
  linefeed: 100,
  useScaleBarcode: false,
  printCount: 1,
  useLabelSize: false,
  labelSizeWidth: 100,
  labelSizeHeight: 50,
  useMargin: false,
  leftMargin: 0,
  rightMargin: 0,
  topMargin: 0,
  leftPush: 0,
  topPush: 0,
);

ScaleOutputRowDraft _row({
  ItemOfMarket? item,
  int copies = 1,
  int widthMm = 100,
  String priceBaseText = '450',
}) => ScaleOutputRowDraft(
  item: item ?? _item(),
  copies: copies,
  widthMm: widthMm,
  heightMm: 50,
  leftMarginMm: 0,
  rightMarginMm: 0,
  topMarginMm: 0,
  leftPushMm: 0,
  topPushMm: 0,
  lineSpacingPercent: 100,
  defaultWeightText: '',
  priceBaseText: priceBaseText,
  weightText: '',
  priceText: '',
  copiesSource: LabelPrintValueSource.itemBaseline,
  widthSource: LabelPrintValueSource.labelSizeFallback,
  heightSource: LabelPrintValueSource.labelSizeFallback,
  leftMarginSource: LabelPrintValueSource.preferenceFallback,
  rightMarginSource: LabelPrintValueSource.preferenceFallback,
  topMarginSource: LabelPrintValueSource.preferenceFallback,
  leftPushSource: LabelPrintValueSource.preferenceFallback,
  topPushSource: LabelPrintValueSource.preferenceFallback,
  lineSpacingSource: LabelPrintValueSource.preferenceFallback,
);
