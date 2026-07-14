import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_manager_draft_backup.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late ItemManagerDraftBackupStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('item_draft_backup_');
    store = ItemManagerDraftBackupStore(
      metadata: const ItemManagerDraftBackupMetadata(
        draftKey: 'user_1_2_4',
        userId: 'user',
        customerId: 1,
        brandId: 2,
        labelSizeId: 4,
        currentMarketId: 3,
      ),
      directoryProvider: () async => directory,
      databaseFactory: databaseFactoryFfi,
    );
    await store.start(selectedRowKeys: const {'item:10'}, anchorRowKey: 'item:10');
  });

  tearDown(() async {
    await store.close();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('delta backup keeps only the first original value per target', () async {
    final controller = _controller();
    final row = controller.rows.first;

    await store.captureItemName(row);
    controller.updateItemName(row.rowKey, '변경 이름');
    await store.captureItemName(controller.rows.first);
    await store.captureCells(
      row: row,
      columnIds: const {7},
      columnContents: controller.scopedColumnContents,
    );
    controller.updateColumnValue(
      row.rowKey,
      columnId: 7,
      editable: true,
      dataString: '변경 값',
    );
    await store.captureCells(
      row: controller.rows.first,
      columnIds: const {7},
      columnContents: controller.scopedColumnContents,
    );

    final snapshot = await store.readSnapshot();
    expect(snapshot.mode, ItemManagerDraftBackupMode.delta);
    expect(snapshot.itemNames, {10: '원본 이름'});
    expect(snapshot.cells[const ColumnItemKey(columnId: 7, itemId: 10)]?.dataString, '원본 값');
    expect(snapshot.elements, isEmpty);
    expect(snapshot.deletedRows, isEmpty);
  });

  test('deleted row backup includes the row and all scoped cells', () async {
    final controller = _controller();
    await store.captureDeletedRows(
      rows: controller.rows,
      columnContents: controller.scopedColumnContents,
    );

    final snapshot = await store.readSnapshot();
    expect(snapshot.deletedRows.keys, {10, 20});
    expect(snapshot.deletedRows[10]?.itemName, '원본 이름');
    expect(snapshot.deletedColumns.keys, {
      const ColumnItemKey(columnId: 7, itemId: 10),
      const ColumnItemKey(columnId: 7, itemId: 20),
    });
  });

  test('full import backup stores every existing row and scoped cell', () async {
    final controller = _controller();
    await store.captureFullImport(controller);

    final snapshot = await store.readSnapshot();
    expect(snapshot.mode, ItemManagerDraftBackupMode.fullImport);
    expect(snapshot.deletedRows.keys, {10, 20});
    expect(snapshot.deletedColumns, hasLength(2));
  });

  test('snapshot restores changed, deleted, and added rows without DB reload', () async {
    final controller = _controller();
    final original = controller.rows.first;
    await store.captureItemName(original);
    await store.captureCells(
      row: original,
      columnIds: const {7},
      columnContents: controller.scopedColumnContents,
    );
    await store.captureDeletedRows(
      rows: [controller.rows.last],
      columnContents: controller.scopedColumnContents,
    );
    await store.captureOrders(controller.rows);

    controller.updateItemName(original.rowKey, '변경 이름');
    controller.updateColumnValue(
      original.rowKey,
      columnId: 7,
      editable: true,
      dataString: '변경 값',
    );
    final added = controller
      .insertRowsAfter('item:10', 1, emptyElementPayload: '{}')
      .single;
    await store.recordAddedRows([added.rowKey]);
    final second = controller.rows.firstWhere((row) => row.rowKey == 'item:20');
    await store.captureItemName(second);
    controller.updateItemName(second.rowKey, '삭제 전 변경 이름');
    controller.deleteRows({'item:20'});

    final snapshot = await store.readSnapshot();
    controller.restoreBackup(
      fullImport: false,
      itemNames: snapshot.itemNames,
      elements: snapshot.elements,
      cells: snapshot.cells,
      orders: snapshot.orders,
      addedRowKeys: snapshot.addedRowKeys,
      deletedRows: snapshot.deletedRows,
      deletedColumns: snapshot.deletedColumns,
      selectedRowKeys: snapshot.selectedRowKeys,
      anchorRowKey: snapshot.anchorRowKey,
    );

    expect(controller.rows.map((row) => row.rowKey), ['item:10', 'item:20']);
    expect(controller.rows.map((row) => row.order), [1, 2]);
    expect(controller.rows.first.itemName, '원본 이름');
    expect(controller.rows.last.itemName, '둘째 이름');
    expect(controller.columnValue(controller.rows.first, 7), '원본 값');
    expect(controller.columnValue(controller.rows.last, 7), '둘째 값');
    expect(controller.isDirty, isFalse);
  });
}

ItemManagerDraftController _controller() {
  final items = [
    _itemOfMarket(itemId: 10, order: 1, name: '원본 이름'),
    _itemOfMarket(itemId: 20, order: 2, name: '둘째 이름'),
  ];
  return ItemManagerDraftController.fromItems(
    items: items,
    rawSnapshots: {10: _snapshot(10), 20: _snapshot(20)},
    scopedColumnContents: TColumnContentScopedView({
      const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
        colContentId: 1,
        columnId: 7,
        itemId: 10,
        editable: true,
        dataString: '원본 값',
      ),
      const ColumnItemKey(columnId: 7, itemId: 20): TColumnContent(
        colContentId: 2,
        columnId: 7,
        itemId: 20,
        editable: true,
        dataString: '둘째 값',
      ),
    }),
  );
}

ItemOfMarket _itemOfMarket({
  required int itemId,
  required int order,
  required String name,
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
      elementRTF: 'UEsDencoded',
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

ItemOfMarketRawSnapshot _snapshot(int itemId) => ItemOfMarketRawSnapshot(
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