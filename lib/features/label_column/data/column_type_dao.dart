import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/models/dao.dart';

TColumnType columnTypeFromRow(Map<String, dynamic> row) {
  return TColumnType(
    code: row['RICH_COLUMN_TYPE_CODE'],
    name: (row['RICH_COLUMN_TYPE_NAME'] ?? '').toString(),
    order: row['RICH_COLUMN_TYPE_ORDER'],
  );
}

class ColumnTypeDAO {
  const ColumnTypeDAO._();

  static const selectSql =
      '''
SELECT
  RICH_COLUMN_TYPE_CODE,
  COALESCE(CONVERT(NVARCHAR(100), RICH_COLUMN_TYPE_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_TYPE_NAME,
  RICH_COLUMN_TYPE_ORDER
FROM BM_RICH_COLUMN_TYPE
ORDER BY RICH_COLUMN_TYPE_ORDER ASC
''';

  static Future<List<TColumnType>> selectAll() async {
    final result = await DbClient.instance.getData(selectSql);
    return DAO.mapRows(result, columnTypeFromRow);
  }
}
