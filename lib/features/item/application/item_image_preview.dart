import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as imglib;
import 'package:path/path.dart' as p;

const List<String> itemBmpPreviewDirectories = <String>[
  r'C:\ITS\LabelManager\bmp files',
  r'C:\ITS\BCSManager\bmpfiles',
];

String? itemBmpPreviewDataUriForFileName(
  String fileNameWithoutExtension, {
  List<String> directories = itemBmpPreviewDirectories,
}) {
  final value = fileNameWithoutExtension.trim();
  if (value.isEmpty) return null;
  final fileName = value.toLowerCase().endsWith('.bmp') ? value : '$value.bmp';
  for (final directory in directories) {
    final file = File(p.join(directory, fileName));
    if (file.existsSync()) {
      return itemBmpPreviewDataUri(file.readAsBytesSync());
    }
  }
  return null;
}

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