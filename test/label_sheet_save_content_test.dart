import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';

void main() {
  test('save content policy checks every supported active-sheet collection', () {
    FortuneWorkbook workbook(FortuneSheet sheet) => FortuneWorkbook(
      sheets: <FortuneSheet>[sheet],
    );

    expect(
      labelSheetWorkbookHasSaveContent(
        workbook(FortuneSheet(id: 'empty', name: 'Empty')),
      ),
      isFalse,
    );

    final sheets = <String, FortuneSheet>{
      'cells': FortuneSheet(
        id: 'cells',
        name: 'Cells',
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: 'content'),
        },
      ),
      'borders': FortuneSheet(
        id: 'borders',
        name: 'Borders',
        borderInfo: const [
          FortuneBorderInfo(
            rangeType: 'range',
            borderType: 'border-all',
            color: Color(0xff000000),
            style: 1,
            ranges: [
              FortuneRange(
                rowStart: 0,
                rowEnd: 0,
                columnStart: 0,
                columnEnd: 0,
              ),
            ],
          ),
        ],
      ),
      'images': FortuneSheet(
        id: 'images',
        name: 'Images',
        images: const [
          FortuneImage(
            id: 'image',
            src: 'data:image/png;base64,AAA=',
            left: 0,
            top: 0,
            width: 10,
            height: 10,
          ),
        ],
      ),
      'lines': FortuneSheet(
        id: 'lines',
        name: 'Lines',
        lines: const [FortuneLine(id: 'line', x1: 0, y1: 0, x2: 10, y2: 10)],
      ),
      'shapes': FortuneSheet(
        id: 'shapes',
        name: 'Shapes',
        shapes: const [
          FortuneShape(
            id: 'shape',
            kind: FortuneShapeKind.rectangle,
            left: 0,
            top: 0,
            width: 10,
            height: 10,
          ),
        ],
      ),
      'data verification': FortuneSheet(
        id: 'data-verification',
        name: 'Data Verification',
        dataVerification: const {
          '0_0': {'type': 'checkbox', 'checked': true},
        },
      ),
      'hyperlinks': FortuneSheet(
        id: 'hyperlinks',
        name: 'Hyperlinks',
        hyperlinks: const {
          '0_0': {
            'linkType': 'webpage',
            'linkAddress': 'https://example.test',
          },
        },
      ),
    };

    for (final entry in sheets.entries) {
      expect(
        labelSheetWorkbookHasSaveContent(workbook(entry.value)),
        isTrue,
        reason: entry.key,
      );
    }
  });

  test('save content policy only checks the active sheet', () {
    final workbook = FortuneWorkbook(
      sheets: <FortuneSheet>[
        FortuneSheet(id: 'active', name: 'Active'),
        FortuneSheet(
          id: 'inactive',
          name: 'Inactive',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: 'content'),
          },
        ),
      ],
    );

    expect(labelSheetWorkbookHasSaveContent(workbook), isFalse);
  });
}