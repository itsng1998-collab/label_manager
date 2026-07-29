import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imglib;
import 'package:label_manager/features/label_sheet/application/label_sheet_import_model.dart';

const String labelSheetDefaultGeminiModel = 'gemini-2.5-flash';
const Duration _labelSheetGeminiRequestTimeout = Duration(seconds: 300);
const Duration _labelSheetGeminiModelListTimeout = Duration(seconds: 30);
const int _labelSheetGeminiMaxUploadImageBytes = 4 * 1024 * 1024;
const int _labelSheetGeminiMaxUploadImageDimension = 2400;
const int _labelSheetGeminiUploadJpegQuality = 94;

class LabelSheetGeminiImportRequest {
  const LabelSheetGeminiImportRequest({
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.imageBytes,
    required this.mimeType,
    required this.fileName,
    required this.sheet,
    this.client,
  });

  final String apiKey;
  final String model;
  final String prompt;
  final Uint8List imageBytes;
  final String mimeType;
  final String fileName;
  final FortuneSheet sheet;
  final http.Client? client;
}

class LabelSheetGeminiImportException implements Exception {
  const LabelSheetGeminiImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LabelSheetGeminiModelInfo {
  const LabelSheetGeminiModelInfo({
    required this.modelId,
    required this.displayName,
    this.description,
  });

  final String modelId;
  final String displayName;
  final String? description;

  String get menuLabel {
    final label = displayName.trim().isEmpty ? modelId : displayName.trim();
    final suffix = description?.trim();
    return suffix == null || suffix.isEmpty ? label : '$label · $suffix';
  }
}

const List<LabelSheetGeminiModelInfo> labelSheetGeminiModels = [
  LabelSheetGeminiModelInfo(
    modelId: 'gemini-2.5-flash',
    displayName: 'Gemini 2.5 Flash',
    description: 'Google AI',
  ),
  LabelSheetGeminiModelInfo(
    modelId: 'gemini-2.5-pro',
    displayName: 'Gemini 2.5 Pro',
    description: 'Google AI',
  ),
  LabelSheetGeminiModelInfo(
    modelId: 'gemini-2.0-flash',
    displayName: 'Gemini 2.0 Flash',
    description: 'Google AI',
  ),
];

Future<List<LabelSheetGeminiModelInfo>> labelSheetFetchGeminiModels({
  required String apiKey,
  http.Client? client,
}) async {
  final trimmedApiKey = apiKey.trim();
  if (trimmedApiKey.isEmpty) {
    throw const LabelSheetGeminiImportException('Gemini API Key를 입력하세요.');
  }
  final uri = Uri.https('generativelanguage.googleapis.com', '/v1beta/models', {
    'key': trimmedApiKey,
  });
  final requestId = _geminiRequestId();
  final httpClient = client ?? http.Client();
  final closeClient = client == null;
  debugPrint(
    '[LabelSheetGemini] requestId=$requestId modelList start '
    'apiKey=${_maskedGeminiApiKey(trimmedApiKey)}',
  );
  try {
    final response = await httpClient
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_labelSheetGeminiModelListTimeout);
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId modelList response '
      'status=${response.statusCode} bytes=${response.bodyBytes.length}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logGeminiHttpFailure(
        requestId: requestId,
        operation: 'modelList',
        response: response,
      );
      throw LabelSheetGeminiImportException(
        _geminiHttpFailureMessage(response, operationLabel: 'Gemini 모델 조회'),
      );
    }
    final parsed = jsonDecode(response.body);
    if (parsed is! Map) {
      throw const LabelSheetGeminiImportException(
        'Gemini 모델 조회 응답 형식이 올바르지 않습니다.',
      );
    }
    final models = _geminiModelsFromListResponse(parsed);
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId modelList parsed '
      'models=${models.map((model) => model.modelId).join(',')}',
    );
    return models;
  } on TimeoutException {
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId modelList timeout '
      'timeoutSec=${_labelSheetGeminiModelListTimeout.inSeconds}',
    );
    throw const LabelSheetGeminiImportException('Gemini 모델 목록 조회 시간이 초과되었습니다.');
  } finally {
    if (closeClient) {
      httpClient.close();
    }
  }
}

List<LabelSheetGeminiModelInfo> _geminiModelsFromListResponse(Map response) {
  final rawModels = response['models'];
  if (rawModels is! List) {
    throw const LabelSheetGeminiImportException(
      'Gemini 모델 조회 응답에 models 목록이 없습니다.',
    );
  }
  final models = <LabelSheetGeminiModelInfo>[];
  final seen = <String>{};
  for (final rawModel in rawModels) {
    if (rawModel is! Map) {
      continue;
    }
    final methods = rawModel['supportedGenerationMethods'];
    if (methods is List && !methods.contains('generateContent')) {
      continue;
    }
    final rawName = _geminiStringField(rawModel['name']);
    if (rawName == null || rawName.isEmpty) {
      continue;
    }
    final modelId = rawName.startsWith('models/')
        ? rawName.substring('models/'.length)
        : rawName;
    if (!seen.add(modelId)) {
      continue;
    }
    models.add(
      LabelSheetGeminiModelInfo(
        modelId: modelId,
        displayName: _geminiStringField(rawModel['displayName']) ?? modelId,
        description: 'Google AI',
      ),
    );
  }
  if (models.isEmpty) {
    throw const LabelSheetGeminiImportException(
      'generateContent를 지원하는 Gemini 모델이 없습니다.',
    );
  }
  return labelSheetSortedGeminiModels(models);
}

List<LabelSheetGeminiModelInfo> labelSheetSortedGeminiModels(
  Iterable<LabelSheetGeminiModelInfo> models,
) {
  final sorted = models.toList(growable: false);
  sorted.sort(_compareGeminiModelMenuOrder);
  return sorted;
}

int _compareGeminiModelMenuOrder(
  LabelSheetGeminiModelInfo left,
  LabelSheetGeminiModelInfo right,
) {
  final leftIsGemini = left.modelId.startsWith('gemini-');
  final rightIsGemini = right.modelId.startsWith('gemini-');
  if (leftIsGemini != rightIsGemini) {
    return leftIsGemini ? -1 : 1;
  }
  final modelCompare = right.modelId.toLowerCase().compareTo(
    left.modelId.toLowerCase(),
  );
  if (modelCompare != 0) {
    return modelCompare;
  }
  return right.displayName.toLowerCase().compareTo(
    left.displayName.toLowerCase(),
  );
}

String? _geminiStringField(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Future<LabelSheetImageImportDraft> labelSheetAnalyzeImageWithGemini(
  LabelSheetGeminiImportRequest request,
) async {
  final apiKey = request.apiKey.trim();
  if (apiKey.isEmpty) {
    throw const LabelSheetGeminiImportException('Gemini API Key를 입력하세요.');
  }
  final model = request.model.trim().isEmpty
      ? labelSheetDefaultGeminiModel
      : request.model.trim();
  final prompt = labelSheetGeminiPrompt(
    sheet: request.sheet,
    imageBytes: request.imageBytes,
    fileName: request.fileName,
    userPrompt: request.prompt,
  );
  final uploadImage = _geminiUploadImagePayload(
    request.imageBytes,
    mimeType: request.mimeType,
  );
  final uploadImageBase64 = base64Encode(uploadImage.bytes);
  final uri = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models/$model:generateContent',
    {'key': apiKey},
  );
  final client = request.client ?? http.Client();
  final closeClient = request.client == null;
  final requestId = _geminiRequestId();
  final stopwatch = Stopwatch()..start();
  debugPrint(
    '[LabelSheetGemini] requestId=$requestId generateContent start '
    'model=$model apiKey=${_maskedGeminiApiKey(apiKey)} '
    'sourceMime=${request.mimeType} sourceBytes=${request.imageBytes.lengthInBytes} '
    'uploadMime=${uploadImage.mimeType} uploadBytes=${uploadImage.bytes.lengthInBytes} '
    'uploadBase64Chars=${uploadImageBase64.length} '
    'reencoded=${uploadImage.reencoded} resized=${uploadImage.resized} '
    'sourcePixels=${uploadImage.sourceWidth}x${uploadImage.sourceHeight} '
    'uploadPixels=${uploadImage.uploadWidth}x${uploadImage.uploadHeight} '
    'promptChars=${prompt.length} timeoutSec=${_labelSheetGeminiRequestTimeout.inSeconds} '
    'fileName=${request.fileName}',
  );
  try {
    final response = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                  {
                    'inlineData': {
                      'mimeType': uploadImage.mimeType,
                      'data': uploadImageBase64,
                    },
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.1,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(_labelSheetGeminiRequestTimeout);
    stopwatch.stop();
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId generateContent response '
      'status=${response.statusCode} elapsedMs=${stopwatch.elapsedMilliseconds} '
      'bodyChars=${response.body.length}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logGeminiHttpFailure(
        requestId: requestId,
        operation: 'generateContent',
        response: response,
      );
      throw LabelSheetGeminiImportException(
        _geminiHttpFailureMessage(
          response,
          operationLabel: 'Gemini 요청',
        ),
      );
    }
    final text = _geminiResponseText(response.body);
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId responseText '
      'chars=${text.length} text=${_compactGeminiText(text, limit: 6000)}',
    );
    final json = _decodeGeminiJson(text);
    final draft = labelSheetDraftFromAiJson(
      json,
      sheet: request.sheet,
      imageBytes: request.imageBytes,
      mimeType: request.mimeType,
      fileName: request.fileName,
      allowSourceImage: false,
    );
    if (draft.cells.isEmpty) {
      throw const LabelSheetGeminiImportException(
        'Gemini 응답에 편집 가능한 셀이 없습니다. '
        '원본 이미지를 통째로 넣는 응답은 적용하지 않았습니다.',
      );
    }
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId draft '
      'rows=${draft.rowHeights.length} columns=${draft.columnWidths.length} '
      'cells=${draft.cells.length} images=${draft.images.length} '
      'widthPx=${_sumDraftSize(draft.columnWidths).toStringAsFixed(2)} '
      'heightPx=${_sumDraftSize(draft.rowHeights).toStringAsFixed(2)}',
    );
    return draft;
  } on TimeoutException {
    stopwatch.stop();
    debugPrint(
      '[LabelSheetGemini] requestId=$requestId generateContent timeout '
      'elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    throw const LabelSheetGeminiImportException(
      'Gemini 요청 시간이 초과되었습니다. 이미지가 복잡하거나 네트워크 응답이 지연되었습니다.',
    );
  } finally {
    if (closeClient) {
      client.close();
    }
  }
}

String _geminiHttpFailureMessage(
  http.Response response, {
  required String operationLabel,
}) {
  final lines = <String>['$operationLabel 실패: HTTP ${response.statusCode}'];
  final parsed = _geminiErrorSummary(response.body);
  if (parsed.isNotEmpty) {
    lines.addAll(parsed);
  } else {
    final body = _compactGeminiText(response.body);
    if (body.isNotEmpty) {
      lines.add('responseBody: $body');
    }
  }
  return lines.join('\n');
}

List<String> _geminiErrorSummary(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      return const <String>[];
    }
    final error = decoded['error'];
    if (error is! Map) {
      return const <String>[];
    }
    final lines = <String>[];
    final status = '${error['status'] ?? ''}'.trim();
    if (status.isNotEmpty) {
      lines.add('status: $status');
    }
    final code = error['code'];
    if (code != null) {
      lines.add('code: $code');
    }
    final type = '${error['type'] ?? ''}'.trim();
    if (type.isNotEmpty) {
      lines.add('type: $type');
    }
    final message = '${error['message'] ?? ''}'.trim();
    if (message.isNotEmpty) {
      lines.add('message: $message');
    }
    final details = error['details'];
    if (details is List) {
      for (final detail in details.whereType<Map>()) {
        lines.addAll(_geminiErrorDetailSummary(detail));
      }
    } else if (details is Map) {
      lines.addAll(_geminiErrorDetailSummary(details));
    }
    return lines;
  } catch (_) {
    return const <String>[];
  }
}

List<String> _geminiErrorDetailSummary(Map detail) {
  final lines = <String>[];
  final type = '${detail['@type'] ?? ''}'.trim();
  final reason = '${detail['reason'] ?? ''}'.trim();
  final domain = '${detail['domain'] ?? ''}'.trim();
  if (type.isNotEmpty || reason.isNotEmpty || domain.isNotEmpty) {
    lines.add(
      'detail: ${[if (type.isNotEmpty) type, if (reason.isNotEmpty) reason, if (domain.isNotEmpty) domain].join(' | ')}',
    );
  }
  final violations = detail['violations'];
  if (violations is List) {
    for (final violation in violations.whereType<Map>()) {
      final fields = <String>[];
      for (final key in [
        'quotaMetric',
        'quotaId',
        'quotaDimensions',
        'quotaValue',
        'subject',
        'description',
      ]) {
        final value = violation[key];
        if (value != null && '$value'.trim().isNotEmpty) {
          fields.add('$key=$value');
        }
      }
      if (fields.isNotEmpty) {
        lines.add('quota: ${fields.join(', ')}');
      }
    }
  }
  final retryDelay = '${detail['retryDelay'] ?? ''}'.trim();
  if (retryDelay.isNotEmpty) {
    lines.add('retryDelay: $retryDelay');
  }
  return lines;
}

void _logGeminiHttpFailure({
  required String requestId,
  required String operation,
  required http.Response response,
}) {
  debugPrint(
    '[LabelSheetGemini] requestId=$requestId $operation failure '
    'status=${response.statusCode} headers=${_geminiSafeHeaders(response.headers)}',
  );
  debugPrint(
    '[LabelSheetGemini] requestId=$requestId $operation failureBody '
    '${_compactGeminiText(response.body, limit: 6000)}',
  );
}

Map<String, String> _geminiSafeHeaders(Map<String, String> headers) {
  return {
    for (final entry in headers.entries)
      if (!_sensitiveHeaderNames.contains(entry.key.toLowerCase()))
        entry.key: entry.value,
  };
}

const Set<String> _sensitiveHeaderNames = {
  'authorization',
  'cookie',
  'set-cookie',
  'x-goog-api-key',
};

String _compactGeminiText(String value, {int limit = 2000}) {
  final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= limit) {
    return compact;
  }
  return '${compact.substring(0, limit)}... (truncated ${compact.length - limit} chars)';
}

String _maskedGeminiApiKey(String apiKey) {
  if (apiKey.isEmpty) {
    return '(empty)';
  }
  final suffixLength = math.min(4, apiKey.length);
  return '***${apiKey.substring(apiKey.length - suffixLength)} len=${apiKey.length}';
}

String _geminiRequestId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final random = math.Random()
      .nextInt(0x10000)
      .toRadixString(16)
      .padLeft(4, '0');
  return '${now.toRadixString(16)}-$random';
}

_LabelSheetGeminiUploadImage _geminiUploadImagePayload(
  Uint8List imageBytes, {
  required String mimeType,
}) {
  final decoded = _decodeSourceImageGeometry(imageBytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return _LabelSheetGeminiUploadImage(
      bytes: imageBytes,
      mimeType: mimeType,
      reencoded: false,
      resized: false,
      sourceWidth: null,
      sourceHeight: null,
      uploadWidth: null,
      uploadHeight: null,
    );
  }

  final longestSide = math.max(decoded.width, decoded.height);
  final shouldResize = longestSide > _labelSheetGeminiMaxUploadImageDimension;
  final shouldReencode =
      shouldResize ||
      imageBytes.lengthInBytes > _labelSheetGeminiMaxUploadImageBytes;
  if (!shouldReencode) {
    return _LabelSheetGeminiUploadImage(
      bytes: imageBytes,
      mimeType: mimeType,
      reencoded: false,
      resized: false,
      sourceWidth: decoded.width,
      sourceHeight: decoded.height,
      uploadWidth: decoded.width,
      uploadHeight: decoded.height,
    );
  }

  final scale = shouldResize
      ? _labelSheetGeminiMaxUploadImageDimension / longestSide
      : 1.0;
  final uploadWidth = math.max(1, (decoded.width * scale).round());
  final uploadHeight = math.max(1, (decoded.height * scale).round());
  final uploadImage = shouldResize
      ? imglib.copyResize(
          decoded,
          width: uploadWidth,
          height: uploadHeight,
          interpolation: imglib.Interpolation.average,
        )
      : decoded;
  final encoded = Uint8List.fromList(
    imglib.encodeJpg(
      uploadImage,
      quality: _labelSheetGeminiUploadJpegQuality,
    ),
  );
  if (!shouldResize && encoded.lengthInBytes >= imageBytes.lengthInBytes) {
    return _LabelSheetGeminiUploadImage(
      bytes: imageBytes,
      mimeType: mimeType,
      reencoded: false,
      resized: false,
      sourceWidth: decoded.width,
      sourceHeight: decoded.height,
      uploadWidth: decoded.width,
      uploadHeight: decoded.height,
    );
  }
  return _LabelSheetGeminiUploadImage(
    bytes: encoded,
    mimeType: 'image/jpeg',
    reencoded: true,
    resized: shouldResize,
    sourceWidth: decoded.width,
    sourceHeight: decoded.height,
    uploadWidth: uploadImage.width,
    uploadHeight: uploadImage.height,
  );
}

class _LabelSheetGeminiUploadImage {
  const _LabelSheetGeminiUploadImage({
    required this.bytes,
    required this.mimeType,
    required this.reencoded,
    required this.resized,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.uploadWidth,
    required this.uploadHeight,
  });

  final Uint8List bytes;
  final String mimeType;
  final bool reencoded;
  final bool resized;
  final int? sourceWidth;
  final int? sourceHeight;
  final int? uploadWidth;
  final int? uploadHeight;
}

double _sumDraftSize(Map<int, double> sizes) {
  return sizes.values.fold<double>(0, (total, value) => total + value);
}

_LabelSheetSourceImageGeometry _sourceImageGeometry(
  Uint8List imageBytes, {
  required FortuneSheetGridClientPhysicalSize physicalSize,
}) {
  final decoded = _decodeSourceImageGeometry(imageBytes);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return _LabelSheetSourceImageGeometry(
      fittedWidthMm: physicalSize.widthMm.toDouble(),
      fittedHeightMm: physicalSize.heightMm.toDouble(),
      promptLines: '- pixelSize: unknown',
    );
  }
  final widthMm = physicalSize.widthMm.toDouble();
  final heightMm = physicalSize.heightMm.toDouble();
  final sourceAspectRatio = decoded.width / decoded.height;
  final sheetAspectRatio = widthMm / heightMm;
  final fittedWidthMm = sourceAspectRatio >= sheetAspectRatio
      ? widthMm
      : heightMm * sourceAspectRatio;
  final fittedHeightMm = sourceAspectRatio >= sheetAspectRatio
      ? widthMm / sourceAspectRatio
      : heightMm;
  return _LabelSheetSourceImageGeometry(
    fittedWidthMm: fittedWidthMm,
    fittedHeightMm: fittedHeightMm,
    promptLines:
        '- pixelWidth: ${decoded.width}\n'
        '- pixelHeight: ${decoded.height}\n'
        '- sourceAspectRatio: ${sourceAspectRatio.toStringAsFixed(4)}\n'
        '- fittedWidthMm: ${fittedWidthMm.toStringAsFixed(2)}\n'
        '- fittedHeightMm: ${fittedHeightMm.toStringAsFixed(2)}',
  );
}

imglib.Image? _decodeSourceImageGeometry(Uint8List imageBytes) {
  try {
    return imglib.decodeImage(imageBytes);
  } catch (_) {
    return null;
  }
}

class _LabelSheetSourceImageGeometry {
  const _LabelSheetSourceImageGeometry({
    required this.fittedWidthMm,
    required this.fittedHeightMm,
    required this.promptLines,
  });

  final double fittedWidthMm;
  final double fittedHeightMm;
  final String promptLines;
}

String labelSheetGeminiPrompt({
  required FortuneSheet sheet,
  required Uint8List imageBytes,
  required String fileName,
  required String userPrompt,
}) {
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final sourceGeometry = _sourceImageGeometry(
    imageBytes,
    physicalSize: physicalSize,
  );
  return '''
You are converting a label image into an editable FortuneSheet label layout.
Use millimeters as the only geometry unit.

Current adjusted sheet size:
- widthMm: ${physicalSize.widthMm}
- heightMm: ${physicalSize.heightMm}

Source image:
- fileName: $fileName
- byteLength: ${imageBytes.lengthInBytes}
${sourceGeometry.promptLines}

User conversion prompt:
${userPrompt.trim().isEmpty ? '(No extra instruction)' : userPrompt.trim()}

Return only valid JSON. Do not use markdown fences.
All coordinates and sizes must be in millimeters.
Clamp the layout inside the current adjusted sheet size.
columnsMm sum must be <= ${physicalSize.widthMm}.
rowsMm sum must be <= ${physicalSize.heightMm}.
Unless the user explicitly asks to stretch, preserve the source image aspect ratio.
Use the fitted layout size as the visual target: widthMm=${sourceGeometry.fittedWidthMm.toStringAsFixed(2)}, heightMm=${sourceGeometry.fittedHeightMm.toStringAsFixed(2)}.
columnsMm should sum close to ${sourceGeometry.fittedWidthMm.toStringAsFixed(2)} and rowsMm should sum close to ${sourceGeometry.fittedHeightMm.toStringAsFixed(2)}.
Do not insert the source image as one large picture.
The result must be editable: create rows, columns, cells, text, and merges.
Set sourceImage.keep to false unless the user explicitly asks to keep the source image.
If text is hard to read, still create an approximate editable layout with empty text cells instead of returning only the source image.
Prioritize visual fidelity over a simplified table: preserve section boundaries, thick separator lines, relative row heights, relative column widths, and dense text blocks.
Do not use equal-width columns or equal-height rows unless the image actually shows equal spacing.
For dense label text, prefer smaller font sizes and top alignment instead of stretching rows or splitting unrelated text into wide uniform table cells.
Keep original line breaks and placeholder tokens exactly when possible.
Represent visible blank/separator bands as short rows instead of dropping them.

JSON schema:
{
  "columnsMm": [number],
  "rowsMm": [number],
  "cells": [
    {
      "row": integer,
      "column": integer,
      "rowSpan": integer,
      "columnSpan": integer,
      "text": string,
      "bold": boolean,
      "fontSizePt": number,
      "horizontalAlign": "left" | "center" | "right",
      "verticalAlign": "top" | "middle" | "bottom"
    }
  ],
  "sourceImage": {
    "keep": boolean,
    "xMm": number,
    "yMm": number,
    "widthMm": number,
    "heightMm": number
  }
}
''';
}

LabelSheetImageImportDraft labelSheetDraftFromAiJson(
  Map<String, Object?> json, {
  required FortuneSheet sheet,
  required Uint8List imageBytes,
  required String mimeType,
  required String fileName,
  bool allowSourceImage = true,
}) {
  final physicalSize =
      fortuneSheetGridClientPhysicalSize(sheet) ??
      const FortuneSheetGridClientPhysicalSize(widthMm: 100, heightMm: 100);
  final columnsMm = _numberList(
    json['columnsMm'],
  ).map((value) => value.clamp(1, physicalSize.widthMm).toDouble()).toList();
  final rowsMm = _numberList(
    json['rowsMm'],
  ).map((value) => value.clamp(1, physicalSize.heightMm).toDouble()).toList();
  if (columnsMm.isEmpty || rowsMm.isEmpty) {
    throw const LabelSheetGeminiImportException(
      'Gemini 응답에 columnsMm/rowsMm가 없습니다.',
    );
  }
  _clampSum(columnsMm, physicalSize.widthMm.toDouble());
  _clampSum(rowsMm, physicalSize.heightMm.toDouble());

  final columnWidths = {
    for (var index = 0; index < columnsMm.length; index += 1)
      index: fortuneMillimetersToLogicalPixels(columnsMm[index]),
  };
  final rowHeights = {
    for (var index = 0; index < rowsMm.length; index += 1)
      index: fortuneMillimetersToLogicalPixels(rowsMm[index]),
  };

  final cells = <FortuneCellCoord, FortuneCell>{};
  for (final cellJson in _mapList(json['cells'])) {
    final row = _intValue(cellJson['row']).clamp(0, rowsMm.length - 1);
    final column = _intValue(cellJson['column']).clamp(0, columnsMm.length - 1);
    final rowSpan = _intValue(
      cellJson['rowSpan'],
      fallback: 1,
    ).clamp(1, rowsMm.length - row);
    final columnSpan = _intValue(
      cellJson['columnSpan'],
      fallback: 1,
    ).clamp(1, columnsMm.length - column);
    final text = '${cellJson['text'] ?? ''}'.trim();
    if (text.isEmpty && rowSpan == 1 && columnSpan == 1) {
      continue;
    }
    cells[FortuneCellCoord(row, column)] = FortuneCell(
      value: text,
      displayValue: text,
      bold: cellJson['bold'] == true,
      fontSize: _doubleValue(cellJson['fontSizePt'], fallback: 11).clamp(4, 72),
      horizontalAlign: _align(cellJson['horizontalAlign']),
      verticalAlign: _verticalAlign(cellJson['verticalAlign']),
      textWrap: 'wrap',
      merge: rowSpan > 1 || columnSpan > 1
          ? FortuneCellMerge(
              row: row,
              column: column,
              rowSpan: rowSpan,
              columnSpan: columnSpan,
            )
          : null,
    );
  }

  final sourceImage = _sourceImageJson(
    json['sourceImage'],
    physicalSize,
    allowSourceImage: allowSourceImage,
  );
  final images = <FortuneImage>[];
  if (sourceImage.keep) {
    images.add(
      FortuneImage(
        id: 'label-ai-import-${DateTime.now().microsecondsSinceEpoch}',
        src: 'data:$mimeType;base64,${base64Encode(imageBytes)}',
        left: fortuneMillimetersToLogicalPixels(sourceImage.xMm),
        top: fortuneMillimetersToLogicalPixels(sourceImage.yMm),
        width: fortuneMillimetersToLogicalPixels(sourceImage.widthMm),
        height: fortuneMillimetersToLogicalPixels(sourceImage.heightMm),
        extraFields: {
          'fileName': fileName,
          'labelAiImport': true,
          'widthMm': sourceImage.widthMm,
          'heightMm': sourceImage.heightMm,
        },
      ),
    );
  }

  return LabelSheetImageImportDraft(
    imageWidth: 0,
    imageHeight: 0,
    rowLines: const <int>[],
    columnLines: const <int>[],
    rowHeights: rowHeights,
    columnWidths: columnWidths,
    cells: cells,
    images: images,
  );
}

String _geminiResponseText(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const LabelSheetGeminiImportException(
      'Gemini 응답 형식이 올바르지 않습니다.',
    );
  }
  final candidates = decoded['candidates'];
  if (candidates is! List || candidates.isEmpty) {
    throw const LabelSheetGeminiImportException(
      'Gemini 응답 후보가 없습니다.',
    );
  }
  final content = candidates.first is Map
      ? (candidates.first as Map)['content']
      : null;
  final parts = content is Map ? content['parts'] : null;
  final text = switch (parts) {
    List parts =>
      parts
          .whereType<Map>()
          .map((part) => '${part['text'] ?? ''}')
          .join()
          .trim(),
    _ => '',
  };
  if (text.isEmpty) {
    throw const LabelSheetGeminiImportException(
      'Gemini 응답 텍스트가 비어 있습니다.',
    );
  }
  return text;
}

Map<String, Object?> _decodeGeminiJson(String text) {
  var normalized = text.trim();
  if (normalized.startsWith('```')) {
    normalized = normalized
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
  final decoded = jsonDecode(normalized);
  if (decoded is! Map) {
    throw const LabelSheetGeminiImportException(
      'Gemini JSON 응답이 객체가 아닙니다.',
    );
  }
  return Map<String, Object?>.from(decoded);
}

List<double> _numberList(Object? value) {
  if (value is! List) {
    return const <double>[];
  }
  return [
    for (final item in value)
      if (item is num && item.isFinite) item.toDouble(),
  ];
}

List<Map<String, Object?>> _mapList(Object? value) {
  if (value is! List) {
    return const <Map<String, Object?>>[];
  }
  return [
    for (final item in value)
      if (item is Map) Map<String, Object?>.from(item),
  ];
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num && value.isFinite) {
    return value.round();
  }
  return fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  return fallback;
}

void _clampSum(List<double> values, double maxSum) {
  final sum = values.fold<double>(0, (total, value) => total + value);
  if (sum <= 0 || sum <= maxSum) {
    return;
  }
  final scale = maxSum / sum;
  for (var index = 0; index < values.length; index += 1) {
    values[index] = math.max(1, values[index] * scale);
  }
}

String? _align(Object? value) {
  return switch ('$value') {
    'center' => 'center',
    'right' => 'right',
    'left' => 'left',
    _ => null,
  };
}

String? _verticalAlign(Object? value) {
  return switch ('$value') {
    'middle' => 'middle',
    'bottom' => 'bottom',
    'top' => 'top',
    _ => null,
  };
}

_AiSourceImage _sourceImageJson(
  Object? value,
  FortuneSheetGridClientPhysicalSize physicalSize, {
  required bool allowSourceImage,
}) {
  if (value is! Map) {
    return _AiSourceImage(
      keep: false,
      xMm: 0,
      yMm: 0,
      widthMm: physicalSize.widthMm.toDouble(),
      heightMm: physicalSize.heightMm.toDouble(),
    );
  }
  final map = Map<String, Object?>.from(value);
  final xMm = math.max(0, _doubleValue(map['xMm']));
  final yMm = math.max(0, _doubleValue(map['yMm']));
  final maxWidth = math.max(1.0, physicalSize.widthMm - xMm);
  final maxHeight = math.max(1.0, physicalSize.heightMm - yMm);
  return _AiSourceImage(
    keep: allowSourceImage && map['keep'] == true,
    xMm: xMm.clamp(0, physicalSize.widthMm).toDouble(),
    yMm: yMm.clamp(0, physicalSize.heightMm).toDouble(),
    widthMm: _doubleValue(
      map['widthMm'],
      fallback: physicalSize.widthMm.toDouble(),
    ).clamp(1, maxWidth).toDouble(),
    heightMm: _doubleValue(
      map['heightMm'],
      fallback: physicalSize.heightMm.toDouble(),
    ).clamp(1, maxHeight).toDouble(),
  );
}

class _AiSourceImage {
  const _AiSourceImage({
    required this.keep,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.heightMm,
  });

  final bool keep;
  final double xMm;
  final double yMm;
  final double widthMm;
  final double heightMm;
}
