import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/market/data/market_dao.dart';

void main() {
  test(
    'market insert captures identity and creates current customer mappings',
    () {
      final sql = MarketDAO.insertWithItemMappingsSql;

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
    expect(MarketDAO.updateSql, contains('RICH_CUSTOMER_ID=@customerId'));
    expect(MarketDAO.updateSql, contains('RICH_NAME=@marketName'));
    expect(MarketDAO.updateSql, isNot(contains('RICH_ETC')));
    expect(
      MarketDAO.deleteItemMappingsSql,
      contains('DELETE FROM BM_ITEM_OF_MARKET'),
    );
    expect(MarketDAO.deleteSql, contains('DELETE FROM BM_MARKET'));
  });

  test('market manager list keeps DAO id order without name fallback', () {
    expect(MarketDAO.orderByMarketId, contains('RICH_MARKET_ID ASC'));
    expect(MarketDAO.orderByMarketId, isNot(contains('RICH_NAME')));
  });
}
