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
  });
}
