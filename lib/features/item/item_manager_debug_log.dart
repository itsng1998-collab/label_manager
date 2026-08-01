import 'package:label_manager/utils/log_context.dart';

abstract final class ItemManagerDebugLog {
  static const String version = 'item-manager-debug-v18';
  static int _sequence = 0;

  static String nextTrace(String operation) {
    _sequence += 1;
    return '$operation-$_sequence';
  }

  static void event(
    String operation,
    String event, {
    String? trace,
    Map<String, Object?> fields = const {},
  }) {
    final details = fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    debugLog(
      '[$version] trace=${trace ?? '-'} operation=$operation event=$event'
      '${details.isEmpty ? '' : ' $details'}',
    );
  }
}
