import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import_temp.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_barcode_renderer.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_image_import_settings.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_rtf_import.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_workbook_builder.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_xlsx_import.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_dialog.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_settings.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/widgets/snackbar.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';
import 'package:label_manager/widgets/label_print_dialog_close_icon.dart';
import 'package:label_manager/widgets/label_print_settings_panel.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _labelFileDirectoryPrefsKey = 'label_file_directory';
const double _labelSheetImportMinReadableFontHeightMm = 2.5;
const double _labelSheetZoomToolbarRightInset = 124.0;
const double _labelSheetObjectPanelMinWidth = 160.0;
const double _labelSheetObjectPanelInitialWidth = 160.0;

FortuneSheet _labelSheetWithPreservedGridClientSize(
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

// 변환 규칙 C(스케일): 물리 라벨 크기에 맞춰 폭 우선으로 스케일하고, 폭 대비 비율로
// 높이를 맞춘다(규칙 5). 폭 기준 축소로 문자가 실물 프린트 기준 최소 가독 크기(규칙 7)를
// 밑돌면 인쇄 영역을 벗어나더라도 다시 키운다(규칙 6). 세부 규칙은
// label_sheet_xlsx_import.dart 상단 규칙 주석 참조.
FortuneSheet _labelSheetScaledToPhysicalWidth(
  FortuneSheet sheet, {
  required FortuneSheet currentSheet,
}) {
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      fortuneSheetGridClientPhysicalSize(currentSheet);
  if (physicalSize == null) {
    return sheet.copyWith();
  }
  final sourceWidth = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.columnWidths,
    sheet.columnCount,
    sheet.defaultColWidth,
  );
  final sourceHeight = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.rowHeights,
    sheet.rowCount,
    sheet.defaultRowHeight,
  );
  if (sourceWidth <= 0 || sourceHeight <= 0) {
    return sheet.copyWith();
  }
  final targetWidth = physicalSize.logicalSize.width;
  final widthScale = _labelSheetAxisScaleForTarget(
    sourceWidth,
    targetWidth,
    sheet.columnCount,
  );
  final minFontSize = _labelSheetMinimumFontSize(sheet);
  final minReadableFontSize = fortuneMillimetersToLogicalPixels(
    _labelSheetImportMinReadableFontHeightMm,
  );
  final readableScale = minFontSize == null || minFontSize <= 0
      ? widthScale
      : minReadableFontSize / minFontSize;
  final scale = math.max(widthScale, readableScale);
  final scaledSheet = _labelSheetScaleSheet(sheet, scale);
  final scaledWidth = _labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.columnWidths,
    scaledSheet.columnCount,
    scaledSheet.defaultColWidth,
  );
  final scaledHeight = _labelSheetAxisLogicalTotalSizeForCount(
    scaledSheet.rowHeights,
    scaledSheet.rowCount,
    scaledSheet.defaultRowHeight,
  );
  final scaledMinFontSize = _labelSheetMinimumFontSize(scaledSheet);
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
    'minReadableMm=$_labelSheetImportMinReadableFontHeightMm '
    'minReadableLogical=$minReadableFontSize '
    'scaledLogical=${scaledWidth}x$scaledHeight overflowWidth=${scaledWidth > targetWidth} '
    'overflowLogical=$overflowLogical overflowMm=$overflowMm',
    skipFrames: 1,
  );
  return scaledSheet;
}

FortuneSheet _labelSheetScaleSheet(FortuneSheet sheet, double scale) {
  if (!scale.isFinite || scale <= 0) {
    return sheet.copyWith();
  }
  return sheet.copyWith(
    rowHeights: _labelSheetScaleAxis(sheet.rowHeights, scale),
    columnWidths: _labelSheetScaleAxis(sheet.columnWidths, scale),
    defaultRowHeight: _labelSheetScaleNullable(sheet.defaultRowHeight, scale),
    defaultColWidth: _labelSheetScaleNullable(sheet.defaultColWidth, scale),
    cells: {
      for (final entry in sheet.cells.entries)
        entry.key: _labelSheetScaleCell(entry.value, scale),
    },
  );
}

Map<int, double> _labelSheetScaleAxis(Map<int, double> values, double scale) {
  return {
    for (final entry in values.entries)
      entry.key: math.max(1.0, entry.value * scale),
  };
}

double? _labelSheetScaleNullable(double? value, double scale) {
  if (value == null) {
    return null;
  }
  return math.max(1.0, value * scale);
}

FortuneCell _labelSheetScaleCell(FortuneCell cell, double scale) {
  return cell.copyWith(
    fontSize: _labelSheetScaleNullable(cell.fontSize, scale),
    inlineRuns: cell.inlineRuns
        ?.map((run) => _labelSheetScaleInlineRun(run, scale))
        .toList(),
    extraFields: _labelSheetScaleTextExtraFields(cell.extraFields, scale),
  );
}

FortuneInlineTextRun _labelSheetScaleInlineRun(
  FortuneInlineTextRun run,
  double scale,
) {
  return run.copyWith(
    fontSize: _labelSheetScaleNullable(run.fontSize, scale),
    extraFields: _labelSheetScaleTextExtraFields(run.extraFields, scale),
  );
}

Map<String, Object?> _labelSheetScaleTextExtraFields(
  Map<String, Object?> values,
  double scale,
) {
  final scaled = <String, Object?>{...values};
  final letterSpacing = _labelSheetNumber(values['letterSpacing']);
  if (letterSpacing != null) {
    scaled['letterSpacing'] = letterSpacing * scale;
  }
  return scaled;
}

double? _labelSheetNumber(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}

double? _labelSheetMinimumFontSize(FortuneSheet sheet) {
  double? minFontSize;
  void add(double? value) {
    if (value == null || !value.isFinite || value <= 0) {
      return;
    }
    minFontSize = minFontSize == null ? value : math.min(minFontSize!, value);
  }

  for (final cell in sheet.cells.values) {
    add(cell.fontSize);
    for (final run in cell.inlineRuns ?? const <FortuneInlineTextRun>[]) {
      add(run.fontSize);
    }
  }
  return minFontSize;
}

double _labelSheetAxisLogicalTotalSizeForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize,
) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return _labelSheetAxisLogicalTotalSize(sizes);
  }
  final fallback = defaultSize ?? 0;
  var total = 0.0;
  for (var index = 0; index < resolvedCount; index += 1) {
    total += (sizes[index] ?? fallback) + 1;
  }
  return total;
}

double _labelSheetAxisScaleForTarget(
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

int _labelSheetAxisCount(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return 0;
  }
  return sizes.keys.reduce(math.max) + 1;
}

void _logImportedSheetApplySample(FortuneSheet sheet) {
  final gridSize = fortuneSheetGridClientPhysicalSize(sheet);
  final columnLogicalWidth = _labelSheetAxisLogicalTotalSize(
    sheet.columnWidths,
  );
  final rowLogicalHeight = _labelSheetAxisLogicalTotalSize(sheet.rowHeights);
  final countedColumnLogicalWidth = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.columnWidths,
    sheet.columnCount,
    sheet.defaultColWidth,
  );
  final countedRowLogicalHeight = _labelSheetAxisLogicalTotalSizeForCount(
    sheet.rowHeights,
    sheet.rowCount,
    sheet.defaultRowHeight,
  );
  final zoomRatio = sheet.zoomRatio <= 0 ? 1.0 : sheet.zoomRatio;
  final valueSamples = <String>[];
  final anchorSamples = <String>[];
  final coveredSamples = <String>[];
  for (final entry
      in sheet.cells.entries.toList()..sort((left, right) {
        final rowCompare = left.key.row.compareTo(right.key.row);
        return rowCompare == 0
            ? left.key.column.compareTo(right.key.column)
            : rowCompare;
      })) {
    final coord = entry.key;
    final cell = entry.value;
    final value = cell.displayValue ?? cell.value;
    if (value.isNotEmpty && valueSamples.length < 40) {
      valueSamples.add(
        '${_labelSheetCoordLabel(coord.row, coord.column)}=${_labelSheetLogText(value)}',
      );
    }
    final merge = cell.merge;
    if (merge == null) {
      continue;
    }
    final sample =
        '${_labelSheetCoordLabel(coord.row, coord.column)}->'
        '${_labelSheetCoordLabel(merge.row, merge.column)} '
        'span=${merge.rowSpan}x${merge.columnSpan} '
        'value=${_labelSheetLogText(value)} '
        'bg=${cell.background} fc=${cell.foreground}';
    if (merge.row == coord.row && merge.column == coord.column) {
      if (anchorSamples.length < 40) {
        anchorSamples.add(sample);
      }
    } else if (coveredSamples.length < 40) {
      coveredSamples.add(sample);
    }
  }
  debugLog(
    'label sheet import apply sample '
    'rows=${sheet.rowCount} columns=${sheet.columnCount} '
    'cells=${sheet.cells.length} borders=${sheet.borderInfo.length} '
    'zoomRatio=${sheet.zoomRatio} '
    'columnLogicalWidth=$columnLogicalWidth '
    'countedColumnLogicalWidth=$countedColumnLogicalWidth '
    'columnVisibleWidth=${columnLogicalWidth * zoomRatio} '
    'rowLogicalHeight=$rowLogicalHeight '
    'countedRowLogicalHeight=$countedRowLogicalHeight '
    'rowVisibleHeight=${rowLogicalHeight * zoomRatio} '
    'gridWidthMm=${gridSize?.widthMm} gridHeightMm=${gridSize?.heightMm} '
    'values=${valueSamples.join(' | ')} '
    'mergeAnchors=${anchorSamples.join(' | ')} '
    'mergeCovered=${coveredSamples.join(' | ')}',
    skipFrames: 1,
  );
  debugLog(
    'label sheet import apply axis '
    'rowHeights=${_labelSheetAxisSample(sheet.rowHeights)} '
    'columnWidths=${_labelSheetAxisSample(sheet.columnWidths)} '
    'rowBoundaries=${_labelSheetAxisBoundarySample(sheet.rowHeights)} '
    'columnBoundaries=${_labelSheetAxisBoundarySample(sheet.columnWidths)} '
    'rowBoundariesCounted=${_labelSheetAxisBoundarySampleForCount(sheet.rowHeights, sheet.rowCount, sheet.defaultRowHeight)} '
    'columnBoundariesCounted=${_labelSheetAxisBoundarySampleForCount(sheet.columnWidths, sheet.columnCount, sheet.defaultColWidth)}',
    skipFrames: 1,
  );
  _logLabelSheetChunks(
    'label sheet import apply row heights',
    _labelSheetAxisSamples(sheet.rowHeights),
  );
  _logLabelSheetChunks(
    'label sheet import apply column widths',
    _labelSheetAxisSamples(sheet.columnWidths),
  );
  _logLabelSheetChunks(
    'label sheet import apply row boundaries counted',
    _labelSheetAxisBoundarySamplesForCount(
      sheet.rowHeights,
      sheet.rowCount,
      sheet.defaultRowHeight,
    ),
  );
  _logLabelSheetChunks(
    'label sheet import apply column boundaries counted',
    _labelSheetAxisBoundarySamplesForCount(
      sheet.columnWidths,
      sheet.columnCount,
      sheet.defaultColWidth,
    ),
  );
  _logLabelSheetChunks(
    'label sheet import apply merge sizes',
    _labelSheetMergeSizeSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply text layout',
    _labelSheetTextLayoutSamples(sheet),
  );
  debugLog(
    'label sheet import apply border summary '
    'borderInfo=${sheet.borderInfo.length} '
    'hasRawBorderInfo=${sheet.hasRawBorderInfo} '
    'rawBorderInfoType=${sheet.rawBorderInfo.runtimeType} '
    'computedBorders=${FortuneBorderCompute.compute(sheet).length}',
    skipFrames: 1,
  );
  _logLabelSheetChunks(
    'label sheet import apply border info',
    _labelSheetBorderInfoSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply border info rows',
    _labelSheetBorderInfoRowSummarySamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed borders',
    _labelSheetComputedBorderSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed blank borders',
    _labelSheetComputedBlankBorderSamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed border rows',
    _labelSheetComputedBorderRowSummarySamples(sheet),
  );
  _logLabelSheetChunks(
    'label sheet import apply computed border row cells',
    _labelSheetComputedBorderRowCellSummarySamples(sheet),
  );
  debugLog(
    'label sheet import apply scale '
    'logicalSize=${columnLogicalWidth}x$rowLogicalHeight '
    'countedLogicalSize=${countedColumnLogicalWidth}x$countedRowLogicalHeight '
    'visibleSize=${columnLogicalWidth * zoomRatio}x${rowLogicalHeight * zoomRatio} '
    'countedVisibleSize=${countedColumnLogicalWidth * zoomRatio}x${countedRowLogicalHeight * zoomRatio} '
    'physicalSizeMm=${gridSize?.widthMm}x${gridSize?.heightMm} '
    'logicalPerMm=${_labelSheetLogicalPerMm(columnLogicalWidth, gridSize?.widthMm)}x'
    '${_labelSheetLogicalPerMm(rowLogicalHeight, gridSize?.heightMm)} '
    'countedLogicalPerMm=${_labelSheetLogicalPerMm(countedColumnLogicalWidth, gridSize?.widthMm)}x'
    '${_labelSheetLogicalPerMm(countedRowLogicalHeight, gridSize?.heightMm)}',
    skipFrames: 1,
  );
}

double _labelSheetAxisLogicalTotalSize(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return 0;
  }
  return sizes.values.fold<double>(0, (sum, size) => sum + size + 1);
}

String _labelSheetAxisSample(Map<int, double> sizes, {int limit = 24}) {
  if (sizes.isEmpty) {
    return '-';
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return entries
      .take(limit)
      .map((entry) => '${entry.key}:${entry.value}')
      .join('|');
}

List<String> _labelSheetAxisSamples(Map<int, double> sizes) {
  if (sizes.isEmpty) {
    return const <String>['-'];
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return [for (final entry in entries) '${entry.key}:${entry.value}'];
}

String _labelSheetAxisBoundarySample(Map<int, double> sizes, {int limit = 24}) {
  if (sizes.isEmpty) {
    return '-';
  }
  final entries = sizes.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  var position = 0.0;
  final samples = <String>[];
  for (final entry in entries.take(limit)) {
    position += entry.value + 1;
    samples.add('${entry.key}:$position');
  }
  return samples.join('|');
}

String _labelSheetAxisBoundarySampleForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize, {
  int limit = 30,
}) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return '-';
  }
  var position = 0.0;
  final fallback = defaultSize ?? 0;
  final samples = <String>[];
  final sampleCount = math.min(resolvedCount, limit);
  for (var index = 0; index < sampleCount; index += 1) {
    final size = sizes[index] ?? fallback;
    position += size + 1;
    samples.add('$index:$position($size)');
  }
  if (resolvedCount > limit) {
    samples.add('...count=$resolvedCount');
  }
  return samples.join('|');
}

List<String> _labelSheetAxisBoundarySamplesForCount(
  Map<int, double> sizes,
  int? count,
  double? defaultSize,
) {
  final resolvedCount = count ?? _labelSheetAxisCount(sizes);
  if (resolvedCount <= 0) {
    return const <String>['-'];
  }
  var position = 0.0;
  final fallback = defaultSize ?? 0;
  final samples = <String>[];
  for (var index = 0; index < resolvedCount; index += 1) {
    final size = sizes[index] ?? fallback;
    position += size + 1;
    samples.add('$index:$position($size)');
  }
  return samples;
}

List<String> _labelSheetMergeSizeSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  final entries = sheet.cells.entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  for (final entry in entries) {
    final merge = entry.value.merge;
    if (merge == null ||
        merge.row != entry.key.row ||
        merge.column != entry.key.column) {
      continue;
    }
    final width = _labelSheetAxisRangeLogicalSize(
      sheet.columnWidths,
      merge.column,
      merge.columnSpan,
      sheet.defaultColWidth,
    );
    final height = _labelSheetAxisRangeLogicalSize(
      sheet.rowHeights,
      merge.row,
      merge.rowSpan,
      sheet.defaultRowHeight,
    );
    final value = entry.value.displayValue ?? entry.value.value;
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'span=${merge.rowSpan}x${merge.columnSpan} logical=${width}x$height '
      'value=${_labelSheetLogText(value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetTextLayoutSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  final entries = sheet.cells.entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  for (final entry in entries) {
    final cell = entry.value;
    final value = cell.displayValue ?? cell.value;
    if (value.isEmpty) {
      continue;
    }
    final merge = cell.merge;
    final isCovered =
        merge != null &&
        (merge.row != entry.key.row || merge.column != entry.key.column);
    if (isCovered) {
      continue;
    }
    final row = merge?.row ?? entry.key.row;
    final column = merge?.column ?? entry.key.column;
    final rowSpan = merge?.rowSpan ?? 1;
    final columnSpan = merge?.columnSpan ?? 1;
    final width = _labelSheetAxisRangeLogicalSize(
      sheet.columnWidths,
      column,
      columnSpan,
      sheet.defaultColWidth,
    );
    final height = _labelSheetAxisRangeLogicalSize(
      sheet.rowHeights,
      row,
      rowSpan,
      sheet.defaultRowHeight,
    );
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'len=${value.length} lines=${_labelSheetLineCount(value)} '
      'span=${rowSpan}x$columnSpan logical=${width}x$height '
      'fs=${cell.fontSize} bold=${cell.bold} wrap=${cell.textWrap} '
      'ha=${cell.horizontalAlign} va=${cell.verticalAlign} '
      'value=${_labelSheetLogText(value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetBorderInfoSamples(
  FortuneSheet sheet, {
  int limit = 200,
}) {
  final samples = <String>[];
  for (final info in sheet.borderInfo) {
    for (final range in info.ranges) {
      samples.add(
        '${info.borderType} range=${_labelSheetRangeLogText(range)} '
        'style=${info.style} stroke=${info.strokeWidth} '
        'color=${info.color}',
      );
      if (samples.length >= limit) {
        return samples;
      }
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetComputedBorderSamples(
  FortuneSheet sheet, {
  int limit = 1000,
}) {
  final computed = FortuneBorderCompute.compute(sheet).entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  final samples = <String>[];
  for (final entry in computed) {
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      '${_labelSheetCellBordersLogText(entry.value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetComputedBlankBorderSamples(
  FortuneSheet sheet, {
  int limit = 400,
}) {
  final computed = FortuneBorderCompute.compute(sheet).entries.toList()
    ..sort((left, right) {
      final rowCompare = left.key.row.compareTo(right.key.row);
      return rowCompare == 0
          ? left.key.column.compareTo(right.key.column)
          : rowCompare;
    });
  final samples = <String>[];
  for (final entry in computed) {
    final cell = sheet.cells[entry.key];
    final value = cell?.displayValue ?? cell?.value ?? '';
    final merge = cell?.merge;
    final isMergeCovered =
        merge != null &&
        (merge.row != entry.key.row || merge.column != entry.key.column);
    if (value.isNotEmpty || isMergeCovered) {
      continue;
    }
    samples.add(
      '${_labelSheetCoordLabel(entry.key.row, entry.key.column)} '
      'state=${_labelSheetComputedBorderCellState(sheet, entry.key)} '
      '${_labelSheetCellBordersLogText(entry.value)}',
    );
    if (samples.length >= limit) {
      break;
    }
  }
  return samples.isEmpty ? const <String>['-'] : samples;
}

List<String> _labelSheetBorderInfoRowSummarySamples(FortuneSheet sheet) {
  final countsByRow = <int, Map<String, int>>{};
  for (final info in sheet.borderInfo) {
    for (final range in info.ranges) {
      for (var row = range.rowStart; row <= range.rowEnd; row += 1) {
        final counts = countsByRow.putIfAbsent(row, () => <String, int>{});
        final key =
            '${info.borderType}/style=${info.style}/stroke=${info.strokeWidth}';
        counts[key] =
            (counts[key] ?? 0) + range.columnEnd - range.columnStart + 1;
      }
    }
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

List<String> _labelSheetComputedBorderRowSummarySamples(FortuneSheet sheet) {
  final countsByRow = <int, Map<String, int>>{};
  final computed = FortuneBorderCompute.compute(sheet);
  for (final entry in computed.entries) {
    final counts = countsByRow.putIfAbsent(
      entry.key.row,
      () => <String, int>{},
    );
    _labelSheetCountComputedBorderSide(counts, 'top', entry.value.top);
    _labelSheetCountComputedBorderSide(counts, 'right', entry.value.right);
    _labelSheetCountComputedBorderSide(counts, 'bottom', entry.value.bottom);
    _labelSheetCountComputedBorderSide(counts, 'left', entry.value.left);
    _labelSheetCountComputedBorderSide(counts, 'slash', entry.value.slash);
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

List<String> _labelSheetComputedBorderRowCellSummarySamples(
  FortuneSheet sheet,
) {
  final countsByRow = <int, Map<String, int>>{};
  final computed = FortuneBorderCompute.compute(sheet);
  for (final coord in computed.keys) {
    final counts = countsByRow.putIfAbsent(coord.row, () => <String, int>{});
    final state = _labelSheetComputedBorderCellState(sheet, coord);
    counts[state] = (counts[state] ?? 0) + 1;
  }
  return _labelSheetBorderRowSummaryLogSamples(countsByRow);
}

String _labelSheetComputedBorderCellState(
  FortuneSheet sheet,
  FortuneCellCoord coord,
) {
  final cell = sheet.cells[coord];
  if (cell == null) {
    return 'noCell';
  }
  final value = cell.displayValue ?? cell.value;
  final merge = cell.merge;
  if (merge != null &&
      (merge.row != coord.row || merge.column != coord.column)) {
    return value.isEmpty ? 'mergeCoveredBlank' : 'mergeCoveredValue';
  }
  if (merge != null) {
    return value.isEmpty ? 'mergeAnchorBlank' : 'mergeAnchorValue';
  }
  return value.isEmpty ? 'blank' : 'value';
}

void _labelSheetCountComputedBorderSide(
  Map<String, int> counts,
  String sideName,
  FortuneBorderSide? side,
) {
  if (side == null) {
    return;
  }
  final key = '$sideName/style=${side.style}/stroke=${side.strokeWidth}';
  counts[key] = (counts[key] ?? 0) + 1;
}

List<String> _labelSheetBorderRowSummaryLogSamples(
  Map<int, Map<String, int>> countsByRow,
) {
  if (countsByRow.isEmpty) {
    return const <String>['-'];
  }
  final samples = <String>[];
  for (final row in countsByRow.keys.toList()..sort()) {
    final counts = countsByRow[row]!;
    final summary = counts.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    samples.add(
      '${_labelSheetCoordLabel(row, 0).replaceFirst('A', 'row')} '
      '${summary.map((entry) => '${entry.key}:${entry.value}').join(',')}',
    );
  }
  return samples;
}

String _labelSheetRangeLogText(FortuneRange range) {
  return '${_labelSheetCoordLabel(range.rowStart, range.columnStart)}:'
      '${_labelSheetCoordLabel(range.rowEnd, range.columnEnd)} '
      'focus=${range.rowFocus},${range.columnFocus}';
}

String _labelSheetCellBordersLogText(FortuneCellBorders borders) {
  final sides = <String>[];
  if (borders.top != null) {
    sides.add('top=${_labelSheetBorderSideLogText(borders.top!)}');
  }
  if (borders.right != null) {
    sides.add('right=${_labelSheetBorderSideLogText(borders.right!)}');
  }
  if (borders.bottom != null) {
    sides.add('bottom=${_labelSheetBorderSideLogText(borders.bottom!)}');
  }
  if (borders.left != null) {
    sides.add('left=${_labelSheetBorderSideLogText(borders.left!)}');
  }
  if (borders.slash != null) {
    sides.add('slash=${_labelSheetBorderSideLogText(borders.slash!)}');
  }
  return sides.isEmpty ? '-' : sides.join(',');
}

String _labelSheetBorderSideLogText(FortuneBorderSide side) {
  return 'style=${side.style}/stroke=${side.strokeWidth}/color=${side.color}';
}

void _logLabelSheetChunks(String prefix, List<String> samples) {
  const maxChunkLength = 1200;
  var chunk = StringBuffer();
  var chunkIndex = 1;
  var sampleIndex = 0;
  void flush() {
    if (chunk.isEmpty) {
      return;
    }
    debugLog(
      '$prefix chunk=$chunkIndex sampleStart=$sampleIndex ${chunk.toString()}',
      skipFrames: 1,
    );
    chunk = StringBuffer();
    chunkIndex += 1;
  }

  for (var index = 0; index < samples.length; index += 1) {
    final sample = samples[index];
    final next = chunk.isEmpty ? sample : ' | $sample';
    if (chunk.isNotEmpty && chunk.length + next.length > maxChunkLength) {
      flush();
      sampleIndex = index;
    }
    if (chunk.isEmpty) {
      chunk.write(sample);
    } else {
      chunk.write(next);
    }
  }
  flush();
}

double _labelSheetAxisRangeLogicalSize(
  Map<int, double> sizes,
  int start,
  int span,
  double? defaultSize,
) {
  var total = 0.0;
  final fallback = defaultSize ?? 0;
  for (var index = start; index < start + span; index += 1) {
    total += (sizes[index] ?? fallback) + 1;
  }
  return total;
}

String _labelSheetLogicalPerMm(double logicalSize, num? mm) {
  if (mm == null || mm <= 0) {
    return '-';
  }
  return (logicalSize / mm.toDouble()).toStringAsFixed(4);
}

String _labelSheetCoordLabel(int row, int column) {
  var value = column + 1;
  final letters = StringBuffer();
  while (value > 0) {
    value -= 1;
    letters.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return '${letters.toString().split('').reversed.join()}${row + 1}';
}

String _labelSheetLogText(String value) {
  final singleLine = value.replaceAll('\r', r'\r').replaceAll('\n', r'\n');
  return singleLine.length <= 60
      ? singleLine
      : '${singleLine.substring(0, 60)}...';
}

int _labelSheetLineCount(String value) {
  if (value.isEmpty) {
    return 0;
  }
  return '\n'.allMatches(value).length + 1;
}

class LabelSheetWorkbench extends StatefulWidget {
  const LabelSheetWorkbench({
    this.initialWorkbook,
    this.labelSize,
    this.labelRtf,
    this.imageObjectIds = const <String>[],
    this.barcodeObjectIds = const <String>[],
    this.imageObjectOptions = const <FortuneObjectConnectionOption>[],
    this.barcodeObjectOptions = const <FortuneObjectConnectionOption>[],
    this.toolbarItems,
    this.hideToolbar = false,
    this.hideRowColumnHeaders = false,
    this.hideRowColumnHeaderLabels = false,
    this.hideSelectionHighlight = false,
    this.singleClickCellEdit = false,
    this.hidePrintAreaBoundary = false,
    this.initialDirty = false,
    this.fitSingleCellToViewport = false,
    this.rulerCornerSizeLabelUsesAsterisk = false,
    this.disableSheetRulerGuideInteraction = false,
    this.hideStatisticBar = false,
    this.copyOnlyContextMenu = false,
    this.limitCellActionsToClipboardAndClear = false,
    this.canEditObjects = true,
    this.allowObjectPanel = true,
    this.showObjectPanelOpenButton = true,
    this.zoomToolbarPlacement = LabelSheetZoomToolbarPlacement.sheetToolbarEnd,
    this.zoomToolbarBackgroundColor,
    this.zoomToolbarUseIcons = false,
    this.zoomController,
    this.onInitialLoadComplete,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
    this.printerListProvider,
    this.barcodeRenderer,
    this.imageImportController,
    this.imageImportUseRootOverlay = false,
    this.editingLifecycleController,
    this.outputCaptureController,
    this.outputCaptureOwnerToken,
    this.onWorkbookChanged,
    this.onUserWorkbookChanged,
    this.onUserWorkbookChangedShouldNotify,
    this.onDirtyChanged,
    this.onSave,
    super.key,
  });

  final FortuneWorkbook? initialWorkbook;
  final LabelSize? labelSize;
  final String? labelRtf;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final List<FortuneObjectConnectionOption> imageObjectOptions;
  final List<FortuneObjectConnectionOption> barcodeObjectOptions;
  final List<String>? toolbarItems;
  final bool hideToolbar;
  final bool hideRowColumnHeaders;
  final bool hideRowColumnHeaderLabels;
  final bool hideSelectionHighlight;
  final bool singleClickCellEdit;
  final bool hidePrintAreaBoundary;
  final bool initialDirty;
  final bool fitSingleCellToViewport;
  final bool rulerCornerSizeLabelUsesAsterisk;
  final bool disableSheetRulerGuideInteraction;
  final bool hideStatisticBar;
  final bool copyOnlyContextMenu;
  final bool limitCellActionsToClipboardAndClear;
  final bool canEditObjects;
  final bool allowObjectPanel;
  final bool showObjectPanelOpenButton;
  final LabelSheetZoomToolbarPlacement zoomToolbarPlacement;
  final Color? zoomToolbarBackgroundColor;
  final bool zoomToolbarUseIcons;
  final LabelSheetZoomController? zoomController;
  final VoidCallback? onInitialLoadComplete;
  final ValueChanged<ui.Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;
  final LabelPrinterListProvider? printerListProvider;
  final FortuneBarcodeRenderer? barcodeRenderer;
  final LabelSheetImageImportController? imageImportController;
  final bool imageImportUseRootOverlay;
  final LabelSheetEditingLifecycleController? editingLifecycleController;
  final LabelSheetOutputCaptureController? outputCaptureController;
  final Object? outputCaptureOwnerToken;
  final ValueChanged<FortuneWorkbook>? onWorkbookChanged;
  final ValueChanged<FortuneWorkbook>? onUserWorkbookChanged;
  final bool Function(FortuneWorkbook previous, FortuneWorkbook current)?
  onUserWorkbookChangedShouldNotify;
  final ValueChanged<bool>? onDirtyChanged;
  final FutureOr<LabelSheetSaveResult> Function(
    int widthMm,
    int heightMm,
    String encodedWorkbook,
  )?
  onSave;

  @override
  State<LabelSheetWorkbench> createState() => _LabelSheetWorkbenchState();
}

enum LabelSheetSaveResult { applied, notApplied }

class LabelSheetEditingLifecycleController {
  _LabelSheetWorkbenchState? _state;

  bool get isAttached => _state != null;
  bool get barcodePropertyRenderPending =>
      _state?._controller.barcodePropertyRenderPending ?? false;

  bool prepareForOwnerReplacement() {
    final state = _state;
    if (state == null) return true;
    return state._controller.finalizeActiveObjectPropertyDraft();
  }

  void _attach(_LabelSheetWorkbenchState state) {
    if (_state != null && _state != state) {
      throw StateError(
        'LabelSheetEditingLifecycleController is already attached.',
      );
    }
    _state = state;
  }

  void _detach(_LabelSheetWorkbenchState state) {
    if (_state == state) _state = null;
  }
}
class LabelSheetImageImportController {
  _LabelSheetWorkbenchState? _state;

  bool get isAttached => _state != null;

  Future<void> openWithImageFile({
    required Uint8List bytes,
    required String fileName,
    required String filePath,
    required String mimeType,
  }) async {
    await _state?._openLabelImageImportWithInitialImage(
      LabelSheetImageImportSelection(
        bytes: bytes,
        mimeType: mimeType,
        fileName: fileName,
        filePath: filePath,
      ),
    );
  }

  void _attach(_LabelSheetWorkbenchState state) {
    _state = state;
  }

  void _detach(_LabelSheetWorkbenchState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class LabelSheetOutputCapture {
  const LabelSheetOutputCapture({
    required this.pngBytes,
    required this.sheet,
    required this.range,
    required this.sourceWidthMm,
    required this.sourceHeightMm,
  });

  final Uint8List pngBytes;
  final FortuneSheet sheet;
  final FortuneRange range;
  final double sourceWidthMm;
  final double sourceHeightMm;
}

class LabelSheetHybridEzplCapture {
  const LabelSheetHybridEzplCapture({
    required this.bytes,
    required this.sheet,
    required this.range,
    required this.metrics,
    required this.plan,
  });

  final Uint8List bytes;
  final FortuneSheet sheet;
  final FortuneRange range;
  final LabelSheetPrintPageMetrics metrics;
  final FortuneHybridRenderPlan plan;
}

class LabelSheetOutputCaptureController {
  _LabelSheetWorkbenchState? _state;
  Object? _ownerToken;
  Object? _replacementOwnerToken;

  bool get isAttached => _state != null;
  Object? get attachedOwnerToken => _ownerToken;

  @visibleForTesting
  FortuneSheet? get debugActiveSheet => _state?._latestWorkbook.activeSheet;

  Future<LabelSheetOutputCapture?> capture({
    required double dpi,
    required int? lineSpacingPercent,
  }) =>
      _state?._captureOutput(
        dpi: dpi,
        lineSpacingPercent: lineSpacingPercent,
      ) ??
      Future<LabelSheetOutputCapture?>.value();

  Future<LabelSheetHybridEzplCapture?> captureHybridEzpl({
    required LabelSheetPrintPageMetrics metrics,
    required LabelSheetPrintOptions options,
    required int? lineSpacingPercent,
  }) =>
      _state?._captureHybridEzpl(
        metrics: metrics,
        options: options,
        lineSpacingPercent: lineSpacingPercent,
      ) ??
      Future<LabelSheetHybridEzplCapture?>.value();

  void replaceAttachedOwner({
    required Object expectedOwnerToken,
    required Object newOwnerToken,
  }) {
    if (_state == null || _ownerToken != expectedOwnerToken) {
      throw StateError('The expected output capture owner is not attached.');
    }
    _replacementOwnerToken = newOwnerToken;
  }

  void _attach(_LabelSheetWorkbenchState state, Object ownerToken) {
    _validateAttach(state, ownerToken);
    _state = state;
    _ownerToken = ownerToken;
    _replacementOwnerToken = null;
  }

  void _validateAttach(_LabelSheetWorkbenchState state, Object ownerToken) {
    if (_state != null &&
        _state != state &&
        _ownerToken != ownerToken &&
        _replacementOwnerToken != ownerToken) {
      throw StateError(
        'LabelSheetOutputCaptureController is already attached.',
      );
    }
  }

  void _detach(_LabelSheetWorkbenchState state) {
    if (_state == state) {
      _state = null;
      _ownerToken = null;
      _replacementOwnerToken = null;
    }
  }
}

class _LabelSheetWorkbenchState extends State<LabelSheetWorkbench>
    with WidgetsBindingObserver {
  late final FortuneWorkbook _fallbackWorkbook = labelSheetWorkbook(
    _baseWorkbook,
    labelSize: widget.labelSize,
    labelRtf: widget.labelRtf,
  );
  late final Future<FortuneWorkbook> _initialWorkbook =
      labelSheetWorkbookWithRtf(
        _baseWorkbook,
        labelSize: widget.labelSize,
        labelRtf: widget.labelRtf,
      );
  late final FortuneSheetController _controller = FortuneSheetController();
  final FocusScopeNode _objectPanelFocusScopeNode = FocusScopeNode(
    debugLabel: 'Label sheet object panel focus scope',
  );
  late final TextEditingController _zoomController = TextEditingController(
    text: '$labelSheetDefaultZoomPercent',
  );
  late final TextEditingController _printLeftMarginController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printTopMarginController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printExtraAreaController =
      TextEditingController(text: '0.0');
  late final TextEditingController _printCopiesController =
      TextEditingController(text: '1');
  late final FocusNode _zoomFocusNode = FocusNode();
  final FocusNode _objectOverlayOpenButtonFocusNode = FocusNode(
    debugLabel: 'Label sheet object panel open button',
  );
  final LayerLink _zoomToolbarLayerLink = LayerLink();
  final GlobalKey _sheetAppKey = GlobalKey(debugLabel: 'label_sheet_sheet_app');
  OverlayEntry? _zoomToolbarOverlayEntry;
  int? _zoomEditOriginalPercent;
  bool _zoomCommitPendingBlur = false;
  late FortuneSheetLocale _locale = _localeForPlatform();
  late FortuneWorkbook _latestWorkbook = _fallbackWorkbook;
  FortuneWorkbook? _workbookBeforeLastChange;
  int _zoomPercent = labelSheetDefaultZoomPercent;
  bool _isDirty = false;
  bool _controllerRebuildScheduled = false;
  bool _rtfSnackBarVisible = false;
  int _rtfSnackBarGeneration = 0;
  bool _rtfImportMarkedDirty = false;
  bool _initialLoadCompleteNotified = false;
  bool _initialWorkbookOpsSettled = false;
  bool _initialZoomSynced = false;
  bool _printSettingsDialogOpen = false;
  static const String _objectPanelWidthPreferenceKey =
      'label_sheet_object_panel_width';
  bool _userWantsObjectDockOpen = true;
  bool _objectOverlayOpen = false;
  bool _objectDockEligible = true;
  double _objectPanelWidth = _labelSheetObjectPanelInitialWidth;
  String? _objectPropertyFocusField;
  String? _objectPropertyFocusSheetId;
  FortuneSheetObjectKey? _objectPropertyFocusObjectKey;
  int _objectPropertyFocusGeneration = 0;
  int _objectLayerFocusGeneration = 0;
  FortuneObjectPanelPresentation? _lastObjectPanelPresentation;
  int _objectPanelFocusHandoffGeneration = 0;
  FocusNode? _objectOverlayTriggerFocus;
  FocusNode? _objectOverlayPreviousFocus;
  FortuneObjectPanelCloseFocusTarget _objectOverlayCloseFocusTarget =
      FortuneObjectPanelCloseFocusTarget.previousFocus;
  bool _objectPanelExplicitClosePending = false;
  double? _objectPanelDragStartWidth;
  bool _objectPanelWidthChangedByUser = false;
  Future<void> _objectPanelWidthWriteQueue = Future<void>.value();
  BuildContext? _printSettingsDialogContext;
  VoidCallback? _rebuildPrintSettingsDialog;
  String _printAutoSpacing = 'none';
  String _printOrientation = 'horizontal';
  String _printSelectedPrinterName = '';

  FortuneWorkbook get _baseWorkbook {
    final workbook =
        widget.initialWorkbook ??
        FortuneWorkbook(
          sheets: [FortuneSheet(id: 'label_sheet_01', name: 'Labels')],
        );
    return _workbookWithExternalZoom(workbook);
  }

  FortuneWorkbook _workbookWithExternalZoom(FortuneWorkbook workbook) {
    final externalController = widget.zoomController;
    if (externalController == null || workbook.sheets.isEmpty) {
      return workbook;
    }
    final activeIndex = workbook.activeSheetIndex.clamp(
      0,
      workbook.sheets.length - 1,
    );
    final zoomRatio =
        externalController.value.clamp(
          externalController.minPercent,
          externalController.maxPercent,
        ) /
        100;
    if (workbook.sheets[activeIndex].zoomRatio == zoomRatio) {
      return workbook;
    }
    final sheets = [...workbook.sheets];
    sheets[activeIndex] = sheets[activeIndex].copyWith(zoomRatio: zoomRatio);
    return workbook.copyWith(sheets: sheets, activeSheetIndex: activeIndex);
  }

  FortuneSettings _sheetSettings(
    FortuneWorkbook workbook,
  ) => labelSheetSettings(
    workbook.settings,
    onImportLabelImage: _handleImportLabelImage,
    onSave: _handleSave,
    onImportLabelFile: _handleImportLabelFile,
    onExportLabelFile: _handleExportLabelFile,
    contextMenuDisabledItemsBuilder: _labelFileContextMenuDisabledItems,
    onPrint: _handlePrint,
    onDialogVisibilityChanged: _handleFortuneDialogVisibilityChanged,
    saveEnabled:
        (_isDirty || _controller.projectedCanonicalChange) &&
        !_controller.barcodePropertyRenderPending,
    importImageTooltip: _labelSheetImportImageTooltip(),
    hideToolbar: widget.hideToolbar,
    saveTooltip: _labelSheetSaveTooltip(),
    printTooltip: _labelSheetPrintTooltip(),
    toolbarItems: widget.toolbarItems,
    hideRowColumnHeaders: widget.hideRowColumnHeaders,
    hideRowColumnHeaderLabels: widget.hideRowColumnHeaderLabels,
    hideSelectionHighlight: widget.hideSelectionHighlight,
    singleClickCellEdit: widget.singleClickCellEdit,
    hidePrintAreaBoundary: widget.hidePrintAreaBoundary,
    fitSingleCellToViewport: widget.fitSingleCellToViewport,
    rulerCornerSizeLabelUsesAsterisk: widget.rulerCornerSizeLabelUsesAsterisk,
    disableSheetRulerGuideInteraction: widget.disableSheetRulerGuideInteraction,
    hideStatisticBar: widget.hideStatisticBar,
    copyOnlyContextMenu: widget.copyOnlyContextMenu,
    limitCellActionsToClipboardAndClear:
        widget.limitCellActionsToClipboardAndClear,
    canEditObjects: widget.canEditObjects,
  );

  FortuneSheetGridClientPhysicalSize? get _gridClientSize {
    final common = widget.labelSize?.labelSizeCommon;
    if (common == null) {
      return const FortuneSheetGridClientPhysicalSize(
        widthMm: labelSheetDefaultPhysicalWidthMm,
        heightMm: labelSheetDefaultPhysicalHeightMm,
      );
    }
    return FortuneSheetGridClientPhysicalSize(
      widthMm: labelSheetPositivePhysicalSizeOrDefault(
        common.width,
        labelSheetDefaultPhysicalWidthMm,
      ),
      heightMm: labelSheetPositivePhysicalSizeOrDefault(
        common.height,
        labelSheetDefaultPhysicalHeightMm,
      ),
    );
  }

  void _openObjectPanel({
    FocusNode? triggerFocus,
    FocusNode? previousFocus,
    FortuneObjectPanelCloseFocusTarget closeFocusTarget =
        FortuneObjectPanelCloseFocusTarget.previousFocus,
  }) {
    if (!mounted) return;
    if (_objectDockEligible && _userWantsObjectDockOpen ||
        !_objectDockEligible && _objectOverlayOpen) {
      return;
    }
    _controller.dismissObjectPanelPresentationTransients();
    setState(() {
      if (_objectDockEligible) {
        _userWantsObjectDockOpen = true;
        _objectOverlayOpen = false;
        _objectOverlayTriggerFocus = null;
        _objectOverlayPreviousFocus = null;
        _objectOverlayCloseFocusTarget =
            FortuneObjectPanelCloseFocusTarget.previousFocus;
      } else {
        _objectOverlayTriggerFocus = triggerFocus;
        _objectOverlayPreviousFocus =
            previousFocus ?? FocusManager.instance.primaryFocus;
        _objectOverlayCloseFocusTarget = closeFocusTarget;
        _objectOverlayOpen = true;
        _objectLayerFocusGeneration += 1;
      }
    });
  }

  void _openObjectOverlayFromButton() {
    final previousFocus = FocusManager.instance.primaryFocus;
    _openObjectPanel(
      triggerFocus: _objectOverlayOpenButtonFocusNode,
      previousFocus: previousFocus == _objectOverlayOpenButtonFocusNode
          ? null
          : previousFocus,
    );
  }

  void _handleObjectPanelOpenRequest(FortuneObjectPanelOpenRequest request) {
    if (!mounted) return;
    if (!widget.allowObjectPanel) return;
    final editRequest =
        request.propertyField != null && request.objectKey != null;
    if (!editRequest) {
      _openObjectPanel(closeFocusTarget: request.closeFocusTarget);
      return;
    }
    setState(() {
      _objectPropertyFocusField = request.propertyField;
      _objectPropertyFocusSheetId = request.sheetId;
      _objectPropertyFocusObjectKey = request.objectKey;
      _objectPropertyFocusGeneration += 1;
      if (_objectDockEligible) {
        _userWantsObjectDockOpen = true;
        _objectOverlayOpen = false;
        _objectOverlayTriggerFocus = null;
        _objectOverlayPreviousFocus = null;
        _objectOverlayCloseFocusTarget =
            FortuneObjectPanelCloseFocusTarget.previousFocus;
      } else {
        if (!_objectOverlayOpen) {
          _objectOverlayTriggerFocus = null;
          _objectOverlayPreviousFocus = FocusManager.instance.primaryFocus;
          _objectOverlayCloseFocusTarget = request.closeFocusTarget;
        }
        _objectOverlayOpen = true;
      }
    });
  }

  void _syncObjectPanelFocusHandoff(
    FortuneObjectPanelPresentation presentation,
  ) {
    final previous = _lastObjectPanelPresentation;
    _lastObjectPanelPresentation = presentation;
    if (presentation != FortuneObjectPanelPresentation.hidden ||
        previous == null ||
        previous == FortuneObjectPanelPresentation.hidden) {
      return;
    }
    if (_objectPanelExplicitClosePending) {
      _objectPanelExplicitClosePending = false;
      final generation = ++_objectPanelFocusHandoffGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _objectPanelFocusHandoffGeneration) {
          return;
        }
        final triggerFocus = _objectOverlayTriggerFocus;
        final previousFocus = _objectOverlayPreviousFocus;
        final closeFocusTarget = _objectOverlayCloseFocusTarget;
        _objectOverlayTriggerFocus = null;
        _objectOverlayPreviousFocus = null;
        _objectOverlayCloseFocusTarget =
            FortuneObjectPanelCloseFocusTarget.previousFocus;
        _restoreObjectOverlayFocus(
          triggerFocus,
          closeFocusTarget: closeFocusTarget,
          fallbackFocus: previousFocus,
        );
      });
      return;
    }
    final generation = ++_objectPanelFocusHandoffGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _objectPanelFocusHandoffGeneration) return;
      _objectOverlayTriggerFocus = null;
      _objectOverlayPreviousFocus = null;
      _objectOverlayCloseFocusTarget =
          FortuneObjectPanelCloseFocusTarget.previousFocus;
      if (_objectPanelFocusScopeNode.hasFocus) {
        _controller.focusCanvas();
      }
    });
  }

  bool _canRestoreFocusToNode(FocusNode? focusNode) {
    return focusNode != null &&
        focusNode.canRequestFocus &&
        focusNode.context != null;
  }

  void _restoreObjectOverlayFocus(
    FocusNode? triggerFocus,
    {
    required FortuneObjectPanelCloseFocusTarget closeFocusTarget,
    FocusNode? fallbackFocus,
  }) {
    if (_canRestoreFocusToNode(triggerFocus)) {
      _restoreFocusNodeWithRetry(
        triggerFocus!,
        fallbackFocus: fallbackFocus,
      );
      return;
    }
    if (closeFocusTarget == FortuneObjectPanelCloseFocusTarget.canvas) {
      _restoreCanvasFocusWithRetry();
      return;
    }
    final primaryFocus = _canRestoreFocusToNode(fallbackFocus)
        ? fallbackFocus
        : null;
    if (primaryFocus == null) {
      _controller.focusCanvas();
      return;
    }
    _restoreFocusNodeWithRetry(primaryFocus);
  }

  void _restoreFocusNodeWithRetry(
    FocusNode focusNode, {
    FocusNode? fallbackFocus,
  }) {
    focusNode.requestFocus();
    final generation = _objectPanelFocusHandoffGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _objectPanelFocusHandoffGeneration) {
        return;
      }
      if (focusNode.hasFocus) {
        return;
      }
      final retryFocus = _canRestoreFocusToNode(focusNode)
          ? focusNode
          : _canRestoreFocusToNode(fallbackFocus)
          ? fallbackFocus
          : null;
      if (retryFocus != null) {
        retryFocus.requestFocus();
      } else {
        _controller.focusCanvas();
      }
    });
  }

  void _restoreCanvasFocusWithRetry() {
    _controller.focusCanvas();
    final generation = _objectPanelFocusHandoffGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _objectPanelFocusHandoffGeneration) {
        return;
      }
      _controller.focusCanvas();
    });
  }

  void _closeObjectPanel() {
    if (!mounted) return;
    if (_objectDockEligible && !_userWantsObjectDockOpen ||
        !_objectDockEligible && !_objectOverlayOpen) {
      return;
    }
    setState(() {
      _objectPropertyFocusField = null;
      _objectPropertyFocusSheetId = null;
      _objectPropertyFocusObjectKey = null;
      _objectPropertyFocusGeneration += 1;
      if (_objectDockEligible) {
        _userWantsObjectDockOpen = false;
        _objectOverlayOpen = false;
        _objectOverlayTriggerFocus = null;
        _objectOverlayPreviousFocus = null;
        _objectOverlayCloseFocusTarget =
            FortuneObjectPanelCloseFocusTarget.previousFocus;
      } else {
        _objectPanelExplicitClosePending = true;
        _objectOverlayOpen = false;
      }
    });
  }

  Future<void> _loadObjectPanelWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final width = prefs.getDouble(_objectPanelWidthPreferenceKey);
    if (!mounted || width == null || _objectPanelWidthChangedByUser) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _objectPanelWidthChangedByUser) {
        return;
      }
      setState(() {
        _objectPanelWidth = math.max(_labelSheetObjectPanelMinWidth, width);
      });
    });
  }

  void _queueObjectPanelWidthSave(double width) {
    _objectPanelWidthWriteQueue = _objectPanelWidthWriteQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_objectPanelWidthPreferenceKey, width);
      } on Object {
        // Preference persistence is best effort; later writes must continue.
      }
    });
  }

  void _notifyGridRectChanged(
    Size size,
    FortuneWorkbook workbook,
    FortuneSettings settings,
  ) {
    final callback = widget.onGridRectChanged;
    if (callback == null) {
      return;
    }
    final gridRect = _gridRect(size, workbook, settings);
    if (gridRect == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) {
        return;
      }
      callback(gridRect.shift(box.localToGlobal(Offset.zero)));
    });
  }

  ui.Rect? _gridRect(
    Size size,
    FortuneWorkbook workbook,
    FortuneSettings settings,
  ) {
    final sheet = workbook.activeSheet;
    if (fortuneSheetGridClientPhysicalSize(sheet) == null) {
      return null;
    }
    final sheetTop =
        settings.effectiveToolbarHeight + settings.effectiveFormulaBarHeight;
    final footerHeight =
        settings.effectiveSheetBarHeight + settings.statisticBarHeight;
    final dataLeft = settings.rowHeaderWidth * 2;
    final dataTop = settings.columnHeaderHeight * 2;
    final metrics = sheet.metrics(settings);
    var dataWidth = math.max(0.0, size.width - dataLeft);
    var dataHeight = math.max(
      0.0,
      size.height - sheetTop - footerHeight - dataTop,
    );
    var vertical = metrics.rowTotalHeight > dataHeight;
    var horizontal = metrics.columnTotalWidth > dataWidth;
    if (vertical) {
      dataWidth = math.max(0.0, dataWidth - fortuneSheetScrollbarThickness);
    }
    if (horizontal) {
      dataHeight = math.max(0.0, dataHeight - fortuneSheetScrollbarThickness);
    }
    if (!vertical && metrics.rowTotalHeight > dataHeight) {
      dataWidth = math.max(0.0, dataWidth - fortuneSheetScrollbarThickness);
    }
    if (!horizontal && metrics.columnTotalWidth > dataWidth) {
      dataHeight = math.max(0.0, dataHeight - fortuneSheetScrollbarThickness);
    }
    final width = math.min(math.max(0.0, metrics.columnTotalWidth), dataWidth);
    final height = math.min(math.max(0.0, metrics.rowTotalHeight), dataHeight);
    if (width <= 0 || height <= 0) {
      return null;
    }
    return ui.Rect.fromLTWH(dataLeft, sheetTop + dataTop, width, height);
  }

  @override
  void initState() {
    super.initState();
    _isDirty = widget.initialDirty;
    _userWantsObjectDockOpen = widget.allowObjectPanel;
    _objectOverlayOpen = false;
    _controller.addListener(_handleControllerCommandStateChanged);
    _initializeZoomFromExternalController();
    widget.zoomController?.bindZoomSetter(_setLabelSheetZoomPercent);
    widget.imageImportController?._attach(this);
    widget.editingLifecycleController?._attach(this);
    widget.outputCaptureController?._attach(
      this,
      widget.outputCaptureOwnerToken ?? this,
    );
    _zoomFocusNode
      ..addListener(_handleZoomFocusChanged)
      ..onKeyEvent = _handleZoomInputKeyEvent;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadObjectPanelWidth());
  }

  @override
  void deactivate() {
    widget.editingLifecycleController?._detach(this);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    widget.editingLifecycleController?._attach(this);
  }

  @override
  void dispose() {
    _objectPropertyFocusGeneration += 1;
    _objectPanelFocusHandoffGeneration += 1;
    _objectOverlayTriggerFocus = null;
    _objectOverlayPreviousFocus = null;
    _controller.removeListener(_handleControllerCommandStateChanged);
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.objectSelection.attached) {
        controller.dispose();
      }
    });
    widget.zoomController?.unbindZoomSetter(_setLabelSheetZoomPercent);
    widget.imageImportController?._detach(this);
    widget.editingLifecycleController?._detach(this);
    widget.outputCaptureController?._detach(this);
    _removeZoomToolbarFloatingOverlay();
    if (_rtfSnackBarVisible) {
      _rtfSnackBarVisible = false;
      final generation = ++_rtfSnackBarGeneration;
      fortuneSheetDebugLog(
        'rtf snackbar dispose hide generation=$generation '
        'labelSizeId=${widget.labelSize?.labelSizeId} '
        'rtfLen=${widget.labelRtf?.length ?? 0} '
        'rtfHash=${widget.labelRtf?.hashCode ?? 0}',
      );
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    }
    _zoomController.dispose();
    _printLeftMarginController.dispose();
    _printTopMarginController.dispose();
    _printExtraAreaController.dispose();
    _printCopiesController.dispose();
    _objectPanelFocusScopeNode.dispose();
    _objectOverlayOpenButtonFocusNode.dispose();
    _zoomFocusNode.removeListener(_handleZoomFocusChanged);
    _zoomFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleControllerCommandStateChanged() {
    if (!mounted || _controllerRebuildScheduled) return;
    _controllerRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerRebuildScheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant LabelSheetWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    final outputCaptureOwnerChanged =
        oldWidget.outputCaptureController != widget.outputCaptureController ||
        oldWidget.outputCaptureOwnerToken != widget.outputCaptureOwnerToken;
    if (outputCaptureOwnerChanged) {
      widget.outputCaptureController?._validateAttach(
        this,
        widget.outputCaptureOwnerToken ?? this,
      );
    }
    if (oldWidget.imageImportController != widget.imageImportController) {
      oldWidget.imageImportController?._detach(this);
      widget.imageImportController?._attach(this);
    }
    if (oldWidget.editingLifecycleController !=
        widget.editingLifecycleController) {
      oldWidget.editingLifecycleController?._detach(this);
      widget.editingLifecycleController?._attach(this);
    }
    if (outputCaptureOwnerChanged) {
      oldWidget.outputCaptureController?._detach(this);
      widget.outputCaptureController?._attach(
        this,
        widget.outputCaptureOwnerToken ?? this,
      );
    }
    if (oldWidget.zoomController != widget.zoomController) {
      oldWidget.zoomController?.unbindZoomSetter(_setLabelSheetZoomPercent);
      _initializeZoomFromExternalController();
      widget.zoomController?.bindZoomSetter(_setLabelSheetZoomPercent);
      _controller.setZoomRatio(_zoomPercent / 100);
    }
    if (oldWidget.zoomToolbarPlacement != widget.zoomToolbarPlacement &&
        widget.zoomToolbarPlacement !=
            LabelSheetZoomToolbarPlacement.previewTabAreaEnd) {
      _removeZoomToolbarFloatingOverlay();
    }
    if (oldWidget.allowObjectPanel != widget.allowObjectPanel &&
        !widget.allowObjectPanel) {
      setState(() {
        _userWantsObjectDockOpen = false;
        _objectOverlayOpen = false;
        _objectOverlayTriggerFocus = null;
        _objectOverlayPreviousFocus = null;
        _objectPropertyFocusField = null;
        _objectPropertyFocusSheetId = null;
        _objectPropertyFocusObjectKey = null;
        _objectPropertyFocusGeneration += 1;
      });
    }
  }

  void _setLabelSheetZoomPercent(int percent) {
    final externalController = widget.zoomController;
    final clamped = percent.clamp(
      externalController?.minPercent ?? labelSheetMinZoomPercent,
      externalController?.maxPercent ?? labelSheetMaxZoomPercent,
    );
    if (externalController != null && externalController.value != clamped) {
      externalController.value = clamped;
    }
    if (_zoomController.text != '$clamped') {
      _zoomController.text = '$clamped';
      _zoomController.selection = TextSelection.collapsed(
        offset: _zoomController.text.length,
      );
    }
    if (_zoomPercent == clamped) {
      _syncExternalZoomController();
      return;
    }
    setState(() {
      _zoomPercent = clamped;
    });
    _controller.setZoomRatio(clamped / 100);
    _syncExternalZoomController();
  }

  void _syncLabelSheetZoomPercent(FortuneWorkbook workbook) {
    final externalController = widget.zoomController;
    if (externalController != null) {
      final percent = externalController.value.clamp(
        externalController.minPercent,
        externalController.maxPercent,
      );
      _zoomPercent = percent;
      if (_zoomController.text != '$percent') {
        _zoomController.text = '$percent';
        _zoomController.selection = TextSelection.collapsed(
          offset: _zoomController.text.length,
        );
      }
      return;
    }
    if (_zoomFocusNode.hasFocus) {
      return;
    }
    final percent = _labelSheetZoomPercentForWorkbook(workbook);
    if (_zoomPercent == percent && _zoomController.text == '$percent') {
      return;
    }
    _zoomPercent = percent;
    if (_zoomController.text != '$percent') {
      _zoomController.text = '$percent';
      _zoomController.selection = TextSelection.collapsed(
        offset: _zoomController.text.length,
      );
    }
    _syncExternalZoomController();
  }

  void _initializeZoomFromExternalController() {
    final externalController = widget.zoomController;
    if (externalController == null) return;
    final percent = externalController.value.clamp(
      externalController.minPercent,
      externalController.maxPercent,
    );
    _zoomPercent = percent;
    _zoomController.text = '$percent';
    _zoomController.selection = TextSelection.collapsed(
      offset: _zoomController.text.length,
    );
  }

  void _syncExternalZoomController() {
    final controller = widget.zoomController;
    if (controller == null || controller.value == _zoomPercent) return;
    controller.value = _zoomPercent;
  }

  int _labelSheetZoomPercentForWorkbook(FortuneWorkbook workbook) {
    final zoomRatio = workbook.activeSheet.zoomRatio <= 0
        ? 1.0
        : workbook.activeSheet.zoomRatio;
    return (zoomRatio * 100).round().clamp(
      labelSheetMinZoomPercent,
      labelSheetMaxZoomPercent,
    );
  }

  void _stepLabelSheetZoom(int deltaPercent) {
    final current = int.tryParse(_zoomController.text) ?? _zoomPercent;
    _setLabelSheetZoomPercent(current + deltaPercent);
  }

  void _commitLabelSheetZoomInput() {
    final value = int.tryParse(_zoomController.text);
    _zoomCommitPendingBlur = true;
    _setLabelSheetZoomPercent(value ?? labelSheetDefaultZoomPercent);
    _zoomFocusNode.unfocus();
  }

  void _handleZoomFocusChanged() {
    if (_zoomFocusNode.hasFocus) {
      _zoomEditOriginalPercent = _zoomPercent;
      _zoomCommitPendingBlur = false;
      return;
    }
    if (_zoomCommitPendingBlur) {
      _zoomCommitPendingBlur = false;
      _zoomEditOriginalPercent = null;
      return;
    }
    _restoreLabelSheetZoomInput();
  }

  KeyEventResult _handleZoomInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _restoreLabelSheetZoomInput();
    node.unfocus();
    return KeyEventResult.handled;
  }

  void _restoreLabelSheetZoomInput() {
    final restored = _zoomEditOriginalPercent ?? _zoomPercent;
    _zoomEditOriginalPercent = null;
    _zoomCommitPendingBlur = false;
    if (_zoomController.text == '$restored') {
      return;
    }
    _zoomController.text = '$restored';
    _zoomController.selection = TextSelection.collapsed(
      offset: _zoomController.text.length,
    );
  }

  void _syncRtfSnackBar(bool visible) {
    if (_rtfSnackBarVisible == visible) {
      return;
    }
    _rtfSnackBarVisible = visible;
    final generation = ++_rtfSnackBarGeneration;
    fortuneSheetDebugLog(
      'rtf snackbar sync visible=$visible generation=$generation '
      'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId} '
      'rtfLen=${widget.labelRtf?.length ?? 0} '
      'rtfHash=${widget.labelRtf?.hashCode ?? 0}',
    );
    // messenger 를 addPostFrameCallback 실행 전에 캡처한다.
    // 콜백 실행 시점에 위젯이 파기(dispose)되어 mounted=false 이더라도
    // hide(visible=false) 는 반드시 수행해야 스낵바가 무한 표시되지 않는다.
    final capturedMessenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _rtfSnackBarGeneration) {
        fortuneSheetDebugLog(
          'rtf snackbar postFrame stale visible=$visible '
          'generation=$generation current=$_rtfSnackBarGeneration '
          'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        return;
      }
      if (visible) {
        // SHOW: 위젯이 살아 있어야 context 로 showSnackBar 를 호출할 수 있다.
        if (!mounted) {
          fortuneSheetDebugLog(
            'rtf snackbar show skipped unmounted generation=$generation '
            'labelSizeId=${widget.labelSize?.labelSizeId}',
          );
          return;
        }
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) {
          fortuneSheetDebugLog(
            'rtf snackbar show skipped noMessenger generation=$generation '
            'labelSizeId=${widget.labelSize?.labelSizeId}',
          );
          return;
        }
        fortuneSheetDebugLog(
          'rtf snackbar show generation=$generation '
          'labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        messenger.clearSnackBars();
        showSnackBar(
          context,
          'RTF를 변환 중입니다...',
          type: SnackBarType.inProgress,
          duration: const Duration(days: 1),
        );
      } else {
        // HIDE: 위젯이 파기된 후에도 반드시 스낵바를 닫아야 한다.
        // mounted 체크 없이 캡처된 messenger 로 직접 닫는다.
        fortuneSheetDebugLog(
          'rtf snackbar hide generation=$generation '
          'hasMessenger=${capturedMessenger != null} '
          'mounted=$mounted labelSizeId=${widget.labelSize?.labelSizeId}',
        );
        capturedMessenger?.hideCurrentSnackBar();
      }
    });
  }

  void _markRtfImportDirtyIfNeeded(FortuneWorkbook workbook) {
    if (_rtfImportMarkedDirty || _isDirty) {
      return;
    }
    if (!labelSheetLooksLikeRichEditRtf(widget.labelRtf)) {
      return;
    }
    if (!_workbookHasRtfImportSource(workbook)) {
      return;
    }
    _rtfImportMarkedDirty = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDirty) {
        return;
      }
      setState(() {
        _isDirty = true;
      });
      widget.onDirtyChanged?.call(true);
    });
  }

  bool _workbookHasRtfImportSource(FortuneWorkbook workbook) {
    if (workbook.sheets.isEmpty) {
      return false;
    }
    final activeIndex = workbook.activeSheetIndex.clamp(
      0,
      workbook.sheets.length - 1,
    );
    return workbook.sheets[activeIndex].extraFields['labelRtfImportSource'] ==
        true;
  }

  bool _opsClearSheet(List<FortuneOp> ops) {
    return ops.any((op) => op['op'] == 'clearSheet');
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {
      _locale = FortuneSheetLocale.forLocale(
        locales?.isNotEmpty == true
            ? locales!.first
            : WidgetsBinding.instance.platformDispatcher.locale,
      );
    });
  }

  FortuneSheetLocale _localeForPlatform() {
    return FortuneSheetLocale.forLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  String _labelSheetImportImageTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '라벨 이미지 가져오기' : 'Import label image';
  }

  String _labelSheetPrintTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '인쇄' : 'Print';
  }

  String _labelSheetSaveTooltip() {
    final languageCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .languageCode
        .toLowerCase();
    return languageCode == 'ko' ? '저장' : 'Save';
  }

  Future<void> _handleImportLabelImage() async {
    await _openLabelImageImportWithInitialImage(null);
  }

  Future<void> _openLabelImageImportWithInitialImage(
    LabelSheetImageImportSelection? initialImage,
  ) async {
    final sheet = _controller.getSheet();
    if (sheet == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('활성 라벨 시트를 찾을 수 없습니다.')));
      }
      return;
    }
    final action = await _showLabelImageImportDialog(
      sheet: sheet,
      initialImage: initialImage,
    );
    if (!mounted || action == null) {
      return;
    }
    await _handleLabelImageImportAction(action);
  }

  Future<void> _handleLabelImageImportAction(
    LabelSheetImageImportAction action,
  ) async {
    final draft = action.draft;
    if (draft == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 분석할 수 없습니다.')));
      }
      return;
    }
    try {
      final xlsxFile = await labelSheetWriteImageImportXlsxFile(
        draft,
        action.fileName,
      );
      final xlsxName = p.basename(xlsxFile.path);
      final importedWorkbook = await _readImportedLabelWorkbook(
        XFile(
          xlsxFile.path,
          name: xlsxName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
      await _applyImportedLabelWorkbook(
        importedWorkbook,
        fileName: xlsxName,
        filePath: xlsxFile.path,
        updateImportDirectory: false,
        successMessage: 'AI 분석 결과를 엑셀로 가져왔습니다: $xlsxName',
      );
    } catch (e, stackTrace) {
      debugLog(
        'label image import xlsx auto import failed: '
        'name=${action.fileName} error=$e\n$stackTrace',
        skipFrames: 1,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI 분석 결과를 엑셀로 가져올 수 없습니다.')),
      );
    }
  }

  void _handlePrint() {
    if (!_controller.finalizeActiveObjectPropertyDraft()) return;
    unawaited(_openPrintSettingsDialog());
  }

  Future<void> _openPrintSettingsDialog() async {
    fortuneSheetDebugLog('label sheet print toolbar click');
    if (_printSettingsDialogOpen) {
      return;
    }
    await _notifyBeforeSheetDialog();
    if (!mounted) {
      return;
    }
    final preferredPrintSettings =
        await LabelPrinterPreferences.loadPreferredPrintSettings(
          listPrinters: widget.printerListProvider,
        );
    if (!mounted) {
      return;
    }
    _applyPrintSettingsPreference(preferredPrintSettings);
    setState(() {
      _printSettingsDialogOpen = true;
    });
    fortuneSheetDebugLog('label sheet print dialog route show');
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            _printSettingsDialogContext = dialogContext;
            _rebuildPrintSettingsDialog = () => setDialogState(() {});
            return _buildPrintSettingsDialog();
          },
        );
      },
    );
    _printSettingsDialogContext = null;
    _rebuildPrintSettingsDialog = null;
    if (mounted && _printSettingsDialogOpen) {
      setState(() {
        _printSettingsDialogOpen = false;
      });
      widget.onSheetDialogClosed?.call();
    }
  }

  void _applyPrintSettingsPreference(
    LabelSheetPreferredPrintSettings? settings,
  ) {
    _printLeftMarginController.text = settings?.leftMargin ?? '0.0';
    _printTopMarginController.text = settings?.topMargin ?? '0.0';
    _printExtraAreaController.text = settings?.extraArea ?? '0.0';
    _printCopiesController.text = '1';
    _printAutoSpacing = settings?.autoSpacing ?? 'none';
    _printOrientation = settings?.orientation ?? 'horizontal';
    _printSelectedPrinterName = settings?.printerName ?? '';
  }

  LabelSheetPreferredPrintSettings? _currentPrintSettingsPreference() {
    final printerName = _printSelectedPrinterName.trim();
    if (printerName.isEmpty) {
      return null;
    }
    return LabelSheetPreferredPrintSettings(
      printerName: printerName,
      leftMargin: _printLeftMarginController.text,
      topMargin: _printTopMarginController.text,
      autoSpacing: _printAutoSpacing,
      extraArea: _printExtraAreaController.text,
      orientation: _printOrientation,
    );
  }

  Future<void> _handleApplyPrintSettings() async {
    final settings = _currentPrintSettingsPreference();
    if (settings == null) {
      return;
    }
    await LabelPrinterPreferences.savePreferredPrintSettings(settings);
  }

  Future<void> _handleIssuePrintSettings() async {
    final printer = await _selectedPrintSettingsPrinter();
    if (!mounted) {
      return;
    }
    if (printer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('발행할 프린터를 선택하세요.')));
      return;
    }
    final sheet = _controller.getSheet();
    final physicalSize = sheet == null
        ? null
        : fortuneSheetGridClientPhysicalSize(sheet);
    if (sheet == null || physicalSize == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 출력 영역을 찾을 수 없습니다.')));
      return;
    }

    final options = _currentPrintOptions();
    final dpi = await _printDpiForPrinter(printer);
    final metrics = LabelSheetPrintPageMetrics(
      labelWidthMm: physicalSize.widthMm,
      labelHeightMm: physicalSize.heightMm,
      dpi: dpi,
    );
    final profile = detectPrinterProfile(printer);
    final rawPortName = Platform.isWindows
        ? await RawPrinterWin32.queryPrinterPortName(printer)
        : null;
    final filePort = RawPrinterWin32.isFilePortName(rawPortName);
    final backend = resolveLabelPrintBackend(
      language: profile.language,
      portName: rawPortName,
    );
    if (filePort && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일 포트 프린터는 일반 인쇄로 전환합니다.')));
    }
    if (!mounted) return;
    if (backend == LabelPrintBackend.ezplRaw) {
      final hybrid = await _captureHybridEzpl(
        metrics: metrics,
        options: options,
        lineSpacingPercent: options.autoSpacingPercent,
      );
      if (hybrid == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 생성할 수 없습니다.')));
        }
        return;
      }
      await RawPrinterWin32.sendRaw(printer, hybrid.bytes);
      return;
    }
    final capture = await _controller.captureRangeAsPng(
      _labelSheetPrintRange(sheet, physicalSize),
      pixelRatio: dpi / fortuneSheetLogicalPixelsPerInch,
      includeGridLines: false,
      includeCellBorders: true,
      includeRulerGuides: false,
      includeLabelAreaBoundary: false,
      outputLineHeightMultiplier: options.autoSpacingPercent == null
          ? null
          : options.autoSpacingPercent! / 100,
    );
    if (!mounted) {
      return;
    }
    if (capture == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 이미지를 생성할 수 없습니다.')));
      return;
    }

    final pdfBytes = await buildLabelSheetPdfBytes(
      pngBytes: capture.pngBytes,
      metrics: metrics,
      options: options,
    );
    if (!mounted) {
      return;
    }
    final accepted = await Printing.directPrintPdf(
      printer: printer,
      name: 'ITSnG_Label_${DateTime.now().millisecondsSinceEpoch}',
      onLayout: (_) async => pdfBytes,
    );
    if (!accepted) {
      throw StateError('프린터가 인쇄 요청을 접수하지 않았습니다.');
    }
  }

  Future<LabelSheetOutputCapture?> _captureOutput({
    required double dpi,
    required int? lineSpacingPercent,
  }) async {
    if (!_controller.finalizeActiveObjectPropertyDraft()) return null;
    final sheet = _controller.getSheet();
    final physicalSize = sheet == null
        ? null
        : fortuneSheetGridClientPhysicalSize(sheet);
    if (sheet == null || physicalSize == null) return null;
    final range = _labelSheetPrintRange(sheet, physicalSize);
    final capture = await _controller.captureRangeAsPng(
      range,
      pixelRatio: dpi / fortuneSheetLogicalPixelsPerInch,
      includeGridLines: false,
      includeCellBorders: true,
      includeRulerGuides: false,
      includeLabelAreaBoundary: false,
      outputLineHeightMultiplier: lineSpacingPercent == null
          ? null
          : lineSpacingPercent / 100,
    );
    if (capture == null) return null;
    return LabelSheetOutputCapture(
      pngBytes: capture.pngBytes,
      sheet: capture.sheet,
      range: capture.range,
      sourceWidthMm: fortuneLogicalPixelsToMillimeters(
        capture.logicalSize.width,
      ),
      sourceHeightMm: fortuneLogicalPixelsToMillimeters(
        capture.logicalSize.height,
      ),
    );
  }

  Future<LabelSheetHybridEzplCapture?> _captureHybridEzpl({
    required LabelSheetPrintPageMetrics metrics,
    required LabelSheetPrintOptions options,
    required int? lineSpacingPercent,
  }) async {
    if (!_controller.finalizeActiveObjectPropertyDraft()) return null;
    final sheet = _controller.getSheet();
    final settings = _controller.settingsSnapshot;
    final physicalSize = sheet == null
        ? null
        : fortuneSheetGridClientPhysicalSize(sheet);
    if (sheet == null || settings == null || physicalSize == null) return null;
    final requestedRange = _labelSheetPrintRange(sheet, physicalSize);
    final sheetMetrics = sheet.metrics(settings);
    final rowStart = math.min(requestedRange.rowStart, requestedRange.rowEnd);
    final rowEnd = math.max(requestedRange.rowStart, requestedRange.rowEnd);
    final columnStart = math.min(
      requestedRange.columnStart,
      requestedRange.columnEnd,
    );
    final columnEnd = math.max(
      requestedRange.columnStart,
      requestedRange.columnEnd,
    );
    final sourceBounds = ui.Rect.fromLTRB(
      sheetMetrics.columnStart(columnStart),
      sheetMetrics.rowStart(rowStart),
      sheetMetrics.columnEnd(columnEnd),
      sheetMetrics.rowEnd(rowEnd),
    );
    final resolvedMetrics = LabelSheetPrintPageMetrics(
      labelWidthMm: metrics.labelWidthMm,
      labelHeightMm: metrics.labelHeightMm,
      dpi: metrics.dpi,
      sourceWidthMm: fortuneLogicalPixelsToMillimeters(sourceBounds.width),
      sourceHeightMm: fortuneLogicalPixelsToMillimeters(sourceBounds.height),
    );
    final layout = LabelSheetPrintLayout.resolve(
      metrics: resolvedMetrics,
      options: options,
    );
    final transform = FortunePrintTransform(
      sourceLogicalBounds: sourceBounds,
      dpi: resolvedMetrics.dpi,
      contentLeftMm: layout.contentLeftMm,
      contentTopMm: layout.contentTopMm,
      clipRightMm: layout.clipRightMm,
      clipBottomMm: layout.clipBottomMm,
      nativeAllowed: !options.rotateQuarterTurns,
    );
    final candidates = fortuneBuildNativeCandidates(
      settings: settings,
      sheet: sheet,
      range: requestedRange,
      transform: transform,
    );
    final descriptors = preflightLabelSheetEzplCandidates(
      sheet: sheet,
      transform: transform,
      candidates: candidates,
    );
    final plan = fortuneFinalizeHybridRenderPlan(
      settings: settings,
      sheet: sheet,
      range: requestedRange,
      transform: transform,
      candidates: candidates,
      approvals: descriptors.map((descriptor) => descriptor.approval),
    );
    final capture = await _controller.captureHybridPlanAsPng(
      plan,
      pixelRatio: resolvedMetrics.dpi / fortuneSheetLogicalPixelsPerInch,
      includeCellBorders: true,
      outputLineHeightMultiplier: lineSpacingPercent == null
          ? null
          : lineSpacingPercent / 100,
    );
    if (capture == null) return null;
    final bytes = await buildLabelSheetPlannedHybridEzplBytes(
      filteredPngBytes: capture.pngBytes,
      metrics: resolvedMetrics,
      options: options,
      plan: plan,
      descriptors: descriptors,
    );
    return LabelSheetHybridEzplCapture(
      bytes: bytes,
      sheet: capture.sheet,
      range: capture.range,
      metrics: resolvedMetrics,
      plan: plan,
    );
  }

  Future<Printer?> _selectedPrintSettingsPrinter() async {
    final selectedName = _printSelectedPrinterName.trim();
    if (selectedName.isEmpty) {
      return null;
    }
    final printers =
        await (widget.printerListProvider ?? Printing.listPrinters)();
    final normalizedSelected = selectedName.toLowerCase();
    for (final printer in printers) {
      if (printer.name.trim().toLowerCase() == normalizedSelected) {
        return printer;
      }
    }
    return null;
  }

  Future<double> _printDpiForPrinter(Printer printer) async {
    if (Platform.isWindows) {
      final dpi = await RawPrinterWin32.queryPrinterDpi(printer);
      if (dpi != null && dpi > 0) {
        return dpi.toDouble();
      }
    }
    return detectPrinterProfile(printer).dpi ?? 203;
  }

  LabelSheetPrintOptions _currentPrintOptions() {
    return LabelSheetPrintOptions(
      copies: math.max(
        1,
        int.tryParse(_printCopiesController.text.trim()) ?? 1,
      ),
      leftMarginMm: _doubleFromPrintInput(_printLeftMarginController.text),
      topMarginMm: _doubleFromPrintInput(_printTopMarginController.text),
      extraAreaMm: _doubleFromPrintInput(_printExtraAreaController.text),
      autoSpacingPercent: _printAutoSpacing == 'none'
          ? null
          : int.tryParse(_printAutoSpacing),
      orientation: _printOrientation == 'vertical'
          ? LabelSheetPrintOrientation.vertical
          : LabelSheetPrintOrientation.horizontal,
    );
  }

  double _doubleFromPrintInput(String value) {
    return math.max(0, double.tryParse(value.trim()) ?? 0);
  }

  FortuneRange _labelSheetPrintRange(
    FortuneSheet sheet,
    FortuneSheetGridClientPhysicalSize physicalSize,
  ) {
    final logicalSize = physicalSize.logicalSize;
    return FortuneRange(
      rowStart: 0,
      rowEnd: _lastPrintIndexForExtent(
        logicalSize.height,
        lengthForIndex: (row) =>
            sheet.rowHeights[row] ?? sheet.defaultRowHeight ?? 19,
      ),
      columnStart: 0,
      columnEnd: _lastPrintIndexForExtent(
        logicalSize.width,
        lengthForIndex: (column) =>
            sheet.columnWidths[column] ?? sheet.defaultColWidth ?? 73,
      ),
    );
  }

  int _lastPrintIndexForExtent(
    double extent, {
    required double Function(int index) lengthForIndex,
  }) {
    if (extent <= 0) {
      return 0;
    }
    var offset = 0.0;
    var index = 0;
    while (offset < extent) {
      offset += lengthForIndex(index);
      if (offset >= extent) {
        return index;
      }
      index += 1;
    }
    return index;
  }

  void _closePrintSettingsDialog() {
    if (!_printSettingsDialogOpen) {
      return;
    }
    fortuneSheetDebugLog('label sheet print dialog close');
    setState(() {
      _printSettingsDialogOpen = false;
    });
    final dialogContext = _printSettingsDialogContext;
    if (dialogContext != null) {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    }
    widget.onSheetDialogClosed?.call();
  }

  Future<void> _notifyBeforeSheetDialog() async {
    _controller.clearHoverState();
    final callback = widget.onBeforeSheetDialog;
    if (callback != null) {
      await Future<void>.sync(callback);
    }
  }

  void _handleFortuneDialogVisibilityChanged(bool open) {
    if (open) {
      unawaited(_notifyBeforeSheetDialog());
      return;
    }
    widget.onSheetDialogClosed?.call();
  }

  Future<void> _handleSelectPrinter() async {
    final printerName = Platform.isWindows
        ? await RawPrinterWin32.showPrinterSetupDialog()
        : (await Printing.pickPrinter(context: context, title: '프린터 선택'))?.name;
    if (!mounted || printerName == null || printerName.isEmpty) {
      return;
    }
    setState(() {
      _printSelectedPrinterName = printerName;
    });
    _rebuildPrintSettingsDialog?.call();
  }

  Future<void> _handleSave() async {
    fortuneSheetDebugLog('label sheet save toolbar click');
    if (!_controller.finalizeActiveObjectPropertyDraft()) return;
    final callback = widget.onSave;
    if (callback == null) {
      return;
    }
    final payload = _encodedWorkbookForCurrentLabelFile();
    try {
      final result = await Future<LabelSheetSaveResult>.sync(
        () => callback(
          payload.widthMm,
          payload.heightMm,
          payload.encodedWorkbook,
        ),
      );
      if (result != LabelSheetSaveResult.applied) {
        return;
      }
    } catch (e) {
      fortuneSheetDebugLog('label sheet save failed: $e');
      return;
    }
    if (mounted) {
      setState(() {
        _isDirty = false;
      });
      widget.onDirtyChanged?.call(false);
    }
  }

  ({int widthMm, int heightMm, String encodedWorkbook})
  _encodedWorkbookForCurrentLabelFile() {
    final workbook = _currentWorkbookForLabelFile();
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(workbook.activeSheet) ??
        _gridClientSize ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    return (
      widthMm: physicalSize.widthMm,
      heightMm: physicalSize.heightMm,
      encodedWorkbook: labelSheetEncodeWorkbookSave(
        labelSheetWorkbookForPrintAreaSave(workbook),
      ),
    );
  }

  FortuneWorkbook _currentWorkbookForLabelFile() {
    final sheets = _controller.getAllSheets();
    return sheets == null
        ? _latestWorkbook
        : _latestWorkbook.copyWith(sheets: sheets);
  }

  Set<String> _labelFileContextMenuDisabledItems() {
    return _currentLabelFileHasContent()
        ? const <String>{}
        : const <String>{fortuneContextExportLabelFileCommand};
  }

  bool _currentLabelFileHasContent() {
    final workbook = labelSheetWorkbookForPrintAreaSave(
      _currentWorkbookForLabelFile(),
    );
    final sheet = workbook.activeSheet;
    return sheet.cells.isNotEmpty ||
        sheet.borderInfo.isNotEmpty ||
        sheet.images.isNotEmpty ||
        sheet.lines.isNotEmpty ||
        sheet.shapes.isNotEmpty ||
        sheet.dataVerification.isNotEmpty ||
        sheet.hyperlinks.isNotEmpty;
  }

  Future<void> _handleExportLabelFile() async {
    fortuneSheetDebugLog('label sheet export label file context click');
    if (!_controller.finalizeActiveObjectPropertyDraft()) return;
    if (!_currentLabelFileHasContent()) {
      return;
    }
    const labelFileGroup = XTypeGroup(
      label: 'Label Manager Sheet',
      extensions: <String>['lms'],
      mimeTypes: <String>['application/octet-stream'],
    );
    final prefs = await SharedPreferences.getInstance();
    final initialDirectory = prefs.getString(_labelFileDirectoryPrefsKey);
    final suggestedName = _suggestedLabelFileName();
    final location = await getSaveLocation(
      acceptedTypeGroups: const <XTypeGroup>[labelFileGroup],
      suggestedName: suggestedName,
      initialDirectory: initialDirectory?.isNotEmpty == true
          ? initialDirectory
          : null,
    );
    if (location == null) {
      return;
    }
    final path = _ensureLabelFileExtension(location.path);
    final payload = _encodedWorkbookForCurrentLabelFile();
    await File(path).writeAsString(payload.encodedWorkbook, flush: true);
    final directory = p.dirname(path);
    if (directory.isNotEmpty) {
      await prefs.setString(_labelFileDirectoryPrefsKey, directory);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('라벨 파일을 내보냈습니다: ${p.basename(path)}')),
    );
  }

  Future<void> _handleImportLabelFile() async {
    fortuneSheetDebugLog('label sheet import label file context click');
    if (!_controller.finalizeActiveObjectPropertyDraft()) return;
    debugLog('label sheet import picker open', skipFrames: 1);
    const labelFileGroup = XTypeGroup(
      label: 'Label Manager Sheet / Excel Workbook',
      extensions: <String>['lms', 'xlsx'],
      mimeTypes: <String>['application/octet-stream'],
    );
    final prefs = await SharedPreferences.getInstance();
    final initialDirectory = prefs.getString(_labelFileDirectoryPrefsKey);
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[labelFileGroup],
      initialDirectory: initialDirectory?.isNotEmpty == true
          ? initialDirectory
          : null,
    );
    if (file == null) {
      debugLog('label sheet import picker canceled', skipFrames: 1);
      return;
    }
    debugLog(
      'label sheet import file selected '
      'name=${file.name} path=${file.path} '
      'pathExt=${p.extension(file.path)} nameExt=${p.extension(file.name)}',
      skipFrames: 1,
    );
    await _importLabelFileFromXFile(file, prefs: prefs);
  }

  Future<void> _importLabelFileFromXFile(
    XFile file, {
    SharedPreferences? prefs,
    bool updateImportDirectory = true,
    String? successMessage,
  }) async {
    FortuneWorkbook importedWorkbook;
    try {
      importedWorkbook = await _readImportedLabelWorkbook(file);
    } catch (e, stackTrace) {
      debugLog(
        'label sheet import label file failed: '
        'name=${file.name} path=${file.path} error=$e\n$stackTrace',
        skipFrames: 1,
      );
      fortuneSheetDebugLog(
        'label sheet import label file failed: '
        'name=${file.name} path=${file.path} error=$e\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일을 읽을 수 없습니다.')));
      return;
    }
    if (importedWorkbook.sheets.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일에 시트가 없습니다.')));
      return;
    }
    await _applyImportedLabelWorkbook(
      importedWorkbook,
      fileName: file.name,
      filePath: file.path,
      prefs: prefs,
      updateImportDirectory: updateImportDirectory,
      successMessage: successMessage,
    );
  }

  Future<void> _applyImportedLabelWorkbook(
    FortuneWorkbook importedWorkbook, {
    required String fileName,
    required String filePath,
    SharedPreferences? prefs,
    bool updateImportDirectory = true,
    String? successMessage,
  }) async {
    if (!_controller.finalizeActiveObjectPropertyDraft()) return;
    if (importedWorkbook.sheets.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('라벨 파일에 시트가 없습니다.')));
      return;
    }
    if (updateImportDirectory && filePath.isNotEmpty) {
      final directory = p.dirname(filePath);
      if (directory.isNotEmpty) {
        final targetPrefs = prefs ?? await SharedPreferences.getInstance();
        await targetPrefs.setString(_labelFileDirectoryPrefsKey, directory);
      }
    }
    final importExtension =
        (p.extension(filePath).isNotEmpty
                ? p.extension(filePath)
                : p.extension(fileName))
            .toLowerCase();
    final scaleToPhysicalWidth = importExtension == '.xlsx';
    final currentSheet = _currentWorkbookForLabelFile().activeSheet;
    final rawImportedGridSize = fortuneSheetGridClientPhysicalSize(
      importedWorkbook.activeSheet,
    );
    final currentGridSize = fortuneSheetGridClientPhysicalSize(currentSheet);
    final sizedImportedSheet = _labelSheetWithPreservedGridClientSize(
      importedWorkbook.activeSheet.copyWith(
        id: currentSheet.id,
        name: currentSheet.name,
        order: currentSheet.order,
        zoomRatio: 1,
        rawZoomRatio: null,
        hasRawZoomRatio: false,
      ),
      currentSheet,
    );
    final importedSheet = scaleToPhysicalWidth
        ? _labelSheetScaledToPhysicalWidth(
            sizedImportedSheet,
            currentSheet: currentSheet,
          )
        : sizedImportedSheet;
    final importedGridSize = fortuneSheetGridClientPhysicalSize(importedSheet);
    debugLog(
      'label sheet import apply sheet '
      'rows=${importedSheet.rowCount} columns=${importedSheet.columnCount} '
      'cells=${importedSheet.cells.length} '
      'scaleToPhysicalWidth=$scaleToPhysicalWidth '
      'sourceGridWidthMm=${rawImportedGridSize?.widthMm} '
      'sourceGridHeightMm=${rawImportedGridSize?.heightMm} '
      'currentGridWidthMm=${currentGridSize?.widthMm} '
      'currentGridHeightMm=${currentGridSize?.heightMm} '
      'gridWidthMm=${importedGridSize?.widthMm} '
      'gridHeightMm=${importedGridSize?.heightMm}',
      skipFrames: 1,
    );
    _logImportedSheetApplySample(importedSheet);
    _controller.clearSheet(
      id: currentSheet.id,
      rowCount: importedSheet.rowCount,
      columnCount: importedSheet.columnCount,
    );
    _controller.updateSheet(<FortuneSheet>[importedSheet]);
    _setLabelSheetZoomPercent(100);
    _controller.unfocusSheet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.unfocusSheet();
    });
    if (!mounted) {
      return;
    }
    setState(() {
      _isDirty = true;
    });
    widget.onDirtyChanged?.call(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage ?? '라벨 파일을 가져왔습니다: $fileName')),
    );
  }

  Future<FortuneWorkbook> _readImportedLabelWorkbook(XFile file) async {
    final extension = _importedLabelFileExtension(file);
    debugLog(
      'label sheet import read start '
      'name=${file.name} path=${file.path} extension=$extension',
      skipFrames: 1,
    );
    if (extension == '.xlsx') {
      final bytes = await file.readAsBytes();
      debugLog(
        'label sheet import read xlsx by extension bytes=${bytes.length}',
        skipFrames: 1,
      );
      return labelSheetNormalizeWorkbookForCurrentSaveFormat(
        labelSheetWorkbookFromXlsxBytes(bytes),
      );
    }
    if (extension == '.lms') {
      debugLog('label sheet import read lms by extension', skipFrames: 1);
      return labelSheetDecodeWorkbookSaveBytes(await file.readAsBytes());
    }
    final bytes = await file.readAsBytes();
    debugLog(
      'label sheet import read unknown extension bytes=${bytes.length}',
      skipFrames: 1,
    );
    if (labelSheetLooksLikeXlsx(bytes)) {
      debugLog('label sheet import detected xlsx by bytes', skipFrames: 1);
      return labelSheetNormalizeWorkbookForCurrentSaveFormat(
        labelSheetWorkbookFromXlsxBytes(bytes),
      );
    }
    debugLog(
      'label sheet import fallback to lms decode by bytes',
      skipFrames: 1,
    );
    return labelSheetDecodeWorkbookSaveBytes(bytes);
  }

  String _importedLabelFileExtension(XFile file) {
    final pathExtension = p.extension(file.path).toLowerCase();
    if (pathExtension.isNotEmpty) {
      return pathExtension;
    }
    return p.extension(file.name).toLowerCase();
  }

  String _suggestedLabelFileName() {
    final name = widget.labelSize?.labelSizeName.trim();
    return _ensureLabelFileExtension(
      name?.isNotEmpty == true ? name! : 'label',
    );
  }

  String _ensureLabelFileExtension(String path) {
    return p.extension(path).toLowerCase() == '.lms'
        ? path
        : p.setExtension(path, '.lms');
  }

  Widget _buildZoomToolbarOverlay() {
    if (widget.zoomToolbarPlacement == LabelSheetZoomToolbarPlacement.hidden) {
      return const SizedBox.shrink();
    }
    final inPreviewTabArea =
        widget.zoomToolbarPlacement ==
        LabelSheetZoomToolbarPlacement.previewTabAreaEnd;
    if (inPreviewTabArea) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 6,
      right: 12,
      height: 29,
      child: _buildZoomToolbarControls(inPreviewTabArea: false),
    );
  }

  Widget _buildZoomToolbarControls({required bool inPreviewTabArea}) {
    return ColoredBox(
      color:
          widget.zoomToolbarBackgroundColor ??
          (inPreviewTabArea
              ? const Color(0xFFF7F8FA)
              : const Color(0xfffafafc)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LabelSheetZoomButton(
            child: widget.zoomToolbarUseIcons
                ? const Icon(Icons.remove, size: 16)
                : const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      color: Color(0xff5f6368),
                    ),
                  ),
            onPressed: () => _stepLabelSheetZoom(-10),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 42,
            height: 25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xffffffff),
                border: Border.all(color: const Color(0xffd4d4d4)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
                child: EditableText(
                  key: const ValueKey('label-sheet-zoom-input'),
                  controller: _zoomController,
                  focusNode: _zoomFocusNode,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: Color(0xff222222),
                  ),
                  cursorColor: const Color(0xff0188fb),
                  cursorOffset: Offset.zero,
                  backgroundCursorColor: const Color(0x330188fb),
                  maxLines: 1,
                  onSubmitted: (_) => _commitLabelSheetZoomInput(),
                  onEditingComplete: _commitLabelSheetZoomInput,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          widget.zoomToolbarUseIcons
              ? const Icon(Icons.percent, size: 13, color: Color(0xff222222))
              : const Text(
                  '%',
                  style: TextStyle(fontSize: 13, color: Color(0xff222222)),
                ),
          const SizedBox(width: 4),
          _LabelSheetZoomButton(
            child: widget.zoomToolbarUseIcons
                ? const Icon(Icons.add, size: 16)
                : const Text(
                    '+',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      color: Color(0xff5f6368),
                    ),
                  ),
            onPressed: () => _stepLabelSheetZoom(10),
          ),
        ],
      ),
    );
  }

  void _syncZoomToolbarFloatingOverlay() {
    final placement = widget.zoomToolbarPlacement;
    if (placement != LabelSheetZoomToolbarPlacement.previewTabAreaEnd) {
      _removeZoomToolbarFloatingOverlay();
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final entry = _zoomToolbarOverlayEntry;
    if (entry != null) {
      entry.markNeedsBuild();
      return;
    }
    _zoomToolbarOverlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _zoomToolbarLayerLink,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(-12, -34),
            showWhenUnlinked: false,
            child: SizedBox(
              key: const ValueKey('label-sheet-zoom-toolbar'),
              height: 29,
              child: _buildZoomToolbarControls(inPreviewTabArea: true),
            ),
          ),
        );
      },
    );
    overlay.insert(_zoomToolbarOverlayEntry!);
  }

  void _removeZoomToolbarFloatingOverlay() {
    _zoomToolbarOverlayEntry?.remove();
    _zoomToolbarOverlayEntry = null;
  }

  Future<LabelSheetImageImportAction?> _showLabelImageImportDialog({
    required FortuneSheet sheet,
    LabelSheetImageImportSelection? initialImage,
  }) async {
    final settings = await loadLabelSheetImageImportSettings(
      defaultModel: labelSheetDefaultGeminiModel,
    );
    final persistedImage =
        initialImage ??
        await loadLabelSheetImageImportSelection(settings.filePath);
    await _notifyBeforeSheetDialog();
    if (!mounted) {
      return null;
    }
    final physicalSize =
        fortuneSheetGridClientPhysicalSize(sheet) ??
        const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
    try {
      return await showLabelSheetImageImportDialog(
        context: context,
        sheet: sheet,
        physicalSize: physicalSize,
        initialImage: persistedImage,
        initialApiKey: settings.apiKey,
        initialModel: settings.model,
        initialPrompt: settings.prompt,
        useRootOverlay: widget.imageImportUseRootOverlay,
      );
    } finally {
      widget.onSheetDialogClosed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<FortuneWorkbook>(
          future: _initialWorkbook,
          initialData: _fallbackWorkbook,
          builder: (context, snapshot) {
            final workbook = _workbookWithExternalZoom(
              snapshot.data ?? _fallbackWorkbook,
            );
            final sheetSettings = _sheetSettings(workbook);
            if (!_isDirty) {
              _latestWorkbook = workbook.copyWith(settings: sheetSettings);
            }
            if (!_initialZoomSynced) {
              _syncLabelSheetZoomPercent(workbook);
              if (snapshot.connectionState == ConnectionState.done) {
                _initialZoomSynced = true;
              }
            }
            final convertingRtf =
                labelSheetLooksLikeRichEditRtf(widget.labelRtf) &&
                snapshot.connectionState != ConnectionState.done;
            _syncRtfSnackBar(convertingRtf);
            if (!convertingRtf &&
                snapshot.connectionState == ConnectionState.done) {
              _markRtfImportDirtyIfNeeded(workbook);
              if (!_initialWorkbookOpsSettled) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _initialWorkbookOpsSettled = true;
                  }
                });
              }
              _notifyInitialLoadComplete(
                rtfImported: _workbookHasRtfImportSource(workbook),
              );
            }
            _objectDockEligible = constraints.maxWidth >= 760;
            final maximumDockPanelWidth = math.min(
              420.0,
              constraints.maxWidth - 480 - 8,
            );
            final objectPanelPresentation = !widget.allowObjectPanel
              ? FortuneObjectPanelPresentation.hidden
              : _objectDockEligible
              ? _userWantsObjectDockOpen
                      ? FortuneObjectPanelPresentation.dock
                      : FortuneObjectPanelPresentation.hidden
                : _objectOverlayOpen
                ? FortuneObjectPanelPresentation.overlay
                : FortuneObjectPanelPresentation.hidden;
            _syncObjectPanelFocusHandoff(objectPanelPresentation);
            final sheet = FortuneSheetApp(
              key: _sheetAppKey,
              workbook: workbook,
              settings: sheetSettings,
              controller: _controller,
              onChange: (workbook) {
                _workbookBeforeLastChange = _latestWorkbook;
                _latestWorkbook = workbook;
                _syncLabelSheetZoomPercent(workbook);
                widget.onWorkbookChanged?.call(workbook);
              },
              onOp: (ops) {
                if (ops.isEmpty || !mounted) {
                  return;
                }
                if (!_initialWorkbookOpsSettled) {
                  return;
                }
                final previousWorkbook = _workbookBeforeLastChange;
                final shouldNotify =
                    previousWorkbook == null ||
                    widget.onUserWorkbookChangedShouldNotify?.call(
                          previousWorkbook,
                          _latestWorkbook,
                        ) !=
                        false;
                if (shouldNotify) {
                  widget.onUserWorkbookChanged?.call(_latestWorkbook);
                }
                _workbookBeforeLastChange = null;
                if (_opsClearSheet(ops)) {
                  if (_isDirty) {
                    setState(() {
                      _isDirty = false;
                    });
                    widget.onDirtyChanged?.call(false);
                  }
                  return;
                }
                if (_isDirty) {
                  return;
                }
                setState(() {
                  _isDirty = true;
                });
                widget.onDirtyChanged?.call(true);
              },
              onOpenObjectPanelRequest: _handleObjectPanelOpenRequest,
              onCloseObjectPanelRequest: _closeObjectPanel,
              objectPanelPresentation: objectPanelPresentation,
                toolbarRightInset:
                  widget.zoomToolbarPlacement ==
                    LabelSheetZoomToolbarPlacement.sheetToolbarEnd
                  ? _labelSheetZoomToolbarRightInset
                  : 0,
              locale: _locale,
              barcodeRenderer:
                  widget.barcodeRenderer ?? labelSheetBarcodeRenderer,
              barcodeFormats: labelSheetBarcodeFormats,
              imageObjectIds: widget.imageObjectIds,
              barcodeObjectIds: widget.barcodeObjectIds,
              imageObjectOptions: widget.imageObjectOptions,
              barcodeObjectOptions: widget.barcodeObjectOptions,
              imageObjectConnectionMode: FortuneObjectConnectionMode.structured,
              barcodeObjectConnectionMode:
                  FortuneObjectConnectionMode.structured,
              gridClientSize: _gridClientSize,
              showFormulaBar: false,
              showSheetTabs: false,
            );
            final dockPanelWidth = _objectPanelWidth
                .clamp(
                  _labelSheetObjectPanelMinWidth,
                  math.max(
                    _labelSheetObjectPanelMinWidth,
                    maximumDockPanelWidth,
                  ),
                )
                .toDouble();
            final dockObjectPanel =
                _objectDockEligible && _userWantsObjectDockOpen;
            final overlayObjectPanel =
                !_objectDockEligible && _objectOverlayOpen;
            final objectPanel = FocusScope(
              node: _objectPanelFocusScopeNode,
              child: FortuneObjectLayerPanel(
                controller: _controller,
                imageObjectOptions: widget.imageObjectOptions,
                barcodeObjectOptions: widget.barcodeObjectOptions,
                imageObjectIds: widget.imageObjectIds,
                barcodeObjectIds: widget.barcodeObjectIds,
                headerHeight: sheetSettings.toolbarHeight,
                actionToolbarHeight: sheetSettings.columnHeaderHeight * 2,
                onClose: _closeObjectPanel,
                presentation: objectPanelPresentation,
                layerFocusGeneration: _objectLayerFocusGeneration,
                propertyFocusField: _objectPropertyFocusField,
                propertyFocusSheetId: _objectPropertyFocusSheetId,
                propertyFocusObjectKey: _objectPropertyFocusObjectKey,
                propertyFocusGeneration: _objectPropertyFocusGeneration,
              ),
            );
            const overlayHorizontalInset = 8.0;
            final overlayPanelWidth = math.min(
              300.0,
              math.max(0.0, constraints.maxWidth - overlayHorizontalInset * 2),
            );
            final sheetViewportSize = Size(
              math.max(
                0,
                constraints.maxWidth -
                    (dockObjectPanel ? dockPanelWidth + 8 : 0),
              ),
              constraints.maxHeight,
            );
            _notifyGridRectChanged(sheetViewportSize, workbook, sheetSettings);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _syncZoomToolbarFloatingOverlay();
              }
            });
            final sheetSurface = CompositedTransformTarget(
              link: _zoomToolbarLayerLink,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  sheet,
                  _buildZoomToolbarOverlay(),
                  if (convertingRtf)
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        child: AbsorbPointer(
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                ],
              ),
            );
            if (dockObjectPanel) {
              return Row(
                children: [
                  Expanded(child: sheetSurface),
                  VerticalPaneSplitter(
                    width: 8,
                    onDragStart: () {
                      _controller.dismissObjectPanelPresentationTransients();
                      _objectPanelWidthChangedByUser = true;
                      _objectPanelWidth = dockPanelWidth;
                      _objectPanelDragStartWidth = dockPanelWidth;
                    },
                    onDrag: (delta) {
                      setState(() {
                        _objectPanelWidth = (_objectPanelWidth - delta).clamp(
                          _labelSheetObjectPanelMinWidth,
                          math.max(
                            _labelSheetObjectPanelMinWidth,
                            maximumDockPanelWidth,
                          ),
                        );
                      });
                    },
                    onDragEnd: () {
                      final startWidth = _objectPanelDragStartWidth;
                      _objectPanelDragStartWidth = null;
                      if (startWidth != null &&
                          startWidth != _objectPanelWidth) {
                        _queueObjectPanelWidthSave(_objectPanelWidth);
                      }
                    },
                    onDragCancel: () {
                      final startWidth = _objectPanelDragStartWidth;
                      _objectPanelDragStartWidth = null;
                      if (startWidth != null) {
                        setState(() {
                          _objectPanelWidth = startWidth;
                        });
                      }
                    },
                    onDoubleTap: () {
                      _objectPanelWidthChangedByUser = true;
                      setState(() {
                        _objectPanelWidth = _labelSheetObjectPanelInitialWidth
                            .clamp(
                          _labelSheetObjectPanelMinWidth,
                          math.max(
                            _labelSheetObjectPanelMinWidth,
                            maximumDockPanelWidth,
                          ),
                        );
                      });
                      _queueObjectPanelWidthSave(_objectPanelWidth);
                    },
                  ),
                  SizedBox(width: dockPanelWidth, child: objectPanel),
                ],
              );
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                sheetSurface,
                if (widget.showObjectPanelOpenButton &&
                    !_objectDockEligible &&
                    !overlayObjectPanel)
                  Positioned(
                    top: 48,
                    right: 8,
                    child: Material(
                      elevation: 2,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      child: IconButton(
                        focusNode: _objectOverlayOpenButtonFocusNode,
                        tooltip: '개체 패널 열기',
                        onPressed: _openObjectOverlayFromButton,
                        icon: const Icon(Icons.layers_outlined, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                if (overlayObjectPanel)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeObjectPanel,
                    child: const ColoredBox(color: Color(0x33000000)),
                  ),
                Positioned(
                  top: 0,
                  right: overlayHorizontalInset,
                  bottom: 0,
                  width: overlayPanelWidth,
                  child: Offstage(
                    offstage: !overlayObjectPanel,
                    child: objectPanel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPrintSettingsDialog() {
    return BlockingModelessDialog(
      child: BlockingModelessDialogFrame(
        title: '프린터 설정',
        width: 526,
        height: 236,
        closeIcon: const LabelPrintDialogCloseIcon(),
        onClose: _closePrintSettingsDialog,
        child: _ClosedLoopDialogFocus(
          child: LabelPrintSettingsPanel(
            leftMarginController: _printLeftMarginController,
            topMarginController: _printTopMarginController,
            extraAreaController: _printExtraAreaController,
            copiesController: _printCopiesController,
            autoSpacing: _printAutoSpacing,
            orientation: _printOrientation,
            selectedPrinterName: _printSelectedPrinterName,
            onAutoSpacingChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _printAutoSpacing = value;
              });
              _rebuildPrintSettingsDialog?.call();
            },
            onOrientationChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _printOrientation = value;
              });
              _rebuildPrintSettingsDialog?.call();
            },
            onSelectPrinter: _handleSelectPrinter,
            onIssue: () => unawaited(_handleIssuePrintSettings()),
            onApply: () => unawaited(_handleApplyPrintSettings()),
            onClose: _closePrintSettingsDialog,
          ),
        ),
      ),
    );
  }

  void _notifyInitialLoadComplete({required bool rtfImported}) {
    if (_initialLoadCompleteNotified) {
      return;
    }
    _initialLoadCompleteNotified = true;
    fortuneSheetDebugLog(
      'label sheet initial load complete '
      'labelSizeId=${widget.labelSize?.labelSizeId} '
      'hasRtf=${labelSheetLooksLikeRichEditRtf(widget.labelRtf)} '
      'rtfImported=$rtfImported',
    );
    final callback = widget.onInitialLoadComplete;
    if (callback == null) {
      return;
    }
    // messenger 를 캡처해 위젯 파기 후에도 스낵바를 닫을 수 있도록 한다.
    final capturedMessenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 스낵바 닫기는 mounted 무관하게 항상 수행한다.
      capturedMessenger?.hideCurrentSnackBar();
      if (!mounted) return;
      callback();
    });
  }
}

class _ClosedLoopDialogFocus extends StatelessWidget {
  const _ClosedLoopDialogFocus({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Builder(
        builder: (dialogFocusContext) {
          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
              SingleActivator(LogicalKeyboardKey.tab, shift: true):
                  PreviousFocusIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                NextFocusIntent: CallbackAction<NextFocusIntent>(
                  onInvoke: (intent) {
                    _moveFocusWithinDialog(dialogFocusContext, forward: true);
                    return null;
                  },
                ),
                PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                  onInvoke: (intent) {
                    _moveFocusWithinDialog(dialogFocusContext, forward: false);
                    return null;
                  },
                ),
              },
              child: FocusTraversalGroup(child: child),
            ),
          );
        },
      ),
    );
  }

  static void _moveFocusWithinDialog(
    BuildContext context, {
    required bool forward,
  }) {
    final scope = FocusScope.of(context);
    final nodes = scope.traversalDescendants
        .where((node) => node.canRequestFocus && !node.skipTraversal)
        .toList(growable: false);
    if (nodes.isEmpty) {
      return;
    }
    final current = FocusManager.instance.primaryFocus;
    var index = current == null ? -1 : nodes.indexOf(current);
    if (index < 0 && current != null) {
      index = nodes.indexWhere((node) => current.ancestors.contains(node));
    }
    final targetIndex = forward
        ? (index + 1) % nodes.length
        : (index <= 0 ? nodes.length - 1 : index - 1);
    nodes[targetIndex].requestFocus();
  }
}

class _LabelSheetZoomButton extends StatefulWidget {
  const _LabelSheetZoomButton({
    this.label,
    this.child,
    required this.onPressed,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback onPressed;

  @override
  State<_LabelSheetZoomButton> createState() => _LabelSheetZoomButtonState();
}

class _LabelSheetZoomButtonState extends State<_LabelSheetZoomButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _pressed
        ? const Color(0xffdfe5f2)
        : _hovered
        ? const Color(0xffedf2fb)
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(3),
          ),
          child: SizedBox(
            width: 23,
            height: 25,
            child: Center(
              child:
                  widget.child ??
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1,
                      color: Color(0xff5f6368),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

