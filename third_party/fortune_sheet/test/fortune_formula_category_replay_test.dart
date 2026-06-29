import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream formula category replay parity', () {
    test('evaluates statistical GROWTH fixture', () {
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
      );

      final expected = [
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

      for (var index = 0; index < expected.length; index += 1) {
        expect(
          FortuneFormulaEngine.evaluateFormula(
            sheet,
            '=INDEX(GROWTH(foo, bar, baz), 1, ${index + 1})',
          ),
          closeTo(expected[index], 1e-6),
          reason: 'GROWTH result ${index + 1}',
        );
      }
    });
  });
}
