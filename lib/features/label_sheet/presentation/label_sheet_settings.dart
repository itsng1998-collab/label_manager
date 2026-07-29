import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

const String labelSheetSaveToolbarCommand = 'label-sheet-save';
const String labelSheetPrintToolbarCommand = 'label-sheet-print';

const List<String> labelSheetToolbarItems = [
  labelSheetSaveToolbarCommand,
  labelSheetPrintToolbarCommand,
  '|',
  fortuneToolbarFontPopupKey,
  '|',
  fortuneToolbarFontSizePopupKey,
  '|',
  fortuneToolbarBoldCommand,
  fortuneToolbarItalicCommand,
  fortuneToolbarStrikeThroughCommand,
  fortuneToolbarUnderlineCommand,
  '|',
  fortuneToolbarFontColorPopupKey,
  fortuneToolbarBackgroundPopupKey,
  fortuneToolbarBorderPopupKey,
  fortuneToolbarMergePopupKey,
  '|',
  fortuneToolbarHorizontalAlignPopupKey,
  fortuneToolbarVerticalAlignPopupKey,
  fortuneToolbarTextWrapPopupKey,
  fortuneToolbarTextRotationPopupKey,
  '|',
  fortuneToolbarImageCommand,
  fortuneToolbarBarcodeCommand,
  fortuneToolbarLineCommand,
  fortuneToolbarShapeCommand,
  fortuneToolbarObjectPanelCommand,
];

const Set<String> labelSheetHiddenContextMenuItems = {
  fortuneContextSortCommand,
  fortuneContextOrderAzCommand,
  fortuneContextOrderZaCommand,
  fortuneToolbarFilterCommand,
  fortuneToolbarLinkCommand,
  fortuneFilterSortAscCommand,
  fortuneFilterSortDescCommand,
};

const List<String> labelSheetClipboardClearContextMenuItems = [
  fortuneContextCopyCommand,
  fortuneContextPasteCommand,
  fortuneContextClearCommand,
];

List<String> labelSheetContextMenuItems(
  List<String> base, {
  bool includeImportLabelImage = false,
}) {
  var visible = fortuneMenuItemsWithout(base, labelSheetHiddenContextMenuItems);
  if (includeImportLabelImage &&
      !visible.contains(fortuneContextImportLabelImageCommand)) {
    final loadCommonLabelIndex = visible.indexOf(
      fortuneContextLoadCommonLabelCommand,
    );
    final insertIndex = loadCommonLabelIndex < 0
        ? visible.length
        : loadCommonLabelIndex + 1;
    visible = [
      ...visible.take(insertIndex),
      fortuneContextImportLabelImageCommand,
      ...visible.skip(insertIndex),
    ];
  }
  if (visible.contains(fortuneToolbarBarcodeCommand)) {
    return visible;
  }
  final imageIndex = visible.indexOf(fortuneToolbarImageCommand);
  if (imageIndex < 0) {
    return visible;
  }
  return [
    ...visible.take(imageIndex + 1),
    fortuneToolbarBarcodeCommand,
    ...visible.skip(imageIndex + 1),
  ];
}

FortuneSettings labelSheetSettings(
  FortuneSettings base, {
  VoidCallback? onImportLabelImage,
  FutureOr<void> Function()? onSave,
  FutureOr<void> Function()? onImportLabelFile,
  FutureOr<void> Function()? onExportLabelFile,
  Set<String> Function()? contextMenuDisabledItemsBuilder,
  VoidCallback? onPrint,
  FortuneDialogVisibilityChanged? onDialogVisibilityChanged,
  bool saveEnabled = true,
  String importImageTooltip = 'Import label image',
  String saveTooltip = 'Save',
  String printTooltip = 'Print',
  List<String>? toolbarItems,
  bool hideToolbar = false,
  bool hideRowColumnHeaders = false,
  bool hideRowColumnHeaderLabels = false,
  bool hideSelectionHighlight = false,
  bool singleClickCellEdit = false,
  bool hidePrintAreaBoundary = false,
  bool fitSingleCellToViewport = false,
  bool rulerCornerSizeLabelUsesAsterisk = false,
  bool disableSheetRulerGuideInteraction = false,
  bool hideStatisticBar = false,
  bool copyOnlyContextMenu = false,
  bool limitCellActionsToClipboardAndClear = false,
  bool? canEditObjects,
}) {
  final resolvedToolbarItems = toolbarItems ?? labelSheetToolbarItems;
  return base.copyWith(
    allowEdit: canEditObjects,
    showToolbar: !hideToolbar,
    copyOnlyContextMenu: copyOnlyContextMenu,
    limitCellActionsToClipboardAndClear: limitCellActionsToClipboardAndClear,
    toolbarItems: resolvedToolbarItems,
    rowHeaderWidth: hideRowColumnHeaders ? 0 : null,
    columnHeaderHeight: hideRowColumnHeaders ? 0 : null,
    hideRowColumnHeaderLabels: hideRowColumnHeaderLabels,
    hideSelectionHighlight: hideSelectionHighlight,
    singleClickCellEdit: singleClickCellEdit,
    hidePrintAreaBoundary: hidePrintAreaBoundary,
    fitSingleCellToViewport: fitSingleCellToViewport,
    rulerCornerSizeLabelUsesAsterisk: rulerCornerSizeLabelUsesAsterisk,
    disableSheetRulerGuideInteraction: disableSheetRulerGuideInteraction,
    statisticBarHeight: hideStatisticBar ? 0 : null,
    customToolbarItems: [
      if (resolvedToolbarItems.contains(labelSheetSaveToolbarCommand))
        FortuneCustomToolbarItem(
          key: labelSheetSaveToolbarCommand,
          tooltip: saveTooltip,
          iconName: 'save',
          disabled: !saveEnabled,
          onClick: (_) {
            final callback = onSave;
            if (callback == null) {
              fortuneSheetDebugLog('label sheet save toolbar click');
              return;
            }
            unawaited(Future<void>.sync(callback));
          },
        ),
      if (resolvedToolbarItems.contains(labelSheetPrintToolbarCommand))
        FortuneCustomToolbarItem(
          key: labelSheetPrintToolbarCommand,
          tooltip: printTooltip,
          iconName: 'print',
          onClick: (_) {
            final callback = onPrint;
            if (callback == null) {
              fortuneSheetDebugLog('label sheet print toolbar click');
              return;
            }
            callback();
          },
        ),
    ],
    cellContextMenu: copyOnlyContextMenu
        ? const [fortuneContextCopyCommand]
        : limitCellActionsToClipboardAndClear
        ? labelSheetClipboardClearContextMenuItems
        : labelSheetContextMenuItems(base.cellContextMenu),
    headerContextMenu: copyOnlyContextMenu
        ? const [fortuneContextCopyCommand]
        : limitCellActionsToClipboardAndClear
        ? labelSheetClipboardClearContextMenuItems
        : labelSheetContextMenuItems(
            base.headerContextMenu,
            includeImportLabelImage: true,
          ),
    sheetTabContextMenu: labelSheetContextMenuItems(base.sheetTabContextMenu),
    filterContextMenu: labelSheetContextMenuItems(base.filterContextMenu),
    onDialogVisibilityChanged: onDialogVisibilityChanged,
    onContextMenuCommand: (command) {
      if (command == fortuneContextImportLabelImageCommand) {
        final callback = onImportLabelImage;
        if (callback == null) {
          fortuneSheetDebugLog('label sheet import image context click');
          return null;
        }
        callback();
        return null;
      }
      if (command == fortuneContextImportLabelFileCommand) {
        final callback = onImportLabelFile;
        if (callback == null) {
          fortuneSheetDebugLog('label sheet import label file context click');
          return null;
        }
        return callback();
      }
      if (command != fortuneContextExportLabelFileCommand) {
        return null;
      }
      final callback = onExportLabelFile;
      if (callback == null) {
        fortuneSheetDebugLog('label sheet export label file context click');
        return null;
      }
      return callback();
    },
    contextMenuDisabledItemsBuilder: contextMenuDisabledItemsBuilder,
  );
}
