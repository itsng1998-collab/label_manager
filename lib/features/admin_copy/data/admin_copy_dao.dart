import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/admin_copy/domain/admin_copy.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/regression_debug_log.dart';

class AdminCopyDAO extends DAO {
  static const String _columnNames = '''
    RICH_LABELSIZE_ID, RICH_COLUMN_NAME, RICH_KEYWORD,
    RICH_COLUMN_ORDER, RICH_TYPE, RICH_WIDTH, RICH_HEIGHT,
    RICH_BARCODE_TYPE, RICH_USE_BARCODE_CHECKDIGIT,
    RICH_SHOW_BARCODE_NUM, RICH_SHOW_QRCODE_TEXT,
    RICH_QRTEXT_ALIGNMENT, RICH_USE_USER_DEFINE_QRDATA,
    RICH_USER_DEFINE_QRDATA, RICH_USER_DEFINE_QRTEXT,
    RICH_PIXELSIZE, RICH_TITLE, RICH_VISIBLE,
    RICH_QRCODE_CREATE_TYPE, RICH_NATRIUM_JOIN_STRING,
    RICH_QRTEXT_FONTSIZE, RICH_QRTEXT_FONTNAME, RICH_QRCODE_SCALE,
    RICH_TIMEBARCODE_TYPE, RICH_AUTO_INC, RICH_AUTO_INC_SIZE,
    RICH_AUTO_INC_RANGE, RICH_AUTO_INC_SAVE, RICH_SEARCH_PRINT,
    RICH_USER_DEFINE_BARCODE_TEXT, RICH_USE_MISSING_KEYWORD_CHECK,
    RICH_AUTO_INC_ZERODEL, RICH_BARCODE_LINE,
    RICH_BARCODE_LINE_SIZE, RICH_BARCODE_ROTATE,
    RICH_AUTO_INC_UPDATE, RICH_USE_DATERANGE, RICH_DATERANGE
  ''';

  static const String _sourceColumnValues = '''
    C.RICH_COLUMN_NAME, C.RICH_KEYWORD,
    C.RICH_COLUMN_ORDER, C.RICH_TYPE, C.RICH_WIDTH, C.RICH_HEIGHT,
    C.RICH_BARCODE_TYPE, C.RICH_USE_BARCODE_CHECKDIGIT,
    C.RICH_SHOW_BARCODE_NUM, C.RICH_SHOW_QRCODE_TEXT,
    C.RICH_QRTEXT_ALIGNMENT, C.RICH_USE_USER_DEFINE_QRDATA,
    C.RICH_USER_DEFINE_QRDATA, C.RICH_USER_DEFINE_QRTEXT,
    C.RICH_PIXELSIZE, C.RICH_TITLE, C.RICH_VISIBLE,
    C.RICH_QRCODE_CREATE_TYPE, C.RICH_NATRIUM_JOIN_STRING,
    C.RICH_QRTEXT_FONTSIZE, C.RICH_QRTEXT_FONTNAME, C.RICH_QRCODE_SCALE,
    C.RICH_TIMEBARCODE_TYPE, C.RICH_AUTO_INC, C.RICH_AUTO_INC_SIZE,
    C.RICH_AUTO_INC_RANGE, C.RICH_AUTO_INC_SAVE, C.RICH_SEARCH_PRINT,
    C.RICH_USER_DEFINE_BARCODE_TEXT, C.RICH_USE_MISSING_KEYWORD_CHECK,
    C.RICH_AUTO_INC_ZERODEL, C.RICH_BARCODE_LINE,
    C.RICH_BARCODE_LINE_SIZE, C.RICH_BARCODE_ROTATE,
    C.RICH_AUTO_INC_UPDATE, C.RICH_USE_DATERANGE, C.RICH_DATERANGE
  ''';

  static const String _copyLabelSizeValues = '''
    T.RICH_FORM_WIDTH=S.RICH_FORM_WIDTH,
    T.RICH_FORM_HEIGHT=S.RICH_FORM_HEIGHT,
    T.RICH_FORM_SHEET=COALESCE(NULLIF(S.RICH_FORM_SHEET, ''), S.RICH_FORM_DATA),
    T.RICH_SETUP_READONLY=S.RICH_SETUP_READONLY,
    T.RICH_SETUP_USE_MAKEDATE=S.RICH_SETUP_USE_MAKEDATE,
    T.RICH_SETUP_USE_MAKETIME=S.RICH_SETUP_USE_MAKETIME,
    T.RICH_SETUP_USE_VALIDDATE=S.RICH_SETUP_USE_VALIDDATE,
    T.RICH_SETUP_USE_VALIDTIME=S.RICH_SETUP_USE_VALIDTIME,
    T.RICH_SETUP_MAKEDATE_TYPE=S.RICH_SETUP_MAKEDATE_TYPE,
    T.RICH_SETUP_MAKETIME_TYPE=S.RICH_SETUP_MAKETIME_TYPE,
    T.RICH_SETUP_VALIDDATE_TYPE=S.RICH_SETUP_VALIDDATE_TYPE,
    T.RICH_SETUP_VALIDTIME_TYPE=S.RICH_SETUP_VALIDTIME_TYPE,
    T.RICH_USER_MAKEDATE=S.RICH_USER_MAKEDATE,
    T.RICH_USER_MAKETIME=S.RICH_USER_MAKETIME,
    T.RICH_USER_VALIDDATE=S.RICH_USER_VALIDDATE,
    T.RICH_USER_VALIDTIME=S.RICH_USER_VALIDTIME,
    T.RICH_SETUP_USE_SCALE=S.RICH_SETUP_USE_SCALE
  ''';

  static const String _itemOfMarketColumns = '''
    RICH_MARKET_ID, RICH_ITEM_ID, RICH_ADDITIONAL_ITEM_ID, RICH_GDS_NO,
    RICH_SALE_START_DATE, RICH_SALE_END_DATE, RICH_DISCOUNT_PERCENT,
    RICH_DISCOUNT_AMOUNT, RICH_DISCOUNT_START_DATE, RICH_DISCOUNT_END_DATE,
    RICH_USE_USER_DEFINE_ELEMENT, RICH_USER_DEFINE_ELEMENT_RTF,
    RICH_USE_LINEFEED, RICH_LINEFEED, RICH_USE_SCALEBARCODE, RICH_PRINT_COUNT,
    RICH_USE_LABELSIZE, RICH_LABELSIZE_WIDTH, RICH_LABELSIZE_HEIGHT,
    RICH_USE_MARGIN, RICH_LEFT_MARGIN, RICH_TOP_MARGIN, RICH_RIGHT_MARGIN,
    RICH_LEFT_PUSH, RICH_TOP_PUSH
  ''';

  static const String _sourceItemOfMarketValues = '''
    M.RICH_ADDITIONAL_ITEM_ID, M.RICH_GDS_NO,
    M.RICH_SALE_START_DATE, M.RICH_SALE_END_DATE, M.RICH_DISCOUNT_PERCENT,
    M.RICH_DISCOUNT_AMOUNT, M.RICH_DISCOUNT_START_DATE, M.RICH_DISCOUNT_END_DATE,
    M.RICH_USE_USER_DEFINE_ELEMENT, M.RICH_USER_DEFINE_ELEMENT_RTF,
    M.RICH_USE_LINEFEED, M.RICH_LINEFEED, M.RICH_USE_SCALEBARCODE,
    M.RICH_PRINT_COUNT, M.RICH_USE_LABELSIZE, M.RICH_LABELSIZE_WIDTH,
    M.RICH_LABELSIZE_HEIGHT, M.RICH_USE_MARGIN, M.RICH_LEFT_MARGIN,
    M.RICH_TOP_MARGIN, M.RICH_RIGHT_MARGIN, M.RICH_LEFT_PUSH, M.RICH_TOP_PUSH
  ''';

  static const String _copyItems = '''
    DECLARE @SourceItems TABLE (
      ROW_NO INT IDENTITY(1,1) PRIMARY KEY,
      SOURCE_ITEM_ID INT NOT NULL UNIQUE
    );
    DECLARE @ItemMap TABLE (
      SOURCE_ITEM_ID INT NOT NULL PRIMARY KEY,
      TARGET_ITEM_ID INT NOT NULL UNIQUE
    );
    DECLARE @CapturedItem TABLE (TARGET_ITEM_ID INT NOT NULL);
    DECLARE @ColumnMap TABLE (
      SOURCE_COLUMN_ID INT NOT NULL PRIMARY KEY,
      TARGET_COLUMN_ID INT NOT NULL UNIQUE
    );
    DECLARE @CopiedContent TABLE (
      TARGET_COLUMN_ID INT NOT NULL,
      TARGET_ITEM_ID INT NOT NULL,
      RICH_EDITABLE TINYINT NOT NULL,
      RICH_COL_CONTENT_DATA NVARCHAR(MAX) NOT NULL,
      PRIMARY KEY (TARGET_COLUMN_ID, TARGET_ITEM_ID)
    );

    DELETE FROM @SourceItems;
    DELETE FROM @ItemMap;
    DELETE FROM @CapturedItem;
    DELETE FROM @ColumnMap;
    DELETE FROM @CopiedContent;

    INSERT INTO @SourceItems (SOURCE_ITEM_ID)
    SELECT RICH_ITEM_ID
      FROM BM_RICH_ITEM
     WHERE RICH_LABELSIZE_ID=@FromSizeId
     ORDER BY RICH_ITEM_ORDER, RICH_ITEM_ID;

    DECLARE @ItemRowNo INT=(SELECT MIN(ROW_NO) FROM @SourceItems);
    DECLARE @ItemRowCount INT=(SELECT MAX(ROW_NO) FROM @SourceItems);
    WHILE @ItemRowNo IS NOT NULL AND @ItemRowNo<=@ItemRowCount
    BEGIN
      DECLARE @SourceItemId INT;
      SELECT @SourceItemId=SOURCE_ITEM_ID
        FROM @SourceItems WHERE ROW_NO=@ItemRowNo;
      DELETE FROM @CapturedItem;
      INSERT INTO BM_RICH_ITEM (
        RICH_LABELSIZE_ID, RICH_ITEM_NAME, RICH_ELEMENT,
        RICH_ELEMENT_SHEET, RICH_ELEMENT_RTF, RICH_PRICE, RICH_ITEM_ORDER
      )
      OUTPUT INSERTED.RICH_ITEM_ID INTO @CapturedItem(TARGET_ITEM_ID)
      SELECT @ToSizeId, RICH_ITEM_NAME, RICH_ELEMENT,
        RICH_ELEMENT_SHEET, RICH_ELEMENT_RTF, RICH_PRICE, RICH_ITEM_ORDER
        FROM BM_RICH_ITEM
       WHERE RICH_ITEM_ID=@SourceItemId;
      INSERT INTO @ItemMap (SOURCE_ITEM_ID, TARGET_ITEM_ID)
      SELECT @SourceItemId, TARGET_ITEM_ID FROM @CapturedItem;
      SET @ItemRowNo+=1;
    END;

    ;WITH SourceColumns AS (
      SELECT RICH_COLUMN_ID,
        ROW_NUMBER() OVER (ORDER BY RICH_COLUMN_ORDER, RICH_COLUMN_ID) AS RN
        FROM BM_RICH_COLUMN
       WHERE RICH_LABELSIZE_ID=@FromSizeId
    ), TargetColumns AS (
      SELECT RICH_COLUMN_ID,
        ROW_NUMBER() OVER (ORDER BY RICH_COLUMN_ORDER, RICH_COLUMN_ID) AS RN
        FROM BM_RICH_COLUMN
       WHERE RICH_LABELSIZE_ID=@ToSizeId
    )
    INSERT INTO @ColumnMap (SOURCE_COLUMN_ID, TARGET_COLUMN_ID)
    SELECT S.RICH_COLUMN_ID, T.RICH_COLUMN_ID
      FROM SourceColumns S
      INNER JOIN TargetColumns T ON T.RN=S.RN;

    IF (SELECT COUNT(*) FROM @ColumnMap) <>
       (SELECT COUNT(*) FROM BM_RICH_COLUMN WHERE RICH_LABELSIZE_ID=@FromSizeId)
      THROW 51120, 'Admin copy column mapping failed.', 1;

    ;WITH RankedSourceContent AS (
      SELECT C.RICH_COLUMN_ID, C.RICH_ITEM_ID, C.RICH_EDITABLE,
        C.RICH_COL_CONTENT_DATA,
        ROW_NUMBER() OVER (
          PARTITION BY C.RICH_COLUMN_ID, C.RICH_ITEM_ID
          ORDER BY C.RICH_COL_CONTENT_ID DESC
        ) AS RN
        FROM BM_RICH_COL_CONTENT C
        INNER JOIN @ItemMap I ON I.SOURCE_ITEM_ID=C.RICH_ITEM_ID
        INNER JOIN @ColumnMap M ON M.SOURCE_COLUMN_ID=C.RICH_COLUMN_ID
    )
    INSERT INTO @CopiedContent (
      TARGET_COLUMN_ID, TARGET_ITEM_ID,
      RICH_EDITABLE, RICH_COL_CONTENT_DATA
    )
    SELECT M.TARGET_COLUMN_ID, I.TARGET_ITEM_ID,
      C.RICH_EDITABLE, C.RICH_COL_CONTENT_DATA
      FROM RankedSourceContent C
      INNER JOIN @ItemMap I ON I.SOURCE_ITEM_ID=C.RICH_ITEM_ID
      INNER JOIN @ColumnMap M ON M.SOURCE_COLUMN_ID=C.RICH_COLUMN_ID
     WHERE C.RN=1;

    UPDATE TARGET_CONTENT SET
      TARGET_CONTENT.RICH_EDITABLE=SOURCE_CONTENT.RICH_EDITABLE,
      TARGET_CONTENT.RICH_COL_CONTENT_DATA=SOURCE_CONTENT.RICH_COL_CONTENT_DATA
      FROM BM_RICH_COL_CONTENT TARGET_CONTENT
      INNER JOIN @CopiedContent SOURCE_CONTENT
        ON SOURCE_CONTENT.TARGET_COLUMN_ID=TARGET_CONTENT.RICH_COLUMN_ID
       AND SOURCE_CONTENT.TARGET_ITEM_ID=TARGET_CONTENT.RICH_ITEM_ID;

    INSERT INTO BM_RICH_COL_CONTENT (
      RICH_COLUMN_ID, RICH_ITEM_ID, RICH_EDITABLE, RICH_COL_CONTENT_DATA
    )
    SELECT C.TARGET_COLUMN_ID, C.TARGET_ITEM_ID,
      C.RICH_EDITABLE, C.RICH_COL_CONTENT_DATA
      FROM @CopiedContent C
     WHERE NOT EXISTS (
       SELECT 1 FROM BM_RICH_COL_CONTENT T
        WHERE T.RICH_COLUMN_ID=C.TARGET_COLUMN_ID
          AND T.RICH_ITEM_ID=C.TARGET_ITEM_ID
     );

    ;WITH SourceMarkets AS (
      SELECT M.*,
        ROW_NUMBER() OVER (
          PARTITION BY M.RICH_ITEM_ID ORDER BY M.RICH_MARKET_ID
        ) AS RN
        FROM BM_ITEM_OF_MARKET M
        INNER JOIN @ItemMap I ON I.SOURCE_ITEM_ID=M.RICH_ITEM_ID
    )
    INSERT INTO BM_ITEM_OF_MARKET ($_itemOfMarketColumns)
    SELECT @targetFirstMarketId, I.TARGET_ITEM_ID, $_sourceItemOfMarketValues
      FROM SourceMarkets M
      INNER JOIN @ItemMap I ON I.SOURCE_ITEM_ID=M.RICH_ITEM_ID
     WHERE M.RN=1;
  ''';

  static const String targetHasColumnsSql = '''
    SELECT CASE WHEN EXISTS (
      SELECT 1 FROM BM_RICH_COLUMN WHERE RICH_LABELSIZE_ID=@targetLabelSizeId
    ) THEN 1 ELSE 0 END AS HAS_COLUMNS
  ''';

  static const String copyLabelSizeSql =
      '''
    DECLARE @FromSizeId INT=@sourceLabelSizeId;
    DECLARE @ToSizeId INT=@targetLabelSizeId;

    IF @overwriteExisting=1
    BEGIN
      DELETE FROM BM_GS1_COLUMN_INFO
       WHERE COLUMN_ID IN (
         SELECT RICH_COLUMN_ID FROM BM_RICH_COLUMN
          WHERE RICH_LABELSIZE_ID=@targetLabelSizeId
       );
      DELETE FROM BM_RICH_COLUMN
       WHERE RICH_LABELSIZE_ID=@targetLabelSizeId;
      DELETE FROM BM_RICH_COL_MIN
       WHERE RICH_LABELSIZE_ID=@targetLabelSizeId;
      DELETE FROM BM_RICH_CHECK_COLUMNS
       WHERE RICH_LABELSIZE_ID=@targetLabelSizeId;
      UPDATE BM_RICH_STATUS
         SET RICH_ID_CHANGE_DELETE_DATE=GETDATE()
       WHERE RICH_LABELSIZE_ID=@targetLabelSizeId;
      DELETE FROM BM_RICH_ITEM
       WHERE RICH_LABELSIZE_ID=@targetLabelSizeId;
    END;

    UPDATE T SET $_copyLabelSizeValues
      FROM BM_RICH_LABELSIZE_FORM T
      INNER JOIN BM_RICH_LABELSIZE_FORM S
        ON S.RICH_LABELSIZE_ID=@sourceLabelSizeId
     WHERE T.RICH_LABELSIZE_ID=@targetLabelSizeId;

    INSERT INTO BM_RICH_COLUMN ($_columnNames)
    SELECT @targetLabelSizeId, $_sourceColumnValues
      FROM BM_RICH_COLUMN C
     WHERE C.RICH_LABELSIZE_ID=@sourceLabelSizeId;

    IF @copyItems=1
    BEGIN
      $_copyItems
    END;

    SELECT @targetLabelSizeId AS TARGET_LABELSIZE_ID;
  ''';

  static const String copyBrandSql =
      '''
    DECLARE @InsertedBrand TABLE (BRAND_ID INT NOT NULL);
    DECLARE @SizeMap TABLE (
      ROW_NO INT IDENTITY(1,1),
      SOURCE_LABELSIZE_ID INT NOT NULL,
      TARGET_LABELSIZE_ID INT NOT NULL
    );
    DECLARE @OneSize TABLE (LABELSIZE_ID INT NOT NULL);
    DECLARE @SourceSizes TABLE (
      ROW_NO INT IDENTITY(1,1),
      LABELSIZE_ID INT NOT NULL,
      LABELSIZE_NAME NVARCHAR(50) NOT NULL
    );

    INSERT INTO BM_RICH_BRAND
      (RICH_CUSTOMER_ID, RICH_BRAND_NAME, RICH_BRAND_ORDER)
    OUTPUT INSERTED.RICH_BRAND_ID INTO @InsertedBrand(BRAND_ID)
    SELECT @targetCustomerId, @sourceBrandName, COUNT(*)+1
      FROM BM_RICH_BRAND
     WHERE RICH_CUSTOMER_ID=@targetCustomerId;

    INSERT INTO @SourceSizes(LABELSIZE_ID, LABELSIZE_NAME)
    SELECT RICH_LABELSIZE_ID, RICH_LABELSIZE_NAME
      FROM BM_RICH_LABELSIZE_FORM
     WHERE RICH_BRAND_ID=@sourceBrandId
     ORDER BY RICH_LABELSIZE_ORDER ASC;

    DECLARE @RowNo INT=1;
    DECLARE @RowCount INT=(SELECT COUNT(*) FROM @SourceSizes);
    WHILE @RowNo<=@RowCount
    BEGIN
      DECLARE @SourceSizeId INT;
      DECLARE @SourceSizeName NVARCHAR(50);
      SELECT @SourceSizeId=LABELSIZE_ID, @SourceSizeName=LABELSIZE_NAME
        FROM @SourceSizes WHERE ROW_NO=@RowNo;
      DELETE FROM @OneSize;
      INSERT INTO BM_RICH_LABELSIZE_FORM
        (RICH_BRAND_ID, RICH_LABELSIZE_NAME, RICH_LABELSIZE_ORDER)
      OUTPUT INSERTED.RICH_LABELSIZE_ID INTO @OneSize(LABELSIZE_ID)
      SELECT B.BRAND_ID, @SourceSizeName, @RowNo FROM @InsertedBrand B;
      INSERT INTO @SizeMap(SOURCE_LABELSIZE_ID, TARGET_LABELSIZE_ID)
      SELECT @SourceSizeId, LABELSIZE_ID FROM @OneSize;
      SET @RowNo+=1;
    END;

    UPDATE T SET $_copyLabelSizeValues
      FROM BM_RICH_LABELSIZE_FORM T
      INNER JOIN @SizeMap M ON M.TARGET_LABELSIZE_ID=T.RICH_LABELSIZE_ID
      INNER JOIN BM_RICH_LABELSIZE_FORM S
        ON S.RICH_LABELSIZE_ID=M.SOURCE_LABELSIZE_ID;

    INSERT INTO BM_RICH_COLUMN ($_columnNames)
    SELECT M.TARGET_LABELSIZE_ID, $_sourceColumnValues
      FROM @SizeMap M
      INNER JOIN BM_RICH_COLUMN C
        ON C.RICH_LABELSIZE_ID=M.SOURCE_LABELSIZE_ID;

    IF @copyItems=1
    BEGIN
      SET @RowNo=1;
      SET @RowCount=(SELECT COUNT(*) FROM @SizeMap);
      WHILE @RowNo<=@RowCount
      BEGIN
        DECLARE @FromSizeId INT;
        DECLARE @ToSizeId INT;
        SELECT @FromSizeId=SOURCE_LABELSIZE_ID,
               @ToSizeId=TARGET_LABELSIZE_ID
          FROM @SizeMap WHERE ROW_NO=@RowNo;
        $_copyItems
        SET @RowNo+=1;
      END;
    END;

    SELECT BRAND_ID AS TARGET_BRAND_ID FROM @InsertedBrand;
  ''';

  static Future<bool> targetHasColumns(int targetLabelSizeId) async {
    final result = await DbClient.instance.getDataWithParams(
      targetHasColumnsSql,
      {'targetLabelSizeId': targetLabelSizeId},
    );
    final row = DAO.getRowMapFromResult(result);
    return (row?['HAS_COLUMNS'] ?? '').toString() == '1';
  }

  static Future<void> copyLabelSize(AdminLabelSizeCopyCommand command) async {
    _validateItemTarget(command.copyItems, command.targetFirstMarketId);
    await DbClient.instance.transaction([
      DbTransactionStatement(
        sql: copyLabelSizeSql,
        params: {
          'sourceLabelSizeId': command.sourceLabelSizeId,
          'targetLabelSizeId': command.targetLabelSizeId,
          'overwriteExisting': command.overwriteExisting ? 1 : 0,
          'copyItems': command.copyItems ? 1 : 0,
          'targetFirstMarketId': command.targetFirstMarketId,
        },
        returnsRows: true,
      ),
    ]);
  }

  static Future<void> copyBrand(AdminBrandCopyCommand command) async {
    _validateItemTarget(command.copyItems, command.targetFirstMarketId);
    RegressionDebugLog.event(
      'adminCopyBrandSql',
      'transactionRequested',
      fields: {
        'sourceBrandId': command.sourceBrandId,
        'targetCustomerId': command.targetCustomerId,
        'copyItems': command.copyItems,
        'targetFirstMarketId': command.targetFirstMarketId,
        'itemWorkspaceReset': 'v1',
      },
    );
    try {
      await DbClient.instance.transaction([
        DbTransactionStatement(
          sql: copyBrandSql,
          params: {
            'sourceBrandId': command.sourceBrandId,
            'targetCustomerId': command.targetCustomerId,
            'sourceBrandName': command.sourceBrandName,
            'copyItems': command.copyItems ? 1 : 0,
            'targetFirstMarketId': command.targetFirstMarketId,
          },
          returnsRows: true,
        ),
      ]);
      RegressionDebugLog.event(
        'adminCopyBrandSql',
        'transactionCompleted',
        fields: {
          'sourceBrandId': command.sourceBrandId,
          'targetCustomerId': command.targetCustomerId,
          'copyItems': command.copyItems,
          'itemWorkspaceReset': 'v1',
        },
      );
    } catch (error) {
      RegressionDebugLog.event(
        'adminCopyBrandSql',
        'transactionFailed',
        fields: {
          'sourceBrandId': command.sourceBrandId,
          'targetCustomerId': command.targetCustomerId,
          'copyItems': command.copyItems,
          'itemWorkspaceReset': 'v1',
          'error': error,
        },
      );
      rethrow;
    }
  }

  static void _validateItemTarget(bool copyItems, int? targetFirstMarketId) {
    if (copyItems && targetFirstMarketId == null) {
      throw StateError('품목을 복사할 대상 거래처에 지점이 없습니다.');
    }
  }
}
