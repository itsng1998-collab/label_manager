import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/print_history/data/print_log_dao.dart';

Object result(int ready) => {
  'columns': ['INDEX_READY'],
  'rows': [
    {'INDEX_READY': ready},
  ],
  'affected': 0,
};

void main() {
  test('ready index does not create or announce creation', () async {
    await PrintLogDAO.ensureQueryIndex(
      read: (sql) async {
        expect(sql, PrintLogDAO.queryIndexCheckSql);
        return result(1);
      },
      write: (_) async => fail('must not create existing index'),
      onCreating: () => fail('must not announce existing index'),
    );
  });

  test('missing index announces creation before waiting and verifies it', () async {
    final pending = Completer<Object>();
    final events = <String>[];
    var reads = 0;
    final ensured = PrintLogDAO.ensureQueryIndex(
      read: (_) async {
        events.add('read');
        return result(reads++ == 0 ? 0 : 1);
      },
      onCreating: () => events.add('creating'),
      write: (sql) {
        expect(sql, PrintLogDAO.createQueryIndexSql);
        events.add('write');
        return pending.future;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, ['read', 'creating', 'write']);
    pending.complete({'rows': [], 'affected': 0});
    await ensured;
    expect(events, ['read', 'creating', 'write', 'read']);
  });

  test('index is checked again after changing the database', () async {
    final readiness = [1, 0, 1].iterator;
    var writes = 0;
    Future<Object> read(String _) async {
      expect(readiness.moveNext(), isTrue);
      return result(readiness.current);
    }
    Future<Object> write(String _) async {
      writes += 1;
      return {'rows': [], 'affected': 0};
    }
    await PrintLogDAO.ensureQueryIndex(read: read, write: write);
    await PrintLogDAO.ensureQueryIndex(read: read, write: write);
    expect(writes, 1);
  });

  test('index creation failures are not converted to success', () async {
    final error = StateError('permission denied');
    await expectLater(
      PrintLogDAO.ensureQueryIndex(
        read: (_) async => result(0),
        write: (_) async => throw error,
      ),
      throwsA(same(error)),
    );
  });

  test('index check failures do not attempt schema changes', () async {
    final error = StateError('connection lost');
    await expectLater(
      PrintLogDAO.ensureQueryIndex(
        read: (_) async => throw error,
        write: (_) async => fail('must not create after failed check'),
      ),
      throwsA(same(error)),
    );
  });

  test('index must be usable after creation or concurrent creation', () async {
    await expectLater(
      PrintLogDAO.ensureQueryIndex(
        read: (_) async => result(0),
        write: (_) async => {'rows': [], 'affected': 0},
      ),
      throwsStateError,
    );
  });

  test('invalid index check response is an explicit error', () {
    expect(
      () => printHistoryQueryIndexReady({
        'rows': [
          {'INDEX_READY': null},
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => printHistoryQueryIndexReady({'rows': []}),
      throwsStateError,
    );
  });

  test('index SQL is narrow, schema aware, and compatible with SQL Server 2017', () {
    final check = PrintLogDAO.queryIndexCheckSql;
    final create = PrintLogDAO.createQueryIndexSql;
    expect(check, contains('sys.indexes'));
    expect(check, contains('i.is_disabled=0'));
    expect(check, contains('ic.key_ordinal=1'));
    expect(check, contains('ic.key_ordinal=2'));
    expect(check, isNot(contains('FROM BM_RICH_PRINT_LOG')));
    expect(create, contains('QUOTENAME(OBJECT_SCHEMA_NAME(@objectId))'));
    expect(create, contains('([RICH_CUSTOMER_ID], [RICH_DATE_YYYYMMDD])'));
    expect(create, contains('INCLUDE ([RICH_DATETIME])'));
    expect(create, contains('IF NOT EXISTS'));
    expect(create, contains('IF ERROR_NUMBER()<>1913'));
    expect(create, contains('THROW;'));
    for (final forbidden in [
      'DROP ', 'DELETE ', 'UPDATE ', 'ONLINE=ON', 'RESUMABLE', 'RICH_PRINT_CELLS',
    ]) {
      expect(create, isNot(contains(forbidden)));
    }
  });
}
