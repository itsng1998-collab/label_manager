String rewriteFormulaReferencesForInsert(
  String formula, {
  required String type,
  required int index,
  required int count,
  required String direction,
  String? targetSheetName,
}) {
  if (!_isFormula(formula) || count <= 0 || index < 0) {
    return formula;
  }
  return _rewriteFormulaReferences(
    formula,
    type: type,
    operation: _ReferenceOperation.insert,
    index: index,
    count: count,
    direction: direction,
    targetSheetName: targetSheetName,
  );
}

String rewriteFormulaReferencesForDelete(
  String formula, {
  required String type,
  required int start,
  required int end,
  String? targetSheetName,
}) {
  if (!_isFormula(formula) || start < 0 || end < 0) {
    return formula;
  }
  final deleteStart = start < end ? start : end;
  final deleteEnd = start < end ? end : start;
  return _rewriteFormulaReferences(
    formula,
    type: type,
    operation: _ReferenceOperation.delete,
    index: deleteStart,
    count: deleteEnd - deleteStart + 1,
    direction: 'rightbottom',
    targetSheetName: targetSheetName,
  );
}

enum _ReferenceOperation { insert, delete }

final RegExp _referencePattern = RegExp(
  r"((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)([A-Za-z]+)(\$?)(\d+)'
  r"(?:\s*:\s*((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)([A-Za-z]+)(\$?)(\d+))?',
);

final RegExp _wholeColumnRangePattern = RegExp(
  r"((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)([A-Za-z]+)\s*:\s*'
  r"((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)([A-Za-z]+)',
);

final RegExp _wholeRowRangePattern = RegExp(
  r"((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)(\d+)\s*:\s*'
  r"((?:'(?:(?:'')|[^'])+'|(?:\[[^\]]+\])?[^!'()+\-*/,=&<>\s:]+)!)?"
  r'(\$?)(\d+)',
);

bool _isFormula(String formula) => formula.startsWith('=');

String _rewriteFormulaReferences(
  String formula, {
  required String type,
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
  required String? targetSheetName,
}) {
  final isRow = type == 'row';
  final isColumn = type == 'column';
  if (!isRow && !isColumn) {
    return formula;
  }

  final buffer = StringBuffer();
  var offset = 0;
  for (final match in _referencePattern.allMatches(formula)) {
    if (_shouldSkipReferenceMatch(formula, match)) {
      continue;
    }
    buffer.write(formula.substring(offset, match.start));
    final first = _ReferenceEndpoint(
      prefix: match.group(1) ?? '',
      columnAbsolute: match.group(2) == r'$',
      column: _columnIndex(match.group(3)!),
      rowAbsolute: match.group(4) == r'$',
      row: int.parse(match.group(5)!) - 1,
    );
    final hasRangeEnd = match.group(9) != null;
    final second = hasRangeEnd
        ? _ReferenceEndpoint(
            prefix: match.group(6) ?? '',
            columnAbsolute: match.group(7) == r'$',
            column: _columnIndex(match.group(8)!),
            rowAbsolute: match.group(9) == r'$',
            row: int.parse(match.group(10)!) - 1,
          )
        : first;

    final rewritten = _rewriteReferenceRange(
      first,
      second,
      hasRangeEnd: hasRangeEnd,
      isRow: isRow,
      operation: operation,
      index: index,
      count: count,
      direction: direction,
      targetSheetName: targetSheetName,
    );
    buffer.write(rewritten);
    offset = match.end;
  }
  buffer.write(formula.substring(offset));
  final rewritten = buffer.toString();
  return isRow
      ? _rewriteWholeRowRanges(
          rewritten,
          operation: operation,
          index: index,
          count: count,
          direction: direction,
          targetSheetName: targetSheetName,
        )
      : _rewriteWholeColumnRanges(
          rewritten,
          operation: operation,
          index: index,
          count: count,
          direction: direction,
          targetSheetName: targetSheetName,
        );
}

String _rewriteWholeColumnRanges(
  String formula, {
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
  required String? targetSheetName,
}) {
  return _rewriteWholeAxisRanges(
    formula,
    pattern: _wholeColumnRangePattern,
    operation: operation,
    index: index,
    count: count,
    direction: direction,
    targetSheetName: targetSheetName,
    parse: _columnIndex,
    format: _columnName,
  );
}

String _rewriteWholeRowRanges(
  String formula, {
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
  required String? targetSheetName,
}) {
  return _rewriteWholeAxisRanges(
    formula,
    pattern: _wholeRowRangePattern,
    operation: operation,
    index: index,
    count: count,
    direction: direction,
    targetSheetName: targetSheetName,
    parse: (value) => int.parse(value) - 1,
    format: (value) => '${value + 1}',
  );
}

String _rewriteWholeAxisRanges(
  String formula, {
  required RegExp pattern,
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
  required String? targetSheetName,
  required int Function(String value) parse,
  required String Function(int value) format,
}) {
  final buffer = StringBuffer();
  var offset = 0;
  for (final match in pattern.allMatches(formula)) {
    if (_shouldSkipReferenceMatch(formula, match)) {
      continue;
    }
    if (targetSheetName != null &&
        !_wholeAxisRangeBelongsToTargetSheet(match, targetSheetName)) {
      continue;
    }
    buffer.write(formula.substring(offset, match.start));
    final first = parse(match.group(3)!);
    final second = parse(match.group(6)!);
    final rewritten = _rewriteWholeAxisRange(
      first,
      second,
      operation: operation,
      index: index,
      count: count,
      direction: direction,
    );
    if (rewritten == null) {
      buffer.write('#REF!');
    } else {
      final (nextFirst, nextSecond) = rewritten;
      buffer
        ..write(match.group(1) ?? '')
        ..write(match.group(2) == r'$' ? r'$' : '')
        ..write(format(nextFirst));
      if (nextFirst != nextSecond || match.group(1) != match.group(4)) {
        buffer
          ..write(':')
          ..write(match.group(4) ?? '')
          ..write(match.group(5) == r'$' ? r'$' : '')
          ..write(format(nextSecond));
      }
    }
    offset = match.end;
  }
  buffer.write(formula.substring(offset));
  return buffer.toString();
}

(int, int)? _rewriteWholeAxisRange(
  int first,
  int second, {
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
}) {
  if (first > second) {
    return (first, second);
  }
  if (operation == _ReferenceOperation.insert) {
    final inclusive = direction == 'lefttop';
    final nextFirst = (inclusive ? first >= index : first > index)
        ? first + count
        : first;
    final nextSecond = (inclusive ? second >= index : second > index)
        ? second + count
        : second;
    return (nextFirst, nextSecond);
  }
  final deleteEnd = index + count - 1;
  if (first >= index && second <= deleteEnd) {
    return null;
  }
  var nextFirst = first;
  var nextSecond = second;
  if (nextFirst > deleteEnd) {
    nextFirst -= count;
  } else if (nextFirst >= index) {
    nextFirst = index;
  }
  if (nextSecond > deleteEnd) {
    nextSecond -= count;
  } else if (nextSecond >= index) {
    nextSecond = index - 1;
  }
  if (nextFirst < 0) {
    nextFirst = 0;
  }
  if (nextSecond < nextFirst) {
    nextSecond = nextFirst;
  }
  return (nextFirst, nextSecond);
}

bool _shouldSkipReferenceMatch(String formula, RegExpMatch match) {
  if (_isInsideFormulaQuotedSegment(formula, match.start)) {
    return true;
  }
  final previous = match.start > 0 ? formula[match.start - 1] : '';
  final next = match.end < formula.length ? formula[match.end] : '';
  if (_isIdentifierChar(previous) || _isIdentifierChar(next)) {
    return true;
  }
  return next == '(' || next == '!';
}

String _rewriteReferenceRange(
  _ReferenceEndpoint first,
  _ReferenceEndpoint second, {
  required bool hasRangeEnd,
  required bool isRow,
  required _ReferenceOperation operation,
  required int index,
  required int count,
  required String direction,
  required String? targetSheetName,
}) {
  if (targetSheetName != null &&
      !_referenceRangeBelongsToTargetSheet(
        first,
        second,
        hasRangeEnd: hasRangeEnd,
        targetSheetName: targetSheetName,
      )) {
    return hasRangeEnd ? '${first.text}:${second.text}' : first.text;
  }
  if (hasRangeEnd &&
      ((second.prefix.isNotEmpty && first.prefix != second.prefix) ||
          first.after(second))) {
    return '${first.text}:${second.text}';
  }
  var start = first;
  var end = second;
  if (operation == _ReferenceOperation.insert) {
    start = start.inserted(
      isRow: isRow,
      index: index,
      count: count,
      direction: direction,
    );
    end = end.inserted(
      isRow: isRow,
      index: index,
      count: count,
      direction: direction,
    );
  } else {
    final deleteEnd = index + count - 1;
    if (_rangeDeleted(
      start,
      end,
      isRow: isRow,
      deleteStart: index,
      deleteEnd: deleteEnd,
    )) {
      return '#REF!';
    }
    start = start.deleted(isRow: isRow, start: index, end: deleteEnd);
    end = end.deleted(isRow: isRow, start: index, end: deleteEnd);
    if (isRow && end.row < start.row) {
      end = end.copyWith(row: start.row);
    } else if (!isRow && end.column < start.column) {
      end = end.copyWith(column: start.column);
    }
  }

  if (!hasRangeEnd || start.sameCellAs(end)) {
    return start.text;
  }
  return '${start.text}:${end.text}';
}

bool _referenceRangeBelongsToTargetSheet(
  _ReferenceEndpoint first,
  _ReferenceEndpoint second, {
  required bool hasRangeEnd,
  required String targetSheetName,
}) {
  if (!_prefixMatchesSheet(first.prefix, targetSheetName)) {
    return false;
  }
  return !hasRangeEnd ||
      second.prefix.isEmpty ||
      _prefixMatchesSheet(second.prefix, targetSheetName);
}

bool _wholeAxisRangeBelongsToTargetSheet(
  RegExpMatch match,
  String targetSheetName,
) {
  final firstPrefix = match.group(1) ?? '';
  final secondPrefix = match.group(4) ?? '';
  if (!_prefixMatchesSheet(firstPrefix, targetSheetName)) {
    return false;
  }
  return secondPrefix.isEmpty ||
      _prefixMatchesSheet(secondPrefix, targetSheetName);
}

bool _prefixMatchesSheet(String prefix, String sheetName) {
  if (prefix.isEmpty || !prefix.endsWith('!')) {
    return false;
  }
  var name = prefix.substring(0, prefix.length - 1);
  final bracketIndex = name.lastIndexOf(']');
  if (bracketIndex >= 0 && bracketIndex + 1 < name.length) {
    name = name.substring(bracketIndex + 1);
  }
  if (name.length >= 2 && name.startsWith("'") && name.endsWith("'")) {
    name = name.substring(1, name.length - 1).replaceAll("''", "'");
  }
  return name.toUpperCase() == sheetName.toUpperCase();
}

bool _rangeDeleted(
  _ReferenceEndpoint rangeStart,
  _ReferenceEndpoint rangeEnd, {
  required bool isRow,
  required int deleteStart,
  required int deleteEnd,
}) {
  final first = isRow ? rangeStart.row : rangeStart.column;
  final second = isRow ? rangeEnd.row : rangeEnd.column;
  return first >= deleteStart && second <= deleteEnd;
}

class _ReferenceEndpoint {
  const _ReferenceEndpoint({
    required this.prefix,
    required this.columnAbsolute,
    required this.column,
    required this.rowAbsolute,
    required this.row,
  });

  final String prefix;
  final bool columnAbsolute;
  final int column;
  final bool rowAbsolute;
  final int row;

  String get text {
    return '$prefix${columnAbsolute ? r'$' : ''}${_columnName(column)}'
        '${rowAbsolute ? r'$' : ''}${row + 1}';
  }

  bool sameCellAs(_ReferenceEndpoint other) {
    return prefix == other.prefix && column == other.column && row == other.row;
  }

  bool after(_ReferenceEndpoint other) {
    return row > other.row || column > other.column;
  }

  _ReferenceEndpoint inserted({
    required bool isRow,
    required int index,
    required int count,
    required String direction,
  }) {
    final inclusive = direction == 'lefttop';
    if (isRow) {
      final shouldShift = inclusive ? row >= index : row > index;
      return shouldShift ? copyWith(row: row + count) : this;
    }
    final shouldShift = inclusive ? column >= index : column > index;
    return shouldShift ? copyWith(column: column + count) : this;
  }

  _ReferenceEndpoint deleted({
    required bool isRow,
    required int start,
    required int end,
  }) {
    final count = end - start + 1;
    if (isRow) {
      if (row > end) {
        return copyWith(row: row - count);
      }
      if (row >= start) {
        return copyWith(row: start);
      }
      return this;
    }
    if (column > end) {
      return copyWith(column: column - count);
    }
    if (column >= start) {
      return copyWith(column: start);
    }
    return this;
  }

  _ReferenceEndpoint copyWith({int? column, int? row}) {
    return _ReferenceEndpoint(
      prefix: prefix,
      columnAbsolute: columnAbsolute,
      column: column ?? this.column,
      rowAbsolute: rowAbsolute,
      row: row ?? this.row,
    );
  }
}

bool _isInsideFormulaQuotedSegment(String formula, int position) {
  var inDoubleQuotedText = false;
  var inSingleQuotedName = false;
  var inBracketedName = false;
  for (var index = 0; index < position; index += 1) {
    final char = formula[index];
    if (char == '"' && !inSingleQuotedName) {
      if (inDoubleQuotedText &&
          index + 1 < position &&
          formula[index + 1] == '"') {
        index += 1;
      } else {
        inDoubleQuotedText = !inDoubleQuotedText;
      }
    } else if (char == "'" && !inDoubleQuotedText) {
      if (inSingleQuotedName &&
          index + 1 < position &&
          formula[index + 1] == "'") {
        index += 1;
      } else {
        inSingleQuotedName = !inSingleQuotedName;
      }
    } else if (char == '[' && !inDoubleQuotedText && !inSingleQuotedName) {
      inBracketedName = true;
    } else if (char == ']' && inBracketedName) {
      inBracketedName = false;
    }
  }
  return inDoubleQuotedText || inSingleQuotedName || inBracketedName;
}

bool _isIdentifierChar(String value) {
  if (value.isEmpty) {
    return false;
  }
  final code = value.codeUnitAt(0);
  return (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      code == 95;
}

int _columnIndex(String columnName) {
  var result = 0;
  for (final code in columnName.toUpperCase().codeUnits) {
    result = result * 26 + (code - 64);
  }
  return result - 1;
}

String _columnName(int index) {
  var value = index + 1;
  final buffer = StringBuffer();
  while (value > 0) {
    value -= 1;
    buffer.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}
