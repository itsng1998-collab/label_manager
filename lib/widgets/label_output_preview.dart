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

class LabelOutputPreview extends StatelessWidget {
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
    this.zoomToolbarAnchorLink,
  });

  final fs.FortuneWorkbook? workbook;
  final String? hintText;
  final String identityKey;
  final LabelSize? labelSize;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final LabelSheetOutputCaptureController? outputCaptureController;
  final LabelSheetZoomToolbarPlacement zoomToolbarPlacement;
  final LayerLink? zoomToolbarAnchorLink;

  @override
  Widget build(BuildContext context) {
    final hint = hintText;
    if (hint != null) return _LabelOutputPreviewHint(hint);
    final value = workbook;
    if (value == null) {
      return const _LabelOutputPreviewHint('현재 공용라벨 시트가 없습니다.');
    }
    final messages = labelOutputPreviewMessages(value);
    return Column(
      children: [
        if (messages.isNotEmpty)
          _LabelOutputPreviewMessages(messages: messages),
        Expanded(
          child: LabelSheetWorkbench(
            key: ValueKey(identityKey),
            initialWorkbook: value,
            labelSize: labelSize,
            imageObjectIds: imageObjectIds,
            barcodeObjectIds: barcodeObjectIds,
            outputCaptureController: outputCaptureController,
            hideToolbar: true,
            hideRowColumnHeaderLabels: true,
            hideSelectionHighlight: true,
            rulerCornerSizeLabelUsesAsterisk: true,
            disableSheetRulerGuideInteraction: true,
            hideStatisticBar: true,
            copyOnlyContextMenu: true,
            zoomToolbarPlacement: zoomToolbarPlacement,
            zoomToolbarAnchorLink: zoomToolbarAnchorLink,
          ),
        ),
      ],
    );
  }
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