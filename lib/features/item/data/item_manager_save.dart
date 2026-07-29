import 'dart:convert';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/item/domain/item_manager_save_command.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/features/item/item_manager_debug_log.dart';
import 'package:label_manager/utils/log_context.dart';

export 'package:label_manager/features/item/domain/item_manager_save_command.dart';

Map<String, dynamic> itemManagerSaveSqlParams(ItemManagerSaveCommand command) {
  command.validate();
  return {
    'targetMarketIdsXml': _itemManagerIdsXml(
      'markets',
      'market',
      command.targetMarketIds,
    ),
    'deletedItemIdsXml': _itemManagerIdsXml(
      'items',
      'item',
      command.deletedSourceItemIds,
    ),
    'existingRowsXml': _itemManagerExistingRowsXml(command.existingRows),
    'newRowsXml': _itemManagerNewRowsXml(command.newRows),
    'columnValuesXml': _itemManagerColumnValuesXml(command.columnValues),
  };
}

String _itemManagerIdsXml(
  String rootName,
  String childName,
  Iterable<int> values,
) =>
    '<$rootName>${values.map((value) => '<$childName id="$value" />').join()}</$rootName>';

String _itemManagerExistingRowsXml(
  Iterable<ItemManagerExistingRowSave> rows,
) {
  final xml = StringBuffer('<rows>');
  for (final row in rows) {
    xml
      ..write('<row sourceItemId="${row.sourceItemId}" order="${row.order}">')
      ..write('<itemName>${_itemManagerXmlText(row.itemName)}</itemName>')
      ..write(
        '<elementPlain>${_itemManagerXmlText(row.elementPlain)}</elementPlain>',
      )
      ..write(
        '<elementSheet>${_itemManagerXmlText(row.elementSheet)}</elementSheet>',
      )
      ..write('</row>');
  }
  return (xml..write('</rows>')).toString();
}

String _itemManagerNewRowsXml(Iterable<ItemManagerNewRowSave> rows) {
  final xml = StringBuffer('<rows>');
  var rowNo = 0;
  for (final row in rows) {
    final defaults = row.mappingDefaults;
    xml
      ..write('<row rowNo="${++rowNo}" labelSizeId="${row.labelSizeId}" ')
      ..write('order="${row.order}" gdsNo="${defaults.gdsNo}" ')
      ..write('discountPercent="${defaults.discountPercent}" ')
      ..write('discountAmount="${defaults.discountAmount}" ')
      ..write('useDefineElement="${defaults.useDefineElement ? 1 : 0}" ')
      ..write('useLinefeed="${defaults.useLinefeed ? 1 : 0}" ')
      ..write('linefeed="${defaults.linefeed}" ')
      ..write('useScaleBarcode="${defaults.useScaleBarcode ? 1 : 0}" ')
      ..write('printCount="${defaults.printCount}" ')
      ..write('useLabelSize="${defaults.useLabelSize ? 1 : 0}" ')
      ..write('labelSizeWidth="${defaults.labelSizeWidth}" ')
      ..write('labelSizeHeight="${defaults.labelSizeHeight}" ')
      ..write('useMargin="${defaults.useMargin ? 1 : 0}" ')
      ..write('leftMargin="${defaults.leftMargin}" ')
      ..write('rightMargin="${defaults.rightMargin}" ')
      ..write('topMargin="${defaults.topMargin}" ')
      ..write('leftPush="${defaults.leftPush}" ')
      ..write('topPush="${defaults.topPush}">')
      ..write(
        '<draftRowKey>${_itemManagerXmlText(row.draftRowKey)}</draftRowKey>',
      )
      ..write('<itemName>${_itemManagerXmlText(row.itemName)}</itemName>')
      ..write(
        '<elementPlain>${_itemManagerXmlText(row.elementPlain)}</elementPlain>',
      )
      ..write(
        '<elementSheet>${_itemManagerXmlText(row.elementSheet)}</elementSheet>',
      )
      ..write(
        '<dateSaleStart>${defaults.dateSaleStart?.toIso8601String() ?? ''}</dateSaleStart>',
      )
      ..write(
        '<dateSaleEnd>${defaults.dateSaleEnd?.toIso8601String() ?? ''}</dateSaleEnd>',
      )
      ..write(
        '<dateStartDiscount>${defaults.dateStartDiscount?.toIso8601String() ?? ''}</dateStartDiscount>',
      )
      ..write(
        '<dateEndDiscount>${defaults.dateEndDiscount?.toIso8601String() ?? ''}</dateEndDiscount>',
      )
      ..write('<rtfText>${_itemManagerXmlText(defaults.rtfText)}</rtfText>')
      ..write('</row>');
  }
  return (xml..write('</rows>')).toString();
}

String _itemManagerColumnValuesXml(
  Iterable<ItemManagerColumnValueSave> values,
) {
  final xml = StringBuffer('<values>');
  for (final value in values) {
    xml
      ..write('<value columnId="${value.columnId}" ')
      ..write('editable="${value.editable ? 1 : 0}"');
    if (value.sourceItemId != null) {
      xml.write(' sourceItemId="${value.sourceItemId}"');
    }
    xml
      ..write('>')
      ..write(
        '<draftRowKey>${_itemManagerXmlText(value.draftRowKey)}</draftRowKey>',
      )
      ..write(
        '<dataString>${_itemManagerXmlText(value.dataString)}</dataString>',
      )
      ..write('</value>');
  }
  return (xml..write('</values>')).toString();
}

String _itemManagerXmlText(Object? value) => const HtmlEscape(
  HtmlEscapeMode.element,
).convert(value?.toString() ?? '');

class ItemManagerSaveDAO extends DAO {
  static const String saveSql = r'''
    SET NOCOUNT ON;

    DECLARE @TargetMarketsDocument XML = CONVERT(XML, @targetMarketIdsXml);
    DECLARE @DeletedItemsDocument XML = CONVERT(XML, @deletedItemIdsXml);
    DECLARE @ExistingRowsDocument XML = CONVERT(XML, @existingRowsXml);
    DECLARE @NewRowsDocument XML = CONVERT(XML, @newRowsXml);
    DECLARE @ColumnValuesDocument XML = CONVERT(XML, @columnValuesXml);
    DECLARE @TargetMarkets TABLE (MARKET_ID INT NOT NULL PRIMARY KEY);
    DECLARE @DeletedItems TABLE (ITEM_ID INT NOT NULL PRIMARY KEY);
    DECLARE @ExistingInput TABLE (
      ITEM_ID INT NOT NULL PRIMARY KEY,
      ITEM_NAME NVARCHAR(100) NOT NULL,
      ELEMENT_PLAIN NVARCHAR(MAX) NOT NULL,
      ELEMENT_SHEET NVARCHAR(MAX) NOT NULL,
      ITEM_ORDER INT NOT NULL
    );
    INSERT INTO @TargetMarkets(MARKET_ID)
    SELECT N.value('@id', 'INT')
    FROM @TargetMarketsDocument.nodes('/markets/market') X(N);
    INSERT INTO @DeletedItems(ITEM_ID)
    SELECT N.value('@id', 'INT')
    FROM @DeletedItemsDocument.nodes('/items/item') X(N);
    INSERT INTO @ExistingInput(
      ITEM_ID, ITEM_NAME, ELEMENT_PLAIN, ELEMENT_SHEET, ITEM_ORDER
    )
    SELECT
      N.value('@sourceItemId', 'INT'),
      N.value('string((itemName/text())[1])', 'NVARCHAR(100)'),
      N.value('string((elementPlain/text())[1])', 'NVARCHAR(MAX)'),
      N.value('string((elementSheet/text())[1])', 'NVARCHAR(MAX)'),
      N.value('@order', 'INT')
    FROM @ExistingRowsDocument.nodes('/rows/row') X(N);

    DECLARE @InsertedRows TABLE (
      DRAFT_ROW_KEY NVARCHAR(100) NOT NULL PRIMARY KEY,
      ITEM_ID INT NOT NULL
    );
    DECLARE @NewInput TABLE (
      ROW_NO INT NOT NULL PRIMARY KEY,
      DRAFT_ROW_KEY NVARCHAR(100) NOT NULL,
      LABELSIZE_ID INT NOT NULL,
      ITEM_NAME NVARCHAR(100) NOT NULL,
      ELEMENT_PLAIN NVARCHAR(MAX) NOT NULL,
      ELEMENT_SHEET NVARCHAR(MAX) NOT NULL,
      ITEM_ORDER INT NOT NULL,
      GDS_NO INT NOT NULL,
      SALE_START_DATE DATETIME2 NULL,
      SALE_END_DATE DATETIME2 NULL,
      DISCOUNT_PERCENT FLOAT NOT NULL,
      DISCOUNT_AMOUNT INT NOT NULL,
      DISCOUNT_START_DATE DATETIME2 NULL,
      DISCOUNT_END_DATE DATETIME2 NULL,
      USE_DEFINE_ELEMENT BIT NOT NULL,
      USER_DEFINE_RTF NVARCHAR(MAX) NOT NULL,
      USE_LINEFEED BIT NOT NULL,
      LINEFEED INT NOT NULL,
      USE_SCALEBARCODE BIT NOT NULL,
      PRINT_COUNT INT NOT NULL,
      USE_LABELSIZE BIT NOT NULL,
      LABELSIZE_WIDTH INT NOT NULL,
      LABELSIZE_HEIGHT INT NOT NULL,
      USE_MARGIN BIT NOT NULL,
      LEFT_MARGIN FLOAT NOT NULL,
      RIGHT_MARGIN FLOAT NOT NULL,
      TOP_MARGIN FLOAT NOT NULL,
      LEFT_PUSH FLOAT NOT NULL,
      TOP_PUSH FLOAT NOT NULL
    );

    INSERT INTO @NewInput
    SELECT
      N.value('@rowNo', 'INT'),
      N.value('string((draftRowKey/text())[1])', 'NVARCHAR(100)'),
      N.value('@labelSizeId', 'INT'),
      N.value('string((itemName/text())[1])', 'NVARCHAR(100)'),
      N.value('string((elementPlain/text())[1])', 'NVARCHAR(MAX)'),
      N.value('string((elementSheet/text())[1])', 'NVARCHAR(MAX)'),
      N.value('@order', 'INT'), N.value('@gdsNo', 'INT'),
      CONVERT(DATETIME2, NULLIF(N.value('string((dateSaleStart/text())[1])', 'NVARCHAR(50)'), N'')),
      CONVERT(DATETIME2, NULLIF(N.value('string((dateSaleEnd/text())[1])', 'NVARCHAR(50)'), N'')),
      N.value('@discountPercent', 'FLOAT'), N.value('@discountAmount', 'INT'),
      CONVERT(DATETIME2, NULLIF(N.value('string((dateStartDiscount/text())[1])', 'NVARCHAR(50)'), N'')),
      CONVERT(DATETIME2, NULLIF(N.value('string((dateEndDiscount/text())[1])', 'NVARCHAR(50)'), N'')),
      N.value('@useDefineElement', 'BIT'),
      N.value('string((rtfText/text())[1])', 'NVARCHAR(MAX)'),
      N.value('@useLinefeed', 'BIT'), N.value('@linefeed', 'INT'),
      N.value('@useScaleBarcode', 'BIT'), N.value('@printCount', 'INT'),
      N.value('@useLabelSize', 'BIT'), N.value('@labelSizeWidth', 'INT'),
      N.value('@labelSizeHeight', 'INT'), N.value('@useMargin', 'BIT'),
      N.value('@leftMargin', 'FLOAT'), N.value('@rightMargin', 'FLOAT'),
      N.value('@topMargin', 'FLOAT'), N.value('@leftPush', 'FLOAT'),
      N.value('@topPush', 'FLOAT')
    FROM @NewRowsDocument.nodes('/rows/row') X(N);

    UPDATE I SET
      RICH_ITEM_NAME=E.ITEM_NAME,
      RICH_ELEMENT=E.ELEMENT_PLAIN,
      RICH_ELEMENT_SHEET=E.ELEMENT_SHEET,
      RICH_ITEM_ORDER=E.ITEM_ORDER
    FROM BM_RICH_ITEM I
    INNER JOIN @ExistingInput E ON I.RICH_ITEM_ID=E.ITEM_ID;
    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @ExistingInput)
      THROW 51001, 'Existing item update count mismatch.', 1;

    DECLARE @RowNo INT = 1;
    DECLARE @RowCount INT = (SELECT COUNT(*) FROM @NewInput);
    WHILE @RowNo <= @RowCount
    BEGIN
      DECLARE @DraftRowKey NVARCHAR(100);
      DECLARE @CapturedItem TABLE (ITEM_ID INT NOT NULL);
      SELECT @DraftRowKey=DRAFT_ROW_KEY FROM @NewInput WHERE ROW_NO=@RowNo;
      INSERT INTO BM_RICH_ITEM (
        RICH_LABELSIZE_ID, RICH_ITEM_NAME, RICH_ELEMENT,
        RICH_ELEMENT_SHEET, RICH_PRICE, RICH_ITEM_ORDER
      )
      OUTPUT INSERTED.RICH_ITEM_ID INTO @CapturedItem(ITEM_ID)
      SELECT LABELSIZE_ID, ITEM_NAME, ELEMENT_PLAIN,
        ELEMENT_SHEET, 0, ITEM_ORDER
      FROM @NewInput WHERE ROW_NO=@RowNo;
      INSERT INTO @InsertedRows(DRAFT_ROW_KEY, ITEM_ID)
      SELECT @DraftRowKey, ITEM_ID FROM @CapturedItem;
      SET @RowNo += 1;
    END;

    IF (SELECT COUNT(*) FROM @InsertedRows) <> (SELECT COUNT(*) FROM @NewInput)
      THROW 51003, 'Inserted item id mapping count mismatch.', 1;
    IF EXISTS (
      SELECT DRAFT_ROW_KEY FROM @NewInput
      EXCEPT
      SELECT DRAFT_ROW_KEY FROM @InsertedRows
    ) OR EXISTS (
      SELECT DRAFT_ROW_KEY FROM @InsertedRows
      EXCEPT
      SELECT DRAFT_ROW_KEY FROM @NewInput
    )
      THROW 51004, 'Inserted item id mapping key mismatch.', 1;

    INSERT INTO BM_ITEM_OF_MARKET (
      RICH_MARKET_ID, RICH_ITEM_ID, RICH_ADDITIONAL_ITEM_ID,
      RICH_GDS_NO, RICH_SALE_START_DATE, RICH_SALE_END_DATE,
      RICH_DISCOUNT_PERCENT, RICH_DISCOUNT_AMOUNT,
      RICH_DISCOUNT_START_DATE, RICH_DISCOUNT_END_DATE,
      RICH_USE_USER_DEFINE_ELEMENT, RICH_USER_DEFINE_ELEMENT_RTF,
      RICH_USE_LINEFEED, RICH_LINEFEED, RICH_USE_SCALEBARCODE,
      RICH_PRINT_COUNT, RICH_USE_LABELSIZE, RICH_LABELSIZE_WIDTH,
      RICH_LABELSIZE_HEIGHT, RICH_USE_MARGIN, RICH_LEFT_MARGIN,
      RICH_RIGHT_MARGIN, RICH_TOP_MARGIN, RICH_LEFT_PUSH, RICH_TOP_PUSH
    )
    SELECT M.MARKET_ID, I.ITEM_ID, NULL,
      N.GDS_NO, N.SALE_START_DATE, N.SALE_END_DATE,
      N.DISCOUNT_PERCENT, N.DISCOUNT_AMOUNT,
      N.DISCOUNT_START_DATE, N.DISCOUNT_END_DATE,
      N.USE_DEFINE_ELEMENT, N.USER_DEFINE_RTF,
      N.USE_LINEFEED, N.LINEFEED, N.USE_SCALEBARCODE,
      N.PRINT_COUNT, N.USE_LABELSIZE, N.LABELSIZE_WIDTH,
      N.LABELSIZE_HEIGHT, N.USE_MARGIN, N.LEFT_MARGIN,
      N.RIGHT_MARGIN, N.TOP_MARGIN, N.LEFT_PUSH, N.TOP_PUSH
    FROM @InsertedRows I
    INNER JOIN @NewInput N ON N.DRAFT_ROW_KEY=I.DRAFT_ROW_KEY
    CROSS JOIN @TargetMarkets M;

    DELETE C
    FROM BM_RICH_COL_CONTENT C
    INNER JOIN @DeletedItems D
      ON C.RICH_ITEM_ID=D.ITEM_ID;

    DELETE M
    FROM BM_ITEM_OF_MARKET M
    INNER JOIN @DeletedItems D
      ON M.RICH_ITEM_ID=D.ITEM_ID;

    DELETE UC
    FROM BM_UPDATE_COL_CONTENT UC
    INNER JOIN BM_UPDATE_ITEM U
      ON UC.RICH_UPDATE_ITEM_ID=U.RICH_UPDATE_ITEM_ID
    INNER JOIN @DeletedItems D
      ON U.RICH_ITEM_ID=D.ITEM_ID;

    DELETE U
    FROM BM_UPDATE_ITEM U
    INNER JOIN @DeletedItems D
      ON U.RICH_ITEM_ID=D.ITEM_ID;

    DELETE I
    FROM BM_RICH_ITEM I
    INNER JOIN @DeletedItems D
      ON I.RICH_ITEM_ID=D.ITEM_ID;
    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @DeletedItems)
      THROW 51005, 'Deleted item count mismatch.', 1;

    UPDATE S SET
      RICH_ID_CHANGE_DELETE_DATE=GETDATE(),
      RICH_ITEM_ID=-1
    FROM BM_RICH_STATUS S
    INNER JOIN @DeletedItems D
      ON S.RICH_ITEM_ID=D.ITEM_ID;

    MERGE BM_RICH_COL_CONTENT AS TARGET
    USING (
      SELECT COALESCE(C.SOURCE_ITEM_ID, I.ITEM_ID) AS ITEM_ID,
        C.COLUMN_ID, C.EDITABLE, C.DATA_STRING
      FROM (
        SELECT
          CONVERT(INT, NULLIF(N.value('string(@sourceItemId)', 'NVARCHAR(20)'), N'')) AS SOURCE_ITEM_ID,
          N.value('string((draftRowKey/text())[1])', 'NVARCHAR(100)') AS DRAFT_ROW_KEY,
          N.value('@columnId', 'INT') AS COLUMN_ID,
          N.value('@editable', 'BIT') AS EDITABLE,
          N.value('string((dataString/text())[1])', 'NVARCHAR(3000)') AS DATA_STRING
        FROM @ColumnValuesDocument.nodes('/values/value') X(N)
      ) C
      LEFT JOIN @InsertedRows I ON I.DRAFT_ROW_KEY=C.DRAFT_ROW_KEY
    ) AS SOURCE
    ON TARGET.RICH_ITEM_ID=SOURCE.ITEM_ID
      AND TARGET.RICH_COLUMN_ID=SOURCE.COLUMN_ID
    WHEN MATCHED THEN UPDATE SET
      RICH_EDITABLE=SOURCE.EDITABLE,
      RICH_COL_CONTENT_DATA=SOURCE.DATA_STRING
    WHEN NOT MATCHED THEN INSERT (
      RICH_COLUMN_ID, RICH_ITEM_ID, RICH_EDITABLE, RICH_COL_CONTENT_DATA
    ) VALUES (
      SOURCE.COLUMN_ID, SOURCE.ITEM_ID, SOURCE.EDITABLE, SOURCE.DATA_STRING
    );

    SELECT DRAFT_ROW_KEY, ITEM_ID FROM @InsertedRows ORDER BY DRAFT_ROW_KEY;
  ''';

  static Future<ItemManagerSaveResult> save(
    ItemManagerSaveCommand command,
  ) async {
    final trace = ItemManagerDebugLog.nextTrace('saveDao');
    final params = itemManagerSaveSqlParams(command);
    ItemManagerDebugLog.event(
      'saveDao',
      'transactionStarted',
      trace: trace,
      fields: {
        'existing': command.existingRows.length,
        'new': command.newRows.length,
        'deleted': command.deletedSourceItemIds.length,
        'columns': command.columnValues.length,
        'targetMarkets': command.targetMarketIds.length,
      },
    );
    debugLog(
      '$START, existing:${command.existingRows.length}, '
      'new:${command.newRows.length}, deleted:${command.deletedSourceItemIds.length}, '
      'columns:${command.columnValues.length}',
    );
    try {
      final results = await DbClient.instance.transaction([
        DbTransactionStatement(sql: saveSql, params: params, returnsRows: true),
      ]);
      final rows = DAO.getRowsFromResult(results.single);
      final insertedIds = <String, int>{
        for (final rawRow in rows)
          (rawRow as Map<String, dynamic>)['DRAFT_ROW_KEY'].toString():
              int.parse(rawRow['ITEM_ID'].toString()),
      };
      if (insertedIds.length != command.newRows.length) {
        throw StateError('Inserted item id mapping count mismatch.');
      }
      debugLog('$END, inserted:${insertedIds.length}');
      ItemManagerDebugLog.event(
        'saveDao',
        'transactionCompleted',
        trace: trace,
        fields: {'inserted': insertedIds.length},
      );
      return ItemManagerSaveResult(insertedItemIdsByDraftKey: insertedIds);
    } catch (e) {
      debugLog('$END, $e');
      ItemManagerDebugLog.event(
        'saveDao',
        'transactionFailed',
        trace: trace,
        fields: {'error': e.runtimeType},
      );
      rethrow;
    }
  }
}
