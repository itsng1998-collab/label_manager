import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String labelSheetPreferredPrinterNamePrefsKey =
    'label_sheet_preferred_printer_name';
const String labelSheetPreferredPrintLeftMarginPrefsKey =
  'label_sheet_preferred_print_left_margin';
const String labelSheetPreferredPrintTopMarginPrefsKey =
  'label_sheet_preferred_print_top_margin';
const String labelSheetPreferredPrintAutoSpacingPrefsKey =
  'label_sheet_preferred_print_auto_spacing';
const String labelSheetPreferredPrintExtraAreaPrefsKey =
  'label_sheet_preferred_print_extra_area';
const String labelSheetPreferredPrintOrientationPrefsKey =
  'label_sheet_preferred_print_orientation';

typedef LabelPrinterListProvider = Future<List<Printer>> Function();

class LabelSheetPreferredPrintSettings {
  const LabelSheetPreferredPrintSettings({
  required this.printerName,
  required this.leftMargin,
  required this.topMargin,
  required this.autoSpacing,
  required this.extraArea,
  required this.orientation,
  });

  final String printerName;
  final String leftMargin;
  final String topMargin;
  final String autoSpacing;
  final String extraArea;
  final String orientation;
}

class LabelPrinterPreferences {
  const LabelPrinterPreferences._();

  static Future<String?> loadPreferredPrinterName({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final settings = await loadPreferredPrintSettings(
      listPrinters: listPrinters,
    );
    return settings?.printerName;
  }

  static Future<LabelSheetPreferredPrintSettings?> loadPreferredPrintSettings({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs
        .getString(labelSheetPreferredPrinterNamePrefsKey)
        ?.trim();
    if (savedName == null || savedName.isEmpty) {
      await _clearPreferredPrintSettings(prefs);
      return null;
    }

    final installed = await _isPrinterInstalled(
      savedName,
      listPrinters: listPrinters,
    );
    if (installed == false) {
      await _clearPreferredPrintSettings(prefs);
      return null;
    }
    return LabelSheetPreferredPrintSettings(
      printerName: savedName,
      leftMargin:
          prefs.getString(labelSheetPreferredPrintLeftMarginPrefsKey) ?? '0.0',
      topMargin:
          prefs.getString(labelSheetPreferredPrintTopMarginPrefsKey) ?? '0.0',
      autoSpacing:
          prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey) ?? 'none',
      extraArea:
          prefs.getString(labelSheetPreferredPrintExtraAreaPrefsKey) ?? '0.0',
      orientation:
          prefs.getString(labelSheetPreferredPrintOrientationPrefsKey) ??
          'horizontal',
    );
  }

  static Future<void> savePreferredPrinterName(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = printerName.trim();
    if (trimmed.isEmpty) {
      await _clearPreferredPrintSettings(prefs);
      return;
    }
    await prefs.setString(labelSheetPreferredPrinterNamePrefsKey, trimmed);
  }

  static Future<void> savePreferredPrintSettings(
    LabelSheetPreferredPrintSettings settings,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final printerName = settings.printerName.trim();
    if (printerName.isEmpty) {
      await _clearPreferredPrintSettings(prefs);
      return;
    }
    await prefs.setString(labelSheetPreferredPrinterNamePrefsKey, printerName);
    await prefs.setString(
      labelSheetPreferredPrintLeftMarginPrefsKey,
      settings.leftMargin,
    );
    await prefs.setString(
      labelSheetPreferredPrintTopMarginPrefsKey,
      settings.topMargin,
    );
    await prefs.setString(
      labelSheetPreferredPrintAutoSpacingPrefsKey,
      settings.autoSpacing,
    );
    await prefs.setString(
      labelSheetPreferredPrintExtraAreaPrefsKey,
      settings.extraArea,
    );
    await prefs.setString(
      labelSheetPreferredPrintOrientationPrefsKey,
      settings.orientation,
    );
  }

  static Future<void> clearPreferredPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearPreferredPrintSettings(prefs);
  }

  static Future<bool> removePreferredPrinterIfMissing({
    LabelPrinterListProvider? listPrinters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs
        .getString(labelSheetPreferredPrinterNamePrefsKey)
        ?.trim();
    if (savedName == null || savedName.isEmpty) {
      await _clearPreferredPrintSettings(prefs);
      return false;
    }

    final installed = await _isPrinterInstalled(
      savedName,
      listPrinters: listPrinters,
    );
    if (installed == false) {
      await _clearPreferredPrintSettings(prefs);
      return true;
    }
    return false;
  }

  /// Future label-sheet printing should load these saved settings, resolve the
  /// saved printer name, and target the matching [Printer] when sending the
  /// actual print job. Copies are intentionally not persisted.
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

  static Future<void> _clearPreferredPrintSettings(
    SharedPreferences prefs,
  ) async {
    await prefs.remove(labelSheetPreferredPrinterNamePrefsKey);
    await prefs.remove(labelSheetPreferredPrintLeftMarginPrefsKey);
    await prefs.remove(labelSheetPreferredPrintTopMarginPrefsKey);
    await prefs.remove(labelSheetPreferredPrintAutoSpacingPrefsKey);
    await prefs.remove(labelSheetPreferredPrintExtraAreaPrefsKey);
    await prefs.remove(labelSheetPreferredPrintOrientationPrefsKey);
  }
}