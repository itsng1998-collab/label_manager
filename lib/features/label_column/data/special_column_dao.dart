import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class SpecialColumnDAO extends DAO {
  static const String selectCheckSql = '''
    SELECT RICH_CHECK_YN FROM BM_RICH_CHECK_COLUMNS
    WHERE RICH_LABELSIZE_ID=@labelSizeId AND RICH_KEYWORD=@keyword
  ''';

  static const String selectElementMinCheckSql = '''
    SELECT TOP 1 RICH_MIN_CHECK FROM BM_RICH_COL_MIN
    WHERE RICH_LABELSIZE_ID=@labelSizeId
      AND (RICH_COLUMN_ID=0 OR RICH_KEYWORD=@keyword)
  ''';

  static const String updateElementMinColumnCheckSql = '''
MERGE BM_RICH_COL_MIN AS T
USING (
  SELECT
    @labelSizeId AS RICH_LABELSIZE_ID,
    0 AS RICH_COLUMN_ID,
    @keyword AS RICH_KEYWORD,
    @columnName AS RICH_COLUMN_NAME,
    0 AS RICH_COLUMN_ORDER,
    @minCheck AS RICH_MIN_CHECK
) AS S
ON T.RICH_LABELSIZE_ID=S.RICH_LABELSIZE_ID
  AND (T.RICH_COLUMN_ID=S.RICH_COLUMN_ID OR T.RICH_KEYWORD=S.RICH_KEYWORD)
WHEN MATCHED THEN
  UPDATE SET T.RICH_COLUMN_ID=S.RICH_COLUMN_ID,
    T.RICH_KEYWORD=S.RICH_KEYWORD,
    T.RICH_COLUMN_NAME=S.RICH_COLUMN_NAME,
    T.RICH_COLUMN_ORDER=S.RICH_COLUMN_ORDER,
    T.RICH_MIN_CHECK=S.RICH_MIN_CHECK
WHEN NOT MATCHED THEN
  INSERT (
    RICH_COLUMN_ID, RICH_LABELSIZE_ID, RICH_KEYWORD, RICH_COLUMN_NAME,
    RICH_COLUMN_ORDER, RICH_MIN_CHECK
  ) VALUES (
    S.RICH_COLUMN_ID, S.RICH_LABELSIZE_ID, S.RICH_KEYWORD, S.RICH_COLUMN_NAME,
    S.RICH_COLUMN_ORDER, S.RICH_MIN_CHECK
  );
''';

  static Future<List<TColumnBase>?> selectByLabelSizeId(int labelSizeId) async {
    debugLog('$START, labelSizeId:$labelSizeId');

    try {
      final columns = <TColumnBase>[];
      for (final keyword in SpecalKeyword.values) {
        final params = {'labelSizeId': labelSizeId, 'keyword': keyword.keyword};
        final result = await DbClient.instance.getDataWithParams(
          selectCheckSql,
          params,
        );
        final row = DAO.getRowMapFromResult(result, throwIfNoRows: false);
        final column = TColumnBase(
          columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
          keyword: keyword.keyword,
          columnName: keyword.columnName,
          useMissingKeywordCheck:
              row != null && row['RICH_CHECK_YN'] != 0,
        );

        if (keyword == SpecalKeyword.INDEX_ELEMENT) {
          final minCheckResult = await DbClient.instance.getDataWithParams(
            selectElementMinCheckSql,
            params,
          );
          final minCheckRow = DAO.getRowMapFromResult(
            minCheckResult,
            throwIfNoRows: false,
          );
          column.useMinColumnCheck =
              minCheckRow != null && minCheckRow['RICH_MIN_CHECK'] != 0;
        }
        columns.add(column);
      }

      debugLog(END);
      return columns;
    } catch (error) {
      debugLog('$END, $error');
      throw Exception(error);
    }
  }

  static Future<void> updateElementMinColumnCheck({
    required int labelSizeId,
    required bool checked,
  }) async {
    await DbClient.instance
        .writeDataWithParams(updateElementMinColumnCheckSql, {
          'labelSizeId': labelSizeId,
          'keyword': SpecalKeyword.INDEX_ELEMENT.keyword,
          'columnName': SpecalKeyword.INDEX_ELEMENT.columnName,
          'minCheck': checked ? 1 : 0,
        });
  }
}
