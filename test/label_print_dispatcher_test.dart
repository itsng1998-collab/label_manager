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

  test('backend maps every physical printer to the Windows legacy driver', () {
    for (final port in ['USB001', null]) {
      expect(
        resolveLabelPrintBackend(portName: port),
        LabelPrintBackend.windowsDriver,
      );
    }
    for (final port in [' FILE: ', 'portprompt:']) {
      expect(
        resolveLabelPrintBackend(portName: port),
        LabelPrintBackend.pdf,
      );
    }
  });

  test('legacy printer names map to the original driver profiles', () {
    LegacyPrinterType type(String name) => detectPrinterProfile(
      Printer(url: name, name: name),
    ).legacyType;

    expect(type('Godex G500'), LegacyPrinterType.godex);
    expect(type('ZDesigner ZD421'), LegacyPrinterType.zebra);
    expect(type('BIXOLON SLP-DX420'), LegacyPrinterType.bixolon);
    expect(type('Citizen CL-S700'), LegacyPrinterType.citizen);
    expect(type('CLP-7201E'), LegacyPrinterType.citizen);
    expect(type('Generic Label Printer'), LegacyPrinterType.other);
  });

  test('Windows driver output stays separate from PDF virtual printers', () {
    expect(LabelPrintBackend.windowsDriver.usesCanvasCapture, isTrue);
    expect(LabelPrintBackend.pdf.usesCanvasCapture, isTrue);
    expect(
      labelPrintRenderDpi(
        backend: LabelPrintBackend.windowsDriver,
        printerDpi: 203.2,
      ),
      203.2,
    );
    expect(
      labelPrintRenderDpi(
        backend: LabelPrintBackend.pdf,
        printerDpi: 300,
      ),
      300,
    );
  });

  test('Windows driver dispatch does not call PDF sender', () async {
    var pdfCalls = 0;
    var windowsCalls = 0;
    final dispatcher = LabelPrintDispatcher(
      sendPdf: (_) async {
        pdfCalls += 1;
        return true;
      },
      sendWindowsDriver: (_) async {
        windowsCalls += 1;
        return true;
      },
    );

    final accepted = await dispatcher.dispatch(
      backend: LabelPrintBackend.windowsDriver,
      pdfBytes: Uint8List(1),
    );

    expect(accepted, isTrue);
    expect(windowsCalls, 1);
    expect(pdfCalls, 0);
  });
}