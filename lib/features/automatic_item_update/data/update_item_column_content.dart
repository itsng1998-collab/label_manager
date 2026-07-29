import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class UpdateItemColumnContent {
  const UpdateItemColumnContent({
    required this.updateColContentId,
    required this.columnId,
    required this.updateItemId,
    required this.dataString,
  });

  final int updateColContentId;
  final int columnId;
  final int updateItemId;
  final String dataString;

  factory UpdateItemColumnContent.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;
    return UpdateItemColumnContent(
      updateColContentId: i('UPDATE_COL_CONTENT_ID'),
      columnId: i('COLUMN_ID'),
      updateItemId: i('UPDATE_ITEM_ID'),
      dataString: s('DATA_STRING'),
    );
  }
}

class UpdateItemColumnContentDAO extends DAO {
  static const String selectPendingByLabelSizeIdSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), C.RICH_UPDATE_COL_CONTENT_ID), N'') AS UPDATE_COL_CONTENT_ID,
      COALESCE(CONVERT(NVARCHAR(20), C.RICH_COLUMN_ID), N'') AS COLUMN_ID,
      COALESCE(CONVERT(NVARCHAR(20), C.RICH_UPDATE_ITEM_ID), N'') AS UPDATE_ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(3000), C.RICH_COL_CONTENT_DATA COLLATE ${DAO.CP949}), N'') AS DATA_STRING
    FROM BM_UPDATE_COL_CONTENT C
    INNER JOIN BM_UPDATE_ITEM U ON U.RICH_UPDATE_ITEM_ID=C.RICH_UPDATE_ITEM_ID
    INNER JOIN BM_RICH_COLUMN R ON R.RICH_COLUMN_ID=C.RICH_COLUMN_ID
    WHERE U.RICH_LABELSIZE_ID=@labelSizeId
      AND U.RICH_IS_APPLY=@isApply
    ORDER BY U.RICH_UPDATE_ITEM_ID ASC, R.RICH_COLUMN_ORDER ASC,
      R.RICH_COLUMN_ID ASC
  ''';

  static Future<Map<AutoItemUpdateCellKey, AutoItemUpdateCellValue>>
  selectPendingByLabelSizeId(
    int labelSizeId, {
    required Map<int, String> rowKeyByUpdateItemId,
  }) async {
    if (labelSizeId <= 0) {
      throw ArgumentError.value(labelSizeId, 'labelSizeId', 'Must be positive.');
    }
    debugLog('$START, labelSizeId:$labelSizeId, isApply:0');
    try {
      final res = await DbClient.instance.getDataWithParams(
        selectPendingByLabelSizeIdSql,
        {'labelSizeId': labelSizeId, 'isApply': 0},
      );
      final contents = DAO.mapRows(res, UpdateItemColumnContent.fromMap);
      final values = <AutoItemUpdateCellKey, AutoItemUpdateCellValue>{};
      for (final content in contents) {
        final rowKey = rowKeyByUpdateItemId[content.updateItemId];
        if (rowKey == null) {
          continue;
        }
        values[
          AutoItemUpdateCellKey(columnId: content.columnId, rowKey: rowKey)
        ] = AutoItemUpdateCellValue(
          contentId: content.updateColContentId,
          columnId: content.columnId,
          rowKey: rowKey,
          editable: true,
          dataString: content.dataString,
        );
      }
      debugLog(END);
      return values;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }
}