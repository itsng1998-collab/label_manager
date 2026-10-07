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
    int secondRunLeft = 27,
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
    payload[10 * 4] &= 0xdf;
    payload[18 * 4 + 3] &= 0xf7;
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

  for (final driverHeat in ['', '^H08\r\n', '^H14\r\n']) {
    test('preserves driver heat and speed commands ${driverHeat.trim()}', () async {
      final driverBytes = Uint8List.fromList([
        ...ascii.encode('$driverHeat^S3\r\n'),
        ...samplePrn(),
      ]);
      final result = await transformGodexInverseDriverPrn(
        prnBytes: driverBytes,
        sourceWidth: 32,
        sourceHeight: 20,
        targetWidth: 32,
        targetHeight: 20,
        textDescriptors: [descriptor()],
        glyphRasterizer: rasterize,
      );
      final payload = latin1.decode(result.bytes);
      expect(payload, contains('$driverHeat^S3\r\n^P1\r\n^L\r\n'));
      expect(
        RegExp(r'\^H\d+').allMatches(payload).map((match) => match.group(0)),
        driverHeat.isEmpty ? isEmpty : [driverHeat.trim()],
      );
      expect(payload, endsWith('E\r\n'));
      expect(result.inverseDescriptors, 1);
      expect(result.nativeRuns, 2);
    });
  }

  test(
    'precomposes inverse XOR cells without changing nearby content',
    () async {
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
      expect(result.clearedPixels, 48);
      expect(result.compensatedPixels, 5);
      final qHeader = ascii.encode('Q0,0,4,20\r');
      final qOffset = _indexOf(result.bytes, qHeader) + qHeader.length;
      for (var row = 0; row < 20; row += 1) {
        final expected = switch (row) {
          0 || 1 || 19 => <int>[0, 0, 0, 0],
          4 || 5 || 6 => <int>[0x30, 0x07, 0xff, 0xe1],
          7 => <int>[0x30, 0x07, 0xff, 0xe3],
          10 => <int>[0x1f, 0xff, 0xff, 0xfc],
          _ => <int>[0x3f, 0xff, 0xff, 0xfc],
        };
        expect(
          result.bytes.sublist(qOffset + row * 4, qOffset + row * 4 + 4),
          expected,
        );
      }
      final composed = Uint8List.fromList(
        result.bytes.sublist(qOffset, qOffset + 4 * 20),
      );
      _xorInverseCell(
        composed,
        stride: 4,
        x: 4,
        y: 4,
        width: 8,
        height: 3,
        raster: Uint8List.fromList(<int>[0x81, 0x42, 0x24]),
      );
      _xorInverseCell(
        composed,
        stride: 4,
        x: 27,
        y: 4,
        width: 4,
        height: 3,
        raster: Uint8List.fromList(<int>[0x90, 0x90, 0x90]),
      );
      for (var row = 0; row < 20; row += 1) {
        final expected = switch (row) {
          0 || 1 || 19 => <int>[0, 0, 0, 0],
          4 => <int>[0x37, 0xef, 0xff, 0xec],
          5 => <int>[0x3b, 0xdf, 0xff, 0xec],
          6 => <int>[0x3d, 0xbf, 0xff, 0xec],
          10 => <int>[0x1f, 0xff, 0xff, 0xfc],
          _ => <int>[0x3f, 0xff, 0xff, 0xfc],
        };
        expect(composed.sublist(row * 4, row * 4 + 4), expected);
      }
      final payload = latin1.decode(result.bytes);
      expect(payload, startsWith('~MDELE,A\r\n~JA\r\n'));
      expect(payload, isNot(contains('^H08\r\n')));
      expect(payload, contains('VA,4,4,1,1,0,0I,!\r\n'));
      expect(payload, contains('VA,27,4,1,1,0,0I,"\r\n'));
      expect(payload, isNot(contains('AZ1,')));
      expect(payload, endsWith('E\r\n'));
    },
  );

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

  test(
    'reinforces small Malgun inverse runs whether already bold or not',
    () async {
      final boldArguments = <bool>[];
      final fontHeights = <double>[];
      Future<Pcl4BitmapGlyph> captureRasterize({
        required String text,
        required int characterCode,
        required String fontFamily,
        required double fontPixelHeight,
        required bool bold,
        required bool italic,
        int? maximumWidth,
      }) async {
        boldArguments.add(bold);
        fontHeights.add(fontPixelHeight);
        return Pcl4BitmapGlyph(
          characterCode: characterCode,
          width: 4,
          height: 3,
          advance: 4,
          raster: Uint8List.fromList(<int>[0x90, 0x90, 0x90]),
        );
      }

      final base = descriptor(right: 24, secondRunLeft: 16);
      LabelSheetWindowsTextDescriptor malgun({required bool bold}) =>
          LabelSheetWindowsTextDescriptor(
            candidateToken: base.candidateToken,
            text: base.text,
            left: base.left,
            top: base.top,
            right: base.right,
            bottom: base.bottom,
            fontFamily: '맑은 고딕',
            fontPixelHeight: 15,
            bold: bold,
            italic: base.italic,
            underline: base.underline,
            strikeThrough: base.strikeThrough,
            colorArgb: base.colorArgb,
            horizontalAlign: base.horizontalAlign,
            verticalAlign: base.verticalAlign,
            wrap: base.wrap,
            predictedPaintedFootprint: base.predictedPaintedFootprint,
            firmwareInverseRuns: base.firmwareInverseRuns,
          );

      final result = await transformGodexInverseDriverPrn(
        prnBytes: samplePrn(),
        sourceWidth: 32,
        sourceHeight: 20,
        targetWidth: 32,
        targetHeight: 20,
        textDescriptors: <LabelSheetWindowsTextDescriptor>[malgun(bold: false)],
        glyphRasterizer: captureRasterize,
      );
      final alreadyBoldResult = await transformGodexInverseDriverPrn(
        prnBytes: samplePrn(),
        sourceWidth: 32,
        sourceHeight: 20,
        targetWidth: 32,
        targetHeight: 20,
        textDescriptors: <LabelSheetWindowsTextDescriptor>[malgun(bold: true)],
        glyphRasterizer: captureRasterize,
      );

      expect(boldArguments, <bool>[true, true, true, true]);
      expect(fontHeights, <double>[20, 20, 20, 20]);
      expect(result.reinforcedRuns, 2);
      expect(alreadyBoldResult.reinforcedRuns, 2);
      expect(result.diagnostics, contains('reinforcedRuns=2'));
    },
  );

  test(
    'transforms the Q pattern containing inverse text when PRN is segmented',
    () async {
      final original = samplePrn();
      final qHeader = ascii.encode('Q0,0,4,20\r');
      final payloadOffset = _indexOf(original, qHeader) + qHeader.length;
      final payload = original.sublist(payloadOffset, payloadOffset + 4 * 20);
      final segmented = Uint8List.fromList(<int>[
        ...original.sublist(0, payloadOffset - qHeader.length),
        ...ascii.encode('Q0,0,4,2\r'),
        ...payload.sublist(0, 4 * 2),
        ...ascii.encode('\r\nQ0,2,4,18\r'),
        ...payload.sublist(4 * 2),
        ...original.sublist(payloadOffset + 4 * 20),
      ]);

      final result = await transformGodexInverseDriverPrn(
        prnBytes: segmented,
        sourceWidth: 32,
        sourceHeight: 20,
        targetWidth: 32,
        targetHeight: 20,
        textDescriptors: <LabelSheetWindowsTextDescriptor>[descriptor()],
        glyphRasterizer: rasterize,
      );

      expect(result.transformed, isTrue);
      expect(result.nativeRuns, 2);
      expect(latin1.decode(result.bytes), contains('Q0,0,4,2\r'));
      expect(latin1.decode(result.bytes), contains('Q0,2,4,18\r'));
    },
  );

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

void _xorInverseCell(
  Uint8List payload, {
  required int stride,
  required int x,
  required int y,
  required int width,
  required int height,
  required Uint8List raster,
}) {
  final glyphStride = (width + 7) ~/ 8;
  for (var targetY = y; targetY < y + height + 1; targetY += 1) {
    for (var targetX = x; targetX < x + width + 1; targetX += 1) {
      final glyphX = targetX - x;
      final glyphY = targetY - y;
      final glyphPixel =
          glyphX >= 0 &&
          glyphX < width &&
          glyphY >= 0 &&
          glyphY < height &&
          (raster[glyphY * glyphStride + glyphX ~/ 8] &
                  (0x80 >> (glyphX % 8))) !=
              0;
      if (glyphPixel) continue;
      payload[targetY * stride + targetX ~/ 8] ^= 0x80 >> (targetX % 8);
    }
  }
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
