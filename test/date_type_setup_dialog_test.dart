import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/date_manager.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/date_type_setup_dialog.dart';

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
      strMakeDate: 'Y-M-D',
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
    expect(find.text('2000-01-01'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Y년 M월 D일');
    await tester.pump();
    expect(find.text('2000년 01월 01일'), findsOneWidget);

    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.strMakeDate, 'Y년 M월 D일');
    expect(result!.makingDateFormat, PrintDateFormat.DATE_FORMAT_USER_DEFINE);
    expect(result!.useMakeTime, isFalse);
  });
}