import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui show PointerDeviceKind, Rect;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_ai_import.dart';
import 'package:label_manager/page_fortune_sheet/fortune_sheet_page.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_import_model.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_open_xml_export.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_fortune_sheet/label_sheet_workbench.dart';

String _encodeLabelSheetSaveArchive({
  required Map<String, Object?> manifest,
  required Map<String, Object?> workbookJson,
}) {
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
    ..addFile(ArchiveFile.string('workbook.json', jsonEncode(workbookJson)));
  return base64Encode(ZipEncoder().encodeBytes(archive));
}

Map<String, Object?> _decodeLabelSheetSaveWorkbookJson(String encoded) {
  final archive = ZipDecoder().decodeBytes(base64Decode(encoded));
  final workbookFile = archive.files.singleWhere(
    (file) => file.name == 'workbook.json',
  );
  return Map<String, Object?>.from(
    jsonDecode(utf8.decode(workbookFile.readBytes()!)) as Map,
  );
}

bool _primaryFocusIsInside(WidgetTester tester, Finder rootFinder) {
  final rootElement = tester.element(rootFinder);
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext is! Element) {
    return false;
  }
  if (focusedContext == rootElement) {
    return true;
  }
  var inside = false;
  focusedContext.visitAncestorElements((ancestor) {
    if (ancestor == rootElement) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('label sheet toolbar starts with save and print actions', () {
    final settings = labelSheetSettings(
      const FortuneSettings(),
      saveTooltip: '저장',
    );
    final items = fortuneToolbarItemsWithCustom(
      settings.toolbarItems,
      settings.customToolbarItems,
    );

    expect(settings.toolbarItems, isNot(contains(fortuneToolbarUndoCommand)));
    expect(settings.toolbarItems, isNot(contains(fortuneToolbarRedoCommand)));
    expect(
      settings.toolbarItems,
      isNot(contains(labelSheetImportImageToolbarCommand)),
    );
    expect(settings.customToolbarItems, hasLength(2));
    expect(settings.customToolbarItems[0].children, isNull);
    expect(settings.customToolbarItems[0].key, labelSheetSaveToolbarCommand);
    expect(settings.customToolbarItems[0].iconName, 'save');
    expect(settings.customToolbarItems[0].tooltip, '저장');
    expect(settings.customToolbarItems[0].disabled, isFalse);
    expect(FortuneToolbarIconPainter.supportedIconIds, contains('save'));
    expect(settings.customToolbarItems[1].key, labelSheetPrintToolbarCommand);
    expect(settings.customToolbarItems[1].iconName, 'print');
    expect(items.take(3), [
      labelSheetSaveToolbarCommand,
      labelSheetPrintToolbarCommand,
      '|',
    ]);
    expect(
      items.where((item) => item == labelSheetPrintToolbarCommand),
      hasLength(1),
    );
    expect(
      items.where((item) => item == labelSheetImportImageToolbarCommand),
      isEmpty,
    );
    expect(
      items.where((item) => item == labelSheetSaveToolbarCommand),
      hasLength(1),
    );
  });

  test('label sheet workbook save payload round trips through base64 zip', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Label',
          rowHeights: const {0: 24},
          columnWidths: const {0: 80},
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '저장',
              extraFields: {'fontScale': 80, 'letterSpacing': 2},
              inlineRuns: [
                FortuneInlineTextRun(
                  text: '저',
                  extraFields: {'script': 'superscript'},
                ),
                FortuneInlineTextRun(
                  text: '장',
                  extraFields: {'lineHeight': 1.5},
                ),
              ],
            ),
          },
          extraFields: const {fortuneSheetGridClientWidthMmKey: 100},
        ),
      ],
    );

    final encoded = labelSheetEncodeWorkbookSave(workbook);
    final decoded = labelSheetDecodeWorkbookSave(encoded);
    final cell = decoded.sheets.single.cells[const FortuneCellCoord(0, 0)]!;

    expect(labelSheetTryDecodeWorkbookSave(encoded), isNotNull);
    expect(decoded.sheets.single.name, 'Label');
    expect(decoded.sheets.single.rowHeights[0], 24);
    expect(decoded.sheets.single.columnWidths[0], 80);
    expect(
      decoded.sheets.single.extraFields[fortuneSheetGridClientWidthMmKey],
      100,
    );
    expect(cell.value, '저장');
    expect(cell.extraFields['fontScale'], 80);
    expect(cell.extraFields['letterSpacing'], 2);
    expect(cell.inlineRuns![0].extraFields['script'], 'superscript');
    expect(cell.inlineRuns![1].extraFields['lineHeight'], 1.5);
  });

  test('label sheet save crops to print area and overflowing content', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Label',
          rowHeights: const {0: 20, 1: 20, 2: 20, 3: 20},
          columnWidths: const {0: 20, 1: 20, 2: 20, 3: 20},
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: 'inside'),
            const FortuneCellCoord(0, 1): const FortuneCell(
              value: 'overflow',
              fontSize: 12,
            ),
            const FortuneCellCoord(0, 4): const FortuneCell(value: 'outside'),
          },
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 10,
            fortuneSheetGridClientHeightMmKey: 10,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.rowCount, 2);
    expect(saved.columnCount, greaterThan(2));
    expect(saved.cells, contains(const FortuneCellCoord(0, 0)));
    expect(saved.cells, contains(const FortuneCellCoord(0, 1)));
    expect(saved.cells, isNot(contains(const FortuneCellCoord(0, 4))));
    expect(saved.rowHeights.keys, everyElement(lessThan(saved.rowCount!)));
    expect(
      saved.columnWidths.keys,
      everyElement(lessThan(saved.columnCount!)),
    );
  });

  test('label sheet save keeps overflow border and image ranges', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Label',
          rowHeights: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
          columnWidths: const {0: 20, 1: 20, 2: 20, 3: 20, 4: 20},
          cells: {
            const FortuneCellCoord(3, 3): const FortuneCell(
              value: 'kept by border',
            ),
            const FortuneCellCoord(4, 4): const FortuneCell(value: 'outside'),
          },
          borderInfo: const [
            FortuneBorderInfo(
              rangeType: 'range',
              borderType: 'border-all',
              color: Color(0xff000000),
              style: 1,
              ranges: [
                FortuneRange(
                  rowStart: 1,
                  rowEnd: 3,
                  columnStart: 1,
                  columnEnd: 3,
                ),
              ],
            ),
          ],
          images: const [
            FortuneImage(
              id: 'barcode-1',
              src: 'data:image/png;base64,AAA=',
              left: 30,
              top: 30,
              width: 45,
              height: 45,
              extraFields: {'kind': 'barcode'},
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 10,
            fortuneSheetGridClientHeightMmKey: 10,
          },
        ),
      ],
    );

    final saved = labelSheetWorkbookForPrintAreaSave(workbook).activeSheet;

    expect(saved.rowCount, 4);
    expect(saved.columnCount, 4);
    expect(saved.borderInfo, hasLength(1));
    expect(saved.borderInfo.single.ranges.single.rowEnd, 3);
    expect(saved.borderInfo.single.ranges.single.columnEnd, 3);
    expect(saved.images.map((image) => image.id), ['barcode-1']);
    expect(saved.cells, contains(const FortuneCellCoord(3, 3)));
    expect(saved.cells, isNot(contains(const FortuneCellCoord(4, 4))));
  });

  test('label sheet save codec loads newer payload best effort', () {
    final workbookJson = FortuneSheetCodec.workbookToJson(
      FortuneWorkbook(
        settings: const FortuneSettings(defaultFontSize: 12),
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Forward',
            rowHeights: const {0: 24},
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '지원',
                inlineRuns: [
                  FortuneInlineTextRun(
                    text: '지원',
                    extraFields: {'letterSpacing': 2.0},
                  ),
                ],
              ),
            },
            extraFields: const {
              fortuneSheetGridClientWidthMmKey: 100,
              'unsupportedSheetFeature': true,
            },
          ),
        ],
        extraFields: const {'unsupportedWorkbookFeature': true},
      ),
    );
    final sheetJson = (workbookJson['data'] as List).single as Map;
    sheetJson['futureSheetField'] = 'drop';
    (sheetJson['config'] as Map)['futureConfigField'] = 'drop';
    final cellJson =
        ((sheetJson['celldata'] as List).single as Map)['v'] as Map;
    cellJson['futureCellField'] = 'drop';
    final cellTypeJson = cellJson['ct'] as Map;
    cellTypeJson['futureCellTypeField'] = 'drop';
    ((cellTypeJson['s'] as List).single as Map)['futureInlineRunField'] =
        'drop';

    final encoded = _encodeLabelSheetSaveArchive(
      manifest: {
        'format': labelSheetSaveFormat,
        'version': labelSheetSaveFormatVersion + 100,
        'features': {
          ...labelSheetSaveFeatureVersions,
          'future.feature': labelSheetSaveFormatVersion + 100,
        },
        'encoding': 'base64',
        'compression': 'zip-deflate',
        'codec': 'fortune-sheet-json',
      },
      workbookJson: Map<String, Object?>.from(workbookJson),
    );

    final decoded = labelSheetDecodeWorkbookSave(encoded);
    final decodedSheet = decoded.sheets.single;
    final decodedCell = decodedSheet.cells[const FortuneCellCoord(0, 0)]!;

    expect(decoded.settings.defaultFontSize, 12);
    expect(decodedSheet.name, 'Forward');
    expect(decodedSheet.rowHeights[0], 24);
    expect(decodedSheet.extraFields[fortuneSheetGridClientWidthMmKey], 100);
    expect(
      decoded.extraFields.containsKey('unsupportedWorkbookFeature'),
      isFalse,
    );
    expect(
      decodedSheet.extraFields.containsKey('unsupportedSheetFeature'),
      isFalse,
    );
    expect(decodedSheet.extraFields.containsKey('futureSheetField'), isFalse);
    expect(
      decodedSheet.configExtraFields.containsKey('futureConfigField'),
      isFalse,
    );
    expect(decodedCell.extraFields.containsKey('futureCellField'), isFalse);
    expect(
      decodedCell.cellType?.extraFields.containsKey('futureCellTypeField'),
      isFalse,
    );
    expect(decodedCell.inlineRuns!.single.extraFields['letterSpacing'], 2.0);
    expect(
      decodedCell.inlineRuns!.single.extraFields.containsKey(
        'futureInlineRunField',
      ),
      isFalse,
    );

    final resavedJson = _decodeLabelSheetSaveWorkbookJson(
      labelSheetEncodeWorkbookSave(decoded),
    );
    final resavedSheet = (resavedJson['data'] as List).single as Map;
    final resavedCell =
        ((resavedSheet['celldata'] as List).single as Map)['v'] as Map;
    final resavedRun = ((resavedCell['ct'] as Map)['s'] as List).single as Map;
    expect(resavedJson.containsKey('unsupportedWorkbookFeature'), isFalse);
    expect(resavedSheet.containsKey('futureSheetField'), isFalse);
    expect(resavedCell.containsKey('futureCellField'), isFalse);
    expect(resavedRun.containsKey('futureInlineRunField'), isFalse);
  });

  test('label image import clears sheet before applying draft', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      rowCount: 30,
      columnCount: 12,
      rowHeights: const {10: 40},
      columnWidths: const {6: 90},
      cells: {const FortuneCellCoord(10, 6): const FortuneCell(value: 'old')},
      images: const [
        FortuneImage(
          id: 'old-image',
          src: 'old',
          left: 0,
          top: 0,
          width: 10,
          height: 10,
        ),
      ],
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        'labelRtfImportSource': true,
      },
    );
    final draft = LabelSheetImageImportDraft(
      imageWidth: 100,
      imageHeight: 60,
      rowLines: <int>[],
      columnLines: <int>[],
      rowHeights: const {0: 20},
      columnWidths: const {0: 50},
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'new')},
      images: const <FortuneImage>[],
    );

    final cleared = labelSheetClearBeforeImageImport(
      sheet,
      rowCount: 20,
      columnCount: 8,
    );
    final imported = labelSheetApplyImageImportDraft(
      cleared,
      draft,
      minRowCount: 20,
      minColumnCount: 8,
    );

    expect(imported.rowCount, 20);
    expect(imported.columnCount, 8);
    expect(imported.rowHeights, {0: 20});
    expect(imported.columnWidths, {0: 50});
    expect(imported.cells.keys, [const FortuneCellCoord(0, 0)]);
    expect(imported.cells[const FortuneCellCoord(0, 0)]!.value, 'new');
    expect(imported.images, isEmpty);
    expect(imported.borderInfo, isEmpty);
    expect(imported.extraFields[fortuneSheetGridClientWidthMmKey], 100);
    expect(imported.extraFields.containsKey('labelRtfImportSource'), isFalse);
  });

  testWidgets('label sheet save button emits encoded workbook payload', (
    tester,
  ) async {
    String? savedPayload;
    int? savedWidth;
    int? savedHeight;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 300,
          child: LabelSheetWorkbench(
            initialWorkbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Label',
                  cells: {
                    const FortuneCellCoord(0, 0): const FortuneCell(
                      value: '저장',
                    ),
                  },
                ),
              ],
            ),
            onSave: (width, height, payload) {
              savedWidth = width;
              savedHeight = height;
              savedPayload = payload;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    var sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    var saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(saveItem.disabled, isTrue);
    sheetApp.onChange!(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Label',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '수정'),
            },
          ),
        ],
      ),
    );
    sheetApp.onOp!(const [
      {'type': 'test'},
    ]);
    await tester.pump();

    sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(saveItem.disabled, isFalse);
    saveItem.onClick!(saveItem);
    await tester.pump();
    await tester.pump();

    expect(savedPayload, isNotNull);
  expect(savedWidth, 100);
  expect(savedHeight, 100);
    final decoded = labelSheetDecodeWorkbookSave(savedPayload!);
    expect(
      decoded.sheets.single.cells[const FortuneCellCoord(0, 0)]!.value,
      '저장',
    );
    sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(saveItem.disabled, isTrue);
  });

  testWidgets('label sheet save button stays enabled when save fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
              onSave: (_, _, _) async {
                throw StateError('save failed');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    var sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    sheetApp.onOp!(const [
      {'type': 'test'},
    ]);
    await tester.pump();

    sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    var saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(saveItem.disabled, isFalse);

    saveItem.onClick!(saveItem);
    await tester.pump();

    saveItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetSaveToolbarCommand);
    expect(saveItem.disabled, isFalse);
  });

  testWidgets('label sheet print button opens printer settings dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 360,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsNothing,
    );

    final printItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetPrintToolbarCommand);
    printItem.onClick!(printItem);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );
    expect(find.text('프린터 설정'), findsOneWidget);
    expect(find.text('프린터 선택'), findsOneWidget);
    expect(find.text('발행'), findsOneWidget);
    expect(find.text('적용'), findsOneWidget);
    expect(find.text('닫기'), findsOneWidget);
    expect(find.text('%'), findsWidgets);
    expect(find.text('간격조정 없음'), findsOneWidget);

    await tester.tap(find.text('간격조정 없음'));
    await tester.pumpAndSettle();

    expect(find.text('80'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('300'),
      100,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('300'), findsOneWidget);
    await tester.tap(find.text('300'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('닫기'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsNothing,
    );
  });

  testWidgets('label sheet print dialog waits for lifecycle callback', (
    tester,
  ) async {
    final beforeCompleter = Completer<void>();
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 360,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
              onBeforePrintSettingsDialog: () {
                events.add('before');
                return beforeCompleter.future;
              },
              onPrintSettingsDialogClosed: () {
                events.add('closed');
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final printItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetPrintToolbarCommand);
    printItem.onClick!(printItem);
    await tester.pump();

    expect(events, ['before']);
    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsNothing,
    );

    beforeCompleter.complete();
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('닫기'));
    await tester.pump();

    expect(events, ['before', 'closed']);
  });

  testWidgets('label sheet print dialog traps tab focus inside dialog', (
    tester,
  ) async {
    final beforeFocusNode = FocusNode();
    final afterFocusNode = FocusNode();
    addTearDown(beforeFocusNode.dispose);
    addTearDown(afterFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: beforeFocusNode),
              Expanded(
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [FortuneSheet(id: 's1', name: 'Label')],
                  ),
                ),
              ),
              TextField(focusNode: afterFocusNode),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final printItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetPrintToolbarCommand);
    printItem.onClick!(printItem);
    await tester.pump();

    final dialogFinder = find.byKey(
      const ValueKey('label-sheet-print-settings-dialog'),
    );
    expect(dialogFinder, findsOneWidget);

    await tester.tap(
      find.descendant(of: dialogFinder, matching: find.byType(TextField)).last,
    );
    await tester.pump();
    expect(_primaryFocusIsInside(tester, dialogFinder), isTrue);

    for (var index = 0; index < 10; index += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_primaryFocusIsInside(tester, dialogFinder), isTrue);
      expect(beforeFocusNode.hasFocus, isFalse);
      expect(afterFocusNode.hasFocus, isFalse);
    }

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    for (var index = 0; index < 10; index += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_primaryFocusIsInside(tester, dialogFinder), isTrue);
      expect(beforeFocusNode.hasFocus, isFalse);
      expect(afterFocusNode.hasFocus, isFalse);
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  });

  testWidgets('label sheet save button is disabled after clear sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [
                  FortuneSheet(
                    id: 's1',
                    name: 'Label',
                    cells: {
                      const FortuneCellCoord(0, 0): const FortuneCell(
                        value: 'clear me',
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    var sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    sheetApp.onOp!(const [
      {'type': 'test'},
    ]);
    await tester.pump();

    sheetApp = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    var saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(saveItem.disabled, isFalse);

    sheetApp.controller!.clearSheet();
    await tester.pump();

    saveItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetSaveToolbarCommand);
    expect(saveItem.disabled, isTrue);
  });

  testWidgets('label sheet zoom toolbar controls active sheet zoom', (
    tester,
  ) async {
    String? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 320,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
              onSave: (_, _, payload) {
                savedPayload = payload;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final zoomInput = find.byKey(const ValueKey('label-sheet-zoom-input'));
    expect(zoomInput, findsOneWidget);
    final initialZoomInput = tester.widget<EditableText>(zoomInput);
    expect(initialZoomInput.cursorOffset, Offset.zero);
    final zoomRow = tester.widget<Row>(
      find.ancestor(of: find.text('%'), matching: find.byType(Row)).first,
    );
    final percentIndex = zoomRow.children.indexWhere(
      (child) => child is Text && child.data == '%',
    );
    expect(percentIndex, greaterThan(0));
    expect(zoomRow.children[percentIndex - 1], isA<SizedBox>());
    expect((zoomRow.children[percentIndex - 1] as SizedBox).width, 2);
    expect(initialZoomInput.controller.text, '$labelSheetDefaultZoomPercent');

    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '110');

    await tester.tap(find.text('-'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '100');

    await tester.enterText(zoomInput, '150abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');

    await tester.enterText(zoomInput, '130');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');

    await tester.enterText(zoomInput, '170');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.onOp!(const [
      {'type': 'test'},
    ]);
    await tester.pump();
    final saveItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetSaveToolbarCommand);
    saveItem.onClick!(saveItem);
    await tester.pump();

    expect(savedPayload, isNotNull);
    final decoded = labelSheetDecodeWorkbookSave(savedPayload!);
    expect(decoded.sheets.single.zoomRatio, 1.5);
  });

  testWidgets('fortune sheet page loads base64 save payload from label RTF', (
    tester,
  ) async {
    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Saved Label',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '복원'),
            },
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 300,
          child: FortuneSheetPage(
            labelSize: LabelSize(
              labelSizeId: 1,
              brandId: 1,
              labelSizeName: 'Saved',
              labelSizeCommon: LabelSizeCommon(
                width: 100,
                height: 60,
                rtf: encoded,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final workbook = sheetApp.workbook!;
    expect(workbook.sheets.single.name, 'Saved');
    expect(
      workbook.sheets.single.cells[const FortuneCellCoord(0, 0)]!.value,
      '복원',
    );
  });

  test('GitHub Copilot Chat model menu includes additional model choices', () {
    final modelIds = labelSheetCopilotModels
        .map((model) => model.modelId)
        .toSet();

    expect(modelIds, contains('openai/gpt-4.1'));
    expect(modelIds, contains('openai/gpt-4.1-mini'));
    expect(modelIds, contains('openai/gpt-4.1-nano'));
    expect(modelIds, contains('openai/gpt-4o'));
    expect(modelIds, contains('openai/gpt-4o-mini'));
    expect(modelIds, contains('openai/o4-mini'));
    expect(modelIds, contains('openai/o3'));
  });

  test('label sheet image import analysis creates an adjusted draft', () {
    final image = imglib.Image(width: 100, height: 60);
    imglib.fill(image, color: imglib.ColorRgb8(255, 255, 255));
    for (final x in [0, 20, 80, 99]) {
      imglib.drawLine(
        image,
        x1: x,
        y1: 0,
        x2: x,
        y2: 59,
        color: imglib.ColorRgb8(0, 0, 0),
      );
    }
    for (final y in [0, 25, 59]) {
      imglib.drawLine(
        image,
        x1: 0,
        y1: y,
        x2: 99,
        y2: y,
        color: imglib.ColorRgb8(0, 0, 0),
      );
    }
    final bytes = Uint8List.fromList(imglib.encodePng(image));
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = labelSheetAnalyzeImageImport(
      bytes,
      sheet: sheet,
      mimeType: 'image/png',
      fileName: 'label.png',
    );

    expect(draft, isNotNull);
    expect(draft!.columnWidths, hasLength(3));
    expect(draft.rowHeights, hasLength(2));
    expect(draft.imageWidth, 100);
    expect(draft.imageHeight, 60);
    expect(draft.images, isEmpty);

    final imported = labelSheetApplyImageImportDraft(sheet, draft);
    expect(imported.columnCount, 3);
    expect(imported.rowCount, 2);
    expect(imported.images, isEmpty);
    expect(imported.cells, isEmpty);
  });

  test(
    'label sheet import draft preserves remaining sheet rows and columns',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        rowCount: 30,
        columnCount: 12,
        rowHeights: {20: 44},
        columnWidths: {8: 88},
      );
      const draft = LabelSheetImageImportDraft(
        imageWidth: 100,
        imageHeight: 40,
        rowLines: <int>[],
        columnLines: <int>[],
        rowHeights: {0: 20, 1: 20},
        columnWidths: {0: 50, 1: 50},
        images: <FortuneImage>[],
      );

      final imported = labelSheetApplyImageImportDraft(sheet, draft);

      expect(imported.rowCount, 30);
      expect(imported.columnCount, 12);
      expect(imported.rowHeights[0], 20);
      expect(imported.rowHeights[20], 44);
      expect(imported.columnWidths[0], 50);
      expect(imported.columnWidths[8], 88);
    },
  );

  test('label sheet draft is written as an Open XML test workbook', () async {
    final path = '.tmp/label_sheet_open_xml_export_test.xlsx';
    final draft = LabelSheetImageImportDraft(
      imageWidth: 100,
      imageHeight: 40,
      rowLines: const <int>[],
      columnLines: const <int>[],
      rowHeights: const {0: 20, 1: 20},
      columnWidths: const {0: 50, 1: 50},
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '첫째 & 둘째',
          merge: FortuneCellMerge(row: 0, column: 0, columnSpan: 2),
          fontFamily: 'Courier New',
          fontSize: 14,
          bold: true,
          italic: true,
          underline: true,
          strikeThrough: true,
          foreground: Color(0xffff0000),
          background: Color(0xff00ff00),
          horizontalAlign: 'center',
          verticalAlign: 'middle',
          textWrap: 'wrap',
          extraFields: {'fontScale': 80, 'letterSpacing': 2, 'lineHeight': 1.5},
          inlineRuns: [
            FortuneInlineTextRun(
              text: '첫째 ',
              fontFamily: 'Courier New',
              fontSize: 14,
              bold: true,
              foreground: Color(0xffff0000),
              extraFields: {
                'fontScale': 80,
                'letterSpacing': 2,
                'lineHeight': 1.5,
              },
            ),
            FortuneInlineTextRun(
              text: '& 둘째',
              fontSize: 8,
              foreground: Color(0xff0000ff),
              extraFields: {'script': 'superscript'},
            ),
          ],
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(value: 'RTF 변환'),
      },
      images: const <FortuneImage>[],
    );

    final file = await labelSheetWriteDraftOpenXmlTestFile(draft, path: path);
    addTearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });

    expect(file.path, path);
    expect(await file.length(), greaterThan(0));

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    expect(archive.findFile('xl/workbook.xml'), isNotNull);
    final worksheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(worksheet, isNotNull);

    final worksheetXml = utf8.decode(worksheet!.content);
    expect(worksheetXml, contains('<dimension ref="A1:B2"/>'));
    expect(worksheetXml, contains('<c r="B1" s="1"/>'));
    expect(worksheetXml, contains('첫째 '));
    expect(worksheetXml, contains('&amp; 둘째'));
    expect(worksheetXml, contains('<rPr><b/><sz val="14.00"/>'));
    expect(worksheetXml, contains('<color rgb="FFFF0000"/>'));
    expect(worksheetXml, contains('<rFont val="Courier New"/>'));
    expect(worksheetXml, contains('<vertAlign val="superscript"/>'));
    expect(worksheetXml, contains('RTF 변환'));
    expect(
      worksheetXml,
      contains('<mergeCells count="1"><mergeCell ref="A1:B1"/></mergeCells>'),
    );

    final styles = archive.findFile('xl/styles.xml');
    expect(styles, isNotNull);
    final stylesXml = utf8.decode(styles!.content);
    expect(stylesXml, contains('<borders count="2">'));
    expect(stylesXml, contains('borderId="1"'));
    expect(stylesXml, contains('<b/><i/><strike/><u/>'));
    expect(stylesXml, contains('<sz val="14.00"/>'));
    expect(stylesXml, contains('<color rgb="FFFF0000"/>'));
    expect(stylesXml, contains('<name val="Courier New"/>'));
    expect(stylesXml, contains('<fgColor rgb="FF00FF00"/>'));
    expect(stylesXml, contains('horizontal="center" vertical="center"'));

    final metadata = archive.findFile('customXml/item1.xml');
    expect(metadata, isNotNull);
    final metadataXml = utf8.decode(metadata!.content);
    expect(metadataXml, contains('<labelSheetRtfMetadata'));
    expect(metadataXml, contains('ref="A1"'));
    expect(metadataXml, contains('fontScale="80.00"'));
    expect(metadataXml, contains('letterSpacing="2.00"'));
    expect(metadataXml, contains('lineHeight="1.50"'));
    expect(metadataXml, contains('script="superscript"'));
  });

  test('RichEdit RTF is written through direct Open XML conversion', () async {
    final path = '.tmp/label_sheet_rtf_open_xml_export_test.xlsx';
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final file = await labelSheetWriteRichEditRtfOpenXmlTestFile(
      r'{\rtf1\ansi\deff0{\colortbl;\red255\green0\blue0;}'
      r'\trowd\trrh1200'
      r'\trbrdrl\brdrs\brdrw20\brdrcf1'
      r'\trbrdrt\brdrs\brdrw20\brdrcf1'
      r'\trbrdrr\brdrs\brdrw20\brdrcf1'
      r'\trbrdrb\brdrs\brdrw20\brdrcf1'
      r'\cellx2000\pard\intbl Alpha\cell\row}',
      sheet: sheet,
      path: path,
    );
    addTearDown(() async {
      if (file != null && await file.exists()) {
        await file.delete();
      }
    });

    expect(file, isNotNull);
    final archive = ZipDecoder().decodeBytes(await file!.readAsBytes());
    final worksheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(worksheet, isNotNull);
    final worksheetXml = utf8.decode(worksheet!.content);
    expect(worksheetXml, contains('<c r="A1" t="inlineStr" s="2">'));
    expect(worksheetXml, contains('Alpha'));

    final styles = archive.findFile('xl/styles.xml');
    expect(styles, isNotNull);
    final stylesXml = utf8.decode(styles!.content);
    expect(stylesXml, contains('<borders count="3">'));
    expect(
      stylesXml,
      contains('<left style="medium"><color rgb="FFFF0000"/></left>'),
    );
    expect(
      stylesXml,
      contains('<right style="medium"><color rgb="FFFF0000"/></right>'),
    );
    expect(stylesXml, contains('borderId="2"'));
  });

  test('RichEdit RTF Open XML conversion prefers native bridge', () async {
    final path = '.tmp/label_sheet_rtf_native_open_xml_test.xlsx';
    final file = File(path);
    await file.parent.create(recursive: true);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
      if (await file.exists()) {
        await file.delete();
      }
    });

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          calls.add(call);
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          expect(arguments['path'], path);
          expect(arguments['rtf'], contains(r'\rtf1'));
          expect(arguments['widthMm'], 100);
          expect(arguments['heightMm'], 60);
          await file.writeAsBytes(<int>[1, 2, 3], flush: true);
          return <String, Object?>{'ok': true, 'path': path};
        });

    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final result = await labelSheetWriteRichEditRtfOpenXmlTestFile(
      r'{\rtf1\ansi\deff0\pard Native\par}',
      sheet: sheet,
      path: path,
    );

    expect(result?.path, path);
    expect(await result!.readAsBytes(), <int>[1, 2, 3]);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'writeRtfOpenXml');
  });

  test('RichEdit RTF preview capture uses native bridge', () async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          calls.add(call);
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          expect(arguments['rtf'], contains(r'\rtf1'));
          expect(arguments['width'], 2);
          expect(arguments['height'], 1);
          expect(arguments['widthMm'], 100);
          expect(arguments['heightMm'], 100);
          expect(arguments['renderScale'], 2.5);
          return <String, Object?>{
            'ok': true,
            'width': 2,
            'height': 1,
            'rgba': Uint8List.fromList(<int>[255, 0, 0, 255, 0, 255, 0, 255]),
          };
        });

    final capture = await labelSheetCaptureRtfNativeImage(
      r'{\rtf1\ansi Preview\par}',
      width: 2,
      height: 1,
      renderScale: 2.5,
    );

    expect(capture, isNotNull);
    expect(capture!.width, 2);
    expect(capture.height, 1);
    expect(capture.rgba, hasLength(8));
    expect(calls.single.method, 'captureRtfImage');
  });

  test('RichEdit RTF preview PNG capture preserves render scale', () async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          expect(arguments['renderScale'], 2.0);
          return <String, Object?>{
            'ok': true,
            'width': 1,
            'height': 1,
            'rgba': Uint8List.fromList(<int>[0, 0, 0, 255]),
          };
        });

    final capture = await labelSheetCaptureRtfNativePngImage(
      r'{\rtf1\ansi Preview\par}',
      width: 1,
      height: 1,
      renderScale: 2.0,
    );

    expect(capture, isNotNull);
    expect(capture!.scale, 2.0);
    expect(capture.bytes, isNotEmpty);
  });

  testWidgets('RichEdit RTF preview recaptures when target size changes', (
    tester,
  ) async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    final sizes = <Size>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          sizes.add(
            Size(
              (arguments['width'] as int).toDouble(),
              (arguments['height'] as int).toDouble(),
            ),
          );
          return <String, Object?>{
            'ok': true,
            'width': arguments['width'],
            'height': arguments['height'],
            'rgba': Uint8List(
              (arguments['width'] as int) * (arguments['height'] as int) * 4,
            ),
          };
        });

    await tester.pumpWidget(
      const MaterialApp(
        home: LabelSheetRtfPreview(
          rtf: r'{\rtf1\ansi\deff0{\fonttbl{\f0 Gulim;}}\pard Preview\par}',
          width: 100,
          height: 50,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const MaterialApp(
        home: LabelSheetRtfPreview(
          rtf: r'{\rtf1\ansi\deff0{\fonttbl{\f0 Gulim;}}\pard Preview\par}',
          width: 140,
          height: 70,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(sizes, contains(const Size(500, 150)));
    expect(sizes, contains(const Size(700, 210)));
  });

  testWidgets('RichEdit RTF preview resolves trimmed content size', (
    tester,
  ) async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    final resolvedSizes = <Size>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          final width = arguments['width'] as int;
          final height = arguments['height'] as int;
          final rgba = Uint8List(width * height * 4);
          for (var index = 0; index < width * height; index++) {
            final offset = index * 4;
            rgba[offset] = 255;
            rgba[offset + 1] = 255;
            rgba[offset + 2] = 255;
            rgba[offset + 3] = 255;
          }
          for (var y = 2; y < 8; y++) {
            for (var x = 2; x < 8; x++) {
              final offset = (y * width + x) * 4;
              rgba[offset] = 0;
              rgba[offset + 1] = 0;
              rgba[offset + 2] = 0;
            }
          }
          return <String, Object?>{
            'ok': true,
            'width': width,
            'height': height,
            'rgba': rgba,
          };
        });

    await tester.pumpWidget(
      MaterialApp(
        home: LabelSheetRtfPreview(
          rtf: r'{\rtf1\ansi\deff0{\fonttbl{\f0 Gulim;}}\pard Preview\par}',
          width: 100,
          height: 50,
          onImageSizeResolved: resolvedSizes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolvedSizes, contains(const Size(6, 6)));
  });

  test('RichEdit RTF preview derives 100 percent pixels from millimeters', () {
    expect(LabelSheetRtfPreview.pixelsForMm(80), 454);
    expect(LabelSheetRtfPreview.pixelsForMm(60), 340);
  });

  test('RichEdit RTF preview capture trims outer whitespace', () async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    final rgba = Uint8List(20 * 20 * 4);
    for (var index = 0; index < 20 * 20; index++) {
      final offset = index * 4;
      rgba[offset] = 255;
      rgba[offset + 1] = 255;
      rgba[offset + 2] = 255;
      rgba[offset + 3] = 255;
    }
    for (var y = 10; y <= 11; y++) {
      for (var x = 10; x <= 11; x++) {
        final offset = (y * 20 + x) * 4;
        rgba[offset] = 0;
        rgba[offset + 1] = 0;
        rgba[offset + 2] = 0;
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          return <String, Object?>{
            'ok': true,
            'width': 20,
            'height': 20,
            'rgba': rgba,
          };
        });

    final capture = await labelSheetCaptureRtfNativeImage(
      r'{\rtf1\ansi Preview\par}',
      width: 20,
      height: 20,
    );

    expect(capture, isNotNull);
    expect(capture!.width, 10);
    expect(capture.height, 10);
  });

  testWidgets('floating preview shows configured tooltip after hover delay', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      tooltip: 'floating tooltip',
      child: const SizedBox.square(
        key: ValueKey('floating-child'),
        dimension: 80,
      ),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final gesture = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('floating-child'))),
    );
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.text('floating tooltip'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('floating tooltip'), findsOneWidget);
    final childCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-child')),
    );
    final tooltipTopLeft = tester.getTopLeft(find.text('floating tooltip'));
    expect(tooltipTopLeft.dx, closeTo(childCenter.dx + 18, 1));
    expect(tooltipTopLeft.dy, closeTo(childCenter.dy + 17, 1));
    final tooltipText = tester.widget<Text>(find.text('floating tooltip'));
    expect(tooltipText.style?.fontWeight, FontWeight.normal);
    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.text('floating tooltip'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('floating tooltip'), findsNothing);
  });

  testWidgets('floating preview aligns bottom-right to target point', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  window.show(context);
                  window.alignBottomRightTo(context, const Offset(700, 500));
                },
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(window.rect.right, 700);
    expect(window.rect.bottom, 500);
  });

  testWidgets('floating preview resize handle resizes without moving window', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      tooltip: 'floating tooltip',
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final beforeTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('floating-child')),
    );
    final beforeSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );
    final gesture = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('floating-child'))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('floating tooltip'), findsOneWidget);
    final handle = find.byKey(const ValueKey('floating-resize-bottom-right'));
    await tester.drag(handle, const Offset(30, 20));
    await tester.pump();

    expect(find.text('floating tooltip'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-child'))),
      beforeTopLeft,
    );
    final afterSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );
    expect(afterSize.width, greaterThan(beforeSize.width));
    expect(afterSize.height, greaterThan(beforeSize.height));
  });

  testWidgets('floating preview corner resize grows both axes from one axis', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final beforeTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('floating-child')),
    );
    final beforeSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );

    final handle = find.byKey(const ValueKey('floating-resize-bottom-right'));
    await tester.drag(handle, const Offset(0, 40));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-child'))),
      beforeTopLeft,
    );
    final afterSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );
    expect(afterSize.width, greaterThan(beforeSize.width));
    expect(afterSize.height, greaterThan(beforeSize.height));
  });

  testWidgets('floating preview top corner resize keeps origin fixed', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final beforeTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('floating-child')),
    );
    final beforeSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );

    final handle = find.byKey(const ValueKey('floating-resize-top-right'));
    await tester.drag(handle, const Offset(20, -40));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-child'))),
      beforeTopLeft,
    );
    final afterSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );
    expect(afterSize.width, greaterThan(beforeSize.width));
    expect(afterSize.height, greaterThan(beforeSize.height));
  });

  testWidgets('floating preview top corner can expand and shrink', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final beforeTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('floating-child')),
    );
    final beforeSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );

    final handle = find.byKey(const ValueKey('floating-resize-top-right'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(25, -56));
    await tester.pump();
    final expandedSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );

    await gesture.moveBy(const Offset(-48, 32));
    await tester.pump();
    final returnedSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );

    await gesture.moveBy(const Offset(-109, 0));
    await tester.pump();
    final crossedSize = tester.getSize(
      find.byKey(const ValueKey('floating-child')),
    );
    await gesture.up();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('floating-child'))),
      beforeTopLeft,
    );
    expect(expandedSize.width, greaterThan(beforeSize.width));
    expect(expandedSize.height, greaterThan(beforeSize.height));
    expect(returnedSize.width, lessThan(expandedSize.width));
    expect(returnedSize.height, lessThan(expandedSize.height));
    expect(crossedSize.width, returnedSize.width);
    expect(crossedSize.height, returnedSize.height);
  });

  testWidgets('floating preview hides move and grip handles during resize', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-move-handle')), findsOneWidget);
    final cornerGripPainters = find.descendant(
      of: find.byKey(const ValueKey('floating-resize-top-right')),
      matching: find.byType(CustomPaint),
    );
    expect(cornerGripPainters, findsOneWidget);

    final handle = find.byKey(const ValueKey('floating-resize-top-right'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-move-handle')), findsNothing);
    expect(cornerGripPainters, findsNothing);

    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-move-handle')), findsOneWidget);
    expect(cornerGripPainters, findsOneWidget);
  });

  testWidgets('floating preview move handle returns to center after resize', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    final handle = find.byKey(const ValueKey('floating-resize-bottom-right'));
    await tester.drag(handle, const Offset(120, 80));
    await tester.pump();

    final childCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-child')),
    );
    final moveHandleCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-move-handle')),
    );
    expect(moveHandleCenter.dx, moreOrLessEquals(childCenter.dx));
  });

  testWidgets('floating preview reports rect changes and resize completion', (
    tester,
  ) async {
    final rectChanges = <ui.Rect>[];
    final resizeStates = <bool>[];
    ui.Rect? completedRect;
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
      onRectChanged: (ui.Rect rect, {required bool isResizing}) {
        rectChanges.add(rect);
        resizeStates.add(isResizing);
      },
      onResizeCompleted: (ui.Rect rect) {
        completedRect = rect;
      },
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    final handle = find.byKey(const ValueKey('floating-resize-bottom-right'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(rectChanges, isNotEmpty);
    expect(resizeStates.any((isResizing) => isResizing), isTrue);
    expect(resizeStates.last, isFalse);
    expect(completedRect, isNotNull);
    expect(completedRect!.width, window.rect.width);
    expect(completedRect!.height, window.rect.height);
  });

  testWidgets('floating preview expands visual card for intrinsic child', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const Center(
        child: SizedBox(
          key: ValueKey('intrinsic-preview-content'),
          width: 40,
          height: 30,
        ),
      ),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    final beforeMaterialSize = tester.getSize(find.byType(Material).last);
    final handle = find.byKey(const ValueKey('floating-resize-bottom-right'));
    await tester.drag(handle, const Offset(120, 80));
    await tester.pump();

    final afterMaterialSize = tester.getSize(find.byType(Material).last);
    final materialCenter = tester.getCenter(find.byType(Material).last);
    final moveHandleCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-move-handle')),
    );

    expect(afterMaterialSize.width, greaterThan(beforeMaterialSize.width));
    expect(afterMaterialSize.height, greaterThan(beforeMaterialSize.height));
    expect(moveHandleCenter.dx, moreOrLessEquals(materialCenter.dx));
  });

  testWidgets('floating preview uses grey outline without changing shadow', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    final cardContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Material).last,
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = cardContainer.decoration as BoxDecoration;
    final border = decoration.border as Border;
    expect(border.top.color, Colors.grey);
    expect(decoration.boxShadow?.single.color, const Color(0x18000000));
  });

  testWidgets('floating preview shows corner resize grips on hover', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
    );
    addTearDown(window.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => window.show(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    final cornerGripPainters = find.descendant(
      of: find.byKey(const ValueKey('floating-resize-bottom-right')),
      matching: find.byType(CustomPaint),
    );
    expect(cornerGripPainters, findsOneWidget);
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: cornerGripPainters,
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);

    final gesture = await tester.createGesture(
      kind: ui.PointerDeviceKind.mouse,
    );
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(
        find.byKey(const ValueKey('floating-resize-bottom-right')),
      ),
    );
    await tester.pump();

    final hoveredOpacity = tester.widget<AnimatedOpacity>(
      find.ancestor(
        of: cornerGripPainters,
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(hoveredOpacity.opacity, 1);
  });

  test('RTF preview does not capture saved sheet payloads', () async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });

    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          calls.add(call);
          return <String, Object?>{'ok': false};
        });

    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Label')],
    );
    final savedPayload = labelSheetEncodeWorkbookSave(workbook);
    final png = await labelSheetCaptureRtfNativePng(
      savedPayload,
      width: 2,
      height: 1,
    );

    expect(png, isNull);
    expect(calls, isEmpty);
  });

  test('AI mm JSON is converted to a sheet draft', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final draft = labelSheetDraftFromAiJson(
      {
        'columnsMm': [20, 50, 30],
        'rowsMm': [15, 20, 25],
        'cells': [
          {
            'row': 0,
            'column': 0,
            'columnSpan': 3,
            'text': '배송분류표',
            'bold': true,
            'fontSizePt': 18,
            'horizontalAlign': 'center',
            'verticalAlign': 'middle',
          },
          {'row': 1, 'column': 1, 'text': '#SHIPSECUR'},
        ],
        'sourceImage': {
          'keep': true,
          'xMm': 0,
          'yMm': 0,
          'widthMm': 100,
          'heightMm': 60,
        },
      },
      sheet: sheet,
      imageBytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/png',
      fileName: 'label.png',
    );

    expect(draft.columnWidths, hasLength(3));
    expect(draft.rowHeights, hasLength(3));
    expect(draft.cells[const FortuneCellCoord(0, 0)]?.merge?.columnSpan, 3);
    expect(draft.cells[const FortuneCellCoord(0, 0)]?.bold, isTrue);
    expect(draft.cells[const FortuneCellCoord(1, 1)]?.value, '#SHIPSECUR');
    expect(draft.images, hasLength(1));

    final imported = labelSheetApplyImageImportDraft(sheet, draft);
    expect(imported.cells, hasLength(2));
    expect(imported.images.single.extraFields['labelAiImport'], isTrue);
  });

  test('GitHub Copilot Chat prompt includes source aspect fit guidance', () {
    final image = imglib.Image(width: 200, height: 100);
    imglib.fill(image, color: imglib.ColorRgb8(255, 255, 255));
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 100,
      },
    );

    final prompt = labelSheetCopilotPrompt(
      sheet: sheet,
      imageBytes: Uint8List.fromList(imglib.encodePng(image)),
      fileName: 'wide-label.png',
      userPrompt: 'convert',
    );

    expect(prompt, contains('pixelWidth: 200'));
    expect(prompt, contains('pixelHeight: 100'));
    expect(prompt, contains('sourceAspectRatio: 2.0000'));
    expect(prompt, contains('fitted layout size'));
    expect(prompt, contains('widthMm=100.00, heightMm=50.00'));
    expect(prompt, contains('Prioritize visual fidelity'));
    expect(prompt, contains('Do not use equal-width columns'));
  });

  test('MFC RichEditCtrl CP949 RTF is converted to an adjusted draft', () async {
    const channel = MethodChannel('charset_converter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'decode') {
            return null;
          }
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          final data = arguments['data'] as Uint8List;
          final hex = data
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          return switch (hex) {
            'c1a6c7b0b8ed' => '제품명',
            'b3bbbfebb7ae' => '내용량',
            'bfb5bee7c1a4bab8' => '영양정보',
            _ => String.fromCharCodes(data),
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final rtf =
        r"""{\rtf1\ansi\ansicpg949\deff0{\fonttbl{\f0\fnil\fcharset129 \'b1\'bc\'b8\'b2;}}
    {\*\generator Riched20 10.0.19041}\viewkind4\uc1
    \pard\b\f0\fs18\lang1042 * \'c1\'a6\'c7\'b0\'b8\'ed:#ITEMNAME  \b0\fs16 * \'b3\'bb\'bf\'eb\'b7\'ae:#CONTENTAMT\par
  """
        '\\trowd'
        r"""\trgaph108\cellx1957\cellx5385
    \pard\intbl\qj\b\f0\fs12\'bf\'b5\'be\'e7\'c1\'a4\'ba\'b8\cell
    \pard\intbl\qr\b0 #N09 #N10\cell\row
}""";
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    expect(labelSheetLooksLikeRichEditRtf(rtf), isTrue);
    final draft = await labelSheetDraftFromRichEditRtfAsync(rtf, sheet: sheet);

    expect(draft, isNotNull);
    expect(draft!.rowHeights, hasLength(2));
    expect(draft.columnWidths, hasLength(2));
    expect(
      draft.cells[const FortuneCellCoord(0, 0)]?.value,
      contains('제품명:#ITEMNAME'),
    );
    expect(
      draft.cells[const FortuneCellCoord(0, 0)]?.value,
      contains('내용량:#CONTENTAMT'),
    );
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.value, '영양정보');
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.bold, isTrue);
    expect(draft.cells[const FortuneCellCoord(1, 1)]?.horizontalAlign, 'right');
  });

  test('RTF import prefers native rtf2html FortuneSheet draft', () async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          calls.add(call);
          expect(call.method, 'convertRtfHtml');
          return <String, Object?>{
            'ok': true,
            'html': '''<!doctype html>
<html><head><style>
.rtf0{font-weight:bold;color:#ff0000;background-color:#00ff00;font-size:8pt;font-family:'Gulim';}
</style></head><body><table>
<colgroup><col style="width:30px"><col style="width:70px"></colgroup>
<tr><td class="bt"><span class="rtf0">Native</span></td><td>Bridge</td></tr>
<tr><td class="bb" colspan="2">Merged</td></tr>
</table></body></html>''',
          };
        });

    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = await labelSheetDraftFromRichEditRtfAsync(
      r'{\rtf1\ansi\deff0\pard Fallback\par}',
      sheet: sheet,
    );

    expect(draft, isNotNull);
    expect(calls, hasLength(1));
    expect(draft!.rowHeights, hasLength(2));
    final totalWidth = draft.columnWidths.values.fold<double>(
      0,
      (sum, width) => sum + width,
    );
    expect(draft.columnWidths[0]! / totalWidth, closeTo(0.3, 0.001));
    expect(draft.columnWidths[1]! / totalWidth, closeTo(0.7, 0.001));
    final nativeCell = draft.cells[const FortuneCellCoord(0, 0)];
    expect(nativeCell?.value, 'Native');
    expect(nativeCell?.bold, isTrue);
    expect(nativeCell?.fontFamily, 'Gulim');
    expect(nativeCell?.fontSize, 8);
    expect(nativeCell?.foreground, const Color(0xffff0000));
    expect(nativeCell?.background, const Color(0xff00ff00));
    expect(draft.cells[const FortuneCellCoord(0, 1)]?.value, 'Bridge');
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.value, 'Merged');
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.merge?.columnSpan, 2);
    expect(
      draft.borderInfo.any(
        (border) => border.extraFields['labelRtfHtmlImport'] == true,
      ),
      isTrue,
    );
  });

  test('RTF import maps plain text lines to separate rows', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = labelSheetDraftFromRichEditRtf(
      r'{\rtf1\ansi\deff0\pard Alpha\line Beta\par Gamma\par}',
      sheet: sheet,
    );

    expect(draft, isNotNull);
    expect(draft!.rowHeights, hasLength(3));
    expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'Alpha');
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.value, 'Beta');
    expect(draft.cells[const FortuneCellCoord(2, 0)]?.value, 'Gamma');
  });

  test('RTF import expands multiline table cells to sheet rows', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = labelSheetDraftFromRichEditRtf(
      r'{\rtf1\ansi\deff0\trowd\trrh4000\cellx2000\cellx2300\cellx4300'
      r'\pard\intbl\b Alpha\b0\line Beta\line\line Tail\line\cell'
      r'\pard\intbl\cell'
      r'\pard\intbl\line One\line Two\line\cell\row}',
      sheet: sheet,
    );

    expect(draft, isNotNull);
    expect(draft!.rowHeights, hasLength(4));
    expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'Alpha');
    expect(draft.cells[const FortuneCellCoord(1, 0)]?.value, 'Beta');
    expect(draft.cells[const FortuneCellCoord(2, 0)], isNull);
    expect(draft.cells[const FortuneCellCoord(3, 0)]?.value, 'Tail');
    expect(draft.cells[const FortuneCellCoord(0, 2)]?.value, 'One');
    expect(draft.cells[const FortuneCellCoord(1, 2)]?.value, 'Two');
    expect(
      draft.cells[const FortuneCellCoord(0, 0)]?.inlineRuns?.first.text,
      'Alpha',
    );
  });

  test('RTF import maps table cell borders to sheet borders', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = labelSheetDraftFromRichEditRtf(
      r'{\rtf1\ansi\deff0{\colortbl;\red255\green0\blue0;}'
      r'\trowd\trrh2000'
      r'\clbrdrl\brdrw20\brdrs\brdrcf1'
      r'\clbrdrt\brdrw20\brdrs\brdrcf1'
      r'\clbrdrr\brdrw20\brdrs\brdrcf1'
      r'\clbrdrb\brdrw20\brdrs\brdrcf1'
      r'\cellx2000\pard\intbl Alpha\line Beta\cell\row}',
      sheet: sheet,
    );

    expect(draft, isNotNull);
    expect(draft!.rowHeights, hasLength(2));
    expect(draft.borderInfo, hasLength(6));
    final byType = <String, List<FortuneBorderInfo>>{};
    for (final border in draft.borderInfo) {
      byType.putIfAbsent(border.borderType, () => []).add(border);
      expect(border.color, const Color(0xffff0000));
      expect(border.strokeWidth, 2);
    }
    expect(byType['border-top']!.single.ranges.single.rowStart, 0);
    expect(byType['border-bottom']!.single.ranges.single.rowStart, 1);
    expect(byType['border-left'], hasLength(2));
    expect(byType['border-right'], hasLength(2));

    final importedSheet = labelSheetApplyImageImportDraft(sheet, draft);
    expect(importedSheet.borderInfo, hasLength(draft.borderInfo.length));
  });

  test(
    'RTF import maps table row borders to perimeter sheet borders',
    () async {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 100,
          fortuneSheetGridClientHeightMmKey: 60,
        },
      );

      final draft = labelSheetDraftFromRichEditRtf(
        r'{\rtf1\ansi\deff0'
        r'\trowd\trrh2000'
        r'\trbrdrl\brdrs\brdrw10'
        r'\trbrdrt\brdrs\brdrw10'
        r'\trbrdrr\brdrs\brdrw10'
        r'\trbrdrb\brdrs\brdrw10'
        r'\cellx2000\cellx4000'
        r'\pard\intbl Left\line Next\cell'
        r'\pard\intbl Right\line More\cell\row}',
        sheet: sheet,
      );

      expect(draft, isNotNull);
      expect(draft!.rowHeights, hasLength(2));
      final borders = draft.borderInfo;
      expect(
        borders.where((border) => border.borderType == 'border-top'),
        hasLength(2),
      );
      expect(
        borders.where((border) => border.borderType == 'border-bottom'),
        hasLength(2),
      );
      expect(
        borders.where((border) => border.borderType == 'border-left'),
        hasLength(2),
      );
      expect(
        borders.where((border) => border.borderType == 'border-right'),
        hasLength(2),
      );
      expect(
        borders
            .where((border) => border.borderType == 'border-left')
            .map((border) => border.ranges.single.columnStart),
        everyElement(0),
      );
      expect(
        borders
            .where((border) => border.borderType == 'border-right')
            .map((border) => border.ranges.single.columnStart),
        everyElement(1),
      );
    },
  );

  test('RTF ANSI decoder caches the first working charset', () async {
    const channel = MethodChannel('charset_converter');
    final charsets = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'decode') {
            return null;
          }
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          final charset = arguments['charset'] as String;
          charsets.add(charset);
          if (charset != 'EUC-KR') {
            throw PlatformException(code: 'charset_name_unrecognized');
          }
          final data = arguments['data'] as Uint8List;
          final hex = data
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join();
          return switch (hex) {
            'c1a6' => '제',
            'b3bb' => '내',
            _ => String.fromCharCodes(data),
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );

    final draft = await labelSheetDraftFromRichEditRtfAsync(
      r"""{\rtf1\ansi\ansicpg949\deff0\pard \'c1\'a6 \'b3\'bb\par}""",
      sheet: sheet,
    );

    expect(draft, isNotNull);
    expect(
      charsets.where((charset) => charset == 'CP949'),
      hasLength(lessThanOrEqualTo(1)),
    );
    expect(
      charsets.where((charset) => charset == 'MS949'),
      hasLength(lessThanOrEqualTo(1)),
    );
    expect(
      charsets.where((charset) => charset == 'x-windows-949'),
      hasLength(lessThanOrEqualTo(1)),
    );
    expect(
      charsets.where((charset) => charset == 'EUC-KR').length,
      greaterThanOrEqualTo(2),
    );
  });

  test(
    'RTF import preserves font color background and inline styles',
    () async {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 100,
          fortuneSheetGridClientHeightMmKey: 60,
        },
      );
      final backslash = String.fromCharCode(92);
      final rtf =
          '''
{${backslash}rtf1${backslash}ansi${backslash}deff0
{${backslash}fonttbl{${backslash}f0${backslash}fnil Arial;}{${backslash}f1${backslash}fnil Courier New;}}
{${backslash}colortbl;${backslash}red255${backslash}green0${backslash}blue0;${backslash}red0${backslash}green255${backslash}blue0;${backslash}red0${backslash}green0${backslash}blue255;}
${backslash}trowd${backslash}clcbpat2${backslash}cellx3000${backslash}pard${backslash}intbl${backslash}f1${backslash}fs28${backslash}cf1${backslash}b Bold ${backslash}i Italic${backslash}i0  ${backslash}ul Under${backslash}ulnone  ${backslash}strike Strike${backslash}strike0  ${backslash}cf3 Blue${backslash}cell${backslash}row
}
''';

      final draft = await labelSheetDraftFromRichEditRtfAsync(
        rtf,
        sheet: sheet,
      );

      expect(draft, isNotNull);
      final cell = draft!.cells[const FortuneCellCoord(0, 0)];
      expect(cell, isNotNull);
      expect(cell!.value, contains('Bold Italic Under Strike Blue'));
      expect(cell.fontFamily, 'Courier New');
      expect(cell.fontSize, 14);
      expect(cell.bold, isTrue);
      expect(cell.hasRawBold, isTrue);
      expect(cell.italic, isTrue);
      expect(cell.hasRawItalic, isTrue);
      expect(cell.underline, isTrue);
      expect(cell.hasRawUnderline, isTrue);
      expect(cell.strikeThrough, isTrue);
      expect(cell.hasRawStrikeThrough, isTrue);
      expect(cell.hasRawForeground, isTrue);
      expect(cell.foreground, const Color(0xffff0000));
      expect(cell.hasRawBackground, isTrue);
      expect(cell.background, const Color(0xff00ff00));
      expect(cell.inlineRuns, isNotNull);
      expect(cell.inlineRuns!.map((run) => run.text).join(), cell.value);
      expect(cell.inlineRuns!.first.fontFamily, 'Courier New');
      expect(cell.inlineRuns!.first.fontSize, 14);
      expect(cell.inlineRuns!.first.foreground, const Color(0xffff0000));
      expect(cell.inlineRuns!.last.text, 'Blue');
      expect(cell.inlineRuns!.last.foreground, const Color(0xff0000ff));
    },
  );

  test('RTF import preserves table and merged cell sizes', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final backslash = String.fromCharCode(92);
    final rtf =
        '''
{${backslash}rtf1${backslash}ansi${backslash}deff0
${backslash}trowd${backslash}trrh720${backslash}clvmgf${backslash}clmgf${backslash}cellx2000${backslash}clmrg${backslash}cellx5000${backslash}pard${backslash}intbl Merged${backslash}cell${backslash}pard${backslash}intbl${backslash}cell${backslash}row
${backslash}trowd${backslash}trrh1440${backslash}clvmrg${backslash}clmgf${backslash}cellx2000${backslash}clmrg${backslash}cellx5000${backslash}pard${backslash}intbl${backslash}cell${backslash}pard${backslash}intbl${backslash}cell${backslash}row
}
''';

    final draft = await labelSheetDraftFromRichEditRtfAsync(rtf, sheet: sheet);

    expect(draft, isNotNull);
    expect(draft!.rowHeights, hasLength(2));
    expect(draft.columnWidths, hasLength(2));
    expect(draft.rowHeights[1]! / draft.rowHeights[0]!, closeTo(2, 0.001));
    expect(
      draft.columnWidths[1]! / draft.columnWidths[0]!,
      closeTo(1.5, 0.001),
    );

    final anchor = draft.cells[const FortuneCellCoord(0, 0)];
    expect(anchor, isNotNull);
    expect(anchor!.value, 'Merged');
    expect(anchor.merge?.rowSpan, 2);
    expect(anchor.merge?.columnSpan, 2);
    expect(
      draft.cells[const FortuneCellCoord(1, 1)]?.merge,
      same(anchor.merge),
    );
  });

  test('RTF import preserves spacing line height and scripts', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final backslash = String.fromCharCode(92);
    final rtf =
        '''
{${backslash}rtf1${backslash}ansi${backslash}deff0
${backslash}trowd${backslash}cellx3000${backslash}pard${backslash}intbl${backslash}fs20${backslash}charscalex80${backslash}expnd8${backslash}sl360${backslash}slmult1 Wide ${backslash}super Sup${backslash}nosupersub  ${backslash}sub Sub${backslash}cell${backslash}row
}
''';

    final draft = await labelSheetDraftFromRichEditRtfAsync(rtf, sheet: sheet);

    expect(draft, isNotNull);
    final cell = draft!.cells[const FortuneCellCoord(0, 0)];
    expect(cell, isNotNull);
    expect(cell!.value, contains('Wide Sup Sub'));
    expect(cell.extraFields['fontScale'], 80);
    expect(cell.extraFields['letterSpacing'], 2);
    expect(cell.extraFields['lineHeight'], 1.5);

    final runs = cell.inlineRuns!;
    final baseRun = runs.firstWhere((run) => run.text.contains('Wide'));
    final superRun = runs.firstWhere((run) => run.text == 'Sup');
    final subRun = runs.firstWhere((run) => run.text == 'Sub');
    expect(baseRun.extraFields['fontScale'], 80);
    expect(baseRun.extraFields['letterSpacing'], 2);
    expect(baseRun.extraFields['lineHeight'], 1.5);
    expect(superRun.extraFields['script'], 'superscript');
    expect(superRun.fontSize, 6);
    expect(subRun.extraFields['script'], 'subscript');
    expect(subRun.fontSize, 6);
  });

  test('RTF import preserves additional properties as metadata', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final backslash = String.fromCharCode(92);
    final rtf =
        '''
{${backslash}rtf1${backslash}ansi${backslash}deff0
${backslash}trowd${backslash}clvertalt${backslash}cellx3000${backslash}pard${backslash}intbl${backslash}qj${backslash}li120${backslash}ri240${backslash}fi-60${backslash}sb100${backslash}sa200${backslash}scaps${backslash}caps${backslash}uldb${backslash}up6${backslash}foo123 Raised ${backslash}dn4 Lower${backslash}cell${backslash}row
}
''';

    final draft = await labelSheetDraftFromRichEditRtfAsync(rtf, sheet: sheet);

    expect(draft, isNotNull);
    final cell = draft!.cells[const FortuneCellCoord(0, 0)];
    expect(cell, isNotNull);
    expect(cell!.value, 'Raised Lower');
    expect(cell.verticalAlign, 'top');
    expect(cell.horizontalAlign, '3');
    expect(cell.underline, isTrue);
    expect(cell.extraFields['rtfUnderlineStyle'], 'uldb');
    expect(cell.extraFields['rtfSmallCaps'], isTrue);
    expect(cell.extraFields['rtfAllCaps'], isTrue);
    expect(cell.extraFields['rtfParagraphAlign'], 'justify');
    expect(cell.extraFields['rtfLeftIndentTwips'], 120);
    expect(cell.extraFields['rtfRightIndentTwips'], 240);
    expect(cell.extraFields['rtfFirstLineIndentTwips'], -60);
    expect(cell.extraFields['rtfSpaceBeforeTwips'], 100);
    expect(cell.extraFields['rtfSpaceAfterTwips'], 200);
    expect(cell.extraFields['rtfBaselineShiftPt'], 3);
    expect(cell.extraFields['rtfUnmappedControls'], contains('foo=123'));

    final lowerRun = cell.inlineRuns!.firstWhere(
      (run) => run.text.contains('Lower'),
    );
    expect(lowerRun.extraFields['rtfBaselineShiftPt'], -2);

    final file = await labelSheetWriteDraftOpenXmlTestFile(
      draft,
      path: '.tmp/label_sheet_rtf_metadata_test.xlsx',
    );
    addTearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });

    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final metadata = archive.findFile('customXml/item1.xml');
    expect(metadata, isNotNull);
    final metadataXml = utf8.decode(metadata!.content);
    expect(metadataXml, contains('rtfUnderlineStyle="uldb"'));
    expect(metadataXml, contains('rtfSmallCaps="true"'));
    expect(metadataXml, contains('rtfAllCaps="true"'));
    expect(metadataXml, contains('rtfParagraphAlign="justify"'));
    expect(metadataXml, contains('rtfLeftIndentTwips="120.00"'));
    expect(metadataXml, contains('rtfFirstLineIndentTwips="-60.00"'));
    expect(metadataXml, contains('rtfBaselineShiftPt="3.00"'));
    expect(metadataXml, contains('rtfBaselineShiftPt="-2.00"'));
    expect(metadataXml, contains('<control value="foo=123"/>'));
  });

  test('RTF import converts pict images to FortuneImage', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final png = imglib.encodePng(
      imglib.Image(width: 1, height: 1)
        ..setPixel(0, 0, imglib.ColorRgb8(255, 0, 0)),
    );
    final hex = png
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final backslash = String.fromCharCode(92);
    final rtf =
        '''
{${backslash}rtf1${backslash}ansi
${backslash}trowd${backslash}cellx2000${backslash}pard${backslash}intbl{${backslash}pict${backslash}pngblip${backslash}picw1${backslash}pich1${backslash}picwgoal300${backslash}pichgoal600 $hex}Logo${backslash}cell${backslash}row
}
''';

    final draft = await labelSheetDraftFromRichEditRtfAsync(rtf, sheet: sheet);

    expect(draft, isNotNull);
    expect(draft!.cells[const FortuneCellCoord(0, 0)]?.value, 'Logo');
    expect(draft.images, hasLength(1));
    final image = draft.images.single;
    expect(image.src, startsWith('data:image/png;base64,'));
    expect(image.left, 0);
    expect(image.top, 0);
    expect(image.width, closeTo(20, 0.01));
    expect(image.height, closeTo(40, 0.01));
    expect(image.extraFields['rtfPicture'], isTrue);
    expect(image.extraFields['rtfPictureType'], 'png');

    final file = await labelSheetWriteDraftOpenXmlTestFile(
      draft,
      path: '.tmp/label_sheet_rtf_pict_test.xlsx',
    );
    addTearDown(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final metadata = archive.findFile('customXml/item1.xml');
    expect(metadata, isNotNull);
    final metadataXml = utf8.decode(metadata!.content);
    expect(metadataXml, contains('<image index="0" id="rtf-picture-0"'));
    expect(metadataXml, contains('rtfPicture="true"'));
    expect(metadataXml, contains('rtfPictureType="png"'));
  });

  test(
    'label sheet workbook loads RichEdit RTF without trimming sheet extent',
    () async {
      final rtf =
          r"""{\rtf1\ansi\ansicpg949\deff0{\fonttbl{\f0\fnil Arial;}}
{\*\generator Riched20 10.0.19041}\viewkind4\uc1
    \pard\b\fs18 Title #ITEMNAME\b0\par
    """
          '\\trowd'
          r"""\cellx2000\cellx5000\pard\intbl Left\cell\pard\intbl\qr Right\cell\row
}""";
      final workbook = FortuneWorkbook(
        sheets: [FortuneSheet(id: 's1', name: 'Label')],
      );

      final imported = await labelSheetWorkbookWithRtf(workbook, labelRtf: rtf);
      final sheet = imported.activeSheet;
      const settings = FortuneSettings();

      expect(sheet.rowCount, settings.row);
      expect(sheet.columnCount, settings.column);
      expect(
        sheet.cells[const FortuneCellCoord(0, 0)]?.value,
        'Title #ITEMNAME',
      );
      expect(sheet.cells[const FortuneCellCoord(0, 0)]?.bold, isTrue);
      expect(sheet.cells[const FortuneCellCoord(1, 1)]?.value, 'Right');
      expect(
        sheet.cells[const FortuneCellCoord(1, 1)]?.horizontalAlign,
        'right',
      );
      expect(sheet.extraFields['labelRtfImportSource'], isTrue);
    },
  );

  test('label sheet workbook does not write RTF XLSX by default', () async {
    addTearDown(() {
      labelSheetWriteRtfOpenXmlTestFileEnabled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });
    labelSheetWriteRtfOpenXmlTestFileEnabled = false;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) async {
          calls.add(call);
          expect(call.method, isNot('writeRtfOpenXml'));
          return <String, Object?>{'ok': false, 'reason': 'test fallback'};
        });
    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Label')],
    );

    final imported = await labelSheetWorkbookWithRtf(
      workbook,
      labelRtf: r'{\rtf1\ansi\deff0\pard Title\par}',
    );

    expect(
      imported.activeSheet.cells[const FortuneCellCoord(0, 0)]?.value,
      'Title',
    );
    expect(calls.map((call) => call.method), contains('convertRtfHtml'));
    expect(
      calls.map((call) => call.method),
      isNot(contains('writeRtfOpenXml')),
    );
  });

  testWidgets('label sheet blocks interaction while RTF is converting', (
    tester,
  ) async {
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null);
    });
    final pendingNativeHtml = Completer<Map<String, Object?>>();
    final nativeMethods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, (call) {
          nativeMethods.add(call.method);
          expect(call.method, 'convertRtfHtml');
          return pendingNativeHtml.future;
        });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: LabelSheetWorkbench(
              labelRtf: r'{\rtf1\ansi\deff0\pard Waiting\par}',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('RTF를 변환 중입니다...'), findsOneWidget);

    final absorbers = tester.widgetList<AbsorbPointer>(
      find.byType(AbsorbPointer),
    );
    final listeners = tester.widgetList<Listener>(find.byType(Listener));
    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final pendingSaveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    expect(pendingSaveItem.disabled, isTrue);
    expect(
      listeners.any((listener) => listener.behavior == HitTestBehavior.opaque),
      isTrue,
    );
    expect(absorbers.any((absorber) => absorber.absorbing), isTrue);
    expect(nativeMethods, ['convertRtfHtml']);

    FortuneSheetPainter currentPainter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .first;

    final initialPainter = currentPainter();
    expect(initialPainter.selection.row, 0);
    expect(initialPainter.selection.column, 0);
    expect(initialPainter.sheetRulerCornerSubtitleLabel, isNull);

    await tester.tapAt(const Offset(220, 180));
    await tester.pump();

    final blockedPainter = currentPainter();
    expect(blockedPainter.selection.row, 0);
    expect(blockedPainter.selection.column, 0);

    pendingNativeHtml.complete(<String, Object?>{
      'ok': true,
      'html': '<table><tr><td>Done</td></tr></table>',
    });
    await tester.pumpAndSettle();

    expect(find.text('RTF를 변환 중입니다...'), findsNothing);

    final restoredAbsorbers = tester.widgetList<AbsorbPointer>(
      find.byType(AbsorbPointer),
    );
    expect(restoredAbsorbers.any((absorber) => absorber.absorbing), isFalse);
    final restoredSheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final restoredSaveItem = restoredSheetApp.settings!.customToolbarItems
        .singleWhere((item) => item.key == labelSheetSaveToolbarCommand);
    expect(restoredSaveItem.disabled, isFalse);
    final restoredPainter = currentPainter();
    expect(restoredPainter.sheetRulerCornerSubtitleLabel, '(RTF 변환 적용)');
  });

  test(
    'GitHub Copilot Chat JSON response is converted to a sheet draft',
    () async {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 100,
          fortuneSheetGridClientHeightMmKey: 60,
        },
      );
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['model'], 'openai/gpt-4.1');
        expect(body['messages'], isA<List>());
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'columnsMm': [40, 60],
                    'rowsMm': [20, 40],
                    'cells': [
                      {'row': 0, 'column': 0, 'text': 'COPILOT'},
                    ],
                    'sourceImage': {
                      'keep': true,
                      'xMm': 0,
                      'yMm': 0,
                      'widthMm': 100,
                      'heightMm': 60,
                    },
                  }),
                },
              },
            ],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });

      final draft = await labelSheetAnalyzeImageWithCopilot(
        LabelSheetCopilotImportRequest(
          token: 'test-token-1234',
          model: 'openai/gpt-4.1',
          prompt: 'convert',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          fileName: 'label.png',
          sheet: sheet,
          client: client,
        ),
      );

      expect(draft.columnWidths, hasLength(2));
      expect(draft.rowHeights, hasLength(2));
      expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'COPILOT');
      expect(draft.images, isEmpty);
    },
  );

  test('GitHub Copilot Chat image-only response is rejected', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'columnsMm': [100],
                  'rowsMm': [60],
                  'cells': [],
                  'sourceImage': {
                    'keep': true,
                    'xMm': 0,
                    'yMm': 0,
                    'widthMm': 100,
                    'heightMm': 60,
                  },
                }),
              },
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    await expectLater(
      labelSheetAnalyzeImageWithCopilot(
        LabelSheetCopilotImportRequest(
          token: 'test-token-1234',
          model: 'openai/gpt-4.1',
          prompt: 'convert',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          fileName: 'label.png',
          sheet: sheet,
          client: client,
        ),
      ),
      throwsA(
        isA<LabelSheetCopilotImportException>().having(
          (error) => error.message,
          'message',
          contains('편집 가능한 셀이 없습니다'),
        ),
      ),
    );
  });

  test(
    'GitHub Copilot Chat HTTP errors include response diagnostics',
    () async {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 100,
          fortuneSheetGridClientHeightMmKey: 60,
        },
      );
      final client = MockClient((request) async {
        expect(request.url.host, 'models.github.ai');
        expect(request.url.path, '/inference/chat/completions');
        expect(request.headers['Authorization'], 'Bearer test-token-1234');
        return http.Response(
          jsonEncode({
            'error': {
              'code': 429,
              'type': 'rate_limit_exceeded',
              'message': 'Rate limit exceeded for GitHub Models inference.',
            },
          }),
          429,
          headers: const {'content-type': 'application/json'},
        );
      });

      await expectLater(
        labelSheetAnalyzeImageWithCopilot(
          LabelSheetCopilotImportRequest(
            token: 'test-token-1234',
            model: 'openai/gpt-4.1',
            prompt: 'convert',
            imageBytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/png',
            fileName: 'label.png',
            sheet: sheet,
            client: client,
          ),
        ),
        throwsA(
          isA<LabelSheetCopilotImportException>()
              .having((error) => error.message, 'message', contains('HTTP 429'))
              .having(
                (error) => error.message,
                'message',
                contains('rate_limit_exceeded'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('Rate limit exceeded for GitHub Models inference.'),
              ),
        ),
      );
    },
  );
}
