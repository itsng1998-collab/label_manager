import 'package:shared_preferences/shared_preferences.dart';

const String _geminiApiKeyPrefsKey = 'label_sheet_gemini_api_key';
const String _geminiModelPrefsKey = 'label_sheet_gemini_model';
const String _geminiPromptPrefsKey = 'label_sheet_gemini_prompt';
const String _imageFilePathPrefsKey = 'label_sheet_image_import_file_path';

class LabelSheetImageImportSettings {
  const LabelSheetImageImportSettings({
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.filePath,
  });

  final String apiKey;
  final String model;
  final String prompt;
  final String filePath;
}

Future<LabelSheetImageImportSettings> loadLabelSheetImageImportSettings({
  required String defaultModel,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return LabelSheetImageImportSettings(
    apiKey: prefs.getString(_geminiApiKeyPrefsKey) ?? '',
    model: prefs.getString(_geminiModelPrefsKey) ?? defaultModel,
    prompt: prefs.getString(_geminiPromptPrefsKey) ?? '',
    filePath: prefs.getString(_imageFilePathPrefsKey) ?? '',
  );
}

Future<void> saveLabelSheetImageImportSettings(
  LabelSheetImageImportSettings settings,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_geminiApiKeyPrefsKey, settings.apiKey.trim());
  await prefs.setString(_geminiModelPrefsKey, settings.model.trim());
  await prefs.setString(_geminiPromptPrefsKey, settings.prompt);
  await prefs.setString(_imageFilePathPrefsKey, settings.filePath.trim());
}

Future<void> saveLabelSheetImageImportCredentials({
  required String apiKey,
  required String model,
  required String prompt,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_geminiApiKeyPrefsKey, apiKey.trim());
  await prefs.setString(_geminiModelPrefsKey, model.trim());
  await prefs.setString(_geminiPromptPrefsKey, prompt);
}

Future<void> saveLabelSheetImageImportModel(String model) async {
  final trimmed = model.trim();
  if (trimmed.isEmpty) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_geminiModelPrefsKey, trimmed);
}

Future<void> saveLabelSheetImageImportFilePath(String filePath) async {
  final trimmed = filePath.trim();
  if (trimmed.isEmpty) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_imageFilePathPrefsKey, trimmed);
}
