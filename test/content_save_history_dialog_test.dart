import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/content_save_log.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/content_save_history_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  const initialCooperator = Cooperator(id: 'coop1', name: '협력업체 1');
  const otherCooperator = Cooperator(id: 'coop2', name: '협력업체 2');
  const initialCustomer = Customer(
    customerId: 10,
    cooperatorId: 'coop1',
    customerName: '거래처 1',
  );
  const otherCustomer = Customer(
    customerId: 20,
    cooperatorId: 'coop1',
    customerName: '거래처 2',
  );
  const log = ContentSaveLog(
    logId: 1,
    userId: 'user01',
    userGrade: '일반 사용자',
    customerId: 10,
    customerName: '거래처 1',
    labelSizeName: '라벨 1',
    itemName: '상품 1',
    goodsNumber: 30,
    contentColumnsWire: '품명\n가격\n',
    contentsWire: '상품 1\n1000\n',
    saveDate: '2025-01-02 03:04:05',
    saveDateYYYYMMDD: '20250102',
    saveIp: '192.168.0.2',
    saveStatus: ContentSaveStatus.newItem,
    elementRtf: '',
  );

  Future<void> pumpContent(
    WidgetTester tester, {
    required UserGrade grade,
    required ContentSaveHistoryQuery query,
    ValueChanged<String>? onLoadCustomers,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            height: 700,
            child: ContentSaveHistoryDialogContent(
              userGrade: grade,
              initialCooperator: initialCooperator,
              initialCustomer: initialCustomer,
              query: query,
              loadCooperators: () async => const [
                initialCooperator,
                otherCooperator,
              ],
              loadCustomers: (cooperatorId) async {
                onLoadCustomers?.call(cooperatorId);
                return const [initialCustomer, otherCustomer];
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('system admin keeps customer list when cooperator changes', (
    tester,
  ) async {
    var loadCount = 0;
    int? queriedCustomerId;
    await pumpContent(
      tester,
      grade: UserGrade.SYSTEM_ADMIN_USER,
      onLoadCustomers: (_) => loadCount += 1,
      query:
          ({required startDate, required endDate, required customerId}) async {
            queriedCustomerId = customerId;
            return const [log];
          },
    );

    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsOneWidget);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsOneWidget);
    expect(loadCount, 1);

    await tester.tap(find.byType(ModelessDropdownFormField<Cooperator>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협력업체 2').last);
    await tester.pumpAndSettle();

    expect(loadCount, 1);

    await tester.tap(find.byType(ModelessDropdownFormField<Customer>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거래처 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();

    expect(queriedCustomerId, 20);
    expect(find.text('상품 1'), findsOneWidget);

    await tester.tap(find.text('상품 1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('상품 1'));
    await tester.pumpAndSettle();

    expect(find.text('데이터내용 이력 상세'), findsOneWidget);
    expect(find.text('품명'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('coop admin visible customer is ignored by query', (
    tester,
  ) async {
    var queryCount = 0;
    int? queriedCustomerId;
    await pumpContent(
      tester,
      grade: UserGrade.COOP_ADMIN_USER,
      query:
          ({required startDate, required endDate, required customerId}) async {
            queryCount += 1;
            queriedCustomerId = customerId;
            return const <ContentSaveLog>[];
          },
    );

    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsNothing);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsOneWidget);
    expect(queryCount, 0);

    await tester.tap(find.byType(ModelessDropdownFormField<Customer>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거래처 2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('조회'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(queriedCustomerId, 10);
    expect(find.text('검색결과가 없습니다!'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(queryCount, 1);
  });
}
