import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/printing/windows_bitmap_printer.dart';
import 'package:printing/printing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('label_manager/bitmap_print');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory captureDirectory;
  final driverBytes = Uint8List.fromList([94, 67, 49, 13, 69, 13]);
  var rawCalls = 0;
  setUp(() async {
    captureDirectory = await Directory.systemTemp.createTemp('bitmap_request_');
    WindowsBitmapPrinter.debugCaptureDirectory = captureDirectory;
    rawCalls = 0;
    WindowsBitmapPrinter.rawSender = (printer, bytes) async {
      rawCalls++;
      expect(printer.name, 'Godex G500');
      expect(bytes, driverBytes);
      return RawPrinterWriteResult(jobId: 1,
          requestedBytes: bytes.length, writtenBytes: bytes.length);
    };
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    WindowsBitmapPrinter.debugCaptureDirectory = null;
    WindowsBitmapPrinter.rawSender = RawPrinterWin32.sendRaw;
    await captureDirectory.delete(recursive: true);
  });

  Future<WindowsBitmapPrintResult> printSample({
    LegacyPrinterType type = LegacyPrinterType.godex,
  }) => WindowsBitmapPrinter.print(
    printer: const Printer(url: 'test', name: 'Godex G500'),
    documentName: 'file-capture-contract',
    bgraBytes: Uint8List.fromList([255, 255, 255, 255]),
    sourceWidth: 1,
    sourceHeight: 1,
    pageWidthMm: 80,
    pageHeightMm: 60,
    copies: 1,
    widthAppendMm: 0,
    legacyPrinterType: type,
  );

  test('file-only capture cannot become an accepted print', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'renderBitmapToPrn');
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
    expect(rawCalls, 0);
  }, skip: !Platform.isWindows);

  test('GoDEX submits driver PRN unchanged and only then accepts print', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true,
      'diagnostics': 'normal-driver-output',
      'prnBytes': driverBytes,
    });
    final result = await printSample();
    expect(result.accepted, isTrue);
    expect(result.diagnostics, contains('driverTransport=generatedPrnRaw'));
    expect(rawCalls, 1);
    final files = await captureDirectory.list().where((entry) => entry.path.endsWith('.prn')).toList();
    expect(files, hasLength(1));
    expect(await File(files.single.path).readAsBytes(), driverBytes);
  }, skip: !Platform.isWindows);

  test('capture preserves the exact channel request before dispatch', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final files = await captureDirectory.list().where((entry) => entry is File).toList();
      expect(files, hasLength(1));
      final bytes = await File(files.single.path).readAsBytes();
      final capture = const StandardMessageCodec().decodeMessage(
        ByteData.sublistView(bytes),
      ) as Map;
      expect(capture['schemaVersion'], 1);
      expect(capture['arguments'], call.arguments);
      expect((capture['arguments'] as Map)['bgra'], isA<Uint8List>());
      return <String, Object>{'ok': true, 'diagnostics': 'captured', 'prnBytes': driverBytes};
    });
    await printSample();
  }, skip: !Platform.isWindows);

  test('replay preserves binary and nested descriptors and uses file-only method', () async {
    final arguments = <String, Object?>{
      'bgra': Uint8List.fromList([0, 255, 128, 255]),
      'sourceWidth': 1,
      'sourceHeight': 1,
      'copies': 1,
      'textDescriptors': [
        {'text': '역상\n둘째줄', 'bold': true, 'left': 15, 'color': 0xffffff},
      ],
      'borderDescriptors': [
        {'thicknessDots': 1, 'horizontal': true},
      ],
    };
    final data = const StandardMessageCodec().encodeMessage({
      'schemaVersion': 1, 'arguments': arguments,
    })!;
    final file = File('${captureDirectory.path}/replay.bin');
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'replayBitmapToFile');
      expect(call.arguments, arguments);
      return <String, Object>{
        'ok': false,
        'diagnostics': 'debugFileCaptured=true physicalPrintSubmitted=false',
      };
    });
    expect(await WindowsBitmapPrinter.replayDebugRequest(file),
        contains('physicalPrintSubmitted=false'));
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true, 'diagnostics': 'normal-driver-output',
    });
    await expectLater(WindowsBitmapPrinter.replayDebugRequest(file), throwsStateError);
  }, skip: !Platform.isWindows);

  test('unsupported capture never invokes the print channel', () async {
    var invoked = false;
    messenger.setMockMethodCallHandler(channel, (_) async {
      invoked = true;
      return null;
    });
    final data = const StandardMessageCodec().encodeMessage({'schemaVersion': 2})!;
    final file = File('${captureDirectory.path}/unsupported.bin');
    await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    await expectLater(WindowsBitmapPrinter.replayDebugRequest(file), throwsFormatException);
    expect(invoked, isFalse);
  }, skip: !Platform.isWindows);

  test('capture filesystem failure does not change native print result', () async {
    final blocker = File('${captureDirectory.path}/not_a_directory');
    await blocker.writeAsString('test');
    WindowsBitmapPrinter.debugCaptureDirectory = Directory(blocker.path);
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true, 'diagnostics': 'normal-driver-output',
      'prnBytes': driverBytes,
    });
    expect((await printSample()).accepted, isTrue);
  }, skip: !Platform.isWindows);

  test('missing PRN and RAW failure never become accepted prints', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true, 'diagnostics': 'rendered',
    });
    await expectLater(printSample(), throwsStateError);
    expect(rawCalls, 0);
    messenger.setMockMethodCallHandler(channel, (_) async => <String, Object>{
      'ok': true, 'diagnostics': 'rendered', 'prnBytes': driverBytes,
    });
    WindowsBitmapPrinter.rawSender = (printer, bytes) async => throw StateError('write failed');
    await expectLater(printSample(), throwsStateError);
    WindowsBitmapPrinter.rawSender = (_, bytes) async => RawPrinterWriteResult(
      jobId: 2, requestedBytes: bytes.length, writtenBytes: bytes.length - 1,
    );
    await expectLater(printSample(), throwsStateError);
  }, skip: !Platform.isWindows);

  test('other vendors retain direct GDI submission', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'printBitmap');
      return <String, Object>{'ok': true, 'diagnostics': 'direct'};
    });
    expect((await printSample(type: LegacyPrinterType.bixolon)).accepted, isTrue);
    expect(rawCalls, 0);
  }, skip: !Platform.isWindows);
}