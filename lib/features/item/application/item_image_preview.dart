import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as imglib;
import 'package:label_manager/utils/log_context.dart';
import 'package:path/path.dart' as p;

const List<String> itemBmpPreviewDirectories = <String>[
  r'C:\ITS\LabelManager\bmp files',
  r'C:\ITS\BCSManager\bmpfiles',
];

final Map<String, Uint8List> _selectedItemBmpPreviewBytes = <String, Uint8List>{};

void cacheSelectedItemBmpPreview(String fileName, Uint8List bytes) {
  final key = _itemBmpPreviewKey(fileName);
  _selectedItemBmpPreviewBytes[key] = Uint8List.fromList(bytes);
  debugLog(
    'itemBmpPreview selected fileName=$fileName key=$key bytes=${bytes.length}',
  );
}

void clearSelectedItemBmpPreviewCache() {
  _selectedItemBmpPreviewBytes.clear();
}

String? itemBmpPreviewDataUriForFileName(
  String fileNameWithoutExtension, {
  List<String> directories = itemBmpPreviewDirectories,
}) {
  final value = fileNameWithoutExtension.trim();
  if (value.isEmpty) return null;
  final fileName = value.toLowerCase().endsWith('.bmp') ? value : '$value.bmp';
  final key = _itemBmpPreviewKey(fileName);
  final selectedBytes = _selectedItemBmpPreviewBytes[key];
  if (selectedBytes != null) {
    debugLog(
      'itemBmpPreview resolved source=selected fileName=$fileName bytes=${selectedBytes.length}',
    );
    return itemBmpPreviewDataUri(selectedBytes);
  }
  for (final directory in directories) {
    final file = File(p.join(directory, fileName));
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      debugLog(
        'itemBmpPreview resolved source=directory fileName=$fileName '
        'path=${file.path} bytes=${bytes.length}',
      );
      return itemBmpPreviewDataUri(bytes);
    }
  }
  debugLog(
    'itemBmpPreview missing fileName=$fileName directories=${directories.join('|')}',
  );
  return null;
}

String _itemBmpPreviewKey(String value) {
  final fileName = p.basename(value.trim()).toLowerCase();
  return fileName.endsWith('.bmp') ? fileName : '$fileName.bmp';
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