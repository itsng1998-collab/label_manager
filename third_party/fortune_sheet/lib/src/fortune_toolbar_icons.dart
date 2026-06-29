import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class FortuneToolbarIconPainter {
  const FortuneToolbarIconPainter._();

  static const Color iconColor = Color(0xff525c6f);
  static const Color textIconColor = Color(0xff394259);
  static const Color mutedStrokeColor = Color(0xffccced2);
  static const Color comboArrowColor = Color(0xffa6a6a6);
  static const Color _printPaperLineColor = Color(0xffffffff);

  static const Set<String> supportedIconIds = {
    'undo',
    'redo',
    'format-painter',
    'clear-format',
    'currency-format',
    'percentage-format',
    'number-decrease',
    'number-increase',
    'format',
    'font',
    'font-size',
    'bold',
    'italic',
    'strike-through',
    'underline',
    'font-color',
    'background',
    'border',
    'merge-cell',
    'merge-all',
    'merge-vertical',
    'merge-horizontal',
    'merge-cancel',
    'horizontal-align',
    'align-left',
    'align-center',
    'align-right',
    'vertical-align',
    'valign-top',
    'valign-middle',
    'valign-bottom',
    'text-wrap',
    'wrap-clip',
    'wrap-overflow',
    'wrap-wrap',
    'text-rotation',
    'rotate-none',
    'rotate-up',
    'rotate-down',
    'rotate-vertical',
    'rotate-up-90',
    'rotate-down-90',
    'freeze',
    'freeze-row',
    'freeze-col',
    'freeze-row-col',
    'freeze-cancel',
    'conditionFormat',
    'condition-format',
    'filter',
    'sort-asc',
    'sort-desc',
    'filter1',
    'filter-create',
    'filter-clear',
    'eraser',
    'link',
    'image',
    'import-image',
    'save',
    'barcode',
    'comment',
    'quick-formula',
    'formula-sum',
    'dataVerification',
    'data-verification',
    'splitColumn',
    'locationCondition',
    'location-condition',
    'screenshot',
    'search',
    'hidden',
    'print',
    'more',
    'combo-arrow',
  };

  static const Set<String> comboIconIds = {
    'format',
    'font',
    'font-size',
    'font-color',
    'background',
    'border',
    'merge-cell',
    'horizontal-align',
    'vertical-align',
    'text-wrap',
    'text-rotation',
    'freeze',
    'conditionFormat',
    'filter',
    'comment',
    'quick-formula',
    'locationCondition',
  };

  static void draw(
    Canvas canvas,
    String id,
    Rect rect, {
    Color? accentColor,
    String currency = '¥',
  }) {
    final normalizedId = _normalize(id);
    if (normalizedId == 'combo-arrow') {
      canvas.save();
      canvas.translate(rect.left, rect.top);
      canvas.scale(rect.width / 10, rect.height / 24);
      final path = Path()
        ..moveTo(8, 10)
        ..lineTo(2, 10)
        ..lineTo(5, 14)
        ..close();
      canvas.drawPath(path, Paint()..color = comboArrowColor);
      canvas.restore();
      return;
    }
    final paint = Paint()
      ..color = iconColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    final fill = Paint()
      ..color = iconColor
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / 24, rect.height / 24);

    switch (normalizedId) {
      case 'undo':
        _undo(canvas, paint, left: true);
        break;
      case 'redo':
        _undo(canvas, paint, left: false);
        break;
      case 'format-painter':
        _formatPainter(canvas, paint, fill);
        break;
      case 'clear-format':
        _eraser(canvas, paint);
        break;
      case 'currency-format':
        _currency(canvas, currency);
        break;
      case 'percentage-format':
        _percent(canvas, paint, fill);
        break;
      case 'number-decrease':
        _numberDelta(canvas, paint, decrease: true);
        break;
      case 'number-increase':
        _numberDelta(canvas, paint, decrease: false);
        break;
      case 'format':
        _compactNumberLabel(canvas, '123', const Offset(4.2, 9.2));
        _line(canvas, paint, const Offset(4, 18), const Offset(20, 18));
        break;
      case 'font':
        _letterA(canvas, const Rect.fromLTWH(5.5, 4.5, 13, 15));
        break;
      case 'font-size':
        _compactNumberLabel(canvas, '11', const Offset(4.2, 9.4));
        _upDown(canvas, paint, 18);
        break;
      case 'bold':
        _letterB(canvas);
        break;
      case 'italic':
        _italic(canvas, fill);
        break;
      case 'strike-through':
        _letterS(canvas);
        _filledRect(
          canvas,
          const Rect.fromLTWH(6, 11.5, 13, 1.5),
          textIconColor,
        );
        break;
      case 'underline':
        _letterU(canvas, dy: 1);
        _filledRect(
          canvas,
          const Rect.fromLTWH(7, 18.5, 10, 1.5),
          textIconColor,
        );
        break;
      case 'font-color':
        _letterA(canvas, const Rect.fromLTWH(7, 4.5, 10, 11));
        _filledRect(
          canvas,
          const Rect.fromLTWH(5, 20, 14, 2),
          accentColor ?? iconColor,
        );
        break;
      case 'background':
        _bucket(canvas, paint, fill, accentColor: accentColor);
        break;
      case 'border':
        _borderAllIcon(canvas, paint);
        break;
      case 'merge-cell':
      case 'merge-all':
        _merge(canvas, paint);
        break;
      case 'merge-vertical':
        _mergeVertical(canvas);
        break;
      case 'merge-horizontal':
        _mergeHorizontal(canvas);
        break;
      case 'merge-cancel':
        _mergeCancel(canvas);
        break;
      case 'horizontal-align':
      case 'align-left':
        _alignLeft(canvas, paint);
        break;
      case 'align-center':
        _alignCenter(canvas, paint);
        break;
      case 'align-right':
        _alignRight(canvas, paint);
        break;
      case 'vertical-align':
      case 'valign-top':
        _alignTop(canvas, paint, fill);
        break;
      case 'valign-middle':
        _alignMiddle(canvas);
        break;
      case 'valign-bottom':
        _alignBottom(canvas);
        break;
      case 'text-wrap':
      case 'wrap-wrap':
        _textWrap(canvas, paint);
        break;
      case 'wrap-overflow':
        _textOverflow(canvas, paint);
        break;
      case 'wrap-clip':
        _textClip(canvas);
        break;
      case 'text-rotation':
      case 'rotate-none':
        _textRotationNone(canvas);
        break;
      case 'rotate-up':
        _textRotationSvg(canvas, _textRotationAngleUpPath);
        break;
      case 'rotate-down':
        _textRotationSvg(canvas, _textRotationAngleDownPath);
        break;
      case 'rotate-vertical':
        _textRotationSvg(canvas, _textRotationVerticalPath);
        break;
      case 'rotate-up-90':
        _textRotationSvg(canvas, _textRotationUpPath);
        break;
      case 'rotate-down-90':
        _textRotationSvg(canvas, _textRotationDownPath);
        break;
      case 'freeze':
      case 'freeze-row-col':
        _freezeRowCol(canvas, paint);
        break;
      case 'freeze-row':
        _freezeRow(canvas, paint);
        break;
      case 'freeze-col':
        _freezeCol(canvas, paint);
        break;
      case 'freeze-cancel':
        _freezeCancel(canvas, paint);
        break;
      case 'conditionFormat':
        _conditionFormat(canvas, paint, fill);
        break;
      case 'filter':
        _filter(canvas, paint, fill);
        break;
      case 'sort-asc':
        _svgPaths(canvas, _sortAscPaths);
        break;
      case 'sort-desc':
        _svgPaths(canvas, _sortDescPaths);
        break;
      case 'filter1':
      case 'filter-create':
        _svgPaths(canvas, const [_filter1Path]);
        break;
      case 'eraser':
      case 'filter-clear':
        _svgPaths(canvas, const [_eraserPath]);
        break;
      case 'link':
        _link(canvas, paint);
        break;
      case 'image':
        _image(canvas, paint);
        break;
      case 'import-image':
        _importImage(canvas, paint);
        break;
      case 'save':
        _save(canvas, paint);
        break;
      case 'barcode':
        _barcode(canvas, paint);
        break;
      case 'comment':
        _comment(canvas, paint);
        break;
      case 'quick-formula':
      case 'formula-sum':
        _sigma(canvas);
        break;
      case 'dataVerification':
        _shieldCheck(canvas, paint);
        break;
      case 'splitColumn':
        _splitColumn(canvas, paint);
        break;
      case 'locationCondition':
        _locationCondition(canvas, paint);
        break;
      case 'screenshot':
        _screenshotCrop(canvas, paint);
        break;
      case 'search':
        _search(canvas, paint);
        break;
      case 'hidden':
        _hidden(canvas, paint);
        break;
      case 'print':
        _print(canvas, paint);
        break;
      case 'combo-arrow':
        break;
      case 'more':
        _more(canvas, fill);
        break;
      default:
        _defaultIcon(canvas, paint);
    }

    canvas.restore();
  }

  static String _normalize(String id) {
    return switch (id) {
      'condition-format' => 'conditionFormat',
      'data-verification' => 'dataVerification',
      'location-condition' => 'locationCondition',
      _ => id,
    };
  }

  static void _undo(Canvas canvas, Paint paint, {required bool left}) {
    final path = Path();
    if (left) {
      path
        ..moveTo(3.5, 7.75)
        ..lineTo(7.2, 10.84)
        ..lineTo(7.2, 8.5)
        ..lineTo(13.25, 8.5)
        ..cubicTo(15.46, 8.5, 17.25, 10.29, 17.25, 12.5)
        ..cubicTo(17.25, 14.71, 15.46, 16.5, 13.25, 16.5)
        ..lineTo(7, 16.5)
        ..lineTo(7, 18)
        ..lineTo(13.25, 18)
        ..cubicTo(16.29, 18, 18.75, 15.54, 18.75, 12.5)
        ..cubicTo(18.75, 9.46, 16.29, 7, 13.25, 7)
        ..lineTo(7.2, 7)
        ..lineTo(7.2, 4.67)
        ..close();
    } else {
      path
        ..moveTo(20.5, 7.75)
        ..lineTo(16.8, 10.84)
        ..lineTo(16.8, 8.5)
        ..lineTo(10.75, 8.5)
        ..cubicTo(8.54, 8.5, 6.75, 10.29, 6.75, 12.5)
        ..cubicTo(6.75, 14.71, 8.54, 16.5, 10.75, 16.5)
        ..lineTo(17, 16.5)
        ..lineTo(17, 18)
        ..lineTo(10.75, 18)
        ..cubicTo(7.71, 18, 5.25, 15.54, 5.25, 12.5)
        ..cubicTo(5.25, 9.46, 7.71, 7, 10.75, 7)
        ..lineTo(16.8, 7)
        ..lineTo(16.8, 4.67)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = iconColor);
  }

  static void _formatPainter(Canvas canvas, Paint paint, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5.4, 5, 11.2, 6.3),
        const Radius.circular(1.5),
      ),
      paint,
    );
    _line(canvas, paint, const Offset(15.3, 8.15), const Offset(18.47, 8.15));
    _line(canvas, paint, const Offset(18.47, 8.15), const Offset(18.47, 13.13));
    _line(canvas, paint, const Offset(18.47, 13.13), const Offset(10.07, 14.2));
    _line(canvas, paint, const Offset(10.07, 14.2), const Offset(10.07, 19));
  }

  static void _eraser(Canvas canvas, Paint paint) {
    _line(canvas, paint, const Offset(8, 18.25), const Offset(20, 18.25));
    final body = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(14, 7.12132)
      ..lineTo(17.8787, 11)
      ..lineTo(10, 18.8787)
      ..lineTo(6.12132, 15)
      ..lineTo(14, 7.12132)
      ..close()
      ..moveTo(14, 5)
      ..lineTo(15.0607, 6.06066)
      ..lineTo(18.9393, 9.93934)
      ..lineTo(20, 11)
      ..lineTo(18.9393, 12.0607)
      ..lineTo(12, 19)
      ..lineTo(8, 19)
      ..lineTo(5.06066, 16.0607)
      ..lineTo(4, 15)
      ..lineTo(5.06066, 13.9393)
      ..lineTo(12.9393, 6.06066)
      ..lineTo(14, 5)
      ..close();
    canvas.drawPath(body, Paint()..color = iconColor);
    canvas.save();
    canvas.translate(13.9375, 6.12316);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 6.98528, 5.7265),
      Paint()
        ..color = iconColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  static void _percent(Canvas canvas, Paint paint, Paint fill) {
    _line(
      canvas,
      paint..strokeWidth = 1.7,
      const Offset(19, 5),
      const Offset(5, 19),
    );
    canvas.drawCircle(const Offset(8, 8), 2.1, paint..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(16, 16), 2.1, paint);
  }

  static void _numberDelta(
    Canvas canvas,
    Paint paint, {
    required bool decrease,
  }) {
    if (decrease) {
      _decimalDotZero(canvas, secondZero: false);
      _decimalArrow(canvas, left: true);
      return;
    }
    _decimalDotZero(canvas, secondZero: true);
    _decimalArrow(canvas, left: false);
  }

  static void _decimalDotZero(Canvas canvas, {required bool secondZero}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3.0, 12.0, 2.0, 2.0),
        const Radius.circular(0.45),
      ),
      Paint()..color = iconColor,
    );
    _decimalZero(canvas, const Rect.fromLTWH(6.52, 3.96, 6.62, 9.62));
    if (secondZero) {
      _decimalZero(canvas, const Rect.fromLTWH(14.36, 3.96, 6.62, 9.62));
    }
  }

  static void _decimalZero(Canvas canvas, Rect rect) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2)))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + 2.05,
            rect.top + 1.65,
            rect.width - 4.1,
            rect.height - 3.3,
          ),
          Radius.circular((rect.width - 4.1) / 2),
        ),
      );
    canvas.drawPath(path, Paint()..color = iconColor);
  }

  static void _decimalArrow(Canvas canvas, {required bool left}) {
    final path = Path();
    if (left) {
      path
        ..moveTo(16.5, 20.0)
        ..lineTo(16.5, 18.23)
        ..lineTo(21.0, 18.23)
        ..lineTo(21.0, 16.88)
        ..lineTo(16.6, 16.88)
        ..lineTo(16.6, 15.0)
        ..lineTo(14.06, 17.43)
        ..close();
    } else {
      path
        ..moveTo(18.5, 15.0)
        ..lineTo(18.5, 16.88)
        ..lineTo(14.0, 16.88)
        ..lineTo(14.0, 18.23)
        ..lineTo(18.5, 18.23)
        ..lineTo(18.5, 20.0)
        ..lineTo(20.94, 17.43)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = iconColor);
  }

  static void _bucket(
    Canvas canvas,
    Paint paint,
    Paint fill, {
    Color? accentColor,
  }) {
    final path = Path()
      ..moveTo(15.66, 15.56)
      ..cubicTo(16.51, 15.56, 17.21, 14.85, 17.21, 13.98)
      ..cubicTo(17.21, 12.94, 15.66, 11.23, 15.66, 11.23)
      ..cubicTo(15.66, 11.23, 14.1, 12.94, 14.1, 13.98)
      ..cubicTo(14.1, 14.85, 14.8, 15.56, 15.66, 15.56)
      ..moveTo(8.25, 14.69)
      ..cubicTo(8.39, 14.83, 8.61, 14.83, 8.75, 14.69)
      ..lineTo(13.77, 9.67)
      ..cubicTo(13.9, 9.53, 13.9, 9.31, 13.77, 9.17)
      ..lineTo(8.75, 4.15)
      ..lineTo(7.22, 2.62)
      ..cubicTo(7.15, 2.55, 7.04, 2.55, 6.97, 2.62)
      ..lineTo(6.03, 3.56)
      ..cubicTo(5.96, 3.63, 5.96, 3.74, 6.03, 3.81)
      ..lineTo(7.35, 5.13)
      ..lineTo(3.27, 9.21)
      ..cubicTo(3.13, 9.35, 3.13, 9.57, 3.27, 9.71)
      ..lineTo(8.25, 14.69)
      ..moveTo(8.5, 5.93)
      ..lineTo(12.0, 9.44)
      ..lineTo(5.0, 9.44)
      ..close();
    canvas.drawPath(path, Paint()..color = iconColor);
    _filledRect(
      canvas,
      const Rect.fromLTWH(2.35, 17.96, 15.37, 1.88),
      accentColor ?? iconColor,
    );
  }

  static void _borderAllIcon(Canvas canvas, Paint paint) {
    canvas.drawRect(const Rect.fromLTWH(5.75, 5.75, 12.5, 12.5), paint);
    _line(canvas, paint, const Offset(6.5, 12), const Offset(17.5, 12));
    _line(canvas, paint, const Offset(12, 17.5), const Offset(12, 6.5));
  }

  static void _merge(Canvas canvas, Paint paint) {
    final fill = Paint()..color = iconColor;
    final leftArrow = Path()
      ..moveTo(15.5, 14.9998)
      ..lineTo(12, 11.9996)
      ..lineTo(15.5, 8.99982)
      ..close();
    final rightArrow = Path()
      ..moveTo(8.5, 14.9998)
      ..lineTo(12, 11.9996)
      ..lineTo(8.5, 8.99982)
      ..close();
    canvas.drawPath(leftArrow, fill);
    canvas.drawPath(rightArrow, fill);
    _filledRect(canvas, const Rect.fromLTWH(7, 11.2498, 2.5, 1.5), iconColor);
    _filledRect(
      canvas,
      const Rect.fromLTWH(14.5, 11.2498, 2.5, 1.5),
      iconColor,
    );
    final frame = Path()
      ..moveTo(9.5, 6.49982)
      ..lineTo(6.5, 6.49982)
      ..lineTo(6.5, 17.4998)
      ..lineTo(9.5, 17.4998)
      ..lineTo(9.5, 15.4999)
      ..lineTo(11, 15.4999)
      ..lineTo(11, 18.9998)
      ..lineTo(5, 18.9998)
      ..lineTo(5, 4.99982)
      ..lineTo(11, 4.99982)
      ..lineTo(11, 8.49988)
      ..lineTo(9.5, 8.49988)
      ..close()
      ..moveTo(13, 15.4999)
      ..lineTo(14.5, 15.4999)
      ..lineTo(14.5, 17.4998)
      ..lineTo(17.5, 17.4998)
      ..lineTo(17.5, 6.49982)
      ..lineTo(14.5, 6.49982)
      ..lineTo(14.5, 8.49988)
      ..lineTo(13, 8.49988)
      ..lineTo(13, 4.99982)
      ..lineTo(19, 4.99982)
      ..lineTo(19, 18.9998)
      ..lineTo(13, 18.9998)
      ..close();
    canvas.drawPath(frame, fill);
  }

  static void _mergeCancel(Canvas canvas) {
    final fill = Paint()..color = iconColor;
    final rightArrow = Path()
      ..moveTo(13, 14.9998)
      ..lineTo(16.5, 11.9996)
      ..lineTo(13, 8.99982)
      ..close();
    final leftArrow = Path()
      ..moveTo(11, 14.9998)
      ..lineTo(7.5, 11.9996)
      ..lineTo(11, 8.99982)
      ..close();
    canvas.drawPath(rightArrow, fill);
    canvas.drawPath(leftArrow, fill);
    _filledRect(canvas, const Rect.fromLTWH(10, 11.2498, 4.5, 1.5), iconColor);
    final frame = Path()
      ..moveTo(9.5, 6.49982)
      ..lineTo(6.5, 6.49982)
      ..lineTo(6.5, 17.4998)
      ..lineTo(9.5, 17.4998)
      ..lineTo(9.5, 15.4999)
      ..lineTo(11, 15.4999)
      ..lineTo(11, 18.9998)
      ..lineTo(5, 18.9998)
      ..lineTo(5, 4.99982)
      ..lineTo(11, 4.99982)
      ..lineTo(11, 8.49988)
      ..lineTo(9.5, 8.49988)
      ..close()
      ..moveTo(13, 15.4999)
      ..lineTo(13, 18.9998)
      ..lineTo(19, 18.9998)
      ..lineTo(19, 4.99982)
      ..lineTo(13, 4.99982)
      ..lineTo(13, 8.49988)
      ..lineTo(14.5, 8.49988)
      ..lineTo(14.5, 6.49982)
      ..lineTo(17.5, 6.49982)
      ..lineTo(17.5, 17.4998)
      ..lineTo(14.5, 17.4998)
      ..lineTo(14.5, 15.9998)
      ..lineTo(14.5, 15.4999)
      ..close();
    canvas.drawPath(frame, fill);
  }

  static void _mergeHorizontal(Canvas canvas) {
    final fill = Paint()..color = iconColor;
    final arrow = Path()
      ..moveTo(11, 15)
      ..lineTo(14.5, 11.9998)
      ..lineTo(11, 9)
      ..close();
    canvas.drawPath(arrow, fill);
    _filledRect(canvas, const Rect.fromLTWH(5, 11.25, 8.5, 1.5), iconColor);
    final frame = Path()
      ..moveTo(11, 5)
      ..lineTo(5, 5)
      ..lineTo(5, 19)
      ..lineTo(11, 19)
      ..lineTo(11, 17.5)
      ..lineTo(6.5, 17.5)
      ..lineTo(6.5, 6.5)
      ..lineTo(11, 6.5)
      ..close()
      ..moveTo(13, 16)
      ..lineTo(14.5, 16)
      ..lineTo(14.5, 17.5)
      ..lineTo(17.5, 17.5)
      ..lineTo(17.5, 6.5)
      ..lineTo(14.5, 6.5)
      ..lineTo(14.5, 8.5)
      ..lineTo(13, 8.5)
      ..lineTo(13, 5)
      ..lineTo(19, 5)
      ..lineTo(19, 19)
      ..lineTo(13, 19)
      ..close();
    canvas.drawPath(frame, fill);
  }

  static void _mergeVertical(Canvas canvas) {
    final fill = Paint()..color = iconColor;
    final arrow = Path()
      ..moveTo(9, 10.9998)
      ..lineTo(12.0002, 14.4998)
      ..lineTo(15, 10.9998)
      ..close();
    canvas.drawPath(arrow, fill);
    _filledRect(
      canvas,
      const Rect.fromLTWH(11.25, 4.99982, 1.5, 8.5),
      iconColor,
    );
    final frame = Path()
      ..moveTo(17.5, 6.49982)
      ..lineTo(6.5, 6.49982)
      ..lineTo(6.5, 10.9998)
      ..lineTo(5, 10.9998)
      ..lineTo(5, 4.99982)
      ..lineTo(19, 4.99982)
      ..lineTo(19, 10.9998)
      ..lineTo(17.5, 10.9998)
      ..close()
      ..moveTo(8, 12.9998)
      ..lineTo(8.5, 12.9998)
      ..lineTo(8.5, 14.4998)
      ..lineTo(6.5, 14.4998)
      ..lineTo(6.5, 17.4998)
      ..lineTo(17.5, 17.4998)
      ..lineTo(17.5, 14.4998)
      ..lineTo(15.5, 14.4998)
      ..lineTo(15.5, 12.9998)
      ..lineTo(19, 12.9998)
      ..lineTo(19, 18.9998)
      ..lineTo(5, 18.9998)
      ..lineTo(5, 12.9998)
      ..close();
    canvas.drawPath(frame, fill);
  }

  static void _alignLeft(Canvas canvas, Paint paint) {
    _line(canvas, paint, const Offset(5, 6.75), const Offset(19, 6.75));
    _line(canvas, paint, const Offset(5, 12), const Offset(13, 12));
    _line(canvas, paint, const Offset(5, 17.25), const Offset(19, 17.25));
  }

  static void _alignCenter(Canvas canvas, Paint paint) {
    _line(canvas, paint, const Offset(5, 6.75), const Offset(19, 6.75));
    _line(canvas, paint, const Offset(8, 12), const Offset(16, 12));
    _line(canvas, paint, const Offset(5, 17.25), const Offset(19, 17.25));
  }

  static void _alignRight(Canvas canvas, Paint paint) {
    _line(canvas, paint, const Offset(5, 6.75), const Offset(19, 6.75));
    _line(canvas, paint, const Offset(11, 12), const Offset(19, 12));
    _line(canvas, paint, const Offset(5, 17.25), const Offset(19, 17.25));
  }

  static void _alignTop(Canvas canvas, Paint paint, Paint fill) {
    final arrow = Path()
      ..moveTo(9.25, 11)
      ..lineTo(12.0002, 8)
      ..lineTo(14.75, 11)
      ..close();
    canvas.drawPath(arrow, Paint()..color = iconColor);
    _filledRect(canvas, const Rect.fromLTWH(5.5, 5.5, 13, 1.5), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(11.25, 10.5, 1.5, 7.5), iconColor);
  }

  static void _alignMiddle(Canvas canvas) {
    final topArrow = Path()
      ..moveTo(9.25, 16.5)
      ..lineTo(12.0002, 13.5)
      ..lineTo(14.75, 16.5)
      ..close();
    final bottomArrow = Path()
      ..moveTo(9.25, 7)
      ..lineTo(12.0002, 10)
      ..lineTo(14.75, 7)
      ..close();
    canvas.drawPath(topArrow, Paint()..color = iconColor);
    canvas.drawPath(bottomArrow, Paint()..color = iconColor);
    _filledRect(canvas, const Rect.fromLTWH(5.5, 11, 13, 1.5), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(11.25, 16, 1.5, 3.5), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(11.25, 4, 1.5, 3.5), iconColor);
  }

  static void _alignBottom(Canvas canvas) {
    final arrow = Path()
      ..moveTo(9.25, 12.5)
      ..lineTo(12.0002, 15.5)
      ..lineTo(14.75, 12.5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = iconColor);
    _filledRect(canvas, const Rect.fromLTWH(5.5, 16.5, 13, 1.5), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(11.25, 5.5, 1.5, 7.5), iconColor);
  }

  static void _textWrap(Canvas canvas, Paint paint) {
    _line(canvas, paint, const Offset(4.75, 5), const Offset(4.75, 19));
    _line(canvas, paint, const Offset(19.25, 5), const Offset(19.25, 19));
    final path = Path()
      ..moveTo(7, 16.25)
      ..lineTo(9.99, 13.5)
      ..lineTo(9.99, 15.5)
      ..lineTo(12, 15.5)
      ..cubicTo(13.93, 15.5, 15.5, 13.93, 15.5, 12)
      ..cubicTo(15.5, 10.07, 13.93, 8.5, 12, 8.5)
      ..lineTo(7, 8.5)
      ..lineTo(7, 7)
      ..lineTo(12, 7)
      ..cubicTo(14.76, 7, 17, 9.24, 17, 12)
      ..cubicTo(17, 14.76, 14.76, 17, 12, 17)
      ..lineTo(9.99, 17)
      ..lineTo(9.99, 19)
      ..close();
    canvas.drawPath(path, Paint()..color = iconColor);
  }

  static void _textOverflow(Canvas canvas, Paint paint) {
    final arrow = Path()
      ..moveTo(16.5, 15)
      ..lineTo(20, 11.9998)
      ..lineTo(16.5, 9)
      ..close();
    canvas.drawPath(arrow, Paint()..color = iconColor);
    _filledRect(canvas, const Rect.fromLTWH(7, 11.25, 9.5, 1.5), iconColor);
    _line(canvas, paint, const Offset(4.75, 5), const Offset(4.75, 19));
    _line(canvas, paint, const Offset(12.25, 5), const Offset(12.25, 9.5));
    _line(canvas, paint, const Offset(12.25, 14.5), const Offset(12.25, 19));
  }

  static void _textClip(Canvas canvas) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final path = Path()
      ..moveTo(217.6, 810.666667)
      ..lineTo(294.4, 810.666667)
      ..cubicTo(296.756, 810.666667, 298.666667, 808.756, 298.666667, 806.4)
      ..lineTo(298.666667, 217.6)
      ..cubicTo(298.666667, 215.244, 296.756, 213.333333, 294.4, 213.333333)
      ..lineTo(217.6, 213.333333)
      ..cubicTo(215.244, 213.333333, 213.333333, 215.244, 213.333333, 217.6)
      ..lineTo(213.333333, 806.4)
      ..cubicTo(213.333333, 808.756, 215.244, 810.666667, 217.6, 810.666667)
      ..close()
      ..moveTo(725.333333, 217.6)
      ..lineTo(725.333333, 465.066667)
      ..cubicTo(
        725.333333,
        467.422667,
        723.422667,
        469.333333,
        721.066667,
        469.333333,
      )
      ..lineTo(388.266667, 469.333333)
      ..cubicTo(385.910667, 469.333333, 384, 471.244, 384, 473.6)
      ..lineTo(384, 550.4)
      ..cubicTo(384, 552.756, 385.910667, 554.666667, 388.266667, 554.666667)
      ..lineTo(721.066667, 554.666667)
      ..cubicTo(
        723.422667,
        554.666667,
        725.333333,
        556.577333,
        725.333333,
        558.933333,
      )
      ..lineTo(725.333333, 806.4)
      ..cubicTo(725.333333, 808.756, 727.244, 810.666667, 729.6, 810.666667)
      ..lineTo(806.4, 810.666667)
      ..cubicTo(808.756, 810.666667, 810.666667, 808.756, 810.666667, 806.4)
      ..lineTo(810.666667, 217.6)
      ..cubicTo(810.666667, 215.244, 808.756, 213.333333, 806.4, 213.333333)
      ..lineTo(729.6, 213.333333)
      ..cubicTo(727.244, 213.333333, 725.333333, 215.244, 725.333333, 217.6)
      ..close();
    canvas.drawPath(path, Paint()..color = iconColor);
    canvas.restore();
  }

  static const String _textRotationAngleUpPath =
      'M634.311111 398.222222c17.066667-17.066667 11.377778-45.511111-11.377778-54.044444L196.266667 170.666667c-35.555556-14.222222-69.688889 21.333333-55.466667 55.466666l172.088889 426.666667c8.533333 22.755556 38.4 28.444444 54.044444 11.377778 9.955556-9.955556 12.8-24.177778 7.111111-36.977778l-39.822222-91.022222 170.666667-170.666667 91.022222 39.822222c12.8 4.266667 28.444444 2.844444 38.4-7.111111z m-322.844444 81.066667l-105.244445-243.2L449.422222 341.333333l-137.955555 137.955556zM696.888889 393.955556c0 15.644444 12.8 28.444444 28.444444 28.444444h64L403.911111 807.822222c-11.377778 11.377778-11.377778 28.444444 0 39.822222 11.377778 11.377778 28.444444 11.377778 39.822222 0l385.422223-385.422222V526.222222c0 15.644444 12.8 28.444444 28.444444 28.444445s28.444444-12.8 28.444444-28.444445v-133.688889c0-15.644444-12.8-28.444444-28.444444-28.444444h-133.688889c-14.222222 1.422222-27.022222 14.222222-27.022222 29.866667z';

  static const String _textRotationAngleDownPath =
      'M625.777778 634.311111c17.066667 17.066667 45.511111 11.377778 54.044444-11.377778l172.088889-426.666666c14.222222-35.555556-21.333333-69.688889-55.466667-55.466667L371.2 312.888889c-22.755556 8.533333-28.444444 38.4-11.377778 54.044444 9.955556 9.955556 24.177778 12.8 36.977778 7.111111l91.022222-39.822222 170.666667 170.666667-39.822222 92.444444c-4.266667 11.377778-2.844444 27.022222 7.111111 36.977778z m-81.066667-322.844444l243.2-105.244445L682.666667 449.422222l-137.955556-137.955555zM630.044444 696.888889c-15.644444 0-28.444444 12.8-28.444444 28.444444v64L216.177778 403.911111c-11.377778-11.377778-28.444444-11.377778-39.822222 0-11.377778 11.377778-11.377778 28.444444 0 39.822222l385.422222 385.422223H497.777778c-15.644444 0-28.444444 12.8-28.444445 28.444444s12.8 28.444444 28.444445 28.444444h133.688889c15.644444 0 28.444444-12.8 28.444444-28.444444v-133.688889c-1.422222-14.222222-14.222222-27.022222-29.866667-27.022222z';

  static const String _textRotationVerticalPath =
      'M465.066667 672.711111c-24.177778 0-39.822222-24.177778-31.288889-46.933333l179.2-423.822222c14.222222-34.133333 64-34.133333 78.222222 0L871.822222 625.777778c9.955556 22.755556-7.111111 46.933333-31.288889 46.933333-14.222222 0-25.6-8.533333-31.288889-21.333333l-36.977777-92.444445H531.911111l-36.977778 92.444445c-4.266667 12.8-17.066667 21.333333-29.866666 21.333333z m285.866666-170.666667L652.8 256 554.666667 502.044444h196.266666zM157.866667 704c11.377778-11.377778 28.444444-11.377778 39.822222 0l45.511111 45.511111V204.8c0-15.644444 12.8-28.444444 28.444444-28.444444s28.444444 12.8 28.444445 28.444444v544.711111l45.511111-45.511111c11.377778-11.377778 28.444444-11.377778 39.822222 0 11.377778 11.377778 11.377778 28.444444 0 39.822222L292.977778 839.111111c-11.377778 11.377778-28.444444 11.377778-39.822222 0l-93.866667-93.866667c-12.8-11.377778-12.8-29.866667-1.422222-41.244444z';

  static const String _textRotationUpPath =
      'M620.088889 366.933333c0-24.177778-24.177778-39.822222-46.933333-31.288889L150.755556 514.844444c-34.133333 14.222222-34.133333 64 0 78.222223l423.822222 179.2c22.755556 9.955556 46.933333-7.111111 46.933333-31.288889 0-14.222222-8.533333-25.6-21.333333-31.288889l-92.444445-36.977778V433.777778l92.444445-36.977778c11.377778-4.266667 19.911111-17.066667 19.911111-29.866667z m-170.666667 285.866667L203.377778 554.666667l246.044444-98.133334v196.266667zM662.755556 320c11.377778 11.377778 28.444444 11.377778 39.822222 0l45.511111-45.511111v544.711111c0 15.644444 12.8 28.444444 28.444444 28.444444s28.444444-12.8 28.444445-28.444444V274.488889l45.511111 45.511111c11.377778 11.377778 28.444444 11.377778 39.822222 0 11.377778-11.377778 11.377778-28.444444 0-39.822222L796.444444 184.888889c-11.377778-11.377778-28.444444-11.377778-39.822222 0l-93.866666 93.866667c-11.377778 11.377778-11.377778 29.866667 0 41.244444z';

  static const String _textRotationDownPath =
      'M403.911111 657.066667c0 24.177778 24.177778 39.822222 46.933333 31.288889L873.244444 509.155556c34.133333-14.222222 34.13333299-64 0-78.222223L450.844444 250.311111c-22.755556-9.955556-46.933333 7.111111-46.933333 31.288889 0 14.222222 8.533333 25.6 21.333333 31.288889l92.444445 36.977778-1e-8 240.355555-92.44444499 36.977778c-12.8 4.266667-21.333333 17.066667-21.333333 29.866667z m170.666667-285.86666701L820.622222 469.33333299l-246.044444 98.13333401L574.577778 371.19999999zM361.244444 704c-11.377778-11.377778-28.444444-11.377778-39.822222 0l-45.511111 45.511111L275.911111 204.79999999c0-15.644444-12.8-28.444444-28.44444399-28.44444399s-28.444444 12.8-28.44444501 28.444444l-1e-8 544.711111-45.51111099-45.511111c-11.377778-11.377778-28.444444-11.377778-39.822222 0-11.377778 11.377778-11.377778 28.444444 0 39.822222L227.555556 839.111111c11.377778 11.377778 28.444444 11.377778 39.822222-1e-8l93.866666-93.86666699c11.377778-11.377778 11.377778-29.866667 0-41.244444z';

  static const List<String> _sortAscPaths = [
    'M839.6 433.8L749 150.5c-1.2-3.9-4.8-6.5-8.9-6.5h-77.4c-4.1 0-7.6 2.6-8.9 6.5l-91.3 283.3c-0.3 0.9-0.5 1.9-0.5 2.9 0 5.1 4.2 9.3 9.3 9.3h56.4c4.2 0 7.8-2.8 9-6.8l17.5-61.6h89l17.3 61.5c1.1 4 4.8 6.8 9 6.8h61.2c1 0 1.9-0.1 2.8-0.4 2.4-0.8 4.3-2.4 5.5-4.6 1.1-2.2 1.3-4.7 0.6-7.1zM663.3 325.5l32.8-116.9h6.3l32.1 116.9h-71.2z',
    'M806.8 818.4H677.2v-0.4l132.6-188.9c1.1-1.6 1.7-3.4 1.7-5.4v-36.4c0-5.1-4.2-9.3-9.3-9.3h-204c-5.1 0-9.3 4.2-9.3 9.3v43c0 5.1 4.2 9.3 9.3 9.3h122.6v0.4L587.7 828.9c-1.1 1.6-1.7 3.4-1.7 5.4v36.4c0 5.1 4.2 9.3 9.3 9.3h211.4c5.1 0 9.3-4.2 9.3-9.3v-43c0.1-5.1-4.1-9.3-9.2-9.3z',
    'M310.3 167.1c-3.2-4.1-9.4-4.1-12.6 0L185.7 309c-4.2 5.3-0.4 13 6.3 13h76v530c0 4.4 3.6 8 8 8h56c4.4 0 8-3.6 8-8V322h76c6.7 0 10.5-7.8 6.3-13l-112-141.9z',
  ];

  static const List<String> _sortDescPaths = [
    'M839.6 433.8L749 150.5c-1.2-3.9-4.8-6.5-8.9-6.5h-77.4c-4.1 0-7.6 2.6-8.9 6.5l-91.3 283.3c-0.3 0.9-0.5 1.9-0.5 2.9 0 5.1 4.2 9.3 9.3 9.3h56.4c4.2 0 7.8-2.8 9-6.8l17.5-61.6h89l17.3 61.5c1.1 4 4.8 6.8 9 6.8h61.2c1 0 1.9-0.1 2.8-0.4 2.4-0.8 4.3-2.4 5.5-4.6 1.1-2.2 1.3-4.7 0.6-7.1zM663.3 325.5l32.8-116.9h6.3l32.1 116.9h-71.2z',
    'M806.8 818.4H677.2v-0.4l132.6-188.9c1.1-1.6 1.7-3.4 1.7-5.4v-36.4c0-5.1-4.2-9.3-9.3-9.3h-204c-5.1 0-9.3 4.2-9.3 9.3v43c0 5.1 4.2 9.3 9.3 9.3h122.6v0.4L587.7 828.9c-1.1 1.6-1.7 3.4-1.7 5.4v36.4c0 5.1 4.2 9.3 9.3 9.3h211.4c5.1 0 9.3-4.2 9.3-9.3v-43c0.1-5.1-4.1-9.3-9.2-9.3z',
    'M416 702h-76V172c0-4.4-3.6-8-8-8h-56c-4.4 0-8 3.6-8 8v530h-76c-6.7 0-10.5 7.8-6.3 13l112 141.9c3.2 4.1 9.4 4.1 12.6 0l112-141.9c4.1-5.2 0.4-13-6.3-13z',
  ];

  static const String _importImagePath =
      'M 6 101 L 0 112 L 0 485 L 5 495 L 10 499 L 18 502 L 389 502 L 397 499 L 403 493 L 406 487 L 406 482 L 407 481 L 407 249 L 408 248 L 489 248 L 490 247 L 495 247 L 502 244 L 507 239 L 511 230 L 511 27 L 508 19 L 499 11 L 492 9 L 139 9 L 129 13 L 122 21 L 120 27 L 120 94 L 119 95 L 20 95 L 12 97 Z M 42 138 L 43 137 L 119 137 L 120 138 L 120 229 L 124 239 L 131 245 L 142 248 L 231 248 L 232 249 L 232 273 L 178 313 L 175 312 L 159 289 L 155 285 L 147 284 L 143 287 L 95 396 L 95 403 L 99 408 L 104 409 L 105 408 L 113 408 L 114 407 L 122 407 L 123 406 L 131 406 L 132 405 L 140 405 L 141 404 L 149 404 L 150 403 L 158 403 L 159 402 L 167 402 L 168 401 L 176 401 L 177 400 L 185 400 L 186 399 L 194 399 L 195 398 L 203 398 L 204 397 L 224 395 L 228 390 L 228 384 L 209 358 L 208 355 L 279 303 L 283 299 L 284 296 L 284 249 L 285 248 L 364 248 L 365 249 L 365 459 L 364 460 L 43 460 L 42 459 Z';

    static const String _savePath =
      'M 62 60 L 51 74 L 47 82 L 43 96 L 43 415 L 47 429 L 51 437 L 60 449 L 74 460 L 82 464 L 96 468 L 415 468 L 429 464 L 437 460 L 448 452 L 460 437 L 464 429 L 468 415 L 468 166 L 464 151 L 456 137 L 432 112 L 375 56 L 362 48 L 345 43 L 96 43 L 82 47 L 74 51 Z M 88 79 L 99 74 L 148 74 L 149 75 L 149 152 L 151 162 L 158 175 L 169 185 L 181 190 L 186 191 L 325 191 L 336 188 L 342 185 L 353 175 L 358 167 L 361 158 L 361 153 L 362 152 L 362 89 L 363 88 L 432 157 L 437 169 L 437 411 L 432 423 L 423 432 L 411 437 L 384 437 L 383 436 L 383 335 L 382 330 L 378 320 L 368 308 L 356 301 L 349 299 L 162 299 L 153 302 L 143 308 L 138 313 L 131 324 L 128 335 L 128 436 L 127 437 L 100 437 L 96 436 L 88 432 L 79 423 L 74 411 L 74 99 L 79 88 Z M 163 332 L 167 330 L 344 330 L 348 332 L 352 338 L 352 436 L 351 437 L 160 437 L 159 436 L 159 338 Z M 180 75 L 181 74 L 330 74 L 331 75 L 331 150 L 329 155 L 322 160 L 189 160 L 185 158 L 182 155 L 180 150 Z';

  static const String _filter1Path =
      'M608 864C588.8 864 576 851.2 576 832L576 448c0-6.4 6.4-19.2 12.8-25.6L787.2 256c6.4-6.4 6.4-19.2 0-19.2 0-6.4-6.4-12.8-19.2-12.8L256 224c-12.8 0-19.2 6.4-19.2 12.8 0 6.4-6.4 12.8 6.4 19.2l198.4 166.4C441.6 428.8 448 441.6 448 448l0 256c0 19.2-12.8 32-32 32S384 723.2 384 704L384 460.8 198.4 307.2c-25.6-25.6-32-64-19.2-96C185.6 179.2 217.6 160 256 160L768 160c32 0 64 19.2 76.8 51.2 12.8 32 6.4 70.4-19.2 89.6l-192 160L633.6 832C640 851.2 627.2 864 608 864z';

  static const String _eraserPath =
      'M596.437333 85.333333a42.837333 42.837333 0 0 0-30.549333 13.824l-469.333333 512a42.666667 42.666667 0 0 0 1.28 59.008l170.666666 170.666667A42.496 42.496 0 0 0 298.666667 853.333333h512v-85.333333h-195.669334l311.168-311.168a42.538667 42.538667 0 0 0 0-60.330667l-298.666666-298.666666A43.221333 43.221333 0 0 0 596.437333 85.333333z m-102.144 682.666667H316.330667l-129.28-129.28 268.8-293.205333 230.485333 230.485333-192.042667 192z m252.373334-252.330667l-233.130667-233.130666 85.12-92.842667L835.669333 426.666667 746.666667 515.669333z';

  static void _svgPaths(Canvas canvas, List<String> pathData) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final paint = Paint()..color = const Color(0xff535a68);
    for (final path in pathData) {
      canvas.drawPath(_svgPath(path), paint);
    }
    canvas.restore();
  }

  static void _textRotationSvg(Canvas canvas, String pathData) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    canvas.drawPath(
      _svgPath(pathData),
      Paint()..color = const Color(0xff535a68),
    );
    canvas.restore();
  }

  static Path _svgPath(String data) {
    final tokens = RegExp(
      r'[MmLlHhVvCcSsAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
    ).allMatches(data).map((match) => match.group(0)!).toList();
    final path = Path();
    var index = 0;
    var command = '';
    var current = Offset.zero;
    var subpathStart = Offset.zero;
    Offset? lastCubicControl;

    bool isCommand(String token) => RegExp(r'^[A-Za-z]$').hasMatch(token);
    double number() => double.parse(tokens[index++]);

    while (index < tokens.length) {
      if (isCommand(tokens[index])) {
        command = tokens[index++];
      }
      if (command.isEmpty) {
        break;
      }
      final relative = command == command.toLowerCase();
      switch (command.toUpperCase()) {
        case 'M':
          final point = Offset(number(), number());
          current = relative ? current + point : point;
          path.moveTo(current.dx, current.dy);
          subpathStart = current;
          lastCubicControl = null;
          command = relative ? 'l' : 'L';
          break;
        case 'L':
          final point = Offset(number(), number());
          current = relative ? current + point : point;
          path.lineTo(current.dx, current.dy);
          lastCubicControl = null;
          break;
        case 'H':
          final x = number();
          current = Offset(relative ? current.dx + x : x, current.dy);
          path.lineTo(current.dx, current.dy);
          lastCubicControl = null;
          break;
        case 'V':
          final y = number();
          current = Offset(current.dx, relative ? current.dy + y : y);
          path.lineTo(current.dx, current.dy);
          lastCubicControl = null;
          break;
        case 'C':
          final first = Offset(number(), number());
          final second = Offset(number(), number());
          final end = Offset(number(), number());
          final control1 = relative ? current + first : first;
          final control2 = relative ? current + second : second;
          final target = relative ? current + end : end;
          path.cubicTo(
            control1.dx,
            control1.dy,
            control2.dx,
            control2.dy,
            target.dx,
            target.dy,
          );
          current = target;
          lastCubicControl = control2;
          break;
        case 'S':
          final second = Offset(number(), number());
          final end = Offset(number(), number());
          final control1 = lastCubicControl == null
              ? current
              : Offset(
                  current.dx * 2 - lastCubicControl.dx,
                  current.dy * 2 - lastCubicControl.dy,
                );
          final control2 = relative ? current + second : second;
          final target = relative ? current + end : end;
          path.cubicTo(
            control1.dx,
            control1.dy,
            control2.dx,
            control2.dy,
            target.dx,
            target.dy,
          );
          current = target;
          lastCubicControl = control2;
          break;
        case 'A':
          final radiusX = number();
          final radiusY = number();
          final xAxisRotation = number();
          final largeArcFlag = number();
          final sweepFlag = number();
          final end = Offset(number(), number());
          final target = relative ? current + end : end;
          path.arcToPoint(
            target,
            radius: Radius.elliptical(radiusX.abs(), radiusY.abs()),
            rotation: xAxisRotation * math.pi / 180,
            largeArc: largeArcFlag != 0,
            clockwise: sweepFlag != 0,
          );
          current = target;
          lastCubicControl = null;
          break;
        case 'Z':
          path.close();
          current = subpathStart;
          lastCubicControl = null;
          command = '';
          break;
        default:
          lastCubicControl = null;
          command = '';
      }
    }
    return path;
  }

  static void _textRotationNone(Canvas canvas) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final path = Path()
      ..moveTo(657.066667, 620.088889)
      ..cubicTo(
        681.244445,
        620.088889,
        696.888889,
        595.911111,
        688.355556,
        573.155556,
      )
      ..lineTo(509.155556, 150.755556)
      ..cubicTo(
        494.933334,
        116.622223,
        445.155556,
        116.622223,
        430.933333,
        150.755556,
      )
      ..lineTo(250.311111, 573.155556)
      ..cubicTo(
        240.355555,
        595.911111,
        257.422222,
        620.088889,
        281.6,
        620.088889,
      )
      ..cubicTo(
        295.822222,
        620.088889,
        307.2,
        611.555556,
        312.888889,
        598.755556,
      )
      ..lineTo(349.866667, 506.311111)
      ..lineTo(590.222222, 506.311111)
      ..lineTo(627.2, 598.755556)
      ..cubicTo(
        631.466667,
        611.555556,
        644.266667,
        620.088889,
        657.066667,
        620.088889,
      )
      ..close()
      ..moveTo(371.2, 449.422222)
      ..lineTo(469.333333, 203.377778)
      ..lineTo(567.466667, 449.422222)
      ..close()
      ..moveTo(704, 662.755556)
      ..cubicTo(692.622222, 674.133334, 692.622222, 691.2, 704, 702.577778)
      ..lineTo(749.511111, 748.088889)
      ..lineTo(204.8, 748.088889)
      ..cubicTo(
        189.155556,
        748.088889,
        176.355556,
        760.888889,
        176.355556,
        776.533333,
      )
      ..cubicTo(
        176.355556,
        792.177778,
        189.155556,
        804.977778,
        204.8,
        804.977778,
      )
      ..lineTo(749.511111, 804.977778)
      ..lineTo(704, 850.488889)
      ..cubicTo(692.622222, 861.866667, 692.622222, 878.933333, 704, 890.311111)
      ..cubicTo(
        715.377778,
        901.688889,
        732.444444,
        901.688889,
        743.822222,
        890.311111,
      )
      ..lineTo(839.111111, 796.444444)
      ..cubicTo(850.488889, 785.066666, 850.488889, 768, 839.111111, 756.622222)
      ..lineTo(745.244444, 662.755556)
      ..cubicTo(733.866667, 651.377778, 715.377778, 651.377778, 704, 662.755556)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff535a68));
    canvas.restore();
  }

  static void _freezeGrid(Canvas canvas, Paint paint) {
    canvas.drawRect(const Rect.fromLTWH(5.75, 5.75, 12.5, 12.5), paint);
    _line(canvas, paint, const Offset(5.75, 12), const Offset(18.25, 12));
    _line(canvas, paint, const Offset(12, 5.5), const Offset(12, 18.5));
  }

  static void _freezeCol(Canvas canvas, Paint paint) {
    _freezeGrid(canvas, paint);
    _line(canvas, paint, const Offset(12, 12), const Offset(5.5, 17.75));
    _line(canvas, paint, const Offset(11.25, 6), const Offset(5.75, 11.5));
  }

  static void _freezeRow(Canvas canvas, Paint paint) {
    _freezeGrid(canvas, paint);
    _line(canvas, paint, const Offset(18, 6.5), const Offset(11.5, 12.25));
    _line(canvas, paint, const Offset(11.25, 6), const Offset(5.75, 11.5));
  }

  static void _freezeRowCol(Canvas canvas, Paint paint) {
    _freezeGrid(canvas, paint);
    _line(canvas, paint, const Offset(18, 6), const Offset(5.75, 18.25));
    _line(canvas, paint, const Offset(11.25, 6), const Offset(5.75, 11.5));
  }

  static void _freezeCancel(Canvas canvas, Paint paint) {
    final cancelPaint = Paint()
      ..color = const Color(0xff535a68)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawRect(const Rect.fromLTWH(5.75, 5.75, 12.5, 12.5), cancelPaint);
    _line(canvas, cancelPaint, const Offset(6.5, 12), const Offset(17.5, 12));
    _line(canvas, cancelPaint, const Offset(12, 17.5), const Offset(12, 6.5));
  }

  static void _conditionFormat(Canvas canvas, Paint paint, Paint fill) {
    const background = Color(0xfffafafc);
    const dark = Color(0xff535a68);
    const mid = Color(0xffa6aab2);
    const border = Color(0xffd0d2d7);

    canvas.save();
    canvas.translate(0, -2);
    _filledRect(canvas, const Rect.fromLTWH(4, 6, 16, 16), background);
    _filledRect(canvas, const Rect.fromLTWH(4, 6, 16, 1), border);
    _filledRect(canvas, const Rect.fromLTWH(4, 21, 16, 1), border);
    _filledRect(canvas, const Rect.fromLTWH(4, 6, 1, 16), border);
    _filledRect(canvas, const Rect.fromLTWH(19, 6, 1, 16), border);

    _filledRect(canvas, const Rect.fromLTWH(5, 7, 14, 2), dark);
    _filledRect(canvas, const Rect.fromLTWH(5, 19, 14, 2), dark);

    _filledRect(canvas, const Rect.fromLTWH(5, 9, 1, 10), mid);
    _filledRect(canvas, const Rect.fromLTWH(8, 9, 1, 10), mid);
    _filledRect(canvas, const Rect.fromLTWH(13, 9, 1, 10), mid);
    _filledRect(canvas, const Rect.fromLTWH(16, 9, 1, 10), mid);
    _filledRect(canvas, const Rect.fromLTWH(18, 9, 1, 10), mid);

    _filledRect(canvas, const Rect.fromLTWH(5, 11, 14, 1), mid);
    _filledRect(canvas, const Rect.fromLTWH(5, 15, 14, 1), mid);
    _filledRect(canvas, const Rect.fromLTWH(5, 16, 14, 1), mid);

    _filledRect(canvas, const Rect.fromLTWH(9, 12, 7, 3), dark);
    _filledRect(canvas, const Rect.fromLTWH(9, 15, 8, 1), dark);
    _filledRect(canvas, const Rect.fromLTWH(14, 9, 2, 10), dark);
    canvas.restore();
  }

  static void _filter(Canvas canvas, Paint paint, Paint fill) {
    final path = Path()
      ..moveTo(4.5, 5.5)
      ..lineTo(19.5, 5.5)
      ..lineTo(13.7, 12.25)
      ..lineTo(13.7, 18.5)
      ..lineTo(10.3, 16.7)
      ..lineTo(10.3, 12.25)
      ..close();
    canvas.drawPath(path, paint);
  }

  static void _link(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final fill = Paint()..color = const Color(0xff535a68);
    final first = Path()
      ..moveTo(577.155781, 655.619241)
      ..lineTo(431.54903, 801.139578)
      ..cubicTo(
        384.961046,
        847.727562,
        309.025789,
        847.727562,
        262.437806,
        801.139578,
      )
      ..lineTo(235.995274, 775.215527)
      ..cubicTo(
        189.234463,
        728.454716,
        189.234463,
        652.864113,
        235.995274,
        606.104304,
      )
      ..lineTo(366.393249, 475.274262)
      ..cubicTo(
        374.77646,
        466.891051,
        388.42786,
        466.891051,
        396.810802,
        475.274262,
      )
      ..cubicTo(
        405.193744,
        483.657473,
        405.193744,
        497.394731,
        396.810802,
        505.778228,
      )
      ..lineTo(266.585654, 636.176203)
      ..cubicTo(
        236.772542,
        665.989315,
        236.772542,
        714.379968,
        266.585654,
        744.19308,
      )
      ..lineTo(293.028186, 770.635612)
      ..cubicTo(
        322.841298,
        800.448724,
        371.231951,
        800.448724,
        401.045063,
        770.635612,
      )
      ..lineTo(546.565401, 625.028861)
      ..cubicTo(
        576.378513,
        595.215749,
        576.378513,
        546.825096,
        546.565401,
        517.011983,
      )
      ..lineTo(535.763713, 505.864641)
      ..cubicTo(
        527.380502,
        497.481144,
        527.380502,
        483.657473,
        535.763713,
        475.274262,
      )
      ..cubicTo(
        544.146924,
        466.891051,
        557.798324,
        466.891051,
        566.181266,
        475.274262,
      )
      ..lineTo(577.415021, 486.421603)
      ..cubicTo(
        624.175832,
        533.182414,
        624.089419,
        608.858948,
        577.155781,
        655.619241,
      )
      ..close();
    final second = Path()
      ..moveTo(446.844219, 368.380759)
      ..lineTo(592.45097, 222.860422)
      ..cubicTo(
        639.038954,
        176.272438,
        714.974211,
        176.272438,
        761.562194,
        222.860422,
      )
      ..lineTo(788.004726, 249.21654)
      ..cubicTo(
        834.765537,
        295.977351,
        834.765537,
        371.567954,
        788.004726,
        418.327764,
      )
      ..lineTo(657.606751, 548.639325)
      ..cubicTo(
        649.22354,
        557.022536,
        635.57214,
        557.022536,
        627.189198,
        548.639325,
      )
      ..cubicTo(
        618.806256,
        540.256114,
        618.806256,
        526.518856,
        627.189198,
        518.135359,
      )
      ..lineTo(757.414346, 387.823797)
      ..cubicTo(
        787.227458,
        358.010685,
        787.227458,
        309.620032,
        757.414346,
        279.80692,
      )
      ..lineTo(730.971814, 253.364388)
      ..cubicTo(
        701.158702,
        223.551276,
        652.768049,
        223.551276,
        622.954937,
        253.364388,
      )
      ..lineTo(477.434599, 398.971139)
      ..cubicTo(
        447.621487,
        428.784251,
        447.621487,
        477.174904,
        477.434599,
        506.988017,
      )
      ..lineTo(488.581941, 518.481013)
      ..cubicTo(
        496.965152,
        526.86451,
        496.965152,
        540.601768,
        488.581941,
        548.985,
      )
      ..cubicTo(
        480.19873,
        557.368211,
        466.54733,
        557.368211,
        458.164388,
        548.985,
      )
      ..lineTo(446.930633, 537.837637)
      ..cubicTo(
        400.169822,
        491.076826,
        400.083409,
        415.141569,
        446.844219,
        368.380759,
      )
      ..close();
    canvas.drawPath(first, fill);
    canvas.drawPath(second, fill);
    canvas.restore();
  }

  static void _image(Canvas canvas, Paint paint) {
    canvas.drawCircle(
      const Offset(8.75, 8.75),
      1.25,
      Paint()..color = iconColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.75, 5.25, 14.5, 13.5),
        const Radius.circular(0.75),
      ),
      paint,
    );
    final path = Path()
      ..moveTo(7, 19)
      ..lineTo(12.98, 11.9)
      ..quadraticBezierTo(13.17, 11.68, 13.7, 11.85)
      ..lineTo(19.5, 17.06);
    canvas.drawPath(path, paint);
  }

  static void _importImage(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(3.5, 3.5);
    canvas.scale(17 / 512, 17 / 512);
    final path = _svgPath(_importImagePath)..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()
        ..color = iconColor
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  static void _save(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(2.28, 2.28);
    canvas.scale(16 / 425, 16 / 425);
    final path = _svgPath(_savePath)..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xff000000)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  static void _barcode(Canvas canvas, Paint paint) {
    final stroke = Paint()
      ..color = iconColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = iconColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.5, 5, 15, 14),
        const Radius.circular(1),
      ),
      stroke,
    );
    for (final rect in const <Rect>[
      Rect.fromLTWH(7, 8, 1.4, 8),
      Rect.fromLTWH(9.2, 8, 0.8, 8),
      Rect.fromLTWH(11, 8, 2, 8),
      Rect.fromLTWH(14.2, 8, 0.8, 8),
      Rect.fromLTWH(16, 8, 1.2, 8),
    ]) {
      canvas.drawRect(rect, fill);
    }
  }

  static void _comment(Canvas canvas, Paint paint) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(9.968, 15.7)
      ..lineTo(12, 17.956)
      ..lineTo(14.032, 15.698)
      ..lineTo(18.5, 15.698)
      ..lineTo(18.5, 5.698)
      ..lineTo(5.5, 5.698)
      ..lineTo(5.5, 15.698)
      ..lineTo(9.968, 15.698)
      ..close()
      ..moveTo(11.257, 19.373)
      ..lineTo(9.3, 17.2)
      ..lineTo(5.5, 17.2)
      ..cubicTo(4.672, 17.2, 4, 16.528, 4, 15.7)
      ..lineTo(4, 5.7)
      ..cubicTo(4, 4.872, 4.672, 4.2, 5.5, 4.2)
      ..lineTo(18.5, 4.2)
      ..cubicTo(19.328, 4.2, 20, 4.872, 20, 5.7)
      ..lineTo(20, 15.7)
      ..cubicTo(20, 16.528, 19.328, 17.2, 18.5, 17.2)
      ..lineTo(14.7, 17.2)
      ..lineTo(12.743, 19.374)
      ..cubicTo(12.345, 19.816, 11.655, 19.816, 11.257, 19.373)
      ..close();
    canvas.drawPath(path, Paint()..color = iconColor);
    _filledRect(canvas, const Rect.fromLTWH(7, 8.2, 10, 1.5), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(7, 11.7, 6, 1.5), iconColor);
  }

  static void _shieldCheck(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(12, 4)
      ..cubicTo(13.4, 5.4, 15.8, 6.1, 18.2, 6.2)
      ..lineTo(18.2, 11.3)
      ..cubicTo(18.2, 14.9, 15.9, 17.9, 12, 20)
      ..cubicTo(8.1, 17.9, 5.8, 14.9, 5.8, 11.3)
      ..lineTo(5.8, 6.2)
      ..cubicTo(8.2, 6.1, 10.6, 5.4, 12, 4)
      ..close();
    canvas.drawPath(path, paint);
    _line(canvas, paint, const Offset(9, 12), const Offset(11, 14));
    _line(canvas, paint, const Offset(11, 14), const Offset(15.5, 9.5));
  }

  static void _splitColumn(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final fill = Paint()..color = const Color(0xff535a68);
    final path = Path()
      ..addRect(const Rect.fromLTWH(102.4, 143.36, 819.2, 245.76))
      ..addRect(const Rect.fromLTWH(143.36, 184.32, 737.28, 163.84))
      ..fillType = PathFillType.evenOdd
      ..moveTo(444.416, 477.184)
      ..lineTo(512, 544.768)
      ..lineTo(579.584, 477.184)
      ..cubicTo(587.776, 468.992, 600.064, 468.992, 608.256, 477.184)
      ..cubicTo(616.448, 485.376, 616.448, 497.664, 608.256, 505.856)
      ..lineTo(512, 602.112)
      ..lineTo(415.744, 505.856)
      ..cubicTo(407.552, 497.664, 407.552, 485.376, 415.744, 477.184)
      ..cubicTo(423.936, 468.992, 436.224, 468.992, 444.416, 477.184)
      ..moveTo(102.4, 634.88)
      ..lineTo(471.04, 634.88)
      ..lineTo(471.04, 880.64)
      ..lineTo(102.4, 880.64)
      ..close()
      ..moveTo(552.96, 634.88)
      ..lineTo(921.6, 634.88)
      ..lineTo(921.6, 880.64)
      ..lineTo(552.96, 880.64)
      ..close()
      ..moveTo(143.36, 839.68)
      ..lineTo(430.08, 839.68)
      ..lineTo(430.08, 675.84)
      ..lineTo(143.36, 675.84)
      ..close()
      ..moveTo(593.92, 839.68)
      ..lineTo(880.64, 839.68)
      ..lineTo(880.64, 675.84)
      ..lineTo(593.92, 675.84)
      ..close();
    canvas.drawPath(path, fill);
    canvas.restore();
  }

  static void _locationCondition(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final path = Path()
      ..moveTo(938.666667, 388.266667)
      ..lineTo(584.533333, 388.266667)
      ..lineTo(584.533333, 247.466667)
      ..cubicTo(
        584.533333,
        235.684599,
        574.982068,
        226.133333,
        563.2,
        226.133333,
      )
      ..lineTo(85.333333, 226.133333)
      ..cubicTo(73.551266, 226.133333, 64, 235.684599, 64, 247.466667)
      ..lineTo(64, 571.733333)
      ..cubicTo(64, 583.515401, 73.551266, 593.066667, 85.333333, 593.066667)
      ..lineTo(362.666667, 593.066667)
      ..lineTo(362.666667, 785.066667)
      ..cubicTo(362.666667, 796.848734, 372.217932, 806.4, 384, 806.4)
      ..lineTo(938.666667, 806.4)
      ..cubicTo(950.448734, 806.4, 960, 796.848734, 960, 785.066667)
      ..lineTo(960, 409.6)
      ..cubicTo(960, 397.817932, 950.448734, 388.266667, 938.666667, 388.266667)
      ..close()
      ..moveTo(106.666667, 550.4)
      ..lineTo(106.666667, 268.8)
      ..lineTo(541.866667, 268.8)
      ..lineTo(541.866667, 388.266667)
      ..lineTo(384, 388.266667)
      ..cubicTo(
        372.217932,
        388.266667,
        362.666667,
        397.817932,
        362.666667,
        409.6,
      )
      ..lineTo(362.666667, 550.4)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff535a68));
    canvas.restore();
  }

  static void _screenshotCrop(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.scale(24 / 1024, 24 / 1024);
    final path = Path()
      ..moveTo(320, 704)
      ..lineTo(320, 128)
      ..lineTo(256, 128)
      ..lineTo(256, 256)
      ..lineTo(128, 256)
      ..lineTo(128, 320)
      ..lineTo(256, 320)
      ..lineTo(256, 768)
      ..lineTo(704, 768)
      ..lineTo(704, 896)
      ..lineTo(768, 896)
      ..lineTo(768, 768)
      ..lineTo(896, 768)
      ..lineTo(896, 704)
      ..close()
      ..moveTo(704, 640)
      ..lineTo(768, 640)
      ..lineTo(768, 256)
      ..lineTo(384, 256)
      ..lineTo(384, 320)
      ..lineTo(704, 320)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff535a68));
    canvas.restore();
  }

  static void _search(Canvas canvas, Paint paint) {
    canvas.drawCircle(const Offset(10.5, 10.5), 5.5, paint);
    _line(canvas, paint, const Offset(15, 15), const Offset(20, 20));
  }

  static void _hidden(Canvas canvas, Paint paint) {
    final eyePath = Path()
      ..moveTo(3, 12)
      ..cubicTo(5.7, 7.5, 9.1, 5.4, 12, 5.4)
      ..cubicTo(14.9, 5.4, 18.3, 7.5, 21, 12)
      ..cubicTo(18.3, 16.5, 14.9, 18.6, 12, 18.6)
      ..cubicTo(9.1, 18.6, 5.7, 16.5, 3, 12)
      ..close();
    canvas.drawPath(eyePath, paint);
    canvas.drawCircle(const Offset(12, 12), 2.3, paint);
    _line(canvas, paint, const Offset(4.5, 19.5), const Offset(19.5, 4.5));
  }

  static void _print(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 9, 14, 8),
        const Radius.circular(1.5),
      ),
      paint,
    );
    _filledRect(canvas, const Rect.fromLTWH(7, 4, 10, 6), iconColor);
    _filledRect(canvas, const Rect.fromLTWH(7, 14, 10, 6), iconColor);
    _filledRect(
      canvas,
      const Rect.fromLTWH(9, 16, 6, 1.2),
      _printPaperLineColor,
    );
    _filledRect(
      canvas,
      const Rect.fromLTWH(9, 18, 6, 1.2),
      _printPaperLineColor,
    );
    canvas.drawCircle(
      const Offset(16, 12),
      0.8,
      Paint()..color = _printPaperLineColor,
    );
  }

  static void _more(Canvas canvas, Paint fill) {
    canvas.drawCircle(const Offset(7, 12), 1.6, fill);
    canvas.drawCircle(const Offset(12, 12), 1.6, fill);
    canvas.drawCircle(const Offset(17, 12), 1.6, fill);
  }

  static void _defaultIcon(Canvas canvas, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 5, 14, 14),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  static void _upDown(Canvas canvas, Paint paint, double x) {
    _line(canvas, paint, Offset(x, 7), Offset(x - 3, 10));
    _line(canvas, paint, Offset(x, 7), Offset(x + 3, 10));
    _line(canvas, paint, Offset(x, 17), Offset(x - 3, 14));
    _line(canvas, paint, Offset(x, 17), Offset(x + 3, 14));
  }

  static void _italic(Canvas canvas, Paint fill) {
    _filledRect(canvas, const Rect.fromLTWH(11, 5, 5, 1.5), textIconColor);
    _filledRect(canvas, const Rect.fromLTWH(9, 17.5, 5, 1.5), textIconColor);
    final path = Path()
      ..moveTo(12.76, 5.88)
      ..lineTo(14.24, 6.12)
      ..lineTo(12.24, 18.12)
      ..lineTo(10.76, 17.88)
      ..close();
    canvas.drawPath(path, Paint()..color = textIconColor);
  }

  static void _currency(Canvas canvas, String currency) {
    final pathData = switch (currency) {
      r'$' =>
        'M4 10.781c.148 1.667 1.513 2.85 3.591 3.003V15h1.043v-1.216c2.27-.179 3.678-1.438 3.678-3.3 0-1.59-.947-2.51-2.956-3.028l-.722-.187V3.467c1.122.11 1.879.714 2.07 1.616h1.47c-.166-1.6-1.54-2.748-3.54-2.875V1H7.591v1.233c-1.939.23-3.27 1.472-3.27 3.156 0 1.454.966 2.483 2.661 2.917l.61.162v4.031c-1.149-.17-1.94-.8-2.131-1.718H4zm3.391-3.836c-1.043-.263-1.6-.825-1.6-1.616 0-.944.704-1.641 1.8-1.828v3.495l-.2-.05zm1.591 1.872c1.287.323 1.852.859 1.852 1.769 0 1.097-.826 1.828-2.2 1.939V8.73l.348.086z',
      '€' =>
        'M4 9.42h1.063C5.4 12.323 7.317 14 10.34 14c.622 0 1.167-.068 1.659-.185v-1.3c-.484.119-1.045.17-1.659.17-2.1 0-3.455-1.198-3.775-3.264h4.017v-.928H6.497v-.936c0-.11 0-.219.008-.329h4.078v-.927H6.618c.388-1.898 1.719-2.985 3.723-2.985.614 0 1.175.05 1.659.177V2.194A6.617 6.617 0 0010.341 2c-2.928 0-4.82 1.569-5.244 4.3H4v.928h1.01v1.265H4v.928z',
      '£' =>
        'M4 8.585h1.969c.115.465.186.939.186 1.43 0 1.385-.736 2.496-2.075 2.771V14H12v-1.24H6.492v-.129c.825-.525 1.135-1.446 1.135-2.694 0-.465-.07-.913-.168-1.352h3.29v-.972H7.22c-.186-.723-.372-1.455-.372-2.247 0-1.274 1.047-2.066 2.58-2.066a5.32 5.32 0 012.103.465V2.456A5.629 5.629 0 009.348 2C6.865 2 5.322 3.291 5.322 5.366c0 .775.195 1.515.399 2.247H4v.972z',
      '₹' =>
        'M4 3.06h2.726c1.22 0 2.12.575 2.325 1.724H4v1.051h5.051C8.855 7.001 8 7.558 6.788 7.558H4v1.317L8.437 14h2.11L6.095 8.884h.855c2.316-.018 3.465-1.476 3.688-3.049H12V4.784h-1.345c-.08-.778-.357-1.335-.793-1.732H12V2H4v1.06z',
      _ =>
        'M8.75 14v-2.629h2.446v-.967H8.75v-1.31h2.445v-.967H9.128L12.5 2h-1.699L8.047 7.327h-.086L5.207 2H3.5l3.363 6.127H4.778v.968H7.25v1.31H4.78v.966h2.47V14h1.502z',
    };
    canvas.save();
    canvas.scale(1.5);
    canvas.drawPath(
      _currencySvgPath(pathData),
      Paint()
        ..color = iconColor
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  static Path _currencySvgPath(String data) {
    final tokens = RegExp(
      r'[CcHhLlMmVvZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
    ).allMatches(data).map((match) => match.group(0)!).toList();
    final path = Path();
    var index = 0;
    var command = '';
    var current = Offset.zero;
    var subpathStart = Offset.zero;

    bool isCommand(String token) =>
        token.length == 1 && 'CcHhLlMmVvZz'.contains(token);
    double number() => double.parse(tokens[index++]);

    while (index < tokens.length) {
      if (isCommand(tokens[index])) {
        command = tokens[index++];
      }
      switch (command) {
        case 'M':
        case 'm':
          var first = true;
          while (index < tokens.length && !isCommand(tokens[index])) {
            final x = number();
            final y = number();
            final point = command == 'm'
                ? current + Offset(x, y)
                : Offset(x, y);
            if (first) {
              path.moveTo(point.dx, point.dy);
              subpathStart = point;
              first = false;
            } else {
              path.lineTo(point.dx, point.dy);
            }
            current = point;
          }
          command = command == 'm' ? 'l' : 'L';
          break;
        case 'L':
        case 'l':
          while (index < tokens.length && !isCommand(tokens[index])) {
            final x = number();
            final y = number();
            final point = command == 'l'
                ? current + Offset(x, y)
                : Offset(x, y);
            path.lineTo(point.dx, point.dy);
            current = point;
          }
          break;
        case 'H':
        case 'h':
          while (index < tokens.length && !isCommand(tokens[index])) {
            final x = number();
            current = Offset(command == 'h' ? current.dx + x : x, current.dy);
            path.lineTo(current.dx, current.dy);
          }
          break;
        case 'V':
        case 'v':
          while (index < tokens.length && !isCommand(tokens[index])) {
            final y = number();
            current = Offset(current.dx, command == 'v' ? current.dy + y : y);
            path.lineTo(current.dx, current.dy);
          }
          break;
        case 'C':
        case 'c':
          var parsedCubic = false;
          while (index + 5 < tokens.length &&
              !tokens.skip(index).take(6).any(isCommand)) {
            parsedCubic = true;
            final x1 = number();
            final y1 = number();
            final x2 = number();
            final y2 = number();
            final x = number();
            final y = number();
            final control1 = command == 'c'
                ? current + Offset(x1, y1)
                : Offset(x1, y1);
            final control2 = command == 'c'
                ? current + Offset(x2, y2)
                : Offset(x2, y2);
            final point = command == 'c'
                ? current + Offset(x, y)
                : Offset(x, y);
            path.cubicTo(
              control1.dx,
              control1.dy,
              control2.dx,
              control2.dy,
              point.dx,
              point.dy,
            );
            current = point;
          }
          if (!parsedCubic &&
              index < tokens.length &&
              !isCommand(tokens[index])) {
            index++;
          }
          break;
        case 'Z':
        case 'z':
          path.close();
          current = subpathStart;
          command = '';
          break;
        default:
          index++;
      }
    }
    return path;
  }

  static void _letterA(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = textIconColor
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final top = Offset(rect.center.dx, rect.top);
    final left = Offset(rect.left, rect.bottom);
    final right = Offset(rect.right, rect.bottom);
    _line(canvas, paint, left, top);
    _line(canvas, paint, top, right);
    _line(
      canvas,
      paint,
      Offset(rect.left + rect.width * 0.28, rect.top + rect.height * 0.62),
      Offset(rect.right - rect.width * 0.28, rect.top + rect.height * 0.62),
    );
  }

  static void _letterB(Canvas canvas) {
    final path = Path()
      ..moveTo(6.30566, 5.07617)
      ..lineTo(6.30566, 18.9992)
      ..lineTo(12.4872, 18.9992)
      ..cubicTo(13.9107, 18.9992, 15.0417, 18.7067, 15.8607, 18.1607)
      ..cubicTo(16.8162, 17.4977, 17.3037, 16.4837, 17.3037, 15.1187)
      ..cubicTo(17.3037, 14.1827, 17.0307, 13.4417, 16.5237, 12.8567)
      ..cubicTo(16.0167, 12.2717, 15.3147, 11.8817, 14.3982, 11.7257)
      ..cubicTo(15.1002, 11.4917, 15.6657, 11.1212, 16.0947, 10.6142)
      ..cubicTo(16.5042, 10.0487, 16.7187, 9.36617, 16.7187, 8.58617)
      ..cubicTo(16.7187, 7.49417, 16.3482, 6.63617, 15.6072, 6.01217)
      ..cubicTo(14.8467, 5.38817, 13.8132, 5.07617, 12.5262, 5.07617)
      ..close()
      ..moveTo(7.90466, 6.42167)
      ..lineTo(12.1557, 6.42167)
      ..cubicTo(13.1307, 6.42167, 13.8717, 6.59717, 14.3787, 6.98717)
      ..cubicTo(14.8857, 7.37717, 15.1392, 7.96217, 15.1392, 8.74217)
      ..cubicTo(15.1392, 9.54167, 14.8662, 10.1462, 14.3592, 10.5557)
      ..cubicTo(13.8522, 10.9457, 13.1112, 11.1602, 12.1362, 11.1602)
      ..lineTo(7.90466, 11.1602)
      ..close()
      ..moveTo(7.90466, 12.4862)
      ..lineTo(12.3507, 12.4862)
      ..cubicTo(13.4232, 12.4862, 14.2422, 12.6812, 14.8077, 13.1102)
      ..cubicTo(15.3927, 13.5392, 15.7047, 14.2022, 15.7047, 15.0992)
      ..cubicTo(15.7047, 15.9962, 15.3537, 16.6787, 14.6712, 17.1077)
      ..cubicTo(14.0862, 17.4587, 13.3257, 17.6537, 12.3507, 17.6537)
      ..lineTo(7.90466, 17.6537)
      ..close();
    canvas.drawPath(path, Paint()..color = textIconColor);
  }

  static void _letterS(Canvas canvas) {
    final paint = Paint()
      ..color = textIconColor
      ..strokeWidth = 1.55
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(16.2, 7.2)
      ..cubicTo(14.8, 5.8, 11.3, 5.4, 9.4, 6.6)
      ..cubicTo(7.1, 8.0, 7.6, 10.5, 10.5, 11.2)
      ..lineTo(13.3, 11.9)
      ..cubicTo(17.1, 12.9, 17.4, 16.3, 14.8, 18.0)
      ..cubicTo(12.6, 19.3, 8.8, 18.8, 7.4, 16.6);
    canvas.drawPath(path, paint);
  }

  static void _letterU(Canvas canvas, {double dy = 0}) {
    final paint = Paint()
      ..color = textIconColor
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(8, 5 + dy)
      ..lineTo(8, 12.2 + dy)
      ..cubicTo(8, 16.6 + dy, 16, 16.6 + dy, 16, 12.2 + dy)
      ..lineTo(16, 5 + dy);
    canvas.drawPath(path, paint);
  }

  static void _sigma(Canvas canvas) {
    final paint = Paint()
      ..color = iconColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(17, 5.5)
      ..lineTo(7, 5.5)
      ..lineTo(12.5, 12)
      ..lineTo(7, 18.5)
      ..lineTo(17, 18.5);
    canvas.drawPath(path, paint);
  }

  static void _compactNumberLabel(Canvas canvas, String text, Offset offset) {
    var x = offset.dx;
    for (final codeUnit in text.codeUnits) {
      _smallDigit(canvas, codeUnit - 48, Offset(x, offset.dy));
      x += 4.8;
    }
  }

  static void _smallDigit(Canvas canvas, int digit, Offset offset) {
    final paint = Paint()
      ..color = iconColor
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final x = offset.dx;
    final y = offset.dy;
    void seg(double ax, double ay, double bx, double by) {
      _line(canvas, paint, Offset(x + ax, y + ay), Offset(x + bx, y + by));
    }

    switch (digit) {
      case 0:
        seg(0.4, 0.2, 3.5, 0.2);
        seg(0.4, 7.0, 3.5, 7.0);
        seg(0.4, 0.2, 0.4, 7.0);
        seg(3.5, 0.2, 3.5, 7.0);
        break;
      case 1:
        seg(2.0, 0.2, 2.0, 7.0);
        seg(0.9, 1.2, 2.0, 0.2);
        seg(0.8, 7.0, 3.3, 7.0);
        break;
      case 2:
        seg(0.5, 0.2, 3.5, 0.2);
        seg(3.5, 0.2, 3.5, 3.5);
        seg(0.5, 3.5, 3.5, 3.5);
        seg(0.5, 3.5, 0.5, 7.0);
        seg(0.5, 7.0, 3.5, 7.0);
        break;
      case 3:
        seg(0.5, 0.2, 3.5, 0.2);
        seg(0.8, 3.5, 3.5, 3.5);
        seg(0.5, 7.0, 3.5, 7.0);
        seg(3.5, 0.2, 3.5, 7.0);
        break;
    }
  }

  static void _filledRect(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  static void _line(Canvas canvas, Paint paint, Offset a, Offset b) {
    canvas.drawLine(a, b, paint);
  }
}
