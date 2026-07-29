import 'dart:async';

import 'package:flutter/material.dart';

class RtfPreviewAiConvertButton extends StatefulWidget {
  const RtfPreviewAiConvertButton({super.key, required this.onPressed});

  final FutureOr<void> Function() onPressed;

  @override
  State<RtfPreviewAiConvertButton> createState() =>
      _RtfPreviewAiConvertButtonState();
}

class _RtfPreviewAiConvertButtonState extends State<RtfPreviewAiConvertButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = _pressed
        ? const Color(0xFF9AA0A6)
        : _hovered
        ? const Color(0xFFDADCE0)
        : Colors.transparent;
    final textColor = _pressed
        ? const Color(0xFF202124)
        : _hovered
        ? const Color(0xFF3C4043)
        : const Color(0xFF5F6368);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: true,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () => widget.onPressed(),
        child: SizedBox(
          height: 14,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              'AI 변환',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
