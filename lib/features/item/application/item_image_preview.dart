import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as imglib;

String itemBmpPreviewDataUri(Uint8List bytes) {
  if (_bmpBitsPerPixel(bytes) case final bitsPerPixel?
      when bitsPerPixel <= 8) {
    final decoded = imglib.decodeBmp(bytes);
    if (decoded != null) {
      return 'data:image/png;base64,${base64Encode(imglib.encodePng(decoded))}';
    }
  }
  return 'data:image/bmp;base64,${base64Encode(bytes)}';
}

int? _bmpBitsPerPixel(Uint8List bytes) {
  if (bytes.length < 30 || bytes[0] != 0x42 || bytes[1] != 0x4d) {
    return null;
  }
  return ByteData.sublistView(bytes).getUint16(28, Endian.little);
}