import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/label_size.dart';

void main() {
  tearDown(() {
    LabelSize.setDatas(null);
  });

  test('replaceCachedFormData updates matching cached label size immutably', () {
    const original = LabelSize(
      labelSizeId: 10,
      brandId: 1,
      labelSizeName: '100x60',
      labelSizeCommon: LabelSizeCommon(width: 100, height: 60, rtf: 'old'),
    );
    const other = LabelSize(
      labelSizeId: 11,
      brandId: 1,
      labelSizeName: '80x40',
      labelSizeCommon: LabelSizeCommon(width: 80, height: 40, rtf: 'other'),
    );
    LabelSize.setDatas([original, other]);

    final updated = LabelSize.replaceCachedFormData(
      10,
      120,
      75,
      'new',
    );

    expect(updated, isNot(same(original)));
    expect(updated?.labelSizeCommon?.width, 120);
    expect(updated?.labelSizeCommon?.height, 75);
    expect(updated?.labelSizeCommon?.rtf, 'new');
    expect(original.labelSizeCommon?.width, 100);
    expect(original.labelSizeCommon?.height, 60);
    expect(original.labelSizeCommon?.rtf, 'old');
    expect(LabelSize.datas, hasLength(2));
    expect(LabelSize.datas![0], same(updated));
    expect(LabelSize.datas![1], same(other));
  });
}
