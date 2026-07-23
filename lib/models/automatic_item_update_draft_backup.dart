import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/update_item.dart';

String automaticItemUpdateDraftKey({
  required String userId,
  required int customerId,
  required int brandId,
  required int labelSizeId,
  required int currentMarketId,
}) => '${userId}_${customerId}_${brandId}_${labelSizeId}_$currentMarketId';

class AutoItemUpdateDraftBackupMetadata {
  const AutoItemUpdateDraftBackupMetadata({
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
      throw ArgumentError('Automatic item update backup metadata is invalid.');
    }
  }
}

class AutoItemUpdateDraftBackupSnapshot {
  const AutoItemUpdateDraftBackupSnapshot({
    required this.applyDates,
    required this.elements,
    required this.cells,
    required this.addedRowKeys,
    required this.deletedRows,
    required this.deletedCells,
    required this.selectedRowKeys,
    this.anchorRowKey,
  });

  final Map<int, DateTime> applyDates;
  final Map<int, ({String plain, String payload})> elements;
  final Map<AutoItemUpdateCellKey, AutoItemUpdateCellValue> cells;
  final Set<String> addedRowKeys;
  final Map<int, AutoItemUpdateDraftRow> deletedRows;
  final Map<AutoItemUpdateCellKey, AutoItemUpdateCellValue> deletedCells;
  final Set<String> selectedRowKeys;
  final String? anchorRowKey;
}

class AutoItemUpdateDraftBackupStore {
  AutoItemUpdateDraftBackupStore({
    required this.metadata,
    Future<Directory> Function()? directoryProvider,
    DatabaseFactory? databaseFactory,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _databaseFactory = databaseFactory;

  static const int schemaVersion = 1;

  final AutoItemUpdateDraftBackupMetadata metadata;
  final Future<Directory> Function() _directoryProvider;
  final DatabaseFactory? _databaseFactory;
  Database? _database;
  String? _databasePath;
  bool _started = false;

  Future<void> start({
    required Iterable<String> selectedRowKeys,
    String? anchorRowKey,
  }) async {
    if (_started) {
      return;
    }
    metadata.validate();
    final database = await _open();
    await database.transaction((transaction) async {
      for (final table in [
        'apply_date_before',
        'element_before',
        'cell_before',
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

  Future<void> captureApplyDate(AutoItemUpdateDraftRow row) async {
    final updateItemId = _existingId(row);
    await (await _open()).insert('apply_date_before', {
      'update_item_id': updateItemId,
      'apply_date': formatAutoItemUpdateDate(row.applyDate),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureElement(AutoItemUpdateDraftRow row) async {
    final updateItemId = _existingId(row);
    await (await _open()).insert('element_before', {
      'update_item_id': updateItemId,
      'element_plain': row.element,
      'element_payload': row.elementRtf,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureCell({
    required AutoItemUpdateDraftRow row,
    required int columnId,
    required AutoItemUpdateCellValue? original,
  }) async {
    final updateItemId = _existingId(row);
    await (await _open()).insert('cell_before', {
      'update_item_id': updateItemId,
      'column_id': columnId,
      'row_key': row.rowKey,
      'col_content_id': original?.contentId ?? 0,
      'editable': original?.editable == true ? 1 : 0,
      'data_string': original?.dataString ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> captureDeletedRows({
    required Iterable<AutoItemUpdateDraftRow> rows,
    required Map<AutoItemUpdateCellKey, AutoItemUpdateCellValue> cellValues,
  }) async {
    final existingRows = rows.where((row) => row.sourceUpdateItemId != null).toList();
    if (existingRows.isEmpty) {
      return;
    }
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final row in existingRows) {
        final updateItemId = row.sourceUpdateItemId!;
        batch.insert('deleted_row', {
          'update_item_id': updateItemId,
          'row_json': jsonEncode(_rowToJson(row)),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final entry in cellValues.entries.where(
          (entry) => entry.key.rowKey == row.rowKey,
        )) {
          batch.insert('deleted_cell', _cellToMap(entry.value),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> recordAddedRows(Iterable<String> rowKeys) async {
    final keys = rowKeys.toSet();
    if (keys.isEmpty) {
      return;
    }
    final database = await _open();
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final rowKey in keys) {
        batch.insert('added_row', {'row_key': rowKey},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<AutoItemUpdateDraftBackupSnapshot> readSnapshot() async {
    final database = await _open();
    final sessionRows = await database.query('draft_session', limit: 1);
    if (sessionRows.isEmpty) {
      throw StateError('Automatic item update backup session is missing.');
    }
    final session = sessionRows.single;
    _validateSession(session);
    final applyDates = <int, DateTime>{
      for (final row in await database.query('apply_date_before'))
        row['update_item_id']! as int:
            parseAutoItemUpdateDate(row['apply_date']! as String)!,
    };
    final elements = <int, ({String plain, String payload})>{
      for (final row in await database.query('element_before'))
        row['update_item_id']! as int: (
          plain: row['element_plain']! as String,
          payload: row['element_payload']! as String,
        ),
    };
    final cells = <AutoItemUpdateCellKey, AutoItemUpdateCellValue>{};
    for (final row in await database.query('cell_before')) {
      final cell = _cellFromMap(row);
      cells[AutoItemUpdateCellKey(columnId: cell.columnId, rowKey: cell.rowKey)] =
          cell;
    }
    final deletedRows = <int, AutoItemUpdateDraftRow>{};
    for (final row in await database.query('deleted_row')) {
      deletedRows[row['update_item_id']! as int] = _rowFromJson(
        Map<String, dynamic>.from(
          jsonDecode(row['row_json']! as String) as Map,
        ),
      );
    }
    final deletedCells = <AutoItemUpdateCellKey, AutoItemUpdateCellValue>{};
    for (final row in await database.query('deleted_cell')) {
      final cell = _cellFromMap(row);
      deletedCells[
        AutoItemUpdateCellKey(columnId: cell.columnId, rowKey: cell.rowKey)
      ] = cell;
    }
    final selectedRowKeys = Set<String>.from(
      jsonDecode(session['selected_row_keys_json']! as String) as List,
    );
    return AutoItemUpdateDraftBackupSnapshot(
      applyDates: applyDates,
      elements: elements,
      cells: cells,
      addedRowKeys: {
        for (final row in await database.query('added_row')) row['row_key']! as String,
      },
      deletedRows: deletedRows,
      deletedCells: deletedCells,
      selectedRowKeys: selectedRowKeys,
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
    if (current != null) {
      return current;
    }
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
        throw StateError('Automatic item update backup schema changed.');
      },
      onDowngrade: (database, _, _) async {
        throw StateError('Automatic item update backup schema changed.');
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
    if (current != null) {
      return current;
    }
    final base = await _directoryProvider();
    final directory = Directory(
      p.join(base.path, 'automatic_item_update_drafts'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
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
      CREATE TABLE apply_date_before (
        update_item_id INTEGER PRIMARY KEY,
        apply_date TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE element_before (
        update_item_id INTEGER PRIMARY KEY,
        element_plain TEXT NOT NULL,
        element_payload TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE cell_before (
        update_item_id INTEGER NOT NULL,
        column_id INTEGER NOT NULL,
        row_key TEXT NOT NULL,
        col_content_id INTEGER NOT NULL,
        editable INTEGER NOT NULL,
        data_string TEXT NOT NULL,
        PRIMARY KEY (update_item_id, column_id)
      )
    ''');
    await database.execute('''
      CREATE TABLE added_row (row_key TEXT PRIMARY KEY)
    ''');
    await database.execute('''
      CREATE TABLE deleted_row (
        update_item_id INTEGER PRIMARY KEY,
        row_json TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE deleted_cell (
        row_key TEXT NOT NULL,
        column_id INTEGER NOT NULL,
        col_content_id INTEGER NOT NULL,
        editable INTEGER NOT NULL,
        data_string TEXT NOT NULL,
        PRIMARY KEY (row_key, column_id)
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
      throw StateError('Automatic item update backup identity does not match.');
    }
  }

  int _existingId(AutoItemUpdateDraftRow row) {
    final updateItemId = row.sourceUpdateItemId;
    if (updateItemId == null) {
      throw ArgumentError('Existing row backup requires an update item id.');
    }
    return updateItemId;
  }
}

Future<void> _deleteDatabaseFiles(String path) async {
  for (final candidate in [path, '$path-wal', '$path-shm', '$path-journal']) {
    final file = File(candidate);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

Map<String, Object?> _cellToMap(AutoItemUpdateCellValue value) => {
  'row_key': value.rowKey,
  'column_id': value.columnId,
  'col_content_id': value.contentId,
  'editable': value.editable ? 1 : 0,
  'data_string': value.dataString,
};

AutoItemUpdateCellValue _cellFromMap(Map<String, Object?> value) =>
    AutoItemUpdateCellValue(
      contentId: value['col_content_id']! as int,
      columnId: value['column_id']! as int,
      rowKey: value['row_key']! as String,
      editable: value['editable'] == 1,
      dataString: value['data_string']! as String,
    );

Map<String, Object?> _rowToJson(AutoItemUpdateDraftRow row) => {
  'rowKey': row.rowKey,
  'sourceUpdateItemId': row.sourceUpdateItemId,
  'sourceItemId': row.sourceItemId,
  'itemName': row.itemName,
  'labelSizeId': row.labelSizeId,
  'applyDate': formatAutoItemUpdateDate(row.applyDate),
  'element': row.element,
  'elementRtf': row.elementRtf,
  'price': row.price,
  'isApply': row.isApply,
  'currentMarketId': row.currentMarketId,
  'originalIndex': row.originalIndex,
  'rowState': row.rowState.name,
  'source': row.source == null
      ? null
      : {
          'updateItemId': row.source!.updateItemId,
          'itemId': row.source!.itemId,
          'itemName': row.source!.itemName,
          'labelSizeId': row.source!.labelSizeId,
          'element': row.source!.element,
          'elementRTF': row.source!.elementRTF,
          'price': row.source!.price,
          'applyDate': formatAutoItemUpdateDate(row.source!.applyDate),
          'isApply': row.source!.isApply ? 1 : 0,
        },
};

AutoItemUpdateDraftRow _rowFromJson(Map<String, dynamic> value) {
  final sourceMap = value['source'] == null
      ? null
      : Map<String, dynamic>.from(value['source'] as Map);
  final source = sourceMap == null
      ? null
      : UpdateItem(
          updateItemId: sourceMap['updateItemId']! as int,
          itemId: sourceMap['itemId']! as int,
          itemName: sourceMap['itemName']! as String,
          labelSizeId: sourceMap['labelSizeId']! as int,
          element: sourceMap['element']! as String,
          elementRTF: sourceMap['elementRTF']! as String,
          price: sourceMap['price']! as int,
          applyDate: parseAutoItemUpdateDate(sourceMap['applyDate']! as String)!,
          isApply: sourceMap['isApply'] == 1,
        );
  return AutoItemUpdateDraftRow(
    rowKey: value['rowKey']! as String,
    sourceUpdateItemId: value['sourceUpdateItemId'] as int?,
    sourceItemId: value['sourceItemId']! as int,
    itemName: value['itemName']! as String,
    labelSizeId: value['labelSizeId']! as int,
    applyDate: parseAutoItemUpdateDate(value['applyDate']! as String)!,
    element: value['element']! as String,
    elementRtf: value['elementRtf']! as String,
    price: value['price']! as int,
    isApply: value['isApply']! as bool,
    currentMarketId: value['currentMarketId']! as int,
    originalIndex: value['originalIndex']! as int,
    rowState: AutoItemUpdateRowState.values.byName(value['rowState']! as String),
    source: source,
  );
}
