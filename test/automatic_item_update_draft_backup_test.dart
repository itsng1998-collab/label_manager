import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/automatic_item_update_draft_backup.dart';
import 'package:label_manager/models/update_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late AutoItemUpdateDraftBackupStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('auto_item_update_backup_');
    store = AutoItemUpdateDraftBackupStore(
      metadata: const AutoItemUpdateDraftBackupMetadata(
        draftKey: 'user_1_2_4_3',
        userId: 'user',
        customerId: 1,
        brandId: 2,
        labelSizeId: 4,
        currentMarketId: 3,
      ),
      directoryProvider: () async => directory,
      databaseFactory: databaseFactoryFfi,
    );
    await store.start(
      selectedRowKeys: const {'update:10'},
      anchorRowKey: 'update:10',
    );
  });

  tearDown(() async {
    await store.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('backup keeps only the first before-image per target', () async {
    final row = _existingRow(updateItemId: 10, itemId: 100, rowKey: 'update:10');

    await store.captureApplyDate(row);
    await store.captureApplyDate(
      row.copyWith(applyDate: DateTime(2026, 7, 26)),
    );
    await store.captureElement(row);
    await store.captureElement(row.copyWith(element: '변경 주원료'));
    await store.captureCell(
      row: row,
      columnId: 7,
      original: const AutoItemUpdateCellValue(
        contentId: 1,
        columnId: 7,
        rowKey: 'update:10',
        editable: true,
        dataString: '원본 값',
      ),
    );
    await store.captureCell(
      row: row,
      columnId: 7,
      original: const AutoItemUpdateCellValue(
        contentId: 1,
        columnId: 7,
        rowKey: 'update:10',
        editable: true,
        dataString: '변경 값',
      ),
    );

    final snapshot = await store.readSnapshot();
    expect(snapshot.applyDates[10], DateTime(2026, 7, 25));
    expect(snapshot.elements[10]?.plain, '주원료');
    expect(
      snapshot.cells[const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:10')]?.dataString,
      '원본 값',
    );
  });

  test('deleted row backup includes the row and all row cells', () async {
    final rows = [
      _existingRow(updateItemId: 10, itemId: 100, rowKey: 'update:10'),
      _existingRow(updateItemId: 20, itemId: 200, rowKey: 'update:20'),
    ];
    await store.captureDeletedRows(
      rows: rows,
      cellValues: {
        const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:10'): const AutoItemUpdateCellValue(
          contentId: 1,
          columnId: 7,
          rowKey: 'update:10',
          editable: true,
          dataString: '원본 값',
        ),
        const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:20'): const AutoItemUpdateCellValue(
          contentId: 2,
          columnId: 7,
          rowKey: 'update:20',
          editable: true,
          dataString: '둘째 값',
        ),
      },
    );

    final snapshot = await store.readSnapshot();
    expect(snapshot.deletedRows.keys, {10, 20});
    expect(snapshot.deletedRows[10]?.itemName, '첫 품목');
    expect(snapshot.deletedCells.keys, {
      const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:10'),
      const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:20'),
    });
  });

  test('added row keys round-trip and clear removes sqlite side files', () async {
    await store.recordAddedRows(const {'auto-draft:1', 'auto-draft:2'});
    final snapshot = await store.readSnapshot();
    expect(snapshot.addedRowKeys, {'auto-draft:1', 'auto-draft:2'});

    final filesBefore = await directory.list(recursive: true).toList();
    expect(filesBefore, isNotEmpty);

    await store.clear();

    final filesAfter = await directory.list(recursive: true).toList();
    expect(filesAfter.whereType<File>(), isEmpty);
  });
}

AutoItemUpdateDraftRow _existingRow({
  required int updateItemId,
  required int itemId,
  required String rowKey,
}) {
  final source = UpdateItem(
    updateItemId: updateItemId,
    itemId: itemId,
    itemName: updateItemId == 10 ? '첫 품목' : '둘째 품목',
    labelSizeId: 4,
    element: '주원료',
    elementRTF: r'{\rtf1 element}',
    price: 0,
    applyDate: DateTime(2026, 7, updateItemId == 10 ? 25 : 26),
    isApply: false,
  );
  return AutoItemUpdateDraftRow.existing(
    source: source,
    currentMarketId: 3,
    originalIndex: updateItemId == 10 ? 0 : 1,
  ).copyWith(rowKey: rowKey);
}