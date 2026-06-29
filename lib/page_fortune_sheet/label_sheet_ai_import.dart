import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imglib;
import 'package:label_manager/page_fortune_sheet/label_sheet_import_model.dart';

const String labelSheetDefaultCopilotModel = 'openai/gpt-4.1';

class LabelSheetCopilotImportRequest {
  const LabelSheetCopilotImportRequest({
    required this.token,
    required this.model,
    required this.prompt,
    required this.imageBytes,
    required this.mimeType,
    required this.fileName,
    required this.sheet,
    this.client,
  });

  final String token;
  final String model;
  final String prompt;
  final Uint8List imageBytes;
  final String mimeType;
  final String fileName;
  final FortuneSheet sheet;
  final http.Client? client;
}

class LabelSheetCopilotImportException implements Exception {
  const LabelSheetCopilotImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LabelSheetCopilotModelInfo {
  const LabelSheetCopilotModelInfo({
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

const List<LabelSheetCopilotModelInfo> labelSheetCopilotModels = [
  LabelSheetCopilotModelInfo(
    modelId: 'openai/gpt-4.1',
    displayName: 'GPT-4.1',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/gpt-4.1-mini',
    displayName: 'GPT-4.1 mini',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/gpt-4.1-nano',
    displayName: 'GPT-4.1 nano',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/gpt-4o',
    displayName: 'GPT-4o',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/gpt-4o-mini',
    displayName: 'GPT-4o mini',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/o4-mini',
    displayName: 'o4-mini',
    description: 'GitHub Models',
  ),
  LabelSheetCopilotModelInfo(
    modelId: 'openai/o3',
    displayName: 'o3',
    description: 'GitHub Models',
  ),
];

Future<LabelSheetImageImportDraft> labelSheetAnalyzeImageWithCopilot(
  LabelSheetCopilotImportRequest request,
) async {
  final token = request.token.trim();
  if (token.isEmpty) {
    throw const LabelSheetCopilotImportException('GitHub token을 입력하세요.');
  }
  final model = request.model.trim().isEmpty
      ? labelSheetDefaultCopilotModel
      : request.model.trim();
  final prompt = labelSheetCopilotPrompt(
    sheet: request.sheet,
    imageBytes: request.imageBytes,
    fileName: request.fileName,
    userPrompt: request.prompt,
  );
  final uri = Uri.https('models.github.ai', '/inference/chat/completions');
  final client = request.client ?? http.Client();
  final closeClient = request.client == null;
  final requestId = _copilotRequestId();
  final stopwatch = Stopwatch()..start();
  debugPrint(
    '[LabelSheetCopilot] requestId=$requestId chatCompletions start '
    'model=$model token=${_maskedCopilotToken(token)} '
    'mime=${request.mimeType} imageBytes=${request.imageBytes.lengthInBytes} '
    'promptChars=${prompt.length} fileName=${request.fileName}',
  );
  try {
    final response = await client
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'Return only valid JSON for the requested label layout.',
              },
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url':
                          'data:${request.mimeType};base64,${base64Encode(request.imageBytes)}',
                    },
                  },
                ],
              },
            ],
            'temperature': 0.1,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(const Duration(seconds: 90));
    stopwatch.stop();
    debugPrint(
      '[LabelSheetCopilot] requestId=$requestId chatCompletions response '
      'status=${response.statusCode} elapsedMs=${stopwatch.elapsedMilliseconds} '
      'bodyChars=${response.body.length}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logCopilotHttpFailure(
        requestId: requestId,
        operation: 'chatCompletions',
        response: response,
      );
      throw LabelSheetCopilotImportException(
        _copilotHttpFailureMessage(
          response,
          operationLabel: 'GitHub Copilot Chat 요청',
        ),
      );
    }
    final text = _copilotResponseText(response.body);
    debugPrint(
      '[LabelSheetCopilot] requestId=$requestId responseText '
      'chars=${text.length} text=${_compactCopilotText(text, limit: 6000)}',
    );
    final json = _decodeCopilotJson(text);
    final draft = labelSheetDraftFromAiJson(
      json,
      sheet: request.sheet,
      imageBytes: request.imageBytes,
      mimeType: request.mimeType,
      fileName: request.fileName,
      allowSourceImage: false,
    );
    if (draft.cells.isEmpty) {
      throw const LabelSheetCopilotImportException(
        'GitHub Copilot Chat 응답에 편집 가능한 셀이 없습니다. '
        '원본 이미지를 통째로 넣는 응답은 적용하지 않았습니다.',
      );
    }
    debugPrint(
      '[LabelSheetCopilot] requestId=$requestId draft '
      'rows=${draft.rowHeights.length} columns=${draft.columnWidths.length} '
      'cells=${draft.cells.length} images=${draft.images.length} '
      'widthPx=${_sumDraftSize(draft.columnWidths).toStringAsFixed(2)} '
      'heightPx=${_sumDraftSize(draft.rowHeights).toStringAsFixed(2)}',
    );
    return draft;
  } on TimeoutException {
    stopwatch.stop();
    debugPrint(
      '[LabelSheetCopilot] requestId=$requestId chatCompletions timeout '
      'elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat 요청 시간이 초과되었습니다.',
    );
  } finally {
    if (closeClient) {
      client.close();
    }
  }
}

String _copilotHttpFailureMessage(
  http.Response response, {
  required String operationLabel,
}) {
  final lines = <String>['$operationLabel 실패: HTTP ${response.statusCode}'];
  final parsed = _copilotErrorSummary(response.body);
  if (parsed.isNotEmpty) {
    lines.addAll(parsed);
  } else {
    final body = _compactCopilotText(response.body);
    if (body.isNotEmpty) {
      lines.add('responseBody: $body');
    }
  }
  return lines.join('\n');
}

List<String> _copilotErrorSummary(String body) {
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
        lines.addAll(_copilotErrorDetailSummary(detail));
      }
    } else if (details is Map) {
      lines.addAll(_copilotErrorDetailSummary(details));
    }
    return lines;
  } catch (_) {
    return const <String>[];
  }
}

List<String> _copilotErrorDetailSummary(Map detail) {
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

void _logCopilotHttpFailure({
  required String requestId,
  required String operation,
  required http.Response response,
}) {
  debugPrint(
    '[LabelSheetCopilot] requestId=$requestId $operation failure '
    'status=${response.statusCode} headers=${_copilotSafeHeaders(response.headers)}',
  );
  debugPrint(
    '[LabelSheetCopilot] requestId=$requestId $operation failureBody '
    '${_compactCopilotText(response.body, limit: 6000)}',
  );
}

Map<String, String> _copilotSafeHeaders(Map<String, String> headers) {
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
  'x-github-token',
};

String _compactCopilotText(String value, {int limit = 2000}) {
  final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= limit) {
    return compact;
  }
  return '${compact.substring(0, limit)}... (truncated ${compact.length - limit} chars)';
}

String _maskedCopilotToken(String token) {
  if (token.isEmpty) {
    return '(empty)';
  }
  final suffixLength = math.min(4, token.length);
  return '***${token.substring(token.length - suffixLength)} len=${token.length}';
}

String _copilotRequestId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final random = math.Random()
      .nextInt(0x10000)
      .toRadixString(16)
      .padLeft(4, '0');
  return '${now.toRadixString(16)}-$random';
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

String labelSheetCopilotPrompt({
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
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat 응답에 columnsMm/rowsMm가 없습니다.',
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

String _copilotResponseText(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map) {
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat 응답 형식이 올바르지 않습니다.',
    );
  }
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat 응답 후보가 없습니다.',
    );
  }
  final message = choices.first is Map
      ? (choices.first as Map)['message']
      : null;
  final content = message is Map ? message['content'] : null;
  final text = switch (content) {
    String value => value.trim(),
    List parts =>
      parts
          .whereType<Map>()
          .map((part) => '${part['text'] ?? ''}')
          .join()
          .trim(),
    _ => '',
  };
  if (text.isEmpty) {
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat 응답 텍스트가 비어 있습니다.',
    );
  }
  return text;
}

Map<String, Object?> _decodeCopilotJson(String text) {
  var normalized = text.trim();
  if (normalized.startsWith('```')) {
    normalized = normalized
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
  final decoded = jsonDecode(normalized);
  if (decoded is! Map) {
    throw const LabelSheetCopilotImportException(
      'GitHub Copilot Chat JSON 응답이 객체가 아닙니다.',
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
