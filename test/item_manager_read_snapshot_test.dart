import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/market.dart';

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

    test('raw market snapshot preserves null and empty values', () {
      final snapshot = ItemOfMarketRawSnapshot.fromMap({
        'MARKET_ID': 3,
        'ITEM_ID': 7,
        'ADDITIONAL_ITEM_ID': null,
        'SALE_START_DATE': null,
        'DISCOUNT_START_DATE': null,
        'USER_DEFINE_ELEMENT_RTF': '',
        'LABEL_SIZE_WIDTH': null,
      });

      expect(snapshot.marketId, 3);
      expect(snapshot.itemId, 7);
      expect(snapshot.additionalItemId, isNull);
      expect(snapshot.dateSaleStart, isNull);
      expect(snapshot.dateStartDiscount, isNull);
      expect(snapshot.rtfText, '');
      expect(snapshot.labelSizeWidth, isNull);
      expect(ItemOfMarketDAO.SelectRawSnapshotSql, isNot(contains('COALESCE')));
    });

    test('customer market query uses only customer condition', () {
      expect(
        MarketDAO.WhereSqlCustomerId,
        contains('RICH_CUSTOMER_ID=@customerId'),
      );
      expect(MarketDAO.WhereSqlCustomerId, isNot(contains('RICH_MARKET_ID')));
    });

    test('scoped column query uses one XML rowset parameter', () {
      expect(TColumnContentDAO.SelectByItemIds, contains('@itemIdsXml'));
      expect(TColumnContentDAO.SelectByItemIds, contains("nodes('/items/id')"));
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

    test('mapping fingerprints use an XML rowset and sorted market ids', () {
      expect(
        ItemOfMarketDAO.SelectMappingFingerprintsSql,
        contains('@itemIdsXml'),
      );
      expect(
        ItemOfMarketDAO.SelectMappingFingerprintsSql,
        contains("nodes('/items/id')"),
      );
      expect(
        ItemOfMarketDAO.SelectMappingFingerprintsSql,
        isNot(contains(' IN (')),
      );

      final baseline = ItemMarketMappingFingerprints.fromRows(const [
        {'ITEM_ID': 10, 'MARKET_ID': 3},
        {'ITEM_ID': 10, 'MARKET_ID': 1},
        {'ITEM_ID': 20, 'MARKET_ID': 5},
      ]);
      final same = ItemMarketMappingFingerprints.fromRows(const [
        {'ITEM_ID': 10, 'MARKET_ID': 1},
        {'ITEM_ID': 10, 'MARKET_ID': 3},
      ]);
      final changed = ItemMarketMappingFingerprints.fromRows(const [
        {'ITEM_ID': 10, 'MARKET_ID': 1},
        {'ITEM_ID': 10, 'MARKET_ID': 7},
      ]);

      expect(baseline.marketIdsFor(10), [1, 3]);
      expect(baseline.matchesForItems(same, [10]), isTrue);
      expect(baseline.matchesForItems(changed, [10]), isFalse);
    });
  });
}
