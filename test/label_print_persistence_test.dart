import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/printing/label_print_persistence.dart';

void main() {
  const first = ColumnItemKey(columnId: 2, itemId: 10);
  const second = ColumnItemKey(columnId: 1, itemId: 20);

  test('history excludes only case-insensitive exact SYSTEM user id', () {
    expect(labelPrintHistoryEnabledForUserId('SYSTEM'), isFalse);
    expect(labelPrintHistoryEnabledForUserId('system'), isFalse);
    expect(labelPrintHistoryEnabledForUserId(' SYSTEM '), isTrue);
    expect(labelPrintHistoryEnabledForUserId('SYSTEM_ADMIN_USER'), isTrue);
  });

  test('auto increment statement uses one JSON parameter and row count check', () {
    final statement = buildLabelAutoIncrementUpdateStatement({
      first: '002',
      second: '003',
    });
    final payload = jsonDecode(statement.params['updatesJson']! as String) as List;

    expect(statement.returnsRows, isFalse);
    expect(payload, [
      {'columnId': 1, 'itemId': 20, 'dataString': '003'},
      {'columnId': 2, 'itemId': 10, 'dataString': '002'},
    ]);
    expect(statement.sql, contains('FROM OPENJSON(@updatesJson)'));
    expect(statement.sql, contains('DECLARE @AffectedRows INT = @@ROWCOUNT'));
    expect(statement.sql, contains('IF @AffectedRows <> @ExpectedRows'));
  });

  test('persistence returns committed map only after transaction success', () async {
    final service = LabelPrintPersistenceService(
      transaction: (_) async => const <Object>[],
    );

    final result = await service.saveAutoIncrementValues({first: '002'});

    expect(result.state, LabelPrintPersistenceState.succeeded);
    expect(result.committedAutoIncrementValues, {first: '002'});
  });

  test('commit outcome unknown does not return committed values', () async {
    final service = LabelPrintPersistenceService(
      transaction: (_) async => throw const DbCommitOutcomeUnknown('commit'),
    );

    final result = await service.saveAutoIncrementValues({first: '002'});

    expect(result.state, LabelPrintPersistenceState.outcomeUnknown);
    expect(result.committedAutoIncrementValues, isEmpty);
    expect(result.error, isA<DbCommitOutcomeUnknown>());
  });

  test('history uses one batch clock and explicit detail JSON', () {
    final statement = buildLabelPrintPersistenceStatement(
      historyParents: [
        {
          'parentIndex': 0,
          'customerId': 1,
          'brandId': 2,
          'details': [
            {
              'detailIndex': 0,
              'columnId': 3,
              'columnName': '원산지',
              'dataString': '국산',
            },
          ],
        },
      ],
    );
    final history = jsonDecode(statement.params['historyJson']! as String) as List;

    expect(history.single['details'].single['detailIndex'], 0);
    expect(RegExp(r'GETDATE\(\)').allMatches(statement.sql), hasLength(1));
    expect(statement.sql, contains("CONVERT(char(8), @historyAt, 112)"));
    expect(statement.sql, contains('DATEPART(second, @historyAt) * 10'));
    expect(statement.sql, contains("OPENJSON(H.payload, '\$.details')"));
  });

  test('history only still runs one transaction without committed values', () async {
    var statementCount = 0;
    final service = LabelPrintPersistenceService(
      transaction: (statements) async {
        statementCount = statements.length;
        return const <Object>[];
      },
    );

    final result = await service.save(
      historyParents: const [
        {'parentIndex': 0, 'customerId': 1, 'brandId': 2},
      ],
    );

    expect(statementCount, 1);
    expect(result.state, LabelPrintPersistenceState.succeeded);
    expect(result.committedAutoIncrementValues, isEmpty);
  });
}