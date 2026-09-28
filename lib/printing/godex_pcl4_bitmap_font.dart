import 'dart:convert';
import 'dart:typed_data';

const int _escape = 0x1b;

Uint8List buildGodexBitmapFontDownload({
  required String slot,
  required Uint8List softFont,
}) {
  _validateSlot(slot);
  if (softFont.isEmpty) {
    throw ArgumentError.value(softFont, 'softFont', 'Must not be empty.');
  }
  return (BytesBuilder(copy: false)
        ..add(ascii.encode('~MDELE,$slot\r\n~J$slot\r\n'))
        ..add(softFont))
      .takeBytes();
}

Uint8List buildGodexDownloadedBitmapTextCommand({
  required String slot,
  required int x,
  required int y,
  required int characterCode,
  bool inverse = true,
}) {
  _validateSlot(slot);
  if (x < 0 || y < 0) {
    throw ArgumentError('Coordinates must not be negative.');
  }
  if (characterCode < 0x21 || characterCode > 0x7e || characterCode == 0x2c) {
    throw RangeError.range(
      characterCode,
      0x21,
      0x7e,
      'characterCode',
      'Must be a printable non-comma ASCII byte.',
    );
  }
  return Uint8List.fromList(<int>[
    ...ascii.encode('V$slot,$x,$y,1,1,0,0${inverse ? 'I' : ''},'),
    characterCode,
    13,
    10,
  ]);
}

void _validateSlot(String slot) {
  if (!RegExp(r'^[A-Z]$').hasMatch(slot)) {
    throw ArgumentError.value(slot, 'slot', 'Must be one letter from A to Z.');
  }
}

class Pcl4BitmapGlyph {
  const Pcl4BitmapGlyph({
    required this.characterCode,
    required this.width,
    required this.height,
    required this.advance,
    required this.raster,
    this.leftOffset = 0,
    this.topOffset,
  });

  final int characterCode;
  final int width;
  final int height;
  final int advance;
  final int leftOffset;
  final int? topOffset;
  final Uint8List raster;
}

Uint8List buildPcl4BitmapSoftFont({
  required String fontName,
  required int cellWidth,
  required int cellHeight,
  required Iterable<Pcl4BitmapGlyph> glyphs,
}) {
  final glyphList = glyphs.toList(growable: false);
  if (glyphList.isEmpty) {
    throw ArgumentError.value(glyphs, 'glyphs', 'Must not be empty.');
  }
  if (cellWidth < 1 || cellWidth > 0xffff) {
    throw RangeError.range(cellWidth, 1, 0xffff, 'cellWidth');
  }
  if (cellHeight < 1 || cellHeight > 0xffff) {
    throw RangeError.range(cellHeight, 1, 0xffff, 'cellHeight');
  }
  final nameBytes = ascii.encode(fontName);
  if (nameBytes.isEmpty || nameBytes.length > 16) {
    throw ArgumentError.value(
      fontName,
      'fontName',
      'Must contain 1 to 16 ASCII characters.',
    );
  }

  final codes = <int>{};
  for (final glyph in glyphList) {
    if (glyph.characterCode < 0 || glyph.characterCode > 0xff) {
      throw RangeError.range(glyph.characterCode, 0, 0xff, 'characterCode');
    }
    if (!codes.add(glyph.characterCode)) {
      throw ArgumentError('Duplicate character code ${glyph.characterCode}.');
    }
    if (glyph.width < 1 || glyph.width > cellWidth) {
      throw RangeError.range(glyph.width, 1, cellWidth, 'glyph.width');
    }
    if (glyph.height < 1 || glyph.height > cellHeight) {
      throw RangeError.range(glyph.height, 1, cellHeight, 'glyph.height');
    }
    if (glyph.advance < 1 || glyph.advance > 0x3fff) {
      throw RangeError.range(glyph.advance, 1, 0x3fff, 'glyph.advance');
    }
    final expectedRasterLength = ((glyph.width + 7) ~/ 8) * glyph.height;
    if (glyph.raster.length != expectedRasterLength) {
      throw ArgumentError.value(
        glyph.raster.length,
        'glyph.raster.length',
        'Expected $expectedRasterLength bytes.',
      );
    }
  }

  final widestAdvance = glyphList
      .map((glyph) => glyph.advance)
      .reduce((left, right) => left > right ? left : right);
  final averageAdvance =
      glyphList.fold<int>(0, (sum, glyph) => sum + glyph.advance) ~/
      glyphList.length;
  final header = Uint8List(64);
  final headerData = ByteData.sublistView(header);
  void uint16(int offset, int value) =>
      headerData.setUint16(offset, value, Endian.big);

  uint16(0, 64);
  header[2] = 0;
  header[3] = 2;
  uint16(6, cellHeight);
  uint16(8, cellWidth);
  uint16(10, cellHeight);
  header[12] = 0;
  header[13] = 1;
  uint16(14, 21);
  uint16(16, widestAdvance * 4);
  uint16(18, cellHeight * 4);
  uint16(20, cellHeight * 4);
  header[24] = 3;
  header[28] = 2;
  uint16(32, ((cellHeight * 6 + 4) ~/ 5) * 4);
  uint16(34, averageAdvance * 4);
  uint16(36, 0);
  uint16(38, 255);
  for (var index = 0; index < nameBytes.length; index += 1) {
    header[48 + index] = nameBytes[index];
  }
  for (var index = nameBytes.length; index < 16; index += 1) {
    header[48 + index] = 0x20;
  }

  final output = BytesBuilder(copy: false)
    ..add(<int>[_escape, ...ascii.encode(')s64W')])
    ..add(header);
  for (final glyph in glyphList) {
    final descriptor = Uint8List(16);
    final descriptorData = ByteData.sublistView(descriptor);
    descriptor[0] = 4;
    descriptor[1] = 0;
    descriptor[2] = 14;
    descriptor[3] = 1;
    descriptor[4] = 0;
    descriptor[5] = 0;
    descriptorData.setInt16(6, glyph.leftOffset, Endian.big);
    descriptorData.setInt16(8, glyph.topOffset ?? glyph.height, Endian.big);
    descriptorData.setUint16(10, glyph.width, Endian.big);
    descriptorData.setUint16(12, glyph.height, Endian.big);
    descriptorData.setUint16(14, glyph.advance * 4, Endian.big);
    final blockLength = descriptor.length + glyph.raster.length;
    output
      ..add(<int>[
        _escape,
        ...ascii.encode('*c${glyph.characterCode}E'),
        _escape,
        ...ascii.encode('(s${blockLength}W'),
      ])
      ..add(descriptor)
      ..add(glyph.raster);
  }
  return output.takeBytes();
}
