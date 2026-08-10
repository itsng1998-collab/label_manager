import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login/domain/user_access_serial.dart';
import 'package:label_manager/features/login/presentation/user_access_serial_dialog.dart';

void main() {
  testWidgets('시리얼 인증은 오답을 거부하고 일치하는 번호를 승인한다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showUserAccessSerialDialog(context, '18529631');
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('18529631'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('userAccessSerialField')),
      'wrong',
    );
    await tester.tap(find.text('입력'));
    await tester.pump();
    expect(find.text('시리얼 번호가 올바르지 않습니다.'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(
      find.byKey(const Key('userAccessSerialField')),
      userAccessSerialNumber('18529631'),
    );
    await tester.tap(find.text('입력'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}