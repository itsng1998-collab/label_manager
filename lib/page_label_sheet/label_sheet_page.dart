import 'dart:async';

import 'package:flutter/material.dart';

import 'package:label_manager/core/app.dart';
import 'package:label_manager/core/ui_scale.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/utils/on_messages.dart';

class LabelSheetPage extends StatelessWidget {
  const LabelSheetPage({
    super.key,
    this.labelSize,
    this.barcodeObjectIds = const <String>[],
    this.onSheetReady,
    this.onGridRectChanged,
    this.onBeforeSheetDialog,
    this.onSheetDialogClosed,
  });

  final LabelSize? labelSize;
  final List<String> barcodeObjectIds;
  final VoidCallback? onSheetReady;
  final ValueChanged<Rect>? onGridRectChanged;
  final FutureOr<void> Function()? onBeforeSheetDialog;
  final VoidCallback? onSheetDialogClosed;

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
        barcodeObjectIds: barcodeObjectIds,
        onInitialLoadComplete: onSheetReady,
        onGridRectChanged: onGridRectChanged,
        onBeforeSheetDialog: onBeforeSheetDialog,
        onSheetDialogClosed: onSheetDialogClosed,
        onSave: (width, height, encodedWorkbook) =>
          _handleSaveLabelSheet(context, width, height, encodedWorkbook),
      ),
    );
  }

  Future<void> _handleSaveLabelSheet(
    BuildContext context,
    int width,
    int height,
    String encodedWorkbook,
  ) async {
    debugLog(START);

    showSnackBar(
      context,
      '라벨을 저장 중입니다...',
      type: SnackBarType.inProgress,
      duration: const Duration(days: 1),
    );

    try {
      if (labelSize == null) {
        debugLog('$END - labelSize is null, skipping save');
        return;
      }

      final id = labelSize!.labelSizeId;
      debugLog('saving workbook for labelSizeId=$id, width=$width, height=$height');
      await LabelSizeDAO.setByLabelSizeId(id, width, height, encodedWorkbook);
      LabelSize.replaceCachedFormData(id, width, height, encodedWorkbook);
      debugLog('$END - save completed');
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
