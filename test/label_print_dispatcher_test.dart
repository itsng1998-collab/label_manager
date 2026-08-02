import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:printing/printing.dart';

void main() {
  test('Godex G500 uses exact eight dots per millimeter', () {
    final profile = detectPrinterProfile(
      const Printer(url: 'Godex G500', name: 'Godex G500'),
    );

    expect(profile.dpi, 203.2);
    expect(resolveLabelPrinterDpi(profile: profile, deviceDpi: 203), 203.2);
    expect((80 * resolveLabelPrinterDpi(profile: profile) / 25.4).round(), 640);
  });

  test('other printers keep the device-reported DPI', () {
    final profile = detectPrinterProfile(
      const Printer(url: 'Office Printer', name: 'Office Printer'),
    );

    expect(resolveLabelPrinterDpi(profile: profile, deviceDpi: 300), 300);
  });

  test('backend resolves only EZPL non-file ports to raw', () {
    expect(
      resolveLabelPrintBackend(
        language: PrinterLanguage.ezpl,
        portName: 'USB001',
      ),
      LabelPrintBackend.ezplRaw,
    );
    expect(
      resolveLabelPrintBackend(
        language: PrinterLanguage.ezpl,
        portName: null,
      ),
      LabelPrintBackend.ezplRaw,
    );
    for (final value in [
      (PrinterLanguage.ezpl, ' FILE: '),
      (PrinterLanguage.ezpl, 'portprompt:'),
      (PrinterLanguage.zpl, 'USB001'),
      (PrinterLanguage.tspl, null),
      (PrinterLanguage.cpcl, null),
      (PrinterLanguage.rasterOnly, null),
    ]) {
      expect(
        resolveLabelPrintBackend(language: value.$1, portName: value.$2),
        LabelPrintBackend.pdf,
      );
    }
  });

  test('raw failure is propagated without PDF fallback', () async {
    var rawCalls = 0;
    var pdfCalls = 0;
    final dispatcher = LabelPrintDispatcher(
      sendPdf: (_) async {
        pdfCalls += 1;
        return true;
      },
      sendRaw: (_) async {
        rawCalls += 1;
        throw StateError('raw failed');
      },
    );

    await expectLater(
      dispatcher.dispatch(
        backend: LabelPrintBackend.ezplRaw,
        pdfBytes: Uint8List(1),
        rawBytes: Uint8List(1),
      ),
      throwsStateError,
    );
    expect(rawCalls, 1);
    expect(pdfCalls, 0);
  });
}