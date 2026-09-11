import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

const int _cp949CodePage = 949;

typedef _MultiByteToWideCharNative =
    Int32 Function(
      Uint32 codePage,
      Uint32 flags,
      Pointer<Uint8> source,
      Int32 sourceLength,
      Pointer<Utf16> destination,
      Int32 destinationLength,
    );
typedef _MultiByteToWideCharDart =
    int Function(
      int codePage,
      int flags,
      Pointer<Uint8> source,
      int sourceLength,
      Pointer<Utf16> destination,
      int destinationLength,
    );

String decodeWindowsCp949(List<int> bytes) {
  if (!Platform.isWindows) {
    throw UnsupportedError('Windows CP949 decoder is only available on Windows.');
  }
  if (bytes.isEmpty) return '';

  final source = calloc<Uint8>(bytes.length);
  try {
    for (var index = 0; index < bytes.length; index += 1) {
      source[index] = bytes[index];
    }
    final convert = DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_MultiByteToWideCharNative, _MultiByteToWideCharDart>(
          'MultiByteToWideChar',
        );
    final length = convert(
      _cp949CodePage,
      0,
      source,
      bytes.length,
      nullptr,
      0,
    );
    if (length <= 0) {
      throw StateError('CP949 decoded length is zero.');
    }
    final destination = calloc<Uint16>(length).cast<Utf16>();
    try {
      final written = convert(
        _cp949CodePage,
        0,
        source,
        bytes.length,
        destination,
        length,
      );
      if (written != length) {
        throw StateError('CP949 decoded length mismatch: $written/$length');
      }
      return destination.toDartString(length: written);
    } finally {
      calloc.free(destination);
    }
  } finally {
    calloc.free(source);
  }
}
