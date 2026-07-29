import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('image import MIME type follows supported file extension', () {
    expect(labelSheetImageImportMimeTypeForName('label.JPG'), 'image/jpeg');
    expect(labelSheetImageImportMimeTypeForName('label.bmp'), 'image/bmp');
    expect(labelSheetImageImportMimeTypeForName('label.webp'), 'image/webp');
    expect(labelSheetImageImportMimeTypeForName('label.png'), 'image/png');
  });

  test('stored image selection loads valid files and ignores missing files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'label_manager_image_import_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}label.JPG');
    await file.writeAsBytes(<int>[1, 2, 3]);

    final selection = await loadLabelSheetImageImportSelection(
      '  ${file.path}  ',
    );

    expect(selection, isNotNull);
    expect(selection!.bytes, <int>[1, 2, 3]);
    expect(selection.mimeType, 'image/jpeg');
    expect(selection.fileName, 'label.JPG');
    expect(selection.filePath, file.path);
    expect(
      await loadLabelSheetImageImportSelection('${directory.path}/missing.png'),
      isNull,
    );
  });

  testWidgets('image import dialog renders initial values and closes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LabelSheetImageImportAction? closeResult;
    var closeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelSheetImageImportDialog(
            sheet: FortuneSheet(id: 'sheet1', name: 'Sheet 1'),
            physicalSize: const FortuneSheetGridClientPhysicalSize(
              widthMm: 100,
              heightMm: 60,
            ),
            initialImage: null,
            initialApiKey: '',
            initialModel: labelSheetDefaultGeminiModel,
            initialPrompt: 'prompt',
            close: (result) {
              closeCalled = true;
              closeResult = result;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('라벨 이미지 가져오기'), findsOneWidget);
    expect(find.textContaining('선택된 파일 없음'), findsOneWidget);
    expect(find.text('prompt'), findsOneWidget);

    await tester.tap(find.text('취소'));
    expect(closeCalled, isTrue);
    expect(closeResult, isNull);
  });
}
