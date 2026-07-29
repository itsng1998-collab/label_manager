import 'dart:convert';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/automatic_item_update/domain/automatic_item_update_draft.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

String _autoItemUpdateXmlText(Object? value) => const HtmlEscape(
  HtmlEscapeMode.element,
).convert(value?.toString() ?? '');

String _autoItemUpdateDateText(DateTime value) => formatAutoItemUpdateDate(value);

String _autoItemUpdateIdsXml(Iterable<int> values) =>
    '<rows>${values.map((value) => '<row id="$value" />').join()}</rows>';

String _autoItemUpdateExistingRowsXml(
  Iterable<AutoItemUpdateExistingRowSave> rows,
) {
  final xml = StringBuffer('<rows>');
  for (final row in rows) {
    xml
      ..write(
        '<row sourceUpdateItemId="${row.sourceUpdateItemId}" '
        'sourceItemId="${row.sourceItemId}" '
        'labelSizeId="${row.labelSizeId}">',
      )
      ..write('<itemName>${_autoItemUpdateXmlText(row.itemName)}</itemName>')
      ..write('<element>${_autoItemUpdateXmlText(row.element)}</element>')
      ..write('<elementRtf>${_autoItemUpdateXmlText(row.elementRtf)}</elementRtf>')
      ..write('<price>${row.price}</price>')
      ..write('<applyDate>${_autoItemUpdateDateText(row.applyDate)}</applyDate>')
      ..write('</row>');
  }
  return (xml..write('</rows>')).toString();
}

String _autoItemUpdateNewRowsXml(
  Iterable<AutoItemUpdateNewRowSave> rows,
) {
  final xml = StringBuffer('<rows>');
  for (final row in rows) {
    xml
      ..write(
        '<row draftRowKey="${_autoItemUpdateXmlText(row.draftRowKey)}" '
        'sourceItemId="${row.sourceItemId}" '
        'labelSizeId="${row.labelSizeId}">',
      )
      ..write('<itemName>${_autoItemUpdateXmlText(row.itemName)}</itemName>')
      ..write('<element>${_autoItemUpdateXmlText(row.element)}</element>')
      ..write('<elementRtf>${_autoItemUpdateXmlText(row.elementRtf)}</elementRtf>')
      ..write('<price>${row.price}</price>')
      ..write('<applyDate>${_autoItemUpdateDateText(row.applyDate)}</applyDate>')
      ..write('</row>');
  }
  return (xml..write('</rows>')).toString();
}

String _autoItemUpdateCellValuesXml(
  Iterable<AutoItemUpdateCellValueSave> values,
) {
  final xml = StringBuffer('<values>');
  for (final value in values) {
    xml.write(
      '<value columnId="${value.columnId}" editable="${value.editable ? 1 : 0}"',
    );
    if (value.sourceUpdateItemId != null) {
      xml.write(' sourceUpdateItemId="${value.sourceUpdateItemId}"');
    }
    xml
      ..write('>')
      ..write(
        '<draftRowKey>${_autoItemUpdateXmlText(value.draftRowKey)}</draftRowKey>',
      )
      ..write(
        '<dataString>${_autoItemUpdateXmlText(value.dataString)}</dataString>',
      )
      ..write('</value>');
  }
  return (xml..write('</values>')).toString();
}

class AutoItemUpdateSaveResult {
  const AutoItemUpdateSaveResult({required this.insertedUpdateItemIdsByRowKey});

  final Map<String, int> insertedUpdateItemIdsByRowKey;
}

class AutoItemUpdateSaveDAO extends DAO {
  static const String saveSql = r'''
    SET XACT_ABORT ON;
    SET NOCOUNT ON;

    DECLARE @DeletedRowsDocument XML = CONVERT(XML, @deletedUpdateItemIdsXml);
    DECLARE @ExistingRowsDocument XML = CONVERT(XML, @existingRowsXml);
    DECLARE @NewRowsDocument XML = CONVERT(XML, @newRowsXml);
    DECLARE @CellValuesDocument XML = CONVERT(XML, @cellValuesXml);

    DECLARE @DeletedRows TABLE (UPDATE_ITEM_ID INT NOT NULL PRIMARY KEY);
    DECLARE @ExistingRows TABLE (
      UPDATE_ITEM_ID INT NOT NULL PRIMARY KEY,
      ITEM_ID INT NOT NULL,
      LABEL_SIZE_ID INT NOT NULL,
      ITEM_NAME NVARCHAR(100) NOT NULL,
      ELEMENT NVARCHAR(MAX) NOT NULL,
      ELEMENT_RTF NVARCHAR(MAX) NOT NULL,
      PRICE INT NOT NULL,
      APPLY_DATE DATETIME NOT NULL
    );
    DECLARE @NewRows TABLE (
      DRAFT_ROW_KEY NVARCHAR(100) NOT NULL PRIMARY KEY,
      ITEM_ID INT NOT NULL,
      LABEL_SIZE_ID INT NOT NULL,
      ITEM_NAME NVARCHAR(100) NOT NULL,
      ELEMENT NVARCHAR(MAX) NOT NULL,
      ELEMENT_RTF NVARCHAR(MAX) NOT NULL,
      PRICE INT NOT NULL,
      APPLY_DATE DATETIME NOT NULL
    );
    DECLARE @CellValues TABLE (
      SOURCE_UPDATE_ITEM_ID INT NULL,
      DRAFT_ROW_KEY NVARCHAR(100) NOT NULL,
      COLUMN_ID INT NOT NULL,
      EDITABLE BIT NOT NULL,
      DATA_STRING NVARCHAR(3000) NOT NULL
    );
    DECLARE @InsertedRows TABLE (
      DRAFT_ROW_KEY NVARCHAR(100) NOT NULL PRIMARY KEY,
      UPDATE_ITEM_ID INT NOT NULL
    );

    INSERT INTO @DeletedRows(UPDATE_ITEM_ID)
    SELECT N.value('@id', 'INT')
    FROM @DeletedRowsDocument.nodes('/rows/row') X(N);

    INSERT INTO @ExistingRows(
      UPDATE_ITEM_ID, ITEM_ID, LABEL_SIZE_ID, ITEM_NAME,
      ELEMENT, ELEMENT_RTF, PRICE, APPLY_DATE
    )
    SELECT
      N.value('@sourceUpdateItemId', 'INT'),
      N.value('@sourceItemId', 'INT'),
      N.value('@labelSizeId', 'INT'),
      N.value('string((itemName/text())[1])', 'NVARCHAR(100)'),
      N.value('string((element/text())[1])', 'NVARCHAR(MAX)'),
      N.value('string((elementRtf/text())[1])', 'NVARCHAR(MAX)'),
      N.value('(price/text())[1]', 'INT'),
      CONVERT(DATETIME, N.value('string((applyDate/text())[1])', 'CHAR(8)'), 112)
    FROM @ExistingRowsDocument.nodes('/rows/row') X(N);

    INSERT INTO @NewRows(
      DRAFT_ROW_KEY, ITEM_ID, LABEL_SIZE_ID, ITEM_NAME,
      ELEMENT, ELEMENT_RTF, PRICE, APPLY_DATE
    )
    SELECT
      N.value('string(@draftRowKey)', 'NVARCHAR(100)'),
      N.value('@sourceItemId', 'INT'),
      N.value('@labelSizeId', 'INT'),
      N.value('string((itemName/text())[1])', 'NVARCHAR(100)'),
      N.value('string((element/text())[1])', 'NVARCHAR(MAX)'),
      N.value('string((elementRtf/text())[1])', 'NVARCHAR(MAX)'),
      N.value('(price/text())[1]', 'INT'),
      CONVERT(DATETIME, N.value('string((applyDate/text())[1])', 'CHAR(8)'), 112)
    FROM @NewRowsDocument.nodes('/rows/row') X(N);

    INSERT INTO @CellValues(
      SOURCE_UPDATE_ITEM_ID, DRAFT_ROW_KEY, COLUMN_ID, EDITABLE, DATA_STRING
    )
    SELECT
      CONVERT(INT, NULLIF(N.value('string(@sourceUpdateItemId)', 'NVARCHAR(20)'), N'')),
      N.value('string((draftRowKey/text())[1])', 'NVARCHAR(100)'),
      N.value('@columnId', 'INT'),
      N.value('@editable', 'BIT'),
      N.value('string((dataString/text())[1])', 'NVARCHAR(3000)')
    FROM @CellValuesDocument.nodes('/values/value') X(N);

    BEGIN TRY
      BEGIN TRANSACTION;

      DELETE C
      FROM BM_UPDATE_COL_CONTENT C
      INNER JOIN @DeletedRows D ON D.UPDATE_ITEM_ID=C.RICH_UPDATE_ITEM_ID;

      DELETE U
      FROM BM_UPDATE_ITEM U
      INNER JOIN @DeletedRows D ON D.UPDATE_ITEM_ID=U.RICH_UPDATE_ITEM_ID;
      IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @DeletedRows)
        THROW 51021, 'Deleted update item count mismatch.', 1;

      UPDATE U SET
        RICH_ITEM_ID=E.ITEM_ID,
        RICH_LABELSIZE_ID=E.LABEL_SIZE_ID,
        RICH_ELEMENT=E.ELEMENT,
        RICH_ELEMENT_RTF=E.ELEMENT_RTF,
        RICH_PRICE=E.PRICE,
        RICH_APPLY_DATE=E.APPLY_DATE,
        RICH_IS_APPLY=0
      FROM BM_UPDATE_ITEM U
      INNER JOIN @ExistingRows E ON E.UPDATE_ITEM_ID=U.RICH_UPDATE_ITEM_ID;
      IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @ExistingRows)
        THROW 51022, 'Existing update item count mismatch.', 1;

      MERGE BM_UPDATE_COL_CONTENT AS TARGET
      USING (
        SELECT SOURCE_UPDATE_ITEM_ID AS UPDATE_ITEM_ID,
          COLUMN_ID, EDITABLE, DATA_STRING
        FROM @CellValues
        WHERE SOURCE_UPDATE_ITEM_ID IS NOT NULL
      ) AS SOURCE
      ON TARGET.RICH_UPDATE_ITEM_ID=SOURCE.UPDATE_ITEM_ID
        AND TARGET.RICH_COLUMN_ID=SOURCE.COLUMN_ID
      WHEN MATCHED THEN UPDATE SET
        RICH_COL_CONTENT_DATA=SOURCE.DATA_STRING
      WHEN NOT MATCHED THEN INSERT (
        RICH_COLUMN_ID, RICH_UPDATE_ITEM_ID, RICH_COL_CONTENT_DATA
      ) VALUES (
        SOURCE.COLUMN_ID, SOURCE.UPDATE_ITEM_ID, SOURCE.DATA_STRING
      );

      MERGE BM_UPDATE_ITEM AS TARGET
      USING @NewRows AS SOURCE
      ON 1 = 0
      WHEN NOT MATCHED THEN INSERT (
        RICH_ITEM_ID,
        RICH_LABELSIZE_ID,
        RICH_ELEMENT,
        RICH_ELEMENT_RTF,
        RICH_PRICE,
        RICH_APPLY_DATE,
        RICH_IS_APPLY
      ) VALUES (
        SOURCE.ITEM_ID,
        SOURCE.LABEL_SIZE_ID,
        SOURCE.ELEMENT,
        SOURCE.ELEMENT_RTF,
        SOURCE.PRICE,
        SOURCE.APPLY_DATE,
        0
      )
      OUTPUT SOURCE.DRAFT_ROW_KEY, INSERTED.RICH_UPDATE_ITEM_ID
      INTO @InsertedRows(DRAFT_ROW_KEY, UPDATE_ITEM_ID);

      IF (SELECT COUNT(*) FROM @InsertedRows) <> (SELECT COUNT(*) FROM @NewRows)
        THROW 51023, 'Inserted update item id mapping count mismatch.', 1;

      INSERT INTO BM_UPDATE_COL_CONTENT (
        RICH_COLUMN_ID, RICH_UPDATE_ITEM_ID, RICH_COL_CONTENT_DATA
      )
      SELECT C.COLUMN_ID, I.UPDATE_ITEM_ID, C.DATA_STRING
      FROM @CellValues C
      INNER JOIN @InsertedRows I ON I.DRAFT_ROW_KEY=C.DRAFT_ROW_KEY
      WHERE C.SOURCE_UPDATE_ITEM_ID IS NULL;

      COMMIT TRANSACTION;

      SELECT DRAFT_ROW_KEY, UPDATE_ITEM_ID FROM @InsertedRows ORDER BY DRAFT_ROW_KEY;
    END TRY
    BEGIN CATCH
      IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
      THROW;
    END CATCH
  ''';

  static DbTransactionStatement buildSaveStatement(
    AutoItemUpdateSaveCommand command,
  ) {
    command.validate();
    return DbTransactionStatement(
      sql: saveSql,
      params: {
        'deletedUpdateItemIdsXml': _autoItemUpdateIdsXml(command.deletedUpdateItemIds),
        'existingRowsXml': _autoItemUpdateExistingRowsXml(command.existingRows),
        'newRowsXml': _autoItemUpdateNewRowsXml(command.newRows),
        'cellValuesXml': _autoItemUpdateCellValuesXml(command.cellValues),
      },
      returnsRows: true,
    );
  }

  static Future<AutoItemUpdateSaveResult> save(
    AutoItemUpdateSaveCommand command,
  ) async {
    final statement = buildSaveStatement(command);
    debugLog(
      '$START, existing:${command.existingRows.length}, '
      'new:${command.newRows.length}, deleted:${command.deletedUpdateItemIds.length}, '
      'cells:${command.cellValues.length}',
    );
    try {
      final results = await DbClient.instance.transaction([statement]);
      final rows = DAO.getRowsFromResult(results.single);
      final inserted = <String, int>{
        for (final rawRow in rows)
          (rawRow as Map<String, dynamic>)['DRAFT_ROW_KEY'].toString():
              int.parse(rawRow['UPDATE_ITEM_ID'].toString()),
      };
      if (inserted.length != command.newRows.length) {
        throw StateError('Inserted update item id mapping count mismatch.');
      }
      debugLog(END);
      return AutoItemUpdateSaveResult(insertedUpdateItemIdsByRowKey: inserted);
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }
}
