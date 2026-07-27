import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/status_print.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/status_print_dialog.dart';
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

  TColumn column(int labelSizeId, String name) => TColumn(
    columnType: const TColumnType(code: 0, name: '기본', order: 0),
    keyword: '',
    columnName: name,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    columnId: 1,
    labelSizeId: labelSizeId,
    order: 0,
    width: 0,
    height: 0,
    barcodeType: BarcodeType.Code128,
    useBarcodeCheckDigit: false,
    showBarcodeNum: false,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: true,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 0,
    qrTextFontName: '',
    qrCodeScalePercent: 0,
    timeBarcodeType: 0,
    autoInc: false,
    autoIncSize: 0,
    autoIncSave: false,
    autoIncRange: 0,
    autoIncZeroDel: false,
    autoIncUpdate: false,
    searchPrint: false,
    userDefineBarcodeText: '',
    lineCheck: 0,
    lineSize: 0,
    gs1ai: '',
    formatOption: 0,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
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
            loadColumns: (labelSizeId) async => [
              column(labelSizeId, '원산지'),
              column(labelSizeId, '원산지'),
              column(labelSizeId, labelSizeId == 1000 ? '가격' : '중량'),
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
      StatusPrintQuerySpec? received;
      await pumpContent(
        tester,
        grade: UserGrade.SYSTEM_ADMIN_USER,
        query: (spec) async {
          queryCount += 1;
          received = spec;
          return const [];
        },
      );

      expect(find.text('협력업체'), findsOneWidget);
      expect(find.text('거래처'), findsOneWidget);
      expect(find.text('[전체 보기]'), findsNWidgets(2));
      expect(find.text(statusPrintElementColumn), findsWidgets);
      expect(queryCount, 0);

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