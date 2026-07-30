import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/settings_name_edit_dialog.dart';

void main() {
  testWidgets('CRUD toolbar keeps add active and gates selected commands', (
    tester,
  ) async {
    var addCount = 0;
    var editCount = 0;
    var deleteCount = 0;

    Widget buildToolbar(bool hasSelection) => MaterialApp(
      home: Scaffold(
        body: SettingsCrudToolbar(
          addTooltip: '추가',
          editTooltip: '수정',
          deleteTooltip: '삭제',
          enabled: true,
          hasSelection: hasSelection,
          onAdd: () => addCount += 1,
          onEdit: () => editCount += 1,
          onDelete: () => deleteCount += 1,
        ),
      ),
    );

    await tester.pumpWidget(buildToolbar(false));
    await tester.tap(find.byTooltip('추가'));
    final buttons = tester
        .widgetList<IconButton>(find.byType(IconButton))
        .toList();
    expect(buttons[1].onPressed, isNull);
    expect(buttons[2].onPressed, isNull);

    await tester.pumpWidget(buildToolbar(true));
    await tester.tap(find.byTooltip('수정'));
    await tester.tap(find.byTooltip('삭제'));

    expect(addCount, 1);
    expect(editCount, 1);
    expect(deleteCount, 1);
  });

  testWidgets('name dialog trims input and returns scale setting', (
    tester,
  ) async {
    SettingsNameEditResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNameEditDialog(
            title: '라벨 수정',
            initialName: '기존 라벨',
            showUseScale: true,
            initialUseScale: false,
            onCancel: () {},
            onSubmit: (value) => result = value,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('settings-name-edit-field')),
      '  새 라벨  ',
    );
    await tester.tap(find.byKey(const ValueKey('settings-name-use-scale')));
    await tester.tap(find.byKey(const ValueKey('settings-name-submit')));

    expect(result?.name, '새 라벨');
    expect(result?.useScale, isTrue);
  });

  testWidgets('name dialog disables save for blank input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsNameEditDialog(
            title: '브랜드 추가',
            initialName: '',
            onCancel: () {},
            onSubmit: (_) {},
          ),
        ),
      ),
    );

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('settings-name-submit')),
    );
    expect(saveButton.onPressed, isNull);
    expect(find.text('전자저울 사용'), findsNothing);
  });
}
