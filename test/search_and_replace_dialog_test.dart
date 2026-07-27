import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/item_detail.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/search_and_replace_dialog.dart';

void main() {
  const brand = Brand(brandId: 10, customerId: 1, brandName: '브랜드 1');
  const labelSize = LabelSize(
    labelSizeId: 100,
    brandId: 10,
    labelSizeName: '라벨 1',
  );
  const result = ItemDetail(
    itemId: 1000,
    labelSizeId: 100,
    itemName: '품목 1',
    labelSizeName: '라벨 1',
    element: '주원료 1',
    elementSheet: '',
    brandId: 10,
    brandName: '브랜드 1',
  );

  Future<SearchAndReplaceController> pumpContent(
    WidgetTester tester, {
    required bool editable,
    String initialSearchText = '',
    ItemDetailSearcher? search,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = SearchAndReplaceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchAndReplaceDialogContent(
            controller: controller,
            customerId: 1,
            editable: editable,
            initialSearchText: initialSearchText,
            loadBrands: (_) async => const [brand],
            loadLabelSizes: (_) async => const [labelSize],
            search:
                search ??
                ({
                  required customerId,
                  required type,
                  required query,
                  brandId,
                  labelSizeId,
                }) async => const [result],
            save: (_) async {},
            onMoveToEdit: (_) async {},
            onMoveToPrint: (_) async {},
            onSaved: () async {},
            onCommitOutcomeUnknown: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('initial query searches once after brand loading', (tester) async {
    var calls = 0;
    String? searched;
    await pumpContent(
      tester,
      editable: true,
      initialSearchText: '초기 품명',
      search:
          ({
            required customerId,
            required type,
            required query,
            brandId,
            labelSizeId,
          }) async {
            calls += 1;
            searched = query;
            return const [result];
          },
    );

    expect(calls, 1);
    expect(searched, '초기 품명');
    expect(find.text('품목 1'), findsOneWidget);
  });

  testWidgets('brand filter enables label size filter in order', (tester) async {
    await pumpContent(tester, editable: true);

    var brandSelector = tester.widget<DropdownButtonFormField<int>>(
      find.byKey(const ValueKey('searchReplaceBrand')),
    );
    var labelCheckbox = tester.widget<Checkbox>(
      find.byKey(const ValueKey('searchReplaceUseLabelSize')),
    );
    expect(brandSelector.onChanged, isNull);
    expect(labelCheckbox.onChanged, isNull);

    await tester.tap(find.byKey(const ValueKey('searchReplaceUseBrand')));
    await tester.pump();
    brandSelector = tester.widget<DropdownButtonFormField<int>>(
      find.byKey(const ValueKey('searchReplaceBrand')),
    );
    labelCheckbox = tester.widget<Checkbox>(
      find.byKey(const ValueKey('searchReplaceUseLabelSize')),
    );
    expect(brandSelector.onChanged, isNotNull);
    expect(labelCheckbox.onChanged, isNotNull);

    await tester.tap(find.byKey(const ValueKey('searchReplaceBrand')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('브랜드 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('searchReplaceUseLabelSize')));
    await tester.pump();
    final labelSelector = tester.widget<DropdownButtonFormField<int>>(
      find.byKey(const ValueKey('searchReplaceLabelSize')),
    );
    expect(labelSelector.onChanged, isNotNull);
  });

  testWidgets('read only user keeps search and move commands only', (
    tester,
  ) async {
    await pumpContent(
      tester,
      editable: false,
      initialSearchText: '품목',
    );

    expect(find.byKey(const ValueKey('searchReplaceBatchButton')), findsNothing);
    expect(find.byKey(const ValueKey('searchReplaceSaveButton')), findsNothing);
    expect(
      find.byKey(const ValueKey('searchReplaceMoveEditButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('searchReplaceMovePrintButton')),
      findsOneWidget,
    );
  });
}