import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/automatic_item_update/application/automatic_item_update_loader.dart';
import 'package:label_manager/features/automatic_item_update/application/automatic_item_update_save_service.dart';
import 'package:label_manager/features/automatic_item_update/data/automatic_item_update_save.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';
import 'package:label_manager/features/automatic_item_update/domain/update_item.dart';

void main() {
  group('[automatic item update draft]', () {
    test('builds baseline rows and starts clean', () {
      final controller = _controller();

      expect(controller.rows, hasLength(2));
      expect(controller.rows.first.rowKey, 'update:10');
      expect(controller.applyDateText(controller.rows.first), '20260725');
      expect(controller.isDirty, isFalse);
      expect(controller.hasStagedRows, isFalse);
    });

    test('loaded selection keeps the previous row when it still exists', () {
      final rows = _controller().rows;

      expect(
        resolveAutoItemUpdateLoadedSelection(
          rows,
          selectedRowKey: 'update:20',
          fallbackIndex: 0,
        ),
        'update:20',
      );
    });

    test('loaded selection falls back to index, first row, or null', () {
      final rows = _controller().rows;

      expect(
        resolveAutoItemUpdateLoadedSelection(
          rows,
          selectedRowKey: 'missing',
          fallbackIndex: 1,
        ),
        'update:20',
      );
      expect(
        resolveAutoItemUpdateLoadedSelection(
          rows,
          selectedRowKey: 'missing',
          fallbackIndex: 10,
        ),
        'update:10',
      );
      expect(resolveAutoItemUpdateLoadedSelection(const []), isNull);
    });

    test('save service builds command and preserves selected row', () async {
      final controller = _controller();
      controller.updateApplyDate('update:10', '20260726');
      controller.setSelection(const {'update:20'}, anchorRowKey: 'update:20');
      AutoItemUpdateSaveCommand? savedCommand;

      final execution = await executeAutoItemUpdateSave(
        controller: controller,
        save: (command) async {
          savedCommand = command;
          return const AutoItemUpdateSaveResult(
            insertedUpdateItemIdsByRowKey: {},
          );
        },
      );

      expect(savedCommand, same(execution.command));
      expect(execution.command.existingRows.single.sourceUpdateItemId, 10);
      expect(execution.selectedRowKey, 'update:20');
      expect(execution.selectedRowIndex, 1);
    });

    test('apply date, element, and cell edits mark an existing row modified', () {
      final controller = _controller();

      expect(controller.updateApplyDate('update:10', '20260726'), isTrue);
      controller.updateElement(
        'update:10',
        element: '변경 주원료',
        elementRtf: r'{\rtf1 changed}',
      );
      controller.updateCellValue(
        'update:10',
        columnId: 7,
        editable: true,
        dataString: '변경 값',
      );

      final row = controller.rows.first;
      expect(row.rowState, AutoItemUpdateRowState.modified);
      expect(controller.isDirty, isTrue);
      expect(row.element, '변경 주원료');
      expect(controller.columnValue(row, 7), '변경 값');
    });

    test('invalid apply date is rejected and leaves the row unchanged', () {
      final controller = _controller();

      expect(controller.updateApplyDate('update:10', '20260723'), isFalse);
      expect(controller.applyDateText(controller.rows.first), '20260725');
      expect(controller.isDirty, isFalse);
    });

    test('staged additions append at end without making the controller dirty', () {
      final controller = _controller();

      final staged = controller.stageAppendItems([
        _seed(itemId: 30, itemName: '추가 품목 1'),
        _seed(itemId: 40, itemName: '추가 품목 2'),
      ]);

      expect(staged, hasLength(2));
      expect(staged.every((row) => row.rowState == AutoItemUpdateRowState.staged), isTrue);
      expect(controller.rows.takeLast(2).map((row) => row.itemName), ['추가 품목 1', '추가 품목 2']);
      expect(controller.anchorRowKey, staged.first.rowKey);
      expect(controller.applyDateText(staged.first), '20260724');
      expect(controller.isDirty, isFalse);
      expect(controller.hasStagedRows, isTrue);
    });

    test('applying staged additions converts them to added rows and makes draft dirty', () {
      final controller = _controller();
      controller.stageAppendItems([
        _seed(itemId: 30, itemName: '추가 품목 1'),
        _seed(itemId: 30, itemName: '추가 품목 1 재추가'),
      ]);

      final addedKeys = controller.applyStagedRows();

      expect(addedKeys, hasLength(2));
      expect(
        controller.rows.skip(2).map((row) => row.rowState),
        everyElement(AutoItemUpdateRowState.added),
      );
      expect(controller.isDirty, isTrue);
      expect(controller.hasStagedRows, isFalse);
    });

    test('canceling staged additions restores the clean baseline selection', () {
      final controller = _controller();
      controller.setSelection(const {'update:20'}, anchorRowKey: 'update:20');
      controller.startAddMode();
      controller.stageAppendItems([_seed(itemId: 30, itemName: '추가 품목 1')]);

      controller.cancelStagedRows();

      expect(controller.rows.map((row) => row.rowKey), ['update:10', 'update:20']);
      expect(controller.selectedRowKeys, {'update:20'});
      expect(controller.anchorRowKey, 'update:20');
      expect(controller.isDirty, isFalse);
    });

    test('same selection and anchor does not notify again', () {
      final controller = _controller();
      var notifications = 0;
      controller.addListener(() {
        notifications += 1;
      });

      controller.setSelection(const {'update:20'}, anchorRowKey: 'update:20');
      controller.setSelection(const {'update:20'}, anchorRowKey: 'update:20');

      expect(notifications, 1);
      expect(controller.selectedRowKeys, {'update:20'});
      expect(controller.anchorRowKey, 'update:20');
    });

    test('delete removes existing ids but not unsaved added rows', () {
      final controller = _controller();
      controller.stageAppendItems([_seed(itemId: 30, itemName: '추가 품목 1')]);
      controller.applyStagedRows();
      final addedKey = controller.rows.last.rowKey;

      final nextKey = controller.deleteRows({'update:20', addedKey});

      expect(controller.deletedUpdateItemIds, {20});
      expect(controller.rows.map((row) => row.rowKey), ['update:10']);
      expect(nextKey, 'update:10');
      expect(controller.anchorRowKey, 'update:10');
    });

    test('restore backup returns to the clean baseline selection', () {
      final controller = _controller();
      controller.setSelection(const {'update:20'}, anchorRowKey: 'update:20');
      controller.updateElement(
        'update:10',
        element: '변경 주원료',
        elementRtf: r'{\rtf1 changed}',
      );
      controller.stageAppendItems([_seed(itemId: 30, itemName: '추가 품목 1')]);
      controller.applyStagedRows();
      controller.deleteRows({'update:20'});

      controller.restoreBackup(
        selectedRowKeys: const {'update:20'},
        anchorRowKey: 'update:20',
      );

      expect(controller.rows.map((row) => row.rowKey), ['update:10', 'update:20']);
      expect(controller.rows.first.rowState, AutoItemUpdateRowState.existing);
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.existing);
      expect(controller.selectedRowKeys, {'update:20'});
      expect(controller.anchorRowKey, 'update:20');
      expect(controller.isDirty, isFalse);
    });

    test('restore backup reapplies stored snapshot rows and cells', () {
      final controller = _controller();
      controller.stageAppendItems([_seed(itemId: 30, itemName: '추가 품목 1')]);
      final addedRowKeys = controller.applyStagedRows();
      controller.deleteRows({'update:20'});

      controller.restoreBackup(
        applyDates: {10: DateTime(2026, 7, 30)},
        elements: {
          10: (plain: '복원 주원료', payload: r'{\rtf1 restored}'),
        },
        cells: {
          const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:10'): const AutoItemUpdateCellValue(
            contentId: 1,
            columnId: 7,
            rowKey: 'update:10',
            editable: true,
            dataString: '복원 값',
          ),
        },
        addedRowKeys: addedRowKeys,
        deletedRows: {
          30: AutoItemUpdateDraftRow.existing(
            source: _updateItem(
              updateItemId: 30,
              itemId: 300,
              itemName: '복원 품목',
              applyDate: DateTime(2026, 7, 27),
            ),
            currentMarketId: 3,
            originalIndex: 1,
          ),
        },
        deletedCells: {
          const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:30'): const AutoItemUpdateCellValue(
            contentId: 3,
            columnId: 7,
            rowKey: 'update:30',
            editable: true,
            dataString: '복원 품목 값',
          ),
        },
        selectedRowKeys: const {'update:30'},
        anchorRowKey: 'update:30',
      );

      expect(controller.rows.map((row) => row.rowKey), ['update:10', 'update:20', 'update:30']);
      expect(controller.applyDateText(controller.rows.first), '20260730');
      expect(controller.rows.first.element, '복원 주원료');
      expect(controller.rows.first.rowState, AutoItemUpdateRowState.modified);
      expect(controller.columnValue(controller.rows.first, 7), '복원 값');
      expect(controller.columnValue(controller.rows[2], 7), '복원 품목 값');
      expect(controller.selectedRowKeys, {'update:30'});
      expect(controller.anchorRowKey, 'update:30');
    });
  });
}

AutoItemUpdateDraftController _controller() {
  return AutoItemUpdateDraftController(
    rows: [
      AutoItemUpdateDraftRow.existing(
        source: _updateItem(updateItemId: 10, itemId: 100, itemName: '첫 품목', applyDate: DateTime(2026, 7, 25)),
        currentMarketId: 3,
        originalIndex: 0,
      ),
      AutoItemUpdateDraftRow.existing(
        source: _updateItem(updateItemId: 20, itemId: 200, itemName: '둘째 품목', applyDate: DateTime(2026, 7, 26)),
        currentMarketId: 3,
        originalIndex: 1,
      ),
    ],
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
    serverToday: DateTime(2026, 7, 23),
  );
}

UpdateItem _updateItem({
  required int updateItemId,
  required int itemId,
  required String itemName,
  required DateTime applyDate,
}) {
  return UpdateItem(
    updateItemId: updateItemId,
    itemId: itemId,
    itemName: itemName,
    labelSizeId: 4,
    element: '주원료',
    elementRTF: r'{\rtf1 element}',
    price: 0,
    applyDate: applyDate,
    isApply: false,
  );
}

AutoItemUpdateSourceSeed _seed({
  required int itemId,
  required String itemName,
}) {
  return AutoItemUpdateSourceSeed(
    itemId: itemId,
    itemName: itemName,
    labelSizeId: 4,
    element: '주원료',
    elementRtf: r'{\rtf1 element}',
    price: 0,
    currentMarketId: 3,
    columnValues: const {
      7: (editable: true, dataString: '복사 값'),
    },
  );
}

extension on List<AutoItemUpdateDraftRow> {
  Iterable<AutoItemUpdateDraftRow> takeLast(int count) => skip(length - count);
}
