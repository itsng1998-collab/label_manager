// ignore_for_file: use_null_aware_elements

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:path/path.dart' as p;

// =============================================================================
// XLSX → 라벨 시트 변환 규칙 (사용자 확정 사양 / 수정 시 반드시 준수)
//
// 목적: .xlsx 엑셀을 라벨 시트로 가져오기. 원본과 최대한 100% 동일하게 변환한다.
//
// A. 테두리
//   1. 엑셀 셀 테두리 속성(방향/스타일·두께/색)을 그대로 1:1 변환한다.
//      임의 변형 금지: thick→thin 다운캐스트, 없는 선 합성, 헤더/외곽 특수처리 등 금지.
//   2. 엑셀에 테두리가 없는 셀은 변환본에도 테두리가 없어야 한다.
//      (변환본에 없던 선이 생기면 그것은 변환 버그다.)
//   ※ "특정 표 외에는 테두리 없음"은 규칙이 아니다. 엑셀에 테두리가 있으면
//      어느 영역이든 그대로 가져온다(엑셀에 있는 회색 격자/검은 선 모두 포함).
//
// B. 일반화
//   4. 특정 파일 전용 하드코딩 금지: 특정 텍스트('영양정보' 등), 고정 크기(rowStart+7 등),
//      특정 좌표 기반 분기 금지. 모든 라벨 xlsx에 통용되는 순수 매핑만 사용한다.
//
// C. 스케일 (label_sheet_workbench.dart 가져오기 경로에서 적용)
//   5. 물리 라벨 크기에 맞게 스케일 조정. 넓이(폭) 우선, 폭 대비 비율로 높이를 맞춘다.
//   6. 폭 기준 축소 후 문자가 사람이 못 읽을 정도면 최소 가독 문자 기준으로 다시 키운다.
//      이때 인쇄 영역을 벗어나도 무방하다.
//   7. 가독 기준은 화면상이 아니라 실물 라벨 프린트 기준(mm 단위)이다.
//
// D. 폰트/텍스트
//   8. 엑셀 폰트 속성(글꼴/크기/굵게·기울임·밑줄·취소선/글자색)을 그대로 1:1 변환한다.
//   9. 자간(letter spacing)/장평(font scale·width)/첨자(super·subscript)/줄간격(line height)도
//      엑셀 속성에 따라 그대로 변환한다. 단 폰트 '크기'만 규칙 5·6에 따라 비례 조정하고,
//      그 외 속성 자체는 유지한다.
// =============================================================================

void _xlsxImportLog(String message) {
  debugLog('xlsx import $message', skipFrames: 1);
}

bool labelSheetLooksLikeXlsx(Uint8List bytes) {
  _xlsxImportLog('probe start bytes=${bytes.length}');
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final result = _tryXlsxText(archive, 'xl/workbook.xml') != null;
    _xlsxImportLog(
      'probe result=$result entries=${archive.files.length} '
      'sample=${_archiveEntrySample(archive)}',
    );
    return result;
  } catch (error) {
    _xlsxImportLog('probe failed error=$error');
    return false;
  }
}

FortuneWorkbook labelSheetWorkbookFromXlsxBytes(Uint8List bytes) {
  _xlsxImportLog('decode start bytes=${bytes.length}');
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    _xlsxImportLog(
      'zip decoded entries=${archive.files.length} '
      'sample=${_archiveEntrySample(archive)}',
    );
    final workbookXml = _xlsxText(archive, 'xl/workbook.xml');
    _xlsxImportLog('workbook.xml loaded chars=${workbookXml.length}');
    final workbookRelsXml = _xlsxText(archive, 'xl/_rels/workbook.xml.rels');
    _xlsxImportLog('workbook rels loaded chars=${workbookRelsXml.length}');
    final sheetInfo = _activeSheetInfo(workbookXml);
    _xlsxImportLog(
      'active sheet name=${sheetInfo.name} relId=${sheetInfo.relationshipId}',
    );
    final sheetPath = _worksheetPath(workbookRelsXml, sheetInfo.relationshipId);
    _xlsxImportLog('worksheet path resolved path=$sheetPath');
    final sheetXml = _xlsxText(archive, sheetPath);
    _xlsxImportLog('worksheet loaded chars=${sheetXml.length}');
    final sheetRels = _worksheetRelationships(archive, sheetPath);
    _xlsxImportLog('worksheet relationships count=${sheetRels.length}');
    final styles = _XlsxStyleTable.fromArchive(archive);
    final sharedStrings = _XlsxSharedStrings.fromArchive(archive);
    final metadata = _XlsxExtensionMetadata.fromArchive(archive);
    _xlsxImportLog(
      'resources loaded styles=${styles.formats.length} fonts=${styles.fonts.length} '
      'fills=${styles.fills.length} borders=${styles.borders.length} '
      'sharedStrings=${sharedStrings.length} metadataCells=${metadata.cellCount} '
      'metadataRuns=${metadata.runCount}',
    );
    final sheetJson = _sheetJsonFromWorksheet(
      sheetXml,
      sheetName: sheetInfo.name,
      sharedStrings: sharedStrings,
      styles: styles,
      relationships: sheetRels,
      metadata: metadata,
    );
    final workbook = FortuneSheetCodec.workbookFromJson({
      'data': [sheetJson],
    });
    _logDecodedSheetSample(workbook.activeSheet);
    _xlsxImportLog(
      'decode success sheets=${workbook.sheets.length} '
      'activeRows=${workbook.activeSheet.rowCount} '
      'activeColumns=${workbook.activeSheet.columnCount} '
      'cells=${workbook.activeSheet.cells.length}',
    );
    return workbook;
  } catch (error, stackTrace) {
    _xlsxImportLog('decode failed error=$error\n$stackTrace');
    rethrow;
  }
}

String _archiveEntrySample(Archive archive) {
  return [
    for (final file in archive.files.take(40)) file.name.replaceAll('\\', '/'),
  ].join('|');
}

String _xlsxText(Archive archive, String path) {
  final normalizedPath = path.replaceAll('\\', '/');
  _xlsxImportLog('entry lookup path=$normalizedPath');
  for (final file in archive.files) {
    if (!file.isFile || file.name.replaceAll('\\', '/') != normalizedPath) {
      continue;
    }
    final bytes = file.readBytes();
    if (bytes == null) {
      break;
    }
    _xlsxImportLog('entry found path=$normalizedPath bytes=${bytes.length}');
    return _normalizeXmlTagPrefixes(utf8.decode(bytes));
  }
  _xlsxImportLog('entry missing path=$normalizedPath');
  throw FormatException('Missing XLSX entry: $normalizedPath');
}

String _normalizeXmlTagPrefixes(String xml) {
  return xml.replaceAllMapped(
    RegExp(r'<(/?)[A-Za-z_][\w.-]*:'),
    (match) => '<${match.group(1) ?? ''}',
  );
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
    _xlsxImportLog('workbook has no sheet tags');
    throw const FormatException('XLSX workbook has no sheets');
  }
  final activeTab = int.tryParse(
    _firstTagAttributes(workbookXml, 'workbookView')?['activeTab'] ?? '',
  );
  final index = activeTab == null ? 0 : activeTab.clamp(0, sheets.length - 1);
  final sheet = sheets[index];
  final relationshipId = sheet['r:id'] ?? sheet['id'];
  if (relationshipId == null || relationshipId.isEmpty) {
    _xlsxImportLog('active sheet relationship missing attributes=$sheet');
    throw const FormatException('XLSX sheet relationship is missing');
  }
  final name = sheet['name']?.trim();
  return (
    name: name == null || name.isEmpty ? 'Sheet${index + 1}' : name,
    relationshipId: relationshipId,
  );
}

String _worksheetPath(String relationshipsXml, String relationshipId) {
  var relationshipCount = 0;
  for (final relationship in _relationships(relationshipsXml)) {
    relationshipCount += 1;
    _xlsxImportLog(
      'workbook relationship id=${relationship.id} target=${relationship.target} '
      'type=${relationship.type}',
    );
    if (relationship.id != relationshipId) {
      continue;
    }
    return _packageTargetPath('xl', relationship.target);
  }
  _xlsxImportLog(
    'worksheet relationship not found relId=$relationshipId '
    'relationshipCount=$relationshipCount',
  );
  throw FormatException(
    'XLSX worksheet relationship not found: $relationshipId',
  );
}

String _packageTargetPath(String baseDirectory, String target) {
  final normalizedTarget = target.replaceAll('\\', '/');
  if (normalizedTarget.startsWith('/')) {
    return p.url.normalize(normalizedTarget.substring(1));
  }
  return p.url.normalize(p.url.join(baseDirectory, normalizedTarget));
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
    _xlsxImportLog('worksheet rels missing path=$relsPath');
    return const <String, _XlsxRelationship>{};
  }
  final result = {
    for (final relationship in _relationships(xml))
      relationship.id: relationship,
  };
  _xlsxImportLog('worksheet rels loaded path=$relsPath count=${result.length}');
  return result;
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
  final sourceRowHeights = <String, Object?>{};
  final sourceColumnWidths = <String, Object?>{};
  final hiddenRows = <String, Object?>{};
  final hiddenColumns = <String, Object?>{};
  final borderInfo = <Map<String, Object?>>[];
  final hyperlinks = <String, Object?>{};
  final mergeMap = <String, Map<String, Object?>>{};
  final valueSamples = <String>[];
  final styleSamples = <String>[];
  final wrapSamples = <String>[];
  final lineBreakSamples = <String>[];
  final borderSamples = <String>[];
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
        sourceColumnWidths['$columnIndex'] = column.width;
        columnWidths['$columnIndex'] = _columnWidthToLogicalPixels(
          column.width!,
        );
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
    r'<row\b([^>]*)/>|<row\b([^>]*)>(.*?)</row>',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(xml)) {
    final rowAttributes = _xmlAttributes(
      rowMatch.group(1) ?? rowMatch.group(2) ?? '',
    );
    final rowNumber = int.tryParse(rowAttributes['r'] ?? '') ?? 0;
    final rowIndex = rowNumber > 0 ? rowNumber - 1 : maxRow;
    final rowHeight = double.tryParse(rowAttributes['ht'] ?? '');
    if (rowHeight != null && rowHeight.isFinite && rowHeight > 0) {
      sourceRowHeights['$rowIndex'] = rowHeight;
      rowHeights['$rowIndex'] = rowHeight * 1.3333333333;
    }
    if (_xmlBool(rowAttributes['hidden'])) {
      hiddenRows['$rowIndex'] = 0;
    }
    maxRow = _max(maxRow, rowIndex + 1);

    final rowBody = rowMatch.group(3) ?? '';
    for (final cellMatch in RegExp(
      r'<c\b([^>]*)/>|<c\b([^>]*)>(.*?)</c>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(rowBody)) {
      final cellAttributes = _xmlAttributes(
        cellMatch.group(1) ?? cellMatch.group(2) ?? '',
      );
      final ref = cellAttributes['r'];
      final coord = ref == null ? null : _cellRefToCoord(ref);
      if (coord == null) {
        continue;
      }
      final style = styles.cellStyle(int.tryParse(cellAttributes['s'] ?? ''));
      final cellBody = cellMatch.group(3) ?? '';
      final cellValue = _cellValue(
        cellBody,
        cellAttributes,
        sharedStrings,
        style,
      );
      final merge = mergeMap['${coord.row}_${coord.column}'];
      final hyperlink = hyperlinks['${coord.row}_${coord.column}'];
      final hasLineBreak = cellValue.text?.contains('\n') ?? false;
      final cellJson = <String, Object?>{
        ...style.cellJson,
        ...metadata.cellExtra(ref),
        if (cellValue.text != null) 'v': cellValue.text,
        if (cellValue.text != null) 'm': cellValue.text,
        if (cellValue.formula != null) 'f': cellValue.formula,
        if (merge != null) 'mc': merge,
        if (hyperlink != null) 'hl': hyperlink,
      };
      if (hasLineBreak) {
        cellJson['tb'] = '2';
      }
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
      // 규칙 A: 엑셀 셀 테두리 속성을 그대로 1:1 변환한다.
      // 엑셀에 정의된 border만 emit하며, 임의 보정/합성/skip을 하지 않는다.
      // 값/채움이 없어 cellJson이 비어도, border가 있으면 그대로 유지한다.
      final cellBorders = style.borderInfo(coord.row, coord.column);
      for (final border in cellBorders) {
        borderInfo.add(border);
        // 진단: 규칙 A 검증용. 엑셀 원본 border(색/스타일)를 셀별로 전량 기록.
        if (borderSamples.length < 3000) {
          borderSamples.add(
            '${_coordLabel(coord.row, coord.column)} '
            'style=${cellAttributes['s']} '
            '${_borderInfoLogText(border)}',
          );
        }
      }
      if (cellBorders.isNotEmpty) {
        maxRow = _max(maxRow, coord.row + 1);
        maxColumn = _max(maxColumn, coord.column + 1);
      }
      if (cellJson.isEmpty) {
        continue;
      }
      final key = '${coord.row}_${coord.column}';
      cellKeys.add(key);
      cells.add({'r': coord.row, 'c': coord.column, 'v': cellJson});
      if (cellValue.text != null && valueSamples.length < 40) {
        valueSamples.add(
          '${_coordLabel(coord.row, coord.column)}=${_logText(cellValue.text!)}',
        );
      }
      if (cellJson['tb'] == '2' && wrapSamples.length < 24) {
        wrapSamples.add(
          '${_coordLabel(coord.row, coord.column)} '
          'len=${cellValue.text?.length ?? 0} '
          'lines=${_lineCount(cellValue.text)} '
          'merge=${merge == null ? '-' : '${merge['rs']}x${merge['cs']}'} '
          'rowHeight=${rowHeights['${coord.row}']} '
          'fontSize=${cellJson['fs']}',
        );
      }
      if (hasLineBreak && lineBreakSamples.length < 24) {
        lineBreakSamples.add(
          '${_coordLabel(coord.row, coord.column)} '
          'len=${cellValue.text?.length ?? 0} '
          'lines=${_lineCount(cellValue.text)} '
          'tb=${cellJson['tb']} '
          'merge=${merge == null ? '-' : '${merge['rs']}x${merge['cs']}'} '
          'rowHeight=${rowHeights['${coord.row}']} '
          'fontSize=${cellJson['fs']}',
        );
      }
      if ((cellJson.containsKey('bg') ||
              cellJson.containsKey('fc') ||
              cellJson.containsKey('bl') ||
              cellJson.containsKey('mc')) &&
          styleSamples.length < 40) {
        styleSamples.add(
          '${_coordLabel(coord.row, coord.column)} '
          'bg=${cellJson['bg']} fc=${cellJson['fc']} bl=${cellJson['bl']} '
          'fs=${cellJson['fs']} mc=${cellJson['mc']}',
        );
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
    cells.add({
      'r': coord.row,
      'c': coord.column,
      'v': {'mc': entry.value},
    });
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
    cells.add({
      'r': coord.row,
      'c': coord.column,
      'v': {'hl': entry.value},
    });
    cellKeys.add(entry.key);
  }

  _xlsxImportLog(
    'worksheet json built name=$sheetName rows=${_max(maxRow, 1)} '
    'columns=${_max(maxColumn, 1)} cells=${cells.length} '
    'merges=${mergeMap.length} rowHeights=${rowHeights.length} '
    'columnWidths=${columnWidths.length} hiddenRows=${hiddenRows.length} '
    'hiddenColumns=${hiddenColumns.length} hyperlinks=${hyperlinks.length} '
    'borders=${borderInfo.length}',
  );
  _xlsxImportLog(
    'worksheet json samples values=${valueSamples.join(' | ')} '
    'styles=${styleSamples.join(' | ')} '
    'merges=${_mergeSample(mergeMap)}',
  );
  _xlsxImportLog(
    'worksheet json layout rowHeights=${_mapSample(rowHeights)} '
    'columnWidths=${_mapSample(columnWidths)} '
    'lineBreakCells=${lineBreakSamples.join(' | ')} '
    'wrapCells=${wrapSamples.join(' | ')}',
  );
  _logXlsxChunks('worksheet border samples', borderSamples);
  _xlsxImportLog(
    'worksheet source axis rowHeightsPt=${_mapSample(sourceRowHeights)} '
    'columnWidthsChars=${_mapSample(sourceColumnWidths)} '
    'rowHeightPtTotal=${_numericMapTotal(sourceRowHeights)} '
    'columnWidthCharTotal=${_numericMapTotal(sourceColumnWidths)}',
  );
  _xlsxImportLog(
    'worksheet converted axis rowHeightsLogical=${_mapSample(rowHeights)} '
    'columnWidthsLogical=${_mapSample(columnWidths)} '
    'rowLogicalTotal=${_numericMapTotal(rowHeights)} '
    'columnLogicalTotal=${_numericMapTotal(columnWidths)}',
  );
  _xlsxImportLog(
    'worksheet axis boundaries rows=$maxRow columns=$maxColumn '
    'sourceRowBoundariesPt=${_axisBoundarySample(sourceRowHeights, maxRow)} '
    'sourceColumnBoundariesChars=${_axisBoundarySample(sourceColumnWidths, maxColumn)} '
    'convertedRowBoundariesLogical=${_axisBoundarySample(rowHeights, maxRow, includeGrid: true)} '
    'convertedColumnBoundariesLogical=${_axisBoundarySample(columnWidths, maxColumn, includeGrid: true)} '
    'mergeLogicalSizes=${_mergeLogicalSizeSample(mergeMap, rowHeights, columnWidths)}',
  );

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

void _logDecodedSheetSample(FortuneSheet sheet) {
  final valueSamples = <String>[];
  final anchorSamples = <String>[];
  final coveredSamples = <String>[];
  for (final entry
      in sheet.cells.entries.toList()..sort((left, right) {
        final rowCompare = left.key.row.compareTo(right.key.row);
        return rowCompare == 0
            ? left.key.column.compareTo(right.key.column)
            : rowCompare;
      })) {
    final coord = entry.key;
    final cell = entry.value;
    final value = cell.displayValue ?? cell.value;
    if (value.isNotEmpty && valueSamples.length < 40) {
      valueSamples.add(
        '${_coordLabel(coord.row, coord.column)}=${_logText(value)}',
      );
    }
    final merge = cell.merge;
    if (merge == null) {
      continue;
    }
    final sample =
        '${_coordLabel(coord.row, coord.column)}->'
        '${_coordLabel(merge.row, merge.column)} '
        'span=${merge.rowSpan}x${merge.columnSpan} '
        'value=${_logText(value)} fs=${cell.fontSize} '
        'bg=${cell.background} fc=${cell.foreground}';
    if (merge.row == coord.row && merge.column == coord.column) {
      if (anchorSamples.length < 40) {
        anchorSamples.add(sample);
      }
    } else if (coveredSamples.length < 40) {
      coveredSamples.add(sample);
    }
  }
  _xlsxImportLog(
    'decoded sheet sample values=${valueSamples.join(' | ')} '
    'mergeAnchors=${anchorSamples.join(' | ')} '
    'mergeCovered=${coveredSamples.join(' | ')}',
  );
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

  int get length => _values.length;

  static _XlsxSharedStrings fromArchive(Archive archive) {
    final xml = _tryXlsxText(archive, 'xl/sharedStrings.xml');
    if (xml == null) {
      _xlsxImportLog('sharedStrings missing');
      return const _XlsxSharedStrings(<_XlsxSharedString>[]);
    }
    final result = _XlsxSharedStrings([
      for (final match in RegExp(
        r'<si\b[^>]*>(.*?)</si>',
        caseSensitive: false,
        dotAll: true,
      ).allMatches(xml))
        _XlsxSharedString(match.group(1) ?? ''),
    ]);
    _xlsxImportLog('sharedStrings loaded count=${result.length}');
    return result;
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

  _XlsxCellValue value(_XlsxCellStyle baseStyle) =>
      _richTextValue(xml, baseStyle);
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
    runs.add({'v': text, ...baseStyle.runJson, ..._runJson(properties)});
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
    if (fontSize != null) 'fs': _pointsToLogicalPixels(fontSize),
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
      _xlsxImportLog('styles missing, using defaults');
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
    _xlsxImportLog(
      'styles parsed formats=${formats.length} fonts=${fonts.length} '
      'fills=${fills.length} borders=${borders.length} numFmts=${numberFormats.length}',
    );
    // 진단: border 정의(index→sides)와 문제 format의 borderId/applyBorder 덤프.
    final borderDefSamples = <String>[];
    for (var i = 0; i < borders.length; i += 1) {
      final sides = borders[i].sides.entries
          .map((e) => '${e.key}=s${e.value.style}/${e.value.color}')
          .join(',');
      borderDefSamples.add('def[$i] ${sides.isEmpty ? '(none)' : sides}');
    }
    _logXlsxChunks('styles border defs', borderDefSamples);
    final formatSamples = <String>[];
    for (var i = 0; i < formats.length; i += 1) {
      final f = formats[i];
      if (f.borderId != null && f.borderId != 0) {
        formatSamples.add(
          'fmt[$i] borderId=${f.borderId} applyBorder=${f.applyBorder} xfId=${f.xfId}',
        );
      }
    }
    _logXlsxChunks('styles formats with border', formatSamples);
    return _XlsxStyleTable(
      formats: formats.isEmpty
          ? const <_XlsxCellFormat>[_XlsxCellFormat()]
          : formats,
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
    // 규칙 A: 엑셀이 실제 렌더하는 테두리만 가져온다. cellXf에 applyBorder="0"이
    // 명시된 경우 엑셀은 borderId가 있어도 테두리를 그리지 않으므로 제외한다.
    final border = format.applyBorder
        ? (_itemAt(borders, format.borderId) ?? const _XlsxBorder())
        : const _XlsxBorder();
    return _XlsxCellStyle(
      formatCode:
          numberFormats[format.numFmtId] ??
          _builtinNumberFormats[format.numFmtId],
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
      if (wrapText) 'tb': '2',
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
          'strokeWidth': side.value.strokeWidth,
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
    this.applyBorder = true,
    this.xfId,
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
  final bool applyBorder;
  final int? xfId;
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
  const _XlsxBorderSide({
    required this.style,
    required this.strokeWidth,
    this.color,
  });

  final int style;
  final double strokeWidth;
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

  int get cellCount => cellExtraByRef.length;

  int get runCount =>
      runExtraByRef.values.fold<int>(0, (total, runs) => total + runs.length);

  static _XlsxExtensionMetadata fromArchive(Archive archive) {
    final cellExtra = <String, Map<String, Object?>>{};
    final runExtra = <String, Map<int, Map<String, Object?>>>{};
    for (final file in archive.files) {
      final name = file.name.replaceAll('\\', '/');
      if (!file.isFile ||
          !name.startsWith('customXml/') ||
          !name.endsWith('.xml')) {
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
      _xlsxImportLog('customXml metadata found path=$name chars=${xml.length}');
      _readMetadataXml(xml, cellExtra, runExtra);
    }
    _xlsxImportLog(
      'customXml metadata parsed cells=${cellExtra.length} '
      'runs=${runExtra.values.fold<int>(0, (total, runs) => total + runs.length)}',
    );
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
        {...runs[index], ...?extras[index]},
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
        runExtra.putIfAbsent(ref, () => <int, Map<String, Object?>>{})[index] =
            {...?runExtra[ref]?[index], ...run};
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
        fontSize: _pointsToLogicalPixels(
          double.tryParse(_firstTagAttributes(fontXml, 'sz')?['val'] ?? ''),
        ),
        fontFamily: _firstTagAttributes(fontXml, 'name')?['val'],
        foreground: _colorFromElement(fontXml, 'color'),
        script: _scriptFromVertAlign(
          _firstTagAttributes(fontXml, 'vertAlign')?['val'],
        ),
      ),
  ];
}

List<String?> _fills(String xml) {
  final body = _extractElement(xml, 'fills') ?? '';
  return [
    for (final fillXml in _elementBodies(body, 'fill'))
      _colorFromElement(fillXml, 'fgColor') ??
          _colorFromElement(fillXml, 'bgColor'),
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
    strokeWidth: _borderStrokeWidth(styleText),
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
      _cellFormat(_xmlAttributes(match.group(1) ?? ''), match.group(2) ?? ''),
  ];
}

_XlsxCellFormat _cellFormat(Map<String, String> attributes, String body) {
  final alignment = _firstTagAttributes(body, 'alignment');
  return _XlsxCellFormat(
    numFmtId: int.tryParse(attributes['numFmtId'] ?? ''),
    fontId: int.tryParse(attributes['fontId'] ?? ''),
    fillId: int.tryParse(attributes['fillId'] ?? ''),
    borderId: int.tryParse(attributes['borderId'] ?? ''),
    // applyBorder 미지정이면 기본 적용(true). 명시적 "0"/"false"만 미적용.
    applyBorder: attributes.containsKey('applyBorder')
        ? _xmlBool(attributes['applyBorder'])
        : true,
    xfId: int.tryParse(attributes['xfId'] ?? ''),
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

String _coordLabel(int row, int column) {
  var value = column + 1;
  final letters = StringBuffer();
  while (value > 0) {
    value -= 1;
    letters.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return '${letters.toString().split('').reversed.join()}${row + 1}';
}

String _logText(String value) {
  final singleLine = value.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
  return singleLine.length <= 60
      ? singleLine
      : '${singleLine.substring(0, 60)}...';
}

String _mergeSample(Map<String, Map<String, Object?>> mergeMap) {
  return mergeMap.entries
      .take(40)
      .map((entry) {
        final coord = _keyToCoord(entry.key);
        final merge = entry.value;
        final row = merge['r'];
        final column = merge['c'];
        final rowSpan = merge['rs'];
        final columnSpan = merge['cs'];
        final label = coord == null
            ? entry.key
            : _coordLabel(coord.row, coord.column);
        return '$label r=$row c=$column span=${rowSpan}x$columnSpan';
      })
      .join(' | ');
}

String _mapSample(Map<String, Object?> map) {
  return map.entries
      .take(30)
      .map((entry) => '${entry.key}:${entry.value}')
      .join('|');
}

String _borderInfoLogText(Map<String, Object?> border) {
  final range = border['range'];
  var row = '?';
  var column = '?';
  if (range is List && range.isNotEmpty && range.first is Map) {
    final rangeMap = range.first as Map;
    row = '${rangeMap['row']}';
    column = '${rangeMap['column']}';
  }
  return 'type=${border['borderType']} style=${border['style']} '
      'stroke=${border['strokeWidth']} color=${border['color']} '
      'row=$row column=$column';
}

void _logXlsxChunks(String prefix, List<String> samples) {
  if (samples.isEmpty) {
    _xlsxImportLog('$prefix=-');
    return;
  }
  const maxChunkLength = 1200;
  var chunk = StringBuffer();
  var chunkIndex = 1;
  var sampleStart = 0;
  void flush() {
    if (chunk.isEmpty) {
      return;
    }
    _xlsxImportLog('$prefix chunk=$chunkIndex sampleStart=$sampleStart $chunk');
    chunk = StringBuffer();
    chunkIndex += 1;
  }

  for (var index = 0; index < samples.length; index += 1) {
    final sample = samples[index];
    final next = chunk.isEmpty ? sample : ' | $sample';
    if (chunk.isNotEmpty && chunk.length + next.length > maxChunkLength) {
      flush();
      sampleStart = index;
    }
    if (chunk.isEmpty) {
      chunk.write(sample);
    } else {
      chunk.write(next);
    }
  }
  flush();
}

double _numericMapTotal(Map<String, Object?> map) {
  var total = 0.0;
  for (final value in map.values) {
    if (value is num) {
      total += value.toDouble();
    }
  }
  return total;
}

String _axisBoundarySample(
  Map<String, Object?> sizes,
  int count, {
  bool includeGrid = false,
  int limit = 30,
}) {
  if (count <= 0) {
    return '-';
  }
  var position = 0.0;
  final samples = <String>[];
  final sampleCount = count < limit ? count : limit;
  for (var index = 0; index < sampleCount; index += 1) {
    final size = _numericMapValue(sizes, index) ?? 0;
    position += size + (includeGrid ? 1 : 0);
    samples.add('$index:$position($size)');
  }
  if (count > limit) {
    samples.add('...count=$count');
  }
  return samples.join('|');
}

String _mergeLogicalSizeSample(
  Map<String, Map<String, Object?>> mergeMap,
  Map<String, Object?> rowHeights,
  Map<String, Object?> columnWidths, {
  int limit = 40,
}) {
  if (mergeMap.isEmpty) {
    return '-';
  }
  return mergeMap.entries
      .take(limit)
      .map((entry) {
        final coord = _keyToCoord(entry.key);
        final merge = entry.value;
        final row = _intValue(merge['r']) ?? coord?.row ?? 0;
        final column = _intValue(merge['c']) ?? coord?.column ?? 0;
        final rowSpan = _intValue(merge['rs']) ?? 1;
        final columnSpan = _intValue(merge['cs']) ?? 1;
        final width = _axisRangeSize(columnWidths, column, columnSpan);
        final height = _axisRangeSize(rowHeights, row, rowSpan);
        final label = coord == null
            ? entry.key
            : _coordLabel(coord.row, coord.column);
        return '$label span=${rowSpan}x$columnSpan logical=${width}x$height';
      })
      .join(' | ');
}

double _axisRangeSize(Map<String, Object?> sizes, int start, int span) {
  var total = 0.0;
  for (var index = start; index < start + span; index += 1) {
    total += (_numericMapValue(sizes, index) ?? 0) + 1;
  }
  return total;
}

double? _numericMapValue(Map<String, Object?> sizes, int index) {
  final value = sizes['$index'];
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value');
}

int _lineCount(String? value) {
  if (value == null || value.isEmpty) {
    return 0;
  }
  return '\n'.allMatches(value).length + 1;
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
  // self-closing(<tag/>)을 여는 태그보다 먼저 매칭해야 한다. 여는 태그 대안을
  // 앞에 두면 `[^>]*`가 self-closing의 `/`까지 삼켜 `<tag/>`를 여는 태그로 오인,
  // 빈 요소(예: <border/>)를 건너뛰어 인덱스(borderId 등)가 밀린다.
  final pattern = RegExp(
    '<$tag\\b[^>]*/>|<$tag\\b[^>]*>(.*?)</$tag>',
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
      if (!excludedKeys.contains(entry.key))
        entry.key: _metadataValue(entry.value),
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
  final decoded = value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
  return decoded.replaceAllMapped(RegExp(r'&#(x?[0-9A-Fa-f]+);'), (match) {
    final raw = match.group(1)!;
    final codePoint = raw.startsWith('x') || raw.startsWith('X')
        ? int.tryParse(raw.substring(1), radix: 16)
        : int.tryParse(raw);
    if (codePoint == null) {
      return match.group(0)!;
    }
    return String.fromCharCode(codePoint);
  });
}

T? _itemAt<T>(List<T> values, int? index) {
  if (index == null || index < 0 || index >= values.length) {
    return null;
  }
  return values[index];
}

int _borderStyle(String style) {
  return switch (style) {
    'hair' || 'dotted' => 10,
    'dashed' || 'dashDot' || 'dashDotDot' => 9,
    'mediumDashed' || 'mediumDashDot' || 'mediumDashDotDot' => 4,
    'medium' => 8,
    'thick' => 13,
    'double' => 2,
    _ => 1,
  };
}

double? _pointsToLogicalPixels(double? points) {
  if (points == null || !points.isFinite || points <= 0) {
    return null;
  }
  return points * 4 / 3;
}

double _columnWidthToLogicalPixels(double width) {
  return (width * 8).clamp(1.0, 4096.0);
}

double _borderStrokeWidth(String style) {
  return switch (style) {
    'hair' => 0.5,
    'medium' || 'mediumDashed' || 'mediumDashDot' || 'mediumDashDotDot' => 1.5,
    'thick' => 2.0,
    _ => 1.0,
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
