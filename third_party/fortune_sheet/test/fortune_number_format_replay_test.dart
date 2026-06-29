import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream toolbar number format replay parity', () {
    const rawValue = '5';

    test('matches currency and percentage display values', () {
      expect(update('¥ #.00', rawValue), '¥ 5.00');
      expect(update('0.00%', rawValue), '500.00%');
    });

    test('matches decimal decrease and increase display values', () {
      expect(update('0.0%', rawValue), '500.0%');
      expect(update('0.00%', rawValue), '500.00%');
    });

    test('matches built-in SSF basic numeric display values', () {
      expect(update('General', 1234.5), '1234.5');
      expect(update('0', 1234.5), '1235');
      expect(update('0', -1234.5), '-1235');
      expect(update('0.00', 1234.5), '1234.50');
      expect(update('#,##0', 1234.5), '1,235');
      expect(update('#,##0.00', 1234.5), '1,234.50');
      expect(update(' 0', 5), ' 5');
      expect(update('0 ', 5), '5 ');
      expect(update(' 0 ', 5), ' 5 ');
    });

    test('throws for unterminated SSF quoted literals', () {
      expect(() => update(r'"abc', 5), throwsA(isA<FormatException>()));
      expect(() => update(r'0;"neg', -5), throwsA(isA<FormatException>()));
      expect(() => update(r'"text@', 'label'), throwsA(isA<FormatException>()));
    });

    test('throws for unterminated SSF bracket blocks', () {
      expect(() => update('[Red', 5), throwsA(isA<FormatException>()));
      expect(() => update('[Blue@', 'label'), throwsA(isA<FormatException>()));
      expect(() => update('[h', 1.5), throwsA(isA<FormatException>()));
    });

    test('matches SSF General scientific display boundaries', () {
      expect(update('General', 0.000012345), '0.000012345');
      expect(update('General', 0.000000123456), '1.23456E-07');
      expect(update('General', -0.000000123456), '-1.23456E-07');
      expect(update('General', 0.000000999999), '9.99999E-07');
      expect(update('General', -0.000000999999), '-9.99999E-07');
      expect(update('General', 0.0000009999999), '0.000001');
      expect(update('General', -0.0000009999999), '-0.000001');
      expect(update('General', 1234567890.12), '1234567890');
      expect(update('General', -1234567890.12), '-1234567890');
      expect(update('General', 999999999.99), '1000000000');
      expect(update('General', -999999999.99), '-1000000000');
      expect(update('General', 12345678901), '12345678901');
      expect(update('General', 123456789012), '1.23457E+11');
      expect(update('General', 10000000000), '10000000000');
      expect(update('General', 10000000000.1), '10000000000');
      expect(update('General', -10000000000), '-10000000000');
      expect(update('General', -10000000000.1), '-10000000000');
      expect(update('General', 9999999999.9), '1E+10');
      expect(update('General', -9999999999.9), '-1E+10');
      expect(update('General', 100000000000), '1E+11');
      expect(update('General', -100000000000), '-1E+11');
      expect(update('General', double.nan), 'NAN');
      expect(update('General', double.infinity), 'INFINITY');
      expect(update('General', double.negativeInfinity), '-INFINITY');
    });

    test('matches SSF numeric writer edge display values', () {
      expect(update('.00', 0.12), '.12');
      expect(update('#.00', 0.12), '.12');
      expect(update('#.00', -0.12), '-0.12');
      expect(update('#,###.00', 0.12), '.12');
      expect(update('###,###.00', 0.995), '1.100');
      expect(update('00,000.00', -123), '-00,123.00');
      expect(update('#,###,#0.00', 12345), '12345.00');
      expect(update('##0.0E+0', -12345), '-12.3E+3');
      expect(update('##0.0E+0', 0.0123), '12.3E-3');
    });

    test('matches SSF placeholder and optional decimal display values', () {
      expect(update('0.#', 12), '12.');
      expect(update('00.##', 1), '1.');
      expect(update('0.0?', 12), '12.0');
      expect(update('0.#?', 12), '12.');
      expect(update('0.?', 12), '12. ');
      expect(update('#.??', 0), '.  ');
      expect(update('????.??', -12), ' -12.  ');
      expect(update('####', 0), '');
      expect(update('????', -0.4), '    ');
      expect(update('*x0', 12), 'x12');
      expect(update('0*x', 12), '12x');
      expect(update('*x????', -0.4), 'x    ');
      expect(update('0* ', 12), '12');
    });

    test('matches SSF text-section fill-token boundaries', () {
      expect(update('*x@', 'label'), 'xlabel');
      expect(update('* @', 'label'), 'label');
      expect(update('**@', 'label'), 'label');
    });

    test('matches SSF section split escaped divider tokens', () {
      expect(update(r'0_;;0', -5), '5');
      expect(update(r'0*;;0', -5), '5');
      expect(update(r'0\;;0', -5), '5');
    });

    test('matches SSF section split quoted semicolon behavior', () {
      expect(update(r'"a;b";0', 5), 'a');
    });

    test('matches SSF text-section bracket directives', () {
      expect(update('[Red]@', 'label'), 'label');
      expect(update('0;0;0;[Blue]@', 'label'), 'label');
      expect(update(r'[$€-407]@', 'label'), '€label');
      expect(update(r'[$-409]@', 'label'), r'$label');
    });

    test('matches accounting zero dash placeholder display value', () {
      const accountingNoSymbol0 = r'_(* #,##0_);_(* \(#,##0\);_(* "-"_);_(@_)';
      const accountingCurrency0 =
          r'_("$"* #,##0_);_("$"* \(#,##0\);_("$"* "-"_);_(@_)';
      const accountingNoSymbol2 =
          r'_(* #,##0.00_);_(* \(#,##0.00\);_(* "-"??_);_(@_)';
      const accountingCurrency2 =
          r'_("$"* #,##0.00_);_("$"* \(#,##0.00\);_("$"* "-"??_);_(@_)';

      expect(update(accountingNoSymbol0, 1234.5), ' 1,235 ');
      expect(update(accountingNoSymbol0, -1234.5), ' (1,235)');
      expect(update(accountingNoSymbol0, 0), ' - ');
      expect(update(accountingNoSymbol0, 'label'), ' label ');
      expect(update(accountingCurrency0, 1234.5), r' $1,235 ');
      expect(update(accountingCurrency0, -1234.5), r' $(1,235)');
      expect(update(accountingCurrency0, 0), r' $- ');
      expect(update(accountingCurrency0, 'label'), ' label ');
      expect(update(accountingNoSymbol2, 1234.5), ' 1,234.50 ');
      expect(update(accountingNoSymbol2, -1234.5), ' (1,234.50)');
      expect(update(accountingNoSymbol2, 0), ' -   ');
      expect(update(accountingNoSymbol2, 'label'), ' label ');
      expect(update(accountingCurrency2, 1234.5), r' $1,234.50 ');
      expect(update(accountingCurrency2, -1234.5), r' $(1,234.50)');
      expect(update(accountingCurrency2, 0), r' $-   ');
      expect(update(accountingCurrency2, 'label'), ' label ');
    });

    test('matches built-in SSF currency display values', () {
      const currency0 = r'"$"#,##0_);\("$"#,##0\)';
      const redCurrency0 = r'"$"#,##0_);[Red]\("$"#,##0\)';
      const currency2 = r'"$"#,##0.00_);\("$"#,##0.00\)';
      const redCurrency2 = r'"$"#,##0.00_);[Red]\("$"#,##0.00\)';

      expect(update(currency0, 1234.5), r'$1,235 ');
      expect(update(currency0, -1234.5), r'($1,235)');
      expect(update(currency0, 0), r'$0 ');
      expect(update(redCurrency0, -1234.5), r'($1,235)');
      expect(update(currency2, 1234.5), r'$1,234.50 ');
      expect(update(currency2, -1234.5), r'($1,234.50)');
      expect(update(currency2, 0), r'$0.00 ');
      expect(update(redCurrency2, -1234.5), r'($1,234.50)');
    });

    test('matches SSF locale currency bracket display values', () {
      final serial = datenumLocal(DateTime(2024, 5, 6));

      expect(update(r'[$-409]#,##0', 1234.5), r'$1,235');
      expect(update(r'[$€-407]#,##0.00', 1234.5), '€1,234.50');
      expect(update(r'[$-409]m/d/yy', serial), '5/6/24');
    });

    test('matches built-in SSF comma negative display values', () {
      expect(update('#,##0 ;(#,##0)', 1234.5), '1,235 ');
      expect(update('#,##0 ;(#,##0)', -1234.5), '(1,235)');
      expect(update('#,##0 ;(#,##0)', 0), '0 ');
      expect(update('#,##0 ;[Red](#,##0)', -1234.5), '(1,235)');
      expect(update('#,##0.00;(#,##0.00)', 1234.5), '1,234.50');
      expect(update('#,##0.00;(#,##0.00)', -1234.5), '(1,234.50)');
      expect(update('#,##0.00;(#,##0.00)', 0), '0.00');
      expect(update('#,##0.00;[Red](#,##0.00)', -1234.5), '(1,234.50)');
    });

    test('matches built-in SSF date and time display values', () {
      final serial = datenumLocal(DateTime(2024, 5, 6, 7, 8, 9));

      expect(update('m/d/yy', 59), '2/28/00');
      expect(update('m/d/yy', 60), '2/29/00');
      expect(update('yyyy-mm-dd', 60), '1900-02-29');
      expect(update('ddd', 60), 'Wed');
      expect(update('dddd', 60), 'Wednesday');
      expect(update('m/d/yy h:mm', 60.5), '2/29/00 12:00');
      expect(update('m/d/yy', 61), '3/1/00');
      expect(update('m/d/yy', -1), '');
      expect(update('m/d/yy', 0), '#####');
      expect(update('m/d/yy', 2958466), '#####');
      expect(update('[h]', 2958466), '');
      expect(update('AM/PM', 0), '');
      expect(update('B1yy', 0), '');
      expect(update('m/d/yy', serial), '5/6/24');
      expect(update('d-mmm-yy', serial), '6-May-24');
      expect(update('d-mmm', serial), '6-May');
      expect(update('mmm-yy', serial), 'May-24');
      expect(update('h:mm', serial), '7:08');
      expect(update('h:mm:ss', serial), '7:08:09');
      expect(update('m/d/yy h:mm', serial), '5/6/24 7:08');
      expect(update('*xm/d/yy', serial), 'x5/6/24');
      expect(update('mm:ss', serial), '08:09');
      expect(update('mmss.0', serial), '0809.0');
      expect(update(r'"上午/下午 "hh"時"mm"分"ss"秒 "', serial), '上午/下午 07時08分09秒 ');
    });

    test('matches SSF era and Buddhist year date tokens', () {
      final serial = datenumLocal(DateTime(2024, 5, 6));

      expect(update('bbbb-mm-dd', serial), '2567-05-06');
      expect(update('bb-mm-dd', serial), '67-05-06');
      expect(update('e-mm-dd', serial), '2024-05-06');
      expect(update('ggge-mm-dd', serial), '2024-05-06');
      expect(update('B1bbbb-mm-dd', serial), '2567-05-06');
    });

    test('matches built-in SSF numeric display values', () {
      expect(update('0%', 0.123), '12%');
      expect(update('0.00%', 0.123), '12.30%');
      expect(update('0.00E+00', 123000000000), '1.23E+11');
      expect(update('# ?/?', 1.5), '1 1/2');
      expect(update('# ??/??', 1.125), '1  1/8 ');
      expect(update('# ?/2', 1.25), '1 1/2');
      expect(update('# ?/4', 1.125), '1 1/4');
      expect(update('# ??/100', 1.125), '1 13/100');
      expect(update('##0.0E+0', 123000000000), '123.0E+9');
      expect(update('@', 'label'), 'label');
    });

    test('matches SSF conditional section display values', () {
      expect(update('[<10]0 "lt";0', 9), '9 lt');
      expect(update('[<=10]0 "le";0', 10), '10 le');
      expect(update('[>10]0 "gt";0', 11), '11 gt');
      expect(update('[>=10]0 "ge";0', 10), '10 ge');
      expect(update('[=10]0 "eq";0', 10), '10 eq');
      expect(update('[<>10]0 "ne";0', 11), '11 ne');
      expect(update('[>10]0 "gt";0 "fallback"', 5), '5 fallback');
    });

    test('matches SSF empty numeric section display values', () {
      expect(update('0;', -5), '');
      expect(update('0;;0', -5), '');
      expect(update('0;0;', 0), '');
    });

    test('matches built-in SSF AM/PM and elapsed time display values', () {
      final evening = datenumLocal(DateTime(2024, 5, 6, 18));

      expect(update('h:mm AM/PM', evening), '6:00 PM');
      expect(update('h:mm:ss AM/PM', evening), '6:00:00 PM');
      expect(update('h:mm A/P', evening), '6:00 P');
      expect(update('A/P h:mm', evening), 'P 6:00');
      expect(update('上午/下午 h:mm', evening), '下午 6:00');
      expect(update('[h]:mm:ss', 1.5), '36:00:00');
      expect(update('[m]:ss', 1.5), '2160:00');
      expect(update('[s]', 1.5), '129600');
    });
  });
}
