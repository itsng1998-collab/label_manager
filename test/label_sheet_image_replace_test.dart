import 'dart:async';
import 'dart:convert';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as image;
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _original = FortuneImage(
  id: 'image_1',
  src: 'data:image/png;base64,'
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
  left: 20,
  top: 30,
  width: 80,
  height: 40,
  extraFields: {
    'rotation': 90,
    'crop': {'width': 80.0, 'height': 40.0, 'offsetLeft': 0.1, 'offsetTop': 0.0},
    'customMetadata': 'preserved',
  },
);
const _key = FortuneSheetObjectKey(FortuneSheetObjectKind.image, 'image_1');
final _replaceButton = find.byKey(
  const ValueKey('fortune-object-property-replace-file'),
);

class _ImageFileSelector extends FileSelectorPlatform {
  Future<XFile?> Function() pick = () async => null;
  int calls = 0;
  List<XTypeGroup>? groups;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    calls++;
    groups = acceptedTypeGroups;
    return pick();
  }
}

Future<FortuneSheetController> _pumpWorkbench(
  WidgetTester tester, {
  FutureOr<LabelSheetSaveResult> Function(int, int, String)? onSave,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: LabelSheetWorkbench(
        initialWorkbook: FortuneWorkbook(sheets: [
          FortuneSheet(id: 's1', name: 'Label', images: const [_original]),
        ]),
        onSave: onSave,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  final app = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
  expect(app.imagePicker, isNull);
  await tester.tap(find.text('이미지 1'));
  await tester.pumpAndSettle();
  expect(app.controller!.objectSelection.activeKey, _key);
  await tester.drag(find.byType(ListView).last, const Offset(0, -600));
  await tester.pumpAndSettle();
  await tester.ensureVisible(_replaceButton);
  await tester.pump();
  return app.controller!;
}

void main() {
  late _ImageFileSelector selector;
  setUp(() {
    final original = FileSelectorPlatform.instance;
    selector = _ImageFileSelector();
    FileSelectorPlatform.instance = selector;
    addTearDown(() => FileSelectorPlatform.instance = original);
  });

  testWidgets('unlinked image property opens default picker and saves replacement', (
    tester,
  ) async {
    String? savedPayload;
    final controller = await _pumpWorkbench(
      tester,
      onSave: (_, _, payload) {
        savedPayload = payload;
        return LabelSheetSaveResult.applied;
      },
    );
    final pending = Completer<XFile?>();
    selector.pick = () => pending.future;
    await tester.tap(_replaceButton);
    await tester.pump();
    expect(selector.calls, 1);
    expect(selector.groups!.single.extensions, containsAll(['png', 'jpg', 'bmp']));
    expect(tester.widget<OutlinedButton>(_replaceButton).onPressed, isNull);
    expect(controller.objectSelection.activeImage!.src, _original.src);

    final bytes = image.encodePng(image.Image(width: 2, height: 3));
    final expectedSrc = 'data:image/png;base64,${base64Encode(bytes)}';
    await tester.runAsync(() async {
      pending.complete(XFile.fromData(bytes, name: 'replacement.png'));
      final deadline = Stopwatch()..start();
      while (controller.objectSelection.activeImage!.src != expectedSrc) {
        if (deadline.elapsed > const Duration(seconds: 5)) {
          fail('The default file picker did not replace the selected image.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    final replaced = controller.objectSelection.activeImage!;
    expect(replaced.src, expectedSrc);
    expect((replaced.left, replaced.top, replaced.width, replaced.height), (20, 30, 80, 40));
    expect(replaced.extraFields['rotation'], 90);
    expect(replaced.extraFields['crop'], _original.extraFields['crop']);
    expect(replaced.extraFields['customMetadata'], 'preserved');
    expect(replaced.extraFields[fortuneImageObjectIdExtraKey], isNull);
    expect((replaced.extraFields['originWidth'], replaced.extraFields['originHeight']), (2, 3));
    expect(controller.projectedCanUndo, isTrue);
    controller.handleUndo();
    controller.selectObject(_key);
    await tester.pumpAndSettle();
    expect(controller.objectSelection.activeImage!.src, _original.src);
    controller.handleRedo();
    controller.selectObject(_key);
    await tester.pumpAndSettle();
    expect(controller.objectSelection.activeImage!.src, expectedSrc);

    final app = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    final save = app.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(save.disabled, isFalse);
    save.onClick!(save);
    await tester.pumpAndSettle();
    expect(savedPayload, isNotNull);
    final saved = labelSheetDecodeWorkbookSave(savedPayload!).activeSheet.images.single;
    expect(saved.src, expectedSrc);
    expect((saved.left, saved.top, saved.width, saved.height), (20, 30, 80, 40));
    expect(saved.extraFields['crop'], _original.extraFields['crop']);
    expect(_original.extraFields.containsKey('originWidth'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default replacement picker cancel preserves image and history', (
    tester,
  ) async {
    final controller = await _pumpWorkbench(tester);
    await tester.tap(_replaceButton);
    await tester.pumpAndSettle();
    expect(selector.calls, 1);
    expect(controller.objectSelection.activeImage!.src, _original.src);
    expect(controller.projectedCanUndo, isFalse);
    expect(controller.activeImagePickerFailed, isFalse);
    expect(tester.widget<OutlinedButton>(_replaceButton).onPressed, isNotNull);
    expect(find.text('이미지를 불러오지 못했습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default replacement picker errors are shown and allow retry', (
    tester,
  ) async {
    final controller = await _pumpWorkbench(tester);
    selector.pick = () async => throw PlatformException(code: 'picker_failed');
    await tester.tap(_replaceButton);
    await tester.pumpAndSettle();
    expect(selector.calls, 1);
    expect(controller.objectSelection.activeImage!.src, _original.src);
    expect(controller.projectedCanUndo, isFalse);
    expect(controller.activeImagePickerFailed, isTrue);
    expect(find.text('이미지를 불러오지 못했습니다.'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(_replaceButton).onPressed, isNotNull);

    selector.pick = () async => null;
    await tester.tap(_replaceButton);
    await tester.pumpAndSettle();
    expect(selector.calls, 2);
    expect(controller.activeImagePickerFailed, isFalse);
    expect(find.text('이미지를 불러오지 못했습니다.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
