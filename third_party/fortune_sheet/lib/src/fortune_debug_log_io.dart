import 'dart:io';

void writeFortuneSheetDebugLogLine(String line, {required bool truncate}) {
  final file = File('.tmp/test.log');
  file.parent.createSync(recursive: true);
  if (truncate) {
    file.writeAsStringSync('', mode: FileMode.write, flush: true);
  }
  file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
}
