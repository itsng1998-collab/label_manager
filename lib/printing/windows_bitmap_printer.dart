import 'dart:io';

import 'package:flutter/services.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:printing/printing.dart';

class WindowsBitmapPrintResult {
  const WindowsBitmapPrintResult({
    required this.accepted,
    required this.diagnostics,
  });

  final bool accepted;
  final String diagnostics;
}

class WindowsBitmapPrinter {
  const WindowsBitmapPrinter._();

  static const MethodChannel _channel = MethodChannel(
    'label_manager/bitmap_print',
  );

  static Future<WindowsBitmapPrintResult> print({
    required Printer printer,
    required String documentName,
    required Uint8List bgraBytes,
    required int sourceWidth,
    required int sourceHeight,
    required double pageWidthMm,
    required double pageHeightMm,
    required int copies,
    required double widthAppendMm,
    required LegacyPrinterType legacyPrinterType,
    List<LabelSheetWindowsTextDescriptor> textDescriptors = const [],
    List<LabelSheetWindowsBorderDescriptor> borderDescriptors = const [],
  }) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows bitmap printing is only supported on Windows.');
    }
    final result = await _channel.invokeMapMethod<String, Object?>(
      'printBitmap',
      <String, Object?>{
        'printerName': printer.name,
        'documentName': documentName,
        'bgra': bgraBytes,
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
        'pageWidthMm': pageWidthMm,
        'pageHeightMm': pageHeightMm,
        'copies': copies,
        'widthAppendMm': widthAppendMm,
        'legacyPrinterType': legacyPrinterType.name,
        'textDescriptors': [
          for (final descriptor in textDescriptors) descriptor.toChannelMap(),
        ],
        'borderDescriptors': [
          for (final descriptor in borderDescriptors)
            descriptor.toChannelMap(),
        ],
      },
    );
    if (result == null) {
      throw StateError('Windows bitmap printer returned no result.');
    }
    final diagnostics = result['diagnostics']?.toString() ?? '';
    final accepted = result['ok'] == true;
    if (!accepted) {
      throw StateError(
        'Windows bitmap print failed: ${result['error'] ?? 'unknown error'} '
        '$diagnostics',
      );
    }
    return WindowsBitmapPrintResult(
      accepted: true,
      diagnostics: diagnostics,
    );
  }
}
