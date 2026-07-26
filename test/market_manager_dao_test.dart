import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/market.dart';

void main() {
  test(
    'market insert captures identity and creates current customer mappings',
    () {
      final sql = MarketDAO.InsertWithItemMappingsSql;

      expect(sql, contains('OUTPUT INSERTED.RICH_MARKET_ID'));
      expect(sql, isNot(contains('SCOPE_IDENTITY')));
      expect(sql, isNot(contains('ORDER BY RICH_MARKET_ID DESC')));
      expect(sql, contains('INSERT INTO BM_ITEM_OF_MARKET'));
      expect(sql, contains('B.RICH_CUSTOMER_ID=@customerId'));
      expect(sql, contains('0, \'\', 0, 100, 0, 1'));
      expect(sql, isNot(contains('RICH_ETC')));
    },
  );

  test('market update and delete keep legacy fields and delete order', () {
    expect(MarketDAO.UpdateSql, contains('RICH_CUSTOMER_ID=@customerId'));
    expect(MarketDAO.UpdateSql, contains('RICH_NAME=@marketName'));
    expect(MarketDAO.UpdateSql, isNot(contains('RICH_ETC')));
    expect(
      MarketDAO.DeleteItemMappingsSql,
      contains('DELETE FROM BM_ITEM_OF_MARKET'),
    );
    expect(MarketDAO.DeleteSql, contains('DELETE FROM BM_MARKET'));
  });

  test('market manager list keeps DAO id order without name fallback', () {
    expect(MarketDAO.OrderByMarketId, contains('RICH_MARKET_ID ASC'));
    expect(MarketDAO.OrderByMarketId, isNot(contains('RICH_NAME')));
  });
}
