import 'package:flutter_test/flutter_test.dart';
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
}