import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';

String itemManagerDraftKey({
  required String userId,
  required int customerId,
  required int brandId,
  required int labelSizeId,
}) => '${userId}_${customerId}_${brandId}_$labelSizeId';

enum ItemManagerDraftBackupMode { delta, fullImport }

class ItemManagerDraftBackupMetadata {
  const ItemManagerDraftBackupMetadata({
    required this.draftKey,
    required this.userId,
    required this.customerId,
    required this.brandId,
    required this.labelSizeId,
    required this.currentMarketId,
  });

  final String draftKey;
  final String userId;
  final int customerId;
  final int brandId;
  final int labelSizeId;
  final int currentMarketId;

  void validate() {
    if (draftKey.trim().isEmpty ||
        userId.trim().isEmpty ||
        customerId <= 0 ||
        brandId <= 0 ||
        labelSizeId <= 0 ||
        currentMarketId <= 0) {
      throw ArgumentError('Draft backup metadata identities are required.');
    }
  }
}

class ItemManagerDraftBackupSnapshot {
  const ItemManagerDraftBackupSnapshot({
    required this.mode,
    required this.itemNames,
    required this.elements,
    required this.cells,
    required this.orders,
    required this.addedRowKeys,
    required this.deletedRows,
    required this.deletedColumns,
    required this.selectedRowKeys,
    this.anchorRowKey,
  });

  final ItemManagerDraftBackupMode mode;
  final Map<int, String> itemNames;
  final Map<int, ({String plain, String payload})> elements;
  final Map<ColumnItemKey, TColumnContent> cells;
  final Map<int, ({int originalIndex, int order})> orders;
  final Set<String> addedRowKeys;
  final Map<int, ItemManagerDraftRow> deletedRows;
  final Map<ColumnItemKey, TColumnContent> deletedColumns;
  final Set<String> selectedRowKeys;
  final String? anchorRowKey;
}

class ItemManagerDraftBackupStore {
  ItemManagerDraftBackupStore({
    required this.metadata,
    Future<Directory> Function()? directoryProvider,
    DatabaseFactory? databaseFactory,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _databaseFactory = databaseFactory;

  static const int schemaVersion = 1;

  final ItemManagerDraftBackupMetadata metadata;
  final Future<Directory> Function() _directoryProvider;
  final DatabaseFactory? _databaseFactory;
  Database? _database;
  String? _databasePath;
  bool _started = false;

  Future<void> start({
    required Iterable<String> selectedRowKeys,
    String? anchorRowKey,
  }) async {
    if (_started) return;
    metadata.validate();
    final database = await _open();
    await database.transaction((transaction) async {
      for (final table in [
        'item_name_before',
        'element_before',
        'cell_before',
        'order_before',
        'added_row',
        'deleted_row',
        'deleted_cell',
      ]) {
        await transaction.delete(table);
      }
      await transaction.delete('draft_session');
      await transaction.insert('draft_session', {
        'session_id': 1,
        'schema_version': schemaVersion,
        'backup_mode': ItemManagerDraftBackupMode.delta.name,
        'draft_key': metadata.draftKey,
        'user_id': metadata.userId,
        'customer_id': metadata.customerId,
        'brand_id': metadata.brandId,
        'label_size_id': metadata.labelSizeId,
        'current_market_id': metadata.currentMarketId,
        'selected_row_keys_json': jsonEncode(selectedRowKeys.toList()),
        'anchor_row_key': anchorRowKey,
      });
    });
    _started = true;
  }

  Future<void> captureItemName(ItemManagerDraftRow row) async {
    final itemId = _sourceItemId(row);
    await (await _open()).insert('item_name_before', {
      'item_id': itemId,
      'item_name': row.source!.item.itemName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureElement(ItemManagerDraftRow row) async {
    final itemId = _sourceItemId(row);
    await (await _open()).insert('element_before', {
      'item_id': itemId,
      'element_plain': row.source!.item.element,
      'element_payload': row.source!.item.elementRTF,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureCell({
    required ItemManagerDraftRow row,
    required int columnId,
    required TColumnContent? original,
  }) async {
    final itemId = _sourceItemId(row);
    await (await _open()).insert('cell_before', {
      'item_id': itemId,
      'column_id': columnId,
      'col_content_id': original?.colContentId ?? 0,
      'editable': original?.editable == true ? 1 : 0,
      'data_string': original?.dataString ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureCells({
    required ItemManagerDraftRow row,
    required Iterable<int> columnIds,
    required TColumnContentScopedView columnContents,
  }) async {
    final itemId = _sourceItemId(row);
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final columnId in columnIds.toSet()) {
        final original = columnContents.get(columnId, itemId);
        batch.insert('cell_before', {
          'item_id': itemId,
          'column_id': columnId,
          'col_content_id': original?.colContentId ?? 0,
          'editable': original?.editable == true ? 1 : 0,
          'data_string': original?.dataString ?? '',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> captureOrders(Iterable<ItemManagerDraftRow> rows) async {
    final existingRows = rows.where((row) => row.sourceItemId != null).toList();
    if (existingRows.isEmpty) return;
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final row in existingRows) {
        batch.insert('order_before', {
          'item_id': row.sourceItemId,
          'original_index': row.originalIndex,
          'item_order': row.source!.item.order,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> recordAddedRows(Iterable<String> rowKeys) async {
    final keys = rowKeys.toSet();
    if (keys.isEmpty) return;
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final rowKey in keys) {
        batch.insert('added_row', {
          'row_key': rowKey,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> captureDeletedRows({
    required Iterable<ItemManagerDraftRow> rows,
    required TColumnContentScopedView columnContents,
  }) async {
    final existingRows = rows.where((row) => row.sourceItemId != null).toList();
    if (existingRows.isEmpty) return;
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final row in existingRows) {
        final itemId = row.sourceItemId!;
        batch.insert('deleted_row', {
          'item_id': itemId,
          'original_index': row.originalIndex,
          'row_json': jsonEncode(_rowToJson(row)),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final content in columnContents.values.values) {
          if (content.itemId != itemId) continue;
          batch.insert('deleted_cell', _columnToMap(content),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> captureFullImport(ItemManagerDraftController controller) async {
    final database = await _open();
    await database.transaction((transaction) async {
      await transaction.update('draft_session', {
        'backup_mode': ItemManagerDraftBackupMode.fullImport.name,
      }, where: 'session_id = 1');
      final batch = transaction.batch();
      for (final row in controller.rows) {
        final itemId = row.sourceItemId;
        if (itemId == null) continue;
        batch.insert('deleted_row', {
          'item_id': itemId,
          'original_index': row.originalIndex,
          'row_json': jsonEncode(_rowToJson(row)),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final content in controller.scopedColumnContents.values.values) {
        batch.insert('deleted_cell', _columnToMap(content),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<ItemManagerDraftBackupSnapshot> readSnapshot() async {
    final database = await _open();
    final sessionRows = await database.query('draft_session', limit: 1);
    if (sessionRows.isEmpty) {
      throw StateError('Item manager draft backup session is missing.');
    }
    final session = sessionRows.single;
    _validateSession(session);
    final itemNames = <int, String>{
      for (final row in await database.query('item_name_before'))
        row['item_id']! as int: row['item_name']! as String,
    };
    final elements = <int, ({String plain, String payload})>{
      for (final row in await database.query('element_before'))
        row['item_id']! as int: (
          plain: row['element_plain']! as String,
          payload: row['element_payload']! as String,
        ),
    };
    final cells = <ColumnItemKey, TColumnContent>{};
    for (final row in await database.query('cell_before')) {
      final content = _columnFromMap(row);
      cells[ColumnItemKey(columnId: content.columnId, itemId: content.itemId)] =
          content;
    }
    final orders = <int, ({int originalIndex, int order})>{
      for (final row in await database.query('order_before'))
        row['item_id']! as int: (
          originalIndex: row['original_index']! as int,
          order: row['item_order']! as int,
        ),
    };
    final deletedRows = <int, ItemManagerDraftRow>{};
    for (final row in await database.query('deleted_row')) {
      final itemId = row['item_id']! as int;
      final json = jsonDecode(row['row_json']! as String);
      deletedRows[itemId] = _rowFromJson(Map<String, dynamic>.from(json as Map));
    }
    final deletedColumns = <ColumnItemKey, TColumnContent>{};
    for (final row in await database.query('deleted_cell')) {
      final content = _columnFromMap(row);
      deletedColumns[
          ColumnItemKey(columnId: content.columnId, itemId: content.itemId)] =
          content;
    }
    final selectedRows = jsonDecode(session['selected_row_keys_json']! as String);
    return ItemManagerDraftBackupSnapshot(
      mode: ItemManagerDraftBackupMode.values.byName(
        session['backup_mode']! as String,
      ),
      itemNames: itemNames,
      elements: elements,
      cells: cells,
      orders: orders,
      addedRowKeys: {
        for (final row in await database.query('added_row'))
          row['row_key']! as String,
      },
      deletedRows: deletedRows,
      deletedColumns: deletedColumns,
      selectedRowKeys: Set<String>.from(selectedRows as List),
      anchorRowKey: session['anchor_row_key'] as String?,
    );
  }

  Future<void> clear() async {
    final path = _databasePath ?? await _resolveDatabasePath();
    await _database?.close();
    _database = null;
    _started = false;
    await _deleteDatabaseFiles(path);
  }

  Future<void> close({bool deleteFile = true}) async {
    if (deleteFile) {
      await clear();
      return;
    }
    await _database?.close();
    _database = null;
    _started = false;
  }

  Future<Database> _open() async {
    final current = _database;
    if (current != null) return current;
    final path = await _resolveDatabasePath();
    final factory = _databaseFactory ?? _defaultDatabaseFactory();
    final options = OpenDatabaseOptions(
      version: schemaVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await database.execute('PRAGMA journal_mode = WAL');
        await database.execute('PRAGMA synchronous = NORMAL');
      },
      onCreate: (database, _) => _createSchema(database),
      onUpgrade: (database, _, _) async {
        throw StateError('Temporary draft backup schema changed.');
      },
      onDowngrade: (database, _, _) async {
        throw StateError('Temporary draft backup schema changed.');
      },
    );
    late final Database database;
    try {
      database = await factory.openDatabase(path, options: options);
    } on StateError {
      await factory.deleteDatabase(path);
      await _deleteDatabaseFiles(path);
      database = await factory.openDatabase(path, options: options);
    }
    _database = database;
    return database;
  }

  Future<String> _resolveDatabasePath() async {
    final current = _databasePath;
    if (current != null) return current;
    final base = await _directoryProvider();
    final directory = Directory(p.join(base.path, 'item_manager_drafts'));
    if (!await directory.exists()) await directory.create(recursive: true);
    final safeKey = metadata.draftKey.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = p.join(directory.path, '$safeKey.sqlite');
    _databasePath = path;
    return path;
  }

  DatabaseFactory _defaultDatabaseFactory() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return databaseFactory;
  }

  Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE draft_session (
        session_id INTEGER PRIMARY KEY CHECK (session_id = 1),
        schema_version INTEGER NOT NULL,
        backup_mode TEXT NOT NULL,
        draft_key TEXT NOT NULL,
        user_id TEXT NOT NULL,
        customer_id INTEGER NOT NULL,
        brand_id INTEGER NOT NULL,
        label_size_id INTEGER NOT NULL,
        current_market_id INTEGER NOT NULL,
        selected_row_keys_json TEXT NOT NULL,
        anchor_row_key TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE item_name_before (
        item_id INTEGER PRIMARY KEY,
        item_name TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE element_before (
        item_id INTEGER PRIMARY KEY,
        element_plain TEXT NOT NULL,
        element_payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE cell_before (
        item_id INTEGER NOT NULL,
        column_id INTEGER NOT NULL,
        col_content_id INTEGER NOT NULL,
        editable INTEGER NOT NULL,
        data_string TEXT NOT NULL,
        PRIMARY KEY (item_id, column_id)
      )
    ''');
    await database.execute('''
      CREATE TABLE order_before (
        item_id INTEGER PRIMARY KEY,
        original_index INTEGER NOT NULL,
        item_order INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE added_row (row_key TEXT PRIMARY KEY)
    ''');
    await database.execute('''
      CREATE TABLE deleted_row (
        item_id INTEGER PRIMARY KEY,
        original_index INTEGER NOT NULL,
        row_json TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE deleted_cell (
        item_id INTEGER NOT NULL,
        column_id INTEGER NOT NULL,
        col_content_id INTEGER NOT NULL,
        editable INTEGER NOT NULL,
        data_string TEXT NOT NULL,
        PRIMARY KEY (item_id, column_id)
      )
    ''');
  }

  void _validateSession(Map<String, Object?> session) {
    if (session['schema_version'] != schemaVersion ||
        session['draft_key'] != metadata.draftKey ||
        session['user_id'] != metadata.userId ||
        session['customer_id'] != metadata.customerId ||
        session['brand_id'] != metadata.brandId ||
        session['label_size_id'] != metadata.labelSizeId ||
        session['current_market_id'] != metadata.currentMarketId) {
      throw StateError('Item manager draft backup identity does not match.');
    }
  }

  int _sourceItemId(ItemManagerDraftRow row) {
    final itemId = row.sourceItemId;
    if (itemId == null) {
      throw ArgumentError('Existing row backup requires a source item id.');
    }
    return itemId;
  }
}

Future<void> _deleteDatabaseFiles(String path) async {
  for (final candidate in [path, '$path-wal', '$path-shm', '$path-journal']) {
    final file = File(candidate);
    if (await file.exists()) await file.delete();
  }
}

Map<String, Object?> _columnToMap(TColumnContent value) => {
  'item_id': value.itemId,
  'column_id': value.columnId,
  'col_content_id': value.colContentId,
  'editable': value.editable ? 1 : 0,
  'data_string': value.dataString,
};

TColumnContent _columnFromMap(Map<String, Object?> value) => TColumnContent(
  colContentId: value['col_content_id']! as int,
  columnId: value['column_id']! as int,
  itemId: value['item_id']! as int,
  editable: value['editable'] == 1,
  dataString: value['data_string']! as String,
);

Map<String, Object?> _rowToJson(ItemManagerDraftRow row) => {
  'originalIndex': row.originalIndex,
  'source': _itemOfMarketToJson(row.source!),
  'rawSnapshot': _rawSnapshotToJson(row.currentMarketSnapshot!),
};

ItemManagerDraftRow _rowFromJson(Map<String, dynamic> value) =>
    ItemManagerDraftRow.existing(
      source: _itemOfMarketFromJson(
        Map<String, dynamic>.from(value['source'] as Map),
      ),
      currentMarketSnapshot: _rawSnapshotFromJson(
        Map<String, dynamic>.from(value['rawSnapshot'] as Map),
      ),
      originalIndex: value['originalIndex']! as int,
    );

Map<String, Object?> _itemOfMarketToJson(ItemOfMarket value) => {
  'marketId': value.marketId,
  'item': {
    'itemId': value.item.itemId,
    'labelSizeId': value.item.labelSizeId,
    'itemName': value.item.itemName,
    'labelSizeName': value.item.labelSizeName,
    'element': value.item.element,
    'elementRTF': value.item.elementRTF,
    'price': value.item.price,
    'order': value.item.order,
  },
  'additionalItem': {
    'additionalItemId': value.additionalItem.AdditionalItemId,
    'itemId': value.additionalItem.itemId,
    'element': value.additionalItem.element,
    'elementRTF': value.additionalItem.elementRTF,
    'price': value.additionalItem.price,
  },
  'gdsNo': value.gdsNo,
  'dateSaleStart': value.dateSaleStart.toIso8601String(),
  'dateSaleEnd': value.dateSaleEnd.toIso8601String(),
  'discountPercent': value.discountPercent,
  'discountAmount': value.discountAmount,
  'dateStartDiscount': value.dateStartDiscount.toIso8601String(),
  'dateEndDiscount': value.dateEndDiscount.toIso8601String(),
  'useDefineElement': value.useDefineElement,
  'rtfText': value.rtfText,
  'useLinefeed': value.useLinefeed,
  'linefeed': value.linefeed,
  'useScaleBarcode': value.useScaleBarcode,
  'printCount': value.printCount,
  'useLabelSize': value.useLabelSize,
  'labelSizeWidth': value.labelSizeWidth,
  'labelSizeHeight': value.labelSizeHeight,
  'useMargin': value.useMargin,
  'leftMargin': value.leftMargin,
  'rightMargin': value.rightMargin,
  'topMargin': value.topMargin,
  'leftPush': value.leftPush,
  'topPush': value.topPush,
};

ItemOfMarket _itemOfMarketFromJson(Map<String, dynamic> value) {
  final item = Map<String, dynamic>.from(value['item'] as Map);
  final additional = Map<String, dynamic>.from(value['additionalItem'] as Map);
  return ItemOfMarket(
    marketId: value['marketId']! as int,
    item: Item(
      itemId: item['itemId']! as int,
      labelSizeId: item['labelSizeId']! as int,
      itemName: item['itemName']! as String,
      labelSizeName: item['labelSizeName']! as String,
      element: item['element']! as String,
      elementRTF: item['elementRTF']! as String,
      price: item['price']! as int,
      order: item['order']! as int,
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: additional['additionalItemId']! as int,
      itemId: additional['itemId']! as int,
      element: additional['element']! as String,
      elementRTF: additional['elementRTF']! as String,
      price: additional['price']! as int,
    ),
    gdsNo: value['gdsNo']! as int,
    dateSaleStart: DateTime.parse(value['dateSaleStart']! as String),
    dateSaleEnd: DateTime.parse(value['dateSaleEnd']! as String),
    discountPercent: (value['discountPercent']! as num).toDouble(),
    discountAmount: value['discountAmount']! as int,
    dateStartDiscount: DateTime.parse(value['dateStartDiscount']! as String),
    dateEndDiscount: DateTime.parse(value['dateEndDiscount']! as String),
    useDefineElement: value['useDefineElement']! as bool,
    rtfText: value['rtfText']! as String,
    useLinefeed: value['useLinefeed']! as bool,
    linefeed: value['linefeed']! as int,
    useScaleBarcode: value['useScaleBarcode']! as bool,
    printCount: value['printCount']! as int,
    useLabelSize: value['useLabelSize']! as bool,
    labelSizeWidth: value['labelSizeWidth']! as int,
    labelSizeHeight: value['labelSizeHeight']! as int,
    useMargin: value['useMargin']! as bool,
    leftMargin: (value['leftMargin']! as num).toDouble(),
    rightMargin: (value['rightMargin']! as num).toDouble(),
    topMargin: (value['topMargin']! as num).toDouble(),
    leftPush: (value['leftPush']! as num).toDouble(),
    topPush: (value['topPush']! as num).toDouble(),
  );
}

Map<String, Object?> _rawSnapshotToJson(ItemOfMarketRawSnapshot value) => {
  'marketId': value.marketId,
  'itemId': value.itemId,
  'additionalItemId': value.additionalItemId,
  'gdsNo': value.gdsNo,
  'dateSaleStart': value.dateSaleStart?.toIso8601String(),
  'dateSaleEnd': value.dateSaleEnd?.toIso8601String(),
  'discountPercent': value.discountPercent,
  'discountAmount': value.discountAmount,
  'dateStartDiscount': value.dateStartDiscount?.toIso8601String(),
  'dateEndDiscount': value.dateEndDiscount?.toIso8601String(),
  'useDefineElement': value.useDefineElement,
  'rtfText': value.rtfText,
  'useLinefeed': value.useLinefeed,
  'linefeed': value.linefeed,
  'useScaleBarcode': value.useScaleBarcode,
  'printCount': value.printCount,
  'useLabelSize': value.useLabelSize,
  'labelSizeWidth': value.labelSizeWidth,
  'labelSizeHeight': value.labelSizeHeight,
  'useMargin': value.useMargin,
  'leftMargin': value.leftMargin,
  'rightMargin': value.rightMargin,
  'topMargin': value.topMargin,
  'leftPush': value.leftPush,
  'topPush': value.topPush,
};

ItemOfMarketRawSnapshot _rawSnapshotFromJson(Map<String, dynamic> value) {
  DateTime? date(String key) => value[key] == null
      ? null
      : DateTime.parse(value[key]! as String);
  return ItemOfMarketRawSnapshot(
    marketId: value['marketId']! as int,
    itemId: value['itemId']! as int,
    additionalItemId: value['additionalItemId'] as int?,
    gdsNo: value['gdsNo'] as int?,
    dateSaleStart: date('dateSaleStart'),
    dateSaleEnd: date('dateSaleEnd'),
    discountPercent: (value['discountPercent'] as num?)?.toDouble(),
    discountAmount: value['discountAmount'] as int?,
    dateStartDiscount: date('dateStartDiscount'),
    dateEndDiscount: date('dateEndDiscount'),
    useDefineElement: value['useDefineElement'] as bool?,
    rtfText: value['rtfText'] as String?,
    useLinefeed: value['useLinefeed'] as bool?,
    linefeed: value['linefeed'] as int?,
    useScaleBarcode: value['useScaleBarcode'] as bool?,
    printCount: value['printCount'] as int?,
    useLabelSize: value['useLabelSize'] as bool?,
    labelSizeWidth: value['labelSizeWidth'] as int?,
    labelSizeHeight: value['labelSizeHeight'] as int?,
    useMargin: value['useMargin'] as bool?,
    leftMargin: (value['leftMargin'] as num?)?.toDouble(),
    rightMargin: (value['rightMargin'] as num?)?.toDouble(),
    topMargin: (value['topMargin'] as num?)?.toDouble(),
    leftPush: (value['leftPush'] as num?)?.toDouble(),
    topPush: (value['topPush'] as num?)?.toDouble(),
  );
}
