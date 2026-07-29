// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

enum SpecalKeyword {
	NDEX_ITEMNAME(0, "ITEMNAME", "품명"),
	INDEX_ELEMENT(1, "ELEMENT", "주원료"),
	INDEX_SCALE_WEIGHT(2, "SWEIGHT", "저울중량"),
	INDEX_SCALE_PRICE(3, "SPRICE", "최종가격");

  final int code;
  final String keyword;
  final String columnName;
  const SpecalKeyword(this.code, this.keyword, this.columnName);
}

class TColumnSpecial {
  static const LABELSIZE_ID = 'labelSizeId';
  static const KEYWORD = 'keyword';
  static const RICH_CHECK_YN = 'RICH_CHECK_YN';
  static const RICH_MIN_CHECK = 'RICH_MIN_CHECK';

  static const int labelSizeId = 0;
  static List<TColumnBase>? datas;

  static Future<List<TColumnBase>?> selectByLabelSizeId(int labelSizeId) async {
    debugLog('$START, $LABELSIZE_ID:$labelSizeId');

    final sql = '''
      SELECT RICH_CHECK_YN FROM BM_RICH_CHECK_COLUMNS WHERE RICH_LABELSIZE_ID=@labelSizeId AND RICH_KEYWORD=@keyword
    ''';

    try {
      // ITEMNAME - 품명
      var columnBase = TColumnBase(
          columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
          keyword: SpecalKeyword.NDEX_ITEMNAME.keyword,
          columnName: SpecalKeyword.NDEX_ITEMNAME.columnName
        );

      var params = {LABELSIZE_ID: labelSizeId, KEYWORD: SpecalKeyword.NDEX_ITEMNAME.keyword };
      var res = await DbClient.instance.getDataWithParams(sql, params);
      var row = DAO.getRowMapFromResult(res, throwIfNoRows: false);
      if (row != null) { columnBase.useMissingKeywordCheck = row[RICH_CHECK_YN] != 0; }
      final columns = [ columnBase ];

      // ELEMENT - 주원료
      columnBase = TColumnBase(
        columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
        keyword: SpecalKeyword.INDEX_ELEMENT.keyword,
        columnName: SpecalKeyword.INDEX_ELEMENT.columnName
      );

      params = {LABELSIZE_ID: labelSizeId, KEYWORD: SpecalKeyword.INDEX_ELEMENT.keyword };
      res = await DbClient.instance.getDataWithParams(sql, params);
      row = DAO.getRowMapFromResult(res, throwIfNoRows: false);
      if (row != null) { columnBase.useMissingKeywordCheck = row[RICH_CHECK_YN] != 0; }
      final minCheckRes = await DbClient.instance.getDataWithParams('''
        SELECT TOP 1 RICH_MIN_CHECK FROM BM_RICH_COL_MIN
        WHERE RICH_LABELSIZE_ID=@labelSizeId AND (RICH_COLUMN_ID=0 OR RICH_KEYWORD=@keyword)
      ''', params);
      final minCheckRow = DAO.getRowMapFromResult(
        minCheckRes,
        throwIfNoRows: false,
      );
      if (minCheckRow != null) {
        columnBase.useMinColumnCheck = minCheckRow[RICH_MIN_CHECK] != 0;
      }
      columns.add(columnBase);

      // SCALE_WEIGHT - 저울중량
      columnBase = TColumnBase(
        columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
        keyword: SpecalKeyword.INDEX_SCALE_WEIGHT.keyword,
        columnName: SpecalKeyword.INDEX_SCALE_WEIGHT.columnName
      );

      params = {LABELSIZE_ID: labelSizeId, KEYWORD: SpecalKeyword.INDEX_SCALE_WEIGHT.keyword };
      res = await DbClient.instance.getDataWithParams(sql, params);
      row = DAO.getRowMapFromResult(res, throwIfNoRows: false);
      if (row != null) { columnBase.useMissingKeywordCheck = row[RICH_CHECK_YN] != 0; }
      columns.add(columnBase);

      // SCALE_PRICE - 최종가격 
      columnBase = TColumnBase(
        columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
        keyword: SpecalKeyword.INDEX_SCALE_PRICE.keyword,
        columnName: SpecalKeyword.INDEX_SCALE_PRICE.columnName
      );

      params = {LABELSIZE_ID: labelSizeId, KEYWORD: SpecalKeyword.INDEX_SCALE_PRICE.keyword };
      res = await DbClient.instance.getDataWithParams(sql, params);
      row = DAO.getRowMapFromResult(res, throwIfNoRows: false);
      if (row != null) { columnBase.useMissingKeywordCheck = row[RICH_CHECK_YN] != 0; }
      columns.add(columnBase);

      debugLog(END);
      return columns;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }

  static Future<void> updateElementMinColumnCheck({
    required int labelSizeId,
    required bool checked,
  }) async {
    const sql = '''
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

    await DbClient.instance.writeDataWithParams(sql, {
      'labelSizeId': labelSizeId,
      'keyword': SpecalKeyword.INDEX_ELEMENT.keyword,
      'columnName': SpecalKeyword.INDEX_ELEMENT.columnName,
      'minCheck': checked ? 1 : 0,
    });
    final element = datas?.firstWhere(
      (column) => column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword,
      orElse: () => TColumnBase(
        columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
        keyword: SpecalKeyword.INDEX_ELEMENT.keyword,
        columnName: SpecalKeyword.INDEX_ELEMENT.columnName,
      ),
    );
    if (element != null) {
      element.useMinColumnCheck = checked;
    }
  }
}
