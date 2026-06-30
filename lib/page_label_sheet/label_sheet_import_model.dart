import 'package:fortune_sheet/fortune_sheet.dart';

class LabelSheetImageImportDraft {
  const LabelSheetImageImportDraft({
    required this.imageWidth,
    required this.imageHeight,
    required this.rowLines,
    required this.columnLines,
    required this.rowHeights,
    required this.columnWidths,
    required this.images,
    this.cells = const <FortuneCellCoord, FortuneCell>{},
    this.borderInfo = const <FortuneBorderInfo>[],
  });

  final int imageWidth;
  final int imageHeight;
  final List<int> rowLines;
  final List<int> columnLines;
  final Map<int, double> rowHeights;
  final Map<int, double> columnWidths;
  final Map<FortuneCellCoord, FortuneCell> cells;
  final List<FortuneImage> images;
  final List<FortuneBorderInfo> borderInfo;

  FortuneImage? get image => images.isEmpty ? null : images.first;
}

FortuneSheet labelSheetApplyImageImportDraft(
  FortuneSheet sheet,
  LabelSheetImageImportDraft draft, {
  int? minRowCount,
  int? minColumnCount,
}) {
  final rowCount = [
    draft.rowHeights.length,
    if (sheet.rowCount != null) sheet.rowCount!,
    if (minRowCount != null) minRowCount,
  ].reduce((value, element) => value > element ? value : element);
  final columnCount = [
    draft.columnWidths.length,
    if (sheet.columnCount != null) sheet.columnCount!,
    if (minColumnCount != null) minColumnCount,
  ].reduce((value, element) => value > element ? value : element);
  return sheet.copyWith(
    rowCount: rowCount,
    columnCount: columnCount,
    cells: draft.cells,
    nullCells: const <FortuneCellCoord>{},
    rowHeights: {...sheet.rowHeights, ...draft.rowHeights},
    columnWidths: {...sheet.columnWidths, ...draft.columnWidths},
    borderInfo: draft.borderInfo,
    customHeight: {for (final row in draft.rowHeights.keys) row: 1},
    customWidth: {for (final column in draft.columnWidths.keys) column: 1},
    images: draft.images,
    showGridLines: true,
  );
}

FortuneSheet labelSheetClearBeforeImageImport(
  FortuneSheet sheet, {
  int? rowCount,
  int? columnCount,
}) {
  final extraFields = <String, Object?>{
    for (final entry in sheet.extraFields.entries) entry.key: entry.value,
  };
  extraFields.remove('labelRtfImportSource');
  return sheet.copyWith(
    rowCount: rowCount ?? sheet.rowCount,
    columnCount: columnCount ?? sheet.columnCount,
    cells: const <FortuneCellCoord, FortuneCell>{},
    nullCells: const <FortuneCellCoord>{},
    rowHeights: const <int, double>{},
    columnWidths: const <int, double>{},
    customHeight: const <int, double>{},
    customWidth: const <int, double>{},
    borderInfo: const <FortuneBorderInfo>[],
    images: const <FortuneImage>[],
    dataVerification: const <String, Object?>{},
    filter: const <String, Object?>{},
    hyperlinks: const <String, Object?>{},
    conditionFormats: const <Object?>[],
    alternateFormats: const <Object?>[],
    extraFields: extraFields,
  );
}
