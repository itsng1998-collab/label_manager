import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/printing/godex_korean_font_provisioner.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('full package write stores printer and port marker', () async {
    var sends = 0;
    final package = GodexKoreanFontPackage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      source: 'test.dat',
      fingerprint: 'test-hash',
    );
    final provisioner = GodexKoreanFontProvisioner(
      packageProvider: () async => package,
      rawSender: (printer, bytes) async {
        sends += 1;
        return RawPrinterWriteResult(
          jobId: 7,
          requestedBytes: bytes.length,
          writtenBytes: bytes.length,
        );
      },
    );
    const printer = Printer(url: 'g500', name: 'Godex G500');

    final installed = await provisioner.ensureInstalled(
      printer: printer,
      portName: 'USB001',
    );
    final reused = await provisioner.ensureInstalled(
      printer: printer,
      portName: 'USB001',
    );

    expect(installed.status, GodexKoreanFontProvisionStatus.installedByApp);
    expect(installed.canUseKoreanAsianFont, isTrue);
    expect(reused.status, GodexKoreanFontProvisionStatus.availableInstalled);
    expect(reused.canUseKoreanAsianFont, isTrue);
    expect(sends, 1);
  });

  test('partial package write does not store installation marker', () async {
    final package = GodexKoreanFontPackage(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      source: 'test.dat',
      fingerprint: 'test-hash',
    );
    final provisioner = GodexKoreanFontProvisioner(
      packageProvider: () async => package,
      rawSender: (printer, bytes) async => const RawPrinterWriteResult(
        jobId: 8,
        requestedBytes: 3,
        writtenBytes: 2,
      ),
    );

    final result = await provisioner.ensureInstalled(
      printer: const Printer(url: 'g500', name: 'Godex G500'),
      portName: 'USB001',
    );
    final preferences = await SharedPreferences.getInstance();

    expect(result.status, GodexKoreanFontProvisionStatus.installFailed);
    expect(result.canUseKoreanAsianFont, isFalse);
    expect(preferences.getString(result.markerKey), isNull);
  });

  test('missing package keeps Korean Asian font unavailable', () async {
    final provisioner = GodexKoreanFontProvisioner(
      packageProvider: () async => null,
      rawSender: (printer, bytes) => throw UnimplementedError(),
    );

    final result = await provisioner.ensureInstalled(
      printer: const Printer(url: 'g500', name: 'Godex G500'),
      portName: 'USB001',
    );

    expect(result.status, GodexKoreanFontProvisionStatus.packageMissing);
    expect(result.canUseKoreanAsianFont, isFalse);
  });
}