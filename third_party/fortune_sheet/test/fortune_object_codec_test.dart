import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_codec.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';

void main() {
  test('line and fortune shape codec round-trips canonical values', () {
    final source = <String, Object?>{
      'id': 'sheet-1',
      'name': 'Objects',
      'lines': [
        {
          'id': 'line_1',
          'x1': 10,
          'y1': 20,
          'x2': 30,
          'y2': 40,
          'strokeStyle': 'dashDot',
          'strokeWidthMm': 0.7,
          'strokeColor': '#AABBCC',
          'zOrder': 3,
        },
      ],
      'fortuneShapes': [
        {
          'id': 'shape_1',
          'kind': 'roundedRectangle',
          'left': 1,
          'top': 2,
          'width': 100,
          'height': 50,
          'rotationDegrees': 45,
          'strokeStyle': 'dotted',
          'strokeWidthMm': 0.5,
          'strokeColor': '#112233',
          'fillColor': '#DDEEFF',
          'cornerRadiusMm': 4,
          'zOrder': 4,
        },
      ],
    };

    final sheet = FortuneSheetCodec.sheetFromJson(source);
    final json = FortuneSheetCodec.sheetToJson(sheet);

    expect(sheet.lines.single.strokeStyle, FortuneStrokeStyle.dashDot);
    expect(sheet.shapes.single.kind, FortuneShapeKind.roundedRectangle);
    expect(sheet.shapes.single.fillColor, '#DDEEFF');
    expect(json['lines'], source['lines']);
    expect(json['fortuneShapes'], source['fortuneShapes']);
    expect(sheet.extraFields, isNot(contains('lines')));
    expect(sheet.extraFields, isNot(contains('fortuneShapes')));
  });

  test('typed object encoder canonicalizes non-finite z-order', () {
    final json = FortuneSheetCodec.sheetToJson(
      FortuneSheet(
        id: 'sheet-1',
        name: 'Objects',
        lines: const [
          FortuneLine(
            id: 'line_1',
            x1: 0,
            y1: 0,
            x2: 10,
            y2: 0,
            zOrder: double.nan,
          ),
        ],
        shapes: const [
          FortuneShape(
            id: 'shape_1',
            kind: FortuneShapeKind.rectangle,
            left: 0,
            top: 0,
            width: 10,
            height: 10,
            zOrder: double.infinity,
          ),
        ],
      ),
    );

    expect(((json['lines'] as List).single as Map)['zOrder'], 0);
    expect(((json['fortuneShapes'] as List).single as Map)['zOrder'], 0);
  });

  test('typed shape encoder canonicalizes direct model geometry and style', () {
    final json = FortuneSheetCodec.sheetToJson(
      FortuneSheet(
        id: 'sheet-1',
        name: 'Objects',
        shapes: const [
          FortuneShape(
            id: 'shape_1',
            kind: FortuneShapeKind.roundedRectangle,
            left: 30,
            top: 20,
            width: -20,
            height: -10,
            rotationDegrees: 405,
            strokeWidthMm: 99,
            strokeColor: 'invalid',
            fillColor: 'invalid',
            cornerRadiusMm: 99,
          ),
        ],
      ),
    );
    final encoded = (json['fortuneShapes'] as List).single as Map;

    expect(encoded['left'], 10);
    expect(encoded['top'], 10);
    expect(encoded['width'], 20);
    expect(encoded['height'], 10);
    expect(encoded['rotationDegrees'], 45);
    expect(encoded['strokeWidthMm'], 0.5);
    expect(encoded['strokeColor'], '#000000');
    expect(encoded['fillColor'], isNull);
    expect(encoded['cornerRadiusMm'], 2);
    expect(
      FortuneSheetCodec.sheetFromJson(json).shapes.single.width,
      20,
    );
  });

  test('object codec canonicalizes invalid values and reserved duplicate ids', () {
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 'sheet-1',
      'name': 'Objects',
      'lines': [
        {
          'id': ' line ',
          'x1': 0,
          'y1': 0,
          'x2': 10,
          'y2': 10,
          'strokeStyle': 'unknown',
          'strokeWidthMm': 99,
          'strokeColor': '#aAbBcC',
          'zOrder': double.infinity,
        },
        {
          'id': 'line',
          'x1': 1,
          'y1': 1,
          'x2': 2,
          'y2': 2,
          'strokeStyle': 'solid',
          'strokeWidthMm': 0.5,
          'strokeColor': '#000000',
          'zOrder': 1,
        },
        {
          'id': 'line__2',
          'x1': 2,
          'y1': 2,
          'x2': 3,
          'y2': 3,
          'strokeStyle': 'solid',
          'strokeWidthMm': 0.5,
          'strokeColor': '#000000',
          'zOrder': 2,
        },
      ],
      'fortuneShapes': [
        {
          'id': 'round',
          'kind': 'roundedRectangle',
          'left': 0,
          'top': 0,
          'width': 10,
          'height': 10,
          'rotationDegrees': 405,
          'strokeStyle': 'solid',
          'strokeWidthMm': 0.5,
          'strokeColor': '#000000',
          'fillColor': '#RGB',
          'cornerRadiusMm': 99,
          'zOrder': 1,
        },
      ],
    });

    expect(sheet.lines.map((line) => line.id), ['line', 'line__3', 'line__2']);
    expect(sheet.lines.first.strokeStyle, FortuneStrokeStyle.solid);
    expect(sheet.lines.first.strokeWidthMm, 0.5);
    expect(sheet.lines.first.strokeColor, '#AABBCC');
    expect(sheet.lines.first.zOrder, 0);
    expect(sheet.shapes.single.rotationDegrees, 45);
    expect(sheet.shapes.single.fillColor, isNull);
    expect(sheet.shapes.single.cornerRadiusMm, 2);

    final json = FortuneSheetCodec.sheetToJson(sheet);
    final firstLine = (json['lines']! as List).first as Map;
    final shape = (json['fortuneShapes']! as List).single as Map;
    expect(firstLine['id'], 'line');
    expect(firstLine['strokeStyle'], 'solid');
    expect(firstLine['strokeWidthMm'], 0.5);
    expect(firstLine['strokeColor'], '#AABBCC');
    expect(firstLine['zOrder'], 0);
    expect(shape['rotationDegrees'], 45);
    expect(shape['fillColor'], isNull);
    expect(shape['cornerRadiusMm'], 2);
  });

  test('sheet copyWith preserves unrelated raw and clears replaced typed raw', () {
    final rawLines = <Object?>[
      {
        'id': 'line_1',
        'x1': 0,
        'y1': 0,
        'x2': 1,
        'y2': 1,
        'strokeStyle': 'solid',
        'strokeWidthMm': 0.5,
        'strokeColor': '#000000',
        'zOrder': 0,
      },
    ];
    final sheet = FortuneSheetCodec.sheetFromJson({
      'id': 'sheet-1',
      'name': 'Objects',
      'lines': rawLines,
      'fortuneShapes': <Object?>[],
    });
    final renamed = sheet.copyWith(name: 'Renamed');
    final replaced = sheet.copyWith(lines: const <FortuneLine>[]);
    (rawLines.single! as Map)['id'] = 'mutated';

    expect(renamed.hasRawLines, isTrue);
    expect((renamed.rawLines! as List).single, containsPair('id', 'line_1'));
    expect(renamed.hasRawFortuneShapes, isTrue);
    expect(replaced.lines, isEmpty);
    expect(replaced.hasRawLines, isFalse);
    expect(replaced.rawLines, isNull);
    expect(FortuneSheetCodec.sheetToJson(replaced), isNot(contains('lines')));
    expect(FortuneSheet(id: 'plain', name: 'Plain').lines, isEmpty);
    expect(FortuneSheet(id: 'plain', name: 'Plain').shapes, isEmpty);
  });
}