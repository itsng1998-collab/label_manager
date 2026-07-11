import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:label_manager/database/db_connection_status.dart';
import 'package:label_manager/database/db_connection_monitor.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/database/db_client.dart';

@visibleForTesting
bool dbConnectionGenerationIsCurrent({
  required int current,
  required int expected,
  required bool cancelled,
}) {
  return !cancelled && current == expected;
}

@visibleForTesting
bool dbReconnectLoopCanTakeOwnership({
  required int generation,
  required int? ownerGeneration,
}) {
  return ownerGeneration != generation;
}

/// DB 연결 상태 모니터링과 재연결을 담당하는 전역 서비스
class DbConnectionService {
  DbConnectionService._();
  static final DbConnectionService instance = DbConnectionService._();
  final status = DbConnectionStatus.instance;

  DbConnectionMonitor? _monitor;
  StreamSubscription<bool>? _sub;
  ServerConnectInfo? _lastConnectInfo;
  int _retryAttempt = 0;
  bool _reconnectCancelled = false;
  int _pollingPauseDepth = 0;
  Future<bool>? _connectionRecovery;
  int? _connectionRecoveryGeneration;
  int? _reconnectLoopGeneration;
  int _attachmentGeneration = 0;

  void attachAndStart({
    required ServerConnectInfo info,
    Duration interval = const Duration(seconds: 20),
  }) {
    final generation = ++_attachmentGeneration;
    _lastConnectInfo = info;
    _reconnectCancelled = false;
    _retryAttempt = 0;
    _monitor?.dispose();
    _monitor = DbConnectionMonitor(
      interval: interval,
      onLost: () {
        if (!_isCurrentGeneration(generation)) return;
        status.up.value = false;
        _scheduleReconnect(generation);
      },
      onRestored: () {
        if (!_isCurrentGeneration(generation)) return;
        status.up.value = true;
        _retryAttempt = 0;
        status.reconnecting.value = false;
      },
    )..start();
    _pollingPauseDepth = 0;
    _sub?.cancel();
    _sub = _monitor!.statusStream.listen((up) {
      if (!_isCurrentGeneration(generation)) return;
      status.up.value = up;
    });
  }

  void detach() {
    _attachmentGeneration++;
    _reconnectCancelled = true;
    _lastConnectInfo = null;
    _monitor?.dispose();
    _monitor = null;
    _sub?.cancel();
    _sub = null;
    status.reset();
  }

  bool _isCurrentGeneration(int generation) {
    return dbConnectionGenerationIsCurrent(
      current: _attachmentGeneration,
      expected: generation,
      cancelled: _reconnectCancelled,
    );
  }

  // 사용자 쿼리 수행 중에는 모니터링 핑을 중지하여 세션 충돌을 피한다.
  void pausePolling() {
    if (_monitor == null) return;
    _pollingPauseDepth++;
    if (_pollingPauseDepth == 1) {
      _monitor!.stop();
    }
  }

  // 사용자 쿼리가 끝난 뒤 모니터링을 재개한다.
  void resumePolling() {
    if (_monitor == null) return;
    if (_pollingPauseDepth > 0) _pollingPauseDepth--;
    if (_pollingPauseDepth == 0) {
      _monitor!.start(immediate: false);
    }
  }

  /// 사용자 주도 DB 작업을 안전하게 실행한다.
  /// - 실행 전 모니터링 폴링을 일시 중지하고, 종료 후 재개한다(중첩 안전).
  /// - [timeout]이 지정되면 해당 시간 내 미응답 시 [onTimeout] 결과를 반환한다.
  Future<T> runUserDbAction<T>(
    Future<T> Function(DbClient db) action, {
    Duration? timeout,
    T Function()? onTimeout,
  }) async {
    final db = DbClient.instance;
    pausePolling();
    try {
      final fut = action(db);
      if (timeout != null) {
        return await fut.timeout(timeout, onTimeout: onTimeout);
      }
      return await fut;
    } finally {
      resumePolling();
    }
  }

  Future<void> _scheduleReconnect(int generation) async {
    if (!_isCurrentGeneration(generation) ||
        !dbReconnectLoopCanTakeOwnership(
          generation: generation,
          ownerGeneration: _reconnectLoopGeneration,
        )) {
      return;
    }
    _reconnectLoopGeneration = generation;
    status.reconnecting.value = true;
    final db = DbClient.instance;

    while (!db.isConnected &&
        _lastConnectInfo != null &&
        _isCurrentGeneration(generation)) {
      final backoff = Duration(
        seconds: (5 * (1 << _retryAttempt)).clamp(5, 60),
      );
      await Future.delayed(backoff);
      if (!_isCurrentGeneration(generation)) break;

      if (await ensureConnected() && _isCurrentGeneration(generation)) {
        status.up.value = true;
        break;
      }

      if (!_isCurrentGeneration(generation)) break;

      _retryAttempt = (_retryAttempt + 1).clamp(0, 6);
    }

    if (_reconnectLoopGeneration == generation) {
      _reconnectLoopGeneration = null;
      status.reconnecting.value = false;
    }
  }

  Future<bool> ensureConnected() => _ensureConnected();

  Future<bool> _ensureConnected({bool force = false}) async {
    final db = DbClient.instance;
    final generation = _attachmentGeneration;
    final info = _lastConnectInfo;
    if (info == null || !_isCurrentGeneration(generation)) return false;
    final active = _connectionRecovery;
    if (active != null) {
      if (_connectionRecoveryGeneration == generation) return active;
      await active;
      if (!_isCurrentGeneration(generation)) return false;
      return _ensureConnected(force: true);
    }
    if (!force && db.isConnected) return true;

    final recovery = () async {
      try {
        final ok = await db.connect(
          ip: info.serverIp,
          port: info.serverPort.toString(),
          databaseName: info.databaseName,
          username: info.userId,
          password: info.password,
          timeoutInSeconds: 15,
        );
        if (!_isCurrentGeneration(generation)) return false;
        status.up.value = ok;
        if (ok) {
          _retryAttempt = 0;
          status.reconnecting.value = false;
        }
        return ok;
      } catch (_) {
        if (!_isCurrentGeneration(generation)) return false;
        status.up.value = false;
        return false;
      }
    }();
    _connectionRecovery = recovery;
    _connectionRecoveryGeneration = generation;
    try {
      return await recovery;
    } finally {
      if (identical(_connectionRecovery, recovery)) {
        _connectionRecovery = null;
        _connectionRecoveryGeneration = null;
      }
    }
  }

  void cancelReconnect() {
    _reconnectCancelled = true;
    _attachmentGeneration++;
    _reconnectLoopGeneration = null;
    status.reconnecting.value = false;
  }
}
