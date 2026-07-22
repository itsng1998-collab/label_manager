import 'dart:math' as math;

import 'fortune_sheet_model.dart';

sealed class FortuneObjectStrokeMark {
  const FortuneObjectStrokeMark();
}

final class FortuneObjectStrokeDash extends FortuneObjectStrokeMark {
  const FortuneObjectStrokeDash(this.start, this.end);

  final double start;
  final double end;
}

final class FortuneObjectStrokeDot extends FortuneObjectStrokeMark {
  const FortuneObjectStrokeDot(this.center);

  final double center;
}

List<FortuneObjectStrokeMark> fortuneObjectStrokeMarks({
  required FortuneStrokeStyle style,
  required double strokeWidth,
  required double pathLength,
  required bool closed,
}) {
  if (style == FortuneStrokeStyle.solid ||
      strokeWidth <= 0 ||
      pathLength <= 0) {
    return const [];
  }
  final firstMarkLength = style == FortuneStrokeStyle.dotted
      ? strokeWidth
      : 4 * strokeWidth;
  final marks = <FortuneObjectStrokeMark>[];
  final seamLimit = closed && pathLength >= firstMarkLength + 2 * strokeWidth
      ? pathLength - 2 * strokeWidth
      : pathLength;

  void addDash(double start, double end, {bool first = false}) {
    if (start >= pathLength || (!first && start >= seamLimit)) {
      return;
    }
    final clippedEnd = math.min(
      pathLength,
      first ? end : math.min(end, seamLimit),
    );
    if (clippedEnd > start) {
      marks.add(FortuneObjectStrokeDash(start, clippedEnd));
    }
  }

  void addDot(double center, {bool first = false}) {
    final radius = strokeWidth / 2;
    if (closed && first && pathLength < strokeWidth) {
      return;
    }
    if (center >= pathLength || (!first && center + radius > seamLimit)) {
      return;
    }
    marks.add(FortuneObjectStrokeDot(center));
  }

  switch (style) {
    case FortuneStrokeStyle.solid:
      break;
    case FortuneStrokeStyle.dashed:
      addDash(0, 4 * strokeWidth, first: true);
      for (
        var start = 6 * strokeWidth;
        start < seamLimit;
        start += 6 * strokeWidth
      ) {
        addDash(start, start + 4 * strokeWidth);
      }
    case FortuneStrokeStyle.dotted:
      final firstCenter = closed ? strokeWidth / 2 : 0.0;
      addDot(firstCenter, first: true);
      for (
        var center = firstCenter + 3 * strokeWidth;
        center < seamLimit;
        center += 3 * strokeWidth
      ) {
        addDot(center);
      }
    case FortuneStrokeStyle.dashDot:
      addDash(0, 4 * strokeWidth, first: true);
      for (var cycle = 0.0; cycle < seamLimit; cycle += 9 * strokeWidth) {
        if (cycle > 0) {
          addDash(cycle, cycle + 4 * strokeWidth);
        }
        addDot(cycle + 6.5 * strokeWidth);
      }
  }
  return marks;
}
