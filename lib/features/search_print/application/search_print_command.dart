import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:label_manager/core/app_menu_command.dart';

String searchPrintButtonLabel(bool active) => active ? '발행' : '검색';

bool searchPrintInputVisible({
  required bool active,
  required bool standardVisible,
}) => active || standardVisible;

bool searchPrintModeShortcutPressed({
  required LogicalKeyboardKey key,
  required bool modifierPressed,
}) => key == LogicalKeyboardKey.f12 && !modifierPressed;

Set<AppMenuCommandId> searchPrintModeBlockedMenuCommands(bool active) =>
    active
    ? {
        for (final command in appMenuCommands)
          if (command.id != AppMenuCommandId.searchPrintMode) command.id,
      }
    : const {};

bool searchPrintModeBlocksHomeShortcut({
  required bool active,
  required LogicalKeyboardKey key,
}) =>
    active &&
    (key == LogicalKeyboardKey.f1 ||
        key == LogicalKeyboardKey.f2 ||
        key == LogicalKeyboardKey.f3 ||
        key == LogicalKeyboardKey.f5);

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