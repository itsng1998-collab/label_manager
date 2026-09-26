import 'dart:convert';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

const int godexInversePrintDarkness = 4;
const int godexRestoredPrintDarkness = 8;
const int _godexAsianFontHeight = 16;

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

  final encodedRuns = <({LabelSheetWindowsFirmwareTextRun run, Uint8List bytes})>[];
  for (final descriptor in inverseDescriptors) {
    for (final run in descriptor.firmwareInverseRuns) {
      if (run.text.contains('\r') || run.text.contains('\n')) {
        throw const FormatException('GoDEX inverse run contains a line break.');
      }
      encodedRuns.add((
        run: run,
        bytes: await CharsetConverter.encode('949', run.text),
      ));
    }
  }

  final modified = Uint8List.fromList(prnBytes);
  var clearedPixels = 0;
  for (final encodedRun in encodedRuns) {
    final left = scaleX(encodedRun.run.left);
    final top = scaleY(encodedRun.run.top);
    final right = left + encodedRun.bytes.length * 8;
    final bottom = top + _godexAsianFontHeight;
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

  final nativeCommands = BytesBuilder(copy: false);
  for (final encodedRun in encodedRuns) {
    nativeCommands.add(
      ascii.encode(
        'AZ1,${scaleX(encodedRun.run.left)},${scaleY(encodedRun.run.top)},'
        '1,1,0,0I,',
      ),
    );
    nativeCommands.add(encodedRun.bytes);
    nativeCommands.add(const <int>[13, 10]);
  }

  final result = BytesBuilder(copy: false)
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
    nativeRuns: encodedRuns.length,
    clearedPixels: clearedPixels,
  );
}
