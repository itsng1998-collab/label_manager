import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart'
  show
    FortuneObjectConnectionOption,
    FortuneWorkbook,
    fortuneBarcodeObjectIdExtraKey,
    fortuneImageObjectIdExtraKey;

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/features/label_sheet/domain/label_sheet_required_keyword.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/widgets/snackbar.dart';

@visibleForTesting
List<String> labelSheetMissingRequiredKeywordNames(
  String encodedWorkbook,
  List<LabelSheetRequiredKeyword> requiredKeywords,
) {
  final workbook = labelSheetTryDecodeWorkbookSave(encodedWorkbook);
  if (workbook == null) {
    return [for (final item in requiredKeywords) item.itemName];
  }
  return labelSheetMissingRequiredKeywordNamesInWorkbook(
    workbook,
    requiredKeywords,
  );
}

@visibleForTesting
List<String> labelSheetMissingRequiredKeywordNamesInWorkbook(
  FortuneWorkbook workbook,
  List<LabelSheetRequiredKeyword> requiredKeywords,
) {
  if (requiredKeywords.isEmpty) {
    return const <String>[];
  }

  final textBuffer = StringBuffer();
  final objectIds = <String>{};
  for (final sheet in workbook.sheets) {
    for (final cell in sheet.cells.values) {
      textBuffer
        ..write(cell.renderedText)
        ..write('\n');
      final formula = cell.formula;
      if (formula != null && formula.isNotEmpty) {
        textBuffer
          ..write(formula)
          ..write('\n');
      }
    }
    for (final image in sheet.images) {
      _addLabelSheetRequiredKeywordObjectId(objectIds, image.id);
      _addLabelSheetRequiredKeywordObjectId(
        objectIds,
        image.extraFields[fortuneImageObjectIdExtraKey],
      );
      _addLabelSheetRequiredKeywordObjectId(
        objectIds,
        image.extraFields[fortuneBarcodeObjectIdExtraKey],
      );
    }
  }

  final text = textBuffer.toString().toLowerCase();
  final missing = <String>[];
  final seenMissing = <String>{};
  for (final item in requiredKeywords) {
    final required = item.normalizedKeyword.trim();
    if (required.isEmpty || required == '#') {
      continue;
    }
    final key = required.toLowerCase();
    if (text.contains(key) || objectIds.contains(key)) {
      continue;
    }
    final itemName = item.itemName.trim().isEmpty ? item.keyword : item.itemName;
    if (seenMissing.add(itemName.toLowerCase())) {
      missing.add(itemName);
    }
  }
  return missing;
}

void _addLabelSheetRequiredKeywordObjectId(Set<String> objectIds, Object? value) {
  if (value == null) {
    return;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return;
  }
  objectIds.add(text.toLowerCase());
  objectIds.add((text.startsWith('#') ? text : '#$text').toLowerCase());
}

class LabelSheetPage extends StatelessWidget {
  const LabelSheetPage({
    super.key,
    this.labelSize,
    this.imageObjectIds = const <String>[],
    this.barcodeObjectIds = const <String>[],
    this.imageObjectOptions = const <FortuneObjectConnectionOption>[],
    this.barcodeObjectOptions = const <FortuneObjectConnectionOption>[],
    this.requiredKeywords = const <LabelSheetRequiredKeyword>[],
    this.onSheetReady,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
    this.imageImportController,
    this.editingLifecycleController,
    this.onDirtyChanged,
    this.onSaved,
  });

  final LabelSize? labelSize;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final List<FortuneObjectConnectionOption> imageObjectOptions;
  final List<FortuneObjectConnectionOption> barcodeObjectOptions;
  final List<LabelSheetRequiredKeyword> requiredKeywords;
  final VoidCallback? onSheetReady;
  final ValueChanged<Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;
  final LabelSheetImageImportController? imageImportController;
  final LabelSheetEditingLifecycleController? editingLifecycleController;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<LabelSize>? onSaved;

  @override
  Widget build(BuildContext context) {
    final size = labelSize?.labelSizeCommon;
    debugLog(
      'native FortuneSheet width=${size?.width}, height=${size?.height}',
    );
    final formData = size?.rtf;
    final isRtf = labelSheetLooksLikeRichEditRtf(formData);
    final savedWorkbook = isRtf
        ? null
        : labelSheetTryDecodeWorkbookSave(formData);
    final rtf = isRtf ? formData : null;
    final id = labelSize?.labelSizeId;
    final width = labelSize?.labelSizeCommon?.width;
    final height = labelSize?.labelSizeCommon?.height;
    return withoutLabelManagerCompactUi(
      context,
      LabelSheetWorkbench(
        key: ValueKey(
          '$id:${width ?? 100}:${height ?? 100}:${rtf?.length ?? 0}:${rtf.hashCode}',
        ),
        initialWorkbook: savedWorkbook,
        labelSize: labelSize,
        labelRtf: rtf,
        imageObjectIds: imageObjectIds,
        barcodeObjectIds: barcodeObjectIds,
        imageObjectOptions: imageObjectOptions,
        barcodeObjectOptions: barcodeObjectOptions,
        onInitialLoadComplete: onSheetReady,
        onGridRectChanged: onGridRectChanged,
        onBeforeSheetDialog: onBeforeSheetDialog,
        onSheetDialogClosed: onSheetDialogClosed,
        imageImportController: imageImportController,
        editingLifecycleController: editingLifecycleController,
        onDirtyChanged: onDirtyChanged,
        hideStatisticBar: true,
        onSave: (width, height, encodedWorkbook) =>
          _handleSaveLabelSheet(context, width, height, encodedWorkbook),
      ),
    );
  }

  Future<LabelSheetSaveResult> _handleSaveLabelSheet(
    BuildContext context,
    int width,
    int height,
    String encodedWorkbook,
  ) async {
    debugLog(START);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text('라벨을 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      debugLog('saveLabelSheet cancelledByUser labelSizeId=${labelSize?.labelSizeId} keepEditing');
      return LabelSheetSaveResult.notApplied;
    }

    final missingRequiredNames = labelSheetMissingRequiredKeywordNames(
      encodedWorkbook,
      requiredKeywords,
    );
    if (missingRequiredNames.isNotEmpty) {
      debugLog(
        'saveLabelSheet missingRequiredKeywords=${missingRequiredNames.join(',')}',
      );
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
          builder: (dialogContext) => AlertDialog(
            content: Text("'${missingRequiredNames.join(',')}'이 누락되었습니다!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      return LabelSheetSaveResult.notApplied;
    }

    if (!context.mounted) return LabelSheetSaveResult.notApplied;
    showSnackBar(
      context,
      '라벨을 저장 중입니다...',
      type: SnackBarType.inProgress,
      duration: const Duration(days: 1),
    );

    try {
      if (labelSize == null) {
        debugLog('$END - labelSize is null, skipping save');
        return LabelSheetSaveResult.notApplied;
      }

      final id = labelSize!.labelSizeId;
      debugLog('saving workbook for labelSizeId=$id, width=$width, height=$height');
      await LabelSizeDAO.updateByLabelSizeId(id, width, height, encodedWorkbook);
      final updated = LabelSize.replaceCachedFormData(
        id,
        width,
        height,
        encodedWorkbook,
      ) ?? labelSize!.copyWith(
        labelSizeCommon: LabelSizeCommon(
          width: width,
          height: height,
          rtf: encodedWorkbook,
        ),
      );
      onSaved?.call(updated);
      debugLog('$END - save completed');
      return LabelSheetSaveResult.applied;
    }
    catch (e) {
      debugLog('$END - save failed, error=$e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await showDialog<void>(
          context: context,
          traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
          builder: (dialogContext) => AlertDialog(
            title: const Text('라벨 저장 실패'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      rethrow;
    }
    finally {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }
}
