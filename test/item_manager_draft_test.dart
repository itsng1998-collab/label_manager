import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/gs1_ai.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';

void main() {
  group('[item manager draft]', () {
    test('builds existing rows without mutating display models', () {
      final first = _itemOfMarket(itemId: 10, order: 1, name: '첫 품목');
      final second = _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목');
      final scoped = TColumnContentScopedView({
        const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
          colContentId: 1,
          columnId: 7,
          itemId: 10,
          editable: true,
          dataString: '00123',
        ),
      });

      final controller = ItemManagerDraftController.fromItems(
        items: [first, second],
        rawSnapshots: {10: _snapshot(10), 20: _snapshot(20)},
        scopedColumnContents: scoped,
      );

      expect(controller.rows, hasLength(2));
      expect(controller.rows.first.rowKey, 'item:10');
      expect(controller.rows.first.source, same(first));
      expect(controller.columnValue(controller.rows.first, 7), '00123');
      expect(controller.columnValue(controller.rows.last, 7), '');
      expect(controller.isDirty, isFalse);
    });

    test('classifies encoded workbook and legacy RTF payloads', () {
      final workbook = _itemOfMarket(itemId: 10, order: 1, name: 'workbook');
      final legacy = _itemOfMarket(
        itemId: 20,
        order: 2,
        name: 'legacy',
        elementPayload: r'{\rtf1 legacy}',
      );
      final controller = _controller([workbook, legacy]);

      expect(
        controller.rows.first.elementPayloadFormat,
        ItemManagerElementPayloadFormat.workbook,
      );
      expect(
        controller.rows.last.elementPayloadFormat,
        ItemManagerElementPayloadFormat.legacyRtf,
      );
    });

    test('adds independent rows and selects the first new row as anchor', () {
      final source = _itemOfMarket(itemId: 10, order: 1, name: '기존');
      final controller = _controller([source]);

      final added = controller.addRows(2, emptyElementPayload: '{}');

      expect(controller.rows, hasLength(3));
      expect(added.map((row) => row.rowKey).toSet(), hasLength(2));
      expect(added.every((row) => row.source == null), isTrue);
      expect(added.every((row) => row.itemPrice == 0), isTrue);
      expect(added.every((row) => row.newMappingDefaults != null), isTrue);
      expect(controller.anchorRowKey, added.first.rowKey);
      expect(
        controller.selectedRowKeys,
        added.map((row) => row.rowKey).toSet(),
      );
      expect(controller.isDirty, isTrue);
      expect(source.item.itemName, '기존');
    });

    test('inserts below anchor and marks shifted existing order modified', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);

      final inserted = controller.insertRowsAfter(
        'item:10',
        1,
        emptyElementPayload: '{}',
      );

      expect(controller.rows.map((row) => row.rowKey), [
        'item:10',
        inserted.single.rowKey,
        'item:20',
      ]);
      expect(controller.rows.map((row) => row.order), [1, 2, 3]);
      expect(inserted.single.insertAnchorItemId, 10);
      expect(controller.rows.last.rowState, ItemManagerDraftRowState.modified);
    });

    test('deletes only existing identities and selects following row', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
        _itemOfMarket(itemId: 30, order: 3, name: '셋째 품목'),
      ]);
      final added = controller.insertRowsAfter(
        'item:10',
        1,
        emptyElementPayload: '{}',
      );

      final nextKey = controller.deleteRows([added.single.rowKey, 'item:20']);

      expect(controller.deletedSourceItemIds, {20});
      expect(controller.rows.map((row) => row.rowKey), ['item:10', 'item:30']);
      expect(nextKey, 'item:30');
      expect(controller.selectedRowKeys, {'item:30'});
    });

    test(
      'replaces clean rows with imported drafts and deletes all sources',
      () {
        final controller = _controller([
          _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
          _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
        ]);

        final imported = controller.replaceAllWithImportedRows(const [
          ItemManagerImportedRow(
            itemName: '가져온 첫 품목',
            elementPlain: '딸기',
            elementPayload: 'UEsDfirst',
            columnDrafts: {
              7: ItemManagerColumnDraft(editable: true, dataString: '00123'),
            },
          ),
          ItemManagerImportedRow(
            itemName: '가져온 둘째 품목',
            elementPlain: '',
            elementPayload: 'UEsDempty',
          ),
        ]);

        expect(controller.deletedSourceItemIds, {10, 20});
        expect(controller.deletedRowsBySourceItemId.keys, {10, 20});
        expect(imported.map((row) => row.rowState), [
          ItemManagerDraftRowState.imported,
          ItemManagerDraftRowState.imported,
        ]);
        expect(imported.map((row) => row.order), [1, 2]);
        expect(imported.first.sourceItemId, isNull);
        expect(imported.first.itemName, '가져온 첫 품목');
        expect(imported.first.elementPlain, '딸기');
        expect(imported.first.columnDrafts[7]?.dataString, '00123');
        expect(controller.selectedRowKeys, {imported.first.rowKey});
        expect(controller.anchorRowKey, imported.first.rowKey);
        expect(controller.isDirty, isTrue);
      },
    );

    test('reverting existing edits clears modified state', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '원본 품명'),
      ]);

      controller.updateItemName('item:10', '수정 품명');
      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '수정값',
      );
      expect(
        controller.rows.single.rowState,
        ItemManagerDraftRowState.modified,
      );

      controller.updateItemName('item:10', '원본 품명');
      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '',
      );

      expect(
        controller.rows.single.rowState,
        ItemManagerDraftRowState.existing,
      );
      expect(controller.rows.single.columnDrafts, isEmpty);
      expect(controller.isDirty, isFalse);
    });

    test('builds save identities for modified and new rows', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '기존'),
      ]);
      controller.updateElement(
        'item:10',
        elementPlain: '원재료',
        elementPayload: '{"sheet":1}',
      );
      final added = controller.addRows(1, emptyElementPayload: '{}').single;
      controller.updateItemName(added.rowKey, '신규');
      controller.updateColumnValue(
        added.rowKey,
        columnId: 7,
        editable: true,
        dataString: '00123',
      );

      final command = controller.toSaveCommand(
        labelSizeId: 4,
        targetMarketIds: const [3, 5],
      );

      expect(command.existingRows.single.sourceItemId, 10);
      expect(command.existingRows.single.elementPlain, '원재료');
      expect(command.newRows.single.draftRowKey, added.draftRowKey);
      expect(command.newRows.single.itemName, '신규');
      expect(command.columnValues.single.sourceItemId, isNull);
      expect(command.columnValues.single.draftRowKey, added.draftRowKey);
      expect(command.targetMarketIds, [3, 5]);
      expect(() => command.toSqlParams(), returnsNormally);
    });

    test('rejects save while a working row has an empty item name', () {
      final controller = ItemManagerDraftController(
        rows: [
          ItemManagerDraftRow.newRow(
            draftRowKey: 'draft-1',
            order: 1,
            originalIndex: 0,
            insertAnchorItemId: null,
            rowState: ItemManagerDraftRowState.added,
            emptyElementPayload: 'UEsDempty',
          ),
        ],
        scopedColumnContents: TColumnContentScopedView(const {}),
      );

      expect(
        () => controller.toSaveCommand(
          labelSizeId: 4,
          targetMarketIds: const [3],
        ),
        throwsStateError,
      );
    });

    test('rejects missing required and unsupported image column values', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '필수 컬럼',
            typeCode: TColumnType.TYPE_BASE,
            required: true,
          ),
          ItemManagerColumnValidationRule(
            columnId: 8,
            columnName: '이미지',
            typeCode: TColumnType.TYPE_IMAGE,
            required: false,
          ),
        ],
      );

      expect(
        controller.validateForSave,
        throwsA(
          isA<ItemManagerDraftValidationError>()
              .having((error) => error.rowKey, 'rowKey', 'item:10')
              .having((error) => error.columnId, 'columnId', 7)
              .having(
                (error) => error.message,
                'message',
                contains('1행 필수 컬럼'),
              ),
        ),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '값',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: 'logo.png',
      );
      expect(
        controller.validateForSave,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('BMP 파일만'),
          ),
        ),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: 'logo',
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test('rejects an empty element when the special column is required', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        requireElement: true,
      );

      expect(
        controller.validateForSave,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('1행의 주원료'),
          ),
        ),
      );

      controller.updateElement(
        'item:10',
        elementPlain: '원재료',
        elementPayload: 'UEsDelement',
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test('normalizes EAN check digits and rejects odd ITF values', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: 'EAN-8',
            typeCode: TColumnType.TYPE_BARCODE,
            required: false,
            barcodeType: BarcodeType.CodeEAN8,
            useBarcodeCheckDigit: true,
          ),
          ItemManagerColumnValidationRule(
            columnId: 8,
            columnName: 'ITF',
            typeCode: TColumnType.TYPE_BARCODE,
            required: false,
            barcodeType: BarcodeType.Itf,
          ),
        ],
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '1234567',
      );
      expect(
        controller.columnValue(controller.rows.single, 7),
        BarcodeDataHelper.ean8('1234567'),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '123',
      );
      expect(
        controller.validateForSave,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('ITF 바코드 형식'),
          ),
        ),
      );
    });

    test('validates legacy date and time column formats', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '제조일자',
            typeCode: TColumnType.TYPE_MAKEDATE,
            required: false,
          ),
          ItemManagerColumnValidationRule(
            columnId: 8,
            columnName: '소비기한',
            typeCode: TColumnType.TYPE_VALIDDATE,
            required: false,
            useDateRange: true,
            dateRange: '3|5',
          ),
          ItemManagerColumnValidationRule(
            columnId: 9,
            columnName: '제조시한',
            typeCode: TColumnType.TYPE_MAKETIME,
            required: false,
          ),
        ],
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '20260230',
      );
      expect(controller.validateForSave, throwsStateError);

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '20260228',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '6',
      );
      expect(controller.validateForSave, throwsStateError);

      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '-3',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 9,
        editable: true,
        dataString: '2360',
      );
      expect(controller.validateForSave, throwsStateError);

      controller.updateColumnValue(
        'item:10',
        columnId: 9,
        editable: true,
        dataString: '2359',
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test('rejects invalid GS1 AI edits without changing the draft', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');

      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: 'GTIN',
            typeCode: TColumnType.TYPE_GS1_AI,
            required: false,
            gs1Definition: Gs1AiDefinition(
              code: '01',
              name: 'GTIN',
              content: '',
              dataFormat: '01+N14',
              dataFormatType: 0,
              needsFnc1: false,
            ),
          ),
        ],
      );

      expect(
        controller.updateColumnValue(
          'item:10',
          columnId: 7,
          editable: true,
          dataString: '1234',
        ),
        isFalse,
      );
      expect(controller.columnValue(controller.rows.single, 7), isEmpty);
      expect(controller.isDirty, isFalse);

      expect(
        controller.updateColumnValue(
          'item:10',
          columnId: 7,
          editable: true,
          dataString: '12345678901234',
        ),
        isTrue,
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test('calculates and validates 10*8 quantity columns', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      const rules = [
        ItemManagerColumnValidationRule(
          columnId: 7,
          columnName: '현재수량',
          typeCode: TColumnType.TYPE_BASE,
          required: false,
        ),
        ItemManagerColumnValidationRule(
          columnId: 8,
          columnName: '총 수량',
          typeCode: TColumnType.TYPE_BASE,
          required: false,
        ),
        ItemManagerColumnValidationRule(
          columnId: 9,
          columnName: '매수',
          typeCode: TColumnType.TYPE_BASE,
          required: false,
        ),
        ItemManagerColumnValidationRule(
          columnId: 10,
          columnName: '발행수량',
          typeCode: TColumnType.TYPE_BASE,
          required: false,
        ),
      ];
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: rules,
        labelSizeName: '10*8',
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '20',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '100',
      );
      expect(controller.columnValue(controller.rows.single, 9), '5');
      expect(controller.columnValue(controller.rows.single, 10), '1/5');
      expect(controller.validateForSave, returnsNormally);

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '0',
      );
      expect(controller.validateForSave, throwsStateError);

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: 'not-a-number',
      );
      expect(controller.validateForSave, throwsStateError);
    });

    test('recalculates legacy time barcode suffixes as dirty values', () {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket(itemId: 10, order: 1, name: '품목')],
        rawSnapshots: {10: _snapshot(10)},
        scopedColumnContents: TColumnContentScopedView({
          const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
            colContentId: 1,
            columnId: 7,
            itemId: 10,
            editable: true,
            dataString: '88001234',
          ),
        }),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '바코드',
            typeCode: TColumnType.TYPE_BARCODE,
            required: false,
            timeBarcodeType: 2,
          ),
          ItemManagerColumnValidationRule(
            columnId: 8,
            columnName: '유통기한',
            typeCode: TColumnType.TYPE_VALIDDATE,
            required: false,
          ),
          ItemManagerColumnValidationRule(
            columnId: 9,
            columnName: '유통시한',
            typeCode: TColumnType.TYPE_VALIDTIME,
            required: false,
          ),
        ],
        now: () => DateTime(2026, 1, 1, 12),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '2',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 9,
        editable: true,
        dataString: '1530',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '88001234',
      );
      expect(
        controller.columnValue(controller.rows.single, 7),
        '8800123421503',
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '3',
      );
      expect(
        controller.columnValue(controller.rows.single, 7),
        '8800123421504',
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test('rejects additions above the shared row limit', () {
      final rows = List.generate(
        ItemManagerLimits.maxRows,
        (index) => ItemManagerDraftRow.newRow(
          draftRowKey: 'row-$index',
          order: index + 1,
          originalIndex: index,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.added,
          emptyElementPayload: '',
        ),
      );
      final controller = ItemManagerDraftController(
        rows: rows,
        scopedColumnContents: TColumnContentScopedView(const {}),
      );

      expect(
        () => controller.addRows(1, emptyElementPayload: ''),
        throwsStateError,
      );
    });
  });
}

ItemManagerDraftController _controller(List<ItemOfMarket> items) {
  return ItemManagerDraftController.fromItems(
    items: items,
    rawSnapshots: {
      for (final item in items) item.item.itemId: _snapshot(item.item.itemId),
    },
    scopedColumnContents: TColumnContentScopedView(const {}),
  );
}

ItemOfMarket _itemOfMarket({
  required int itemId,
  required int order,
  required String name,
  String elementPayload = 'UEsDencoded',
}) {
  final date = DateTime(2026, 1, 1);
  return ItemOfMarket(
    marketId: 3,
    item: Item(
      itemId: itemId,
      labelSizeId: 4,
      itemName: name,
      labelSizeName: '60x40',
      element: '',
      elementRTF: elementPayload,
      price: 0,
      order: order,
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: 0,
      itemId: itemId,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: date,
    dateSaleEnd: date,
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: date,
    dateEndDiscount: date,
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 100,
    useScaleBarcode: false,
    printCount: 1,
    useLabelSize: false,
    labelSizeWidth: 0,
    labelSizeHeight: 0,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );
}

ItemOfMarketRawSnapshot _snapshot(int itemId) {
  return ItemOfMarketRawSnapshot(
    marketId: 3,
    itemId: itemId,
    additionalItemId: null,
    gdsNo: null,
    dateSaleStart: null,
    dateSaleEnd: null,
    discountPercent: null,
    discountAmount: null,
    dateStartDiscount: null,
    dateEndDiscount: null,
    useDefineElement: null,
    rtfText: null,
    useLinefeed: null,
    linefeed: null,
    useScaleBarcode: null,
    printCount: null,
    useLabelSize: null,
    labelSizeWidth: null,
    labelSizeHeight: null,
    useMargin: null,
    leftMargin: null,
    rightMargin: null,
    topMargin: null,
    leftPush: null,
    topPush: null,
  );
}
