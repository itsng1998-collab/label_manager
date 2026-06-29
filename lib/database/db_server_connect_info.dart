// UTF-8 인코딩
// 로컬 DB: dmServerConnectInfo.db (테이블: DB_SERVER_CONNECT_INFO)
// 기능: 생성, 오픈, 조회, 업데이트

// ignore_for_file: constant_identifier_names, body_might_complete_normally_catch_error

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:synchronized/synchronized.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/utils/log_context.dart';

enum CustomerType {
  CUST_TYPE_NORMAL(0),
  CUST_SHINSEGAE(1),
  CUST_GS_RETAIL(2);

  final int code;
  const CustomerType(this.code);
  static CustomerType fromCode(int code) =>
      CustomerType.values.firstWhere((e) => e.code == code);
}

/// 서버 연결 정보 모델
class ServerConnectInfo {
  final String serverIp;
  final String databaseName;
  final int serverPort;
  final String userId;
  final String password;
  final String serverName;
  final CustomerType customerType;

  const ServerConnectInfo({
    required this.serverIp,
    required this.databaseName,
    required this.serverPort,
    required this.userId,
    required this.password,
    required this.serverName,
    required this.customerType,
  });

  Map<String, Object?> toMap() => {
    'RICH_SERVER_IP': serverIp,
    'RICH_DATABASE_NAME': databaseName,
    'RICH_SERVER_PORT': serverPort,
    'RICH_USER_ID': userId,
    'RICH_PWD': password,
    'RICH_SERVER_NAME': serverName,
    'RICH_CUSTOMER_TYPE': customerType.code,
  };

  static ServerConnectInfo fromMap(Map<String, Object?> m) => ServerConnectInfo(
    serverIp: (m['RICH_SERVER_IP'] ?? '') as String,
    databaseName: (m['RICH_DATABASE_NAME'] ?? '') as String,
    serverPort: (m['RICH_SERVER_PORT'] ?? 0) as int,
    userId: (m['RICH_USER_ID'] ?? '') as String,
    password: (m['RICH_PWD'] ?? '') as String,
    serverName: (m['RICH_SERVER_NAME'] ?? '') as String,
    customerType: CustomerType.fromCode((m['RICH_CUSTOMER_TYPE'] ?? 0) as int),
  );
}

/// DB 헬퍼: 생성/오픈/조회/업데이트
class DbServerConnectInfoHelper {
  static const _data = 'data';
  static const _dbName = 'labelmanager_server_connect_info.db';
  static const _table = 'BM_DB_SERVER_CONNECT_INFO';
  static const _lastTable = 'BM_LAST_CONNECT_DB_SERVER';
  static const _connectInfoColumns = <String>[
    'RICH_SERVER_IP',
    'RICH_DATABASE_NAME',
    'RICH_SERVER_PORT',
    'RICH_USER_ID',
    'RICH_PWD',
    'RICH_SERVER_NAME',
    'RICH_CUSTOMER_TYPE',
  ];
  static const _dbVersion = 2;
  static const _openDatabaseTimeout = Duration(seconds: 3);
  static const _maxOpenTries = 2;

  static Database? _db;
  static MethodChannel? _channel;
  static final _dbInitLock = Lock(); // 동시성 방지
  static var _openAttemptSeq = 0;

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static String _databaseFactoryDebugName() {
    try {
      return databaseFactory.runtimeType.toString();
    } catch (_) {
      return 'uninitialized';
    }
  }

  /// 데스크톱(Windows/macOS/Linux)에서 sqflite_ffi 초기화
  static void _ensureDesktopInit() {
    if (_isDesktop) {
      debugLog('before init, factory=${_databaseFactoryDebugName()}');
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfiNoIsolate;
      debugLog(
        'after init, factory=${_databaseFactoryDebugName()}, mode=ffiNoIsolate',
      );
    }
  }

  static DatabaseFactory get _openDatabaseFactory =>
      _isDesktop ? ffi.databaseFactoryFfiNoIsolate : databaseFactory;

  static Future<Directory> _desktopDbBaseDir() async {
    if (Platform.isWindows && kReleaseMode) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.trim().isNotEmpty) {
        return Directory(p.join(appData, 'com.itsng', APP_TITLE_SHORT));
      }
    }

    if (kDebugMode) {
      return Directory.current;
    }

    return getApplicationSupportDirectory();
  }

  static Future<void> _copyBundledDbIfMissing(String dbFullPath) async {
    final dbFile = File(dbFullPath);
    if (await dbFile.exists()) {
      return;
    }

    try {
      final bytes = await rootBundle.load('assets/$_data/$_dbName');
      await dbFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      debugLog('copied bundled db to $dbFullPath');
    } catch (e) {
      debugLog('failed to copy bundled db to $dbFullPath: $e');
    }
  }

  static Future<void> _logDbOpenEnvironment(String dbFullPath) async {
    final dbState = await _fileState(dbFullPath);
    final sidecars = <String>[
      if (await File('$dbFullPath-wal').exists()) 'wal',
      if (await File('$dbFullPath-shm').exists()) 'shm',
      if (await File('$dbFullPath-journal').exists()) 'journal',
    ];
    final dbFile = File(dbFullPath);
    final dbDir = dbFile.parent;
    debugLog(
      'platform=${Platform.operatingSystem}, debug=$kDebugMode, '
      'factory=${_databaseFactoryDebugName()}, cwd=${Directory.current.path}, '
      'dirExists=${await dbDir.exists()}, db=$dbState, '
      'sidecars=${sidecars.isEmpty ? 'none' : sidecars.join(',')}',
    );
  }

  static Future<String> _fileState(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return 'missing';
      }
      final stat = await file.stat();
      return 'exists,size=${stat.size},modified=${stat.modified.toIso8601String()},mode=${stat.modeString()}';
    } catch (e) {
      return 'state-error=$e';
    }
  }

  /// DB 파일의 최종 경로를 결정
  static Future<String> _dbFullPath() async {
    debugLog(START);

    // Android: SAF/Legacy 권한을 처리한 뒤 선택된 Documents 하위 경로를 사용한다.
    // 앱의 쓰기 가능한 디렉터리 하위에 assets/data 경로를 생성하고, 해당 경로에 DB 파일을 복사한다.
    if (Platform.isAndroid) {
      // 내부에 labelmanager_server_connect_info.db가 있는 지 판단한다.
      final internalDocDir = await getApplicationDocumentsDirectory();
      String? internalDbPath = p.join(internalDocDir.path, _data, _dbName);
      if (!(await File(internalDbPath).exists())) {
        internalDbPath = null;
      }

      _channel ??= MethodChannel('$appPackageName/storage');
      String? externalDbPath = await _channel!.invokeMethod<String>(
        'prepareDocumentsAndGetPath',
        {'isInternalDbExists': internalDbPath != null},
      );

      if (externalDbPath != null && externalDbPath.isNotEmpty) {
        debugLog('Android SAF/Legacy ExternalDbPath = $externalDbPath');

        // SAF URI인 경우, 내용을 로컬 파일로 복사
        if (externalDbPath.startsWith('content://')) {
          try {
            _channel ??= MethodChannel('$appPackageName/storage');
            final Uint8List? data = await _channel!.invokeMethod(
              'readContentUri',
              {'uri': externalDbPath},
            );

            if (data != null) {
              final dir = Directory(p.join(internalDocDir.path, _data));
              if (!await dir.exists()) {
                await dir.create(recursive: true);
              }
              internalDbPath = p.join(internalDocDir.path, _data, _dbName);
              await File(internalDbPath).writeAsBytes(data, flush: true);
              debugLog(
                'Copied SAF content URI to local file: $internalDbPath',
              );
            } else {
              debugLog('Internal db file: $internalDbPath');
            }
          } catch (e) {
            debugLog('Failed to read/copy content URI: $e');
            // 에러 발생 시 기존 경로(content://)로 시도하도록 둠 (실패하겠지만)
          }
        }

        return internalDbPath!;
      }

      throw UnsupportedError('ERROR!!');
    }

    Directory baseDir;

    if (kIsWeb) {
      // Web은 sqflite 미지원. 여기선 예외를 던집니다.
      throw UnsupportedError('sqflite is not supported on Web');
    } else if (Platform.isIOS) {
      // iOS는 앱의 Documents 디렉터리를 사용합니다.
      baseDir = await getApplicationDocumentsDirectory();
      debugPrint('DB baseDir (iOS): ${baseDir.path}');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      baseDir = await _desktopDbBaseDir();
    } else {
      baseDir = await getTemporaryDirectory();
    }

    final dir = Directory(p.join(baseDir.path, 'assets', 'data'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dbPath = p.join(dir.path, _dbName);
    if (Platform.isWindows && kReleaseMode) {
      await _copyBundledDbIfMissing(dbPath);
    }

    debugLog('$END, path=${dir.path}');
    return dbPath;
  }

  //////////////////////////////////////////////////////////////////////////////
  /// DB 오픈 (필요 시 생성 및 마이그레이션)

  static Future<Database> open() {
    final lockSw = Stopwatch()..start();
    debugLog('lock wait start');
    return _dbInitLock.synchronized(() async {
      lockSw.stop();
      final attempt = ++_openAttemptSeq;
      debugLog('#$attempt: lock acquired (${lockSw.elapsedMilliseconds}ms)');

      if (_db != null && _db!.isOpen) {
        debugLog('#$attempt: reuse open database');
        return _db!;
      }

      _ensureDesktopInit();
      String dbFullPath = await _dbFullPath();
      debugLog('#$attempt: path=$dbFullPath');
      await _logDbOpenEnvironment(dbFullPath);

      for (var openTry = 1; openTry <= _maxOpenTries; openTry += 1) {
        Timer? openWatchdog;
        final sw = Stopwatch()..start();
        var lastWatchdogSecond = 0;
        openWatchdog = Timer.periodic(const Duration(seconds: 2), (_) {
          final elapsedSeconds = sw.elapsed.inSeconds;
          if (elapsedSeconds == lastWatchdogSecond) return;
          lastWatchdogSecond = elapsedSeconds;
          debugLog('#$attempt: openDatabase waiting ${sw.elapsedMilliseconds}ms');
        });

        try {
          debugLog(
            '#$attempt: openDatabase try $openTry/$_maxOpenTries before call, timeout=${_openDatabaseTimeout.inSeconds}s, mode=${_isDesktop ? 'ffiNoIsolate' : 'default'}',
          );
          _db = await _openDatabaseFactory
              .openDatabase(
                dbFullPath,
                options: OpenDatabaseOptions(
                  version: _dbVersion,
                  onConfigure: (db) async {
                    debugLog('#$attempt: onConfigure start, isOpen=${db.isOpen}');
                    debugLog('#$attempt: onConfigure end');
                  },
                  onCreate: (db, version) async {
                    debugLog('#$attempt: onCreate start, version=$version');
                    await db.execute('''
            CREATE TABLE IF NOT EXISTS $_table (
              RICH_SERVER_IP     TEXT (0, 64),
              RICH_DATABASE_NAME TEXT (0, 256),
              RICH_SERVER_PORT   INTEGER (0, 5),
              RICH_USER_ID       TEXT (0, 64),
              RICH_PWD           TEXT (0, 64),
              RICH_SERVER_NAME   TEXT (0, 512),
              RICH_CUSTOMER_TYPE INTEGER (0, 5) DEFAULT (0),
              RICH_ETC           TEXT (0, 64),
              PRIMARY KEY (
                  RICH_SERVER_IP COLLATE RTRIM ASC,
                  RICH_DATABASE_NAME COLLATE RTRIM ASC
              )
            )
          ''');
                    await db.execute('''
            CREATE TABLE IF NOT EXISTS $_lastTable (
              RICH_SERVER_IP     TEXT (64),
              RICH_DATABASE_NAME TEXT (0, 256),
              PRIMARY KEY (
                RICH_SERVER_IP COLLATE RTRIM ASC,
                RICH_DATABASE_NAME COLLATE RTRIM ASC
              )
            )
          ''');
                    debugLog('#$attempt: onCreate end');
                  },
                  onUpgrade: (db, oldVersion, newVersion) async {
                    debugLog(
                      '#$attempt: onUpgrade start, oldVersion=$oldVersion, newVersion=$newVersion',
                    );
                    debugLog('#$attempt: onUpgrade end');
                  },
                  onOpen: (db) async {
                    debugLog('#$attempt: onOpen start, isOpen=${db.isOpen}');
                    debugLog('#$attempt: onOpen end');
                  },
                ),
              )
              .timeout(_openDatabaseTimeout);
          sw.stop();
          debugLog(
            '#$attempt: openDatabase returned (${sw.elapsedMilliseconds}ms), try=$openTry',
          );
          break;
        } on TimeoutException catch (e) {
          sw.stop();
          debugLog(
            '#$attempt: openDatabase timeout (${sw.elapsedMilliseconds}ms), try=$openTry/$_maxOpenTries, path=$dbFullPath',
          );
          if (openTry == _maxOpenTries) {
            debugLog(
              '#$attempt: Failed to open database after $_maxOpenTries tries at $dbFullPath, error=$e',
            );
            rethrow;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          sw.stop();
          debugLog(
            '#$attempt: Failed to open database at $dbFullPath, try=$openTry, error=$e',
          );
          rethrow;
        } finally {
          openWatchdog.cancel();
          debugLog('#$attempt: openDatabase watchdog cancelled, try=$openTry');
        }
      }

      debugLog('#$attempt: $END, isOpen=${_db!.isOpen}');
      return _db!;
    });
  }

  /// 마지막 접속 정보 조회
  static Future<ServerConnectInfo?> getLastConnectDBInfo() async {
    final db = await open();
    final rows = await _queryLastConnectInfo(db);
    if (rows.isEmpty) {
      return _recoverLastConnectInfo(db);
    }
    return ServerConnectInfo.fromMap(rows.first);
  }

  static Future<List<Map<String, Object?>>> _queryLastConnectInfo(
    Database db,
  ) {
    return db.rawQuery('''
			SELECT
				P2.RICH_SERVER_IP,
				P2.RICH_DATABASE_NAME,
				P2.RICH_SERVER_PORT,
				P2.RICH_USER_ID,
				P2.RICH_PWD,
				P2.RICH_SERVER_NAME,
				P2.RICH_CUSTOMER_TYPE
			FROM $_lastTable AS P1
			INNER JOIN $_table AS P2
				ON P1.RICH_SERVER_IP = P2.RICH_SERVER_IP
			AND P1.RICH_DATABASE_NAME = P2.RICH_DATABASE_NAME
		''');
  }

  static Future<ServerConnectInfo?> _recoverLastConnectInfo(Database db) async {
    debugLog('last connect info not found; checking fallback rows');
    final fallbackRows = await db.query(
      _table,
      columns: _connectInfoColumns,
      limit: 1,
    );
    if (fallbackRows.isNotEmpty) {
      final info = ServerConnectInfo.fromMap(fallbackRows.first);
      await _setLastConnected(db, info.serverIp, info.databaseName);
      debugLog(
        'last connect info recovered from first server row: ${info.serverIp}/${info.databaseName}',
      );
      return info;
    }

    if (Platform.isWindows && kReleaseMode) {
      final restored = await _seedFromBundledDb(db);
      if (restored != null) {
        return restored;
      }
    }

    debugLog('no server connect info rows found');
    return null;
  }

  static Future<ServerConnectInfo?> _seedFromBundledDb(Database db) async {
    Database? bundledDb;
    File? tempFile;
    try {
      final bytes = await rootBundle.load('assets/$_data/$_dbName');
      tempFile = File(
        p.join(
          Directory.systemTemp.path,
          'labelmanager_server_connect_info_${DateTime.now().microsecondsSinceEpoch}.db',
        ),
      );
      await tempFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      bundledDb = await _openDatabaseFactory.openDatabase(tempFile.path);
      final bundledServerRows = await bundledDb.query(
        _table,
        columns: _connectInfoColumns,
      );
      if (bundledServerRows.isEmpty) {
        debugLog('bundled server connect db has no server rows');
        return null;
      }
      final bundledLastRows = await bundledDb.query(_lastTable);
      await db.transaction((txn) async {
        for (final row in bundledServerRows) {
          await txn.insert(
            _table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final row in bundledLastRows) {
          await txn.insert(
            _lastTable,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      final rows = await _queryLastConnectInfo(db);
      final info = rows.isNotEmpty
          ? ServerConnectInfo.fromMap(rows.first)
          : ServerConnectInfo.fromMap(bundledServerRows.first);
      await _setLastConnected(db, info.serverIp, info.databaseName);
      debugLog(
        'seeded server connect info from bundled db: ${info.serverIp}/${info.databaseName}',
      );
      return info;
    } catch (e) {
      debugLog('failed to seed server connect info from bundled db: $e');
      return null;
    } finally {
      await bundledDb?.close();
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // ignore cleanup failure
      }
    }
  }

  static Future<void> _setLastConnected(
    Database db,
    String serverIp,
    String databaseName,
  ) async {
    await db.insert(_lastTable, {
      'RICH_SERVER_IP': serverIp,
      'RICH_DATABASE_NAME': databaseName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// upsert: 존재하면 업데이트, 없으면 삽입
  static Future<void> upsert(ServerConnectInfo info) async {
    final db = await open();
    await db.insert(
      _table,
      info.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // 마지막 접속 테이블 갱신 (업데이트 타임스탬프)
    await _setLastConnected(db, info.serverIp, info.databaseName);
  }

  /// 마지막 접속 정보 수동 갱신 (필요 시 호출)
  static Future<void> setLastConnected(
    String serverIp,
    String databaseName,
  ) async {
    final db = await open();
    await _setLastConnected(db, serverIp, databaseName);
  }

  /// DB 닫기
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
