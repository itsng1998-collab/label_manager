import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login/domain/user_access_serial.dart';

void main() {
  test('임시번호와 시리얼 번호를 레거시 산식으로 계산한다', () {
    final temporary = userAccessTemporaryNumber(
      DateTime(2026, 8, 10, 12, 34, 56),
    );

    expect(temporary, '18529631');
    expect(userAccessSerialNumber(temporary), '13897245');
  });

  test('서버 접속 토큰을 두 구간으로 나눠 로컬 PC 값으로 변환한다', () {
    expect(
      userAccessLocalValue('20260810123456123'),
      '162086495370368383',
    );
  });
}