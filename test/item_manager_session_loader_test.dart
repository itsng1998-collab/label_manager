import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/application/item_manager_session_loader.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/core/user.dart';

void main() {
  const labelSize = LabelSize(
    labelSizeId: 1,
    brandId: 2,
    labelSizeName: '테스트',
    labelSizeCommon: LabelSizeCommon(width: 60, height: 40, rtf: ''),
  );
  const customer = Customer(
    customerId: 10,
    cooperatorId: 'coop',
    customerName: '거래처',
  );
  const user = User(
    userId: 'user',
    marketId: 20,
    name: '사용자',
    pwd: '',
    grade: UserGrade.MANAGER_USER,
    marketName: '매장',
    customerName: '거래처',
  );

  test('로그인 정보가 없으면 DB 조회 전에 실패한다', () async {
    await expectLater(
      loadItemManagerSession(
        labelSize: labelSize,
        customer: null,
        market: null,
        user: null,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '품목관리 편집 세션의 로그인 정보가 없습니다.',
        ),
      ),
    );
  });

  test('현재 매장이 다른 거래처에 속하면 DB 조회 전에 실패한다', () async {
    await expectLater(
      loadItemManagerSession(
        labelSize: labelSize,
        customer: customer,
        market: const Market(marketId: 20, customerId: 11, name: '다른 매장'),
        user: user,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '현재 거래처와 로그인 고객 정보가 일치하지 않습니다.',
        ),
      ),
    );
  });
}