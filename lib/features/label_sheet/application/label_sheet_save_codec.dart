import 'dart:convert';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

const String labelSheetSaveFormat = 'label-manager.sheet';
final int labelSheetSaveFormatVersion = _labelSheetSaveFeatureKeys.length;
final Map<String, int> labelSheetSaveFeatureVersions = Map.unmodifiable({
  for (var i = 0; i < _labelSheetSaveFeatureKeys.length; i += 1)
    _labelSheetSaveFeatureKeys[i]: i + 1,
});

const List<String> _labelSheetSaveFeatureKeys = [
  'workbook.core',
  'workbook.settings',
  'sheet.core',
  'sheet.config.dimensions',
  'sheet.config.merge',
  'sheet.config.border',
  'sheet.config.protection',
  'sheet.cells',
  'cell.value',
  'cell.format.base',
  'cell.format.style',
  'cell.inlineRuns',
  'cell.linksAndNotes',
  'sheet.images',
  'sheet.images.objectMetadata',
  'sheet.validationFilter',
  'sheet.formulaMetadata',
  'sheet.frozen',
  'sheet.labelMetadata',
  'sheet.images.preserveTemplateBarcodeFormat',
  'sheet.lines',
  'sheet.fortuneShapes',
];

const Set<String> _supportedWorkbookKeys = {
  'data',
  'column',
  'row',
  'addRows',
  'showToolbar',
  'showFormulaBar',
  'showSheetTabs',
  'config',
  'devicePixelRatio',
  'allowEdit',
  'lang',
  'currency',
  'forceCalculation',
  'rowHeaderWidth',
  'columnHeaderHeight',
  'defaultColWidth',
  'defaultRowHeight',
  'defaultFontSize',
  'fontFamilies',
  'toolbarItems',
  'customToolbarItems',
  'cellContextMenu',
  'headerContextMenu',
  'sheetTabContextMenu',
  'filterContextMenu',
};

const Set<String> _supportedSheetKeys = {
  'name',
  'config',
  'order',
  'color',
  'data',
  'celldata',
  'id',
  'images',
  'image',
  'lines',
  'fortuneShapes',
  'shapes',
  'zoomRatio',
  'column',
  'row',
  'addRows',
  'status',
  'hide',
  'luckysheet_select_save',
  'luckysheet_selection_range',
  'calcChain',
  'defaultRowHeight',
  'defaultColWidth',
  'showGridLines',
  'visibledatarow',
  'visibledatacolumn',
  'ch_width',
  'rh_height',
  'pivotTable',
  'isPivotTable',
  'filter',
  'filter_select',
  'luckysheet_conditionformat_save',
  'luckysheet_alternateformat_save',
  'luckysheet_alternateformat_save_modelCustom',
  'dataVerification',
  'hyperlink',
  'dynamicArray_compute',
  'dynamicArray',
  'frozen',
  fortuneSheetGridClientWidthMmKey,
  fortuneSheetGridClientHeightMmKey,
  fortuneSheetRulerVisibleKey,
  fortuneSheetRulerGuidesKey,
  'labelRtfImportSource',
};

const Set<String> _supportedSheetConfigKeys = {
  'merge',
  'rowlen',
  'columnlen',
  'rowhidden',
  'colhidden',
  'customHeight',
  'customWidth',
  'borderInfo',
  'authority',
  'rowReadOnly',
  'colReadOnly',
};

const Set<String> _supportedCellKeys = {
  'v',
  'm',
  'mc',
  'f',
  'ct',
  'qp',
  'spl',
  'bg',
  'lo',
  'rt',
  'ps',
  'hl',
  'bl',
  'it',
  'ff',
  'fs',
  'fc',
  'ht',
  'vt',
  'tb',
  'cl',
  'un',
  'tr',
  'fontScale',
  'letterSpacing',
  'lineHeight',
  'script',
  'rtfHidden',
  'rtfSmallCaps',
  'rtfAllCaps',
  'rtfUnderlineStyle',
  'rtfShadow',
};

const Set<String> _supportedMergeKeys = {'r', 'c', 'rs', 'cs'};
const Set<String> _supportedCellTypeKeys = {'fa', 't', 's'};
const Set<String> _supportedInlineRunKeys = {
  'v',
  'fc',
  'bl',
  'it',
  'cl',
  'un',
  'fs',
  'ff',
  'wrap',
  'bg',
  'script',
  'fontScale',
  'letterSpacing',
  'lineHeight',
  'rtfHidden',
  'rtfSmallCaps',
  'rtfAllCaps',
  'rtfUnderlineStyle',
  'rtfShadow',
};

const Set<String> _supportedImageKeys = {
  'id',
  'src',
  'left',
  'top',
  'width',
  'height',
  'originWidth',
  'originHeight',
  'rotation',
  'widthMm',
  'heightMm',
  'crop',
  'fortuneBarcode',
  'barcodeText',
  'barcodeFormatId',
  'barcodeFormatLabel',
  'barcodeModuleScale',
  'barcodeBarHeight',
  'barcodeLeadingText',
  'barcodeTrailingText',
  'barcodeShowText',
  'barcodeHumanReadableFontFamily',
  'barcodeHumanReadableFontSize',
  'preserveTemplateBarcodeFormat',
  fortuneImageObjectIdExtraKey,
  fortuneBarcodeObjectIdExtraKey,
  fortuneSheetObjectZOrderExtraKey,
  fortuneBarcodeBodyTopExtraKey,
  fortuneBarcodeBodyHeightExtraKey,
  fortuneBarcodeBodyRatioExtraKey,
  fortuneBarcodeIdLabelPrintExcludedExtraKey,
};

const Set<String> _supportedLineKeys = {
  'id',
  'x1',
  'y1',
  'x2',
  'y2',
  'strokeStyle',
  'strokeWidthMm',
  'strokeColor',
  'zOrder',
};

const Set<String> _supportedFortuneShapeKeys = {
  'id',
  'kind',
  'left',
  'top',
  'width',
  'height',
  'rotationDegrees',
  'strokeStyle',
  'strokeWidthMm',
  'strokeColor',
  'fillColor',
  'cornerRadiusMm',
  'zOrder',
};

const Set<String> _supportedImageCropKeys = {
  'width',
  'height',
  'offsetLeft',
  'offsetTop',
};

String labelSheetEncodeWorkbookSave(FortuneWorkbook workbook) {
  final manifest = <String, Object?>{
    'format': labelSheetSaveFormat,
    'version': labelSheetSaveFormatVersion,
    'features': labelSheetSaveFeatureVersions,
    'encoding': 'base64',
    'compression': 'zip-deflate',
    'codec': 'fortune-sheet-json',
  };
  final workbookJson = labelSheetSanitizeWorkbookSaveJson(
    FortuneSheetCodec.workbookToJson(workbook),
  );
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
    ..addFile(ArchiveFile.string('workbook.json', jsonEncode(workbookJson)));
  return base64Encode(ZipEncoder().encodeBytes(archive));
}

FortuneWorkbook labelSheetWorkbookForPrintAreaSave(FortuneWorkbook workbook) {
  final nextSheets = [
    for (final sheet in workbook.sheets) _sheetForPrintAreaSave(sheet),
  ];
  return workbook.copyWith(sheets: nextSheets);
}

FortuneSheet _sheetForPrintAreaSave(FortuneSheet sheet) {
  final physicalSize = fortuneSheetGridClientPhysicalSize(sheet);
  if (physicalSize == null) {
    return sheet.copyWith();
  }
  final logicalSize = physicalSize.logicalSize;
  final printBounds = _LabelSheetSaveBounds(
    maxRow: _lastVisibleIndexForExtent(
      logicalSize.height,
      lengthForIndex: (row) => _rowHeight(sheet, row),
    ),
    maxColumn: _lastVisibleIndexForExtent(
      logicalSize.width,
      lengthForIndex: (column) => _columnWidth(sheet, column),
    ),
  );
  var bounds = printBounds;
  bounds = _expandBoundsForCells(sheet, printBounds, bounds);
  bounds = _expandBoundsForBorders(sheet, printBounds, bounds);
  bounds = _expandBoundsForImages(sheet, printBounds, bounds);
  final typedObjects = _typedObjectsForPrintArea(
    sheet,
    ui.Rect.fromLTWH(0, 0, logicalSize.width, logicalSize.height),
    bounds,
  );
  bounds = typedObjects.bounds;
  return sheet.copyWith(
    rowCount: bounds.maxRow + 1,
    columnCount: bounds.maxColumn + 1,
    cells: {
      for (final entry in sheet.cells.entries)
        if (bounds.contains(entry.key)) entry.key: entry.value.copyWith(),
    },
    nullCells: {
      for (final coord in sheet.nullCells)
        if (bounds.contains(coord)) coord,
    },
    rowHeights: _intDoubleMapWithin(sheet.rowHeights, bounds.maxRow),
    columnWidths: _intDoubleMapWithin(sheet.columnWidths, bounds.maxColumn),
    customHeight: _intDoubleMapWithin(sheet.customHeight, bounds.maxRow),
    customWidth: _intDoubleMapWithin(sheet.customWidth, bounds.maxColumn),
    hiddenRows: sheet.hiddenRows.where((row) => row <= bounds.maxRow).toSet(),
    hiddenColumns: sheet.hiddenColumns
        .where((column) => column <= bounds.maxColumn)
        .toSet(),
    hiddenRowValues: _intObjectMapWithin(sheet.hiddenRowValues, bounds.maxRow),
    hiddenColumnValues: _intObjectMapWithin(
      sheet.hiddenColumnValues,
      bounds.maxColumn,
    ),
    borderInfo: [
      for (final border in sheet.borderInfo)
        if (_borderIntersectsBounds(border, bounds)) border.copyWith(),
    ],
    images: [
      for (final image in sheet.images)
        if (_imageIntersectsBounds(sheet, image, bounds)) image.copyWith(),
    ],
    lines: typedObjects.lines,
    shapes: typedObjects.shapes,
    dataVerification: _coordKeyMapWithin(sheet.dataVerification, bounds),
    filter: _coordKeyMapWithin(sheet.filter, bounds),
    hyperlinks: _coordKeyMapWithin(sheet.hyperlinks, bounds),
  );
}

_LabelSheetSaveBounds _expandBoundsForCells(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final entry in sheet.cells.entries) {
    final coord = entry.key;
    final cell = entry.value;
    if (!printBounds.contains(coord)) {
      continue;
    }
    final merge = cell.merge;
    if (merge != null) {
      next = next.expandTo(
        row: merge.row + merge.rowSpan - 1,
        column: merge.column + merge.columnSpan - 1,
      );
    }
    if (cell.renderedText.isEmpty) {
      continue;
    }
    final textExtent = _estimatedCellTextExtent(sheet, coord, cell);
    next = next.expandTo(row: textExtent.maxRow, column: textExtent.maxColumn);
  }
  return next;
}

_LabelSheetSaveBounds _expandBoundsForBorders(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final border in sheet.borderInfo) {
    for (final range in border.ranges) {
      if (!_rangeIntersectsBounds(range, printBounds)) {
        continue;
      }
      next = next.expandTo(row: range.rowEnd, column: range.columnEnd);
    }
  }
  return next;
}

_LabelSheetSaveBounds _expandBoundsForImages(
  FortuneSheet sheet,
  _LabelSheetSaveBounds printBounds,
  _LabelSheetSaveBounds currentBounds,
) {
  var next = currentBounds;
  for (final image in sheet.images) {
    if (!_imageIntersectsBounds(sheet, image, printBounds)) {
      continue;
    }
    next = next.expandTo(
      row: _lastIndexForPosition(
        image.top + image.height,
        lengthForIndex: (row) => _rowHeight(sheet, row),
      ),
      column: _lastIndexForPosition(
        image.left + image.width,
        lengthForIndex: (column) => _columnWidth(sheet, column),
      ),
    );
  }
  return next;
}

({
  _LabelSheetSaveBounds bounds,
  List<FortuneLine> lines,
  List<FortuneShape> shapes,
})
_typedObjectsForPrintArea(
  FortuneSheet sheet,
  ui.Rect printRect,
  _LabelSheetSaveBounds currentBounds,
) {
  var nextBounds = currentBounds;
  final lines = <FortuneLine>[];
  final shapes = <FortuneShape>[];
  for (final line in sheet.lines) {
    final path = ui.Path()
      ..moveTo(line.x1, line.y1)
      ..lineTo(line.x2, line.y2);
    final strokeWidth = fortuneMillimetersToLogicalPixels(line.strokeWidthMm);
    if (!_strokeLineIntersectsRect(
      ui.Offset(line.x1, line.y1),
      ui.Offset(line.x2, line.y2),
      line.strokeStyle,
      strokeWidth,
      printRect,
    )) {
      continue;
    }
    lines.add(line.copyWith());
    nextBounds = _expandBoundsForLogicalRect(
      sheet,
      nextBounds,
      path.getBounds().inflate(strokeWidth / 2),
    );
  }
  for (final shape in sheet.shapes) {
    final path = _fortuneShapeLogicalPath(shape);
    final strokeWidth = fortuneMillimetersToLogicalPixels(shape.strokeWidthMm);
    final fillIntersects =
        shape.fillColor != null && _filledShapeIntersectsRect(shape, printRect);
    final strokeIntersects = shape.strokeStyle == FortuneStrokeStyle.solid
        ? _solidShapeStrokeIntersectsRect(shape, path, strokeWidth, printRect)
        : _strokePathIntersectsRect(
                path,
                shape.strokeStyle,
                strokeWidth,
                printRect,
              ) ||
              shape.kind == FortuneShapeKind.rectangle &&
                  _patternedRectangleMiterIntersectsRect(
                    shape,
                    strokeWidth,
                    printRect,
                  );
    if (!fillIntersects && !strokeIntersects) {
      continue;
    }
    shapes.add(shape.copyWith());
    nextBounds = _expandBoundsForLogicalRect(
      sheet,
      nextBounds,
      path.getBounds().inflate(
        shape.kind == FortuneShapeKind.rectangle
            ? strokeWidth / math.sqrt2
            : strokeWidth / 2,
      ),
    );
  }
  return (bounds: nextBounds, lines: lines, shapes: shapes);
}

_LabelSheetSaveBounds _expandBoundsForLogicalRect(
  FortuneSheet sheet,
  _LabelSheetSaveBounds bounds,
  ui.Rect rect,
) {
  return bounds.expandTo(
    row: _lastIndexForPosition(
      math.max(0, rect.bottom),
      lengthForIndex: (row) => _rowHeight(sheet, row),
    ),
    column: _lastIndexForPosition(
      math.max(0, rect.right),
      lengthForIndex: (column) => _columnWidth(sheet, column),
    ),
  );
}

ui.Path _fortuneShapeLogicalPath(FortuneShape shape) {
  final rect = ui.Rect.fromLTWH(
    shape.left,
    shape.top,
    shape.width,
    shape.height,
  );
  final path = ui.Path();
  switch (shape.kind) {
    case FortuneShapeKind.rectangle:
      path.addRect(rect);
    case FortuneShapeKind.roundedRectangle:
      final radius = math.min(
        fortuneMillimetersToLogicalPixels(shape.cornerRadiusMm),
        math.min(rect.width, rect.height) / 2,
      );
      path.addRRect(
        ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)),
      );
    case FortuneShapeKind.ellipse:
      path.addOval(rect);
  }
  if (shape.rotationDegrees == 0) {
    return path;
  }
  final transform = Matrix4.identity()
    ..translateByDouble(rect.center.dx, rect.center.dy, 0, 1)
    ..rotateZ(shape.rotationDegrees * math.pi / 180)
    ..translateByDouble(-rect.center.dx, -rect.center.dy, 0, 1);
  return path.transform(transform.storage);
}

bool _filledShapeIntersectsRect(FortuneShape shape, ui.Rect printRect) {
  final shapeRect = ui.Rect.fromLTWH(
    shape.left,
    shape.top,
    shape.width,
    shape.height,
  );
  final pathBounds = _fortuneShapeLogicalPath(shape).getBounds();
  if (!_rectsIntersectOrTouch(pathBounds, printRect)) {
    return false;
  }

  final radians = -shape.rotationDegrees * math.pi / 180;
  final cosine = math.cos(radians);
  final sine = math.sin(radians);
  final center = shapeRect.center;
  ui.Offset toShapeLocal(ui.Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return ui.Offset(
      center.dx + dx * cosine - dy * sine,
      center.dy + dx * sine + dy * cosine,
    );
  }

  final printPolygon = <ui.Offset>[
    toShapeLocal(printRect.topLeft),
    toShapeLocal(printRect.topRight),
    toShapeLocal(printRect.bottomRight),
    toShapeLocal(printRect.bottomLeft),
  ];
  switch (shape.kind) {
    case FortuneShapeKind.rectangle:
      return _polygonDistanceSquaredToRect(printPolygon, shapeRect) == 0;
    case FortuneShapeKind.roundedRectangle:
      final radius = math.min(
        fortuneMillimetersToLogicalPixels(shape.cornerRadiusMm),
        math.min(shapeRect.width, shapeRect.height) / 2,
      );
      final core = ui.Rect.fromLTRB(
        shapeRect.left + radius,
        shapeRect.top + radius,
        shapeRect.right - radius,
        shapeRect.bottom - radius,
      );
      return _polygonDistanceSquaredToRect(printPolygon, core) <=
          radius * radius;
    case FortuneShapeKind.ellipse:
      final radiusX = shapeRect.width / 2;
      final radiusY = shapeRect.height / 2;
      final normalizedPolygon = printPolygon
          .map(
            (point) => ui.Offset(
              (point.dx - center.dx) / radiusX,
              (point.dy - center.dy) / radiusY,
            ),
          )
          .toList(growable: false);
      return _pointInConvexPolygon(ui.Offset.zero, normalizedPolygon) ||
          _minimumDistanceSquaredToPolygon(ui.Offset.zero, normalizedPolygon) <=
              1;
  }
}

double _polygonDistanceSquaredToRect(List<ui.Offset> polygon, ui.Rect rect) {
  final rectPolygon = <ui.Offset>[
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
  if (polygon.any(rect.contains) ||
      rectPolygon.any((point) => _pointInConvexPolygon(point, polygon))) {
    return 0;
  }
  var minimum = double.infinity;
  for (var index = 0; index < polygon.length; index += 1) {
    final start = polygon[index];
    final end = polygon[(index + 1) % polygon.length];
    for (var rectIndex = 0; rectIndex < rectPolygon.length; rectIndex += 1) {
      final rectStart = rectPolygon[rectIndex];
      final rectEnd = rectPolygon[(rectIndex + 1) % rectPolygon.length];
      if (_segmentsIntersect(start, end, rectStart, rectEnd)) {
        return 0;
      }
      minimum = math.min(
        minimum,
        math.min(
          _pointToSegmentDistanceSquared(start, rectStart, rectEnd),
          _pointToSegmentDistanceSquared(rectStart, start, end),
        ),
      );
    }
  }
  return minimum;
}

bool _pointInConvexPolygon(ui.Offset point, List<ui.Offset> polygon) {
  var hasPositive = false;
  var hasNegative = false;
  for (var index = 0; index < polygon.length; index += 1) {
    final start = polygon[index];
    final end = polygon[(index + 1) % polygon.length];
    final cross =
        (end.dx - start.dx) * (point.dy - start.dy) -
        (end.dy - start.dy) * (point.dx - start.dx);
    hasPositive = hasPositive || cross > 0;
    hasNegative = hasNegative || cross < 0;
    if (hasPositive && hasNegative) {
      return false;
    }
  }
  return true;
}

double _minimumDistanceSquaredToPolygon(
  ui.Offset point,
  List<ui.Offset> polygon,
) {
  var minimum = double.infinity;
  for (var index = 0; index < polygon.length; index += 1) {
    minimum = math.min(
      minimum,
      _pointToSegmentDistanceSquared(
        point,
        polygon[index],
        polygon[(index + 1) % polygon.length],
      ),
    );
  }
  return minimum;
}

double _pointToSegmentDistanceSquared(
  ui.Offset point,
  ui.Offset start,
  ui.Offset end,
) {
  final delta = end - start;
  final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
  if (lengthSquared == 0) {
    return (point - start).distanceSquared;
  }
  final projection =
      ((point.dx - start.dx) * delta.dx + (point.dy - start.dy) * delta.dy) /
      lengthSquared;
  final closest = start + delta * projection.clamp(0.0, 1.0);
  return (point - closest).distanceSquared;
}

bool _strokeLineIntersectsRect(
  ui.Offset start,
  ui.Offset end,
  FortuneStrokeStyle style,
  double strokeWidth,
  ui.Rect rect,
) {
  final delta = end - start;
  final length = delta.distance;
  if (length == 0) {
    return false;
  }
  final direction = delta / length;
  final normal = ui.Offset(-direction.dy, direction.dx) * (strokeWidth / 2);

  bool markIntersects(double markStart, double markEnd) {
    final markStartPoint = start + direction * markStart;
    final markEndPoint = start + direction * markEnd;
    final polygon = <ui.Offset>[
      markStartPoint + normal,
      markEndPoint + normal,
      markEndPoint - normal,
      markStartPoint - normal,
    ];
    return _polygonDistanceSquaredToRect(polygon, rect) == 0;
  }

  if (style == FortuneStrokeStyle.solid) {
    return markIntersects(0, length);
  }
  final marks = fortuneObjectStrokeMarks(
    style: style,
    strokeWidth: strokeWidth,
    pathLength: length,
    closed: false,
  );
  for (final mark in marks) {
    switch (mark) {
      case FortuneObjectStrokeDot(:final center):
        if (_circleIntersectsRect(
          start + direction * center,
          strokeWidth / 2,
          rect,
        )) {
          return true;
        }
      case FortuneObjectStrokeDash(:final start, :final end):
        if (markIntersects(start, end)) {
          return true;
        }
    }
  }
  return false;
}

bool _strokePathIntersectsRect(
  ui.Path path,
  FortuneStrokeStyle style,
  double strokeWidth,
  ui.Rect rect,
) {
  if (!_rectsIntersectOrTouch(
    path.getBounds().inflate(strokeWidth / 2),
    rect,
  )) {
    return false;
  }
  for (final metric in path.computeMetrics()) {
    if (style == FortuneStrokeStyle.solid) {
      if (_pathMetricStrokeIntersectsRect(
        metric,
        0,
        metric.length,
        rect,
        strokeWidth / 2,
      )) {
        return true;
      }
      continue;
    }
    final marks = fortuneObjectStrokeMarks(
      style: style,
      strokeWidth: strokeWidth,
      pathLength: metric.length,
      closed: metric.isClosed,
    );
    for (final mark in marks) {
      switch (mark) {
        case FortuneObjectStrokeDot(:final center):
          final tangent = metric.getTangentForOffset(center);
          if (tangent != null &&
              _circleIntersectsRect(tangent.position, strokeWidth / 2, rect)) {
            return true;
          }
        case FortuneObjectStrokeDash(:final start, :final end):
          if (_pathMetricStrokeIntersectsRect(
            metric,
            start,
            end,
            rect,
            strokeWidth / 2,
          )) {
            return true;
          }
      }
    }
  }
  return false;
}

bool _solidShapeStrokeIntersectsRect(
  FortuneShape shape,
  ui.Path path,
  double strokeWidth,
  ui.Rect printRect,
) {
  if (shape.kind != FortuneShapeKind.rectangle) {
    return _strokePathIntersectsRect(
      path,
      FortuneStrokeStyle.solid,
      strokeWidth,
      printRect,
    );
  }
  final center = ui.Offset(
    shape.left + shape.width / 2,
    shape.top + shape.height / 2,
  );
  final radians = shape.rotationDegrees * math.pi / 180;
  final cosine = math.cos(radians);
  final sine = math.sin(radians);
  ui.Offset rotate(ui.Offset point) {
    final delta = point - center;
    return center +
        ui.Offset(
          delta.dx * cosine - delta.dy * sine,
          delta.dx * sine + delta.dy * cosine,
        );
  }

  List<ui.Offset> polygonFor(ui.Rect rect) => [
    rotate(rect.topLeft),
    rotate(rect.topRight),
    rotate(rect.bottomRight),
    rotate(rect.bottomLeft),
  ];

  final radius = strokeWidth / 2;
  final centerlineRect = ui.Rect.fromLTWH(
    shape.left,
    shape.top,
    shape.width,
    shape.height,
  );
  final outer = polygonFor(centerlineRect.inflate(radius));
  if (_polygonDistanceSquaredToRect(outer, printRect) != 0) {
    return false;
  }
  if (shape.width <= strokeWidth || shape.height <= strokeWidth) {
    return true;
  }
  final inner = polygonFor(centerlineRect.deflate(radius));
  return ![
    printRect.topLeft,
    printRect.topRight,
    printRect.bottomRight,
    printRect.bottomLeft,
  ].every((point) => _pointStrictlyInConvexPolygon(point, inner));
}

bool _patternedRectangleMiterIntersectsRect(
  FortuneShape shape,
  double strokeWidth,
  ui.Rect printRect,
) {
  final width = shape.width;
  final height = shape.height;
  final perimeter = 2 * (width + height);
  final marks = fortuneObjectStrokeMarks(
    style: shape.strokeStyle,
    strokeWidth: strokeWidth,
    pathLength: perimeter,
    closed: true,
  );
  final radius = strokeWidth / 2;
  final center = ui.Offset(shape.left + width / 2, shape.top + height / 2);
  final radians = shape.rotationDegrees * math.pi / 180;
  final cosine = math.cos(radians);
  final sine = math.sin(radians);
  ui.Offset rotate(ui.Offset point) {
    final delta = point - center;
    return center +
        ui.Offset(
          delta.dx * cosine - delta.dy * sine,
          delta.dx * sine + delta.dy * cosine,
        );
  }

  final corners = <({double offset, List<ui.Offset> triangle})>[
    (
      offset: width,
      triangle: [
        ui.Offset(shape.left + width, shape.top - radius),
        ui.Offset(shape.left + width + radius, shape.top - radius),
        ui.Offset(shape.left + width + radius, shape.top),
      ],
    ),
    (
      offset: width + height,
      triangle: [
        ui.Offset(shape.left + width + radius, shape.top + height),
        ui.Offset(shape.left + width + radius, shape.top + height + radius),
        ui.Offset(shape.left + width, shape.top + height + radius),
      ],
    ),
    (
      offset: 2 * width + height,
      triangle: [
        ui.Offset(shape.left, shape.top + height + radius),
        ui.Offset(shape.left - radius, shape.top + height + radius),
        ui.Offset(shape.left - radius, shape.top + height),
      ],
    ),
  ];
  for (final corner in corners) {
    final covered = marks.any(
      (mark) => switch (mark) {
        FortuneObjectStrokeDash(:final start, :final end) =>
          start < corner.offset && end > corner.offset,
        FortuneObjectStrokeDot() => false,
      },
    );
    if (covered &&
        _polygonDistanceSquaredToRect(
              corner.triangle.map(rotate).toList(growable: false),
              printRect,
            ) ==
            0) {
      return true;
    }
  }
  return false;
}

bool _pointStrictlyInConvexPolygon(ui.Offset point, List<ui.Offset> polygon) {
  var sign = 0;
  for (var index = 0; index < polygon.length; index += 1) {
    final start = polygon[index];
    final end = polygon[(index + 1) % polygon.length];
    final cross =
        (end.dx - start.dx) * (point.dy - start.dy) -
        (end.dy - start.dy) * (point.dx - start.dx);
    if (cross == 0) {
      return false;
    }
    final currentSign = cross > 0 ? 1 : -1;
    sign = sign == 0 ? currentSign : sign;
    if (sign != currentSign) {
      return false;
    }
  }
  return true;
}

bool _rectsIntersectOrTouch(ui.Rect first, ui.Rect second) {
  return first.left <= second.right &&
      first.right >= second.left &&
      first.top <= second.bottom &&
      first.bottom >= second.top;
}

bool _circleIntersectsRect(ui.Offset center, double radius, ui.Rect rect) {
  final closestX = center.dx.clamp(rect.left, rect.right);
  final closestY = center.dy.clamp(rect.top, rect.bottom);
  final dx = center.dx - closestX;
  final dy = center.dy - closestY;
  return dx * dx + dy * dy <= radius * radius;
}

bool _pathMetricStrokeIntersectsRect(
  ui.PathMetric metric,
  double start,
  double end,
  ui.Rect rect,
  double radius,
) {
  const minimumInterval = 1e-7;
  const maximumDepth = 48;

  bool intersects(double intervalStart, double intervalEnd, int depth) {
    final intervalPath = metric.extractPath(intervalStart, intervalEnd);
    final bounds = intervalPath.getBounds();
    if (_rectDistanceSquared(bounds, rect) > radius * radius) {
      return false;
    }
    if (_rectsIntersectOrTouch(bounds, rect)) {
      return true;
    }
    if (depth >= maximumDepth ||
        intervalEnd - intervalStart <= minimumInterval) {
      final startTangent = metric.getTangentForOffset(intervalStart);
      final endTangent = metric.getTangentForOffset(intervalEnd);
      if (startTangent == null || endTangent == null) {
        return false;
      }
      final startNormal = ui.Offset(
        -startTangent.vector.dy,
        startTangent.vector.dx,
      );
      final endNormal = ui.Offset(-endTangent.vector.dy, endTangent.vector.dx);
      final footprint = <ui.Offset>[
        startTangent.position + startNormal * radius,
        endTangent.position + endNormal * radius,
        endTangent.position - endNormal * radius,
        startTangent.position - startNormal * radius,
      ];
      return _polygonDistanceSquaredToRect(footprint, rect) == 0;
    }
    final middle = (intervalStart + intervalEnd) / 2;
    return intersects(intervalStart, middle, depth + 1) ||
        intersects(middle, intervalEnd, depth + 1);
  }

  return intersects(start, end, 0);
}

double _rectDistanceSquared(ui.Rect first, ui.Rect second) {
  final dx = math.max(
    0.0,
    math.max(first.left - second.right, second.left - first.right),
  );
  final dy = math.max(
    0.0,
    math.max(first.top - second.bottom, second.top - first.bottom),
  );
  return dx * dx + dy * dy;
}

bool _segmentsIntersect(ui.Offset a, ui.Offset b, ui.Offset c, ui.Offset d) {
  double cross(ui.Offset first, ui.Offset second, ui.Offset third) {
    return (second.dx - first.dx) * (third.dy - first.dy) -
        (second.dy - first.dy) * (third.dx - first.dx);
  }

  bool onSegment(ui.Offset start, ui.Offset point, ui.Offset end) {
    return point.dx >= math.min(start.dx, end.dx) &&
        point.dx <= math.max(start.dx, end.dx) &&
        point.dy >= math.min(start.dy, end.dy) &&
        point.dy <= math.max(start.dy, end.dy);
  }

  final abC = cross(a, b, c);
  final abD = cross(a, b, d);
  final cdA = cross(c, d, a);
  final cdB = cross(c, d, b);
  if ((abC > 0 && abD < 0 || abC < 0 && abD > 0) &&
      (cdA > 0 && cdB < 0 || cdA < 0 && cdB > 0)) {
    return true;
  }
  return abC == 0 && onSegment(a, c, b) ||
      abD == 0 && onSegment(a, d, b) ||
      cdA == 0 && onSegment(c, a, d) ||
      cdB == 0 && onSegment(c, b, d);
}

_LabelSheetSaveBounds _estimatedCellTextExtent(
  FortuneSheet sheet,
  FortuneCellCoord coord,
  FortuneCell cell,
) {
  final merge = cell.merge;
  final startRow = merge?.row ?? coord.row;
  final startColumn = merge?.column ?? coord.column;
  final rowSpan = math.max<int>(1, merge?.rowSpan ?? 1);
  final columnSpan = math.max<int>(1, merge?.columnSpan ?? 1);
  final lines = cell.renderedText.split('\n');
  final fontSize = cell.fontSize ?? 10;
  final fontScale = _numberFrom(cell.extraFields['fontScale']) ?? 100;
  final letterSpacing = _numberFrom(cell.extraFields['letterSpacing']) ?? 0;
  final lineHeight = _numberFrom(cell.extraFields['lineHeight']) ?? 1.2;
  final longestLine = lines.fold<int>(0, (longest, line) {
    return math.max(longest, line.runes.length);
  });
  final estimatedTextWidth =
      longestLine * (fontSize * 0.56 + letterSpacing) * fontScale / 100;
  final estimatedTextHeight = lines.length * fontSize * lineHeight;
  final availableWidth = _spanLength(
    startColumn,
    columnSpan,
    lengthForIndex: (column) => _columnWidth(sheet, column),
  );
  final availableHeight = _spanLength(
    startRow,
    rowSpan,
    lengthForIndex: (row) => _rowHeight(sheet, row),
  );
  return _LabelSheetSaveBounds(
    maxRow:
        startRow +
        math.max<int>(
          rowSpan,
          (estimatedTextHeight / math.max(availableHeight, 1)).ceil() * rowSpan,
        ) -
        1,
    maxColumn:
        startColumn +
        math.max<int>(
          columnSpan,
          (estimatedTextWidth / math.max(availableWidth, 1)).ceil() *
              columnSpan,
        ) -
        1,
  );
}

bool _imageIntersectsBounds(
  FortuneSheet sheet,
  FortuneImage image,
  _LabelSheetSaveBounds bounds,
) {
  final boundsRight = _spanLength(
    0,
    bounds.maxColumn + 1,
    lengthForIndex: (column) => _columnWidth(sheet, column),
  );
  final boundsBottom = _spanLength(
    0,
    bounds.maxRow + 1,
    lengthForIndex: (row) => _rowHeight(sheet, row),
  );
  return image.left < boundsRight &&
      image.left + image.width > 0 &&
      image.top < boundsBottom &&
      image.top + image.height > 0;
}

bool _borderIntersectsBounds(
  FortuneBorderInfo border,
  _LabelSheetSaveBounds bounds,
) {
  return border.ranges.any((range) => _rangeIntersectsBounds(range, bounds));
}

bool _rangeIntersectsBounds(FortuneRange range, _LabelSheetSaveBounds bounds) {
  return range.rowStart <= bounds.maxRow &&
      range.rowEnd >= 0 &&
      range.columnStart <= bounds.maxColumn &&
      range.columnEnd >= 0;
}

int _lastVisibleIndexForExtent(
  double extent, {
  required double Function(int index) lengthForIndex,
}) {
  return _lastIndexForPosition(extent, lengthForIndex: lengthForIndex);
}

int _lastIndexForPosition(
  double position, {
  required double Function(int index) lengthForIndex,
}) {
  if (position <= 0) {
    return 0;
  }
  var offset = 0.0;
  var index = 0;
  while (offset < position) {
    offset += lengthForIndex(index);
    if (offset >= position) {
      return index;
    }
    index += 1;
  }
  return index;
}

double _spanLength(
  int start,
  int count, {
  required double Function(int index) lengthForIndex,
}) {
  var total = 0.0;
  for (var index = start; index < start + count; index += 1) {
    total += lengthForIndex(index);
  }
  return total;
}

double _rowHeight(FortuneSheet sheet, int row) {
  return sheet.rowHeights[row] ?? sheet.defaultRowHeight ?? 19;
}

double _columnWidth(FortuneSheet sheet, int column) {
  return sheet.columnWidths[column] ?? sheet.defaultColWidth ?? 73;
}

double? _numberFrom(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

Map<int, double> _intDoubleMapWithin(Map<int, double> source, int maxIndex) {
  return {
    for (final entry in source.entries)
      if (entry.key <= maxIndex) entry.key: entry.value,
  };
}

Map<int, Object?> _intObjectMapWithin(Map<int, Object?> source, int maxIndex) {
  return {
    for (final entry in source.entries)
      if (entry.key <= maxIndex) entry.key: cloneFortuneMetadata(entry.value),
  };
}

Map<String, Object?> _coordKeyMapWithin(
  Map<String, Object?> source,
  _LabelSheetSaveBounds bounds,
) {
  return {
    for (final entry in source.entries)
      if (_coordKeyWithinBounds(entry.key, bounds))
        entry.key: cloneFortuneMetadata(entry.value),
  };
}

bool _coordKeyWithinBounds(String key, _LabelSheetSaveBounds bounds) {
  final parts = key.split('_');
  if (parts.length != 2) {
    return false;
  }
  final row = int.tryParse(parts[0]);
  final column = int.tryParse(parts[1]);
  if (row == null || column == null) {
    return false;
  }
  return row <= bounds.maxRow && column <= bounds.maxColumn;
}

class _LabelSheetSaveBounds {
  const _LabelSheetSaveBounds({required this.maxRow, required this.maxColumn});

  final int maxRow;
  final int maxColumn;

  bool contains(FortuneCellCoord coord) {
    return coord.row <= maxRow && coord.column <= maxColumn;
  }

  _LabelSheetSaveBounds expandTo({required int row, required int column}) {
    return _LabelSheetSaveBounds(
      maxRow: math.max(maxRow, row),
      maxColumn: math.max(maxColumn, column),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _LabelSheetSaveBounds &&
        other.maxRow == maxRow &&
        other.maxColumn == maxColumn;
  }

  @override
  int get hashCode => Object.hash(maxRow, maxColumn);
}

FortuneWorkbook labelSheetDecodeWorkbookSave(String encoded) {
  return labelSheetDecodeWorkbookSaveBytes(utf8.encode(encoded.trim()));
}

FortuneWorkbook labelSheetDecodeWorkbookSaveBytes(List<int> encodedBytes) {
  final encoded = utf8.decode(encodedBytes).trim();
  final archive = ZipDecoder().decodeBytes(base64Decode(encoded.trim()));
  final manifestFile = _archiveFile(archive, 'manifest.json');
  final workbookFile = _archiveFile(archive, 'workbook.json');
  if (manifestFile == null || workbookFile == null) {
    throw const FormatException('Missing label sheet save entries');
  }
  final manifestBytes = manifestFile.readBytes();
  final workbookBytes = workbookFile.readBytes();
  if (manifestBytes == null || workbookBytes == null) {
    throw const FormatException('Unreadable label sheet save entries');
  }
  final manifest = jsonDecode(utf8.decode(manifestBytes));
  if (manifest is! Map ||
      manifest['format'] != labelSheetSaveFormat ||
      manifest['codec'] != 'fortune-sheet-json') {
    throw const FormatException('Unsupported label sheet save format');
  }
  final workbookJson = jsonDecode(utf8.decode(workbookBytes));
  if (workbookJson is! Map) {
    throw const FormatException('Invalid label sheet workbook payload');
  }
  final migratedJson = labelSheetMigrateWorkbookSaveJson(
    Map<String, Object?>.from(workbookJson),
    manifest: Map<String, Object?>.from(manifest),
  );
  return FortuneSheetCodec.workbookFromJson(
    labelSheetSanitizeWorkbookSaveJson(migratedJson),
  );
}

FortuneWorkbook? labelSheetTryDecodeWorkbookSave(String? encoded) {
  if (encoded == null || encoded.trim().isEmpty) {
    return null;
  }
  try {
    return labelSheetDecodeWorkbookSave(encoded);
  } catch (_) {
    return null;
  }
}

/// Normalizes imported workbooks to the current label-sheet save shape.
///
/// Every non-`.lms` import path that creates a [FortuneWorkbook] directly
/// (xlsx, future external formats, generated drafts) must pass through this
/// before it is applied to the workbench. When the save format changes, add the
/// feature key, sanitizer allow-list entries, migration step, and tests here so
/// all import paths stay current together.
FortuneWorkbook labelSheetNormalizeWorkbookForCurrentSaveFormat(
  FortuneWorkbook workbook,
) {
  final workbookJson = FortuneSheetCodec.workbookToJson(workbook);
  final migratedJson = labelSheetMigrateWorkbookSaveJson(
    Map<String, Object?>.from(workbookJson),
    manifest: {
      'format': labelSheetSaveFormat,
      'version': labelSheetSaveFormatVersion,
      'features': labelSheetSaveFeatureVersions,
      'codec': 'fortune-sheet-json',
    },
  );
  return FortuneSheetCodec.workbookFromJson(
    labelSheetSanitizeWorkbookSaveJson(migratedJson),
  );
}

ArchiveFile? _archiveFile(Archive archive, String name) {
  for (final file in archive.files) {
    if (file.name == name && file.isFile) {
      return file;
    }
  }
  return null;
}

Map<String, Object?> labelSheetSanitizeWorkbookSaveJson(
  Map<String, Object?> json,
) {
  return _sanitizeMap(
    json,
    _supportedWorkbookKeys,
    valueSanitizer: (key, value) {
      if (key == 'data' && value is List) {
        return [
          for (final item in value)
            if (item is Map)
              _sanitizeSheetJson(Map<String, Object?>.from(item)),
        ];
      }
      return _cloneSupportedSaveValue(value);
    },
  );
}

Map<String, Object?> labelSheetMigrateWorkbookSaveJson(
  Map<String, Object?> json, {
  Map<String, Object?> manifest = const <String, Object?>{},
}) {
  final sourceVersion = _intLike(manifest['version']) ?? 0;
  final sourceFeatures = _featureVersions(manifest['features']);
  final migrated = _cloneStringObjectMap(json);
  _migrateLegacySheetImageKey(
    migrated,
    sourceVersion: sourceVersion,
    sourceFeatures: sourceFeatures,
  );
  return migrated;
}

void _migrateLegacySheetImageKey(
  Map<String, Object?> workbookJson, {
  required int sourceVersion,
  required Map<String, int> sourceFeatures,
}) {
  final sheetImagesFeatureVersion =
      labelSheetSaveFeatureVersions['sheet.images'] ??
      labelSheetSaveFormatVersion;
  final currentImagesFeatureKnown =
      sourceVersion >= sheetImagesFeatureVersion &&
      sourceFeatures.containsKey('sheet.images');
  final sheets = workbookJson['data'];
  if (sheets is! List) {
    return;
  }
  for (final sheet in sheets) {
    if (sheet is! Map) {
      continue;
    }
    final sheetJson = Map<String, Object?>.from(sheet);
    if (!sheetJson.containsKey('images') && sheetJson.containsKey('image')) {
      sheet['images'] = _cloneSupportedSaveValue(sheetJson['image']);
    }
    if (!currentImagesFeatureKnown || sheetJson.containsKey('image')) {
      sheet.remove('image');
    }
  }
}

int? _intLike(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

Map<String, int> _featureVersions(Object? value) {
  if (value is! Map) {
    return const <String, int>{};
  }
  return {
    for (final entry in value.entries)
      if (_intLike(entry.value) != null) '${entry.key}': _intLike(entry.value)!,
  };
}

Map<String, Object?> _cloneStringObjectMap(Map<String, Object?> value) {
  return {
    for (final entry in value.entries)
      entry.key: _cloneSupportedSaveValue(entry.value),
  };
}

Map<String, Object?> _sanitizeSheetJson(Map<String, Object?> json) {
  final hasLegacyShapes = json.containsKey('shapes');
  final legacyShapes = hasLegacyShapes
      ? _strictCloneLegacyShapes(json['shapes'], HashSet<Object>.identity())
      : (valid: false, value: null);
  final source = Map<String, Object?>.from(json)..remove('shapes');
  final sanitized = _sanitizeMap(
    source,
    _supportedSheetKeys,
    valueSanitizer: (key, value) {
      return switch (key) {
        'config' when value is Map => _sanitizeSheetConfigJson(
          Map<String, Object?>.from(value),
        ),
        'celldata' when value is List => _sanitizeCelldata(value),
        'data' when value is List => _sanitizeMatrixData(value),
        'images' || 'image' when value is List => _sanitizeImages(value),
        'lines' when value is List => _sanitizeObjectList(
          value,
          _supportedLineKeys,
        ),
        'fortuneShapes' when value is List => _sanitizeObjectList(
          value,
          _supportedFortuneShapeKeys,
        ),
        _ => _cloneSupportedSaveValue(value),
      };
    },
  );
  if (hasLegacyShapes && legacyShapes.valid) {
    sanitized['shapes'] = legacyShapes.value;
  }
  return sanitized;
}

List<Object?> _sanitizeObjectList(
  List<Object?> raw,
  Set<String> supportedKeys,
) {
  return [
    for (final item in raw)
      if (item is Map)
        _sanitizeMap(Map<String, Object?>.from(item), supportedKeys),
  ];
}

({bool valid, Object? value}) _strictCloneLegacyShapes(
  Object? value,
  Set<Object> currentPath,
) {
  if (value == null || value is bool || value is String) {
    return (valid: true, value: value);
  }
  if (value is num) {
    return value.isFinite
        ? (valid: true, value: value)
        : (valid: false, value: null);
  }
  if (value is Map) {
    if (!currentPath.add(value)) {
      return (valid: false, value: null);
    }
    try {
      final result = <String, Object?>{};
      for (final entry in value.entries) {
        if (entry.key is! String) {
          return (valid: false, value: null);
        }
        final child = _strictCloneLegacyShapes(entry.value, currentPath);
        if (!child.valid) {
          return (valid: false, value: null);
        }
        result[entry.key as String] = child.value;
      }
      return (valid: true, value: result);
    } finally {
      currentPath.remove(value);
    }
  }
  if (value is List) {
    if (!currentPath.add(value)) {
      return (valid: false, value: null);
    }
    try {
      final result = <Object?>[];
      for (final item in value) {
        final child = _strictCloneLegacyShapes(item, currentPath);
        if (!child.valid) {
          return (valid: false, value: null);
        }
        result.add(child.value);
      }
      return (valid: true, value: result);
    } finally {
      currentPath.remove(value);
    }
  }
  return (valid: false, value: null);
}

List<Object?> _sanitizeImages(List<Object?> raw) {
  return [
    for (final item in raw)
      if (item is Map) _sanitizeImageJson(Map<String, Object?>.from(item)),
  ];
}

Map<String, Object?> _sanitizeImageJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedImageKeys,
    valueSanitizer: (key, value) {
      if (key == 'crop' && value is Map) {
        return _sanitizeMap(
          Map<String, Object?>.from(value),
          _supportedImageCropKeys,
        );
      }
      return _cloneSupportedSaveValue(value);
    },
  );
}

Map<String, Object?> _sanitizeSheetConfigJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedSheetConfigKeys,
    valueSanitizer: (_, value) => _cloneSupportedSaveValue(value),
  );
}

List<Object?> _sanitizeCelldata(List<Object?> raw) {
  return [
    for (final item in raw)
      if (item is Map)
        {
          for (final entry in item.entries)
            if (entry.key == 'r' || entry.key == 'c')
              '${entry.key}': _cloneSupportedSaveValue(entry.value)
            else if (entry.key == 'v')
              'v': entry.value is Map
                  ? _sanitizeCellJson(
                      Map<String, Object?>.from(entry.value as Map),
                    )
                  : _cloneSupportedSaveValue(entry.value),
        },
  ];
}

List<Object?> _sanitizeMatrixData(List<Object?> raw) {
  return [
    for (final row in raw)
      if (row is List)
        [
          for (final cell in row)
            cell is Map
                ? _sanitizeCellJson(Map<String, Object?>.from(cell))
                : _cloneSupportedSaveValue(cell),
        ]
      else
        _cloneSupportedSaveValue(row),
  ];
}

Map<String, Object?> _sanitizeCellJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedCellKeys,
    valueSanitizer: (key, value) {
      return switch (key) {
        'mc' when value is Map => _sanitizeMap(
          Map<String, Object?>.from(value),
          _supportedMergeKeys,
        ),
        'ct' when value is Map => _sanitizeCellTypeJson(
          Map<String, Object?>.from(value),
        ),
        _ => _cloneSupportedSaveValue(value),
      };
    },
  );
}

Map<String, Object?> _sanitizeCellTypeJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedCellTypeKeys,
    valueSanitizer: (key, value) {
      if (key == 's' && value is List) {
        return [
          for (final item in value)
            if (item is Map)
              _sanitizeInlineRunJson(Map<String, Object?>.from(item)),
        ];
      }
      return _cloneSupportedSaveValue(value);
    },
  );
}

Map<String, Object?> _sanitizeInlineRunJson(Map<String, Object?> json) {
  return _sanitizeMap(
    json,
    _supportedInlineRunKeys,
    valueSanitizer: (_, value) => _cloneSupportedSaveValue(value),
  );
}

Map<String, Object?> _sanitizeMap(
  Map<String, Object?> json,
  Set<String> supportedKeys, {
  Object? Function(String key, Object? value)? valueSanitizer,
}) {
  return {
    for (final entry in json.entries)
      if (supportedKeys.contains(entry.key))
        entry.key:
            valueSanitizer?.call(entry.key, entry.value) ??
            _cloneSupportedSaveValue(entry.value),
  };
}

Object? _cloneSupportedSaveValue(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        '${entry.key}': _cloneSupportedSaveValue(entry.value),
    };
  }
  if (value is List) {
    return [for (final item in value) _cloneSupportedSaveValue(item)];
  }
  return value;
}
