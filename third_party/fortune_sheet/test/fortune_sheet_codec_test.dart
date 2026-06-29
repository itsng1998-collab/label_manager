import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_codec.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test('codec preserves upstream Empty story null celldata entries', () {
    final source = <String, Object?>{
      'data': [
        {
          'name': 'Empty',
          'status': 1,
          'celldata': [
            {'r': 0, 'c': 0, 'v': null},
          ],
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sheet = workbook.activeSheet;

    expect(sheet.name, 'Empty');
    expect(sheet.status, 1);
    expect(sheet.cells, isEmpty);
    expect(sheet.nullCells, {const FortuneCellCoord(0, 0)});
    expect(FortuneSheetCodec.sheetToJson(sheet), {
      'id': 'sheet_0',
      'name': 'Empty',
      'status': 1,
      'celldata': [
        {'r': 0, 'c': 0, 'v': null},
      ],
    });
    expect(FortuneSheetCodec.workbookToJson(workbook)['data'], [
      {
        'id': 'sheet_0',
        'name': 'Empty',
        'status': 1,
        'celldata': [
          {'r': 0, 'c': 0, 'v': null},
        ],
      },
    ]);
  });

  test('codec preserves upstream DataVerification story rules', () {
    final dataVerification = <String, Object?>{
      '0_0': {
        'type': 'dropdown',
        'type2': '',
        'rangeTxt': 'A1',
        'value1': '1,2,3,4,a',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': true,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
      '0_1': {
        'type': 'dropdown',
        'type2': 'true',
        'rangeTxt': 'B1',
        'value1': 'a,b,c,d',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': false,
        'hintShow': false,
        'hintValue': '',
        'checked': false,
      },
      '0_2': {
        'type': 'checkbox',
        'type2': '',
        'rangeTxt': 'C1',
        'value1': 'a',
        'value2': 'b',
        'validity': '',
        'remote': false,
        'prohibitInput': false,
        'hintShow': true,
        'hintValue': '自定义',
        'checked': false,
      },
      '0_3': {
        'type': 'validity',
        'type2': 'phoneNumber',
        'rangeTxt': 'D1',
        'value1': '',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': false,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
      '1_0': {
        'type': 'number',
        'type2': 'between',
        'rangeTxt': 'A2',
        'value1': '1',
        'value2': '3',
        'validity': '',
        'remote': false,
        'prohibitInput': true,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
      '1_1': {
        'type': 'number_integer',
        'type2': 'equal',
        'rangeTxt': 'B2',
        'value1': '2',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': false,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
      '1_2': {
        'type': 'text_content',
        'type2': 'include',
        'rangeTxt': 'C2',
        'value1': 'a',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': false,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
      '1_3': {
        'type': 'text_length',
        'type2': 'greaterOrEqualTo',
        'rangeTxt': 'D2',
        'value1': '3',
        'value2': '',
        'validity': '',
        'remote': false,
        'prohibitInput': true,
        'hintShow': true,
        'hintValue': '',
        'checked': false,
      },
    };
    final source = <String, Object?>{
      'data': [
        {
          'name': 'dataVerification',
          'status': 1,
          'order': 0,
          'id': '67ec0341-3741-45cb-8fd7-aaf97362ebd7',
          'row': 84,
          'column': 60,
          'config': <String, Object?>{},
          'pivotTable': null,
          'isPivotTable': false,
          'color': null,
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {
                'm': '2',
                'ct': {'fa': 'General', 't': 'n'},
                'v': '2',
              },
            },
            {
              'r': 0,
              'c': 1,
              'v': {
                'm': 'a,b,c',
                'ct': {'fa': 'General', 't': 'g'},
                'v': 'a,b,c',
              },
            },
            {
              'r': 0,
              'c': 2,
              'v': {
                'm': 'b',
                'ct': {'fa': 'General', 't': 'g'},
                'v': 'b',
              },
            },
            {
              'r': 0,
              'c': 3,
              'v': {
                'v': '14209083729',
                'ct': {'fa': 'General', 't': 'n'},
                'm': '14209083729',
              },
            },
            {
              'r': 1,
              'c': 0,
              'v': {
                'v': '2',
                'ct': {'fa': 'General', 't': 'n'},
                'm': '2',
              },
            },
            {
              'r': 1,
              'c': 1,
              'v': {
                'v': '3',
                'ct': {'fa': 'General', 't': 'n'},
                'm': '3',
              },
            },
            {
              'r': 1,
              'c': 2,
              'v': {
                'm': 'abc',
                'ct': {'fa': 'General', 't': 'g'},
                'v': 'abc',
              },
            },
            {
              'r': 1,
              'c': 3,
              'v': {
                'm': 'aaaa',
                'ct': {'fa': 'General', 't': 'g'},
                'v': 'aaaa',
              },
            },
          ],
          'dataVerification': dataVerification,
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sheet = workbook.activeSheet;
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.name, 'dataVerification');
    expect(sheet.status, 1);
    expect(sheet.order, 0);
    expect(sheet.id, '67ec0341-3741-45cb-8fd7-aaf97362ebd7');
    expect(sheet.rowCount, 84);
    expect(sheet.columnCount, 60);
    expect(sheet.color, isNull);
    expect(sheet.hasRawColor, isTrue);
    expect(sheet.rawConfig, isEmpty);
    expect(sheet.hasRawConfig, isTrue);
    expect(sheet.pivotTable, isNull);
    expect(sheet.hasRawPivotTable, isTrue);
    expect(sheet.isPivotTable, isFalse);
    expect(sheet.hasRawIsPivotTable, isTrue);
    expect(sheet.dataVerification, dataVerification);
    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.rawValue, '2');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'a,b,c');
    expect(sheet.cells[const FortuneCellCoord(0, 2)]?.rawValue, 'b');
    expect(sheet.cells[const FortuneCellCoord(0, 3)]?.rawValue, '14209083729');
    expect(json['config'], isEmpty);
    expect(json['color'], isNull);
    expect(json['pivotTable'], isNull);
    expect(json['isPivotTable'], false);
    expect(json['dataVerification'], dataVerification);
    expect((json['celldata'] as List), hasLength(8));
    expect(FortuneSheetCodec.workbookToJson(workbook)['data'], [json]);
  });

  test('codec preserves upstream Freeze story frozen pane metadata', () {
    final source = <String, Object?>{
      'data': [
        {
          'name': 'Freeze',
          'color': '',
          'status': 1,
          'id': '0',
          'row': 84,
          'column': 60,
          'config': {
            'merge': <String, Object?>{},
            'rowlen': <String, Object?>{},
          },
          'pivotTable': null,
          'isPivotTable': false,
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {
                'v': 1,
                'ct': {'fa': 'General', 't': 'n'},
                'm': '1',
              },
            },
            {
              'r': 0,
              'c': 9,
              'v': {
                'v': 10,
                'ct': {'fa': 'General', 't': 'n'},
                'm': '10',
              },
            },
          ],
          'frozen': {
            'type': 'rangeBoth',
            'range': {'row_focus': 3, 'column_focus': 1},
          },
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sheet = workbook.activeSheet;
    final json = FortuneSheetCodec.sheetToJson(sheet);
    final frozenJson = json['frozen']! as Map;

    expect(sheet.name, 'Freeze');
    expect(sheet.id, '0');
    expect(sheet.status, 1);
    expect(sheet.rowCount, 84);
    expect(sheet.columnCount, 60);
    expect(sheet.color, '');
    expect(sheet.hasRawColor, isTrue);
    expect(sheet.rawConfig, {
      'merge': <String, Object?>{},
      'rowlen': <String, Object?>{},
    });
    expect(sheet.hasRawConfig, isTrue);
    expect(sheet.pivotTable, isNull);
    expect(sheet.hasRawPivotTable, isTrue);
    expect(sheet.isPivotTable, isFalse);
    expect(sheet.hasRawIsPivotTable, isTrue);
    expect(sheet.frozen?.type, 'rangeBoth');
    expect(sheet.frozen?.rowFocus, 3);
    expect(sheet.frozen?.rawRowFocus, 3);
    expect(sheet.frozen?.hasRawRowFocus, isTrue);
    expect(sheet.frozen?.columnFocus, 1);
    expect(sheet.frozen?.rawColumnFocus, 1);
    expect(sheet.frozen?.hasRawColumnFocus, isTrue);
    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.rawValue, 1);
    expect(sheet.cells[const FortuneCellCoord(0, 9)]?.renderedText, '10');
    expect(frozenJson, {
      'type': 'rangeBoth',
      'range': {'row_focus': 3, 'column_focus': 1},
    });
    expect((json['celldata'] as List), hasLength(2));
    expect(FortuneSheetCodec.workbookToJson(workbook)['data'], [json]);
  });

  test('codec preserves upstream Protected story lock metadata', () {
    final source = <String, Object?>{
      'data': [
        {
          'name': 'protected',
          'config': {
            'authority': {'sheet': 1},
          },
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {'v': 'can edit', 'lo': 0},
            },
            {
              'r': 0,
              'c': 1,
              'v': {'v': 'is locked', 'lo': 1},
            },
            {
              'r': 0,
              'c': 2,
              'v': {'v': 'default is locked'},
            },
          ],
        },
        {
          'name': 'partial editable',
          'config': {
            'colReadOnly': {'1': 1},
            'rowReadOnly': {'1': 1},
            'columnlen': {'0': 200, '1': 200},
          },
          'celldata': [
            {
              'r': 0,
              'c': 1,
              'v': {'v': 'protected column'},
            },
            {
              'r': 1,
              'c': 0,
              'v': {'v': 'protected row'},
            },
          ],
        },
        {
          'name': 'editable',
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {'v': 'can edit', 'lo': 0},
            },
            {
              'r': 0,
              'c': 1,
              'v': {'v': 'is locked', 'lo': 1},
            },
            {
              'r': 0,
              'c': 2,
              'v': {'v': 'default can edit'},
            },
          ],
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final protectedSheet = workbook.sheets[0];
    final partialEditableSheet = workbook.sheets[1];
    final editableSheet = workbook.sheets[2];

    expect(workbook.sheets.map((sheet) => sheet.name), [
      'protected',
      'partial editable',
      'editable',
    ]);
    expect(protectedSheet.authority, {'sheet': 1});
    expect(protectedSheet.cells[const FortuneCellCoord(0, 0)]?.locked, false);
    expect(protectedSheet.cells[const FortuneCellCoord(0, 1)]?.locked, true);
    expect(protectedSheet.cells[const FortuneCellCoord(0, 2)]?.locked, isNull);
    expect(
      isAllowEdit(
        protectedSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
        ],
      ),
      isTrue,
    );
    expect(
      isAllowEdit(
        protectedSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 1, columnEnd: 1),
        ],
      ),
      isFalse,
    );
    expect(
      isAllowEdit(
        protectedSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 2, columnEnd: 2),
        ],
      ),
      isFalse,
    );
    expect(partialEditableSheet.colReadOnly, {'1': 1});
    expect(partialEditableSheet.rowReadOnly, {'1': 1});
    expect(partialEditableSheet.columnWidths, {0: 200.0, 1: 200.0});
    expect(
      isAllowEdit(
        partialEditableSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 1, columnEnd: 1),
        ],
      ),
      isFalse,
    );
    expect(
      isAllowEdit(
        partialEditableSheet,
        ranges: const [
          FortuneRange(rowStart: 1, rowEnd: 1, columnStart: 0, columnEnd: 0),
        ],
      ),
      isFalse,
    );
    expect(editableSheet.cells[const FortuneCellCoord(0, 1)]?.locked, true);
    expect(
      isAllowEdit(
        editableSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 1, columnEnd: 1),
        ],
      ),
      isFalse,
    );
    expect(
      isAllowEdit(
        editableSheet,
        ranges: const [
          FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 2, columnEnd: 2),
        ],
      ),
      isTrue,
    );
    expect(FortuneSheetCodec.workbookToJson(workbook)['data'], [
      {
        'id': 'sheet_0',
        'name': 'protected',
        'config': {
          'authority': {'sheet': 1},
        },
        'status': 1,
        'celldata': [
          {
            'r': 0,
            'c': 0,
            'v': {'v': 'can edit', 'lo': 0},
          },
          {
            'r': 0,
            'c': 1,
            'v': {'v': 'is locked', 'lo': 1},
          },
          {
            'r': 0,
            'c': 2,
            'v': {'v': 'default is locked'},
          },
        ],
      },
      {
        'id': 'sheet_1',
        'name': 'partial editable',
        'config': {
          'columnlen': {'0': 200, '1': 200},
          'rowReadOnly': {'1': 1},
          'colReadOnly': {'1': 1},
        },
        'status': 0,
        'celldata': [
          {
            'r': 0,
            'c': 1,
            'v': {'v': 'protected column'},
          },
          {
            'r': 1,
            'c': 0,
            'v': {'v': 'protected row'},
          },
        ],
      },
      {
        'id': 'sheet_2',
        'name': 'editable',
        'status': 0,
        'celldata': [
          {
            'r': 0,
            'c': 0,
            'v': {'v': 'can edit', 'lo': 0},
          },
          {
            'r': 0,
            'c': 1,
            'v': {'v': 'is locked', 'lo': 1},
          },
          {
            'r': 0,
            'c': 2,
            'v': {'v': 'default can edit'},
          },
        ],
      },
    ]);
  });

  test('codec preserves upstream Cell story config metadata', () {
    final borderInfo = [
      {
        'rangeType': 'cell',
        'value': {
          'row_index': 3,
          'col_index': 3,
          'l': {'style': 10, 'color': 'rgb(255, 0, 0)'},
          'r': {'style': 10, 'color': 'rgb(255, 0, 0)'},
          't': {'style': 10, 'color': 'rgb(255, 0, 0)'},
          'b': {'style': 10, 'color': 'rgb(255, 0, 0)'},
        },
      },
      {
        'rangeType': 'cell',
        'value': {
          'row_index': 7,
          'col_index': 5,
          'l': {'style': 2, 'color': 'rgb(154, 205, 50)'},
          't': {'style': 2, 'color': 'rgb(154, 205, 50)'},
        },
      },
    ];
    final merge = {
      '13_5': {'r': 13, 'c': 5, 'rs': 3, 'cs': 1},
      '14_2': {'r': 14, 'c': 2, 'rs': 1, 'cs': 2},
    };
    final rowReadOnly = {'2': 1, '3': 1, '4': 1};
    final rowlen = {
      '0': 20,
      '1': 20,
      '2': 20,
      '3': 20,
      '4': 20,
      '5': 20,
      '6': 20,
      '7': 20,
      '8': 20,
      '9': 20,
      '10': 20,
      '11': 20,
      '12': 20,
      '13': 20,
      '14': 20,
      '15': 20,
      '16': 20,
      '17': 31,
      '18': 20,
      '19': 20,
      '20': 20,
      '21': 20,
      '22': 20,
      '23': 20,
      '24': 20,
      '25': 79,
      '26': 20,
      '27': 20,
      '28': 80,
      '29': 36,
    };
    final columnlen = {
      '0': 131,
      '2': 153,
      '3': 128,
      '4': 136,
      '5': 122,
      '6': 138,
      '7': 131,
      '8': 128,
      '9': 140,
      '10': 144,
    };
    final rowhidden = {'30': 0, '31': 0};
    final customHeight = {'29': 1};
    final customWidth = {'2': 1};
    final source = <String, Object?>{
      'data': [
        {
          'name': 'Cell',
          'config': {
            'rowReadOnly': rowReadOnly,
            'merge': merge,
            'borderInfo': borderInfo,
            'rowlen': rowlen,
            'columnlen': columnlen,
            'rowhidden': rowhidden,
            'customHeight': customHeight,
            'customWidth': customWidth,
          },
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {
                'customKey': {'a': 1},
                'bg': null,
                'bl': 0,
                'it': 0,
                'ff': 0,
                'fs': 11,
                'fc': 'rgb(51, 51, 51)',
                'ht': 1,
                'vt': 1,
                'v': 1,
                'ct': {'fa': 'General', 't': 'n'},
                'm': '1',
              },
            },
            {
              'r': 0,
              'c': 3,
              'v': {
                'bg': null,
                'bl': 0,
                'it': 0,
                'ff': 0,
                'fs': 11,
                'fc': 'rgb(51, 51, 51)',
                'ht': 1,
                'vt': 1,
                'v': 0,
                'ct': {'fa': 'General', 't': 'n'},
                'm': '0',
                'f': '=Formula!D3+Formula!D4',
              },
            },
          ],
          'id': '0',
          'zoomRatio': 1,
          'order': '0',
          'column': 18,
          'addRows': 70,
          'row': 36,
          'status': 1,
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sheet = workbook.activeSheet;
    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;
    Map exportedCellValueAt(int row, int column) {
      return (((json['celldata']! as List).cast<Map>()).singleWhere(
            (cell) => cell['r'] == row && cell['c'] == column,
          )['v']!
          as Map);
    }

    expect(sheet.name, 'Cell');
    expect(sheet.id, '0');
    expect(sheet.zoomRatio, 1);
    expect(sheet.rawZoomRatio, 1);
    expect(sheet.hasRawZoomRatio, isTrue);
    expect(sheet.order, 0);
    expect(sheet.rawOrder, '0');
    expect(sheet.hasRawOrder, isTrue);
    expect(sheet.columnCount, 18);
    expect(sheet.rowCount, 36);
    expect(sheet.addRows, 70);
    expect(sheet.rawAddRows, 70);
    expect(sheet.hasRawAddRows, isTrue);
    expect(sheet.status, 1);
    expect(sheet.rowReadOnly, rowReadOnly);
    expect(sheet.rawMerge, merge);
    expect(sheet.rawBorderInfo, borderInfo);
    expect(sheet.hasRawBorderInfo, isTrue);
    expect(sheet.rawRowHeights, rowlen);
    expect(sheet.rowHeights[25], 79);
    expect(sheet.rawColumnWidths, columnlen);
    expect(sheet.columnWidths[10], 144);
    expect(sheet.hiddenRows, {30, 31});
    expect(sheet.rawCustomHeight, customHeight);
    expect(sheet.customHeight, {29: 1.0});
    expect(sheet.rawCustomWidth, customWidth);
    expect(sheet.customWidth, {2: 1.0});
    final firstCell = sheet.cells[const FortuneCellCoord(0, 0)]!;
    final formulaCell = sheet.cells[const FortuneCellCoord(0, 3)]!;
    expect(firstCell.rawValue, 1);
    expect(FortuneSheetCodec.cellToJson(firstCell)['customKey'], {'a': 1});
    expect(firstCell.rawForeground, 'rgb(51, 51, 51)');
    expect(firstCell.hasRawForeground, isTrue);
    expect(formulaCell.rawValue, 0);
    expect(formulaCell.rawFormula, '=Formula!D3+Formula!D4');
    expect(formulaCell.hasRawFormula, isTrue);
    expect(config['rowReadOnly'], rowReadOnly);
    expect(config['merge'], merge);
    expect(config['borderInfo'], borderInfo);
    expect(config['rowlen'], rowlen);
    expect(config['columnlen'], columnlen);
    expect(config['rowhidden'], rowhidden);
    expect(config['customHeight'], customHeight);
    expect(config['customWidth'], customWidth);
    expect(json['id'], '0');
    expect(json['zoomRatio'], 1);
    expect(json['order'], '0');
    expect(json['column'], 18);
    expect(json['addRows'], 70);
    expect(json['row'], 36);
    expect(json['status'], 1);
    expect(exportedCellValueAt(0, 0)['customKey'], {'a': 1});
    expect(exportedCellValueAt(0, 3)['f'], '=Formula!D3+Formula!D4');
    final exportedSheet =
        (FortuneSheetCodec.workbookToJson(workbook)['data']! as List).single
            as Map;
    expect(exportedSheet['config'], config);
    expect(exportedSheet['status'], 1);
  });

  test('codec preserves upstream Formula story sheet metadata', () {
    final merge = {
      '12_2': {'rs': 1, 'cs': 6, 'r': 12, 'c': 2},
      '19_2': {'rs': 1, 'cs': 6, 'r': 19, 'c': 2},
      '20_6': {'rs': 1, 'cs': 5, 'r': 20, 'c': 6},
      '22_6': {'rs': 1, 'cs': 2, 'r': 22, 'c': 6},
      '23_6': {'rs': 1, 'cs': 2, 'r': 23, 'c': 6},
      '28_2': {'rs': 1, 'cs': 6, 'r': 28, 'c': 2},
      '31_6': {'rs': 1, 'cs': 3, 'r': 31, 'c': 6},
      '33_6': {'rs': 1, 'cs': 3, 'r': 33, 'c': 6},
      '35_6': {'rs': 1, 'cs': 3, 'r': 35, 'c': 6},
      '37_6': {'rs': 1, 'cs': 3, 'r': 37, 'c': 6},
      '29_6': {'r': 29, 'c': 6, 'rs': 1, 'cs': 3},
    };
    final columnlen = {
      '0': 111,
      '2': 105,
      '3': 82,
      '4': 71,
      '5': 84,
      '6': 123,
      '7': 48,
      '8': 192,
      '9': 56,
      '10': 56,
    };
    final calcChain = [
      {
        'r': 6,
        'c': 3,
        'id': '1',
        'color': 'w',
        'parent': null,
        'chidren': <String, Object?>{},
        'times': 0,
      },
    ];
    final selectionSave = [
      {
        'left': 532,
        'width': 123,
        'top': 780,
        'height': 19,
        'left_move': 532,
        'width_move': 123,
        'top_move': 780,
        'height_move': 19,
        'row': [39, 39],
        'column': [6, 6],
        'row_focus': 39,
        'column_focus': 6,
      },
    ];
    final source = <String, Object?>{
      'data': [
        {
          'name': 'Formula',
          'color': '',
          'config': {
            'merge': merge,
            'rowlen': <String, Object?>{},
            'columnlen': columnlen,
          },
          'id': '1',
          'chart': [],
          'order': '1',
          'column': 18,
          'row': 45,
          'celldata': [
            {
              'r': 0,
              'c': 0,
              'v': {
                'bg': null,
                'bl': 0,
                'it': 0,
                'ff': 9,
                'fs': 10,
                'fc': 'rgb(0, 0, 0)',
                'ht': 1,
                'vt': 0,
              },
            },
            {
              'r': 1,
              'c': 0,
              'v': {
                'v': 'Basic Function',
                'ct': {'fa': 'General', 't': 'g'},
                'm': 'Basic Function',
                'bg': null,
                'bl': 1,
                'it': 0,
                'ff': 9,
              },
            },
            {
              'r': 5,
              'c': 9,
              'v': {
                'v': 'J2',
                'ct': {'fa': 'General', 't': 'g'},
                'm': 'J2',
                'bg': null,
                'bl': 0,
                'it': 0,
                'ff': 9,
                'fs': 10,
                'fc': 'rgb(0, 0, 0)',
                'ht': 1,
                'vt': 0,
                'f': '=INDIRECT("I2")',
              },
            },
            {
              'r': 6,
              'c': 3,
              'v': {
                'v': 23.75,
                'ct': {'fa': 'General', 't': 'n'},
                'm': '23.75',
                'bg': null,
                'bl': 0,
                'it': 0,
                'ff': 9,
                'fs': 10,
                'fc': 'rgb(0, 0, 0)',
                'ht': 1,
                'vt': 0,
                'f': '=AVERAGE(D3:D6)',
              },
            },
          ],
          'calcChain': calcChain,
          'ch_width': 1723,
          'rh_height': 1010,
          'luckysheet_select_save': selectionSave,
          'luckysheet_selection_range': [],
          'scrollLeft': 0,
          'scrollTop': 0,
          'frozen': {'type': 'row'},
        },
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sheet = workbook.activeSheet;
    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;
    Map exportedCellValueAt(int row, int column) {
      return (((json['celldata']! as List).cast<Map>()).singleWhere(
            (cell) => cell['r'] == row && cell['c'] == column,
          )['v']!
          as Map);
    }

    expect(sheet.name, 'Formula');
    expect(sheet.color, '');
    expect(sheet.id, '1');
    expect(sheet.order, 1);
    expect(sheet.rawOrder, '1');
    expect(sheet.rowCount, 45);
    expect(sheet.columnCount, 18);
    expect(sheet.rawMerge, merge);
    expect(sheet.rawColumnWidths, columnlen);
    expect(sheet.columnWidths[6], 123);
    expect(sheet.columnWidths[10], 56);
    expect(sheet.hasRawRowHeights, isTrue);
    expect(sheet.rawRowHeights, isEmpty);
    expect(sheet.calcChain, calcChain);
    expect(sheet.selectionSave, selectionSave);
    expect(sheet.selectionRange, isEmpty);
    expect(sheet.sheetWidth, 1723);
    expect(sheet.sheetHeight, 1010);
    expect(sheet.extraFields['chart'], isEmpty);
    expect(sheet.extraFields['scrollLeft'], 0);
    expect(sheet.extraFields['scrollTop'], 0);
    expect(sheet.frozen?.type, 'row');
    expect(sheet.rawFrozen, {'type': 'row'});
    expect(
      sheet.cells[const FortuneCellCoord(1, 0)]?.rawValue,
      'Basic Function',
    );
    final indirectCell = sheet.cells[const FortuneCellCoord(5, 9)]!;
    final averageCell = sheet.cells[const FortuneCellCoord(6, 3)]!;
    expect(indirectCell.rawValue, 'J2');
    expect(indirectCell.formula, '=INDIRECT("I2")');
    expect(indirectCell.rawFormula, '=INDIRECT("I2")');
    expect(indirectCell.hasRawFormula, isTrue);
    expect(indirectCell.rawForeground, 'rgb(0, 0, 0)');
    expect(indirectCell.hasRawForeground, isTrue);
    expect(averageCell.rawValue, 23.75);
    expect(averageCell.formula, '=AVERAGE(D3:D6)');
    expect(averageCell.rawFormula, '=AVERAGE(D3:D6)');
    expect(averageCell.hasRawFormula, isTrue);
    expect(config['merge'], merge);
    expect(config['rowlen'], isEmpty);
    expect(config['columnlen'], columnlen);
    expect(json['chart'], isEmpty);
    expect(json['calcChain'], calcChain);
    expect(json['ch_width'], 1723);
    expect(json['rh_height'], 1010);
    expect(json['luckysheet_select_save'], selectionSave);
    expect(json['luckysheet_selection_range'], isEmpty);
    expect(json['scrollLeft'], 0);
    expect(json['scrollTop'], 0);
    expect(json['frozen'], {'type': 'row'});
    expect(exportedCellValueAt(5, 9)['f'], '=INDIRECT("I2")');
    expect(exportedCellValueAt(6, 3)['f'], '=AVERAGE(D3:D6)');
  });

  test(
    'codec converts data matrix and celldata through public API helpers',
    () {
      final matrixValue = {
        'v': 'A',
        'custom': [1],
      };
      final data = [
        [
          matrixValue,
          null,
          {'v': 3},
        ],
        [
          null,
          {'f': '=A1'},
          null,
        ],
      ];

      final celldata = FortuneSheetCodec.dataToCelldata(data);
      final restored = FortuneSheetCodec.celldataToData(
        celldata,
        rowCount: 3,
        columnCount: 4,
      )!;

      matrixValue['v'] = 'mutated';
      (matrixValue['custom']! as List).add(2);
      ((celldata.first['v']! as Map)['custom']! as List).add(3);
      ((restored[0][0]! as Map)['custom']! as List).add(4);

      expect(celldata, [
        {
          'r': 0,
          'c': 0,
          'v': {
            'v': 'A',
            'custom': [1, 3],
          },
        },
        {
          'r': 0,
          'c': 2,
          'v': {'v': 3},
        },
        {
          'r': 1,
          'c': 1,
          'v': {'f': '=A1'},
        },
      ]);
      expect(restored.length, 3);
      expect(restored.first.length, 4);
      expect(restored[0][0], {
        'v': 'A',
        'custom': [1, 4],
      });
      expect(restored[0][1], isNull);
      expect(restored[0][2], {'v': 3});
      expect(restored[1][1], {'f': '=A1'});
      expect(restored[2][3], isNull);
      expect(FortuneSheetCodec.dataToCelldata(null), isEmpty);
      expect(FortuneSheetCodec.celldataToData([]), [
        [null],
      ]);
      expect(
        FortuneSheetCodec.celldataToData([
          {'r': 1, 'c': 2, 'v': 'tail'},
        ], rowCount: 5),
        [
          [null, null, null],
          [null, null, 'tail'],
        ],
      );
      expect(
        FortuneSheetCodec.celldataToData([
          {'r': 1, 'c': 2, 'v': 'tail'},
        ], columnCount: 5),
        [
          [null, null, null],
          [null, null, 'tail'],
        ],
      );
      expect(FortuneSheetCodec.celldataToData(null), isNull);
    },
  );

  test(
    'codec initializes sheet data from celldata like upstream initSheetData',
    () {
      final explicitCell = {
        'v': 'A',
        'meta': [1],
      };
      final explicitSheet = <String, Object?>{
        'id': 's1',
        'row': 3,
        'column': 4,
        'celldata': [
          {'r': 1, 'c': 2, 'v': explicitCell},
        ],
      };
      final defaultSheet = <String, Object?>{
        'id': 's2',
        'celldata': [
          {
            'r': 2,
            'c': 1,
            'v': {'v': 'B'},
          },
        ],
      };
      final invalidSheet = <String, Object?>{'id': 's3'};

      final explicitData = FortuneSheetCodec.initSheetData(explicitSheet)!;
      final defaultData = FortuneSheetCodec.initSheetData(
        defaultSheet,
        settings: const FortuneSettings(row: 5, column: 6),
      )!;
      final invalidData = FortuneSheetCodec.initSheetData(invalidSheet);

      explicitCell['v'] = 'mutated';
      (explicitCell['meta']! as List).add(2);
      ((explicitData[1][2]! as Map)['meta']! as List).add(3);

      expect(explicitData.length, 3);
      expect(explicitData.first.length, 4);
      expect(explicitData[1][2], {
        'v': 'A',
        'meta': [1, 3],
      });
      expect(explicitSheet.containsKey('celldata'), isFalse);
      expect(identical(explicitSheet['data'], explicitData), isTrue);
      expect(defaultData.length, 5);
      expect(defaultData.first.length, 6);
      expect(defaultData[2][1], {'v': 'B'});
      expect(defaultSheet.containsKey('celldata'), isFalse);
      expect(invalidData, isNull);
      expect(invalidSheet.containsKey('data'), isFalse);
    },
  );

  test('cellFromJson maps FortuneSheet cell style fields', () {
    final source = <String, Object?>{
      'v': 10,
      'm': '10.00',
      'f': '=A1',
      'bg': '#fff2cc',
      'fc': 'rgb(192, 0, 0)',
      'bl': 1,
      'it': '1',
      'cl': 1,
      'un': 1,
      'fs': 14,
      'ff': 2,
      'ht': 2,
      'vt': 1,
      'tb': 2,
      'rt': 45,
      'tr': 3,
      'lo': 1,
      'qp': 1,
      'spl': {'type': 'line'},
      'ps': {'value': 'note', 'left': 1, 'top': 2, 'width': 3, 'height': 4},
      'hl': {'r': 0, 'c': 0, 'id': 'h1'},
      'mc': {
        'r': 0,
        'c': 0,
        'rs': 2,
        'cs': 3,
        'customMergeMeta': {'origin': 'cell'},
      },
      'ct': {
        'fa': 'General',
        't': 'n',
        'customTypeMeta': {'source': 'fixture'},
      },
      'customRendererState': {
        'flag': true,
        'items': [1, 2],
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceRendererState = source['customRendererState']! as Map;
    sourceRendererState['flag'] = false;
    (sourceRendererState['items']! as List).add(3);

    expect(cell.value, '10');
    expect(cell.rawValue, 10);
    expect(cell.hasRawValue, isTrue);
    expect(cell.displayValue, '10.00');
    expect(cell.rawDisplayValue, '10.00');
    expect(cell.hasRawDisplayValue, isTrue);
    expect(cell.formula, '=A1');
    expect(cell.background, const Color(0xfffff2cc));
    expect(cell.foreground, const Color(0xffc00000));
    expect(cell.bold, isTrue);
    expect(cell.italic, isTrue);
    expect(cell.strikeThrough, isTrue);
    expect(cell.underline, isTrue);
    expect(cell.fontSize, 14);
    expect(cell.normalizedFontFamily, 'Tahoma');
    expect(cell.normalizedHorizontalAlign, '2');
    expect(cell.normalizedVerticalAlign, '1');
    expect(cell.normalizedTextWrap, '2');
    expect(cell.textRotation, '45');
    expect(cell.rawTextRotation, 45);
    expect(cell.hasRawTextRotation, isTrue);
    expect(cell.isVerticalText, isTrue);
    expect(cell.locked, isTrue);
    expect(cell.quotePrefix, isTrue);
    expect(cell.sparkline, isA<Map>());
    expect(cell.comment?.value, 'note');
    expect(cell.comment?.width, 3);
    expect(cell.comment?.extraFields, isEmpty);
    expect(cell.hyperlink?.id, 'h1');
    expect(cell.merge?.rowSpan, 2);
    expect(cell.merge?.columnSpan, 3);
    expect(cell.merge?.extraFields['customMergeMeta'], {'origin': 'cell'});
    expect(cell.cellType?.format, 'General');
    expect(cell.cellType?.type, 'n');
    expect(cell.cellType?.extraFields['customTypeMeta'], {'source': 'fixture'});
    expect(cell.extraFields['customRendererState'], isA<Map>());
    expect((cell.extraFields['customRendererState']! as Map)['flag'], isTrue);
    expect(cell.extraFields['customRendererState'], {
      'flag': true,
      'items': [1, 2],
    });
  });

  test('cellFromJson snapshots top-level extra metadata fields', () {
    final source = {
      'v': 'A1',
      'customRendererState': {
        'flag': true,
        'items': [1, 2],
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceRendererState = source['customRendererState']! as Map;
    sourceRendererState['flag'] = false;
    (sourceRendererState['items']! as List).add(3);

    expect(cell.extraFields['customRendererState'], {
      'flag': true,
      'items': [1, 2],
    });

    final json = FortuneSheetCodec.cellToJson(cell);
    final exportedRendererState = json['customRendererState']! as Map;
    exportedRendererState['flag'] = false;
    (exportedRendererState['items']! as List).add(4);

    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['customRendererState'], {
      'flag': true,
      'items': [1, 2],
    });
  });

  test('cellFromJson converts inline string ct.s to rich text runs', () {
    final source = <String, Object?>{
      'ct': <String, Object?>{
        't': 'inlineStr',
        'customTypeMeta': {'source': 'rich'},
        's': [
          <String, Object?>{
            'v': 'Hello',
            'bl': 1,
            'customRunMeta': {
              'token': 1,
              'tags': ['original'],
            },
          },
          {'v': ' World', 'fc': '#188038', 'un': 1},
        ],
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final type = source['ct']! as Map;
    final runsSource = type['s']! as List;
    final runMeta = (runsSource.first as Map)['customRunMeta']! as Map;
    runMeta['token'] = 99;
    (runMeta['tags']! as List).add('changed');

    expect(cell.renderedText, 'Hello World');
    expect(cell.inlineRuns, hasLength(2));
    expect(cell.inlineRuns![0].bold, isTrue);
    expect(cell.inlineRuns![0].extraFields['customRunMeta'], {
      'token': 1,
      'tags': ['original'],
    });
    expect(cell.inlineRuns![1].foreground, const Color(0xff188038));
    expect(cell.inlineRuns![1].rawForeground, '#188038');
    expect(cell.inlineRuns![1].hasRawForeground, isTrue);
    expect(cell.inlineRuns![1].underline, isTrue);

    final json = FortuneSheetCodec.cellToJson(cell);
    final cellType = json['ct']! as Map;
    final runs = cellType['s']! as List;
    expect(cellType['customTypeMeta'], {'source': 'rich'});
    expect((runs.first as Map)['customRunMeta'], {
      'token': 1,
      'tags': ['original'],
    });
    expect((runs.first as Map).containsKey('fc'), isFalse);

    final exportedRunMeta = (runs.first as Map)['customRunMeta']! as Map;
    exportedRunMeta['token'] = 99;
    (exportedRunMeta['tags']! as List).add('export changed');
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRuns = (reexported['ct']! as Map)['s']! as List;
    expect((reexportedRuns.first as Map)['customRunMeta'], {
      'token': 1,
      'tags': ['original'],
    });
    expect(cell.inlineRuns![0].extraFields['customRunMeta'], {
      'token': 1,
      'tags': ['original'],
    });
  });

  test('cellFromJson preserves inline string wrap markers', () {
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {
        't': 'inlineStr',
        's': [
          {'v': 'Line 1'},
          {'wrap': true},
          {'v': 'Line 2'},
        ],
      },
    });

    expect(cell.renderedText, 'Line 1Line 2');
    expect(cell.inlineRuns, hasLength(3));
    expect(cell.inlineRuns![1].text, isEmpty);
    expect(cell.inlineRuns![1].wrap, isTrue);
    expect(cell.inlineRuns![1].rawWrap, isTrue);
    expect(cell.inlineRuns![1].hasRawWrap, isTrue);
    expect(cell.inlineRuns![1].hasRawText, isFalse);

    final json = FortuneSheetCodec.cellToJson(cell);
    final runs = (json['ct']! as Map)['s']! as List;
    expect(runs[1], {'wrap': true});
  });

  test('editing rich text cell does not export stale ct.s runs', () {
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {
        't': 'inlineStr',
        's': [
          {'v': 'old', 'bl': 1},
        ],
      },
    });

    final edited = cell.withEditedValue('new');
    final json = FortuneSheetCodec.cellToJson(edited);

    expect(json['v'], 'new');
    expect(json.containsKey('ct'), isFalse);

    json
      ..['v'] = 'mutated'
      ..['ct'] = {
        't': 'inlineStr',
        's': [
          {'v': 'stale'},
        ],
      };
    final reexported = FortuneSheetCodec.cellToJson(edited);
    expect(reexported['v'], 'new');
    expect(reexported.containsKey('ct'), isFalse);
  });

  test('cellToJson writes mapped fields and preserved extra fields', () {
    const cell = FortuneCell(
      value: '10',
      displayValue: '10.00',
      formula: '=A1',
      merge: FortuneCellMerge(
        row: 0,
        column: 0,
        rowSpan: 2,
        columnSpan: 3,
        extraFields: {
          'customMergeMeta': {'origin': 'manual'},
        },
      ),
      cellType: FortuneCellType(
        format: 'General',
        type: 'n',
        extraFields: {
          'customTypeMeta': {'source': 'manual'},
        },
      ),
      quotePrefix: true,
      sparkline: {'type': 'line'},
      locked: false,
      comment: FortuneCellComment(
        value: 'note',
        left: 1,
        top: 2,
        width: 3,
        height: 4,
        isShow: true,
      ),
      hyperlink: FortuneHyperlink(row: 0, column: 0, id: 'h1'),
      background: Color(0xfffff2cc),
      foreground: Color(0xffc00000),
      bold: true,
      italic: true,
      strikeThrough: true,
      underline: true,
      fontSize: 14,
      fontFamily: '2',
      horizontalAlign: '2',
      verticalAlign: '1',
      textWrap: '2',
      textRotation: '45',
      textRotationMode: '3',
      extraFields: {
        'customRendererState': {
          'flag': true,
          'items': [1, 2],
        },
        'v': 'extra must not override mapped value',
      },
    );

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(json['v'], '10');
    expect(json['m'], '10.00');
    expect(json['f'], '=A1');
    expect(json['bg'], '#fff2cc');
    expect(json['fc'], '#c00000');
    expect(json['bl'], 1);
    expect(json['it'], 1);
    expect(json['cl'], 1);
    expect(json['un'], 1);
    expect(json['fs'], 14);
    expect(json['ff'], 2);
    expect(json['ht'], 2);
    expect(json['vt'], 1);
    expect(json['tb'], '2');
    expect(json['rt'], '45');
    expect(json['tr'], '3');
    expect(json['lo'], 0);
    expect(json['qp'], 1);
    expect(json['spl'], {'type': 'line'});
    expect(json['ps'], {
      'left': 1,
      'top': 2,
      'width': 3,
      'height': 4,
      'value': 'note',
      'isShow': true,
    });
    expect(json['hl'], {'r': 0, 'c': 0, 'id': 'h1'});
    expect(json['mc'], {
      'customMergeMeta': {'origin': 'manual'},
      'r': 0,
      'c': 0,
      'rs': 2,
      'cs': 3,
    });
    expect(json['ct'], {
      'customTypeMeta': {'source': 'manual'},
      'fa': 'General',
      't': 'n',
    });
    expect(json['customRendererState'], isA<Map>());

    json
      ..['v'] = 'mutated'
      ..['m'] = 'mutated'
      ..['f'] = '=B1';
    (json['spl']! as Map)['type'] = 'bar';
    (json['ps']! as Map)['value'] = 'mutated';
    (json['hl']! as Map)['id'] = 'h2';
    (json['mc']! as Map)
      ..['r'] = 9
      ..['customMergeMeta'] = {'origin': 'mutated'};
    (json['ct']! as Map)
      ..['t'] = 's'
      ..['customTypeMeta'] = {'source': 'mutated'};
    ((json['customRendererState']! as Map)['items']! as List).add(3);
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['v'], '10');
    expect(reexported['m'], '10.00');
    expect(reexported['f'], '=A1');
    expect(reexported['spl'], {'type': 'line'});
    expect((reexported['ps']! as Map)['value'], 'note');
    expect(reexported['hl'], {'r': 0, 'c': 0, 'id': 'h1'});
    expect(reexported['mc'], {
      'customMergeMeta': {'origin': 'manual'},
      'r': 0,
      'c': 0,
      'rs': 2,
      'cs': 3,
    });
    expect(reexported['ct'], {
      'customTypeMeta': {'source': 'manual'},
      'fa': 'General',
      't': 'n',
    });
    expect(reexported['customRendererState'], {
      'flag': true,
      'items': [1, 2],
    });
  });

  test('cell comment and hyperlink preserve nested unknown fields', () {
    final source = <String, Object?>{
      'v': 'linked note',
      'ps': <String, Object?>{
        'value': 'note',
        'left': 1,
        'customCommentMeta': <String, Object?>{
          'author': 'tester',
          'mentions': ['a', 'b'],
        },
      },
      'hl': <String, Object?>{
        'r': 0,
        'c': 0,
        'id': 'h1',
        'linkType': 'webpage',
        'linkAddress': 'https://example.test',
        'customLinkMeta': <String, Object?>{
          'tracking': true,
          'events': ['open'],
        },
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceComment = source['ps']! as Map;
    final sourceCommentMeta = sourceComment['customCommentMeta']! as Map;
    sourceCommentMeta['author'] = 'source mutated';
    (sourceCommentMeta['mentions']! as List).add('source');
    final sourceHyperlink = source['hl']! as Map;
    final sourceHyperlinkMeta = sourceHyperlink['customLinkMeta']! as Map;
    sourceHyperlinkMeta['tracking'] = false;
    (sourceHyperlinkMeta['events']! as List).add('source');

    final commentMeta = cell.comment!.extraFields['customCommentMeta']! as Map;
    final hyperlinkMeta = cell.hyperlink!.extraFields['customLinkMeta']! as Map;

    expect(commentMeta['author'], 'tester');
    expect(commentMeta['mentions'], ['a', 'b']);
    expect(hyperlinkMeta['tracking'], isTrue);
    expect(hyperlinkMeta['events'], ['open']);

    final json = FortuneSheetCodec.cellToJson(cell);
    final comment = json['ps']! as Map;
    final hyperlink = json['hl']! as Map;

    expect(comment['customCommentMeta'], {
      'author': 'tester',
      'mentions': ['a', 'b'],
    });
    expect(hyperlink['linkType'], 'webpage');
    expect(hyperlink['linkAddress'], 'https://example.test');
    expect(hyperlink['customLinkMeta'], {
      'tracking': true,
      'events': ['open'],
    });

    final exportedCommentMeta = comment['customCommentMeta']! as Map;
    final exportedMentions = exportedCommentMeta['mentions']! as List;
    exportedCommentMeta['author'] = 'mutated';
    exportedMentions.add('c');
    final exportedHyperlinkMeta = hyperlink['customLinkMeta']! as Map;
    exportedHyperlinkMeta['tracking'] = false;
    (exportedHyperlinkMeta['events']! as List).add('export');

    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect((reexported['ps']! as Map)['customCommentMeta'], {
      'author': 'tester',
      'mentions': ['a', 'b'],
    });
    expect((reexported['hl']! as Map)['customLinkMeta'], {
      'tracking': true,
      'events': ['open'],
    });
    expect(cell.comment!.extraFields['customCommentMeta'], {
      'author': 'tester',
      'mentions': ['a', 'b'],
    });
    expect(cell.hyperlink!.extraFields['customLinkMeta'], {
      'tracking': true,
      'events': ['open'],
    });
  });

  test('cellToJson preserves explicit empty comment and hyperlink objects', () {
    final source = <String, Object?>{
      'ps': <String, Object?>{},
      'hl': <String, Object?>{},
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    (source['ps']! as Map)['value'] = 'mutated';
    (source['hl']! as Map)['id'] = 'mutated';

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.comment, isNotNull);
    expect(cell.hyperlink, isNotNull);
    expect(json.containsKey('ps'), isTrue);
    expect(json['ps'], isEmpty);
    expect(json.containsKey('hl'), isTrue);
    expect(json['hl'], isEmpty);

    (json['ps']! as Map)['value'] = 'export-mutated';
    (json['hl']! as Map)['id'] = 'export-mutated';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('ps'), isTrue);
    expect(reexported['ps'], isEmpty);
    expect(reexported.containsKey('hl'), isTrue);
    expect(reexported['hl'], isEmpty);
  });

  test('cell comment export preserves raw dimensions and absent fields', () {
    final sparse = FortuneSheetCodec.cellFromJson({
      'ps': {
        'value': 'note',
        'left': 1,
        'isShow': 1,
        'customCommentMeta': {'author': 'tester'},
      },
    });
    final fullSource = {
      'value': 'full note',
      'left': '1',
      'top': 2,
      'width': null,
      'height': 4,
      'isShow': false,
    };
    final full = FortuneSheetCodec.cellFromJson({'ps': fullSource});
    fullSource
      ..['left'] = '9'
      ..['top'] = 9
      ..['width'] = 9
      ..['height'] = 9
      ..['isShow'] = true;

    final sparseJson = FortuneSheetCodec.cellToJson(sparse)['ps']! as Map;
    final fullJson = FortuneSheetCodec.cellToJson(full)['ps']! as Map;

    expect(sparseJson, {
      'customCommentMeta': {'author': 'tester'},
      'left': 1,
      'value': 'note',
      'isShow': 1,
    });
    expect(fullJson, {
      'left': '1',
      'top': 2,
      'width': null,
      'height': 4,
      'value': 'full note',
      'isShow': false,
    });

    fullJson
      ..['left'] = '9'
      ..['top'] = 9
      ..['width'] = 9
      ..['height'] = 9
      ..['isShow'] = true;
    final reexportedFull = FortuneSheetCodec.cellToJson(full)['ps']! as Map;
    expect(reexportedFull, {
      'left': '1',
      'top': 2,
      'width': null,
      'height': 4,
      'value': 'full note',
      'isShow': false,
    });
  });

  test('cellFromJson snapshots nested raw comment and hyperlink fields', () {
    final commentValue = {
      'items': [
        {'value': 'comment value'},
      ],
    };
    final linkAddress = {
      'items': [
        {'value': 'link address'},
      ],
    };
    final source = {
      'ps': {'value': commentValue},
      'hl': {'linkAddress': linkAddress},
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    ((commentValue['items']! as List).single as Map)['value'] =
        'mutated source';
    ((linkAddress['items']! as List).single as Map)['value'] = 'mutated source';

    final exported = FortuneSheetCodec.cellToJson(cell);
    final exportedCommentValue = (exported['ps']! as Map)['value']! as Map;
    final exportedLinkAddress = (exported['hl']! as Map)['linkAddress']! as Map;
    ((exportedCommentValue['items']! as List).single as Map)['value'] =
        'mutated export';
    ((exportedLinkAddress['items']! as List).single as Map)['value'] =
        'mutated export';

    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedCommentValue = (reexported['ps']! as Map)['value']! as Map;
    final reexportedLinkAddress =
        (reexported['hl']! as Map)['linkAddress']! as Map;
    expect(
      ((reexportedCommentValue['items']! as List).single as Map)['value'],
      'comment value',
    );
    expect(
      ((reexportedLinkAddress['items']! as List).single as Map)['value'],
      'link address',
    );
    expect(((cell.comment!.rawValue! as Map)['items']! as List).single, {
      'value': 'comment value',
    });
    expect(
      ((cell.hyperlink!.rawLinkAddress! as Map)['items']! as List).single,
      {'value': 'link address'},
    );
  });

  test('cell comment export preserves raw value field', () {
    final commentSource = <String, Object?>{'value': 123};
    final cell = FortuneSheetCodec.cellFromJson({'ps': commentSource});
    commentSource['value'] = 'mutated';
    final changed = cell.copyWith(
      comment: cell.comment!.copyWith(value: 'changed'),
    );

    final json = FortuneSheetCodec.cellToJson(cell)['ps']! as Map;
    final changedJson = FortuneSheetCodec.cellToJson(changed)['ps']! as Map;

    expect(cell.comment?.value, '123');
    expect(cell.comment?.rawValue, 123);
    expect(cell.comment?.hasRawValue, isTrue);
    expect(json['value'], 123);
    expect(changedJson['value'], 'changed');

    json['value'] = 'mutated';
    final reexported = FortuneSheetCodec.cellToJson(cell)['ps']! as Map;
    expect(reexported['value'], 123);
  });

  test('cell comment export preserves explicit null fields', () {
    final commentSource = <String, Object?>{
      'left': null,
      'top': null,
      'height': null,
      'value': null,
      'isShow': null,
    };
    final cell = FortuneSheetCodec.cellFromJson({'ps': commentSource});
    commentSource
      ..['left'] = 1
      ..['top'] = 2
      ..['height'] = 3
      ..['value'] = 'mutated'
      ..['isShow'] = true;

    final json = FortuneSheetCodec.cellToJson(cell)['ps']! as Map;

    expect(cell.comment?.hasRawLeft, isTrue);
    expect(cell.comment?.hasRawTop, isTrue);
    expect(cell.comment?.hasRawHeight, isTrue);
    expect(cell.comment?.hasRawValue, isTrue);
    expect(cell.comment?.hasRawIsShow, isTrue);
    expect(json, {
      'left': null,
      'top': null,
      'height': null,
      'value': null,
      'isShow': null,
    });

    json
      ..['left'] = 1
      ..['top'] = 2
      ..['height'] = 3
      ..['value'] = 'mutated'
      ..['isShow'] = true;
    final reexported = FortuneSheetCodec.cellToJson(cell)['ps']! as Map;
    expect(reexported, {
      'left': null,
      'top': null,
      'height': null,
      'value': null,
      'isShow': null,
    });
  });

  test('merge export preserves raw span fields even when span is one', () {
    final cellMergeSource = {'r': '0', 'c': 0, 'rs': 1, 'cs': '1'};
    final cell = FortuneSheetCodec.cellFromJson({'mc': cellMergeSource});
    cellMergeSource
      ..['r'] = '9'
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = '9';
    final moved = cell.copyWith(
      merge: const FortuneCellMerge(row: 1, column: 0, rowSpan: 1),
    );
    final configMergeSource = {'r': '2', 'c': 3, 'rs': 1, 'cs': '1'};
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'merge': {'2_3': configMergeSource},
      },
    });
    configMergeSource
      ..['r'] = '9'
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = '9';

    final cellMerge = FortuneSheetCodec.cellToJson(cell)['mc']! as Map;
    final movedMerge = FortuneSheetCodec.cellToJson(moved)['mc']! as Map;
    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final configMerge = (config['merge']! as Map)['2_3']! as Map;

    expect(cell.merge?.hasRawRow, isTrue);
    expect(cell.merge?.hasRawColumn, isTrue);
    expect(cellMerge['r'], '0');
    expect(cellMerge['c'], 0);
    expect(cell.merge?.hasRawRowSpan, isTrue);
    expect(cell.merge?.hasRawColumnSpan, isTrue);
    expect(cellMerge['rs'], 1);
    expect(cellMerge['cs'], '1');
    expect(movedMerge['r'], 1);
    expect(movedMerge['c'], 0);
    expect(configMerge['r'], '2');
    expect(configMerge['c'], 3);
    expect(configMerge['rs'], 1);
    expect(configMerge['cs'], '1');

    cellMerge
      ..['r'] = '9'
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = '9';
    configMerge
      ..['r'] = '9'
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = '9';
    final reexportedCellMerge =
        FortuneSheetCodec.cellToJson(cell)['mc']! as Map;
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final reexportedConfigMerge =
        (reexportedConfig['merge']! as Map)['2_3']! as Map;
    expect(reexportedCellMerge, {'r': '0', 'c': 0, 'rs': 1, 'cs': '1'});
    expect(reexportedConfigMerge, {'r': '2', 'c': 3, 'rs': 1, 'cs': '1'});
  });

  test('sheetToJson preserves unchanged raw config merge map', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'merge': {
          'custom_anchor_key': {
            'r': '0',
            'c': 0,
            'rs': '2',
            'cs': 1,
            'customMergeMeta': {'origin': 'raw'},
          },
          'raw_only': {'note': 'preserve'},
        },
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    final sourceMerge = sourceConfig['merge']! as Map;
    final sourceAnchor = sourceMerge['custom_anchor_key']! as Map;
    sourceAnchor['customMergeMeta'] = {'origin': 'mutated'};
    sourceMerge['raw_only'] = {'note': 'mutated'};
    final changed = sheet.copyWith(
      cells: {
        ...sheet.cells,
        const FortuneCellCoord(0, 0): sheet.cells[const FortuneCellCoord(0, 0)]!
            .copyWith(
              merge: const FortuneCellMerge(row: 0, column: 0, rowSpan: 3),
            ),
      },
    );

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.rawMerge, {
      'custom_anchor_key': {
        'r': '0',
        'c': 0,
        'rs': '2',
        'cs': 1,
        'customMergeMeta': {'origin': 'raw'},
      },
      'raw_only': {'note': 'preserve'},
    });
    expect(sheet.hasRawMerge, isTrue);
    expect(config['merge'], {
      'custom_anchor_key': {
        'r': '0',
        'c': 0,
        'rs': '2',
        'cs': 1,
        'customMergeMeta': {'origin': 'raw'},
      },
      'raw_only': {'note': 'preserve'},
    });
    final exportedMerge = config['merge']! as Map;
    (exportedMerge['custom_anchor_key']! as Map)['customMergeMeta'] = {
      'origin': 'export-mutated',
    };
    exportedMerge['raw_only'] = {'note': 'export-mutated'};
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['merge'], {
      'custom_anchor_key': {
        'r': '0',
        'c': 0,
        'rs': '2',
        'cs': 1,
        'customMergeMeta': {'origin': 'raw'},
      },
      'raw_only': {'note': 'preserve'},
    });
    expect(changedConfig['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 3},
    });
  });

  test('sheetToJson preserves empty raw config merge presence', () {
    final emptyMergeSheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {'merge': <String, Object?>{}},
    });
    final nullMergeSheet = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'config': {'merge': null},
    });

    final emptyConfig =
        FortuneSheetCodec.sheetToJson(emptyMergeSheet)['config']! as Map;
    final nullConfig =
        FortuneSheetCodec.sheetToJson(nullMergeSheet)['config']! as Map;

    expect(emptyMergeSheet.hasRawMerge, isTrue);
    expect(emptyConfig.containsKey('merge'), isTrue);
    expect(emptyConfig['merge'], <String, Object?>{});
    expect(nullMergeSheet.hasRawMerge, isTrue);
    expect(nullConfig.containsKey('merge'), isTrue);
    expect(nullConfig['merge'], isNull);
  });

  test('sheetToJson omits plain single-cell config merge anchors', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        FortuneCellCoord(0, 0): FortuneCell(
          merge: FortuneCellMerge(row: 0, column: 0),
        ),
      },
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(json.containsKey('config'), isFalse);
  });

  test('cellToJson preserves explicit empty merge object', () {
    final source = <String, Object?>{'mc': <String, Object?>{}};

    final cell = FortuneSheetCodec.cellFromJson(source);
    (source['mc']! as Map)['r'] = 9;
    const manual = FortuneCell(merge: FortuneCellMerge(row: 0, column: 0));

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.merge, isNotNull);
    expect(cell.merge?.preserveEmpty, isTrue);
    expect(json.containsKey('mc'), isTrue);
    expect(json['mc'], isEmpty);
    expect(FortuneSheetCodec.cellToJson(manual)['mc'], {'r': 0, 'c': 0});

    (json['mc']! as Map)['r'] = 9;
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('mc'), isTrue);
    expect(reexported['mc'], isEmpty);
  });

  test('cellToJson preserves explicit null merge coordinates and spans', () {
    final source = <String, Object?>{
      'mc': <String, Object?>{'r': null, 'c': null, 'rs': null, 'cs': null},
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceMerge = source['mc']! as Map;
    sourceMerge
      ..['r'] = 9
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = 9;
    final moved = cell.copyWith(
      merge: const FortuneCellMerge(row: 2, column: 3, rowSpan: 4),
    );

    final json = FortuneSheetCodec.cellToJson(cell)['mc']! as Map;
    final movedJson = FortuneSheetCodec.cellToJson(moved)['mc']! as Map;

    expect(json.containsKey('r'), isTrue);
    expect(json['r'], isNull);
    expect(json.containsKey('c'), isTrue);
    expect(json['c'], isNull);
    expect(json.containsKey('rs'), isTrue);
    expect(json['rs'], isNull);
    expect(json.containsKey('cs'), isTrue);
    expect(json['cs'], isNull);
    expect(movedJson, {'r': 2, 'c': 3, 'rs': 4});

    json
      ..['r'] = 9
      ..['c'] = 9
      ..['rs'] = 9
      ..['cs'] = 9;
    final reexported = FortuneSheetCodec.cellToJson(cell)['mc']! as Map;
    expect(reexported.containsKey('r'), isTrue);
    expect(reexported['r'], isNull);
    expect(reexported.containsKey('c'), isTrue);
    expect(reexported['c'], isNull);
    expect(reexported.containsKey('rs'), isTrue);
    expect(reexported['rs'], isNull);
    expect(reexported.containsKey('cs'), isTrue);
    expect(reexported['cs'], isNull);
  });

  test('cell hyperlink export preserves raw row and column fields', () {
    final source = {'r': '1', 'c': 2, 'id': 'h1'};
    final cell = FortuneSheetCodec.cellFromJson({'hl': source});
    source
      ..['r'] = '9'
      ..['c'] = 9;
    final moved = cell.copyWith(hyperlink: cell.hyperlink!.copyWith(row: 3));

    final json = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    final movedJson = FortuneSheetCodec.cellToJson(moved)['hl']! as Map;

    expect(cell.hyperlink?.rawRow, '1');
    expect(cell.hyperlink?.hasRawRow, isTrue);
    expect(json['r'], '1');
    expect(json['c'], 2);
    expect(movedJson['r'], 3);
    expect(movedJson['c'], 2);

    json
      ..['r'] = '9'
      ..['c'] = 9;
    final reexported = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    expect(reexported['r'], '1');
    expect(reexported['c'], 2);
  });

  test('cell hyperlink export preserves raw id field', () {
    final source = {'r': 1, 'c': 2, 'id': 123};
    final cell = FortuneSheetCodec.cellFromJson({'hl': source});
    source['id'] = 456;
    final changed = cell.copyWith(
      hyperlink: cell.hyperlink!.copyWith(id: 'h2'),
    );

    final json = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    final changedJson = FortuneSheetCodec.cellToJson(changed)['hl']! as Map;

    expect(cell.hyperlink?.id, '123');
    expect(cell.hyperlink?.rawId, 123);
    expect(cell.hyperlink?.hasRawId, isTrue);
    expect(json['id'], 123);
    expect(changedJson['id'], 'h2');

    json['id'] = 456;
    expect(FortuneSheetCodec.cellToJson(cell)['hl'], containsPair('id', 123));
  });

  test('cell hyperlink export preserves raw type and address fields', () {
    final source = <String, Object?>{'linkType': 7, 'linkAddress': null};
    final cell = FortuneSheetCodec.cellFromJson({'hl': source});
    source
      ..['linkType'] = 8
      ..['linkAddress'] = 'https://mutated.test';
    final changed = cell.copyWith(
      hyperlink: cell.hyperlink!.copyWith(
        linkType: 'webpage',
        linkAddress: 'https://example.test',
      ),
    );

    final json = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    final changedJson = FortuneSheetCodec.cellToJson(changed)['hl']! as Map;

    expect(cell.hyperlink?.linkType, '7');
    expect(cell.hyperlink?.rawLinkType, 7);
    expect(cell.hyperlink?.hasRawLinkType, isTrue);
    expect(cell.hyperlink?.linkAddress, isNull);
    expect(cell.hyperlink?.hasRawLinkAddress, isTrue);
    expect(json['linkType'], 7);
    expect(json.containsKey('linkAddress'), isTrue);
    expect(json['linkAddress'], isNull);
    expect(changedJson['linkType'], 'webpage');
    expect(changedJson['linkAddress'], 'https://example.test');

    json
      ..['linkType'] = 8
      ..['linkAddress'] = 'https://mutated.test';
    final reexported = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    expect(reexported['linkType'], 7);
    expect(reexported['linkAddress'], isNull);
  });

  test('cell hyperlink export preserves explicit null fields', () {
    final source = <String, Object?>{
      'hl': <String, Object?>{
        'r': null,
        'c': null,
        'id': null,
        'linkType': null,
        'linkAddress': null,
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceHyperlink = source['hl']! as Map;
    sourceHyperlink
      ..['r'] = 9
      ..['c'] = 9
      ..['id'] = 'h1'
      ..['linkType'] = 'webpage'
      ..['linkAddress'] = 'https://mutated.test';

    final json = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;

    expect(cell.hyperlink?.hasRawRow, isTrue);
    expect(cell.hyperlink?.hasRawColumn, isTrue);
    expect(cell.hyperlink?.hasRawId, isTrue);
    expect(cell.hyperlink?.hasRawLinkType, isTrue);
    expect(cell.hyperlink?.hasRawLinkAddress, isTrue);
    expect(json, {
      'r': null,
      'c': null,
      'id': null,
      'linkType': null,
      'linkAddress': null,
    });

    json
      ..['r'] = 9
      ..['c'] = 9
      ..['id'] = 'h1'
      ..['linkType'] = 'webpage'
      ..['linkAddress'] = 'https://mutated.test';
    final reexported = FortuneSheetCodec.cellToJson(cell)['hl']! as Map;
    expect(reexported, {
      'r': null,
      'c': null,
      'id': null,
      'linkType': null,
      'linkAddress': null,
    });
  });

  test('cellToJson preserves quote prefix and locked raw flags', () {
    final source = {'qp': 0, 'lo': '0'};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['qp'] = 1
      ..['lo'] = '1';
    final changed = cell.copyWith(quotePrefix: true, locked: true);

    final json = FortuneSheetCodec.cellToJson(cell);
    final changedJson = FortuneSheetCodec.cellToJson(changed);

    expect(cell.hasRawQuotePrefix, isTrue);
    expect(cell.hasRawLocked, isTrue);
    expect(json['qp'], 0);
    expect(json['lo'], '0');
    expect(changedJson['qp'], 1);
    expect(changedJson['lo'], 1);

    json
      ..['qp'] = 1
      ..['lo'] = '1';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['qp'], 0);
    expect(reexported['lo'], '0');
  });

  test('cellToJson preserves explicit null quote prefix and style flags', () {
    final source = <String, Object?>{
      'qp': null,
      'lo': null,
      'bl': null,
      'it': null,
      'cl': null,
      'un': null,
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['qp'] = 1
      ..['lo'] = 1
      ..['bl'] = 1
      ..['it'] = 1
      ..['cl'] = 1
      ..['un'] = 1;
    final changed = cell.copyWith(quotePrefix: true, locked: false, bold: true);

    final json = FortuneSheetCodec.cellToJson(cell);
    final changedJson = FortuneSheetCodec.cellToJson(changed);

    expect(json['qp'], isNull);
    expect(json['lo'], isNull);
    expect(json['bl'], isNull);
    expect(json['it'], isNull);
    expect(json['cl'], isNull);
    expect(json['un'], isNull);
    expect(changedJson['qp'], 1);
    expect(changedJson['lo'], 0);
    expect(changedJson['bl'], 1);

    json
      ..['qp'] = 1
      ..['lo'] = 1
      ..['bl'] = 1
      ..['it'] = 1
      ..['cl'] = 1
      ..['un'] = 1;
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['qp'], isNull);
    expect(reexported['lo'], isNull);
    expect(reexported['bl'], isNull);
    expect(reexported['it'], isNull);
    expect(reexported['cl'], isNull);
    expect(reexported['un'], isNull);
  });

  test('cellToJson preserves raw style flags and font size', () {
    final source = {'bl': 0, 'it': '0', 'cl': false, 'un': '1', 'fs': '14'};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['bl'] = 1
      ..['it'] = '1'
      ..['cl'] = true
      ..['un'] = '0'
      ..['fs'] = '18';
    final changed = cell.copyWith(bold: true, fontSize: 12);

    final json = FortuneSheetCodec.cellToJson(cell);
    final changedJson = FortuneSheetCodec.cellToJson(changed);

    expect(cell.hasRawBold, isTrue);
    expect(cell.hasRawItalic, isTrue);
    expect(cell.hasRawStrikeThrough, isTrue);
    expect(cell.hasRawUnderline, isTrue);
    expect(cell.hasRawFontSize, isTrue);
    expect(json['bl'], 0);
    expect(json['it'], '0');
    expect(json['cl'], isFalse);
    expect(json['un'], '1');
    expect(json['fs'], '14');
    expect(changedJson['bl'], 1);
    expect(changedJson['fs'], 12);

    json
      ..['bl'] = 1
      ..['it'] = '1'
      ..['cl'] = true
      ..['un'] = '0'
      ..['fs'] = '18';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['bl'], 0);
    expect(reexported['it'], '0');
    expect(reexported['cl'], isFalse);
    expect(reexported['un'], '1');
    expect(reexported['fs'], '14');
  });

  test('cellToJson preserves raw style option value types', () {
    final source = {'ff': '2', 'ht': 0, 'vt': '1', 'tb': 2, 'tr': 3};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['ff'] = '9'
      ..['ht'] = 2
      ..['vt'] = '3'
      ..['tb'] = 1
      ..['tr'] = 1;
    final changed = cell.copyWith(horizontalAlign: '2', textRotationMode: '1');

    final json = FortuneSheetCodec.cellToJson(cell);
    final changedJson = FortuneSheetCodec.cellToJson(changed);

    expect(cell.hasRawFontFamily, isTrue);
    expect(cell.hasRawHorizontalAlign, isTrue);
    expect(cell.hasRawVerticalAlign, isTrue);
    expect(cell.hasRawTextWrap, isTrue);
    expect(cell.hasRawTextRotationMode, isTrue);
    expect(json['ff'], '2');
    expect(json['ht'], 0);
    expect(json['vt'], '1');
    expect(json['tb'], 2);
    expect(json['tr'], 3);
    expect(changedJson['ff'], '2');
    expect(changedJson['ht'], 2);
    expect(changedJson['vt'], '1');
    expect(changedJson['tb'], 2);
    expect(changedJson['tr'], '1');

    json
      ..['ff'] = '9'
      ..['ht'] = 2
      ..['vt'] = '3'
      ..['tb'] = 1
      ..['tr'] = 1;
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['ff'], '2');
    expect(reexported['ht'], 0);
    expect(reexported['vt'], '1');
    expect(reexported['tb'], 2);
    expect(reexported['tr'], 3);
  });

  test('cellToJson preserves explicit null style option fields', () {
    final source = <String, Object?>{
      'fs': null,
      'ff': null,
      'ht': null,
      'vt': null,
      'tb': null,
      'tr': null,
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['fs'] = 11
      ..['ff'] = 3
      ..['ht'] = 2
      ..['vt'] = 1
      ..['tb'] = '1'
      ..['tr'] = '2';
    final changed = cell.copyWith(
      fontSize: 11,
      fontFamily: '3',
      horizontalAlign: '2',
      verticalAlign: '1',
      textWrap: '1',
      textRotationMode: '2',
    );

    final json = FortuneSheetCodec.cellToJson(cell);
    final changedJson = FortuneSheetCodec.cellToJson(changed);

    expect(cell.hasRawFontSize, isTrue);
    expect(cell.hasRawFontFamily, isTrue);
    expect(cell.hasRawHorizontalAlign, isTrue);
    expect(cell.hasRawVerticalAlign, isTrue);
    expect(cell.hasRawTextWrap, isTrue);
    expect(cell.hasRawTextRotationMode, isTrue);
    expect(json['fs'], isNull);
    expect(json['ff'], isNull);
    expect(json['ht'], isNull);
    expect(json['vt'], isNull);
    expect(json['tb'], isNull);
    expect(json['tr'], isNull);
    expect(changedJson['fs'], 11);
    expect(changedJson['ff'], 3);
    expect(changedJson['ht'], 2);
    expect(changedJson['vt'], 1);
    expect(changedJson['tb'], '1');
    expect(changedJson['tr'], '2');

    json
      ..['fs'] = 11
      ..['ff'] = 3
      ..['ht'] = 2
      ..['vt'] = 1
      ..['tb'] = '1'
      ..['tr'] = '2';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['fs'], isNull);
    expect(reexported['ff'], isNull);
    expect(reexported['ht'], isNull);
    expect(reexported['vt'], isNull);
    expect(reexported['tb'], isNull);
    expect(reexported['tr'], isNull);
  });

  test('cellToJson preserves unchanged raw value and display types', () {
    final numericSource = {'v': 10, 'm': 10};
    final booleanSource = {'v': true, 'm': 'TRUE'};
    final numeric = FortuneSheetCodec.cellFromJson(numericSource);
    final boolean = FortuneSheetCodec.cellFromJson(booleanSource);
    numericSource
      ..['v'] = 11
      ..['m'] = 11;
    booleanSource
      ..['v'] = false
      ..['m'] = 'FALSE';
    final edited = numeric.withEditedValue('11');

    final numericJson = FortuneSheetCodec.cellToJson(numeric);
    final booleanJson = FortuneSheetCodec.cellToJson(boolean);

    expect(numericJson['v'], 10);
    expect(numericJson['m'], 10);
    expect(booleanJson['v'], isTrue);
    expect(booleanJson['m'], 'TRUE');
    expect(FortuneSheetCodec.cellToJson(edited)['v'], '11');
    expect(FortuneSheetCodec.cellToJson(edited).containsKey('m'), isFalse);

    numericJson
      ..['v'] = 12
      ..['m'] = 12;
    booleanJson
      ..['v'] = false
      ..['m'] = 'FALSE';
    final reexportedNumeric = FortuneSheetCodec.cellToJson(numeric);
    final reexportedBoolean = FortuneSheetCodec.cellToJson(boolean);
    expect(reexportedNumeric['v'], 10);
    expect(reexportedNumeric['m'], 10);
    expect(reexportedBoolean['v'], isTrue);
    expect(reexportedBoolean['m'], 'TRUE');
  });

  test(
    'cellToJson does not resurrect stale raw value after copyWith edits',
    () {
      final numeric = FortuneSheetCodec.cellFromJson({'v': 10, 'm': 10});
      final changed = numeric.copyWith(value: '11', displayValue: 'eleven');
      final changedBack = changed.copyWith(value: '10', displayValue: null);

      expect(FortuneSheetCodec.cellToJson(changed)['v'], '11');
      expect(FortuneSheetCodec.cellToJson(changed)['m'], 'eleven');
      expect(FortuneSheetCodec.cellToJson(changedBack)['v'], '10');
      expect(
        FortuneSheetCodec.cellToJson(changedBack).containsKey('m'),
        isFalse,
      );
    },
  );

  test('cellToJson preserves explicit null value and display fields', () {
    final source = <String, Object?>{'v': null, 'm': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['v'] = 'mutated'
      ..['m'] = 'mutated';
    final edited = cell.withEditedValue('text');

    final json = FortuneSheetCodec.cellToJson(cell);
    final editedJson = FortuneSheetCodec.cellToJson(edited);

    expect(cell.hasRawValue, isTrue);
    expect(cell.hasRawDisplayValue, isTrue);
    expect(json.containsKey('v'), isTrue);
    expect(json['v'], isNull);
    expect(json.containsKey('m'), isTrue);
    expect(json['m'], isNull);
    expect(editedJson['v'], 'text');
    expect(editedJson.containsKey('m'), isFalse);

    json
      ..['v'] = 'export-mutated'
      ..['m'] = 'export-mutated';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('v'), isTrue);
    expect(reexported['v'], isNull);
    expect(reexported.containsKey('m'), isTrue);
    expect(reexported['m'], isNull);
  });

  test('cellToJson preserves unchanged raw formula field', () {
    final numericSource = {'f': 123, 'v': 3};
    final numericFormula = FortuneSheetCodec.cellFromJson(numericSource);
    numericSource['f'] = 456;
    final nullSource = <String, Object?>{'f': null, 'v': ''};
    final nullFormula = FortuneSheetCodec.cellFromJson(nullSource);
    nullSource['f'] = '=A1';
    final changed = numericFormula.copyWith(formula: '=B1');
    final changedFromNull = nullFormula.copyWith(formula: '=C1');

    expect(numericFormula.formula, '123');
    expect(numericFormula.rawFormula, 123);
    expect(numericFormula.hasRawFormula, isTrue);
    expect(nullFormula.formula, isNull);
    expect(nullFormula.rawFormula, isNull);
    expect(nullFormula.hasRawFormula, isTrue);
    final numericJson = FortuneSheetCodec.cellToJson(numericFormula);
    final nullJson = FortuneSheetCodec.cellToJson(nullFormula);
    expect(numericJson['f'], 123);
    expect(nullJson.containsKey('f'), isTrue);
    expect(nullJson['f'], isNull);
    expect(FortuneSheetCodec.cellToJson(changed)['f'], '=B1');
    expect(changedFromNull.hasRawFormula, isFalse);
    expect(FortuneSheetCodec.cellToJson(changedFromNull)['f'], '=C1');

    numericJson['f'] = 789;
    nullJson['f'] = '=D1';
    expect(FortuneSheetCodec.cellToJson(numericFormula)['f'], 123);
    final reexportedNull = FortuneSheetCodec.cellToJson(nullFormula);
    expect(reexportedNull.containsKey('f'), isTrue);
    expect(reexportedNull['f'], isNull);
  });

  test('cellToJson preserves explicit null sparkline field', () {
    final source = <String, Object?>{'v': 'spark', 'spl': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source['spl'] = {'type': 'bar'};
    final cleared = cell.withClearedContent();

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.sparkline, isNull);
    expect(cell.rawSparkline, isNull);
    expect(cell.hasSparkline, isTrue);
    expect(cell.hasRawSparkline, isTrue);
    expect(json.containsKey('spl'), isTrue);
    expect(json['spl'], isNull);
    expect(cleared.hasSparkline, isFalse);
    expect(cleared.hasRawSparkline, isFalse);
    expect(FortuneSheetCodec.cellToJson(cleared).containsKey('spl'), isFalse);

    json['spl'] = {'type': 'line'};
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('spl'), isTrue);
    expect(reexported['spl'], isNull);
  });

  test('cellFromJson snapshots nested sparkline metadata', () {
    final source = <String, Object?>{
      'v': 'spark',
      'spl': <String, Object?>{
        'type': 'line',
        'data': [1, 2],
        'options': <String, Object?>{
          'markers': [
            {'color': 'red'},
          ],
        },
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceSparkline = source['spl']! as Map;
    (sourceSparkline['data']! as List).add(3);
    final sourceOptions = sourceSparkline['options']! as Map;
    final sourceMarkers = sourceOptions['markers']! as List;
    (sourceMarkers.first as Map)['color'] = 'blue';

    expect(cell.sparkline, {
      'type': 'line',
      'data': [1, 2],
      'options': {
        'markers': [
          {'color': 'red'},
        ],
      },
    });
    expect(cell.rawSparkline, cell.sparkline);
    expect(cell.hasRawSparkline, isTrue);

    final json = FortuneSheetCodec.cellToJson(cell);
    final sparkline = json['spl']! as Map;
    (sparkline['data']! as List).add(4);
    final options = sparkline['options']! as Map;
    final markers = options['markers']! as List;
    (markers.first as Map)['color'] = 'green';

    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['spl'], {
      'type': 'line',
      'data': [1, 2],
      'options': {
        'markers': [
          {'color': 'red'},
        ],
      },
    });

    final changed = cell.copyWith(sparkline: {'type': 'bar'});
    expect(changed.hasRawSparkline, isFalse);
    expect(FortuneSheetCodec.cellToJson(changed)['spl'], {'type': 'bar'});
  });

  test('cellFromJson recognizes sparkline type aliases', () {
    final chartTypeSource = <String, Object?>{
      'v': 'spark',
      'spl': <String, Object?>{
        'chartType': 'BAR',
        'data': [1, 2, 3],
      },
    };
    final nameSource = <String, Object?>{
      'v': 'spark',
      'spl': <String, Object?>{
        'name': 'column',
        'data': [5, 6, 7],
      },
    };

    final chartTypeCell = FortuneSheetCodec.cellFromJson(chartTypeSource);
    final nameCell = FortuneSheetCodec.cellFromJson(nameSource);
    ((chartTypeSource['spl']! as Map)['data']! as List).add(4);
    ((nameSource['spl']! as Map)['data']! as List).add(8);

    expect(fortuneSparklineType(chartTypeCell.sparkline), 'bar');
    expect(fortuneSparklineType(nameCell.sparkline), 'column');
    final chartTypeJson = FortuneSheetCodec.cellToJson(chartTypeCell);
    final nameJson = FortuneSheetCodec.cellToJson(nameCell);
    expect(chartTypeJson['spl'], {
      'chartType': 'BAR',
      'data': [1, 2, 3],
    });
    expect(nameJson['spl'], {
      'name': 'column',
      'data': [5, 6, 7],
    });

    ((chartTypeJson['spl']! as Map)['data']! as List).add(4);
    ((nameJson['spl']! as Map)['data']! as List).add(8);
    expect(FortuneSheetCodec.cellToJson(chartTypeCell)['spl'], {
      'chartType': 'BAR',
      'data': [1, 2, 3],
    });
    expect(FortuneSheetCodec.cellToJson(nameCell)['spl'], {
      'name': 'column',
      'data': [5, 6, 7],
    });
  });

  test('sparkline values read supported value aliases', () {
    expect(fortuneSparklineValues({'data': '1, 2 3'}), [1.0, 2.0, 3.0]);
    expect(
      fortuneSparklineValues({
        'values': [4, '5 6'],
      }),
      [4.0, 5.0, 6.0],
    );
    expect(fortuneSparklineValues({'value': 7}), [7.0]);
    expect(
      fortuneSparklineValues({
        'range': [
          [8, '9'],
          {'data': 10},
        ],
      }),
      [8.0, 9.0, 10.0],
    );
  });

  test('sparkline children read compose aliases', () {
    final line = {
      'chartType': 'line',
      'data': [1, 2],
    };
    final pie = {
      'name': 'pie',
      'values': [3, 4],
    };

    expect(
      fortuneSparklineChildren({
        'type': 'compose',
        'sparklines': [
          line,
          [5, 6],
        ],
      }),
      [
        line,
        {
          'type': 'line',
          'data': [5, 6],
        },
      ],
    );
    expect(
      fortuneSparklineChildren({
        'type': 'composesplines',
        'items': [pie],
      }),
      [pie],
    );
  });

  test('sparkline points scale values into chart rect', () {
    expect(
      fortuneSparklinePoints(const [
        2,
        4,
        6,
      ], const Rect.fromLTWH(10, 20, 90, 60)),
      const [Offset(10, 80), Offset(55, 50), Offset(100, 20)],
    );
    expect(
      fortuneSparklinePoints(const [5, 5], const Rect.fromLTWH(10, 20, 90, 60)),
      const [Offset(10, 50), Offset(100, 50)],
    );
    expect(
      fortuneSparklinePoints(const [0, 0], const Rect.fromLTWH(10, 20, 90, 60)),
      const [Offset(10, 50), Offset(100, 50)],
    );
    expect(
      fortuneSparklinePoints(const [1], const Rect.fromLTWH(0, 0, 10, 10)),
      isEmpty,
    );
    expect(fortuneSparklinePoints(const [1, 2], Rect.zero), isEmpty);
  });

  test('cellToJson preserves raw cell type fields', () {
    final source = <String, Object?>{
      'v': 'typed',
      'ct': <String, Object?>{'fa': 123, 't': null, 's': null},
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceType = source['ct']! as Map;
    sourceType
      ..['fa'] = 'mutated'
      ..['t'] = 's'
      ..['s'] = [
        {'v': 'mutated'},
      ];
    final edited = cell.copyWith(
      cellType: const FortuneCellType(format: 'General', type: 'n'),
    );

    expect(cell.cellType?.format, '123');
    expect(cell.cellType?.rawFormat, 123);
    expect(cell.cellType?.hasRawFormat, isTrue);
    expect(cell.cellType?.type, isNull);
    expect(cell.cellType?.hasRawType, isTrue);
    expect(cell.cellType?.style, isNull);
    expect(cell.cellType?.hasRawStyle, isTrue);

    final json = FortuneSheetCodec.cellToJson(cell)['ct']! as Map;
    final editedJson = FortuneSheetCodec.cellToJson(edited)['ct']! as Map;
    expect(json['fa'], 123);
    expect(json.containsKey('t'), isTrue);
    expect(json['t'], isNull);
    expect(json.containsKey('s'), isTrue);
    expect(json['s'], isNull);
    expect(editedJson, {'fa': 'General', 't': 'n'});

    json
      ..['fa'] = 'mutated'
      ..['t'] = 's'
      ..['s'] = [
        {'v': 'mutated'},
      ];
    final reexported = FortuneSheetCodec.cellToJson(cell)['ct']! as Map;
    expect(reexported['fa'], 123);
    expect(reexported.containsKey('t'), isTrue);
    expect(reexported['t'], isNull);
    expect(reexported.containsKey('s'), isTrue);
    expect(reexported['s'], isNull);
  });

  test('cellFromJson snapshots nested cell type extra fields', () {
    final source = <String, Object?>{
      'v': 'typed',
      'ct': <String, Object?>{
        'fa': 'General',
        'customTypeMeta': {
          'items': [
            {'value': 'original'},
          ],
        },
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final type = source['ct']! as Map;
    final meta = type['customTypeMeta']! as Map;
    final items = meta['items']! as List;
    (items.first as Map)['value'] = 'changed';

    expect(cell.cellType?.extraFields['customTypeMeta'], {
      'items': [
        {'value': 'original'},
      ],
    });

    final json = FortuneSheetCodec.cellToJson(cell);
    final jsonMeta = (json['ct']! as Map)['customTypeMeta']! as Map;
    ((jsonMeta['items']! as List).first as Map)['value'] = 'export changed';

    expect(cell.cellType?.extraFields['customTypeMeta'], {
      'items': [
        {'value': 'original'},
      ],
    });

    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect((reexported['ct']! as Map)['customTypeMeta'], {
      'items': [
        {'value': 'original'},
      ],
    });
  });

  test('cellFromJson snapshots nested merge extra fields', () {
    final source = <String, Object?>{
      'v': 'merged',
      'mc': <String, Object?>{
        'r': 0,
        'c': 0,
        'rs': 2,
        'cs': 3,
        'customMergeMeta': {
          'items': [
            {'value': 'original'},
          ],
        },
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final merge = source['mc']! as Map;
    final meta = merge['customMergeMeta']! as Map;
    ((meta['items']! as List).first as Map)['value'] = 'changed';

    expect(cell.merge?.extraFields['customMergeMeta'], {
      'items': [
        {'value': 'original'},
      ],
    });

    final json = FortuneSheetCodec.cellToJson(cell);
    final jsonMerge = json['mc']! as Map;
    final jsonMeta = jsonMerge['customMergeMeta']! as Map;
    ((jsonMeta['items']! as List).first as Map)['value'] = 'export changed';

    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect((reexported['mc']! as Map)['customMergeMeta'], {
      'items': [
        {'value': 'original'},
      ],
    });
  });

  test('cellToJson preserves non-string raw cell type values', () {
    final source = <String, Object?>{
      'v': 'typed',
      'ct': <String, Object?>{'t': 456},
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    (source['ct']! as Map)['t'] = 789;
    final changed = cell.copyWith(cellType: cell.cellType?.copyWith(type: 'n'));
    final json = FortuneSheetCodec.cellToJson(cell)['ct']! as Map;
    final changedJson = FortuneSheetCodec.cellToJson(changed)['ct']! as Map;

    expect(cell.cellType?.type, '456');
    expect(cell.cellType?.rawType, 456);
    expect(cell.cellType?.hasRawType, isTrue);
    expect(json['t'], 456);
    expect(changedJson['t'], 'n');

    json['t'] = 789;
    expect((FortuneSheetCodec.cellToJson(cell)['ct']! as Map)['t'], 456);
  });

  test('cellToJson preserves non-inline raw cell type styles', () {
    final source = <String, Object?>{
      'v': 'styled',
      'ct': <String, Object?>{
        't': 'n',
        's': <String, Object?>{
          'fa': 'General',
          'ff': 2,
          'customStyleMeta': {
            'source': 'raw',
            'items': [
              {'value': 'original'},
            ],
          },
        },
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    final sourceType = source['ct']! as Map;
    final sourceStyle = sourceType['s']! as Map;
    final sourceMeta = sourceStyle['customStyleMeta']! as Map;
    sourceMeta['source'] = 'source mutated';
    ((sourceMeta['items']! as List).first as Map)['value'] = 'changed';
    final edited = cell.withEditedValue('changed');

    expect(cell.cellType?.style, isA<Map>());
    expect(cell.cellType?.hasRawStyle, isTrue);
    expect((cell.cellType?.style! as Map)['customStyleMeta'], {
      'source': 'raw',
      'items': [
        {'value': 'original'},
      ],
    });

    final json = FortuneSheetCodec.cellToJson(cell)['ct']! as Map;
    final editedJson = FortuneSheetCodec.cellToJson(edited)['ct']! as Map;
    expect(json['s'], {
      'fa': 'General',
      'ff': 2,
      'customStyleMeta': {
        'source': 'raw',
        'items': [
          {'value': 'original'},
        ],
      },
    });
    expect(editedJson['s'], json['s']);

    final exportedStyle = json['s']! as Map;
    final exportedMeta = exportedStyle['customStyleMeta']! as Map;
    exportedMeta['source'] = 'export mutated';
    ((exportedMeta['items']! as List).first as Map)['value'] = 'exported';

    final reexported = FortuneSheetCodec.cellToJson(cell)['ct']! as Map;
    expect(reexported['s'], {
      'fa': 'General',
      'ff': 2,
      'customStyleMeta': {
        'source': 'raw',
        'items': [
          {'value': 'original'},
        ],
      },
    });
  });

  test('cellToJson preserves explicit empty cell type object', () {
    final source = <String, Object?>{'v': 'typed', 'ct': <String, Object?>{}};

    final cell = FortuneSheetCodec.cellFromJson(source);
    (source['ct']! as Map)['t'] = 'n';

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.cellType, isNotNull);
    expect(json.containsKey('ct'), isTrue);
    expect(json['ct'], isEmpty);

    (json['ct']! as Map)['t'] = 'n';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('ct'), isTrue);
    expect(reexported['ct'], isEmpty);
  });

  test('cellToJson preserves unchanged raw numeric rotation type', () {
    final source = {'v': 'rotated', 'rt': 45};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source['rt'] = 30;
    final editedRotation = cell.copyWith(textRotation: '30');

    final json = FortuneSheetCodec.cellToJson(cell);
    expect(json['rt'], 45);
    expect(FortuneSheetCodec.cellToJson(editedRotation)['rt'], '30');

    json['rt'] = 15;
    expect(FortuneSheetCodec.cellToJson(cell)['rt'], 45);
  });

  test('cellToJson preserves explicit null rotation field', () {
    final source = <String, Object?>{'v': 'rotated', 'rt': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source['rt'] = 45;
    final editedRotation = cell.copyWith(textRotation: '30');

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.hasRawTextRotation, isTrue);
    expect(json.containsKey('rt'), isTrue);
    expect(json['rt'], isNull);
    expect(FortuneSheetCodec.cellToJson(editedRotation)['rt'], '30');

    json['rt'] = 45;
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('rt'), isTrue);
    expect(reexported['rt'], isNull);
  });

  test('cellToJson preserves explicit null text rotation mode field', () {
    final source = <String, Object?>{'v': 'rotated', 'tr': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source['tr'] = '2';
    final editedMode = cell.copyWith(textRotationMode: '1');

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.hasRawTextRotationMode, isTrue);
    expect(json.containsKey('tr'), isTrue);
    expect(json['tr'], isNull);
    expect(FortuneSheetCodec.cellToJson(editedMode)['tr'], '1');

    json['tr'] = '2';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('tr'), isTrue);
    expect(reexported['tr'], isNull);
  });

  test('cellToJson preserves unchanged raw color strings', () {
    final source = {'v': 'color', 'bg': 'rgb(255, 242, 204)', 'fc': '#C00000'};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['bg'] = '#ffffff'
      ..['fc'] = '#000000';
    final editedValue = cell.withEditedValue('new');
    final editedColor = cell.copyWith(background: const Color(0xffffffff));

    final json = FortuneSheetCodec.cellToJson(cell);
    expect(json['bg'], 'rgb(255, 242, 204)');
    expect(json['fc'], '#C00000');
    expect(
      FortuneSheetCodec.cellToJson(editedValue)['bg'],
      'rgb(255, 242, 204)',
    );
    expect(FortuneSheetCodec.cellToJson(editedValue)['fc'], '#C00000');
    expect(FortuneSheetCodec.cellToJson(editedColor)['bg'], '#ffffff');
    expect(FortuneSheetCodec.cellToJson(editedColor)['fc'], '#C00000');

    json
      ..['bg'] = '#ffffff'
      ..['fc'] = '#000000';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['bg'], 'rgb(255, 242, 204)');
    expect(reexported['fc'], '#C00000');
  });

  test('cellFromJson expands short hex color strings', () {
    final source = {'v': 'color', 'bg': '#f0c', 'fc': '#06a'};
    final cell = FortuneSheetCodec.cellFromJson(source);
    source
      ..['bg'] = '#ffffff'
      ..['fc'] = '#000000';

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.background, const Color(0xffff00cc));
    expect(cell.foreground, const Color(0xff0066aa));
    expect(json['bg'], '#f0c');
    expect(json['fc'], '#06a');

    json
      ..['bg'] = '#ffffff'
      ..['fc'] = '#000000';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported['bg'], '#f0c');
    expect(reexported['fc'], '#06a');
  });

  test('cellToJson preserves explicit null foreground color field', () {
    final source = <String, Object?>{'v': 'color', 'fc': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source['fc'] = '#188038';
    final editedColor = cell.copyWith(foreground: const Color(0xff188038));

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.hasRawForeground, isTrue);
    expect(json.containsKey('fc'), isTrue);
    expect(json['fc'], isNull);
    expect(FortuneSheetCodec.cellToJson(editedColor)['fc'], '#188038');

    json['fc'] = '#188038';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('fc'), isTrue);
    expect(reexported['fc'], isNull);
  });

  test('cellToJson preserves explicit null background color field', () {
    final source = <String, Object?>{'v': 'color', 'bg': null};

    final cell = FortuneSheetCodec.cellFromJson(source);
    source['bg'] = '#fff2cc';
    final editedColor = cell.copyWith(background: const Color(0xfffff2cc));

    final json = FortuneSheetCodec.cellToJson(cell);

    expect(cell.hasRawBackground, isTrue);
    expect(json.containsKey('bg'), isTrue);
    expect(json['bg'], isNull);
    expect(FortuneSheetCodec.cellToJson(editedColor)['bg'], '#fff2cc');

    json['bg'] = '#fff2cc';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    expect(reexported.containsKey('bg'), isTrue);
    expect(reexported['bg'], isNull);
  });

  test('cellToJson preserves unchanged inline run raw color strings', () {
    final firstRun = {'v': 'Hello', 'fc': 'rgb(24, 128, 56)'};
    final secondRun = {'v': ' World', 'fc': '#C00000'};
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {
        't': 'inlineStr',
        's': [firstRun, secondRun],
      },
    });
    firstRun['fc'] = '#000000';
    secondRun['fc'] = '#ffffff';

    final json = FortuneSheetCodec.cellToJson(cell);
    final runs = (json['ct']! as Map)['s']! as List;

    expect((runs[0] as Map)['fc'], 'rgb(24, 128, 56)');
    expect((runs[1] as Map)['fc'], '#C00000');

    (runs[0] as Map)['fc'] = '#000000';
    (runs[1] as Map)['fc'] = '#ffffff';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRuns = (reexported['ct']! as Map)['s']! as List;
    expect((reexportedRuns[0] as Map)['fc'], 'rgb(24, 128, 56)');
    expect((reexportedRuns[1] as Map)['fc'], '#C00000');
  });

  test('cellToJson preserves inline run raw style values', () {
    final sourceRun = {
      'v': 'Styled',
      'bl': 0,
      'it': '1',
      'cl': false,
      'un': '0',
      'fs': '12',
      'ff': '2',
    };
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {
        't': 'inlineStr',
        's': [sourceRun],
      },
    });
    sourceRun
      ..['bl'] = 1
      ..['it'] = 0
      ..['cl'] = true
      ..['un'] = 1
      ..['fs'] = '24'
      ..['ff'] = '9';

    final json = FortuneSheetCodec.cellToJson(cell);
    final run = (((json['ct']! as Map)['s']! as List).single) as Map;
    final parsedRun = cell.inlineRuns!.single;

    expect(parsedRun.hasRawBold, isTrue);
    expect(parsedRun.hasRawItalic, isTrue);
    expect(parsedRun.hasRawStrikeThrough, isTrue);
    expect(parsedRun.hasRawUnderline, isTrue);
    expect(parsedRun.hasRawFontSize, isTrue);
    expect(parsedRun.hasRawFontFamily, isTrue);
    expect(run['bl'], 0);
    expect(run['it'], '1');
    expect(run['cl'], isFalse);
    expect(run['un'], '0');
    expect(run['fs'], '12');
    expect(run['ff'], '2');

    run
      ..['bl'] = 1
      ..['it'] = 0
      ..['cl'] = true
      ..['un'] = 1
      ..['fs'] = '24'
      ..['ff'] = '9';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRun =
        (((reexported['ct']! as Map)['s']! as List).single) as Map;
    expect(reexportedRun['bl'], 0);
    expect(reexportedRun['it'], '1');
    expect(reexportedRun['cl'], isFalse);
    expect(reexportedRun['un'], '0');
    expect(reexportedRun['fs'], '12');
    expect(reexportedRun['ff'], '2');
  });

  test('cellToJson preserves inline run raw text values and empty runs', () {
    final sourceRuns = <Map<String, Object?>>[
      {'v': 123, 'bl': 1},
      {'v': '', 'it': 1},
      {'v': null, 'un': 1},
    ];
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {'t': 'inlineStr', 's': sourceRuns},
    });
    sourceRuns[0]['v'] = 'mutated source';
    sourceRuns[1]['v'] = 'mutated source';
    sourceRuns[2]['v'] = 'mutated source';

    final json = FortuneSheetCodec.cellToJson(cell);
    final runs = (json['ct']! as Map)['s']! as List;

    expect(cell.inlineRuns, hasLength(3));
    expect(cell.renderedText, '123');
    expect((runs[0] as Map)['v'], 123);
    expect((runs[1] as Map).containsKey('v'), isTrue);
    expect((runs[1] as Map)['v'], '');
    expect((runs[2] as Map).containsKey('v'), isTrue);
    expect((runs[2] as Map)['v'], isNull);

    (runs[0] as Map)['v'] = 'mutated export';
    (runs[1] as Map)['v'] = 'mutated export';
    (runs[2] as Map)['v'] = 'mutated export';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRuns = (reexported['ct']! as Map)['s']! as List;
    expect((reexportedRuns[0] as Map)['v'], 123);
    expect((reexportedRuns[1] as Map).containsKey('v'), isTrue);
    expect((reexportedRuns[1] as Map)['v'], '');
    expect((reexportedRuns[2] as Map).containsKey('v'), isTrue);
    expect((reexportedRuns[2] as Map)['v'], isNull);
  });

  test('cellFromJson snapshots nested inline run raw fields', () {
    final runText = {
      'items': [
        {'value': 'run text'},
      ],
    };
    final runForeground = {
      'items': [
        {'value': 'run foreground'},
      ],
    };
    final source = {
      'ct': {
        't': 'inlineStr',
        's': [
          {'v': runText, 'fc': runForeground},
        ],
      },
    };

    final cell = FortuneSheetCodec.cellFromJson(source);
    ((runText['items']! as List).single as Map)['value'] = 'mutated source';
    ((runForeground['items']! as List).single as Map)['value'] =
        'mutated source';

    final exported = FortuneSheetCodec.cellToJson(cell);
    final exportedRun =
        (((exported['ct']! as Map)['s']! as List).single) as Map;
    ((exportedRun['v']! as Map)['items']! as List).single['value'] =
        'mutated export';
    ((exportedRun['fc']! as Map)['items']! as List).single['value'] =
        'mutated export';

    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRun =
        (((reexported['ct']! as Map)['s']! as List).single) as Map;
    expect(((reexportedRun['v']! as Map)['items']! as List).single, {
      'value': 'run text',
    });
    expect(((reexportedRun['fc']! as Map)['items']! as List).single, {
      'value': 'run foreground',
    });
    expect(
      ((cell.inlineRuns!.single.rawText! as Map)['items']! as List).single,
      {'value': 'run text'},
    );
    expect(
      ((cell.inlineRuns!.single.rawForeground! as Map)['items']! as List)
          .single,
      {'value': 'run foreground'},
    );
  });

  test('cellToJson preserves multiline inline run boundaries', () {
    final sourceRun = {'v': 'Line 1\nLine 2', 'bl': 1};
    final cell = FortuneSheetCodec.cellFromJson({
      'ct': {
        't': 'inlineStr',
        's': [sourceRun],
      },
    });
    sourceRun['v'] = 'Line 1 Line 2';

    final json = FortuneSheetCodec.cellToJson(cell);
    final runs = (json['ct']! as Map)['s']! as List;
    final run = runs.single as Map;

    expect(cell.renderedText, 'Line 1\nLine 2');
    expect(run['v'], 'Line 1\nLine 2');
    expect(run['bl'], 1);

    run['v'] = 'Line 1 Line 2';
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedRun = ((reexported['ct']! as Map)['s']! as List).single;
    expect((reexportedRun as Map)['v'], 'Line 1\nLine 2');
    expect(reexportedRun['bl'], 1);
  });

  test('sheetToJson preserves unchanged borderInfo raw color strings', () {
    final borderSource = {
      'rangeType': 'range',
      'borderType': 'border-all',
      'color': 'rgb(1, 136, 251)',
      'style': 2,
      'range': [
        {
          'row': [0, 1],
          'column': [0, 1],
        },
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'borderInfo': [borderSource],
      },
    });
    borderSource['color'] = '#c00000';

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final borderInfo = config['borderInfo']! as List;
    final exportedBorder = borderInfo.first as Map;

    expect(sheet.borderInfo.first.rawColor, 'rgb(1, 136, 251)');
    expect(sheet.borderInfo.first.hasRawColor, isTrue);
    expect(exportedBorder['color'], 'rgb(1, 136, 251)');

    exportedBorder['color'] = '#c00000';
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final reexportedBorder =
        (reexportedConfig['borderInfo']! as List).single as Map;
    expect(reexportedBorder['color'], 'rgb(1, 136, 251)');
  });

  test('sheetToJson preserves unchanged border range raw coordinates', () {
    final rangeSource = {
      'row': ['0', 1],
      'column': [0, '2'],
      'row_focus': '0',
      'column_focus': 2,
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'borderInfo': [
          {
            'rangeType': 'range',
            'borderType': 'border-all',
            'color': '#0188fb',
            'style': 1,
            'range': [rangeSource],
          },
        ],
      },
    });
    rangeSource
      ..['row'] = [9, 9]
      ..['column'] = [9, 9]
      ..['row_focus'] = 9
      ..['column_focus'] = '9';

    final changed = sheet.copyWith(
      borderInfo: [
        FortuneBorderInfo(
          rangeType: sheet.borderInfo.single.rangeType,
          borderType: sheet.borderInfo.single.borderType,
          color: sheet.borderInfo.single.color,
          style: sheet.borderInfo.single.style,
          ranges: [
            FortuneRange(
              rowStart: 1,
              rowEnd: 1,
              columnStart: 0,
              columnEnd: 2,
              rowFocus: 0,
              columnFocus: 2,
            ),
          ],
          rawColor: sheet.borderInfo.single.rawColor,
          hasRawColor: sheet.borderInfo.single.hasRawColor,
        ),
      ],
    );

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;
    final range =
        (((config['borderInfo']! as List).single as Map)['range']! as List)
                .single
            as Map;
    final changedRange =
        (((changedConfig['borderInfo']! as List).single as Map)['range']!
                    as List)
                .single
            as Map;

    expect(sheet.borderInfo.single.ranges.single.hasRawRow, isTrue);
    expect(sheet.borderInfo.single.ranges.single.rawRow, ['0', 1]);
    expect(range['row'], ['0', 1]);
    expect(range['column'], [0, '2']);
    expect(range['row_focus'], '0');
    expect(range['column_focus'], 2);
    expect(changedRange['row'], [1, 1]);
    expect(changedRange['column'], [0, 2]);

    range
      ..['row'] = [9, 9]
      ..['column'] = [9, 9]
      ..['row_focus'] = 9
      ..['column_focus'] = '9';
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final reexportedRange =
        (((reexportedConfig['borderInfo']! as List).single as Map)['range']!
                    as List)
                .single
            as Map;
    expect(reexportedRange['row'], ['0', 1]);
    expect(reexportedRange['column'], [0, '2']);
    expect(reexportedRange['row_focus'], '0');
    expect(reexportedRange['column_focus'], 2);
  });

  test('sheetToJson preserves unchanged raw borderInfo list', () {
    final rangeEntry = <String, Object?>{
      'row': ['0', 1],
      'column': [0, '1'],
    };
    final borderEntry = <String, Object?>{
      'rangeType': 'range',
      'borderType': 'border-all',
      'color': 'rgb(1, 136, 251)',
      'style': '2',
      'range': [rangeEntry],
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'borderInfo': [borderEntry],
      },
    });
    borderEntry
      ..['color'] = '#c00000'
      ..['style'] = 4;
    (rangeEntry['row']! as List).add(99);
    final emptyRaw = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'config': {'borderInfo': null},
    });
    final changed = sheet.copyWith(
      borderInfo: [
        FortuneBorderInfo(
          rangeType: sheet.borderInfo.single.rangeType,
          borderType: sheet.borderInfo.single.borderType,
          color: const Color(0xffc00000),
          style: sheet.borderInfo.single.style,
          ranges: sheet.borderInfo.single.ranges,
        ),
      ],
    );

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final emptyConfig =
        FortuneSheetCodec.sheetToJson(emptyRaw)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.rawBorderInfo, [
      {
        'rangeType': 'range',
        'borderType': 'border-all',
        'color': 'rgb(1, 136, 251)',
        'style': '2',
        'range': [
          {
            'row': ['0', 1],
            'column': [0, '1'],
          },
        ],
      },
    ]);
    expect(sheet.hasRawBorderInfo, isTrue);
    expect(config['borderInfo'], [
      {
        'rangeType': 'range',
        'borderType': 'border-all',
        'color': 'rgb(1, 136, 251)',
        'style': '2',
        'range': [
          {
            'row': ['0', 1],
            'column': [0, '1'],
          },
        ],
      },
    ]);
    final exportedBorder = (config['borderInfo']! as List).single as Map;
    exportedBorder['color'] = '#c00000';
    (((exportedBorder['range']! as List).single as Map)['row']! as List).add(
      99,
    );
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['borderInfo'], [
      {
        'rangeType': 'range',
        'borderType': 'border-all',
        'color': 'rgb(1, 136, 251)',
        'style': '2',
        'range': [
          {
            'row': ['0', 1],
            'column': [0, '1'],
          },
        ],
      },
    ]);
    expect(emptyConfig.containsKey('borderInfo'), isTrue);
    expect(emptyConfig['borderInfo'], isNull);
    expect(
      ((changedConfig['borderInfo']! as List).single as Map)['color'],
      '#c00000',
    );
  });

  test('sheetToJson preserves unchanged frozen pane raw focus fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'frozen': {
        'type': 'rangeBoth',
        'range': {'row_focus': '2', 'column_focus': 1},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceFrozen = source['frozen']! as Map;
    final sourceRange = sourceFrozen['range']! as Map;
    sourceRange
      ..['row_focus'] = '99'
      ..['column_focus'] = 9;
    final changed = sheet.copyWith(
      frozen: FortuneFrozenPane(
        type: sheet.frozen!.type,
        rowFocus: 3,
        columnFocus: sheet.frozen!.columnFocus,
        rawColumnFocus: sheet.frozen!.rawColumnFocus,
        hasRawColumnFocus: sheet.frozen!.hasRawColumnFocus,
      ),
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);
    final range = (json['frozen']! as Map)['range']! as Map;
    final changedRange = (changedJson['frozen']! as Map)['range']! as Map;

    expect(sheet.frozen?.rawRowFocus, '2');
    expect(sheet.frozen?.hasRawRowFocus, isTrue);
    expect(sheet.frozen?.rawColumnFocus, 1);
    expect(sheet.frozen?.hasRawColumnFocus, isTrue);
    expect(range['row_focus'], '2');
    expect(range['column_focus'], 1);
    expect(changedRange['row_focus'], 3);
    expect(changedRange['column_focus'], 1);

    range
      ..['row_focus'] = '99'
      ..['column_focus'] = 9;
    final reexportedRange =
        (FortuneSheetCodec.sheetToJson(sheet)['frozen']! as Map)['range']!
            as Map;
    expect(reexportedRange['row_focus'], '2');
    expect(reexportedRange['column_focus'], 1);
  });

  test('sheetToJson preserves unchanged raw frozen object', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'frozen': {
        'type': 'rangeBoth',
        'range': {'row_focus': '2', 'column_focus': 1},
        'customFrozenMeta': {'source': 'fixture'},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceFrozen = source['frozen']! as Map;
    sourceFrozen['customFrozenMeta'] = {'source': 'source-mutated'};
    (sourceFrozen['range']! as Map)['row_focus'] = '99';
    final nullFrozen = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'frozen': null,
    });
    final invalidFrozen = FortuneSheetCodec.sheetFromJson({
      'id': 's3',
      'name': 'Sheet3',
      'frozen': {'range': {}},
    });
    final changed = sheet.copyWith(
      frozen: FortuneFrozenPane(
        type: sheet.frozen!.type,
        rowFocus: 3,
        columnFocus: sheet.frozen!.columnFocus,
        extraFields: sheet.frozen!.extraFields,
        rangeExtraFields: sheet.frozen!.rangeExtraFields,
      ),
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(json['frozen'], {
      'type': 'rangeBoth',
      'range': {'row_focus': '2', 'column_focus': 1},
      'customFrozenMeta': {'source': 'fixture'},
    });
    final exportedFrozen = json['frozen']! as Map;
    exportedFrozen['customFrozenMeta'] = {'source': 'export-mutated'};
    (exportedFrozen['range']! as Map)['row_focus'] = '99';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['frozen'], {
      'type': 'rangeBoth',
      'range': {'row_focus': '2', 'column_focus': 1},
      'customFrozenMeta': {'source': 'fixture'},
    });
    expect(FortuneSheetCodec.sheetToJson(nullFrozen)['frozen'], isNull);
    expect(FortuneSheetCodec.sheetToJson(invalidFrozen)['frozen'], {
      'range': {},
    });
    expect(changedJson['frozen'], {
      'customFrozenMeta': {'source': 'fixture'},
      'type': 'rangeBoth',
      'range': {'row_focus': 3, 'column_focus': 1},
    });
  });

  test('sheetToJson writes frozen range metadata without focus fields', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      frozen: FortuneFrozenPane(
        type: 'rangeBoth',
        rangeExtraFields: {
          'customRangeMeta': {'source': 'manual'},
        },
      ),
    );

    final frozen = FortuneSheetCodec.sheetToJson(sheet)['frozen']! as Map;

    expect(frozen, {
      'type': 'rangeBoth',
      'range': {
        'customRangeMeta': {'source': 'manual'},
      },
    });
  });

  test('sheetToJson preserves explicit showGridLines raw flag', () {
    final source = {'id': 's1', 'name': 'Sheet1', 'showGridLines': '1'};
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source['showGridLines'] = '0';
    final nullSheet = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'showGridLines': null,
    });
    final changed = sheet.copyWith(showGridLines: false);
    final defaultSheet = FortuneSheet(id: 's3', name: 'Sheet3');
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.showGridLines, isTrue);
    expect(sheet.rawShowGridLines, '1');
    expect(sheet.hasRawShowGridLines, isTrue);
    expect(json['showGridLines'], '1');
    expect(nullSheet.showGridLines, isTrue);
    expect(nullSheet.hasRawShowGridLines, isTrue);
    expect(FortuneSheetCodec.sheetToJson(nullSheet)['showGridLines'], isNull);
    expect(FortuneSheetCodec.sheetToJson(changed)['showGridLines'], 0);
    expect(
      FortuneSheetCodec.sheetToJson(defaultSheet).containsKey('showGridLines'),
      isFalse,
    );

    json['showGridLines'] = '0';
    expect(FortuneSheetCodec.sheetToJson(sheet)['showGridLines'], '1');
  });

  test('sheetToJson preserves raw sheet color field', () {
    final source = {'id': 's1', 'name': 'Sheet1', 'color': 123};
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source['color'] = 456;
    final nullSheet = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'color': null,
    });
    final changed = sheet.copyWith(color: '#188038');
    final manual = FortuneSheet(id: 's3', name: 'Sheet3', color: '#c00000');
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.color, '123');
    expect(sheet.rawColor, 123);
    expect(sheet.hasRawColor, isTrue);
    expect(json['color'], 123);
    expect(nullSheet.color, isNull);
    expect(nullSheet.hasRawColor, isTrue);
    expect(
      FortuneSheetCodec.sheetToJson(nullSheet).containsKey('color'),
      isTrue,
    );
    expect(FortuneSheetCodec.sheetToJson(nullSheet)['color'], isNull);
    expect(FortuneSheetCodec.sheetToJson(changed)['color'], '#188038');
    expect(FortuneSheetCodec.sheetToJson(manual)['color'], '#c00000');

    json['color'] = 456;
    expect(FortuneSheetCodec.sheetToJson(sheet)['color'], 123);
  });

  test('sheetToJson preserves raw sheet id and name fields', () {
    final source = {'id': 123, 'name': 456};
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['id'] = 789
      ..['name'] = 999;
    final nullSheet = FortuneSheetCodec.sheetFromJson({
      'id': null,
      'name': null,
      'order': 7,
    });
    final changed = sheet.copyWith(id: 's2', name: 'Sheet2');
    final manual = FortuneSheet(id: 's3', name: 'Sheet3');

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final nullJson = FortuneSheetCodec.sheetToJson(nullSheet);

    expect(sheet.id, '123');
    expect(sheet.rawId, 123);
    expect(sheet.hasRawId, isTrue);
    expect(sheet.name, '456');
    expect(sheet.rawName, 456);
    expect(sheet.hasRawName, isTrue);
    expect(json['id'], 123);
    expect(json['name'], 456);
    expect(nullSheet.id, 'sheet_7');
    expect(nullSheet.name, 'Sheet');
    expect(nullJson.containsKey('id'), isTrue);
    expect(nullJson['id'], isNull);
    expect(nullJson.containsKey('name'), isTrue);
    expect(nullJson['name'], isNull);
    expect(FortuneSheetCodec.sheetToJson(changed)['id'], 's2');
    expect(FortuneSheetCodec.sheetToJson(changed)['name'], 'Sheet2');
    expect(FortuneSheetCodec.sheetToJson(manual)['id'], 's3');
    expect(FortuneSheetCodec.sheetToJson(manual)['name'], 'Sheet3');

    json
      ..['id'] = 789
      ..['name'] = 999;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['id'], 123);
    expect(reexported['name'], 456);
  });

  test('sheetToJson preserves explicit empty and null config fields', () {
    final emptyConfigSource = {'id': 's1', 'name': 'Sheet1', 'config': {}};
    final emptyConfigSheet = FortuneSheetCodec.sheetFromJson(emptyConfigSource);
    (emptyConfigSource['config']! as Map)['authority'] = {'sheet': 1};
    final nullConfigSource = <String, Object?>{
      'id': 's2',
      'name': 'Sheet2',
      'config': null,
    };
    final nullConfigSheet = FortuneSheetCodec.sheetFromJson(nullConfigSource);
    nullConfigSource['config'] = {};
    final nullAuthoritySource = {
      'id': 's3',
      'name': 'Sheet3',
      'config': <String, Object?>{'authority': null},
    };
    final nullAuthoritySheet = FortuneSheetCodec.sheetFromJson(
      nullAuthoritySource,
    );
    (nullAuthoritySource['config']! as Map)['authority'] = {'sheet': 1};
    final changed = emptyConfigSheet.copyWith(authority: {'sheet': 1});
    final manual = FortuneSheet(id: 's4', name: 'Sheet4');
    final emptyConfigJson = FortuneSheetCodec.sheetToJson(emptyConfigSheet);
    final nullConfigJson = FortuneSheetCodec.sheetToJson(nullConfigSheet);
    final nullAuthorityJson = FortuneSheetCodec.sheetToJson(nullAuthoritySheet);

    expect(emptyConfigSheet.hasRawConfig, isTrue);
    expect(emptyConfigSheet.rawConfig, isEmpty);
    expect(emptyConfigJson['config'], isEmpty);
    expect(nullConfigSheet.hasRawConfig, isTrue);
    expect(nullConfigSheet.rawConfig, isNull);
    expect(nullConfigJson['config'], isNull);
    expect(nullAuthoritySheet.hasRawConfig, isTrue);
    expect(nullAuthoritySheet.rawConfig, {'authority': null});
    expect(nullAuthorityJson['config'], {'authority': null});
    expect(FortuneSheetCodec.sheetToJson(changed)['config'], {
      'authority': {'sheet': 1},
    });
    expect(
      FortuneSheetCodec.sheetToJson(manual).containsKey('config'),
      isFalse,
    );

    (emptyConfigJson['config']! as Map)['authority'] = {'sheet': 1};
    nullConfigJson['config'] = {'authority': 1};
    (nullAuthorityJson['config']! as Map)['authority'] = {'sheet': 1};
    expect(FortuneSheetCodec.sheetToJson(emptyConfigSheet)['config'], isEmpty);
    expect(FortuneSheetCodec.sheetToJson(nullConfigSheet)['config'], isNull);
    expect(FortuneSheetCodec.sheetToJson(nullAuthoritySheet)['config'], {
      'authority': null,
    });
  });

  test('sheetToJson preserves explicit null config permission fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'rowlen': {'1': 29},
        'authority': null,
        'rowReadOnly': null,
        'colReadOnly': null,
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    sourceConfig
      ..['authority'] = {'sheet': 1}
      ..['rowReadOnly'] = {'1': 1}
      ..['colReadOnly'] = {'2': 1};
    final changed = sheet.copyWith(
      authority: {'sheet': 1},
      rowReadOnly: {'1': 1},
      colReadOnly: {'2': 1},
    );

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.hasRawAuthority, isTrue);
    expect(sheet.hasRawRowReadOnly, isTrue);
    expect(sheet.hasRawColReadOnly, isTrue);
    expect(config['rowlen'], {'1': 29});
    expect(config.containsKey('authority'), isTrue);
    expect(config['authority'], isNull);
    expect(config.containsKey('rowReadOnly'), isTrue);
    expect(config['rowReadOnly'], isNull);
    expect(config.containsKey('colReadOnly'), isTrue);
    expect(config['colReadOnly'], isNull);
    expect(changedConfig['authority'], {'sheet': 1});
    expect(changedConfig['rowReadOnly'], {'1': 1});
    expect(changedConfig['colReadOnly'], {'2': 1});

    config
      ..['authority'] = {'sheet': 1}
      ..['rowReadOnly'] = {'1': 1}
      ..['colReadOnly'] = {'2': 1};
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['rowlen'], {'1': 29});
    expect(reexportedConfig.containsKey('authority'), isTrue);
    expect(reexportedConfig['authority'], isNull);
    expect(reexportedConfig.containsKey('rowReadOnly'), isTrue);
    expect(reexportedConfig['rowReadOnly'], isNull);
    expect(reexportedConfig.containsKey('colReadOnly'), isTrue);
    expect(reexportedConfig['colReadOnly'], isNull);
  });

  test('sheetToJson snapshots raw config permission maps', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'authority': {
          'sheet': 1,
          'range': {
            'row': [0, 1],
          },
        },
        'rowReadOnly': {'1': '1', 'bad': 1},
        'colReadOnly': {'2': null},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    final sourceAuthority = sourceConfig['authority']! as Map;
    ((sourceAuthority['range']! as Map)['row']! as List)[0] = 9;
    (sourceConfig['rowReadOnly']! as Map)['1'] = '9';
    (sourceConfig['colReadOnly']! as Map)['3'] = null;

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;

    expect(config['authority'], {
      'sheet': 1,
      'range': {
        'row': [0, 1],
      },
    });
    expect(config['rowReadOnly'], {'1': '1', 'bad': 1});
    expect(config['colReadOnly'], {'2': null});

    final exportedAuthority = config['authority']! as Map;
    ((exportedAuthority['range']! as Map)['row']! as List)[0] = 7;
    (config['rowReadOnly']! as Map)['1'] = '7';
    (config['colReadOnly']! as Map)['3'] = null;

    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['authority'], {
      'sheet': 1,
      'range': {
        'row': [0, 1],
      },
    });
    expect(reexportedConfig['rowReadOnly'], {'1': '1', 'bad': 1});
    expect(reexportedConfig['colReadOnly'], {'2': null});
  });

  test('sheetToJson preserves empty null and invalid sizing config fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': <String, Object?>{
        'rowlen': null,
        'columnlen': {},
        'customHeight': 'invalid',
        'customWidth': null,
        'authority': {'sheet': 1},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    sourceConfig
      ..['rowlen'] = {'1': 29}
      ..['columnlen'] = {'2': 99}
      ..['customHeight'] = {'3': 1}
      ..['customWidth'] = {'4': 1}
      ..['authority'] = {'sheet': 2};
    final changed = sheet.copyWith(
      rowHeights: {1: 29},
      columnWidths: {2: 99},
      customHeight: {3: 1},
      customWidth: {4: 1},
    );

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.hasRawRowHeights, isTrue);
    expect(sheet.hasRawColumnWidths, isTrue);
    expect(sheet.hasRawCustomHeight, isTrue);
    expect(sheet.hasRawCustomWidth, isTrue);
    expect(config.containsKey('rowlen'), isTrue);
    expect(config['rowlen'], isNull);
    expect(config['columnlen'], isEmpty);
    expect(config['customHeight'], 'invalid');
    expect(config.containsKey('customWidth'), isTrue);
    expect(config['customWidth'], isNull);
    expect(config['authority'], {'sheet': 1});
    expect(changedConfig['rowlen'], {'1': 29});
    expect(changedConfig['columnlen'], {'2': 99});
    expect(changedConfig['customHeight'], {'3': 1});
    expect(changedConfig['customWidth'], {'4': 1});

    config
      ..['rowlen'] = {'1': 29}
      ..['columnlen'] = {'2': 99}
      ..['customHeight'] = {'3': 1}
      ..['customWidth'] = {'4': 1}
      ..['authority'] = {'sheet': 2};
    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig.containsKey('rowlen'), isTrue);
    expect(reexportedConfig['rowlen'], isNull);
    expect(reexportedConfig['columnlen'], isEmpty);
    expect(reexportedConfig['customHeight'], 'invalid');
    expect(reexportedConfig.containsKey('customWidth'), isTrue);
    expect(reexportedConfig['customWidth'], isNull);
    expect(reexportedConfig['authority'], {'sheet': 1});
  });

  test('sheetToJson preserves unchanged raw sizing map entries', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'rowlen': {'1': '29', 'bad': 77, '2': 0},
        'columnlen': {'3': 88.5},
        'customHeight': {'4': '1'},
        'customWidth': {'5': 1},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    (sourceConfig['rowlen']! as Map)['1'] = '99';
    (sourceConfig['columnlen']! as Map)['3'] = 12.0;
    (sourceConfig['customHeight']! as Map)['4'] = '0';
    (sourceConfig['customWidth']! as Map)['5'] = 0;
    final changed = sheet.copyWith(rowHeights: {1: 30});

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.rowHeights, {1: 29});
    expect(config['rowlen'], {'1': '29', 'bad': 77, '2': 0});
    expect(config['columnlen'], {'3': 88.5});
    expect(config['customHeight'], {'4': '1'});
    expect(config['customWidth'], {'5': 1});
    expect(changedConfig['rowlen'], {'1': 30});

    (config['rowlen']! as Map)['1'] = '77';
    (config['columnlen']! as Map)['3'] = 33.0;
    (config['customHeight']! as Map)['4'] = '2';
    (config['customWidth']! as Map)['5'] = 2;

    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['rowlen'], {'1': '29', 'bad': 77, '2': 0});
    expect(reexportedConfig['columnlen'], {'3': 88.5});
    expect(reexportedConfig['customHeight'], {'4': '1'});
    expect(reexportedConfig['customWidth'], {'5': 1});
  });

  test('sheetToJson preserves unchanged raw hidden axis maps', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'rowhidden': {'3': '7', 'bad': 1},
        'colhidden': {'4': null},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    (sourceConfig['rowhidden']! as Map)['3'] = '99';
    (sourceConfig['colhidden']! as Map)['5'] = null;
    final emptyRaw = FortuneSheetCodec.sheetFromJson({
      'id': 's2',
      'name': 'Sheet2',
      'config': {'rowhidden': {}, 'colhidden': null},
    });
    final changed = sheet.copyWith(hiddenRowValues: {3: 0});

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    final emptyConfig =
        FortuneSheetCodec.sheetToJson(emptyRaw)['config']! as Map;
    final changedConfig =
        FortuneSheetCodec.sheetToJson(changed)['config']! as Map;

    expect(sheet.hiddenRows, {3});
    expect(sheet.hiddenColumns, {4});
    expect(sheet.rawHiddenRows, {'3': '7', 'bad': 1});
    expect(sheet.hasRawHiddenRows, isTrue);
    expect(sheet.rawHiddenColumns, {'4': null});
    expect(sheet.hasRawHiddenColumns, isTrue);
    expect(sheet.hiddenRowValues[3], '7');
    expect(sheet.hiddenColumnValues[4], isNull);
    expect(config['rowhidden'], {'3': '7', 'bad': 1});
    expect(config['colhidden'], {'4': null});
    expect(emptyConfig['rowhidden'], isEmpty);
    expect(emptyConfig.containsKey('colhidden'), isTrue);
    expect(emptyConfig['colhidden'], isNull);
    expect(changedConfig['rowhidden'], {'3': 0});

    (config['rowhidden']! as Map)['3'] = '77';
    (config['colhidden']! as Map)['5'] = null;

    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['rowhidden'], {'3': '7', 'bad': 1});
    expect(reexportedConfig['colhidden'], {'4': null});
  });

  test('sheetToJson preserves raw sheet visibility and pivot flags', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'hide': '1',
      'isPivotTable': 1,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['hide'] = '0'
      ..['isPivotTable'] = 0;
    final changed = sheet.copyWith(hide: 0, isPivotTable: false);
    final manual = FortuneSheet(
      id: 's2',
      name: 'Sheet2',
      hide: 1,
      isPivotTable: true,
    );
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.hide, 1);
    expect(sheet.rawHide, '1');
    expect(sheet.hasRawHide, isTrue);
    expect(sheet.isPivotTable, isTrue);
    expect(sheet.rawIsPivotTable, 1);
    expect(sheet.hasRawIsPivotTable, isTrue);
    expect(json['hide'], '1');
    expect(json['isPivotTable'], 1);
    expect(FortuneSheetCodec.sheetToJson(changed)['hide'], 0);
    expect(FortuneSheetCodec.sheetToJson(changed)['isPivotTable'], isFalse);
    expect(FortuneSheetCodec.sheetToJson(manual)['hide'], 1);
    expect(FortuneSheetCodec.sheetToJson(manual)['isPivotTable'], isTrue);

    json
      ..['hide'] = '0'
      ..['isPivotTable'] = 0;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['hide'], '1');
    expect(reexported['isPivotTable'], 1);
  });

  test('sheetToJson preserves raw sheet status outside workbook export', () {
    final source = {'id': 's1', 'name': 'Sheet1', 'status': '1'};
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source['status'] = '0';
    final changed = sheet.copyWith(status: 0);
    final workbook = FortuneWorkbook(sheets: [sheet], activeSheetIndex: 0);
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.status, 1);
    expect(sheet.rawStatus, '1');
    expect(sheet.hasRawStatus, isTrue);
    expect(json['status'], '1');
    expect(FortuneSheetCodec.sheetToJson(changed)['status'], 0);
    expect(
      ((FortuneSheetCodec.workbookToJson(workbook)['data']! as List).single
          as Map)['status'],
      1,
    );

    json['status'] = '0';
    expect(FortuneSheetCodec.sheetToJson(sheet)['status'], '1');
  });

  test('sheetToJson preserves explicit null sheet state fields', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'status': null,
      'hide': null,
      'isPivotTable': null,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['status'] = 1
      ..['hide'] = 0
      ..['isPivotTable'] = true;
    final changed = sheet.copyWith(status: 1, hide: 0, isPivotTable: true);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(sheet.hasRawStatus, isTrue);
    expect(sheet.hasRawHide, isTrue);
    expect(sheet.hasRawIsPivotTable, isTrue);
    expect(json.containsKey('status'), isTrue);
    expect(json['status'], isNull);
    expect(json.containsKey('hide'), isTrue);
    expect(json['hide'], isNull);
    expect(json.containsKey('isPivotTable'), isTrue);
    expect(json['isPivotTable'], isNull);
    expect(changed.hasRawStatus, isFalse);
    expect(changed.hasRawHide, isFalse);
    expect(changed.hasRawIsPivotTable, isFalse);
    expect(changedJson['status'], 1);
    expect(changedJson['hide'], 0);
    expect(changedJson['isPivotTable'], isTrue);

    json
      ..['status'] = 1
      ..['hide'] = 0
      ..['isPivotTable'] = true;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('status'), isTrue);
    expect(reexported['status'], isNull);
    expect(reexported.containsKey('hide'), isTrue);
    expect(reexported['hide'], isNull);
    expect(reexported.containsKey('isPivotTable'), isTrue);
    expect(reexported['isPivotTable'], isNull);
  });

  test('sheetToJson preserves raw sheet dimension metadata', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'order': '3',
      'row': '120',
      'column': 40,
      'addRows': null,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['order'] = '4'
      ..['row'] = '121'
      ..['column'] = 41
      ..['addRows'] = 10;
    final changed = sheet.copyWith(rowCount: 121, addRows: 10);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(sheet.order, 3);
    expect(sheet.rawOrder, '3');
    expect(sheet.hasRawOrder, isTrue);
    expect(sheet.rowCount, 120);
    expect(sheet.rawRowCount, '120');
    expect(sheet.hasRawRowCount, isTrue);
    expect(sheet.columnCount, 40);
    expect(sheet.rawColumnCount, 40);
    expect(sheet.hasRawColumnCount, isTrue);
    expect(sheet.addRows, isNull);
    expect(sheet.hasRawAddRows, isTrue);
    expect(json['order'], '3');
    expect(json['row'], '120');
    expect(json['column'], 40);
    expect(json.containsKey('addRows'), isTrue);
    expect(json['addRows'], isNull);
    expect(changedJson['row'], 121);
    expect(changedJson['addRows'], 10);

    json
      ..['order'] = '4'
      ..['row'] = '121'
      ..['column'] = 41
      ..['addRows'] = 10;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['order'], '3');
    expect(reexported['row'], '120');
    expect(reexported['column'], 40);
    expect(reexported.containsKey('addRows'), isTrue);
    expect(reexported['addRows'], isNull);
  });

  test('sheetToJson preserves explicit null sheet dimension metadata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'order': null,
      'row': null,
      'column': null,
      'addRows': null,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['order'] = 3
      ..['row'] = 120
      ..['column'] = 40
      ..['addRows'] = 10;
    final changed = sheet.copyWith(
      order: 3,
      rowCount: 120,
      columnCount: 40,
      addRows: 10,
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(sheet.hasRawOrder, isTrue);
    expect(sheet.hasRawRowCount, isTrue);
    expect(sheet.hasRawColumnCount, isTrue);
    expect(sheet.hasRawAddRows, isTrue);
    expect(json.containsKey('order'), isTrue);
    expect(json['order'], isNull);
    expect(json.containsKey('row'), isTrue);
    expect(json['row'], isNull);
    expect(json.containsKey('column'), isTrue);
    expect(json['column'], isNull);
    expect(json.containsKey('addRows'), isTrue);
    expect(json['addRows'], isNull);
    expect(changed.hasRawOrder, isFalse);
    expect(changed.hasRawRowCount, isFalse);
    expect(changed.hasRawColumnCount, isFalse);
    expect(changed.hasRawAddRows, isFalse);
    expect(changedJson['order'], 3);
    expect(changedJson['row'], 120);
    expect(changedJson['column'], 40);
    expect(changedJson['addRows'], 10);

    json
      ..['order'] = 3
      ..['row'] = 120
      ..['column'] = 40
      ..['addRows'] = 10;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('order'), isTrue);
    expect(reexported['order'], isNull);
    expect(reexported.containsKey('row'), isTrue);
    expect(reexported['row'], isNull);
    expect(reexported.containsKey('column'), isTrue);
    expect(reexported['column'], isNull);
    expect(reexported.containsKey('addRows'), isTrue);
    expect(reexported['addRows'], isNull);
  });

  test('sheetToJson preserves raw sheet sizing metadata', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'defaultRowHeight': '21',
      'defaultColWidth': 88,
      'zoomRatio': '1',
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['defaultRowHeight'] = '22'
      ..['defaultColWidth'] = 99
      ..['zoomRatio'] = '2';
    final changed = sheet.copyWith(defaultRowHeight: 22.5, zoomRatio: 1.25);
    final defaultSheet = FortuneSheet(id: 's2', name: 'Sheet2');

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);
    final defaultJson = FortuneSheetCodec.sheetToJson(defaultSheet);

    expect(sheet.defaultRowHeight, 21);
    expect(sheet.rawDefaultRowHeight, '21');
    expect(sheet.hasRawDefaultRowHeight, isTrue);
    expect(sheet.defaultColWidth, 88);
    expect(sheet.rawDefaultColWidth, 88);
    expect(sheet.hasRawDefaultColWidth, isTrue);
    expect(sheet.zoomRatio, 1);
    expect(sheet.rawZoomRatio, '1');
    expect(sheet.hasRawZoomRatio, isTrue);
    expect(json['defaultRowHeight'], '21');
    expect(json['defaultColWidth'], 88);
    expect(json['zoomRatio'], '1');
    expect(changedJson['defaultRowHeight'], 22.5);
    expect(changedJson['defaultColWidth'], 88);
    expect(changedJson['zoomRatio'], 1.25);
    expect(defaultJson.containsKey('zoomRatio'), isFalse);

    json
      ..['defaultRowHeight'] = '22'
      ..['defaultColWidth'] = 99
      ..['zoomRatio'] = '2';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['defaultRowHeight'], '21');
    expect(reexported['defaultColWidth'], 88);
    expect(reexported['zoomRatio'], '1');
  });

  test('sheetToJson preserves explicit null sheet sizing metadata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'defaultRowHeight': null,
      'defaultColWidth': null,
      'zoomRatio': null,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['defaultRowHeight'] = 21
      ..['defaultColWidth'] = 88
      ..['zoomRatio'] = 1.25;
    final changed = sheet.copyWith(
      defaultRowHeight: 21,
      defaultColWidth: 88,
      zoomRatio: 1.25,
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(sheet.hasRawDefaultRowHeight, isTrue);
    expect(sheet.hasRawDefaultColWidth, isTrue);
    expect(sheet.hasRawZoomRatio, isTrue);
    expect(json.containsKey('defaultRowHeight'), isTrue);
    expect(json['defaultRowHeight'], isNull);
    expect(json.containsKey('defaultColWidth'), isTrue);
    expect(json['defaultColWidth'], isNull);
    expect(json.containsKey('zoomRatio'), isTrue);
    expect(json['zoomRatio'], isNull);
    expect(changed.hasRawDefaultRowHeight, isFalse);
    expect(changed.hasRawDefaultColWidth, isFalse);
    expect(changed.hasRawZoomRatio, isFalse);
    expect(changedJson['defaultRowHeight'], 21);
    expect(changedJson['defaultColWidth'], 88);
    expect(changedJson['zoomRatio'], 1.25);

    json
      ..['defaultRowHeight'] = 21
      ..['defaultColWidth'] = 88
      ..['zoomRatio'] = 1.25;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('defaultRowHeight'), isTrue);
    expect(reexported['defaultRowHeight'], isNull);
    expect(reexported.containsKey('defaultColWidth'), isTrue);
    expect(reexported['defaultColWidth'], isNull);
    expect(reexported.containsKey('zoomRatio'), isTrue);
    expect(reexported['zoomRatio'], isNull);
  });

  test('sheet copyWith accepts integer default sizing values', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
    ).copyWith(defaultRowHeight: 21, defaultColWidth: 88);

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.defaultRowHeight, 21);
    expect(sheet.defaultColWidth, 88);
    expect(json['defaultRowHeight'], 21);
    expect(json['defaultColWidth'], 88);

    json
      ..['defaultRowHeight'] = 99
      ..['defaultColWidth'] = 99;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['defaultRowHeight'], 21);
    expect(reexported['defaultColWidth'], 88);
  });

  test('sheet copyWith accepts numeric and boolean metadata strings', () {
    final sheet = FortuneSheet(id: 's1', name: 'Sheet1').copyWith(
      order: '2',
      rowCount: '120',
      columnCount: 40.0,
      addRows: '5',
      hide: '1',
      zoomRatio: '1.5',
      showGridLines: '0',
      status: '0',
      isPivotTable: 'true',
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.order, 2);
    expect(sheet.rowCount, 120);
    expect(sheet.columnCount, 40);
    expect(sheet.addRows, 5);
    expect(sheet.hide, 1);
    expect(sheet.zoomRatio, 1.5);
    expect(sheet.showGridLines, isFalse);
    expect(sheet.status, 0);
    expect(sheet.isPivotTable, isTrue);
    expect(json['order'], 2);
    expect(json['row'], 120);
    expect(json['column'], 40);
    expect(json['addRows'], 5);
    expect(json['hide'], 1);
    expect(json['zoomRatio'], 1.5);
    expect(json['showGridLines'], 0);
    expect(json['status'], 0);
    expect(json['isPivotTable'], isTrue);

    json
      ..['order'] = 9
      ..['row'] = 9
      ..['column'] = 9
      ..['addRows'] = 9
      ..['hide'] = 0
      ..['zoomRatio'] = 2
      ..['showGridLines'] = 1
      ..['status'] = 1
      ..['isPivotTable'] = false;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['order'], 2);
    expect(reexported['row'], 120);
    expect(reexported['column'], 40);
    expect(reexported['addRows'], 5);
    expect(reexported['hide'], 1);
    expect(reexported['zoomRatio'], 1.5);
    expect(reexported['showGridLines'], 0);
    expect(reexported['status'], 0);
    expect(reexported['isPivotTable'], isTrue);
  });

  test('sheet copyWith string metadata accepts non-string values', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
    ).copyWith(id: 456, name: Uri.parse('sheet://renamed'), color: 123);

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.id, '456');
    expect(sheet.name, 'sheet://renamed');
    expect(sheet.color, '123');
    expect(json['id'], '456');
    expect(json['name'], 'sheet://renamed');
    expect(json['color'], '123');

    json
      ..['id'] = 'mutated'
      ..['name'] = 'mutated'
      ..['color'] = 'mutated';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['id'], '456');
    expect(reexported['name'], 'sheet://renamed');
    expect(reexported['color'], '123');
  });

  test('sheetToJson preserves raw chart and shape overlay metadata', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'chart': [
        {
          'id': 'chart1',
          'left': 12,
          'top': 24,
          'width': 320,
          'height': 180,
          'option': {
            'xAxis': {
              'axisPointer': {
                'show': true,
                'label': {
                  'formatter': 'x: {value}',
                  'padding': [1, 2, 3, 4],
                },
                'handle': {
                  'show': true,
                  'size': [16, 24],
                },
              },
            },
            'series': [
              {
                'type': 'bar',
                'data': [1, 2, 3],
              },
            ],
          },
        },
      ],
      'shapes': {
        'shape1': {
          'type': 'rect',
          'left': 40,
          'top': 60,
          'width': 100,
          'height': 50,
        },
      },
      'customOverlay': {'kind': 'plugin-overlay', 'zIndex': 3},
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceChart = (source['chart']! as List).single as Map;
    final sourceOption = sourceChart['option']! as Map;
    final sourceXAxis = sourceOption['xAxis']! as Map;
    final sourceAxisPointer = sourceXAxis['axisPointer']! as Map;
    (sourceAxisPointer['label']! as Map)['formatter'] = 'mutated';
    ((sourceAxisPointer['handle']! as Map)['size']! as List)[0] = 99;
    (((sourceOption['series']! as List).single as Map)['data']! as List)[0] =
        99;
    ((source['shapes']! as Map)['shape1']! as Map)['left'] = 99;
    (source['customOverlay']! as Map)['zIndex'] = 99;

    final renamed = sheet.copyWith(name: 'Renamed');
    final json = FortuneSheetCodec.sheetToJson(renamed);

    expect(renamed.extraFields['chart'], isA<List>());
    expect(renamed.extraFields['shapes'], isA<Map>());
    expect(json['name'], 'Renamed');
    expect(json['chart'], [
      {
        'id': 'chart1',
        'left': 12,
        'top': 24,
        'width': 320,
        'height': 180,
        'option': {
          'xAxis': {
            'axisPointer': {
              'show': true,
              'label': {
                'formatter': 'x: {value}',
                'padding': [1, 2, 3, 4],
              },
              'handle': {
                'show': true,
                'size': [16, 24],
              },
            },
          },
          'series': [
            {
              'type': 'bar',
              'data': [1, 2, 3],
            },
          ],
        },
      },
    ]);
    expect(json['shapes'], {
      'shape1': {
        'type': 'rect',
        'left': 40,
        'top': 60,
        'width': 100,
        'height': 50,
      },
    });
    expect(json['customOverlay'], {'kind': 'plugin-overlay', 'zIndex': 3});

    final exportedChart = (json['chart']! as List).single as Map;
    final exportedOption = exportedChart['option']! as Map;
    final exportedAxisPointer =
        ((exportedOption['xAxis']! as Map)['axisPointer']) as Map;
    (exportedAxisPointer['label'] as Map)['formatter'] = 'export-mutated';
    ((exportedAxisPointer['handle'] as Map)['size'] as List)[0] = 99;
    (((exportedOption['series']! as List).single as Map)['data']! as List)[0] =
        99;
    ((json['shapes']! as Map)['shape1']! as Map)['left'] = 99;
    (json['customOverlay']! as Map)['zIndex'] = 99;
    final reexported = FortuneSheetCodec.sheetToJson(renamed);

    expect(
      ((((reexported['chart']! as List).single as Map)['option']
              as Map)['xAxis']
          as Map)['axisPointer'],
      {
        'show': true,
        'label': {
          'formatter': 'x: {value}',
          'padding': [1, 2, 3, 4],
        },
        'handle': {
          'show': true,
          'size': [16, 24],
        },
      },
    );
    final reexportedChart = (reexported['chart']! as List).single as Map;
    final reexportedOption = reexportedChart['option']! as Map;
    expect(((reexportedOption['series']! as List).single as Map)['data'], [
      1,
      2,
      3,
    ]);
    expect(reexported['shapes'], {
      'shape1': {
        'type': 'rect',
        'left': 40,
        'top': 60,
        'width': 100,
        'height': 50,
      },
    });
    expect(reexported['customOverlay'], {
      'kind': 'plugin-overlay',
      'zIndex': 3,
    });
  });

  test('sheetToJson preserves unchanged image raw geometry values', () {
    final imageSource = {
      'id': 'img1',
      'src': 'data:image/png;base64,test',
      'left': '10',
      'top': 20,
      'width': '30.5',
      'height': 40,
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'images': [imageSource],
    });
    imageSource
      ..['left'] = '99'
      ..['top'] = 99
      ..['width'] = '99'
      ..['height'] = 99;
    final moved = sheet.copyWith(
      images: [sheet.images.single.copyWith(left: 11.0)],
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final movedJson = FortuneSheetCodec.sheetToJson(moved);
    final image = (json['images']! as List).single as Map;
    final movedImage = (movedJson['images']! as List).single as Map;

    expect(sheet.images.single.hasRawLeft, isTrue);
    expect(sheet.images.single.hasRawTop, isTrue);
    expect(sheet.images.single.hasRawWidth, isTrue);
    expect(sheet.images.single.hasRawHeight, isTrue);
    expect(image['left'], '10');
    expect(image['top'], 20);
    expect(image['width'], '30.5');
    expect(image['height'], 40);
    expect(movedImage['left'], 11);
    expect(movedImage['width'], '30.5');

    image
      ..['left'] = '99'
      ..['top'] = 99
      ..['width'] = '99'
      ..['height'] = 99;
    final reexportedImage =
        (FortuneSheetCodec.sheetToJson(sheet)['images']! as List).single as Map;
    expect(reexportedImage['left'], '10');
    expect(reexportedImage['top'], 20);
    expect(reexportedImage['width'], '30.5');
    expect(reexportedImage['height'], 40);
  });

  test('sheet codec supports documented singular image metadata key', () {
    final imageSource = {
      'id': 'img1',
      'src': 'data:image/png;base64,test',
      'left': '10',
      'top': 20,
      'width': '30.5',
      'height': 40,
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'image': [imageSource],
    });
    imageSource
      ..['left'] = '99'
      ..['top'] = 99;
    final moved = sheet.copyWith(
      images: [sheet.images.single.copyWith(left: 11.0)],
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final movedJson = FortuneSheetCodec.sheetToJson(moved);
    final image = (json['image']! as List).single as Map;
    final movedImage = (movedJson['image']! as List).single as Map;

    expect(sheet.images, hasLength(1));
    expect(sheet.rawImagesKey, 'image');
    expect(sheet.hasRawImages, isTrue);
    expect(json.containsKey('images'), isFalse);
    expect(image['left'], '10');
    expect(image['top'], 20);
    expect(movedJson.containsKey('images'), isFalse);
    expect(movedImage['left'], 11);
    expect(movedImage['width'], '30.5');
  });

  test('sheetToJson preserves unchanged raw images list', () {
    final sourceImages = [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': '10',
        'top': 20,
        'width': '30.5',
        'height': 40,
        'crop': {'x': 1},
      },
      {'id': 'missing-geometry'},
    ];
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'images': sourceImages,
    });
    final moved = sheet.copyWith(
      images: [sheet.images.single.copyWith(left: 11.0)],
    );
    final sourceFirstImage = sourceImages.first;
    sourceFirstImage['left'] = 'mutated';
    (sourceFirstImage['crop']! as Map)['x'] = 9;
    sourceImages[1]['id'] = 'mutated-missing';

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final movedJson = FortuneSheetCodec.sheetToJson(moved);

    expect(sheet.images, hasLength(1));
    expect(sheet.rawImages, [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': '10',
        'top': 20,
        'width': '30.5',
        'height': 40,
        'crop': {'x': 1},
      },
      {'id': 'missing-geometry'},
    ]);
    expect(sheet.hasRawImages, isTrue);
    expect(json['images'], [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': '10',
        'top': 20,
        'width': '30.5',
        'height': 40,
        'crop': {'x': 1},
      },
      {'id': 'missing-geometry'},
    ]);
    final exportedImages = json['images']! as List;
    final exportedFirstImage = exportedImages.first as Map;
    exportedFirstImage['left'] = 'export-mutated';
    (exportedFirstImage['crop']! as Map)['x'] = 99;
    (exportedImages[1] as Map)['id'] = 'export-mutated-missing';
    expect(FortuneSheetCodec.sheetToJson(sheet)['images'], [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': '10',
        'top': 20,
        'width': '30.5',
        'height': 40,
        'crop': {'x': 1},
      },
      {'id': 'missing-geometry'},
    ]);
    expect(movedJson['images'], [
      {
        'crop': {'x': 1},
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': 11,
        'top': 20,
        'width': '30.5',
        'height': 40,
      },
    ]);

    final movedImageJson = (movedJson['images']! as List).single as Map;
    (movedImageJson['crop']! as Map)['x'] = 99;
    final reexportedMovedImage =
        (FortuneSheetCodec.sheetToJson(moved)['images']! as List).single as Map;
    expect(reexportedMovedImage['crop'], {'x': 1});
    expect(moved.images.single.extraFields['crop'], {'x': 1});
  });

  test(
    'sheetToJson preserves explicit empty null and invalid images fields',
    () {
      final emptyImages = <Object?>[];
      final emptyImagesSheet = FortuneSheetCodec.sheetFromJson({
        'id': 's1',
        'name': 'Sheet1',
        'images': emptyImages,
      });
      emptyImages.add({'id': 'source-mutated'});
      final nullImagesSource = <String, Object?>{
        'id': 's2',
        'name': 'Sheet2',
        'images': null,
      };
      final nullImagesSheet = FortuneSheetCodec.sheetFromJson(nullImagesSource);
      nullImagesSource['images'] = [];
      final invalidImages = <Object?>[
        {'id': 'missing-geometry'},
        'invalid',
      ];
      final invalidImagesSheet = FortuneSheetCodec.sheetFromJson({
        'id': 's3',
        'name': 'Sheet3',
        'images': invalidImages,
      });
      (invalidImages.first as Map)['id'] = 'source-mutated';
      invalidImages.add({'id': 'source-added'});
      final changed = invalidImagesSheet.copyWith(
        images: const [
          FortuneImage(
            id: 'img1',
            src: 'data:image/png;base64,test',
            left: 10,
            top: 20,
            width: 30,
            height: 40,
          ),
        ],
      );
      final manual = FortuneSheet(id: 's4', name: 'Sheet4');

      expect(emptyImagesSheet.hasRawImages, isTrue);
      expect(
        FortuneSheetCodec.sheetToJson(emptyImagesSheet)['images'],
        isEmpty,
      );
      expect(nullImagesSheet.hasRawImages, isTrue);
      expect(FortuneSheetCodec.sheetToJson(nullImagesSheet)['images'], isNull);
      expect(invalidImagesSheet.images, isEmpty);
      expect(FortuneSheetCodec.sheetToJson(invalidImagesSheet)['images'], [
        {'id': 'missing-geometry'},
        'invalid',
      ]);
      expect(
        (FortuneSheetCodec.sheetToJson(changed)['images']! as List).single,
        {
          'id': 'img1',
          'src': 'data:image/png;base64,test',
          'left': 10,
          'top': 20,
          'width': 30,
          'height': 40,
        },
      );
      expect(
        FortuneSheetCodec.sheetToJson(manual).containsKey('images'),
        isFalse,
      );

      final emptyImagesJson = FortuneSheetCodec.sheetToJson(emptyImagesSheet);
      final nullImagesJson = FortuneSheetCodec.sheetToJson(nullImagesSheet);
      final invalidImagesJson = FortuneSheetCodec.sheetToJson(
        invalidImagesSheet,
      );
      (emptyImagesJson['images']! as List).add({'id': 'export-mutated'});
      nullImagesJson['images'] = [];
      ((invalidImagesJson['images']! as List).first as Map)['id'] =
          'export-mutated';
      (invalidImagesJson['images']! as List).add({'id': 'export-added'});
      expect(
        FortuneSheetCodec.sheetToJson(emptyImagesSheet)['images'],
        isEmpty,
      );
      expect(FortuneSheetCodec.sheetToJson(nullImagesSheet)['images'], isNull);
      expect(FortuneSheetCodec.sheetToJson(invalidImagesSheet)['images'], [
        {'id': 'missing-geometry'},
        'invalid',
      ]);
    },
  );

  test('sheetToJson preserves explicit empty and null sheet maps', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'dataVerification': {},
      'filter': null,
      'hyperlink': 'invalid',
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    (source['dataVerification']! as Map)['0_0'] = {'type': 'dropdown'};
    source
      ..['filter'] = {
        '0': {'caljs': {}},
      }
      ..['hyperlink'] = {
        '0_1': {'linkType': 'webpage'},
      };
    final changed = sheet.copyWith(
      dataVerification: {
        '0_0': {'type': 'dropdown'},
      },
      filter: {
        '0': {'caljs': {}},
      },
      hyperlinks: {
        '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      },
    );
    final manual = FortuneSheet(id: 's2', name: 'Sheet2');
    final nullDataVerificationSheet = FortuneSheetCodec.sheetFromJson({
      'id': 's3',
      'name': 'Sheet3',
      'dataVerification': null,
      'filter': {},
    });

    expect(sheet.hasRawDataVerification, isTrue);
    expect(sheet.rawDataVerification, isEmpty);
    expect(sheet.hasRawFilter, isTrue);
    expect(sheet.rawFilter, isNull);
    expect(sheet.hasRawHyperlinks, isTrue);
    expect(sheet.rawHyperlinks, 'invalid');
    expect(FortuneSheetCodec.sheetToJson(sheet)['dataVerification'], isEmpty);
    expect(FortuneSheetCodec.sheetToJson(sheet)['filter'], isNull);
    expect(FortuneSheetCodec.sheetToJson(sheet)['hyperlink'], 'invalid');
    expect(FortuneSheetCodec.sheetToJson(changed)['dataVerification'], {
      '0_0': {'type': 'dropdown'},
    });
    expect(FortuneSheetCodec.sheetToJson(changed)['filter'], {
      '0': {'caljs': {}},
    });
    expect(FortuneSheetCodec.sheetToJson(changed)['hyperlink'], {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
    expect(
      FortuneSheetCodec.sheetToJson(manual).containsKey('dataVerification'),
      isFalse,
    );
    expect(
      FortuneSheetCodec.sheetToJson(manual).containsKey('filter'),
      isFalse,
    );
    expect(
      FortuneSheetCodec.sheetToJson(manual).containsKey('hyperlink'),
      isFalse,
    );
    expect(nullDataVerificationSheet.hasRawDataVerification, isTrue);
    expect(nullDataVerificationSheet.rawDataVerification, isNull);
    expect(nullDataVerificationSheet.hasRawFilter, isTrue);
    expect(nullDataVerificationSheet.rawFilter, isEmpty);
    expect(
      FortuneSheetCodec.sheetToJson(
        nullDataVerificationSheet,
      )['dataVerification'],
      isNull,
    );
    expect(
      FortuneSheetCodec.sheetToJson(nullDataVerificationSheet)['filter'],
      isEmpty,
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    (json['dataVerification']! as Map)['0_0'] = {'type': 'dropdown'};
    json
      ..['filter'] = {
        '0': {'caljs': {}},
      }
      ..['hyperlink'] = {
        '0_1': {'linkType': 'webpage'},
      };
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['dataVerification'], isEmpty);
    expect(reexported['filter'], isNull);
    expect(reexported['hyperlink'], 'invalid');
  });

  test('sheetFromJson snapshots sheet map metadata fields', () {
    final sourceDataVerification = {
      '0_0': {
        'type': 'dropdown',
        'values': ['A', 'B'],
      },
    };
    final sourceFilter = {
      '0': {
        'caljs': {
          'value': ['A'],
        },
      },
    };
    final sourceHyperlinks = {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'dataVerification': sourceDataVerification,
      'filter': sourceFilter,
      'hyperlink': sourceHyperlinks,
    });

    final sourceValues = sourceDataVerification['0_0']!['values'] as List;
    sourceValues[0] = 'mutated';
    final sourceFilterCaljs = sourceFilter['0']!['caljs'] as Map;
    final sourceFilterValues = sourceFilterCaljs['value'] as List;
    sourceFilterValues[0] = 'mutated';
    sourceHyperlinks['0_1']!['linkAddress'] = 'https://mutated.test';

    expect(sheet.hasRawDataVerification, isTrue);
    expect(sheet.rawDataVerification, {
      '0_0': {
        'type': 'dropdown',
        'values': ['A', 'B'],
      },
    });
    expect(sheet.hasRawFilter, isTrue);
    expect(sheet.rawFilter, {
      '0': {
        'caljs': {
          'value': ['A'],
        },
      },
    });
    expect(sheet.hasRawHyperlinks, isTrue);
    expect(sheet.rawHyperlinks, {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(json['dataVerification'], {
      '0_0': {
        'type': 'dropdown',
        'values': ['A', 'B'],
      },
    });
    expect(json['filter'], {
      '0': {
        'caljs': {
          'value': ['A'],
        },
      },
    });
    expect(json['hyperlink'], {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });

    final exportedFilter = (json['filter'] as Map)['0'] as Map;
    final exportedFilterCaljs = exportedFilter['caljs'] as Map;
    final exportedFilterValues = exportedFilterCaljs['value'] as List;
    exportedFilterValues[0] = 'export-mutated';
    final exportedDataVerification =
        (json['dataVerification'] as Map)['0_0'] as Map;
    (exportedDataVerification['values'] as List)[0] = 'export-mutated';
    final exportedHyperlink = (json['hyperlink'] as Map)['0_1'] as Map;
    exportedHyperlink['linkAddress'] = 'https://export-mutated.test';

    expect(FortuneSheetCodec.sheetToJson(sheet)['filter'], {
      '0': {
        'caljs': {
          'value': ['A'],
        },
      },
    });
    expect(FortuneSheetCodec.sheetToJson(sheet)['dataVerification'], {
      '0_0': {
        'type': 'dropdown',
        'values': ['A', 'B'],
      },
    });
    expect(FortuneSheetCodec.sheetToJson(sheet)['hyperlink'], {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
  });

  test('sheetToJson preserves explicit null sheet hyperlink fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'hyperlink': {
        '0_0': <String, Object?>{
          'id': null,
          'linkType': null,
          'linkAddress': null,
        },
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceHyperlink = (source['hyperlink']! as Map)['0_0']! as Map;
    sourceHyperlink
      ..['id'] = 'link1'
      ..['linkType'] = 'webpage'
      ..['linkAddress'] = 'https://example.test';

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final hyperlink = (json['hyperlink'] as Map)['0_0'] as Map;

    expect(hyperlink.keys, containsAll(['id', 'linkType', 'linkAddress']));
    expect(hyperlink['id'], isNull);
    expect(hyperlink['linkType'], isNull);
    expect(hyperlink['linkAddress'], isNull);

    hyperlink
      ..['id'] = 'link1'
      ..['linkType'] = 'webpage'
      ..['linkAddress'] = 'https://example.test';
    final reexportedHyperlink =
        (FortuneSheetCodec.sheetToJson(sheet)['hyperlink'] as Map)['0_0']
            as Map;
    expect(
      reexportedHyperlink.keys,
      containsAll(['id', 'linkType', 'linkAddress']),
    );
    expect(reexportedHyperlink['id'], isNull);
    expect(reexportedHyperlink['linkType'], isNull);
    expect(reexportedHyperlink['linkAddress'], isNull);
  });

  test('sheetToJson preserves explicit null object metadata fields', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'luckysheet_select_save': null,
      'luckysheet_selection_range': null,
      'calcChain': null,
      'filter_select': null,
      'luckysheet_conditionformat_save': null,
      'luckysheet_alternateformat_save': null,
      'luckysheet_alternateformat_save_modelCustom': null,
      'pivotTable': null,
      'dynamicArray_compute': null,
      'dynamicArray': null,
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    source
      ..['luckysheet_select_save'] = [
        {
          'row': [0, 0],
        },
      ]
      ..['luckysheet_selection_range'] = [
        {
          'column': [1, 1],
        },
      ]
      ..['calcChain'] = [
        {'r': 0, 'c': 0},
      ]
      ..['filter_select'] = {
        'row': [0, 10],
        'column': [1, 1],
      }
      ..['luckysheet_conditionformat_save'] = [
        {'type': 'cellIs'},
      ]
      ..['luckysheet_alternateformat_save'] = [
        {'range': 'A1:B2'},
      ]
      ..['luckysheet_alternateformat_save_modelCustom'] = [
        {'key': 'custom', 'text': 'Custom'},
      ]
      ..['pivotTable'] = {'enabled': true}
      ..['dynamicArray_compute'] = {'0_0': true}
      ..['dynamicArray'] = [
        {'r': 0, 'c': 0},
      ];
    final changed = sheet.copyWith(
      selectionSave: [
        {
          'row': [0, 0],
        },
      ],
      selectionRange: [
        {
          'column': [1, 1],
        },
      ],
      calcChain: [
        {'r': 0, 'c': 0},
      ],
      filterSelect: {
        'row': [0, 10],
        'column': [1, 1],
      },
      conditionFormats: [
        {'type': 'cellIs'},
      ],
      alternateFormats: [
        {'range': 'A1:B2'},
      ],
      alternateFormatCustomModels: [
        {'key': 'custom', 'text': 'Custom'},
      ],
      pivotTable: {'enabled': true},
      dynamicArrayCompute: {'0_0': true},
      dynamicArray: [
        {'r': 0, 'c': 0},
      ],
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final changedJson = FortuneSheetCodec.sheetToJson(changed);

    expect(sheet.hasRawSelectionSave, isTrue);
    expect(sheet.selectionSave, isNull);
    expect(sheet.hasRawSelectionRange, isTrue);
    expect(sheet.selectionRange, isNull);
    expect(sheet.hasRawCalcChain, isTrue);
    expect(sheet.calcChain, isNull);
    expect(sheet.hasRawFilterSelect, isTrue);
    expect(sheet.filterSelect, isNull);
    expect(sheet.hasRawConditionFormats, isTrue);
    expect(sheet.conditionFormats, isNull);
    expect(sheet.hasRawAlternateFormats, isTrue);
    expect(sheet.alternateFormats, isNull);
    expect(sheet.hasRawAlternateFormatCustomModels, isTrue);
    expect(sheet.alternateFormatCustomModels, isNull);
    expect(sheet.hasRawPivotTable, isTrue);
    expect(sheet.pivotTable, isNull);
    expect(sheet.hasRawDynamicArrayCompute, isTrue);
    expect(sheet.dynamicArrayCompute, isNull);
    expect(sheet.hasRawDynamicArray, isTrue);
    expect(sheet.dynamicArray, isNull);
    expect(
      json.keys,
      containsAll(<String>[
        'luckysheet_select_save',
        'luckysheet_selection_range',
        'calcChain',
        'filter_select',
        'luckysheet_conditionformat_save',
        'luckysheet_alternateformat_save',
        'luckysheet_alternateformat_save_modelCustom',
        'pivotTable',
        'dynamicArray_compute',
        'dynamicArray',
      ]),
    );
    expect(json['luckysheet_select_save'], isNull);
    expect(json['luckysheet_selection_range'], isNull);
    expect(json['calcChain'], isNull);
    expect(json['filter_select'], isNull);
    expect(json['luckysheet_conditionformat_save'], isNull);
    expect(json['luckysheet_alternateformat_save'], isNull);
    expect(json['luckysheet_alternateformat_save_modelCustom'], isNull);
    expect(json['pivotTable'], isNull);
    expect(json['dynamicArray_compute'], isNull);
    expect(json['dynamicArray'], isNull);
    expect(changedJson['luckysheet_select_save'], isA<List>());
    expect(changedJson['luckysheet_selection_range'], isA<List>());
    expect(changedJson['calcChain'], isA<List>());
    expect(changedJson['filter_select'], isA<Map>());
    expect(changedJson['luckysheet_conditionformat_save'], isA<List>());
    expect(changedJson['luckysheet_alternateformat_save'], isA<List>());
    expect(
      changedJson['luckysheet_alternateformat_save_modelCustom'],
      isA<List>(),
    );
    expect(changedJson['pivotTable'], {'enabled': true});
    expect(changedJson['dynamicArray_compute'], {'0_0': true});
    expect(changedJson['dynamicArray'], isA<List>());

    json
      ..['luckysheet_select_save'] = [
        {
          'row': [0, 0],
        },
      ]
      ..['luckysheet_selection_range'] = [
        {
          'column': [1, 1],
        },
      ]
      ..['calcChain'] = [
        {'r': 0, 'c': 0},
      ]
      ..['filter_select'] = {
        'row': [0, 10],
        'column': [1, 1],
      }
      ..['luckysheet_conditionformat_save'] = [
        {'type': 'cellIs'},
      ]
      ..['luckysheet_alternateformat_save'] = [
        {'range': 'A1:B2'},
      ]
      ..['luckysheet_alternateformat_save_modelCustom'] = [
        {'key': 'custom', 'text': 'Custom'},
      ]
      ..['pivotTable'] = {'enabled': true}
      ..['dynamicArray_compute'] = {'0_0': true}
      ..['dynamicArray'] = [
        {'r': 0, 'c': 0},
      ];
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['luckysheet_select_save'], isNull);
    expect(reexported['luckysheet_selection_range'], isNull);
    expect(reexported['calcChain'], isNull);
    expect(reexported['filter_select'], isNull);
    expect(reexported['luckysheet_conditionformat_save'], isNull);
    expect(reexported['luckysheet_alternateformat_save'], isNull);
    expect(reexported['luckysheet_alternateformat_save_modelCustom'], isNull);
    expect(reexported['pivotTable'], isNull);
    expect(reexported['dynamicArray_compute'], isNull);
    expect(reexported['dynamicArray'], isNull);
  });

  test('sheetFromJson snapshots object metadata fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'luckysheet_select_save': [
        {
          'row': [0, 0],
          'column': [1, 1],
        },
      ],
      'luckysheet_selection_range': [
        {
          'row': [2, 2],
          'column': [3, 3],
        },
      ],
      'filter_select': {
        'row': [0, 10],
        'column': [1, 1],
      },
      'luckysheet_conditionformat_save': [
        {'type': 'cellIs'},
      ],
      'luckysheet_alternateformat_save': [
        {'range': 'A1:B2'},
      ],
      'luckysheet_alternateformat_save_modelCustom': [
        {
          'key': 'custom',
          'format': {
            'head': {'fc': '#ffffff'},
          },
        },
      ],
      'pivotTable': {
        'enabled': true,
        'range': {
          'row': [0, 1],
        },
      },
      'dynamicArray_compute': {
        '0_0': {'r': 0, 'c': 0},
      },
      'calcChain': [
        {'r': 0, 'c': 0},
      ],
      'dynamicArray': [
        {'r': 0, 'c': 0},
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceSelection = source['luckysheet_select_save']! as List;
    final sourceSelectionRow = (sourceSelection.single as Map)['row'] as List;
    sourceSelectionRow[0] = 9;
    final sourceSelectionRange = source['luckysheet_selection_range']! as List;
    final sourceSelectionRangeColumn =
        (sourceSelectionRange.single as Map)['column'] as List;
    sourceSelectionRangeColumn[0] = 99;
    final sourceFilterSelect = source['filter_select']! as Map;
    final sourceFilterSelectRow = sourceFilterSelect['row'] as List;
    sourceFilterSelectRow[1] = 99;
    final sourceConditionFormat =
        (source['luckysheet_conditionformat_save']! as List).single as Map;
    sourceConditionFormat['type'] = 'mutated';
    final sourceAlternateFormat =
        (source['luckysheet_alternateformat_save']! as List).single as Map;
    sourceAlternateFormat['range'] = 'Z9';
    final sourceAlternateFormatCustomModel =
        (source['luckysheet_alternateformat_save_modelCustom']! as List).single
            as Map;
    ((sourceAlternateFormatCustomModel['format']! as Map)['head']!
            as Map)['fc'] =
        '#000000';
    final sourcePivotTable = source['pivotTable']! as Map;
    ((sourcePivotTable['range']! as Map)['row']! as List)[0] = 9;
    final sourceDynamicArrayCompute = source['dynamicArray_compute']! as Map;
    final sourceDynamicArrayAnchor = sourceDynamicArrayCompute['0_0']! as Map;
    sourceDynamicArrayAnchor['r'] = 9;
    ((source['calcChain']! as List).single as Map)['r'] = 9;
    ((source['dynamicArray']! as List).single as Map)['c'] = 9;

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(json['luckysheet_select_save'], [
      {
        'row': [0, 0],
        'column': [1, 1],
      },
    ]);
    expect(json['luckysheet_selection_range'], [
      {
        'row': [2, 2],
        'column': [3, 3],
      },
    ]);
    expect(json['filter_select'], {
      'row': [0, 10],
      'column': [1, 1],
    });
    expect(json['luckysheet_conditionformat_save'], [
      {'type': 'cellIs'},
    ]);
    expect(json['luckysheet_alternateformat_save'], [
      {'range': 'A1:B2'},
    ]);
    expect(json['luckysheet_alternateformat_save_modelCustom'], [
      {
        'key': 'custom',
        'format': {
          'head': {'fc': '#ffffff'},
        },
      },
    ]);
    expect(json['pivotTable'], {
      'enabled': true,
      'range': {
        'row': [0, 1],
      },
    });
    expect(json['dynamicArray_compute'], {
      '0_0': {'r': 0, 'c': 0},
    });
    expect(json['calcChain'], [
      {'r': 0, 'c': 0},
    ]);
    expect(json['dynamicArray'], [
      {'r': 0, 'c': 0},
    ]);

    final exportedSelection = json['luckysheet_select_save']! as List;
    (((exportedSelection.single as Map)['row']! as List))[0] = 7;
    final exportedSelectionRange = json['luckysheet_selection_range']! as List;
    (((exportedSelectionRange.single as Map)['column']! as List))[0] = 77;
    final exportedFilterSelect = json['filter_select']! as Map;
    (exportedFilterSelect['row']! as List)[1] = 77;
    final exportedConditionFormat =
        (json['luckysheet_conditionformat_save']! as List).single as Map;
    exportedConditionFormat['type'] = 'mutated';
    final exportedAlternateFormat =
        (json['luckysheet_alternateformat_save']! as List).single as Map;
    exportedAlternateFormat['range'] = 'Z9';
    final exportedAlternateFormatCustomModel =
        (json['luckysheet_alternateformat_save_modelCustom']! as List).single
            as Map;
    ((exportedAlternateFormatCustomModel['format']! as Map)['head']!
            as Map)['fc'] =
        '#000000';
    final exportedPivotTable = json['pivotTable']! as Map;
    ((exportedPivotTable['range']! as Map)['row']! as List)[0] = 7;
    final exportedDynamicArrayCompute = json['dynamicArray_compute']! as Map;
    final exportedDynamicArrayAnchor =
        exportedDynamicArrayCompute['0_0']! as Map;
    exportedDynamicArrayAnchor['r'] = 7;
    ((json['calcChain']! as List).single as Map)['r'] = 7;
    ((json['dynamicArray']! as List).single as Map)['c'] = 7;

    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['luckysheet_select_save'], [
      {
        'row': [0, 0],
        'column': [1, 1],
      },
    ]);
    expect(reexported['luckysheet_selection_range'], [
      {
        'row': [2, 2],
        'column': [3, 3],
      },
    ]);
    expect(reexported['filter_select'], {
      'row': [0, 10],
      'column': [1, 1],
    });
    expect(reexported['luckysheet_conditionformat_save'], [
      {'type': 'cellIs'},
    ]);
    expect(reexported['luckysheet_alternateformat_save'], [
      {'range': 'A1:B2'},
    ]);
    expect(reexported['luckysheet_alternateformat_save_modelCustom'], [
      {
        'key': 'custom',
        'format': {
          'head': {'fc': '#ffffff'},
        },
      },
    ]);
    expect(reexported['pivotTable'], {
      'enabled': true,
      'range': {
        'row': [0, 1],
      },
    });
    expect(reexported['dynamicArray_compute'], {
      '0_0': {'r': 0, 'c': 0},
    });
    expect(reexported['calcChain'], [
      {'r': 0, 'c': 0},
    ]);
    expect(reexported['dynamicArray'], [
      {'r': 0, 'c': 0},
    ]);
  });

  test('sheet copyWith can explicitly clear object metadata to null', () {
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'luckysheet_select_save': [
        {
          'row': [0, 0],
        },
      ],
      'luckysheet_selection_range': [
        {
          'column': [1, 1],
        },
      ],
      'calcChain': [
        {'r': 0, 'c': 0},
      ],
      'filter_select': {
        'row': [0, 10],
      },
      'luckysheet_conditionformat_save': [
        {'type': 'cellIs'},
      ],
      'luckysheet_alternateformat_save': [
        {'range': 'A1:B2'},
      ],
      'luckysheet_alternateformat_save_modelCustom': [
        {'key': 'custom', 'text': 'Custom'},
      ],
      'pivotTable': {'enabled': true},
      'dynamicArray_compute': {'0_0': true},
      'dynamicArray': [
        {'r': 0, 'c': 0},
      ],
    });
    final cleared = sheet.copyWith(
      selectionSave: null,
      selectionRange: null,
      calcChain: null,
      filterSelect: null,
      conditionFormats: null,
      alternateFormats: null,
      alternateFormatCustomModels: null,
      pivotTable: null,
      dynamicArrayCompute: null,
      dynamicArray: null,
    );

    final json = FortuneSheetCodec.sheetToJson(cleared);

    expect(json.containsKey('luckysheet_select_save'), isTrue);
    expect(json['luckysheet_select_save'], isNull);
    expect(json.containsKey('luckysheet_selection_range'), isTrue);
    expect(json['luckysheet_selection_range'], isNull);
    expect(json.containsKey('calcChain'), isTrue);
    expect(json['calcChain'], isNull);
    expect(json.containsKey('filter_select'), isTrue);
    expect(json['filter_select'], isNull);
    expect(json.containsKey('luckysheet_conditionformat_save'), isTrue);
    expect(json['luckysheet_conditionformat_save'], isNull);
    expect(json.containsKey('luckysheet_alternateformat_save'), isTrue);
    expect(json['luckysheet_alternateformat_save'], isNull);
    expect(
      json.containsKey('luckysheet_alternateformat_save_modelCustom'),
      isTrue,
    );
    expect(json['luckysheet_alternateformat_save_modelCustom'], isNull);
    expect(json.containsKey('pivotTable'), isTrue);
    expect(json['pivotTable'], isNull);
    expect(json.containsKey('dynamicArray_compute'), isTrue);
    expect(json['dynamicArray_compute'], isNull);
    expect(json.containsKey('dynamicArray'), isTrue);
    expect(json['dynamicArray'], isNull);

    json
      ..['luckysheet_select_save'] = [
        {
          'row': [0, 0],
        },
      ]
      ..['luckysheet_selection_range'] = [
        {
          'column': [1, 1],
        },
      ]
      ..['calcChain'] = [
        {'r': 0, 'c': 0},
      ]
      ..['filter_select'] = {
        'row': [0, 10],
      }
      ..['luckysheet_conditionformat_save'] = [
        {'type': 'cellIs'},
      ]
      ..['luckysheet_alternateformat_save'] = [
        {'range': 'A1:B2'},
      ]
      ..['luckysheet_alternateformat_save_modelCustom'] = [
        {'key': 'custom', 'text': 'Custom'},
      ]
      ..['pivotTable'] = {'enabled': true}
      ..['dynamicArray_compute'] = {'0_0': true}
      ..['dynamicArray'] = [
        {'r': 0, 'c': 0},
      ];
    final reexported = FortuneSheetCodec.sheetToJson(cleared);
    expect(reexported['luckysheet_select_save'], isNull);
    expect(reexported['luckysheet_selection_range'], isNull);
    expect(reexported['calcChain'], isNull);
    expect(reexported['filter_select'], isNull);
    expect(reexported['luckysheet_conditionformat_save'], isNull);
    expect(reexported['luckysheet_alternateformat_save'], isNull);
    expect(reexported['luckysheet_alternateformat_save_modelCustom'], isNull);
    expect(reexported['pivotTable'], isNull);
    expect(reexported['dynamicArray_compute'], isNull);
    expect(reexported['dynamicArray'], isNull);
  });

  test(
    'sheet copyWith can explicitly clear config permission fields to null',
    () {
      final sheet = FortuneSheetCodec.sheetFromJson({
        'id': 's1',
        'name': 'Sheet1',
        'config': {
          'authority': {'sheet': 1},
          'rowReadOnly': {'1': 1},
          'colReadOnly': {'2': 1},
        },
      });
      final cleared = sheet.copyWith(
        authority: null,
        rowReadOnly: null,
        colReadOnly: null,
      );

      final config = FortuneSheetCodec.sheetToJson(cleared)['config']! as Map;

      expect(config.containsKey('authority'), isTrue);
      expect(config['authority'], isNull);
      expect(config.containsKey('rowReadOnly'), isTrue);
      expect(config['rowReadOnly'], isNull);
      expect(config.containsKey('colReadOnly'), isTrue);
      expect(config['colReadOnly'], isNull);

      config
        ..['authority'] = {'sheet': 1}
        ..['rowReadOnly'] = {'1': 1}
        ..['colReadOnly'] = {'2': 1};
      final reexportedConfig =
          FortuneSheetCodec.sheetToJson(cleared)['config']! as Map;
      expect(reexportedConfig.containsKey('authority'), isTrue);
      expect(reexportedConfig['authority'], isNull);
      expect(reexportedConfig.containsKey('rowReadOnly'), isTrue);
      expect(reexportedConfig['rowReadOnly'], isNull);
      expect(reexportedConfig.containsKey('colReadOnly'), isTrue);
      expect(reexportedConfig['colReadOnly'], isNull);
    },
  );

  test('cellToJson writes numeric style ids as numbers', () {
    const indexed = FortuneCell(
      fontFamily: '2',
      horizontalAlign: '0',
      verticalAlign: '1',
    );
    const named = FortuneCell(fontFamily: 'Tahoma');

    final indexedJson = FortuneSheetCodec.cellToJson(indexed);
    final namedJson = FortuneSheetCodec.cellToJson(named);

    expect(indexedJson['ff'], 2);
    expect(indexedJson['ht'], 0);
    expect(indexedJson['vt'], 1);
    expect(namedJson['ff'], 'Tahoma');

    indexedJson
      ..['ff'] = 'Tahoma'
      ..['ht'] = 2
      ..['vt'] = 0;
    namedJson['ff'] = 2;
    final reexportedIndexed = FortuneSheetCodec.cellToJson(indexed);
    final reexportedNamed = FortuneSheetCodec.cellToJson(named);
    expect(reexportedIndexed['ff'], 2);
    expect(reexportedIndexed['ht'], 0);
    expect(reexportedIndexed['vt'], 1);
    expect(reexportedNamed['ff'], 'Tahoma');
  });

  test('cellToJson can write inline rich text runs', () {
    const cell = FortuneCell(
      inlineRuns: [
        FortuneInlineTextRun(text: 'Hello', bold: true),
        FortuneInlineTextRun(
          text: ' World',
          foreground: Color(0xff188038),
          italic: false,
          strikeThrough: true,
          underline: false,
          fontSize: 12.5,
          fontFamily: '2',
          wrap: false,
          extraFields: {'customRunMeta': 'preserve'},
        ),
        FortuneInlineTextRun(
          text: ' Raw',
          rawForeground: 'theme-accent-1',
          hasRawForeground: true,
        ),
      ],
    );

    final json = FortuneSheetCodec.cellToJson(cell);
    final cellType = json['ct']! as Map;
    final runs = cellType['s']! as List;

    expect(cellType['t'], 'inlineStr');
    expect(runs[0], {'v': 'Hello', 'bl': 1});
    expect(runs[1], {
      'customRunMeta': 'preserve',
      'v': ' World',
      'fc': '#188038',
      'it': 0,
      'cl': 1,
      'un': 0,
      'fs': 12.5,
      'ff': 2,
      'wrap': false,
    });
    expect(runs[2], {'v': ' Raw', 'fc': 'theme-accent-1'});

    cellType['t'] = 'mutated';
    runs
      ..clear()
      ..add({'v': 'mutated'});
    final reexported = FortuneSheetCodec.cellToJson(cell);
    final reexportedCellType = reexported['ct']! as Map;
    final reexportedRuns = reexportedCellType['s']! as List;
    expect(reexportedCellType['t'], 'inlineStr');
    expect(reexportedRuns[0], {'v': 'Hello', 'bl': 1});
    expect(reexportedRuns[1], {
      'customRunMeta': 'preserve',
      'v': ' World',
      'fc': '#188038',
      'it': 0,
      'cl': 1,
      'un': 0,
      'fs': 12.5,
      'ff': 2,
      'wrap': false,
    });
    expect(reexportedRuns[2], {'v': ' Raw', 'fc': 'theme-accent-1'});
  });

  test('sheetFromJson reads celldata and config', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'order': 3,
      'row': 120,
      'column': 40,
      'addRows': 10,
      'status': 1,
      'color': '#188038',
      'hide': 0,
      'defaultRowHeight': 21,
      'defaultColWidth': 88,
      'zoomRatio': 1.25,
      'showGridLines': 0,
      'luckysheet_select_save': [
        {
          'row': [0, 1],
          'column': [0, 1],
        },
      ],
      'luckysheet_selection_range': [
        {
          'row': [2, 2],
          'column': [3, 3],
        },
      ],
      'calcChain': [
        {'r': 0, 'c': 0},
      ],
      'filter_select': {
        'row': [0, 10],
        'column': [1, 1],
      },
      'luckysheet_conditionformat_save': [
        {'type': 'cellIs'},
      ],
      'luckysheet_alternateformat_save': [
        {'range': 'A1:B2'},
      ],
      'pivotTable': {'enabled': true},
      'isPivotTable': 1,
      'dynamicArray_compute': {'0_0': true},
      'dynamicArray': [
        {'r': 0, 'c': 0},
      ],
      'customSheetMeta': {'flag': true},
      'images': [
        {
          'id': 'img1',
          'src': 'data:image/png;base64,test',
          'left': 10,
          'top': 20,
          'width': 30,
          'height': 40,
          'crop': {'x': 1, 'y': 2},
          'border': 'solid',
        },
      ],
      'dataVerification': {
        '0_0': {'type': 'dropdown'},
      },
      'filter': {
        '0': {'caljs': {}},
      },
      'frozen': {
        'type': 'rangeBoth',
        'customFrozenMeta': {'source': 'fixture'},
        'range': {
          'row_focus': 2,
          'column_focus': 1,
          'customRangeMeta': {'label': 'pane'},
        },
      },
      'config': {
        'rowlen': {'1': 29},
        'columnlen': {'2': 99},
        'customHeight': {'1': 1},
        'customWidth': {'2': 1},
        'rowhidden': {'3': 7},
        'colhidden': {'4': 9},
        'authority': {'sheet': 1},
        'rowReadOnly': {'1': 1},
        'colReadOnly': {'2': 1},
        'customConfigMeta': {'mode': 'preserve'},
        'merge': {
          '2_1': {
            'r': 2,
            'c': 1,
            'rs': 2,
            'cs': 3,
            'customMergeMeta': {'origin': 'config'},
          },
        },
        'borderInfo': [
          {
            'rangeType': 'range',
            'borderType': 'border-all',
            'color': '#0188fb',
            'style': 2,
            'customBorderMeta': {'source': 'fixture'},
            'range': [
              {
                'row': [0, 1],
                'column': [0, 1],
                'customRangeMeta': {'label': 'top-left'},
              },
            ],
          },
        ],
      },
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'A1'},
        },
        {
          'r': 0,
          'c': 1,
          'v': {'v': 'B1'},
        },
        {'r': 1, 'c': 1, 'v': null},
      ],
      'hyperlink': {
        '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      },
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    (source['customSheetMeta']! as Map)['flag'] = false;
    final sourceConfig = source['config']! as Map;
    (sourceConfig['customConfigMeta']! as Map)['mode'] = 'mutated';
    ((sourceConfig['merge']! as Map)['2_1']! as Map)['customMergeMeta'] = {
      'origin': 'mutated',
    };
    (((source['celldata']! as List).first as Map)['v']! as Map)['v'] =
        'mutated';
    ((source['hyperlink']! as Map)['0_1']! as Map)['linkAddress'] =
        'https://mutated.test';

    expect(sheet.id, 's1');
    expect(sheet.name, 'Sheet1');
    expect(sheet.order, 3);
    expect(sheet.rowCount, 120);
    expect(sheet.columnCount, 40);
    expect(sheet.addRows, 10);
    expect(sheet.status, 1);
    expect(sheet.color, '#188038');
    expect(sheet.hide, 0);
    expect(sheet.defaultRowHeight, 21);
    expect(sheet.defaultColWidth, 88);
    expect(sheet.zoomRatio, 1.25);
    expect(sheet.showGridLines, isFalse);
    expect(sheet.selectionSave, isA<List>());
    expect(sheet.selectionRange, isA<List>());
    expect(sheet.calcChain, isA<List>());
    expect(sheet.filterSelect, isA<Map>());
    expect(sheet.conditionFormats, isA<List>());
    expect(sheet.alternateFormats, isA<List>());
    expect(sheet.pivotTable, isA<Map>());
    expect(sheet.isPivotTable, isTrue);
    expect(sheet.dynamicArrayCompute, isA<Map>());
    expect(sheet.dynamicArray, isA<List>());
    expect(sheet.extraFields['customSheetMeta'], isA<Map>());
    expect(sheet.configExtraFields['customConfigMeta'], isA<Map>());
    expect(sheet.authority, isA<Map>());
    expect(sheet.rowReadOnly, isA<Map>());
    expect(sheet.colReadOnly, isA<Map>());
    expect(sheet.images, hasLength(1));
    expect(sheet.images.first.id, 'img1');
    expect(sheet.images.first.extraFields['crop'], {'x': 1, 'y': 2});
    expect(sheet.images.first.extraFields['border'], 'solid');
    expect(sheet.dataVerification['0_0'], isA<Map>());
    expect(sheet.filter['0'], isA<Map>());
    expect(sheet.hyperlinks['0_1'], isA<Map>());
    expect(sheet.frozen?.type, 'rangeBoth');
    expect(sheet.frozen?.rowFocus, 2);
    expect(sheet.frozen?.columnFocus, 1);
    expect(sheet.frozen?.extraFields['customFrozenMeta'], {
      'source': 'fixture',
    });
    expect(sheet.frozen?.rangeExtraFields['customRangeMeta'], {
      'label': 'pane',
    });
    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, 'A1');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'B1');
    expect(sheet.nullCells, contains(const FortuneCellCoord(1, 1)));
    expect(
      sheet.cells[const FortuneCellCoord(0, 1)]?.hyperlink?.linkAddress,
      'https://example.test',
    );
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.hyperlink?.id, 's1');
    expect(sheet.rowHeights[1], 29);
    expect(sheet.columnWidths[2], 99);
    expect(sheet.customHeight[1], 1);
    expect(sheet.customWidth[2], 1);
    expect(sheet.hiddenRows, contains(3));
    expect(sheet.hiddenColumns, contains(4));
    expect(sheet.hiddenRowValues[3], 7);
    expect(sheet.hiddenColumnValues[4], 9);
    final mergeAnchor = sheet.cells[const FortuneCellCoord(2, 1)]?.merge;
    expect(mergeAnchor?.row, 2);
    expect(mergeAnchor?.column, 1);
    expect(mergeAnchor?.rowSpan, 2);
    expect(mergeAnchor?.columnSpan, 3);
    expect(mergeAnchor?.extraFields['customMergeMeta'], {'origin': 'config'});
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.merge?.row, 2);
    expect(sheet.cells[const FortuneCellCoord(3, 3)]?.merge?.column, 1);
    expect(
      sheet.mergeAnchorFor(const FortuneCellCoord(3, 3)),
      const FortuneCellCoord(2, 1),
    );
    expect(sheet.borderInfo, hasLength(1));
    expect(sheet.borderInfo.first.borderType, 'border-all');
    expect(sheet.borderInfo.first.color, const Color(0xff0188fb));
    expect(sheet.borderInfo.first.style, 2);
    expect(sheet.borderInfo.first.extraFields['customBorderMeta'], {
      'source': 'fixture',
    });
    expect(sheet.borderInfo.first.ranges.first.rowEnd, 1);
    expect(sheet.borderInfo.first.ranges.first.extraFields['customRangeMeta'], {
      'label': 'top-left',
    });
  });

  test('sheetFromJson treats data matrix as authoritative over celldata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'stale'},
        },
        {'r': 1, 'c': 1, 'v': null},
      ],
      'data': [
        [
          null,
          {'v': 'matrix'},
        ],
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    (((source['celldata']! as List).first as Map)['v']! as Map)['v'] =
        'source-mutated';
    (((source['data']! as List).single as List)[1] as Map)['v'] =
        'source-mutated';

    expect(sheet.cells.containsKey(const FortuneCellCoord(0, 0)), isFalse);
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, 'matrix');
    expect(sheet.nullCells, isEmpty);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    expect(json.containsKey('celldata'), isFalse);
    expect(json['data'], [
      [
        null,
        {'v': 'matrix'},
      ],
    ]);

    (((json['data']! as List).single as List)[1] as Map)['v'] =
        'export-mutated';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('celldata'), isFalse);
    expect(reexported['data'], [
      [
        null,
        {'v': 'matrix'},
      ],
    ]);
  });

  test('sheetFromJson imports celldata shorthand scalar values', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {'r': 10, 'c': 11, 'v': 'value 2'},
        {'r': 0, 'c': 1, 'v': 12},
      ],
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final cell = sheet.cells[const FortuneCellCoord(10, 11)];
    final numberCell = sheet.cells[const FortuneCellCoord(0, 1)];

    expect(cell?.value, 'value 2');
    expect(cell?.displayValue, 'value 2');
    expect(cell?.cellType?.format, 'General');
    expect(cell?.cellType?.type, 'g');
    expect(numberCell?.value, '12');
    expect(numberCell?.displayValue, '12');
    expect(numberCell?.cellType?.format, 'General');
    expect(numberCell?.cellType?.type, 'n');
    expect(FortuneSheetCodec.sheetToJson(sheet)['celldata'], [
      {'r': 10, 'c': 11, 'v': 'value 2'},
      {'r': 0, 'c': 1, 'v': 12},
    ]);
  });

  test('sheetToJson preserves unchanged raw data matrix', () {
    final sourceData = [
      [
        {'v': 'A1'},
        null,
        {'v': 3, 'm': 3},
      ],
      'invalid-row',
      [
        null,
        {'v': 'B2'},
      ],
    ];
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'data': sourceData,
    });
    final changed = sheet.copyWith(
      cells: {
        ...sheet.cells,
        const FortuneCellCoord(0, 0): sheet.cells[const FortuneCellCoord(0, 0)]!
            .withEditedValue('changed'),
      },
    );
    final sourceFirstRow = sourceData[0] as List<Object?>;
    final sourceFirstCell = sourceFirstRow[0] as Map;
    sourceFirstCell['v'] = 'mutated';
    final sourceThirdRow = sourceData[2] as List<Object?>;
    final sourceThirdCell = sourceThirdRow[1] as Map;
    sourceThirdCell['v'] = 'mutated';

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final data = json['data']! as List;

    expect(data, [
      [
        {'v': 'A1'},
        null,
        {'v': 3, 'm': 3},
      ],
      'invalid-row',
      [
        null,
        {'v': 'B2'},
      ],
    ]);
    expect(
      FortuneSheetCodec.sheetToJson(sheet).containsKey('celldata'),
      isFalse,
    );
    ((data[0] as List)[0] as Map)['v'] = 'export-mutated';
    ((data[2] as List)[1] as Map)['v'] = 'export-mutated';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['data'], [
      [
        {'v': 'A1'},
        null,
        {'v': 3, 'm': 3},
      ],
      'invalid-row',
      [
        null,
        {'v': 'B2'},
      ],
    ]);
    expect(reexported.containsKey('celldata'), isFalse);
    expect(FortuneSheetCodec.sheetToJson(changed).containsKey('data'), isFalse);
    expect(FortuneSheetCodec.sheetToJson(changed)['celldata'], [
      {
        'r': 0,
        'c': 0,
        'v': {'v': 'changed'},
      },
      {
        'r': 0,
        'c': 2,
        'v': {'v': 3, 'm': 3},
      },
      {
        'r': 2,
        'c': 1,
        'v': {'v': 'B2'},
      },
    ]);
  });

  test(
    'sheetToJson preserves raw data matrix with config metadata applied',
    () {
      final sheet = FortuneSheetCodec.sheetFromJson({
        'id': 's1',
        'name': 'Sheet1',
        'data': [
          [
            {'v': 'merged link'},
          ],
        ],
        'hyperlink': {
          '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
        },
        'config': {
          'merge': {
            '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
          },
        },
      });

      final json = FortuneSheetCodec.sheetToJson(sheet);
      final config = json['config']! as Map;

      expect(json['data'], [
        [
          {'v': 'merged link'},
        ],
      ]);
      expect(json.containsKey('celldata'), isFalse);
      expect(json['hyperlink'], {
        '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      });
      expect(config['merge'], {
        '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
      });

      (((json['data']! as List).single) as List)[0] = {'v': 'mutated'};
      ((json['hyperlink']! as Map)['0_0']! as Map)['linkAddress'] =
          'https://mutated.test';
      ((config['merge']! as Map)['0_0']! as Map)['rs'] = 9;
      final reexported = FortuneSheetCodec.sheetToJson(sheet);
      expect(reexported['data'], [
        [
          {'v': 'merged link'},
        ],
      ]);
      expect(reexported['hyperlink'], {
        '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      });
      expect((reexported['config']! as Map)['merge'], {
        '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
      });
    },
  );

  test('sheetToJson preserves explicit empty null and invalid data fields', () {
    final emptyData = <Object?>[];
    final emptySheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'data': emptyData,
    });
    emptyData.add([
      {'v': 'source-mutated'},
    ]);
    final nullSource = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'data': null,
    };
    final nullSheet = FortuneSheetCodec.sheetFromJson(nullSource);
    nullSource['data'] = [];
    final invalidSource = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'data': 'invalid',
    };
    final invalidSheet = FortuneSheetCodec.sheetFromJson(invalidSource);
    invalidSource['data'] = [];

    final emptyJson = FortuneSheetCodec.sheetToJson(emptySheet);
    final nullJson = FortuneSheetCodec.sheetToJson(nullSheet);
    final invalidJson = FortuneSheetCodec.sheetToJson(invalidSheet);

    expect(emptyJson['data'], isEmpty);
    expect(nullJson['data'], isNull);
    expect(invalidJson['data'], 'invalid');

    (emptyJson['data']! as List).add([
      {'v': 'export-mutated'},
    ]);
    nullJson['data'] = [];
    invalidJson['data'] = [];
    expect(FortuneSheetCodec.sheetToJson(emptySheet)['data'], isEmpty);
    expect(FortuneSheetCodec.sheetToJson(nullSheet)['data'], isNull);
    expect(FortuneSheetCodec.sheetToJson(invalidSheet)['data'], 'invalid');
  });

  test('sheetToJson preserves unchanged raw celldata list', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': '1',
          'c': 0,
          'v': {'v': 'B1'},
        },
        {
          'r': 0,
          'c': '0',
          'v': {'v': 'A1'},
        },
        {'rawOnly': true},
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceCelldata = source['celldata']! as List<Object?>;
    ((sourceCelldata[0]! as Map<Object?, Object?>)['v']!
            as Map<Object?, Object?>)['v'] =
        'mutated';
    (sourceCelldata[2]! as Map<Object?, Object?>)['rawOnly'] = false;
    final changed = sheet.copyWith(
      cells: {
        ...sheet.cells,
        const FortuneCellCoord(0, 0): sheet.cells[const FortuneCellCoord(0, 0)]!
            .withEditedValue('changed'),
      },
    );

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final celldata = json['celldata']! as List;

    expect(celldata, [
      {
        'r': '1',
        'c': 0,
        'v': {'v': 'B1'},
      },
      {
        'r': 0,
        'c': '0',
        'v': {'v': 'A1'},
      },
      {'rawOnly': true},
    ]);
    ((celldata[0] as Map)['v']! as Map)['v'] = 'export-mutated';
    (celldata[2] as Map)['rawOnly'] = false;
    expect(FortuneSheetCodec.sheetToJson(sheet)['celldata'], [
      {
        'r': '1',
        'c': 0,
        'v': {'v': 'B1'},
      },
      {
        'r': 0,
        'c': '0',
        'v': {'v': 'A1'},
      },
      {'rawOnly': true},
    ]);
    expect(FortuneSheetCodec.sheetToJson(changed)['celldata'], [
      {
        'r': 0,
        'c': 0,
        'v': {'v': 'changed'},
      },
      {
        'r': 1,
        'c': 0,
        'v': {'v': 'B1'},
      },
    ]);
  });

  test('sheetToJson preserves raw celldata with config metadata applied', () {
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'merged link'},
        },
      ],
      'hyperlink': {
        '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      },
      'config': {
        'merge': {
          '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
        },
      },
    });

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;

    expect(json['celldata'], [
      {
        'r': 0,
        'c': 0,
        'v': {'v': 'merged link'},
      },
    ]);
    expect(json['hyperlink'], {
      '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
    expect(config['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });

    (((json['celldata']! as List).single as Map)['v']! as Map)['v'] = 'mutated';
    ((json['hyperlink']! as Map)['0_0']! as Map)['linkAddress'] =
        'https://mutated.test';
    ((config['merge']! as Map)['0_0']! as Map)['rs'] = 9;
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['celldata'], [
      {
        'r': 0,
        'c': 0,
        'v': {'v': 'merged link'},
      },
    ]);
    expect(reexported['hyperlink'], {
      '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
    expect((reexported['config']! as Map)['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });
  });

  test(
    'sheetToJson preserves explicit empty null and invalid celldata fields',
    () {
      final emptyCelldata = <Object?>[];
      final emptySheet = FortuneSheetCodec.sheetFromJson({
        'id': 's1',
        'name': 'Sheet1',
        'celldata': emptyCelldata,
      });
      emptyCelldata.add({'rawOnly': 'source-mutated'});
      final nullSource = <String, Object?>{
        'id': 's1',
        'name': 'Sheet1',
        'celldata': null,
      };
      final nullSheet = FortuneSheetCodec.sheetFromJson(nullSource);
      nullSource['celldata'] = [];
      final invalidCelldata = <Object?>[
        {'rawOnly': true},
      ];
      final invalidSheet = FortuneSheetCodec.sheetFromJson({
        'id': 's1',
        'name': 'Sheet1',
        'celldata': invalidCelldata,
      });
      (invalidCelldata.single as Map)['rawOnly'] = false;

      final emptyJson = FortuneSheetCodec.sheetToJson(emptySheet);
      expect(emptyJson['celldata'], isEmpty);
      final nullJson = FortuneSheetCodec.sheetToJson(nullSheet);
      expect(nullJson.containsKey('celldata'), isTrue);
      expect(nullJson['celldata'], isNull);
      final clonedNullJson = FortuneSheetCodec.sheetToJson(
        nullSheet.copyWith(),
      );
      expect(clonedNullJson.containsKey('celldata'), isTrue);
      expect(clonedNullJson['celldata'], isNull);
      expect(FortuneSheetCodec.sheetToJson(invalidSheet)['celldata'], [
        {'rawOnly': true},
      ]);

      (emptyJson['celldata']! as List).add({'rawOnly': 'export-mutated'});
      nullJson['celldata'] = [];
      final invalidJson = FortuneSheetCodec.sheetToJson(invalidSheet);
      ((invalidJson['celldata']! as List).single as Map)['rawOnly'] = false;
      expect(FortuneSheetCodec.sheetToJson(emptySheet)['celldata'], isEmpty);
      final reexportedNullJson = FortuneSheetCodec.sheetToJson(nullSheet);
      expect(reexportedNullJson.containsKey('celldata'), isTrue);
      expect(reexportedNullJson['celldata'], isNull);
      expect(FortuneSheetCodec.sheetToJson(invalidSheet)['celldata'], [
        {'rawOnly': true},
      ]);
    },
  );

  test('sheetToJson does not resurrect cleared raw celldata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'A1'},
        },
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source).copyWith(cells: {});
    (((source['celldata']! as List).single as Map)['v']! as Map)['v'] =
        'source-mutated';

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(json.containsKey('celldata'), isFalse);

    json['celldata'] = [
      {
        'r': 0,
        'c': 0,
        'v': {'v': 'export-mutated'},
      },
    ];
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('celldata'), isFalse);
  });

  test('sheetToJson does not resurrect cleared raw merge and hidden axes', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'merge': {
          '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
        },
        'rowhidden': {'1': 0},
        'colhidden': {'2': 0},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source).copyWith(
      cells: {},
      hiddenRows: {},
      hiddenColumns: {},
      hiddenRowValues: {},
      hiddenColumnValues: {},
    );
    final sourceConfig = source['config']! as Map;
    ((sourceConfig['merge']! as Map)['0_0']! as Map)['rs'] = 9;
    (sourceConfig['rowhidden']! as Map)['1'] = 9;
    (sourceConfig['colhidden']! as Map)['2'] = 9;

    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(json.containsKey('config'), isFalse);

    json['config'] = {
      'merge': {
        '0_0': {'r': 9, 'c': 9, 'rs': 9, 'cs': 9},
      },
      'rowhidden': {'1': 9},
      'colhidden': {'2': 9},
    };
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('config'), isFalse);
  });

  test(
    'sheet hyperlink map enriches existing cell hyperlink without losing id',
    () {
      final source = {
        'id': 's1',
        'name': 'Sheet1',
        'celldata': [
          {
            'r': 0,
            'c': 0,
            'v': {
              'v': 'link',
              'hl': {
                'r': 0,
                'c': 0,
                'id': 'h1',
                'cellLinkMeta': {
                  'events': [
                    {'value': 'cell'},
                  ],
                },
              },
            },
          },
        ],
        'hyperlink': {
          '0_0': {
            'linkType': 'webpage',
            'linkAddress': 'https://example.test',
            'tooltip': 'open example',
            'customLinkMeta': {
              'events': [
                {'value': 'open'},
              ],
            },
          },
        },
      };
      final sheet = FortuneSheetCodec.sheetFromJson(source);
      final sourceCellHyperlink =
          (((source['celldata']! as List).single as Map)['v']! as Map)['hl']!
              as Map;
      final sourceCellMeta = sourceCellHyperlink['cellLinkMeta']! as Map;
      ((sourceCellMeta['events']! as List).single as Map)['value'] = 'mutated';
      final sourceHyperlink =
          ((source['hyperlink']! as Map)['0_0']! as Map)['customLinkMeta']!
              as Map;
      ((sourceHyperlink['events']! as List).single as Map)['value'] = 'mutated';

      final hyperlink = sheet.cells[const FortuneCellCoord(0, 0)]!.hyperlink!;

      expect(hyperlink.id, 'h1');
      expect(hyperlink.row, 0);
      expect(hyperlink.column, 0);
      expect(hyperlink.linkType, 'webpage');
      expect(hyperlink.linkAddress, 'https://example.test');
      expect(hyperlink.extraFields['cellLinkMeta'], {
        'events': [
          {'value': 'cell'},
        ],
      });
      expect(hyperlink.extraFields['tooltip'], 'open example');
      expect(hyperlink.extraFields['customLinkMeta'], {
        'events': [
          {'value': 'open'},
        ],
      });

      final cellJson = FortuneSheetCodec.cellToJson(
        sheet.cells[const FortuneCellCoord(0, 0)]!,
      );
      expect(cellJson['hl'], {
        'cellLinkMeta': {
          'events': [
            {'value': 'cell'},
          ],
        },
        'tooltip': 'open example',
        'customLinkMeta': {
          'events': [
            {'value': 'open'},
          ],
        },
        'r': 0,
        'c': 0,
        'id': 'h1',
        'linkType': 'webpage',
        'linkAddress': 'https://example.test',
      });

      final exportedHyperlink = cellJson['hl']! as Map;
      (exportedHyperlink['cellLinkMeta']! as Map)['events'] = [
        {'value': 'export-mutated'},
      ];
      (exportedHyperlink['customLinkMeta']! as Map)['events'] = [
        {'value': 'export-mutated'},
      ];
      exportedHyperlink['linkAddress'] = 'https://export-mutated.test';
      expect(
        FortuneSheetCodec.cellToJson(
          sheet.cells[const FortuneCellCoord(0, 0)]!,
        )['hl'],
        {
          'cellLinkMeta': {
            'events': [
              {'value': 'cell'},
            ],
          },
          'tooltip': 'open example',
          'customLinkMeta': {
            'events': [
              {'value': 'open'},
            ],
          },
          'r': 0,
          'c': 0,
          'id': 'h1',
          'linkType': 'webpage',
          'linkAddress': 'https://example.test',
        },
      );
    },
  );

  test('sheet hyperlink map synthesizes cell hyperlink sheet id', () {
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'link'},
        },
      ],
      'hyperlink': {
        '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      },
    });

    final hyperlink = sheet.cells[const FortuneCellCoord(0, 0)]!.hyperlink!;
    expect(hyperlink.id, 's1');
    final json = FortuneSheetCodec.cellToJson(sheet.cells.values.single);
    final exportedHyperlink = json['hl']! as Map;
    expect(exportedHyperlink, {
      'r': 0,
      'c': 0,
      'id': 's1',
      'linkType': 'webpage',
      'linkAddress': 'https://example.test',
    });

    exportedHyperlink
      ..['id'] = 'mutated'
      ..['linkAddress'] = 'https://mutated.test';
    expect(FortuneSheetCodec.cellToJson(sheet.cells.values.single)['hl'], {
      'r': 0,
      'c': 0,
      'id': 's1',
      'linkType': 'webpage',
      'linkAddress': 'https://example.test',
    });
  });

  test('sheet hyperlink map does not synthesize empty celldata cells', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'hyperlink': {
        '2_3': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      },
    };
    final sheet = FortuneSheetCodec.sheetFromJson(source);
    ((source['hyperlink']! as Map)['2_3']! as Map)['linkAddress'] =
        'https://mutated.test';

    expect(sheet.hyperlinks['2_3'], isA<Map>());
    expect(sheet.cells.containsKey(const FortuneCellCoord(2, 3)), isFalse);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    expect(json.containsKey('celldata'), isFalse);
    expect(json['hyperlink'], {
      '2_3': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });

    ((json['hyperlink']! as Map)['2_3']! as Map)['linkAddress'] =
        'https://export-mutated.test';
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('celldata'), isFalse);
    expect(reexported['hyperlink'], {
      '2_3': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
  });

  test('sheetFromJson snapshots config extra metadata fields', () {
    final sourceConfigMeta = {
      'mode': 'preserve',
      'nested': [
        {'value': 'A'},
      ],
    };
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'config': {'customConfigMeta': sourceConfigMeta},
    });

    final sourceNested = sourceConfigMeta['nested'] as List;
    final sourceNestedMap = sourceNested.single as Map;
    sourceNestedMap['value'] = 'mutated';

    final config = FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;

    expect(sheet.configExtraFields['customConfigMeta'], {
      'mode': 'preserve',
      'nested': [
        {'value': 'A'},
      ],
    });
    expect(config['customConfigMeta'], {
      'mode': 'preserve',
      'nested': [
        {'value': 'A'},
      ],
    });

    final exportedMeta = config['customConfigMeta']! as Map;
    exportedMeta['mode'] = 'mutated';
    ((exportedMeta['nested']! as List).single as Map)['value'] = 'B';

    final reexportedConfig =
        FortuneSheetCodec.sheetToJson(sheet)['config']! as Map;
    expect(reexportedConfig['customConfigMeta'], {
      'mode': 'preserve',
      'nested': [
        {'value': 'A'},
      ],
    });
  });

  test('sheetFromJson snapshots top-level extra metadata fields', () {
    final source = {
      'id': 's1',
      'name': 'Sheet1',
      'customSheetMeta': {
        'owner': 'qa',
        'events': [
          {'type': 'open'},
        ],
      },
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceMeta = source['customSheetMeta']! as Map;
    sourceMeta['owner'] = 'mutated';
    (sourceMeta['events']! as List).add({'type': 'close'});

    expect(sheet.extraFields['customSheetMeta'], {
      'owner': 'qa',
      'events': [
        {'type': 'open'},
      ],
    });

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final exportedMeta = json['customSheetMeta']! as Map;
    exportedMeta['owner'] = 'export-mutated';
    ((exportedMeta['events']! as List).single as Map)['type'] = 'edited';

    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['customSheetMeta'], {
      'owner': 'qa',
      'events': [
        {'type': 'open'},
      ],
    });
  });

  test('sheet hyperlink map ignores malformed entries for cells', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'link'},
        },
      ],
      'hyperlink': {
        '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
        'bad': {'linkType': 'webpage'},
        '0_x': {'linkType': 'webpage'},
        '1_1': 'not a map',
        '2_3': {'linkType': 'webpage', 'linkAddress': 'https://empty.test'},
      },
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceHyperlinks = source['hyperlink']! as Map;
    (sourceHyperlinks['0_0']! as Map)['linkAddress'] = 'mutated';
    sourceHyperlinks['2_3'] = {'linkType': 'webpage'};

    final cell = sheet.cells[const FortuneCellCoord(0, 0)]!;
    expect(cell.hyperlink?.linkAddress, 'https://example.test');
    expect(sheet.cells.containsKey(const FortuneCellCoord(2, 3)), isFalse);
    expect(sheet.hyperlinks, {
      '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      'bad': {'linkType': 'webpage'},
      '0_x': {'linkType': 'webpage'},
      '1_1': 'not a map',
      '2_3': {'linkType': 'webpage', 'linkAddress': 'https://empty.test'},
    });

    final json = FortuneSheetCodec.sheetToJson(sheet);
    expect(json['hyperlink'], sheet.hyperlinks);
    final exportedHyperlinks = json['hyperlink']! as Map;
    (exportedHyperlinks['0_0']! as Map)['linkAddress'] = 'export-mutated';
    exportedHyperlinks['2_3'] = {'linkType': 'webpage'};

    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['hyperlink'], {
      '0_0': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
      'bad': {'linkType': 'webpage'},
      '0_x': {'linkType': 'webpage'},
      '1_1': 'not a map',
      '2_3': {'linkType': 'webpage', 'linkAddress': 'https://empty.test'},
    });
  });

  test('sheetToJson omits synthetic merge follower cells from celldata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'merge': {
          '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
        },
      },
      'celldata': [
        {
          'r': 0,
          'c': 0,
          'v': {
            'v': 'merged',
            'customCellMeta': {
              'events': [
                {'value': 'anchor'},
              ],
            },
          },
        },
      ],
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    final sourceMerge = sourceConfig['merge']! as Map;
    (sourceMerge['0_0']! as Map)['rs'] = 9;
    final sourceCellData = source['celldata']! as List;
    final sourceCellValue = (sourceCellData.single as Map)['v']! as Map;
    sourceCellValue['v'] = 'mutated';
    (((sourceCellValue['customCellMeta']! as Map)['events']! as List).single
            as Map)['value'] =
        'source-mutated';

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;
    final celldata = json['celldata']! as List;

    expect(celldata, hasLength(1));
    expect(celldata.single, {
      'r': 0,
      'c': 0,
      'v': {
        'customCellMeta': {
          'events': [
            {'value': 'anchor'},
          ],
        },
        'v': 'merged',
      },
    });
    expect(config['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });

    (((celldata.single as Map)['v']! as Map)['customCellMeta']!
        as Map)['events'] = [
      {'value': 'export-mutated'},
    ];
    ((celldata.single as Map)['v']! as Map)['v'] = 'export-mutated';
    (config['merge']! as Map)['0_0'] = {'r': 9, 'c': 9, 'rs': 9, 'cs': 9};
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported['celldata'], [
      {
        'r': 0,
        'c': 0,
        'v': {
          'customCellMeta': {
            'events': [
              {'value': 'anchor'},
            ],
          },
          'v': 'merged',
        },
      },
    ]);
    expect((reexported['config']! as Map)['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });
  });

  test('sheetToJson omits merge-only anchor cells from celldata', () {
    final source = <String, Object?>{
      'id': 's1',
      'name': 'Sheet1',
      'config': {
        'merge': {
          '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
        },
      },
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final sourceConfig = source['config']! as Map;
    final sourceMerge = sourceConfig['merge']! as Map;
    (sourceMerge['0_0']! as Map)['cs'] = 9;

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;

    expect(json.containsKey('celldata'), isFalse);
    expect(config['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });

    (config['merge']! as Map)['0_0'] = {'r': 9, 'c': 9, 'rs': 9, 'cs': 9};
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    expect(reexported.containsKey('celldata'), isFalse);
    expect((reexported['config']! as Map)['merge'], {
      '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 2},
    });
  });

  test('sheetToJson writes sheet metadata celldata and config', () {
    final sourceDataVerification = <String, Map<String, Object?>>{
      '0_0': {'type': 'dropdown'},
    };
    final sourceFilter = <String, Map<String, Object?>>{
      '0': {'caljs': <String, Object?>{}},
    };
    final sourceHyperlinks = <String, Map<String, Object?>>{
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    };
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      order: 3,
      rowCount: 120,
      columnCount: 40,
      addRows: 10,
      defaultRowHeight: 21,
      defaultColWidth: 88,
      status: 1,
      color: '#188038',
      hide: 0,
      zoomRatio: 1.25,
      showGridLines: false,
      visibleDataRows: [0, 21, 42],
      visibleDataColumns: [0, 88, 176],
      sheetWidth: 2322,
      sheetHeight: 949,
      frozen: const FortuneFrozenPane(
        type: 'rangeBoth',
        rowFocus: 2,
        columnFocus: 1,
        extraFields: {
          'customFrozenMeta': {'source': 'manual'},
        },
        rangeExtraFields: {
          'customRangeMeta': {'label': 'pane'},
        },
      ),
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1'),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: 'merged',
          merge: FortuneCellMerge(
            row: 2,
            column: 1,
            rowSpan: 2,
            columnSpan: 3,
            extraFields: {
              'customMergeMeta': {'origin': 'config'},
            },
          ),
        ),
        const FortuneCellCoord(3, 3): const FortuneCell(
          merge: FortuneCellMerge(row: 2, column: 1),
        ),
      },
      nullCells: {const FortuneCellCoord(1, 1)},
      rowHeights: {1: 29},
      columnWidths: {2: 99},
      customHeight: {1: 1},
      customWidth: {2: 1},
      hiddenRows: {3},
      hiddenColumns: {4},
      hiddenRowValues: {3: 7},
      hiddenColumnValues: {4: 9},
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff0188fb),
          style: 2,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 1,
              columnStart: 0,
              columnEnd: 1,
              extraFields: {
                'customRangeMeta': {'label': 'top-left'},
              },
            ),
          ],
          extraFields: {
            'customBorderMeta': {'source': 'fixture'},
          },
        ),
      ],
      images: const [
        FortuneImage(
          id: 'img1',
          src: 'data:image/png;base64,test',
          left: 10,
          top: 20,
          width: 30,
          height: 40,
          extraFields: {
            'crop': {'x': 1, 'y': 2},
            'border': 'solid',
          },
        ),
      ],
      dataVerification: sourceDataVerification,
      filter: sourceFilter,
      hyperlinks: sourceHyperlinks,
      selectionSave: [
        {
          'row': [0, 1],
          'column': [0, 1],
        },
      ],
      selectionRange: [
        {
          'row': [2, 2],
          'column': [3, 3],
        },
      ],
      calcChain: [
        {'r': 0, 'c': 0},
      ],
      filterSelect: {
        'row': [0, 10],
        'column': [1, 1],
      },
      conditionFormats: [
        {'type': 'cellIs'},
      ],
      alternateFormats: [
        {'range': 'A1:B2'},
      ],
      alternateFormatCustomModels: [
        {
          'key': 'custom',
          'format': {
            'head': {'fc': '#ffffff'},
          },
        },
      ],
      pivotTable: {'enabled': true},
      isPivotTable: true,
      dynamicArrayCompute: {'0_0': true},
      dynamicArray: [
        {'r': 0, 'c': 0},
      ],
      authority: {'sheet': 1},
      rowReadOnly: {'1': 1},
      colReadOnly: {'2': 1},
      extraFields: {
        'customSheetMeta': {'flag': true},
        'name': 'extra must not override mapped name',
      },
      configExtraFields: {
        'customConfigMeta': {'mode': 'preserve'},
        'rowlen': {'9': 9},
      },
    );

    sourceDataVerification['0_0']!['type'] = 'mutated';
    (sourceFilter['0']!['caljs']! as Map)['value'] = ['mutated'];
    sourceHyperlinks['0_1']!['linkAddress'] = 'https://source-mutated.test';

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final config = json['config']! as Map;
    final celldata = json['celldata']! as List;

    expect(json['id'], 's1');
    expect(json['name'], 'Sheet1');
    expect(json['customSheetMeta'], {'flag': true});
    expect(json['order'], 3);
    expect(json['row'], 120);
    expect(json['column'], 40);
    expect(json['addRows'], 10);
    expect(json['status'], 1);
    expect(json['color'], '#188038');
    expect(json['hide'], 0);
    expect(json['defaultRowHeight'], 21);
    expect(json['defaultColWidth'], 88);
    expect(json['zoomRatio'], 1.25);
    expect(json['showGridLines'], 0);
    expect(json['visibledatarow'], [0, 21, 42]);
    expect(json['visibledatacolumn'], [0, 88, 176]);
    expect(json['ch_width'], 2322);
    expect(json['rh_height'], 949);
    expect(json['frozen'], {
      'customFrozenMeta': {'source': 'manual'},
      'type': 'rangeBoth',
      'range': {
        'customRangeMeta': {'label': 'pane'},
        'row_focus': 2,
        'column_focus': 1,
      },
    });
    expect(config['rowlen'], {'1': 29});
    expect(config['columnlen'], {'2': 99});
    expect(config['customHeight'], {'1': 1});
    expect(config['customWidth'], {'2': 1});
    expect(config['rowhidden'], {'3': 7});
    expect(config['colhidden'], {'4': 9});
    expect(config['authority'], {'sheet': 1});
    expect(config['rowReadOnly'], {'1': 1});
    expect(config['colReadOnly'], {'2': 1});
    expect(config['customConfigMeta'], {'mode': 'preserve'});
    expect(config['merge'], {
      '2_1': {
        'customMergeMeta': {'origin': 'config'},
        'r': 2,
        'c': 1,
        'rs': 2,
        'cs': 3,
      },
    });
    expect(config['borderInfo'], [
      {
        'rangeType': 'range',
        'borderType': 'border-all',
        'color': '#0188fb',
        'style': 2,
        'customBorderMeta': {'source': 'fixture'},
        'range': [
          {
            'row': [0, 1],
            'column': [0, 1],
            'customRangeMeta': {'label': 'top-left'},
          },
        ],
      },
    ]);
    expect(celldata.first, {
      'r': 0,
      'c': 0,
      'v': {'v': 'A1'},
    });
    expect(
      celldata.any(
        (item) =>
            item is Map &&
            item['r'] == 1 &&
            item['c'] == 1 &&
            item['v'] == null,
      ),
      isTrue,
    );
    expect(
      celldata.any((item) {
        final value = (item as Map)['v'];
        return value is Map && value['v'] == 'merged';
      }),
      isTrue,
    );
    expect(json['images'], [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': 10,
        'top': 20,
        'width': 30,
        'height': 40,
        'crop': {'x': 1, 'y': 2},
        'border': 'solid',
      },
    ]);
    expect(json['dataVerification'], {
      '0_0': {'type': 'dropdown'},
    });
    expect(json['filter'], {
      '0': {'caljs': {}},
    });
    expect(json['hyperlink'], {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
    expect(json['luckysheet_select_save'], [
      {
        'row': [0, 1],
        'column': [0, 1],
      },
    ]);
    expect(json['luckysheet_selection_range'], [
      {
        'row': [2, 2],
        'column': [3, 3],
      },
    ]);
    expect(json['calcChain'], [
      {'r': 0, 'c': 0},
    ]);
    expect(json['filter_select'], {
      'row': [0, 10],
      'column': [1, 1],
    });
    expect(json['luckysheet_conditionformat_save'], [
      {'type': 'cellIs'},
    ]);
    expect(json['luckysheet_alternateformat_save'], [
      {'range': 'A1:B2'},
    ]);
    expect(json['luckysheet_alternateformat_save_modelCustom'], [
      {
        'key': 'custom',
        'format': {
          'head': {'fc': '#ffffff'},
        },
      },
    ]);
    expect(json['pivotTable'], {'enabled': true});
    expect(json['isPivotTable'], isTrue);
    expect(json['dynamicArray_compute'], {'0_0': true});
    expect(json['dynamicArray'], isA<List>());

    json
      ..['name'] = 'mutated'
      ..['customSheetMeta'] = {'flag': false}
      ..['visibledatarow'] = [9]
      ..['visibledatacolumn'] = [9]
      ..['ch_width'] = 9
      ..['rh_height'] = 9;
    config
      ..['rowlen'] = {'1': 1}
      ..['customConfigMeta'] = {'mode': 'mutated'};
    (config['merge']! as Map)['2_1'] = {'r': 9, 'c': 9, 'rs': 9, 'cs': 9};
    (celldata.first as Map)['v'] = {'v': 'mutated'};
    (json['images']! as List).clear();
    (json['dataVerification']! as Map)['0_0'] = {'type': 'mutated'};
    (json['filter']! as Map)['0'] = {
      'caljs': {
        'value': ['mutated'],
      },
    };
    (json['hyperlink']! as Map)['0_1'] = {
      'linkType': 'webpage',
      'linkAddress': 'https://mutated.test',
    };
    ((json['luckysheet_select_save']! as List).single as Map)['row'] = [9, 9];
    ((json['luckysheet_selection_range']! as List).single as Map)['column'] = [
      9,
      9,
    ];
    ((json['calcChain']! as List).single as Map)['r'] = 9;
    (json['filter_select']! as Map)['row'] = [9, 9];
    ((json['luckysheet_conditionformat_save']! as List).single as Map)['type'] =
        'mutated';
    ((json['luckysheet_alternateformat_save']! as List).single
            as Map)['range'] =
        'Z9:Z9';
    ((((json['luckysheet_alternateformat_save_modelCustom']! as List).single
                    as Map)['format']!
                as Map)['head']!
            as Map)['fc'] =
        '#000000';
    (json['pivotTable']! as Map)['enabled'] = false;
    (json['dynamicArray_compute']! as Map)['0_0'] = false;
    (json['dynamicArray']! as List).clear();
    final reexported = FortuneSheetCodec.sheetToJson(sheet);
    final reexportedConfig = reexported['config']! as Map;
    final reexportedCellData = reexported['celldata']! as List;
    expect(reexported['name'], 'Sheet1');
    expect(reexported['customSheetMeta'], {'flag': true});
    expect(reexported['visibledatarow'], [0, 21, 42]);
    expect(reexported['visibledatacolumn'], [0, 88, 176]);
    expect(reexported['ch_width'], 2322);
    expect(reexported['rh_height'], 949);
    expect(reexportedConfig['rowlen'], {'1': 29});
    expect(reexportedConfig['customConfigMeta'], {'mode': 'preserve'});
    expect(reexportedConfig['merge'], {
      '2_1': {
        'customMergeMeta': {'origin': 'config'},
        'r': 2,
        'c': 1,
        'rs': 2,
        'cs': 3,
      },
    });
    expect(reexportedCellData.first, {
      'r': 0,
      'c': 0,
      'v': {'v': 'A1'},
    });
    expect(reexported['images'], [
      {
        'id': 'img1',
        'src': 'data:image/png;base64,test',
        'left': 10,
        'top': 20,
        'width': 30,
        'height': 40,
        'crop': {'x': 1, 'y': 2},
        'border': 'solid',
      },
    ]);
    expect(reexported['dataVerification'], {
      '0_0': {'type': 'dropdown'},
    });
    expect(reexported['filter'], {
      '0': {'caljs': {}},
    });
    expect(reexported['hyperlink'], {
      '0_1': {'linkType': 'webpage', 'linkAddress': 'https://example.test'},
    });
    expect(reexported['luckysheet_select_save'], [
      {
        'row': [0, 1],
        'column': [0, 1],
      },
    ]);
    expect(reexported['luckysheet_selection_range'], [
      {
        'row': [2, 2],
        'column': [3, 3],
      },
    ]);
    expect(reexported['calcChain'], [
      {'r': 0, 'c': 0},
    ]);
    expect(reexported['filter_select'], {
      'row': [0, 10],
      'column': [1, 1],
    });
    expect(reexported['luckysheet_conditionformat_save'], [
      {'type': 'cellIs'},
    ]);
    expect(reexported['luckysheet_alternateformat_save'], [
      {'range': 'A1:B2'},
    ]);
    expect(reexported['luckysheet_alternateformat_save_modelCustom'], [
      {
        'key': 'custom',
        'format': {
          'head': {'fc': '#ffffff'},
        },
      },
    ]);
    expect(reexported['pivotTable'], {'enabled': true});
    expect(reexported['dynamicArray_compute'], {'0_0': true});
    expect(reexported['dynamicArray'], [
      {'r': 0, 'c': 0},
    ]);
  });

  test('sheetFromJson maps visible geometry runtime fields', () {
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 's1',
      'name': 'Sheet1',
      'visibledatarow': [0, 21, 42],
      'visibledatacolumn': [0, 88, 176],
      'ch_width': '2322',
      'rh_height': 949,
    });

    expect(sheet.visibleDataRows, [0, 21, 42]);
    expect(sheet.hasRawVisibleDataRows, isTrue);
    expect(sheet.visibleDataColumns, [0, 88, 176]);
    expect(sheet.hasRawVisibleDataColumns, isTrue);
    expect(sheet.sheetWidth, 2322);
    expect(sheet.rawSheetWidth, '2322');
    expect(sheet.hasRawSheetWidth, isTrue);
    expect(sheet.sheetHeight, 949);
    expect(sheet.rawSheetHeight, 949);
    expect(sheet.hasRawSheetHeight, isTrue);
    expect(sheet.extraFields.containsKey('visibledatarow'), isFalse);
    expect(sheet.extraFields.containsKey('visibledatacolumn'), isFalse);
    expect(sheet.extraFields.containsKey('ch_width'), isFalse);
    expect(sheet.extraFields.containsKey('rh_height'), isFalse);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    expect(json['visibledatarow'], [0, 21, 42]);
    expect(json['visibledatacolumn'], [0, 88, 176]);
    expect(json['ch_width'], '2322');
    expect(json['rh_height'], 949);
  });

  test('workbookFromJson chooses active sheet by status', () {
    final source = <String, Object?>{
      'customWorkbookMeta': {'owner': 'qa'},
      'data': [
        <String, Object?>{'id': 's1', 'name': 'A', 'status': 0},
        <String, Object?>{'id': 's2', 'name': 'B', 'status': 1},
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sourceData = source['data']! as List;
    (sourceData[0] as Map)['status'] = 1;
    (sourceData[1] as Map)['status'] = 0;

    expect(workbook.sheets, hasLength(2));
    expect(workbook.activeSheet.id, 's2');
    expect(workbook.extraFields['customWorkbookMeta'], isA<Map>());

    final data = FortuneSheetCodec.workbookToJson(workbook)['data']! as List;
    expect((data[0] as Map)['status'], 0);
    expect((data[1] as Map)['status'], 1);
    (data[0] as Map)['status'] = 1;
    (data[1] as Map)['status'] = 0;
    final reexportedData =
        FortuneSheetCodec.workbookToJson(workbook)['data']! as List;
    expect((reexportedData[0] as Map)['status'], 0);
    expect((reexportedData[1] as Map)['status'], 1);
  });

  test(
    'workbookFromJson skips hidden active sheet and falls back by order',
    () {
      final hiddenActive = FortuneSheetCodec.workbookFromJson({
        'data': [
          {'id': 's1', 'name': 'Hidden', 'status': 1, 'hide': 1, 'order': 0},
          {'id': 's2', 'name': 'Visible', 'status': 0, 'hide': 0, 'order': 1},
        ],
      });
      final orderFallback = FortuneSheetCodec.workbookFromJson({
        'data': [
          {'id': 's1', 'name': 'Later', 'status': 0, 'hide': 0, 'order': 2},
          {'id': 's2', 'name': 'Hidden', 'status': 0, 'hide': 1, 'order': 0},
          {'id': 's3', 'name': 'Earlier', 'status': 0, 'hide': 0, 'order': 1},
        ],
      });

      expect(hiddenActive.activeSheet.id, 's2');
      expect(orderFallback.activeSheet.id, 's3');

      final hiddenActiveData =
          FortuneSheetCodec.workbookToJson(hiddenActive)['data']! as List;
      expect((hiddenActiveData[0] as Map)['status'], 0);
      expect((hiddenActiveData[1] as Map)['status'], 1);
      final orderFallbackData =
          FortuneSheetCodec.workbookToJson(orderFallback)['data']! as List;
      expect((orderFallbackData[0] as Map)['status'], 0);
      expect((orderFallbackData[1] as Map)['status'], 0);
      expect((orderFallbackData[2] as Map)['status'], 1);
    },
  );

  test('workbookFromJson snapshots top-level extra fields', () {
    final source = {
      'customWorkbookMeta': {
        'owner': 'qa',
        'events': [
          {'type': 'open'},
        ],
      },
      'data': [
        {'id': 's1', 'name': 'A'},
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final sourceMeta = source['customWorkbookMeta']! as Map;
    sourceMeta['owner'] = 'mutated';
    (sourceMeta['events']! as List).add({'type': 'close'});

    expect(workbook.extraFields['customWorkbookMeta'], {
      'owner': 'qa',
      'events': [
        {'type': 'open'},
      ],
    });

    final json = FortuneSheetCodec.workbookToJson(workbook);
    final exportedMeta = json['customWorkbookMeta']! as Map;
    exportedMeta['owner'] = 'export-mutated';
    (exportedMeta['events']! as List).single['type'] = 'edited';

    final reexported = FortuneSheetCodec.workbookToJson(workbook);
    expect(reexported['customWorkbookMeta'], {
      'owner': 'qa',
      'events': [
        {'type': 'open'},
      ],
    });
  });

  test('workbookFromJson reads upstream top-level settings', () {
    final source = <String, Object?>{
      'column': '12',
      'row': 34.7,
      'addRows': '25',
      'showToolbar': false,
      'showFormulaBar': 'false',
      'showSheetTabs': 0,
      'devicePixelRatio': '2',
      'allowEdit': 'true',
      'lang': 'ko',
      'currency': r'$',
      'forceCalculation': 1,
      'config': {
        'merge': {
          '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 1},
        },
      },
      'rowHeaderWidth': '52',
      'columnHeaderHeight': 24,
      'defaultColWidth': '88.5',
      'defaultRowHeight': 21,
      'defaultFontSize': '11',
      'toolbarItems': ['undo', 'redo'],
      'customToolbarItems': [
        {
          'key': 'export',
          'tooltip': 'Export',
          'children': {'type': 'button'},
          'iconName': 'download',
        },
      ],
      'cellContextMenu': ['copy', 'paste'],
      'headerContextMenu': ['hide-row'],
      'sheetTabContextMenu': ['rename'],
      'filterContextMenu': ['sort-asc'],
      'data': [
        {'id': 's1', 'name': 'A'},
      ],
    };
    final workbook = FortuneSheetCodec.workbookFromJson(
      source,
      settings: const FortuneSettings(
        toolbarHeight: 44,
        formulaBarHeight: 31,
        sheetBarHeight: 33,
        statisticBarHeight: 25,
      ),
    );
    source
      ..['column'] = '1'
      ..['row'] = 1
      ..['addRows'] = '1'
      ..['showToolbar'] = true
      ..['showFormulaBar'] = 'true'
      ..['showSheetTabs'] = 1
      ..['devicePixelRatio'] = '1'
      ..['allowEdit'] = 'false'
      ..['lang'] = 'en'
      ..['currency'] = '€'
      ..['forceCalculation'] = 0
      ..['config'] = <String, Object?>{}
      ..['rowHeaderWidth'] = '1'
      ..['columnHeaderHeight'] = 1
      ..['defaultColWidth'] = '1'
      ..['defaultRowHeight'] = 1
      ..['defaultFontSize'] = '1'
      ..['toolbarItems'] = ['mutated']
      ..['customToolbarItems'] = <Object?>[]
      ..['cellContextMenu'] = ['mutated']
      ..['headerContextMenu'] = ['mutated']
      ..['sheetTabContextMenu'] = ['mutated']
      ..['filterContextMenu'] = ['mutated'];
    (source['data']! as List).add({'id': 's2', 'name': 'B'});

    final settings = workbook.settings;
    expect(settings.column, 12);
    expect(settings.row, 34);
    expect(settings.addRows, 25);
    expect(settings.showToolbar, isFalse);
    expect(settings.showFormulaBar, isFalse);
    expect(settings.showSheetTabs, isFalse);
    expect(settings.devicePixelRatio, 2);
    expect(settings.allowEdit, isTrue);
    expect(settings.lang, 'ko');
    expect(settings.currency, r'$');
    expect(settings.forceCalculation, isTrue);
    expect(settings.config, {
      'merge': {
        '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 1},
      },
    });
    expect(settings.rowHeaderWidth, 52);
    expect(settings.columnHeaderHeight, 24);
    expect(settings.defaultColWidth, 88.5);
    expect(settings.defaultRowHeight, 21);
    expect(settings.defaultFontSize, 11);
    expect(settings.toolbarItems, ['undo', 'redo']);
    expect(settings.customToolbarItems.single.toJson(), {
      'key': 'export',
      'tooltip': 'Export',
      'children': {'type': 'button'},
      'iconName': 'download',
    });
    expect(settings.cellContextMenu, ['copy', 'paste']);
    expect(settings.headerContextMenu, ['hide-row']);
    expect(settings.sheetTabContextMenu, ['rename']);
    expect(settings.filterContextMenu, ['sort-asc']);
    expect(settings.toolbarHeight, 44);
    expect(settings.formulaBarHeight, 31);
    expect(settings.sheetBarHeight, 33);
    expect(settings.statisticBarHeight, 25);
    expect(workbook.extraFields['showToolbar'], isFalse);
    expect(workbook.sheets, hasLength(1));
    expect(workbook.activeSheet.id, 's1');

    final json = FortuneSheetCodec.workbookToJson(workbook);
    expect(json['column'], '12');
    expect(json['row'], 34.7);
    expect(json['addRows'], '25');
    expect(json['showToolbar'], isFalse);
    expect(json['showFormulaBar'], 'false');
    expect(json['showSheetTabs'], 0);
    expect(json['devicePixelRatio'], '2');
    expect(json['allowEdit'], 'true');
    expect(json['lang'], 'ko');
    expect(json['currency'], r'$');
    expect(json['forceCalculation'], 1);
    expect(json['config'], {
      'merge': {
        '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 1},
      },
    });
    expect(json['rowHeaderWidth'], '52');
    expect(json['columnHeaderHeight'], 24);
    expect(json['defaultColWidth'], '88.5');
    expect(json['defaultRowHeight'], 21);
    expect(json['defaultFontSize'], '11');
    expect(json['toolbarItems'], ['undo', 'redo']);
    expect(json['customToolbarItems'], [
      {
        'key': 'export',
        'tooltip': 'Export',
        'children': {'type': 'button'},
        'iconName': 'download',
      },
    ]);
    expect(json['cellContextMenu'], ['copy', 'paste']);
    expect(json['headerContextMenu'], ['hide-row']);
    expect(json['sheetTabContextMenu'], ['rename']);
    expect(json['filterContextMenu'], ['sort-asc']);
    final data = json['data']! as List;
    expect(data, hasLength(1));
    expect((data.single as Map)['id'], 's1');
    expect((data.single as Map)['name'], 'A');

    json
      ..['column'] = '1'
      ..['row'] = 1
      ..['addRows'] = '1'
      ..['showToolbar'] = true
      ..['showFormulaBar'] = 'true'
      ..['showSheetTabs'] = 1
      ..['devicePixelRatio'] = '1'
      ..['allowEdit'] = 'false'
      ..['lang'] = 'en'
      ..['currency'] = 'mutated'
      ..['forceCalculation'] = 0
      ..['config'] = <String, Object?>{}
      ..['rowHeaderWidth'] = '1'
      ..['columnHeaderHeight'] = 1
      ..['defaultColWidth'] = '1'
      ..['defaultRowHeight'] = 1
      ..['defaultFontSize'] = '1'
      ..['toolbarItems'] = ['mutated']
      ..['customToolbarItems'] = <Object?>[]
      ..['cellContextMenu'] = ['mutated']
      ..['headerContextMenu'] = ['mutated']
      ..['sheetTabContextMenu'] = ['mutated']
      ..['filterContextMenu'] = ['mutated'];
    (data.single as Map)
      ..['id'] = 'mutated'
      ..['name'] = 'mutated';
    final reexported = FortuneSheetCodec.workbookToJson(workbook);
    final reexportedData = reexported['data']! as List;
    expect(reexported['column'], '12');
    expect(reexported['row'], 34.7);
    expect(reexported['addRows'], '25');
    expect(reexported['showToolbar'], isFalse);
    expect(reexported['showFormulaBar'], 'false');
    expect(reexported['showSheetTabs'], 0);
    expect(reexported['devicePixelRatio'], '2');
    expect(reexported['allowEdit'], 'true');
    expect(reexported['lang'], 'ko');
    expect(reexported['currency'], r'$');
    expect(reexported['forceCalculation'], 1);
    expect(reexported['config'], {
      'merge': {
        '0_0': {'r': 0, 'c': 0, 'rs': 2, 'cs': 1},
      },
    });
    expect(reexported['rowHeaderWidth'], '52');
    expect(reexported['columnHeaderHeight'], 24);
    expect(reexported['defaultColWidth'], '88.5');
    expect(reexported['defaultRowHeight'], 21);
    expect(reexported['defaultFontSize'], '11');
    expect(reexported['toolbarItems'], ['undo', 'redo']);
    expect(reexported['customToolbarItems'], [
      {
        'key': 'export',
        'tooltip': 'Export',
        'children': {'type': 'button'},
        'iconName': 'download',
      },
    ]);
    expect(reexported['cellContextMenu'], ['copy', 'paste']);
    expect(reexported['headerContextMenu'], ['hide-row']);
    expect(reexported['sheetTabContextMenu'], ['rename']);
    expect(reexported['filterContextMenu'], ['sort-asc']);
    expect(reexportedData, hasLength(1));
    expect((reexportedData.single as Map)['id'], 's1');
    expect((reexportedData.single as Map)['name'], 'A');
  });

  test('workbookToJson writes changed upstream top-level settings', () {
    final workbook = FortuneWorkbook(
      settings: const FortuneSettings(
        column: 12,
        row: 34,
        addRows: 25,
        showToolbar: false,
        showFormulaBar: false,
        showSheetTabs: false,
        devicePixelRatio: 2,
        allowEdit: false,
        lang: 'ko',
        currency: '€',
        forceCalculation: true,
        rowHeaderWidth: 52,
        columnHeaderHeight: 24,
        defaultColWidth: 88.5,
        defaultRowHeight: 21,
        defaultFontSize: 11,
        fontFamilies: ['Times New Roman', 'Arial', 'Aptos'],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'A')],
    );

    final json = FortuneSheetCodec.workbookToJson(workbook);

    expect(json['column'], 12);
    expect(json['row'], 34);
    expect(json['addRows'], 25);
    expect(json['showToolbar'], isFalse);
    expect(json['showFormulaBar'], isFalse);
    expect(json['showSheetTabs'], isFalse);
    expect(json['devicePixelRatio'], 2);
    expect(json['allowEdit'], isFalse);
    expect(json['lang'], 'ko');
    expect(json['currency'], '€');
    expect(json['forceCalculation'], isTrue);
    expect(json['rowHeaderWidth'], 52);
    expect(json['columnHeaderHeight'], 24);
    expect(json['defaultColWidth'], 88.5);
    expect(json['defaultRowHeight'], 21);
    expect(json['defaultFontSize'], 11);
    expect(json['fontFamilies'], ['Times New Roman', 'Arial', 'Aptos']);

    json
      ..['column'] = 1
      ..['row'] = 1
      ..['addRows'] = 1
      ..['showToolbar'] = true
      ..['showFormulaBar'] = true
      ..['showSheetTabs'] = true
      ..['devicePixelRatio'] = 1
      ..['allowEdit'] = true
      ..['lang'] = 'en'
      ..['currency'] = r'$'
      ..['forceCalculation'] = false
      ..['rowHeaderWidth'] = 1
      ..['columnHeaderHeight'] = 1
      ..['defaultColWidth'] = 1
      ..['defaultRowHeight'] = 1
      ..['defaultFontSize'] = 1;
    final reexported = FortuneSheetCodec.workbookToJson(workbook);
    expect(reexported['column'], 12);
    expect(reexported['row'], 34);
    expect(reexported['addRows'], 25);
    expect(reexported['showToolbar'], isFalse);
    expect(reexported['showFormulaBar'], isFalse);
    expect(reexported['showSheetTabs'], isFalse);
    expect(reexported['devicePixelRatio'], 2);
    expect(reexported['allowEdit'], isFalse);
    expect(reexported['lang'], 'ko');
    expect(reexported['currency'], '€');
    expect(reexported['forceCalculation'], isTrue);
    expect(reexported['rowHeaderWidth'], 52);
    expect(reexported['columnHeaderHeight'], 24);
    expect(reexported['defaultColWidth'], 88.5);
    expect(reexported['defaultRowHeight'], 21);
    expect(reexported['defaultFontSize'], 11);
    expect(reexported['fontFamilies'], ['Times New Roman', 'Arial', 'Aptos']);
  });

  test('workbookToJson preserves unchanged raw top-level settings', () {
    final source = {
      'showToolbar': 'false',
      'defaultRowHeight': '21',
      'currency': '₩',
      'data': [
        {'id': 's1', 'name': 'A'},
      ],
    };

    final workbook = FortuneSheetCodec.workbookFromJson(source);
    source['showToolbar'] = true;
    source['defaultRowHeight'] = '99';
    source['currency'] = 'mutated';

    final unchanged = FortuneSheetCodec.workbookToJson(workbook);
    final changed = FortuneSheetCodec.workbookToJson(
      workbook.copyWith(
        settings: const FortuneSettings(
          showToolbar: true,
          currency: '€',
          defaultRowHeight: 22,
        ),
      ),
    );

    expect(unchanged['showToolbar'], 'false');
    expect(unchanged['currency'], '₩');
    expect(unchanged['defaultRowHeight'], '21');
    expect(changed['showToolbar'], isTrue);
    expect(changed['currency'], '€');
    expect(changed['defaultRowHeight'], 22);

    unchanged['showToolbar'] = true;
    unchanged['defaultRowHeight'] = '99';
    unchanged['currency'] = 'mutated';
    final reexported = FortuneSheetCodec.workbookToJson(workbook);
    expect(reexported['showToolbar'], 'false');
    expect(reexported['currency'], '₩');
    expect(reexported['defaultRowHeight'], '21');
  });

  test('workbookFromJson creates default sheet for missing data', () {
    final missingDataWorkbook = FortuneSheetCodec.workbookFromJson({});
    final malformedDataWorkbook = FortuneSheetCodec.workbookFromJson({
      'data': 'raw-only',
    });

    expect(missingDataWorkbook.sheets, hasLength(1));
    expect(missingDataWorkbook.activeSheet.id, 'sheet_01');
    expect(missingDataWorkbook.activeSheet.name, 'Sheet1');
    expect(missingDataWorkbook.hasRawData, isFalse);

    expect(malformedDataWorkbook.sheets, hasLength(1));
    expect(malformedDataWorkbook.activeSheet.id, 'sheet_01');
    expect(malformedDataWorkbook.activeSheet.name, 'Sheet1');
    expect(malformedDataWorkbook.rawData, 'raw-only');
    expect(malformedDataWorkbook.hasRawData, isTrue);
    final missingData =
        FortuneSheetCodec.workbookToJson(missingDataWorkbook)['data']! as List;
    expect(missingData, isA<List>());
    final malformedData =
        FortuneSheetCodec.workbookToJson(malformedDataWorkbook)['data']!
            as List;
    expect((malformedData.single as Map)['id'], 'sheet_01');
    expect((malformedData.single as Map)['status'], 1);

    (missingData.single as Map)['id'] = 'mutated';
    (malformedData.single as Map)
      ..['id'] = 'mutated'
      ..['status'] = 0;
    final reexportedMissingData =
        FortuneSheetCodec.workbookToJson(missingDataWorkbook)['data']! as List;
    final reexportedMalformedData =
        FortuneSheetCodec.workbookToJson(malformedDataWorkbook)['data']!
            as List;
    expect((reexportedMissingData.single as Map)['id'], 'sheet_01');
    expect((reexportedMissingData.single as Map)['status'], 1);
    expect((reexportedMalformedData.single as Map)['id'], 'sheet_01');
    expect((reexportedMalformedData.single as Map)['status'], 1);
  });

  test('workbook copyWith accepts numeric active sheet index strings', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'A'),
        FortuneSheet(id: 's2', name: 'B'),
      ],
    );

    final changed = workbook.copyWith(activeSheetIndex: '1');
    final clamped = workbook.copyWith(activeSheetIndex: '99');
    final invalid = changed.copyWith(activeSheetIndex: 'invalid');

    expect(workbook.activeSheet.id, 's1');
    expect(changed.activeSheet.id, 's2');
    expect(clamped.activeSheet.id, 's2');
    expect(invalid.activeSheet.id, 's2');
    expect(changed.copyWith(activeSheetIndex: null).activeSheet.id, 's2');

    final data = FortuneSheetCodec.workbookToJson(changed)['data']! as List;
    expect((data[0] as Map)['status'], 0);
    expect((data[1] as Map)['status'], 1);
    (data[0] as Map)['status'] = 1;
    (data[1] as Map)['status'] = 0;
    final reexportedData =
        FortuneSheetCodec.workbookToJson(changed)['data']! as List;
    expect((reexportedData[0] as Map)['status'], 0);
    expect((reexportedData[1] as Map)['status'], 1);
  });

  test('workbookToJson preserves raw-only workbook data entries', () {
    final workbook = FortuneSheetCodec.workbookFromJson({
      'customWorkbookMeta': {'owner': 'qa'},
      'data': [
        {'id': 's1', 'name': 'A', 'status': 0},
        'raw-only',
        {'id': 's2', 'name': 'B', 'status': 1},
        null,
      ],
    });
    final changed = workbook.copyWith(
      sheets: [
        ...workbook.sheets,
        FortuneSheet(id: 's3', name: 'C'),
      ],
      activeSheetIndex: 2,
    );
    final activeChanged = workbook.copyWith(activeSheetIndex: 0);

    final data = FortuneSheetCodec.workbookToJson(workbook)['data']! as List;
    final activeChangedData =
        FortuneSheetCodec.workbookToJson(activeChanged)['data']! as List;
    final changedData =
        FortuneSheetCodec.workbookToJson(changed)['data']! as List;

    expect(data[0], isA<Map>());
    expect(data[1], 'raw-only');
    expect(data[2], isA<Map>());
    expect(data[3], isNull);
    expect((data[0] as Map)['id'], 's1');
    expect((data[0] as Map)['status'], 0);
    expect((data[2] as Map)['id'], 's2');
    expect((data[2] as Map)['status'], 1);
    expect(activeChangedData[1], 'raw-only');
    expect(activeChangedData[3], isNull);
    expect((activeChangedData[0] as Map)['status'], 1);
    expect((activeChangedData[2] as Map)['status'], 0);
    expect(changedData, hasLength(3));
    expect(changedData.any((item) => item == 'raw-only'), isFalse);
    expect((changedData[2] as Map)['id'], 's3');
    expect((changedData[2] as Map)['status'], 1);

    (data[0] as Map)['id'] = 'mutated';
    data[1] = 'export-mutated';
    (data[2] as Map)['status'] = 0;
    data[3] = {'raw': true};
    final reexportedData =
        FortuneSheetCodec.workbookToJson(workbook)['data']! as List;
    expect((reexportedData[0] as Map)['id'], 's1');
    expect((reexportedData[0] as Map)['status'], 0);
    expect(reexportedData[1], 'raw-only');
    expect((reexportedData[2] as Map)['id'], 's2');
    expect((reexportedData[2] as Map)['status'], 1);
    expect(reexportedData[3], isNull);
  });

  test('workbookFromJson snapshots raw-only workbook data entries', () {
    final source = {
      'data': [
        {'id': 's1', 'name': 'A', 'status': 0},
        [
          {
            'kind': 'raw-only',
            'items': ['original'],
          },
        ],
        {'id': 's2', 'name': 'B', 'status': 1},
      ],
    };
    final workbook = FortuneSheetCodec.workbookFromJson(source);
    final rawOnlyEntry = (source['data']! as List)[1] as List;
    (rawOnlyEntry.single as Map)['items'] = ['mutated'];
    rawOnlyEntry.add({'extra': true});

    final data = FortuneSheetCodec.workbookToJson(workbook)['data']! as List;

    expect(data[1], [
      {
        'kind': 'raw-only',
        'items': ['original'],
      },
    ]);

    (((data[1] as List).single as Map)['items']! as List).add('exported');
    (data[1] as List).add({'extra': true});
    final reexported =
        FortuneSheetCodec.workbookToJson(workbook)['data']! as List;

    expect(reexported[1], [
      {
        'kind': 'raw-only',
        'items': ['original'],
      },
    ]);
  });

  test('workbookToJson writes data array and active sheet status', () {
    final workbook = FortuneWorkbook(
      activeSheetIndex: 1,
      extraFields: {
        'customWorkbookMeta': {'owner': 'qa'},
        'data': 'extra must not override mapped data',
      },
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'A',
          status: 1,
          cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
        ),
        FortuneSheet(
          id: 's2',
          name: 'B',
          status: 0,
          cells: {const FortuneCellCoord(0, 1): const FortuneCell(value: 'B1')},
        ),
      ],
    );

    final json = FortuneSheetCodec.workbookToJson(workbook);
    final data = json['data']! as List;

    expect(json['customWorkbookMeta'], {'owner': 'qa'});
    expect(data, hasLength(2));
    expect((data[0] as Map)['id'], 's1');
    expect((data[0] as Map)['status'], 0);
    expect((data[1] as Map)['id'], 's2');
    expect((data[1] as Map)['status'], 1);
    expect(((data[0] as Map)['celldata']! as List).single, {
      'r': 0,
      'c': 0,
      'v': {'v': 'A1'},
    });
    expect(((data[1] as Map)['celldata']! as List).single, {
      'r': 0,
      'c': 1,
      'v': {'v': 'B1'},
    });

    (json['customWorkbookMeta']! as Map)['owner'] = 'mutated';
    (data[0] as Map)['status'] = 1;
    ((((data[0] as Map)['celldata']! as List).single as Map)['v']!
            as Map)['v'] =
        'mutated';
    (data[1] as Map)['status'] = 0;
    ((((data[1] as Map)['celldata']! as List).single as Map)['v']!
            as Map)['v'] =
        'mutated';
    final reexported = FortuneSheetCodec.workbookToJson(workbook);
    final reexportedData = reexported['data']! as List;
    expect(reexported['customWorkbookMeta'], {'owner': 'qa'});
    expect((reexportedData[0] as Map)['status'], 0);
    expect(((reexportedData[0] as Map)['celldata']! as List).single, {
      'r': 0,
      'c': 0,
      'v': {'v': 'A1'},
    });
    expect((reexportedData[1] as Map)['status'], 1);
    expect(((reexportedData[1] as Map)['celldata']! as List).single, {
      'r': 0,
      'c': 1,
      'v': {'v': 'B1'},
    });

    final roundTripped = FortuneSheetCodec.workbookFromJson(reexported);
    expect(roundTripped.activeSheet.id, 's2');
  });
}
