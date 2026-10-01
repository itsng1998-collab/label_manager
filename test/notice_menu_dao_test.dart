import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/update_notice/data/notice_dao.dart';
import 'package:label_manager/features/update_notice/domain/notice.dart';
import 'package:label_manager/features/update_notice/presentation/update_notice_dialog.dart';
import 'package:label_manager/core/user.dart';

void main() {
  test('target users follow legacy customer name order', () {
    expect(NoticeDAO.selectTargetUsersSql, contains('C.RICH_COOP_ID=@cooperatorId'));
    expect(NoticeDAO.selectTargetUsersSql, contains('CUSTOMER_ID'));
    expect(NoticeDAO.selectTargetUsersSql, contains('MARKET_ID'));
    expect(NoticeDAO.selectTargetUsersSql, contains('MARKET_NAME'));
    expect(NoticeDAO.selectTargetUsersSql, contains('ORDER BY C.RICH_NAME'));
  });

  test('notice targets filter by customer and market', () {
    const users = [
      NoticeTargetUser(
        userId: 'alpha',
        customerId: 1,
        customerName: '거래처 A',
        marketId: 10,
        marketName: '지점 A',
      ),
      NoticeTargetUser(
        userId: 'beta',
        customerId: 1,
        customerName: '거래처 A',
        marketId: 11,
        marketName: '지점 B',
      ),
      NoticeTargetUser(
        userId: 'gamma',
        customerId: 2,
        customerName: '거래처 B',
        marketId: 20,
        marketName: '지점 C',
      ),
    ];

    expect(
      filterNoticeTargetUsers(users, customerId: 1).map((user) => user.userId),
      ['alpha', 'beta'],
    );
    expect(
      filterNoticeTargetUsers(users, customerId: 1, marketId: 11)
          .map((user) => user.userId),
      ['beta'],
    );
  });

  test('account ID search is trimmed and case insensitive', () {
    const users = [
      NoticeTargetUser(
        userId: 'Tester01',
        customerId: 1,
        customerName: '거래처',
        marketId: 10,
        marketName: '지점',
      ),
    ];

    expect(findNoticeTargetUserIndex(users, ' tester '), 0);
    expect(findNoticeTargetUserIndex(users, 'missing'), -1);
  });

  test('administrator target statements create missing selected notice', () {
    final selected = NoticeDAO.selectedUserStatement(
      userId: 'user1',
      message: '공지',
    );
    expect(selected.params, {
      'userId': 'user1',
      'message': '공지',
      'version': appVersion,
    });
    expect(selected.sql, contains('UN_STATE=0'));
    expect(selected.sql, contains('IF @@ROWCOUNT = 0'));
    expect(selected.sql, contains('INSERT INTO BM_UPDATE_NOTICE'));
    expect(NoticeDAO.updateAllSql, contains('UN_STATE=2'));
    expect(NoticeDAO.updateCooperatorSql, contains('UN_COOP_ID=@cooperatorId'));
    expect(NoticeDAO.updateAllSql, isNot(contains('UN_VERSION')));
  });

  test('regular user statement never updates message', () {
    expect(NoticeDAO.updateUserStateSql, contains('UN_STATE=@state'));
    expect(NoticeDAO.updateUserStateSql, isNot(contains('UN_MSG')));
  });

  test('selected user mode rejects an empty selection before DML', () {
    expect(
      () => NoticeDAO.updateSelectedUsers(userIds: const [], message: '공지'),
      throwsArgumentError,
    );
  });

  test('system administrator target priority follows legacy order', () {
    expect(
      resolveUpdateNoticeSaveTarget(
        grade: UserGrade.SYSTEM_ADMIN_USER,
        selectUsers: true,
        allCooperators: true,
      ),
      UpdateNoticeSaveTarget.selectedUsers,
    );
    expect(
      resolveUpdateNoticeSaveTarget(
        grade: UserGrade.SYSTEM_ADMIN_USER,
        selectUsers: false,
        allCooperators: true,
      ),
      UpdateNoticeSaveTarget.allCooperators,
    );
    expect(
      resolveUpdateNoticeSaveTarget(
        grade: UserGrade.SYSTEM_ADMIN_USER,
        selectUsers: false,
        allCooperators: false,
      ),
      UpdateNoticeSaveTarget.currentCooperator,
    );
  });

  test('cooperator administrator cannot expand beyond current cooperator', () {
    expect(
      resolveUpdateNoticeSaveTarget(
        grade: UserGrade.COOP_ADMIN_USER,
        selectUsers: false,
        allCooperators: true,
      ),
      UpdateNoticeSaveTarget.currentCooperator,
    );
    expect(
      resolveUpdateNoticeSaveTarget(
        grade: UserGrade.COOP_ADMIN_USER,
        selectUsers: true,
        allCooperators: false,
      ),
      UpdateNoticeSaveTarget.selectedUsers,
    );
  });

  test('non-administrator grades always update current user state', () {
    for (final grade in [UserGrade.MANAGER_USER, UserGrade.CLIENT_USER]) {
      expect(
        resolveUpdateNoticeSaveTarget(
          grade: grade,
          selectUsers: true,
          allCooperators: true,
        ),
        UpdateNoticeSaveTarget.currentUser,
      );
    }
  });

  test('save request separates administrator message from user state', () {
    const administrator = UpdateNoticeSaveRequest(
      target: UpdateNoticeSaveTarget.currentCooperator,
      message: '공지',
      selectedUserIds: [],
      dontShowAgain: true,
    );
    const regularUser = UpdateNoticeSaveRequest(
      target: UpdateNoticeSaveTarget.currentUser,
      message: null,
      selectedUserIds: [],
      dontShowAgain: true,
    );
    expect(administrator.message, '공지');
    expect(regularUser.message, isNull);
    expect(regularUser.dontShowAgain, isTrue);
  });

  testWidgets('dialog-level Enter saves once and closes for regular user', (
    tester,
  ) async {
    const user = User(
      userId: 'user1',
      marketId: 1,
      name: '사용자',
      pwd: '',
      grade: UserGrade.CLIENT_USER,
      marketName: '지점',
      customerName: '거래처',
    );
    var saveCount = 0;
    var closeCount = 0;
    UpdateNoticeSaveRequest? savedRequest;
    final controller = UpdateNoticeDialogController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateNoticeDialog(
            controller: controller,
            user: user,
            notice: const Notice(message: '공지', state: 1),
            targetUsers: const [],
            onSave: (request) async {
              saveCount++;
              savedRequest = request;
            },
            onClose: () => closeCount++,
            onCommitOutcomeUnknown: () => closeCount++,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText).first).focusNode.hasFocus,
      isTrue,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('notice-content-area'))).width,
      tester.getSize(find.byKey(const ValueKey('notice-ad-area'))).width,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(saveCount, 1);
    expect(closeCount, 1);
    expect(savedRequest?.target, UpdateNoticeSaveTarget.currentUser);
    expect(savedRequest?.message, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final useAlt in [false, true]) {
    testWidgets('administrator message ${useAlt ? 'Alt+Enter' : 'Enter'} does not save', (
      tester,
    ) async {
      final controller = UpdateNoticeDialogController();
      addTearDown(controller.dispose);
      var saveCount = 0;
      var closeCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateNoticeDialog(
              controller: controller,
              user: _systemAdministrator,
              notice: const Notice(message: '첫 줄', state: 0),
              targetUsers: const [],
              onSave: (_) async => saveCount++,
              onClose: () => closeCount++,
              onCommitOutcomeUnknown: () => closeCount++,
            ),
          ),
        ),
      );
      await tester.pump();
      final contentField = find.descendant(
        of: find.byKey(const ValueKey('notice-content-area')),
        matching: find.byType(EditableText),
      );
      await tester.tap(contentField);
      await tester.pump();
      if (useAlt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      if (useAlt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();

      expect(saveCount, 0);
      expect(closeCount, 0);
      expect(find.byType(UpdateNoticeDialog), findsOneWidget);
      final editingController = tester.widget<EditableText>(contentField).controller;
      expect(editingController.text, '첫 줄\n');
      expect(editingController.selection.baseOffset, 4);

      if (useAlt) await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      if (useAlt) await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(editingController.text, '첫 줄\n\n\n');
      expect(saveCount, 0);
      expect(closeCount, 0);

      editingController.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(editingController.text, '\n 줄\n\n\n');
      expect(editingController.selection.baseOffset, 1);
      expect(saveCount, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('unknown commit outcome is shown once and closes the dialog', (
    tester,
  ) async {
    const user = User(
      userId: 'user1',
      marketId: 1,
      name: '사용자',
      pwd: '',
      grade: UserGrade.CLIENT_USER,
      marketName: '지점',
      customerName: '거래처',
    );
    final controller = UpdateNoticeDialogController();
    addTearDown(controller.dispose);
    var saveCount = 0;
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateNoticeDialog(
            controller: controller,
            user: user,
            notice: const Notice(message: '공지', state: 0),
            targetUsers: const [],
            onSave: (_) async {
              saveCount++;
              throw const DbCommitOutcomeUnknown('commit outcome unknown');
            },
            onClose: () {},
            onCommitOutcomeUnknown: () => closeCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(saveCount, 1);
    expect(find.textContaining('commit outcome unknown'), findsOneWidget);
    expect(closeCount, 0);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closeCount, 1);
    expect(saveCount, 1);
  });

  testWidgets('notice target filter keeps selections outside current results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = UpdateNoticeDialogController();
    addTearDown(controller.dispose);
    UpdateNoticeSaveRequest? savedRequest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateNoticeDialog(
            controller: controller,
            user: _systemAdministrator,
            notice: const Notice(message: '공지', state: 0),
            targetUsers: _filterTargetUsers,
            onSave: (request) async => savedRequest = request,
            onClose: () {},
            onCommitOutcomeUnknown: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, '사용자 선택'));
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notice-target-user-alpha')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('notice-target-customer-filter')),
    );
    await tester.pump();
    await tester.tap(find.text('거래처 B'));
    await tester.pump();

    expect(find.byKey(const ValueKey('notice-target-user-alpha')), findsNothing);
    expect(
      find.byKey(const ValueKey('notice-target-user-gamma')),
      findsOneWidget,
    );
    expect(find.text('선택 1명'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notice-target-user-gamma')),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pump();

    expect(savedRequest?.selectedUserIds, containsAll(['alpha', 'gamma']));
  });

  testWidgets('account ID search scrolls to a matching target without saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = UpdateNoticeDialogController();
    addTearDown(controller.dispose);
    var saveCount = 0;
    final users = List.generate(
      30,
      (index) => NoticeTargetUser(
        userId: 'user${index.toString().padLeft(2, '0')}',
        customerId: 1,
        customerName: '거래처',
        marketId: 10,
        marketName: '지점',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateNoticeDialog(
            controller: controller,
            user: _systemAdministrator,
            notice: const Notice(message: '공지', state: 0),
            targetUsers: users,
            onSave: (_) async => saveCount++,
            onClose: () {},
            onCommitOutcomeUnknown: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, '사용자 선택'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('notice-target-account-search')),
      'USER29',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('notice-target-user-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(scrollable).position.pixels, greaterThan(0));
    expect(
      find.byKey(const ValueKey('notice-target-user-user29')),
      findsOneWidget,
    );
    expect(saveCount, 0);
  });

  test('controller exposes dirty and write-busy exit state', () {
    final controller = UpdateNoticeDialogController();
    addTearDown(controller.dispose);

    expect(controller.snapshot().dirtyWorks, isEmpty);
    controller.setDirty(true);
    expect(controller.snapshot().dirtyWorks.single.name, '업데이트 메시지');
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, isNotNull);
  });
}

const _systemAdministrator = User(
  userId: User.SYSTEM,
  marketId: 1,
  name: '시스템 관리자',
  pwd: '',
  grade: UserGrade.SYSTEM_ADMIN_USER,
  marketName: '지점',
  customerName: '거래처',
);

const _filterTargetUsers = [
  NoticeTargetUser(
    userId: 'alpha',
    customerId: 1,
    customerName: '거래처 A',
    marketId: 10,
    marketName: '지점 A',
  ),
  NoticeTargetUser(
    userId: 'beta',
    customerId: 1,
    customerName: '거래처 A',
    marketId: 11,
    marketName: '지점 B',
  ),
  NoticeTargetUser(
    userId: 'gamma',
    customerId: 2,
    customerName: '거래처 B',
    marketId: 20,
    marketName: '지점 C',
  ),
];