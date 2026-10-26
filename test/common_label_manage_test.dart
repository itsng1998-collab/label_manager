import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as image;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:label_manager/features/item/application/item_image_preview.dart';
import 'package:label_manager/features/label_sheet/application/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/application/common_label_connections.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';
import 'package:label_manager/features/label_column/application/special_columns.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/features/label_sheet/presentation/common_label_manage.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_page.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/features/label_sheet/presentation/label_sheet_settings.dart';
import 'package:label_manager/features/nutrition/application/nutrition_table_columns.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_box.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_type.dart';

class _RecordingKeywordInsertController
    extends LabelSheetKeywordInsertController {
  String? insertedText;

  @override
  bool insertAtCurrentContext(String text) {
    insertedText = text;
    return true;
  }
}

  FortuneSheetPainter _sheetPainter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<FortuneSheetPainter>()
      .single;

  Future<void> _waitForImage(WidgetTester tester, String src) async {
    await tester.runAsync(() async {
      final deadline = Stopwatch()..start();
      while (!_sheetPainter(tester).decodedImages.containsKey(src)) {
        if (deadline.elapsed > const Duration(seconds: 3)) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    expect(_sheetPainter(tester).decodedImages, contains(src));
  }

  Future<int> _greenPixels(WidgetTester tester) async {
    final paint = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).singleWhere(
      (widget) => widget.painter is FortuneSheetPainter,
    );
    final size = tester.getSize(find.byWidget(paint));
    return (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      paint.painter!.paint(ui.Canvas(recorder), size);
      final picture = recorder.endRecording();
      final bitmap = await picture.toImage(size.width.ceil(), size.height.ceil());
      final bytes = (await bitmap.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      var count = 0;
      for (var offset = 0; offset < bytes.lengthInBytes; offset += 4) {
        if (bytes.getUint8(offset) == 0 &&
            bytes.getUint8(offset + 1) == 255 &&
            bytes.getUint8(offset + 2) == 0) {
          count++;
        }
      }
      bitmap.dispose();
      picture.dispose();
      return count;
    }))!;
  }
TColumnBase _column(
  String keyword, {
  String? columnName,
  bool useMissingKeywordCheck = false,
  int typeCode = TColumnType.TYPE_BASE,
}) {
  return TColumnBase(
    columnType: TColumnType(
      code: typeCode,
      name: 'base',
      order: 0,
    ),
    keyword: keyword,
    columnName: columnName ?? keyword,
    useMissingKeywordCheck: useMissingKeywordCheck,
  );
}

TColumn _storedColumn(
  String keyword, {
  required int typeCode,
  String? columnName,
  BarcodeType barcodeType = BarcodeType.Code128,
  bool showBarcodeNum = false,
  int width = 0,
  int height = 0,
}) {
  return TColumn(
    columnType: TColumnType(code: typeCode, name: '항목', order: 0),
    keyword: keyword,
    columnName: columnName ?? keyword,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    columnId: 1,
    labelSizeId: 10,
    order: 1,
    width: width,
    height: height,
    barcodeType: barcodeType,
    useBarcodeCheckDigit: false,
    showBarcodeNum: showBarcodeNum,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: true,
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
    gs1ai: '',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

void main() {
  for (final outcome in ['success', 'duplicate', 'save-error']) {
    testWidgets('nutrition insertion updates common label keywords: $outcome', (tester) async {
      final oldColumns = TColumn.datas;
      final oldSpecials = TColumnSpecial.datas;
      final oldTypes = TColumnType.datas;
      addTearDown(() {
        TColumn.datas = oldColumns;
        TColumnSpecial.datas = oldSpecials;
        TColumnType.datas = oldTypes;
      });
      TColumn.datas = outcome == 'duplicate'
          ? [_storedColumn('N01', typeCode: TColumnType.TYPE_NUT)]
          : [];
      TColumnSpecial.datas = [];
      TColumnType.datas = const [
        TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 0),
        TColumnType(code: TColumnType.TYPE_NUT, name: '영양성분', order: 8),
      ];
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final template = labelSheetEncodeWorkbookSave(FortuneWorkbook(sheets: [
        FortuneSheet(id: 'nutrition', name: 'Nutrition', cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: '영양정보 #N16 #N17'),
          for (var index = 1; index <= 15; index++)
            FortuneCellCoord(index, 0):
                FortuneCell(value: '#N${index.toString().padLeft(2, '0')}'),
        }),
      ]));
      final initial = labelSheetEncodeWorkbookSave(FortuneWorkbook(sheets: [
        FortuneSheet(id: 'label', name: 'Label', cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: '기존 라벨'),
        }),
      ]));
      var registrations = 0;
      int? registeredTypeId;
      bool? tableAbsentBeforeRegistration;
      var dirty = false;
      final release = Completer<void>();
      late FortuneSheetController controller;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommonLabelManage(
        title: '공용라벨관리',
        labelSize: LabelSize(
          labelSizeId: 10,
          brandId: 1,
          labelSizeName: 'TEST',
          labelSizeCommon: LabelSizeCommon(width: 100, height: 100, rtf: initial),
        ),
        nutritionBoxListLoader: () async => [
          NutritionBox(id: 117, typeId: 2, typeName: '총 내용량',
            name: '80*100(플러터)', rtf: template, width: 80),
        ],
        onPrepareNutritionTableInsert: (box) async {
          registeredTypeId = box.typeId;
          tableAbsentBeforeRegistration =
              controller.getSheet()!.cells[const FortuneCellCoord(1, 1)] == null;
          final command = nutritionTableColumnSaveCommand(
            labelSizeId: 10,
            columns: TColumn.datas!,
            nutritionColumns: [
              for (var index = 1; index <= 17; index++)
                NutritionTypeColumn(id: index,
                  keyword: 'N${index.toString().padLeft(2, '0')}', name: '영양 $index'),
            ],
          );
          registrations++;
          await release.future;
          if (outcome == 'save-error') throw StateError('키워드 저장 실패');
          TColumn.datas = [
            for (final row in command.newColumns)
              row.column.copyWith(columnId: 100 + row.column.order),
          ];
        },
        onSheetDirtyChanged: (value) => dirty = value,
      ))));
      await tester.pumpAndSettle();
      final app = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
      controller = app.controller!;
      controller.focusCanvas();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(controller.getFlattenRange()!.first, const FortuneCellCoord(1, 1));
      final dirtyBeforeInsertion = dirty;
      final insertion = app.settings!.onContextMenuCommand!(
        labelSheetInsertNutritionTableCommand,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutritionBoxInsertButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(registeredTypeId, 2);
      expect(tableAbsentBeforeRegistration, isTrue);
      if (outcome != 'duplicate') {
        expect(registrations, 1);
        expect(find.text('영양성분 항목을 등록 중입니다...'), findsOneWidget);
        expect(controller.getSheet()!.cells[const FortuneCellCoord(1, 1)], isNull);
        release.complete();
      }
      await tester.pumpAndSettle();
      if (outcome != 'success') {
        expect(find.text('영양성분표 삽입 실패'), findsOneWidget);
        expect(controller.getSheet()!.cells[const FortuneCellCoord(1, 1)], isNull);
        expect(TColumn.datas, hasLength(outcome == 'duplicate' ? 1 : 0));
        expect(dirty, dirtyBeforeInsertion);
        await tester.tap(find.widgetWithText(TextButton, '확인').last);
        await tester.pumpAndSettle();
      } else {
        expect(TColumn.datas, hasLength(17));
        expect(find.text('N01'), findsOneWidget);
        expect(controller.getSheet()!.cells[const FortuneCellCoord(1, 1)]?.renderedText,
            '영양정보 #N16 #N17');
        expect(controller.getSheet()!.cells[const FortuneCellCoord(16, 1)]?.renderedText,
            '#N15');
        expect(dirty, isTrue);
        final saved = labelSheetDecodeWorkbookSave(
          labelSheetBuildSavePayload(_sheetPainter(tester).workbook).encodedWorkbook,
        );
        expect(saved.activeSheet.cells[const FortuneCellCoord(1, 1)]?.renderedText,
            '영양정보 #N16 #N17');
        controller.handleUndo();
        await tester.pumpAndSettle();
        expect(controller.getSheet()!.cells[const FortuneCellCoord(1, 1)], isNull);
        expect(TColumn.datas, hasLength(17));
        controller.handleRedo();
        await tester.pumpAndSettle();
        expect(controller.getSheet()!.cells[const FortuneCellCoord(1, 1)]?.renderedText,
            '영양정보 #N16 #N17');
      }
      await insertion;
      expect(controller.getSheet()!.cells[const FortuneCellCoord(0, 0)]?.renderedText,
          '기존 라벨');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('duplicated image connection displays selected item without changing saved source', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final previousColumns = TColumn.datas;
    final previousSpecials = TColumnSpecial.datas;
    addTearDown(() {
      TColumn.datas = previousColumns;
      TColumnSpecial.datas = previousSpecials;
      clearSelectedItemBmpPreviewCache();
    });
    TColumn.datas = [
      _storedColumn('PARTMARK', typeCode: TColumnType.TYPE_IMAGE, columnName: '이미지'),
    ];
    TColumnSpecial.datas = [];
    final red = image.Image(width: 4, height: 4);
    image.fill(red, color: image.ColorRgb8(255, 0, 0));
    final green = image.Image(width: 4, height: 4);
    image.fill(green, color: image.ColorRgb8(0, 255, 0));
    final blue = image.Image(width: 4, height: 4);
    image.fill(blue, color: image.ColorRgb8(0, 0, 255));
    final originalSrc = 'data:image/png;base64,${base64Encode(image.encodePng(red))}';
    cacheSelectedItemBmpPreview('PP.bmp', image.encodeBmp(green));
    cacheSelectedItemBmpPreview('PE.bmp', image.encodeBmp(blue));
    final linkedSrc = itemBmpPreviewDataUriForFileName('PP')!;
    final workbook = FortuneWorkbook(sheets: [
      FortuneSheet(id: 's1', name: 'Label', images: [
        FortuneImage(
          id: 'image_1', src: originalSrc,
          left: 20, top: 30, width: 80, height: 40,
        ),
      ]),
    ]);
    final label = LabelSize(
      labelSizeId: 10, brandId: 1, labelSizeName: 'test',
      labelSizeCommon: LabelSizeCommon(
        width: 100, height: 100,
        rtf: labelSheetEncodeWorkbookSave(workbook),
      ),
    );
    Future<void> show(Map<int, String> values) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: CommonLabelManage(
          title: '공용라벨관리', labelSize: label, imageColumnValues: values,
        ),
      )));
      await tester.pumpAndSettle();
    }
    await show({1: 'PP'});
    final app = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    final controller = app.controller!;
    expect(app.imageObjectSources!['#PARTMARK'], linkedSrc);
    await tester.tap(find.text('이미지 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('선택한 개체 복제'));
    await tester.pumpAndSettle();
    final cloneId = controller.objectSelection.activeImage!.id;
    expect(cloneId, isNot('image_1'));
    final connection = find.byKey(const ValueKey('fortune-object-property-connectionId'));
    await tester.ensureVisible(connection);
    await tester.tap(connection);
    await tester.pumpAndSettle();
    await tester.tap(find.text('이미지 (#PARTMARK)').last);
    await tester.pumpAndSettle();
    final apply = find.byKey(const ValueKey('fortune-object-property-apply'));
    await tester.drag(find.descendant(
      of: find.byType(FortuneObjectLayerPanel),
      matching: find.byType(ListView),
    ).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    final canonical = controller.getSheet()!;
    expect(canonical.images.first.src, originalSrc);
    expect(canonical.images.last.src, originalSrc);
    expect(canonical.images.last.extraFields[fortuneImageObjectIdExtraKey], '#PARTMARK');
    await _waitForImage(tester, linkedSrc);
    expect(await _greenPixels(tester), greaterThan(100));
    final saved = labelSheetDecodeWorkbookSave(labelSheetEncodeWorkbookSave(
      FortuneWorkbook(sheets: [canonical]),
    ));
    expect(saved.activeSheet.images.last.src, originalSrc);
    expect(saved.activeSheet.images.last.extraFields[fortuneImageObjectIdExtraKey], '#PARTMARK');

    controller.handleUndo();
    await tester.pumpAndSettle();
    expect(await _greenPixels(tester), 0);
    controller.handleRedo();
    await tester.pumpAndSettle();
    expect(await _greenPixels(tester), greaterThan(100));
    await show({1: 'PE'});
    await _waitForImage(tester, itemBmpPreviewDataUriForFileName('PE')!);
    expect(await _greenPixels(tester), 0);
    await show({});
    expect(await _greenPixels(tester), 0);
    expect(controller.getSheet()!.images.last.extraFields[fortuneImageObjectIdExtraKey], '#PARTMARK');
    expect(controller.getSheet()!.images.last.src, originalSrc);
    await show({1: 'PP'});
    expect(await _greenPixels(tester), greaterThan(100));
    expect(controller.getSheet()!.images, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  test('linked image display sources are separate from canonical and barcode sources', () {
    const source = FortuneImage(
      id: 'image', src: 'PVC', left: 0, top: 0, width: 80, height: 40,
      extraFields: {fortuneImageObjectIdExtraKey: ' #PARTMARK '},
    );
    expect(fortuneImageDisplaySource(source, {'#partmark': 'PP'}), 'PP');
    expect(fortuneImageDisplaySource(source.copyWith(left: 50), {'#PARTMARK': 'PP'}), 'PP');
    expect(fortuneImageDisplaySource(source, {}), '');
    expect(fortuneImageDisplaySource(source, {'#PARTMARK': ''}), '');
    expect(fortuneImageDisplaySource(source, null), 'PVC');
    expect(fortuneImageDisplaySource(source.copyWith(extraFields: {}), {'#PARTMARK': 'PP'}), 'PVC');
    expect(fortuneImageDisplaySource(source.copyWith(extraFields: {
      ...source.extraFields, 'fortuneBarcode': true,
    }), {'#PARTMARK': 'PP'}), 'PVC');
    expect(source.src, 'PVC');
  });

  test('right pane starts and stops at ten less than previous table width', () {
    expect(commonLabelRightPaneInitialWidth, 350);
    expect(commonLabelRightPaneMinWidth, 350);
  });

  test('keyword and name share resize space while required width stays fixed', () {
    expect(commonLabelColumnWidthsForViewport(350), [120, 120, 70]);
    expect(commonLabelColumnWidthsForViewport(450), [170, 170, 70]);
  });

  test('barcode object ids include only barcode column types', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [
        _column('CODE', typeCode: TColumnType.TYPE_BARCODE),
        _column('#QR_VALUE', typeCode: TColumnType.TYPE_QR_CODE),
        _column('  CODE  ', typeCode: TColumnType.TYPE_GS1_BARCODE),
        _column('BARCODE_TEXT'),
        _column('ITEMNAME'),
      ],
      const [],
    );

    expect(objectIds, ['#CODE', '#QR_VALUE']);
  });

  test('barcode object ids fall back to default when no barcode keyword exists', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [_column('ITEMNAME')],
      const [],
    );

    expect(objectIds, ['#BARCODE']);
  });

  test('image object ids include only image column types', () {
    final objectIds = commonLabelImageObjectIdsFromColumns(
      [
        _column('ITEM_IMAGE', typeCode: TColumnType.TYPE_IMAGE),
        _column('ELEMENT'),
      ],
    );

    final combined = commonLabelImageObjectIdsFromColumns([
      _column('ITEM_IMAGE', typeCode: TColumnType.TYPE_IMAGE),
      _column('  #SUB_IMAGE  ', typeCode: TColumnType.TYPE_IMAGE),
      _column('BARCODE_ID', typeCode: TColumnType.TYPE_BARCODE),
      _column('item_image', typeCode: TColumnType.TYPE_IMAGE),
    ]);

    expect(objectIds, ['#ITEM_IMAGE']);
    expect(combined, ['#ITEM_IMAGE', '#SUB_IMAGE']);
  });

  test('barcode connection options preserve column metadata', () {
    final options = commonLabelBarcodeObjectOptionsFromColumns([
      _storedColumn(
        'ITEM_CODE',
        typeCode: TColumnType.TYPE_BARCODE,
        columnName: '품목 코드',
        barcodeType: BarcodeType.CodeEAN13,
        showBarcodeNum: true,
      ),
      _storedColumn('IMAGE', typeCode: TColumnType.TYPE_IMAGE),
    ]);

    expect(options, hasLength(1));
    expect(options.single.value, '#ITEM_CODE');
    expect(options.single.label, '품목 코드 (#ITEM_CODE) · EAN13');
    expect(options.single.formatId, 'ean13');
    expect(options.single.formatLabel, 'EAN13');
    expect(options.single.showHumanReadableText, isTrue);
  });

  test('image connection options include image columns only', () {
    final options = commonLabelImageObjectOptionsFromColumns([
      _storedColumn(
        '#ITEM_IMAGE',
        typeCode: TColumnType.TYPE_IMAGE,
        columnName: '품목 이미지',
      ),
      _storedColumn('CODE', typeCode: TColumnType.TYPE_BARCODE),
    ]);

    expect(options, hasLength(1));
    expect(options.single.value, '#ITEM_IMAGE');
    expect(options.single.label, '품목 이미지 (#ITEM_IMAGE)');
  });

  test('GS1 connection options restrict unsupported barcode formats', () {
    final options = commonLabelBarcodeObjectOptionsFromColumns([
      _storedColumn('GS1', typeCode: TColumnType.TYPE_GS1_BARCODE),
      _storedColumn('BARCODE', typeCode: TColumnType.TYPE_BARCODE),
    ]);
    expect(options.first.excludedFormatIds, {'code39', 'microQRCode', 'code93'});
    expect(options.last.excludedFormatIds, isEmpty);
  });

  test('required keywords include only missing-keyword checked columns', () {
    final required = commonLabelRequiredKeywordsFromColumns([
      _column(
        'ITEMNAME',
        columnName: '품명',
        useMissingKeywordCheck: true,
      ),
      _column('PRICE', columnName: '가격'),
      _column(
        '  #BARCODE_ID  ',
        columnName: '바코드',
        useMissingKeywordCheck: true,
      ),
      _column('itemname', columnName: '중복', useMissingKeywordCheck: true),
    ]);

    expect(required.map((item) => item.keyword), ['ITEMNAME', '#BARCODE_ID']);
    expect(required.map((item) => item.itemName), ['품명', '바코드']);
  });

  testWidgets('required checkbox notifies current unchecked state', (
    tester,
  ) async {
    final columns = [
      _column(
        'SWEIGHT',
        columnName: '저울중량',
        useMissingKeywordCheck: true,
      ),
    ];
    var changedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 120,
            child: commonLabelRequiredTableForTesting(
              columns: columns,
              onRequiredChanged: () => changedCount += 1,
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<TColumnBase>),
    );
    await tester.tapAt(tableTopLeft + const Offset(40 + 120 + 120 + 35, 50));
    await tester.pump();

    expect(columns.single.useMissingKeywordCheck, isFalse);
    expect(changedCount, 1);
    expect(commonLabelRequiredKeywordsFromColumns(columns), isEmpty);
  });

  testWidgets('required checkbox marks common label sheet dirty', (
    tester,
  ) async {
    final previousSpecialColumns = TColumnSpecial.datas;
    final previousColumns = TColumn.datas;
    addTearDown(() {
      TColumnSpecial.datas = previousSpecialColumns;
      TColumn.datas = previousColumns;
    });
    TColumnSpecial.datas = [
      _column(
        'SWEIGHT',
        columnName: '저울중량',
        useMissingKeywordCheck: true,
      ),
    ];
    TColumn.datas = const [];
    final dirtyChanges = <bool>[];
    final editingLifecycleController =
      LabelSheetEditingLifecycleController();
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommonLabelManage(
            title: '공용라벨관리',
            editingLifecycleController: editingLifecycleController,
            onSheetDirtyChanged: dirtyChanges.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final specialTable = find.byType(FortuneTable<TColumnBase>).first;
    final tableTopLeft = tester.getTopLeft(specialTable);
    await tester.tapAt(tableTopLeft + const Offset(315, 50));
    await tester.pump();

    expect(TColumnSpecial.datas!.single.useMissingKeywordCheck, isFalse);
    expect(dirtyChanges, contains(true));
  });

  test('saved image size snapshot advances only matching baselines and preserves new edits', () {
    final loaded = _storedColumn(
      'PARTMARK', typeCode: TColumnType.TYPE_IMAGE, width: 30, height: 30,
    );
    final local = loaded.copyWith(width: 32, height: 33);
    final other = loaded.copyWith(columnId: 2);
    final foreign = loaded.copyWith(labelSizeId: 99);
    final updated = commonLabelColumnsWithSavedImageSizes(
      labelSizeId: 10, columns: [local, other, foreign],
      savedSizes: [(columnId: 1, width: 31, height: 31)],
    );
    expect((updated.first.persistedWidth, updated.first.persistedHeight), (31, 31));
    expect((updated.first.width, updated.first.height), (32, 33));
    expect((loaded.persistedWidth, loaded.persistedHeight), (30, 30));
    expect(updated[1], same(other));
    expect(updated[2], same(foreign));
    expect(updated.first.copyWith(columnName: '수정').persistedWidth, 31);
  });

  testWidgets('common label save advances captured image size without replacing newer draft', (
    tester,
  ) async {
    final previousColumns = TColumn.datas;
    final previousSpecial = TColumnSpecial.datas;
    addTearDown(() {
      TColumn.datas = previousColumns;
      TColumnSpecial.datas = previousSpecial;
    });
    final loaded = _storedColumn(
      'PARTMARK', typeCode: TColumnType.TYPE_IMAGE, width: 30, height: 30,
    );
    TColumn.datas = [loaded.copyWith(width: 31, height: 31)];
    TColumnSpecial.datas = [];
    const label = LabelSize(labelSizeId: 10, brandId: 1, labelSizeName: 'test');
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CommonLabelManage(
      title: '공용라벨관리', labelSize: label,
    ))));
    await tester.pumpAndSettle();
    final page = tester.widget<LabelSheetPage>(find.byType(LabelSheetPage));
    expect(page.imageColumnSizes.single, (columnId: 1, width: 31, height: 31));
    expect(TColumn.datas!.single.persistedWidth, 30);
    TColumn.datas = [TColumn.datas!.single.copyWith(width: 32)];
    page.onSaved!(label);
    expect(TColumn.datas!.single.width, 32);
    expect(TColumn.datas!.single.persistedWidth, 31);
    expect(TColumn.datas!.single.persistedHeight, 31);
    var session = LabelColumnEditSession.fromColumns(
      labelSizeId: 10, columns: TColumn.datas!,
    ).beginPropertyEdit();
    session = session.updatePropertyDraft(session.propertyDraft!.copyWith(
      column: session.propertyDraft!.column.copyWith(width: 33),
    )).applyProperty();
    final command = session.toSaveCommand();
    expect(command.originalColumnsById[1]!.column.width, 31);
    expect(command.updatedColumns.single.column.width, 33);
    expect(command.changedKeysByColumnId[1], {'width'});
  });

  test('successful required-check snapshot advances only matching DB baselines', () {
    final loaded = _storedColumn('TEST', typeCode: TColumnType.TYPE_BASE);
    final other = loaded.copyWith(columnId: 2, keyword: 'OTHER');
    final foreign = loaded.copyWith(labelSizeId: 99);
    loaded.useMissingKeywordCheck = true;
    final snapshot = commonLabelRequiredCheckSaves([], [loaded]);
    loaded.useMissingKeywordCheck = false;
    final updated = commonLabelColumnsWithSavedRequiredChecks(
      labelSizeId: 10,
      columns: [loaded, other, foreign],
      savedChecks: snapshot,
    );
    expect(updated.first.persistedMissingKeywordCheck, isTrue);
    expect(updated.first.persistedMainMissingKeywordCheck, isFalse);
    expect(updated.first.useMissingKeywordCheck, isFalse);
    expect(loaded.persistedMissingKeywordCheck, isFalse);
    expect(updated[1], same(other));
    expect(updated[2], same(foreign));
    expect(
      updated.first.copyWith(columnName: '수정').persistedMissingKeywordCheck,
      isTrue,
    );
  });

  testWidgets('common label save callback advances its captured check snapshot', (
    tester,
  ) async {
    final previousColumns = TColumn.datas;
    final previousSpecial = TColumnSpecial.datas;
    addTearDown(() {
      TColumn.datas = previousColumns;
      TColumnSpecial.datas = previousSpecial;
    });
    final loaded = _storedColumn('TEST', typeCode: TColumnType.TYPE_BASE)
      ..useMissingKeywordCheck = true;
    TColumn.datas = [loaded];
    TColumnSpecial.datas = [];
    const labelSize = LabelSize(labelSizeId: 10, brandId: 1, labelSizeName: 'test');
    LabelSize? notified;
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommonLabelManage(
            title: '공용라벨관리',
            labelSize: labelSize,
            onLabelSaved: (saved) => notified = saved,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final page = tester.widget<LabelSheetPage>(find.byType(LabelSheetPage));
    expect(page.requiredChecks.single.checked, isTrue);
    expect(loaded.persistedMissingKeywordCheck, isFalse);
    loaded.useMissingKeywordCheck = false;
    page.onSaved!(labelSize);
    expect(TColumn.datas!.single.persistedMissingKeywordCheck, isTrue);
    expect(TColumn.datas!.single.persistedMainMissingKeywordCheck, isFalse);
    expect(TColumn.datas!.single.useMissingKeywordCheck, isFalse);
    expect(notified, same(labelSize));
  });

  test('required check save snapshot includes special and stored columns', () {
    final saves = commonLabelRequiredCheckSaves(
      [
        _column('SWEIGHT', columnName: '저울중량'),
        _column('SPRICE', columnName: '최종가격'),
      ],
      [
        _storedColumn('CUSTOM', typeCode: TColumnType.TYPE_BASE)
          ..useMissingKeywordCheck = true,
      ],
    );

    expect(saves[0], (
      columnId: -3,
      keyword: 'SWEIGHT',
      columnName: '저울중량',
      checked: false,
    ));
    expect(saves[1].columnId, -4);
    expect(saves[2].columnId, 1);
    expect(saves[2].checked, isTrue);
  });

  test('linked image size updates only its image column', () {
    final imageColumn = _storedColumn(
      'TEST',
      typeCode: TColumnType.TYPE_IMAGE,
    ).copyWith(width: 20, height: 5);
    final textColumn = _storedColumn(
      'TEXT',
      typeCode: TColumnType.TYPE_BASE,
    ).copyWith(width: 7, height: 8);
    final updated = commonLabelColumnsWithImageObjectSizes(
      FortuneWorkbook(
        sheets: [
          FortuneSheet(
            id: 'label',
            name: '라벨',
            images: const [
              FortuneImage(
                id: 'image-1',
                src: 'data:image/png;base64,AA==',
                left: 0,
                top: 0,
                width: 120,
                height: 120,
                extraFields: {
                  fortuneImageObjectIdExtraKey: '#TEST',
                  'widthMm': 30.0,
                  'heightMm': 30.0,
                },
              ),
            ],
          ),
        ],
      ),
      [imageColumn, textColumn],
    );

    expect((updated[0].width, updated[0].height), (30, 30));
    expect(identical(updated[1], textColumn), isTrue);
    expect(commonLabelImageColumnSizeSaves(updated), [
      (columnId: imageColumn.columnId, width: 30, height: 30),
    ]);
  });

  testWidgets('name column drag drops keyword into the label sheet', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dirtyValues = <bool>[];
    final logLines = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 350,
                height: 120,
                child: commonLabelRequiredTableForTesting(
                  columns: [_column('SWEIGHT', columnName: '저울중량')],
                  onRequiredChanged: () {},
                ),
              ),
              Expanded(
                child: LabelSheetWorkbench(
                  initialWorkbook: FortuneWorkbook(
                    sheets: [
                      FortuneSheet(
                        id: 'label', name: 'Label', rowCount: 20, columnCount: 5,
                      ),
                    ],
                  ),
                  onDirtyChanged: dirtyValues.add,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final destination = tester.getTopLeft(find.byType(FortuneSheetCanvas)) +
      const Offset(220, 120);
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logLines.add(message);
    };
    try {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('저울중량')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(find.text('#SWEIGHT'), findsOneWidget);
      await gesture.moveTo(destination);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    } finally {
      debugPrint = previousDebugPrint;
    }
    expect(logLines, contains(contains('inserted=true dragColumns=keyword-name-v1')));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EditableText && widget.controller.text == '#SWEIGHT',
      ),
      findsOneWidget,
    );
    final app = tester.widget<FortuneSheetApp>(find.byType(FortuneSheetApp));
    app.controller!.commitActiveCellEditing();
    await tester.pumpAndSettle();
    expect(app.controller!.getSheet()!.cells.values.single.renderedText, '#SWEIGHT');
    expect(dirtyValues, [true]);
    expect(logLines, contains(contains('feature=commonLabelKeyword event=dropInsert text=#SWEIGHT')));
  });

  testWidgets('keyword and name columns share drag payload and double tap insertion', (
    tester,
  ) async {
    final logLines = <String>[];
    final keywordController = _RecordingKeywordInsertController();
    final columns = [_column('SWEIGHT', columnName: '저울중량')];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 120,
            child: commonLabelRequiredTableForTesting(
              columns: columns,
              keywordInsertController: keywordController,
              onRequiredChanged: () {},
            ),
          ),
        ),
      ),
    );

    final table = tester.widget<FortuneTable<TColumnBase>>(
      find.byType(FortuneTable<TColumnBase>),
    );
    final keywordColumn = table.columns.first;
    expect(keywordColumn.onDoubleTap, isNotNull);
    keywordColumn.onDoubleTap!(columns.single, 0);
    expect(keywordController.insertedText, '#SWEIGHT');
    final dragData = keywordColumn.dragData!(columns.single, 0);
    expect(
      dragData,
      isA<LabelSheetKeywordDragData>().having(
        (data) => data.text,
        'text',
        '#SWEIGHT',
      ),
    );
    final nameColumn = table.columns[1];
    expect(nameColumn.onDoubleTap, isNotNull);
    keywordController.insertedText = null;
    final nameCell = find.text('저울중량');
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logLines.add(message);
    };
    try {
      await tester.tap(nameCell);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(nameCell);
      await tester.pumpAndSettle();
    } finally {
      debugPrint = previousDebugPrint;
    }
    expect(keywordController.insertedText, '#SWEIGHT');
    expect(
      logLines,
      contains(
        contains(
          'feature=commonLabelKeyword event=doubleTapInsert '
          'column=이름 rowIndex=0 keyword=SWEIGHT name=저울중량 inserted=true',
        ),
      ),
    );
    expect(
      nameColumn.dragData!(columns.single, 0),
      isA<LabelSheetKeywordDragData>().having(
        (data) => data.text,
        'text',
        '#SWEIGHT',
      ),
    );
    expect(nameColumn.dragFeedbackBuilder, isNotNull);
    expect(table.columns[2].dragData, isNull);
  });
}
