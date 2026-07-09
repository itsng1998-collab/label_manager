import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/page_home/item_manage.dart';

void main() {
  testWidgets('FortuneTable selects rows and toggles checkbox cells', (
    tester,
  ) async {
    final rows = ['첫째', '둘째', '셋째'];
    final checked = <String>{};
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FortuneTable<String>(
                  rows: rows,
                  autoFitColumns: false,
                  onRowSelected: (row, index) => selectedIndex = index,
                  columns: [
                    FortuneTableColumn<String>(
                      id: 'name',
                      header: '이름',
                      initialWidth: 100,
                      text: (row) => row,
                    ),
                    FortuneTableColumn<String>(
                      id: 'check',
                      header: '체크',
                      initialWidth: 60,
                      text: (_) => '',
                      checkboxValue: checked.contains,
                      onCheckboxChanged: (row, value) {
                        setState(() {
                          if (value) {
                            checked.add(row);
                          } else {
                            checked.remove(row);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('둘째'));
    await tester.pump();

    expect(selectedIndex, 1);

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 100 + 30, 36 + 14));
    await tester.pump();

    expect(checked, {'첫째'});

    await tester.tapAt(tableTopLeft + const Offset(40 + 100 + 30, 36 + 28 + 14));
    await tester.pump();

    expect(checked, {'첫째', '둘째'});

    await tester.tapAt(tableTopLeft + const Offset(40 + 100 + 30, 36 + 14));
    await tester.pump();

    expect(checked, {'둘째'});
  });

  testWidgets('FortuneTable row-index checkbox callbacks toggle only one row', (
    tester,
  ) async {
    const rows = ['같은 값', '같은 값'];
    final checkedRows = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 120,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FortuneTable<String>(
                  rows: rows,
                  autoFitColumns: false,
                  columns: [
                    FortuneTableColumn<String>(
                      id: 'check',
                      header: '체크',
                      initialWidth: 60,
                      text: (_) => '',
                      checkboxValueAt: (row, rowIndex) =>
                          checkedRows.contains(rowIndex),
                      onCheckboxChangedAt: (row, rowIndex, value) {
                        setState(() {
                          if (value) {
                            checkedRows.add(rowIndex);
                          } else {
                            checkedRows.remove(rowIndex);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 14));
    await tester.pump();

    expect(checkedRows, {0});

    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 28 + 14));
    await tester.pump();

    expect(checkedRows, {0, 1});

    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 14));
    await tester.pump();

    expect(checkedRows, {1});
  });

  testWidgets('ItemManage renders the FortuneTable management table', (
    tester,
  ) async {
    ItemOfMarket? selected;
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: [_testItemOfMarket(itemName: '테스트 품목')],
              onRowSelected: (row, index) {
                selected = row;
                selectedIndex = index;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FortuneTable<ItemOfMarket>), findsOneWidget);
    expect(find.text('테스트 품목'), findsOneWidget);

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.autoFitColumns, isFalse);
    expect(table.columns.map((column) => column.initialWidth), [
      40,
      100,
      280,
      180,
    ]);

    await tester.tap(find.text('테스트 품목'));
    await tester.pump();

    expect(selected?.item.itemName, '테스트 품목');
    expect(selectedIndex, 0);
  });

  testWidgets('ItemManage publish checkbox is scoped to clicked row', (
    tester,
  ) async {
    final items = [
      _testItemOfMarket(itemName: '첫째 품목', marketId: 1),
      _testItemOfMarket(itemName: '둘째 품목', marketId: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(items: items),
          ),
        ),
      ),
    );

    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns.first.checkboxValueAt!(items[0], 0), isFalse);
    expect(table.columns.first.checkboxValueAt!(items[1], 1), isFalse);

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<ItemOfMarket>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 20, 36 + 14));
    await tester.pump();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns.first.checkboxValueAt!(items[0], 0), isTrue);
    expect(table.columns.first.checkboxValueAt!(items[1], 1), isFalse);
  });

  testWidgets('FortuneTable consumes mouse wheel inside a parent scroll view', (
    tester,
  ) async {
    final parentController = ScrollController();
    addTearDown(parentController.dispose);
    final rows = List<String>.generate(40, (index) => '행 $index');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: SingleChildScrollView(
              controller: parentController,
              child: Column(
                children: [
                  SizedBox(
                    width: 360,
                    height: 180,
                    child: FortuneTable<String>(
                      rows: rows,
                      autoFitColumns: false,
                      columns: [
                        FortuneTableColumn<String>(
                          id: 'name',
                          header: '이름',
                          initialWidth: 240,
                          text: (row) => row,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    final bodyVerticalController = _bodyVerticalController(tester);
    final headerCenter = tableTopLeft + const Offset(120, 18);
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: headerCenter,
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();

    expect(parentController.offset, 0);
    expect(bodyVerticalController.offset, greaterThan(0));

    final firstRowCenter = tableTopLeft + const Offset(120, 36 + 14);
    for (var index = 0; index < 20; index += 1) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: firstRowCenter,
          scrollDelta: const Offset(0, 100),
        ),
      );
      await tester.pump();
    }

    expect(parentController.offset, 0);
    expect(bodyVerticalController.offset, greaterThan(0));
  });

  testWidgets('FortuneTable consumes trackpad pan inside a parent scroll view', (
    tester,
  ) async {
    final parentController = ScrollController();
    addTearDown(parentController.dispose);
    final rows = List<String>.generate(40, (index) => '행 $index');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: SingleChildScrollView(
              controller: parentController,
              child: Column(
                children: [
                  SizedBox(
                    width: 360,
                    height: 180,
                    child: FortuneTable<String>(
                      rows: rows,
                      autoFitColumns: false,
                      columns: [
                        FortuneTableColumn<String>(
                          id: 'name',
                          header: '이름',
                          initialWidth: 240,
                          text: (row) => row,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    final bodyVerticalController = _bodyVerticalController(tester);
    final firstRowCenter = tableTopLeft + const Offset(120, 36 + 14);
    tester.binding.handlePointerEvent(
      PointerPanZoomStartEvent(position: firstRowCenter),
    );
    await tester.pump();
    for (var index = 0; index < 20; index += 1) {
      tester.binding.handlePointerEvent(
        PointerPanZoomUpdateEvent(
          position: firstRowCenter,
          panDelta: const Offset(0, 100),
        ),
      );
      await tester.pump();
    }
    tester.binding.handlePointerEvent(
      PointerPanZoomEndEvent(position: firstRowCenter),
    );
    await tester.pump();

    expect(parentController.offset, 0);
    expect(bodyVerticalController.offset, greaterThan(0));
  });

  testWidgets('FortuneTable shows scrollbars only when content overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 140,
            child: FortuneTable<String>(
              rows: List<String>.generate(20, (index) => '행 $index'),
              autoFitColumns: false,
              columns: [
                FortuneTableColumn<String>(
                  id: 'wide',
                  header: '넓은 컬럼',
                  initialWidth: 320,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    var scrollbars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar));
    expect(scrollbars.map((scrollbar) => scrollbar.thumbVisibility), [
      true,
      true,
    ]);
    expect(
      scrollbars.map(
        (scrollbar) => scrollbar.notificationPredicate(
          ScrollStartNotification(
            metrics: FixedScrollMetrics(
              minScrollExtent: 0,
              maxScrollExtent: 100,
              pixels: 0,
              viewportDimension: 50,
              axisDirection: AxisDirection.down,
              devicePixelRatio: 1,
            ),
            context: tester.element(find.byType(FortuneTable<String>)),
          ),
        ),
      ),
      [true, false],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FortuneTable<String>(
              rows: const ['행 1'],
              autoFitColumns: false,
              columns: [
                FortuneTableColumn<String>(
                  id: 'narrow',
                  header: '좁은 컬럼',
                  initialWidth: 120,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    scrollbars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar));
    expect(scrollbars.map((scrollbar) => scrollbar.thumbVisibility), [
      false,
      false,
    ]);
  });
}

ScrollController _bodyVerticalController(WidgetTester tester) {
  final listViews = tester.widgetList<ListView>(find.byType(ListView));
  return listViews.last.controller!;
}

ItemOfMarket _testItemOfMarket({
  String itemName = '테스트 품목',
  int marketId = 1,
}) {
  final now = DateTime(2026, 7, 8);
  return ItemOfMarket(
    marketId: marketId,
    item: Item(
      itemId: 10,
      labelSizeId: 20,
      itemName: itemName,
      labelSizeName: '테스트 라벨',
      element: '원재료',
      elementRTF: '',
      price: 0,
      order: 0,
    ),
    additionalItem: const AdditionalItem(
      AdditionalItemId: 0,
      itemId: 10,
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
