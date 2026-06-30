import 'dart:convert';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

const String labelSheetSaveFormat = 'label-manager.sheet';
final int labelSheetSaveFormatVersion = _labelSheetSaveFeatureKeys.length;
final Map<String, int> labelSheetSaveFeatureVersions = Map.unmodifiable({
  for (var i = 0; i < _labelSheetSaveFeatureKeys.length; i += 1)
    _labelSheetSaveFeatureKeys[i]: i + 1,
});

const List<String> _labelSheetSaveFeatureKeys = [
  'workbook.core',
  'workbook.settings',
  'sheet.core',
  'sheet.config.dimensions',
  'sheet.config.merge',
  'sheet.config.border',
  'sheet.config.protection',
  'sheet.cells',
  'cell.value',
  'cell.format.base',
  'cell.format.style',
  'cell.inlineRuns',
  'cell.linksAndNotes',
  'sheet.images',
  'sheet.validationFilter',
  'sheet.formulaMetadata',
  'sheet.frozen',
  'sheet.labelMetadata',
];

const Set<String> _supportedWorkbookKeys = {
  'data',
  'column',
  'row',
  'addRows',
  'showToolbar',
  'showFormulaBar',
  'showSheetTabs',
  'config',
  'devicePixelRatio',
  'allowEdit',
  'lang',
  'currency',
  'forceCalculation',
  'rowHeaderWidth',
  'columnHeaderHeight',
  'defaultColWidth',
  'defaultRowHeight',
  'defaultFontSize',
  'fontFamilies',
  'toolbarItems',
  'customToolbarItems',
  'cellContextMenu',
  'headerContextMenu',
  'sheetTabContextMenu',
  'filterContextMenu',
};

const Set<String> _supportedSheetKeys = {
  'name',
  'config',
  'order',
  'color',
  'data',
  'celldata',
  'id',
  'images',
  'image',
  'zoomRatio',
  'column',
  'row',
  'addRows',
  'status',
  'hide',
  'luckysheet_select_save',
  'luckysheet_selection_range',
  'calcChain',
  'defaultRowHeight',
  'defaultColWidth',
  'showGridLines',
  'visibledatarow',
  'visibledatacolumn',
  'ch_width',
  'rh_height',
  'pivotTable',
  'isPivotTable',
  'filter',
  'filter_select',
  'luckysheet_conditionformat_save',
  'luckysheet_alternateformat_save',
  'luckysheet_alternateformat_save_modelCustom',
  'dataVerification',
  'hyperlink',
  'dynamicArray_compute',
  'dynamicArray',
  'frozen',
  fortuneSheetGridClientWidthMmKey,
  fortuneSheetGridClientHeightMmKey,
  fortuneSheetRulerVisibleKey,
  fortuneSheetRulerGuidesKey,
  'labelRtfImportSource',
};

const Set<String> _supportedSheetConfigKeys = {
  'merge',
  'rowlen',
  'columnlen',
  'rowhidden',
  'colhidden',
  'customHeight',
  'customWidth',
  'borderInfo',
  'authority',
  'rowReadOnly',
  'colReadOnly',
};

const Set<String> _supportedCellKeys = {
  'v',
  'm',
  'mc',
  'f',
  'ct',
  'qp',
  'spl',
  'bg',
  'lo',
  'rt',
  'ps',
  'hl',
  'bl',
  'it',
  'ff',
  'fs',
  'fc',
  'ht',
  'vt',
  'tb',
  'cl',
  'un',
  'tr',
  'fontScale',
  'letterSpacing',
  'lineHeight',
  'script',
  'rtfHidden',
  'rtfSmallCaps',
  'rtfAllCaps',
  'rtfUnderlineStyle',
  'rtfShadow',
};

const Set<String> _supportedMergeKeys = {'r', 'c', 'rs', 'cs'};
const Set<String> _supportedCellTypeKeys = {'fa', 't', 's'};
const Set<String> _supportedInlineRunKeys = {
  'v',
  'fc',
  'bl',
  'it',
  'cl',
  'un',
  'fs',
  'ff',
  'wrap',
  'bg',
  'script',
  'fontScale',
  'letterSpacing',
  'lineHeight',
  'rtfHidden',
  'rtfSmallCaps',
  'rtfAllCaps',
  'rtfUnderlineStyle',
  'rtfShadow',
};

String labelSheetEncodeWorkbookSave(FortuneWorkbook workbook) {
  final manifest = <String, Object?>{
    'format': labelSheetSaveFormat,
    'version': labelSheetSaveFormatVersion,
    'features': labelSheetSaveFeatureVersions,
    'encoding': 'base64',
    'compression': 'zip-deflate',
    'codec': 'fortune-sheet-json',
  };
  final workbookJson = labelSheetSanitizeWorkbookSaveJson(
    FortuneSheetCodec.workbookToJson(workbook),
  );
  final archive = Archive()
    ..addFile(
      ArchiveFile.string('manifest.json', jsonEncode(manifest)),
    )
    ..addFile(
      ArchiveFile.string(
        'workbook.json',
        jsonEncode(workbookJson),
      ),
    );
  return base64Encode(ZipEncoder().encodeBytes(archive));
}

FortuneWorkbook labelSheetWorkbookForPrintAreaSave(FortuneWorkbook workbook) {
  final nextSheets = [
    for (final sheet in workbook.sheets) _sheetForPrintAreaSave(sheet),
  ];
  return workbook.copyWith(sheets: nextSheets);
}

FortuneSheet _sheetForPrintAreaSave(FortuneSheet sheet) {
  final physicalSize = fortuneSheetGridClientPhysicalSize(sheet);
  if (physicalSize == null) {
    return sheet.copyWith();
  }
  final logicalSize = physicalSize.logicalSize;
  final printBounds = _LabelSheetSaveBounds(
    maxRow: _lastVisibleIndexForExtent(
      logicalSize.height,
      lengthForIndex: (row) => _rowHeight(sheet, row),
    ),
    maxColumn: _lastVisibleIndexForExtent(
      logicalSize.width,
      lengthForIndex: (column) => _columnWidth(sheet, column),
    ),
  );
  var bounds = printBounds;
  bounds = _expandBoundsForCells(sheet, printBounds, bounds);
  bounds = _expandBoundsForBorders(sheet, printBounds, bounds);
  bounds = _expandBoundsForImages(sheet, printBounds, bounds);
  return sheet.copyWith(
    rowCount: bounds.maxRow + 1,
    columnCount: bounds.maxColumn + 1,
    cells: {
      for (final entry in sheet.cells.entries)
        if (bounds.contains(entry.key)) entry.key: entry.value.copyWith(),
    },
    nullCells: {
      for (final coord in sheet.nullCells)
        if (bounds.contains(coord)) coord,
    },
    rowHeights: _intDoubleMapWithin(sheet.rowHeights, bounds.maxRow),
    columnWidths: _intDoubleMapWithin(sheet.columnWidths, bounds.maxColumn),
    customHeight: _intDoubleMapWithin(sheet.customHeight, bounds.maxRow),
    customWidth: _intDoubleMapWithin(sheet.customWidth, bounds.maxColumn),
    hiddenRows: sheet.hiddenRows.where((row) => row <= bounds.maxRow).toSet(),
    hiddenColumns: sheet.hiddenColumns
        .where((column) => column <= bounds.maxColumn)
        .toSet(),
    hiddenRowValues: _intObjectMapWithin(sheet.hiddenRowValues, bounds.maxRow),
    hiddenColumnValues: _intObjectMapWithin(
      sheet.hiddenColumnValues,
      bounds.maxColumn,
    ),
    borderInfo: [
      for (final border in sheet.borderInfo)
        if (_borderIntersectsBounds(border, bounds)) border.copyWith(),
    ],
    images: [
      for (final image in sheet.images)
        if (_imageIntersectsBounds(sheet, image, bounds)) image.copyWith(),
    ],
    dataVerification: _coordKeyMapWithin(sheet.dataVerification, bounds),
    filter: _coordKeyMapWithin(sheet.filter, bounds),
    hyperlinks: _coordKeyMapWithin(sheet.hyperlinks, bounds),
  );
}

_LabelSheetSaveBounds _expandBoundsForCells(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final entry in sheet.cells.entries) {
    final coord = entry.key;
    final cell = entry.value;
    if (!printBounds.contains(coord)) {
      continue;
    }
    final merge = cell.merge;
    if (merge != null) {
      next = next.expandTo(
        row: merge.row + merge.rowSpan - 1,
        column: merge.column + merge.columnSpan - 1,
      );
    }
    if (cell.renderedText.isEmpty) {
      continue;
    }
    final textExtent = _estimatedCellTextExtent(sheet, coord, cell);
    next = next.expandTo(row: textExtent.maxRow, column: textExtent.maxColumn);
  }
  return next;
}

_LabelSheetSaveBounds _expandBoundsForBorders(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final border in sheet.borderInfo) {
    for (final range in border.ranges) {
      if (!_rangeIntersectsBounds(range, printBounds)) {
        continue;
      }
      next = next.expandTo(row: range.rowEnd, column: range.columnEnd);
    }
  }
  return next;
}

_LabelSheetSaveBounds _expandBoundsForImages(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final image in sheet.images) {
    if (!_imageIntersectsBounds(sheet, image, printBounds)) {
      continue;
    }
    next = next.expandTo(
      row: _lastIndexForPosition(
        image.top + image.height,
        lengthForIndex: (row) => _rowHeight(sheet, row),
      ),
      column: _lastIndexForPosition(
        image.left + image.width,
        lengthForIndex: (column) => _columnWidth(sheet, column),
      ),
    );
  }
  return next;
}

_LabelSheetSaveBounds _estimatedCellTextExtent(
  FortuneSheet sheet,
  FortuneCellCoord coord,
  FortuneCell cell,
) {
  final merge = cell.merge;
  final startRow = merge?.row ?? coord.row;
  final startColumn = merge?.column ?? coord.column;
  final rowSpan = math.max<int>(1, merge?.rowSpan ?? 1);
  final columnSpan = math.max<int>(1, merge?.columnSpan ?? 1);
  final lines = cell.renderedText.split('\n');
  final fontSize = cell.fontSize ?? 10;
  final fontScale = _numberFrom(cell.extraFields['fontScale']) ?? 100;
  final letterSpacing = _numberFrom(cell.extraFields['letterSpacing']) ?? 0;
  final lineHeight = _numberFrom(cell.extraFields['lineHeight']) ?? 1.2;
  final longestLine = lines.fold<int>(0, (longest, line) {
    return math.max(longest, line.runes.length);
  });
  final estimatedTextWidth = longestLine * (fontSize * 0.56 + letterSpacing) *
      fontScale /
      100;
  final estimatedTextHeight = lines.length * fontSize * lineHeight;
  final availableWidth = _spanLength(
    startColumn,
    columnSpan,
    lengthForIndex: (column) => _columnWidth(sheet, column),
  );
  final availableHeight = _spanLength(
    startRow,
    rowSpan,
    lengthForIndex: (row) => _rowHeight(sheet, row),
  );
  return _LabelSheetSaveBounds(
    maxRow: startRow +
        math.max<int>(
          rowSpan,
          (estimatedTextHeight / math.max(availableHeight, 1)).ceil() * rowSpan,
        ) -
        1,
    maxColumn: startColumn +
        math.max<int>(
          columnSpan,
          (estimatedTextWidth / math.max(availableWidth, 1)).ceil() *
              columnSpan,
        ) -
        1,
  );
}

bool _imageIntersectsBounds(
  FortuneSheet sheet,
  FortuneImage image,
  _LabelSheetSaveBounds bounds,
) {
  final boundsRight = _spanLength(
    0,
    bounds.maxColumn + 1,
    lengthForIndex: (column) => _columnWidth(sheet, column),
  );
  final boundsBottom = _spanLength(
    0,
    bounds.maxRow + 1,
    lengthForIndex: (row) => _rowHeight(sheet, row),
  );
  return image.left < boundsRight &&
      image.left + image.width > 0 &&
      image.top < boundsBottom &&
      image.top + image.height > 0;
}

bool _borderIntersectsBounds(
  FortuneBorderInfo border,
  _LabelSheetSaveBounds bounds,
) {
  return border.ranges.any((range) => _rangeIntersectsBounds(range, bounds));
}

bool _rangeIntersectsBounds(FortuneRange range, _LabelSheetSaveBounds bounds) {
  return range.rowStart <= bounds.maxRow &&
      range.rowEnd >= 0 &&
      range.columnStart <= bounds.maxColumn &&
      range.columnEnd >= 0;
}

int _lastVisibleIndexForExtent(
  double extent, {
  required double Function(int index) lengthForIndex,
}) {
  return _lastIndexForPosition(extent, lengthForIndex: lengthForIndex);
}

int _lastIndexForPosition(
  double position, {
  required double Function(int index) lengthForIndex,
}) {
  if (position <= 0) {
    return 0;
  }
  var offset = 0.0;
  var index = 0;
  while (offset < position) {
    offset += lengthForIndex(index);
    if (offset >= position) {
      return index;
    }
    index += 1;
  }
  return index;
}

double _spanLength(
  int start,
  int count, {
  required double Function(int index) lengthForIndex,
}) {
  var total = 0.0;
  for (var index = start; index < start + count; index += 1) {
    total += lengthForIndex(index);
  }
  return total;
}

double _rowHeight(FortuneSheet sheet, int row) {
  return sheet.rowHeights[row] ?? sheet.defaultRowHeight ?? 19;
}

double _columnWidth(FortuneSheet sheet, int column) {
  return sheet.columnWidths[column] ?? sheet.defaultColWidth ?? 73;
}

double? _numberFrom(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

Map<int, double> _intDoubleMapWithin(Map<int, double> source, int maxIndex) {
  return {
    for (final entry in source.entries)
      if (entry.key <= maxIndex) entry.key: entry.value,
  };
}

Map<int, Object?> _intObjectMapWithin(Map<int, Object?> source, int maxIndex) {
  return {
    for (final entry in source.entries)
      if (entry.key <= maxIndex) entry.key: cloneFortuneMetadata(entry.value),
  };
}

Map<String, Object?> _coordKeyMapWithin(
  Map<String, Object?> source,
  _LabelSheetSaveBounds bounds,
) {
  return {
    for (final entry in source.entries)
      if (_coordKeyWithinBounds(entry.key, bounds))
        entry.key: cloneFortuneMetadata(entry.value),
  };
}

bool _coordKeyWithinBounds(String key, _LabelSheetSaveBounds bounds) {
  final parts = key.split('_');
  if (parts.length != 2) {
    return false;
  }
  final row = int.tryParse(parts[0]);
  final column = int.tryParse(parts[1]);
  if (row == null || column == null) {
    return false;
  }
  return row <= bounds.maxRow && column <= bounds.maxColumn;
}

class _LabelSheetSaveBounds {
  const _LabelSheetSaveBounds({required this.maxRow, required this.maxColumn});

  final int maxRow;
  final int maxColumn;

  bool contains(FortuneCellCoord coord) {
    return coord.row <= maxRow && coord.column <= maxColumn;
  }

  _LabelSheetSaveBounds expandTo({required int row, required int column}) {
    return _LabelSheetSaveBounds(
      maxRow: math.max(maxRow, row),
      maxColumn: math.max(maxColumn, column),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _LabelSheetSaveBounds &&
        other.maxRow == maxRow &&
        other.maxColumn == maxColumn;
  }

  @override
  int get hashCode => Object.hash(maxRow, maxColumn);
}

FortuneWorkbook labelSheetDecodeWorkbookSave(String encoded) {
  final archive = ZipDecoder().decodeBytes(base64Decode(encoded.trim()));
  final manifestFile = _archiveFile(archive, 'manifest.json');
  final workbookFile = _archiveFile(archive, 'workbook.json');
  if (manifestFile == null || workbookFile == null) {
    throw const FormatException('Missing label sheet save entries');
  }
  final manifestBytes = manifestFile.readBytes();
  final workbookBytes = workbookFile.readBytes();
  if (manifestBytes == null || workbookBytes == null) {
    throw const FormatException('Unreadable label sheet save entries');
  }
  final manifest = jsonDecode(utf8.decode(manifestBytes));
  if (manifest is! Map ||
      manifest['format'] != labelSheetSaveFormat ||
      manifest['codec'] != 'fortune-sheet-json') {
    throw const FormatException('Unsupported label sheet save format');
  }
  final workbookJson = jsonDecode(utf8.decode(workbookBytes));
  if (workbookJson is! Map) {
    throw const FormatException('Invalid label sheet workbook payload');
  }
  return FortuneSheetCodec.workbookFromJson(
    labelSheetSanitizeWorkbookSaveJson(Map<String, Object?>.from(workbookJson)),
  );
}

FortuneWorkbook? labelSheetTryDecodeWorkbookSave(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) {
    return null;
  }
  try {
    return labelSheetDecodeWorkbookSave(encoded);
  } catch (_) {
    return null;
  }
}

ArchiveFile? _archiveFile(Archive archive, String name) {
  for (final file in archive.files) {
    if (file.name == name && file.isFile) {
      return file;
    }
  }
  return null;
}

Map<String, Object?> labelSheetSanitizeWorkbookSaveJson(
  Map<String, Object?> json,
) {
  return _sanitizeMap(json, _supportedWorkbookKeys, valueSanitizer: (
    key,
    value,
  ) {
    if (key == 'data' && value is List) {
      return [
        for (final item in value)
          if (item is Map)
            _sanitizeSheetJson(Map<String, Object?>.from(item)),
      ];
    }
    return _cloneSupportedSaveValue(value);
  });
}

Map<String, Object?> _sanitizeSheetJson(Map<String, Object?> json) {
  return _sanitizeMap(json, _supportedSheetKeys, valueSanitizer: (key, value) {
    return switch (key) {
      'config' when value is Map =>
        _sanitizeSheetConfigJson(Map<String, Object?>.from(value)),
      'celldata' when value is List => _sanitizeCelldata(value),
      'data' when value is List => _sanitizeMatrixData(value),
      _ => _cloneSupportedSaveValue(value),
    };
  });
}

Map<String, Object?> _sanitizeSheetConfigJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedSheetConfigKeys,
    valueSanitizer: (_, value) => _cloneSupportedSaveValue(value),
  );
}

List<Object?> _sanitizeCelldata(List<Object?> raw) {
  return [
    for (final item in raw)
      if (item is Map)
        {
          for (final entry in item.entries)
            if (entry.key == 'r' || entry.key == 'c')
              '${entry.key}': _cloneSupportedSaveValue(entry.value)
            else if (entry.key == 'v')
              'v': entry.value is Map
                  ? _sanitizeCellJson(Map<String, Object?>.from(entry.value as Map))
                  : _cloneSupportedSaveValue(entry.value),
        },
  ];
}

List<Object?> _sanitizeMatrixData(List<Object?> raw) {
  return [
    for (final row in raw)
      if (row is List)
        [
          for (final cell in row)
            cell is Map
                ? _sanitizeCellJson(Map<String, Object?>.from(cell))
                : _cloneSupportedSaveValue(cell),
        ]
      else
        _cloneSupportedSaveValue(row),
  ];
}

Map<String, Object?> _sanitizeCellJson(Map<String, Object?> json) {
  return _sanitizeMap(json, _supportedCellKeys, valueSanitizer: (key, value) {
    return switch (key) {
      'mc' when value is Map => _sanitizeMap(
        Map<String, Object?>.from(value),
        _supportedMergeKeys,
      ),
      'ct' when value is Map => _sanitizeCellTypeJson(
        Map<String, Object?>.from(value),
      ),
      _ => _cloneSupportedSaveValue(value),
    };
  });
}

Map<String, Object?> _sanitizeCellTypeJson(Map<String, Object?> json) {
  return _sanitizeMap(json, _supportedCellTypeKeys, valueSanitizer: (key, value) {
    if (key == 's' && value is List) {
      return [
        for (final item in value)
          if (item is Map)
            _sanitizeInlineRunJson(Map<String, Object?>.from(item)),
      ];
    }
    return _cloneSupportedSaveValue(value);
  });
}

Map<String, Object?> _sanitizeInlineRunJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedInlineRunKeys,
    valueSanitizer: (_, value) => _cloneSupportedSaveValue(value),
  );
}

Map<String, Object?> _sanitizeMap(
  Map<String, Object?> json,
  Set<String> supportedKeys, {
  Object? Function(String key, Object? value)? valueSanitizer,
}) {
  return {
    for (final entry in json.entries)
      if (supportedKeys.contains(entry.key))
        entry.key:
            valueSanitizer?.call(entry.key, entry.value) ??
            _cloneSupportedSaveValue(entry.value),
  };
}

Object? _cloneSupportedSaveValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        '${entry.key}': _cloneSupportedSaveValue(entry.value),
    };
  }
  if (value is List) {
    return [for (final item in value) _cloneSupportedSaveValue(item)];
  }
  return value;
}