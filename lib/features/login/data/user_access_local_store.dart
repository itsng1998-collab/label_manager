import 'dart:io';

class UserAccessLocalStore {
  static final File _file = File(r'C:\ITS\labelmanager_user_access.ini');
  static const _header = '[USER_ACCESS_LOG]';
  static const _key = 'ACCESS_DATA=';

  static Future<String> read() async {
    if (!await _file.exists()) return '';
    for (final line in await _file.readAsLines()) {
      if (line.startsWith(_key)) return line.substring(_key.length).trim();
    }
    return '';
  }

  static Future<void> write(String value) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString('$_header\r\n$_key$value\r\n');
  }
}