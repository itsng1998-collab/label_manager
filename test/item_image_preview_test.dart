import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/features/item/application/item_image_preview.dart';

void main() {
  test('품목 BMP 기본 탐색 폴더에 LabelManager와 BCSManager를 포함한다', () {
    expect(itemBmpPreviewDirectories, const <String>[
      r'C:\ITS\LabelManager\bmp files',
      r'C:\ITS\BCSManager\bmpfiles',
    ]);
  });

  test('1-bit BMP는 품목 미리보기용 PNG로 정규화한다', () {
    final dataUri = itemBmpPreviewDataUri(_oneBitBmp());
    final bytes = base64Decode(dataUri.substring(dataUri.indexOf(',') + 1));
    final decoded = imglib.decodePng(bytes);

    expect(dataUri, startsWith('data:image/png;base64,'));
    expect(decoded, isNotNull);
    expect(decoded!.width, 2);
    expect(decoded.height, 2);
  });

  test('24-bit BMP는 기존 BMP data URI를 유지한다', () {
    final source = Uint8List.fromList(imglib.encodeBmp(imglib.Image(width: 2, height: 2)));

    final dataUri = itemBmpPreviewDataUri(source);

    expect(dataUri, startsWith('data:image/bmp;base64,'));
    expect(base64Decode(dataUri.substring(dataUri.indexOf(',') + 1)), source);
  });

  test('기본 폴더에 없으면 BCSManager BMP 폴더에서 찾는다', () {
    final root = Directory.systemTemp.createTempSync('item-bmp-preview-');
    addTearDown(() => root.deleteSync(recursive: true));
    final labelManagerDirectory = Directory('${root.path}/label-manager')
      ..createSync();
    final bcsManagerDirectory = Directory('${root.path}/bcs-manager')
      ..createSync();
    final source = Uint8List.fromList(
      imglib.encodeBmp(imglib.Image(width: 2, height: 2)),
    );
    File('${bcsManagerDirectory.path}/logo.bmp').writeAsBytesSync(source);

    final dataUri = itemBmpPreviewDataUriForFileName(
      'logo',
      directories: [labelManagerDirectory.path, bcsManagerDirectory.path],
    );

    expect(dataUri, isNotNull);
    expect(base64Decode(dataUri!.substring(dataUri.indexOf(',') + 1)), source);
  });

  test('같은 파일명이 있으면 기존 LabelManager BMP 폴더를 우선한다', () {
    final root = Directory.systemTemp.createTempSync('item-bmp-preview-');
    addTearDown(() => root.deleteSync(recursive: true));
    final labelManagerDirectory = Directory('${root.path}/label-manager')
      ..createSync();
    final bcsManagerDirectory = Directory('${root.path}/bcs-manager')
      ..createSync();
    File('${labelManagerDirectory.path}/logo.bmp').writeAsBytesSync(_oneBitBmp());
    File('${bcsManagerDirectory.path}/logo.bmp').writeAsBytesSync(
      imglib.encodeBmp(imglib.Image(width: 2, height: 2)),
    );

    final dataUri = itemBmpPreviewDataUriForFileName(
      'logo',
      directories: [labelManagerDirectory.path, bcsManagerDirectory.path],
    );

    expect(dataUri, startsWith('data:image/png;base64,'));
  });
}

Uint8List _oneBitBmp() {
  final bytes = Uint8List(70);
  final data = ByteData.sublistView(bytes);
  bytes[0] = 0x42;
  bytes[1] = 0x4d;
  data.setUint32(2, bytes.length, Endian.little);
  data.setUint32(10, 62, Endian.little);
  data.setUint32(14, 40, Endian.little);
  data.setInt32(18, 2, Endian.little);
  data.setInt32(22, 2, Endian.little);
  data.setUint16(26, 1, Endian.little);
  data.setUint16(28, 1, Endian.little);
  data.setUint32(34, 8, Endian.little);
  data.setUint32(46, 2, Endian.little);
  bytes.setAll(58, const <int>[255, 255, 255, 0]);
  bytes[62] = 0x80;
  bytes[66] = 0x40;
  return bytes;
}