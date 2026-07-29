import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_layout.dart';

void main() {
  test('import layout preserves current physical size when source has none', () {
    final imported = FortuneSheet(
      id: 'imported',
      name: 'Imported',
      extraFields: const <String, Object?>{'source': true},
    );
    final current = FortuneSheet(
      id: 'current',
      name: 'Current',
      extraFields: const <String, Object?>{
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final result = labelSheetImportWithPreservedGridClientSize(
      imported,
      current,
    );

    expect(result.extraFields['source'], isTrue);
    expect(result.extraFields[fortuneSheetGridClientWidthMmKey], 100);
    expect(result.extraFields[fortuneSheetGridClientHeightMmKey], 60);
  });

  test('import layout scales text and axes for minimum readability', () {
    final sheet = FortuneSheet(
      id: 'imported',
      name: 'Imported',
      rowCount: 1,
      columnCount: 1,
      rowHeights: const <int, double>{0: 100},
      columnWidths: const <int, double>{0: 1000},
      cells: <FortuneCellCoord, FortuneCell>{
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: 'Label',
          fontSize: 20,
          extraFields: <String, Object?>{'letterSpacing': 2},
          inlineRuns: <FortuneInlineTextRun>[
            FortuneInlineTextRun(
              text: 'small',
              fontSize: 10,
              extraFields: <String, Object?>{'letterSpacing': 1},
            ),
          ],
        ),
      },
      extraFields: const <String, Object?>{
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final result = labelSheetScaleImportedToPhysicalWidth(
      sheet,
      currentSheet: sheet,
    );
    final readableFontSize = fortuneMillimetersToLogicalPixels(
      labelSheetImportMinReadableFontHeightMm,
    );
    final scale = readableFontSize / 10;
    final cell = result.cells[const FortuneCellCoord(0, 0)]!;

    expect(result.columnWidths[0], closeTo(1000 * scale, 0.001));
    expect(result.rowHeights[0], closeTo(100 * scale, 0.001));
    expect(cell.fontSize, closeTo(20 * scale, 0.001));
    expect(cell.extraFields['letterSpacing'], closeTo(2 * scale, 0.001));
    expect(cell.inlineRuns!.single.fontSize, closeTo(readableFontSize, 0.001));
    expect(
      cell.inlineRuns!.single.extraFields['letterSpacing'],
      closeTo(scale, 0.001),
    );
    expect(
      labelSheetAxisLogicalTotalSizeForCount(
        result.columnWidths,
        result.columnCount,
        result.defaultColWidth,
      ),
      greaterThan(fortuneMillimetersToLogicalPixels(100)),
    );
  });
}
