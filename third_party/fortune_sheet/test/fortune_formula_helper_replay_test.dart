import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream formula helper replay parity', () {
    test('extracts and rebuilds cell labels', () {
      expect(extractLabel('A1'), [
        {'index': 0, 'label': '1', 'isAbsolute': false},
        {'index': 0, 'label': 'A', 'isAbsolute': false},
      ]);
      expect(extractLabel('a1'), [
        {'index': 0, 'label': '1', 'isAbsolute': false},
        {'index': 0, 'label': 'A', 'isAbsolute': false},
      ]);
      expect(extractLabel(r'A$1'), [
        {'index': 0, 'label': '1', 'isAbsolute': true},
        {'index': 0, 'label': 'A', 'isAbsolute': false},
      ]);
      expect(extractLabel(r'a$1'), [
        {'index': 0, 'label': '1', 'isAbsolute': true},
        {'index': 0, 'label': 'A', 'isAbsolute': false},
      ]);
      expect(extractLabel(r'$A1'), [
        {'index': 0, 'label': '1', 'isAbsolute': false},
        {'index': 0, 'label': 'A', 'isAbsolute': true},
      ]);
      expect(extractLabel(r'$A$1'), [
        {'index': 0, 'label': '1', 'isAbsolute': true},
        {'index': 0, 'label': 'A', 'isAbsolute': true},
      ]);
      expect(extractLabel(r'$AG199'), [
        {'index': 198, 'label': '199', 'isAbsolute': false},
        {'index': 32, 'label': 'AG', 'isAbsolute': true},
      ]);
      expect(extractLabel(r'$Ag199'), [
        {'index': 198, 'label': '199', 'isAbsolute': false},
        {'index': 32, 'label': 'AG', 'isAbsolute': true},
      ]);
      expect(extractLabel(r'$$AG199'), isEmpty);
      expect(extractLabel(r'AG$$199'), isEmpty);
      expect(extractLabel(null), isEmpty);
      expect(extractLabel(0), isEmpty);

      expect(
        toLabel(
          {'index': 0, 'isAbsolute': false},
          {'index': 0, 'isAbsolute': false},
        ),
        'A1',
      );
      expect(
        toLabel(
          {'index': 0, 'isAbsolute': true},
          {'index': 0, 'isAbsolute': false},
        ),
        r'A$1',
      );
      expect(
        toLabel(
          {'index': 0, 'isAbsolute': true},
          {'index': 0, 'isAbsolute': true},
        ),
        r'$A$1',
      );
      expect(
        toLabel(
          {'index': 44, 'isAbsolute': true},
          {'index': 20, 'isAbsolute': true},
        ),
        r'$U$45',
      );
      expect(
        toLabel(
          {'index': 1, 'isAbsolute': false},
          {'index': 20, 'isAbsolute': true},
        ),
        r'$U2',
      );
    });

    test('converts row and column labels', () {
      expect(columnIndexToLabel(-100), '');
      expect(columnIndexToLabel(-1), '');
      expect(columnIndexToLabel(0), 'A');
      expect(columnIndexToLabel(1), 'B');
      expect(columnIndexToLabel(10), 'K');
      expect(columnIndexToLabel(100), 'CW');
      expect(columnIndexToLabel(1000), 'ALM');
      expect(columnIndexToLabel(10000), 'NTQ');

      expect(columnLabelToIndex(''), -1);
      expect(columnLabelToIndex('A'), 0);
      expect(columnLabelToIndex('B'), 1);
      expect(columnLabelToIndex('K'), 10);
      expect(columnLabelToIndex('k'), 10);
      expect(columnLabelToIndex('CW'), 100);
      expect(columnLabelToIndex('ALM'), 1000);
      expect(columnLabelToIndex('aLM'), 1000);
      expect(columnLabelToIndex('NTQ'), 10000);

      expect(rowIndexToLabel(-100), '');
      expect(rowIndexToLabel(-1), '');
      expect(rowIndexToLabel(0), '1');
      expect(rowIndexToLabel(1), '2');
      expect(rowIndexToLabel(10), '11');
      expect(rowIndexToLabel(100), '101');

      expect(rowLabelToIndex(''), -1);
      expect(rowLabelToIndex('0'), -1);
      expect(rowLabelToIndex('1'), 0);
      expect(rowLabelToIndex('2'), 1);
      expect(rowLabelToIndex('100'), 99);
      expect(rowLabelToIndex('92'), 91);
    });

    test('converts and inverts numeric helper values', () {
      expect(toNumber(-100), -100);
      expect(toNumber(-1), -1);
      expect(toNumber(19), 19);
      expect(toNumber(19.9), 19.9);
      expect(toNumber(0.9), 0.9);
      expect(toNumber('0.9'), 0.9);
      expect(toNumber('0'), 0);
      expect(toNumber('-10'), -10);
      expect(toNumber(' -10 '), -10);
      expect(toNumber('foo')!.isNaN, isTrue);

      expect(invertNumber(-100), 100);
      expect(invertNumber(-1), 1);
      expect(invertNumber(19), -19);
      expect(invertNumber(19.9), -19.9);
      expect(invertNumber(0.9), -0.9);
      expect(invertNumber('0.9'), -0.9);
      final invertedZero = invertNumber('0');
      expect(invertedZero, 0);
      expect(invertedZero, isA<double>());
      expect((invertedZero as double).isNegative, isTrue);
      expect(invertNumber('-10'), 10);
      expect(invertNumber(' -10 '), 10);
      expect(invertNumber('foo').isNaN, isTrue);
    });

    test('trims string edges', () {
      expect(trimEdges('hello'), 'ell');
      expect(trimEdges('hello', 1), 'ell');
      expect(trimEdges('hello', 2), 'l');
    });
  });
}
