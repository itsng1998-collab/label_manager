// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

TColumn tColumnFromRow(Map<String, dynamic> row) {
  String s(String key) => (row[key] ?? '').toString();
  dynamic v(String key) => row[key];

  return TColumn(
    columnId: v('RICH_COLUMN_ID'),
    labelSizeId: v('RICH_LABELSIZE_ID'),
    order: v('RICH_COLUMN_ORDER'),
    width: v('RICH_WIDTH'),
    height: v('RICH_HEIGHT'),
    barcodeType: _barcodeTypeFromDb(s('RICH_BARCODE_TYPE')),
    useBarcodeCheckDigit: v('RICH_USE_BARCODE_CHECKDIGIT') != 0,
    showBarcodeNum: v('RICH_SHOW_BARCODE_NUM') != 0,
    showQRCodeText: v('RICH_SHOW_QRCODE_TEXT') != 0,
    qrTextAlignment: _qrTextAlignmentFromCode(v('RICH_QRTEXT_ALIGNMENT')),
    useUserDefineQRData: v('RICH_USE_USER_DEFINE_QRDATA') != 0,
    userDefineQRData: s('RICH_USER_DEFINE_QRDATA'),
    userDefineQRText: s('RICH_USER_DEFINE_QRTEXT'),
    pixelSize: v('RICH_PIXELSIZE'),
    title: s('RICH_TITLE'),
    visible: v('RICH_VISIBLE') != 0,
    qrCodeCreateType: _qrCodeCreateTypeFromCode(v('RICH_QRCODE_CREATE_TYPE')),
    natriumJoinString: s('RICH_NATRIUM_JOIN_STRING'),
    qrTextFontSize: v('RICH_QRTEXT_FONTSIZE'),
    qrTextFontName: s('RICH_QRTEXT_FONTNAME'),
    qrCodeScalePercent: v('RICH_QRCODE_SCALE'),
    columnType: TColumnType.getFromCode(v('RICH_TYPE')),
    keyword: s('RICH_KEYWORD'),
    columnName: s('RICH_COLUMN_NAME'),
    useMissingKeywordCheck: v('RICH_CHECK_YN') != 0,
    useMinColumnCheck: v('RICH_MIN_CHECK') != 0,
    timeBarcodeType: v('RICH_TIMEBARCODE_TYPE'),
    autoInc: v('RICH_AUTO_INC') != 0,
    autoIncSize: v('RICH_AUTO_INC_SIZE'),
    autoIncRange: v('RICH_AUTO_INC_RANGE'),
    autoIncSave: v('RICH_AUTO_INC_SAVE') != 0,
    autoIncZeroDel: v('RICH_AUTO_INC_ZERODEL') != 0,
    searchPrint: v('RICH_SEARCH_PRINT') != 0,
    userDefineBarcodeText: s('RICH_USER_DEFINE_BARCODE_TEXT'),
    lineCheck: v('RICH_BARCODE_LINE'),
    lineSize: v('RICH_BARCODE_LINE_SIZE'),
    rotate: v('RICH_BARCODE_ROTATE'),
    autoIncUpdate: v('RICH_AUTO_INC_UPDATE') != 0,
    useDateRange: v('RICH_USE_DATERANGE') != 0,
    dateRange: s('RICH_DATERANGE'),
    gs1ai: s('COLUMN_GS1_CODE'),
    formatOption: v('COLUMN_GS1_FORMAT_OPTION'),
    useGS1Code: v('USE_GS1_CODE') != 0,
    containColumns: s('CONTAIN_COLUMNS_ID'),
    showGS1Code: v('COLUMN_SHOW_GS1CODE') != 0,
  );
}

BarcodeType _barcodeTypeFromDb(String dbName) {
  return barcodeTypeFromDbName(dbName);
}

QRTextAlignment _qrTextAlignmentFromCode(Object? code) {
  return QRTextAlignment.values.firstWhere(
    (e) => e.code == code,
    orElse: () => QRTextAlignment.ALIGN_LEFT,
  );
}

QRCodeCreateType _qrCodeCreateTypeFromCode(Object? code) {
  return QRCodeCreateType.values.firstWhere(
    (e) => e.code == code,
    orElse: () => QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
  );
}

class TColumnDAO extends DAO {
  static const String selectSql =
      '''
		SELECT 
			BM_RICH_COLUMN.RICH_COLUMN_ID AS RICH_COLUMN_ID,
			BM_RICH_COLUMN.RICH_LABELSIZE_ID AS RICH_LABELSIZE_ID,
			BM_RICH_COLUMN.RICH_COLUMN_ORDER AS RICH_COLUMN_ORDER,
			BM_RICH_COLUMN.RICH_WIDTH AS RICH_WIDTH,
			BM_RICH_COLUMN.RICH_HEIGHT AS RICH_HEIGHT,
			COALESCE(CONVERT(NVARCHAR(23), BM_RICH_COLUMN.RICH_BARCODE_TYPE COLLATE ${DAO.CP949}), N'') AS RICH_BARCODE_TYPE,
			BM_RICH_COLUMN.RICH_USE_BARCODE_CHECKDIGIT AS RICH_USE_BARCODE_CHECKDIGIT,
			BM_RICH_COLUMN.RICH_SHOW_BARCODE_NUM AS RICH_SHOW_BARCODE_NUM,
			BM_RICH_COLUMN.RICH_SHOW_QRCODE_TEXT AS RICH_SHOW_QRCODE_TEXT,
			BM_RICH_COLUMN.RICH_QRTEXT_ALIGNMENT AS RICH_QRTEXT_ALIGNMENT,
			BM_RICH_COLUMN.RICH_USE_USER_DEFINE_QRDATA AS RICH_USE_USER_DEFINE_QRDATA,
			COALESCE(CONVERT(NVARCHAR(3000), BM_RICH_COLUMN.RICH_USER_DEFINE_QRDATA COLLATE ${DAO.CP949}), N'') AS RICH_USER_DEFINE_QRDATA,
			COALESCE(CONVERT(NVARCHAR(200), BM_RICH_COLUMN.RICH_USER_DEFINE_QRTEXT COLLATE ${DAO.CP949}), N'') AS RICH_USER_DEFINE_QRTEXT,
			BM_RICH_COLUMN.RICH_PIXELSIZE AS RICH_PIXELSIZE,
			COALESCE(CONVERT(NVARCHAR(20), BM_RICH_COLUMN.RICH_TITLE COLLATE ${DAO.CP949}), N'') AS RICH_TITLE,
			BM_RICH_COLUMN.RICH_VISIBLE AS RICH_VISIBLE,
			BM_RICH_COLUMN.RICH_QRCODE_CREATE_TYPE AS RICH_QRCODE_CREATE_TYPE,
			COALESCE(CONVERT(NVARCHAR(200), BM_RICH_COLUMN.RICH_NATRIUM_JOIN_STRING COLLATE ${DAO.CP949}), N'') AS RICH_NATRIUM_JOIN_STRING,
			BM_RICH_COLUMN.RICH_QRTEXT_FONTSIZE AS RICH_QRTEXT_FONTSIZE,
			COALESCE(CONVERT(NVARCHAR(50), BM_RICH_COLUMN.RICH_QRTEXT_FONTNAME COLLATE ${DAO.CP949}), N'') AS RICH_QRTEXT_FONTNAME,
			BM_RICH_COLUMN.RICH_QRCODE_SCALE AS RICH_QRCODE_SCALE,
			BM_RICH_COLUMN.RICH_TYPE AS RICH_TYPE,
			COALESCE(CONVERT(NVARCHAR(100), BM_RICH_COLUMN.RICH_KEYWORD COLLATE ${DAO.CP949}), N'') AS RICH_KEYWORD,
			COALESCE(CONVERT(NVARCHAR(50), BM_RICH_COLUMN.RICH_COLUMN_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_NAME,
			BM_RICH_COLUMN.RICH_TIMEBARCODE_TYPE AS RICH_TIMEBARCODE_TYPE, 
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC END AS RICH_AUTO_INC,
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC_SIZE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC_SIZE END AS RICH_AUTO_INC_SIZE,
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC_RANGE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC_RANGE END AS RICH_AUTO_INC_RANGE,
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC_SAVE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC_SAVE END AS RICH_AUTO_INC_SAVE,
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC_ZERODEL IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC_ZERODEL END AS RICH_AUTO_INC_ZERODEL,
			CASE WHEN BM_RICH_COLUMN.RICH_SEARCH_PRINT IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_SEARCH_PRINT END AS RICH_SEARCH_PRINT,
			COALESCE(CONVERT(NVARCHAR(200), BM_RICH_COLUMN.RICH_USER_DEFINE_BARCODE_TEXT COLLATE ${DAO.CP949}), N'') AS RICH_USER_DEFINE_BARCODE_TEXT,
			CASE WHEN BM_RICH_COLUMN.RICH_BARCODE_LINE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_BARCODE_LINE END AS RICH_BARCODE_LINE,
			CASE WHEN BM_RICH_COLUMN.RICH_BARCODE_LINE_SIZE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_BARCODE_LINE_SIZE END AS RICH_BARCODE_LINE_SIZE,
			CASE WHEN BM_RICH_COLUMN.RICH_BARCODE_ROTATE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_BARCODE_ROTATE END AS RICH_BARCODE_ROTATE,
			CASE WHEN BM_RICH_COLUMN.RICH_AUTO_INC_UPDATE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_AUTO_INC_UPDATE END AS RICH_AUTO_INC_UPDATE,
			CASE WHEN BM_RICH_COLUMN.RICH_USE_DATERANGE IS NULL THEN 0 ELSE BM_RICH_COLUMN.RICH_USE_DATERANGE END AS RICH_USE_DATERANGE,
			COALESCE(CONVERT(NVARCHAR(12), BM_RICH_COLUMN.RICH_DATERANGE COLLATE ${DAO.CP949}), N'') AS RICH_DATERANGE,
			CASE WHEN BM_RICH_CHECK_COLUMNS.RICH_CHECK_YN IS NULL THEN 0 ELSE BM_RICH_CHECK_COLUMNS.RICH_CHECK_YN END AS RICH_CHECK_YN,
      CASE WHEN BM_RICH_COL_MIN.RICH_MIN_CHECK IS NULL THEN 0 ELSE BM_RICH_COL_MIN.RICH_MIN_CHECK END AS RICH_MIN_CHECK,
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_GS1_CODE IS NULL THEN '01' ELSE BM_GS1_COLUMN_INFO.COLUMN_GS1_CODE END AS COLUMN_GS1_CODE, 
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_GS1_FORMAT_OPTION IS NULL THEN -1 ELSE BM_GS1_COLUMN_INFO.COLUMN_GS1_FORMAT_OPTION END AS COLUMN_GS1_FORMAT_OPTION, 
			CASE WHEN VIEW_BM_GS1_CONTAIN_COLUMN.CONTAIN_COLUMNS_ID IS NULL THEN 0 ELSE 1 END AS USE_GS1_CODE,
			VIEW_BM_GS1_CONTAIN_COLUMN.CONTAIN_COLUMNS_ID AS CONTAIN_COLUMNS_ID, 
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_SHOW_GS1CODE IS NULL THEN 0 ELSE BM_GS1_COLUMN_INFO.COLUMN_SHOW_GS1CODE END AS COLUMN_SHOW_GS1CODE
		FROM BM_RICH_COLUMN  
		LEFT OUTER JOIN BM_RICH_CHECK_COLUMNS  
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = BM_RICH_CHECK_COLUMNS.RICH_COLUMN_ID  
		 AND BM_RICH_COLUMN.RICH_LABELSIZE_ID = BM_RICH_CHECK_COLUMNS.RICH_LABELSIZE_ID 	
    LEFT OUTER JOIN BM_RICH_COL_MIN
      ON BM_RICH_COLUMN.RICH_COLUMN_ID = BM_RICH_COL_MIN.RICH_COLUMN_ID
     AND BM_RICH_COLUMN.RICH_LABELSIZE_ID = BM_RICH_COL_MIN.RICH_LABELSIZE_ID
		LEFT OUTER JOIN BM_GS1_COLUMN_INFO 
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = BM_GS1_COLUMN_INFO.COLUMN_ID 
		LEFT OUTER JOIN VIEW_BM_GS1_CONTAIN_COLUMN 
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = VIEW_BM_GS1_CONTAIN_COLUMN.MAIN_COLUMN_ID 
	''';

  static const String whereSqlByLabelSizeId = '''
		WHERE BM_RICH_COLUMN.RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String orderByColumnOrder = '''
		ORDER BY RICH_COLUMN_ORDER
	''';

  static Future<List<TColumn>?> selectByLabelSizeId(int labelSizeId) async {
    debugLog('$START, labelSizeId:$labelSizeId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlByLabelSizeId $orderByColumnOrder',
        {'labelSizeId': labelSizeId},
      );

      final columns = DAO.mapRows(res, tColumnFromRow);

      debugLog(END);
      return columns;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }

  static Future<List<String>> selectNamesByLabelSizeIds(
    List<int> labelSizeIds,
  ) async {
    final uniqueIds = labelSizeIds.toSet().toList(growable: false);
    if (uniqueIds.isEmpty) return const [];

    final parameters = <String, dynamic>{};
    final placeholders = <String>[];
    for (var index = 0; index < uniqueIds.length; index += 1) {
      final name = 'labelSizeId$index';
      placeholders.add('@$name');
      parameters[name] = uniqueIds[index];
    }
    final sql = '''
SELECT DISTINCT
  COALESCE(CONVERT(NVARCHAR(50), RICH_COLUMN_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_NAME
FROM BM_RICH_COLUMN
WHERE RICH_LABELSIZE_ID IN (${placeholders.join(', ')})
ORDER BY RICH_COLUMN_NAME
''';

    debugLog('$START, labelSizeCount:${uniqueIds.length}');
    try {
      final result = await DbClient.instance.getDataWithParams(sql, parameters);
      final names = DAO.getRowsFromResult(result)
          .map((row) => (row['RICH_COLUMN_NAME'] ?? '').toString())
          .toList(growable: false);
      debugLog(END);
      return names;
    } catch (error) {
      debugLog('$END, $error');
      throw Exception(error);
    }
  }

  static Future<void> updateMinColumnCheck({
    required int labelSizeId,
    required TColumn column,
    required bool checked,
  }) async {
    const sql = '''
MERGE BM_RICH_COL_MIN AS T
USING (
  SELECT
    @labelSizeId AS RICH_LABELSIZE_ID,
    @columnId AS RICH_COLUMN_ID,
    @keyword AS RICH_KEYWORD,
    @columnName AS RICH_COLUMN_NAME,
    @columnOrder AS RICH_COLUMN_ORDER,
    @minCheck AS RICH_MIN_CHECK
) AS S
ON T.RICH_LABELSIZE_ID=S.RICH_LABELSIZE_ID AND T.RICH_COLUMN_ID=S.RICH_COLUMN_ID
WHEN MATCHED THEN
  UPDATE SET T.RICH_KEYWORD=S.RICH_KEYWORD,
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
      'columnId': column.columnId,
      'keyword': column.keyword,
      'columnName': column.columnName,
      'columnOrder': column.order,
      'minCheck': checked ? 1 : 0,
    });
    column.useMinColumnCheck = checked;
  }
}