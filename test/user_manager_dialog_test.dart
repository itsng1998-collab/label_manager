import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/managed_user.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/user_manager_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

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

  testWidgets('name search wraps and connect invokes selected row', (
    tester,
  ) async {
    final connected = <String>[];
    await _pumpManager(
      tester,
      initialUsers: [_user('one', '김하나'), _user('two', '김둘')],
      connect: (user) async => connected.add(user.userId),
    );

    await tester.enterText(find.byKey(const ValueKey('userSearchField')), '김');
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userSearchButton')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('userConnectButton')));
    await tester.pumpAndSettle();

    expect(connected, ['one']);
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
  List<ManagedUser>? initialUsers,
  Future<List<ManagedUser>> Function(int)? loadUsers,
  Future<ManagedUser?> Function(String)? lookupUser,
  Future<void> Function(ManagedUser)? connect,
  Future<void> Function(ManagedUser)? insert,
  Future<void> Function(String)? delete,
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
            cooperatorSelectionEnabled: true,
            customerSelectionEnabled: true,
            marketSelectionEnabled: true,
            showCredentials: showCredentials,
            connect: connect ?? (user) async {},
            loadCooperators: () async => const [
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
