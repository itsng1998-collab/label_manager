import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:synchronized/synchronized.dart';

import 'package:label_manager/models/label_print.dart';

@immutable
class ScaleConnectInfo {
  const ScaleConnectInfo({
    required this.portName,
    required this.baudRate,
    required this.dataBit,
    required this.stopBit,
    required this.parityBit,
    required this.autoPrint,
  });

  const ScaleConnectInfo.defaults()
      : portName = 'COM1',
        baudRate = 9600,
        dataBit = 8,
        stopBit = 1,
        parityBit = 'none',
        autoPrint = false;

  final String portName;
  final int baudRate;
  final int dataBit;
  final int stopBit;
  final String parityBit;
  final bool autoPrint;

  Map<String, Object?> toMap() => <String, Object?>{
    'PORT_NAME': portName,
    'BAUD_RATE': baudRate,
    'DATA_BIT': dataBit,
    'STOP_BIT': stopBit,
    'PARITY_BIT': parityBit,
    'AUTO_PRINT': autoPrint ? 1 : 0,
  };

  ScaleConnectInfo copyWith({
    String? portName,
    int? baudRate,
    int? dataBit,
    int? stopBit,
    String? parityBit,
    bool? autoPrint,
  }) => ScaleConnectInfo(
    portName: portName ?? this.portName,
    baudRate: baudRate ?? this.baudRate,
    dataBit: dataBit ?? this.dataBit,
    stopBit: stopBit ?? this.stopBit,
    parityBit: parityBit ?? this.parityBit,
    autoPrint: autoPrint ?? this.autoPrint,
  );

  static ScaleConnectInfo fromMap(Map<String, Object?> map) => ScaleConnectInfo(
    portName: (map['PORT_NAME'] ?? 'COM1').toString(),
    baudRate: (map['BAUD_RATE'] as num?)?.toInt() ?? 9600,
    dataBit: (map['DATA_BIT'] as num?)?.toInt() ?? 8,
    stopBit: (map['STOP_BIT'] as num?)?.toInt() ?? 1,
    parityBit: (map['PARITY_BIT'] ?? 'none').toString(),
    autoPrint: ((map['AUTO_PRINT'] as num?)?.toInt() ?? 0) != 0,
  );
}

class DbScaleConnectInfoHelper {
  static const _dbName = 'labelmanager_scale_output.db';
  static const _connectTable = 'BM_RICH_SCALE_CONNECT_SETUP';
  static const _printerTable = 'BM_RICH_SCALE_OUTPUT_PRINTER_SETUP';
  static const _dbVersion = 1;

  static Database? _db;
  static final Lock _lock = Lock();

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static void _ensureDesktopInit() {
    if (_isDesktop) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfiNoIsolate;
    }
  }

  static DatabaseFactory get _databaseFactory =>
      _isDesktop ? ffi.databaseFactoryFfiNoIsolate : databaseFactory;

  static Future<String> _dbPath() async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on Web');
    }
    Directory baseDir;
    if (_isDesktop) {
      if (Platform.isWindows && kReleaseMode) {
        final appData = Platform.environment['APPDATA'];
        if (appData != null && appData.trim().isNotEmpty) {
          baseDir = Directory(p.join(appData, 'com.itsng', 'label_manager'));
        } else {
          baseDir = Directory.current;
        }
      } else if (kDebugMode) {
        baseDir = Directory.current;
      } else {
        baseDir = await getApplicationSupportDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(baseDir.path, 'assets', 'data'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(dir.path, _dbName);
  }

  static Future<Database> open() {
    return _lock.synchronized(() async {
      if (_db != null && _db!.isOpen) return _db!;
      _ensureDesktopInit();
      final path = await _dbPath();
      _db = await _databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $_connectTable (
                PORT_NAME TEXT NOT NULL,
                BAUD_RATE INTEGER NOT NULL,
                DATA_BIT INTEGER NOT NULL,
                STOP_BIT INTEGER NOT NULL,
                PARITY_BIT TEXT NOT NULL,
                AUTO_PRINT INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $_printerTable (
                LABELSIZE_ID INTEGER PRIMARY KEY,
                PRINTER_NAME TEXT,
                LEFT_MARGIN REAL NOT NULL DEFAULT 0,
                RIGHT_MARGIN REAL NOT NULL DEFAULT 0,
                TOP_MARGIN REAL NOT NULL DEFAULT 0,
                LEFT_PUSH REAL NOT NULL DEFAULT 0,
                TOP_PUSH REAL NOT NULL DEFAULT 0,
                EXTRA_AREA REAL NOT NULL DEFAULT 0,
                ORIENTATION TEXT NOT NULL DEFAULT 'horizontal',
                LINE_SPACING INTEGER
              )
            ''');
          },
        ),
      );
      return _db!;
    });
  }

  static Future<ScaleConnectInfo> loadConnectInfo() async {
    final db = await open();
    final rows = await db.query(_connectTable, limit: 1);
    if (rows.isEmpty) {
      return const ScaleConnectInfo.defaults();
    }
    return ScaleConnectInfo.fromMap(rows.first);
  }

  static Future<void> saveConnectInfo(ScaleConnectInfo info) async {
    final db = await open();
    await db.transaction((txn) async {
      await txn.delete(_connectTable);
      await txn.insert(_connectTable, info.toMap());
    });
  }

  static Future<LabelPrintSettingsSnapshot?> loadPrinterSettings(
    int labelSizeId,
  ) async {
    final db = await open();
    final rows = await db.query(
      _printerTable,
      where: 'LABELSIZE_ID = ?',
      whereArgs: <Object?>[labelSizeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return LabelPrintSettingsSnapshot(
      printerName: row['PRINTER_NAME'] as String?,
      leftMarginMm: (row['LEFT_MARGIN'] as num?)?.toDouble() ?? 0,
      rightMarginMm: (row['RIGHT_MARGIN'] as num?)?.toDouble() ?? 0,
      topMarginMm: (row['TOP_MARGIN'] as num?)?.toDouble() ?? 0,
      leftPushMm: (row['LEFT_PUSH'] as num?)?.toDouble() ?? 0,
      topPushMm: (row['TOP_PUSH'] as num?)?.toDouble() ?? 0,
      lineSpacingPercent: (row['LINE_SPACING'] as num?)?.toInt(),
      extraAreaMm: (row['EXTRA_AREA'] as num?)?.toDouble() ?? 0,
      orientation: (row['ORIENTATION'] == 'vertical')
          ? LabelPrintOrientation.vertical
          : LabelPrintOrientation.horizontal,
    );
  }

  static Future<void> savePrinterSettings(
    int labelSizeId,
    LabelPrintSettingsSnapshot settings,
  ) async {
    final db = await open();
    await db.insert(
      _printerTable,
      <String, Object?>{
        'LABELSIZE_ID': labelSizeId,
        'PRINTER_NAME': settings.printerName,
        'LEFT_MARGIN': settings.leftMarginMm,
        'RIGHT_MARGIN': settings.rightMarginMm,
        'TOP_MARGIN': settings.topMarginMm,
        'LEFT_PUSH': settings.leftPushMm,
        'TOP_PUSH': settings.topPushMm,
        'EXTRA_AREA': settings.extraAreaMm,
        'ORIENTATION': settings.orientation == LabelPrintOrientation.vertical
            ? 'vertical'
            : 'horizontal',
        'LINE_SPACING': settings.lineSpacingPercent,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}