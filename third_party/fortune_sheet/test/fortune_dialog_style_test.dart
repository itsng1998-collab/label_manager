import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('default dialog button colors mirror upstream Dialog CSS', () {
    expect(fortuneDialogDefaultButtonBackgroundColor, const Color(0xffffffff));
    expect(fortuneDialogDefaultButtonBorderColor, const Color(0xffebebeb));
    expect(fortuneDialogDefaultButtonTextColor, const Color(0xff262a33));
    expect(fortuneDialogPrimaryButtonBackgroundColor, const Color(0xff0188fb));
    expect(fortuneDialogPrimaryButtonTextColor, const Color(0xffffffff));
    expect(fortuneDialogMessageButtonBorderRadius, 4.0);
    expect(fortuneDialogMessageButtonFontSize, 14.0);
  });
}
