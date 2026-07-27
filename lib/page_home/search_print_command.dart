import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

String searchPrintButtonLabel(bool active) => active ? '발행' : '검색';

bool searchPrintInputVisible({
  required bool active,
  required bool standardVisible,
}) => active || standardVisible;

bool searchPrintModeShortcutPressed({
  required LogicalKeyboardKey key,
  required bool modifierPressed,
}) => key == LogicalKeyboardKey.f12 && !modifierPressed;

Future<void> runSearchPrintInputCommand({
  required TextEditingController controller,
  required Future<void> Function(String query) issue,
}) async {
  final query = controller.text.trim();
  try {
    await issue(query);
  } finally {
    controller.clear();
  }
}