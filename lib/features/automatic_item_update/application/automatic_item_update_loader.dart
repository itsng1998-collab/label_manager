import 'package:label_manager/features/automatic_item_update/data/update_item.dart';
import 'package:label_manager/features/automatic_item_update/data/update_item_column_content.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';

String? resolveAutoItemUpdateLoadedSelection(
  List<AutoItemUpdateDraftRow> rows, {
  String? selectedRowKey,
  int? fallbackIndex,
}) {
  if (rows.isEmpty) return null;
  if (selectedRowKey != null &&
      rows.any((row) => row.rowKey == selectedRowKey)) {
    return selectedRowKey;
  }
  if (fallbackIndex != null &&
      fallbackIndex >= 0 &&
      fallbackIndex < rows.length) {
    return rows[fallbackIndex].rowKey;
  }
  return rows.first.rowKey;
}

Future<AutoItemUpdateDraftController> loadAutoItemUpdateDraft({
  required int labelSizeId,
  required int marketId,
  String? selectedRowKey,
  int? fallbackIndex,
}) async {
  final items = await UpdateItemDAO.selectPendingByLabelSizeId(labelSizeId);
  final rows = [
    for (var index = 0; index < items.length; index += 1)
      AutoItemUpdateDraftRow.existing(
        source: items[index],
        currentMarketId: marketId,
        originalIndex: index,
      ),
  ];
  final rowKeyByUpdateItemId = {
    for (final row in rows)
      if (row.sourceUpdateItemId != null) row.sourceUpdateItemId!: row.rowKey,
  };
  final cellValues =
      await UpdateItemColumnContentDAO.selectPendingByLabelSizeId(
        labelSizeId,
        rowKeyByUpdateItemId: rowKeyByUpdateItemId,
      );
  final controller = AutoItemUpdateDraftController(
    rows: rows,
    cellValues: cellValues,
    serverToday: await UpdateItemDAO.selectServerToday(),
  );
  final nextSelectedRowKey = resolveAutoItemUpdateLoadedSelection(
    rows,
    selectedRowKey: selectedRowKey,
    fallbackIndex: fallbackIndex,
  );
  if (nextSelectedRowKey != null) {
    controller.setSelection(
      [nextSelectedRowKey],
      anchorRowKey: nextSelectedRowKey,
    );
  }
  return controller;
}