import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';

void main() {
  test('공용라벨 필수등록 해제값을 SQL Server XML payload로 보존한다', () {
    final xml = labelRequiredChecksXml(const [
      (
        columnId: -3,
        keyword: 'SWEIGHT',
        columnName: '저울중량',
        checked: false,
      ),
      (
        columnId: -4,
        keyword: 'SPRICE',
        columnName: '최종가격',
        checked: false,
      ),
    ]);

    expect(xml, contains('<check columnId="-3">'));
    expect(xml, contains('<keyword>SWEIGHT</keyword>'));
    expect(xml, contains('<keyword>SPRICE</keyword>'));
    expect(RegExp(r'<checked>0</checked>').allMatches(xml), hasLength(2));
  });

  test('라벨 서식 저장 트랜잭션이 필수등록 상태를 함께 MERGE한다', () {
    expect(
      LabelSizeDAO.UpdateFormDataTransactionSql,
      contains('MERGE BM_RICH_CHECK_COLUMNS AS T'),
    );
    expect(
      LabelSizeDAO.UpdateFormDataTransactionSql,
      contains('T.RICH_CHECK_YN=S.RICH_CHECK_YN'),
    );
    expect(
      LabelSizeDAO.UpdateFormDataTransactionSql,
      contains('S.RICH_COLUMN_ID < 0 AND T.RICH_KEYWORD=S.RICH_KEYWORD'),
    );
  });
}