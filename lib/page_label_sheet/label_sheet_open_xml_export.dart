import 'dart:io';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/page_label_sheet/label_sheet_import_model.dart';

const String labelSheetOpenXmlTestPath = '.tmp/test.xlsx';
const String labelSheetOpenXmlFallbackTestPath = '.tmp/test_latest.xlsx';

Future<File> labelSheetWriteDraftOpenXmlTestFile(
  LabelSheetImageImportDraft draft, {
  String path = labelSheetOpenXmlTestPath,
}) async {
  final file = File(path);
  await file.parent.create(recursive: true);

  final archive = Archive();
  void addXml(String name, String content) {
    archive.addFile(ArchiveFile.string(name, content));
  }

  addXml('[Content_Types].xml', _contentTypesXml);
  addXml('_rels/.rels', _rootRelsXml);
  addXml('xl/workbook.xml', _workbookXml);
  addXml('xl/_rels/workbook.xml.rels', _workbookRelsXml);
  final styles = _OpenXmlStyleTable.fromDraft(draft);
  addXml('xl/styles.xml', styles.toXml());
  addXml('xl/worksheets/sheet1.xml', _worksheetXml(draft, styles));
  addXml('customXml/item1.xml', _metadataXml(draft));

  final bytes = ZipEncoder().encodeBytes(archive);
  try {
    await file.writeAsBytes(bytes, flush: true);
  } on FileSystemException {
    if (path != labelSheetOpenXmlTestPath) {
      rethrow;
    }
    final fallback = File(labelSheetOpenXmlFallbackTestPath);
    await fallback.parent.create(recursive: true);
    await fallback.writeAsBytes(bytes, flush: true);
    return fallback;
  }
  return file;
}

String _worksheetXml(
  LabelSheetImageImportDraft draft,
  _OpenXmlStyleTable styles,
) {
  final rowCount = _rowCount(draft);
  final columnCount = _columnCount(draft);
  final dimension = 'A1:${_columnName(columnCount)}$rowCount';
  final mergeRefs = _mergeRefs(draft);
  final buffer = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    )
    ..write('<dimension ref="$dimension"/>')
    ..write('<sheetViews><sheetView workbookViewId="0"/></sheetViews>')
    ..write('<sheetFormatPr defaultRowHeight="15"/>')
    ..write(_columnsXml(draft.columnWidths, columnCount))
    ..write('<sheetData>');

  for (var rowIndex = 0; rowIndex < rowCount; rowIndex += 1) {
    final rowNumber = rowIndex + 1;
    final rowHeight = draft.rowHeights[rowIndex];
    buffer.write('<row r="$rowNumber"');
    if (rowHeight != null && rowHeight.isFinite && rowHeight > 0) {
      buffer.write(' ht="${_excelRowHeight(rowHeight)}" customHeight="1"');
    }
    buffer.write('>');
    for (var columnIndex = 0; columnIndex < columnCount; columnIndex += 1) {
      final coord = FortuneCellCoord(rowIndex, columnIndex);
      final cell = draft.cells[coord];
      final text = _cellText(cell);
      final ref = '${_columnName(columnIndex + 1)}$rowNumber';
      final styleIndex = styles.styleIndex(coord, cell);
      if (text.isEmpty) {
        buffer.write('<c r="$ref" s="$styleIndex"/>');
        continue;
      }
      buffer
        ..write('<c r="$ref" t="inlineStr" s="$styleIndex"><is>')
        ..write(_inlineStringXml(cell, text))
        ..write('</is></c>');
    }
    buffer.write('</row>');
  }

  buffer
    ..write('</sheetData>')
    ..write(_mergeCellsXml(mergeRefs))
    ..write(
      '<pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>',
    )
    ..write('</worksheet>');
  return buffer.toString();
}

String _inlineStringXml(FortuneCell? cell, String fallbackText) {
  final runs = cell?.inlineRuns;
  if (runs == null || runs.isEmpty) {
    return _textXml(fallbackText);
  }
  final buffer = StringBuffer();
  for (final run in runs) {
    if (run.text.isEmpty) {
      continue;
    }
    buffer
      ..write('<r>')
      ..write(_runPropertiesXml(run))
      ..write(_textXml(run.text))
      ..write('</r>');
  }
  return buffer.isEmpty ? _textXml(fallbackText) : buffer.toString();
}

String _textXml(String text) {
  return '<t${_needsPreserveSpace(text) ? ' xml:space="preserve"' : ''}>${_xmlEscape(text)}</t>';
}

String _runPropertiesXml(FortuneInlineTextRun run) {
  final buffer = StringBuffer()..write('<rPr>');
  if (run.bold == true) {
    buffer.write('<b/>');
  }
  if (run.italic == true) {
    buffer.write('<i/>');
  }
  if (run.strikeThrough == true) {
    buffer.write('<strike/>');
  }
  if (run.underline == true) {
    buffer.write('<u/>');
  }
  final fontSize = run.fontSize;
  if (fontSize != null && fontSize.isFinite && fontSize > 0) {
    buffer.write('<sz val="${_fixed(fontSize)}"/>');
  }
  final foreground = run.foreground;
  if (foreground != null) {
    buffer.write('<color rgb="${_colorHex(foreground)}"/>');
  }
  final fontFamily = run.fontFamily;
  if (fontFamily != null && fontFamily.isNotEmpty) {
    buffer.write('<rFont val="${_xmlEscape(fontFamily)}"/>');
  }
  final script = run.extraFields['script'];
  if (script == 'superscript' || script == 'subscript') {
    buffer.write('<vertAlign val="$script"/>');
  }
  buffer.write('</rPr>');
  return buffer.toString();
}

String _mergeCellsXml(List<String> mergeRefs) {
  if (mergeRefs.isEmpty) {
    return '';
  }
  final buffer = StringBuffer()
    ..write('<mergeCells count="${mergeRefs.length}">');
  for (final ref in mergeRefs) {
    buffer.write('<mergeCell ref="$ref"/>');
  }
  buffer.write('</mergeCells>');
  return buffer.toString();
}

List<String> _mergeRefs(LabelSheetImageImportDraft draft) {
  final refs = <String>[];
  final seen = <String>{};
  for (final entry in draft.cells.entries) {
    final merge = entry.value.merge;
    if (merge == null || (merge.rowSpan <= 1 && merge.columnSpan <= 1)) {
      continue;
    }
    final startRow = merge.row;
    final startColumn = merge.column;
    final endRow = startRow + merge.rowSpan - 1;
    final endColumn = startColumn + merge.columnSpan - 1;
    if (startRow < 0 ||
        startColumn < 0 ||
        endRow < startRow ||
        endColumn < startColumn) {
      continue;
    }
    final ref =
        '${_columnName(startColumn + 1)}${startRow + 1}:${_columnName(endColumn + 1)}${endRow + 1}';
    if (seen.add(ref)) {
      refs.add(ref);
    }
  }
  refs.sort();
  return refs;
}

String _columnsXml(Map<int, double> columnWidths, int columnCount) {
  if (columnCount <= 0) {
    return '';
  }
  final buffer = StringBuffer()..write('<cols>');
  for (var index = 0; index < columnCount; index += 1) {
    final width = columnWidths[index];
    final excelWidth = width == null || !width.isFinite || width <= 0
        ? 10.0
        : (width / 7).clamp(3.0, 80.0);
    final columnNumber = index + 1;
    buffer.write(
      '<col min="$columnNumber" max="$columnNumber" width="${_fixed(excelWidth)}" customWidth="1"/>',
    );
  }
  buffer.write('</cols>');
  return buffer.toString();
}

int _rowCount(LabelSheetImageImportDraft draft) {
  return _maxIndex(draft.rowHeights.keys, _cellRowIndexes(draft));
}

int _columnCount(LabelSheetImageImportDraft draft) {
  return _maxIndex(draft.columnWidths.keys, _cellColumnIndexes(draft));
}

Iterable<int> _cellRowIndexes(LabelSheetImageImportDraft draft) sync* {
  for (final entry in draft.cells.entries) {
    yield entry.key.row;
    final merge = entry.value.merge;
    if (merge != null) {
      yield merge.row + merge.rowSpan - 1;
    }
  }
}

Iterable<int> _cellColumnIndexes(LabelSheetImageImportDraft draft) sync* {
  for (final entry in draft.cells.entries) {
    yield entry.key.column;
    final merge = entry.value.merge;
    if (merge != null) {
      yield merge.column + merge.columnSpan - 1;
    }
  }
}

int _maxIndex(Iterable<int> first, Iterable<int> second) {
  var maxIndex = 0;
  for (final value in [...first, ...second]) {
    if (value > maxIndex) {
      maxIndex = value;
    }
  }
  return maxIndex + 1;
}

String _cellText(FortuneCell? cell) {
  if (cell == null) {
    return '';
  }
  return cell.displayValue ?? cell.value;
}

String _columnName(int columnNumber) {
  var value = columnNumber;
  final chars = <int>[];
  while (value > 0) {
    value -= 1;
    chars.add(65 + value % 26);
    value ~/= 26;
  }
  return String.fromCharCodes(chars.reversed);
}

String _excelRowHeight(double logicalHeight) =>
    _fixed((logicalHeight / 1.3333333333).clamp(6.0, 409.0));

String _fixed(num value) => value.toStringAsFixed(2);

String _colorHex(Color color) =>
    color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

Object? _inlineMeta(Map<String, Object?> extraFields, String key) {
  final value = extraFields[key];
  return switch (value) {
    num number when number.isFinite => _fixed(number),
    bool flag => flag ? 'true' : 'false',
    String text when text.isNotEmpty => text,
    _ => null,
  };
}

List<MapEntry<String, String>> _metadataAttributes(
  Map<String, Object?> extraFields,
) {
  final entries = <MapEntry<String, String>>[];
  final keys = extraFields.keys.toList()..sort();
  for (final key in keys) {
    if (key == 'labelRtfImport' || key == 'rtfUnmappedControls') {
      continue;
    }
    final value = _inlineMeta(extraFields, key);
    if (value != null) {
      entries.add(MapEntry(key, '$value'));
    }
  }
  return entries;
}

List<String> _metadataControls(Map<String, Object?> extraFields) {
  final controls = extraFields['rtfUnmappedControls'];
  if (controls is Iterable) {
    return [
      for (final control in controls)
        if ('$control'.isNotEmpty) '$control',
    ];
  }
  return const <String>[];
}

void _writeMetadataAttributes(
  StringBuffer buffer,
  Map<String, Object?> extraFields,
) {
  for (final entry in _metadataAttributes(extraFields)) {
    buffer.write(' ${entry.key}="${_xmlEscape(entry.value)}"');
  }
}

void _writeMetadataControls(
  StringBuffer buffer,
  Map<String, Object?> extraFields,
) {
  for (final control in _metadataControls(extraFields)) {
    buffer.write('<control value="${_xmlEscape(control)}"/>');
  }
}

String _metadataXml(LabelSheetImageImportDraft draft) {
  final buffer = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write('<labelSheetRtfMetadata xmlns="urn:label-manager:rtf-metadata">');
  final entries = draft.cells.entries.toList()
    ..sort((a, b) {
      final row = a.key.row.compareTo(b.key.row);
      return row != 0 ? row : a.key.column.compareTo(b.key.column);
    });
  for (final entry in entries) {
    final ref = '${_columnName(entry.key.column + 1)}${entry.key.row + 1}';
    final cell = entry.value;
    buffer.write('<cell ref="$ref"');
    _writeMetadataAttributes(buffer, cell.extraFields);
    final cellControls = _metadataControls(cell.extraFields);
    final runs = cell.inlineRuns ?? const <FortuneInlineTextRun>[];
    if (runs.isEmpty && cellControls.isEmpty) {
      buffer.write('/>');
      continue;
    }
    buffer.write('>');
    _writeMetadataControls(buffer, cell.extraFields);
    for (var index = 0; index < runs.length; index += 1) {
      final run = runs[index];
      final hasMetadata =
          _metadataAttributes(run.extraFields).isNotEmpty ||
          _metadataControls(run.extraFields).isNotEmpty;
      if (!hasMetadata) {
        continue;
      }
      buffer.write('<run index="$index" text="${_xmlEscape(run.text)}"');
      _writeMetadataAttributes(buffer, run.extraFields);
      final controls = _metadataControls(run.extraFields);
      if (controls.isEmpty) {
        buffer.write('/>');
      } else {
        buffer.write('>');
        _writeMetadataControls(buffer, run.extraFields);
        buffer.write('</run>');
      }
    }
    buffer.write('</cell>');
  }
  for (var index = 0; index < draft.images.length; index += 1) {
    final image = draft.images[index];
    buffer.write(
      '<image index="$index" id="${_xmlEscape(image.id)}" '
      'left="${_fixed(image.left)}" top="${_fixed(image.top)}" '
      'width="${_fixed(image.width)}" height="${_fixed(image.height)}"',
    );
    _writeMetadataAttributes(buffer, image.extraFields);
    final controls = _metadataControls(image.extraFields);
    if (controls.isEmpty) {
      buffer.write('/>');
    } else {
      buffer.write('>');
      _writeMetadataControls(buffer, image.extraFields);
      buffer.write('</image>');
    }
  }
  buffer.write('</labelSheetRtfMetadata>');
  return buffer.toString();
}

bool _needsPreserveSpace(String value) => RegExp(r'^\s|\s$').hasMatch(value);

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const String _contentTypesXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';

const String _rootRelsXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml" Target="customXml/item1.xml"/>
</Relationships>''';

const String _workbookXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="RTF Test" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''';

const String _workbookRelsXml =
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

class _OpenXmlStyleTable {
  _OpenXmlStyleTable._();

  final List<_OpenXmlFont> _fonts = [const _OpenXmlFont()];
  final List<Color?> _fills = [null, null];
  final List<_OpenXmlBorder> _borders = const [
    _OpenXmlBorder(),
    _OpenXmlBorder.diagnosticGrid(),
  ].toList();
  final List<_OpenXmlCellFormat> _cellFormats = const [
    _OpenXmlCellFormat(fontId: 0, fillId: 0, borderId: 0),
    _OpenXmlCellFormat(fontId: 0, fillId: 0, borderId: 1, wrap: true),
  ].toList();
  final Map<_OpenXmlFont, int> _fontIds = {const _OpenXmlFont(): 0};
  final Map<int, int> _fillIds = <int, int>{};
  final Map<_OpenXmlBorder, int> _borderIds = {
    const _OpenXmlBorder(): 0,
    const _OpenXmlBorder.diagnosticGrid(): 1,
  };
  final Map<_OpenXmlCellFormat, int> _cellFormatIds = {
    const _OpenXmlCellFormat(fontId: 0, fillId: 0, borderId: 0): 0,
    const _OpenXmlCellFormat(fontId: 0, fillId: 0, borderId: 1, wrap: true): 1,
  };
  Map<FortuneCellCoord, _OpenXmlBorder>? _actualBordersByCoord;

  factory _OpenXmlStyleTable.fromDraft(LabelSheetImageImportDraft draft) {
    final table = _OpenXmlStyleTable._();
    table._actualBordersByCoord = _openXmlBordersByCoord(draft.borderInfo);
    for (final entry in draft.cells.entries) {
      table.styleIndex(entry.key, entry.value);
    }
    return table;
  }

  int styleIndex(FortuneCellCoord coord, FortuneCell? cell) {
    final actualBorders = _actualBordersByCoord;
    final border = actualBorders?[coord];
    final borderId = border == null
        ? actualBorders == null
              ? 1
              : 0
        : _borderId(border);
    if (cell == null) {
      if (borderId == 1) {
        return 1;
      }
      final format = _OpenXmlCellFormat(
        fontId: 0,
        fillId: 0,
        borderId: borderId,
        wrap: true,
      );
      return _cellFormatIds.putIfAbsent(format, () {
        _cellFormats.add(format);
        return _cellFormats.length - 1;
      });
    }
    final format = _OpenXmlCellFormat(
      fontId: _fontId(_OpenXmlFont.fromCell(cell)),
      fillId: _fillId(cell.background),
      borderId: borderId,
      horizontalAlign: cell.horizontalAlign,
      verticalAlign: cell.verticalAlign == 'middle'
          ? 'center'
          : cell.verticalAlign,
      wrap: cell.textWrap == 'wrap',
    );
    return _cellFormatIds.putIfAbsent(format, () {
      _cellFormats.add(format);
      return _cellFormats.length - 1;
    });
  }

  int _borderId(_OpenXmlBorder border) {
    return _borderIds.putIfAbsent(border, () {
      _borders.add(border);
      return _borders.length - 1;
    });
  }

  int _fontId(_OpenXmlFont font) {
    return _fontIds.putIfAbsent(font, () {
      _fonts.add(font);
      return _fonts.length - 1;
    });
  }

  int _fillId(Color? color) {
    if (color == null) {
      return 0;
    }
    final key = color.toARGB32();
    return _fillIds.putIfAbsent(key, () {
      _fills.add(color);
      return _fills.length - 1;
    });
  }

  String toXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  ${_fontsXml()}
  ${_fillsXml()}
  ${_bordersXml()}
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  ${_cellXfsXml()}
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
  }

  String _fontsXml() =>
      '<fonts count="${_fonts.length}">${_fonts.map((font) => font.toXml()).join()}</fonts>';

  String _fillsXml() {
    final buffer = StringBuffer()
      ..write('<fills count="${_fills.length}">')
      ..write('<fill><patternFill patternType="none"/></fill>')
      ..write('<fill><patternFill patternType="gray125"/></fill>');
    for (final color in _fills.skip(2)) {
      buffer.write(
        '<fill><patternFill patternType="solid"><fgColor rgb="${_colorHex(color!)}"/><bgColor indexed="64"/></patternFill></fill>',
      );
    }
    buffer.write('</fills>');
    return buffer.toString();
  }

  String _bordersXml() =>
      '<borders count="${_borders.length}">${_borders.map((border) => border.toXml()).join()}</borders>';

  String _cellXfsXml() {
    final buffer = StringBuffer()
      ..write('<cellXfs count="${_cellFormats.length}">');
    for (final format in _cellFormats) {
      buffer.write(format.toXml());
    }
    buffer.write('</cellXfs>');
    return buffer.toString();
  }
}

class _OpenXmlFont {
  const _OpenXmlFont({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikeThrough = false,
    this.fontSize,
    this.fontFamily,
    this.foreground,
  });

  factory _OpenXmlFont.fromCell(FortuneCell cell) {
    return _OpenXmlFont(
      bold: cell.bold,
      italic: cell.italic,
      underline: cell.underline,
      strikeThrough: cell.strikeThrough,
      fontSize: cell.fontSize,
      fontFamily: cell.fontFamily,
      foreground:
          cell.hasRawForeground || cell.foreground != const Color(0xff000000)
          ? cell.foreground
          : null,
    );
  }

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikeThrough;
  final double? fontSize;
  final String? fontFamily;
  final Color? foreground;

  String toXml() {
    final buffer = StringBuffer()..write('<font>');
    if (bold) buffer.write('<b/>');
    if (italic) buffer.write('<i/>');
    if (strikeThrough) buffer.write('<strike/>');
    if (underline) buffer.write('<u/>');
    buffer.write(
      '<sz val="${_fixed(fontSize == null || fontSize! <= 0 ? 11 : fontSize!)}"/>',
    );
    if (foreground == null) {
      buffer.write('<color theme="1"/>');
    } else {
      buffer.write('<color rgb="${_colorHex(foreground!)}"/>');
    }
    buffer.write(
      '<name val="${_xmlEscape(fontFamily == null || fontFamily!.isEmpty ? 'Calibri' : fontFamily!)}"/><family val="2"/></font>',
    );
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is _OpenXmlFont &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.strikeThrough == strikeThrough &&
        other.fontSize == fontSize &&
        other.fontFamily == fontFamily &&
        other.foreground?.toARGB32() == foreground?.toARGB32();
  }

  @override
  int get hashCode => Object.hash(
    bold,
    italic,
    underline,
    strikeThrough,
    fontSize,
    fontFamily,
    foreground?.toARGB32(),
  );
}

Map<FortuneCellCoord, _OpenXmlBorder>? _openXmlBordersByCoord(
  List<FortuneBorderInfo> borderInfo,
) {
  if (borderInfo.isEmpty) {
    return null;
  }
  final builders = <FortuneCellCoord, _OpenXmlBorderBuilder>{};
  for (final info in borderInfo) {
    if (info.rangeType != 'range') {
      continue;
    }
    final sideName = switch (info.borderType) {
      'border-left' => 'left',
      'border-right' => 'right',
      'border-top' => 'top',
      'border-bottom' => 'bottom',
      _ => null,
    };
    if (sideName == null) {
      continue;
    }
    final side = _OpenXmlBorderSide.fromFortune(info);
    for (final range in info.ranges) {
      for (var row = range.rowStart; row <= range.rowEnd; row += 1) {
        for (
          var column = range.columnStart;
          column <= range.columnEnd;
          column += 1
        ) {
          final coord = FortuneCellCoord(row, column);
          builders
              .putIfAbsent(coord, _OpenXmlBorderBuilder.new)
              .setSide(sideName, side);
        }
      }
    }
  }
  if (builders.isEmpty) {
    return null;
  }
  return {for (final entry in builders.entries) entry.key: entry.value.build()};
}

class _OpenXmlBorderBuilder {
  _OpenXmlBorderSide? left;
  _OpenXmlBorderSide? right;
  _OpenXmlBorderSide? top;
  _OpenXmlBorderSide? bottom;

  void setSide(String sideName, _OpenXmlBorderSide side) {
    switch (sideName) {
      case 'left':
        left = side;
      case 'right':
        right = side;
      case 'top':
        top = side;
      case 'bottom':
        bottom = side;
    }
  }

  _OpenXmlBorder build() =>
      _OpenXmlBorder(left: left, right: right, top: top, bottom: bottom);
}

class _OpenXmlBorder {
  const _OpenXmlBorder({this.left, this.right, this.top, this.bottom});

  const _OpenXmlBorder.diagnosticGrid()
    : left = const _OpenXmlBorderSide(style: 'thin'),
      right = const _OpenXmlBorderSide(style: 'thin'),
      top = const _OpenXmlBorderSide(style: 'thin'),
      bottom = const _OpenXmlBorderSide(style: 'thin');

  final _OpenXmlBorderSide? left;
  final _OpenXmlBorderSide? right;
  final _OpenXmlBorderSide? top;
  final _OpenXmlBorderSide? bottom;

  String toXml() {
    return '<border>${_sideXml('left', left)}${_sideXml('right', right)}${_sideXml('top', top)}${_sideXml('bottom', bottom)}<diagonal/></border>';
  }

  String _sideXml(String name, _OpenXmlBorderSide? side) {
    if (side == null) {
      return '<$name/>';
    }
    final color = side.color;
    return '<$name style="${side.style}">${color == null ? '<color auto="1"/>' : '<color rgb="${_colorHex(color)}"/>'}</$name>';
  }

  @override
  bool operator ==(Object other) {
    return other is _OpenXmlBorder &&
        other.left == left &&
        other.right == right &&
        other.top == top &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, right, top, bottom);
}

class _OpenXmlBorderSide {
  const _OpenXmlBorderSide({required this.style, this.color});

  factory _OpenXmlBorderSide.fromFortune(FortuneBorderInfo info) {
    final width = info.strokeWidth ?? 1;
    final style = switch (info.style) {
      2 => 'double',
      3 || 10 => 'dotted',
      4 || 9 => 'dashed',
      _ =>
        width >= 3
            ? 'thick'
            : width >= 2
            ? 'medium'
            : 'thin',
    };
    return _OpenXmlBorderSide(style: style, color: info.color);
  }

  final String style;
  final Color? color;

  @override
  bool operator ==(Object other) {
    return other is _OpenXmlBorderSide &&
        other.style == style &&
        other.color?.toARGB32() == color?.toARGB32();
  }

  @override
  int get hashCode => Object.hash(style, color?.toARGB32());
}

class _OpenXmlCellFormat {
  const _OpenXmlCellFormat({
    required this.fontId,
    required this.fillId,
    required this.borderId,
    this.horizontalAlign,
    this.verticalAlign,
    this.wrap = false,
  });

  final int fontId;
  final int fillId;
  final int borderId;
  final String? horizontalAlign;
  final String? verticalAlign;
  final bool wrap;

  String toXml() {
    final hasAlignment =
        wrap || horizontalAlign != null || verticalAlign != null;
    final buffer = StringBuffer()
      ..write(
        '<xf numFmtId="0" fontId="$fontId" fillId="$fillId" borderId="$borderId" xfId="0"',
      )
      ..write(fontId == 0 ? '' : ' applyFont="1"')
      ..write(fillId == 0 ? '' : ' applyFill="1"')
      ..write(borderId == 0 ? '' : ' applyBorder="1"')
      ..write(hasAlignment ? ' applyAlignment="1"' : '');
    if (!hasAlignment) {
      buffer.write('/>');
      return buffer.toString();
    }
    buffer
      ..write('><alignment')
      ..write(wrap ? ' wrapText="1"' : '')
      ..write(
        horizontalAlign == null
            ? ''
            : ' horizontal="${_xmlEscape(horizontalAlign!)}"',
      )
      ..write(
        verticalAlign == null
            ? ''
            : ' vertical="${_xmlEscape(verticalAlign!)}"',
      )
      ..write('/></xf>');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is _OpenXmlCellFormat &&
        other.fontId == fontId &&
        other.fillId == fillId &&
        other.borderId == borderId &&
        other.horizontalAlign == horizontalAlign &&
        other.verticalAlign == verticalAlign &&
        other.wrap == wrap;
  }

  @override
  int get hashCode => Object.hash(
    fontId,
    fillId,
    borderId,
    horizontalAlign,
    verticalAlign,
    wrap,
  );
}
