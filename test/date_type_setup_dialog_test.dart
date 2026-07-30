import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/date_setup/domain/date_manager.dart';
import 'package:label_manager/features/date_setup/presentation/date_type_setup_dialog.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';

void main() {
  testWidgets('date setup dialog previews custom format and returns update', (
    tester,
  ) async {
    LabelSizeDateSetupUpdate? result;
    const setup = LabelSizeSetup(
      readOnly: true,
      useMakeDate: true,
      useMakeTime: false,
      useValidDate: true,
      useValidTime: false,
      makingDateFormat: PrintDateFormat.DATE_FORMAT_USER_DEFINE,
      makingTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      validDateFormat: PrintDateFormat.DATE_FORMAT_SLASH,
      validTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      strMakeDate: 'yyyy-mm-dd',
      strMakeTime: '',
      strValidDate: '',
      strValidTime: '',
      useScale: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<LabelSizeDateSetupUpdate>(
                context: context,
                builder: (_) => const DateTypeSetupDialog(
                  initialSetup: setup,
                  showInvalidValueWarning: true,
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 타입 설정'), findsOneWidget);
    expect(find.textContaining('지원 범위를 벗어나'), findsOneWidget);
    expect(find.textContaining('날짜 y/m/d, 시간 h/m'), findsOneWidget);
    expect(find.text('2000-01-01'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'yyyy년 mm월 dd일');
    await tester.pump();
    expect(find.text('2000년 01월 01일'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.strMakeDate, 'yyyy년 mm월 dd일');
    expect(result!.makingDateFormat, PrintDateFormat.DATE_FORMAT_USER_DEFINE);
    expect(result!.useMakeTime, isFalse);
  });

  testWidgets('date setup dialog is read-only without edit permission', (
    tester,
  ) async {
    const setup = LabelSizeSetup(
      readOnly: false,
      useMakeDate: true,
      useMakeTime: false,
      useValidDate: true,
      useValidTime: false,
      makingDateFormat: PrintDateFormat.DATE_FORMAT_DOT,
      makingTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      validDateFormat: PrintDateFormat.DATE_FORMAT_SLASH,
      validTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      strMakeDate: '',
      strMakeTime: '',
      strValidDate: '',
      strValidTime: '',
      useScale: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DateTypeSetupDialog(
            initialSetup: setup,
            showInvalidValueWarning: false,
            readOnly: true,
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '저장'))
          .onPressed,
      isNull,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged, isNull);
    expect(tester.widget<TextField>(find.byType(TextField).first).enabled, isFalse);
  });
}