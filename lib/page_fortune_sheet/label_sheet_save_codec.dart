import 'dart:convert';

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