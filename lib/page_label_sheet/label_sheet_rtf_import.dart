import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as imglib;
import 'package:label_manager/page_label_sheet/label_sheet_import_model.dart';
import 'package:label_manager/page_label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_label_sheet/label_sheet_open_xml_export.dart';
import 'package:label_manager/utils/log_context.dart';

String? _preferredKoreanAnsiCharset;

void _rtfLog(String message) {
  debugLog(message, skipFrames: 1);
}

bool labelSheetLooksLikeRichEditRtf(String? rtf) {
  final value = rtf?.trimLeft();
  if (value == null || value.isEmpty) {
    return false;
  }
  if (!value.startsWith('{\\rtf')) {
    return false;
  }
  return RegExp(
    r'\\(?:ansi|ansicpg\d+|deff\d+|fonttbl|colortbl|pard|trowd|generator)',
  ).hasMatch(value);
}

LabelSheetImageImportDraft? labelSheetDraftFromRichEditRtf(
  String rtf, {
  required FortuneSheet sheet,
}) {
  final stopwatch = Stopwatch()..start();
  _rtfLog('sync convert start length=${rtf.length} hash=${rtf.hashCode}');
  if (!labelSheetLooksLikeRichEditRtf(rtf)) {
    _rtfLog('sync convert skipped: not RichEdit RTF');
    return null;
  }
  final document = _RtfDocumentReader(rtf).read();
  _rtfLog(
    'sync parse done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'rawRows=${document.rows.length} preferredEdges=${document.preferredCellEdgesTwips.length}',
  );
  final sourceRows = document.rows
      .where((row) => row.any((cell) => cell.isStructurallyRelevant))
      .toList();
  final expanded = _expandMultilineRtfRows(
    sourceRows,
    document.rowHeightsTwips,
  );
  final rows = expanded.rows;
  if (rows.isEmpty) {
    _rtfLog('sync convert result=null reason=no non-empty rows');
    return null;
  }

  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final logicalSize = physicalSize.logicalSize;
  final columnCount = math.max(
    1,
    rows.map((row) => row.length).reduce(math.max),
  );
  final rowHeights = _rowHeights(
    expanded.rowHeightsTwips,
    rowCount: rows.length,
    logicalHeight: logicalSize.height,
  );
  final columnWidths = _columnWidths(
    document.preferredCellEdgesTwips,
    columnCount: columnCount,
    logicalWidth: logicalSize.width,
  );
  final cells = _cellsFromRtfRows(rows);
  final borderInfo = _borderInfoFromRtfRows(rows);
  if (cells.isEmpty) {
    _rtfLog('sync convert result=null reason=no cells');
    return null;
  }
  final images = _rtfPicturesToImages(
    document.pictures,
    rowHeights: rowHeights,
    columnWidths: columnWidths,
  );

  _rtfLog(
    'sync convert done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'rows=${rows.length} columns=$columnCount cells=${cells.length} '
    'images=${images.length} physical=${physicalSize.widthMm}x${physicalSize.heightMm}',
  );

  return LabelSheetImageImportDraft(
    imageWidth: physicalSize.widthMm.round(),
    imageHeight: physicalSize.heightMm.round(),
    rowLines: const <int>[],
    columnLines: const <int>[],
    rowHeights: rowHeights,
    columnWidths: columnWidths,
    cells: cells,
    borderInfo: borderInfo,
    images: images,
  );
}

_ExpandedRtfRows _expandMultilineRtfRows(
  List<List<_RtfCell>> rows,
  List<int?> rowHeightsTwips,
) {
  final expandedRows = <List<_RtfCell>>[];
  final expandedHeights = <int?>[];
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
    final row = rows[rowIndex];
    final rowHeight = rowIndex < rowHeightsTwips.length
        ? rowHeightsTwips[rowIndex]
        : null;
    if (row.any((cell) => cell.hasMergeFlag)) {
      expandedRows.add(row);
      expandedHeights.add(rowHeight);
      continue;
    }
    final linesByCell = [for (final cell in row) _rtfCellLineSlices(cell)];
    final lineCount = linesByCell.fold<int>(
      1,
      (count, lines) => math.max(count, lines.length),
    );
    if (lineCount <= 1) {
      expandedRows.add(row);
      expandedHeights.add(rowHeight);
      continue;
    }
    _rtfLog('expand multiline row row=$rowIndex lines=$lineCount');
    final splitHeight = rowHeight == null
        ? null
        : math.max(1, rowHeight ~/ lineCount);
    for (var lineIndex = 0; lineIndex < lineCount; lineIndex += 1) {
      expandedRows.add([
        for (var column = 0; column < row.length; column += 1)
          row[column].copyWithLine(
            lineIndex < linesByCell[column].length
                ? linesByCell[column][lineIndex]
                : const _RtfLineSlice(text: ''),
            lineIndex: lineIndex,
            lineCount: lineCount,
          ),
      ]);
      expandedHeights.add(splitHeight);
    }
  }
  return _ExpandedRtfRows(
    rows: List.unmodifiable(expandedRows),
    rowHeightsTwips: List.unmodifiable(expandedHeights),
  );
}

List<FortuneBorderInfo> _borderInfoFromRtfRows(List<List<_RtfCell>> rows) {
  final borders = <FortuneBorderInfo>[];
  for (var row = 0; row < rows.length; row += 1) {
    for (var column = 0; column < rows[row].length; column += 1) {
      final cell = rows[row][column];
      for (final entry in cell.borderSides.entries) {
        final borderSide = entry.value;
        if (!borderSide.isVisible) {
          continue;
        }
        borders.add(
          FortuneBorderInfo(
            rangeType: 'range',
            borderType: 'border-${entry.key}',
            color: borderSide.color ?? const Color(0xff000000),
            style: borderSide.fortuneStyle,
            strokeWidth: borderSide.strokeWidth,
            ranges: [
              FortuneRange(
                rowStart: row,
                rowEnd: row,
                columnStart: column,
                columnEnd: column,
              ),
            ],
            extraFields: const {'labelRtfImport': true},
          ),
        );
      }
    }
  }
  return borders;
}

List<_RtfLineSlice> _rtfCellLineSlices(_RtfCell cell) {
  final textLines = _normalizedRtfLines(cell.text);
  final firstContentLine = textLines.indexWhere(
    (line) => line.trim().isNotEmpty,
  );
  if (firstContentLine < 0) {
    return const [_RtfLineSlice(text: '')];
  }
  var lastContentLine = textLines.length - 1;
  while (lastContentLine > firstContentLine &&
      textLines[lastContentLine].trim().isEmpty) {
    lastContentLine -= 1;
  }
  final runsByLine = _inlineRunsByRtfLine(cell.inlineRuns, textLines.length);
  return [
    for (var line = firstContentLine; line <= lastContentLine; line += 1)
      _RtfLineSlice(
        text: textLines[line],
        inlineRuns: runsByLine == null ? null : runsByLine[line],
      ),
  ];
}

List<String> _normalizedRtfLines(String text) {
  return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
}

List<List<FortuneInlineTextRun>?>? _inlineRunsByRtfLine(
  List<FortuneInlineTextRun>? runs,
  int lineCount,
) {
  if (runs == null || runs.isEmpty) {
    return null;
  }
  final runsByLine = List<List<FortuneInlineTextRun>?>.filled(lineCount, null);
  var line = 0;
  for (final run in runs) {
    final parts = _normalizedRtfLines(run.text);
    for (var partIndex = 0; partIndex < parts.length; partIndex += 1) {
      final part = parts[partIndex];
      if (part.isNotEmpty && line < runsByLine.length) {
        (runsByLine[line] ??= <FortuneInlineTextRun>[]).add(
          run.copyWith(text: part, rawText: part),
        );
      }
      if (partIndex < parts.length - 1) {
        line += 1;
      }
    }
  }
  return runsByLine;
}

Future<LabelSheetImageImportDraft?> _nativeRtfHtmlDraft(
  String rtf, {
  required FortuneSheet sheet,
}) async {
  final html = await labelSheetConvertRtfNativeHtml(rtf);
  if (html == null) {
    return null;
  }
  final draft = _draftFromRtfHtml(html, sheet: sheet);
  if (draft != null) {
    _rtfLog(
      'native html draft done rows=${draft.rowHeights.length} '
      'columns=${draft.columnWidths.length} cells=${draft.cells.length}',
    );
  }
  return draft;
}

LabelSheetImageImportDraft? _draftFromRtfHtml(
  String html, {
  required FortuneSheet sheet,
}) {
  final document = html_parser.parse(html);
  final table = document.querySelector('table');
  if (table == null) {
    return null;
  }
  final rows = table.querySelectorAll('tr');
  if (rows.isEmpty) {
    return null;
  }
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final logicalSize = physicalSize.logicalSize;
  final css = _htmlCssRules(document);
  final rawColumnWidths = [
    for (final col in table.querySelectorAll('col'))
      _cssLengthPx(col.attributes['style'] ?? ''),
  ].whereType<double>().toList();

  final rowCells = <List<html_dom.Element>>[];
  var columnCount = rawColumnWidths.length;
  for (final row in rows) {
    final cells = row.children
        .where((element) => element.localName == 'td' || element.localName == 'th')
        .toList(growable: false);
    if (cells.isEmpty) {
      continue;
    }
    rowCells.add(cells);
    var count = 0;
    for (final cell in cells) {
      count += int.tryParse(cell.attributes['colspan'] ?? '') ?? 1;
    }
    columnCount = math.max(columnCount, count);
  }
  if (rowCells.isEmpty || columnCount == 0) {
    return null;
  }

  final widthUnits = rawColumnWidths.length == columnCount
      ? rawColumnWidths
      : List<double>.filled(columnCount, 1);
  final totalWidth = widthUnits.fold<double>(0, (sum, value) => sum + value);
  final columnWidths = <int, double>{
    for (var column = 0; column < columnCount; column += 1)
      column: logicalSize.width * widthUnits[column] / math.max(1, totalWidth),
  };
  final rowHeight = logicalSize.height / rowCells.length;
  final rowHeights = <int, double>{
    for (var row = 0; row < rowCells.length; row += 1) row: rowHeight,
  };

  final cells = <FortuneCellCoord, FortuneCell>{};
  final borders = <FortuneBorderInfo>[];
  for (var rowIndex = 0; rowIndex < rowCells.length; rowIndex += 1) {
    var columnIndex = 0;
    for (final element in rowCells[rowIndex]) {
      final text = element.text.trim();
      final columnSpan = int.tryParse(element.attributes['colspan'] ?? '') ?? 1;
      final style = _htmlCellStyle(element, css);
      final coord = FortuneCellCoord(rowIndex, columnIndex);
      if (text.isNotEmpty || columnSpan > 1) {
        cells[coord] = FortuneCell(
          value: text,
          displayValue: text,
          rawValue: text,
          hasRawValue: text.isNotEmpty,
          rawDisplayValue: text,
          hasRawDisplayValue: text.isNotEmpty,
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          bold: style.bold ?? false,
          rawBold: style.bold,
          hasRawBold: style.bold != null,
          italic: style.italic ?? false,
          rawItalic: style.italic,
          hasRawItalic: style.italic != null,
          foreground: style.foreground ?? const Color(0xff000000),
          rawForeground: style.foreground,
          hasRawForeground: style.foreground != null,
          background: style.background,
          rawBackground: style.background,
          hasRawBackground: style.background != null,
          textWrap: 'wrap',
          verticalAlign: 'middle',
          merge: columnSpan > 1
              ? FortuneCellMerge(
                  row: rowIndex,
                  column: columnIndex,
                  columnSpan: columnSpan,
                )
              : null,
          extraFields: {
            if (style.script != null) 'script': style.script,
          },
        );
      }
      _addHtmlBorders(
        borders,
        element,
        row: rowIndex,
        column: columnIndex,
        columnSpan: columnSpan,
      );
      columnIndex += columnSpan;
    }
  }
  return LabelSheetImageImportDraft(
    imageWidth: physicalSize.widthMm.round(),
    imageHeight: physicalSize.heightMm.round(),
    rowLines: const <int>[],
    columnLines: const <int>[],
    rowHeights: rowHeights,
    columnWidths: columnWidths,
    cells: cells,
    images: const <FortuneImage>[],
    borderInfo: borders,
  );
}

Map<String, Map<String, String>> _htmlCssRules(html_dom.Document document) {
  final rules = <String, Map<String, String>>{};
  for (final style in document.querySelectorAll('style')) {
    final css = style.text;
    final matches = RegExp(r'([^{}]+)\{([^{}]+)\}').allMatches(css);
    for (final match in matches) {
      final selector = match.group(1)!.trim();
      if (!selector.startsWith('.')) {
        continue;
      }
      rules[selector.substring(1)] = _cssDeclarations(match.group(2)!);
    }
  }
  return rules;
}

Map<String, String> _cssDeclarations(String style) {
  final values = <String, String>{};
  for (final item in style.split(';')) {
    final separator = item.indexOf(':');
    if (separator <= 0) {
      continue;
    }
    values[item.substring(0, separator).trim().toLowerCase()] = item
        .substring(separator + 1)
        .trim();
  }
  return values;
}

double? _cssLengthPx(String style) {
  final match = RegExp(r'width\s*:\s*([0-9.]+)').firstMatch(style);
  return match == null ? null : double.tryParse(match.group(1)!);
}

_HtmlCellStyle _htmlCellStyle(
  html_dom.Element cell,
  Map<String, Map<String, String>> css,
) {
  final declarations = <String, String>{};
  void mergeElement(html_dom.Element element) {
    for (final className in element.classes) {
      declarations.addAll(css[className] ?? const <String, String>{});
    }
    declarations.addAll(_cssDeclarations(element.attributes['style'] ?? ''));
  }

  mergeElement(cell);
  for (final element in cell.querySelectorAll('p, span, sup, sub')) {
    mergeElement(element);
    if (element.localName == 'sup') {
      declarations['vertical-align'] = 'super';
    } else if (element.localName == 'sub') {
      declarations['vertical-align'] = 'sub';
    }
    if (element.text.trim().isNotEmpty) {
      break;
    }
  }
  final verticalAlign = declarations['vertical-align']?.toLowerCase();
  return _HtmlCellStyle(
    fontFamily: _firstFontFamily(declarations['font-family']),
    fontSize: _fontSizePt(declarations['font-size']),
    bold: declarations['font-weight']?.toLowerCase() == 'bold' ? true : null,
    italic: declarations['font-style']?.toLowerCase() == 'italic' ? true : null,
    foreground: _cssColor(declarations['color']),
    background: _cssColor(
      declarations['background-color'] ?? declarations['background'],
    ),
    script: verticalAlign == 'super'
        ? 'superscript'
        : verticalAlign == 'sub'
        ? 'subscript'
        : null,
  );
}

String? _firstFontFamily(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value.split(',').first.replaceAll("'", '').replaceAll('"', '').trim();
}

double? _fontSizePt(String? value) {
  if (value == null) {
    return null;
  }
  final match = RegExp(r'([0-9.]+)\s*pt').firstMatch(value);
  return match == null ? null : double.tryParse(match.group(1)!);
}

Color? _cssColor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final hex = RegExp(r'#([0-9a-fA-F]{6})').firstMatch(value);
  if (hex != null) {
    return Color(0xff000000 | int.parse(hex.group(1)!, radix: 16));
  }
  switch (value.trim().toLowerCase()) {
    case 'black':
      return const Color(0xff000000);
    case 'white':
      return const Color(0xffffffff);
  }
  return null;
}

void _addHtmlBorders(
  List<FortuneBorderInfo> borders,
  html_dom.Element cell, {
  required int row,
  required int column,
  required int columnSpan,
}) {
  final classes = cell.classes;
  final sides = <String>['left', 'right'];
  if (classes.contains('bt')) {
    sides.add('top');
  }
  if (classes.contains('bb')) {
    sides.add('bottom');
  }
  for (final side in sides) {
    borders.add(
      FortuneBorderInfo(
        rangeType: 'range',
        borderType: 'border-$side',
        color: const Color(0xff000000),
        style: 1,
        strokeWidth: 1,
        ranges: [
          FortuneRange(
            rowStart: row,
            rowEnd: row,
            columnStart: column,
            columnEnd: column + (columnSpan < 1 ? 1 : columnSpan) - 1,
          ),
        ],
        extraFields: const {'labelRtfHtmlImport': true},
      ),
    );
  }
}

class _HtmlCellStyle {
  const _HtmlCellStyle({
    this.fontFamily,
    this.fontSize,
    this.bold,
    this.italic,
    this.foreground,
    this.background,
    this.script,
  });

  final String? fontFamily;
  final double? fontSize;
  final bool? bold;
  final bool? italic;
  final Color? foreground;
  final Color? background;
  final String? script;
}

Future<LabelSheetImageImportDraft?> labelSheetDraftFromRichEditRtfAsync(
  String rtf, {
  required FortuneSheet sheet,
  FortuneBarcodeRenderer? barcodeRenderer,
}) async {
  final stopwatch = Stopwatch()..start();
  _rtfLog('async convert start length=${rtf.length} hash=${rtf.hashCode}');
  if (!labelSheetLooksLikeRichEditRtf(rtf)) {
    _rtfLog('async convert skipped: not RichEdit RTF');
    return null;
  }
  final nativeDraft = await _nativeRtfHtmlDraft(rtf, sheet: sheet);
  if (nativeDraft != null) {
    var draft = nativeDraft;
    if (barcodeRenderer != null) {
      final decodedForImages = await _decodeRtfAnsiHex(rtf);
      final document = _RtfDocumentReader(decodedForImages).read();
      final images = await _rtfPicturesToImagesAsync(
        document.pictures,
        rowHeights: draft.rowHeights,
        columnWidths: draft.columnWidths,
        barcodeRenderer: barcodeRenderer,
      );
      draft = LabelSheetImageImportDraft(
        imageWidth: draft.imageWidth,
        imageHeight: draft.imageHeight,
        rowLines: draft.rowLines,
        columnLines: draft.columnLines,
        rowHeights: draft.rowHeights,
        columnWidths: draft.columnWidths,
        cells: draft.cells,
        images: images,
        borderInfo: draft.borderInfo,
      );
    }
    _rtfLog(
      'async native convert done elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    return draft;
  }
  final decoded = await _decodeRtfAnsiHex(rtf);
  _rtfLog(
    'async decode done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'decodedLength=${decoded.length} decodedHash=${decoded.hashCode}',
  );
  var draft = labelSheetDraftFromRichEditRtf(decoded, sheet: sheet);
  if (draft != null && barcodeRenderer != null) {
    final document = _RtfDocumentReader(decoded).read();
    final images = await _rtfPicturesToImagesAsync(
      document.pictures,
      rowHeights: draft.rowHeights,
      columnWidths: draft.columnWidths,
      barcodeRenderer: barcodeRenderer,
    );
    draft = LabelSheetImageImportDraft(
      imageWidth: draft.imageWidth,
      imageHeight: draft.imageHeight,
      rowLines: draft.rowLines,
      columnLines: draft.columnLines,
      rowHeights: draft.rowHeights,
      columnWidths: draft.columnWidths,
      cells: draft.cells,
      images: images,
      borderInfo: draft.borderInfo,
    );
  }
  _rtfLog(
    'async convert done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'result=${draft == null ? 'null' : 'draft'}',
  );
  return draft;
}

Future<File?> labelSheetWriteRichEditRtfOpenXmlTestFile(
  String rtf, {
  required FortuneSheet sheet,
  String path = labelSheetOpenXmlTestPath,
  FortuneBarcodeRenderer? barcodeRenderer,
}) async {
  final stopwatch = Stopwatch()..start();
  _rtfLog('openxml convert start length=${rtf.length} hash=${rtf.hashCode}');
  if (!labelSheetLooksLikeRichEditRtf(rtf)) {
    _rtfLog('openxml convert skipped: not RichEdit RTF');
    return null;
  }
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final nativeFile = await labelSheetWriteRtfNativeOpenXmlFile(
    rtf,
    physicalSize: physicalSize,
    path: path,
  );
  if (nativeFile != null) {
    _rtfLog(
      'openxml native convert done elapsedMs=${stopwatch.elapsedMilliseconds} '
      'path=${nativeFile.path}',
    );
    return nativeFile;
  }
  final draft = await labelSheetDraftFromRichEditRtfAsync(
    rtf,
    sheet: sheet,
    barcodeRenderer: barcodeRenderer,
  );
  if (draft == null) {
    _rtfLog('openxml convert result=null reason=no draft');
    return null;
  }
  final file = await labelSheetWriteDraftOpenXmlTestFile(draft, path: path);
  _rtfLog(
    'openxml convert done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'path=${file.path} rows=${draft.rowHeights.length} '
    'columns=${draft.columnWidths.length} cells=${draft.cells.length} '
    'borders=${draft.borderInfo.length}',
  );
  return file;
}

Map<FortuneCellCoord, FortuneCell> _cellsFromRtfRows(
  List<List<_RtfCell>> rows,
) {
  final cells = <FortuneCellCoord, FortuneCell>{};
  final mergeByCoord = _mergeCells(rows);
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1) {
    final row = rows[rowIndex];
    _rtfLog('build row row=$rowIndex cells=${row.length}');
    for (var columnIndex = 0; columnIndex < row.length; columnIndex += 1) {
      final cell = row[columnIndex];
      final text = cell.text.trim();
      final coord = FortuneCellCoord(rowIndex, columnIndex);
      final merge = mergeByCoord[coord];
      if (text.isEmpty && merge == null) {
        continue;
      }
      cells[coord] = FortuneCell(
        value: text,
        displayValue: text,
        rawValue: text,
        hasRawValue: true,
        rawDisplayValue: text,
        hasRawDisplayValue: true,
        background: cell.backgroundColor,
        rawBackground: cell.backgroundColor,
        hasRawBackground: cell.backgroundColor != null,
        foreground: cell.foregroundColor ?? const Color(0xff000000),
        rawForeground: cell.foregroundColor,
        hasRawForeground: cell.foregroundColor != null,
        bold: cell.bold,
        rawBold: cell.bold,
        hasRawBold: cell.hasBold,
        italic: cell.italic,
        rawItalic: cell.italic,
        hasRawItalic: cell.hasItalic,
        strikeThrough: cell.strikeThrough,
        rawStrikeThrough: cell.strikeThrough,
        hasRawStrikeThrough: cell.hasStrikeThrough,
        underline: cell.underline,
        rawUnderline: cell.underline,
        hasRawUnderline: cell.hasUnderline,
        fontSize: cell.fontSizePt?.clamp(4, 72),
        rawFontSize: cell.fontSizePt,
        hasRawFontSize: cell.fontSizePt != null,
        fontFamily: cell.fontFamily,
        rawFontFamily: cell.fontFamily,
        hasRawFontFamily: cell.fontFamily != null,
        horizontalAlign: cell.horizontalAlign,
        rawHorizontalAlign: cell.horizontalAlign,
        hasRawHorizontalAlign: cell.horizontalAlign != null,
        verticalAlign: cell.verticalAlign ?? 'middle',
        rawVerticalAlign: cell.verticalAlign ?? 'middle',
        hasRawVerticalAlign: true,
        textWrap: 'wrap',
        rawTextWrap: 'wrap',
        hasRawTextWrap: true,
        merge: merge,
        inlineRuns: cell.inlineRuns,
        extraFields: cell.extraFields,
      );
    }
  }
  return cells;
}

List<FortuneImage> _rtfPicturesToImages(
  List<_RtfPicture> pictures, {
  required Map<int, double> rowHeights,
  required Map<int, double> columnWidths,
}) {
  return [
    for (var index = 0; index < pictures.length; index += 1)
      _rtfPictureToImage(
        pictures[index],
        index: index,
        rowHeights: rowHeights,
        columnWidths: columnWidths,
      ),
  ];
}

Future<List<FortuneImage>> _rtfPicturesToImagesAsync(
  List<_RtfPicture> pictures, {
  required Map<int, double> rowHeights,
  required Map<int, double> columnWidths,
  required FortuneBarcodeRenderer barcodeRenderer,
}) async {
  final images = <FortuneImage>[];
  for (var index = 0; index < pictures.length; index += 1) {
    final picture = pictures[index];
    final fallback = _rtfPictureToImage(
      picture,
      index: index,
      rowHeights: rowHeights,
      columnWidths: columnWidths,
    );
    images.add(
      await _rtfPictureToBarcodeImage(
            picture,
            fallback,
            barcodeRenderer: barcodeRenderer,
          ) ??
          fallback,
    );
  }
  return images;
}

FortuneImage _rtfPictureToImage(
  _RtfPicture picture, {
  required int index,
  required Map<int, double> rowHeights,
  required Map<int, double> columnWidths,
}) {
  final size = _rtfPictureLogicalSize(picture);
  return FortuneImage(
    id: 'rtf-picture-$index',
    src: _bytesDataUri(picture.bytes, picture.mimeType),
    left: _axisStart(columnWidths, picture.column),
    top: _axisStart(rowHeights, picture.row),
    width: size.width,
    height: size.height,
    extraFields: {
      'labelRtfImport': true,
      'rtfPicture': true,
      'rtfPictureType': picture.type,
      'originWidth': size.width,
      'originHeight': size.height,
      'rtfPicWidth': ?picture.picWidth,
      'rtfPicHeight': ?picture.picHeight,
      'rtfPicWidthGoalTwips': ?picture.picWidthGoalTwips,
      'rtfPicHeightGoalTwips': ?picture.picHeightGoalTwips,
      'rtfPicScaleX': picture.scaleX,
      'rtfPicScaleY': picture.scaleY,
    },
  );
}

Future<FortuneImage?> _rtfPictureToBarcodeImage(
  _RtfPicture picture,
  FortuneImage fallback, {
  required FortuneBarcodeRenderer barcodeRenderer,
}) async {
  final decoded = _decodeRtfPictureBarcode(picture);
  if (decoded == null) {
    return null;
  }
  final formatId = _zxingFormatId(decoded.format);
  if (formatId == null || decoded.text == null || decoded.text!.isEmpty) {
    return null;
  }
  final result = await barcodeRenderer(
    FortuneBarcodeRequest(
      text: decoded.text!,
      formatId: formatId,
      width: fallback.width,
      height: fallback.height,
      rotation: 0,
      barHeight: fallback.height,
      moduleScale: 3,
    ),
  );
  if (result == null) {
    return null;
  }
  return fallback.copyWith(
    src: _bytesDataUri(result.bytes, result.mimeType),
    width: result.pixelWidth?.toDouble() ?? fallback.width,
    height: result.pixelHeight?.toDouble() ?? fallback.height,
    extraFields: {
      ...fallback.extraFields,
      'fortuneBarcode': true,
      'barcodeText': decoded.text,
      'barcodeFormatId': formatId,
      'barcodeFormatLabel': decoded.format?.name ?? formatId,
      'originWidth': result.pixelWidth ?? fallback.width,
      'originHeight': result.pixelHeight ?? fallback.height,
      'barcodeModuleScale': 3,
      'barcodeBarHeight': fallback.height,
      'barcodeShowText': false,
      'rtfBarcodeDecoded': true,
    },
  );
}

zxing.Code? _decodeRtfPictureBarcode(_RtfPicture picture) {
  final decodedImage = imglib.decodeImage(picture.bytes);
  if (decodedImage == null ||
      decodedImage.width <= 0 ||
      decodedImage.height <= 0) {
    return null;
  }
  final luminance = Uint8List(decodedImage.width * decodedImage.height);
  var offset = 0;
  for (var y = 0; y < decodedImage.height; y += 1) {
    for (var x = 0; x < decodedImage.width; x += 1) {
      final pixel = decodedImage.getPixel(x, y);
      luminance[offset] =
          ((pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114)).round();
      offset += 1;
    }
  }
  try {
    final code = zxing.zx.readBarcode(
      luminance,
      zxing.DecodeParams(
        imageFormat: zxing.ImageFormat.lum,
        format: zxing.Format.any,
        width: decodedImage.width,
        height: decodedImage.height,
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
        tryDownscale: true,
      ),
    );
    return code.isValid ? code : null;
  } catch (error) {
    _rtfLog('barcode decode failed error=${error.runtimeType}: $error');
    return null;
  }
}

String? _zxingFormatId(int? format) {
  return switch (format) {
    zxing.Format.qrCode => 'qrCode',
    zxing.Format.dataMatrix => 'dataMatrix',
    zxing.Format.aztec => 'aztec',
    zxing.Format.codabar => 'codabar',
    zxing.Format.code39 => 'code39',
    zxing.Format.code93 => 'code93',
    zxing.Format.code128 => 'code128',
    zxing.Format.ean8 => 'ean8',
    zxing.Format.ean13 => 'ean13',
    zxing.Format.itf => 'itf',
    zxing.Format.upca => 'upca',
    zxing.Format.upce => 'upce',
    _ => null,
  };
}

({double width, double height}) _rtfPictureLogicalSize(_RtfPicture picture) {
  final width = picture.picWidthGoalTwips == null
      ? (picture.picWidth ?? 120).toDouble()
      : picture.picWidthGoalTwips! / 15;
  final height = picture.picHeightGoalTwips == null
      ? (picture.picHeight ?? 80).toDouble()
      : picture.picHeightGoalTwips! / 15;
  return (
    width: math.max(1, width * picture.scaleX / 100),
    height: math.max(1, height * picture.scaleY / 100),
  );
}

double _axisStart(Map<int, double> sizes, int index) {
  var offset = 0.0;
  for (var axis = 0; axis < index; axis += 1) {
    offset += sizes[axis] ?? 0;
  }
  return offset;
}

String _bytesDataUri(Uint8List bytes, String mimeType) {
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<String> _decodeRtfAnsiHex(String rtf) async {
  final stopwatch = Stopwatch()..start();
  final runPattern = RegExp(r"(?:\\'[0-9a-fA-F]{2})+");
  final buffer = StringBuffer();
  var offset = 0;
  var runCount = 0;
  var byteCount = 0;
  _rtfLog('hex decode scan start length=${rtf.length}');
  for (final match in runPattern.allMatches(rtf)) {
    runCount += 1;
    buffer.write(rtf.substring(offset, match.start));
    final bytes = <int>[];
    final run = match.group(0)!;
    for (var index = 0; index + 3 < run.length; index += 4) {
      bytes.add(int.parse(run.substring(index + 2, index + 4), radix: 16));
    }
    byteCount += bytes.length;
    if (runCount <= 10 || runCount % 100 == 0) {
      _rtfLog(
        'hex decode run=$runCount start=${match.start} end=${match.end} '
        'bytes=${bytes.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
    buffer.write(await _decodeKoreanAnsiBytes(bytes));
    offset = match.end;
  }
  buffer.write(rtf.substring(offset));
  _rtfLog(
    'hex decode scan done elapsedMs=${stopwatch.elapsedMilliseconds} '
    'runs=$runCount bytes=$byteCount outputLength=${buffer.length}',
  );
  return buffer.toString();
}

Future<String> _decodeKoreanAnsiBytes(List<int> bytes) async {
  if (bytes.isEmpty) {
    return '';
  }
  final data = Uint8List.fromList(bytes);
  final preferred = _preferredKoreanAnsiCharset;
  final charsets = [
    ?preferred,
    for (final charset in const ['CP949', 'MS949', 'x-windows-949', 'EUC-KR'])
      if (charset != preferred) charset,
  ];
  for (final charset in charsets) {
    try {
      final decoded = await CharsetConverter.decode(charset, data);
      _preferredKoreanAnsiCharset = charset;
      _rtfLog('charset decode success charset=$charset bytes=${bytes.length}');
      return decoded;
    } catch (error) {
      _rtfLog(
        'charset decode failed charset=$charset bytes=${bytes.length} '
        'error=${error.runtimeType}: $error',
      );
    }
  }
  _rtfLog('charset decode fallback latin1 bytes=${bytes.length}');
  return String.fromCharCodes(bytes);
}

Map<int, double> _columnWidths(
  List<int> edgesTwips, {
  required int columnCount,
  required double logicalWidth,
}) {
  if (edgesTwips.length >= columnCount) {
    final normalized = <int>[];
    var previous = 0;
    for (final edge in edgesTwips.take(columnCount)) {
      if (edge > previous) {
        normalized.add(edge);
        previous = edge;
      }
    }
    if (normalized.length == columnCount && normalized.last > 0) {
      var left = 0;
      return {
        for (var index = 0; index < normalized.length; index += 1)
          index: () {
            final right = normalized[index];
            final width =
                math.max(1, right - left) / normalized.last * logicalWidth;
            left = right;
            return width;
          }(),
      };
    }
  }
  return {
    for (var column = 0; column < columnCount; column += 1)
      column: logicalWidth / columnCount,
  };
}

Map<int, double> _rowHeights(
  List<int?> heightsTwips, {
  required int rowCount,
  required double logicalHeight,
}) {
  final normalized = [
    for (var row = 0; row < rowCount; row += 1)
      row < heightsTwips.length ? (heightsTwips[row]?.abs() ?? 0) : 0,
  ];
  final total = normalized.fold<int>(0, (sum, height) => sum + height);
  if (total > 0 && normalized.every((height) => height > 0)) {
    return {
      for (var row = 0; row < rowCount; row += 1)
        row: math.max(1, normalized[row]) / total * logicalHeight,
    };
  }
  return {
    for (var row = 0; row < rowCount; row += 1) row: logicalHeight / rowCount,
  };
}

Map<FortuneCellCoord, FortuneCellMerge> _mergeCells(List<List<_RtfCell>> rows) {
  final merges = <FortuneCellCoord, FortuneCellMerge>{};
  for (var row = 0; row < rows.length; row += 1) {
    for (var column = 0; column < rows[row].length; column += 1) {
      final cell = rows[row][column];
      if (cell.horizontalMergeContinuation || cell.verticalMergeContinuation) {
        continue;
      }

      var columnSpan = 1;
      while (column + columnSpan < rows[row].length &&
          rows[row][column + columnSpan].horizontalMergeContinuation) {
        columnSpan += 1;
      }

      var rowSpan = 1;
      if (cell.verticalMergeStart) {
        while (row + rowSpan < rows.length &&
            column < rows[row + rowSpan].length &&
            rows[row + rowSpan][column].verticalMergeContinuation) {
          rowSpan += 1;
        }
      }

      if (rowSpan <= 1 && columnSpan <= 1) {
        continue;
      }
      final merge = FortuneCellMerge(
        row: row,
        column: column,
        rowSpan: rowSpan,
        columnSpan: columnSpan,
      );
      for (var rowOffset = 0; rowOffset < rowSpan; rowOffset += 1) {
        for (
          var columnOffset = 0;
          columnOffset < columnSpan;
          columnOffset += 1
        ) {
          merges[FortuneCellCoord(row + rowOffset, column + columnOffset)] =
              merge;
        }
      }
    }
  }
  return merges;
}

class _RtfDocument {
  const _RtfDocument({
    required this.rows,
    required this.preferredCellEdgesTwips,
    required this.rowHeightsTwips,
    required this.pictures,
  });

  final List<List<_RtfCell>> rows;
  final List<int> preferredCellEdgesTwips;
  final List<int?> rowHeightsTwips;
  final List<_RtfPicture> pictures;
}

class _ExpandedRtfRows {
  const _ExpandedRtfRows({required this.rows, required this.rowHeightsTwips});

  final List<List<_RtfCell>> rows;
  final List<int?> rowHeightsTwips;
}

class _RtfLineSlice {
  const _RtfLineSlice({required this.text, this.inlineRuns});

  final String text;
  final List<FortuneInlineTextRun>? inlineRuns;
}

class _RtfBorderSide {
  const _RtfBorderSide({this.style, this.widthTwips, this.color});

  final String? style;
  final int? widthTwips;
  final Color? color;

  bool get isVisible {
    return style != null && style != 'none' && (widthTwips ?? 1) > 0;
  }

  int get fortuneStyle {
    final width = strokeWidth ?? 1;
    return switch (style) {
      'double' => 2,
      'dotted' => width >= 2 ? 3 : 10,
      'dashed' => width >= 2 ? 4 : 9,
      _ =>
        width >= 3
            ? 13
            : width >= 2
            ? 8
            : 1,
    };
  }

  double? get strokeWidth {
    final width = widthTwips;
    if (width == null || width <= 0) {
      return null;
    }
    return math.max(1, width / 10);
  }

  _RtfBorderSide copyWith({String? style, int? widthTwips, Color? color}) {
    return _RtfBorderSide(
      style: style ?? this.style,
      widthTwips: widthTwips ?? this.widthTwips,
      color: color ?? this.color,
    );
  }
}

class _RtfPicture {
  const _RtfPicture({
    required this.bytes,
    required this.type,
    required this.mimeType,
    required this.row,
    required this.column,
    required this.scaleX,
    required this.scaleY,
    this.picWidth,
    this.picHeight,
    this.picWidthGoalTwips,
    this.picHeightGoalTwips,
  });

  final Uint8List bytes;
  final String type;
  final String mimeType;
  final int row;
  final int column;
  final int scaleX;
  final int scaleY;
  final int? picWidth;
  final int? picHeight;
  final int? picWidthGoalTwips;
  final int? picHeightGoalTwips;
}

class _RtfPictureBuilder {
  _RtfPictureBuilder({required this.row, required this.column});

  final int row;
  final int column;
  final StringBuffer _hex = StringBuffer();
  String? type;
  int? picWidth;
  int? picHeight;
  int? picWidthGoalTwips;
  int? picHeightGoalTwips;
  int scaleX = 100;
  int scaleY = 100;

  void addHexChar(String char) {
    if (_isHexChar(char)) {
      _hex.write(char);
    }
  }

  void addHexByte(int value) {
    _hex.write(value.toRadixString(16).padLeft(2, '0'));
  }

  void readControlWord(String word, int? argument) {
    switch (word) {
      case 'pngblip':
        type = 'png';
      case 'jpegblip':
      case 'macpict':
        type = 'jpeg';
      case 'picw':
        picWidth = argument;
      case 'pich':
        picHeight = argument;
      case 'picwgoal':
        picWidthGoalTwips = argument;
      case 'pichgoal':
        picHeightGoalTwips = argument;
      case 'picscalex':
        scaleX = argument ?? 100;
      case 'picscaley':
        scaleY = argument ?? 100;
    }
  }

  _RtfPicture? build() {
    final data = _hex.toString();
    if (data.length < 2) {
      return null;
    }
    final evenLength = data.length.isEven ? data.length : data.length - 1;
    final bytes = Uint8List(evenLength ~/ 2);
    for (var index = 0; index < evenLength; index += 2) {
      final value = int.tryParse(data.substring(index, index + 2), radix: 16);
      if (value == null) {
        return null;
      }
      bytes[index ~/ 2] = value;
    }
    final resolvedType = type ?? _sniffPictureType(bytes);
    final mimeType = switch (resolvedType) {
      'png' => 'image/png',
      'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
    if (mimeType == 'application/octet-stream') {
      return null;
    }
    if (resolvedType == null) {
      return null;
    }
    return _RtfPicture(
      bytes: bytes,
      type: resolvedType,
      mimeType: mimeType,
      row: row,
      column: column,
      scaleX: scaleX <= 0 ? 100 : scaleX,
      scaleY: scaleY <= 0 ? 100 : scaleY,
      picWidth: picWidth,
      picHeight: picHeight,
      picWidthGoalTwips: picWidthGoalTwips,
      picHeightGoalTwips: picHeightGoalTwips,
    );
  }

  bool _isHexChar(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 70) ||
        (code >= 97 && code <= 102);
  }
}

String? _sniffPictureType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8) {
    return 'jpeg';
  }
  return null;
}

class _RtfCell {
  const _RtfCell({
    required this.text,
    required this.bold,
    required this.hasBold,
    required this.italic,
    required this.hasItalic,
    required this.strikeThrough,
    required this.hasStrikeThrough,
    required this.underline,
    required this.hasUnderline,
    required this.fontSizePt,
    required this.fontFamily,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.horizontalAlign,
    required this.verticalAlign,
    required this.horizontalMergeStart,
    required this.horizontalMergeContinuation,
    required this.verticalMergeStart,
    required this.verticalMergeContinuation,
    required this.borderSides,
    required this.extraFields,
    required this.inlineRuns,
  });

  final String text;
  final bool bold;
  final bool hasBold;
  final bool italic;
  final bool hasItalic;
  final bool strikeThrough;
  final bool hasStrikeThrough;
  final bool underline;
  final bool hasUnderline;
  final double? fontSizePt;
  final String? fontFamily;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final String? horizontalAlign;
  final String? verticalAlign;
  final bool horizontalMergeStart;
  final bool horizontalMergeContinuation;
  final bool verticalMergeStart;
  final bool verticalMergeContinuation;
  final Map<String, _RtfBorderSide> borderSides;
  final Map<String, Object?> extraFields;
  final List<FortuneInlineTextRun>? inlineRuns;

  bool get isStructurallyRelevant {
    return text.trim().isNotEmpty ||
        horizontalMergeStart ||
        horizontalMergeContinuation ||
        verticalMergeStart ||
        verticalMergeContinuation;
  }

  bool get hasMergeFlag {
    return horizontalMergeStart ||
        horizontalMergeContinuation ||
        verticalMergeStart ||
        verticalMergeContinuation;
  }

  _RtfCell copyWithLine(
    _RtfLineSlice line, {
    required int lineIndex,
    required int lineCount,
  }) {
    return _RtfCell(
      text: line.text,
      bold: bold,
      hasBold: hasBold,
      italic: italic,
      hasItalic: hasItalic,
      strikeThrough: strikeThrough,
      hasStrikeThrough: hasStrikeThrough,
      underline: underline,
      hasUnderline: hasUnderline,
      fontSizePt: fontSizePt,
      fontFamily: fontFamily,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      horizontalAlign: horizontalAlign,
      verticalAlign: verticalAlign,
      horizontalMergeStart: horizontalMergeStart,
      horizontalMergeContinuation: horizontalMergeContinuation,
      verticalMergeStart: verticalMergeStart,
      verticalMergeContinuation: verticalMergeContinuation,
      borderSides: _lineBorderSides(lineIndex: lineIndex, lineCount: lineCount),
      extraFields: extraFields,
      inlineRuns: line.inlineRuns,
    );
  }

  Map<String, _RtfBorderSide> _lineBorderSides({
    required int lineIndex,
    required int lineCount,
  }) {
    if (lineCount <= 1 || borderSides.isEmpty) {
      return borderSides;
    }
    return {
      for (final entry in borderSides.entries)
        if (entry.key == 'left' ||
            entry.key == 'right' ||
            (entry.key == 'top' && lineIndex == 0) ||
            (entry.key == 'bottom' && lineIndex == lineCount - 1))
          entry.key: entry.value,
    };
  }

  _RtfCell copyWithAdditionalBorders(Map<String, _RtfBorderSide> borders) {
    if (borders.isEmpty) {
      return this;
    }
    return _RtfCell(
      text: text,
      bold: bold,
      hasBold: hasBold,
      italic: italic,
      hasItalic: hasItalic,
      strikeThrough: strikeThrough,
      hasStrikeThrough: hasStrikeThrough,
      underline: underline,
      hasUnderline: hasUnderline,
      fontSizePt: fontSizePt,
      fontFamily: fontFamily,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      horizontalAlign: horizontalAlign,
      verticalAlign: verticalAlign,
      horizontalMergeStart: horizontalMergeStart,
      horizontalMergeContinuation: horizontalMergeContinuation,
      verticalMergeStart: verticalMergeStart,
      verticalMergeContinuation: verticalMergeContinuation,
      borderSides: {...borderSides, ...borders},
      extraFields: extraFields,
      inlineRuns: inlineRuns,
    );
  }
}

class _RtfTextRun {
  const _RtfTextRun({required this.text, required this.state});

  final String text;
  final _RtfState state;
}

class _RtfCellFormat {
  const _RtfCellFormat({
    this.horizontalMergeStart = false,
    this.horizontalMergeContinuation = false,
    this.verticalMergeStart = false,
    this.verticalMergeContinuation = false,
    this.verticalAlign,
    this.borderSides = const <String, _RtfBorderSide>{},
  });

  final bool horizontalMergeStart;
  final bool horizontalMergeContinuation;
  final bool verticalMergeStart;
  final bool verticalMergeContinuation;
  final String? verticalAlign;
  final Map<String, _RtfBorderSide> borderSides;

  _RtfCellFormat copyWith({
    bool? horizontalMergeStart,
    bool? horizontalMergeContinuation,
    bool? verticalMergeStart,
    bool? verticalMergeContinuation,
    String? verticalAlign,
    Map<String, _RtfBorderSide>? borderSides,
  }) {
    return _RtfCellFormat(
      horizontalMergeStart: horizontalMergeStart ?? this.horizontalMergeStart,
      horizontalMergeContinuation:
          horizontalMergeContinuation ?? this.horizontalMergeContinuation,
      verticalMergeStart: verticalMergeStart ?? this.verticalMergeStart,
      verticalMergeContinuation:
          verticalMergeContinuation ?? this.verticalMergeContinuation,
      verticalAlign: verticalAlign ?? this.verticalAlign,
      borderSides: borderSides ?? this.borderSides,
    );
  }

  _RtfCellFormat withBorderSide(String side, _RtfBorderSide borderSide) {
    return copyWith(
      borderSides: Map.unmodifiable({...borderSides, side: borderSide}),
    );
  }
}

class _RtfCellBuilder {
  final StringBuffer _text = StringBuffer();
  final List<_RtfTextRun> _runs = [];
  bool bold = false;
  bool hasBold = false;
  bool italic = false;
  bool hasItalic = false;
  bool strikeThrough = false;
  bool hasStrikeThrough = false;
  bool underline = false;
  bool hasUnderline = false;
  double? fontSizePt;
  String? fontFamily;
  Color? foregroundColor;
  Color? backgroundColor;
  String? horizontalAlign;
  String? verticalAlign;
  double? fontScale;
  double? letterSpacing;
  double? lineHeight;
  String? script;
  Map<String, Object?>? rtfProperties;
  List<String>? unmappedControls;

  bool get isEmpty => _text.toString().trim().isEmpty;

  void append(String text, _RtfState state) {
    if (text.isEmpty) {
      return;
    }
    _text.write(text);
    if (_runs.isNotEmpty && _runs.last.state.sameInlineStyle(state)) {
      final previous = _runs.removeLast();
      _runs.add(_RtfTextRun(text: '${previous.text}$text', state: state));
    } else {
      _runs.add(_RtfTextRun(text: text, state: state));
    }
    if (text.trim().isEmpty) {
      return;
    }
    bold = bold || state.bold;
    hasBold = hasBold || state.hasBold;
    italic = italic || state.italic;
    hasItalic = hasItalic || state.hasItalic;
    strikeThrough = strikeThrough || state.strikeThrough;
    hasStrikeThrough = hasStrikeThrough || state.hasStrikeThrough;
    underline = underline || state.underline;
    hasUnderline = hasUnderline || state.hasUnderline;
    fontSizePt ??= state.fontSizePt;
    fontFamily ??= state.fontFamily;
    foregroundColor ??= state.foregroundColor;
    backgroundColor ??= state.backgroundColor;
    horizontalAlign ??= state.horizontalAlign;
    verticalAlign ??= state.verticalAlign;
    fontScale ??= state.fontScale;
    letterSpacing ??= state.letterSpacing;
    lineHeight ??= state.lineHeight;
    script ??= state.script;
    if (rtfProperties == null && state.rtfProperties.isNotEmpty) {
      rtfProperties = Map.unmodifiable(state.rtfProperties);
    }
    if (unmappedControls == null && state.unmappedControls.isNotEmpty) {
      unmappedControls = List.unmodifiable(state.unmappedControls);
    }
  }

  _RtfCell build(_RtfCellFormat format) {
    return _RtfCell(
      text: _text.toString(),
      bold: bold,
      hasBold: hasBold,
      italic: italic,
      hasItalic: hasItalic,
      strikeThrough: strikeThrough,
      hasStrikeThrough: hasStrikeThrough,
      underline: underline,
      hasUnderline: hasUnderline,
      fontSizePt: fontSizePt,
      fontFamily: fontFamily,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      horizontalAlign: horizontalAlign,
      verticalAlign: format.verticalAlign ?? verticalAlign,
      horizontalMergeStart: format.horizontalMergeStart,
      horizontalMergeContinuation: format.horizontalMergeContinuation,
      verticalMergeStart: format.verticalMergeStart,
      verticalMergeContinuation: format.verticalMergeContinuation,
      borderSides: format.borderSides,
      extraFields: _rtfInlineExtraFields(
        fontScale: fontScale,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
        script: script,
        rtfProperties: rtfProperties,
        unmappedControls: unmappedControls,
      ),
      inlineRuns: _inlineRuns(),
    );
  }

  List<FortuneInlineTextRun>? _inlineRuns() {
    if (_runs.isEmpty) {
      return null;
    }
    return [
      for (final run in _runs)
        FortuneInlineTextRun(
          text: run.text,
          rawText: run.text,
          hasRawText: true,
          foreground: run.state.foregroundColor,
          rawForeground: run.state.foregroundColor,
          hasRawForeground: run.state.foregroundColor != null,
          bold: run.state.bold,
          rawBold: run.state.bold,
          hasRawBold: run.state.hasBold,
          italic: run.state.italic,
          rawItalic: run.state.italic,
          hasRawItalic: run.state.hasItalic,
          strikeThrough: run.state.strikeThrough,
          rawStrikeThrough: run.state.strikeThrough,
          hasRawStrikeThrough: run.state.hasStrikeThrough,
          underline: run.state.underline,
          rawUnderline: run.state.underline,
          hasRawUnderline: run.state.hasUnderline,
          fontSize: _rtfInlineFontSize(run.state),
          rawFontSize: _rtfInlineFontSize(run.state),
          hasRawFontSize: run.state.fontSizePt != null,
          fontFamily: run.state.fontFamily,
          rawFontFamily: run.state.fontFamily,
          hasRawFontFamily: run.state.fontFamily != null,
          extraFields: _rtfInlineExtraFields(
            fontScale: run.state.fontScale,
            letterSpacing: run.state.letterSpacing,
            lineHeight: run.state.lineHeight,
            script: run.state.script,
            rtfProperties: run.state.rtfProperties,
            unmappedControls: run.state.unmappedControls,
          ),
        ),
    ];
  }
}

double? _rtfInlineFontSize(_RtfState state) {
  final fontSize = state.fontSizePt;
  if (fontSize == null) {
    return null;
  }
  return state.script == null ? fontSize : fontSize * 0.6;
}

double? _rtfLineHeight(
  int? lineSpacingTwips,
  double? fontSizePt,
  bool multiple,
) {
  if (lineSpacingTwips == null || lineSpacingTwips == 0) {
    return null;
  }
  final absoluteTwips = lineSpacingTwips.abs();
  if (multiple) {
    return absoluteTwips / 240;
  }
  if (fontSizePt == null || fontSizePt <= 0) {
    return null;
  }
  return absoluteTwips / 20 / fontSizePt;
}

Map<String, Object?> _rtfInlineExtraFields({
  required double? fontScale,
  required double? letterSpacing,
  required double? lineHeight,
  required String? script,
  Map<String, Object?>? rtfProperties,
  List<String>? unmappedControls,
}) {
  return {
    'labelRtfImport': true,
    'fontScale': ?fontScale,
    'letterSpacing': ?letterSpacing,
    'lineHeight': ?lineHeight,
    'script': ?script,
    ...?rtfProperties,
    if (unmappedControls != null && unmappedControls.isNotEmpty)
      'rtfUnmappedControls': unmappedControls,
  };
}

String _rtfControlToken(String word, int? argument) =>
    argument == null ? word : '$word=$argument';

bool _rtfMapEquals(Map<String, Object?> left, Map<String, Object?> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

bool _rtfListEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

class _RtfState {
  const _RtfState({
    this.bold = false,
    this.hasBold = false,
    this.italic = false,
    this.hasItalic = false,
    this.strikeThrough = false,
    this.hasStrikeThrough = false,
    this.underline = false,
    this.hasUnderline = false,
    this.fontSizePt,
    this.fontFamily,
    this.foregroundColor,
    this.backgroundColor,
    this.horizontalAlign,
    this.verticalAlign,
    this.fontScale,
    this.letterSpacing,
    this.lineHeight,
    this.lineSpacingTwips,
    this.lineSpacingMultiple = false,
    this.script,
    this.rtfProperties = const <String, Object?>{},
    this.unmappedControls = const <String>[],
    this.ucSkip = 1,
  });

  final bool bold;
  final bool hasBold;
  final bool italic;
  final bool hasItalic;
  final bool strikeThrough;
  final bool hasStrikeThrough;
  final bool underline;
  final bool hasUnderline;
  final double? fontSizePt;
  final String? fontFamily;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final String? horizontalAlign;
  final String? verticalAlign;
  final double? fontScale;
  final double? letterSpacing;
  final double? lineHeight;
  final int? lineSpacingTwips;
  final bool lineSpacingMultiple;
  final String? script;
  final Map<String, Object?> rtfProperties;
  final List<String> unmappedControls;
  final int ucSkip;

  bool sameInlineStyle(_RtfState other) {
    return bold == other.bold &&
        hasBold == other.hasBold &&
        italic == other.italic &&
        hasItalic == other.hasItalic &&
        strikeThrough == other.strikeThrough &&
        hasStrikeThrough == other.hasStrikeThrough &&
        underline == other.underline &&
        hasUnderline == other.hasUnderline &&
        fontSizePt == other.fontSizePt &&
        fontFamily == other.fontFamily &&
        foregroundColor == other.foregroundColor &&
        backgroundColor == other.backgroundColor &&
        horizontalAlign == other.horizontalAlign &&
        verticalAlign == other.verticalAlign &&
        fontScale == other.fontScale &&
        letterSpacing == other.letterSpacing &&
        lineHeight == other.lineHeight &&
        script == other.script &&
        _rtfMapEquals(rtfProperties, other.rtfProperties) &&
        _rtfListEquals(unmappedControls, other.unmappedControls);
  }

  _RtfState copyWith({
    bool? bold,
    bool? hasBold,
    bool? italic,
    bool? hasItalic,
    bool? strikeThrough,
    bool? hasStrikeThrough,
    bool? underline,
    bool? hasUnderline,
    double? fontSizePt,
    bool clearFontSize = false,
    String? fontFamily,
    bool clearFontFamily = false,
    Color? foregroundColor,
    bool clearForegroundColor = false,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    String? horizontalAlign,
    bool clearHorizontalAlign = false,
    String? verticalAlign,
    bool clearVerticalAlign = false,
    double? fontScale,
    bool clearFontScale = false,
    double? letterSpacing,
    bool clearLetterSpacing = false,
    double? lineHeight,
    bool clearLineHeight = false,
    int? lineSpacingTwips,
    bool clearLineSpacingTwips = false,
    bool? lineSpacingMultiple,
    String? script,
    bool clearScript = false,
    Map<String, Object?>? rtfProperties,
    List<String>? unmappedControls,
    int? ucSkip,
  }) {
    return _RtfState(
      bold: bold ?? this.bold,
      hasBold: hasBold ?? this.hasBold,
      italic: italic ?? this.italic,
      hasItalic: hasItalic ?? this.hasItalic,
      strikeThrough: strikeThrough ?? this.strikeThrough,
      hasStrikeThrough: hasStrikeThrough ?? this.hasStrikeThrough,
      underline: underline ?? this.underline,
      hasUnderline: hasUnderline ?? this.hasUnderline,
      fontSizePt: clearFontSize ? null : fontSizePt ?? this.fontSizePt,
      fontFamily: clearFontFamily ? null : fontFamily ?? this.fontFamily,
      foregroundColor: clearForegroundColor
          ? null
          : foregroundColor ?? this.foregroundColor,
      backgroundColor: clearBackgroundColor
          ? null
          : backgroundColor ?? this.backgroundColor,
      horizontalAlign: clearHorizontalAlign
          ? null
          : horizontalAlign ?? this.horizontalAlign,
      verticalAlign: clearVerticalAlign
          ? null
          : verticalAlign ?? this.verticalAlign,
      fontScale: clearFontScale ? null : fontScale ?? this.fontScale,
      letterSpacing: clearLetterSpacing
          ? null
          : letterSpacing ?? this.letterSpacing,
      lineHeight: clearLineHeight ? null : lineHeight ?? this.lineHeight,
      lineSpacingTwips: clearLineSpacingTwips
          ? null
          : lineSpacingTwips ?? this.lineSpacingTwips,
      lineSpacingMultiple: lineSpacingMultiple ?? this.lineSpacingMultiple,
      script: clearScript ? null : script ?? this.script,
      rtfProperties: rtfProperties ?? this.rtfProperties,
      unmappedControls: unmappedControls ?? this.unmappedControls,
      ucSkip: ucSkip ?? this.ucSkip,
    );
  }

  _RtfState withRtfProperty(String key, Object? value) {
    final next = Map<String, Object?>.from(rtfProperties);
    if (value == null || value == false) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return copyWith(rtfProperties: Map.unmodifiable(next));
  }

  _RtfState withUnmappedControl(String word, int? argument) {
    if (unmappedControls.length >= 64) {
      return this;
    }
    return copyWith(
      unmappedControls: List.unmodifiable([
        ...unmappedControls,
        _rtfControlToken(word, argument),
      ]),
    );
  }
}

class _RtfGroupFrame {
  const _RtfGroupFrame({required this.state, required this.skip});

  final _RtfState state;
  final bool skip;
}

class _RtfDocumentReader {
  _RtfDocumentReader(this.rtf)
    : _colorTable = _parseColorTable(rtf),
      _fontTable = _parseFontTable(rtf);

  final String rtf;
  final Map<int, Color> _colorTable;
  final Map<int, String> _fontTable;
  final List<List<_RtfCell>> _rows = [];
  final List<_RtfPicture> _pictures = [];
  final List<int> _preferredCellEdgesTwips = [];
  final List<int?> _rowHeightsTwips = [];
  final List<_RtfGroupFrame> _groups = [];
  final List<_RtfCell> _currentRow = [];
  final List<int> _currentCellEdgesTwips = [];
  final List<_RtfCellFormat> _currentCellFormats = [];
  int? _currentRowHeightTwips;
  final Map<String, _RtfBorderSide> _currentRowBorderSides = {};
  String? _currentRowBorderSide;
  _RtfCellFormat _currentCellFormat = const _RtfCellFormat();
  String? _currentCellBorderSide;
  _RtfCellBuilder _currentCell = _RtfCellBuilder();
  _RtfState _state = const _RtfState();
  bool _skip = false;
  int? _pictureGroupDepth;
  _RtfPictureBuilder? _pictureBuilder;
  bool _inTableRow = false;
  bool _pendingSkipDestination = false;
  int _unicodeFallbackCharsToSkip = 0;
  int _controlWordCount = 0;
  int _controlSymbolCount = 0;
  int _hexByteCount = 0;
  int _textCharCount = 0;

  _RtfDocument read() {
    final stopwatch = Stopwatch()..start();
    _rtfLog('reader start length=${rtf.length}');
    for (var index = 0; index < rtf.length;) {
      final beforeIndex = index;
      if (index < 20 || index % 1000 == 0) {
        _rtfLog(
          'reader progress index=$index/${rtf.length} '
          'groups=${_groups.length} rows=${_rows.length} '
          'currentRow=${_currentRow.length} skip=$_skip inTable=$_inTableRow '
          'elapsedMs=${stopwatch.elapsedMilliseconds}',
        );
      }
      final char = rtf[index];
      if (char == '{') {
        _groups.add(_RtfGroupFrame(state: _state, skip: _skip));
        index += 1;
        _guardReaderProgress(beforeIndex, index, stopwatch);
        continue;
      }
      if (char == '}') {
        if (_pictureBuilder != null && _groups.length == _pictureGroupDepth) {
          _finishPicture();
        }
        if (_groups.isNotEmpty) {
          final frame = _groups.removeLast();
          _state = frame.state;
          _skip = frame.skip;
        }
        index += 1;
        _guardReaderProgress(beforeIndex, index, stopwatch);
        continue;
      }
      if (char == r'\') {
        index = _readControl(index + 1);
        _guardReaderProgress(beforeIndex, index, stopwatch);
        continue;
      }
      if (_pictureBuilder != null) {
        _pictureBuilder!.addHexChar(char);
        index += 1;
        _guardReaderProgress(beforeIndex, index, stopwatch);
        continue;
      }
      if (!_skip && _unicodeFallbackCharsToSkip <= 0) {
        _currentCell.append(char, _state);
        _textCharCount += 1;
      } else if (_unicodeFallbackCharsToSkip > 0) {
        _unicodeFallbackCharsToSkip -= 1;
      }
      index += 1;
      _guardReaderProgress(beforeIndex, index, stopwatch);
    }
    _flushParagraph();
    _rtfLog(
      'reader done elapsedMs=${stopwatch.elapsedMilliseconds} '
      'rows=${_rows.length} controlWords=$_controlWordCount '
      'controlSymbols=$_controlSymbolCount hexBytes=$_hexByteCount '
      'textChars=$_textCharCount openGroups=${_groups.length}',
    );
    return _RtfDocument(
      rows: List.unmodifiable(_rows),
      preferredCellEdgesTwips: List.unmodifiable(_preferredCellEdgesTwips),
      rowHeightsTwips: List.unmodifiable(_rowHeightsTwips),
      pictures: List.unmodifiable(_pictures),
    );
  }

  int _readControl(int index) {
    if (index >= rtf.length) {
      _rtfLog('control at EOF index=$index');
      return index;
    }
    final symbol = rtf[index];
    if (symbol == "'") {
      _readHexByte(index + 1);
      return math.min(index + 3, rtf.length);
    }
    if (!_isLetter(symbol)) {
      _controlSymbolCount += 1;
      if (_controlSymbolCount <= 20 || _controlSymbolCount % 100 == 0) {
        _rtfLog(
          'control symbol count=$_controlSymbolCount symbol=$symbol index=$index skip=$_skip',
        );
      }
      _readControlSymbol(symbol);
      return index + 1;
    }

    final start = index;
    while (index < rtf.length && _isLetter(rtf[index])) {
      index += 1;
    }
    final word = rtf.substring(start, index);
    var sign = 1;
    if (index < rtf.length && rtf[index] == '-') {
      sign = -1;
      index += 1;
    }
    final numberStart = index;
    while (index < rtf.length && _isDigit(rtf[index])) {
      index += 1;
    }
    final hasNumber = index > numberStart;
    final argument = hasNumber
        ? sign * int.parse(rtf.substring(numberStart, index))
        : null;
    if (index < rtf.length && rtf[index] == ' ') {
      index += 1;
    }
    _controlWordCount += 1;
    if (_controlWordCount <= 80 || _controlWordCount % 200 == 0) {
      _rtfLog(
        'control word count=$_controlWordCount word=$word arg=$argument '
        'nextIndex=$index skip=$_skip pendingDest=$_pendingSkipDestination '
        'groups=${_groups.length}',
      );
    }
    _readControlWord(word, argument);
    return index;
  }

  void _guardReaderProgress(
    int beforeIndex,
    int afterIndex,
    Stopwatch stopwatch,
  ) {
    if (afterIndex > beforeIndex) {
      return;
    }
    _rtfLog(
      'reader stalled before=$beforeIndex after=$afterIndex '
      'length=${rtf.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    throw StateError('RTF reader stalled at index $beforeIndex');
  }

  void _readControlSymbol(String symbol) {
    if (symbol == '*') {
      _pendingSkipDestination = true;
      return;
    }
    if (_skip) {
      return;
    }
    switch (symbol) {
      case r'\':
      case '{':
      case '}':
        _currentCell.append(symbol, _state);
      case '~':
        _currentCell.append(' ', _state);
      case '-':
      case '_':
        _currentCell.append('-', _state);
    }
  }

  void _readControlWord(String word, int? argument) {
    if (word == 'pict') {
      _startPicture();
      return;
    }
    final pictureBuilder = _pictureBuilder;
    if (pictureBuilder != null) {
      pictureBuilder.readControlWord(word, argument);
      return;
    }
    if (_rtfDestinationWords.contains(word) || _pendingSkipDestination) {
      _skip = true;
      _pendingSkipDestination = false;
      return;
    }
    _pendingSkipDestination = false;
    if (_skip) {
      return;
    }

    switch (word) {
      case 'b':
        _state = _state.copyWith(bold: argument != 0, hasBold: true);
      case 'i':
        _state = _state.copyWith(italic: argument != 0, hasItalic: true);
      case 'strike':
        _state = _state.copyWith(
          strikeThrough: argument != 0,
          hasStrikeThrough: true,
        );
      case 'ul':
        _state = _state.copyWith(underline: argument != 0, hasUnderline: true);
      case 'ulnone':
        _state = _state.copyWith(underline: false, hasUnderline: true);
      case 'uld':
      case 'uldash':
      case 'uldashd':
      case 'uldashdd':
      case 'uldb':
      case 'ulhwave':
      case 'ulth':
      case 'ulthd':
      case 'ulthdash':
      case 'ulthdashd':
      case 'ulthdashdd':
      case 'ulthldash':
      case 'ululdbwave':
      case 'ulw':
      case 'ulwave':
        _state = _state
            .copyWith(underline: argument != 0, hasUnderline: true)
            .withRtfProperty('rtfUnderlineStyle', word);
      case 'scaps':
        _state = _state.withRtfProperty('rtfSmallCaps', argument != 0);
      case 'caps':
        _state = _state.withRtfProperty('rtfAllCaps', argument != 0);
      case 'v':
        _state = _state.withRtfProperty('rtfHidden', argument != 0);
      case 'outl':
        _state = _state.withRtfProperty('rtfOutline', argument != 0);
      case 'shad':
        _state = _state.withRtfProperty('rtfShadow', argument != 0);
      case 'embo':
        _state = _state.withRtfProperty('rtfEmboss', argument != 0);
      case 'impr':
        _state = _state.withRtfProperty('rtfImprint', argument != 0);
      case 'fs':
        if (argument != null && argument > 0) {
          final fontSizePt = argument / 2;
          _state = _state.copyWith(
            fontSizePt: fontSizePt,
            lineHeight: _rtfLineHeight(
              _state.lineSpacingTwips,
              fontSizePt,
              _state.lineSpacingMultiple,
            ),
          );
        }
      case 'charscalex':
        _state = _state.copyWith(
          fontScale: argument == null || argument <= 0
              ? null
              : argument.toDouble(),
          clearFontScale: argument == null || argument <= 0,
        );
      case 'expnd':
        _state = _state.copyWith(
          letterSpacing: argument == null ? null : argument / 4,
          clearLetterSpacing: argument == null,
        );
      case 'expndtw':
        _state = _state.copyWith(
          letterSpacing: argument == null ? null : argument / 20,
          clearLetterSpacing: argument == null,
        );
      case 'f':
        if (argument != null) {
          final fontFamily = _fontTable[argument];
          if (fontFamily != null && fontFamily.isNotEmpty) {
            _state = _state.copyWith(fontFamily: fontFamily);
          }
        }
      case 'cf':
        _state = _state.copyWith(
          foregroundColor: _colorTable[argument ?? -1],
          clearForegroundColor: argument == null || argument == 0,
        );
      case 'cb':
      case 'highlight':
      case 'clcbpat':
        _state = _state.copyWith(
          backgroundColor: _colorTable[argument ?? -1],
          clearBackgroundColor: argument == null || argument == 0,
        );
      case 'plain':
        _state = _state.copyWith(
          bold: false,
          hasBold: true,
          italic: false,
          hasItalic: true,
          strikeThrough: false,
          hasStrikeThrough: true,
          underline: false,
          hasUnderline: true,
          clearFontSize: true,
          clearFontFamily: true,
          clearForegroundColor: true,
          clearBackgroundColor: true,
          clearFontScale: true,
          clearLetterSpacing: true,
          clearScript: true,
          clearVerticalAlign: true,
          rtfProperties: const <String, Object?>{},
          unmappedControls: const <String>[],
        );
      case 'pard':
        _state = _state.copyWith(
          clearHorizontalAlign: true,
          clearLineHeight: true,
          clearLineSpacingTwips: true,
          lineSpacingMultiple: false,
        );
      case 'ql':
        _state = _state.copyWith(horizontalAlign: 'left');
      case 'qc':
        _state = _state.copyWith(horizontalAlign: 'center');
      case 'qr':
        _state = _state.copyWith(horizontalAlign: 'right');
      case 'qj':
        _state = _state
            .copyWith(horizontalAlign: '3')
            .withRtfProperty('rtfParagraphAlign', 'justify');
      case 'li':
        _state = _state.withRtfProperty('rtfLeftIndentTwips', argument);
      case 'ri':
        _state = _state.withRtfProperty('rtfRightIndentTwips', argument);
      case 'fi':
        _state = _state.withRtfProperty('rtfFirstLineIndentTwips', argument);
      case 'sb':
        _state = _state.withRtfProperty('rtfSpaceBeforeTwips', argument);
      case 'sa':
        _state = _state.withRtfProperty('rtfSpaceAfterTwips', argument);
      case 'sl':
        _state = _state.copyWith(
          lineSpacingTwips: argument,
          clearLineSpacingTwips: argument == null || argument == 0,
          lineHeight: _rtfLineHeight(
            argument,
            _state.fontSizePt,
            _state.lineSpacingMultiple,
          ),
          clearLineHeight: argument == null || argument == 0,
        );
      case 'slmult':
        final multiple = argument == 1;
        _state = _state.copyWith(
          lineSpacingMultiple: multiple,
          lineHeight: _rtfLineHeight(
            _state.lineSpacingTwips,
            _state.fontSizePt,
            multiple,
          ),
          clearLineHeight: _state.lineSpacingTwips == null,
        );
      case 'super':
        _state = _state.copyWith(script: 'superscript');
      case 'sub':
        _state = _state.copyWith(script: 'subscript');
      case 'nosupersub':
        _state = _state.copyWith(clearScript: true);
      case 'up':
        _state = _state.withRtfProperty(
          'rtfBaselineShiftPt',
          argument == null ? null : argument / 2,
        );
      case 'dn':
        _state = _state.withRtfProperty(
          'rtfBaselineShiftPt',
          argument == null ? null : -(argument / 2),
        );
      case 'uc':
        _state = _state.copyWith(ucSkip: math.max(0, argument ?? 1));
      case 'u':
        if (argument != null) {
          _appendUnicode(argument);
        }
      case 'tab':
        _flushCell();
      case 'line':
        if (_inTableRow) {
          _currentCell.append('\n', _state);
        } else {
          _flushParagraph();
        }
      case 'par':
        if (!_inTableRow) {
          _flushParagraph();
        }
      case 'trowd':
        _startTableRow();
      case 'trrh':
        if (argument != null && argument != 0) {
          _currentRowHeightTwips = argument.abs();
        }
      case 'trbrdrl':
        _currentRowBorderSide = 'left';
        _currentCellBorderSide = null;
      case 'trbrdrt':
        _currentRowBorderSide = 'top';
        _currentCellBorderSide = null;
      case 'trbrdrr':
        _currentRowBorderSide = 'right';
        _currentCellBorderSide = null;
      case 'trbrdrb':
        _currentRowBorderSide = 'bottom';
        _currentCellBorderSide = null;
      case 'clmgf':
        _currentCellFormat = _currentCellFormat.copyWith(
          horizontalMergeStart: true,
          horizontalMergeContinuation: false,
        );
      case 'clmrg':
        _currentCellFormat = _currentCellFormat.copyWith(
          horizontalMergeStart: false,
          horizontalMergeContinuation: true,
        );
      case 'clvmgf':
        _currentCellFormat = _currentCellFormat.copyWith(
          verticalMergeStart: true,
          verticalMergeContinuation: false,
        );
      case 'clvmrg':
        _currentCellFormat = _currentCellFormat.copyWith(
          verticalMergeStart: false,
          verticalMergeContinuation: true,
        );
      case 'clvertalt':
        _currentCellFormat = _currentCellFormat.copyWith(verticalAlign: 'top');
      case 'clvertalc':
        _currentCellFormat = _currentCellFormat.copyWith(
          verticalAlign: 'middle',
        );
      case 'clvertalb':
        _currentCellFormat = _currentCellFormat.copyWith(
          verticalAlign: 'bottom',
        );
      case 'clbrdrl':
        _currentCellBorderSide = 'left';
        _currentRowBorderSide = null;
      case 'clbrdrt':
        _currentCellBorderSide = 'top';
        _currentRowBorderSide = null;
      case 'clbrdrr':
        _currentCellBorderSide = 'right';
        _currentRowBorderSide = null;
      case 'clbrdrb':
        _currentCellBorderSide = 'bottom';
        _currentRowBorderSide = null;
      case 'brdrs':
        _updateCurrentBorder(style: 'solid');
      case 'brdrdb':
        _updateCurrentBorder(style: 'double');
      case 'brdrdot':
        _updateCurrentBorder(style: 'dotted');
      case 'brdrdash':
      case 'brdrdashd':
      case 'brdrdashdd':
        _updateCurrentBorder(style: 'dashed');
      case 'brdrnone':
        _updateCurrentBorder(style: 'none');
      case 'brdrw':
        if (argument != null) {
          _updateCurrentBorder(widthTwips: argument.abs());
        }
      case 'brdrcf':
        _updateCurrentBorder(color: _colorTable[argument ?? -1]);
      case 'intbl':
        _inTableRow = true;
      case 'cellx':
        if (argument != null && argument > 0) {
          _currentCellEdgesTwips.add(argument);
          _currentCellFormats.add(_currentCellFormat);
          _currentCellFormat = const _RtfCellFormat();
          _currentCellBorderSide = null;
          _currentRowBorderSide = null;
        }
      case 'cell':
        _flushCell(force: true);
      case 'row':
        _flushTableRow();
      default:
        _state = _state.withUnmappedControl(word, argument);
    }
  }

  void _readHexByte(int index) {
    final pictureBuilder = _pictureBuilder;
    if (pictureBuilder != null) {
      if (index + 1 < rtf.length) {
        final value = int.tryParse(rtf.substring(index, index + 2), radix: 16);
        if (value != null) {
          pictureBuilder.addHexByte(value);
        }
      }
      return;
    }
    if (_skip || index + 1 >= rtf.length) {
      _rtfLog('hex byte skipped index=$index skip=$_skip length=${rtf.length}');
      return;
    }
    final value = int.tryParse(rtf.substring(index, index + 2), radix: 16);
    if (value == null) {
      _rtfLog(
        'hex byte invalid index=$index raw=${rtf.substring(index, math.min(index + 2, rtf.length))}',
      );
      return;
    }
    _hexByteCount += 1;
    if (_hexByteCount <= 20 || _hexByteCount % 100 == 0) {
      _rtfLog('hex byte count=$_hexByteCount index=$index value=$value');
    }
    _currentCell.append(String.fromCharCode(value), _state);
  }

  void _appendUnicode(int signedCodeUnit) {
    var codeUnit = signedCodeUnit;
    if (codeUnit < 0) {
      codeUnit += 65536;
    }
    if (codeUnit >= 0 && codeUnit <= 0x10ffff) {
      _currentCell.append(String.fromCharCode(codeUnit), _state);
    }
    _unicodeFallbackCharsToSkip = _state.ucSkip;
  }

  void _updateCurrentBorder({String? style, int? widthTwips, Color? color}) {
    final rowSide = _currentRowBorderSide;
    if (rowSide != null) {
      final current = _currentRowBorderSides[rowSide] ?? const _RtfBorderSide();
      _currentRowBorderSides[rowSide] = current.copyWith(
        style: style,
        widthTwips: widthTwips,
        color: color,
      );
      return;
    }
    final side = _currentCellBorderSide;
    if (side == null) {
      return;
    }
    final current =
        _currentCellFormat.borderSides[side] ?? const _RtfBorderSide();
    _currentCellFormat = _currentCellFormat.withBorderSide(
      side,
      current.copyWith(style: style, widthTwips: widthTwips, color: color),
    );
  }

  void _startTableRow() {
    _rtfLog(
      'table row start rows=${_rows.length} currentRow=${_currentRow.length} '
      'cellEmpty=${_currentCell.isEmpty}',
    );
    if (_currentRow.isNotEmpty || !_currentCell.isEmpty) {
      _flushTableRow();
    }
    _inTableRow = true;
    _currentRow.clear();
    _currentCellEdgesTwips.clear();
    _currentCellFormats.clear();
    _currentRowHeightTwips = null;
    _currentRowBorderSides.clear();
    _currentRowBorderSide = null;
    _currentCellFormat = const _RtfCellFormat();
    _currentCellBorderSide = null;
    _currentCell = _RtfCellBuilder();
  }

  void _flushCell({bool force = false}) {
    if (!force && _currentCell.isEmpty) {
      _rtfLog(
        'cell flush skipped empty force=$force currentRow=${_currentRow.length}',
      );
      _currentCell = _RtfCellBuilder();
      return;
    }
    final format = _currentRow.length < _currentCellFormats.length
        ? _currentCellFormats[_currentRow.length]
        : const _RtfCellFormat();
    _currentRow.add(_currentCell.build(format));
    _rtfLog('cell flushed force=$force currentRow=${_currentRow.length}');
    _currentCell = _RtfCellBuilder();
  }

  void _flushParagraph() {
    if (_inTableRow) {
      _rtfLog(
        'paragraph flush skipped because inTableRow currentRow=${_currentRow.length}',
      );
      return;
    }
    _flushCell();
    if (_currentRow.any((cell) => cell.text.trim().isNotEmpty)) {
      _rows.add(List.unmodifiable(_currentRow));
      _rowHeightsTwips.add(null);
      _rtfLog(
        'paragraph flushed rows=${_rows.length} cells=${_currentRow.length}',
      );
    }
    _currentRow.clear();
  }

  void _flushTableRow() {
    _flushCell();
    if (_currentRow.any((cell) => cell.isStructurallyRelevant)) {
      _rows.add(List.unmodifiable(_rowWithRowBorders()));
      _rtfLog(
        'table row flushed rows=${_rows.length} cells=${_currentRow.length} '
        'edges=${_currentCellEdgesTwips.length}',
      );
      if (_currentCellEdgesTwips.length > _preferredCellEdgesTwips.length) {
        _preferredCellEdgesTwips
          ..clear()
          ..addAll(_currentCellEdgesTwips);
      }
      _rowHeightsTwips.add(_currentRowHeightTwips);
    }
    _currentRow.clear();
    _currentCellEdgesTwips.clear();
    _currentCellFormats.clear();
    _currentRowHeightTwips = null;
    _currentRowBorderSides.clear();
    _currentRowBorderSide = null;
    _currentCellFormat = const _RtfCellFormat();
    _currentCellBorderSide = null;
    _currentCell = _RtfCellBuilder();
    _inTableRow = false;
  }

  List<_RtfCell> _rowWithRowBorders() {
    if (_currentRowBorderSides.isEmpty || _currentRow.isEmpty) {
      return List<_RtfCell>.from(_currentRow);
    }
    final lastColumn = _currentRow.length - 1;
    return [
      for (var column = 0; column < _currentRow.length; column += 1)
        _currentRow[column].copyWithAdditionalBorders(
          _rowBordersForColumn(column: column, lastColumn: lastColumn),
        ),
    ];
  }

  Map<String, _RtfBorderSide> _rowBordersForColumn({
    required int column,
    required int lastColumn,
  }) {
    final borders = <String, _RtfBorderSide>{};
    final top = _currentRowBorderSides['top'];
    if (top != null) {
      borders['top'] = top;
    }
    final bottom = _currentRowBorderSides['bottom'];
    if (bottom != null) {
      borders['bottom'] = bottom;
    }
    final left = _currentRowBorderSides['left'];
    if (column == 0 && left != null) {
      borders['left'] = left;
    }
    final right = _currentRowBorderSides['right'];
    if (column == lastColumn && right != null) {
      borders['right'] = right;
    }
    return borders;
  }

  void _startPicture() {
    _pictureBuilder = _RtfPictureBuilder(
      row: _rows.length,
      column: _currentRow.length,
    );
    _pictureGroupDepth = _groups.length;
    _pendingSkipDestination = false;
    _skip = false;
  }

  void _finishPicture() {
    final picture = _pictureBuilder?.build();
    if (picture != null) {
      _pictures.add(picture);
      _rtfLog(
        'picture parsed count=${_pictures.length} type=${picture.type} '
        'bytes=${picture.bytes.length} row=${picture.row} column=${picture.column}',
      );
    }
    _pictureBuilder = null;
    _pictureGroupDepth = null;
  }

  bool _isLetter(String value) {
    final codeUnit = value.codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) ||
        (codeUnit >= 97 && codeUnit <= 122);
  }

  bool _isDigit(String value) {
    final codeUnit = value.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }
}

Map<int, Color> _parseColorTable(String rtf) {
  final group = _rtfDestinationGroup(rtf, 'colortbl');
  if (group == null) {
    return const <int, Color>{};
  }
  final colors = <int, Color>{};
  var index = 0;
  var red = 0;
  var green = 0;
  var blue = 0;
  var hasComponent = false;
  final tokenPattern = RegExp(r'\\(red|green|blue)(-?\d+)|;');
  for (final match in tokenPattern.allMatches(group)) {
    final separator = match.group(0) == ';';
    if (separator) {
      if (hasComponent) {
        colors[index] = Color.fromARGB(
          0xff,
          red.clamp(0, 255),
          green.clamp(0, 255),
          blue.clamp(0, 255),
        );
      }
      index += 1;
      red = 0;
      green = 0;
      blue = 0;
      hasComponent = false;
      continue;
    }
    final value = int.tryParse(match.group(2) ?? '') ?? 0;
    switch (match.group(1)) {
      case 'red':
        red = value;
      case 'green':
        green = value;
      case 'blue':
        blue = value;
    }
    hasComponent = true;
  }
  return Map.unmodifiable(colors);
}

Map<int, String> _parseFontTable(String rtf) {
  final group = _rtfDestinationGroup(rtf, 'fonttbl');
  if (group == null) {
    return const <int, String>{};
  }
  final fonts = <int, String>{};
  final fontPattern = RegExp(r'{\\f(\d+)(?:[^{};]*?\s)?([^{};\\][^{};]*)?;}');
  for (final match in fontPattern.allMatches(group)) {
    final index = int.tryParse(match.group(1) ?? '');
    final name = _cleanRtfFontName(match.group(2));
    if (index != null && name != null && name.isNotEmpty) {
      fonts[index] = name;
    }
  }
  return Map.unmodifiable(fonts);
}

String? _rtfDestinationGroup(String rtf, String destination) {
  final marker = '\\$destination';
  final markerIndex = rtf.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }
  var start = markerIndex;
  while (start >= 0 && rtf[start] != '{') {
    start -= 1;
  }
  if (start < 0) {
    return null;
  }
  var depth = 0;
  for (var index = start; index < rtf.length; index += 1) {
    final char = rtf[index];
    if (char == '\\') {
      index += 1;
      continue;
    }
    if (char == '{') {
      depth += 1;
    } else if (char == '}') {
      depth -= 1;
      if (depth == 0) {
        return rtf.substring(start, index + 1);
      }
    }
  }
  return null;
}

String? _cleanRtfFontName(String? value) {
  if (value == null) {
    return null;
  }
  final cleaned = value
      .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d*\s?'), '')
      .replaceAll(RegExp(r'[{};]'), '')
      .trim();
  return cleaned.isEmpty ? null : cleaned;
}

const Set<String> _rtfDestinationWords = {
  'fonttbl',
  'colortbl',
  'stylesheet',
  'info',
  'object',
  'datastore',
  'themedata',
  'colorschememapping',
  'generator',
  'listtable',
  'listoverridetable',
  'revtbl',
};
