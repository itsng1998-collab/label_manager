import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';

void main() {
  test(
    'hyperlink range selection geometry mirrors upstream LinkEidtCard CSS',
    () {
      expect(fortuneHyperlinkDialogLabelTextHeight, 16.0);
      expect(fortuneHyperlinkDialogBorderColor, const Color(0xffe5e5e5));
      expect(fortuneHyperlinkDialogLabelVerticalPadding, 7.0);
      expect(fortuneHyperlinkDialogLabelBoxHeight, 30.0);
      expect(fortuneHyperlinkDialogLabelColor, const Color(0xff333333));
      expect(fortuneHyperlinkDialogInputBorderRadius, 5.0);
      expect(fortuneHyperlinkDialogInputHorizontalPadding, 8.0);
      expect(fortuneHyperlinkDialogInputBorderColor, const Color(0xffd9d9d9));
      expect(
        fortuneHyperlinkDialogInputFocusBorderColor,
        const Color(0xff4d90fe),
      );
      expect(fortuneHyperlinkDialogCellSelectorContentSize, 20.0);
      expect(fortuneHyperlinkDialogCellSelectorPadding, 4.0);
      expect(fortuneHyperlinkDialogCellSelectorSize, 26.0);
      expect(fortuneHyperlinkDialogCellSelectorBorderRadius, 5.0);
      expect(
        fortuneHyperlinkDialogCellSelectorBackgroundColor,
        const Color(0xfff7f7f7),
      );
      expect(
        fortuneHyperlinkDialogCellSelectorBorderColor,
        const Color(0xffd9d9d9),
      );
      expect(
        fortuneHyperlinkDialogCellSelectorIconColor,
        const Color(0xff333333),
      );
      expect(fortuneHyperlinkDialogCellSelectorIconStrokeWidth, 1.2);
      expect(fortuneHyperlinkCardContentTextInset, 8.0);
      expect(fortuneHyperlinkCardBorderColor, const Color(0xffd9d9d9));
      expect(fortuneHyperlinkCardContentTextColor, const Color(0xff1a73e8));
      expect(fortuneHyperlinkCardButtonTextColor, const Color(0xff333333));
      expect(fortuneHyperlinkRangeSelectionContentWidth, 380.0);
      expect(fortuneHyperlinkRangeSelectionPadding, 22.0);
      expect(fortuneHyperlinkRangeSelectionDialogWidth, 424.0);
      expect(fortuneHyperlinkRangeSelectionTitleFontSize, 16.0);
      expect(fortuneHyperlinkRangeSelectionTitleColor, const Color(0xdd000000));
      expect(fortuneHyperlinkRangeSelectionTitleFontWeight, FontWeight.w500);
      expect(fortuneHyperlinkRangeSelectionInputBorderRadius, 4.0);
      expect(fortuneHyperlinkRangeSelectionInputHorizontalPadding, 11.0);
      expect(
        fortuneHyperlinkRangeSelectionInputFocusBorderColor,
        const Color(0xff4d90fe),
      );

      final dialogRect = fortuneHyperlinkRangeSelectionDialogRect(
        const Size(800, 600),
        const Rect.fromLTWH(100, 120, 80, 24),
      );
      expect(dialogRect, const Rect.fromLTWH(100, 149, 424, 145));
      expect(
        fortuneHyperlinkRangeSelectionInputRect(dialogRect),
        const Rect.fromLTWH(122, 207, 380, 32),
      );

      final hyperlinkDialogRect = fortuneHyperlinkDialogRect(
        const Size(800, 600),
        const Rect.fromLTWH(100, 120, 80, 24),
      );
      expect(
        fortuneHyperlinkDialogCellSelectorRect(hyperlinkDialogRect),
        const Rect.fromLTWH(426, 240, 26, 26),
      );
    },
  );
}
