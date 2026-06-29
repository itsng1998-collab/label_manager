import 'package:flutter/foundation.dart';

String runtimeLogName({StackTrace? stackTrace, int skipFrames = 0}) {
  final trace = (stackTrace ?? StackTrace.current).toString();
  final lines = trace.split('\n');
  var skipped = 0;
  for (final line in lines) {
    final member = _stackFrameMember(line);
    if (member == null || member.isEmpty) {
      continue;
    }
    if (_isLogContextMember(member)) {
      continue;
    }
    if (skipped < skipFrames) {
      skipped++;
      continue;
    }
    return _normalizeMember(member);
  }
  return 'Unknown.unknown';
}

String runtimeLogTag({StackTrace? stackTrace, int skipFrames = 0}) {
  return '[${runtimeLogName(stackTrace: stackTrace, skipFrames: skipFrames)}]';
}

String runtimeLogMessage(String message, {int skipFrames = 0}) {
  return '${runtimeLogName(skipFrames: skipFrames)}: $message';
}

void debugLog(String message, {int skipFrames = 0}) {
  debugPrint(runtimeLogMessage(message, skipFrames: skipFrames));
}

String? _stackFrameMember(String line) {
  final trimmed = line.trim();
  final match = RegExp(r'^#\d+\s+(.+?)\s+\(').firstMatch(trimmed);
  return match?.group(1);
}

bool _isLogContextMember(String member) {
  return member == 'runtimeLogName' ||
      member == 'runtimeLogTag' ||
      member == 'runtimeLogMessage' ||
      member == 'debugLog' ||
      member.startsWith('_stackFrameMember') ||
      member.startsWith('_isLogContextMember') ||
      member.startsWith('_normalizeMember');
}

String _normalizeMember(String member) {
  var value = member.trim();
  value = value.replaceAll('.<anonymous closure>', '');
  value = value.replaceAll('<anonymous closure>', '');
  value = value.replaceAll('.<fn>', '');
  value = value.replaceAll('<fn>', '');
  while (value.contains('..')) {
    value = value.replaceAll('..', '.');
  }
  return value.endsWith('.') ? value.substring(0, value.length - 1) : value;
}
