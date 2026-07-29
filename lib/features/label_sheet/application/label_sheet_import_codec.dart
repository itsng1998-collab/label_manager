import 'dart:typed_data';

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_xlsx_import.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:path/path.dart' as p;

FortuneWorkbook labelSheetDecodeImportedWorkbook({
  required Uint8List bytes,
  required String filePath,
  required String fileName,
}) {
  final pathExtension = p.extension(filePath).toLowerCase();
  final extension = pathExtension.isNotEmpty
      ? pathExtension
      : p.extension(fileName).toLowerCase();
  debugLog(
    'label sheet import decode '
    'name=$fileName path=$filePath extension=$extension bytes=${bytes.length}',
    skipFrames: 1,
  );
  if (extension == '.xlsx' ||
      (extension != '.lms' && labelSheetLooksLikeXlsx(bytes))) {
    return labelSheetNormalizeWorkbookForCurrentSaveFormat(
      labelSheetWorkbookFromXlsxBytes(bytes),
    );
  }
  return labelSheetDecodeWorkbookSaveBytes(bytes);
}