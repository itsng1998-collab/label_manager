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
    expect(sheet.columnCount, 3);
    expect(sheet.rowHeights[0], closeTo(32, 0.01));
    expect(sheet.columnWidths[0], closeTo(84, 0.01));
    expect(sheet.hiddenRows, contains(1));
    expect(sheet.hiddenColumns, contains(2));

    final a1 = sheet.cells[const FortuneCellCoord(0, 0)]!;
    expect(a1.value, '라벨');
    expect(a1.bold, isTrue);
    expect(a1.italic, isTrue);
    expect(a1.underline, isTrue);
    expect(a1.fontFamily, '맑은 고딕');
    expect(a1.fontSize, 14);
    expect(a1.foreground, const Color(0xffff0000));
    expect(a1.background, const Color(0xff00ff00));
    expect(a1.horizontalAlign, 'center');
    expect(a1.verticalAlign, 'middle');
    expect(a1.textWrap, 'wrap');
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
  });
}

Uint8List _xlsxBytes() {
  final archive = Archive();
  void addXml(String name, String content) {
    archive.addFile(ArchiveFile.string(name, content));
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
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
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
  <dimension ref="A1:C3"/>
  <cols><col min="1" max="1" width="12" customWidth="1"/><col min="3" max="3" hidden="1" width="10" customWidth="1"/></cols>
  <sheetData>
    <row r="1" ht="24" customHeight="1">
      <c r="A1" t="s" s="1"><v>0</v></c>
      <c r="B1" s="2"><f>SUM(A1,1)</f><v>42</v></c>
      <c r="C1" t="s" s="2"><v>1</v></c>
    </row>
    <row r="2" hidden="1"><c r="A2" s="2"/></row>
  </sheetData>
  <mergeCells count="1"><mergeCell ref="A1:B2"/></mergeCells>
  <hyperlinks><hyperlink ref="B1" r:id="rIdHyper"/></hyperlinks>
</worksheet>''');
  addXml('customXml/item1.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<labelSheetRtfMetadata xmlns="urn:label-manager:rtf-metadata">
  <cell ref="A1" fontScale="85" letterSpacing="1.25" lineHeight="1.4"/>
  <cell ref="C1"><run index="1" fontScale="70" letterSpacing="0.5" lineHeight="1.2" script="subscript"/></cell>
</labelSheetRtfMetadata>''');

  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}