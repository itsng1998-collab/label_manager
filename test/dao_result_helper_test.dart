import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/dao.dart';

void main() {
  group('DAO result helpers', () {
    final resultMap = <String, dynamic>{
      'columns': ['ID', 'NAME'],
      'rows': [
        {'ID': 1, 'NAME': 'Alpha'},
      ],
      'affected': 0,
    };

    test('read rows directly from structured isolate result maps', () {
      final rows = DAO.getRowsFromResult(resultMap);

      expect(rows, hasLength(1));
      expect(rows.single, {'ID': 1, 'NAME': 'Alpha'});
    });

    test(
      'map structured result rows without model-level fromPipeLines helpers',
      () {
        final names = DAO.mapRows(resultMap, (row) => row['NAME'] as String);
        final row = DAO.mapRow(resultMap, (row) => row['ID'] as int);
        final byId = DAO.mapRowsByKey(
          resultMap,
          (row) => row['NAME'] as String,
          (name) => name.length,
        );

        expect(names, ['Alpha']);
        expect(row, 1);
        expect(byId, {5: 'Alpha'});
      },
    );

    test('keep compatibility with JSON string driver results', () {
      final rows = DAO.getRowsFromResult(jsonEncode(resultMap));
      final row = DAO.getRowMapFromResult(jsonEncode(resultMap));

      expect(rows.single, {'ID': 1, 'NAME': 'Alpha'});
      expect(row, {'ID': 1, 'NAME': 'Alpha'});
    });

    test('return empty collections for empty list query results', () {
      final emptyResult = <String, dynamic>{
        'columns': ['ID', 'NAME'],
        'rows': <Map<String, dynamic>>[],
        'affected': 0,
      };

      final rows = DAO.getRowsFromResult(emptyResult);
      final names = DAO.mapRows(emptyResult, (row) => row['NAME'] as String);
      final byId = DAO.mapRowsByKey(
        emptyResult,
        (row) => row['NAME'] as String,
        (name) => name.length,
      );

      expect(rows, isEmpty);
      expect(names, isEmpty);
      expect(byId, isEmpty);
      expect(
        () => DAO.getRowMapFromResult(emptyResult),
        throwsA(isA<StateError>()),
      );
      expect(
        DAO.getRowMapFromResult(emptyResult, throwIfNoRows: false),
        isNull,
      );
    });
  });
}
