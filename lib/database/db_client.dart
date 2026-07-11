import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:label_manager/utils/debug_logger.dart';
import 'package:label_manager/utils/log_context.dart';

import 'db_isolate.dart';
import 'drivers/db_driver.dart';

@visibleForTesting
Future<DbIsolateResponse> waitForDbIsolateResponse({
  required DbIsolateAction action,
  required Future<dynamic> response,
  required Future<Object> termination,
}) async {
  final result = await Future.any<Object>([
    response.then<Object>((value) => value as DbIsolateResponse),
    termination.then<Object>((reason) => _DbIsolateTerminated(reason)),
  ]);
  if (result is DbIsolateResponse) return result;
  final reason = (result as _DbIsolateTerminated).reason;
  if (action == DbIsolateAction.transaction) {
    throw DbCommitOutcomeUnknown('DB isolate terminated: $reason');
  }
  throw StateError('DB isolate terminated before responding: $reason');
}

class _DbIsolateTerminated {
  const _DbIsolateTerminated(this.reason);

  final Object reason;
}

@visibleForTesting
void completeDbIsolateTermination(
  Completer<Object>? termination,
  Object reason,
) {
  if (termination != null && !termination.isCompleted) {
    termination.complete(reason);
  }
}

@visibleForTesting
bool dbDriverConnectedAfterResponse({
  required bool current,
  required DbIsolateResponse response,
}) {
  return switch (response.errorCode) {
    'connectionLost' || 'commitOutcomeUnknownConnectionLost' => false,
    _ => current,
  };
}

@visibleForTesting
bool dbConnectResultAccepted({
  required bool result,
  required bool disconnecting,
}) {
  return result && !disconnecting;
}

@visibleForTesting
bool dbConnectIdentityMatches({
  required ({
    String ip,
    String port,
    String databaseName,
    String username,
    String password,
    int timeoutInSeconds,
  })
  left,
  required ({
    String ip,
    String port,
    String databaseName,
    String username,
    String password,
    int timeoutInSeconds,
  })
  right,
}) {
  return left == right;
}

@visibleForTesting
class DbConnectOperationQueue<T> {
  Future<bool>? _active;
  T? _activeIdentity;

  Future<bool> run(T identity, Future<bool> Function() operation) {
    final active = _active;
    if (active != null) {
      if (_activeIdentity == identity) return active;
      return active.then(
        (_) => run(identity, operation),
        onError: (_) => run(identity, operation),
      );
    }

    late final Future<bool> current;
    current = operation().whenComplete(() {
      if (identical(_active, current)) {
        _active = null;
        _activeIdentity = null;
      }
    });
    _active = current;
    _activeIdentity = identity;
    return current;
  }
}

class _DbIsolateStartupFailure {
  const _DbIsolateStartupFailure._(this.message);

  factory _DbIsolateStartupFailure.error(Object error) {
    return _DbIsolateStartupFailure._('DB isolate startup error: $error');
  }

  const factory _DbIsolateStartupFailure.exit() = _DbIsolateStartupFailureExit;
  const factory _DbIsolateStartupFailure.timeout() =
      _DbIsolateStartupFailureTimeout;

  final String message;
}

class _DbIsolateStartupFailureExit extends _DbIsolateStartupFailure {
  const _DbIsolateStartupFailureExit()
    : super._('DB isolate exited before sending bootstrap SendPort');
}

class _DbIsolateStartupFailureTimeout extends _DbIsolateStartupFailure {
  const _DbIsolateStartupFailureTimeout()
    : super._('DB isolate bootstrap SendPort timed out after 5s');
}

/// DB 작업을 처리하는 Isolate 기반 클라이언트
class DbClient {
  DbClient._();
  static final DbClient instance = DbClient._();

  Isolate? _dbIsolate;
  SendPort? _dbSendPort;
  ReceivePort? _errorReceivePort;
  ReceivePort? _exitReceivePort;
  StreamSubscription<dynamic>? _errorSubscription;
  StreamSubscription<dynamic>? _exitSubscription;
  Completer<Object>? _isolateTermination;
  ReceivePort? _logReceivePort;
  StreamSubscription<dynamic>? _logSubscription;
  Future<void>? _isolateInit;
  final DbConnectOperationQueue<
    ({
      String ip,
      String port,
      String databaseName,
      String username,
      String password,
      int timeoutInSeconds,
    })
  >
  _connectOperations = DbConnectOperationQueue();
  Future<void>? _disconnectFuture;
  bool _driverConnected = false;
  bool _disconnecting = false;

  static const int _maxIsolateStartAttempts = 2;

  bool get isConnected =>
      _driverConnected && _dbIsolate != null && _dbSendPort != null;

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final formatted = runtimeLogMessage('$timestamp $message', skipFrames: 1);
    debugPrint(formatted);
    if (Platform.isWindows) {
      try {
        DebugLogger.outputDebugString(formatted);
      } catch (_) {
        // DebugView 출력 실패 시 무시
      }
    }
  }

  Future<void> _ensureIsolate() async {
    if (_dbSendPort != null) return;
    if (_isolateInit != null) {
      await _isolateInit;
      return;
    }

    final init = _startIsolateWithRetry();
    _isolateInit = init;
    try {
      await init;
    } finally {
      if (identical(_isolateInit, init)) {
        _isolateInit = null;
      }
    }
  }

  Future<void> _startIsolateWithRetry() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 1; attempt <= _maxIsolateStartAttempts; attempt++) {
      try {
        await _startIsolateOnce(attempt: attempt);
        return;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        _log(
          'Isolate bootstrap failed on attempt '
          '$attempt/$_maxIsolateStartAttempts: $e',
        );
        if (attempt < _maxIsolateStartAttempts) {
          _log('Isolate bootstrap retry start');
        }
      }
    }

    Error.throwWithStackTrace(lastError!, lastStackTrace!);
  }

  Future<void> _startIsolateOnce({required int attempt}) async {
    _log('Isolate 준비 시작 (attempt $attempt/$_maxIsolateStartAttempts)');
    final sw = Stopwatch()..start();
    final commandReceivePort = ReceivePort();
    final errorReceivePort = _errorReceivePort = ReceivePort();
    final exitReceivePort = _exitReceivePort = ReceivePort();
    final termination = Completer<Object>();
    _isolateTermination = termination;
    var bootstrapped = false;
    final startupFailure = Completer<_DbIsolateStartupFailure>();
    _errorSubscription = errorReceivePort.listen((error) {
      final failure = _DbIsolateStartupFailure.error(error);
      if (!bootstrapped && !startupFailure.isCompleted) {
        startupFailure.complete(failure);
      }
      _handleIsolateTermination(termination, failure.message);
    });
    _exitSubscription = exitReceivePort.listen((_) {
      const failure = _DbIsolateStartupFailure.exit();
      if (!bootstrapped && !startupFailure.isCompleted) {
        startupFailure.complete(failure);
      }
      _handleIsolateTermination(termination, failure.message);
    });
    _logReceivePort = ReceivePort();
    _logSubscription = _logReceivePort!.listen((message) {
      final text = message is String ? message : message.toString();
      if (Platform.isWindows) {
        try {
          DebugLogger.outputDebugString(text);
        } catch (_) {
          // ignore DebugView failure
        }
      }
      _log('[Isolate] $text');
    });

    try {
      _log('Isolate spawn 호출 직전');
      _dbIsolate = await Isolate.spawn(
        dbIsolateMain,
        DbIsolateBootstrapMessage(
          commandPort: commandReceivePort.sendPort,
          logPort: _logReceivePort!.sendPort,
        ),
        onError: errorReceivePort.sendPort,
        onExit: exitReceivePort.sendPort,
        errorsAreFatal: true,
      );
      _log('Isolate spawn 반환 완료, bootstrap SendPort 대기 시작');
      final bootstrapResult =
          await Future.any<dynamic>([
            commandReceivePort.first,
            startupFailure.future,
          ]).timeout(
            const Duration(seconds: 5),
            onTimeout: () => const _DbIsolateStartupFailure.timeout(),
          );
      if (bootstrapResult is _DbIsolateStartupFailure) {
        throw StateError(bootstrapResult.message);
      }
      bootstrapped = true;
      _dbSendPort = bootstrapResult as SendPort;
      _log('Isolate bootstrap SendPort 수신 완료');
      commandReceivePort.close();
      sw.stop();
      _log(
        'Isolate 생성 완료 (${sw.elapsedMilliseconds}ms), '
        'attempt=$attempt',
      );
    } catch (e) {
      commandReceivePort.close();
      await _disposeIsolateResources(kill: true);
      _log(
        'Isolate spawn failed (attempt '
        '$attempt/$_maxIsolateStartAttempts): $e',
      );
      rethrow;
    }
  }

  void _handleIsolateTermination(Completer<Object> termination, Object reason) {
    completeDbIsolateTermination(termination, reason);
    if (!identical(_isolateTermination, termination)) return;
    _driverConnected = false;
    _dbIsolate = null;
    _dbSendPort = null;
    _isolateTermination = null;
    _errorReceivePort?.close();
    _errorReceivePort = null;
    _exitReceivePort?.close();
    _exitReceivePort = null;
    unawaited(_errorSubscription?.cancel());
    _errorSubscription = null;
    unawaited(_exitSubscription?.cancel());
    _exitSubscription = null;
    unawaited(_logSubscription?.cancel());
    _logSubscription = null;
    _logReceivePort?.close();
    _logReceivePort = null;
    _log('DB isolate 종료 감지: $reason');
  }

  Future<void> _disposeIsolateResources({
    required bool kill,
    Object reason = 'DB isolate disposed.',
  }) async {
    completeDbIsolateTermination(_isolateTermination, reason);
    if (kill) _dbIsolate?.kill(priority: Isolate.immediate);
    _driverConnected = false;
    _dbIsolate = null;
    _dbSendPort = null;
    _isolateTermination = null;
    _errorReceivePort?.close();
    _errorReceivePort = null;
    _exitReceivePort?.close();
    _exitReceivePort = null;
    await _errorSubscription?.cancel();
    _errorSubscription = null;
    await _exitSubscription?.cancel();
    _exitSubscription = null;
    await _logSubscription?.cancel();
    _logSubscription = null;
    _logReceivePort?.close();
    _logReceivePort = null;
  }

  Future<T> _sendToIsolate<T>(
    DbIsolateAction action,
    Map<String, dynamic> payload,
  ) async {
    if (_disconnecting && action != DbIsolateAction.disconnect) {
      throw StateError('DB client is disconnecting.');
    }
    await _ensureIsolate();
    if (_disconnecting && action != DbIsolateAction.disconnect) {
      throw StateError('DB client is disconnecting.');
    }
    final responsePort = ReceivePort();
    _log('Isolate 요청: $action, payload=${_maskPayload(payload)}');
    if (action == DbIsolateAction.connect) {
      _log('Isolate 연결 문자열(mask): ${_maskConnectionString(payload)}');
    }
    final sendPort = _dbSendPort;
    final terminationSignal = _isolateTermination;
    if (sendPort == null || terminationSignal == null) {
      responsePort.close();
      throw StateError('DB isolate terminated before request dispatch.');
    }
    final termination = terminationSignal.future;
    sendPort.send(DbIsolateRequest(action, payload, responsePort.sendPort));
    final DbIsolateResponse res;
    try {
      res = await waitForDbIsolateResponse(
        action: action,
        response: responsePort.first,
        termination: termination,
      );
    } finally {
      responsePort.close();
    }
    _log('Isolate 응답: $action, success=${res.success}');
    if (res.success) {
      return res.result as T;
    }
    _driverConnected = dbDriverConnectedAfterResponse(
      current: _driverConnected,
      response: res,
    );
    if (res.errorCode == 'commitOutcomeUnknown' ||
        res.errorCode == 'commitOutcomeUnknownConnectionLost') {
      throw DbCommitOutcomeUnknown(
        res.error ?? 'Commit outcome is unknown.',
        connectionLost: res.errorCode == 'commitOutcomeUnknownConnectionLost',
      );
    }
    if (res.errorCode == 'connectionLost') {
      throw DbConnectionLost(res.error ?? 'Database connection was lost.');
    }
    throw Exception(res.error ?? 'DB Isolate error');
  }

  Future<bool> connect({
    required String ip,
    required String port,
    required String databaseName,
    required String username,
    required String password,
    int timeoutInSeconds = 15,
  }) {
    final identity = (
      ip: ip,
      port: port,
      databaseName: databaseName,
      username: username,
      password: password,
      timeoutInSeconds: timeoutInSeconds,
    );
    return _connectOperations.run(
      identity,
      () => _performConnect(
        ip: ip,
        port: port,
        databaseName: databaseName,
        username: username,
        password: password,
        timeoutInSeconds: timeoutInSeconds,
      ),
    );
  }

  Future<bool> _performConnect({
    required String ip,
    required String port,
    required String databaseName,
    required String username,
    required String password,
    required int timeoutInSeconds,
  }) async {
    if (_disconnecting) {
      throw StateError('DB client is disconnecting.');
    }
    _driverConnected = false;
    // Isolate가 준비될 때까지 기다려서 경합 조건을 방지한다.
    await _ensureIsolate();

    _log('DB 연결 시도: $ip:$port/$databaseName ($username)');
    final sw = Stopwatch()..start();
    try {
      final ok = await _sendToIsolate<bool>(DbIsolateAction.connect, {
        'ip': ip,
        'port': port,
        'databaseName': databaseName,
        'username': username,
        'password': password,
        'timeoutInSeconds': timeoutInSeconds,
      });
      _driverConnected = dbConnectResultAccepted(
        result: ok,
        disconnecting: _disconnecting,
      );
      sw.stop();
      _log('DB 연결 결과: $_driverConnected (${sw.elapsedMilliseconds}ms)');
      return _driverConnected;
    } catch (_) {
      _driverConnected = false;
      rethrow;
    }
  }

  Future<Object> getData(String sql) async {
    _log('getData 요청 시작');
    _debugPrintSql(sql);
    final sw = Stopwatch()..start();
    final result = await _sendToIsolate<Object>(DbIsolateAction.query, {
      'sql': sql,
    });
    sw.stop();
    _log('getData 요청 완료 (${sw.elapsedMilliseconds}ms)');
    return result;
  }

  Future<Object> getDataWithParams(
    String sql,
    Map<String, dynamic> params,
  ) async {
    _log('getDataWithParams 요청 시작');
    _debugPrintSql(sql, params);
    final sw = Stopwatch()..start();
    final result = await _sendToIsolate<Object>(
      DbIsolateAction.queryWithParams,
      {'sql': sql, 'params': params},
    );
    sw.stop();
    _log('getDataWithParams 요청 완료 (${sw.elapsedMilliseconds}ms)');
    return result;
  }

  Future<Object> writeData(String sql) async {
    _log('writeData 요청 시작');
    _debugPrintSql(sql);
    final sw = Stopwatch()..start();
    final result = await _sendToIsolate<Object>(DbIsolateAction.write, {
      'sql': sql,
    });
    sw.stop();
    _log('writeData 요청 완료 (${sw.elapsedMilliseconds}ms)');
    return result;
  }

  Future<Object> writeDataWithParams(
    String sql,
    Map<String, dynamic> params,
  ) async {
    _log('writeDataWithParams 요청 시작');
    _debugPrintSql(sql, params);
    final sw = Stopwatch()..start();
    final result = await _sendToIsolate<Object>(
      DbIsolateAction.writeWithParams,
      {'sql': sql, 'params': params},
    );
    sw.stop();
    _log('writeDataWithParams 요청 완료 (${sw.elapsedMilliseconds}ms)');
    return result;
  }

  Future<List<Object>> transaction(
    List<DbTransactionStatement> statements,
  ) async {
    if (statements.isEmpty) return const [];
    _log('transaction 요청 시작: statements=${statements.length}');
    final sw = Stopwatch()..start();
    final result = await _sendToIsolate<Object>(DbIsolateAction.transaction, {
      'statements': statements
          .map((statement) => statement.toMap())
          .toList(growable: false),
    });
    sw.stop();
    _log('transaction 요청 완료 (${sw.elapsedMilliseconds}ms)');
    return List<Object>.from(result as List);
  }

  Future<void> disconnect() {
    final active = _disconnectFuture;
    if (active != null) return active;
    late final Future<void> operation;
    operation = _performDisconnect().whenComplete(() {
      if (identical(_disconnectFuture, operation)) {
        _disconnectFuture = null;
      }
    });
    _disconnectFuture = operation;
    return operation;
  }

  Future<void> _performDisconnect() async {
    _disconnecting = true;
    _log('DB 연결 종료 요청');
    final sw = Stopwatch()..start();
    try {
      try {
        await _isolateInit;
      } catch (_) {}
      if (_dbSendPort != null) {
        await _sendToIsolate(DbIsolateAction.disconnect, {});
      }
    } finally {
      await _disposeIsolateResources(
        kill: true,
        reason: 'DB client disconnected.',
      );
      _disconnecting = false;
      sw.stop();
      _log('DB 연결 종료 완료 (${sw.elapsedMilliseconds}ms)');
    }
  }

  Map<String, dynamic> _maskPayload(Map<String, dynamic> payload) {
    return payload.map((key, value) {
      if (key.toLowerCase() == 'password') {
        return MapEntry(key, '******');
      }
      return MapEntry(key, value);
    });
  }

  String _maskConnectionString(Map<String, dynamic> payload) {
    final ip = (payload['ip'] ?? '').toString().trim();
    final port = (payload['port'] ?? '').toString().trim();
    final db = (payload['databaseName'] ?? '').toString().trim();
    final user = (payload['username'] ?? '').toString().trim();
    final timeout = (payload['timeoutInSeconds'] ?? '').toString().trim();
    return 'Server=$ip,$port;Database=$db;UID=$user;PWD=******;Login Timeout=$timeout;';
  }

  void _debugPrintSql(String sql, [Map<String, dynamic>? params]) {
    try {
      final statement = params == null
          ? sql
          : _formatSqlWithParams(sql, params);
      debugLog('SQL $statement');
    } catch (e) {
      debugLog('SQL format failed: $e');
      debugLog('SQL raw: $sql');
    }
  }

  String _formatSqlWithParams(String sql, Map<String, dynamic> params) {
    if (params.isEmpty) return sql;
    var statement = sql;
    final entries =
        params.entries
            .map((e) => MapEntry(_normalizeParamName(e.key), e.value))
            .toList()
          ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      final literal = _toSqlLiteral(entry.value);
      final pattern = RegExp(
        '\\b${RegExp.escape(entry.key)}\\b',
        caseSensitive: false,
      );
      statement = statement.replaceAll(pattern, literal);
    }
    return statement;
  }

  String _normalizeParamName(String name) =>
      name.startsWith('@') ? name : '@$name';

  String _toSqlLiteral(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    if (value is DateTime) {
      final iso = value.toIso8601String();
      return "'${iso.replaceAll("'", "''")}'";
    }
    if (value is Iterable) {
      final list = value.map(_toSqlLiteral).join(', ');
      return '($list)';
    }
    final text = value.toString().replaceAll("'", "''");
    return "'$text'";
  }
}
