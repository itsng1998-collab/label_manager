import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/common_label_history.dart';

void main() {
  test('common label history keeps log id and prefers nonempty sheet', () {
    final history = CommonLabelHistory.fromMap({
      'LOG_ID': '7',
      'BEFORE_WIDTH': '60',
      'BEFORE_HEIGHT': '40',
      'BEFORE_FORM_DATA': r'{\rtf1 before}',
      'BEFORE_FORM_SHEET': '{"version":1}',
      'AFTER_FORM_DATA': r'{\rtf1 after}',
      'AFTER_FORM_SHEET': '',
    });

    expect(history.logId, 7);
    expect(history.beforeWidth, 60);
    expect(history.beforeHeight, 40);
    expect(history.beforePayload.usesSheet, isTrue);
    expect(history.beforePayload.value, '{"version":1}');
    expect(history.afterPayload.usesSheet, isFalse);
    expect(history.afterPayload.value, r'{\rtf1 after}');
  });

  test('common label history query keeps legacy join scope and no ordering', () {
    final sql = CommonLabelHistoryDAO.selectBetweenDatesAndCustomerSql;
    expect(sql, contains('FROM BM_RICH_LABELSIZE_FORM_LOG A'));
    expect(
      sql,
      contains('INNER JOIN BM_RICH_BRAND B ON A.RICH_BRAND_ID=B.RICH_BRAND_ID'),
    );
    expect(sql, contains('A.RICH_MOD_DATE BETWEEN @startDate AND @endDate'));
    expect(sql, contains('A.RICH_CUSTOMER_ID=@customerId'));
    expect(sql, contains('A.RICH_MOD_LOG_ID'));
    expect(sql, contains('A.RICH_FORM_SHEET'));
    expect(sql, contains('A.RICH_ALTER_FORM_SHEET'));
    expect(sql, isNot(contains('ORDER BY')));
  });
}