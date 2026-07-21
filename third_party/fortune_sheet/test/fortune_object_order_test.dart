import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  test('typed object paint order uses finite z order and source sequence', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      images: const [
        FortuneImage(
          id: 'image-storage',
          src: 'image',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          extraFields: {
            fortuneImageObjectIdExtraKey: 'same',
            fortuneSheetObjectZOrderExtraKey: double.infinity,
          },
        ),
        FortuneImage(
          id: 'barcode-storage',
          src: 'barcode',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          extraFields: {
            'fortuneBarcode': true,
            fortuneBarcodeObjectIdExtraKey: 'same',
            fortuneSheetObjectZOrderExtraKey: 2,
          },
        ),
      ],
      lines: const [
        FortuneLine(id: 'same', x1: 0, y1: 0, x2: 1, y2: 1, zOrder: 2),
      ],
      shapes: const [
        FortuneShape(
          id: 'same',
          kind: FortuneShapeKind.rectangle,
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          zOrder: 2,
        ),
      ],
    );

    final objects = fortuneSheetObjectsInPaintOrder(sheet);

    expect(objects.map((object) => object.zOrder), [0, 2, 2, 2]);
    expect(objects.map((object) => object.key.kind), [
      FortuneSheetObjectKind.image,
      FortuneSheetObjectKind.barcode,
      FortuneSheetObjectKind.line,
      FortuneSheetObjectKind.rectangle,
    ]);
    expect(objects.map((object) => object.key.id), everyElement('same'));
    expect(objects.map((object) => object.sourceIndex), [0, 1, 2, 3]);
    expect(objects.map((object) => object.key).toSet(), hasLength(4));
  });

  test('typed object allocator uses the smallest free kind suffix', () {
    const existing = [
      FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
      FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_3'),
      FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'line_2'),
    ];

    expect(
      fortuneAllocateObjectId(FortuneSheetObjectKind.line, existing),
      'line_2',
    );
    expect(
      fortuneAllocateObjectId(
        FortuneSheetObjectKind.line,
        existing,
        reserved: const ['line_2'],
      ),
      'line_4',
    );
    expect(
      fortuneAllocateObjectId(FortuneSheetObjectKind.roundedRectangle, existing),
      'roundRect_1',
    );
  });

  test('object z order reservation rebases when finite headroom is exhausted', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      images: const [
        FortuneImage(
          id: 'storage-image',
          src: 'image',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          extraFields: {
            fortuneImageObjectIdExtraKey: 'image_1',
            fortuneSheetObjectZOrderExtraKey: double.maxFinite,
          },
        ),
      ],
      rawImages: const [
        {'id': 'storage-image', 'zOrder': double.maxFinite},
      ],
      hasRawImages: true,
      lines: const [
        FortuneLine(
          id: 'line_1',
          x1: 0,
          y1: 0,
          x2: 1,
          y2: 1,
          zOrder: 1,
        ),
      ],
      rawLines: const [
        {'id': 'line_1', 'zOrder': 1},
      ],
      hasRawLines: true,
      shapes: const [
        FortuneShape(
          id: 'rect_1',
          kind: FortuneShapeKind.rectangle,
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          zOrder: 2,
        ),
      ],
      rawFortuneShapes: const [
        {'id': 'rect_1', 'zOrder': 2},
      ],
      hasRawFortuneShapes: true,
    );

    final plan = fortuneReserveObjectZOrders(sheet, 2);

    expect(plan.rebased, isTrue);
    expect(plan.zOrders, [4, 5]);
    expect(plan.sheet.images.map((image) => image.id), ['storage-image']);
    expect(plan.sheet.lines.map((line) => line.id), ['line_1']);
    expect(plan.sheet.shapes.map((shape) => shape.id), ['rect_1']);
    expect(
      fortuneSheetObjectsInPaintOrder(
        plan.sheet,
      ).map((object) => object.zOrder),
      [1, 2, 3],
    );
    expect(plan.sheet.hasRawImages, isFalse);
    expect(plan.sheet.hasRawLines, isTrue);
    expect(plan.sheet.hasRawFortuneShapes, isTrue);
  });

  test('object z order reservation preserves untouched raw kinds', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      images: const [
        FortuneImage(
          id: 'storage-image',
          src: 'image',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
          extraFields: {
            fortuneImageObjectIdExtraKey: 'image_1',
            fortuneSheetObjectZOrderExtraKey: 1,
          },
        ),
      ],
      rawImages: const [
        {'id': 'storage-image', 'zOrder': 1},
      ],
      hasRawImages: true,
      lines: const [
        FortuneLine(
          id: 'line_1',
          x1: 0,
          y1: 0,
          x2: 1,
          y2: 1,
          zOrder: double.maxFinite,
        ),
      ],
      rawLines: const [
        {'id': 'line_1', 'zOrder': double.maxFinite},
      ],
      hasRawLines: true,
    );

    final plan = fortuneReserveObjectZOrders(sheet, 1);

    expect(plan.rebased, isTrue);
    expect(plan.zOrders, [3]);
    expect(plan.sheet.hasRawImages, isTrue);
    expect(plan.sheet.hasRawLines, isFalse);
    expect(fortuneImageZOrder(plan.sheet.images.single), 1);
    expect(plan.sheet.lines.single.zOrder, 2);
  });

  test('typed object hit test returns the frontmost exact key', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      lines: const [
        FortuneLine(id: 'same', x1: 0, y1: 10, x2: 30, y2: 10, zOrder: 1),
      ],
      shapes: const [
        FortuneShape(
          id: 'same',
          kind: FortuneShapeKind.rectangle,
          left: 0,
          top: 0,
          width: 30,
          height: 20,
          fillColor: '#FFFFFF',
          zOrder: 2,
        ),
      ],
    );

    expect(
      fortuneSheetObjectKeyAtLogicalPosition(sheet, const Offset(15, 10)),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'same'),
    );
  });

  test('empty shape interior passes through to a lower object', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      lines: const [
        FortuneLine(id: 'line_1', x1: 0, y1: 10, x2: 30, y2: 10, zOrder: 1),
      ],
      shapes: const [
        FortuneShape(
          id: 'rect_1',
          kind: FortuneShapeKind.rectangle,
          left: 0,
          top: 0,
          width: 30,
          height: 20,
          zOrder: 2,
        ),
      ],
    );

    expect(
      fortuneSheetObjectKeyAtLogicalPosition(sheet, const Offset(15, 10)),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
  });

  test('rotated filled shape hit test uses inverse rotation', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Objects',
      shapes: const [
        FortuneShape(
          id: 'rect_1',
          kind: FortuneShapeKind.rectangle,
          left: 0,
          top: 0,
          width: 20,
          height: 10,
          rotationDegrees: 90,
          fillColor: '#FFFFFF',
        ),
      ],
    );

    expect(
      fortuneSheetObjectKeyAtLogicalPosition(sheet, const Offset(10, 12)),
      const FortuneSheetObjectKey(FortuneSheetObjectKind.rectangle, 'rect_1'),
    );
    expect(
      fortuneSheetObjectKeyAtLogicalPosition(sheet, const Offset(25, 5)),
      isNull,
    );
  });
}