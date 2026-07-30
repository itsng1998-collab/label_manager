import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/application/item_manager_xlsx.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/presentation/item_manager_import_transform_dialog.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';

void main() {
  testWidgets('configures column arithmetic before Excel import is applied', (
    tester,
  ) async {
    ItemManagerImportTransforms? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showItemManagerImportTransformDialog(
                  context,
                  result: _result(),
                  columns: _columns,
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('Excel 가져오기 연산 설정'), findsOneWidget);
    expect(find.text('이미지'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('item-import-operation:column:7')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('× 곱하기').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:column:7')),
      '5',
    );
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pumpAndSettle();

    expect(selected?.columns[7]?.operation, ItemManagerImportTransformOperation.multiply);
    expect(selected?.columns[7]?.value, '5');
  });

  testWidgets('configures Mid text insertion with a left position', (
    tester,
  ) async {
    ItemManagerImportTransforms? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showItemManagerImportTransformDialog(
                  context,
                  result: _result(),
                  columns: _columns,
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-import-operation:item')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mid (왼쪽 N자 이후 대체)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:item')),
      '초등학교',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-import-position:item')),
      '1',
    );
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pumpAndSettle();

    expect(selected?.itemName?.apply('서울'), '서초등학교');
  });

  testWidgets('shows the first non-empty imported value as the sample', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showItemManagerImportTransformDialog(
                context,
                result: _resultWithLeadingEmptyValues(),
                columns: _columns,
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('둘째 품목'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget);
  });

  testWidgets('configures division decimal places', (tester) async {
    ItemManagerImportTransforms? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showItemManagerImportTransformDialog(
                  context,
                  result: _result(),
                  columns: _columns,
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('item-import-operation:column:7')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('÷ 나누기').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:column:7')),
      '5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('item-import-decimals:column:7')),
      '3',
    );
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pumpAndSettle();

    expect(selected?.columns[7]?.decimalPlaces, 3);
    expect(selected?.columns[7]?.apply('3'), '0.6');
  });
}

const _columns = [
  ItemManagerXlsxColumn(
    columnId: 7,
    name: '가격',
    editable: true,
    typeCode: TColumnType.TYPE_BASE,
  ),
  ItemManagerXlsxColumn(
    columnId: 8,
    name: '이미지',
    editable: true,
    typeCode: TColumnType.TYPE_IMAGE,
  ),
];

ItemManagerXlsxImportResult _result() => ItemManagerXlsxImportResult(
  rows: [
    ItemManagerImportedRow(
      itemName: '서울',
      elementPlain: '',
      elementPayload: 'UEsDempty',
      columnDrafts: const {
        7: ItemManagerColumnDraft(editable: true, dataString: '3'),
        8: ItemManagerColumnDraft(editable: true, dataString: '상품'),
      },
    ),
  ],
);

ItemManagerXlsxImportResult _resultWithLeadingEmptyValues() =>
    ItemManagerXlsxImportResult(
      rows: [
        ItemManagerImportedRow(
          itemName: '',
          elementPlain: '첫 행을 유지하는 다른 값',
          elementPayload: 'UEsDempty',
          columnDrafts: const {
            7: ItemManagerColumnDraft(editable: true, dataString: ''),
          },
        ),
        ItemManagerImportedRow(
          itemName: '둘째 품목',
          elementPlain: '',
          elementPayload: 'UEsDempty',
          columnDrafts: const {
            7: ItemManagerColumnDraft(editable: true, dataString: '2500'),
          },
        ),
      ],
    );