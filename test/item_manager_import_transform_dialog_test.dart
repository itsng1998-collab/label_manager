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
    ItemManagerImportTransformSelection? selected;
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

    expect(
      selected?.transforms.columns[7]?.operation,
      ItemManagerImportTransformOperation.multiply,
    );
    expect(selected?.transforms.columns[7]?.value, '5');
    expect(selected?.result.rows.single.columnDrafts[7]?.dataString, '15');
  });

  testWidgets('configures Mid text insertion with a left position', (
    tester,
  ) async {
    ItemManagerImportTransformSelection? selected;
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

    expect(selected?.transforms.itemName?.apply('서울'), '서초등학교');
    expect(selected?.result.rows.single.itemName, '서초등학교');
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
    ItemManagerImportTransformSelection? selected;
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

    expect(selected?.transforms.columns[7]?.decimalPlaces, 3);
    expect(selected?.transforms.columns[7]?.apply('3'), '0.6');
    expect(selected?.result.rows.single.columnDrafts[7]?.dataString, '0.6');
  });

  testWidgets('rejects ambiguous comma grouping in numeric settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showItemManagerImportTransformDialog(
                context,
                result: _result(),
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
    await tester.tap(
      find.byKey(const ValueKey('item-import-operation:column:7')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('× 곱하기').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:column:7')),
      '1,2,3',
    );
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pump();

    expect(find.text('천 단위 쉼표와 소수점(.)을 확인하세요.'), findsOneWidget);
    expect(find.text('Excel 가져오기 연산 설정'), findsOneWidget);
  });

  testWidgets('keeps the dialog open when a later Excel row cannot transform', (
    tester,
  ) async {
    ItemManagerImportTransformSelection? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showItemManagerImportTransformDialog(
                  context,
                  result: _resultWithInvalidLaterNumber(),
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
    await tester.tap(find.text('× 곱하기').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:column:7')),
      '5',
    );
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pump();

    expect(selected, isNull);
    expect(find.text('Excel 가져오기 연산 설정'), findsOneWidget);
    expect(
      find.textContaining('Excel 3행 가격 연산 실패'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the setting value when the operation changes', (
    tester,
  ) async {
    ItemManagerImportTransformSelection? selected;
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
    await tester.tap(find.text('× 곱하기').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item-import-value:column:7')),
      '5',
    );
    await tester.tap(
      find.byKey(const ValueKey('item-import-operation:column:7')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('÷ 나누기').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pumpAndSettle();

    expect(
      selected?.transforms.columns[7]?.operation,
      ItemManagerImportTransformOperation.divide,
    );
    expect(selected?.transforms.columns[7]?.value, '5');
  });

  testWidgets('validates an invalid setting after its row scrolls offscreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showItemManagerImportTransformDialog(
                context,
                result: _resultWithManyColumns(),
                columns: _manyColumns,
              ),
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
    await tester.tap(find.text('Right (뒤에 추가)').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-import-value:item')), findsNothing);

    await tester.tap(find.byKey(const Key('item-import-transform-apply')));
    await tester.pump();

    expect(find.text('품목: 설정값을 입력하세요.'), findsOneWidget);
    expect(find.text('Excel 가져오기 연산 설정'), findsOneWidget);
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

final _manyColumns = [
  for (var id = 1; id <= 12; id++)
    ItemManagerXlsxColumn(
      columnId: id,
      name: '컬럼$id',
      editable: true,
      typeCode: TColumnType.TYPE_BASE,
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

ItemManagerXlsxImportResult _resultWithInvalidLaterNumber() =>
    ItemManagerXlsxImportResult(
      rows: [
        ItemManagerImportedRow(
          itemName: '첫 품목',
          elementPlain: '',
          elementPayload: 'UEsDempty',
          excelRowNumber: 2,
          columnDrafts: const {
            7: ItemManagerColumnDraft(editable: true, dataString: '3'),
          },
        ),
        ItemManagerImportedRow(
          itemName: '둘째 품목',
          elementPlain: '',
          elementPayload: 'UEsDempty',
          excelRowNumber: 3,
          columnDrafts: const {
            7: ItemManagerColumnDraft(editable: true, dataString: '서울'),
          },
        ),
      ],
    );

ItemManagerXlsxImportResult _resultWithManyColumns() =>
    ItemManagerXlsxImportResult(
      rows: [
        ItemManagerImportedRow(
          itemName: '품목값',
          elementPlain: '',
          elementPayload: 'UEsDempty',
          columnDrafts: {
            for (var id = 1; id <= 12; id++)
              id: ItemManagerColumnDraft(
                editable: true,
                dataString: '$id',
              ),
          },
        ),
      ],
    );
