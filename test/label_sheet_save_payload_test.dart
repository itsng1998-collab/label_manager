import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';

void main() {
  test('save payload uses workbook physical size before fallback', () {
    final workbook = FortuneWorkbook(
      sheets: <FortuneSheet>[
        FortuneSheet(
          id: 'sheet1',
          name: 'Label',
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 80,
            fortuneSheetGridClientHeightMmKey: 60,
          },
        ),
      ],
    );

    final payload = labelSheetBuildSavePayload(
      workbook,
      fallbackPhysicalSize: const FortuneSheetGridClientPhysicalSize(
        widthMm: 40,
        heightMm: 30,
      ),
    );

    expect(payload.widthMm, 80);
    expect(payload.heightMm, 60);
    expect(
      labelSheetDecodeWorkbookSave(payload.encodedWorkbook).activeSheet.name,
      'Label',
    );
  });

  test('save payload uses provided and default physical size fallbacks', () {
    final workbook = FortuneWorkbook(
      sheets: <FortuneSheet>[FortuneSheet(id: 'sheet1', name: 'Label')],
    );

    final provided = labelSheetBuildSavePayload(
      workbook,
      fallbackPhysicalSize: const FortuneSheetGridClientPhysicalSize(
        widthMm: 40,
        heightMm: 30,
      ),
    );
    final defaulted = labelSheetBuildSavePayload(workbook);

    expect((provided.widthMm, provided.heightMm), (40, 30));
    expect((defaulted.widthMm, defaulted.heightMm), (100, 100));
  });
}