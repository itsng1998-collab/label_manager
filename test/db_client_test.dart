import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_isolate.dart';
import 'package:label_manager/database/drivers/db_driver.dart';

void main() {
  group('[DB client isolate boundary]', () {
    test('transaction termination reports unknown commit outcome', () async {
      final response = Completer<DbIsolateResponse>();
      final termination = Completer<Object>();

      final result = waitForDbIsolateResponse(
        action: DbIsolateAction.transaction,
        response: response.future,
        termination: termination.future,
      );
      termination.complete('isolate exited');

      await expectLater(result, throwsA(isA<DbCommitOutcomeUnknown>()));
    });

    test('query termination reports a regular isolate failure', () async {
      final response = Completer<DbIsolateResponse>();
      final termination = Completer<Object>();

      final result = waitForDbIsolateResponse(
        action: DbIsolateAction.query,
        response: response.future,
        termination: termination.future,
      );
      termination.complete('isolate exited');

      await expectLater(result, throwsStateError);
    });

    test('response wins when it arrives before termination', () async {
      final response = Completer<DbIsolateResponse>();
      final termination = Completer<Object>();
      final expected = DbIsolateResponse(success: true, result: 'ok');

      final result = waitForDbIsolateResponse(
        action: DbIsolateAction.transaction,
        response: response.future,
        termination: termination.future,
      );
      response.complete(expected);

      expect(await result, same(expected));
    });

    test('explicit cleanup completes pending requests', () async {
      final response = Completer<DbIsolateResponse>();
      final termination = Completer<Object>();

      final result = waitForDbIsolateResponse(
        action: DbIsolateAction.query,
        response: response.future,
        termination: termination.future,
      );
      completeDbIsolateTermination(termination, 'client disconnected');

      await expectLater(result, throwsStateError);
      expect(termination.isCompleted, isTrue);
    });

    test('termination completion is idempotent', () async {
      final termination = Completer<Object>();

      completeDbIsolateTermination(termination, 'first');
      completeDbIsolateTermination(termination, 'second');

      expect(await termination.future, 'first');
    });

    test('connection-lost response invalidates cached driver state', () {
      final response = DbIsolateResponse(
        success: false,
        error: 'link failure',
        errorCode: 'connectionLost',
      );

      expect(
        dbDriverConnectedAfterResponse(current: true, response: response),
        isFalse,
      );
    });

    test('commit-unknown connection loss invalidates cached state', () {
      final response = DbIsolateResponse(
        success: false,
        error: 'commit outcome unknown after link failure',
        errorCode: 'commitOutcomeUnknownConnectionLost',
      );

      expect(
        dbDriverConnectedAfterResponse(current: true, response: response),
        isFalse,
      );
    });

    test('statement error preserves cached driver state', () {
      final response = DbIsolateResponse(success: false, error: 'syntax error');

      expect(
        dbDriverConnectedAfterResponse(current: true, response: response),
        isTrue,
      );
    });

    test('connect result is rejected after disconnect starts', () {
      expect(
        dbConnectResultAccepted(result: true, disconnecting: true),
        isFalse,
      );
      expect(
        dbConnectResultAccepted(result: true, disconnecting: false),
        isTrue,
      );
    });

    test('connect identity includes server credentials and timeout', () {
      final first = (
        ip: '10.0.0.1',
        port: '1433',
        databaseName: 'main',
        username: 'user',
        password: 'secret',
        timeoutInSeconds: 15,
      );

      expect(dbConnectIdentityMatches(left: first, right: first), isTrue);
      expect(
        dbConnectIdentityMatches(
          left: first,
          right: (
            ip: '10.0.0.2',
            port: '1433',
            databaseName: 'main',
            username: 'user',
            password: 'secret',
            timeoutInSeconds: 15,
          ),
        ),
        isFalse,
      );
    });

    test('same connect identity shares one in-flight operation', () async {
      final queue = DbConnectOperationQueue<String>();
      final completion = Completer<bool>();
      var calls = 0;

      Future<bool> operation() {
        calls++;
        return completion.future;
      }

      final first = queue.run('server-a', operation);
      final second = queue.run('server-a', operation);
      expect(identical(first, second), isTrue);
      expect(calls, 1);

      completion.complete(true);
      expect(await first, isTrue);
      expect(await second, isTrue);
    });

    test('different connect identity waits and runs after failure', () async {
      final queue = DbConnectOperationQueue<String>();
      final firstCompletion = Completer<bool>();
      final calls = <String>[];

      final first = queue.run('server-a', () {
        calls.add('server-a');
        return firstCompletion.future;
      });
      final second = queue.run('server-b', () async {
        calls.add('server-b');
        return true;
      });
      expect(calls, ['server-a']);

      firstCompletion.completeError(StateError('connect failed'));
      await expectLater(first, throwsStateError);
      expect(await second, isTrue);
      expect(calls, ['server-a', 'server-b']);
    });
  });
}
