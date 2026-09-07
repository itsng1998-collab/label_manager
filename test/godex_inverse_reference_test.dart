import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:label_manager/features/label_sheet/application/label_sheet_rtf_import.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('documents legacy 5pt inverse size loss in current Windows path', () {
    const text = '계란,우유,대두,밀 함유';
    final unicodeText = text.codeUnits
        .map((unit) => '\\u${unit > 32767 ? unit - 65536 : unit}?')
        .join();
    final rtf = r'{\rtf1\ansi\deff0\uc1'
        r'{\fonttbl{\f0\fnil\fcharset129 굴림;}}'
        r'{\colortbl;\red255\green255\blue255;\red25\green19\blue26;}'
        r'\trowd\trrh360\cellx4000\pard\intbl\f0\fs10\b\cf1 '
        '$unicodeText'
        r'\cell\row}';
    final draft = labelSheetDraftFromRichEditRtf(
      rtf,
      sheet: fs.FortuneSheet(id: 'reference', name: 'Reference'),
    );
    expect(draft, isNotNull);
    final cell = draft!.cells.values.single;
    expect(cell.renderedText.trim(), text);
    expect(cell.fontSize, 5);
    expect(cell.fontFamily, '굴림');
    expect(cell.bold, isTrue);
    expect(cell.foreground, const ui.Color(0xffffffff));

    final preparation = prepareLabelSheetWindowsHybridPrint(
      sheet: fs.FortuneSheet(
        id: 'reference',
        name: 'Reference',
        cells: draft.cells,
        defaultRowHeight: 24,
        defaultColWidth: 260,
      ),
      settings: const fs.FortuneSettings(fontFamilies: ['굴림']),
      physicalSize: const fs.FortuneSheetGridClientPhysicalSize(
        widthMm: 80,
        heightMm: 60,
      ),
      metrics: const LabelSheetPrintPageMetrics(
        labelWidthMm: 80,
        labelHeightMm: 60,
        dpi: 203.2,
      ),
      options: const LabelSheetPrintOptions(
        copies: 1,
        leftMarginMm: 0,
        topMarginMm: 0,
        extraAreaMm: 0,
        autoSpacingPercent: null,
        orientation: LabelSheetPrintOrientation.horizontal,
      ),
      lineSpacingPercent: null,
    );
    expect(preparation.descriptors, isNotEmpty);
    expect(preparation.descriptors.map((value) => value.text).join(), text);
    final legacyDots = (5 * 203.2 / 72).round();
    final currentDots = (5 * 203.2 / 96).round();
    expect(legacyDots, 14);
    expect(currentDots, 11);
    for (final descriptor in preparation.descriptors) {
      expect(descriptor.fontFamily, '굴림');
      expect(descriptor.fontPixelHeight, currentDots);
      expect(descriptor.fontPixelHeight, isNot(legacyDots));
      expect(descriptor.bold, isTrue);
      expect(descriptor.colorArgb, 0xffffffff);
      expect(descriptor.wrap, isFalse);
    }
  });
}