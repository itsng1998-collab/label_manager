import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream formula operator replay parity', () {
    test('exposes upstream operator symbol metadata', () {
      expect(SUPPORTED_FORMULAS, hasLength(452));
      expect(SUPPORTED_FORMULAS.take(5), <String>[
        'BETADIST',
        'BETAINV',
        'BINOMDIST',
        'ISOCEILING',
        'CEILING',
      ]);
      expect(SUPPORTED_FORMULAS.skip(SUPPORTED_FORMULAS.length - 5), <String>[
        'ARGS2ARRAY',
        'REFERENCE',
        'JOIN',
        'NUMBERS',
        'utils',
      ]);

      final expectedSymbols = <String, Object>{
        '+': '+',
        '&': '&',
        '/': '/',
        '=': '=',
        'SUM': 'SUM',
        '>': '>',
        '>=': '>=',
        '<': '<',
        '<=': '<=',
        '-': '-',
        '*': '*',
        '<>': '<>',
        '^': '^',
      };

      for (final entry in expectedSymbols.entries) {
        expect(getOperation(entry.key), isA<FortuneFormulaOperator>());
        expect(getOperation(entry.key)?.symbol, entry.value, reason: entry.key);
      }
      expect(getOperation('sum')?.symbol, 'SUM');
      expect(getOperation('SUM')?.isFactory, isFalse);
      expect(formulaFunctionOperator.isFactory, isTrue);
      expect(formulaFunctionOperator.symbol, same(SUPPORTED_FORMULAS));
    });

    test('registers custom operators and rejects unknown operators', () {
      registerOperation("foo", (params) {
        if (params.every((value) => value is num)) {
          return params.cast<num>().reduce((a, b) => a + b);
        }
        return params.map((value) => '$value').join();
      });
      registerOperation('foo_replay', (params) {
        if (params.every((value) => value is num)) {
          return params.cast<num>().reduce((a, b) => a + b);
        }
        return params.map((value) => '$value').join();
      });

      expect(evaluateByOperator("foo", [2, 8.8]), 10.8);
      expect(evaluateByOperator("foo", ["2", "8.8"]), '28.8');
      expect(evaluateByOperator('foo_replay', [2, 8.8]), 10.8);
      expect(evaluateByOperator('foo_replay', ['2', '8.8']), '28.8');
      expect(() => evaluateByOperator("bar", [2, 8.8]), throwsStateError);
      expect(() => evaluateByOperator("baz"), throwsStateError);
      expect(() => evaluateByOperator('bar', [2, 8.8]), throwsStateError);
      expect(() => evaluateByOperator('baz'), throwsStateError);
    });

    test('accepts upstream evaluate-by-operator dispatcher operators', () {
      expect(() => evaluateByOperator("+", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("&", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("/", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("=", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("SUM", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator(">", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator(">=", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("<", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("<=", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("-", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("*", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("<>", [2, 8.8]), returnsNormally);
      expect(() => evaluateByOperator("^", [2, 2]), returnsNormally);
    });

    test('evaluates arithmetic operator fixtures', () {
      expect(evaluateByOperator('+', [2, 8.8]), 10.8);
      expect(evaluateByOperator('+', ['2', 8.8]), 10.8);
      expect(evaluateByOperator('+', ['2', '8.8']), 10.8);
      expect(
        evaluateByOperator('+', ['2', '-8.8', 6, 0.4]),
        closeTo(-0.4000000000000007, 1e-12),
      );
      expect(
        () => evaluateByOperator('+', ['foo', ' ', 'bar', ' baz']),
        throwsStateError,
      );
      expect(() => evaluateByOperator('+', ['foo', 2]), throwsStateError);

      expect(
        evaluateByOperator('-', [2, 8.8]),
        closeTo(-6.800000000000001, 1e-12),
      );
      expect(
        evaluateByOperator('-', ['2', 8.8]),
        closeTo(-6.800000000000001, 1e-12),
      );
      expect(
        evaluateByOperator('-', ['2', '8.8']),
        closeTo(-6.800000000000001, 1e-12),
      );
      expect(evaluateByOperator('-', ['2', '-8.8', 6, 0.4]), 4.4);
      expect(
        () => evaluateByOperator('-', ['foo', ' ', 'bar', ' baz']),
        throwsStateError,
      );
      expect(() => evaluateByOperator('-', ['foo', 2]), throwsStateError);

      expect(evaluateByOperator('*', [2, 8.8]), 17.6);
      expect(evaluateByOperator('*', ['2', 8.8]), 17.6);
      expect(evaluateByOperator('*', ['2', '8.8']), 17.6);
      expect(
        evaluateByOperator('*', ['2', '-8.8', 6, 0.4]),
        closeTo(-42.24000000000001, 1e-12),
      );
      expect(
        () => evaluateByOperator('*', ['foo', ' ', 'bar', ' baz']),
        throwsStateError,
      );
      expect(() => evaluateByOperator('*', ['foo', 2]), throwsStateError);

      expect(evaluateByOperator('/', [2, 8.8]), 0.22727272727272727);
      expect(evaluateByOperator('/', ['2', 8.8]), 0.22727272727272727);
      expect(
        evaluateByOperator('/', ['2', '-8.8', 6, 0.4]),
        closeTo(-0.0946969696969697, 1e-12),
      );
      expect(evaluateByOperator('/', ['foo', ' ', 'bar', ' baz']), ERROR_VALUE);
      expect(evaluateByOperator('/', [0, 1]), 0);
      expect(evaluateByOperator('/', [1, 0]), ERROR_DIV_ZERO);
      expect(evaluateByOperator('SUM', [2, 8.8]), 10.8);
      expect(evaluateByOperator('SUM'), 0);

      expect(evaluateByOperator('&', [2, 8.8]), '28.8');
      expect(evaluateByOperator('&', ['2', 8.8]), '28.8');
      expect(evaluateByOperator('&', ['2', '-8.8', 6, 0.4]), '2-8.860.4');
      expect(
        evaluateByOperator('&', ['foo', ' ', 'bar', ' baz']),
        'foo bar baz',
      );

      expect(evaluateByOperator('^', [2, 8.8]), 445.7218884076158);
      expect(evaluateByOperator('^', ['2', 8.8]), 445.7218884076158);
      expect(evaluateByOperator('^', ['2', '8.8']), 445.7218884076158);
      expect(evaluateByOperator('^', ['2', '8.8', 6, 0.4]), 445.7218884076158);
      expect(
        () => evaluateByOperator('^', ['foo', ' ', 'bar', ' baz']),
        throwsStateError,
      );
      expect(() => evaluateByOperator('^', ['foo', 2]), throwsStateError);
    });

    test('evaluates formula function operator fixtures', () {
      expect(
        () => evaluateByOperator('SUMEE', [8.8, 2, 1, 4]),
        throwsStateError,
      );
      expect(
        () => evaluateByOperator('SUMEE.INT', [8.8, 2, 1, 4]),
        throwsStateError,
      );
      expect(evaluateByOperator('SUM', [8.8, 2, 1, 4]), 15.8);
      expect(evaluateByOperator('Sum', [8.8, 2, 1, 4]), 15.8);
      expect(evaluateByOperator('T', ['#ERROR!']), '#ERROR!');
      expect(
        evaluateByOperator('Rank.eq', [
          2,
          [7, 3.5, 3.5, 1, 2],
        ]),
        4,
      );
    });

    test('evaluates comparison operator fixtures', () {
      expect(evaluateByOperator('=', [2, 8.8]), isFalse);
      expect(evaluateByOperator('=', ['2', 8.8]), isFalse);
      expect(evaluateByOperator('=', [1, '1']), isFalse);
      expect(evaluateByOperator('=', [0, null]), isFalse);
      expect(evaluateByOperator('=', [null, null]), isTrue);
      expect(evaluateByOperator('=', [1, 1]), isTrue);

      expect(evaluateByOperator('<>', [2, 8.8]), isTrue);
      expect(evaluateByOperator('<>', ['2', 8.8]), isTrue);
      expect(evaluateByOperator('<>', [1, '1']), isTrue);
      expect(evaluateByOperator('<>', [0, null]), isTrue);
      expect(evaluateByOperator('<>', [null, null]), isFalse);
      expect(evaluateByOperator('<>', [1, 1]), isFalse);

      expect(evaluateByOperator('>', [2, 8.8]), isFalse);
      expect(evaluateByOperator('>', ['2', 8.8]), isFalse);
      expect(evaluateByOperator('>', [1, '1']), isFalse);
      expect(evaluateByOperator('>', [1, 1]), isFalse);
      expect(evaluateByOperator('>', [0, null]), isFalse);
      expect(evaluateByOperator('>', [2, 1]), isTrue);
      expect(evaluateByOperator('>', [2.2, 2.1]), isTrue);

      expect(evaluateByOperator('>=', [2, 8.8]), isFalse);
      expect(evaluateByOperator('>=', ['2', 8.8]), isFalse);
      expect(evaluateByOperator('>=', [0, null]), isTrue);
      expect(evaluateByOperator('>=', [1, '1']), isTrue);
      expect(evaluateByOperator('>=', [1, 1]), isTrue);
      expect(evaluateByOperator('>=', [2, 1]), isTrue);
      expect(evaluateByOperator('>=', [2.2, 2.1]), isTrue);

      expect(evaluateByOperator('<', [2, 1]), isFalse);
      expect(evaluateByOperator('<', [2.2, 2.1]), isFalse);
      expect(evaluateByOperator('<', [1, '1']), isFalse);
      expect(evaluateByOperator('<', [1, 1]), isFalse);
      expect(evaluateByOperator('<', [2, 8.8]), isTrue);
      expect(evaluateByOperator('<', ['2', 8.8]), isTrue);
      expect(evaluateByOperator('<', [0, null]), isFalse);
      expect(evaluateByOperator('<=', [2, 1]), isFalse);
      expect(evaluateByOperator('<=', [2.2, 2.1]), isFalse);
      expect(evaluateByOperator('<=', [2, 8.8]), isTrue);
      expect(evaluateByOperator('<=', ['2', 8.8]), isTrue);
      expect(evaluateByOperator('<=', [0, null]), isTrue);
      expect(evaluateByOperator('<=', [1, '1']), isTrue);
      expect(evaluateByOperator('<=', [1, 1]), isTrue);
    });
  });
}
