import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_sql_log_policy.dart';

void main() {
  test('connection probe SQL만 로그 생략 대상으로 식별한다', () {
    expect(isDbConnectionProbeSql('SELECT 1'), isTrue);
    expect(isDbConnectionProbeSql(' select  1; '), isTrue);
    expect(isDbConnectionProbeSql('SELECT 10'), isFalse);
    expect(isDbConnectionProbeSql('SELECT 1 FROM BM_RICH_USER'), isFalse);
  });
}