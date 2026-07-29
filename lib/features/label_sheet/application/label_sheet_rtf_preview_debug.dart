import 'package:label_manager/utils/log_context.dart';

bool labelSheetRtfPreviewDebugLogEnabled = const bool.fromEnvironment(
  'LABEL_MANAGER_RTF_PREVIEW_DEBUG',
);

void labelSheetRtfPreviewDebugLog(String message, {int skipFrames = 0}) {
  if (!labelSheetRtfPreviewDebugLogEnabled) {
    return;
  }
  debugLog(message, skipFrames: skipFrames + 1);
}