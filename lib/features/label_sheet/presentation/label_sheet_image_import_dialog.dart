import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_ai_import.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_import_model.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_components.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_preview.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String labelSheetGeminiApiKeyPrefsKey = 'label_sheet_gemini_api_key';
const String labelSheetGeminiModelPrefsKey = 'label_sheet_gemini_model';
const String labelSheetGeminiPromptPrefsKey = 'label_sheet_gemini_prompt';
const String labelSheetImageImportFilePathPrefsKey =
    'label_sheet_image_import_file_path';

const XTypeGroup _labelSheetImageImportFileGroup = XTypeGroup(
  label: 'Label image',
  extensions: <String>['png', 'jpg', 'jpeg', 'bmp', 'webp'],
  mimeTypes: <String>['image/*'],
);

String labelSheetImageImportMimeTypeForName(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'bmp' => 'image/bmp',
    'webp' => 'image/webp',
    _ => 'image/png',
  };
}

class LabelSheetImageImportSelection {
  const LabelSheetImageImportSelection({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
    required this.filePath,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
  final String filePath;
}

class LabelSheetImageImportAction {
  const LabelSheetImageImportAction({
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.fileName,
    required this.filePath,
    this.draft,
  });

  final String apiKey;
  final String model;
  final String prompt;
  final String fileName;
  final String filePath;
  final LabelSheetImageImportDraft? draft;
}

class LabelSheetImageImportDialog extends StatefulWidget {
  const LabelSheetImageImportDialog({
    required this.sheet,
    required this.physicalSize,
    required this.initialImage,
    required this.initialApiKey,
    required this.initialModel,
    required this.initialPrompt,
    this.close,
    super.key,
  });

  final FortuneSheet sheet;
  final FortuneSheetGridClientPhysicalSize physicalSize;
  final LabelSheetImageImportSelection? initialImage;
  final String initialApiKey;
  final String initialModel;
  final String initialPrompt;
  final ValueChanged<LabelSheetImageImportAction?>? close;

  @override
  State<LabelSheetImageImportDialog> createState() =>
      _LabelSheetImageImportDialogState();
}

class _LabelSheetImageImportDialogState
    extends State<LabelSheetImageImportDialog> {
  late LabelSheetImageImportSelection? _selectedImage = widget.initialImage;
  late final TextEditingController _apiKeyController = TextEditingController(
    text: widget.initialApiKey,
  );
  late final TextEditingController _modelController = TextEditingController(
    text: widget.initialModel,
  );
  late final TextEditingController _promptController = TextEditingController(
    text: widget.initialPrompt,
  );
  List<LabelSheetGeminiModelInfo> _geminiModels = labelSheetGeminiModels;
  bool _analyzing = false;
  bool _loadingGeminiModels = false;
  int _modelLoadGeneration = 0;
  String? _errorLog;

  void _close([LabelSheetImageImportAction? result]) {
    final close = widget.close;
    if (close != null) {
      close(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_refreshGeminiModels());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.78;
    return BlockingModelessDialogFrame(
      title: '라벨 이미지 가져오기',
      width: 640,
      height: dialogHeight,
      closeIcon: const LabelSheetImageImportCloseIcon(),
      onClose: _analyzing ? () {} : _close,
      footer: _buildFooter(),
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 30,
                    child: LabelSheetImageImportFooterButton(
                      label: '파일 선택',
                      onPressed: _analyzing ? null : _selectImageFile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedImage?.fileName ?? '선택된 파일 없음'} · '
                      '현재 시트 ${widget.physicalSize.widthMm} x '
                      '${widget.physicalSize.heightMm} mm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LabelSheetImageImportPreview(
                imageBytes: _selectedImage?.bytes,
                physicalSize: widget.physicalSize,
              ),
              const SizedBox(height: 14),
              LabelSheetImageImportApiKeyField(
                controller: _apiKeyController,
                enabled: !_analyzing,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'label-image-import-model-${_geminiModels.map((model) => model.modelId).join('|')}',
                ),
                initialValue: _selectedGeminiModelValue(
                  _modelController.text,
                  _geminiModels,
                ),
                isExpanded: true,
                decoration: labelSheetImageImportInputDecoration(
                  _loadingGeminiModels
                      ? 'Gemini Model 조회 중...'
                      : 'Gemini Model',
                ),
                items: [
                  for (final model in _geminiModels)
                    DropdownMenuItem(
                      value: model.modelId,
                      child: Text(model.menuLabel),
                    ),
                ],
                onChanged: _analyzing
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }
                        _modelController.text = value;
                        unawaited(_rememberSelectedGeminiModel(value));
                      },
              ),
              const SizedBox(height: 12),
              _compactTextField(
                controller: _promptController,
                labelText: '변환 프롬프트(mm 기준)',
                enabled: !_analyzing,
                minLines: 4,
                maxLines: 6,
                alignLabelWithHint: true,
              ),
              LabelSheetImageImportErrorPanel(message: _errorLog),
              const SizedBox(height: 8),
              Text(
                '* Gemini API Key와 model을 이 PC에 저장합니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshGeminiModels() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _selectFallbackGeminiModelIfNeeded();
      return;
    }
    final generation = ++_modelLoadGeneration;
    setState(() {
      _loadingGeminiModels = true;
    });
    try {
      final fetchedModels = await labelSheetFetchGeminiModels(apiKey: apiKey);
      if (!mounted || generation != _modelLoadGeneration) {
        return;
      }
      final models = _mergedGeminiModels(fetchedModels, labelSheetGeminiModels);
      _selectFallbackGeminiModelIfNeeded(models: models);
      setState(() {
        _geminiModels = models;
        _loadingGeminiModels = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _modelLoadGeneration) {
        return;
      }
      _selectFallbackGeminiModelIfNeeded();
      setState(() {
        _loadingGeminiModels = false;
        _errorLog = 'Gemini 모델 목록 조회 실패: $error';
      });
    }
  }

  Future<void> _rememberSelectedGeminiModel(String model) async {
    final trimmed = model.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(labelSheetGeminiModelPrefsKey, trimmed);
  }

  Future<void> _rememberGeminiImportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      labelSheetGeminiApiKeyPrefsKey,
      _apiKeyController.text.trim(),
    );
    await prefs.setString(
      labelSheetGeminiModelPrefsKey,
      _modelController.text.trim(),
    );
    await prefs.setString(
      labelSheetGeminiPromptPrefsKey,
      _promptController.text,
    );
  }

  Future<void> _selectImageFile() async {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_labelSheetImageImportFileGroup],
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted || bytes.isEmpty) {
      return;
    }
    final selection = LabelSheetImageImportSelection(
      bytes: bytes,
      mimeType: labelSheetImageImportMimeTypeForName(file.name),
      fileName: file.name,
      filePath: file.path,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      labelSheetImageImportFilePathPrefsKey,
      selection.filePath,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImage = selection;
      _errorLog = null;
    });
  }

  void _selectFallbackGeminiModelIfNeeded({
    List<LabelSheetGeminiModelInfo>? models,
  }) {
    final effectiveModels = models ?? _geminiModels;
    if (effectiveModels.isEmpty ||
        _selectedGeminiModelValue(_modelController.text, effectiveModels) !=
            null) {
      return;
    }
    _modelController.text =
        _selectedGeminiModelValue(
          labelSheetDefaultGeminiModel,
          effectiveModels,
        ) ??
        effectiveModels.first.modelId;
  }

  List<LabelSheetGeminiModelInfo> _mergedGeminiModels(
    List<LabelSheetGeminiModelInfo> fetchedModels,
    List<LabelSheetGeminiModelInfo> fallbackModels,
  ) {
    final merged = <LabelSheetGeminiModelInfo>[];
    final seen = <String>{};
    for (final model in [...fetchedModels, ...fallbackModels]) {
      if (seen.add(model.modelId)) {
        merged.add(model);
      }
    }
    return labelSheetSortedGeminiModels(merged);
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 84,
            height: 30,
            child: LabelSheetImageImportFooterButton(
              label: '취소',
              onPressed: _analyzing ? null : _close,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 112,
            height: 30,
            child: LabelSheetImageImportFooterButton(
              label: _analyzing ? '분석 중...' : 'AI 분석 적용',
              onPressed: _analyzing ? null : _applyGeminiAnalysis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactTextField({
    required TextEditingController controller,
    required String labelText,
    bool enabled = true,
    bool obscureText = false,
    bool alignLabelWithHint = false,
    int? minLines,
    int? maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      minLines: minLines,
      maxLines: obscureText ? 1 : maxLines,
      decoration: labelSheetImageImportInputDecoration(
        labelText,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }

  Future<void> _applyGeminiAnalysis() async {
    setState(() {
      _analyzing = true;
      _errorLog = null;
    });
    try {
      await _rememberGeminiImportSettings();
      final selectedImage = _selectedImage;
      if (selectedImage == null) {
        throw const LabelSheetGeminiImportException('분석할 이미지 파일을 선택하세요.');
      }
      final draft = await labelSheetAnalyzeImageWithGemini(
        LabelSheetGeminiImportRequest(
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim(),
          prompt: _promptController.text,
          imageBytes: selectedImage.bytes,
          mimeType: selectedImage.mimeType,
          fileName: selectedImage.fileName,
          sheet: widget.sheet,
        ),
      );
      if (!mounted) {
        return;
      }
      _close(
        LabelSheetImageImportAction(
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim(),
          prompt: _promptController.text,
          fileName: selectedImage.fileName,
          filePath: selectedImage.filePath,
          draft: draft,
        ),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _analyzing = false;
        _errorLog = '$error';
      });
    }
  }
}

String? _selectedGeminiModelValue(
  String current,
  List<LabelSheetGeminiModelInfo> models,
) {
  for (final model in models) {
    if (model.modelId == current) {
      return model.modelId;
    }
  }
  return null;
}
