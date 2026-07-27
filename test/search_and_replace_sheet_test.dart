import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/page_home/search_and_replace_sheet.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';

void main() {
  test('replaces plain and sheet values together', () async {
    final result = await replaceSearchElement(
      element: '국산 대두',
      elementSheet: '',
      find: '대두',
      replacement: '콩',
    );
    final workbook = labelSheetDecodeWorkbookSave(result.elementSheet);
    expect(result.element, '국산 콩');
    expect(
      workbook.sheets.first.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '국산 콩',
    );
  });

  test('keeps inline run styles while replacing run text', () async {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 'item_element',
          name: '주원료',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '국산 대두',
              inlineRuns: [
                FortuneInlineTextRun(text: '국산 ', bold: true),
                FortuneInlineTextRun(text: '대두', italic: true),
              ],
            ),
          },
        ),
      ],
    );
    final result = await replaceSearchElement(
      element: '국산 대두',
      elementSheet: labelSheetEncodeWorkbookSave(workbook),
      find: '대두',
      replacement: '콩',
    );
    final cell = labelSheetDecodeWorkbookSave(
      result.elementSheet,
    ).sheets.first.cells[const FortuneCellCoord(0, 0)]!;
    expect(cell.inlineRuns?.map((run) => run.text), ['국산 ', '콩']);
    expect(cell.inlineRuns?.first.bold, isTrue);
    expect(cell.inlineRuns?.last.italic, isTrue);
  });

  test('individual edit writes one current sheet cell', () async {
    final result = await setSearchElement(
      element: '새 주원료',
      elementSheet: '',
    );
    final workbook = labelSheetDecodeWorkbookSave(result.elementSheet);
    expect(workbook.sheets, hasLength(1));
    expect(
      workbook.sheets.first.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '새 주원료',
    );
  });
}