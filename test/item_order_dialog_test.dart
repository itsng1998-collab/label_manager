import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/application/item_manager_order_service.dart';
import 'package:label_manager/features/item/presentation/item_order_dialog.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

void main() {
  test('builds one-based order updates and forwards them to the writer', () async {
    final orderedItems = [
      _item(itemId: 3, name: '셋째 품목'),
      _item(itemId: 1, name: '첫째 품목'),
      _item(itemId: 2, name: '둘째 품목'),
    ];
    List<ItemOrderUpdate>? savedUpdates;

    await saveItemManagerOrder(
      orderedItems: orderedItems,
      save: (updates) async => savedUpdates = updates,
    );

    expect(savedUpdates?.map((value) => value.itemId), [3, 1, 2]);
    expect(savedUpdates?.map((value) => value.order), [1, 2, 3]);
  });

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
                  selectedItemId: 2,
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
      find.widgetWithText(FilledButton, '저장'),
    );
    expect(applyButton.onPressed, isNull);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.byType(EditableSwipeNameTable<ItemOfMarket>),
      findsOneWidget,
    );
    final upButton = find.byKey(const ValueKey('item-order-up'));
    final downButton = find.byKey(const ValueKey('item-order-down'));
    expect(upButton, findsOneWidget);
    expect(downButton, findsOneWidget);
    expect(tester.getSize(upButton), const Size(34, 34));
    expect(tester.getSize(downButton), const Size(34, 34));
    expect(tester.getTopLeft(downButton).dy - tester.getBottomLeft(upButton).dy, 8);
    expect(
      tester.widget<OutlinedButton>(
        find.descendant(of: upButton, matching: find.byType(OutlinedButton)),
      ).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<OutlinedButton>(
        find.descendant(of: downButton, matching: find.byType(OutlinedButton)),
      ).onPressed,
      isNotNull,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('둘째 품목')),
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('첫째 품목')));
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('둘째 품목')).dy,
      lessThan(tester.getTopLeft(find.text('첫째 품목')).dy),
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
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
    await tester.tap(find.text('취소'));
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
