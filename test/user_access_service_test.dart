import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/application/user_access_service.dart';
import 'package:label_manager/features/login/domain/user_access_serial.dart';

void main() {
  const user = User(
    userId: 'user',
    marketId: 1,
    name: '사용자',
    pwd: 'pw',
    grade: UserGrade.CLIENT_USER,
    marketName: '지점',
    customerName: '거래처',
  );
  const serverData = '20260810123456123';

  test('관리자와 마스터키 로그인을 PC 시리얼 인증에서 제외한다', () {
    expect(
      userAccessAuthorizationRequired(LoginAuthenticationMode.regular),
      isTrue,
    );
    expect(
      userAccessAuthorizationRequired(LoginAuthenticationMode.firstAdmin),
      isFalse,
    );
    expect(
      userAccessAuthorizationRequired(LoginAuthenticationMode.masterKey),
      isFalse,
    );
  });

  test('서버와 로컬 PC 값이 같으면 시리얼 인증 없이 통과한다', () async {
    var prompted = false;
    final service = UserAccessService(
      loadAccessData: (_) async => serverData,
      readLocalValue: () async => userAccessLocalValue(serverData),
      saveAccessData: (_, _) async => throw StateError('저장하면 안 됨'),
      writeLocalValue: (_) async => throw StateError('저장하면 안 됨'),
    );

    final result = await service.authorize(
      user: user,
      promptSerial: (_) async {
        prompted = true;
        return true;
      },
    );

    expect(result, isTrue);
    expect(prompted, isFalse);
  });

  test('서버와 로컬에 접속 정보가 없으면 현재 PC를 자동 등록한다', () async {
    String? stored;
    final service = UserAccessService(
      loadAccessData: (_) async => null,
      readLocalValue: () async => '',
      saveAccessData: (userId, userName) async {
        expect(userId, 'user');
        expect(userName, '사용자');
        return serverData;
      },
      writeLocalValue: (value) async => stored = value,
    );

    expect(
      await service.authorize(
        user: user,
        promptSerial: (_) async => throw StateError('표시하면 안 됨'),
      ),
      isTrue,
    );
    expect(stored, userAccessLocalValue(serverData));
  });

  test('PC 값이 다르면 임시번호 인증 성공 후 서버와 로컬을 갱신한다', () async {
    String? stored;
    final service = UserAccessService(
      loadAccessData: (_) async => serverData,
      readLocalValue: () async => 'other-pc',
      saveAccessData: (_, _) async => '20260810150000999',
      writeLocalValue: (value) async => stored = value,
      now: () => DateTime(2026, 8, 10, 12, 34, 56),
    );

    final result = await service.authorize(
      user: user,
      promptSerial: (temporaryNumber) async {
        expect(temporaryNumber, '18529631');
        return true;
      },
    );

    expect(result, isTrue);
    expect(stored, userAccessLocalValue('20260810150000999'));
  });

  test('시리얼 인증 성공 후 같은 PC 재로그인은 인증을 생략한다', () async {
    var serverValue = serverData;
    var localValue = 'other-pc';
    var promptCount = 0;
    final service = UserAccessService(
      loadAccessData: (_) async => serverValue,
      readLocalValue: () async => localValue,
      saveAccessData: (_, _) async {
        serverValue = '20260810150000999';
        return serverValue;
      },
      writeLocalValue: (value) async => localValue = value,
      now: () => DateTime(2026, 8, 10, 12, 34, 56),
    );

    Future<bool> authorize() => service.authorize(
      user: user,
      promptSerial: (_) async {
        promptCount += 1;
        return true;
      },
    );

    expect(await authorize(), isTrue);
    expect(await authorize(), isTrue);
    expect(promptCount, 1);
  });

  test('PC 값이 다르고 시리얼 인증을 취소하면 저장하지 않는다', () async {
    var saved = false;
    final service = UserAccessService(
      loadAccessData: (_) async => serverData,
      readLocalValue: () async => 'other-pc',
      saveAccessData: (_, _) async {
        saved = true;
        return serverData;
      },
      writeLocalValue: (_) async {},
    );

    expect(
      await service.authorize(
        user: user,
        promptSerial: (_) async => false,
      ),
      isFalse,
    );
    expect(saved, isFalse);
  });
}