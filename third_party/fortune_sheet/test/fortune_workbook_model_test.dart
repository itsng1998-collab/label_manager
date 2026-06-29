import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test('settings defaults mirror upstream FortuneSheet defaultSettings', () {
    const settings = FortuneSettings();

    expect(settings.column, 60);
    expect(settings.row, 84);
    expect(settings.addRows, 50);
    expect(settings.showToolbar, isTrue);
    expect(settings.showFormulaBar, isTrue);
    expect(settings.showSheetTabs, isTrue);
    expect(settings.devicePixelRatio, 0);
    expect(settings.allowEdit, isTrue);
    expect(settings.lang, isNull);
    expect(settings.currency, '¥');
    expect(settings.forceCalculation, isFalse);
    expect(settings.rowHeaderWidth, 46);
    expect(settings.columnHeaderHeight, 20);
    expect(settings.defaultColWidth, 73);
    expect(settings.defaultRowHeight, 19);
    expect(settings.defaultFontSize, 10);
    expect(settings.fontFamilies, fortuneFontArray);
    expect(settings.fontProvider, isNull);
    expect(settings.cellContextMenu, defaultCellContextMenu);
    expect(settings.headerContextMenu, defaultHeaderContextMenu);
    expect(settings.sheetTabContextMenu, defaultSheetTabContextMenu);
    expect(settings.filterContextMenu, defaultFilterContextMenu);
  });

  test(
    'settings copyWith supports toolbar and context menu reconfiguration',
    () {
      const source = FortuneSettings(
        row: 7,
        column: 8,
        showToolbar: false,
        defaultRowHeight: 24,
        toolbarItems: ['undo', 'redo', 'filter'],
        customToolbarItems: [
          FortuneCustomToolbarItem(key: 'custom', tooltip: 'Custom'),
        ],
        cellContextMenu: ['copy', 'sort', 'link'],
        headerContextMenu: ['copy', 'filter'],
        sheetTabContextMenu: ['rename'],
        filterContextMenu: ['sort-by-asc', 'filter-by-value'],
      );

      final changed = source.copyWith(
        toolbarItems: const ['undo'],
        customToolbarItems: const <FortuneCustomToolbarItem>[],
        cellContextMenu: const ['copy'],
        headerContextMenu: const ['copy'],
        filterContextMenu: const ['filter-by-value'],
      );

      expect(changed.row, 7);
      expect(changed.column, 8);
      expect(changed.showToolbar, isFalse);
      expect(changed.defaultRowHeight, 24);
      expect(changed.toolbarItems, ['undo']);
      expect(changed.customToolbarItems, isEmpty);
      expect(changed.cellContextMenu, ['copy']);
      expect(changed.headerContextMenu, ['copy']);
      expect(changed.sheetTabContextMenu, ['rename']);
      expect(changed.filterContextMenu, ['filter-by-value']);
    },
  );

  test(
    'fortuneMenuItemsWithout removes commands and normalizes separators',
    () {
      expect(
        fortuneMenuItemsWithout(
          const ['|', 'copy', '|', 'sort', 'orderAZ', '|', 'filter', '|'],
          const {'sort', 'orderAZ', 'filter'},
        ),
        ['copy'],
      );
      expect(
        fortuneMenuItemsWithout(
          const ['copy', '|', 'paste', '|', 'link'],
          const {'link'},
        ),
        ['copy', '|', 'paste'],
      );
    },
  );

  test('font family merge keeps defaults and de-duplicates names', () {
    final collapsed = <String>[];
    final duplicates = <String>[];
    final filtered = <String>[];
    final fonts = fortuneMergeFontFamilies(
      [
        ' Arial ',
        'Aptos',
        'aptos',
        '"Noto Sans"',
        'Noto-Sans Bold',
        'Noto_Sans Italic',
        'Roboto Regular',
        'Roboto Bold Italic',
        'Bahnschrift SemiBold Condensed',
        'Bahnschrift SemiLight SemiCondensed',
        'Bahnschrift SemiBold SemiConden',
        'Segoe UI',
        'Segoe UI Variable Text',
        'Segoe UI Variable Display',
        'Segoe UI Variable Small',
        'D2Coding',
        'D2Coding ligature',
        'Franklin Gothic Demi Cond',
        'Noto Sans KR DemiLight',
        'Noto Sans KR',
        'Courier',
        'Courier New',
        'Gill Sans',
        'Gill Sans MT',
        'Gill Sans MT Condensed',
        'Microsoft JhengHei',
        'Microsoft JhengHei UI',
        'Microsoft JhengHei UI Light',
        'Microsoft YaHei',
        'Microsoft YaHei UI',
        'Microsoft YaHei UI Light',
        'Yu Gothic',
        'Yu Gothic UI',
        'Script',
        'Script MT Bold',
        'Eras Bold ITC',
        'Eras Demi ITC',
        'Eras Light ITC',
        'Eras Medium ITC',
        'Bell MT',
        'Juice ITC',
        'Century',
        'Century Gothic',
        'Century Schoolbook',
        'Arial Rounded MT Bold',
        'Cambria',
        'Cambria Math',
        'Sitka Text',
        'Sitka Display',
        'Sitka Heading',
        'Sitka Small',
        'Sitka Subheading',
        'Sitka Banner',
        'SimSun',
        'SimSun ExtB',
        'SimSun ExtG',
        'Nirmala Text',
        'Nirmala UI',
        'MapInfo StreetPro',
        'MapInfo StreetPro Unicode',
        'Segoe UI Emoji',
        'Segoe UI Symbol',
        'MS Gothic',
        'MS PGothic',
        'MS UI Gothic',
        'Lucida Sans',
        'Lucida Sans Typewriter',
        '굴림',
        '굴림체',
        '궁서',
        '궁서체',
        '휴먼매직체',
        'Cooper Black',
        '',
      ],
      onCollapsedFamily: (source, family) {
        collapsed.add('$source -> $family');
      },
      onDuplicateFamily: (source, family) {
        duplicates.add('$source -> $family');
      },
      onFilteredFamily: filtered.add,
    );

    expect(fonts, [
      'Times New Roman',
      'Arial',
      'Tahoma',
      'Verdana',
      'Aptos',
      'Noto Sans',
      'Noto Sans Bold',
      'Noto Sans Italic',
      'Roboto Regular',
      'Roboto Bold Italic',
      'Segoe UI',
      'D2Coding',
      'Noto Sans KR DemiLight',
      'Noto Sans KR',
      'Courier',
      'Courier New',
      'Gill Sans',
      'Microsoft JhengHei',
      'Microsoft YaHei',
      'Yu Gothic',
      'Century',
      'Century Gothic',
      'Century Schoolbook',
      'Cambria',
      'Sitka Text',
      'SimSun',
      'Nirmala Text',
      'MS Gothic',
      'MS PGothic',
      'MS UI Gothic',
      'Lucida Sans',
      'Lucida Sans Typewriter',
      '굴림',
      '굴림체',
      '궁서',
      '궁서체',
    ]);
    expect(collapsed, contains('Segoe UI Variable Text -> Segoe UI'));
    expect(collapsed, contains('Segoe UI Variable Display -> Segoe UI'));
    expect(collapsed, contains('Segoe UI Variable Small -> Segoe UI'));
    expect(collapsed, contains('Gill Sans MT -> Gill Sans'));
    expect(collapsed, contains('Microsoft JhengHei UI -> Microsoft JhengHei'));
    expect(collapsed, contains('Microsoft YaHei UI -> Microsoft YaHei'));
    expect(collapsed, contains('Yu Gothic UI -> Yu Gothic'));
    expect(collapsed, contains('Sitka Display -> Sitka Text'));
    expect(collapsed, contains('Sitka Heading -> Sitka Text'));
    expect(collapsed, contains('Sitka Small -> Sitka Text'));
    expect(collapsed, contains('Sitka Subheading -> Sitka Text'));
    expect(collapsed, contains('Sitka Banner -> Sitka Text'));
    expect(collapsed, contains('SimSun ExtB -> SimSun'));
    expect(collapsed, contains('SimSun ExtG -> SimSun'));
    expect(collapsed, contains('Nirmala UI -> Nirmala Text'));
    expect(
      collapsed,
      contains('MapInfo StreetPro Unicode -> MapInfo StreetPro'),
    );
    expect(collapsed, isNot(contains('Century Gothic -> Century')));
    expect(collapsed, isNot(contains('Century Schoolbook -> Century')));
    expect(duplicates, contains('Arial -> Arial'));
    expect(duplicates, contains('aptos -> aptos'));
    expect(duplicates, contains('Segoe UI Variable Text -> Segoe UI'));
    expect(duplicates, contains('Sitka Display -> Sitka Text'));
    expect(filtered, contains('Bahnschrift SemiBold Condensed'));
    expect(filtered, contains('D2Coding ligature'));
    expect(filtered, contains('Gill Sans MT Condensed'));
    expect(filtered, contains('MapInfo StreetPro'));
    expect(filtered, contains('Segoe UI Emoji'));
    expect(filtered, contains('Segoe UI Symbol'));
    expect(filtered, contains('휴먼매직체'));
    expect(filtered, contains('Cooper Black'));
    expect(fonts, isNot(contains('MapInfo StreetPro')));
    expect(fonts, isNot(contains('Segoe UI Symbol')));
  });

  test('font family sort keeps language fonts first then sorts names', () {
    expect(
      fortuneSortFontFamilies(
        const [
          'Verdana',
          'Noto Sans KR',
          'Arial',
          '맑은 고딕',
          'Cambria',
          '굴림',
          'Roboto Regular',
        ],
        preferred: const ['맑은 고딕', '굴림'],
      ),
      const [
        '굴림',
        '맑은 고딕',
        'Arial',
        'Cambria',
        'Noto Sans KR',
        'Roboto Regular',
        'Verdana',
      ],
    );
  });

  test('font family merge keeps common Android and Apple families', () {
    final filtered = <String>[];
    final fonts = fortuneMergeFontFamilies(const [
      'sans-serif',
      'sans-serif-condensed',
      'serif',
      'monospace',
      'Roboto',
      'Helvetica Neue',
      'Menlo',
      'Apple SD Gothic Neo',
      'PingFang SC',
      'Noto Color Emoji',
      'Material Icons',
    ], onFilteredFamily: filtered.add);

    expect(
      fonts,
      containsAll(<String>[
        'sans-serif',
        'sans-serif-condensed',
        'serif',
        'monospace',
        'Roboto',
        'Helvetica Neue',
        'Menlo',
        'Apple SD Gothic Neo',
        'PingFang SC',
      ]),
    );
    expect(filtered, contains('Material Icons'));
    expect(filtered, contains('Noto Color Emoji'));
  });

  test('font family resolver falls back to closest available family', () {
    expect(
      fortuneResolveFontFamily('Calibri Light', const ['Arial', 'Calibri']),
      'Calibri',
    );
    expect(
      fortuneResolveFontFamily('Segoe UI Variable Text Semiligh', const [
        'Arial',
        'Segoe UI',
      ]),
      'Segoe UI',
    );
    expect(fortuneResolveFontFamily('굴림체', const ['Arial', '굴림']), '굴림');
    expect(
      fortuneResolveFontFamily('Missing Mono', const ['Arial', 'Consolas']),
      'Consolas',
    );
    expect(
      fortuneResolveFontFamily('Missing Serif', const [
        'Arial',
        'Times New Roman',
      ]),
      'Times New Roman',
    );
    expect(
      fortuneResolveFontFamily('Unknown Display', const ['Arial', 'Verdana']),
      'Arial',
    );
  });

  test('default context mirrors upstream core cell defaults', () {
    final context = defaultContext();
    final defaultCell = context['defaultCell'] as Map;

    expect(fortuneFontArray, const [
      'Times New Roman',
      'Arial',
      'Tahoma',
      'Verdana',
    ]);
    expect(defaultCell['bl'], 0);
    expect(defaultCell['ct'], {'fa': 'General', 't': 'n'});
    expect(defaultCell['fc'], 'rgb(51, 51, 51)');
    expect(defaultCell['ff'], 0);
    expect(defaultCell['fs'], 11);
    expect(defaultCell['ht'], 1);
    expect(defaultCell['it'], 0);
    expect(defaultCell['vt'], 1);
    expect(defaultCell['m'], '');
    expect(defaultCell['v'], '');
  });

  test('default context mirrors upstream runtime state defaults', () {
    final context = defaultContext();
    final dataVerification = context['dataVerification'] as Map;

    expect(context['luckysheetfile'], isEmpty);
    expect(context['currentSheetId'], '');
    expect(context['calculateSheetId'], '');
    expect(context['warnDialog'], isNull);
    expect(context['rangeDialog'], {
      'show': false,
      'rangeTxt': '',
      'type': '',
      'singleSelect': false,
    });
    expect(dataVerification['selectStatus'], isFalse);
    expect(dataVerification['selectRange'], isEmpty);
    expect(dataVerification['dataRegulation'], {
      'type': '',
      'type2': '',
      'rangeTxt': '',
      'value1': '',
      'value2': '',
      'validity': '',
      'remote': false,
      'prohibitInput': false,
      'hintShow': false,
      'hintValue': '',
    });
    expect(dataVerification['optionLabel_en'], {
      'number': 'numeric',
      'number_integer': 'integer',
      'number_decimal': 'decimal',
      'between': 'between',
      'notBetween': 'not between',
      'equal': 'equal to',
      'notEqualTo': 'not equal to',
      'moreThanThe': 'greater',
      'lessThan': 'less than',
      'greaterOrEqualTo': 'greater or equal to',
      'lessThanOrEqualTo': 'less than or equal to',
      'include': 'include',
      'exclude': 'not include',
      'earlierThan': 'earlier than',
      'noEarlierThan': 'not earlier than',
      'laterThan': 'later than',
      'noLaterThan': 'not later than',
      'identificationNumber': 'identification number',
      'phoneNumber': 'phone number',
    });
    expect(dataVerification['optionLabel_ru'], {
      'number': 'числовое',
      'number_integer': 'целое число',
      'number_decimal': 'десятичное число',
      'between': 'между',
      'notBetween': 'не между',
      'equal': 'равно',
      'notEqualTo': 'не равно',
      'moreThanThe': 'больше',
      'lessThan': 'меньше',
      'greaterOrEqualTo': 'больше или равно',
      'lessThanOrEqualTo': 'меньше или равно',
      'include': 'содержит',
      'exclude': 'не содержит',
      'earlierThan': 'раньше',
      'noEarlierThan': 'не раньше',
      'laterThan': 'позже',
      'noLaterThan': 'не позже',
      'identificationNumber': 'идентификационный номер',
      'phoneNumber': 'номер телефона',
    });
    expect(dataVerification['optionLabel_hi'], {
      'number': 'संख्यात्मक',
      'number_integer': 'पूर्णांक',
      'number_decimal': 'दशमलव',
      'between': 'के बीच',
      'notBetween': 'के बीच नहीं',
      'equal': 'के बराबर',
      'notEqualTo': 'के बराबर नहीं',
      'moreThanThe': 'से अधिक',
      'lessThan': 'से कम',
      'greaterOrEqualTo': 'के बराबर या अधिक',
      'lessThanOrEqualTo': 'के बराबर या कम',
      'include': 'शामिल',
      'exclude': 'शामिल नहीं',
      'earlierThan': 'से पहले',
      'noEarlierThan': 'से पहले नहीं',
      'laterThan': 'के बाद',
      'noLaterThan': 'के बाद नहीं',
      'identificationNumber': 'पहचान संख्या',
      'phoneNumber': 'फोन नंबर',
    });
    expect(dataVerification['optionLabel_zh'], {
      'number': '数值',
      'number_integer': '整数',
      'number_decimal': '小数',
      'between': '介于',
      'notBetween': '不介于',
      'equal': '等于',
      'notEqualTo': '不等于',
      'moreThanThe': '大于',
      'lessThan': '小于',
      'greaterOrEqualTo': '大于等于',
      'lessThanOrEqualTo': '小于等于',
      'include': '包括',
      'exclude': '不包括',
      'earlierThan': '早于',
      'noEarlierThan': '不早于',
      'laterThan': '晚于',
      'noLaterThan': '不晚于',
      'identificationNumber': '身份证号码',
      'phoneNumber': '手机号',
    });
    expect(dataVerification['optionLabel_zh_tw'], {
      'number': '數位',
      'number_integer': '數位-整數',
      'number_decimal': '數位-小數',
      'between': '介於',
      'notBetween': '不介於',
      'equal': '等於',
      'notEqualTo': '不等於',
      'moreThanThe': '大於',
      'lessThan': '小於',
      'greaterOrEqualTo': '大於等於',
      'lessThanOrEqualTo': '小於等於',
      'include': '包括',
      'exclude': '不包括',
      'earlierThan': '早於',
      'noEarlierThan': '不早於',
      'laterThan': '晚於',
      'noLaterThan': '不晚於',
      'identificationNumber': '身份證號碼',
      'phoneNumber': '手機號',
    });
    expect(dataVerification['optionLabel_es'], {
      'number': 'Número',
      'number_integer': 'Número entero',
      'number_decimal': 'Número decimal',
      'between': 'Entre',
      'notBetween': 'No entre',
      'equal': 'Iqual',
      'notEqualTo': 'No iqual a',
      'moreThanThe': 'Más que el',
      'lessThan': 'Menos que',
      'greaterOrEqualTo': 'Mayor o igual a',
      'lessThanOrEqualTo': 'Menor o igual a',
      'include': 'Incluir',
      'exclude': 'Excluir',
      'earlierThan': 'Antes de',
      'noEarlierThan': 'No antes de',
      'laterThan': 'Después de',
      'noLaterThan': 'No después de',
      'identificationNumber': 'Número de identificación',
      'phoneNumber': 'Número de teléfono',
    });
    expect(context['dataVerificationDropDownList'], isFalse);
    expect(context['conditionRules'], {
      'rulesType': '',
      'rulesValue': '',
      'textColor': {'check': true, 'color': '#000000'},
      'cellColor': {'check': true, 'color': '#000000'},
      'betweenValue': {'value1': '', 'value2': ''},
      'dateValue': '',
      'repeatValue': '0',
      'projectValue': '10',
    });
    expect(context['visibledatarow'], isEmpty);
    expect(context['visibledatacolumn'], isEmpty);
    expect(context['ch_width'], 0);
    expect(context['rh_height'], 0);
    expect(context['cellmainWidth'], 0);
    expect(context['cellmainHeight'], 0);
    expect(context['toolbarHeight'], 41);
    expect(context['infobarHeight'], 57);
    expect(context['calculatebarHeight'], 29);
    expect(context['rowHeaderWidth'], 46);
    expect(context['columnHeaderHeight'], 20);
    expect(context['cellMainSrollBarSize'], 12);
    expect(context['sheetBarHeight'], 31);
    expect(context['statisticBarHeight'], 23);
    expect(context['luckysheetTableContentHW'], [0, 0]);
    expect(context['defaultcollen'], 73);
    expect(context['defaultrowlen'], 19);
    expect(context['sheetScrollRecord'], isEmpty);
    expect(context['scrollLeft'], 0);
    expect(context['scrollTop'], 0);
    expect(context['luckysheet_select_status'], isFalse);
    expect(context['luckysheet_select_save'], isNull);
    expect(context['luckysheet_selection_range'], isEmpty);
    expect(context['formulaRangeHighlight'], isEmpty);
    expect(context['formulaRangeSelect'], isNull);
    expect(context['functionCandidates'], isEmpty);
    expect(context['functionHint'], isNull);
    expect(context['luckysheet_copy_save'], isNull);
    expect(context['luckysheet_paste_iscut'], isFalse);
    expect(context['filterchage'], isTrue);
    expect(context['filter'], isEmpty);
    expect(context['luckysheet_sheet_move_status'], isFalse);
    expect(context['luckysheet_sheet_move_data'], isEmpty);
    expect(context['luckysheet_scroll_status'], isFalse);
    expect(context['luckysheetcurrentisPivotTable'], isFalse);
    expect(context['luckysheet_rows_selected_status'], isFalse);
    expect(context['luckysheet_cols_selected_status'], isFalse);
    expect(context['luckysheet_rows_change_size'], isFalse);
    expect(context['luckysheet_rows_change_size_start'], isEmpty);
    expect(context['luckysheet_cols_change_size'], isFalse);
    expect(context['luckysheet_cols_change_size_start'], isEmpty);
    expect(context['luckysheet_cols_freeze_drag'], isFalse);
    expect(context['luckysheet_rows_freeze_drag'], isFalse);
    expect(context['luckysheetCellUpdate'], isEmpty);
    expect(context['luckysheet_shiftkeydown'], isFalse);
    expect(context['luckysheet_shiftpositon'], isNull);
    expect(context['iscopyself'], isTrue);
    expect(context['activeImg'], isNull);
    expect(context['orderbyindex'], 0);
    expect(context['luckysheet_model_move_state'], isFalse);
    expect(context['luckysheet_model_xy'], [0, 0]);
    expect(context['luckysheet_model_move_obj'], isNull);
    expect(context['luckysheet_cell_selected_move'], isFalse);
    expect(context['luckysheet_cell_selected_move_index'], isEmpty);
    expect(context['luckysheet_cell_selected_extend'], isFalse);
    expect(context['luckysheet_cell_selected_extend_index'], isEmpty);
    expect(context['lang'], isNull);
    expect(context['chart_selection'], isEmpty);
    expect(context['zoomRatio'], 1);
    expect(context['showGridLines'], isTrue);
    expect(context['allowEdit'], isTrue);
    expect(context['fontList'], isEmpty);
    expect(context['defaultFontSize'], 10);
    expect(context['luckysheetPaintModelOn'], isFalse);
    expect(context['luckysheetPaintSingle'], isFalse);
    expect(context['sheetFocused'], isTrue);
    expect(context['groupValuesRefreshData'], isEmpty);
    expect(context['hooks'], isEmpty);
  });

  test('presence color helper mirrors upstream story utilities', () {
    expect(fortunePresenceColorPalette, hasLength(29));
    expect(fortunePresenceColorPalette.take(5), const [
      '#c1232b',
      '#27727b',
      '#fcce10',
      '#e87c25',
      '#b5c334',
    ]);

    expect(fortunePresenceHashCode(''), 0);
    expect(fortunePresenceHashCode('Alice'), 63350368);
    expect(fortunePresenceHashCode('Bob'), 66965);
    expect(fortunePresenceHashCode('fortune-sheet'), -175702829);
    expect(fortunePresenceHashCode('😀'), 1772899);

    expect(fortunePresenceColorForUserId(''), '#c1232b');
    expect(fortunePresenceColorForUserId('Alice'), '#f0805a');
    expect(fortunePresenceColorForUserId('Bob'), '#b5c334');
    expect(fortunePresenceColorForUserId('u1'), '#32a487');
    expect(fortunePresenceColorForUserId('u2'), '#3fb1e3');
    expect(fortunePresenceColorForUserId('fortune-sheet'), '#fad860');
  });

  test('settings show flags collapse effective chrome heights', () {
    const visible = FortuneSettings(
      toolbarHeight: 41,
      formulaBarHeight: 29,
      sheetBarHeight: 31,
    );
    const hidden = FortuneSettings(
      showToolbar: false,
      showFormulaBar: false,
      showSheetTabs: false,
      toolbarHeight: 41,
      formulaBarHeight: 29,
      sheetBarHeight: 31,
    );

    expect(visible.effectiveToolbarHeight, 41);
    expect(visible.effectiveFormulaBarHeight, 29);
    expect(visible.effectiveSheetBarHeight, 31);
    expect(hidden.effectiveToolbarHeight, 0);
    expect(hidden.effectiveFormulaBarHeight, 0);
    expect(hidden.effectiveSheetBarHeight, 0);
    expect(hidden.toolbarHeight, 41);
    expect(hidden.formulaBarHeight, 29);
    expect(hidden.sheetBarHeight, 31);
  });

  test('checkboxChange toggles upstream truthy checked values off', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'Done'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: 'Yes'),
      },
      dataVerification: {
        '0_0': {
          'type': 'checkbox',
          'checked': 1,
          'value1': 'Done',
          'value2': 'Open',
        },
        '0_1': {
          'type': 'checkbox',
          'checked': 'true',
          'value1': 'Yes',
          'value2': 'No',
        },
      },
    );

    final numeric = checkboxChange(sheet, 0, 0);
    final string = checkboxChange(sheet, 0, 1);

    expect(numeric.dataVerification['0_0'], containsPair('checked', false));
    expect(numeric.cells[const FortuneCellCoord(0, 0)]?.rawValue, 'Open');
    expect(string.dataVerification['0_1'], containsPair('checked', false));
    expect(string.cells[const FortuneCellCoord(0, 1)]?.rawValue, 'No');
  });

  test('column index char helpers mirror upstream utils', () {
    expect(indexToColumnChar(-1), '');
    expect(indexToColumnChar(0), 'A');
    expect(indexToColumnChar(25), 'Z');
    expect(indexToColumnChar(26), 'AA');
    expect(indexToColumnChar(701), 'ZZ');
    expect(indexToColumnChar(702), 'AAA');
    expect(indexToColumnChar(18277), 'ZZZ');
    expect(indexToColumnChar(18278), 'AAAA');

    expect(columnCharToIndex(null), isNull);
    expect(columnCharToIndex(''), isNull);
    expect(columnCharToIndex('A'), 0);
    expect(columnCharToIndex('z'), 25);
    expect(columnCharToIndex('aZ'), 51);
    expect(columnCharToIndex('AA'), 26);
    expect(columnCharToIndex('ZZ'), 701);
    expect(columnCharToIndex('AAA'), 702);
    expect(columnCharToIndex('@'), -33);
    expect(columnCharToIndex('A1'), -22);
  });

  test('workbook copyWith switches active sheet and clamps index', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1'),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
    );

    final switched = workbook.copyWith(activeSheetIndex: 1);
    final clamped = workbook.copyWith(activeSheetIndex: 99);

    expect(switched.activeSheet.id, 's2');
    expect(clamped.activeSheetIndex, 1);
  });

  test('workbook returns sheets through upstream public API helpers', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A')},
        ),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
      activeSheetIndex: 1,
    );

    final allSheets = workbook.getAllSheets();
    final active = workbook.getSheet();
    final byId = workbook.getSheet(id: 's1');
    final byIndex = workbook.getSheet(index: 0);
    final missingId = workbook.getSheet(id: 'missing');
    final missingIndex = workbook.getSheet(index: 99);

    allSheets.add(FortuneSheet(id: 'extra', name: 'Extra'));
    byId!.cells[const FortuneCellCoord(0, 0)] = const FortuneCell(value: 'B');

    expect(allSheets.map((sheet) => sheet.id), ['s1', 's2', 'extra']);
    expect(workbook.sheets.map((sheet) => sheet.id), ['s1', 's2']);
    expect(active?.id, 's2');
    expect(byId.id, 's1');
    expect(byIndex?.id, 's1');
    expect(missingId, isNull);
    expect(missingIndex, isNull);
    expect(
      workbook.sheets.first.cells[const FortuneCellCoord(0, 0)]!.value,
      'A',
    );
  });

  test('workbook returns sheet with latest celldata snapshot', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rawData: [
            [
              {'v': 'fresh'},
              null,
              null,
            ],
            [
              null,
              null,
              {'v': 'formula', 'f': '=A1'},
            ],
          ],
          hasRawData: true,
          rawCelldata: [
            {
              'r': 0,
              'c': 0,
              'v': {'v': 'stale'},
            },
          ],
          hasRawCelldata: true,
          cells: {
            const FortuneCellCoord(0, 0): const FortuneCell(value: 'fresh'),
            const FortuneCellCoord(1, 2): const FortuneCell(
              value: 'formula',
              formula: '=A1',
            ),
          },
        ),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
    );

    final snapshot = workbook.getSheetWithLatestCelldata(id: 's1')!;
    final activeSnapshot = workbook.getSheetWithLatestCelldata()!;
    final missing = workbook.getSheetWithLatestCelldata(id: 'missing');

    final celldata = (snapshot['celldata']! as List).cast<Map>();
    final firstCell = celldata.singleWhere((cell) => cell['r'] == 0);
    final secondCell = celldata.singleWhere((cell) => cell['r'] == 1);

    expect(snapshot['id'], 's1');
    expect(snapshot['data'], [
      [
        {'v': 'fresh'},
        null,
        null,
      ],
      [
        null,
        null,
        {'v': 'formula', 'f': '=A1'},
      ],
    ]);
    expect((firstCell['v']! as Map)['v'], 'fresh');
    expect((secondCell['v']! as Map)['f'], '=A1');
    expect(activeSnapshot['id'], 's1');
    expect(missing, isNull);

    (firstCell['v']! as Map)['v'] = 'mutated';
    expect(
      workbook.sheets.first.cells[const FortuneCellCoord(0, 0)]!.value,
      'fresh',
    );
  });

  test('workbook activates sheets and renames sheets by id', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1'),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
    );

    final activated = workbook.activateSheet('s2');
    final renamed = activated.setSheetName('s2', 'Summary');

    expect(activated.activeSheet.id, 's2');
    expect(renamed.activeSheet.id, 's2');
    expect(renamed.sheets[1].name, 'Summary');
    expect(workbook.activeSheet.id, 's1');
    expect(workbook.sheets[1].name, 'Sheet2');
  });

  test('workbook reorders sheets by id and normalizes order values', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', order: 0),
        FortuneSheet(id: 's2', name: 'Sheet2', order: 1),
        FortuneSheet(id: 's3', name: 'Sheet3', order: 2),
      ],
      activeSheetIndex: 1,
    );

    final reordered = workbook.setSheetOrder({'s3': 0, 's1': 2});

    expect(reordered.sheets.map((sheet) => sheet.id), ['s3', 's2', 's1']);
    expect(reordered.sheets.map((sheet) => sheet.order), [0, 1, 2]);
    expect(reordered.activeSheet.id, 's2');
    expect(workbook.sheets.map((sheet) => sheet.id), ['s1', 's2', 's3']);
  });

  test('workbook adds deletes and copies sheets by id', () {
    final uuidV4Pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 'sheet_1', name: 'Sheet1', order: 0),
        FortuneSheet(id: 'sheet_2', name: 'Sheet2', order: 1),
      ],
    );

    final added = workbook.addSheet();
    final copied = added.copySheet('sheet_2', id: 'sheet_copy');
    final deleted = copied.deleteSheet('sheet_2');
    final generatedAddId = added.activeSheet.id;

    expect(generatedAddId, matches(uuidV4Pattern));
    expect(generatedAddId, isNot('sheet_3'));
    expect(added.activeSheet.name, 'Sheet3');
    expect(copied.sheets.map((sheet) => sheet.id), [
      'sheet_1',
      'sheet_2',
      'sheet_copy',
      generatedAddId,
    ]);
    expect(copied.sheets[2].name, 'Sheet2(copy)');
    expect(copied.sheets.map((sheet) => sheet.order), [0, 1, 2, 3]);
    expect(copied.activeSheet.id, generatedAddId);
    expect(deleted.sheets.map((sheet) => sheet.id), [
      'sheet_1',
      'sheet_copy',
      generatedAddId,
    ]);
    expect(deleted.sheets.map((sheet) => sheet.order), [0, 1, 2]);
    expect(deleted.activeSheet.id, generatedAddId);
    expect(workbook.sheets.map((sheet) => sheet.id), ['sheet_1', 'sheet_2']);
  });

  test('workbook adds provided sheet at requested order', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', order: 0),
        FortuneSheet(id: 's2', name: 'Sheet2', order: 1),
        FortuneSheet(id: 's3', name: 'Sheet3', order: 2),
      ],
      activeSheetIndex: 2,
    );

    final added = workbook.addSheet(
      id: 'inserted',
      sheet: FortuneSheet(id: 'source', name: 'Inserted', order: 1),
    );

    expect(added.sheets.map((sheet) => '${sheet.id}:${sheet.order}'), [
      's1:0',
      's2:2',
      's3:3',
      'inserted:1',
    ]);
    expect(added.activeSheet.id, 's3');
  });

  test('workbook deletes active sheet and selects first visible by order', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1', order: 5),
        FortuneSheet(id: 's2', name: 'Sheet2', order: 2),
        FortuneSheet(id: 's3', name: 'Sheet3', order: 0),
        FortuneSheet(id: 's4', name: 'Sheet4', order: 1, hide: 1),
      ],
      activeSheetIndex: 1,
    );

    final deleted = workbook.deleteSheet('s2');

    expect(deleted.sheets.map((sheet) => '${sheet.id}:${sheet.order}'), [
      's1:4',
      's3:0',
      's4:1',
    ]);
    expect(deleted.activeSheet.id, 's3');
  });

  test('workbook allows deleting the last sheet', () {
    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
    );

    final deleted = workbook.deleteSheet('s1');

    expect(deleted.sheets, isEmpty);
    expect(deleted.activeSheetIndex, 0);
  });

  test('workbook updates sheets by id and appends new sheets', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1'),
        FortuneSheet(id: 's2', name: 'Sheet2'),
      ],
      activeSheetIndex: 1,
    );

    final updated = workbook.updateSheet([
      FortuneSheet(
        id: 's1',
        name: 'Updated',
        cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A')},
      ),
      FortuneSheet(id: 's3', name: 'Added'),
    ]);

    expect(updated.sheets.map((sheet) => sheet.id), ['s1', 's2', 's3']);
    expect(updated.sheets.first.name, 'Updated');
    expect(
      updated.sheets.first.cells[const FortuneCellCoord(0, 0)]!.value,
      'A',
    );
    expect(updated.activeSheet.id, 's2');
    expect(workbook.sheets.first.name, 'Sheet1');
    expect(workbook.sheets.length, 2);
  });

  test('workbook copyWith snapshots extra metadata', () {
    final sourceItem = {'value': 'A'};
    final sourceExtra = {
      'customWorkbookMeta': {
        'items': [sourceItem],
      },
    };
    final workbook = FortuneWorkbook(
      sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      extraFields: sourceExtra,
    );
    final copy = workbook.copyWith(activeSheetIndex: 0);
    final workbookItem =
        ((workbook.extraFields['customWorkbookMeta']! as Map)['items']! as List)
                .single
            as Map;
    final copyItem =
        ((copy.extraFields['customWorkbookMeta']! as Map)['items']! as List)
                .single
            as Map;

    sourceItem['value'] = 'mutated source';
    copyItem['value'] = 'mutated copy';

    expect(workbookItem['value'], 'A');
    expect(copyItem['value'], 'mutated copy');
  });

  test('sheet reads row heights and column widths with upstream defaults', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowHeights: {1: 42},
      columnWidths: {2: 88},
    );

    expect(sheet.getRowHeights([-1, 0, 1, 2]), {0: 19, 1: 42, 2: 19});
    expect(sheet.getColumnWidths([-1, 0, 2, 3]), {0: 73, 2: 88, 3: 73});
  });

  test('sheet gets sets and clears cell values through API helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '10',
          rawValue: 10,
          hasRawValue: true,
          displayValue: 'ten',
          rawDisplayValue: 'ten',
          hasRawDisplayValue: true,
          bold: true,
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(formula: '=A1'),
        const FortuneCellCoord(0, 2): const FortuneCell(
          value: 'spark',
          sparkline: {'type': 'line'},
          hasSparkline: true,
        ),
        const FortuneCellCoord(0, 3): const FortuneCell(
          formula: '=A1',
          sparkline: {'type': 'line'},
          hasSparkline: true,
        ),
        const FortuneCellCoord(0, 4): const FortuneCell(
          value: '44989',
          rawValue: 44989,
          hasRawValue: true,
          displayValue: '2023-03-04',
          rawDisplayValue: '2023-03-04',
          hasRawDisplayValue: true,
          cellType: FortuneCellType(format: 'yyyy-MM-dd', type: 'd'),
        ),
        const FortuneCellCoord(0, 5): const FortuneCell(
          value: '44989',
          rawValue: 44989,
          hasRawValue: true,
          displayValue: '2023-03-04',
          rawDisplayValue: '2023-03-04',
          hasRawDisplayValue: true,
          cellType: FortuneCellType(format: 'yyyy-MM-dd', type: 'n'),
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: 'old',
          formula: '=A1',
          hasRawFormula: true,
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: 'old',
          formula: '=A1',
          hasRawFormula: true,
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          value: 'old',
          formula: '=A1',
          hasRawFormula: true,
        ),
      },
      calcChain: const [
        {'r': 2, 'c': 0, 'id': 's1'},
        {'r': 2, 'c': 1, 'id': 's1'},
        {'r': 2, 'c': 2, 'id': 's1'},
        {'r': 9, 'c': 9, 'id': 's1'},
      ],
      hasRawCalcChain: true,
      dynamicArray: const [
        {'r': 2, 'c': 0},
        {'r': 2, 'c': 1},
        {'r': 2, 'c': 2},
        {'r': 9, 'c': 9},
      ],
      hasRawDynamicArray: true,
      dynamicArrayCompute: const {
        '2_0': true,
        '2_1': true,
        '2_2': true,
        '9_9': {'keep': true},
      },
      hasRawDynamicArrayCompute: true,
    );

    final text = sheet.setCellValue(1, 0, 'hello');
    final formula = text.setCellValue(1, 1, '=A1');
    final mapped = formula.setCellValue(1, 2, {
      'v': 42,
      'm': 'forty two',
      'f': '=SUM(A1:A2)',
      'bg': '#ffeeaa',
      'bl': 1,
      'qp': 1,
      'customFlag': {'enabled': true},
    });
    final mappedCell = mapped.cells[const FortuneCellCoord(1, 2)]!;
    final cleared = mapped.clearCell(0, 0);
    final directFormulaCleanup = sheet.setCellValue(2, 0, 'plain');
    final directClearCleanup = directFormulaCleanup.clearCell(2, 1);
    final directRawFormulaPreserved = sheet.setCellValue(
      2,
      2,
      const FortuneCell(rawFormula: '=B1', hasRawFormula: true),
    );

    expect(sheet.getCellValue(0, 0), 10);
    expect(sheet.getCellValue(0, 0, type: 'm'), 'ten');
    expect(sheet.getCellValue(0, 1, type: 'f'), '=A1');
    expect(text.getCellValue(1, 0), 'hello');
    expect(formula.getCellValue(1, 1, type: 'f'), '=A1');
    expect(mapped.getCellValue(1, 2), 42);
    expect(mapped.getCellValue(1, 2, type: 'm'), 'forty two');
    expect(mapped.getCellValue(1, 2, type: 'f'), '=SUM(A1:A2)');
    expect(sheet.getCellValue(0, 4), '2023-03-04');
    expect(sheet.getCellValue(0, 5), 44989);
    expect(mappedCell.rawBackground, '#ffeeaa');
    expect(mappedCell.bold, isTrue);
    expect(mappedCell.quotePrefix, isTrue);
    expect(mappedCell.extraFields['customFlag'], {'enabled': true});
    expect(cleared.getCellValue(0, 0), isNull);
    expect(cleared.getCellValue(0, 0, type: 'm'), isNull);
    expect(cleared.getCellValue(0, 0, type: 'f'), isNull);
    expect(cleared.cells[const FortuneCellCoord(0, 0)]!.bold, isTrue);
    expect(
      cleared.clearCell(0, 2).cells[const FortuneCellCoord(0, 2)]!.sparkline,
      {'type': 'line'},
    );
    expect(
      cleared.clearCell(0, 3).cells[const FortuneCellCoord(0, 3)]!.hasSparkline,
      isFalse,
    );
    expect(directClearCleanup.calcChain, [
      {'r': 2, 'c': 2, 'id': 's1'},
      {'r': 9, 'c': 9, 'id': 's1'},
    ]);
    expect(directClearCleanup.dynamicArray, [
      {'r': 2, 'c': 2},
      {'r': 9, 'c': 9},
    ]);
    expect(directClearCleanup.dynamicArrayCompute, {
      '2_2': true,
      '9_9': {'keep': true},
    });
    expect(
      directRawFormulaPreserved.calcChain,
      contains(equals({'r': 2, 'c': 2, 'id': 's1'})),
    );
    expect(
      directRawFormulaPreserved.dynamicArray,
      contains(equals({'r': 2, 'c': 2})),
    );
    expect(
      directRawFormulaPreserved.dynamicArrayCompute,
      containsPair('2_2', true),
    );
    expect(sheet.cells.containsKey(const FortuneCellCoord(1, 0)), isFalse);
  });

  test('workbook clearSheet preserves adjusted sheet metadata', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rowCount: 10,
          columnCount: 8,
          cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
          images: [
            FortuneImage(
              id: 'img1',
              src: 'data:image/png;base64,AA==',
              left: 1,
              top: 2,
              width: 3,
              height: 4,
            ),
          ],
          extraFields: const {
            fortuneSheetGridClientWidthMmKey: 80,
            fortuneSheetGridClientHeightMmKey: 50,
            fortuneSheetRulerVisibleKey: false,
            'labelRtfImportSource': true,
            fortuneSheetRulerGuidesKey: [
              {'id': 1, 'axis': 'vertical', 'positionMm': 12.5},
            ],
          },
        ),
      ],
    );

    final cleared = clearSheet(workbook, id: 's1');
    final sheet = cleared.activeSheet;

    expect(sheet.cells, isEmpty);
    expect(sheet.images, isEmpty);
    expect(
      fortuneSheetGridClientPhysicalSize(sheet),
      const FortuneSheetGridClientPhysicalSize(widthMm: 80, heightMm: 50),
    );
    expect(sheet.extraFields[fortuneSheetRulerVisibleKey], isFalse);
    expect(sheet.extraFields[fortuneSheetRulerGuidesKey], [
      {'id': 1, 'axis': 'vertical', 'positionMm': 12.5},
    ]);
    expect(sheet.extraFields.containsKey('labelRtfImportSource'), isFalse);
  });

  test('sheet sets cell formats through upstream public API shape', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A')},
    );

    final formatted = sheet
        .setCellFormat(0, 0, 'bg', '#ff0000')
        .setCellFormat(0, 0, 'fc', '#00ff00')
        .setCellFormat(0, 0, 'bl', 1)
        .setCellFormat(0, 0, 'ct', {'t': 'n', 'fa': '0.00'})
        .setCellFormat(0, 0, 'custom', {'flag': true})
        .setCellFormat(0, 0, 'bd', {
          'borderType': 'border-outside',
          'color': '#123456',
          'style': 2,
        });

    final cell = formatted.cells[const FortuneCellCoord(0, 0)]!;
    expect(cell.background, const Color(0xffff0000));
    expect(cell.rawBackground, '#ff0000');
    expect(cell.foreground, const Color(0xff00ff00));
    expect(cell.rawForeground, '#00ff00');
    expect(cell.bold, isTrue);
    expect(cell.rawBold, 1);
    expect(cell.cellType!.type, 'n');
    expect(cell.cellType!.format, '0.00');
    expect(cell.extraFields['custom'], {'flag': true});
    expect(formatted.borderInfo.single.borderType, 'border-outside');
    expect(formatted.borderInfo.single.color, const Color(0xff123456));
    expect(formatted.borderInfo.single.style, 2);
    expect(formatted.borderInfo.single.ranges.single.rowStart, 0);
    expect(formatted.borderInfo.single.ranges.single.columnStart, 0);
    expect(sheet.cells[const FortuneCellCoord(0, 0)]!.background, isNull);
  });

  test('sheet merges and cancels merges through upstream public API shape', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A')},
    );
    const range = FortuneRange(
      rowStart: 0,
      rowEnd: 1,
      columnStart: 0,
      columnEnd: 1,
    );

    final merged = sheet.mergeCells(range, 'merge-all');
    final anchor = merged.cells[const FortuneCellCoord(0, 0)]!;

    expect(anchor.merge?.row, 0);
    expect(anchor.merge?.column, 0);
    expect(anchor.merge?.rowSpan, 2);
    expect(anchor.merge?.columnSpan, 2);
    expect(merged.cells[const FortuneCellCoord(0, 1)]!.merge?.row, 0);
    expect(merged.cells[const FortuneCellCoord(1, 1)]!.merge?.column, 0);
    expect(
      merged.mergeAnchorFor(const FortuneCellCoord(1, 1)),
      const FortuneCellCoord(0, 0),
    );

    final horizontal = sheet.mergeCells(range, 'merge-horizontal');
    expect(horizontal.cells[const FortuneCellCoord(0, 0)]!.merge?.rowSpan, 1);
    expect(
      horizontal.cells[const FortuneCellCoord(0, 0)]!.merge?.columnSpan,
      2,
    );
    expect(horizontal.cells[const FortuneCellCoord(1, 0)]!.merge?.row, 1);
    expect(
      horizontal.cells[const FortuneCellCoord(1, 0)]!.merge?.columnSpan,
      2,
    );

    final vertical = sheet.mergeCells(range, 'merge-vertical');
    expect(vertical.cells[const FortuneCellCoord(0, 0)]!.merge?.rowSpan, 2);
    expect(vertical.cells[const FortuneCellCoord(0, 0)]!.merge?.columnSpan, 1);
    expect(vertical.cells[const FortuneCellCoord(0, 1)]!.merge?.column, 1);
    expect(vertical.cells[const FortuneCellCoord(0, 1)]!.merge?.rowSpan, 2);

    final cancelled = vertical.cancelMerge(range);
    expect(cancelled.cells[const FortuneCellCoord(0, 0)]!.value, 'A');
    expect(cancelled.cells[const FortuneCellCoord(0, 0)]!.merge, isNull);
    expect(cancelled.cells.containsKey(const FortuneCellCoord(0, 1)), isFalse);
    expect(sheet.cells[const FortuneCellCoord(0, 0)]!.merge, isNull);
  });

  test('sheet freezes panes through upstream public API shape', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      frozen: const FortuneFrozenPane(
        type: 'rangeRow',
        rowFocus: 5,
        columnFocus: 6,
        extraFields: {'legacy': true},
      ),
    );

    final row = sheet.freeze('row', row: 2, column: 3);
    final column = row.freeze('column', row: 4, column: 1);
    final both = column.freeze('both', row: 6, column: 7);
    final invalid = both.freeze('invalid', row: 8, column: 9);
    final negative = both.freeze('row', row: -1, column: 0);

    expect(row.frozen?.type, 'rangeRow');
    expect(row.frozen?.rowFocus, 2);
    expect(row.frozen?.columnFocus, 3);
    expect(row.frozen?.extraFields, isEmpty);
    expect(column.frozen?.type, 'rangeColumn');
    expect(column.frozen?.rowFocus, 4);
    expect(column.frozen?.columnFocus, 1);
    expect(both.frozen?.type, 'rangeBoth');
    expect(both.frozen?.rowFocus, 6);
    expect(both.frozen?.columnFocus, 7);
    expect(invalid.frozen?.type, 'rangeBoth');
    expect(negative.frozen?.type, 'rangeBoth');
    expect(sheet.frozen?.rowFocus, 5);
    expect(sheet.frozen?.extraFields, {'legacy': true});
  });

  test('frozen pane focus indices fall back to zero', () {
    const both = FortuneFrozenPane(type: 'rangeBoth');
    const rows = FortuneFrozenPane(type: 'rangeRow');
    const columns = FortuneFrozenPane(type: 'rangeColumn');

    expect(both.rowFocusIndex(5), 0);
    expect(both.columnFocusIndex(5), 0);
    expect(rows.rowFocusIndex(5), 0);
    expect(rows.columnFocusIndex(5), isNull);
    expect(columns.rowFocusIndex(5), isNull);
    expect(columns.columnFocusIndex(5), 0);
    expect(both.rowFocusIndex(0), isNull);
    expect(both.columnFocusIndex(-1), isNull);
  });

  test('sheet reads and writes cells through range API helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(value: 'A'),
        const FortuneCellCoord(0, 1): const FortuneCell(value: 'B'),
        const FortuneCellCoord(1, 0): const FortuneCell(value: 'C'),
      },
    );
    const range = FortuneRange(
      rowStart: 0,
      rowEnd: 1,
      columnStart: 0,
      columnEnd: 1,
    );

    final flattened = sheet.getFlattenRange([range]);
    final flatCells = sheet.getCellsByFlattenRange(flattened);
    final matrix = sheet.getCellsByRange(range);
    final written = sheet.setCellValuesByRange([
      ['R0C0', '=A1'],
      [3, null],
    ], range);
    final formatted = written.setCellFormatByRange('bl', 1, range);
    expect(flattened, const [
      FortuneCellCoord(0, 0),
      FortuneCellCoord(0, 1),
      FortuneCellCoord(1, 0),
      FortuneCellCoord(1, 1),
    ]);
    expect(flatCells.map((cell) => cell?.value), ['A', 'B', 'C', null]);
    expect(matrix[0][0]?.value, 'A');
    expect(matrix[0][1]?.value, 'B');
    expect(matrix[1][0]?.value, 'C');
    expect(matrix[1][1], isNull);
    expect(written.getCellValue(0, 0), 'R0C0');
    expect(written.getCellValue(0, 1, type: 'f'), '=A1');
    expect(written.getCellValue(1, 0), 3);
    expect(written.getCellValue(1, 1), isNull);
    expect(formatted.cells[const FortuneCellCoord(0, 0)]!.bold, isTrue);
    expect(formatted.cells[const FortuneCellCoord(1, 1)]!.bold, isTrue);
    expect(
      () => sheet.setCellValuesByRange([
        ['only one'],
      ], range),
      throwsA(isA<FortuneApiError>()),
    );
    expect(sheet.cells[const FortuneCellCoord(0, 0)]!.value, 'A');
  });

  test('sheet builds auto fill payload through upstream public API shape', () {
    final plainSheet = FortuneSheet(
      id: 'plain',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A')},
    );
    final numericSheet = FortuneSheet(
      id: 'numeric',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '1',
          displayValue: '1',
          cellType: FortuneCellType(type: 'n'),
        ),
      },
    );
    const copyRange = FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 0,
    );
    const applyRange = FortuneRange(
      rowStart: 1,
      rowEnd: 3,
      columnStart: 0,
      columnEnd: 0,
    );

    final plainPayload = autoFillCell(
      plainSheet,
      copyRange,
      applyRange,
      'down',
    );
    final numericPayload = autoFillCell(
      numericSheet,
      copyRange,
      applyRange,
      'down',
    );

    expect(plainPayload, {
      'copyRange': {
        'row': [0, 0],
        'column': [0, 0],
      },
      'applyRange': {
        'row': [1, 3],
        'column': [0, 0],
      },
      'direction': 'down',
      'applyType': '0',
    });
    expect(numericPayload, {
      'copyRange': {
        'row': [0, 0],
        'column': [0, 0],
      },
      'applyRange': {
        'row': [1, 3],
        'column': [0, 0],
      },
      'direction': 'down',
      'applyType': '1',
    });
  });

  test('sheet exports range values as upstream copy HTML table', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowHeights: {0: 24},
      columnWidths: {0: 90},
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff123456),
          style: 9,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
          ],
        ),
      ],
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: '<raw>',
          displayValue: 'Shown & safe',
          merge: FortuneCellMerge(row: 0, column: 0, rowSpan: 1, columnSpan: 2),
          background: Color(0xffffee00),
          foreground: Color(0xff112233),
          hasRawForeground: true,
          bold: true,
          italic: true,
          underline: true,
          fontSize: 12,
          horizontalAlign: 'center',
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          merge: FortuneCellMerge(row: 0, column: 0),
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          value: 'Plain',
          foreground: Color(0xff000000),
          rawForeground: '#000000',
          hasRawForeground: true,
          fontSize: 10,
          fontFamily: 'Tahoma',
          horizontalAlign: '2',
          verticalAlign: '0',
          textWrap: 'wrap',
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: 'Tiny',
          foreground: Color(0xff000000),
          underline: true,
          fontSize: 8,
        ),
        const FortuneCellCoord(2, 0): const FortuneCell(
          value: 'Inline',
          foreground: Color(0xffff0000),
          bold: true,
          fontSize: 14,
          inlineRuns: [FortuneInlineTextRun(text: 'Inline')],
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          value: 'Alpha',
          background: Color(0x80010203),
          foreground: Color(0x80040506),
        ),
      },
    );
    const range = FortuneRange(
      rowStart: 0,
      rowEnd: 2,
      columnStart: 0,
      columnEnd: 1,
    );

    final html = sheet.getHtmlByRange([range]);

    expect(html, contains('<table data-type="fortune-copy-action-table">'));
    expect(html, contains('<colgroup width="90px"></colgroup>'));
    expect(html, contains('<colgroup width="72px"></colgroup>'));
    expect(html, contains('<tr><td rowspan="1" colspan="2"'));
    expect(html, contains('height:24px;'));
    expect(html, contains('background-color:#ffee00;'));
    expect(html, contains('color:#112233;'));
    expect(html, contains('font-weight:bold;'));
    expect(html, contains('font-style:italic;'));
    expect(html, contains('border-bottom:1px solid #112233;'));
    expect(html, contains('font-size:12pt;'));
    expect(html, contains('text-align:center;'));
    expect(html, contains('border-left:1pt dashed #123456;'));
    expect(html, contains('border-top:1pt dashed #123456;'));
    expect(html, contains('border-bottom:1pt dashed #123456;'));
    expect(html, contains('Shown &amp; safe'));
    expect(
      html,
      contains(
        '<td style="height:19px;text-align:right;align-items:center;">Plain</td>',
      ),
    );
    expect(html, isNot(contains('font-size:10pt;')));
    expect(html, isNot(contains('color:#000000;')));
    expect(html, isNot(contains('font-family:Tahoma;')));
    expect(html, isNot(contains('white-space:normal;')));
    expect(html, contains('border-bottom:0px solid #000000;'));
    expect(html, isNot(contains('color:#ff0000;')));
    expect(html, isNot(contains('font-size:14pt;')));
    expect(html, contains('background-color:#010203;'));
    expect(html, contains('color:#040506;'));
    expect(html, isNot(contains('rgba(')));
    expect(html, isNot(contains('<raw>')));
  });

  test('sheet exports merged range perimeter borders as copy HTML', () {
    final sheet = FortuneSheet(
      id: 'merged-border-html',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-outside',
          color: Color(0xffabcdef),
          style: 13,
          ranges: [
            FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
          ],
        ),
      ],
      cells: {
        const FortuneCellCoord(0, 0): const FortuneCell(
          value: 'Merged',
          merge: FortuneCellMerge(row: 0, column: 0, rowSpan: 2, columnSpan: 2),
        ),
        const FortuneCellCoord(0, 1): const FortuneCell(
          merge: FortuneCellMerge(row: 0, column: 0),
        ),
        const FortuneCellCoord(1, 0): const FortuneCell(
          merge: FortuneCellMerge(row: 0, column: 0),
        ),
        const FortuneCellCoord(1, 1): const FortuneCell(
          merge: FortuneCellMerge(row: 0, column: 0),
        ),
      },
    );

    final html = sheet.getHtmlByRange(const [
      FortuneRange(rowStart: 0, rowEnd: 1, columnStart: 0, columnEnd: 1),
    ]);

    expect(html, contains('rowspan="2" colspan="2"'));
    expect(html, contains('border-left:1.5pt solid #abcdef;'));
    expect(html, contains('border-right:1.5pt solid #abcdef;'));
    expect(html, contains('border-top:1.5pt solid #abcdef;'));
    expect(html, contains('border-bottom:1.5pt solid #abcdef;'));
  });

  test('sheet reads and writes selection through public API helpers', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      selectionSave: [
        {
          'row': [0, 0],
          'column': [0, 0],
          'row_focus': 0,
          'column_focus': 0,
          'custom': {'source': 'raw'},
        },
        {
          'row': [1, 2],
          'column': [26, 27],
        },
        {
          'row': [3],
          'column': [0, 0],
        },
      ],
    );

    final selection = sheet.getSelection();
    final coordinates = sheet.getSelectionCoordinates();
    final selected = sheet.setSelection([
      const FortuneRange(
        rowStart: 2,
        rowEnd: 3,
        columnStart: 1,
        columnEnd: 2,
        rowFocus: 2,
        columnFocus: 1,
        extraFields: {'color': '#0188fb'},
      ),
    ]);

    expect(selection, hasLength(2));
    expect(selection.first.rowStart, 0);
    expect(selection.first.columnStart, 0);
    expect(selection.first.rowFocus, 0);
    expect(selection.first.columnFocus, 0);
    expect(selection.first.extraFields['custom'], {'source': 'raw'});
    expect(selection.last.rowStart, 1);
    expect(selection.last.rowEnd, 2);
    expect(selection.last.columnStart, 26);
    expect(selection.last.columnEnd, 27);
    expect(coordinates, ['A1', 'AA2:AB3']);
    expect(selected.selectionSave, [
      {
        'color': '#0188fb',
        'row': [2, 3],
        'column': [1, 2],
        'row_focus': 2,
        'column_focus': 1,
      },
    ]);
    expect(sheet.getSelectionCoordinates(), ['A1', 'AA2:AB3']);
  });

  test('sheet row and column size readers prefer sheet defaults', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      defaultRowHeight: 25,
      defaultColWidth: 90,
      rowHeights: {3: 44},
      columnWidths: {4: 120},
    );
    const settings = FortuneSettings(defaultRowHeight: 30, defaultColWidth: 80);

    expect(sheet.getRowHeights([2, 3], settings: settings), {2: 25, 3: 44});
    expect(sheet.getColumnWidths([2, 4], settings: settings), {2: 90, 4: 120});
  });

  test('sheet sets row heights and column widths with custom flags', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowHeights: {1: 24},
      columnWidths: {1: 70},
      customHeight: {1: 1},
      customWidth: {1: 1},
    );

    final rows = sheet.setRowHeight({-1: 10, 1: 30, 2: 40}, custom: true);
    final columns = sheet.setColumnWidth({-1: 10, 1: 80, 3: 120});

    expect(rows.rowHeights, {1: 30, 2: 40});
    expect(rows.customHeight, {1: 1, 2: 1});
    expect(columns.columnWidths, {1: 80, 3: 120});
    expect(columns.customWidth, {1: 1});
    expect(sheet.rowHeights, {1: 24});
    expect(sheet.columnWidths, {1: 70});
  });

  test(
    'sheet inserts and deletes rows and columns through public API shape',
    () {
      final sheet = FortuneSheet(
        id: 's1',
        name: 'Sheet1',
        rowCount: 4,
        columnCount: 4,
        cells: {
          const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1'),
          const FortuneCellCoord(1, 1): const FortuneCell(value: 'B2'),
          const FortuneCellCoord(3, 3): const FortuneCell(
            value: 'D4',
            merge: FortuneCellMerge(
              row: 3,
              column: 3,
              rowSpan: 1,
              columnSpan: 1,
            ),
          ),
        },
        nullCells: {const FortuneCellCoord(2, 2)},
        rowHeights: {1: 30, 3: 40},
        columnWidths: {1: 80, 3: 120},
        customHeight: {3: 1},
        customWidth: {3: 1},
        rawRowHeights: {'1': 30, '3': 40, 'legacy': 'kept'},
        hasRawRowHeights: true,
        rawColumnWidths: {'1': 80, '3': 120, 'legacy': 'kept'},
        hasRawColumnWidths: true,
        rawCustomHeight: {'3': 1, 'legacy': 'kept'},
        hasRawCustomHeight: true,
        rawCustomWidth: {'3': 1, 'legacy': 'kept'},
        hasRawCustomWidth: true,
        hiddenRows: {3},
        hiddenColumns: {3},
        hiddenRowValues: {3: 0},
        hiddenColumnValues: {3: 0},
        rawHiddenRows: {'3': 0, 'legacy': 'kept'},
        hasRawHiddenRows: true,
        rawHiddenColumns: {'3': 0, 'legacy': 'kept'},
        hasRawHiddenColumns: true,
      );

      final insertedRow = sheet.insertRowOrColumn(
        'row',
        1,
        1,
        direction: 'lefttop',
      );
      final deletedRow = insertedRow.deleteRowOrColumn('row', 2, 2);
      final insertedColumn = sheet.insertRowOrColumn('column', 1, 1);
      final deletedColumn = insertedColumn.deleteRowOrColumn('column', 2, 2);

      expect(insertedRow.rowCount, 5);
      expect(insertedRow.cells[const FortuneCellCoord(0, 0)]?.value, 'A1');
      expect(insertedRow.cells[const FortuneCellCoord(2, 1)]?.value, 'B2');
      expect(insertedRow.cells[const FortuneCellCoord(4, 3)]?.value, 'D4');
      expect(insertedRow.cells[const FortuneCellCoord(4, 3)]?.merge?.row, 4);
      expect(insertedRow.cells[const FortuneCellCoord(4, 3)]?.merge?.column, 3);
      expect(insertedRow.nullCells, {const FortuneCellCoord(3, 2)});
      expect(insertedRow.rowHeights, {2: 30, 4: 40});
      expect(insertedRow.rawRowHeights, {'2': 30, '4': 40, 'legacy': 'kept'});
      expect(insertedRow.hasRawRowHeights, isTrue);
      expect(insertedRow.customHeight, {4: 1});
      expect(insertedRow.rawCustomHeight, {'4': 1, 'legacy': 'kept'});
      expect(insertedRow.hasRawCustomHeight, isTrue);
      expect(insertedRow.hiddenRows, {4});
      expect(insertedRow.hiddenRowValues, {4: 0});
      expect(insertedRow.rawHiddenRows, {'4': 0, 'legacy': 'kept'});
      expect(insertedRow.hasRawHiddenRows, isTrue);
      expect(deletedRow.rowCount, 4);
      expect(deletedRow.cells[const FortuneCellCoord(1, 1)], isNull);
      expect(deletedRow.cells[const FortuneCellCoord(3, 3)]?.value, 'D4');
      expect(deletedRow.cells[const FortuneCellCoord(3, 3)]?.merge?.row, 3);
      expect(deletedRow.cells[const FortuneCellCoord(3, 3)]?.merge?.column, 3);
      expect(deletedRow.rowHeights, {3: 40});
      expect(deletedRow.rawRowHeights, {'3': 40, 'legacy': 'kept'});
      expect(deletedRow.rawCustomHeight, {'3': 1, 'legacy': 'kept'});
      expect(deletedRow.rawHiddenRows, {'3': 0, 'legacy': 'kept'});
      expect(insertedColumn.columnCount, 5);
      expect(insertedColumn.cells[const FortuneCellCoord(1, 1)]?.value, 'B2');
      expect(insertedColumn.cells[const FortuneCellCoord(3, 4)]?.value, 'D4');
      expect(insertedColumn.cells[const FortuneCellCoord(3, 4)]?.merge?.row, 3);
      expect(
        insertedColumn.cells[const FortuneCellCoord(3, 4)]?.merge?.column,
        4,
      );
      expect(insertedColumn.nullCells, {const FortuneCellCoord(2, 3)});
      expect(insertedColumn.columnWidths, {1: 80, 4: 120});
      expect(insertedColumn.rawColumnWidths, {
        '1': 80,
        '4': 120,
        'legacy': 'kept',
      });
      expect(insertedColumn.hasRawColumnWidths, isTrue);
      expect(insertedColumn.customWidth, {4: 1});
      expect(insertedColumn.rawCustomWidth, {'4': 1, 'legacy': 'kept'});
      expect(insertedColumn.hasRawCustomWidth, isTrue);
      expect(insertedColumn.hiddenColumns, {4});
      expect(insertedColumn.hiddenColumnValues, {4: 0});
      expect(insertedColumn.rawHiddenColumns, {'4': 0, 'legacy': 'kept'});
      expect(insertedColumn.hasRawHiddenColumns, isTrue);
      expect(deletedColumn.columnCount, 4);
      expect(deletedColumn.cells[const FortuneCellCoord(3, 3)]?.value, 'D4');
      expect(deletedColumn.cells[const FortuneCellCoord(3, 3)]?.merge?.row, 3);
      expect(
        deletedColumn.cells[const FortuneCellCoord(3, 3)]?.merge?.column,
        3,
      );
      expect(deletedColumn.columnWidths, {1: 80, 3: 120});
      expect(deletedColumn.rawColumnWidths, {
        '1': 80,
        '3': 120,
        'legacy': 'kept',
      });
      expect(deletedColumn.rawCustomWidth, {'3': 1, 'legacy': 'kept'});
      expect(deletedColumn.rawHiddenColumns, {'3': 0, 'legacy': 'kept'});
      (insertedRow.rawRowHeights! as Map)['2'] = 'mutated';
      expect(sheet.rawRowHeights, {'1': 30, '3': 40, 'legacy': 'kept'});
      expect(sheet.cells[const FortuneCellCoord(1, 1)]?.value, 'B2');
    },
  );

  test('sheet insert and delete rewrites formula references', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowCount: 8,
      columnCount: 8,
      cells: {
        const FortuneCellCoord(0, 3): const FortuneCell(
          formula: r'=SUM(A1:A3)+$B$2+Sheet1!C3+"A1"+LOG10(A1)',
          rawFormula: r'=SUM(A1:A3)+$B$2+Sheet1!C3+"A1"+LOG10(A1)',
          hasRawFormula: true,
        ),
        const FortuneCellCoord(1, 4): const FortuneCell(
          formula: '=SUM(A1:D1)+C2+E2',
        ),
        const FortuneCellCoord(3, 0): const FortuneCell(
          formula: '=SUM(A1:A4)+B3+C5',
        ),
        const FortuneCellCoord(4, 4): const FortuneCell(
          formula: '=SUM(1:3)+SUM(A:C)+SUM(Sheet1!2:4)+SUM(Sheet1!B:D)',
        ),
        const FortuneCellCoord(5, 5): const FortuneCell(
          formula: '=SUM(1:4)+SUM(2:3)+SUM(A:D)+SUM(B:C)',
        ),
        const FortuneCellCoord(6, 6): const FortuneCell(
          formula: '=SUM(Sheet1!A1:Other!A3)+SUM(C3:A1)',
        ),
        const FortuneCellCoord(7, 7): const FortuneCell(
          formula:
              "='O''Brien'!A1+'O''Brien'!B2+SUM('O''Brien'!A1:'O''Brien'!A3)",
        ),
        const FortuneCellCoord(8, 0): const FortuneCell(
          formula:
              "=SUM('[Book1.xlsx]Q1'' Plan'!A1:'[Book1.xlsx]Q1'' Plan'!A3)+SUM('[Book1.xlsx]Q1'' Plan'!A:C)+SUM('[Book1.xlsx]Q1'' Plan'!1:3)",
        ),
      },
    );

    final insertedRow = sheet.insertRowOrColumn(
      'row',
      1,
      2,
      direction: 'lefttop',
    );
    final insertedColumn = sheet.insertRowOrColumn('column', 1, 1);
    final deletedRow = sheet.deleteRowOrColumn('row', 1, 2);
    final deletedColumn = sheet.deleteRowOrColumn('column', 1, 2);

    final rowFormula = insertedRow.cells[const FortuneCellCoord(0, 3)]?.formula;
    expect(rowFormula, r'=SUM(A1:A5)+$B$4+Sheet1!C5+"A1"+LOG10(A1)');
    expect(
      insertedRow.cells[const FortuneCellCoord(0, 3)]?.rawFormula,
      rowFormula,
    );
    expect(
      insertedColumn.cells[const FortuneCellCoord(1, 5)]?.formula,
      '=SUM(A1:E1)+D2+F2',
    );
    expect(
      deletedRow.cells[const FortuneCellCoord(1, 0)]?.formula,
      '=SUM(A1:A2)+#REF!+C3',
    );
    expect(
      deletedColumn.cells[const FortuneCellCoord(1, 2)]?.formula,
      '=SUM(A1:B1)+#REF!+C2',
    );
    expect(
      insertedRow.cells[const FortuneCellCoord(6, 4)]?.formula,
      '=SUM(1:5)+SUM(A:C)+SUM(Sheet1!4:6)+SUM(Sheet1!B:D)',
    );
    expect(
      insertedColumn.cells[const FortuneCellCoord(4, 5)]?.formula,
      '=SUM(1:3)+SUM(A:D)+SUM(Sheet1!2:4)+SUM(Sheet1!B:E)',
    );
    expect(
      deletedRow.cells[const FortuneCellCoord(3, 5)]?.formula,
      '=SUM(1:2)+SUM(#REF!)+SUM(A:D)+SUM(B:C)',
    );
    expect(
      deletedColumn.cells[const FortuneCellCoord(5, 3)]?.formula,
      '=SUM(1:4)+SUM(2:3)+SUM(A:B)+SUM(#REF!)',
    );
    expect(
      insertedRow.cells[const FortuneCellCoord(8, 6)]?.formula,
      '=SUM(Sheet1!A1:Other!A3)+SUM(C3:A1)',
    );
    expect(
      insertedRow.cells[const FortuneCellCoord(9, 7)]?.formula,
      "='O''Brien'!A1+'O''Brien'!B4+SUM('O''Brien'!A1:'O''Brien'!A5)",
    );
    expect(
      deletedRow.cells[const FortuneCellCoord(5, 7)]?.formula,
      "='O''Brien'!A1+#REF!+SUM('O''Brien'!A1:'O''Brien'!A2)",
    );
    expect(
      insertedRow.cells[const FortuneCellCoord(10, 0)]?.formula,
      "=SUM('[Book1.xlsx]Q1'' Plan'!A1:'[Book1.xlsx]Q1'' Plan'!A5)+SUM('[Book1.xlsx]Q1'' Plan'!A:C)+SUM('[Book1.xlsx]Q1'' Plan'!1:5)",
    );
    expect(
      insertedColumn.cells[const FortuneCellCoord(8, 0)]?.formula,
      "=SUM('[Book1.xlsx]Q1'' Plan'!A1:'[Book1.xlsx]Q1'' Plan'!A3)+SUM('[Book1.xlsx]Q1'' Plan'!A:D)+SUM('[Book1.xlsx]Q1'' Plan'!1:3)",
    );
    expect(
      deletedRow.cells[const FortuneCellCoord(6, 0)]?.formula,
      "=SUM('[Book1.xlsx]Q1'' Plan'!A1:'[Book1.xlsx]Q1'' Plan'!A2)+SUM('[Book1.xlsx]Q1'' Plan'!A:C)+SUM('[Book1.xlsx]Q1'' Plan'!1:1)",
    );
    expect(
      deletedColumn.cells[const FortuneCellCoord(8, 0)]?.formula,
      "=SUM('[Book1.xlsx]Q1'' Plan'!A1:'[Book1.xlsx]Q1'' Plan'!A3)+SUM('[Book1.xlsx]Q1'' Plan'!A:A)+SUM('[Book1.xlsx]Q1'' Plan'!1:3)",
    );
  });

  test('sheet insert and delete shifts coordinate keyed metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      dataVerification: {
        '1_1': {'type': 'dropdown', 'value1': 'A,B'},
        '3_2': {'type': 'number', 'value1': 10},
      },
      rawDataVerification: {
        '1_1': {'rawType': 'dropdown', 'value1': 'A,B'},
        '3_2': {'rawType': 'number', 'value1': 10},
        'meta': {'scope': 'sheet'},
      },
      hasRawDataVerification: true,
      hyperlinks: {
        '1_1': {'linkAddress': 'https://a.example'},
        '3_2': {'linkAddress': 'https://b.example'},
      },
      rawHyperlinks: {
        '1_1': {'rawLinkAddress': 'https://a.example'},
        '3_2': {'rawLinkAddress': 'https://b.example'},
        'meta': {'scope': 'sheet'},
      },
      hasRawHyperlinks: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 1, 2);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      1,
      2,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 1, 2);
    final deletedColumn = sheet.deleteRowOrColumn('column', 1, 1);

    expect(insertedRow.dataVerification.keys, {'1_1', '2_1', '3_1', '5_2'});
    expect(insertedRow.rawDataVerification, isA<Map>());
    expect((insertedRow.rawDataVerification! as Map).keys, {
      '1_1',
      '2_1',
      '3_1',
      '5_2',
      'meta',
    });
    expect(insertedRow.hasRawDataVerification, isTrue);
    expect(insertedRow.dataVerification['2_1'], {
      'type': 'dropdown',
      'value1': 'A,B',
    });
    expect((insertedRow.rawDataVerification! as Map)['2_1'], {
      'rawType': 'dropdown',
      'value1': 'A,B',
    });
    expect(insertedRow.hyperlinks.keys, {'1_1', '5_2'});
    expect((insertedRow.rawHyperlinks! as Map).keys, {'1_1', '5_2', 'meta'});
    expect(insertedRow.hasRawHyperlinks, isTrue);
    expect(insertedColumn.dataVerification.keys, {'1_1', '1_2', '1_3', '3_4'});
    expect((insertedColumn.rawDataVerification! as Map).keys, {
      '1_1',
      '1_2',
      '1_3',
      '3_4',
      'meta',
    });
    expect(insertedColumn.hyperlinks.keys, {'1_3', '3_4'});
    expect((insertedColumn.rawHyperlinks! as Map).keys, {'1_3', '3_4', 'meta'});
    expect(deletedRow.dataVerification.keys, {'1_2'});
    expect((deletedRow.rawDataVerification! as Map).keys, {'1_2', 'meta'});
    expect(deletedRow.hyperlinks.keys, {'1_2'});
    expect((deletedRow.rawHyperlinks! as Map).keys, {'1_2', 'meta'});
    expect(deletedColumn.dataVerification.keys, {'3_1'});
    expect((deletedColumn.rawDataVerification! as Map).keys, {'3_1', 'meta'});
    expect(deletedColumn.hyperlinks.keys, {'3_1'});
    expect((deletedColumn.rawHyperlinks! as Map).keys, {'3_1', 'meta'});

    (insertedRow.dataVerification['2_1']! as Map)['value1'] = 'mutated';
    ((insertedRow.rawDataVerification! as Map)['2_1']! as Map)['value1'] =
        'mutated';
    ((insertedRow.rawHyperlinks! as Map)['5_2']! as Map)['rawLinkAddress'] =
        'mutated';
    expect(sheet.dataVerification['1_1'], {
      'type': 'dropdown',
      'value1': 'A,B',
    });
    expect((sheet.rawDataVerification! as Map)['1_1'], {
      'rawType': 'dropdown',
      'value1': 'A,B',
    });
    expect((sheet.rawHyperlinks! as Map)['3_2'], {
      'rawLinkAddress': 'https://b.example',
    });
  });

  test('sheet insert and delete shifts frozen pane focus', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      frozen: FortuneFrozenPane(
        type: 'rangeBoth',
        rowFocus: 3,
        rawRowFocus: '3',
        hasRawRowFocus: true,
        columnFocus: 4,
        rawColumnFocus: '4',
        hasRawColumnFocus: true,
      ),
    );

    final insertedRow = sheet.insertRowOrColumn('row', 2, 2);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      4,
      1,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 1, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 5);
    final rowOnlyInsertedColumn = sheet
        .freeze('row', row: 3, column: 4)
        .insertRowOrColumn('column', 1, 1);

    expect(insertedRow.frozen?.rowFocus, 5);
    expect(insertedRow.frozen?.columnFocus, 4);
    expect(insertedRow.frozen?.hasRawRowFocus, isFalse);
    expect(insertedColumn.frozen?.rowFocus, 3);
    expect(insertedColumn.frozen?.columnFocus, 5);
    expect(insertedColumn.frozen?.hasRawColumnFocus, isFalse);
    expect(deletedRow.frozen?.rowFocus, 0);
    expect(deletedRow.frozen?.columnFocus, 4);
    expect(deletedColumn.frozen?.rowFocus, 3);
    expect(deletedColumn.frozen?.columnFocus, 1);
    expect(rowOnlyInsertedColumn.frozen?.type, 'rangeRow');
    expect(rowOnlyInsertedColumn.frozen?.columnFocus, 4);
  });

  test('sheet insert and delete preserves image metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      images: const [
        FortuneImage(
          id: 'img1',
          src: 'data:image/png;base64,abc',
          left: 12,
          top: 34,
          width: 56,
          height: 78,
          extraFields: {'alt': 'keep'},
        ),
      ],
      rawImages: {
        'img1': {
          'src': 'data:image/png;base64,abc',
          'default': {'left': 12, 'top': 34},
        },
        'meta': {'value': 'keep'},
      },
      hasRawImages: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 1, 2);
    final insertedColumn = sheet.insertRowOrColumn('column', 1, 2);
    final deletedRow = sheet.deleteRowOrColumn('row', 1, 2);
    final deletedColumn = sheet.deleteRowOrColumn('column', 1, 1);

    for (final next in [
      insertedRow,
      insertedColumn,
      deletedRow,
      deletedColumn,
    ]) {
      expect(next.images.single.id, 'img1');
      expect(next.images.single.top, 34);
      expect(next.images.single.left, 12);
      expect(next.images.single.extraFields, {'alt': 'keep'});
      expect(next.rawImages, isA<Map>());
      expect(next.hasRawImages, isTrue);
      expect(((next.rawImages! as Map)['meta'] as Map)['value'], 'keep');
    }

    insertedRow.images.single.extraFields['alt'] = 'mutated';
    (((insertedRow.rawImages! as Map)['img1'] as Map)['default']
            as Map)['top'] =
        'mutated';
    expect(sheet.images.single.extraFields, {'alt': 'keep'});
    expect(((sheet.rawImages! as Map)['img1'] as Map)['default'], {
      'left': 12,
      'top': 34,
    });
  });

  test('sheet insert and delete shifts calc chain coordinates', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      calcChain: [
        {
          'r': 1,
          'c': 1,
          'id': 's1',
          'extra': {'value': 'keep'},
        },
        {'r': 3, 'c': 2, 'id': 's1'},
        {'r': 5, 'c': 4, 'id': 's1'},
        {'c': 7, 'id': 'missing-row'},
        'legacy',
      ],
    );

    final insertedRow = sheet.insertRowOrColumn('row', 1, 2);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      2,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 4);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 3);

    expect(insertedRow.hasRawCalcChain, isTrue);
    expect(insertedRow.calcChain, [
      {
        'r': 1,
        'c': 1,
        'id': 's1',
        'extra': {'value': 'keep'},
      },
      {'r': 5, 'c': 2, 'id': 's1'},
      {'r': 7, 'c': 4, 'id': 's1'},
      {'c': 7, 'id': 'missing-row'},
      'legacy',
    ]);
    expect(insertedColumn.calcChain, [
      {
        'r': 1,
        'c': 1,
        'id': 's1',
        'extra': {'value': 'keep'},
      },
      {'r': 3, 'c': 4, 'id': 's1'},
      {'r': 5, 'c': 6, 'id': 's1'},
      {'c': 9, 'id': 'missing-row'},
      'legacy',
    ]);
    expect(deletedRow.calcChain, [
      {
        'r': 1,
        'c': 1,
        'id': 's1',
        'extra': {'value': 'keep'},
      },
      {'r': 2, 'c': 4, 'id': 's1'},
      {'c': 7, 'id': 'missing-row'},
      'legacy',
    ]);
    expect(deletedColumn.calcChain, [
      {
        'r': 1,
        'c': 1,
        'id': 's1',
        'extra': {'value': 'keep'},
      },
      {'r': 5, 'c': 2, 'id': 's1'},
      {'c': 5, 'id': 'missing-row'},
      'legacy',
    ]);

    final insertedExtra =
        ((insertedRow.calcChain! as List).first as Map)['extra'] as Map;
    insertedExtra['value'] = 'mutated';
    final originalExtra =
        ((sheet.calcChain! as List).first as Map)['extra'] as Map;
    expect(originalExtra['value'], 'keep');
  });

  test('sheet insert and delete shifts pivot and dynamic array metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      pivotTable: {
        'pivot_select_save': {
          'row': [1, 3],
          'column': [2, 4],
          'row_focus': 1,
          'column_focus': 2,
          'nested': {'r': 4, 'c': 4, 'value': 'keep'},
        },
        'source': [
          {'r': 1, 'c': 2, 'sourceExtra': true},
          {'r': 4, 'c': 5},
        ],
      },
      hasRawPivotTable: true,
      dynamicArrayCompute: {
        '1_2': {'computeExtra': true},
        '4_5': true,
        'legacy': 'keep',
      },
      hasRawDynamicArrayCompute: true,
      dynamicArray: [
        {'r': 1, 'c': 2, 'arrayExtra': true},
        {'r': 4, 'c': 5},
        'legacy',
      ],
      hasRawDynamicArray: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 1, 2);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      1,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 3, 3);

    final rowPivot = insertedRow.pivotTable! as Map;
    final rowSelection = rowPivot['pivot_select_save']! as Map;
    expect(rowSelection['row'], [1, 5]);
    expect(rowSelection['row_focus'], 1);
    expect((rowSelection['nested'] as Map)['r'], 6);
    expect(((rowPivot['source'] as List)[0] as Map)['r'], 1);
    expect(((rowPivot['source'] as List)[1] as Map)['r'], 6);
    expect((insertedRow.dynamicArrayCompute! as Map).keys, {
      '1_2',
      '6_5',
      'legacy',
    });
    expect(((insertedRow.dynamicArray! as List)[1] as Map)['r'], 6);

    final columnPivot = insertedColumn.pivotTable! as Map;
    final columnSelection = columnPivot['pivot_select_save']! as Map;
    expect(columnSelection['column'], [3, 5]);
    expect(columnSelection['column_focus'], 3);
    expect((columnSelection['nested'] as Map)['c'], 5);
    expect(((columnPivot['source'] as List)[0] as Map)['c'], 3);
    expect(((columnPivot['source'] as List)[1] as Map)['c'], 6);
    expect((insertedColumn.dynamicArrayCompute! as Map).keys, {
      '1_3',
      '4_6',
      'legacy',
    });
    expect(((insertedColumn.dynamicArray! as List)[0] as Map)['c'], 3);

    final deletedRowPivot = deletedRow.pivotTable! as Map;
    final deletedRowSelection = deletedRowPivot['pivot_select_save']! as Map;
    expect(deletedRowSelection['row'], [1, 1]);
    expect(deletedRowSelection['row_focus'], 1);
    expect((deletedRowSelection['nested'] as Map)['r'], 2);
    expect(((deletedRowPivot['source'] as List)[0] as Map)['r'], 1);
    expect(((deletedRowPivot['source'] as List)[1] as Map)['r'], 2);
    expect((deletedRow.dynamicArrayCompute! as Map).keys, {
      '1_2',
      '2_5',
      'legacy',
    });
    expect(((deletedRow.dynamicArray! as List)[0] as Map)['r'], 1);
    expect(((deletedRow.dynamicArray! as List)[1] as Map)['r'], 2);

    final deletedColumnPivot = deletedColumn.pivotTable! as Map;
    final deletedColumnSelection =
        deletedColumnPivot['pivot_select_save']! as Map;
    expect(deletedColumnSelection['column'], [2, 3]);
    expect(deletedColumnSelection['column_focus'], 2);
    expect((deletedColumnSelection['nested'] as Map)['c'], 3);
    expect(((deletedColumnPivot['source'] as List)[0] as Map)['c'], 2);
    expect(((deletedColumnPivot['source'] as List)[1] as Map)['c'], 4);
    expect((deletedColumn.dynamicArrayCompute! as Map).keys, {
      '1_2',
      '4_4',
      'legacy',
    });
    expect(((deletedColumn.dynamicArray! as List)[1] as Map)['c'], 4);

    (rowSelection['nested'] as Map)['value'] = 'mutated';
    final originalSelection =
        (sheet.pivotTable! as Map)['pivot_select_save']! as Map;
    expect((originalSelection['nested'] as Map)['value'], 'keep');
  });

  test('sheet insert and delete shifts format cell ranges', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      conditionFormats: [
        {
          'type': 'colorScale',
          'cellrange': [
            {
              'row': [1, 3],
              'column': [1, 2],
            },
            {
              'row': [4, 5],
              'column': [4, 5],
            },
          ],
          'extra': {'value': 'keep'},
        },
        {
          'type': 'removed',
          'cellrange': [
            {
              'row': [2, 3],
              'column': [0, 0],
            },
          ],
        },
      ],
      alternateFormats: [
        {
          'format': 'banded',
          'cellrange': {
            'row': [1, 3],
            'column': [1, 2],
          },
          'extra': {'value': 'keep'},
        },
        {
          'format': 'removed',
          'cellrange': {
            'row': [2, 3],
            'column': [4, 5],
          },
        },
      ],
    );

    final insertedRow = sheet.insertRowOrColumn(
      'row',
      2,
      2,
      direction: 'lefttop',
    );
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      1,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 4);

    final insertedRowCondition =
        (insertedRow.conditionFormats! as List).first as Map;
    expect(insertedRow.hasRawConditionFormats, isTrue);
    expect(insertedRowCondition['cellrange'], [
      {
        'row': [1, 5],
        'column': [1, 2],
      },
      {
        'row': [6, 7],
        'column': [4, 5],
      },
    ]);
    expect(
      ((insertedRow.alternateFormats! as List).first as Map)['cellrange'],
      {
        'row': [1, 5],
        'column': [1, 2],
      },
    );
    expect(insertedRow.hasRawAlternateFormats, isTrue);

    final insertedColumnCondition =
        (insertedColumn.conditionFormats! as List).first as Map;
    expect(insertedColumn.hasRawConditionFormats, isTrue);
    expect(insertedColumn.hasRawAlternateFormats, isTrue);
    expect(insertedColumnCondition['cellrange'], [
      {
        'row': [1, 3],
        'column': [1, 3],
      },
      {
        'row': [4, 5],
        'column': [5, 6],
      },
    ]);

    final deletedRowConditions = deletedRow.conditionFormats! as List;
    expect(deletedRowConditions, hasLength(1));
    expect((deletedRowConditions.single as Map)['cellrange'], [
      {
        'row': [1, 1],
        'column': [1, 2],
      },
      {
        'row': [2, 3],
        'column': [4, 5],
      },
    ]);
    expect(deletedRow.alternateFormats, [
      {
        'format': 'banded',
        'cellrange': {
          'row': [1, 1],
          'column': [1, 2],
        },
        'extra': {'value': 'keep'},
      },
    ]);
    expect(deletedRow.hasRawConditionFormats, isTrue);
    expect(deletedRow.hasRawAlternateFormats, isTrue);

    final deletedColumnCondition =
        (deletedColumn.conditionFormats! as List).first as Map;
    expect(deletedColumn.hasRawConditionFormats, isTrue);
    expect(deletedColumn.hasRawAlternateFormats, isTrue);
    expect(deletedColumnCondition['cellrange'], [
      {
        'row': [1, 3],
        'column': [1, 1],
      },
      {
        'row': [4, 5],
        'column': [2, 2],
      },
    ]);

    final insertedExtra = insertedRowCondition['extra'] as Map;
    insertedExtra['value'] = 'mutated';
    final originalExtra =
        ((sheet.conditionFormats! as List).first as Map)['extra'] as Map;
    expect(originalExtra['value'], 'keep');
    final insertedAlternateExtra =
        ((insertedRow.alternateFormats! as List).first as Map)['extra'] as Map;
    insertedAlternateExtra['value'] = 'mutated';
    final originalAlternateExtra =
        ((sheet.alternateFormats! as List).first as Map)['extra'] as Map;
    expect(originalAlternateExtra['value'], 'keep');
  });

  test('sheet insert and delete updates selection metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowCount: 6,
      columnCount: 5,
      selectionSave: [
        {
          'row': [1, 1],
          'column': [1, 1],
        },
      ],
      hasRawSelectionSave: true,
      selectionRange: [
        {
          'row': [2, 3],
          'column': [2, 3],
          'row_focus': 2,
          'column_focus': 2,
          'extra': {'value': 'keep'},
        },
      ],
      hasRawSelectionRange: true,
    );

    final insertedRow = sheet.insertRowOrColumn(
      'row',
      2,
      2,
      direction: 'lefttop',
    );
    final insertedColumn = sheet.insertRowOrColumn('column', 2, 2);
    final deletedRow = sheet.deleteRowOrColumn('row', 1, 1);
    final deletedColumn = sheet.deleteRowOrColumn('column', 1, 1);

    expect(insertedRow.selectionSave, [
      {
        'row': [2, 3],
        'column': [0, 4],
      },
    ]);
    expect(insertedRow.selectionRange, [
      {
        'row': [4, 5],
        'column': [2, 3],
        'row_focus': 4,
        'column_focus': 2,
        'extra': {'value': 'keep'},
      },
    ]);
    expect(insertedRow.hasRawSelectionRange, isTrue);
    expect(insertedRow.getSelectionCoordinates(), ['A3:E4']);
    expect(insertedColumn.selectionSave, [
      {
        'row': [0, 5],
        'column': [3, 4],
      },
    ]);
    expect(insertedColumn.selectionRange, [
      {
        'row': [2, 3],
        'column': [2, 5],
        'row_focus': 2,
        'column_focus': 2,
        'extra': {'value': 'keep'},
      },
    ]);
    expect(insertedColumn.getSelectionCoordinates(), ['D1:E6']);
    expect(deletedRow.selectionSave, isNull);
    expect(deletedRow.hasRawSelectionSave, isFalse);
    expect(deletedRow.selectionRange, [
      {
        'row': [1, 2],
        'column': [2, 3],
        'row_focus': 1,
        'column_focus': 2,
        'extra': {'value': 'keep'},
      },
    ]);
    expect(deletedRow.hasRawSelectionRange, isTrue);
    expect(deletedColumn.selectionSave, isNull);
    expect(deletedColumn.hasRawSelectionSave, isFalse);
    expect(deletedColumn.selectionRange, [
      {
        'row': [2, 3],
        'column': [1, 2],
        'row_focus': 2,
        'column_focus': 1,
        'extra': {'value': 'keep'},
      },
    ]);
    final insertedRowSelectionRange =
        (insertedRow.selectionRange! as List).single as Map;
    (insertedRowSelectionRange['extra'] as Map)['value'] = 'mutated';
    final originalSelectionRange =
        (sheet.selectionRange! as List).single as Map;
    expect((originalSelectionRange['extra'] as Map)['value'], 'keep');
    expect(sheet.getSelectionCoordinates(), ['B2']);
  });

  test('sheet insert and delete shifts filter metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      filterSelect: {
        'row': [1, 4],
        'column': [1, 4],
      },
      hasRawFilterSelect: true,
      filter: {
        '0': {
          'cindex': 1,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'1': 0, '2': 0, '4': 0},
        },
        '1': {
          'cindex': 2,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'2': 0},
        },
        '3': {
          'cindex': 4,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'4': 0},
        },
      },
      rawFilter: {
        '0': {
          'cindex': 1,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'1': 0, '2': 0, '4': 0},
        },
        '1': {
          'cindex': 2,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'2': 0},
        },
        '3': {
          'cindex': 4,
          'stc': 1,
          'edc': 4,
          'str': 1,
          'edr': 4,
          'rowhidden': {'4': 0},
        },
        'legacy': 'kept',
      },
      hasRawFilter: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 2, 2);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      1,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 3);

    expect(insertedRow.filterSelect, {
      'row': [1, 6],
      'column': [1, 4],
    });
    expect((insertedRow.filter['0']! as Map)['rowhidden'], {
      '1': 0,
      '2': 0,
      '6': 0,
    });
    expect((insertedRow.filter['0']! as Map)['edr'], 6);
    expect(insertedRow.rawFilter, isA<Map>());
    expect((insertedRow.rawFilter! as Map).keys, {'0', '1', '3', 'legacy'});
    expect((insertedRow.rawFilter! as Map)['legacy'], 'kept');
    expect(((insertedRow.rawFilter! as Map)['0']! as Map)['rowhidden'], {
      '1': 0,
      '2': 0,
      '6': 0,
    });
    expect(((insertedRow.rawFilter! as Map)['0']! as Map)['edr'], 6);
    expect(insertedRow.hasRawFilter, isTrue);

    expect(insertedColumn.filterSelect, {
      'row': [1, 4],
      'column': [1, 5],
    });
    expect(insertedColumn.filter.keys, {'0', '2', '4'});
    expect((insertedColumn.filter['2']! as Map)['cindex'], 3);
    expect((insertedColumn.filter['4']! as Map)['cindex'], 5);
    expect((insertedColumn.filter['2']! as Map)['edc'], 5);
    expect((insertedColumn.rawFilter! as Map).keys, {'0', '2', '4', 'legacy'});
    expect(((insertedColumn.rawFilter! as Map)['2']! as Map)['cindex'], 3);
    expect(((insertedColumn.rawFilter! as Map)['4']! as Map)['cindex'], 5);
    expect(((insertedColumn.rawFilter! as Map)['2']! as Map)['edc'], 5);

    expect(deletedRow.filterSelect, {
      'row': [1, 2],
      'column': [1, 4],
    });
    expect(deletedRow.filter.keys, {'0', '3'});
    expect((deletedRow.filter['0']! as Map)['rowhidden'], {'1': 0, '2': 0});
    expect((deletedRow.filter['0']! as Map)['edr'], 2);
    expect((deletedRow.rawFilter! as Map).keys, {'0', '3', 'legacy'});
    expect(((deletedRow.rawFilter! as Map)['0']! as Map)['rowhidden'], {
      '1': 0,
      '2': 0,
    });
    expect(((deletedRow.rawFilter! as Map)['0']! as Map)['edr'], 2);

    expect(deletedColumn.filterSelect, {
      'row': [1, 4],
      'column': [1, 2],
    });
    expect(deletedColumn.filter.keys, {'0', '1'});
    expect((deletedColumn.filter['1']! as Map)['cindex'], 2);
    expect((deletedColumn.filter['1']! as Map)['edc'], 2);
    expect((deletedColumn.rawFilter! as Map).keys, {'0', '1', 'legacy'});
    expect(((deletedColumn.rawFilter! as Map)['1']! as Map)['cindex'], 2);
    expect(((deletedColumn.rawFilter! as Map)['1']! as Map)['edc'], 2);

    ((insertedRow.filter['0']! as Map)['rowhidden'] as Map)['1'] = 'mutated';
    (((insertedRow.rawFilter! as Map)['0']! as Map)['rowhidden'] as Map)['1'] =
        'mutated';
    expect(((sheet.filter['0']! as Map)['rowhidden'] as Map)['1'], 0);
    expect(((sheet.rawFilter! as Map)['0']! as Map)['rowhidden'], {
      '1': 0,
      '2': 0,
      '4': 0,
    });
  });

  test('sheet insert and delete shifts read only metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rowReadOnly: {
        '1': {'locked': 'before'},
        '2': {'locked': 'anchor'},
        '4': {'locked': 'after'},
        'legacy': true,
      },
      hasRawRowReadOnly: true,
      colReadOnly: {
        '1': {'locked': 'before'},
        '2': {'locked': 'anchor'},
        '4': {'locked': 'after'},
        'legacy': true,
      },
      hasRawColReadOnly: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 2, 2);
    final insertedColumn = sheet.insertRowOrColumn('column', 2, 2);
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 3);

    expect(insertedRow.rowReadOnly, {
      '1': {'locked': 'before'},
      '6': {'locked': 'after'},
      'legacy': true,
    });
    expect(insertedColumn.colReadOnly, {
      '1': {'locked': 'before'},
      '6': {'locked': 'after'},
      'legacy': true,
    });
    expect(deletedRow.rowReadOnly, {
      '1': {'locked': 'before'},
      '2': {'locked': 'after'},
      'legacy': true,
    });
    expect(deletedColumn.colReadOnly, {
      '1': {'locked': 'before'},
      '2': {'locked': 'after'},
      'legacy': true,
    });

    ((insertedRow.rowReadOnly! as Map)['1'] as Map)['locked'] = 'mutated';
    expect(((sheet.rowReadOnly! as Map)['1'] as Map)['locked'], 'before');
  });

  test('sheet insert and delete shifts range border metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: const [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: Color(0xff123456),
          style: 1,
          ranges: [
            FortuneRange(rowStart: 1, rowEnd: 3, columnStart: 1, columnEnd: 2),
            FortuneRange(rowStart: 4, rowEnd: 5, columnStart: 4, columnEnd: 5),
          ],
          extraFields: {'meta': 'keep'},
        ),
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-outside',
          color: Color(0xff654321),
          style: 2,
          ranges: [
            FortuneRange(rowStart: 2, rowEnd: 3, columnStart: 6, columnEnd: 6),
          ],
        ),
      ],
    );

    final insertedRow = sheet.insertRowOrColumn(
      'row',
      2,
      2,
      direction: 'lefttop',
    );
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      1,
      direction: 'lefttop',
    );
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 4);

    expect(insertedRow.borderInfo.first.ranges[0].rowStart, 1);
    expect(insertedRow.borderInfo.first.ranges[0].rowEnd, 5);
    expect(insertedRow.borderInfo.first.ranges[1].rowStart, 6);
    expect(insertedRow.borderInfo.first.ranges[1].rowEnd, 7);
    expect(insertedColumn.borderInfo.first.ranges[0].columnStart, 1);
    expect(insertedColumn.borderInfo.first.ranges[0].columnEnd, 3);
    expect(insertedColumn.borderInfo.first.ranges[1].columnStart, 5);
    expect(insertedColumn.borderInfo.first.ranges[1].columnEnd, 6);

    expect(deletedRow.borderInfo, hasLength(1));
    expect(deletedRow.borderInfo.single.ranges[0].rowStart, 1);
    expect(deletedRow.borderInfo.single.ranges[0].rowEnd, 1);
    expect(deletedRow.borderInfo.single.ranges[1].rowStart, 2);
    expect(deletedRow.borderInfo.single.ranges[1].rowEnd, 3);
    expect(deletedColumn.borderInfo.first.ranges[0].columnStart, 1);
    expect(deletedColumn.borderInfo.first.ranges[0].columnEnd, 1);
    expect(deletedColumn.borderInfo.first.ranges[1].columnStart, 2);
    expect(deletedColumn.borderInfo.first.ranges[1].columnEnd, 2);

    insertedRow.borderInfo.first.extraFields['meta'] = 'mutated';
    expect(sheet.borderInfo.first.extraFields['meta'], 'keep');
  });

  test('sheet insert and delete preserves raw cell border metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawBorderInfo: [
        {
          'rangeType': 'range',
          'borderType': 'border-all',
          'style': 1,
          'color': '#123456',
          'range': [
            {
              'row': [1, 3],
              'column': [1, 2],
              'meta': 'keep',
            },
          ],
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 2,
            'col_index': 3,
            'l': {'style': 1, 'color': '#ff0000'},
          },
        },
        {
          'rangeType': 'cell',
          'value': {
            'row_index': 5,
            'col_index': 1,
            't': {'style': 2, 'color': '#00ff00'},
          },
        },
      ],
      hasRawBorderInfo: true,
    );

    final insertedRow = sheet.insertRowOrColumn(
      'row',
      2,
      2,
      direction: 'lefttop',
    );
    final insertedColumn = sheet.insertRowOrColumn('column', 3, 1);
    final deletedRow = sheet.deleteRowOrColumn('row', 2, 3);
    final deletedColumn = sheet.deleteRowOrColumn('column', 2, 3);

    final rowRaw = insertedRow.rawBorderInfo! as List;
    final rowRange = rowRaw.first as Map;
    final rowRangeBody = (rowRange['range'] as List).single as Map;
    final rowCells = rowRaw.skip(1).cast<Map>().toList();
    expect(rowRangeBody['row'], [1, 5]);
    expect(rowRangeBody['meta'], 'keep');
    expect(rowCells.map((item) => (item['value'] as Map)['row_index']), [
      4,
      7,
      2,
      3,
    ]);
    expect(insertedRow.hasRawBorderInfo, isTrue);

    final columnRaw = insertedColumn.rawBorderInfo! as List;
    final columnCells = columnRaw.skip(1).cast<Map>().toList();
    expect(columnCells.map((item) => (item['value'] as Map)['col_index']), [
      3,
      1,
      4,
    ]);

    final deletedRowRaw = deletedRow.rawBorderInfo! as List;
    final deletedRowCells = deletedRowRaw.skip(1).cast<Map>().toList();
    expect(deletedRowCells.map((item) => (item['value'] as Map)['row_index']), [
      3,
    ]);

    final deletedColumnRaw = deletedColumn.rawBorderInfo! as List;
    final deletedColumnCells = deletedColumnRaw.skip(1).cast<Map>().toList();
    expect(
      deletedColumnCells.map((item) => (item['value'] as Map)['col_index']),
      [1],
    );

    (((rowRaw[1] as Map)['value'] as Map)['l'] as Map)['color'] = '#000000';
    expect(
      ((((sheet.rawBorderInfo! as List)[1] as Map)['value'] as Map)['l']
          as Map)['color'],
      '#ff0000',
    );
  });

  test('sheet insert row and column expands intersecting merged cells', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: 'merged',
          merge: FortuneCellMerge(row: 1, column: 1, rowSpan: 2, columnSpan: 2),
        ),
        const FortuneCellCoord(1, 2): const FortuneCell(
          merge: FortuneCellMerge(row: 1, column: 1),
        ),
        const FortuneCellCoord(2, 1): const FortuneCell(
          merge: FortuneCellMerge(row: 1, column: 1),
        ),
        const FortuneCellCoord(2, 2): const FortuneCell(
          merge: FortuneCellMerge(row: 1, column: 1),
        ),
      },
      rawMerge: {
        '1_1': {'r': 1, 'c': 1, 'rs': 2, 'cs': 2, 'extra': 'keep'},
      },
      hasRawMerge: true,
    );

    final insertedRow = sheet.insertRowOrColumn('row', 1, 1);
    final insertedColumn = sheet.insertRowOrColumn(
      'column',
      2,
      1,
      direction: 'lefttop',
    );

    expect(insertedRow.cells[const FortuneCellCoord(1, 1)]?.merge?.rowSpan, 3);
    expect(insertedRow.cells[const FortuneCellCoord(2, 1)]?.merge?.row, 1);
    expect(insertedRow.cells[const FortuneCellCoord(2, 1)]?.merge?.column, 1);
    expect(insertedRow.cells[const FortuneCellCoord(3, 2)]?.merge?.row, 1);
    expect(insertedRow.cells[const FortuneCellCoord(3, 2)]?.merge?.column, 1);
    expect(insertedRow.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 3, 'cs': 2, 'extra': 'keep'},
    });
    expect(insertedRow.hasRawMerge, isTrue);
    expect(
      insertedColumn.cells[const FortuneCellCoord(1, 1)]?.merge?.columnSpan,
      3,
    );
    expect(insertedColumn.cells[const FortuneCellCoord(1, 3)]?.merge?.row, 1);
    expect(
      insertedColumn.cells[const FortuneCellCoord(1, 3)]?.merge?.column,
      1,
    );
    expect(insertedColumn.cells[const FortuneCellCoord(2, 3)]?.merge?.row, 1);
    expect(
      insertedColumn.cells[const FortuneCellCoord(2, 3)]?.merge?.column,
      1,
    );
    expect(insertedColumn.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 2, 'cs': 3, 'extra': 'keep'},
    });

    final insertedRowRawMerge = (insertedRow.rawMerge! as Map)['1_1'] as Map;
    insertedRowRawMerge['extra'] = 'mutated';
    expect(((sheet.rawMerge! as Map)['1_1'] as Map)['extra'], 'keep');
  });

  test('sheet delete row and column shrinks intersecting merged cells', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {
        const FortuneCellCoord(1, 1): const FortuneCell(
          value: 'merged',
          merge: FortuneCellMerge(row: 1, column: 1, rowSpan: 3, columnSpan: 3),
        ),
        for (var row = 1; row <= 3; row += 1)
          for (var column = 1; column <= 3; column += 1)
            if (row != 1 || column != 1)
              FortuneCellCoord(row, column): const FortuneCell(
                merge: FortuneCellMerge(row: 1, column: 1),
              ),
      },
      rawMerge: {
        '1_1': {'r': 1, 'c': 1, 'rs': 3, 'cs': 3, 'extra': 'keep'},
      },
      hasRawMerge: true,
    );

    final deletedMiddleRow = sheet.deleteRowOrColumn('row', 2, 2);
    final deletedAnchorRow = sheet.deleteRowOrColumn('row', 1, 1);
    final deletedMiddleColumn = sheet.deleteRowOrColumn('column', 2, 2);
    final deletedAnchorColumn = sheet.deleteRowOrColumn('column', 1, 1);

    expect(
      deletedMiddleRow.cells[const FortuneCellCoord(1, 1)]?.merge?.rowSpan,
      2,
    );
    expect(deletedMiddleRow.cells[const FortuneCellCoord(2, 3)]?.merge?.row, 1);
    expect(deletedMiddleRow.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 2, 'cs': 3, 'extra': 'keep'},
    });
    expect(deletedMiddleRow.hasRawMerge, isTrue);
    expect(
      deletedAnchorRow.cells[const FortuneCellCoord(1, 1)]?.merge?.rowSpan,
      2,
    );
    expect(deletedAnchorRow.cells[const FortuneCellCoord(1, 1)]?.merge?.row, 1);
    expect(deletedAnchorRow.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 2, 'cs': 3, 'extra': 'keep'},
    });
    expect(
      deletedMiddleColumn
          .cells[const FortuneCellCoord(1, 1)]
          ?.merge
          ?.columnSpan,
      2,
    );
    expect(
      deletedMiddleColumn.cells[const FortuneCellCoord(3, 2)]?.merge?.column,
      1,
    );
    expect(deletedMiddleColumn.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 3, 'cs': 2, 'extra': 'keep'},
    });
    expect(
      deletedAnchorColumn
          .cells[const FortuneCellCoord(1, 1)]
          ?.merge
          ?.columnSpan,
      2,
    );
    expect(
      deletedAnchorColumn.cells[const FortuneCellCoord(1, 1)]?.merge?.column,
      1,
    );
    expect(deletedAnchorColumn.rawMerge, {
      '1_1': {'r': 1, 'c': 1, 'rs': 3, 'cs': 2, 'extra': 'keep'},
    });

    final deletedMiddleRowRawMerge =
        (deletedMiddleRow.rawMerge! as Map)['1_1'] as Map;
    deletedMiddleRowRawMerge['extra'] = 'mutated';
    expect(((sheet.rawMerge! as Map)['1_1'] as Map)['extra'], 'keep');
  });

  test('sheet hides and shows rows through upstream public API shape', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenRows: {1},
      hiddenRowValues: {1: 0, 4: 'custom'},
    );

    final hidden = sheet.hideRowOrColumn([-1, 2, 4], 'row');
    final shown = hidden.showRowOrColumn([1, 2], 'row');

    expect(hidden.hiddenRows, {1, 2, 4});
    expect(hidden.hiddenRowValues, {1: 0, 4: 0, 2: 0});
    expect(shown.hiddenRows, {4});
    expect(shown.hiddenRowValues, {4: 0});
    expect(sheet.hiddenRows, {1, 4});
    expect(sheet.hiddenRowValues, {1: 0, 4: 'custom'});
  });

  test('sheet hides and shows columns through upstream public API shape', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      hiddenColumns: {1},
      hiddenColumnValues: {1: 0, 4: 'custom'},
    );

    final hidden = sheet.hideRowOrColumn([-1, 2, 4], 'column');
    final shown = hidden.showRowOrColumn([1, 2], 'column');

    expect(hidden.hiddenColumns, {1, 2, 4});
    expect(hidden.hiddenColumnValues, {1: 0, 4: 0, 2: 0});
    expect(shown.hiddenColumns, {4});
    expect(shown.hiddenColumnValues, {4: 0});
    expect(sheet.hiddenColumns, {1, 4});
    expect(sheet.hiddenColumnValues, {1: 0, 4: 'custom'});
  });

  test('workbook hides sheets and falls back to first visible sheet', () {
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(id: 's1', name: 'Sheet1'),
        FortuneSheet(id: 's2', name: 'Sheet2'),
        FortuneSheet(id: 's3', name: 'Sheet3'),
      ],
      activeSheetIndex: 1,
    );

    final hidden = workbook.hideSheet('s2');
    final shown = hidden.showSheet('s2');

    expect(hidden.sheets[1].hide, 1);
    expect(hidden.sheets[1].status, 0);
    expect(hidden.activeSheet.id, 's1');
    expect(shown.sheets[1].hide, isNull);
    expect(workbook.sheets[1].hide, isNull);
    expect(workbook.activeSheet.id, 's2');
  });

  test(
    'workbook hideSheet keeps a valid active sheet when all sheets hide',
    () {
      final workbook = FortuneWorkbook(
        sheets: [FortuneSheet(id: 's1', name: 'Sheet1')],
      );

      final hidden = workbook.hideSheet('s1');

      expect(hidden.sheets.single.hide, 1);
      expect(hidden.activeSheetIndex, 0);
      expect(hidden.activeSheet.id, 's1');
    },
  );

  test('workbook copyWith snapshots raw data and sheets', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final replacementItem = {'value': 'replacement'};
    final workbook = FortuneWorkbook(
      sheets: [
        FortuneSheet(
          id: 's1',
          name: 'Sheet1',
          rawColor: raw('sheet'),
          hasRawColor: true,
        ),
      ],
      rawData: raw('workbook'),
      hasRawData: true,
    );

    final copy = workbook.copyWith(activeSheetIndex: 0);
    final replacement = workbook.copyWith(
      rawData: {
        'items': [replacementItem],
      },
    );

    mutateValue(copy.rawData, 'mutated copy');
    mutateValue(copy.sheets.single.rawColor, 'mutated sheet copy');
    replacementItem['value'] = 'mutated replacement source';

    expect(valueOf(workbook.rawData), 'workbook');
    expect(valueOf(workbook.sheets.single.rawColor), 'sheet');
    expect(valueOf(replacement.rawData), 'replacement');
  });

  test('workbook constructor snapshots sheets', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final sourceSheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawColor: raw('sheet'),
      hasRawColor: true,
    );
    final workbook = FortuneWorkbook(sheets: [sourceSheet]);

    mutateValue(sourceSheet.rawColor, 'mutated source');

    expect(valueOf(workbook.sheets.single.rawColor), 'sheet');
  });

  test('sheet constructor snapshots nested model collections', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final border = FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: const Color(0xff000000),
      rawColor: raw('border'),
      hasRawColor: true,
      style: 1,
      ranges: [
        FortuneRange(
          rowStart: 0,
          rowEnd: 1,
          rawRow: raw('range'),
          hasRawRow: true,
          columnStart: 0,
          columnEnd: 1,
        ),
      ],
    );
    final image = FortuneImage(
      id: 'image1',
      src: 'data:image/png;base64,AA==',
      left: 1,
      rawLeft: raw('image'),
      hasRawLeft: true,
      top: 2,
      width: 3,
      height: 4,
    );

    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      borderInfo: [border],
      images: [image],
    );

    mutateValue(border.rawColor, 'mutated source');
    mutateValue(border.ranges.single.rawRow, 'mutated source');
    mutateValue(image.rawLeft, 'mutated source');

    expect(valueOf(sheet.borderInfo.single.rawColor), 'border');
    expect(valueOf(sheet.borderInfo.single.ranges.single.rawRow), 'range');
    expect(valueOf(sheet.images.single.rawLeft), 'image');
  });

  test('sheet constructor snapshots cell map models', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final cell = FortuneCell(
      value: 'A1',
      rawValue: raw('cell'),
      hasRawValue: true,
    );
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): cell},
    );

    mutateValue(cell.rawValue, 'mutated source');

    expect(
      valueOf(sheet.cells[const FortuneCellCoord(0, 0)]!.rawValue),
      'cell',
    );
  });

  test('sheet copyWith preserves data and updates tab metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
      color: '#0188fb',
      selectionSave: [
        {
          'row': [0, 0],
          'column': [0, 0],
        },
      ],
      rowReadOnly: {'1': 1},
    );

    final copy = sheet.copyWith(id: 's2', name: 'Sheet1(copy)', hide: 1);
    ((copy.selectionSave! as List).single as Map)['row'] = [1, 1];
    (copy.rowReadOnly! as Map)['2'] = 1;

    expect(copy.id, 's2');
    expect(copy.name, 'Sheet1(copy)');
    expect(copy.hide, 1);
    expect(copy.color, '#0188fb');
    expect(copy.cells[const FortuneCellCoord(0, 0)]?.value, 'A1');
    expect(identical(copy.cells, sheet.cells), isFalse);
    expect(((sheet.selectionSave! as List).single as Map)['row'], [0, 0]);
    expect((sheet.rowReadOnly! as Map).containsKey('2'), isFalse);
  });

  test('sheet copyWith snapshots extra metadata', () {
    final sourceSheetItem = {'value': 'A'};
    final sourceConfigItem = {'value': 'B'};
    final sourceExtra = {
      'customSheetMeta': {
        'items': [sourceSheetItem],
      },
    };
    final sourceConfigExtra = {
      'customConfigMeta': {
        'items': [sourceConfigItem],
      },
    };
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      extraFields: sourceExtra,
      configExtraFields: sourceConfigExtra,
    );
    final copy = sheet.copyWith(name: 'Copy');
    final sheetItem =
        ((sheet.extraFields['customSheetMeta']! as Map)['items']! as List)
                .single
            as Map;
    final sheetConfigItem =
        ((sheet.configExtraFields['customConfigMeta']! as Map)['items']!
                    as List)
                .single
            as Map;
    final copyItem =
        ((copy.extraFields['customSheetMeta']! as Map)['items']! as List).single
            as Map;
    final copyConfigItem =
        ((copy.configExtraFields['customConfigMeta']! as Map)['items']! as List)
                .single
            as Map;

    sourceSheetItem['value'] = 'mutated source';
    sourceConfigItem['value'] = 'mutated source';
    copyItem['value'] = 'mutated copy';
    copyConfigItem['value'] = 'mutated copy';

    expect(sheetItem['value'], 'A');
    expect(sheetConfigItem['value'], 'B');
    expect(copyItem['value'], 'mutated copy');
    expect(copyConfigItem['value'], 'mutated copy');
  });

  test('sheet copyWith snapshots nested structured metadata maps', () {
    Map<String, Object?> metadata(String key, Map<String, String> item) => {
      key: {
        'items': [item],
      },
    };

    Map itemOf(Map<String, Object?> fields, String key) {
      return ((fields[key]! as Map)['items']! as List).single as Map;
    }

    String valueOf(Map<String, Object?> fields, String key) {
      return itemOf(fields, key)['value']! as String;
    }

    final replacementItem = {'value': 'replacement'};
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      dataVerification: metadata('verificationMeta', {'value': 'verify'}),
      filter: metadata('filterMeta', {'value': 'filter'}),
      hyperlinks: metadata('hyperlinkMeta', {'value': 'hyperlink'}),
    );

    final copy = sheet.copyWith(name: 'Copy');
    final replacement = sheet.copyWith(
      dataVerification: metadata('verificationMeta', replacementItem),
    );

    itemOf(copy.dataVerification, 'verificationMeta')['value'] = 'mutated copy';
    itemOf(copy.filter, 'filterMeta')['value'] = 'mutated copy';
    itemOf(copy.hyperlinks, 'hyperlinkMeta')['value'] = 'mutated copy';
    replacementItem['value'] = 'mutated replacement source';

    expect(valueOf(sheet.dataVerification, 'verificationMeta'), 'verify');
    expect(valueOf(sheet.filter, 'filterMeta'), 'filter');
    expect(valueOf(sheet.hyperlinks, 'hyperlinkMeta'), 'hyperlink');
    expect(
      valueOf(replacement.dataVerification, 'verificationMeta'),
      'replacement',
    );
  });

  test('sheet copyWith snapshots nested raw model metadata', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final replacementItem = {'value': 'replacement'};
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      rawData: raw('data'),
      hasRawData: true,
      rawColor: raw('color'),
      hasRawColor: true,
      frozen: FortuneFrozenPane(
        type: 'row',
        rowFocus: 1,
        rawRowFocus: raw('frozen'),
        hasRawRowFocus: true,
      ),
      borderInfo: [
        FortuneBorderInfo(
          rangeType: 'range',
          borderType: 'border-all',
          color: const Color(0xff000000),
          rawColor: raw('border'),
          hasRawColor: true,
          style: 1,
          ranges: [
            FortuneRange(
              rowStart: 0,
              rowEnd: 1,
              rawRow: raw('range'),
              hasRawRow: true,
              columnStart: 0,
              columnEnd: 1,
            ),
          ],
        ),
      ],
      images: [
        FortuneImage(
          id: 'image1',
          src: 'data:image/png;base64,AA==',
          left: 1,
          rawLeft: raw('image'),
          hasRawLeft: true,
          top: 2,
          width: 3,
          height: 4,
        ),
      ],
    );

    final copy = sheet.copyWith(name: 'Copy');
    final replacement = sheet.copyWith(
      rawData: {
        'items': [replacementItem],
      },
    );

    mutateValue(copy.rawData, 'mutated copy');
    mutateValue(copy.rawColor, 'mutated copy');
    mutateValue(copy.frozen!.rawRowFocus, 'mutated copy');
    mutateValue(copy.borderInfo.single.rawColor, 'mutated copy');
    mutateValue(copy.borderInfo.single.ranges.single.rawRow, 'mutated copy');
    mutateValue(copy.images.single.rawLeft, 'mutated copy');
    replacementItem['value'] = 'mutated replacement source';

    expect(valueOf(sheet.rawData), 'data');
    expect(valueOf(sheet.rawColor), 'color');
    expect(valueOf(sheet.frozen!.rawRowFocus), 'frozen');
    expect(valueOf(sheet.borderInfo.single.rawColor), 'border');
    expect(valueOf(sheet.borderInfo.single.ranges.single.rawRow), 'range');
    expect(valueOf(sheet.images.single.rawLeft), 'image');
    expect(valueOf(replacement.rawData), 'replacement');
  });

  test('comment and hyperlink copyWith snapshot extra metadata', () {
    final replacementCommentItem = {'value': 'replacement comment'};
    final replacementHyperlinkItem = {'value': 'replacement hyperlink'};
    final comment = FortuneCellComment(
      value: 'note',
      extraFields: const {
        'customCommentMeta': {
          'items': [
            {'value': 'comment'},
          ],
        },
      },
    );
    final hyperlink = FortuneHyperlink(
      linkAddress: 'https://example.test',
      extraFields: const {
        'customLinkMeta': {
          'items': [
            {'value': 'hyperlink'},
          ],
        },
      },
    );

    final commentCopy = comment.copyWith(value: 'copy');
    final hyperlinkCopy = hyperlink.copyWith(id: 'copy');
    final replacementComment = comment.copyWith(
      extraFields: {
        'customCommentMeta': {
          'items': [replacementCommentItem],
        },
      },
    );
    final replacementHyperlink = hyperlink.copyWith(
      extraFields: {
        'customLinkMeta': {
          'items': [replacementHyperlinkItem],
        },
      },
    );
    final commentItem =
        ((comment.extraFields['customCommentMeta']! as Map)['items']! as List)
                .single
            as Map;
    final hyperlinkItem =
        ((hyperlink.extraFields['customLinkMeta']! as Map)['items']! as List)
                .single
            as Map;
    final commentCopyItem =
        ((commentCopy.extraFields['customCommentMeta']! as Map)['items']!
                    as List)
                .single
            as Map;
    final hyperlinkCopyItem =
        ((hyperlinkCopy.extraFields['customLinkMeta']! as Map)['items']!
                    as List)
                .single
            as Map;
    final replacementCommentCopyItem =
        ((replacementComment.extraFields['customCommentMeta']! as Map)['items']!
                    as List)
                .single
            as Map;
    final replacementHyperlinkCopyItem =
        ((replacementHyperlink.extraFields['customLinkMeta']! as Map)['items']!
                    as List)
                .single
            as Map;

    commentCopyItem['value'] = 'mutated copy';
    hyperlinkCopyItem['value'] = 'mutated copy';
    replacementCommentItem['value'] = 'mutated replacement source';
    replacementHyperlinkItem['value'] = 'mutated replacement source';

    expect(commentItem['value'], 'comment');
    expect(hyperlinkItem['value'], 'hyperlink');
    expect(commentCopyItem['value'], 'mutated copy');
    expect(hyperlinkCopyItem['value'], 'mutated copy');
    expect(replacementCommentCopyItem['value'], 'replacement comment');
    expect(replacementHyperlinkCopyItem['value'], 'replacement hyperlink');
  });

  test('model copyWith snapshots nested extra metadata fields', () {
    Map<String, Object?> metadata(String key, Map<String, String> item) => {
      key: {
        'items': [item],
      },
    };

    Map itemOf(Map<String, Object?> extraFields, String key) {
      return ((extraFields[key]! as Map)['items']! as List).single as Map;
    }

    String valueOf(Map<String, Object?> extraFields, String key) =>
        itemOf(extraFields, key)['value']! as String;

    void mutateCopy(Map<String, Object?> extraFields, String key) {
      itemOf(extraFields, key)['value'] = 'mutated copy';
    }

    final replacementItem = {'value': 'replacement'};
    final cell = FortuneCell(
      value: 'A',
      extraFields: metadata('cellMeta', {'value': 'cell'}),
    );
    final inlineRun = FortuneInlineTextRun(
      text: 'A',
      extraFields: metadata('runMeta', {'value': 'run'}),
    );
    final image = FortuneImage(
      id: 'image1',
      src: 'data:image/png;base64,AA==',
      left: 1,
      top: 2,
      width: 3,
      height: 4,
      extraFields: metadata('imageMeta', {'value': 'image'}),
    );
    final frozen = FortuneFrozenPane(
      type: 'row',
      extraFields: metadata('frozenMeta', {'value': 'frozen'}),
      rangeExtraFields: metadata('rangeMeta', {'value': 'frozen range'}),
    );
    final merge = FortuneCellMerge(
      row: 0,
      column: 0,
      extraFields: metadata('mergeMeta', {'value': 'merge'}),
    );
    final cellType = FortuneCellType(
      format: 'General',
      extraFields: metadata('typeMeta', {'value': 'type'}),
    );
    final borderInfo = FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: const Color(0xff000000),
      style: 1,
      ranges: const [
        FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
      ],
      extraFields: metadata('borderMeta', {'value': 'border'}),
    );
    final range = FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 0,
      extraFields: metadata('rangeMeta', {'value': 'range'}),
    );

    final cellCopy = cell.copyWith(value: 'B');
    final inlineRunCopy = inlineRun.copyWith(text: 'B');
    final imageCopy = image.copyWith(left: 9);
    final frozenCopy = frozen.copyWith(type: 'column');
    final mergeCopy = merge.copyWith(rowSpan: 2);
    final cellTypeCopy = cellType.copyWith(type: 'n');
    final borderInfoCopy = borderInfo.copyWith(style: 2);
    final rangeCopy = range.copyWith(rowEnd: 1);
    final replacementCell = cell.copyWith(
      extraFields: metadata('cellMeta', replacementItem),
    );

    mutateCopy(cellCopy.extraFields, 'cellMeta');
    mutateCopy(inlineRunCopy.extraFields, 'runMeta');
    mutateCopy(imageCopy.extraFields, 'imageMeta');
    mutateCopy(frozenCopy.extraFields, 'frozenMeta');
    mutateCopy(frozenCopy.rangeExtraFields, 'rangeMeta');
    mutateCopy(mergeCopy.extraFields, 'mergeMeta');
    mutateCopy(cellTypeCopy.extraFields, 'typeMeta');
    mutateCopy(borderInfoCopy.extraFields, 'borderMeta');
    mutateCopy(rangeCopy.extraFields, 'rangeMeta');
    replacementItem['value'] = 'mutated replacement source';

    expect(valueOf(cell.extraFields, 'cellMeta'), 'cell');
    expect(valueOf(inlineRun.extraFields, 'runMeta'), 'run');
    expect(valueOf(image.extraFields, 'imageMeta'), 'image');
    expect(valueOf(frozen.extraFields, 'frozenMeta'), 'frozen');
    expect(valueOf(frozen.rangeExtraFields, 'rangeMeta'), 'frozen range');
    expect(valueOf(merge.extraFields, 'mergeMeta'), 'merge');
    expect(valueOf(cellType.extraFields, 'typeMeta'), 'type');
    expect(valueOf(borderInfo.extraFields, 'borderMeta'), 'border');
    expect(valueOf(range.extraFields, 'rangeMeta'), 'range');
    expect(valueOf(replacementCell.extraFields, 'cellMeta'), 'replacement');
  });

  test('cell copyWith snapshots nested sparkline metadata', () {
    final replacementMarker = {'color': 'green'};
    final cell = FortuneCell(
      value: 'A',
      sparkline: {
        'type': 'line',
        'markers': [
          {'color': 'red'},
        ],
      },
      hasSparkline: true,
    );

    final copy = cell.copyWith(value: 'B');
    final replacement = cell.copyWith(
      sparkline: {
        'type': 'line',
        'markers': [replacementMarker],
      },
    );

    final copyMarkers = (copy.sparkline! as Map)['markers']! as List;
    (copyMarkers.single as Map)['color'] = 'blue';
    replacementMarker['color'] = 'mutated replacement source';

    final originalMarkers = (cell.sparkline! as Map)['markers']! as List;
    final replacementMarkers =
        (replacement.sparkline! as Map)['markers']! as List;
    expect((originalMarkers.single as Map)['color'], 'red');
    expect((replacementMarkers.single as Map)['color'], 'green');
  });

  test('cell copyWith snapshots nested raw value metadata', () {
    final replacementItem = {'value': 'replacement'};
    final cell = FortuneCell(
      value: 'A',
      rawValue: {
        'items': [
          {'value': 'raw'},
        ],
      },
      hasRawValue: true,
    );

    final copy = cell.copyWith(bold: true);
    final replacement = cell.copyWith(
      rawValue: {
        'items': [replacementItem],
      },
    );

    final copyItems = (copy.rawValue! as Map)['items']! as List;
    (copyItems.single as Map)['value'] = 'mutated copy';
    replacementItem['value'] = 'mutated replacement source';

    final originalItems = (cell.rawValue! as Map)['items']! as List;
    final replacementItems = (replacement.rawValue! as Map)['items']! as List;
    expect((originalItems.single as Map)['value'], 'raw');
    expect((replacementItems.single as Map)['value'], 'replacement');
  });

  test('cell copyWith snapshots nested model metadata', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final replacementCommentItem = {'value': 'replacement'};
    final cell = FortuneCell(
      value: 'A',
      merge: FortuneCellMerge(
        row: 0,
        rawRow: raw('merge'),
        hasRawRow: true,
        column: 0,
      ),
      cellType: FortuneCellType(
        format: 'General',
        rawFormat: raw('type'),
        hasRawFormat: true,
      ),
      comment: FortuneCellComment(
        value: 'note',
        rawValue: raw('comment'),
        hasRawValue: true,
      ),
      hyperlink: FortuneHyperlink(
        linkAddress: 'https://example.test',
        rawLinkAddress: raw('link'),
        hasRawLinkAddress: true,
      ),
      inlineRuns: [
        FortuneInlineTextRun(text: 'A', rawText: raw('run'), hasRawText: true),
      ],
    );

    final copy = cell.copyWith(value: 'B');
    final replacement = cell.copyWith(
      comment: FortuneCellComment(
        value: 'replacement',
        rawValue: {
          'items': [replacementCommentItem],
        },
        hasRawValue: true,
      ),
    );

    mutateValue(copy.merge!.rawRow, 'mutated copy');
    mutateValue(copy.cellType!.rawFormat, 'mutated copy');
    mutateValue(copy.comment!.rawValue, 'mutated copy');
    mutateValue(copy.hyperlink!.rawLinkAddress, 'mutated copy');
    mutateValue(copy.inlineRuns!.single.rawText, 'mutated copy');
    replacementCommentItem['value'] = 'mutated replacement source';

    expect(valueOf(cell.merge!.rawRow), 'merge');
    expect(valueOf(cell.cellType!.rawFormat), 'type');
    expect(valueOf(cell.comment!.rawValue), 'comment');
    expect(valueOf(cell.hyperlink!.rawLinkAddress), 'link');
    expect(valueOf(cell.inlineRuns!.single.rawText), 'run');
    expect(valueOf(replacement.comment!.rawValue), 'replacement');
  });

  test('cell withEditedValue snapshots retained metadata', () {
    final cell = FortuneCell(
      value: 'A',
      sparkline: {
        'markers': [
          {'color': 'red'},
        ],
      },
      hasSparkline: true,
      extraFields: {
        'cellMeta': {
          'items': [
            {'value': 'original'},
          ],
        },
      },
    );

    final edited = cell.withEditedValue('B');
    final editedMarkers = (edited.sparkline! as Map)['markers']! as List;
    (editedMarkers.single as Map)['color'] = 'blue';
    final editedMeta = edited.extraFields['cellMeta']! as Map;
    ((editedMeta['items']! as List).single as Map)['value'] = 'mutated edited';

    final originalMarkers = (cell.sparkline! as Map)['markers']! as List;
    final originalMeta = cell.extraFields['cellMeta']! as Map;
    expect((originalMarkers.single as Map)['color'], 'red');
    expect(
      ((originalMeta['items']! as List).single as Map)['value'],
      'original',
    );
  });

  test('inline text run copyWith snapshots nested raw metadata', () {
    final replacementItem = {'value': 'replacement'};
    final run = FortuneInlineTextRun(
      text: 'A',
      rawText: {
        'items': [
          {'value': 'raw'},
        ],
      },
      hasRawText: true,
    );

    final copy = run.copyWith(foreground: const Color(0xff188038));
    final replacement = run.copyWith(
      rawText: {
        'items': [replacementItem],
      },
    );

    final copyItems = (copy.rawText! as Map)['items']! as List;
    (copyItems.single as Map)['value'] = 'mutated copy';
    replacementItem['value'] = 'mutated replacement source';

    final originalItems = (run.rawText! as Map)['items']! as List;
    final replacementItems = (replacement.rawText! as Map)['items']! as List;
    expect((originalItems.single as Map)['value'], 'raw');
    expect((replacementItems.single as Map)['value'], 'replacement');
  });

  test('structured model copyWith snapshots nested raw metadata', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    final image = FortuneImage(
      id: 'image1',
      src: 'data:image/png;base64,AA==',
      left: 1,
      rawLeft: raw('image'),
      hasRawLeft: true,
      top: 2,
      width: 3,
      height: 4,
    );
    final frozen = FortuneFrozenPane(
      type: 'row',
      rowFocus: 1,
      rawRowFocus: raw('frozen'),
      hasRawRowFocus: true,
    );
    final merge = FortuneCellMerge(
      row: 0,
      rawRow: raw('merge'),
      hasRawRow: true,
      column: 0,
    );
    final cellType = FortuneCellType(
      format: 'General',
      rawFormat: raw('type'),
      hasRawFormat: true,
      style: raw('style'),
      rawStyle: raw('raw style'),
      hasRawStyle: true,
    );

    final imageCopy = image.copyWith(top: 9);
    final frozenCopy = frozen.copyWith(type: 'column');
    final mergeCopy = merge.copyWith(columnSpan: 2);
    final cellTypeCopy = cellType.copyWith(type: 'n');

    (((imageCopy.rawLeft! as Map)['items']! as List).single as Map)['value'] =
        'mutated copy';
    (((frozenCopy.rawRowFocus! as Map)['items']! as List).single
            as Map)['value'] =
        'mutated copy';
    (((mergeCopy.rawRow! as Map)['items']! as List).single as Map)['value'] =
        'mutated copy';
    (((cellTypeCopy.rawFormat! as Map)['items']! as List).single
            as Map)['value'] =
        'mutated copy';
    (((cellTypeCopy.style! as Map)['items']! as List).single as Map)['value'] =
        'mutated copy';
    (((cellTypeCopy.rawStyle! as Map)['items']! as List).single
            as Map)['value'] =
        'mutated copy';

    expect(valueOf(image.rawLeft), 'image');
    expect(valueOf(frozen.rawRowFocus), 'frozen');
    expect(valueOf(merge.rawRow), 'merge');
    expect(valueOf(cellType.rawFormat), 'type');
    expect(valueOf(cellType.style), 'style');
    expect(valueOf(cellType.rawStyle), 'raw style');
  });

  test('annotation and border copyWith snapshots nested raw metadata', () {
    Map<String, Object?> raw(String value) => {
      'items': [
        {'value': value},
      ],
    };

    String valueOf(Object? rawValue) {
      return (((rawValue! as Map)['items']! as List).single as Map)['value']!
          as String;
    }

    void mutateValue(Object? rawValue, String value) {
      (((rawValue! as Map)['items']! as List).single as Map)['value'] = value;
    }

    final comment = FortuneCellComment(
      value: 'note',
      rawValue: raw('comment'),
      hasRawValue: true,
    );
    final hyperlink = FortuneHyperlink(
      row: 0,
      column: 0,
      linkAddress: 'https://example.test',
      rawLinkAddress: raw('link'),
      hasRawLinkAddress: true,
    );
    final range = FortuneRange(
      rowStart: 0,
      rowEnd: 1,
      rawRow: raw('range row'),
      hasRawRow: true,
      columnStart: 0,
      columnEnd: 1,
      extraFields: raw('range extra'),
    );
    final borderInfo = FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: const Color(0xff000000),
      rawColor: raw('border color'),
      hasRawColor: true,
      style: 1,
      ranges: [range],
    );

    final commentCopy = comment.copyWith(left: 1);
    final hyperlinkCopy = hyperlink.copyWith(id: 'link1');
    final rangeCopy = range.copyWith(rowFocus: 0);
    final borderInfoCopy = borderInfo.copyWith(style: 2);

    mutateValue(commentCopy.rawValue, 'mutated copy');
    mutateValue(hyperlinkCopy.rawLinkAddress, 'mutated copy');
    mutateValue(rangeCopy.rawRow, 'mutated copy');
    mutateValue(rangeCopy.extraFields, 'mutated copy');
    mutateValue(borderInfoCopy.rawColor, 'mutated copy');
    final copiedBorderRange = borderInfoCopy.ranges.single;
    mutateValue(copiedBorderRange.rawRow, 'mutated border range');
    mutateValue(copiedBorderRange.extraFields, 'mutated border range');

    expect(valueOf(comment.rawValue), 'comment');
    expect(valueOf(hyperlink.rawLinkAddress), 'link');
    expect(valueOf(range.rawRow), 'range row');
    expect(valueOf(range.extraFields), 'range extra');
    expect(valueOf(borderInfo.rawColor), 'border color');
    expect(valueOf(borderInfo.ranges.single.rawRow), 'range row');
    expect(valueOf(borderInfo.ranges.single.extraFields), 'range extra');
  });

  test('sheet copyWith can clear nullable tab metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      color: '#0188fb',
      hide: 1,
      frozen: const FortuneFrozenPane(type: 'row'),
      status: 1,
    );

    final visible = sheet.copyWith(
      color: null,
      hide: null,
      frozen: null,
      status: null,
    );

    expect(visible.color, isNull);
    expect(visible.hide, isNull);
    expect(visible.frozen, isNull);
    expect(visible.status, isNull);
  });

  test('sheet copyWith can clear raw object metadata', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      selectionSave: [
        {
          'row': [0, 0],
          'column': [0, 0],
        },
      ],
      hasRawSelectionSave: true,
      rowReadOnly: {'1': 1},
      hasRawRowReadOnly: true,
    );

    final cleared = sheet.copyWith(selectionSave: null, rowReadOnly: null);

    expect(cleared.selectionSave, isNull);
    expect(cleared.hasRawSelectionSave, isTrue);
    expect(cleared.rowReadOnly, isNull);
    expect(cleared.hasRawRowReadOnly, isTrue);
  });

  test('sheet copyWith clears raw data metadata when editing cells', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
      rawData: [
        [
          {'v': 'A1'},
        ],
      ],
      hasRawData: true,
      rawCelldata: [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'A1'},
        },
      ],
      hasRawCelldata: true,
    );

    final renamed = sheet.copyWith(name: 'Renamed');
    final edited = sheet.copyWith(
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'B1')},
    );

    expect(renamed.rawData, sheet.rawData);
    expect(renamed.rawCelldata, sheet.rawCelldata);
    expect(identical(renamed.rawData, sheet.rawData), isFalse);
    expect(identical(renamed.rawCelldata, sheet.rawCelldata), isFalse);
    expect(renamed.hasRawData, isTrue);
    expect(renamed.hasRawCelldata, isTrue);

    expect(edited.cells[const FortuneCellCoord(0, 0)]?.value, 'B1');
    expect(edited.rawData, isNull);
    expect(edited.rawCelldata, isNull);
    expect(edited.hasRawData, isFalse);
    expect(edited.hasRawCelldata, isFalse);
  });

  test('sheet copyWith clears raw data metadata when editing null cells', () {
    final sheet = FortuneSheet(
      id: 's1',
      name: 'Sheet1',
      cells: {const FortuneCellCoord(0, 0): const FortuneCell(value: 'A1')},
      rawData: [
        [
          {'v': 'A1'},
        ],
      ],
      hasRawData: true,
      rawCelldata: [
        {
          'r': 0,
          'c': 0,
          'v': {'v': 'A1'},
        },
      ],
      hasRawCelldata: true,
    );

    final edited = sheet.copyWith(nullCells: {const FortuneCellCoord(1, 1)});

    expect(edited.cells[const FortuneCellCoord(0, 0)]?.value, 'A1');
    expect(edited.nullCells, {const FortuneCellCoord(1, 1)});
    expect(edited.rawData, isNull);
    expect(edited.rawCelldata, isNull);
    expect(edited.hasRawData, isFalse);
    expect(edited.hasRawCelldata, isFalse);
  });
}
