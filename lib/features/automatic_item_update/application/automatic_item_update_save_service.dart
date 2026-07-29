import 'package:label_manager/features/automatic_item_update/data/automatic_item_update_save.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';

typedef AutoItemUpdateCommandSaver = Future<AutoItemUpdateSaveResult> Function(
  AutoItemUpdateSaveCommand command,
);

class AutoItemUpdateSaveExecution {
  const AutoItemUpdateSaveExecution({
    required this.command,
    required this.result,
    required this.selectedRowKey,
    required this.selectedRowIndex,
  });

  final AutoItemUpdateSaveCommand command;
  final AutoItemUpdateSaveResult result;
  final String? selectedRowKey;
  final int selectedRowIndex;
}

Future<AutoItemUpdateSaveExecution> executeAutoItemUpdateSave({
  required AutoItemUpdateDraftController controller,
  AutoItemUpdateCommandSaver save = AutoItemUpdateSaveDAO.save,
}) async {
  controller.validateForSave();
  final selectedRowKey = controller.anchorRowKey;
  final selectedRowIndex = selectedRowKey == null
      ? -1
      : controller.rows.indexWhere((row) => row.rowKey == selectedRowKey);
  final command = controller.toSaveCommand();
  final result = await save(command);
  final insertedRowKey = result.insertedUpdateItemIdsByRowKey.keys.isEmpty
      ? null
      : result.insertedUpdateItemIdsByRowKey.keys.first;
  return AutoItemUpdateSaveExecution(
    command: command,
    result: result,
    selectedRowKey:
        selectedRowKey != null && controller.hasRowKey(selectedRowKey)
        ? selectedRowKey
        : insertedRowKey,
    selectedRowIndex: selectedRowIndex,
  );
}