import 'dart:io';
import 'dart:typed_data';

import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String godexKoreanAsianFontPackageId = 'az1-korean-gulimche-16-v1';

enum GodexKoreanFontProvisionStatus {
  availableInstalled,
  installedByApp,
  packageMissing,
  installFailed,
}

class GodexKoreanFontPackage {
  const GodexKoreanFontPackage({
    required this.bytes,
    required this.source,
    required this.fingerprint,
  });

  final Uint8List bytes;
  final String source;
  final String fingerprint;
}

class GodexKoreanFontProvisionResult {
  const GodexKoreanFontProvisionResult({
    required this.status,
    required this.markerKey,
    this.package,
    this.writeResult,
    this.error,
  });

  final GodexKoreanFontProvisionStatus status;
  final String markerKey;
  final GodexKoreanFontPackage? package;
  final RawPrinterWriteResult? writeResult;
  final Object? error;

  bool get canUseKoreanAsianFont =>
      status == GodexKoreanFontProvisionStatus.availableInstalled ||
      status == GodexKoreanFontProvisionStatus.installedByApp;

  String get diagnostics =>
      'status=${status.name} package=$godexKoreanAsianFontPackageId '
      'markerKey=$markerKey source=${package?.source} '
      'fingerprint=${package?.fingerprint} bytes=${package?.bytes.length} '
      'write=${writeResult?.diagnostics} error=$error';
}

typedef GodexKoreanFontPackageProvider =
    Future<GodexKoreanFontPackage?> Function();
typedef GodexKoreanFontRawSender =
    Future<RawPrinterWriteResult> Function(Printer printer, Uint8List bytes);

class GodexKoreanFontProvisioner {
  const GodexKoreanFontProvisioner({
    required this.packageProvider,
    required this.rawSender,
  });

  final GodexKoreanFontPackageProvider packageProvider;
  final GodexKoreanFontRawSender rawSender;

  static GodexKoreanFontProvisioner production() =>
      GodexKoreanFontProvisioner(
        packageProvider: _loadOrCreatePackage,
        rawSender: RawPrinterWin32.sendRaw,
      );

  Future<GodexKoreanFontProvisionResult> ensureInstalled({
    required Printer printer,
    required String? portName,
  }) async {
    final markerKey = godexKoreanFontMarkerKey(
      printerName: printer.name,
      portName: portName,
    );
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(markerKey) == godexKoreanAsianFontPackageId) {
      return GodexKoreanFontProvisionResult(
        status: GodexKoreanFontProvisionStatus.availableInstalled,
        markerKey: markerKey,
      );
    }

    GodexKoreanFontPackage? package;
    try {
      package = await packageProvider();
      if (package == null) {
        return GodexKoreanFontProvisionResult(
          status: GodexKoreanFontProvisionStatus.packageMissing,
          markerKey: markerKey,
        );
      }
      final writeResult = await rawSender(printer, package.bytes);
      if (writeResult.writtenBytes != package.bytes.length) {
        throw StateError(
          'Godex Korean font package write was incomplete: '
          '${writeResult.writtenBytes}/${package.bytes.length}',
        );
      }
      await preferences.setString(markerKey, godexKoreanAsianFontPackageId);
      return GodexKoreanFontProvisionResult(
        status: GodexKoreanFontProvisionStatus.installedByApp,
        markerKey: markerKey,
        package: package,
        writeResult: writeResult,
      );
    } catch (error) {
      return GodexKoreanFontProvisionResult(
        status: GodexKoreanFontProvisionStatus.installFailed,
        markerKey: markerKey,
        package: package,
        error: error,
      );
    }
  }
}

String godexKoreanFontMarkerKey({
  required String printerName,
  required String? portName,
}) {
  final identity = '${printerName.trim().toLowerCase()}|'
      '${portName?.trim().toLowerCase() ?? ''}|'
      '$godexKoreanAsianFontPackageId';
  var hash = 0xcbf29ce484222325;
  for (final byte in identity.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x100000001b3).toUnsigned(64);
  }
  return 'godex_korean_font_${hash.toRadixString(16).padLeft(16, '0')}';
}

Future<GodexKoreanFontPackage?> _loadOrCreatePackage() async {
  if (!Platform.isWindows) return null;
  final executableDirectory = p.dirname(Platform.resolvedExecutable);
  final helperPath = p.join(executableDirectory, 'godex_font_helper.exe');
  final goLabelDirectory = _resolveGoLabelDirectory();
  if (!File(helperPath).existsSync() || goLabelDirectory == null) return null;

  final supportDirectory = await getApplicationSupportDirectory();
  final packageDirectory = Directory(
    p.join(
      supportDirectory.path,
      'godex_fonts',
      godexKoreanAsianFontPackageId,
    ),
  );
  await packageDirectory.create(recursive: true);
  final packageFile = File(p.join(packageDirectory.path, 'AZ_KO16x16.DAT'));
  if (!await packageFile.exists()) {
    final process = await Process.run(
      helperPath,
      <String>[goLabelDirectory, packageDirectory.path],
      runInShell: false,
    );
    if (process.exitCode != 0) {
      throw StateError(
        'GoLabel Korean font helper failed (${process.exitCode}): '
        '${process.stderr}',
      );
    }
  }

  final bytes = await packageFile.readAsBytes();
  if (!_isGodexKoreanPackage(bytes)) {
    throw StateError('GoLabel Korean font package header is invalid.');
  }
  return GodexKoreanFontPackage(
    bytes: bytes,
    source: packageFile.path,
    fingerprint: _fingerprint(bytes),
  );
}

String? _resolveGoLabelDirectory() {
  final roots = <String>{
    ?Platform.environment['ProgramFiles(x86)'],
    ?Platform.environment['ProgramFiles'],
    r'C:\Program Files (x86)',
  };
  for (final root in roots) {
    final candidate = p.join(root, 'GoDEX', 'GoLabel II');
    if (File(p.join(candidate, 'FontFile.dll')).existsSync() &&
        File(p.join(candidate, 'QlabelDlg.DLL')).existsSync()) {
      return candidate;
    }
  }
  return null;
}

bool _isGodexKoreanPackage(Uint8List bytes) {
  const header = <int>[
    0x0d,
    0x0a,
    0x7e,
    0x4d,
    0x44,
    0x45,
    0x4c,
    0x41,
    0x2c,
    0x31,
  ];
  if (bytes.length < 64) return false;
  for (var index = 0; index < header.length; index += 1) {
    if (bytes[index] != header[index]) return false;
  }
  return true;
}

String _fingerprint(Uint8List bytes) {
  var hash = 0xcbf29ce484222325;
  for (final byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x100000001b3).toUnsigned(64);
  }
  return 'fnv64:${hash.toRadixString(16).padLeft(16, '0')}';
}