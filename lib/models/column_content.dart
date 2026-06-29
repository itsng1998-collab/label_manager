// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class TColumnContent {
  static const int NO_ID = 0;

  final int colContentId;
  final int columnId;
  final int itemId;
  final bool editable;
  final String dataString;

  TColumnContent({
    required this.colContentId,
    required this.columnId,
    required this.itemId,
    required this.editable,
    required this.dataString,
  });

  @override
  String toString() =>
    'colContentId: $colContentId, columnId: $columnId, itemId: $itemId, editable: $editable, dataString: $dataString';

  factory TColumnContent.fromMap(Map<String, dynamic> map) {
    return TColumnContent(
      colContentId: map['RICH_COL_CONTENT_ID'],
      columnId: map['RICH_COLUMN_ID'],
      itemId: map['RICH_ITEM_ID'],
      editable: map['RICH_EDITABLE'] != 0,
      dataString: map['RICH_COL_CONTENT_DATA'],
    );
  }

  static Map<ColumnItemKey, TColumnContent>? datas;

  static void setDatas(Map<ColumnItemKey, TColumnContent>? values) {
    datas = values;
  }

  static TColumnContent? get(int columnId, int itemId) {
    final map = datas;
    if (map == null) return null;
    return map[ColumnItemKey(columnId: columnId, itemId: itemId)];
  }

}

class ColumnItemKey {
  final int columnId;
  final int itemId;

  const ColumnItemKey({required this.columnId, required this.itemId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnItemKey &&
        runtimeType == other.runtimeType &&
        columnId == other.columnId &&
        itemId == other.itemId;

  @override
  int get hashCode => Object.hash(columnId, itemId);
}

class TColumnContentDAO extends DAO {
  static const String SelectByLabelSizeId = '''
    SELECT 
      P1.RICH_COL_CONTENT_ID AS RICH_COL_CONTENT_ID,
      P1.RICH_COLUMN_ID AS RICH_COLUMN_ID,
      P1.RICH_ITEM_ID AS RICH_ITEM_ID,
      P1.RICH_EDITABLE AS RICH_EDITABLE,
      COALESCE(CONVERT(NVARCHAR(3000), P1.RICH_COL_CONTENT_DATA COLLATE ${DAO.CP949}), N'') AS RICH_COL_CONTENT_DATA
    FROM BM_RICH_COL_CONTENT P1 
    INNER JOIN BM_RICH_ITEM P2 
    ON P1.RICH_ITEM_ID=P2.RICH_ITEM_ID 
    INNER JOIN BM_RICH_COLUMN P3 
    ON P1.RICH_COLUMN_ID=P3.RICH_COLUMN_ID
	''';

  static const String WhereSqlByLabelSizeId = '''
		WHERE P2.RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String OrderByItemAndColumn = '''
		ORDER BY P2.RICH_ITEM_ORDER,P2.RICH_ITEM_ID, P3.RICH_COLUMN_ORDER, P3.RICH_COLUMN_ID ASC
	''';

  static Future<Map<ColumnItemKey, TColumnContent>?> getByLabelSizeId(int labelSizeId) async {
    debugLog('$START, labelSizeId:$labelSizeId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectByLabelSizeId $WhereSqlByLabelSizeId $OrderByItemAndColumn', {'labelSizeId': labelSizeId},
      );

      final columnContents = DAO.mapRowsByKey(
        res,
        TColumnContent.fromMap,
        (item) => ColumnItemKey(columnId: item.columnId, itemId: item.itemId),
      );

      debugLog(END);
      return columnContents;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }
}
