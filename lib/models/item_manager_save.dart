import 'dart:convert';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/item_manager_debug_log.dart';
import 'package:label_manager/utils/log_context.dart';

class ItemSaveSchemaCapabilities {
  final bool hasRichElementSheet;

  const ItemSaveSchemaCapabilities({required this.hasRichElementSheet});

  factory ItemSaveSchemaCapabilities.fromMap(Map<String, dynamic> map) {
    bool flag(String key) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      return value?.toString() == '1';
    }

    return ItemSaveSchemaCapabilities(
      hasRichElementSheet: flag('HAS_RICH_ELEMENT_SHEET'),
    );
  }
}

class ItemSaveSchemaCapabilityDAO extends DAO {
  static ItemSaveSchemaCapabilities? _cached;

  static const String probeSql = '''
    SELECT
      CASE WHEN COL_LENGTH(N'BM_RICH_ITEM', N'RICH_ELEMENT_SHEET') IS NULL
        THEN 0 ELSE 1 END AS HAS_RICH_ELEMENT_SHEET;
  ''';

  static Future<ItemSaveSchemaCapabilities> probe({bool force = false}) async {
    if (!force && _cached != null) return _cached!;
    debugLog('$START, force:$force');
    try {
      final result = await DbClient.instance.getData(probeSql);
      final capabilities = DAO.mapRow(
        result,
        ItemSaveSchemaCapabilities.fromMap,
      )!;
      _cached = capabilities;
      debugLog(
        '$END, hasRichElementSheet:${capabilities.hasRichElementSheet}, '
      );
      return capabilities;
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static void clearCache() {
    _cached = null;
  }
}

class ItemManagerNewMappingDefaults {
  final int gdsNo;
  final DateTime? dateSaleStart;
  final DateTime? dateSaleEnd;
  final double discountPercent;
  final int discountAmount;
  final DateTime? dateStartDiscount;
  final DateTime? dateEndDiscount;
  final bool useDefineElement;
  final String rtfText;
  final bool useLinefeed;
  final int linefeed;
  final bool useScaleBarcode;
  final int printCount;
  final bool useLabelSize;
  final int labelSizeWidth;
  final int labelSizeHeight;
  final bool useMargin;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;

  const ItemManagerNewMappingDefaults({
    this.gdsNo = 0,
    this.dateSaleStart,
    this.dateSaleEnd,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.dateStartDiscount,
    this.dateEndDiscount,
    this.useDefineElement = false,
    this.rtfText = '',
    this.useLinefeed = false,
    this.linefeed = 100,
    this.useScaleBarcode = false,
    this.printCount = 1,
    this.useLabelSize = false,
    this.labelSizeWidth = 0,
    this.labelSizeHeight = 0,
    this.useMargin = false,
    this.leftMargin = 0,
    this.rightMargin = 0,
    this.topMargin = 0,
    this.leftPush = 0,
    this.topPush = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'gdsNo': gdsNo,
      'dateSaleStart': dateSaleStart?.toIso8601String(),
      'dateSaleEnd': dateSaleEnd?.toIso8601String(),
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'dateStartDiscount': dateStartDiscount?.toIso8601String(),
      'dateEndDiscount': dateEndDiscount?.toIso8601String(),
      'useDefineElement': useDefineElement,
      'rtfText': rtfText,
      'useLinefeed': useLinefeed,
      'linefeed': linefeed,
      'useScaleBarcode': useScaleBarcode,
      'printCount': printCount,
      'useLabelSize': useLabelSize,
      'labelSizeWidth': labelSizeWidth,
      'labelSizeHeight': labelSizeHeight,
      'useMargin': useMargin,
      'leftMargin': leftMargin,
      'rightMargin': rightMargin,
      'topMargin': topMargin,
      'leftPush': leftPush,
      'topPush': topPush,
    };
  }
}

class ItemManagerExistingRowSave {
  final int sourceItemId;
  final String itemName;
  final String elementPlain;
  final String elementSheet;
  final int order;

  const ItemManagerExistingRowSave({
    required this.sourceItemId,
    required this.itemName,
    required this.elementPlain,
    required this.elementSheet,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'sourceItemId': sourceItemId,
    'itemName': itemName,
    'elementPlain': elementPlain,
    'elementSheet': elementSheet,
    'order': order,
  };
}

class ItemManagerNewRowSave {
  final String draftRowKey;
  final int labelSizeId;
  final String itemName;
  final String elementPlain;
  final String elementSheet;
  final int order;
  final ItemManagerNewMappingDefaults mappingDefaults;

  const ItemManagerNewRowSave({
    required this.draftRowKey,
    required this.labelSizeId,
    required this.itemName,
    required this.elementPlain,
    required this.elementSheet,
    required this.order,
    this.mappingDefaults = const ItemManagerNewMappingDefaults(),
  });

  Map<String, dynamic> toJson() => {
    'draftRowKey': draftRowKey,
    'labelSizeId': labelSizeId,
    'itemName': itemName,
    'elementPlain': elementPlain,
    'elementSheet': elementSheet,
    'order': order,
    ...mappingDefaults.toJson(),
  };
}

class ItemManagerColumnValueSave {
  final int? sourceItemId;
  final String? draftRowKey;
  final int columnId;
  final bool editable;
  final String dataString;

  const ItemManagerColumnValueSave({
    this.sourceItemId,
    this.draftRowKey,
    required this.columnId,
    this.editable = true,
    required this.dataString,
  });

  Map<String, dynamic> toJson() => {
    'sourceItemId': sourceItemId,
    'draftRowKey': draftRowKey,
    'columnId': columnId,
    'editable': editable,
    'dataString': dataString,
  };
}

class ItemManagerSaveCommand {
  final List<int> targetMarketIds;
  final List<int> deletedSourceItemIds;
  final List<ItemManagerExistingRowSave> existingRows;
  final List<ItemManagerNewRowSave> newRows;
  final List<ItemManagerColumnValueSave> columnValues;

  const ItemManagerSaveCommand({
    required this.targetMarketIds,
    this.deletedSourceItemIds = const [],
    this.existingRows = const [],
    this.newRows = const [],
    this.columnValues = const [],
  });

  void validate() {
    void requireUniquePositive(Iterable<int> values, String field) {
      final list = values.toList();
      if (list.any((value) => value <= 0) ||
          list.toSet().length != list.length) {
        throw ArgumentError('$field requires unique positive ids.');
      }
    }

    requireUniquePositive(targetMarketIds, 'targetMarketIds');
    requireUniquePositive(deletedSourceItemIds, 'deletedSourceItemIds');
    requireUniquePositive(
      existingRows.map((row) => row.sourceItemId),
      'existingRows.sourceItemId',
    );
    final draftKeys = newRows.map((row) => row.draftRowKey).toList();
    if (draftKeys.any((key) => key.trim().isEmpty) ||
        draftKeys.toSet().length != draftKeys.length) {
      throw ArgumentError('newRows.draftRowKey requires unique values.');
    }
    if (newRows.isNotEmpty && targetMarketIds.isEmpty) {
      throw ArgumentError('New rows require targetMarketIds.');
    }
    for (final value in columnValues) {
      final hasSource = value.sourceItemId != null;
      final hasDraft = value.draftRowKey?.isNotEmpty == true;
      if (hasSource == hasDraft || value.columnId <= 0) {
        throw ArgumentError(
          'Column values require one row identity and a positive column id.',
        );
      }
    }
  }

  Map<String, dynamic> toSqlParams() {
    validate();
    return {
      'targetMarketIdsJson': jsonEncode(targetMarketIds),
      'deletedItemIdsJson': jsonEncode(deletedSourceItemIds),
      'existingRowsJson': jsonEncode(
        existingRows.map((row) => row.toJson()).toList(growable: false),
      ),
      'newRowsJson': jsonEncode(
        newRows.map((row) => row.toJson()).toList(growable: false),
      ),
      'columnValuesJson': jsonEncode(
        columnValues.map((value) => value.toJson()).toList(growable: false),
      ),
    };
  }
}

class ItemManagerSaveResult {
  final Map<String, int> insertedItemIdsByDraftKey;

  const ItemManagerSaveResult({required this.insertedItemIdsByDraftKey});
}

class ItemManagerSaveDAO extends DAO {
  static const String saveSql = r'''
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
    SELECT CONVERT(INT, [key]) + 1, J.*
    FROM OPENJSON(@newRowsJson) N
    CROSS APPLY OPENJSON(N.value) WITH (
      DRAFT_ROW_KEY NVARCHAR(100) '$.draftRowKey',
      LABELSIZE_ID INT '$.labelSizeId',
      ITEM_NAME NVARCHAR(100) '$.itemName',
      ELEMENT_PLAIN NVARCHAR(MAX) '$.elementPlain',
      ELEMENT_SHEET NVARCHAR(MAX) '$.elementSheet',
      ITEM_ORDER INT '$.order',
      GDS_NO INT '$.gdsNo',
      SALE_START_DATE DATETIME2 '$.dateSaleStart',
      SALE_END_DATE DATETIME2 '$.dateSaleEnd',
      DISCOUNT_PERCENT FLOAT '$.discountPercent',
      DISCOUNT_AMOUNT INT '$.discountAmount',
      DISCOUNT_START_DATE DATETIME2 '$.dateStartDiscount',
      DISCOUNT_END_DATE DATETIME2 '$.dateEndDiscount',
      USE_DEFINE_ELEMENT BIT '$.useDefineElement',
      USER_DEFINE_RTF NVARCHAR(MAX) '$.rtfText',
      USE_LINEFEED BIT '$.useLinefeed',
      LINEFEED INT '$.linefeed',
      USE_SCALEBARCODE BIT '$.useScaleBarcode',
      PRINT_COUNT INT '$.printCount',
      USE_LABELSIZE BIT '$.useLabelSize',
      LABELSIZE_WIDTH INT '$.labelSizeWidth',
      LABELSIZE_HEIGHT INT '$.labelSizeHeight',
      USE_MARGIN BIT '$.useMargin',
      LEFT_MARGIN FLOAT '$.leftMargin',
      RIGHT_MARGIN FLOAT '$.rightMargin',
      TOP_MARGIN FLOAT '$.topMargin',
      LEFT_PUSH FLOAT '$.leftPush',
      TOP_PUSH FLOAT '$.topPush'
    ) J;

    UPDATE I SET
      RICH_ITEM_NAME=E.ITEM_NAME,
      RICH_ELEMENT=E.ELEMENT_PLAIN,
      RICH_ELEMENT_SHEET=E.ELEMENT_SHEET,
      RICH_ITEM_ORDER=E.ITEM_ORDER
    FROM BM_RICH_ITEM I
    INNER JOIN OPENJSON(@existingRowsJson) WITH (
      ITEM_ID INT '$.sourceItemId',
      ITEM_NAME NVARCHAR(100) '$.itemName',
      ELEMENT_PLAIN NVARCHAR(MAX) '$.elementPlain',
      ELEMENT_SHEET NVARCHAR(MAX) '$.elementSheet',
      ITEM_ORDER INT '$.order'
    ) E ON I.RICH_ITEM_ID=E.ITEM_ID;
    IF @@ROWCOUNT <> (SELECT COUNT(*) FROM OPENJSON(@existingRowsJson))
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
    CROSS JOIN OPENJSON(@targetMarketIdsJson) WITH (MARKET_ID INT '$') M;

    DELETE M
    FROM BM_ITEM_OF_MARKET M
    INNER JOIN OPENJSON(@deletedItemIdsJson) WITH (ITEM_ID INT '$') D
      ON M.RICH_ITEM_ID=D.ITEM_ID;

    MERGE BM_RICH_COL_CONTENT AS TARGET
    USING (
      SELECT COALESCE(C.SOURCE_ITEM_ID, I.ITEM_ID) AS ITEM_ID,
        C.COLUMN_ID, C.EDITABLE, C.DATA_STRING
      FROM OPENJSON(@columnValuesJson) WITH (
        SOURCE_ITEM_ID INT '$.sourceItemId',
        DRAFT_ROW_KEY NVARCHAR(100) '$.draftRowKey',
        COLUMN_ID INT '$.columnId',
        EDITABLE BIT '$.editable',
        DATA_STRING NVARCHAR(3000) '$.dataString'
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
    ItemSaveSchemaCapabilities capabilities,
  ) async {
    final trace = ItemManagerDebugLog.nextTrace('saveDao');
    if (!capabilities.hasRichElementSheet) {
      throw StateError(
        'BM_RICH_ITEM.RICH_ELEMENT_SHEET migration is required.',
      );
    }
    final params = command.toSqlParams();
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
