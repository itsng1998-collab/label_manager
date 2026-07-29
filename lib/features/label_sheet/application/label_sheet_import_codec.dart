import 'dart:typed_data';

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_xlsx_import.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:path/path.dart' as p;

enum LabelSheetImportFormat { lms, xlsx, unknown }

LabelSheetImportFormat labelSheetResolveImportFormat({
  required String filePath,
  required String fileName,
}) {
  final pathExtension = p.extension(filePath).toLowerCase();
  final extension = pathExtension.isNotEmpty
      ? pathExtension
      : p.extension(fileName).toLowerCase();
  return switch (extension) {
    '.lms' => LabelSheetImportFormat.lms,
    '.xlsx' => LabelSheetImportFormat.xlsx,
    _ => LabelSheetImportFormat.unknown,
  };
}

FortuneWorkbook labelSheetDecodeImportedWorkbook({
  required Uint8List bytes,
  required String filePath,
  required String fileName,
}) {
  final format = labelSheetResolveImportFormat(
    filePath: filePath,
    fileName: fileName,
  );
  debugLog(
    'label sheet import decode '
    'name=$fileName path=$filePath format=${format.name} bytes=${bytes.length}',
    skipFrames: 1,
  );
  if (format == LabelSheetImportFormat.xlsx ||
      (format == LabelSheetImportFormat.unknown &&
          labelSheetLooksLikeXlsx(bytes))) {
    return labelSheetNormalizeWorkbookForCurrentSaveFormat(
      labelSheetWorkbookFromXlsxBytes(bytes),
    );
  }
  return labelSheetDecodeWorkbookSaveBytes(bytes);
}