import 'dart:typed_data';

import 'package:label_manager/printing/printer_profiles.dart';

enum LabelPrintBackend { pdf, windowsDriver, ezplRaw }

extension LabelPrintBackendCapture on LabelPrintBackend {
  bool get usesCanvasCapture =>
      this == LabelPrintBackend.pdf || this == LabelPrintBackend.windowsDriver;
}

LabelPrintBackend resolveLabelPrintBackend({
  required PrinterLanguage language,
  required String? portName,
  bool preferWindowsDriver = false,
}) {
  final normalizedPort = portName?.trim().toUpperCase();
  final isFilePort = normalizedPort == 'FILE:' || normalizedPort == 'PORTPROMPT:';
  if (language == PrinterLanguage.ezpl && !isFilePort) {
    return preferWindowsDriver
        ? LabelPrintBackend.windowsDriver
        : LabelPrintBackend.ezplRaw;
  }
  return LabelPrintBackend.pdf;
}

typedef LabelPrintBytesSender = Future<bool> Function(Uint8List bytes);

class LabelPrintDispatcher {
  const LabelPrintDispatcher({
    required this.sendPdf,
    required this.sendWindowsDriver,
    required this.sendRaw,
  });

  final LabelPrintBytesSender sendPdf;
  final LabelPrintBytesSender sendWindowsDriver;
  final LabelPrintBytesSender sendRaw;

  Future<bool> dispatch({
    required LabelPrintBackend backend,
    required Uint8List pdfBytes,
    required Uint8List rawBytes,
  }) {
    return switch (backend) {
      LabelPrintBackend.pdf => sendPdf(pdfBytes),
      LabelPrintBackend.windowsDriver => sendWindowsDriver(pdfBytes),
      LabelPrintBackend.ezplRaw => sendRaw(rawBytes),
    };
  }
}

double labelPrintRenderDpi({
  required LabelPrintBackend backend,
  required double printerDpi,
}) => printerDpi;