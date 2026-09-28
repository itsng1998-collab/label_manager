import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/godex_pcl4_bitmap_font.dart';
import 'package:label_manager/printing/godex_text_glyph_rasterizer.dart';

void main() {
  test('builds a format 0 PCL bitmap font with big-endian glyph metrics', () {
    final bytes = buildPcl4BitmapSoftFont(
      fontName: 'LMINV001',
      cellWidth: 9,
      cellHeight: 3,
      glyphs: <Pcl4BitmapGlyph>[
        Pcl4BitmapGlyph(
          characterCode: 65,
          width: 9,
          height: 3,
          advance: 9,
          leftOffset: -1,
          topOffset: 2,
          raster: Uint8List.fromList(<int>[0x80, 0x00, 0x40, 0x00, 0x20, 0x00]),
        ),
      ],
    );

    final headerCommand = <int>[0x1b, ...ascii.encode(')s64W')];
    expect(bytes.sublist(0, headerCommand.length), headerCommand);
    final headerOffset = headerCommand.length;
    final header = ByteData.sublistView(bytes, headerOffset, headerOffset + 64);
    expect(header.getUint16(0, Endian.big), 64);
    expect(header.getUint8(2), 0);
    expect(header.getUint8(3), 2);
    expect(header.getUint16(6, Endian.big), 3);
    expect(header.getUint16(8, Endian.big), 9);
    expect(header.getUint16(10, Endian.big), 3);
    expect(header.getUint8(13), 1);
    expect(header.getUint16(16, Endian.big), 36);
    expect(header.getUint16(18, Endian.big), 12);
    expect(header.getUint16(38, Endian.big), 255);
    expect(
      ascii.decode(bytes.sublist(headerOffset + 48, headerOffset + 64)),
      'LMINV001        ',
    );

    final characterCommand = <int>[
      0x1b,
      ...ascii.encode('*c65E'),
      0x1b,
      ...ascii.encode('(s22W'),
    ];
    final descriptorOffset = headerOffset + 64;
    expect(
      bytes.sublist(
        descriptorOffset,
        descriptorOffset + characterCommand.length,
      ),
      characterCommand,
    );
    final characterOffset = descriptorOffset + characterCommand.length;
    final descriptor = ByteData.sublistView(
      bytes,
      characterOffset,
      characterOffset + 16,
    );
    expect(descriptor.getUint8(0), 4);
    expect(descriptor.getUint8(1), 0);
    expect(descriptor.getUint8(2), 14);
    expect(descriptor.getUint8(3), 1);
    expect(descriptor.getInt16(6, Endian.big), -1);
    expect(descriptor.getInt16(8, Endian.big), 2);
    expect(descriptor.getUint16(10, Endian.big), 9);
    expect(descriptor.getUint16(12, Endian.big), 3);
    expect(descriptor.getUint16(14, Endian.big), 36);
    expect(bytes.sublist(characterOffset + 16), <int>[
      0x80,
      0x00,
      0x40,
      0x00,
      0x20,
      0x00,
    ]);
  });

  test('rejects a raster whose row stride does not match its dimensions', () {
    expect(
      () => buildPcl4BitmapSoftFont(
        fontName: 'LMINV001',
        cellWidth: 9,
        cellHeight: 3,
        glyphs: <Pcl4BitmapGlyph>[
          Pcl4BitmapGlyph(
            characterCode: 65,
            width: 9,
            height: 3,
            advance: 9,
            raster: Uint8List(3),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('wraps an SFP download and emits an inverse V command', () {
    final softFont = Uint8List.fromList(<int>[0x1b, 0x29, 0x73]);
    final download = buildGodexBitmapFontDownload(
      slot: 'A',
      softFont: softFont,
    );
    expect(download, <int>[
      ...ascii.encode('~MDELE,A\r\n~JA\r\n'),
      ...softFont,
    ]);
    expect(
      buildGodexDownloadedBitmapTextCommand(
        slot: 'A',
        x: 12,
        y: 34,
        characterCode: 65,
      ),
      ascii.encode('VA,12,34,1,1,0,0I,A\r\n'),
    );
  });

  testWidgets('rasterizes one Korean run as one proportional glyph', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final glyph = await rasterizeGodexTextGlyph(
        text: '영양정보',
        characterCode: 65,
        fontFamily: 'Gulim',
        fontPixelHeight: 20,
        bold: true,
        italic: false,
        maximumWidth: 64,
      );

      expect(glyph.width, 64);
      expect(glyph.height, greaterThanOrEqualTo(19));
      expect(glyph.advance, glyph.width);
      expect(glyph.raster, contains(isNot(0)));
      final font = buildPcl4BitmapSoftFont(
        fontName: 'LMINV001',
        cellWidth: glyph.width,
        cellHeight: glyph.height,
        glyphs: <Pcl4BitmapGlyph>[glyph],
      );
      expect(font, isNotEmpty);
    });
  });
}
