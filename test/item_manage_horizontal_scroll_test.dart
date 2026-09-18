import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/item/presentation/item_manage.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';

void main() {
  testWidgets('Enter 편집 후 품목관리 가로 스크롤을 유지한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final originalColumns = TColumn.datas;
    addTearDown(() => TColumn.datas = originalColumns);
    TColumn.datas = List.generate(
      14,
      (index) => _column(
        id: 100 + index,
        name: index == 0 ? '소비기한' : '항목 ${index + 1}',
      ),
    );
    final item = _item();
    final controller = ItemManagerDraftController.fromItems(
      items: [item],
      scopedColumnContents: TColumnContentScopedView({
        const ColumnItemKey(columnId: 100, itemId: 10): TColumnContent(
          colContentId: 1,
          columnId: 100,
          itemId: 10,
          editable: true,
          dataString: '365',
        ),
      }),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            height: 300,
            child: ItemManage(
              items: [item],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '대부기능테스트',
              ),
              marketId: 1,
              onCancelDraft: () async {},
              onSaveDraft: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    RawScrollbar horizontalScrollbar() => tester
        .widgetList<RawScrollbar>(find.byType(RawScrollbar))
        .singleWhere(
          (scrollbar) =>
              scrollbar.notificationPredicate(
                ScrollStartNotification(
                  metrics: FixedScrollMetrics(
                    minScrollExtent: 0,
                    maxScrollExtent: 100,
                    pixels: 0,
                    viewportDimension: 100,
                    axisDirection: AxisDirection.right,
                    devicePixelRatio: 1,
                  ),
                  context: tester.element(find.byType(ItemManage)),
                ),
              ),
        );

    expect(horizontalScrollbar().thumbVisibility, isTrue);
    expect(horizontalScrollbar().trackVisibility, isTrue);
    await tester.tap(find.text('365'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('365'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '360');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.columnValue(controller.rows.single, 100), '360');
    expect(horizontalScrollbar().thumbVisibility, isTrue);
    expect(controller.contentRevision, greaterThan(0));
    final tableFinder = find.byWidgetPredicate(
      (widget) => widget is FortuneTable<ItemOfMarket>,
    );
    final scrollController = tester
        .widget<FortuneTable<ItemOfMarket>>(tableFinder)
        .scrollController!;
    expect(
      tester
          .widget<FortuneTable<ItemOfMarket>>(tableFinder)
          .tabSeparatedPasteEnabled,
      isTrue,
    );
    expect(scrollController.hasHorizontalOverflow, isTrue);
    expect(
      scrollController.horizontalContentWidth,
      greaterThan(scrollController.horizontalViewportWidth),
    );
    expect(scrollController.horizontalMaxScrollExtent, greaterThan(0));
    expect(horizontalScrollbar().trackVisibility, isTrue);
    await tester.pump(const Duration(seconds: 5));
    expect(horizontalScrollbar().thumbVisibility, isTrue);
    expect(horizontalScrollbar().trackVisibility, isTrue);

    expect(scrollController.horizontalOffset, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(scrollController.horizontalOffset, greaterThan(0));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(scrollController.horizontalOffset, 0);
    await tester.pump(const Duration(milliseconds: 50));
  });
}

ItemOfMarket _item() {
  final now = DateTime(2026, 9, 11);
  return ItemOfMarket(
    marketId: 1,
    item: Item(
      itemId: 10,
      labelSizeId: 20,
      itemName: '원픽(용도:불고기용)',
      labelSizeName: '대부기능테스트',
      element: '',
      elementRTF: '',
      price: 0,
      order: 1,
    ),
    additionalItem: AdditionalItem(
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

TColumn _column({required int id, required String name}) => TColumn(
  columnId: id,
  labelSizeId: 20,
  order: id,
  width: 70,
  height: 30,
  barcodeType: BarcodeType.Code128,
  useBarcodeCheckDigit: false,
  showBarcodeNum: false,
  showQRCodeText: false,
  qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
  useUserDefineQRData: false,
  userDefineQRData: '',
  userDefineQRText: '',
  pixelSize: 0,
  title: '',
  visible: true,
  qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
  natriumJoinString: '',
  qrTextFontSize: 0,
  qrTextFontName: '',
  qrCodeScalePercent: 100,
  columnType: const TColumnType(
    code: TColumnType.TYPE_FIX,
    name: '고정',
    order: 1,
  ),
  keyword: 'COL_$id',
  columnName: name,
  useMissingKeywordCheck: false,
  useMinColumnCheck: false,
  timeBarcodeType: 0,
  autoInc: false,
  autoIncSize: 0,
  autoIncSave: false,
  autoIncRange: 0,
  autoIncZeroDel: false,
  autoIncUpdate: false,
  searchPrint: false,
  userDefineBarcodeText: '',
  lineCheck: 0,
  lineSize: 0,
  gs1ai: '',
  formatOption: 0,
  useGS1Code: false,
  containColumns: '',
  showGS1Code: false,
  rotate: 0,
  useDateRange: false,
  dateRange: '',
);