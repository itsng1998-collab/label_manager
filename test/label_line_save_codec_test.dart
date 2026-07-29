import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';

void main() {
  test('label save features append lines and fortune shapes', () {
    final lineVersion = labelSheetSaveFeatureVersions['sheet.lines'];
    final shapeVersion = labelSheetSaveFeatureVersions['sheet.fortuneShapes'];

    expect(lineVersion, isNotNull);
    expect(shapeVersion, lineVersion! + 1);
    expect(shapeVersion, labelSheetSaveFormatVersion);
  });

  test('label save sanitizer keeps only typed object allow-list fields', () {
    final sanitized = labelSheetSanitizeWorkbookSaveJson({
      'data': [
        {
          'id': 's1',
          'name': 'Objects',
          'lines': [
            {
              'id': 'line_1',
              'x1': 1,
              'y1': 2,
              'x2': 3,
              'y2': 4,
              'strokeStyle': 'solid',
              'strokeWidthMm': 0.5,
              'strokeColor': '#000000',
              'zOrder': 1,
              'unsupported': true,
            },
          ],
          'fortuneShapes': [
            {
              'id': 'shape_1',
              'kind': 'ellipse',
              'left': 1,
              'top': 2,
              'width': 3,
              'height': 4,
              'rotationDegrees': 0,
              'strokeStyle': 'dashed',
              'strokeWidthMm': 0.5,
              'strokeColor': '#000000',
              'fillColor': null,
              'cornerRadiusMm': 0,
              'zOrder': 2,
              'unsupported': true,
            },
          ],
        },
      ],
    });
    final sheet = (sanitized['data']! as List).single as Map;
    final line = (sheet['lines']! as List).single as Map;
    final shape = (sheet['fortuneShapes']! as List).single as Map;

    expect(line, isNot(contains('unsupported')));
    expect(shape, isNot(contains('unsupported')));
    expect(line['strokeStyle'], 'solid');
    expect(shape['kind'], 'ellipse');
  });

  test('manifest feature absence does not remove typed object payload', () {
    final migrated = labelSheetMigrateWorkbookSaveJson(
      {
        'data': [
          {
            'id': 's1',
            'name': 'Objects',
            'lines': [
              {'id': 'line_1', 'x1': 1, 'y1': 2, 'x2': 3, 'y2': 4},
            ],
            'fortuneShapes': [
              {
                'id': 'shape_1',
                'kind': 'rectangle',
                'left': 1,
                'top': 2,
                'width': 3,
                'height': 4,
              },
            ],
          },
        ],
      },
      manifest: const {'version': 1, 'features': <String, Object?>{}},
    );
    final sheet = (migrated['data']! as List).single as Map;

    expect(sheet['lines'], isA<List>());
    expect(sheet['fortuneShapes'], isA<List>());
  });

  test('legacy shapes strict clone omits only invalid overlay', () {
    final cycle = <Object?>[];
    cycle.add(cycle);
    final invalid = labelSheetSanitizeWorkbookSaveJson({
      'data': [
        {
          'id': 's1',
          'name': 'Invalid overlay',
          'shapes': {'validSibling': true, 'cycle': cycle},
          'lines': <Object?>[],
        },
      ],
    });
    final invalidSheet = (invalid['data']! as List).single as Map;

    expect(invalidSheet, isNot(contains('shapes')));
    expect(invalidSheet['lines'], isEmpty);

    final shared = <String, Object?>{'label': 'shared', 'value': null};
    final valid = labelSheetSanitizeWorkbookSaveJson({
      'data': [
        {
          'id': 's2',
          'name': 'Valid overlay',
          'shapes': {'first': shared, 'second': shared},
        },
      ],
    });
    final validSheet = (valid['data']! as List).single as Map;

    expect(validSheet['shapes'], {
      'first': {'label': 'shared', 'value': null},
      'second': {'label': 'shared', 'value': null},
    });
  });

  test('save normalization retains typed line and shape models', () {
    final normalized = labelSheetNormalizeWorkbookForCurrentSaveFormat(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Objects',
            lines: const [
              FortuneLine(id: 'line_1', x1: 1, y1: 2, x2: 3, y2: 4),
            ],
            shapes: const [
              FortuneShape(
                id: 'shape_1',
                kind: FortuneShapeKind.rectangle,
                left: 1,
                top: 2,
                width: 3,
                height: 4,
              ),
            ],
          ),
        ],
      ),
    );

    expect(normalized.activeSheet.lines.single.id, 'line_1');
    expect(normalized.activeSheet.shapes.single.id, 'shape_1');
  });

  test(
    'print area keeps intersecting typed geometry and expands its bounds',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Objects',
            rowHeights: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
            columnWidths: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
            lines: const [
              FortuneLine(id: 'crossing-line', x1: 10, y1: 10, x2: 70, y2: 10),
              FortuneLine(
                id: 'outside-line',
                x1: 80,
                y1: 80,
                x2: 100,
                y2: 100,
                strokeStyle: FortuneStrokeStyle.dashed,
              ),
            ],
            shapes: const [
              FortuneShape(
                id: 'containing-fill',
                kind: FortuneShapeKind.rectangle,
                left: -10,
                top: -10,
                width: 80,
                height: 80,
                fillColor: '#FFFFFF',
                rotationDegrees: 15,
              ),
              FortuneShape(
                id: 'outside-shape',
                kind: FortuneShapeKind.ellipse,
                left: 90,
                top: 90,
                width: 10,
                height: 10,
              ),
            ],
            extraFields: const {
              fortuneSheetGridClientWidthMmKey: 10,
              fortuneSheetGridClientHeightMmKey: 10,
            },
          ),
        ],
      );

      final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

      expect(saved.lines.map((line) => line.id), ['crossing-line']);
      expect(saved.shapes.map((shape) => shape.id), ['containing-fill']);
      expect(saved.columnCount, greaterThan(2));
      expect(saved.rowCount, greaterThan(2));
    },
  );

  test('print area keeps a stroke that only touches its boundary', () {
    const printSizeMm = 10.0;
    const strokeWidthMm = 0.5;
    final printRight = fortuneMillimetersToLogicalPixels(printSizeMm);
    final halfStroke = fortuneMillimetersToLogicalPixels(strokeWidthMm) / 2;
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Boundary touch',
          rowHeights: const {0: 20, 1: 20},
          columnWidths: const {0: 20, 1: 20, 2: 20},
          lines: [
            FortuneLine(
              id: 'touching-line',
              x1: printRight + halfStroke,
              y1: 5,
              x2: printRight + halfStroke,
              y2: 25,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.lines.map((line) => line.id), ['touching-line']);
  });

  test(
    'print area excludes objects outside physical extent in a wide cell',
    () {
      const printSizeMm = 10.0;
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Physical extent',
            rowHeights: const {0: 100},
            columnWidths: const {0: 100},
            lines: const [
              FortuneLine(
                id: 'outside-physical-width',
                x1: 50,
                y1: 5,
                x2: 50,
                y2: 25,
              ),
            ],
            extraFields: const {
              fortuneSheetGridClientWidthMmKey: printSizeMm,
              fortuneSheetGridClientHeightMmKey: printSizeMm,
            },
          ),
        ],
      );

      final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

      expect(saved.lines, isEmpty);
    },
  );

  test('print area excludes the inflated corner beyond a butt line cap', () {
    const printSizeMm = 10.0;
    const strokeWidthMm = 2.0;
    final printExtent = fortuneMillimetersToLogicalPixels(printSizeMm);
    final radius = fortuneMillimetersToLogicalPixels(strokeWidthMm) / 2;
    final start = Offset(
      printExtent + radius * 0.8,
      printExtent + radius * 0.8,
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Butt cap',
          rowHeights: const {0: 100},
          columnWidths: const {0: 100},
          lines: [
            FortuneLine(
              id: 'outside-butt-cap',
              x1: start.dx,
              y1: start.dy,
              x2: start.dx + 20,
              y2: start.dy,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.lines, isEmpty);
  });

  test('print area keeps a rotated rectangle miter tip', () {
    const printSizeMm = 10.0;
    const strokeWidthMm = 2.0;
    final printExtent = fortuneMillimetersToLogicalPixels(printSizeMm);
    final radius = fortuneMillimetersToLogicalPixels(strokeWidthMm) / 2;
    final corner = Offset(printExtent + 1.2 * radius, printExtent / 2);
    const side = 20.0;
    final center = Offset(corner.dx + side / math.sqrt2, corner.dy);
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Miter tip',
          rowHeights: const {0: 100},
          columnWidths: const {0: 100},
          shapes: [
            FortuneShape(
              id: 'touching-miter',
              kind: FortuneShapeKind.rectangle,
              left: center.dx - side / 2,
              top: center.dy - side / 2,
              width: side,
              height: side,
              rotationDegrees: 45,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.shapes.map((shape) => shape.id), ['touching-miter']);
  });

  test('print area keeps a patterned rectangle corner miter', () {
    const printSizeMm = 26;
    final printExtent = fortuneMillimetersToLogicalPixels(printSizeMm);
    final strokeWidthMm = fortuneLogicalPixelsToMillimeters(10);
    const side = 70.0;
    final centerX = printExtent + 6 + side / math.sqrt2;
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Patterned miter',
          rowHeights: const {0: 100},
          columnWidths: const {0: 100, 1: 100},
          shapes: [
            FortuneShape(
              id: 'touching-pattern-miter',
              kind: FortuneShapeKind.rectangle,
              left: centerX - side / 2,
              top: 15,
              width: side,
              height: side,
              rotationDegrees: 45,
              strokeStyle: FortuneStrokeStyle.dashed,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.shapes.map((shape) => shape.id), ['touching-pattern-miter']);
  });

  test('print area excludes an ellipse outside its rounded stroke corner', () {
    const printSizeMm = 10.0;
    const strokeWidthMm = 2.0;
    final printExtent = fortuneMillimetersToLogicalPixels(printSizeMm);
    final radius = fortuneMillimetersToLogicalPixels(strokeWidthMm) / 2;
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Ellipse corner',
          rowHeights: const {0: 100},
          columnWidths: const {0: 100},
          shapes: [
            FortuneShape(
              id: 'outside-rounded-stroke',
              kind: FortuneShapeKind.ellipse,
              left: printExtent + 0.8 * radius,
              top: printExtent + 0.8 * radius,
              width: 0.1 * radius,
              height: 0.1 * radius,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.shapes, isEmpty);
  });

  test('print area excludes a phantom terminal dot on an open line', () {
    const printSizeMm = 10.0;
    const strokeWidthMm = 1.0;
    final width = fortuneMillimetersToLogicalPixels(strokeWidthMm);
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Terminal dot',
          rowHeights: const {0: 100},
          columnWidths: const {0: 100},
          lines: [
            FortuneLine(
              id: 'phantom-terminal-dot',
              x1: -3 * width,
              y1: 0.15 * width,
              x2: 0,
              y2: 0.15 * width,
              strokeStyle: FortuneStrokeStyle.dotted,
              strokeWidthMm: strokeWidthMm,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.lines, isEmpty);
  });

  test('print area keeps a thin intersection with a rotated ellipse fill', () {
    const printSizeMm = 10.0;
    const rotationDegrees = 17.0;
    const width = 100.0;
    const height = 20.0;
    final printRight = fortuneMillimetersToLogicalPixels(printSizeMm);
    final radians = rotationDegrees * math.pi / 180;
    final horizontalExtent = math.sqrt(
      math.pow(width / 2 * math.cos(radians), 2) +
          math.pow(height / 2 * math.sin(radians), 2),
    );
    final centerX = printRight + horizontalExtent - 0.01;
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Rotated ellipse intersection',
          rowHeights: const {0: 20, 1: 20},
          columnWidths: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
          shapes: [
            FortuneShape(
              id: 'thin-fill-intersection',
              kind: FortuneShapeKind.ellipse,
              left: centerX - width / 2,
              top: 9,
              width: width,
              height: height,
              rotationDegrees: rotationDegrees,
              strokeWidthMm: 0,
              fillColor: '#FFFFFF',
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: printSizeMm,
            fortuneSheetGridClientHeightMmKey: printSizeMm,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.shapes.map((shape) => shape.id), ['thin-fill-intersection']);
  });

  test(
    'print area keeps a thin intersection with a rotated ellipse stroke',
    () {
      const printSizeMm = 10.0;
      const rotationDegrees = 17.0;
      const width = 100.0;
      const height = 20.0;
      const strokeWidthMm = 0.001;
      final printRight = fortuneMillimetersToLogicalPixels(printSizeMm);
      final halfStroke = fortuneMillimetersToLogicalPixels(strokeWidthMm) / 2;
      final radians = rotationDegrees * math.pi / 180;
      final horizontalExtent = math.sqrt(
        math.pow(width / 2 * math.cos(radians), 2) +
            math.pow(height / 2 * math.sin(radians), 2),
      );
      final centerX = printRight + horizontalExtent + halfStroke - 0.0001;
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Rotated ellipse stroke intersection',
            rowHeights: const {0: 20, 1: 20},
            columnWidths: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
            shapes: [
              FortuneShape(
                id: 'thin-stroke-intersection',
                kind: FortuneShapeKind.ellipse,
                left: centerX - width / 2,
                top: 9,
                width: width,
                height: height,
                rotationDegrees: rotationDegrees,
                strokeWidthMm: strokeWidthMm,
              ),
            ],
            extraFields: const {
              fortuneSheetGridClientWidthMmKey: printSizeMm,
              fortuneSheetGridClientHeightMmKey: printSizeMm,
            },
          ),
        ],
      );

      final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

      expect(saved.shapes.map((shape) => shape.id), [
        'thin-stroke-intersection',
      ]);
    },
  );
}
