import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
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
