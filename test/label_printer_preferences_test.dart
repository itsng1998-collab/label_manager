import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('preferred printer is saved and loaded when installed', () async {
    await LabelPrinterPreferences.savePreferredPrinterName('Godex G500');

    final loaded = await LabelPrinterPreferences.loadPreferredPrinterName(
      listPrinters: () async => const <Printer>[
        Printer(url: 'g500', name: 'Godex G500'),
      ],
    );

    expect(loaded, 'Godex G500');
  });

  test('preferred print settings are saved and loaded when installed', () async {
    await LabelPrinterPreferences.savePreferredPrintSettings(
      const LabelSheetPreferredPrintSettings(
        printerName: 'Godex G500',
        leftMargin: '1.5',
        topMargin: '2.5',
        autoSpacing: '120',
        extraArea: '3.5',
        orientation: 'vertical',
      ),
    );

    final loaded = await LabelPrinterPreferences.loadPreferredPrintSettings(
      listPrinters: () async => const <Printer>[
        Printer(url: 'g500', name: 'Godex G500'),
      ],
    );

    expect(loaded, isNotNull);
    expect(loaded!.printerName, 'Godex G500');
    expect(loaded.leftMargin, '1.5');
    expect(loaded.topMargin, '2.5');
    expect(loaded.autoSpacing, '120');
    expect(loaded.extraArea, '3.5');
    expect(loaded.orientation, 'vertical');
  });

  test('missing preferred printer is removed while loading', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Missing Printer',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
      labelSheetPreferredPrintTopMarginPrefsKey: '2.5',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '120',
      labelSheetPreferredPrintExtraAreaPrefsKey: '3.5',
      labelSheetPreferredPrintOrientationPrefsKey: 'vertical',
    });

    final loaded = await LabelPrinterPreferences.loadPreferredPrintSettings(
      listPrinters: () async => const <Printer>[
        Printer(url: 'other', name: 'Other Printer'),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    expect(loaded, isNull);
    expect(prefs.getString(labelSheetPreferredPrinterNamePrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintLeftMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintTopMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintExtraAreaPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintOrientationPrefsKey), isNull);
  });

  test('startup cleanup removes missing preferred printer', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Removed Printer',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
      labelSheetPreferredPrintTopMarginPrefsKey: '2.5',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '120',
      labelSheetPreferredPrintExtraAreaPrefsKey: '3.5',
      labelSheetPreferredPrintOrientationPrefsKey: 'vertical',
    });

    final removed = await LabelPrinterPreferences.removePreferredPrinterIfMissing(
      listPrinters: () async => const <Printer>[
        Printer(url: 'alive', name: 'Alive Printer'),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    expect(removed, isTrue);
    expect(prefs.getString(labelSheetPreferredPrinterNamePrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintLeftMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintTopMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintExtraAreaPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintOrientationPrefsKey), isNull);
  });

  test('empty preferred printer name clears all preferred settings', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Removed Printer',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
      labelSheetPreferredPrintTopMarginPrefsKey: '2.5',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '120',
      labelSheetPreferredPrintExtraAreaPrefsKey: '3.5',
      labelSheetPreferredPrintOrientationPrefsKey: 'vertical',
    });

    await LabelPrinterPreferences.savePreferredPrinterName('  ');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(labelSheetPreferredPrinterNamePrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintLeftMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintTopMarginPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintExtraAreaPrefsKey), isNull);
    expect(prefs.getString(labelSheetPreferredPrintOrientationPrefsKey), isNull);
  });

  test('printer query failure keeps saved preference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Temporary Unknown Printer',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
    });

    final loaded = await LabelPrinterPreferences.loadPreferredPrintSettings(
      listPrinters: () => throw StateError('printer query failed'),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(loaded, isNotNull);
    expect(loaded!.printerName, 'Temporary Unknown Printer');
    expect(loaded.leftMargin, '1.5');
    expect(
      prefs.getString(labelSheetPreferredPrinterNamePrefsKey),
      'Temporary Unknown Printer',
    );
    expect(prefs.getString(labelSheetPreferredPrintLeftMarginPrefsKey), '1.5');
  });
}