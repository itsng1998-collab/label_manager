import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_file_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('label file directory ignores blank values and stores parent', () async {
    SharedPreferences.setMockInitialValues({'label_file_directory': ''});

    expect(await loadLabelSheetFileDirectory(), isNull);

    await saveLabelSheetFileDirectoryForPath('C:/labels/import/label.xlsx');
    expect(await loadLabelSheetFileDirectory(), 'C:/labels/import');

    await saveLabelSheetFileDirectoryForPath('');
    expect(await loadLabelSheetFileDirectory(), 'C:/labels/import');
  });
}