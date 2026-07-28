import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/search_print_settings.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/search_print_settings_dialog.dart';

const _baseType = TColumnType(
  code: TColumnType.TYPE_BASE,
  name: '기본',
  order: 1,
);
const _gs1Type = TColumnType(
  code: TColumnType.TYPE_GS1_AI,
  name: 'GS1 AI',
  order: 2,
);

void main() {
  test('draft changes individual and all search flags', () {
    final first = _column(
      id: 1,
      type: _baseType,
      keyword: 'FIRST',
      name: '첫째',
    );
    final second = _column(
      id: 2,
      type: _baseType,
      keyword: 'SECOND',
      name: '둘째',
    ).copyWith(searchPrint: true);
    final draft = SearchPrintSettingsDraft([first, second]);
    addTearDown(draft.dispose);

    expect(draft.isDirty, isFalse);
    draft.setSearchPrint(1, true);
    expect(draft.columns.map((column) => column.searchPrint), [true, true]);
    expect(draft.isDirty, isTrue);
    draft.setAll(false);
    expect(draft.columns.map((column) => column.searchPrint), [false, false]);
    draft.replaceCommitted(draft.columns);
    expect(draft.isDirty, isFalse);
  });

  test('save command updates every column with every persisted field key', () {
    final original = [
      _column(
        id: 1,
        type: _baseType,
        keyword: 'FIRST',
        name: '첫째',
      ),
      _column(
        id: 2,
        type: _gs1Type,
        keyword: 'SECOND',
        name: '둘째',
      ),
    ];
    final working = <TColumn>[
      original[0].copyWith(searchPrint: true),
      original[1].copyWith(searchPrint: false),
    ];
    final command = buildSearchPrintSettingsSaveCommand(
      labelSizeId: 3,
      customerId: 4,
      originalColumns: original,
      workingColumns: working,
    );
    final labelCommand = command.labelColumns!;

    expect(labelCommand.updatedColumns.length, 2);
    expect(labelCommand.newColumns, isEmpty);
    expect(labelCommand.deletedColumnIds, isEmpty);
    for (final draft in labelCommand.updatedColumns) {
      expect(
        labelCommand.changedKeysByColumnId[draft.column.columnId],
        containsAll(draft.persistedValues.keys),
      );
    }
    expect(labelCommand.changedKeysByColumnId[1], contains('searchPrint'));
    expect(labelCommand.changedKeysByColumnId[2], contains('type'));
    expect(labelCommand.changedKeysByColumnId[2], contains('contains'));
    expect(labelCommand.changedKeysByColumnId[2], contains('check'));
  });

  test('save command rejects a reordered snapshot', () {
    final first = _column(
      id: 1,
      type: _baseType,
      keyword: 'FIRST',
      name: '첫째',
    );
    final second = _column(
      id: 2,
      type: _baseType,
      keyword: 'SECOND',
      name: '둘째',
    );
    expect(
      () => buildSearchPrintSettingsSaveCommand(
        labelSizeId: 3,
        customerId: 4,
        originalColumns: [first, second],
        workingColumns: [second, first],
      ),
      throwsStateError,
    );
  });

  testWidgets('Enter applies unchanged snapshot and keeps dialog open', (
    tester,
  ) async {
    const brand = Brand(brandId: 1, customerId: 4, brandName: '브랜드');
    const labelSize = LabelSize(
      labelSizeId: 3,
      brandId: 1,
      labelSizeName: '라벨',
    );
    final columns = [
      _column(
        id: 1,
        type: _baseType,
        keyword: 'FIRST',
        name: '첫째',
      ),
    ];
    var applyCount = 0;
    var closeCount = 0;
    final controller = SearchPrintSettingsDialogController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPrintSettingsDialog(
            controller: controller,
            brands: const [brand],
            initialBrand: brand,
            initialLabelSize: labelSize,
            loadLabelSizes: (_) async => const [labelSize],
            loadColumns: (_) async => columns,
            apply: ({
              required labelSizeId,
              required originalColumns,
              required workingColumns,
            }) async {
              applyCount++;
              return workingColumns;
            },
            onClose: () => closeCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'SearchPrintSettingsInitialFocus',
    );
    final table = tester.widget<FortuneTable<TColumn>>(
      find.byKey(const ValueKey('searchPrintSettingsTable')),
    );
    expect(table.rows, columns);
    expect(table.columns.map((column) => column.header), ['검색 여부', '항목명']);
    expect(table.columns.first.checkboxValue!(table.rows.first), isFalse);
    table.columns.first.onCheckboxChanged!(table.rows.first, true);
    await tester.pump();
    final checkedTable = tester.widget<FortuneTable<TColumn>>(
      find.byKey(const ValueKey('searchPrintSettingsTable')),
    );
    expect(
      checkedTable.columns.first.checkboxValue!(checkedTable.rows.first),
      isTrue,
    );
    await tester.tap(find.text('전체 해제'));
    await tester.pump();
    final uncheckedTable = tester.widget<FortuneTable<TColumn>>(
      find.byKey(const ValueKey('searchPrintSettingsTable')),
    );
    expect(
      uncheckedTable.columns.first.checkboxValue!(uncheckedTable.rows.first),
      isFalse,
    );
    await tester.tap(find.text('전체 선택'));
    await tester.pump();
    final allCheckedTable = tester.widget<FortuneTable<TColumn>>(
      find.byKey(const ValueKey('searchPrintSettingsTable')),
    );
    expect(
      allCheckedTable.columns.first.checkboxValue!(allCheckedTable.rows.first),
      isTrue,
    );
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('닫기'), findsNothing);
    expect(
      tester
          .getCenter(
            find.byKey(const ValueKey('searchPrintSettingsCancelButton')),
          )
          .dx,
      lessThan(
        tester
            .getCenter(
              find.byKey(const ValueKey('searchPrintSettingsApplyButton')),
            )
            .dx,
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(applyCount, 1);
    expect(find.text('저장되었습니다.'), findsOneWidget);
    expect(closeCount, 0);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('검색출력 설정'), findsOneWidget);
    expect(closeCount, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closeCount, 1);
  });

  test('controller exposes dirty and write-busy exit state', () {
    final controller = SearchPrintSettingsDialogController();
    addTearDown(controller.dispose);

    expect(controller.snapshot().dirtyWorks, isEmpty);
    controller.setDirty(true);
    expect(controller.snapshot().dirtyWorks.single.name, '검색출력 설정');
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, isNotNull);
  });
}

TColumn _column({
  required int id,
  required TColumnType type,
  required String keyword,
  required String name,
}) => TColumn(
  columnType: type,
  keyword: keyword,
  columnName: name,
  useMissingKeywordCheck: false,
  useMinColumnCheck: false,
  columnId: id,
  labelSizeId: 3,
  order: id,
  width: 0,
  height: 0,
  barcodeType: BarcodeType.Code128,
  useBarcodeCheckDigit: true,
  showBarcodeNum: true,
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