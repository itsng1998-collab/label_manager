import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/windows_bitmap_printer.dart';
import 'package:printing/printing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('label_manager/bitmap_print');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<WindowsBitmapPrintResult> printSample() => WindowsBitmapPrinter.print(
    printer: const Printer(url: 'test', name: 'Godex G500'),
    documentName: 'file-capture-contract',
    bgraBytes: Uint8List.fromList([255, 255, 255, 255]),
    sourceWidth: 1,
    sourceHeight: 1,
    pageWidthMm: 80,
    pageHeightMm: 60,
    copies: 1,
    widthAppendMm: 0,
    legacyPrinterType: LegacyPrinterType.godex,
  );

  test('file-only capture cannot become an accepted print', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'printBitmap');
      return <String, Object>{
        'ok': false,
        'diagnostics': 'debugFileCaptured=true physicalPrintSubmitted=false',
        'error': 'Debug print file captured; no physical print was submitted.',
      };
    });
    await expectLater(
      printSample(),
      throwsA(isA<StateError>().having(
        (error) => error.message,
        'message',
        contains('debugFileCaptured=true'),
      )),
    );
  }, skip: !Platform.isWindows);

  test('normal native success remains accepted', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true,
      'diagnostics': 'normal-driver-output',
    });
    final result = await printSample();
    expect(result.accepted, isTrue);
    expect(result.diagnostics, 'normal-driver-output');
  }, skip: !Platform.isWindows);
}