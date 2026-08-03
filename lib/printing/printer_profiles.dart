import 'package:printing/printing.dart';

enum LegacyPrinterType { godex, zebra, bixolon, citizen, other }

class PrinterProfile {
  final String vendor;
  final String model;
  final double? dpi; // known default DPI if available
  final double? defaultWidthMm;
  final double? defaultHeightMm;
  final LegacyPrinterType legacyType;

  const PrinterProfile({
    required this.vendor,
    required this.model,
    this.dpi,
    this.defaultWidthMm,
    this.defaultHeightMm,
    this.legacyType = LegacyPrinterType.other,
  });

  @override
  String toString() =>
      'PrinterProfile(vendor=$vendor, model=$model, legacy=${legacyType.name}, dpi=$dpi, ${defaultWidthMm}x${defaultHeightMm}mm)';
}

double resolveLabelPrinterDpi({
  required PrinterProfile profile,
  int? deviceDpi,
}) {
  if (profile.vendor == 'GoDEX' && profile.model == 'G500') {
    return 203.2;
  }
  return deviceDpi?.toDouble() ?? profile.dpi ?? 203;
}

/// Best-effort detection based on the available fields in [Printer].
/// This is string-matching and can be extended in the future for new models.
PrinterProfile detectPrinterProfile(Printer? printer) {
  final String name = (printer?.name ?? '').toUpperCase();
  final String location = (printer?.location ?? '').toUpperCase();
  final String url = (printer?.url ?? '').toUpperCase();
  final String signature = '$name $location $url';

  // Godex G500: 203.2dpi, 80x60mm default
  if (signature.contains('GODEX G500') || signature.contains('G500')) {
    return const PrinterProfile(
      vendor: 'GoDEX',
      model: 'G500',
      dpi: 203.2,
      defaultWidthMm: 80.0,
      defaultHeightMm: 60.0,
      legacyType: LegacyPrinterType.godex,
    );
  }
  if (signature.contains('GODEX')) {
    return const PrinterProfile(
      vendor: 'GoDEX',
      model: 'Unknown',
      dpi: 203,
      legacyType: LegacyPrinterType.godex,
    );
  }

  if (signature.contains('ZEBRA') ||
      signature.contains('ZDESIGNER') ||
      signature.contains('ZPL')) {
    return const PrinterProfile(
      vendor: 'Zebra',
      model: 'Unknown',
      legacyType: LegacyPrinterType.zebra,
    );
  }
  if (signature.contains('BIXOLON')) {
    return const PrinterProfile(
      vendor: 'BIXOLON',
      model: 'Unknown',
      legacyType: LegacyPrinterType.bixolon,
    );
  }
  if (signature.contains('CITIZEN') ||
      signature.contains('CLP-7201E') ||
      signature.contains('CL-S700')) {
    return const PrinterProfile(
      vendor: 'CITIZEN',
      model: 'Unknown',
      legacyType: LegacyPrinterType.citizen,
    );
  }
  return const PrinterProfile(
    vendor: 'Unknown',
    model: 'Unknown',
  );
}
