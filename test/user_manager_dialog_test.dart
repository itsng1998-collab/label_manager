import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/managed_user/domain/managed_user.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/managed_user/presentation/user_manager_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  test('manager lifecycle blocks child and write work', () {
    final controller = UserManagerController();
    controller.setActiveEditing(true);
    expect(controller.snapshot().blockingReason, contains('입력'));
    controller.setActiveEditing(false);
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, contains('작업'));
    controller.dispose();
    controller.setWriteBusy(false);
  });

  testWidgets('restricted cooperator account does not load other cooperators', (
    tester,
  ) async {
    var cooperatorLoads = 0;
    await _pumpManager(
      tester,
      cooperatorSelectionEnabled: false,
      loadCooperators: () async {
        cooperatorLoads += 1;
        return const [Cooperator(id: 'B', name: 'B 업체')];
      },
    );

    expect(cooperatorLoads, 0);
    expect(find.text('김하나'), findsOneWidget);
  });

  testWidgets('credentials are omitted and show-all disables scoped controls', (
    tester,
  ) async {
    await _pumpManager(tester, showCredentials: false);

    expect(find.text('사용자 ID'), findsNothing);
    expect(find.text('비밀번호'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('userShowAllCheckbox')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ModelessDropdownFormField<int>>(
            find.byKey(const ValueKey('userCustomerSelector')),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('userAddButton')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('administrator credentials show user id and password', (
    tester,
  ) async {
    await _pumpManager(tester, showCredentials: true);

    expect(find.text('사용자 ID'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('one'), findsOneWidget);
    expect(find.text('pw'), findsOneWidget);
  });

  testWidgets('scope selectors show aligned labels', (tester) async {
    await _pumpManager(tester);

    final scopeRect = tester.getRect(
      find.byKey(const ValueKey('userScopeSelectors')),
    );
    final cooperatorLabelRect = tester.getRect(
      find.byKey(const ValueKey('userCooperatorLabel')),
    );
    expect(cooperatorLabelRect.left, scopeRect.left);

    for (final pair in const [
      (ValueKey('userCooperatorLabel'), ValueKey('userCooperatorSelector')),
      (ValueKey('userCustomerLabel'), ValueKey('userCustomerSelector')),
      (ValueKey('userMarketLabel'), ValueKey('userMarketSelector')),
    ]) {
      final labelRect = tester.getRect(find.byKey(pair.$1));
      final selectorRect = tester.getRect(find.byKey(pair.$2));
      expect(labelRect.right, lessThanOrEqualTo(selectorRect.left));
      expect(labelRect.center.dy, moreOrLessEquals(selectorRect.center.dy));
    }
  });

  testWidgets('customer selection chooses first market and reloads users', (
    tester,
  ) async {
    final userScopes = <int>[];
    await _pumpManager(
      tester,
      loadUsers: (marketId) async {
        userScopes.add(marketId);
        return [_user('user-$marketId', '이름')];
      },
    );

    await tester.tap(find.byKey(const ValueKey('userCustomerSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B 거래처').last);
    await tester.pumpAndSettle();

    expect(userScopes, [1, 2]);
    expect(find.text('user-2'), findsOneWidget);
  });

  testWidgets('input validates required, password match and duplicate id', (
    tester,
  ) async {
    await _pumpManager(
      tester,
      lookupUser: (id) async => id == 'duplicate' ? _user(id, '기존') : null,
    );

    await tester.tap(find.byKey(const ValueKey('userAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('managedUserApplyButton')));
    await tester.pump();
    expect(find.text('ID를 입력해주세요!'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('managedUserIdField')),
      'duplicate',
    );
    await tester.enterText(
      find.byKey(const ValueKey('managedUserPasswordField')),
      'one',
    );
    await tester.enterText(
      find.byKey(const ValueKey('managedUserPasswordCheckField')),
      'two',
    );
    await tester.enterText(
      find.byKey(const ValueKey('managedUserNameField')),
      '사용자',
    );
    await tester.tap(find.byKey(const ValueKey('managedUserApplyButton')));
    await tester.pump();
    expect(find.textContaining('일치하지않습니다'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('managedUserPasswordCheckField')),
      'one',
    );
    await tester.tap(find.byKey(const ValueKey('managedUserApplyButton')));
    await tester.pumpAndSettle();
    expect(find.textContaining('이미 존재하는 ID입니다'), findsOneWidget);
  });

  testWidgets('name search wraps and connect is disabled without permission', (
    tester,
  ) async {
    await _pumpManager(
      tester,
      initialUsers: [_user('one', '김하나'), _user('two', '김둘')],
    );

    await tester.enterText(find.byKey(const ValueKey('userSearchField')), '김');
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('userDeleteButton')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('userConnectButton')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('authorized manager connects as the selected user', (
    tester,
  ) async {
    ManagedUser? connected;
    await _pumpManager(
      tester,
      canConnect: true,
      connect: (user) async => connected = user,
    );

    await tester.tap(find.text('김하나'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('userConnectButton')));
    await tester.pump();

    expect(connected?.userId, 'one');
  });

  testWidgets('name search centers the matched row in the table viewport', (
    tester,
  ) async {
    final users = [
      for (var index = 0; index < 100; index += 1)
        _user('user-$index', index == 80 ? '검색 대상' : '사용자 $index'),
    ];
    await _pumpManager(tester, initialUsers: users);

    await tester.enterText(
      find.byKey(const ValueKey('userSearchField')),
      '검색 대상',
    );
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.pump();

    final table = tester.widget<FortuneTable<ManagedUser>>(
      find.byKey(const ValueKey('userTable')),
    );
    final verticalPosition = tester
        .widgetList<ListView>(
          find.descendant(
            of: find.byKey(const ValueKey('userTable')),
            matching: find.byType(ListView),
          ),
        )
        .map((list) => list.controller)
        .whereType<ScrollController>()
        .where((controller) => controller.hasClients)
        .map((controller) => controller.position)
        .firstWhere((position) => position.maxScrollExtent > 0);
    final expectedOffset = ((80.5 * table.rowHeight) -
            verticalPosition.viewportDimension / 2)
        .clamp(0.0, verticalPosition.maxScrollExtent);
    expect(verticalPosition.pixels, closeTo(expectedOffset, 1));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('userTable')),
        matching: find.text('검색 대상'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'add defaults to client grade and delete needs one confirmation',
    (tester) async {
      final inserted = <ManagedUser>[];
      final deleted = <String>[];
      await _pumpManager(
        tester,
        insert: (user) async => inserted.add(user),
        delete: (id) async => deleted.add(id),
      );

      await tester.tap(find.byKey(const ValueKey('userAddButton')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('managedUserIdField')),
        'new-user',
      );
      await tester.enterText(
        find.byKey(const ValueKey('managedUserPasswordField')),
        'pw',
      );
      await tester.enterText(
        find.byKey(const ValueKey('managedUserPasswordCheckField')),
        'pw',
      );
      await tester.enterText(
        find.byKey(const ValueKey('managedUserNameField')),
        '새 사용자',
      );
      await tester.tap(find.byKey(const ValueKey('managedUserApplyButton')));
      await tester.pumpAndSettle();
      expect(inserted.single.grade, UserGrade.CLIENT_USER);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('김하나'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('userDeleteButton')));
      await tester.pumpAndSettle();
      expect(find.text('해당 사용자를 정말 삭제하시겠습니까?'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(deleted, ['one']);
    },
  );

  testWidgets('committed delete closes after reload failure', (tester) async {
    var loads = 0;
    var closes = 0;
    await _pumpManager(
      tester,
      loadUsers: (_) async {
        loads += 1;
        if (loads > 1) throw Exception('reload failed');
        return [_user('one', '김하나')];
      },
      delete: (_) async {},
      onClose: () => closes += 1,
    );

    await tester.tap(find.text('김하나'));
  await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userDeleteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });
}

Future<void> _pumpManager(
  WidgetTester tester, {
  bool showCredentials = true,
  bool cooperatorSelectionEnabled = true,
  Future<List<Cooperator>> Function()? loadCooperators,
  List<ManagedUser>? initialUsers,
  Future<List<ManagedUser>> Function(int)? loadUsers,
  Future<ManagedUser?> Function(String)? lookupUser,
  Future<void> Function(ManagedUser)? insert,
  Future<void> Function(String)? delete,
  bool canConnect = false,
  Future<void> Function(ManagedUser)? connect,
  VoidCallback? onClose,
}) async {
  final controller = UserManagerController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1180,
          height: 720,
          child: UserManagerDialogContent(
            controller: controller,
            onClose: onClose ?? () {},
            initialCooperator: const Cooperator(id: 'A', name: 'A 업체'),
            initialCustomer: const Customer(
              customerId: 10,
              cooperatorId: 'A',
              customerName: 'A 거래처',
            ),
            initialMarket: const Market(
              marketId: 1,
              customerId: 10,
              name: 'A 지점',
            ),
            cooperatorSelectionEnabled: cooperatorSelectionEnabled,
            customerSelectionEnabled: true,
            marketSelectionEnabled: true,
            showCredentials: showCredentials,
            loadCooperators: loadCooperators ??
                () async => const [
                  Cooperator(id: 'A', name: 'A 업체'),
                ],
            loadCustomers: (_) async => const [
              Customer(
                customerId: 10,
                cooperatorId: 'A',
                customerName: 'A 거래처',
              ),
              Customer(
                customerId: 20,
                cooperatorId: 'A',
                customerName: 'B 거래처',
              ),
            ],
            loadMarkets: (customerId) async => [
              Market(
                marketId: customerId == 10 ? 1 : 2,
                customerId: customerId,
                name: customerId == 10 ? 'A 지점' : 'B 지점',
              ),
            ],
            loadUsers:
                loadUsers ?? (_) async => initialUsers ?? [_user('one', '김하나')],
            loadCooperatorUsers: (_) async =>
                initialUsers ?? [_user('all', '전체')],
            lookupUser: lookupUser ?? (_) async => null,
            insert: insert ?? (_) async {},
            update: (_, _) async {},
            delete: delete ?? (_) async {},
            canConnect: canConnect,
            connect: connect,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ManagedUser _user(String id, String name) => ManagedUser(
  userId: id,
  marketId: 1,
  name: name,
  password: 'pw',
  grade: UserGrade.MANAGER_USER,
  marketName: '지점',
  customerName: '거래처',
);
