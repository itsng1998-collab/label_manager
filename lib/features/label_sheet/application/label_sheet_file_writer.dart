import 'dart:io';

import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:path/path.dart' as p;

String labelSheetEnsureFileExtension(String path) {
  return p.extension(path).toLowerCase() == '.lms'
      ? path
      : p.setExtension(path, '.lms');
}

Future<String> labelSheetWriteWorkbookFile({
  required String path,
  required FortuneWorkbook workbook,
}) async {
  final outputPath = labelSheetEnsureFileExtension(path);
  final encodedWorkbook = labelSheetEncodeWorkbookSave(
    labelSheetWorkbookForPrintAreaSave(workbook),
  );
  await File(outputPath).writeAsString(encodedWorkbook, flush: true);
  return outputPath;
}