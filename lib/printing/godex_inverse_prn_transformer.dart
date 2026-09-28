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
const int _godexInverseCellRightOverhang = 1;
const int _godexInverseCellBottomOverhang = 1;

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
    required this.restoredWhitePixels,
    required this.clearedPixels,
    required this.compensatedPixels,
  });

  final Uint8List bytes;
  final int inverseDescriptors;
  final int nativeRuns;
  final int restoredWhitePixels;
  final int clearedPixels;
  final int compensatedPixels;

  bool get transformed => inverseDescriptors > 0;

  String get diagnostics =>
      'firmwareInverse=$inverseDescriptors nativeRuns=$nativeRuns '
      'restoredWhitePixels=$restoredWhitePixels '
      'clearedPixels=$clearedPixels compensatedPixels=$compensatedPixels '
      'darkness=$godexInversePrintDarkness '
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

class _GodexPixelRect {
  const _GodexPixelRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;
}

bool _isGodexPixelBlack(Uint8List bytes, _GodexQPattern pattern, int x, int y) {
  final localX = x - pattern.originX;
  final localY = y - pattern.originY;
  final byteIndex =
      pattern.payloadOffset + localY * pattern.stride + localX ~/ 8;
  return (bytes[byteIndex] & (0x80 >> (localX % 8))) != 0;
}

_GodexPixelRect _findInverseBlackBand({
  required Uint8List bytes,
  required _GodexQPattern pattern,
  required int descriptorLeft,
  required int descriptorTop,
  required int descriptorRight,
  required int descriptorBottom,
  required int horizontalSearchPadding,
}) {
  final patternRight = pattern.originX + pattern.stride * 8;
  final patternBottom = pattern.originY + pattern.height;
  final searchLeft = math.max(
    pattern.originX,
    descriptorLeft - horizontalSearchPadding,
  );
  final searchRight = math.min(
    patternRight,
    descriptorRight + horizontalSearchPadding,
  );
  var bandLeft = -1;
  var bandRight = -1;
  for (var y = descriptorTop; y < descriptorBottom; y += 1) {
    int? runStart;
    var lastBlack = -1;
    var whiteGap = 0;
    void considerRun() {
      if (runStart == null || lastBlack < runStart) return;
      final runRight = lastBlack + 1;
      if (runStart <= descriptorLeft && runRight >= descriptorRight) {
        if (bandLeft < 0 || runRight - runStart > bandRight - bandLeft) {
          bandLeft = runStart;
          bandRight = runRight;
        }
      }
    }

    for (var x = searchLeft; x < searchRight; x += 1) {
      if (_isGodexPixelBlack(bytes, pattern, x, y)) {
        runStart ??= x;
        lastBlack = x;
        whiteGap = 0;
      } else if (runStart != null) {
        whiteGap += 1;
        if (whiteGap > 2) {
          considerRun();
          runStart = null;
          lastBlack = -1;
          whiteGap = 0;
        }
      }
    }
    considerRun();
  }
  if (bandLeft < 0 || bandRight <= bandLeft) {
    throw const FormatException(
      'Could not resolve the original black band for inverse text.',
    );
  }

  bool rowBelongsToBand(int y) {
    var blackPixels = 0;
    for (var x = bandLeft; x < bandRight; x += 1) {
      if (_isGodexPixelBlack(bytes, pattern, x, y)) blackPixels += 1;
    }
    return blackPixels * 2 >= bandRight - bandLeft;
  }

  var bandTop = descriptorTop;
  while (bandTop > pattern.originY && rowBelongsToBand(bandTop - 1)) {
    bandTop -= 1;
  }
  var bandBottom = descriptorBottom;
  while (bandBottom < patternBottom && rowBelongsToBand(bandBottom)) {
    bandBottom += 1;
  }
  return _GodexPixelRect(bandLeft, bandTop, bandRight, bandBottom);
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
      restoredWhitePixels: 0,
      clearedPixels: 0,
      compensatedPixels: 0,
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
  final rasterizedRunsByDescriptor =
      Map<
        LabelSheetWindowsTextDescriptor,
        List<_GodexRasterizedRun>
      >.identity();
  var characterCode = 0x21;
  for (final descriptor in inverseDescriptors) {
    final descriptorRuns = <_GodexRasterizedRun>[];
    rasterizedRunsByDescriptor[descriptor] = descriptorRuns;
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
      final rasterizedRun = _GodexRasterizedRun(x: x, y: y, glyph: glyph);
      rasterizedRuns.add(rasterizedRun);
      descriptorRuns.add(rasterizedRun);
      characterCode += 1;
    }
  }

  final modified = Uint8List.fromList(prnBytes);
  final bandsByRun = Map<_GodexRasterizedRun, _GodexPixelRect>.identity();
  var restoredWhitePixels = 0;
  for (final descriptor in inverseDescriptors) {
    final horizontalPadding = scaleFontHeight(descriptor.fontPixelHeight) + 1;
    final descriptorLeft = scaleX(descriptor.left);
    final descriptorTop = math.max(pattern.originY, scaleY(descriptor.top));
    final descriptorRight = scaleX(descriptor.right);
    final descriptorBottom = math.min(
      pattern.originY + pattern.height,
      scaleY(descriptor.bottom),
    );
    if (descriptorRight <= descriptorLeft ||
        descriptorBottom <= descriptorTop) {
      throw FormatException(
        'Inverse descriptor is outside the GoDEX Q pattern: '
        '$descriptorLeft,$descriptorTop,$descriptorRight,$descriptorBottom',
      );
    }
    final band = _findInverseBlackBand(
      bytes: prnBytes,
      pattern: pattern,
      descriptorLeft: descriptorLeft,
      descriptorTop: descriptorTop,
      descriptorRight: descriptorRight,
      descriptorBottom: descriptorBottom,
      horizontalSearchPadding: horizontalPadding,
    );
    final descriptorRuns = rasterizedRunsByDescriptor[descriptor]!;
    for (final run in descriptorRuns) {
      bandsByRun[run] = band;
    }
    final contentLeft = descriptorRuns.fold<int>(
      descriptorLeft,
      (value, run) => math.min(value, run.x),
    );
    final contentTop = descriptorRuns.fold<int>(
      descriptorTop,
      (value, run) => math.min(value, run.y),
    );
    final contentRight = descriptorRuns.fold<int>(
      descriptorRight,
      (value, run) => math.max(value, run.x + run.glyph.width),
    );
    final contentBottom = descriptorRuns.fold<int>(
      descriptorBottom,
      (value, run) => math.max(value, run.y + run.glyph.height),
    );
    final restoreLeft = math.max(band.left, contentLeft - 1);
    final restoreTop = math.max(band.top, contentTop - 1);
    final restoreRight = math.min(band.right, contentRight + 1);
    final restoreBottom = math.min(band.bottom, contentBottom + 1);
    for (var y = restoreTop; y < restoreBottom; y += 1) {
      for (var x = restoreLeft; x < restoreRight; x += 1) {
        final localX = x - pattern.originX;
        final localY = y - pattern.originY;
        final byteIndex =
            pattern.payloadOffset + localY * pattern.stride + localX ~/ 8;
        final mask = 0x80 >> (localX % 8);
        if ((modified[byteIndex] & mask) == 0) restoredWhitePixels += 1;
        modified[byteIndex] |= mask;
      }
    }
  }
  var clearedPixels = 0;
  var compensatedPixels = 0;
  for (final rasterizedRun in rasterizedRuns) {
    // G500 applies downloaded-font inverse text as XOR over a cell that is
    // one dot wider on the right and one dot taller at the bottom than the
    // PCL bitmap. Precompose that exact cell so nearby sheet pixels survive.
    final left = rasterizedRun.x;
    final top = rasterizedRun.y;
    final right =
        rasterizedRun.x +
        rasterizedRun.glyph.width +
        _godexInverseCellRightOverhang;
    final bottom =
        top + rasterizedRun.glyph.height + _godexInverseCellBottomOverhang;
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
    final band = bandsByRun[rasterizedRun]!;
    final glyphStride = (rasterizedRun.glyph.width + 7) ~/ 8;
    for (var y = top; y < bottom; y += 1) {
      for (var x = left; x < right; x += 1) {
        final localX = x - pattern.originX;
        final localY = y - pattern.originY;
        final byteIndex =
            pattern.payloadOffset + localY * pattern.stride + localX ~/ 8;
        final mask = 0x80 >> (localX % 8);
        final insideBand =
            x >= band.left &&
            x < band.right &&
            y >= band.top &&
            y < band.bottom;
        if (insideBand) {
          if ((modified[byteIndex] & mask) != 0) clearedPixels += 1;
          modified[byteIndex] &= 0xff ^ mask;
          continue;
        }
        final glyphX = x - rasterizedRun.x;
        final glyphY = y - rasterizedRun.y;
        final isGlyphPixel =
            glyphX >= 0 &&
            glyphX < rasterizedRun.glyph.width &&
            glyphY >= 0 &&
            glyphY < rasterizedRun.glyph.height &&
            (rasterizedRun.glyph.raster[glyphY * glyphStride + glyphX ~/ 8] &
                    (0x80 >> (glyphX % 8))) !=
                0;
        if (!isGlyphPixel) {
          modified[byteIndex] ^= mask;
          compensatedPixels += 1;
        }
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
    restoredWhitePixels: restoredWhitePixels,
    clearedPixels: clearedPixels,
    compensatedPixels: compensatedPixels,
  );
}
