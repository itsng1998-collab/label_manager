import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String labelSheetPreferredPrinterNamePrefsKey =
    'label_sheet_preferred_printer_name';

typedef LabelPrinterListProvider = Future<List<Printer>> Function();

class LabelPrinterPreferences {
  const LabelPrinterPreferences._();

  static Future<String?> loadPreferredPrinterName({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs
        .getString(labelSheetPreferredPrinterNamePrefsKey)
        ?.trim();
    if (savedName == null || savedName.isEmpty) {
      await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
      return null;
    }

    final installed = await _isPrinterInstalled(
      savedName,
      listPrinters: listPrinters,
    );
    if (installed == false) {
      await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
      return null;
    }
    return savedName;
  }

  static Future<void> savePreferredPrinterName(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = printerName.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
      return;
    }
    await prefs.setString(labelSheetPreferredPrinterNamePrefsKey, trimmed);
  }

  static Future<void> clearPreferredPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
  }

  static Future<bool> removePreferredPrinterIfMissing({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs
        .getString(labelSheetPreferredPrinterNamePrefsKey)
        ?.trim();
    if (savedName == null || savedName.isEmpty) {
      await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
      return false;
    }

    final installed = await _isPrinterInstalled(
      savedName,
      listPrinters: listPrinters,
    );
    if (installed == false) {
      await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
      return true;
    }
    return false;
  }

  /// Future label-sheet printing should resolve this saved printer name and
  /// target the matching [Printer] when sending the actual print job.
  static Future<Printer?> resolvePreferredPrinter({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final savedName = await loadPreferredPrinterName(
      listPrinters: listPrinters,
    );
    if (savedName == null) {
      return null;
    }
    final printers = await (listPrinters ?? Printing.listPrinters)();
    return _findPrinterByName(printers, savedName);
  }

  static Future<bool?> _isPrinterInstalled(
    String printerName, {
    LabelPrinterListProvider? listPrinters,
  }) async {
    try {
      final printers = await (listPrinters ?? Printing.listPrinters)();
      return _findPrinterByName(printers, printerName) != null;
    } catch (_) {
      return null;
    }
  }

  static Printer? _findPrinterByName(List<Printer> printers, String name) {
    final normalizedName = _normalizePrinterName(name);
    for (final printer in printers) {
      if (_normalizePrinterName(printer.name) == normalizedName) {
        return printer;
      }
    }
    return null;
  }

  static String _normalizePrinterName(String value) =>
      value.trim().toLowerCase();
}