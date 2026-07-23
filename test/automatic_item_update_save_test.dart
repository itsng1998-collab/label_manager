import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/automatic_item_update_save.dart';
import 'package:label_manager/models/update_item.dart';

void main() {
  group('[automatic item update save]', () {
    test('controller builds save command from modified, added, and deleted rows', () {
      final controller = _controller();
      controller.updateApplyDate('update:10', '20260726');
      controller.updateCellValue(
        'update:10',
        columnId: 7,
        editable: true,
        dataString: '변경 값',
      );
      controller.stageAppendItems([_seed(30, '추가 품목')]);
      controller.applyStagedRows();
      controller.deleteRows(const {'update:20'});

      final command = controller.toSaveCommand();

      expect(command.deletedUpdateItemIds, [20]);
      expect(command.existingRows.map((row) => row.sourceUpdateItemId), [10]);
      expect(command.newRows.map((row) => row.draftRowKey), ['auto-draft:0']);
      expect(command.cellValues, hasLength(2));
    });

    test('builds one XML transaction statement without json helpers', () {
      final command = AutoItemUpdateSaveCommand(
        deletedUpdateItemIds: const [20],
        existingRows: [
          AutoItemUpdateExistingRowSave(
            sourceUpdateItemId: 10,
            sourceItemId: 100,
            labelSizeId: 4,
            itemName: '기존 품목',
            element: '주원료',
            elementRtf: r'{\rtf1 element}',
            price: 0,
            applyDate: DateTime(2026, 7, 26),
          ),
        ],
        newRows: [
          AutoItemUpdateNewRowSave(
            draftRowKey: 'auto-draft:3',
            sourceItemId: 300,
            labelSizeId: 4,
            itemName: '신규 품목',
            element: '주원료',
            elementRtf: r'{\rtf1 element}',
            price: 0,
            applyDate: DateTime(2026, 7, 27),
          ),
        ],
        cellValues: const [
          AutoItemUpdateCellValueSave(
            sourceUpdateItemId: 10,
            columnId: 7,
            editable: true,
            dataString: '변경 값',
          ),
          AutoItemUpdateCellValueSave(
            draftRowKey: 'auto-draft:3',
            columnId: 8,
            editable: true,
            dataString: '신규 값',
          ),
        ],
      );

      final statement = AutoItemUpdateSaveDAO.buildSaveStatement(command);
      final deletedXml = statement.params['deletedUpdateItemIdsXml'] as String;
      final existingXml = statement.params['existingRowsXml'] as String;
      final newXml = statement.params['newRowsXml'] as String;
      final cellXml = statement.params['cellValuesXml'] as String;

      expect(statement.returnsRows, isTrue);
      expect(statement.sql, contains('CONVERT(XML, @deletedUpdateItemIdsXml)'));
      expect(statement.sql, contains('MERGE BM_UPDATE_ITEM AS TARGET'));
      expect(statement.sql, contains('OUTPUT SOURCE.DRAFT_ROW_KEY, INSERTED.RICH_UPDATE_ITEM_ID'));
      expect(statement.sql, contains('DELETE C\n      FROM BM_UPDATE_COL_CONTENT C'));
      expect(statement.sql, isNot(contains('OPENJSON')));
      expect(statement.sql, isNot(contains('JSON_VALUE')));
      expect(deletedXml, '<rows><row id="20" /></rows>');
      expect(existingXml, contains('sourceUpdateItemId="10"'));
      expect(existingXml, contains('<applyDate>20260726</applyDate>'));
      expect(newXml, contains('draftRowKey="auto-draft:3"'));
      expect(cellXml, contains('sourceUpdateItemId="10"'));
      expect(cellXml, contains('<draftRowKey>auto-draft:3</draftRowKey>'));
    });
  });
}

AutoItemUpdateDraftController _controller() {
  return AutoItemUpdateDraftController(
    rows: [
      AutoItemUpdateDraftRow.existing(
        source: _item(10, 100, '첫 품목', DateTime(2026, 7, 25)),
        currentMarketId: 3,
        originalIndex: 0,
      ),
      AutoItemUpdateDraftRow.existing(
        source: _item(20, 200, '둘째 품목', DateTime(2026, 7, 26)),
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

AutoItemUpdateSourceSeed _seed(int itemId, String itemName) {
  return AutoItemUpdateSourceSeed(
    itemId: itemId,
    itemName: itemName,
    labelSizeId: 4,
    element: '주원료',
    elementRtf: r'{\rtf1 element}',
    price: 0,
    currentMarketId: 3,
    columnValues: const {7: (editable: true, dataString: '복사 값')},
  );
}

dynamic _item(int updateItemId, int itemId, String name, DateTime applyDate) {
  return UpdateItem(
    updateItemId: updateItemId,
    itemId: itemId,
    itemName: name,
    labelSizeId: 4,
    element: '주원료',
    elementRTF: r'{\rtf1 element}',
    price: 0,
    applyDate: applyDate,
    isApply: false,
  );
}