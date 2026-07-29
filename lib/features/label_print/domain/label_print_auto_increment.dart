import 'package:flutter/foundation.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_print/domain/item_code_data_resolver.dart';

@immutable
class LabelAutoIncrementProjection {
  const LabelAutoIncrementProjection({
    required this.value,
    required this.applied,
  });

  final String value;
  final bool applied;
}

int legacyAtoi(String value) {
  var index = 0;
  while (index < value.length && _isAsciiWhitespace(value.codeUnitAt(index))) {
    index += 1;
  }
  var sign = 1;
  if (index < value.length &&
      (value.codeUnitAt(index) == 0x2b || value.codeUnitAt(index) == 0x2d)) {
    if (value.codeUnitAt(index) == 0x2d) sign = -1;
    index += 1;
  }
  var result = 0;
  var hasDigit = false;
  while (index < value.length) {
    final code = value.codeUnitAt(index);
    if (code < 0x30 || code > 0x39) break;
    hasDigit = true;
    result = result * 10 + code - 0x30;
    index += 1;
  }
  return hasDigit ? result * sign : 0;
}

LabelAutoIncrementProjection projectLabelAutoIncrement({
  required String original,
  required int copyIndex,
  required int autoIncSize,
  required int autoIncRange,
  required bool autoIncZeroDel,
  required DateTime referenceAt,
  int timeBarcodeSuffixLength = 0,
  bool hasBarcodeCheckDigit = false,
  String Function(String value)? applyBarcodeCheckDigit,
  String Function(String value, DateTime referenceAt)? applyTimeBarcode,
}) {
  if (autoIncRange <= 0) {
    return LabelAutoIncrementProjection(value: original, applied: false);
  }
  final prepared = _prepareAutoIncrementTarget(
    original: original,
    autoIncRange: autoIncRange,
    timeBarcodeSuffixLength: timeBarcodeSuffixLength,
    hasBarcodeCheckDigit: hasBarcodeCheckDigit,
  );
  final source = prepared.source;
  final split = source.length > autoIncRange
      ? source.length - autoIncRange
      : 0;
  final prefix = source.substring(0, split);
  final target = prepared.target;
  final originalNumber = legacyAtoi(target);
  if (target != '0' && originalNumber == 0) {
    return LabelAutoIncrementProjection(value: original, applied: false);
  }

  var candidate = originalNumber + autoIncSize * copyIndex;
  final rangeLimit = _pow10(autoIncRange);
  if (candidate >= rangeLimit) candidate -= rangeLimit;
  final number = '$candidate';
  final projected = autoIncZeroDel ? number : number.padLeft(autoIncRange, '0');
  var value = '$prefix$projected';
  if (hasBarcodeCheckDigit && applyBarcodeCheckDigit != null) {
    value = applyBarcodeCheckDigit(value);
  }
  if (timeBarcodeSuffixLength > 0 && applyTimeBarcode != null) {
    value = applyTimeBarcode(value, referenceAt);
  }
  return LabelAutoIncrementProjection(value: value, applied: true);
}

bool labelAutoIncrementApplies({
  required String original,
  required int autoIncRange,
  int timeBarcodeSuffixLength = 0,
  bool hasBarcodeCheckDigit = false,
}) {
  if (autoIncRange <= 0) return false;
  final target = _prepareAutoIncrementTarget(
    original: original,
    autoIncRange: autoIncRange,
    timeBarcodeSuffixLength: timeBarcodeSuffixLength,
    hasBarcodeCheckDigit: hasBarcodeCheckDigit,
  ).target;
  return target == '0' || legacyAtoi(target) != 0;
}

bool _isAsciiWhitespace(int code) =>
    code == 0x20 || (code >= 0x09 && code <= 0x0d);

int _pow10(int exponent) {
  var result = 1;
  for (var index = 0; index < exponent; index += 1) {
    result *= 10;
  }
  return result;
}

({String source, String target}) _prepareAutoIncrementTarget({
  required String original,
  required int autoIncRange,
  required int timeBarcodeSuffixLength,
  required bool hasBarcodeCheckDigit,
}) {
  var source = original;
  if (timeBarcodeSuffixLength > 0 && source.length >= timeBarcodeSuffixLength) {
    source = source.substring(0, source.length - timeBarcodeSuffixLength);
  }
  if (hasBarcodeCheckDigit && source.isNotEmpty) {
    source = source.substring(0, source.length - 1);
  }
  final split = source.length > autoIncRange
      ? source.length - autoIncRange
      : 0;
  var target = source.substring(split);
  if (timeBarcodeSuffixLength > 0) {
    target = target.replaceFirst(RegExp(r'^0+'), '');
    if (target.isEmpty && source.substring(split).isNotEmpty) target = '0';
  }
  return (source: source, target: target);
}

Map<int, String> projectLabelPrintColumnValues({
  required int itemId,
  required int copyIndex,
  required List<TColumn> columns,
  required Map<ColumnItemKey, TColumnContent> columnContents,
  required DateTime referenceAt,
}) {
  final sortedColumns = [...columns]
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.columnId.compareTo(right.columnId);
    });
  final specs = [
    for (final column in sortedColumns) ItemCodeColumnSpec.fromColumn(column),
  ];
  String baseline(int columnId) =>
      columnContents[ColumnItemKey(columnId: columnId, itemId: itemId)]
          ?.dataString ??
      '';
  final projected = <int, String>{};
  for (var index = 0; index < sortedColumns.length; index += 1) {
    final column = sortedColumns[index];
    var value = itemCodeTokenColumnValue(
      column: specs[index],
      columns: specs,
      columnValue: baseline,
      referenceAt: referenceAt,
    );
    if (column.autoInc) {
      value = projectLabelAutoIncrement(
        original: baseline(column.columnId),
        copyIndex: copyIndex,
        autoIncSize: column.autoIncSize,
        autoIncRange: column.autoIncRange,
        autoIncZeroDel: column.autoIncZeroDel,
        referenceAt: referenceAt,
        timeBarcodeSuffixLength: labelTimeBarcodeSuffixLength(column),
        hasBarcodeCheckDigit:
            column.columnType.code == TColumnType.TYPE_BARCODE &&
            column.useBarcodeCheckDigit,
        applyBarcodeCheckDigit: (candidate) =>
            BarcodeDataHelper.normalizeForPrint(column.barcodeType, candidate),
        applyTimeBarcode: (candidate, at) =>
            '$candidate${_labelTimeBarcodeSuffix(column.timeBarcodeType, specs, baseline, at) ?? ''}',
      ).value;
    }
    projected[column.columnId] = value;
  }
  return Map.unmodifiable(projected);
}

int labelTimeBarcodeSuffixLength(TColumn column) {
  if (column.columnType.code != TColumnType.TYPE_BARCODE) return 0;
  return switch (column.timeBarcodeType) { 1 || 2 || 4 => 5, 9 => 7, _ => 0 };
}

String? _labelTimeBarcodeSuffix(
  int type,
  List<ItemCodeColumnSpec> columns,
  String Function(int columnId) columnValue,
  DateTime referenceAt,
) {
  final validDateColumn = columns
      .where((column) => column.typeCode == TColumnType.TYPE_VALIDDATE)
      .firstOrNull;
  if (validDateColumn == null) return null;
  final validDateValue = itemCodeTokenColumnValue(
    column: validDateColumn,
    columns: columns,
    columnValue: columnValue,
    referenceAt: referenceAt,
  );
  if (!RegExp(r'^\d{8}$').hasMatch(validDateValue)) return null;
  final year = validDateValue.substring(2, 4);
  final month = validDateValue.substring(4, 6);
  final day = validDateValue.substring(6, 8);
  final validTime = columns
      .where((column) => column.typeCode == TColumnType.TYPE_VALIDTIME)
      .map((column) => columnValue(column.columnId).trim())
      .firstOrNull;
  return switch (type) {
    1 => '1$day$month',
    2 when validTime != null && RegExp(r'^\d{4}$').hasMatch(validTime) =>
      '2${validTime.substring(0, 2)}$day',
    4 when validTime != null && RegExp(r'^\d{4}$').hasMatch(validTime) =>
      '4$day${validTime.substring(0, 2)}',
    9 => '9$year$month$day',
    _ => null,
  };
}