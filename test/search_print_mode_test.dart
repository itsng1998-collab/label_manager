import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/search_print.dart';
import 'package:label_manager/page_home/search_print_command.dart';

void main() {
  test('legacy search print SQL keeps exact match and grouped first-row order', () {
    expect(SearchPrintDAO.SelectSql, contains('B.RICH_ITEM_NAME=@query'));
    expect(
      SearchPrintDAO.SelectSql,
      contains('A.RICH_COL_CONTENT_DATA=@query AND F.RICH_SEARCH_PRINT=1'),
    );
    expect(SearchPrintDAO.SelectSql, contains('BM_RICH_COL_CONTENT A'));
    expect(
      SearchPrintDAO.SelectSql,
      contains(
        'GROUP BY C.RICH_BRAND_ID, B.RICH_LABELSIZE_ID, A.RICH_ITEM_ID',
      ),
    );
    expect(SearchPrintDAO.SelectSql.toUpperCase(), isNot(contains('ORDER BY')));
  });

  test('search result maps legacy print identity', () {
    final result = SearchPrintResult.fromMap({
      'BRAND_ID': '2',
      'LABELSIZE_ID': 3,
      'ITEM_ID': '4',
    });
    expect(result.brandId, 2);
    expect(result.labelSizeId, 3);
    expect(result.itemId, 4);
  });

  test('mode blocks only a different main tab', () {
    expect(
      searchPrintModeBlocksTabSelection(
        active: true,
        currentTab: 'items',
        requestedTab: 'label_print',
      ),
      isTrue,
    );
    expect(
      searchPrintModeBlocksTabSelection(
        active: true,
        currentTab: 'items',
        requestedTab: 'items',
      ),
      isFalse,
    );
    expect(
      searchPrintModeBlocksTabSelection(
        active: false,
        currentTab: 'items',
        requestedTab: 'label_print',
      ),
      isFalse,
    );
  });

  test('matched item uses current market baseline without fallback', () {
    final item = _itemOfMarket(itemId: 10);
    expect(searchPrintFindBaselineItem([item], 10), same(item));
    expect(searchPrintFindBaselineItem([item], 11), isNull);
  });

  test('button label follows mode', () {
    expect(searchPrintButtonLabel(false), '검색');
    expect(searchPrintButtonLabel(true), '발행');
  });

  test('mode shows print input even where normal search is hidden', () {
    expect(
      searchPrintInputVisible(active: true, standardVisible: false),
      isTrue,
    );
    expect(
      searchPrintInputVisible(active: false, standardVisible: false),
      isFalse,
    );
  });

  test('only unmodified F12 toggles search print mode', () {
    expect(
      searchPrintModeShortcutPressed(
        key: LogicalKeyboardKey.f12,
        modifierPressed: false,
      ),
      isTrue,
    );
    expect(
      searchPrintModeShortcutPressed(
        key: LogicalKeyboardKey.f12,
        modifierPressed: true,
      ),
      isFalse,
    );
    expect(
      searchPrintModeShortcutPressed(
        key: LogicalKeyboardKey.f3,
        modifierPressed: false,
      ),
      isFalse,
    );
  });

  test('search print command trims query and clears input on success', () async {
    final controller = TextEditingController(text: '  품목  ');
    addTearDown(controller.dispose);
    String? issuedQuery;
    await runSearchPrintInputCommand(
      controller: controller,
      issue: (query) async => issuedQuery = query,
    );
    expect(issuedQuery, '품목');
    expect(controller.text, isEmpty);
  });

  test('search print command clears empty input and query errors', () async {
    final controller = TextEditingController(text: '   ');
    addTearDown(controller.dispose);
    await expectLater(
      runSearchPrintInputCommand(
        controller: controller,
        issue: (_) async => throw StateError('조회 실패'),
      ),
      throwsStateError,
    );
    expect(controller.text, isEmpty);
  });
}

ItemOfMarket _itemOfMarket({required int itemId}) => ItemOfMarket(
  marketId: 1,
  item: Item(
    itemId: itemId,
    labelSizeId: 2,
    itemName: '품목',
    labelSizeName: '라벨',
    element: '',
    elementRTF: '',
    price: 0,
    order: 0,
  ),
  additionalItem: const AdditionalItem(
    AdditionalItemId: 0,
    itemId: 0,
    element: '',
    elementRTF: '',
    price: 0,
  ),
  gdsNo: 0,
  dateSaleStart: DateTime(2024),
  dateSaleEnd: DateTime(2024),
  discountPercent: 0,
  discountAmount: 0,
  dateStartDiscount: DateTime(2024),
  dateEndDiscount: DateTime(2024),
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