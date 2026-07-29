import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_barcode_renderer.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_model.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_rtf_import.dart';

bool labelSheetWriteRtfOpenXmlTestFileEnabled = false;
const int labelSheetDefaultPhysicalWidthMm = 100;
const int labelSheetDefaultPhysicalHeightMm = 100;

int labelSheetPositivePhysicalSizeOrDefault(int? value, int fallback) {
  return value != null && value > 0 ? value : fallback;
}

FortuneWorkbook labelSheetWorkbook(
  FortuneWorkbook base, {
  LabelSize? labelSize,
  String? labelRtf,
}) {
  if (base.sheets.isEmpty) {
    return base;
  }
  final common = labelSize?.labelSizeCommon;
  final widthMm = labelSheetPositivePhysicalSizeOrDefault(
    common?.width,
    labelSheetDefaultPhysicalWidthMm,
  );
  final heightMm = labelSheetPositivePhysicalSizeOrDefault(
    common?.height,
    labelSheetDefaultPhysicalHeightMm,
  );
  final activeIndex = base.activeSheetIndex.clamp(0, base.sheets.length - 1);
  final sheets = [
    for (var index = 0; index < base.sheets.length; index += 1)
      index == activeIndex
          ? _labelSheetSizedSheet(
              base.sheets[index],
              labelSize: labelSize,
              widthMm: widthMm,
              heightMm: heightMm,
              labelRtf: labelRtf,
            )
          : base.sheets[index].copyWith(),
  ];
  return base.copyWith(sheets: sheets);
}

Future<FortuneWorkbook> labelSheetWorkbookWithRtf(
  FortuneWorkbook base, {
  LabelSize? labelSize,
  String? labelRtf,
}) async {
  final sized = labelSheetWorkbook(
    base,
    labelSize: labelSize,
    labelRtf: labelRtf,
  );
  if (sized.sheets.isEmpty || !labelSheetLooksLikeRichEditRtf(labelRtf)) {
    return sized;
  }
  final activeIndex = sized.activeSheetIndex.clamp(0, sized.sheets.length - 1);
  final activeSheet = sized.sheets[activeIndex];
  final draft = await labelSheetDraftFromRichEditRtfAsync(
    labelRtf!,
    sheet: activeSheet,
    barcodeRenderer: labelSheetBarcodeRenderer,
  );
  if (draft == null) {
    return sized;
  }
  if (labelSheetWriteRtfOpenXmlTestFileEnabled) {
    try {
      final file = await labelSheetWriteRichEditRtfOpenXmlTestFile(
        labelRtf,
        sheet: activeSheet,
        barcodeRenderer: labelSheetBarcodeRenderer,
      );
      if (file == null) {
        fortuneSheetDebugLog('label RTF Open XML test file skipped');
      } else {
        fortuneSheetDebugLog(
          'label RTF Open XML test file written: ${file.path}',
        );
      }
    } catch (error, stackTrace) {
      fortuneSheetDebugLog(
        'label RTF Open XML test file failed: $error\n$stackTrace',
      );
    }
  }
  final importedSheet = labelSheetApplyImageImportDraft(
    activeSheet,
    draft,
    minRowCount: sized.settings.row,
    minColumnCount: sized.settings.column,
  );
  final importedExtraFields = {
    ...importedSheet.extraFields,
    'labelRtfImportSource': true,
  };
  final sheets = [
    for (var index = 0; index < sized.sheets.length; index += 1)
      index == activeIndex
          ? importedSheet.copyWith(extraFields: importedExtraFields)
          : sized.sheets[index].copyWith(),
  ];
  return sized.copyWith(sheets: sheets);
}

FortuneSheet _labelSheetSizedSheet(
  FortuneSheet sheet, {
  required LabelSize? labelSize,
  required int widthMm,
  required int heightMm,
  required String? labelRtf,
}) {
  final extraFields = {
    ...sheet.extraFields,
    fortuneSheetGridClientWidthMmKey: widthMm,
    fortuneSheetGridClientHeightMmKey: heightMm,
  };
  if (labelSheetLooksLikeRichEditRtf(labelRtf)) {
    extraFields.remove('labelRtfImportSource');
  }
  return sheet.copyWith(
    name: labelSize?.labelSizeName ?? sheet.name,
    extraFields: extraFields,
  );
}