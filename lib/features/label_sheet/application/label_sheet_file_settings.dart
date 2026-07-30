import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

const String _labelFileDirectoryPrefsKey = 'label_file_directory';

Future<String?> loadLabelSheetFileDirectory() async {
  final prefs = await SharedPreferences.getInstance();
  final directory = prefs.getString(_labelFileDirectoryPrefsKey);
  return directory?.isNotEmpty == true ? directory : null;
}

Future<void> saveLabelSheetFileDirectoryForPath(String filePath) async {
  if (filePath.isEmpty) {
    return;
  }
  final directory = p.dirname(filePath);
  if (directory.isEmpty) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_labelFileDirectoryPrefsKey, directory);
}