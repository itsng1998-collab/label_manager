import 'dart:async';

import 'package:flutter/material.dart';
import 'package:label_manager/utils/log_context.dart';

int _blockingModelessOverlayDialogSequence = 0;

/// Shared wrapper for every modeless dialog overlay in Label Manager.
///
/// Use this as the root widget of `OverlayEntry.builder` for modeless dialogs.
/// It keeps the dialog modeless in structure, but blocks pointer/touch input and
/// unhandled key events from reaching widgets behind the overlay. Programmatic
/// callbacks, notifiers, and parent-state updates triggered from inside the
/// dialog are not blocked.
class BlockingModelessDialog extends StatefulWidget {
  const BlockingModelessDialog({
    super.key,
    required this.child,
    this.barrierColor = const Color(0x8A000000),
  });

  final Widget child;
  final Color barrierColor;

  @override
  State<BlockingModelessDialog> createState() => _BlockingModelessDialogState();
}

/// Shows a confirmation/warning dialog above modeless settings overlays.
///
/// Brand/label settings are inserted as `OverlayEntry`s. A normal `showDialog`
/// can be placed below an already inserted modeless entry, so confirmations
/// launched from those settings must use this helper instead.
Future<T?> showBlockingModelessOverlayDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, void Function(T? result) close)
  builder,
  Color barrierColor = const Color(0x8A000000),
}) {
  final dialogId = ++_blockingModelessOverlayDialogSequence;
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<T?>();
  late final OverlayEntry entry;

  debugLog(
    'blockingOverlayDialog#$dialogId create overlay=${identityHashCode(overlay)} '
    'context=${context.runtimeType} barrierColor=$barrierColor',
  );

  void close(T? result) {
    debugLog(
      'blockingOverlayDialog#$dialogId close requested '
      'completed=${completer.isCompleted} mounted=${entry.mounted} result=$result',
    );
    if (completer.isCompleted) {
      return;
    }
    if (entry.mounted) {
      entry.remove();
      debugLog('blockingOverlayDialog#$dialogId entry removed');
    } else {
      debugLog(
        'blockingOverlayDialog#$dialogId entry remove skipped mounted=false',
      );
    }
    completer.complete(result);
    debugLog('blockingOverlayDialog#$dialogId completed result=$result');
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      debugLog(
        'blockingOverlayDialog#$dialogId build '
        'overlayContext=${overlayContext.runtimeType}',
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(dismissible: false, color: barrierColor),
          Center(
            child: Material(
              type: MaterialType.transparency,
              child: builder(overlayContext, close),
            ),
          ),
        ],
      );
    },
  );
  debugLog('blockingOverlayDialog#$dialogId insert start');
  overlay.insert(entry);
  debugLog(
    'blockingOverlayDialog#$dialogId insert done mounted=${entry.mounted}',
  );
  return completer.future;
}

class _BlockingModelessDialogState extends State<BlockingModelessDialog> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'BlockingModelessDialogScope',
  );
  final FocusNode _focusNode = FocusNode(debugLabel: 'BlockingModelessDialog');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scopeNode,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ModalBarrier(dismissible: false, color: widget.barrierColor),
            widget.child,
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}

class BlockingModelessDialogFrame extends StatelessWidget {
  const BlockingModelessDialogFrame({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    required this.onClose,
    required this.child,
    this.footer,
    this.closeIcon = const Icon(Icons.close, size: 18),
    this.closeEnabled = true,
  });

  final String title;
  final double width;
  final double height;
  final VoidCallback onClose;
  final Widget child;
  final Widget? footer;
  final Widget closeIcon;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Color(0xffece6f0),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BlockingModelessDialogTitleBar(
                  title: title,
                  closeIcon: closeIcon,
                  onClose: closeEnabled ? onClose : null,
                ),
                Expanded(child: child),
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockingModelessDialogTitleBar extends StatelessWidget {
  const _BlockingModelessDialogTitleBar({
    required this.title,
    required this.closeIcon,
    required this.onClose,
  });

  final String title;
  final Widget closeIcon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: '닫기',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            icon: closeIcon,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
