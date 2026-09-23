import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/application/item_editable_default_repair.dart';

void main() {
  test('legacy editable defaults are repaired once after success', () async {
    var completed = false;
    var repairs = 0;
    var marks = 0;

    final first = await runLegacyItemEditableDefaultRepair(
      isCompleted: () async => completed,
      repair: () async {
        repairs += 1;
        return 12;
      },
      markCompleted: () async {
        marks += 1;
        completed = true;
      },
    );
    final second = await runLegacyItemEditableDefaultRepair(
      isCompleted: () async => completed,
      repair: () async {
        repairs += 1;
        return 0;
      },
      markCompleted: () async {
        marks += 1;
      },
    );

    expect(first, 12);
    expect(second, isNull);
    expect(repairs, 1);
    expect(marks, 1);
  });

  test('failed repair is not marked completed', () async {
    var marked = false;

    await expectLater(
      runLegacyItemEditableDefaultRepair(
        isCompleted: () async => false,
        repair: () async => throw StateError('failed'),
        markCompleted: () async => marked = true,
      ),
      throwsStateError,
    );

    expect(marked, isFalse);
  });
}