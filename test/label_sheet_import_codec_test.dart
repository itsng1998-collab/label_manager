import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import_temp.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_codec.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_model.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';

void main() {
  test('import codec decodes lms by extension and unknown bytes', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        labelSheetEncodeWorkbookSave(
          FortuneWorkbook(
            sheets: <FortuneSheet>[
              FortuneSheet(id: 'lms', name: 'LMS Sheet'),
            ],
          ),
        ),
      ),
    );

    expect(
      labelSheetDecodeImportedWorkbook(
        bytes: bytes,
        filePath: 'label.lms',
        fileName: 'ignored.xlsx',
      ).activeSheet.name,
      'LMS Sheet',
    );
    expect(
      labelSheetDecodeImportedWorkbook(
        bytes: bytes,
        filePath: '',
        fileName: 'label.bin',
      ).activeSheet.name,
      'LMS Sheet',
    );
  });

  test('import codec decodes xlsx by extension and unknown bytes', () async {
    const draft = LabelSheetImageImportDraft(
      imageWidth: 100,
      imageHeight: 60,
      rowLines: <int>[0, 60],
      columnLines: <int>[0, 100],
      rowHeights: <int, double>{0: 60},
      columnWidths: <int, double>{0: 100},
      images: [],
    );
    final directory = await Directory.systemTemp.createTemp(
      'label_manager_import_codec_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = await labelSheetWriteImageImportXlsxFile(
      draft,
      'label.png',
      directory: directory,
      uniqueId: 1,
    );
    final bytes = await file.readAsBytes();

    expect(
      labelSheetDecodeImportedWorkbook(
        bytes: bytes,
        filePath: 'label.xlsx',
        fileName: 'ignored.lms',
      ).activeSheet.name,
      'RTF Test',
    );
    expect(
      labelSheetDecodeImportedWorkbook(
        bytes: bytes,
        filePath: '',
        fileName: 'label.bin',
      ).activeSheet.name,
      'RTF Test',
    );
  });
}