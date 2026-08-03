import 'dart:typed_data';

enum LabelPrintBackend { pdf, windowsDriver }

extension LabelPrintBackendCapture on LabelPrintBackend {
  bool get usesCanvasCapture =>
      this == LabelPrintBackend.pdf || this == LabelPrintBackend.windowsDriver;
}

LabelPrintBackend resolveLabelPrintBackend({
  required String? portName,
}) {
  final normalizedPort = portName?.trim().toUpperCase();
  final isFilePort = normalizedPort == 'FILE:' || normalizedPort == 'PORTPROMPT:';
  return isFilePort ? LabelPrintBackend.pdf : LabelPrintBackend.windowsDriver;
}

typedef LabelPrintBytesSender = Future<bool> Function(Uint8List bytes);

class LabelPrintDispatcher {
  const LabelPrintDispatcher({
    required this.sendPdf,
    required this.sendWindowsDriver,
  });

  final LabelPrintBytesSender sendPdf;
  final LabelPrintBytesSender sendWindowsDriver;

  Future<bool> dispatch({
    required LabelPrintBackend backend,
    required Uint8List pdfBytes,
  }) {
    return switch (backend) {
      LabelPrintBackend.pdf => sendPdf(pdfBytes),
      LabelPrintBackend.windowsDriver => sendWindowsDriver(pdfBytes),
    };
  }
}

double labelPrintRenderDpi({
  required LabelPrintBackend backend,
  required double printerDpi,
}) => printerDpi;