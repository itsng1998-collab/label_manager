import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream patch replay parity', () {
    final twoSheetWorkbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 'id_1', name: 'Sheet1'),
        FortuneSheet(id: 'id_2', name: 'Sheet2'),
      ],
    );

    test('converts normal patches and ops across sheets', () {
      final ops = [
        {
          'op': 'add',
          'value': 1,
          'id': 'id_1',
          'path': ['data', 1, 1, 'bl'],
        },
        {
          'op': 'add',
          'value': 1,
          'id': 'id_2',
          'path': ['data', 2, 1, 'cl'],
        },
      ];
      final patches = [
        {
          'op': 'add',
          'value': 1,
          'path': ['luckysheetfile', 0, 'data', 1, 1, 'bl'],
        },
        {
          'op': 'add',
          'value': 1,
          'path': ['luckysheetfile', 1, 'data', 2, 1, 'cl'],
        },
      ];

      expect(patchToOp(twoSheetWorkbook, patches), ops);
      final opToPatchResult = opToPatch(twoSheetWorkbook, ops);
      expect(opToPatchResult[0], patches);
      expect(opToPatchResult[1], isEmpty);
    });

    test('locks upstream op docs bold cell example', () {
      final workbook = FortuneWorkbook(
        sheets: [FortuneSheet(id: '0', name: 'Sheet1')],
      );
      final ops = <Map<String, Object?>>[
        {
          'op': 'replace',
          'id': '0',
          'path': ['data', 1, 0, 'bl'],
          'value': 1,
        },
      ];
      final patches = <Map<String, Object?>>[
        {
          'op': 'replace',
          'path': ['luckysheetfile', 0, 'data', 1, 0, 'bl'],
          'value': 1,
        },
      ];

      expect(patchToOp(workbook, patches), ops);
      final opToPatchResult = opToPatch(workbook, ops);
      expect(opToPatchResult[0], patches);
      expect(opToPatchResult[1], isEmpty);

      final applied = applyOp(workbook, ops);
      final boldCell = applied.activeSheet.cells[const FortuneCellCoord(1, 0)];
      expect(boldCell?.rawBold, 1);
      expect(boldCell?.hasRawBold, isTrue);
    });

    test('reduces row and column structural patches to special ops', () {
      final rowInsertOps = patchToOp(
        twoSheetWorkbook,
        [
          {
            'op': 'replace',
            'value': {'bl': 1},
            'path': ['luckysheetfile', 0, 'data', 1, 1],
          },
          {
            'op': 'replace',
            'value': {'cl': 2},
            'path': ['luckysheetfile', 1, 'data', 2, 1],
          },
          {
            'op': 'replace',
            'value': ['1'],
            'path': ['luckysheetfile', 0, 'calcChain'],
          },
        ],
        {
          'insertRowColOp': {
            'type': 'row',
            'index': 2,
            'count': 3,
            'direction': 'lefttop',
            'id': 'id_1',
          },
        },
      );
      expect(rowInsertOps, [
        {
          'op': 'replace',
          'value': ['1'],
          'id': 'id_1',
          'path': ['calcChain'],
        },
        {
          'op': 'insertRowCol',
          'id': 'id_1',
          'path': [],
          'value': {
            'type': 'row',
            'index': 2,
            'count': 3,
            'direction': 'lefttop',
            'id': 'id_1',
          },
        },
      ]);

      final rowInsertFormulaOps = patchToOp(
        twoSheetWorkbook,
        [
          {
            'op': 'replace',
            'value': {'bl': 1},
            'path': ['luckysheetfile', 0, 'data', 1, 1],
          },
          {
            'op': 'replace',
            'value': {'cl': 2},
            'path': ['luckysheetfile', 0, 'data', 2, 1],
          },
          {
            'op': 'replace',
            'value': [
              {'cl': 2},
              null,
              null,
              {'f': 'f1'},
              null,
              {'f': 'f2'},
            ],
            'path': ['luckysheetfile', 0, 'data', 3],
          },
          {
            'op': 'replace',
            'value': ['1'],
            'path': ['luckysheetfile', 0, 'calcChain'],
          },
        ],
        {
          'insertRowColOp': {
            'type': 'row',
            'index': 1,
            'count': 2,
            'direction': 'lefttop',
            'id': 'id_1',
          },
        },
      );
      expect(rowInsertFormulaOps, [
        {
          'op': 'replace',
          'value': ['1'],
          'id': 'id_1',
          'path': ['calcChain'],
        },
        {
          'op': 'insertRowCol',
          'id': 'id_1',
          'path': [],
          'value': {
            'type': 'row',
            'index': 1,
            'count': 2,
            'direction': 'lefttop',
            'id': 'id_1',
          },
        },
        {
          'op': 'replace',
          'value': {'f': 'f1'},
          'id': 'id_1',
          'path': ['data', 3, 3],
        },
        {
          'op': 'replace',
          'value': {'f': 'f2'},
          'id': 'id_1',
          'path': ['data', 3, 5],
        },
      ]);

      final columnDeleteOps = patchToOp(
        twoSheetWorkbook,
        [
          {
            'op': 'replace',
            'value': {'bl': 1},
            'path': ['luckysheetfile', 0, 'data', 1, 1],
          },
          {
            'op': 'replace',
            'value': {'f': 'f1'},
            'path': ['luckysheetfile', 0, 'data', 3, 3],
          },
          {
            'op': 'replace',
            'value': {'f': 'f2'},
            'path': ['luckysheetfile', 0, 'data', 3, 5],
          },
          {
            'op': 'replace',
            'value': ['1'],
            'path': ['luckysheetfile', 0, 'calcChain'],
          },
        ],
        {
          'deleteRowColOp': {
            'type': 'column',
            'start': 2,
            'end': 3,
            'id': 'id_1',
          },
        },
      );
      expect(columnDeleteOps, [
        {
          'op': 'replace',
          'value': ['1'],
          'id': 'id_1',
          'path': ['calcChain'],
        },
        {
          'op': 'deleteRowCol',
          'id': 'id_1',
          'path': [],
          'value': {'type': 'column', 'start': 2, 'end': 3, 'id': 'id_1'},
        },
        {
          'op': 'replace',
          'value': {'f': 'f1'},
          'id': 'id_1',
          'path': ['data', 3, 3],
        },
        {
          'op': 'replace',
          'value': {'f': 'f2'},
          'id': 'id_1',
          'path': ['data', 3, 5],
        },
      ]);

      final opToPatchResult = opToPatch(twoSheetWorkbook, rowInsertOps);
      expect(opToPatchResult[0], [
        {
          'op': 'replace',
          'value': ['1'],
          'path': ['luckysheetfile', 0, 'calcChain'],
        },
      ]);
      expect(opToPatchResult[1], [rowInsertOps[1]]);
    });

    test('restores deleted cells and expands merge header metadata', () {
      final restoreWorkbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'restore-sheet',
            name: 'RestoreSheet',
            cells: {
              const FortuneCellCoord(1, 0): const FortuneCell(value: '10'),
              const FortuneCellCoord(1, 3): const FortuneCell(value: '13'),
              const FortuneCellCoord(2, 1): const FortuneCell(value: '21'),
              const FortuneCellCoord(2, 4): const FortuneCell(value: '24'),
              const FortuneCellCoord(3, 0): const FortuneCell(value: '30'),
            },
          ),
        ],
      );

      expect(
        patchToOp(
          restoreWorkbook,
          [
            {
              'op': 'replace',
              'path': ['luckysheetfile', 0, 'data', 1, 2],
              'value': {'f': '=A1+1'},
            },
            {
              'op': 'replace',
              'path': ['luckysheetfile', 0, 'calcChain'],
              'value': ['1'],
            },
          ],
          {
            'insertRowColOp': {
              'type': 'row',
              'index': 1,
              'count': 2,
              'direction': 'lefttop',
              'id': 'restore-sheet',
            },
            'restoreDeletedCells': true,
          },
        ),
        [
          {
            'op': 'replace',
            'value': ['1'],
            'id': 'restore-sheet',
            'path': ['calcChain'],
          },
          {
            'op': 'insertRowCol',
            'id': 'restore-sheet',
            'path': [],
            'value': {
              'type': 'row',
              'index': 1,
              'count': 2,
              'direction': 'lefttop',
              'id': 'restore-sheet',
            },
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 1, 2],
            'value': {'f': '=A1+1'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 1, 0],
            'value': {'v': '10'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 1, 3],
            'value': {'v': '13'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 2, 1],
            'value': {'v': '21'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 2, 4],
            'value': {'v': '24'},
          },
        ],
      );

      expect(
        patchToOp(
          restoreWorkbook,
          [
            {
              'op': 'replace',
              'path': ['luckysheetfile', 0, 'data', 0, 1],
              'value': {'f': '=A1+1'},
            },
            {
              'op': 'replace',
              'path': ['luckysheetfile', 0, 'calcChain'],
              'value': ['1'],
            },
          ],
          {
            'insertRowColOp': {
              'type': 'column',
              'index': 1,
              'count': 3,
              'direction': 'lefttop',
              'id': 'restore-sheet',
            },
            'restoreDeletedCells': true,
          },
        ),
        [
          {
            'op': 'replace',
            'value': ['1'],
            'id': 'restore-sheet',
            'path': ['calcChain'],
          },
          {
            'op': 'insertRowCol',
            'id': 'restore-sheet',
            'path': [],
            'value': {
              'type': 'column',
              'index': 1,
              'count': 3,
              'direction': 'lefttop',
              'id': 'restore-sheet',
            },
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 0, 1],
            'value': {'f': '=A1+1'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 1, 3],
            'value': {'v': '13'},
          },
          {
            'op': 'replace',
            'id': 'restore-sheet',
            'path': ['data', 2, 1],
            'value': {'v': '21'},
          },
        ],
      );

      expect(
        patchToOp(
          FortuneWorkbook(
            sheets: [FortuneSheet(id: 'merge-sheet', name: 'MergeSheet')],
          ),
          [
            {
              'op': 'replace',
              'path': ['luckysheetfile', 0, 'config', 'merge'],
              'value': {
                '1_2': {'r': 1, 'c': 2, 'rs': 2, 'cs': 2},
              },
            },
          ],
          {
            'deleteRowColOp': {
              'type': 'row',
              'start': 0,
              'end': 0,
              'id': 'merge-sheet',
            },
          },
        ),
        [
          {
            'op': 'replace',
            'value': {
              '1_2': {'r': 1, 'c': 2, 'rs': 2, 'cs': 2},
            },
            'id': 'merge-sheet',
            'path': ['config', 'merge'],
          },
          {
            'op': 'deleteRowCol',
            'id': 'merge-sheet',
            'path': [],
            'value': {'type': 'row', 'start': 0, 'end': 0, 'id': 'merge-sheet'},
          },
          {
            'op': 'replace',
            'id': 'merge-sheet',
            'path': ['data', 1, 2, 'mc'],
            'value': {'r': 1, 'c': 2},
          },
          {
            'op': 'replace',
            'id': 'merge-sheet',
            'path': ['data', 1, 3, 'mc'],
            'value': {'r': 1, 'c': 2},
          },
          {
            'op': 'replace',
            'id': 'merge-sheet',
            'path': ['data', 2, 2, 'mc'],
            'value': {'r': 1, 'c': 2},
          },
          {
            'op': 'replace',
            'id': 'merge-sheet',
            'path': ['data', 2, 3, 'mc'],
            'value': {'r': 1, 'c': 2},
          },
          {
            'op': 'replace',
            'id': 'merge-sheet',
            'path': ['data', 1, 2, 'mc'],
            'value': {'r': 1, 'c': 2, 'rs': 2, 'cs': 2},
          },
        ],
      );
    });

    test('mirrors sheet add and delete undo options', () {
      final addedSheetValue = {
        'id': 'added-sheet',
        'name': 'AddedSheet',
        'order': 1,
      };
      final orderedWorkbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(id: 'left-sheet', name: 'Left', order: 0),
          FortuneSheet(id: 'added-sheet', name: 'AddedSheet', order: 1),
          FortuneSheet(id: 'right-sheet', name: 'Right', order: 2),
        ],
      );

      expect(
        patchToOp(
          orderedWorkbook,
          [
            {
              'op': 'add',
              'path': ['luckysheetfile', 1],
              'value': addedSheetValue,
            },
          ],
          {
            'addSheetOp': true,
            'addSheet': {'id': 'added-sheet', 'value': addedSheetValue},
          },
          true,
        ),
        [
          {
            'op': 'deleteSheet',
            'id': 'added-sheet',
            'path': [],
            'value': {'id': 'added-sheet', 'value': addedSheetValue},
          },
          {
            'op': 'replace',
            'id': 'added-sheet',
            'path': ['order'],
            'value': 0,
          },
          {
            'op': 'replace',
            'id': 'right-sheet',
            'path': ['order'],
            'value': 1,
          },
        ],
      );

      final deletedSheetValue = {
        'id': 'deleted-sheet',
        'name': 'DeletedSheet',
        'order': 1,
      };
      final afterDeleteWorkbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(id: 'left-sheet', name: 'Left', order: 0),
          FortuneSheet(id: 'right-sheet', name: 'Right', order: 1),
        ],
      );

      expect(
        patchToOp(afterDeleteWorkbook, const [], {
          'deleteSheetOp': {'id': 'deleted-sheet'},
          'deletedSheet': {
            'id': 'deleted-sheet',
            'order': 1,
            'value': deletedSheetValue,
          },
        }, true),
        [
          {
            'op': 'addSheet',
            'id': 'deleted-sheet',
            'path': [],
            'value': deletedSheetValue,
          },
          {
            'op': 'replace',
            'id': 'deleted-sheet',
            'path': ['name'],
            'value': 'DeletedSheet',
          },
          {
            'op': 'replace',
            'id': 'right-sheet',
            'path': ['order'],
            'value': 1,
          },
        ],
      );
    });

    test('mirrors upstream inverse row and column options', () {
      expect(
        inverseRowColOptions({
          'insertRowColOp': {
            'type': 'row',
            'index': 2,
            'count': 3,
            'direction': 'lefttop',
            'id': 'id_1',
          },
        }),
        {
          'deleteRowColOp': {'type': 'row', 'id': 'id_1', 'start': 2, 'end': 4},
        },
      );
      expect(
        inverseRowColOptions({
          'insertRowColOp': {
            'type': 'row',
            'index': 2,
            'count': 3,
            'direction': 'rightbottom',
            'id': 'id_1',
          },
        }),
        {
          'deleteRowColOp': {'type': 'row', 'id': 'id_1', 'start': 3, 'end': 5},
        },
      );
      expect(
        inverseRowColOptions({
          'deleteRowColOp': {'type': 'row', 'start': 2, 'end': 4, 'id': 'id_1'},
        }),
        {
          'insertRowColOp': {
            'type': 'row',
            'id': 'id_1',
            'index': 2,
            'count': 3,
            'direction': 'lefttop',
          },
        },
      );
      expect(inverseRowColOptions({}), <String, Object?>{});
    });
  });
}
