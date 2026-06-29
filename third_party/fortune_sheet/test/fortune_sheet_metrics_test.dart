import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test('metrics match FortuneSheet cumulative row and column sizing', () {
    final sheet = FortuneSheet(
      id: 'sheet',
      name: 'Sheet1',
      rowHeights: {1: 29},
      columnWidths: {1: 99},
    );

    final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

    expect(metrics, isA<FortuneSheetMetrics>());
    expect(metrics.visibleDataRows, [20, 50, 70]);
    expect(metrics.visibleDataColumns, [74, 174, 248]);
    expect(metrics.rowTotalHeight, 150);
    expect(metrics.columnTotalWidth, 368);
  });

  test('metrics keep hidden row and column indexes at previous edge', () {
    final sheet = FortuneSheet(
      id: 'sheet',
      name: 'Sheet1',
      hiddenRows: {1},
      hiddenColumns: {1},
    );

    final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

    expect(metrics.visibleDataRows, [20, 20, 40]);
    expect(metrics.visibleDataColumns, [74, 74, 148]);
  });

  test('metrics apply zoom rounding while hidden axes keep previous edge', () {
    final sheet = FortuneSheet(
      id: 'sheet',
      name: 'Sheet1',
      zoomRatio: 1.5,
      rowHeights: {2: 24},
      columnWidths: {2: 80},
      hiddenRows: {1},
      hiddenColumns: {1},
    );

    final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

    expect(metrics.visibleDataRows, [30, 30, 68]);
    expect(metrics.visibleDataColumns, [111, 111, 233]);
    expect(metrics.rowTotalHeight, 148);
    expect(metrics.columnTotalWidth, 353);
  });

  test('axis lookup returns matching cell bounds', () {
    final sheet = FortuneSheet(id: 'sheet', name: 'Sheet1');
    final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

    final row = metrics.rowAt(21);
    final column = metrics.columnAt(75);
    final firstRow = metrics.rowAt(-10);
    final lastColumn = metrics.columnAt(999);

    expect(row, isA<FortuneAxisCell>());
    expect(column, isA<FortuneAxisCell>());
    expect(row.index, 1);
    expect(row.start, 20);
    expect(row.end, 40);
    expect(column.index, 1);
    expect(column.start, 74);
    expect(column.end, 148);
    expect(firstRow.index, 0);
    expect(firstRow.start, 0);
    expect(firstRow.end, 20);
    expect(lastColumn.index, 2);
    expect(lastColumn.start, 148);
    expect(lastColumn.end, 222);
  });

  test('empty visible axis ranges report no available cells', () {
    const rows = <double>[];

    final range = FortuneAxisRange.fromVisibleData(rows, 0, 100);

    expect(range.start, 0);
    expect(range.end, -1);
  });

  test('visible axis ranges clamp to available metrics', () {
    final sheet = FortuneSheet(id: 'sheet', name: 'Sheet1');
    final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

    final rows = metrics.visibleRows(21, 200);
    final columns = metrics.visibleColumns(75, 300);

    expect(rows.start, 1);
    expect(rows.end, 2);
    expect(columns.start, 1);
    expect(columns.end, 2);
    expect(metrics.rowStart(0), 0);
    expect(metrics.rowStart(2), 40);
    expect(metrics.rowEnd(2), 60);
    expect(metrics.columnStart(0), 0);
    expect(metrics.columnStart(2), 148);
    expect(metrics.columnEnd(2), 222);
  });

  test(
    'sheet-local row count, column count and default sizes affect metrics',
    () {
      final sheet = FortuneSheet(
        id: 'sheet',
        name: 'Sheet1',
        rowCount: 2,
        columnCount: 2,
        defaultRowHeight: 24,
        defaultColWidth: 80,
      );

      final metrics = sheet.metrics(const FortuneSettings(row: 3, column: 3));

      expect(metrics.visibleDataRows, [25, 50]);
      expect(metrics.visibleDataColumns, [81, 162]);
      expect(metrics.rowTotalHeight, 130);
      expect(metrics.columnTotalWidth, 282);
    },
  );
}
