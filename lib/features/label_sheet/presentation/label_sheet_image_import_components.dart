import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabelSheetImageImportApiKeyField extends StatelessWidget {
  const LabelSheetImageImportApiKeyField({
    required this.controller,
    required this.enabled,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, control: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            const _BlockedApiKeyClipboardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
            const _BlockedApiKeyClipboardIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BlockedApiKeyClipboardIntent:
              CallbackAction<_BlockedApiKeyClipboardIntent>(
                onInvoke: (_) => null,
              ),
        },
        child: TextField(
          controller: controller,
          enabled: enabled,
          obscureText: true,
          enableInteractiveSelection: true,
          contextMenuBuilder: _apiKeyPasteOnlyContextMenuBuilder,
          decoration: labelSheetImageImportInputDecoration('Gemini API Key'),
        ),
      ),
    );
  }
}

class _BlockedApiKeyClipboardIntent extends Intent {
  const _BlockedApiKeyClipboardIntent();
}

Widget _apiKeyPasteOnlyContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final buttonItems = editableTextState.contextMenuButtonItems
      .where(
        (item) =>
            item.type != ContextMenuButtonType.copy &&
            item.type != ContextMenuButtonType.cut,
      )
      .toList(growable: false);
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

class LabelSheetImageImportFooterButton extends StatelessWidget {
  const LabelSheetImageImportFooterButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF1F3F4),
        foregroundColor: const Color(0xff111111),
        side: const BorderSide(color: Color(0xffc7c7c7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class LabelSheetImageImportCloseIcon extends StatelessWidget {
  const LabelSheetImageImportCloseIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _LabelSheetImageImportCloseIconPainter(),
    );
  }
}

class _LabelSheetImageImportCloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glyphRect = ui.Rect.fromCenter(
      center: ui.Offset(size.width / 2, size.height / 2),
      width: 11,
      height: 11,
    );
    final paint = Paint()
      ..color = const Color(0xff9a9a9a)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(glyphRect.topLeft, glyphRect.bottomRight, paint);
    canvas.drawLine(glyphRect.topRight, glyphRect.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(
    covariant _LabelSheetImageImportCloseIconPainter oldDelegate,
  ) {
    return false;
  }
}

InputDecoration labelSheetImageImportInputDecoration(
  String labelText, {
  bool alignLabelWithHint = false,
}) {
  return InputDecoration(
    labelText: labelText,
    alignLabelWithHint: alignLabelWithHint,
    isDense: true,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  );
}

class LabelSheetImageImportErrorPanel extends StatelessWidget {
  const LabelSheetImageImportErrorPanel({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message?.trim();
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
