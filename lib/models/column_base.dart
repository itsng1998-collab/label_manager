// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/models/column_type.dart';

class TColumnBase {
  final TColumnType columnType;
  final String keyword;
  final String columnName;
  bool useMissingKeywordCheck;

  TColumnBase({
    required this.columnType,
    required this.keyword,
    required this.columnName,
    this.useMissingKeywordCheck = false,
  });

  @override
  String toString() =>
    '${columnType.toString()}, keyword: $keyword, columnName: $columnName, useMissingKeywordCheck: $useMissingKeywordCheck';
}
