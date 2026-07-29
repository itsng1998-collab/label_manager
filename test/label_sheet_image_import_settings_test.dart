import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_image_import_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('image import settings use defaults and round-trip values', () async {
    SharedPreferences.setMockInitialValues({});

    expect(
      await loadLabelSheetImageImportSettings(defaultModel: 'default-model'),
      isA<LabelSheetImageImportSettings>()
          .having((settings) => settings.apiKey, 'apiKey', '')
          .having((settings) => settings.model, 'model', 'default-model')
          .having((settings) => settings.prompt, 'prompt', '')
          .having((settings) => settings.filePath, 'filePath', ''),
    );

    await saveLabelSheetImageImportSettings(
      const LabelSheetImageImportSettings(
        apiKey: '  key  ',
        model: '  model  ',
        prompt: ' prompt ',
        filePath: '  C:/label.png  ',
      ),
    );

    expect(
      await loadLabelSheetImageImportSettings(defaultModel: 'fallback'),
      isA<LabelSheetImageImportSettings>()
          .having((settings) => settings.apiKey, 'apiKey', 'key')
          .having((settings) => settings.model, 'model', 'model')
          .having((settings) => settings.prompt, 'prompt', ' prompt ')
          .having(
            (settings) => settings.filePath,
            'filePath',
            'C:/label.png',
          ),
    );
  });

  test('image import partial settings ignore blank values', () async {
    SharedPreferences.setMockInitialValues({
      'label_sheet_gemini_model': 'model-1',
      'label_sheet_image_import_file_path': 'C:/before.png',
    });

    await saveLabelSheetImageImportModel('   ');
    await saveLabelSheetImageImportFilePath('');
    await saveLabelSheetImageImportCredentials(
      apiKey: '  key-2 ',
      model: ' model-2  ',
      prompt: ' prompt-2 ',
    );

    final settings = await loadLabelSheetImageImportSettings(
      defaultModel: 'fallback',
    );
    expect(settings.apiKey, 'key-2');
    expect(settings.model, 'model-2');
    expect(settings.prompt, ' prompt-2 ');
    expect(settings.filePath, 'C:/before.png');
  });
}