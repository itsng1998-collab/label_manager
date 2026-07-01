import 'package:flutter/foundation.dart';

bool _fortuneSheetDebugLogEnabled = false;
@visibleForTesting
DebugPrintCallback? fortuneSheetDebugLogDebugPrintOverride;

bool get fortuneSheetDebugLogEnabled => _fortuneSheetDebugLogEnabled;

set fortuneSheetDebugLogEnabled(bool value) {
  _fortuneSheetDebugLogEnabled = value;
}

void fortuneSheetDebugLog(String message) {
  if (!_fortuneSheetDebugLogEnabled) {
    return;
  }
  final timestamp = DateTime.now().toIso8601String();
  (fortuneSheetDebugLogDebugPrintOverride ?? debugPrint)(
    '[$timestamp] $message',
  );
}
