import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_file_writer.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';

void main() {
  test('writer normalizes extension and writes a decodable workbook', () async {
    final directory = await Directory.systemTemp.createTemp(
      'label_manager_file_writer_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final workbook = FortuneWorkbook(
      sheets: <FortuneSheet>[
        FortuneSheet(id: 'sheet1', name: 'Exported Sheet'),
      ],
    );

    final outputPath = await labelSheetWriteWorkbookFile(
      path: '${directory.path}${Platform.pathSeparator}label.txt',
      workbook: workbook,
    );

    expect(outputPath, endsWith('label.lms'));
    expect(File(outputPath).existsSync(), isTrue);
    expect(
      labelSheetDecodeWorkbookSave(await File(outputPath).readAsString())
          .activeSheet
          .name,
      'Exported Sheet',
    );
  });

  test('extension helper preserves an existing lms extension', () {
    expect(labelSheetEnsureFileExtension('label.LMS'), 'label.LMS');
    expect(labelSheetEnsureFileExtension('label.xlsx'), 'label.lms');
  });
}