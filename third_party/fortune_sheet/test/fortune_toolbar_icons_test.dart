import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart';
import 'package:fortune_sheet/src/fortune_sheet_painter.dart';
import 'package:fortune_sheet/src/fortune_toolbar_icons.dart';

void main() {
  test('all default toolbar item ids have a canvas icon implementation', () {
    final missing = fortuneToolbarItems
        .where((item) => item != '|')
        .where(
          (item) => !FortuneToolbarIconPainter.supportedIconIds.contains(item),
        )
        .toList();

    expect(missing, isEmpty);
  });

  test('filter popup command ids have a canvas icon implementation', () {
    final missing = fortuneToolbarFilterPopupCommands
        .where((item) => item != '|')
        .where(
          (item) => !FortuneToolbarIconPainter.supportedIconIds.contains(item),
        )
        .toList();

    expect(missing, isEmpty);
  });

  test('icon-backed toolbar popup command ids have canvas implementations', () {
    final iconBackedPopupCommands = <String>{
      ...fortuneToolbarMergeCommands,
      ...fortuneToolbarHorizontalAlignCommands,
      ...fortuneToolbarVerticalAlignCommands,
      ...fortuneToolbarTextWrapCommands,
      ...fortuneToolbarTextRotationCommands,
      ...fortuneToolbarFilterPopupCommands.where((item) => item != '|'),
      ...fortuneFreezeMenuItems,
    };

    final missing = iconBackedPopupCommands
        .where(
          (item) => !FortuneToolbarIconPainter.supportedIconIds.contains(item),
        )
        .toList();

    expect(missing, isEmpty);
  });

  test('combo toolbar icon ids are backed by supported icons', () {
    final missing = FortuneToolbarIconPainter.comboIconIds
        .where(
          (item) => !FortuneToolbarIconPainter.supportedIconIds.contains(item),
        )
        .toList();

    expect(missing, isEmpty);
  });

  test(
    'currency toolbar icon mirrors upstream currency glyph choices',
    () async {
      final signatures = <String, int>{};
      for (final currency in [r'$', '€', '£', '₹', '¥']) {
        signatures[currency] = await _currencyIconSignature(currency: currency);
      }

      expect(signatures.values.toSet(), hasLength(5));
      expect(await _currencyIconSignature(currency: '₩'), signatures['¥']);
    },
  );

  test('toolbar painter passes workbook currency to currency icon', () async {
    final dollarSignature = await _toolbarCurrencySignature(currency: r'$');
    final yenSignature = await _toolbarCurrencySignature(currency: '¥');
    final fallbackSignature = await _toolbarCurrencySignature(currency: '₩');

    expect(dollarSignature, isNot(yenSignature));
    expect(fallbackSignature, yenSignature);
  });

  test('upstream kebab-case toolbar icon aliases are supported', () {
    const aliases = {
      'condition-format': 'conditionFormat',
      'data-verification': 'dataVerification',
      'location-condition': 'locationCondition',
    };

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final iconRect = ui.Rect.fromLTWH(0, 0, 24, 24);

    for (final entry in aliases.entries) {
      expect(
        FortuneToolbarIconPainter.supportedIconIds.contains(entry.key),
        isTrue,
        reason: entry.key,
      );
      expect(
        FortuneToolbarIconPainter.supportedIconIds.contains(entry.value),
        isTrue,
        reason: entry.value,
      );
      expect(
        () => FortuneToolbarIconPainter.draw(canvas, entry.key, iconRect),
        returnsNormally,
        reason: entry.key,
      );
    }

    recorder.endRecording().dispose();
  });

  test('conditional format icon matches upstream gray grid palette', () async {
    final colors = await _toolbarIconColors('conditionFormat');

    expect(colors, contains(0xff535a68));
    expect(colors, contains(0xffa6aab2));
    expect(colors, contains(0xffd0d2d7));
    expect(colors, contains(0xfffafafc));
    expect(colors, isNot(contains(0xffd93025)));
    expect(colors, isNot(contains(0xffffc000)));
    expect(colors, isNot(contains(0xff188038)));
  });

  test('conditional format icon y position aligns with freeze icon', () async {
    final freezeBounds = await _toolbarIconBounds('freeze');
    final conditionBounds = await _toolbarIconBounds('conditionFormat');

    expect(conditionBounds.center.dy, closeTo(freezeBounds.center.dy, 0.75));
  });

  test('import image icon matches flutter vector glyph', () async {
    final colors = await _toolbarIconColors('import-image');
    final bounds = await _toolbarIconBounds('import-image');

    expect(colors, contains(0xff525c6f));
    expect(colors, isNot(contains(0xff000000)));
    expect(bounds.left, greaterThanOrEqualTo(3));
    expect(bounds.top, greaterThanOrEqualTo(3));
    expect(bounds.right, lessThanOrEqualTo(21));
    expect(bounds.bottom, lessThanOrEqualTo(21));
  });

  test('save icon matches compact pasted glyph size', () async {
    final colors = await _toolbarIconColors('save');
    final bounds = await _toolbarIconBounds('save');
    final importBounds = await _toolbarIconBounds('import-image');
    final printBounds = await _toolbarIconBounds('print');

    expect(colors, contains(0xff000000));
    expect(colors, isNot(contains(0xff525c6f)));
    expect(bounds.left, greaterThanOrEqualTo(3));
    expect(bounds.top, greaterThanOrEqualTo(3));
    expect(bounds.right, lessThanOrEqualTo(21));
    expect(bounds.bottom, lessThanOrEqualTo(21));
    expect(bounds.width, closeTo(importBounds.width - 1, 1));
    expect(bounds.height, closeTo(printBounds.height, 2));
  });

  test('toolbar popup item ids have labels', () {
    final missing = fortuneToolbarPopupItems.values
        .expand((items) => items)
        .where((item) => item != '|')
        .where((item) => !fortuneToolbarPopupLabels.containsKey(item))
        .toList();

    expect(missing, isEmpty);
  });

  test('dynamic comment popup item ids have labels', () {
    final commentPopupItems = {
      ...fortuneToolbarCommentEmptyPopupCommands,
      ...fortuneToolbarCommentExistingPopupCommands,
    };
    final missing = commentPopupItems
        .where((item) => !fortuneToolbarPopupLabels.containsKey(item))
        .toList();

    expect(commentPopupItems, hasLength(5));
    expect(missing, isEmpty);
  });

  test('freeze toolbar menu item ids have labels', () {
    final missing = fortuneFreezeMenuItems
        .where((item) => !fortuneFreezeMenuLabels.containsKey(item))
        .toList();

    expect(missing, isEmpty);
  });

  test('freeze toolbar menu labels mirror upstream current freeze options', () {
    expect(fortuneFreezeMenuLabels, {
      fortuneFreezeRowCommand: 'Freeze to current row',
      fortuneFreezeColumnCommand: 'Freeze to current column',
      fortuneFreezeRowColumnCommand: 'Freeze to current cell',
      fortuneFreezeCancelCommand: 'Cancel freezing',
    });
    const locale = FortuneSheetLocale();
    expect(locale.freezeDefault, 'Freeze');
    expect(locale.freezeFirstRow, 'First Row');
    expect(locale.freezeFirstColumn, 'First Column');
    expect(locale.freezeBoth, 'Both');
    expect(locale.freezeRowRange, 'Freeze to current row');
    expect(locale.freezeColumnRange, 'Freeze to current column');
    expect(locale.freezeRowColumnRange, 'Freeze to current cell');
    expect(locale.freezeCancel, 'Cancel freezing');
    expect(locale.freezeNoSelectionError, 'No Range to be selected');
    expect(locale.freezeRangeOverErrorTitle, 'Freeze reminder');
    expect(
      locale.freezeRangeOverError,
      'The frozen pane is beyond the visible range, which will lead to abnormal operation. Please reset the frozen area.',
    );
  });

  test('merge toolbar menu labels mirror upstream merge labels', () {
    const locale = FortuneSheetLocale();

    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarMergeAllCommand, 'Merge all'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarMergeVerticalCommand, 'Merge Vertically'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarMergeHorizontalCommand, 'Merge Horizontally'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarMergeCancelCommand, 'Unmerge'),
    );
    expect(locale.mergeAll, 'Merge all');
    expect(locale.mergeVertical, 'Merge Vertically');
    expect(locale.mergeHorizontal, 'Merge Horizontally');
    expect(locale.mergeCancel, 'Unmerge');
    expect(locale.mergeOverlappingError, 'Cannot merge overlapping areas');
    expect(
      locale.mergePartiallyError,
      'Cannot perform this operation on partially merged cells',
    );
  });

  test('border toolbar menu labels mirror upstream border labels', () {
    const locale = FortuneSheetLocale();

    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderTopCommand, 'Top border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderBottomCommand, 'Bottom border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderLeftCommand, 'Left border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderRightCommand, 'Right border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderNoneCommand, 'No border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderAllCommand, 'All borders'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderOutsideCommand, 'Outside border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderInsideCommand, 'Inside border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderHorizontalCommand, 'Horizontal borders'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderVerticalCommand, 'Vertical borders'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderSlashCommand, 'Slash border'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderColorSubmenuKey, 'border color'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarBorderStyleSubmenuKey, 'border style'),
    );
    expect(locale.borderLabels, {
      'borderTop': 'Top border',
      'borderBottom': 'Bottom border',
      'borderLeft': 'Left border',
      'borderRight': 'Right border',
      'borderNone': 'No border',
      'borderAll': 'All borders',
      'borderOutside': 'Outside border',
      'borderInside': 'Inside border',
      'borderHorizontal': 'Horizontal borders',
      'borderVertical': 'Vertical borders',
      'borderColor': 'border color',
      'borderSize': 'border size',
      'borderSlash': 'Slash border',
      'borderDefault': 'default',
      'borderStyle': 'border style',
    });
  });

  test('alignment wrap and rotation toolbar labels mirror upstream labels', () {
    const locale = FortuneSheetLocale();

    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarAlignLeftCommand, 'left'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarAlignCenterCommand, 'center'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarAlignRightCommand, 'right'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarVerticalAlignTopCommand, 'Top'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarVerticalAlignMiddleCommand, 'Middle'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarVerticalAlignBottomCommand, 'Bottom'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarWrapOverflowCommand, 'Overflow'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarWrapWrapCommand, 'Wrap'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarWrapClipCommand, 'Clip'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateNoneCommand, 'None'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateUpCommand, 'Tilt Up'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateDownCommand, 'Tilt Down'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateVerticalCommand, 'Stack Vertically'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateUp90Command, 'Rotate Up'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarRotateDown90Command, 'Rotate Down'),
    );
    expect(locale.alignLabels, {
      'left': 'left',
      'center': 'center',
      'right': 'right',
      'top': 'Top',
      'middle': 'Middle',
      'bottom': 'Bottom',
    });
    expect(locale.textWrapLabels, {
      'overflow': 'Overflow',
      'wrap': 'Wrap',
      'clip': 'Clip',
    });
    expect(locale.rotationLabels, {
      'none': 'None',
      'angleup': 'Tilt Up',
      'angledown': 'Tilt Down',
      'vertical': 'Stack Vertically',
      'rotationUp': 'Rotate Up',
      'rotationDown': 'Rotate Down',
    });
  });

  test('default locale covers sheet and context menu item labels', () {
    const locale = FortuneSheetLocale();
    final missingSheetTabLabels = fortuneSheetTabMenuItems
        .where((item) => item != '|')
        .where((item) => !locale.sheetTabMenuLabels.containsKey(item))
        .toList();
    final missingContextLabels = fortuneContextMenuItems
        .where((item) => item != '|')
        .where((item) => !locale.contextMenuLabels.containsKey(item))
        .toList();
    final missingHeaderContextLabels = fortuneHeaderContextMenuItems
        .where((item) => item != '|')
        .where((item) => !locale.contextMenuLabels.containsKey(item))
        .toList();

    expect(missingSheetTabLabels, isEmpty);
    expect(
      locale.sheetTabMenuLabels[fortuneSheetTabColorCommand],
      'Change color',
    );
    expect(locale.customColorReset, 'Reset color');
    expect(locale.customColorConfirm, 'OK');
    expect(missingContextLabels, isEmpty);
    expect(
      locale.contextMenuLabels[fortuneContextDeleteRowCommand],
      'Delete selected Row',
    );
    expect(
      locale.contextMenuLabels[fortuneContextDeleteColumnCommand],
      'Delete selected Column',
    );
    expect(
      locale.contextMenuLabels[fortuneContextChartCommand],
      'Create chart',
    );
    expect(missingHeaderContextLabels, isEmpty);
  });

  test('default locale sheet and context menu labels mirror upstream text', () {
    const locale = FortuneSheetLocale();

    expect(locale.sheetTabMenuLabels, {
      'delete': 'Delete',
      'copy': 'Copy',
      'rename': 'Rename',
      'color': 'Change color',
      'hide': 'Hide',
      'move': 'Move',
      'move-left': 'Move left',
      'move-right': 'Move right',
      'show-hidden': 'Unhide',
      'focus': 'Focus',
    });
    expect(locale.contextMenuLabels, {
      'copy': 'Copy',
      'paste': 'Paste',
      'insert-row': 'Insert row above',
      'insert-row-below': 'Insert row below',
      'insert-column': 'Insert column left',
      'insert-column-right': 'Insert column right',
      'insert-inline-prefix': 'Insert',
      'insert-row-inline-suffix': 'Row Above',
      'insert-row-below-inline-suffix': 'Row Below',
      'insert-column-inline-suffix': 'Column Left',
      'insert-column-right-inline-suffix': 'Column Right',
      'show-grid-lines': 'Show grid lines',
      'show-ruler': 'Show ruler',
      'delete-row': 'Delete selected Row',
      'delete-column': 'Delete selected Column',
      'delete-cell': 'Delete cell',
      'hide-row': 'Hide selected Row',
      'show-hidden-row': 'Show hidden Row',
      'hide-column': 'Hide selected Column',
      'show-hidden-column': 'Show hidden Column',
      'set-row-height': 'Row height',
      'set-column-width': 'Column width',
      'set-label-width': 'Label width',
      'set-label-height': 'Label height',
      'row-height-inline-label': 'RowHeight',
      'column-width-inline-label': 'ColumnWidth',
      'label-width-inline-label': 'Label width',
      'label-height-inline-label': 'Label height',
      'context-menu-pixel-unit': 'px',
      'context-menu-millimeter-unit': 'mm',
      'clear': 'Clear content',
      'clear-sheet': 'Clear sheet',
      'sort': 'Sort',
      'orderAZ': 'Ascending sort',
      'orderZA': 'Descending sort',
      'filter': 'Filter',
      'chart': 'Create chart',
      'image': 'Insert image',
      'barcode': 'Insert barcode',
      'insert-auto-ingredient-table': 'Insert auto ingredient table',
      'load-common-label': 'Load common label',
      'link': 'Insert link',
      'data': 'Data verification',
      'cell-format': 'Format cells',
      'editor-superscript': 'Superscript',
      'editor-subscript': 'Subscript',
      'editor-clear-script': 'Clear script',
      'editor-letter-spacing': 'Letter spacing',
      'editor-font-scale': 'Character scale',
      'editor-line-height': 'Line spacing',
      'editor-letter-spacing-unit': 'pt',
      'editor-font-scale-unit': '%',
      'editor-line-height-unit': 'x',
      'editor-letter-spacing-hint': 'Ex: 1.0',
      'editor-font-scale-hint': 'Ex: 90',
      'editor-line-height-hint': 'Ex: 1.2',
    });
  });

  test('korean locale localizes context menu labels', () {
    const defaultLocale = FortuneSheetLocale();
    final locale = FortuneSheetLocale.forLocale(const Locale('ko', 'KR'));
    final contextCommands = {
      ...fortuneContextMenuItems.where((item) => item != '|'),
      ...fortuneHeaderContextMenuItems.where((item) => item != '|'),
      ...fortuneEditorContextMenuItems.where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneContextMenuItems,
      ).where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneHeaderContextMenuItems,
      ).where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneEditorContextMenuItems,
      ).where((item) => item != '|'),
    };

    final missingLabels = contextCommands
        .where((item) => !locale.contextMenuLabels.containsKey(item))
        .toList();
    expect(missingLabels, isEmpty);

    expect(locale.contextMenuLabels[fortuneContextCopyCommand], '복사');
    expect(locale.contextMenuLabels[fortuneContextInsertRowCommand], '위에 행 삽입');
    expect(
      locale.contextMenuLabels[fortuneContextInsertRowBelowCommand],
      '아래에 행 삽입',
    );
    expect(
      locale.contextMenuLabels[fortuneContextInsertColumnRightCommand],
      '오른쪽에 열 삽입',
    );
    expect(
      locale.contextMenuLabels[fortuneEditorContextSuperscriptCommand],
      '위 첨자',
    );
    expect(
      locale.contextMenuLabels[fortuneEditorContextClearScriptCommand],
      '첨자 해제',
    );
    expect(
      locale.contextMenuLabels[fortuneEditorContextLetterSpacingCommand],
      '자간',
    );
    expect(locale.contextMenuLabels['editor-line-height-hint'], '예: 1.2');
    expect(locale.contextMenuLabels[fortuneToolbarFilterCommand], '필터');
    expect(locale.contextMenuLabels[fortuneToolbarImageCommand], '이미지 삽입');
    expect(
      locale.contextMenuLabels[fortuneContextInsertAutoIngredientTableCommand],
      '자동 성분표 삽입',
    );
    expect(
      locale.contextMenuLabels[fortuneContextLoadCommonLabelCommand],
      '공용 라벨 불러오기',
    );
    expect(locale.contextMenuLabels[fortuneToolbarLinkCommand], '링크 삽입');
    expect(locale.contextMenuLabels['insert-inline-prefix'], '삽입');
    expect(locale.contextMenuLabels['insert-row-inline-suffix'], '위에 행');
    expect(locale.contextMenuLabels['column-width-inline-label'], '열 넓이');
    expect(locale.contextMenuLabels['row-height-inline-label'], '행 높이');
    expect(locale.contextMenuLabels['label-width-inline-label'], '라넬 넓이');
    expect(locale.contextMenuLabels['label-height-inline-label'], '라벨 높이');
    expect(locale.contextMenuLabels[fortuneContextClearSheetCommand], '시트 지우기');

    final untranslatedLabels = contextCommands
        .where(
          (item) =>
              defaultLocale.contextMenuLabels[item] != null &&
              locale.contextMenuLabels[item] ==
                  defaultLocale.contextMenuLabels[item],
        )
        .toList();
    expect(untranslatedLabels, isEmpty);
  });

  test('default locale menu label keys reference known menu commands', () {
    const locale = FortuneSheetLocale();
    final sheetTabCommands = {
      ...fortuneSheetTabMenuItems.where((item) => item != '|'),
      fortuneSheetTabMoveLeftCommand,
      fortuneSheetTabMoveRightCommand,
      fortuneSheetTabShowHiddenCommand,
      fortuneSheetTabFocusCommand,
    };
    final contextCommands = {
      ...fortuneContextMenuItems.where((item) => item != '|'),
      ...fortuneHeaderContextMenuItems.where((item) => item != '|'),
      ...fortuneEditorContextMenuItems.where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneContextMenuItems,
      ).where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneHeaderContextMenuItems,
      ).where((item) => item != '|'),
      ...fortuneContextRenderableMenuItems(
        fortuneEditorContextMenuItems,
      ).where((item) => item != '|'),
      fortuneContextInsertRowBelowCommand,
      fortuneContextInsertColumnRightCommand,
      fortuneContextShowHiddenRowCommand,
      fortuneContextShowHiddenColumnCommand,
      fortuneEditorContextClearScriptCommand,
      fortuneContextChartCommand,
      fortuneContextDataCommand,
      fortuneContextCellFormatCommand,
      fortuneToolbarImageCommand,
      fortuneToolbarBarcodeCommand,
      'insert-inline-prefix',
      'insert-row-inline-suffix',
      'insert-row-below-inline-suffix',
      'insert-column-inline-suffix',
      'insert-column-right-inline-suffix',
      'row-height-inline-label',
      'column-width-inline-label',
      'label-width-inline-label',
      'label-height-inline-label',
      'context-menu-pixel-unit',
      'context-menu-millimeter-unit',
      'editor-letter-spacing-unit',
      'editor-font-scale-unit',
      'editor-line-height-unit',
      'editor-letter-spacing-hint',
      'editor-font-scale-hint',
      'editor-line-height-hint',
    };

    expect(locale.sheetTabMenuLabels.keys.toSet(), sheetTabCommands);
    final contextLabelCommands = locale.contextMenuLabels.keys.toSet();
    expect(contextLabelCommands.difference(contextCommands), isEmpty);
    expect(contextCommands.difference(contextLabelCommands), isEmpty);
  });

  test('toolbar and menu command ids are nonempty and unique', () {
    final commandLists = <String, List<String>>{
      'toolbar': fortuneToolbarItems,
      'sheet tab menu': fortuneSheetTabMenuItems,
      'cell context menu': fortuneContextMenuItems,
      'header context menu': fortuneHeaderContextMenuItems,
      'editor context menu': fortuneEditorContextMenuItems,
      'freeze menu': fortuneFreezeMenuItems,
      for (final entry in fortuneToolbarPopupItems.entries)
        'toolbar popup ${entry.key}': entry.value,
    };

    for (final entry in commandLists.entries) {
      final commands = entry.value.where((item) => item != '|').toList();
      final duplicateCommands = [
        for (final command in commands.toSet())
          if (commands.where((item) => item == command).length > 1) command,
      ];

      expect(
        commands.where((item) => item.trim().isEmpty),
        isEmpty,
        reason: entry.key,
      );
      expect(duplicateCommands, isEmpty, reason: entry.key);
    }
  });

  test('toolbar and menu separators are internal and isolated', () {
    final commandLists = <String, List<String>>{
      'toolbar': fortuneToolbarItems,
      'sheet tab menu': fortuneSheetTabMenuItems,
      'cell context menu': fortuneContextMenuItems,
      'header context menu': fortuneHeaderContextMenuItems,
      'editor context menu': fortuneEditorContextMenuItems,
      'freeze menu': fortuneFreezeMenuItems,
      'formula popup': fortuneToolbarFormulaPopupCommands,
      for (final entry in fortuneToolbarPopupItems.entries)
        'toolbar popup ${entry.key}': entry.value,
    };

    for (final entry in commandLists.entries) {
      final commands = entry.value;
      expect(commands, isNotEmpty, reason: entry.key);
      expect(commands.first, isNot('|'), reason: entry.key);
      expect(commands.last, isNot('|'), reason: entry.key);
      for (var index = 1; index < commands.length; index += 1) {
        expect(
          commands[index - 1] == '|' && commands[index] == '|',
          isFalse,
          reason: entry.key,
        );
      }
    }
  });

  test('toolbar command groups reference known toolbar commands', () {
    final toolbarCommands =
        fortuneToolbarItems.where((item) => item != '|').toSet()
          ..add(fortuneToolbarBarcodeCommand);
    final groupedToolbarCommands = <String, List<String>>{
      'edit': fortuneToolbarEditCommands,
      'style': fortuneToolbarStyleCommands,
      'immediate': fortuneToolbarImmediateCommands,
      'number format': fortuneToolbarNumberFormatCommands,
      'utility': fortuneToolbarUtilityCommands,
    };

    for (final entry in groupedToolbarCommands.entries) {
      final duplicateCommands = [
        for (final command in entry.value.toSet())
          if (entry.value.where((item) => item == command).length > 1) command,
      ];

      expect(entry.value, isNotEmpty, reason: entry.key);
      expect(entry.value, isNot(contains('|')), reason: entry.key);
      expect(duplicateCommands, isEmpty, reason: entry.key);
      expect(
        entry.value.toSet().difference(toolbarCommands),
        isEmpty,
        reason: entry.key,
      );
    }
    expect(
      fortuneToolbarFormulaPopupCommands.where((item) => item != '|'),
      containsAll(fortuneToolbarFormulaCommands),
    );
  });

  test('default toolbar and menu labels are nonempty', () {
    const locale = FortuneSheetLocale();
    final labelMaps = <String, Map<String, String>>{
      'toolbar tooltips': fortuneToolbarTooltipLabels,
      'toolbar popups': fortuneToolbarPopupLabels,
      'freeze menu': fortuneFreezeMenuLabels,
      'sheet tab menu': locale.sheetTabMenuLabels,
      'context menu': locale.contextMenuLabels,
      'locale toolbar tooltips': locale.toolbarTooltipLabels,
      'locale toolbar popups': locale.toolbarPopupLabels,
      'locale freeze menu': locale.freezeMenuLabels,
      'condition rule titles': locale.conditionRuleTitles,
      'condition rule descriptions': locale.conditionRuleDescriptions,
    };

    for (final mapEntry in labelMaps.entries) {
      final emptyLabels = mapEntry.value.entries
          .where((entry) => entry.value.trim().isEmpty)
          .map((entry) => entry.key)
          .toList();

      expect(emptyLabels, isEmpty, reason: mapEntry.key);
    }
  });

  test('korean locale localizes toolbar UI labels', () {
    final locale = FortuneSheetLocale.forLocale(const Locale('ko', 'KR'));

    expect(locale.toolbarTooltipLabels[fortuneToolbarFreezePopupKey], '고정');
    expect(locale.toolbarTooltipLabels[fortuneToolbarFontPopupKey], '글꼴');
    expect(
      locale.toolbarTooltipLabels[fortuneToolbarDataVerificationCommand],
      '데이터 유효성',
    );
    expect(
      locale.toolbarPopupLabels[fortuneToolbarCreateFilterCommand],
      '필터 만들기',
    );
    expect(
      locale.toolbarPopupLabels[fortuneToolbarCommentShowHideAllCommand],
      '모두 표시/숨기기',
    );
    expect(locale.toolbarPopupLabels[fortuneToolbarRotateUp90Command], '위로 회전');
    expect(locale.toolbarPopupLabels[fortuneToolbarLocationNullCommand], '빈 값');
    expect(
      locale.toolbarPopupLabels[fortuneConditionFormatHighlightRulesCommand],
      '셀 강조 규칙',
    );
    expect(
      locale.toolbarPopupLabels[fortuneToolbarBorderStyleDefaultCommand],
      '기본값',
    );
    expect(locale.toolbarPopupLabels['border-style-label-10'], '테두리 스타일 10');
    expect(locale.toolbarPopupLabels['custom-color-label'], '사용자:');
    expect(
      locale
          .toolbarPopupLabels['condition-submenu-value-$fortuneConditionFormatUniqueValuesCommand'],
      '고유 값',
    );
    expect(
      locale
          .toolbarPopupLabels['condition-submenu-value-$fortuneConditionFormatAboveAverageCommand'],
      '평균 초과',
    );

    final untranslatedTooltips = fortuneToolbarTooltipLabels.entries
        .where((entry) => locale.toolbarTooltipLabels[entry.key] == entry.value)
        .map((entry) => entry.key)
        .toList();
    expect(untranslatedTooltips, isEmpty, reason: 'toolbar tooltips');

    final popupLabelsAllowedToMatchDefault = {
      ...fortuneToolbarFontCommands,
      ...fortuneToolbarFontSizeCommands,
    };
    final untranslatedPopups = fortuneToolbarPopupLabels.entries
        .where(
          (entry) =>
              !popupLabelsAllowedToMatchDefault.contains(entry.key) &&
              locale.toolbarPopupLabels[entry.key] == entry.value,
        )
        .map((entry) => entry.key)
        .toList();
    expect(untranslatedPopups, isEmpty, reason: 'toolbar popups');
  });

  test('korean locale localizes dialog labels', () {
    const defaultLocale = FortuneSheetLocale();
    final locale = FortuneSheetLocale.forLocale(const Locale('ko', 'KR'));

    expect(locale.alternatingColorsLabels['applyRange'], '범위에 적용');
    expect(locale.protectionLabels['protectiontTitle'], '보호');
    expect(locale.formatLabels['moreCurrency'], '기타 통화 형식');
    expect(locale.dataVerificationConditionLabels['checkbox'], '체크박스');
    expect(locale.dataVerificationRuleLabels['between'], '사이');
    expect(locale.filterConditionLabels['cellTextContain'], '텍스트 포함');
    expect(locale.formulaLabels['ifGenerate'], 'IF 수식 생성기');
    expect(locale.formulaMoreLabels['helpClose'], '닫기');
    expect(locale.pivotTableLabels['title'], '피벗 테이블');
    expect(locale.cellFormatTitle, '셀 서식');
    expect(locale.printMenuItemPrint, '인쇄 (Ctrl+P)');

    final dialogMaps = <String, Map<String, String>>{
      'alternating colors': locale.alternatingColorsLabels,
      'protection': locale.protectionLabels,
      'paint': locale.paintLabels,
      'format': locale.formatLabels,
      'data verification conditions': locale.dataVerificationConditionLabels,
      'data verification rules': locale.dataVerificationRuleLabels,
      'data verification tooltips': locale.dataVerificationTooltipMessages,
      'drag': locale.dragLabels,
      'pivot table': locale.pivotTableLabels,
      'filter conditions': locale.filterConditionLabels,
      'formula': locale.formulaLabels,
      'formula more': locale.formulaMoreLabels,
    };
    final defaultDialogMaps = <String, Map<String, String>>{
      'alternating colors': defaultLocale.alternatingColorsLabels,
      'protection': defaultLocale.protectionLabels,
      'paint': defaultLocale.paintLabels,
      'format': defaultLocale.formatLabels,
      'data verification conditions':
          defaultLocale.dataVerificationConditionLabels,
      'data verification rules': defaultLocale.dataVerificationRuleLabels,
      'data verification tooltips':
          defaultLocale.dataVerificationTooltipMessages,
      'drag': defaultLocale.dragLabels,
      'pivot table': defaultLocale.pivotTableLabels,
      'filter conditions': defaultLocale.filterConditionLabels,
      'formula': defaultLocale.formulaLabels,
      'formula more': defaultLocale.formulaMoreLabels,
    };
    const allowedDefaultMatches = <String, Set<String>>{
      'paint': {'end'},
      'formula': {'ifGenRangeTo'},
      'formula more': {'luckysheet'},
    };

    for (final mapEntry in dialogMaps.entries) {
      final untranslatedKeys = defaultDialogMaps[mapEntry.key]!.entries
          .where(
            (entry) =>
                !(allowedDefaultMatches[mapEntry.key] ?? const <String>{})
                    .contains(entry.key) &&
                mapEntry.value[entry.key] == entry.value,
          )
          .map((entry) => entry.key)
          .toList();

      expect(untranslatedKeys, isEmpty, reason: mapEntry.key);
    }

    final dialogScalars = <String, String>{
      'screenshotBrowserNotTip': locale.screenshotBrowserNotTip,
      'screenshotRightClickTip': locale.screenshotRightClickTip,
      'screenshotCopySuccessTip': locale.screenshotCopySuccessTip,
      'imageTextImageSetting': locale.imageTextImageSetting,
      'imageTextMoveCell1': locale.imageTextMoveCell1,
      'splitConfirmToExe': locale.splitConfirmToExe,
      'splitTextTipNoMultiColumn': locale.splitTextTipNoMultiColumn,
      'sortNoRangeError': locale.sortNoRangeError,
      'sortMergeError': locale.sortMergeError,
      'freezeRangeOverError': locale.freezeRangeOverError,
      'mergeOverlappingError': locale.mergeOverlappingError,
      'mergePartiallyError': locale.mergePartiallyError,
      'dataVerificationSelectCellRange': locale.dataVerificationSelectCellRange,
      'dataVerificationPlaceholder1': locale.dataVerificationPlaceholder1,
      'filterRangeStartTip': locale.filterRangeStartTip,
      'filterByColorTip': locale.filterByColorTip,
      'filterMoreDataTip': locale.filterMoreDataTip,
      'filterMergeError': locale.filterMergeError,
      'cellFormatProtectionTips': locale.cellFormatProtectionTips,
      'cellFormatSelectionIsNullAlert': locale.cellFormatSelectionIsNullAlert,
      'printLayoutBtn': locale.printLayoutBtn,
      'websocketRefresh': locale.websocketRefresh,
    };
    final defaultDialogScalars = <String, String>{
      'screenshotBrowserNotTip': defaultLocale.screenshotBrowserNotTip,
      'screenshotRightClickTip': defaultLocale.screenshotRightClickTip,
      'screenshotCopySuccessTip': defaultLocale.screenshotCopySuccessTip,
      'imageTextImageSetting': defaultLocale.imageTextImageSetting,
      'imageTextMoveCell1': defaultLocale.imageTextMoveCell1,
      'splitConfirmToExe': defaultLocale.splitConfirmToExe,
      'splitTextTipNoMultiColumn': defaultLocale.splitTextTipNoMultiColumn,
      'sortNoRangeError': defaultLocale.sortNoRangeError,
      'sortMergeError': defaultLocale.sortMergeError,
      'freezeRangeOverError': defaultLocale.freezeRangeOverError,
      'mergeOverlappingError': defaultLocale.mergeOverlappingError,
      'mergePartiallyError': defaultLocale.mergePartiallyError,
      'dataVerificationSelectCellRange':
          defaultLocale.dataVerificationSelectCellRange,
      'dataVerificationPlaceholder1':
          defaultLocale.dataVerificationPlaceholder1,
      'filterRangeStartTip': defaultLocale.filterRangeStartTip,
      'filterByColorTip': defaultLocale.filterByColorTip,
      'filterMoreDataTip': defaultLocale.filterMoreDataTip,
      'filterMergeError': defaultLocale.filterMergeError,
      'cellFormatProtectionTips': defaultLocale.cellFormatProtectionTips,
      'cellFormatSelectionIsNullAlert':
          defaultLocale.cellFormatSelectionIsNullAlert,
      'printLayoutBtn': defaultLocale.printLayoutBtn,
      'websocketRefresh': defaultLocale.websocketRefresh,
    };
    final untranslatedScalars = defaultDialogScalars.entries
        .where((entry) => dialogScalars[entry.key] == entry.value)
        .map((entry) => entry.key)
        .toList();

    expect(untranslatedScalars, isEmpty);
  });

  test('default toolbar label keys reference known commands', () {
    final toolbarCommands =
        fortuneToolbarItems.where((item) => item != '|').toSet()
          ..add(fortuneToolbarMorePopupKey)
          ..add(fortuneToolbarBarcodeCommand);
    final popupCommands = {
      for (final items in fortuneToolbarPopupItems.values)
        ...items.where((item) => item != '|'),
      ...fortuneConditionFormatHighlightItems,
      ...fortuneConditionFormatSelectionItems,
      ...fortuneConditionFormatDeleteItems,
      ...fortuneToolbarCommentExistingPopupCommands,
      fortuneToolbarFormatMoreCurrencyCommand,
      fortuneToolbarFormatMoreDateTimeCommand,
      fortuneToolbarFormatMoreNumberCommand,
      fortuneConditionFormatUniqueValuesCommand,
      fortuneToolbarBorderStyleDefaultCommand,
      for (var style = 1; style <= 13; style += 1) 'border-style-label-$style',
      'custom-color-label',
    };

    expect(
      fortuneToolbarTooltipLabels.keys.toSet().difference(toolbarCommands),
      isEmpty,
      reason: 'toolbar tooltips',
    );
    expect(
      fortuneToolbarPopupLabels.keys.toSet().difference(popupCommands),
      isEmpty,
      reason: 'toolbar popups',
    );
    expect(
      fortuneFreezeMenuLabels.keys.toSet(),
      fortuneFreezeMenuItems.toSet(),
      reason: 'freeze menu',
    );
  });

  test('toolbar popup maps are reachable from toolbar items', () {
    final toolbarCommands = fortuneToolbarItems
        .where((item) => item != '|')
        .toSet();

    expect(
      fortuneToolbarPopupItems.keys.toSet().difference(toolbarCommands),
      isEmpty,
    );
    expect(
      fortuneToolbarPopupItems.keys,
      isNot(contains(fortuneToolbarFreezePopupKey)),
    );
  });

  test('condition format labels cover nested menu metadata', () {
    const locale = FortuneSheetLocale();
    final conditionPopupCommands = {
      ...fortuneConditionFormatTopLevelItems.where((item) => item != '|'),
      ...fortuneConditionFormatHighlightItems,
      ...fortuneConditionFormatSelectionItems,
      ...fortuneConditionFormatDeleteItems,
      fortuneConditionFormatUniqueValuesCommand,
    };
    final missingPopupLabels = conditionPopupCommands
        .where((item) => !fortuneToolbarPopupLabels.containsKey(item))
        .toList();

    expect(missingPopupLabels, isEmpty);
    expect(
      locale.conditionRuleDescriptions.keys.toSet(),
      locale.conditionRuleTitles.keys.toSet(),
    );
  });

  test('default locale exposes upstream condition format rule labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.conditionRuleTitles, {
      'greaterThan': 'Format cells greater than',
      'lessThan': 'Format cells smaller than',
      'between': 'Format cells with values between',
      'equal': 'Format cells equal to',
      'textContains': 'Format cells containing the following text',
      'occurrenceDate': 'Format cells containing the following dates',
      'duplicateValue': 'Format cells containing the following types of values',
      'top10': 'Format the cells with the highest value',
      'top10_percent': 'Format the cells with the highest value',
      'last10': 'Format the cells with the smallest value',
      'last10_percent': 'Format the cells with the smallest value',
      'aboveAverage': 'Format cells above average',
      'belowAverage': 'Format cells below average',
    });
    expect(locale.duplicateValue, 'Duplicate value');
    expect(locale.uniqueValue, 'Unique value');
    expect(locale.betweenSeparator, 'to');
    expect(locale.top, 'Top');
    expect(locale.bottom, 'Bottom');
    expect(locale.item, 'item');
    expect(locale.percent, '%');
  });

  test('default locale scalar labels are nonempty', () {
    const locale = FortuneSheetLocale();
    final labels = <String, String>{
      'ok': locale.ok,
      'cancel': locale.cancel,
      'close': locale.close,
      'generalDialogLabels': locale.generalDialogLabels.values.join('|'),
      'buttonLabels': locale.buttonLabels.values.join('|'),
      'alternatingColorsLabels': locale.alternatingColorsLabels.values.join(
        '|',
      ),
      'infoLabels': locale.infoLabels.values.join('|'),
      'sheetIsFocused': locale.sheetIsFocused,
      'sheetNotFocused': locale.sheetNotFocused,
      'sheetSrIntro': locale.sheetSrIntro,
      'currentCellInput': locale.currentCellInput,
      'newSheet': locale.newSheet,
      'sheetOptions': locale.sheetOptions,
      'dropdownShortcutLabel': locale.dropdownShortcutLabel,
      'zoomIn': locale.zoomIn,
      'zoomOut': locale.zoomOut,
      'toggleSheetFocusShortcut': locale.toggleSheetFocusShortcut,
      'selectRangeShortcut': locale.selectRangeShortcut,
      'autoFillDownShortcut': locale.autoFillDownShortcut,
      'autoFillRightShortcut': locale.autoFillRightShortcut,
      'boldTextShortcut': locale.boldTextShortcut,
      'copyShortcut': locale.copyShortcut,
      'pasteShortcut': locale.pasteShortcut,
      'undoShortcut': locale.undoShortcut,
      'redoShortcut': locale.redoShortcut,
      'deleteCellContentShortcut': locale.deleteCellContentShortcut,
      'confirmCellEditShortcut': locale.confirmCellEditShortcut,
      'moveRightShortcut': locale.moveRightShortcut,
      'moveLeftShortcut': locale.moveLeftShortcut,
      'toolbar': locale.toolbar,
      'shortcuts': locale.shortcuts,
      'commentInsert': locale.commentInsert,
      'commentEdit': locale.commentEdit,
      'commentDelete': locale.commentDelete,
      'commentShowOne': locale.commentShowOne,
      'commentShowAll': locale.commentShowAll,
      'screenshotTipNoSelection': locale.screenshotTipNoSelection,
      'screenshotTipTitle': locale.screenshotTipTitle,
      'screenshotTipSuccess': locale.screenshotTipSuccess,
      'screenshotTipHasMerge': locale.screenshotTipHasMerge,
      'screenshotTipHasMulti': locale.screenshotTipHasMulti,
      'screenshotImageName': locale.screenshotImageName,
      'screenshotDownloadClose': locale.screenshotDownloadClose,
      'screenshotDownloadCopy': locale.screenshotDownloadCopy,
      'screenshotDownloadButton': locale.screenshotDownloadButton,
      'screenshotBrowserNotTip': locale.screenshotBrowserNotTip,
      'screenshotRightClickTip': locale.screenshotRightClickTip,
      'screenshotCopySuccessTip': locale.screenshotCopySuccessTip,
      'imageTextImageSetting': locale.imageTextImageSetting,
      'imageTextClose': locale.imageTextClose,
      'imageTextConventional': locale.imageTextConventional,
      'imageTextMoveCell1': locale.imageTextMoveCell1,
      'imageTextMoveCell2': locale.imageTextMoveCell2,
      'imageTextMoveCell3': locale.imageTextMoveCell3,
      'imageTextFixedPos': locale.imageTextFixedPos,
      'imageTextBorder': locale.imageTextBorder,
      'imageTextWidth': locale.imageTextWidth,
      'imageTextRadius': locale.imageTextRadius,
      'imageTextStyle': locale.imageTextStyle,
      'imageTextSolid': locale.imageTextSolid,
      'imageTextDashed': locale.imageTextDashed,
      'imageTextDotted': locale.imageTextDotted,
      'imageTextDouble': locale.imageTextDouble,
      'imageTextColor': locale.imageTextColor,
      'imageCtrlBorderTile': locale.imageCtrlBorderTile,
      'imageCtrlBorderCur': locale.imageCtrlBorderCur,
      'protectionLabels': locale.protectionLabels.values.join('|'),
      'find': locale.find,
      'replace': locale.replace,
      'findTextbox': locale.findTextbox,
      'replaceTextbox': locale.replaceTextbox,
      'regexTextbox': locale.regexTextbox,
      'wholeTextbox': locale.wholeTextbox,
      'distinguishTextbox': locale.distinguishTextbox,
      'allReplaceBtn': locale.allReplaceBtn,
      'replaceBtn': locale.replaceBtn,
      'allFindBtn': locale.allFindBtn,
      'findBtn': locale.findBtn,
      'noFindTip': locale.noFindTip,
      'searchInputTip': locale.searchInputTip,
      'noReplaceTip': locale.noReplaceTip,
      'noMatchTip': locale.noMatchTip,
      'replaceSuccessTip': locale.replaceSuccessTip,
      'modeTip': locale.modeTip,
      'searchTargetSheet': locale.searchTargetSheet,
      'searchTargetCell': locale.searchTargetCell,
      'searchTargetValue': locale.searchTargetValue,
      'findCondition': locale.findCondition,
      'location': locale.location,
      'locationExample': locale.locationExample,
      'locationConstant': locale.locationConstant,
      'locationFormula': locale.locationFormula,
      'locationDate': locale.locationDate,
      'locationDigital': locale.locationDigital,
      'locationString': locale.locationString,
      fortuneToolbarLocationBoolCommand: locale.locationBool,
      'locationError': locale.locationError,
      'locationNull': locale.locationNull,
      'locationCondition': locale.locationCondition,
      'locationRowSpan': locale.locationRowSpan,
      'locationColumnSpan': locale.locationColumnSpan,
      'locationTiplessTwoRow': locale.locationTiplessTwoRow,
      'locationTiplessTwoColumn': locale.locationTiplessTwoColumn,
      'locationTipNotFindCell': locale.locationTipNotFindCell,
      'titleCurrency': locale.titleCurrency,
      'titleNumber': locale.titleNumber,
      'decimalPlaces': locale.decimalPlaces,
      'tipDecimalPlaces': locale.tipDecimalPlaces,
      'format': locale.format,
      'currency': locale.currency,
      'paintLabels': locale.paintLabels.values.join('|'),
      'formatLabels': locale.formatLabels.values.join('|'),
      'fontFamilyLabels': locale.fontFamilyLabels.values.join('|'),
      'splitTextTitle': locale.splitTextTitle,
      'splitDelimiters': locale.splitDelimiters,
      'splitOther': locale.splitOther,
      'splitContinueSymbol': locale.splitContinueSymbol,
      'splitDataPreview': locale.splitDataPreview,
      'splitConfirmToExe': locale.splitConfirmToExe,
      'splitTextTipNoMulti': locale.splitTextTipNoMulti,
      'splitTextTipNoMultiColumn': locale.splitTextTipNoMultiColumn,
      'splitTextTipNoSelect': locale.splitTextTipNoSelect,
      'punctuationTab': locale.punctuationTab,
      'punctuationSemicolon': locale.punctuationSemicolon,
      'punctuationComma': locale.punctuationComma,
      'punctuationSpace': locale.punctuationSpace,
      'sortAscendingLabel': locale.sortAscendingLabel,
      'sortDescendingLabel': locale.sortDescendingLabel,
      'sortCustom': locale.sortCustom,
      'sortTitle': locale.sortTitle,
      'sortRangeTitle': locale.sortRangeTitle,
      'sortRangeTitleTo': locale.sortRangeTitleTo,
      'hasTitle': locale.hasTitle,
      'sortBy': locale.sortBy,
      'sortAddOthers': locale.sortAddOthers,
      'sortClose': locale.sortClose,
      'sortColumnOperation': locale.sortColumnOperation,
      'sortSecondaryTitle': locale.sortSecondaryTitle,
      'ascending': locale.ascending,
      'descending': locale.descending,
      'sortConfirm': locale.sortConfirm,
      'sortNoRangeError': locale.sortNoRangeError,
      'sortMergeError': locale.sortMergeError,
      'freezeDefault': locale.freezeDefault,
      'freezeFirstRow': locale.freezeFirstRow,
      'freezeFirstColumn': locale.freezeFirstColumn,
      'freezeBoth': locale.freezeBoth,
      'freezeRowRange': locale.freezeRowRange,
      'freezeColumnRange': locale.freezeColumnRange,
      'freezeRowColumnRange': locale.freezeRowColumnRange,
      'freezeCancel': locale.freezeCancel,
      'freezeNoSelectionError': locale.freezeNoSelectionError,
      'freezeRangeOverErrorTitle': locale.freezeRangeOverErrorTitle,
      'freezeRangeOverError': locale.freezeRangeOverError,
      'mergeAll': locale.mergeAll,
      'mergeVertical': locale.mergeVertical,
      'mergeHorizontal': locale.mergeHorizontal,
      'mergeCancel': locale.mergeCancel,
      'mergeOverlappingError': locale.mergeOverlappingError,
      'mergePartiallyError': locale.mergePartiallyError,
      'borderLabels': locale.borderLabels.values.join('|'),
      'alignLabels': locale.alignLabels.values.join('|'),
      'textWrapLabels': locale.textWrapLabels.values.join('|'),
      'rotationLabels': locale.rotationLabels.values.join('|'),
      'rowHeight': locale.rowHeight,
      'columnWidth': locale.columnWidth,
      'height': locale.height,
      'width': locale.width,
      'linkText': locale.linkText,
      'linkType': locale.linkType,
      'linkAddress': locale.linkAddress,
      'openLink': locale.openLink,
      'goToLink': locale.goToLink,
      'copyLink': locale.copyLink,
      'editLink': locale.editLink,
      'unlink': locale.unlink,
      'linkSheet': locale.linkSheet,
      'linkCell': locale.linkCell,
      'linkSheetOption': locale.linkSheetOption,
      'linkWebpages': locale.linkWebpages,
      'dataVerification': locale.dataVerification,
      'cellRange': locale.cellRange,
      'verificationCondition': locale.verificationCondition,
      'dropdown': locale.dropdown,
      'dataVerificationSelectCellRange': locale.dataVerificationSelectCellRange,
      'dataVerificationSelectCellRange2':
          locale.dataVerificationSelectCellRange2,
      'dataVerificationPlaceholder1': locale.dataVerificationPlaceholder1,
      'dataVerificationPlaceholder2': locale.dataVerificationPlaceholder2,
      'dataVerificationPlaceholder3': locale.dataVerificationPlaceholder3,
      'dataVerificationPlaceholder4': locale.dataVerificationPlaceholder4,
      'dataVerificationPlaceholder5': locale.dataVerificationPlaceholder5,
      'dataVerificationRuleLabels': locale.dataVerificationRuleLabels.values
          .join('|'),
      'allowMultiSelect': locale.allowMultiSelect,
      'prohibitInput': locale.prohibitInput,
      'hintShow': locale.hintShow,
      'deleteVerification': locale.deleteVerification,
      'dataVerificationTooltipMessages': locale
          .dataVerificationTooltipMessages
          .values
          .join('|'),
      'dropCellCopyCell': locale.dropCellCopyCell,
      'dropCellSequence': locale.dropCellSequence,
      'dropCellOnlyFormat': locale.dropCellOnlyFormat,
      'dropCellNoFormat': locale.dropCellNoFormat,
      'dropCellDay': locale.dropCellDay,
      'dropCellWorkDay': locale.dropCellWorkDay,
      'dropCellMonth': locale.dropCellMonth,
      'dropCellYear': locale.dropCellYear,
      'dropCellChineseNumber': locale.dropCellChineseNumber,
      'dragLabels': locale.dragLabels.values.join('|'),
      'pivotTableLabels': locale.pivotTableLabels.values.join('|'),
      'cellFormatTitle': locale.cellFormatTitle,
      'cellFormatProtection': locale.cellFormatProtection,
      'cellFormatLocked': locale.cellFormatLocked,
      'cellFormatHidden': locale.cellFormatHidden,
      'cellFormatProtectionTips': locale.cellFormatProtectionTips,
      'cellFormatTipsPart': locale.cellFormatTipsPart,
      'cellFormatTipsAll': locale.cellFormatTipsAll,
      'cellFormatSelectionIsNullAlert': locale.cellFormatSelectionIsNullAlert,
      'cellFormatSheetDataIsNullAlert': locale.cellFormatSheetDataIsNullAlert,
      'printNormalBtn': locale.printNormalBtn,
      'printLayoutBtn': locale.printLayoutBtn,
      'printPageBtn': locale.printPageBtn,
      'printMenuItemPrint': locale.printMenuItemPrint,
      'printMenuItemAreas': locale.printMenuItemAreas,
      'printMenuItemRows': locale.printMenuItemRows,
      'printMenuItemColumns': locale.printMenuItemColumns,
      'editTyping': locale.editTyping,
      'websocketSuccess': locale.websocketSuccess,
      'websocketRefresh': locale.websocketRefresh,
      'websocketWait': locale.websocketWait,
      'websocketClose': locale.websocketClose,
      'websocketContact': locale.websocketContact,
      'websocketSupport': locale.websocketSupport,
      'filterSortByAsc': locale.filterSortByAsc,
      'filterSortByDesc': locale.filterSortByDesc,
      'filterCreate': locale.filterCreate,
      'filterByColor': locale.filterByColor,
      'filterClear': locale.filterClear,
      'filterByCondition': locale.filterByCondition,
      'filterByValues': locale.filterByValues,
      'filterInputNone': locale.filterInputNone,
      'filterInputTip': locale.filterInputTip,
      'filterRangeStartTip': locale.filterRangeStartTip,
      'filterRangeEndTip': locale.filterRangeEndTip,
      'filterConditionLabels': locale.filterConditionLabels.values.join('|'),
      'filterCheckAll': locale.filterCheckAll,
      'filterClearSelection': locale.filterClearSelection,
      'filterInverseSelection': locale.filterInverseSelection,
      'filterCellColor': locale.filterCellColor,
      'filterTextColor': locale.filterTextColor,
      'filterByColorTip': locale.filterByColorTip,
      'filterByTextColorTip': locale.filterByTextColorTip,
      'filterContainerOneColorTip': locale.filterContainerOneColorTip,
      'filterDateFormatTip': locale.filterDateFormatTip,
      'filterConfirm': locale.filterConfirm,
      'filterCancel': locale.filterCancel,
      'filterMoreDataTip': locale.filterMoreDataTip,
      'filterMonthText': locale.filterMonthText,
      'filterYearText': locale.filterYearText,
      'filterBlankValue': locale.filterBlankValue,
      'filterMergeError': locale.filterMergeError,
      'filterValueSearchPlaceholder': locale.filterValueSearchPlaceholder,
      'filterNoMatches': locale.filterNoMatches,
      'findFunctionTitle': locale.findFunctionTitle,
      'functionSearchPlaceholder': locale.functionSearchPlaceholder,
      'functionCategoryLabel': locale.functionCategoryLabel,
      'selectFunctionLabel': locale.selectFunctionLabel,
      'formulaLabels': locale.formulaLabels.values.join('|'),
      'formulaMoreLabels': locale.formulaMoreLabels.values.join('|'),
      'clearColor': locale.clearColor,
      'customColorReset': locale.customColorReset,
      'customColorConfirm': locale.customColorConfirm,
      'setAs': locale.setAs,
      'textColor': locale.textColor,
      'cellColor': locale.cellColor,
      'conditionRuleFallbackDescription':
          locale.conditionRuleFallbackDescription,
      'duplicateValue': locale.duplicateValue,
      'uniqueValue': locale.uniqueValue,
      'betweenSeparator': locale.betweenSeparator,
      'top': locale.top,
      'bottom': locale.bottom,
      'item': locale.item,
      'percent': locale.percent,
    };

    final emptyLabels = labels.entries
        .where((entry) => entry.value.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();

    expect(emptyLabels, isEmpty);
  });

  test(
    'default locale exposes upstream common dialog button alternating info paint and format labels',
    () {
      const locale = FortuneSheetLocale();

      expect(locale.generalDialogLabels, {
        'partiallyError':
            'Cannot perform this operation on partially merged cells',
        'readOnlyError': 'Cannot perform this operation in read-only mode',
        'dataNullError':
            'Cannot perform this operation on data that does not exist',
        'noSeletionError': 'The selection operation has not been performed yet',
        'cannotSelectMultiple': 'Cannot select multiple selections',
      });
      expect(locale.buttonLabels, {
        'confirm': 'OK',
        'cancel': 'Cancel',
        'close': 'Close',
        'update': 'Update',
        'delete': 'Delete',
        'insert': 'Insert',
        'prevPage': 'Previous',
        'nextPage': 'Next',
        'total': 'total:',
      });
      expect(locale.alternatingColorsLabels, {
        'applyRange': 'Apply to range',
        'selectRange': 'Select a data range',
        'header': 'Header',
        'footer': 'Footer',
        'errorInfo':
            'Cannot perform this operation on multiple selection areas, please select a single area and try again',
        'textTitle': 'Format style',
        'custom': 'CUSTOM',
        'close': 'close',
        'selectionTextColor': 'Click to select text color',
        'selectionCellColor': 'Click to select cell color',
        'removeColor': 'Remove alternating colors',
        'colorShow': 'color',
        'currentColor': 'Current',
        'tipSelectRange': 'Please select the range of alternating colors',
        'errorNoRange': 'No range is selected',
        'errorExistColors':
            'Alternating colors already exist and cannot be edited',
      });
      expect(locale.infoLabels, {
        'detailUpdate': 'New opened',
        'detailSave': 'Local cache restored',
        'row': '',
        'column': '',
        'loading': 'Loading...',
        'copy': 'Copy',
        'return': 'Exit',
        'rename': 'Rename',
        'tips': 'WorkBook rename',
        'noName': 'Untitled spreadsheet',
        'wait': 'waiting for update',
        'add': 'Add',
        'addLast': 'more rows at bottom',
        'backTop': 'Back to the top',
        'pageInfo': r'Total ${total}，${totalPage} page，current ${currentPage}',
        'nextPage': 'Next',
        'tipInputNumber': 'Please enter the number',
        'tipInputNumberLimit': 'The increase range is limited to 1-100',
        'tipRowHeightLimit': 'Row height must be between 0 ~ 545',
        'tipColumnWidthLimit': 'The column width must be between 0 ~ 2038',
        'pageInfoFull': r'Total ${total}，${totalPage} page，All data displayed',
        'sheetIsFocused': 'Sheet focus lock enabled.',
        'sheetNotFocused': 'Sheet focus lock disabled.',
        'sheetSrIntro':
            'To toggle sheet focus to assist with toolbar and other non-sheet navigation, use Shift, Control, F.',
        'currentCellInput': 'Current cell input',
        'newSheet': 'New sheet',
        'sheetOptions': 'Sheet options',
        'Dropdown': 'Dropdown',
        'zoomIn': 'Zoom in',
        'zoomOut': 'Zoom out',
        'toggleSheetFocusShortcut':
            'Toggle sheet focus lock: Shift, Control, F.',
        'selectRangeShortcut': 'Select range: Shift, arrow keys.',
        'autoFillDownShortcut':
            'Auto-fill selection down from first cell: Control or Meta key, D.',
        'autoFillRightShortcut':
            'Auto-fill selection right from first cell: Control or Meta key, R.',
        'boldTextShortcut': 'Bold text: Control or Meta key, B.',
        'copyShortcut': 'Copy: Control or Meta key, C.',
        'pasteShortcut': 'Paste: Control or Meta key, V.',
        'undoShortcut': 'Undo: Control or Meta key, Z.',
        'redoShortcut': 'Redo: Control or Meta key, Shift, Z.',
        'deleteCellContentShortcut':
            'Delete cell content: Delete or Backspace.',
        'confirmCellEditShortcut': 'Confirm cell edit and move down: Enter.',
        'moveRightShortcut': 'Move right: Tab.',
        'moveLeftShortcut': 'Move left: Shift, Tab.',
        'shortcuts': 'Keyboard Shortcuts',
      });
      expect(locale.paintLabels, {
        'start': 'Paint format start',
        'end': 'ESC',
        'tipSelectRange': 'Please select the range to be copied',
        'tipNotMulti':
            'Cannot perform this operation on multiple selection ranges',
      });
      expect(locale.formatLabels, {
        'moreCurrency': 'More currency formats',
        'moreDateTime': 'More date and time formats',
        'moreNumber': 'More number formats',
        'titleCurrency': 'Currency formats',
        'decimalPlaces': 'Decimal places',
        'titleDateTime': 'Date and time formats',
        'titleNumber': 'Number formats',
        'tipDecimalPlaces': 'The decimal places must be between 0-9!',
        'select': 'Select',
        'format': 'format',
        'currency': 'currency',
      });
      expect(locale.fontFamilyLabels, {'MicrosoftYaHei': 'YaHei'});
    },
  );

  test('default locale exposes upstream sheet focus shortcut labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.sheetIsFocused, 'Sheet focus lock enabled.');
    expect(locale.sheetNotFocused, 'Sheet focus lock disabled.');
    expect(
      locale.sheetSrIntro,
      'To toggle sheet focus to assist with toolbar and other non-sheet navigation, use Shift, Control, F.',
    );
    expect(locale.currentCellInput, 'Current cell input');
    expect(locale.dialogInputCut, 'Cut');
    expect(locale.dialogInputCopy, 'Copy');
    expect(locale.dialogInputPaste, 'Paste');
    expect(locale.dialogInputSelectAll, 'Select all');
    expect(locale.newSheet, 'New sheet');
    expect(locale.sheetOptions, 'Sheet options');
    expect(locale.dropdownShortcutLabel, 'Dropdown');
    expect(locale.toolbar, 'Toolbar');
    expect(locale.clearColor, 'Clear color');
    expect(locale.commentInsert, 'Insert');
    expect(locale.commentEdit, 'Edit');
    expect(locale.commentDelete, 'Delete');
    expect(locale.commentShowOne, 'Show/Hide');
    expect(locale.commentShowAll, 'Show/Hide All');
    expect(
      locale.screenshotTipNoSelection,
      'Please select the scope of the screenshot',
    );
    expect(locale.screenshotTipTitle, 'Warning！');
    expect(locale.screenshotTipSuccess, 'Successful');
    expect(
      locale.screenshotTipHasMerge,
      'This operation cannot be performed on merged cells',
    );
    expect(
      locale.screenshotTipHasMulti,
      'This operation cannot be performed on multiple selection regions',
    );
    expect(locale.screenshotImageName, 'Screenshot');
    expect(locale.screenshotDownloadClose, 'Close');
    expect(locale.screenshotDownloadCopy, 'Copy to clipboard');
    expect(locale.screenshotDownloadButton, 'Download');
    expect(locale.screenshotBrowserNotTip, 'not supported by IE browser!');
    expect(
      locale.screenshotRightClickTip,
      'Please right-click "copy" on the picture',
    );
    expect(
      locale.screenshotCopySuccessTip,
      'Successfully (if pasting fails, please right-click on the image to "copy image")',
    );
    expect(locale.imageTextImageSetting, 'Image setting');
    expect(locale.imageTextClose, 'Close');
    expect(locale.imageTextConventional, 'Conventional');
    expect(locale.imageTextMoveCell1, 'Move and resize cells');
    expect(locale.imageTextMoveCell2, 'Move and do not resize the cell');
    expect(locale.imageTextMoveCell3, 'Do not move and resize the cell');
    expect(locale.imageTextFixedPos, 'Fixed position');
    expect(locale.imageTextBorder, 'Border');
    expect(locale.imageTextWidth, 'Width');
    expect(locale.imageTextRadius, 'Radius');
    expect(locale.imageTextStyle, 'Style');
    expect(locale.imageTextSolid, 'Solid');
    expect(locale.imageTextDashed, 'Dashed');
    expect(locale.imageTextDotted, 'Dotted');
    expect(locale.imageTextDouble, 'Double');
    expect(locale.imageTextColor, 'Color');
    expect(locale.imageCtrlBorderTile, 'Image border color');
    expect(locale.imageCtrlBorderCur, 'Color');
    expect(locale.zoomIn, 'Zoom in');
    expect(locale.zoomOut, 'Zoom out');
    expect(
      locale.toggleSheetFocusShortcut,
      'Toggle sheet focus lock: Shift, Control, F.',
    );
    expect(locale.selectRangeShortcut, 'Select range: Shift, arrow keys.');
    expect(
      locale.autoFillDownShortcut,
      'Auto-fill selection down from first cell: Control or Meta key, D.',
    );
    expect(
      locale.autoFillRightShortcut,
      'Auto-fill selection right from first cell: Control or Meta key, R.',
    );
    expect(locale.boldTextShortcut, 'Bold text: Control or Meta key, B.');
    expect(locale.copyShortcut, 'Copy: Control or Meta key, C.');
    expect(locale.pasteShortcut, 'Paste: Control or Meta key, V.');
    expect(locale.undoShortcut, 'Undo: Control or Meta key, Z.');
    expect(locale.redoShortcut, 'Redo: Control or Meta key, Shift, Z.');
    expect(
      locale.deleteCellContentShortcut,
      'Delete cell content: Delete or Backspace.',
    );
    expect(
      locale.confirmCellEditShortcut,
      'Confirm cell edit and move down: Enter.',
    );
    expect(locale.moveRightShortcut, 'Move right: Tab.');
    expect(locale.moveLeftShortcut, 'Move left: Shift, Tab.');
    expect(locale.shortcuts, 'Keyboard Shortcuts');
  });

  test('default locale exposes upstream filter and formula labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.dataVerification, 'Data verification');
    expect(locale.dropCellCopyCell, 'Copy');
    expect(locale.dropCellSequence, 'Sequence');
    expect(locale.dropCellOnlyFormat, 'Only format');
    expect(locale.dropCellNoFormat, 'Not format');
    expect(locale.dropCellDay, 'Day');
    expect(locale.dropCellWorkDay, 'Work Day');
    expect(locale.dropCellMonth, 'Month');
    expect(locale.dropCellYear, 'Year');
    expect(locale.dropCellChineseNumber, 'Chinese numbers');
    expect(locale.filterSortByAsc, 'Ascending sort');
    expect(locale.filterSortByDesc, 'Descending sort');
    expect(locale.filterCreate, 'create filter');
    expect(locale.filterByColor, 'Filter by color');
    expect(locale.filterByCondition, 'Filter by condition');
    expect(locale.filterByValues, 'Filter by values');
    expect(locale.filterInputNone, 'None');
    expect(locale.filterInputTip, 'Enter filter value');
    expect(locale.filterRangeStartTip, 'Value for formula');
    expect(locale.filterRangeEndTip, 'Value for formula');
    expect(locale.filterConditionLabels, {
      'none': 'None',
      'cellIsNull': 'Is empty',
      'cellNotNull': 'Is not empty',
      'cellTextContain': 'Text contains',
      'cellTextNotContain': 'Text does not contain',
      'cellTextStart': 'Text starts with',
      'cellTextEnd': 'Text ends with',
      'cellTextEqual': 'Text is exactly',
      'cellDateEqual': 'Date is',
      'cellDateBefore': 'Date is before',
      'cellDateAfter': 'Date is after',
      'cellGreater': 'Greater than',
      'cellGreaterEqual': 'Greater than or equal to',
      'cellLess': 'Less than',
      'cellLessEqual': 'Less than or equal to',
      'cellEqual': 'Is equal to',
      'cellNotEqual': 'Is not equal to',
      'cellBetween': 'Is between',
      'cellNotBetween': 'Is not between',
    });
    expect(locale.filterCheckAll, 'Check all');
    expect(locale.filterClearSelection, 'Clear');
    expect(locale.filterInverseSelection, 'Inverse');
    expect(locale.filterByColorTip, 'Filter by cell color');
    expect(locale.filterByTextColorTip, 'Filter by font color');
    expect(
      locale.filterContainerOneColorTip,
      'This column contains only one color',
    );
    expect(locale.filterDateFormatTip, 'Date format');
    expect(locale.filterConfirm, 'Confirm');
    expect(locale.filterCancel, 'Cancel');
    expect(locale.filterMoreDataTip, 'Big amount of data! please wait');
    expect(locale.filterMonthText, 'Month');
    expect(locale.filterYearText, 'Year');
    expect(locale.filterBlankValue, '(Null)');
    expect(
      locale.filterMergeError,
      'There are merged cells in the filter selection, this operation cannot be performed!',
    );
    expect(locale.filterValueSearchPlaceholder, 'filter By Values');
    expect(locale.filterClear, 'Clear filter');
    expect(locale.findFunctionTitle, 'Search function');
    expect(
      locale.functionSearchPlaceholder,
      'Function name or brief description of function',
    );
  });

  test('default locale exposes upstream formula labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.formulaLabels, {
      'sum': 'Sum',
      'average': 'Average',
      'count': 'Count',
      'max': 'Max',
      'min': 'Min',
      'ifGenerate': 'If formula generator',
      'find': 'Learn more',
      'tipNotBelongToIf':
          'This cell function does not belong to the if formula!',
      'tipSelectCell': 'Please select the cell to insert the function',
      'ifGenCompareValueTitle': 'Comparison value',
      'ifGenSelectCellTitle': 'Click to select cell',
      'ifGenRangeTitle': 'Range',
      'ifGenRangeTo': 'to',
      'ifGenRangeEvaluate': 'Range evaluate',
      'ifGenSelectRangeTitle': 'Click to select range',
      'ifGenCutWay': 'Partition way',
      'ifGenCutSame': 'Same Partition value',
      'ifGenCutNpiece': 'Partition by N',
      'ifGenCutCustom': 'Custom',
      'ifGenCutConfirm': 'Confirm',
      'ifGenTipSelectCell': 'Select cells',
      'ifGenTipSelectCellPlace': 'Please select cells',
      'ifGenTipSelectRange': 'Select range',
      'ifGenTipSelectRangePlace': 'Please select range',
      'ifGenTipNotNullValue': 'The comparison value cannot be empty!',
      'ifGenTipLableTitile': 'Label',
      'ifGenTipRangeNotforNull': 'The range cannot be empty!',
      'ifGenTipCutValueNotforNull': 'The partition value cannot be empty!',
      'ifGenTipNotGenCondition': 'No conditions are available for generation!',
    });
    expect(locale.formulaMoreLabels, {
      'valueTitle': 'Value',
      'tipSelectDataRange': 'Select data range',
      'tipDataRangeTile': 'Data range',
      'findFunctionTitle': 'Search function',
      'tipInputFunctionName': 'Function name or brief description of function',
      'Array': 'Array',
      'Database': 'Database',
      'Date': 'Date',
      'Engineering': 'Engineering',
      'Filter': 'Filter',
      'Financial': 'Financial',
      'luckysheet': 'Luckysheet',
      'other': 'Other',
      'Logical': 'Logical',
      'Lookup': 'Lookup',
      'Math': 'Math',
      'Operator': 'Operator',
      'Parser': 'Parser',
      'Statistical': 'Statistical',
      'Text': 'Text',
      'dataMining': 'Data Mining',
      'selectFunctionTitle': 'Select a function',
      'calculationResult': 'Result',
      'tipSuccessText': 'Success',
      'tipParamErrorText': 'Parameter type error',
      'helpClose': 'Close',
      'helpCollapse': 'Collapse',
      'helpExample': 'Example',
      'helpAbstract': 'Abstract',
      'execfunctionError': 'Error in the formula',
      'execfunctionSelfError': 'The formula cannot refer to its own cell',
      'execfunctionSelfErrorResult':
          'The formula cannot refer to its own cell, which will lead to inaccurate calculation results',
      'allowRepeatText': 'Repeatable',
      'allowOptionText': 'Optional',
      'selectCategory': 'Or select a category',
    });
  });

  test('default locale exposes upstream cell format labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.cellFormatTitle, 'Format cells');
    expect(locale.cellFormatProtection, 'Protection');
    expect(locale.cellFormatLocked, 'Locked');
    expect(locale.cellFormatHidden, 'Hidden');
    expect(
      locale.cellFormatProtectionTips,
      'To lock cells or hide formulas, protect the worksheet. On the toolbar, Click Protect Sheet Button',
    );
    expect(locale.cellFormatTipsPart, 'Partial checked');
    expect(locale.cellFormatTipsAll, 'All checked');
    expect(locale.cellFormatSelectionIsNullAlert, 'Selection is required!');
    expect(locale.cellFormatSheetDataIsNullAlert, 'error, Data is none!');
  });

  test('default locale exposes upstream drag labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.dragLabels, {
      'noMerge': 'Cannot perform this operation on merged cells',
      'affectPivot':
          'This change cannot be made to the selected cell because it will affect the pivot table!',
      'noMulti':
          'Cannot perform this operation on multiple selection areas, please select a single area',
      'noPaste':
          'Unable to paste this content here, please select a cell in the paste area and try to paste again',
      'noPartMerge': 'Cannot perform this operation on partially merged cells',
      'inputCorrect': 'Please enter the correct value',
      'notLessOne': 'The number of rows and columns cannot be less than 1',
      'offsetColumnLessZero': 'The offset column cannot be negative!',
      'pasteMustKeybordAlert':
          '在表格中进行复制粘贴: Ctrl + C 进行复制, Ctrl + V 进行粘贴, Ctrl + X 进行剪切',
      'pasteMustKeybordAlertHTMLTitle': '在表格中进行复制粘贴',
      'pasteMustKeybordAlertHTML':
          "<span style='line-height: 1.0;font-size:36px;font-weight: bold;color:#666;'>Ctrl + C</span>&nbsp;&nbsp;进行复制<br/><span style='line-height: 1.0;font-size:36px;font-weight: bold;color:#666;'>Ctrl + V</span>&nbsp;&nbsp;进行粘贴<br/><span style='line-height: 1.0;font-size:36px;font-weight: bold;color:#666;'>Ctrl + X</span>&nbsp;&nbsp;进行剪切",
    });
  });

  test('default locale exposes upstream pivot table labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.pivotTableLabels, {
      'title': 'Pivot Table',
      'closePannel': 'Close',
      'editRange': 'Range',
      'tipPivotFieldSelected': 'Select the fields',
      'tipClearSelectedField': 'Clear all fields',
      'btnClearSelectedField': 'Clear',
      'btnFilter': 'Filter',
      'titleRow': 'Row',
      'titleColumn': 'Column',
      'titleValue': 'Value',
      'tipShowColumn': 'Statistics fields are displayed as columns',
      'tipShowRow': 'Statistics fields are displayed as rows',
      'titleSelectionDataRange': 'Select range',
      'titleDataRange': 'Data range',
      'valueSum': 'SUM',
      'valueStatisticsSUM': 'Sum',
      'valueStatisticsCOUNT': 'Count',
      'valueStatisticsCOUNTA': 'Count A',
      'valueStatisticsCOUNTUNIQUE': 'Count Unique',
      'valueStatisticsAVERAGE': 'Average',
      'valueStatisticsMAX': 'Max',
      'valueStatisticsMIN': 'Min',
      'valueStatisticsMEDIAN': 'Median',
      'valueStatisticsPRODUCT': 'Product',
      'valueStatisticsSTDEV': 'Stdev',
      'valueStatisticsSTDEVP': 'Stdevp',
      'valueStatisticslet': 'Var',
      'valueStatisticsVARP': 'VarP',
      'errorNotAllowEdit': 'This operation is prohibited in non-editing mode!',
      'errorNotAllowMulti':
          'Cannot perform this operation on multiple selection areas, please select a single range and try again',
      'errorSelectRange': 'Please select the range of the new pivot table',
      'errorIsDamage': 'The source data of this pivot table is corrupted!',
      'errorNotAllowPivotData': 'Cannot select pivot table as source data!',
      'errorSelectionRange': 'Selection failed, wrong input range!',
      'errorIncreaseRange': 'Please expand the selected range!',
      'titleAddColumn': 'Add column to pivot table',
      'titleMoveColumn': 'Move the column to the white box below',
      'titleClearColumnFilter': 'Clear the filter for this column',
      'titleFilterColumn': 'Filter',
      'titleSort': 'Sort',
      'titleNoSort': 'No sort',
      'titleSortAsc': 'ASC',
      'titleSortDesc': 'DESC',
      'titleSortBy': 'Sort by',
      'titleShowSum': 'Show total',
      'titleStasticTrue': 'Yes',
      'titleStasticFalse': 'No',
    });
  });

  test('default locale exposes upstream protection labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.protectionLabels, {
      'protectiontTitle': 'Protection',
      'enterPassword': 'Enter a password (optional)',
      'enterHintTitle': 'Prompt when editing is prohibited (optional)',
      'enterHint':
          'The cell or chart you are trying to change is in a protected worksheet. If you want to change it, please unprotect the worksheet. You may need to enter a password',
      'swichProtectionTip': 'Protect the sheet and contents of locked cells',
      'authorityTitle': 'Allow users of this sheet to:',
      'selectLockedCells': 'Select locked cells',
      'selectunLockedCells': 'Select unlocked cells',
      'formatCells': 'Format cells',
      'formatColumns': 'Format columns',
      'formatRows': 'Format rows',
      'insertColumns': 'Insert columns',
      'insertRows': 'Insert rows',
      'insertHyperlinks': 'Insert hyperlinks',
      'deleteColumns': 'Delete columns',
      'deleteRows': 'Delete rows',
      'sort': 'Sort',
      'filter': 'Filter',
      'usePivotTablereports': 'Use Pivot Table reports',
      'editObjects': 'Edit objects',
      'editScenarios': 'Edit scenarios',
      'allowRangeTitle': 'Allow users of range to:',
      'allowRangeAdd': 'New...',
      'allowRangeAddTitle': 'Title',
      'allowRangeAddSqrf': 'Reference',
      'selectCellRange': 'Click to select a cell range',
      'selectCellRangeHolder': 'Cell range',
      'allowRangeAddTitlePassword': 'Password',
      'allowRangeAddTitleHint': 'Prompt',
      'allowRangeAddTitleHintTitle': 'Prompt when a password is set (optional)',
      'allowRangeAddtitleDefault': 'Input range name',
      'rangeItemDblclick': 'Double click to edit',
      'rangeItemHasPassword': 'Has password',
      'rangeItemErrorTitleNull': 'Title is null',
      'rangeItemErrorRangeNull': 'Reference is null',
      'rangeItemErrorRange': 'Reference is error',
      'validationTitle': 'Password validation',
      'validationTips':
          'Need to enter a password to unlock the protection of the worksheet',
      'validationInputHint': 'Enter a password',
      'checkPasswordNullalert': 'Password is required!',
      'checkPasswordWrongalert': 'Incorrect password, please try again!',
      'checkPasswordSucceedalert': 'Unlock Succeed!',
      'defaultRangeHintText': 'The cell is being password protected.',
      'defaultSheetHintText':
          'The cell or chart is in a protected worksheet. To make changes, please unprotect the worksheet. You may need to enter a password',
    });
  });

  test('default locale exposes upstream print edit and websocket labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.printNormalBtn, 'Normal');
    expect(locale.printLayoutBtn, 'Page Layout');
    expect(locale.printPageBtn, 'Page break preview');
    expect(locale.printMenuItemPrint, 'Print (Ctrl+P)');
    expect(locale.printMenuItemAreas, 'Print areas');
    expect(locale.printMenuItemRows, 'Print title rows');
    expect(locale.printMenuItemColumns, 'Print title columns');
    expect(locale.editTyping, 'typing');
    expect(locale.websocketSuccess, 'WebSocket connection success');
    expect(
      locale.websocketRefresh,
      'An error occurred in the WebSocket connection, please refresh the page!',
    );
    expect(
      locale.websocketWait,
      'An error occurred in the WebSocket connection, please be patient!',
    );
    expect(locale.websocketClose, 'WebSocket connection closed');
    expect(
      locale.websocketContact,
      'Server communication error occurred, please refresh the page and try again, if not, please contact the administrator!',
    );
    expect(
      locale.websocketSupport,
      'The current browser does not support WebSocket',
    );
  });

  test('default locale exposes upstream find and replace labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.find, 'Find');
    expect(locale.replace, 'Replace');
    expect(locale.location, 'Location');
    expect(locale.locationFormula, 'Formula');
    expect(locale.locationDate, 'Date');
    expect(locale.locationDigital, 'Number');
    expect(locale.locationString, 'String');
    expect(locale.locationError, 'Error');
    expect(locale.locationRowSpan, 'Row span');
    expect(locale.locationColumnSpan, 'Column span');
    expect(locale.locationTiplessTwoRow, 'Please select at least two rows');
    expect(
      locale.locationTiplessTwoColumn,
      'Please select at least two columns',
    );
    expect(locale.findTextbox, 'Find Content');
    expect(locale.replaceTextbox, 'Replace Content');
    expect(locale.regexTextbox, 'Regular Expression');
    expect(locale.wholeTextbox, 'Whole word');
    expect(locale.distinguishTextbox, 'Case sensitive');
    expect(locale.allReplaceBtn, 'Replace All');
    expect(locale.replaceBtn, 'Replace');
    expect(locale.allFindBtn, 'Find All');
    expect(locale.findBtn, 'Find next');
    expect(locale.noFindTip, 'The content was not found');
    expect(locale.modeTip, 'This operation is not available in this mode');
    expect(locale.searchTargetSheet, 'Sheet');
    expect(locale.searchTargetCell, 'Cell');
    expect(locale.searchTargetValue, 'Value');
    expect(locale.findCondition, 'Condition');
    expect(locale.searchInputTip, 'Please enter the search content');
    expect(locale.noReplaceTip, 'There is nothing to replace');
    expect(locale.noMatchTip, 'No match found');
    expect(locale.replaceSuccessTip, r'${xlength} items found');
    expect(locale.locationExample, 'Location');
    expect(locale.locationConstant, 'Constant');
    expect(locale.locationCondition, 'Conditional format');
  });

  test('default locale exposes upstream split sort and link labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.splitDelimiters, 'Delimiters');
    expect(locale.splitOther, 'Other');
    expect(
      locale.splitContinueSymbol,
      'Consecutive separators are treated as a single',
    );
    expect(locale.splitDataPreview, 'Preview');
    expect(locale.splitTextTitle, 'Split text');
    expect(
      locale.splitConfirmToExe,
      'There is already data here, do you want to replace it?',
    );
    expect(locale.punctuationTab, 'Tab');
    expect(locale.punctuationSemicolon, 'semicolon');
    expect(locale.punctuationComma, 'comma');
    expect(locale.punctuationSpace, 'space');
    expect(
      [
        locale.punctuationTab,
        locale.punctuationSemicolon,
        locale.punctuationComma,
        locale.punctuationSpace,
      ],
      ['Tab', 'semicolon', 'comma', 'space'],
    );
    expect(
      locale.splitTextTipNoMulti,
      'Cannot perform this operation on multiple selection areas, please select a single area and try again',
    );
    expect(
      locale.splitTextTipNoMultiColumn,
      'Only one column of data can be converted at a time. The selected area can have multiple rows but not multiple columns. Please try again after selecting a single column range',
    );
    expect(
      locale.splitTextTipNoSelect,
      'You cannot separate a cell without selecting it',
    );
    expect(locale.sortAscendingLabel, 'Ascending ');
    expect(locale.sortDescendingLabel, 'Descending ');
    expect(locale.sortCustom, 'Custom sort');
    expect(locale.sortTitle, 'Sort range');
    expect(locale.hasTitle, 'Data has a header row');
    expect(locale.sortBy, 'Sort by');
    expect(locale.sortAddOthers, 'Add another sort column');
    expect(locale.sortClose, 'close');
    expect(locale.sortColumnOperation, 'Column');
    expect(locale.sortSecondaryTitle, 'then by');
    expect(locale.sortConfirm, 'sort');
    expect(locale.sortRangeTitle, 'Sort range from');
    expect(locale.sortRangeTitleTo, 'to');
    expect(
      locale.sortNoRangeError,
      'Cannot perform this operation on multiple selection areas, please select a single range and try again',
    );
    expect(
      locale.sortMergeError,
      'There are merged cells in the selection, this operation cannot be performed!',
    );
    expect(locale.linkText, 'Display text');
    expect(locale.linkType, 'Link type');
    expect(locale.linkAddress, 'Link address');
    expect(locale.linkSheet, 'Worksheet');
    expect(locale.linkCell, 'Cell range');
    expect(locale.selectCellRange, 'Select cell range');
    expect(
      locale.cellRangePlaceholder,
      'Select cells using the cursor or enter directly',
    );
    expect(locale.openLink, 'Open link');
    expect(locale.goToLink, r'Go to ${linkAddress}');
    expect(locale.linkWebpages, 'Webpages');
    expect(locale.linkSheetOption, 'Sheet');
  });

  test('default locale exposes upstream data verification dialog labels', () {
    const locale = FortuneSheetLocale();

    expect(locale.dataVerification, 'Data verification');
    expect(locale.cellRange, 'Cell range');
    expect(locale.verificationCondition, 'Verification condition');
    expect(locale.allowMultiSelect, 'Allow multiple selection');
    expect(locale.dropdown, 'drop-down list');
    expect(
      locale.dataVerificationSelectCellRange,
      'Click to select a cell range',
    );
    expect(
      locale.dataVerificationSelectCellRange2,
      'Please select a range of cells',
    );
    expect(locale.dataVerificationConditionLabels, {
      'dropdown': 'drop-down list',
      'checkbox': 'Checkbox',
      'number': 'Number',
      'number_integer': 'Number-integer',
      'number_decimal': 'Number-decimal',
      'text_content': 'Text-content',
      'text_length': 'Text-length',
      'date': 'Date',
      'validity': 'Effectiveness',
    });
    expect(
      locale.dataVerificationPlaceholder1,
      'Please enter the options, separated by commas, such as 1,2,3,4,5',
    );
    expect(locale.dataVerificationPlaceholder2, 'Please enter content');
    expect(locale.dataVerificationPlaceholder3, 'Numeric value, such as 10');
    expect(
      locale.dataVerificationPlaceholder4,
      'Please enter the specified text',
    );
    expect(
      locale.dataVerificationPlaceholder5,
      'Please enter the prompt displayed when the cell is selected',
    );
    expect(locale.dataVerificationRuleLabels, {
      'selected': 'Selected',
      'notSelected': 'Not selected',
      'between': 'Between',
      'notBetween': 'Not between',
      'equal': 'Equal',
      'notEqualTo': 'Not equal to',
      'moreThanThe': 'More than the',
      'lessThan': 'Less than',
      'greaterOrEqualTo': 'Greater or equal to',
      'lessThanOrEqualTo': 'Less than or equal to',
      'include': 'Include',
      'exclude': 'Exclude',
      'earlierThan': 'Earlier than',
      'noEarlierThan': 'No earlier than',
      'laterThan': 'Later than',
      'noLaterThan': 'No later than',
      'identificationNumber': 'Identification number',
      'phoneNumber': 'Phone number',
      'remote': 'Automatic remote acquisition option',
    });
    expect(locale.prohibitInput, 'Prohibit input when input data is invalid');
    expect(locale.hintShow, 'Show prompt when the cell is selected');
    expect(locale.deleteVerification, 'Delete verification');
    expect(locale.dataVerificationTooltipMessages, {
      'tooltipInfo1': 'The drop-down list option cannot be empty',
      'tooltipInfo2': 'Checkbox content cannot be empty',
      'tooltipInfo3': 'The value entered is not a numeric type',
      'tooltipInfo4': 'The value 2 cannot be less than the value 1',
      'tooltipInfo5': 'The text content cannot be empty',
      'tooltipInfo6': 'The value entered is not a date type',
      'tooltipInfo7': 'Date 2 cannot be less than date 1',
      'textlengthInteger':
          'Text length must be an integer greater than or equal to 0',
    });
  });

  test('toolbar color commands expose opaque swatches', () {
    final expectedColorCommands = {
      ...fortuneToolbarFontColorCommands,
      ...fortuneToolbarBackgroundCommands.where(
        (item) => item != fortuneToolbarBackgroundNoneCommand,
      ),
    };

    expect(fortuneToolbarColorCommands.keys.toSet(), expectedColorCommands);
    for (final entry in fortuneToolbarColorCommands.entries) {
      final alpha = (entry.value.a * 255.0).round().clamp(0, 255);
      expect(alpha, 0xff, reason: entry.key);
    }
  });

  test('toolbar background none is the only no-swatch color command', () {
    final colorSelectableCommands = {
      ...fortuneToolbarFontColorCommands,
      ...fortuneToolbarBackgroundCommands,
    };

    expect(
      colorSelectableCommands.difference(
        fortuneToolbarColorCommands.keys.toSet(),
      ),
      {fortuneToolbarBackgroundNoneCommand},
    );
    expect(
      fortuneToolbarColorCommands.keys.toSet().difference(
        colorSelectableCommands,
      ),
      isEmpty,
    );
  });

  test('toolbar color picker palette exposes valid hex commands', () {
    final hexPattern = RegExp(r'^#[0-9a-f]{6}$');
    final paletteColors = [
      for (final row in fortuneToolbarColorPickerPalette) ...row,
    ];

    expect(fortuneToolbarColorPickerPalette, isNotEmpty);
    expect(fortuneToolbarColorPickerPalette, [
      [
        '#000000',
        '#444444',
        '#666666',
        '#999999',
        '#cccccc',
        '#eeeeee',
        '#f3f3f3',
        '#ffffff',
      ],
      [
        '#f00f00',
        '#f90f90',
        '#ff0ff0',
        '#0f00f0',
        '#0ff0ff',
        '#00f00f',
        '#90f90f',
        '#f0ff0f',
      ],
      [
        '#f4cccc',
        '#fce5cd',
        '#fff2cc',
        '#d9ead3',
        '#d0e0e3',
        '#cfe2f3',
        '#d9d2e9',
        '#ead1dc',
      ],
      [
        '#ea9999',
        '#f9cb9c',
        '#ffe599',
        '#b6d7a8',
        '#a2c4c9',
        '#9fc5e8',
        '#b4a7d6',
        '#d5a6bd',
      ],
      [
        '#e06666',
        '#f6b26b',
        '#ffd966',
        '#93c47d',
        '#76a5af',
        '#6fa8dc',
        '#8e7cc3',
        '#c27ba0',
      ],
      [
        '#c00c00',
        '#e69138',
        '#f1c232',
        '#6aa84f',
        '#45818e',
        '#3d85c6',
        '#674ea7',
        '#a64d79',
      ],
      [
        '#900900',
        '#b45f06',
        '#bf9000',
        '#38761d',
        '#134f5c',
        '#0b5394',
        '#351c75',
        '#741b47',
      ],
      [
        '#600600',
        '#783f04',
        '#7f6000',
        '#274e13',
        '#0c343d',
        '#073763',
        '#20124d',
        '#4c1130',
      ],
    ]);
    expect(paletteColors, isNotEmpty);
    expect(paletteColors.toSet(), hasLength(paletteColors.length));
    for (final row in fortuneToolbarColorPickerPalette) {
      expect(row, hasLength(fortuneToolbarColorPickerPalette.first.length));
      expect(row, isNotEmpty);
      for (final hex in row) {
        expect(hexPattern.hasMatch(hex), isTrue, reason: hex);
        expect(fortuneToolbarHexColor(hex).a, 1.0, reason: hex);
        expect(
          fortuneToolbarFontColorPaletteCommand(hex),
          '$fortuneToolbarFontColorPaletteCommandPrefix$hex',
        );
        expect(
          fortuneToolbarBackgroundPaletteCommand(hex),
          '$fortuneToolbarBackgroundPaletteCommandPrefix$hex',
        );
      }
    }
  });

  test('toolbar border metadata follows border commands', () {
    expect(
      fortuneToolbarBorderPopupCommands.where((item) => item != '|'),
      containsAll(fortuneToolbarBorderCommands),
    );
    expect(fortuneToolbarBorderStyleValues, [1, 2, 3, 4, 5, 6, 8, 9, 10, 11]);
    expect(fortuneToolbarBorderWidthEditableStyles, [8, 9, 10, 11]);
    expect(fortuneToolbarBorderStyleStrokeWidths, {
      1: 1,
      2: 1,
      3: 2,
      4: 2,
      5: 2,
      6: 2,
      8: 2,
      9: 3,
      10: 3,
      11: 3,
    });
    expect(fortuneToolbarBorderStyleDashPatterns, {
      1: [1, 0],
      2: [1, 5],
      3: [2, 5],
      4: [5, 5],
      5: [20, 5, 5, 10, 5, 5],
      6: [20, 5, 5, 5, 5, 10, 5, 5, 5, 5],
      8: [2, 0],
      9: [3, 5],
      10: [20, 5, 5, 10, 5, 5],
      11: [5, 5, 5, 5, 20, 5, 5, 5, 5, 10],
    });
    expect(
      fortuneToolbarBorderStyleStrokeWidths.keys.toSet(),
      fortuneToolbarBorderStyleValues.toSet(),
    );
    expect(
      fortuneToolbarBorderStyleDashPatterns.keys.toSet(),
      fortuneToolbarBorderStyleValues.toSet(),
    );
    expect(
      fortuneToolbarBorderStyleStrokeWidths.values,
      everyElement(greaterThan(0)),
    );
    expect(
      fortuneToolbarBorderStyleDashPatterns.values,
      everyElement(isNotEmpty),
    );
  });

  test('toolbar font size labels match command suffixes', () {
    for (final command in fortuneToolbarFontSizeCommands) {
      final label = fortuneToolbarPopupLabels[command];
      final suffix = command.substring('font-size-'.length);

      expect(label, suffix, reason: command);
      expect(int.parse(suffix), greaterThan(0), reason: command);
    }
  });

  test('toolbar format metadata follows format commands', () {
    expect(fortuneToolbarFormatCommands, [
      fortuneToolbarFormatAutomaticCommand,
      fortuneToolbarFormatPlainTextCommand,
      '|',
      fortuneToolbarFormatNumberCommand,
      fortuneToolbarFormatPercentCommand,
      fortuneToolbarFormatScientificCommand,
      '|',
      fortuneToolbarFormatAccountingCommand,
      fortuneToolbarFormatCurrencyCommand,
      '|',
      fortuneToolbarFormatDateCommand,
      fortuneToolbarFormatTimeCommand,
      fortuneToolbarFormatTime24Command,
      fortuneToolbarFormatDateTimeCommand,
      fortuneToolbarFormatDateTime24Command,
      '|',
      fortuneToolbarFormatMoreCommand,
    ]);
    expect(fortuneToolbarFormatMoreSubmenuCommands, [
      fortuneToolbarFormatMoreCurrencyCommand,
      fortuneToolbarFormatMoreDateTimeCommand,
      fortuneToolbarFormatMoreNumberCommand,
    ]);

    final valueFormatCommands = fortuneToolbarFormatCommands
        .where((item) => item != '|')
        .where((item) => item != fortuneToolbarFormatMoreCommand)
        .toSet();

    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatAutomaticCommand, 'Automatic'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatPlainTextCommand, 'Plain text'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatNumberCommand, 'Number'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatPercentCommand, 'Percent'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatScientificCommand, 'Scientific'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatAccountingCommand, 'Accounting'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatCurrencyCommand, 'Currency'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatDateCommand, 'Date'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatTimeCommand, 'Time'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatTime24Command, 'Time 24H'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatDateTimeCommand, 'Date time'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatDateTime24Command, 'Date time 24 H'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(fortuneToolbarFormatMoreCommand, 'Custom formats'),
    );
    expect(
      fortuneToolbarPopupLabels,
      containsPair(
        fortuneToolbarFormatMoreDateTimeCommand,
        'More date and time formats',
      ),
    );

    expect(fortuneToolbarFormatExamples.keys.toSet(), valueFormatCommands);
    expect(fortuneToolbarFormatValues.keys.toSet(), valueFormatCommands);
    expect(fortuneToolbarFormatValues.values, everyElement(isNotEmpty));
    expect(fortuneToolbarFormatValues, {
      fortuneToolbarFormatAutomaticCommand: 'General',
      fortuneToolbarFormatPlainTextCommand: '@',
      fortuneToolbarFormatNumberCommand: '##0.00',
      fortuneToolbarFormatPercentCommand: '#0.00%',
      fortuneToolbarFormatScientificCommand: '0.00E+00',
      fortuneToolbarFormatAccountingCommand: r'$(0.00)',
      fortuneToolbarFormatCurrencyCommand: r'$0.00',
      fortuneToolbarFormatDateCommand: 'yyyy-MM-dd',
      fortuneToolbarFormatTimeCommand: 'hh:mm AM/PM',
      fortuneToolbarFormatTime24Command: 'hh:mm',
      fortuneToolbarFormatDateTimeCommand: 'yyyy-MM-dd hh:mm AM/PM',
      fortuneToolbarFormatDateTime24Command: 'yyyy-MM-dd hh:mm',
    });
    expect(fortuneToolbarFormatExamples, {
      fortuneToolbarFormatAutomaticCommand: '',
      fortuneToolbarFormatPlainTextCommand: '',
      fortuneToolbarFormatNumberCommand: '1000.12',
      fortuneToolbarFormatPercentCommand: '12.21%',
      fortuneToolbarFormatScientificCommand: '1.01E+5',
      fortuneToolbarFormatAccountingCommand: r'$(1200.09)',
      fortuneToolbarFormatCurrencyCommand: r'$1200.09',
      fortuneToolbarFormatDateCommand: '2017-11-29',
      fortuneToolbarFormatTimeCommand: '3:00 PM',
      fortuneToolbarFormatTime24Command: '15:00',
      fortuneToolbarFormatDateTimeCommand: '2017-11-29 3:00 PM',
      fortuneToolbarFormatDateTime24Command: '2017-11-29 15:00',
    });
  });

  test('format search options expose valid selectable metadata', () {
    final optionLists = <String, List<FortuneFormatSearchOption>>{
      'currency': fortuneFormatSearchCurrencyOptions,
      'dateTime': fortuneFormatSearchDateTimeOptions,
      'number': fortuneFormatSearchNumberOptions,
    };

    expect(
      fortuneFormatSearchOptionsFor(fortuneToolbarFormatMoreCurrencyCommand),
      same(fortuneFormatSearchCurrencyOptions),
    );
    expect(
      fortuneFormatSearchOptionsFor(fortuneToolbarFormatMoreNumberCommand),
      same(fortuneFormatSearchNumberOptions),
    );
    expect(
      fortuneFormatSearchOptionsFor(fortuneToolbarFormatMoreDateTimeCommand),
      same(fortuneFormatSearchDateTimeOptions),
    );

    expect(
      fortuneFormatSearchCurrencyOptions
          .where((item) => item.position == 'after')
          .map((item) => '${item.name}:${item.value}')
          .toList(),
      [
        'Afghani:Af',
        'Paraguayan Guarani:Gs',
        'Belarusian ruble:р',
        'Polish Zloty:z?',
        'Danish Krone:kr',
        'Russian Ruble:?',
        'Czech Koruna:K?',
        'Norwegian Krone:kr',
        'Swedish Krona:kr',
        'Pacific Franc:FCFP',
        'VND:?',
      ],
    );

    expect(
      fortuneFormatSearchNumberOptions
          .map((item) => '${item.name}:${item.value}:${item.position}')
          .toList(),
      ['Volts:V:after', 'Ampere:A:after', 'Ohms:Ω:after'],
    );

    expect(fortuneFormatSearchDateTimeOptions.map((item) => item.name), [
      '1930-08-05',
      '1930/8/5',
      '08-05',
      '8-5',
      '13:30:30',
      '13:30',
      'PM 01:30',
      'PM 1:30',
      'PM 1:30:30',
      '08-05 PM 01:30',
    ]);
    expect(fortuneFormatSearchDateTimeOptions.map((item) => item.value), [
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'MM-dd',
      'M-d',
      'h:mm:ss',
      'h:mm',
      'AM/PM hh:mm',
      'AM/PM h:mm',
      'AM/PM h:mm:ss',
      'MM-dd AM/PM hh:mm',
    ]);
    expect(
      fortuneFormatSearchDateTimeOptions.map((item) => item.position),
      everyElement('before'),
    );

    for (final entry in optionLists.entries) {
      final options = entry.value;
      final invalidNames = options
          .where((option) => option.name.trim().isEmpty)
          .map((option) => option.value)
          .toList();
      final invalidValues = options
          .where((option) => option.value.trim().isEmpty)
          .map((option) => option.name)
          .toList();
      final invalidPositions = options
          .where(
            (option) =>
                option.position != 'before' && option.position != 'after',
          )
          .map((option) => option.name)
          .toList();

      expect(options, isNotEmpty, reason: entry.key);
      expect(invalidNames, isEmpty, reason: '${entry.key} names');
      expect(invalidValues, isEmpty, reason: '${entry.key} values');
      expect(invalidPositions, isEmpty, reason: '${entry.key} positions');
    }
  });

  test('toolbar text combo items have default labels', () {
    expect(
      fortuneToolbarDefaultComboLabels.keys.toSet(),
      fortuneToolbarTextComboItems,
    );
    expect(fortuneToolbarDefaultComboLabels.values, everyElement(isNotEmpty));
  });

  test('all supported toolbar icons draw without throwing', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final iconRect = ui.Rect.fromLTWH(0, 0, 24, 24);

    for (final iconId in FortuneToolbarIconPainter.supportedIconIds) {
      expect(
        () => FortuneToolbarIconPainter.draw(canvas, iconId, iconRect),
        returnsNormally,
        reason: iconId,
      );
    }

    recorder.endRecording().dispose();
  });

  test('unknown toolbar icon ids draw fallback icon without throwing', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(
      () => FortuneToolbarIconPainter.draw(
        canvas,
        'missing-toolbar-command',
        ui.Rect.fromLTWH(0, 0, 24, 24),
      ),
      returnsNormally,
    );

    recorder.endRecording().dispose();
  });
}

Future<int> _currencyIconSignature({required String currency}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  FortuneToolbarIconPainter.draw(
    canvas,
    fortuneToolbarCurrencyFormatCommand,
    ui.Rect.fromLTWH(0, 0, 24, 24),
    currency: currency,
  );
  final image = await recorder.endRecording().toImage(24, 24);
  final signature = await _imageSignature(image);
  image.dispose();
  return signature;
}

Future<int> _toolbarCurrencySignature({required String currency}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final size = ui.Size(420, 80);
  final painter = FortuneSheetPainter(
    workbook: FortuneWorkbook(
      sheets: [FortuneSheet(id: 'sheet1', name: 'Sheet1')],
      settings: FortuneSettings(currency: currency),
    ),
    selection: const FortuneSelection(row: 0, column: 0),
    scrollOffset: Offset.zero,
    sheetTabScrollOffset: 0,
    textDirection: TextDirection.ltr,
  );
  painter.paint(canvas, size);
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final signature = await _imageSignature(image);
  image.dispose();
  return signature;
}

Future<Set<int>> _toolbarIconColors(String iconId) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  FortuneToolbarIconPainter.draw(
    canvas,
    iconId,
    ui.Rect.fromLTWH(0, 0, 24, 24),
  );
  final image = await recorder.endRecording().toImage(24, 24);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  final colors = <int>{};
  for (var index = 0; index < bytes.length; index += 4) {
    final red = bytes[index];
    final green = bytes[index + 1];
    final blue = bytes[index + 2];
    final alpha = bytes[index + 3];
    if (alpha == 0) {
      continue;
    }
    colors.add((alpha << 24) | (red << 16) | (green << 8) | blue);
  }
  return colors;
}

Future<ui.Rect> _toolbarIconBounds(String iconId) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  FortuneToolbarIconPainter.draw(
    canvas,
    iconId,
    ui.Rect.fromLTWH(0, 0, 24, 24),
  );
  final image = await recorder.endRecording().toImage(24, 24);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  var left = 24;
  var top = 24;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < 24; y += 1) {
    for (var x = 0; x < 24; x += 1) {
      final alpha = bytes[(y * 24 + x) * 4 + 3];
      if (alpha == 0) {
        continue;
      }
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) {
    return ui.Rect.zero;
  }
  return ui.Rect.fromLTRB(
    left.toDouble(),
    top.toDouble(),
    right + 1.0,
    bottom + 1.0,
  );
}

Future<int> _imageSignature(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  var hash = 0;
  for (final byte in bytes) {
    hash = 0x3fffffff & ((hash * 31) + byte);
  }
  return hash;
}
