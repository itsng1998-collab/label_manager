import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item_of_market.dart';

void main() {
  group('[읽기/스냅샷]', () {
    test('item display query aliases label size and orders rows', () {
      expect(ItemOfMarketDAO.SelectSql, contains('AS P1_LABEL_SIZE_WIDTH'));
      expect(ItemOfMarketDAO.SelectSql, contains('AS P1_LABEL_SIZE_HEIGHT'));
      expect(
        ItemOfMarketDAO.OrderByItemOrder,
        contains('P2.RICH_ITEM_ORDER, P2.RICH_ITEM_ID ASC'),
      );

      final item = ItemOfMarket.fromMap({
        'P1_LABEL_SIZE_WIDTH': '72',
        'P1_LABEL_SIZE_HEIGHT': '40',
      });
      expect(item.labelSizeWidth, 72);
      expect(item.labelSizeHeight, 40);
    });

    test('customer market query uses only customer condition', () {
      expect(
        MarketDAO.whereSqlCustomerId,
        contains('RICH_CUSTOMER_ID=@customerId'),
      );
      expect(MarketDAO.whereSqlCustomerId, isNot(contains('RICH_MARKET_ID')));
    });

    test('scoped column query uses one XML rowset parameter', () {
      expect(TColumnContentDAO.SelectByItemIds, contains('@itemIdsXml'));
      expect(TColumnContentDAO.SelectByItemIds, contains("nodes('/items/id')"));
      expect(
        TColumnContentDAO.SelectByItemIds,
        contains('DECLARE @ScopedItemIds TABLE'),
      );
      expect(TColumnContentDAO.SelectByItemIds, contains('PRIMARY KEY'));
      expect(
        TColumnContentDAO.SelectByItemIds,
        contains('INNER JOIN @ScopedItemIds S'),
      );
      expect(TColumnContentDAO.SelectByItemIds, contains('OPTION (RECOMPILE)'));
      expect(TColumnContentDAO.SelectByItemIds, isNot(contains(' IN (')));
      expect(
        TColumnContentDAO.itemIdsXml([3, 1, 3, 0, -1]),
        '<items><id>1</id><id>3</id></items>',
      );
    });

    test('scoped column view resolves only supplied values', () {
      final content = TColumnContent(
        colContentId: 1,
        columnId: 10,
        itemId: 20,
        editable: true,
        dataString: '값',
      );
      final view = TColumnContentScopedView({
        const ColumnItemKey(columnId: 10, itemId: 20): content,
      });

      expect(view.value(10, 20), '값');
      expect(view.value(10, 21), '');
      expect(
        () => view.values[const ColumnItemKey(columnId: 11, itemId: 20)] =
            content,
        throwsUnsupportedError,
      );
    });

  });
}
