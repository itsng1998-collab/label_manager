import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';

int? normalizeLegacyLabelPrintSpacingPercent(int? value) {
  if (value == null) return null;
  return value >= 80 && value <= 300 && (value - 80) % 5 == 0 ? value : 100;
}

Future<LabelPrintSettingsSnapshot> loadLabelPrintSettingsSnapshot() async {
  final settings = await LabelPrinterPreferences.loadPreferredPrintSettings();
  if (settings == null) return const LabelPrintSettingsSnapshot.empty();
  double nonNegative(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : 0;
  }

  double signed(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

  final autoSpacing = settings.autoSpacing.trim();
  final spacing = autoSpacing == 'none' || autoSpacing == '0'
      ? null
      : normalizeLegacyLabelPrintSpacingPercent(int.tryParse(autoSpacing)) ??
            100;
  return LabelPrintSettingsSnapshot(
    printerName: settings.printerName,
    leftMarginMm: nonNegative(settings.leftMargin),
    rightMarginMm: nonNegative(settings.rightMargin),
    topMarginMm: nonNegative(settings.topMargin),
    leftPushMm: signed(settings.leftPush),
    topPushMm: signed(settings.topPush),
    lineSpacingPercent: spacing,
    extraAreaMm: nonNegative(settings.extraArea),
    orientation: settings.orientation == 'vertical'
        ? LabelPrintOrientation.vertical
        : LabelPrintOrientation.horizontal,
  );
}

Future<void> saveLabelPrintSettingsSnapshot(
  LabelPrintSettingsSnapshot settings,
) => LabelPrinterPreferences.savePreferredPrintSettings(
  LabelSheetPreferredPrintSettings(
    printerName: settings.printerName ?? '',
    leftMargin: '${settings.leftMarginMm}',
    rightMargin: '${settings.rightMarginMm}',
    topMargin: '${settings.topMarginMm}',
    leftPush: '${settings.leftPushMm}',
    topPush: '${settings.topPushMm}',
    autoSpacing: settings.lineSpacingPercent == null
        ? 'none'
        : '${settings.lineSpacingPercent}',
    extraArea: '${settings.extraAreaMm}',
    orientation: settings.orientation == LabelPrintOrientation.vertical
        ? 'vertical'
        : 'horizontal',
  ),
);