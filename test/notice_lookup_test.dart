import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/application/startup_login_service.dart';
import 'package:label_manager/features/update_notice/data/notice_dao.dart';

void main() {
  for (final asJson in [false, true]) {
    Object result(List<Map<String, dynamic>> rows) {
      final value = <String, dynamic>{'rows': rows};
      return asJson ? jsonEncode(value) : value;
    }

    test('missing notice is empty and suppressed without DB writes (json=$asJson)', () async {
      var reads = 0;
      final notice = await NoticeDAO.selectNoticeByUserId(
        'testflutter',
        read: (sql, params) async {
          reads++;
          expect(sql, NoticeDAO.selectSql);
          expect(params, {'userId': 'testflutter'});
          return result([]);
        },
      );
      expect(reads, 1);
      expect(notice.message, isEmpty);
      expect(notice.state, 1);
    });

    for (final state in [0, 1, 2]) {
      test('existing notice keeps message and state=$state (json=$asJson)', () async {
        final notice = await NoticeDAO.selectNoticeByUserId(
          'existing',
          read: (_, _) async => result([
            {'UN_MSG': 'Update notice', 'UN_STATE': state},
          ]),
        );
        expect(notice.message, 'Update notice');
        expect(notice.state, state);
      });
    }
  }

  test('notice lookup propagates actual query errors', () async {
    final error = StateError('database query failed');
    await expectLater(
      NoticeDAO.selectNoticeByUserId('testflutter', read: (_, _) async => throw error),
      throwsA(same(error)),
    );
  });

  test('notice lookup does not mask malformed responses', () async {
    await expectLater(
      NoticeDAO.selectNoticeByUserId('testflutter', read: (_, _) async => 'invalid json'),
      throwsFormatException,
    );
  });

  test('message-only lookup shares missing-notice semantics', () async {
    final message = await NoticeDAO.selectByUserId(
      'new-user',
      read: (_, _) async => <String, dynamic>{'rows': []},
    );
    expect(message, isEmpty);
  });

  test('new account without notice still reaches user lookup', () async {
    const user = User(
      userId: 'new-user',
      marketId: 10,
      name: 'New user',
      pwd: '0000',
      grade: UserGrade.MANAGER_USER,
      marketName: 'Test market',
      customerName: 'Test customer',
    );
    final calls = <String>[];
    final service = StartupLoginService(
      loadNotice: (id) => NoticeDAO.selectNoticeByUserId(
        id,
        read: (_, params) async {
          calls.add('notice:${params['userId']}');
          return <String, dynamic>{'rows': []};
        },
      ),
      loadUser: (id) async {
        calls.add('user:$id');
        return id == user.userId ? user : null;
      },
    );

    final found = await service.lookupUser(user.userId);
    expect(calls, ['notice:new-user', 'user:new-user']);
    expect(found.user, same(user));
    expect(found.user!.pwd, '0000');
    expect(found.notice.message, isEmpty);
    expect(found.notice.state, 1);

    final missing = await service.lookupUser('unknown-user');
    expect(missing.user, isNull);
  });

  test('notice query failure remains an error before user lookup', () async {
    var userLoaded = false;
    final error = StateError('notice database unavailable');
    final service = StartupLoginService(
      loadNotice: (id) => NoticeDAO.selectNoticeByUserId(
        id,
        read: (_, _) async => throw error,
      ),
      loadUser: (_) async {
        userLoaded = true;
        return null;
      },
    );
    await expectLater(service.lookupUser('new-user'), throwsA(same(error)));
    expect(userLoaded, isFalse);
  });
}
