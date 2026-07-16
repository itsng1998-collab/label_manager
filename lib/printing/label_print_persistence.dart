import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/label_print_auto_increment.dart';
import 'package:label_manager/printing/label_print_pipeline.dart';

enum LabelPrintPersistenceState {
  notAttempted,
  succeeded,
  failed,
  outcomeUnknown,
}

@immutable
class LabelPrintPersistenceResult {
  const LabelPrintPersistenceResult({
    required this.state,
    this.error,
    this.committedAutoIncrementValues = const <ColumnItemKey, String>{},
  });

  final LabelPrintPersistenceState state;
  final Object? error;
  final Map<ColumnItemKey, String> committedAutoIncrementValues;
}

typedef LabelPrintTransaction = Future<List<Object>> Function(
  List<DbTransactionStatement> statements,
);

bool labelPrintHistoryEnabledForUserId(
  String userId, {
  String systemUserId = 'SYSTEM',
}) => userId.toLowerCase() != systemUserId.toLowerCase();

@immutable
class LabelPrintHistoryContext {
  const LabelPrintHistoryContext({
    required this.userId,
    required this.userName,
    required this.userGradeCode,
    required this.userGradeLabel,
    required this.marketId,
    required this.marketName,
    required this.customerId,
    required this.customerName,
    required this.brandId,
    required this.brandName,
    required this.labelSizeId,
    required this.labelSizeName,
    required this.printerName,
    required this.extraAreaMm,
  });

  final String userId;
  final String userName;
  final int userGradeCode;
  final String userGradeLabel;
  final int marketId;
  final String marketName;
  final int customerId;
  final String customerName;
  final int brandId;
  final String brandName;
  final int labelSizeId;
  final String labelSizeName;
  final String printerName;
  final double extraAreaMm;
}

List<Map<String, Object?>> buildLabelPrintHistoryParents({
  required List<LabelPrintUnit> acceptedUnits,
  required List<TColumn> columns,
  required Map<ColumnItemKey, TColumnContent> columnContents,
  required LabelPrintHistoryContext context,
}) {
  if (acceptedUnits.isEmpty) return const <Map<String, Object?>>[];
  final orderedColumns = [...columns]
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.columnId.compareTo(right.columnId);
    });
  final hasAutoIncrement = orderedColumns.any((column) => column.autoInc);
  final parentUnits = <({LabelPrintUnit unit, int printCount})>[];
  if (hasAutoIncrement) {
    for (final unit in acceptedUnits) {
      parentUnits.add((unit: unit, printCount: 1));
    }
  } else {
    final byRow = <int, List<LabelPrintUnit>>{};
    for (final unit in acceptedUnits) {
      (byRow[unit.rowIndex] ??= []).add(unit);
    }
    for (final units in byRow.values) {
      parentUnits.add((unit: units.first, printCount: units.length));
    }
  }
  final columnsWire = '주원료|${orderedColumns.map((c) => c.columnName).join('|')}|';
  final statusUserId = legacyAtoi(context.userId);
  return List.unmodifiable([
    for (var parentIndex = 0;
        parentIndex < parentUnits.length;
        parentIndex += 1)
      (() {
        final parent = parentUnits[parentIndex];
        final unit = parent.unit;
        final element = unit.row.item.item.element;
        String projected(TColumn column) =>
            unit.projectedColumnValues[column.columnId] ?? '';
        String baseline(TColumn column) =>
            columnContents[ColumnItemKey(
              columnId: column.columnId,
              itemId: unit.row.itemId,
            )]
                ?.dataString ??
            '';
        return <String, Object?>{
          'parentIndex': parentIndex,
          'userId': context.userId,
          'userName': context.userName,
          'userGradeCode': context.userGradeCode,
          'userGradeLabel': context.userGradeLabel,
          'statusUserId': statusUserId,
          'marketId': context.marketId,
          'marketName': context.marketName,
          'customerId': context.customerId,
          'customerName': context.customerName,
          'brandId': context.brandId,
          'brandName': context.brandName,
          'labelSizeId': context.labelSizeId,
          'labelSizeName': context.labelSizeName,
          'printerName': context.printerName,
          'itemId': unit.row.itemId,
          'itemName': unit.row.item.item.itemName,
          'element': element,
          'printCount': parent.printCount,
          'columnsWire': columnsWire,
          'printCellsWire': '$element|${orderedColumns.map(projected).join('|')}|',
          'baselineCellsWire': '$element|${orderedColumns.map(baseline).join('|')}|',
          'widthMm': unit.row.widthMm,
          'heightMm': unit.row.heightMm,
          'leftMarginMm': unit.row.leftMarginMm,
          'rightMarginMm': unit.row.rightMarginMm,
          'topMarginMm': unit.row.topMarginMm,
          'leftPushMm': unit.row.leftPushMm,
          'topPushMm': unit.row.topPushMm,
          'extraAreaMm': context.extraAreaMm,
          'details': [
            for (var detailIndex = 0;
                detailIndex < orderedColumns.length;
                detailIndex += 1)
              {
                'detailIndex': detailIndex,
                'columnId': orderedColumns[detailIndex].columnId,
                'columnName': orderedColumns[detailIndex].columnName,
                'dataString': projected(orderedColumns[detailIndex]),
              },
          ],
        };
      })(),
  ]);
}

Map<ColumnItemKey, String> buildAcceptedAutoIncrementValues({
  required List<LabelPrintUnit> acceptedUnits,
  required List<TColumn> columns,
  required Map<ColumnItemKey, TColumnContent> columnContents,
  required DateTime referenceAt,
}) {
  final maxCopyIndexByItem = <int, int>{};
  for (final unit in acceptedUnits) {
    final itemId = unit.row.itemId;
    final previous = maxCopyIndexByItem[itemId];
    if (previous == null || unit.copyIndex > previous) {
      maxCopyIndexByItem[itemId] = unit.copyIndex;
    }
  }
  final updates = <ColumnItemKey, String>{};
  for (final column in columns) {
    if (!column.autoInc) continue;
    for (final entry in maxCopyIndexByItem.entries) {
      final key = ColumnItemKey(columnId: column.columnId, itemId: entry.key);
      final original = columnContents[key]?.dataString ?? '';
      final isBarcode = column.columnType.code == TColumnType.TYPE_BARCODE;
      if (!labelAutoIncrementApplies(
        original: original,
        autoIncRange: column.autoIncRange,
        timeBarcodeSuffixLength: labelTimeBarcodeSuffixLength(column),
        hasBarcodeCheckDigit: isBarcode && column.useBarcodeCheckDigit,
      )) {
        continue;
      }
      final saveIndex = entry.value + (column.autoIncSave ? 1 : 0);
      updates[key] = projectLabelPrintColumnValues(
        itemId: entry.key,
        copyIndex: saveIndex,
        columns: columns,
        columnContents: columnContents,
        referenceAt: referenceAt,
      )[column.columnId]!;
    }
  }
  return Map.unmodifiable(updates);
}

class LabelPrintPersistenceService {
  LabelPrintPersistenceService({LabelPrintTransaction? transaction})
    : _transaction = transaction ?? DbClient.instance.transaction;

  final LabelPrintTransaction _transaction;

  Future<LabelPrintPersistenceResult> saveAutoIncrementValues(
    Map<ColumnItemKey, String> values,
  ) => save(values: values);

  Future<LabelPrintPersistenceResult> save({
    Map<ColumnItemKey, String> values = const <ColumnItemKey, String>{},
    List<Map<String, Object?>> historyParents =
        const <Map<String, Object?>>[],
  }) async {
    if (values.isEmpty && historyParents.isEmpty) {
      return const LabelPrintPersistenceResult(
        state: LabelPrintPersistenceState.notAttempted,
      );
    }
    final committed = Map<ColumnItemKey, String>.unmodifiable(values);
    try {
      await _transaction([
        buildLabelPrintPersistenceStatement(
          values: committed,
          historyParents: historyParents,
        ),
      ]);
      return LabelPrintPersistenceResult(
        state: LabelPrintPersistenceState.succeeded,
        committedAutoIncrementValues: committed,
      );
    } on DbCommitOutcomeUnknown catch (error) {
      return LabelPrintPersistenceResult(
        state: LabelPrintPersistenceState.outcomeUnknown,
        error: error,
      );
    } catch (error) {
      return LabelPrintPersistenceResult(
        state: LabelPrintPersistenceState.failed,
        error: error,
      );
    }
  }
}

DbTransactionStatement buildLabelAutoIncrementUpdateStatement(
  Map<ColumnItemKey, String> values,
) => buildLabelPrintPersistenceStatement(values: values);

DbTransactionStatement buildLabelPrintPersistenceStatement({
  Map<ColumnItemKey, String> values = const <ColumnItemKey, String>{},
  List<Map<String, Object?>> historyParents =
      const <Map<String, Object?>>[],
}) {
  final payload = [
    for (final entry in values.entries)
      {
        'columnId': entry.key.columnId,
        'itemId': entry.key.itemId,
        'dataString': entry.value,
      },
  ]..sort((left, right) {
    final column = (left['columnId'] as int).compareTo(
      right['columnId'] as int,
    );
    return column != 0
        ? column
        : (left['itemId'] as int).compareTo(right['itemId'] as int);
  });
  return DbTransactionStatement(
    sql: _labelAutoIncrementUpdateSql,
    params: {
      'updatesJson': jsonEncode(payload),
      'historyJson': jsonEncode(historyParents),
    },
  );
}

const String _labelAutoIncrementUpdateSql = r'''
SET NOCOUNT ON;

DECLARE @Updates TABLE (
  RICH_COLUMN_ID INT NOT NULL,
  RICH_ITEM_ID INT NOT NULL,
  RICH_COL_CONTENT_DATA NVARCHAR(MAX) NOT NULL,
  PRIMARY KEY (RICH_COLUMN_ID, RICH_ITEM_ID)
);

INSERT INTO @Updates (
  RICH_COLUMN_ID,
  RICH_ITEM_ID,
  RICH_COL_CONTENT_DATA
)
SELECT columnId, itemId, dataString
FROM OPENJSON(@updatesJson) WITH (
  columnId INT '$.columnId',
  itemId INT '$.itemId',
  dataString NVARCHAR(MAX) '$.dataString'
);

UPDATE C
SET C.RICH_COL_CONTENT_DATA = U.RICH_COL_CONTENT_DATA
FROM BM_RICH_COL_CONTENT C
INNER JOIN @Updates U
  ON U.RICH_COLUMN_ID = C.RICH_COLUMN_ID
 AND U.RICH_ITEM_ID = C.RICH_ITEM_ID;

DECLARE @AffectedRows INT = @@ROWCOUNT;
DECLARE @ExpectedRows INT = (SELECT COUNT(*) FROM @Updates);
IF @AffectedRows <> @ExpectedRows
  THROW 51000, '자동증가 값 갱신 행 수가 예상과 다릅니다.', 1;

DECLARE @historyAt DATETIME = GETDATE();
DECLARE @History TABLE (
  parentIndex INT NOT NULL,
  customerId INT NOT NULL,
  brandId INT NOT NULL,
  payload NVARCHAR(MAX) NOT NULL,
  statusOrder INT NULL,
  statusId NVARCHAR(100) NULL
);

INSERT INTO @History (parentIndex, customerId, brandId, payload)
SELECT parentIndex, customerId, brandId, value
FROM OPENJSON(@historyJson) WITH (
  parentIndex INT '$.parentIndex',
  customerId INT '$.customerId',
  brandId INT '$.brandId',
  value NVARCHAR(MAX) '$' AS JSON
);

;WITH CustomerBase AS (
  SELECT H.customerId, COALESCE(MAX(S.RICH_STATUS_ORDER), 0) AS baseOrder
  FROM (SELECT DISTINCT customerId FROM @History) H
  LEFT JOIN BM_RICH_STATUS S ON S.RICH_CUSTOMER_ID = H.customerId
  GROUP BY H.customerId
), Ordered AS (
  SELECT H.parentIndex,
    B.baseOrder + ROW_NUMBER() OVER (
      PARTITION BY H.customerId ORDER BY H.parentIndex
    ) AS statusOrder
  FROM @History H
  INNER JOIN CustomerBase B ON B.customerId = H.customerId
)
UPDATE H SET
  statusOrder = O.statusOrder,
  statusId = CONCAT(H.customerId, N'-', H.brandId, N'-', O.statusOrder)
FROM @History H
INNER JOIN Ordered O ON O.parentIndex = H.parentIndex;

INSERT INTO BM_RICH_PRINT_LOG (
  RICH_USER_ID, RICH_USER_NAME, RICH_USER_GRADE,
  RICH_MARKET_ID, RICH_MARKET_NAME, RICH_CUSTOMER_ID, RICH_CUSTOMER_NAME,
  RICH_BRAND_NAME, RICH_LABELSIZE_NAME, RICH_ITEM_NAME, RICH_PRINT_COUNT,
  RICH_DATETIME, RICH_DATE_YYYYMMDD, RICH_PRINTER,
  RICH_COLUMNS, RICH_PRINT_CELLS, RICH_SAVE_IN_DB_CELLS,
  RICH_FORM_WIDTH, RICH_FORM_HEIGHT,
  RICH_PRINT_LEFT_MARGIN, RICH_PRINT_RIGHT_MARGIN, RICH_PRINT_TOP_MARGIN,
  RICH_PRINT_LEFT_PUSH, RICH_PRINT_TOP_PUSH, RICH_PRINT_APPENDANT,
  RICH_ITEM_ID
)
SELECT
  J.userId, J.userName, J.userGradeCode,
  J.marketId, J.marketName, J.customerId, J.customerName,
  J.brandName, J.labelSizeName, J.itemName, J.printCount,
  @historyAt, CONVERT(char(8), @historyAt, 112), J.printerName,
  J.columnsWire, J.printCellsWire, J.baselineCellsWire,
  J.widthMm, J.heightMm,
  J.leftMarginMm, J.rightMarginMm, J.topMarginMm,
  J.leftPushMm, J.topPushMm, J.extraAreaMm,
  J.itemId
FROM @History H
CROSS APPLY OPENJSON(H.payload) WITH (
  userId NVARCHAR(30) '$.userId', userName NVARCHAR(100) '$.userName',
  userGradeCode INT '$.userGradeCode', marketId INT '$.marketId',
  marketName NVARCHAR(100) '$.marketName', customerId INT '$.customerId',
  customerName NVARCHAR(100) '$.customerName', brandName NVARCHAR(100) '$.brandName',
  labelSizeName NVARCHAR(100) '$.labelSizeName', itemName NVARCHAR(300) '$.itemName',
  printCount INT '$.printCount', printerName NVARCHAR(300) '$.printerName',
  columnsWire NVARCHAR(MAX) '$.columnsWire', printCellsWire NVARCHAR(MAX) '$.printCellsWire',
  baselineCellsWire NVARCHAR(MAX) '$.baselineCellsWire', widthMm INT '$.widthMm',
  heightMm INT '$.heightMm', leftMarginMm FLOAT '$.leftMarginMm',
  rightMarginMm FLOAT '$.rightMarginMm', topMarginMm FLOAT '$.topMarginMm',
  leftPushMm FLOAT '$.leftPushMm', topPushMm FLOAT '$.topPushMm',
  extraAreaMm FLOAT '$.extraAreaMm', itemId INT '$.itemId'
) J;

INSERT INTO BM_RICH_STATUS (
  RICH_STATUS_ID, RICH_ITEM_ID, RICH_MARKET_ID, RICH_CUSTOMER_ID,
  RICH_BRAND_ID, RICH_LABELSIZE_ID, RICH_USER_ID, RICH_PRINT_COUNT,
  RICH_PRINT_DATE, RICH_PRINT_ITEM_NAME, RICH_PRINT_ITEM_ELEMENT,
  RICH_STATUS_ORDER, RICH_LABELSIZE_NAME, RICH_USER_NAME, RICH_USER_GRADE,
  RICH_BRAND_NAME, RICH_DATE_YYYYMMDD
)
SELECT
  H.statusId, J.itemId, J.marketId, J.customerId,
  H.brandId, J.labelSizeId, J.statusUserId, J.printCount,
  CONVERT(char(19), @historyAt, 120) + N'.' +
    CASE WHEN DATEPART(second, @historyAt) * 10 < 10 THEN N'0' ELSE N'' END +
    CONVERT(NVARCHAR(3), DATEPART(second, @historyAt) * 10),
  J.itemName, J.element, H.statusOrder, J.labelSizeName,
  J.userName, J.userGradeLabel, J.brandName,
  CONVERT(char(8), @historyAt, 112)
FROM @History H
CROSS APPLY OPENJSON(H.payload) WITH (
  itemId INT '$.itemId', marketId INT '$.marketId', customerId INT '$.customerId',
  labelSizeId INT '$.labelSizeId', statusUserId INT '$.statusUserId',
  printCount INT '$.printCount', itemName NVARCHAR(300) '$.itemName',
  element NVARCHAR(MAX) '$.element', labelSizeName NVARCHAR(100) '$.labelSizeName',
  userName NVARCHAR(100) '$.userName', userGradeLabel NVARCHAR(100) '$.userGradeLabel',
  brandName NVARCHAR(100) '$.brandName'
) J;

INSERT INTO BM_RICH_STATUS_DATA (
  RICH_STATUS_DATA_ID, RICH_COLUMN_ID, RICH_STATUS_ID,
  RICH_PRINT_COLUMN_DATA, RICH_COLUMN_NAME
)
SELECT
  CONCAT(H.statusId, N'D', D.detailIndex), D.columnId, H.statusId,
  D.dataString, D.columnName
FROM @History H
CROSS APPLY OPENJSON(H.payload, '$.details') WITH (
  detailIndex INT '$.detailIndex', columnId INT '$.columnId',
  dataString NVARCHAR(MAX) '$.dataString', columnName NVARCHAR(300) '$.columnName'
) D;
''';