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

  test('missing preferred printer is removed while loading', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Missing Printer',
    });

    final loaded = await LabelPrinterPreferences.loadPreferredPrinterName(
      listPrinters: () async => const <Printer>[
        Printer(url: 'other', name: 'Other Printer'),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    expect(loaded, isNull);
    expect(prefs.getString(labelSheetPreferredPrinterNamePrefsKey), isNull);
  });

  test('startup cleanup removes missing preferred printer', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Removed Printer',
    });

    final removed = await LabelPrinterPreferences.removePreferredPrinterIfMissing(
      listPrinters: () async => const <Printer>[
        Printer(url: 'alive', name: 'Alive Printer'),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    expect(removed, isTrue);
    expect(prefs.getString(labelSheetPreferredPrinterNamePrefsKey), isNull);
  });

  test('printer query failure keeps saved preference', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Temporary Unknown Printer',
    });

    final loaded = await LabelPrinterPreferences.loadPreferredPrinterName(
      listPrinters: () => throw StateError('printer query failed'),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(loaded, 'Temporary Unknown Printer');
    expect(
      prefs.getString(labelSheetPreferredPrinterNamePrefsKey),
      'Temporary Unknown Printer',
    );
  });
}