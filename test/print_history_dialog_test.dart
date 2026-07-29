import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/print_history/domain/print_log.dart';
import 'package:label_manager/features/print_history/presentation/print_history_dialog.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  const initialCooperator = Cooperator(id: 'coop1', name: '협력업체 1');
  const initialCustomer = Customer(
    customerId: 10,
    cooperatorId: 'coop1',
    customerName: '거래처 1',
  );

  PrintLog printLog() => const PrintLog(
    logId: 1,
    userId: 'user01',
    userName: '사용자 1',
    userGrade: 3,
    marketId: 1,
    marketName: '지점 1',
    customerId: 10,
    customerName: '거래처 1',
    brandName: '브랜드 1',
    labelSizeName: '라벨 1',
    itemName: '상품 1',
    printCount: 4,
    dateTime: '2025-01-02 03:04:05',
    dateYYYYMMDD: '20250102',
    printerName: '프린터 1',
    columnsWire: '품명|가격|',
    printCellsWire: '상품 1|1000|',
    savedCellsWire: '상품 1|900|',
    formWidth: 60,
    formHeight: 40,
    leftMargin: 1,
    rightMargin: 2,
    topMargin: 3,
    leftPush: 4,
    topPush: 5,
    appendant: 6,
    itemId: 20,
  );

  Future<void> pumpContent(
    WidgetTester tester, {
    required UserGrade grade,
    required PrintHistoryQuery query,
    required PrintHistorySumQuery querySum,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1400,
            height: 800,
            child: PrintHistoryDialogContent(
              userGrade: grade,
              initialCooperator: initialCooperator,
              initialCustomer: initialCustomer,
              query: query,
              querySum: querySum,
              loadCooperators: () async => const [initialCooperator],
              loadCustomers: (_) async => const [initialCustomer],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('system admin queries current customer and opens row detail', (
    tester,
  ) async {
    var queryCount = 0;
    final sumCalls = <({String? customer, String? labelSize})>[];
    await pumpContent(
      tester,
      grade: UserGrade.SYSTEM_ADMIN_USER,
      query:
          ({
            required startDate,
            required endDate,
            required searchType,
            required searchText,
            customerId,
          }) async {
            queryCount += 1;
            expect(searchType, PrintLogSearchType.itemName);
            expect(searchText, isEmpty);
            expect(customerId, 10);
            return [printLog()];
          },
      querySum: ({startDate, endDate, customerName, labelSizeName}) async {
        sumCalls.add((customer: customerName, labelSize: labelSizeName));
        if (labelSizeName != null) return 4;
        return startDate == null ? 100 : 10;
      },
    );

    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsOneWidget);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsOneWidget);
    expect(find.text('품명'), findsWidgets);
    expect(queryCount, 0);

    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();

    expect(queryCount, 1);
    expect(sumCalls, [
      (customer: '거래처 1', labelSize: null),
      (customer: '거래처 1', labelSize: null),
      (customer: '거래처 1', labelSize: '라벨 1'),
    ]);
    expect(find.text('[총 누계]'), findsOneWidget);
    expect(find.text('[기간별 합계]'), findsOneWidget);
    expect(find.text('[라벨사이즈별 합계] 라벨 1'), findsOneWidget);
    expect(find.text('상품 1'), findsOneWidget);

    await tester.tap(find.text('상품 1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('상품 1'));
    await tester.pumpAndSettle();

    expect(find.text('발행내역 상세'), findsOneWidget);
    expect(find.text('저장값'), findsOneWidget);
    expect(find.text('출력값'), findsOneWidget);
    expect(find.text('900'), findsOneWidget);
    expect(find.text('1000'), findsOneWidget);
  });

  testWidgets('client hides selectors and Enter queries current customer', (
    tester,
  ) async {
    var queryCount = 0;
    await pumpContent(
      tester,
      grade: UserGrade.CLIENT_USER,
      query:
          ({
            required startDate,
            required endDate,
            required searchType,
            required searchText,
            customerId,
          }) async {
            queryCount += 1;
            expect(customerId, 10);
            return const <PrintLog>[];
          },
      querySum: ({startDate, endDate, customerName, labelSizeName}) async => 0,
    );

    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsNothing);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsNothing);
    expect(queryCount, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(queryCount, 1);
    expect(find.text('[총 누계]'), findsOneWidget);
    expect(find.text('[기간별 합계]'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(queryCount, 2);
  });

  testWidgets('all customers keeps query and summaries in global scope', (
    tester,
  ) async {
    int? queriedCustomerId = 99;
    final summaryCustomers = <String?>[];
    await pumpContent(
      tester,
      grade: UserGrade.SYSTEM_ADMIN_USER,
      query:
          ({
            required startDate,
            required endDate,
            required searchType,
            required searchText,
            customerId,
          }) async {
            queriedCustomerId = customerId;
            return const <PrintLog>[];
          },
      querySum: ({startDate, endDate, customerName, labelSizeName}) async {
        summaryCustomers.add(customerName);
        return 0;
      },
    );

    await tester.tap(find.byType(ModelessDropdownFormField<Customer>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('[전체 보기]').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();

    expect(queriedCustomerId, isNull);
    expect(summaryCustomers, [null, null]);
    expect(find.text('[총 누계]'), findsOneWidget);
    expect(find.text('[기간별 합계]'), findsOneWidget);
  });
}
