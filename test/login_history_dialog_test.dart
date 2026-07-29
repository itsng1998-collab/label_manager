import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login_history/domain/login_log.dart';
import 'package:label_manager/features/login_history/presentation/login_history_page.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/user.dart';

void main() {
  const initialCooperator = Cooperator(id: 'coop1', name: '협력업체 1');
  const initialCustomer = Customer(
    customerId: 10,
    cooperatorId: 'coop1',
    customerName: '거래처 1',
  );

  Future<void> pumpContent(
    WidgetTester tester, {
    required UserGrade grade,
    required LoginHistoryQuery query,
    String cooperatorName = '협력업체 1',
    String customerName = '거래처 1',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 700,
            child: LoginHistoryDialogContent(
              userGrade: grade,
              initialCooperator: initialCooperator,
              initialCustomer: initialCustomer,
              query: query,
              loadCooperators: () async => [
                Cooperator(id: 'coop1', name: cooperatorName),
              ],
              loadCustomers: (_) async => [
                Customer(
                  customerId: 10,
                  cooperatorId: 'coop1',
                  customerName: customerName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('system admin sees both selectors without automatic query', (
    tester,
  ) async {
    var queryCount = 0;
    await pumpContent(
      tester,
      grade: UserGrade.SYSTEM_ADMIN_USER,
      query: ({required startDate, required endDate, required customerId}) async {
        queryCount += 1;
        expect(customerId, 10);
        return const [
          LoginLog(
            logId: 1,
            userId: 'user01',
            userGrade: '일반 사용자',
            programVersion: '1.0.0',
            customerId: 10,
            customerName: '거래처 1',
            loginDate: '2025-01-02 03:04:05',
            loginDateYYYYMMDD: '20250102',
            loginIP: '192.168.0.2',
            loginCondition: LoginCondition.LOGIN,
          ),
        ];
      },
    );

    expect(find.text('협력업체'), findsOneWidget);
    expect(find.text('거래처'), findsOneWidget);
    expect(find.text('조회'), findsOneWidget);
    expect(queryCount, 0);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();

    expect(queryCount, 1);
    expect(find.text('user01'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });

  testWidgets('client hides both selectors and keeps query available', (
    tester,
  ) async {
    var queryCount = 0;
    await pumpContent(
      tester,
      grade: UserGrade.CLIENT_USER,
      query: ({required startDate, required endDate, required customerId}) async {
        queryCount += 1;
        return const <LoginLog>[];
      },
    );

    expect(find.text('협력업체'), findsNothing);
    expect(find.text('거래처'), findsNothing);
    expect(find.text('조회'), findsOneWidget);
    expect(queryCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long filter names stay within fixed selector widths', (
    tester,
  ) async {
    await pumpContent(
      tester,
      grade: UserGrade.SYSTEM_ADMIN_USER,
      query: ({required startDate, required endDate, required customerId}) async =>
          const <LoginLog>[],
      cooperatorName: '아주 긴 협력업체 이름이 선택 영역을 넘어가는 경우',
      customerName: '아주 긴 거래처 이름이 선택 영역을 넘어가는 경우',
    );

    expect(tester.takeException(), isNull);
  });
}