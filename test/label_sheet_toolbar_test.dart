import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui show PointerDeviceKind, Rect;

import 'package:archive/archive.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/home_page_manager.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
import 'package:label_manager/page_label_sheet/label_sheet_ai_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_ai_import_temp.dart';
import 'package:label_manager/page_label_sheet/label_sheet_page.dart';
import 'package:label_manager/page_label_sheet/label_sheet_import_model.dart';
import 'package:label_manager/page_label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_label_sheet/label_sheet_open_xml_export.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/utils/on_messages.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

ItemOfMarket _testItemOfMarket({
  int itemId = 10,
  String itemName = '테스트 품목',
  String element = '원재료',
}) {
  final now = DateTime(2026, 7, 7);
  return ItemOfMarket(
    marketId: 1,
    item: Item(
      itemId: itemId,
      labelSizeId: 20,
      itemName: itemName,
      labelSizeName: '테스트 라벨',
      element: element,
      elementRTF: '',
      price: 0,
      order: 0,
    ),
    additionalItem: const AdditionalItem(
      AdditionalItemId: 0,
      itemId: 10,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: now,
    dateSaleEnd: now,
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: now,
    dateEndDiscount: now,
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 0,
    useScaleBarcode: false,
    printCount: 1,
    useLabelSize: false,
    labelSizeWidth: 0,
    labelSizeHeight: 0,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );
}

LabelSize _testLabelSizeWithFormData(String formData) {
  return LabelSize(
    labelSizeId: 20,
    brandId: 1,
    labelSizeName: '테스트 라벨',
    labelSizeCommon: LabelSizeCommon(width: 100, height: 80, rtf: formData),
  );
}

TColumn _testColumn(int id, String keyword) {
  const type = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
  return TColumn(
    columnType: type,
    keyword: keyword,
    columnName: keyword,
    useMissingKeywordCheck: false,
    columnId: id,
    labelSizeId: 20,
    order: 1,
    width: 0,
    height: 0,
    barcodeType: BarcodeType.Code128,
    useBarcodeCheckDigit: false,
    showBarcodeNum: false,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: false,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 10,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
    timeBarcodeType: 0,
    autoInc: false,
    autoIncSize: 0,
    autoIncSave: false,
    autoIncRange: 0,
    autoIncZeroDel: false,
    autoIncUpdate: false,
    searchPrint: false,
    userDefineBarcodeText: '',
    lineCheck: 0,
    lineSize: 0,
    gs1ai: '01',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

Offset _toolbarItemCenter(
  String key, {
  double width = 1200,
  List<String> items = fortuneToolbarItems,
}) {
  for (final entry in fortuneVisibleToolbarItemRects(width, items: items)) {
    if (entry.key == key) {
      return entry.value.center;
    }
  }
  fail('toolbar item not found: $key');
}

FortuneSheetPainter _currentFortunePainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<FortuneSheetPainter>()
    .first;

Finder _printDialogCloseButtonFinder() {
  final closeFinder = find.text('닫기');
  return closeFinder.evaluate().isNotEmpty ? closeFinder : find.text('취소');
}

const List<String> _itemElementToolbarItemsForTest = [
  fortuneToolbarFontPopupKey,
  fortuneToolbarFontSizePopupKey,
  fortuneToolbarBoldCommand,
  fortuneToolbarItalicCommand,
  fortuneToolbarStrikeThroughCommand,
  fortuneToolbarUnderlineCommand,
  fortuneToolbarFontColorPopupKey,
  fortuneToolbarBackgroundPopupKey,
  fortuneToolbarHorizontalAlignPopupKey,
  fortuneToolbarVerticalAlignPopupKey,
  fortuneToolbarTextWrapPopupKey,
  fortuneToolbarTextRotationPopupKey,
];

List<String> _editableTextValues(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .map((editableText) => editableText.controller.text)
    .toList();

Offset _floatingResizeGripPoint(WidgetTester tester, String key) {
  final topLeft = tester.getTopLeft(find.byKey(ValueKey(key)));
  final local = switch (key) {
    'floating-resize-top-right' => const Offset(36, 8),
    'floating-resize-bottom-right' => const Offset(36, 36),
    'floating-resize-bottom-left' => const Offset(8, 36),
    _ => const Offset(8, 8),
  };
  return topLeft + local;
}

void main() {
  test('item manager load progress does not expire during slow DB work', () {
    expect(
      itemManagerLoadProgressDuration,
      greaterThan(const Duration(hours: 1)),
    );
  });

  test('common label dirty callback is scoped to its label session', () {
    expect(
      commonLabelSheetDirtyChangeBelongsToCurrentSession(
        sourceLabelSizeId: 10,
        currentLabelSizeId: 10,
      ),
      isTrue,
    );
    expect(
      commonLabelSheetDirtyChangeBelongsToCurrentSession(
        sourceLabelSizeId: 10,
        currentLabelSizeId: 20,
      ),
      isFalse,
    );
    expect(
      commonLabelSheetDirtyChangeBelongsToCurrentSession(
        sourceLabelSizeId: 10,
        currentLabelSizeId: null,
      ),
      isFalse,
    );
  });

  testWidgets(
    'item manager load failure closes progress and shows warning dialog',
    (tester) async {
      late BuildContext scaffoldContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                scaffoldContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      showSnackBar(
        scaffoldContext,
        '브랜드 데이터를 불러오고 있습니다...',
        type: SnackBarType.inProgress,
        duration: itemManagerLoadProgressDuration,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      unawaited(showItemManagerLoadFailureDialog(scaffoldContext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('품목 조회 오류'), findsOneWidget);
      expect(find.text(itemManagerLoadFailureMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('dirty item draft blocks header dropdown menus', (tester) async {
    tester.view.physicalSize = const Size(1400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const firstBrand = Brand(brandId: 1, customerId: 1, brandName: '브랜드 A');
    const secondBrand = Brand(brandId: 2, customerId: 1, brandName: '브랜드 B');
    const firstLabel = LabelSize(
      labelSizeId: 10,
      brandId: 1,
      labelSizeName: '라벨 A',
    );
    const secondLabel = LabelSize(
      labelSizeId: 20,
      brandId: 1,
      labelSizeName: '라벨 B',
    );
    var blockedTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugTopControlAreaForTesting(
            brands: const [firstBrand, secondBrand],
            selectedBrand: firstBrand,
            labelSizes: const [firstLabel, secondLabel],
            selectedLabelSize: firstLabel,
            dropdownChangeBlocked: true,
            onBlockedDropdownTap: () => blockedTapCount += 1,
          ),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.text('브랜드 A')));
    await tester.pumpAndSettle();
    expect(find.text('브랜드 B'), findsNothing);

    await tester.tapAt(tester.getCenter(find.text('라벨 A')));
    await tester.pumpAndSettle();
    expect(find.text('라벨 B'), findsNothing);
    expect(blockedTapCount, 2);
  });

  test('date settings is enabled only on item management tab', () {
    expect(
      debugItemManagerDateSettingsEnabledForTesting(selectedTabValue: 'items'),
      isTrue,
    );
    expect(
      debugItemManagerDateSettingsEnabledForTesting(
        selectedTabValue: 'common_label',
      ),
      isFalse,
    );
    expect(
      debugItemManagerDateSettingsEnabledForTesting(
        selectedTabValue: 'label_output',
      ),
      isFalse,
    );
  });

  testWidgets(
    'label settings button is active when date settings is available',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: debugTopControlAreaForTesting(onDateSettingsPressed: () {}),
          ),
        ),
      );

      final popupFinder = find.byWidgetPredicate(
        (widget) =>
            widget is PopupMenuButton<String> && widget.tooltip == '라벨 설정',
      );
      final popup = tester.widget<PopupMenuButton<String>>(popupFinder);
      final button = tester.widget<OutlinedButton>(
        find.descendant(of: popupFinder, matching: find.byType(OutlinedButton)),
      );
      expect(popup.enabled, isTrue);
      expect(button.onPressed, isNotNull);

      await tester.tap(popupFinder);
      await tester.pumpAndSettle();
      expect(find.text('날짜 타입 설정...'), findsOneWidget);
      final dateItem = tester.widget<PopupMenuItem<String>>(
        find.ancestor(
          of: find.text('날짜 타입 설정...'),
          matching: find.byType(PopupMenuItem<String>),
        ),
      );
      expect(dateItem.enabled, isTrue);
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  test('item output preview reports RTF and invalid sheet states', () {
    final item = _testItemOfMarket();
    final rtfPreview = debugItemOutputPreviewForTesting(
      labelSize: _testLabelSizeWithFormData(r'{\rtf1\ansi legacy}'),
      item: item,
      elementText: '원재료 편집',
    );

    expect(rtfPreview.workbook, isNull);
    expect(rtfPreview.hintText, '* 라벨을 편집 저장 후 가능합니다.');

    final invalidPreview = debugItemOutputPreviewForTesting(
      labelSize: _testLabelSizeWithFormData('not a label sheet save'),
      item: item,
      elementText: '원재료 편집',
    );

    expect(invalidPreview.workbook, isNull);
    expect(invalidPreview.hintText, '* 저장된 라벨에 문제가 있습니다.');
  });

  test(
    'item output preview collects barcode messages and error placeholder',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Label',
            images: const [
              FortuneImage(
                id: 'warning',
                src: 'data:image/png;base64,AAA=',
                left: 0,
                top: 0,
                width: 10,
                height: 10,
                extraFields: {'itemCodeWarning': '대체 형식을 사용합니다.'},
              ),
              FortuneImage(
                id: 'error',
                src: 'data:image/png;base64,AAA=',
                left: 10,
                top: 0,
                width: 10,
                height: 10,
                extraFields: {
                  'itemCodeWarning': '대체 형식을 사용합니다.',
                  'itemCodeError': '바코드를 표시할 수 없습니다.',
                },
              ),
            ],
          ),
        ],
      );

      final messages = debugItemCodePreviewMessagesForTesting(workbook);
      expect(messages, [
        (text: '대체 형식을 사용합니다.', error: false),
        (text: '바코드를 표시할 수 없습니다.', error: true),
      ]);
      expect(
        debugItemCodeErrorPlaceholderForTesting(),
        startsWith('data:image/svg+xml;base64,'),
      );
    },
  );

  test(
    'item output preview creates fallback sheet for empty saved workbook',
    () {
      final encoded = _encodeLabelSheetSaveArchive(
        manifest: {
          'format': labelSheetSaveFormat,
          'version': labelSheetSaveFormatVersion,
          'features': labelSheetSaveFeatureVersions,
          'codec': 'fortune-sheet-json',
        },
        workbookJson: {'name': 'empty workbook', 'data': <Object?>[]},
      );

      final preview = debugItemOutputPreviewForTesting(
        labelSize: _testLabelSizeWithFormData(encoded),
        item: _testItemOfMarket(),
        elementText: '원재료 편집',
      );

      expect(preview.hintText, isNull);
      expect(preview.workbook, isNotNull);
      expect(preview.workbook!.sheets, hasLength(1));
      expect(
        preview.workbook!.sheets.single.id,
        'item_output_preview_sheet_01',
      );
      expect(preview.workbook!.sheets.single.name, '테스트 라벨');
    },
  );

  test('item output preview uses private active saved sheet only', () {
    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        activeSheetIndex: 1,
        sheets: [
          FortuneSheet(
            id: 'common_01',
            name: '다른 시트',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '사용하지 않음'),
            },
          ),
          FortuneSheet(
            id: 'common_02',
            name: '출력 시트',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '#ITEMNAME',
              ),
              const FortuneCellCoord(0, 1): const FortuneCell(
                value: '#ELEMENT',
              ),
            },
          ),
        ],
      ),
    );

    final preview = debugItemOutputPreviewForTesting(
      labelSize: _testLabelSizeWithFormData(encoded),
      item: _testItemOfMarket(itemName: '딸기잼'),
      elementText: '딸기, 설탕',
    );

    expect(preview.hintText, isNull);
    expect(preview.workbook, isNotNull);
    expect(preview.workbook!.sheets, hasLength(1));
    final sheet = preview.workbook!.sheets.single;
    expect(sheet.id, 'item_output_preview_sheet_01');
    expect(sheet.name, '테스트 라벨');
    expect(sheet.showGridLines, isFalse);
    expect(sheet.cells[const FortuneCellCoord(0, 0)]?.renderedText, '딸기잼');
    expect(sheet.cells[const FortuneCellCoord(0, 1)]?.renderedText, '딸기, 설탕');
  });

  test('item output preview preserves rich element replacement runs', () {
    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'common_01',
            name: '출력 시트',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '원재료: #ELEMENT / 보관',
              ),
            },
          ),
        ],
      ),
    );
    final elementWorkbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 'item_element',
          name: '주원료 및 함량',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(
              value: '딸기\n설탕',
              inlineRuns: [
                FortuneInlineTextRun(
                  text: '딸기',
                  bold: true,
                  hasRawBold: true,
                  fontFamily: 'Batang',
                  hasRawFontFamily: true,
                  fontSize: 14,
                  hasRawFontSize: true,
                ),
                FortuneInlineTextRun(text: '\n'),
                FortuneInlineTextRun(
                  text: '설탕',
                  italic: true,
                  hasRawItalic: true,
                  fontSize: 12,
                  hasRawFontSize: true,
                ),
              ],
            ),
          },
        ),
      ],
    );

    final preview = debugItemOutputPreviewForTesting(
      labelSize: _testLabelSizeWithFormData(encoded),
      item: _testItemOfMarket(itemName: '딸기잼'),
      elementText: 'plain fallback',
      elementWorkbook: elementWorkbook,
    );

    final cell =
        preview.workbook!.sheets.single.cells[const FortuneCellCoord(0, 0)]!;
    expect(cell.renderedText, '원재료: 딸기\n설탕 / 보관');
    expect(cell.textWrap, '2');
    expect(preview.workbook!.sheets.single.customHeight[0], 1);
    expect(preview.workbook!.sheets.single.rowHeights[0], greaterThan(19));
    final runs = cell.inlineRuns!;
    expect(runs.map((run) => run.text).join(), cell.renderedText);
    expect(runs.any((run) => run.text == '딸기' && run.bold == true), isTrue);
    expect(
      runs.any(
        (run) =>
            run.text == '딸기' &&
            run.fontFamily == 'Batang' &&
            run.fontSize == 14,
      ),
      isTrue,
    );
    expect(runs.any((run) => run.text == '설탕' && run.italic == true), isTrue);
  });

  test('item output preview prefers projected column values over shared content', () {
    final previousColumns = TColumn.datas;
    TColumn.datas = [_testColumn(7, 'EXP')];
    addTearDown(() {
      TColumn.datas = previousColumns;
    });

    final encoded = labelSheetEncodeWorkbookSave(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'common_01',
            name: '출력 시트',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '#EXP'),
            },
          ),
        ],
      ),
    );

    final preview = debugItemOutputPreviewForTesting(
      labelSize: _testLabelSizeWithFormData(encoded),
      item: _testItemOfMarket(),
      elementText: '원재료 편집',
      projectedColumnValues: const {7: '2026-07-08'},
    );

    expect(preview.hintText, isNull);
    expect(
      preview.workbook!.sheets.single.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '2026-07-08',
    );
  });

  testWidgets('item element hides formula bar and opens editor on double tap', (
    tester,
  ) async {
    var commitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 10, itemName: '첫 품목'),
            labelSize: _testLabelSizeWithFormData(''),
            onElementCommitted: (_, _, _) async {
              commitCount += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    expect(sheetApp.settings!.singleClickCellEdit, isFalse);
    expect(sheetApp.showFormulaBar, isFalse);
    expect(
      sheetApp.settings!.customToolbarItems.where(
        (item) => item.key == labelSheetSaveToolbarCommand,
      ),
      isEmpty,
    );

    final sheetTopLeft = tester.getTopLeft(find.byType(FortuneSheetApp));
    final initialEditorCount = find.byType(EditableText).evaluate().length;
    await tester.tapAt(sheetTopLeft + const Offset(80, 80));
    await tester.pump();
    expect(find.byType(EditableText), findsNWidgets(initialEditorCount));
    await tester.tapAt(sheetTopLeft + const Offset(80, 80));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(EditableText), findsNWidgets(initialEditorCount + 1));
    expect(commitCount, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(commitCount, 0);
  });

  test('item element content comparison ignores view state only', () {
    final previous = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 'item_element',
          name: '주원료 및 함량',
          status: 1,
          cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: '원료')},
        ),
      ],
    );
    final viewStateChanged = previous.copyWith(
      sheets: [previous.sheets.single.copyWith(status: 0)],
    );
    final contentChanged = previous.copyWith(
      sheets: [
        previous.sheets.single.copyWith(
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: '변경 원료'),
          },
        ),
      ],
    );
    final normalizedUnchangedEdit = previous.copyWith(
      sheets: [
        previous.sheets.single.copyWith(
          cells: {
            const FortuneCellCoord(0, 0): previous
                .sheets
                .single
                .cells[const FortuneCellCoord(0, 0)]!
                .withEditedValue('원료'),
          },
        ),
      ],
    );

    expect(
      debugItemElementWorkbookContentEqualsForTesting(
        previous,
        viewStateChanged,
      ),
      isTrue,
    );
    expect(
      debugItemElementWorkbookContentEqualsForTesting(previous, contentChanged),
      isFalse,
    );
    expect(
      debugItemElementWorkbookContentEqualsForTesting(
        previous,
        normalizedUnchangedEdit,
      ),
      isTrue,
    );
  });

  testWidgets('item element changes commit to draft without toolbar save', (
    tester,
  ) async {
    String? committedRowIdentity;
    String? committedPlain;
    String? committedPayload;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 0, itemName: '신규 품목'),
            rowIdentity: 'draft:auto-commit',
            labelSize: _testLabelSizeWithFormData(''),
            onElementCommitted: (rowIdentity, plain, payload) async {
              committedRowIdentity = rowIdentity;
              committedPlain = plain;
              committedPayload = payload;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.onChange!(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'item_element',
            name: '주원료 및 함량',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(
                value: '저장 버튼 없는 변경',
              ),
            },
          ),
        ],
      ),
    );
    sheetApp.onOp!(const [
      {'type': 'test'},
    ]);
    await tester.pump();

    expect(committedRowIdentity, 'draft:auto-commit');
    expect(committedPlain, '저장 버튼 없는 변경');
    expect(committedPayload, isNotNull);
    expect(
      labelSheetDecodeWorkbookSave(
        committedPayload!,
      ).sheets.first.cells.values.single.value,
      '저장 버튼 없는 변경',
    );
  });

  testWidgets('item element initial workbook sync does not dirty draft', (
    tester,
  ) async {
    var commitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 578, itemName: '조회 품목'),
            rowIdentity: 'item:578',
            labelSize: _testLabelSizeWithFormData(''),
            onElementCommitted: (_, _, _) async {
              commitCount += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.onChange!(sheetApp.workbook!);
    await tester.pump();

    expect(commitCount, 0);
  });

  testWidgets('item element is read-only without edit permission', (
    tester,
  ) async {
    var commitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 10, itemName: '조회 전용 품목'),
            labelSize: _testLabelSizeWithFormData(''),
            canEdit: false,
            onElementCommitted: (_, _, _) async {
              commitCount += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    expect(sheetApp.workbook!.activeSheet.authority, {'sheet': 1});
    expect(sheetApp.settings!.customToolbarItems, isEmpty);

    sheetApp.onChange!(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'item_element',
            name: '주원료 및 함량',
            cells: {
              const FortuneCellCoord(0, 0): const FortuneCell(value: '수정'),
            },
          ),
        ],
      ),
    );
    await tester.pump();

    expect(commitCount, 0);
  });

  test('item element RTF conversion decodes Korean ANSI hex', () async {
    const channel = MethodChannel('charset_converter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          final data = List<int>.from(arguments['data'] as List);
          final hex = data
              .map((value) => value.toRadixString(16).padLeft(2, '0'))
              .join();
          return switch (hex) {
            'c1a6c7b0b8ed' => '제품명',
            'b5fab1e2' => '딸기',
            _ => String.fromCharCodes(data),
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final workbook = await debugItemElementWorkbookFromRichEditRtfForTesting(
      r"""{\rtf1\ansi\ansicpg949\deff0{\fonttbl{\f0\fnil\fcharset129 \'b1\'bc\'b8\'b2;}}
    \viewkind4\uc1\pard\f0\fs18 \'c1\'a6\'c7\'b0\'b8\'ed: \'b5\'fa\'b1\'e2\par} """,
      _testLabelSizeWithFormData(''),
    );

    expect(workbook, isNotNull);
    expect(
      workbook!.sheets.single.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      contains('제품명: 딸기'),
    );
  });

  test('item element RTF conversion trims outer whitespace only', () async {
    final workbook = await debugItemElementWorkbookFromRichEditRtfForTesting(
      r"""{\rtf1\ansi\deff0{\fonttbl{\f0 Arial;}}
\viewkind4\uc1\pard\f0\fs18 \tab  원료 A\line 함량 1%\tab\par} """,
      _testLabelSizeWithFormData(''),
    );

    expect(workbook, isNotNull);
    expect(
      workbook!.sheets.single.cells[const FortuneCellCoord(0, 0)]?.renderedText,
      '원료 A\n함량 1%',
    );
  });

  test('item element DAO keeps legacy RTF while saving sheet data', () {
    expect(ItemOfMarketDAO.SelectSql, contains('P2.RICH_ELEMENT_SHEET'));
    expect(ItemOfMarketDAO.SelectSql, contains('P2.RICH_ELEMENT_RTF'));
    expect(
      ItemOfMarketDAO.SelectSql,
      contains('NULLIF(P2.RICH_ELEMENT_SHEET, \'\')'),
    );
    expect(ItemDAO.UpdateElementSheetSql, contains('RICH_ELEMENT=@element'));
    expect(
      ItemDAO.UpdateElementSheetSql,
      contains('RICH_ELEMENT_SHEET=@elementSheet'),
    );
    expect(ItemDAO.UpdateElementSheetSql, isNot(contains('RICH_ELEMENT_RTF')));
    expect(
      ItemDAO.AutoMigrateElementSheetSql,
      contains('RICH_ELEMENT=@element'),
    );
    expect(
      ItemDAO.AutoMigrateElementSheetSql,
      contains('RICH_ELEMENT_SHEET=@elementSheet'),
    );
    expect(
      ItemDAO.AutoMigrateElementSheetSql,
      contains("RICH_ELEMENT_SHEET IS NULL OR RICH_ELEMENT_SHEET=''"),
    );
    expect(
      ItemDAO.AutoMigrateElementSheetSql,
      isNot(contains('RICH_ELEMENT_RTF')),
    );
  });

  testWidgets('item preview keeps selected tab when selected row changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 10, itemName: '첫 품목'),
            labelSize: _testLabelSizeWithFormData(r'{\rtf1\ansi legacy}'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('출력내용 미리보기').last);
    await tester.pumpAndSettle();

    expect(find.text('* 라벨을 편집 저장 후 가능합니다.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 11, itemName: '둘째 품목'),
            labelSize: _testLabelSizeWithFormData(r'{\rtf1\ansi legacy}'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('* 라벨을 편집 저장 후 가능합니다.'), findsOneWidget);
  });

  testWidgets('item preview blocks output tab while draft context is locked', (
    tester,
  ) async {
    var blockedRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 10, itemName: '첫 품목'),
            labelSize: _testLabelSizeWithFormData(r'{\rtf1\ansi legacy}'),
            canSelectOutputPreview: () {
              blockedRequests += 1;
              return false;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('출력내용 미리보기').last);
    await tester.pumpAndSettle();

    expect(blockedRequests, 1);
    expect(find.text('* 라벨을 편집 저장 후 가능합니다.'), findsNothing);
    expect(find.text('주원료 및 함량'), findsWidgets);
  });

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
      isNot(contains(fortuneContextImportLabelImageCommand)),
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
      items.where((item) => item == fortuneContextImportLabelImageCommand),
      isEmpty,
    );
    expect(
      items.where((item) => item == labelSheetSaveToolbarCommand),
      hasLength(1),
    );
  });

  test('label sheet settings can disable object mutations explicitly', () {
    expect(labelSheetSettings(const FortuneSettings()).allowEdit, isTrue);
    expect(
      labelSheetSettings(
        const FortuneSettings(),
        canEditObjects: false,
      ).allowEdit,
      isFalse,
    );
  });

  test('label sheet settings can isolate item element editing mode', () {
    final settings = labelSheetSettings(
      const FortuneSettings(),
      toolbarItems: _itemElementToolbarItemsForTest,
      hideRowColumnHeaderLabels: true,
      hideSelectionHighlight: true,
      rulerCornerSizeLabelUsesAsterisk: true,
      disableSheetRulerGuideInteraction: true,
      hideStatisticBar: true,
      limitCellActionsToClipboardAndClear: true,
    );
    final toolbarItems = fortuneToolbarItemsWithCustom(
      settings.toolbarItems,
      settings.customToolbarItems,
    );

    expect(toolbarItems.first, fortuneToolbarFontPopupKey);
    expect(toolbarItems, isNot(contains(labelSheetSaveToolbarCommand)));
    expect(toolbarItems, isNot(contains(labelSheetPrintToolbarCommand)));
    expect(settings.rowHeaderWidth, 46);
    expect(settings.columnHeaderHeight, 20);
    expect(settings.hideRowColumnHeaderLabels, isTrue);
    expect(settings.hideSelectionHighlight, isTrue);
    expect(settings.singleClickCellEdit, isFalse);
    expect(settings.hidePrintAreaBoundary, isFalse);
    expect(settings.fitSingleCellToViewport, isFalse);
    expect(settings.rulerCornerSizeLabelUsesAsterisk, isTrue);
    expect(settings.disableSheetRulerGuideInteraction, isTrue);
    expect(settings.statisticBarHeight, 0);
    expect(settings.limitCellActionsToClipboardAndClear, isTrue);
    expect(settings.cellContextMenu, labelSheetClipboardClearContextMenuItems);
    expect(
      settings.headerContextMenu,
      labelSheetClipboardClearContextMenuItems,
    );

    final defaultSettings = labelSheetSettings(const FortuneSettings());
    expect(
      defaultSettings.toolbarItems,
      contains(labelSheetPrintToolbarCommand),
    );
    expect(defaultSettings.rowHeaderWidth, 46);
    expect(defaultSettings.columnHeaderHeight, 20);
    expect(defaultSettings.hideRowColumnHeaderLabels, isFalse);
    expect(defaultSettings.hideSelectionHighlight, isFalse);
    expect(defaultSettings.singleClickCellEdit, isFalse);
    expect(defaultSettings.hidePrintAreaBoundary, isFalse);
    expect(defaultSettings.fitSingleCellToViewport, isFalse);
    expect(defaultSettings.rulerCornerSizeLabelUsesAsterisk, isFalse);
    expect(defaultSettings.disableSheetRulerGuideInteraction, isFalse);
    expect(defaultSettings.statisticBarHeight, 23);
    expect(defaultSettings.limitCellActionsToClipboardAndClear, isFalse);
  });

  testWidgets('item element sheet limits menu and key actions by flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: debugItemPreviewPanelForTesting(
            item: _testItemOfMarket(itemId: 10, itemName: '첫 품목'),
            labelSize: _testLabelSizeWithFormData(''),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final settings = sheetApp.settings!;
    expect(settings.limitCellActionsToClipboardAndClear, isTrue);
    expect(settings.copyOnlyContextMenu, isFalse);
    expect(settings.cellContextMenu, labelSheetClipboardClearContextMenuItems);
    expect(
      settings.headerContextMenu,
      labelSheetClipboardClearContextMenuItems,
    );
    expect(
      settings.cellContextMenu,
      isNot(contains(fortuneContextInsertRowCommand)),
    );
    expect(
      settings.cellContextMenu,
      isNot(contains(fortuneContextClearSheetCommand)),
    );
  });

  testWidgets('limited cell action mode blocks formatting shortcut', (
    tester,
  ) async {
    Future<bool> ctrlBoldChangesWorkbook({required bool limited}) async {
      var changed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 320,
              child: LabelSheetWorkbench(
                key: ValueKey('limited-cell-action-$limited'),
                initialWorkbook: FortuneWorkbook(
                  sheets: [
                    FortuneSheet(
                      id: 's1',
                      name: 'Label',
                      cells: {
                        const FortuneCellCoord(0, 0): const FortuneCell(
                          value: '원료',
                        ),
                      },
                    ),
                  ],
                ),
                toolbarItems: _itemElementToolbarItemsForTest,
                limitCellActionsToClipboardAndClear: limited,
                onUserWorkbookChanged: (_) => changed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tapAt(
        tester.getTopLeft(find.byType(FortuneSheetApp)) + const Offset(80, 80),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      return changed;
    }

    expect(await ctrlBoldChangesWorkbook(limited: false), isTrue);
    expect(await ctrlBoldChangesWorkbook(limited: true), isFalse);
  });

  test('label sheet settings can hide toolbar and keep copy-only menus', () {
    final settings = labelSheetSettings(
      const FortuneSettings(),
      hideToolbar: true,
      copyOnlyContextMenu: true,
      toolbarItems: const <String>[],
    );

    expect(settings.showToolbar, isFalse);
    expect(settings.effectiveToolbarHeight, 0);
    expect(settings.toolbarItems, isEmpty);
    expect(settings.customToolbarItems, isEmpty);
    expect(settings.copyOnlyContextMenu, isTrue);
    expect(settings.cellContextMenu, const [fortuneContextCopyCommand]);
    expect(settings.headerContextMenu, const [fortuneContextCopyCommand]);

    final defaultSettings = labelSheetSettings(const FortuneSettings());
    expect(defaultSettings.showToolbar, isTrue);
    expect(defaultSettings.copyOnlyContextMenu, isFalse);
    expect(
      defaultSettings.cellContextMenu,
      contains(fortuneContextPasteCommand),
    );
  });

  testWidgets('single cell viewport fit keeps visible size across zoom', (
    tester,
  ) async {
    final controller = FortuneSheetController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          height: 200,
          child: FortuneSheetCanvas(
            workbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Sheet1',
                  rowCount: 1,
                  columnCount: 1,
                  cells: {
                    const FortuneCellCoord(0, 0): const FortuneCell(value: 'A'),
                  },
                ),
              ],
            ),
            settings: const FortuneSettings(
              toolbarItems: [],
              rowHeaderWidth: 0,
              columnHeaderHeight: 0,
              fitSingleCellToViewport: true,
            ),
            showFormulaBar: false,
            showSheetTabs: false,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();

    var sheet = controller.getSheet()!;
    final initialVisibleWidth = ((sheet.columnWidths[0]! + 1) * sheet.zoomRatio)
        .round();
    final initialVisibleHeight = ((sheet.rowHeights[0]! + 1) * sheet.zoomRatio)
        .round();
    expect(initialVisibleWidth, greaterThan(0));
    expect(initialVisibleHeight, greaterThan(0));

    controller.setZoomRatio(2);
    await tester.pump();

    sheet = controller.getSheet()!;
    expect(sheet.zoomRatio, 2);
    expect(
      ((sheet.columnWidths[0]! + 1) * sheet.zoomRatio).round(),
      initialVisibleWidth,
    );
    expect(
      ((sheet.rowHeights[0]! + 1) * sheet.zoomRatio).round(),
      initialVisibleHeight,
    );
  });

  test('label sheet context menu exposes AI image import', () {
    var importClicked = false;
    final settings = labelSheetSettings(
      const FortuneSettings(),
      onImportLabelImage: () {
        importClicked = true;
      },
    );

    expect(
      settings.cellContextMenu,
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );
    expect(
      settings.headerContextMenu,
      contains(fortuneContextImportLabelImageCommand),
    );
    expect(
      settings.sheetTabContextMenu,
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );
    expect(
      settings.filterContextMenu,
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );
    expect(
      fortuneContextRenderableMenuItems(settings.cellContextMenu),
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );
    expect(
      FortuneSheetLocale
          .korean
          .contextMenuLabels[fortuneContextImportLabelImageCommand],
      '라벨 이미지 가져오기',
    );

    settings.onContextMenuCommand!(fortuneContextImportLabelImageCommand);

    expect(importClicked, isTrue);
  });

  test('label sheet barcode formats include Micro QR Code', () {
    expect(
      labelSheetBarcodeFormats.map((format) => format.id),
      contains('microQRCode'),
    );

    final format = labelSheetBarcodeFormats.singleWhere(
      (format) => format.id == 'microQRCode',
    );

    expect(format.label, 'Micro QR Code');
    expect(format.ratio, 1.0);
  });

  testWidgets('label image import context menu only appears on sheet corner', (
    tester,
  ) async {
    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      settings: labelSheetSettings(
        const FortuneSettings(),
        onImportLabelImage: () {},
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 640,
          height: 760,
          child: FortuneSheetCanvas(workbook: workbook),
        ),
      ),
    );

    FortuneSheetPainter painter() {
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is FortuneSheetPainter,
      );
      return tester.widget<CustomPaint>(finder).painter! as FortuneSheetPainter;
    }

    final topLeft = tester.getTopLeft(find.byType(FortuneSheetCanvas));
    final columnHeaderGesture = await tester.startGesture(
      topLeft + const Offset(83, 80),
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await columnHeaderGesture.up();
    await tester.pump();

    expect(
      painter().contextMenuItems,
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );

    final rowHeaderGesture = await tester.startGesture(
      topLeft + const Offset(20, 100),
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await rowHeaderGesture.up();
    await tester.pump();

    expect(
      painter().contextMenuItems,
      isNot(contains(fortuneContextImportLabelImageCommand)),
    );

    final cornerGesture = await tester.startGesture(
      topLeft + const Offset(20, 80),
      kind: ui.PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await cornerGesture.up();
    await tester.pump();

    expect(
      painter().contextMenuItems,
      contains(fortuneContextImportLabelImageCommand),
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

  test('label sheet save preserves supported image object metadata', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Label',
          images: const [
            FortuneImage(
              id: 'barcode-image',
              src: 'data:image/png;base64,AAA=',
              left: 10,
              top: 20,
              width: 120,
              height: 60,
              extraFields: {
                'fortuneBarcode': true,
                'barcodeText': '1234567890',
                'barcodeFormatId': 'code128',
                'barcodeFormatLabel': 'Code 128',
                'originWidth': 240,
                'originHeight': 120,
                'rotation': 90,
                'widthMm': 42,
                'heightMm': 18,
                'barcodeModuleScale': 2,
                'barcodeBarHeight': 14,
                'barcodeLeadingText': '',
                'barcodeTrailingText': '',
                'barcodeShowText': true,
                'barcodeHumanReadableFontFamily': 'Arial',
                'barcodeHumanReadableFontSize': 12,
                'preserveTemplateBarcodeFormat': true,
                'crop': {
                  'width': 80,
                  'height': 40,
                  'offsetLeft': 4,
                  'offsetTop': 5,
                  'unsupportedCropField': 'drop',
                },
                fortuneBarcodeObjectIdExtraKey: '#BARCODE9',
                fortuneSheetObjectZOrderExtraKey: 7,
                fortuneBarcodeBodyTopExtraKey: 6,
                fortuneBarcodeBodyHeightExtraKey: 44,
                fortuneBarcodeBodyRatioExtraKey: 0.73,
                fortuneBarcodeIdLabelPrintExcludedExtraKey: true,
                'unsupportedImageField': 'drop',
              },
            ),
            FortuneImage(
              id: 'plain-image',
              src: 'data:image/png;base64,BBB=',
              left: 30,
              top: 40,
              width: 80,
              height: 50,
              extraFields: {
                fortuneImageObjectIdExtraKey: '#IMAGE4',
                fortuneSheetObjectZOrderExtraKey: 3,
              },
            ),
          ],
        ),
      ],
    );

    final encoded = labelSheetEncodeWorkbookSave(workbook);
    final savedJson = _decodeLabelSheetSaveWorkbookJson(encoded);
    final savedSheetJson = (savedJson['data'] as List).single as Map;
    final savedBarcodeJson = (savedSheetJson['images'] as List).first as Map;
    final savedCropJson = savedBarcodeJson['crop'] as Map;

    expect(
      labelSheetSaveFeatureVersions,
      contains('sheet.images.objectMetadata'),
    );
    expect(
      labelSheetSaveFeatureVersions,
      contains('sheet.images.preserveTemplateBarcodeFormat'),
    );
    expect(savedBarcodeJson['unsupportedImageField'], isNull);
    expect(savedCropJson['unsupportedCropField'], isNull);
    expect(savedBarcodeJson[fortuneBarcodeObjectIdExtraKey], '#BARCODE9');
    expect(savedBarcodeJson[fortuneSheetObjectZOrderExtraKey], 7);
    expect(savedBarcodeJson[fortuneBarcodeBodyRatioExtraKey], 0.73);
    expect(savedCropJson['offsetLeft'], 4);

    final decoded = labelSheetDecodeWorkbookSave(encoded);
    final decodedImages = decoded.activeSheet.images;
    final decodedBarcode = decodedImages.singleWhere(
      (image) => image.id == 'barcode-image',
    );
    final decodedImage = decodedImages.singleWhere(
      (image) => image.id == 'plain-image',
    );

    expect(decodedBarcode.extraFields['fortuneBarcode'], isTrue);
    expect(
      decodedBarcode.extraFields[fortuneBarcodeObjectIdExtraKey],
      '#BARCODE9',
    );
    expect(decodedBarcode.extraFields[fortuneSheetObjectZOrderExtraKey], 7);
    expect(decodedBarcode.extraFields[fortuneBarcodeBodyTopExtraKey], 6);
    expect(decodedBarcode.extraFields[fortuneBarcodeBodyHeightExtraKey], 44);
    expect(decodedBarcode.extraFields[fortuneBarcodeBodyRatioExtraKey], 0.73);
    expect(decodedBarcode.extraFields['preserveTemplateBarcodeFormat'], isTrue);
    expect(
      decodedBarcode.extraFields[fortuneBarcodeIdLabelPrintExcludedExtraKey],
      isTrue,
    );
    expect(decodedBarcode.extraFields['unsupportedImageField'], isNull);
    expect(
      (decodedBarcode.extraFields['crop'] as Map)['unsupportedCropField'],
      isNull,
    );
    expect(decodedImage.extraFields[fortuneImageObjectIdExtraKey], '#IMAGE4');
    expect(decodedImage.extraFields[fortuneSheetObjectZOrderExtraKey], 3);
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
    expect(saved.columnWidths.keys, everyElement(lessThan(saved.columnCount!)));
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

  test('label sheet save codec migrates legacy image key to images', () {
    final workbookJson = FortuneSheetCodec.workbookToJson(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'LegacyImage',
            rowCount: 2,
            columnCount: 2,
          ),
        ],
      ),
    );
    final sheetJson = (workbookJson['data'] as List).single as Map;
    sheetJson.remove('images');
    sheetJson['image'] = [
      {
        'id': 'img_legacy',
        'src': 'data:image/png;base64,abc',
        'left': 1,
        'top': 2,
        'width': 30,
        'height': 40,
      },
    ];

    final encoded = _encodeLabelSheetSaveArchive(
      manifest: {
        'format': labelSheetSaveFormat,
        'version': 1,
        'features': const <String, Object?>{},
        'encoding': 'base64',
        'compression': 'zip-deflate',
        'codec': 'fortune-sheet-json',
      },
      workbookJson: Map<String, Object?>.from(workbookJson),
    );

    final decoded = labelSheetDecodeWorkbookSave(encoded);

    expect(decoded.sheets.single.images.single.id, 'img_legacy');

    final resavedJson = _decodeLabelSheetSaveWorkbookJson(
      labelSheetEncodeWorkbookSave(decoded),
    );
    final resavedSheet = (resavedJson['data'] as List).single as Map;
    expect(resavedSheet.containsKey('image'), isFalse);
    expect(resavedSheet['images'], isA<List>());
    expect(
      ((resavedSheet['images'] as List).single as Map)['id'],
      'img_legacy',
    );
  });

  test(
    'label sheet save codec migrates legacy image key through bytes decoder',
    () {
      final encoded = _encodeLabelSheetSaveArchive(
        manifest: {
          'format': labelSheetSaveFormat,
          'version': 1,
          'features': const <String, Object?>{},
          'encoding': 'base64',
          'compression': 'zip-deflate',
          'codec': 'fortune-sheet-json',
        },
        workbookJson: {
          'data': [
            {
              'id': 's1',
              'name': 'BytesImport',
              'row': 1,
              'column': 1,
              'image': [
                {
                  'id': 'img_bytes',
                  'src': 'data:image/png;base64,abc',
                  'left': 1,
                  'top': 2,
                  'width': 30,
                  'height': 40,
                },
              ],
            },
          ],
        },
      );

      final decoded = labelSheetDecodeWorkbookSaveBytes(utf8.encode(encoded));

      expect(decoded.sheets.single.images.single.id, 'img_bytes');
    },
  );

  test(
    'label sheet save codec normalization keeps external imports current',
    () {
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'ExternalImport',
            rowCount: 1,
            columnCount: 1,
            images: const [
              FortuneImage(
                id: 'img_imported',
                src: 'data:image/png;base64,abc',
                left: 1,
                top: 2,
                width: 30,
                height: 40,
              ),
            ],
          ),
        ],
      );

      final normalized = labelSheetNormalizeWorkbookForCurrentSaveFormat(
        workbook,
      );
      final resavedJson = _decodeLabelSheetSaveWorkbookJson(
        labelSheetEncodeWorkbookSave(normalized),
      );
      final resavedSheet = (resavedJson['data'] as List).single as Map;

      expect(normalized.sheets.single.images.single.id, 'img_imported');
      expect(resavedSheet.containsKey('image'), isFalse);
      expect(resavedSheet['images'], isA<List>());
    },
  );

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
              return LabelSheetSaveResult.applied;
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

  testWidgets('label sheet save finalizes the active object property draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    String? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1100,
          height: 700,
          child: LabelSheetWorkbench(
            initialDirty: true,
            initialWorkbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Label',
                  shapes: const [
                    FortuneShape(
                      id: 'shape_1',
                      kind: FortuneShapeKind.rectangle,
                      left: 10,
                      top: 10,
                      width: 40,
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
            onSave: (_, _, payload) {
              savedPayload = payload;
              return LabelSheetSaveResult.applied;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('사각형 shape_1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-width')),
      '75',
    );
    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final saveItem = sheetApp.settings!.customToolbarItems.singleWhere(
      (item) => item.key == labelSheetSaveToolbarCommand,
    );
    saveItem.onClick!(saveItem);
    await tester.pump();
    await tester.pump();

    expect(savedPayload, isNotNull);
    expect(
      labelSheetDecodeWorkbookSave(
        savedPayload!,
      ).sheets.single.shapes.single.width,
      fortuneMillimetersToLogicalPixels(75),
    );
  });

  testWidgets('label sheet save projects active property draft changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1100,
          height: 700,
          child: LabelSheetWorkbench(
            initialWorkbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Label',
                  shapes: const [
                    FortuneShape(
                      id: 'shape_1',
                      kind: FortuneShapeKind.rectangle,
                      left: 10,
                      top: 10,
                      width: 40,
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
            onSave: (_, _, _) => LabelSheetSaveResult.applied,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('사각형 shape_1'));
    await tester.pump();

    final widthField = find.byKey(
      const ValueKey('fortune-object-property-width'),
    );
    final originalText = tester.widget<TextField>(widthField).controller!.text;

    bool saveDisabled() => tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetSaveToolbarCommand)
        .disabled;

    expect(saveDisabled(), isTrue);
    await tester.enterText(widthField, '75');
    await tester.pump();
    await tester.pump();
    expect(saveDisabled(), isFalse);

    await tester.enterText(widthField, 'invalid');
    await tester.pump();
    await tester.pump();
    expect(saveDisabled(), isTrue);

    await tester.enterText(widthField, originalText);
    await tester.pump();
    await tester.pump();
    expect(saveDisabled(), isTrue);
  });

  testWidgets('label sheet owner replacement finalizes property draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = LabelSheetEditingLifecycleController();
    FortuneWorkbook? changedWorkbook;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1100,
          height: 700,
          child: LabelSheetWorkbench(
            editingLifecycleController: lifecycle,
            initialWorkbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Label',
                  shapes: const [
                    FortuneShape(
                      id: 'shape_1',
                      kind: FortuneShapeKind.rectangle,
                      left: 10,
                      top: 10,
                      width: 40,
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
            onWorkbookChanged: (workbook) => changedWorkbook = workbook,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(lifecycle.isAttached, isTrue);
    await tester.tap(find.text('사각형 shape_1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-width')),
      '75',
    );

    expect(lifecycle.prepareForOwnerReplacement(), isTrue);
    await tester.pump();
    expect(
      changedWorkbook!.sheets.single.shapes.single.width,
      fortuneMillimetersToLogicalPixels(75),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    expect(lifecycle.isAttached, isFalse);
  });

  testWidgets('keyed label sheet owner replacement transfers lifecycle', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final lifecycle = LabelSheetEditingLifecycleController();

    Widget buildSheet(String labelId) => MaterialApp(
      home: SizedBox(
        width: 1100,
        height: 700,
        child: LabelSheetWorkbench(
          key: ValueKey(labelId),
          editingLifecycleController: lifecycle,
          initialWorkbook: FortuneWorkbook(
            sheets: [FortuneSheet(id: labelId, name: 'Label')],
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildSheet('label_1'));
    await tester.pump();
    expect(lifecycle.isAttached, isTrue);

    expect(lifecycle.prepareForOwnerReplacement(), isTrue);
    await tester.pumpWidget(buildSheet('label_2'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(lifecycle.isAttached, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(lifecycle.isAttached, isFalse);
  });

  testWidgets('label sheet owner replacement blocks barcode render pending', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final lifecycle = LabelSheetEditingLifecycleController();
    final render = Completer<FortuneBarcodeRenderResult?>();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1100,
          height: 1800,
          child: LabelSheetWorkbench(
            editingLifecycleController: lifecycle,
            barcodeRenderer: (_) => render.future,
            initialWorkbook: FortuneWorkbook(
              sheets: [
                FortuneSheet(
                  id: 's1',
                  name: 'Label',
                  images: const [
                    FortuneImage(
                      id: 'barcode_1',
                      src: 'old-src',
                      left: 20,
                      top: 30,
                      width: 80,
                      height: 40,
                      extraFields: {
                        'fortuneBarcode': true,
                        'barcodeText': 'OLD',
                        'barcodeFormatId': 'code128',
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('바코드 barcode_1'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('fortune-object-property-barcodeText')),
      'NEW',
    );
    final propertyList = find.ancestor(
      of: find.byKey(const ValueKey('fortune-object-property-connectionId')),
      matching: find.byType(ListView),
    );
    await tester.drag(propertyList, const Offset(0, -1200));
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('fortune-object-property-apply')),
        )
        .onPressed!();
    await tester.pump();

    expect(lifecycle.barcodePropertyRenderPending, isTrue);
    expect(lifecycle.prepareForOwnerReplacement(), isFalse);

    render.complete(null);
    await tester.pump();
    await tester.pump();
    expect(lifecycle.barcodePropertyRenderPending, isFalse);
    expect(lifecycle.prepareForOwnerReplacement(), isTrue);
  });

  testWidgets('label sheet zoom toolbar placement can move or hide controls', (
    tester,
  ) async {
    const hostKey = ValueKey('zoom-placement-host');
    const zoomInputKey = ValueKey('label-sheet-zoom-input');

    void expectZoomInputContentOffset() {
      final zoomInputFinder = find.byKey(zoomInputKey);
      final zoomInput = tester.widget<EditableText>(zoomInputFinder);
      expect(zoomInput.cursorOffset, Offset.zero);
      final ancestorPadding = tester
          .widgetList<Padding>(
            find.ancestor(of: zoomInputFinder, matching: find.byType(Padding)),
          )
          .map((padding) => padding.padding);
      expect(ancestorPadding, contains(const EdgeInsets.fromLTRB(5, 6, 5, 4)));
    }

    Widget buildWorkbench(LabelSheetZoomToolbarPlacement placement) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: SizedBox(
              key: hostKey,
              width: 420,
              height: 260,
              child: LabelSheetWorkbench(
                initialWorkbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 's1', name: 'Label')],
                ),
                zoomToolbarPlacement: placement,
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      buildWorkbench(LabelSheetZoomToolbarPlacement.previewTabAreaEnd),
    );
    await tester.pump();
    await tester.pump();

    final hostTop = tester.getTopLeft(find.byKey(hostKey)).dy;
    final zoomTop = tester.getTopLeft(find.byKey(zoomInputKey)).dy;
    expect(zoomTop, lessThan(hostTop));
    expectZoomInputContentOffset();

    await tester.pumpWidget(
      buildWorkbench(LabelSheetZoomToolbarPlacement.sheetToolbarEnd),
    );
    await tester.pump();

    expectZoomInputContentOffset();

    await tester.pumpWidget(
      buildWorkbench(LabelSheetZoomToolbarPlacement.hidden),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('label-sheet-zoom-input')), findsNothing);
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
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 360,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [
                  FortuneSheet(
                    id: 's1',
                    name: 'Label',
                    lines: const [
                      FortuneLine(id: 'line_1', x1: 20, y1: 20, x2: 80, y2: 20),
                    ],
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );
    expect(find.text('프린터 설정'), findsOneWidget);
    expect(find.text('프린터 선택'), findsOneWidget);
    expect(find.text('발행'), findsOneWidget);
    expect(find.text('적용'), findsOneWidget);
    expect(_printDialogCloseButtonFinder(), findsOneWidget);
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

    await tester.tap(_printDialogCloseButtonFinder());
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsNothing,
    );
  });

  testWidgets('label sheet print dialog clears toolbar tooltip hover', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

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

    final sheetTopLeft = tester.getTopLeft(find.byType(FortuneSheetApp));
    await tester.sendEventToBinding(
      PointerHoverEvent(
        position:
            sheetTopLeft +
            _toolbarItemCenter(
              labelSheetPrintToolbarCommand,
              width: 600,
              items: labelSheetToolbarItems,
            ),
      ),
    );
    await tester.pump();

    expect(
      _currentFortunePainter(tester).toolbarHoveredKey,
      labelSheetPrintToolbarCommand,
    );

    final printItem = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .settings!
        .customToolbarItems
        .singleWhere((item) => item.key == labelSheetPrintToolbarCommand);
    printItem.onClick!(printItem);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );
    expect(_currentFortunePainter(tester).toolbarHoveredKey, isNull);
  });

  testWidgets('label sheet print dialog restores saved preferred settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Stored Printer',
      labelSheetPreferredPrintLeftMarginPrefsKey: '1.5',
      labelSheetPreferredPrintTopMarginPrefsKey: '2.5',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '120',
      labelSheetPreferredPrintExtraAreaPrefsKey: '3.5',
      labelSheetPreferredPrintOrientationPrefsKey: 'vertical',
    });

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
              printerListProvider: () async => const <Printer>[
                Printer(url: 'stored', name: 'Stored Printer'),
              ],
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );
    expect(find.text('Stored Printer'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(_editableTextValues(tester), containsAll(['1.5', '2.5', '3.5']));
    expect(_editableTextValues(tester), contains('1'));
  });

  testWidgets('label sheet print dialog saves settings only on apply', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      labelSheetPreferredPrinterNamePrefsKey: 'Stored Printer',
      labelSheetPreferredPrintAutoSpacingPrefsKey: '120',
    });

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
              printerListProvider: () async => const <Printer>[
                Printer(url: 'stored', name: 'Stored Printer'),
              ],
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
    await tester.pump();

    await tester.tap(find.text('120'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('300'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('300'));
    await tester.pumpAndSettle();

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey), '120');

    await tester.tap(find.text('적용'));
    await tester.pump();

    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(labelSheetPreferredPrintAutoSpacingPrefsKey), '300');
  });

  testWidgets('label sheet print dialog waits for lifecycle callback', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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
              onBeforeSheetDialog: () {
                events.add('before');
                return beforeCompleter.future;
              },
              onSheetDialogClosed: () {
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );

    await tester.tap(_printDialogCloseButtonFinder());
    await tester.pump();

    expect(events, ['before', 'closed']);
  });

  testWidgets('label sheet print dialog traps tab focus inside dialog', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
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

  testWidgets('label sheet print dialog blocks taps outside workbench', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var outsideTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                height: 72,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => outsideTapCount += 1,
                  child: const Center(child: Text('outside workbench')),
                ),
              ),
              Expanded(
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [FortuneSheet(id: 's1', name: 'Label')],
                  ),
                ),
              ),
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-print-settings-dialog')),
      findsOneWidget,
    );

    await tester.tap(find.text('outside workbench'), warnIfMissed: false);
    await tester.pump();

    expect(outsideTapCount, 0);
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
                return LabelSheetSaveResult.applied;
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

  testWidgets('label sheet zoom toolbar reflects loaded workbook zoom', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 320,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label', zoomRatio: 1.5)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final zoomInput = find.byKey(const ValueKey('label-sheet-zoom-input'));
    expect(zoomInput, findsOneWidget);
    expect(tester.widget<EditableText>(zoomInput).controller.text, '150');
  });

  testWidgets('label sheet zoom survives parent layout rebuild', (
    tester,
  ) async {
    late StateSetter setHostState;
    var width = 520.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return SizedBox(
                width: width,
                height: 320,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [FortuneSheet(id: 's1', name: 'Label')],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final zoomInput = find.byKey(const ValueKey('label-sheet-zoom-input'));
    await tester.tap(find.text('+'));
    await tester.pump();
    expect(tester.widget<EditableText>(zoomInput).controller.text, '110');

    setHostState(() => width = 640);
    await tester.pump();

    expect(tester.widget<EditableText>(zoomInput).controller.text, '110');
  });

  testWidgets('object panel separators align with sheet header boundaries', (
    tester,
  ) async {
    const toolbarHeight = 47.0;
    const columnHeaderHeight = 23.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 450,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                settings: const FortuneSettings(
                  toolbarHeight: toolbarHeight,
                  columnHeaderHeight: columnHeaderHeight,
                ),
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetRect = tester.getRect(find.byType(FortuneSheetApp));
    final titleRect = tester.getRect(
      find.byKey(const ValueKey('fortune-object-panel-header')),
    );
    final toolbarRect = tester.getRect(
      find.byKey(const ValueKey('fortune-object-panel-action-toolbar')),
    );
    expect(titleRect.top, sheetRect.top);
    expect(titleRect.bottom, sheetRect.top + toolbarHeight);
    expect(toolbarRect.top, titleRect.bottom);
    expect(
      toolbarRect.bottom,
      sheetRect.top + toolbarHeight + columnHeaderHeight * 2,
    );
  });

  testWidgets('object panel callbacks toggle dock panel and active state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 450,
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

    expect(find.byType(FortuneObjectLayerPanel), findsOneWidget);
    expect(
      _currentFortunePainter(tester).toolbarActiveKeys,
      contains(fortuneToolbarObjectPanelCommand),
    );

    tester
      .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
      .onCloseObjectPanelRequest!();
    await tester.pumpAndSettle();

    expect(find.byType(FortuneObjectLayerPanel), findsNothing);
    expect(
      _currentFortunePainter(tester).toolbarActiveKeys,
      isNot(contains(fortuneToolbarObjectPanelCommand)),
    );

    tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .onOpenObjectPanelRequest!(
          const FortuneObjectPanelOpenRequest(
            sheetId: 's1',
            objectKey: null,
            propertyField: null,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.byType(FortuneObjectLayerPanel), findsOneWidget);
    expect(
      _currentFortunePainter(tester).toolbarActiveKeys,
      contains(fortuneToolbarObjectPanelCommand),
    );
  });

  testWidgets('narrow object overlay caps at 300 within safe insets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              height: 320,
              child: LabelSheetWorkbench(
                initialWorkbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 's1', name: 'Label')],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final hiddenPanel = find.byType(
      FortuneObjectLayerPanel,
      skipOffstage: false,
    );
    final panelState = tester.state(hiddenPanel);
    tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .onOpenObjectPanelRequest!(
          const FortuneObjectPanelOpenRequest(
            sheetId: 's1',
            objectKey: null,
            propertyField: null,
          ),
        );
    await tester.pump();

    final rect = tester.getRect(find.byType(FortuneObjectLayerPanel));
    final sheetPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    expect(tester.takeException(), isNull);
    expect(
      sheetPainter.toolbarActiveKeys,
      contains(fortuneToolbarObjectPanelCommand),
    );
    expect(
      tester.state(find.byType(FortuneObjectLayerPanel)),
      same(panelState),
    );
    expect(rect.left, 12);
    expect(rect.right, 312);
    expect(rect.width, 300);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    final closedSheetPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .single;
    expect(
      closedSheetPainter.toolbarActiveKeys,
      isNot(contains(fortuneToolbarObjectPanelCommand)),
    );
  });

  testWidgets('narrow object overlay shrinks below 220 without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 216,
              height: 320,
              child: LabelSheetWorkbench(
                initialWorkbook: FortuneWorkbook(
                  sheets: [FortuneSheet(id: 's1', name: 'Label')],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .onOpenObjectPanelRequest!(
          const FortuneObjectPanelOpenRequest(
            sheetId: 's1',
            objectKey: null,
            propertyField: null,
          ),
        );
    await tester.pump();

    final rect = tester.getRect(find.byType(FortuneObjectLayerPanel));
    expect(rect.left, 8);
    expect(rect.right, 208);
    expect(rect.width, 200);
  });

  testWidgets('closing object overlay returns property focus to canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 500,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [
                  FortuneSheet(
                    id: 's1',
                    name: 'Label',
                    lines: const [
                      FortuneLine(id: 'line_1', x1: 20, y1: 20, x2: 80, y2: 20),
                    ],
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

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.controller!.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    final propertyField = find.byKey(
      const ValueKey('fortune-object-property-x1'),
    );
    await tester.tap(propertyField);
    await tester.pump();
    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneObjectLayerPanel)),
      isTrue,
    );

    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();
    await tester.pump();

    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneSheetCanvas)),
      isTrue,
    );
  });

  testWidgets('narrow object overlay focuses layers and restores prior focus', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    externalFocus.requestFocus();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.controller!.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(externalFocus.hasFocus, isFalse);
    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneObjectLayerPanel)),
      isTrue,
    );

    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();
    await tester.pump();

    expect(externalFocus.hasFocus, isTrue);
  });

  testWidgets('narrow object overlay close restores host open trigger first', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    externalFocus.requestFocus();
    await tester.pump();
    await tester.tap(find.byTooltip('개체 패널 열기'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FortuneObjectLayerPanel), findsOneWidget);
    expect(externalFocus.hasFocus, isFalse);

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    final openButtonFocus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.layers_outlined),
    ).focusNode!;
    expect(openButtonFocus.hasFocus, isTrue);
    expect(externalFocus.hasFocus, isFalse);
  });

  testWidgets('closing overlay cancels pending property focus', (tester) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    externalFocus.requestFocus();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    const objectKey = FortuneSheetObjectKey(
      FortuneSheetObjectKind.line,
      'line_1',
    );
    sheetApp.controller!.selectObject(objectKey);
    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: objectKey,
        propertyField: 'x1',
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(FortuneObjectLayerPanel), findsNothing);
    expect(externalFocus.hasFocus, isTrue);
  });

  testWidgets(
    'narrow edit overlay close restores the latest trigger focus after prior dock close',
    (tester) async {
      final originalFocus = FocusNode();
      final latestTriggerFocus = FocusNode();
      var workbenchWidth = 600.0;
      late StateSetter setHostState;
      addTearDown(originalFocus.dispose);
      addTearDown(latestTriggerFocus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return Column(
                  children: [
                    TextButton(
                      focusNode: originalFocus,
                      onPressed: () {},
                      child: const Text('original trigger'),
                    ),
                    TextButton(
                      focusNode: latestTriggerFocus,
                      onPressed: () {},
                      child: const Text('latest trigger'),
                    ),
                    SizedBox(
                      width: workbenchWidth,
                      height: 450,
                      child: LabelSheetWorkbench(
                        initialWorkbook: FortuneWorkbook(
                          sheets: [
                            FortuneSheet(
                              id: 's1',
                              name: 'Label',
                              lines: const [
                                FortuneLine(
                                  id: 'line_1',
                                  x1: 20,
                                  y1: 20,
                                  x2: 80,
                                  y2: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final workbench = find.byType(LabelSheetWorkbench);
      final sheetAppFinder = find.byType(FortuneSheetApp);
      FortuneSheetApp sheetApp() => tester.widget<FortuneSheetApp>(sheetAppFinder);

      sheetApp().controller!.selectObject(
        const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
      );

      originalFocus.requestFocus();
      await tester.pump();
      sheetApp().onOpenObjectPanelRequest!(
        const FortuneObjectPanelOpenRequest(
          sheetId: 's1',
          objectKey: null,
          propertyField: null,
        ),
      );
      await tester.pump();
      await tester.pump();

      setHostState(() {
        workbenchWidth = 1000;
      });
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byTooltip('닫기'));
      await tester.pump();
      await tester.pump();

      setHostState(() {
        workbenchWidth = 500;
      });
      await tester.pumpAndSettle();

      expect(find.byType(VerticalPaneSplitter), findsNothing);

      latestTriggerFocus.requestFocus();
      await tester.pump();

      sheetApp().onOpenObjectPanelRequest!(
        const FortuneObjectPanelOpenRequest(
          sheetId: 's1',
          objectKey: FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
          propertyField: 'x1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.descendant(of: workbench, matching: find.byType(FortuneObjectLayerPanel)), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(latestTriggerFocus.hasFocus, isTrue);
      expect(originalFocus.hasFocus, isFalse);
    },
  );

  testWidgets('generic object panel request opens overlay and focuses layer list', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    externalFocus.requestFocus();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.controller!.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    await tester.pump();
    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(FortuneObjectLayerPanel), findsOneWidget);
    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneObjectLayerPanel)),
      isTrue,
    );
  });

  testWidgets('wide dock generic open request is no-op when panel is already open', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 1000,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.controller!.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    await tester.pump();

    externalFocus.requestFocus();
    await tester.pump();

    expect(find.byType(VerticalPaneSplitter), findsOneWidget);
    expect(externalFocus.hasFocus, isTrue);

    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(externalFocus.hasFocus, isTrue);
    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneObjectLayerPanel)),
      isFalse,
    );
  });

  testWidgets('narrow overlay generic open request is no-op while property field is focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 500,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [
                  FortuneSheet(
                    id: 's1',
                    name: 'Label',
                    lines: const [
                      FortuneLine(id: 'line_1', x1: 20, y1: 20, x2: 80, y2: 20),
                    ],
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

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    sheetApp.controller!.selectObject(
      const FortuneSheetObjectKey(FortuneSheetObjectKind.line, 'line_1'),
    );
    await tester.pump();

    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    await tester.pump();

    final propertyField = find.byKey(
      const ValueKey('fortune-object-property-x1'),
    );
    await tester.tap(propertyField);
    await tester.pump();

    final fieldFocusNode = tester.widget<TextField>(propertyField).focusNode!;
    expect(fieldFocusNode.hasFocus, isTrue);

    sheetApp.onOpenObjectPanelRequest!(
      const FortuneObjectPanelOpenRequest(
        sheetId: 's1',
        objectKey: null,
        propertyField: null,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(fieldFocusNode.hasFocus, isTrue);
    expect(find.byType(FortuneObjectLayerPanel), findsOneWidget);
  });

  testWidgets('wide dock close request is no-op when panel is already hidden', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 1000,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    externalFocus.requestFocus();
    await tester.pump();

    await tester.tap(find.byTooltip('닫기'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(VerticalPaneSplitter), findsNothing);
    expect(externalFocus.hasFocus, isTrue);

    final hiddenPanel = tester.widget<FortuneObjectLayerPanel>(
      find.byType(FortuneObjectLayerPanel, skipOffstage: false),
    );
    hiddenPanel.onClose!.call();
    await tester.pump();
    await tester.pump();

    expect(find.byType(VerticalPaneSplitter), findsNothing);
    expect(find.byType(FortuneObjectLayerPanel), findsNothing);
    expect(externalFocus.hasFocus, isTrue);
  });

  testWidgets('narrow overlay close request is no-op when panel is already hidden', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    externalFocus.requestFocus();
    await tester.pump();

    tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .onOpenObjectPanelRequest!(
          const FortuneObjectPanelOpenRequest(
            sheetId: 's1',
            objectKey: null,
            propertyField: null,
          ),
        );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(find.byType(FortuneObjectLayerPanel), findsNothing);
    expect(externalFocus.hasFocus, isTrue);

    final hiddenPanel = tester.widget<FortuneObjectLayerPanel>(
      find.byType(FortuneObjectLayerPanel, skipOffstage: false),
    );
    hiddenPanel.onClose!.call();
    await tester.pump();
    await tester.pump();

    expect(find.byType(FortuneObjectLayerPanel), findsNothing);
    expect(externalFocus.hasFocus, isTrue);
  });

  testWidgets('canvas-owned open request restores canvas on overlay close', (
    tester,
  ) async {
    final externalFocus = FocusNode();
    addTearDown(externalFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: externalFocus),
              SizedBox(
                width: 600,
                height: 450,
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 's1',
                        name: 'Label',
                        lines: const [
                          FortuneLine(
                            id: 'line_1',
                            x1: 20,
                            y1: 20,
                            x2: 80,
                            y2: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    externalFocus.requestFocus();
    await tester.pump();

    tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .onOpenObjectPanelRequest!(
          const FortuneObjectPanelOpenRequest(
            sheetId: 's1',
            objectKey: null,
            propertyField: null,
            closeFocusTarget: FortuneObjectPanelCloseFocusTarget.canvas,
          ),
        );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    expect(
      _primaryFocusIsInside(tester, find.byType(FortuneSheetCanvas)),
      isTrue,
    );
    expect(externalFocus.hasFocus, isFalse);
  });

  testWidgets('object panel width persists drag then reset in order', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 500,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final splitter = find.byType(VerticalPaneSplitter);
    await tester.drag(splitter, const Offset(-120, 0));
    await tester.pumpAndSettle();
    var preferences = await SharedPreferences.getInstance();
    final draggedWidth = tester
        .getSize(find.byType(FortuneObjectLayerPanel))
        .width;
    expect(draggedWidth, isNot(300));
    expect(
      preferences.getDouble('label_sheet_object_panel_width'),
      draggedWidth,
    );

    final splitterCenter = tester.getCenter(splitter);
    await tester.tapAt(splitterCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(splitterCenter);
    await tester.pumpAndSettle();
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getDouble('label_sheet_object_panel_width'), 300);
  });

  testWidgets('constrained object panel starts drag from its visible width', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'label_sheet_object_panel_width': 420.0,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 500,
            child: LabelSheetWorkbench(
              initialWorkbook: FortuneWorkbook(
                sheets: [FortuneSheet(id: 's1', name: 'Label')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byType(FortuneObjectLayerPanel);
    expect(tester.getSize(panel).width, 312);

    await tester.drag(find.byType(VerticalPaneSplitter), const Offset(30, 0));
    await tester.pumpAndSettle();

    expect(tester.getSize(panel).width, 302);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getDouble('label_sheet_object_panel_width'), 302);
  });

  testWidgets('narrow-start workbench preserves saved dock width for wide restore', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'label_sheet_object_panel_width': 420.0,
    });
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var width = 600.0;
    late StateSetter setHostState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 500,
                  child: LabelSheetWorkbench(
                    initialWorkbook: FortuneWorkbook(
                      sheets: [FortuneSheet(id: 's1', name: 'Label')],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VerticalPaneSplitter), findsNothing);
    expect(find.byTooltip('개체 패널 열기'), findsOneWidget);

    setHostState(() {
      width = 1000;
    });
    await tester.pumpAndSettle();

    expect(find.byType(VerticalPaneSplitter), findsOneWidget);
    expect(tester.getSize(find.byType(FortuneObjectLayerPanel)).width, 420);

    setHostState(() {
      width = 600;
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(VerticalPaneSplitter), findsNothing);
    expect(find.byTooltip('개체 패널 열기'), findsOneWidget);
  });

  testWidgets('external zoom toolbar controls label sheet', (tester) async {
    final zoomController = LabelSheetZoomController();
    addTearDown(zoomController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [FortuneSheet(id: 's1', name: 'Label')],
                  ),
                  zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
                  zoomController: zoomController,
                ),
              ),
              LabelSheetZoomToolbar(controller: zoomController),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('+'));
    await tester.pump();

    expect(zoomController.value, 110);
    expect(
      tester
          .widget<EditableText>(
            find.byKey(const ValueKey('label-sheet-zoom-input')),
          )
          .controller
          .text,
      '110',
    );
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
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: LabelSheetPage(
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

  testWidgets('label sheet reports ready when RTF import falls back', (
    tester,
  ) async {
    var readyCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          labelSheetNativeOpenXmlChannel,
          (_) async => null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(labelSheetNativeOpenXmlChannel, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: LabelSheetPage(
              labelSize: LabelSize(
                labelSizeId: 1,
                brandId: 1,
                labelSizeName: 'Legacy',
                labelSizeCommon: LabelSizeCommon(
                  width: 100,
                  height: 60,
                  rtf: r'{\rtf1\ansi}',
                ),
              ),
              onSheetReady: () => readyCount += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(readyCount, 1);
    final workbook = tester
        .widget<FortuneSheetApp>(find.byType(FortuneSheetApp))
        .workbook!;
    expect(
      workbook.sheets.single.extraFields['labelRtfImportSource'],
      isNot(true),
    );
  });

  testWidgets('fortune sheet page gives hidden footer height to the grid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 400, height: 300, child: LabelSheetPage()),
      ),
    );
    await tester.pump();

    final sheetApp = tester.widget<FortuneSheetApp>(
      find.byType(FortuneSheetApp),
    );
    final sheetPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<FortuneSheetPainter>()
        .first;
    expect(sheetApp.showSheetTabs, isFalse);
    expect(sheetPainter.workbook.settings.effectiveSheetBarHeight, 0);
    expect(sheetPainter.workbook.settings.statisticBarHeight, 0);
  });

  testWidgets(
    'fortune sheet page ignores zero label size during initial load',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: LabelSheetPage(
              labelSize: const LabelSize(
                labelSizeId: 1,
                brandId: 1,
                labelSizeName: 'Zero',
                labelSizeCommon: LabelSizeCommon(width: 0, height: 0, rtf: ''),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final sheetApp = tester.widget<FortuneSheetApp>(
        find.byType(FortuneSheetApp),
      );
      expect(sheetApp.gridClientSize?.widthMm, 100);
      expect(sheetApp.gridClientSize?.heightMm, 100);
    },
  );

  test('label sheet required keywords search cells images and barcodes', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Required',
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: '#ITEMNAME'),
          },
          images: const [
            FortuneImage(
              id: 'img1',
              src: 'data:image/png;base64,AA==',
              left: 0,
              top: 0,
              width: 10,
              height: 10,
              extraFields: {fortuneImageObjectIdExtraKey: '#IMAGEKEY'},
            ),
            FortuneImage(
              id: 'barcode1',
              src: 'data:image/png;base64,AA==',
              left: 0,
              top: 0,
              width: 10,
              height: 10,
              extraFields: {
                'fortuneBarcode': true,
                fortuneBarcodeObjectIdExtraKey: '#BARCODEKEY',
              },
            ),
          ],
        ),
      ],
    );

    final missing = labelSheetMissingRequiredKeywordNamesInWorkbook(workbook, [
      const LabelSheetRequiredKeyword(keyword: 'ITEMNAME', itemName: '품명'),
      const LabelSheetRequiredKeyword(keyword: 'IMAGEKEY', itemName: '이미지'),
      const LabelSheetRequiredKeyword(keyword: 'BARCODEKEY', itemName: '바코드'),
      const LabelSheetRequiredKeyword(keyword: 'PRICE', itemName: '가격'),
    ]);

    expect(missing, ['가격']);
  });

  test(
    'item output excludes unresolved linked images but keeps fixed images',
    () {
      const fixedImage = FortuneImage(
        id: 'fixed',
        src: 'data:image/png;base64,AA==',
        left: 0,
        top: 0,
        width: 10,
        height: 10,
      );
      final workbook = FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 's1',
            name: 'Images',
            images: const [
              FortuneImage(
                id: 'empty-linked',
                src: 'data:image/png;base64,AA==',
                left: 0,
                top: 0,
                width: 10,
                height: 10,
                extraFields: {fortuneImageObjectIdExtraKey: '#EMPTY_IMAGE'},
              ),
              FortuneImage(
                id: 'missing-linked',
                src: 'data:image/png;base64,AA==',
                left: 0,
                top: 0,
                width: 10,
                height: 10,
                extraFields: {fortuneImageObjectIdExtraKey: '#MISSING_IMAGE'},
              ),
              fixedImage,
            ],
          ),
        ],
      );

      final materialized = debugMaterializeItemImagesForTesting(workbook, {
        '#EMPTY_IMAGE': '',
        '#MISSING_IMAGE': '__label_manager_missing_image__',
      });

      final images = materialized.sheets.single.images;
      expect(images, hasLength(1));
      expect(images.single.id, fixedImage.id);
      expect(images.single.src, fixedImage.src);
      expect(
        images.single.extraFields.containsKey(fortuneImageObjectIdExtraKey),
        isFalse,
      );
    },
  );

  test('Gemini model menu includes supported model choices', () {
    final modelIds = labelSheetGeminiModels
        .map((model) => model.modelId)
        .toSet();

    expect(modelIds, contains('gemini-2.5-flash'));
    expect(modelIds, contains('gemini-2.5-pro'));
    expect(modelIds, contains('gemini-2.0-flash'));
  });

  test('Gemini model list is fetched from Google AI models API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(request.url.path, '/v1beta/models');
      expect(request.url.queryParameters['key'], 'test-api-key-1234');
      return http.Response(
        jsonEncode({
          'models': [
            {
              'name': 'models/gemini-2.5-flash',
              'displayName': 'Gemini 2.5 Flash',
              'supportedGenerationMethods': ['generateContent'],
            },
            {
              'name': 'models/gemma-3-27b-it',
              'displayName': 'Gemma 3 27B',
              'supportedGenerationMethods': ['generateContent'],
            },
            {
              'name': 'models/gemini-3.5-pro',
              'displayName': 'Gemini 3.5 Pro',
              'supportedGenerationMethods': ['generateContent'],
            },
            {
              'name': 'models/gemini-embed-text',
              'displayName': 'Gemini Embedding',
              'supportedGenerationMethods': ['embedContent'],
            },
            {
              'name': 'models/gemma-2-9b-it',
              'displayName': 'Gemma 2 9B',
              'supportedGenerationMethods': ['generateContent'],
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final models = await labelSheetFetchGeminiModels(
      apiKey: 'test-api-key-1234',
      client: client,
    );

    expect(models.map((model) => model.modelId), [
      'gemini-3.5-pro',
      'gemini-2.5-flash',
      'gemma-3-27b-it',
      'gemma-2-9b-it',
    ]);
    expect(models.first.menuLabel, 'Gemini 3.5 Pro · Google AI');
  });

  test('label image import preview scales to readable text size', () {
    final viewportHeight =
        labelSheetImageImportPreviewHeight -
        (labelSheetImageImportPreviewPadding * 2);
    final smallReadableLayout = labelSheetImageImportPreviewLayout(
      imageWidth: 200,
      imageHeight: 200,
      viewportWidth: 616,
      viewportHeight: viewportHeight,
      physicalSize: const FortuneSheetGridClientPhysicalSize(
        widthMm: 100,
        heightMm: 100,
      ),
    );

    expect(smallReadableLayout.usesReadableScale, isTrue);
    expect(smallReadableLayout.height, greaterThan(viewportHeight));

    final sufficientlyReadableLayout = labelSheetImageImportPreviewLayout(
      imageWidth: 1200,
      imageHeight: 600,
      viewportWidth: 616,
      viewportHeight: viewportHeight,
      physicalSize: const FortuneSheetGridClientPhysicalSize(
        widthMm: 100,
        heightMm: 50,
      ),
    );

    expect(sufficientlyReadableLayout.usesReadableScale, isFalse);
    expect(sufficientlyReadableLayout.width, lessThanOrEqualTo(616));
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
    final nativeImages = <LabelSheetNativeRtfPngImage>[];
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
          onNativeImageResolved: nativeImages.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolvedSizes, contains(const Size(6, 6)));
    expect(nativeImages, hasLength(1));
    expect(nativeImages.single.width, 12);
    expect(nativeImages.single.height, 12);
    expect(nativeImages.single.scale, 2);
    expect(nativeImages.single.bytes, isNotEmpty);
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

  testWidgets('floating preview hide animation keeps child layout stable', (
    tester,
  ) async {
    final layoutSizes = <Size>[];
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: LayoutBuilder(
        builder: (context, constraints) {
          layoutSizes.add(Size(constraints.maxWidth, constraints.maxHeight));
          return const SizedBox.expand(key: ValueKey('floating-child'));
        },
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
    layoutSizes.clear();

    final hideFuture = window.hideToRect(const ui.Rect.fromLTWH(20, 20, 2, 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(layoutSizes, isNotEmpty);
    expect(
      layoutSizes.every((size) => size.width >= 80 && size.height >= 60),
      isTrue,
      reason: 'layoutSizes=$layoutSizes',
    );

    await tester.pump(const Duration(milliseconds: 200));
    await hideFuture;
    await tester.pump();
    expect(find.byKey(const ValueKey('floating-child')), findsNothing);
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
    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
      const Offset(30, 20),
    );
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

    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
      const Offset(0, 40),
    );
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

    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-top-right'),
      const Offset(20, -40),
    );
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

    final gesture = await tester.startGesture(
      _floatingResizeGripPoint(tester, 'floating-resize-top-right'),
    );
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

  testWidgets('floating preview top corner stays above zoom overlay', (
    tester,
  ) async {
    final window = PreviewFloatingWindow(
      initialSize: const Size(420, 260),
      child: LabelSheetWorkbench(
        initialWorkbook: FortuneWorkbook(
          sheets: [FortuneSheet(id: 's1', name: 'Label')],
        ),
        zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.previewTabAreaEnd,
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
    await tester.pump();

    expect(
      find.byKey(const ValueKey('label-sheet-zoom-input')),
      findsOneWidget,
    );
    final beforeRect = window.rect;

    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-top-right'),
      const Offset(20, -20),
    );
    await tester.pump();

    expect(window.rect.width, greaterThan(beforeRect.width));
    expect(window.rect.height, greaterThan(beforeRect.height));
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

    final gesture = await tester.startGesture(
      _floatingResizeGripPoint(tester, 'floating-resize-top-right'),
    );
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

    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
      const Offset(120, 80),
    );
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
    final gesture = await tester.startGesture(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
    );
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

  testWidgets('floating preview reports user move separately', (tester) async {
    ui.Rect? movedRect;
    final window = PreviewFloatingWindow(
      initialSize: const Size(120, 90),
      child: const SizedBox.expand(key: ValueKey('floating-child')),
      onMoved: (rect) {
        movedRect = rect;
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

    await tester.drag(
      find.byKey(const ValueKey('floating-move-handle')),
      const Offset(24, 16),
    );
    await tester.pump();

    expect(movedRect, isNotNull);
    expect(movedRect!.left, window.rect.left);
    expect(movedRect!.top, window.rect.top);
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
    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
      const Offset(120, 80),
    );
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
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
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

  testWidgets('floating preview corner resize ignores empty handle box area', (
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

    final beforeSize = window.rect.size;
    final handleCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-resize-bottom-right')),
    );
    await tester.dragFrom(handleCenter, const Offset(80, 60));
    await tester.pump();

    expect(window.rect.size, beforeSize);

    await tester.dragFrom(
      _floatingResizeGripPoint(tester, 'floating-resize-bottom-right'),
      const Offset(80, 60),
    );
    await tester.pump();

    expect(window.rect.width, greaterThan(beforeSize.width));
    expect(window.rect.height, greaterThan(beforeSize.height));
  });

  testWidgets('floating preview lets child scrollbars win over edge resize', (
    tester,
  ) async {
    var rightScrollbarDowns = 0;
    var bottomScrollbarDowns = 0;
    final window = PreviewFloatingWindow(
      initialSize: const Size(160, 120),
      child: Stack(
        key: const ValueKey('floating-scrollbar-child'),
        children: [
          Positioned(
            top: 20,
            right: 0,
            bottom: 20,
            width: 8,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => rightScrollbarDowns += 1,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            height: 8,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => bottomScrollbarDowns += 1,
            ),
          ),
        ],
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
    final beforeSize = window.rect.size;
    final childTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('floating-scrollbar-child')),
    );
    final childSize = tester.getSize(
      find.byKey(const ValueKey('floating-scrollbar-child')),
    );

    await tester.dragFrom(
      childTopLeft + Offset(childSize.width - 4, childSize.height / 2),
      const Offset(24, 0),
    );
    await tester.pump();

    expect(rightScrollbarDowns, 1);
    expect(window.rect.size, beforeSize);

    await tester.dragFrom(
      childTopLeft + Offset(childSize.width / 2, childSize.height - 4),
      const Offset(0, 24),
    );
    await tester.pump();

    expect(bottomScrollbarDowns, 1);
    expect(window.rect.size, beforeSize);
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

  test('Gemini prompt includes source aspect fit guidance', () {
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

    final prompt = labelSheetGeminiPrompt(
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

  test('Gemini JSON response is converted to a sheet draft', () async {
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
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(
        request.url.path,
        '/v1beta/models/gemini-2.5-flash:generateContent',
      );
      expect(request.url.queryParameters['key'], 'test-api-key-1234');
      expect(body['contents'], isA<List>());
      expect(
        body['generationConfig'],
        containsPair('responseMimeType', 'application/json'),
      );
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'columnsMm': [40, 60],
                      'rowsMm': [20, 40],
                      'cells': [
                        {'row': 0, 'column': 0, 'text': 'GEMINI'},
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
                ],
              },
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    final draft = await labelSheetAnalyzeImageWithGemini(
      LabelSheetGeminiImportRequest(
        apiKey: 'test-api-key-1234',
        model: 'gemini-2.5-flash',
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
    expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'GEMINI');
    expect(draft.images, isEmpty);
  });

  test('AI import temp directory uses .tmp in debug mode', () {
    final directory = labelSheetAiImportTempDirectory(
      debugMode: true,
      currentDirectoryPath: r'C:\Workspace\ITSnG\label_manager',
    );

    expect(
      p.normalize(directory.path),
      p.normalize(r'C:\Workspace\ITSnG\label_manager\.tmp'),
    );
  });

  test('AI import temp directory uses app data temp in release mode', () {
    final directory = labelSheetAiImportTempDirectory(
      debugMode: false,
      environment: const {'APPDATA': r'C:\Users\tester\AppData\Roaming'},
    );

    expect(
      p.normalize(directory.path),
      p.normalize(
        r'C:\Users\tester\AppData\Roaming\com.itsng\Label Manager\temp',
      ),
    );
  });

  test('AI import startup cleanup clears release temp contents', () async {
    final root = await Directory.systemTemp.createTemp(
      'label_manager_ai_import_temp_test_',
    );
    try {
      final appData = Directory(p.join(root.path, 'Roaming'));
      final environment = {'APPDATA': appData.path};
      final tempDirectory = labelSheetAiImportReleaseTempDirectory(
        environment: environment,
      );
      await File(
        p.join(tempDirectory.path, 'old.xlsx'),
      ).create(recursive: true);
      await File(
        p.join(tempDirectory.path, 'nested', 'old.txt'),
      ).create(recursive: true);

      await clearLabelSheetAiImportStartupTempDirectory(
        environment: environment,
      );

      expect(await tempDirectory.exists(), isTrue);
      expect(await tempDirectory.list().toList(), isEmpty);
    } finally {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    }
  });

  test(
    'Gemini request keeps OCR-sized source images without upload compression',
    () async {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Label',
        extraFields: const {
          fortuneSheetGridClientWidthMmKey: 100,
          fortuneSheetGridClientHeightMmKey: 60,
        },
      );
      final sourceImage = imglib.Image(width: 2400, height: 1200)
        ..clear(imglib.ColorRgb8(255, 255, 255));
      final sourceBytes = Uint8List.fromList(imglib.encodePng(sourceImage));
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        final contents = body['contents'] as List;
        final parts = (contents.single as Map)['parts'] as List;
        final inlineData = (parts.last as Map)['inlineData'] as Map;
        expect(inlineData['mimeType'], 'image/png');
        final uploadedBytes = base64Decode(inlineData['data'] as String);
        expect(uploadedBytes, sourceBytes);
        final uploadedImage = imglib.decodeImage(uploadedBytes)!;
        expect(uploadedImage.width, 2400);
        expect(uploadedImage.height, 1200);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'columnsMm': [100],
                        'rowsMm': [60],
                        'cells': [
                          {'row': 0, 'column': 0, 'text': 'KEPT'},
                        ],
                        'sourceImage': {'keep': false},
                      }),
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      final draft = await labelSheetAnalyzeImageWithGemini(
        LabelSheetGeminiImportRequest(
          apiKey: 'test-api-key-1234',
          model: 'gemini-2.5-flash',
          prompt: '',
          imageBytes: sourceBytes,
          mimeType: 'image/png',
          fileName: 'large-label.png',
          sheet: sheet,
          client: client,
        ),
      );

      expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'KEPT');
    },
  );

  test('Gemini request downsizes oversized source images for upload', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final sourceImage = imglib.Image(width: 3200, height: 1600)
      ..clear(imglib.ColorRgb8(255, 255, 255));
    final sourceBytes = Uint8List.fromList(imglib.encodePng(sourceImage));
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map;
      final contents = body['contents'] as List;
      final parts = (contents.single as Map)['parts'] as List;
      final inlineData = (parts.last as Map)['inlineData'] as Map;
      expect(inlineData['mimeType'], 'image/jpeg');
      final uploadedBytes = base64Decode(inlineData['data'] as String);
      final uploadedImage = imglib.decodeImage(uploadedBytes)!;
      expect(uploadedImage.width, 2400);
      expect(uploadedImage.height, 1200);
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'columnsMm': [100],
                      'rowsMm': [60],
                      'cells': [
                        {'row': 0, 'column': 0, 'text': 'DOWNSIZED'},
                      ],
                      'sourceImage': {'keep': false},
                    }),
                  },
                ],
              },
            },
          ],
        }),
        200,
      );
    });

    final draft = await labelSheetAnalyzeImageWithGemini(
      LabelSheetGeminiImportRequest(
        apiKey: 'test-api-key-1234',
        model: 'gemini-2.5-flash',
        prompt: '',
        imageBytes: sourceBytes,
        mimeType: 'image/png',
        fileName: 'large-label.png',
        sheet: sheet,
        client: client,
      ),
    );

    expect(draft.cells[const FortuneCellCoord(0, 0)]?.value, 'DOWNSIZED');
  });

  test('Gemini image-only response is rejected', () async {
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
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
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
                ],
              },
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });

    await expectLater(
      labelSheetAnalyzeImageWithGemini(
        LabelSheetGeminiImportRequest(
          apiKey: 'test-api-key-1234',
          model: 'gemini-2.5-flash',
          prompt: 'convert',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          fileName: 'label.png',
          sheet: sheet,
          client: client,
        ),
      ),
      throwsA(
        isA<LabelSheetGeminiImportException>().having(
          (error) => error.message,
          'message',
          contains('편집 가능한 셀이 없습니다'),
        ),
      ),
    );
  });

  test('Gemini HTTP errors include response diagnostics', () async {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Label',
      extraFields: const {
        fortuneSheetGridClientWidthMmKey: 100,
        fortuneSheetGridClientHeightMmKey: 60,
      },
    );
    final client = MockClient((request) async {
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(
        request.url.path,
        '/v1beta/models/gemini-2.5-flash:generateContent',
      );
      expect(request.url.queryParameters['key'], 'test-api-key-1234');
      expect(request.headers, isNot(contains('Authorization')));
      return http.Response(
        jsonEncode({
          'error': {
            'code': 429,
            'status': 'RESOURCE_EXHAUSTED',
            'message': 'Quota exceeded for Gemini API.',
          },
        }),
        429,
        headers: const {'content-type': 'application/json'},
      );
    });

    await expectLater(
      labelSheetAnalyzeImageWithGemini(
        LabelSheetGeminiImportRequest(
          apiKey: 'test-api-key-1234',
          model: 'gemini-2.5-flash',
          prompt: 'convert',
          imageBytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          fileName: 'label.png',
          sheet: sheet,
          client: client,
        ),
      ),
      throwsA(
        isA<LabelSheetGeminiImportException>()
            .having((error) => error.message, 'message', contains('HTTP 429'))
            .having(
              (error) => error.message,
              'message',
              contains('RESOURCE_EXHAUSTED'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Quota exceeded for Gemini API.'),
            ),
      ),
    );
  });
}
