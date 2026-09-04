import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/gs1/domain/gs1_ai_definition.dart';
import 'package:label_manager/features/item/application/item_manager_save_service.dart';
import 'package:label_manager/features/item/data/item_manager_save.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/item/domain/item_manager_rules.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';

void main() {
  group('[item manager draft]', () {
    test('warns about other markets when save includes deletion', () {
      expect(
        itemManagerSaveConfirmationMessage(hasDeletedItems: false),
        '품목관리 변경 사항을 저장할까요?',
      );
      expect(
        itemManagerSaveConfirmationMessage(hasDeletedItems: true),
        contains('같은 고객의 다른 market 품목관리에서도 보이지 않을 수 있습니다.'),
      );
    });

    test('resolves reload selection by item id, row index, then first row', () {
      final items = [
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
        _itemOfMarket(itemId: 30, order: 3, name: '셋째 품목'),
      ];

      expect(
        resolveItemManagerReloadSelectionIndex(
          items,
          selectedItemId: 20,
          fallbackIndex: 0,
        ),
        1,
      );
      expect(
        resolveItemManagerReloadSelectionIndex(
          items,
          selectedItemId: 99,
          fallbackIndex: 2,
        ),
        2,
      );
      expect(resolveItemManagerReloadSelectionIndex(items), 0);
      expect(resolveItemManagerReloadSelectionIndex(const []), isNull);
    });

    test('resolves saved selection from mapping and sole insert fallback', () {
      final selected = ItemManagerDraftRow.newRow(
        draftRowKey: 'draft-1',
        order: 1,
        originalIndex: 0,
        insertAnchorItemId: null,
        rowState: ItemManagerDraftRowState.added,
        emptyElementPayload: 'UEsDempty',
      );

      expect(
        resolveItemManagerSavedSelectionItemId(
          selectedRow: selected,
          insertedItemIdsByDraftKey: const {'draft-1': 101, 'draft-2': 102},
        ),
        101,
      );
      expect(
        resolveItemManagerSavedSelectionItemId(
          selectedRow: null,
          insertedItemIdsByDraftKey: const {'draft-1': 101},
        ),
        101,
      );
      expect(
        resolveItemManagerSavedSelectionItemId(
          selectedRow: null,
          insertedItemIdsByDraftKey: const {'draft-1': 101, 'draft-2': 102},
        ),
        isNull,
      );
    });

    test('save service builds command and preserves selected item', () async {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);
      controller.updateItemName('item:10', '수정 품목');
      controller.setSelection(const ['item:20'], anchorRowKey: 'item:20');
      ItemManagerSaveCommand? savedCommand;

      final execution = await executeItemManagerSave(
        controller: controller,
        labelSizeId: 4,
        targetMarketIds: const [3, 4],
        save: (command) async {
          savedCommand = command;
          return const ItemManagerSaveResult(
            insertedItemIdsByDraftKey: {},
          );
        },
      );

      expect(savedCommand, same(execution.command));
      expect(execution.command.targetMarketIds, [3, 4]);
      expect(execution.command.existingRows.single.itemName, '수정 품목');
      expect(execution.selectedItemId, 20);
      expect(execution.selectedRowIndex, 1);
    });

    test('content revision excludes selection-only changes', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);

      expect(controller.contentRevision, 0);
      controller.setSelection(const ['item:20'], anchorRowKey: 'item:20');
      expect(controller.contentRevision, 0);

      controller.updateItemName('item:10', '수정 품목');
      expect(controller.contentRevision, 1);

      controller.addRows(1, emptyElementPayload: '{}');
      expect(controller.contentRevision, 2);
    });

    test('minimum column check participates in draft save and revert', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
      ]);
      const changed = ItemManagerMinColumnCheckSave(
        labelSizeId: 4,
        columnId: 7,
        keyword: '{{가격}}',
        columnName: '가격',
        columnOrder: 2,
        checked: true,
      );

      controller.updateMinColumnCheck(
        value: changed,
        baselineChecked: false,
      );

      expect(controller.isDirty, isTrue);
      expect(controller.minColumnCheckValue(7, false), isTrue);
      expect(
        controller
            .toSaveCommand(labelSizeId: 4, targetMarketIds: const [3])
            .minColumnChecks,
        [changed],
      );

      controller.updateMinColumnCheck(
        value: const ItemManagerMinColumnCheckSave(
          labelSizeId: 4,
          columnId: 7,
          keyword: '{{가격}}',
          columnName: '가격',
          columnOrder: 2,
          checked: false,
        ),
        baselineChecked: false,
      );
      expect(controller.isDirty, isFalse);
      expect(controller.minColumnCheckValue(7, false), isFalse);
    });

    test('client editable change is saved without changing cell data', () {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket(itemId: 10, order: 1, name: '첫 품목')],
        scopedColumnContents: TColumnContentScopedView({
          const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
            colContentId: 1,
            columnId: 7,
            itemId: 10,
            editable: false,
            dataString: '원래 값',
          ),
        }),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '원래 값',
      );

      expect(controller.isDirty, isTrue);
      final value = controller
          .toSaveCommand(labelSizeId: 4, targetMarketIds: const [3])
          .columnValues
          .single;
      expect(value.editable, isTrue);
      expect(value.dataString, '원래 값');

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: false,
        dataString: '원래 값',
      );
      expect(controller.isDirty, isFalse);
    });

    test('applies auto increment values as drafts and skips committed keys', () {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket(itemId: 10, order: 1, name: '첫 품목')],
        scopedColumnContents: TColumnContentScopedView({
          const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
            colContentId: 1,
            columnId: 7,
            itemId: 10,
            editable: false,
            dataString: '001',
          ),
          const ColumnItemKey(columnId: 8, itemId: 10): TColumnContent(
            colContentId: 2,
            columnId: 8,
            itemId: 10,
            editable: true,
            dataString: '010',
          ),
        }),
      );

      controller.applyColumnValueDrafts(
        {
          const ColumnItemKey(columnId: 7, itemId: 10): '003',
          const ColumnItemKey(columnId: 8, itemId: 10): '011',
        },
        skippedKeys: {const ColumnItemKey(columnId: 8, itemId: 10)},
      );

      expect(controller.columnValue(controller.rows.single, 7), '003');
      expect(controller.columnValue(controller.rows.single, 8), '010');
      final saved = controller
          .toSaveCommand(labelSizeId: 4, targetMarketIds: const [3])
          .columnValues
          .single;
      expect(saved.columnId, 7);
      expect(saved.editable, isFalse);
      expect(controller.isDirty, isTrue);
    });

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

    test('removing a failed insert restores shifted rows to clean state', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);

      final inserted = controller.insertRowsAfter(
        'item:10',
        1,
        emptyElementPayload: '{}',
      );
      controller.deleteRows(inserted.map((row) => row.rowKey));

      expect(controller.rows.map((row) => row.order), [1, 2]);
      expect(
        controller.rows.map((row) => row.rowState),
        everyElement(ItemManagerDraftRowState.existing),
      );
      expect(controller.isDirty, isFalse);
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

    test('discards ordinary edits from the in-memory baseline', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);
      controller.updateItemName('item:10', '수정 품목');
      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: 'changed',
      );
      controller.addRows(1, emptyElementPayload: '{}');
      controller.deleteRows(const ['item:20']);

      controller.discardChanges(selectedItemId: 20);

      expect(controller.isDirty, isFalse);
      expect(controller.rows.map((row) => row.rowKey), ['item:10', 'item:20']);
      expect(controller.rows.first.itemName, '첫 품목');
      expect(controller.rows.first.columnDrafts, isEmpty);
      expect(controller.deletedSourceItemIds, isEmpty);
      expect(controller.anchorRowKey, 'item:20');
      expect(controller.selectedRowKeys, {'item:20'});
    });

    test('discards added rows to the clean selection baseline', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);
      controller.setSelection(const ['item:20'], anchorRowKey: 'item:20');
      controller.addRows(1, emptyElementPayload: '{}');

      controller.discardChanges();

      expect(controller.anchorRowKey, 'item:20');
      expect(controller.selectedRowKeys, {'item:20'});
    });

    test('discards added rows to the clean multi-selection baseline', () {
      final controller = _controller([
        _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
        _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
      ]);
      controller.setSelection(
        const ['item:10', 'item:20'],
        anchorRowKey: 'item:20',
      );
      controller.addRows(1, emptyElementPayload: '{}');

      controller.discardChanges();

      expect(controller.anchorRowKey, 'item:20');
      expect(controller.selectedRowKeys, {'item:10', 'item:20'});
    });

    test('rejects values that exceed save SQL string limits', () {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket(itemId: 10, order: 1, name: '기존 품목')],
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '일반 컬럼',
            typeCode: TColumnType.TYPE_BASE,
            required: false,
          ),
        ],
      );
      controller.updateItemName(
        'item:10',
        '가' * (ItemManagerLimits.maxItemNameLength + 1),
      );

      expect(
        controller.validateForSave,
        throwsA(
          isA<ItemManagerDraftValidationError>()
              .having(
                (error) => error.columnId,
                'columnId',
                ItemManagerFixedColumnIds.itemName,
              )
              .having(
                (error) => error.message,
                'message',
                contains('${ItemManagerLimits.maxItemNameLength}자 이하'),
              ),
        ),
      );

      controller.updateItemName(
        'item:10',
        '가' * ItemManagerLimits.maxItemNameLength,
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '나' * (ItemManagerLimits.maxColumnValueLength + 1),
      );
      expect(
        controller.validateForSave,
        throwsA(
          isA<ItemManagerDraftValidationError>()
              .having((error) => error.columnId, 'columnId', 7)
              .having(
                (error) => error.message,
                'message',
                contains('${ItemManagerLimits.maxColumnValueLength}자 이하'),
              ),
        ),
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '나' * ItemManagerLimits.maxColumnValueLength,
      );
      expect(controller.validateForSave, returnsNormally);
    });

    test(
      'replaces clean rows with imported drafts and deletes all sources',
      () {
        final controller = _controller([
          _itemOfMarket(itemId: 10, order: 1, name: '첫 품목'),
          _itemOfMarket(itemId: 20, order: 2, name: '둘째 품목'),
        ]);

        final imported = controller.replaceAllWithImportedRows(
          const [
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
          ],
        );

        expect(controller.deletedSourceItemIds, {10, 20});
        expect(controller.deletedRowsBySourceItemId, isEmpty);
        expect(controller.hasImportedRows, isTrue);
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
      expect(command.validate, returnsNormally);
    });

    test('builds legacy content history wire from final row values', () {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket(itemId: 10, order: 1, name: '기존')],
        scopedColumnContents: TColumnContentScopedView({
          const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
            colContentId: 1,
            columnId: 7,
            itemId: 10,
            editable: true,
            dataString: '기존\n가격',
          ),
        }),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '가격\n표시',
            typeCode: TColumnType.TYPE_BASE,
            required: false,
          ),
          ItemManagerColumnValidationRule(
            columnId: 8,
            columnName: '원산지',
            typeCode: TColumnType.TYPE_BASE,
            required: false,
          ),
        ],
      );
      controller.updateItemName('item:10', '수정\n품목');
      controller.updateElement(
        'item:10',
        elementPlain: '치즈\n우유',
        elementPayload: '{"sheet":1}',
      );
      controller.updateColumnValue(
        'item:10',
        columnId: 8,
        editable: true,
        dataString: '한국\n산',
      );

      final row = controller
          .toSaveCommand(labelSizeId: 4, targetMarketIds: const [3])
          .existingRows
          .single;

      expect(row.contentColumnsWire, '품목\n주원료\n가격표시\n원산지\n');
      expect(row.contentsWire, '수정품목\n치즈우유\n기존가격\n한국산\n');
    });

    test('allows empty item names and elements for existing and new rows', () {
      final existing = _itemOfMarket(itemId: 10, order: 1, name: '기존');
      final controller = ItemManagerDraftController.fromItems(
        items: [existing],
        scopedColumnContents: TColumnContentScopedView(const {}),
        requireElement: true,
      );
      controller.addRows(1, emptyElementPayload: 'UEsDempty');
      controller.updateItemName('item:10', '');
      controller.updateElement(
        'item:10',
        elementPlain: '',
        elementPayload: 'UEsDempty-existing',
      );

      final command = controller.toSaveCommand(
        labelSizeId: 4,
        targetMarketIds: const [3],
      );

      expect(command.existingRows.single.itemName, '');
      expect(command.existingRows.single.elementPlain, '');
      expect(command.newRows.single.itemName, '');
      expect(command.newRows.single.elementPlain, '');
      expect(command.validate, returnsNormally);
    });

    test('rejects missing required and unsupported image column values', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
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

    test('allows an empty element when the special column is required', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        scopedColumnContents: TColumnContentScopedView(const {}),
        requireElement: true,
      );

      expect(controller.validateForSave, returnsNormally);
    });

    test('normalizes EAN check digits and rejects odd ITF values', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
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

    test('does not barcode-validate a non-barcode column', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '제품유형',
            typeCode: TColumnType.TYPE_BASE,
            required: false,
            barcodeType: BarcodeType.Itf,
            useBarcodeCheckDigit: true,
          ),
        ],
      );

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: 'PE',
      );

      expect(controller.columnValue(controller.rows.single, 7), 'PE');
      expect(controller.validateForSave, returnsNormally);
    });

    test('does not format-validate an untouched existing column', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        scopedColumnContents: TColumnContentScopedView({
          const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
            colContentId: 1,
            columnId: 7,
            itemId: 10,
            editable: true,
            dataString: '123',
          ),
        }),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: 'ITF',
            typeCode: TColumnType.TYPE_BARCODE,
            required: false,
            barcodeType: BarcodeType.Itf,
          ),
        ],
      );

      controller.updateElement(
        'item:10',
        elementPlain: '수정된 주원료',
        elementPayload: 'UEsDchanged',
      );
      expect(controller.validateForSave, returnsNormally);

      controller.updateColumnValue(
        'item:10',
        columnId: 7,
        editable: true,
        dataString: '125',
      );
      expect(controller.validateForSave, throwsStateError);
    });

    test('validates legacy date and time column formats', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
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

    test('allows free-form valid time values like legacy', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');
      final controller = ItemManagerDraftController.fromItems(
        items: [row],
        scopedColumnContents: TColumnContentScopedView(const {}),
        validationRules: const [
          ItemManagerColumnValidationRule(
            columnId: 7,
            columnName: '소비시한',
            typeCode: TColumnType.TYPE_VALIDTIME,
            required: false,
          ),
        ],
      );

      for (final value in ['', '한글', 'text', '123']) {
        controller.updateColumnValue(
          'item:10',
          columnId: 7,
          editable: true,
          dataString: value,
        );
        expect(controller.validateForSave, returnsNormally);
      }
    });

    test('rejects invalid GS1 AI edits without changing the draft', () {
      final row = _itemOfMarket(itemId: 10, order: 1, name: '품목');

      final controller = ItemManagerDraftController.fromItems(
        items: [row],
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
