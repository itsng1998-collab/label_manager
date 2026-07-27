import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/nutrition_box.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/page_home/nutrition_box_dialog.dart';

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
            editRtf: (_) async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('기본표'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nutritionBoxDeleteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });
}