import 'package:flutter/material.dart';

class VerticalPaneSplitter extends StatelessWidget {
  const VerticalPaneSplitter({
    super.key,
    required this.width,
    required this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onDragCancel,
    this.onDoubleTap,
  });

  final double width;
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => onDragStart?.call(),
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        onHorizontalDragEnd: (_) => onDragEnd?.call(),
        onHorizontalDragCancel: onDragCancel,
        onDoubleTap: onDoubleTap,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            border: Border(
              left: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 36,
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