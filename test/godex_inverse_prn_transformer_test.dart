import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/godex_inverse_prn_transformer.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const charsetChannel = MethodChannel('charset_converter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(charsetChannel, (call) async {
          expect(call.method, 'encode');
          final arguments = call.arguments as Map<Object?, Object?>;
          expect(arguments['charset'], '949');
          return ascii.encode(arguments['data']! as String);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(charsetChannel, null);
  });

  LabelSheetWindowsTextDescriptor descriptor({
    int left = 0,
    int right = 32,
    int secondRunLeft = 24,
  }) => LabelSheetWindowsTextDescriptor(
    candidateToken: 'text:0:0',
    text: 'A  B',
    left: left,
    top: 0,
    right: right,
    bottom: 16,
    fontFamily: 'Gulim',
    fontPixelHeight: 16,
    bold: true,
    italic: false,
    underline: false,
    strikeThrough: false,
    colorArgb: 0xffffffff,
    horizontalAlign: '1',
    verticalAlign: '1',
    wrap: false,
    predictedPaintedFootprint: const ui.Rect.fromLTWH(0, 0, 32, 16),
    firmwareInverseRuns: <LabelSheetWindowsFirmwareTextRun>[
      const LabelSheetWindowsFirmwareTextRun(text: 'A', left: 0, top: 0),
      LabelSheetWindowsFirmwareTextRun(text: 'B', left: secondRunLeft, top: 0),
    ],
  );

  Uint8List samplePrn() => Uint8List.fromList(<int>[
    ...ascii.encode('^P1\r\n^L\r\nQ0,0,4,16\r'),
    ...List<int>.filled(4 * 16, 0xff),
    ...ascii.encode('\r\nE\r\n'),
  ]);

  test('clears inverse clip and emits low-darkness AZ1 runs', () async {
    final result = await transformGodexInverseDriverPrn(
      prnBytes: samplePrn(),
      sourceWidth: 32,
      sourceHeight: 16,
      targetWidth: 32,
      targetHeight: 16,
      textDescriptors: <LabelSheetWindowsTextDescriptor>[descriptor()],
    );

    expect(result.inverseDescriptors, 1);
    expect(result.nativeRuns, 2);
    expect(result.clearedPixels, 16 * 16);
    final qHeader = ascii.encode('Q0,0,4,16\r');
    final qOffset = _indexOf(result.bytes, qHeader) + qHeader.length;
    for (var row = 0; row < 16; row += 1) {
      expect(
        result.bytes.sublist(qOffset + row * 4, qOffset + row * 4 + 4),
        <int>[0, 0xff, 0xff, 0],
      );
    }
    final payload = latin1.decode(result.bytes);
    expect(payload, contains('^H04\r\n^L\r\n'));
    expect(payload, contains('AZ1,0,0,1,1,0,0I,A\r\n'));
    expect(payload, contains('AZ1,24,0,1,1,0,0I,B\r\n'));
    expect(payload, endsWith('E\r\n^H08\r\n'));
  });

  test('returns driver bytes unchanged without inverse descriptors', () async {
    final bytes = samplePrn();
    final result = await transformGodexInverseDriverPrn(
      prnBytes: bytes,
      sourceWidth: 32,
      sourceHeight: 16,
      targetWidth: 0,
      targetHeight: 0,
      textDescriptors: const <LabelSheetWindowsTextDescriptor>[],
    );
    expect(result.transformed, isFalse);
    expect(result.bytes, same(bytes));
  });

  test('rejects an inverse run outside the driver Q pattern', () async {
    await expectLater(
      transformGodexInverseDriverPrn(
        prnBytes: samplePrn(),
        sourceWidth: 32,
        sourceHeight: 16,
        targetWidth: 32,
        targetHeight: 16,
        textDescriptors: <LabelSheetWindowsTextDescriptor>[
          descriptor(right: 40, secondRunLeft: 32),
        ],
      ),
      throwsFormatException,
    );
  });
}

int _indexOf(Uint8List bytes, List<int> pattern) {
  for (var index = 0; index <= bytes.length - pattern.length; index += 1) {
    var matches = true;
    for (var offset = 0; offset < pattern.length; offset += 1) {
      if (bytes[index + offset] != pattern[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return index;
  }
  return -1;
}
