import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/nutrition_box.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/page_home/nutrition_box_dialog.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';

void main() {
  test('validation follows legacy name width type order', () {
    expect(nutritionBoxValidationMessage('', 0, null), '명칭을 입력하셔야 합니다 !!');
    expect(nutritionBoxValidationMessage('표', 0, null), '너비를 입력하셔야 합니다 !!');
    expect(nutritionBoxValidationMessage('표', -1, null), '영양성분 형식을 선택하세요');
    expect(nutritionBoxValidationMessage('표', -1, 3), isNull);
  });

  test('dialog lifecycle reports and discards child draft', () async {
    final controller = NutritionBoxDialogController();
    var discarded = false;
    controller.setChildDirty(dirty: true, discard: () async => discarded = true);
    final snapshot = controller.snapshot();
    expect(snapshot.dirtyWorks.single.name, '영양성분표 추가');
    await snapshot.dirtyWorks.single.discard();
    expect(discarded, isTrue);
    controller.dispose();
  });

  test('sheet data is decoded for nutrition preview and editing', () async {
    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'nutrition',
            name: 'Nutrition',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '열량'),
            },
          ),
        ],
      ),
    );

    final workbook = await nutritionBoxWorkbookFromData(
      encoded,
      widthMm: 75,
    );

    expect(workbook.activeSheet.cells.values.single.renderedText, '열량');
  });

  test('legacy RTF data is converted to a nutrition workbook', () async {
    final workbook = await nutritionBoxWorkbookFromData(
      r'{\rtf1\ansi Calories 100}',
      widthMm: 75,
    );

    expect(
      workbook.activeSheet.cells.values
          .map((cell) => cell.renderedText)
          .join('\n'),
      contains('Calories 100'),
    );
  });

  testWidgets('committed delete closes after list reload failure', (
    tester,
  ) async {
    final controller = NutritionBoxDialogController();
    addTearDown(controller.dispose);
    var loads = 0;
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionBoxDialogContent(
            controller: controller,
            onCommitOutcomeUnknown: () => closes += 1,
            loadBoxes: () async {
              loads += 1;
              if (loads > 1) throw Exception('reload failed');
              return const [
                NutritionBox(
                  id: 1,
                  typeId: 2,
                  typeName: '기본형',
                  name: '기본표',
                  rtf: '',
                  width: 100,
                ),
              ];
            },
            loadTypes: () async => const [NutritionType(id: 2, name: '기본형')],
            loadColumns: (_) async => const [],
            insert: ({required typeId, required name, required rtf, required width}) async {},
            update: ({required boxId, required typeId, required name, required rtf, required width}) async {},
            delete: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<NutritionBox>>(
      find.byKey(const ValueKey('nutritionBoxManagerTable')),
    );
    table.onRowSelected!(table.rows.single, 0);
    await tester.pump();
    final deleteButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionBoxDeleteButton')),
    );
    deleteButton.onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });

  testWidgets('manager uses item sheet preview and editor hides object view', (
    tester,
  ) async {
    final controller = NutritionBoxDialogController();
    addTearDown(controller.dispose);
    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        sheets: [FortuneSheet(id: 'nutrition', name: 'Nutrition')],
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionBoxDialogContent(
            controller: controller,
            onCommitOutcomeUnknown: () {},
            loadBoxes: () async => [
              NutritionBox(
                id: 1,
                typeId: 2,
                typeName: '기본형',
                name: '기본표',
                rtf: encoded,
                width: 75,
              ),
            ],
            loadTypes: () async => const [NutritionType(id: 2, name: '기본형')],
            loadColumns: (_) async => const [],
            insert: ({required typeId, required name, required rtf, required width}) async {},
            update: ({required boxId, required typeId, required name, required rtf, required width}) async {},
            delete: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<NutritionBox>>(
      find.byKey(const ValueKey('nutritionBoxManagerTable')),
    );
    table.onRowSelected!(table.rows.single, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LabelOutputPreview), findsOneWidget);
    final preview = tester.widget<LabelOutputPreview>(
      find.byType(LabelOutputPreview),
    );
    expect(
      preview.zoomToolbarBackgroundColor,
      blockingModelessDialogBackgroundColor,
    );
    final previewSheet = tester.widget<LabelSheetWorkbench>(
      find.descendant(
        of: find.byType(LabelOutputPreview),
        matching: find.byType(LabelSheetWorkbench),
      ),
    );
    expect(previewSheet.hideToolbar, isTrue);
    expect(previewSheet.hideRowColumnHeaderLabels, isTrue);
    expect(previewSheet.hideSelectionHighlight, isTrue);
    expect(previewSheet.copyOnlyContextMenu, isTrue);
    expect(previewSheet.canEditObjects, isFalse);
    expect(previewSheet.allowObjectPanel, isFalse);
    expect(previewSheet.showObjectPanelOpenButton, isFalse);
    expect(previewSheet.initialWorkbook!.activeSheet.showGridLines, isFalse);
    expect(previewSheet.zoomToolbarUseIcons, isTrue);
    expect(
      previewSheet.zoomToolbarPlacement,
      LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
    );
    expect(
      previewSheet.zoomToolbarBackgroundColor,
      blockingModelessDialogBackgroundColor,
    );
    final zoomToolbarBackground = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('label-sheet-zoom-toolbar')),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(
      zoomToolbarBackground.color,
      blockingModelessDialogBackgroundColor,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('nutritionBoxManagerToolbar')))
          .height,
      34,
    );
    final initialPreviewWidth = tester
        .getSize(find.byKey(const ValueKey('nutritionBoxPreviewPane')))
        .width;
    tester.widget<VerticalPaneSplitter>(
      find.byKey(const ValueKey('nutritionBoxPreviewSplitter')),
    ).onDrag(-40);
    await tester.pump();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('nutritionBoxPreviewPane')))
          .width,
      initialPreviewWidth + 40,
    );

    final modifyButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionBoxModifyButton')),
    );
    modifyButton.onPressed!();
    await tester.pumpAndSettle();
    final editor = tester.widget<LabelSheetWorkbench>(
      find.byType(LabelSheetWorkbench),
    );
    expect(editor.allowObjectPanel, isFalse);
    expect(editor.showObjectPanelOpenButton, isFalse);
    expect(editor.toolbarItems, isNot(contains(fortuneToolbarObjectPanelCommand)));
    expect(editor.toolbarItems, isNot(contains(labelSheetSaveToolbarCommand)));
    expect(find.text('RTF 편집'), findsNothing);
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey('nutritionBoxEditorSheet')),
      ).dx,
      lessThan(
        tester.getTopLeft(
          find.byKey(const ValueKey('nutritionBoxTypeColumns')),
        ).dx,
      ),
    );
    final editorZoomToolbarRect = tester.getRect(
      find.byKey(const ValueKey('nutritionBoxEditorZoomToolbar')),
    );
    final saveButtonRect = tester.getRect(
      find.byKey(const ValueKey('nutritionBoxSaveButton')),
    );
    expect(editorZoomToolbarRect.center.dy, saveButtonRect.center.dy);
    expect(editorZoomToolbarRect.right, lessThan(saveButtonRect.left));
    final editorSheet = tester.widget<LabelSheetWorkbench>(
      find.byType(LabelSheetWorkbench),
    );
    expect(
      editorSheet.zoomToolbarPlacement,
      LabelSheetZoomToolbarPlacement.hidden,
    );
    final editorZoomToolbar = tester.widget<LabelSheetZoomToolbar>(
      find.byType(LabelSheetZoomToolbar),
    );
    expect(editorZoomToolbar.controller, same(editorSheet.zoomController));
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
  });

  testWidgets('legacy RTF preview floats and restores from zoom toolbar', (
    tester,
  ) async {
    final controller = NutritionBoxDialogController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlockingModelessDialog(
            child: NutritionBoxDialogContent(
              controller: controller,
              onCommitOutcomeUnknown: () {},
              loadBoxes: () async => const [
                NutritionBox(
                  id: 1,
                  typeId: 2,
                  typeName: '기본형',
                  name: 'RTF 표',
                  rtf: r'{\rtf1\ansi Calories 100}',
                  width: 75,
                ),
              ],
              loadTypes: () async => const [],
              loadColumns: (_) async => const [],
              insert: ({required typeId, required name, required rtf, required width}) async {},
              update: ({required boxId, required typeId, required name, required rtf, required width}) async {},
              delete: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<NutritionBox>>(
      find.byKey(const ValueKey('nutritionBoxManagerTable')),
    );
    table.onRowSelected!(table.rows.single, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LabelSheetRtfPreview), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('preview-floating-close-button')),
    );
    await tester.pump();
    final restoreButton = find.byKey(
      const ValueKey('nutritionBoxRtfPreviewRestore'),
    );
    final restoreOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: restoreButton,
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(restoreOpacity.opacity, 1);
    expect(find.byType(LabelSheetRtfPreview), findsNothing);

    await tester.tap(restoreButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LabelSheetRtfPreview), findsOneWidget);
  });

  testWidgets('RTF row change keeps resized floating preview window', (
    tester,
  ) async {
    final controller = NutritionBoxDialogController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlockingModelessDialog(
            child: NutritionBoxDialogContent(
              controller: controller,
              onCommitOutcomeUnknown: () {},
              loadBoxes: () async => const [
                NutritionBox(
                  id: 1,
                  typeId: 2,
                  typeName: '기본형',
                  name: 'RTF 표 1',
                  rtf: r'{\rtf1\ansi Calories 100}',
                  width: 75,
                ),
                NutritionBox(
                  id: 2,
                  typeId: 2,
                  typeName: '기본형',
                  name: 'RTF 표 2',
                  rtf: r'{\rtf1\ansi Calories 200}',
                  width: 90,
                ),
              ],
              loadTypes: () async => const [],
              loadColumns: (_) async => const [],
              insert: ({required typeId, required name, required rtf, required width}) async {},
              update: ({required boxId, required typeId, required name, required rtf, required width}) async {},
              delete: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<NutritionBox>>(
      find.byKey(const ValueKey('nutritionBoxManagerTable')),
    );
    table.onRowSelected!(table.rows.first, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.dragFrom(
      tester.getCenter(
        find.byKey(const ValueKey('floating-resize-bottom-right')),
      ) - const Offset(5, 5),
      const Offset(80, 60),
    );
    await tester.pump();
    final resizedSize = tester.getSize(find.byType(LabelSheetRtfPreview));

    table.onRowSelected!(table.rows.last, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getSize(find.byType(LabelSheetRtfPreview)), resizedSize);
    expect(tester.widget<LabelSheetRtfPreview>(find.byType(LabelSheetRtfPreview)).rtf, contains('200'));
  });

  testWidgets('editor saves current workbook data in rtf column', (tester) async {
    final controller = NutritionBoxDialogController();
    addTearDown(controller.dispose);
    String? savedData;
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionBoxDialogContent(
            controller: controller,
            onCommitOutcomeUnknown: () {},
            loadBoxes: () async => const [],
            loadTypes: () async => const [NutritionType(id: 2, name: '기본형')],
            loadColumns: (_) async => const [],
            insert: ({required typeId, required name, required rtf, required width}) async {
              savedData = rtf;
            },
            update: ({required boxId, required typeId, required name, required rtf, required width}) async {},
            delete: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionBoxAddButton')),
    ).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nutritionBoxNameField')),
      '신규표',
    );
    await tester.enterText(
      find.byKey(const ValueKey('nutritionBoxWidthField')),
      '75',
    );
    tester.widget<ModelessDropdownFormField<int>>(
      find.byKey(const ValueKey('nutritionBoxTypeSelector')),
    ).onChanged!(2);
    await tester.pump();
    final editedWorkbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 'nutrition',
          name: 'Nutrition',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: '나트륨'),
          },
        ),
      ],
    );
    tester.widget<LabelSheetWorkbench>(
      find.byType(LabelSheetWorkbench),
    ).onUserWorkbookChanged!(editedWorkbook);
    await tester.pump();
    tester.widget<FilledButton>(
      find.byKey(const ValueKey('nutritionBoxSaveButton')),
    ).onPressed!();
    await tester.pumpAndSettle();

    final savedWorkbook = labelSheetTryDecodeWorkbookSave(savedData);
    expect(savedWorkbook, isNotNull);
    expect(savedWorkbook!.activeSheet.cells.values.single.renderedText, '나트륨');
  });
}