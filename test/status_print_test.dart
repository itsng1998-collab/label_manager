import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/status_print.dart';

void main() {
  const base = StatusPrintQuerySpec(
    startDate: '20250101',
    endDate: '20250131',
    customerId: 10,
    searchColumn: statusPrintElementColumn,
    exactMatch: false,
  );

  test('status print row keeps status id and deletion state', () {
    final row = StatusPrintRow.fromMap({
      'STATUS_ID': '10-20-30',
      'PRINT_COUNT': '4',
      'ITEM_CHANGE_DELETE_DATE': '2025-01-03',
    });
    expect(row.statusId, '10-20-30');
    expect(row.printCount, 4);
    expect(row.deleted, isTrue);
  });

  test('element query avoids detail join and keeps legacy ordering', () {
    final sql = StatusPrintDAO.buildSelectQuery(base);
    expect(sql, contains('FROM BM_RICH_STATUS S'));
    expect(sql, isNot(contains('JOIN BM_RICH_STATUS_DATA')));
    expect(sql, contains('S.RICH_PRINT_ITEM_ELEMENT LIKE @searchText'));
    expect(sql, contains('S.RICH_DATE_YYYYMMDD BETWEEN @startDate AND @endDate'));
    expect(sql, endsWith('ORDER BY S.RICH_PRINT_DATE'));
    expect(sql, isNot(contains('SUM(')));
    expect(base.parameters['searchText'], '%%');
  });

  test('column query joins detail and applies optional filters', () {
    const spec = StatusPrintQuerySpec(
      startDate: '20250101',
      endDate: '20250131',
      customerId: 10,
      brandId: 20,
      labelSizeId: 30,
      itemName: '상품',
      searchColumn: '원산지',
      searchText: '국내산',
      exactMatch: true,
    );
    final sql = StatusPrintDAO.buildSelectQuery(spec);
    expect(sql, contains('INNER JOIN BM_RICH_STATUS_DATA D'));
    expect(sql, contains('D.RICH_COLUMN_NAME=@searchColumn'));
    expect(sql, contains('D.RICH_PRINT_COLUMN_DATA=@searchText'));
    expect(sql, contains('S.RICH_BRAND_ID=@brandId'));
    expect(sql, contains('S.RICH_LABELSIZE_ID=@labelSizeId'));
    expect(sql, contains('S.RICH_PRINT_ITEM_NAME LIKE @itemName'));
    expect(spec.parameters['itemName'], '%상품%');
    expect(sql, isNot(contains('RICH_DATETIME')));
  });

  test('detail queries keep legacy fields and no added ordering', () {
    expect(StatusPrintDAO.selectDetailItemSql, contains('RICH_PRINT_ITEM_NAME'));
    expect(
      StatusPrintDAO.selectDetailRowsSql,
      contains('RICH_COLID_CHANGE_DELETE_DATE'),
    );
    expect(StatusPrintDAO.selectDetailRowsSql, isNot(contains('ORDER BY')));
  });
}