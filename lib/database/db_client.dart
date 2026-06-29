import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:label_manager/utils/debug_logger.dart';
import 'package:label_manager/utils/log_context.dart';

import 'db_isolate.dart';

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
  ReceivePort? _logReceivePort;
  StreamSubscription<dynamic>? _logSubscription;
  Future<void>? _isolateInit;

  static const int _maxIsolateStartAttempts = 2;

  bool get isConnected => _dbIsolate != null && _dbSendPort != null;

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
    final errorReceivePort = ReceivePort();
    final exitReceivePort = ReceivePort();
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
      final bootstrapResult = await Future.any<dynamic>([
        commandReceivePort.first,
        errorReceivePort.first.then<dynamic>(
          (error) => _DbIsolateStartupFailure.error(error),
        ),
        exitReceivePort.first.then<dynamic>(
          (_) => const _DbIsolateStartupFailure.exit(),
        ),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => const _DbIsolateStartupFailure.timeout(),
      );
      if (bootstrapResult is _DbIsolateStartupFailure) {
        throw StateError(bootstrapResult.message);
      }
      _dbSendPort = bootstrapResult as SendPort;
      _log('Isolate bootstrap SendPort 수신 완료');
      commandReceivePort.close();
      errorReceivePort.close();
      exitReceivePort.close();
      sw.stop();
      _log(
        'Isolate 생성 완료 (${sw.elapsedMilliseconds}ms), '
        'attempt=$attempt',
      );
    } catch (e) {
      commandReceivePort.close();
      errorReceivePort.close();
      exitReceivePort.close();
      _dbIsolate?.kill(priority: Isolate.immediate);
      await _logSubscription?.cancel();
      _logSubscription = null;
      _logReceivePort?.close();
      _logReceivePort = null;
      _dbIsolate = null;
      _dbSendPort = null;
      _log(
        'Isolate spawn failed (attempt '
        '$attempt/$_maxIsolateStartAttempts): $e',
      );
      rethrow;
    }
  }

  Future<T> _sendToIsolate<T>(
    DbIsolateAction action,
    Map<String, dynamic> payload,
  ) async {
    await _ensureIsolate();
    final responsePort = ReceivePort();
    _log('Isolate 요청: $action, payload=${_maskPayload(payload)}');
    if (action == DbIsolateAction.connect) {
      _log('Isolate 연결 문자열(mask): ${_maskConnectionString(payload)}');
    }
    _dbSendPort!.send(DbIsolateRequest(action, payload, responsePort.sendPort));
    final DbIsolateResponse res = await responsePort.first as DbIsolateResponse;
    responsePort.close();
    _log('Isolate 응답: $action, success=${res.success}');
    if (res.success) {
      return res.result as T;
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
  }) async {
    // Isolate가 준비될 때까지 기다려서 경합 조건을 방지한다.
    await _ensureIsolate();

    _log('DB 연결 시도: $ip:$port/$databaseName ($username)');
    final sw = Stopwatch()..start();
    final ok = await _sendToIsolate<bool>(DbIsolateAction.connect, {
      'ip': ip,
      'port': port,
      'databaseName': databaseName,
      'username': username,
      'password': password,
      'timeoutInSeconds': timeoutInSeconds,
    });
    sw.stop();
    _log('DB 연결 결과: $ok (${sw.elapsedMilliseconds}ms)');
    return ok;
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

  Future<void> disconnect() async {
    if (_dbSendPort == null) return;
    _log('DB 연결 종료 요청');
    final sw = Stopwatch()..start();
    try {
      await _sendToIsolate(DbIsolateAction.disconnect, {});
    } finally {
      _dbIsolate?.kill(priority: Isolate.immediate);
      _dbIsolate = null;
      _dbSendPort = null;
      await _logSubscription?.cancel();
      _logSubscription = null;
      _logReceivePort?.close();
      _logReceivePort = null;
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
