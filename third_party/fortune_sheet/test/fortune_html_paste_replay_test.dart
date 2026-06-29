import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  group('upstream HTML paste replay parity', () {
    test('replays WPS HTML paste value and style fixture', () {
      const wpsHtml = '''
<table>
  <tr>
    <td x:num="1" style="color:#000000;font-size:12.0pt;font-weight:400;font-style:normal;text-decoration:none;text-align:general;vertical-align:middle;mso-number-format:General;">1</td>
    <td x:num="2" style="color:#000000;font-size:12.0pt;font-weight:700;font-style:normal;text-decoration:none;text-align:general;vertical-align:middle;mso-number-format:General;">2</td>
    <td x:num="3" style="color:#ED7D31;font-size:12.0pt;font-weight:700;font-style:normal;text-decoration:none;text-align:general;vertical-align:middle;mso-number-format:General;">3</td>
  </tr>
  <tr>
    <td x:num="4" style="color:#000000;font-size:12.0pt;font-weight:400;font-style:normal;text-decoration:none;text-align:general;vertical-align:middle;background:#ED7D31;mso-number-format:General;">4</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td x:num="5" style="color:#000000;font-size:12.0pt;font-weight:400;font-style:normal;text-decoration:underline;text-align:general;vertical-align:middle;mso-number-format:General;">5</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td x:num="6" style="color:#000000;font-size:12.0pt;font-weight:400;font-style:italic;text-decoration:none;text-align:general;vertical-align:middle;mso-number-format:General;">6</td>
    <td></td>
    <td></td>
  </tr>
</table>
''';

      final pastePayload = pasteHandlerOfHtmlTable(
        FortuneWorkbook(
          sheets: [FortuneSheet(id: 'sheet-1', name: 'Sheet1')],
        ),
        {
          'currentSheetId': 'sheet-1',
          'luckysheet_select_save': [
            {
              'row': [0, 0],
              'column': [0, 0],
            },
          ],
        },
        wpsHtml,
      );

      final pastedSheet = pastePayload?['sheet'] as FortuneSheet;
      expect(pastedSheet.cells[const FortuneCellCoord(0, 0)]?.rawValue, 1);
      expect(pastedSheet.cells[const FortuneCellCoord(3, 0)]?.rawValue, 6);

      final coloredBold = pastedSheet.cells[const FortuneCellCoord(0, 2)]!;
      expect(coloredBold.rawValue, 3);
      expect(coloredBold.rawBold, 1);
      expect(coloredBold.rawForeground, '#ED7D31');
      expect(coloredBold.rawFontSize, 9);
      expect(coloredBold.rawHorizontalAlign, 1);
      expect(coloredBold.rawVerticalAlign, 0);

      final background = pastedSheet.cells[const FortuneCellCoord(1, 0)]!;
      expect(background.rawValue, 4);
      expect(background.rawBackground, '#ED7D31');
      expect(background.rawBold, 0);

      final underlined = pastedSheet.cells[const FortuneCellCoord(2, 0)]!;
      expect(underlined.rawValue, 5);
      expect(underlined.rawUnderline, 1);

      final italic = pastedSheet.cells[const FortuneCellCoord(3, 0)]!;
      expect(italic.rawValue, 6);
      expect(italic.rawItalic, 1);
    });

    test('replays Excel HTML paste class styles from upstream fixture', () {
      const excelHtml = '''
<html>
<head>
<style>
<!--
.xl65 {font-weight:700;}
.xl66 {color:#ED7D31;}
.xl67 {background:#ED7D31; mso-pattern:black none;}
.xl68 {text-decoration:underline; text-underline-style:single;}
.xl69 {font-style:italic;}
-->
</style>
</head>
<body>
<table>
 <tr>
  <td>1</td>
  <td class=xl65>2</td>
  <td class=xl66>3</td>
 </tr>
 <tr>
  <td class=xl67>3</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td class=xl68>4</td>
  <td></td>
  <td></td>
 </tr>
 <tr>
  <td class=xl69>5</td>
  <td></td>
  <td></td>
 </tr>
</table>
</body>
</html>
''';

      final pastePayload = pasteHandlerOfHtmlTable(
        FortuneWorkbook(
          sheets: [FortuneSheet(id: 'sheet-1', name: 'Sheet1')],
        ),
        {
          'currentSheetId': 'sheet-1',
          'luckysheet_select_save': [
            {
              'row': [0, 0],
              'column': [0, 0],
            },
          ],
        },
        excelHtml,
      );

      final pastedSheet = pastePayload?['sheet'] as FortuneSheet;
      expect(pastedSheet.cells[const FortuneCellCoord(0, 0)]?.rawValue, 1);
      expect(pastedSheet.cells[const FortuneCellCoord(3, 0)]?.rawValue, 5);
      expect(pastedSheet.cells[const FortuneCellCoord(0, 1)]?.rawBold, 1);
      expect(
        pastedSheet.cells[const FortuneCellCoord(0, 2)]?.rawForeground,
        '#ED7D31',
      );
      expect(
        pastedSheet.cells[const FortuneCellCoord(1, 0)]?.rawBackground,
        '#ED7D31',
      );
      expect(pastedSheet.cells[const FortuneCellCoord(2, 0)]?.rawUnderline, 1);
      expect(pastedSheet.cells[const FortuneCellCoord(3, 0)]?.rawItalic, 1);
    });
  });
}
