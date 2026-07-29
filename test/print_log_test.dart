import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/print_history/data/print_log_dao.dart';
import 'package:label_manager/features/print_history/domain/print_log.dart';

void main() {
  test('print log codec keeps legacy row and detail wires', () {
    final log = PrintLog.fromMap({
      'LOG_ID': '7',
      'USER_ID': 'user01',
      'USER_NAME': '사용자',
      'USER_GRADE': '3',
      'CUSTOMER_ID': '10',
      'CUSTOMER_NAME': '거래처',
      'PRINT_COUNT': '4',
      'COLUMNS': '품명|가격|',
      'PRINT_CELLS': '상품|1000|',
      'SAVE_IN_DB_CELLS': '상품|900|',
      'LEFT_MARGIN': '1.5',
    });

    expect(log.logId, 7);
    expect(log.userGrade, 3);
    expect(log.printCount, 4);
    expect(log.leftMargin, 1.5);
    expect(log.columnNames, ['품명', '가격']);
    expect(log.printCells, ['상품', '1000']);
    expect(log.savedCells, ['상품', '900']);
  });

  test('print log query contract keeps legacy scope and ordering', () {
    expect(PrintLogDAO.selectSql, contains('BM_RICH_PRINT_LOG'));
    expect(
      PrintLogDAO.selectSql,
      contains(
        'RICH_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)\n'
        '      AND CONVERT(VARCHAR(8), @endDate)',
      ),
    );
    expect(
      PrintLogDAO.selectSql,
      isNot(contains('CONVERT(VARCHAR(8), RICH_DATE_YYYYMMDD)')),
    );
    expect(PrintLogDAO.selectSql, isNot(contains('COOP')));
    expect(PrintLogDAO.sumSql, isNot(contains('ORDER BY')));

    final item = PrintLogDAO.buildSelectQuery(
      startDate: '20250101',
      endDate: '20250131',
      searchType: PrintLogSearchType.itemName,
      searchText: '',
      customerId: 10,
    );
    expect(item.sql, contains("RICH_ITEM_NAME LIKE N'%' + @searchText + N'%'"));
    expect(item.sql, contains('RICH_CUSTOMER_ID=@customerId'));
    expect(item.sql, endsWith('ORDER BY RICH_DATETIME ASC'));
    expect(item.params['searchText'], isEmpty);

    final user = PrintLogDAO.buildSelectQuery(
      startDate: '20250101',
      endDate: '20250131',
      searchType: PrintLogSearchType.userId,
      searchText: '',
      customerId: 10,
    );
    expect(user.sql, contains('RICH_USER_ID=@searchText'));
    expect(user.params['searchText'], isEmpty);

    final customer = PrintLogDAO.buildSelectQuery(
      startDate: '20250101',
      endDate: '20250131',
      searchType: PrintLogSearchType.customerName,
      searchText: '거래처 1',
      customerId: 10,
    );
    expect(customer.sql, contains('RICH_CUSTOMER_NAME=@searchText'));
    expect(customer.sql, isNot(contains('RICH_CUSTOMER_ID=@customerId')));
    expect(customer.params, isNot(contains('customerId')));

    final all = PrintLogDAO.buildSelectQuery(
      startDate: '20250101',
      endDate: '20250131',
      searchType: PrintLogSearchType.itemName,
      searchText: '상품',
    );
    expect(all.sql, isNot(contains('RICH_CUSTOMER_ID=@customerId')));
    expect(all.params, isNot(contains('customerId')));
  });

  test('print log summaries do not inherit the search condition', () {
    final total = PrintLogDAO.buildSumQuery();
    expect(total.params, isEmpty);
    expect(total.sql, isNot(contains('@searchText')));

    final labelSize = PrintLogDAO.buildSumQuery(
      startDate: '20250101',
      endDate: '20250131',
      customerName: '거래처 1',
      labelSizeName: '라벨 1',
    );
    expect(
      labelSize.sql,
      contains(
        'RICH_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate) '
        'AND CONVERT(VARCHAR(8), @endDate)',
      ),
    );
    expect(labelSize.sql, contains('RICH_CUSTOMER_NAME=@customerName'));
    expect(labelSize.sql, contains('RICH_LABELSIZE_NAME=@labelSizeName'));
    expect(labelSize.sql, isNot(contains('@searchText')));
  });
}
