// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:convert';

class DAO {
  static const String CP949 = 'Korean_Wansung_CI_AS';
  static const String LINE_U16LE = 'LINE_U16LE';
  static const String SPLITTER = '^';
  static const String exception = 'Exception';
  static const String incorrect_format = 'Incorrect format';
  static const String no_rows_result = 'No rows in result';
  static const String unsupported_result_type = 'Unsupported result type';
  static const int query_timeouts = 5;

  static Map<String, dynamic> _resultMap(Object jsonOrMap) =>
      switch (jsonOrMap) {
        final String s => jsonDecode(s) as Map<String, dynamic>,
        final Map mm when mm is Map<String, dynamic> => mm,
        _ => throw ArgumentError(unsupported_result_type),
      };

  static List<T> mapRows<T>(
    Object jsonOrMap,
    T Function(Map<String, dynamic> row) mapper,
  ) {
    final rows = getRowsFromResult(jsonOrMap);
    return [for (final row in rows) mapper(row as Map<String, dynamic>)];
  }

  static T? mapRow<T>(
    Object jsonOrMap,
    T Function(Map<String, dynamic> row) mapper, {
    bool throwIfNoRows = true,
  }) {
    final row = getRowMapFromResult(jsonOrMap, throwIfNoRows: throwIfNoRows);
    return row == null ? null : mapper(row);
  }

  static Map<K, V> mapRowsByKey<K, V>(
    Object jsonOrMap,
    V Function(Map<String, dynamic> row) mapper,
    K Function(V value) keyOf,
  ) {
    final result = <K, V>{};
    for (final value in mapRows(jsonOrMap, mapper)) {
      result[keyOf(value)] = value;
    }
    return result;
  }

  static List<dynamic> getRowFromResult(Object jsonOrMap) {
    final m = _resultMap(jsonOrMap);

    final rows = (m['rows'] as List?) ?? const [];
    if (rows.isEmpty) throw StateError(no_rows_result);
    final row = rows.first as Map<String, dynamic>;
    return row.values.toList(growable: false);
  }

  static Map<String, dynamic>? getRowMapFromResult(
    Object jsonOrMap, {
    bool throwIfNoRows = true,
  }) {
    final m = _resultMap(jsonOrMap);

    final rows = (m['rows'] as List?) ?? const [];
    if (throwIfNoRows && rows.isEmpty) throw StateError(no_rows_result);
    return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
  }

  static List<dynamic> getRowsFromResult(Object jsonOrMap) {
    final m = _resultMap(jsonOrMap);

    final rows = (m['rows'] as List?) ?? const [];
    return rows;
  }
}
