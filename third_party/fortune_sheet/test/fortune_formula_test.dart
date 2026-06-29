import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_formula.dart';
import 'package:fortune_sheet/src/fortune_sheet_codec.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test(
    'formula engine calculates workbook formulas through public API helper',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
              const FortuneCellCoord(0, 1): const FortuneCell(
                value: '=A1+1',
                formula: '=A1+1',
                displayValue: 'old-b',
                rawDisplayValue: 'old-b',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 2): const FortuneCell(
                value: '=A1+2',
                formula: '=A1+2',
                displayValue: 'old-c',
                rawDisplayValue: 'old-c',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 3): const FortuneCell(
                value: '=Café!A1+1',
                formula: '=Café!A1+1',
                displayValue: 'old-d',
                rawDisplayValue: 'old-d',
                hasRawDisplayValue: true,
              ),
            },
          ),
          FortuneSheet(
            id: 's2',
            name: 'Sheet2',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '5'),
              const FortuneCellCoord(0, 1): const FortuneCell(
                value: '=A1+1',
                formula: '=A1+1',
                displayValue: 'old-s2',
                rawDisplayValue: 'old-s2',
                hasRawDisplayValue: true,
              ),
            },
          ),
          FortuneSheet(
            id: 's3',
            name: 'Café',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '7'),
            },
          ),
        ],
        activeSheetIndex: 1,
      );

      final ranged = FortuneFormulaEngine.calculateFormula(
        workbook,
        id: 's1',
        range: const FortuneRange(
          rowStart: 0,
          rowEnd: 0,
          columnStart: 1,
          columnEnd: 1,
        ),
      );
      final all = FortuneFormulaEngine.calculateFormula(workbook);

      expect(ranged.activeSheet.id, 's2');
      expect(
        ranged.sheets[0].cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '3',
      );
      expect(
        ranged.sheets[0].cells[const FortuneCellCoord(0, 2)]?.renderedText,
        'old-c',
      );
      expect(
        ranged.sheets[1].cells[const FortuneCellCoord(0, 1)]?.renderedText,
        'old-s2',
      );
      expect(
        all.sheets[0].cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '3',
      );
      expect(
        all.sheets[0].cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '4',
      );
      expect(
        all.sheets[0].cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '8',
      );
      final calculatedFormulaCell =
          all.sheets[0].cells[const FortuneCellCoord(0, 1)]!;
      expect(calculatedFormulaCell.value, '3');
      expect(calculatedFormulaCell.rawValue, '3');
      expect(calculatedFormulaCell.hasRawValue, isTrue);
      expect(FortuneSheetCodec.cellToJson(calculatedFormulaCell), {
        'v': '3',
        'm': '3',
        'f': '=A1+1',
      });
      expect(
        all.sheets[1].cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '6',
      );
      expect(
        workbook.sheets[0].cells[const FortuneCellCoord(0, 1)]?.renderedText,
        'old-b',
      );
    },
  );

  test(
    'formula calculation materializes raw value when display is current',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=A1+1',
            rawValue: '=A1+1',
            hasRawValue: true,
            formula: '=A1+1',
            rawFormula: '=A1+1',
            hasRawFormula: true,
            displayValue: '3',
            rawDisplayValue: '3',
            hasRawDisplayValue: true,
          ),
        },
      );

      final recalculatedSheet = FortuneFormulaEngine.recalculate(sheet);
      final calculatedWorkbook = FortuneFormulaEngine.calculateFormula(
        FortuneWorkbook(sheets: [sheet]),
      );

      expect(
        FortuneSheetCodec.cellToJson(
          recalculatedSheet.cells[const FortuneCellCoord(0, 1)]!,
        ),
        {'v': '3', 'm': '3', 'f': '=A1+1'},
      );
      expect(
        FortuneSheetCodec.cellToJson(
          calculatedWorkbook.sheets.single.cells[const FortuneCellCoord(0, 1)]!,
        ),
        {'v': '3', 'm': '3', 'f': '=A1+1'},
      );
    },
  );

  test(
    'formula workbook calculation materializes dynamic array spill cells',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=SEQUENCE(2, 2)',
                formula: '=SEQUENCE(2, 2)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
            },
          ),
        ],
      );

      final calculated = FortuneFormulaEngine.calculateFormula(workbook);
      final cells = calculated.sheets.single.cells;

      expect(cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
      expect(cells[const FortuneCellCoord(0, 0)]?.formula, '=SEQUENCE(2, 2)');
      expect(cells[const FortuneCellCoord(0, 1)]?.renderedText, '2');
      expect(cells[const FortuneCellCoord(1, 0)]?.renderedText, '3');
      expect(cells[const FortuneCellCoord(1, 1)]?.renderedText, '4');
      expect(
        workbook.sheets.single.cells[const FortuneCellCoord(0, 1)],
        isNull,
      );
    },
  );

  test(
    'formula workbook calculation returns spill when dynamic array range is occupied',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=SEQUENCE(2, 1)',
                formula: '=SEQUENCE(2, 1)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(1, 0): const FortuneCell(value: 'kept'),
            },
          ),
        ],
      );

      final calculated = FortuneFormulaEngine.calculateFormula(workbook);
      final sheet = calculated.sheets.single;

      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '#SPILL!',
      );
      expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'kept');
      expect(sheet.dynamicArray, isNull);
    },
  );

  test(
    'formula workbook calculation updates existing dynamic array followers',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=SEQUENCE(2, 1)',
                formula: '=SEQUENCE(2, 1)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(1, 0): const FortuneCell(
                value: '2',
                rawValue: 2.0,
                hasRawValue: true,
                displayValue: '2',
                rawDisplayValue: '2',
                hasRawDisplayValue: true,
              ),
            },
            dynamicArray: const [
              {
                'r': 0,
                'c': 0,
                'f': '=SEQUENCE(2, 1)',
                'data': [1.0, 2.0],
                'rowCount': 2,
                'columnCount': 1,
                'id': 's1',
              },
            ],
            hasRawDynamicArray: true,
          ),
        ],
      );

      final calculated = FortuneFormulaEngine.calculateFormula(workbook);
      final sheet = calculated.sheets.single;

      expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
      expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '2');
      expect((sheet.dynamicArray! as List).single, {
        'r': 0,
        'c': 0,
        'f': '=SEQUENCE(2, 1)',
        'data': [1.0, 2.0],
        'rowCount': 2,
        'columnCount': 1,
        'id': 's1',
      });
    },
  );

  test('formula refresh recalculates formulas that depend on spill cells', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '=SEQUENCE(B1)',
              formula: '=SEQUENCE(B1)',
              displayValue: 'old-anchor',
              rawDisplayValue: 'old-anchor',
              hasRawDisplayValue: true,
            ),
            const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
            const FortuneCellCoord(0, 2): const FortuneCell(
              value: '=A2+10',
              formula: '=A2+10',
              displayValue: 'stale',
              rawDisplayValue: 'stale',
              hasRawDisplayValue: true,
            ),
          },
          calcChain: const [
            {'r': 0, 'c': 0, 'id': 's1'},
            {'r': 0, 'c': 2, 'id': 's1'},
          ],
        ),
      ],
    );

    final refreshed = refreshAffectedFormulas(
      workbook,
      row: 0,
      column: 1,
      id: 's1',
      value: '2',
    );
    final cells = refreshed.sheets.single.cells;

    expect(cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(cells[const FortuneCellCoord(1, 0)]?.renderedText, '2');
    expect(cells[const FortuneCellCoord(0, 2)]?.renderedText, '12');
  });

  test(
    'formula refresh returns spill when dynamic array range is occupied',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=SEQUENCE(B1)',
                formula: '=SEQUENCE(B1)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
              const FortuneCellCoord(1, 0): const FortuneCell(value: 'kept'),
            },
            calcChain: const [
              {'r': 0, 'c': 0, 'id': 's1'},
            ],
          ),
        ],
      );

      final refreshed = refreshAffectedFormulas(
        workbook,
        row: 0,
        column: 1,
        id: 's1',
        value: '2',
      );
      final sheet = refreshed.sheets.single;

      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '#SPILL!',
      );
      expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'kept');
      expect(sheet.dynamicArray, isNull);
    },
  );

  test(
    'formula refresh returns spill when nested dynamic array range is occupied',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=IF(B1>1,SEQUENCE(2),5)',
                formula: '=IF(B1>1,SEQUENCE(2),5)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
              const FortuneCellCoord(1, 0): const FortuneCell(value: 'kept'),
            },
            calcChain: const [
              {'r': 0, 'c': 0, 'id': 's1'},
            ],
          ),
        ],
      );

      final refreshed = refreshAffectedFormulas(
        workbook,
        row: 0,
        column: 1,
        id: 's1',
        value: '2',
      );
      final sheet = refreshed.sheets.single;

      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '#SPILL!',
      );
      expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'kept');
      expect(sheet.dynamicArray, isNull);
    },
  );

  test('formula refresh clears stale dynamic array spill followers', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '=SEQUENCE(B1)',
              formula: '=SEQUENCE(B1)',
              displayValue: 'old-anchor',
              rawDisplayValue: 'old-anchor',
              hasRawDisplayValue: true,
            ),
            const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
          },
          calcChain: const [
            {'r': 0, 'c': 0, 'id': 's1'},
          ],
        ),
      ],
    );

    final expanded = refreshAffectedFormulas(
      workbook,
      row: 0,
      column: 1,
      id: 's1',
      value: '2',
    );
    expect(
      expanded.sheets.single.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '2',
    );

    final shrunk = refreshAffectedFormulas(
      expanded,
      row: 0,
      column: 1,
      id: 's1',
      value: '1',
    );
    final cells = shrunk.sheets.single.cells;

    expect(cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty, isTrue);
    expect(cells[const FortuneCellCoord(1, 0)]?.hasRawValue, isFalse);
  });

  test(
    'formula refresh recalculates formulas that depend on cleared spill cells',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=SEQUENCE(B1)',
                formula: '=SEQUENCE(B1)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
              const FortuneCellCoord(0, 2): const FortuneCell(
                value: '=A3+10',
                formula: '=A3+10',
                displayValue: 'stale',
                rawDisplayValue: 'stale',
                hasRawDisplayValue: true,
              ),
            },
            calcChain: const [
              {'r': 0, 'c': 0, 'id': 's1'},
              {'r': 0, 'c': 2, 'id': 's1'},
            ],
          ),
        ],
      );

      final expanded = refreshAffectedFormulas(
        workbook,
        row: 0,
        column: 1,
        id: 's1',
        value: '3',
      );
      expect(
        expanded
            .sheets
            .single
            .cells[const FortuneCellCoord(2, 0)]
            ?.renderedText,
        '3',
      );
      expect(
        expanded
            .sheets
            .single
            .cells[const FortuneCellCoord(0, 2)]
            ?.renderedText,
        '13',
      );

      final shrunk = refreshAffectedFormulas(
        expanded,
        row: 0,
        column: 1,
        id: 's1',
        value: '2',
      );
      final cells = shrunk.sheets.single.cells;

      expect(cells[const FortuneCellCoord(2, 0)]?.isVisuallyEmpty, isTrue);
      expect(cells[const FortuneCellCoord(0, 2)]?.renderedText, '10');
    },
  );

  test('formula refresh clears spill followers when anchor becomes scalar', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '=IF(B1>1,SEQUENCE(2),5)',
              formula: '=IF(B1>1,SEQUENCE(2),5)',
              displayValue: 'old-anchor',
              rawDisplayValue: 'old-anchor',
              hasRawDisplayValue: true,
            ),
            const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
            const FortuneCellCoord(0, 2): const FortuneCell(
              value: '=A2+10',
              formula: '=A2+10',
              displayValue: 'stale',
              rawDisplayValue: 'stale',
              hasRawDisplayValue: true,
            ),
          },
          calcChain: const [
            {'r': 0, 'c': 0, 'id': 's1'},
            {'r': 0, 'c': 2, 'id': 's1'},
          ],
        ),
      ],
    );

    final expanded = refreshAffectedFormulas(
      workbook,
      row: 0,
      column: 1,
      id: 's1',
      value: '2',
    );
    expect(
      expanded.sheets.single.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '2',
    );
    expect(
      expanded.sheets.single.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '12',
    );

    final scalar = refreshAffectedFormulas(
      expanded,
      row: 0,
      column: 1,
      id: 's1',
      value: '1',
    );
    final sheet = scalar.sheets.single;

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty, isTrue);
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '10');
    expect(sheet.dynamicArray, isEmpty);
  });

  test(
    'workbook recalculation clears spill followers when anchor becomes scalar',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=IF(B1>1,SEQUENCE(2),5)',
                formula: '=IF(B1>1,SEQUENCE(2),5)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
            },
            calcChain: const [
              {'r': 0, 'c': 0, 'id': 's1'},
            ],
          ),
        ],
      );

      final expanded = refreshAffectedFormulas(
        workbook,
        row: 0,
        column: 1,
        id: 's1',
        value: '2',
      );
      final editedSheet = expanded.sheets.single.setCellValue(0, 1, '1');
      final recalculated = FortuneFormulaEngine.calculateFormula(
        expanded.copyWith(sheets: [editedSheet]),
      ).sheets.single;

      expect(
        recalculated.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '5',
      );
      expect(
        recalculated.cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty,
        isTrue,
      );
      expect(recalculated.dynamicArray, isEmpty);
    },
  );

  test(
    'sheet recalculation clears spill followers when anchor becomes scalar',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '=IF(B1>1,SEQUENCE(2),5)',
                formula: '=IF(B1>1,SEQUENCE(2),5)',
                displayValue: 'old-anchor',
                rawDisplayValue: 'old-anchor',
                hasRawDisplayValue: true,
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
            },
            calcChain: const [
              {'r': 0, 'c': 0, 'id': 's1'},
            ],
          ),
        ],
      );

      final expanded = refreshAffectedFormulas(
        workbook,
        row: 0,
        column: 1,
        id: 's1',
        value: '2',
      );
      final editedSheet = expanded.sheets.single.setCellValue(0, 1, '1');
      final recalculated = FortuneFormulaEngine.recalculate(editedSheet);

      expect(
        recalculated.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '5',
      );
      expect(
        recalculated.cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty,
        isTrue,
      );
      expect(recalculated.dynamicArray, isEmpty);
    },
  );

  test('workbook recalculation clears stale dynamic array spill followers', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '=SEQUENCE(B1)',
              formula: '=SEQUENCE(B1)',
              displayValue: 'old-anchor',
              rawDisplayValue: 'old-anchor',
              hasRawDisplayValue: true,
            ),
            const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
          },
          calcChain: const [
            {'r': 0, 'c': 0, 'id': 's1'},
          ],
        ),
      ],
    );

    final expanded = refreshAffectedFormulas(
      workbook,
      row: 0,
      column: 1,
      id: 's1',
      value: '2',
    );
    final editedSheet = expanded.sheets.single.setCellValue(0, 1, '1');
    final recalculated = FortuneFormulaEngine.calculateFormula(
      expanded.copyWith(sheets: [editedSheet]),
    );
    final sheet = recalculated.sheets.single;

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty, isTrue);
    expect((sheet.dynamicArray! as List).single, {
      'r': 0,
      'c': 0,
      'f': '=SEQUENCE(B1)',
      'data': [1.0],
      'rowCount': 1,
      'columnCount': 1,
      'id': 's1',
    });
  });

  test('sheet recalculation clears stale dynamic array spill followers', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '=SEQUENCE(B1)',
              formula: '=SEQUENCE(B1)',
              displayValue: 'old-anchor',
              rawDisplayValue: 'old-anchor',
              hasRawDisplayValue: true,
            ),
            const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
          },
          calcChain: const [
            {'r': 0, 'c': 0, 'id': 's1'},
          ],
        ),
      ],
    );

    final expanded = refreshAffectedFormulas(
      workbook,
      row: 0,
      column: 1,
      id: 's1',
      value: '2',
    );
    final editedSheet = expanded.sheets.single.setCellValue(0, 1, '1');
    final recalculated = FortuneFormulaEngine.recalculate(editedSheet);

    expect(recalculated.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(
      recalculated.cells[const FortuneCellCoord(1, 0)]?.isVisuallyEmpty,
      isTrue,
    );
    expect((recalculated.dynamicArray! as List).single, {
      'r': 0,
      'c': 0,
      'f': '=SEQUENCE(B1)',
      'data': [1.0],
      'rowCount': 1,
      'columnCount': 1,
      'id': 's1',
    });
  });

  test('formula engine evaluates references arithmetic and ranges', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1+A2+3',
          formula: '=A1+A2+3',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUM(A1:A2, 5)',
          formula: '=SUM(A1:A2, 5)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=AVERAGE(A1:A2)',
          formula: '=AVERAGE(A1:A2)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: r'=VALUE("$ 1,234.50")',
          formula: r'=VALUE("$ 1,234.50")',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=Sheet1!A1+SUM(Sheet1!A1:A2)',
          formula: '=Sheet1!A1+SUM(Sheet1!A1:A2)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=SUM(Sheet1!A1:Sheet1!A2)',
          formula: '=SUM(Sheet1!A1:Sheet1!A2)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: "='Sheet1'!A1+SUM('Sheet1'!A1:'Sheet1'!A2)",
          formula: "='Sheet1'!A1+SUM('Sheet1'!A1:'Sheet1'!A2)",
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=SUM([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!A2)',
          formula: '=SUM([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!A2)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value:
              "='[Book1.xlsx]Sheet1'!A1+SUM('[Book1.xlsx]Sheet1'!A1:'[Book1.xlsx]Sheet1'!A2)",
          formula:
              "='[Book1.xlsx]Sheet1'!A1+SUM('[Book1.xlsx]Sheet1'!A1:'[Book1.xlsx]Sheet1'!A2)",
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=Sheet1!A1%',
          formula: '=Sheet1!A1%',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: "='Sheet1'!A1:'Sheet1'!A2%",
          formula: "='Sheet1'!A1:'Sheet1'!A2%",
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '1234.5');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '0.02');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '0.05');
  });

  test('formula engine normalizes reversed ranges', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=SUM(B2:A1)',
          formula: '=SUM(B2:A1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: r'=SUM($B$2:A$1)',
          formula: r'=SUM($B$2:A$1)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: r'=SUM(B$2:$A1)',
          formula: r'=SUM(B$2:$A1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '10');
  });

  test('formula engine treats missing references as blanks', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=A1+5',
          formula: '=A1+5',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=SUM(A1:B2)',
          formula: '=SUM(A1:B2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '0');
  });

  test('formula engine evaluates parser default variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=TRUE',
          formula: '=TRUE',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=FALSE',
          formula: '=FALSE',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=NULL',
          formula: '=NULL',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=NULL+5',
          formula: '=NULL+5',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=',
          formula: '=',
        ),
      },
    );

    expect(FortuneFormulaEngine.evaluateFormula(sheet, ''), '');
    expect(FortuneFormulaEngine.evaluateFormula(sheet, '='), '');

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '');
  });

  test('formula engine returns ref error for unknown sheet prefixes', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '5'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=Missing!A1',
          formula: '=Missing!A1',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUM(Missing!A1:Missing!A2)',
          formula: '=SUM(Missing!A1:Missing!A2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IFERROR(Missing!A1, "bad ref")',
          formula: '=IFERROR(Missing!A1, "bad ref")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: "='Missing Sheet'!A1",
          formula: "='Missing Sheet'!A1",
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=[Book1.xlsx]Missing!A1',
          formula: '=[Book1.xlsx]Missing!A1',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, 'bad ref');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#REF!');
  });

  test('formula engine rejects mixed sheet range prefixes', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '5'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=SUM(Sheet1!A1:Missing!A2)',
          formula: '=SUM(Sheet1!A1:Missing!A2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUM(A1:Missing!A2)',
          formula: '=SUM(A1:Missing!A2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IFERROR(SUM(Sheet1!A1:Missing!A2), "bad range")',
          formula: '=IFERROR(SUM(Sheet1!A1:Missing!A2), "bad range")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText,
      'bad range',
    );
  });

  test('formula engine evaluates raw numeric values before display text', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '2',
          rawValue: 2,
          hasRawValue: true,
          displayValue: 'two',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '3',
          rawValue: 3,
          hasRawValue: true,
          displayValue: 'three',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1+A2',
          formula: '=A1+A2',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUM(A1:A2)',
          formula: '=SUM(A1:A2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '5');
  });

  test('formula engine evaluates raw numeric strings before display text', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '2',
          rawValue: '2',
          hasRawValue: true,
          displayValue: 'two',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '3.5',
          rawValue: '3.5',
          hasRawValue: true,
          displayValue: 'three point five',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1+A2',
          formula: '=A1+A2',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUM(A1:A2)',
          formula: '=SUM(A1:A2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '5.5');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '5.5');
  });

  test('formula engine evaluates raw booleans before display text', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: 'TRUE',
          rawValue: true,
          hasRawValue: true,
          displayValue: 'yes',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: 'FALSE',
          rawValue: false,
          hasRawValue: true,
          displayValue: 'no',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1',
          formula: '=A1',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=A1+1',
          formula: '=A1+1',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=A2+1',
          formula: '=A2+1',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '1');
  });

  test('formula engine evaluates raw text before display text', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: 'alpha',
          rawValue: 'alpha',
          hasRawValue: true,
          displayValue: 'ALPHA',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: 'beta',
          rawValue: 'beta',
          hasRawValue: true,
          displayValue: 'BETA',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1',
          formula: '=A1',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=A1&"-"&A2',
          formula: '=A1&"-"&A2',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'alpha');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      'alpha-beta',
    );
  });

  test('formula engine evaluates named formula variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: {
        'formulaVariables': {
          'taxRate': 0.1,
          'label': 'Q1',
          'matrix': [
            [1, 2],
            [3, 4],
          ],
          'blank': null,
          'baz': '6.6',
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=100*TAXRATE',
          formula: '=100*TAXRATE',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=label&"-"&SUM(matrix)',
          formula: '=label&"-"&SUM(matrix)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=blank+5',
          formula: '=blank+5',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=TAXRATE%',
          formula: '=TAXRATE%',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=SUM(baz, 2.1, 0.2)',
          formula: '=SUM(baz, 2.1, 0.2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'Q1-10');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '0.001');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '8.9');
    expect(
      FortuneFormulaEngine.evaluateFormula(sheet, '=SUM(baz, 2.1, 0.2)'),
      closeTo(8.899999999999999, 1e-12),
    );
  });

  test('formula engine evaluates custom formula functions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: {
        'formulaFunctions': <String, FortuneFormulaFunction>{
          'ADD_5': (params) => (params.single as num) + 5,
          'GET_LETTER': (params) {
            final text = params[0].toString();
            final index = ((params[1] as num) - 1).toInt();
            return text[index];
          },
          'GET_DATE': (params) => DateTime.utc(2026, 5, 28, 9, 30),
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=SUM(4, ADD_5(1))',
          formula: '=SUM(4, ADD_5(1))',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=GET_LETTER("Some string", 3)',
          formula: '=GET_LETTER("Some string", 3)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=GET_DATE()',
          formula: '=GET_DATE()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'm');
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      DateTime.utc(2026, 5, 28, 9, 30).toString(),
    );
    expect(FortuneFormulaEngine.evaluateFormula(sheet, '=add_5(2)'), 7);
  });

  test('formula engine lets custom formula functions override built-ins', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: {
        'formulaFunctions': <String, FortuneFormulaFunction>{
          'SUM': (params) => 'custom:${params.join('|')}',
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=SUM(1, 2, 3)',
          formula: '=SUM(1, 2, 3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      'custom:1.0|2.0|3.0',
    );
    expect(
      FortuneFormulaEngine.evaluateFormula(sheet, '=sum(4, 5)'),
      'custom:4.0|5.0',
    );
  });

  test('formula engine supports FormulaJS exact export aliases', () {
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1');
    final cases = <String, Matcher>{
      '=CEILINGMATH(-4.3, 2)': equals(-4),
      '=CEILINGPRECISE(-4.3, 2)': equals(-4),
      '=ISOCEILING(4.3, 2)': equals(6),
      '=FLOORMATH(-4.3, 2, 1)': equals(-4),
      '=FLOORPRECISE(-4.3, 2)': equals(-6),
      '=GAMMALNPRECISE(4)': closeTo(1.791759469228, 1e-12),
      '=ROUND(ERFPRECISE(1), 6)': equals(0.842701),
      '=ROUND(ERFCPRECISE(1), 6)': equals(0.157299),
      '=ROUND(COVARIANCEP({1,2,3}, {2,3,4}), 6)': equals(0.666667),
      '=COVARIANCES({1,2,3}, {2,3,4})': equals(1),
      '=PERCENTRANK({1,2,3,4}, 4)': equals(1),
      '=ROUND(POISSON(1, 3, TRUE), 6)': equals(0.199148),
      '=NETWORKDAYSINTL(DATE(2023,1,2), DATE(2023,1,6))': equals(5),
      '=WORKDAYINTL(DATE(2023,1,6), 1)-DATE(2023,1,9)': equals(0),
      '=CRITBINOM(5, 0.5, 0.5)': equals(2),
      '=ISNUMBER(CHIDISTRT(18.307, 10))': equals(true),
      '=ISNUMBER(CHIINVRT(0.05, 10))': equals(true),
      '=ISNUMBER(TDISTRT(1, 10))': equals(true),
      '=CHISQ.TEST({10,20;30,40}, {12,18;28,42})': equals(0.372998),
      '=CHITEST({10,20;30,40}, {12,18;28,42})': equals(0.372998),
      '=ROUND(F.TEST({1,2,3}, {2,4,8}), 6)': equals(0.107143),
      '=ROUND(FTEST({1,2,3}, {2,4,8}), 6)': equals(0.107143),
      '=ROUND(E(1), 6)': equals(2.718282),
      '=ROUND(LN10(), 6)': equals(2.302585),
      '=ROUND(LN2(), 6)': equals(0.693147),
      '=ROUND(LOG10E(), 6)': equals(0.434294),
      '=ROUND(LOG2E(), 6)': equals(1.442695),
      '=ROUND(SQRT1_2(), 6)': equals(0.707107),
      '=ROUND(SQRT2(1), 6)': equals(1.414214),
      '=FINDFIELD({"Tree","Height";"Apple",18}, "Tree")': equals(0),
      '=FINDFIELD({"Tree","Height";"Apple",18}, "Apple")': equals(1),
    };

    for (final entry in cases.entries) {
      expect(
        FortuneFormulaEngine.evaluateFormula(sheet, entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });
  test('formula engine mirrors formula parser function error fixtures', () {
    final formulas = <String, String>{
      'foo()': '#NAME?',
      'ACOTH("foo")': '#VALUE!',
      "ACOTH('foo')": '#VALUE!',
      'ACOTH(foo)': '#NAME?',
    };
    final cells = <FortuneCellCoord, FortuneCell>{};
    var column = 0;
    for (final formula in formulas.keys) {
      cells[FortuneCellCoord(0, column)] = FortuneCell(
        value: '=$formula',
        formula: '=$formula',
      );
      column += 1;
    }
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1', cells: cells);

    FortuneFormulaEngine.recalculate(sheet);

    column = 0;
    for (final entry in formulas.entries) {
      expect(
        sheet.cells[FortuneCellCoord(0, column)]?.renderedText,
        entry.value,
        reason: entry.key,
      );
      column += 1;
    }
  });

  test('formula engine evaluates bracket array function arguments', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=SUM([])',
          formula: '=SUM([])',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=SUM([1])',
          formula: '=SUM([1])',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=SUM([1,2,3])',
          formula: '=SUM([1,2,3])',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '6');
  });

  test(
    'formula engine honors lowercase functions and semicolon separators',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [7, 3.5, 3.5, 1, 2],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
          const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=sum(A1:A2; 5)',
            formula: '=sum(A1:A2; 5)',
          ),
          const FortuneCellCoord(1, 1): const FortuneCell(
            value: '=min(A1:A2; 1)',
            formula: '=min(A1:A2; 1)',
          ),
          const FortuneCellCoord(2, 1): const FortuneCell(
            value: '=if(A1=2; sum(A1:A2); 0)',
            formula: '=if(A1=2; sum(A1:A2); 0)',
          ),
          const FortuneCellCoord(3, 1): const FortuneCell(
            value: '=if(true; "ok"; "bad")',
            formula: '=if(true; "ok"; "bad")',
          ),
          const FortuneCellCoord(4, 1): const FortuneCell(
            value: '=sum(2, 3, Rank.eq(2, foo))',
            formula: '=sum(2, 3, Rank.eq(2, foo))',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '10');
      expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '1');
      expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '5');
      expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, 'ok');
      expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '9');
    },
  );

  test('formula engine validates absolute reference dollar markers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: r'=$A$1',
          formula: r'=$A$1',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: r'=$a$1',
          formula: r'=$a$1',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: r'=$A1+A$1',
          formula: r'=$A1+A$1',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: r'=A$$1',
          formula: r'=A$$1',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: r'=$$A1',
          formula: r'=$$A1',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: r'=A1$',
          formula: r'=A1$',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: r'=A1$$$',
          formula: r'=A1$$$',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: r'=a1$$$',
          formula: r'=a1$$$',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: r'=$A$$$$1',
          formula: r'=$A$$$$1',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#ERROR!');
  });

  test('formula engine validates absolute range dollar markers', () {
    final formulas = <String, String>{
      r'$A$1:$B$2': '5',
      r'$a$1:$B$2': '5',
      r'$a$1:$b$2': '5',
      r'$A$1:B2': '5',
      r'$A$1:b2': '5',
      r'$A$1:B$2': '5',
      r'$A1:B$2': '5',
      r'A$1:B2': '5',
      r'A$1:$B2': '5',
      r'A$1:$B$2': '5',
      r'A1:$B$2': '5',
      r'A1:$B2': '5',
      r'a$1:$b2': '5',
      r'A1:b2': '5',
      r'a1:B2': '5',
      r'a1:b2': '5',
      r'$A$$1:$B$2': '#ERROR!',
      r'$A$1:$B$$2': '#ERROR!',
      r'$A$1:$$B$2': '#ERROR!',
      r'$$A$1:$B$2': '#ERROR!',
      r'A1:$$B2': '#ERROR!',
      r'A1:B2$': '#ERROR!',
      r'a1:b2$': '#ERROR!',
      r'A1$:B2': '#ERROR!',
    };
    final cells = <FortuneCellCoord, FortuneCell>{
      const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
      const FortuneCellCoord(1, 1): const FortuneCell(value: '3'),
    };
    var column = 0;
    for (final formula in formulas.keys) {
      cells[FortuneCellCoord(2, column)] = FortuneCell(
        value: '=$formula',
        formula: '=$formula',
      );
      column += 1;
    }
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1', cells: cells);

    FortuneFormulaEngine.recalculate(sheet);

    column = 0;
    for (final entry in formulas.entries) {
      expect(
        sheet.cells[FortuneCellCoord(2, column)]?.renderedText,
        entry.value,
        reason: entry.key,
      );
      column += 1;
    }
  });

  test('formula engine mirrors formula parser operator fixtures', () {
    final formulas = <String, String>{
      '10+10': '20',
      '10 + 10': '20',
      '10 + 11 + 23 + 11 + 2': '57',
      '1.4425 + 4.333': '5.7755',
      '"2" + 8.8': '10.8',
      '"2" + "8.8"': '10.8',
      '"2" + "-8.8" + 6 + 0.4': '-0.4',
      '"foo" + 4.333': '#VALUE!',
      '10-10': '0',
      '10 - 10': '0',
      '10 - 10 - 2': '-2',
      '10 - 11 - 23 - 11 - 2': '-37',
      '2 - 8.8': '-6.8',
      '"2" - "-8.8" - 6 - 0.4': '4.4',
      '"foo" - 4.333': '#VALUE!',
      '2 / 1': '2',
      '64 / 2 / 4': '8',
      '2 / 0': '#DIV/0!',
      '"2" / 8.8': '0.227272727273',
      '"2" / "-8.8" / 6 / 0.4': '-0.094696969697',
      '"foo" / 4.333': '#VALUE!',
      '0 * 0 * 0 * 0 * 0': '0',
      '2 * 1': '2',
      '64 * 2 * 4': '512',
      '"2" * "8.8"': '17.6',
      '"2" * "-8.8" * 6 * 0.4': '-42.24',
      '"foo" * 4.333': '#VALUE!',
      '2 ^ 5': '32',
      '"2" ^ "8.8"': '445.721888407616',
      '"foo" ^ 4': '#VALUE!',
      '2 & 5': '25',
      '(2 & 5)': '25',
      '("" & "")': '',
      '"" & ""': '',
      '("Hello" & " world") & "!"': 'Hello world!',
      '1 + 10 - 20 * 3/2': '-19',
      '((1 + 10 - 20 * 3 / 2) + 20) * 10': '10',
      '(((1 + 10 - 20 * 3/2) + 20) * 10) / 5.12': '1.953125',
      '(((1 + "foo" - 20 * 3/2) + 20) * 10) / 5.12': '#VALUE!',
      '10 = 10': 'TRUE',
      '10 = 11': 'FALSE',
      '1 = "1"': 'FALSE',
      '11 > 10': 'TRUE',
      '10 > 1.1': 'TRUE',
      '10 >- 10': 'TRUE',
      '10 > 11': 'FALSE',
      '10 > 11.1': 'FALSE',
      '10 > 10.00001': 'FALSE',
      '1 > "1"': 'FALSE',
      '10 < 11': 'TRUE',
      '10 < 11.1': 'TRUE',
      '10 < 10.00001': 'TRUE',
      '11 < 10': 'FALSE',
      '10 < 1.1': 'FALSE',
      '10 <- 10': 'FALSE',
      '1 < "1"': 'FALSE',
      '11 >= 10': 'TRUE',
      '11 >= 11': 'TRUE',
      '10 >= 10': 'TRUE',
      '10 >= -10': 'TRUE',
      '10 >= 11': 'FALSE',
      '10 >= 11.1': 'FALSE',
      '10 >= 10.00001': 'FALSE',
      '1 >= "1"': 'TRUE',
      '10 <= 10': 'TRUE',
      '1.1 <= 10': 'TRUE',
      '-10 <= 10': 'TRUE',
      '11 <= 10': 'FALSE',
      '11.1 <= 10': 'FALSE',
      '10.00001 <= 10': 'FALSE',
      '1 <= "1"': 'TRUE',
      '10 <> 11': 'TRUE',
      '1.1 <> 10': 'TRUE',
      '-10 <> 10': 'TRUE',
      '10 <> 10': 'FALSE',
      '11.1 <> 11.1': 'FALSE',
      '10.00001 <> 10.00001': 'FALSE',
      '1 <> "1"': 'TRUE',
    };
    final cells = <FortuneCellCoord, FortuneCell>{};
    var column = 0;
    for (final formula in formulas.keys) {
      cells[FortuneCellCoord(0, column)] = FortuneCell(
        value: '=$formula',
        formula: '=$formula',
      );
      column += 1;
    }
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1', cells: cells);

    FortuneFormulaEngine.recalculate(sheet);

    column = 0;
    for (final entry in formulas.entries) {
      expect(
        sheet.cells[FortuneCellCoord(0, column)]?.renderedText,
        entry.value,
        reason: entry.key,
      );
      column += 1;
    }
  });

  test('formula engine evaluates engineering comparison helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DELTA(58)',
          formula: '=DELTA(58)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=DELTA(58, 4)',
          formula: '=DELTA(58, 4)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=DELTA(58, 58)',
          formula: '=DELTA(58, 58)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DELTA("x", 1)',
          formula: '=DELTA("x", 1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=GESTEP(1, 2)',
          formula: '=GESTEP(1, 2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=GESTEP(-1, -2)',
          formula: '=GESTEP(-1, -2)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=GESTEP(0)',
          formula: '=GESTEP(0)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=GESTEP("x", 1)',
          formula: '=GESTEP("x", 1)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=DELTA()',
          formula: '=DELTA()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=GESTEP()',
          formula: '=GESTEP()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering decimal conversions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=BIN2DEC(1010)',
          formula: '=BIN2DEC(1010)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=BIN2DEC(1111111111)',
          formula: '=BIN2DEC(1111111111)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=BIN2DEC(102)',
          formula: '=BIN2DEC(102)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=BIN2DEC(0)',
          formula: '=BIN2DEC(0)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=BIN2DEC(1)',
          formula: '=BIN2DEC(1)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=BIN2DEC("-1010")',
          formula: '=BIN2DEC("-1010")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=HEX2DEC("FA")',
          formula: '=HEX2DEC("FA")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=HEX2DEC(200)',
          formula: '=HEX2DEC(200)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=HEX2DEC("FFFFFFFFFF")',
          formula: '=HEX2DEC("FFFFFFFFFF")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=HEX2DEC("FG")',
          formula: '=HEX2DEC("FG")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=HEX2DEC()',
          formula: '=HEX2DEC()',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=HEX2DEC("-FF")',
          formula: '=HEX2DEC("-FF")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=OCT2DEC(3)',
          formula: '=OCT2DEC(3)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=OCT2DEC(33)',
          formula: '=OCT2DEC(33)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=OCT2DEC("7777777777")',
          formula: '=OCT2DEC("7777777777")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=OCT2DEC(8)',
          formula: '=OCT2DEC(8)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=OCT2DEC()',
          formula: '=OCT2DEC()',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=OCT2DEC("-7")',
          formula: '=OCT2DEC("-7")',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=BIN2DEC()',
          formula: '=BIN2DEC()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=BIN2HEX()',
          formula: '=BIN2HEX()',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=BIN2OCT()',
          formula: '=BIN2OCT()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '250');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '512');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '27');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
  });

  test('formula engine evaluates engineering decimal to base conversions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DEC2BIN(10)',
          formula: '=DEC2BIN(10)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=DEC2BIN(0, 4)',
          formula: '=DEC2BIN(0, 4)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=DEC2BIN(-1)',
          formula: '=DEC2BIN(-1)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DEC2BIN(512)',
          formula: '=DEC2BIN(512)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=DEC2BIN(1)',
          formula: '=DEC2BIN(1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=DEC2HEX(100)',
          formula: '=DEC2HEX(100)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=DEC2HEX(100, 4)',
          formula: '=DEC2HEX(100, 4)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=DEC2HEX(-1)',
          formula: '=DEC2HEX(-1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=DEC2HEX(100, 1)',
          formula: '=DEC2HEX(100, 1)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=DEC2HEX(0)',
          formula: '=DEC2HEX(0)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=DEC2HEX(1)',
          formula: '=DEC2HEX(1)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=DEC2OCT(58)',
          formula: '=DEC2OCT(58)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=DEC2OCT(58, 4)',
          formula: '=DEC2OCT(58, 4)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=DEC2OCT(-1)',
          formula: '=DEC2OCT(-1)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=DEC2OCT(58, "x")',
          formula: '=DEC2OCT(58, "x")',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=DEC2OCT(0)',
          formula: '=DEC2OCT(0)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=DEC2OCT(1)',
          formula: '=DEC2OCT(1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=DEC2BIN()',
          formula: '=DEC2BIN()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=DEC2HEX()',
          formula: '=DEC2HEX()',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=DEC2OCT()',
          formula: '=DEC2OCT()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1010');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0000');
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '1111111111',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '0064');
    expect(
      sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
      'ffffffffff',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '72');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '0072');
    expect(
      sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText,
      '7777777777',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering base to base conversions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=BIN2HEX(1010)',
          formula: '=BIN2HEX(1010)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=BIN2HEX(1010, 4)',
          formula: '=BIN2HEX(1010, 4)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=BIN2OCT(1010)',
          formula: '=BIN2OCT(1010)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=BIN2OCT(1010, 4)',
          formula: '=BIN2OCT(1010, 4)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=BIN2HEX(102)',
          formula: '=BIN2HEX(102)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=BIN2HEX(0, 3)',
          formula: '=BIN2HEX(0, 3)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=BIN2HEX(1111)',
          formula: '=BIN2HEX(1111)',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=BIN2OCT(0, 3)',
          formula: '=BIN2OCT(0, 3)',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=BIN2OCT(111)',
          formula: '=BIN2OCT(111)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=HEX2BIN("FA")',
          formula: '=HEX2BIN("FA")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=HEX2BIN("FA", 10)',
          formula: '=HEX2BIN("FA", 10)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=HEX2BIN(200)',
          formula: '=HEX2BIN(200)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=HEX2OCT("FA")',
          formula: '=HEX2OCT("FA")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=HEX2OCT("FA", 6)',
          formula: '=HEX2OCT("FA", 6)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=HEX2OCT(200)',
          formula: '=HEX2OCT(200)',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=HEX2BIN()',
          formula: '=HEX2BIN()',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=HEX2OCT()',
          formula: '=HEX2OCT()',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=OCT2BIN(3)',
          formula: '=OCT2BIN(3)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=OCT2BIN(3, 4)',
          formula: '=OCT2BIN(3, 4)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=OCT2HEX(33)',
          formula: '=OCT2HEX(33)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=OCT2HEX(33, 3)',
          formula: '=OCT2HEX(33, 3)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=OCT2BIN("7777777777")',
          formula: '=OCT2BIN("7777777777")',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=OCT2BIN()',
          formula: '=OCT2BIN()',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=OCT2HEX()',
          formula: '=OCT2HEX()',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=OCT2HEX(3)',
          formula: '=OCT2HEX(3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'a');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '000a');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '0012');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '000');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, 'f');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '000');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '11111010');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '0011111010',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '372');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '000372');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '1000');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '0011');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '1b');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '01b');
    expect(
      sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText,
      '1111111111',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '3');
  });

  test('formula engine evaluates engineering bit helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=BITAND(2, 4)',
          formula: '=BITAND(2, 4)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=BITAND(1, 5)',
          formula: '=BITAND(1, 5)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=BITOR(2, 4)',
          formula: '=BITOR(2, 4)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=BITOR(1, 5)',
          formula: '=BITOR(1, 5)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=BITXOR(4, 2)',
          formula: '=BITXOR(4, 2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=BITXOR(1, 5)',
          formula: '=BITXOR(1, 5)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=BITLSHIFT(2, 4)',
          formula: '=BITLSHIFT(2, 4)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=BITLSHIFT(1, 5)',
          formula: '=BITLSHIFT(1, 5)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=BITRSHIFT(4, 2)',
          formula: '=BITRSHIFT(4, 2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=BITRSHIFT(1, 5)',
          formula: '=BITRSHIFT(1, 5)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=BITAND(-1, 1)',
          formula: '=BITAND(-1, 1)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=BITOR("x", 1)',
          formula: '=BITOR("x", 1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=BITAND()',
          formula: '=BITAND()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=BITAND(2)',
          formula: '=BITAND(2)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=BITLSHIFT()',
          formula: '=BITLSHIFT()',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=BITLSHIFT(2)',
          formula: '=BITLSHIFT(2)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=BITOR()',
          formula: '=BITOR()',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=BITOR(2)',
          formula: '=BITOR(2)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=BITRSHIFT()',
          formula: '=BITRSHIFT()',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=BITRSHIFT(2)',
          formula: '=BITRSHIFT(2)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=BITXOR()',
          formula: '=BITXOR()',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=BITXOR(2)',
          formula: '=BITXOR(2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '32');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '32');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering complex helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=COMPLEX(2, 0)',
          formula: '=COMPLEX(2, 0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=COMPLEX(4, 2)',
          formula: '=COMPLEX(4, 2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=COMPLEX(0, -1)',
          formula: '=COMPLEX(0, -1)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=COMPLEX(1, 5, "j")',
          formula: '=COMPLEX(1, 5, "j")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=COMPLEX("x", 1)',
          formula: '=COMPLEX("x", 1)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=COMPLEX()',
          formula: '=COMPLEX()',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=COMPLEX(1, 5)',
          formula: '=COMPLEX(1, 5)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=IMREAL("3+4i")',
          formula: '=IMREAL("3+4i")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=IMAGINARY("3+4i")',
          formula: '=IMAGINARY("3+4i")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=IMAGINARY("+i")',
          formula: '=IMAGINARY("+i")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=IMCONJUGATE("3+4i")',
          formula: '=IMCONJUGATE("3+4i")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=IMABS("5+12i")',
          formula: '=IMABS("5+12i")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=IMREAL("bad")',
          formula: '=IMREAL("bad")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IMCONJUGATE(1)',
          formula: '=IMCONJUGATE(1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=IMREAL()',
          formula: '=IMREAL()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=IMAGINARY()',
          formula: '=IMAGINARY()',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=IMCONJUGATE()',
          formula: '=IMCONJUGATE()',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=IMABS()',
          formula: '=IMABS()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '4+2i');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '-i');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '1+5j');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '1+5i');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '+1');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '3-4i');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '13');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering complex arithmetic helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=IMSUM("3+4i")',
          formula: '=IMSUM("3+4i")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=IMSUM("3+4i", "2+3i")',
          formula: '=IMSUM("3+4i", "2+3i")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=IMSUB("3+4i", "2+3i")',
          formula: '=IMSUB("3+4i", "2+3i")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=IMPRODUCT("3+4i")',
          formula: '=IMPRODUCT("3+4i")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=IMPRODUCT("3+4i", "1+2i")',
          formula: '=IMPRODUCT("3+4i", "1+2i")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=IMDIV("3+4i", "2+2i")',
          formula: '=IMDIV("3+4i", "2+2i")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=IMDIV("3+4i", "0+0i")',
          formula: '=IMDIV("3+4i", "0+0i")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=IMSUM("bad")',
          formula: '=IMSUM("bad")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=IMSUM()',
          formula: '=IMSUM()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IMSUB()',
          formula: '=IMSUB()',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=IMSUB("3+4i")',
          formula: '=IMSUB("3+4i")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=IMPRODUCT()',
          formula: '=IMPRODUCT()',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=IMDIV()',
          formula: '=IMDIV()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=IMDIV("3+4i")',
          formula: '=IMDIV("3+4i")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '3+4i');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '5+7i');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1+i');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '3+4i');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '-5+10i');
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '1.75+0.25i',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering complex exponent helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=IMARGUMENT("3+4i")',
          formula: '=IMARGUMENT("3+4i")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=IMARGUMENT(0)',
          formula: '=IMARGUMENT(0)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=IMEXP("3+4i")',
          formula: '=IMEXP("3+4i")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=IMLN("3+4i")',
          formula: '=IMLN("3+4i")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=IMLOG10("3+4i")',
          formula: '=IMLOG10("3+4i")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=IMLOG2("3+4i")',
          formula: '=IMLOG2("3+4i")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=IMPOWER("3+4i", 3)',
          formula: '=IMPOWER("3+4i", 3)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IMSQRT("3+4i")',
          formula: '=IMSQRT("3+4i")',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=IMLN(0)',
          formula: '=IMLN(0)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=IMARGUMENT(1)',
          formula: '=IMARGUMENT(1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=IMARGUMENT()',
          formula: '=IMARGUMENT()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=IMEXP()',
          formula: '=IMEXP()',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=IMLN()',
          formula: '=IMLN()',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=IMLOG10()',
          formula: '=IMLOG10()',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=IMLOG2()',
          formula: '=IMLOG2()',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=IMPOWER()',
          formula: '=IMPOWER()',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=IMPOWER("3+4i")',
          formula: '=IMPOWER("3+4i")',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=IMSQRT()',
          formula: '=IMSQRT()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '0.927295218002',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#DIV/0!');
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '-13.128783081462-15.200784463068i',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '1.609437912434+0.927295218002i',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '0.698970004336+0.402719196273i',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
      '2.321928094887+1.337804212451i',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '-117+44i');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '2+i');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#VALUE!');
  });

  test(
    'formula engine evaluates engineering complex trigonometric helpers',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=IMSIN("3+4i")',
            formula: '=IMSIN("3+4i")',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=IMCOS("3+4i")',
            formula: '=IMCOS("3+4i")',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=IMTAN("3+4i")',
            formula: '=IMTAN("3+4i")',
          ),
          const FortuneCellCoord(1, 0): const FortuneCell(
            value: '=IMSINH("3+4i")',
            formula: '=IMSINH("3+4i")',
          ),
          const FortuneCellCoord(1, 1): const FortuneCell(
            value: '=IMCOSH("3+4i")',
            formula: '=IMCOSH("3+4i")',
          ),
          const FortuneCellCoord(1, 2): const FortuneCell(
            value: '=IMCOT("3+4i")',
            formula: '=IMCOT("3+4i")',
          ),
          const FortuneCellCoord(2, 0): const FortuneCell(
            value: '=IMSEC("3+4i")',
            formula: '=IMSEC("3+4i")',
          ),
          const FortuneCellCoord(2, 1): const FortuneCell(
            value: '=IMCSC("3+4i")',
            formula: '=IMCSC("3+4i")',
          ),
          const FortuneCellCoord(2, 2): const FortuneCell(
            value: '=IMSECH("3+4i")',
            formula: '=IMSECH("3+4i")',
          ),
          const FortuneCellCoord(3, 0): const FortuneCell(
            value: '=IMCSCH("3+4i")',
            formula: '=IMCSCH("3+4i")',
          ),
          const FortuneCellCoord(3, 1): const FortuneCell(
            value: '=IMCSC(0)',
            formula: '=IMCSC(0)',
          ),
          const FortuneCellCoord(3, 2): const FortuneCell(
            value: '=IMCSC()',
            formula: '=IMCSC()',
          ),
          const FortuneCellCoord(3, 3): const FortuneCell(
            value: '=IMCSCH()',
            formula: '=IMCSCH()',
          ),
          const FortuneCellCoord(4, 0): const FortuneCell(
            value: '=IMSIN()',
            formula: '=IMSIN()',
          ),
          const FortuneCellCoord(4, 1): const FortuneCell(
            value: '=IMCOS()',
            formula: '=IMCOS()',
          ),
          const FortuneCellCoord(4, 2): const FortuneCell(
            value: '=IMTAN()',
            formula: '=IMTAN()',
          ),
          const FortuneCellCoord(5, 0): const FortuneCell(
            value: '=IMSINH()',
            formula: '=IMSINH()',
          ),
          const FortuneCellCoord(5, 1): const FortuneCell(
            value: '=IMCOSH()',
            formula: '=IMCOSH()',
          ),
          const FortuneCellCoord(5, 2): const FortuneCell(
            value: '=IMCOT()',
            formula: '=IMCOT()',
          ),
          const FortuneCellCoord(6, 0): const FortuneCell(
            value: '=IMSEC()',
            formula: '=IMSEC()',
          ),
          const FortuneCellCoord(6, 1): const FortuneCell(
            value: '=IMSECH()',
            formula: '=IMSECH()',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '3.853738037919-27.016813258004i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '-27.034945603074-3.851153334812i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '-0.000187346205+0.999355987381i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
        '-6.548120040911-7.619231720321i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
        '-6.580663040551-7.581552742747i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
        '-0.000187587738-1.000644392472i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText,
        '-0.036253496916+0.005164344608i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText,
        '0.005174473184+0.036275889629i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText,
        '-0.065294027858+0.075224960303i',
      );
      expect(
        sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText,
        '-0.064877471371+0.075489832916i',
      );
      expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
      expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
      expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#NUM!');
      expect(
        sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test('formula engine evaluates engineering error functions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ERF(1)',
          formula: '=ERF(1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ERF(2)',
          formula: '=ERF(2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ERF(-1)',
          formula: '=ERF(-1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=ERFC(0)',
          formula: '=ERFC(0)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=ERFC(1)',
          formula: '=ERFC(1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=ERF("x")',
          formula: '=ERF("x")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ERF()',
          formula: '=ERF()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=ERFC()',
          formula: '=ERFC()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '0.84270079295',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '0.995322265019',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '-0.84270079295',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '0.15729920705',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering unit conversions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=CONVERT(2, "lbm", "kg")',
          formula: '=CONVERT(2, "lbm", "kg")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=CONVERT(100, "km", "mi")',
          formula: '=CONVERT(100, "km", "mi")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=CONVERT(100, "km", "m")',
          formula: '=CONVERT(100, "km", "m")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=CONVERT(2, "km/h", "mi")',
          formula: '=CONVERT(2, "km/h", "mi")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=CONVERT("x", "kg", "g")',
          formula: '=CONVERT("x", "kg", "g")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=ROUND(CONVERT(100, "m/s", "kph"), 6)',
          formula: '=ROUND(CONVERT(100, "m/s", "kph"), 6)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ROUND(CONVERT(1, "J", "cal"), 6)',
          formula: '=ROUND(CONVERT(1, "J", "cal"), 6)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ROUND(CONVERT(1, "atm", "Pa"), 0)',
          formula: '=ROUND(CONVERT(1, "atm", "Pa"), 0)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=CONVERT(1)',
          formula: '=CONVERT(1)',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=CONVERT()',
          formula: '=CONVERT()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '0.90718474',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '62.137119223733',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '100000');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '360');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '0.239006');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '101325');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates engineering bessel functions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=BESSELI(1.4, 1)',
          formula: '=BESSELI(1.4, 1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=BESSELJ(1.4, 1)',
          formula: '=BESSELJ(1.4, 1)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=BESSELK(1.4, 1)',
          formula: '=BESSELK(1.4, 1)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=BESSELY(1.4, 1)',
          formula: '=BESSELY(1.4, 1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=BESSELJ(0, 1)',
          formula: '=BESSELJ(0, 1)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=BESSELK(0, 1)',
          formula: '=BESSELK(0, 1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=BESSELI(1.4, -1)',
          formula: '=BESSELI(1.4, -1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=BESSELI("x", 1)',
          formula: '=BESSELI("x", 1)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=BESSELI()',
          formula: '=BESSELI()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=BESSELI(1.4)',
          formula: '=BESSELI(1.4)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=BESSELJ()',
          formula: '=BESSELJ()',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=BESSELJ(1.4)',
          formula: '=BESSELJ(1.4)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=BESSELK()',
          formula: '=BESSELK()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=BESSELK(1.4)',
          formula: '=BESSELK(1.4)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=BESSELY()',
          formula: '=BESSELY()',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=BESSELY(1.4)',
          formula: '=BESSELY(1.4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '0.886091979396',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '0.541947713885',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '0.320835905505',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
      '-0.479146974111',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates interval and binary information helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INTERVAL(0)',
          formula: '=INTERVAL(0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INTERVAL(1)',
          formula: '=INTERVAL(1)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=INTERVAL(60)',
          formula: '=INTERVAL(60)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=INTERVAL(10000000)',
          formula: '=INTERVAL(10000000)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=INTERVAL()',
          formula: '=INTERVAL()',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=ISBINARY()',
          formula: '=ISBINARY()',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=ISBINARY(1)',
          formula: '=ISBINARY(1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=ISBINARY("1010")',
          formula: '=ISBINARY("1010")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ISBINARY(2)',
          formula: '=ISBINARY(2)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ISBINARY(0)',
          formula: '=ISBINARY(0)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'PT');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'PT1S');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'PT1M');
    expect(
      sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
      'P3M25DT17H46M40S',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'TRUE');
  });

  test('formula engine evaluates regex and html text helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=HTML2TEXT("Click <a>Link</a>")',
          formula: '=HTML2TEXT("Click <a>Link</a>")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=HTML2TEXT()',
          formula: '=HTML2TEXT()',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=REGEXEXTRACT("extract foo bar", "(foo)")',
          formula: '=REGEXEXTRACT("extract foo bar", "(foo)")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=REGEXEXTRACT("pressure 12.21bar", "([0-9]+.[0-9]+)")',
          formula: '=REGEXEXTRACT("pressure 12.21bar", "([0-9]+.[0-9]+)")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=REGEXMATCH("pressure 12.21bar", "([0-9]+.[0-9]+)")',
          formula: '=REGEXMATCH("pressure 12.21bar", "([0-9]+.[0-9]+)")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=REGEXREPLACE("extract foo bar", "(foo)", "baz")',
          formula: '=REGEXREPLACE("extract foo bar", "(foo)", "baz")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=REGEXEXTRACT("abc", "([0-9]+)")',
          formula: '=REGEXEXTRACT("abc", "([0-9]+)")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value:
              '=REGEXREPLACE("pressure 12.21bar", "([0-9]+.[0-9]+)", "43.1")',
          formula:
              '=REGEXREPLACE("pressure 12.21bar", "([0-9]+.[0-9]+)", "43.1")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=REGEXMATCH("pressure 12.33bar", "([0-9]+.[0-9]+)", TRUE)',
          formula: '=REGEXMATCH("pressure 12.33bar", "([0-9]+.[0-9]+)", TRUE)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=REGEXEXTRACT()',
          formula: '=REGEXEXTRACT()',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=REGEXREPLACE()',
          formula: '=REGEXREPLACE()',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=REGEXMATCH()',
          formula: '=REGEXMATCH()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      'Click Link',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'foo');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '12.21');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'TRUE');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      'extract baz bar',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText,
      'pressure 43.1bar',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '#N/A');
  });

  test('formula engine evaluates split text arrays', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INDEX(SPLIT("foo bar baz"), 1, 1)',
          formula: '=INDEX(SPLIT("foo bar baz"), 1, 1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=COLUMNS(SPLIT("foo bar baz"))',
          formula: '=COLUMNS(SPLIT("foo bar baz"))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=INDEX(SPLIT("foo bar baz", " "), 1, 2)',
          formula: '=INDEX(SPLIT("foo bar baz", " "), 1, 2)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=COLUMNS(SPLIT("foo bar baz", " "))',
          formula: '=COLUMNS(SPLIT("foo bar baz", " "))',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=SPLIT()',
          formula: '=SPLIT()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      'foo bar baz',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'bar');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#ERROR!');
  });

  test('formula engine evaluates function-style math operators', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ADD(3, 5)',
          formula: '=ADD(3, 5)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=MINUS(1.3, 1.2)',
          formula: '=MINUS(1.3, 1.2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MULTIPLY(2, 2.2)',
          formula: '=MULTIPLY(2, 2.2)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DIVIDE(0, 2)',
          formula: '=DIVIDE(0, 2)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=DIVIDE(2, 0)',
          formula: '=DIVIDE(2, 0)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=POW(2, 8)',
          formula: '=POW(2, 8)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=EQ("foo", "foo")',
          formula: '=EQ("foo", "foo")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=NE(3, 4)',
          formula: '=NE(3, 4)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=GTE(1.1, 1.1)',
          formula: '=GTE(1.1, 1.1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=LT(1.2, 1.2)',
          formula: '=LT(1.2, 1.2)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=LTE(1.2, 1.2)',
          formula: '=LTE(1.2, 1.2)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=ADD("value")',
          formula: '=ADD("value")',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=GT(3, 2)',
          formula: '=GT(3, 2)',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=LE(2, 2)',
          formula: '=LE(2, 2)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ADD()',
          formula: '=ADD()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=ADD(3)',
          formula: '=ADD(3)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=ADD(3, 5, 6, 7, 1)',
          formula: '=ADD(3, 5, 6, 7, 1)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=ADD(3.01, 5.02)',
          formula: '=ADD(3.01, 5.02)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=ADD(3, -5)',
          formula: '=ADD(3, -5)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=DIVIDE()',
          formula: '=DIVIDE()',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=DIVIDE("value")',
          formula: '=DIVIDE("value")',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=DIVIDE(1)',
          formula: '=DIVIDE(1)',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=DIVIDE(0, 0)',
          formula: '=DIVIDE(0, 0)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=EQ()',
          formula: '=EQ()',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=EQ("value")',
          formula: '=EQ("value")',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=EQ(1, 1)',
          formula: '=EQ(1, 1)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=EQ("bar", "foo")',
          formula: '=EQ("bar", "foo")',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=EQ(12.2, 12.3)',
          formula: '=EQ(12.2, 12.3)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=GTE()',
          formula: '=GTE()',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=GTE("value")',
          formula: '=GTE("value")',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=GTE(1)',
          formula: '=GTE(1)',
        ),
        const FortuneCellCoord(3, 8): const FortuneCell(
          value: '=GTE(1, 2)',
          formula: '=GTE(1, 2)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=LT()',
          formula: '=LT()',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=LT("value")',
          formula: '=LT("value")',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=LT(1)',
          formula: '=LT(1)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=LT(1, 2)',
          formula: '=LT(1, 2)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=LT(1.1, 1.2)',
          formula: '=LT(1.1, 1.2)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=LT(1.3, 1.2)',
          formula: '=LT(1.3, 1.2)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=LTE()',
          formula: '=LTE()',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=LTE("value")',
          formula: '=LTE("value")',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=LTE(1)',
          formula: '=LTE(1)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=LTE(1, 2)',
          formula: '=LTE(1, 2)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=LTE(1.1, 1.2)',
          formula: '=LTE(1.1, 1.2)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=LTE(1.3, 1.2)',
          formula: '=LTE(1.3, 1.2)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=MINUS()',
          formula: '=MINUS()',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=MINUS("value")',
          formula: '=MINUS("value")',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=MINUS(1)',
          formula: '=MINUS(1)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=MINUS(1, 2)',
          formula: '=MINUS(1, 2)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=MINUS(1.1, 1.2)',
          formula: '=MINUS(1.1, 1.2)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=MINUS(1.2, 1.2)',
          formula: '=MINUS(1.2, 1.2)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=MINUS(1.3, 1.2)',
          formula: '=MINUS(1.3, 1.2)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=MULTIPLY()',
          formula: '=MULTIPLY()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=MULTIPLY("value")',
          formula: '=MULTIPLY("value")',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=MULTIPLY(1)',
          formula: '=MULTIPLY(1)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=MULTIPLY(3, 4)',
          formula: '=MULTIPLY(3, 4)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=MULTIPLY(3, -4)',
          formula: '=MULTIPLY(3, -4)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=NE()',
          formula: '=NE()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=NE("value")',
          formula: '=NE("value")',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=NE(1)',
          formula: '=NE(1)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=NE(3, -4)',
          formula: '=NE(3, -4)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=NE(2, 2.2)',
          formula: '=NE(2, 2.2)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=NE(2.2, 2.2)',
          formula: '=NE(2.2, 2.2)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=POW()',
          formula: '=POW()',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=POW("value")',
          formula: '=POW("value")',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=POW(2)',
          formula: '=POW(2)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=POW(2, 4)',
          formula: '=POW(2, 4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0.1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '4.4');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '256');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '8.03');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '-2');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 8)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '-0.1');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '0.1');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '-12');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '16');
  });

  test('formula engine evaluates aggregate and subtotal functions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '120'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '10'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '150'),
        const FortuneCellCoord(1, 3): const FortuneCell(value: '23'),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=AGGREGATE(1, 4, A1:C1)',
          formula: '=AGGREGATE(1, 4, A1:C1)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=AGGREGATE(6, 4, A1:C1)',
          formula: '=AGGREGATE(6, 4, A1:C1)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=AGGREGATE(10, 4, A1:C1, 2)',
          formula: '=AGGREGATE(10, 4, A1:C1, 2)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=SUBTOTAL(9, A2:D2)',
          formula: '=SUBTOTAL(9, A2:D2)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=AGGREGATE(15, 4, A1:C1, 2)',
          formula: '=AGGREGATE(15, 4, A1:C1, 2)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=AGGREGATE(12, 4, A1:C1)',
          formula: '=AGGREGATE(12, 4, A1:C1)',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=AGGREGATE(13, 4, A6:D6)',
          formula: '=AGGREGATE(13, 4, A6:D6)',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=AGGREGATE(14, 4, A2:D2, 2)',
          formula: '=AGGREGATE(14, 4, A2:D2, 2)',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=AGGREGATE(16, 4, A1:C1, 0.5)',
          formula: '=AGGREGATE(16, 4, A1:C1, 0.5)',
        ),
        const FortuneCellCoord(2, 9): const FortuneCell(
          value: '=AGGREGATE(17, 4, A1:C1, 1)',
          formula: '=AGGREGATE(17, 4, A1:C1, 1)',
        ),
        const FortuneCellCoord(2, 10): const FortuneCell(
          value: '=AGGREGATE(18, 4, A1:C1, 0.5)',
          formula: '=AGGREGATE(18, 4, A1:C1, 0.5)',
        ),
        const FortuneCellCoord(2, 11): const FortuneCell(
          value: '=AGGREGATE(19, 4, A1:C1, 2)',
          formula: '=AGGREGATE(19, 4, A1:C1, 2)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=AGGREGATE(1, 4, A5:B5)/(10^308)',
          formula: '=AGGREGATE(1, 4, A5:B5)/(10^308)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=AGGREGATE(6, 4, A5:B5)',
          formula: '=AGGREGATE(6, 4, A5:B5)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=AGGREGATE(9, 4, A5:B5)',
          formula: '=AGGREGATE(9, 4, A5:B5)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=SUBTOTAL(1, A5:B5)/(10^308)',
          formula: '=SUBTOTAL(1, A5:B5)/(10^308)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=SUBTOTAL(6, A5:B5)',
          formula: '=SUBTOTAL(6, A5:B5)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=SUBTOTAL(9, A5:B5)',
          formula: '=SUBTOTAL(9, A5:B5)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(5, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(5, 2): const FortuneCell(value: '2'),
        const FortuneCellCoord(5, 3): const FortuneCell(value: '3'),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '303');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '120');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 9)]?.renderedText, '1.5');
    expect(sheet.cells[const FortuneCellCoord(2, 10)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 11)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '#NUM!');
  });

  test('formula engine evaluates SUBTOTAL range fixture', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '120'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '10'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '173'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SUBTOTAL(9, A1:C1)',
          formula: '=SUBTOTAL(9, A1:C1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '303');
  });

  test('formula engine evaluates miscellaneous array helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 10): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 11): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 10): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 11): const FortuneCell(value: '4'),
        const FortuneCellCoord(2, 10): const FortuneCell(value: '5'),
        const FortuneCellCoord(2, 11): const FortuneCell(value: '6'),
        const FortuneCellCoord(0, 12): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 13): const FortuneCell(value: '2'),
        FortuneCellCoord(1, 12): FortuneCell(rawValue: [3], hasRawValue: true),
        FortuneCellCoord(1, 13): FortuneCell(
          rawValue: [4, 5],
          hasRawValue: true,
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=INDEX(ARGS2ARRAY(1, 4, 4, 3), 1, 2)',
          formula: '=INDEX(ARGS2ARRAY(1, 4, 4, 3), 1, 2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=COLUMNS(ARGS2ARRAY("foo", "bar", "foo"))',
          formula: '=COLUMNS(ARGS2ARRAY("foo", "bar", "foo"))',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=INDEX(FLATTEN(A1:B2), 1, 3)',
          formula: '=INDEX(FLATTEN(A1:B2), 1, 3)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=JOIN(A1:B2)',
          formula: '=JOIN(A1:B2)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=INDEX(NUMBERS(1, "4", "4", 3), 1, 2)',
          formula: '=INDEX(NUMBERS(1, "4", "4", 3), 1, 2)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=COLUMNS(NUMBERS("foo", 2, "bar", "foo"))',
          formula: '=COLUMNS(NUMBERS("foo", 2, "bar", "foo"))',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=INDEX({10,20,30}, 2)',
          formula: '=INDEX({10,20,30}, 2)',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=SUM(INDEX(A1:B2, 0, 2))',
          formula: '=SUM(INDEX(A1:B2, 0, 2))',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=SUM(INDEX(A1:B2, 2, 0))',
          formula: '=SUM(INDEX(A1:B2, 2, 0))',
        ),
        const FortuneCellCoord(2, 9): const FortuneCell(
          value: '=SUM(INDEX(A1:B2, 0, 0))',
          formula: '=SUM(INDEX(A1:B2, 0, 0))',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=JOIN(K1:L3)',
          formula: '=JOIN(K1:L3)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=INDEX(FLATTEN(K1:L3), 1, 5)',
          formula: '=INDEX(FLATTEN(K1:L3), 1, 5)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=JOIN(ARGS2ARRAY())',
          formula: '=JOIN(ARGS2ARRAY())',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=JOIN(NUMBERS())',
          formula: '=JOIN(NUMBERS())',
        ),
        const FortuneCellCoord(4, 0): FortuneCell(
          rawValue: {
            'name': {'firstName': 'Jim'},
          },
          hasRawValue: true,
        ),
        const FortuneCellCoord(4, 1): FortuneCell(
          value: '=REFERENCE(A5, "name.firstName")',
          formula: '=REFERENCE(A5, "name.firstName")',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=JOIN(M1:N2)',
          formula: '=JOIN(M1:N2)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=INDEX(FLATTEN(M1:N2), 1, 5)',
          formula: '=INDEX(FLATTEN(M1:N2), 1, 5)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '1,2,3,4');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(2, 9)]?.renderedText, '10');
    expect(
      sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText,
      '1,2,3,4,5,6',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, 'Jim');
    expect(
      sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText,
      '1,2,3,4,5',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '5');
  });

  test('formula engine evaluates REFERENCE object path fixture', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): FortuneCell(
          rawValue: {
            'name': {'firstName': 'Jim'},
            'items': [
              {'label': 'foo'},
              {'label': 'bar'},
            ],
          },
          hasRawValue: true,
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=REFERENCE(A1, "name.firstName")',
          formula: '=REFERENCE(A1, "name.firstName")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=REFERENCE(A1, "name.middle.initial")',
          formula: '=REFERENCE(A1, "name.middle.initial")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=REFERENCE(A1, "items.1.label")',
          formula: '=REFERENCE(A1, "items.1.label")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=REFERENCE(A1, "items.9.label")',
          formula: '=REFERENCE(A1, "items.9.label")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'Jim');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'bar');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#N/A');
  });

  test('formula engine evaluates FLATTEN and JOIN range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        FortuneCellCoord(1, 0): FortuneCell(rawValue: [3], hasRawValue: true),
        FortuneCellCoord(1, 1): FortuneCell(
          rawValue: [4, 5],
          hasRawValue: true,
        ),
        FortuneCellCoord(2, 0): FortuneCell(rawValue: [], hasRawValue: true),
        FortuneCellCoord(2, 1): FortuneCell(rawValue: [], hasRawValue: true),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=FLATTEN(A1:B3)',
          formula: '=FLATTEN(A1:B3)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=JOIN(A1:B3)',
          formula: '=JOIN(A1:B3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText,
      '1,2,3,4,5',
    );
  });

  test('formula engine evaluates statistical aliases and helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1, 1, 2, 2, 2],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 4): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 5): const FortuneCell(value: 'dewdew'),
        const FortuneCellCoord(0, 6): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 7): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=COUNTIN(A1:D1, 2)',
          formula: '=COUNTIN(A1:D1, 2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=COUNTUNIQUE(1, 1, 2, 2, 3, "a", "a")',
          formula: '=COUNTUNIQUE(1, 1, 2, 2, 3, "a", "a")',
        ),
        const FortuneCellCoord(59, 0): const FortuneCell(
          value: '=COUNTIN(foo, 1)',
          formula: '=COUNTIN(foo, 1)',
        ),
        const FortuneCellCoord(59, 1): const FortuneCell(
          value: '=COUNTIN(foo, 2)',
          formula: '=COUNTIN(foo, 2)',
        ),
        const FortuneCellCoord(1, 8): const FortuneCell(
          value: '=COUNT(TRUE, 0.5, "foo", 1, 8)',
          formula: '=COUNT(TRUE, 0.5, "foo", 1, 8)',
        ),
        const FortuneCellCoord(1, 9): const FortuneCell(
          value: '=COUNTA(TRUE, 0.5, "foo", 1, 8)',
          formula: '=COUNTA(TRUE, 0.5, "foo", 1, 8)',
        ),
        const FortuneCellCoord(1, 10): const FortuneCell(
          value: '=AVERAGE(1.1, TRUE, 2, NULL, 5, 10)',
          formula: '=AVERAGE(1.1, TRUE, 2, NULL, 5, 10)',
        ),
        const FortuneCellCoord(1, 11): const FortuneCell(
          value: '=AVEDEV()',
          formula: '=AVEDEV()',
        ),
        const FortuneCellCoord(1, 12): const FortuneCell(
          value: '=AVEDEV(1.1)',
          formula: '=AVEDEV(1.1)',
        ),
        const FortuneCellCoord(1, 13): const FortuneCell(
          value: '=AVEDEV(1.1, 2)',
          formula: '=AVEDEV(1.1, 2)',
        ),
        const FortuneCellCoord(1, 14): const FortuneCell(
          value: '=AVEDEV(1.1, 2, 5, 10)',
          formula: '=AVEDEV(1.1, 2, 5, 10)',
        ),
        const FortuneCellCoord(1, 15): const FortuneCell(
          value: '=AVERAGEA(1.1, TRUE, 2, NULL, 5, 10)',
          formula: '=AVERAGEA(1.1, TRUE, 2, NULL, 5, 10)',
        ),
        const FortuneCellCoord(1, 16): const FortuneCell(
          value: '=AVEDEV(1.1, 2, 5)',
          formula: '=AVEDEV(1.1, 2, 5)',
        ),
        const FortuneCellCoord(1, 17): const FortuneCell(
          value: '=AVERAGE(1.1)',
          formula: '=AVERAGE(1.1)',
        ),
        const FortuneCellCoord(1, 18): const FortuneCell(
          value: '=AVERAGE(1.1, 2, 5, 10)',
          formula: '=AVERAGE(1.1, 2, 5, 10)',
        ),
        const FortuneCellCoord(1, 19): const FortuneCell(
          value: '=AVERAGEA(1.1)',
          formula: '=AVERAGEA(1.1)',
        ),
        const FortuneCellCoord(1, 20): const FortuneCell(
          value: '=AVERAGEA(1.1, 2, 5, 10)',
          formula: '=AVERAGEA(1.1, 2, 5, 10)',
        ),
        const FortuneCellCoord(1, 21): const FortuneCell(
          value: '=COUNT()',
          formula: '=COUNT()',
        ),
        const FortuneCellCoord(1, 22): const FortuneCell(
          value: '=COUNT(0.5)',
          formula: '=COUNT(0.5)',
        ),
        const FortuneCellCoord(1, 23): const FortuneCell(
          value: '=COUNTA()',
          formula: '=COUNTA()',
        ),
        const FortuneCellCoord(1, 24): const FortuneCell(
          value: '=COUNTA(0.5)',
          formula: '=COUNTA(0.5)',
        ),
        const FortuneCellCoord(1, 25): const FortuneCell(
          value: '=COUNTBLANK()',
          formula: '=COUNTBLANK()',
        ),
        const FortuneCellCoord(1, 26): const FortuneCell(
          value: '=COUNTBLANK(0.5)',
          formula: '=COUNTBLANK(0.5)',
        ),
        const FortuneCellCoord(1, 27): const FortuneCell(
          value: '=COUNTBLANK(TRUE, 0.5, "", 1, 8)',
          formula: '=COUNTBLANK(TRUE, 0.5, "", 1, 8)',
        ),
        const FortuneCellCoord(1, 28): const FortuneCell(
          value: '=COUNTUNIQUE()',
          formula: '=COUNTUNIQUE()',
        ),
        const FortuneCellCoord(1, 29): const FortuneCell(
          value: '=COUNTUNIQUE(1, 1, 2, 2, 3)',
          formula: '=COUNTUNIQUE(1, 1, 2, 2, 3)',
        ),
        const FortuneCellCoord(1, 30): const FortuneCell(
          value: '=COUNTUNIQUE(NULL, "", 0)',
          formula: '=COUNTUNIQUE(NULL, "", 0)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=PERCENTILEINC(A1:D1, 0.5)',
          formula: '=PERCENTILEINC(A1:D1, 0.5)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=PERCENTILEEXC(A1:D1, 0.5)',
          formula: '=PERCENTILEEXC(A1:D1, 0.5)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=QUARTILEINC(A1:D1, 1)',
          formula: '=QUARTILEINC(A1:D1, 1)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=PERCENTRANKINC(A1:D1, 4)',
          formula: '=PERCENTRANKINC(A1:D1, 4)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=RANKAVG(2, A1:D1, 1)',
          formula: '=RANKAVG(2, A1:D1, 1)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=RANKEQ(2, A1:D1)',
          formula: '=RANKEQ(2, A1:D1)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=PERCENTILE(A1:D1, 0.5)',
          formula: '=PERCENTILE(A1:D1, 0.5)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=QUARTILE(A1:D1, 1)',
          formula: '=QUARTILE(A1:D1, 1)',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=PERCENTILEINC(E1:H1, 0.5)',
          formula: '=PERCENTILEINC(E1:H1, 0.5)',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=PERCENTILEEXC(E1:H1, 0.5)',
          formula: '=PERCENTILEEXC(E1:H1, 0.5)',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=PERCENTRANKINC(E1:H1, 4)',
          formula: '=PERCENTRANKINC(E1:H1, 4)',
        ),
        const FortuneCellCoord(2, 9): const FortuneCell(
          value: '=PERCENTRANKEXC(E1:H1, 4)',
          formula: '=PERCENTRANKEXC(E1:H1, 4)',
        ),
        const FortuneCellCoord(2, 10): const FortuneCell(
          value: '=PERCENTRANKEXC(A1:D1, 1)',
          formula: '=PERCENTRANKEXC(A1:D1, 1)',
        ),
        const FortuneCellCoord(2, 11): const FortuneCell(
          value: '=PERCENTRANKEXC(A1:D1, 4)',
          formula: '=PERCENTRANKEXC(A1:D1, 4)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=VARS(A1:D1)',
          formula: '=VARS(A1:D1)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=VARA(1, 2, TRUE, "foo")',
          formula: '=VARA(1, 2, TRUE, "foo")',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=STDEVA(1, 2, TRUE, "foo")',
          formula: '=STDEVA(1, 2, TRUE, "foo")',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=STDEVPA(1, 2, TRUE, "foo")',
          formula: '=STDEVPA(1, 2, TRUE, "foo")',
        ),
        const FortuneCellCoord(3, 8): const FortuneCell(
          value: '=VAR.S(1, 2, 3, 4, TRUE, "foo")',
          formula: '=VAR.S(1, 2, 3, 4, TRUE, "foo")',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=EXPONDIST(0.2, 10, TRUE)',
          formula: '=EXPONDIST(0.2, 10, TRUE)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=POISSONDIST(2, 5, FALSE)',
          formula: '=POISSONDIST(2, 5, FALSE)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=BINOM.DIST.RANGE(60, 0.5, 34)',
          formula: '=BINOM.DIST.RANGE(60, 0.5, 34)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=FINVRT(0.1, 6, 4)',
          formula: '=FINVRT(0.1, 6, 4)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=CHISQ.DIST(0.5, 1)',
          formula: '=CHISQ.DIST(0.5, 1)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=LOGNORMINV(0.039084, 3.5, 1.2)',
          formula: '=LOGNORMINV(0.039084, 3.5, 1.2)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=WEIBULLDIST(105, 20, 100, TRUE)',
          formula: '=WEIBULLDIST(105, 20, 100, TRUE)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=MODESNGL(5.6, 4, 4, 3, 2, 4)',
          formula: '=MODESNGL(5.6, 4, 4, 3, 2, 4)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3), 1, 2)',
          formula: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3), 1, 2)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=COLUMNS(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3))',
          formula: '=COLUMNS(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3))',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=SKEWP(3, 4, 5, 2, 3, 4, 5, 6, 4, 7)',
          formula: '=SKEWP(3, 4, 5, 2, 3, 4, 5, 6, 4, 7)',
        ),
        const FortuneCellCoord(5, 6): const FortuneCell(
          value: '=MODE(5.6, 4, 4, 3, 2, 4)',
          formula: '=MODE(5.6, 4, 4, 3, 2, 4)',
        ),
        const FortuneCellCoord(5, 7): const FortuneCell(
          value: '=ZTEST(A1:D1, 2, 1)',
          formula: '=ZTEST(A1:D1, 2, 1)',
        ),
        const FortuneCellCoord(5, 8): const FortuneCell(
          value: '=NORMSDIST(1)',
          formula: '=NORMSDIST(1)',
        ),
        const FortuneCellCoord(5, 9): const FortuneCell(
          value: '=NORMSDIST(1, TRUE)',
          formula: '=NORMSDIST(1, TRUE)',
        ),
        const FortuneCellCoord(5, 10): const FortuneCell(
          value: '=MODESNGL(5.6, "dewdew", 4, 3, 2, 4)',
          formula: '=MODESNGL(5.6, "dewdew", 4, 3, 2, 4)',
        ),
        const FortuneCellCoord(5, 11): const FortuneCell(
          value: '=MODEMULT(1, 2, "dewdew", 4, 3, 2, 1, 2, 3, 5, 6, 1)',
          formula: '=MODEMULT(1, 2, "dewdew", 4, 3, 2, 1, 2, 3, 5, 6, 1)',
        ),
        const FortuneCellCoord(5, 12): const FortuneCell(
          value: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 1)',
          formula: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 1)',
        ),
        const FortuneCellCoord(5, 13): const FortuneCell(
          value: '=INDEX(MODE.MULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 2)',
          formula:
              '=INDEX(MODE.MULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 2)',
        ),
        const FortuneCellCoord(5, 14): const FortuneCell(
          value: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 3)',
          formula: '=INDEX(MODEMULT(1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1), 1, 3)',
        ),
        const FortuneCellCoord(5, 15): const FortuneCell(
          value: '=NORMINV(1, 0, 1)',
          formula: '=NORMINV(1, 0, 1)',
        ),
        const FortuneCellCoord(5, 16): const FortuneCell(
          value: '=NORMSINV(1)',
          formula: '=NORMSINV(1)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=CHISQ.DIST.RT()',
          formula: '=CHISQ.DIST.RT()',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=CHISQ.DIST.RT(0.5)',
          formula: '=CHISQ.DIST.RT(0.5)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=CHISQ.INV.RT()',
          formula: '=CHISQ.INV.RT()',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=CHISQ.INV.RT(0.5)',
          formula: '=CHISQ.INV.RT(0.5)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=FINVRT()',
          formula: '=FINVRT()',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=FINVRT(0.1)',
          formula: '=FINVRT(0.1)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=FINVRT(0.1, 6)',
          formula: '=FINVRT(0.1, 6)',
        ),
        const FortuneCellCoord(6, 7): const FortuneCell(
          value: '=FDIST(15, 6, 4)',
          formula: '=FDIST(15, 6, 4)',
        ),
        const FortuneCellCoord(6, 8): const FortuneCell(
          value: '=FDIST(15, 6, 4, TRUE)',
          formula: '=FDIST(15, 6, 4, TRUE)',
        ),
        const FortuneCellCoord(6, 9): const FortuneCell(
          value: '=FINV(0.1, 6, 4)',
          formula: '=FINV(0.1, 6, 4)',
        ),
        const FortuneCellCoord(6, 10): const FortuneCell(
          value: '=CHISQ.DIST.RT(0.5, 1)',
          formula: '=CHISQ.DIST.RT(0.5, 1)',
        ),
        const FortuneCellCoord(6, 11): const FortuneCell(
          value: '=F.INV.RT(0.1, 6, 4)',
          formula: '=F.INV.RT(0.1, 6, 4)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=EXPONDIST(0.2, 10)',
          formula: '=EXPONDIST(0.2, 10)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=NORMDIST(1, 0, 1)',
          formula: '=NORMDIST(1, 0, 1)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=LOGNORMDIST(4, 3.5, 1.2)',
          formula: '=LOGNORMDIST(4, 3.5, 1.2)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=POISSONDIST(1, 3)',
          formula: '=POISSONDIST(1, 3)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=NEGBINOMDIST(10, 5, 0.25)',
          formula: '=NEGBINOMDIST(10, 5, 0.25)',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=NEGBINOMDIST(10, 5, 0.25, TRUE)',
          formula: '=NEGBINOMDIST(10, 5, 0.25, TRUE)',
        ),
        const FortuneCellCoord(7, 6): const FortuneCell(
          value: '=HYPGEOMDIST(1, 4, 8, 20, TRUE)',
          formula: '=HYPGEOMDIST(1, 4, 8, 20, TRUE)',
        ),
        const FortuneCellCoord(7, 7): const FortuneCell(
          value: '=WEIBULLDIST(1, 2, 3)',
          formula: '=WEIBULLDIST(1, 2, 3)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=GAMMADIST()',
          formula: '=GAMMADIST()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=GAMMADIST(1)',
          formula: '=GAMMADIST(1)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=GAMMADIST(1, 3)',
          formula: '=GAMMADIST(1, 3)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=GAMMADIST(1, 3, 7)',
          formula: '=GAMMADIST(1, 3, 7)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=GAMMAINV()',
          formula: '=GAMMAINV()',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=GAMMAINV(1)',
          formula: '=GAMMAINV(1)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=GAMMAINV(1, 3)',
          formula: '=GAMMAINV(1, 3)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=GAMMALN.PRECISE()',
          formula: '=GAMMALN.PRECISE()',
        ),
        const FortuneCellCoord(8, 8): const FortuneCell(
          value: '=GAMMALN.PRECISE(4)',
          formula: '=GAMMALN.PRECISE(4)',
        ),
        const FortuneCellCoord(8, 9): const FortuneCell(
          value: '=GAMMAINV(1, 3, 7)',
          formula: '=GAMMAINV(1, 3, 7)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=VAR_S(A1:D1)',
          formula: '=VAR_S(A1:D1)',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=VAR_P(A1:D1)',
          formula: '=VAR_P(A1:D1)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=COVARIANCE_P(A1:C1, B1:D1)',
          formula: '=COVARIANCE_P(A1:C1, B1:D1)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=COVARIANCE_S(A1:C1, B1:D1)',
          formula: '=COVARIANCE_S(A1:C1, B1:D1)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=POISSON_DIST(2, 5, FALSE)',
          formula: '=POISSON_DIST(2, 5, FALSE)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=NORM_DIST(1, 0, 1, TRUE)',
          formula: '=NORM_DIST(1, 0, 1, TRUE)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=ROUND(NORM_S_INV(0.841344746069), 6)',
          formula: '=ROUND(NORM_S_INV(0.841344746069), 6)',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=BINOM_DIST(2, 5, 0.5, FALSE)',
          formula: '=BINOM_DIST(2, 5, 0.5, FALSE)',
        ),
        const FortuneCellCoord(9, 8): const FortuneCell(
          value: '=RANK_EQ(2, A1:D1)',
          formula: '=RANK_EQ(2, A1:D1)',
        ),
        const FortuneCellCoord(9, 9): const FortuneCell(
          value: '=RANK_AVG(2, A1:D1)',
          formula: '=RANK_AVG(2, A1:D1)',
        ),
        const FortuneCellCoord(9, 10): const FortuneCell(
          value: '=ROUND(T_TEST({1,2,5}, {2,4,6}, 2, 1), 6)',
          formula: '=ROUND(T_TEST({1,2,5}, {2,4,6}, 2, 1), 6)',
        ),
        const FortuneCellCoord(9, 11): const FortuneCell(
          value: '=ROUND(T.TEST({1,2,5}, {2,4,6}, 1, 1), 6)',
          formula: '=ROUND(T.TEST({1,2,5}, {2,4,6}, 1, 1), 6)',
        ),
        const FortuneCellCoord(9, 12): const FortuneCell(
          value: '=ISNUMBER(TTEST({1,2,3}, {2,4,8}, 2, 2))',
          formula: '=ISNUMBER(TTEST({1,2,3}, {2,4,8}, 2, 2))',
        ),
        const FortuneCellCoord(9, 13): const FortuneCell(
          value: '=ISNUMBER(T_TEST({1,2,3}, {2,4,8}, 2, 3))',
          formula: '=ISNUMBER(T_TEST({1,2,3}, {2,4,8}, 2, 3))',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=AVERAGEA()',
          formula: '=AVERAGEA()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=MINA()',
          formula: '=MINA()',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=MAXA()',
          formula: '=MAXA()',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=VARS()',
          formula: '=VARS()',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=VARA()',
          formula: '=VARA()',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=VARP()',
          formula: '=VARP()',
        ),
        const FortuneCellCoord(10, 6): const FortuneCell(
          value: '=VARPA()',
          formula: '=VARPA()',
        ),
        const FortuneCellCoord(10, 7): const FortuneCell(
          value: '=AVERAGE()',
          formula: '=AVERAGE()',
        ),
        const FortuneCellCoord(10, 8): const FortuneCell(
          value: '=MEDIAN()',
          formula: '=MEDIAN()',
        ),
        const FortuneCellCoord(10, 9): const FortuneCell(
          value: '=MIN()',
          formula: '=MIN()',
        ),
        const FortuneCellCoord(10, 10): const FortuneCell(
          value: '=MAX()',
          formula: '=MAX()',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=FDISTRT()',
          formula: '=FDISTRT()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=FDISTRT(15, 6)',
          formula: '=FDISTRT(15, 6)',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=T.DIST.RT()',
          formula: '=T.DIST.RT()',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=T.DIST.RT(1)',
          formula: '=T.DIST.RT(1)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=T.DIST.2T()',
          formula: '=T.DIST.2T()',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=T.DIST.2T(1)',
          formula: '=T.DIST.2T(1)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=BETAINV()',
          formula: '=BETAINV()',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=BETAINV(0.6854705810117458, 8, 10, 1, 3)',
          formula: '=BETAINV(0.6854705810117458, 8, 10, 1, 3)',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=BETA.INV(0.6854705810117458, 8, 10, 1, 3)',
          formula: '=BETA.INV(0.6854705810117458, 8, 10, 1, 3)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=BINOMDIST()',
          formula: '=BINOMDIST()',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=BINOMDIST(6)',
          formula: '=BINOMDIST(6)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=BINOMDIST(6, 10, 0.5)',
          formula: '=BINOMDIST(6, 10, 0.5)',
        ),
        const FortuneCellCoord(12, 6): const FortuneCell(
          value: '=BINOMDIST(6, 10, 0.5, FALSE)',
          formula: '=BINOMDIST(6, 10, 0.5, FALSE)',
        ),
        const FortuneCellCoord(12, 7): const FortuneCell(
          value: '=BINOM.DIST(6, 10, 0.5, FALSE)',
          formula: '=BINOM.DIST(6, 10, 0.5, FALSE)',
        ),
        const FortuneCellCoord(12, 8): const FortuneCell(
          value: '=BINOM.INV()',
          formula: '=BINOM.INV()',
        ),
        const FortuneCellCoord(12, 9): const FortuneCell(
          value: '=BINOM.INV(6, 0.5)',
          formula: '=BINOM.INV(6, 0.5)',
        ),
        const FortuneCellCoord(12, 10): const FortuneCell(
          value: '=BINOM.INV(6, 0.5, 0.7)',
          formula: '=BINOM.INV(6, 0.5, 0.7)',
        ),
        const FortuneCellCoord(12, 11): const FortuneCell(
          value: '=BINOMDIST(6, 10)',
          formula: '=BINOMDIST(6, 10)',
        ),
        const FortuneCellCoord(12, 12): const FortuneCell(
          value: '=BINOM.DIST.RANGE()',
          formula: '=BINOM.DIST.RANGE()',
        ),
        const FortuneCellCoord(12, 13): const FortuneCell(
          value: '=BINOM.DIST.RANGE(60)',
          formula: '=BINOM.DIST.RANGE(60)',
        ),
        const FortuneCellCoord(12, 14): const FortuneCell(
          value: '=BINOM.DIST.RANGE(60, 0.5)',
          formula: '=BINOM.DIST.RANGE(60, 0.5)',
        ),
        const FortuneCellCoord(12, 15): const FortuneCell(
          value: '=BINOM.INV(6)',
          formula: '=BINOM.INV(6)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=CONFIDENCE()',
          formula: '=CONFIDENCE()',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=CONFIDENCE(0.5)',
          formula: '=CONFIDENCE(0.5)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=CONFIDENCE(0.5, 1)',
          formula: '=CONFIDENCE(0.5, 1)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=CONFIDENCE(0.5, 1, 5)',
          formula: '=CONFIDENCE(0.5, 1, 5)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=CONFIDENCE.NORM(0.5, 1, 5)',
          formula: '=CONFIDENCE.NORM(0.5, 1, 5)',
        ),
        const FortuneCellCoord(13, 5): const FortuneCell(
          value: '=CONFIDENCE.T()',
          formula: '=CONFIDENCE.T()',
        ),
        const FortuneCellCoord(13, 6): const FortuneCell(
          value: '=CONFIDENCE.T(0.5)',
          formula: '=CONFIDENCE.T(0.5)',
        ),
        const FortuneCellCoord(13, 7): const FortuneCell(
          value: '=CONFIDENCE.T(0.5, 1)',
          formula: '=CONFIDENCE.T(0.5, 1)',
        ),
        const FortuneCellCoord(13, 8): const FortuneCell(
          value: '=CONFIDENCE.T(0.5, 1, 5)',
          formula: '=CONFIDENCE.T(0.5, 1, 5)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=CORREL()',
          formula: '=CORREL()',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=CORREL({3,2,4,5,6}, {9,7,12,15,17})',
          formula: '=CORREL({3,2,4,5,6}, {9,7,12,15,17})',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=COVARIANCE.P({3,2,4,5,6}, {9,7,12,15,17})',
          formula: '=COVARIANCE.P({3,2,4,5,6}, {9,7,12,15,17})',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=COVARIANCE.S({2,4,8}, {5,11,12})',
          formula: '=COVARIANCE.S({2,4,8}, {5,11,12})',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=DEVSQ({4,5,8,7,11,4,3})',
          formula: '=DEVSQ({4,5,8,7,11,4,3})',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=EXPONDIST()',
          formula: '=EXPONDIST()',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=EXPONDIST(0.2)',
          formula: '=EXPONDIST(0.2)',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=EXPON.DIST(0.2, 10, TRUE)',
          formula: '=EXPON.DIST(0.2, 10, TRUE)',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=FDIST()',
          formula: '=FDIST()',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=FDIST(15)',
          formula: '=FDIST(15)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=FDIST(15, 6)',
          formula: '=FDIST(15, 6)',
        ),
        const FortuneCellCoord(15, 6): const FortuneCell(
          value: '=F.DIST(15, 6, 4, TRUE)',
          formula: '=F.DIST(15, 6, 4, TRUE)',
        ),
        const FortuneCellCoord(15, 7): const FortuneCell(
          value: '=FDISTRT(15)',
          formula: '=FDISTRT(15)',
        ),
        const FortuneCellCoord(15, 8): const FortuneCell(
          value: '=FDISTRT(15, 6, 4)',
          formula: '=FDISTRT(15, 6, 4)',
        ),
        const FortuneCellCoord(15, 9): const FortuneCell(
          value: '=F.DIST.RT(15, 6, 4)',
          formula: '=F.DIST.RT(15, 6, 4)',
        ),
        const FortuneCellCoord(15, 10): const FortuneCell(
          value: '=FINV()',
          formula: '=FINV()',
        ),
        const FortuneCellCoord(15, 11): const FortuneCell(
          value: '=FINV(0.1)',
          formula: '=FINV(0.1)',
        ),
        const FortuneCellCoord(15, 12): const FortuneCell(
          value: '=FINV(0.1, 6)',
          formula: '=FINV(0.1, 6)',
        ),
        const FortuneCellCoord(15, 13): const FortuneCell(
          value: '=F.INV(0.1, 6, 4)',
          formula: '=F.INV(0.1, 6, 4)',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=FISHER()',
          formula: '=FISHER()',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=FISHER(0.1)',
          formula: '=FISHER(0.1)',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=FISHER(1)',
          formula: '=FISHER(1)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=FISHERINV()',
          formula: '=FISHERINV()',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=FISHERINV(0.1)',
          formula: '=FISHERINV(0.1)',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=FISHERINV(1)',
          formula: '=FISHERINV(1)',
        ),
        const FortuneCellCoord(16, 6): const FortuneCell(
          value: '=FORECAST(30, {6,7,9,15,21}, {20,28,31,38,40})',
          formula: '=FORECAST(30, {6,7,9,15,21}, {20,28,31,38,40})',
        ),
        const FortuneCellCoord(16, 7): const FortuneCell(
          value:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 1)',
          formula:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 1)',
        ),
        const FortuneCellCoord(16, 8): const FortuneCell(
          value:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 2)',
          formula:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 2)',
        ),
        const FortuneCellCoord(16, 9): const FortuneCell(
          value:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 3)',
          formula:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 3)',
        ),
        const FortuneCellCoord(16, 10): const FortuneCell(
          value:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 4)',
          formula:
              '=INDEX(FREQUENCY({79,85,78,85,50,81,95,88,97}, {70,79,89}), 1, 4)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=GAMMA()',
          formula: '=GAMMA()',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=GAMMA(0.1)',
          formula: '=GAMMA(0.1)',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=GAMMADIST(1, 3, 7, TRUE)',
          formula: '=GAMMADIST(1, 3, 7, TRUE)',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=GAMMA.DIST(1, 3, 7, TRUE)',
          formula: '=GAMMA.DIST(1, 3, 7, TRUE)',
        ),
        const FortuneCellCoord(17, 4): const FortuneCell(
          value: '=GAMMA.INV(1, 3, 7)',
          formula: '=GAMMA.INV(1, 3, 7)',
        ),
        const FortuneCellCoord(17, 5): const FortuneCell(
          value: '=GAMMALN()',
          formula: '=GAMMALN()',
        ),
        const FortuneCellCoord(17, 6): const FortuneCell(
          value: '=GAMMALN(4)',
          formula: '=GAMMALN(4)',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(
          value: '=GAUSS()',
          formula: '=GAUSS()',
        ),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=GAUSS(4)',
          formula: '=GAUSS(4)',
        ),
        const FortuneCellCoord(18, 2): const FortuneCell(
          value: '=GEOMEAN({4,5,8,7,11,4,3})',
          formula: '=GEOMEAN({4,5,8,7,11,4,3})',
        ),
        const FortuneCellCoord(18, 3): const FortuneCell(
          value: '=HARMEAN({4,5,8,7,11,4,3})',
          formula: '=HARMEAN({4,5,8,7,11,4,3})',
        ),
        const FortuneCellCoord(18, 4): const FortuneCell(
          value: '=HYPGEOMDIST()',
          formula: '=HYPGEOMDIST()',
        ),
        const FortuneCellCoord(18, 5): const FortuneCell(
          value: '=HYPGEOMDIST(1)',
          formula: '=HYPGEOMDIST(1)',
        ),
        const FortuneCellCoord(18, 6): const FortuneCell(
          value: '=HYPGEOMDIST(1, 4)',
          formula: '=HYPGEOMDIST(1, 4)',
        ),
        const FortuneCellCoord(18, 7): const FortuneCell(
          value: '=HYPGEOMDIST(1, 4, 8)',
          formula: '=HYPGEOMDIST(1, 4, 8)',
        ),
        const FortuneCellCoord(18, 8): const FortuneCell(
          value: '=HYPGEOMDIST(1, 4, 8, 20)',
          formula: '=HYPGEOMDIST(1, 4, 8, 20)',
        ),
        const FortuneCellCoord(18, 9): const FortuneCell(
          value: '=HYPGEOMDIST(1, 4, 8, 20, TRUE)',
          formula: '=HYPGEOMDIST(1, 4, 8, 20, TRUE)',
        ),
        const FortuneCellCoord(19, 0): const FortuneCell(
          value: '=INTERCEPT({2,3,9,1,8}, {6,5,11,7,5})',
          formula: '=INTERCEPT({2,3,9,1,8}, {6,5,11,7,5})',
        ),
        const FortuneCellCoord(19, 1): const FortuneCell(
          value: '=KURT({3,4,5,2,3,4,5,6,4,7})',
          formula: '=KURT({3,4,5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(19, 2): const FortuneCell(
          value: '=KURT({3,4,5,2,3,4,5,"dewdwe",4,7})',
          formula: '=KURT({3,4,5,2,3,4,5,"dewdwe",4,7})',
        ),
        const FortuneCellCoord(19, 3): const FortuneCell(
          value: '=LARGE({3,5,3,5,4}, 3)',
          formula: '=LARGE({3,5,3,5,4}, 3)',
        ),
        const FortuneCellCoord(19, 4): const FortuneCell(
          value: '=LARGE({3,5,3,"dwedwed",4}, 3)',
          formula: '=LARGE({3,5,3,"dwedwed",4}, 3)',
        ),
        const FortuneCellCoord(20, 0): const FortuneCell(
          value:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 1)',
          formula:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 1)',
        ),
        const FortuneCellCoord(20, 1): const FortuneCell(
          value:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 5)',
          formula:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 5)',
        ),
        const FortuneCellCoord(20, 2): const FortuneCell(
          value:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 9)',
          formula:
              '=INDEX(GROWTH({33100,47300,69000,102000,150000,220000}, {11,12,13,14,15,16}, {11,12,13,14,15,16,17,18,19}), 1, 9)',
        ),
        const FortuneCellCoord(21, 0): const FortuneCell(
          value: '=INDEX(LINEST({1,9,5,7}, {0,4,2,3}), 1, 1)',
          formula: '=INDEX(LINEST({1,9,5,7}, {0,4,2,3}), 1, 1)',
        ),
        const FortuneCellCoord(21, 1): const FortuneCell(
          value: '=INDEX(LINEST({1,9,5,7}, {0,4,2,3}), 1, 2)',
          formula: '=INDEX(LINEST({1,9,5,7}, {0,4,2,3}), 1, 2)',
        ),
        const FortuneCellCoord(21, 2): const FortuneCell(
          value: '=LINEST({1,9,5,7}, "aaaaaa")',
          formula: '=LINEST({1,9,5,7}, "aaaaaa")',
        ),
        const FortuneCellCoord(21, 3): const FortuneCell(
          value: '=INDEX(LOGEST({1,9,5,7}, {0,4,2,3}), 1, 1)',
          formula: '=INDEX(LOGEST({1,9,5,7}, {0,4,2,3}), 1, 1)',
        ),
        const FortuneCellCoord(21, 4): const FortuneCell(
          value: '=INDEX(LOGEST({1,9,5,7}, {0,4,2,3}), 1, 2)',
          formula: '=INDEX(LOGEST({1,9,5,7}, {0,4,2,3}), 1, 2)',
        ),
        const FortuneCellCoord(21, 5): const FortuneCell(
          value: '=LOGEST({1,9,5,7}, "aaaaaa")',
          formula: '=LOGEST({1,9,5,7}, "aaaaaa")',
        ),
        const FortuneCellCoord(22, 0): const FortuneCell(
          value: '=LOGNORMDIST()',
          formula: '=LOGNORMDIST()',
        ),
        const FortuneCellCoord(22, 1): const FortuneCell(
          value: '=LOGNORMDIST(4)',
          formula: '=LOGNORMDIST(4)',
        ),
        const FortuneCellCoord(22, 2): const FortuneCell(
          value: '=LOGNORMDIST(4, 3.5)',
          formula: '=LOGNORMDIST(4, 3.5)',
        ),
        const FortuneCellCoord(22, 3): const FortuneCell(
          value: '=LOGNORMDIST(4, 3.5, 1.2)',
          formula: '=LOGNORMDIST(4, 3.5, 1.2)',
        ),
        const FortuneCellCoord(22, 4): const FortuneCell(
          value: '=LOGNORMDIST(4, 3.5, 1.2, TRUE)',
          formula: '=LOGNORMDIST(4, 3.5, 1.2, TRUE)',
        ),
        const FortuneCellCoord(22, 5): const FortuneCell(
          value: '=LOGNORM.DIST(4, 3.5, 1.2, TRUE)',
          formula: '=LOGNORM.DIST(4, 3.5, 1.2, TRUE)',
        ),
        const FortuneCellCoord(23, 0): const FortuneCell(
          value: '=LOGNORMINV()',
          formula: '=LOGNORMINV()',
        ),
        const FortuneCellCoord(23, 1): const FortuneCell(
          value: '=LOGNORMINV(0.0390835557068005)',
          formula: '=LOGNORMINV(0.0390835557068005)',
        ),
        const FortuneCellCoord(23, 2): const FortuneCell(
          value: '=LOGNORMINV(0.0390835557068005, 3.5)',
          formula: '=LOGNORMINV(0.0390835557068005, 3.5)',
        ),
        const FortuneCellCoord(23, 3): const FortuneCell(
          value: '=LOGNORMINV(0.0390835557068005, 3.5, 1.2)',
          formula: '=LOGNORMINV(0.0390835557068005, 3.5, 1.2)',
        ),
        const FortuneCellCoord(23, 4): const FortuneCell(
          value: '=LOGNORM.INV(0.0390835557068005, 3.5, 1.2)',
          formula: '=LOGNORM.INV(0.0390835557068005, 3.5, 1.2)',
        ),
        const FortuneCellCoord(24, 0): const FortuneCell(
          value: '=MAX(-1, 9, 9.2, 4, "foo", TRUE)',
          formula: '=MAX(-1, 9, 9.2, 4, "foo", TRUE)',
        ),
        const FortuneCellCoord(24, 1): const FortuneCell(
          value: '=MAXA(-1, 9, 9.2, 4, "foo", TRUE)',
          formula: '=MAXA(-1, 9, 9.2, 4, "foo", TRUE)',
        ),
        const FortuneCellCoord(24, 2): const FortuneCell(
          value: '=MEDIAN(1, 9, 9.2, 4)',
          formula: '=MEDIAN(1, 9, 9.2, 4)',
        ),
        const FortuneCellCoord(24, 3): const FortuneCell(
          value: '=MIN(-1.1, 9, 9.2, 4, "foo", TRUE)',
          formula: '=MIN(-1.1, 9, 9.2, 4, "foo", TRUE)',
        ),
        const FortuneCellCoord(24, 4): const FortuneCell(
          value: '=MINA(-1.1, 9, 9.2, 4, "foo", TRUE)',
          formula: '=MINA(-1.1, 9, 9.2, 4, "foo", TRUE)',
        ),
        const FortuneCellCoord(25, 0): const FortuneCell(
          value: '=INDEX(MODEMULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 1)',
          formula: '=INDEX(MODEMULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 1)',
        ),
        const FortuneCellCoord(25, 1): const FortuneCell(
          value: '=INDEX(MODE.MULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 2)',
          formula: '=INDEX(MODE.MULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 2)',
        ),
        const FortuneCellCoord(25, 2): const FortuneCell(
          value: '=INDEX(MODEMULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 3)',
          formula: '=INDEX(MODEMULT({1,2,3,4,3,2,1,2,3,5,6,1}), 1, 3)',
        ),
        const FortuneCellCoord(25, 3): const FortuneCell(
          value: '=MODEMULT({1,2,"dewdew",4,3,2,1,2,3,5,6,1})',
          formula: '=MODEMULT({1,2,"dewdew",4,3,2,1,2,3,5,6,1})',
        ),
        const FortuneCellCoord(25, 4): const FortuneCell(
          value: '=MODESNGL({5.6,4,4,3,2,4})',
          formula: '=MODESNGL({5.6,4,4,3,2,4})',
        ),
        const FortuneCellCoord(25, 5): const FortuneCell(
          value: '=MODE.SNGL({5.6,4,4,3,2,4})',
          formula: '=MODE.SNGL({5.6,4,4,3,2,4})',
        ),
        const FortuneCellCoord(25, 6): const FortuneCell(
          value: '=MODESNGL({5.6,"dewdew",4,3,2,4})',
          formula: '=MODESNGL({5.6,"dewdew",4,3,2,4})',
        ),
        const FortuneCellCoord(26, 0): const FortuneCell(
          value: '=NEGBINOMDIST()',
          formula: '=NEGBINOMDIST()',
        ),
        const FortuneCellCoord(26, 1): const FortuneCell(
          value: '=NEGBINOMDIST(10)',
          formula: '=NEGBINOMDIST(10)',
        ),
        const FortuneCellCoord(26, 2): const FortuneCell(
          value: '=NEGBINOMDIST(10, 5)',
          formula: '=NEGBINOMDIST(10, 5)',
        ),
        const FortuneCellCoord(26, 3): const FortuneCell(
          value: '=NEGBINOMDIST(10, 5, 0.25)',
          formula: '=NEGBINOMDIST(10, 5, 0.25)',
        ),
        const FortuneCellCoord(26, 4): const FortuneCell(
          value: '=NEGBINOMDIST(10, 5, 0.25, TRUE)',
          formula: '=NEGBINOMDIST(10, 5, 0.25, TRUE)',
        ),
        const FortuneCellCoord(26, 5): const FortuneCell(
          value: '=NEGBINOM.DIST(10, 5, 0.25, TRUE)',
          formula: '=NEGBINOM.DIST(10, 5, 0.25, TRUE)',
        ),
        const FortuneCellCoord(27, 0): const FortuneCell(
          value: '=NORMDIST()',
          formula: '=NORMDIST()',
        ),
        const FortuneCellCoord(27, 1): const FortuneCell(
          value: '=NORMDIST(1)',
          formula: '=NORMDIST(1)',
        ),
        const FortuneCellCoord(27, 2): const FortuneCell(
          value: '=NORMDIST(1, 0)',
          formula: '=NORMDIST(1, 0)',
        ),
        const FortuneCellCoord(27, 3): const FortuneCell(
          value: '=NORMDIST(1, 0, 1)',
          formula: '=NORMDIST(1, 0, 1)',
        ),
        const FortuneCellCoord(27, 4): const FortuneCell(
          value: '=NORMDIST(1, 0, 1, TRUE)',
          formula: '=NORMDIST(1, 0, 1, TRUE)',
        ),
        const FortuneCellCoord(27, 5): const FortuneCell(
          value: '=NORM.DIST(1, 0, 1, TRUE)',
          formula: '=NORM.DIST(1, 0, 1, TRUE)',
        ),
        const FortuneCellCoord(28, 0): const FortuneCell(
          value: '=NORMINV()',
          formula: '=NORMINV()',
        ),
        const FortuneCellCoord(28, 1): const FortuneCell(
          value: '=NORMINV(1)',
          formula: '=NORMINV(1)',
        ),
        const FortuneCellCoord(28, 2): const FortuneCell(
          value: '=NORMINV(1, 0)',
          formula: '=NORMINV(1, 0)',
        ),
        const FortuneCellCoord(28, 3): const FortuneCell(
          value: '=NORMINV(1, 0, 1)',
          formula: '=NORMINV(1, 0, 1)',
        ),
        const FortuneCellCoord(28, 4): const FortuneCell(
          value: '=NORM.INV(1, 0, 1)',
          formula: '=NORM.INV(1, 0, 1)',
        ),
        const FortuneCellCoord(29, 0): const FortuneCell(
          value: '=NORMSDIST()',
          formula: '=NORMSDIST()',
        ),
        const FortuneCellCoord(29, 1): const FortuneCell(
          value: '=NORMSDIST(1)',
          formula: '=NORMSDIST(1)',
        ),
        const FortuneCellCoord(29, 2): const FortuneCell(
          value: '=NORMSDIST(1, TRUE)',
          formula: '=NORMSDIST(1, TRUE)',
        ),
        const FortuneCellCoord(29, 3): const FortuneCell(
          value: '=NORM.S.DIST(1, TRUE)',
          formula: '=NORM.S.DIST(1, TRUE)',
        ),
        const FortuneCellCoord(29, 4): const FortuneCell(
          value: '=NORMSINV()',
          formula: '=NORMSINV()',
        ),
        const FortuneCellCoord(29, 5): const FortuneCell(
          value: '=NORMSINV(1)',
          formula: '=NORMSINV(1)',
        ),
        const FortuneCellCoord(29, 6): const FortuneCell(
          value: '=NORM.S.INV(1)',
          formula: '=NORM.S.INV(1)',
        ),
        const FortuneCellCoord(30, 0): const FortuneCell(
          value: '=PEARSON({9,7,5,3,1}, {10,6,1,5,3})',
          formula: '=PEARSON({9,7,5,3,1}, {10,6,1,5,3})',
        ),
        const FortuneCellCoord(30, 1): const FortuneCell(
          value: '=PEARSON({9,7,5,3,1}, {10,"dewdewd",1,5,3})',
          formula: '=PEARSON({9,7,5,3,1}, {10,"dewdewd",1,5,3})',
        ),
        const FortuneCellCoord(31, 0): const FortuneCell(
          value: '=PERCENTILEEXC({1,2,3,4}, 0)',
          formula: '=PERCENTILEEXC({1,2,3,4}, 0)',
        ),
        const FortuneCellCoord(31, 1): const FortuneCell(
          value: '=PERCENTILEEXC({1,2,3,4}, 0.5)',
          formula: '=PERCENTILEEXC({1,2,3,4}, 0.5)',
        ),
        const FortuneCellCoord(31, 2): const FortuneCell(
          value: '=PERCENTILEEXC({1,"dewdew",3,4}, 0.5)',
          formula: '=PERCENTILEEXC({1,"dewdew",3,4}, 0.5)',
        ),
        const FortuneCellCoord(31, 3): const FortuneCell(
          value: '=PERCENTILEINC({1,2,3,4}, 0)',
          formula: '=PERCENTILEINC({1,2,3,4}, 0)',
        ),
        const FortuneCellCoord(31, 4): const FortuneCell(
          value: '=PERCENTILEINC({1,2,3,4}, 0.5)',
          formula: '=PERCENTILEINC({1,2,3,4}, 0.5)',
        ),
        const FortuneCellCoord(31, 5): const FortuneCell(
          value: '=PERCENTILEINC({1,"dewdew",3,4}, 0.5)',
          formula: '=PERCENTILEINC({1,"dewdew",3,4}, 0.5)',
        ),
        const FortuneCellCoord(32, 0): const FortuneCell(
          value: '=PERCENTRANKEXC({1,2,3,4}, 1)',
          formula: '=PERCENTRANKEXC({1,2,3,4}, 1)',
        ),
        const FortuneCellCoord(32, 1): const FortuneCell(
          value: '=PERCENTRANKEXC({1,2,3,4}, 4)',
          formula: '=PERCENTRANKEXC({1,2,3,4}, 4)',
        ),
        const FortuneCellCoord(32, 2): const FortuneCell(
          value: '=PERCENTRANKEXC({1,"dewdew",3,4}, 4)',
          formula: '=PERCENTRANKEXC({1,"dewdew",3,4}, 4)',
        ),
        const FortuneCellCoord(32, 3): const FortuneCell(
          value: '=PERCENTRANKINC({1,2,3,4}, 1)',
          formula: '=PERCENTRANKINC({1,2,3,4}, 1)',
        ),
        const FortuneCellCoord(32, 4): const FortuneCell(
          value: '=PERCENTRANKINC({1,2,3,4}, 4)',
          formula: '=PERCENTRANKINC({1,2,3,4}, 4)',
        ),
        const FortuneCellCoord(32, 5): const FortuneCell(
          value: '=PERCENTRANKINC({1,"dewdew",3,4}, 4)',
          formula: '=PERCENTRANKINC({1,"dewdew",3,4}, 4)',
        ),
        const FortuneCellCoord(33, 0): const FortuneCell(
          value: '=PERMUT()',
          formula: '=PERMUT()',
        ),
        const FortuneCellCoord(33, 1): const FortuneCell(
          value: '=PERMUT(10)',
          formula: '=PERMUT(10)',
        ),
        const FortuneCellCoord(33, 2): const FortuneCell(
          value: '=PERMUT(10, 3)',
          formula: '=PERMUT(10, 3)',
        ),
        const FortuneCellCoord(33, 3): const FortuneCell(
          value: '=PERMUTATIONA()',
          formula: '=PERMUTATIONA()',
        ),
        const FortuneCellCoord(33, 4): const FortuneCell(
          value: '=PERMUTATIONA(10)',
          formula: '=PERMUTATIONA(10)',
        ),
        const FortuneCellCoord(33, 5): const FortuneCell(
          value: '=PERMUTATIONA(10, 3)',
          formula: '=PERMUTATIONA(10, 3)',
        ),
        const FortuneCellCoord(34, 0): const FortuneCell(
          value: '=PHI()',
          formula: '=PHI()',
        ),
        const FortuneCellCoord(34, 1): const FortuneCell(
          value: '=PHI(1)',
          formula: '=PHI(1)',
        ),
        const FortuneCellCoord(35, 0): const FortuneCell(
          value: '=POISSONDIST()',
          formula: '=POISSONDIST()',
        ),
        const FortuneCellCoord(35, 1): const FortuneCell(
          value: '=POISSONDIST(1)',
          formula: '=POISSONDIST(1)',
        ),
        const FortuneCellCoord(35, 2): const FortuneCell(
          value: '=POISSONDIST(1, 3)',
          formula: '=POISSONDIST(1, 3)',
        ),
        const FortuneCellCoord(35, 3): const FortuneCell(
          value: '=POISSONDIST(1, 3, TRUE)',
          formula: '=POISSONDIST(1, 3, TRUE)',
        ),
        const FortuneCellCoord(35, 4): const FortuneCell(
          value: '=POISSON.DIST(1, 3, TRUE)',
          formula: '=POISSON.DIST(1, 3, TRUE)',
        ),
        const FortuneCellCoord(36, 0): const FortuneCell(
          value: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4}, 2)',
          formula: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4}, 2)',
        ),
        const FortuneCellCoord(36, 1): const FortuneCell(
          value: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4}, 1, 3)',
          formula: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4}, 1, 3)',
        ),
        const FortuneCellCoord(36, 2): const FortuneCell(
          value: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4})',
          formula: '=PROB({0,1,2,3}, {0.2,0.3,0.1,0.4})',
        ),
        const FortuneCellCoord(36, 3): const FortuneCell(
          value: '=PROB({0,"dewd",2,3}, {0.2,0.3,0.1,0.4}, 1, 3)',
          formula: '=PROB({0,"dewd",2,3}, {0.2,0.3,0.1,0.4}, 1, 3)',
        ),
        const FortuneCellCoord(36, 4): const FortuneCell(
          value: '=PROB({10,20}, {0.3,0.5}, 15)',
          formula: '=PROB({10,20}, {0.3,0.5}, 15)',
        ),
        const FortuneCellCoord(36, 5): const FortuneCell(
          value: '=PROB({10,20,30}, {0.4,0.4,0.3}, 20)',
          formula: '=PROB({10,20,30}, {0.4,0.4,0.3}, 20)',
        ),
        const FortuneCellCoord(37, 0): const FortuneCell(
          value: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 1)',
          formula: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 1)',
        ),
        const FortuneCellCoord(37, 1): const FortuneCell(
          value: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 2)',
          formula: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 2)',
        ),
        const FortuneCellCoord(37, 2): const FortuneCell(
          value: '=QUARTILE.EXC({6,7,15,36,39,40,41,42,43,47,49}, 2)',
          formula: '=QUARTILE.EXC({6,7,15,36,39,40,41,42,43,47,49}, 2)',
        ),
        const FortuneCellCoord(37, 3): const FortuneCell(
          value: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 4)',
          formula: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, 4)',
        ),
        const FortuneCellCoord(37, 4): const FortuneCell(
          value: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, "dwe")',
          formula: '=QUARTILEEXC({6,7,15,36,39,40,41,42,43,47,49}, "dwe")',
        ),
        const FortuneCellCoord(38, 0): const FortuneCell(
          value: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 1)',
          formula: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 1)',
        ),
        const FortuneCellCoord(38, 1): const FortuneCell(
          value: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 2)',
          formula: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 2)',
        ),
        const FortuneCellCoord(38, 2): const FortuneCell(
          value: '=QUARTILE.INC({1,2,4,7,8,9,10,12}, 2)',
          formula: '=QUARTILE.INC({1,2,4,7,8,9,10,12}, 2)',
        ),
        const FortuneCellCoord(38, 3): const FortuneCell(
          value: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 4)',
          formula: '=QUARTILEINC({1,2,4,7,8,9,10,12}, 4)',
        ),
        const FortuneCellCoord(38, 4): const FortuneCell(
          value: '=QUARTILEINC({1,2,4,7,8,9,10,12}, "dwe")',
          formula: '=QUARTILEINC({1,2,4,7,8,9,10,12}, "dwe")',
        ),
        const FortuneCellCoord(39, 0): const FortuneCell(
          value: '=RANKAVG(94, {89,88,92,101,94,97,95})',
          formula: '=RANKAVG(94, {89,88,92,101,94,97,95})',
        ),
        const FortuneCellCoord(39, 1): const FortuneCell(
          value: '=RANKAVG(88, {89,88,92,101,94,97,95}, 1)',
          formula: '=RANKAVG(88, {89,88,92,101,94,97,95}, 1)',
        ),
        const FortuneCellCoord(39, 2): const FortuneCell(
          value: '=RANK.AVG(88, {89,88,92,101,94,97,95}, 1)',
          formula: '=RANK.AVG(88, {89,88,92,101,94,97,95}, 1)',
        ),
        const FortuneCellCoord(39, 3): const FortuneCell(
          value: '=RANKAVG("dwe", {89,88,92,101,94,97,95}, 1)',
          formula: '=RANKAVG("dwe", {89,88,92,101,94,97,95}, 1)',
        ),
        const FortuneCellCoord(40, 0): const FortuneCell(
          value: '=RANKEQ(7, {7,3.5,3.5,1,2}, 1)',
          formula: '=RANKEQ(7, {7,3.5,3.5,1,2}, 1)',
        ),
        const FortuneCellCoord(40, 1): const FortuneCell(
          value: '=RANKEQ(2, {7,3.5,3.5,1,2})',
          formula: '=RANKEQ(2, {7,3.5,3.5,1,2})',
        ),
        const FortuneCellCoord(40, 2): const FortuneCell(
          value: '=RANK.EQ(2, {7,3.5,3.5,1,2})',
          formula: '=RANK.EQ(2, {7,3.5,3.5,1,2})',
        ),
        const FortuneCellCoord(40, 3): const FortuneCell(
          value: '=RANKEQ("dwe", {7,3.5,3.5,1,2}, TRUE)',
          formula: '=RANKEQ("dwe", {7,3.5,3.5,1,2}, TRUE)',
        ),
        const FortuneCellCoord(41, 0): const FortuneCell(
          value: '=RSQ({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
          formula: '=RSQ({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(41, 1): const FortuneCell(
          value: '=RSQ({6,"dwe",11,7,5,4,4}, {6,5,11,7,5,4,4})',
          formula: '=RSQ({6,"dwe",11,7,5,4,4}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(42, 0): const FortuneCell(
          value: '=SKEW({3,4,5,2,3,4,5,6,4,7})',
          formula: '=SKEW({3,4,5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(42, 1): const FortuneCell(
          value: '=SKEW({3,"dwe",5,2,3,4,5,6,4,7})',
          formula: '=SKEW({3,"dwe",5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(42, 2): const FortuneCell(
          value: '=SKEWP({3,4,5,2,3,4,5,6,4,7})',
          formula: '=SKEWP({3,4,5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(42, 3): const FortuneCell(
          value: '=SKEW.P({3,4,5,2,3,4,5,6,4,7})',
          formula: '=SKEW.P({3,4,5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(42, 4): const FortuneCell(
          value: '=SKEWP({3,"dwe",5,2,3,4,5,6,4,7})',
          formula: '=SKEWP({3,"dwe",5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(42, 5): const FortuneCell(
          value: '=SKEW.P({3,"dwe",5,2,3,4,5,6,4,7})',
          formula: '=SKEW.P({3,"dwe",5,2,3,4,5,6,4,7})',
        ),
        const FortuneCellCoord(43, 0): const FortuneCell(
          value: '=SLOPE({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
          formula: '=SLOPE({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(43, 1): const FortuneCell(
          value: '=SLOPE({6,"dwe",11,7,5,4,4}, {6,5,11,7,5,4,4})',
          formula: '=SLOPE({6,"dwe",11,7,5,4,4}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(43, 2): const FortuneCell(
          value: '=SMALL({3,4,5,2,3,4,6,4,7}, 4)',
          formula: '=SMALL({3,4,5,2,3,4,6,4,7}, 4)',
        ),
        const FortuneCellCoord(43, 3): const FortuneCell(
          value: '=SMALL({3,4,"dwe",2,3,4,6,4,7}, 4)',
          formula: '=SMALL({3,4,"dwe",2,3,4,6,4,7}, 4)',
        ),
        const FortuneCellCoord(44, 0): const FortuneCell(
          value: '=STANDARDIZE()',
          formula: '=STANDARDIZE()',
        ),
        const FortuneCellCoord(44, 1): const FortuneCell(
          value: '=STANDARDIZE(1)',
          formula: '=STANDARDIZE(1)',
        ),
        const FortuneCellCoord(44, 2): const FortuneCell(
          value: '=STANDARDIZE(1, 3)',
          formula: '=STANDARDIZE(1, 3)',
        ),
        const FortuneCellCoord(44, 3): const FortuneCell(
          value: '=STANDARDIZE(1, 3, 5)',
          formula: '=STANDARDIZE(1, 3, 5)',
        ),
        const FortuneCellCoord(45, 0): const FortuneCell(
          value: '=STDEVP({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEVP({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(45, 1): const FortuneCell(
          value:
              '=STDEV.P({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEV.P({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(45, 2): const FortuneCell(
          value: '=STDEVS({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEVS({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(45, 3): const FortuneCell(
          value:
              '=STDEV.S({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEV.S({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(45, 4): const FortuneCell(
          value: '=STDEVA({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEVA({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(45, 5): const FortuneCell(
          value:
              '=STDEVPA({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
          formula:
              '=STDEVPA({1345,1301,1368,1322,1310,1370,1318,1350,1303,1299})',
        ),
        const FortuneCellCoord(46, 0): const FortuneCell(
          value: '=STEYX({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
          formula: '=STEYX({2,3,9,1,8,7,5}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(46, 1): const FortuneCell(
          value: '=STEYX({6,5,"dwe",7,5,4,4}, {6,5,11,7,5,4,4})',
          formula: '=STEYX({6,5,"dwe",7,5,4,4}, {6,5,11,7,5,4,4})',
        ),
        const FortuneCellCoord(47, 0): const FortuneCell(
          value: '=TDIST()',
          formula: '=TDIST()',
        ),
        const FortuneCellCoord(47, 1): const FortuneCell(
          value: '=TDIST(1)',
          formula: '=TDIST(1)',
        ),
        const FortuneCellCoord(47, 2): const FortuneCell(
          value: '=TDIST(1, 3)',
          formula: '=TDIST(1, 3)',
        ),
        const FortuneCellCoord(47, 3): const FortuneCell(
          value: '=TDIST(1, 3, TRUE)',
          formula: '=TDIST(1, 3, TRUE)',
        ),
        const FortuneCellCoord(47, 4): const FortuneCell(
          value: '=T.DIST(1, 3, TRUE)',
          formula: '=T.DIST(1, 3, TRUE)',
        ),
        const FortuneCellCoord(48, 0): const FortuneCell(
          value: '=T.DIST.2T()',
          formula: '=T.DIST.2T()',
        ),
        const FortuneCellCoord(48, 1): const FortuneCell(
          value: '=T.DIST.2T(1)',
          formula: '=T.DIST.2T(1)',
        ),
        const FortuneCellCoord(48, 2): const FortuneCell(
          value: '=T.DIST.2T(1, 6)',
          formula: '=T.DIST.2T(1, 6)',
        ),
        const FortuneCellCoord(49, 0): const FortuneCell(
          value: '=T.DIST.RT()',
          formula: '=T.DIST.RT()',
        ),
        const FortuneCellCoord(49, 1): const FortuneCell(
          value: '=T.DIST.RT(1)',
          formula: '=T.DIST.RT(1)',
        ),
        const FortuneCellCoord(49, 2): const FortuneCell(
          value: '=T.DIST.RT(1, 6)',
          formula: '=T.DIST.RT(1, 6)',
        ),
        const FortuneCellCoord(50, 0): const FortuneCell(
          value: '=TINV()',
          formula: '=TINV()',
        ),
        const FortuneCellCoord(50, 1): const FortuneCell(
          value: '=TINV(0.1)',
          formula: '=TINV(0.1)',
        ),
        const FortuneCellCoord(50, 2): const FortuneCell(
          value: '=TINV(0.1, 6)',
          formula: '=TINV(0.1, 6)',
        ),
        const FortuneCellCoord(50, 3): const FortuneCell(
          value: '=T.INV(0.1, 6)',
          formula: '=T.INV(0.1, 6)',
        ),
        const FortuneCellCoord(51, 0): const FortuneCell(
          value: '=T.INV.2T()',
          formula: '=T.INV.2T()',
        ),
        const FortuneCellCoord(51, 1): const FortuneCell(
          value: '=T.INV.2T(0.1)',
          formula: '=T.INV.2T(0.1)',
        ),
        const FortuneCellCoord(51, 2): const FortuneCell(
          value: '=T.INV.2T(0.1, 6)',
          formula: '=T.INV.2T(0.1, 6)',
        ),
        const FortuneCellCoord(52, 0): const FortuneCell(
          value: '=INDEX(TREND({1,9,5,7}, {0,4,2,3}, {5,8}), 1, 1)',
          formula: '=INDEX(TREND({1,9,5,7}, {0,4,2,3}, {5,8}), 1, 1)',
        ),
        const FortuneCellCoord(52, 1): const FortuneCell(
          value: '=INDEX(TREND({1,9,5,7}, {0,4,2,3}, {5,8}), 1, 2)',
          formula: '=INDEX(TREND({1,9,5,7}, {0,4,2,3}, {5,8}), 1, 2)',
        ),
        const FortuneCellCoord(52, 2): const FortuneCell(
          value: '=TREND({1,9,5,7}, {0,4,2,3}, "dwe")',
          formula: '=TREND({1,9,5,7}, {0,4,2,3}, "dwe")',
        ),
        const FortuneCellCoord(53, 0): const FortuneCell(
          value: '=TRIMMEAN({4,5,6,7,2,3,4,5,1,2,3}, 0.2)',
          formula: '=TRIMMEAN({4,5,6,7,2,3,4,5,1,2,3}, 0.2)',
        ),
        const FortuneCellCoord(53, 1): const FortuneCell(
          value: '=TRIMMEAN({4,5,"dwe",7,2,3,4,5,1,2,3}, 0.2)',
          formula: '=TRIMMEAN({4,5,"dwe",7,2,3,4,5,1,2,3}, 0.2)',
        ),
        const FortuneCellCoord(54, 0): const FortuneCell(
          value: '=VARP()',
          formula: '=VARP()',
        ),
        const FortuneCellCoord(54, 1): const FortuneCell(
          value: '=VARP(1)',
          formula: '=VARP(1)',
        ),
        const FortuneCellCoord(54, 2): const FortuneCell(
          value: '=VARP(1, 2)',
          formula: '=VARP(1, 2)',
        ),
        const FortuneCellCoord(54, 3): const FortuneCell(
          value: '=VARP(1, 2, 3)',
          formula: '=VARP(1, 2, 3)',
        ),
        const FortuneCellCoord(54, 4): const FortuneCell(
          value: '=VARP(1, 2, 3, 4)',
          formula: '=VARP(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(54, 5): const FortuneCell(
          value: '=VAR.P(1, 2, 3, 4)',
          formula: '=VAR.P(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(55, 0): const FortuneCell(
          value: '=VARS()',
          formula: '=VARS()',
        ),
        const FortuneCellCoord(55, 1): const FortuneCell(
          value: '=VARS(1)',
          formula: '=VARS(1)',
        ),
        const FortuneCellCoord(55, 2): const FortuneCell(
          value: '=VARS(1, 2)',
          formula: '=VARS(1, 2)',
        ),
        const FortuneCellCoord(55, 3): const FortuneCell(
          value: '=VARS(1, 2, 3)',
          formula: '=VARS(1, 2, 3)',
        ),
        const FortuneCellCoord(55, 4): const FortuneCell(
          value: '=VARS(1, 2, 3, 4)',
          formula: '=VARS(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(55, 5): const FortuneCell(
          value: '=VAR.S(1, 2, 3, 4)',
          formula: '=VAR.S(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(55, 6): const FortuneCell(
          value: '=VAR.S(1, 2, 3, 4, TRUE, "foo")',
          formula: '=VAR.S(1, 2, 3, 4, TRUE, "foo")',
        ),
        const FortuneCellCoord(56, 0): const FortuneCell(
          value: '=VARA()',
          formula: '=VARA()',
        ),
        const FortuneCellCoord(56, 1): const FortuneCell(
          value: '=VARA(1)',
          formula: '=VARA(1)',
        ),
        const FortuneCellCoord(56, 2): const FortuneCell(
          value: '=VARA(1, 2)',
          formula: '=VARA(1, 2)',
        ),
        const FortuneCellCoord(56, 3): const FortuneCell(
          value: '=VARA(1, 2, 3)',
          formula: '=VARA(1, 2, 3)',
        ),
        const FortuneCellCoord(56, 4): const FortuneCell(
          value: '=VARA(1, 2, 3, 4)',
          formula: '=VARA(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(56, 5): const FortuneCell(
          value: '=VARA(1, 2, 3, 4, TRUE, "foo")',
          formula: '=VARA(1, 2, 3, 4, TRUE, "foo")',
        ),
        const FortuneCellCoord(57, 0): const FortuneCell(
          value: '=VARPA()',
          formula: '=VARPA()',
        ),
        const FortuneCellCoord(57, 1): const FortuneCell(
          value: '=VARPA(1)',
          formula: '=VARPA(1)',
        ),
        const FortuneCellCoord(57, 2): const FortuneCell(
          value: '=VARPA(1, 2)',
          formula: '=VARPA(1, 2)',
        ),
        const FortuneCellCoord(57, 3): const FortuneCell(
          value: '=VARPA(1, 2, 3)',
          formula: '=VARPA(1, 2, 3)',
        ),
        const FortuneCellCoord(57, 4): const FortuneCell(
          value: '=VARPA(1, 2, 3, 4)',
          formula: '=VARPA(1, 2, 3, 4)',
        ),
        const FortuneCellCoord(57, 5): const FortuneCell(
          value: '=VARPA(1, 2, 3, 4, TRUE, "foo")',
          formula: '=VARPA(1, 2, 3, 4, TRUE, "foo")',
        ),
        const FortuneCellCoord(58, 0): const FortuneCell(
          value: '=WEIBULLDIST()',
          formula: '=WEIBULLDIST()',
        ),
        const FortuneCellCoord(58, 1): const FortuneCell(
          value: '=WEIBULLDIST(1)',
          formula: '=WEIBULLDIST(1)',
        ),
        const FortuneCellCoord(58, 2): const FortuneCell(
          value: '=WEIBULLDIST(1, 2)',
          formula: '=WEIBULLDIST(1, 2)',
        ),
        const FortuneCellCoord(58, 3): const FortuneCell(
          value: '=WEIBULLDIST(1, 2, 3)',
          formula: '=WEIBULLDIST(1, 2, 3)',
        ),
        const FortuneCellCoord(58, 4): const FortuneCell(
          value: '=WEIBULLDIST(1, 2, 3, TRUE)',
          formula: '=WEIBULLDIST(1, 2, 3, TRUE)',
        ),
        const FortuneCellCoord(58, 5): const FortuneCell(
          value: '=WEIBULL.DIST(1, 2, 3, TRUE)',
          formula: '=WEIBULL.DIST(1, 2, 3, TRUE)',
        ),
        const FortuneCellCoord(58, 6): const FortuneCell(
          value: '=WEIBULL(1, 2, 3, TRUE)',
          formula: '=WEIBULL(1, 2, 3, TRUE)',
        ),
        const FortuneCellCoord(58, 7): const FortuneCell(
          value: '=ROUND(CHIDIST(3, 4), 6)',
          formula: '=ROUND(CHIDIST(3, 4), 6)',
        ),
        const FortuneCellCoord(58, 8): const FortuneCell(
          value: '=ROUND(CHIINV(0.5578254, 4), 6)',
          formula: '=ROUND(CHIINV(0.5578254, 4), 6)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(59, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(59, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 8)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 9)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 10)]?.renderedText, '4.525');
    expect(sheet.cells[const FortuneCellCoord(1, 11)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 12)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 13)]?.renderedText, '0.45');
    expect(sheet.cells[const FortuneCellCoord(1, 14)]?.renderedText, '2.975');
    expect(sheet.cells[const FortuneCellCoord(1, 15)]?.renderedText, '3.82');
    expect(
      sheet.cells[const FortuneCellCoord(1, 16)]?.renderedText,
      '1.533333333333',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 17)]?.renderedText, '1.1');
    expect(sheet.cells[const FortuneCellCoord(1, 18)]?.renderedText, '4.525');
    expect(sheet.cells[const FortuneCellCoord(1, 19)]?.renderedText, '1.1');
    expect(sheet.cells[const FortuneCellCoord(1, 20)]?.renderedText, '4.525');
    expect(sheet.cells[const FortuneCellCoord(1, 21)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 22)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 23)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 24)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 25)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 26)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 27)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 28)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 29)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 30)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '1.75');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '1.75');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 10)]?.renderedText, '0.2');
    expect(sheet.cells[const FortuneCellCoord(2, 11)]?.renderedText, '0.8');
    expect(
      sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText,
      '1.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText,
      '0.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText,
      '0.816496580928',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText,
      '0.707106781187',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 8)]?.renderedText,
      '1.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText,
      '0.864664716763',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText,
      '0.084224337489',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText,
      '0.06061658684',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText,
      '4.009749312674',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText,
      '0.439391289468',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText,
      '4.000025209777',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText,
      '0.929581390069',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '2');
    expect(
      sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText,
      '0.303193339354',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 6)]?.renderedText, '4');
    expect(
      sheet.cells[const FortuneCellCoord(5, 7)]?.renderedText,
      '0.158655253931',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 8)]?.renderedText,
      '0.241970724519',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 9)]?.renderedText,
      '0.841344746069',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 11)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 12)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(5, 13)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(5, 14)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(5, 15)]?.renderedText,
      '141.42135623731',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 16)]?.renderedText,
      '141.42135623731',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(6, 7)]?.renderedText,
      '0.001271446908',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 8)]?.renderedText,
      '0.989741952394',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 9)]?.renderedText,
      '0.314389988322',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 10)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(6, 11)]?.renderedText,
      '4.009749312674',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText,
      '1.353352832366',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText,
      '0.241970724519',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText,
      '0.017617596682',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText,
      '0.149361205104',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText,
      '0.055048660375',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText,
      '0.313514058478',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 6)]?.renderedText,
      '0.465428276574',
    );
    expect(
      sheet.cells[const FortuneCellCoord(7, 7)]?.renderedText,
      '0.198853181514',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(8, 8)]?.renderedText,
      '1.791759469228',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 9)]?.renderedText,
      '1233.435565298214',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText,
      '1.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '1.25');
    expect(
      sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText,
      '0.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText,
      '0.084224337489',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText,
      '0.841344746069',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '0.3125');
    expect(sheet.cells[const FortuneCellCoord(9, 8)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(9, 9)]?.renderedText, '3');
    expect(
      sheet.cells[const FortuneCellCoord(9, 10)]?.renderedText,
      '0.057191',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 11)]?.renderedText,
      '0.028595',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 12)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(9, 13)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 8)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 9)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 10)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText,
      '1.999999999971',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText,
      '1.999999999971',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(12, 6)]?.renderedText,
      '0.205078125',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 7)]?.renderedText,
      '0.205078125',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 10)]?.renderedText, '4');
    expect(
      sheet.cells[const FortuneCellCoord(12, 11)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 12)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 13)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 14)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 15)]?.renderedText,
      '#VALUE!',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText,
      '0.301640986325',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText,
      '0.301640986325',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 7)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 8)]?.renderedText,
      '0.331249806162',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '#ERROR!');
    expect(
      sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText,
      '0.997054485502',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '5.2');
    expect(
      sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText,
      '9.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '48');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText,
      '0.864664716763',
    );
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(15, 6)]?.renderedText,
      '0.989741952394',
    );
    expect(sheet.cells[const FortuneCellCoord(15, 7)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(15, 8)]?.renderedText,
      '0.010258047606',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 9)]?.renderedText,
      '0.010258047606',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 10)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 11)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 12)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 13)]?.renderedText,
      '0.314389988322',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText,
      '0.100335347731',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText,
      'Infinity',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText,
      '0.099667994625',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText,
      '0.761594155956',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 6)]?.renderedText,
      '10.60725308642',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(16, 8)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(16, 9)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(16, 10)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText,
      '9.513507698669',
    );
    expect(
      sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText,
      '0.000436707431',
    );
    expect(
      sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText,
      '0.000436707431',
    );
    expect(
      sheet.cells[const FortuneCellCoord(17, 4)]?.renderedText,
      '1233.435565298214',
    );
    expect(sheet.cells[const FortuneCellCoord(17, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(17, 6)]?.renderedText,
      '1.791759469228',
    );
    expect(sheet.cells[const FortuneCellCoord(18, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText,
      '0.499968328758',
    );
    expect(
      sheet.cells[const FortuneCellCoord(18, 2)]?.renderedText,
      '5.476986969657',
    );
    expect(
      sheet.cells[const FortuneCellCoord(18, 3)]?.renderedText,
      '5.028375962062',
    );
    expect(sheet.cells[const FortuneCellCoord(18, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 7)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(18, 8)]?.renderedText,
      '0.363261093911',
    );
    expect(
      sheet.cells[const FortuneCellCoord(18, 9)]?.renderedText,
      '0.465428276574',
    );
    expect(
      sheet.cells[const FortuneCellCoord(19, 0)]?.renderedText,
      '0.048387096774',
    );
    expect(
      sheet.cells[const FortuneCellCoord(19, 1)]?.renderedText,
      '-0.151799637208',
    );
    expect(sheet.cells[const FortuneCellCoord(19, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(19, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(19, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(20, 0)]?.renderedText,
      '32618.203773539713',
    );
    expect(
      sheet.cells[const FortuneCellCoord(20, 1)]?.renderedText,
      '149542.486740045948',
    );
    expect(
      sheet.cells[const FortuneCellCoord(20, 2)]?.renderedText,
      '685597.388981237542',
    );
    expect(sheet.cells[const FortuneCellCoord(21, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(21, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(21, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(21, 3)]?.renderedText,
      '1.751115955582',
    );
    expect(
      sheet.cells[const FortuneCellCoord(21, 4)]?.renderedText,
      '1.194315590982',
    );
    expect(sheet.cells[const FortuneCellCoord(21, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(22, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(22, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(22, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(22, 3)]?.renderedText,
      '0.017617596682',
    );
    expect(
      sheet.cells[const FortuneCellCoord(22, 4)]?.renderedText,
      '0.039083555707',
    );
    expect(
      sheet.cells[const FortuneCellCoord(22, 5)]?.renderedText,
      '0.039083555707',
    );
    expect(sheet.cells[const FortuneCellCoord(23, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(23, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(23, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(23, 3)]?.renderedText,
      '3.999999991096',
    );
    expect(
      sheet.cells[const FortuneCellCoord(23, 4)]?.renderedText,
      '3.999999991096',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 0)]?.renderedText, '9.2');
    expect(sheet.cells[const FortuneCellCoord(24, 1)]?.renderedText, '9.2');
    expect(sheet.cells[const FortuneCellCoord(24, 2)]?.renderedText, '6.5');
    expect(sheet.cells[const FortuneCellCoord(24, 3)]?.renderedText, '-1.1');
    expect(sheet.cells[const FortuneCellCoord(24, 4)]?.renderedText, '-1.1');
    expect(sheet.cells[const FortuneCellCoord(25, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(25, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(25, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(25, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(25, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(25, 5)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(25, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(26, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(26, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(26, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(26, 3)]?.renderedText,
      '0.055048660375',
    );
    expect(
      sheet.cells[const FortuneCellCoord(26, 4)]?.renderedText,
      '0.313514058478',
    );
    expect(
      sheet.cells[const FortuneCellCoord(26, 5)]?.renderedText,
      '0.313514058478',
    );
    expect(sheet.cells[const FortuneCellCoord(27, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(27, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(27, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(27, 3)]?.renderedText,
      '0.241970724519',
    );
    expect(
      sheet.cells[const FortuneCellCoord(27, 4)]?.renderedText,
      '0.841344746069',
    );
    expect(
      sheet.cells[const FortuneCellCoord(27, 5)]?.renderedText,
      '0.841344746069',
    );
    expect(sheet.cells[const FortuneCellCoord(28, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(28, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(28, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(28, 3)]?.renderedText,
      '141.42135623731',
    );
    expect(
      sheet.cells[const FortuneCellCoord(28, 4)]?.renderedText,
      '141.42135623731',
    );
    expect(sheet.cells[const FortuneCellCoord(29, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(29, 1)]?.renderedText,
      '0.241970724519',
    );
    expect(
      sheet.cells[const FortuneCellCoord(29, 2)]?.renderedText,
      '0.841344746069',
    );
    expect(
      sheet.cells[const FortuneCellCoord(29, 3)]?.renderedText,
      '0.841344746069',
    );
    expect(sheet.cells[const FortuneCellCoord(29, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(29, 5)]?.renderedText,
      '141.42135623731',
    );
    expect(
      sheet.cells[const FortuneCellCoord(29, 6)]?.renderedText,
      '141.42135623731',
    );
    expect(
      sheet.cells[const FortuneCellCoord(30, 0)]?.renderedText,
      '0.69937860618',
    );
    expect(sheet.cells[const FortuneCellCoord(30, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(31, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(31, 1)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(31, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(31, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(31, 4)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(31, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(32, 0)]?.renderedText, '0.2');
    expect(sheet.cells[const FortuneCellCoord(32, 1)]?.renderedText, '0.8');
    expect(sheet.cells[const FortuneCellCoord(32, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(32, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(32, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(32, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(33, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(33, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(33, 2)]?.renderedText, '720');
    expect(sheet.cells[const FortuneCellCoord(33, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(33, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(33, 5)]?.renderedText, '1000');
    expect(sheet.cells[const FortuneCellCoord(34, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(36, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(36, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(34, 1)]?.renderedText,
      '0.241970724519',
    );
    expect(sheet.cells[const FortuneCellCoord(35, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(35, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(35, 2)]?.renderedText,
      '0.149361205104',
    );
    expect(
      sheet.cells[const FortuneCellCoord(35, 3)]?.renderedText,
      '0.199148273471',
    );
    expect(
      sheet.cells[const FortuneCellCoord(35, 4)]?.renderedText,
      '0.199148273471',
    );
    expect(sheet.cells[const FortuneCellCoord(36, 0)]?.renderedText, '0.1');
    expect(sheet.cells[const FortuneCellCoord(36, 1)]?.renderedText, '0.8');
    expect(sheet.cells[const FortuneCellCoord(36, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(36, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(37, 0)]?.renderedText, '15');
    expect(sheet.cells[const FortuneCellCoord(37, 1)]?.renderedText, '40');
    expect(sheet.cells[const FortuneCellCoord(37, 2)]?.renderedText, '40');
    expect(sheet.cells[const FortuneCellCoord(37, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(37, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(38, 0)]?.renderedText, '3.5');
    expect(sheet.cells[const FortuneCellCoord(38, 1)]?.renderedText, '7.5');
    expect(sheet.cells[const FortuneCellCoord(38, 2)]?.renderedText, '7.5');
    expect(sheet.cells[const FortuneCellCoord(38, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(38, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(39, 0)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(39, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(39, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(39, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(40, 0)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(40, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(40, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(40, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(41, 0)]?.renderedText,
      '0.057950191571',
    );
    expect(sheet.cells[const FortuneCellCoord(41, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(42, 0)]?.renderedText,
      '0.359543071407',
    );
    expect(sheet.cells[const FortuneCellCoord(42, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(42, 2)]?.renderedText,
      '0.303193339354',
    );
    expect(
      sheet.cells[const FortuneCellCoord(42, 3)]?.renderedText,
      '0.303193339354',
    );
    expect(sheet.cells[const FortuneCellCoord(42, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(42, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(43, 0)]?.renderedText,
      '0.305555555556',
    );
    expect(sheet.cells[const FortuneCellCoord(43, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(43, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(43, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(44, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(44, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(44, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(44, 3)]?.renderedText, '-0.4');
    expect(
      sheet.cells[const FortuneCellCoord(45, 0)]?.renderedText,
      '26.054558142482',
    );
    expect(
      sheet.cells[const FortuneCellCoord(45, 1)]?.renderedText,
      '26.054558142482',
    );
    expect(
      sheet.cells[const FortuneCellCoord(45, 2)]?.renderedText,
      '27.463915719843',
    );
    expect(
      sheet.cells[const FortuneCellCoord(45, 3)]?.renderedText,
      '27.463915719843',
    );
    expect(
      sheet.cells[const FortuneCellCoord(45, 4)]?.renderedText,
      '27.463915719843',
    );
    expect(
      sheet.cells[const FortuneCellCoord(45, 5)]?.renderedText,
      '26.054558142482',
    );
    expect(
      sheet.cells[const FortuneCellCoord(46, 0)]?.renderedText,
      '3.30571895021',
    );
    expect(sheet.cells[const FortuneCellCoord(46, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(47, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(47, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(47, 2)]?.renderedText,
      '0.206748335783',
    );
    expect(
      sheet.cells[const FortuneCellCoord(47, 3)]?.renderedText,
      '0.804498890522',
    );
    expect(
      sheet.cells[const FortuneCellCoord(47, 4)]?.renderedText,
      '0.804498890522',
    );
    expect(sheet.cells[const FortuneCellCoord(48, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(48, 1)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(48, 2)]?.renderedText,
      '0.35591768375',
    );
    expect(sheet.cells[const FortuneCellCoord(49, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(49, 1)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(49, 2)]?.renderedText,
      '0.177958841875',
    );
    expect(sheet.cells[const FortuneCellCoord(50, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(50, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(50, 2)]?.renderedText,
      '-1.439755747265',
    );
    expect(
      sheet.cells[const FortuneCellCoord(50, 3)]?.renderedText,
      '-1.439755747265',
    );
    expect(sheet.cells[const FortuneCellCoord(51, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(51, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(51, 2)]?.renderedText,
      '1.943180280515',
    );
    expect(sheet.cells[const FortuneCellCoord(52, 0)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(52, 1)]?.renderedText, '17');
    expect(sheet.cells[const FortuneCellCoord(52, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(53, 0)]?.renderedText,
      '3.777777777778',
    );
    expect(sheet.cells[const FortuneCellCoord(53, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(54, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(54, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(54, 2)]?.renderedText, '0.25');
    expect(
      sheet.cells[const FortuneCellCoord(54, 3)]?.renderedText,
      '0.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(54, 4)]?.renderedText, '1.25');
    expect(sheet.cells[const FortuneCellCoord(54, 5)]?.renderedText, '1.25');
    expect(sheet.cells[const FortuneCellCoord(55, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(55, 1)]?.renderedText, 'NaN');
    expect(sheet.cells[const FortuneCellCoord(55, 2)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(55, 3)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(55, 4)]?.renderedText,
      '1.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(55, 5)]?.renderedText,
      '1.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(55, 6)]?.renderedText,
      '1.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(56, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(56, 1)]?.renderedText, 'NaN');
    expect(sheet.cells[const FortuneCellCoord(56, 2)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(56, 3)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(56, 4)]?.renderedText,
      '1.666666666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(56, 5)]?.renderedText,
      '2.166666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(57, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(57, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(57, 2)]?.renderedText, '0.25');
    expect(
      sheet.cells[const FortuneCellCoord(57, 3)]?.renderedText,
      '0.666666666667',
    );
    expect(sheet.cells[const FortuneCellCoord(57, 4)]?.renderedText, '1.25');
    expect(
      sheet.cells[const FortuneCellCoord(57, 5)]?.renderedText,
      '1.805555555556',
    );
    expect(sheet.cells[const FortuneCellCoord(58, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(58, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(58, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(58, 3)]?.renderedText,
      '0.198853181514',
    );
    expect(
      sheet.cells[const FortuneCellCoord(58, 4)]?.renderedText,
      '0.105160683186',
    );
    expect(
      sheet.cells[const FortuneCellCoord(58, 5)]?.renderedText,
      '0.105160683186',
    );
    expect(
      sheet.cells[const FortuneCellCoord(58, 6)]?.renderedText,
      '0.105160683186',
    );
    expect(
      sheet.cells[const FortuneCellCoord(58, 7)]?.renderedText,
      '0.557825',
    );
    expect(sheet.cells[const FortuneCellCoord(58, 8)]?.renderedText, '3');
  });

  test('formula engine matches statistical parser edge cases', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '0'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '0.2'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '0.3'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(1, 3): const FortuneCell(value: '0.4'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '0'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: 'dewd'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 3): const FortuneCell(value: '3'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(3, 2): const FortuneCell(value: '4'),
        const FortuneCellCoord(3, 3): const FortuneCell(value: '7'),
        const FortuneCellCoord(3, 4): const FortuneCell(value: '8'),
        const FortuneCellCoord(3, 5): const FortuneCell(value: '9'),
        const FortuneCellCoord(3, 6): const FortuneCell(value: '10'),
        const FortuneCellCoord(3, 7): const FortuneCell(value: '12'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(4, 2): const FortuneCell(value: 'dwe'),
        const FortuneCellCoord(4, 3): const FortuneCell(value: '2'),
        const FortuneCellCoord(4, 4): const FortuneCell(value: '3'),
        const FortuneCellCoord(4, 5): const FortuneCell(value: '4'),
        const FortuneCellCoord(4, 6): const FortuneCell(value: '6'),
        const FortuneCellCoord(4, 7): const FortuneCell(value: '4'),
        const FortuneCellCoord(4, 8): const FortuneCell(value: '7'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: '6'),
        const FortuneCellCoord(5, 1): const FortuneCell(value: 'dwe'),
        const FortuneCellCoord(5, 2): const FortuneCell(value: '11'),
        const FortuneCellCoord(5, 3): const FortuneCell(value: '7'),
        const FortuneCellCoord(5, 4): const FortuneCell(value: '5'),
        const FortuneCellCoord(5, 5): const FortuneCell(value: '4'),
        const FortuneCellCoord(5, 6): const FortuneCell(value: '4'),
        const FortuneCellCoord(6, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(6, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(6, 2): const FortuneCell(value: '9'),
        const FortuneCellCoord(6, 3): const FortuneCell(value: '1'),
        const FortuneCellCoord(6, 4): const FortuneCell(value: '8'),
        const FortuneCellCoord(6, 5): const FortuneCell(value: '7'),
        const FortuneCellCoord(6, 6): const FortuneCell(value: '5'),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=PROB(A1:D1, A2:D2)',
          formula: '=PROB(A1:D1, A2:D2)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=PROB(A3:D3, A2:D2, 1, 3)',
          formula: '=PROB(A3:D3, A2:D2, 1, 3)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=QUARTILEINC(A4:H4, 4)',
          formula: '=QUARTILEINC(A4:H4, 4)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=QUARTILEEXC(A4:H4, "dwe")',
          formula: '=QUARTILEEXC(A4:H4, "dwe")',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=SKEW(A5:I5)',
          formula: '=SKEW(A5:I5)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=SKEWP(A5:I5)',
          formula: '=SKEWP(A5:I5)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=SLOPE(A6:G6, A7:G7)',
          formula: '=SLOPE(A6:G6, A7:G7)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=SMALL(A5:I5, 4)',
          formula: '=SMALL(A5:I5, 4)',
        ),
        const FortuneCellCoord(8, 8): const FortuneCell(
          value: '=KURT(A5:I5)',
          formula: '=KURT(A5:I5)',
        ),
        const FortuneCellCoord(8, 9): const FortuneCell(
          value: '=STEYX(A6:G6, A7:G7)',
          formula: '=STEYX(A6:G6, A7:G7)',
        ),
        const FortuneCellCoord(8, 10): const FortuneCell(
          value: '=TRIMMEAN(A5:I5, 0.2)',
          formula: '=TRIMMEAN(A5:I5, 0.2)',
        ),
        const FortuneCellCoord(8, 11): const FortuneCell(
          value: '=ROUND(TDIST(1, 3), 9)',
          formula: '=ROUND(TDIST(1, 3), 9)',
        ),
        const FortuneCellCoord(8, 12): const FortuneCell(
          value: '=ROUND(TDIST(1, 3, TRUE), 9)',
          formula: '=ROUND(TDIST(1, 3, TRUE), 9)',
        ),
        const FortuneCellCoord(8, 13): const FortuneCell(
          value: '=ROUND(TINV(0.1, 6), 8)',
          formula: '=ROUND(TINV(0.1, 6), 8)',
        ),
        const FortuneCellCoord(8, 14): const FortuneCell(
          value: '=VARS(1)',
          formula: '=VARS(1)',
        ),
        const FortuneCellCoord(8, 15): const FortuneCell(
          value: '=VARA(1)',
          formula: '=VARA(1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 10)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(8, 11)]?.renderedText,
      '0.206748336',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 12)]?.renderedText,
      '0.804498891',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 13)]?.renderedText,
      '-1.43975575',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 14)]?.renderedText, 'NaN');
    expect(sheet.cells[const FortuneCellCoord(8, 15)]?.renderedText, 'NaN');
  });

  test('formula engine evaluates statistical named variable fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [3, 2, 4, 5, 6],
          'bar': [9, 7, 12, 15, 17],
          'shortFoo': [2, 4, 8],
          'shortBar': [5, 11, 12],
          'devsqFoo': [4, 5, 8, 7, 11, 4, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=CORREL(foo, bar)',
          formula: '=CORREL(foo, bar)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=COVARIANCE.P(foo, bar)',
          formula: '=COVARIANCE.P(foo, bar)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=COVARIANCE.S(shortFoo, shortBar)',
          formula: '=COVARIANCE.S(shortFoo, shortBar)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DEVSQ(devsqFoo)',
          formula: '=DEVSQ(devsqFoo)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.9970544855015815, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '5.2');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ?? 'NaN',
      ),
      closeTo(9.666666666, 1e-9),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '48');
  });

  test('formula engine evaluates statistical exact named variables', () {
    final covarianceSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [2, 4, 8],
          'bar': [5, 11, 12],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=COVARIANCE.S(foo, bar)',
          formula: '=COVARIANCE.S(foo, bar)',
        ),
      },
    );
    final devsqSheet = FortuneSheet(
      id: 's2',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [4, 5, 8, 7, 11, 4, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DEVSQ(foo)',
          formula: '=DEVSQ(foo)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(covarianceSheet);
    FortuneFormulaEngine.recalculate(devsqSheet);

    expect(
      double.parse(
        covarianceSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ??
            'NaN',
      ),
      closeTo(9.666666666, 1e-9),
    );
    expect(devsqSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '48');
  });

  test('formula engine evaluates statistical average range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '8'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '16'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=AVERAGEIF(A1:B3, ">5", A4:B6)',
          formula: '=AVERAGEIF(A1:B3, ">5", A4:B6)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(7, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(7, 2): const FortuneCell(value: '8'),
        const FortuneCellCoord(7, 3): const FortuneCell(value: '16'),
        const FortuneCellCoord(8, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(8, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(8, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(8, 3): const FortuneCell(value: '4'),
        const FortuneCellCoord(9, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(9, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(9, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(9, 3): const FortuneCell(value: '4'),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=AVERAGEIFS(A8:D8, A9:D9, ">2", A10:D10, ">2")',
          formula: '=AVERAGEIFS(A8:D8, A9:D9, ">2", A10:D10, ">2")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '3.5');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '12');
  });

  test('formula engine evaluates AVERAGEIFS exact range fixture', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '8'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: '16'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 3): const FortuneCell(value: '4'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(2, 3): const FortuneCell(value: '4'),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=AVERAGEIFS(A1:D1, A2:D2, ">2", A3:D3, ">2")',
          formula: '=AVERAGEIFS(A1:D1, A2:D2, ">2", A3:D3, ">2")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '12');
  });

  test('formula engine evaluates statistical count named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1, null, 3, 'a', ''],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=COUNTIF(foo, ">1")',
          formula: '=COUNTIF(foo, ">1")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=COUNTIFS(foo, ">1")',
          formula: '=COUNTIFS(foo, ">1")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
  });

  test('formula engine evaluates COUNTIF range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: 'a'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: 'c'),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=COUNTIF(A1:C2, ">1")',
          formula: '=COUNTIF(A1:C2, ">1")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=COUNTIFS(A1:C2, ">1")',
          formula: '=COUNTIFS(A1:C2, ">1")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '2');
  });

  test('formula engine evaluates statistical forecast named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [6, 7, 9, 15, 21],
          'bar': [20, 28, 31, 38, 40],
          'frequencyFoo': [79, 85, 78, 85, 50, 81, 95, 88, 97],
          'frequencyBar': [70, 79, 89],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=FORECAST(30, foo, bar)',
          formula: '=FORECAST(30, foo, bar)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 1)',
          formula: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 1)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 2)',
          formula: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 2)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 3)',
          formula: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 3)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 4)',
          formula: '=INDEX(FREQUENCY(frequencyFoo, frequencyBar), 1, 4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(10.607253086419755, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '2');
  });

  test(
    'formula engine evaluates statistical frequency exact named variables',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [79, 85, 78, 85, 50, 81, 95, 88, 97],
            'bar': [70, 79, 89],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=FREQUENCY(foo, bar)',
            formula: '=FREQUENCY(foo, bar)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=INDEX(FREQUENCY(foo, bar), 1, 2)',
            formula: '=INDEX(FREQUENCY(foo, bar), 1, 2)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=INDEX(FREQUENCY(foo, bar), 1, 3)',
            formula: '=INDEX(FREQUENCY(foo, bar), 1, 3)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=INDEX(FREQUENCY(foo, bar), 1, 4)',
            formula: '=INDEX(FREQUENCY(foo, bar), 1, 4)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
      expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '2');
      expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '4');
      expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '2');
    },
  );

  test('formula engine evaluates statistical mean named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [4, 5, 8, 7, 11, 4, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=GEOMEAN(foo)',
          formula: '=GEOMEAN(foo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=HARMEAN(foo)',
          formula: '=HARMEAN(foo)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(5.476986969656962, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText ?? 'NaN',
      ),
      closeTo(5.028375962061728, 1e-12),
    );
  });

  test('formula engine evaluates statistical rank named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'interceptFoo': [2, 3, 9, 1, 8],
          'interceptBar': [6, 5, 11, 7, 5],
          'kurtFoo': [3, 4, 5, 2, 3, 4, 5, 6, 4, 7],
          'kurtBar': [3, 4, 5, 2, 3, 4, 5, 'dewdwe', 4, 7],
          'largeFoo': [3, 5, 3, 5, 4],
          'largeBar': [3, 5, 3, 'dwedwed', 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INTERCEPT(interceptFoo, interceptBar)',
          formula: '=INTERCEPT(interceptFoo, interceptBar)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=KURT(kurtFoo)',
          formula: '=KURT(kurtFoo)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=KURT(kurtBar)',
          formula: '=KURT(kurtBar)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=LARGE(largeFoo, 3)',
          formula: '=LARGE(largeFoo, 3)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=LARGE(largeBar, 3)',
          formula: '=LARGE(largeBar, 3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.04838709677419217, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText ?? 'NaN',
      ),
      closeTo(-0.15179963720841627, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates statistical rank exact named variables', () {
    final interceptSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [2, 3, 9, 1, 8],
          'bar': [6, 5, 11, 7, 5],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INTERCEPT(foo, bar)',
          formula: '=INTERCEPT(foo, bar)',
        ),
      },
    );
    final kurtSheet = FortuneSheet(
      id: 's2',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [3, 4, 5, 2, 3, 4, 5, 6, 4, 7],
          'bar': [3, 4, 5, 2, 3, 4, 5, 'dewdwe', 4, 7],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=KURT(foo)',
          formula: '=KURT(foo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=KURT(bar)',
          formula: '=KURT(bar)',
        ),
      },
    );
    final largeSheet = FortuneSheet(
      id: 's3',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [3, 5, 3, 5, 4],
          'bar': [3, 5, 3, 'dwedwed', 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=LARGE(foo, 3)',
          formula: '=LARGE(foo, 3)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=LARGE(bar, 3)',
          formula: '=LARGE(bar, 3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(interceptSheet);
    FortuneFormulaEngine.recalculate(kurtSheet);
    FortuneFormulaEngine.recalculate(largeSheet);

    expect(
      double.parse(
        interceptSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ??
            'NaN',
      ),
      closeTo(0.04838709677419217, 1e-12),
    );
    expect(
      double.parse(
        kurtSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(-0.15179963720841627, 1e-12),
    );
    expect(
      kurtSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '#VALUE!',
    );
    expect(largeSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '4');
    expect(
      largeSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '#VALUE!',
    );
  });

  test('formula engine evaluates statistical estimate named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1, 9, 5, 7],
          'bar': [0, 4, 2, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INDEX(LINEST(foo, bar), 1, 1)',
          formula: '=INDEX(LINEST(foo, bar), 1, 1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(LINEST(foo, bar), 1, 2)',
          formula: '=INDEX(LINEST(foo, bar), 1, 2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=LINEST(foo, "aaaaaa")',
          formula: '=LINEST(foo, "aaaaaa")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=INDEX(LOGEST(foo, bar), 1, 1)',
          formula: '=INDEX(LOGEST(foo, bar), 1, 1)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=INDEX(LOGEST(foo, bar), 1, 2)',
          formula: '=INDEX(LOGEST(foo, bar), 1, 2)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=LOGEST(foo, "aaaaaa")',
          formula: '=LOGEST(foo, "aaaaaa")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText ?? 'NaN',
      ),
      closeTo(1.751116, 1e-6),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText ?? 'NaN',
      ),
      closeTo(1.194316, 1e-6),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates statistical growth named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [33100, 47300, 69000, 102000, 150000, 220000],
          'bar': [11, 12, 13, 14, 15, 16],
          'baz': [11, 12, 13, 14, 15, 16, 17, 18, 19],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INDEX(GROWTH(foo, bar, baz), 1, 1)',
          formula: '=INDEX(GROWTH(foo, bar, baz), 1, 1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(GROWTH(foo, bar, baz), 1, 5)',
          formula: '=INDEX(GROWTH(foo, bar, baz), 1, 5)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=INDEX(GROWTH(foo, bar, baz), 1, 9)',
          formula: '=INDEX(GROWTH(foo, bar, baz), 1, 9)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(32618.20377353843, 1e-7),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText ?? 'NaN',
      ),
      closeTo(149542.4867400496, 1e-7),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ?? 'NaN',
      ),
      closeTo(685597.3889812973, 1e-7),
    );
  });

  test('formula engine evaluates statistical mode named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'multiFoo': [1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1],
          'multiBar': [1, 2, 'dewdew', 4, 3, 2, 1, 2, 3, 5, 6, 1],
          'singleFoo': [5.6, 4, 4, 3, 2, 4],
          'singleBar': [5.6, 'dewdew', 4, 3, 2, 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INDEX(MODEMULT(multiFoo), 1, 1)',
          formula: '=INDEX(MODEMULT(multiFoo), 1, 1)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(MODE.MULT(multiFoo), 1, 2)',
          formula: '=INDEX(MODE.MULT(multiFoo), 1, 2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=INDEX(MODEMULT(multiFoo), 1, 3)',
          formula: '=INDEX(MODEMULT(multiFoo), 1, 3)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=MODEMULT(multiBar)',
          formula: '=MODEMULT(multiBar)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=MODESNGL(singleFoo)',
          formula: '=MODESNGL(singleFoo)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=MODE.SNGL(singleFoo)',
          formula: '=MODE.SNGL(singleFoo)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=MODESNGL(singleBar)',
          formula: '=MODESNGL(singleBar)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates statistical mode exact named variables', () {
    final multiSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1],
          'bar': [1, 2, 'dewdew', 4, 3, 2, 1, 2, 3, 5, 6, 1],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=MODEMULT(foo)',
          formula: '=MODEMULT(foo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=MODE.MULT(foo)',
          formula: '=MODE.MULT(foo)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MODEMULT(bar)',
          formula: '=MODEMULT(bar)',
        ),
      },
    );
    final singleSheet = FortuneSheet(
      id: 's2',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [5.6, 4, 4, 3, 2, 4],
          'bar': [5.6, 'dewdew', 4, 3, 2, 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=MODESNGL(foo)',
          formula: '=MODESNGL(foo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=MODE.SNGL(foo)',
          formula: '=MODE.SNGL(foo)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MODESNGL(bar)',
          formula: '=MODESNGL(bar)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(multiSheet);
    FortuneFormulaEngine.recalculate(singleSheet);

    expect(multiSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '2');
    expect(multiSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '2');
    expect(
      multiSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '#VALUE!',
    );
    expect(singleSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '4');
    expect(singleSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '4');
    expect(
      singleSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '#VALUE!',
    );
  });

  test('formula engine evaluates statistical percentile named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'pearsonFoo': [9, 7, 5, 3, 1],
          'pearsonBar': [10, 6, 1, 5, 3],
          'pearsonBaz': [10, 'dewdewd', 1, 5, 3],
          'rankFoo': [1, 2, 3, 4],
          'rankBar': [1, 'dewdew', 3, 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=PEARSON(pearsonFoo, pearsonBar)',
          formula: '=PEARSON(pearsonFoo, pearsonBar)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=PEARSON(pearsonFoo, pearsonBaz)',
          formula: '=PEARSON(pearsonFoo, pearsonBaz)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=PERCENTILEEXC(rankFoo, 0)',
          formula: '=PERCENTILEEXC(rankFoo, 0)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=PERCENTILEEXC(rankFoo, 0.5)',
          formula: '=PERCENTILEEXC(rankFoo, 0.5)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=PERCENTILEEXC(rankBar, 0.5)',
          formula: '=PERCENTILEEXC(rankBar, 0.5)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=PERCENTILEINC(rankFoo, 0)',
          formula: '=PERCENTILEINC(rankFoo, 0)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=PERCENTILEINC(rankFoo, 0.5)',
          formula: '=PERCENTILEINC(rankFoo, 0.5)',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=PERCENTILEINC(rankBar, 0.5)',
          formula: '=PERCENTILEINC(rankBar, 0.5)',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=PERCENTRANKEXC(rankFoo, 1)',
          formula: '=PERCENTRANKEXC(rankFoo, 1)',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=PERCENTRANKEXC(rankFoo, 4)',
          formula: '=PERCENTRANKEXC(rankFoo, 4)',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=PERCENTRANKEXC(rankBar, 4)',
          formula: '=PERCENTRANKEXC(rankBar, 4)',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=PERCENTRANKINC(rankFoo, 1)',
          formula: '=PERCENTRANKINC(rankFoo, 1)',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value: '=PERCENTRANKINC(rankFoo, 4)',
          formula: '=PERCENTRANKINC(rankFoo, 4)',
        ),
        const FortuneCellCoord(0, 13): const FortuneCell(
          value: '=PERCENTRANKINC(rankBar, 4)',
          formula: '=PERCENTRANKINC(rankBar, 4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.6993786061802354, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '0.2');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '0.8');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 13)]?.renderedText, '#VALUE!');
  });

  test(
    'formula engine evaluates statistical percentile exact named variables',
    () {
      final pearsonSheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [9, 7, 5, 3, 1],
            'bar': [10, 6, 1, 5, 3],
            'baz': [10, 'dewdewd', 1, 5, 3],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=PEARSON(foo, bar)',
            formula: '=PEARSON(foo, bar)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=PEARSON(foo, baz)',
            formula: '=PEARSON(foo, baz)',
          ),
        },
      );
      final rankSheet = FortuneSheet(
        id: 's2',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [1, 2, 3, 4],
            'bar': [1, 'dewdew', 3, 4],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=PERCENTILEEXC(foo, 0)',
            formula: '=PERCENTILEEXC(foo, 0)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=PERCENTILEEXC(foo, 0.5)',
            formula: '=PERCENTILEEXC(foo, 0.5)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=PERCENTILEEXC(bar, 0.5)',
            formula: '=PERCENTILEEXC(bar, 0.5)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=PERCENTILEINC(foo, 0)',
            formula: '=PERCENTILEINC(foo, 0)',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '=PERCENTILEINC(foo, 0.5)',
            formula: '=PERCENTILEINC(foo, 0.5)',
          ),
          const FortuneCellCoord(0, 5): const FortuneCell(
            value: '=PERCENTILEINC(bar, 0.5)',
            formula: '=PERCENTILEINC(bar, 0.5)',
          ),
          const FortuneCellCoord(0, 6): const FortuneCell(
            value: '=PERCENTRANKEXC(foo, 1)',
            formula: '=PERCENTRANKEXC(foo, 1)',
          ),
          const FortuneCellCoord(0, 7): const FortuneCell(
            value: '=PERCENTRANKEXC(foo, 4)',
            formula: '=PERCENTRANKEXC(foo, 4)',
          ),
          const FortuneCellCoord(0, 8): const FortuneCell(
            value: '=PERCENTRANKEXC(bar, 4)',
            formula: '=PERCENTRANKEXC(bar, 4)',
          ),
          const FortuneCellCoord(0, 9): const FortuneCell(
            value: '=PERCENTRANKINC(foo, 1)',
            formula: '=PERCENTRANKINC(foo, 1)',
          ),
          const FortuneCellCoord(0, 10): const FortuneCell(
            value: '=PERCENTRANKINC(foo, 4)',
            formula: '=PERCENTRANKINC(foo, 4)',
          ),
          const FortuneCellCoord(0, 11): const FortuneCell(
            value: '=PERCENTRANKINC(bar, 4)',
            formula: '=PERCENTRANKINC(bar, 4)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(pearsonSheet);
      FortuneFormulaEngine.recalculate(rankSheet);

      expect(
        double.parse(
          pearsonSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ??
              'NaN',
        ),
        closeTo(0.6993786061802354, 1e-12),
      );
      expect(
        pearsonSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '#VALUE!',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '#NUM!',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '2.5',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '#VALUE!',
      );
      expect(rankSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '1');
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '2.5',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 5)]?.renderedText,
        '#VALUE!',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 6)]?.renderedText,
        '0.2',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 7)]?.renderedText,
        '0.8',
      );
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 8)]?.renderedText,
        '#VALUE!',
      );
      expect(rankSheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '0');
      expect(rankSheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '1');
      expect(
        rankSheet.cells[const FortuneCellCoord(0, 11)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test(
    'formula engine evaluates statistical quartile rank named variables',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'quartileExcFoo': [6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49],
            'quartileIncFoo': [1, 2, 4, 7, 8, 9, 10, 12],
            'rankAvgFoo': [89, 88, 92, 101, 94, 97, 95],
            'rankEqFoo': [7, 3.5, 3.5, 1, 2],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=QUARTILEEXC(quartileExcFoo, 1)',
            formula: '=QUARTILEEXC(quartileExcFoo, 1)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=QUARTILEEXC(quartileExcFoo, 2)',
            formula: '=QUARTILEEXC(quartileExcFoo, 2)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=QUARTILE.EXC(quartileExcFoo, 2)',
            formula: '=QUARTILE.EXC(quartileExcFoo, 2)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=QUARTILEEXC(quartileExcFoo, 4)',
            formula: '=QUARTILEEXC(quartileExcFoo, 4)',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '=QUARTILEEXC(quartileExcFoo, "dwe")',
            formula: '=QUARTILEEXC(quartileExcFoo, "dwe")',
          ),
          const FortuneCellCoord(0, 5): const FortuneCell(
            value: '=QUARTILEINC(quartileIncFoo, 1)',
            formula: '=QUARTILEINC(quartileIncFoo, 1)',
          ),
          const FortuneCellCoord(0, 6): const FortuneCell(
            value: '=QUARTILEINC(quartileIncFoo, 2)',
            formula: '=QUARTILEINC(quartileIncFoo, 2)',
          ),
          const FortuneCellCoord(0, 7): const FortuneCell(
            value: '=QUARTILE.INC(quartileIncFoo, 2)',
            formula: '=QUARTILE.INC(quartileIncFoo, 2)',
          ),
          const FortuneCellCoord(0, 8): const FortuneCell(
            value: '=QUARTILEINC(quartileIncFoo, 4)',
            formula: '=QUARTILEINC(quartileIncFoo, 4)',
          ),
          const FortuneCellCoord(0, 9): const FortuneCell(
            value: '=QUARTILEINC(quartileIncFoo, "dwe")',
            formula: '=QUARTILEINC(quartileIncFoo, "dwe")',
          ),
          const FortuneCellCoord(0, 10): const FortuneCell(
            value: '=RANKAVG(94, rankAvgFoo)',
            formula: '=RANKAVG(94, rankAvgFoo)',
          ),
          const FortuneCellCoord(0, 11): const FortuneCell(
            value: '=RANKAVG(88, rankAvgFoo, 1)',
            formula: '=RANKAVG(88, rankAvgFoo, 1)',
          ),
          const FortuneCellCoord(0, 12): const FortuneCell(
            value: '=RANK.AVG(88, rankAvgFoo, 1)',
            formula: '=RANK.AVG(88, rankAvgFoo, 1)',
          ),
          const FortuneCellCoord(0, 13): const FortuneCell(
            value: '=RANKAVG("dwe", rankAvgFoo, 1)',
            formula: '=RANKAVG("dwe", rankAvgFoo, 1)',
          ),
          const FortuneCellCoord(0, 14): const FortuneCell(
            value: '=RANKEQ(7, rankEqFoo, 1)',
            formula: '=RANKEQ(7, rankEqFoo, 1)',
          ),
          const FortuneCellCoord(0, 15): const FortuneCell(
            value: '=RANKEQ(2, rankEqFoo)',
            formula: '=RANKEQ(2, rankEqFoo)',
          ),
          const FortuneCellCoord(0, 16): const FortuneCell(
            value: '=RANK.EQ(2, rankEqFoo)',
            formula: '=RANK.EQ(2, rankEqFoo)',
          ),
          const FortuneCellCoord(0, 17): const FortuneCell(
            value: '=RANKEQ("dwe", rankEqFoo, TRUE)',
            formula: '=RANKEQ("dwe", rankEqFoo, TRUE)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '15');
      expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '40');
      expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '40');
      expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
      expect(
        sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '#VALUE!',
      );
      expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '3.5');
      expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '7.5');
      expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '7.5');
      expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '#NUM!');
      expect(
        sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText,
        '#VALUE!',
      );
      expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '4');
      expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, '1');
      expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, '1');
      expect(
        sheet.cells[const FortuneCellCoord(0, 13)]?.renderedText,
        '#VALUE!',
      );
      expect(sheet.cells[const FortuneCellCoord(0, 14)]?.renderedText, '5');
      expect(sheet.cells[const FortuneCellCoord(0, 15)]?.renderedText, '4');
      expect(sheet.cells[const FortuneCellCoord(0, 16)]?.renderedText, '4');
      expect(
        sheet.cells[const FortuneCellCoord(0, 17)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test(
    'formula engine evaluates statistical quartile rank exact named variables',
    () {
      final quartileExcSheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=QUARTILEEXC(foo, 1)',
            formula: '=QUARTILEEXC(foo, 1)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=QUARTILEEXC(foo, 2)',
            formula: '=QUARTILEEXC(foo, 2)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=QUARTILE.EXC(foo, 2)',
            formula: '=QUARTILE.EXC(foo, 2)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=QUARTILEEXC(foo, 4)',
            formula: '=QUARTILEEXC(foo, 4)',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '=QUARTILEEXC(foo, "dwe")',
            formula: '=QUARTILEEXC(foo, "dwe")',
          ),
        },
      );
      final quartileIncSheet = FortuneSheet(
        id: 's2',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [1, 2, 4, 7, 8, 9, 10, 12],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=QUARTILEINC(foo, 1)',
            formula: '=QUARTILEINC(foo, 1)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=QUARTILEINC(foo, 2)',
            formula: '=QUARTILEINC(foo, 2)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=QUARTILE.INC(foo, 2)',
            formula: '=QUARTILE.INC(foo, 2)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=QUARTILEINC(foo, 4)',
            formula: '=QUARTILEINC(foo, 4)',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '=QUARTILEINC(foo, "dwe")',
            formula: '=QUARTILEINC(foo, "dwe")',
          ),
        },
      );
      final rankAvgSheet = FortuneSheet(
        id: 's3',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [89, 88, 92, 101, 94, 97, 95],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=RANKAVG(94, foo)',
            formula: '=RANKAVG(94, foo)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=RANKAVG(88, foo, 1)',
            formula: '=RANKAVG(88, foo, 1)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=RANK.AVG(88, foo, 1)',
            formula: '=RANK.AVG(88, foo, 1)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=RANKAVG("dwe", foo, 1)',
            formula: '=RANKAVG("dwe", foo, 1)',
          ),
        },
      );
      final rankEqSheet = FortuneSheet(
        id: 's4',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [7, 3.5, 3.5, 1, 2],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=RANKEQ(7, foo, 1)',
            formula: '=RANKEQ(7, foo, 1)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=RANKEQ(2, foo)',
            formula: '=RANKEQ(2, foo)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=RANK.EQ(2, foo)',
            formula: '=RANK.EQ(2, foo)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=RANKEQ("dwe", foo, TRUE)',
            formula: '=RANKEQ("dwe", foo, TRUE)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(quartileExcSheet);
      FortuneFormulaEngine.recalculate(quartileIncSheet);
      FortuneFormulaEngine.recalculate(rankAvgSheet);
      FortuneFormulaEngine.recalculate(rankEqSheet);

      expect(
        quartileExcSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '15',
      );
      expect(
        quartileExcSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '40',
      );
      expect(
        quartileExcSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '40',
      );
      expect(
        quartileExcSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#NUM!',
      );
      expect(
        quartileExcSheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '#VALUE!',
      );
      expect(
        quartileIncSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '3.5',
      );
      expect(
        quartileIncSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '7.5',
      );
      expect(
        quartileIncSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '7.5',
      );
      expect(
        quartileIncSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#NUM!',
      );
      expect(
        quartileIncSheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '#VALUE!',
      );
      expect(
        rankAvgSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '4',
      );
      expect(
        rankAvgSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '1',
      );
      expect(
        rankAvgSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '1',
      );
      expect(
        rankAvgSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#VALUE!',
      );
      expect(
        rankEqSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '5',
      );
      expect(
        rankEqSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '4',
      );
      expect(
        rankEqSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
        '4',
      );
      expect(
        rankEqSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test('formula engine evaluates statistical regression named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'probFoo': [0, 1, 2, 3],
          'probBar': [0.2, 0.3, 0.1, 0.4],
          'probBaz': [0, 'dewd', 2, 3],
          'regressionFoo': [2, 3, 9, 1, 8, 7, 5],
          'regressionBar': [6, 5, 11, 7, 5, 4, 4],
          'regressionBaz': [6, 'dwe', 11, 7, 5, 4, 4],
          'skewFoo': [3, 4, 5, 2, 3, 4, 5, 6, 4, 7],
          'skewBar': [3, 'dwe', 5, 2, 3, 4, 5, 6, 4, 7],
          'smallFoo': [3, 4, 5, 2, 3, 4, 6, 4, 7],
          'smallBar': [3, 4, 'dwe', 2, 3, 4, 6, 4, 7],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=PROB(probFoo, probBar, 2)',
          formula: '=PROB(probFoo, probBar, 2)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=PROB(probFoo, probBar, 1, 3)',
          formula: '=PROB(probFoo, probBar, 1, 3)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=PROB(probFoo, probBar)',
          formula: '=PROB(probFoo, probBar)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=PROB(probBaz, probBar, 1, 3)',
          formula: '=PROB(probBaz, probBar, 1, 3)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=RSQ(regressionFoo, regressionBar)',
          formula: '=RSQ(regressionFoo, regressionBar)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=RSQ(regressionBaz, regressionBar)',
          formula: '=RSQ(regressionBaz, regressionBar)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=SKEW(skewFoo)',
          formula: '=SKEW(skewFoo)',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=SKEW(skewBar)',
          formula: '=SKEW(skewBar)',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=SKEWP(skewFoo)',
          formula: '=SKEWP(skewFoo)',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=SKEW.P(skewFoo)',
          formula: '=SKEW.P(skewFoo)',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=SKEWP(skewBar)',
          formula: '=SKEWP(skewBar)',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=SKEW.P(skewBar)',
          formula: '=SKEW.P(skewBar)',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value: '=SLOPE(regressionFoo, regressionBar)',
          formula: '=SLOPE(regressionFoo, regressionBar)',
        ),
        const FortuneCellCoord(0, 13): const FortuneCell(
          value: '=SLOPE(regressionBaz, regressionBar)',
          formula: '=SLOPE(regressionBaz, regressionBar)',
        ),
        const FortuneCellCoord(0, 14): const FortuneCell(
          value: '=SMALL(smallFoo, 4)',
          formula: '=SMALL(smallFoo, 4)',
        ),
        const FortuneCellCoord(0, 15): const FortuneCell(
          value: '=SMALL(smallBar, 4)',
          formula: '=SMALL(smallBar, 4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0.1');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0.8');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.05795019157088122, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.3595430714067974, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.303193339354144, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.303193339354144, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText ?? 'NaN',
      ),
      closeTo(0.3055555555555556, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 13)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 14)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 15)]?.renderedText, '#VALUE!');
  });

  test(
    'formula engine evaluates statistical regression exact named variables',
    () {
      final regressionSheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [2, 3, 9, 1, 8, 7, 5],
            'bar': [6, 5, 11, 7, 5, 4, 4],
            'baz': [6, 'dwe', 11, 7, 5, 4, 4],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=RSQ(foo, bar)',
            formula: '=RSQ(foo, bar)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=RSQ(baz, bar)',
            formula: '=RSQ(baz, bar)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=SLOPE(foo, bar)',
            formula: '=SLOPE(foo, bar)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=SLOPE(baz, bar)',
            formula: '=SLOPE(baz, bar)',
          ),
        },
      );
      final skewSheet = FortuneSheet(
        id: 's2',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [3, 4, 5, 2, 3, 4, 5, 6, 4, 7],
            'bar': [3, 'dwe', 5, 2, 3, 4, 5, 6, 4, 7],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=SKEW(foo)',
            formula: '=SKEW(foo)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=SKEW(bar)',
            formula: '=SKEW(bar)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=SKEWP(foo)',
            formula: '=SKEWP(foo)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=SKEW.P(foo)',
            formula: '=SKEW.P(foo)',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '=SKEWP(bar)',
            formula: '=SKEWP(bar)',
          ),
          const FortuneCellCoord(0, 5): const FortuneCell(
            value: '=SKEW.P(bar)',
            formula: '=SKEW.P(bar)',
          ),
        },
      );
      final smallSheet = FortuneSheet(
        id: 's3',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [3, 4, 5, 2, 3, 4, 6, 4, 7],
            'bar': [3, 4, 'dwe', 2, 3, 4, 6, 4, 7],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=SMALL(foo, 4)',
            formula: '=SMALL(foo, 4)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=SMALL(bar, 4)',
            formula: '=SMALL(bar, 4)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(regressionSheet);
      FortuneFormulaEngine.recalculate(skewSheet);
      FortuneFormulaEngine.recalculate(smallSheet);

      expect(
        double.parse(
          regressionSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ??
              'NaN',
        ),
        closeTo(0.05795019157088122, 1e-12),
      );
      expect(
        regressionSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '#VALUE!',
      );
      expect(
        double.parse(
          regressionSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ??
              'NaN',
        ),
        closeTo(0.3055555555555556, 1e-12),
      );
      expect(
        regressionSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#VALUE!',
      );
      expect(
        double.parse(
          skewSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
        ),
        closeTo(0.3595430714067974, 1e-12),
      );
      expect(
        skewSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '#VALUE!',
      );
      expect(
        double.parse(
          skewSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ?? 'NaN',
        ),
        closeTo(0.303193339354144, 1e-12),
      );
      expect(
        double.parse(
          skewSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText ?? 'NaN',
        ),
        closeTo(0.303193339354144, 1e-12),
      );
      expect(
        skewSheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '#VALUE!',
      );
      expect(
        skewSheet.cells[const FortuneCellCoord(0, 5)]?.renderedText,
        '#VALUE!',
      );
      expect(smallSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '4');
      expect(
        smallSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test(
    'formula engine evaluates statistical probability exact named variables',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: const {
          'formulaVariables': {
            'foo': [0, 1, 2, 3],
            'bar': [0.2, 0.3, 0.1, 0.4],
            'baz': [0, 'dewd', 2, 3],
          },
        },
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=PROB(foo, bar, 2)',
            formula: '=PROB(foo, bar, 2)',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=PROB(foo, bar, 1, 3)',
            formula: '=PROB(foo, bar, 1, 3)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=PROB(foo, bar)',
            formula: '=PROB(foo, bar)',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=PROB(baz, bar, 1, 3)',
            formula: '=PROB(baz, bar, 1, 3)',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0.1');
      expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0.8');
      expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '0');
      expect(
        sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        '#VALUE!',
      );
    },
  );

  test('formula engine evaluates statistical trend named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'deviationFoo': [
            1345,
            1301,
            1368,
            1322,
            1310,
            1370,
            1318,
            1350,
            1303,
            1299,
          ],
          'steyxFoo': [2, 3, 9, 1, 8, 7, 5],
          'steyxBar': [6, 5, 11, 7, 5, 4, 4],
          'steyxBaz': [6, 5, 'dwe', 7, 5, 4, 4],
          'trendFoo': [1, 9, 5, 7],
          'trendBar': [0, 4, 2, 3],
          'trendBaz': [5, 8],
          'trimFoo': [4, 5, 6, 7, 2, 3, 4, 5, 1, 2, 3],
          'trimBar': [4, 5, 'dwe', 7, 2, 3, 4, 5, 1, 2, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=STDEVP(deviationFoo)',
          formula: '=STDEVP(deviationFoo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=STDEV.P(deviationFoo)',
          formula: '=STDEV.P(deviationFoo)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=STDEVS(deviationFoo)',
          formula: '=STDEVS(deviationFoo)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=STDEV.S(deviationFoo)',
          formula: '=STDEV.S(deviationFoo)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=STDEVA(deviationFoo)',
          formula: '=STDEVA(deviationFoo)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=STDEVPA(deviationFoo)',
          formula: '=STDEVPA(deviationFoo)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=STEYX(steyxFoo, steyxBar)',
          formula: '=STEYX(steyxFoo, steyxBar)',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=STEYX(steyxBaz, steyxBar)',
          formula: '=STEYX(steyxBaz, steyxBar)',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=INDEX(TREND(trendFoo, trendBar, trendBaz), 1, 1)',
          formula: '=INDEX(TREND(trendFoo, trendBar, trendBaz), 1, 1)',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=INDEX(TREND(trendFoo, trendBar, trendBaz), 1, 2)',
          formula: '=INDEX(TREND(trendFoo, trendBar, trendBaz), 1, 2)',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=TREND(trendFoo, trendBar, "dwe")',
          formula: '=TREND(trendFoo, trendBar, "dwe")',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=TRIMMEAN(trimFoo, 0.2)',
          formula: '=TRIMMEAN(trimFoo, 0.2)',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value: '=TRIMMEAN(trimBar, 0.2)',
          formula: '=TRIMMEAN(trimBar, 0.2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText ?? 'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ?? 'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText ?? 'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText ?? 'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText ?? 'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText ?? 'NaN',
      ),
      closeTo(3.305718950210041, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '17');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '#VALUE!');
    expect(
      double.parse(
        sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText ?? 'NaN',
      ),
      closeTo(3.777777777777, 1e-11),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates statistical trend exact named variables', () {
    final deviationSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1345, 1301, 1368, 1322, 1310, 1370, 1318, 1350, 1303, 1299],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=STDEVP(foo)',
          formula: '=STDEVP(foo)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=STDEV.P(foo)',
          formula: '=STDEV.P(foo)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=STDEVS(foo)',
          formula: '=STDEVS(foo)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=STDEV.S(foo)',
          formula: '=STDEV.S(foo)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=STDEVA(foo)',
          formula: '=STDEVA(foo)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=STDEVPA(foo)',
          formula: '=STDEVPA(foo)',
        ),
      },
    );
    final steyxSheet = FortuneSheet(
      id: 's2',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [2, 3, 9, 1, 8, 7, 5],
          'bar': [6, 5, 11, 7, 5, 4, 4],
          'baz': [6, 5, 'dwe', 7, 5, 4, 4],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=STEYX(foo, bar)',
          formula: '=STEYX(foo, bar)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=STEYX(baz, bar)',
          formula: '=STEYX(baz, bar)',
        ),
      },
    );
    final trendSheet = FortuneSheet(
      id: 's3',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [1, 9, 5, 7],
          'bar': [0, 4, 2, 3],
          'baz': [5, 8],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=TREND(foo, bar, baz)',
          formula: '=TREND(foo, bar, baz)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(TREND(foo, bar, baz), 1, 2)',
          formula: '=INDEX(TREND(foo, bar, baz), 1, 2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=TREND(foo, bar, "dwe")',
          formula: '=TREND(foo, bar, "dwe")',
        ),
      },
    );
    final trimSheet = FortuneSheet(
      id: 's4',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [4, 5, 6, 7, 2, 3, 4, 5, 1, 2, 3],
          'bar': [4, 5, 'dwe', 7, 2, 3, 4, 5, 1, 2, 3],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=TRIMMEAN(foo, 0.2)',
          formula: '=TRIMMEAN(foo, 0.2)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=TRIMMEAN(bar, 0.2)',
          formula: '=TRIMMEAN(bar, 0.2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(deviationSheet);
    FortuneFormulaEngine.recalculate(steyxSheet);
    FortuneFormulaEngine.recalculate(trendSheet);
    FortuneFormulaEngine.recalculate(trimSheet);

    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ??
            'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText ??
            'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText ??
            'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText ??
            'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 4)]?.renderedText ??
            'NaN',
      ),
      closeTo(27.46391571984349, 1e-12),
    );
    expect(
      double.parse(
        deviationSheet.cells[const FortuneCellCoord(0, 5)]?.renderedText ??
            'NaN',
      ),
      closeTo(26.054558142482477, 1e-12),
    );
    expect(
      double.parse(
        steyxSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(3.305718950210041, 1e-12),
    );
    expect(
      steyxSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '#VALUE!',
    );
    expect(trendSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '11');
    expect(trendSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '17');
    expect(
      trendSheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '#VALUE!',
    );
    expect(
      double.parse(
        trimSheet.cells[const FortuneCellCoord(0, 0)]?.renderedText ?? 'NaN',
      ),
      closeTo(3.777777777777, 1e-11),
    );
    expect(
      trimSheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '#VALUE!',
    );
  });

  test('formula engine evaluates statistical regression arrays', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '79'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '85'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '78'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: '85'),
        const FortuneCellCoord(0, 4): const FortuneCell(value: '50'),
        const FortuneCellCoord(0, 5): const FortuneCell(value: '81'),
        const FortuneCellCoord(0, 6): const FortuneCell(value: '95'),
        const FortuneCellCoord(0, 7): const FortuneCell(value: '88'),
        const FortuneCellCoord(0, 8): const FortuneCell(value: '97'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '70'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '79'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '89'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '9'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '5'),
        const FortuneCellCoord(2, 3): const FortuneCell(value: '7'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '0'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(3, 2): const FortuneCell(value: '2'),
        const FortuneCellCoord(3, 3): const FortuneCell(value: '3'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '5'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: '8'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: '33100'),
        const FortuneCellCoord(5, 1): const FortuneCell(value: '47300'),
        const FortuneCellCoord(5, 2): const FortuneCell(value: '69000'),
        const FortuneCellCoord(5, 3): const FortuneCell(value: '102000'),
        const FortuneCellCoord(5, 4): const FortuneCell(value: '150000'),
        const FortuneCellCoord(5, 5): const FortuneCell(value: '220000'),
        const FortuneCellCoord(6, 0): const FortuneCell(value: '11'),
        const FortuneCellCoord(6, 1): const FortuneCell(value: '12'),
        const FortuneCellCoord(6, 2): const FortuneCell(value: '13'),
        const FortuneCellCoord(6, 3): const FortuneCell(value: '14'),
        const FortuneCellCoord(6, 4): const FortuneCell(value: '15'),
        const FortuneCellCoord(6, 5): const FortuneCell(value: '16'),
        const FortuneCellCoord(6, 6): const FortuneCell(value: '17'),
        const FortuneCellCoord(6, 7): const FortuneCell(value: '18'),
        const FortuneCellCoord(6, 8): const FortuneCell(value: '19'),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 1)',
          formula: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 1)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 3)',
          formula: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 3)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 4)',
          formula: '=INDEX(FREQUENCY(A1:I1, A2:C2), 1, 4)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=INDEX(LINEST(A3:D3, A4:D4), 1, 1)',
          formula: '=INDEX(LINEST(A3:D3, A4:D4), 1, 1)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=INDEX(LINEST(A3:D3, A4:D4), 1, 2)',
          formula: '=INDEX(LINEST(A3:D3, A4:D4), 1, 2)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=INDEX(TREND(A3:D3, A4:D4, A5:B5), 1, 1)',
          formula: '=INDEX(TREND(A3:D3, A4:D4, A5:B5), 1, 1)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=INDEX(TREND(A3:D3, A4:D4, A5:B5), 1, 2)',
          formula: '=INDEX(TREND(A3:D3, A4:D4, A5:B5), 1, 2)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=INDEX(LOGEST(A3:D3, A4:D4), 1, 1)',
          formula: '=INDEX(LOGEST(A3:D3, A4:D4), 1, 1)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=INDEX(LOGEST(A3:D3, A4:D4), 1, 2)',
          formula: '=INDEX(LOGEST(A3:D3, A4:D4), 1, 2)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=INDEX(GROWTH(A6:F6, A7:F7, A7:I7), 1, 9)',
          formula: '=INDEX(GROWTH(A6:F6, A7:F7, A7:I7), 1, 9)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '17');
    expect(
      sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText,
      '1.751115955582',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText,
      '1.194315590982',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText,
      '685597.388981237542',
    );
  });

  test('formula engine recalculates dependent formulas', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1+1',
          formula: '=A1+1',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=B1+1',
          formula: '=B1+1',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '6');

    sheet.cells[const FortuneCellCoord(0, 0)] = const FortuneCell(value: '10');
    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '12');
  });

  test(
    'formula engine preserves cells when recalculated result is unchanged',
    () {
      const formulaCoord = FortuneCellCoord(0, 1);
      const formulaCell = FortuneCell(
        value: '5',
        rawValue: '5',
        hasRawValue: true,
        formula: '=A1+1',
        rawFormula: '=A1+1',
        hasRawFormula: true,
        displayValue: '5',
        rawDisplayValue: '5',
        hasRawDisplayValue: true,
      );
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: '4'),
          formulaCoord: formulaCell,
        },
      );
      final preservedCell = sheet.cells[formulaCoord];

      FortuneFormulaEngine.recalculate(sheet);

      expect(identical(sheet.cells[formulaCoord], preservedCell), isTrue);
      expect(sheet.cells[formulaCoord]?.renderedText, '5');
    },
  );

  test('formula engine evaluates comparisons booleans and IF strings', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '8'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=A1>5',
          formula: '=A1>5',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=IF(A1>=10, "high", "low")',
          formula: '=IF(A1>=10, "high", "low")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=IF(FALSE, 1, A1+2)',
          formula: '=IF(FALSE, 1, A1+2)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '="a""b"="a""b"',
          formula: '="a""b"="a""b"',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=NULL=0',
          formula: '=NULL=0',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=NULL<>1',
          formula: '=NULL<>1',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'low');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, 'TRUE');
  });

  test('formula engine concatenates strings and referenced values', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'North'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '12'),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=A1&" "&B1',
          formula: '=A1&" "&B1',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=CONCAT(A1, "-", B1+1)',
          formula: '=CONCAT(A1, "-", B1+1)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=IF(A1="North", A1&" ok", "no")',
          formula: '=IF(A1="North", A1&" ok", "no")',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=A1&" "&B1="North 12"',
          formula: '=A1&" "&B1="North 12"',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '="A"&1="A1"',
          formula: '="A"&1="A1"',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=NULL&"tail"',
          formula: '=NULL&"tail"',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '="head"&NULL',
          formula: '="head"&NULL',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=CONCAT()',
          formula: '=CONCAT()',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=CONCAT("head", NULL, "", "tail")',
          formula: '=CONCAT("head", NULL, "", "tail")',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=CONCAT(A1:B1, "-done")',
          formula: '=CONCAT(A1:B1, "-done")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'North 12');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'North-13');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, 'North ok');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, 'tail');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, 'head');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '');
    expect(
      sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText,
      'headtail',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText,
      'North12-done',
    );
  });

  test('formula engine evaluates only the selected IF branch', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=IF(TRUE, "ok", 1/0)',
          formula: '=IF(TRUE, "ok", 1/0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=IF(FALSE, UNKNOWN(1), 42)',
          formula: '=IF(FALSE, UNKNOWN(1), 42)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=IF(1=1, CONCAT("A", "-", "B"), 1/0)',
          formula: '=IF(1=1, CONCAT("A", "-", "B"), 1/0)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=IFS(FALSE, 1/0, TRUE, "matched", UNKNOWN(1), 2)',
          formula: '=IFS(FALSE, 1/0, TRUE, "matched", UNKNOWN(1), 2)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=SWITCH("b", "a", 1/0, "b", "bee", "fallback")',
          formula: '=SWITCH("b", "a", 1/0, "b", "bee", "fallback")',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=SWITCH("z", "a", 1/0, "fallback")',
          formula: '=SWITCH("z", "a", 1/0, "fallback")',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=SWITCH(10, 9, "foo", 7, "bar")',
          formula: '=SWITCH(10, 9, "foo", 7, "bar")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'ok');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'A-B');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'matched');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, 'bee');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'fallback');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '#N/A');
  });

  test('formula engine lazily evaluates semicolon choice branches', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=IFS(FALSE; 1/0; TRUE; "matched"; TRUE; UNKNOWN(1))',
          formula: '=IFS(FALSE; 1/0; TRUE; "matched"; TRUE; UNKNOWN(1))',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=SWITCH("b"; "a"; 1/0; "b"; "bee"; "fallback")',
          formula: '=SWITCH("b"; "a"; 1/0; "b"; "bee"; "fallback")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=SWITCH("z"; "a"; 1/0; "fallback")',
          formula: '=SWITCH("z"; "a"; 1/0; "fallback")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=CHOOSE(2; 1/0; "blue"; UNKNOWN(1))',
          formula: '=CHOOSE(2; 1/0; "blue"; UNKNOWN(1))',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'matched');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'bee');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'fallback');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'blue');
  });

  test('formula engine evaluates IFERROR fallback lazily', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=IFERROR(1/0, "fallback")',
          formula: '=IFERROR(1/0, "fallback")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=IFERROR(UNKNOWN(1), 42)',
          formula: '=IFERROR(UNKNOWN(1), 42)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=IFERROR(5+1, UNKNOWN(1))',
          formula: '=IFERROR(5+1, UNKNOWN(1))',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=IFERROR(CONCAT("A", "-", "B"), 1/0)',
          formula: '=IFERROR(CONCAT("A", "-", "B"), 1/0)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'fallback');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'A-B');
  });

  test('formula engine evaluates error information lazily', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ISERROR(1/0)',
          formula: '=ISERROR(1/0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ISERROR(UNKNOWN(1))',
          formula: '=ISERROR(UNKNOWN(1))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ISERROR(5+1)',
          formula: '=ISERROR(5+1)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=ISERR(CONCAT("A", "B"))',
          formula: '=ISERR(CONCAT("A", "B"))',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=NA()',
          formula: '=NA()',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=ISNA(NA())',
          formula: '=ISNA(NA())',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=ISERROR(NA())',
          formula: '=ISERROR(NA())',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=ISERR(NA())',
          formula: '=ISERR(NA())',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=IFNA(NA(), "missing")',
          formula: '=IFNA(NA(), "missing")',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=IFNA(42, UNKNOWN(1))',
          formula: '=IFNA(42, UNKNOWN(1))',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=1/0',
          formula: '=1/0',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=ISERR(1/0)',
          formula: '=ISERR(1/0)',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value: '=ISNA(1/0)',
          formula: '=ISNA(1/0)',
        ),
        const FortuneCellCoord(0, 13): const FortuneCell(
          value: '=IFNA(1/0, "missing")',
          formula: '=IFNA(1/0, "missing")',
        ),
        const FortuneCellCoord(0, 14): const FortuneCell(
          value: '=(1/0)+1',
          formula: '=(1/0)+1',
        ),
        const FortuneCellCoord(0, 15): const FortuneCell(
          value: '=2*NA()',
          formula: '=2*NA()',
        ),
        const FortuneCellCoord(0, 16): const FortuneCell(
          value: '=NA()^2',
          formula: '=NA()^2',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=NA()&"x"',
          formula: '=NA()&"x"',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=NA()=NA()',
          formula: '=NA()=NA()',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=SUM(1, NA())',
          formula: '=SUM(1, NA())',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=IFERROR(SUM(1, NA()), "fallback")',
          formula: '=IFERROR(SUM(1, NA()), "fallback")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=IFNA(SUM(1, NA()), "missing")',
          formula: '=IFNA(SUM(1, NA()), "missing")',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=IFERROR(1/0%, "fallback")',
          formula: '=IFERROR(1/0%, "fallback")',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=#REF!+1',
          formula: '=#REF!+1',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=IFERROR(#REF!+1, "bad ref")',
          formula: '=IFERROR(#REF!+1, "bad ref")',
        ),
        const FortuneCellCoord(1, 8): const FortuneCell(
          value: '=#NULL!',
          formula: '=#NULL!',
        ),
        const FortuneCellCoord(1, 9): const FortuneCell(
          value: '=ISERROR(#NULL!)',
          formula: '=ISERROR(#NULL!)',
        ),
        const FortuneCellCoord(1, 10): const FortuneCell(
          value: '=ISERR(#NULL!)',
          formula: '=ISERR(#NULL!)',
        ),
        const FortuneCellCoord(1, 11): const FortuneCell(
          value: '=ISNA(#NULL!)',
          formula: '=ISNA(#NULL!)',
        ),
        const FortuneCellCoord(1, 12): const FortuneCell(
          value: '=IFERROR(#NULL!+1, "null intersection")',
          formula: '=IFERROR(#NULL!+1, "null intersection")',
        ),
        const FortuneCellCoord(1, 13): const FortuneCell(
          value: '=IFNA(#NULL!, "missing")',
          formula: '=IFNA(#NULL!, "missing")',
        ),
        const FortuneCellCoord(1, 14): const FortuneCell(
          value: '=IFERROR(NA(), "direct fallback")',
          formula: '=IFERROR(NA(), "direct fallback")',
        ),
        const FortuneCellCoord(1, 15): const FortuneCell(
          value: '=IFNA(NA(), "direct missing")',
          formula: '=IFNA(NA(), "direct missing")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 13)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 14)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 15)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(0, 16)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, 'fallback');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, 'fallback');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, 'bad ref');
    expect(sheet.cells[const FortuneCellCoord(1, 8)]?.renderedText, '#NULL!');
    expect(sheet.cells[const FortuneCellCoord(1, 9)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 10)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 11)]?.renderedText, 'FALSE');
    expect(
      sheet.cells[const FortuneCellCoord(1, 12)]?.renderedText,
      'null intersection',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 13)]?.renderedText, '#NULL!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 14)]?.renderedText,
      'direct fallback',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 15)]?.renderedText,
      'direct missing',
    );
  });

  test('formula engine evaluates logical functions', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '0'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=AND(A1>0, TRUE, NOT(A2))',
          formula: '=AND(A1>0, TRUE, NOT(A2))',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=OR(A2, FALSE, A1=1)',
          formula: '=OR(A2, FALSE, A1=1)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=IF(AND(A1=1, NOT(A2)), "yes", "no")',
          formula: '=IF(AND(A1=1, NOT(A2)), "yes", "no")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=XOR(FALSE, A1=1, A2=1)',
          formula: '=XOR(FALSE, A1=1, A2=1)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=XOR(TRUE, A1=1, A2=1)',
          formula: '=XOR(TRUE, A1=1, A2=1)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=AND(TRUE(), NOT(FALSE()))',
          formula: '=AND(TRUE(), NOT(FALSE()))',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=AND()',
          formula: '=AND()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=OR()',
          formula: '=OR()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=XOR()',
          formula: '=XOR()',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=NOT()',
          formula: '=NOT()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=IF()',
          formula: '=IF()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=CHOOSE()',
          formula: '=CHOOSE()',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=AND(TRUE, TRUE, FALSE)',
          formula: '=AND(TRUE, TRUE, FALSE)',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=AND(TRUE, TRUE, TRUE)',
          formula: '=AND(TRUE, TRUE, TRUE)',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=OR(TRUE, TRUE, TRUE)',
          formula: '=OR(TRUE, TRUE, TRUE)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=OR(TRUE, FALSE, FALSE)',
          formula: '=OR(TRUE, FALSE, FALSE)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=OR(FALSE, FALSE, FALSE)',
          formula: '=OR(FALSE, FALSE, FALSE)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=NOT(TRUE)',
          formula: '=NOT(TRUE)',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=NOT(FALSE)',
          formula: '=NOT(FALSE)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=NOT(0)',
          formula: '=NOT(0)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=NOT(1)',
          formula: '=NOT(1)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=TRUE()',
          formula: '=TRUE()',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=FALSE()',
          formula: '=FALSE()',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=IF(TRUE, 1, 2)',
          formula: '=IF(TRUE, 1, 2)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=IF(FALSE, 1, 2)',
          formula: '=IF(FALSE, 1, 2)',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=CHOOSE(1, "foo", "bar", "baz")',
          formula: '=CHOOSE(1, "foo", "bar", "baz")',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=CHOOSE(3, "foo", "bar", "baz")',
          formula: '=CHOOSE(3, "foo", "bar", "baz")',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=CHOOSE(4, "foo", "bar", "baz")',
          formula: '=CHOOSE(4, "foo", "bar", "baz")',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=SWITCH(7, "foo")',
          formula: '=SWITCH(7, "foo")',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=SWITCH(7, 9, "foo", 7, "bar")',
          formula: '=SWITCH(7, 9, "foo", 7, "bar")',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=SWITCH(10, 9, "foo", 7, "bar")',
          formula: '=SWITCH(10, 9, "foo", 7, "bar")',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=SWITCH()',
          formula: '=SWITCH()',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=XOR(TRUE, TRUE)',
          formula: '=XOR(TRUE, TRUE)',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=XOR(TRUE, FALSE)',
          formula: '=XOR(TRUE, FALSE)',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=XOR(FALSE, TRUE)',
          formula: '=XOR(FALSE, TRUE)',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=XOR(FALSE, FALSE)',
          formula: '=XOR(FALSE, FALSE)',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(
          value: '=AND(NULL, TRUE)',
          formula: '=AND(NULL, TRUE)',
        ),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=OR(NULL, FALSE)',
          formula: '=OR(NULL, FALSE)',
        ),
        const FortuneCellCoord(18, 2): const FortuneCell(
          value: '=NOT(NULL)',
          formula: '=NOT(NULL)',
        ),
        const FortuneCellCoord(18, 3): const FortuneCell(
          value: '=IF(NULL, "yes", "no")',
          formula: '=IF(NULL, "yes", "no")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, 'yes');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, 'foo');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, 'baz');
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, 'foo');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, 'bar');
    expect(sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(18, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(18, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(18, 3)]?.renderedText, 'no');
  });

  test('formula engine evaluates powers and percentages', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '200'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=2^3',
          formula: '=2^3',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=POWER(3, 2)',
          formula: '=POWER(3, 2)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=A1*10%',
          formula: '=A1*10%',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=50%%',
          formula: '=50%%',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=POWER(0, -1)',
          formula: '=POWER(0, -1)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=0^-1',
          formula: '=0^-1',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=POWER(-1, 0.5)',
          formula: '=POWER(-1, 0.5)',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=(-1)^0.5',
          formula: '=(-1)^0.5',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=POWER(0, 0)',
          formula: '=POWER(0, 0)',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=-(50%)',
          formula: '=-(50%)',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value: '=-100%',
          formula: '=-100%',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value: '=--100%',
          formula: '=--100%',
        ),
        const FortuneCellCoord(0, 13): const FortuneCell(
          value: '=-(A1%*10%)',
          formula: '=-(A1%*10%)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=POWER()',
          formula: '=POWER()',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=POWER("value")',
          formula: '=POWER("value")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=POWER(2)',
          formula: '=POWER(2)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=POWER(2, 4)',
          formula: '=POWER(2, 4)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=POWER(2, 8)',
          formula: '=POWER(2, 8)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=2^3^2',
          formula: '=2^3^2',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=(2^3)^2',
          formula: '=(2^3)^2',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=POWER(2, 3)%',
          formula: '=POWER(2, 3)%',
        ),
        const FortuneCellCoord(1, 8): const FortuneCell(
          value: '=(2+3)%',
          formula: '=(2+3)%',
        ),
        const FortuneCellCoord(1, 9): const FortuneCell(
          value: '=TRUE%',
          formula: '=TRUE%',
        ),
        const FortuneCellCoord(1, 10): const FortuneCell(
          value: '=FALSE%',
          formula: '=FALSE%',
        ),
        const FortuneCellCoord(1, 11): const FortuneCell(
          value: '=NULL%',
          formula: '=NULL%',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '0.005');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '-0.5');
    expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 13)]?.renderedText, '-0.2');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '16');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '256');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '512');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '0.08');
    expect(sheet.cells[const FortuneCellCoord(1, 8)]?.renderedText, '0.05');
    expect(sheet.cells[const FortuneCellCoord(1, 9)]?.renderedText, '0.01');
    expect(sheet.cells[const FortuneCellCoord(1, 10)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 11)]?.renderedText, '0');
  });

  test('formula engine evaluates rounding helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ABS(-12.5)',
          formula: '=ABS(-12.5)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ROUND(12.345, 2)',
          formula: '=ROUND(12.345, 2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ROUND(1234, -2)',
          formula: '=ROUND(1234, -2)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=ROUNDUP(-1.21, 1)',
          formula: '=ROUNDUP(-1.21, 1)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=ROUNDDOWN(-1.29, 1)',
          formula: '=ROUNDDOWN(-1.29, 1)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=TRUNC(12.987, 2)',
          formula: '=TRUNC(12.987, 2)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=TRUNC(-1234, -2)',
          formula: '=TRUNC(-1234, -2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=EVEN(3.1)',
          formula: '=EVEN(3.1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=EVEN(-3.1)',
          formula: '=EVEN(-3.1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ODD(2)',
          formula: '=ODD(2)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ODD(-2)',
          formula: '=ODD(-2)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=CEILING(4.3, 2)',
          formula: '=CEILING(4.3, 2)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=FLOOR(4.3, 2)',
          formula: '=FLOOR(4.3, 2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=CEILING(-4.3, -2)',
          formula: '=CEILING(-4.3, -2)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=FLOOR(-4.3, -2)',
          formula: '=FLOOR(-4.3, -2)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=CEILING(4.3, -2)',
          formula: '=CEILING(4.3, -2)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=CEILING.MATH(-4.3, 2)',
          formula: '=CEILING.MATH(-4.3, 2)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=CEILING.MATH(-4.3, 2, 1)',
          formula: '=CEILING.MATH(-4.3, 2, 1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=FLOOR.MATH(-4.3, 2)',
          formula: '=FLOOR.MATH(-4.3, 2)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=FLOOR.MATH(-4.3, 2, 1)',
          formula: '=FLOOR.MATH(-4.3, 2, 1)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=CEILING.PRECISE(-4.3, 2)',
          formula: '=CEILING.PRECISE(-4.3, 2)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=FLOOR.PRECISE(-4.3, 2)',
          formula: '=FLOOR.PRECISE(-4.3, 2)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ISO.CEILING(4.3, 2)',
          formula: '=ISO.CEILING(4.3, 2)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=ROUND(12.345, 400)',
          formula: '=ROUND(12.345, 400)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=ROUND(1234, -400)',
          formula: '=ROUND(1234, -400)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=ROUNDDOWN(12.345, 400)',
          formula: '=ROUNDDOWN(12.345, 400)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=TRUNC(-1234, -400)',
          formula: '=TRUNC(-1234, -400)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=ROUNDUP(1234, -400)',
          formula: '=ROUNDUP(1234, -400)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=ROUNDUP(0, -400)',
          formula: '=ROUNDUP(0, -400)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=CEILING(10^308, 9*10^307)',
          formula: '=CEILING(10^308, 9*10^307)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=CEILING.MATH(10^308, 9*10^307)',
          formula: '=CEILING.MATH(10^308, 9*10^307)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=FLOOR.MATH(-(10^308), 9*10^307)',
          formula: '=FLOOR.MATH(-(10^308), 9*10^307)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=CEILING.PRECISE(10^308, 9*10^307)',
          formula: '=CEILING.PRECISE(10^308, 9*10^307)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=FLOOR.PRECISE(-(10^308), 9*10^307)',
          formula: '=FLOOR.PRECISE(-(10^308), 9*10^307)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=ISO.CEILING(10^308, 9*10^307)',
          formula: '=ISO.CEILING(10^308, 9*10^307)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=FLOOR(4.3, -2)',
          formula: '=FLOOR(4.3, -2)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=UNARY_PERCENT(100)',
          formula: '=UNARY_PERCENT(100)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=UNARY_PERCENT(12.5)',
          formula: '=UNARY_PERCENT(12.5)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=CEILING(-4.3)',
          formula: '=CEILING(-4.3)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=CEILING(7, 2, 8)',
          formula: '=CEILING(7, 2, 8)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=CEILING(-1.234, 0.1, "value")',
          formula: '=CEILING(-1.234, 0.1, "value")',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=FLOOR(6.998, -1.99)',
          formula: '=FLOOR(6.998, -1.99)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=FLOOR(-1, -10)',
          formula: '=FLOOR(-1, -10)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=ABS()',
          formula: '=ABS()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=ABS(-8)',
          formula: '=ABS(-8)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=ABS(-8.89)',
          formula: '=ABS(-8.89)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=ABS(8)',
          formula: '=ABS(8)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=CEILING()',
          formula: '=CEILING()',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=CEILING("value")',
          formula: '=CEILING("value")',
        ),
        const FortuneCellCoord(7, 6): const FortuneCell(
          value: '=CEILING(7.2)',
          formula: '=CEILING(7.2)',
        ),
        const FortuneCellCoord(7, 7): const FortuneCell(
          value: '=CEILING(-1.234, 0.1)',
          formula: '=CEILING(-1.234, 0.1)',
        ),
        const FortuneCellCoord(7, 8): const FortuneCell(
          value: '=EVEN()',
          formula: '=EVEN()',
        ),
        const FortuneCellCoord(7, 9): const FortuneCell(
          value: '=EVEN("value")',
          formula: '=EVEN("value")',
        ),
        const FortuneCellCoord(7, 10): const FortuneCell(
          value: '=EVEN(1)',
          formula: '=EVEN(1)',
        ),
        const FortuneCellCoord(7, 11): const FortuneCell(
          value: '=EVEN(-33)',
          formula: '=EVEN(-33)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=FLOOR()',
          formula: '=FLOOR()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=FLOOR("value")',
          formula: '=FLOOR("value")',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=FLOOR(1)',
          formula: '=FLOOR(1)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=FLOOR(3.33, 1.11)',
          formula: '=FLOOR(3.33, 1.11)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=ODD()',
          formula: '=ODD()',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=ODD("value")',
          formula: '=ODD("value")',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=ODD(-34)',
          formula: '=ODD(-34)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=ODD(11)',
          formula: '=ODD(11)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=ROUND()',
          formula: '=ROUND()',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=ROUND("value")',
          formula: '=ROUND("value")',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=ROUND(1)',
          formula: '=ROUND(1)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=ROUND(1.2234, 0)',
          formula: '=ROUND(1.2234, 0)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=ROUND(1.2234, 2)',
          formula: '=ROUND(1.2234, 2)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=ROUND(1.2234578, 4)',
          formula: '=ROUND(1.2234578, 4)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=ROUND(2345.2234578, -1)',
          formula: '=ROUND(2345.2234578, -1)',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=ROUND(2345.2234578, -2)',
          formula: '=ROUND(2345.2234578, -2)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=ROUNDDOWN()',
          formula: '=ROUNDDOWN()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=ROUNDDOWN("value")',
          formula: '=ROUNDDOWN("value")',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=ROUNDDOWN(1)',
          formula: '=ROUNDDOWN(1)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=ROUNDDOWN(1.2234, 0)',
          formula: '=ROUNDDOWN(1.2234, 0)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=ROUNDDOWN(1.2234, 2)',
          formula: '=ROUNDDOWN(1.2234, 2)',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=ROUNDDOWN(1.2234578, 4)',
          formula: '=ROUNDDOWN(1.2234578, 4)',
        ),
        const FortuneCellCoord(10, 6): const FortuneCell(
          value: '=ROUNDDOWN(2345.2234578, -1)',
          formula: '=ROUNDDOWN(2345.2234578, -1)',
        ),
        const FortuneCellCoord(10, 7): const FortuneCell(
          value: '=ROUNDDOWN(2345.2234578, -2)',
          formula: '=ROUNDDOWN(2345.2234578, -2)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=ROUNDUP()',
          formula: '=ROUNDUP()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=ROUNDUP("value")',
          formula: '=ROUNDUP("value")',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=ROUNDUP(1)',
          formula: '=ROUNDUP(1)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=ROUNDUP(1.2234, 0)',
          formula: '=ROUNDUP(1.2234, 0)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=ROUNDUP(1.2234, 2)',
          formula: '=ROUNDUP(1.2234, 2)',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=ROUNDUP(1.2234578, 4)',
          formula: '=ROUNDUP(1.2234578, 4)',
        ),
        const FortuneCellCoord(11, 6): const FortuneCell(
          value: '=ROUNDUP(2345.2234578, -1)',
          formula: '=ROUNDUP(2345.2234578, -1)',
        ),
        const FortuneCellCoord(11, 7): const FortuneCell(
          value: '=ROUNDUP(2345.2234578, -2)',
          formula: '=ROUNDUP(2345.2234578, -2)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=TRUNC()',
          formula: '=TRUNC()',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=TRUNC("value")',
          formula: '=TRUNC("value")',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=TRUNC(1)',
          formula: '=TRUNC(1)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=TRUNC(1.99988877)',
          formula: '=TRUNC(1.99988877)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=TRUNC(-221.99988877)',
          formula: '=TRUNC(-221.99988877)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=TRUNC(0.99988877)',
          formula: '=TRUNC(0.99988877)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '12.5');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '12.35');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1200');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '-1.3');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '-1.2');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '12.98');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '-1200');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '-3');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '-6');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '-6');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '-6');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '-6');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '-6');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '12.345');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '12.345');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '0.125');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '-10');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '8.89');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 6)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(7, 7)]?.renderedText, '-1.2');
    expect(sheet.cells[const FortuneCellCoord(7, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 10)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(7, 11)]?.renderedText, '-34');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '-35');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '1.22');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '1.2235');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '2350');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '2300');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '1.22');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '1.2234');
    expect(sheet.cells[const FortuneCellCoord(10, 6)]?.renderedText, '2340');
    expect(sheet.cells[const FortuneCellCoord(10, 7)]?.renderedText, '2300');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '1.23');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '1.2235');
    expect(sheet.cells[const FortuneCellCoord(11, 6)]?.renderedText, '2350');
    expect(sheet.cells[const FortuneCellCoord(11, 7)]?.renderedText, '2400');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, '-221');
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, '0');
  });

  test('formula engine surfaces square sum overflow as numeric errors', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=SUMSQ(10^154, 10^154)',
          formula: '=SUMSQ(10^154, 10^154)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=SUMXMY2(10^154, -(10^154))',
          formula: '=SUMXMY2(10^154, -(10^154))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=SUMX2MY2(10^155, 0)',
          formula: '=SUMX2MY2(10^155, 0)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SUMX2PY2(10^154, 10^154)',
          formula: '=SUMX2PY2(10^154, 10^154)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=PRODUCT(10^200, 10^200)',
          formula: '=PRODUCT(10^200, 10^200)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=SUMPRODUCT(10^200, 10^200)',
          formula: '=SUMPRODUCT(10^200, 10^200)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=SUM(10^308, 10^308)',
          formula: '=SUM(10^308, 10^308)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=AVERAGE(10^308, 10^308)/(10^308)',
          formula: '=AVERAGE(10^308, 10^308)/(10^308)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=AVERAGE(10^308, -(10^308))',
          formula: '=AVERAGE(10^308, -(10^308))',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=AVERAGEA(10^308, 10^308)/(10^308)',
          formula: '=AVERAGEA(10^308, 10^308)/(10^308)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=AVERAGEIF(A3:A4, 1, B3:B4)/(10^308)',
          formula: '=AVERAGEIF(A3:A4, 1, B3:B4)/(10^308)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=AVERAGEIFS(B3:B4, A3:A4, 1)/(10^308)',
          formula: '=AVERAGEIFS(B3:B4, A3:A4, 1)/(10^308)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=VAR.P(10^308, 10^308)',
          formula: '=VAR.P(10^308, 10^308)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=STDEV.P(10^308, 10^308)',
          formula: '=STDEV.P(10^308, 10^308)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=DEVSQ(10^308, 10^308)',
          formula: '=DEVSQ(10^308, 10^308)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=AVEDEV(10^308, 10^308)',
          formula: '=AVEDEV(10^308, 10^308)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=TRIMMEAN({10^308,10^308}, 0)/(10^308)',
          formula: '=TRIMMEAN({10^308,10^308}, 0)/(10^308)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '1');
  });

  test('formula engine surfaces combinatorial overflow as numeric errors', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=FACT(200)',
          formula: '=FACT(200)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=FACTDOUBLE(400)',
          formula: '=FACTDOUBLE(400)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=COMBIN(2000, 1000)',
          formula: '=COMBIN(2000, 1000)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=COMBINA(2000, 1000)',
          formula: '=COMBINA(2000, 1000)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=PERMUT(200, 200)',
          formula: '=PERMUT(200, 200)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=MULTINOMIAL(200, 200)',
          formula: '=MULTINOMIAL(200, 200)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    for (var column = 0; column <= 5; column += 1) {
      expect(sheet.cells[FortuneCellCoord(0, column)]?.renderedText, '#NUM!');
    }
  });

  test('formula engine evaluates additional numeric helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'SERIESSUM_ARR': [
            1,
            -0.5,
            0.041666666666666664,
            -0.001388888888888889,
          ],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INT(12.9)',
          formula: '=INT(12.9)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INT(-1.2)',
          formula: '=INT(-1.2)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MOD(10, 3)',
          formula: '=MOD(10, 3)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=MOD(-3, 2)',
          formula: '=MOD(-3, 2)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=SQRT(81)',
          formula: '=SQRT(81)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=SQRT(-1)',
          formula: '=SQRT(-1)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=INT()',
          formula: '=INT()',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=INT("value")',
          formula: '=INT("value")',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=INT(1)',
          formula: '=INT(1)',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=INT(1.1)',
          formula: '=INT(1.1)',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=INT(1.5)',
          formula: '=INT(1.5)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=PRODUCT(A2:C2, 5)',
          formula: '=PRODUCT(A2:C2, 5)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=SIGN(-42)',
          formula: '=SIGN(-42)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=ROUND(EXP(1), 6)',
          formula: '=ROUND(EXP(1), 6)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ROUND(LN(EXP(1)), 6)',
          formula: '=ROUND(LN(EXP(1)), 6)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=LOG10(1000)',
          formula: '=LOG10(1000)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=LN(0)',
          formula: '=LN(0)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=EXP(1000)',
          formula: '=EXP(1000)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=EXP()',
          formula: '=EXP()',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=EXP("1")',
          formula: '=EXP("1")',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=EXP(1, 1)',
          formula: '=EXP(1, 1)',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=LOG(1)',
          formula: '=LOG(1)',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=LOG(10, 10)',
          formula: '=LOG(10, 10)',
        ),
        const FortuneCellCoord(2, 9): const FortuneCell(
          value: '=EXP(MY_VAR)',
          formula: '=EXP(MY_VAR)',
        ),
        const FortuneCellCoord(2, 10): const FortuneCell(
          value: '=EXP(1)',
          formula: '=EXP(1)',
        ),
        const FortuneCellCoord(2, 11): const FortuneCell(
          value: '=LN()',
          formula: '=LN()',
        ),
        const FortuneCellCoord(2, 12): const FortuneCell(
          value: '=LN("value")',
          formula: '=LN("value")',
        ),
        const FortuneCellCoord(2, 13): const FortuneCell(
          value: '=LN(1)',
          formula: '=LN(1)',
        ),
        const FortuneCellCoord(2, 14): const FortuneCell(
          value: '=LN(EXP(1))',
          formula: '=LN(EXP(1))',
        ),
        const FortuneCellCoord(2, 15): const FortuneCell(
          value: '=LOG()',
          formula: '=LOG()',
        ),
        const FortuneCellCoord(2, 16): const FortuneCell(
          value: '=LOG("value")',
          formula: '=LOG("value")',
        ),
        const FortuneCellCoord(2, 17): const FortuneCell(
          value: '=LOG10()',
          formula: '=LOG10()',
        ),
        const FortuneCellCoord(2, 18): const FortuneCell(
          value: '=LOG10("value")',
          formula: '=LOG10("value")',
        ),
        const FortuneCellCoord(2, 19): const FortuneCell(
          value: '=LOG10(10)',
          formula: '=LOG10(10)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '9'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '1'),
        const FortuneCellCoord(3, 2): const FortuneCell(value: '5'),
        const FortuneCellCoord(3, 3): const FortuneCell(value: '7'),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=MEDIAN(A4:D4)',
          formula: '=MEDIAN(A4:D4)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=LARGE(A4:D4, 2)',
          formula: '=LARGE(A4:D4, 2)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=SMALL(A4:D4, 2)',
          formula: '=SMALL(A4:D4, 2)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=LARGE(A4:D4, 0)',
          formula: '=LARGE(A4:D4, 0)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=ROUND(PI(), 6)',
          formula: '=ROUND(PI(), 6)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=ROUND(SIN(PI()/2), 6)',
          formula: '=ROUND(SIN(PI()/2), 6)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=ROUND(COS(0), 6)',
          formula: '=ROUND(COS(0), 6)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=ROUND(TAN(0), 6)',
          formula: '=ROUND(TAN(0), 6)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=ROUND(DEGREES(PI()), 6)',
          formula: '=ROUND(DEGREES(PI()), 6)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=ROUND(RADIANS(180), 6)',
          formula: '=ROUND(RADIANS(180), 6)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=ROUND(DEGREES(ASIN(1)), 6)',
          formula: '=ROUND(DEGREES(ASIN(1)), 6)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=ROUND(DEGREES(ACOS(0)), 6)',
          formula: '=ROUND(DEGREES(ACOS(0)), 6)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=ROUND(DEGREES(ATAN(1)), 6)',
          formula: '=ROUND(DEGREES(ATAN(1)), 6)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=ROUND(SQRTPI(2), 6)',
          formula: '=ROUND(SQRTPI(2), 6)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=LOG(8, 2)',
          formula: '=LOG(8, 2)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=LOG(100, 10)',
          formula: '=LOG(100, 10)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=ASIN(2)',
          formula: '=ASIN(2)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=LOG(8, 1)',
          formula: '=LOG(8, 1)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=ROUND(VAR(A4:D4), 6)',
          formula: '=ROUND(VAR(A4:D4), 6)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=VARP(A4:D4)',
          formula: '=VARP(A4:D4)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=ROUND(STDEV(A4:D4), 6)',
          formula: '=ROUND(STDEV(A4:D4), 6)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=ROUND(STDEVP(A4:D4), 6)',
          formula: '=ROUND(STDEVP(A4:D4), 6)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=ROUND(VAR.S(A4:D4), 6)',
          formula: '=ROUND(VAR.S(A4:D4), 6)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=VAR.P(A4:D4)',
          formula: '=VAR.P(A4:D4)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=STDEV(A1)',
          formula: '=STDEV(A1)',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=DEVSQ(A4:D4)',
          formula: '=DEVSQ(A4:D4)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=AVEDEV(A4:D4)',
          formula: '=AVEDEV(A4:D4)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=SUMSQ(A4:D4)',
          formula: '=SUMSQ(A4:D4)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=ROUND(GEOMEAN(A4:D4), 6)',
          formula: '=ROUND(GEOMEAN(A4:D4), 6)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=ROUND(HARMEAN(A4:D4), 6)',
          formula: '=ROUND(HARMEAN(A4:D4), 6)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=GEOMEAN(-1, 2)',
          formula: '=GEOMEAN(-1, 2)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=HARMEAN(0, 2)',
          formula: '=HARMEAN(0, 2)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=SUMSQ()',
          formula: '=SUMSQ()',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=SUMSQ("value")',
          formula: '=SUMSQ("value")',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=FACT(5)',
          formula: '=FACT(5)',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=FACTDOUBLE(7)',
          formula: '=FACTDOUBLE(7)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=COMBIN(5, 2)',
          formula: '=COMBIN(5, 2)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=PERMUT(5, 2)',
          formula: '=PERMUT(5, 2)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=GCD(24, 36, 60)',
          formula: '=GCD(24, 36, 60)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=LCM(4, 6, 10)',
          formula: '=LCM(4, 6, 10)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=GCD()',
          formula: '=GCD()',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=LCM()',
          formula: '=LCM()',
        ),
        const FortuneCellCoord(9, 8): const FortuneCell(
          value: '=FACT()',
          formula: '=FACT()',
        ),
        const FortuneCellCoord(9, 9): const FortuneCell(
          value: '=FACT("value")',
          formula: '=FACT("value")',
        ),
        const FortuneCellCoord(9, 10): const FortuneCell(
          value: '=FACT(1)',
          formula: '=FACT(1)',
        ),
        const FortuneCellCoord(9, 11): const FortuneCell(
          value: '=FACT(3)',
          formula: '=FACT(3)',
        ),
        const FortuneCellCoord(9, 12): const FortuneCell(
          value: '=FACT(3.33)',
          formula: '=FACT(3.33)',
        ),
        const FortuneCellCoord(9, 13): const FortuneCell(
          value: '=FACT(6)',
          formula: '=FACT(6)',
        ),
        const FortuneCellCoord(9, 14): const FortuneCell(
          value: '=FACT(6.998)',
          formula: '=FACT(6.998)',
        ),
        const FortuneCellCoord(9, 15): const FortuneCell(
          value: '=FACT(10)',
          formula: '=FACT(10)',
        ),
        const FortuneCellCoord(9, 16): const FortuneCell(
          value: '=GCD("value")',
          formula: '=GCD("value")',
        ),
        const FortuneCellCoord(9, 17): const FortuneCell(
          value: '=GCD(1)',
          formula: '=GCD(1)',
        ),
        const FortuneCellCoord(9, 18): const FortuneCell(
          value: '=GCD(2, 36)',
          formula: '=GCD(2, 36)',
        ),
        const FortuneCellCoord(9, 19): const FortuneCell(
          value: '=GCD(200, -12, 22, 9)',
          formula: '=GCD(200, -12, 22, 9)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=QUOTIENT(17, 5)',
          formula: '=QUOTIENT(17, 5)',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=QUOTIENT(-17, 5)',
          formula: '=QUOTIENT(-17, 5)',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=COMBIN(2, 5)',
          formula: '=COMBIN(2, 5)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=FACT(-1)',
          formula: '=FACT(-1)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=LCM(0, 5)',
          formula: '=LCM(0, 5)',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=QUOTIENT(1, 0)',
          formula: '=QUOTIENT(1, 0)',
        ),
        const FortuneCellCoord(10, 6): const FortuneCell(
          value: '=FACTDOUBLE()',
          formula: '=FACTDOUBLE()',
        ),
        const FortuneCellCoord(10, 7): const FortuneCell(
          value: '=FACTDOUBLE("value")',
          formula: '=FACTDOUBLE("value")',
        ),
        const FortuneCellCoord(10, 8): const FortuneCell(
          value: '=FACTDOUBLE(1)',
          formula: '=FACTDOUBLE(1)',
        ),
        const FortuneCellCoord(10, 9): const FortuneCell(
          value: '=FACTDOUBLE(3)',
          formula: '=FACTDOUBLE(3)',
        ),
        const FortuneCellCoord(10, 10): const FortuneCell(
          value: '=FACTDOUBLE(3.33)',
          formula: '=FACTDOUBLE(3.33)',
        ),
        const FortuneCellCoord(10, 11): const FortuneCell(
          value: '=FACTDOUBLE(6)',
          formula: '=FACTDOUBLE(6)',
        ),
        const FortuneCellCoord(10, 12): const FortuneCell(
          value: '=FACTDOUBLE(6.998)',
          formula: '=FACTDOUBLE(6.998)',
        ),
        const FortuneCellCoord(10, 13): const FortuneCell(
          value: '=FACTDOUBLE(10)',
          formula: '=FACTDOUBLE(10)',
        ),
        const FortuneCellCoord(10, 14): const FortuneCell(
          value: '=LCM("value")',
          formula: '=LCM("value")',
        ),
        const FortuneCellCoord(10, 15): const FortuneCell(
          value: '=LCM(1)',
          formula: '=LCM(1)',
        ),
        const FortuneCellCoord(10, 16): const FortuneCell(
          value: '=LCM(1.1, 2)',
          formula: '=LCM(1.1, 2)',
        ),
        const FortuneCellCoord(10, 17): const FortuneCell(
          value: '=LCM(3, 8)',
          formula: '=LCM(3, 8)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=ISEVEN(4.9)',
          formula: '=ISEVEN(4.9)',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=ISODD(-3.2)',
          formula: '=ISODD(-3.2)',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=ISEVEN(5)',
          formula: '=ISEVEN(5)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=MULTINOMIAL(2, 3, 4)',
          formula: '=MULTINOMIAL(2, 3, 4)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=MULTINOMIAL(1, -1)',
          formula: '=MULTINOMIAL(1, -1)',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=SERIESSUM(2, 0, 1, 1, 2, 3)',
          formula: '=SERIESSUM(2, 0, 1, 1, 2, 3)',
        ),
        const FortuneCellCoord(11, 6): const FortuneCell(
          value: '=MULTINOMIAL()',
          formula: '=MULTINOMIAL()',
        ),
        const FortuneCellCoord(11, 7): const FortuneCell(
          value: '=MULTINOMIAL("value")',
          formula: '=MULTINOMIAL("value")',
        ),
        const FortuneCellCoord(11, 8): const FortuneCell(
          value: '=MULTINOMIAL(1)',
          formula: '=MULTINOMIAL(1)',
        ),
        const FortuneCellCoord(11, 9): const FortuneCell(
          value: '=MULTINOMIAL(1, 3, 4)',
          formula: '=MULTINOMIAL(1, 3, 4)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=ROUND(SKEW(A4:D4), 6)',
          formula: '=ROUND(SKEW(A4:D4), 6)',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=ROUND(KURT(A4:D4), 6)',
          formula: '=ROUND(KURT(A4:D4), 6)',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=SKEW(1, 2)',
          formula: '=SKEW(1, 2)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=KURT(1, 2, 3)',
          formula: '=KURT(1, 2, 3)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=MODE_SNGL(1, 2, 2, 3, 3, 3)',
          formula: '=MODE_SNGL(1, 2, 2, 3, 3, 3)',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=MODE_SNGL(1, 2, 3)',
          formula: '=MODE_SNGL(1, 2, 3)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=PERCENTILE_INC(A4:D4, 0.25)',
          formula: '=PERCENTILE_INC(A4:D4, 0.25)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=PERCENTILE_EXC(A4:D4, 0.4)',
          formula: '=PERCENTILE_EXC(A4:D4, 0.4)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=QUARTILE_INC(A4:D4, 1)',
          formula: '=QUARTILE_INC(A4:D4, 1)',
        ),
        const FortuneCellCoord(13, 5): const FortuneCell(
          value: '=QUARTILE_EXC(A4:D4, 2)',
          formula: '=QUARTILE_EXC(A4:D4, 2)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=PERCENTILE_INC(A4:D4, 2)',
          formula: '=PERCENTILE_INC(A4:D4, 2)',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=QUARTILE_EXC(A4:D4, 0)',
          formula: '=QUARTILE_EXC(A4:D4, 0)',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=SUMPRODUCT(A2:C2, A4:C4)',
          formula: '=SUMPRODUCT(A2:C2, A4:C4)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=RANK(7, A4:D4)',
          formula: '=RANK(7, A4:D4)',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=RANK.EQ(5, A4:D4, 1)',
          formula: '=RANK.EQ(5, A4:D4, 1)',
        ),
        const FortuneCellCoord(14, 5): const FortuneCell(
          value: '=RANK.AVG(5, A4:D4)',
          formula: '=RANK.AVG(5, A4:D4)',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(15, 1): const FortuneCell(value: 'x'),
        const FortuneCellCoord(15, 2): const FortuneCell(value: '4'),
        const FortuneCellCoord(16, 0): const FortuneCell(value: '10'),
        const FortuneCellCoord(16, 1): const FortuneCell(value: '20'),
        const FortuneCellCoord(16, 2): const FortuneCell(value: '30'),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=SUMPRODUCT(A16:C16, A17:C17)',
          formula: '=SUMPRODUCT(A16:C16, A17:C17)',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=SUMPRODUCT(A16:C16, A17:B17)',
          formula: '=SUMPRODUCT(A16:C16, A17:B17)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=SUMXMY2(A16:C16, A17:C17)',
          formula: '=SUMXMY2(A16:C16, A17:C17)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=SUMX2MY2(A16:C16, A17:C17)',
          formula: '=SUMX2MY2(A16:C16, A17:C17)',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=SUMX2PY2(A16:C16, A17:C17)',
          formula: '=SUMX2PY2(A16:C16, A17:C17)',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=SUMXMY2(A16:C16, A17:B17)',
          formula: '=SUMXMY2(A16:C16, A17:B17)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=MOD(1, 0)',
          formula: '=MOD(1, 0)',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(value: '5'),
        const FortuneCellCoord(17, 2): const FortuneCell(value: '5'),
        const FortuneCellCoord(17, 3): const FortuneCell(value: '1'),
        const FortuneCellCoord(17, 4): const FortuneCell(
          value: '=RANK.AVG(5, B18:D18)',
          formula: '=RANK.AVG(5, B18:D18)',
        ),
        const FortuneCellCoord(17, 5): const FortuneCell(
          value: '=RANK(8, A4:D4)',
          formula: '=RANK(8, A4:D4)',
        ),
        const FortuneCellCoord(17, 6): const FortuneCell(
          value: '=MOD()',
          formula: '=MOD()',
        ),
        const FortuneCellCoord(17, 7): const FortuneCell(
          value: '=MOD("value")',
          formula: '=MOD("value")',
        ),
        const FortuneCellCoord(17, 8): const FortuneCell(
          value: '=MOD(1)',
          formula: '=MOD(1)',
        ),
        const FortuneCellCoord(17, 9): const FortuneCell(
          value: '=MOD(1, 2)',
          formula: '=MOD(1, 2)',
        ),
        const FortuneCellCoord(17, 10): const FortuneCell(
          value: '=MOD(3, 2)',
          formula: '=MOD(3, 2)',
        ),
        const FortuneCellCoord(17, 11): const FortuneCell(
          value: '=MOD(4, 0)',
          formula: '=MOD(4, 0)',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(
          value: '=COMBINA(4, 3)',
          formula: '=COMBINA(4, 3)',
        ),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=PERMUTATIONA(4, 3)',
          formula: '=PERMUTATIONA(4, 3)',
        ),
        const FortuneCellCoord(18, 2): const FortuneCell(
          value: '=COMBINA(0, 2)',
          formula: '=COMBINA(0, 2)',
        ),
        const FortuneCellCoord(18, 3): const FortuneCell(
          value: '=PERMUTATIONA(-1, 2)',
          formula: '=PERMUTATIONA(-1, 2)',
        ),
        const FortuneCellCoord(18, 4): const FortuneCell(
          value: '=COMBIN()',
          formula: '=COMBIN()',
        ),
        const FortuneCellCoord(18, 5): const FortuneCell(
          value: '=COMBIN("value")',
          formula: '=COMBIN("value")',
        ),
        const FortuneCellCoord(18, 6): const FortuneCell(
          value: '=COMBIN(1)',
          formula: '=COMBIN(1)',
        ),
        const FortuneCellCoord(18, 7): const FortuneCell(
          value: '=COMBIN(0, 0)',
          formula: '=COMBIN(0, 0)',
        ),
        const FortuneCellCoord(18, 8): const FortuneCell(
          value: '=COMBIN(1, 0)',
          formula: '=COMBIN(1, 0)',
        ),
        const FortuneCellCoord(18, 9): const FortuneCell(
          value: '=COMBIN(3, 1)',
          formula: '=COMBIN(3, 1)',
        ),
        const FortuneCellCoord(18, 10): const FortuneCell(
          value: '=COMBIN(3, 3)',
          formula: '=COMBIN(3, 3)',
        ),
        const FortuneCellCoord(18, 11): const FortuneCell(
          value: '=PERMUT(0, 0)',
          formula: '=PERMUT(0, 0)',
        ),
        const FortuneCellCoord(18, 12): const FortuneCell(
          value: '=PERMUT(1, 0)',
          formula: '=PERMUT(1, 0)',
        ),
        const FortuneCellCoord(18, 13): const FortuneCell(
          value: '=PERMUT(3, 3)',
          formula: '=PERMUT(3, 3)',
        ),
        const FortuneCellCoord(19, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(19, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(19, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(19, 3): const FortuneCell(
          value: '=COMBINA()',
          formula: '=COMBINA()',
        ),
        const FortuneCellCoord(19, 4): const FortuneCell(
          value: '=COMBINA("value")',
          formula: '=COMBINA("value")',
        ),
        const FortuneCellCoord(19, 5): const FortuneCell(
          value: '=COMBINA(1)',
          formula: '=COMBINA(1)',
        ),
        const FortuneCellCoord(19, 6): const FortuneCell(
          value: '=COMBINA(0, 0)',
          formula: '=COMBINA(0, 0)',
        ),
        const FortuneCellCoord(19, 7): const FortuneCell(
          value: '=COMBINA(1, 0)',
          formula: '=COMBINA(1, 0)',
        ),
        const FortuneCellCoord(19, 8): const FortuneCell(
          value: '=COMBINA(3, 1)',
          formula: '=COMBINA(3, 1)',
        ),
        const FortuneCellCoord(19, 9): const FortuneCell(
          value: '=COMBINA(3, 3)',
          formula: '=COMBINA(3, 3)',
        ),
        const FortuneCellCoord(19, 10): const FortuneCell(
          value: '=PERMUTATIONA(0, 0)',
          formula: '=PERMUTATIONA(0, 0)',
        ),
        const FortuneCellCoord(19, 11): const FortuneCell(
          value: '=PERMUTATIONA(1, 0)',
          formula: '=PERMUTATIONA(1, 0)',
        ),
        const FortuneCellCoord(20, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(20, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(20, 2): const FortuneCell(value: '5'),
        const FortuneCellCoord(20, 3): const FortuneCell(
          value: '=ROUND(CORREL(A20:C20, A21:C21), 6)',
          formula: '=ROUND(CORREL(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(20, 4): const FortuneCell(
          value: '=ROUND(PEARSON(A20:C20, A21:C21), 6)',
          formula: '=ROUND(PEARSON(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(20, 5): const FortuneCell(
          value: '=ROUND(RSQ(A20:C20, A21:C21), 6)',
          formula: '=ROUND(RSQ(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(20, 9): const FortuneCell(value: '10'),
        const FortuneCellCoord(20, 10): const FortuneCell(value: 'dewdewd'),
        const FortuneCellCoord(20, 11): const FortuneCell(value: '1'),
        const FortuneCellCoord(21, 0): const FortuneCell(
          value: '=COVARIANCE.P(A20:C20, A21:C21)',
          formula: '=COVARIANCE.P(A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(21, 1): const FortuneCell(
          value: '=COVARIANCE.S(A20:C20, A21:C21)',
          formula: '=COVARIANCE.S(A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(21, 2): const FortuneCell(
          value: '=COVAR(A20:C20, A21:C21)',
          formula: '=COVAR(A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(21, 3): const FortuneCell(
          value: '=CORREL(A20:C20, A21:B21)',
          formula: '=CORREL(A20:C20, A21:B21)',
        ),
        const FortuneCellCoord(21, 4): const FortuneCell(
          value: '=CORREL(A20:C20, 1)',
          formula: '=CORREL(A20:C20, 1)',
        ),
        const FortuneCellCoord(21, 5): const FortuneCell(
          value: '=ROUND(SLOPE(A20:C20, A21:C21), 6)',
          formula: '=ROUND(SLOPE(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(21, 6): const FortuneCell(
          value: '=CORREL()',
          formula: '=CORREL()',
        ),
        const FortuneCellCoord(21, 8): const FortuneCell(
          value: '=PEARSON(A20:C20, J21:L21)',
          formula: '=PEARSON(A20:C20, J21:L21)',
        ),
        const FortuneCellCoord(22, 0): const FortuneCell(
          value: '=ROUND(INTERCEPT(A20:C20, A21:C21), 6)',
          formula: '=ROUND(INTERCEPT(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(22, 1): const FortuneCell(
          value: '=ROUND(STEYX(A20:C20, A21:C21), 6)',
          formula: '=ROUND(STEYX(A20:C20, A21:C21), 6)',
        ),
        const FortuneCellCoord(22, 2): const FortuneCell(
          value: '=SLOPE(A20:C20, A21:B21)',
          formula: '=SLOPE(A20:C20, A21:B21)',
        ),
        const FortuneCellCoord(23, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(23, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(23, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(24, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(24, 1): const FortuneCell(value: '1'),
        const FortuneCellCoord(24, 2): const FortuneCell(value: '1'),
        const FortuneCellCoord(22, 3): const FortuneCell(
          value: '=SLOPE(A24:C24, A25:C25)',
          formula: '=SLOPE(A24:C24, A25:C25)',
        ),
        const FortuneCellCoord(22, 4): const FortuneCell(
          value: '=STEYX(A20:B20, A21:B21)',
          formula: '=STEYX(A20:B20, A21:B21)',
        ),
        const FortuneCellCoord(22, 5): const FortuneCell(
          value: '=FORECAST(6, A20:C20, A21:C21)',
          formula: '=FORECAST(6, A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(23, 3): const FortuneCell(
          value: '=FORECAST.LINEAR(6, A20:C20, A21:C21)',
          formula: '=FORECAST.LINEAR(6, A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(23, 4): const FortuneCell(
          value: '=FORECAST(6, A20:C20, A21:B21)',
          formula: '=FORECAST(6, A20:C20, A21:B21)',
        ),
        const FortuneCellCoord(23, 5): const FortuneCell(
          value: '=FORECAST("x", A20:C20, A21:C21)',
          formula: '=FORECAST("x", A20:C20, A21:C21)',
        ),
        const FortuneCellCoord(24, 3): const FortuneCell(
          value: '=FORECAST(6, A24:C24, A25:C25)',
          formula: '=FORECAST(6, A24:C24, A25:C25)',
        ),
        const FortuneCellCoord(24, 4): const FortuneCell(
          value: '=STANDARDIZE(42, 40, 2)',
          formula: '=STANDARDIZE(42, 40, 2)',
        ),
        const FortuneCellCoord(24, 5): const FortuneCell(
          value: '=STANDARDIZE(42, 40, 0)',
          formula: '=STANDARDIZE(42, 40, 0)',
        ),
        const FortuneCellCoord(25, 0): const FortuneCell(
          value: '=ROUND(FISHER(0.5), 6)',
          formula: '=ROUND(FISHER(0.5), 6)',
        ),
        const FortuneCellCoord(25, 1): const FortuneCell(
          value: '=ROUND(FISHERINV(FISHER(0.5)), 6)',
          formula: '=ROUND(FISHERINV(FISHER(0.5)), 6)',
        ),
        const FortuneCellCoord(25, 2): const FortuneCell(
          value: '=FISHER(1)',
          formula: '=FISHER(1)',
        ),
        const FortuneCellCoord(25, 3): const FortuneCell(
          value: '=PERCENTRANK.INC(A4:D4, 7)',
          formula: '=PERCENTRANK.INC(A4:D4, 7)',
        ),
        const FortuneCellCoord(25, 4): const FortuneCell(
          value: '=PERCENTRANK.INC(A4:D4, 6, 4)',
          formula: '=PERCENTRANK.INC(A4:D4, 6, 4)',
        ),
        const FortuneCellCoord(25, 5): const FortuneCell(
          value: '=PERCENTRANK.EXC(A4:D4, 7)',
          formula: '=PERCENTRANK.EXC(A4:D4, 7)',
        ),
        const FortuneCellCoord(26, 0): const FortuneCell(
          value: '=PERCENTRANK.EXC(A4:D4, 1)',
          formula: '=PERCENTRANK.EXC(A4:D4, 1)',
        ),
        const FortuneCellCoord(26, 1): const FortuneCell(
          value: '=PERCENTRANK.INC(A4:D4, 7, 0)',
          formula: '=PERCENTRANK.INC(A4:D4, 7, 0)',
        ),
        const FortuneCellCoord(26, 2): const FortuneCell(
          value: '=TRIMMEAN(A4:D4, 0.5)',
          formula: '=TRIMMEAN(A4:D4, 0.5)',
        ),
        const FortuneCellCoord(26, 3): const FortuneCell(
          value: '=TRIMMEAN(A4:D4, 0)',
          formula: '=TRIMMEAN(A4:D4, 0)',
        ),
        const FortuneCellCoord(26, 4): const FortuneCell(
          value: '=TRIMMEAN(A4:D4, 1)',
          formula: '=TRIMMEAN(A4:D4, 1)',
        ),
        const FortuneCellCoord(26, 5): const FortuneCell(
          value: '=ROUND(EXPON.DIST(0.5, 2, FALSE), 6)',
          formula: '=ROUND(EXPON.DIST(0.5, 2, FALSE), 6)',
        ),
        const FortuneCellCoord(27, 0): const FortuneCell(
          value: '=ROUND(EXPON.DIST(0.5, 2, TRUE), 6)',
          formula: '=ROUND(EXPON.DIST(0.5, 2, TRUE), 6)',
        ),
        const FortuneCellCoord(27, 1): const FortuneCell(
          value: '=EXPON.DIST(-1, 2, TRUE)',
          formula: '=EXPON.DIST(-1, 2, TRUE)',
        ),
        const FortuneCellCoord(27, 2): const FortuneCell(
          value: '=ROUND(POISSON.DIST(2, 3, FALSE), 6)',
          formula: '=ROUND(POISSON.DIST(2, 3, FALSE), 6)',
        ),
        const FortuneCellCoord(27, 3): const FortuneCell(
          value: '=ROUND(POISSON.DIST(2, 3, TRUE), 6)',
          formula: '=ROUND(POISSON.DIST(2, 3, TRUE), 6)',
        ),
        const FortuneCellCoord(27, 4): const FortuneCell(
          value: '=POISSON.DIST(-1, 3, TRUE)',
          formula: '=POISSON.DIST(-1, 3, TRUE)',
        ),
        const FortuneCellCoord(27, 5): const FortuneCell(
          value: '=ROUND(NORM.DIST(42, 40, 2, FALSE), 6)',
          formula: '=ROUND(NORM.DIST(42, 40, 2, FALSE), 6)',
        ),
        const FortuneCellCoord(28, 0): const FortuneCell(
          value: '=ROUND(NORM.DIST(42, 40, 2, TRUE), 6)',
          formula: '=ROUND(NORM.DIST(42, 40, 2, TRUE), 6)',
        ),
        const FortuneCellCoord(28, 1): const FortuneCell(
          value: '=NORM.DIST(42, 40, 0, TRUE)',
          formula: '=NORM.DIST(42, 40, 0, TRUE)',
        ),
        const FortuneCellCoord(28, 2): const FortuneCell(
          value: '=ROUND(NORM.S.DIST(1, FALSE), 6)',
          formula: '=ROUND(NORM.S.DIST(1, FALSE), 6)',
        ),
        const FortuneCellCoord(28, 3): const FortuneCell(
          value: '=ROUND(NORM.S.DIST(1, TRUE), 6)',
          formula: '=ROUND(NORM.S.DIST(1, TRUE), 6)',
        ),
        const FortuneCellCoord(28, 4): const FortuneCell(
          value: '=ROUND(NORM.INV(0.841344746, 40, 2), 6)',
          formula: '=ROUND(NORM.INV(0.841344746, 40, 2), 6)',
        ),
        const FortuneCellCoord(28, 5): const FortuneCell(
          value: '=NORM.S.INV(0)',
          formula: '=NORM.S.INV(0)',
        ),
        const FortuneCellCoord(29, 0): const FortuneCell(
          value: '=ROUND(BINOM.DIST(6, 10, 0.5, FALSE), 6)',
          formula: '=ROUND(BINOM.DIST(6, 10, 0.5, FALSE), 6)',
        ),
        const FortuneCellCoord(29, 1): const FortuneCell(
          value: '=BINOM.DIST(6, 10, 0.5, TRUE)',
          formula: '=BINOM.DIST(6, 10, 0.5, TRUE)',
        ),
        const FortuneCellCoord(29, 2): const FortuneCell(
          value: '=BINOM.DIST(11, 10, 0.5, TRUE)',
          formula: '=BINOM.DIST(11, 10, 0.5, TRUE)',
        ),
        const FortuneCellCoord(29, 3): const FortuneCell(
          value: '=BINOM.DIST(6, 10, 2, FALSE)',
          formula: '=BINOM.DIST(6, 10, 2, FALSE)',
        ),
        const FortuneCellCoord(29, 4): const FortuneCell(
          value: '=BINOM.INV(6, 0.5, 0.75)',
          formula: '=BINOM.INV(6, 0.5, 0.75)',
        ),
        const FortuneCellCoord(29, 5): const FortuneCell(
          value: '=BINOM.INV(6, 0.5, 1)',
          formula: '=BINOM.INV(6, 0.5, 1)',
        ),
        const FortuneCellCoord(30, 0): const FortuneCell(
          value: '=ROUND(NEGBINOM.DIST(10, 5, 0.25, FALSE), 6)',
          formula: '=ROUND(NEGBINOM.DIST(10, 5, 0.25, FALSE), 6)',
        ),
        const FortuneCellCoord(30, 1): const FortuneCell(
          value: '=ROUND(NEGBINOM.DIST(10, 5, 0.25, TRUE), 6)',
          formula: '=ROUND(NEGBINOM.DIST(10, 5, 0.25, TRUE), 6)',
        ),
        const FortuneCellCoord(30, 2): const FortuneCell(
          value: '=NEGBINOM.DIST(-1, 5, 0.25, FALSE)',
          formula: '=NEGBINOM.DIST(-1, 5, 0.25, FALSE)',
        ),
        const FortuneCellCoord(30, 3): const FortuneCell(
          value: '=NEGBINOM.DIST(10, 0, 0.25, FALSE)',
          formula: '=NEGBINOM.DIST(10, 0, 0.25, FALSE)',
        ),
        const FortuneCellCoord(30, 4): const FortuneCell(
          value: '=ROUND(HYPGEOM.DIST(1, 4, 8, 20, FALSE), 6)',
          formula: '=ROUND(HYPGEOM.DIST(1, 4, 8, 20, FALSE), 6)',
        ),
        const FortuneCellCoord(30, 5): const FortuneCell(
          value: '=ROUND(HYPGEOM.DIST(1, 4, 8, 20, TRUE), 6)',
          formula: '=ROUND(HYPGEOM.DIST(1, 4, 8, 20, TRUE), 6)',
        ),
        const FortuneCellCoord(31, 0): const FortuneCell(
          value: '=HYPGEOM.DIST(5, 4, 8, 20, FALSE)',
          formula: '=HYPGEOM.DIST(5, 4, 8, 20, FALSE)',
        ),
        const FortuneCellCoord(31, 1): const FortuneCell(
          value: '=HYPGEOM.DIST(1, 21, 8, 20, FALSE)',
          formula: '=HYPGEOM.DIST(1, 21, 8, 20, FALSE)',
        ),
        const FortuneCellCoord(31, 2): const FortuneCell(
          value: '=POISSON.DIST(200, 200, FALSE)',
          formula: '=POISSON.DIST(200, 200, FALSE)',
        ),
        const FortuneCellCoord(31, 3): const FortuneCell(
          value: '=BINOM.DIST(500, 1000, 0.5, FALSE)',
          formula: '=BINOM.DIST(500, 1000, 0.5, FALSE)',
        ),
        const FortuneCellCoord(31, 4): const FortuneCell(
          value: '=NEGBINOM.DIST(200, 200, 0.5, FALSE)',
          formula: '=NEGBINOM.DIST(200, 200, 0.5, FALSE)',
        ),
        const FortuneCellCoord(31, 5): const FortuneCell(
          value: '=HYPGEOM.DIST(50, 100, 500, 1000, FALSE)',
          formula: '=HYPGEOM.DIST(50, 100, 500, 1000, FALSE)',
        ),
        const FortuneCellCoord(32, 0): const FortuneCell(value: '0.2'),
        const FortuneCellCoord(32, 1): const FortuneCell(value: '0.3'),
        const FortuneCellCoord(32, 2): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(32, 3): const FortuneCell(value: '0.4'),
        const FortuneCellCoord(32, 4): const FortuneCell(
          value: '=PROB(A4:D4, A33:D33, 5)',
          formula: '=PROB(A4:D4, A33:D33, 5)',
        ),
        const FortuneCellCoord(32, 5): const FortuneCell(
          value: '=PROB(A4:D4, A33:D33, 5, 9)',
          formula: '=PROB(A4:D4, A33:D33, 5, 9)',
        ),
        const FortuneCellCoord(33, 0): const FortuneCell(
          value: '=PROB(A4:D4, A33:C33, 5, 9)',
          formula: '=PROB(A4:D4, A33:C33, 5, 9)',
        ),
        const FortuneCellCoord(33, 1): const FortuneCell(value: '0.8'),
        const FortuneCellCoord(33, 2): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(33, 3): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(33, 4): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(33, 5): const FortuneCell(
          value: '=PROB(A4:D4, B34:E34, 5, 9)',
          formula: '=PROB(A4:D4, B34:E34, 5, 9)',
        ),
        const FortuneCellCoord(34, 0): const FortuneCell(
          value: '=PROB(A4:D4, A33:D33, 9, 5)',
          formula: '=PROB(A4:D4, A33:D33, 9, 5)',
        ),
        const FortuneCellCoord(34, 1): const FortuneCell(
          value: '=ROUND(WEIBULL.DIST(1.5, 2, 3, FALSE), 6)',
          formula: '=ROUND(WEIBULL.DIST(1.5, 2, 3, FALSE), 6)',
        ),
        const FortuneCellCoord(34, 2): const FortuneCell(
          value: '=ROUND(WEIBULL.DIST(1.5, 2, 3, TRUE), 6)',
          formula: '=ROUND(WEIBULL.DIST(1.5, 2, 3, TRUE), 6)',
        ),
        const FortuneCellCoord(34, 3): const FortuneCell(
          value: '=WEIBULL.DIST(-1, 2, 3, TRUE)',
          formula: '=WEIBULL.DIST(-1, 2, 3, TRUE)',
        ),
        const FortuneCellCoord(34, 4): const FortuneCell(
          value: '=WEIBULL.DIST(1, 0, 3, TRUE)',
          formula: '=WEIBULL.DIST(1, 0, 3, TRUE)',
        ),
        const FortuneCellCoord(34, 5): const FortuneCell(
          value: '=WEIBULL.DIST(1, 2, 0, TRUE)',
          formula: '=WEIBULL.DIST(1, 2, 0, TRUE)',
        ),
        const FortuneCellCoord(44, 2): const FortuneCell(
          value: '=WEIBULL.DIST(10^308, 3, 1, FALSE)',
          formula: '=WEIBULL.DIST(10^308, 3, 1, FALSE)',
        ),
        const FortuneCellCoord(45, 3): const FortuneCell(
          value: '=WEIBULL.DIST(10^-320, 0.01, 1, FALSE)',
          formula: '=WEIBULL.DIST(10^-320, 0.01, 1, FALSE)',
        ),
        const FortuneCellCoord(35, 0): const FortuneCell(
          value: '=ROUND(LOGNORM.DIST(4, 1, 0.5, FALSE), 6)',
          formula: '=ROUND(LOGNORM.DIST(4, 1, 0.5, FALSE), 6)',
        ),
        const FortuneCellCoord(35, 1): const FortuneCell(
          value: '=ROUND(LOGNORM.DIST(4, 1, 0.5, TRUE), 6)',
          formula: '=ROUND(LOGNORM.DIST(4, 1, 0.5, TRUE), 6)',
        ),
        const FortuneCellCoord(35, 2): const FortuneCell(
          value: '=ROUND(LOGNORM.INV(0.841344746, 1, 0.5), 6)',
          formula: '=ROUND(LOGNORM.INV(0.841344746, 1, 0.5), 6)',
        ),
        const FortuneCellCoord(35, 3): const FortuneCell(
          value: '=LOGNORM.DIST(0, 1, 0.5, TRUE)',
          formula: '=LOGNORM.DIST(0, 1, 0.5, TRUE)',
        ),
        const FortuneCellCoord(35, 4): const FortuneCell(
          value: '=LOGNORM.DIST(4, 1, 0, TRUE)',
          formula: '=LOGNORM.DIST(4, 1, 0, TRUE)',
        ),
        const FortuneCellCoord(35, 5): const FortuneCell(
          value: '=LOGNORM.INV(1, 1, 0.5)',
          formula: '=LOGNORM.INV(1, 1, 0.5)',
        ),
        const FortuneCellCoord(44, 3): const FortuneCell(
          value: '=FISHERINV(1000)',
          formula: '=FISHERINV(1000)',
        ),
        const FortuneCellCoord(44, 4): const FortuneCell(
          value: '=FISHERINV(-1000)',
          formula: '=FISHERINV(-1000)',
        ),
        const FortuneCellCoord(44, 5): const FortuneCell(
          value: '=LOGNORM.INV(0.5, 1000, 1)',
          formula: '=LOGNORM.INV(0.5, 1000, 1)',
        ),
        const FortuneCellCoord(36, 0): const FortuneCell(
          value: '=ROUND(PHI(1), 6)',
          formula: '=ROUND(PHI(1), 6)',
        ),
        const FortuneCellCoord(36, 1): const FortuneCell(
          value: '=ROUND(GAUSS(1), 6)',
          formula: '=ROUND(GAUSS(1), 6)',
        ),
        const FortuneCellCoord(36, 2): const FortuneCell(
          value: '=ROUND(GAUSS(0), 6)',
          formula: '=ROUND(GAUSS(0), 6)',
        ),
        const FortuneCellCoord(36, 3): const FortuneCell(
          value: '=PHI("x")',
          formula: '=PHI("x")',
        ),
        const FortuneCellCoord(36, 4): const FortuneCell(
          value: '=GAMMA(5)',
          formula: '=GAMMA(5)',
        ),
        const FortuneCellCoord(36, 5): const FortuneCell(
          value: '=ROUND(GAMMALN(5), 6)',
          formula: '=ROUND(GAMMALN(5), 6)',
        ),
        const FortuneCellCoord(37, 0): const FortuneCell(
          value: '=ROUND(GAMMA.DIST(2, 3, 2, FALSE), 6)',
          formula: '=ROUND(GAMMA.DIST(2, 3, 2, FALSE), 6)',
        ),
        const FortuneCellCoord(37, 1): const FortuneCell(
          value: '=ROUND(GAMMA.DIST(2, 3, 2, TRUE), 6)',
          formula: '=ROUND(GAMMA.DIST(2, 3, 2, TRUE), 6)',
        ),
        const FortuneCellCoord(37, 2): const FortuneCell(
          value: '=GAMMA(0)',
          formula: '=GAMMA(0)',
        ),
        const FortuneCellCoord(37, 3): const FortuneCell(
          value: '=ROUND(CHISQ.DIST(3, 4, FALSE), 6)',
          formula: '=ROUND(CHISQ.DIST(3, 4, FALSE), 6)',
        ),
        const FortuneCellCoord(37, 4): const FortuneCell(
          value: '=ROUND(CHISQ.DIST(3, 4, TRUE), 6)',
          formula: '=ROUND(CHISQ.DIST(3, 4, TRUE), 6)',
        ),
        const FortuneCellCoord(37, 5): const FortuneCell(
          value: '=ROUND(CHISQ.DIST.RT(3, 4), 6)',
          formula: '=ROUND(CHISQ.DIST.RT(3, 4), 6)',
        ),
        const FortuneCellCoord(38, 0): const FortuneCell(
          value: '=CHISQ.DIST(-1, 4, TRUE)',
          formula: '=CHISQ.DIST(-1, 4, TRUE)',
        ),
        const FortuneCellCoord(38, 1): const FortuneCell(
          value: '=ROUND(GAMMA.INV(0.080301397, 3, 2), 6)',
          formula: '=ROUND(GAMMA.INV(0.080301397, 3, 2), 6)',
        ),
        const FortuneCellCoord(38, 2): const FortuneCell(
          value: '=ROUND(CHISQ.INV(0.4421746, 4), 6)',
          formula: '=ROUND(CHISQ.INV(0.4421746, 4), 6)',
        ),
        const FortuneCellCoord(38, 3): const FortuneCell(
          value: '=ROUND(CHISQ.INV.RT(0.5578254, 4), 6)',
          formula: '=ROUND(CHISQ.INV.RT(0.5578254, 4), 6)',
        ),
        const FortuneCellCoord(38, 4): const FortuneCell(
          value: '=GAMMA.INV(0, 3, 2)',
          formula: '=GAMMA.INV(0, 3, 2)',
        ),
        const FortuneCellCoord(38, 5): const FortuneCell(
          value: '=CHISQ.INV(0.5, 0)',
          formula: '=CHISQ.INV(0.5, 0)',
        ),
        const FortuneCellCoord(38, 6): const FortuneCell(
          value: '=CHISQ.DIST()',
          formula: '=CHISQ.DIST()',
        ),
        const FortuneCellCoord(38, 7): const FortuneCell(
          value: '=CHISQ.DIST(0.5)',
          formula: '=CHISQ.DIST(0.5)',
        ),
        const FortuneCellCoord(38, 8): const FortuneCell(
          value: '=CHISQ.DIST(0.5, 1, TRUE)',
          formula: '=CHISQ.DIST(0.5, 1, TRUE)',
        ),
        const FortuneCellCoord(38, 9): const FortuneCell(
          value: '=CHISQ.DIST.RT(3, 5)',
          formula: '=CHISQ.DIST.RT(3, 5)',
        ),
        const FortuneCellCoord(38, 10): const FortuneCell(
          value: '=CHISQ.INV()',
          formula: '=CHISQ.INV()',
        ),
        const FortuneCellCoord(38, 11): const FortuneCell(
          value: '=CHISQ.INV(0.5)',
          formula: '=CHISQ.INV(0.5)',
        ),
        const FortuneCellCoord(38, 12): const FortuneCell(
          value: '=CHISQ.INV(0.5, 6)',
          formula: '=CHISQ.INV(0.5, 6)',
        ),
        const FortuneCellCoord(38, 13): const FortuneCell(
          value: '=CHISQ.INV.RT(-1, 2)',
          formula: '=CHISQ.INV.RT(-1, 2)',
        ),
        const FortuneCellCoord(38, 14): const FortuneCell(
          value: '=CHISQ.INV.RT(0.4, 6)',
          formula: '=CHISQ.INV.RT(0.4, 6)',
        ),
        const FortuneCellCoord(39, 0): const FortuneCell(
          value: '=ROUND(BETA.DIST(0.5, 2, 3, FALSE), 6)',
          formula: '=ROUND(BETA.DIST(0.5, 2, 3, FALSE), 6)',
        ),
        const FortuneCellCoord(39, 1): const FortuneCell(
          value: '=BETA.DIST(0.5, 2, 3, TRUE)',
          formula: '=BETA.DIST(0.5, 2, 3, TRUE)',
        ),
        const FortuneCellCoord(39, 2): const FortuneCell(
          value: '=ROUND(BETA.INV(0.6875, 2, 3), 6)',
          formula: '=ROUND(BETA.INV(0.6875, 2, 3), 6)',
        ),
        const FortuneCellCoord(39, 3): const FortuneCell(
          value: '=ROUND(BETA.DIST(4, 2, 3, FALSE, 2, 6), 6)',
          formula: '=ROUND(BETA.DIST(4, 2, 3, FALSE, 2, 6), 6)',
        ),
        const FortuneCellCoord(39, 4): const FortuneCell(
          value: '=ROUND(BETA.INV(0.6875, 2, 3, 2, 6), 6)',
          formula: '=ROUND(BETA.INV(0.6875, 2, 3, 2, 6), 6)',
        ),
        const FortuneCellCoord(39, 5): const FortuneCell(
          value: '=BETA.DIST(0.5, 0, 3, TRUE)',
          formula: '=BETA.DIST(0.5, 0, 3, TRUE)',
        ),
        const FortuneCellCoord(40, 0): const FortuneCell(
          value: '=BETA.INV(1, 2, 3)',
          formula: '=BETA.INV(1, 2, 3)',
        ),
        const FortuneCellCoord(40, 1): const FortuneCell(
          value: '=ROUND(F.DIST(1, 4, 6, FALSE), 6)',
          formula: '=ROUND(F.DIST(1, 4, 6, FALSE), 6)',
        ),
        const FortuneCellCoord(40, 2): const FortuneCell(
          value: '=F.DIST(1, 4, 6, TRUE)',
          formula: '=F.DIST(1, 4, 6, TRUE)',
        ),
        const FortuneCellCoord(40, 3): const FortuneCell(
          value: '=F.DIST.RT(1, 4, 6)',
          formula: '=F.DIST.RT(1, 4, 6)',
        ),
        const FortuneCellCoord(40, 4): const FortuneCell(
          value: '=ROUND(F.INV(0.5248, 4, 6), 6)',
          formula: '=ROUND(F.INV(0.5248, 4, 6), 6)',
        ),
        const FortuneCellCoord(40, 5): const FortuneCell(
          value: '=ROUND(F.INV.RT(0.4752, 4, 6), 6)',
          formula: '=ROUND(F.INV.RT(0.4752, 4, 6), 6)',
        ),
        const FortuneCellCoord(40, 6): const FortuneCell(
          value: '=BETADIST(2, 8, 10, TRUE, 1)',
          formula: '=BETADIST(2, 8, 10, TRUE, 1)',
        ),
        const FortuneCellCoord(40, 7): const FortuneCell(
          value: '=BETADIST()',
          formula: '=BETADIST()',
        ),
        const FortuneCellCoord(40, 8): const FortuneCell(
          value: '=BETADIST(2)',
          formula: '=BETADIST(2)',
        ),
        const FortuneCellCoord(40, 9): const FortuneCell(
          value: '=BETADIST(2, 8)',
          formula: '=BETADIST(2, 8)',
        ),
        const FortuneCellCoord(40, 10): const FortuneCell(
          value: '=BETADIST(2, 8, 10)',
          formula: '=BETADIST(2, 8, 10)',
        ),
        const FortuneCellCoord(40, 11): const FortuneCell(
          value: '=BETADIST(2, 8, 10, TRUE, 1, 3)',
          formula: '=BETADIST(2, 8, 10, TRUE, 1, 3)',
        ),
        const FortuneCellCoord(40, 12): const FortuneCell(
          value: '=BETA.DIST(2, 8, 10, TRUE, 1, 3)',
          formula: '=BETA.DIST(2, 8, 10, TRUE, 1, 3)',
        ),
        const FortuneCellCoord(41, 0): const FortuneCell(
          value: '=F.DIST(-1, 4, 6, TRUE)',
          formula: '=F.DIST(-1, 4, 6, TRUE)',
        ),
        const FortuneCellCoord(41, 1): const FortuneCell(
          value: '=F.INV(0, 4, 6)',
          formula: '=F.INV(0, 4, 6)',
        ),
        const FortuneCellCoord(41, 2): const FortuneCell(
          value: '=ROUND(T.DIST(1, 1, FALSE), 6)',
          formula: '=ROUND(T.DIST(1, 1, FALSE), 6)',
        ),
        const FortuneCellCoord(41, 3): const FortuneCell(
          value: '=T.DIST(1, 1, TRUE)',
          formula: '=T.DIST(1, 1, TRUE)',
        ),
        const FortuneCellCoord(41, 4): const FortuneCell(
          value: '=T.DIST.RT(1, 1)',
          formula: '=T.DIST.RT(1, 1)',
        ),
        const FortuneCellCoord(41, 5): const FortuneCell(
          value: '=T.DIST.2T(1, 1)',
          formula: '=T.DIST.2T(1, 1)',
        ),
        const FortuneCellCoord(42, 0): const FortuneCell(
          value: '=ROUND(T.INV(0.75, 1), 6)',
          formula: '=ROUND(T.INV(0.75, 1), 6)',
        ),
        const FortuneCellCoord(42, 1): const FortuneCell(
          value: '=ROUND(T.INV(0.25, 1), 6)',
          formula: '=ROUND(T.INV(0.25, 1), 6)',
        ),
        const FortuneCellCoord(42, 2): const FortuneCell(
          value: '=ROUND(T.INV.2T(0.5, 1), 6)',
          formula: '=ROUND(T.INV.2T(0.5, 1), 6)',
        ),
        const FortuneCellCoord(42, 3): const FortuneCell(
          value: '=TDIST(1, 1, 2)',
          formula: '=TDIST(1, 1, 2)',
        ),
        const FortuneCellCoord(42, 4): const FortuneCell(
          value: '=T.DIST.2T(-1, 1)',
          formula: '=T.DIST.2T(-1, 1)',
        ),
        const FortuneCellCoord(42, 5): const FortuneCell(
          value: '=T.INV(1, 1)',
          formula: '=T.INV(1, 1)',
        ),
        const FortuneCellCoord(43, 0): const FortuneCell(
          value: '=ROUND(CONFIDENCE.NORM(0.05, 2, 100), 6)',
          formula: '=ROUND(CONFIDENCE.NORM(0.05, 2, 100), 6)',
        ),
        const FortuneCellCoord(43, 1): const FortuneCell(
          value: '=ROUND(CONFIDENCE(0.05, 2, 100), 6)',
          formula: '=ROUND(CONFIDENCE(0.05, 2, 100), 6)',
        ),
        const FortuneCellCoord(43, 2): const FortuneCell(
          value: '=ROUND(CONFIDENCE.T(0.5, 1, 2), 6)',
          formula: '=ROUND(CONFIDENCE.T(0.5, 1, 2), 6)',
        ),
        const FortuneCellCoord(43, 3): const FortuneCell(
          value: '=CONFIDENCE.NORM(0, 2, 100)',
          formula: '=CONFIDENCE.NORM(0, 2, 100)',
        ),
        const FortuneCellCoord(43, 4): const FortuneCell(
          value: '=CONFIDENCE.NORM(0.05, 0, 100)',
          formula: '=CONFIDENCE.NORM(0.05, 0, 100)',
        ),
        const FortuneCellCoord(43, 5): const FortuneCell(
          value: '=CONFIDENCE.T(0.5, 1, 1)',
          formula: '=CONFIDENCE.T(0.5, 1, 1)',
        ),
        const FortuneCellCoord(44, 0): const FortuneCell(
          value: '=ROUND(SQRTPI(10^308)/10^154, 6)',
          formula: '=ROUND(SQRTPI(10^308)/10^154, 6)',
        ),
        const FortuneCellCoord(44, 1): const FortuneCell(
          value: '=SERIESSUM(10^308, 2, 1, 1)',
          formula: '=SERIESSUM(10^308, 2, 1, 1)',
        ),
        const FortuneCellCoord(45, 0): const FortuneCell(
          value: '=GAMMA.DIST(10^-320, 0.01, 1, FALSE)',
          formula: '=GAMMA.DIST(10^-320, 0.01, 1, FALSE)',
        ),
        const FortuneCellCoord(45, 1): const FortuneCell(
          value: '=CHISQ.DIST(10^-320, 0.02, FALSE)',
          formula: '=CHISQ.DIST(10^-320, 0.02, FALSE)',
        ),
        const FortuneCellCoord(45, 2): const FortuneCell(
          value: '=BETA.DIST(10^-320, 0.01, 1, FALSE)',
          formula: '=BETA.DIST(10^-320, 0.01, 1, FALSE)',
        ),
        const FortuneCellCoord(45, 4): const FortuneCell(
          value: '=F.DIST(10^-320, 0.02, 1, FALSE)',
          formula: '=F.DIST(10^-320, 0.02, 1, FALSE)',
        ),
        const FortuneCellCoord(46, 0): const FortuneCell(
          value: '=PRODUCT()',
          formula: '=PRODUCT()',
        ),
        const FortuneCellCoord(46, 1): const FortuneCell(
          value: '=PRODUCT("value")',
          formula: '=PRODUCT("value")',
        ),
        const FortuneCellCoord(46, 2): const FortuneCell(
          value: '=PRODUCT(2)',
          formula: '=PRODUCT(2)',
        ),
        const FortuneCellCoord(46, 3): const FortuneCell(
          value: '=PRODUCT(2, 4)',
          formula: '=PRODUCT(2, 4)',
        ),
        const FortuneCellCoord(46, 4): const FortuneCell(
          value: '=PRODUCT(2, 8)',
          formula: '=PRODUCT(2, 8)',
        ),
        const FortuneCellCoord(46, 5): const FortuneCell(
          value: '=PRODUCT(2, 8, 10, 10)',
          formula: '=PRODUCT(2, 8, 10, 10)',
        ),
        const FortuneCellCoord(47, 0): const FortuneCell(
          value: '=QUOTIENT()',
          formula: '=QUOTIENT()',
        ),
        const FortuneCellCoord(47, 1): const FortuneCell(
          value: '=QUOTIENT("value")',
          formula: '=QUOTIENT("value")',
        ),
        const FortuneCellCoord(47, 2): const FortuneCell(
          value: '=QUOTIENT(2)',
          formula: '=QUOTIENT(2)',
        ),
        const FortuneCellCoord(47, 3): const FortuneCell(
          value: '=QUOTIENT(2, 4)',
          formula: '=QUOTIENT(2, 4)',
        ),
        const FortuneCellCoord(47, 4): const FortuneCell(
          value: '=QUOTIENT(8, 2)',
          formula: '=QUOTIENT(8, 2)',
        ),
        const FortuneCellCoord(47, 5): const FortuneCell(
          value: '=QUOTIENT(9, 2)',
          formula: '=QUOTIENT(9, 2)',
        ),
        const FortuneCellCoord(47, 6): const FortuneCell(
          value: '=QUOTIENT(-9, 2)',
          formula: '=QUOTIENT(-9, 2)',
        ),
        const FortuneCellCoord(48, 0): const FortuneCell(
          value: '=SIGN()',
          formula: '=SIGN()',
        ),
        const FortuneCellCoord(48, 1): const FortuneCell(
          value: '=SIGN("value")',
          formula: '=SIGN("value")',
        ),
        const FortuneCellCoord(48, 2): const FortuneCell(
          value: '=SIGN(1)',
          formula: '=SIGN(1)',
        ),
        const FortuneCellCoord(48, 3): const FortuneCell(
          value: '=SIGN(30)',
          formula: '=SIGN(30)',
        ),
        const FortuneCellCoord(48, 4): const FortuneCell(
          value: '=SIGN(-1.1)',
          formula: '=SIGN(-1.1)',
        ),
        const FortuneCellCoord(48, 5): const FortuneCell(
          value: '=SIGN(0)',
          formula: '=SIGN(0)',
        ),
        const FortuneCellCoord(49, 0): const FortuneCell(
          value: '=SQRT()',
          formula: '=SQRT()',
        ),
        const FortuneCellCoord(49, 1): const FortuneCell(
          value: '=SQRT("value")',
          formula: '=SQRT("value")',
        ),
        const FortuneCellCoord(49, 2): const FortuneCell(
          value: '=SQRT(1)',
          formula: '=SQRT(1)',
        ),
        const FortuneCellCoord(49, 3): const FortuneCell(
          value: '=SQRT(9)',
          formula: '=SQRT(9)',
        ),
        const FortuneCellCoord(49, 4): const FortuneCell(
          value: '=SQRT(64)',
          formula: '=SQRT(64)',
        ),
        const FortuneCellCoord(49, 5): const FortuneCell(
          value: '=SQRTPI()',
          formula: '=SQRTPI()',
        ),
        const FortuneCellCoord(49, 6): const FortuneCell(
          value: '=SQRTPI("value")',
          formula: '=SQRTPI("value")',
        ),
        const FortuneCellCoord(49, 7): const FortuneCell(
          value: '=SQRTPI(64)',
          formula: '=SQRTPI(64)',
        ),
        const FortuneCellCoord(50, 0): const FortuneCell(
          value:
              '=ROUND(SERIESSUM(PI() / 4, 0, 2, 1, -1/FACT(2), 1/FACT(4), -1/FACT(6)), 6)',
          formula:
              '=ROUND(SERIESSUM(PI() / 4, 0, 2, 1, -1/FACT(2), 1/FACT(4), -1/FACT(6)), 6)',
        ),
        const FortuneCellCoord(50, 1): const FortuneCell(
          value: '=SERIESSUM(PI() / 4, 0, 2, SERIESSUM_ARR)',
          formula: '=SERIESSUM(PI() / 4, 0, 2, SERIESSUM_ARR)',
        ),
        const FortuneCellCoord(51, 0): const FortuneCell(
          value: '=SUM()',
          formula: '=SUM()',
        ),
        const FortuneCellCoord(51, 1): const FortuneCell(
          value: '=SUM("value")',
          formula: '=SUM("value")',
        ),
        const FortuneCellCoord(51, 2): const FortuneCell(
          value: '=SUM(64)',
          formula: '=SUM(64)',
        ),
        const FortuneCellCoord(51, 3): const FortuneCell(
          value: '=SUM(64, 3.3, 0.1)',
          formula: '=SUM(64, 3.3, 0.1)',
        ),
        const FortuneCellCoord(52, 0): const FortuneCell(
          value: '=SUMPRODUCT({3,4;8,6;1,9}, {2,7;6,7;5,3})',
          formula: '=SUMPRODUCT({3,4;8,6;1,9}, {2,7;6,7;5,3})',
        ),
        const FortuneCellCoord(52, 1): const FortuneCell(
          value: '=SUMSQ(64)',
          formula: '=SUMSQ(64)',
        ),
        const FortuneCellCoord(52, 2): const FortuneCell(
          value: '=SUMSQ(64, 3.3, 0.1)',
          formula: '=SUMSQ(64, 3.3, 0.1)',
        ),
        const FortuneCellCoord(53, 0): const FortuneCell(
          value: '=SUMX2MY2({1,2,3}, {4,5,6})',
          formula: '=SUMX2MY2({1,2,3}, {4,5,6})',
        ),
        const FortuneCellCoord(53, 1): const FortuneCell(
          value: '=SUMX2PY2({1,2,3}, {4,5,6})',
          formula: '=SUMX2PY2({1,2,3}, {4,5,6})',
        ),
        const FortuneCellCoord(53, 2): const FortuneCell(
          value: '=SUMXMY2({1,2,3}, {4,5,6})',
          formula: '=SUMXMY2({1,2,3}, {4,5,6})',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '-2');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '120');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '2.718282');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 9)]?.renderedText, '#NAME?');
    expect(
      sheet.cells[const FortuneCellCoord(2, 10)]?.renderedText,
      '2.718281828459',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 11)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 12)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 13)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 14)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 15)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 16)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 17)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 18)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 19)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '3.141593');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '180');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '3.141593');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '90');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '90');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '45');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '2.506628');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText,
      '11.666667',
    );

    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '8.75');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '3.41565');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '2.95804');
    expect(
      sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText,
      '11.666667',
    );
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '8.75');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '35');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '2.5');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '156');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '4.212866');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '2.751092');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '120');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '105');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '60');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 10)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(9, 11)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(9, 12)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(9, 13)]?.renderedText, '720');
    expect(sheet.cells[const FortuneCellCoord(9, 14)]?.renderedText, '720');
    expect(sheet.cells[const FortuneCellCoord(9, 15)]?.renderedText, '3628800');
    expect(sheet.cells[const FortuneCellCoord(9, 16)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 17)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(9, 18)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 19)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '-3');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(10, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(10, 9)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(10, 10)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(10, 11)]?.renderedText, '48');
    expect(sheet.cells[const FortuneCellCoord(10, 12)]?.renderedText, '48');
    expect(sheet.cells[const FortuneCellCoord(10, 13)]?.renderedText, '3840');
    expect(
      sheet.cells[const FortuneCellCoord(10, 14)]?.renderedText,
      '#VALUE!',
    );
    expect(sheet.cells[const FortuneCellCoord(10, 15)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(10, 16)]?.renderedText, '2.2');
    expect(sheet.cells[const FortuneCellCoord(10, 17)]?.renderedText, '24');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, '1260');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '17');
    expect(sheet.cells[const FortuneCellCoord(11, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(11, 9)]?.renderedText, '280');
    expect(
      sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText,
      '-0.752837',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText,
      '0.342857',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(13, 5)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '41');
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(14, 5)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '140');
    expect(sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText, '1140');
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '-1380');
    expect(sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText, '1420');
    expect(sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(17, 4)]?.renderedText, '1.5');
    expect(sheet.cells[const FortuneCellCoord(17, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(17, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 9)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 10)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(17, 11)]?.renderedText,
      '#DIV/0!',
    );
    expect(sheet.cells[const FortuneCellCoord(18, 0)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(18, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(18, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(18, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(18, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(18, 9)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(18, 10)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(18, 11)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(18, 12)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(18, 13)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(19, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(19, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(19, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(19, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(19, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(19, 8)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(19, 9)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(19, 10)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(19, 11)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(20, 3)]?.renderedText,
      '0.981981',
    );
    expect(
      sheet.cells[const FortuneCellCoord(20, 4)]?.renderedText,
      '0.981981',
    );
    expect(
      sheet.cells[const FortuneCellCoord(20, 5)]?.renderedText,
      '0.964286',
    );
    expect(sheet.cells[const FortuneCellCoord(21, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(21, 1)]?.renderedText, '1.5');
    expect(sheet.cells[const FortuneCellCoord(21, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(21, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(21, 5)]?.renderedText,
      '0.642857',
    );
    expect(sheet.cells[const FortuneCellCoord(21, 6)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(21, 8)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(22, 0)]?.renderedText,
      '-0.357143',
    );
    expect(
      sheet.cells[const FortuneCellCoord(22, 1)]?.renderedText,
      '0.267261',
    );
    expect(sheet.cells[const FortuneCellCoord(22, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(22, 3)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(22, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(22, 5)]?.renderedText, '3.5');
    expect(sheet.cells[const FortuneCellCoord(23, 3)]?.renderedText, '3.5');
    expect(sheet.cells[const FortuneCellCoord(23, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(23, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(24, 3)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(24, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(24, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(25, 0)]?.renderedText,
      '0.549306',
    );
    expect(sheet.cells[const FortuneCellCoord(25, 1)]?.renderedText, '0.5');
    expect(
      sheet.cells[const FortuneCellCoord(25, 2)]?.renderedText,
      'Infinity',
    );
    expect(sheet.cells[const FortuneCellCoord(25, 3)]?.renderedText, '0.667');
    expect(sheet.cells[const FortuneCellCoord(25, 4)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(25, 5)]?.renderedText, '0.6');
    expect(sheet.cells[const FortuneCellCoord(26, 0)]?.renderedText, '0.2');
    expect(sheet.cells[const FortuneCellCoord(26, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(26, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(26, 3)]?.renderedText, '5.5');
    expect(sheet.cells[const FortuneCellCoord(26, 4)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(26, 5)]?.renderedText,
      '0.735759',
    );
    expect(
      sheet.cells[const FortuneCellCoord(27, 0)]?.renderedText,
      '0.632121',
    );
    expect(sheet.cells[const FortuneCellCoord(27, 1)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(27, 2)]?.renderedText,
      '0.224042',
    );
    expect(sheet.cells[const FortuneCellCoord(27, 3)]?.renderedText, '0.42319');
    expect(sheet.cells[const FortuneCellCoord(27, 4)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(27, 5)]?.renderedText,
      '0.120985',
    );
    expect(
      sheet.cells[const FortuneCellCoord(28, 0)]?.renderedText,
      '0.841345',
    );
    expect(sheet.cells[const FortuneCellCoord(28, 1)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(28, 2)]?.renderedText,
      '0.241971',
    );
    expect(
      sheet.cells[const FortuneCellCoord(28, 3)]?.renderedText,
      '0.841345',
    );
    expect(sheet.cells[const FortuneCellCoord(28, 4)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(28, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(29, 0)]?.renderedText,
      '0.205078',
    );
    expect(
      sheet.cells[const FortuneCellCoord(29, 1)]?.renderedText,
      '0.828125',
    );
    expect(sheet.cells[const FortuneCellCoord(29, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(29, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(29, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(29, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(30, 0)]?.renderedText,
      '0.055049',
    );
    expect(
      sheet.cells[const FortuneCellCoord(30, 1)]?.renderedText,
      '0.313514',
    );
    expect(sheet.cells[const FortuneCellCoord(30, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(30, 3)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(30, 4)]?.renderedText,
      '0.363261',
    );
    expect(
      sheet.cells[const FortuneCellCoord(30, 5)]?.renderedText,
      '0.465428',
    );
    expect(sheet.cells[const FortuneCellCoord(31, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(31, 1)]?.renderedText, '#NUM!');
    final poissonLargeProbability = double.parse(
      sheet.cells[const FortuneCellCoord(31, 2)]!.renderedText,
    );
    expect(poissonLargeProbability, inInclusiveRange(0.028, 0.029));
    final binomialLargeProbability = double.parse(
      sheet.cells[const FortuneCellCoord(31, 3)]!.renderedText,
    );
    expect(binomialLargeProbability, inInclusiveRange(0.025, 0.026));
    final negativeBinomialLargeProbability = double.parse(
      sheet.cells[const FortuneCellCoord(31, 4)]!.renderedText,
    );
    expect(negativeBinomialLargeProbability, inInclusiveRange(0.019, 0.021));
    final hypergeometricLargeProbability = double.parse(
      sheet.cells[const FortuneCellCoord(31, 5)]!.renderedText,
    );
    expect(hypergeometricLargeProbability, inInclusiveRange(0.08, 0.09));
    expect(sheet.cells[const FortuneCellCoord(32, 4)]?.renderedText, '0.1');
    expect(sheet.cells[const FortuneCellCoord(32, 5)]?.renderedText, '0.7');
    expect(sheet.cells[const FortuneCellCoord(33, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(33, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(34, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(44, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(45, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(45, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(45, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(45, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(34, 1)]?.renderedText, '0.2596');
    expect(sheet.cells[const FortuneCellCoord(44, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(45, 3)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(34, 2)]?.renderedText,
      '0.221199',
    );
    expect(sheet.cells[const FortuneCellCoord(34, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(34, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(34, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(35, 0)]?.renderedText,
      '0.148002',
    );
    expect(
      sheet.cells[const FortuneCellCoord(35, 1)]?.renderedText,
      '0.780117',
    );
    expect(
      sheet.cells[const FortuneCellCoord(35, 2)]?.renderedText,
      '4.481689',
    );
    expect(sheet.cells[const FortuneCellCoord(35, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(35, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(35, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(44, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(44, 4)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(44, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(36, 0)]?.renderedText,
      '0.241971',
    );
    expect(
      sheet.cells[const FortuneCellCoord(36, 1)]?.renderedText,
      '0.341345',
    );
    expect(sheet.cells[const FortuneCellCoord(36, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(36, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(36, 4)]?.renderedText, '24');
    expect(
      sheet.cells[const FortuneCellCoord(36, 5)]?.renderedText,
      '3.178054',
    );
    expect(sheet.cells[const FortuneCellCoord(37, 0)]?.renderedText, '0.09197');
    expect(
      sheet.cells[const FortuneCellCoord(37, 1)]?.renderedText,
      '0.080301',
    );
    expect(sheet.cells[const FortuneCellCoord(37, 2)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(37, 3)]?.renderedText,
      '0.167348',
    );
    expect(
      sheet.cells[const FortuneCellCoord(37, 4)]?.renderedText,
      '0.442175',
    );
    expect(
      sheet.cells[const FortuneCellCoord(37, 5)]?.renderedText,
      '0.557825',
    );
    expect(sheet.cells[const FortuneCellCoord(38, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(38, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(38, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(38, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(38, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(38, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(38, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(38, 7)]?.renderedText, '#VALUE!');
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(38, 8)]!.renderedText),
      closeTo(0.5204998778130242, 1e-12),
    );
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(38, 9)]!.renderedText),
      closeTo(0.6999858358786271, 1e-12),
    );
    expect(
      sheet.cells[const FortuneCellCoord(38, 10)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(38, 11)]?.renderedText,
      '#VALUE!',
    );
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(38, 12)]!.renderedText),
      closeTo(5.348120627447116, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(38, 13)]?.renderedText, '#NUM!');
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(38, 14)]!.renderedText),
      closeTo(6.2107571945266935, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(39, 0)]?.renderedText, '1.5');
    expect(sheet.cells[const FortuneCellCoord(39, 1)]?.renderedText, '0.6875');
    expect(sheet.cells[const FortuneCellCoord(39, 2)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(39, 3)]?.renderedText, '0.375');
    expect(sheet.cells[const FortuneCellCoord(39, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(39, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(40, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(40, 1)]?.renderedText, '0.41472');
    expect(sheet.cells[const FortuneCellCoord(40, 2)]?.renderedText, '0.5248');
    expect(sheet.cells[const FortuneCellCoord(40, 3)]?.renderedText, '0.4752');
    expect(sheet.cells[const FortuneCellCoord(40, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(40, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(40, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(40, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(40, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(40, 9)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(40, 10)]?.renderedText,
      '#VALUE!',
    );
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(40, 11)]!.renderedText),
      closeTo(0.6854705810117458, 1e-9),
    );
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(40, 12)]!.renderedText),
      closeTo(0.6854705810117458, 1e-9),
    );
    expect(sheet.cells[const FortuneCellCoord(41, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(41, 1)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(41, 2)]?.renderedText,
      '0.159155',
    );
    expect(sheet.cells[const FortuneCellCoord(41, 3)]?.renderedText, '0.75');
    expect(sheet.cells[const FortuneCellCoord(41, 4)]?.renderedText, '0.25');
    expect(sheet.cells[const FortuneCellCoord(41, 5)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(42, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(42, 1)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(42, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(42, 3)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(42, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(42, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(43, 0)]?.renderedText,
      '0.391993',
    );
    expect(
      sheet.cells[const FortuneCellCoord(43, 1)]?.renderedText,
      '0.391993',
    );
    expect(
      sheet.cells[const FortuneCellCoord(43, 2)]?.renderedText,
      '0.707107',
    );
    expect(sheet.cells[const FortuneCellCoord(43, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(43, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(43, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(44, 0)]?.renderedText,
      '1.772454',
    );
    expect(sheet.cells[const FortuneCellCoord(46, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(46, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(46, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(46, 3)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(46, 4)]?.renderedText, '16');
    expect(sheet.cells[const FortuneCellCoord(46, 5)]?.renderedText, '1600');
    expect(sheet.cells[const FortuneCellCoord(47, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(47, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(47, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(47, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(47, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(47, 5)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(47, 6)]?.renderedText, '-4');
    expect(sheet.cells[const FortuneCellCoord(48, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(48, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(48, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(48, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(48, 4)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(48, 5)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(49, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(49, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(49, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(49, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(49, 4)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(49, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(49, 6)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(49, 7)]?.renderedText,
      '14.179630807244',
    );
    expect(
      sheet.cells[const FortuneCellCoord(50, 0)]?.renderedText,
      '0.707103',
    );
    final namedSeriesSumText =
        sheet.cells[const FortuneCellCoord(50, 1)]?.renderedText;
    expect(
      double.parse(namedSeriesSumText ?? 'NaN'),
      closeTo(0.7071032148228457, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(51, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(51, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(51, 2)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(51, 3)]?.renderedText, '67.4');
    expect(sheet.cells[const FortuneCellCoord(52, 0)]?.renderedText, '156');
    expect(sheet.cells[const FortuneCellCoord(52, 1)]?.renderedText, '4096');
    expect(
      sheet.cells[const FortuneCellCoord(52, 2)]?.renderedText,
      '4106.900000000001',
    );
    expect(sheet.cells[const FortuneCellCoord(53, 0)]?.renderedText, '-63');
    expect(sheet.cells[const FortuneCellCoord(53, 1)]?.renderedText, '91');
    expect(sheet.cells[const FortuneCellCoord(53, 2)]?.renderedText, '27');
  });

  test('formula engine evaluates SUMPRODUCT range fixture', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '8'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '6'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '9'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '7'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '6'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: '7'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: '5'),
        const FortuneCellCoord(5, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SUMPRODUCT(A1:B3, A4:B6)',
          formula: '=SUMPRODUCT(A1:B3, A4:B6)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '156');
  });

  test('formula engine evaluates SUMX range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '5'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '6'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SUMX2MY2(A1:B3, A4:B6)',
          formula: '=SUMX2MY2(A1:B3, A4:B6)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=SUMX2PY2(A1:B3, A4:B6)',
          formula: '=SUMX2PY2(A1:B3, A4:B6)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=SUMXMY2(A1:B3, A4:B6)',
          formula: '=SUMXMY2(A1:B3, A4:B6)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '-63');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '91');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '27');
  });

  test('formula engine evaluates dollar fraction helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DOLLARDE(1.1, 4)',
          formula: '=DOLLARDE(1.1, 4)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=DOLLARFR(1.1, 4)',
          formula: '=DOLLARFR(1.1, 4)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=DOLLARDE(100.10, 32)',
          formula: '=DOLLARDE(100.10, 32)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DOLLARFR(100.3125, 32)',
          formula: '=DOLLARFR(100.3125, 32)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=DOLLARDE(1.1, 0)',
          formula: '=DOLLARDE(1.1, 0)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=DOLLARFR(1.1, -4)',
          formula: '=DOLLARFR(1.1, -4)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=DOLLARDE()',
          formula: '=DOLLARDE()',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=DOLLARDE(1.1)',
          formula: '=DOLLARDE(1.1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=DOLLARFR()',
          formula: '=DOLLARFR()',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=DOLLARFR(1.1)',
          formula: '=DOLLARFR(1.1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1.25');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1.04');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '100.3125');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '100.1');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates effective and nominal interest helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ROUND(EFFECT(0.1, 4), 6)',
          formula: '=ROUND(EFFECT(0.1, 4), 6)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ROUND(NOMINAL(0.1, 4), 6)',
          formula: '=ROUND(NOMINAL(0.1, 4), 6)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ROUND(EFFECT(0.1, 4.9), 6)',
          formula: '=ROUND(EFFECT(0.1, 4.9), 6)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=EFFECT(0, 4)',
          formula: '=EFFECT(0, 4)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=NOMINAL(-0.1, 4)',
          formula: '=NOMINAL(-0.1, 4)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=EFFECT(0.1, 0.9)',
          formula: '=EFFECT(0.1, 0.9)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=EFFECT(10^308, 4)',
          formula: '=EFFECT(10^308, 4)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=NOMINAL(10^308, 4)',
          formula: '=NOMINAL(10^308, 4)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=EFFECT()',
          formula: '=EFFECT()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=EFFECT(1.1)',
          formula: '=EFFECT(1.1)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=EFFECT(1.1, 4)',
          formula: '=EFFECT(1.1, 4)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=NOMINAL()',
          formula: '=NOMINAL()',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=NOMINAL(1.1)',
          formula: '=NOMINAL(1.1)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=NOMINAL(1.1, 2)',
          formula: '=NOMINAL(1.1, 2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0.103813');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0.096455');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '0.103813');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      isNot('#NUM!'),
    );
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText,
      '1.642656640625',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText,
      '0.898275349238',
    );
  });

  test('formula engine evaluates future value schedule helper', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=FVSCHEDULE(100,{0.09,0.11,0.1})',
          formula: '=FVSCHEDULE(100,{0.09,0.11,0.1})',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=FVSCHEDULE(100,{0.09;0.11;0.1})',
          formula: '=FVSCHEDULE(100,{0.09;0.11;0.1})',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=FVSCHEDULE(100,{0.09,TRUE,0.1})',
          formula: '=FVSCHEDULE(100,{0.09,TRUE,0.1})',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=FVSCHEDULE("x",{0.1})',
          formula: '=FVSCHEDULE("x",{0.1})',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=FVSCHEDULE(100,{0.1,1/0})',
          formula: '=FVSCHEDULE(100,{0.1,1/0})',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=FVSCHEDULE(10^308,{1,1})',
          formula: '=FVSCHEDULE(10^308,{1,1})',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '133.089');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '133.089');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '239.8');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');

    final rangeSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '0.09'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '0.1'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '0.11'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=FVSCHEDULE(100, A1:C1)',
          formula: '=FVSCHEDULE(100, A1:C1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(rangeSheet);

    expect(
      rangeSheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
      '133.089',
    );
  });

  test('formula engine evaluates annuity financial helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ROUND(PV(0.08/12, 12*10, -100), 6)',
          formula: '=ROUND(PV(0.08/12, 12*10, -100), 6)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ROUND(FV(0.08/12, 12*10, -100), 6)',
          formula: '=ROUND(FV(0.08/12, 12*10, -100), 6)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ROUND(PMT(0.08/12, 12*10, 10000), 6)',
          formula: '=ROUND(PMT(0.08/12, 12*10, 10000), 6)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=PV(0, 10, -100, 0, TRUE)',
          formula: '=PV(0, 10, -100, 0, TRUE)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=PMT(0, 10, 1000)',
          formula: '=PMT(0, 10, 1000)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=FV(0.08/12, 12*10, -100, 0, 2)',
          formula: '=FV(0.08/12, 12*10, -100, 0, 2)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=ROUND(NPER(0.08/12, -100, 8242.148089), 6)',
          formula: '=ROUND(NPER(0.08/12, -100, 8242.148089), 6)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=NPER(0, -100, 1000)',
          formula: '=NPER(0, -100, 1000)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=NPER(0, 0, 1000)',
          formula: '=NPER(0, 0, 1000)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=NPER(0.08/12, -100, 8242.148089, 0, 2)',
          formula: '=NPER(0.08/12, -100, 8242.148089, 0, 2)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ROUND(IPMT(0.08/12, 1, 12*10, 10000), 6)',
          formula: '=ROUND(IPMT(0.08/12, 1, 12*10, 10000), 6)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=ROUND(PPMT(0.08/12, 1, 12*10, 10000), 6)',
          formula: '=ROUND(PPMT(0.08/12, 1, 12*10, 10000), 6)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ROUND(IPMT(0.08/12, 2, 12*10, 10000), 6)',
          formula: '=ROUND(IPMT(0.08/12, 2, 12*10, 10000), 6)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=ROUND(PPMT(0.08/12, 2, 12*10, 10000), 6)',
          formula: '=ROUND(PPMT(0.08/12, 2, 12*10, 10000), 6)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=IPMT(0, 1, 10, 1000)',
          formula: '=IPMT(0, 1, 10, 1000)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=PPMT(0, 1, 10, 1000)',
          formula: '=PPMT(0, 1, 10, 1000)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=IPMT(0.08/12, 0, 12*10, 10000)',
          formula: '=IPMT(0.08/12, 0, 12*10, 10000)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=ROUND(CUMIPMT(0.08/12, 12*10, 10000, 1, 2, 0), 6)',
          formula: '=ROUND(CUMIPMT(0.08/12, 12*10, 10000, 1, 2, 0), 6)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=ROUND(CUMPRINC(0.08/12, 12*10, 10000, 1, 2, 0), 6)',
          formula: '=ROUND(CUMPRINC(0.08/12, 12*10, 10000, 1, 2, 0), 6)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=CUMIPMT(0, 10, 1000, 1, 2, 0)',
          formula: '=CUMIPMT(0, 10, 1000, 1, 2, 0)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=CUMPRINC(0.08/12, 12*10, 10000, 2, 1, 0)',
          formula: '=CUMPRINC(0.08/12, 12*10, 10000, 2, 1, 0)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=ROUND(RATE(12*10, -121.327594, 10000), 6)',
          formula: '=ROUND(RATE(12*10, -121.327594, 10000), 6)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ROUND(RATE(12*10, -100, 8242.148089, 0, 1), 6)',
          formula: '=ROUND(RATE(12*10, -100, 8242.148089, 0, 1), 6)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=RATE(10, -100, 1000)',
          formula: '=RATE(10, -100, 1000)',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12, 100000)',
          formula: '=CUMIPMT(0.1/12, 30*12, 100000)',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24)',
          formula: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=RATE(0, -100, 1000)',
          formula: '=RATE(0, -100, 1000)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=RATE(10, -100, 1000, 0, 2)',
          formula: '=RATE(10, -100, 1000, 0, 2)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=ROUND(PDURATION(0.1, 200, 400), 6)',
          formula: '=ROUND(PDURATION(0.1, 200, 400), 6)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=PDURATION(0, 200, 400)',
          formula: '=PDURATION(0, 200, 400)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=PDURATION(0.1, -200, 400)',
          formula: '=PDURATION(0.1, -200, 400)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=PDURATION("not a number", 200, 400)',
          formula: '=PDURATION("not a number", 200, 400)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=ROUND(RRI(8, 100, 300), 6)',
          formula: '=ROUND(RRI(8, 100, 300), 6)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=RRI(0, 100, 300)',
          formula: '=RRI(0, 100, 300)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=RRI(8, 0, 300)',
          formula: '=RRI(8, 0, 300)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=RRI("not a number", 100, 300)',
          formula: '=RRI("not a number", 100, 300)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=ISPMT(1.1, 2, 16, 1000)',
          formula: '=ISPMT(1.1, 2, 16, 1000)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=ISPMT(1.1, 2, 0, 1000)',
          formula: '=ISPMT(1.1, 2, 0, 1000)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=ISPMT("not a number", 2, 16, 1000)',
          formula: '=ISPMT("not a number", 2, 16, 1000)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=ISPMT()',
          formula: '=ISPMT()',
        ),
        const FortuneCellCoord(6, 7): const FortuneCell(
          value: '=ISPMT(1.1, 2)',
          formula: '=ISPMT(1.1, 2)',
        ),
        const FortuneCellCoord(6, 8): const FortuneCell(
          value: '=ISPMT(1.1, 2, 16)',
          formula: '=ISPMT(1.1, 2, 16)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=ROUND(IPMT(0.2, 6, 24, 1000, 200, 1), 12)',
          formula: '=ROUND(IPMT(0.2, 6, 24, 1000, 200, 1), 12)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=ROUND(PPMT(0.1, 200, 400, 5000), 12)',
          formula: '=ROUND(PPMT(0.1, 200, 400, 5000), 12)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=ROUND(RATE(24, -1000, -10000), 12)',
          formula: '=ROUND(RATE(24, -1000, -10000), 12)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=RATE(24, -1000, -10000, 10000)',
          formula: '=RATE(24, -1000, -10000, 10000)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=ROUND(RATE(24, -1000, -10000, 10000, 1), 12)',
          formula: '=ROUND(RATE(24, -1000, -10000, 10000, 1), 12)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=CUMIPMT()',
          formula: '=CUMIPMT()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=CUMIPMT(0.1/12)',
          formula: '=CUMIPMT(0.1/12)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12)',
          formula: '=CUMIPMT(0.1/12, 30*12)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12, 100000)',
          formula: '=CUMIPMT(0.1/12, 30*12, 100000)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12, 100000, 13)',
          formula: '=CUMIPMT(0.1/12, 30*12, 100000, 13)',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12, 100000, 13, 24)',
          formula: '=CUMIPMT(0.1/12, 30*12, 100000, 13, 24)',
        ),
        const FortuneCellCoord(7, 6): const FortuneCell(
          value: '=CUMIPMT(0.1/12, 30*12, 100000, 13, 24, 0)',
          formula: '=CUMIPMT(0.1/12, 30*12, 100000, 13, 24, 0)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=CUMPRINC()',
          formula: '=CUMPRINC()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=CUMPRINC(0.1/12)',
          formula: '=CUMPRINC(0.1/12)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12)',
          formula: '=CUMPRINC(0.1/12, 30*12)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12, 100000)',
          formula: '=CUMPRINC(0.1/12, 30*12, 100000)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12, 100000, 13)',
          formula: '=CUMPRINC(0.1/12, 30*12, 100000, 13)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24)',
          formula: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24, 0)',
          formula: '=CUMPRINC(0.1/12, 30*12, 100000, 13, 24, 0)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=FV()',
          formula: '=FV()',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=FV(1.1, 10)',
          formula: '=FV(1.1, 10)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=FV(1.1, 10, -200)',
          formula: '=FV(1.1, 10, -200)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=FV(1.1, 10, -200, -500)',
          formula: '=FV(1.1, 10, -200, -500)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=FV(1.1, 10, -200, -500, 1)',
          formula: '=FV(1.1, 10, -200, -500, 1)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=IPMT()',
          formula: '=IPMT()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=IPMT(0.2, 6)',
          formula: '=IPMT(0.2, 6)',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=IPMT(0.2, 6, 24)',
          formula: '=IPMT(0.2, 6, 24)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=IPMT(0.2, 6, 24, 1000)',
          formula: '=IPMT(0.2, 6, 24, 1000)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=IPMT(0.2, 6, 24, 1000, 200)',
          formula: '=IPMT(0.2, 6, 24, 1000, 200)',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=IPMT(0.2, 6, 24, 1000, 200, 1)',
          formula: '=IPMT(0.2, 6, 24, 1000, 200, 1)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=NPER()',
          formula: '=NPER()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=NPER(1.1)',
          formula: '=NPER(1.1)',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=NPER(1.1, -2)',
          formula: '=NPER(1.1, -2)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=NPER(1.1, -2, -100)',
          formula: '=NPER(1.1, -2, -100)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=NPER(1.1, -2, -100, 1000)',
          formula: '=NPER(1.1, -2, -100, 1000)',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=NPER(1.1, -2, -100, 1000, 1)',
          formula: '=NPER(1.1, -2, -100, 1000, 1)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=PDURATION()',
          formula: '=PDURATION()',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=PDURATION(0.1)',
          formula: '=PDURATION(0.1)',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=PDURATION(0.1, 200)',
          formula: '=PDURATION(0.1, 200)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=PDURATION(0.1, 200, 400)',
          formula: '=PDURATION(0.1, 200, 400)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=PMT()',
          formula: '=PMT()',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=PMT(0.1)',
          formula: '=PMT(0.1)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=PMT(0.1, 200)',
          formula: '=PMT(0.1, 200)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=PMT(0.1, 200, 400)',
          formula: '=PMT(0.1, 200, 400)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=PMT(0.1, 200, 400, 500)',
          formula: '=PMT(0.1, 200, 400, 500)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=PPMT()',
          formula: '=PPMT()',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=PPMT(0.1)',
          formula: '=PPMT(0.1)',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=PPMT(0.1, 200)',
          formula: '=PPMT(0.1, 200)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=PPMT(0.1, 200, 400)',
          formula: '=PPMT(0.1, 200, 400)',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=PPMT(0.1, 200, 400, 5000)',
          formula: '=PPMT(0.1, 200, 400, 5000)',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=PV()',
          formula: '=PV()',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=PV(1.1)',
          formula: '=PV(1.1)',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=PV(1.1, 200)',
          formula: '=PV(1.1, 200)',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=PV(1.1, 200, 400)',
          formula: '=PV(1.1, 200, 400)',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=PV(1.1, 200, 400, 5000)',
          formula: '=PV(1.1, 200, 400, 5000)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=PV(1.1, 200, 400, 5000, 1)',
          formula: '=PV(1.1, 200, 400, 5000, 1)',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=RATE()',
          formula: '=RATE()',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=RATE(24)',
          formula: '=RATE(24)',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=RATE(24, -1000)',
          formula: '=RATE(24, -1000)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=RATE(24, -1000, -10000)',
          formula: '=RATE(24, -1000, -10000)',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=RATE(24, -1000, -10000, 10000, 1, 0.1)',
          formula: '=RATE(24, -1000, -10000, 10000, 1, 0.1)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=RRI()',
          formula: '=RRI()',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=RRI(8)',
          formula: '=RRI(8)',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=RRI(8, 100)',
          formula: '=RRI(8, 100)',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=RRI(8, 100, 300)',
          formula: '=RRI(8, 100, 300)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '8242.148089',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '18294.603518',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      '-121.327594',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '1000');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '-100');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '120');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText,
      '-66.666667',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText,
      '-54.660928',
    );
    expect(
      sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText,
      '-66.30226',
    );
    expect(
      sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText,
      '-55.025334',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '-100');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText,
      '-132.968927',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText,
      '-109.686262',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '0.006667');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '0.006796');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '7.272541');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '0.147203');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '-962.5');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 8)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText,
      '-162.874616277321',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText,
      '0.000012207031',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText,
      '-1.207909688697',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '-0.1');
    expect(
      sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText,
      '-0.090909090909',
    );
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(7, 6)]?.renderedText,
      '-9916.772513957079',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText,
      '-614.086327108513',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText,
      '303088.745058200089',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText,
      '1137082.793968250509',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText,
      '1470480.413532270584',
    );
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText,
      '-196.207949610655',
    );
    expect(
      sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText,
      '-195.449539532786',
    );
    expect(
      sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText,
      '-162.874616277321',
    );
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText,
      '-5.425460410277',
    );
    expect(
      sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText,
      '3.08163908268',
    );
    expect(
      sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText,
      '3.058108732154',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText,
      '7.272540897342',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText,
      '-40.000000210631',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText,
      '-40.00000047392',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText,
      '0.000012207031',
    );
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText,
      '-363.636363636364',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText,
      '-363.636363636364',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText,
      '-763.636363636364',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText,
      '-1.207909688697',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText,
      '-0.090909090909',
    );
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText,
      '0.14720269044',
    );
  });

  test('formula engine evaluates depreciation financial helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=SLN(300000, 75000, 10)',
          formula: '=SLN(300000, 75000, 10)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ROUND(SYD(100, 50, 10, 2), 6)',
          formula: '=ROUND(SYD(100, 50, 10, 2), 6)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=SLN(100, 10, 0)',
          formula: '=SLN(100, 10, 0)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SYD(100, 10, 5, 0)',
          formula: '=SYD(100, 10, 5, 0)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=SYD(100, 10, 5, 6)',
          formula: '=SYD(100, 10, 5, 6)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=DDB(2400, 300, 10, 1)',
          formula: '=DDB(2400, 300, 10, 1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=DDB(2400, 300, 10, 2)',
          formula: '=DDB(2400, 300, 10, 2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=ROUND(DDB(2400, 300, 10, 10), 6)',
          formula: '=ROUND(DDB(2400, 300, 10, 10), 6)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=DDB(2400, 300, 10, 1, 1.5)',
          formula: '=DDB(2400, 300, 10, 1, 1.5)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=DDB(2400, 300, 10, 0)',
          formula: '=DDB(2400, 300, 10, 0)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=DDB(2400, 300, 10, 1, 0)',
          formula: '=DDB(2400, 300, 10, 1, 0)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=DB(1000000, 100000, 6, 1)',
          formula: '=DB(1000000, 100000, 6, 1)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=DB(1000000, 100000, 6, 2)',
          formula: '=DB(1000000, 100000, 6, 2)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=DB(0, 0, 6, 1)',
          formula: '=DB(0, 0, 6, 1)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=DB(1000000, 100000, 6, 1, 6)',
          formula: '=DB(1000000, 100000, 6, 1, 6)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=DB(1000000, 100000, 6, 1, 0)',
          formula: '=DB(1000000, 100000, 6, 1, 0)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=DB(1000000, 100000, 6, 7)',
          formula: '=DB(1000000, 100000, 6, 7)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=VDB(2400, 300, 10, 0, 1)',
          formula: '=VDB(2400, 300, 10, 0, 1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=VDB(2400, 300, 10, 0, 2)',
          formula: '=VDB(2400, 300, 10, 0, 2)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=ROUND(VDB(2400, 300, 10, 0, 10, 1), 6)',
          formula: '=ROUND(VDB(2400, 300, 10, 0, 10, 1), 6)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=ROUND(VDB(2400, 300, 10, 0, 10, 1, TRUE), 6)',
          formula: '=ROUND(VDB(2400, 300, 10, 0, 10, 1, TRUE), 6)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=ROUND(VDB(2400, 300, 10, 0.5, 1.5), 6)',
          formula: '=ROUND(VDB(2400, 300, 10, 0.5, 1.5), 6)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=VDB(2400, 300, 10, 2, 1)',
          formula: '=VDB(2400, 300, 10, 2, 1)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=VDB(2400, 300, 10, 0, 1, 0)',
          formula: '=VDB(2400, 300, 10, 0, 1, 0)',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 0, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 0, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 1, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 1, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 8): const FortuneCell(
          value:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 6, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 6, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 9): const FortuneCell(
          value: '=AMORLINC(2400, "2024-07-01", "2024-01-01", 300, 1, 0.15, 3)',
          formula:
              '=AMORLINC(2400, "2024-07-01", "2024-01-01", 300, 1, 0.15, 3)',
        ),
        const FortuneCellCoord(3, 10): const FortuneCell(
          value: '=AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 1, 0, 3)',
          formula: '=AMORLINC(2400, "2024-01-01", "2024-07-01", 300, 1, 0, 3)',
        ),
        const FortuneCellCoord(3, 11): const FortuneCell(
          value:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 0, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 0, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 12): const FortuneCell(
          value:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 1, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 1, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 13): const FortuneCell(
          value:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 5, 0.15, 3), 6)',
          formula:
              '=ROUND(AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 5, 0.15, 3), 6)',
        ),
        const FortuneCellCoord(3, 14): const FortuneCell(
          value:
              '=AMORDEGRC(2400, "2024-07-01", "2024-01-01", 300, 1, 0.15, 3)',
          formula:
              '=AMORDEGRC(2400, "2024-07-01", "2024-01-01", 300, 1, 0.15, 3)',
        ),
        const FortuneCellCoord(3, 15): const FortuneCell(
          value: '=AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 1, 0, 3)',
          formula: '=AMORDEGRC(2400, "2024-01-01", "2024-07-01", 300, 1, 0, 3)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=DB()',
          formula: '=DB()',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=DB(10000)',
          formula: '=DB(10000)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=DB(10000, 1000)',
          formula: '=DB(10000, 1000)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=DB(10000, 1000, 6)',
          formula: '=DB(10000, 1000, 6)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=DB(10000, 1000, 6, 1)',
          formula: '=DB(10000, 1000, 6, 1)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=DDB()',
          formula: '=DDB()',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=DDB(10000)',
          formula: '=DDB(10000)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=DDB(10000, 1000)',
          formula: '=DDB(10000, 1000)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=DDB(10000, 1000, 6)',
          formula: '=DDB(10000, 1000, 6)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=DDB(10000, 1000, 6, 1)',
          formula: '=DDB(10000, 1000, 6, 1)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=SLN()',
          formula: '=SLN()',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=SLN(200)',
          formula: '=SLN(200)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=SLN(200, 750)',
          formula: '=SLN(200, 750)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=SLN(200, 750, 10)',
          formula: '=SLN(200, 750, 10)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=SYD()',
          formula: '=SYD()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=SYD(200)',
          formula: '=SYD(200)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=SYD(200, 750)',
          formula: '=SYD(200, 750)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=SYD(200, 750, 10)',
          formula: '=SYD(200, 750, 10)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=SYD(200, 750, 10, 1)',
          formula: '=SYD(200, 750, 10, 1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '22500');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '8.181818');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '480');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '384');
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '22.122547',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '360');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '319000');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '217239');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '159500');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '480');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '864');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '2100');
    expect(
      sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText,
      '1563.171744',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '432');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText,
      '179.506849',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '360');
    expect(
      sheet.cells[const FortuneCellCoord(3, 8)]?.renderedText,
      '120.493151',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 10)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(3, 11)]?.renderedText,
      '448.767123',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 12)]?.renderedText,
      '731.712329',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 13)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(3, 14)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 15)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '3190');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText,
      '3333.333333333333',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '-55');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '-100');
  });

  test('formula engine evaluates cash flow financial helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ROUND(NPV(0.1, {-10000,3000,4200,6800}), 6)',
          formula: '=ROUND(NPV(0.1, {-10000,3000,4200,6800}), 6)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=ROUND(-40000+NPV(0.08,{8000,9200,10000,12000,14500}), 6)',
          formula: '=ROUND(-40000+NPV(0.08,{8000,9200,10000,12000,14500}), 6)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=NPV(0, {1,2,3})',
          formula: '=NPV(0, {1,2,3})',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=NPV(-1, {1,2,3})',
          formula: '=NPV(-1, {1,2,3})',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=NPV(0.1, "x")',
          formula: '=NPV(0.1, "x")',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value:
              '=ROUND(MIRR({-120000,39000,30000,21000,37000,46000},0.1,0.12),6)',
          formula:
              '=ROUND(MIRR({-120000,39000,30000,21000,37000,46000},0.1,0.12),6)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=NPV(1.1)',
          formula: '=NPV(1.1)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=MIRR({100,200},0.1,0.12)',
          formula: '=MIRR({100,200},0.1,0.12)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=MIRR({-100,-200},0.1,0.12)',
          formula: '=MIRR({-100,-200},0.1,0.12)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=MIRR({-100,200},-1,0.12)',
          formula: '=MIRR({-100,200},-1,0.12)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ROUND(IRR({-70000,12000,15000,18000,21000,26000}),6)',
          formula: '=ROUND(IRR({-70000,12000,15000,18000,21000,26000}),6)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ROUND(IRR({-100,39,59,55,20},0.2),6)',
          formula: '=ROUND(IRR({-100,39,59,55,20},0.2),6)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=IRR({100,200})',
          formula: '=IRR({100,200})',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value:
              '=ROUND(XNPV(0.09,{-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"}),6)',
          formula:
              '=ROUND(XNPV(0.09,{-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"}),6)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=XNPV(-1, {1,2}, {"2024-01-01","2024-02-01"})',
          formula: '=XNPV(-1, {1,2}, {"2024-01-01","2024-02-01"})',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=XNPV(0.1, {1,2}, {"2024-01-01"})',
          formula: '=XNPV(0.1, {1,2}, {"2024-01-01"})',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=XNPV(0.1, {1}, {"not a date"})',
          formula: '=XNPV(0.1, {1}, {"not a date"})',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"}),6)',
          formula:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"}),6)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"},0.2),6)',
          formula:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"2018-01-01","2018-03-01","2018-10-30","2019-02-15","2019-04-01"},0.2),6)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=XIRR({100,200}, {"2024-01-01","2024-02-01"})',
          formula: '=XIRR({100,200}, {"2024-01-01","2024-02-01"})',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=XIRR({-100,200}, {"2024-01-01"})',
          formula: '=XIRR({-100,200}, {"2024-01-01"})',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=XIRR({-100,200}, {"not a date","2024-02-01"})',
          formula: '=XIRR({-100,200}, {"not a date","2024-02-01"})',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=IRR({-75000,12000,15000,18000,21000,24000})',
          formula: '=IRR({-75000,12000,15000,18000,21000,24000})',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=MIRR({-75000,12000,15000,18000,21000,24000},0.1,0.12)',
          formula: '=MIRR({-75000,12000,15000,18000,21000,24000},0.1,0.12)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=NPV()',
          formula: '=NPV()',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=NPV(1.1, -2)',
          formula: '=NPV(1.1, -2)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=NPV(1.1, -2, -100)',
          formula: '=NPV(1.1, -2, -100)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=NPV(1.1, -2, -100, 1000)',
          formula: '=NPV(1.1, -2, -100, 1000)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=NPV(1.1, -2, -100, 1000, 1)',
          formula: '=NPV(1.1, -2, -100, 1000, 1)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value:
              '=XNPV(0.09,{-10000,2750,4250,3250,2750},{"01/01/2008","03/01/2008","10/30/2008","02/15/2009","04/01/2009"})',
          formula:
              '=XNPV(0.09,{-10000,2750,4250,3250,2750},{"01/01/2008","03/01/2008","10/30/2008","02/15/2009","04/01/2009"})',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"01/jan/08","01/mar/08","30/oct/08","15/feb/09","01/apr/09"},0.1),6)',
          formula:
              '=ROUND(XIRR({-10000,2750,4250,3250,2750},{"01/jan/08","01/mar/08","30/oct/08","15/feb/09","01/apr/09"},0.1),6)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '1188.443412',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      '1922.061555',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '0.126094');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '0.086631');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '0.280948');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText,
      '2089.501636',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '0.374859');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '0.374859');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText,
      '0.057151428872',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText,
      '0.079717103608',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText,
      '-0.952380952381',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText,
      '-23.628117913832',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText,
      '84.351581902602',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText,
      '84.403000807277',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText,
      '2086.647602031535',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '0.373363');
  });

  test('formula engine evaluates cash flow financial range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '-75000'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '12000'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '15000'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: '18000'),
        const FortuneCellCoord(0, 4): const FortuneCell(value: '21000'),
        const FortuneCellCoord(0, 5): const FortuneCell(value: '24000'),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=IRR(A1:F1)',
          formula: '=IRR(A1:F1)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=MIRR(A1:F1,0.1,0.12)',
          formula: '=MIRR(A1:F1,0.1,0.12)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=MIRR(A1:F1, 0.1, 0.12)',
          formula: '=MIRR(A1:F1, 0.1, 0.12)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '-10000'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '2750'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '4250'),
        const FortuneCellCoord(2, 3): const FortuneCell(value: '3250'),
        const FortuneCellCoord(2, 4): const FortuneCell(value: '2750'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: '01/01/2008'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '03/01/2008'),
        const FortuneCellCoord(3, 2): const FortuneCell(value: '10/30/2008'),
        const FortuneCellCoord(3, 3): const FortuneCell(value: '02/15/2009'),
        const FortuneCellCoord(3, 4): const FortuneCell(value: '04/01/2009'),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=XNPV(0.09,A3:E3,A4:E4)',
          formula: '=XNPV(0.09,A3:E3,A4:E4)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=XNPV(0.09, A3:E3, A4:E4)',
          formula: '=XNPV(0.09, A3:E3, A4:E4)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '0.057151428872',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '0.079717103608',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
      '0.079717103608',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText,
      '2086.647602031535',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText,
      '2086.647602031535',
    );
  });

  test('formula engine evaluates security rate financial helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value:
              '=ROUND(INTRATE("2024-01-01", "2024-07-01", 100000, 103000, 3), 6)',
          formula:
              '=ROUND(INTRATE("2024-01-01", "2024-07-01", 100000, 103000, 3), 6)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value:
              '=ROUND(RECEIVED("2024-01-01", "2024-07-01", 100000, 0.05, 3), 0)',
          formula:
              '=ROUND(RECEIVED("2024-01-01", "2024-07-01", 100000, 0.05, 3), 0)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=ROUND(DISC("2024-01-01", "2024-07-01", 97, 100, 3), 6)',
          formula: '=ROUND(DISC("2024-01-01", "2024-07-01", 97, 100, 3), 6)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=INTRATE("2024-07-01", "2024-01-01", 100000, 103000, 3)',
          formula: '=INTRATE("2024-07-01", "2024-01-01", 100000, 103000, 3)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=RECEIVED("2024-01-01", "2024-07-01", 100000, 3, 3)',
          formula: '=RECEIVED("2024-01-01", "2024-07-01", 100000, 3, 3)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=DISC("2024-01-01", "2024-07-01", 0, 100, 3)',
          formula: '=DISC("2024-01-01", "2024-07-01", 0, 100, 3)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=DISC("not a date", "2024-07-01", 97, 100, 3)',
          formula: '=DISC("not a date", "2024-07-01", 97, 100, 3)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=INTRATE("2024-01-01", "2024-07-01", 100000, 103000, 9)',
          formula: '=INTRATE("2024-01-01", "2024-07-01", 100000, 103000, 9)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value:
              '=ROUND(PRICEDISC("2024-01-01", "2024-07-01", 0.05, 100, 3), 6)',
          formula:
              '=ROUND(PRICEDISC("2024-01-01", "2024-07-01", 0.05, 100, 3), 6)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ROUND(YIELDDISC("2024-01-01", "2024-07-01", 97, 100, 3), 6)',
          formula:
              '=ROUND(YIELDDISC("2024-01-01", "2024-07-01", 97, 100, 3), 6)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=PRICEDISC("2024-01-01", "2024-07-01", 3, 100, 3)',
          formula: '=PRICEDISC("2024-01-01", "2024-07-01", 3, 100, 3)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=YIELDDISC("2024-01-01", "2024-07-01", 0, 100, 3)',
          formula: '=YIELDDISC("2024-01-01", "2024-07-01", 0, 100, 3)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ROUND(TBILLPRICE("2024-01-01", "2024-07-01", 0.05), 6)',
          formula: '=ROUND(TBILLPRICE("2024-01-01", "2024-07-01", 0.05), 6)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=ROUND(TBILLYIELD("2024-01-01", "2024-07-01", 97), 6)',
          formula: '=ROUND(TBILLYIELD("2024-01-01", "2024-07-01", 97), 6)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=ROUND(TBILLEQ("2024-01-01", "2024-07-01", 0.05), 6)',
          formula: '=ROUND(TBILLEQ("2024-01-01", "2024-07-01", 0.05), 6)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=TBILLPRICE("2024-07-01", "2024-01-01", 0.05)',
          formula: '=TBILLPRICE("2024-07-01", "2024-01-01", 0.05)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=TBILLPRICE("2024-01-01", "2025-01-01", 0.05)',
          formula: '=TBILLPRICE("2024-01-01", "2025-01-01", 0.05)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=TBILLYIELD("2024-01-01", "2024-07-01", 0)',
          formula: '=TBILLYIELD("2024-01-01", "2024-07-01", 0)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=TBILLEQ("not a date", "2024-07-01", 0.05)',
          formula: '=TBILLEQ("not a date", "2024-07-01", 0.05)',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=ROUND(TBILLEQ("03/31/2008", "06/01/2008", 0.09), 12)',
          formula: '=ROUND(TBILLEQ("03/31/2008", "06/01/2008", 0.09), 12)',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=TBILLPRICE("03/31/2008", "06/01/2008", 0.09)',
          formula: '=TBILLPRICE("03/31/2008", "06/01/2008", 0.09)',
        ),
        const FortuneCellCoord(3, 8): const FortuneCell(
          value: '=ROUND(TBILLYIELD("03/31/2008", "06/01/2008", 0.09), 12)',
          formula: '=ROUND(TBILLYIELD("03/31/2008", "06/01/2008", 0.09), 12)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value:
              '=ROUND(ACCRINTM("2024-01-01", "2024-07-01", 0.05, 1000, 3), 6)',
          formula:
              '=ROUND(ACCRINTM("2024-01-01", "2024-07-01", 0.05, 1000, 3), 6)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=ACCRINTM("2024-07-01", "2024-01-01", 0.05, 1000, 3)',
          formula: '=ACCRINTM("2024-07-01", "2024-01-01", 0.05, 1000, 3)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=ACCRINTM("2024-01-01", "2024-07-01", 0, 1000, 3)',
          formula: '=ACCRINTM("2024-01-01", "2024-07-01", 0, 1000, 3)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ACCRINTM("not a date", "2024-07-01", 0.05, 1000, 3)',
          formula: '=ACCRINTM("not a date", "2024-07-01", 0.05, 1000, 3)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value:
              '=ROUND(PRICEMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 0.06, 3), 6)',
          formula:
              '=ROUND(PRICEMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 0.06, 3), 6)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value:
              '=PRICEMAT("2024-01-01", "2024-07-01", "2024-04-01", 0.05, 0.06, 3)',
          formula:
              '=PRICEMAT("2024-01-01", "2024-07-01", "2024-04-01", 0.05, 0.06, 3)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value:
              '=PRICEMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, -0.01, 3)',
          formula:
              '=PRICEMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, -0.01, 3)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value:
              '=PRICEMAT("not a date", "2024-07-01", "2024-01-01", 0.05, 0.06, 3)',
          formula:
              '=PRICEMAT("not a date", "2024-07-01", "2024-01-01", 0.05, 0.06, 3)',
        ),
        const FortuneCellCoord(4, 6): const FortuneCell(
          value:
              '=ROUND(YIELDMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 99.735987, 3), 6)',
          formula:
              '=ROUND(YIELDMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 99.735987, 3), 6)',
        ),
        const FortuneCellCoord(4, 7): const FortuneCell(
          value:
              '=YIELDMAT("2024-01-01", "2024-07-01", "2024-04-01", 0.05, 99.735987, 3)',
          formula:
              '=YIELDMAT("2024-01-01", "2024-07-01", "2024-04-01", 0.05, 99.735987, 3)',
        ),
        const FortuneCellCoord(4, 8): const FortuneCell(
          value:
              '=YIELDMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 0, 3)',
          formula:
              '=YIELDMAT("2024-04-01", "2024-07-01", "2024-01-01", 0.05, 0, 3)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value:
              '=ROUND(ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, TRUE), 6)',
          formula:
              '=ROUND(ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, TRUE), 6)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value:
              '=ROUND(ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, FALSE), 6)',
          formula:
              '=ROUND(ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, FALSE), 6)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value:
              '=ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 3, 0, TRUE)',
          formula:
              '=ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0.1, 1000, 3, 0, TRUE)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value:
              '=ACCRINT("not a date", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, TRUE)',
          formula:
              '=ACCRINT("not a date", "2012-03-30", "2013-12-04", 0.1, 1000, 1, 0, TRUE)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value:
              '=ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0, 1000, 1, 0, TRUE)',
          formula:
              '=ACCRINT("2012-02-02", "2012-03-30", "2013-12-04", 0, 1000, 1, 0, TRUE)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value:
              '=ROUND(DURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 1, 0), 6)',
          formula:
              '=ROUND(DURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 1, 0), 6)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value:
              '=ROUND(MDURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 1, 0), 6)',
          formula:
              '=ROUND(MDURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 1, 0), 6)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=DURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 3, 3)',
          formula: '=DURATION("2024-01-01", "2027-01-01", 0.05, 0.06, 3, 3)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=DURATION("not a date", "2027-01-01", 0.05, 0.06, 1, 3)',
          formula: '=DURATION("not a date", "2027-01-01", 0.05, 0.06, 1, 3)',
        ),
        const FortuneCellCoord(5, 6): const FortuneCell(
          value: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013")',
          formula: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013")',
        ),
        const FortuneCellCoord(5, 7): const FortuneCell(
          value: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1)',
          formula:
              '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1)',
        ),
        const FortuneCellCoord(5, 8): const FortuneCell(
          value: '=ACCRINT()',
          formula: '=ACCRINT()',
        ),
        const FortuneCellCoord(5, 9): const FortuneCell(
          value: '=ACCRINT("2/2/2012")',
          formula: '=ACCRINT("2/2/2012")',
        ),
        const FortuneCellCoord(5, 10): const FortuneCell(
          value: '=ACCRINT("2/2/2012", "3/30/2012")',
          formula: '=ACCRINT("2/2/2012", "3/30/2012")',
        ),
        const FortuneCellCoord(5, 11): const FortuneCell(
          value: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1)',
          formula: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1)',
        ),
        const FortuneCellCoord(5, 12): const FortuneCell(
          value: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000)',
          formula: '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000)',
        ),
        const FortuneCellCoord(5, 13): const FortuneCell(
          value:
              '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1, 0)',
          formula:
              '=ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1, 0)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=MDURATION("2024-01-01", "2027-01-01", 0.05, -0.01, 1, 3)',
          formula: '=MDURATION("2024-01-01", "2027-01-01", 0.05, -0.01, 1, 3)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=COUPNUM("2024-01-01", "2027-01-01", 1, 0)',
          formula: '=COUPNUM("2024-01-01", "2027-01-01", 1, 0)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=COUPNUM("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPNUM("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=COUPNUM("2024-01-01", "2027-01-01", 3, 0)',
          formula: '=COUPNUM("2024-01-01", "2027-01-01", 3, 0)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=COUPNUM("not a date", "2027-01-01", 1, 0)',
          formula: '=COUPNUM("not a date", "2027-01-01", 1, 0)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=COUPNUM("2024-01-01", "2027-01-01", 1, 9)',
          formula: '=COUPNUM("2024-01-01", "2027-01-01", 1, 9)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=COUPNCD("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPNCD("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=COUPPCD("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPPCD("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=COUPNCD("2024-01-01", "2027-01-01", 3, 0)',
          formula: '=COUPNCD("2024-01-01", "2027-01-01", 3, 0)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=COUPPCD("not a date", "2027-01-01", 1, 0)',
          formula: '=COUPPCD("not a date", "2027-01-01", 1, 0)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=COUPDAYBS("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPDAYBS("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=COUPDAYS("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPDAYS("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=COUPDAYSNC("2024-04-15", "2025-01-01", 2, 0)',
          formula: '=COUPDAYSNC("2024-04-15", "2025-01-01", 2, 0)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=COUPDAYS("2024-01-01", "2027-01-01", 3, 0)',
          formula: '=COUPDAYS("2024-01-01", "2027-01-01", 3, 0)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=COUPDAYBS("not a date", "2027-01-01", 1, 0)',
          formula: '=COUPDAYBS("not a date", "2027-01-01", 1, 0)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value:
              '=ROUND(PRICE("2024-04-15", "2025-01-01", 0.05, 0.06, 100, 2, 0), 6)',
          formula:
              '=ROUND(PRICE("2024-04-15", "2025-01-01", 0.05, 0.06, 100, 2, 0), 6)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=PRICE("2024-04-15", "2025-01-01", 0.05, -0.01, 100, 2, 0)',
          formula: '=PRICE("2024-04-15", "2025-01-01", 0.05, -0.01, 100, 2, 0)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=PRICE("2024-04-15", "2025-01-01", 0.05, 0.06, 100, 3, 0)',
          formula: '=PRICE("2024-04-15", "2025-01-01", 0.05, 0.06, 100, 3, 0)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=PRICE("not a date", "2025-01-01", 0.05, 0.06, 100, 2, 0)',
          formula: '=PRICE("not a date", "2025-01-01", 0.05, 0.06, 100, 2, 0)',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value:
              '=ROUND(YIELD("2024-04-15", "2025-01-01", 0.05, 99.30485, 100, 2, 0), 6)',
          formula:
              '=ROUND(YIELD("2024-04-15", "2025-01-01", 0.05, 99.30485, 100, 2, 0), 6)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=YIELD("2024-04-15", "2025-01-01", 0.05, 0, 100, 2, 0)',
          formula: '=YIELD("2024-04-15", "2025-01-01", 0.05, 0, 100, 2, 0)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=YIELD("2024-04-15", "2025-01-01", 0.05, 99, 100, 3, 0)',
          formula: '=YIELD("2024-04-15", "2025-01-01", 0.05, 99, 100, 3, 0)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=YIELD("not a date", "2025-01-01", 0.05, 99, 100, 2, 0)',
          formula: '=YIELD("not a date", "2025-01-01", 0.05, 99, 100, 2, 0)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value:
              '=ROUND(ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 2, 3), 6)',
          formula:
              '=ROUND(ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 2, 3), 6)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value:
              '=ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, -0.01, 100, 2, 3)',
          formula:
              '=ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, -0.01, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value:
              '=ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 3, 3)',
          formula:
              '=ODDLPRICE("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 3, 3)',
        ),
        const FortuneCellCoord(9, 8): const FortuneCell(
          value:
              '=ODDLPRICE("not a date", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 2, 3)',
          formula:
              '=ODDLPRICE("not a date", "2025-03-01", "2025-01-01", 0.05, 0.06, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 9): const FortuneCell(
          value:
              '=ROUND(ODDLYIELD("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 99.12273, 100, 2, 3), 6)',
          formula:
              '=ROUND(ODDLYIELD("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 99.12273, 100, 2, 3), 6)',
        ),
        const FortuneCellCoord(9, 10): const FortuneCell(
          value:
              '=ODDLYIELD("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0, 100, 2, 3)',
          formula:
              '=ODDLYIELD("2024-04-01", "2025-03-01", "2025-01-01", 0.05, 0, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 11): const FortuneCell(
          value:
              '=ODDLYIELD("not a date", "2025-03-01", "2025-01-01", 0.05, 99.12273, 100, 2, 3)',
          formula:
              '=ODDLYIELD("not a date", "2025-03-01", "2025-01-01", 0.05, 99.12273, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 12): const FortuneCell(
          value:
              '=ROUND(ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0.06, 100, 2, 3), 6)',
          formula:
              '=ROUND(ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0.06, 100, 2, 3), 6)',
        ),
        const FortuneCellCoord(9, 13): const FortuneCell(
          value:
              '=ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, -0.01, 100, 2, 3)',
          formula:
              '=ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, -0.01, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 14): const FortuneCell(
          value:
              '=ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0.06, 100, 3, 3)',
          formula:
              '=ODDFPRICE("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0.06, 100, 3, 3)',
        ),
        const FortuneCellCoord(9, 15): const FortuneCell(
          value:
              '=ROUND(ODDFYIELD("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 99.18895, 100, 2, 3), 6)',
          formula:
              '=ROUND(ODDFYIELD("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 99.18895, 100, 2, 3), 6)',
        ),
        const FortuneCellCoord(9, 16): const FortuneCell(
          value:
              '=ODDFYIELD("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0, 100, 2, 3)',
          formula:
              '=ODDFYIELD("2024-03-01", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 0, 100, 2, 3)',
        ),
        const FortuneCellCoord(9, 17): const FortuneCell(
          value:
              '=ODDFYIELD("not a date", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 99.18895, 100, 2, 3)',
          formula:
              '=ODDFYIELD("not a date", "2025-01-01", "2024-01-01", "2024-07-01", 0.05, 99.18895, 100, 2, 3)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=TBILLEQ()',
          formula: '=TBILLEQ()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=TBILLEQ("03/31/2008")',
          formula: '=TBILLEQ("03/31/2008")',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=TBILLEQ("03/31/2008", "06/01/2008")',
          formula: '=TBILLEQ("03/31/2008", "06/01/2008")',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=TBILLPRICE()',
          formula: '=TBILLPRICE()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=TBILLPRICE("03/31/2008")',
          formula: '=TBILLPRICE("03/31/2008")',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=TBILLPRICE("03/31/2008", "06/01/2008")',
          formula: '=TBILLPRICE("03/31/2008", "06/01/2008")',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=TBILLYIELD()',
          formula: '=TBILLYIELD()',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=TBILLYIELD("03/31/2008")',
          formula: '=TBILLYIELD("03/31/2008")',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=TBILLYIELD("03/31/2008", "06/01/2008")',
          formula: '=TBILLYIELD("03/31/2008", "06/01/2008")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0.060165');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '102557');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '0.060165');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
      '97.506849',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '0.062026');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '97.5');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '0.061856');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '0.051994');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText,
      '0.092663112465',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '98.475');
    expect(
      sheet.cells[const FortuneCellCoord(3, 8)]?.renderedText,
      '6551.475409836065',
    );
    expect(
      sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText,
      '24.931507',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText,
      '99.735987',
    );
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 6)]?.renderedText, '0.06');
    expect(sheet.cells[const FortuneCellCoord(4, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(4, 8)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText,
      '183.888889',
    );
    expect(
      sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText,
      '167.777778',
    );
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '2.857347');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '2.695611');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 11)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 12)]?.renderedText, '#NUM!');
    expect(
      sheet.cells[const FortuneCellCoord(5, 13)]?.renderedText,
      '183.888888888889',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '45474');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '45292');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '104');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '180');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '76');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '99.30485');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '0.06');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '99.12273');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 9)]?.renderedText, '0.06');
    expect(sheet.cells[const FortuneCellCoord(9, 10)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 11)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(9, 12)]?.renderedText,
      '99.18895',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 13)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 14)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 15)]?.renderedText, '0.06');
    expect(sheet.cells[const FortuneCellCoord(9, 16)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(9, 17)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '#VALUE!');
  });

  test('formula engine evaluates trigonometric and random helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=ROUND(DEGREES(ATAN2(1, 1)), 6)',
          formula: '=ROUND(DEGREES(ATAN2(1, 1)), 6)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=SINH(0)',
          formula: '=SINH(0)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=COSH(0)',
          formula: '=COSH(0)',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=TANH(0)',
          formula: '=TANH(0)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=ASINH(0)',
          formula: '=ASINH(0)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=ACOSH(1)',
          formula: '=ACOSH(1)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=ASINH()',
          formula: '=ASINH()',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=ASINH("value")',
          formula: '=ASINH("value")',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=ASINH(0.5)',
          formula: '=ASINH(0.5)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=ATANH(0)',
          formula: '=ATANH(0)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=ACOSH(0)',
          formula: '=ACOSH(0)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=ATANH(1)',
          formula: '=ATANH(1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=MROUND(10, 3)',
          formula: '=MROUND(10, 3)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=MROUND(-10, -3)',
          formula: '=MROUND(-10, -3)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=MROUND(10, -3)',
          formula: '=MROUND(10, -3)',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=ATANH()',
          formula: '=ATANH()',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=ATANH("value")',
          formula: '=ATANH("value")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=RAND()',
          formula: '=RAND()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=RANDBETWEEN(1, 3)',
          formula: '=RANDBETWEEN(1, 3)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=RANDBETWEEN(3, 1)',
          formula: '=RANDBETWEEN(3, 1)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=ATAN2(0, 0)',
          formula: '=ATAN2(0, 0)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=RANDBETWEEN(-5, -3)',
          formula: '=RANDBETWEEN(-5, -3)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=SEC(0)',
          formula: '=SEC(0)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=CSC(0)',
          formula: '=CSC(0)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=ROUND(COT(PI()/4), 6)',
          formula: '=ROUND(COT(PI()/4), 6)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=ROUND(ACOT(1), 6)',
          formula: '=ROUND(ACOT(1), 6)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ROUND(ACOT(-1), 6)',
          formula: '=ROUND(ACOT(-1), 6)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=COT(0)',
          formula: '=COT(0)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=SECH(0)',
          formula: '=SECH(0)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=CSCH(0)',
          formula: '=CSCH(0)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=COTH(0)',
          formula: '=COTH(0)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=ROUND(ACOTH(2), 6)',
          formula: '=ROUND(ACOTH(2), 6)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=ACOTH(1)',
          formula: '=ACOTH(1)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=ACOTH(-1)',
          formula: '=ACOTH(-1)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=SINH(1000)',
          formula: '=SINH(1000)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=COSH(1000)',
          formula: '=COSH(1000)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=TANH(1000)',
          formula: '=TANH(1000)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=TANH(-1000)',
          formula: '=TANH(-1000)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=COTH(1000)',
          formula: '=COTH(1000)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=ROUND(ASINH(10^308), 6)',
          formula: '=ROUND(ASINH(10^308), 6)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=ROUND(ASINH(-(10^308)), 6)',
          formula: '=ROUND(ASINH(-(10^308)), 6)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=ROUND(ACOSH(10^308), 6)',
          formula: '=ROUND(ACOSH(10^308), 6)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=CSCH(1000)',
          formula: '=CSCH(1000)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=CSCH(-1000)',
          formula: '=CSCH(-1000)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=MROUND(14*10^307, 9*10^307)',
          formula: '=MROUND(14*10^307, 9*10^307)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=MROUND()',
          formula: '=MROUND()',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=MROUND("value")',
          formula: '=MROUND("value")',
        ),
        const FortuneCellCoord(6, 7): const FortuneCell(
          value: '=MROUND(1)',
          formula: '=MROUND(1)',
        ),
        const FortuneCellCoord(6, 8): const FortuneCell(
          value: '=MROUND(1, 2)',
          formula: '=MROUND(1, 2)',
        ),
        const FortuneCellCoord(6, 9): const FortuneCell(
          value: '=MROUND(3, 2)',
          formula: '=MROUND(3, 2)',
        ),
        const FortuneCellCoord(6, 10): const FortuneCell(
          value: '=MROUND(-4, 1.1)',
          formula: '=MROUND(-4, 1.1)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=ACOS()',
          formula: '=ACOS()',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=ACOS(1)',
          formula: '=ACOS(1)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=ACOS(-1)',
          formula: '=ACOS(-1)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=ASIN()',
          formula: '=ASIN()',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=ASIN("value")',
          formula: '=ASIN("value")',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=ASIN(0.5)',
          formula: '=ASIN(0.5)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=ATAN()',
          formula: '=ATAN()',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=ATAN("value")',
          formula: '=ATAN("value")',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=ATAN(0.5)',
          formula: '=ATAN(0.5)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=ACOSH()',
          formula: '=ACOSH()',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=ACOSH(-1)',
          formula: '=ACOSH(-1)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=ACOT()',
          formula: '=ACOT()',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=ACOT(1)',
          formula: '=ACOT(1)',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=ACOT(-1)',
          formula: '=ACOT(-1)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=ACOTH()',
          formula: '=ACOTH()',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=ATAN2()',
          formula: '=ATAN2()',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=ATAN2(1)',
          formula: '=ATAN2(1)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=ATAN2("value")',
          formula: '=ATAN2("value")',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=ATAN2(1, 1)',
          formula: '=ATAN2(1, 1)',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=COS()',
          formula: '=COS()',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=COS("value")',
          formula: '=COS("value")',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=COS(1)',
          formula: '=COS(1)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=COSH()',
          formula: '=COSH()',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=COSH("value")',
          formula: '=COSH("value")',
        ),
        const FortuneCellCoord(10, 6): const FortuneCell(
          value: '=COSH(1)',
          formula: '=COSH(1)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=COT()',
          formula: '=COT()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=COT("value")',
          formula: '=COT("value")',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=COT(1)',
          formula: '=COT(1)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=COT(2)',
          formula: '=COT(2)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=COTH()',
          formula: '=COTH()',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=COTH("value")',
          formula: '=COTH("value")',
        ),
        const FortuneCellCoord(11, 6): const FortuneCell(
          value: '=COTH(1)',
          formula: '=COTH(1)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=COTH(2)',
          formula: '=COTH(2)',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=CSC()',
          formula: '=CSC()',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=CSC("value")',
          formula: '=CSC("value")',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=CSC(1)',
          formula: '=CSC(1)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=CSC(2)',
          formula: '=CSC(2)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=CSCH()',
          formula: '=CSCH()',
        ),
        const FortuneCellCoord(12, 6): const FortuneCell(
          value: '=CSCH("value")',
          formula: '=CSCH("value")',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=CSCH(1)',
          formula: '=CSCH(1)',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=CSCH(2)',
          formula: '=CSCH(2)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=SEC()',
          formula: '=SEC()',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=SEC("value")',
          formula: '=SEC("value")',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=SEC(1)',
          formula: '=SEC(1)',
        ),
        const FortuneCellCoord(13, 5): const FortuneCell(
          value: '=SEC(30)',
          formula: '=SEC(30)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=SECH()',
          formula: '=SECH()',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=SECH("value")',
          formula: '=SECH("value")',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=SECH(1)',
          formula: '=SECH(1)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=SECH(30)',
          formula: '=SECH(30)',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=DEGREES()',
          formula: '=DEGREES()',
        ),
        const FortuneCellCoord(14, 5): const FortuneCell(
          value: '=DEGREES("value")',
          formula: '=DEGREES("value")',
        ),
        const FortuneCellCoord(14, 6): const FortuneCell(
          value: '=DEGREES(PI())',
          formula: '=DEGREES(PI())',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=DEGREES(PI() / 2)',
          formula: '=DEGREES(PI() / 2)',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=DEGREES(1.1)',
          formula: '=DEGREES(1.1)',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=RADIANS()',
          formula: '=RADIANS()',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=RADIANS("value")',
          formula: '=RADIANS("value")',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=RADIANS(180)',
          formula: '=RADIANS(180)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=RADIANS(90)',
          formula: '=RADIANS(90)',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=SIN()',
          formula: '=SIN()',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=SIN("value")',
          formula: '=SIN("value")',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=SIN(PI() / 2)',
          formula: '=SIN(PI() / 2)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=SINH()',
          formula: '=SINH()',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=SINH("value")',
          formula: '=SINH("value")',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=SINH(1)',
          formula: '=SINH(1)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=TAN()',
          formula: '=TAN()',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=TAN("value")',
          formula: '=TAN("value")',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=TAN(1)',
          formula: '=TAN(1)',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=TAN(RADIANS(45))',
          formula: '=TAN(RADIANS(45))',
        ),
        const FortuneCellCoord(17, 4): const FortuneCell(
          value: '=TANH()',
          formula: '=TANH()',
        ),
        const FortuneCellCoord(17, 5): const FortuneCell(
          value: '=TANH("value")',
          formula: '=TANH("value")',
        ),
        const FortuneCellCoord(17, 6): const FortuneCell(
          value: '=TANH(1)',
          formula: '=TANH(1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '45');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '#VALUE!');
    expect(
      double.parse(sheet.cells[const FortuneCellCoord(0, 8)]!.renderedText),
      closeTo(0.48121182505960347, 1e-12),
    );
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, 'Infinity');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '-9');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '#VALUE!');
    final rand = double.parse(
      sheet.cells[const FortuneCellCoord(2, 0)]!.renderedText,
    );
    expect(rand, inInclusiveRange(0, 1));
    final randomBetween = double.parse(
      sheet.cells[const FortuneCellCoord(2, 1)]!.renderedText,
    );
    expect(randomBetween, inInclusiveRange(1, 3));
    expect(randomBetween, randomBetween.truncateToDouble());
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#DIV/0!');
    final negativeRandomBetween = double.parse(
      sheet.cells[const FortuneCellCoord(2, 4)]!.renderedText,
    );
    expect(negativeRandomBetween, inInclusiveRange(-5, -3));
    expect(negativeRandomBetween, negativeRandomBetween.truncateToDouble());
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, 'Infinity');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '0.785398');
    expect(
      sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText,
      '-0.785398',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, 'Infinity');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, 'Infinity');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, 'Infinity');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '0.549306');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, 'Infinity');
    expect(
      sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText,
      '-Infinity',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '-1');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText,
      '709.889356',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText,
      '-709.889356',
    );
    expect(
      sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText,
      '709.889356',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 8)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(6, 9)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(6, 10)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '0');
    expect(
      sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText,
      '3.14159265359',
    );
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText,
      '0.523598775598',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText,
      '0.463647609001',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText,
      '0.785398163397',
    );
    expect(
      sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText,
      '-0.785398163397',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText,
      '0.785398163397',
    );
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText,
      '0.540302305868',
    );
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(10, 6)]?.renderedText,
      '1.543080634815',
    );
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText,
      '0.642092615934',
    );
    expect(
      sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText,
      '-0.45765755436',
    );
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(11, 6)]?.renderedText,
      '1.313035285499',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText,
      '1.037314720728',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText,
      '1.188395105778',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText,
      '1.099750170295',
    );
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 6)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText,
      '0.850918128239',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText,
      '0.275720564772',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText,
      '1.850815717681',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 5)]?.renderedText,
      '6.482921234963',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText,
      '0.648054273664',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 6)]?.renderedText, '180');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, '90');
    expect(
      sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText,
      '63.025357464391',
    );
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText,
      '3.14159265359',
    );
    expect(
      sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText,
      '1.570796326795',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText,
      '1.175201193644',
    );
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText,
      '1.557407724655',
    );
    expect(sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(17, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(17, 6)]?.renderedText,
      '0.761594155956',
    );
  });

  test('formula engine evaluates text helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '  Hello   World  ',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=LEN(TRIM(A1))',
          formula: '=LEN(TRIM(A1))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=LOWER("MiXeD")',
          formula: '=LOWER("MiXeD")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=UPPER(LEFT(TRIM(A1), 5))',
          formula: '=UPPER(LEFT(TRIM(A1), 5))',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=RIGHT(TRIM(A1), 5)',
          formula: '=RIGHT(TRIM(A1), 5)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=MID(TRIM(A1), 7, 3)',
          formula: '=MID(TRIM(A1), 7, 3)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=REPT("ha", 3)',
          formula: '=REPT("ha", 3)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=FIND("World", TRIM(A1))',
          formula: '=FIND("World", TRIM(A1))',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=SEARCH("world", TRIM(A1))',
          formula: '=SEARCH("world", TRIM(A1))',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=FIND("l", TRIM(A1), 4)',
          formula: '=FIND("l", TRIM(A1), 4)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=SUBSTITUTE("one two one", "one", "1")',
          formula: '=SUBSTITUTE("one two one", "one", "1")',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=SUBSTITUTE("one two one", "one", "1", 2)',
          formula: '=SUBSTITUTE("one two one", "one", "1", 2)',
        ),
        const FortuneCellCoord(1, 11): const FortuneCell(
          value: '=SUBSTITUTE("one two one", "one", "1", 3)',
          formula: '=SUBSTITUTE("one two one", "one", "1", 3)',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=REPT("ha", 0)',
          formula: '=REPT("ha", 0)',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=REPT("ha", -1)',
          formula: '=REPT("ha", -1)',
        ),
        const FortuneCellCoord(1, 8): const FortuneCell(
          value: '=MID("hello", 0, 2)',
          formula: '=MID("hello", 0, 2)',
        ),
        const FortuneCellCoord(1, 9): const FortuneCell(
          value: '=MID("hello", -1, 2)',
          formula: '=MID("hello", -1, 2)',
        ),
        const FortuneCellCoord(1, 10): const FortuneCell(
          value: '=SUBSTITUTE("hello", "", "x")',
          formula: '=SUBSTITUTE("hello", "", "x")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=FIND("world", TRIM(A1))',
          formula: '=FIND("world", TRIM(A1))',
        ),
        const FortuneCellCoord(2, 14): const FortuneCell(
          value: '=FIND("O", "FooBar")',
          formula: '=FIND("O", "FooBar")',
        ),
        const FortuneCellCoord(2, 15): const FortuneCell(
          value: '=EXACT(1100, 1100)',
          formula: '=EXACT(1100, 1100)',
        ),
        const FortuneCellCoord(2, 16): const FortuneCell(
          value: '=EXACT(1100, "1100")',
          formula: '=EXACT(1100, "1100")',
        ),
        const FortuneCellCoord(2, 17): const FortuneCell(
          value: '=PROPER(TRUE)',
          formula: '=PROPER(TRUE)',
        ),
        const FortuneCellCoord(2, 18): const FortuneCell(
          value: '=PROPER(1234)',
          formula: '=PROPER(1234)',
        ),
        const FortuneCellCoord(2, 19): const FortuneCell(
          value: '=T(TRUE)&"x"&T(9.887)',
          formula: '=T(TRUE)&"x"&T(9.887)',
        ),
        const FortuneCellCoord(2, 20): const FortuneCell(
          value: '=T("foo bar baz")',
          formula: '=T("foo bar baz")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=EXACT("Text", "Text")',
          formula: '=EXACT("Text", "Text")',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=EXACT("Text", "text")',
          formula: '=EXACT("Text", "text")',
        ),
        const FortuneCellCoord(2, 22): const FortuneCell(
          value: '=EXACT("", "")',
          formula: '=EXACT("", "")',
        ),
        const FortuneCellCoord(2, 23): const FortuneCell(
          value: '=EXACT(" ", "")',
          formula: '=EXACT(" ", "")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=REPLACE("abcdef", 2, 3, "ZZ")',
          formula: '=REPLACE("abcdef", 2, 3, "ZZ")',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=PROPER("hello-world 42nd")',
          formula: '=PROPER("hello-world 42nd")',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=T("text")&T(123)',
          formula: '=T("text")&T(123)',
        ),
        const FortuneCellCoord(2, 6): const FortuneCell(
          value: '=EXACT()',
          formula: '=EXACT()',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=EXACT("Text")',
          formula: '=EXACT("Text")',
        ),
        const FortuneCellCoord(2, 21): const FortuneCell(
          value: '=EXACT(1100)',
          formula: '=EXACT(1100)',
        ),
        const FortuneCellCoord(2, 8): const FortuneCell(
          value: '=FIND()',
          formula: '=FIND()',
        ),
        const FortuneCellCoord(2, 9): const FortuneCell(
          value: '=FIND("o")',
          formula: '=FIND("o")',
        ),
        const FortuneCellCoord(2, 10): const FortuneCell(
          value: '=RIGHT()',
          formula: '=RIGHT()',
        ),
        const FortuneCellCoord(2, 11): const FortuneCell(
          value: '=SUBSTITUTE()',
          formula: '=SUBSTITUTE()',
        ),
        const FortuneCellCoord(2, 12): const FortuneCell(
          value: '=SUBSTITUTE("foo bar baz")',
          formula: '=SUBSTITUTE("foo bar baz")',
        ),
        const FortuneCellCoord(2, 13): const FortuneCell(
          value: '=T()',
          formula: '=T()',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: r'=VALUE("$1,234.50")',
          formula: r'=VALUE("$1,234.50")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=VALUE("25%")',
          formula: '=VALUE("25%")',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=VALUE("2024-02-29")',
          formula: '=VALUE("2024-02-29")',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=VALUE("06:00")',
          formula: '=VALUE("06:00")',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=VALUE("not numeric")',
          formula: '=VALUE("not numeric")',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=VALUE("1.23E+3")',
          formula: '=VALUE("1.23E+3")',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=VALUE("01:00:00")',
          formula: '=VALUE("01:00:00")',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=VALUE("foo Bar")',
          formula: '=VALUE("foo Bar")',
        ),
        const FortuneCellCoord(3, 8): const FortuneCell(
          value: r'=VALUE("$ 1,234.50")',
          formula: r'=VALUE("$ 1,234.50")',
        ),
        const FortuneCellCoord(3, 9): const FortuneCell(
          value: '=VALUE(UNICHAR(8364)&" 1,234.50")',
          formula: '=VALUE(UNICHAR(8364)&" 1,234.50")',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(value: 'North'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: ''),
        const FortuneCellCoord(4, 2): const FortuneCell(value: 'South'),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=TEXTJOIN("-", TRUE, A5:C5, "East")',
          formula: '=TEXTJOIN("-", TRUE, A5:C5, "East")',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=TEXTJOIN("|", FALSE, "A", "", "B")',
          formula: '=TEXTJOIN("|", FALSE, "A", "", "B")',
        ),
        const FortuneCellCoord(4, 9): const FortuneCell(
          value: '=TEXTJOIN("|", TRUE, "", "", "")',
          formula: '=TEXTJOIN("|", TRUE, "", "", "")',
        ),
        const FortuneCellCoord(4, 10): const FortuneCell(
          value: '=TEXTJOIN("|", FALSE, "", "", "")',
          formula: '=TEXTJOIN("|", FALSE, "", "", "")',
        ),
        const FortuneCellCoord(4, 11): const FortuneCell(
          value: '=TEXTJOIN("", FALSE, "A", "", "B")',
          formula: '=TEXTJOIN("", FALSE, "A", "", "B")',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=CHAR(65)&CODE("Az")',
          formula: '=CHAR(65)&CODE("Az")',
        ),
        const FortuneCellCoord(4, 6): const FortuneCell(
          value: '=CODE()',
          formula: '=CODE()',
        ),
        const FortuneCellCoord(4, 7): const FortuneCell(
          value: '=CHAR()',
          formula: '=CHAR()',
        ),
        const FortuneCellCoord(4, 8): const FortuneCell(
          value: '=UNICODE()',
          formula: '=UNICODE()',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=CLEAN("a"&CHAR(10)&"b")',
          formula: '=CLEAN("a"&CHAR(10)&"b")',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=CHAR(0)',
          formula: '=CHAR(0)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=CODE("")',
          formula: '=CODE("")',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: r'=DOLLAR(-1234.567, 2)',
          formula: r'=DOLLAR(-1234.567, 2)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=FIXED(1234.567, 1)',
          formula: '=FIXED(1234.567, 1)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=FIXED(1234.567, 1, TRUE)',
          formula: '=FIXED(1234.567, 1, TRUE)',
        ),
        const FortuneCellCoord(5, 6): const FortuneCell(
          value: '=CLEAN()',
          formula: '=CLEAN()',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=NUMBERVALUE("1.234,56", ",", ".")',
          formula: '=NUMBERVALUE("1.234,56", ",", ".")',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=NUMBERVALUE("12,5%", ",", ".")',
          formula: '=NUMBERVALUE("12,5%", ",", ".")',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=NUMBERVALUE("1.2.3")',
          formula: '=NUMBERVALUE("1.2.3")',
        ),
        const FortuneCellCoord(6, 11): const FortuneCell(
          value: '=NUMBERVALUE("1"&CHAR(160)&"234,56", ",", CHAR(160))',
          formula: '=NUMBERVALUE("1"&CHAR(160)&"234,56", ",", CHAR(160))',
        ),
        const FortuneCellCoord(6, 12): const FortuneCell(
          value: '=NUMBERVALUE("12,5%%", ",", ".")',
          formula: '=NUMBERVALUE("12,5%%", ",", ".")',
        ),
        const FortuneCellCoord(6, 13): const FortuneCell(
          value: '=NUMBERVALUE("1,2", ",", ",")',
          formula: '=NUMBERVALUE("1,2", ",", ",")',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=BASE(31, 16, 4)',
          formula: '=BASE(31, 16, 4)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=DECIMAL("001F", 16)',
          formula: '=DECIMAL("001F", 16)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=BASE(-1, 2)',
          formula: '=BASE(-1, 2)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=BASE()',
          formula: '=BASE()',
        ),
        const FortuneCellCoord(6, 7): const FortuneCell(
          value: '=BASE("value")',
          formula: '=BASE("value")',
        ),
        const FortuneCellCoord(6, 8): const FortuneCell(
          value: '=BASE(7)',
          formula: '=BASE(7)',
        ),
        const FortuneCellCoord(6, 9): const FortuneCell(
          value: '=BASE(7, 2)',
          formula: '=BASE(7, 2)',
        ),
        const FortuneCellCoord(6, 10): const FortuneCell(
          value: '=BASE(7, 2, 8)',
          formula: '=BASE(7, 2, 8)',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=DECIMAL("102", 2)',
          formula: '=DECIMAL("102", 2)',
        ),
        const FortuneCellCoord(7, 6): const FortuneCell(
          value: '=DECIMAL(1.3)',
          formula: '=DECIMAL(1.3)',
        ),
        const FortuneCellCoord(7, 7): const FortuneCell(
          value: '=DECIMAL("value")',
          formula: '=DECIMAL("value")',
        ),
        const FortuneCellCoord(7, 8): const FortuneCell(
          value: '=DECIMAL()',
          formula: '=DECIMAL()',
        ),
        const FortuneCellCoord(7, 9): const FortuneCell(
          value: '=DECIMAL("0", 2)',
          formula: '=DECIMAL("0", 2)',
        ),
        const FortuneCellCoord(7, 10): const FortuneCell(
          value: '=DECIMAL("1010101", 2)',
          formula: '=DECIMAL("1010101", 2)',
        ),
        const FortuneCellCoord(7, 11): const FortuneCell(
          value: '=DECIMAL("32b", 16)',
          formula: '=DECIMAL("32b", 16)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=ROMAN(1999)',
          formula: '=ROMAN(1999)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=ARABIC("MCMXCIX")',
          formula: '=ARABIC("MCMXCIX")',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=ROMAN(4000)',
          formula: '=ROMAN(4000)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=ARABIC("IIV")',
          formula: '=ARABIC("IIV")',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=UNICODE(UNICHAR(9731))',
          formula: '=UNICODE(UNICHAR(9731))',
        ),
        const FortuneCellCoord(7, 12): const FortuneCell(
          value: '=ARABIC()',
          formula: '=ARABIC()',
        ),
        const FortuneCellCoord(7, 13): const FortuneCell(
          value: '=ARABIC("ABC")',
          formula: '=ARABIC("ABC")',
        ),
        const FortuneCellCoord(7, 14): const FortuneCell(
          value: '=ARABIC("X")',
          formula: '=ARABIC("X")',
        ),
        const FortuneCellCoord(7, 15): const FortuneCell(
          value: '=ARABIC("MXL")',
          formula: '=ARABIC("MXL")',
        ),
        const FortuneCellCoord(7, 16): const FortuneCell(
          value: '=ROMAN(3999)',
          formula: '=ROMAN(3999)',
        ),
        const FortuneCellCoord(7, 17): const FortuneCell(
          value: '=ARABIC("")',
          formula: '=ARABIC("")',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=UNICHAR(55296)',
          formula: '=UNICHAR(55296)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=UNICODE("")',
          formula: '=UNICODE("")',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=TEXT("North", "@ region")',
          formula: '=TEXT("North", "@ region")',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=TEXT("closed", "0.0;[red]-0.0;zero;status: @")',
          formula: '=TEXT("closed", "0.0;[red]-0.0;zero;status: @")',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=LEN(TRUE)',
          formula: '=LEN(TRUE)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=LEN(1023)',
          formula: '=LEN(1023)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=PROPER("")',
          formula: '=PROPER("")',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=SEARCH("w*d", TRIM(A1))',
          formula: '=SEARCH("w*d", TRIM(A1))',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=SEARCH("w?r", TRIM(A1))',
          formula: '=SEARCH("w?r", TRIM(A1))',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=SEARCH("~*", "a*b")',
          formula: '=SEARCH("~*", "a*b")',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=SEARCH("~~", "a~b")',
          formula: '=SEARCH("~~", "a~b")',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=FIND("*", "a*b")',
          formula: '=FIND("*", "a*b")',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=SEARCH("w*d", "World world", 3)',
          formula: '=SEARCH("w*d", "World world", 3)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=SEARCH("~?", "a?b")',
          formula: '=SEARCH("~?", "a?b")',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=SEARCH("a", "abc", 4)',
          formula: '=SEARCH("a", "abc", 4)',
        ),
        const FortuneCellCoord(9, 8): const FortuneCell(
          value: '=FIND("", "abc")',
          formula: '=FIND("", "abc")',
        ),
        const FortuneCellCoord(9, 9): const FortuneCell(
          value: '=SEARCH("", "abc")',
          formula: '=SEARCH("", "abc")',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=TEXTBEFORE("alpha.beta.gamma", ".")',
          formula: '=TEXTBEFORE("alpha.beta.gamma", ".")',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=TEXTAFTER("alpha.beta.gamma", ".")',
          formula: '=TEXTAFTER("alpha.beta.gamma", ".")',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=TEXTBEFORE("alpha.beta.gamma", ".", -1)',
          formula: '=TEXTBEFORE("alpha.beta.gamma", ".", -1)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=TEXTAFTER("alpha.beta.gamma", ".", -1)',
          formula: '=TEXTAFTER("alpha.beta.gamma", ".", -1)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=TEXTBEFORE("Alpha.beta", "B", 1, 1)',
          formula: '=TEXTBEFORE("Alpha.beta", "B", 1, 1)',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=TEXTAFTER("alpha.beta", ":")',
          formula: '=TEXTAFTER("alpha.beta", ":")',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=TEXTBEFORE("alpha", ":", 1, 0, 1)',
          formula: '=TEXTBEFORE("alpha", ":", 1, 0, 1)',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=TEXTAFTER("alpha", ":", 1, 0, 1)',
          formula: '=TEXTAFTER("alpha", ":", 1, 0, 1)',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=TEXTBEFORE("alpha", ":", 1, 0, 2)',
          formula: '=TEXTBEFORE("alpha", ":", 1, 0, 2)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=TEXTBEFORE("alpha", ":", 1, 0, 0, "missing")',
          formula: '=TEXTBEFORE("alpha", ":", 1, 0, 0, "missing")',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=TEXTAFTER("alpha", ":", 1, 0, 1, "missing")',
          formula: '=TEXTAFTER("alpha", ":", 1, 0, 1, "missing")',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=TEXTAFTER("alpha", ":", 1, 0, 0, 42)',
          formula: '=TEXTAFTER("alpha", ":", 1, 0, 0, 42)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=TEXTBEFORE("alpha.beta", ".", 1, 0, 0, UNKNOWN(1))',
          formula: '=TEXTBEFORE("alpha.beta", ".", 1, 0, 0, UNKNOWN(1))',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=TEXTAFTER("alpha", ":", 1, 0, 0, UNKNOWN(1))',
          formula: '=TEXTAFTER("alpha", ":", 1, 0, 0, UNKNOWN(1))',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=ROMAN(499, 1)',
          formula: '=ROMAN(499, 1)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=ROMAN(499, 2)',
          formula: '=ROMAN(499, 2)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=ROMAN(499, 3)',
          formula: '=ROMAN(499, 3)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=ROMAN(499, 4)',
          formula: '=ROMAN(499, 4)',
        ),
        const FortuneCellCoord(12, 6): const FortuneCell(
          value: '=TEXTBEFORE("alpha", "")',
          formula: '=TEXTBEFORE("alpha", "")',
        ),
        const FortuneCellCoord(12, 7): const FortuneCell(
          value: '=TEXTAFTER("alpha", "")',
          formula: '=TEXTAFTER("alpha", "")',
        ),
        const FortuneCellCoord(12, 8): const FortuneCell(
          value: '=TEXTBEFORE("alpha,beta", 1/0)',
          formula: '=TEXTBEFORE("alpha,beta", 1/0)',
        ),
        const FortuneCellCoord(12, 9): const FortuneCell(
          value: '=TEXTAFTER("alpha,beta", 1/0)',
          formula: '=TEXTAFTER("alpha,beta", 1/0)',
        ),
        const FortuneCellCoord(12, 10): const FortuneCell(
          value: '=TEXTBEFORE("alpha.beta", ".", 1/0)',
          formula: '=TEXTBEFORE("alpha.beta", ".", 1/0)',
        ),
        const FortuneCellCoord(12, 11): const FortuneCell(
          value: '=TEXTAFTER("alpha.beta", ".", 1/0)',
          formula: '=TEXTAFTER("alpha.beta", ".", 1/0)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("red,green,blue", ","), 1, 2)',
          formula: '=INDEX(TEXTSPLIT("red,green,blue", ","), 1, 2)',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value:
              '=ROWS(TEXTSPLIT("a,b;c,d", ",", ";"))&"x"&COLUMNS(TEXTSPLIT("a,b;c,d", ",", ";"))',
          formula:
              '=ROWS(TEXTSPLIT("a,b;c,d", ",", ";"))&"x"&COLUMNS(TEXTSPLIT("a,b;c,d", ",", ";"))',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("a,,b", ",", , TRUE), 1, 2)',
          formula: '=INDEX(TEXTSPLIT("a,,b", ",", , TRUE), 1, 2)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("a,b;c", ",", ";", FALSE, 0, "pad"), 2, 2)',
          formula:
              '=INDEX(TEXTSPLIT("a,b;c", ",", ";", FALSE, 0, "pad"), 2, 2)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("AlphaXbeta", "x", , FALSE, 1), 1, 2)',
          formula: '=INDEX(TEXTSPLIT("AlphaXbeta", "x", , FALSE, 1), 1, 2)',
        ),
        const FortuneCellCoord(13, 5): const FortuneCell(
          value: '=TEXTSPLIT("a,b", 1/0)',
          formula: '=TEXTSPLIT("a,b", 1/0)',
        ),
        const FortuneCellCoord(13, 6): const FortuneCell(
          value: '=TEXTSPLIT("a,b;c", ",", 1/0)',
          formula: '=TEXTSPLIT("a,b;c", ",", 1/0)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("red,green;blue", E15:E16), 1, 3)',
          formula: '=INDEX(TEXTSPLIT("red,green;blue", E15:E16), 1, 3)',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=ROWS(TEXTSPLIT("a,b;c,d|e,f", ",", E17:E18))',
          formula: '=ROWS(TEXTSPLIT("a,b;c,d|e,f", ",", E17:E18))',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value:
              '=INDEX(TEXTSPLIT("AlphaXbetaYgamma", E19:E20, , FALSE, 1), 1, 3)',
          formula:
              '=INDEX(TEXTSPLIT("AlphaXbetaYgamma", E19:E20, , FALSE, 1), 1, 3)',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=INDEX(TEXTSPLIT("red,green;blue", {",",";"}), 1, 3)',
          formula: '=INDEX(TEXTSPLIT("red,green;blue", {",",";"}), 1, 3)',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=ROWS(TEXTSPLIT("a,b;c,d|e,f", ",", {";";"|"}))',
          formula: '=ROWS(TEXTSPLIT("a,b;c,d|e,f", ",", {";";"|"}))',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value:
              '=INDEX(TEXTSPLIT("AlphaXbetaYgamma", {"x","y"}, , FALSE, 1), 1, 3)',
          formula:
              '=INDEX(TEXTSPLIT("AlphaXbetaYgamma", {"x","y"}, , FALSE, 1), 1, 3)',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=ROWS({1,2;3,4})&"x"&COLUMNS({1,2;3,4})',
          formula: '=ROWS({1,2;3,4})&"x"&COLUMNS({1,2;3,4})',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=INDEX({"a","b";"c","d"}, 2, 1)',
          formula: '=INDEX({"a","b";"c","d"}, 2, 1)',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=ROMAN(499, TRUE)',
          formula: '=ROMAN(499, TRUE)',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=ROMAN(499, FALSE)',
          formula: '=ROMAN(499, FALSE)',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=HYPERLINK("https://example.com")',
          formula: '=HYPERLINK("https://example.com")',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=HYPERLINK("https://example.com", "Example")',
          formula: '=HYPERLINK("https://example.com", "Example")',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=ENCODEURL("a b+c?=&")',
          formula: '=ENCODEURL("a b+c?=&")',
        ),
        const FortuneCellCoord(16, 6): const FortuneCell(
          value: '=ENCODEURL("")',
          formula: '=ENCODEURL("")',
        ),
        const FortuneCellCoord(16, 7): const FortuneCell(
          value: '=LEFTB("abcdef", 2)&RIGHTB("abcdef", 2)&MIDB("abcdef", 3, 2)',
          formula:
              '=LEFTB("abcdef", 2)&RIGHTB("abcdef", 2)&MIDB("abcdef", 3, 2)',
        ),
        const FortuneCellCoord(16, 8): const FortuneCell(
          value: '=LENB("abcdef")&":"&FINDB("cd", "abcdef")',
          formula: '=LENB("abcdef")&":"&FINDB("cd", "abcdef")',
        ),
        const FortuneCellCoord(16, 9): const FortuneCell(
          value: '=SEARCHB("C?", "abcdef")&":"&REPLACEB("abcdef", 2, 3, "ZZ")',
          formula:
              '=SEARCHB("C?", "abcdef")&":"&REPLACEB("abcdef", 2, 3, "ZZ")',
        ),
        const FortuneCellCoord(16, 10): const FortuneCell(
          value: '=ASC("ABC 123")&":"&DBCS("ABC 123")',
          formula: '=ASC("ABC 123")&":"&DBCS("ABC 123")',
        ),
        const FortuneCellCoord(16, 11): const FortuneCell(
          value: '=ASC("ＡＢＣ　１２３！")',
          formula: '=ASC("ＡＢＣ　１２３！")',
        ),
        const FortuneCellCoord(16, 12): const FortuneCell(
          value: '=DBCS("ABC 123!")',
          formula: '=DBCS("ABC 123!")',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(value: ','),
        const FortuneCellCoord(15, 4): const FortuneCell(value: ';'),
        const FortuneCellCoord(16, 4): const FortuneCell(value: ';'),
        const FortuneCellCoord(17, 4): const FortuneCell(value: '|'),
        const FortuneCellCoord(18, 4): const FortuneCell(value: 'x'),
        const FortuneCellCoord(19, 4): const FortuneCell(value: 'y'),
        const FortuneCellCoord(20, 0): const FortuneCell(
          value: '=LOWER()',
          formula: '=LOWER()',
        ),
        const FortuneCellCoord(20, 1): const FortuneCell(
          value: '=UPPER()',
          formula: '=UPPER()',
        ),
        const FortuneCellCoord(20, 2): const FortuneCell(
          value: '=TRIM()',
          formula: '=TRIM()',
        ),
        const FortuneCellCoord(20, 3): const FortuneCell(
          value: '=LEFT()',
          formula: '=LEFT()',
        ),
        const FortuneCellCoord(20, 4): const FortuneCell(
          value: '=SEARCH()',
          formula: '=SEARCH()',
        ),
        const FortuneCellCoord(20, 5): const FortuneCell(
          value: '=SEARCH("bar")',
          formula: '=SEARCH("bar")',
        ),
        const FortuneCellCoord(20, 6): const FortuneCell(
          value: '=LEN()',
          formula: '=LEN()',
        ),
        const FortuneCellCoord(21, 0): const FortuneCell(
          value: '=MID("")',
          formula: '=MID("")',
        ),
        const FortuneCellCoord(21, 1): const FortuneCell(
          value: '=MID("Foo Bar", 2)',
          formula: '=MID("Foo Bar", 2)',
        ),
        const FortuneCellCoord(21, 2): const FortuneCell(
          value: '=REPLACE()',
          formula: '=REPLACE()',
        ),
        const FortuneCellCoord(21, 3): const FortuneCell(
          value: '=REPLACE("foo bar", 2, 5)',
          formula: '=REPLACE("foo bar", 2, 5)',
        ),
        const FortuneCellCoord(21, 6): const FortuneCell(
          value: '=REPLACE("foo bar")',
          formula: '=REPLACE("foo bar")',
        ),
        const FortuneCellCoord(21, 7): const FortuneCell(
          value: '=REPLACE("foo bar", 2)',
          formula: '=REPLACE("foo bar", 2)',
        ),
        const FortuneCellCoord(21, 8): const FortuneCell(
          value: '=MID()',
          formula: '=MID()',
        ),
        const FortuneCellCoord(21, 9): const FortuneCell(
          value: '=PROPER()',
          formula: '=PROPER()',
        ),
        const FortuneCellCoord(21, 4): const FortuneCell(
          value: '=REPT()',
          formula: '=REPT()',
        ),
        const FortuneCellCoord(21, 5): const FortuneCell(
          value: '=REPT("foo ")',
          formula: '=REPT("foo ")',
        ),
        const FortuneCellCoord(22, 0): const FortuneCell(
          value: '=TEXTJOIN("|", TRUE, DM_TEXT_CUTWORD("Alpha beta Alpha 北京"))',
          formula:
              '=TEXTJOIN("|", TRUE, DM_TEXT_CUTWORD("Alpha beta Alpha 北京"))',
        ),
        const FortuneCellCoord(22, 1): const FortuneCell(
          value: '=TEXTJOIN("|", TRUE, DM_TEXT_TFIDF("red blue red green", 2))',
          formula:
              '=TEXTJOIN("|", TRUE, DM_TEXT_TFIDF("red blue red green", 2))',
        ),
        const FortuneCellCoord(22, 2): const FortuneCell(
          value: '=TEXTJOIN("|", TRUE, DM_TEXT_TEXTRANK("我我来到北京", 2))',
          formula: '=TEXTJOIN("|", TRUE, DM_TEXT_TEXTRANK("我我来到北京", 2))',
        ),
        const FortuneCellCoord(23, 0): const FortuneCell(
          value: '=CHAR(33)',
          formula: '=CHAR(33)',
        ),
        const FortuneCellCoord(23, 1): const FortuneCell(
          value: '=CLEAN(CHAR(9)&"Monthly report"&CHAR(10))',
          formula: '=CLEAN(CHAR(9)&"Monthly report"&CHAR(10))',
        ),
        const FortuneCellCoord(23, 2): const FortuneCell(
          value: '=CODE("a")',
          formula: '=CODE("a")',
        ),
        const FortuneCellCoord(23, 3): const FortuneCell(
          value: '=CONCATENATE()',
          formula: '=CONCATENATE()',
        ),
        const FortuneCellCoord(23, 4): const FortuneCell(
          value: '=CONCATENATE("a")',
          formula: '=CONCATENATE("a")',
        ),
        const FortuneCellCoord(23, 5): const FortuneCell(
          value: '=CONCATENATE("a", 1)',
          formula: '=CONCATENATE("a", 1)',
        ),
        const FortuneCellCoord(23, 6): const FortuneCell(
          value: '=CONCATENATE("a", 1, TRUE)',
          formula: '=CONCATENATE("a", 1, TRUE)',
        ),
        const FortuneCellCoord(23, 7): const FortuneCell(
          value: '=EXACT(1100, -2)',
          formula: '=EXACT(1100, -2)',
        ),
        const FortuneCellCoord(23, 8): const FortuneCell(
          value: '=FIND("o", "FooBar")',
          formula: '=FIND("o", "FooBar")',
        ),
        const FortuneCellCoord(23, 9): const FortuneCell(
          value: '=LEFT("Foo Bar")',
          formula: '=LEFT("Foo Bar")',
        ),
        const FortuneCellCoord(23, 10): const FortuneCell(
          value: '=LEFT("Foo Bar", 3)',
          formula: '=LEFT("Foo Bar", 3)',
        ),
        const FortuneCellCoord(23, 11): const FortuneCell(
          value: '=LOWER("")',
          formula: '=LOWER("")',
        ),
        const FortuneCellCoord(23, 12): const FortuneCell(
          value: '=LOWER("Foo Bar")',
          formula: '=LOWER("Foo Bar")',
        ),
        const FortuneCellCoord(23, 13): const FortuneCell(
          value: '=LEFT("Foo Bar", 0)',
          formula: '=LEFT("Foo Bar", 0)',
        ),
        const FortuneCellCoord(23, 14): const FortuneCell(
          value: '=RIGHT("Foo Bar", 0)',
          formula: '=RIGHT("Foo Bar", 0)',
        ),
        const FortuneCellCoord(23, 15): const FortuneCell(
          value: '=MID("Foo Bar", 2, 0)',
          formula: '=MID("Foo Bar", 2, 0)',
        ),
        const FortuneCellCoord(23, 16): const FortuneCell(
          value: '=MID("Foo Bar", 9, 2)',
          formula: '=MID("Foo Bar", 9, 2)',
        ),
        const FortuneCellCoord(23, 17): const FortuneCell(
          value: '=LEN("")',
          formula: '=LEN("")',
        ),
        const FortuneCellCoord(23, 18): const FortuneCell(
          value: '=UPPER("")',
          formula: '=UPPER("")',
        ),
        const FortuneCellCoord(24, 0): const FortuneCell(
          value: '=MID("Foo Bar", 2, 5)',
          formula: '=MID("Foo Bar", 2, 5)',
        ),
        const FortuneCellCoord(24, 1): const FortuneCell(
          value: '=PROPER("foo bar")',
          formula: '=PROPER("foo bar")',
        ),
        const FortuneCellCoord(24, 2): const FortuneCell(
          value: '=REPLACE("foo bar", 2, 5, "*")',
          formula: '=REPLACE("foo bar", 2, 5, "*")',
        ),
        const FortuneCellCoord(24, 3): const FortuneCell(
          value: '=REPT("foo ", 5)',
          formula: '=REPT("foo ", 5)',
        ),
        const FortuneCellCoord(24, 4): const FortuneCell(
          value: '=RIGHT("foo bar")',
          formula: '=RIGHT("foo bar")',
        ),
        const FortuneCellCoord(24, 5): const FortuneCell(
          value: '=RIGHT("foo bar", 4)',
          formula: '=RIGHT("foo bar", 4)',
        ),
        const FortuneCellCoord(24, 6): const FortuneCell(
          value: '=SEARCH("bar", "foo bar")',
          formula: '=SEARCH("bar", "foo bar")',
        ),
        const FortuneCellCoord(24, 7): const FortuneCell(
          value: '=SUBSTITUTE("foo bar baz", "a", "A")',
          formula: '=SUBSTITUTE("foo bar baz", "a", "A")',
        ),
        const FortuneCellCoord(24, 8): const FortuneCell(
          value: '=TRIM("")',
          formula: '=TRIM("")',
        ),
        const FortuneCellCoord(24, 9): const FortuneCell(
          value: '=TRIM("     ")',
          formula: '=TRIM("     ")',
        ),
        const FortuneCellCoord(24, 10): const FortuneCell(
          value: '=TRIM("   foo  ")',
          formula: '=TRIM("   foo  ")',
        ),
        const FortuneCellCoord(24, 21): const FortuneCell(
          value: '=TRIM("  foo   bar  ")',
          formula: '=TRIM("  foo   bar  ")',
        ),
        const FortuneCellCoord(24, 22): const FortuneCell(
          value: '=REPLACE("foo", 2, 0, "X")',
          formula: '=REPLACE("foo", 2, 0, "X")',
        ),
        const FortuneCellCoord(24, 23): const FortuneCell(
          value: '=SUBSTITUTE("foo foo", "foo", "bar", 0)',
          formula: '=SUBSTITUTE("foo foo", "foo", "bar", 0)',
        ),
        const FortuneCellCoord(24, 11): const FortuneCell(
          value: '=UNICHAR(33)',
          formula: '=UNICHAR(33)',
        ),
        const FortuneCellCoord(24, 12): const FortuneCell(
          value: '=UNICODE("!")',
          formula: '=UNICODE("!")',
        ),
        const FortuneCellCoord(24, 13): const FortuneCell(
          value: '=UPPER("foo Bar")',
          formula: '=UPPER("foo Bar")',
        ),
        const FortuneCellCoord(24, 14): const FortuneCell(
          value: '=ROMAN()',
          formula: '=ROMAN()',
        ),
        const FortuneCellCoord(24, 15): const FortuneCell(
          value: '=ROMAN("value")',
          formula: '=ROMAN("value")',
        ),
        const FortuneCellCoord(24, 16): const FortuneCell(
          value: '=ROMAN(1)',
          formula: '=ROMAN(1)',
        ),
        const FortuneCellCoord(24, 17): const FortuneCell(
          value: '=ROMAN(12)',
          formula: '=ROMAN(12)',
        ),
        const FortuneCellCoord(24, 18): const FortuneCell(
          value: '=ROMAN(992)',
          formula: '=ROMAN(992)',
        ),
        const FortuneCellCoord(24, 19): const FortuneCell(
          value: '=ROMAN(2000)',
          formula: '=ROMAN(2000)',
        ),
        const FortuneCellCoord(24, 20): const FortuneCell(
          value: '=UNICHAR()',
          formula: '=UNICHAR()',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, 'mixed');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, 'HELLO');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, 'World');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'Wor');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'hahaha');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '1 two 1');
    expect(
      sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText,
      'one two 1',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 11)]?.renderedText,
      'one two one',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 9)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, 'aZZef');
    expect(
      sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText,
      'Hello-World 42nd',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, 'text');
    expect(sheet.cells[const FortuneCellCoord(2, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 8)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 9)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 10)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 11)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 12)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 13)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(2, 14)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(2, 15)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 16)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(2, 17)]?.renderedText, 'True');
    expect(sheet.cells[const FortuneCellCoord(2, 18)]?.renderedText, '1234');
    expect(sheet.cells[const FortuneCellCoord(2, 19)]?.renderedText, 'x');
    expect(
      sheet.cells[const FortuneCellCoord(2, 20)]?.renderedText,
      'foo bar baz',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 21)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 22)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 23)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '1234.5');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '0.25');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '21600');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '1230');
    expect(sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText, '3600');
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(3, 8)]?.renderedText, '1234.5');
    expect(sheet.cells[const FortuneCellCoord(3, 9)]?.renderedText, '1234.5');
    expect(
      sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText,
      'North-South-East',
    );
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, 'A||B');
    expect(sheet.cells[const FortuneCellCoord(4, 9)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(4, 10)]?.renderedText, '||');
    expect(sheet.cells[const FortuneCellCoord(4, 11)]?.renderedText, 'AB');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, 'A65');
    expect(sheet.cells[const FortuneCellCoord(4, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(4, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 8)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, 'ab');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText,
      r'($1,234.57)',
    );
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '1,234.6');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '1234.6');
    expect(sheet.cells[const FortuneCellCoord(5, 6)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '1234.56');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '0.125');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 11)]?.renderedText, '1234.56');
    expect(sheet.cells[const FortuneCellCoord(6, 12)]?.renderedText, '0.00125');
    expect(sheet.cells[const FortuneCellCoord(6, 13)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '001F');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '31');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 9)]?.renderedText, '111');
    expect(
      sheet.cells[const FortuneCellCoord(6, 10)]?.renderedText,
      '00000111',
    );
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(7, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 8)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 9)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(7, 10)]?.renderedText, '85');
    expect(sheet.cells[const FortuneCellCoord(7, 11)]?.renderedText, '811');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, 'MCMXCIX');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '1999');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '9731');
    expect(sheet.cells[const FortuneCellCoord(7, 12)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 13)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(7, 14)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(7, 15)]?.renderedText, '1040');
    expect(
      sheet.cells[const FortuneCellCoord(7, 16)]?.renderedText,
      'MMMCMXCIX',
    );
    expect(sheet.cells[const FortuneCellCoord(7, 17)]?.renderedText, '0');
    expect(
      sheet.cells[const FortuneCellCoord(24, 20)]?.renderedText,
      '#VALUE!',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText,
      'North region',
    );
    expect(
      sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText,
      'status: closed',
    );
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 8)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(9, 9)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, 'alpha');
    expect(
      sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText,
      'beta.gamma',
    );
    expect(
      sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText,
      'alpha.beta',
    );
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, 'gamma');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, 'Alpha.');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, 'alpha');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, 'alpha');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#NAME?');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, 'LDVLIV');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, 'XDIX');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, 'VDIV');
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, 'ID');
    expect(sheet.cells[const FortuneCellCoord(12, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 8)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(12, 9)]?.renderedText, '#DIV/0!');
    expect(
      sheet.cells[const FortuneCellCoord(12, 10)]?.renderedText,
      '#DIV/0!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 11)]?.renderedText,
      '#DIV/0!',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, 'green');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText, 'b');
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, 'pad');
    expect(sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText, 'beta');
    expect(sheet.cells[const FortuneCellCoord(13, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(13, 6)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, 'blue');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, 'gamma');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, 'blue');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, 'gamma');
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText, 'c');
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, 'CDXCIX');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, 'ID');
    expect(
      sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText,
      'https://example.com',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, 'Example');
    expect(
      sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText,
      'a%20b%2Bc%3F%3D%26',
    );
    expect(sheet.cells[const FortuneCellCoord(16, 6)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(16, 7)]?.renderedText, 'abefcd');
    expect(sheet.cells[const FortuneCellCoord(16, 8)]?.renderedText, '6:3');
    expect(sheet.cells[const FortuneCellCoord(16, 9)]?.renderedText, '3:aZZef');
    expect(
      sheet.cells[const FortuneCellCoord(16, 10)]?.renderedText,
      'ABC 123:ＡＢＣ　１２３',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 11)]?.renderedText,
      'ABC 123!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(16, 12)]?.renderedText,
      'ＡＢＣ　１２３！',
    );
    expect(sheet.cells[const FortuneCellCoord(20, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(20, 6)]?.renderedText, '#ERROR!');
    expect(sheet.cells[const FortuneCellCoord(21, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 7)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(22, 0)]?.renderedText,
      'alpha|beta|alpha|北|京',
    );
    expect(
      sheet.cells[const FortuneCellCoord(22, 1)]?.renderedText,
      'red|green',
    );
    expect(sheet.cells[const FortuneCellCoord(22, 2)]?.renderedText, '我|来');
    expect(sheet.cells[const FortuneCellCoord(23, 0)]?.renderedText, '!');
    expect(
      sheet.cells[const FortuneCellCoord(23, 1)]?.renderedText,
      'Monthly report',
    );
    expect(sheet.cells[const FortuneCellCoord(23, 2)]?.renderedText, '97');
    expect(sheet.cells[const FortuneCellCoord(23, 3)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(23, 4)]?.renderedText, 'a');
    expect(sheet.cells[const FortuneCellCoord(23, 5)]?.renderedText, 'a1');
    expect(sheet.cells[const FortuneCellCoord(23, 6)]?.renderedText, 'a1TRUE');
    expect(sheet.cells[const FortuneCellCoord(23, 7)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(23, 8)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(23, 9)]?.renderedText, 'F');
    expect(sheet.cells[const FortuneCellCoord(23, 10)]?.renderedText, 'Foo');
    expect(sheet.cells[const FortuneCellCoord(23, 11)]?.renderedText, '');
    expect(
      sheet.cells[const FortuneCellCoord(23, 12)]?.renderedText,
      'foo bar',
    );
    expect(sheet.cells[const FortuneCellCoord(23, 13)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(23, 14)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(23, 15)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(23, 16)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(23, 17)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(23, 18)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(24, 0)]?.renderedText, 'oo Ba');
    expect(sheet.cells[const FortuneCellCoord(24, 1)]?.renderedText, 'Foo Bar');
    expect(sheet.cells[const FortuneCellCoord(24, 2)]?.renderedText, 'f*r');
    expect(
      sheet.cells[const FortuneCellCoord(24, 3)]?.renderedText,
      'foo foo foo foo foo ',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 4)]?.renderedText, 'r');
    expect(sheet.cells[const FortuneCellCoord(24, 5)]?.renderedText, ' bar');
    expect(sheet.cells[const FortuneCellCoord(24, 6)]?.renderedText, '5');
    expect(
      sheet.cells[const FortuneCellCoord(24, 7)]?.renderedText,
      'foo bAr bAz',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 8)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(24, 9)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(24, 10)]?.renderedText, 'foo');
    expect(
      sheet.cells[const FortuneCellCoord(24, 21)]?.renderedText,
      'foo bar',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 22)]?.renderedText, 'fXoo');
    expect(
      sheet.cells[const FortuneCellCoord(24, 23)]?.renderedText,
      '#VALUE!',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 11)]?.renderedText, '!');
    expect(sheet.cells[const FortuneCellCoord(24, 12)]?.renderedText, '33');
    expect(
      sheet.cells[const FortuneCellCoord(24, 13)]?.renderedText,
      'FOO BAR',
    );
    expect(
      sheet.cells[const FortuneCellCoord(24, 14)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(24, 15)]?.renderedText,
      '#VALUE!',
    );
    expect(sheet.cells[const FortuneCellCoord(24, 16)]?.renderedText, 'I');
    expect(sheet.cells[const FortuneCellCoord(24, 17)]?.renderedText, 'XII');
    expect(sheet.cells[const FortuneCellCoord(24, 18)]?.renderedText, 'CMXCII');
    expect(sheet.cells[const FortuneCellCoord(24, 19)]?.renderedText, 'MM');
  });

  test('formula engine evaluates TRANSPOSE range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '5'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '6'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=TRANSPOSE(A1:C2)',
          formula: '=TRANSPOSE(A1:C2)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=ROWS(TRANSPOSE(A1:C2))&"x"&COLUMNS(TRANSPOSE(A1:C2))',
          formula: '=ROWS(TRANSPOSE(A1:C2))&"x"&COLUMNS(TRANSPOSE(A1:C2))',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=INDEX(TRANSPOSE(A1:C2), 2, 2)',
          formula: '=INDEX(TRANSPOSE(A1:C2), 2, 2)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=TRANSPOSE(A3:C3)',
          formula: '=TRANSPOSE(A3:C3)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=ROWS(TRANSPOSE(A3:C3))&"x"&COLUMNS(TRANSPOSE(A3:C3))',
          formula: '=ROWS(TRANSPOSE(A3:C3))&"x"&COLUMNS(TRANSPOSE(A3:C3))',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=INDEX(TRANSPOSE(A3:C3), 3, 1)',
          formula: '=INDEX(TRANSPOSE(A3:C3), 3, 1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '3x1');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '3');
  });

  test('formula engine evaluates LEN direct fixture', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=LEN("Foo Bar")',
          formula: '=LEN("Foo Bar")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '7');
  });

  test('formula engine evaluates text formatting active fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DOLLAR()',
          formula: '=DOLLAR()',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=DOLLAR(1100)',
          formula: '=DOLLAR(1100)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=DOLLAR(1100, -2)',
          formula: '=DOLLAR(1100, -2)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=FIXED()',
          formula: '=FIXED()',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=FIXED(12345.11, -1)',
          formula: '=FIXED(12345.11, -1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=FIXED(12345.11, 0)',
          formula: '=FIXED(12345.11, 0)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=FIXED(12345.11, 0, TRUE)',
          formula: '=FIXED(12345.11, 0, TRUE)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=FIXED(12345.11, 4, TRUE)',
          formula: '=FIXED(12345.11, 4, TRUE)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=VALUE()',
          formula: '=VALUE()',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: r'=VALUE("$1,000")',
          formula: r'=VALUE("$1,000")',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=VALUE("01:00:00")',
          formula: '=VALUE("01:00:00")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=VALUE("foo Bar")',
          formula: '=VALUE("foo Bar")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText,
      r'$1,100.00',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, r'$1,100');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '12,350');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '12,345');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '12345');
    expect(
      sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText,
      '12345.1100',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '1000');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '3600');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '0');
  });

  test('formula engine parses slash dates and meridiem times', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DATEVALUE("1/2/2024 3:04 PM")=DATE(2024,1,2)',
          formula: '=DATEVALUE("1/2/2024 3:04 PM")=DATE(2024,1,2)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=HOUR("1/2/2024 3:04 PM")',
          formula: '=HOUR("1/2/2024 3:04 PM")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MINUTE("1/2/2024 3:04 PM")',
          formula: '=MINUTE("1/2/2024 3:04 PM")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SECOND("1/2/2024 3:04:05.250 PM")',
          formula: '=SECOND("1/2/2024 3:04:05.250 PM")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=TIMEVALUE("12:30 AM")=TIME(0,30,0)',
          formula: '=TIMEVALUE("12:30 AM")=TIME(0,30,0)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=TIMEVALUE("12:30 PM")=TIME(12,30,0)',
          formula: '=TIMEVALUE("12:30 PM")=TIME(12,30,0)',
        ),
        const FortuneCellCoord(0, 6): const FortuneCell(
          value: '=ISDATE("2/29/2024 12:00 AM")',
          formula: '=ISDATE("2/29/2024 12:00 AM")',
        ),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=ISDATE("2/29/2023 12:00 AM")',
          formula: '=ISDATE("2/29/2023 12:00 AM")',
        ),
        const FortuneCellCoord(0, 8): const FortuneCell(
          value: '=DATEVALUE("2024/2/29")=DATE(2024,2,29)',
          formula: '=DATEVALUE("2024/2/29")=DATE(2024,2,29)',
        ),
        const FortuneCellCoord(0, 9): const FortuneCell(
          value: '=ISDATE("2023/2/29")',
          formula: '=ISDATE("2023/2/29")',
        ),
        const FortuneCellCoord(0, 10): const FortuneCell(
          value: '=ISDATE("1/2/2024 13:00 PM")',
          formula: '=ISDATE("1/2/2024 13:00 PM")',
        ),
        const FortuneCellCoord(0, 11): const FortuneCell(
          value:
              '=TIMEVALUE("1/2/2024 3:04:05.5 PM")='
              'TIMEVALUE("1/2/2024 3:04:05.500 PM")',
          formula:
              '=TIMEVALUE("1/2/2024 3:04:05.5 PM")='
              'TIMEVALUE("1/2/2024 3:04:05.500 PM")',
        ),
        const FortuneCellCoord(0, 12): const FortuneCell(
          value:
              '=DATEVALUE(" 1/2/2024 3:04 PM ")='
              'DATEVALUE("1/2/2024 3:04 PM")',
          formula:
              '=DATEVALUE(" 1/2/2024 3:04 PM ")='
              'DATEVALUE("1/2/2024 3:04 PM")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '15');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 8)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 10)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(0, 11)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(0, 12)]?.renderedText, 'TRUE');
  });

  test('formula engine evaluates information helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '42'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: 'text'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=1=1',
          formula: '=1=1',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=ISBLANK(A1)',
          formula: '=ISBLANK(A1)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=ISNUMBER(B1)',
          formula: '=ISNUMBER(B1)',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=ISTEXT(C1)',
          formula: '=ISTEXT(C1)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=ISLOGICAL(D1)',
          formula: '=ISLOGICAL(D1)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=ISBLANK(NULL)',
          formula: '=ISBLANK(NULL)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=ISLOGICAL(NULL)',
          formula: '=ISLOGICAL(NULL)',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=ISLOGICAL()',
          formula: '=ISLOGICAL()',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=ISNONTEXT(A1)',
          formula: '=ISNONTEXT(A1)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=A1+5',
          formula: '=A1+5',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=A1&"x"',
          formula: '=A1&"x"',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=COUNTA(A1:C1)',
          formula: '=COUNTA(A1:C1)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=COUNTBLANK(A1:C1)',
          formula: '=COUNTBLANK(A1:C1)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=COUNTBLANK(A1:C1, "")',
          formula: '=COUNTBLANK(A1:C1, "")',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=COUNTBLANK(NULL, "")',
          formula: '=COUNTBLANK(NULL, "")',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=AVERAGE(A1:B1)',
          formula: '=AVERAGE(A1:B1)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=AVERAGEA(A1:D1)',
          formula: '=AVERAGEA(A1:D1)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=MINA(A1:D1)',
          formula: '=MINA(A1:D1)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=MAXA(A1:D1)',
          formula: '=MAXA(A1:D1)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=N(TRUE)',
          formula: '=N(TRUE)',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=N("text")',
          formula: '=N("text")',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=N(A1)',
          formula: '=N(A1)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=N(NA())',
          formula: '=N(NA())',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=TYPE(42)',
          formula: '=TYPE(42)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=TYPE("text")',
          formula: '=TYPE("text")',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=TYPE(TRUE)',
          formula: '=TYPE(TRUE)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=TYPE(1/0)',
          formula: '=TYPE(1/0)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=TYPE({1,2})',
          formula: '=TYPE({1,2})',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=TYPE(CHOOSE({1,2}, "red", "blue"))',
          formula: '=TYPE(CHOOSE({1,2}, "red", "blue"))',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=ERROR.TYPE(#NULL!)',
          formula: '=ERROR.TYPE(#NULL!)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=ERROR.TYPE(1/0)',
          formula: '=ERROR.TYPE(1/0)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=ERROR.TYPE(UNKNOWN(1))',
          formula: '=ERROR.TYPE(UNKNOWN(1))',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=ERROR.TYPE(42)',
          formula: '=ERROR.TYPE(42)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=ERROR_TYPE(1/0)',
          formula: '=ERROR_TYPE(1/0)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=ERROR.TYPE(#VALUE!)',
          formula: '=ERROR.TYPE(#VALUE!)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=ERROR.TYPE(#REF!)',
          formula: '=ERROR.TYPE(#REF!)',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=ERROR.TYPE(#NUM!)',
          formula: '=ERROR.TYPE(#NUM!)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=ERROR.TYPE(NA())',
          formula: '=ERROR.TYPE(NA())',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=ERROR.TYPE(#GETTING_DATA)',
          formula: '=ERROR.TYPE(#GETTING_DATA)',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=ERROR.TYPE(#SPILL!)',
          formula: '=ERROR.TYPE(#SPILL!)',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=ERROR.TYPE(#CONNECT!)',
          formula: '=ERROR.TYPE(#CONNECT!)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=ERROR.TYPE(#BLOCKED!)',
          formula: '=ERROR.TYPE(#BLOCKED!)',
        ),
        const FortuneCellCoord(8, 8): const FortuneCell(
          value: '=ERROR.TYPE(#UNKNOWN!)',
          formula: '=ERROR.TYPE(#UNKNOWN!)',
        ),
        const FortuneCellCoord(8, 9): const FortuneCell(
          value: '=ERROR.TYPE(#FIELD!)',
          formula: '=ERROR.TYPE(#FIELD!)',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=1+2',
          formula: '=1+2',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=ISFORMULA(A10)',
          formula: '=ISFORMULA(A10)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=FORMULATEXT(A10)',
          formula: '=FORMULATEXT(A10)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=ISFORMULA(C1)',
          formula: '=ISFORMULA(C1)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=FORMULATEXT(C1)',
          formula: '=FORMULATEXT(C1)',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=ISREF(A1)',
          formula: '=ISREF(A1)',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: r'=ISREF($A$1:$D$4)',
          formula: r'=ISREF($A$1:$D$4)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=ISREF(42)',
          formula: '=ISREF(42)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=ISREF(UNKNOWN(1))',
          formula: '=ISREF(UNKNOWN(1))',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=ISREF(INDIRECT("A1:B2"))',
          formula: '=ISREF(INDIRECT("A1:B2"))',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=ISREF(OFFSET(A1, 1, 1))',
          formula: '=ISREF(OFFSET(A1, 1, 1))',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=ISREF(INDIRECT("missing"))',
          formula: '=ISREF(INDIRECT("missing"))',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=ISFORMULA(INDIRECT("A10"))',
          formula: '=ISFORMULA(INDIRECT("A10"))',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=FORMULATEXT(INDIRECT("A10"))',
          formula: '=FORMULATEXT(INDIRECT("A10"))',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=ISFORMULA(OFFSET(A10, 0, 0))',
          formula: '=ISFORMULA(OFFSET(A10, 0, 0))',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=FORMULATEXT(INDIRECT("C1"))',
          formula: '=FORMULATEXT(INDIRECT("C1"))',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=ISFORMULA(INDIRECT("A1:B2"))',
          formula: '=ISFORMULA(INDIRECT("A1:B2"))',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=ISERROR(#SPILL!)',
          formula: '=ISERROR(#SPILL!)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=IFERROR(#FIELD!, "field fallback")',
          formula: '=IFERROR(#FIELD!, "field fallback")',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=ISERR(#CONNECT!)',
          formula: '=ISERR(#CONNECT!)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=IFNA(#BLOCKED!, "missing")',
          formula: '=IFNA(#BLOCKED!, "missing")',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=SHEET()',
          formula: '=SHEET()',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=SHEET(A1)',
          formula: '=SHEET(A1)',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=SHEETS(A1:B2)',
          formula: '=SHEETS(A1:B2)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=SHEETS(INDIRECT("A1:B2"))',
          formula: '=SHEETS(INDIRECT("A1:B2"))',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=SHEET(42)',
          formula: '=SHEET(42)',
        ),
        const FortuneCellCoord(14, 5): const FortuneCell(
          value: '=SHEETS(UNKNOWN(1))',
          formula: '=SHEETS(UNKNOWN(1))',
        ),
        const FortuneCellCoord(14, 6): const FortuneCell(
          value: '=ISREF(Sheet1!A1:B2)',
          formula: '=ISREF(Sheet1!A1:B2)',
        ),
        const FortuneCellCoord(14, 7): const FortuneCell(
          value: '=ROW(\'Sheet1\'!C5:D8)',
          formula: '=ROW(\'Sheet1\'!C5:D8)',
        ),
        const FortuneCellCoord(14, 8): const FortuneCell(
          value: '=COLUMN(Sheet1!C5:D8)',
          formula: '=COLUMN(Sheet1!C5:D8)',
        ),
        const FortuneCellCoord(14, 9): const FortuneCell(
          value: '=ISREF([Book1.xlsx]Sheet1!A1:B2)',
          formula: '=ISREF([Book1.xlsx]Sheet1!A1:B2)',
        ),
        const FortuneCellCoord(14, 10): const FortuneCell(
          value: r"=ROW('[Book1.xlsx]Sheet1'!C5:D8)",
          formula: r"=ROW('[Book1.xlsx]Sheet1'!C5:D8)",
        ),
        const FortuneCellCoord(14, 11): const FortuneCell(
          value: '=COLUMN([Book1.xlsx]Sheet1!C5:D8)',
          formula: '=COLUMN([Book1.xlsx]Sheet1!C5:D8)',
        ),
        const FortuneCellCoord(14, 12): const FortuneCell(
          value:
              '=ROWS(Sheet1!A1:B2)&"x"&COLUMNS([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!B2)',
          formula:
              '=ROWS(Sheet1!A1:B2)&"x"&COLUMNS([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!B2)',
        ),
        const FortuneCellCoord(14, 13): const FortuneCell(
          value:
              '=ROWS(OFFSET(Sheet1!A1:Sheet1!A2,0,0))&"x"&COLUMNS(OFFSET([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!B2,0,0))',
          formula:
              '=ROWS(OFFSET(Sheet1!A1:Sheet1!A2,0,0))&"x"&COLUMNS(OFFSET([Book1.xlsx]Sheet1!A1:[Book1.xlsx]Sheet1!B2,0,0))',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=ISNUMBER()',
          formula: '=ISNUMBER()',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=ISTEXT()',
          formula: '=ISTEXT()',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=ISNONTEXT()',
          formula: '=ISNONTEXT()',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=COLUMNS()',
          formula: '=COLUMNS()',
        ),
        const FortuneCellCoord(15, 8): const FortuneCell(
          value: '=ROWS()',
          formula: '=ROWS()',
        ),
        const FortuneCellCoord(15, 9): const FortuneCell(
          value: '=ISEVEN(2.5)',
          formula: '=ISEVEN(2.5)',
        ),
        const FortuneCellCoord(15, 10): const FortuneCell(
          value: '=ISODD(2.5)',
          formula: '=ISODD(2.5)',
        ),
        const FortuneCellCoord(15, 11): const FortuneCell(
          value: '=ISNONTEXT(TRUE)',
          formula: '=ISNONTEXT(TRUE)',
        ),
        const FortuneCellCoord(15, 12): const FortuneCell(
          value: '=ISTEXT(TRUE)',
          formula: '=ISTEXT(TRUE)',
        ),
        const FortuneCellCoord(15, 13): const FortuneCell(
          value: '=ISTEXT("FALSE")',
          formula: '=ISTEXT("FALSE")',
        ),
        const FortuneCellCoord(15, 14): const FortuneCell(
          value: '=ISBINARY("1010")',
          formula: '=ISBINARY("1010")',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=ISFORMULA(Sheet1!A10)',
          formula: '=ISFORMULA(Sheet1!A10)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=FORMULATEXT(Sheet1!A10)',
          formula: '=FORMULATEXT(Sheet1!A10)',
        ),
        const FortuneCellCoord(15, 6): const FortuneCell(
          value: r"=ISFORMULA('[Book1.xlsx]Sheet1'!A10)",
          formula: r"=ISFORMULA('[Book1.xlsx]Sheet1'!A10)",
        ),
        const FortuneCellCoord(15, 7): const FortuneCell(
          value: r"=FORMULATEXT('[Book1.xlsx]Sheet1'!A10)",
          formula: r"=FORMULATEXT('[Book1.xlsx]Sheet1'!A10)",
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=CELL("address", B1)',
          formula: '=CELL("address", B1)',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=CELL("row", C1)',
          formula: '=CELL("row", C1)',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=CELL("col", C1)',
          formula: '=CELL("col", C1)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=CELL("contents", B1)',
          formula: '=CELL("contents", B1)',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=CELL("contents", C1)',
          formula: '=CELL("contents", C1)',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=CELL("type", A1)',
          formula: '=CELL("type", A1)',
        ),
        const FortuneCellCoord(16, 6): const FortuneCell(
          value: '=CELL("type", B1)',
          formula: '=CELL("type", B1)',
        ),
        const FortuneCellCoord(16, 7): const FortuneCell(
          value: '=CELL("type", C1)',
          formula: '=CELL("type", C1)',
        ),
        const FortuneCellCoord(16, 8): const FortuneCell(
          value: '=CELL("row", Sheet1!C1)',
          formula: '=CELL("row", Sheet1!C1)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=INFO("recalc")',
          formula: '=INFO("recalc")',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=INFO("numfile")',
          formula: '=INFO("numfile")',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=INFO("system")',
          formula: '=INFO("system")',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=INFO("unknown")',
          formula: '=INFO("unknown")',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(
          value: '=ISDATE("2024-02-29")',
          formula: '=ISDATE("2024-02-29")',
        ),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=ISDATE("not a date")',
          formula: '=ISDATE("not a date")',
        ),
        const FortuneCellCoord(18, 2): const FortuneCell(
          value: '=ISDATE(DATE(2024, 2, 29))',
          formula: '=ISDATE(DATE(2024, 2, 29))',
        ),
        const FortuneCellCoord(18, 3): const FortuneCell(
          value: '=TO_PURE_NUMBER("1,234")',
          formula: '=TO_PURE_NUMBER("1,234")',
        ),
        const FortuneCellCoord(18, 4): const FortuneCell(
          value: '=TO_TEXT(12.5)',
          formula: '=TO_TEXT(12.5)',
        ),
        const FortuneCellCoord(18, 5): const FortuneCell(
          value: '=TO_DATE(45292)',
          formula: '=TO_DATE(45292)',
        ),
        const FortuneCellCoord(18, 6): const FortuneCell(
          value: '=TO_PERCENT(0.5)',
          formula: '=TO_PERCENT(0.5)',
        ),
        const FortuneCellCoord(18, 7): const FortuneCell(
          value: '=TO_DOLLARS("abc")',
          formula: '=TO_DOLLARS("abc")',
        ),
        const FortuneCellCoord(18, 8): const FortuneCell(
          value: '=ISIDCARD("11010519491231002X")',
          formula: '=ISIDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 9): const FortuneCell(
          value: '=ISIDCARD("110105194912310021")',
          formula: '=ISIDCARD("110105194912310021")',
        ),
        const FortuneCellCoord(18, 10): const FortuneCell(
          value: '=BIRTHDAY_BY_IDCARD("11010519491231002X", 1)',
          formula: '=BIRTHDAY_BY_IDCARD("11010519491231002X", 1)',
        ),
        const FortuneCellCoord(18, 11): const FortuneCell(
          value: '=SEX_BY_IDCARD("11010519491231002X")',
          formula: '=SEX_BY_IDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 12): const FortuneCell(
          value: '=PROVINCE_BY_IDCARD("11010519491231002X")',
          formula: '=PROVINCE_BY_IDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 13): const FortuneCell(
          value: '=CITY_BY_IDCARD("11010519491231002X")',
          formula: '=CITY_BY_IDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 14): const FortuneCell(
          value: '=STAR_BY_IDCARD("11010519491231002X")',
          formula: '=STAR_BY_IDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 15): const FortuneCell(
          value: '=ANIMAL_BY_IDCARD("11010519491231002X")',
          formula: '=ANIMAL_BY_IDCARD("11010519491231002X")',
        ),
        const FortuneCellCoord(18, 16): const FortuneCell(
          value: '=AGE_BY_IDCARD("11010519491231002X", "2017-10-01")',
          formula: '=AGE_BY_IDCARD("11010519491231002X", "2017-10-01")',
        ),
        const FortuneCellCoord(19, 0): const FortuneCell(
          value: '=EVALUATE("B1+8")',
          formula: '=EVALUATE("B1+8")',
        ),
        const FortuneCellCoord(19, 1): const FortuneCell(
          value: '=EVALUATE("=SUM({1,2;3,4})")',
          formula: '=EVALUATE("=SUM({1,2;3,4})")',
        ),
        const FortuneCellCoord(19, 2): const FortuneCell(
          value: '=DATA_CN_STOCK_CLOSE("000001")',
          formula: '=DATA_CN_STOCK_CLOSE("000001")',
        ),
        const FortuneCellCoord(19, 3): const FortuneCell(
          value: '=GETPIVOTDATA("Sales", A1)',
          formula: '=GETPIVOTDATA("Sales", A1)',
        ),
        const FortuneCellCoord(19, 4): const FortuneCell(
          value: '=REMOTE("SUM(A1:A10000000)")',
          formula: '=REMOTE("SUM(A1:A10000000)")',
        ),
        const FortuneCellCoord(20, 0): const FortuneCell(
          value: '=ISBLANK(FALSE)',
          formula: '=ISBLANK(FALSE)',
        ),
        const FortuneCellCoord(20, 1): const FortuneCell(
          value: '=ISBLANK(0)',
          formula: '=ISBLANK(0)',
        ),
        const FortuneCellCoord(20, 2): const FortuneCell(
          value: '=ISEVEN(1)',
          formula: '=ISEVEN(1)',
        ),
        const FortuneCellCoord(20, 3): const FortuneCell(
          value: '=ISEVEN(2)',
          formula: '=ISEVEN(2)',
        ),
        const FortuneCellCoord(20, 4): const FortuneCell(
          value: '=ISODD(1)',
          formula: '=ISODD(1)',
        ),
        const FortuneCellCoord(20, 5): const FortuneCell(
          value: '=ISODD(2)',
          formula: '=ISODD(2)',
        ),
        const FortuneCellCoord(20, 6): const FortuneCell(
          value: '=ISLOGICAL(1)',
          formula: '=ISLOGICAL(1)',
        ),
        const FortuneCellCoord(20, 7): const FortuneCell(
          value: '=ISLOGICAL(TRUE)',
          formula: '=ISLOGICAL(TRUE)',
        ),
        const FortuneCellCoord(20, 8): const FortuneCell(
          value: '=ISLOGICAL(FALSE)',
          formula: '=ISLOGICAL(FALSE)',
        ),
        const FortuneCellCoord(20, 9): const FortuneCell(
          value: '=ISNONTEXT(1)',
          formula: '=ISNONTEXT(1)',
        ),
        const FortuneCellCoord(20, 10): const FortuneCell(
          value: '=ISNONTEXT("FALSE")',
          formula: '=ISNONTEXT("FALSE")',
        ),
        const FortuneCellCoord(20, 11): const FortuneCell(
          value: '=ISNONTEXT("foo")',
          formula: '=ISNONTEXT("foo")',
        ),
        const FortuneCellCoord(20, 12): const FortuneCell(
          value: '=ISNUMBER(0.142342)',
          formula: '=ISNUMBER(0.142342)',
        ),
        const FortuneCellCoord(20, 13): const FortuneCell(
          value: '=ISNUMBER(TRUE)',
          formula: '=ISNUMBER(TRUE)',
        ),
        const FortuneCellCoord(20, 14): const FortuneCell(
          value: '=ISNUMBER("FALSE")',
          formula: '=ISNUMBER("FALSE")',
        ),
        const FortuneCellCoord(20, 15): const FortuneCell(
          value: '=ISTEXT(1)',
          formula: '=ISTEXT(1)',
        ),
        const FortuneCellCoord(20, 16): const FortuneCell(
          value: '=ISTEXT("foo")',
          formula: '=ISTEXT("foo")',
        ),
        const FortuneCellCoord(20, 17): const FortuneCell(
          value: '=ISNUMBER("foo")',
          formula: '=ISNUMBER("foo")',
        ),
        const FortuneCellCoord(20, 18): const FortuneCell(
          value: '=ISNUMBER(1)',
          formula: '=ISNUMBER(1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, 'x');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '42');
    expect(
      sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText,
      '14.333333333333',
    );
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '16');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '64');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '11');
    expect(sheet.cells[const FortuneCellCoord(8, 8)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(8, 9)]?.renderedText, '13');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '=1+2');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '=1+2');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, 'TRUE');
    expect(
      sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText,
      'field fallback',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, 'TRUE');
    expect(
      sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText,
      '#BLOCKED!',
    );
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(14, 5)]?.renderedText, '#NAME?');
    expect(sheet.cells[const FortuneCellCoord(14, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(14, 7)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(14, 8)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(14, 9)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(14, 10)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(14, 11)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(14, 12)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(14, 13)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(15, 8)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(15, 9)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 10)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(15, 11)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 12)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(15, 13)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 14)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText, '=1+2');
    expect(sheet.cells[const FortuneCellCoord(15, 6)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(15, 7)]?.renderedText, '=1+2');
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, r'$B$1');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '42');
    expect(sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText, 'text');
    expect(sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText, 'b');
    expect(sheet.cells[const FortuneCellCoord(16, 6)]?.renderedText, 'v');
    expect(sheet.cells[const FortuneCellCoord(16, 7)]?.renderedText, 'l');
    expect(sheet.cells[const FortuneCellCoord(16, 8)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText,
      'Automatic',
    );
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText, 'pcdos');
    expect(sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(18, 0)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(18, 2)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(18, 3)]?.renderedText, '1234');
    expect(sheet.cells[const FortuneCellCoord(18, 4)]?.renderedText, '12.5');
    expect(sheet.cells[const FortuneCellCoord(18, 5)]?.renderedText, '45292');
    expect(sheet.cells[const FortuneCellCoord(18, 6)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(18, 7)]?.renderedText, 'abc');
    expect(sheet.cells[const FortuneCellCoord(18, 8)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(18, 9)]?.renderedText, 'FALSE');
    expect(
      sheet.cells[const FortuneCellCoord(18, 10)]?.renderedText,
      '1949-12-31',
    );
    expect(sheet.cells[const FortuneCellCoord(18, 11)]?.renderedText, '女');
    expect(sheet.cells[const FortuneCellCoord(18, 12)]?.renderedText, '北京市');
    expect(sheet.cells[const FortuneCellCoord(18, 13)]?.renderedText, '北京市');
    expect(sheet.cells[const FortuneCellCoord(18, 14)]?.renderedText, '摩羯座');
    expect(sheet.cells[const FortuneCellCoord(18, 15)]?.renderedText, '牛');
    expect(sheet.cells[const FortuneCellCoord(18, 16)]?.renderedText, '67');
    expect(sheet.cells[const FortuneCellCoord(19, 0)]?.renderedText, '50');
    expect(sheet.cells[const FortuneCellCoord(19, 1)]?.renderedText, '10');
    expect(
      sheet.cells[const FortuneCellCoord(19, 2)]?.renderedText,
      '#GETTING_DATA',
    );
    expect(sheet.cells[const FortuneCellCoord(19, 3)]?.renderedText, '#N/A');
    expect(
      sheet.cells[const FortuneCellCoord(19, 4)]?.renderedText,
      '#GETTING_DATA',
    );
    expect(sheet.cells[const FortuneCellCoord(20, 0)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 1)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 2)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 3)]?.renderedText, 'TRUE');

    expect(sheet.cells[const FortuneCellCoord(20, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 5)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 6)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 7)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 8)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 9)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 10)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 11)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 12)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 13)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 14)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 15)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 16)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(20, 17)]?.renderedText, 'FALSE');
    expect(sheet.cells[const FortuneCellCoord(20, 18)]?.renderedText, 'TRUE');
  });

  test('formula engine evaluates indexed row and column vectors', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '6'),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=ROW(A1:B3)',
          formula: '=ROW(A1:B3)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=COLUMN(A1:B3)',
          formula: '=COLUMN(A1:B3)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=ROW(A1:B3, -1)',
          formula: '=ROW(A1:B3, -1)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=INDEX(ROW(A1:B3, 0), 1, 2)',
          formula: '=INDEX(ROW(A1:B3, 0), 1, 2)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=INDEX(ROW(A1:B3, 2), 1, 2)',
          formula: '=INDEX(ROW(A1:B3, 2), 1, 2)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=INDEX(COLUMN(A1:B3, 0), 3, 1)',
          formula: '=INDEX(COLUMN(A1:B3, 0), 3, 1)',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=INDEX(COLUMN(A1:B3, 1), 3, 1)',
          formula: '=INDEX(COLUMN(A1:B3, 1), 3, 1)',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=ROWS(A1:B3)&"x"&COLUMNS(A1:B3)',
          formula: '=ROWS(A1:B3)&"x"&COLUMNS(A1:B3)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=JOIN(ROW(A1:C2, 0))',
          formula: '=JOIN(ROW(A1:C2, 0))',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=JOIN(COLUMN(A1:C2, 0))',
          formula: '=JOIN(COLUMN(A1:C2, 0))',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=JOIN(COLUMN(A1:C2, 1))',
          formula: '=JOIN(COLUMN(A1:C2, 1))',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=ROWS(A1:C2)&"x"&COLUMNS(A1:C2)',
          formula: '=ROWS(A1:C2)&"x"&COLUMNS(A1:C2)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '1,2,3');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '1,2');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '2,3');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '2x3');
  });

  test(
    'formula engine evaluates CELL omitted reference against current cell',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        cells: {
          const FortuneCellCoord(4, 3): const FortuneCell(
            value: '=CELL("address")',
            formula: '=CELL("address")',
          ),
          const FortuneCellCoord(5, 4): const FortuneCell(
            value: '=CELL("row")',
            formula: '=CELL("row")',
          ),
          const FortuneCellCoord(6, 5): const FortuneCell(
            value: '=CELL("col")',
            formula: '=CELL("col")',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, r'$D$5');
      expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '6');
      expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '6');
    },
  );

  test('formula engine evaluates CELL with dynamic references', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 1): const FortuneCell(value: 'B1'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: 'B2'),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=CELL("address", INDIRECT("B1"))',
          formula: '=CELL("address", INDIRECT("B1"))',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=CELL("row", OFFSET(A1, 1, 1))',
          formula: '=CELL("row", OFFSET(A1, 1, 1))',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=CELL("col", OFFSET(A1, 1, 1))',
          formula: '=CELL("col", OFFSET(A1, 1, 1))',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, r'$B$1');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '2');
  });

  test('formula engine stores sparkline formula results', () {
    final sheet = FortuneSheet(
      id: 'sheet1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value:
              '=LINESPLINES(A1:A3, "#ff0000", 2, "avg", "#00ff00", "#0000ff", "#ff00ff", 4)',
          formula:
              '=LINESPLINES(A1:A3, "#ff0000", 2, "avg", "#00ff00", "#0000ff", "#ff00ff", 4)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=PIESPLINES({1,2,3}, 45, 2, "#111111", "#ff0000", "#00ff00")',
          formula:
              '=PIESPLINES({1,2,3}, 45, 2, "#111111", "#ff0000", "#00ff00")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=COMPOSESPLINES(LINESPLINES(A1:A3), PIESPLINES({1,2,3}))',
          formula: '=COMPOSESPLINES(LINESPLINES(A1:A3), PIESPLINES({1,2,3}))',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value:
              '=AREASPLINES(A1:A3, "#ff0000", "#00ff00", 3, "median", "#123456")',
          formula:
              '=AREASPLINES(A1:A3, "#ff0000", "#00ff00", 3, "median", "#123456")',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=COLUMNSPLINES({1,-2,3}, 1, "#0000ff", "#00ff00")',
          formula: '=COLUMNSPLINES({1,-2,3}, 1, "#0000ff", "#00ff00")',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=DISCRETESPLINES({0,2}, 1, "#0000ff", "#00ff00")',
          formula: '=DISCRETESPLINES({0,2}, 1, "#0000ff", "#00ff00")',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value:
              '=TRISTATESPLINES({0,1,-1}, 1, "#0000ff", "#00ff00", "#ff00ff", "0:#111111", "1:#222222")',
          formula:
              '=TRISTATESPLINES({0,1,-1}, 1, "#0000ff", "#00ff00", "#ff00ff", "0:#111111", "1:#222222")',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=BOXSPLINES({1,2,3,4,5}, 1.5, 4, 3)',
          formula: '=BOXSPLINES({1,2,3,4,5}, 1.5, 4, 3)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=COLUMNSPLINES({1,2,3}, 7, "#0000ff", "#00ff00")',
          formula: '=COLUMNSPLINES({1,2,3}, 7, "#0000ff", "#00ff00")',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=BARSPLINES({10,20}, 1, "#0000ff", "#00ff00", 40)',
          formula: '=BARSPLINES({10,20}, 1, "#0000ff", "#00ff00", 40)',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value:
              '=COLUMNSPLINES({1,2,3}, 1, "#0000ff", "#00ff00", 10, "#111111", "2:#222222", "3:4:#333333")',
          formula:
              '=COLUMNSPLINES({1,2,3}, 1, "#0000ff", "#00ff00", 10, "#111111", "2:#222222", "3:4:#333333")',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=STACKCOLUMNSPLINES({1,2}, 1, 1, 6, "#0000ff", "#00ff00")',
          formula: '=STACKCOLUMNSPLINES({1,2}, 1, 1, 6, "#0000ff", "#00ff00")',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value:
              '=STACKCOLUMNSPLINES({1,2;3,4}, 1, 5, 10, "#0000ff", "#00ff00")',
          formula:
              '=STACKCOLUMNSPLINES({1,2;3,4}, 1, 5, 10, "#0000ff", "#00ff00")',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=STACKBARSPLINES({1,2;3,4}, 0, 4)',
          formula: '=STACKBARSPLINES({1,2;3,4}, 0, 4)',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=BULLETSPLINES(10, 8, 12)',
          formula: '=BULLETSPLINES(10, 8, 12)',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=BARSPLINES({1,2,3}, 9)',
          formula: '=BARSPLINES({1,2,3}, 9)',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=COLUMNSPLINES(A1:A3)',
          formula: '=COLUMNSPLINES(A1:A3)',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=BARSPLINES(A1:A3)',
          formula: '=BARSPLINES(A1:A3)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    final lineSparkline = sheet.cells[const FortuneCellCoord(0, 1)]?.sparkline;
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, isEmpty);
    expect(lineSparkline, isA<Map>());
    final lineMap = lineSparkline! as Map;
    expect(lineMap['type'], 'line');
    expect(lineMap['data'], [1.0, 2.0, 3.0]);
    expect(lineMap['color'], '#ff0000');
    expect(lineMap['lineWidth'], 2.0);
    expect(lineMap['normalRange'], 'avg');
    expect(lineMap['normalRangeColor'], '#00ff00');
    expect(lineMap['maxSpotColor'], '#0000ff');
    expect(lineMap['minSpotColor'], '#ff00ff');
    expect(lineMap['spotRadius'], 4.0);

    final pieSparkline = sheet.cells[const FortuneCellCoord(1, 1)]?.sparkline;
    expect(pieSparkline, isA<Map>());
    final pieMap = pieSparkline! as Map;
    expect(pieMap['type'], 'pie');
    expect(pieMap['data'], [1.0, 2.0, 3.0]);
    expect(pieMap['offset'], 45.0);
    expect(pieMap['borderWidth'], 2.0);
    expect(pieMap['borderColor'], '#111111');
    expect(pieMap['sliceColors'], ['#ff0000', '#00ff00']);

    final composeSparkline =
        sheet.cells[const FortuneCellCoord(2, 1)]?.sparkline;
    expect(composeSparkline, isA<Map>());
    final composeMap = composeSparkline! as Map;
    expect(composeMap['type'], 'compose');
    expect(composeMap['children'], hasLength(2));

    final areaSparkline = sheet.cells[const FortuneCellCoord(3, 1)]?.sparkline;
    expect(areaSparkline, isA<Map>());
    final areaMap = areaSparkline! as Map;
    expect(areaMap['type'], 'area');
    expect(areaMap['color'], '#ff0000');
    expect(areaMap['fillColor'], '#00ff00');
    expect(areaMap['lineWidth'], 3.0);
    expect(areaMap['normalRange'], 'median');
    expect(areaMap['normalRangeColor'], '#123456');

    final columnSparkline =
        sheet.cells[const FortuneCellCoord(4, 1)]?.sparkline;
    expect(columnSparkline, isA<Map>());
    final columnMap = columnSparkline! as Map;
    expect(columnMap['type'], 'column');
    expect(columnMap['data'], [1.0, -2.0, 3.0]);
    expect(columnMap['color'], '#0000ff');
    expect(columnMap['negativeColor'], '#00ff00');

    final discreteSparkline =
        sheet.cells[const FortuneCellCoord(5, 1)]?.sparkline;
    expect(discreteSparkline, isA<Map>());
    final discreteMap = discreteSparkline! as Map;
    expect(discreteMap['type'], 'discrete');
    expect(discreteMap['data'], [0.0, 2.0]);
    expect(discreteMap['thresholdValue'], 1.0);
    expect(discreteMap['color'], '#0000ff');
    expect(discreteMap['negativeColor'], '#00ff00');

    final tristateSparkline =
        sheet.cells[const FortuneCellCoord(6, 1)]?.sparkline;
    expect(tristateSparkline, isA<Map>());
    final tristateMap = tristateSparkline! as Map;
    expect(tristateMap['type'], 'tristate');
    expect(tristateMap['data'], [0.0, 1.0, -1.0]);
    expect(tristateMap['barSpacing'], 1.0);
    expect(tristateMap['color'], '#0000ff');
    expect(tristateMap['negativeColor'], '#00ff00');
    expect(tristateMap['zeroColor'], '#ff00ff');
    expect(tristateMap['colorMap'], ['0:#111111', '1:#222222']);

    final boxSparkline = sheet.cells[const FortuneCellCoord(7, 1)]?.sparkline;
    expect(boxSparkline, isA<Map>());
    final boxMap = boxSparkline! as Map;
    expect(boxMap['type'], 'box');
    expect(boxMap['data'], [1.0, 2.0, 3.0, 4.0, 5.0]);
    expect(boxMap['outlierIQR'], 1.5);
    expect(boxMap['targetValue'], 4.0);
    expect(boxMap['spotRadius'], 3.0);

    final spacedColumnSparkline =
        sheet.cells[const FortuneCellCoord(8, 1)]?.sparkline;
    expect(spacedColumnSparkline, isA<Map>());
    final spacedColumnMap = spacedColumnSparkline! as Map;
    expect(spacedColumnMap['type'], 'column');
    expect(spacedColumnMap['data'], [1.0, 2.0, 3.0]);
    expect(spacedColumnMap['barSpacing'], 7.0);
    expect(spacedColumnMap['color'], '#0000ff');
    expect(spacedColumnMap['negativeColor'], '#00ff00');

    final rangedBarSparkline =
        sheet.cells[const FortuneCellCoord(9, 1)]?.sparkline;
    expect(rangedBarSparkline, isA<Map>());
    final rangedBarMap = rangedBarSparkline! as Map;
    expect(rangedBarMap['type'], 'bar');
    expect(rangedBarMap['data'], [10.0, 20.0]);
    expect(rangedBarMap['barSpacing'], 1.0);
    expect(rangedBarMap['color'], '#0000ff');
    expect(rangedBarMap['negativeColor'], '#00ff00');
    expect(rangedBarMap['chartRangeMax'], 40.0);

    final mappedColumnSparkline =
        sheet.cells[const FortuneCellCoord(10, 1)]?.sparkline;
    expect(mappedColumnSparkline, isA<Map>());
    final mappedColumnMap = mappedColumnSparkline! as Map;
    expect(mappedColumnMap['type'], 'column');
    expect(mappedColumnMap['data'], [1.0, 2.0, 3.0]);
    expect(mappedColumnMap['chartRangeMax'], 10.0);
    expect(mappedColumnMap['colorMap'], [
      '#111111',
      '2:#222222',
      '3:4:#333333',
    ]);

    final stackedColumnSparkline =
        sheet.cells[const FortuneCellCoord(11, 1)]?.sparkline;
    expect(stackedColumnSparkline, isA<Map>());
    final stackedColumnMap = stackedColumnSparkline! as Map;
    expect(stackedColumnMap['type'], 'stackcolumn');
    expect(stackedColumnMap['data'], [1.0, 2.0]);
    expect(stackedColumnMap['chartRangeMax'], 6.0);
    expect(stackedColumnMap['stackedBarColors'], ['#0000ff', '#00ff00']);

    final groupedStackedColumnSparkline =
        sheet.cells[const FortuneCellCoord(12, 1)]?.sparkline;
    expect(groupedStackedColumnSparkline, isA<Map>());
    final groupedStackedColumnMap = groupedStackedColumnSparkline! as Map;
    expect(groupedStackedColumnMap['type'], 'stackcolumn');
    expect(groupedStackedColumnMap['data'], [1.0, 2.0, 3.0, 4.0]);
    expect(groupedStackedColumnMap['stackGroups'], [
      [1.0, 3.0],
      [2.0, 4.0],
    ]);
    expect(groupedStackedColumnMap['barSpacing'], 5.0);
    expect(groupedStackedColumnMap['chartRangeMax'], 10.0);

    final groupedStackedBarSparkline =
        sheet.cells[const FortuneCellCoord(13, 1)]?.sparkline;
    expect(groupedStackedBarSparkline, isA<Map>());
    final groupedStackedBarMap = groupedStackedBarSparkline! as Map;
    expect(groupedStackedBarMap['type'], 'stackbar');
    expect(groupedStackedBarMap['stackGroups'], [
      [1.0, 2.0],
      [3.0, 4.0],
    ]);
    expect(groupedStackedBarMap['barSpacing'], 4.0);
    expect(groupedStackedBarMap.containsKey('chartRangeMax'), isFalse);

    final bulletSparkline =
        sheet.cells[const FortuneCellCoord(14, 1)]?.sparkline;
    expect(bulletSparkline, isA<Map>());
    final bulletMap = bulletSparkline! as Map;
    expect(bulletMap['type'], 'bullet');
    expect(bulletMap['data'], [10.0, 8.0, 12.0]);

    final barSpacingOnlySparkline =
        sheet.cells[const FortuneCellCoord(15, 1)]?.sparkline;
    expect(barSpacingOnlySparkline, isA<Map>());
    final barSpacingOnlyMap = barSpacingOnlySparkline! as Map;
    expect(barSpacingOnlyMap['type'], 'bar');
    expect(barSpacingOnlyMap['data'], [1.0, 2.0, 3.0]);
    expect(barSpacingOnlyMap['barSpacing'], 9.0);
    expect(barSpacingOnlyMap.containsKey('color'), isFalse);

    final minimalColumnSparkline =
        sheet.cells[const FortuneCellCoord(16, 1)]?.sparkline;
    expect(minimalColumnSparkline, isA<Map>());
    final minimalColumnMap = minimalColumnSparkline! as Map;
    expect(minimalColumnMap['type'], 'column');
    expect(minimalColumnMap['data'], [1.0, 2.0, 3.0]);
    expect(minimalColumnMap.containsKey('barSpacing'), isFalse);
    expect(minimalColumnMap.containsKey('color'), isFalse);

    final minimalBarSparkline =
        sheet.cells[const FortuneCellCoord(17, 1)]?.sparkline;
    expect(minimalBarSparkline, isA<Map>());
    final minimalBarMap = minimalBarSparkline! as Map;
    expect(minimalBarMap['type'], 'bar');
    expect(minimalBarMap['data'], [1.0, 2.0, 3.0]);
    expect(minimalBarMap.containsKey('barSpacing'), isFalse);
    expect(minimalBarMap.containsKey('color'), isFalse);
  });

  test('formula engine serializes computed sparkline results', () {
    const formula =
        '=LINESPLINES(A1:A3, "#ff0000", 2, "avg", "#00ff00", "#0000ff", "#ff00ff", 4)';
    final sheet = FortuneSheet(
      id: 'sheet1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: formula,
          formula: formula,
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final celldata = json['celldata']! as List;
    final sparklineCell =
        celldata.singleWhere(
              (entry) => entry is Map && entry['r'] == 0 && entry['c'] == 1,
            )
            as Map;
    final cellJson = sparklineCell['v']! as Map;

    expect(cellJson['f'], formula);
    expect(cellJson['m'], isEmpty);
    expect(cellJson['spl'], {
      'type': 'line',
      'data': [1.0, 2.0, 3.0],
      'color': '#ff0000',
      'lineWidth': 2.0,
      'normalRange': 'avg',
      'normalRangeColor': '#00ff00',
      'maxSpotColor': '#0000ff',
      'minSpotColor': '#ff00ff',
      'spotRadius': 4.0,
    });
  });

  test('formula engine evaluates conditional aggregations', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '3'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '5'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: 'north'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: 'northwest'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: 'south'),
        const FortuneCellCoord(14, 0): const FortuneCell(value: 'a*'),
        const FortuneCellCoord(15, 0): const FortuneCell(value: 'a?'),
        const FortuneCellCoord(16, 0): const FortuneCell(value: 'a~'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '10'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '20'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '30'),
        const FortuneCellCoord(14, 2): const FortuneCell(value: '10'),
        const FortuneCellCoord(15, 2): const FortuneCell(value: '20'),
        const FortuneCellCoord(16, 2): const FortuneCell(value: '30'),
        const FortuneCellCoord(0, 3): const FortuneCell(value: 'open'),
        const FortuneCellCoord(1, 3): const FortuneCell(value: 'closed'),
        const FortuneCellCoord(2, 3): const FortuneCell(value: 'open'),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=COUNTIF(A1:A3, ">2")',
          formula: '=COUNTIF(A1:A3, ">2")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUMIF(A1:A3, ">=3")',
          formula: '=SUMIF(A1:A3, ">=3")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=AVERAGEIF(A1:A3, "<>1")',
          formula: '=AVERAGEIF(A1:A3, "<>1")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=COUNTIF(A4:A6, "north*")',
          formula: '=COUNTIF(A4:A6, "north*")',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=COUNTIF(A4:A6, "<>south")',
          formula: '=COUNTIF(A4:A6, "<>south")',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=SUMIF(A1:A3, ">=3", C1:C3)',
          formula: '=SUMIF(A1:A3, ">=3", C1:C3)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=AVERAGEIF(A4:A6, "north*", C1:C3)',
          formula: '=AVERAGEIF(A4:A6, "north*", C1:C3)',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=COUNTIFS(A1:A3, ">1", D1:D3, "open")',
          formula: '=COUNTIFS(A1:A3, ">1", D1:D3, "open")',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=SUMIFS(C1:C3, A1:A3, ">1", D1:D3, "open")',
          formula: '=SUMIFS(C1:C3, A1:A3, ">1", D1:D3, "open")',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=AVERAGEIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
          formula: '=AVERAGEIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=MAXIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
          formula: '=MAXIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=MINIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
          formula: '=MINIFS(C1:C3, A1:A3, ">1", D1:D3, "<>closed")',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=MAXIFS(C1:C3, A1:A3, ">10")',
          formula: '=MAXIFS(C1:C3, A1:A3, ">10")',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=MINIFS(C1:C3, A1:A2, ">1")',
          formula: '=MINIFS(C1:C3, A1:A2, ">1")',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=COUNTIF(A15:A17, "a~*")',
          formula: '=COUNTIF(A15:A17, "a~*")',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=SUMIF(A15:A17, "a~?", C15:C17)',
          formula: '=SUMIF(A15:A17, "a~?", C15:C17)',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=COUNTIF(A15:A17, "a~~")',
          formula: '=COUNTIF(A15:A17, "a~~")',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=COUNTIF(A15:A17, "<>a~~")',
          formula: '=COUNTIF(A15:A17, "<>a~~")',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(value: 'big'),
        const FortuneCellCoord(19, 0): const FortuneCell(value: 'big'),
        const FortuneCellCoord(18, 2): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(19, 2): const FortuneCell(value: '1e308'),
        const FortuneCellCoord(18, 3): const FortuneCell(value: 'open'),
        const FortuneCellCoord(19, 3): const FortuneCell(value: 'open'),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=SUMIF(A19:A20, "big", C19:C20)',
          formula: '=SUMIF(A19:A20, "big", C19:C20)',
        ),
        const FortuneCellCoord(19, 1): const FortuneCell(
          value: '=SUMIFS(C19:C20, A19:A20, "big", D19:D20, "open")',
          formula: '=SUMIFS(C19:C20, A19:A20, "big", D19:D20, "open")',
        ),
        const FortuneCellCoord(20, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(20, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(20, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(20, 3): const FortuneCell(
          value: '=SUMIFS(A21:C21, ">1", "<3")',
          formula: '=SUMIFS(A21:C21, ">1", "<3")',
        ),
        const FortuneCellCoord(20, 4): const FortuneCell(
          value: '=SUMIF(A21:C21, ">2")',
          formula: '=SUMIF(A21:C21, ">2")',
        ),
        const FortuneCellCoord(21, 0): const FortuneCell(),
        const FortuneCellCoord(22, 0): const FortuneCell(value: ''),
        const FortuneCellCoord(23, 0): const FortuneCell(value: 'filled'),
        const FortuneCellCoord(21, 2): const FortuneCell(value: 'open'),
        const FortuneCellCoord(22, 2): const FortuneCell(value: 'closed'),
        const FortuneCellCoord(23, 2): const FortuneCell(value: 'open'),
        const FortuneCellCoord(21, 3): const FortuneCell(value: '5'),
        const FortuneCellCoord(22, 3): const FortuneCell(value: '7'),
        const FortuneCellCoord(23, 3): const FortuneCell(value: '11'),
        const FortuneCellCoord(21, 1): const FortuneCell(
          value: '=COUNTIF(A22:A24, "")',
          formula: '=COUNTIF(A22:A24, "")',
        ),
        const FortuneCellCoord(22, 1): const FortuneCell(
          value: '=COUNTIF(A22:A24, NULL)',
          formula: '=COUNTIF(A22:A24, NULL)',
        ),
        const FortuneCellCoord(23, 1): const FortuneCell(
          value: '=COUNTIFS(A22:A24, "", C22:C24, "open")',
          formula: '=COUNTIFS(A22:A24, "", C22:C24, "open")',
        ),
        const FortuneCellCoord(24, 1): const FortuneCell(
          value: '=SUMIF(A22:A24, "", D22:D24)',
          formula: '=SUMIF(A22:A24, "", D22:D24)',
        ),
        const FortuneCellCoord(25, 1): const FortuneCell(
          value: '=AVERAGEIF(A22:A24, NULL, D22:D24)',
          formula: '=AVERAGEIF(A22:A24, NULL, D22:D24)',
        ),
        const FortuneCellCoord(26, 1): const FortuneCell(
          value: '=SUMIFS(D22:D24, A22:A24, "", C22:C24, "closed")',
          formula: '=SUMIFS(D22:D24, A22:A24, "", C22:C24, "closed")',
        ),
        const FortuneCellCoord(27, 1): const FortuneCell(
          value: '=AVERAGEIFS(D22:D24, A22:A24, "", C22:C24, "open")',
          formula: '=AVERAGEIFS(D22:D24, A22:A24, "", C22:C24, "open")',
        ),
        const FortuneCellCoord(28, 1): const FortuneCell(
          value: '=MAXIFS(D22:D24, A22:A24, "")',
          formula: '=MAXIFS(D22:D24, A22:A24, "")',
        ),
        const FortuneCellCoord(29, 1): const FortuneCell(
          value: '=MINIFS(D22:D24, A22:A24, "")',
          formula: '=MINIFS(D22:D24, A22:A24, "")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '50');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '15');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(19, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(20, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(20, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(21, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(22, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(23, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(24, 1)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(25, 1)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(26, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(27, 1)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(28, 1)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(29, 1)]?.renderedText, '5');
  });

  test('formula engine evaluates SUMIF range fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '3'),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=SUMIF(A1:C1, ">2")',
          formula: '=SUMIF(A1:C1, ">2")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=SUMIFS(A1:C1, ">1", "<3")',
          formula: '=SUMIFS(A1:C1, ">1", "<3")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '2');
  });

  test('formula engine evaluates database count and sum helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'Type'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: 'Qty'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: 'Note'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: 'fruit'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '5'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: 'sold'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: 'fruit'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(3, 0): const FortuneCell(value: 'veg'),
        const FortuneCellCoord(3, 1): const FortuneCell(value: '7'),
        const FortuneCellCoord(3, 2): const FortuneCell(value: 'sold'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: 'fruit'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: 'pending'),
        const FortuneCellCoord(4, 2): const FortuneCell(value: 'hold'),
        const FortuneCellCoord(0, 4): const FortuneCell(value: 'Type'),
        const FortuneCellCoord(0, 5): const FortuneCell(value: 'Qty'),
        const FortuneCellCoord(1, 4): const FortuneCell(value: 'fruit'),
        const FortuneCellCoord(1, 5): const FortuneCell(value: '>3'),
        const FortuneCellCoord(3, 4): const FortuneCell(value: 'Type'),
        const FortuneCellCoord(4, 4): const FortuneCell(value: 'fruit'),
        const FortuneCellCoord(5, 4): const FortuneCell(value: 'veg'),
        const FortuneCellCoord(7, 4): const FortuneCell(value: 'Type'),
        const FortuneCellCoord(8, 4): const FortuneCell(value: ''),
        const FortuneCellCoord(0, 7): const FortuneCell(
          value: '=DSUM(A1:C5, "Qty", E1:F2)',
          formula: '=DSUM(A1:C5, "Qty", E1:F2)',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=DCOUNT(A1:C5, 2, E1:F2)',
          formula: '=DCOUNT(A1:C5, 2, E1:F2)',
        ),
        const FortuneCellCoord(2, 7): const FortuneCell(
          value: '=DCOUNTA(A1:C5, "Note", E1:F2)',
          formula: '=DCOUNTA(A1:C5, "Note", E1:F2)',
        ),
        const FortuneCellCoord(3, 7): const FortuneCell(
          value: '=DSUM(A1:C5, "Qty", E4:E6)',
          formula: '=DSUM(A1:C5, "Qty", E4:E6)',
        ),
        const FortuneCellCoord(4, 7): const FortuneCell(
          value: '=DCOUNTA(A1:C5, "Note", E4:E6)',
          formula: '=DCOUNTA(A1:C5, "Note", E4:E6)',
        ),
        const FortuneCellCoord(5, 7): const FortuneCell(
          value: '=ROUND(DAVERAGE(A1:C5, "Qty", E4:E6), 6)',
          formula: '=ROUND(DAVERAGE(A1:C5, "Qty", E4:E6), 6)',
        ),
        const FortuneCellCoord(6, 7): const FortuneCell(
          value: '=DMAX(A1:C5, "Qty", E4:E6)',
          formula: '=DMAX(A1:C5, "Qty", E4:E6)',
        ),
        const FortuneCellCoord(7, 7): const FortuneCell(
          value: '=DMIN(A1:C5, "Qty", E4:E6)',
          formula: '=DMIN(A1:C5, "Qty", E4:E6)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=DPRODUCT(A1:C5, "Qty", E4:E6)',
          formula: '=DPRODUCT(A1:C5, "Qty", E4:E6)',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=ROUND(DVAR(A1:C5, "Qty", E4:E6), 6)',
          formula: '=ROUND(DVAR(A1:C5, "Qty", E4:E6), 6)',
        ),
        const FortuneCellCoord(10, 7): const FortuneCell(
          value: '=ROUND(DVARP(A1:C5, "Qty", E4:E6), 6)',
          formula: '=ROUND(DVARP(A1:C5, "Qty", E4:E6), 6)',
        ),
        const FortuneCellCoord(11, 7): const FortuneCell(
          value: '=ROUND(DSTDEV(A1:C5, "Qty", E4:E6), 6)',
          formula: '=ROUND(DSTDEV(A1:C5, "Qty", E4:E6), 6)',
        ),
        const FortuneCellCoord(12, 7): const FortuneCell(
          value: '=ROUND(DSTDEVP(A1:C5, "Qty", E4:E6), 6)',
          formula: '=ROUND(DSTDEVP(A1:C5, "Qty", E4:E6), 6)',
        ),
        const FortuneCellCoord(13, 7): const FortuneCell(
          value: '=DGET(A1:C5, "Note", E1:F2)',
          formula: '=DGET(A1:C5, "Note", E1:F2)',
        ),
        const FortuneCellCoord(14, 7): const FortuneCell(
          value: '=DGET(A1:C5, "Note", E4:E6)',
          formula: '=DGET(A1:C5, "Note", E4:E6)',
        ),
        const FortuneCellCoord(15, 7): const FortuneCell(
          value: '=DCOUNT(A1:C5, "Qty", E8:E9)',
          formula: '=DCOUNT(A1:C5, "Qty", E8:E9)',
        ),
        const FortuneCellCoord(16, 7): const FortuneCell(
          value: '=DSUM(A1:C5, "Qty", E8:E9)',
          formula: '=DSUM(A1:C5, "Qty", E8:E9)',
        ),
        const FortuneCellCoord(17, 7): const FortuneCell(
          value: '=DCOUNTA(A1:C5, "Note", E8:E9)',
          formula: '=DCOUNTA(A1:C5, "Note", E8:E9)',
        ),
        const FortuneCellCoord(18, 7): const FortuneCell(
          value: '=ROUND(DAVERAGE(A1:C5, "Qty", E8:E9), 6)',
          formula: '=ROUND(DAVERAGE(A1:C5, "Qty", E8:E9), 6)',
        ),
        const FortuneCellCoord(19, 7): const FortuneCell(
          value: '=DMAX(A1:C5, "Qty", E8:E9)',
          formula: '=DMAX(A1:C5, "Qty", E8:E9)',
        ),
        const FortuneCellCoord(20, 7): const FortuneCell(
          value: '=DMIN(A1:C5, "Qty", E8:E9)',
          formula: '=DMIN(A1:C5, "Qty", E8:E9)',
        ),
        const FortuneCellCoord(21, 7): const FortuneCell(
          value: '=DPRODUCT(A1:C5, "Qty", E8:E9)',
          formula: '=DPRODUCT(A1:C5, "Qty", E8:E9)',
        ),
        const FortuneCellCoord(22, 7): const FortuneCell(
          value: '=ROUND(DVAR(A1:C5, "Qty", E8:E9), 6)',
          formula: '=ROUND(DVAR(A1:C5, "Qty", E8:E9), 6)',
        ),
        const FortuneCellCoord(23, 7): const FortuneCell(
          value: '=ROUND(DVARP(A1:C5, "Qty", E8:E9), 6)',
          formula: '=ROUND(DVARP(A1:C5, "Qty", E8:E9), 6)',
        ),
        const FortuneCellCoord(24, 7): const FortuneCell(
          value: '=ROUND(DSTDEV(A1:C5, "Qty", E8:E9), 6)',
          formula: '=ROUND(DSTDEV(A1:C5, "Qty", E8:E9), 6)',
        ),
        const FortuneCellCoord(25, 7): const FortuneCell(
          value: '=ROUND(DSTDEVP(A1:C5, "Qty", E8:E9), 6)',
          formula: '=ROUND(DSTDEVP(A1:C5, "Qty", E8:E9), 6)',
        ),
        const FortuneCellCoord(26, 7): const FortuneCell(
          value: '=DGET(A1:C5, "Note", E8:E9)',
          formula: '=DGET(A1:C5, "Note", E8:E9)',
        ),
        const FortuneCellCoord(27, 7): const FortuneCell(
          value: '=DCOUNT(A1:C5, "Qty", E8:E8)',
          formula: '=DCOUNT(A1:C5, "Qty", E8:E8)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 7)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(3, 7)]?.renderedText, '14');
    expect(sheet.cells[const FortuneCellCoord(4, 7)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(5, 7)]?.renderedText, '4.666667');
    expect(sheet.cells[const FortuneCellCoord(6, 7)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(7, 7)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '70');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '6.333333');
    expect(
      sheet.cells[const FortuneCellCoord(10, 7)]?.renderedText,
      '4.222222',
    );
    expect(
      sheet.cells[const FortuneCellCoord(11, 7)]?.renderedText,
      '2.516611',
    );
    expect(
      sheet.cells[const FortuneCellCoord(12, 7)]?.renderedText,
      '2.054805',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 7)]?.renderedText, 'sold');
    expect(sheet.cells[const FortuneCellCoord(14, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 7)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(16, 7)]?.renderedText, '14');
    expect(sheet.cells[const FortuneCellCoord(17, 7)]?.renderedText, '3');
    expect(
      sheet.cells[const FortuneCellCoord(18, 7)]?.renderedText,
      '4.666667',
    );
    expect(sheet.cells[const FortuneCellCoord(19, 7)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(20, 7)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(21, 7)]?.renderedText, '70');
    expect(
      sheet.cells[const FortuneCellCoord(22, 7)]?.renderedText,
      '6.333333',
    );
    expect(
      sheet.cells[const FortuneCellCoord(23, 7)]?.renderedText,
      '4.222222',
    );
    expect(
      sheet.cells[const FortuneCellCoord(24, 7)]?.renderedText,
      '2.516611',
    );
    expect(
      sheet.cells[const FortuneCellCoord(25, 7)]?.renderedText,
      '2.054805',
    );
    expect(sheet.cells[const FortuneCellCoord(26, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(27, 7)]?.renderedText, '3');
  });

  test('formula engine evaluates dynamic array helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=INDEX(TAKE({1,2,3;4,5,6;7,8,9}, 2, 2), 2, 2)',
          formula: '=INDEX(TAKE({1,2,3;4,5,6;7,8,9}, 2, 2), 2, 2)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=INDEX(TAKE({1,2,3;4,5,6;7,8,9}, -2, -1), 1, 1)',
          formula: '=INDEX(TAKE({1,2,3;4,5,6;7,8,9}, -2, -1), 1, 1)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value:
              '=ROWS(DROP({1,2,3;4,5,6;7,8,9}, 1))&"x"&COLUMNS(DROP({1,2,3;4,5,6;7,8,9}, 1))',
          formula:
              '=ROWS(DROP({1,2,3;4,5,6;7,8,9}, 1))&"x"&COLUMNS(DROP({1,2,3;4,5,6;7,8,9}, 1))',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=INDEX(DROP({1,2,3;4,5,6;7,8,9}, -1, -2), 2, 1)',
          formula: '=INDEX(DROP({1,2,3;4,5,6;7,8,9}, -1, -2), 2, 1)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=TAKE({1,2;3,4}, 0)',
          formula: '=TAKE({1,2;3,4}, 0)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=DROP({1,2;3,4}, 2)',
          formula: '=DROP({1,2;3,4}, 2)',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=INDEX(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, 3, 1), 2, 2)',
          formula: '=INDEX(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, 3, 1), 2, 2)',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value:
              '=ROWS(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, -1, 2))&"x"&COLUMNS(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, -1, 2))',
          formula:
              '=ROWS(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, -1, 2))&"x"&COLUMNS(CHOOSEROWS({1,2,3;4,5,6;7,8,9}, -1, 2))',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=INDEX(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, 3, 1), 2, 2)',
          formula: '=INDEX(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, 3, 1), 2, 2)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value:
              '=ROWS(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, -1, 2))&"x"&COLUMNS(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, -1, 2))',
          formula:
              '=ROWS(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, -1, 2))&"x"&COLUMNS(CHOOSECOLS({1,2,3;4,5,6;7,8,9}, -1, 2))',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=CHOOSEROWS({1,2;3,4}, 0)',
          formula: '=CHOOSEROWS({1,2;3,4}, 0)',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=CHOOSECOLS({1,2;3,4}, 3)',
          formula: '=CHOOSECOLS({1,2;3,4}, 3)',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value:
              '=ROWS(EXPAND({1,2;3,4}, 3, 4, "pad"))&"x"&COLUMNS(EXPAND({1,2;3,4}, 3, 4, "pad"))',
          formula:
              '=ROWS(EXPAND({1,2;3,4}, 3, 4, "pad"))&"x"&COLUMNS(EXPAND({1,2;3,4}, 3, 4, "pad"))',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=INDEX(EXPAND({1,2;3,4}, 3, 4), 3, 4)',
          formula: '=INDEX(EXPAND({1,2;3,4}, 3, 4), 3, 4)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=INDEX(EXPAND({1,2;3,4}, 3, 4, "pad"), 3, 4)',
          formula: '=INDEX(EXPAND({1,2;3,4}, 3, 4, "pad"), 3, 4)',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=INDEX(EXPAND({1,2;3,4}, 3), 3, 2)',
          formula: '=INDEX(EXPAND({1,2;3,4}, 3), 3, 2)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=EXPAND({1,2;3,4}, 1, 2)',
          formula: '=EXPAND({1,2;3,4}, 1, 2)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=EXPAND({1,2;3,4}, 2, 1)',
          formula: '=EXPAND({1,2;3,4}, 2, 1)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value:
              '=ROWS(VSTACK({1,2;3,4}, {5,6}))&"x"&COLUMNS(VSTACK({1,2;3,4}, {5,6}))',
          formula:
              '=ROWS(VSTACK({1,2;3,4}, {5,6}))&"x"&COLUMNS(VSTACK({1,2;3,4}, {5,6}))',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=INDEX(VSTACK({1,2;3,4}, {5,6}), 3, 2)',
          formula: '=INDEX(VSTACK({1,2;3,4}, {5,6}), 3, 2)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=INDEX(VSTACK({1,2}, {3}), 2, 2)',
          formula: '=INDEX(VSTACK({1,2}, {3}), 2, 2)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value:
              '=ROWS(HSTACK({1;2}, {3,4;5,6}))&"x"&COLUMNS(HSTACK({1;2}, {3,4;5,6}))',
          formula:
              '=ROWS(HSTACK({1;2}, {3,4;5,6}))&"x"&COLUMNS(HSTACK({1;2}, {3,4;5,6}))',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=INDEX(HSTACK({1;2}, {3,4;5,6}), 2, 3)',
          formula: '=INDEX(HSTACK({1;2}, {3,4;5,6}), 2, 3)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=INDEX(HSTACK({1;2}, {3}), 2, 2)',
          formula: '=INDEX(HSTACK({1;2}, {3}), 2, 2)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=INDEX(TOCOL({1,2;3,4}), 3, 1)',
          formula: '=INDEX(TOCOL({1,2;3,4}), 3, 1)',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=INDEX(TOCOL({1,2;3,4}, 0, TRUE), 3, 1)',
          formula: '=INDEX(TOCOL({1,2;3,4}, 0, TRUE), 3, 1)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=INDEX(TOROW({1,2;3,4}), 1, 3)',
          formula: '=INDEX(TOROW({1,2;3,4}), 1, 3)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=INDEX(TOROW({1,2;3,4}, 0, TRUE), 1, 3)',
          formula: '=INDEX(TOROW({1,2;3,4}, 0, TRUE), 1, 3)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=ROWS(TOCOL(VSTACK({1,2}, {3}), 2))',
          formula: '=ROWS(TOCOL(VSTACK({1,2}, {3}), 2))',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=COLUMNS(TOROW(HSTACK({1;2}, {3}), 2))',
          formula: '=COLUMNS(TOROW(HSTACK({1;2}, {3}), 2))',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value:
              '=ROWS(WRAPROWS({1,2,3,4,5}, 2, "pad"))&"x"&COLUMNS(WRAPROWS({1,2,3,4,5}, 2, "pad"))',
          formula:
              '=ROWS(WRAPROWS({1,2,3,4,5}, 2, "pad"))&"x"&COLUMNS(WRAPROWS({1,2,3,4,5}, 2, "pad"))',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=INDEX(WRAPROWS({1,2,3,4,5}, 2), 3, 2)',
          formula: '=INDEX(WRAPROWS({1,2,3,4,5}, 2), 3, 2)',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=INDEX(WRAPROWS({1,2,3,4,5}, 2, "pad"), 3, 2)',
          formula: '=INDEX(WRAPROWS({1,2,3,4,5}, 2, "pad"), 3, 2)',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value:
              '=ROWS(WRAPCOLS({1;2;3;4;5}, 2, "pad"))&"x"&COLUMNS(WRAPCOLS({1;2;3;4;5}, 2, "pad"))',
          formula:
              '=ROWS(WRAPCOLS({1;2;3;4;5}, 2, "pad"))&"x"&COLUMNS(WRAPCOLS({1;2;3;4;5}, 2, "pad"))',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=INDEX(WRAPCOLS({1;2;3;4;5}, 2), 2, 3)',
          formula: '=INDEX(WRAPCOLS({1;2;3;4;5}, 2), 2, 3)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=WRAPROWS({1,2;3,4}, 2)',
          formula: '=WRAPROWS({1,2;3,4}, 2)',
        ),
        const FortuneCellCoord(5, 6): const FortuneCell(
          value: '=WRAPCOLS({1;2}, 0)',
          formula: '=WRAPCOLS({1;2}, 0)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=ROWS(SEQUENCE(3))&"x"&COLUMNS(SEQUENCE(3))',
          formula: '=ROWS(SEQUENCE(3))&"x"&COLUMNS(SEQUENCE(3))',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=INDEX(SEQUENCE(3), 3, 1)',
          formula: '=INDEX(SEQUENCE(3), 3, 1)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=INDEX(SEQUENCE(2, 3, 10, 5), 2, 3)',
          formula: '=INDEX(SEQUENCE(2, 3, 10, 5), 2, 3)',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=SUM(SEQUENCE(2, 2))',
          formula: '=SUM(SEQUENCE(2, 2))',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=SEQUENCE(0)',
          formula: '=SEQUENCE(0)',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=SEQUENCE(2, 0)',
          formula: '=SEQUENCE(2, 0)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          value: '=SUM(SEQUENCE(2, 2, 5, 0))',
          formula: '=SUM(SEQUENCE(2, 2, 5, 0))',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value:
              '=ROWS(TRANSPOSE({1,2,3;4,5,6}))&"x"&COLUMNS(TRANSPOSE({1,2,3;4,5,6}))',
          formula:
              '=ROWS(TRANSPOSE({1,2,3;4,5,6}))&"x"&COLUMNS(TRANSPOSE({1,2,3;4,5,6}))',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=INDEX(TRANSPOSE({1,2,3;4,5,6}), 3, 2)',
          formula: '=INDEX(TRANSPOSE({1,2,3;4,5,6}), 3, 2)',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=INDEX(TRANSPOSE(SEQUENCE(2, 3)), 2, 2)',
          formula: '=INDEX(TRANSPOSE(SEQUENCE(2, 3)), 2, 2)',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=SUM(TRANSPOSE({1,2;3,4}))',
          formula: '=SUM(TRANSPOSE({1,2;3,4}))',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value:
              '=ROWS(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}))&"x"&COLUMNS(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}))',
          formula:
              '=ROWS(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}))&"x"&COLUMNS(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}))',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=INDEX(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}), 2, 2)',
          formula: '=INDEX(MMULT({1,2,3;4,5,6}, {7,8;9,10;11,12}), 2, 2)',
        ),
        const FortuneCellCoord(7, 6): const FortuneCell(
          value: '=TRANSPOSE()',
          formula: '=TRANSPOSE()',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=INDEX(FILTER({1,2;3,4;5,6}, {TRUE;FALSE;TRUE}), 2, 2)',
          formula: '=INDEX(FILTER({1,2;3,4;5,6}, {TRUE;FALSE;TRUE}), 2, 2)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value:
              '=ROWS(FILTER({1,2,3;4,5,6}, {TRUE;FALSE}))&"x"&COLUMNS(FILTER({1,2,3;4,5,6}, {TRUE;FALSE}))',
          formula:
              '=ROWS(FILTER({1,2,3;4,5,6}, {TRUE;FALSE}))&"x"&COLUMNS(FILTER({1,2,3;4,5,6}, {TRUE;FALSE}))',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=INDEX(FILTER({1,2,3;4,5,6}, {TRUE,FALSE,TRUE}), 2, 2)',
          formula: '=INDEX(FILTER({1,2,3;4,5,6}, {TRUE,FALSE,TRUE}), 2, 2)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=FILTER({1,2;3,4}, {FALSE;FALSE}, "empty")',
          formula: '=FILTER({1,2;3,4}, {FALSE;FALSE}, "empty")',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=FILTER({1,2;3,4}, {FALSE;FALSE})',
          formula: '=FILTER({1,2;3,4}, {FALSE;FALSE})',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=FILTER({1,2;3,4}, {TRUE;1/0}, "empty")',
          formula: '=FILTER({1,2;3,4}, {TRUE;1/0}, "empty")',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=FILTER({1,2;3,4}, {TRUE,FALSE;FALSE,TRUE})',
          formula: '=FILTER({1,2;3,4}, {TRUE,FALSE;FALSE,TRUE})',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value:
              '=ROWS(UNIQUE({1,2;1,2;3,4}))&"x"&COLUMNS(UNIQUE({1,2;1,2;3,4}))',
          formula:
              '=ROWS(UNIQUE({1,2;1,2;3,4}))&"x"&COLUMNS(UNIQUE({1,2;1,2;3,4}))',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=INDEX(UNIQUE({1,2;1,2;3,4}), 2, 2)',
          formula: '=INDEX(UNIQUE({1,2;1,2;3,4}), 2, 2)',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=INDEX(UNIQUE({1,1,2;3,3,4}, TRUE), 2, 2)',
          formula: '=INDEX(UNIQUE({1,1,2;3,3,4}, TRUE), 2, 2)',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=INDEX(UNIQUE({1;2;1;3}, FALSE, TRUE), 1, 1)',
          formula: '=INDEX(UNIQUE({1;2;1;3}, FALSE, TRUE), 1, 1)',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=ROWS(UNIQUE({1;2;1;3}, FALSE, TRUE))',
          formula: '=ROWS(UNIQUE({1;2;1;3}, FALSE, TRUE))',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=UNIQUE({1;1}, FALSE, TRUE)',
          formula: '=UNIQUE({1;1}, FALSE, TRUE)',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=ROWS(UNIQUE())&"x"&COLUMNS(UNIQUE())',
          formula: '=ROWS(UNIQUE())&"x"&COLUMNS(UNIQUE())',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=JOIN(UNIQUE(1, 2, 3, 4, 4, 4, 4, 3))',
          formula: '=JOIN(UNIQUE(1, 2, 3, 4, 4, 4, 4, 3))',
        ),
        const FortuneCellCoord(9, 8): const FortuneCell(
          value: '=JOIN(UNIQUE("foo", "bar", "foo"))',
          formula: '=JOIN(UNIQUE("foo", "bar", "foo"))',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value:
              '=ROWS(SORT({3,"c";1,"a";2,"b"}))&"x"&COLUMNS(SORT({3,"c";1,"a";2,"b"}))',
          formula:
              '=ROWS(SORT({3,"c";1,"a";2,"b"}))&"x"&COLUMNS(SORT({3,"c";1,"a";2,"b"}))',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=INDEX(SORT({3,"c";1,"a";2,"b"}), 1, 2)',
          formula: '=INDEX(SORT({3,"c";1,"a";2,"b"}), 1, 2)',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=INDEX(SORT({1,"b";2,"c";3,"a"}, 2, -1), 1, 1)',
          formula: '=INDEX(SORT({1,"b";2,"c";3,"a"}, 2, -1), 1, 1)',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=INDEX(SORT({3,1,2;"c","a","b"}, 1, 1, TRUE), 2, 2)',
          formula: '=INDEX(SORT({3,1,2;"c","a","b"}, 1, 1, TRUE), 2, 2)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=SORT({1,2;3,4}, 3)',
          formula: '=SORT({1,2;3,4}, 3)',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=SORT({1,2;3,4}, 1, 0)',
          formula: '=SORT({1,2;3,4}, 1, 0)',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=INDEX(SORTBY({1,"b";2,"a";3,"c"}, {"b";"a";"c"}), 1, 1)',
          formula: '=INDEX(SORTBY({1,"b";2,"a";3,"c"}, {"b";"a";"c"}), 1, 1)',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=INDEX(SORTBY({1,"b";2,"a";3,"c"}, {"b";"a";"c"}, -1), 1, 1)',
          formula:
              '=INDEX(SORTBY({1,"b";2,"a";3,"c"}, {"b";"a";"c"}, -1), 1, 1)',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value:
              '=INDEX(SORTBY({1,"b";2,"a";3,"b"}, {"b";"a";"b"}, 1, {2;3;1}, -1), 2, 1)',
          formula:
              '=INDEX(SORTBY({1,"b";2,"a";3,"b"}, {"b";"a";"b"}, 1, {2;3;1}, -1), 2, 1)',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=INDEX(SORTBY({1,2,3;"b","a","c"}, {"b","a","c"}), 2, 2)',
          formula: '=INDEX(SORTBY({1,2,3;"b","a","c"}, {"b","a","c"}), 2, 2)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=SORTBY({1,2;3,4}, {1,2,3})',
          formula: '=SORTBY({1,2;3,4}, {1,2,3})',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=SORTBY({1,2;3,4}, {1;2}, 0)',
          formula: '=SORTBY({1,2;3,4}, {1;2}, 0)',
        ),
        const FortuneCellCoord(11, 6): const FortuneCell(
          value: '=SORTBY({1,2;3,4}, {2;1}, 1, {1,2}, 1)',
          formula: '=SORTBY({1,2;3,4}, {2;1}, 1, {1,2}, 1)',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value:
              '=ROWS(RANDARRAY(2,3,5,5,TRUE))&"x"&COLUMNS(RANDARRAY(2,3,5,5,TRUE))',
          formula:
              '=ROWS(RANDARRAY(2,3,5,5,TRUE))&"x"&COLUMNS(RANDARRAY(2,3,5,5,TRUE))',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=SUM(RANDARRAY(2,2,5,5,TRUE))',
          formula: '=SUM(RANDARRAY(2,2,5,5,TRUE))',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=INDEX(RANDARRAY(2,2,7,7,FALSE), 2, 2)',
          formula: '=INDEX(RANDARRAY(2,2,7,7,FALSE), 2, 2)',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=RANDARRAY(0)',
          formula: '=RANDARRAY(0)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=RANDARRAY(1,1,10,5)',
          formula: '=RANDARRAY(1,1,10,5)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=RANDARRAY(1,1,1.5,1.6,TRUE)',
          formula: '=RANDARRAY(1,1,1.5,1.6,TRUE)',
        ),
        const FortuneCellCoord(13, 0): const FortuneCell(
          value: '=ARRAYTOTEXT({1,2;3,4})',
          formula: '=ARRAYTOTEXT({1,2;3,4})',
        ),
        const FortuneCellCoord(13, 1): const FortuneCell(
          value: '=ARRAYTOTEXT({1,"a";TRUE,#N/A}, 1)',
          formula: '=ARRAYTOTEXT({1,"a";TRUE,#N/A}, 1)',
        ),
        const FortuneCellCoord(13, 2): const FortuneCell(
          value: '=ARRAYTOTEXT(SORT({2,"b";1,"a"}), 1)',
          formula: '=ARRAYTOTEXT(SORT({2,"b";1,"a"}), 1)',
        ),
        const FortuneCellCoord(13, 3): const FortuneCell(
          value: '=VALUETOTEXT("a""b", 1)',
          formula: '=VALUETOTEXT("a""b", 1)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=VALUETOTEXT(TRUE)',
          formula: '=VALUETOTEXT(TRUE)',
        ),
        const FortuneCellCoord(13, 5): const FortuneCell(
          value: '=ARRAYTOTEXT({1,2}, 2)',
          formula: '=ARRAYTOTEXT({1,2}, 2)',
        ),
        const FortuneCellCoord(14, 0): const FortuneCell(
          value: '=TAKE({1;1/0}, 1)',
          formula: '=TAKE({1;1/0}, 1)',
        ),
        const FortuneCellCoord(14, 1): const FortuneCell(
          value: '=DROP({1/0;2}, 1)',
          formula: '=DROP({1/0;2}, 1)',
        ),
        const FortuneCellCoord(14, 2): const FortuneCell(
          value: '=INDEX(TAKE({1,2/0;3,4}, 2, 1), 2, 1)',
          formula: '=INDEX(TAKE({1,2/0;3,4}, 2, 1), 2, 1)',
        ),
        const FortuneCellCoord(14, 3): const FortuneCell(
          value: '=INDEX(DROP({1,2/0;3,4}, 0, 1), 1, 1)',
          formula: '=INDEX(DROP({1,2/0;3,4}, 0, 1), 1, 1)',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=TAKE({1;2}, 1/0)',
          formula: '=TAKE({1;2}, 1/0)',
        ),
        const FortuneCellCoord(14, 5): const FortuneCell(
          value: '=DROP({1;2}, 2)',
          formula: '=DROP({1;2}, 2)',
        ),
        const FortuneCellCoord(15, 0): const FortuneCell(
          value: '=INDEX(CHOOSEROWS({1,2;1/0,4}, 1), 1, 2)',
          formula: '=INDEX(CHOOSEROWS({1,2;1/0,4}, 1), 1, 2)',
        ),
        const FortuneCellCoord(15, 1): const FortuneCell(
          value: '=INDEX(CHOOSEROWS({1,2;3,4;5,1/0}, -2), 1, 2)',
          formula: '=INDEX(CHOOSEROWS({1,2;3,4;5,1/0}, -2), 1, 2)',
        ),
        const FortuneCellCoord(15, 2): const FortuneCell(
          value: '=INDEX(CHOOSECOLS({1,2/0;3,4}, 1), 2, 1)',
          formula: '=INDEX(CHOOSECOLS({1,2/0;3,4}, 1), 2, 1)',
        ),
        const FortuneCellCoord(15, 3): const FortuneCell(
          value: '=INDEX(CHOOSECOLS({1,2;3,1/0}, -2), 2, 1)',
          formula: '=INDEX(CHOOSECOLS({1,2;3,1/0}, -2), 2, 1)',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=CHOOSEROWS({1;2}, 1/0)',
          formula: '=CHOOSEROWS({1;2}, 1/0)',
        ),
        const FortuneCellCoord(15, 5): const FortuneCell(
          value: '=CHOOSECOLS({1,2}, 3)',
          formula: '=CHOOSECOLS({1,2}, 3)',
        ),
        const FortuneCellCoord(16, 0): const FortuneCell(
          value: '=INDEX(VSTACK({1;1/0}, {2}), 1, 1)',
          formula: '=INDEX(VSTACK({1;1/0}, {2}), 1, 1)',
        ),
        const FortuneCellCoord(16, 1): const FortuneCell(
          value: '=INDEX(VSTACK({1;1/0}, {2}), 3, 1)',
          formula: '=INDEX(VSTACK({1;1/0}, {2}), 3, 1)',
        ),
        const FortuneCellCoord(16, 2): const FortuneCell(
          value: '=INDEX(HSTACK({1,1/0}, {2}), 1, 1)',
          formula: '=INDEX(HSTACK({1,1/0}, {2}), 1, 1)',
        ),
        const FortuneCellCoord(16, 3): const FortuneCell(
          value: '=INDEX(HSTACK({1,1/0}, {2}), 1, 3)',
          formula: '=INDEX(HSTACK({1,1/0}, {2}), 1, 3)',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=INDEX(VSTACK({1,2}, {3}), 2, 2)',
          formula: '=INDEX(VSTACK({1,2}, {3}), 2, 2)',
        ),
        const FortuneCellCoord(16, 5): const FortuneCell(
          value: '=INDEX(HSTACK({1;2}, {3}), 2, 2)',
          formula: '=INDEX(HSTACK({1;2}, {3}), 2, 2)',
        ),
        const FortuneCellCoord(17, 0): const FortuneCell(
          value: '=INDEX(TRANSPOSE({1,2/0;3,4}), 1, 1)',
          formula: '=INDEX(TRANSPOSE({1,2/0;3,4}), 1, 1)',
        ),
        const FortuneCellCoord(17, 1): const FortuneCell(
          value: '=INDEX(TRANSPOSE({1,2/0;3,4}), 1, 2)',
          formula: '=INDEX(TRANSPOSE({1,2/0;3,4}), 1, 2)',
        ),
        const FortuneCellCoord(17, 2): const FortuneCell(
          value: '=INDEX(WRAPROWS({1,1/0,2}, 2), 2, 1)',
          formula: '=INDEX(WRAPROWS({1,1/0,2}, 2), 2, 1)',
        ),
        const FortuneCellCoord(17, 3): const FortuneCell(
          value: '=INDEX(WRAPCOLS({1,1/0,2}, 2), 1, 2)',
          formula: '=INDEX(WRAPCOLS({1,1/0,2}, 2), 1, 2)',
        ),
        const FortuneCellCoord(17, 4): const FortuneCell(
          value: '=INDEX(WRAPROWS({1}, 2, 1/0), 1, 1)',
          formula: '=INDEX(WRAPROWS({1}, 2, 1/0), 1, 1)',
        ),
        const FortuneCellCoord(17, 5): const FortuneCell(
          value: '=WRAPROWS({1,2}, 1/0)',
          formula: '=WRAPROWS({1,2}, 1/0)',
        ),
        const FortuneCellCoord(18, 0): const FortuneCell(
          value: '=INDEX(UNIQUE({1,1/0;2,3}), 2, 1)',
          formula: '=INDEX(UNIQUE({1,1/0;2,3}), 2, 1)',
        ),
        const FortuneCellCoord(18, 1): const FortuneCell(
          value: '=INDEX(UNIQUE({1,2/0;1,2/0;3,4}), 2, 1)',
          formula: '=INDEX(UNIQUE({1,2/0;1,2/0;3,4}), 2, 1)',
        ),
        const FortuneCellCoord(18, 2): const FortuneCell(
          value: '=INDEX(SORT({1,1/0;2,3}, 1), 2, 1)',
          formula: '=INDEX(SORT({1,1/0;2,3}, 1), 2, 1)',
        ),
        const FortuneCellCoord(18, 3): const FortuneCell(
          value: '=SORT({1;1/0}, 1)',
          formula: '=SORT({1;1/0}, 1)',
        ),
        const FortuneCellCoord(18, 4): const FortuneCell(
          value: '=INDEX(SORTBY({1,1/0;2,3}, {1;2}), 2, 1)',
          formula: '=INDEX(SORTBY({1,1/0;2,3}, {1;2}), 2, 1)',
        ),
        const FortuneCellCoord(18, 5): const FortuneCell(
          value: '=SORTBY({1;2}, {1;1/0})',
          formula: '=SORTBY({1;2}, {1;1/0})',
        ),
        const FortuneCellCoord(19, 0): const FortuneCell(
          value: '=INDEX(EXPAND({1}, 2, 2, 1/0), 1, 1)',
          formula: '=INDEX(EXPAND({1}, 2, 2, 1/0), 1, 1)',
        ),
        const FortuneCellCoord(19, 1): const FortuneCell(
          value: '=INDEX(EXPAND({1}, 2, 2, 1/0), 2, 2)',
          formula: '=INDEX(EXPAND({1}, 2, 2, 1/0), 2, 2)',
        ),
        const FortuneCellCoord(19, 2): const FortuneCell(
          value: '=EXPAND({1}, 1/0, 2)',
          formula: '=EXPAND({1}, 1/0, 2)',
        ),
        const FortuneCellCoord(19, 3): const FortuneCell(
          value: '=INDEX(TOROW({1,1/0;2,3}), 1, 1)',
          formula: '=INDEX(TOROW({1,1/0;2,3}), 1, 1)',
        ),
        const FortuneCellCoord(19, 4): const FortuneCell(
          value: '=INDEX(TOCOL({1,1/0,2}, 2), 2, 1)',
          formula: '=INDEX(TOCOL({1,1/0,2}, 2), 2, 1)',
        ),
        const FortuneCellCoord(19, 5): const FortuneCell(
          value: '=TOCOL({1,2}, 1/0)',
          formula: '=TOCOL({1,2}, 1/0)',
        ),
        const FortuneCellCoord(20, 0): const FortuneCell(
          value: '=INDEX(TOCOL({1,1/0;2,3}, 0, TRUE), 3, 1)',
          formula: '=INDEX(TOCOL({1,1/0;2,3}, 0, TRUE), 3, 1)',
        ),
        const FortuneCellCoord(20, 1): const FortuneCell(
          value: '=INDEX(TOROW({1,1/0,2}, 2), 1, 2)',
          formula: '=INDEX(TOROW({1,1/0,2}, 2), 1, 2)',
        ),
        const FortuneCellCoord(20, 2): const FortuneCell(
          value: '=TOCOL({1/0}, 2)',
          formula: '=TOCOL({1/0}, 2)',
        ),
        const FortuneCellCoord(21, 0): const FortuneCell(
          value: '=MDETERM({1,2;3,4})',
          formula: '=MDETERM({1,2;3,4})',
        ),
        const FortuneCellCoord(21, 1): const FortuneCell(
          value: '=MDETERM({1,2;2,4})',
          formula: '=MDETERM({1,2;2,4})',
        ),
        const FortuneCellCoord(21, 2): const FortuneCell(
          value: '=MDETERM({1,2,3;4,5,6})',
          formula: '=MDETERM({1,2,3;4,5,6})',
        ),
        const FortuneCellCoord(21, 3): const FortuneCell(
          value: '=INDEX(MINVERSE({4,7;2,6}), 1, 1)',
          formula: '=INDEX(MINVERSE({4,7;2,6}), 1, 1)',
        ),
        const FortuneCellCoord(21, 4): const FortuneCell(
          value: '=INDEX(MINVERSE({4,7;2,6}), 1, 2)',
          formula: '=INDEX(MINVERSE({4,7;2,6}), 1, 2)',
        ),
        const FortuneCellCoord(21, 5): const FortuneCell(
          value: '=MINVERSE({1,2;2,4})',
          formula: '=MINVERSE({1,2;2,4})',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '3x4');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, 'pad');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, 'pad');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '3x1');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '35');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(6, 6)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '154');
    expect(sheet.cells[const FortuneCellCoord(7, 6)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '1x3');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, 'empty');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '#CALC!');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '#CALC!');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '0x0');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '1,2,3,4');
    expect(sheet.cells[const FortuneCellCoord(9, 8)]?.renderedText, 'foo,bar');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '3x2');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, 'a');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, 'b');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, 'b');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(13, 0)]?.renderedText,
      '1, 2; 3, 4',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 1)]?.renderedText,
      '{1,"a";TRUE,#N/A}',
    );
    expect(
      sheet.cells[const FortuneCellCoord(13, 2)]?.renderedText,
      '{1,"a";2,"b"}',
    );
    expect(sheet.cells[const FortuneCellCoord(13, 3)]?.renderedText, '"a""b"');
    expect(sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(13, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(14, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(14, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(14, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(14, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(15, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(15, 1)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(15, 2)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(15, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(15, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(16, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(16, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(16, 2)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(16, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(16, 5)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(17, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(17, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(17, 3)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(17, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(17, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(18, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(18, 1)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(18, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(18, 3)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(18, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(18, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(19, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(19, 1)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(19, 2)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(19, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(19, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(19, 5)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(20, 0)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(20, 1)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(20, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 0)]?.renderedText, '-2');
    expect(sheet.cells[const FortuneCellCoord(21, 1)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(21, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(21, 3)]?.renderedText, '0.6');
    expect(sheet.cells[const FortuneCellCoord(21, 4)]?.renderedText, '-0.7');
    expect(sheet.cells[const FortuneCellCoord(21, 5)]?.renderedText, '#NUM!');
  });

  test('formula engine evaluates lookup helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'foo': [0, 1, 2, 3, 4, 100, 7],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'a'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: 'b'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: 'c'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '10'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '20'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '30'),
        const FortuneCellCoord(0, 2): const FortuneCell(value: '100'),
        const FortuneCellCoord(1, 2): const FortuneCell(value: '200'),
        const FortuneCellCoord(2, 2): const FortuneCell(value: '300'),
        const FortuneCellCoord(4, 0): const FortuneCell(value: 'q1'),
        const FortuneCellCoord(4, 1): const FortuneCell(value: 'q2'),
        const FortuneCellCoord(4, 2): const FortuneCell(value: 'q3'),
        const FortuneCellCoord(5, 0): const FortuneCell(value: '11'),
        const FortuneCellCoord(5, 1): const FortuneCell(value: '22'),
        const FortuneCellCoord(5, 2): const FortuneCell(value: '33'),
        const FortuneCellCoord(6, 0): const FortuneCell(value: '111'),
        const FortuneCellCoord(6, 1): const FortuneCell(value: '222'),
        const FortuneCellCoord(6, 2): const FortuneCell(value: '333'),
        const FortuneCellCoord(31, 0): const FortuneCell(value: '10'),
        const FortuneCellCoord(31, 1): const FortuneCell(value: '20'),
        const FortuneCellCoord(31, 2): const FortuneCell(value: '30'),
        const FortuneCellCoord(32, 0): const FortuneCell(value: 'red'),
        const FortuneCellCoord(32, 1): const FortuneCell(value: 'blue'),
        const FortuneCellCoord(32, 2): const FortuneCell(value: 'green'),
        const FortuneCellCoord(74, 0): const FortuneCell(value: 'alpha'),
        const FortuneCellCoord(75, 0): const FortuneCell(value: 'beta'),
        const FortuneCellCoord(74, 1): const FortuneCell(
          value: '=1/0',
          formula: '=1/0',
        ),
        const FortuneCellCoord(75, 1): const FortuneCell(value: 'ok'),
        const FortuneCellCoord(84, 0): const FortuneCell(value: 'alpha'),
        const FortuneCellCoord(84, 1): const FortuneCell(value: 'beta'),
        const FortuneCellCoord(85, 0): const FortuneCell(
          value: '=1/0',
          formula: '=1/0',
        ),
        const FortuneCellCoord(85, 1): const FortuneCell(value: 'ok'),
        const FortuneCellCoord(106, 0): const FortuneCell(value: 'a*'),
        const FortuneCellCoord(106, 1): const FortuneCell(value: 'star'),
        const FortuneCellCoord(107, 0): const FortuneCell(value: 'a?'),
        const FortuneCellCoord(107, 1): const FortuneCell(value: 'question'),
        const FortuneCellCoord(108, 0): const FortuneCell(value: 'a~'),
        const FortuneCellCoord(108, 1): const FortuneCell(value: 'tilde'),
        const FortuneCellCoord(109, 0): const FortuneCell(value: 'alpha'),
        const FortuneCellCoord(109, 1): const FortuneCell(value: 'v-ok'),
        const FortuneCellCoord(110, 0): const FortuneCell(
          value: '=1/0',
          formula: '=1/0',
        ),
        const FortuneCellCoord(110, 1): const FortuneCell(value: 'later'),
        const FortuneCellCoord(119, 0): const FortuneCell(value: '30'),
        const FortuneCellCoord(119, 1): const FortuneCell(value: 'high'),
        const FortuneCellCoord(120, 0): const FortuneCell(value: '20'),
        const FortuneCellCoord(120, 1): const FortuneCell(value: 'mid'),
        const FortuneCellCoord(121, 0): const FortuneCell(value: '10'),
        const FortuneCellCoord(121, 1): const FortuneCell(value: 'low'),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=INDEX(A1:C3, 2, 3)',
          formula: '=INDEX(A1:C3, 2, 3)',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=MATCH("b", A1:A3, 0)',
          formula: '=MATCH("b", A1:A3, 0)',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=MATCH(25, B1:B3)',
          formula: '=MATCH(25, B1:B3)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=VLOOKUP("b", A1:C3, 3, FALSE)',
          formula: '=VLOOKUP("b", A1:C3, 3, FALSE)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=VLOOKUP("d", A1:C3, 2, FALSE)',
          formula: '=VLOOKUP("d", A1:C3, 2, FALSE)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=HLOOKUP("q2", A5:C7, 3, FALSE)',
          formula: '=HLOOKUP("q2", A5:C7, 3, FALSE)',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=HLOOKUP("q4", A5:C7, 2, FALSE)',
          formula: '=HLOOKUP("q4", A5:C7, 2, FALSE)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=XLOOKUP("c", A1:A3, C1:C3)',
          formula: '=XLOOKUP("c", A1:A3, C1:C3)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=XLOOKUP("d", A1:A3, C1:C3, "missing")',
          formula: '=XLOOKUP("d", A1:A3, C1:C3, "missing")',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=XLOOKUP("q*", A5:C5, A7:C7, "none", 2)',
          formula: '=XLOOKUP("q*", A5:C5, A7:C7, "none", 2)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=XLOOKUP(25, B1:B3, C1:C3, "none", 1)',
          formula: '=XLOOKUP(25, B1:B3, C1:C3, "none", 1)',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=XLOOKUP(25, B1:B3, C1:C3, "none", -1)',
          formula: '=XLOOKUP(25, B1:B3, C1:C3, "none", -1)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=XMATCH("q?", A5:C5, 2)',
          formula: '=XMATCH("q?", A5:C5, 2)',
        ),
        const FortuneCellCoord(13, 4): const FortuneCell(
          value: '=CHOOSE(2, "red", "blue")',
          formula: '=CHOOSE(2, "red", "blue")',
        ),
        const FortuneCellCoord(14, 4): const FortuneCell(
          value: '=ROWS(A1:C3)&"x"&COLUMNS(A1:C3)',
          formula: '=ROWS(A1:C3)&"x"&COLUMNS(A1:C3)',
        ),
        const FortuneCellCoord(15, 4): const FortuneCell(
          value: '=MATCH("z", A1:A3, 0)',
          formula: '=MATCH("z", A1:A3, 0)',
        ),
        const FortuneCellCoord(16, 4): const FortuneCell(
          value: '=XLOOKUP("z", A1:A3, C1:C3)',
          formula: '=XLOOKUP("z", A1:A3, C1:C3)',
        ),
        const FortuneCellCoord(17, 4): const FortuneCell(
          value: '=IFNA(VLOOKUP("z", A1:C3, 2, FALSE), "missing")',
          formula: '=IFNA(VLOOKUP("z", A1:C3, 2, FALSE), "missing")',
        ),
        const FortuneCellCoord(18, 4): const FortuneCell(
          value: '=ADDRESS(2, 3)',
          formula: '=ADDRESS(2, 3)',
        ),
        const FortuneCellCoord(19, 4): const FortuneCell(
          value: '=ADDRESS(2, 3, 4)',
          formula: '=ADDRESS(2, 3, 4)',
        ),
        const FortuneCellCoord(20, 4): const FortuneCell(
          value: '=ADDRESS(2, 3, 2, FALSE)',
          formula: '=ADDRESS(2, 3, 2, FALSE)',
        ),
        const FortuneCellCoord(21, 4): const FortuneCell(
          value: '=ADDRESS(2, 3, 1, TRUE, "Sheet 2")',
          formula: '=ADDRESS(2, 3, 1, TRUE, "Sheet 2")',
        ),
        const FortuneCellCoord(22, 4): const FortuneCell(
          value: '=ADDRESS(2, 3, 9)',
          formula: '=ADDRESS(2, 3, 9)',
        ),
        const FortuneCellCoord(23, 4): const FortuneCell(
          value: '=ROW(C5)',
          formula: '=ROW(C5)',
        ),
        const FortuneCellCoord(24, 4): const FortuneCell(
          value: '=COLUMN(C5)',
          formula: '=COLUMN(C5)',
        ),
        const FortuneCellCoord(25, 4): const FortuneCell(
          value: r'=ROW($C$5:D8)',
          formula: r'=ROW($C$5:D8)',
        ),
        const FortuneCellCoord(26, 4): const FortuneCell(
          value: r'=COLUMN($C$5:D8)',
          formula: r'=COLUMN($C$5:D8)',
        ),
        const FortuneCellCoord(27, 4): const FortuneCell(
          value: '=LOOKUP(25, B1:B3, C1:C3)',
          formula: '=LOOKUP(25, B1:B3, C1:C3)',
        ),
        const FortuneCellCoord(28, 4): const FortuneCell(
          value: '=LOOKUP(20, B1:B3)',
          formula: '=LOOKUP(20, B1:B3)',
        ),
        const FortuneCellCoord(29, 4): const FortuneCell(
          value: '=LOOKUP(5, B1:B3, C1:C3)',
          formula: '=LOOKUP(5, B1:B3, C1:C3)',
        ),
        const FortuneCellCoord(30, 4): const FortuneCell(
          value: '=LOOKUP("b", A1:A3, C1:C3)',
          formula: '=LOOKUP("b", A1:A3, C1:C3)',
        ),
        const FortuneCellCoord(31, 4): const FortuneCell(
          value: '=LOOKUP(25, B1:C3)',
          formula: '=LOOKUP(25, B1:C3)',
        ),
        const FortuneCellCoord(32, 4): const FortuneCell(
          value: '=LOOKUP(25, A32:C33)',
          formula: '=LOOKUP(25, A32:C33)',
        ),
        const FortuneCellCoord(33, 4): const FortuneCell(
          value: '=ROW()',
          formula: '=ROW()',
        ),
        const FortuneCellCoord(34, 4): const FortuneCell(
          value: '=COLUMN()',
          formula: '=COLUMN()',
        ),
        const FortuneCellCoord(35, 4): const FortuneCell(
          value: '=SUM(OFFSET(A1, 1, 1, 2, 2))',
          formula: '=SUM(OFFSET(A1, 1, 1, 2, 2))',
        ),
        const FortuneCellCoord(36, 4): const FortuneCell(
          value: '=INDEX(OFFSET(A1, 1, 0, 2, 3), 2, 3)',
          formula: '=INDEX(OFFSET(A1, 1, 0, 2, 3), 2, 3)',
        ),
        const FortuneCellCoord(37, 4): const FortuneCell(
          value:
              '=ROWS(OFFSET(A1, 0, 0, 2, 3))&"x"&COLUMNS(OFFSET(A1, 0, 0, 2, 3))',
          formula:
              '=ROWS(OFFSET(A1, 0, 0, 2, 3))&"x"&COLUMNS(OFFSET(A1, 0, 0, 2, 3))',
        ),
        const FortuneCellCoord(38, 4): const FortuneCell(
          value: '=OFFSET(A1, -1, 0)',
          formula: '=OFFSET(A1, -1, 0)',
        ),
        const FortuneCellCoord(39, 4): const FortuneCell(
          value: '=OFFSET(A1, 0, 0, 0, 1)',
          formula: '=OFFSET(A1, 0, 0, 0, 1)',
        ),
        const FortuneCellCoord(40, 4): const FortuneCell(
          value: '=INDIRECT("A2")',
          formula: '=INDIRECT("A2")',
        ),
        const FortuneCellCoord(41, 4): const FortuneCell(
          value: '=INDIRECT("B2")+1',
          formula: '=INDIRECT("B2")+1',
        ),
        const FortuneCellCoord(42, 4): const FortuneCell(
          value: '=SUM(INDIRECT("B1:C2"))',
          formula: '=SUM(INDIRECT("B1:C2"))',
        ),
        const FortuneCellCoord(43, 4): const FortuneCell(
          value: '=INDEX(INDIRECT("A1:C3"), 3, 2)',
          formula: '=INDEX(INDIRECT("A1:C3"), 3, 2)',
        ),
        const FortuneCellCoord(44, 4): const FortuneCell(
          value: '=INDIRECT("R2C3", FALSE)',
          formula: '=INDIRECT("R2C3", FALSE)',
        ),
        const FortuneCellCoord(45, 4): const FortuneCell(
          value: '=INDIRECT("\'Sheet1\'!C3")',
          formula: '=INDIRECT("\'Sheet1\'!C3")',
        ),
        const FortuneCellCoord(46, 4): const FortuneCell(
          value: '=INDIRECT("missing")',
          formula: '=INDIRECT("missing")',
        ),
        const FortuneCellCoord(47, 4): const FortuneCell(
          value: '=ROW(INDIRECT("C5:D8"))',
          formula: '=ROW(INDIRECT("C5:D8"))',
        ),
        const FortuneCellCoord(48, 4): const FortuneCell(
          value: '=COLUMN(OFFSET(A1, 1, 2))',
          formula: '=COLUMN(OFFSET(A1, 1, 2))',
        ),
        const FortuneCellCoord(49, 4): const FortuneCell(
          value: '=SUM(INDEX(A1:C3, 0, 2))',
          formula: '=SUM(INDEX(A1:C3, 0, 2))',
        ),
        const FortuneCellCoord(50, 4): const FortuneCell(
          value: '=SUM(INDEX(A1:C3, 2, 0))',
          formula: '=SUM(INDEX(A1:C3, 2, 0))',
        ),
        const FortuneCellCoord(51, 4): const FortuneCell(
          value: '=SUM(INDEX(A1:C3, 0, 0))',
          formula: '=SUM(INDEX(A1:C3, 0, 0))',
        ),
        const FortuneCellCoord(52, 4): const FortuneCell(
          value: '=ROWS(INDEX(A1:C3, 0, 2))&"x"&COLUMNS(INDEX(A1:C3, 0, 2))',
          formula: '=ROWS(INDEX(A1:C3, 0, 2))&"x"&COLUMNS(INDEX(A1:C3, 0, 2))',
        ),
        const FortuneCellCoord(53, 4): const FortuneCell(
          value: '=ROW(INDEX(A1:C3, 0, 2))&","&COLUMN(INDEX(A1:C3, 0, 2))',
          formula: '=ROW(INDEX(A1:C3, 0, 2))&","&COLUMN(INDEX(A1:C3, 0, 2))',
        ),
        const FortuneCellCoord(54, 4): const FortuneCell(
          value: '=SUM(CHOOSE(2, A1:A3, B1:B3))',
          formula: '=SUM(CHOOSE(2, A1:A3, B1:B3))',
        ),
        const FortuneCellCoord(55, 4): const FortuneCell(
          value: '=INDEX(CHOOSE(2, A1:C1, A2:C2), 1, 3)',
          formula: '=INDEX(CHOOSE(2, A1:C1, A2:C2), 1, 3)',
        ),
        const FortuneCellCoord(56, 4): const FortuneCell(
          value:
              '=ROWS(CHOOSE(1, B2:C3, A1:A2))&"x"&COLUMNS(CHOOSE(1, B2:C3, A1:A2))',
          formula:
              '=ROWS(CHOOSE(1, B2:C3, A1:A2))&"x"&COLUMNS(CHOOSE(1, B2:C3, A1:A2))',
        ),
        const FortuneCellCoord(57, 4): const FortuneCell(
          value:
              '=ROW(CHOOSE(1, B2:C3, A1:A2))&","&COLUMN(CHOOSE(1, B2:C3, A1:A2))',
          formula:
              '=ROW(CHOOSE(1, B2:C3, A1:A2))&","&COLUMN(CHOOSE(1, B2:C3, A1:A2))',
        ),
        const FortuneCellCoord(58, 4): const FortuneCell(
          value: '=SUM(XLOOKUP("b", A1:A3, B1:C3))',
          formula: '=SUM(XLOOKUP("b", A1:A3, B1:C3))',
        ),
        const FortuneCellCoord(59, 4): const FortuneCell(
          value: '=INDEX(XLOOKUP("b", A1:A3, B1:C3), 1, 2)',
          formula: '=INDEX(XLOOKUP("b", A1:A3, B1:C3), 1, 2)',
        ),
        const FortuneCellCoord(60, 4): const FortuneCell(
          value: '=SUM(XLOOKUP("q2", A5:C5, A6:C7))',
          formula: '=SUM(XLOOKUP("q2", A5:C5, A6:C7))',
        ),
        const FortuneCellCoord(61, 4): const FortuneCell(
          value:
              '=ROWS(XLOOKUP("q2", A5:C5, A6:C7))&"x"&COLUMNS(XLOOKUP("q2", A5:C5, A6:C7))',
          formula:
              '=ROWS(XLOOKUP("q2", A5:C5, A6:C7))&"x"&COLUMNS(XLOOKUP("q2", A5:C5, A6:C7))',
        ),
        const FortuneCellCoord(62, 4): const FortuneCell(
          value:
              '=ROW(XLOOKUP("q2", A5:C5, A6:C7))&","&COLUMN(XLOOKUP("q2", A5:C5, A6:C7))',
          formula:
              '=ROW(XLOOKUP("q2", A5:C5, A6:C7))&","&COLUMN(XLOOKUP("q2", A5:C5, A6:C7))',
        ),
        const FortuneCellCoord(63, 4): const FortuneCell(
          value: '=CHOOSE(2, 1/0, "safe", UNKNOWN(1))',
          formula: '=CHOOSE(2, 1/0, "safe", UNKNOWN(1))',
        ),
        const FortuneCellCoord(64, 4): const FortuneCell(
          value: '=SUM(CHOOSE(2, 1/0, B1:B3))',
          formula: '=SUM(CHOOSE(2, 1/0, B1:B3))',
        ),
        const FortuneCellCoord(65, 4): const FortuneCell(
          value: '=CHOOSE(1, 1/0, "safe")',
          formula: '=CHOOSE(1, 1/0, "safe")',
        ),
        const FortuneCellCoord(66, 4): const FortuneCell(
          value: '=XMATCH("b", A1:A3, 3)',
          formula: '=XMATCH("b", A1:A3, 3)',
        ),
        const FortuneCellCoord(67, 4): const FortuneCell(
          value: '=XMATCH("b", A1:A3, 0, 0)',
          formula: '=XMATCH("b", A1:A3, 0, 0)',
        ),
        const FortuneCellCoord(68, 4): const FortuneCell(
          value: '=XLOOKUP("b", A1:A3, B1:B3, "missing", 3)',
          formula: '=XLOOKUP("b", A1:A3, B1:B3, "missing", 3)',
        ),
        const FortuneCellCoord(69, 4): const FortuneCell(
          value: '=XLOOKUP("b", A1:A3, B1:B3, "missing", 0, 0)',
          formula: '=XLOOKUP("b", A1:A3, B1:B3, "missing", 0, 0)',
        ),
        const FortuneCellCoord(70, 4): const FortuneCell(
          value: '=XMATCH("b", A1:B3, 0)',
          formula: '=XMATCH("b", A1:B3, 0)',
        ),
        const FortuneCellCoord(71, 4): const FortuneCell(
          value: '=XLOOKUP("b", A1:B3, C1:C3)',
          formula: '=XLOOKUP("b", A1:B3, C1:C3)',
        ),
        const FortuneCellCoord(72, 4): const FortuneCell(
          value: '=XLOOKUP("b", A1:A3, B1:B3, UNKNOWN(1))',
          formula: '=XLOOKUP("b", A1:A3, B1:B3, UNKNOWN(1))',
        ),
        const FortuneCellCoord(73, 4): const FortuneCell(
          value: '=XLOOKUP("z", A1:A3, B1:B3, UNKNOWN(1))',
          formula: '=XLOOKUP("z", A1:A3, B1:B3, UNKNOWN(1))',
        ),
        const FortuneCellCoord(74, 4): const FortuneCell(
          value: '=XLOOKUP("missing", A75:A76, B75:B76, "fallback")',
          formula: '=XLOOKUP("missing", A75:A76, B75:B76, "fallback")',
        ),
        const FortuneCellCoord(75, 4): const FortuneCell(
          value: '=XLOOKUP("alpha", A75:A76, B75:B76, "fallback")',
          formula: '=XLOOKUP("alpha", A75:A76, B75:B76, "fallback")',
        ),
        const FortuneCellCoord(76, 4): const FortuneCell(
          value: '=MATCH("b", A1:A3, 2)',
          formula: '=MATCH("b", A1:A3, 2)',
        ),
        const FortuneCellCoord(77, 4): const FortuneCell(
          value: '=MATCH("b", A1:B3, 0)',
          formula: '=MATCH("b", A1:B3, 0)',
        ),
        const FortuneCellCoord(78, 4): const FortuneCell(
          value: '=VLOOKUP("b", A1:C3, 4, FALSE)',
          formula: '=VLOOKUP("b", A1:C3, 4, FALSE)',
        ),
        const FortuneCellCoord(79, 4): const FortuneCell(
          value: '=HLOOKUP("q2", A5:C7, 4, FALSE)',
          formula: '=HLOOKUP("q2", A5:C7, 4, FALSE)',
        ),
        const FortuneCellCoord(80, 4): const FortuneCell(
          value: '=XLOOKUP("z", A1:A3, B1:C2, "fallback")',
          formula: '=XLOOKUP("z", A1:A3, B1:C2, "fallback")',
        ),
        const FortuneCellCoord(81, 4): const FortuneCell(
          value: '=XLOOKUP("b", A1:A3, B1:C2, "fallback")',
          formula: '=XLOOKUP("b", A1:A3, B1:C2, "fallback")',
        ),
        const FortuneCellCoord(82, 4): const FortuneCell(
          value: '=LOOKUP("b", A1:B3, C1:C3)',
          formula: '=LOOKUP("b", A1:B3, C1:C3)',
        ),
        const FortuneCellCoord(83, 4): const FortuneCell(
          value: '=LOOKUP("b", A1:A3, B1:C2)',
          formula: '=LOOKUP("b", A1:A3, B1:C2)',
        ),
        const FortuneCellCoord(84, 4): const FortuneCell(
          value: '=VLOOKUP("missing", A75:B76, 2, FALSE)',
          formula: '=VLOOKUP("missing", A75:B76, 2, FALSE)',
        ),
        const FortuneCellCoord(85, 4): const FortuneCell(
          value: '=VLOOKUP("alpha", A75:B76, 2, FALSE)',
          formula: '=VLOOKUP("alpha", A75:B76, 2, FALSE)',
        ),
        const FortuneCellCoord(86, 4): const FortuneCell(
          value: '=HLOOKUP("missing", A85:B86, 2, FALSE)',
          formula: '=HLOOKUP("missing", A85:B86, 2, FALSE)',
        ),
        const FortuneCellCoord(87, 4): const FortuneCell(
          value: '=HLOOKUP("alpha", A85:B86, 2, FALSE)',
          formula: '=HLOOKUP("alpha", A85:B86, 2, FALSE)',
        ),
        const FortuneCellCoord(88, 4): const FortuneCell(
          value: '=INDEX(A1:C3, 4, 1)',
          formula: '=INDEX(A1:C3, 4, 1)',
        ),
        const FortuneCellCoord(89, 4): const FortuneCell(
          value: '=INDEX(A1:C3, 1, 4)',
          formula: '=INDEX(A1:C3, 1, 4)',
        ),
        const FortuneCellCoord(90, 4): const FortuneCell(
          value: '=LOOKUP("aardvark", A75:A76, B75:B76)',
          formula: '=LOOKUP("aardvark", A75:A76, B75:B76)',
        ),
        const FortuneCellCoord(91, 4): const FortuneCell(
          value: '=LOOKUP("alpha", A75:A76, B75:B76)',
          formula: '=LOOKUP("alpha", A75:A76, B75:B76)',
        ),
        const FortuneCellCoord(92, 4): const FortuneCell(
          value: '=INDEX(A75:B76, 2, 2)',
          formula: '=INDEX(A75:B76, 2, 2)',
        ),
        const FortuneCellCoord(93, 4): const FortuneCell(
          value: '=INDEX(A75:B76, 1, 2)',
          formula: '=INDEX(A75:B76, 1, 2)',
        ),
        const FortuneCellCoord(94, 4): const FortuneCell(
          value: '=OFFSET(A1, 1/0, 0)',
          formula: '=OFFSET(A1, 1/0, 0)',
        ),
        const FortuneCellCoord(95, 4): const FortuneCell(
          value: '=OFFSET(A1, 0, 0, UNKNOWN(1), 1)',
          formula: '=OFFSET(A1, 0, 0, UNKNOWN(1), 1)',
        ),
        const FortuneCellCoord(96, 4): const FortuneCell(
          value: '=INDIRECT(1/0)',
          formula: '=INDIRECT(1/0)',
        ),
        const FortuneCellCoord(97, 4): const FortuneCell(
          value: '=INDIRECT("A1", UNKNOWN(1))',
          formula: '=INDIRECT("A1", UNKNOWN(1))',
        ),
        const FortuneCellCoord(98, 4): const FortuneCell(
          value: '=ROW(1/0)',
          formula: '=ROW(1/0)',
        ),
        const FortuneCellCoord(99, 4): const FortuneCell(
          value: '=COLUMN(UNKNOWN(1))',
          formula: '=COLUMN(UNKNOWN(1))',
        ),
        const FortuneCellCoord(100, 4): const FortuneCell(
          value: '=MATCH("alpha", A75:B75, 0)',
          formula: '=MATCH("alpha", A75:B75, 0)',
        ),
        const FortuneCellCoord(101, 4): const FortuneCell(
          value: '=MATCH("missing", A75:B75, 0)',
          formula: '=MATCH("missing", A75:B75, 0)',
        ),
        const FortuneCellCoord(102, 4): const FortuneCell(
          value: '=XMATCH("alpha", A75:B75)',
          formula: '=XMATCH("alpha", A75:B75)',
        ),
        const FortuneCellCoord(103, 4): const FortuneCell(
          value: '=XMATCH("alpha", A75:B75, 0, -1)',
          formula: '=XMATCH("alpha", A75:B75, 0, -1)',
        ),
        const FortuneCellCoord(104, 4): const FortuneCell(
          value: '=MATCH("a*", A1:A3, 0)',
          formula: '=MATCH("a*", A1:A3, 0)',
        ),
        const FortuneCellCoord(105, 4): const FortuneCell(
          value: '=MATCH("?", A1:A3, 0)',
          formula: '=MATCH("?", A1:A3, 0)',
        ),
        const FortuneCellCoord(106, 4): const FortuneCell(
          value: '=MATCH("a~*", A107:A109, 0)',
          formula: '=MATCH("a~*", A107:A109, 0)',
        ),
        const FortuneCellCoord(107, 4): const FortuneCell(
          value: '=XMATCH("a~?", A107:A109, 2)',
          formula: '=XMATCH("a~?", A107:A109, 2)',
        ),
        const FortuneCellCoord(108, 4): const FortuneCell(
          value: '=XLOOKUP("a~~", A107:A109, B107:B109, "missing", 2)',
          formula: '=XLOOKUP("a~~", A107:A109, B107:B109, "missing", 2)',
        ),
        const FortuneCellCoord(109, 4): const FortuneCell(
          value: '=VLOOKUP("a~*", A107:B109, 2, FALSE)',
          formula: '=VLOOKUP("a~*", A107:B109, 2, FALSE)',
        ),
        const FortuneCellCoord(110, 4): const FortuneCell(
          value: '=VLOOKUP("alpha", A110:B111, 2, FALSE)',
          formula: '=VLOOKUP("alpha", A110:B111, 2, FALSE)',
        ),
        const FortuneCellCoord(111, 4): const FortuneCell(
          value: '=HLOOKUP("alpha", A75:B76, 2, FALSE)',
          formula: '=HLOOKUP("alpha", A75:B76, 2, FALSE)',
        ),
        const FortuneCellCoord(112, 4): const FortuneCell(
          value: '=XLOOKUP("alpha", A110:A111, B110:B111)',
          formula: '=XLOOKUP("alpha", A110:A111, B110:B111)',
        ),
        const FortuneCellCoord(113, 4): const FortuneCell(
          value: '=XLOOKUP("missing", A110:A111, B110:B111, "fallback")',
          formula: '=XLOOKUP("missing", A110:A111, B110:B111, "fallback")',
        ),
        const FortuneCellCoord(114, 4): const FortuneCell(
          value: '=MATCH("z", A110:A111)',
          formula: '=MATCH("z", A110:A111)',
        ),
        const FortuneCellCoord(115, 4): const FortuneCell(
          value: '=XMATCH("z", A110:A111, 1)',
          formula: '=XMATCH("z", A110:A111, 1)',
        ),
        const FortuneCellCoord(116, 4): const FortuneCell(
          value: '=XMATCH(20, B1:B3, 0, 2)',
          formula: '=XMATCH(20, B1:B3, 0, 2)',
        ),
        const FortuneCellCoord(117, 4): const FortuneCell(
          value: '=XMATCH(25, B1:B3, -1, 2)',
          formula: '=XMATCH(25, B1:B3, -1, 2)',
        ),
        const FortuneCellCoord(118, 4): const FortuneCell(
          value: '=XMATCH(25, B1:B3, 1, 2)',
          formula: '=XMATCH(25, B1:B3, 1, 2)',
        ),
        const FortuneCellCoord(119, 4): const FortuneCell(
          value: '=XLOOKUP(25, B1:B3, C1:C3, "none", -1, 2)',
          formula: '=XLOOKUP(25, B1:B3, C1:C3, "none", -1, 2)',
        ),
        const FortuneCellCoord(120, 4): const FortuneCell(
          value: '=XLOOKUP(25, A120:A122, B120:B122, "none", 1, -2)',
          formula: '=XLOOKUP(25, A120:A122, B120:B122, "none", 1, -2)',
        ),
        const FortuneCellCoord(121, 4): const FortuneCell(
          value: '=XMATCH(25, A120:A122, -1, -2)',
          formula: '=XMATCH(25, A120:A122, -1, -2)',
        ),
        const FortuneCellCoord(122, 4): const FortuneCell(
          value: '=XMATCH(5, B1:B3, -1, 2)',
          formula: '=XMATCH(5, B1:B3, -1, 2)',
        ),
        const FortuneCellCoord(123, 4): const FortuneCell(
          value: '=SUM(CHOOSE({1,2}, 10, 20))',
          formula: '=SUM(CHOOSE({1,2}, 10, 20))',
        ),
        const FortuneCellCoord(124, 4): const FortuneCell(
          value: '=INDEX(CHOOSE({1,2}, "red", "blue"), 1, 2)',
          formula: '=INDEX(CHOOSE({1,2}, "red", "blue"), 1, 2)',
        ),
        const FortuneCellCoord(125, 4): const FortuneCell(
          value:
              '=ROWS(CHOOSE({1;2}, "red", "blue"))&"x"&COLUMNS(CHOOSE({1;2}, "red", "blue"))',
          formula:
              '=ROWS(CHOOSE({1;2}, "red", "blue"))&"x"&COLUMNS(CHOOSE({1;2}, "red", "blue"))',
        ),
        const FortuneCellCoord(126, 4): const FortuneCell(
          value: '=INDEX(CHOOSE({2,2}, UNKNOWN(1), "safe"), 1, 2)',
          formula: '=INDEX(CHOOSE({2,2}, UNKNOWN(1), "safe"), 1, 2)',
        ),
        const FortuneCellCoord(127, 4): const FortuneCell(
          value: '=SUM(OFFSET(INDEX(A1:C3, 2, 0), 0, 1, 1, 2))',
          formula: '=SUM(OFFSET(INDEX(A1:C3, 2, 0), 0, 1, 1, 2))',
        ),
        const FortuneCellCoord(128, 4): const FortuneCell(
          value: '=SUM(OFFSET(INDIRECT("B1:C2"), 1, 0))',
          formula: '=SUM(OFFSET(INDIRECT("B1:C2"), 1, 0))',
        ),
        const FortuneCellCoord(129, 4): const FortuneCell(
          value:
              '=ROW(OFFSET(CHOOSE(1, B2:C3, A1:A2), 1, 0))&","&COLUMN(OFFSET(CHOOSE(1, B2:C3, A1:A2), 1, 0))',
          formula:
              '=ROW(OFFSET(CHOOSE(1, B2:C3, A1:A2), 1, 0))&","&COLUMN(OFFSET(CHOOSE(1, B2:C3, A1:A2), 1, 0))',
        ),
        const FortuneCellCoord(130, 4): const FortuneCell(
          value: '=OFFSET(A1, 1, 1)',
          formula: '=OFFSET(A1, 1, 1)',
        ),
        const FortuneCellCoord(131, 4): const FortuneCell(
          value: '=OFFSET(INDIRECT("B1:C2"), 1, 1)',
          formula: '=OFFSET(INDIRECT("B1:C2"), 1, 1)',
        ),
        const FortuneCellCoord(132, 4): const FortuneCell(
          value: '=MATCH()',
          formula: '=MATCH()',
        ),
        const FortuneCellCoord(133, 4): const FortuneCell(
          value: '=MATCH(1)',
          formula: '=MATCH(1)',
        ),
        const FortuneCellCoord(134, 4): const FortuneCell(
          value: '=AREAS(A1:C3)',
          formula: '=AREAS(A1:C3)',
        ),
        const FortuneCellCoord(135, 4): const FortuneCell(
          value: '=AREAS((A1:C3,B5:C7))',
          formula: '=AREAS((A1:C3,B5:C7))',
        ),
        const FortuneCellCoord(136, 4): const FortuneCell(
          value: '=AREAS((Sheet1!A1:C3,\'[Book1.xlsx]Sheet1\'!B5:C7))',
          formula: '=AREAS((Sheet1!A1:C3,\'[Book1.xlsx]Sheet1\'!B5:C7))',
        ),
        const FortuneCellCoord(137, 4): const FortuneCell(
          value: '=JOIN(ROW(A1:C3, 0))',
          formula: '=JOIN(ROW(A1:C3, 0))',
        ),
        const FortuneCellCoord(138, 4): const FortuneCell(
          value: '=JOIN(ROW(A1:C3, 2))',
          formula: '=JOIN(ROW(A1:C3, 2))',
        ),
        const FortuneCellCoord(139, 4): const FortuneCell(
          value: '=JOIN(COLUMN(A1:C3, 1))',
          formula: '=JOIN(COLUMN(A1:C3, 1))',
        ),
        const FortuneCellCoord(140, 4): const FortuneCell(
          value: '=ROW(A1:C3, -1)',
          formula: '=ROW(A1:C3, -1)',
        ),
        const FortuneCellCoord(141, 4): const FortuneCell(
          value: '=ROW(A1:C3)',
          formula: '=ROW(A1:C3)',
        ),
        const FortuneCellCoord(142, 4): const FortuneCell(
          value: '=COLUMN(A1:C3)',
          formula: '=COLUMN(A1:C3)',
        ),
        const FortuneCellCoord(143, 4): const FortuneCell(
          value: '=COLUMN(A1:C2)',
          formula: '=COLUMN(A1:C2)',
        ),
        const FortuneCellCoord(144, 4): const FortuneCell(
          value: '=ROW(A1:C2)',
          formula: '=ROW(A1:C2)',
        ),
        const FortuneCellCoord(145, 4): const FortuneCell(
          value: '=ROW(A1:C2, -1)',
          formula: '=ROW(A1:C2, -1)',
        ),
        const FortuneCellCoord(146, 4): const FortuneCell(
          value: '=MATCH(1, {0,1,2,3,4,100,7})',
          formula: '=MATCH(1, {0,1,2,3,4,100,7})',
        ),
        const FortuneCellCoord(147, 4): const FortuneCell(
          value: '=MATCH(4, {0,1,2,3,4,100,7}, 1)',
          formula: '=MATCH(4, {0,1,2,3,4,100,7}, 1)',
        ),
        const FortuneCellCoord(148, 4): const FortuneCell(
          value: '=MATCH("jima", {"jima","jimb","jimc","bernie"}, 0)',
          formula: '=MATCH("jima", {"jima","jimb","jimc","bernie"}, 0)',
        ),
        const FortuneCellCoord(149, 4): const FortuneCell(
          value: '=MATCH("j?b", {"jima","jimb","jimc","bernie"}, 0)',
          formula: '=MATCH("j?b", {"jima","jimb","jimc","bernie"}, 0)',
        ),
        const FortuneCellCoord(150, 4): const FortuneCell(
          value: '=MATCH("jimc", {"jima","jimb","jimc","bernie"}, 0)',
          formula: '=MATCH("jimc", {"jima","jimb","jimc","bernie"}, 0)',
        ),
        const FortuneCellCoord(151, 4): const FortuneCell(
          value: '=MATCH(1, foo)',
          formula: '=MATCH(1, foo)',
        ),
        const FortuneCellCoord(152, 4): const FortuneCell(
          value: '=MATCH(4, foo, 1)',
          formula: '=MATCH(4, foo, 1)',
        ),
        const FortuneCellCoord(153, 4): const FortuneCell(
          value: '=VLOOKUP("b", A1:C3, 0, FALSE)',
          formula: '=VLOOKUP("b", A1:C3, 0, FALSE)',
        ),
        const FortuneCellCoord(154, 4): const FortuneCell(
          value: '=HLOOKUP("q2", A5:C7, 0, FALSE)',
          formula: '=HLOOKUP("q2", A5:C7, 0, FALSE)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '222');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '300');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '111');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '300');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(13, 4)]?.renderedText, 'blue');
    expect(sheet.cells[const FortuneCellCoord(14, 4)]?.renderedText, '3x3');
    expect(sheet.cells[const FortuneCellCoord(15, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(16, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(17, 4)]?.renderedText, 'missing');
    expect(sheet.cells[const FortuneCellCoord(18, 4)]?.renderedText, r'$C$2');
    expect(sheet.cells[const FortuneCellCoord(19, 4)]?.renderedText, 'C2');
    expect(sheet.cells[const FortuneCellCoord(20, 4)]?.renderedText, 'R2C[3]');
    expect(
      sheet.cells[const FortuneCellCoord(21, 4)]?.renderedText,
      r"'Sheet 2'!$C$2",
    );
    expect(sheet.cells[const FortuneCellCoord(22, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(23, 4)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(24, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(25, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(26, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(27, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(28, 4)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(29, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(30, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(31, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(32, 4)]?.renderedText, 'blue');
    expect(sheet.cells[const FortuneCellCoord(33, 4)]?.renderedText, '34');
    expect(sheet.cells[const FortuneCellCoord(34, 4)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(35, 4)]?.renderedText, '550');
    expect(sheet.cells[const FortuneCellCoord(36, 4)]?.renderedText, '300');
    expect(sheet.cells[const FortuneCellCoord(37, 4)]?.renderedText, '2x3');
    expect(sheet.cells[const FortuneCellCoord(38, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(39, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(40, 4)]?.renderedText, 'b');
    expect(sheet.cells[const FortuneCellCoord(41, 4)]?.renderedText, '21');
    expect(sheet.cells[const FortuneCellCoord(42, 4)]?.renderedText, '330');
    expect(sheet.cells[const FortuneCellCoord(43, 4)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(44, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(45, 4)]?.renderedText, '300');
    expect(sheet.cells[const FortuneCellCoord(46, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(47, 4)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(48, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(49, 4)]?.renderedText, '60');
    expect(sheet.cells[const FortuneCellCoord(50, 4)]?.renderedText, '220');
    expect(sheet.cells[const FortuneCellCoord(51, 4)]?.renderedText, '660');
    expect(sheet.cells[const FortuneCellCoord(52, 4)]?.renderedText, '3x1');
    expect(sheet.cells[const FortuneCellCoord(53, 4)]?.renderedText, '1,2');
    expect(sheet.cells[const FortuneCellCoord(54, 4)]?.renderedText, '60');
    expect(sheet.cells[const FortuneCellCoord(55, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(56, 4)]?.renderedText, '2x2');
    expect(sheet.cells[const FortuneCellCoord(57, 4)]?.renderedText, '2,2');
    expect(sheet.cells[const FortuneCellCoord(58, 4)]?.renderedText, '220');
    expect(sheet.cells[const FortuneCellCoord(59, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(60, 4)]?.renderedText, '244');
    expect(sheet.cells[const FortuneCellCoord(61, 4)]?.renderedText, '2x1');
    expect(sheet.cells[const FortuneCellCoord(62, 4)]?.renderedText, '6,2');
    expect(sheet.cells[const FortuneCellCoord(63, 4)]?.renderedText, 'safe');
    expect(sheet.cells[const FortuneCellCoord(64, 4)]?.renderedText, '60');
    expect(sheet.cells[const FortuneCellCoord(65, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(66, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(67, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(68, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(69, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(70, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(71, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(72, 4)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(73, 4)]?.renderedText, '#NAME?');
    expect(
      sheet.cells[const FortuneCellCoord(74, 4)]?.renderedText,
      'fallback',
    );
    expect(sheet.cells[const FortuneCellCoord(75, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(76, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(77, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(78, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(79, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(80, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(81, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(82, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(83, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(84, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(85, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(86, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(87, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(88, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(89, 4)]?.renderedText, '#REF!');
    expect(sheet.cells[const FortuneCellCoord(90, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(91, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(92, 4)]?.renderedText, 'ok');
    expect(sheet.cells[const FortuneCellCoord(93, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(94, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(95, 4)]?.renderedText, '#NAME?');
    expect(sheet.cells[const FortuneCellCoord(96, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(97, 4)]?.renderedText, '#NAME?');
    expect(sheet.cells[const FortuneCellCoord(98, 4)]?.renderedText, '#DIV/0!');
    expect(sheet.cells[const FortuneCellCoord(99, 4)]?.renderedText, '#NAME?');
    expect(sheet.cells[const FortuneCellCoord(100, 4)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(101, 4)]?.renderedText,
      '#DIV/0!',
    );
    expect(sheet.cells[const FortuneCellCoord(102, 4)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(103, 4)]?.renderedText,
      '#DIV/0!',
    );
    expect(sheet.cells[const FortuneCellCoord(104, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(105, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(106, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(107, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(108, 4)]?.renderedText, 'tilde');
    expect(sheet.cells[const FortuneCellCoord(109, 4)]?.renderedText, 'star');
    expect(sheet.cells[const FortuneCellCoord(110, 4)]?.renderedText, 'v-ok');
    expect(sheet.cells[const FortuneCellCoord(111, 4)]?.renderedText, 'beta');
    expect(sheet.cells[const FortuneCellCoord(112, 4)]?.renderedText, 'v-ok');
    expect(
      sheet.cells[const FortuneCellCoord(113, 4)]?.renderedText,
      '#DIV/0!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(114, 4)]?.renderedText,
      '#DIV/0!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(115, 4)]?.renderedText,
      '#DIV/0!',
    );
    expect(sheet.cells[const FortuneCellCoord(116, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(117, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(118, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(119, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(120, 4)]?.renderedText, 'high');
    expect(sheet.cells[const FortuneCellCoord(121, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(122, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(123, 4)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(124, 4)]?.renderedText, 'blue');
    expect(sheet.cells[const FortuneCellCoord(125, 4)]?.renderedText, '2x1');
    expect(sheet.cells[const FortuneCellCoord(126, 4)]?.renderedText, 'safe');
    expect(sheet.cells[const FortuneCellCoord(127, 4)]?.renderedText, '220');
    expect(sheet.cells[const FortuneCellCoord(128, 4)]?.renderedText, '550');
    expect(sheet.cells[const FortuneCellCoord(129, 4)]?.renderedText, '3,2');
    expect(sheet.cells[const FortuneCellCoord(130, 4)]?.renderedText, '20');
    expect(sheet.cells[const FortuneCellCoord(131, 4)]?.renderedText, '200');
    expect(sheet.cells[const FortuneCellCoord(132, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(133, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(134, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(135, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(136, 4)]?.renderedText, '2');
    expect(
      sheet.cells[const FortuneCellCoord(137, 4)]?.renderedText,
      'a,10,100',
    );
    expect(
      sheet.cells[const FortuneCellCoord(138, 4)]?.renderedText,
      'c,30,300',
    );
    expect(
      sheet.cells[const FortuneCellCoord(139, 4)]?.renderedText,
      '10,20,30',
    );
    expect(sheet.cells[const FortuneCellCoord(140, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(141, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(142, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(143, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(144, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(145, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(146, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(147, 4)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(148, 4)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(149, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(150, 4)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(151, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(152, 4)]?.renderedText, '5');
    expect(
      sheet.cells[const FortuneCellCoord(153, 4)]?.renderedText,
      '#VALUE!',
    );
    expect(
      sheet.cells[const FortuneCellCoord(154, 4)]?.renderedText,
      '#VALUE!',
    );
  });

  test('formula engine evaluates ROW and COLUMN callback shape fixtures', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '1'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(2, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(2, 1): const FortuneCell(value: '4'),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=ROWS(A1:B3)',
          formula: '=ROWS(A1:B3)',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=COLUMNS(A1:B3)',
          formula: '=COLUMNS(A1:B3)',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=JOIN(ROW(A1:B3, 0))',
          formula: '=JOIN(ROW(A1:B3, 0))',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=JOIN(ROW(A1:B3, 2))',
          formula: '=JOIN(ROW(A1:B3, 2))',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=JOIN(COLUMN(A1:B3, 1))',
          formula: '=JOIN(COLUMN(A1:B3, 1))',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=ROW(A1:B3)',
          formula: '=ROW(A1:B3)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=COLUMN(A1:B3)',
          formula: '=COLUMN(A1:B3)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ROW(A1:B3, -1)',
          formula: '=ROW(A1:B3, -1)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '1,2');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '2,4');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '2,3,4');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '#NUM!');
  });

  test('formula engine evaluates relative R1C1 INDIRECT references', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '2'),
        const FortuneCellCoord(1, 1): const FortuneCell(value: '3'),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=INDIRECT("R[-2]C[-2]", FALSE)',
          formula: '=INDIRECT("R[-2]C[-2]", FALSE)',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=SUM(INDIRECT("R[-3]C[-3]:R[-2]C[-2]", FALSE))',
          formula: '=SUM(INDIRECT("R[-3]C[-3]:R[-2]C[-2]", FALSE))',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '5');
  });

  test('formula engine evaluates MATCH string named variables', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: const {
        'formulaVariables': {
          'bar': ['jima', 'jimb', 'jimc', 'bernie'],
        },
      },
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=MATCH("jima", bar, 0)',
          formula: '=MATCH("jima", bar, 0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=MATCH("j?b", bar, 0)',
          formula: '=MATCH("j?b", bar, 0)',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MATCH("jimc", bar, 0)',
          formula: '=MATCH("jimc", bar, 0)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#N/A');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '3');
  });

  test('formula engine counts areas with quoted sheet name commas', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: r"=AREAS(('Q1, Bob''s'!A1:B2,'East, West'!C3:D4))",
          formula: r"=AREAS(('Q1, Bob''s'!A1:B2,'East, West'!C3:D4))",
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '2');
  });

  test('formula engine evaluates basic date helpers', () {
    final today = DateTime.now();
    final expectedTodaySerial = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(1899, 12, 30)).inDays;
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=DATE(2024, 2, 29)',
          formula: '=DATE(2024, 2, 29)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=YEAR(DATE(2024, 2, 29))',
          formula: '=YEAR(DATE(2024, 2, 29))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MONTH("2024-02-29")',
          formula: '=MONTH("2024-02-29")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=DAY("2024/02/29")',
          formula: '=DAY("2024/02/29")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=DATE(124, 14, 1)',
          formula: '=DATE(124, 14, 1)',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=TODAY()',
          formula: '=TODAY()',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=YEAR(TODAY())',
          formula: '=YEAR(TODAY())',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=MONTH(TODAY())',
          formula: '=MONTH(TODAY())',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=DAY(TODAY())',
          formula: '=DAY(TODAY())',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=DATEVALUE("2024-02-29")',
          formula: '=DATEVALUE("2024-02-29")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=DATEVALUE("not a date")',
          formula: '=DATEVALUE("not a date")',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=DATEVALUE(DATE(2024, 2, 29)+TIME(6, 0, 0))',
          formula: '=DATEVALUE(DATE(2024, 2, 29)+TIME(6, 0, 0))',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=EDATE("2024-01-31", 1)',
          formula: '=EDATE("2024-01-31", 1)',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=EOMONTH("2024-01-15", 1)',
          formula: '=EOMONTH("2024-01-15", 1)',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=DAYS("2024-03-01", "2024-02-28")',
          formula: '=DAYS("2024-03-01", "2024-02-28")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=WEEKDAY("2024-02-25")',
          formula: '=WEEKDAY("2024-02-25")',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=WEEKDAY("2024-02-25", 2)',
          formula: '=WEEKDAY("2024-02-25", 2)',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=DAYS360("2024-01-30", "2024-02-28")',
          formula: '=DAYS360("2024-01-30", "2024-02-28")',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=DAYS360("2024-01-31", "2024-02-29", TRUE)',
          formula: '=DAYS360("2024-01-31", "2024-02-29", TRUE)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=EDATE("not a date", 1)',
          formula: '=EDATE("not a date", 1)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=WEEKNUM("2024-02-25")',
          formula: '=WEEKNUM("2024-02-25")',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=WEEKNUM("2024-02-25", 2)',
          formula: '=WEEKNUM("2024-02-25", 2)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=ISOWEEKNUM("2024-02-25")',
          formula: '=ISOWEEKNUM("2024-02-25")',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=NETWORKDAYS("2024-01-01", "2024-01-10", A5:A5)',
          formula: '=NETWORKDAYS("2024-01-01", "2024-01-10", A5:A5)',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(value: '2024-01-03'),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=WORKDAY("2024-01-01", 5, A5:A5)',
          formula: '=WORKDAY("2024-01-01", 5, A5:A5)',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=WORKDAY("2024-01-08", -3)',
          formula: '=WORKDAY("2024-01-08", -3)',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", 11)',
          formula: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", 11)',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "0000011")',
          formula: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "0000011")',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=WORKDAY.INTL("2024-01-01", 5, 11)',
          formula: '=WORKDAY.INTL("2024-01-01", 5, 11)',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=WORKDAY.INTL("2024-01-01", 5, "0000011")',
          formula: '=WORKDAY.INTL("2024-01-01", 5, "0000011")',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "1111111")',
          formula: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "1111111")',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01")',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01")',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01", 1)',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01", 1)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01", 2)',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01", 2)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01", 3)',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01", 3)',
        ),
        const FortuneCellCoord(6, 0): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01", 4)',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01", 4)',
        ),
        const FortuneCellCoord(6, 1): const FortuneCell(
          value: '=YEARFRAC("2024-01-01", "2024-07-01", 9)',
          formula: '=YEARFRAC("2024-01-01", "2024-07-01", 9)',
        ),
        const FortuneCellCoord(6, 2): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "Y")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "Y")',
        ),
        const FortuneCellCoord(6, 3): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "M")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "M")',
        ),
        const FortuneCellCoord(6, 4): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "D")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "D")',
        ),
        const FortuneCellCoord(6, 5): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "YM")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "YM")',
        ),
        const FortuneCellCoord(7, 0): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "MD")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "MD")',
        ),
        const FortuneCellCoord(7, 1): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "YD")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "YD")',
        ),
        const FortuneCellCoord(7, 2): const FortuneCell(
          value: '=DATEDIF("2024-03-10", "2020-01-15", "D")',
          formula: '=DATEDIF("2024-03-10", "2020-01-15", "D")',
        ),
        const FortuneCellCoord(7, 3): const FortuneCell(
          value: '=WEEKDAY("2024-02-25", 99)',
          formula: '=WEEKDAY("2024-02-25", 99)',
        ),
        const FortuneCellCoord(7, 4): const FortuneCell(
          value: '=WEEKNUM("2024-02-25", 99)',
          formula: '=WEEKNUM("2024-02-25", 99)',
        ),
        const FortuneCellCoord(7, 5): const FortuneCell(
          value: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", 99)',
          formula: '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", 99)',
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          value: '=WORKDAY.INTL("2024-01-01", 5, 99)',
          formula: '=WORKDAY.INTL("2024-01-01", 5, 99)',
        ),
        const FortuneCellCoord(8, 1): const FortuneCell(
          value: '=DATEDIF("2020-01-15", "2024-03-10", "Q")',
          formula: '=DATEDIF("2020-01-15", "2024-03-10", "Q")',
        ),
        const FortuneCellCoord(8, 2): const FortuneCell(
          value: '=NETWORKDAYS_INTL("2024-01-01", "2024-01-07", 11)',
          formula: '=NETWORKDAYS_INTL("2024-01-01", "2024-01-07", 11)',
        ),
        const FortuneCellCoord(8, 3): const FortuneCell(
          value: '=WORKDAY_INTL("2024-01-01", 5, 11)',
          formula: '=WORKDAY_INTL("2024-01-01", 5, 11)',
        ),
        const FortuneCellCoord(8, 4): const FortuneCell(
          value: '=DATEVALUE("1/1/2000")',
          formula: '=DATEVALUE("1/1/2000")',
        ),
        const FortuneCellCoord(8, 5): const FortuneCell(
          value: '=MONTH("2/1/1901")',
          formula: '=MONTH("2/1/1901")',
        ),
        const FortuneCellCoord(8, 6): const FortuneCell(
          value: '=DAY(1)',
          formula: '=DAY(1)',
        ),
        const FortuneCellCoord(8, 7): const FortuneCell(
          value: '=DATEVALUE("1/1/1900")',
          formula: '=DATEVALUE("1/1/1900")',
        ),
        const FortuneCellCoord(8, 8): const FortuneCell(
          value: '=EDATE("1/1/1900", 1)',
          formula: '=EDATE("1/1/1900", 1)',
        ),
        const FortuneCellCoord(8, 9): const FortuneCell(
          value: '=EOMONTH("1/1/1900", 1)',
          formula: '=EOMONTH("1/1/1900", 1)',
        ),
        const FortuneCellCoord(8, 10): const FortuneCell(
          value: '=NETWORKDAYS("2013-12-04", "2013-12-05")',
          formula: '=NETWORKDAYS("2013-12-04", "2013-12-05")',
        ),
        const FortuneCellCoord(8, 11): const FortuneCell(
          value: '=NETWORKDAYS("2013-11-04", "2013-12-05")',
          formula: '=NETWORKDAYS("2013-11-04", "2013-12-05")',
        ),
        const FortuneCellCoord(8, 12): const FortuneCell(
          value: '=WEEKDAY("1/1/1901")',
          formula: '=WEEKDAY("1/1/1901")',
        ),
        const FortuneCellCoord(8, 13): const FortuneCell(
          value: '=WEEKDAY("1/1/1901", 2)',
          formula: '=WEEKDAY("1/1/1901", 2)',
        ),
        const FortuneCellCoord(8, 14): const FortuneCell(
          value: '=WEEKNUM("2/1/1900")',
          formula: '=WEEKNUM("2/1/1900")',
        ),
        const FortuneCellCoord(8, 15): const FortuneCell(
          value: '=WEEKNUM("2/1/1909", 2)',
          formula: '=WEEKNUM("2/1/1909", 2)',
        ),
        const FortuneCellCoord(8, 16): const FortuneCell(
          value: '=WORKDAY("1/1/1900", 1)',
          formula: '=WORKDAY("1/1/1900", 1)',
        ),
        const FortuneCellCoord(8, 17): const FortuneCell(
          value: '=YEARFRAC("1/1/1900", "1/2/1900")',
          formula: '=YEARFRAC("1/1/1900", "1/2/1900")',
        ),
        const FortuneCellCoord(9, 0): const FortuneCell(
          value: '=DATE()',
          formula: '=DATE()',
        ),
        const FortuneCellCoord(9, 1): const FortuneCell(
          value: '=DATEVALUE()',
          formula: '=DATEVALUE()',
        ),
        const FortuneCellCoord(9, 2): const FortuneCell(
          value: '=DAY()',
          formula: '=DAY()',
        ),
        const FortuneCellCoord(9, 3): const FortuneCell(
          value: '=DAYS()',
          formula: '=DAYS()',
        ),
        const FortuneCellCoord(9, 4): const FortuneCell(
          value: '=DAYS(1)',
          formula: '=DAYS(1)',
        ),
        const FortuneCellCoord(9, 5): const FortuneCell(
          value: '=DAYS360()',
          formula: '=DAYS360()',
        ),
        const FortuneCellCoord(9, 6): const FortuneCell(
          value: '=DAYS360(1)',
          formula: '=DAYS360(1)',
        ),
        const FortuneCellCoord(9, 7): const FortuneCell(
          value: '=DAYS360(1, 6)',
          formula: '=DAYS360(1, 6)',
        ),
        const FortuneCellCoord(10, 0): const FortuneCell(
          value: '=EDATE()',
          formula: '=EDATE()',
        ),
        const FortuneCellCoord(10, 1): const FortuneCell(
          value: '=EDATE(1)',
          formula: '=EDATE(1)',
        ),
        const FortuneCellCoord(10, 2): const FortuneCell(
          value: '=EOMONTH()',
          formula: '=EOMONTH()',
        ),
        const FortuneCellCoord(10, 3): const FortuneCell(
          value: '=EOMONTH(1)',
          formula: '=EOMONTH(1)',
        ),
        const FortuneCellCoord(10, 4): const FortuneCell(
          value: '=ISOWEEKNUM()',
          formula: '=ISOWEEKNUM()',
        ),
        const FortuneCellCoord(10, 5): const FortuneCell(
          value: '=MONTH()',
          formula: '=MONTH()',
        ),
        const FortuneCellCoord(10, 6): const FortuneCell(
          value: '=NETWORKDAYS()',
          formula: '=NETWORKDAYS()',
        ),
        const FortuneCellCoord(10, 7): const FortuneCell(
          value: '=NETWORKDAYS("2/1/1901")',
          formula: '=NETWORKDAYS("2/1/1901")',
        ),
        const FortuneCellCoord(11, 0): const FortuneCell(
          value: '=WEEKDAY()',
          formula: '=WEEKDAY()',
        ),
        const FortuneCellCoord(11, 1): const FortuneCell(
          value: '=WEEKNUM()',
          formula: '=WEEKNUM()',
        ),
        const FortuneCellCoord(11, 2): const FortuneCell(
          value: '=WORKDAY()',
          formula: '=WORKDAY()',
        ),
        const FortuneCellCoord(11, 3): const FortuneCell(
          value: '=WORKDAY("1/1/1900")',
          formula: '=WORKDAY("1/1/1900")',
        ),
        const FortuneCellCoord(11, 4): const FortuneCell(
          value: '=YEAR()',
          formula: '=YEAR()',
        ),
        const FortuneCellCoord(11, 5): const FortuneCell(
          value: '=YEARFRAC()',
          formula: '=YEARFRAC()',
        ),
        const FortuneCellCoord(11, 6): const FortuneCell(
          value: '=YEARFRAC("1/1/1904")',
          formula: '=YEARFRAC("1/1/1904")',
        ),
        const FortuneCellCoord(12, 0): const FortuneCell(
          value: '=ISOWEEKNUM("1/8/1901")',
          formula: '=ISOWEEKNUM("1/8/1901")',
        ),
        const FortuneCellCoord(12, 1): const FortuneCell(
          value: '=ISOWEEKNUM("6/6/1902")',
          formula: '=ISOWEEKNUM("6/6/1902")',
        ),
        const FortuneCellCoord(12, 2): const FortuneCell(
          value: '=MONTH("10/1/1901")',
          formula: '=MONTH("10/1/1901")',
        ),
        const FortuneCellCoord(12, 3): const FortuneCell(
          value: '=DATE(2001, 5, 12)',
          formula: '=DATE(2001, 5, 12)',
        ),
        const FortuneCellCoord(12, 4): const FortuneCell(
          value: '=DAY(2958465)',
          formula: '=DAY(2958465)',
        ),
        const FortuneCellCoord(12, 5): const FortuneCell(
          value: '=DAY("2958465")',
          formula: '=DAY("2958465")',
        ),
        const FortuneCellCoord(12, 6): const FortuneCell(
          value: '=DAYS(1, 6)',
          formula: '=DAYS(1, 6)',
        ),
        const FortuneCellCoord(12, 7): const FortuneCell(
          value: '=DAYS("1/2/2000", "1/10/2001")',
          formula: '=DAYS("1/2/2000", "1/10/2001")',
        ),
        const FortuneCellCoord(12, 8): const FortuneCell(
          value: '=DAYS360("1/1/1901", "2/1/1901", TRUE)',
          formula: '=DAYS360("1/1/1901", "2/1/1901", TRUE)',
        ),
        const FortuneCellCoord(12, 9): const FortuneCell(
          value: '=DAYS360("1/1/1901", "12/31/1901", FALSE)',
          formula: '=DAYS360("1/1/1901", "12/31/1901", FALSE)',
        ),
        const FortuneCellCoord(12, 10): const FortuneCell(
          value: '=YEAR("1/1/1904")',
          formula: '=YEAR("1/1/1904")',
        ),
        const FortuneCellCoord(12, 11): const FortuneCell(
          value: '=YEAR("12/12/2001")',
          formula: '=YEAR("12/12/2001")',
        ),
        const FortuneCellCoord(12, 12): const FortuneCell(
          value: '=NETWORKDAYS("2013-12-05", "2013-12-04")',
          formula: '=NETWORKDAYS("2013-12-05", "2013-12-04")',
        ),
        const FortuneCellCoord(12, 13): const FortuneCell(
          value: '=WORKDAY.INTL("2024-01-08", -3, 11)',
          formula: '=WORKDAY.INTL("2024-01-08", -3, 11)',
        ),
        const FortuneCellCoord(12, 14): const FortuneCell(
          value: '=NETWORKDAYS.INTL("2024-01-07", "2024-01-01", "0000011")',
          formula: '=NETWORKDAYS.INTL("2024-01-07", "2024-01-01", "0000011")',
        ),
        const FortuneCellCoord(12, 15): const FortuneCell(
          value:
              '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "0000011", A5:A5)',
          formula:
              '=NETWORKDAYS.INTL("2024-01-01", "2024-01-07", "0000011", A5:A5)',
        ),
        const FortuneCellCoord(12, 16): const FortuneCell(
          value: '=WORKDAY.INTL("2024-01-01", 5, "0000011", A5:A5)',
          formula: '=WORKDAY.INTL("2024-01-01", 5, "0000011", A5:A5)',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '2024');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '29');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '45689');
    expect(
      sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText,
      expectedTodaySerial.toString(),
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      today.year.toString(),
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      today.month.toString(),
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText,
      today.day.toString(),
    );
    expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '45351');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '28');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '29');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '8');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '7');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '45300');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '45294');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '45297');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '45299');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '0.5');
    expect(
      sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText,
      '0.497267759563',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText,
      '0.505555555556',
    );
    expect(
      sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText,
      '0.498630136986',
    );
    expect(sheet.cells[const FortuneCellCoord(6, 0)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(6, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(6, 2)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(6, 3)]?.renderedText, '49');
    expect(sheet.cells[const FortuneCellCoord(6, 4)]?.renderedText, '1516');
    expect(sheet.cells[const FortuneCellCoord(6, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(7, 0)]?.renderedText, '24');
    expect(sheet.cells[const FortuneCellCoord(7, 1)]?.renderedText, '55');
    expect(sheet.cells[const FortuneCellCoord(7, 2)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 3)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 4)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(7, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(8, 2)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(8, 3)]?.renderedText, '45297');
    expect(sheet.cells[const FortuneCellCoord(8, 4)]?.renderedText, '36526');
    expect(sheet.cells[const FortuneCellCoord(8, 5)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(8, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(8, 7)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(8, 8)]?.renderedText, '32');
    expect(sheet.cells[const FortuneCellCoord(8, 9)]?.renderedText, '59');
    expect(sheet.cells[const FortuneCellCoord(8, 10)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(8, 11)]?.renderedText, '24');
    expect(sheet.cells[const FortuneCellCoord(8, 12)]?.renderedText, '3');
    expect(sheet.cells[const FortuneCellCoord(8, 13)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(8, 14)]?.renderedText, '5');
    expect(sheet.cells[const FortuneCellCoord(8, 15)]?.renderedText, '6');
    expect(sheet.cells[const FortuneCellCoord(8, 16)]?.renderedText, '2');
    expect(
      sheet.cells[const FortuneCellCoord(8, 17)]?.renderedText,
      '0.002777777778',
    );
    expect(sheet.cells[const FortuneCellCoord(9, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(9, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(10, 7)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(11, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(12, 0)]?.renderedText, '2');
    expect(sheet.cells[const FortuneCellCoord(12, 1)]?.renderedText, '23');
    expect(sheet.cells[const FortuneCellCoord(12, 2)]?.renderedText, '10');
    expect(sheet.cells[const FortuneCellCoord(12, 3)]?.renderedText, '37023');
    expect(sheet.cells[const FortuneCellCoord(12, 4)]?.renderedText, '31');
    expect(sheet.cells[const FortuneCellCoord(12, 5)]?.renderedText, '31');
    expect(sheet.cells[const FortuneCellCoord(12, 6)]?.renderedText, '-5');
    expect(sheet.cells[const FortuneCellCoord(12, 7)]?.renderedText, '-374');
    expect(sheet.cells[const FortuneCellCoord(12, 8)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(12, 9)]?.renderedText, '360');
    expect(sheet.cells[const FortuneCellCoord(12, 10)]?.renderedText, '1904');
    expect(sheet.cells[const FortuneCellCoord(12, 11)]?.renderedText, '2001');
    expect(sheet.cells[const FortuneCellCoord(12, 12)]?.renderedText, '-2');
    expect(sheet.cells[const FortuneCellCoord(12, 13)]?.renderedText, '45295');
    expect(sheet.cells[const FortuneCellCoord(12, 14)]?.renderedText, '-5');
    expect(sheet.cells[const FortuneCellCoord(12, 15)]?.renderedText, '4');
    expect(sheet.cells[const FortuneCellCoord(12, 16)]?.renderedText, '45300');
  });

  test('formula engine evaluates basic time helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=TIME(12, 0, 0)',
          formula: '=TIME(12, 0, 0)',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=HOUR(TIME(25, 30, 75))',
          formula: '=HOUR(TIME(25, 30, 75))',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: '=MINUTE("13:45:30")',
          formula: '=MINUTE("13:45:30")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=SECOND("2024-02-29T13:45:30")',
          formula: '=SECOND("2024-02-29T13:45:30")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=HOUR(DATE(2024, 2, 29)+TIME(6, 15, 0))',
          formula: '=HOUR(DATE(2024, 2, 29)+TIME(6, 15, 0))',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=NOW()-TODAY()',
          formula: '=NOW()-TODAY()',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=TIMEVALUE("06:15:30")',
          formula: '=TIMEVALUE("06:15:30")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=TIMEVALUE("2024-02-29T06:15:30")',
          formula: '=TIMEVALUE("2024-02-29T06:15:30")',
        ),
        const FortuneCellCoord(1, 6): const FortuneCell(
          value: '=TIMEVALUE("2024-02-29 06:15:30")',
          formula: '=TIMEVALUE("2024-02-29 06:15:30")',
        ),
        const FortuneCellCoord(1, 7): const FortuneCell(
          value: '=TIMEVALUE("2024/2/29 06:15:30")',
          formula: '=TIMEVALUE("2024/2/29 06:15:30")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=TIMEVALUE("25:00")',
          formula: '=TIMEVALUE("25:00")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=TIMEVALUE("1:05 PM")',
          formula: '=TIMEVALUE("1:05 PM")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=HOUR("12:00 AM")',
          formula: '=HOUR("12:00 AM")',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=HOUR("12:00 PM")',
          formula: '=HOUR("12:00 PM")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=SECOND("2024-02-29 7:08:09 p.m.")',
          formula: '=SECOND("2024-02-29 7:08:09 p.m.")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=TIMEVALUE("13:00 PM")',
          formula: '=TIMEVALUE("13:00 PM")',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=TIMEVALUE("06:15:30.500")',
          formula: '=TIMEVALUE("06:15:30.500")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=TIMEVALUE("2024-02-29T06:15:30.250")',
          formula: '=TIMEVALUE("2024-02-29T06:15:30.250")',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=SECOND("7:08:09.750 PM")',
          formula: '=SECOND("7:08:09.750 PM")',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=TIME(-1, 0, 0)',
          formula: '=TIME(-1, 0, 0)',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=TIME(1, -1, 0)',
          formula: '=TIME(1, -1, 0)',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=TIME(1, 0, -1)',
          formula: '=TIME(1, 0, -1)',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=HOUR("1/1/1900 16:33")',
          formula: '=HOUR("1/1/1900 16:33")',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=TIME(24, 0, 0)',
          formula: '=TIME(24, 0, 0)',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=TIME(1, 1, 1)',
          formula: '=TIME(1, 1, 1)',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=TIMEVALUE("1/1/1900 00:00:00")',
          formula: '=TIMEVALUE("1/1/1900 00:00:00")',
        ),
        const FortuneCellCoord(3, 6): const FortuneCell(
          value: '=TIMEVALUE("1/1/1900 23:00:00")',
          formula: '=TIMEVALUE("1/1/1900 23:00:00")',
        ),
        const FortuneCellCoord(4, 0): const FortuneCell(
          value: '=HOUR()',
          formula: '=HOUR()',
        ),
        const FortuneCellCoord(4, 1): const FortuneCell(
          value: '=MINUTE()',
          formula: '=MINUTE()',
        ),
        const FortuneCellCoord(4, 2): const FortuneCell(
          value: '=SECOND()',
          formula: '=SECOND()',
        ),
        const FortuneCellCoord(4, 3): const FortuneCell(
          value: '=TIME()',
          formula: '=TIME()',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          value: '=TIME(0)',
          formula: '=TIME(0)',
        ),
        const FortuneCellCoord(4, 5): const FortuneCell(
          value: '=TIME(0, 0)',
          formula: '=TIME(0, 0)',
        ),
        const FortuneCellCoord(4, 6): const FortuneCell(
          value: '=TIMEVALUE()',
          formula: '=TIMEVALUE()',
        ),
        const FortuneCellCoord(5, 0): const FortuneCell(
          value: '=MINUTE("1/1/1901 1:01")',
          formula: '=MINUTE("1/1/1901 1:01")',
        ),
        const FortuneCellCoord(5, 1): const FortuneCell(
          value: '=MINUTE("1/1/1901 15:36")',
          formula: '=MINUTE("1/1/1901 15:36")',
        ),
        const FortuneCellCoord(5, 2): const FortuneCell(
          value: '=SECOND("2/1/1901 13:33:12")',
          formula: '=SECOND("2/1/1901 13:33:12")',
        ),
        const FortuneCellCoord(5, 3): const FortuneCell(
          value: '=TIME(0, 0, 0)',
          formula: '=TIME(0, 0, 0)',
        ),
        const FortuneCellCoord(5, 4): const FortuneCell(
          value: '=HOUR(0.75)',
          formula: '=HOUR(0.75)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          value: '=MINUTE(12/24+1/1440)',
          formula: '=MINUTE(12/24+1/1440)',
        ),
        const FortuneCellCoord(5, 6): const FortuneCell(
          value: '=SECOND(12/24+1/86400)',
          formula: '=SECOND(12/24+1/86400)',
        ),
        const FortuneCellCoord(5, 7): const FortuneCell(
          value: '=TIMEVALUE("1:05 A.M.")=TIME(1,5,0)',
          formula: '=TIMEVALUE("1:05 A.M.")=TIME(1,5,0)',
        ),
        const FortuneCellCoord(5, 8): const FortuneCell(
          value: '=TIMEVALUE("06:15:30.5")=TIMEVALUE("06:15:30.500")',
          formula: '=TIMEVALUE("06:15:30.5")=TIMEVALUE("06:15:30.500")',
        ),
        const FortuneCellCoord(5, 9): const FortuneCell(
          value: '=TIMEVALUE("06:15:30.05")=TIMEVALUE("06:15:30.050")',
          formula: '=TIMEVALUE("06:15:30.05")=TIMEVALUE("06:15:30.050")',
        ),
        const FortuneCellCoord(5, 10): const FortuneCell(
          value: '=TIMEVALUE("12:60 AM")',
          formula: '=TIMEVALUE("12:60 AM")',
        ),
        const FortuneCellCoord(5, 11): const FortuneCell(
          value: '=TIMEVALUE("12:30:60 AM")',
          formula: '=TIMEVALUE("12:30:60 AM")',
        ),
        const FortuneCellCoord(5, 12): const FortuneCell(
          value: '=TIMEVALUE(" 1:05 PM ")=TIMEVALUE("1:05 PM")',
          formula: '=TIMEVALUE(" 1:05 PM ")=TIMEVALUE("1:05 PM")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '0.5');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '45');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText, '30');
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '6');
    final nowFraction = double.parse(
      sheet.cells[const FortuneCellCoord(0, 5)]!.renderedText,
    );
    expect(nowFraction, inInclusiveRange(0, 1));
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '0.260763888889',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
      '0.260763888889',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText,
      '0.260763888889',
    );
    expect(
      sheet.cells[const FortuneCellCoord(1, 7)]?.renderedText,
      '0.260763888889',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText,
      '0.545138888889',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText,
      '0.260769675926',
    );
    expect(
      sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText,
      '0.260766782407',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '9');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '#NUM!');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '16');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '1');
    expect(
      sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText,
      '0.042372685185',
    );
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '0');
    expect(
      sheet.cells[const FortuneCellCoord(3, 6)]?.renderedText,
      '0.958333333333',
    );
    expect(sheet.cells[const FortuneCellCoord(4, 0)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 1)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 2)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 3)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 4)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 5)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(4, 6)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 0)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 1)]?.renderedText, '36');
    expect(sheet.cells[const FortuneCellCoord(5, 2)]?.renderedText, '12');
    expect(sheet.cells[const FortuneCellCoord(5, 3)]?.renderedText, '0');
    expect(sheet.cells[const FortuneCellCoord(5, 4)]?.renderedText, '18');
    expect(sheet.cells[const FortuneCellCoord(5, 5)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 6)]?.renderedText, '1');
    expect(sheet.cells[const FortuneCellCoord(5, 7)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(5, 8)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(5, 9)]?.renderedText, 'TRUE');
    expect(sheet.cells[const FortuneCellCoord(5, 10)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 11)]?.renderedText, '#VALUE!');
    expect(sheet.cells[const FortuneCellCoord(5, 12)]?.renderedText, 'TRUE');
  });

  test('formula engine evaluates basic TEXT formats', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '=TEXT(1234.567, "#,##0.00")',
          formula: '=TEXT(1234.567, "#,##0.00")',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          value: '=TEXT(0.256, "0.0%")',
          formula: '=TEXT(0.256, "0.0%")',
        ),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: r'=TEXT(1234.5, "$#,##0.00")',
          formula: r'=TEXT(1234.5, "$#,##0.00")',
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          value: '=TEXT(DATE(2024, 2, 9), "yyyy-mm-dd")',
          formula: '=TEXT(DATE(2024, 2, 9), "yyyy-mm-dd")',
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '=TEXT(TIME(6, 7, 8), "HH:MM:SS")',
          formula: '=TEXT(TIME(6, 7, 8), "HH:MM:SS")',
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '=TEXT("not numeric", "0.00")',
          formula: '=TEXT("not numeric", "0.00")',
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: '=TEXT(DATE(2024, 2, 9)+TIME(6, 7, 8), "yyyy-mm-dd hh:mm:ss")',
          formula:
              '=TEXT(DATE(2024, 2, 9)+TIME(6, 7, 8), "yyyy-mm-dd hh:mm:ss")',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: '=TEXT(TIME(13, 5, 0), "h:mm AM/PM")',
          formula: '=TEXT(TIME(13, 5, 0), "h:mm AM/PM")',
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          value: '=TEXT(TIME(0, 5, 0), "hh:mm A/P")',
          formula: '=TEXT(TIME(0, 5, 0), "hh:mm A/P")',
        ),
        const FortuneCellCoord(1, 3): const FortuneCell(
          value: '=TEXT(-1234.5, "#,##0.0;(#,##0.0);zero")',
          formula: '=TEXT(-1234.5, "#,##0.0;(#,##0.0);zero")',
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          value: '=TEXT(0, "#,##0.0;(#,##0.0);zero")',
          formula: '=TEXT(0, "#,##0.0;(#,##0.0);zero")',
        ),
        const FortuneCellCoord(1, 5): const FortuneCell(
          value: '=TEXT(12.3, """score ""0.0")',
          formula: '=TEXT(12.3, """score ""0.0")',
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: '=TEXT(-12.3, "0.0;[Red]-0.0")',
          formula: '=TEXT(-12.3, "0.0;[Red]-0.0")',
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: '=TEXT(1500, "[>=1000]big;[<1000]low;zero")',
          formula: '=TEXT(1500, "[>=1000]big;[<1000]low;zero")',
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: '=TEXT(42, "[>=1000]big;[<1000]low;zero")',
          formula: '=TEXT(42, "[>=1000]big;[<1000]low;zero")',
        ),
        const FortuneCellCoord(2, 3): const FortuneCell(
          value: '=TEXT(1.125, "[h]:mm:ss")',
          formula: '=TEXT(1.125, "[h]:mm:ss")',
        ),
        const FortuneCellCoord(2, 4): const FortuneCell(
          value: '=TEXT(1.125, "[m]")',
          formula: '=TEXT(1.125, "[m]")',
        ),
        const FortuneCellCoord(2, 5): const FortuneCell(
          value: '=TEXT(1.125, "[s]")',
          formula: '=TEXT(1.125, "[s]")',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          value: '=TEXT(1.2, "0.##")',
          formula: '=TEXT(1.2, "0.##")',
        ),
        const FortuneCellCoord(3, 1): const FortuneCell(
          value: '=TEXT(1, "0.0#")',
          formula: '=TEXT(1, "0.0#")',
        ),
        const FortuneCellCoord(3, 2): const FortuneCell(
          value: '=TEXT(1.25, "0.0#")',
          formula: '=TEXT(1.25, "0.0#")',
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          value: '=TEXT(0, "#")',
          formula: '=TEXT(0, "#")',
        ),
        const FortuneCellCoord(3, 4): const FortuneCell(
          value: '=TEXT(0.5, "#.##")',
          formula: '=TEXT(0.5, "#.##")',
        ),
        const FortuneCellCoord(3, 5): const FortuneCell(
          value: '=TEXT(-0.5, "#.##")',
          formula: '=TEXT(-0.5, "#.##")',
        ),
      },
    );

    FortuneFormulaEngine.recalculate(sheet);

    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '1,234.57');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '25.6%');
    expect(
      sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText,
      r'$1,234.50',
    );
    expect(
      sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
      '2024-02-09',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText, '06:07:08');
    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText, '#VALUE!');
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
      '2024-02-09 06:07:08',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '1:05 PM');
    expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '12:05 A');
    expect(
      sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText,
      '(1,234.5)',
    );
    expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, 'zero');
    expect(
      sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText,
      'score 12.3',
    );
    expect(sheet.cells[const FortuneCellCoord(2, 0)]?.renderedText, '-12.3');
    expect(sheet.cells[const FortuneCellCoord(2, 1)]?.renderedText, 'big');
    expect(sheet.cells[const FortuneCellCoord(2, 2)]?.renderedText, 'low');
    expect(sheet.cells[const FortuneCellCoord(2, 3)]?.renderedText, '27:00:00');
    expect(sheet.cells[const FortuneCellCoord(2, 4)]?.renderedText, '1620');
    expect(sheet.cells[const FortuneCellCoord(2, 5)]?.renderedText, '97200');
    expect(sheet.cells[const FortuneCellCoord(3, 0)]?.renderedText, '1.2');
    expect(sheet.cells[const FortuneCellCoord(3, 1)]?.renderedText, '1.0');
    expect(sheet.cells[const FortuneCellCoord(3, 2)]?.renderedText, '1.25');
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.renderedText, '');
    expect(sheet.cells[const FortuneCellCoord(3, 4)]?.renderedText, '.5');
    expect(sheet.cells[const FortuneCellCoord(3, 5)]?.renderedText, '-.5');
  });

  test(
    'formula engine reports unsupported and circular formulas as errors',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(
            value: '=A1',
            formula: '=A1',
          ),
          const FortuneCellCoord(0, 1): const FortuneCell(
            value: '=UNKNOWN(1)',
            formula: '=UNKNOWN(1)',
          ),
          const FortuneCellCoord(0, 2): const FortuneCell(
            value: '=missing_name+1',
            formula: '=missing_name+1',
          ),
          const FortuneCellCoord(0, 3): const FortuneCell(
            value: '=IFERROR(UNKNOWN(1), "bad name")',
            formula: '=IFERROR(UNKNOWN(1), "bad name")',
          ),
          const FortuneCellCoord(0, 4): const FortuneCell(
            value: '="unterminated',
            formula: '="unterminated',
          ),
          const FortuneCellCoord(0, 5): const FortuneCell(
            value: '=SUM({1,2;3',
            formula: '=SUM({1,2;3',
          ),
          const FortuneCellCoord(1, 0): const FortuneCell(
            value: '=#DIV/0!',
            formula: '=#DIV/0!',
          ),
          const FortuneCellCoord(1, 1): const FortuneCell(
            value: '=#N/A',
            formula: '=#N/A',
          ),
          const FortuneCellCoord(1, 2): const FortuneCell(
            value: '=#NULL!',
            formula: '=#NULL!',
          ),
          const FortuneCellCoord(1, 3): const FortuneCell(
            value: '=#NUM!',
            formula: '=#NUM!',
          ),
          const FortuneCellCoord(1, 4): const FortuneCell(
            value: '=#REF!',
            formula: '=#REF!',
          ),
          const FortuneCellCoord(1, 5): const FortuneCell(
            value: '=#VALUE!',
            formula: '=#VALUE!',
          ),
          const FortuneCellCoord(1, 6): const FortuneCell(
            value: '=#DIV/0?',
            formula: '=#DIV/0?',
          ),
        },
      );

      FortuneFormulaEngine.recalculate(sheet);

      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText,
        '#VALUE!',
      );
      expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '#NAME?');
      expect(sheet.cells[const FortuneCellCoord(0, 2)]?.renderedText, '#NAME?');
      expect(
        sheet.cells[const FortuneCellCoord(0, 3)]?.renderedText,
        'bad name',
      );
      expect(
        sheet.cells[const FortuneCellCoord(0, 4)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(0, 5)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(1, 0)]?.renderedText,
        '#DIV/0!',
      );
      expect(sheet.cells[const FortuneCellCoord(1, 1)]?.renderedText, '#N/A');
      expect(sheet.cells[const FortuneCellCoord(1, 2)]?.renderedText, '#NULL!');
      expect(sheet.cells[const FortuneCellCoord(1, 3)]?.renderedText, '#NUM!');
      expect(sheet.cells[const FortuneCellCoord(1, 4)]?.renderedText, '#REF!');
      expect(
        sheet.cells[const FortuneCellCoord(1, 5)]?.renderedText,
        '#VALUE!',
      );
      expect(
        sheet.cells[const FortuneCellCoord(1, 6)]?.renderedText,
        '#ERROR!',
      );
    },
  );

  test('formula engine parses formula error literals', () {
    final formulas = <String, String>{
      '#ERROR!': '#ERROR!',
      '#DIV/0!': '#DIV/0!',
      '#NAME?': '#NAME?',
      '#N/A': '#N/A',
      '#NULL!': '#NULL!',
      '#NUM!': '#NUM!',
      '#REF!': '#REF!',
      '#VALUE!': '#VALUE!',
      ' #ERRfefweOR! ': '#ERROR!',
      '#DIV/0?': '#ERROR!',
      '#DIV/1!': '#ERROR!',
      '#DIV/': '#ERROR!',
      '#NAME!': '#ERROR!',
      '#NAMe!': '#ERROR!',
      '#N/A!': '#ERROR!',
      '#N/A?': '#ERROR!',
      '#NA': '#ERROR!',
      '#NULL?': '#ERROR!',
      '#NULl!': '#ERROR!',
      '#NUM?': '#ERROR!',
      '#NuM!': '#ERROR!',
      '#REF?': '#ERROR!',
      '#REf!': '#ERROR!',
      '#VALUE?': '#ERROR!',
      '#VALUe!': '#ERROR!',
    };
    final cells = <FortuneCellCoord, FortuneCell>{};
    var column = 0;
    for (final formula in formulas.keys) {
      cells[FortuneCellCoord(0, column)] = FortuneCell(
        value: '=$formula',
        formula: '=$formula',
      );
      column += 1;
    }
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1', cells: cells);

    FortuneFormulaEngine.recalculate(sheet);

    column = 0;
    for (final expected in formulas.values) {
      expect(sheet.cells[FortuneCellCoord(0, column)]?.renderedText, expected);
      column += 1;
    }
  });

  test('formula reference translation preserves absolute axes', () {
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=A1+$B1+C$1+$D$1+SUM(A1:B2)',
        rowDelta: 2,
        columnDelta: 1,
      ),
      r'=B3+$B3+D$1+$D$1+SUM(B3:C4)',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=A1+B2',
        rowDelta: -1,
        columnDelta: -1,
      ),
      r'=#REF!+A1',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'''="A1"&A1&"B2:B3"&SUM(A1:B2)&'A1 Sheet'!A1''',
        rowDelta: 1,
        columnDelta: 1,
      ),
      r'''="A1"&B2&"B2:B3"&SUM(B2:C3)&'A1 Sheet'!B2''',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=A1+A1foo+fooA1+A1_2+A1.A2',
        rowDelta: 1,
        columnDelta: 1,
      ),
      r'=B2+A1foo+FOOB2+A1_2+A1.A2',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=Sheet1!A1+SUM(Sheet1!A1:B2)',
        rowDelta: 1,
        columnDelta: 1,
      ),
      r'=Sheet1!B2+SUM(Sheet1!B2:C3)',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=[Book1.xlsx]Sheet1!A1+SUM([Book1.xlsx]Sheet1!A1:B2)',
        rowDelta: 1,
        columnDelta: 1,
      ),
      r'=[Book1.xlsx]Sheet1!B2+SUM([Book1.xlsx]Sheet1!B2:C3)',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r'=[A1]Sheet1!A1+SUM([B2]Sheet1!B2:C3)',
        rowDelta: 2,
        columnDelta: 1,
      ),
      r'=[A1]Sheet1!B3+SUM([B2]Sheet1!C4:D5)',
    );
  });

  test('formula reference translation skips escaped quoted segments', () {
    expect(
      FortuneFormulaEngine.translateReferences(
        r'="A1 ""still text"" B2"&A1',
        rowDelta: 1,
        columnDelta: 1,
      ),
      r'="A1 ""still text"" B2"&B2',
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r"='A1'' Sheet'!A1+[A1.xlsx]Sheet1!A1",
        rowDelta: 1,
        columnDelta: 1,
      ),
      r"='A1'' Sheet'!B2+[A1.xlsx]Sheet1!B2",
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r"='[A1.xlsx]Q1'' Plan'!A1+[B2.xlsx]'C3 Sheet'!B2+SUM('[C4.xlsx]S''1'!C3:D4)",
        rowDelta: 2,
        columnDelta: 1,
      ),
      r"='[A1.xlsx]Q1'' Plan'!B3+[B2.xlsx]'C3 Sheet'!C4+SUM('[C4.xlsx]S''1'!D5:E6)",
    );
    expect(
      FortuneFormulaEngine.translateReferences(
        r"=''!A1+''''!B2+'A1'''!C3",
        rowDelta: 1,
        columnDelta: 1,
      ),
      r"=''!B2+''''!C3+'A1'''!D4",
    );
  });

  test('formula engine evaluates an ad hoc formula without mutating cells', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: '4'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: '6'),
      },
    );

    expect(
      FortuneFormulaEngine.evaluateFormula(sheet, '=SUM(A1:A2)>9'),
      isTrue,
    );
    expect(FortuneFormulaEngine.evaluateFormula(sheet, '=A1&A2'), '46');
  });

  test(
    'formula operator registry evaluates built-ins and custom operators',
    () {
      registerOperation('foo', (params) {
        final left = params[0];
        final right = params[1];
        if (left is num && right is num) {
          return left + right;
        }
        return '$left$right';
      });

      expect(evaluateByOperator('foo', [2, 8.8]), 10.8);
      expect(evaluateByOperator('foo', ['2', '8.8']), '28.8');
      registerOperation(['alias_one', 'alias_two'], (params) => params.length);
      expect(evaluateByOperator('ALIAS_ONE', [1, 2, 3]), 3);
      expect(evaluateByOperator('alias_two', ['x']), 1);
      expect(evaluateByOperator('+', [2, '8.8']), 10.8);
      expect(
        evaluateByOperator('+', ['2', '-8.8', 6, 0.4]),
        -0.4000000000000007,
      );
      expect(() => evaluateByOperator('+', ['foo', 2]), throwsStateError);
      expect(evaluateByOperator('&', [2, 8.8]), '28.8');
      expect(evaluateByOperator('&', ['2', '-8.8', 6, 0.4]), '2-8.860.4');
      expect(
        evaluateByOperator('&', ['foo', ' ', 'bar', ' baz']),
        'foo bar baz',
      );
      expect(evaluateByOperator('/', [2, 8.8]), closeTo(0.2272727272, 1e-10));
      expect(
        evaluateByOperator('/', ['2', '-8.8', 6, 0.4]),
        closeTo(-0.0946969696969697, 1e-15),
      );
      expect(evaluateByOperator('/', [0, 1]), 0);
      expect(evaluateByOperator('/', [1, 0]), ERROR_DIV_ZERO);
      expect(evaluateByOperator('=', [2, '2']), isFalse);
      expect(evaluateByOperator('=', [null, null]), isTrue);
      expect(evaluateByOperator('SUM', [2, 8.8]), 10.8);
      expect(evaluateByOperator('>', [2, 8.8]), isFalse);
      expect(evaluateByOperator('>', [1, '1']), isFalse);
      expect(evaluateByOperator('>', [0, null]), isFalse);
      expect(evaluateByOperator('>=', [2, 2]), isTrue);
      expect(evaluateByOperator('>=', [0, null]), isTrue);
      expect(evaluateByOperator('<', [2, 8.8]), isTrue);
      expect(evaluateByOperator('<', ['2', 8.8]), isTrue);
      expect(evaluateByOperator('<', [0, null]), isFalse);
      expect(evaluateByOperator('<=', [2, 2]), isTrue);
      expect(evaluateByOperator('<=', [0, null]), isTrue);
      expect(evaluateByOperator('-', [2, 8.8]), -6.800000000000001);
      expect(evaluateByOperator('*', [2, 8.8]), 17.6);
      expect(
        evaluateByOperator('*', ['2', '-8.8', 6, 0.4]),
        -42.24000000000001,
      );
      expect(() => evaluateByOperator('*', ['foo', 2]), throwsStateError);
      expect(evaluateByOperator('<>', [2, 8.8]), isTrue);
      expect(evaluateByOperator('<>', [1, '1']), isTrue);
      expect(evaluateByOperator('<>', [null, null]), isFalse);
      expect(evaluateByOperator('^', [2, 2]), 4);
      expect(evaluateByOperator('^', ['2', '8.8', 6, 0.4]), 445.7218884076158);
      expect(() => evaluateByOperator('^', ['foo', 2]), throwsStateError);
      expect(() => evaluateByOperator('bar', [2, 8.8]), throwsStateError);
    },
  );
}
