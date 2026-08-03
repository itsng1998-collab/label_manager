import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';

final DynamicLibrary _comdlg32 = DynamicLibrary.open('comdlg32.dll');
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');
final DynamicLibrary _winspool = DynamicLibrary.open('winspool.drv');

final _PrintDlgW _printDlgW = _comdlg32
    .lookupFunction<_PrintDlgWNative, _PrintDlgW>('PrintDlgW');
final _GlobalAlloc _globalAlloc = _kernel32
  .lookupFunction<_GlobalAllocNative, _GlobalAlloc>('GlobalAlloc');
final _GlobalLock _globalLock = _kernel32
    .lookupFunction<_GlobalLockNative, _GlobalLock>('GlobalLock');
final _GlobalUnlock _globalUnlock = _kernel32
    .lookupFunction<_GlobalUnlockNative, _GlobalUnlock>('GlobalUnlock');
final _GlobalFree _globalFree = _kernel32
    .lookupFunction<_GlobalFreeNative, _GlobalFree>('GlobalFree');
final _GetPrinterW _getPrinterW = _winspool
  .lookupFunction<_GetPrinterWNative, _GetPrinterW>('GetPrinterW');

const int _pdNoSelection = 0x00000004;
const int _pdNoPageNums = 0x00000008;
const int _pdReturnDc = 0x00000100;
const int _pdUseDevModeCopiesAndCollate = 0x00040000;
const int _pdDisablePrintToFile = 0x00080000;
const int _pdHidePrintToFile = 0x00100000;
const int _gmemMoveable = 0x0002;
const int _gmemZeroInit = 0x0040;

typedef _PrintDlgWNative = Int32 Function(Pointer<_PrintDlgWStruct>);
typedef _PrintDlgW = int Function(Pointer<_PrintDlgWStruct>);
typedef _GlobalAllocNative = IntPtr Function(Uint32, IntPtr);
typedef _GlobalAlloc = int Function(int, int);
typedef _GlobalLockNative = Pointer<Void> Function(IntPtr);
typedef _GlobalLock = Pointer<Void> Function(int);
typedef _GlobalUnlockNative = Int32 Function(IntPtr);
typedef _GlobalUnlock = int Function(int);
typedef _GlobalFreeNative = IntPtr Function(IntPtr);
typedef _GlobalFree = int Function(int);
typedef _GetPrinterWNative = Int32 Function(
  IntPtr,
  Uint32,
  Pointer<Uint8>,
  Uint32,
  Pointer<Uint32>,
);
typedef _GetPrinterW = int Function(
  int,
  int,
  Pointer<Uint8>,
  int,
  Pointer<Uint32>,
);

final class _PrintDlgWStruct extends Struct {
  @Uint32()
  external int lStructSize;
  @IntPtr()
  external int hwndOwner;
  @IntPtr()
  external int hDevMode;
  @IntPtr()
  external int hDevNames;
  @IntPtr()
  external int hDC;
  @Uint32()
  external int flags;
  @Uint16()
  external int nFromPage;
  @Uint16()
  external int nToPage;
  @Uint16()
  external int nMinPage;
  @Uint16()
  external int nMaxPage;
  @Uint16()
  external int nCopies;
  @IntPtr()
  external int hInstance;
  @IntPtr()
  external int lCustData;
  @IntPtr()
  external int lpfnPrintHook;
  @IntPtr()
  external int lpfnSetupHook;
  @IntPtr()
  external int lpPrintTemplateName;
  @IntPtr()
  external int lpSetupTemplateName;
  @IntPtr()
  external int hPrintTemplate;
  @IntPtr()
  external int hSetupTemplate;
}

final class _DevNamesStruct extends Struct {
  @Uint16()
  external int wDriverOffset;
  @Uint16()
  external int wDeviceOffset;
  @Uint16()
  external int wOutputOffset;
  @Uint16()
  external int wDefault;
}

final class _PrinterInfo2Struct extends Struct {
  external Pointer<Utf16> pServerName;
  external Pointer<Utf16> pPrinterName;
  external Pointer<Utf16> pShareName;
  external Pointer<Utf16> pPortName;
  external Pointer<Utf16> pDriverName;
  external Pointer<Utf16> pComment;
  external Pointer<Utf16> pLocation;
  external Pointer<Void> pDevMode;
  external Pointer<Utf16> pSepFile;
  external Pointer<Utf16> pPrintProcessor;
  external Pointer<Utf16> pDatatype;
  external Pointer<Utf16> pParameters;
  external Pointer<Void> pSecurityDescriptor;

  @Uint32()
  external int attributes;
  @Uint32()
  external int priority;
  @Uint32()
  external int defaultPriority;
  @Uint32()
  external int startTime;
  @Uint32()
  external int untilTime;
  @Uint32()
  external int status;
  @Uint32()
  external int jobCount;
  @Uint32()
  external int averagePagesPerMinute;
}

class RawPrinterWin32 {
  const RawPrinterWin32._();

  static bool isFilePortName(String? portName) {
    final normalized = portName?.trim().toUpperCase();
    return normalized == 'FILE:' || normalized == 'PORTPROMPT:';
  }

  static Future<String?> showPrinterSetupDialog({String? initialPrinterName}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'System printer dialog is only supported on Windows.',
      );
    }

    final printDlg = calloc<_PrintDlgWStruct>();
    try {
      final initialDevNames = _createDevNames(initialPrinterName);
      printDlg.ref
        ..lStructSize = sizeOf<_PrintDlgWStruct>()
        ..hDevNames = initialDevNames
        ..flags =
            _pdReturnDc |
            _pdNoSelection |
            _pdNoPageNums |
            _pdUseDevModeCopiesAndCollate |
            _pdDisablePrintToFile |
            _pdHidePrintToFile
        ..nCopies = 1;

      final result = _printDlgW(printDlg);
      if (result == 0) {
        return null;
      }
      return _printerNameFromDevNames(printDlg.ref.hDevNames);
    } finally {
      if (printDlg.ref.hDC != 0) {
        DeleteDC(printDlg.ref.hDC);
      }
      if (printDlg.ref.hDevMode != 0) {
        _globalFree(printDlg.ref.hDevMode);
      }
      if (printDlg.ref.hDevNames != 0) {
        _globalFree(printDlg.ref.hDevNames);
      }
      calloc.free(printDlg);
    }
  }

  static String? _printerNameFromDevNames(int hDevNames) {
    if (hDevNames == 0) {
      return null;
    }
    final memory = _globalLock(hDevNames);
    if (memory == nullptr) {
      return null;
    }
    try {
      final devNames = memory.cast<_DevNamesStruct>().ref;
      return _readNullTerminatedUtf16(
        memory.cast<Uint16>() + devNames.wDeviceOffset,
      );
    } finally {
      _globalUnlock(hDevNames);
    }
  }

  static int _createDevNames(String? printerName) {
    final normalizedName = printerName?.trim() ?? '';
    if (normalizedName.isEmpty) return 0;

    final printerHandle = calloc<HANDLE>();
    final printerNamePointer = normalizedName.toNativeUtf16();
    try {
      if (OpenPrinter(printerNamePointer, printerHandle, nullptr) == 0) {
        return 0;
      }
      final bytesNeeded = calloc<Uint32>();
      try {
        _getPrinterW(printerHandle.value, 2, nullptr, 0, bytesNeeded);
        if (bytesNeeded.value == 0) return 0;
        final printerInfoBuffer = calloc<Uint8>(bytesNeeded.value);
        try {
          if (_getPrinterW(
                printerHandle.value,
                2,
                printerInfoBuffer,
                bytesNeeded.value,
                bytesNeeded,
              ) ==
              0) {
            return 0;
          }
          final printerInfo = printerInfoBuffer.cast<_PrinterInfo2Struct>().ref;
          if (printerInfo.pPrinterName == nullptr ||
              printerInfo.pPortName == nullptr) {
            return 0;
          }
          return _allocateDevNames(
            driverName: 'WINSPOOL',
            deviceName: printerInfo.pPrinterName.toDartString(),
            outputName: printerInfo.pPortName.toDartString(),
          );
        } finally {
          calloc.free(printerInfoBuffer);
        }
      } finally {
        calloc.free(bytesNeeded);
      }
    } finally {
      if (printerHandle.value != 0) {
        ClosePrinter(printerHandle.value);
      }
      calloc.free(printerHandle);
      calloc.free(printerNamePointer);
    }
  }

  static int _allocateDevNames({
    required String driverName,
    required String deviceName,
    required String outputName,
  }) {
    final headerUnits = sizeOf<_DevNamesStruct>() ~/ sizeOf<Uint16>();
    final driverOffset = headerUnits;
    final deviceOffset = driverOffset + driverName.codeUnits.length + 1;
    final outputOffset = deviceOffset + deviceName.codeUnits.length + 1;
    final totalUnits = outputOffset + outputName.codeUnits.length + 1;
    final handle = _globalAlloc(
      _gmemMoveable | _gmemZeroInit,
      totalUnits * sizeOf<Uint16>(),
    );
    if (handle == 0) return 0;

    final memory = _globalLock(handle);
    if (memory == nullptr) {
      _globalFree(handle);
      return 0;
    }
    try {
      memory.cast<_DevNamesStruct>().ref
        ..wDriverOffset = driverOffset
        ..wDeviceOffset = deviceOffset
        ..wOutputOffset = outputOffset
        ..wDefault = 0;
      final units = memory.cast<Uint16>();
      _writeNullTerminatedUtf16(units + driverOffset, driverName);
      _writeNullTerminatedUtf16(units + deviceOffset, deviceName);
      _writeNullTerminatedUtf16(units + outputOffset, outputName);
    } finally {
      _globalUnlock(handle);
    }
    return handle;
  }

  static void _writeNullTerminatedUtf16(
    Pointer<Uint16> destination,
    String value,
  ) {
    final codeUnits = value.codeUnits;
    for (var index = 0; index < codeUnits.length; index += 1) {
      (destination + index).value = codeUnits[index];
    }
    (destination + codeUnits.length).value = 0;
  }

  static String _readNullTerminatedUtf16(Pointer<Uint16> pointer) {
    final units = <int>[];
    for (var index = 0; ; index += 1) {
      final unit = (pointer + index).value;
      if (unit == 0) {
        break;
      }
      units.add(unit);
    }
    return String.fromCharCodes(units);
  }

  static Future<String?> queryPrinterPortName(Printer printer) async {
    if (!Platform.isWindows || printer.name.isEmpty) return null;

    final printerHandle = calloc<HANDLE>();
    final printerName = printer.name.toNativeUtf16();
    try {
      if (OpenPrinter(printerName, printerHandle, nullptr) == 0) {
        return null;
      }
      final bytesNeeded = calloc<Uint32>();
      try {
        _getPrinterW(printerHandle.value, 2, nullptr, 0, bytesNeeded);
        if (bytesNeeded.value == 0) return null;
        final buffer = calloc<Uint8>(bytesNeeded.value);
        try {
          final result = _getPrinterW(
            printerHandle.value,
            2,
            buffer,
            bytesNeeded.value,
            bytesNeeded,
          );
          if (result == 0) return null;
          final portName = buffer.cast<_PrinterInfo2Struct>().ref.pPortName;
          return portName == nullptr ? null : portName.toDartString();
        } finally {
          calloc.free(buffer);
        }
      } finally {
        calloc.free(bytesNeeded);
      }
    } finally {
      if (printerHandle.value != 0) {
        ClosePrinter(printerHandle.value);
      }
      calloc.free(printerHandle);
      calloc.free(printerName);
    }
  }

  static Future<int?> queryPrinterDpi(Printer printer) async {
    if (!Platform.isWindows) return null;
    final String printerName = printer.name;
    if (printerName.isEmpty) {
      return null;
    }

    final Pointer<Utf16> driverPtr = 'WINSPOOL'.toNativeUtf16();
    final Pointer<Utf16> devicePtr = printerName.toNativeUtf16();
    try {
      final int hdc = CreateDC(driverPtr, devicePtr, nullptr, nullptr);
      if (hdc == 0) {
        return null;
      }
      try {
        final int dpiX = GetDeviceCaps(hdc, LOGPIXELSX);
        final int dpiY = GetDeviceCaps(hdc, LOGPIXELSY);
        int? dpi;
        if (dpiX > 0 && dpiY > 0) {
          dpi = ((dpiX + dpiY) / 2).round();
        } else if (dpiX > 0) {
          dpi = dpiX;
        } else if (dpiY > 0) {
          dpi = dpiY;
        }
        return dpi;
      } finally {
        DeleteDC(hdc);
      }
    } finally {
      calloc.free(driverPtr);
      calloc.free(devicePtr);
    }
  }
}
