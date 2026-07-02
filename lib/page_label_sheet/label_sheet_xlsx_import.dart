// ignore_for_file: use_null_aware_elements

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:path/path.dart' as p;

FortuneWorkbook labelSheetWorkbookFromXlsxBytes(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final workbookXml = _xlsxText(archive, 'xl/workbook.xml');
  final workbookRelsXml = _xlsxText(archive, 'xl/_rels/workbook.xml.rels');
  final sheetInfo = _activeSheetInfo(workbookXml);
  final sheetPath = _worksheetPath(workbookRelsXml, sheetInfo.relationshipId);
  final sheetXml = _xlsxText(archive, sheetPath);
  final sheetRels = _worksheetRelationships(archive, sheetPath);
  final styles = _XlsxStyleTable.fromArchive(archive);
  final sharedStrings = _XlsxSharedStrings.fromArchive(archive);
  final metadata = _XlsxExtensionMetadata.fromArchive(archive);
  final sheetJson = _sheetJsonFromWorksheet(
    sheetXml,
    sheetName: sheetInfo.name,
    sharedStrings: sharedStrings,
    styles: styles,
    relationships: sheetRels,
    metadata: metadata,
  );
  return FortuneSheetCodec.workbookFromJson({
    'data': [sheetJson],
  });
}

String _xlsxText(Archive archive, String path) {
  final normalizedPath = path.replaceAll('\\', '/');
  for (final file in archive.files) {
    if (!file.isFile || file.name.replaceAll('\\', '/') != normalizedPath) {
      continue;
    }
    final bytes = file.readBytes();
    if (bytes == null) {
      break;
    }
    return utf8.decode(bytes);
  }
  throw FormatException('Missing XLSX entry: $normalizedPath');
}

String? _tryXlsxText(Archive archive, String path) {
  try {
    return _xlsxText(archive, path);
  } on FormatException {
    return null;
  }
}

({String name, String relationshipId}) _activeSheetInfo(String workbookXml) {
  final sheets = [
    for (final match in RegExp(
      r'<sheet\b([^>]*)/?>',
      caseSensitive: false,
    ).allMatches(workbookXml))
      _xmlAttributes(match.group(1) ?? ''),
  ];
  if (sheets.isEmpty) {
    throw const FormatException('XLSX workbook has no sheets');
  }
  final activeTab = int.tryParse(
    _firstTagAttributes(workbookXml, 'workbookView')?['activeTab'] ?? '',
  );
  final index = activeTab == null ? 0 : activeTab.clamp(0, sheets.length - 1);
  final sheet = sheets[index];
  final relationshipId = sheet['r:id'] ?? sheet['id'];
  if (relationshipId == null || relationshipId.isEmpty) {
    throw const FormatException('XLSX sheet relationship is missing');
  }
  final name = sheet['name']?.trim();
  return (
    name: name == null || name.isEmpty ? 'Sheet${index + 1}' : name,
    relationshipId: relationshipId,
  );
}

String _worksheetPath(String relationshipsXml, String relationshipId) {
  for (final relationship in _relationships(relationshipsXml)) {
    if (relationship.id != relationshipId) {
      continue;
    }
    return p.url.normalize(p.url.join('xl', relationship.target));
  }
  throw FormatException('XLSX worksheet relationship not found: $relationshipId');
}

Map<String, _XlsxRelationship> _worksheetRelationships(
  Archive archive,
  String sheetPath,
) {
  final dir = p.url.dirname(sheetPath);
  final fileName = p.url.basename(sheetPath);
  final relsPath = p.url.join(dir, '_rels', '$fileName.rels');
  final xml = _tryXlsxText(archive, relsPath);
  if (xml == null) {
    return const <String, _XlsxRelationship>{};
  }
  return {for (final relationship in _relationships(xml)) relationship.id: relationship};
}

Iterable<_XlsxRelationship> _relationships(String xml) sync* {
  for (final match in RegExp(
    r'<Relationship\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(xml)) {
    final attributes = _xmlAttributes(match.group(1) ?? '');
    final id = attributes['Id'];
    final target = attributes['Target'];
    if (id == null || id.isEmpty || target == null || target.isEmpty) {
      continue;
    }
    yield _XlsxRelationship(
      id: id,
      target: target,
      type: attributes['Type'],
      targetMode: attributes['TargetMode'],
    );
  }
}

Map<String, Object?> _sheetJsonFromWorksheet(
  String xml, {
  required String sheetName,
  required _XlsxSharedStrings sharedStrings,
  required _XlsxStyleTable styles,
  required Map<String, _XlsxRelationship> relationships,
  required _XlsxExtensionMetadata metadata,
}) {
  final cells = <Map<String, Object?>>[];
  final cellKeys = <String>{};
  final rowHeights = <String, Object?>{};
  final columnWidths = <String, Object?>{};
  final hiddenRows = <String, Object?>{};
  final hiddenColumns = <String, Object?>{};
  final borderInfo = <Map<String, Object?>>[];
  final hyperlinks = <String, Object?>{};
  final mergeMap = <String, Map<String, Object?>>{};
  var maxRow = 0;
  var maxColumn = 0;

  final dimension = _dimensionEnd(xml);
  if (dimension != null) {
    maxRow = _max(maxRow, dimension.row + 1);
    maxColumn = _max(maxColumn, dimension.column + 1);
  }

  for (final merge in _mergeRefs(xml)) {
    final start = _cellRefToCoord(merge.start);
    final end = _cellRefToCoord(merge.end);
    if (start == null || end == null) {
      continue;
    }
    final rowSpan = end.row - start.row + 1;
    final columnSpan = end.column - start.column + 1;
    if (rowSpan <= 1 && columnSpan <= 1) {
      continue;
    }
    mergeMap['${start.row}_${start.column}'] = {
      'r': start.row,
      'c': start.column,
      'rs': rowSpan,
      'cs': columnSpan,
    };
    maxRow = _max(maxRow, end.row + 1);
    maxColumn = _max(maxColumn, end.column + 1);
  }

  for (final column in _columnDefs(xml)) {
    for (var index = column.min; index <= column.max; index += 1) {
      final columnIndex = index - 1;
      if (column.width != null && column.width! > 0) {
        columnWidths['$columnIndex'] = (column.width! * 7).clamp(1.0, 4096.0);
      }
      if (column.hidden) {
        hiddenColumns['$columnIndex'] = 0;
      }
      maxColumn = _max(maxColumn, index);
    }
  }

  final hyperlinkByCell = _hyperlinks(xml, relationships);
  for (final entry in hyperlinkByCell.entries) {
    final coord = _cellRefToCoord(entry.key);
    if (coord == null) {
      continue;
    }
    hyperlinks['${coord.row}_${coord.column}'] = entry.value;
    maxRow = _max(maxRow, coord.row + 1);
    maxColumn = _max(maxColumn, coord.column + 1);
  }

  for (final rowMatch in RegExp(
    r'<row\b([^>]*)>(.*?)</row>|<row\b([^>]*)/>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml)) {
    final rowAttributes = _xmlAttributes(
      rowMatch.group(1) ?? rowMatch.group(3) ?? '',
    );
    final rowNumber = int.tryParse(rowAttributes['r'] ?? '') ?? 0;
    final rowIndex = rowNumber > 0 ? rowNumber - 1 : maxRow;
    final rowHeight = double.tryParse(rowAttributes['ht'] ?? '');
    if (rowHeight != null && rowHeight.isFinite && rowHeight > 0) {
      rowHeights['$rowIndex'] = rowHeight * 1.3333333333;
    }
    if (_xmlBool(rowAttributes['hidden'])) {
      hiddenRows['$rowIndex'] = 0;
    }
    maxRow = _max(maxRow, rowIndex + 1);

    final rowBody = rowMatch.group(2) ?? '';
    for (final cellMatch in RegExp(
      r'<c\b([^>]*)>(.*?)</c>|<c\b([^>]*)/>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(rowBody)) {
      final cellAttributes = _xmlAttributes(
        cellMatch.group(1) ?? cellMatch.group(3) ?? '',
      );
      final ref = cellAttributes['r'];
      final coord = ref == null ? null : _cellRefToCoord(ref);
      if (coord == null) {
        continue;
      }
      final style = styles.cellStyle(int.tryParse(cellAttributes['s'] ?? ''));
      final cellBody = cellMatch.group(2) ?? '';
      final cellValue = _cellValue(
        cellBody,
        cellAttributes,
        sharedStrings,
        style,
      );
      final merge = mergeMap['${coord.row}_${coord.column}'];
      final hyperlink = hyperlinks['${coord.row}_${coord.column}'];
      final cellJson = <String, Object?>{
        ...style.cellJson,
        ...metadata.cellExtra(ref),
        if (cellValue.text != null) 'v': cellValue.text,
        if (cellValue.text != null) 'm': cellValue.text,
        if (cellValue.formula != null) 'f': cellValue.formula,
        if (merge != null) 'mc': merge,
        if (hyperlink != null) 'hl': hyperlink,
      };
      final inlineRuns = metadata.applyRunExtra(ref, cellValue.inlineRuns);
      if (inlineRuns != null && inlineRuns.isNotEmpty) {
        cellJson['ct'] = {
          ...?cellJson['ct'] as Map<String, Object?>?,
          's': inlineRuns,
        };
      } else if (style.formatCode != null) {
        cellJson['ct'] = {
          ...?cellJson['ct'] as Map<String, Object?>?,
          'fa': style.formatCode,
        };
      }
      if (cellJson.isEmpty) {
        continue;
      }
      final key = '${coord.row}_${coord.column}';
      cellKeys.add(key);
      cells.add({'r': coord.row, 'c': coord.column, 'v': cellJson});
      for (final border in style.borderInfo(coord.row, coord.column)) {
        borderInfo.add(border);
      }
      maxRow = _max(maxRow, coord.row + 1);
      maxColumn = _max(maxColumn, coord.column + 1);
    }
  }

  for (final entry in mergeMap.entries) {
    if (cellKeys.contains(entry.key)) {
      continue;
    }
    final coord = _keyToCoord(entry.key);
    if (coord == null) {
      continue;
    }
    cells.add({'r': coord.row, 'c': coord.column, 'v': {'mc': entry.value}});
    cellKeys.add(entry.key);
  }

  for (final entry in hyperlinks.entries) {
    if (cellKeys.contains(entry.key)) {
      continue;
    }
    final coord = _keyToCoord(entry.key);
    if (coord == null) {
      continue;
    }
    cells.add({'r': coord.row, 'c': coord.column, 'v': {'hl': entry.value}});
    cellKeys.add(entry.key);
  }

  return {
    'name': sheetName,
    'id': 'sheet_01',
    'order': 0,
    'status': 1,
    'row': _max(maxRow, 1),
    'column': _max(maxColumn, 1),
    'celldata': cells,
    if (hyperlinks.isNotEmpty) 'hyperlink': hyperlinks,
    'config': {
      if (mergeMap.isNotEmpty) 'merge': mergeMap,
      if (rowHeights.isNotEmpty) 'rowlen': rowHeights,
      if (columnWidths.isNotEmpty) 'columnlen': columnWidths,
      if (hiddenRows.isNotEmpty) 'rowhidden': hiddenRows,
      if (hiddenColumns.isNotEmpty) 'colhidden': hiddenColumns,
      if (borderInfo.isNotEmpty) 'borderInfo': borderInfo,
    },
  };
}

_XlsxCellValue _cellValue(
  String cellBody,
  Map<String, String> attributes,
  _XlsxSharedStrings sharedStrings,
  _XlsxCellStyle style,
) {
  final type = attributes['t'];
  final formula = _formulaText(_tagText(cellBody, 'f'));
  if (type == 'inlineStr') {
    final inlineMatch = RegExp(
      r'<is\b[^>]*>(.*?)</is>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(cellBody);
    final textValue = _richTextValue(inlineMatch?.group(1) ?? cellBody, style);
    return textValue.copyWith(formula: formula);
  }
  final rawValue = _tagText(cellBody, 'v');
  if (type == 's') {
    final index = int.tryParse((rawValue ?? '').trim());
    final shared = index == null ? null : sharedStrings.value(index, style);
    return (shared ?? const _XlsxCellValue()).copyWith(formula: formula);
  }
  if (type == 'b') {
    return _XlsxCellValue(
      text: rawValue?.trim() == '1' ? 'TRUE' : 'FALSE',
      formula: formula,
    );
  }
  if (type == 'str' || type == 'e') {
    return _XlsxCellValue(text: _emptyToNull(rawValue), formula: formula);
  }
  if (rawValue != null) {
    return _XlsxCellValue(text: _emptyToNull(rawValue), formula: formula);
  }
  return _XlsxCellValue(
    text: formula == null ? null : '=$formula',
    formula: formula,
  );
}

String? _formulaText(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value.startsWith('=') ? value : '=$value';
}

Map<String, Object?> _hyperlinks(
  String xml,
  Map<String, _XlsxRelationship> relationships,
) {
  final result = <String, Object?>{};
  for (final match in RegExp(
    r'<hyperlink\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(xml)) {
    final attributes = _xmlAttributes(match.group(1) ?? '');
    final ref = attributes['ref'];
    if (ref == null || ref.isEmpty) {
      continue;
    }
    final relationship = relationships[attributes['r:id']];
    final location = attributes['location'];
    final display = attributes['display'];
    final address = relationship?.target ?? location;
    if (address == null || address.isEmpty) {
      continue;
    }
    result[ref] = {
      'linkType': relationship?.targetMode == 'External' ? 'url' : 'location',
      'linkAddress': address,
      if (display != null && display.isNotEmpty) 'display': display,
    };
  }
  return result;
}

class _XlsxSharedStrings {
  const _XlsxSharedStrings(this._values);

  final List<_XlsxSharedString> _values;

  static _XlsxSharedStrings fromArchive(Archive archive) {
    final xml = _tryXlsxText(archive, 'xl/sharedStrings.xml');
    if (xml == null) {
      return const _XlsxSharedStrings(<_XlsxSharedString>[]);
    }
    return _XlsxSharedStrings([
      for (final match in RegExp(
        r'<si\b[^>]*>(.*?)</si>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(xml))
        _XlsxSharedString(match.group(1) ?? ''),
    ]);
  }

  _XlsxCellValue? value(int index, _XlsxCellStyle baseStyle) {
    if (index < 0 || index >= _values.length) {
      return null;
    }
    return _values[index].value(baseStyle);
  }
}

class _XlsxSharedString {
  const _XlsxSharedString(this.xml);

  final String xml;

  _XlsxCellValue value(_XlsxCellStyle baseStyle) => _richTextValue(xml, baseStyle);
}

_XlsxCellValue _richTextValue(String xml, _XlsxCellStyle baseStyle) {
  final runMatches = RegExp(
    r'<r\b[^>]*>(.*?)</r>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml).toList();
  if (runMatches.isEmpty) {
    final text = _textFromPlainTextXml(xml);
    return _XlsxCellValue(text: _emptyToNull(text));
  }
  final runs = <Map<String, Object?>>[];
  final buffer = StringBuffer();
  for (final match in runMatches) {
    final runXml = match.group(1) ?? '';
    final text = _textFromPlainTextXml(runXml);
    if (text.isEmpty) {
      continue;
    }
    buffer.write(text);
    final properties = _extractElement(runXml, 'rPr');
    runs.add({
      'v': text,
      ...baseStyle.runJson,
      ..._runJson(properties),
    });
  }
  return _XlsxCellValue(
    text: _emptyToNull(buffer.toString()),
    inlineRuns: runs.isEmpty ? null : runs,
  );
}

Map<String, Object?> _runJson(String? properties) {
  if (properties == null || properties.isEmpty) {
    return const <String, Object?>{};
  }
  final color = _colorFromElement(properties, 'color');
  final vertAlign = _firstTagAttributes(properties, 'vertAlign')?['val'];
  final fontSize = double.tryParse(
    _firstTagAttributes(properties, 'sz')?['val'] ?? '',
  );
  final fontFamily = _firstTagAttributes(properties, 'rFont')?['val'];
  return {
    if (_hasFlag(properties, 'b')) 'bl': true,
    if (_hasFlag(properties, 'i')) 'it': true,
    if (_hasFlag(properties, 'strike')) 'cl': true,
    if (_hasFlag(properties, 'u')) 'un': true,
    if (color != null) 'fc': color,
    if (fontSize != null) 'fs': fontSize,
    if (fontFamily != null) 'ff': fontFamily,
    if (vertAlign == 'superscript' || vertAlign == 'subscript')
      'script': vertAlign,
  };
}

class _XlsxStyleTable {
  const _XlsxStyleTable({
    required this.formats,
    required this.fonts,
    required this.fills,
    required this.borders,
    required this.numberFormats,
  });

  final List<_XlsxCellFormat> formats;
  final List<_XlsxFont> fonts;
  final List<String?> fills;
  final List<_XlsxBorder> borders;
  final Map<int, String> numberFormats;

  static _XlsxStyleTable fromArchive(Archive archive) {
    final xml = _tryXlsxText(archive, 'xl/styles.xml');
    if (xml == null) {
      return const _XlsxStyleTable(
        formats: <_XlsxCellFormat>[_XlsxCellFormat()],
        fonts: <_XlsxFont>[_XlsxFont()],
        fills: <String?>[null, null],
        borders: <_XlsxBorder>[_XlsxBorder()],
        numberFormats: <int, String>{},
      );
    }
    final fonts = _fonts(xml);
    final fills = _fills(xml);
    final borders = _borders(xml);
    final numberFormats = _numberFormats(xml);
    final formats = _cellFormats(xml);
    return _XlsxStyleTable(
      formats: formats.isEmpty ? const <_XlsxCellFormat>[_XlsxCellFormat()] : formats,
      fonts: fonts.isEmpty ? const <_XlsxFont>[_XlsxFont()] : fonts,
      fills: fills.isEmpty ? const <String?>[null, null] : fills,
      borders: borders.isEmpty ? const <_XlsxBorder>[_XlsxBorder()] : borders,
      numberFormats: numberFormats,
    );
  }

  _XlsxCellStyle cellStyle(int? index) {
    final format = index == null || index < 0 || index >= formats.length
        ? const _XlsxCellFormat()
        : formats[index];
    final font = _itemAt(fonts, format.fontId) ?? const _XlsxFont();
    final fill = _itemAt(fills, format.fillId);
    final border = _itemAt(borders, format.borderId) ?? const _XlsxBorder();
    return _XlsxCellStyle(
      formatCode: numberFormats[format.numFmtId] ?? _builtinNumberFormats[format.numFmtId],
      font: font,
      background: fill,
      border: border,
      horizontalAlign: format.horizontalAlign,
      verticalAlign: format.verticalAlign,
      wrapText: format.wrapText,
      textRotation: format.textRotation,
      quotePrefix: format.quotePrefix,
    );
  }
}

class _XlsxCellStyle {
  const _XlsxCellStyle({
    this.formatCode,
    required this.font,
    required this.background,
    required this.border,
    this.horizontalAlign,
    this.verticalAlign,
    this.wrapText = false,
    this.textRotation,
    this.quotePrefix = false,
  });

  final String? formatCode;
  final _XlsxFont font;
  final String? background;
  final _XlsxBorder border;
  final String? horizontalAlign;
  final String? verticalAlign;
  final bool wrapText;
  final String? textRotation;
  final bool quotePrefix;

  Map<String, Object?> get cellJson {
    final script = font.script;
    return {
      ...runJson,
      if (background != null) 'bg': background,
      if (horizontalAlign != null) 'ht': horizontalAlign,
      if (verticalAlign != null)
        'vt': verticalAlign == 'center' ? 'middle' : verticalAlign,
      if (wrapText) 'tb': 'wrap',
      if (textRotation != null) 'rt': textRotation,
      if (quotePrefix) 'qp': true,
      if (script != null) 'script': script,
    };
  }

  Map<String, Object?> get runJson {
    return {
      if (font.bold) 'bl': true,
      if (font.italic) 'it': true,
      if (font.strikeThrough) 'cl': true,
      if (font.underline) 'un': true,
      if (font.foreground != null) 'fc': font.foreground,
      if (font.fontSize != null) 'fs': font.fontSize,
      if (font.fontFamily != null) 'ff': font.fontFamily,
      if (font.script != null) 'script': font.script,
    };
  }

  List<Map<String, Object?>> borderInfo(int row, int column) {
    return [
      for (final side in border.sides.entries)
        {
          'rangeType': 'range',
          'borderType': side.key,
          'color': side.value.color ?? '#ff000000',
          'style': side.value.style,
          'range': [
            {
              'row': [row, row],
              'column': [column, column],
              'row_focus': row,
              'column_focus': column,
            },
          ],
        },
    ];
  }
}

class _XlsxCellFormat {
  const _XlsxCellFormat({
    this.numFmtId,
    this.fontId,
    this.fillId,
    this.borderId,
    this.horizontalAlign,
    this.verticalAlign,
    this.wrapText = false,
    this.textRotation,
    this.quotePrefix = false,
  });

  final int? numFmtId;
  final int? fontId;
  final int? fillId;
  final int? borderId;
  final String? horizontalAlign;
  final String? verticalAlign;
  final bool wrapText;
  final String? textRotation;
  final bool quotePrefix;
}

class _XlsxFont {
  const _XlsxFont({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikeThrough = false,
    this.fontSize,
    this.fontFamily,
    this.foreground,
    this.script,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final double? fontSize;
  final String? fontFamily;
  final String? foreground;
  final String? script;
}

class _XlsxBorder {
  const _XlsxBorder({this.sides = const <String, _XlsxBorderSide>{}});

  final Map<String, _XlsxBorderSide> sides;
}

class _XlsxBorderSide {
  const _XlsxBorderSide({required this.style, this.color});

  final int style;
  final String? color;
}

class _XlsxCellValue {
  const _XlsxCellValue({this.text, this.formula, this.inlineRuns});

  final String? text;
  final String? formula;
  final List<Map<String, Object?>>? inlineRuns;

  _XlsxCellValue copyWith({String? formula}) {
    return _XlsxCellValue(
      text: text,
      formula: formula ?? this.formula,
      inlineRuns: inlineRuns,
    );
  }
}

class _XlsxRelationship {
  const _XlsxRelationship({
    required this.id,
    required this.target,
    this.type,
    this.targetMode,
  });

  final String id;
  final String target;
  final String? type;
  final String? targetMode;
}

class _XlsxExtensionMetadata {
  const _XlsxExtensionMetadata({
    this.cellExtraByRef = const <String, Map<String, Object?>>{},
    this.runExtraByRef = const <String, Map<int, Map<String, Object?>>>{},
  });

  final Map<String, Map<String, Object?>> cellExtraByRef;
  final Map<String, Map<int, Map<String, Object?>>> runExtraByRef;

  static _XlsxExtensionMetadata fromArchive(Archive archive) {
    final cellExtra = <String, Map<String, Object?>>{};
    final runExtra = <String, Map<int, Map<String, Object?>>>{};
    for (final file in archive.files) {
      final name = file.name.replaceAll('\\', '/');
      if (!file.isFile || !name.startsWith('customXml/') || !name.endsWith('.xml')) {
        continue;
      }
      final bytes = file.readBytes();
      if (bytes == null) {
        continue;
      }
      final xml = utf8.decode(bytes);
      if (!xml.contains('labelSheetRtfMetadata')) {
        continue;
      }
      _readMetadataXml(xml, cellExtra, runExtra);
    }
    return _XlsxExtensionMetadata(
      cellExtraByRef: cellExtra,
      runExtraByRef: runExtra,
    );
  }

  Map<String, Object?> cellExtra(String? ref) {
    if (ref == null) {
      return const <String, Object?>{};
    }
    return cellExtraByRef[ref] ?? const <String, Object?>{};
  }

  List<Map<String, Object?>>? applyRunExtra(
    String? ref,
    List<Map<String, Object?>>? runs,
  ) {
    if (ref == null || runs == null || runs.isEmpty) {
      return runs;
    }
    final extras = runExtraByRef[ref];
    if (extras == null || extras.isEmpty) {
      return runs;
    }
    return [
      for (var index = 0; index < runs.length; index += 1)
        {
          ...runs[index],
          ...?extras[index],
        },
    ];
  }

  static void _readMetadataXml(
    String xml,
    Map<String, Map<String, Object?>> cellExtra,
    Map<String, Map<int, Map<String, Object?>>> runExtra,
  ) {
    for (final match in RegExp(
      r'<cell\b([^>]*)/>|<cell\b([^>]*)>(.*?)</cell>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xml)) {
      final attributes = _xmlAttributes(match.group(1) ?? match.group(2) ?? '');
      final ref = attributes['ref'];
      if (ref == null || ref.isEmpty) {
        continue;
      }
      final extra = _metadataExtra(attributes, const {'ref'});
      final body = match.group(3) ?? '';
      final controls = _metadataControls(body);
      if (controls.isNotEmpty) {
        extra['rtfUnmappedControls'] = controls;
      }
      if (extra.isNotEmpty) {
        cellExtra[ref] = {...?cellExtra[ref], ...extra};
      }
      for (final runMatch in RegExp(
        r'<run\b([^>]*)/>|<run\b([^>]*)>(.*?)</run>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(body)) {
        final runAttributes = _xmlAttributes(
          runMatch.group(1) ?? runMatch.group(2) ?? '',
        );
        final index = int.tryParse(runAttributes['index'] ?? '');
        if (index == null || index < 0) {
          continue;
        }
        final run = _metadataExtra(runAttributes, const {'index', 'text'});
        final runControls = _metadataControls(runMatch.group(3) ?? '');
        if (runControls.isNotEmpty) {
          run['rtfUnmappedControls'] = runControls;
        }
        if (run.isEmpty) {
          continue;
        }
        runExtra.putIfAbsent(ref, () => <int, Map<String, Object?>>{})[index] = {
          ...?runExtra[ref]?[index],
          ...run,
        };
      }
    }
  }
}

List<_XlsxFont> _fonts(String xml) {
  final body = _extractElement(xml, 'fonts') ?? '';
  return [
    for (final fontXml in _elementBodies(body, 'font'))
      _XlsxFont(
        bold: _hasFlag(fontXml, 'b'),
        italic: _hasFlag(fontXml, 'i'),
        underline: _hasFlag(fontXml, 'u'),
        strikeThrough: _hasFlag(fontXml, 'strike'),
        fontSize: double.tryParse(_firstTagAttributes(fontXml, 'sz')?['val'] ?? ''),
        fontFamily: _firstTagAttributes(fontXml, 'name')?['val'],
        foreground: _colorFromElement(fontXml, 'color'),
        script: _scriptFromVertAlign(_firstTagAttributes(fontXml, 'vertAlign')?['val']),
      ),
  ];
}

List<String?> _fills(String xml) {
  final body = _extractElement(xml, 'fills') ?? '';
  return [
    for (final fillXml in _elementBodies(body, 'fill'))
      _colorFromElement(fillXml, 'fgColor') ?? _colorFromElement(fillXml, 'bgColor'),
  ];
}

List<_XlsxBorder> _borders(String xml) {
  final body = _extractElement(xml, 'borders') ?? '';
  return [
    for (final borderXml in _elementBodies(body, 'border'))
      _XlsxBorder(sides: _borderSides(borderXml)),
  ];
}

Map<String, _XlsxBorderSide> _borderSides(String borderXml) {
  final left = _borderSide(borderXml, 'left');
  final right = _borderSide(borderXml, 'right');
  final top = _borderSide(borderXml, 'top');
  final bottom = _borderSide(borderXml, 'bottom');
  return {
    if (left != null) 'border-left': left,
    if (right != null) 'border-right': right,
    if (top != null) 'border-top': top,
    if (bottom != null) 'border-bottom': bottom,
  };
}

_XlsxBorderSide? _borderSide(String xml, String tag) {
  final content = _extractElement(xml, tag);
  final attributes = _firstTagAttributes(xml, tag);
  if (content == null && attributes == null) {
    return null;
  }
  final styleText = attributes?['style'];
  if (styleText == null || styleText == 'none') {
    return null;
  }
  return _XlsxBorderSide(
    style: _borderStyle(styleText),
    color: content == null ? null : _colorFromElement(content, 'color'),
  );
}

Map<int, String> _numberFormats(String xml) {
  final body = _extractElement(xml, 'numFmts') ?? '';
  final formats = <int, String>{};
  for (final match in RegExp(
    r'<numFmt\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(body)) {
    final attributes = _xmlAttributes(match.group(1) ?? '');
    final id = int.tryParse(attributes['numFmtId'] ?? '');
    final formatCode = attributes['formatCode'];
    if (id != null && formatCode != null) {
      formats[id] = formatCode;
    }
  }
  return formats;
}

List<_XlsxCellFormat> _cellFormats(String xml) {
  final body = _extractElement(xml, 'cellXfs') ?? '';
  final matches = RegExp(
    r'<xf\b([^>/]*)(?:/|>(.*?)</xf>)',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(body);
  return [
    for (final match in matches)
      _cellFormat(
        _xmlAttributes(match.group(1) ?? ''),
        match.group(2) ?? '',
      ),
  ];
}

_XlsxCellFormat _cellFormat(Map<String, String> attributes, String body) {
  final alignment = _firstTagAttributes(body, 'alignment');
  return _XlsxCellFormat(
    numFmtId: int.tryParse(attributes['numFmtId'] ?? ''),
    fontId: int.tryParse(attributes['fontId'] ?? ''),
    fillId: int.tryParse(attributes['fillId'] ?? ''),
    borderId: int.tryParse(attributes['borderId'] ?? ''),
    quotePrefix: _xmlBool(attributes['quotePrefix']),
    horizontalAlign: alignment?['horizontal'],
    verticalAlign: alignment?['vertical'],
    wrapText: _xmlBool(alignment?['wrapText']),
    textRotation: alignment?['textRotation'],
  );
}

Iterable<({String start, String end})> _mergeRefs(String xml) sync* {
  for (final match in RegExp(
    r'<mergeCell\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(xml)) {
    final ref = _xmlAttributes(match.group(1) ?? '')['ref'];
    if (ref == null || ref.isEmpty) {
      continue;
    }
    final parts = ref.split(':');
    if (parts.length == 1) {
      yield (start: parts[0], end: parts[0]);
    } else if (parts.length == 2) {
      yield (start: parts[0], end: parts[1]);
    }
  }
}

Iterable<({int min, int max, double? width, bool hidden})> _columnDefs(
  String xml,
) sync* {
  for (final match in RegExp(
    r'<col\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(xml)) {
    final attributes = _xmlAttributes(match.group(1) ?? '');
    final min = int.tryParse(attributes['min'] ?? '');
    final max = int.tryParse(attributes['max'] ?? '');
    if (min == null || max == null || min <= 0 || max < min) {
      continue;
    }
    yield (
      min: min,
      max: max,
      width: double.tryParse(attributes['width'] ?? ''),
      hidden: _xmlBool(attributes['hidden']),
    );
  }
}

({int row, int column})? _cellRefToCoord(String ref) {
  final match = RegExp(r'^\$?([A-Za-z]+)\$?(\d+)').firstMatch(ref.trim());
  if (match == null) {
    return null;
  }
  var column = 0;
  for (final codeUnit in match.group(1)!.toUpperCase().codeUnits) {
    column = column * 26 + (codeUnit - 64);
  }
  final row = int.tryParse(match.group(2)!);
  if (row == null || row <= 0 || column <= 0) {
    return null;
  }
  return (row: row - 1, column: column - 1);
}

({int row, int column})? _dimensionEnd(String xml) {
  final ref = _firstTagAttributes(xml, 'dimension')?['ref'];
  if (ref == null || ref.isEmpty) {
    return null;
  }
  final parts = ref.split(':');
  return _cellRefToCoord(parts.length == 1 ? parts[0] : parts[1]);
}

({int row, int column})? _keyToCoord(String key) {
  final parts = key.split('_');
  if (parts.length != 2) {
    return null;
  }
  final row = int.tryParse(parts[0]);
  final column = int.tryParse(parts[1]);
  if (row == null || column == null) {
    return null;
  }
  return (row: row, column: column);
}

Map<String, String>? _firstTagAttributes(String xml, String tag) {
  final match = RegExp(
    '<$tag\\b([^>]*)/?>',
    caseSensitive: false,
  ).firstMatch(xml);
  return match == null ? null : _xmlAttributes(match.group(1) ?? '');
}

String? _extractElement(String xml, String tag) {
  final match = RegExp(
    '<$tag\\b[^>]*>(.*?)</$tag>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(xml);
  return match?.group(1);
}

Iterable<String> _elementBodies(String xml, String tag) sync* {
  final pattern = RegExp(
    '<$tag\\b[^>]*>(.*?)</$tag>|<$tag\\b[^>]*/>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final match in pattern.allMatches(xml)) {
    yield match.group(1) ?? '';
  }
}

String? _tagText(String xml, String tag) {
  final match = RegExp(
    '<$tag\\b[^>]*>(.*?)</$tag>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(xml);
  return match == null ? null : _xmlDecode(match.group(1) ?? '');
}

String _textFromPlainTextXml(String xml) {
  final buffer = StringBuffer();
  for (final match in RegExp(
    r'<t\b[^>]*>(.*?)</t>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml)) {
    buffer.write(_xmlDecode(match.group(1) ?? ''));
  }
  return buffer.toString();
}

Map<String, String> _xmlAttributes(String raw) {
  return {
    for (final match in RegExp(
      "([\\w:.-]+)\\s*=\\s*(\"([^\"]*)\"|'([^']*)')",
    ).allMatches(raw))
      match.group(1)!: _xmlDecode(match.group(3) ?? match.group(4) ?? ''),
  };
}

Map<String, Object?> _metadataExtra(
  Map<String, String> attributes,
  Set<String> excludedKeys,
) {
  return {
    for (final entry in attributes.entries)
      if (!excludedKeys.contains(entry.key)) entry.key: _metadataValue(entry.value),
  };
}

Object _metadataValue(String value) {
  if (value == 'true') {
    return true;
  }
  if (value == 'false') {
    return false;
  }
  final integer = int.tryParse(value);
  if (integer != null) {
    return integer;
  }
  final number = double.tryParse(value);
  if (number != null) {
    return number;
  }
  return value;
}

List<String> _metadataControls(String xml) {
  return [
    for (final match in RegExp(
      r'<control\b([^>]*)/?>',
      caseSensitive: false,
    ).allMatches(xml))
      if (_xmlAttributes(match.group(1) ?? '')['value'] case final value?)
        if (value.isNotEmpty) value,
  ];
}

String? _colorFromElement(String xml, String tag) {
  final attributes = _firstTagAttributes(xml, tag);
  if (attributes == null) {
    return null;
  }
  final rgb = attributes['rgb'];
  if (rgb != null && RegExp(r'^[0-9a-fA-F]{6,8}$').hasMatch(rgb)) {
    return '#${rgb.length == 6 ? 'ff$rgb' : rgb}'.toLowerCase();
  }
  final indexed = int.tryParse(attributes['indexed'] ?? '');
  return indexed == null ? null : _indexedColors[indexed];
}

String? _scriptFromVertAlign(String? value) {
  if (value == 'superscript' || value == 'subscript') {
    return value;
  }
  return null;
}

bool _hasFlag(String xml, String tag) {
  final attributes = _firstTagAttributes(xml, tag);
  if (attributes == null) {
    return false;
  }
  return !_xmlBool(attributes['val'], defaultValue: true) ? false : true;
}

bool _xmlBool(String? value, {bool defaultValue = false}) {
  if (value == null || value.isEmpty) {
    return defaultValue;
  }
  final normalized = value.toLowerCase();
  return normalized == '1' || normalized == 'true';
}

String? _emptyToNull(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

String _xmlDecode(String value) {
  return value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

T? _itemAt<T>(List<T> values, int? index) {
  if (index == null || index < 0 || index >= values.length) {
    return null;
  }
  return values[index];
}

int _borderStyle(String style) {
  return switch (style) {
    'hair' || 'dotted' => 3,
    'dashDot' || 'dashDotDot' || 'dashed' => 2,
    'medium' || 'mediumDashed' || 'mediumDashDot' || 'mediumDashDotDot' => 4,
    'thick' || 'double' => 5,
    _ => 1,
  };
}

int _max(int left, int right) => left > right ? left : right;

const Map<int, String> _builtinNumberFormats = {
  0: 'General',
  1: '0',
  2: '0.00',
  3: '#,##0',
  4: '#,##0.00',
  9: '0%',
  10: '0.00%',
  11: '0.00E+00',
  12: '# ?/?',
  13: '# ??/??',
  14: 'm/d/yy',
  15: 'd-mmm-yy',
  16: 'd-mmm',
  17: 'mmm-yy',
  18: 'h:mm AM/PM',
  19: 'h:mm:ss AM/PM',
  20: 'h:mm',
  21: 'h:mm:ss',
  22: 'm/d/yy h:mm',
  37: '#,##0 ;(#,##0)',
  38: '#,##0 ;[Red](#,##0)',
  39: '#,##0.00;(#,##0.00)',
  40: '#,##0.00;[Red](#,##0.00)',
  45: 'mm:ss',
  46: '[h]:mm:ss',
  47: 'mmss.0',
  48: '##0.0E+0',
  49: '@',
};

const Map<int, String> _indexedColors = {
  0: '#ff000000',
  1: '#ffffffff',
  2: '#ffff0000',
  3: '#ff00ff00',
  4: '#ff0000ff',
  5: '#ffffff00',
  6: '#ffff00ff',
  7: '#ff00ffff',
  8: '#ff000000',
  9: '#ffffffff',
  10: '#ffff0000',
  11: '#ff00ff00',
  12: '#ff0000ff',
  13: '#ffffff00',
  14: '#ffff00ff',
  15: '#ff00ffff',
  16: '#ff800000',
  17: '#ff008000',
  18: '#ff000080',
  19: '#ff808000',
  20: '#ff800080',
  21: '#ff008080',
  22: '#ffc0c0c0',
  23: '#ff808080',
  64: '#00000000',
};
