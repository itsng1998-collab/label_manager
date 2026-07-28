import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/admin_copy.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/admin_copy_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  const cooperator = Cooperator(id: 'C1', name: '협력업체');
  const customers = [
    Customer(customerId: 1, cooperatorId: 'C1', customerName: '원본 거래처'),
    Customer(customerId: 2, cooperatorId: 'C1', customerName: '대상 거래처'),
  ];

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Future<void> Function(AdminBrandCopyCommand) copyBrand,
    Future<bool> Function(int)? targetHasColumns,
    Future<void> Function(AdminLabelSizeCopyCommand)? copyLabelSize,
    VoidCallback? onClose,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 820,
            height: 412,
            child: AdminCopyDialogContent(
              controller: AdminCopyController(),
              initialCooperator: cooperator,
              cooperatorSelectionEnabled: true,
              onCommitted: () async {},
              onCommitOutcomeUnknown: () {},
              onClose: onClose ?? () {},
              loadCooperators: () async => const [cooperator],
              loadCustomers: (_) async => customers,
              loadBrands: (customerId) async => [
                Brand(
                  brandId: customerId * 10,
                  customerId: customerId,
                  brandName: '브랜드 $customerId',
                ),
              ],
              loadLabelSizes: (brandId) async => [
                LabelSize(
                  labelSizeId: brandId * 10,
                  brandId: brandId,
                  labelSizeName: '크기 $brandId',
                ),
              ],
              loadMarkets: (_) async => const [],
              targetHasColumns: targetHasColumns ?? (_) async => false,
              copyLabelSize: copyLabelSize ?? (_) async {},
              copyBrand: copyBrand,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('brand checkbox waits for source brand selection event', (
    tester,
  ) async {
    await pumpDialog(tester, copyBrand: (_) async {});
    await tester.tap(find.byKey(const ValueKey('adminCopyWholeBrand')));
    await tester.pump();
    final targetBefore = tester.widget<ModelessDropdownFormField<int>>(
      find.byKey(const ValueKey('adminCopyTargetCustomer')),
    );
    expect(targetBefore.onChanged, isNull);

    await tester.tap(find.byKey(const ValueKey('adminCopySourceCustomer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('원본 거래처').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopySourceBrand')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('브랜드 1').last);
    await tester.pumpAndSettle();

    final targetAfter = tester.widget<ModelessDropdownFormField<int>>(
      find.byKey(const ValueKey('adminCopyTargetCustomer')),
    );
    expect(targetAfter.onChanged, isNotNull);
  });

  testWidgets('uses compact comparison layout with leading checkboxes', (
    tester,
  ) async {
    await pumpDialog(tester, copyBrand: (_) async {});

    final sourceCustomer = tester.getRect(
      find.byKey(const ValueKey('adminCopySourceCustomer')),
    );
    final targetCustomer = tester.getRect(
      find.byKey(const ValueKey('adminCopyTargetCustomer')),
    );
    expect(sourceCustomer.top, moreOrLessEquals(targetCustomer.top));
    expect(sourceCustomer.right, lessThan(targetCustomer.left));

    final brandCheckbox = tester.getRect(
      find.byKey(const ValueKey('adminCopyWholeBrand')),
    );
    final brandLabel = tester.getRect(find.text('브랜드 복사'));
    expect(brandCheckbox.right, lessThanOrEqualTo(brandLabel.left));
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('adminCopyExecute'))).dy,
      lessThanOrEqualTo(396),
    );
  });

  testWidgets('shows legacy hint and closes from the footer', (tester) async {
    var closeCount = 0;
    await pumpDialog(
      tester,
      copyBrand: (_) async {},
      onClose: () => closeCount += 1,
    );

    expect(
      find.text('※ 복사할 내용이 있는 라벨크기를 선택해주세요!!'),
      findsOneWidget,
    );
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
    expect(
      tester.getCenter(find.byKey(const ValueKey('adminCopyClose'))).dx,
      lessThan(
        tester.getCenter(find.byKey(const ValueKey('adminCopyExecute'))).dx,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('adminCopyClose')));
    await tester.pump();
    expect(closeCount, 1);
  });

  testWidgets('brand copy is enabled by target customer event', (
    tester,
  ) async {
    AdminBrandCopyCommand? copied;
    await pumpDialog(tester, copyBrand: (value) async => copied = value);
    await tester.tap(find.byKey(const ValueKey('adminCopyWholeBrand')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adminCopySourceCustomer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('원본 거래처').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopySourceBrand')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('브랜드 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopyTargetCustomer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대상 거래처').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopyExecute')));
    await tester.pumpAndSettle();

    expect(copied?.sourceBrandId, 10);
    expect(copied?.targetCustomerId, 2);
  });

  testWidgets('item copy without target market performs no DML', (
    tester,
  ) async {
    var copyCount = 0;
    await pumpDialog(
      tester,
      copyBrand: (_) async => copyCount += 1,
    );
    await tester.tap(find.byKey(const ValueKey('adminCopyWholeBrand')));
    await tester.tap(find.byKey(const ValueKey('adminCopyItems')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('adminCopySourceCustomer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('원본 거래처').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopySourceBrand')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('브랜드 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopyTargetCustomer')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('대상 거래처').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adminCopyExecute')));
    await tester.pumpAndSettle();

    expect(copyCount, 0);
    expect(find.textContaining('지점이 없습니다'), findsOneWidget);
  });
}