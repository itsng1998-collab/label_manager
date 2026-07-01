import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/app.dart';

typedef _OutputDebugStringNative = Void Function(Pointer<Utf16>);
typedef _OutputDebugStringDart = void Function(Pointer<Utf16>);

class DebugLogger {
  DebugLogger._();

  static bool _initialized = false;
  static _OutputDebugStringDart? _outputDebugString;
  static File? _logFile;
  static IOSink? _logSink;
  static Future<void>? _logSinkDone;
  static void Function(String? message, {int? wrapWidth})? _originalDebugPrint;
  static String? _version;

  static void outputDebugString(String message) {
    final ptr = message.toNativeUtf16();
    try {
      _outputDebugString?.call(ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    _originalDebugPrint = debugPrint;
    _outputDebugString = _loadOutputDebugString();
    await _initApplogAndDebugPrint();
  }

  static void setVersion(String version) {
    _version = version;
    if (_logFile != null) {
      log('=== DebugLogger version: $version ===');
    }
  }

  static void log(String message) {
    debugPrint(message);
  }

  static Future<void> close() async {
    final sink = _logSink;
    final done = _logSinkDone;
    _logSink = null;
    _logSinkDone = null;
    _logFile = null;
    if (sink == null) {
      return;
    }
    try {
      await sink.flush();
      await sink.close();
      if (done != null) {
        await done;
      }
    } catch (error) {
      _originalDebugPrint?.call('DebugLogger: failed to close log -> $error');
    }
  }

  static _OutputDebugStringDart? _loadOutputDebugString() {
    if (!Platform.isWindows) {
      return null;
    }
    try {
      final lib = DynamicLibrary.open('kernel32.dll');
      return lib
          .lookupFunction<_OutputDebugStringNative, _OutputDebugStringDart>(
            'OutputDebugStringW',
          );
    } catch (e) {
      _originalDebugPrint?.call(
        'DebugLogger: failed to load OutputDebugStringW -> $e',
      );
      return null;
    }
  }

  static Future<void> _initApplogAndDebugPrint() async {
    try {
      final logDir = await _resolveLogDirectory();

      if (!await logDir.exists()) await logDir.create(recursive: true);
      await _deleteOldLogs(logDir);

      final now = DateTime.now();
      final stamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
      final logPath = p.join(logDir.path, 'app_$stamp.log');
      final logFile = File(logPath);

      _logFile = logFile;
      _logSink = logFile.openWrite(mode: FileMode.append);
      _logSinkDone = _logSink!.done.catchError((Object error) {
        _originalDebugPrint?.call('DebugLogger: log sink error -> $error');
      });
      _originalDebugPrint?.call('LogPath: $logPath');

      debugPrint = (String? message, {int? wrapWidth}) {
        final safeMessage = message ?? '';
        final prefixed = '[LM] $safeMessage';
        final highVolumeLog = _isHighVolumeLog(safeMessage);

        if (!highVolumeLog && Platform.isWindows && _outputDebugString != null) {
          final nativeStr = prefixed.toNativeUtf16();
          try {
            _outputDebugString!(nativeStr);
          } finally {
            calloc.free(nativeStr);
          }
        }

        if (!highVolumeLog) {
          _originalDebugPrint?.call(prefixed, wrapWidth: wrapWidth);
        }
        _writeLogLine('${DateTime.now().toIso8601String()} $safeMessage');
      };

      log('=== DebugLogger initialized: $logPath ===');
      if (_version != null) {
        log('=== DebugLogger version: $_version ===');
      }

      FlutterError.onError = (FlutterErrorDetails d) {
        debugPrint('FlutterError: ${d.toString()}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught: $error');
        debugPrint(stack.toString());
        return true;
      };
    } catch (e) {
      _originalDebugPrint?.call('DebugLogger: initialization failed -> $e');
    }
  }

  static Future<Directory> _resolveLogDirectory() async {
    if (Platform.isWindows && kReleaseMode) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.trim().isNotEmpty) {
        return Directory(p.join(appData, 'com.itsng', APP_TITLE_SHORT, 'log'));
      }
    }

    final baseDir = (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? Directory.current
        : await getApplicationSupportDirectory();
    return Directory(
      Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? p.join(baseDir.path, '.tmp', 'log')
          : p.join(baseDir.path, 'log'),
    );
  }

  static bool _isHighVolumeLog(String message) {
    return message.startsWith('cellEditorTrace#');
  }

  static void _writeLogLine(String line) {
    try {
      _logSink?.writeln(line);
    } catch (error) {
      _originalDebugPrint?.call('DebugLogger: failed to write log -> $error');
    }
  }

  static Future<void> _deleteOldLogs(Directory logDir) async {
    try {
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final logFileEntities = logDir.listSync();

      for (final entity in logFileEntities) {
        if (entity is File) {
          final fileName = p.basename(entity.path);
          if (fileName.startsWith('app_') && fileName.endsWith('.log')) {
            try {
              final match = RegExp(
                r'^app_(\d{4}-\d{2}-\d{2})(?:_(\d{2}-\d{2}-\d{2}))?\.log$',
              ).firstMatch(fileName);
              if (match != null) {
                final datePart = match.group(1)!;
                final timePart = match.group(2);
                final dateTimeString = timePart != null
                    ? '${datePart}_$timePart'
                    : datePart;
                final formatter = DateFormat(
                  timePart != null ? 'yyyy-MM-dd_HH-mm-ss' : 'yyyy-MM-dd',
                );
                final fileDate = formatter.parse(dateTimeString);

                if (fileDate.isBefore(oneMonthAgo)) {
                  await entity.delete();
                  _originalDebugPrint?.call(
                    'Deleted old log file: ${entity.path}',
                  );
                }
              } else {
                _originalDebugPrint?.call(
                  'Could not parse log file name: ${entity.path}',
                );
              }
            } catch (e) {
              _originalDebugPrint?.call(
                'Could not process log file ${entity.path}: $e',
              );
            }
          }
        }
      }
    } catch (e) {
      _originalDebugPrint?.call('Failed to delete old logs: $e');
    }
  }
}
