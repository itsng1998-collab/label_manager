import 'dart:ui';

import 'fortune_sheet_model.dart';

class FortuneBorderCompute {
  const FortuneBorderCompute._();

  static Map<FortuneCellCoord, FortuneCellBorders> compute(FortuneSheet sheet) {
    final result = <FortuneCellCoord, FortuneCellBorders>{};
    if (sheet.hasRawBorderInfo && sheet.rawBorderInfo is List) {
      _applyRawBorderInfo(
        result,
        sheet.rawBorderInfo! as List,
        hiddenRows: sheet.hiddenRows,
      );
      _removeHiddenRows(result, sheet.hiddenRows);
      _removeMergeInnerBorders(result, sheet);
      result.removeWhere((_, borders) => borders.isEmpty);
      return result;
    }
    for (final info in sheet.borderInfo) {
      if (info.rangeType != 'range') {
        continue;
      }
      final side = FortuneBorderSide(
        color: info.color,
        style: info.style,
        strokeWidth: info.strokeWidth,
      );
      for (final range in info.ranges) {
        _applyRangeBorder(
          result,
          info.borderType,
          range,
          side,
          hiddenRows: sheet.hiddenRows,
        );
      }
    }
    _removeHiddenRows(result, sheet.hiddenRows);
    _removeMergeInnerBorders(result, sheet);
    result.removeWhere((_, borders) => borders.isEmpty);
    return result;
  }

  static Map<FortuneCellCoord, FortuneCellBorders> computeRange(
    FortuneSheet sheet,
    FortuneRange datasetRange,
  ) {
    final result = <FortuneCellCoord, FortuneCellBorders>{};
    if (sheet.hasRawBorderInfo && sheet.rawBorderInfo is List) {
      _applyRawBorderInfo(
        result,
        sheet.rawBorderInfo! as List,
        clipRange: datasetRange,
        hiddenRows: sheet.hiddenRows,
      );
      _removeOutOfRange(result, datasetRange);
      _removeHiddenRows(result, sheet.hiddenRows);
      _removeMergeInnerBorders(result, sheet);
      result.removeWhere((_, borders) => borders.isEmpty);
      return result;
    }
    for (final info in sheet.borderInfo) {
      if (info.rangeType != 'range') {
        continue;
      }
      final side = FortuneBorderSide(
        color: info.color,
        style: info.style,
        strokeWidth: info.strokeWidth,
      );
      for (final range in info.ranges) {
        final clippedRange = _clipRange(range, datasetRange);
        if (clippedRange != null) {
          _applyRangeBorder(
            result,
            info.borderType,
            clippedRange,
            side,
            hiddenRows: sheet.hiddenRows,
          );
        }
      }
    }
    _removeOutOfRange(result, datasetRange);
    _removeHiddenRows(result, sheet.hiddenRows);
    _removeMergeInnerBorders(result, sheet);
    result.removeWhere((_, borders) => borders.isEmpty);
    return result;
  }

  static void _applyRawBorderInfo(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    List raw, {
    FortuneRange? clipRange,
    Set<int> hiddenRows = const {},
  }) {
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      final rangeType = item['rangeType'];
      if (rangeType == 'range') {
        final side = FortuneBorderSide(
          color: _rawBorderColor(item['color']) ?? const Color(0xff000000),
          style: _rawBorderInt(item['style']) ?? 1,
          strokeWidth: _rawBorderDouble(item['strokeWidth']),
        );
        final borderType = item['borderType']?.toString() ?? 'border-all';
        final ranges = item['range'];
        if (ranges is! List) {
          continue;
        }
        for (final range in ranges) {
          final parsed = _rawBorderRange(range);
          if (parsed != null) {
            final effectiveRange = clipRange == null
                ? parsed
                : _clipRange(parsed, clipRange);
            if (effectiveRange != null) {
              _applyRangeBorder(
                result,
                borderType,
                effectiveRange,
                side,
                hiddenRows: hiddenRows,
              );
            }
          }
        }
      } else if (rangeType == 'cell') {
        _applyRawCellBorder(result, item['value'], hiddenRows: hiddenRows);
      }
    }
  }

  static FortuneRange? _clipRange(FortuneRange range, FortuneRange clipRange) {
    final rowStart = range.rowStart < clipRange.rowStart
        ? clipRange.rowStart
        : range.rowStart;
    final rowEnd = range.rowEnd > clipRange.rowEnd
        ? clipRange.rowEnd
        : range.rowEnd;
    final columnStart = range.columnStart < clipRange.columnStart
        ? clipRange.columnStart
        : range.columnStart;
    final columnEnd = range.columnEnd > clipRange.columnEnd
        ? clipRange.columnEnd
        : range.columnEnd;
    if (rowStart > rowEnd || columnStart > columnEnd) {
      return null;
    }
    return FortuneRange(
      rowStart: rowStart,
      rowEnd: rowEnd,
      columnStart: columnStart,
      columnEnd: columnEnd,
      rowFocus: range.rowFocus,
      columnFocus: range.columnFocus,
    );
  }

  static void _removeOutOfRange(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    FortuneRange range,
  ) {
    result.removeWhere((coord, _) {
      return coord.row < range.rowStart ||
          coord.row > range.rowEnd ||
          coord.column < range.columnStart ||
          coord.column > range.columnEnd;
    });
  }

  static void _removeHiddenRows(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    Set<int> hiddenRows,
  ) {
    if (hiddenRows.isEmpty) {
      return;
    }
    result.removeWhere((coord, _) => hiddenRows.contains(coord.row));
  }

  static void _removeMergeInnerBorders(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    FortuneSheet sheet,
  ) {
    for (final entry in sheet.cells.entries) {
      final merge = entry.value.merge;
      if (merge == null ||
          entry.key.row != merge.row ||
          entry.key.column != merge.column ||
          (merge.rowSpan <= 1 && merge.columnSpan <= 1)) {
        continue;
      }
      final rowEnd = merge.row + merge.rowSpan - 1;
      final columnEnd = merge.column + merge.columnSpan - 1;
      for (var row = merge.row; row <= rowEnd; row += 1) {
        for (var column = merge.column; column <= columnEnd; column += 1) {
          final coord = FortuneCellCoord(row, column);
          final borders = result[coord];
          if (borders == null) {
            continue;
          }
          result[coord] = FortuneCellBorders(
            top: row > merge.row ? null : borders.top,
            right: column < columnEnd ? null : borders.right,
            bottom: row < rowEnd ? null : borders.bottom,
            left: column > merge.column ? null : borders.left,
            slash: borders.slash,
          );
        }
      }
    }
  }

  static void _applyRangeBorder(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    String borderType,
    FortuneRange range,
    FortuneBorderSide side, {
    Set<int> hiddenRows = const {},
  }) {
    switch (borderType) {
      case 'border-none':
        _clearRange(result, range, hiddenRows: hiddenRows);
        break;
      case 'border-top':
        if (hiddenRows.contains(range.rowStart)) {
          break;
        }
        for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
          _set(result, range.rowStart, c, top: side);
        }
        break;
      case 'border-bottom':
        if (hiddenRows.contains(range.rowEnd)) {
          break;
        }
        for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
          _set(result, range.rowEnd, c, bottom: side);
        }
        break;
      case 'border-left':
        for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
          if (hiddenRows.contains(r)) {
            continue;
          }
          _set(result, r, range.columnStart, left: side);
        }
        break;
      case 'border-right':
        for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
          if (hiddenRows.contains(r)) {
            continue;
          }
          _set(result, r, range.columnEnd, right: side);
        }
        break;
      case 'border-outside':
        _outside(result, range, side, hiddenRows: hiddenRows);
        break;
      case 'border-inside':
        _inside(result, range, side, hiddenRows: hiddenRows);
        break;
      case 'border-horizontal':
        for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
          if (hiddenRows.contains(r)) {
            continue;
          }
          for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
            if (r > range.rowStart) {
              _set(result, r, c, top: side);
            }
            if (r < range.rowEnd) {
              _set(result, r, c, bottom: side);
            }
          }
        }
        break;
      case 'border-vertical':
        for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
          if (hiddenRows.contains(r)) {
            continue;
          }
          for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
            if (c > range.columnStart) {
              _set(result, r, c, left: side);
            }
            if (c < range.columnEnd) {
              _set(result, r, c, right: side);
            }
          }
        }
        break;
      case 'border-slash':
        if (hiddenRows.contains(range.rowFocus ?? range.rowStart)) {
          break;
        }
        _set(
          result,
          range.rowFocus ?? range.rowStart,
          range.columnFocus ?? range.columnStart,
          slash: side,
        );
        break;
      case 'border-all':
      default:
        for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
          if (hiddenRows.contains(r)) {
            continue;
          }
          for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
            _set(
              result,
              r,
              c,
              top: side,
              right: side,
              bottom: side,
              left: side,
            );
          }
        }
    }
  }

  static void _applyRawCellBorder(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    Object? rawValue, {
    Set<int> hiddenRows = const {},
  }) {
    if (rawValue is! Map) {
      return;
    }
    final row = _rawBorderInt(rawValue['row_index']);
    final column = _rawBorderInt(rawValue['col_index']);
    if (row == null || column == null) {
      return;
    }
    if (hiddenRows.contains(row)) {
      return;
    }
    final coord = FortuneCellCoord(row, column);
    if (rawValue['l'] == null &&
        rawValue['r'] == null &&
        rawValue['t'] == null &&
        rawValue['b'] == null) {
      result.remove(coord);
      return;
    }
    final current = result[coord] ?? const FortuneCellBorders();
    final left = rawValue.containsKey('l')
        ? _rawCellBorderSide(rawValue['l'])
        : current.left;
    final right = rawValue.containsKey('r')
        ? _rawCellBorderSide(rawValue['r'])
        : current.right;
    final top = rawValue.containsKey('t')
        ? _rawCellBorderSide(rawValue['t'])
        : current.top;
    final bottom = rawValue.containsKey('b')
        ? _rawCellBorderSide(rawValue['b'])
        : current.bottom;
    result[coord] = current.copyWith(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
    if (left != null) {
      _setExisting(result, row, column - 1, right: left);
    }
    if (right != null) {
      _setExisting(result, row, column + 1, left: right);
    }
    if (top != null) {
      _setExisting(result, row - 1, column, bottom: top);
    }
    if (bottom != null) {
      _setExisting(result, row + 1, column, top: bottom);
    }
  }

  static FortuneRange? _rawBorderRange(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final row = _rawBorderAxis(raw['row']);
    final column = _rawBorderAxis(raw['column']);
    if (row == null || column == null) {
      return null;
    }
    return FortuneRange(
      rowStart: row[0],
      rowEnd: row[1],
      columnStart: column[0],
      columnEnd: column[1],
    );
  }

  static List<int>? _rawBorderAxis(Object? raw) {
    if (raw is! List || raw.length < 2) {
      return null;
    }
    final start = _rawBorderInt(raw[0]);
    final end = _rawBorderInt(raw[1]);
    if (start == null || end == null) {
      return null;
    }
    return [start, end];
  }

  static FortuneBorderSide? _rawCellBorderSide(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return FortuneBorderSide(
      color: _rawBorderColor(raw['color']) ?? const Color(0xff000000),
      style: _rawBorderInt(raw['style']) ?? 1,
      strokeWidth: _rawBorderDouble(raw['strokeWidth']),
    );
  }

  static double? _rawBorderDouble(Object? raw) {
    if (raw is num && raw.isFinite) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw.trim());
    }
    return null;
  }

  static int? _rawBorderInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num && raw.isFinite) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  static Color? _rawBorderColor(Object? raw) {
    if (raw is Color) {
      return raw;
    }
    if (raw is! String) {
      return null;
    }
    var value = raw.trim();
    if (value.startsWith('#')) {
      value = value.substring(1);
    }
    if (value.length == 3) {
      value = value.split('').map((part) => '$part$part').join();
    }
    if (value.length == 6) {
      value = 'ff$value';
    }
    if (value.length != 8) {
      return null;
    }
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  static void _outside(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    FortuneRange range,
    FortuneBorderSide side, {
    Set<int> hiddenRows = const {},
  }) {
    for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
      if (!hiddenRows.contains(range.rowStart)) {
        _set(result, range.rowStart, c, top: side);
      }
      if (!hiddenRows.contains(range.rowEnd)) {
        _set(result, range.rowEnd, c, bottom: side);
      }
    }
    for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
      if (hiddenRows.contains(r)) {
        continue;
      }
      _set(result, r, range.columnStart, left: side);
      _set(result, r, range.columnEnd, right: side);
    }
  }

  static void _inside(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    FortuneRange range,
    FortuneBorderSide side, {
    Set<int> hiddenRows = const {},
  }) {
    for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
      if (hiddenRows.contains(r)) {
        continue;
      }
      for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
        if (r > range.rowStart) {
          _set(result, r, c, top: side);
        }
        if (r < range.rowEnd) {
          _set(result, r, c, bottom: side);
        }
        if (c > range.columnStart) {
          _set(result, r, c, left: side);
        }
        if (c < range.columnEnd) {
          _set(result, r, c, right: side);
        }
      }
    }
  }

  static void _clearRange(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    FortuneRange range, {
    Set<int> hiddenRows = const {},
  }) {
    for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
      if (hiddenRows.contains(r)) {
        continue;
      }
      for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
        result.remove(FortuneCellCoord(r, c));
        if (r == range.rowStart) {
          _clearExistingSide(result, r - 1, c, bottom: true);
        }
        if (r == range.rowEnd) {
          _clearExistingSide(result, r + 1, c, top: true);
        }
        if (c == range.columnStart) {
          _clearExistingSide(result, r, c - 1, right: true);
        }
        if (c == range.columnEnd) {
          _clearExistingSide(result, r, c + 1, left: true);
        }
      }
    }
  }

  static void _clearExistingSide(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    int row,
    int column, {
    bool top = false,
    bool right = false,
    bool bottom = false,
    bool left = false,
  }) {
    final coord = FortuneCellCoord(row, column);
    final current = result[coord];
    if (current == null) {
      return;
    }
    final next = current.copyWith(
      top: top ? null : current.top,
      right: right ? null : current.right,
      bottom: bottom ? null : current.bottom,
      left: left ? null : current.left,
    );
    if (next.isEmpty) {
      result.remove(coord);
    } else {
      result[coord] = next;
    }
  }

  static void _set(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    int row,
    int column, {
    FortuneBorderSide? top,
    FortuneBorderSide? right,
    FortuneBorderSide? bottom,
    FortuneBorderSide? left,
    FortuneBorderSide? slash,
  }) {
    final coord = FortuneCellCoord(row, column);
    final current = result[coord] ?? const FortuneCellBorders();
    result[coord] = current.copyWith(
      top: top ?? current.top,
      right: right ?? current.right,
      bottom: bottom ?? current.bottom,
      left: left ?? current.left,
      slash: slash ?? current.slash,
    );
    if (top != null) {
      _setExisting(result, row - 1, column, bottom: top);
    }
    if (right != null) {
      _setExisting(result, row, column + 1, left: right);
    }
    if (bottom != null) {
      _setExisting(result, row + 1, column, top: bottom);
    }
    if (left != null) {
      _setExisting(result, row, column - 1, right: left);
    }
  }

  static void _setExisting(
    Map<FortuneCellCoord, FortuneCellBorders> result,
    int row,
    int column, {
    FortuneBorderSide? top,
    FortuneBorderSide? right,
    FortuneBorderSide? bottom,
    FortuneBorderSide? left,
  }) {
    final coord = FortuneCellCoord(row, column);
    final current = result[coord];
    if (current == null) {
      return;
    }
    result[coord] = current.copyWith(
      top: top ?? current.top,
      right: right ?? current.right,
      bottom: bottom ?? current.bottom,
      left: left ?? current.left,
    );
  }
}

Map<FortuneCellCoord, FortuneCellBorders> getBorderInfoCompute(
  FortuneSheet sheet,
) {
  return FortuneBorderCompute.compute(sheet);
}

Map<FortuneCellCoord, FortuneCellBorders> getBorderInfoComputeRange(
  FortuneSheet sheet,
  int datasetRowStart,
  int datasetRowEnd,
  int datasetColumnStart,
  int datasetColumnEnd,
) {
  return FortuneBorderCompute.computeRange(
    sheet,
    FortuneRange(
      rowStart: datasetRowStart,
      rowEnd: datasetRowEnd,
      columnStart: datasetColumnStart,
      columnEnd: datasetColumnEnd,
    ),
  );
}
