import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  test('formula search dialog style mirrors local canvas constants', () {
    expect(fortuneFormulaSearchOverlayColor, const Color(0x1a000000));
    expect(fortuneFormulaSearchDialogBorderColor, const Color(0x11000000));
    expect(fortuneFormulaSearchInputHorizontalPadding, 10.0);
    expect(fortuneFormulaSearchFieldHorizontalPadding, 8.0);
    expect(fortuneFormulaSearchCategoryArrowReserve, 28.0);
    expect(fortuneFormulaSearchCategoryArrowLeftInset, 16.0);
    expect(fortuneFormulaSearchCategoryArrowRightInset, 8.0);
    expect(fortuneFormulaSearchCategoryArrowCenterInset, 12.0);
    expect(fortuneFormulaSearchCategoryArrowTopInset, 9.0);
    expect(fortuneFormulaSearchCategoryArrowBottomInset, 14.0);
    expect(fortuneFormulaSearchFieldBorderColor, const Color(0xffd4d4d4));
    expect(fortuneFormulaSearchBackgroundColor, const Color(0xffffffff));
    expect(fortuneFormulaSearchCloseColor, const Color(0xffb6b6b6));
    expect(fortuneFormulaSearchArrowColor, const Color(0xff000000));
    expect(fortuneFormulaSearchTextColor, const Color(0xff222222));
    expect(fortuneFormulaSearchPlaceholderColor, const Color(0xff777777));
    expect(fortuneFormulaSearchSelectedColor, const Color(0xff8c89fe));
    expect(fortuneFormulaSearchSelectedTextColor, const Color(0xffffffff));
  });
}
