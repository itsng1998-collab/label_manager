import 'dart:convert';

class DbTransactionStatement {
  final String sql;
  final Map<String, dynamic> params;
  final bool returnsRows;

  const DbTransactionStatement({
    required this.sql,
    this.params = const {},
    this.returnsRows = false,
  });

  factory DbTransactionStatement.fromMap(Map<String, dynamic> map) {
    return DbTransactionStatement(
      sql: map['sql'] as String,
      params: Map<String, dynamic>.from(
        map['params'] as Map<dynamic, dynamic>? ?? const {},
      ),
      returnsRows: map['returnsRows'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {'sql': sql, 'params': params, 'returnsRows': returnsRows};
  }
}

class DbCommitOutcomeUnknown implements Exception {
  const DbCommitOutcomeUnknown(this.message);

  final String message;

  @override
  String toString() => 'DbCommitOutcomeUnknown: $message';
}

void _throwIfDriverError(Object result) {
  final Object? decoded = switch (result) {
    final String value when value.trimLeft().startsWith('{') =>
      jsonDecode(value),
    _ => result,
  };
  if (decoded is! Map) return;
  final error = decoded['error']?.toString().trim();
  if (error != null && error.isNotEmpty) {
    throw StateError(error);
  }
}

abstract class DbDriver {
  bool get isConnected;

  Future<bool> connect({
    required String ip,
    required String port,
    required String databaseName,
    required String username,
    required String password,
    int timeoutInSeconds = 15,
  });

  Future<Object> getData(String sql);

  Future<Object> writeData(String sql);

  Future<Object> getDataWithParams(String sql, Map<String, dynamic> params);

  Future<Object> writeDataWithParams(String sql, Map<String, dynamic> params);

  Future<bool> disconnect();
}

Future<List<Object>> executeDriverTransaction(
  DbDriver driver,
  List<DbTransactionStatement> statements,
) async {
  if (!driver.isConnected) {
    throw StateError('Database is not connected.');
  }
  if (statements.isEmpty) return const [];

  var beginAttempted = false;
  var commitAttempted = false;
  try {
    beginAttempted = true;
    final beginResult = await driver.writeData('BEGIN TRANSACTION');
    _throwIfDriverError(beginResult);
    final results = <Object>[];
    for (final statement in statements) {
      final hasParams = statement.params.isNotEmpty;
      final result = statement.returnsRows
          ? hasParams
                ? await driver.getDataWithParams(
                    statement.sql,
                    statement.params,
                  )
                : await driver.getData(statement.sql)
          : hasParams
          ? await driver.writeDataWithParams(statement.sql, statement.params)
          : await driver.writeData(statement.sql);
      _throwIfDriverError(result);
      results.add(result);
    }
    commitAttempted = true;
    final commitResult = await driver.writeData('COMMIT TRANSACTION');
    _throwIfDriverError(commitResult);
    return results;
  } catch (error, stackTrace) {
    if (beginAttempted) {
      try {
        await driver.writeData(
          'IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION',
        );
      } catch (_) {}
    }
    if (commitAttempted) {
      Error.throwWithStackTrace(
        DbCommitOutcomeUnknown(error.toString()),
        stackTrace,
      );
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
}
