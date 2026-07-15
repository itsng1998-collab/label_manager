import 'dart:convert';

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/models/label_column_candidates.dart';
import 'package:label_manager/models/label_column_edit.dart';

class LabelColumnSchemaCapabilities {
  const LabelColumnSchemaCapabilities({
    required this.hasCoreSchema,
    required this.hasMainMissingKeywordCheck,
    required this.hasContentEditable,
    required this.hasUpdateContent,
    required this.hasStatusData,
  });

  final bool hasCoreSchema;
  final bool hasMainMissingKeywordCheck;
  final bool hasContentEditable;
  final bool hasUpdateContent;
  final bool hasStatusData;

  factory LabelColumnSchemaCapabilities.fromResult(Object result) {
    final row = DAO.getRowMapFromResult(result)!;
    bool flag(String key) {
      final value = row[key] ?? row[key.toLowerCase()];
      return value == true || value == 1 || value?.toString() == '1';
    }

    return LabelColumnSchemaCapabilities(
      hasCoreSchema: flag('HAS_CORE_SCHEMA'),
      hasMainMissingKeywordCheck: flag('HAS_MAIN_MISSING_KEYWORD_CHECK'),
      hasContentEditable: flag('HAS_CONTENT_EDITABLE'),
      hasUpdateContent: flag('HAS_UPDATE_CONTENT'),
      hasStatusData: flag('HAS_STATUS_DATA'),
    );
  }
}

abstract final class LabelColumnSaveDao {
  static const String capabilitySql = '''
SELECT
  CASE WHEN OBJECT_ID('dbo.BM_RICH_COLUMN', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_COLUMN_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_LABELSIZE_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_COLUMN_ORDER') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_KEYWORD') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_COLUMN_NAME') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_TYPE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_WIDTH') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_HEIGHT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_BARCODE_TYPE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USE_BARCODE_CHECKDIGIT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_SHOW_BARCODE_NUM') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_SHOW_QRCODE_TEXT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_QRTEXT_ALIGNMENT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USE_USER_DEFINE_QRDATA') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USER_DEFINE_QRDATA') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USER_DEFINE_QRTEXT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_PIXELSIZE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_TITLE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_VISIBLE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_QRCODE_CREATE_TYPE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_NATRIUM_JOIN_STRING') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_QRTEXT_FONTSIZE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_QRTEXT_FONTNAME') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_QRCODE_SCALE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_TIMEBARCODE_TYPE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC_SIZE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC_RANGE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC_SAVE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_SEARCH_PRINT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USER_DEFINE_BARCODE_TEXT') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC_ZERODEL') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_BARCODE_LINE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_BARCODE_LINE_SIZE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_BARCODE_ROTATE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_AUTO_INC_UPDATE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USE_DATERANGE') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_DATERANGE') IS NOT NULL
    AND OBJECT_ID('dbo.BM_RICH_CHECK_COLUMNS', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_CHECK_COLUMNS', 'RICH_CHECK_YN') IS NOT NULL
    AND OBJECT_ID('dbo.BM_RICH_COL_MIN', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COL_MIN', 'RICH_MIN_CHECK') IS NOT NULL
    AND OBJECT_ID('dbo.BM_RICH_ITEM', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_ITEM', 'RICH_ITEM_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_ITEM', 'RICH_LABELSIZE_ID') IS NOT NULL
    AND OBJECT_ID('dbo.BM_RICH_COL_CONTENT', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_COL_CONTENT', 'RICH_COL_CONTENT_DATA') IS NOT NULL
    AND OBJECT_ID('dbo.BM_GS1_COLUMN_INFO', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_GS1_COLUMN_INFO', 'COLUMN_GS1_CODE') IS NOT NULL
    AND OBJECT_ID('dbo.BM_GS1_CONTAIN_COLUMN', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_GS1_CONTAIN_COLUMN', 'MAIN_COLUMN_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_GS1_CONTAIN_COLUMN', 'CONTAIN_COLUMN_ID') IS NOT NULL
    THEN 1 ELSE 0 END AS HAS_CORE_SCHEMA,
  CASE WHEN COL_LENGTH('dbo.BM_RICH_COLUMN', 'RICH_USE_MISSING_KEYWORD_CHECK')
    IS NULL THEN 0 ELSE 1 END AS HAS_MAIN_MISSING_KEYWORD_CHECK,
  CASE WHEN COL_LENGTH('dbo.BM_RICH_COL_CONTENT', 'RICH_EDITABLE')
    IS NULL THEN 0 ELSE 1 END AS HAS_CONTENT_EDITABLE,
  CASE WHEN OBJECT_ID('dbo.BM_UPDATE_ITEM', 'U') IS NOT NULL
    AND OBJECT_ID('dbo.BM_UPDATE_COL_CONTENT', 'U') IS NOT NULL
    AND COL_LENGTH('dbo.BM_UPDATE_ITEM', 'RICH_UPDATE_ITEM_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_UPDATE_ITEM', 'RICH_LABELSIZE_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_UPDATE_COL_CONTENT', 'RICH_COLUMN_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_UPDATE_COL_CONTENT', 'RICH_UPDATE_ITEM_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_UPDATE_COL_CONTENT', 'RICH_COL_CONTENT_DATA') IS NOT NULL
    THEN 1 ELSE 0 END AS HAS_UPDATE_CONTENT,
  CASE WHEN OBJECT_ID('dbo.BM_RICH_STATUS_DATA', 'U')
    IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_STATUS_DATA', 'RICH_COLUMN_ID') IS NOT NULL
    AND COL_LENGTH('dbo.BM_RICH_STATUS_DATA', 'RICH_COLID_CHANGE_DELETE_DATE') IS NOT NULL
    THEN 1 ELSE 0 END AS HAS_STATUS_DATA;
''';

  static const Map<String, String> _columnByChangedKey = {
    'type': 'RICH_TYPE',
    'keyword': 'RICH_KEYWORD',
    'name': 'RICH_COLUMN_NAME',
    'order': 'RICH_COLUMN_ORDER',
    'width': 'RICH_WIDTH',
    'height': 'RICH_HEIGHT',
    'barcodeType': 'RICH_BARCODE_TYPE',
    'checkDigit': 'RICH_USE_BARCODE_CHECKDIGIT',
    'showBarcodeNum': 'RICH_SHOW_BARCODE_NUM',
    'showQRCodeText': 'RICH_SHOW_QRCODE_TEXT',
    'qrTextAlignment': 'RICH_QRTEXT_ALIGNMENT',
    'useUserQrData': 'RICH_USE_USER_DEFINE_QRDATA',
    'userQrData': 'RICH_USER_DEFINE_QRDATA',
    'userQrText': 'RICH_USER_DEFINE_QRTEXT',
    'pixelSize': 'RICH_PIXELSIZE',
    'title': 'RICH_TITLE',
    'visible': 'RICH_VISIBLE',
    'qrCreateType': 'RICH_QRCODE_CREATE_TYPE',
    'natrium': 'RICH_NATRIUM_JOIN_STRING',
    'qrTextSize': 'RICH_QRTEXT_FONTSIZE',
    'qrTextFont': 'RICH_QRTEXT_FONTNAME',
    'qrScale': 'RICH_QRCODE_SCALE',
    'timeBarcodeType': 'RICH_TIMEBARCODE_TYPE',
    'autoInc': 'RICH_AUTO_INC',
    'autoIncSize': 'RICH_AUTO_INC_SIZE',
    'autoIncSave': 'RICH_AUTO_INC_SAVE',
    'autoIncRange': 'RICH_AUTO_INC_RANGE',
    'autoIncZeroDel': 'RICH_AUTO_INC_ZERODEL',
    'autoIncUpdate': 'RICH_AUTO_INC_UPDATE',
    'searchPrint': 'RICH_SEARCH_PRINT',
    'barcodeText': 'RICH_USER_DEFINE_BARCODE_TEXT',
    'lineCheck': 'RICH_BARCODE_LINE',
    'lineSize': 'RICH_BARCODE_LINE_SIZE',
    'rotate': 'RICH_BARCODE_ROTATE',
    'useDateRange': 'RICH_USE_DATERANGE',
    'dateRange': 'RICH_DATERANGE',
  };

  static const String _jsonProjection = '''
DECLARE @LabelSizeId INT = TRY_CONVERT(INT, JSON_VALUE(@commandJson, '\$.labelSizeId'));
IF @LabelSizeId IS NULL OR @LabelSizeId <= 0
  THROW 51100, 'Invalid label size id.', 1;

DECLARE @NewColumns TABLE (
  ROW_NO INT IDENTITY(1,1) PRIMARY KEY, DRAFT_KEY NVARCHAR(100) NOT NULL,
  RICH_COLUMN_NAME NVARCHAR(50) NOT NULL, RICH_KEYWORD NVARCHAR(100) NOT NULL,
  RICH_COLUMN_ORDER INT NOT NULL, RICH_TYPE INT NOT NULL,
  RICH_WIDTH INT NOT NULL, RICH_HEIGHT INT NOT NULL,
  RICH_BARCODE_TYPE NVARCHAR(23) NOT NULL,
  RICH_USE_BARCODE_CHECKDIGIT BIT NOT NULL, RICH_SHOW_BARCODE_NUM BIT NOT NULL,
  RICH_SHOW_QRCODE_TEXT BIT NOT NULL, RICH_QRTEXT_ALIGNMENT INT NOT NULL,
  RICH_USE_USER_DEFINE_QRDATA BIT NOT NULL,
  RICH_USER_DEFINE_QRDATA NVARCHAR(3000) NOT NULL,
  RICH_USER_DEFINE_QRTEXT NVARCHAR(200) NOT NULL, RICH_PIXELSIZE INT NOT NULL,
  RICH_TITLE NVARCHAR(20) NOT NULL, RICH_VISIBLE BIT NOT NULL,
  RICH_QRCODE_CREATE_TYPE INT NOT NULL,
  RICH_NATRIUM_JOIN_STRING NVARCHAR(200) NOT NULL,
  RICH_QRTEXT_FONTSIZE INT NOT NULL, RICH_QRTEXT_FONTNAME NVARCHAR(50) NOT NULL,
  RICH_QRCODE_SCALE INT NOT NULL, RICH_TIMEBARCODE_TYPE INT NOT NULL,
  RICH_AUTO_INC BIT NOT NULL, RICH_AUTO_INC_SIZE INT NOT NULL,
  RICH_AUTO_INC_RANGE INT NOT NULL, RICH_AUTO_INC_SAVE BIT NOT NULL,
  RICH_SEARCH_PRINT BIT NOT NULL, RICH_USER_DEFINE_BARCODE_TEXT NVARCHAR(200) NOT NULL,
  RICH_CHECK_YN BIT NOT NULL, RICH_AUTO_INC_ZERODEL BIT NOT NULL,
  RICH_BARCODE_LINE INT NOT NULL, RICH_BARCODE_LINE_SIZE INT NOT NULL,
  RICH_BARCODE_ROTATE INT NOT NULL, RICH_AUTO_INC_UPDATE BIT NOT NULL,
  RICH_USE_DATERANGE BIT NOT NULL, RICH_DATERANGE NVARCHAR(12) NOT NULL,
  COLUMN_GS1_CODE NVARCHAR(100) NOT NULL, COLUMN_GS1_FORMAT_OPTION INT NOT NULL,
  CONTAIN_COLUMNS NVARCHAR(MAX) NOT NULL, COLUMN_SHOW_GS1CODE BIT NOT NULL
);

INSERT @NewColumns (
  DRAFT_KEY, RICH_COLUMN_NAME, RICH_KEYWORD, RICH_COLUMN_ORDER, RICH_TYPE,
  RICH_WIDTH, RICH_HEIGHT, RICH_BARCODE_TYPE, RICH_USE_BARCODE_CHECKDIGIT,
  RICH_SHOW_BARCODE_NUM, RICH_SHOW_QRCODE_TEXT, RICH_QRTEXT_ALIGNMENT,
  RICH_USE_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRTEXT,
  RICH_PIXELSIZE, RICH_TITLE, RICH_VISIBLE, RICH_QRCODE_CREATE_TYPE,
  RICH_NATRIUM_JOIN_STRING, RICH_QRTEXT_FONTSIZE, RICH_QRTEXT_FONTNAME,
  RICH_QRCODE_SCALE, RICH_TIMEBARCODE_TYPE, RICH_AUTO_INC, RICH_AUTO_INC_SIZE,
  RICH_AUTO_INC_RANGE, RICH_AUTO_INC_SAVE, RICH_SEARCH_PRINT,
  RICH_USER_DEFINE_BARCODE_TEXT, RICH_CHECK_YN, RICH_AUTO_INC_ZERODEL,
  RICH_BARCODE_LINE, RICH_BARCODE_LINE_SIZE, RICH_BARCODE_ROTATE,
  RICH_AUTO_INC_UPDATE, RICH_USE_DATERANGE, RICH_DATERANGE, COLUMN_GS1_CODE,
  COLUMN_GS1_FORMAT_OPTION, CONTAIN_COLUMNS, COLUMN_SHOW_GS1CODE
)
SELECT * FROM OPENJSON(@commandJson, '\$.newColumns') WITH (
  DRAFT_KEY NVARCHAR(100) '\$.draftKey', RICH_COLUMN_NAME NVARCHAR(50) '\$.name',
  RICH_KEYWORD NVARCHAR(100) '\$.keyword', RICH_COLUMN_ORDER INT '\$.order',
  RICH_TYPE INT '\$.type', RICH_WIDTH INT '\$.width', RICH_HEIGHT INT '\$.height',
  RICH_BARCODE_TYPE NVARCHAR(23) '\$.barcodeType',
  RICH_USE_BARCODE_CHECKDIGIT BIT '\$.checkDigit',
  RICH_SHOW_BARCODE_NUM BIT '\$.showBarcodeNum',
  RICH_SHOW_QRCODE_TEXT BIT '\$.showQRCodeText',
  RICH_QRTEXT_ALIGNMENT INT '\$.qrTextAlignment',
  RICH_USE_USER_DEFINE_QRDATA BIT '\$.useUserQrData',
  RICH_USER_DEFINE_QRDATA NVARCHAR(3000) '\$.userQrData',
  RICH_USER_DEFINE_QRTEXT NVARCHAR(200) '\$.userQrText',
  RICH_PIXELSIZE INT '\$.pixelSize', RICH_TITLE NVARCHAR(20) '\$.title',
  RICH_VISIBLE BIT '\$.visible', RICH_QRCODE_CREATE_TYPE INT '\$.qrCreateType',
  RICH_NATRIUM_JOIN_STRING NVARCHAR(200) '\$.natrium',
  RICH_QRTEXT_FONTSIZE INT '\$.qrTextSize',
  RICH_QRTEXT_FONTNAME NVARCHAR(50) '\$.qrTextFont',
  RICH_QRCODE_SCALE INT '\$.qrScale', RICH_TIMEBARCODE_TYPE INT '\$.timeBarcodeType',
  RICH_AUTO_INC BIT '\$.autoInc', RICH_AUTO_INC_SIZE INT '\$.autoIncSize',
  RICH_AUTO_INC_RANGE INT '\$.autoIncRange', RICH_AUTO_INC_SAVE BIT '\$.autoIncSave',
  RICH_SEARCH_PRINT BIT '\$.searchPrint',
  RICH_USER_DEFINE_BARCODE_TEXT NVARCHAR(200) '\$.barcodeText',
  RICH_CHECK_YN BIT '\$.check', RICH_AUTO_INC_ZERODEL BIT '\$.autoIncZeroDel',
  RICH_BARCODE_LINE INT '\$.lineCheck', RICH_BARCODE_LINE_SIZE INT '\$.lineSize',
  RICH_BARCODE_ROTATE INT '\$.rotate', RICH_AUTO_INC_UPDATE BIT '\$.autoIncUpdate',
  RICH_USE_DATERANGE BIT '\$.useDateRange', RICH_DATERANGE NVARCHAR(12) '\$.dateRange',
  COLUMN_GS1_CODE NVARCHAR(100) '\$.gs1ai',
  COLUMN_GS1_FORMAT_OPTION INT '\$.formatOption',
  CONTAIN_COLUMNS NVARCHAR(MAX) '\$.contains',
  COLUMN_SHOW_GS1CODE BIT '\$.showGs1'
);

DECLARE @UpdatedColumns TABLE (
  RICH_COLUMN_ID INT PRIMARY KEY, CHANGED_KEYS NVARCHAR(MAX) NOT NULL,
  RICH_COLUMN_NAME NVARCHAR(50), RICH_KEYWORD NVARCHAR(100), RICH_COLUMN_ORDER INT,
  RICH_TYPE INT, RICH_WIDTH INT, RICH_HEIGHT INT, RICH_BARCODE_TYPE NVARCHAR(23),
  RICH_USE_BARCODE_CHECKDIGIT BIT, RICH_SHOW_BARCODE_NUM BIT,
  RICH_SHOW_QRCODE_TEXT BIT, RICH_QRTEXT_ALIGNMENT INT,
  RICH_USE_USER_DEFINE_QRDATA BIT, RICH_USER_DEFINE_QRDATA NVARCHAR(3000),
  RICH_USER_DEFINE_QRTEXT NVARCHAR(200), RICH_PIXELSIZE INT, RICH_TITLE NVARCHAR(20),
  RICH_VISIBLE BIT, RICH_QRCODE_CREATE_TYPE INT, RICH_NATRIUM_JOIN_STRING NVARCHAR(200),
  RICH_QRTEXT_FONTSIZE INT, RICH_QRTEXT_FONTNAME NVARCHAR(50), RICH_QRCODE_SCALE INT,
  RICH_TIMEBARCODE_TYPE INT, RICH_AUTO_INC BIT, RICH_AUTO_INC_SIZE INT,
  RICH_AUTO_INC_RANGE INT, RICH_AUTO_INC_SAVE BIT, RICH_SEARCH_PRINT BIT,
  RICH_USER_DEFINE_BARCODE_TEXT NVARCHAR(200), RICH_CHECK_YN BIT,
  RICH_AUTO_INC_ZERODEL BIT, RICH_BARCODE_LINE INT, RICH_BARCODE_LINE_SIZE INT,
  RICH_BARCODE_ROTATE INT, RICH_AUTO_INC_UPDATE BIT, RICH_USE_DATERANGE BIT,
  RICH_DATERANGE NVARCHAR(12), COLUMN_GS1_CODE NVARCHAR(100),
  COLUMN_GS1_FORMAT_OPTION INT, CONTAIN_COLUMNS NVARCHAR(MAX), COLUMN_SHOW_GS1CODE BIT
);
INSERT @UpdatedColumns
SELECT * FROM OPENJSON(@commandJson, '\$.updatedColumns') WITH (
  RICH_COLUMN_ID INT '\$.columnId', CHANGED_KEYS NVARCHAR(MAX) '\$.changedKeys' AS JSON,
  RICH_COLUMN_NAME NVARCHAR(50) '\$.name', RICH_KEYWORD NVARCHAR(100) '\$.keyword',
  RICH_COLUMN_ORDER INT '\$.order', RICH_TYPE INT '\$.type', RICH_WIDTH INT '\$.width',
  RICH_HEIGHT INT '\$.height', RICH_BARCODE_TYPE NVARCHAR(23) '\$.barcodeType',
  RICH_USE_BARCODE_CHECKDIGIT BIT '\$.checkDigit', RICH_SHOW_BARCODE_NUM BIT '\$.showBarcodeNum',
  RICH_SHOW_QRCODE_TEXT BIT '\$.showQRCodeText', RICH_QRTEXT_ALIGNMENT INT '\$.qrTextAlignment',
  RICH_USE_USER_DEFINE_QRDATA BIT '\$.useUserQrData',
  RICH_USER_DEFINE_QRDATA NVARCHAR(3000) '\$.userQrData',
  RICH_USER_DEFINE_QRTEXT NVARCHAR(200) '\$.userQrText', RICH_PIXELSIZE INT '\$.pixelSize',
  RICH_TITLE NVARCHAR(20) '\$.title', RICH_VISIBLE BIT '\$.visible',
  RICH_QRCODE_CREATE_TYPE INT '\$.qrCreateType',
  RICH_NATRIUM_JOIN_STRING NVARCHAR(200) '\$.natrium',
  RICH_QRTEXT_FONTSIZE INT '\$.qrTextSize', RICH_QRTEXT_FONTNAME NVARCHAR(50) '\$.qrTextFont',
  RICH_QRCODE_SCALE INT '\$.qrScale', RICH_TIMEBARCODE_TYPE INT '\$.timeBarcodeType',
  RICH_AUTO_INC BIT '\$.autoInc', RICH_AUTO_INC_SIZE INT '\$.autoIncSize',
  RICH_AUTO_INC_RANGE INT '\$.autoIncRange', RICH_AUTO_INC_SAVE BIT '\$.autoIncSave',
  RICH_SEARCH_PRINT BIT '\$.searchPrint',
  RICH_USER_DEFINE_BARCODE_TEXT NVARCHAR(200) '\$.barcodeText', RICH_CHECK_YN BIT '\$.check',
  RICH_AUTO_INC_ZERODEL BIT '\$.autoIncZeroDel', RICH_BARCODE_LINE INT '\$.lineCheck',
  RICH_BARCODE_LINE_SIZE INT '\$.lineSize', RICH_BARCODE_ROTATE INT '\$.rotate',
  RICH_AUTO_INC_UPDATE BIT '\$.autoIncUpdate', RICH_USE_DATERANGE BIT '\$.useDateRange',
  RICH_DATERANGE NVARCHAR(12) '\$.dateRange', COLUMN_GS1_CODE NVARCHAR(100) '\$.gs1ai',
  COLUMN_GS1_FORMAT_OPTION INT '\$.formatOption', CONTAIN_COLUMNS NVARCHAR(MAX) '\$.contains',
  COLUMN_SHOW_GS1CODE BIT '\$.showGs1'
);

DECLARE @DeletedColumns TABLE (RICH_COLUMN_ID INT PRIMARY KEY);
INSERT @DeletedColumns SELECT VALUE FROM OPENJSON(@commandJson, '\$.deletedColumnIds');
DECLARE @FinalOrder TABLE (
  DRAFT_KEY NVARCHAR(100), RICH_COLUMN_ID INT, RICH_COLUMN_ORDER INT NOT NULL UNIQUE
);
INSERT @FinalOrder
SELECT DRAFT_KEY, RICH_COLUMN_ID, RICH_COLUMN_ORDER
FROM OPENJSON(@commandJson, '\$.finalOrder') WITH (
  DRAFT_KEY NVARCHAR(100) '\$.draftKey', RICH_COLUMN_ID INT '\$.columnId',
  RICH_COLUMN_ORDER INT '\$.order'
);

IF EXISTS (
  SELECT 1 FROM (
    SELECT RICH_COLUMN_ID FROM @UpdatedColumns
    UNION ALL SELECT RICH_COLUMN_ID FROM @DeletedColumns
  ) T LEFT JOIN BM_RICH_COLUMN C ON C.RICH_COLUMN_ID=T.RICH_COLUMN_ID
    AND C.RICH_LABELSIZE_ID=@LabelSizeId
  WHERE C.RICH_COLUMN_ID IS NULL
) THROW 51101, 'Column ownership validation failed.', 1;
''';

  static String _insertSql(bool hasMainMissingKeywordCheck) {
    final optionalColumn = hasMainMissingKeywordCheck
        ? ', RICH_USE_MISSING_KEYWORD_CHECK'
        : '';
    final optionalValue = hasMainMissingKeywordCheck ? ', @Check' : '';
    return '''
DECLARE @InsertedRows TABLE (DRAFT_KEY NVARCHAR(100) PRIMARY KEY, COLUMN_ID INT UNIQUE);
DECLARE @OneInserted TABLE (COLUMN_ID INT);
DECLARE @RowNo INT = 1, @RowCount INT = (SELECT COUNT(*) FROM @NewColumns);
WHILE @RowNo <= @RowCount
BEGIN
  DECLARE @DraftKey NVARCHAR(100), @Check BIT;
  SELECT @DraftKey=DRAFT_KEY, @Check=RICH_CHECK_YN FROM @NewColumns WHERE ROW_NO=@RowNo;
  DELETE FROM @OneInserted;
  INSERT BM_RICH_COLUMN (
    RICH_LABELSIZE_ID, RICH_COLUMN_NAME, RICH_KEYWORD, RICH_COLUMN_ORDER, RICH_TYPE,
    RICH_WIDTH, RICH_HEIGHT, RICH_BARCODE_TYPE, RICH_USE_BARCODE_CHECKDIGIT,
    RICH_SHOW_BARCODE_NUM, RICH_SHOW_QRCODE_TEXT, RICH_QRTEXT_ALIGNMENT,
    RICH_USE_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRTEXT,
    RICH_PIXELSIZE, RICH_TITLE, RICH_VISIBLE, RICH_QRCODE_CREATE_TYPE,
    RICH_NATRIUM_JOIN_STRING, RICH_QRTEXT_FONTSIZE, RICH_QRTEXT_FONTNAME,
    RICH_QRCODE_SCALE, RICH_TIMEBARCODE_TYPE, RICH_AUTO_INC, RICH_AUTO_INC_SIZE,
    RICH_AUTO_INC_RANGE, RICH_AUTO_INC_SAVE, RICH_SEARCH_PRINT,
    RICH_USER_DEFINE_BARCODE_TEXT, RICH_AUTO_INC_ZERODEL, RICH_BARCODE_LINE,
    RICH_BARCODE_LINE_SIZE, RICH_BARCODE_ROTATE, RICH_AUTO_INC_UPDATE,
    RICH_USE_DATERANGE, RICH_DATERANGE$optionalColumn
  ) OUTPUT INSERTED.RICH_COLUMN_ID INTO @OneInserted
  SELECT @LabelSizeId, RICH_COLUMN_NAME, RICH_KEYWORD, RICH_COLUMN_ORDER, RICH_TYPE,
    RICH_WIDTH, RICH_HEIGHT, RICH_BARCODE_TYPE, RICH_USE_BARCODE_CHECKDIGIT,
    RICH_SHOW_BARCODE_NUM, RICH_SHOW_QRCODE_TEXT, RICH_QRTEXT_ALIGNMENT,
    RICH_USE_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRTEXT,
    RICH_PIXELSIZE, RICH_TITLE, RICH_VISIBLE, RICH_QRCODE_CREATE_TYPE,
    RICH_NATRIUM_JOIN_STRING, RICH_QRTEXT_FONTSIZE, RICH_QRTEXT_FONTNAME,
    RICH_QRCODE_SCALE, RICH_TIMEBARCODE_TYPE, RICH_AUTO_INC, RICH_AUTO_INC_SIZE,
    RICH_AUTO_INC_RANGE, RICH_AUTO_INC_SAVE, RICH_SEARCH_PRINT,
    RICH_USER_DEFINE_BARCODE_TEXT, RICH_AUTO_INC_ZERODEL, RICH_BARCODE_LINE,
    RICH_BARCODE_LINE_SIZE, RICH_BARCODE_ROTATE, RICH_AUTO_INC_UPDATE,
    RICH_USE_DATERANGE, RICH_DATERANGE$optionalValue
  FROM @NewColumns WHERE ROW_NO=@RowNo;
  IF @@ROWCOUNT <> 1 OR (SELECT COUNT(*) FROM @OneInserted) <> 1
    THROW 51102, 'Inserted column count mismatch.', 1;
  INSERT @InsertedRows SELECT @DraftKey, COLUMN_ID FROM @OneInserted;
  SET @RowNo += 1;
END;
IF (SELECT COUNT(*) FROM @InsertedRows) <> @RowCount
  THROW 51103, 'Inserted column mapping count mismatch.', 1;
''';
  }

  static String get _mainUpdates {
    final buffer = StringBuffer();
    for (final entry in _columnByChangedKey.entries) {
      buffer.writeln('''
UPDATE C SET ${entry.value}=U.${entry.value}
FROM BM_RICH_COLUMN C JOIN @UpdatedColumns U ON U.RICH_COLUMN_ID=C.RICH_COLUMN_ID
WHERE EXISTS (SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE='${entry.key}');
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @UpdatedColumns U
  WHERE EXISTS (SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE='${entry.key}'))
  THROW 51104, 'Updated column count mismatch.', 1;''');
    }
    return buffer.toString();
  }

  static String _optionalMainCheckUpdate(bool enabled) => enabled
      ? '''
UPDATE C SET RICH_USE_MISSING_KEYWORD_CHECK=U.RICH_CHECK_YN
FROM BM_RICH_COLUMN C JOIN @UpdatedColumns U ON U.RICH_COLUMN_ID=C.RICH_COLUMN_ID
WHERE EXISTS (SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE='check');
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @UpdatedColumns U
  WHERE EXISTS (SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE='check'))
  THROW 51105, 'Missing-keyword update count mismatch.', 1;
'''
      : '';

  static const String _checkAndMinSql = '''
INSERT BM_RICH_COL_MIN (
  RICH_COLUMN_ID, RICH_LABELSIZE_ID, RICH_KEYWORD, RICH_COLUMN_NAME,
  RICH_COLUMN_ORDER, RICH_MIN_CHECK
)
SELECT 0, @LabelSizeId, 'ELEMENT', N'주원료', 0, 0
WHERE NOT EXISTS (SELECT 1 FROM BM_RICH_COL_MIN
  WHERE RICH_LABELSIZE_ID=@LabelSizeId AND RICH_COLUMN_ID=0);

INSERT BM_RICH_CHECK_COLUMNS (
  RICH_LABELSIZE_ID, RICH_COLUMN_ID, RICH_KEYWORD, RICH_COLUMN_NAME, RICH_CHECK_YN
)
SELECT @LabelSizeId, I.COLUMN_ID, N.RICH_KEYWORD, N.RICH_COLUMN_NAME, N.RICH_CHECK_YN
FROM @NewColumns N JOIN @InsertedRows I ON I.DRAFT_KEY=N.DRAFT_KEY;
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @NewColumns)
  THROW 51106, 'Inserted check-column count mismatch.', 1;

INSERT BM_RICH_COL_MIN (
  RICH_COLUMN_ID, RICH_LABELSIZE_ID, RICH_KEYWORD, RICH_COLUMN_NAME,
  RICH_COLUMN_ORDER, RICH_MIN_CHECK
)
SELECT I.COLUMN_ID, @LabelSizeId, N.RICH_KEYWORD, N.RICH_COLUMN_NAME,
  N.RICH_COLUMN_ORDER, 0
FROM @NewColumns N JOIN @InsertedRows I ON I.DRAFT_KEY=N.DRAFT_KEY;
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @NewColumns)
  THROW 51107, 'Inserted minimum-column count mismatch.', 1;

MERGE BM_RICH_CHECK_COLUMNS AS T
USING (
  SELECT * FROM @UpdatedColumns U WHERE EXISTS (
    SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE IN ('keyword','name','check')
  )
) S ON T.RICH_LABELSIZE_ID=@LabelSizeId AND T.RICH_COLUMN_ID=S.RICH_COLUMN_ID
WHEN MATCHED THEN UPDATE SET T.RICH_KEYWORD=S.RICH_KEYWORD,
  T.RICH_COLUMN_NAME=S.RICH_COLUMN_NAME, T.RICH_CHECK_YN=S.RICH_CHECK_YN
WHEN NOT MATCHED THEN INSERT (
  RICH_LABELSIZE_ID, RICH_COLUMN_ID, RICH_KEYWORD, RICH_COLUMN_NAME, RICH_CHECK_YN
) VALUES (@LabelSizeId, S.RICH_COLUMN_ID, S.RICH_KEYWORD, S.RICH_COLUMN_NAME, S.RICH_CHECK_YN);

MERGE BM_RICH_COL_MIN AS T
USING (
  SELECT * FROM @UpdatedColumns U WHERE EXISTS (
    SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K WHERE K.VALUE IN ('keyword','name','order')
  )
) S ON T.RICH_LABELSIZE_ID=@LabelSizeId AND T.RICH_COLUMN_ID=S.RICH_COLUMN_ID
WHEN MATCHED THEN UPDATE SET T.RICH_KEYWORD=S.RICH_KEYWORD,
  T.RICH_COLUMN_NAME=S.RICH_COLUMN_NAME, T.RICH_COLUMN_ORDER=S.RICH_COLUMN_ORDER
WHEN NOT MATCHED THEN INSERT (
  RICH_COLUMN_ID, RICH_LABELSIZE_ID, RICH_KEYWORD, RICH_COLUMN_NAME,
  RICH_COLUMN_ORDER, RICH_MIN_CHECK
) VALUES (S.RICH_COLUMN_ID, @LabelSizeId, S.RICH_KEYWORD, S.RICH_COLUMN_NAME,
  S.RICH_COLUMN_ORDER, 0);
''';

  static String _contentInsert(bool editable) => editable
      ? '''
INSERT BM_RICH_COL_CONTENT (
  RICH_COLUMN_ID, RICH_ITEM_ID, RICH_EDITABLE, RICH_COL_CONTENT_DATA
)
SELECT M.COLUMN_ID, I.RICH_ITEM_ID, 0, '' FROM @InsertedRows M
CROSS JOIN BM_RICH_ITEM I
WHERE I.RICH_LABELSIZE_ID=@LabelSizeId AND NOT EXISTS (
  SELECT 1 FROM BM_RICH_COL_CONTENT C
  WHERE C.RICH_COLUMN_ID=M.COLUMN_ID AND C.RICH_ITEM_ID=I.RICH_ITEM_ID
);
'''
      : '''
INSERT BM_RICH_COL_CONTENT (RICH_COLUMN_ID, RICH_ITEM_ID, RICH_COL_CONTENT_DATA)
SELECT M.COLUMN_ID, I.RICH_ITEM_ID, '' FROM @InsertedRows M
CROSS JOIN BM_RICH_ITEM I
WHERE I.RICH_LABELSIZE_ID=@LabelSizeId AND NOT EXISTS (
  SELECT 1 FROM BM_RICH_COL_CONTENT C
  WHERE C.RICH_COLUMN_ID=M.COLUMN_ID AND C.RICH_ITEM_ID=I.RICH_ITEM_ID
);
''';

  static String _updateContent(bool enabled) => enabled
      ? '''
INSERT BM_UPDATE_COL_CONTENT (
  RICH_COLUMN_ID, RICH_UPDATE_ITEM_ID, RICH_COL_CONTENT_DATA
)
SELECT M.COLUMN_ID, I.RICH_UPDATE_ITEM_ID, '' FROM @InsertedRows M
CROSS JOIN BM_UPDATE_ITEM I
WHERE I.RICH_LABELSIZE_ID=@LabelSizeId AND NOT EXISTS (
  SELECT 1 FROM BM_UPDATE_COL_CONTENT C
  WHERE C.RICH_COLUMN_ID=M.COLUMN_ID
    AND C.RICH_UPDATE_ITEM_ID=I.RICH_UPDATE_ITEM_ID
);
'''
      : '';

  static const String _gs1Sql = '''
DECLARE @TouchedColumns TABLE (
  COLUMN_ID INT PRIMARY KEY, RICH_TYPE INT, COLUMN_GS1_CODE NVARCHAR(100),
  COLUMN_GS1_FORMAT_OPTION INT, CONTAIN_COLUMNS NVARCHAR(MAX), COLUMN_SHOW_GS1CODE BIT
);
INSERT @TouchedColumns
SELECT I.COLUMN_ID, N.RICH_TYPE, N.COLUMN_GS1_CODE, N.COLUMN_GS1_FORMAT_OPTION,
  N.CONTAIN_COLUMNS, N.COLUMN_SHOW_GS1CODE
FROM @NewColumns N JOIN @InsertedRows I ON I.DRAFT_KEY=N.DRAFT_KEY
UNION ALL
SELECT RICH_COLUMN_ID, RICH_TYPE, COLUMN_GS1_CODE, COLUMN_GS1_FORMAT_OPTION,
  CONTAIN_COLUMNS, COLUMN_SHOW_GS1CODE FROM @UpdatedColumns U
WHERE EXISTS (
  SELECT 1 FROM OPENJSON(U.CHANGED_KEYS) K
  WHERE K.VALUE IN ('type','gs1ai','formatOption','contains','showGs1')
);

DELETE G FROM BM_GS1_COLUMN_INFO G JOIN @TouchedColumns T ON T.COLUMN_ID=G.COLUMN_ID
WHERE T.RICH_TYPE<>${TColumnType.TYPE_GS1_AI};
MERGE BM_GS1_COLUMN_INFO AS G
USING (SELECT * FROM @TouchedColumns WHERE RICH_TYPE=${TColumnType.TYPE_GS1_AI}) T
ON G.COLUMN_ID=T.COLUMN_ID
WHEN MATCHED THEN UPDATE SET COLUMN_GS1_CODE=T.COLUMN_GS1_CODE,
  COLUMN_GS1_FORMAT_OPTION=T.COLUMN_GS1_FORMAT_OPTION,
  COLUMN_SHOW_GS1CODE=T.COLUMN_SHOW_GS1CODE
WHEN NOT MATCHED THEN INSERT (
  COLUMN_ID, COLUMN_GS1_CODE, COLUMN_GS1_FORMAT_OPTION, COLUMN_SHOW_GS1CODE
) VALUES (T.COLUMN_ID, T.COLUMN_GS1_CODE, T.COLUMN_GS1_FORMAT_OPTION,
  T.COLUMN_SHOW_GS1CODE);

DELETE G FROM BM_GS1_CONTAIN_COLUMN G
JOIN @TouchedColumns T ON T.COLUMN_ID=G.MAIN_COLUMN_ID;
INSERT BM_GS1_CONTAIN_COLUMN (MAIN_COLUMN_ID, CONTAIN_COLUMN_ID)
SELECT T.COLUMN_ID, COALESCE(NM.COLUMN_ID, C.RICH_COLUMN_ID)
FROM @TouchedColumns T
CROSS APPLY STRING_SPLIT(T.CONTAIN_COLUMNS, '|') S
OUTER APPLY (
  SELECT I.COLUMN_ID FROM @InsertedRows I
  JOIN @NewColumns N ON N.DRAFT_KEY=I.DRAFT_KEY
  WHERE S.VALUE LIKE '#%' AND N.RICH_KEYWORD=SUBSTRING(S.VALUE, 2, 100)
    AND N.RICH_TYPE=${TColumnType.TYPE_GS1_AI}
) NM
LEFT JOIN BM_RICH_COLUMN C ON C.RICH_LABELSIZE_ID=@LabelSizeId
  AND ((S.VALUE LIKE '#%' AND C.RICH_KEYWORD=SUBSTRING(S.VALUE, 2, 100))
    OR C.RICH_COLUMN_ID=TRY_CONVERT(INT, S.VALUE))
  AND C.RICH_TYPE=${TColumnType.TYPE_GS1_AI}
WHERE T.RICH_TYPE=${TColumnType.TYPE_GS1_BARCODE} AND S.VALUE<>''
  AND COALESCE(NM.COLUMN_ID, C.RICH_COLUMN_ID) IS NOT NULL;
IF EXISTS (
  SELECT T.COLUMN_ID FROM @TouchedColumns T
  CROSS APPLY STRING_SPLIT(T.CONTAIN_COLUMNS, '|') S
  WHERE T.RICH_TYPE=${TColumnType.TYPE_GS1_BARCODE} AND S.VALUE<>''
  GROUP BY T.COLUMN_ID
  HAVING COUNT(*)<>(SELECT COUNT(*) FROM BM_GS1_CONTAIN_COLUMN G
    WHERE G.MAIN_COLUMN_ID=T.COLUMN_ID)
) THROW 51108, 'GS1 contain mapping failed.', 1;
''';

  static String _deleteOptionalSql({
    required bool updateContent,
    required bool statusData,
  }) => '''
${updateContent ? 'DELETE U FROM BM_UPDATE_COL_CONTENT U JOIN @DeletedColumns D ON D.RICH_COLUMN_ID=U.RICH_COLUMN_ID;' : ''}
${statusData ? 'UPDATE S SET RICH_COLID_CHANGE_DELETE_DATE=GETDATE() FROM BM_RICH_STATUS_DATA S JOIN @DeletedColumns D ON D.RICH_COLUMN_ID=S.RICH_COLUMN_ID;' : ''}
''';

  static const String _deleteAndOrderSql = '''
DELETE C FROM BM_RICH_COL_CONTENT C JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=C.RICH_COLUMN_ID;
DELETE C FROM BM_RICH_CHECK_COLUMNS C JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=C.RICH_COLUMN_ID;
DELETE C FROM BM_RICH_COL_MIN C JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=C.RICH_COLUMN_ID;
DELETE G FROM BM_GS1_COLUMN_INFO G JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=G.COLUMN_ID;
DELETE G FROM BM_GS1_CONTAIN_COLUMN G JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=G.MAIN_COLUMN_ID OR D.RICH_COLUMN_ID=G.CONTAIN_COLUMN_ID;
DELETE C FROM BM_RICH_COLUMN C JOIN @DeletedColumns D
  ON D.RICH_COLUMN_ID=C.RICH_COLUMN_ID WHERE C.RICH_LABELSIZE_ID=@LabelSizeId;
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @DeletedColumns)
  THROW 51109, 'Deleted column count mismatch.', 1;

UPDATE O SET RICH_COLUMN_ID=I.COLUMN_ID
FROM @FinalOrder O JOIN @InsertedRows I ON I.DRAFT_KEY=O.DRAFT_KEY
WHERE O.RICH_COLUMN_ID IS NULL;
IF EXISTS (SELECT 1 FROM @FinalOrder WHERE RICH_COLUMN_ID IS NULL)
  THROW 51110, 'Final order mapping failed.', 1;
IF (SELECT COUNT(*) FROM @FinalOrder) > 0 AND (
  (SELECT MIN(RICH_COLUMN_ORDER) FROM @FinalOrder)<>1 OR
  (SELECT MAX(RICH_COLUMN_ORDER) FROM @FinalOrder)<>(SELECT COUNT(*) FROM @FinalOrder)
) THROW 51111, 'Final column order is not continuous.', 1;
UPDATE C SET RICH_COLUMN_ORDER=O.RICH_COLUMN_ORDER
FROM BM_RICH_COLUMN C JOIN @FinalOrder O ON O.RICH_COLUMN_ID=C.RICH_COLUMN_ID
WHERE C.RICH_LABELSIZE_ID=@LabelSizeId;
IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @FinalOrder)
  THROW 51112, 'Final column order count mismatch.', 1;
UPDATE M SET RICH_COLUMN_ORDER=O.RICH_COLUMN_ORDER
FROM BM_RICH_COL_MIN M JOIN @FinalOrder O ON O.RICH_COLUMN_ID=M.RICH_COLUMN_ID
WHERE M.RICH_LABELSIZE_ID=@LabelSizeId;

IF EXISTS (SELECT DRAFT_KEY FROM @InsertedRows GROUP BY DRAFT_KEY HAVING COUNT(*)<>1)
  THROW 51113, 'Duplicate inserted column mapping.', 1;
IF (SELECT COUNT(*) FROM @InsertedRows)<>(SELECT COUNT(*) FROM @NewColumns)
  THROW 51114, 'Inserted column mapping count mismatch.', 1;
SELECT DRAFT_KEY, COLUMN_ID FROM @InsertedRows ORDER BY DRAFT_KEY;
''';

  static DbTransactionStatement buildSaveStatement(
    LabelColumnSaveCommand command,
    LabelColumnSchemaCapabilities capabilities,
  ) {
    if (!capabilities.hasCoreSchema) {
      throw StateError('Required label column schema is not supported.');
    }
    _validateCommand(command);
    final sql = StringBuffer()
      ..write(_jsonProjection)
      ..write(_insertSql(capabilities.hasMainMissingKeywordCheck))
      ..write(_mainUpdates)
      ..write(_optionalMainCheckUpdate(capabilities.hasMainMissingKeywordCheck))
      ..write(_checkAndMinSql)
      ..write(_contentInsert(capabilities.hasContentEditable))
      ..write(_updateContent(capabilities.hasUpdateContent))
      ..write(_gs1Sql)
      ..write(
        _deleteOptionalSql(
          updateContent: capabilities.hasUpdateContent,
          statusData: capabilities.hasStatusData,
        ),
      )
      ..write(_deleteAndOrderSql);
    return DbTransactionStatement(
      sql: sql.toString(),
      params: {'commandJson': jsonEncode(_commandJson(command))},
      returnsRows: true,
    );
  }

  static LabelColumnSaveResult decodeSaveResult(
    Object result, {
    required int expectedMappingCount,
  }) {
    final mapping = <String, int>{};
    final mappedIds = <int>{};
    for (final raw in DAO.getRowsFromResult(result)) {
      final row = raw as Map<String, dynamic>;
      final key = (row['DRAFT_KEY'] ?? row['draft_key']).toString();
      final id = int.parse((row['COLUMN_ID'] ?? row['column_id']).toString());
      if (mapping.containsKey(key) || !mappedIds.add(id)) {
        throw StateError('Duplicate inserted column mapping: $key / $id');
      }
      mapping[key] = id;
    }
    if (mapping.length != expectedMappingCount) {
      throw StateError('Inserted column mapping count mismatch.');
    }
    return LabelColumnSaveResult(Map.unmodifiable(mapping));
  }

  static Future<LabelColumnSaveResult> save(
    LabelColumnSaveCommand command,
  ) async {
    final capabilityResult = await DbClient.instance.getData(capabilitySql);
    final capabilities = LabelColumnSchemaCapabilities.fromResult(
      capabilityResult,
    );
    final results = await DbClient.instance.transaction([
      buildSaveStatement(command, capabilities),
    ]);
    return decodeSaveResult(
      results.single,
      expectedMappingCount: command.newColumns.length,
    );
  }

  static Future<void> saveDialog(LabelColumnDialogSaveCommand command) async {
    LabelColumnSchemaCapabilities? capabilities;
    final labelCommand = command.labelColumns;
    if (labelCommand != null) {
      final capabilityResult = await DbClient.instance.getData(capabilitySql);
      capabilities = LabelColumnSchemaCapabilities.fromResult(
        capabilityResult,
      );
    }
    final statements = buildDialogSaveStatements(command, capabilities);
    final results = await DbClient.instance.transaction(statements);
    if (labelCommand != null) {
      try {
        decodeSaveResult(
          results.first,
          expectedMappingCount: labelCommand.newColumns.length,
        );
      } catch (error) {
        throw LabelColumnSaveCommittedException(
          '저장은 완료됐지만 신규 항목 결과를 확인하지 못했습니다. '
          '중복 저장을 막기 위해 다이얼로그를 닫고 최신 정보를 다시 불러오세요.\n$error',
        );
      }
    }
  }

  static List<DbTransactionStatement> buildDialogSaveStatements(
    LabelColumnDialogSaveCommand command,
    LabelColumnSchemaCapabilities? capabilities,
  ) {
    if (command.labelSizeId <= 0 || command.customerId <= 0) {
      throw ArgumentError('Invalid dialog save context.');
    }
    final statements = <DbTransactionStatement>[];
    final labelCommand = command.labelColumns;
    if (labelCommand != null) {
      if (labelCommand.labelSizeId != command.labelSizeId) {
        throw StateError('Label column save context mismatch.');
      }
      if (capabilities == null) {
        throw ArgumentError.notNull('capabilities');
      }
      statements.add(buildSaveStatement(labelCommand, capabilities));
    }
    final customerCommand = command.customerColumns;
    if (customerCommand != null) {
      if (customerCommand.customerId != command.customerId) {
        throw StateError('Customer column save context mismatch.');
      }
      statements.add(CustomerColumnDAO.buildSaveStatement(customerCommand));
    }
    return List.unmodifiable(statements);
  }

  static Map<String, Object?> _commandJson(LabelColumnSaveCommand command) {
    final updatedById = {
      for (final draft in command.updatedColumns) draft.column.columnId: draft,
    };
    final newKeys = {for (final draft in command.newColumns) draft.key};
    return {
      'labelSizeId': command.labelSizeId,
      'newColumns': [for (final draft in command.newColumns) _draftJson(draft)],
      'updatedColumns': [
        for (final entry in command.changedKeysByColumnId.entries)
          {
            ..._draftJson(updatedById[entry.key]!),
            'changedKeys': entry.value.toList()..sort(),
          },
      ],
      'deletedColumnIds': command.deletedColumnIds.toList()..sort(),
      'finalOrder': [
        for (var index = 0; index < command.orderedKeys.length; index += 1)
          {
            'draftKey': newKeys.contains(command.orderedKeys[index])
                ? command.orderedKeys[index]
                : null,
            'columnId': newKeys.contains(command.orderedKeys[index])
              ? null
              : command.orderedKeys[index].startsWith('column:')
                ? int.parse(command.orderedKeys[index].substring(7))
                : null,
            'order': index + 1,
          },
      ],
    };
  }

  static Map<String, Object?> _draftJson(LabelColumnDraft draft) => {
    'draftKey': draft.key,
    'columnId': draft.column.columnId,
    ...draft.persistedValues,
  };

  static void _validateCommand(LabelColumnSaveCommand command) {
    if (command.labelSizeId <= 0) {
      throw ArgumentError.value(command.labelSizeId, 'labelSizeId');
    }
    final newKeys = <String>{};
    for (final draft in command.newColumns) {
      if (!draft.isNew ||
          draft.column.labelSizeId != command.labelSizeId ||
          !newKeys.add(draft.key)) {
        throw StateError('Invalid or duplicate new column draft.');
      }
    }
    final updatedIds = <int>{};
    for (final draft in command.updatedColumns) {
      final id = draft.column.columnId;
      if (draft.isNew ||
          draft.column.labelSizeId != command.labelSizeId ||
          !updatedIds.add(id)) {
        throw StateError('Invalid or duplicate updated column.');
      }
    }
    if (updatedIds.length != command.changedKeysByColumnId.length ||
        !updatedIds.containsAll(command.changedKeysByColumnId.keys)) {
      throw StateError('Updated column change keys do not match rows.');
    }
    const auxiliaryKeys = {'check', 'gs1ai', 'formatOption', 'contains', 'showGs1'};
    final supportedKeys = {..._columnByChangedKey.keys, ...auxiliaryKeys};
    for (final entry in command.changedKeysByColumnId.entries) {
      if (entry.value.isEmpty || !supportedKeys.containsAll(entry.value)) {
        throw StateError('Unsupported changed property key for column ${entry.key}.');
      }
    }
    if (command.deletedColumnIds.any(updatedIds.contains)) {
      throw StateError('A column cannot be updated and deleted together.');
    }
    if (command.orderedKeys.toSet().length != command.orderedKeys.length ||
        !command.orderedKeys.toSet().containsAll(newKeys) ||
        command.orderedKeys.any(
          (key) => !newKeys.contains(key) && !key.startsWith('column:'),
        ) ||
        command.deletedColumnIds.any(
          (id) => command.orderedKeys.contains('column:$id'),
        )) {
      throw StateError('Final column order identities are invalid.');
    }
  }
}
