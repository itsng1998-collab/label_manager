import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/page_home/item_order_dialog.dart';

void main() {
  testWidgets('moves the selected item and returns the changed order', (
    tester,
  ) async {
    List<ItemOfMarket>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<List<ItemOfMarket>>(
                context: context,
                builder: (_) => ItemOrderDialog(
                  items: [
                    _item(itemId: 1, name: '첫째 품목'),
                    _item(itemId: 2, name: '둘째 품목'),
                    _item(itemId: 3, name: '셋째 품목'),
                  ],
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    final applyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '적용'),
    );
    expect(applyButton.onPressed, isNull);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('item-order-down')));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('둘째 품목')).dy,
      lessThan(tester.getTopLeft(find.text('첫째 품목')).dy),
    );
    await tester.tap(find.widgetWithText(FilledButton, '적용'));
    await tester.pumpAndSettle();

    expect(result?.map((value) => value.item.itemId), [2, 1, 3]);
  });

  testWidgets('close returns no order change', (tester) async {
    List<ItemOfMarket>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<List<ItemOfMarket>>(
                context: context,
                builder: (_) => ItemOrderDialog(
                  items: [
                    _item(itemId: 1, name: '첫째 품목'),
                    _item(itemId: 2, name: '둘째 품목'),
                  ],
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}

ItemOfMarket _item({required int itemId, required String name}) {
  final now = DateTime(2026, 7, 8);
  return ItemOfMarket(
    marketId: 1,
    item: Item(
      itemId: itemId,
      labelSizeId: 20,
      itemName: name,
      labelSizeName: '테스트 라벨',
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
    dateSaleStart: now,
    dateSaleEnd: now,
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: now,
    dateEndDiscount: now,
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 0,
    useScaleBarcode: false,
    printCount: 1,
    useLabelSize: false,
    labelSizeWidth: 0,
    labelSizeHeight: 0,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );
}
