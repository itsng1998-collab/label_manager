import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

(double, double) _parseComplexResult(String value) {
  final match = RegExp(
    r'^([+-]?(?:\d+(?:\.\d+)?|\.\d+))(?:([+-])((?:\d+(?:\.\d+)?|\.\d+)))i$',
  ).firstMatch(value);
  if (match == null) {
    throw FormatException('Invalid complex result', value);
  }
  final imaginary = double.parse(match.group(3)!);
  return (
    double.parse(match.group(1)!),
    match.group(2) == '-' ? -imaginary : imaginary,
  );
}

void main() {
  group('upstream formula parser replay parity', () {
    test('exports and normalizes parser error helpers', () {
      expect(ERROR, 'ERROR');
      expect(ERROR_DIV_ZERO, 'DIV/0');
      expect(ERROR_NAME, 'NAME');
      expect(ERROR_NOT_AVAILABLE, 'N/A');
      expect(ERROR_NULL, 'NULL');
      expect(ERROR_NUM, 'NUM');
      expect(ERROR_REF, 'REF');
      expect(ERROR_VALUE, 'VALUE');
      expect(SUPPORTED_FORMULAS, isA<List<String>>());

      expect(formulaParserError(null), isNull);
      expect(formulaParserError(''), isNull);
      expect(formulaParserError('dewdewdw'), isNull);
      expect(formulaParserError('ERROR1'), isNull);
      expect(formulaParserError(' ERROR!'), isNull);
      expect(formulaParserError(' #ERROR!'), isNull);

      expect(formulaParserError('ERROR'), '#ERROR!');
      expect(formulaParserError('ERROR!'), '#ERROR!');
      expect(formulaParserError('#ERROR'), '#ERROR!');
      expect(formulaParserError('#ERROR!'), '#ERROR!');
      expect(formulaParserError('#ERROR?'), '#ERROR!');
      expect(formulaParserError('DIV/0'), '#DIV/0!');
      expect(formulaParserError('DIV/0!'), '#DIV/0!');
      expect(formulaParserError('#DIV/0'), '#DIV/0!');
      expect(formulaParserError('#DIV/0!'), '#DIV/0!');
      expect(formulaParserError('#DIV/0?'), '#DIV/0!');
      expect(formulaParserError('NAME'), '#NAME?');
      expect(formulaParserError('NAME!'), '#NAME?');
      expect(formulaParserError('#NAME'), '#NAME?');
      expect(formulaParserError('#NAME!'), '#NAME?');
      expect(formulaParserError('#NAME?'), '#NAME?');
      expect(formulaParserError('N/A'), '#N/A');
      expect(formulaParserError('N/A!'), '#N/A');
      expect(formulaParserError('#N/A'), '#N/A');
      expect(formulaParserError('#N/A!'), '#N/A');
      expect(formulaParserError('#N/A?'), '#N/A');
      expect(formulaParserError('NULL'), '#NULL!');
      expect(formulaParserError('NULL!'), '#NULL!');
      expect(formulaParserError('#NULL'), '#NULL!');
      expect(formulaParserError('#NULL!'), '#NULL!');
      expect(formulaParserError('#NULL?'), '#NULL!');
      expect(formulaParserError('NUM'), '#NUM!');
      expect(formulaParserError('NUM!'), '#NUM!');
      expect(formulaParserError('#NUM'), '#NUM!');
      expect(formulaParserError('#NUM!'), '#NUM!');
      expect(formulaParserError('#NUM?'), '#NUM!');
      expect(formulaParserError('REF'), '#REF!');
      expect(formulaParserError('REF!'), '#REF!');
      expect(formulaParserError('#REF'), '#REF!');
      expect(formulaParserError('#REF!'), '#REF!');
      expect(formulaParserError('#REF?'), '#REF!');
      expect(formulaParserError('VALUE'), '#VALUE!');
      expect(formulaParserError('VALUE!'), '#VALUE!');
      expect(formulaParserError('#VALUE'), '#VALUE!');
      expect(formulaParserError('#VALUE!'), '#VALUE!');
      expect(formulaParserError('#VALUE?'), '#VALUE!');

      expect(isValidStrict(null), isFalse);
      expect(isValidStrict(''), isFalse);
      expect(isValidStrict('dewdewdw'), isFalse);
      expect(isValidStrict('ERROR'), isFalse);
      expect(isValidStrict('ERROR!'), isFalse);
      expect(isValidStrict('#ERROR'), isFalse);
      expect(isValidStrict('#ERROR?'), isFalse);
      expect(isValidStrict('DIV/0'), isFalse);
      expect(isValidStrict('DIV/0!'), isFalse);
      expect(isValidStrict('#DIV/0'), isFalse);
      expect(isValidStrict('#DIV/0?'), isFalse);
      expect(isValidStrict('NAME'), isFalse);
      expect(isValidStrict('NAME!'), isFalse);
      expect(isValidStrict('#NAME'), isFalse);
      expect(isValidStrict('#NAME!'), isFalse);
      expect(isValidStrict('N/A'), isFalse);
      expect(isValidStrict('N/A!'), isFalse);
      expect(isValidStrict('#N/A!'), isFalse);
      expect(isValidStrict('#N/A?'), isFalse);
      expect(isValidStrict('NULL'), isFalse);
      expect(isValidStrict('NULL!'), isFalse);
      expect(isValidStrict('#NULL'), isFalse);
      expect(isValidStrict('#NULL?'), isFalse);
      expect(isValidStrict('NUM'), isFalse);
      expect(isValidStrict('NUM!'), isFalse);
      expect(isValidStrict('#NUM'), isFalse);
      expect(isValidStrict('#NUM?'), isFalse);
      expect(isValidStrict('REF'), isFalse);
      expect(isValidStrict('REF!'), isFalse);
      expect(isValidStrict('#REF'), isFalse);
      expect(isValidStrict('#REF?'), isFalse);
      expect(isValidStrict('VALUE'), isFalse);
      expect(isValidStrict('VALUE!'), isFalse);
      expect(isValidStrict('#VALUE'), isFalse);
      expect(isValidStrict('#VALUE?'), isFalse);
      expect(isValidStrict('#ERROR!'), isTrue);
      expect(isValidStrict('#DIV/0!'), isTrue);
      expect(isValidStrict('#NAME?'), isTrue);
      expect(isValidStrict('#N/A'), isTrue);
      expect(isValidStrict('#NULL!'), isTrue);
      expect(isValidStrict('#NUM!'), isTrue);
      expect(isValidStrict('#REF!'), isTrue);
      expect(isValidStrict('#VALUE!'), isTrue);
    });

    test('evaluates parser default and named variables', () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        extraFields: {
          'formulaVariables': {'foo': 'bar', 'baz': '6.6'},
        },
      );

      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=TRUE'), true);
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=FALSE'), false);
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=NULL+5'), 5);
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=foo'), 'bar');
      expect(
        FortuneFormulaEngine.evaluateFormula(sheet, '=SUM(baz, 2.1, 0.2)'),
        closeTo(8.899999999999999, 1e-12),
      );
    });

    test('exposes upstream Parser-style parse API', () {
      final parser = Parser()
        ..setVariable('foo', 'bar')
        ..setVariable('baz', '6.6')
        ..setFunction('ADD_5', (params) => (params.single as num) + 5)
        ..setFunction('GET_LETTER', (params) {
          final string = params[0] as String;
          final index = (params[1] as num).toInt() - 1;
          return string[index];
        })
        ..setFunction('RETURN_ERROR_LITERAL', (_) => StateError(ERROR))
        ..setFunction(
          'RETURN_DIV_ZERO_ERROR',
          (_) => StateError(ERROR_DIV_ZERO),
        )
        ..setFunction('RETURN_NAME_ERROR', (_) => StateError(ERROR_NAME))
        ..setFunction(
          'RETURN_NOT_AVAILABLE_ERROR',
          (_) => StateError(ERROR_NOT_AVAILABLE),
        )
        ..setFunction('RETURN_NULL_ERROR', (_) => StateError(ERROR_NULL))
        ..setFunction('RETURN_NUM_ERROR', (_) => StateError(ERROR_NUM))
        ..setFunction('RETURN_REF_ERROR', (_) => StateError(ERROR_REF))
        ..setFunction('RETURN_ERROR', (_) => StateError(ERROR_VALUE))
        ..setFunction('RETURN_UNKNOWN_ERROR', (_) => StateError('some error'));

      expect(parser.getVariable('TRUE'), isTrue);
      expect(parser.getVariable('FALSE'), isFalse);
      expect(parser.getVariable('NULL'), isNull);
      expect(parser.getVariable('missing'), isNull);
      expect(parser.getVariable('foo'), 'bar');
      parser
        ..setVariable('unit_foo', 1234)
        ..setVariable('unit_bar', '1234')
        ..setVariable('unit_baz', [1, 2]);
      expect(parser.getVariable('unit_foo'), 1234);
      expect(parser.getVariable('unit_bar'), '1234');
      expect(parser.getVariable('unit_baz'), [1, 2]);
      expect(parser.getFunction('add_5'), isNotNull);
      expect(parser.getFunction('add_5')!([1]), 6);
      expect(parser.parse(''), {'error': null, 'result': ''});
      expect(parser.parse(200), {'error': '#ERROR!', 'result': null});
      expect(parser.parse(20.1), {'error': '#ERROR!', 'result': null});
      expect(parser.parse(null), {'error': '#ERROR!', 'result': null});
      expect(parser.parse({}), {'error': '#ERROR!', 'result': null});
      expect(parser.parse({'a': 1}), {'error': '#ERROR!', 'result': null});
      expect(parser.parse([]), {'error': '#ERROR!', 'result': null});
      expect(parser.parse([1, 2]), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('TRUE'), {'error': null, 'result': true});
      expect(parser.parse('"ERROR"'), {'error': null, 'result': 'ERROR'});
      expect(parser.parse('"#ERROR!"'), {'error': null, 'result': '#ERROR!'});
      expect(parser.parse('foo'), {'error': null, 'result': 'bar'});
      expect(
        parser.parse('SUM(baz, 2.1, 0.2)')['result'],
        closeTo(8.899999999999999, 1e-12),
      );
      expect(parser.parse('foo()'), {'error': '#NAME?', 'result': null});
      expect(parser.parse('ACOTH("foo")'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(parser.parse("ACOTH('foo')"), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(Parser().parse('ACOTH(foo)'), {'error': '#NAME?', 'result': null});
      expect(parser.parse('SUM(4, ADD_5(1))'), {'error': null, 'result': 10});
      expect(parser.parse('GET_LETTER("Some string", 3)'), {
        'error': null,
        'result': 'm',
      });
      expect(parser.parse('SUM([])'), {'error': null, 'result': 0});
      expect(parser.parse('SUM([1])'), {'error': null, 'result': 1});
      expect(parser.parse('SUM([1,2,3])'), {'error': null, 'result': 6});
      parser.setVariable('foo', [7, 3.5, 3.5, 1, 2]);
      expect(parser.parse('sum(2, 3, Rank.eq(2, foo))'), {
        'error': null,
        'result': 9,
      });
      expect(parser.parse('UNKNOWN_NAME'), {'error': '#NAME?', 'result': null});
      expect(parser.parse('RETURN_ERROR_LITERAL()'), {
        'error': '#ERROR!',
        'result': null,
      });
      expect(parser.parse('RETURN_DIV_ZERO_ERROR()'), {
        'error': '#DIV/0!',
        'result': null,
      });
      expect(parser.parse('RETURN_NAME_ERROR()'), {
        'error': '#NAME?',
        'result': null,
      });
      expect(parser.parse('RETURN_NOT_AVAILABLE_ERROR()'), {
        'error': '#N/A',
        'result': null,
      });
      expect(parser.parse('RETURN_NULL_ERROR()'), {
        'error': '#NULL!',
        'result': null,
      });
      expect(parser.parse('RETURN_NUM_ERROR()'), {
        'error': '#NUM!',
        'result': null,
      });
      expect(parser.parse('RETURN_REF_ERROR()'), {
        'error': '#REF!',
        'result': null,
      });
      expect(parser.parse('RETURN_ERROR()'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(parser.parse('RETURN_UNKNOWN_ERROR()'), {
        'error': '#ERROR!',
        'result': null,
      });
    });

    test('parses upstream Parser error literals strictly', () {
      final parser = Parser();

      expect(parser.parse('#ERROR!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#ERRfefweOR!'), {
        'error': '#ERROR!',
        'result': null,
      });
      expect(parser.parse(' #ERRfefweOR! '), {
        'error': '#ERROR!',
        'result': null,
      });
      expect(parser.parse('#DIV/0!'), {'error': '#DIV/0!', 'result': null});
      expect(parser.parse('#DIV/0?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#DIV/1!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#DIV/'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NAME?'), {'error': '#NAME?', 'result': null});
      expect(parser.parse('#NAME!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NAMe!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#N/A'), {'error': '#N/A', 'result': null});
      expect(parser.parse('#N/A!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#N/A?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NA'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NULL!'), {'error': '#NULL!', 'result': null});
      expect(parser.parse('#NULL?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NULl!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NUM!'), {'error': '#NUM!', 'result': null});
      expect(parser.parse('#NUM?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#NuM!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#REF!'), {'error': '#REF!', 'result': null});
      expect(parser.parse('#REF?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#REf!'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#VALUE!'), {'error': '#VALUE!', 'result': null});
      expect(parser.parse('#VALUE?'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('#VALUe!'), {'error': '#ERROR!', 'result': null});
    });

    test('parses upstream Parser cell event value fixtures', () {
      final parser = Parser()
        ..on('callCellValue', (
          Map<String, Object?> cell,
          ParserEventDone done,
        ) {
          final row = cell['row'] as Map<String, Object?>;
          final column = cell['column'] as Map<String, Object?>;
          if (row['index'] == 0 && column['index'] == 2) {
            done('4');
          } else if (row['index'] == 0 && column['index'] == 7) {
            done(45);
          } else if (row['index'] == 2 && column['index'] == 7) {
            done([1, 2, 3]);
          } else if (row['index'] == 3 &&
              column['index'] == 7 &&
              column['isAbsolute'] == true) {
            done(true);
          } else if (row['index'] == 4 &&
              row['isAbsolute'] == true &&
              column['index'] == 7 &&
              column['isAbsolute'] == true) {
            done(0.9);
          }
        });

      expect(parser.parse('A1'), {'error': null, 'result': null});
      expect(parser.parse('C1'), {'error': null, 'result': '4'});
      expect(parser.parse('H1'), {'error': null, 'result': 45});
      expect(parser.parse('H3'), {
        'error': null,
        'result': [1, 2, 3],
      });
      expect(parser.parse(r'$H4'), {'error': null, 'result': true});
      expect(parser.parse(r'$H$5'), {'error': null, 'result': 0.9});
    });

    test('parses upstream Parser range event value fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> firstCell,
          Map<String, Object?> lastCell,
          ParserEventDone done,
        ) {
          final row1 = firstCell['row'] as Map<String, Object?>;
          final column1 = firstCell['column'] as Map<String, Object?>;
          final row2 = lastCell['row'] as Map<String, Object?>;
          final column2 = lastCell['column'] as Map<String, Object?>;
          if (row1['index'] == 0 &&
              column1['index'] == 2 &&
              row2['index'] == 3 &&
              column2['index'] == 3) {
            done([
              [1, 2],
              [4, 5],
            ]);
          } else if (row1['index'] == 0 &&
              row1['isAbsolute'] == true &&
              column1['index'] == 0 &&
              row2['index'] == 3 &&
              column2['index'] == 3 &&
              column2['isAbsolute'] == true) {
            done([
              ['a', 'b'],
              ['z', 'd'],
            ]);
          } else if (row1['index'] == 0 &&
              row1['isAbsolute'] == true &&
              column1['index'] == 0 &&
              column1['isAbsolute'] == true &&
              row2['index'] == 4 &&
              row2['isAbsolute'] == true &&
              column2['index'] == 4 &&
              column2['isAbsolute'] == true) {
            done([
              [true, false],
              [true, true],
            ]);
          }
        });

      expect(parser.parse('A1:B2'), {'error': null, 'result': []});
      expect(parser.parse('C1:D4'), {
        'error': null,
        'result': [
          [1, 2],
          [4, 5],
        ],
      });
      expect(parser.parse(r'A$1:$D4'), {
        'error': null,
        'result': [
          ['a', 'b'],
          ['z', 'd'],
        ],
      });
      expect(parser.parse(r'$A$1:$E$5'), {
        'error': null,
        'result': [
          [true, false],
          [true, true],
        ],
      });
    });

    test('parses upstream Parser coordinate callback payloads', () {
      Map<String, Object?>? cellCoord;
      Map<String, Object?>? startCellCoord;
      Map<String, Object?>? endCellCoord;
      final parser = Parser()
        ..on('callCellValue', (
          Map<String, Object?> cell,
          ParserEventDone done,
        ) {
          cellCoord = Map<String, Object?>.from(cell);
          done(55);
        })
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          startCellCoord = Map<String, Object?>.from(start);
          endCellCoord = Map<String, Object?>.from(end);
          done([
            [3, 6, 10],
          ]);
        });

      expect(parser.parse('a1'), {'error': null, 'result': 55});
      expect(cellCoord, {
        'label': 'A1',
        'row': {'index': 0, 'isAbsolute': false, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
      });

      expect(parser.parse(r'$a$1'), {'error': null, 'result': 55});
      expect(cellCoord, {
        'label': r'$A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      for (final expression in [
        r'$A$$$$1',
        r'$$A$1',
        r'A$$1',
        r'$$A1',
        r'A1$',
        r'A1$$$',
        r'a1$$$',
      ]) {
        expect(parser.parse(expression), {
          'error': '#ERROR!',
          'result': null,
        }, reason: expression);
      }

      expect(parser.parse(r'$a$1:$b$2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'$A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'$B$2',
        'row': {'index': 1, 'isAbsolute': true, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': true, 'label': 'B'},
      });
      expect(parser.parse(r'$a$1:$B$2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'$A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'$B$2',
        'row': {'index': 1, 'isAbsolute': true, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': true, 'label': 'B'},
      });
      expect(parser.parse(r'$A$1:b2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'$A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': 'B2',
        'row': {'index': 1, 'isAbsolute': false, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': false, 'label': 'B'},
      });

      expect(parser.parse(r'$A$1:B$2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'$A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'B$2',
        'row': {'index': 1, 'isAbsolute': true, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': false, 'label': 'B'},
      });

      expect(parser.parse(r'A1:$B2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'A1',
        'row': {'index': 0, 'isAbsolute': false, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'$B2',
        'row': {'index': 1, 'isAbsolute': false, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': true, 'label': 'B'},
      });

      expect(parser.parse(r'A$1:$B$2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'$B$2',
        'row': {'index': 1, 'isAbsolute': true, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': true, 'label': 'B'},
      });

      expect(parser.parse(r'a$1:$b2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'A$1',
        'row': {'index': 0, 'isAbsolute': true, 'label': '1'},
        'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'$B2',
        'row': {'index': 1, 'isAbsolute': false, 'label': '2'},
        'column': {'index': 1, 'isAbsolute': true, 'label': 'B'},
      });

      for (final expression in ['A1:B2', 'a1:B2', 'A1:b2', 'a1:b2']) {
        expect(parser.parse(expression), {
          'error': null,
          'result': [
            [3, 6, 10],
          ],
        }, reason: expression);
        expect(startCellCoord, {
          'label': 'A1',
          'row': {'index': 0, 'isAbsolute': false, 'label': '1'},
          'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
        }, reason: expression);
        expect(endCellCoord, {
          'label': 'B2',
          'row': {'index': 1, 'isAbsolute': false, 'label': '2'},
          'column': {'index': 1, 'isAbsolute': false, 'label': 'B'},
        }, reason: expression);
      }

      expect(parser.parse(r'$A$9:B2'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'$A2',
        'row': {'index': 1, 'isAbsolute': false, 'label': '2'},
        'column': {'index': 0, 'isAbsolute': true, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'B$9',
        'row': {'index': 8, 'isAbsolute': true, 'label': '9'},
        'column': {'index': 1, 'isAbsolute': false, 'label': 'B'},
      });

      expect(parser.parse(r'B$2:A$8'), {
        'error': null,
        'result': [
          [3, 6, 10],
        ],
      });
      expect(startCellCoord, {
        'label': r'A$2',
        'row': {'index': 1, 'isAbsolute': true, 'label': '2'},
        'column': {'index': 0, 'isAbsolute': false, 'label': 'A'},
      });
      expect(endCellCoord, {
        'label': r'B$8',
        'row': {'index': 7, 'isAbsolute': true, 'label': '8'},
        'column': {'index': 1, 'isAbsolute': false, 'label': 'B'},
      });
      for (final expression in [
        r'$A$$1:$B$2',
        r'$A$1:$B$$2',
        r'$A$1:$$B$2',
        r'$$A$1:$B$2',
        r'A1:$$B2',
        r'A1:B2$',
        r'a1:b2$',
        r'A1$:B2',
      ]) {
        expect(parser.parse(expression), {
          'error': '#ERROR!',
          'result': null,
        }, reason: expression);
      }
    });

    test('parses upstream Parser math and logical operators', () {
      final parser = Parser();

      final mathCases = <String, Map<String, Object?>>{
        '10+10': {'error': null, 'result': 20},
        '10 + 10': {'error': null, 'result': 20},
        '10 + 11 + 23 + 11 + 2': {'error': null, 'result': 57},
        '1.4425 + 4.333': {'error': null, 'result': 5.7755},
        '"foo" + 4.333': {'error': '#VALUE!', 'result': null},
        '1 + "foo"': {'error': '#VALUE!', 'result': null},
        '(1 + "foo")': {'error': '#VALUE!', 'result': null},
        '10-10': {'error': null, 'result': 0},
        '10 - 10': {'error': null, 'result': 0},
        '10 - 10 - 2': {'error': null, 'result': -2},
        '10 - 11 - 23 - 11 - 2': {'error': null, 'result': -37},
        '"foo" - 4.333': {'error': '#VALUE!', 'result': null},
        '2 / 1': {'error': null, 'result': 2},
        '64 / 2 / 4': {'error': null, 'result': 8},
        '2 / 0': {'error': '#DIV/0!', 'result': null},
        '"foo" / 4.333': {'error': '#VALUE!', 'result': null},
        '0 * 0 * 0 * 0 * 0': {'error': null, 'result': 0},
        '2 * 1': {'error': null, 'result': 2},
        '64 * 2 * 4': {'error': null, 'result': 512},
        '"foo" * 4.333': {'error': '#VALUE!', 'result': null},
        '2 ^ 5': {'error': null, 'result': 32},
        '"foo" ^ 4': {'error': '#VALUE!', 'result': null},
        '2 & 5': {'error': null, 'result': '25'},
        '(2 & 5)': {'error': null, 'result': '25'},
        '("" & "")': {'error': null, 'result': ''},
        '"" & ""': {'error': null, 'result': ''},
        '("Hello" & " world") & "!"': {'error': null, 'result': 'Hello world!'},
        '1 + 10 - 20 * 3/2': {'error': null, 'result': -19},
        '((1 + 10 - 20 * 3 / 2) + 20) * 10': {'error': null, 'result': 10},
        '(((1 + 10 - 20 * 3/2) + 20) * 10) / 5.12': {
          'error': null,
          'result': 1.953125,
        },
        '(((1 + "foo" - 20 * 3/2) + 20) * 10) / 5.12': {
          'error': '#VALUE!',
          'result': null,
        },
      };
      for (final entry in mathCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      final logicalCases = <String, bool>{
        '10 = 10': true,
        '10 = 11': false,
        '11 > 10': true,
        '10 > 1.1': true,
        '10 >- 10': true,
        '10 > 11': false,
        '10 > 11.1': false,
        '10 > 10.00001': false,
        '10 < 11': true,
        '10 < 11.1': true,
        '10 < 10.00001': true,
        '11 < 10': false,
        '10 < 1.1': false,
        '10 <- 10': false,
        '11 >= 10': true,
        '11 >= 11': true,
        '10 >= 10': true,
        '10 >= -10': true,
        '10 >= 11': false,
        '10 >= 11.1': false,
        '10 >= 10.00001': false,
        '10 <= 10': true,
        '1.1 <= 10': true,
        '-10 <= 10': true,
        '11 <= 10': false,
        '11.1 <= 10': false,
        '10.00001 <= 10': false,
        '10 <> 11': true,
        '1.1 <> 10': true,
        '-10 <> 10': true,
        '10 <> 10': false,
        '11.1 <> 11.1': false,
        '10.00001 <> 10.00001': false,
      };
      for (final entry in logicalCases.entries) {
        expect(parser.parse(entry.key), {'error': null, 'result': entry.value});
      }
    });

    test('parses upstream math trig basic scalar fixtures', () {
      final parser = Parser();
      final aggregateParser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          done([
            [1, 2, 3],
          ]);
        });
      final exactCases = <String, Map<String, Object?>>{
        'ABS()': {'error': '#VALUE!', 'result': null},
        'ABS(-8)': {'error': null, 'result': 8},
        'ABS(-8.89)': {'error': null, 'result': 8.89},
        'ABS(8)': {'error': null, 'result': 8},
        'ACOS()': {'error': '#VALUE!', 'result': null},
        'ACOS(1)': {'error': null, 'result': 0},
        'ACOS(-1)': {'error': null, 'result': math.pi},
        'ACOSH()': {'error': '#VALUE!', 'result': null},
        'ACOSH(1)': {'error': null, 'result': 0},
        'ACOSH(-1)': {'error': '#NUM!', 'result': null},
        'ACOTH()': {'error': '#VALUE!', 'result': null},
        'ACOTH(1)': {'error': null, 'result': double.infinity},
        'ACOTH(-1)': {'error': null, 'result': double.negativeInfinity},
        'ADD()': {'error': '#N/A', 'result': null},
        'ADD(3)': {'error': '#N/A', 'result': null},
        'ADD(3, 5, 6, 7, 1)': {'error': '#N/A', 'result': null},
        'ADD(3, 5)': {'error': null, 'result': 8},
        'ADD(3.01, 5.02)': {'error': null, 'result': 8.03},
        'ADD(3, -5)': {'error': null, 'result': -2},
        'ASIN()': {'error': '#VALUE!', 'result': null},
        'ASIN("value")': {'error': '#VALUE!', 'result': null},
        'ASINH()': {'error': '#VALUE!', 'result': null},
        'ASINH("value")': {'error': '#VALUE!', 'result': null},
        'ATAN()': {'error': '#VALUE!', 'result': null},
        'ATAN("value")': {'error': '#VALUE!', 'result': null},
        'ATAN2()': {'error': '#VALUE!', 'result': null},
        'ATAN2(1)': {'error': '#VALUE!', 'result': null},
        'ATAN2("value")': {'error': '#VALUE!', 'result': null},
        'ATANH()': {'error': '#VALUE!', 'result': null},
        'ATANH("value")': {'error': '#VALUE!', 'result': null},
        'ATANH(1)': {'error': null, 'result': double.infinity},
      };
      final closeCases = <String, num>{
        'ACOT(1)': 0.7853981633974483,
        'ACOT(-1)': -0.7853981633974483,
        'ASIN(0.5)': 0.5235987755982989,
        'ASINH(0.5)': 0.48121182505960347,
        'ATAN(0.5)': 0.4636476090008061,
        'ATAN2(1, 1)': 0.7853981633974483,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(parser.parse('ACOT()'), {'error': '#VALUE!', 'result': null});
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      expect(aggregateParser.parse('AGGREGATE(1, 4, A1:C1)'), {
        'error': null,
        'result': 2,
      });
      expect(aggregateParser.parse('AGGREGATE(6, 4, A1:C1)'), {
        'error': null,
        'result': 6,
      });
      expect(aggregateParser.parse('AGGREGATE(10, 4, A1:C1, 2)'), {
        'error': null,
        'result': 1,
      });
    });

    test('parses upstream math trig numeral and ceiling fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'ARABIC()': {'error': '#VALUE!', 'result': null},
        'ARABIC("ABC")': {'error': '#VALUE!', 'result': null},
        'ARABIC("X")': {'error': null, 'result': 10},
        'ARABIC("MXL")': {'error': null, 'result': 1040},
        'BASE()': {'error': '#VALUE!', 'result': null},
        'BASE("value")': {'error': '#VALUE!', 'result': null},
        'BASE(7)': {'error': '#VALUE!', 'result': null},
        'BASE(7, 2)': {'error': null, 'result': '111'},
        'BASE(7, 2, 8)': {'error': null, 'result': '00000111'},
        'CEILING()': {'error': '#VALUE!', 'result': null},
        'CEILING("value")': {'error': '#VALUE!', 'result': null},
        'CEILING(7.2)': {'error': null, 'result': 8},
        'CEILING(7, 2, 8)': {'error': null, 'result': 8},
        'CEILING(-4.3)': {'error': null, 'result': -4},
        'CEILING(-1.234, 0.1, "value")': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{'CEILING(-1.234, 0.1)': -1.2};

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream math trig combinations and reciprocal fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'COMBIN()': {'error': '#VALUE!', 'result': null},
        'COMBIN("value")': {'error': '#VALUE!', 'result': null},
        'COMBIN(1)': {'error': '#VALUE!', 'result': null},
        'COMBIN(0, 0)': {'error': null, 'result': 1},
        'COMBIN(1, 0)': {'error': null, 'result': 1},
        'COMBIN(3, 1)': {'error': null, 'result': 3},
        'COMBIN(3, 3)': {'error': null, 'result': 1},
        'COMBINA()': {'error': '#VALUE!', 'result': null},
        'COMBINA("value")': {'error': '#VALUE!', 'result': null},
        'COMBINA(1)': {'error': '#VALUE!', 'result': null},
        'COMBINA(0, 0)': {'error': null, 'result': 1},
        'COMBINA(1, 0)': {'error': null, 'result': 1},
        'COMBINA(3, 1)': {'error': null, 'result': 3},
        'COMBINA(3, 3)': {'error': null, 'result': 10},
        'COS()': {'error': '#VALUE!', 'result': null},
        'COS("value")': {'error': '#VALUE!', 'result': null},
        'COS(0)': {'error': null, 'result': 1},
        'COSH()': {'error': '#VALUE!', 'result': null},
        'COSH("value")': {'error': '#VALUE!', 'result': null},
        'COSH(0)': {'error': null, 'result': 1},
        'COT()': {'error': '#VALUE!', 'result': null},
        'COT("value")': {'error': '#VALUE!', 'result': null},
        'COT(0)': {'error': null, 'result': double.infinity},
        'COTH()': {'error': '#VALUE!', 'result': null},
        'COTH("value")': {'error': '#VALUE!', 'result': null},
        'COTH(0)': {'error': null, 'result': double.infinity},
        'CSC()': {'error': '#VALUE!', 'result': null},
        'CSC("value")': {'error': '#VALUE!', 'result': null},
        'CSC(0)': {'error': null, 'result': double.infinity},
      };
      final closeCases = <String, num>{
        'COS(1)': 0.5403023058681398,
        'COSH(1)': 1.5430806348152437,
        'COT(1)': 0.6420926159343306,
        'COT(2)': -0.45765755436028577,
        'COTH(1)': 1.3130352854993312,
        'COTH(2)': 1.0373147207275482,
        'CSC(1)': 1.1883951057781212,
        'CSC(2)': 1.0997501702946164,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream math trig numeric conversion fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'CSCH()': {'error': '#VALUE!', 'result': null},
        'CSCH("value")': {'error': '#VALUE!', 'result': null},
        'CSCH(0)': {'error': null, 'result': double.infinity},
        'DECIMAL()': {'error': '#VALUE!', 'result': null},
        'DECIMAL(1.3)': {'error': null, 'result': 1},
        'DECIMAL("0", 2)': {'error': null, 'result': 0},
        'DECIMAL("1010101", 2)': {'error': null, 'result': 85},
        'DECIMAL("32b", 16)': {'error': null, 'result': 811},
        'DEGREES()': {'error': '#VALUE!', 'result': null},
        'DEGREES("value")': {'error': '#VALUE!', 'result': null},
        'DEGREES(PI())': {'error': null, 'result': 180},
        'DEGREES(PI() / 2)': {'error': null, 'result': 90},
        'DIVIDE()': {'error': '#N/A', 'result': null},
        'DIVIDE("value")': {'error': '#N/A', 'result': null},
        'DIVIDE(1)': {'error': '#N/A', 'result': null},
        'DIVIDE(0, 0)': {'error': '#DIV/0!', 'result': null},
        'DIVIDE(2, 0)': {'error': '#DIV/0!', 'result': null},
        'DIVIDE(0, 2)': {'error': null, 'result': 0},
        'EVEN()': {'error': '#VALUE!', 'result': null},
        'EVEN("value")': {'error': '#VALUE!', 'result': null},
        'EVEN(1)': {'error': null, 'result': 2},
        'EVEN(-33)': {'error': null, 'result': -34},
        'EQ()': {'error': '#N/A', 'result': null},
        'EQ("value")': {'error': '#N/A', 'result': null},
        'EQ(1, 1)': {'error': null, 'result': true},
        'EQ("foo", "foo")': {'error': null, 'result': true},
        'EQ("bar", "foo")': {'error': null, 'result': false},
        'EQ(12.2, 12.3)': {'error': null, 'result': false},
        'EXP()': {'error': '#N/A', 'result': null},
        'EXP(MY_VAR)': {'error': '#NAME?', 'result': null},
        'EXP("1")': {'error': '#ERROR!', 'result': null},
        'EXP(1, 1)': {'error': '#ERROR!', 'result': null},
        'EXP(1)': {'error': null, 'result': math.e},
      };
      final closeCases = <String, num>{
        'CSCH(1)': 0.8509181282393216,
        'CSCH(2)': 0.27572056477178325,
        'DEGREES(1.1)': 63.02535746439057,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      final decimalInvalid = parser.parse('DECIMAL("value")');
      expect(decimalInvalid['error'], isNull);
      expect(decimalInvalid['result'], isNaN);
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream math trig factorial floor comparison fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'FACT()': {'error': '#VALUE!', 'result': null},
        'FACT("value")': {'error': '#VALUE!', 'result': null},
        'FACT(1)': {'error': null, 'result': 1},
        'FACT(3)': {'error': null, 'result': 6},
        'FACT(3.33)': {'error': null, 'result': 6},
        'FACT(6)': {'error': null, 'result': 720},
        'FACT(6.998)': {'error': null, 'result': 720},
        'FACT(10)': {'error': null, 'result': 3628800},
        'FACTDOUBLE()': {'error': '#VALUE!', 'result': null},
        'FACTDOUBLE("value")': {'error': '#VALUE!', 'result': null},
        'FACTDOUBLE(1)': {'error': null, 'result': 1},
        'FACTDOUBLE(3)': {'error': null, 'result': 3},
        'FACTDOUBLE(3.33)': {'error': null, 'result': 3},
        'FACTDOUBLE(6)': {'error': null, 'result': 48},
        'FACTDOUBLE(6.998)': {'error': null, 'result': 48},
        'FACTDOUBLE(10)': {'error': null, 'result': 3840},
        'FLOOR()': {'error': '#VALUE!', 'result': null},
        'FLOOR("value")': {'error': '#VALUE!', 'result': null},
        'FLOOR(1)': {'error': null, 'result': 1},
        'FLOOR(3.33, 1.11)': {'error': null, 'result': 3},
        'FLOOR(6.998, -1.99)': {'error': null, 'result': 6},
        'FLOOR(-1, -10)': {'error': null, 'result': -10},
        'GCD()': {'error': '#VALUE!', 'result': null},
        'GCD("value")': {'error': '#VALUE!', 'result': null},
        'GCD(1)': {'error': null, 'result': 1},
        'GCD(2, 36)': {'error': null, 'result': 2},
        'GCD(200, -12, 22, 9)': {'error': null, 'result': 1},
        'GTE()': {'error': '#N/A', 'result': null},
        'GTE("value")': {'error': '#N/A', 'result': null},
        'GTE(1)': {'error': '#N/A', 'result': null},
        'GTE(1, 2)': {'error': null, 'result': false},
        'GTE(1.1, 1.1)': {'error': null, 'result': true},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream math trig log and comparison fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'INT()': {'error': '#VALUE!', 'result': null},
        'INT("value")': {'error': '#VALUE!', 'result': null},
        'INT(1)': {'error': null, 'result': 1},
        'INT(1.1)': {'error': null, 'result': 1},
        'INT(1.5)': {'error': null, 'result': 1},
        'LCM()': {'error': '#VALUE!', 'result': null},
        'LCM("value")': {'error': '#VALUE!', 'result': null},
        'LCM(1)': {'error': null, 'result': 1},
        'LCM(1.1, 2)': {'error': null, 'result': 2.2},
        'LCM(3, 8)': {'error': null, 'result': 24},
        'LN()': {'error': '#VALUE!', 'result': null},
        'LN("value")': {'error': '#VALUE!', 'result': null},
        'LN(1)': {'error': null, 'result': 0},
        'LN(${math.e})': {'error': null, 'result': 1},
        'LOG()': {'error': '#VALUE!', 'result': null},
        'LOG("value")': {'error': '#VALUE!', 'result': null},
        'LOG(1)': {'error': '#VALUE!', 'result': null},
        'LOG(10, 10)': {'error': null, 'result': 1},
        'LOG10()': {'error': '#VALUE!', 'result': null},
        'LOG10("value")': {'error': '#VALUE!', 'result': null},
        'LOG10(10)': {'error': null, 'result': 1},
        'LT()': {'error': '#N/A', 'result': null},
        'LT("value")': {'error': '#N/A', 'result': null},
        'LT(1)': {'error': '#N/A', 'result': null},
        'LT(1, 2)': {'error': null, 'result': true},
        'LT(1.1, 1.2)': {'error': null, 'result': true},
        'LT(1.2, 1.2)': {'error': null, 'result': false},
        'LT(1.3, 1.2)': {'error': null, 'result': false},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream math trig operator and rounding fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'LTE()': {'error': '#N/A', 'result': null},
        'LTE("value")': {'error': '#N/A', 'result': null},
        'LTE(1)': {'error': '#N/A', 'result': null},
        'LTE(1, 2)': {'error': null, 'result': true},
        'LTE(1.1, 1.2)': {'error': null, 'result': true},
        'LTE(1.2, 1.2)': {'error': null, 'result': true},
        'LTE(1.3, 1.2)': {'error': null, 'result': false},
        'MINUS()': {'error': '#N/A', 'result': null},
        'MINUS("value")': {'error': '#N/A', 'result': null},
        'MINUS(1)': {'error': '#N/A', 'result': null},
        'MINUS(1, 2)': {'error': null, 'result': -1},
        'MINUS(1.2, 1.2)': {'error': null, 'result': 0},
        'MOD()': {'error': '#VALUE!', 'result': null},
        'MOD("value")': {'error': '#VALUE!', 'result': null},
        'MOD(1)': {'error': '#VALUE!', 'result': null},
        'MOD(1, 2)': {'error': null, 'result': 1},
        'MOD(3, 2)': {'error': null, 'result': 1},
        'MOD(4, 0)': {'error': '#DIV/0!', 'result': null},
        'MROUND()': {'error': '#VALUE!', 'result': null},
        'MROUND("value")': {'error': '#VALUE!', 'result': null},
        'MROUND(1)': {'error': '#VALUE!', 'result': null},
        'MROUND(1, 2)': {'error': null, 'result': 2},
        'MROUND(3, 2)': {'error': null, 'result': 4},
        'MROUND(-4, 1.1)': {'error': '#NUM!', 'result': null},
        'MULTINOMIAL()': {'error': '#VALUE!', 'result': null},
        'MULTINOMIAL("value")': {'error': '#VALUE!', 'result': null},
        'MULTINOMIAL(1)': {'error': null, 'result': 1},
        'MULTINOMIAL(1, 3, 4)': {'error': null, 'result': 280},
        'MULTIPLY()': {'error': '#N/A', 'result': null},
        'MULTIPLY("value")': {'error': '#N/A', 'result': null},
        'MULTIPLY(1)': {'error': '#N/A', 'result': null},
        'MULTIPLY(3, 4)': {'error': null, 'result': 12},
        'MULTIPLY(3, -4)': {'error': null, 'result': -12},
        'MULTIPLY(2, 2.2)': {'error': null, 'result': 4.4},
      };
      final closeCases = <String, num>{
        'MINUS(1.1, 1.2)': -0.1,
        'MINUS(1.3, 1.2)': 0.1,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream math trig power product fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'NE()': {'error': '#N/A', 'result': null},
        'NE("value")': {'error': '#N/A', 'result': null},
        'NE(1)': {'error': '#N/A', 'result': null},
        'NE(3, 4)': {'error': null, 'result': true},
        'NE(3, -4)': {'error': null, 'result': true},
        'NE(2, 2.2)': {'error': null, 'result': true},
        'NE(2.2, 2.2)': {'error': null, 'result': false},
        'ODD()': {'error': '#VALUE!', 'result': null},
        'ODD("value")': {'error': '#VALUE!', 'result': null},
        'ODD(2)': {'error': null, 'result': 3},
        'ODD(-34)': {'error': null, 'result': -35},
        'ODD(11)': {'error': null, 'result': 11},
        'PI()': {'error': null, 'result': math.pi},
        'POWER()': {'error': '#VALUE!', 'result': null},
        'POWER("value")': {'error': '#VALUE!', 'result': null},
        'POWER(2)': {'error': '#VALUE!', 'result': null},
        'POWER(2, 4)': {'error': null, 'result': 16},
        'POWER(2, 8)': {'error': null, 'result': 256},
        'POW()': {'error': '#N/A', 'result': null},
        'POW("value")': {'error': '#N/A', 'result': null},
        'POW(2)': {'error': '#N/A', 'result': null},
        'POW(2, 4)': {'error': null, 'result': 16},
        'POW(2, 8)': {'error': null, 'result': 256},
        'PRODUCT()': {'error': '#VALUE!', 'result': null},
        'PRODUCT("value")': {'error': '#VALUE!', 'result': null},
        'PRODUCT(2)': {'error': null, 'result': 2},
        'PRODUCT(2, 4)': {'error': null, 'result': 8},
        'PRODUCT(2, 8)': {'error': null, 'result': 16},
        'PRODUCT(2, 8, 10, 10)': {'error': null, 'result': 1600},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream math trig quotient random roman fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'QUOTIENT()': {'error': '#VALUE!', 'result': null},
        'QUOTIENT("value")': {'error': '#VALUE!', 'result': null},
        'QUOTIENT(2)': {'error': '#VALUE!', 'result': null},
        'QUOTIENT(2, 4)': {'error': null, 'result': 0},
        'QUOTIENT(8, 2)': {'error': null, 'result': 4},
        'QUOTIENT(9, 2)': {'error': null, 'result': 4},
        'QUOTIENT(-9, 2)': {'error': null, 'result': -4},
        'RADIANS()': {'error': '#VALUE!', 'result': null},
        'RADIANS("value")': {'error': '#VALUE!', 'result': null},
        'RADIANS(180)': {'error': null, 'result': math.pi},
        'RADIANS(90)': {'error': null, 'result': math.pi / 2},
        'ROMAN()': {'error': '#VALUE!', 'result': null},
        'ROMAN("value")': {'error': '#VALUE!', 'result': null},
        'ROMAN(1)': {'error': null, 'result': 'I'},
        'ROMAN(12)': {'error': null, 'result': 'XII'},
        'ROMAN(992)': {'error': null, 'result': 'CMXCII'},
        'ROMAN(2000)': {'error': null, 'result': 'MM'},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }

      final random = parser.parse('RAND()');
      expect(random['error'], isNull);
      expect(random['result'], greaterThanOrEqualTo(0));
      expect(random['result'], lessThanOrEqualTo(1));

      final randomBetween = parser.parse('RANDBETWEEN(-5, -3)');
      expect(randomBetween['error'], isNull);
      expect(randomBetween['result'], greaterThanOrEqualTo(-5));
      expect(randomBetween['result'], lessThanOrEqualTo(-3));
    });

    test('parses upstream math trig rounding sine fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'ROUND()': {'error': '#VALUE!', 'result': null},
        'ROUND("value")': {'error': '#VALUE!', 'result': null},
        'ROUND(1)': {'error': '#VALUE!', 'result': null},
        'ROUND(1.2234, 0)': {'error': null, 'result': 1},
        'ROUND(1.2234, 2)': {'error': null, 'result': 1.22},
        'ROUND(1.2234578, 4)': {'error': null, 'result': 1.2235},
        'ROUND(2345.2234578, -1)': {'error': null, 'result': 2350},
        'ROUND(2345.2234578, -2)': {'error': null, 'result': 2300},
        'ROUNDDOWN()': {'error': '#VALUE!', 'result': null},
        'ROUNDDOWN("value")': {'error': '#VALUE!', 'result': null},
        'ROUNDDOWN(1)': {'error': '#VALUE!', 'result': null},
        'ROUNDDOWN(1.2234, 0)': {'error': null, 'result': 1},
        'ROUNDDOWN(1.2234, 2)': {'error': null, 'result': 1.22},
        'ROUNDDOWN(1.2234578, 4)': {'error': null, 'result': 1.2234},
        'ROUNDDOWN(2345.2234578, -1)': {'error': null, 'result': 2340},
        'ROUNDDOWN(2345.2234578, -2)': {'error': null, 'result': 2300},
        'ROUNDUP()': {'error': '#VALUE!', 'result': null},
        'ROUNDUP("value")': {'error': '#VALUE!', 'result': null},
        'ROUNDUP(1)': {'error': '#VALUE!', 'result': null},
        'ROUNDUP(1.2234, 0)': {'error': null, 'result': 2},
        'ROUNDUP(1.2234, 2)': {'error': null, 'result': 1.23},
        'ROUNDUP(1.2234578, 4)': {'error': null, 'result': 1.2235},
        'ROUNDUP(2345.2234578, -1)': {'error': null, 'result': 2350},
        'ROUNDUP(2345.2234578, -2)': {'error': null, 'result': 2400},
        'SEC()': {'error': '#VALUE!', 'result': null},
        'SEC("value")': {'error': '#VALUE!', 'result': null},
        'SECH()': {'error': '#VALUE!', 'result': null},
        'SECH("value")': {'error': '#VALUE!', 'result': null},
        'SIN()': {'error': '#VALUE!', 'result': null},
        'SIN("value")': {'error': '#VALUE!', 'result': null},
        'SIN(${math.pi / 2})': {'error': null, 'result': 1},
        'SINH()': {'error': '#VALUE!', 'result': null},
        'SINH("value")': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'SEC(1)': 1.8508157176809255,
        'SEC(30)': 6.482921234962678,
        'SECH(1)': 0.6480542736638855,
        'SECH(30)': 1.8715245937680314e-13,
        'SINH(1)': 1.1752011936438014,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream math trig sqrt sum tan fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'B3') {
            done([
              [3, 4],
              [8, 6],
              [1, 9],
            ]);
          } else if (start['label'] == 'A4' && end['label'] == 'B6') {
            done([
              [2, 7],
              [6, 7],
              [5, 3],
            ]);
          } else if (start['label'] == 'C1' && end['label'] == 'C3') {
            done([
              [1, 2, 3],
            ]);
          } else if (start['label'] == 'C4' && end['label'] == 'C6') {
            done([
              [4, 5, 6],
            ]);
          }
        });
      final sumxParser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'B3') {
            done([
              [1, 2, 3],
            ]);
          } else if (start['label'] == 'A4' && end['label'] == 'B6') {
            done([
              [4, 5, 6],
            ]);
          }
        });
      final exactCases = <String, Map<String, Object?>>{
        'SQRT()': {'error': '#VALUE!', 'result': null},
        'SQRT("value")': {'error': '#VALUE!', 'result': null},
        'SQRT(1)': {'error': null, 'result': 1},
        'SQRT(9)': {'error': null, 'result': 3},
        'SQRT(64)': {'error': null, 'result': 8},
        'SUM()': {'error': null, 'result': 0},
        'SUM("value")': {'error': null, 'result': 0},
        'SUM(64)': {'error': null, 'result': 64},
        'SUMPRODUCT(A1:B3, A4:B6)': {'error': null, 'result': 156},
        'SUMSQ()': {'error': '#VALUE!', 'result': null},
        'SUMSQ("value")': {'error': '#VALUE!', 'result': null},
        'SUMSQ(64)': {'error': null, 'result': 4096},
        'SUMX2MY2(C1:C3, C4:C6)': {'error': null, 'result': -63},
        'SUMX2PY2(C1:C3, C4:C6)': {'error': null, 'result': 91},
        'SUMXMY2(C1:C3, C4:C6)': {'error': null, 'result': 27},
        'TAN()': {'error': '#VALUE!', 'result': null},
        'TAN("value")': {'error': '#VALUE!', 'result': null},
        'TANH()': {'error': '#VALUE!', 'result': null},
        'TANH("value")': {'error': '#VALUE!', 'result': null},
        'TRUNC()': {'error': '#VALUE!', 'result': null},
        'TRUNC("value")': {'error': '#VALUE!', 'result': null},
        'TRUNC(1)': {'error': null, 'result': 1},
        'TRUNC(1.99988877)': {'error': null, 'result': 1},
        'TRUNC(-221.99988877)': {'error': null, 'result': -221},
        'TRUNC(0.99988877)': {'error': null, 'result': 0},
      };
      final sumxExactCases = <String, Map<String, Object?>>{
        'SUMX2MY2(A1:B3, A4:B6)': {'error': null, 'result': -63},
        'SUMX2PY2(A1:B3, A4:B6)': {'error': null, 'result': 91},
        'SUMXMY2(A1:B3, A4:B6)': {'error': null, 'result': 27},
      };
      final closeCases = <String, num>{
        'SQRTPI(64)': 14.179630807244127,
        'SUM(64, 3.3, 0.1)': 67.4,
        'SUMSQ(64, 3.3, 0.1)': 4106.9,
        'TAN(1)': 1.5574077246549023,
        'TAN(RADIANS(45))': 1,
        'TANH(1)': 0.761594155955765,
      };

      expect(parser.parse('SQRTPI()'), {'error': '#VALUE!', 'result': null});
      expect(parser.parse('SQRTPI("value")'), {
        'error': '#VALUE!',
        'result': null,
      });
      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in sumxExactCases.entries) {
        expect(sumxParser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test(
      'parses upstream math trig series subtotal conditional sum fixtures',
      () {
        final parser = Parser();
        final subtotalParser = Parser()
          ..on('callRangeValue', (
            Map<String, Object?> start,
            Map<String, Object?> end,
            ParserEventDone done,
          ) {
            done([
              [120, 10, 150, 23],
            ]);
          });
        final conditionalParser = Parser()
          ..on('callRangeValue', (
            Map<String, Object?> start,
            Map<String, Object?> end,
            ParserEventDone done,
          ) {
            done([
              [1, 2, 3],
            ]);
          });
        final fact2 = parser.parse('FACT(2)')['result'] as num;
        final fact4 = parser.parse('FACT(4)')['result'] as num;
        final fact6 = parser.parse('FACT(6)')['result'] as num;
        parser.setVariable('SERIESSUM_ARR', [
          1,
          -1 / fact2,
          1 / fact4,
          -1 / fact6,
        ]);
        final exactCases = <String, Map<String, Object?>>{
          'SIGN()': {'error': '#VALUE!', 'result': null},
          'SIGN("value")': {'error': '#VALUE!', 'result': null},
          'SIGN(1)': {'error': null, 'result': 1},
          'SIGN(30)': {'error': null, 'result': 1},
          'SIGN(-1.1)': {'error': null, 'result': -1},
          'SIGN(0)': {'error': null, 'result': 0},
        };
        final closeCases = <String, num>{
          'SERIESSUM(PI() / 4, 0, 2, SERIESSUM_ARR)': 0.7071032148228457,
        };

        for (final entry in exactCases.entries) {
          expect(parser.parse(entry.key), entry.value, reason: entry.key);
        }
        for (final entry in closeCases.entries) {
          final result = parser.parse(entry.key);
          expect(result['error'], isNull, reason: entry.key);
          expect(
            result['result'],
            closeTo(entry.value, 5e-8),
            reason: entry.key,
          );
        }
        expect(subtotalParser.parse('SUBTOTAL(9, A1:C1)'), {
          'error': null,
          'result': 303,
        });
        expect(conditionalParser.parse('SUMIF(A1:C1, ">2")'), {
          'error': null,
          'result': 3,
        });
        expect(conditionalParser.parse('SUMIFS(A1:C1, ">1", "<3")'), {
          'error': null,
          'result': 2,
        });
      },
    );

    test('parses upstream statistical average fixtures', () {
      final parser = Parser();
      final averageIfParser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'B3') {
            done([
              [2, 4],
              [8, 16],
            ]);
          } else if (start['label'] == 'A4' && end['label'] == 'B6') {
            done([
              [1, 2],
              [3, 4],
            ]);
          }
        });
      final averageIfsParser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'D1') {
            done([2, 4, 8, 16]);
          } else if (start['label'] == 'A2' && end['label'] == 'D2') {
            done([1, 2, 3, 4]);
          } else if (start['label'] == 'A3' && end['label'] == 'D3') {
            done([1, 2, 3, 4]);
          }
        });
      final exactCases = <String, Map<String, Object?>>{
        'AVEDEV()': {'error': '#VALUE!', 'result': null},
        'AVEDEV(1.1)': {'error': null, 'result': 0},
        'AVERAGE()': {'error': '#NUM!', 'result': null},
        'AVERAGEA()': {'error': '#NUM!', 'result': null},
      };
      final closeCases = <String, num>{
        'AVEDEV(1.1, 2)': 0.45,
        'AVEDEV(1.1, 2, 5)': 1.5333333333333332,
        'AVEDEV(1.1, 2, 5, 10)': 2.975,
        'AVERAGE(1.1)': 1.1,
        'AVERAGE(1.1, 2, 5, 10)': 4.525,
        'AVERAGE(1.1, TRUE, 2, NULL, 5, 10)': 4.525,
        'AVERAGEA(1.1)': 1.1,
        'AVERAGEA(1.1, 2, 5, 10)': 4.525,
        'AVERAGEA(1.1, TRUE, 2, NULL, 5, 10)': 3.82,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      expect(averageIfParser.parse('AVERAGEIF(A1:B3, ">5", A4:B6)'), {
        'error': null,
        'result': 3.5,
      });
      expect(
        averageIfsParser.parse('AVERAGEIFS(A1:D1, A2:D2, ">2", A3:D3, ">2")'),
        {'error': null, 'result': 12},
      );
    });

    test('parses upstream statistical beta binomial fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'BETADIST()': {'error': '#VALUE!', 'result': null},
        'BETADIST(2)': {'error': '#VALUE!', 'result': null},
        'BETADIST(2, 8)': {'error': '#VALUE!', 'result': null},
        'BETADIST(2, 8, 10)': {'error': '#VALUE!', 'result': null},
        'BETADIST(2, 8, 10, TRUE, 1)': {'error': null, 'result': 1},
        'BETAINV()': {'error': '#VALUE!', 'result': null},
        'BINOMDIST()': {'error': '#VALUE!', 'result': null},
        'BINOMDIST(6)': {'error': '#VALUE!', 'result': null},
        'BINOMDIST(6, 10)': {'error': '#VALUE!', 'result': null},
        'BINOMDIST(6, 10, 0.5)': {'error': '#VALUE!', 'result': null},
        'BINOM.DIST.RANGE()': {'error': '#VALUE!', 'result': null},
        'BINOM.DIST.RANGE(60)': {'error': '#VALUE!', 'result': null},
        'BINOM.DIST.RANGE(60, 0.5)': {'error': '#VALUE!', 'result': null},
        'BINOM.INV()': {'error': '#VALUE!', 'result': null},
        'BINOM.INV(6)': {'error': '#VALUE!', 'result': null},
        'BINOM.INV(6, 0.5)': {'error': '#VALUE!', 'result': null},
        'BINOM.INV(6, 0.5, 0.7)': {'error': null, 'result': 4},
      };
      final closeCases = <String, num>{
        'BETADIST(2, 8, 10, TRUE, 1, 3)': 0.6854705810117458,
        'BETA.DIST(2, 8, 10, TRUE, 1, 3)': 0.6854705810117458,
        'BETAINV(0.6854705810117458, 8, 10, 1, 3)': 2,
        'BETA.INV(0.6854705810117458, 8, 10, 1, 3)': 2,
        'BINOMDIST(6, 10, 0.5, FALSE)': 0.205078125,
        'BINOM.DIST(6, 10, 0.5, FALSE)': 0.205078125,
        'BINOM.DIST.RANGE(60, 0.5, 34)': 0.060616586840172675,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical chi square fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'CHISQ.DIST()': {'error': '#VALUE!', 'result': null},
        'CHISQ.DIST(0.5)': {'error': '#VALUE!', 'result': null},
        'CHISQ.DIST.RT()': {'error': '#N/A', 'result': null},
        'CHISQ.DIST.RT(0.5)': {'error': '#N/A', 'result': null},
        'CHISQ.DIST.RT(0.5, 1)': {'error': '#NUM!', 'result': null},
        'CHISQ.INV()': {'error': '#VALUE!', 'result': null},
        'CHISQ.INV(0.5)': {'error': '#VALUE!', 'result': null},
        'CHISQ.INV.RT()': {'error': '#N/A', 'result': null},
        'CHISQ.INV.RT(0.5)': {'error': '#N/A', 'result': null},
        'CHISQ.INV.RT(-1, 2)': {'error': '#NUM!', 'result': null},
      };
      final closeCases = <String, num>{
        'CHISQ.DIST(0.5, 1)': 0.43939128946770356,
        'CHISQ.DIST(0.5, 1, TRUE)': 0.5204998778130242,
        'CHISQ.DIST.RT(3, 5)': 0.6999858358786271,
        'CHISQ.INV(0.5, 6)': 5.348120627447116,
        'CHISQ.INV.RT(0.4, 6)': 6.2107571945266935,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical column confidence count fixtures', () {
      final columnParser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          done([
            [1, 2],
            [2, 3],
            [2, 4],
          ]);
        });
      final countParser = Parser()
        ..setVariable('foo', [1, null, 3, 'a', ''])
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          done([
            [1, null, 3],
            ['a', 4, 'c'],
          ]);
        });
      final parser = Parser()
        ..setVariable('bar', [3, 2, 4, 5, 6])
        ..setVariable('baz', [9, 7, 12, 15, 17]);
      final correlParser = Parser()
        ..setVariable('foo', [3, 2, 4, 5, 6])
        ..setVariable('bar', [9, 7, 12, 15, 17]);
      final countInParser = Parser()..setVariable('foo', [1, 1, 2, 2, 2]);
      final exactCases = <String, Map<String, Object?>>{
        'CONFIDENCE()': {'error': '#VALUE!', 'result': null},
        'CONFIDENCE(0.5)': {'error': '#VALUE!', 'result': null},
        'CONFIDENCE(0.5, 1)': {'error': '#VALUE!', 'result': null},
        'CONFIDENCE.T()': {'error': '#VALUE!', 'result': null},
        'CONFIDENCE.T(0.5)': {'error': '#VALUE!', 'result': null},
        'CONFIDENCE.T(0.5, 1)': {'error': '#VALUE!', 'result': null},
        'CORREL()': {'error': '#ERROR!', 'result': null},
        'COUNT()': {'error': null, 'result': 0},
        'COUNT(0.5)': {'error': null, 'result': 1},
        'COUNT(TRUE, 0.5, "foo", 1, 8)': {'error': null, 'result': 3},
        'COUNTA()': {'error': null, 'result': 0},
        'COUNTA(0.5)': {'error': null, 'result': 1},
        'COUNTA(TRUE, 0.5, "foo", 1, 8)': {'error': null, 'result': 5},
        'COUNTBLANK()': {'error': null, 'result': 0},
        'COUNTBLANK(0.5)': {'error': null, 'result': 0},
        'COUNTBLANK(TRUE, 0.5, "", 1, 8)': {'error': null, 'result': 1},
        'COUNTUNIQUE()': {'error': null, 'result': 0},
        'COUNTUNIQUE(1, 1, 2, 2, 3)': {'error': null, 'result': 3},
        'COUNTUNIQUE(1, 1, 2, 2, 3, "a", "a")': {'error': null, 'result': 4},
      };
      final closeCases = <String, num>{
        'CONFIDENCE(0.5, 1, 5)': 0.301640986313058,
        'CONFIDENCE.NORM(0.5, 1, 5)': 0.301640986313058,
        'CONFIDENCE.T(0.5, 1, 5)': 0.33124980616238564,
        'CORREL(bar, baz)': 0.9970544855015815,
      };

      expect(columnParser.parse('COLUMN()'), {'error': '#N/A', 'result': null});
      expect(columnParser.parse('COLUMN(A1:C2)'), {
        'error': '#N/A',
        'result': null,
      });
      expect(columnParser.parse('COLUMN(A1:C2, 0)'), {
        'error': null,
        'result': [
          [1],
          [2],
          [2],
        ],
      });
      expect(columnParser.parse('COLUMN(A1:C2, 1)'), {
        'error': null,
        'result': [
          [2],
          [3],
          [4],
        ],
      });
      expect(columnParser.parse('COLUMNS()'), {
        'error': '#N/A',
        'result': null,
      });
      expect(columnParser.parse('COLUMNS(A1:C2)'), {
        'error': null,
        'result': 2,
      });
      expect(countParser.parse('COUNTIF(foo, ">1")'), {
        'error': null,
        'result': 1,
      });
      expect(countParser.parse('COUNTIF(A1:C2, ">1")'), {
        'error': null,
        'result': 2,
      });
      expect(countParser.parse('COUNTIFS(foo, ">1")'), {
        'error': null,
        'result': 1,
      });
      expect(countParser.parse('COUNTIFS(A1:C2, ">1")'), {
        'error': null,
        'result': 2,
      });
      expect(countInParser.parse('COUNTIN(foo, 1)'), {
        'error': null,
        'result': 2,
      });
      expect(countInParser.parse('COUNTIN(foo, 2)'), {
        'error': null,
        'result': 3,
      });
      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }

      final correlResult = correlParser.parse('CORREL(foo, bar)');
      expect(correlResult['error'], isNull);
      expect(correlResult['result'], closeTo(0.9970544855015815, 5e-8));
    });

    test('parses upstream statistical covariance f distribution fixtures', () {
      final parser = Parser()
        ..setVariable('foo', [3, 2, 4, 5, 6])
        ..setVariable('bar', [9, 7, 12, 15, 17])
        ..setVariable('shortFoo', [2, 4, 8])
        ..setVariable('shortBar', [5, 11, 12])
        ..setVariable('devsqFoo', [4, 5, 8, 7, 11, 4, 3]);
      final covarianceSParser = Parser()
        ..setVariable('foo', [2, 4, 8])
        ..setVariable('bar', [5, 11, 12]);
      final devsqParser = Parser()..setVariable('foo', [4, 5, 8, 7, 11, 4, 3]);
      final exactCases = <String, Map<String, Object?>>{
        'COVARIANCE.P(foo, bar)': {'error': null, 'result': 5.2},
        'EXPONDIST()': {'error': '#VALUE!', 'result': null},
        'EXPONDIST(0.2)': {'error': '#VALUE!', 'result': null},
        'FDIST()': {'error': '#VALUE!', 'result': null},
        'FDIST(15)': {'error': '#VALUE!', 'result': null},
        'FDIST(15, 6)': {'error': '#VALUE!', 'result': null},
        'FDISTRT()': {'error': '#N/A', 'result': null},
        'FDISTRT(15)': {'error': '#N/A', 'result': null},
        'FDISTRT(15, 6)': {'error': '#N/A', 'result': null},
        'FINV()': {'error': '#VALUE!', 'result': null},
        'FINV(0.1)': {'error': '#VALUE!', 'result': null},
        'FINV(0.1, 6)': {'error': '#VALUE!', 'result': null},
        'FINVRT()': {'error': '#N/A', 'result': null},
        'FINVRT(0.1)': {'error': '#N/A', 'result': null},
        'FINVRT(0.1, 6)': {'error': '#N/A', 'result': null},
        'FISHER()': {'error': '#VALUE!', 'result': null},
        'FISHER(1)': {'error': null, 'result': double.infinity},
        'FISHERINV()': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'COVARIANCE.S(shortFoo, shortBar)': 9.666666666,
        'DEVSQ(devsqFoo)': 48,
        'EXPONDIST(0.2, 10)': 1.353352832366127,
        'EXPONDIST(0.2, 10, TRUE)': 0.8646647167633873,
        'EXPON.DIST(0.2, 10, TRUE)': 0.8646647167633873,
        'FDIST(15, 6, 4)': 0.0012714469079329002,
        'FDIST(15, 6, 4, TRUE)': 0.9897419523940192,
        'F.DIST(15, 6, 4, TRUE)': 0.9897419523940192,
        'FDISTRT(15, 6, 4)': 0.010258047605980813,
        'F.DIST.RT(15, 6, 4)': 0.010258047605980813,
        'FINV(0.1, 6, 4)': 0.31438998832176834,
        'F.INV(0.1, 6, 4)': 0.31438998832176834,
        'FINVRT(0.1, 6, 4)': 4.009749312673947,
        'F.INV.RT(0.1, 6, 4)': 4.009749312673947,
        'FISHER(0.1)': 0.10033534773107562,
        'FISHERINV(0.1)': 0.09966799462495583,
        'FISHERINV(1)': 0.761594155955765,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }

      final covarianceSResult = covarianceSParser.parse(
        'COVARIANCE.S(foo, bar)',
      );
      expect(covarianceSResult['error'], isNull);
      expect(covarianceSResult['result'], closeTo(9.666666666, 5e-8));
      final devsqResult = devsqParser.parse('DEVSQ(foo)');
      expect(devsqResult['error'], isNull);
      expect(devsqResult['result'], closeTo(48, 5e-8));
    });

    test('parses upstream statistical forecast gamma growth fixtures', () {
      final parser = Parser()
        ..setVariable('forecastY', [6, 7, 9, 15, 21])
        ..setVariable('forecastX', [20, 28, 31, 38, 40])
        ..setVariable('frequencyData', [79, 85, 78, 85, 50, 81, 95, 88, 97])
        ..setVariable('frequencyBins', [70, 79, 89])
        ..setVariable('geoData', [4, 5, 8, 7, 11, 4, 3])
        ..setVariable('growthY', [33100, 47300, 69000, 102000, 150000, 220000])
        ..setVariable('growthX', [11, 12, 13, 14, 15, 16])
        ..setVariable('growthNewX', [11, 12, 13, 14, 15, 16, 17, 18, 19]);
      final forecastParser = Parser()
        ..setVariable('foo', [6, 7, 9, 15, 21])
        ..setVariable('bar', [20, 28, 31, 38, 40]);
      final frequencyParser = Parser()
        ..setVariable('foo', [79, 85, 78, 85, 50, 81, 95, 88, 97])
        ..setVariable('bar', [70, 79, 89]);
      final meanParser = Parser()..setVariable('foo', [4, 5, 8, 7, 11, 4, 3]);
      final growthParser = Parser()
        ..setVariable('foo', [33100, 47300, 69000, 102000, 150000, 220000])
        ..setVariable('bar', [11, 12, 13, 14, 15, 16])
        ..setVariable('baz', [11, 12, 13, 14, 15, 16, 17, 18, 19]);
      final exactCases = <String, Map<String, Object?>>{
        'FREQUENCY(frequencyData, frequencyBins)': {
          'error': null,
          'result': [1, 2, 4, 2],
        },
        'GAMMA()': {'error': '#VALUE!', 'result': null},
        'GAMMADIST()': {'error': '#N/A', 'result': null},
        'GAMMADIST(1)': {'error': '#N/A', 'result': null},
        'GAMMADIST(1, 3)': {'error': '#N/A', 'result': null},
        'GAMMADIST(1, 3, 7)': {'error': '#N/A', 'result': null},
        'GAMMAINV()': {'error': '#N/A', 'result': null},
        'GAMMAINV(1)': {'error': '#N/A', 'result': null},
        'GAMMAINV(1, 3)': {'error': '#N/A', 'result': null},
        'GAMMALN()': {'error': '#VALUE!', 'result': null},
        'GAMMALN.PRECISE()': {'error': '#N/A', 'result': null},
        'GAUSS()': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'FORECAST(30, forecastY, forecastX)': 10.607253086419755,
        'GAMMA(0.1)': 9.51350769866877,
        'GAMMADIST(1, 3, 7, TRUE)': 0.00043670743091302124,
        'GAMMA.DIST(1, 3, 7, TRUE)': 0.00043670743091302124,
        'GAMMAINV(1, 3, 7)': 1233.435565298214,
        'GAMMA.INV(1, 3, 7)': 1233.435565298214,
        'GAMMALN(4)': 1.7917594692280547,
        'GAMMALN.PRECISE(4)': 1.7917594692280547,
        'GAUSS(4)': 0.4999683287581669,
        'GEOMEAN(geoData)': 5.476986969656962,
        'HARMEAN(geoData)': 5.028375962061728,
      };
      final growthResult = parser.parse('GROWTH(growthY, growthX, growthNewX)');
      final upstreamGrowthResult = growthParser.parse('GROWTH(foo, bar, baz)');
      final expectedGrowth = <num>[
        32618.20377353843,
        47729.422614746654,
        69841.30085621699,
        102197.07337883323,
        149542.4867400496,
        218821.8762146044,
        320196.71836349065,
        468536.05418408196,
        685597.3889812973,
      ];

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final forecastResult = forecastParser.parse('FORECAST(30, foo, bar)');
      expect(forecastResult['error'], isNull);
      expect(forecastResult['result'], closeTo(10.607253086419755, 5e-8));
      expect(frequencyParser.parse('FREQUENCY(foo, bar)'), {
        'error': null,
        'result': [1, 2, 4, 2],
      });
      for (final entry in <String, num>{
        'GEOMEAN(foo)': 5.476986969656962,
        'HARMEAN(foo)': 5.028375962061728,
      }.entries) {
        final result = meanParser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      expect(growthResult['error'], isNull);
      expect(growthResult['result'], isA<List<Object?>>());
      final growthValues = growthResult['result']! as List<Object?>;
      expect(growthValues, hasLength(expectedGrowth.length));
      expect(upstreamGrowthResult['error'], isNull);
      expect(upstreamGrowthResult['result'], isA<List<Object?>>());
      final upstreamGrowthValues =
          upstreamGrowthResult['result']! as List<Object?>;
      expect(upstreamGrowthValues, hasLength(expectedGrowth.length));
      for (var index = 0; index < expectedGrowth.length; index += 1) {
        expect(
          growthValues[index],
          closeTo(expectedGrowth[index], 5e-6),
          reason: 'GROWTH index $index',
        );
        expect(
          upstreamGrowthValues[index],
          closeTo(expectedGrowth[index], 5e-6),
          reason: 'upstream GROWTH index $index',
        );
      }
    });

    test('parses upstream statistical hypgeom regression fixtures', () {
      final parser = Parser()
        ..setVariable('interceptY', [2, 3, 9, 1, 8])
        ..setVariable('interceptX', [6, 5, 11, 7, 5])
        ..setVariable('kurtData', [3, 4, 5, 2, 3, 4, 5, 6, 4, 7])
        ..setVariable('kurtBadData', [3, 4, 5, 2, 3, 4, 5, 'dewdwe', 4, 7])
        ..setVariable('largeData', [3, 5, 3, 5, 4])
        ..setVariable('largeBadData', [3, 5, 3, 'dwedwed', 4])
        ..setVariable('regressionY', [1, 9, 5, 7])
        ..setVariable('regressionX', [0, 4, 2, 3]);
      final interceptParser = Parser()
        ..setVariable('foo', [2, 3, 9, 1, 8])
        ..setVariable('bar', [6, 5, 11, 7, 5]);
      final kurtParser = Parser()
        ..setVariable('foo', [3, 4, 5, 2, 3, 4, 5, 6, 4, 7])
        ..setVariable('bar', [3, 4, 5, 2, 3, 4, 5, 'dewdwe', 4, 7]);
      final largeParser = Parser()
        ..setVariable('foo', [3, 5, 3, 5, 4])
        ..setVariable('bar', [3, 5, 3, 'dwedwed', 4]);
      final regressionParser = Parser()
        ..setVariable('foo', [1, 9, 5, 7])
        ..setVariable('bar', [0, 4, 2, 3]);
      final exactCases = <String, Map<String, Object?>>{
        'HYPGEOMDIST()': {'error': '#VALUE!', 'result': null},
        'HYPGEOMDIST(1)': {'error': '#VALUE!', 'result': null},
        'HYPGEOMDIST(1, 4)': {'error': '#VALUE!', 'result': null},
        'HYPGEOMDIST(1, 4, 8)': {'error': '#VALUE!', 'result': null},
        'LARGE(largeData, 3)': {'error': null, 'result': 4},
        'LARGE(largeBadData, 3)': {'error': '#VALUE!', 'result': null},
        'LINEST(regressionY, regressionX)': {
          'error': null,
          'result': [2, 1],
        },
        'LINEST(regressionY, "aaaaaa")': {'error': '#VALUE!', 'result': null},
        'LOGEST(regressionY, "aaaaaa")': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'HYPGEOMDIST(1, 4, 8, 20)': 0.3632610939112487,
        'HYPGEOMDIST(1, 4, 8, 20, TRUE)': 0.46542827657378744,
        'INTERCEPT(interceptY, interceptX)': 0.04838709677419217,
        'KURT(kurtData)': -0.15179963720841627,
      };
      final logestResult = parser.parse('LOGEST(regressionY, regressionX)');
      final upstreamLogestResult = regressionParser.parse('LOGEST(foo, bar)');

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(parser.parse('KURT(kurtBadData)'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(kurtParser.parse('KURT(bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(largeParser.parse('LARGE(foo, 3)'), {'error': null, 'result': 4});
      expect(largeParser.parse('LARGE(bar, 3)'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(regressionParser.parse('LINEST(foo, bar)'), {
        'error': null,
        'result': [2, 1],
      });
      expect(regressionParser.parse('LINEST(foo, "aaaaaa")'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(regressionParser.parse('LOGEST(foo, "aaaaaa")'), {
        'error': '#VALUE!',
        'result': null,
      });
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final interceptResult = interceptParser.parse('INTERCEPT(foo, bar)');
      expect(interceptResult['error'], isNull);
      expect(interceptResult['result'], closeTo(0.04838709677419217, 5e-8));
      final kurtResult = kurtParser.parse('KURT(foo)');
      expect(kurtResult['error'], isNull);
      expect(kurtResult['result'], closeTo(-0.15179963720841627, 5e-8));
      expect(logestResult['error'], isNull);
      expect(logestResult['result'], isA<List<Object?>>());
      final logestValues = logestResult['result']! as List<Object?>;
      expect(logestValues, hasLength(2));
      expect(logestValues[0], closeTo(1.751116, 5e-7));
      expect(logestValues[1], closeTo(1.194316, 5e-7));
      expect(upstreamLogestResult['error'], isNull);
      expect(upstreamLogestResult['result'], isA<List<Object?>>());
      final upstreamLogestValues =
          upstreamLogestResult['result']! as List<Object?>;
      expect(upstreamLogestValues, hasLength(2));
      expect(upstreamLogestValues[0], closeTo(1.751116, 5e-7));
      expect(upstreamLogestValues[1], closeTo(1.194316, 5e-7));
    });

    test('parses upstream statistical lognorm mode fixtures', () {
      final parser = Parser()
        ..setVariable('multiData', [1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1])
        ..setVariable('multiBadData', [
          1,
          2,
          'dewdew',
          4,
          3,
          2,
          1,
          2,
          3,
          5,
          6,
          1,
        ])
        ..setVariable('singleData', [5.6, 4, 4, 3, 2, 4])
        ..setVariable('singleBadData', [5.6, 'dewdew', 4, 3, 2, 4]);
      final multiModeParser = Parser()
        ..setVariable('foo', [1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1])
        ..setVariable('bar', [1, 2, 'dewdew', 4, 3, 2, 1, 2, 3, 5, 6, 1]);
      final singleModeParser = Parser()
        ..setVariable('foo', [5.6, 4, 4, 3, 2, 4])
        ..setVariable('bar', [5.6, 'dewdew', 4, 3, 2, 4]);
      final exactCases = <String, Map<String, Object?>>{
        'LOGNORMDIST()': {'error': '#VALUE!', 'result': null},
        'LOGNORMDIST(4)': {'error': '#VALUE!', 'result': null},
        'LOGNORMDIST(4, 3.5)': {'error': '#VALUE!', 'result': null},
        'LOGNORMINV()': {'error': '#VALUE!', 'result': null},
        'LOGNORMINV(0.0390835557068005)': {'error': '#VALUE!', 'result': null},
        'LOGNORMINV(0.0390835557068005, 3.5)': {
          'error': '#VALUE!',
          'result': null,
        },
        'MAX()': {'error': null, 'result': 0},
        'MAX(-1, 9, 9.2, 4, "foo", TRUE)': {'error': null, 'result': 9.2},
        'MAXA()': {'error': null, 'result': 0},
        'MAXA(-1, 9, 9.2, 4, "foo", TRUE)': {'error': null, 'result': 9.2},
        'MEDIAN()': {'error': '#NUM!', 'result': null},
        'MEDIAN(1, 9, 9.2, 4)': {'error': null, 'result': 6.5},
        'MIN()': {'error': null, 'result': 0},
        'MIN(-1.1, 9, 9.2, 4, "foo", TRUE)': {'error': null, 'result': -1.1},
        'MINA()': {'error': null, 'result': 0},
        'MINA(-1.1, 9, 9.2, 4, "foo", TRUE)': {'error': null, 'result': -1.1},
        'MODEMULT(multiData)': {
          'error': null,
          'result': [2, 3, 1],
        },
        'MODE.MULT(multiData)': {
          'error': null,
          'result': [2, 3, 1],
        },
        'MODEMULT(multiBadData)': {'error': '#VALUE!', 'result': null},
        'MODESNGL(singleData)': {'error': null, 'result': 4},
        'MODE.SNGL(singleData)': {'error': null, 'result': 4},
        'MODESNGL(singleBadData)': {'error': '#VALUE!', 'result': null},
        'NEGBINOMDIST()': {'error': '#VALUE!', 'result': null},
        'NEGBINOMDIST(10)': {'error': '#VALUE!', 'result': null},
        'NEGBINOMDIST(10, 5)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'LOGNORMDIST(4, 3.5, 1.2)': 0.01761759668181924,
        'LOGNORMDIST(4, 3.5, 1.2, TRUE)': 0.0390835557068005,
        'LOGNORM.DIST(4, 3.5, 1.2, TRUE)': 0.0390835557068005,
        'LOGNORMINV(0.0390835557068005, 3.5, 1.2)': 4,
        'LOGNORM.INV(0.0390835557068005, 3.5, 1.2)': 4,
        'NEGBINOMDIST(10, 5, 0.25)': 0.05504866037517786,
        'NEGBINOMDIST(10, 5, 0.25, TRUE)': 0.3135140584781766,
        'NEGBINOM.DIST(10, 5, 0.25, TRUE)': 0.3135140584781766,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(multiModeParser.parse('MODEMULT(foo)'), {
        'error': null,
        'result': [2, 3, 1],
      });
      expect(multiModeParser.parse('MODE.MULT(foo)'), {
        'error': null,
        'result': [2, 3, 1],
      });
      expect(multiModeParser.parse('MODEMULT(bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(singleModeParser.parse('MODESNGL(foo)'), {
        'error': null,
        'result': 4,
      });
      expect(singleModeParser.parse('MODE.SNGL(foo)'), {
        'error': null,
        'result': 4,
      });
      expect(singleModeParser.parse('MODESNGL(bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical normal percentile fixtures', () {
      final parser = Parser()
        ..setVariable('pearsonY', [9, 7, 5, 3, 1])
        ..setVariable('pearsonX', [10, 6, 1, 5, 3])
        ..setVariable('pearsonBadX', [10, 'dewdewd', 1, 5, 3])
        ..setVariable('rankData', [1, 2, 3, 4])
        ..setVariable('rankBadData', [1, 'dewdew', 3, 4]);
      final pearsonParser = Parser()
        ..setVariable('foo', [9, 7, 5, 3, 1])
        ..setVariable('bar', [10, 6, 1, 5, 3])
        ..setVariable('baz', [10, 'dewdewd', 1, 5, 3]);
      final percentileParser = Parser()
        ..setVariable('foo', [1, 2, 3, 4])
        ..setVariable('bar', [1, 'dewdew', 3, 4]);
      final exactCases = <String, Map<String, Object?>>{
        'NORMDIST()': {'error': '#VALUE!', 'result': null},
        'NORMDIST(1)': {'error': '#VALUE!', 'result': null},
        'NORMDIST(1, 0)': {'error': '#VALUE!', 'result': null},
        'NORMINV()': {'error': '#VALUE!', 'result': null},
        'NORMINV(1)': {'error': '#VALUE!', 'result': null},
        'NORMINV(1, 0)': {'error': '#VALUE!', 'result': null},
        'NORMSDIST()': {'error': '#VALUE!', 'result': null},
        'NORMSINV()': {'error': '#VALUE!', 'result': null},
        'PEARSON(pearsonY, pearsonBadX)': {'error': '#VALUE!', 'result': null},
        'PERCENTILEEXC(rankData, 0)': {'error': '#NUM!', 'result': null},
        'PERCENTILEEXC(rankData, 0.5)': {'error': null, 'result': 2.5},
        'PERCENTILEEXC(rankBadData, 0.5)': {'error': '#VALUE!', 'result': null},
        'PERCENTILEINC(rankData, 0)': {'error': null, 'result': 1},
        'PERCENTILEINC(rankData, 0.5)': {'error': null, 'result': 2.5},
        'PERCENTILEINC(rankBadData, 0.5)': {'error': '#VALUE!', 'result': null},
        'PERCENTRANKEXC(rankData, 1)': {'error': null, 'result': 0.2},
        'PERCENTRANKEXC(rankData, 4)': {'error': null, 'result': 0.8},
        'PERCENTRANKEXC(rankBadData, 4)': {'error': '#VALUE!', 'result': null},
        'PERCENTRANKINC(rankData, 1)': {'error': null, 'result': 0},
        'PERCENTRANKINC(rankData, 4)': {'error': null, 'result': 1},
        'PERCENTRANKINC(rankBadData, 4)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'NORMDIST(1, 0, 1)': 0.24197072451914337,
        'NORMDIST(1, 0, 1, TRUE)': 0.8413447460685429,
        'NORM.DIST(1, 0, 1, TRUE)': 0.8413447460685429,
        'NORMINV(1, 0, 1)': 141.4213562373095,
        'NORM.INV(1, 0, 1)': 141.4213562373095,
        'NORMSDIST(1)': 0.24197072451914337,
        'NORMSDIST(1, TRUE)': 0.8413447460685429,
        'NORM.S.DIST(1, TRUE)': 0.8413447460685429,
        'NORMSINV(1)': 141.4213562373095,
        'NORM.S.INV(1)': 141.4213562373095,
        'PEARSON(pearsonY, pearsonX)': 0.6993786061802354,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(pearsonParser.parse('PEARSON(foo, baz)'), {
        'error': '#VALUE!',
        'result': null,
      });
      final percentileExactCases = <String, Map<String, Object?>>{
        'PERCENTILEEXC(foo, 0)': {'error': '#NUM!', 'result': null},
        'PERCENTILEEXC(foo, 0.5)': {'error': null, 'result': 2.5},
        'PERCENTILEEXC(bar, 0.5)': {'error': '#VALUE!', 'result': null},
        'PERCENTILEINC(foo, 0)': {'error': null, 'result': 1},
        'PERCENTILEINC(foo, 0.5)': {'error': null, 'result': 2.5},
        'PERCENTILEINC(bar, 0.5)': {'error': '#VALUE!', 'result': null},
        'PERCENTRANKEXC(foo, 1)': {'error': null, 'result': 0.2},
        'PERCENTRANKEXC(foo, 4)': {'error': null, 'result': 0.8},
        'PERCENTRANKEXC(bar, 4)': {'error': '#VALUE!', 'result': null},
        'PERCENTRANKINC(foo, 1)': {'error': null, 'result': 0},
        'PERCENTRANKINC(foo, 4)': {'error': null, 'result': 1},
        'PERCENTRANKINC(bar, 4)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in percentileExactCases.entries) {
        expect(
          percentileParser.parse(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final pearsonResult = pearsonParser.parse('PEARSON(foo, bar)');
      expect(pearsonResult['error'], isNull);
      expect(pearsonResult['result'], closeTo(0.6993786061802354, 5e-8));
    });

    test('parses upstream statistical permutation rank fixtures', () {
      final parser = Parser()
        ..setVariable('probX', [0, 1, 2, 3])
        ..setVariable('probP', [0.2, 0.3, 0.1, 0.4])
        ..setVariable('probBadX', [0, 'dewd', 2, 3])
        ..setVariable('quartileExcData', [
          6,
          7,
          15,
          36,
          39,
          40,
          41,
          42,
          43,
          47,
          49,
        ])
        ..setVariable('quartileIncData', [1, 2, 4, 7, 8, 9, 10, 12])
        ..setVariable('rankAvgData', [89, 88, 92, 101, 94, 97, 95])
        ..setVariable('rankEqData', [7, 3.5, 3.5, 1, 2]);
      final probParser = Parser()
        ..setVariable('foo', [0, 1, 2, 3])
        ..setVariable('bar', [0.2, 0.3, 0.1, 0.4])
        ..setVariable('baz', [0, 'dewd', 2, 3]);
      final quartileExcParser = Parser()
        ..setVariable('foo', [6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49]);
      final quartileIncParser = Parser()
        ..setVariable('foo', [1, 2, 4, 7, 8, 9, 10, 12]);
      final rankAvgParser = Parser()
        ..setVariable('foo', [89, 88, 92, 101, 94, 97, 95]);
      final rankEqParser = Parser()..setVariable('foo', [7, 3.5, 3.5, 1, 2]);
      final exactCases = <String, Map<String, Object?>>{
        'PERMUT()': {'error': '#VALUE!', 'result': null},
        'PERMUT(10)': {'error': '#VALUE!', 'result': null},
        'PERMUT(10, 3)': {'error': null, 'result': 720},
        'PERMUTATIONA()': {'error': '#VALUE!', 'result': null},
        'PERMUTATIONA(10)': {'error': '#VALUE!', 'result': null},
        'PERMUTATIONA(10, 3)': {'error': null, 'result': 1000},
        'PHI()': {'error': '#VALUE!', 'result': null},
        'POISSONDIST()': {'error': '#VALUE!', 'result': null},
        'POISSONDIST(1)': {'error': '#VALUE!', 'result': null},
        'PROB(probX, probP, 2)': {'error': null, 'result': 0.1},
        'PROB(probX, probP, 1, 3)': {'error': null, 'result': 0.8},
        'PROB(probX, probP)': {'error': null, 'result': 0},
        'PROB(probBadX, probP, 1, 3)': {'error': '#VALUE!', 'result': null},
        'QUARTILEEXC(quartileExcData, 1)': {'error': null, 'result': 15},
        'QUARTILEEXC(quartileExcData, 2)': {'error': null, 'result': 40},
        'QUARTILE.EXC(quartileExcData, 2)': {'error': null, 'result': 40},
        'QUARTILEEXC(quartileExcData, 4)': {'error': '#NUM!', 'result': null},
        'QUARTILEEXC(quartileExcData, "dwe")': {
          'error': '#VALUE!',
          'result': null,
        },
        'QUARTILEINC(quartileIncData, 1)': {'error': null, 'result': 3.5},
        'QUARTILEINC(quartileIncData, 2)': {'error': null, 'result': 7.5},
        'QUARTILE.INC(quartileIncData, 2)': {'error': null, 'result': 7.5},
        'QUARTILEINC(quartileIncData, 4)': {'error': '#NUM!', 'result': null},
        'QUARTILEINC(quartileIncData, "dwe")': {
          'error': '#VALUE!',
          'result': null,
        },
        'RANKAVG(94, rankAvgData)': {'error': null, 'result': 4},
        'RANKAVG(88, rankAvgData, 1)': {'error': null, 'result': 1},
        'RANK.AVG(88, rankAvgData, 1)': {'error': null, 'result': 1},
        'RANKAVG("dwe", rankAvgData, 1)': {'error': '#VALUE!', 'result': null},
        'RANKEQ(7, rankEqData, 1)': {'error': null, 'result': 5},
        'RANKEQ(2, rankEqData)': {'error': null, 'result': 4},
        'RANK.EQ(2, rankEqData)': {'error': null, 'result': 4},
        'RANKEQ("dwe", rankEqData, TRUE)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'PHI(1)': 0.24197072451914337,
        'POISSONDIST(1, 3)': 0.14936120510359185,
        'POISSONDIST(1, 3, TRUE)': 0.1991482734714558,
        'POISSON.DIST(1, 3, TRUE)': 0.1991482734714558,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      final probExactCases = <String, Map<String, Object?>>{
        'PROB(foo, bar, 2)': {'error': null, 'result': 0.1},
        'PROB(foo, bar, 1, 3)': {'error': null, 'result': 0.8},
        'PROB(foo, bar)': {'error': null, 'result': 0},
        'PROB(baz, bar, 1, 3)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in probExactCases.entries) {
        expect(probParser.parse(entry.key), entry.value, reason: entry.key);
      }
      final quartileExcExactCases = <String, Map<String, Object?>>{
        'QUARTILEEXC(foo, 1)': {'error': null, 'result': 15},
        'QUARTILEEXC(foo, 2)': {'error': null, 'result': 40},
        'QUARTILE.EXC(foo, 2)': {'error': null, 'result': 40},
        'QUARTILEEXC(foo, 4)': {'error': '#NUM!', 'result': null},
        'QUARTILEEXC(foo, "dwe")': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in quartileExcExactCases.entries) {
        expect(
          quartileExcParser.parse(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      final quartileIncExactCases = <String, Map<String, Object?>>{
        'QUARTILEINC(foo, 1)': {'error': null, 'result': 3.5},
        'QUARTILEINC(foo, 2)': {'error': null, 'result': 7.5},
        'QUARTILE.INC(foo, 2)': {'error': null, 'result': 7.5},
        'QUARTILEINC(foo, 4)': {'error': '#NUM!', 'result': null},
        'QUARTILEINC(foo, "dwe")': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in quartileIncExactCases.entries) {
        expect(
          quartileIncParser.parse(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      final rankAvgExactCases = <String, Map<String, Object?>>{
        'RANKAVG(94, foo)': {'error': null, 'result': 4},
        'RANKAVG(88, foo, 1)': {'error': null, 'result': 1},
        'RANK.AVG(88, foo, 1)': {'error': null, 'result': 1},
        'RANKAVG("dwe", foo, 1)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in rankAvgExactCases.entries) {
        expect(rankAvgParser.parse(entry.key), entry.value, reason: entry.key);
      }
      final rankEqExactCases = <String, Map<String, Object?>>{
        'RANKEQ(7, foo, 1)': {'error': null, 'result': 5},
        'RANKEQ(2, foo)': {'error': null, 'result': 4},
        'RANK.EQ(2, foo)': {'error': null, 'result': 4},
        'RANKEQ("dwe", foo, TRUE)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in rankEqExactCases.entries) {
        expect(rankEqParser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical row rows fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C2') {
            done([
              [1, 2],
              [2, 3],
              [2, 4],
            ]);
          }
        });

      expect(parser.parse('ROW()'), {'error': '#N/A', 'result': null});
      expect(parser.parse('ROW(A1:C2)'), {'error': '#N/A', 'result': null});
      expect(parser.parse('ROW(A1:C2, -1)'), {
        'error': '#NUM!',
        'result': null,
      });
      expect(parser.parse('ROW(A1:C2, 0)'), {
        'error': null,
        'result': [1, 2],
      });
      expect(parser.parse('ROW(A1:C2, 2)'), {
        'error': null,
        'result': [2, 4],
      });
      expect(parser.parse('ROWS()'), {'error': '#N/A', 'result': null});
      expect(parser.parse('ROWS(A1:C2)'), {'error': null, 'result': 3});
    });

    test('parses upstream statistical regression deviation fixtures', () {
      final parser = Parser()
        ..setVariable('regressionY', [2, 3, 9, 1, 8, 7, 5])
        ..setVariable('regressionX', [6, 5, 11, 7, 5, 4, 4])
        ..setVariable('regressionBadY', [6, 'dwe', 11, 7, 5, 4, 4])
        ..setVariable('standardErrorBadX', [6, 5, 'dwe', 7, 5, 4, 4])
        ..setVariable('skewData', [3, 4, 5, 2, 3, 4, 5, 6, 4, 7])
        ..setVariable('skewBadData', [3, 'dwe', 5, 2, 3, 4, 5, 6, 4, 7])
        ..setVariable('smallData', [3, 4, 5, 2, 3, 4, 6, 4, 7])
        ..setVariable('smallBadData', [3, 4, 'dwe', 2, 3, 4, 6, 4, 7])
        ..setVariable('stdevData', [
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
        ]);
      final regressionParser = Parser()
        ..setVariable('foo', [2, 3, 9, 1, 8, 7, 5])
        ..setVariable('bar', [6, 5, 11, 7, 5, 4, 4])
        ..setVariable('baz', [6, 'dwe', 11, 7, 5, 4, 4]);
      final skewParser = Parser()
        ..setVariable('foo', [3, 4, 5, 2, 3, 4, 5, 6, 4, 7])
        ..setVariable('bar', [3, 'dwe', 5, 2, 3, 4, 5, 6, 4, 7]);
      final smallParser = Parser()
        ..setVariable('foo', [3, 4, 5, 2, 3, 4, 6, 4, 7])
        ..setVariable('bar', [3, 4, 'dwe', 2, 3, 4, 6, 4, 7]);
      final stdevParser = Parser()
        ..setVariable('foo', [
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
        ]);
      final standardErrorParser = Parser()
        ..setVariable('foo', [2, 3, 9, 1, 8, 7, 5])
        ..setVariable('bar', [6, 5, 11, 7, 5, 4, 4])
        ..setVariable('baz', [6, 5, 'dwe', 7, 5, 4, 4]);
      final exactCases = <String, Map<String, Object?>>{
        'RSQ(regressionBadY, regressionX)': {
          'error': '#VALUE!',
          'result': null,
        },
        'SKEW(skewBadData)': {'error': '#VALUE!', 'result': null},
        'SKEWP(skewBadData)': {'error': '#VALUE!', 'result': null},
        'SKEW.P(skewBadData)': {'error': '#VALUE!', 'result': null},
        'SLOPE(regressionBadY, regressionX)': {
          'error': '#VALUE!',
          'result': null,
        },
        'SMALL(smallData, 4)': {'error': null, 'result': 4},
        'SMALL(smallBadData, 4)': {'error': '#VALUE!', 'result': null},
        'STANDARDIZE()': {'error': '#VALUE!', 'result': null},
        'STANDARDIZE(1)': {'error': '#VALUE!', 'result': null},
        'STANDARDIZE(1, 3)': {'error': '#VALUE!', 'result': null},
        'STANDARDIZE(1, 3, 5)': {'error': null, 'result': -0.4},
        'STEYX(standardErrorBadX, regressionX)': {
          'error': '#VALUE!',
          'result': null,
        },
      };
      final closeCases = <String, num>{
        'RSQ(regressionY, regressionX)': 0.05795019157088122,
        'SKEW(skewData)': 0.3595430714067974,
        'SKEWP(skewData)': 0.303193339354144,
        'SKEW.P(skewData)': 0.303193339354144,
        'SLOPE(regressionY, regressionX)': 0.3055555555555556,
        'STDEVP(stdevData)': 26.054558142482477,
        'STDEV.P(stdevData)': 26.054558142482477,
        'STDEVS(stdevData)': 27.46391571984349,
        'STDEV.S(stdevData)': 27.46391571984349,
        'STDEVA(stdevData)': 27.46391571984349,
        'STDEVPA(stdevData)': 26.054558142482477,
        'STEYX(regressionY, regressionX)': 3.305718950210041,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(regressionParser.parse('RSQ(baz, bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(regressionParser.parse('SLOPE(baz, bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      final skewExactCases = <String, Map<String, Object?>>{
        'SKEW(bar)': {'error': '#VALUE!', 'result': null},
        'SKEWP(bar)': {'error': '#VALUE!', 'result': null},
        'SKEW.P(bar)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in skewExactCases.entries) {
        expect(skewParser.parse(entry.key), entry.value, reason: entry.key);
      }
      final smallExactCases = <String, Map<String, Object?>>{
        'SMALL(foo, 4)': {'error': null, 'result': 4},
        'SMALL(bar, 4)': {'error': '#VALUE!', 'result': null},
      };
      for (final entry in smallExactCases.entries) {
        expect(smallParser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(standardErrorParser.parse('STEYX(baz, bar)'), {
        'error': '#VALUE!',
        'result': null,
      });
      final regressionCloseCases = <String, num>{
        'RSQ(foo, bar)': 0.05795019157088122,
        'SLOPE(foo, bar)': 0.3055555555555556,
      };
      for (final entry in regressionCloseCases.entries) {
        final result = regressionParser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final skewCloseCases = <String, num>{
        'SKEW(foo)': 0.3595430714067974,
        'SKEWP(foo)': 0.303193339354144,
        'SKEW.P(foo)': 0.303193339354144,
      };
      for (final entry in skewCloseCases.entries) {
        final result = skewParser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final stdevCloseCases = <String, num>{
        'STDEVP(foo)': 26.054558142482477,
        'STDEV.P(foo)': 26.054558142482477,
        'STDEVS(foo)': 27.46391571984349,
        'STDEV.S(foo)': 27.46391571984349,
        'STDEVA(foo)': 27.46391571984349,
        'STDEVPA(foo)': 26.054558142482477,
      };
      for (final entry in stdevCloseCases.entries) {
        final result = stdevParser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
      final standardErrorResult = standardErrorParser.parse('STEYX(foo, bar)');
      expect(standardErrorResult['error'], isNull);
      expect(standardErrorResult['result'], closeTo(3.305718950210041, 5e-8));
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical transpose t trend fixtures', () {
      final parser = Parser()
        ..setVariable('trendY', [1, 9, 5, 7])
        ..setVariable('trendX', [0, 4, 2, 3])
        ..setVariable('trendNewX', [5, 8])
        ..setVariable('trimData', [4, 5, 6, 7, 2, 3, 4, 5, 1, 2, 3])
        ..setVariable('trimBadData', [4, 5, 'dwe', 7, 2, 3, 4, 5, 1, 2, 3])
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C2') {
            done([
              [1, 2],
              [3, 4],
              [5, 6],
            ]);
          } else if (start['label'] == 'A3' && end['label'] == 'C3') {
            done([1, 2, 3]);
          }
        });
      final trendParser = Parser()
        ..setVariable('foo', [1, 9, 5, 7])
        ..setVariable('bar', [0, 4, 2, 3])
        ..setVariable('baz', [5, 8]);
      final trimMeanParser = Parser()
        ..setVariable('foo', [4, 5, 6, 7, 2, 3, 4, 5, 1, 2, 3])
        ..setVariable('bar', [4, 5, 'dwe', 7, 2, 3, 4, 5, 1, 2, 3]);
      final exactCases = <String, Map<String, Object?>>{
        'TRANSPOSE()': {'error': '#N/A', 'result': null},
        'TRANSPOSE(A1:C2)': {
          'error': null,
          'result': [
            [1, 3, 5],
            [2, 4, 6],
          ],
        },
        'TRANSPOSE(A3:C3)': {
          'error': null,
          'result': [
            [1],
            [2],
            [3],
          ],
        },
        'TDIST()': {'error': '#VALUE!', 'result': null},
        'TDIST(1)': {'error': '#VALUE!', 'result': null},
        'T.DIST.2T()': {'error': '#N/A', 'result': null},
        'T.DIST.2T(1)': {'error': '#N/A', 'result': null},
        'T.DIST.RT()': {'error': '#N/A', 'result': null},
        'T.DIST.RT(1)': {'error': '#N/A', 'result': null},
        'TINV()': {'error': '#VALUE!', 'result': null},
        'TINV(0.1)': {'error': '#VALUE!', 'result': null},
        'T.INV.2T()': {'error': '#VALUE!', 'result': null},
        'T.INV.2T(0.1)': {'error': '#VALUE!', 'result': null},
        'TREND(trendY, trendX, trendNewX)': {
          'error': null,
          'result': [11, 17],
        },
        'TREND(trendY, trendX, "dwe")': {'error': '#VALUE!', 'result': null},
        'TRIMMEAN(trimBadData, 0.2)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'TDIST(1, 3)': 0.2067483346226397,
        'TDIST(1, 3, TRUE)': 0.8044988904727264,
        'T.DIST(1, 3, TRUE)': 0.8044988904727264,
        'T.DIST.2T(1, 6)': 0.3559176837495821,
        'T.DIST.RT(1, 6)': 0.17795884187479105,
        'TINV(0.1, 6)': -1.4397557472652736,
        'T.INV(0.1, 6)': -1.4397557472652736,
        'T.INV.2T(0.1, 6)': 1.9431802743487372,
        'TRIMMEAN(trimData, 0.2)': 3.777777777777,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(trendParser.parse('TREND(foo, bar, baz)'), {
        'error': null,
        'result': [11, 17],
      });
      expect(trendParser.parse('TREND(foo, bar, "dwe")'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(trimMeanParser.parse('TRIMMEAN(bar, 0.2)'), {
        'error': '#VALUE!',
        'result': null,
      });
      final trimMeanResult = trimMeanParser.parse('TRIMMEAN(foo, 0.2)');
      expect(trimMeanResult['error'], isNull);
      expect(trimMeanResult['result'], closeTo(3.777777777777, 5e-8));
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream statistical variance weibull fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'VARP()': {'error': '#NUM!', 'result': null},
        'VARP(1)': {'error': null, 'result': 0},
        'VARS()': {'error': null, 'result': -0.0},
        'VARA()': {'error': null, 'result': -0.0},
        'VARPA()': {'error': '#NUM!', 'result': null},
        'VARPA(1)': {'error': null, 'result': 0},
        'WEIBULLDIST()': {'error': '#VALUE!', 'result': null},
        'WEIBULLDIST(1)': {'error': '#VALUE!', 'result': null},
        'WEIBULLDIST(1, 2)': {'error': '#VALUE!', 'result': null},
      };
      final nanCases = <String>['VARS(1)', 'VARA(1)'];
      final closeCases = <String, num>{
        'VARP(1, 2)': 0.25,
        'VARP(1, 2, 3)': 0.6666666666,
        'VARP(1, 2, 3, 4)': 1.25,
        'VAR.P(1, 2, 3, 4)': 1.25,
        'VARS(1, 2)': 0.5,
        'VARS(1, 2, 3)': 1,
        'VARS(1, 2, 3, 4)': 1.6666666666666,
        'VAR.S(1, 2, 3, 4)': 1.6666666666666,
        'VAR.S(1, 2, 3, 4, TRUE, "foo")': 1.66666666666,
        'VARA(1, 2)': 0.5,
        'VARA(1, 2, 3)': 1,
        'VARA(1, 2, 3, 4)': 1.666666666666,
        'VARA(1, 2, 3, 4, TRUE, "foo")': 2.166666666666,
        'VARPA(1, 2)': 0.25,
        'VARPA(1, 2, 3)': 0.6666666666666,
        'VARPA(1, 2, 3, 4)': 1.25,
        'VARPA(1, 2, 3, 4, TRUE, "foo")': 1.80555555555,
        'WEIBULLDIST(1, 2, 3)': 0.1988531815143044,
        'WEIBULLDIST(1, 2, 3, TRUE)': 0.10516068318563021,
        'WEIBULL.DIST(1, 2, 3, TRUE)': 0.10516068318563021,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final formula in nanCases) {
        final result = parser.parse(formula);
        expect(result['error'], isNull, reason: formula);
        expect(result['result'], 'NaN', reason: formula);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream lookup-reference MATCH fixtures', () {
      final parser = Parser()
        ..setVariable('foo', [0, 1, 2, 3, 4, 100, 7])
        ..setVariable('bar', ['jima', 'jimb', 'jimc', 'bernie']);

      expect(parser.parse('MATCH()'), {'error': '#N/A', 'result': null});
      expect(parser.parse('MATCH(1)'), {'error': '#N/A', 'result': null});
      expect(parser.parse('MATCH(1, foo)'), {'error': null, 'result': 2.0});
      expect(parser.parse('MATCH(4, foo, 1)'), {'error': null, 'result': 5.0});
      expect(parser.parse('MATCH("jima", bar, 0)'), {
        'error': null,
        'result': 1.0,
      });
      expect(parser.parse('MATCH("j?b", bar, 0)'), {
        'error': '#N/A',
        'result': null,
      });
      expect(parser.parse('MATCH("jimc", bar, 0)'), {
        'error': null,
        'result': 3.0,
      });
    });

    test('parses upstream miscellaneous formula fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'B3') {
            done([
              [
                1,
                2,
                [3],
                [4, 5],
              ],
            ]);
          }
        })
        ..on('callCellValue', (
          Map<String, Object?> cell,
          ParserEventDone done,
        ) {
          if (cell['label'] == 'A1') {
            done({
              'name': {'firstName': 'Jim'},
            });
          }
        });

      expect(parser.parse('UNIQUE()'), {'error': null, 'result': []});
      expect(parser.parse('UNIQUE(1, 2, 3, 4, 4, 4, 4, 3)'), {
        'error': null,
        'result': [1, 2, 3, 4],
      });
      expect(parser.parse('UNIQUE("foo", "bar", "foo")'), {
        'error': null,
        'result': ['foo', 'bar'],
      });
      expect(parser.parse('ARGS2ARRAY()'), {'error': null, 'result': []});
      expect(parser.parse('ARGS2ARRAY(1, 4, 4, 3)'), {
        'error': null,
        'result': [1, 4, 4, 3],
      });
      expect(parser.parse('ARGS2ARRAY("foo", "bar", "foo")'), {
        'error': null,
        'result': ['foo', 'bar', 'foo'],
      });
      expect(parser.parse('FLATTEN(A1:B3)'), {
        'error': null,
        'result': [1, 2, 3, 4, 5],
      });
      expect(parser.parse('JOIN(A1:B3)'), {
        'error': null,
        'result': '1,2,3,4,5',
      });
      expect(parser.parse('NUMBERS()'), {'error': null, 'result': []});
      expect(parser.parse('NUMBERS(1, "4", "4", 3)'), {
        'error': null,
        'result': [1, 3],
      });
      expect(parser.parse('NUMBERS("foo", 2, "bar", "foo")'), {
        'error': null,
        'result': [2],
      });
      expect(parser.parse('REFERENCE(A1, "name.firstName")'), {
        'error': null,
        'result': 'Jim',
      });
    });

    test('parses upstream logical formula fixtures', () {
      final parser = Parser();

      expect(parser.parse('AND()'), {'error': null, 'result': true});
      expect(parser.parse('AND(TRUE, TRUE, FALSE)'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('AND(TRUE, TRUE, TRUE)'), {
        'error': null,
        'result': true,
      });
      expect(parser.parse('CHOOSE()'), {'error': '#N/A', 'result': null});
      expect(parser.parse('CHOOSE(1, "foo", "bar", "baz")'), {
        'error': null,
        'result': 'foo',
      });
      expect(parser.parse('CHOOSE(3, "foo", "bar", "baz")'), {
        'error': null,
        'result': 'baz',
      });
      expect(parser.parse('CHOOSE(4, "foo", "bar", "baz")'), {
        'error': '#VALUE!',
        'result': null,
      });
      expect(parser.parse('FALSE()'), {'error': null, 'result': false});
      expect(parser.parse('IF()'), {'error': null, 'result': true});
      expect(parser.parse('IF(TRUE, 1, 2)'), {'error': null, 'result': 1});
      expect(parser.parse('IF(FALSE, 1, 2)'), {'error': null, 'result': 2});
      expect(parser.parse('NOT()'), {'error': null, 'result': true});
      expect(parser.parse('NOT(TRUE)'), {'error': null, 'result': false});
      expect(parser.parse('NOT(FALSE)'), {'error': null, 'result': true});
      expect(parser.parse('NOT(0)'), {'error': null, 'result': true});
      expect(parser.parse('NOT(1)'), {'error': null, 'result': false});
      expect(parser.parse('OR()'), {'error': null, 'result': false});
      expect(parser.parse('OR(TRUE, TRUE, TRUE)'), {
        'error': null,
        'result': true,
      });
      expect(parser.parse('OR(TRUE, FALSE, FALSE)'), {
        'error': null,
        'result': true,
      });
      expect(parser.parse('OR(FALSE, FALSE, FALSE)'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('TRUE()'), {'error': null, 'result': true});
      expect(parser.parse('XOR()'), {'error': null, 'result': false});
      expect(parser.parse('XOR(TRUE, TRUE)'), {'error': null, 'result': false});
      expect(parser.parse('XOR(TRUE, FALSE)'), {'error': null, 'result': true});
      expect(parser.parse('XOR(FALSE, TRUE)'), {'error': null, 'result': true});
      expect(parser.parse('XOR(FALSE, FALSE)'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('SWITCH()'), {'error': '#VALUE!', 'result': null});
      expect(parser.parse('SWITCH(7, "foo")'), {
        'error': null,
        'result': 'foo',
      });
      expect(parser.parse('SWITCH(7, 9, "foo", 7, "bar")'), {
        'error': null,
        'result': 'bar',
      });
      expect(parser.parse('SWITCH(10, 9, "foo", 7, "bar")'), {
        'error': '#N/A',
        'result': null,
      });
    });

    test('parses upstream information formula fixtures', () {
      final parser = Parser();

      expect(parser.parse('ISBINARY()'), {'error': null, 'result': false});
      expect(parser.parse('ISBINARY(1)'), {'error': null, 'result': true});
      expect(parser.parse('ISBINARY(0)'), {'error': null, 'result': true});
      expect(parser.parse('ISBINARY("1010")'), {'error': null, 'result': true});
      expect(parser.parse('ISBLANK(NULL)'), {'error': null, 'result': true});
      expect(parser.parse('ISBLANK(FALSE)'), {'error': null, 'result': false});
      expect(parser.parse('ISBLANK(0)'), {'error': null, 'result': false});
      expect(parser.parse('ISEVEN(1)'), {'error': null, 'result': false});
      expect(parser.parse('ISEVEN(2)'), {'error': null, 'result': true});
      expect(parser.parse('ISEVEN(2.5)'), {'error': null, 'result': true});
      expect(parser.parse('ISLOGICAL(1)'), {'error': null, 'result': false});
      expect(parser.parse('ISLOGICAL(TRUE)'), {'error': null, 'result': true});
      expect(parser.parse('ISLOGICAL(FALSE)'), {'error': null, 'result': true});
      expect(parser.parse('ISLOGICAL(NULL)'), {'error': null, 'result': false});
      expect(parser.parse('ISNONTEXT()'), {'error': null, 'result': true});
      expect(parser.parse('ISNONTEXT(1)'), {'error': null, 'result': true});
      expect(parser.parse('ISNONTEXT(TRUE)'), {'error': null, 'result': true});
      expect(parser.parse('ISNONTEXT("FALSE")'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('ISNONTEXT("foo")'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('ISNUMBER()'), {'error': null, 'result': false});
      expect(parser.parse('ISNUMBER(1)'), {'error': null, 'result': true});
      expect(parser.parse('ISNUMBER(0.142342)'), {
        'error': null,
        'result': true,
      });
      expect(parser.parse('ISNUMBER(TRUE)'), {'error': null, 'result': false});
      expect(parser.parse('ISNUMBER("FALSE")'), {
        'error': null,
        'result': false,
      });
      expect(parser.parse('ISNUMBER("foo")'), {'error': null, 'result': false});
      expect(parser.parse('ISODD(1)'), {'error': null, 'result': true});
      expect(parser.parse('ISODD(2)'), {'error': null, 'result': false});
      expect(parser.parse('ISODD(2.5)'), {'error': null, 'result': false});
      expect(parser.parse('ISTEXT()'), {'error': null, 'result': false});
      expect(parser.parse('ISTEXT(1)'), {'error': null, 'result': false});
      expect(parser.parse('ISTEXT(TRUE)'), {'error': null, 'result': false});
      expect(parser.parse('ISTEXT("FALSE")'), {'error': null, 'result': true});
      expect(parser.parse('ISTEXT("foo")'), {'error': null, 'result': true});
    });

    test('parses upstream deterministic date-time formula fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'DATE()': {'error': '#VALUE!', 'result': null},
        'DATEVALUE()': {'error': '#VALUE!', 'result': null},
        'DATEVALUE("1/1/1900")': {'error': null, 'result': 1},
        'DATEVALUE("1/1/2000")': {'error': null, 'result': 36526},
        'DAY()': {'error': '#VALUE!', 'result': null},
        'DAY(1)': {'error': null, 'result': 1},
        'DAY(2958465)': {'error': null, 'result': 31},
        'DAY("2958465")': {'error': null, 'result': 31},
        'DAYS()': {'error': '#VALUE!', 'result': null},
        'DAYS(1)': {'error': '#VALUE!', 'result': null},
        'DAYS(1, 6)': {'error': null, 'result': -5},
        'DAYS("1/2/2000", "1/10/2001")': {'error': null, 'result': -374},
        'DAYS360()': {'error': '#VALUE!', 'result': null},
        'DAYS360(1)': {'error': '#VALUE!', 'result': null},
        'DAYS360(1, 6)': {'error': '#VALUE!', 'result': null},
        'DAYS360("1/1/1901", "2/1/1901", TRUE)': {'error': null, 'result': 30},
        'DAYS360("1/1/1901", "12/31/1901", FALSE)': {
          'error': null,
          'result': 360,
        },
        'EDATE()': {'error': '#VALUE!', 'result': null},
        'EDATE(1)': {'error': '#VALUE!', 'result': null},
        'EDATE("1/1/1900", 1)': {'error': null, 'result': 32},
        'EOMONTH()': {'error': '#VALUE!', 'result': null},
        'EOMONTH(1)': {'error': '#VALUE!', 'result': null},
        'EOMONTH("1/1/1900", 1)': {'error': null, 'result': 59},
        'HOUR()': {'error': '#VALUE!', 'result': null},
        'HOUR("1/1/1900 16:33")': {'error': null, 'result': 16},
        'INTERVAL()': {'error': '#VALUE!', 'result': null},
        'INTERVAL(0)': {'error': null, 'result': 'PT'},
        'INTERVAL(1)': {'error': null, 'result': 'PT1S'},
        'INTERVAL(60)': {'error': null, 'result': 'PT1M'},
        'INTERVAL(10000000)': {'error': null, 'result': 'P3M25DT17H46M40S'},
        'ISOWEEKNUM()': {'error': '#VALUE!', 'result': null},
        'ISOWEEKNUM("1/8/1901")': {'error': null, 'result': 2},
        'ISOWEEKNUM("6/6/1902")': {'error': null, 'result': 23},
        'MINUTE()': {'error': '#VALUE!', 'result': null},
        'MINUTE("1/1/1901 1:01")': {'error': null, 'result': 1},
        'MINUTE("1/1/1901 15:36")': {'error': null, 'result': 36},
        'MONTH()': {'error': '#VALUE!', 'result': null},
        'MONTH("2/1/1901")': {'error': null, 'result': 2},
        'MONTH("10/1/1901")': {'error': null, 'result': 10},
        'NETWORKDAYS()': {'error': '#VALUE!', 'result': null},
        'NETWORKDAYS("2/1/1901")': {'error': '#VALUE!', 'result': null},
        'NETWORKDAYS("2013-12-04", "2013-12-05")': {'error': null, 'result': 2},
        'NETWORKDAYS("2013-11-04", "2013-12-05")': {
          'error': null,
          'result': 24,
        },
        'SECOND()': {'error': '#VALUE!', 'result': null},
        'SECOND("2/1/1901 13:33:12")': {'error': null, 'result': 12},
        'TIME()': {'error': '#VALUE!', 'result': null},
        'TIME(0)': {'error': '#VALUE!', 'result': null},
        'TIME(0, 0)': {'error': '#VALUE!', 'result': null},
        'TIME(0, 0, 0)': {'error': null, 'result': 0},
        'TIME(24, 0, 0)': {'error': null, 'result': 1},
        'TIMEVALUE()': {'error': '#VALUE!', 'result': null},
        'TIMEVALUE("1/1/1900 00:00:00")': {'error': null, 'result': 0},
        'WEEKDAY()': {'error': '#VALUE!', 'result': null},
        'WEEKDAY("1/1/1901")': {'error': null, 'result': 3},
        'WEEKDAY("1/1/1901", 2)': {'error': null, 'result': 2},
        'WEEKNUM()': {'error': '#VALUE!', 'result': null},
        'WEEKNUM("2/1/1900")': {'error': null, 'result': 5},
        'WEEKNUM("2/1/1909", 2)': {'error': null, 'result': 6},
        'WORKDAY()': {'error': '#VALUE!', 'result': null},
        'WORKDAY("1/1/1900")': {'error': '#VALUE!', 'result': null},
        'YEAR()': {'error': '#VALUE!', 'result': null},
        'YEAR("1/1/1904")': {'error': null, 'result': 1904},
        'YEAR("12/12/2001")': {'error': null, 'result': 2001},
        'YEARFRAC()': {'error': '#VALUE!', 'result': null},
        'YEARFRAC("1/1/1904")': {'error': '#VALUE!', 'result': null},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(
        parser.parse('TIME(1, 1, 1)')['result'],
        closeTo(0.04237268518518519, 1e-15),
      );
      final dateResult = parser.parse('DATE(2001, 5, 12)');
      expect(dateResult['error'], isNull);
      expect(dateResult['result'], isA<DateTime>());
      final date = dateResult['result']! as DateTime;
      expect(date.year, 2001);
      expect(date.month, 5);
      expect(date.day, 12);
      expect(
        parser.parse('TIMEVALUE("1/1/1900 23:00:00")')['result'],
        closeTo(0.9583333333333334, 1e-15),
      );
      final beforeNow = DateTime.now();
      final nowResult = parser.parse('NOW()');
      final afterNow = DateTime.now();
      expect(nowResult['error'], isNull);
      expect(nowResult['result'], isA<DateTime>());
      final nowDate = nowResult['result']! as DateTime;
      expect(
        nowDate.isBefore(beforeNow.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        nowDate.isAfter(afterNow.add(const Duration(seconds: 1))),
        isFalse,
      );
      final todayResult = parser.parse('TODAY()');
      expect(todayResult['error'], isNull);
      expect(todayResult['result'], isA<DateTime>());
      expect((todayResult['result']! as DateTime).day, DateTime.now().day);
      final workdayResult = parser.parse('WORKDAY("1/1/1900", 1)');
      expect(workdayResult['error'], isNull);
      expect(workdayResult['result'], isA<DateTime>());
      expect((workdayResult['result']! as DateTime).day, 2);
      expect(
        parser.parse('YEARFRAC("1/1/1900", "1/2/1900")')['result'],
        closeTo(0.002777777777777778, 1e-15),
      );
    });

    test('parses upstream deterministic text and formatting fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'CHAR()': {'error': '#VALUE!', 'result': null},
        'CHAR(33)': {'error': null, 'result': '!'},
        'CLEAN()': {'error': null, 'result': ''},
        'CLEAN(CHAR(9)&"Monthly report"&CHAR(10))': {
          'error': null,
          'result': 'Monthly report',
        },
        'CODE()': {'error': '#N/A', 'result': null},
        'CODE("a")': {'error': null, 'result': 97},
        'CONCATENATE()': {'error': null, 'result': ''},
        'CONCATENATE("a")': {'error': null, 'result': 'a'},
        'CONCATENATE("a", 1)': {'error': null, 'result': 'a1'},
        'CONCATENATE("a", 1, TRUE)': {'error': null, 'result': 'a1TRUE'},
        'EXACT()': {'error': '#N/A', 'result': null},
        'EXACT(1100)': {'error': '#N/A', 'result': null},
        'EXACT(1100, -2)': {'error': null, 'result': false},
        'EXACT(1100, 1100)': {'error': null, 'result': true},
        'EXACT(1100, "1100")': {'error': null, 'result': false},
        'DOLLAR()': {'error': '#VALUE!', 'result': null},
        'DOLLAR(1100)': {'error': null, 'result': r'$1,100.00'},
        'DOLLAR(1100, -2)': {'error': null, 'result': r'$1,100'},
        'FIND()': {'error': '#N/A', 'result': null},
        'FIND("o")': {'error': '#N/A', 'result': null},
        'FIND("o", "FooBar")': {'error': null, 'result': 2},
        'FIND("O", "FooBar")': {'error': null, 'result': 0},
        'FIXED()': {'error': '#VALUE!', 'result': null},
        'FIXED(12345.11, -1)': {'error': null, 'result': '12,350'},
        'FIXED(12345.11, 0)': {'error': null, 'result': '12,345'},
        'FIXED(12345.11, 0, TRUE)': {'error': null, 'result': '12345'},
        'FIXED(12345.11, 4, TRUE)': {'error': null, 'result': '12345.1100'},
        'HTML2TEXT()': {'error': null, 'result': ''},
        'HTML2TEXT("Click <a>Link</a>")': {
          'error': null,
          'result': 'Click Link',
        },
        'LEFT()': {'error': '#VALUE!', 'result': null},
        'LEFT("Foo Bar")': {'error': null, 'result': 'F'},
        'LEFT("Foo Bar", 3)': {'error': null, 'result': 'Foo'},
        'LEN()': {'error': '#ERROR!', 'result': null},
        'LEN(TRUE)': {'error': '#VALUE!', 'result': null},
        'LEN(1023)': {'error': '#VALUE!', 'result': null},
        'LEN("Foo Bar")': {'error': null, 'result': 7},
        'LOWER()': {'error': '#VALUE!', 'result': null},
        'LOWER("")': {'error': null, 'result': ''},
        'LOWER("Foo Bar")': {'error': null, 'result': 'foo bar'},
        'MID()': {'error': '#VALUE!', 'result': null},
        'MID("")': {'error': '#VALUE!', 'result': null},
        'MID("Foo Bar", 2)': {'error': '#VALUE!', 'result': null},
        'MID("Foo Bar", 2, 5)': {'error': null, 'result': 'oo Ba'},
        'PROPER()': {'error': '#VALUE!', 'result': null},
        'PROPER("")': {'error': '#VALUE!', 'result': null},
        'PROPER(TRUE)': {'error': null, 'result': 'True'},
        'PROPER(1234)': {'error': null, 'result': '1234'},
        'PROPER("foo bar")': {'error': null, 'result': 'Foo Bar'},
        'REGEXEXTRACT()': {'error': '#N/A', 'result': null},
        'REGEXEXTRACT("extract foo bar", "(foo)")': {
          'error': null,
          'result': 'foo',
        },
        'REGEXEXTRACT("pressure 12.21bar", "([0-9]+.[0-9]+)")': {
          'error': null,
          'result': '12.21',
        },
        'REGEXREPLACE()': {'error': '#N/A', 'result': null},
        'REGEXREPLACE("extract foo bar", "(foo)", "baz")': {
          'error': null,
          'result': 'extract baz bar',
        },
        'REGEXREPLACE("pressure 12.21bar", "([0-9]+.[0-9]+)", "43.1")': {
          'error': null,
          'result': 'pressure 43.1bar',
        },
        'REGEXMATCH()': {'error': '#N/A', 'result': null},
        'REGEXMATCH("pressure 12.21bar", "([0-9]+.[0-9]+)")': {
          'error': null,
          'result': true,
        },
        'REPLACE()': {'error': '#VALUE!', 'result': null},
        'REPLACE("foo bar")': {'error': '#VALUE!', 'result': null},
        'REPLACE("foo bar", 2)': {'error': '#VALUE!', 'result': null},
        'REPLACE("foo bar", 2, 5)': {'error': '#VALUE!', 'result': null},
        'REPLACE("foo bar", 2, 5, "*")': {'error': null, 'result': 'f*r'},
        'REPT()': {'error': '#VALUE!', 'result': null},
        'REPT("foo ")': {'error': '#VALUE!', 'result': null},
        'REPT("foo ", 5)': {'error': null, 'result': 'foo foo foo foo foo '},
        'RIGHT()': {'error': '#N/A', 'result': null},
        'RIGHT("foo bar")': {'error': null, 'result': 'r'},
        'RIGHT("foo bar", 4)': {'error': null, 'result': ' bar'},
        'SEARCH()': {'error': '#VALUE!', 'result': null},
        'SEARCH("bar")': {'error': '#VALUE!', 'result': null},
        'SEARCH("bar", "foo bar")': {'error': null, 'result': 5},
        'SPLIT()': {'error': '#ERROR!', 'result': null},
        'SPLIT("foo bar baz")': {
          'error': null,
          'result': ['foo bar baz'],
        },
        'SPLIT("foo bar baz", " ")': {
          'error': null,
          'result': ['foo', 'bar', 'baz'],
        },
        'SUBSTITUTE()': {'error': '#N/A', 'result': null},
        'SUBSTITUTE("foo bar baz")': {'error': '#N/A', 'result': null},
        'SUBSTITUTE("foo bar baz", "a", "A")': {
          'error': null,
          'result': 'foo bAr bAz',
        },
        'T()': {'error': null, 'result': ''},
        'T(TRUE)': {'error': null, 'result': ''},
        'T(9.887)': {'error': null, 'result': ''},
        'T("foo bar baz")': {'error': null, 'result': 'foo bar baz'},
        'TEXT()': {'error': '#N/A', 'result': null},
        'TEXT(1234.99)': {'error': null, 'result': '1,235'},
        'TEXT(1234.99, "####.#")': {'error': null, 'result': '1235.0'},
        'TEXT(1234.99, "####.###")': {'error': null, 'result': '1234.990'},
        'TRIM()': {'error': '#VALUE!', 'result': null},
        'TRIM("")': {'error': null, 'result': ''},
        'TRIM("     ")': {'error': null, 'result': ''},
        'TRIM("   foo  ")': {'error': null, 'result': 'foo'},
        'UNICHAR()': {'error': '#VALUE!', 'result': null},
        'UNICHAR(33)': {'error': null, 'result': '!'},
        'UNICODE()': {'error': '#N/A', 'result': null},
        'UNICODE("!")': {'error': null, 'result': 33},
        'UPPER()': {'error': '#VALUE!', 'result': null},
        'UPPER("foo Bar")': {'error': null, 'result': 'FOO BAR'},
        'VALUE()': {'error': '#VALUE!', 'result': null},
        r'VALUE("$1,000")': {'error': null, 'result': 1000},
        'VALUE("01:00:00")': {'error': null, 'result': 3600},
        'VALUE("foo Bar")': {'error': null, 'result': 0},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream engineering base and bit fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'BIN2DEC()': {'error': '#NUM!', 'result': null},
        'BIN2DEC(1010)': {'error': null, 'result': 10},
        'BIN2DEC(0)': {'error': null, 'result': 0},
        'BIN2DEC(1)': {'error': null, 'result': 1},
        'BIN2HEX()': {'error': '#NUM!', 'result': null},
        'BIN2HEX(1010)': {'error': null, 'result': 'a'},
        'BIN2HEX(1010, 4)': {'error': null, 'result': '000a'},
        'BIN2HEX(0, 3)': {'error': null, 'result': '000'},
        'BIN2HEX(1111)': {'error': null, 'result': 'f'},
        'BIN2OCT()': {'error': '#NUM!', 'result': null},
        'BIN2OCT(1010)': {'error': null, 'result': '12'},
        'BIN2OCT(1010, 4)': {'error': null, 'result': '0012'},
        'BIN2OCT(0, 3)': {'error': null, 'result': '000'},
        'BIN2OCT(111)': {'error': null, 'result': '7'},
        'BITAND()': {'error': '#VALUE!', 'result': null},
        'BITAND(2)': {'error': '#VALUE!', 'result': null},
        'BITAND(2, 4)': {'error': null, 'result': 0},
        'BITAND(1, 5)': {'error': null, 'result': 1},
        'BITLSHIFT()': {'error': '#VALUE!', 'result': null},
        'BITLSHIFT(2)': {'error': '#VALUE!', 'result': null},
        'BITLSHIFT(2, 4)': {'error': null, 'result': 32},
        'BITLSHIFT(1, 5)': {'error': null, 'result': 32},
        'BITOR()': {'error': '#VALUE!', 'result': null},
        'BITOR(2)': {'error': '#VALUE!', 'result': null},
        'BITOR(2, 4)': {'error': null, 'result': 6},
        'BITOR(1, 5)': {'error': null, 'result': 5},
        'BITRSHIFT()': {'error': '#VALUE!', 'result': null},
        'BITRSHIFT(2)': {'error': '#VALUE!', 'result': null},
        'BITRSHIFT(4, 2)': {'error': null, 'result': 1},
        'BITRSHIFT(1, 5)': {'error': null, 'result': 0},
        'BITXOR()': {'error': '#VALUE!', 'result': null},
        'BITXOR(2)': {'error': '#VALUE!', 'result': null},
        'BITXOR(4, 2)': {'error': null, 'result': 6},
        'BITXOR(1, 5)': {'error': null, 'result': 4},
        'DEC2BIN()': {'error': '#VALUE!', 'result': null},
        'DEC2BIN(10)': {'error': null, 'result': '1010'},
        'DEC2BIN(0, 4)': {'error': null, 'result': '0000'},
        'DEC2BIN(1)': {'error': null, 'result': '1'},
        'DEC2HEX()': {'error': '#VALUE!', 'result': null},
        'DEC2HEX(100)': {'error': null, 'result': '64'},
        'DEC2HEX(100, 4)': {'error': null, 'result': '0064'},
        'DEC2HEX(0)': {'error': null, 'result': '0'},
        'DEC2HEX(1)': {'error': null, 'result': '1'},
        'DEC2OCT()': {'error': '#VALUE!', 'result': null},
        'DEC2OCT(58)': {'error': null, 'result': '72'},
        'DEC2OCT(58, 4)': {'error': null, 'result': '0072'},
        'DEC2OCT(0)': {'error': null, 'result': '0'},
        'DEC2OCT(1)': {'error': null, 'result': '1'},
        'HEX2BIN()': {'error': '#NUM!', 'result': null},
        'HEX2BIN("FA")': {'error': null, 'result': '11111010'},
        'HEX2BIN("FA", 10)': {'error': null, 'result': '0011111010'},
        'HEX2BIN(200)': {'error': '#NUM!', 'result': null},
        'HEX2DEC()': {'error': '#NUM!', 'result': null},
        'HEX2DEC("FA")': {'error': null, 'result': 250},
        'HEX2DEC(200)': {'error': null, 'result': 512},
        'HEX2OCT()': {'error': '#NUM!', 'result': null},
        'HEX2OCT("FA")': {'error': null, 'result': '372'},
        'HEX2OCT("FA", 6)': {'error': null, 'result': '000372'},
        'HEX2OCT(200)': {'error': null, 'result': '1000'},
        'OCT2BIN()': {'error': '#NUM!', 'result': null},
        'OCT2BIN(3)': {'error': null, 'result': '11'},
        'OCT2BIN(3, 4)': {'error': null, 'result': '0011'},
        'OCT2DEC()': {'error': '#NUM!', 'result': null},
        'OCT2DEC(3)': {'error': null, 'result': 3},
        'OCT2DEC(33)': {'error': null, 'result': 27},
        'OCT2HEX()': {'error': '#NUM!', 'result': null},
        'OCT2HEX(3)': {'error': null, 'result': '3'},
        'OCT2HEX(33)': {'error': null, 'result': '1b'},
        'OCT2HEX(33, 3)': {'error': null, 'result': '01b'},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream engineering numeric fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'BESSELI()': {'error': '#VALUE!', 'result': null},
        'BESSELI(1.4)': {'error': '#VALUE!', 'result': null},
        'BESSELJ()': {'error': '#VALUE!', 'result': null},
        'BESSELJ(1.4)': {'error': '#VALUE!', 'result': null},
        'BESSELK()': {'error': '#VALUE!', 'result': null},
        'BESSELK(1.4)': {'error': '#VALUE!', 'result': null},
        'BESSELY()': {'error': '#VALUE!', 'result': null},
        'BESSELY(1.4)': {'error': '#VALUE!', 'result': null},
        'DELTA()': {'error': '#VALUE!', 'result': null},
        'DELTA(58)': {'error': null, 'result': 0},
        'DELTA(58, 4)': {'error': null, 'result': 0},
        'DELTA(58, 58)': {'error': null, 'result': 1},
        'ERF()': {'error': '#VALUE!', 'result': null},
        'ERFC()': {'error': '#VALUE!', 'result': null},
        'GESTEP()': {'error': '#VALUE!', 'result': null},
        'GESTEP(1, 2)': {'error': null, 'result': 0},
        'GESTEP(-1, -2)': {'error': null, 'result': 1},
      };
      final closeCases = <String, num>{
        'BESSELI(1.4, 1)': 0.8860919793963105,
        'BESSELJ(1.4, 1)': 0.5419477138848564,
        'BESSELK(1.4, 1)': 0.32083590550458985,
        'BESSELY(1.4, 1)': -0.47914697411134044,
        'ERF(1)': 0.8427007929497149,
        'ERF(2)': 0.9953222650189527,
        'ERFC(0)': 1,
        'ERFC(1)': 0.1572992070502851,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        expect(
          parser.parse(entry.key)['result'],
          closeTo(entry.value, 1e-12),
          reason: entry.key,
        );
      }
    });

    test('parses upstream engineering complex and convert fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'COMPLEX()': {'error': '#VALUE!', 'result': null},
        'COMPLEX(2, 0)': {'error': null, 'result': '2'},
        'COMPLEX(4, 2)': {'error': null, 'result': '4+2i'},
        'COMPLEX(1, 5)': {'error': null, 'result': '1+5i'},
        'CONVERT()': {'error': '#VALUE!', 'result': null},
        'CONVERT(1)': {'error': '#ERROR!', 'result': null},
        'CONVERT(2, "km/h", "mi")': {'error': '#N/A', 'result': null},
      };
      final closeCases = <String, num>{
        'CONVERT(2, "lbm", "kg")': 0.90718474,
        'CONVERT(100, "km", "mi")': 62.13711922373339,
        'CONVERT(100, "km", "m")': 100000,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream engineering complex basics fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'IMABS()': {'error': '#VALUE!', 'result': null},
        'IMABS("5+12i")': {'error': null, 'result': 13},
        'IMAGINARY()': {'error': '#VALUE!', 'result': null},
        'IMAGINARY("3+4i")': {'error': null, 'result': 4},
        'IMAGINARY("+i")': {'error': null, 'result': '+1'},
        'IMARGUMENT()': {'error': '#VALUE!', 'result': null},
        'IMARGUMENT(1)': {'error': '#ERROR!', 'result': null},
        'IMARGUMENT(0)': {'error': '#DIV/0!', 'result': null},
        'IMCONJUGATE()': {'error': '#VALUE!', 'result': null},
        'IMCONJUGATE(1)': {'error': '#ERROR!', 'result': null},
        'IMCONJUGATE("3+4i")': {'error': null, 'result': '3-4i'},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      expect(
        parser.parse('IMARGUMENT("3+4i")')['result'],
        closeTo(0.9272952180016122, 5e-8),
        reason: 'IMARGUMENT("3+4i")',
      );
    });

    test('parses upstream engineering complex arithmetic fixtures', () {
      final parser = Parser();
      final cases = <String, Map<String, Object?>>{
        'IMDIV()': {'error': '#VALUE!', 'result': null},
        'IMDIV("3+4i")': {'error': '#VALUE!', 'result': null},
        'IMDIV("3+4i", "2+2i")': {'error': null, 'result': '1.75+0.25i'},
        'IMEXP()': {'error': '#VALUE!', 'result': null},
        'IMLN()': {'error': '#VALUE!', 'result': null},
        'IMLOG10()': {'error': '#VALUE!', 'result': null},
        'IMLOG2()': {'error': '#VALUE!', 'result': null},
        'IMPOWER()': {'error': '#VALUE!', 'result': null},
        'IMPOWER("3+4i")': {'error': '#VALUE!', 'result': null},
        'IMPRODUCT()': {'error': '#VALUE!', 'result': null},
        'IMPRODUCT("3+4i")': {'error': null, 'result': '3+4i'},
        'IMPRODUCT("3+4i", "1+2i")': {'error': null, 'result': '-5+10i'},
        'IMREAL()': {'error': '#VALUE!', 'result': null},
        'IMREAL("3+4i")': {'error': null, 'result': 3},
        'IMSQRT()': {'error': '#VALUE!', 'result': null},
        'IMSQRT("3+4i")': {'error': null, 'result': '2+i'},
        'IMSUB()': {'error': '#VALUE!', 'result': null},
        'IMSUB("3+4i")': {'error': '#VALUE!', 'result': null},
        'IMSUB("3+4i", "2+3i")': {'error': null, 'result': '1+i'},
        'IMSUM()': {'error': '#VALUE!', 'result': null},
        'IMSUM("3+4i")': {'error': null, 'result': '3+4i'},
        'IMSUM("3+4i", "2+3i")': {'error': null, 'result': '5+7i'},
      };
      final complexCases = <String, (double, double)>{
        'IMEXP("3+4i")': (-13.128783081462158, -15.200784463067954),
        'IMLN("3+4i")': (1.6094379124341003, 0.9272952180016122),
        'IMLOG10("3+4i")': (0.6989700043360187, 0.4027191962733731),
        'IMLOG2("3+4i")': (2.321928094887362, 1.3378042124509761),
        'IMPOWER("3+4i", 3)': (-117, 44.000000000000036),
      };

      for (final entry in cases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in complexCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        final parts = _parseComplexResult(result['result'] as String);
        expect(parts.$1, closeTo(entry.value.$1, 5e-8), reason: entry.key);
        expect(parts.$2, closeTo(entry.value.$2, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream engineering complex trig fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'IMCOS()': {'error': '#VALUE!', 'result': null},
        'IMCOSH()': {'error': '#VALUE!', 'result': null},
        'IMCOT()': {'error': '#VALUE!', 'result': null},
        'IMCSC()': {'error': '#NUM!', 'result': null},
        'IMCSCH()': {'error': '#NUM!', 'result': null},
        'IMSEC()': {'error': '#VALUE!', 'result': null},
        'IMSECH()': {'error': '#VALUE!', 'result': null},
        'IMSIN()': {'error': '#VALUE!', 'result': null},
        'IMSINH()': {'error': '#VALUE!', 'result': null},
        'IMTAN()': {'error': '#VALUE!', 'result': null},
      };
      final complexCases = <String, (double, double)>{
        'IMCOS("3+4i")': (-27.03494560307422, -3.8511533348117766),
        'IMCOSH("3+4i")': (-6.580663040551157, -7.581552742746545),
        'IMCOT("3+4i")': (-0.0001875877379836712, -1.0006443924715591),
        'IMCSC("3+4i")': (0.005174473184019398, 0.03627588962862602),
        'IMCSCH("3+4i")': (-0.0648774713706355, 0.0754898329158637),
        'IMSEC("3+4i")': (-0.03625349691586888, 0.005164344607753179),
        'IMSECH("3+4i")': (-0.06529402785794704, 0.07522496030277322),
        'IMSIN("3+4i")': (3.8537380379193764, -27.01681325800393),
        'IMSINH("3+4i")': (-6.5481200409110025, -7.61923172032141),
        'IMTAN("3+4i")': (-0.00018734620462949037, 0.9993559873814729),
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in complexCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        final parts = _parseComplexResult(result['result'] as String);
        expect(parts.$1, closeTo(entry.value.$1, 5e-8), reason: entry.key);
        expect(parts.$2, closeTo(entry.value.$2, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial effective nominal fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'EFFECT()': {'error': '#VALUE!', 'result': null},
        'EFFECT(1.1)': {'error': '#VALUE!', 'result': null},
        'NOMINAL()': {'error': '#VALUE!', 'result': null},
        'NOMINAL(1.1)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'EFFECT(1.1, 4)': 1.6426566406249994,
        'NOMINAL(1.1, 2)': 0.8982753492378879,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial accrued interest fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'ACCRINT()': {'error': '#VALUE!', 'result': null},
        'ACCRINT("2/2/2012")': {'error': '#VALUE!', 'result': null},
        'ACCRINT("2/2/2012", "3/30/2012")': {
          'error': '#VALUE!',
          'result': null,
        },
        'ACCRINT("2/2/2012", "3/30/2012", "12/4/2013")': {
          'error': '#NUM!',
          'result': null,
        },
        'ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1)': {
          'error': '#NUM!',
          'result': null,
        },
        'ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000)': {
          'error': '#NUM!',
          'result': null,
        },
        'ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1)': {
          'error': '#NUM!',
          'result': null,
        },
      };
      final closeCases = <String, num>{
        'ACCRINT("2/2/2012", "3/30/2012", "12/4/2013", 0.1, 1000, 1, 0)':
            183.88888888888889,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial dollar fraction fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'DOLLARDE()': {'error': '#VALUE!', 'result': null},
        'DOLLARDE(1.1)': {'error': '#VALUE!', 'result': null},
        'DOLLARFR()': {'error': '#VALUE!', 'result': null},
        'DOLLARFR(1.1)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'DOLLARDE(1.1, 4)': 1.25,
        'DOLLARFR(1.1, 4)': 1.04,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial future value fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'FV()': {'error': '#VALUE!', 'result': null},
        'FV(1.1, 10)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'FV(1.1, 10, -200)': 303088.7450582,
        'FV(1.1, 10, -200, -500)': 1137082.79396825,
        'FV(1.1, 10, -200, -500, 1)': 1470480.4135322701,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial future value schedule fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C1') {
            done([
              [0.09, 0.1, 0.11],
            ]);
          }
        });

      expect(parser.parse('FVSCHEDULE(100, A1:C1)'), {
        'error': null,
        'result': closeTo(133.08900000000003, 5e-8),
      });
    });

    test('parses upstream financial rate of return range fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C1') {
            done([
              [-75000, 12000, 15000, 18000, 21000, 24000],
            ]);
          }
        });
      final closeCases = <String, num>{
        'IRR(A1:C1)': 0.05715142887178453,
        'MIRR(A1:C1, 0.1, 0.12)': 0.07971710360838036,
      };

      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial number of periods fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'NPER()': {'error': '#VALUE!', 'result': null},
        'NPER(1.1)': {'error': '#VALUE!', 'result': null},
        'NPER(1.1, -2)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'NPER(1.1, -2, -100)': -5.4254604102768305,
        'NPER(1.1, -2, -100, 1000)': 3.081639082679854,
        'NPER(1.1, -2, -100, 1000, 1)': 3.058108732153963,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial net present value fixtures', () {
      final parser = Parser();
      expect(parser.parse('NPV()'), {'error': '#VALUE!', 'result': null});

      final closeCases = <String, num>{
        'NPV(1.1)': 0,
        'NPV(1.1, -2)': -0.9523809523809523,
        'NPV(1.1, -2, -100)': -23.6281179138322,
        'NPV(1.1, -2, -100, 1000)': 84.3515819026023,
        'NPV(1.1, -2, -100, 1000, 1)': 84.4030008072768,
      };

      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial rate fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'RATE()': {'error': '#VALUE!', 'result': null},
        'RATE(24)': {'error': '#VALUE!', 'result': null},
        'RATE(24, -1000)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'RATE(24, -1000, -10000)': -1.2079096886965142,
        'RATE(24, -1000, -10000, 10000)': -0.1,
        'RATE(24, -1000, -10000, 10000, 1)': -0.09090909090909093,
        'RATE(24, -1000, -10000, 10000, 1, 0.1)': -0.09090909090909091,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial payment present value fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'PMT()': {'error': '#VALUE!', 'result': null},
        'PMT(0.1)': {'error': '#VALUE!', 'result': null},
        'PMT(0.1, 200)': {'error': '#VALUE!', 'result': null},
        'PV()': {'error': '#VALUE!', 'result': null},
        'PV(1.1)': {'error': '#VALUE!', 'result': null},
        'PV(1.1, 200)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'PMT(0.1, 200, 400)': -40.00000021063133,
        'PMT(0.1, 200, 400, 500)': -40.00000047392049,
        'PV(1.1, 200, 400)': -363.6363636363636,
        'PV(1.1, 200, 400, 5000)': -363.6363636363636,
        'PV(1.1, 200, 400, 5000, 1)': -763.6363636363636,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial interest principal payment fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'IPMT()': {'error': '#VALUE!', 'result': null},
        'IPMT(0.2, 6)': {'error': '#VALUE!', 'result': null},
        'IPMT(0.2, 6, 24)': {'error': '#VALUE!', 'result': null},
        'PPMT()': {'error': '#VALUE!', 'result': null},
        'PPMT(0.1)': {'error': '#VALUE!', 'result': null},
        'PPMT(0.1, 200)': {'error': '#VALUE!', 'result': null},
        'PPMT(0.1, 200, 400)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'IPMT(0.2, 6, 24, 1000)': -196.20794961065468,
        'IPMT(0.2, 6, 24, 1000, 200)': -195.44953953278565,
        'IPMT(0.2, 6, 24, 1000, 200, 1)': -162.87461627732137,
        'PPMT(0.1, 200, 400, 5000)': 0.000012207031261368684,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial interest paid period fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'ISPMT()': {'error': '#VALUE!', 'result': null},
        'ISPMT(1.1, 2)': {'error': '#VALUE!', 'result': null},
        'ISPMT(1.1, 2, 16)': {'error': '#VALUE!', 'result': null},
        'ISPMT(1.1, 2, 16, 1000)': {'error': null, 'result': -962.5},
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream financial cumulative payment fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'CUMIPMT()': {'error': '#VALUE!', 'result': null},
        'CUMIPMT(0.1/12)': {'error': '#VALUE!', 'result': null},
        'CUMIPMT(0.1/12, 30*12)': {'error': '#VALUE!', 'result': null},
        'CUMIPMT(0.1/12, 30*12, 100000)': {'error': '#NUM!', 'result': null},
        'CUMIPMT(0.1/12, 30*12, 100000, 13)': {
          'error': '#NUM!',
          'result': null,
        },
        'CUMIPMT(0.1/12, 30*12, 100000, 13, 24)': {
          'error': '#NUM!',
          'result': null,
        },
        'CUMPRINC()': {'error': '#VALUE!', 'result': null},
        'CUMPRINC(0.1/12)': {'error': '#VALUE!', 'result': null},
        'CUMPRINC(0.1/12, 30*12)': {'error': '#VALUE!', 'result': null},
        'CUMPRINC(0.1/12, 30*12, 100000)': {'error': '#NUM!', 'result': null},
        'CUMPRINC(0.1/12, 30*12, 100000, 13)': {
          'error': '#NUM!',
          'result': null,
        },
        'CUMPRINC(0.1/12, 30*12, 100000, 13, 24)': {
          'error': '#NUM!',
          'result': null,
        },
      };
      final closeCases = <String, num>{
        'CUMIPMT(0.1/12, 30*12, 100000, 13, 24, 0)': -9916.77251395708,
        'CUMPRINC(0.1/12, 30*12, 100000, 13, 24, 0)': -614.0863271085149,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial duration rate fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'PDURATION()': {'error': '#VALUE!', 'result': null},
        'PDURATION(0.1)': {'error': '#VALUE!', 'result': null},
        'PDURATION(0.1, 200)': {'error': '#VALUE!', 'result': null},
        'RRI()': {'error': '#VALUE!', 'result': null},
        'RRI(8)': {'error': '#VALUE!', 'result': null},
        'RRI(8, 100)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'PDURATION(0.1, 200, 400)': 7.272540897341714,
        'RRI(8, 100, 300)': 0.1472026904398771,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial depreciation fixtures', () {
      final parser = Parser();
      final cases = <String, Map<String, Object?>>{
        'SLN()': {'error': '#VALUE!', 'result': null},
        'SLN(200)': {'error': '#VALUE!', 'result': null},
        'SLN(200, 750)': {'error': '#VALUE!', 'result': null},
        'SLN(200, 750, 10)': {'error': null, 'result': -55},
        'SYD()': {'error': '#VALUE!', 'result': null},
        'SYD(200)': {'error': '#VALUE!', 'result': null},
        'SYD(200, 750)': {'error': '#VALUE!', 'result': null},
        'SYD(200, 750, 10)': {'error': '#VALUE!', 'result': null},
        'SYD(200, 750, 10, 1)': {'error': null, 'result': -100},
      };

      for (final entry in cases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
    });

    test('parses upstream financial declining depreciation fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'DB()': {'error': '#VALUE!', 'result': null},
        'DB(10000)': {'error': '#VALUE!', 'result': null},
        'DB(10000, 1000)': {'error': '#VALUE!', 'result': null},
        'DB(10000, 1000, 6)': {'error': '#VALUE!', 'result': null},
        'DB(10000, 1000, 6, 1)': {'error': null, 'result': 3190},
        'DDB()': {'error': '#VALUE!', 'result': null},
        'DDB(10000)': {'error': '#VALUE!', 'result': null},
        'DDB(10000, 1000)': {'error': '#VALUE!', 'result': null},
        'DDB(10000, 1000, 6)': {'error': '#VALUE!', 'result': null},
      };
      final closeCases = <String, num>{
        'DDB(10000, 1000, 6, 1)': 3333.333333333333,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial treasury bill fixtures', () {
      final parser = Parser();
      final exactCases = <String, Map<String, Object?>>{
        'TBILLEQ()': {'error': '#VALUE!', 'result': null},
        'TBILLEQ("03/31/2008")': {'error': '#VALUE!', 'result': null},
        'TBILLEQ("03/31/2008", "06/01/2008")': {
          'error': '#VALUE!',
          'result': null,
        },
        'TBILLPRICE()': {'error': '#VALUE!', 'result': null},
        'TBILLPRICE("03/31/2008")': {'error': '#VALUE!', 'result': null},
        'TBILLPRICE("03/31/2008", "06/01/2008")': {
          'error': '#VALUE!',
          'result': null,
        },
        'TBILLYIELD()': {'error': '#VALUE!', 'result': null},
        'TBILLYIELD("03/31/2008")': {'error': '#VALUE!', 'result': null},
        'TBILLYIELD("03/31/2008", "06/01/2008")': {
          'error': '#VALUE!',
          'result': null,
        },
      };
      final closeCases = <String, num>{
        'TBILLEQ("03/31/2008", "06/01/2008", 0.09)': 0.09266311246509266,
        'TBILLPRICE("03/31/2008", "06/01/2008", 0.09)': 98.475,
        'TBILLYIELD("03/31/2008", "06/01/2008", 0.09)': 6551.475409836065,
      };

      for (final entry in exactCases.entries) {
        expect(parser.parse(entry.key), entry.value, reason: entry.key);
      }
      for (final entry in closeCases.entries) {
        final result = parser.parse(entry.key);
        expect(result['error'], isNull, reason: entry.key);
        expect(result['result'], closeTo(entry.value, 5e-8), reason: entry.key);
      }
    });

    test('parses upstream financial irregular net present value fixtures', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C1') {
            done([
              [-10000, 2750, 4250, 3250, 2750],
            ]);
          } else if (start['label'] == 'A2' && end['label'] == 'C2') {
            done([
              [
                '01/01/2008',
                '03/01/2008',
                '10/30/2008',
                '02/15/2009',
                '04/01/2009',
              ],
            ]);
          }
        });

      final result = parser.parse('XNPV(0.09, A1:C1, A2:C2)');

      expect(result['error'], isNull);
      expect(result['result'], closeTo(2086.647602031535, 5e-8));
    });

    test('locks implemented XIRR for upstream skipped fixture inputs', () {
      final parser = Parser()
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          if (start['label'] == 'A1' && end['label'] == 'C1') {
            done([
              [-10000, 2750, 4250, 3250, 2750],
            ]);
          } else if (start['label'] == 'A2' && end['label'] == 'C2') {
            done([
              ['01/jan/08', '01/mar/08', '30/oct/08', '15/feb/09', '01/apr/09'],
            ]);
          }
        });

      final result = parser.parse('XIRR(A1:C1, A2:C2, 0.1)');

      expect(result['error'], isNull);
      expect(result['result'], closeTo(0.3733625335188315, 5e-8));
    });

    test('exposes upstream Parser event callbacks', () {
      final parser = Parser();
      Map<String, Object?>? cellCoord;
      Map<String, Object?>? rangeStart;
      Map<String, Object?>? rangeEnd;

      parser
        ..on('callVariable', (String name, ParserEventDone done) {
          if (name == 'EVENT_VAR') {
            done(7);
          }
        })
        ..on('callFunction', (
          String name,
          List<Object?> params,
          ParserEventDone done,
        ) {
          if (name == 'DOUBLE') {
            done((params.single as num) * 2);
          }
        })
        ..on('callCellValue', (
          Map<String, Object?> cell,
          ParserEventDone done,
        ) {
          cellCoord = cell;
          done(55);
        })
        ..on('callRangeValue', (
          Map<String, Object?> start,
          Map<String, Object?> end,
          ParserEventDone done,
        ) {
          rangeStart = start;
          rangeEnd = end;
          done([
            [1, 2],
            [3, 4],
          ]);
        });

      expect(parser.parse('EVENT_VAR'), {'error': null, 'result': 7});
      parser.setVariable('FALLBACK_VAR', 11);
      expect(parser.parse('FALLBACK_VAR'), {'error': null, 'result': 11});
      expect(parser.parse('DOUBLE(3)'), {'error': null, 'result': 6});
      parser.setFunction('FALLBACK_FN', (params) => (params.single as num) + 3);
      expect(parser.parse('FALLBACK_FN(4)'), {'error': null, 'result': 7});
      expect(parser.parse('A1'), {'error': null, 'result': 55});
      expect(cellCoord?['label'], 'A1');
      expect(cellCoord?['row'], {
        'index': 0,
        'isAbsolute': false,
        'label': '1',
      });
      expect(cellCoord?['column'], {
        'index': 0,
        'isAbsolute': false,
        'label': 'A',
      });
      expect(parser.parse(r'$A$1'), {'error': null, 'result': 55});
      expect(cellCoord?['label'], r'$A$1');
      expect(cellCoord?['row'], {'index': 0, 'isAbsolute': true, 'label': '1'});
      expect(cellCoord?['column'], {
        'index': 0,
        'isAbsolute': true,
        'label': 'A',
      });
      expect(parser.parse(r'A$1'), {'error': null, 'result': 55});
      expect(cellCoord?['label'], r'A$1');
      expect(cellCoord?['row'], {'index': 0, 'isAbsolute': true, 'label': '1'});
      expect(cellCoord?['column'], {
        'index': 0,
        'isAbsolute': false,
        'label': 'A',
      });
      expect(parser.parse(r'$A1'), {'error': null, 'result': 55});
      expect(cellCoord?['label'], r'$A1');
      expect(cellCoord?['row'], {
        'index': 0,
        'isAbsolute': false,
        'label': '1',
      });
      expect(cellCoord?['column'], {
        'index': 0,
        'isAbsolute': true,
        'label': 'A',
      });
      expect(parser.parse(r'$a$1'), {'error': null, 'result': 55});
      expect(cellCoord?['label'], r'$A$1');
      expect(parser.parse(r'$A$$$$1'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse(r'A1$'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse('SUM(A1:B2)'), {'error': null, 'result': 10});
      expect(rangeStart?['label'], 'A1');
      expect(rangeEnd?['label'], 'B2');
      expect(parser.parse('A1:B2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], 'A1');
      expect(rangeEnd?['label'], 'B2');
      expect(parser.parse('a1:b2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], 'A1');
      expect(rangeEnd?['label'], 'B2');
      expect(parser.parse(r'$A$1:B2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], r'$A$1');
      expect(rangeStart?['row'], {
        'index': 0,
        'isAbsolute': true,
        'label': '1',
      });
      expect(rangeStart?['column'], {
        'index': 0,
        'isAbsolute': true,
        'label': 'A',
      });
      expect(rangeEnd?['label'], 'B2');
      expect(rangeEnd?['row'], {'index': 1, 'isAbsolute': false, 'label': '2'});
      expect(rangeEnd?['column'], {
        'index': 1,
        'isAbsolute': false,
        'label': 'B',
      });
      expect(parser.parse(r'A1:$B$2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], 'A1');
      expect(rangeEnd?['label'], r'$B$2');
      expect(parser.parse(r'a$1:$b2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], r'A$1');
      expect(rangeEnd?['label'], r'$B2');
      expect(parser.parse(r'$A$9:B2'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], r'$A2');
      expect(rangeStart?['row'], {
        'index': 1,
        'isAbsolute': false,
        'label': '2',
      });
      expect(rangeStart?['column'], {
        'index': 0,
        'isAbsolute': true,
        'label': 'A',
      });
      expect(rangeEnd?['label'], r'B$9');
      expect(rangeEnd?['row'], {'index': 8, 'isAbsolute': true, 'label': '9'});
      expect(rangeEnd?['column'], {
        'index': 1,
        'isAbsolute': false,
        'label': 'B',
      });
      expect(parser.parse(r'B$2:A$8'), {
        'error': null,
        'result': [
          [1, 2],
          [3, 4],
        ],
      });
      expect(rangeStart?['label'], r'A$2');
      expect(rangeEnd?['label'], r'B$8');
      expect(parser.parse(r'A1:B2$'), {'error': '#ERROR!', 'result': null});
      expect(parser.parse(r'SUM(A$1:$B2)'), {'error': null, 'result': 10});
      expect(rangeStart?['label'], r'A$1');
      expect(rangeStart?['row'], {
        'index': 0,
        'isAbsolute': true,
        'label': '1',
      });
      expect(rangeStart?['column'], {
        'index': 0,
        'isAbsolute': false,
        'label': 'A',
      });
      expect(rangeEnd?['label'], r'$B2');
      expect(rangeEnd?['row'], {'index': 1, 'isAbsolute': false, 'label': '2'});
      expect(rangeEnd?['column'], {
        'index': 1,
        'isAbsolute': true,
        'label': 'B',
      });

      parser.off('callVariable');
      expect(parser.parse('EVENT_VAR'), {'error': '#NAME?', 'result': null});
    });

    test('evaluates custom functions and stringified array arguments', () {
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
          },
        },
      );

      expect(
        FortuneFormulaEngine.evaluateFormula(sheet, '=SUM(4, ADD_5(1))'),
        10,
      );
      expect(
        FortuneFormulaEngine.evaluateFormula(
          sheet,
          '=GET_LETTER("Some string", 3)',
        ),
        'm',
      );
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=SUM([])'), 0);
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=SUM([1])'), 1);
      expect(FortuneFormulaEngine.evaluateFormula(sheet, '=SUM([1,2,3])'), 6);
    });

    test('evaluates ampersand operator fixture values', () {
      expect(evaluateByOperator('&', [2, 8.8]), '28.8');
      expect(evaluateByOperator('&', ['2', 8.8]), '28.8');
      expect(evaluateByOperator('&', ['2', '-8.8', 6, 0.4]), '2-8.860.4');
      expect(
        evaluateByOperator('&', ['foo', ' ', 'bar', ' baz']),
        'foo bar baz',
      );
    });
  });
}
