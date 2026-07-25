import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';

int labelOutputPreviewValuesFingerprint(Map<int, String>? values) {
  if (values == null || values.isEmpty) return 0;
  final entries = values.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.expand((entry) => <Object>[entry.key, entry.value]),
  );
}

class LabelOutputPreview extends StatefulWidget {
  const LabelOutputPreview({
    super.key,
    required this.workbook,
    required this.hintText,
    required this.identityKey,
    required this.imageObjectIds,
    required this.barcodeObjectIds,
    this.labelSize,
    this.outputCaptureController,
    this.zoomToolbarPlacement =
      LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
    this.zoomController,
    this.autoFitWidth = false,
  });

  final fs.FortuneWorkbook? workbook;
  final String? hintText;
  final String identityKey;
  final LabelSize? labelSize;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final LabelSheetOutputCaptureController? outputCaptureController;
  final LabelSheetZoomToolbarPlacement zoomToolbarPlacement;
  final LabelSheetZoomController? zoomController;
  final bool autoFitWidth;

  @override
  State<LabelOutputPreview> createState() => _LabelOutputPreviewState();
}

class _LabelOutputPreviewState extends State<LabelOutputPreview> {
  @override
  void didUpdateWidget(covariant LabelOutputPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outputCaptureController == widget.outputCaptureController &&
        oldWidget.identityKey != widget.identityKey) {
      widget.outputCaptureController?.replaceAttachedOwner(
        expectedOwnerToken: oldWidget.identityKey,
        newOwnerToken: widget.identityKey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final captureController = widget.outputCaptureController;
    final attachedOwnerToken = captureController?.attachedOwnerToken;
    if (attachedOwnerToken != null &&
        attachedOwnerToken != widget.identityKey) {
      captureController!.replaceAttachedOwner(
        expectedOwnerToken: attachedOwnerToken,
        newOwnerToken: widget.identityKey,
      );
    }
    final hint = widget.hintText;
    if (hint != null) return _LabelOutputPreviewHint(hint);
    final value = widget.workbook;
    if (value == null) {
      return const _LabelOutputPreviewHint('현재 공용라벨 시트가 없습니다.');
    }
    final messages = labelOutputPreviewMessages(value);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.autoFitWidth && constraints.maxWidth.isFinite) {
          widget.zoomController?.applyInitialAutoFit(
            labelOutputPreviewFitWidthZoomPercent(
              viewportWidth: constraints.maxWidth,
              sheet: value.activeSheet,
            ),
          );
        }
        return Column(
          children: [
            if (messages.isNotEmpty)
              _LabelOutputPreviewMessages(messages: messages),
            Expanded(
              child: LabelSheetWorkbench(
                key: ValueKey(widget.identityKey),
                initialWorkbook: value,
                labelSize: widget.labelSize,
                imageObjectIds: widget.imageObjectIds,
                barcodeObjectIds: widget.barcodeObjectIds,
                outputCaptureController: widget.outputCaptureController,
                outputCaptureOwnerToken: widget.identityKey,
                hideToolbar: true,
                hideRowColumnHeaderLabels: true,
                hideSelectionHighlight: true,
                rulerCornerSizeLabelUsesAsterisk: true,
                disableSheetRulerGuideInteraction: true,
                hideStatisticBar: true,
                copyOnlyContextMenu: true,
                canEditObjects: false,
                allowObjectPanel: false,
                showObjectPanelOpenButton: false,
                zoomToolbarPlacement: widget.zoomToolbarPlacement,
                zoomController: widget.zoomController,
              ),
            ),
          ],
        );
      },
    );
  }
}

int labelOutputPreviewFitWidthZoomPercent({
  required double viewportWidth,
  required fs.FortuneSheet sheet,
  double? fallbackLabelWidthMm,
}) {
  const reservedWidth = 58.0;
  final labelWidth =
      fs.fortuneSheetGridClientLogicalSize(sheet)?.width ??
      (fallbackLabelWidthMm != null && fallbackLabelWidthMm > 0
          ? fs.fortuneMillimetersToLogicalPixels(fallbackLabelWidthMm)
          : null);
  if (labelWidth == null || labelWidth <= 0) {
    return labelSheetDefaultZoomPercent;
  }
  final availableWidth = math.max(1.0, viewportWidth - reservedWidth);
  final rawPercent = availableWidth / labelWidth * 100;
  final steppedPercent = (rawPercent / 10).floor() * 10;
  return steppedPercent.clamp(
    labelSheetMinZoomPercent,
    labelSheetMaxZoomPercent,
  );
}

List<({String text, bool error})> labelOutputPreviewMessages(
  fs.FortuneWorkbook workbook,
) {
  final messages = <({String text, bool error})>[];
  final seen = <String>{};
  for (final sheet in workbook.sheets) {
    for (final image in sheet.images) {
      final warning = image.extraFields['itemCodeWarning']?.toString().trim();
      final error = image.extraFields['itemCodeError']?.toString().trim();
      if (warning != null && warning.isNotEmpty && seen.add('w:$warning')) {
        messages.add((text: warning, error: false));
      }
      if (error != null && error.isNotEmpty && seen.add('e:$error')) {
        messages.add((text: error, error: true));
      }
    }
  }
  return messages;
}

class _LabelOutputPreviewMessages extends StatelessWidget {
  const _LabelOutputPreviewMessages({required this.messages});

  final List<({String text, bool error})> messages;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(maxHeight: 96),
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListView.separated(
      shrinkWrap: true,
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              message.error ? Icons.error_outline : Icons.warning_amber,
              size: 16,
              color: message.error
                  ? Theme.of(context).colorScheme.error
                  : Colors.orange.shade800,
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(message.text)),
          ],
        );
      },
    ),
  );
}

class _LabelOutputPreviewHint extends StatelessWidget {
  const _LabelOutputPreviewHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color(0xFF5F6368),
      ),
    ),
  );
}