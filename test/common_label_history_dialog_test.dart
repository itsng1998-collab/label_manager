import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:label_manager/models/common_label_history.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/common_label_history_dialog.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/horizontal_pane_splitter.dart';
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
    cooperatorId: 'coop2',
    customerName: '거래처 2',
  );
  const row = CommonLabelHistory(
    logId: 7,
    modifiedAt: '2025-01-02 03:04:05',
    userId: 'user01',
    brandName: '브랜드 1',
    labelSizeName: '라벨 1',
    beforeWidth: 60,
    beforeHeight: 40,
    beforeFormData: 'before',
    beforeFormSheet: '',
    afterWidth: 70,
    afterHeight: 50,
    afterFormData: 'after',
    afterFormSheet: '',
    innerIp: '192.168.0.2',
    outerIp: '127.0.0.1',
  );

  test('history preview hides grid lines without changing source workbook', () {
    final source = fs.FortuneWorkbook(
      sheets: [
        fs.FortuneSheet(id: 'sheet1', name: 'Sheet 1', showGridLines: true),
      ],
    );

    final preview = commonLabelHistoryPreviewWorkbook(source)!;

    expect(source.activeSheet.showGridLines, isTrue);
    expect(preview.activeSheet.showGridLines, isFalse);
  });

  testWidgets('system admin cascades customer and loads both previews', (
    tester,
  ) async {
    final loadedCooperatorIds = <String>[];
    var queryCount = 0;
    var previewCount = 0;
    int? queriedCustomerId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1300,
            height: 780,
            child: CommonLabelHistoryDialogContent(
              userGrade: UserGrade.SYSTEM_ADMIN_USER,
              initialCooperator: initialCooperator,
              initialCustomer: initialCustomer,
              loadCooperators: () async => const [
                initialCooperator,
                otherCooperator,
              ],
              loadCustomers: (cooperatorId) async {
                loadedCooperatorIds.add(cooperatorId);
                return cooperatorId == otherCooperator.id
                    ? const [otherCustomer]
                    : const [initialCustomer];
              },
              query:
                  ({
                    required startDate,
                    required endDate,
                    required customerId,
                  }) async {
                    queryCount += 1;
                    queriedCustomerId = customerId;
                    return const [row];
                  },
              loadPreview: (payload, {required width, required height}) async {
                previewCount += 1;
                return null;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tablePane = find.byKey(
      const ValueKey('common-label-history-table-pane'),
    );
    expect(tester.getSize(tablePane).height, 220);
    final splitter = find.byKey(
      const ValueKey('common-label-history-splitter'),
    );
    final initialSplitterCenter = tester.getCenter(splitter);
    final gesture = await tester.startGesture(initialSplitterCenter);
    for (var step = 1; step <= 4; step += 1) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
      expect(tester.getSize(tablePane).height, 220 + step * 10);
      expect(tester.getCenter(splitter).dy, initialSplitterCenter.dy + step * 10);
    }
    await gesture.up();

    final beforePreview = find.byKey(
      const ValueKey('common-label-history-before-preview'),
    );
    final previewFrame = tester.widget<DecoratedBox>(
      find.descendant(of: beforePreview, matching: find.byType(DecoratedBox)).first,
    );
    final frameDecoration = previewFrame.decoration as BoxDecoration;
    expect(
      (frameDecoration.border as Border).top.color,
      commonLabelHistoryPreviewBorderColor,
    );
    for (final toolbar in find.byType(LabelSheetZoomToolbar).evaluate()) {
      final coloredBox = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byWidget(toolbar.widget),
          matching: find.byType(ColoredBox),
        ).first,
      );
      expect(coloredBox.color, blockingModelessDialogBackgroundColor);
    }

    expect(queryCount, 0);
    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsOneWidget);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsOneWidget);
    expect(loadedCooperatorIds, ['coop1']);

    await tester.tap(find.byType(ModelessDropdownFormField<Cooperator>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('협력업체 2').last);
    await tester.pumpAndSettle();
    expect(loadedCooperatorIds, ['coop1', 'coop2']);

    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();
    expect(queriedCustomerId, 20);
    expect(find.text('브랜드 1'), findsOneWidget);
    expect(find.text('검색결과가 없습니다!'), findsNothing);

    await tester.tap(find.text('브랜드 1'));
    await tester.pumpAndSettle();
    expect(previewCount, 2);
    expect(find.text('변경 전 미리보기를 표시할 수 없습니다.'), findsOneWidget);
    expect(find.text('변경 후 미리보기를 표시할 수 없습니다.'), findsOneWidget);
  });

  testWidgets('regular user hides selectors and empty result stays silent', (
    tester,
  ) async {
    var queryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1300,
            height: 780,
            child: CommonLabelHistoryDialogContent(
              userGrade: UserGrade.CLIENT_USER,
              initialCooperator: initialCooperator,
              initialCustomer: initialCustomer,
              query:
                  ({
                    required startDate,
                    required endDate,
                    required customerId,
                  }) async {
                    queryCount += 1;
                    expect(customerId, 10);
                    return const [];
                  },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ModelessDropdownFormField<Cooperator>), findsNothing);
    expect(find.byType(ModelessDropdownFormField<Customer>), findsNothing);
    expect(queryCount, 0);

    await tester.tap(find.text('조회'));
    await tester.pumpAndSettle();
    expect(queryCount, 1);
    expect(find.text('검색결과가 없습니다!'), findsNothing);
  });
}