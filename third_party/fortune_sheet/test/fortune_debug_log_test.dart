import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

Offset debugToolbarItemArrowCenter(String key, {double width = 1688}) {
  for (final entry in fortuneVisibleToolbarItemRects(width)) {
    if (entry.key == key) {
      return fortuneToolbarComboArrowRect(entry.value).center;
    }
  }
  fail('toolbar item not found: $key');
}

double debugToolbarPopupLeftForKey(String toolbarKey, {double width = 1688}) {
  ui.Rect? itemRect;
  for (final entry in fortuneVisibleToolbarItemRects(width)) {
    if (entry.key == toolbarKey) {
      itemRect = entry.value;
      break;
    }
  }
  return fortuneToolbarPopupLeftFor(
    key: toolbarKey,
    itemRect: itemRect,
    viewportWidth: width,
    popupWidth: fortuneToolbarPopupWidthFor(toolbarKey),
  );
}

Offset debugToolbarPopupItemCenterForKey({
  required double popupLeft,
  required String toolbarKey,
  required int itemIndex,
}) {
  final options = fortuneToolbarPopupItems[toolbarKey];
  final top =
      fortuneToolbarPopupTop +
      fortuneToolbarPopupContentTopPaddingFor(toolbarKey) +
      fortuneToolbarPopupRowHeightFor(toolbarKey) * itemIndex;
  final itemHeight = options != null && options[itemIndex] == '|'
      ? fortuneToolbarMenuDividerHeight
      : fortuneToolbarPopupRowHeightFor(toolbarKey);
  return Offset(popupLeft + 20, top + itemHeight / 2);
}

StringBuffer captureFortuneDebugLog() {
  final buffer = StringBuffer();
  fortuneSheetDebugLogDebugPrintOverride = (String? message, {int? wrapWidth}) {
    buffer.writeln(message ?? '');
  };
  fortuneSheetDebugLogEnabled = true;
  addTearDown(() {
    fortuneSheetDebugLogEnabled = false;
    fortuneSheetDebugLogDebugPrintOverride = null;
  });
  return buffer;
}

void main() {
  testWidgets('font debug log records merge and duplicate details', (
    tester,
  ) async {
    final logBuffer = captureFortuneDebugLog();

    final workbook = FortuneWorkbook(
      settings: FortuneSettings(
        fontProvider: () async => const [
          'Bahnschrift SemiBold Condensed',
          'Bahnschrift SemiLight SemiCondensed',
          'Roboto Regular',
          'Roboto Bold Italic',
        ],
      ),
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 360,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );
    await tester.pump();

    final log = logBuffer.toString();
    expect(log, contains('font canvas merge'));
    expect(
      log,
      contains(
        'font canvas merge provider=4 previous=4 next=6 collapsed=0 duplicates=0 filtered=2',
      ),
    );
    expect(log, isNot(contains('font canvas collapse')));
    expect(log, isNot(contains('font canvas duplicate')));
    expect(
      log,
      contains('font canvas filtered Bahnschrift SemiBold Condensed'),
    );
    expect(
      log,
      contains('font canvas filtered Bahnschrift SemiLight SemiCondensed'),
    );
    expect(log, contains('font canvas final count=6'));
    expect(
      log,
      contains(
        'font canvas final 1-6=Arial | Tahoma | Times New Roman | Verdana | Roboto Bold Italic | Roboto Regular',
      ),
    );
  });

  testWidgets('active editor debug log records multiline input trace', (
    tester,
  ) async {
    final logBuffer = captureFortuneDebugLog();

    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 640,
                height: 360,
                child: FortuneSheetCanvas(workbook: workbook),
              ),
            ),
          ],
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(83, 100));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    tester.testTextInput.enterText('line1');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();

    final log = logBuffer.toString();
    expect(log, contains('editor multilineEnter'));
    expect(log, contains('editor runImmediateMutation before'));
    expect(log, contains(r'editor insertText text=\n'));
    expect(log, contains('editor setValue userUpdate'));
  });

  testWidgets('active editor does not double-delete after IME update', (
    tester,
  ) async {
    captureFortuneDebugLog();

    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => SizedBox(
                width: 640,
                height: 360,
                child: FortuneSheetCanvas(workbook: workbook),
              ),
            ),
          ],
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(83, 100));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.value = const TextEditingValue(
      text: '간ㄷ',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 1, end: 2),
    );
    await tester.pump();
    editable.controller.value = const TextEditingValue(
      text: '간',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 1, end: 1),
    );
    await tester.pump();
    editable.controller.value = const TextEditingValue(
      text: '간',
      selection: TextSelection.collapsed(offset: 1),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(editable.controller.text, '간');
  });

  testWidgets('active editor debug log records popup copy trace', (
    tester,
  ) async {
    final logBuffer = captureFortuneDebugLog();

    var clipboardText = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboardText = (call.arguments as Map)['text'] as String;
            return null;
          case 'Clipboard.getData':
            return <String, Object?>{'text': clipboardText};
        }
        return null;
      },
    );

    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: 'abcdefghij',
            ),
          },
          columnWidths: const {0: 180},
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 360,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      return tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<FortuneSheetPainter>()
          .single;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(83, 100));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection = const TextSelection(
      baseOffset: 8,
      extentOffset: 2,
    );
    await tester.pump();

    final editableRect = tester.getRect(find.byType(EditableText));
    final gesture = await tester.startGesture(
      Offset(editableRect.left + 30, editableRect.center.dy),
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pump();

    await tester.tapAt(
      topLeft +
          fortuneContextMenuItemCenter(
            painter().contextMenuAt!,
            fortuneContextCopyCommand,
            painter().contextMenuItems,
          ),
    );
    await tester.pump();
    await tester.pump();

    expect(clipboardText, 'cdefgh');
    final log = logBuffer.toString();
    expect(log, contains('editor contextMenu open'));
    expect(log, contains('editor pointerDown'));
    expect(log, contains('editor pointerDown ignored openingPointer'));
    expect(log, contains('keepSelection=true'));
    expect(log, contains('selection=8-2 start=2 end=8'));
    expect(log, contains('editor contextMenu command=copy'));
    expect(log, contains('storedRange=2-8'));
    expect(log, contains('editor contextCopy start'));
    expect(log, contains('editor contextCopy clipboardSet begin'));
    expect(log, contains('selectedText=cdefgh'));
    expect(log, contains('editor contextCopy clipboardSet complete'));
    expect(log, contains('editor contextCopy decision'));
    expect(log, contains('restore=true'));
    expect(log, contains('editor contextCopy closeMenu'));
    expect(log, contains('editor contextCopy restore'));
    expect(log, contains('applied=8-2 start=2 end=8'));
    expect(log, contains('editor contextCopy postFrame'));
  });

  testWidgets('active editor debug log records toolbar font size trace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1688, 600);
    tester.view.devicePixelRatio = 1;
    final logBuffer = captureFortuneDebugLog();
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: 'abcdefghij',
            ),
          },
          columnWidths: const {0: 180},
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 1688,
          height: 360,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    await tester.tapAt(topLeft + const Offset(83, 100));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    editable.controller.selection = const TextSelection(
      baseOffset: 2,
      extentOffset: 7,
    );
    await tester.pump();

    await tester.tapAt(
      topLeft +
          debugToolbarItemArrowCenter(
            fortuneToolbarFontSizePopupKey,
            width: 1688,
          ),
    );
    await tester.pump();
    await tester.tapAt(
      topLeft +
          debugToolbarPopupItemCenterForKey(
            popupLeft: debugToolbarPopupLeftForKey(
              fortuneToolbarFontSizePopupKey,
              width: 1688,
            ),
            toolbarKey: fortuneToolbarFontSizePopupKey,
            itemIndex: fortuneToolbarFontSizeCommands.indexOf(
              fortuneToolbarFontSize11Command,
            ),
          ),
    );
    await tester.pump();

    final log = logBuffer.toString();
    expect(log, contains('editor inlineToolbar remember'));
    expect(log, contains('editor inlineToolbar popupCommand'));
    expect(log, contains('editor inlineToolbar apply begin'));
    expect(log, contains('command=font-size-11 key=fs value=11'));
    expect(log, contains('editor inlineToolbar apply complete'));
    expect(log, contains('runsAfter='));
  });

  testWidgets(
    'active editor debug log records inline line-height input trace',
    (tester) async {
      final logBuffer = captureFortuneDebugLog();

      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Sheet1',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: 'aa\nbb\ncc',
                textWrap: '2',
              ),
            },
            columnWidths: const {0: 180},
            rowHeights: const {0: 96},
          ),
        ],
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 640,
            height: 360,
            child: FortuneSheetCanvas(workbook: workbook),
          ),
        ),
      );

      FortuneSheetPainter painter() {
        return tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((paint) => paint.painter)
            .whereType<FortuneSheetPainter>()
            .single;
      }

      final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
      await tester.tapAt(topLeft + const Offset(83, 100));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      editable.controller.selection = const TextSelection.collapsed(offset: 4);
      await tester.pump();

      final editableRect = tester.getRect(find.byType(EditableText));
      final gesture = await tester.startGesture(
        Offset(editableRect.left + 24, editableRect.center.dy),
        kind: ui.PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pump();

      final lineHeightInput = find.byKey(
        const ValueKey(
          'fortune-context-menu-input-$fortuneEditorContextLineHeightCommand',
        ),
      );
      await tester.tap(lineHeightInput);
      await tester.enterText(lineHeightInput, '1.7');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(painter().contextMenuAt, isNull);
      final log = logBuffer.toString();
      expect(log, contains('editor contextMenu open'));
      expect(
        log,
        contains('editor inlineInput range command=editor-line-height'),
      );
      expect(log, contains('source=collapsedLine'));
      expect(log, contains('range=3-5'));
      expect(
        log,
        contains('editor inlineInput commit begin command=editor-line-height'),
      );
      expect(log, contains('parsed=1.7'));
      expect(
        log,
        contains('editor inlineInput apply begin command=editor-line-height'),
      );
      expect(log, contains('key=lineHeight value=1.7'));
      expect(log, contains('collapsedLine=true'));
      expect(
        log,
        contains(
          'editor inlineInput apply complete command=editor-line-height',
        ),
      );
    },
  );
}
