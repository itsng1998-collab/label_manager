import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/features/status_print/domain/status_print.dart';
import 'package:label_manager/features/status_print/presentation/status_print_dialog.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  const initialCooperator = Cooperator(id: 'coop1', name: '협력업체 1');
  const secondCooperator = Cooperator(id: 'coop2', name: '협력업체 2');
  const initialCustomer = Customer(
    customerId: 10,
    cooperatorId: 'coop1',
    customerName: '거래처 1',
  );
  const secondCustomer = Customer(
    customerId: 20,
    cooperatorId: 'coop2',
    customerName: '거래처 2',
  );
  const brand1 = Brand(brandId: 100, customerId: 10, brandName: '브랜드 1');
  const brand2 = Brand(brandId: 200, customerId: 10, brandName: '브랜드 2');
  const label1 = LabelSize(
    labelSizeId: 1000,
    brandId: 100,
    labelSizeName: '라벨 1',
  );
  const label2 = LabelSize(
    labelSizeId: 2000,
    brandId: 200,
    labelSizeName: '라벨 2',
  );

  StatusPrintRow result({bool deleted = false}) => StatusPrintRow(
    statusId: 'status-1',
    printDate: '2025-01-02 03:04:05',
    printCount: 4,
    itemName: '상품 1',
    itemElement: '원료 1',
    searchValue: '원료 1',
    brandName: '브랜드 1',
    labelSizeName: '라벨 1',
    itemChangeDeleteDate: deleted ? '2025-01-03' : '',
  );

  Future<void> pumpContent(
    WidgetTester tester, {
    required UserGrade grade,
    required StatusPrintQuery query,
    StatusPrintDetailQuery? queryDetail,
    StatusPrintCustomerLoader? loadCustomers,
    StatusPrintBrandLoader? loadBrands,
    StatusPrintColumnNamesLoader? loadColumnNames,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusPrintDialogContent(
            userGrade: grade,
            initialCooperator: initialCooperator,
            initialCustomer: initialCustomer,
            query: query,
            queryDetail:
                queryDetail ??
                (_) async => const StatusPrintDetail(
                  itemName: '',
                  itemElement: '',
                  itemChangeDeleteDate: '',
                  rows: [],
                ),
            loadCooperators: () async => const [
              initialCooperator,
              secondCooperator,
            ],
            loadCustomers:
                loadCustomers ??
                (cooperatorId) async => cooperatorId == 'coop1'
                    ? const [initialCustomer]
                    : const [secondCustomer],
            loadBrands:
                loadBrands ??
                (customerId) async => customerId == 10
                    ? const [brand1, brand2]
                    : const [
                        Brand(
                          brandId: 300,
                          customerId: 20,
                          brandName: '브랜드 3',
                        ),
                      ],
            loadLabelSizes: (brandId) async => switch (brandId) {
              100 => const [label1],
              200 => const [label2],
              _ => const [
                  LabelSize(
                    labelSizeId: 3000,
                    brandId: 300,
                    labelSizeName: '라벨 3',
                  ),
                ],
            },
            loadColumnNames:
                loadColumnNames ??
                (labelSizeIds) async => [
                  '원산지',
                  if (labelSizeIds.contains(1000)) '가격',
                  if (labelSizeIds.contains(2000)) '중량',
                ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'system admin cascade uses selected customer and default partial element',
    (tester) async {
      var queryCount = 0;
      var columnLoadCount = 0;
      List<int>? loadedColumnLabelSizeIds;
      StatusPrintQuerySpec? received;
      await pumpContent(
        tester,
        grade: UserGrade.SYSTEM_ADMIN_USER,
        query: (spec) async {
          queryCount += 1;
          received = spec;
          return const [];
        },
        loadColumnNames: (labelSizeIds) async {
          columnLoadCount += 1;
          loadedColumnLabelSizeIds = labelSizeIds;
          return const ['원산지', '가격', '중량'];
        },
      );

      expect(find.text('협력업체'), findsOneWidget);
      expect(find.text('거래처'), findsOneWidget);
      expect(find.text('[전체 보기]'), findsNWidgets(2));
      expect(find.text(statusPrintElementColumn), findsWidgets);
      expect(queryCount, 0);
      expect(columnLoadCount, 1);
      expect(loadedColumnLabelSizeIds, [1000, 2000]);
      final initialTable = tester.widget<FortuneTable<StatusPrintTableRow>>(
        find.byType(FortuneTable<StatusPrintTableRow>),
      );
      expect(
        initialTable.columns
            .singleWhere((column) => column.id == 'searchValue')
            .initialWidth,
        420,
      );

      await tester.tap(
        find.widgetWithText(
          ModelessDropdownFormField<String>,
          statusPrintElementColumn,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('원산지'), findsOneWidget);
      expect(find.text('가격'), findsOneWidget);
      expect(find.text('중량'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(
          ModelessDropdownFormField<String>,
          initialCooperator.name,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('협력업체 2').last);
      await tester.pumpAndSettle();
      expect(find.text('거래처 2'), findsOneWidget);

      await tester.tap(find.text('조회'));
      await tester.pumpAndSettle();

      expect(queryCount, 1);
      expect(received?.customerId, 20);
      expect(received?.brandId, isNull);
      expect(received?.labelSizeId, isNull);
      expect(received?.searchColumn, statusPrintElementColumn);
      expect(received?.exactMatch, isFalse);
    },
  );

  testWidgets('zero result keeps two summaries without alert and Enter once', (
    tester,
  ) async {
    var queryCount = 0;
    await pumpContent(
      tester,
      grade: UserGrade.CLIENT_USER,
      query: (spec) async {
        queryCount += 1;
        expect(spec.customerId, initialCustomer.customerId);
        return const [];
      },
    );

    expect(find.text('협력업체'), findsNothing);
    expect(find.text('거래처'), findsNothing);
    expect(queryCount, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(queryCount, 1);
    expect(find.text('[총 발행 매수]'), findsOneWidget);
    expect(find.text('[삭제된 품목 매수]'), findsOneWidget);
    final table = tester.widget<FortuneTable<StatusPrintTableRow>>(
      find.byType(FortuneTable<StatusPrintTableRow>),
    );
    expect(table.columns.first.text(table.rows.first), '[총 발행 매수]');
    expect(table.columns[2].text(table.rows.first), '');
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byType(TextField).first);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(queryCount, 2);
  });

  testWidgets('only actual row opens detail and summaries use required colors', (
    tester,
  ) async {
    var detailCount = 0;
    await pumpContent(
      tester,
      grade: UserGrade.CLIENT_USER,
      query: (_) async => [result(deleted: true)],
      queryDetail: (statusId) async {
        detailCount += 1;
        expect(statusId, 'status-1');
        return const StatusPrintDetail(
          itemName: '상품 1',
          itemElement: '원료 1',
          itemChangeDeleteDate: '2025-01-03',
          rows: [
            StatusPrintDetailRow(
              columnName: '원산지',
              changeDeleteDate: '2025-01-03',
              value: '국내산',
            ),
          ],
        );
      },
    );

    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();

    final renderedTable = tester.widget<FortuneTable<StatusPrintTableRow>>(
      find.byType(FortuneTable<StatusPrintTableRow>),
    );
    final renderedElementColumn = renderedTable.columns.singleWhere(
      (column) => column.id == 'searchValue',
    );
    expect(renderedElementColumn.initialWidth, 420);
    expect(renderedElementColumn.autoFit, isFalse);
    expect(renderedElementColumn.fillRemaining, isTrue);
    final renderedLabelSizeColumn = renderedTable.columns.singleWhere(
      (column) => column.id == 'labelSize',
    );
    expect(renderedLabelSizeColumn.autoFit, isTrue);
    expect(renderedLabelSizeColumn.fillRemaining, isFalse);

    double renderedWidthBetween(String leftColumnId, String rightColumnId) {
      return tester
              .getCenter(
                find.byKey(
                  ValueKey('fortune_table_column_resize_$rightColumnId'),
                ),
              )
              .dx -
          tester
              .getCenter(
                find.byKey(
                  ValueKey('fortune_table_column_resize_$leftColumnId'),
                ),
              )
              .dx;
    }

    expect(
      renderedWidthBetween('item', 'searchValue'),
      greaterThanOrEqualTo(420),
    );
    expect(renderedWidthBetween('brand', 'labelSize'), lessThan(130));

    const total = StatusPrintTableRow.summary(
      kind: StatusPrintRowKind.total,
      label: '[총 발행 매수]',
      count: 4,
    );
    const deleted = StatusPrintTableRow.summary(
      kind: StatusPrintRowKind.deleted,
      label: '[삭제된 품목 매수]',
      count: 4,
    );
    expect(statusPrintRowColor(total), statusPrintTotalColor);
    expect(statusPrintRowColor(deleted), statusPrintDeletedColor);
    expect(
      statusPrintRowColor(StatusPrintTableRow.result(result(deleted: true))),
      statusPrintDeletedColor,
    );

    await tester.tap(find.text('[총 발행 매수]'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('[총 발행 매수]'));
    await tester.pumpAndSettle();
    expect(detailCount, 0);

    await tester.tap(find.text('상품 1'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('상품 1'));
    await tester.pumpAndSettle();

    expect(detailCount, 1);
    expect(find.text('발행 통계 상세'), findsOneWidget);
    expect(find.text('품명  상품 1'), findsOneWidget);
    expect(find.text('주원료  원료 1'), findsOneWidget);
    expect(find.text('국내산'), findsOneWidget);
  });
}