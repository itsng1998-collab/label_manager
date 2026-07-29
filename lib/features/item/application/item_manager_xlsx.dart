import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_xlsx_import.dart';
import 'package:label_manager/features/item/item_manager_debug_log.dart';
import 'package:path/path.dart' as p;

class ItemManagerXlsxColumn {
  const ItemManagerXlsxColumn({
    required this.columnId,
    required this.name,
    required this.editable,
    required this.typeCode,
  });

  final int columnId;
  final String name;
  final bool editable;
  final int typeCode;
}

class ItemManagerXlsxImportResult {
  const ItemManagerXlsxImportResult({
    required this.rows,
    this.warnings = const [],
  });

  final List<ItemManagerImportedRow> rows;
  final List<String> warnings;
}

Uint8List itemManagerExportXlsxBytes({
  required List<ItemManagerDraftRow> rows,
  required List<ItemManagerXlsxColumn> columns,
  required String Function(
    ItemManagerDraftRow row,
    ItemManagerXlsxColumn column,
  )
  columnValue,
}) {
  final trace = ItemManagerDebugLog.nextTrace('xlsxWriter');
  ItemManagerDebugLog.event(
    'xlsxWriter',
    'started',
    trace: trace,
    fields: {'rows': rows.length, 'columns': columns.length},
  );
  if (rows.isEmpty) {
    throw StateError('Excel로 저장할 데이터가 없습니다.');
  }
  final headers = ['품목', '주원료', ...columns.map((column) => column.name)];
  final sheetXml = StringBuffer(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
    '<dimension ref="A1:${_xlsxColumnName(headers.length - 1)}${rows.length + 1}"/>'
    '<sheetData>',
  );
  _writeInlineStringRow(sheetXml, 1, headers);
  for (var index = 0; index < rows.length; index += 1) {
    final row = rows[index];
    _writeInlineStringRow(sheetXml, index + 2, [
      row.itemName,
      row.elementPlain,
      for (final column in columns) columnValue(row, column),
    ]);
  }
  sheetXml.write('</sheetData></worksheet>');

  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            '</Types>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            '</Relationships>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/workbook.xml',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '<sheets><sheet name="품목관리" sheetId="1" r:id="rId1"/></sheets>'
            '</workbook>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
            '</Relationships>',
      ),
    )
    ..addFile(
      ArchiveFile.string('xl/worksheets/sheet1.xml', sheetXml.toString()),
    );
  final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  ItemManagerDebugLog.event(
    'xlsxWriter',
    'completed',
    trace: trace,
    fields: {'bytes': bytes.length},
  );
  return bytes;
}

void _writeInlineStringRow(
  StringBuffer output,
  int rowNumber,
  List<String> values,
) {
  output.write('<row r="$rowNumber">');
  for (var index = 0; index < values.length; index += 1) {
    final reference = '${_xlsxColumnName(index)}$rowNumber';
    output.write(
      '<c r="$reference" t="inlineStr"><is><t xml:space="preserve">'
      '${_xmlEscape(values[index])}</t></is></c>',
    );
  }
  output.write('</row>');
}

String _xlsxColumnName(int index) {
  if (index < 0) throw ArgumentError.value(index, 'index');
  var value = index + 1;
  final result = StringBuffer();
  while (value > 0) {
    value -= 1;
    result.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return result.toString().split('').reversed.join();
}

String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

ItemManagerXlsxImportResult itemManagerImportXlsxBytes(
  Uint8List bytes, {
  required List<ItemManagerXlsxColumn> columns,
  required String emptyElementPayload,
}) {
  final trace = ItemManagerDebugLog.nextTrace('xlsxParser');
  ItemManagerDebugLog.event(
    'xlsxParser',
    'started',
    trace: trace,
    fields: {'bytes': bytes.length, 'columns': columns.length},
  );
  if (!labelSheetLooksLikeXlsx(bytes)) {
    throw const FormatException('지원하지 않는 Excel 파일 형식입니다. .xlsx 파일을 선택해 주세요.');
  }
  final context = labelSheetXlsxParseContext(bytes, sheetIndex: 0);
  final sheet = context.parsedWorkbook.activeSheet;
  final rowCount = sheet.rowCount ?? 0;
  final columnCount = sheet.columnCount ?? 0;
  ItemManagerDebugLog.event(
    'xlsxParser',
    'sheetParsed',
    trace: trace,
    fields: {'rows': rowCount, 'columns': columnCount},
  );
  final descriptors = <String, _ItemManagerHeader>{
    '품목': const _ItemManagerHeader.item(),
    '주원료': const _ItemManagerHeader.element(),
    for (final column in columns)
      column.name: _ItemManagerHeader.column(column),
  };
  final mappedHeaders = <int, _ItemManagerHeader>{};
  final usedNames = <String>{};
  int? blankHeaderColumn;
  for (var columnIndex = 0; columnIndex < columnCount; columnIndex += 1) {
    final header = _cellDisplayText(context, 0, columnIndex).trim();
    if (header.isEmpty) {
      blankHeaderColumn = columnIndex;
      break;
    }
    final descriptor = descriptors[header];
    if (descriptor != null && usedNames.add(header)) {
      mappedHeaders[columnIndex] = descriptor;
    }
  }
  if (!mappedHeaders.values.any((header) => header.kind == _HeaderKind.item)) {
    throw const FormatException('첫 번째 worksheet의 1행에 품목 헤더가 없습니다.');
  }

  final warnings = <String>[];
  if (blankHeaderColumn != null) {
    for (
      var columnIndex = blankHeaderColumn + 1;
      columnIndex < columnCount;
      columnIndex += 1
    ) {
      if (descriptors.containsKey(
        _cellDisplayText(context, 0, columnIndex).trim(),
      )) {
        warnings.add('빈 헤더 뒤의 컬럼은 가져오지 않습니다.');
        break;
      }
    }
  }

  final rows = <ItemManagerImportedRow>[];
  for (var rowIndex = 1; rowIndex < rowCount; rowIndex += 1) {
    final values = <int, String>{
      for (final columnIndex in mappedHeaders.keys)
        columnIndex: _cellDisplayText(context, rowIndex, columnIndex),
    };
    if (values.values.every((value) => value.isEmpty)) continue;
    if (rows.length >= ItemManagerLimits.maxRows) {
      throw StateError('품목은 최대 ${ItemManagerLimits.maxRows}개까지 가져올 수 있습니다.');
    }
    var itemName = '';
    var elementPlain = '';
    var elementPayload = emptyElementPayload;
    final columnDrafts = <int, ItemManagerColumnDraft>{};
    for (final entry in mappedHeaders.entries) {
      final descriptor = entry.value;
      var value = values[entry.key] ?? '';
      switch (descriptor.kind) {
        case _HeaderKind.item:
          itemName = value;
        case _HeaderKind.element:
          elementPlain = value;
          if (value.isNotEmpty ||
              sheet.cells.containsKey(FortuneCellCoord(rowIndex, entry.key))) {
            elementPayload = _elementPayload(sheet, rowIndex, entry.key);
          }
        case _HeaderKind.column:
          final column = descriptor.column!;
          if (column.typeCode == TColumnType.TYPE_IMAGE) {
            value = _normalizeImageValue(value);
          }
          columnDrafts[column.columnId] = ItemManagerColumnDraft(
            editable: column.editable,
            dataString: value,
          );
      }
    }
    rows.add(
      ItemManagerImportedRow(
        itemName: itemName,
        elementPlain: elementPlain,
        elementPayload: elementPayload,
        columnDrafts: Map.unmodifiable(columnDrafts),
      ),
    );
  }
  if (rows.isEmpty) {
    throw const FormatException('Excel 파일에 가져올 품목 데이터가 없습니다.');
  }
  ItemManagerDebugLog.event(
    'xlsxParser',
    'completed',
    trace: trace,
    fields: {
      'rows': rows.length,
      'warnings': warnings.length,
      'mappedHeaders': mappedHeaders.length,
    },
  );
  return ItemManagerXlsxImportResult(
    rows: List.unmodifiable(rows),
    warnings: List.unmodifiable(warnings),
  );
}

enum _HeaderKind { item, element, column }

class _ItemManagerHeader {
  const _ItemManagerHeader.item() : kind = _HeaderKind.item, column = null;
  const _ItemManagerHeader.element()
    : kind = _HeaderKind.element,
      column = null;
  const _ItemManagerHeader.column(this.column) : kind = _HeaderKind.column;

  final _HeaderKind kind;
  final ItemManagerXlsxColumn? column;
}

String _cellDisplayText(
  LabelSheetXlsxParseContext context,
  int row,
  int column,
) {
  final coord = FortuneCellCoord(row, column);
  final metadata = context.cellMetadata[coord];
  final cell = context.parsedWorkbook.activeSheet.cells[coord];
  if (metadata?.formula != null && metadata?.hasCachedValue != true) return '';
  final type = metadata?.cellType;
  if (type == 's' || type == 'inlineStr' || type == 'str') {
    var value = metadata?.parsedText ?? cell?.renderedText ?? '';
    if (metadata?.quotePrefix == true && value.startsWith("'")) {
      value = value.substring(1);
    }
    return value;
  }
  final rawValue = metadata?.rawValue;
  if (rawValue == null || rawValue.isEmpty) return cell?.renderedText ?? '';
  final numeric = double.tryParse(rawValue);
  if (numeric == null) return metadata?.parsedText ?? rawValue;
  return _formatNumeric(
    numeric,
    metadata?.formatCode,
    uses1904DateSystem: context.workbookUses1904DateSystem,
  );
}

String _formatNumeric(
  double value,
  String? formatCode, {
  required bool uses1904DateSystem,
}) {
  final format = (formatCode ?? '').split(';').first.toLowerCase();
  final dateFormat = _datePattern(format);
  if (dateFormat != null) {
    final base = uses1904DateSystem
        ? DateTime.utc(1904, 1, 1)
        : DateTime.utc(1899, 12, 30);
    return DateFormat(dateFormat).format(
      base.add(
        Duration(milliseconds: (value * Duration.millisecondsPerDay).round()),
      ),
    );
  }
  if (_looksLikeTime(format)) {
    final totalSeconds = (value * Duration.secondsPerDay).round();
    final hours = (totalSeconds ~/ 3600) % 24;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;
    final base =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    return format.contains('s')
        ? '$base:${seconds.toString().padLeft(2, '0')}'
        : base;
  }
  final decimalMatch = RegExp(r'\.([0#]+)').firstMatch(format);
  final decimals = decimalMatch?.group(1)?.length;
  if (decimals != null) {
    return NumberFormat(
      '${format.contains(',') ? '#,##0' : '0'}.${'0' * decimals}',
    ).format(value);
  }
  if (format.contains(',')) return NumberFormat('#,##0').format(value);
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toString();
}

String? _datePattern(String format) {
  final normalized = format.replaceAll(RegExp(r'\[[^\]]+\]|"[^"]*"'), '');
  if (!RegExp(r'[yd]').hasMatch(normalized)) return null;
  final separator = normalized.contains('/')
      ? '/'
      : normalized.contains('.')
      ? '.'
      : '-';
  return 'yyyy${separator}MM${separator}dd';
}

bool _looksLikeTime(String format) =>
    format.contains('h') && (format.contains('m') || format.contains('s'));

String _normalizeImageValue(String value) {
  if (value.isEmpty) return value;
  final fileName = p.basename(value.replaceAll('\\', '/'));
  return fileName.toLowerCase().endsWith('.bmp')
      ? fileName.substring(0, fileName.length - 4)
      : fileName;
}

String _elementPayload(FortuneSheet source, int row, int column) {
  final sourceCell = source.cells[FortuneCellCoord(row, column)];
  final merge = sourceCell?.merge;
  final startRow = merge?.row ?? row;
  final startColumn = merge?.column ?? column;
  final rowSpan = merge?.rowSpan ?? 1;
  final columnSpan = merge?.columnSpan ?? 1;
  final cells = <FortuneCellCoord, FortuneCell>{};
  for (var rowOffset = 0; rowOffset < rowSpan; rowOffset += 1) {
    for (var columnOffset = 0; columnOffset < columnSpan; columnOffset += 1) {
      final cell =
          source.cells[FortuneCellCoord(
            startRow + rowOffset,
            startColumn + columnOffset,
          )];
      if (cell == null) continue;
      cells[FortuneCellCoord(rowOffset, columnOffset)] = cell.copyWith(
        merge: cell.merge?.copyWith(
          row: cell.merge!.row - startRow,
          column: cell.merge!.column - startColumn,
        ),
      );
    }
  }
  final borders = <FortuneBorderInfo>[];
  for (final border in source.borderInfo) {
    final ranges = <FortuneRange>[];
    for (final range in border.ranges) {
      final rowStart = range.rowStart.clamp(startRow, startRow + rowSpan - 1);
      final rowEnd = range.rowEnd.clamp(startRow, startRow + rowSpan - 1);
      final columnStart = range.columnStart.clamp(
        startColumn,
        startColumn + columnSpan - 1,
      );
      final columnEnd = range.columnEnd.clamp(
        startColumn,
        startColumn + columnSpan - 1,
      );
      if (rowStart > rowEnd || columnStart > columnEnd) continue;
      ranges.add(
        FortuneRange(
          rowStart: rowStart - startRow,
          rowEnd: rowEnd - startRow,
          columnStart: columnStart - startColumn,
          columnEnd: columnEnd - startColumn,
        ),
      );
    }
    if (ranges.isNotEmpty) borders.add(border.copyWith(ranges: ranges));
  }
  final sheet = FortuneSheet(
    id: 'item_element',
    name: '주원료 및 함량',
    rowCount: rowSpan,
    columnCount: columnSpan,
    cells: cells,
    rowHeights: {
      for (var index = 0; index < rowSpan; index += 1)
        index: ?source.rowHeights[startRow + index],
    },
    columnWidths: {
      for (var index = 0; index < columnSpan; index += 1)
        index: ?source.columnWidths[startColumn + index],
    },
    customHeight: {
      for (var index = 0; index < rowSpan; index += 1)
        index: ?source.customHeight[startRow + index],
    },
    customWidth: {
      for (var index = 0; index < columnSpan; index += 1)
        index: ?source.customWidth[startColumn + index],
    },
    borderInfo: borders,
  );
  return labelSheetEncodeWorkbookSave(FortuneWorkbook(sheets: [sheet]));
}
