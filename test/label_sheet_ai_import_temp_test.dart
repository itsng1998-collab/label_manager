import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import_temp.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_model.dart';
import 'package:path/path.dart' as p;

void main() {
  const draft = LabelSheetImageImportDraft(
    imageWidth: 100,
    imageHeight: 60,
    rowLines: <int>[0, 60],
    columnLines: <int>[0, 100],
    rowHeights: <int, double>{0: 60},
    columnWidths: <int, double>{0: 100},
    images: [],
  );

  test('image import xlsx writer normalizes source file names', () async {
    final directory = await Directory.systemTemp.createTemp(
      'label_manager_ai_import_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final file = await labelSheetWriteImageImportXlsxFile(
      draft,
      '  라벨 name (최종).png  ',
      directory: directory,
      uniqueId: 123,
    );

    expect(
      p.basename(file.path),
      'label_manager_ai_import_123_라벨_name_최종_.xlsx',
    );
    expect(await file.length(), greaterThan(0));
  });

  test('image import xlsx writer uses fallback for empty base name', () async {
    final directory = await Directory.systemTemp.createTemp(
      'label_manager_ai_import_',
    );
    addTearDown(() => directory.delete(recursive: true));

    final file = await labelSheetWriteImageImportXlsxFile(
      draft,
      '   ',
      directory: directory,
      uniqueId: 456,
    );

    expect(
      p.basename(file.path),
      'label_manager_ai_import_456_label_image.xlsx',
    );
  });
}