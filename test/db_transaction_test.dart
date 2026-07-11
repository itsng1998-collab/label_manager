import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/drivers/db_driver.dart';

void main() {
  group('[transaction/DAO]', () {
    test('transaction commits statements on one connected driver', () async {
      final driver = _FakeDbDriver();
      final results = await executeDriverTransaction(driver, [
        const DbTransactionStatement(
          sql: 'UPDATE ITEMS SET NAME=@name',
          params: {'name': '품목'},
        ),
        const DbTransactionStatement(
          sql: 'SELECT @@TRANCOUNT AS TRANCOUNT',
          returnsRows: true,
        ),
      ]);

      expect(driver.calls, [
        'write:BEGIN TRANSACTION',
        'writeParams:UPDATE ITEMS SET NAME=@name:{name: 품목}',
        'query:SELECT @@TRANCOUNT AS TRANCOUNT',
        'write:COMMIT TRANSACTION',
      ]);
      expect(results, [
        {'affected': 1},
        {'rows': <Object>[]},
      ]);
    });

    test('transaction rolls back and preserves the original failure', () async {
      final driver = _FakeDbDriver(failingSql: 'UPDATE FAIL');

      await expectLater(
        executeDriverTransaction(driver, const [
          DbTransactionStatement(sql: 'UPDATE FIRST'),
          DbTransactionStatement(sql: 'UPDATE FAIL'),
          DbTransactionStatement(sql: 'UPDATE NEVER'),
        ]),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          'failed: UPDATE FAIL',
        )),
      );

      expect(driver.calls, [
        'write:BEGIN TRANSACTION',
        'write:UPDATE FIRST',
        'write:UPDATE FAIL',
        'write:IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION',
      ]);
    });

    for (final errorResult in <Object>[
      {'error': 'map driver failure'},
      '{"rows":[],"affected":1,"error":"json driver failure"}',
    ]) {
      test('transaction rolls back driver error result $errorResult', () async {
        final driver = _FakeDbDriver(
          resultSql: 'UPDATE FAIL RESULT',
          result: errorResult,
        );

        await expectLater(
          executeDriverTransaction(driver, const [
            DbTransactionStatement(sql: 'UPDATE FIRST'),
            DbTransactionStatement(sql: 'UPDATE FAIL RESULT'),
            DbTransactionStatement(sql: 'UPDATE NEVER'),
          ]),
          throwsA(isA<StateError>()),
        );

        expect(driver.calls, [
          'write:BEGIN TRANSACTION',
          'write:UPDATE FIRST',
          'write:UPDATE FAIL RESULT',
          'write:IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION',
        ]);
      });
    }

    test('transaction accepts plain-text success results', () async {
      final driver = _FakeDbDriver(
        resultSql: 'UPDATE TEXT RESULT',
        result: 'success',
      );

      expect(
        await executeDriverTransaction(driver, const [
          DbTransactionStatement(sql: 'UPDATE TEXT RESULT'),
        ]),
        ['success'],
      );
      expect(driver.calls.last, 'write:COMMIT TRANSACTION');
    });

    test('transaction rolls back malformed JSON begin result', () async {
      final driver = _FakeDbDriver(
        resultSql: 'BEGIN TRANSACTION',
        result: '{malformed',
      );

      await expectLater(
        executeDriverTransaction(driver, const [
          DbTransactionStatement(sql: 'UPDATE NEVER'),
        ]),
        throwsFormatException,
      );
      expect(driver.calls, [
        'write:BEGIN TRANSACTION',
        'write:IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION',
      ]);
    });

    test('transaction attempts rollback when begin call throws', () async {
      final driver = _FakeDbDriver(failingSql: 'BEGIN TRANSACTION');

      await expectLater(
        executeDriverTransaction(driver, const [
          DbTransactionStatement(sql: 'UPDATE NEVER'),
        ]),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          'failed: BEGIN TRANSACTION',
        )),
      );
      expect(driver.calls, [
        'write:BEGIN TRANSACTION',
        'write:IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION',
      ]);
    });

    test('transaction preserves begin error when rollback also fails', () async {
      final driver = _FakeDbDriver(
        failingSql: 'BEGIN TRANSACTION',
        rollbackFails: true,
      );

      await expectLater(
        executeDriverTransaction(driver, const [
          DbTransactionStatement(sql: 'UPDATE NEVER'),
        ]),
        throwsA(isA<StateError>().having(
          (error) => error.message,
          'message',
          'failed: BEGIN TRANSACTION',
        )),
      );
      expect(driver.calls.last, 'write:IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION');
    });

    test('transaction statement maps are isolate safe', () {
      const statement = DbTransactionStatement(
        sql: 'UPDATE T SET VALUE=@value',
        params: {'value': 3},
        returnsRows: true,
      );

      final restored = DbTransactionStatement.fromMap(statement.toMap());
      expect(restored.sql, statement.sql);
      expect(restored.params, statement.params);
      expect(restored.returnsRows, isTrue);
    });

    test('empty transactions do not touch the driver', () async {
      final driver = _FakeDbDriver();
      expect(await executeDriverTransaction(driver, const []), isEmpty);
      expect(driver.calls, isEmpty);
    });
  });
}

class _FakeDbDriver implements DbDriver {
  _FakeDbDriver({
    this.failingSql,
    this.resultSql,
    this.result,
    this.rollbackFails = false,
  });

  final String? failingSql;
  final String? resultSql;
  final Object? result;
  final bool rollbackFails;
  final List<String> calls = [];

  @override
  bool get isConnected => true;

  void _failIfNeeded(String sql) {
    if (sql == failingSql) throw StateError('failed: $sql');
    if (rollbackFails && sql.contains('ROLLBACK TRANSACTION')) {
      throw StateError('rollback failed');
    }
  }

  Object _resultFor(String sql, Object fallback) =>
      sql == resultSql ? result! : fallback;

  @override
  Future<Object> getData(String sql) async {
    calls.add('query:$sql');
    _failIfNeeded(sql);
    return _resultFor(sql, {'rows': <Object>[]});
  }

  @override
  Future<Object> getDataWithParams(
    String sql,
    Map<String, dynamic> params,
  ) async {
    calls.add('queryParams:$sql:$params');
    _failIfNeeded(sql);
    return _resultFor(sql, {'rows': <Object>[]});
  }

  @override
  Future<Object> writeData(String sql) async {
    calls.add('write:$sql');
    _failIfNeeded(sql);
    return _resultFor(sql, {'affected': 1});
  }

  @override
  Future<Object> writeDataWithParams(
    String sql,
    Map<String, dynamic> params,
  ) async {
    calls.add('writeParams:$sql:$params');
    _failIfNeeded(sql);
    return _resultFor(sql, {'affected': 1});
  }

  @override
  Future<bool> connect({
    required String ip,
    required String port,
    required String databaseName,
    required String username,
    required String password,
    int timeoutInSeconds = 15,
  }) async => true;

  @override
  Future<bool> disconnect() async => true;
}
