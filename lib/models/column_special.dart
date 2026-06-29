// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_type.dart';
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

  static const int labelSizeId = 0;
  static List<TColumnBase>? datas;

  static Future<List<TColumnBase>?> getByLabelSizeId(int labelSizeId) async {
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
}
