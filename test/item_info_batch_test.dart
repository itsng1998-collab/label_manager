import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/models/item_of_market.dart';

void main() {
  ItemOfMarket item() => ItemOfMarket(
    marketId: 7,
    item: const Item(
      itemId: 11,
      labelSizeId: 3,
      itemName: '품목',
      labelSizeName: '라벨',
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
    useLinefeed: true,
    linefeed: 105,
    useScaleBarcode: true,
    printCount: 2,
    useLabelSize: true,
    labelSizeWidth: 300,
    labelSizeHeight: 200,
    useMargin: true,
    leftMargin: 1.1,
    rightMargin: 1.2,
    topMargin: 1.3,
    leftPush: 1.4,
    topPush: 1.5,
  );

  test('item info batch updates only active legacy fields by row identity', () {
    final edited = item().copyWith(linefeed: 110, printCount: 0);
    final statements = ItemOfMarketDAO.itemInfoUpdateStatements([edited]);
    expect(statements, hasLength(1));
    expect(statements.single.params['marketId'], 7);
    expect(statements.single.params['itemId'], 11);
    expect(statements.single.params['linefeed'], 110);
    expect(statements.single.params['printCount'], 0);
    expect(ItemOfMarketDAO.UpdateItemInfoSql, contains('IF @@ROWCOUNT<>1'));
    expect(ItemOfMarketDAO.UpdateItemInfoSql, isNot(contains('RICH_GDS_NO')));
    expect(ItemOfMarketDAO.UpdateItemInfoSql, isNot(contains('RICH_DISCOUNT')));
    expect(ItemOfMarketDAO.UpdateItemInfoSql, isNot(contains('RICH_SALE')));
  });
}