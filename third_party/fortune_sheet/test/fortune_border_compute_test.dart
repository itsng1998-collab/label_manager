import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_border_compute.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test('single edge borders apply to range perimeter side only', () {
    FortuneSheet sheetFor(String borderType) {
      return FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        borderInfo: [
          FortuneBorderInfo(
            rangeType: 'range',
            borderType: borderType,
            color: const Color(0xff123456),
            style: 13,
            ranges: const [
              FortuneRange(
                rowStart: 1,
                rowEnd: 2,
                columnStart: 1,
                columnEnd: 2,
              ),
            ],
          ),
        ],
      );
    }

    final topBorders = FortuneBorderCompute.compute(sheetFor('border-top'));
    expect(
      topBorders[const FortuneCellCoord(1, 1)]?.top?.color,
      const Color(0xff123456),
    );
    expect(topBorders[const FortuneCellCoord(1, 1)]?.top?.style, 13);
    expect(topBorders[const FortuneCellCoord(2, 1)]?.top, isNull);
    expect(topBorders[const FortuneCellCoord(1, 1)]?.bottom, isNull);

    final bottomBorders = FortuneBorderCompute.compute(
      sheetFor('border-bottom'),
    );
    expect(bottomBorders[const FortuneCellCoord(2, 2)]?.bottom, isNotNull);
    expect(bottomBorders[const FortuneCellCoord(1, 2)]?.bottom, isNull);

    final leftBorders = FortuneBorderCompute.compute(sheetFor('border-left'));
    expect(leftBorders[const FortuneCellCoord(1, 1)]?.left, isNotNull);
    expect(leftBorders[const FortuneCellCoord(1, 2)]?.left, isNull);

    final rightBorders = FortuneBorderCompute.compute(sheetFor('border-right'));
    expect(rightBorders[const FortuneCellCoord(2, 2)]?.right, isNotNull);
    expect(rightBorders[const FortuneCellCoord(2, 1)]?.right, isNull);
  });

  test('later border info overwrites the same cell side', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-top',
          color: Color(0xff111111),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-top',
          color: Color(0xff222222),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(
      borders[const FortuneCellCoord(0, 0)]?.top?.color,
      const Color(0xff222222),
    );
    expect(borders[const FortuneCellCoord(0, 0)]?.top?.style, 13);
  });

  test('range border info preserves per-entry stroke width', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff111111),
          style: 8,
          strokeWidth: 2,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff111111),
          style: 8,
          strokeWidth: 4,
          ranges: [
            FortuneRange(rowStart: 2, rowEnd: 2, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)]?.top?.style, 8);
    expect(borders[const FortuneCellCoord(0, 0)]?.top?.strokeWidth, 2);
    expect(borders[const FortuneCellCoord(2, 0)]?.top?.style, 8);
    expect(borders[const FortuneCellCoord(2, 0)]?.top?.strokeWidth, 4);
  });

  test('edge borders update already computed adjacent cell sides', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-top',
          color: Color(0xff111111),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-left',
          color: Color(0xff222222),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 1, columnEnd: 1),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-top',
          color: Color(0xff333333),
          style: 7,
          ranges: [
            FortuneRange(rowStart: 1, rowEnd: 1, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 1)]?.left?.style, 13);
    expect(borders[const FortuneCellCoord(0, 0)]?.right?.style, 13);
    expect(borders[const FortuneCellCoord(1, 0)]?.top?.style, 7);
    expect(borders[const FortuneCellCoord(0, 0)]?.bottom?.style, 7);
  });

  test('outside border applies only range perimeter', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: [
        const FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-outside',
          color: Color(0xff0188fb),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 1, rowEnd: 2, columnStart: 1, columnEnd: 2),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(
      borders[const FortuneCellCoord(1, 1)]?.top?.color,
      const Color(0xff0188fb),
    );
    expect(borders[const FortuneCellCoord(1, 1)]?.left, isNotNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.right, isNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.bottom, isNull);
    expect(borders[const FortuneCellCoord(2, 2)]?.right, isNotNull);
    expect(borders[const FortuneCellCoord(2, 2)]?.bottom, isNotNull);
  });

  test('inside border applies interior edges', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: [
        const FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-inside',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)]?.right, isNotNull);
    expect(borders[const FortuneCellCoord(0, 0)]?.bottom, isNotNull);
    expect(borders[const FortuneCellCoord(0, 0)]?.top, isNull);
    expect(borders[const FortuneCellCoord(0, 0)]?.left, isNull);
  });

  test('horizontal and vertical borders apply only shared range edges', () {
    final horizontalSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-horizontal',
          color: Color(0xff00ffff),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
    );
    final horizontalBorders = FortuneBorderCompute.compute(horizontalSheet);

    expect(horizontalBorders[const FortuneCellCoord(0, 0)]?.bottom, isNotNull);
    expect(horizontalBorders[const FortuneCellCoord(1, 0)]?.top, isNotNull);
    expect(horizontalBorders[const FortuneCellCoord(0, 0)]?.top, isNull);
    expect(horizontalBorders[const FortuneCellCoord(0, 0)]?.right, isNull);
    expect(horizontalBorders[const FortuneCellCoord(0, 1)]?.left, isNull);

    final verticalSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-vertical',
          color: Color(0xffff00ff),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
    );
    final verticalBorders = FortuneBorderCompute.compute(verticalSheet);

    expect(verticalBorders[const FortuneCellCoord(0, 0)]?.right, isNotNull);
    expect(verticalBorders[const FortuneCellCoord(0, 1)]?.left, isNotNull);
    expect(verticalBorders[const FortuneCellCoord(0, 0)]?.left, isNull);
    expect(verticalBorders[const FortuneCellCoord(0, 0)]?.bottom, isNull);
    expect(verticalBorders[const FortuneCellCoord(1, 0)]?.top, isNull);
  });

  test('slash border applies to focused cell only', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-slash',
          color: Color(0xffcc00cc),
          style: 5,
          ranges: [
            FortuneRange(
              rowStart: 1,
              rowEnd: 3,
              columnStart: 2,
              columnEnd: 4,
              rowFocus: 2,
              columnFocus: 3,
            ),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(
      borders[const FortuneCellCoord(2, 3)]?.slash?.color,
      const Color(0xffcc00cc),
    );
    expect(borders[const FortuneCellCoord(2, 3)]?.slash?.style, 5);
    expect(borders[const FortuneCellCoord(1, 2)]?.slash, isNull);
    expect(borders[const FortuneCellCoord(3, 4)]?.slash, isNull);
  });

  test('border-none clears previous range borders', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: [
        const FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        const FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-none',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)], isNull);
  });

  test('border-none clears only the requested range borders', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 1),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-none',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)], isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.top, isNotNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.right, isNotNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.bottom, isNotNull);
  });

  test('border-none clears adjacent perimeter sides', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff111111),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 1),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-none',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)], isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.left, isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.right?.style, 1);
  });

  test('raw cell border info applies individual cell sides in order', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': 1,
          'color': '#111111',
          'range': [
            {
              'row': [0, 0],
              'column': [0, 0],
            },
          ],
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 0,
            'col_index': 0,
            'l': {'style': 2, 'color': '#ff0000'},
            'r': {'style': 3, 'color': '#00ff00'},
            't': {'style': 4, 'color': '#0000ff'},
            'b': {'style': 5, 'color': '#123456'},
          },
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.compute(sheet);
    final cell = borders[const FortuneCellCoord(0, 0)];

    expect(cell?.left?.color, const Color(0xffff0000));
    expect(cell?.left?.style, 2);
    expect(cell?.right?.color, const Color(0xff00ff00));
    expect(cell?.right?.style, 3);
    expect(cell?.top?.color, const Color(0xff0000ff));
    expect(cell?.top?.style, 4);
    expect(cell?.bottom?.color, const Color(0xff123456));
    expect(cell?.bottom?.style, 5);
  });

  test('raw cell border info updates already computed adjacent sides', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': 1,
          'color': '#111111',
          'range': [
            {
              'row': [0, 0],
              'column': [0, 0],
            },
          ],
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 0,
            'col_index': 1,
            'l': {'style': 7, 'color': '#abcdef'},
          },
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 1)]?.left?.style, 7);
    expect(
      borders[const FortuneCellCoord(0, 1)]?.left?.color,
      const Color(0xffabcdef),
    );
    expect(borders[const FortuneCellCoord(0, 0)]?.right?.style, 7);
    expect(
      borders[const FortuneCellCoord(0, 0)]?.right?.color,
      const Color(0xffabcdef),
    );
  });

  test('raw cell border info without sides deletes computed cell borders', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': 1,
          'color': '#111111',
          'range': [
            {
              'row': [0, 0],
              'column': [0, 0],
            },
          ],
        },
        {
          'rangeType': 'cell',
          'value': {'row_index': 0, 'col_index': 0},
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)], isNull);
  });

  test('non-range border info is ignored', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'cell',
          borderType: 'border-all',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    expect(FortuneBorderCompute.compute(sheet), isEmpty);
  });

  test('range compute clips perimeter borders to dataset bounds', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-right',
          color: Color(0xff123456),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 2, columnStart: 0, columnEnd: 5),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-bottom',
          color: Color(0xff654321),
          style: 7,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 5, columnStart: 0, columnEnd: 2),
          ],
        ),
      ],
    );

    final borders = getBorderInfoComputeRange(sheet, 0, 2, 0, 2);

    expect(
      borders[const FortuneCellCoord(0, 2)]?.right?.color,
      const Color(0xff123456),
    );
    expect(borders[const FortuneCellCoord(0, 2)]?.right?.style, 13);
    expect(borders[const FortuneCellCoord(0, 5)]?.right, isNull);
    expect(
      borders[const FortuneCellCoord(2, 0)]?.bottom?.color,
      const Color(0xff654321),
    );
    expect(borders[const FortuneCellCoord(2, 0)]?.bottom?.style, 7);
    expect(borders[const FortuneCellCoord(5, 0)]?.bottom, isNull);
  });

  test('hidden rows are skipped when computing borders', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenRows: {1},
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-right',
          color: Color(0xff123456),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 2, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 1)]?.right?.style, 13);
    expect(borders[const FortuneCellCoord(1, 1)]?.right, isNull);
    expect(borders[const FortuneCellCoord(2, 1)]?.right?.style, 13);
  });

  test('hidden row borders do not update adjacent visible cell sides', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenRows: {1},
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff111111),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-top',
          color: Color(0xff777777),
          style: 7,
          ranges: [
            FortuneRange(rowStart: 1, rowEnd: 1, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(1, 0)], isNull);
    expect(borders[const FortuneCellCoord(0, 0)]?.bottom?.style, 1);
  });

  test('border-none skips hidden rows before clearing adjacent sides', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenRows: {1},
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff111111),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-none',
          color: Color(0xff000000),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 1, rowEnd: 1, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)]?.bottom?.style, 1);
  });

  test('hidden rows are skipped for raw cell borders', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenRows: {1},
      rawBorderInfo: [
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 0,
            'col_index': 0,
            'r': {'style': 2, 'color': '#123456'},
          },
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 1,
            'col_index': 0,
            'r': {'style': 3, 'color': '#654321'},
          },
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.computeRange(
      sheet,
      const FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 0),
    );

    expect(borders[const FortuneCellCoord(0, 0)]?.right?.style, 2);
    expect(borders[const FortuneCellCoord(1, 0)]?.right, isNull);
  });

  test('merged cells suppress internal borders', () {
    final cells = {
      const FortuneCellCoord(0, 0): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0, rowSpan: 2, columnSpan: 2),
      ),
      const FortuneCellCoord(0, 1): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
      const FortuneCellCoord(1, 0): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
      const FortuneCellCoord(1, 1): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
    };
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: cells,
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff123456),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)]?.top?.style, 13);
    expect(borders[const FortuneCellCoord(0, 0)]?.left?.style, 13);
    expect(borders[const FortuneCellCoord(0, 0)]?.right, isNull);
    expect(borders[const FortuneCellCoord(0, 0)]?.bottom, isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.left, isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.right?.style, 13);
    expect(borders[const FortuneCellCoord(1, 0)]?.top, isNull);
    expect(borders[const FortuneCellCoord(1, 0)]?.bottom?.style, 13);
    expect(borders[const FortuneCellCoord(1, 1)]?.top, isNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.left, isNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.right?.style, 13);
    expect(borders[const FortuneCellCoord(1, 1)]?.bottom?.style, 13);
  });

  test('raw range borders suppress merged cell internals', () {
    final cells = {
      const FortuneCellCoord(0, 0): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0, rowSpan: 2, columnSpan: 2),
      ),
      const FortuneCellCoord(0, 1): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
      const FortuneCellCoord(1, 0): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
      const FortuneCellCoord(1, 1): const FortuneCell(
        merge: FortuneCellMerge(row: 0, column: 0),
      ),
    };
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: cells,
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': 13,
          'color': '#123456',
          'range': [
            {
              'row': [0, 1],
              'column': [0, 1],
            },
          ],
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.compute(sheet);

    expect(borders[const FortuneCellCoord(0, 0)]?.top?.style, 13);
    expect(borders[const FortuneCellCoord(0, 0)]?.right, isNull);
    expect(borders[const FortuneCellCoord(0, 1)]?.left, isNull);
    expect(borders[const FortuneCellCoord(1, 0)]?.top, isNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.left, isNull);
    expect(borders[const FortuneCellCoord(1, 1)]?.bottom?.style, 13);
  });

  test('raw range borders clip and normalize numeric metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': '2',
          'color': '#abc',
          'range': [
            {
              'row': [-1.0, 1.0],
              'column': ['0', '2'],
            },
          ],
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': '0',
            'col_index': 1.0,
            'r': {'style': 3.5, 'color': const Color(0xff112233)},
          },
        },
      ],
      hasRawBorderInfo: true,
    );

    final borders = FortuneBorderCompute.computeRange(
      sheet,
      const FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 1, columnEnd: 1),
    );
    final cell = borders[const FortuneCellCoord(0, 1)];

    expect(borders.keys, [const FortuneCellCoord(0, 1)]);
    expect(cell?.top?.color, const Color(0xffaabbcc));
    expect(cell?.top?.style, 2);
    expect(cell?.left?.style, 2);
    expect(cell?.right?.color, const Color(0xff112233));
    expect(cell?.right?.style, 3);
  });
}
