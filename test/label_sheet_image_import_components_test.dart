import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_components.dart';

Widget _host(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('image import API key field obscures text and blocks copy keys', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'secret');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        LabelSheetImageImportApiKeyField(
          controller: controller,
          enabled: true,
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    final shortcuts = tester.widget<Shortcuts>(
      find.descendant(
        of: find.byType(LabelSheetImageImportApiKeyField),
        matching: find.byType(Shortcuts),
      ),
    );
    expect(textField.obscureText, isTrue);
    expect(textField.enableInteractiveSelection, isTrue);
    expect(shortcuts.shortcuts, hasLength(4));
  });

  testWidgets('image import error panel hides empty and shows trimmed text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const LabelSheetImageImportErrorPanel(message: '   ')),
    );
    expect(find.byType(SelectableText), findsNothing);

    await tester.pumpWidget(
      _host(const LabelSheetImageImportErrorPanel(message: '  failed  ')),
    );
    expect(find.text('failed'), findsOneWidget);
  });
}
