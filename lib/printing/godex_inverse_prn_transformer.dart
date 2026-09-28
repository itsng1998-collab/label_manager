import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:label_manager/printing/godex_pcl4_bitmap_font.dart';
import 'package:label_manager/printing/godex_text_glyph_rasterizer.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

const int godexInversePrintDarkness = 8;
const int godexRestoredPrintDarkness = 8;
const String _godexInverseFontSlot = 'A';
const String _godexInverseFontName = 'LMINVAPP1';

typedef GodexInverseGlyphRasterizer =
    Future<Pcl4BitmapGlyph> Function({
      required String text,
      required int characterCode,
      required String fontFamily,
      required double fontPixelHeight,
      required bool bold,
      required bool italic,
      int? maximumWidth,
    });

class _GodexRasterizedRun {
  const _GodexRasterizedRun({
    required this.x,
    required this.y,
    required this.glyph,
  });

  final int x;
  final int y;
  final Pcl4BitmapGlyph glyph;
}

class GodexInversePrnTransformResult {
  const GodexInversePrnTransformResult({
    required this.bytes,
    required this.inverseDescriptors,
    required this.nativeRuns,
    required this.clearedPixels,
  });

  final Uint8List bytes;
  final int inverseDescriptors;
  final int nativeRuns;
  final int clearedPixels;

  bool get transformed => inverseDescriptors > 0;

  String get diagnostics =>
      'firmwareInverse=$inverseDescriptors nativeRuns=$nativeRuns '
      'clearedPixels=$clearedPixels darkness=$godexInversePrintDarkness '
      'restoreDarkness=$godexRestoredPrintDarkness';
}

class _GodexQPattern {
  const _GodexQPattern({
    required this.originX,
    required this.originY,
    required this.stride,
    required this.height,
    required this.payloadOffset,
  });

  final int originX;
  final int originY;
  final int stride;
  final int height;
  final int payloadOffset;
}

Future<GodexInversePrnTransformResult> transformGodexInverseDriverPrn({
  required Uint8List prnBytes,
  required int sourceWidth,
  required int sourceHeight,
  required int targetWidth,
  required int targetHeight,
  required List<LabelSheetWindowsTextDescriptor> textDescriptors,
  GodexInverseGlyphRasterizer glyphRasterizer = rasterizeGodexTextGlyph,
}) async {
  final inverseDescriptors = textDescriptors
      .where(
        (descriptor) =>
            descriptor.colorArgb == 0xffffffff &&
            descriptor.firmwareInverseRuns.isNotEmpty,
      )
      .toList(growable: false);
  if (inverseDescriptors.isEmpty) {
    return GodexInversePrnTransformResult(
      bytes: prnBytes,
      inverseDescriptors: 0,
      nativeRuns: 0,
      clearedPixels: 0,
    );
  }
  if (sourceWidth <= 0 ||
      sourceHeight <= 0 ||
      targetWidth <= 0 ||
      targetHeight <= 0) {
    throw const FormatException('Invalid GoDEX inverse page dimensions.');
  }

  var offset = 0;
  int? labelStartOffset;
  int? endCommandOffset;
  _GodexQPattern? pattern;
  while (offset < prnBytes.length) {
    if (prnBytes[offset] == 10 || prnBytes[offset] == 13) {
      offset += 1;
      continue;
    }
    final start = offset;
    while (offset < prnBytes.length &&
        prnBytes[offset] != 10 &&
        prnBytes[offset] != 13) {
      offset += 1;
    }
    final command = ascii.decode(prnBytes.sublist(start, offset));
    if (command == '^L') {
      if (labelStartOffset != null) {
        throw const FormatException('GoDEX PRN has multiple ^L commands.');
      }
      labelStartOffset = start;
      continue;
    }
    final qMatch = RegExp(r'^Q(\d+),(\d+),(\d+),(\d+)$').firstMatch(command);
    if (qMatch != null) {
      if (pattern != null ||
          offset >= prnBytes.length ||
          prnBytes[offset] != 13) {
        throw const FormatException('GoDEX PRN has an invalid Q pattern.');
      }
      final stride = int.parse(qMatch.group(3)!);
      final height = int.parse(qMatch.group(4)!);
      final payloadOffset = offset + 1;
      final payloadLength = stride * height;
      if (stride <= 0 ||
          height <= 0 ||
          payloadOffset + payloadLength > prnBytes.length) {
        throw const FormatException('GoDEX Q payload is truncated.');
      }
      pattern = _GodexQPattern(
        originX: int.parse(qMatch.group(1)!),
        originY: int.parse(qMatch.group(2)!),
        stride: stride,
        height: height,
        payloadOffset: payloadOffset,
      );
      offset = payloadOffset + payloadLength;
      continue;
    }
    if (command == 'E') {
      endCommandOffset = start;
      break;
    }
  }
  if (labelStartOffset == null || pattern == null || endCommandOffset == null) {
    throw const FormatException(
      'GoDEX PRN must contain one ^L, one Q pattern, and E.',
    );
  }

  int scaleX(int value) => (value * targetWidth / sourceWidth).round();
  int scaleY(int value) => (value * targetHeight / sourceHeight).round();
  int scaleFontHeight(int value) =>
      math.max(1, (value * targetHeight / sourceHeight).round());

  final rasterizedRuns = <_GodexRasterizedRun>[];
  var characterCode = 0x21;
  for (final descriptor in inverseDescriptors) {
    for (final run in descriptor.firmwareInverseRuns) {
      if (run.text.isEmpty ||
          run.text.contains('\r') ||
          run.text.contains('\n')) {
        throw const FormatException(
          'GoDEX inverse run must be one non-empty line.',
        );
      }
      while (characterCode == 0x2c) {
        characterCode += 1;
      }
      if (characterCode > 0x7e) {
        throw const FormatException('GoDEX inverse has too many text runs.');
      }
      final x = scaleX(run.left);
      final y = scaleY(run.top);
      final maximumWidth = pattern.originX + pattern.stride * 8 - x;
      if (x < pattern.originX ||
          y < pattern.originY ||
          maximumWidth < 1 ||
          y >= pattern.originY + pattern.height) {
        throw FormatException(
          'Inverse run starts outside the GoDEX Q pattern: $x,$y',
        );
      }
      final glyph = await glyphRasterizer(
        text: run.text,
        characterCode: characterCode,
        fontFamily: descriptor.fontFamily,
        fontPixelHeight: scaleFontHeight(descriptor.fontPixelHeight).toDouble(),
        bold: descriptor.bold,
        italic: descriptor.italic,
        maximumWidth: maximumWidth,
      );
      rasterizedRuns.add(_GodexRasterizedRun(x: x, y: y, glyph: glyph));
      characterCode += 1;
    }
  }

  final modified = Uint8List.fromList(prnBytes);
  var clearedPixels = 0;
  for (final rasterizedRun in rasterizedRuns) {
    final left = rasterizedRun.x;
    final top = rasterizedRun.y;
    final right = left + rasterizedRun.glyph.width;
    final bottom = top + rasterizedRun.glyph.height;
    if (left < pattern.originX ||
        top < pattern.originY ||
        right > pattern.originX + pattern.stride * 8 ||
        bottom > pattern.originY + pattern.height ||
        right <= left ||
        bottom <= top) {
      throw FormatException(
        'Inverse run is outside the GoDEX Q pattern: '
        '$left,$top,$right,$bottom',
      );
    }
    for (var y = top; y < bottom; y += 1) {
      for (var x = left; x < right; x += 1) {
        final localX = x - pattern.originX;
        final localY = y - pattern.originY;
        final byteIndex =
            pattern.payloadOffset + localY * pattern.stride + localX ~/ 8;
        final mask = 0x80 >> (localX % 8);
        if ((modified[byteIndex] & mask) != 0) clearedPixels += 1;
        modified[byteIndex] &= 0xff ^ mask;
      }
    }
  }

  final glyphs = rasterizedRuns
      .map((rasterizedRun) => rasterizedRun.glyph)
      .toList(growable: false);
  final cellWidth = glyphs.map((glyph) => glyph.width).reduce(math.max);
  final cellHeight = glyphs.map((glyph) => glyph.height).reduce(math.max);
  final softFont = buildPcl4BitmapSoftFont(
    fontName: _godexInverseFontName,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    glyphs: glyphs,
  );
  final fontDownload = buildGodexBitmapFontDownload(
    slot: _godexInverseFontSlot,
    softFont: softFont,
  );
  final nativeCommands = BytesBuilder(copy: false);
  for (final rasterizedRun in rasterizedRuns) {
    nativeCommands.add(
      buildGodexDownloadedBitmapTextCommand(
        slot: _godexInverseFontSlot,
        x: rasterizedRun.x,
        y: rasterizedRun.y,
        characterCode: rasterizedRun.glyph.characterCode,
      ),
    );
  }

  final result = BytesBuilder(copy: false)
    ..add(fontDownload)
    ..add(const <int>[13, 10])
    ..add(modified.sublist(0, labelStartOffset))
    ..add(
      ascii.encode(
        '^H${godexInversePrintDarkness.toString().padLeft(2, '0')}\r\n',
      ),
    )
    ..add(modified.sublist(labelStartOffset, endCommandOffset))
    ..add(nativeCommands.takeBytes())
    ..add(modified.sublist(endCommandOffset))
    ..add(
      ascii.encode(
        '^H${godexRestoredPrintDarkness.toString().padLeft(2, '0')}\r\n',
      ),
    );
  return GodexInversePrnTransformResult(
    bytes: result.takeBytes(),
    inverseDescriptors: inverseDescriptors.length,
    nativeRuns: rasterizedRuns.length,
    clearedPixels: clearedPixels,
  );
}
