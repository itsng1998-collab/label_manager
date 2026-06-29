import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  test('formula bar geometry mirrors upstream FxEditor CSS', () {
    const settings = FortuneSettings();

    expect(fortuneFormulaBarNameBoxWidth, 99.0);
    expect(fortuneFormulaBarFxBoxWidth, 47.0);
    expect(fortuneFormulaBarInputLeftPadding, 2.0);
    expect(settings.effectiveFormulaBarHeight - 1, 28.0);
    expect(
      fortuneFormulaBarNameBoxRect(const Size(640, 360), settings),
      const Rect.fromLTWH(0, 41, 99, 28),
    );
    expect(
      fortuneFormulaBarInputRect(const Size(640, 360), settings),
      const Rect.fromLTWH(148, 41, 492, 28),
    );
  });
}
