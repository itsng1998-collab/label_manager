import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/label_column_candidates.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/page_home/label_column_edit_dialog.dart';

const baseType = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
const barcodeColumnType = TColumnType(
  code: TColumnType.TYPE_BARCODE,
  name: '바코드',
  order: 2,
);

TColumn _column(int id, String keyword, {int order = 1}) {
  return TColumn(
    columnType: baseType,
    keyword: keyword,
    columnName: keyword,
    useMissingKeywordCheck: false,
    columnId: id,
    labelSizeId: 10,
    order: order,
    width: 0,
    height: 0,
    barcodeType: BarcodeType.Code128,
    useBarcodeCheckDigit: true,
    showBarcodeNum: true,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: false,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 10,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
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
    gs1ai: '01',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  List<TColumn>? columns,
  Future<void> Function(LabelColumnSaveCommand command)? onSave,
  Future<void> Function(CustomerColumnSaveCommand command)? saveCustomer,
  Future<List<CustomerColumnCandidate>> Function(int customerId)? loadCustomer,
  VoidCallback? onClose,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LabelColumnEditDialog(
          labelSizeId: 10,
          customerId: 7,
          initialColumns: columns ?? [_column(1, 'BASE_A')],
          canSave: () async => true,
          onSave: onSave ?? (_) async {},
          onClose: onClose ?? () {},
          loadFixedTypes: () async => const [
            FixedColumnType(id: 1, name: '공통'),
          ],
          loadFixedCandidates: (_) async => const [
            FixedColumnCandidate(
              id: 1,
              typeId: 1,
              columnType: baseType,
              keyword: 'FIXED_A',
              columnName: '고정 A',
            ),
            FixedColumnCandidate(
              id: 2,
              typeId: 1,
              columnType: barcodeColumnType,
              keyword: 'BARCODE_A',
              columnName: '바코드 A',
            ),
          ],
          loadCustomerCandidates: loadCustomer ??
              (_) async => const [
                    CustomerColumnCandidate(
                      id: 11,
                      customerId: 7,
                      columnType: baseType,
                      keyword: 'CUSTOM_A',
                      columnName: '사용자 A',
                    ),
                  ],
          saveCustomerColumns: saveCustomer ?? (_) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  setUp(() {
    TColumnType.datas = [baseType, barcodeColumnType];
  });

  tearDown(() {
    TColumnType.datas = null;
  });

  testWidgets('opens three-area layout and switches fixed/customer candidates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    expect(find.text('라벨 항목 편집'), findsOneWidget);
    expect(find.text('속성'), findsOneWidget);
    expect(find.text('사용 항목'), findsOneWidget);
    expect(find.text('고정 A'), findsOneWidget);

    await _tapVisible(tester, find.text('사용자 항목'));
    await tester.pumpAndSettle();
    expect(find.text('사용자 A'), findsOneWidget);
  });

  testWidgets('adds and removes candidates through shared commands', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('고정 A'));
    await _tapVisible(tester, find.byKey(const Key('label-column-add')));
    await tester.pump();
    final usedFixed = find.descendant(
      of: find.byKey(const Key('label-column-used-table')),
      matching: find.text('FIXED_A'),
    );
    expect(usedFixed, findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('label-column-remove')));
    await tester.pump();
    expect(usedFixed, findsNothing);
  });

  testWidgets('guards a pending special initial apply and cancel removes it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('바코드 A'));
    await _tapVisible(tester, find.byKey(const Key('label-column-add')));
    await tester.pump();
    await _tapVisible(tester, find.text('BASE_A').last);
    await tester.pump();

    expect(find.text('미적용 속성'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('label-column-property-apply')), findsOneWidget);

    tester
        .widget<TextButton>(
          find.byKey(const Key('label-column-property-cancel')),
        )
        .onPressed!();
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('label-column-used-table')),
        matching: find.text('BARCODE_A'),
      ),
      findsNothing,
    );
  });

  testWidgets('property cancel restores baseline and apply reaches save command', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LabelColumnSaveCommand? saved;
    await _pumpDialog(tester, onSave: (command) async => saved = command);

    await tester.enterText(find.byKey(const Key('label-column-name')), '취소할 이름');
    tester
        .widget<TextButton>(
          find.byKey(const Key('label-column-property-cancel')),
        )
        .onPressed!();
    await tester.pump();
    final nameEditor = find.descendant(
      of: find.byKey(const Key('label-column-name')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(nameEditor).controller.text, 'BASE_A');

    await tester.enterText(find.byKey(const Key('label-column-name')), '적용한 이름');
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('label-column-property-apply')),
        )
        .onPressed!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.updatedColumns.single.column.columnName, '적용한 이름');
  });

  testWidgets('reorder cancel restores and apply persists stable-key order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LabelColumnSaveCommand? saved;
    await _pumpDialog(
      tester,
      columns: [_column(1, 'A'), _column(2, 'B', order: 2)],
      onSave: (command) async => saved = command,
    );

    await _tapVisible(tester, find.byKey(const Key('label-column-reorder')));
    await _tapVisible(tester, find.byKey(const Key('label-column-move-down')));
    await _tapVisible(tester, find.byKey(const Key('label-column-reorder-cancel')));
    await tester.pump();
    final mainSave = tester.widget<FilledButton>(
      find.byKey(const Key('label-column-main-save')),
    );
    expect(mainSave.onPressed, isNull);

    await _tapVisible(tester, find.byKey(const Key('label-column-reorder')));
    await _tapVisible(tester, find.byKey(const Key('label-column-move-down')));
    await _tapVisible(tester, find.byKey(const Key('label-column-reorder-apply')));
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.orderedKeys, ['column:2', 'column:1']);
  });

  testWidgets('user edit excludes reorder and saves then reloads candidates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var loadCount = 0;
    CustomerColumnSaveCommand? saved;
    await _pumpDialog(
      tester,
      saveCustomer: (command) async => saved = command,
      loadCustomer: (_) async {
        loadCount += 1;
        return loadCount == 1
            ? const []
            : const [
                CustomerColumnCandidate(
                  id: 22,
                  customerId: 7,
                  columnType: baseType,
                  keyword: 'NEW1',
                  columnName: '새 항목',
                ),
              ];
      },
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-reorder'))).onPressed,
      isNull,
    );

    await _tapVisible(tester, find.byKey(const Key('label-column-user-add')));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('customer-keyword:customer-draft:1')), 'new1');
    await tester.enterText(find.byKey(const ValueKey('customer-name:customer-draft:1')), '새 항목');
    await tester.tap(find.byKey(const Key('label-column-user-save')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pumpAndSettle();

    expect(saved?.newColumns.single.keyword, 'NEW1');
    expect(loadCount, 2);
    expect(find.text('새 항목'), findsOneWidget);
    expect(find.byKey(const Key('label-column-user-editor')), findsNothing);
  });

  testWidgets('busy disables commands and 900x600 has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saveCompleter = Completer<void>();
    var closed = false;
    await _pumpDialog(
      tester,
      onSave: (_) => saveCompleter.future,
      onClose: () => closed = true,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(const Key('label-column-name')), '변경');
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('label-column-property-apply')),
        )
        .onPressed!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-reorder'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('label-column-main-cancel'))).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);

    saveCompleter.complete();
    await tester.pump();
    await tester.pump();
    expect(closed, isTrue);
  });
}
