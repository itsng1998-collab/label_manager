import 'fortune_debug_log_stub.dart'
    if (dart.library.io) 'fortune_debug_log_io.dart';

bool _fortuneSheetDebugLogEnabled = false;
bool _fortuneSheetDebugLogWasEnabled = false;

bool get fortuneSheetDebugLogEnabled => _fortuneSheetDebugLogEnabled;

set fortuneSheetDebugLogEnabled(bool value) {
  _fortuneSheetDebugLogEnabled = value;
  if (!value) {
    _fortuneSheetDebugLogWasEnabled = false;
  }
}

void fortuneSheetDebugLog(String message) {
  if (!_fortuneSheetDebugLogEnabled) {
    return;
  }
  final truncate = !_fortuneSheetDebugLogWasEnabled;
  _fortuneSheetDebugLogWasEnabled = true;
  final timestamp = DateTime.now().toIso8601String();
  writeFortuneSheetDebugLogLine('[$timestamp] $message', truncate: truncate);
}
