import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';

void main() {
  test('raw printing excludes Windows file ports', () {
    expect(RawPrinterWin32.isFilePortName('FILE:'), isTrue);
    expect(RawPrinterWin32.isFilePortName(' portprompt: '), isTrue);
    expect(RawPrinterWin32.isFilePortName('USB001'), isFalse);
    expect(RawPrinterWin32.isFilePortName('10.253.9.10'), isFalse);
    expect(RawPrinterWin32.isFilePortName(null), isFalse);
  });
}