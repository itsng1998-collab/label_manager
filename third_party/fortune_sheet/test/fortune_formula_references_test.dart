import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_formula_references.dart';

void main() {
  group('formula reference rewrite helpers', () {
    test('rewrite whole axis ranges for insert and delete', () {
      expect(
        rewriteFormulaReferencesForInsert(
          '=SUM(A:C)+SUM(1:3)',
          type: 'column',
          index: 1,
          count: 1,
          direction: 'lefttop',
        ),
        '=SUM(A:D)+SUM(1:3)',
      );
      expect(
        rewriteFormulaReferencesForInsert(
          '=SUM(A:C)+SUM(1:3)',
          type: 'row',
          index: 1,
          count: 2,
          direction: 'rightbottom',
        ),
        '=SUM(A:C)+SUM(1:5)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          '=SUM(B:C)+SUM(2:3)',
          type: 'column',
          start: 1,
          end: 2,
        ),
        '=SUM(#REF!)+SUM(2:3)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          '=SUM(B:C)+SUM(2:3)',
          type: 'row',
          start: 1,
          end: 2,
        ),
        '=SUM(B:C)+SUM(#REF!)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          '=SUM(D:F)+SUM(4:6)',
          type: 'column',
          start: 1,
          end: 2,
        ),
        '=SUM(B:D)+SUM(4:6)',
      );
    });

    test('rewrite only references that belong to target sheet', () {
      expect(
        rewriteFormulaReferencesForInsert(
          r"=Sheet1!A1+Sheet2!A1+SUM(Sheet1!A:C)+SUM(Sheet2!A:C)",
          type: 'column',
          index: 0,
          count: 1,
          direction: 'lefttop',
          targetSheetName: 'Sheet1',
        ),
        r"=Sheet1!B1+Sheet2!A1+SUM(Sheet1!B:D)+SUM(Sheet2!A:C)",
      );
      expect(
        rewriteFormulaReferencesForDelete(
          r"='A'' Sheet'!B2:C3+[Book.xlsx]Raw!B:C+Raw!B:C",
          type: 'column',
          start: 1,
          end: 1,
          targetSheetName: "A' Sheet",
        ),
        r"='A'' Sheet'!B2:B3+[Book.xlsx]Raw!B:C+Raw!B:C",
      );
      expect(
        rewriteFormulaReferencesForInsert(
          r"='[Book.xlsx]Raw'!A1+[Book.xlsx]Raw!A1",
          type: 'row',
          index: 0,
          count: 1,
          direction: 'lefttop',
          targetSheetName: 'Raw',
        ),
        r"='[Book.xlsx]Raw'!A1+[Book.xlsx]Raw!A2",
      );
      expect(
        rewriteFormulaReferencesForInsert(
          r'=SUM(Sheet1!A1:Sheet1!B2)+SUM(Sheet1!A:Sheet1!C)',
          type: 'column',
          index: 0,
          count: 1,
          direction: 'lefttop',
          targetSheetName: 'Sheet1',
        ),
        r'=SUM(Sheet1!B1:Sheet1!C2)+SUM(Sheet1!B:Sheet1!D)',
      );
      expect(
        rewriteFormulaReferencesForInsert(
          r'=SUM(Sheet1!A:C)+SUM(Sheet2!A:C)+SUM(Sheet1!1:3)+SUM(Sheet2!1:3)',
          type: 'column',
          index: 0,
          count: 1,
          direction: 'lefttop',
          targetSheetName: 'Sheet1',
        ),
        r'=SUM(Sheet1!B:D)+SUM(Sheet2!A:C)+SUM(Sheet1!1:3)+SUM(Sheet2!1:3)',
      );
      expect(
        rewriteFormulaReferencesForInsert(
          r'=SUM(Sheet1!A:C)+SUM(Sheet2!A:C)+SUM(Sheet1!1:3)+SUM(Sheet2!1:3)',
          type: 'row',
          index: 0,
          count: 1,
          direction: 'lefttop',
          targetSheetName: 'Sheet1',
        ),
        r'=SUM(Sheet1!A:C)+SUM(Sheet2!A:C)+SUM(Sheet1!2:4)+SUM(Sheet2!1:3)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          r'=SUM(Sheet1!B:D)+SUM(Sheet2!B:D)+SUM(Sheet1!2:4)+SUM(Sheet2!2:4)',
          type: 'column',
          start: 1,
          end: 1,
          targetSheetName: 'Sheet1',
        ),
        r'=SUM(Sheet1!B:C)+SUM(Sheet2!B:D)+SUM(Sheet1!2:4)+SUM(Sheet2!2:4)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          r'=SUM(Sheet1!B:D)+SUM(Sheet2!B:D)+SUM(Sheet1!2:4)+SUM(Sheet2!2:4)',
          type: 'row',
          start: 1,
          end: 1,
          targetSheetName: 'Sheet1',
        ),
        r'=SUM(Sheet1!B:D)+SUM(Sheet2!B:D)+SUM(Sheet1!2:3)+SUM(Sheet2!2:4)',
      );
    });

    test('preserve reversed ranges and skip quoted text', () {
      expect(
        rewriteFormulaReferencesForInsert(
          r'=SUM(C:A)+"A:C"+A1',
          type: 'column',
          index: 0,
          count: 1,
          direction: 'lefttop',
        ),
        r'=SUM(C:A)+"A:C"+B1',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          r"='A:C'!A1+SUM(A1:C1)",
          type: 'column',
          start: 1,
          end: 2,
        ),
        r"='A:C'!A1+SUM(A1:B1)",
      );
      expect(
        rewriteFormulaReferencesForInsert(
          r'="A1 "" B1"+C1',
          type: 'column',
          index: 0,
          count: 1,
          direction: 'lefttop',
        ),
        r'="A1 "" B1"+D1',
      );
    });

    test('collapse partially deleted ranges to a single reference', () {
      expect(
        rewriteFormulaReferencesForDelete(
          r'=SUM(B1:D1)',
          type: 'column',
          start: 0,
          end: 2,
        ),
        r'=SUM(A1)',
      );
      expect(
        rewriteFormulaReferencesForDelete(
          r'=SUM(A2:A4)',
          type: 'row',
          start: 0,
          end: 2,
        ),
        r'=SUM(A1)',
      );
    });
  });
}
