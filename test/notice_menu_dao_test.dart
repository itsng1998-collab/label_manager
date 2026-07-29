import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/update_notice/data/notice_dao.dart';
import 'package:label_manager/features/update_notice/domain/notice.dart';
import 'package:label_manager/features/update_notice/presentation/update_notice_dialog.dart';
import 'package:label_manager/core/user.dart';

void main() {
  test('target users follow legacy customer name order', () {
    expect(NoticeDAO.selectTargetUsersSql, contains('C.RICH_COOP_ID=@cooperatorId'));
    expect(NoticeDAO.selectTargetUsersSql, contains('ORDER BY C.RICH_NAME'));
  });

  test('administrator target statements update only active notice fields', () {
    final selected = NoticeDAO.selectedUserStatement(
      userId: 'user1',
      message: '공지',
    );
    expect(selected.params, {'userId': 'user1', 'message': '공지'});
    expect(selected.sql, contains('UN_STATE=0'));
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