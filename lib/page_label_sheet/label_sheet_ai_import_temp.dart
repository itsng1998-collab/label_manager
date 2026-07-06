import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

const String labelSheetAiImportTempVendorDirectory = 'com.itsng';
const String labelSheetAiImportTempAppDirectory = 'Label Manager';
const String labelSheetAiImportTempDirectoryName = 'temp';

Directory labelSheetAiImportTempDirectory({
  bool debugMode = kDebugMode,
  Map<String, String>? environment,
  String? currentDirectoryPath,
}) {
  if (debugMode) {
    return Directory(p.join(currentDirectoryPath ?? Directory.current.path, '.tmp'));
  }
  return labelSheetAiImportReleaseTempDirectory(
    environment: environment,
    currentDirectoryPath: currentDirectoryPath,
  );
}

Directory labelSheetAiImportReleaseTempDirectory({
  Map<String, String>? environment,
  String? currentDirectoryPath,
}) {
  final env = environment ?? Platform.environment;
  final appData = env['APPDATA']?.trim();
  final userProfile = env['USERPROFILE']?.trim();
  final basePath = appData != null && appData.isNotEmpty
      ? appData
      : userProfile != null && userProfile.isNotEmpty
      ? p.join(userProfile, 'AppData', 'Roaming')
      : currentDirectoryPath ?? Directory.current.path;
  return Directory(
    p.join(
      basePath,
      labelSheetAiImportTempVendorDirectory,
      labelSheetAiImportTempAppDirectory,
      labelSheetAiImportTempDirectoryName,
    ),
  );
}

Future<void> clearLabelSheetAiImportStartupTempDirectory({
  Map<String, String>? environment,
  String? currentDirectoryPath,
}) async {
  final directory = labelSheetAiImportReleaseTempDirectory(
    environment: environment,
    currentDirectoryPath: currentDirectoryPath,
  );
  if (!await directory.exists()) {
    await directory.create(recursive: true);
    return;
  }
  await for (final entity in directory.list(followLinks: false)) {
    await entity.delete(recursive: true);
  }
}