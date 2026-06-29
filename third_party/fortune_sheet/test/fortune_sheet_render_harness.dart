import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

String fortuneSheetGoldenPath(String name) {
  return 'goldens/$name.png';
}

Future<void> expectFortuneSheetGolden(
  WidgetTester tester,
  Finder finder,
  String goldenPath, {
  double maxDiffRatio = 0.001,
}) async {
  final renderObject = tester.firstRenderObject(finder);
  if (renderObject is! RenderRepaintBoundary) {
    fail('Expected a RenderRepaintBoundary for golden capture.');
  }
  final actualImage = await tester.runAsync(
    () => renderObject.toImage(pixelRatio: 1),
  );
  if (actualImage == null) {
    fail('Failed to capture actual golden image for $goldenPath.');
  }
  final actualData = await tester.runAsync(
    () => actualImage.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (actualData == null) {
    fail('Failed to read actual golden capture pixels.');
  }

  final goldenFile = File('test/$goldenPath');
  if (Platform.environment['FORTUNE_UPDATE_GOLDENS'] == '1') {
    final pngData = await tester.runAsync(
      () => actualImage.toByteData(format: ui.ImageByteFormat.png),
    );
    if (pngData == null) {
      fail('Failed to encode updated golden image for $goldenPath.');
    }
    goldenFile
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(pngData.buffer.asUint8List());
  }

  final expectedImage = await tester.runAsync(
    () => _decodePng(goldenFile.readAsBytesSync()),
  );
  if (expectedImage == null) {
    fail('Failed to decode expected golden image for $goldenPath.');
  }
  final expectedData = await tester.runAsync(
    () => expectedImage.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  if (expectedData == null) {
    fail('Failed to read expected golden pixels for $goldenPath.');
  }

  final width = actualImage.width;
  final height = actualImage.height;
  if (width != expectedImage.width || height != expectedImage.height) {
    fail(
      'Golden $goldenPath size mismatch: actual ${width}x$height, '
      'expected ${expectedImage.width}x${expectedImage.height}.',
    );
  }

  final diffPixels = _differentPixelCount(
    actualData.buffer.asUint8List(),
    expectedData.buffer.asUint8List(),
  );
  final pixelCount = width * height;
  final diffRatio = diffPixels / pixelCount;
  if (diffRatio > maxDiffRatio) {
    fail(
      'Golden $goldenPath pixel diff ${diffPixels}px '
      '(${(diffRatio * 100).toStringAsFixed(3)}%) exceeds '
      '${(maxDiffRatio * 100).toStringAsFixed(3)}%.',
    );
  }
}

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

int _differentPixelCount(Uint8List actual, Uint8List expected) {
  if (actual.length != expected.length) {
    fail(
      'Golden raw byte length mismatch: actual ${actual.length}, '
      'expected ${expected.length}.',
    );
  }
  var count = 0;
  for (var index = 0; index < actual.length; index += 4) {
    if (actual[index] != expected[index] ||
        actual[index + 1] != expected[index + 1] ||
        actual[index + 2] != expected[index + 2] ||
        actual[index + 3] != expected[index + 3]) {
      count += 1;
    }
  }
  return count;
}
