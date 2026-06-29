// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';
import 'barcode.dart';
import 'column_base.dart';

enum QRTextAlignment {
  ALIGN_LEFT(0),
  ALIGN_CENTER(1),
  ALIGN_RIGHT(2);

  final int code;
  const QRTextAlignment(this.code);
}

enum QRCodeCreateType {
  QRCODE_TYPE_PLAIN_TEXT(0),
  QRCODE_TYPE_USER_DEFINE(1),
  QRCODE_TYPE_NATRIUM(2),
  BARCODE_TEXT_LINK(3);

  final int code;
  const QRCodeCreateType(this.code);
}

class TColumn extends TColumnBase {
  final int columnId;
  final int labelSizeId;
  final int order;
  final int width;
  final int height;
  final BarcodeType barcodeType;
  final bool useBarcodeCheckDigit;
  final bool showBarcodeNum;
  final bool showQRCodeText;
  bool checkMode = false;
  final QRTextAlignment qrTextAlignment;
  final bool useUserDefineQRData;
  final String userDefineQRData; // QR코드 이미지 데이터
  final String userDefineQRText; // QR코드 하단의 문자열
  final int pixelSize;
  final String title;
  final bool visible;
  int editableCellNum = 0; // Column에 속한 Cell 값 중에서 수정가능한 Cell의 갯수
  final QRCodeCreateType qrCodeCreateType;
  final String natriumJoinString;
  final int qrTextFontSize;
  final String qrTextFontName;
  final int qrCodeScalePercent;
  bool newColumnQRCodeInfo = false;
  final int timeBarcodeType;
  int barFontSize = 0;
  final bool autoInc;
  final int autoIncSize;
  final bool autoIncSave;
  final int autoIncRange;
  final bool autoIncZeroDel;
  final bool autoIncUpdate;

  bool modify = false;
  final bool searchPrint;
  final String userDefineBarcodeText;

  bool change = false;
  final int lineCheck;
  final int lineSize;

  final String gs1ai;
  final int formatOption;
  final bool useGS1Code;
  final String containColumns;
  final bool showGS1Code;

  final int rotate;

  final bool useDateRange;
  final String dateRange;

  TColumn({
    required super.columnType,
    required super.keyword,
    required super.columnName,
    required super.useMissingKeywordCheck,
    required this.columnId,
    required this.labelSizeId,
    required this.order,
    required this.width,
    required this.height,
    required this.barcodeType,
    required this.useBarcodeCheckDigit,
    required this.showBarcodeNum,
    required this.showQRCodeText,
    required this.qrTextAlignment,
    required this.useUserDefineQRData,
    required this.userDefineQRData,
    required this.userDefineQRText,
    required this.pixelSize,
    required this.title,
    required this.visible,
    required this.qrCodeCreateType,
    required this.natriumJoinString,
    required this.qrTextFontSize,
    required this.qrTextFontName,
    required this.qrCodeScalePercent,
    required this.timeBarcodeType,
    required this.autoInc,
    required this.autoIncSize,
    required this.autoIncSave,
    required this.autoIncRange,
    required this.autoIncZeroDel,
    required this.autoIncUpdate,
    required this.searchPrint,
    required this.userDefineBarcodeText,
    required this.lineCheck,
    required this.lineSize,
    required this.gs1ai,
    required this.formatOption,
    required this.useGS1Code,
    required this.containColumns,
    required this.showGS1Code,
    required this.rotate,
    required this.useDateRange,
    required this.dateRange,
  });

  // @override
  // String toString() =>
  //   'columnId: $columnId, labelSizeId: $labelSizeId, order: $order, width: $width, height: $height, '
  //   'barcodeType: $barcodeType, useBarcodeCheckDigit: $useBarcodeCheckDigit, showBarcodeNum: $showBarcodeNum, '
  //   'showQRCodeText: $showQRCodeText, checkMode: $checkMode, qrTextAlignment: $qrTextAlignment, '
  //   'useUserDefineQRData: $useUserDefineQRData, userDefineQRData: $userDefineQRData, '
  //   'userDefineQRText: $userDefineQRText, pixelSize: $pixelSize, title: $title, visible: $visible, '
  //   'editableCellNum: $editableCellNum, qrCodeCreateType: $qrCodeCreateType, natriumJoinString: $natriumJoinString, '
  //   'qrTextFontSize: $qrTextFontSize, qrTextFontName: $qrTextFontName, qrCodeScalePercent: $qrCodeScalePercent, '
  //   'newColumnQRCodeInfo: $newColumnQRCodeInfo, timeBarcodeType: $timeBarcodeType, barFontSize: $barFontSize, '
  //   'autoInc: $autoInc, autoIncSize: $autoIncSize, autoIncSave: $autoIncSave, autoIncRange: $autoIncRange, '
  //   'autoIncZeroDel: $autoIncZeroDel, autoIncUpdate: $autoIncUpdate, modify: $modify, searchPrint: $searchPrint, '
  //   'userDefineBarcodeText: $userDefineBarcodeText, change: $change, lineCheck: $lineCheck, lineSize: $lineSize, '
  //   'gs1ai: $gs1ai, formatOption: $formatOption, useGS1Code: $useGS1Code, containColumns: $containColumns, '
  //   'showGS1Code: $showGS1Code, rotate: $rotate, useDateRange: $useDateRange, dateRange: $dateRange';

  factory TColumn.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    dynamic v(String key) => map[key];

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

  static BarcodeType _barcodeTypeFromDb(String dbName) {
    final normalized = dbName.toUpperCase();
    return BarcodeType.values.firstWhere(
      (e) => e.dbName.toUpperCase() == normalized,
      orElse: () => BarcodeType.Code128,
    );
  }

  static QRTextAlignment _qrTextAlignmentFromCode(Object? code) {
    return QRTextAlignment.values.firstWhere(
      (e) => e.code == code,
      orElse: () => QRTextAlignment.ALIGN_LEFT,
    );
  }

  static QRCodeCreateType _qrCodeCreateTypeFromCode(Object? code) {
    return QRCodeCreateType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    );
  }

  static List<TColumn>? datas;

  static void setDatas(List<TColumn>? values) {
    datas = values;
  }
}

class TColumnDAO extends DAO {
  static const String SelectSql =
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
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_GS1_CODE IS NULL THEN '01' ELSE BM_GS1_COLUMN_INFO.COLUMN_GS1_CODE END AS COLUMN_GS1_CODE, 
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_GS1_FORMAT_OPTION IS NULL THEN -1 ELSE BM_GS1_COLUMN_INFO.COLUMN_GS1_FORMAT_OPTION END AS COLUMN_GS1_FORMAT_OPTION, 
			CASE WHEN VIEW_BM_GS1_CONTAIN_COLUMN.CONTAIN_COLUMNS_ID IS NULL THEN 0 ELSE 1 END AS USE_GS1_CODE,
			VIEW_BM_GS1_CONTAIN_COLUMN.CONTAIN_COLUMNS_ID AS CONTAIN_COLUMNS_ID, 
			CASE WHEN BM_GS1_COLUMN_INFO.COLUMN_SHOW_GS1CODE IS NULL THEN 0 ELSE BM_GS1_COLUMN_INFO.COLUMN_SHOW_GS1CODE END AS COLUMN_SHOW_GS1CODE
		FROM BM_RICH_COLUMN  
		LEFT OUTER JOIN BM_RICH_CHECK_COLUMNS  
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = BM_RICH_CHECK_COLUMNS.RICH_COLUMN_ID  
		 AND BM_RICH_COLUMN.RICH_LABELSIZE_ID = BM_RICH_CHECK_COLUMNS.RICH_LABELSIZE_ID 	
		LEFT OUTER JOIN BM_GS1_COLUMN_INFO 
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = BM_GS1_COLUMN_INFO.COLUMN_ID 
		LEFT OUTER JOIN VIEW_BM_GS1_CONTAIN_COLUMN 
		  ON BM_RICH_COLUMN.RICH_COLUMN_ID = VIEW_BM_GS1_CONTAIN_COLUMN.MAIN_COLUMN_ID 
	''';

  static const String WhereSqlByLabelSizeID = '''
		WHERE BM_RICH_COLUMN.RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String OrderByColumnOrder = '''
		ORDER BY RICH_COLUMN_ORDER
	''';

  static Future<List<TColumn>?> getByLabelSizeId(int labelSizeId) async {
    debugLog('$START, labelSizeId:$labelSizeId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlByLabelSizeID $OrderByColumnOrder',
        {'labelSizeId': labelSizeId},
      );

      final columns = DAO.mapRows(res, TColumn.fromMap);

      debugLog(END);
      return columns;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception(e);
    }
  }
}
