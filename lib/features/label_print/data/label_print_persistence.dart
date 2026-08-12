import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/domain/label_print_auto_increment.dart';

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
  final updates = [
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
      'updatesXml': _labelPrintUpdatesXml(updates),
      'historyXml': _labelPrintHistoryXml(historyParents),
    },
  );
}

String _labelPrintUpdatesXml(List<Map<String, Object?>> updates) {
  final xml = StringBuffer('<updates>');
  for (final update in updates) {
    xml
      ..write('<update columnId="${update['columnId']}" ')
      ..write('itemId="${update['itemId']}"><dataString>')
      ..write(_xmlText(update['dataString']))
      ..write('</dataString></update>');
  }
  return (xml..write('</updates>')).toString();
}

String _labelPrintHistoryXml(List<Map<String, Object?>> parents) {
  final xml = StringBuffer('<history>');
  for (final parent in parents) {
    xml.write('<parent');
    for (final name in _labelPrintHistoryNumericFields) {
      xml.write(' $name="${parent[name] ?? 0}"');
    }
    xml.write('>');
    for (final name in _labelPrintHistoryTextFields) {
      xml
        ..write('<$name>')
        ..write(_xmlText(parent[name]))
        ..write('</$name>');
    }
    xml.write('<details>');
    for (final detail
        in (parent['details'] as List<Object?>? ?? const <Object?>[])) {
      final values = detail! as Map<String, Object?>;
      xml
        ..write('<detail detailIndex="${values['detailIndex']}" ')
        ..write('columnId="${values['columnId']}"><columnName>')
        ..write(_xmlText(values['columnName']))
        ..write('</columnName><dataString>')
        ..write(_xmlText(values['dataString']))
        ..write('</dataString></detail>');
    }
    xml.write('</details></parent>');
  }
  return (xml..write('</history>')).toString();
}

String _xmlText(Object? value) => const HtmlEscape(
  HtmlEscapeMode.element,
).convert(value?.toString() ?? '');

const _labelPrintHistoryNumericFields = <String>[
  'parentIndex',
  'userGradeCode',
  'statusUserId',
  'marketId',
  'customerId',
  'brandId',
  'labelSizeId',
  'itemId',
  'printCount',
  'widthMm',
  'heightMm',
  'leftMarginMm',
  'rightMarginMm',
  'topMarginMm',
  'leftPushMm',
  'topPushMm',
  'extraAreaMm',
];

const _labelPrintHistoryTextFields = <String>[
  'userId',
  'userName',
  'userGradeLabel',
  'marketName',
  'customerName',
  'brandName',
  'labelSizeName',
  'printerName',
  'itemName',
  'element',
  'columnsWire',
  'printCellsWire',
  'baselineCellsWire',
];

const String _labelAutoIncrementUpdateSql = r'''
SET NOCOUNT ON;

DECLARE @UpdatesDocument XML = CONVERT(XML, @updatesXml);
DECLARE @HistoryDocument XML = CONVERT(XML, @historyXml);
IF @UpdatesDocument IS NULL OR @HistoryDocument IS NULL
  THROW 51000, '라벨 발행 저장 데이터를 해석할 수 없습니다.', 1;

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
FROM (
  SELECT
    N.value('@columnId', 'INT') AS columnId,
    N.value('@itemId', 'INT') AS itemId,
    N.value('string((dataString/text())[1])', 'NVARCHAR(MAX)') AS dataString
  FROM @UpdatesDocument.nodes('/updates/update') U(N)
) ParsedUpdates;

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
  userId NVARCHAR(30) NOT NULL,
  userName NVARCHAR(100) NOT NULL,
  userGradeCode INT NOT NULL,
  userGradeLabel NVARCHAR(100) NOT NULL,
  statusUserId INT NOT NULL,
  marketId INT NOT NULL,
  marketName NVARCHAR(100) NOT NULL,
  customerId INT NOT NULL,
  customerName NVARCHAR(100) NOT NULL,
  brandId INT NOT NULL,
  brandName NVARCHAR(100) NOT NULL,
  labelSizeId INT NOT NULL,
  labelSizeName NVARCHAR(100) NOT NULL,
  printerName NVARCHAR(300) NOT NULL,
  itemId INT NOT NULL,
  itemName NVARCHAR(300) NOT NULL,
  element NVARCHAR(MAX) NOT NULL,
  printCount INT NOT NULL,
  columnsWire NVARCHAR(MAX) NOT NULL,
  printCellsWire NVARCHAR(MAX) NOT NULL,
  baselineCellsWire NVARCHAR(MAX) NOT NULL,
  widthMm INT NOT NULL,
  heightMm INT NOT NULL,
  leftMarginMm FLOAT NOT NULL,
  rightMarginMm FLOAT NOT NULL,
  topMarginMm FLOAT NOT NULL,
  leftPushMm FLOAT NOT NULL,
  topPushMm FLOAT NOT NULL,
  extraAreaMm FLOAT NOT NULL,
  details XML NOT NULL,
  statusOrder INT NULL,
  statusId NVARCHAR(100) NULL
);

INSERT INTO @History (
  parentIndex, userId, userName, userGradeCode, userGradeLabel, statusUserId,
  marketId, marketName, customerId, customerName, brandId, brandName,
  labelSizeId, labelSizeName, printerName, itemId, itemName, element, printCount,
  columnsWire, printCellsWire, baselineCellsWire, widthMm, heightMm,
  leftMarginMm, rightMarginMm, topMarginMm, leftPushMm, topPushMm, extraAreaMm,
  details
)
SELECT
  N.value('@parentIndex', 'INT'),
  N.value('string((userId/text())[1])', 'NVARCHAR(30)'),
  N.value('string((userName/text())[1])', 'NVARCHAR(100)'),
  N.value('@userGradeCode', 'INT'),
  N.value('string((userGradeLabel/text())[1])', 'NVARCHAR(100)'),
  N.value('@statusUserId', 'INT'),
  N.value('@marketId', 'INT'),
  N.value('string((marketName/text())[1])', 'NVARCHAR(100)'),
  N.value('@customerId', 'INT'),
  N.value('string((customerName/text())[1])', 'NVARCHAR(100)'),
  N.value('@brandId', 'INT'),
  N.value('string((brandName/text())[1])', 'NVARCHAR(100)'),
  N.value('@labelSizeId', 'INT'),
  N.value('string((labelSizeName/text())[1])', 'NVARCHAR(100)'),
  N.value('string((printerName/text())[1])', 'NVARCHAR(300)'),
  N.value('@itemId', 'INT'),
  N.value('string((itemName/text())[1])', 'NVARCHAR(300)'),
  N.value('string((element/text())[1])', 'NVARCHAR(MAX)'),
  N.value('@printCount', 'INT'),
  N.value('string((columnsWire/text())[1])', 'NVARCHAR(MAX)'),
  N.value('string((printCellsWire/text())[1])', 'NVARCHAR(MAX)'),
  N.value('string((baselineCellsWire/text())[1])', 'NVARCHAR(MAX)'),
  N.value('@widthMm', 'INT'), N.value('@heightMm', 'INT'),
  N.value('@leftMarginMm', 'FLOAT'), N.value('@rightMarginMm', 'FLOAT'),
  N.value('@topMarginMm', 'FLOAT'), N.value('@leftPushMm', 'FLOAT'),
  N.value('@topPushMm', 'FLOAT'), N.value('@extraAreaMm', 'FLOAT'),
  N.query('details')
FROM @HistoryDocument.nodes('/history/parent') H(N);

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
  H.userId, H.userName, H.userGradeCode,
  H.marketId, H.marketName, H.customerId, H.customerName,
  H.brandName, H.labelSizeName, H.itemName, H.printCount,
  @historyAt, CONVERT(char(8), @historyAt, 112), H.printerName,
  H.columnsWire, H.printCellsWire, H.baselineCellsWire,
  H.widthMm, H.heightMm,
  H.leftMarginMm, H.rightMarginMm, H.topMarginMm,
  H.leftPushMm, H.topPushMm, H.extraAreaMm,
  H.itemId
FROM @History H;

INSERT INTO BM_RICH_STATUS (
  RICH_STATUS_ID, RICH_ITEM_ID, RICH_MARKET_ID, RICH_CUSTOMER_ID,
  RICH_BRAND_ID, RICH_LABELSIZE_ID, RICH_USER_ID, RICH_PRINT_COUNT,
  RICH_PRINT_DATE, RICH_PRINT_ITEM_NAME, RICH_PRINT_ITEM_ELEMENT,
  RICH_STATUS_ORDER, RICH_LABELSIZE_NAME, RICH_USER_NAME, RICH_USER_GRADE,
  RICH_BRAND_NAME, RICH_DATE_YYYYMMDD
)
SELECT
  H.statusId, H.itemId, H.marketId, H.customerId,
  H.brandId, H.labelSizeId, H.statusUserId, H.printCount,
  CONVERT(char(19), @historyAt, 120) + N'.' +
    CASE WHEN DATEPART(second, @historyAt) * 10 < 10 THEN N'0' ELSE N'' END +
    CONVERT(NVARCHAR(3), DATEPART(second, @historyAt) * 10),
  H.itemName, H.element, H.statusOrder, H.labelSizeName,
  H.userName, H.userGradeLabel, H.brandName,
  CONVERT(char(8), @historyAt, 112)
FROM @History H;

INSERT INTO BM_RICH_STATUS_DATA (
  RICH_STATUS_DATA_ID, RICH_COLUMN_ID, RICH_STATUS_ID,
  RICH_PRINT_COLUMN_DATA, RICH_COLUMN_NAME
)
SELECT
  CONCAT(H.statusId, N'D', D.detailIndex), D.columnId, H.statusId,
  D.dataString, D.columnName
FROM @History H
CROSS APPLY H.details.nodes('/details/detail') X(N)
CROSS APPLY (
  SELECT
    N.value('@detailIndex', 'INT') AS detailIndex,
    N.value('@columnId', 'INT') AS columnId,
    N.value('string((dataString/text())[1])', 'NVARCHAR(MAX)') AS dataString,
    N.value('string((columnName/text())[1])', 'NVARCHAR(300)') AS columnName
) D;
''';