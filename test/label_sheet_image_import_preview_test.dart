import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_preview.dart';

const _physicalSize = FortuneSheetGridClientPhysicalSize(
  widthMm: 100,
  heightMm: 50,
);

Widget _preview(Uint8List? imageBytes) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 640,
          child: LabelSheetImageImportPreview(
            imageBytes: imageBytes,
            physicalSize: _physicalSize,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('image import preview shows empty selection message', (
    tester,
  ) async {
    await tester.pumpWidget(_preview(null));

    expect(find.text('이미지 파일을 선택하세요.'), findsOneWidget);
    expect(find.byType(widgets.Image), findsNothing);
  });

  testWidgets('image import preview renders selected image bytes', (
    tester,
  ) async {
    final imageBytes = Uint8List.fromList(
      imglib.encodePng(imglib.Image(width: 200, height: 100)),
    );

    await tester.pumpWidget(_preview(imageBytes));

    expect(find.text('이미지 파일을 선택하세요.'), findsNothing);
    expect(find.byType(widgets.Image), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNWidgets(2));
  });
}
