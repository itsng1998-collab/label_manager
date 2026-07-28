import 'package:flutter/material.dart';

class HorizontalPaneSplitter extends StatefulWidget {
  const HorizontalPaneSplitter({
    super.key,
    required this.height,
    required this.onDrag,
    this.onDragStart,
  });

  final double height;
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragStart;

  @override
  State<HorizontalPaneSplitter> createState() =>
      _HorizontalPaneSplitterState();
}

class _HorizontalPaneSplitterState extends State<HorizontalPaneSplitter> {
  double? _dragStartGlobalY;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (details) {
          _dragStartGlobalY = details.globalPosition.dy;
          widget.onDragStart?.call();
        },
        onVerticalDragUpdate: (details) {
          final startGlobalY = _dragStartGlobalY;
          if (startGlobalY == null) return;
          widget.onDrag(details.globalPosition.dy - startGlobalY);
        },
        onVerticalDragEnd: (_) => _dragStartGlobalY = null,
        onVerticalDragCancel: () => _dragStartGlobalY = null,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 2,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}