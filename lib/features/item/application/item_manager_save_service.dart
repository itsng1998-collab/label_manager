import 'package:label_manager/features/item/data/item_manager_save.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';

typedef ItemManagerCommandSaver = Future<ItemManagerSaveResult> Function(
  ItemManagerSaveCommand command,
);

class ItemManagerSaveExecution {
  const ItemManagerSaveExecution({
    required this.command,
    required this.result,
    required this.selectedItemId,
    required this.selectedRowIndex,
  });

  final ItemManagerSaveCommand command;
  final ItemManagerSaveResult result;
  final int? selectedItemId;
  final int selectedRowIndex;
}

Future<ItemManagerSaveExecution> executeItemManagerSave({
  required ItemManagerDraftController controller,
  required int labelSizeId,
  required List<int> targetMarketIds,
  ItemManagerCommandSaver save = ItemManagerSaveDAO.save,
}) async {
  controller.validateForSave();
  final selectedKey = controller.anchorRowKey;
  final selectedRowIndex = selectedKey == null
      ? -1
      : controller.rows.indexWhere((row) => row.rowKey == selectedKey);
  final selectedRow = selectedRowIndex < 0
      ? null
      : controller.rows[selectedRowIndex];
  final command = controller.toSaveCommand(
    labelSizeId: labelSizeId,
    targetMarketIds: targetMarketIds,
  );
  final result = await save(command);
  return ItemManagerSaveExecution(
    command: command,
    result: result,
    selectedItemId: resolveItemManagerSavedSelectionItemId(
      selectedRow: selectedRow,
      insertedItemIdsByDraftKey: result.insertedItemIdsByDraftKey,
    ),
    selectedRowIndex: selectedRowIndex,
  );
}