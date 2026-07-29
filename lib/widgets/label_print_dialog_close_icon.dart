import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class LabelPrintDialogCloseIcon extends StatelessWidget {
  const LabelPrintDialogCloseIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _LabelPrintDialogCloseIconPainter(),
    );
  }
}

class _LabelPrintDialogCloseIconPainter extends CustomPainter {
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
    covariant _LabelPrintDialogCloseIconPainter oldDelegate,
  ) => false;
}