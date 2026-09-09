import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:label_manager/features/label_sheet/application/label_sheet_rtf_import.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final points in [5, 6, 8]) {
  test('preserves legacy ${points}pt inverse physical size in Windows output', () {
    const text = '계란,우유,대두,밀 함유';
    final unicodeText = text.codeUnits
        .map((unit) => '\\u${unit > 32767 ? unit - 65536 : unit}?')
        .join();
    final rtf = r'{\rtf1\ansi\deff0\uc1'
        r'{\fonttbl{\f0\fnil\fcharset129 굴림;}}'
        r'{\colortbl;\red255\green255\blue255;\red25\green19\blue26;}'
        r'\trowd\trrh360\cellx4000\pard\intbl\f0'
        '\\fs${points * 2}\\b\\cf1 '
        '$unicodeText'
        r'\cell\row}';
    final draft = labelSheetDraftFromRichEditRtf(
      rtf,
      sheet: fs.FortuneSheet(id: 'reference', name: 'Reference'),
    );
    expect(draft, isNotNull);
    final cell = draft!.cells.values.single;
    expect(cell.renderedText.trim(), text);
    expect(cell.fontSize, closeTo(points * 96 / 72, 0.0001));
    expect(cell.rawFontSize, closeTo(points * 96 / 72, 0.0001));
    for (final run in cell.inlineRuns!) {
      expect(run.fontSize, closeTo(points * 96 / 72, 0.0001));
      expect(run.rawFontSize, closeTo(points * 96 / 72, 0.0001));
    }
    expect(cell.fontFamily, '굴림');
    expect(cell.bold, isTrue);
    expect(cell.foreground, const ui.Color(0xffffffff));

    final importedSheet = fs.FortuneSheet(
        id: 'reference',
        name: 'Reference',
        cells: draft.cells,
        defaultRowHeight: 24,
        defaultColWidth: 260,
      );
    final reloaded = fs.FortuneSheetCodec.workbookFromJson(
      fs.FortuneSheetCodec.workbookToJson(
        fs.FortuneWorkbook(sheets: [importedSheet]),
      ),
    ).activeSheet;
    final reloadedCell = reloaded.cells.values.single;
    expect(reloadedCell.fontSize, closeTo(points * 96 / 72, 0.0001));
    expect(reloadedCell.rawFontSize, closeTo(points * 96 / 72, 0.0001));
    for (final run in reloadedCell.inlineRuns!) {
      expect(run.fontSize, closeTo(points * 96 / 72, 0.0001));
      expect(run.rawFontSize, closeTo(points * 96 / 72, 0.0001));
    }
    final preparation = _prepare(reloaded);
    expect(preparation.descriptors, isNotEmpty);
    expect(preparation.descriptors.map((value) => value.text).join(), text);
    final legacyDots = (points * 203.2 / 72).round();
    for (final descriptor in preparation.descriptors) {
      expect(descriptor.fontFamily, '굴림');
      expect(descriptor.fontPixelHeight, legacyDots);
      expect(descriptor.bold, isTrue);
      expect(descriptor.colorArgb, 0xffffffff);
      expect(descriptor.wrap, isFalse);
    }
  });
  }

  test('keeps existing sheet logical font sizes unchanged', () {
    for (final color in [const ui.Color(0xffffffff), const ui.Color(0xff000000)]) {
      final sheet = fs.FortuneSheet(
        id: 'existing',
        name: 'Existing',
        defaultRowHeight: 24,
        defaultColWidth: 260,
        cells: {
          const fs.FortuneCellCoord(0, 0): fs.FortuneCell(
            value: '기존 글자',
            fontSize: 8,
            fontFamily: '굴림',
            foreground: color,
            background: color == const ui.Color(0xffffffff)
                ? const ui.Color(0xff000000) : const ui.Color(0xffffffff),
            bold: true,
          ),
        },
      );
      final preparation = _prepare(sheet);
      expect(preparation.descriptors, isNotEmpty);
      for (final descriptor in preparation.descriptors) {
        expect(descriptor.fontPixelHeight, 17);
      }
      expect(sheet.cells.values.single.fontSize, 8);
    }
  });
}

LabelSheetWindowsHybridPreparation _prepare(fs.FortuneSheet sheet) {
  return prepareLabelSheetWindowsHybridPrint(
    sheet: sheet,
    settings: const fs.FortuneSettings(fontFamilies: ['굴림']),
    physicalSize: const fs.FortuneSheetGridClientPhysicalSize(widthMm: 80, heightMm: 60),
    metrics: const LabelSheetPrintPageMetrics(labelWidthMm: 80, labelHeightMm: 60, dpi: 203.2),
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
}