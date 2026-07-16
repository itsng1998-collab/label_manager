import 'dart:typed_data';

import 'package:label_manager/printing/printer_profiles.dart';

enum LabelPrintBackend { pdf, ezplRaw }

LabelPrintBackend resolveLabelPrintBackend({
  required PrinterLanguage language,
  required String? portName,
}) {
  final normalizedPort = portName?.trim().toUpperCase();
  final isFilePort = normalizedPort == 'FILE:' || normalizedPort == 'PORTPROMPT:';
  return language == PrinterLanguage.ezpl && !isFilePort
      ? LabelPrintBackend.ezplRaw
      : LabelPrintBackend.pdf;
}

typedef LabelPrintBytesSender = Future<bool> Function(Uint8List bytes);

class LabelPrintDispatcher {
  const LabelPrintDispatcher({
    required this.sendPdf,
    required this.sendRaw,
  });

  final LabelPrintBytesSender sendPdf;
  final LabelPrintBytesSender sendRaw;

  Future<bool> dispatch({
    required LabelPrintBackend backend,
    required Uint8List pdfBytes,
    required Uint8List rawBytes,
  }) {
    return switch (backend) {
      LabelPrintBackend.pdf => sendPdf(pdfBytes),
      LabelPrintBackend.ezplRaw => sendRaw(rawBytes),
    };
  }
}