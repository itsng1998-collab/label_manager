import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/notice.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/update_notice_dialog.dart';

void main() {
  test('target users follow legacy customer name order', () {
    expect(NoticeDAO.SelectTargetUsersSql, contains('C.RICH_COOP_ID=@cooperatorId'));
    expect(NoticeDAO.SelectTargetUsersSql, contains('ORDER BY C.RICH_NAME'));
  });

  test('administrator target statements update only active notice fields', () {
    final selected = NoticeDAO.selectedUserStatement(
      userId: 'user1',
      message: '공지',
    );
    expect(selected.params, {'userId': 'user1', 'message': '공지'});
    expect(selected.sql, contains('UN_STATE=0'));
    expect(NoticeDAO.UpdateAllSql, contains('UN_STATE=2'));
    expect(NoticeDAO.UpdateCooperatorSql, contains('UN_COOP_ID=@cooperatorId'));
    expect(NoticeDAO.UpdateAllSql, isNot(contains('UN_VERSION')));
  });

  test('regular user statement never updates message', () {
    expect(NoticeDAO.UpdateUserStateSql, contains('UN_STATE=@state'));
    expect(NoticeDAO.UpdateUserStateSql, isNot(contains('UN_MSG')));
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateNoticeDialog(
            user: user,
            notice: const Notice(message: '공지', state: 1),
            targetUsers: const [],
            onSave: (request) async {
              saveCount++;
              savedRequest = request;
            },
            onClose: () => closeCount++,
          ),
        ),
      ),
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
}