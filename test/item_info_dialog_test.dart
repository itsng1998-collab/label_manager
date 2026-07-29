import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/item/presentation/item_info_dialog.dart';

void main() {
  ItemOfMarket item() => ItemOfMarket(
    marketId: 7,
    item: const Item(
      itemId: 11,
      labelSizeId: 3,
      itemName: '품목 1',
      labelSizeName: '라벨 1',
      element: '',
      elementRTF: '',
      price: 0,
      order: 0,
    ),
    additionalItem: const AdditionalItem(
      AdditionalItemId: 0,
      itemId: 11,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: DateTime(2025),
    dateSaleEnd: DateTime(2025),
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: DateTime(2025),
    dateEndDiscount: DateTime(2025),
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 100,
    useScaleBarcode: false,
    printCount: 1,
    useLabelSize: false,
    labelSizeWidth: 300,
    labelSizeHeight: 200,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );

  Future<ItemInfoController> pumpContent(
    WidgetTester tester, {
    required int? marketId,
    required int? labelSizeId,
    required ItemInfoLoader load,
    ItemInfoSaver? save,
    ValueChanged<List<ItemOfMarket>>? onCommitted,
    VoidCallback? onClose,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ItemInfoController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemInfoDialogContent(
            controller: controller,
            marketId: marketId,
            labelSizeId: labelSizeId,
            load: load,
            save: save ?? (_) async {},
            onCommitted: onCommitted ?? (_) {},
            onCommitOutcomeUnknown: () {},
            onClose: onClose ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('missing main context opens empty without DAO call', (
    tester,
  ) async {
    var loadCalls = 0;
    final controller = await pumpContent(
      tester,
      marketId: null,
      labelSizeId: 3,
      load: (_, _) async {
        loadCalls += 1;
        return [item()];
      },
    );

    expect(loadCalls, 0);
    expect(controller.rows, isEmpty);
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('itemInfoSaveButton')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('bottom close button requests dialog close', (tester) async {
    var closeCalls = 0;
    await pumpContent(
      tester,
      marketId: 7,
      labelSizeId: 3,
      load: (_, _) async => [item()],
      onClose: () => closeCalls += 1,
    );

    expect(find.text('취소'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
    expect(
      tester.getCenter(find.byKey(const ValueKey('itemInfoCloseButton'))).dx,
      lessThan(
        tester.getCenter(find.byKey(const ValueKey('itemInfoSaveButton'))).dx,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('itemInfoCloseButton')));
    await tester.pump();

    expect(closeCalls, 1);
  });

  testWidgets('dependent edit saves batch and keeps committed rows', (
    tester,
  ) async {
    List<ItemOfMarket>? saved;
    List<ItemOfMarket>? committed;
    final controller = await pumpContent(
      tester,
      marketId: 7,
      labelSizeId: 3,
      load: (_, _) async => [item()],
      save: (values) async => saved = values,
      onCommitted: (values) => committed = values,
    );
    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    var linefeed = table.columns.firstWhere((column) => column.id == 'linefeed');
    expect(linefeed.isTextEditable!(controller.rows.single, 0), isFalse);

    final useLinefeed = table.columns.firstWhere(
      (column) => column.id == 'useLinefeed',
    );
    useLinefeed.onCheckboxChangedAt!(controller.rows.single, 0, true);
    await tester.pump();
    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    linefeed = table.columns.firstWhere((column) => column.id == 'linefeed');
    expect(linefeed.isTextEditable!(controller.rows.single, 0), isTrue);
    await linefeed.onTextCommitted!(controller.rows.single, 0, '110');
    await tester.pump();
    expect(controller.dirty, isTrue);

    await tester.tap(find.byKey(const ValueKey('itemInfoSaveButton')));
    await tester.pumpAndSettle();
    expect(saved?.single.linefeed, 110);
    expect(committed?.single.useLinefeed, isTrue);
    expect(controller.rows.single.linefeed, 110);
    expect(controller.dirty, isFalse);
    expect(find.text('품목 1'), findsOneWidget);
  });
}