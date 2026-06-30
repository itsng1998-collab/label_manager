import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:printing/printing.dart';
import 'package:win32/win32.dart';

final DynamicLibrary _comdlg32 = DynamicLibrary.open('comdlg32.dll');
final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final _PrintDlgW _printDlgW = _comdlg32
    .lookupFunction<_PrintDlgWNative, _PrintDlgW>('PrintDlgW');
final _GlobalLock _globalLock = _kernel32
    .lookupFunction<_GlobalLockNative, _GlobalLock>('GlobalLock');
final _GlobalUnlock _globalUnlock = _kernel32
    .lookupFunction<_GlobalUnlockNative, _GlobalUnlock>('GlobalUnlock');
final _GlobalFree _globalFree = _kernel32
    .lookupFunction<_GlobalFreeNative, _GlobalFree>('GlobalFree');

const int _pdNoSelection = 0x00000004;
const int _pdNoPageNums = 0x00000008;
const int _pdReturnDc = 0x00000100;
const int _pdUseDevModeCopiesAndCollate = 0x00040000;
const int _pdDisablePrintToFile = 0x00080000;
const int _pdHidePrintToFile = 0x00100000;

typedef _PrintDlgWNative = Int32 Function(Pointer<_PrintDlgWStruct>);
typedef _PrintDlgW = int Function(Pointer<_PrintDlgWStruct>);
typedef _GlobalLockNative = Pointer<Void> Function(IntPtr);
typedef _GlobalLock = Pointer<Void> Function(int);
typedef _GlobalUnlockNative = Int32 Function(IntPtr);
typedef _GlobalUnlock = int Function(int);
typedef _GlobalFreeNative = IntPtr Function(IntPtr);
typedef _GlobalFree = int Function(int);

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

class RawPrinterWin32 {
  const RawPrinterWin32._();

  static Future<String?> showPrinterSetupDialog() async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'System printer dialog is only supported on Windows.',
      );
    }

    final printDlg = calloc<_PrintDlgWStruct>();
    try {
      printDlg.ref
        ..lStructSize = sizeOf<_PrintDlgWStruct>()
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

  static Future<void> sendRaw(Printer printer, Uint8List data) async {
    if (!Platform.isWindows) {
      throw UnsupportedError('Raw printing is only supported on Windows.');
    }
    // printing.Printer.name is non-nullable; avoid dead null-aware checks
    final String printerName = printer.name;
    if (printerName.isEmpty) {
      throw ArgumentError('Printer name is not available.');
    }
    if (data.isEmpty) {
      throw StateError('Empty printer command payload.');
    }

    final Pointer<HANDLE> phPrinter = calloc<HANDLE>();
    final Pointer<Utf16> namePtr = printerName.toNativeUtf16();
    try {
      final int openResult = OpenPrinter(namePtr, phPrinter, nullptr);
      if (openResult == 0) {
        throw StateError('OpenPrinter failed with error ${GetLastError()}');
      }

      final Pointer<DOC_INFO_1> docInfo = calloc<DOC_INFO_1>();
      final Pointer<Utf16> docName = 'Label Job'.toNativeUtf16();
      final Pointer<Utf16> dataType = 'RAW'.toNativeUtf16();
      docInfo.ref
        ..pDocName = docName
        ..pOutputFile = nullptr
        ..pDatatype = dataType;

      try {
        final int startDoc = StartDocPrinter(phPrinter.value, 1, docInfo);
        if (startDoc == 0) {
          throw StateError('StartDocPrinter failed (${GetLastError()})');
        }
        try {
          if (StartPagePrinter(phPrinter.value) == 0) {
            throw StateError('StartPagePrinter failed (${GetLastError()})');
          }

          final Pointer<Uint8> dataPtr = calloc<Uint8>(data.length);
          final Uint8List dataList = dataPtr.asTypedList(data.length);
          dataList.setAll(0, data);
          final Pointer<DWORD> written = calloc<DWORD>();
          try {
            final int writeResult = WritePrinter(
              phPrinter.value,
              dataPtr.cast(),
              data.length,
              written,
            );
            if (writeResult == 0 || written.value != data.length) {
              throw StateError('WritePrinter failed (${GetLastError()})');
            }
          } finally {
            calloc.free(written);
            calloc.free(dataPtr);
          }

          if (EndPagePrinter(phPrinter.value) == 0) {
            throw StateError('EndPagePrinter failed (${GetLastError()})');
          }
        } finally {
          EndDocPrinter(phPrinter.value);
        }
      } finally {
        calloc.free(docInfo);
        calloc.free(docName);
        calloc.free(dataType);
      }
    } finally {
      ClosePrinter(phPrinter.value);
      calloc.free(phPrinter);
      calloc.free(namePtr);
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
