import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_connection_monitor.dart';
import 'package:label_manager/database/db_connection_service.dart';

void main() {
  test('initial failed ping reports connection loss', () async {
    final lost = Completer<void>();
    final monitor = DbConnectionMonitor(
      customPing: () async => false,
      onLost: lost.complete,
    );
    addTearDown(monitor.dispose);

    monitor.start();

    await lost.future;
    expect(monitor.lastStatus, isFalse);
  });

  test('connection generation rejects cancelled and stale work', () {
    expect(
      dbConnectionGenerationIsCurrent(
        current: 3,
        expected: 3,
        cancelled: false,
      ),
      isTrue,
    );
    expect(
      dbConnectionGenerationIsCurrent(
        current: 4,
        expected: 3,
        cancelled: false,
      ),
      isFalse,
    );
    expect(
      dbConnectionGenerationIsCurrent(current: 3, expected: 3, cancelled: true),
      isFalse,
    );
  });

  test('new generation takes reconnect ownership from an old loop', () async {
    final oldLoop = Completer<void>();
    int? ownerGeneration = 3;
    final oldCompletion = oldLoop.future.then((_) {
      if (ownerGeneration == 3) ownerGeneration = null;
    });

    expect(
      dbReconnectLoopCanTakeOwnership(
        generation: 4,
        ownerGeneration: ownerGeneration,
      ),
      isTrue,
    );
    ownerGeneration = 4;
    oldLoop.complete();
    await oldCompletion;

    expect(ownerGeneration, 4);
  });
}
