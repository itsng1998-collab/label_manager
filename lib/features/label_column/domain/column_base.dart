// ignore_for_file: non_constant_identifier_names

import 'package:label_manager/features/label_column/domain/column_type.dart';

class TColumnBase {
  final TColumnType columnType;
  final String keyword;
  final String columnName;
  bool useMissingKeywordCheck;
  bool useMinColumnCheck;

  TColumnBase({
    required this.columnType,
    required this.keyword,
    required this.columnName,
    this.useMissingKeywordCheck = false,
    this.useMinColumnCheck = false,
  });

  @override
  String toString() =>
      '${columnType.toString()}, keyword: $keyword, columnName: $columnName, useMissingKeywordCheck: $useMissingKeywordCheck, useMinColumnCheck: $useMinColumnCheck';
}
