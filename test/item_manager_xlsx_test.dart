import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/application/item_manager_xlsx.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';

void main() {
  test(
    'imports first-sheet item rows with formatted values and element style',
    () {
      final result = itemManagerImportXlsxBytes(
        _itemWorkbookBytes(),
        columns: const [
          ItemManagerXlsxColumn(
            columnId: 7,
            name: '코드',
            editable: true,
            typeCode: TColumnType.TYPE_BASE,
          ),
          ItemManagerXlsxColumn(
            columnId: 8,
            name: '날짜',
            editable: true,
            typeCode: TColumnType.TYPE_VALIDDATE,
          ),
          ItemManagerXlsxColumn(
            columnId: 9,
            name: '이미지',
            editable: true,
            typeCode: TColumnType.TYPE_IMAGE,
          ),
        ],
        emptyElementPayload: 'UEsDempty',
      );

      expect(result.rows, hasLength(1));
      expect(result.warnings, ['빈 헤더 뒤의 컬럼은 가져오지 않습니다.']);
      final row = result.rows.single;
      expect(row.itemName, '딸기잼');
      expect(row.elementPlain, '딸기 60%');
      expect(row.columnDrafts[7]?.dataString, '00123');
      expect(row.columnDrafts[8]?.dataString, '2023/03/15');
      expect(row.columnDrafts[9]?.dataString, '상품');

      final element = labelSheetDecodeWorkbookSave(
        row.elementPayload,
      ).activeSheet;
      final cell = element.cells[const FortuneCellCoord(0, 0)]!;
      expect(cell.value, '딸기 60%');
      expect(cell.bold, isTrue);
      expect(cell.background, isNotNull);
      expect(element.rowHeights[0], closeTo(32, 0.01));
      expect(element.columnWidths[0], closeTo(112, 0.01));
    },
  );

  test('rejects a first worksheet without the item header', () {
    expect(
      () => itemManagerImportXlsxBytes(
        _itemWorkbookBytes(itemHeader: '상품'),
        columns: const [],
        emptyElementPayload: 'UEsDempty',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('removes only an escaped leading apostrophe from string cells', () {
    const columns = [
      ItemManagerXlsxColumn(
        columnId: 7,
        name: '코드',
        editable: true,
        typeCode: TColumnType.TYPE_BASE,
      ),
    ];

    final escaped = itemManagerImportXlsxBytes(
      _itemWorkbookBytes(codeValue: "'00123", codeQuotePrefix: true),
      columns: columns,
      emptyElementPayload: 'UEsDempty',
    );
    final literal = itemManagerImportXlsxBytes(
      _itemWorkbookBytes(codeValue: "'00123"),
      columns: columns,
      emptyElementPayload: 'UEsDempty',
    );

    expect(escaped.rows.single.columnDrafts[7]?.dataString, '00123');
    expect(literal.rows.single.columnDrafts[7]?.dataString, "'00123");
  });

  test(
    'exports stable rows as inline strings that round-trip through import',
    () {
      const columns = [
        ItemManagerXlsxColumn(
          columnId: 7,
          name: '코드',
          editable: true,
          typeCode: TColumnType.TYPE_BASE,
        ),
      ];
      final row =
          ItemManagerDraftRow.newRow(
            draftRowKey: 'export-1',
            order: 1,
            originalIndex: 0,
            insertAnchorItemId: null,
            rowState: ItemManagerDraftRowState.imported,
            emptyElementPayload: 'UEsDempty',
          ).copyWith(
            itemName: '딸기 & 설탕 <특가>',
            elementPlain: '딸기 60%',
            columnDrafts: const {
              7: ItemManagerColumnDraft(editable: true, dataString: '00123'),
            },
          );

      final bytes = itemManagerExportXlsxBytes(
        rows: [row],
        columns: columns,
        columnValue: (draft, column) =>
            draft.columnDrafts[column.columnId]?.dataString ?? '',
      );
      final imported = itemManagerImportXlsxBytes(
        bytes,
        columns: columns,
        emptyElementPayload: 'UEsDempty',
      );

      expect(imported.rows, hasLength(1));
      expect(imported.rows.single.itemName, '딸기 & 설탕 <특가>');
      expect(imported.rows.single.elementPlain, '딸기 60%');
      expect(imported.rows.single.columnDrafts[7]?.dataString, '00123');
    },
  );
}

Uint8List _itemWorkbookBytes({
  String itemHeader = '품목',
  String codeValue = '00123',
  bool codeQuotePrefix = false,
}) {
  final archive = Archive();
  void addXml(String name, String content) {
    archive.addFile(ArchiveFile.string(name, content));
  }

  addXml('xl/workbook.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <bookViews><workbookView activeTab="0"/></bookViews>
  <sheets><sheet name="Items" sheetId="1" r:id="rId1"/></sheets>
</workbook>''');
  addXml('xl/_rels/workbook.xml.rels', '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''');
  addXml('xl/styles.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2"><font><sz val="11"/></font><font><b/><sz val="12"/></font></fonts>
  <fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FFFFFF00"/></patternFill></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="4"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/><xf numFmtId="14" fontId="0" fillId="0" borderId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" applyFill="1" applyFont="1"/><xf numFmtId="0" fontId="0" fillId="0" borderId="0" quotePrefix="1"/></cellXfs>
</styleSheet>''');
  addXml('xl/worksheets/sheet1.xml', '''<?xml version="1.0" encoding="UTF-8"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <dimension ref="A1:G3"/>
  <cols><col min="2" max="2" width="14" customWidth="1"/></cols>
  <sheetData>
    <row r="1"><c r="A1" t="inlineStr"><is><t>$itemHeader</t></is></c><c r="B1" t="inlineStr"><is><t>주원료</t></is></c><c r="C1" t="inlineStr"><is><t>코드</t></is></c><c r="D1" t="inlineStr"><is><t>날짜</t></is></c><c r="E1" t="inlineStr"><is><t>이미지</t></is></c><c r="G1" t="inlineStr"><is><t>품목</t></is></c></row>
    <row r="2" ht="24" customHeight="1"><c r="A2" t="inlineStr"><is><t>딸기잼</t></is></c><c r="B2" t="inlineStr" s="2"><is><t>딸기 60%</t></is></c><c r="C2" t="inlineStr"${codeQuotePrefix ? ' s="3"' : ''}><is><t>$codeValue</t></is></c><c r="D2" s="1"><v>45000</v></c><c r="E2" t="inlineStr"><is><t>C:\\images\\상품.BMP</t></is></c></row>
    <row r="3"/>
  </sheetData>
</worksheet>''');
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}
