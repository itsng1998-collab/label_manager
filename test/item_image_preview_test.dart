import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/features/item/application/item_image_preview.dart';

void main() {
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