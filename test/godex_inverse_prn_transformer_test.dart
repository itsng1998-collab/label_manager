import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/godex_inverse_prn_transformer.dart';
import 'package:label_manager/printing/godex_pcl4_bitmap_font.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LabelSheetWindowsTextDescriptor descriptor({
    int left = 4,
    int right = 28,
    int secondRunLeft = 24,
  }) => LabelSheetWindowsTextDescriptor(
    candidateToken: 'text:0:0',
    text: 'A  B',
    left: left,
    top: 4,
    right: right,
    bottom: 18,
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
    predictedPaintedFootprint: const ui.Rect.fromLTWH(4, 4, 24, 14),
    firmwareInverseRuns: <LabelSheetWindowsFirmwareTextRun>[
      const LabelSheetWindowsFirmwareTextRun(text: 'A', left: 4, top: 4),
      LabelSheetWindowsFirmwareTextRun(text: 'B', left: secondRunLeft, top: 4),
    ],
  );

  Uint8List samplePrn() {
    final payload = Uint8List(4 * 20);
    for (var row = 2; row < 19; row += 1) {
      payload[row * 4] = 0x3f;
      payload[row * 4 + 1] = 0xff;
      payload[row * 4 + 2] = 0xff;
      payload[row * 4 + 3] = 0xfc;
    }
    payload[4 * 4 + 1] &= 0xf7;
    payload[18 * 4 + 3] &= 0xfb;
    return Uint8List.fromList(<int>[
      ...ascii.encode('^P1\r\n^L\r\nQ0,0,4,20\r'),
      ...payload,
      ...ascii.encode('\r\nE\r\n'),
    ]);
  }

  Future<Pcl4BitmapGlyph> rasterize({
    required String text,
    required int characterCode,
    required String fontFamily,
    required double fontPixelHeight,
    required bool bold,
    required bool italic,
    int? maximumWidth,
  }) async {
    expect(fontFamily, 'Gulim');
    expect(fontPixelHeight, 16);
    expect(bold, isTrue);
    expect(italic, isFalse);
    final width = text == 'A' ? 8 : 4;
    expect(maximumWidth, greaterThanOrEqualTo(width));
    final raster = text == 'A'
        ? Uint8List.fromList(<int>[0x81, 0x42, 0x24])
        : Uint8List.fromList(<int>[0x90, 0x90, 0x90]);
    return Pcl4BitmapGlyph(
      characterCode: characterCode,
      width: width,
      height: 3,
      advance: width,
      raster: raster,
    );
  }

  test('clears only glyph pixels and emits inverse soft-font runs', () async {
    final result = await transformGodexInverseDriverPrn(
      prnBytes: samplePrn(),
      sourceWidth: 32,
      sourceHeight: 20,
      targetWidth: 32,
      targetHeight: 20,
      textDescriptors: <LabelSheetWindowsTextDescriptor>[descriptor()],
      glyphRasterizer: rasterize,
    );

    expect(result.inverseDescriptors, 1);
    expect(result.nativeRuns, 2);
    expect(result.restoredWhitePixels, 2);
    expect(result.clearedPixels, 12);
    final qHeader = ascii.encode('Q0,0,4,20\r');
    final qOffset = _indexOf(result.bytes, qHeader) + qHeader.length;
    for (var row = 0; row < 20; row += 1) {
      final expected = switch (row) {
        0 || 1 || 19 => <int>[0, 0, 0, 0],
        4 => <int>[0x37, 0xef, 0xff, 0x6c],
        5 => <int>[0x3b, 0xdf, 0xff, 0x6c],
        6 => <int>[0x3d, 0xbf, 0xff, 0x6c],
        _ => <int>[0x3f, 0xff, 0xff, 0xfc],
      };
      expect(
        result.bytes.sublist(qOffset + row * 4, qOffset + row * 4 + 4),
        expected,
      );
    }
    final payload = latin1.decode(result.bytes);
    expect(payload, startsWith('~MDELE,A\r\n~JA\r\n'));
    expect(payload, contains('^H08\r\n^L\r\n'));
    expect(payload, contains('VA,4,4,1,1,0,0I,!\r\n'));
    expect(payload, contains('VA,24,4,1,1,0,0I,"\r\n'));
    expect(payload, isNot(contains('AZ1,')));
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
        sourceHeight: 20,
        targetWidth: 32,
        targetHeight: 20,
        textDescriptors: <LabelSheetWindowsTextDescriptor>[
          descriptor(right: 40, secondRunLeft: 32),
        ],
        glyphRasterizer: rasterize,
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
