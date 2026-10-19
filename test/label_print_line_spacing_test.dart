import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:label_manager/features/label_sheet/application/label_sheet_rtf_import.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/label_sheet_zoom.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _settings = fs.FortuneSettings();
const _physical = fs.FortuneSheetGridClientPhysicalSize(
  widthMm: 80,
  heightMm: 60,
);
const _metrics = LabelSheetPrintPageMetrics(
  labelWidthMm: 80,
  labelHeightMm: 60,
  dpi: 203.2,
);

LabelSheetPrintOptions _options(int? percent) => LabelSheetPrintOptions(
  copies: 1,
  leftMarginMm: 0,
  topMarginMm: 0,
  extraAreaMm: 0,
  autoSpacingPercent: percent,
  orientation: LabelSheetPrintOrientation.horizontal,
);

fs.FortuneSheet _sheet() => fs.FortuneSheet(
  id: 'flow',
  name: 'Flow',
  rowCount: 8,
  columnCount: 2,
  defaultColWidth: 150,
  defaultRowHeight: 20,
  rowHeights: {0: 20, 1: 20, 2: 18, 3: 20},
  cells: {
    for (final row in [0, 1, 3])
      fs.FortuneCellCoord(row, 0): fs.FortuneCell(
        value: 'Paragraph $row',
        fontSize: 10,
        verticalAlign: '0',
        textWrap: '2',
        extraFields: const {'lineHeight': 2},
      ),
    const fs.FortuneCellCoord(2, 0): const fs.FortuneCell(
      value: 'Nutrition',
      fontSize: 10,
      textWrap: '2',
    ),
    const fs.FortuneCellCoord(2, 1): const fs.FortuneCell(
      value: 'Amount',
      fontSize: 10,
      textWrap: '2',
    ),
  },
  borderInfo: const [
    fs.FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: ui.Color(0xff000000),
      style: 1,
      ranges: [
        fs.FortuneRange(rowStart: 2, rowEnd: 2, columnStart: 0, columnEnd: 1),
      ],
    ),
  ],
);

LabelSheetWindowsHybridPreparation _prepare(
  fs.FortuneSheet sheet,
  int? percent,
) => prepareLabelSheetWindowsHybridPrint(
  sheet: sheet,
  settings: _settings,
  physicalSize: _physical,
  metrics: _metrics,
  options: _options(percent),
  lineSpacingPercent: percent,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    '80 and 300 percent reflow paragraph rows without stretching tables',
    () {
      final source = _sheet();
      final compact = _prepare(source, 80);
      final expanded = _prepare(source, 300);
      expect(compact.plan.sheet.rowHeights[0], closeTo(8, 0.01));
      expect(expanded.plan.sheet.rowHeights[0], closeTo(30, 0.01));
      expect(compact.plan.sheet.rowHeights[1], closeTo(8, 0.01));
      expect(expanded.plan.sheet.rowHeights[1], closeTo(30, 0.01));
      expect(compact.plan.sheet.rowHeights[2], 18);
      expect(expanded.plan.sheet.rowHeights[2], 18);
      final small = compact.descriptors.firstWhere(
        (d) => d.text == 'Paragraph 1',
      );
      final large = expanded.descriptors.firstWhere(
        (d) => d.text == 'Paragraph 1',
      );
      expect(large.top - small.top, greaterThan(30));
      expect(large.fontPixelHeight, small.fontPixelHeight);
      final smallTable = compact.descriptors.firstWhere(
        (descriptor) => descriptor.text == 'Nutrition',
      );
      final largeTable = expanded.descriptors.firstWhere(
        (descriptor) => descriptor.text == 'Nutrition',
      );
      expect(
        largeTable.bottom - largeTable.top,
        smallTable.bottom - smallTable.top,
      );
      expect(largeTable.fontPixelHeight, smallTable.fontPixelHeight);
      expect(
        largeTable.top - smallTable.top,
        closeTo(44 * _metrics.dpi / 96, 2),
      );
      expect(source.rowHeights[0], 20);
      expect(
        source
            .cells[const fs.FortuneCellCoord(0, 0)]!
            .extraFields['lineHeight'],
        2,
      );
    },
  );

  test(
    'none and zero preserve saved spacing; fonts never scale with percent',
    () {
      final source = _sheet();
      for (final percent in [null, 0]) {
        expect(
          identical(
            labelSheetWithOutputLineSpacing(
              sheet: source,
              settings: _settings,
              percent: percent,
            ),
            source,
          ),
          isTrue,
        );
        expect(
          _prepare(source, percent).plan.sheet.rowHeights,
          source.rowHeights,
        );
      }
      for (final percent in [80, 100, 300]) {
        final output = _prepare(source, percent).plan.sheet;
        expect(output.cells[const fs.FortuneCellCoord(0, 0)]!.fontSize, 10);
        expect(output.cells[const fs.FortuneCellCoord(2, 0)]!.fontSize, 10);
        expect(
          output
              .cells[const fs.FortuneCellCoord(2, 0)]!
              .extraFields['lineHeight'],
          1.15,
        );
      }
      expect(
        () => labelSheetWithOutputLineSpacing(
          sheet: source,
          settings: _settings,
          percent: 301,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'wrapped rich paragraphs use largest inline font and reflow every line',
    () {
      final source = _sheet().copyWith(
        cells: {
          const fs.FortuneCellCoord(0, 0): const fs.FortuneCell(
            value: 'BIG\nsmall',
            fontSize: 10,
            textWrap: '2',
            inlineRuns: [
              fs.FortuneInlineTextRun(text: 'BIG\n', fontSize: 20),
              fs.FortuneInlineTextRun(text: 'small', fontSize: 10),
            ],
          ),
          const fs.FortuneCellCoord(1, 0): const fs.FortuneCell(
            value: 'Next',
            fontSize: 10,
          ),
        },
      );
      final compact = _prepare(source, 80);
      final expanded = _prepare(source, 300);
      expect(compact.plan.sheet.rowHeights[0], closeTo(24, 0.01));
      expect(expanded.plan.sheet.rowHeights[0], closeTo(90, 0.01));
      expect(
        expanded
            .plan
            .sheet
            .cells[const fs.FortuneCellCoord(0, 0)]!
            .inlineRuns!
            .first
            .fontSize,
        20,
      );
      expect(
        expanded.descriptors.firstWhere((d) => d.text == 'Next').top,
        greaterThan(
          compact.descriptors.firstWhere((d) => d.text == 'Next').top,
        ),
      );
    },
  );

  test('single-cell borderless RTF tables retain legacy 115 percent rule', () {
    final draft = labelSheetDraftFromRichEditRtf(
      r'{\rtf1\ansi\deff0{\fonttbl{\f0 Arial;}}'
      r'\f0\fs15 First\par'
      r'\trowd\trrh240\cellx3000\pard\intbl Table\cell\row'
      r'\pard After\par}',
      sheet: _sheet(),
    )!;
    final imported = _sheet().copyWith(
      cells: draft.cells,
      borderInfo: [],
      rowHeights: {0: 20, 1: 18, 2: 20},
    );
    final roundTrip = fs.FortuneSheetCodec.workbookFromJson(
      fs.FortuneSheetCodec.workbookToJson(
        fs.FortuneWorkbook(sheets: [imported]),
      ),
    ).activeSheet;
    const tableCoord = fs.FortuneCellCoord(1, 0);
    expect(
      roundTrip.cells[tableCoord]!.extraFields['labelRtfTableCell'],
      isTrue,
    );
    for (final percent in [80, 300]) {
      final output = _prepare(roundTrip, percent).plan.sheet;
      expect(output.rowHeights[1], 18);
      expect(output.cells[tableCoord]!.extraFields['lineHeight'], 1.15);
    }
    expect(
      roundTrip
          .cells[const fs.FortuneCellCoord(0, 0)]!
          .extraFields['labelRtfTableCell'],
      isNull,
    );
  });

  test(
    'repeated preparation is idempotent and only RTF-anchored images flow',
    () {
      final source = _sheet().copyWith(
        images: const [
          fs.FortuneImage(
            id: 'rtf',
            src: '',
            left: 0,
            top: 61,
            width: 10,
            height: 10,
            extraFields: {'rtfPicture': true},
          ),
          fs.FortuneImage(
            id: 'fixed',
            src: '',
            left: 30,
            top: 61,
            width: 10,
            height: 10,
          ),
        ],
      );
      final once = _prepare(source, 300).plan.sheet;
      final twice = _prepare(once, 300).plan.sheet;
      expect(once.rowHeights, twice.rowHeights);
      expect(once.images.first.top, 81);
      expect(twice.images.first.top, 81);
      expect(once.images.last.top, 61);
      expect(source.images.first.top, 61);
      expect(
        _prepare(once, 80).plan.sheet.rowHeights,
        _prepare(source, 80).plan.sheet.rowHeights,
      );
      final ezpl = prepareLabelSheetEzplPrint(
        sheet: source,
        settings: _settings,
        physicalSize: _physical,
        metrics: _metrics,
        options: _options(300),
        lineSpacingPercent: 300,
      );
      expect(ezpl.plan.sheet.rowHeights, once.rowHeights);
      expect(ezpl.plan.sheet.images.first.top, 81);
    },
  );

  testWidgets(
    'G500 capture, bitmap fallback and preview share spacing geometry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = _sheet().copyWith(
        extraFields: const {
          fs.fortuneSheetGridClientWidthMmKey: 80,
          fs.fortuneSheetGridClientHeightMmKey: 60,
        },
      );
      final workbook = fs.FortuneWorkbook(sheets: [source]);
      final capture = LabelSheetOutputCaptureController();
      final zoom = LabelSheetZoomController();
      addTearDown(zoom.dispose);
      Widget preview(int? percent, {bool applyToPreview = false}) =>
          MaterialApp(
            home: Scaffold(
              body: LabelOutputPreview(
                workbook: workbook,
                hintText: null,
                identityKey: 'spacing',
                imageObjectIds: const [],
                barcodeObjectIds: const [],
                labelSize: const LabelSize(
                  labelSizeId: 1,
                  brandId: 1,
                  labelSizeName: 'Label',
                  labelSizeCommon: LabelSizeCommon(
                    width: 80,
                    height: 60,
                    rtf: '',
                  ),
                ),
                outputCaptureController: capture,
                zoomController: zoom,
                printOptions: applyToPreview ? _options(percent) : null,
              ),
            ),
          );
      await tester.pumpWidget(preview(null));
      await tester.pumpAndSettle();
      zoom.setZoomPercent(150);
      await tester.pumpAndSettle();
      final compact = await tester.runAsync(
        () => capture.captureWindowsDriver(
          metrics: _metrics,
          options: _options(80),
          lineSpacingPercent: 80,
        ),
      );
      final expanded = await tester.runAsync(
        () => capture.captureWindowsDriver(
          metrics: _metrics,
          options: _options(300),
          lineSpacingPercent: 300,
        ),
      );
      expect(compact, isNotNull);
      expect(expanded, isNotNull);
      final smallTop = compact!.textDescriptors
          .firstWhere((d) => d.text == 'Paragraph 1')
          .top;
      final bigTop = expanded!.textDescriptors
          .firstWhere((d) => d.text == 'Paragraph 1')
          .top;
      expect(bigTop - smallTop, greaterThan(30));
      expect(compact.pngBytes, isNot(orderedEquals(expanded.pngBytes)));
      final compactRaster = await tester.runAsync(
        () => capture.capture(dpi: 203.2, lineSpacingPercent: 80),
      );
      final expandedRaster = await tester.runAsync(
        () => capture.capture(dpi: 203.2, lineSpacingPercent: 300),
      );
      expect(
        compactRaster!.pngBytes,
        isNot(orderedEquals(expandedRaster!.pngBytes)),
      );
      expect(compactRaster.sheet.rowHeights, compact.sheet.rowHeights);
      expect(expandedRaster.sheet.rowHeights, expanded.sheet.rowHeights);
      final ezpl = await tester.runAsync(
        () => capture.captureEzpl(
          metrics: _metrics,
          options: _options(300),
          lineSpacingPercent: 300,
        ),
      );
      expect(ezpl!.sheet.rowHeights, expanded.sheet.rowHeights);
      expect(capture.debugActiveSheet!.rowHeights[0], 20);
      for (final percent in [80, 300, 80]) {
        await tester.pumpWidget(preview(percent, applyToPreview: true));
        await tester.pumpAndSettle();
        expect(
          capture.debugActiveSheet!.rowHeights[0],
          closeTo(percent / 10, 0.01),
        );
        expect(capture.debugActiveSheet!.rowHeights[2], 18);
        expect(zoom.value, 150);
        final printed = await tester.runAsync(
          () => capture.captureWindowsDriver(
            metrics: _metrics,
            options: _options(percent),
            lineSpacingPercent: percent,
          ),
        );
        expect(
          printed!.textDescriptors
              .firstWhere((d) => d.text == 'Paragraph 1')
              .top,
          percent == 80 ? smallTop : bigTop,
        );
      }
      await tester.pumpWidget(preview(null));
      await tester.pumpAndSettle();
      expect(capture.debugActiveSheet!.rowHeights[0], 20);
      expect(source.rowHeights[0], 20);
      expect(
        source
            .cells[const fs.FortuneCellCoord(0, 0)]!
            .extraFields['lineHeight'],
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
