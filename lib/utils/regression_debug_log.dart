import 'package:flutter/foundation.dart';
import 'package:label_manager/utils/log_context.dart';

abstract final class RegressionDebugLog {
  static const String version = 'regression-debug-v1';

  @visibleForTesting
  static String message(
    String feature,
    String event, {
    Map<String, Object?> fields = const {},
  }) {
    final details = fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    return '[$version] feature=$feature event=$event'
        '${details.isEmpty ? '' : ' $details'}';
  }

  static void event(
    String feature,
    String event, {
    Map<String, Object?> fields = const {},
  }) {
    debugLog(message(feature, event, fields: fields));
  }
}