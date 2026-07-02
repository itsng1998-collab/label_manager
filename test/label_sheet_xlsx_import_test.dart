import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/page_label_sheet/label_sheet_xlsx_import.dart';

void main() {
  test('imports xlsx values, styles, structure, links and rich text', () {
    final workbook = labelSheetWorkbookFromXlsxBytes(_xlsxBytes());
    final sheet = workbook.activeSheet;

    expect(sheet.name, 'Labels');
    expect(sheet.rowCount, 3);
    expect(sheet.columnCount, 7);
    expect(sheet.rowHeights[0], closeTo(32, 0.01));
    expect(sheet.columnWidths[0], closeTo(96, 0.01));
    expect(sheet.hiddenRows, contains(1));
    expect(sheet.hiddenColumns, contains(2));

    final a1 = sheet.cells[const FortuneCellCoord(0, 0)]!;
    expect(a1.value, '라벨');
    expect(a1.bold, isTrue);
    expect(a1.italic, isTrue);
    expect(a1.underline, isTrue);
    expect(a1.fontFamily, '맑은 고딕');
    expect(a1.fontSize, closeTo(18.67, 0.01));
    expect(a1.foreground, const Color(0xffff0000));
    expect(a1.background, const Color(0xff00ff00));
    expect(a1.horizontalAlign, 'center');
    expect(a1.verticalAlign, 'middle');
    expect(a1.textWrap, '2');
    expect(a1.normalizedTextWrap, '2');
    expect(a1.cellType?.format, '0.00');
    expect(a1.merge?.rowSpan, 2);
    expect(a1.merge?.columnSpan, 2);
    expect(a1.extraFields['fontScale'], 85);
    expect(a1.extraFields['letterSpacing'], 1.25);
    expect(a1.extraFields['lineHeight'], 1.4);

    final b1 = sheet.cells[const FortuneCellCoord(0, 1)]!;
    expect(b1.value, '42');
    expect(b1.formula, '=SUM(A1,1)');
    expect(b1.hyperlink?.linkAddress, 'https://example.com');
    expect(b1.merge?.row, 0);
    expect(b1.merge?.column, 0);

    final d1 = sheet.cells[const FortuneCellCoord(0, 3)]!;
    expect(d1.value, '오른쪽 병합');
    expect(d1.merge?.rowSpan, 1);
    expect(d1.merge?.columnSpan, 2);

    final a3 = sheet.cells[const FortuneCellCoord(2, 0)]!;
    expect(a3.value, '첫 줄\n둘째 줄');
    expect(a3.textWrap, '2');
    expect(a3.normalizedTextWrap, '2');

    final e1 = sheet.cells[const FortuneCellCoord(0, 4)]!;
    expect(e1.merge?.row, 0);
    expect(e1.merge?.column, 3);

    expect(sheet.cells[const FortuneCellCoord(0, 5)]?.value, isEmpty);
    expect(sheet.cells[const FortuneCellCoord(0, 6)]?.value, '빈셀 다음 값');

    final c1 = sheet.cells[const FortuneCellCoord(0, 2)]!;
    expect(c1.value, 'H2O');
    expect(c1.inlineRuns, hasLength(2));
    expect(c1.inlineRuns![0].text, 'H');
    expect(c1.inlineRuns![1].text, '2O');
    expect(c1.inlineRuns![1].extraFields['script'], 'subscript');
    expect(c1.inlineRuns![1].extraFields['fontScale'], 70);
    expect(c1.inlineRuns![1].extraFields['letterSpacing'], 0.5);
    expect(c1.inlineRuns![1].extraFields['lineHeight'], 1.2);

    expect(sheet.borderInfo.map((border) => border.borderType), contains('border-left'));
    expect(sheet.borderInfo.map((border) => border.borderType), contains('border-top'));
    expect(
      sheet.borderInfo
          .where((border) => border.borderType == 'border-top')
          .map((border) => border.style),
      contains(8),
    );
    expect(
      sheet.borderInfo
          .where((border) => border.borderType == 'border-top')
          .map((border) => border.strokeWidth),
      contains(1.5),
    );
  });

  test('detects xlsx bytes and supports absolute worksheet targets', () {
    final bytes = _xlsxBytes(absoluteWorksheetTarget: true);

    expect(labelSheetLooksLikeXlsx(bytes), isTrue);
    expect(labelSheetLooksLikeXlsx(Uint8List.fromList('not a zip'.codeUnits)), isFalse);
    expect(
      labelSheetWorkbookFromXlsxBytes(bytes)
          .activeSheet
          .cells[const FortuneCellCoord(0, 0)]
          ?.value,
      '라벨',
    );
  });

  test('imports xlsx xml with namespace-prefixed spreadsheet tags', () {
    final workbook = labelSheetWorkbookFromXlsxBytes(_xlsxBytes(prefixTags: true));

    expect(workbook.activeSheet.name, 'Labels');
    expect(
      workbook.activeSheet.cells[const FortuneCellCoord(0, 0)]?.value,
      '라벨',
    );
    expect(
      workbook.activeSheet.cells[const FortuneCellCoord(0, 2)]?.inlineRuns?[1].extraFields['script'],
      'subscript',
    );
  });
}

Uint8List _xlsxBytes({
  bool absoluteWorksheetTarget = false,
  bool prefixTags = false,
}) {
  final archive = Archive();
  void addXml(String name, String content) {
    final shouldPrefix = prefixTags &&
        name.startsWith('xl/') &&
        name.endsWith('.xml') &&
        !name.contains('/_rels/');
    archive.addFile(
      ArchiveFile.string(name, shouldPrefix ? _prefixSpreadsheetTags(content) : content),
    );
  }

  addXml('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>''');
  addXml('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
  addXml('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews><workbookView activeTab="0"/></bookViews>
  <sheets><sheet name="Labels" sheetId="1" r:id="rId1"/></sheets>
</workbook>''');
  addXml('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="${absoluteWorksheetTarget ? '/xl/worksheets/sheet1.xml' : 'worksheets/sheet1.xml'}"/>
</Relationships>''');
  addXml('xl/worksheets/_rels/sheet1.xml.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdHyper" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://example.com" TargetMode="External"/>
</Relationships>''');
  addXml('xl/sharedStrings.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="2" uniqueCount="2">
  <si><t>라벨</t></si>
  <si><r><t>H</t></r><r><rPr><vertAlign val="subscript"/><sz val="9"/></rPr><t>2O</t></r></si>
</sst>''');
  addXml('xl/styles.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <numFmts count="1"><numFmt numFmtId="164" formatCode="0.00"/></numFmts>
  <fonts count="2">
    <font><sz val="11"/><name val="Arial"/></font>
    <font><b/><i/><u/><sz val="14"/><color rgb="FFFF0000"/><name val="맑은 고딕"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF00FF00"/></patternFill></fill>
  </fills>
  <borders count="2">
    <border><left/><right/><top/><bottom/></border>
    <border><left style="thin"><color rgb="FF0000FF"/></left><top style="medium"><color rgb="FFFF0000"/></top></border>
  </borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
    <xf numFmtId="164" fontId="1" fillId="2" borderId="1" quotePrefix="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellXfs>
</styleSheet>''');
  addXml('xl/worksheets/sheet1.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <dimension ref="A1:G3"/>
  <cols><col min="1" max="1" width="12" customWidth="1"/><col min="3" max="3" hidden="1" width="10" customWidth="1"/><col min="4" max="5" width="8" customWidth="1"/><col min="6" max="7" width="8" customWidth="1"/></cols>
  <sheetData>
    <row r="1" ht="24" customHeight="1">
      <c r="A1" t="s" s="1"><v>0</v></c>
      <c r="B1" s="2"><f>SUM(A1,1)</f><v>42</v></c>
      <c r="C1" t="s" s="2"><v>1</v></c>
      <c r="D1" t="str" s="1"><v>오른쪽 병합</v></c>
      <c r="E1" s="1"/>
      <c r="F1" s="2"/>
      <c r="G1" t="str" s="2"><v>빈셀 다음 값</v></c>
    </row>
    <row r="2" hidden="1"><c r="A2" s="2"/></row>
    <row r="3"><c r="A3" t="str" s="2"><v>첫 줄&#10;둘째 줄</v></c></row>
  </sheetData>
  <mergeCells count="2"><mergeCell ref="A1:B2"/><mergeCell ref="D1:E1"/></mergeCells>
  <hyperlinks><hyperlink ref="B1" r:id="rIdHyper"/></hyperlinks>
</worksheet>''');
  addXml('customXml/item1.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<labelSheetRtfMetadata xmlns="urn:label-manager:rtf-metadata">
  <cell ref="A1" fontScale="85" letterSpacing="1.25" lineHeight="1.4"/>
  <cell ref="C1"><run index="1" fontScale="70" letterSpacing="0.5" lineHeight="1.2" script="subscript"/></cell>
</labelSheetRtfMetadata>''');

  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

String _prefixSpreadsheetTags(String xml) {
  final withNamespacePrefix = xml.replaceAll(
    'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"',
    'xmlns:x="http://schemas.openxmlformats.org/spreadsheetml/2006/main"',
  );
  const tags = <String>{
    'alignment',
    'b',
    'border',
    'borders',
    'bookViews',
    'workbookView',
    'bottom',
    'c',
    'cellStyleXfs',
    'cellXfs',
    'col',
    'color',
    'cols',
    'dimension',
    'f',
    'fgColor',
    'fill',
    'fills',
    'font',
    'fonts',
    'hyperlink',
    'hyperlinks',
    'i',
    'left',
    'mergeCell',
    'mergeCells',
    'name',
    'numFmt',
    'numFmts',
    'patternFill',
    'r',
    'right',
    'rPr',
    'row',
    'sheet',
    'sheetData',
    'sheets',
    'si',
    'sst',
    'styleSheet',
    'sz',
    't',
    'top',
    'u',
    'v',
    'workbook',
    'worksheet',
    'xf',
  };
  return withNamespacePrefix.replaceAllMapped(
    RegExp(r'<(/?)([A-Za-z][A-Za-z0-9]*)\b'),
    (match) {
      final tag = match.group(2)!;
      if (!tags.contains(tag)) {
        return match.group(0)!;
      }
      return '<${match.group(1) ?? ''}x:$tag';
    },
  );
}