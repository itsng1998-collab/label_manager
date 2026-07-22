import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  test('open dotted pattern does not add a dot at the terminal endpoint', () {
    final marks = fortuneObjectStrokeMarks(
      style: FortuneStrokeStyle.dotted,
      strokeWidth: 1,
      pathLength: 3,
      closed: false,
    );

    expect(marks, hasLength(1));
    expect((marks.single as FortuneObjectStrokeDot).center, 0);
  });

  test('dash-dot uses two-width visible gaps around each dot', () {
    final marks = fortuneObjectStrokeMarks(
      style: FortuneStrokeStyle.dashDot,
      strokeWidth: 1,
      pathLength: 20,
      closed: false,
    );

    expect(
      marks.map(
        (mark) => switch (mark) {
          FortuneObjectStrokeDash(:final start, :final end) => (
            'dash',
            start,
            end,
          ),
          FortuneObjectStrokeDot(:final center) => ('dot', center, center),
        },
      ),
      [
        ('dash', 0, 4),
        ('dot', 6.5, 6.5),
        ('dash', 9, 13),
        ('dot', 15.5, 15.5),
        ('dash', 18, 20),
      ],
    );
  });

  test('closed dashed pattern clips the terminal mark for the seam gap', () {
    final marks = fortuneObjectStrokeMarks(
      style: FortuneStrokeStyle.dashed,
      strokeWidth: 1,
      pathLength: 10,
      closed: true,
    );

    expect(marks, hasLength(2));
    expect(
      marks.map((mark) {
        final dash = mark as FortuneObjectStrokeDash;
        return (dash.start, dash.end);
      }),
      [(0, 4), (6, 8)],
    );
  });

  test('closed dotted pattern reserves the seam gap after its first dot', () {
    final marks = fortuneObjectStrokeMarks(
      style: FortuneStrokeStyle.dotted,
      strokeWidth: 1,
      pathLength: 4,
      closed: true,
    );

    expect(marks, hasLength(1));
    expect((marks.single as FortuneObjectStrokeDot).center, 0.5);
  });
}
