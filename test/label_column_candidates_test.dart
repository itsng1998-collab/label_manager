import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_column/data/label_column_candidates.dart';
import 'package:label_manager/features/label_column/domain/label_column_candidates.dart';
import 'package:label_manager/models/column_type.dart';

const baseType = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
const barcodeType = TColumnType(
  code: TColumnType.TYPE_BARCODE,
  name: '바코드',
  order: 2,
);

CustomerColumnCandidate candidate(int id, String keyword) {
  return CustomerColumnCandidate(
    id: id,
    customerId: 7,
    columnType: baseType,
    keyword: keyword,
    columnName: keyword,
  );
}

void main() {
  group('CustomerColumnEditSession', () {
    test('selects a customer row explicitly', () {
      final session = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: [candidate(1, 'A')],
      );

      expect(session.selectedKey, isNull);
      expect(session.select('customer-column:1').selectedKey, 'customer-column:1');
    });

    test('builds independent insert update delete deltas', () {
      var session = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: [candidate(1, 'A'), candidate(2, 'B')],
      );
      session = session.update(
        session.working.first.copyWith(columnName: '변경'),
      );
      session = session.remove('customer-column:2');
      session = session.add(
        CustomerColumnDraft.empty(
          key: 'draft:1',
          customerId: 7,
          columnType: barcodeType,
        ).copyWith(keyword: 'new1', columnName: '신규'),
      );

      final command = session.toSaveCommand();
      expect(command.updatedColumns.single.id, 1);
      expect(command.deletedIds, {2});
      expect(command.newColumns.single.keyword, 'NEW1');
      expect(command.keywordChangedIds, isEmpty);
    });

    test('rejects invalid and newly duplicated keywords', () {
      var session = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: [candidate(1, 'A')],
      );
      session = session.add(
        CustomerColumnDraft.empty(
          key: 'draft:1',
          customerId: 7,
          columnType: baseType,
        ).copyWith(keyword: 'A', columnName: '중복'),
      );
      expect(session.toSaveCommand, throwsFormatException);

      final invalid = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: const [],
      ).add(
        CustomerColumnDraft.empty(
          key: 'draft:2',
          customerId: 7,
          columnType: baseType,
        ).copyWith(keyword: 'A-B', columnName: '잘못됨'),
      );
      expect(invalid.toSaveCommand, throwsFormatException);
    });

    test('save statement binds XML and validates ownership and row counts', () {
      final command = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: [candidate(1, 'A')],
      ).update(
        CustomerColumnDraft.fromCandidate(candidate(1, 'A')).copyWith(
          columnName: "작은따옴표's & 기호",
        ),
      ).toSaveCommand();

      final statement = CustomerColumnDAO.buildSaveStatement(command);
      expect(
        statement.sql,
        contains("@UpdatedColumnsDocument.nodes('/columns/column')"),
      );
      expect(statement.sql, contains('RICH_CUSTOMER_ID=@customerId'));
      expect(statement.sql, contains('IF @@ROWCOUNT<>'));
      expect(statement.sql, isNot(contains("작은따옴표's & 기호")));
      expect(statement.sql, isNot(contains('OPENJSON')));
      expect(statement.sql, isNot(contains('JSON_VALUE')));
      expect(statement.sql, isNot(contains('TRY_CONVERT')));
      expect(
        statement.params['updatedColumnsXml'],
        contains("<columnName>작은따옴표's &amp; 기호</columnName>"),
      );
    });

    test('fixed type query preserves legacy database order', () {
      expect(FixedColumnDAO.selectTypesSql.toUpperCase(), isNot(contains('ORDER BY')));
      expect(FixedColumnDAO.selectCandidatesSql, contains('RICH_FIX_COL_TYPE_ID=@typeId'));
    });
  });
}