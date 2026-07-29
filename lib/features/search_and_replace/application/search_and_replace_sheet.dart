import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';

class SearchReplaceElementValue {
  const SearchReplaceElementValue({
    required this.element,
    required this.elementSheet,
  });

  final String element;
  final String elementSheet;
}

Future<SearchReplaceElementValue> replaceSearchElement({
  required String element,
  required String elementSheet,
  required String find,
  required String replacement,
}) async {
  var workbook = labelSheetTryDecodeWorkbookSave(elementSheet);
  workbook ??= await _legacyElementWorkbook(elementSheet, element);
  final nextWorkbook = workbook.copyWith(
    sheets: [
      for (final sheet in workbook.sheets)
        sheet.copyWith(
          cells: {
            for (final entry in sheet.cells.entries)
              entry.key: _replaceCell(entry.value, find, replacement),
          },
        ),
    ],
  );
  return SearchReplaceElementValue(
    element: element.replaceAll(find, replacement),
    elementSheet: labelSheetEncodeWorkbookSave(nextWorkbook),
  );
}

Future<SearchReplaceElementValue> setSearchElement({
  required String element,
  required String elementSheet,
}) async {
  var workbook = labelSheetTryDecodeWorkbookSave(elementSheet);
  workbook ??= await _legacyElementWorkbook(elementSheet, element);
  final sheet = workbook.sheets.first;
  final baseCell = sheet.cells.values.firstOrNull ?? const FortuneCell();
  final nextCell = baseCell.copyWith(
    value: element,
    rawValue: element,
    displayValue: null,
    rawDisplayValue: null,
    hasRawDisplayValue: false,
    cellType: null,
    inlineRuns: null,
  );
  workbook = workbook.copyWith(
    sheets: [
      sheet.copyWith(
        rowCount: 1,
        columnCount: 1,
        cells: {const FortuneCellCoord(0, 0): nextCell},
      ),
    ],
    activeSheetIndex: 0,
  );
  return SearchReplaceElementValue(
    element: element,
    elementSheet: labelSheetEncodeWorkbookSave(workbook),
  );
}

Future<FortuneWorkbook> _legacyElementWorkbook(
  String elementSheet,
  String element,
) async {
  final base = _plainElementWorkbook(element);
  if (!labelSheetLooksLikeRichEditRtf(elementSheet)) return base;
  final draft = await labelSheetDraftFromRichEditRtfAsync(
    elementSheet,
    sheet: base.sheets.first,
  );
  if (draft == null || draft.cells.isEmpty) return base;
  final entries = draft.cells.entries.toList()
    ..sort((left, right) {
      final row = left.key.row.compareTo(right.key.row);
      return row != 0 ? row : left.key.column.compareTo(right.key.column);
    });
  final runs = <FortuneInlineTextRun>[];
  int? previousRow;
  var firstInRow = true;
  for (final entry in entries) {
    if (entry.value.renderedText.isEmpty) continue;
    if (previousRow != entry.key.row) {
      if (previousRow != null) {
        runs.add(const FortuneInlineTextRun(text: '\n'));
      }
      previousRow = entry.key.row;
      firstInRow = true;
    } else if (!firstInRow) {
      runs.add(const FortuneInlineTextRun(text: '\t'));
    }
    runs.addAll(
      entry.value.inlineRuns ??
          [FortuneInlineTextRun(text: entry.value.renderedText)],
    );
    firstInRow = false;
  }
  if (runs.isEmpty) return base;
  final sheet = base.sheets.first;
  final text = runs.map((run) => run.text).join();
  return base.copyWith(
    sheets: [
      sheet.copyWith(
        cells: {
          const FortuneCellCoord(0, 0): entries.first.value.copyWith(
            value: text,
            rawValue: text,
            displayValue: null,
            rawDisplayValue: null,
            hasRawDisplayValue: false,
            inlineRuns: runs,
          ),
        },
      ),
    ],
  );
}

FortuneWorkbook _plainElementWorkbook(String element) => FortuneWorkbook(
  sheets: [
    FortuneSheet(
      id: 'item_element',
      name: '주원료 및 함량',
      rowCount: 1,
      columnCount: 1,
      cells: {const FortuneCellCoord(0, 0): FortuneCell(value: element)},
      showGridLines: false,
    ),
  ],
);

FortuneCell _replaceCell(
  FortuneCell cell,
  String find,
  String replacement,
) {
  final runs = cell.inlineRuns;
  if (runs != null && runs.isNotEmpty) {
    final nextRuns = [
      for (final run in runs)
        run.copyWith(text: run.text.replaceAll(find, replacement)),
    ];
    final text = nextRuns.map((run) => run.text).join();
    return cell.copyWith(
      value: text,
      rawValue: text,
      displayValue: null,
      rawDisplayValue: null,
      hasRawDisplayValue: false,
      cellType: null,
      inlineRuns: nextRuns,
    );
  }
  final text = cell.renderedText.replaceAll(find, replacement);
  return cell.copyWith(
    value: text,
    rawValue: text,
    displayValue: null,
    rawDisplayValue: null,
    hasRawDisplayValue: false,
    inlineRuns: null,
  );
}