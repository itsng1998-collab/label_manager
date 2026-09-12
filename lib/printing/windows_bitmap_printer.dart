import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
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

  @visibleForTesting
  static Directory? debugCaptureDirectory;
  @visibleForTesting
  static Future<RawPrinterWriteResult> Function(Printer, Uint8List) rawSender =
      RawPrinterWin32.sendRaw;
  static int _captureSequence = 0;

  static Future<File?> _captureDebugRequest(Map<String, Object?> arguments) async {
    final directory = debugCaptureDirectory ??
        Directory('.tmp/log/bitmap_print_requests');
    try {
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}/v1.3.127_${DateTime.now().microsecondsSinceEpoch}'
        '_${_captureSequence++}.bin',
      );
      final data = const StandardMessageCodec().encodeMessage({
        'schemaVersion': 1,
        'arguments': arguments,
      })!;
      await file.writeAsBytes(data.buffer.asUint8List(
        data.offsetInBytes, data.lengthInBytes,
      ), flush: true);
      debugPrint('bitmapRequestCaptureVersion=1.3.127 '
          'requestFile=${file.path} notActualSpoolCapture=true');
      return file;
    } on FileSystemException catch (error) {
      debugPrint('bitmapRequestCaptureFailed=${error.message}');
      return null;
    }
  }

  static Future<String> replayDebugRequest(File requestFile) async {
    if (!kDebugMode || !Platform.isWindows) {
      throw UnsupportedError('Request replay requires a Windows Debug build.');
    }
    final bytes = await requestFile.readAsBytes();
    final capture = const StandardMessageCodec().decodeMessage(
      ByteData.sublistView(bytes),
    );
    if (capture is! Map || capture['schemaVersion'] != 1 ||
        capture['arguments'] is! Map) {
      throw const FormatException('Unsupported bitmap print request capture.');
    }
    final result = await _channel.invokeMapMethod<String, Object?>(
      'replayBitmapToFile', capture['arguments'],
    );
    final diagnostics = result?['diagnostics']?.toString() ?? '';
    if (result?['ok'] != false ||
        !diagnostics.contains('debugFileCaptured=true')) {
      throw StateError('File-only request replay failed: '
          '${result?['error'] ?? 'invalid result'} $diagnostics');
    }
    return diagnostics;
  }

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
    final arguments = <String, Object?>{
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
      };
    final requestCapture = kDebugMode ? await _captureDebugRequest(arguments) : null;
    final useDriverPrn = legacyPrinterType == LegacyPrinterType.godex;
    final result = await _channel.invokeMapMethod<String, Object?>(
      useDriverPrn ? 'renderBitmapToPrn' : 'printBitmap', arguments,
    );
    if (result == null) {
      throw StateError('Windows bitmap printer returned no result.');
    }
    var diagnostics = result['diagnostics']?.toString() ?? '';
    final accepted = result['ok'] == true;
    if (!accepted) {
      throw StateError(
        'Windows bitmap print failed: ${result['error'] ?? 'unknown error'} '
        '$diagnostics',
      );
    }
    if (useDriverPrn) {
      final bytes = result['prnBytes'];
      if (bytes is! Uint8List || bytes.isEmpty) {
        throw StateError('GoDEX driver returned no PRN data.');
      }
      if (requestCapture != null) {
        try {
          final file = File('${requestCapture.path}.prn');
          await file.writeAsBytes(bytes, flush: true);
          debugPrint('driverPrnVersion=1.3.129 driverPrnFile=${file.path}');
        } on FileSystemException catch (error) {
          debugPrint('driverPrnCaptureFailed=${error.message}');
        }
      }
      final submitted = await rawSender(printer, bytes);
      if (submitted.writtenBytes != bytes.length) {
        throw StateError('GoDEX driver PRN was not completely submitted.');
      }
      diagnostics = '$diagnostics driverTransport=generatedPrnRaw '
          'driverTransportVersion=1.3.129 ${submitted.diagnostics} '
          'physicalPrintSubmitted=true';
    }
    return WindowsBitmapPrintResult(
      accepted: true,
      diagnostics: diagnostics,
    );
  }
}
