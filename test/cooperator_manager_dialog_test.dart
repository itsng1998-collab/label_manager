import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/page_home/cooperator_manager_dialog.dart';

void main() {
  test('manager lifecycle blocks active child and writes', () {
    final controller = CooperatorManagerController();

    expect(controller.snapshot().blockingReason, isNull);
    controller.setActiveEditing(true);
    expect(controller.snapshot().blockingReason, contains('입력'));
    controller.setActiveEditing(false);
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, contains('저장'));

    controller.dispose();
  });

  testWidgets('add cancel does not write or reload', (tester) async {
    var loads = 0;
    var inserts = 0;
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        return const [];
      },
      insert: (value) async => inserts += 1,
    );

    await tester.tap(find.byKey(const ValueKey('cooperatorAddButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cooperatorIdField')), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(inserts, 0);
    expect(loads, 1);
  });

  testWidgets('add applies empty values once then reloads', (tester) async {
    var loads = 0;
    final inserted = <Cooperator>[];
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        return const [];
      },
      insert: (value) async => inserted.add(value),
    );

    await tester.tap(find.byKey(const ValueKey('cooperatorAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(inserted, hasLength(1));
    expect(inserted.single.id, isEmpty);
    expect(inserted.single.name, isEmpty);
    expect(loads, 2);
    expect(find.text('추가가 완료되었습니다.'), findsOneWidget);
  });

  testWidgets('valid row double tap updates once and reloads', (tester) async {
    var loads = 0;
    final updates = <String>[];
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        return const [Cooperator(id: 'A01', name: '기존 업체')];
      },
      update: (oldId, value) async {
        updates.add('$oldId:${value.id}:${value.name}');
      },
    );

    await _doubleTap(tester, find.text('기존 업체'));
    expect(find.byKey(const ValueKey('cooperatorNameField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('cooperatorNameField')),
      '수정 업체',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(updates, ['A01:A01:수정 업체']);
    expect(loads, 2);
    expect(find.text('수정이 완료되었습니다.'), findsOneWidget);
  });

  testWidgets('failed add keeps manager list without reload or success', (
    tester,
  ) async {
    var loads = 0;
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        return const [Cooperator(id: 'A01', name: '기존 업체')];
      },
      insert: (value) async => throw Exception('DB rejected'),
    );

    await tester.tap(find.byKey(const ValueKey('cooperatorAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('cooperatorIdField')),
      'A02',
    );
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(loads, 1);
    expect(find.text('기존 업체'), findsOneWidget);
    expect(find.textContaining('DB rejected'), findsOneWidget);
    expect(find.text('추가가 완료되었습니다.'), findsNothing);
    expect(find.byKey(const ValueKey('cooperatorIdField')), findsNothing);
  });

  testWidgets('committed add closes after reload failure', (tester) async {
    var loads = 0;
    var closes = 0;
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        if (loads > 1) throw Exception('reload failed');
        return const [];
      },
      insert: (_) async {},
      onClose: () => closes += 1,
    );

    await tester.tap(find.byKey(const ValueKey('cooperatorAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    expect(closes, 0);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });

  testWidgets('delete requires selection password and one warning', (
    tester,
  ) async {
    var deletes = 0;
    var loads = 0;
    await _pumpManager(
      tester,
      load: () async {
        loads += 1;
        return const [Cooperator(id: 'A01', name: '삭제 업체')];
      },
      delete: (id) async => deletes += 1,
      systemPassword: ([now]) => '1234',
    );

    await tester.tap(find.byKey(const ValueKey('cooperatorDeleteButton')));
    await tester.pumpAndSettle();
    expect(find.text('삭제할 행을 먼저 선택해주세요!!'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('삭제 업체'));
    await tester.tap(find.byKey(const ValueKey('cooperatorDeleteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('systemPasswordField')),
      '0000',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(deletes, 0);
    expect(find.textContaining('모든 거래처가 삭제됩니다'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cooperatorDeleteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('systemPasswordField')),
      '1234',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('모든 거래처가 삭제됩니다'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(deletes, 1);
    expect(loads, 2);
    expect(find.text('삭제가 완료되었습니다.'), findsOneWidget);
  });
}

Future<void> _pumpManager(
  WidgetTester tester, {
  required Future<List<Cooperator>> Function() load,
  Future<void> Function(Cooperator value)? insert,
  Future<void> Function(String oldId, Cooperator value)? update,
  Future<void> Function(String id)? delete,
  String Function([DateTime? now])? systemPassword,
  VoidCallback? onClose,
}) async {
  final controller = CooperatorManagerController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 760,
          height: 620,
          child: CooperatorManagerDialogContent(
            controller: controller,
            onClose: onClose ?? () {},
            load: load,
            insert: insert ?? (value) async {},
            update: update ?? (oldId, value) async {},
            delete: delete ?? (id) async {},
            systemPassword: systemPassword ?? ([now]) => '1234',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
}