import 'dart:math' as math;

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/utils/log_context.dart';

const double labelSheetImportMinReadableFontHeightMm = 2.5;

FortuneSheet labelSheetImportWithPreservedGridClientSize(
  FortuneSheet importedSheet,
  FortuneSheet currentSheet,
) {
  if (fortuneSheetGridClientPhysicalSize(importedSheet) != null) {
    return importedSheet.copyWith();
  }
  final currentSize = fortuneSheetGridClientPhysicalSize(currentSheet);
  if (currentSize == null) {
    return importedSheet.copyWith();
  }
  return importedSheet.copyWith(
    extraFields: {
      ...importedSheet.extraFields,
      fortuneSheetGridClientWidthMmKey: currentSize.widthMm,
      fortuneSheetGridClientHeightMmKey: currentSize.heightMm,
    },
  );
}

FortuneSheet labelSheetScaleImportedToPhysicalWidth(
  FortuneSheet sheet, {
  required FortuneSheet currentSheet,
}) {
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      fortuneSheetGridClientPhysicalSize(currentSheet);
  if (physicalSize == null) {
    return sheet.copyWith();
  }
  final sourceWidth = labelSheetAxisLogicalTotalSizeForCount(
    sheet.columnWidths,
    sheet.columnCount,
    sheet.defaultColWidth,
  );
  final sourceHeight = labelSheetAxisLogicalTotalSizeForCount(
    sheet.rowHeights,
    sheet.rowCount,
    sheet.defaultRowHeight,
  );
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    return sheet.copyWith();
  }
  final targetWidth = physicalSize.logicalSize.width;
  final widthScale = _axisScaleForTarget(
    sourceWidth,
    targetWidth,
    sheet.columnCount,
  );
  final minFontSize = _minimumFontSize(sheet);
  final minReadableFontSize = fortuneMillimetersToLogicalPixels(
    labelSheetImportMinReadableFontHeightMm,
  );
  final readableScale = minFontSize == null || minFontSize <= 0
      ? widthScale
      : minReadableFontSize / minFontSize;
  final scale = math.max(widthScale, readableScale);
  final scaledSheet = _scaleSheet(sheet, scale);
  final scaledWidth = labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.columnWidths,
    scaledSheet.columnCount,
    scaledSheet.defaultColWidth,
  );
  final scaledHeight = labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.rowHeights,
    scaledSheet.rowCount,
    scaledSheet.defaultRowHeight,
  );
  final scaledMinFontSize = _minimumFontSize(scaledSheet);
  final overflowLogical = scaledWidth - targetWidth;
  final overflowMm = overflowLogical <= 0
      ? 0.0
      : overflowLogical / fortuneMillimetersToLogicalPixels(1);
  debugLog(
    'label sheet import physical scale '
    'sourceLogical=${sourceWidth}x$sourceHeight '
    'targetWidth=$targetWidth physicalSizeMm=${physicalSize.widthMm}x${physicalSize.heightMm} '
    'widthScale=$widthScale readableScale=$readableScale scale=$scale '
    'minFontSize=$minFontSize scaledMinFontSize=$scaledMinFontSize '
    'minReadableMm=$labelSheetImportMinReadableFontHeightMm '
    'minReadableLogical=$minReadableFontSize '
    'scaledLogical=${scaledWidth}x$scaledHeight overflowWidth=${scaledWidth > targetWidth} '
    'overflowLogical=$overflowLogical overflowMm=$overflowMm',
    skipFrames: 1,
  );
  return scaledSheet;
}

double labelSheetAxisLogicalTotalSizeForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize,
) {
  final resolvedCount = count ?? labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return sizes.values.fold<double>(0, (sum, size) => sum + size + 1);
  }
  final fallback = defaultSize ?? 0;
  var total = 0.0;
  for (var index = 0; index < resolvedCount; index += 1) {
    total += (sizes[index] ?? fallback) + 1;
  }
  return total;
}

int labelSheetAxisCount(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return 0;
  }
  return sizes.keys.reduce(math.max) + 1;
}

FortuneSheet _scaleSheet(FortuneSheet sheet, double scale) {
  if (!scale.isFinite || scale <= 0) {
    return sheet.copyWith();
  }
  return sheet.copyWith(
    rowHeights: _scaleAxis(sheet.rowHeights, scale),
    columnWidths: _scaleAxis(sheet.columnWidths, scale),
    defaultRowHeight: _scaleNullable(sheet.defaultRowHeight, scale),
    defaultColWidth: _scaleNullable(sheet.defaultColWidth, scale),
    cells: {
      for (final entry in sheet.cells.entries)
        entry.key: _scaleCell(entry.value, scale),
    },
  );
}

Map<int, double> _scaleAxis(Map<int, double> values, double scale) {
  return {
    for (final entry in values.entries)
      entry.key: math.max(1.0, entry.value * scale),
  };
}

double? _scaleNullable(double? value, double scale) {
  if (value == null) {
    return null;
  }
  return math.max(1.0, value * scale);
}

FortuneCell _scaleCell(FortuneCell cell, double scale) {
  return cell.copyWith(
    fontSize: _scaleNullable(cell.fontSize, scale),
    inlineRuns: cell.inlineRuns
        ?.map((run) => _scaleInlineRun(run, scale))
        .toList(),
    extraFields: _scaleTextExtraFields(cell.extraFields, scale),
  );
}

FortuneInlineTextRun _scaleInlineRun(
  FortuneInlineTextRun run,
  double scale,
) {
  return run.copyWith(
    fontSize: _scaleNullable(run.fontSize, scale),
    extraFields: _scaleTextExtraFields(run.extraFields, scale),
  );
}

Map<String, Object?> _scaleTextExtraFields(
  Map<String, Object?> values,
  double scale,
) {
  final scaled = <String, Object?>{...values};
  final letterSpacing = _number(values['letterSpacing']);
  if (letterSpacing != null) {
    scaled['letterSpacing'] = letterSpacing * scale;
  }
  return scaled;
}

double? _number(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

double? _minimumFontSize(FortuneSheet sheet) {
  double? minFontSize;
  void add(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return;
    }
    minFontSize = minFontSize == null
        ? value
        : math.min(minFontSize!, value);
  }

  for (final cell in sheet.cells.values) {
    add(cell.fontSize);
    for (final run in cell.inlineRuns ?? const <FortuneInlineTextRun>[]) {
      add(run.fontSize);
    }
  }
  return minFontSize;
}

double _axisScaleForTarget(
  double sourceTotal,
  double targetTotal,
  int? count,
) {
  if (sourceTotal <= 0 || targetTotal <= 0) {
    return 1;
  }
  final gridLineCount = math.max(0, count ?? 0);
  final sourceContent = math.max(1.0, sourceTotal - gridLineCount);
  final targetContent = math.max(1.0, targetTotal - gridLineCount);
  return targetContent / sourceContent;
}
