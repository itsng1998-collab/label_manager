import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_print/application/label_print_settings.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('label print settings snapshot loads all physical fields', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Godex G500',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
      labelSheetPreferredPrintRightMarginPrefsKey: '2.5',
      labelSheetPreferredPrintTopMarginPrefsKey: '3.5',
      labelSheetPreferredPrintLeftPushPrefsKey: '-1.25',
      labelSheetPreferredPrintTopPushPrefsKey: '0.75',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '125',
      labelSheetPreferredPrintExtraAreaPrefsKey: '4.5',
      labelSheetPreferredPrintWidthAppendPrefsKey: '1.25',
      labelSheetPreferredPrintOrientationPrefsKey: 'vertical',
    });

    final loaded = await loadLabelPrintSettingsSnapshot();

    expect(loaded.printerName, 'Godex G500');
    expect(loaded.leftMarginMm, 1.5);
    expect(loaded.rightMarginMm, 2.5);
    expect(loaded.topMarginMm, 3.5);
    expect(loaded.leftPushMm, -1.25);
    expect(loaded.topPushMm, 0.75);
    expect(loaded.lineSpacingPercent, 125);
    expect(loaded.extraAreaMm, 4.5);
    expect(loaded.widthAppendMm, 1.25);
    expect(loaded.orientation, LabelPrintOrientation.vertical);
    expect(loaded.pdfSingleFile, isTrue);
  });

  test('label print settings normalizes non-legacy auto spacing', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Godex G500',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '123',
    });

    final loaded = await loadLabelPrintSettingsSnapshot();

    expect(loaded.lineSpacingPercent, 100);
  });

  test('label print settings input builds a snapshot', () {
    final settings = parseLabelPrintSettingsSnapshot(
      printerName: ' Godex G500 ',
      leftMargin: '1.5',
      rightMargin: '2.5',
      topMargin: '3.5',
      leftPush: '-1.25',
      topPush: '0.75',
      lineSpacing: '0',
      extraArea: '4.5',
      widthAppend: '1.25',
      orientation: 'vertical',
      pdfSingleFile: false,
    );

    expect(settings, isNotNull);
    expect(settings!.printerName, 'Godex G500');
    expect(settings.leftMarginMm, 1.5);
    expect(settings.rightMarginMm, 2.5);
    expect(settings.topMarginMm, 3.5);
    expect(settings.leftPushMm, -1.25);
    expect(settings.topPushMm, 0.75);
    expect(settings.lineSpacingPercent, isNull);
    expect(settings.extraAreaMm, 4.5);
    expect(settings.widthAppendMm, 1.25);
    expect(settings.orientation, LabelPrintOrientation.vertical);
    expect(settings.pdfSingleFile, isFalse);
  });

  test('label print settings input rejects invalid physical values', () {
    LabelPrintSettingsSnapshot? parse({
      String leftMargin = '1',
      String lineSpacing = '100',
    }) => parseLabelPrintSettingsSnapshot(
      printerName: 'Godex G500',
      leftMargin: leftMargin,
      rightMargin: '2',
      topMargin: '3',
      leftPush: '-1',
      topPush: '1',
      lineSpacing: lineSpacing,
      extraArea: '0',
      orientation: 'horizontal',
    );

    expect(parse(leftMargin: '-1'), isNull);
    expect(parse(lineSpacing: '123'), isNull);
  });
}