import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/content_save_history/data/content_save_log_dao.dart';
import 'package:label_manager/features/content_save_history/domain/content_save_log.dart';

void main() {
  test('content save log codec keeps string grade and pairs shorter wire', () {
    final log = ContentSaveLog.fromMap({
      'LOG_ID': '7',
      'USER_ID': 'user01',
      'USER_GRADE': '일반 사용자',
      'CUSTOMER_ID': '10',
      'ITEM_NAME': '상품 1',
      'CONTENT_COLUMNS': '품명\n가격\n원산지\n',
      'CONTENTS': '상품 1\n1000\n',
      'SAVE_STATUS': '0',
    });

    expect(log.userGrade, '일반 사용자');
    expect(log.saveStatus, ContentSaveStatus.newItem);
    expect(log.saveStatus.label, '신규');
    expect(log.details, hasLength(2));
    expect(log.details[0].columnName, '품명');
    expect(log.details[0].content, '상품 1');
    expect(log.details[1].columnName, '가격');
    expect(log.details[1].content, '1000');
  });

  test('content save log maps every nonzero status to modified', () {
    expect(ContentSaveLog.fromMap({'SAVE_STATUS': '4'}).saveStatus.label, '수정');
  });

  test('content save log query keeps legacy date customer and ordering', () {
    final sql = ContentSaveLogDAO.selectBetweenDatesAndCustomerSql;
    expect(sql, contains('FROM BM_CONTENT_SAVE_LOG'));
    expect(
      sql,
      contains(
        'SAVE_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)\n'
        '      AND CONVERT(VARCHAR(8), @endDate)',
      ),
    );
    expect(sql, contains('CUST_ID=@customerId'));
    expect(sql, isNot(contains('CONVERT(VARCHAR(8), SAVE_DATE_YYYYMMDD)')));
    expect(sql, isNot(contains('CONVERT(NVARCHAR(8), SAVE_DATE_YYYYMMDD)')));
    expect(sql, contains('ORDER BY SAVE_DATE ASC'));
    expect(sql, isNot(contains('ORDER BY SAVE_DATE ASC,')));
  });
}
