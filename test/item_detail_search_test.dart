import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/search_and_replace/data/item_detail_dao.dart';
import 'package:label_manager/models/item.dart';

void main() {
  test('item detail row maps database values', () {
    final detail = itemDetailFromRow(const {
      'ITEM_ID': '11',
      'LABELSIZE_ID': 22,
      'ITEM_NAME': '품목',
      'LABELSIZE_NAME': '라벨',
      'ELEMENT': '원재료',
      'ELEMENT_SHEET': '{"sheet":1}',
      'BRAND_ID': '33',
      'BRAND_NAME': '브랜드',
    });

    expect(detail.itemId, 11);
    expect(detail.labelSizeId, 22);
    expect(detail.elementSheet, '{"sheet":1}');
    expect(detail.brandId, 33);
  });

  test('item detail search stays in customer and optional filters', () {
    final sql = ItemDetailDAO.searchByItemNameSql;
    expect(sql, contains('B.RICH_CUSTOMER_ID=@customerId'));
    expect(sql, contains('@useBrand=0 OR B.RICH_BRAND_ID=@brandId'));
    expect(sql, contains('@useLabelSize=0 OR L.RICH_LABELSIZE_ID=@labelSizeId'));
    expect(sql, contains("I.RICH_ITEM_NAME LIKE N'%' + @query + N'%'"));
    expect(sql, contains('ORDER BY B.RICH_BRAND_ID ASC'));
  });

  test('element search uses current sheet with legacy RTF fallback', () {
    final sql = ItemDetailDAO.searchByElementSql;
    expect(sql, contains("NULLIF(I.RICH_ELEMENT_SHEET, '')"));
    expect(sql, contains('I.RICH_ELEMENT_RTF'));
    expect(sql, contains("I.RICH_ELEMENT LIKE N'%' + @query + N'%'"));
  });

  test('element LIKE wildcard characters follow legacy bracket escaping', () {
    expect(
      ItemDetailDAO.escapeElementLikePattern('[100%_]^'),
      '[[]100[%][_]][^]',
    );
  });

  test('changed elements build one transaction statement per item', () {
    final statements = ItemDAO.searchReplaceElementStatements(const [
      ItemElementSearchReplaceUpdate(
        itemId: 1,
        element: '원료 A',
        elementSheet: '{"sheet":1}',
      ),
      ItemElementSearchReplaceUpdate(
        itemId: 2,
        element: '원료 B',
        elementSheet: '{"sheet":2}',
      ),
    ]);
    expect(statements, hasLength(2));
    expect(statements.every((value) => value.sql == ItemDAO.UpdateSearchReplaceElementSql), isTrue);
    expect(statements.map((value) => value.params['itemId']), [1, 2]);
    expect(ItemDAO.UpdateSearchReplaceElementSql, contains('IF @@ROWCOUNT<>1'));
    expect(ItemDAO.UpdateSearchReplaceElementSql, isNot(contains('RICH_ITEM_NAME')));
    expect(ItemDAO.UpdateSearchReplaceElementSql, isNot(contains('RICH_PRICE')));
  });
}