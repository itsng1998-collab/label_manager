import 'dart:math' as math;
import 'dart:ui';

import 'fortune_sheet_model.dart';

class FortuneSheetCodec {
  const FortuneSheetCodec._();

  static FortuneWorkbook workbookFromJson(
    Map<String, Object?> json, {
    FortuneSettings settings = const FortuneSettings(),
  }) {
    final rawSheets = json['data'];
    final sheets = rawSheets is List
        ? [
            for (var index = 0; index < rawSheets.length; index += 1)
              if (rawSheets[index] is Map)
                sheetFromJson(
                  Map<String, Object?>.from(rawSheets[index] as Map),
                  fallbackIndex: index,
                ),
          ]
        : <FortuneSheet>[];
    final activeIndex = _activeSheetIndex(sheets);
    return FortuneWorkbook(
      sheets: sheets.isEmpty
          ? [FortuneSheet(id: 'sheet_01', name: 'Sheet1')]
          : sheets,
      activeSheetIndex: activeIndex,
      settings: _settingsFromJson(json, settings),
      rawData: cloneFortuneMetadata(json['data']),
      hasRawData: json.containsKey('data'),
      extraFields: _unhandledWorkbookFields(json),
    );
  }

  static int _activeSheetIndex(List<FortuneSheet> sheets) {
    final statusIndex = sheets.indexWhere(
      (sheet) => sheet.status == 1 && sheet.hide != 1,
    );
    if (statusIndex >= 0) {
      return statusIndex;
    }
    var activeIndex = -1;
    int? activeOrder;
    for (var index = 0; index < sheets.length; index += 1) {
      final sheet = sheets[index];
      if (sheet.hide == 1) {
        continue;
      }
      final order = sheet.order;
      if (activeIndex < 0 ||
          (order != null && (activeOrder == null || order < activeOrder))) {
        activeIndex = index;
        activeOrder = order;
      }
    }
    return activeIndex < 0 ? 0 : activeIndex;
  }

  static FortuneSettings _settingsFromJson(
    Map<String, Object?> json,
    FortuneSettings fallback,
  ) {
    return FortuneSettings(
      column: _int(json['column']) ?? fallback.column,
      row: _int(json['row']) ?? fallback.row,
      addRows: _int(json['addRows']) ?? fallback.addRows,
      showToolbar: _bool(json['showToolbar']) ?? fallback.showToolbar,
      showFormulaBar: _bool(json['showFormulaBar']) ?? fallback.showFormulaBar,
      showSheetTabs: _bool(json['showSheetTabs']) ?? fallback.showSheetTabs,
      config: json.containsKey('config')
          ? cloneFortuneMetadata(json['config'])
          : fallback.config,
      devicePixelRatio:
          _double(json['devicePixelRatio']) ?? fallback.devicePixelRatio,
      allowEdit: _bool(json['allowEdit']) ?? fallback.allowEdit,
      lang: json.containsKey('lang') ? _string(json['lang']) : fallback.lang,
      currency: _string(json['currency']) ?? fallback.currency,
      forceCalculation:
          _bool(json['forceCalculation']) ?? fallback.forceCalculation,
      toolbarHeight: fallback.toolbarHeight,
      formulaBarHeight: fallback.formulaBarHeight,
      rowHeaderWidth:
          _double(json['rowHeaderWidth']) ?? fallback.rowHeaderWidth,
      columnHeaderHeight:
          _double(json['columnHeaderHeight']) ?? fallback.columnHeaderHeight,
      sheetBarHeight: fallback.sheetBarHeight,
      statisticBarHeight: fallback.statisticBarHeight,
      defaultColWidth:
          _double(json['defaultColWidth']) ?? fallback.defaultColWidth,
      defaultRowHeight:
          _double(json['defaultRowHeight']) ?? fallback.defaultRowHeight,
      defaultFontSize:
          _double(json['defaultFontSize']) ?? fallback.defaultFontSize,
      fontFamilies: _stringList(json['fontFamilies']) ?? fallback.fontFamilies,
      fontProvider: fallback.fontProvider,
      toolbarItems: _stringList(json['toolbarItems']) ?? fallback.toolbarItems,
      customToolbarItems:
          _customToolbarItems(json['customToolbarItems']) ??
          fallback.customToolbarItems,
      cellContextMenu:
          _stringList(json['cellContextMenu']) ?? fallback.cellContextMenu,
      headerContextMenu:
          _stringList(json['headerContextMenu']) ?? fallback.headerContextMenu,
      sheetTabContextMenu:
          _stringList(json['sheetTabContextMenu']) ??
          fallback.sheetTabContextMenu,
      filterContextMenu:
          _stringList(json['filterContextMenu']) ?? fallback.filterContextMenu,
      generateSheetId: fallback.generateSheetId,
      beforeUpdateCell: fallback.beforeUpdateCell,
      afterUpdateCell: fallback.afterUpdateCell,
      afterSelectionChange: fallback.afterSelectionChange,
      beforeCellMouseDown: fallback.beforeCellMouseDown,
      afterCellMouseDown: fallback.afterCellMouseDown,
      beforePaste: fallback.beforePaste,
      beforeRenderCellArea: fallback.beforeRenderCellArea,
      beforeRenderRowHeaderCell: fallback.beforeRenderRowHeaderCell,
      afterRenderRowHeaderCell: fallback.afterRenderRowHeaderCell,
      beforeRenderColumnHeaderCell: fallback.beforeRenderColumnHeaderCell,
      afterRenderColumnHeaderCell: fallback.afterRenderColumnHeaderCell,
      beforeRenderCell: fallback.beforeRenderCell,
      afterRenderCell: fallback.afterRenderCell,
      beforeUpdateComment: fallback.beforeUpdateComment,
      afterUpdateComment: fallback.afterUpdateComment,
      beforeInsertComment: fallback.beforeInsertComment,
      afterInsertComment: fallback.afterInsertComment,
      beforeDeleteComment: fallback.beforeDeleteComment,
      afterDeleteComment: fallback.afterDeleteComment,
      beforeAddSheet: fallback.beforeAddSheet,
      afterAddSheet: fallback.afterAddSheet,
      beforeActivateSheet: fallback.beforeActivateSheet,
      afterActivateSheet: fallback.afterActivateSheet,
      beforeDeleteSheet: fallback.beforeDeleteSheet,
      afterDeleteSheet: fallback.afterDeleteSheet,
      beforeUpdateSheetName: fallback.beforeUpdateSheetName,
      afterUpdateSheetName: fallback.afterUpdateSheetName,
    );
  }

  static Map<String, Object?> workbookToJson(FortuneWorkbook workbook) {
    return {
      for (final entry in workbook.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      ..._workbookSettingsToJson(workbook),
      'data': _workbookDataToJson(workbook),
    };
  }

  static List<Map<String, Object?>> dataToCelldata(Object? data) {
    final celldata = <Map<String, Object?>>[];
    if (data is! List) {
      return celldata;
    }
    for (var row = 0; row < data.length; row += 1) {
      final rowData = data[row];
      if (rowData is! List) {
        continue;
      }
      for (var column = 0; column < rowData.length; column += 1) {
        final value = rowData[column];
        if (value != null) {
          celldata.add({
            'r': row,
            'c': column,
            'v': cloneFortuneMetadata(value),
          });
        }
      }
    }
    return celldata;
  }

  static List<List<Object?>>? celldataToData(
    Object? celldata, {
    int? rowCount,
    int? columnCount,
  }) {
    if (celldata is! List) {
      return null;
    }
    var lastRow = 0;
    var lastColumn = 0;
    final entries = <({int row, int column, Object? value})>[];
    for (final item in celldata.whereType<Map>()) {
      final row = _int(item['r']);
      final column = _int(item['c']);
      if (row == null || column == null || row < 0 || column < 0) {
        continue;
      }
      entries.add((row: row, column: column, value: item['v']));
      lastRow = math.max(lastRow, row);
      lastColumn = math.max(lastColumn, column);
    }
    var rowLength = lastRow + 1;
    var columnLength = lastColumn + 1;
    if (rowCount != null &&
        columnCount != null &&
        rowCount > 0 &&
        columnCount > 0) {
      rowLength = math.max(rowLength, rowCount);
      columnLength = math.max(columnLength, columnCount);
    }
    final data = [
      for (var row = 0; row < rowLength; row += 1)
        List<Object?>.filled(columnLength, null),
    ];
    for (final entry in entries) {
      data[entry.row][entry.column] = cloneFortuneMetadata(entry.value);
    }
    return data;
  }

  static List<List<Object?>>? initSheetData(
    Map<String, Object?> sheet, {
    FortuneSettings settings = const FortuneSettings(),
  }) {
    final rowCount = _int(sheet['row']);
    final columnCount = _int(sheet['column']);
    final hasExplicitSize =
        rowCount != null &&
        columnCount != null &&
        rowCount > 0 &&
        columnCount > 0;
    final data = celldataToData(
      sheet['celldata'],
      rowCount: hasExplicitSize ? rowCount : settings.row,
      columnCount: hasExplicitSize ? columnCount : settings.column,
    );
    if (data == null) {
      return null;
    }
    sheet['data'] = data;
    sheet.remove('celldata');
    return data;
  }

  static Map<String, Object?> _workbookSettingsToJson(
    FortuneWorkbook workbook,
  ) {
    final settings = workbook.settings;
    const defaults = FortuneSettings();
    final raw = workbook.extraFields;
    final json = <String, Object?>{};

    void writeInt(String key, int value, int defaultValue) {
      final hasRaw = raw.containsKey(key);
      if (hasRaw) {
        final parsed = _int(raw[key]);
        if (parsed == value || (parsed == null && value == defaultValue)) {
          return;
        }
      }
      if (hasRaw || value != defaultValue) {
        json[key] = value;
      }
    }

    void writeDouble(String key, double value, double defaultValue) {
      final hasRaw = raw.containsKey(key);
      if (hasRaw) {
        final parsed = _double(raw[key]);
        if (parsed == value || (parsed == null && value == defaultValue)) {
          return;
        }
      }
      if (hasRaw || value != defaultValue) {
        json[key] = _jsonNumber(value);
      }
    }

    void writeBool(String key, bool value, bool defaultValue) {
      final hasRaw = raw.containsKey(key);
      if (hasRaw) {
        final parsed = _bool(raw[key]);
        if (parsed == value || (parsed == null && value == defaultValue)) {
          return;
        }
      }
      if (hasRaw || value != defaultValue) {
        json[key] = value;
      }
    }

    void writeString(String key, String? value, String? defaultValue) {
      final hasRaw = raw.containsKey(key);
      if (hasRaw && _string(raw[key]) == value) {
        return;
      }
      if (hasRaw || value != defaultValue) {
        json[key] = value;
      }
    }

    void writeStringList(
      String key,
      List<String> value,
      List<String> defaultValue,
    ) {
      final hasRaw = raw.containsKey(key);
      final parsed = _stringList(raw[key]);
      if (hasRaw && parsed != null && _stringListsEqual(parsed, value)) {
        return;
      }
      if (hasRaw || !_stringListsEqual(value, defaultValue)) {
        json[key] = List<String>.from(value);
      }
    }

    void writeMetadata(String key, Object? value, Object? defaultValue) {
      final hasRaw = raw.containsKey(key);
      if (hasRaw && _metadataEquals(raw[key], value)) {
        return;
      }
      if (hasRaw || !_metadataEquals(value, defaultValue)) {
        json[key] = cloneFortuneMetadata(value);
      }
    }

    writeInt('column', settings.column, defaults.column);
    writeInt('row', settings.row, defaults.row);
    writeInt('addRows', settings.addRows, defaults.addRows);
    writeBool('showToolbar', settings.showToolbar, defaults.showToolbar);
    writeBool(
      'showFormulaBar',
      settings.showFormulaBar,
      defaults.showFormulaBar,
    );
    writeBool('showSheetTabs', settings.showSheetTabs, defaults.showSheetTabs);
    writeMetadata('config', settings.config, defaults.config);
    writeDouble(
      'devicePixelRatio',
      settings.devicePixelRatio,
      defaults.devicePixelRatio,
    );
    writeBool('allowEdit', settings.allowEdit, defaults.allowEdit);
    writeString('lang', settings.lang, defaults.lang);
    writeString('currency', settings.currency, defaults.currency);
    writeBool(
      'forceCalculation',
      settings.forceCalculation,
      defaults.forceCalculation,
    );
    writeDouble(
      'rowHeaderWidth',
      settings.rowHeaderWidth,
      defaults.rowHeaderWidth,
    );
    writeDouble(
      'columnHeaderHeight',
      settings.columnHeaderHeight,
      defaults.columnHeaderHeight,
    );
    writeDouble(
      'defaultColWidth',
      settings.defaultColWidth,
      defaults.defaultColWidth,
    );
    writeDouble(
      'defaultRowHeight',
      settings.defaultRowHeight,
      defaults.defaultRowHeight,
    );
    writeDouble(
      'defaultFontSize',
      settings.defaultFontSize,
      defaults.defaultFontSize,
    );
    writeStringList(
      'fontFamilies',
      settings.fontFamilies,
      defaults.fontFamilies,
    );
    writeStringList(
      'toolbarItems',
      settings.toolbarItems,
      defaults.toolbarItems,
    );
    writeMetadata(
      'customToolbarItems',
      settings.customToolbarItems.map((item) => item.toJson()).toList(),
      const <Object?>[],
    );
    writeStringList(
      'cellContextMenu',
      settings.cellContextMenu,
      defaults.cellContextMenu,
    );
    writeStringList(
      'headerContextMenu',
      settings.headerContextMenu,
      defaults.headerContextMenu,
    );
    writeStringList(
      'sheetTabContextMenu',
      settings.sheetTabContextMenu,
      defaults.sheetTabContextMenu,
    );
    writeStringList(
      'filterContextMenu',
      settings.filterContextMenu,
      defaults.filterContextMenu,
    );
    return json;
  }

  static List<Object?> _workbookDataToJson(FortuneWorkbook workbook) {
    final canonical = [
      for (var i = 0; i < workbook.sheets.length; i += 1)
        {
          ...sheetToJson(workbook.sheets[i]),
          'status': i == workbook.activeSheetIndex ? 1 : 0,
        },
    ];
    final raw = workbook.rawData;
    if (!workbook.hasRawData || raw is! List) {
      return canonical;
    }
    final rawSheetCount = raw.whereType<Map>().length;
    if (rawSheetCount != workbook.sheets.length) {
      return canonical;
    }
    var sheetIndex = 0;
    return [
      for (final item in raw)
        if (item is Map)
          canonical[sheetIndex++]
        else
          cloneFortuneMetadata(item),
    ];
  }

  static FortuneSheet sheetFromJson(
    Map<String, Object?> json, {
    int fallbackIndex = 0,
  }) {
    final config = _map(json['config']);
    final cells = <FortuneCellCoord, FortuneCell>{};
    final nullCells = <FortuneCellCoord>{};
    if (json['data'] is List) {
      _readMatrixData(json['data'], cells, nullCells);
    } else {
      _readCelldata(json['celldata'], cells, nullCells);
    }
    final sheetId =
        _string(json['id']) ?? 'sheet_${json['order'] ?? fallbackIndex}';
    _applyConfigMerge(config['merge'], cells);
    _applySheetHyperlinks(json['hyperlink'], cells, sheetId: sheetId);
    final hasMatrixData = json['data'] is List;

    final rowHeights = _numberMap(config['rowlen']);
    final columnWidths = _numberMap(config['columnlen']);
    final hiddenRowValues = _intObjectMap(config['rowhidden']);
    final hiddenColumnValues = _intObjectMap(config['colhidden']);

    final rawImagesKey = json.containsKey('images')
        ? 'images'
        : json.containsKey('image')
        ? 'image'
        : 'images';
    final rawImages = json[rawImagesKey];

    return FortuneSheet(
      id: sheetId,
      rawId: cloneFortuneMetadata(json['id']),
      hasRawId: json.containsKey('id'),
      name: _string(json['name']) ?? 'Sheet',
      rawName: cloneFortuneMetadata(json['name']),
      hasRawName: json.containsKey('name'),
      order: _int(json['order']),
      rawOrder: cloneFortuneMetadata(json['order']),
      hasRawOrder: json.containsKey('order'),
      rowCount: _int(json['row']),
      rawRowCount: cloneFortuneMetadata(json['row']),
      hasRawRowCount: json.containsKey('row'),
      columnCount: _int(json['column']),
      rawColumnCount: cloneFortuneMetadata(json['column']),
      hasRawColumnCount: json.containsKey('column'),
      addRows: _int(json['addRows']),
      rawAddRows: cloneFortuneMetadata(json['addRows']),
      hasRawAddRows: json.containsKey('addRows'),
      defaultRowHeight: _double(json['defaultRowHeight']),
      rawDefaultRowHeight: cloneFortuneMetadata(json['defaultRowHeight']),
      hasRawDefaultRowHeight: json.containsKey('defaultRowHeight'),
      defaultColWidth: _double(json['defaultColWidth']),
      rawDefaultColWidth: cloneFortuneMetadata(json['defaultColWidth']),
      hasRawDefaultColWidth: json.containsKey('defaultColWidth'),
      status: _int(json['status']),
      rawStatus: cloneFortuneMetadata(json['status']),
      hasRawStatus: json.containsKey('status'),
      color: _string(json['color']),
      rawColor: cloneFortuneMetadata(json['color']),
      hasRawColor: json.containsKey('color'),
      hide: _int(json['hide']),
      rawHide: cloneFortuneMetadata(json['hide']),
      hasRawHide: json.containsKey('hide'),
      zoomRatio: _double(json['zoomRatio']) ?? 1,
      rawZoomRatio: cloneFortuneMetadata(json['zoomRatio']),
      hasRawZoomRatio: json.containsKey('zoomRatio'),
      showGridLines: _boolFlag(json['showGridLines'], defaultValue: true),
      rawShowGridLines: cloneFortuneMetadata(json['showGridLines']),
      hasRawShowGridLines: json.containsKey('showGridLines'),
      visibleDataRows: json['visibledatarow'],
      hasRawVisibleDataRows: json.containsKey('visibledatarow'),
      visibleDataColumns: json['visibledatacolumn'],
      hasRawVisibleDataColumns: json.containsKey('visibledatacolumn'),
      sheetWidth: _double(json['ch_width']),
      rawSheetWidth: cloneFortuneMetadata(json['ch_width']),
      hasRawSheetWidth: json.containsKey('ch_width'),
      sheetHeight: _double(json['rh_height']),
      rawSheetHeight: cloneFortuneMetadata(json['rh_height']),
      hasRawSheetHeight: json.containsKey('rh_height'),
      frozen: _frozen(json['frozen']),
      rawFrozen: cloneFortuneMetadata(json['frozen']),
      hasRawFrozen: json.containsKey('frozen'),
      cells: cells,
      nullCells: nullCells,
      rawData: cloneFortuneMetadata(json['data']),
      hasRawData: json.containsKey('data'),
      rawCelldata: hasMatrixData
          ? null
          : cloneFortuneMetadata(json['celldata']),
      hasRawCelldata: !hasMatrixData && json.containsKey('celldata'),
      rowHeights: rowHeights,
      rawRowHeights: cloneFortuneMetadata(config['rowlen']),
      hasRawRowHeights: config.containsKey('rowlen'),
      columnWidths: columnWidths,
      rawColumnWidths: cloneFortuneMetadata(config['columnlen']),
      hasRawColumnWidths: config.containsKey('columnlen'),
      customHeight: _numberMap(config['customHeight']),
      rawCustomHeight: cloneFortuneMetadata(config['customHeight']),
      hasRawCustomHeight: config.containsKey('customHeight'),
      customWidth: _numberMap(config['customWidth']),
      rawCustomWidth: cloneFortuneMetadata(config['customWidth']),
      hasRawCustomWidth: config.containsKey('customWidth'),
      hiddenRows: hiddenRowValues.keys.toSet(),
      hiddenColumns: hiddenColumnValues.keys.toSet(),
      hiddenRowValues: hiddenRowValues,
      rawHiddenRows: cloneFortuneMetadata(config['rowhidden']),
      hasRawHiddenRows: config.containsKey('rowhidden'),
      hiddenColumnValues: hiddenColumnValues,
      rawHiddenColumns: cloneFortuneMetadata(config['colhidden']),
      hasRawHiddenColumns: config.containsKey('colhidden'),
      rawMerge: cloneFortuneMetadata(config['merge']),
      hasRawMerge: config.containsKey('merge'),
      borderInfo: _borderInfo(config['borderInfo']),
      rawBorderInfo: cloneFortuneMetadata(config['borderInfo']),
      hasRawBorderInfo: config.containsKey('borderInfo'),
      images: _images(rawImages),
      rawImages: cloneFortuneMetadata(rawImages),
      hasRawImages: json.containsKey(rawImagesKey),
      rawImagesKey: rawImagesKey,
      dataVerification: _objectMap(json['dataVerification']),
      rawDataVerification: cloneFortuneMetadata(json['dataVerification']),
      hasRawDataVerification: json.containsKey('dataVerification'),
      filter: _objectMap(json['filter']),
      rawFilter: cloneFortuneMetadata(json['filter']),
      hasRawFilter: json.containsKey('filter'),
      hyperlinks: _objectMap(json['hyperlink']),
      rawHyperlinks: cloneFortuneMetadata(json['hyperlink']),
      hasRawHyperlinks: json.containsKey('hyperlink'),
      selectionSave: json['luckysheet_select_save'],
      hasRawSelectionSave: json.containsKey('luckysheet_select_save'),
      selectionRange: json['luckysheet_selection_range'],
      hasRawSelectionRange: json.containsKey('luckysheet_selection_range'),
      calcChain: json['calcChain'],
      hasRawCalcChain: json.containsKey('calcChain'),
      filterSelect: json['filter_select'],
      hasRawFilterSelect: json.containsKey('filter_select'),
      conditionFormats: json['luckysheet_conditionformat_save'],
      hasRawConditionFormats: json.containsKey(
        'luckysheet_conditionformat_save',
      ),
      alternateFormats: json['luckysheet_alternateformat_save'],
      hasRawAlternateFormats: json.containsKey(
        'luckysheet_alternateformat_save',
      ),
      alternateFormatCustomModels:
          json['luckysheet_alternateformat_save_modelCustom'],
      hasRawAlternateFormatCustomModels: json.containsKey(
        'luckysheet_alternateformat_save_modelCustom',
      ),
      pivotTable: json['pivotTable'],
      hasRawPivotTable: json.containsKey('pivotTable'),
      isPivotTable: _nullableBoolFlag(json['isPivotTable']),
      rawIsPivotTable: cloneFortuneMetadata(json['isPivotTable']),
      hasRawIsPivotTable: json.containsKey('isPivotTable'),
      dynamicArrayCompute: json['dynamicArray_compute'],
      hasRawDynamicArrayCompute: json.containsKey('dynamicArray_compute'),
      dynamicArray: json['dynamicArray'],
      hasRawDynamicArray: json.containsKey('dynamicArray'),
      authority: config['authority'],
      hasRawAuthority: config.containsKey('authority'),
      rowReadOnly: config['rowReadOnly'],
      hasRawRowReadOnly: config.containsKey('rowReadOnly'),
      colReadOnly: config['colReadOnly'],
      hasRawColReadOnly: config.containsKey('colReadOnly'),
      rawConfig: cloneFortuneMetadata(json['config']),
      hasRawConfig: json.containsKey('config'),
      extraFields: _unhandledSheetFields(json),
      configExtraFields: _unhandledConfigFields(config),
    );
  }

  static Map<String, Object?> sheetToJson(FortuneSheet sheet) {
    final celldata = _celldataToJson(sheet.cells, sheet.nullCells);
    final config = <String, Object?>{
      for (final entry in sheet.configExtraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
    };
    if (sheet.rowHeights.isNotEmpty) {
      config['rowlen'] = _rawOrIntDoubleMapToJson(
        values: sheet.rowHeights,
        raw: sheet.rawRowHeights,
        hasRaw: sheet.hasRawRowHeights,
      );
    } else if (sheet.hasRawRowHeights) {
      config['rowlen'] = cloneFortuneMetadata(sheet.rawRowHeights);
    }
    if (sheet.columnWidths.isNotEmpty) {
      config['columnlen'] = _rawOrIntDoubleMapToJson(
        values: sheet.columnWidths,
        raw: sheet.rawColumnWidths,
        hasRaw: sheet.hasRawColumnWidths,
      );
    } else if (sheet.hasRawColumnWidths) {
      config['columnlen'] = cloneFortuneMetadata(sheet.rawColumnWidths);
    }
    if (sheet.customHeight.isNotEmpty) {
      config['customHeight'] = _rawOrIntDoubleMapToJson(
        values: sheet.customHeight,
        raw: sheet.rawCustomHeight,
        hasRaw: sheet.hasRawCustomHeight,
      );
    } else if (sheet.hasRawCustomHeight) {
      config['customHeight'] = cloneFortuneMetadata(sheet.rawCustomHeight);
    }
    if (sheet.customWidth.isNotEmpty) {
      config['customWidth'] = _rawOrIntDoubleMapToJson(
        values: sheet.customWidth,
        raw: sheet.rawCustomWidth,
        hasRaw: sheet.hasRawCustomWidth,
      );
    } else if (sheet.hasRawCustomWidth) {
      config['customWidth'] = cloneFortuneMetadata(sheet.rawCustomWidth);
    }
    if (sheet.hiddenRows.isNotEmpty) {
      config['rowhidden'] = _rawOrIntObjectMapToJson(
        values: sheet.hiddenRowValues,
        keys: sheet.hiddenRows,
        raw: sheet.rawHiddenRows,
        hasRaw: sheet.hasRawHiddenRows,
      );
    } else if (sheet.hasRawHiddenRows &&
        _intObjectMap(sheet.rawHiddenRows).isEmpty) {
      config['rowhidden'] = cloneFortuneMetadata(sheet.rawHiddenRows);
    }
    if (sheet.hiddenColumns.isNotEmpty) {
      config['colhidden'] = _rawOrIntObjectMapToJson(
        values: sheet.hiddenColumnValues,
        keys: sheet.hiddenColumns,
        raw: sheet.rawHiddenColumns,
        hasRaw: sheet.hasRawHiddenColumns,
      );
    } else if (sheet.hasRawHiddenColumns &&
        _intObjectMap(sheet.rawHiddenColumns).isEmpty) {
      config['colhidden'] = cloneFortuneMetadata(sheet.rawHiddenColumns);
    }
    final merge = _mergeConfigToJson(sheet.cells);
    if (merge.isNotEmpty) {
      config['merge'] = _rawOrMergeConfigToJson(
        values: merge,
        raw: sheet.rawMerge,
        hasRaw: sheet.hasRawMerge,
      );
    } else if (sheet.hasRawMerge && _rawMergeConfigIsEmpty(sheet.rawMerge)) {
      config['merge'] = cloneFortuneMetadata(sheet.rawMerge);
    }
    if (sheet.borderInfo.isNotEmpty) {
      config['borderInfo'] = _rawOrBorderInfoToJson(
        values: sheet.borderInfo,
        raw: sheet.rawBorderInfo,
        hasRaw: sheet.hasRawBorderInfo,
      );
    } else if (sheet.hasRawBorderInfo) {
      config['borderInfo'] = cloneFortuneMetadata(sheet.rawBorderInfo);
    }
    if (sheet.hasRawAuthority || sheet.authority != null) {
      config['authority'] = cloneFortuneMetadata(sheet.authority);
    }
    if (sheet.hasRawRowReadOnly || sheet.rowReadOnly != null) {
      config['rowReadOnly'] = cloneFortuneMetadata(sheet.rowReadOnly);
    }
    if (sheet.hasRawColReadOnly || sheet.colReadOnly != null) {
      config['colReadOnly'] = cloneFortuneMetadata(sheet.colReadOnly);
    }

    final json = <String, Object?>{
      for (final entry in sheet.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'id': _rawOrString(
        value: sheet.id,
        raw: sheet.rawId,
        hasRaw: sheet.hasRawId,
      ),
      'name': _rawOrString(
        value: sheet.name,
        raw: sheet.rawName,
        hasRaw: sheet.hasRawName,
      ),
      if (sheet.hasRawOrder || sheet.order != null)
        'order': _rawOrJsonNullableInt(
          value: sheet.order,
          raw: sheet.rawOrder,
          hasRaw: sheet.hasRawOrder,
        ),
      if (sheet.hasRawColor || sheet.color != null)
        'color': _rawOrString(
          value: sheet.color,
          raw: sheet.rawColor,
          hasRaw: sheet.hasRawColor,
        ),
      if (sheet.hasRawRowCount || sheet.rowCount != null)
        'row': _rawOrJsonNullableInt(
          value: sheet.rowCount,
          raw: sheet.rawRowCount,
          hasRaw: sheet.hasRawRowCount,
        ),
      if (sheet.hasRawColumnCount || sheet.columnCount != null)
        'column': _rawOrJsonNullableInt(
          value: sheet.columnCount,
          raw: sheet.rawColumnCount,
          hasRaw: sheet.hasRawColumnCount,
        ),
      if (sheet.hasRawAddRows || sheet.addRows != null)
        'addRows': _rawOrJsonNullableInt(
          value: sheet.addRows,
          raw: sheet.rawAddRows,
          hasRaw: sheet.hasRawAddRows,
        ),
      if (sheet.hasRawStatus || sheet.status != null)
        'status': _rawOrJsonNullableInt(
          value: sheet.status,
          raw: sheet.rawStatus,
          hasRaw: sheet.hasRawStatus,
        ),
      if (sheet.hasRawHide || sheet.hide != null)
        'hide': _rawOrJsonNullableInt(
          value: sheet.hide,
          raw: sheet.rawHide,
          hasRaw: sheet.hasRawHide,
        ),
      if (sheet.hasRawDefaultRowHeight || sheet.defaultRowHeight != null)
        'defaultRowHeight': _rawOrJsonNumber(
          value: sheet.defaultRowHeight,
          raw: sheet.rawDefaultRowHeight,
          hasRaw: sheet.hasRawDefaultRowHeight,
        ),
      if (sheet.hasRawDefaultColWidth || sheet.defaultColWidth != null)
        'defaultColWidth': _rawOrJsonNumber(
          value: sheet.defaultColWidth,
          raw: sheet.rawDefaultColWidth,
          hasRaw: sheet.hasRawDefaultColWidth,
        ),
      if (sheet.hasRawZoomRatio || sheet.zoomRatio != 1)
        'zoomRatio': _rawOrJsonNumber(
          value: sheet.zoomRatio,
          raw: sheet.rawZoomRatio,
          hasRaw: sheet.hasRawZoomRatio,
        ),
      if (sheet.hasRawShowGridLines || !sheet.showGridLines)
        'showGridLines': _rawOrNumericBoolFlag(
          value: sheet.showGridLines,
          raw: sheet.rawShowGridLines,
          hasRaw: sheet.hasRawShowGridLines,
        ),
      if (sheet.hasRawVisibleDataRows || sheet.visibleDataRows != null)
        'visibledatarow': cloneFortuneMetadata(sheet.visibleDataRows),
      if (sheet.hasRawVisibleDataColumns || sheet.visibleDataColumns != null)
        'visibledatacolumn': cloneFortuneMetadata(sheet.visibleDataColumns),
      if (sheet.hasRawSheetWidth || sheet.sheetWidth != null)
        'ch_width': _rawOrJsonNumber(
          value: sheet.sheetWidth,
          raw: sheet.rawSheetWidth,
          hasRaw: sheet.hasRawSheetWidth,
        ),
      if (sheet.hasRawSheetHeight || sheet.sheetHeight != null)
        'rh_height': _rawOrJsonNumber(
          value: sheet.sheetHeight,
          raw: sheet.rawSheetHeight,
          hasRaw: sheet.hasRawSheetHeight,
        ),
      if (config.isNotEmpty ||
          (sheet.hasRawConfig && _rawConfigIsEmpty(sheet.rawConfig)))
        'config': config.isNotEmpty
            ? config
            : cloneFortuneMetadata(sheet.rawConfig),
      if (sheet.hasRawData &&
          _rawDataMatrixUnchanged(
            cells: sheet.cells,
            nullCells: sheet.nullCells,
            raw: sheet.rawData,
            rawMerge: sheet.rawMerge,
            rawHyperlinks: sheet.rawHyperlinks,
            sheetId: sheet.id,
          ))
        'data': cloneFortuneMetadata(sheet.rawData),
      if (celldata.isNotEmpty &&
          !(sheet.hasRawData &&
              _rawDataMatrixUnchanged(
                cells: sheet.cells,
                nullCells: sheet.nullCells,
                raw: sheet.rawData,
                rawMerge: sheet.rawMerge,
                rawHyperlinks: sheet.rawHyperlinks,
                sheetId: sheet.id,
              )))
        'celldata': _rawOrCelldataToJson(
          cells: sheet.cells,
          nullCells: sheet.nullCells,
          raw: sheet.rawCelldata,
          hasRaw: sheet.hasRawCelldata,
          rawMerge: sheet.rawMerge,
          rawHyperlinks: sheet.rawHyperlinks,
          sheetId: sheet.id,
        ),
      if (celldata.isEmpty &&
          !sheet.hasRawData &&
          sheet.hasRawCelldata &&
          _rawCelldataIsEmpty(sheet.rawCelldata))
        'celldata': cloneFortuneMetadata(sheet.rawCelldata),
      if (sheet.images.isNotEmpty)
        sheet.rawImagesKey: _rawOrImagesToJson(
          values: sheet.images,
          raw: sheet.rawImages,
          hasRaw: sheet.hasRawImages,
        ),
      if (sheet.images.isEmpty && sheet.hasRawImages)
        sheet.rawImagesKey: cloneFortuneMetadata(sheet.rawImages),
      if (sheet.dataVerification.isNotEmpty)
        'dataVerification': _stringObjectMapToJson(sheet.dataVerification),
      if (sheet.dataVerification.isEmpty && sheet.hasRawDataVerification)
        'dataVerification': cloneFortuneMetadata(sheet.rawDataVerification),
      if (sheet.filter.isNotEmpty)
        'filter': _stringObjectMapToJson(sheet.filter),
      if (sheet.filter.isEmpty && sheet.hasRawFilter)
        'filter': cloneFortuneMetadata(sheet.rawFilter),
      if (sheet.hyperlinks.isNotEmpty)
        'hyperlink': _stringObjectMapToJson(sheet.hyperlinks),
      if (sheet.hyperlinks.isEmpty && sheet.hasRawHyperlinks)
        'hyperlink': cloneFortuneMetadata(sheet.rawHyperlinks),
      if (sheet.hasRawSelectionSave || sheet.selectionSave != null)
        'luckysheet_select_save': cloneFortuneMetadata(sheet.selectionSave),
      if (sheet.hasRawSelectionRange || sheet.selectionRange != null)
        'luckysheet_selection_range': cloneFortuneMetadata(
          sheet.selectionRange,
        ),
      if (sheet.hasRawCalcChain || sheet.calcChain != null)
        'calcChain': cloneFortuneMetadata(sheet.calcChain),
      if (sheet.hasRawFilterSelect || sheet.filterSelect != null)
        'filter_select': cloneFortuneMetadata(sheet.filterSelect),
      if (sheet.hasRawConditionFormats || sheet.conditionFormats != null)
        'luckysheet_conditionformat_save': cloneFortuneMetadata(
          sheet.conditionFormats,
        ),
      if (sheet.hasRawAlternateFormats || sheet.alternateFormats != null)
        'luckysheet_alternateformat_save': cloneFortuneMetadata(
          sheet.alternateFormats,
        ),
      if (sheet.hasRawAlternateFormatCustomModels ||
          sheet.alternateFormatCustomModels != null)
        'luckysheet_alternateformat_save_modelCustom': cloneFortuneMetadata(
          sheet.alternateFormatCustomModels,
        ),
      if (sheet.hasRawPivotTable || sheet.pivotTable != null)
        'pivotTable': cloneFortuneMetadata(sheet.pivotTable),
      if (sheet.hasRawIsPivotTable || sheet.isPivotTable != null)
        'isPivotTable': _rawOrNullableBoolFlag(
          value: sheet.isPivotTable,
          raw: sheet.rawIsPivotTable,
          hasRaw: sheet.hasRawIsPivotTable,
        ),
      if (sheet.hasRawDynamicArrayCompute || sheet.dynamicArrayCompute != null)
        'dynamicArray_compute': cloneFortuneMetadata(sheet.dynamicArrayCompute),
      if (sheet.hasRawDynamicArray || sheet.dynamicArray != null)
        'dynamicArray': cloneFortuneMetadata(sheet.dynamicArray),
      if (sheet.frozen != null)
        'frozen': _rawOrFrozenToJson(
          value: sheet.frozen!,
          raw: sheet.rawFrozen,
          hasRaw: sheet.hasRawFrozen,
        ),
      if (sheet.frozen == null && sheet.hasRawFrozen)
        'frozen': cloneFortuneMetadata(sheet.rawFrozen),
    };
    return json;
  }

  static Map<String, Object?> _unhandledWorkbookFields(
    Map<String, Object?> json,
  ) {
    const handled = {'data'};
    return _unhandledFields(json, handled);
  }

  static Map<String, Object?> _unhandledSheetFields(Map<String, Object?> json) {
    const handled = {
      'name',
      'config',
      'order',
      'color',
      'data',
      'celldata',
      'id',
      'images',
      'image',
      'zoomRatio',
      'column',
      'row',
      'addRows',
      'status',
      'hide',
      'luckysheet_select_save',
      'luckysheet_selection_range',
      'calcChain',
      'defaultRowHeight',
      'defaultColWidth',
      'showGridLines',
      'visibledatarow',
      'visibledatacolumn',
      'ch_width',
      'rh_height',
      'pivotTable',
      'isPivotTable',
      'filter',
      'filter_select',
      'luckysheet_conditionformat_save',
      'luckysheet_alternateformat_save',
      'luckysheet_alternateformat_save_modelCustom',
      'dataVerification',
      'hyperlink',
      'dynamicArray_compute',
      'dynamicArray',
      'frozen',
    };
    return _unhandledFields(json, handled);
  }

  static Map<String, Object?> _unhandledConfigFields(
    Map<String, Object?> config,
  ) {
    const handled = {
      'merge',
      'rowlen',
      'columnlen',
      'rowhidden',
      'colhidden',
      'customHeight',
      'customWidth',
      'borderInfo',
      'authority',
      'rowReadOnly',
      'colReadOnly',
    };
    return _unhandledFields(config, handled);
  }

  static Map<String, Object?> _unhandledFields(
    Map<String, Object?> json,
    Set<String> handled,
  ) {
    return {
      for (final entry in json.entries)
        if (!handled.contains(entry.key))
          entry.key: cloneFortuneMetadata(entry.value),
    };
  }

  static void _readCelldata(
    Object? raw,
    Map<FortuneCellCoord, FortuneCell> cells,
    Set<FortuneCellCoord> nullCells,
  ) {
    if (raw is! List) {
      return;
    }
    for (final item in raw.whereType<Map>()) {
      final row = _int(item['r']);
      final column = _int(item['c']);
      if (row == null || column == null) {
        continue;
      }
      final coord = FortuneCellCoord(row, column);
      final value = item['v'];
      if (value is Map) {
        cells[coord] = cellFromJson(Map<String, Object?>.from(value));
        nullCells.remove(coord);
      } else if (item.containsKey('v') && value == null) {
        cells.remove(coord);
        nullCells.add(coord);
      } else if (item.containsKey('v')) {
        final generated = genarate(value);
        if (generated != null) {
          cells[coord] = cellFromJson({
            'v': generated[2],
            'm': generated[0],
            'ct': generated[1],
          });
          nullCells.remove(coord);
        }
      }
    }
  }

  static List<Map<String, Object?>> _celldataToJson(
    Map<FortuneCellCoord, FortuneCell> cells,
    Set<FortuneCellCoord> nullCells,
  ) {
    final coords = {...cells.keys, ...nullCells}.toList()..sort(_compareCoord);
    final items = <Map<String, Object?>>[];
    for (final coord in coords) {
      if (cells.containsKey(coord)) {
        final cell = cells[coord]!;
        final value = cellToJson(cell);
        if (_isMergeOnlyCell(value)) {
          continue;
        }
        items.add({'r': coord.row, 'c': coord.column, 'v': value});
      } else {
        items.add({'r': coord.row, 'c': coord.column, 'v': null});
      }
    }
    return items;
  }

  static Object? _rawOrCelldataToJson({
    required Map<FortuneCellCoord, FortuneCell> cells,
    required Set<FortuneCellCoord> nullCells,
    required Object? raw,
    required bool hasRaw,
    required Object? rawMerge,
    required Object? rawHyperlinks,
    required String sheetId,
  }) {
    if (hasRaw && raw is List) {
      final rawCells = <FortuneCellCoord, FortuneCell>{};
      final rawNullCells = <FortuneCellCoord>{};
      _readCelldata(raw, rawCells, rawNullCells);
      _applyConfigMerge(rawMerge, rawCells);
      _applySheetHyperlinks(rawHyperlinks, rawCells, sheetId: sheetId);
      if (_metadataEquals(
        _celldataToJson(rawCells, rawNullCells),
        _celldataToJson(cells, nullCells),
      )) {
        return cloneFortuneMetadata(raw);
      }
    }
    return _celldataToJson(cells, nullCells);
  }

  static bool _rawCelldataIsEmpty(Object? raw) {
    if (raw is! List) {
      return true;
    }
    final rawCells = <FortuneCellCoord, FortuneCell>{};
    final rawNullCells = <FortuneCellCoord>{};
    _readCelldata(raw, rawCells, rawNullCells);
    return _celldataToJson(rawCells, rawNullCells).isEmpty;
  }

  static bool _rawDataMatrixUnchanged({
    required Map<FortuneCellCoord, FortuneCell> cells,
    required Set<FortuneCellCoord> nullCells,
    required Object? raw,
    required Object? rawMerge,
    required Object? rawHyperlinks,
    required String sheetId,
  }) {
    if (raw is! List) {
      return cells.isEmpty && nullCells.isEmpty;
    }
    final rawCells = <FortuneCellCoord, FortuneCell>{};
    final rawNullCells = <FortuneCellCoord>{};
    _readMatrixData(raw, rawCells, rawNullCells);
    _applyConfigMerge(rawMerge, rawCells);
    _applySheetHyperlinks(rawHyperlinks, rawCells, sheetId: sheetId);
    return _metadataEquals(
      _celldataToJson(rawCells, rawNullCells),
      _celldataToJson(cells, nullCells),
    );
  }

  static bool _rawMergeConfigIsEmpty(Object? raw) {
    if (raw is! Map) {
      return true;
    }
    final rawCells = <FortuneCellCoord, FortuneCell>{};
    _applyConfigMerge(raw, rawCells);
    return _mergeConfigToJson(rawCells).isEmpty;
  }

  static bool _rawConfigIsEmpty(Object? raw) {
    if (raw is! Map) {
      return true;
    }
    final config = _map(raw);
    if (!_rawMergeConfigIsEmpty(config['merge'])) {
      return false;
    }
    if (_numberMap(config['rowlen']).isNotEmpty ||
        _numberMap(config['columnlen']).isNotEmpty ||
        _numberMap(config['customHeight']).isNotEmpty ||
        _numberMap(config['customWidth']).isNotEmpty ||
        _intObjectMap(config['rowhidden']).isNotEmpty ||
        _intObjectMap(config['colhidden']).isNotEmpty ||
        _borderInfo(config['borderInfo']).isNotEmpty ||
        config.containsKey('authority') ||
        config.containsKey('rowReadOnly') ||
        config.containsKey('colReadOnly')) {
      return false;
    }
    return _unhandledConfigFields(config).isEmpty;
  }

  static bool _isMergeOnlyCell(Map<String, Object?> json) {
    return json.length == 1 && json.containsKey('mc');
  }

  static int _compareCoord(FortuneCellCoord a, FortuneCellCoord b) {
    final rowCompare = a.row.compareTo(b.row);
    return rowCompare == 0 ? a.column.compareTo(b.column) : rowCompare;
  }

  static void _readMatrixData(
    Object? raw,
    Map<FortuneCellCoord, FortuneCell> cells,
    Set<FortuneCellCoord> nullCells,
  ) {
    if (raw is! List) {
      return;
    }
    for (var r = 0; r < raw.length; r += 1) {
      final row = raw[r];
      if (row is! List) {
        continue;
      }
      for (var c = 0; c < row.length; c += 1) {
        final value = row[c];
        if (value is Map) {
          final coord = FortuneCellCoord(r, c);
          cells[coord] = cellFromJson(Map<String, Object?>.from(value));
          nullCells.remove(coord);
        }
      }
    }
  }

  static FortuneCell cellFromJson(Map<String, Object?> json) {
    final rawType = json['ct'];
    final type = _map(rawType);
    final rawMerge = json['mc'];
    final merge = _map(rawMerge);
    return FortuneCell(
      value: _cellValue(json['v']),
      rawValue: cloneFortuneMetadata(json['v']),
      hasRawValue: json.containsKey('v'),
      displayValue: _optionalCellValue(json['m']),
      rawDisplayValue: cloneFortuneMetadata(json['m']),
      hasRawDisplayValue: json.containsKey('m'),
      formula: _string(json['f']),
      rawFormula: cloneFortuneMetadata(json['f']),
      hasRawFormula: json.containsKey('f'),
      quotePrefix: _boolFlag(json['qp']),
      rawQuotePrefix: cloneFortuneMetadata(json['qp']),
      hasRawQuotePrefix: json.containsKey('qp'),
      sparkline: cloneFortuneMetadata(json['spl']),
      rawSparkline: cloneFortuneMetadata(json['spl']),
      hasSparkline: json.containsKey('spl'),
      hasRawSparkline: json.containsKey('spl'),
      locked: _nullableBoolFlag(json['lo']),
      rawLocked: cloneFortuneMetadata(json['lo']),
      hasRawLocked: json.containsKey('lo'),
      merge: rawMerge is! Map
          ? null
          : FortuneCellMerge(
              row: _int(merge['r']) ?? 0,
              rawRow: cloneFortuneMetadata(merge['r']),
              hasRawRow: merge.containsKey('r'),
              column: _int(merge['c']) ?? 0,
              rawColumn: cloneFortuneMetadata(merge['c']),
              hasRawColumn: merge.containsKey('c'),
              rowSpan: _int(merge['rs']) ?? 1,
              rawRowSpan: cloneFortuneMetadata(merge['rs']),
              hasRawRowSpan: merge.containsKey('rs'),
              columnSpan: _int(merge['cs']) ?? 1,
              rawColumnSpan: cloneFortuneMetadata(merge['cs']),
              hasRawColumnSpan: merge.containsKey('cs'),
              preserveEmpty: merge.isEmpty,
              extraFields: _unhandledFields(merge, {'r', 'c', 'rs', 'cs'}),
            ),
      cellType: rawType is! Map
          ? null
          : FortuneCellType(
              format: _string(type['fa']),
              rawFormat: cloneFortuneMetadata(type['fa']),
              hasRawFormat: type.containsKey('fa'),
              type: _string(type['t']),
              rawType: cloneFortuneMetadata(type['t']),
              hasRawType: type.containsKey('t'),
              style: cloneFortuneMetadata(type['s']),
              rawStyle: cloneFortuneMetadata(type['s']),
              hasRawStyle: type.containsKey('s'),
              extraFields: _unhandledFields(type, {'fa', 't', 's'}),
            ),
      comment: _comment(json['ps']),
      hyperlink: _cellHyperlink(json['hl']),
      background: parseColor(_string(json['bg'])),
      rawBackground: cloneFortuneMetadata(json['bg']),
      hasRawBackground: json.containsKey('bg'),
      foreground: parseColor(_string(json['fc'])) ?? const Color(0xff000000),
      rawForeground: cloneFortuneMetadata(json['fc']),
      hasRawForeground: json.containsKey('fc'),
      bold: _boolFlag(json['bl']),
      rawBold: cloneFortuneMetadata(json['bl']),
      hasRawBold: json.containsKey('bl'),
      italic: _boolFlag(json['it']),
      rawItalic: cloneFortuneMetadata(json['it']),
      hasRawItalic: json.containsKey('it'),
      strikeThrough: _boolFlag(json['cl']),
      rawStrikeThrough: cloneFortuneMetadata(json['cl']),
      hasRawStrikeThrough: json.containsKey('cl'),
      underline: _boolFlag(json['un']),
      rawUnderline: cloneFortuneMetadata(json['un']),
      hasRawUnderline: json.containsKey('un'),
      fontSize: _double(json['fs']),
      rawFontSize: cloneFortuneMetadata(json['fs']),
      hasRawFontSize: json.containsKey('fs'),
      fontFamily: _string(json['ff']),
      rawFontFamily: cloneFortuneMetadata(json['ff']),
      hasRawFontFamily: json.containsKey('ff'),
      horizontalAlign: _string(json['ht']),
      rawHorizontalAlign: cloneFortuneMetadata(json['ht']),
      hasRawHorizontalAlign: json.containsKey('ht'),
      verticalAlign: _string(json['vt']),
      rawVerticalAlign: cloneFortuneMetadata(json['vt']),
      hasRawVerticalAlign: json.containsKey('vt'),
      textWrap: _string(json['tb']),
      rawTextWrap: cloneFortuneMetadata(json['tb']),
      hasRawTextWrap: json.containsKey('tb'),
      textRotation: _string(json['rt']),
      rawTextRotation: cloneFortuneMetadata(json['rt']),
      hasRawTextRotation: json.containsKey('rt'),
      textRotationMode: _string(json['tr']),
      rawTextRotationMode: cloneFortuneMetadata(json['tr']),
      hasRawTextRotationMode: json.containsKey('tr'),
      inlineRuns: _inlineRuns(type['s']),
      extraFields: _unhandledCellFields(json),
    );
  }

  static Map<String, Object?> cellToJson(FortuneCell cell) {
    final json = <String, Object?>{
      for (final entry in cell.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
    };

    if (cell.hasRawValue) {
      final raw = cloneFortuneMetadata(cell.rawValue);
      json['v'] = raw == null && cell.value.isEmpty
          ? null
          : raw != null && '$raw' == cell.value
          ? raw
          : cell.value;
    } else if (cell.value.isNotEmpty) {
      json['v'] = cell.value;
    }
    if (cell.hasRawDisplayValue || cell.displayValue != null) {
      final raw = cloneFortuneMetadata(cell.rawDisplayValue);
      json['m'] =
          cell.hasRawDisplayValue && raw == null && cell.displayValue == null
          ? null
          : cell.hasRawDisplayValue &&
                raw != null &&
                '$raw' == cell.displayValue
          ? raw
          : cell.displayValue;
    }
    if (cell.hasRawFormula || cell.formula != null) {
      final raw = cloneFortuneMetadata(cell.rawFormula);
      json['f'] = cell.hasRawFormula && raw != null && '$raw' == cell.formula
          ? raw
          : cell.formula;
    }
    if (cell.merge != null) {
      json['mc'] = _mergeToJson(cell.merge!);
    }
    if (cell.cellType != null || cell.inlineRuns != null) {
      json['ct'] = _cellTypeToJson(cell);
    }
    if (cell.hasRawQuotePrefix || cell.quotePrefix) {
      json['qp'] = _rawOrNumericBoolFlag(
        value: cell.quotePrefix,
        raw: cell.rawQuotePrefix,
        hasRaw: cell.hasRawQuotePrefix,
      );
    }
    if (cell.hasRawSparkline || cell.hasSparkline || cell.sparkline != null) {
      json['spl'] = cloneFortuneMetadata(
        cell.hasRawSparkline ? cell.rawSparkline : cell.sparkline,
      );
    }
    if (cell.background != null) {
      json['bg'] = _rawOrHexColor(
        color: cell.background!,
        raw: cell.rawBackground,
        hasRaw: cell.hasRawBackground,
      );
    } else if (cell.hasRawBackground) {
      json['bg'] = cloneFortuneMetadata(cell.rawBackground);
    }
    if (cell.hasRawLocked || cell.locked != null) {
      json['lo'] = _rawOrNullableNumericBoolFlag(
        value: cell.locked,
        raw: cell.rawLocked,
        hasRaw: cell.hasRawLocked,
      );
    }
    if (cell.comment != null) {
      json['ps'] = _commentToJson(cell.comment!);
    }
    if (cell.hyperlink != null) {
      json['hl'] = _cellHyperlinkToJson(cell.hyperlink!);
    }
    if (cell.hasRawForeground || cell.foreground != const Color(0xff000000)) {
      json['fc'] =
          cell.hasRawForeground &&
              cell.rawForeground == null &&
              cell.foreground == const Color(0xff000000)
          ? null
          : _rawOrHexColor(
              color: cell.foreground,
              raw: cell.rawForeground,
              hasRaw: cell.hasRawForeground,
            );
    }
    if (cell.hasRawBold || cell.bold) {
      json['bl'] = _rawOrNumericBoolFlag(
        value: cell.bold,
        raw: cell.rawBold,
        hasRaw: cell.hasRawBold,
      );
    }
    if (cell.hasRawItalic || cell.italic) {
      json['it'] = _rawOrNumericBoolFlag(
        value: cell.italic,
        raw: cell.rawItalic,
        hasRaw: cell.hasRawItalic,
      );
    }
    if (cell.hasRawStrikeThrough || cell.strikeThrough) {
      json['cl'] = _rawOrNumericBoolFlag(
        value: cell.strikeThrough,
        raw: cell.rawStrikeThrough,
        hasRaw: cell.hasRawStrikeThrough,
      );
    }
    if (cell.hasRawUnderline || cell.underline) {
      json['un'] = _rawOrNumericBoolFlag(
        value: cell.underline,
        raw: cell.rawUnderline,
        hasRaw: cell.hasRawUnderline,
      );
    }
    if (cell.hasRawFontSize || cell.fontSize != null) {
      json['fs'] = _rawOrJsonNumber(
        value: cell.fontSize,
        raw: cell.rawFontSize,
        hasRaw: cell.hasRawFontSize,
      );
    }
    if (cell.hasRawFontFamily || cell.fontFamily != null) {
      json['ff'] = _rawOrStyleValue(
        value: cell.fontFamily,
        raw: cell.rawFontFamily,
        hasRaw: cell.hasRawFontFamily,
      );
    }
    if (cell.hasRawHorizontalAlign || cell.horizontalAlign != null) {
      json['ht'] = _rawOrStyleValue(
        value: cell.horizontalAlign,
        raw: cell.rawHorizontalAlign,
        hasRaw: cell.hasRawHorizontalAlign,
      );
    }
    if (cell.hasRawVerticalAlign || cell.verticalAlign != null) {
      json['vt'] = _rawOrStyleValue(
        value: cell.verticalAlign,
        raw: cell.rawVerticalAlign,
        hasRaw: cell.hasRawVerticalAlign,
      );
    }
    if (cell.hasRawTextWrap || cell.textWrap != null) {
      json['tb'] = _rawOrStyleValue(
        value: cell.textWrap,
        raw: cell.rawTextWrap,
        hasRaw: cell.hasRawTextWrap,
        numericDefault: false,
      );
    }
    if (cell.hasRawTextRotation || cell.textRotation != null) {
      final raw = cloneFortuneMetadata(cell.rawTextRotation);
      json['rt'] =
          cell.hasRawTextRotation &&
              (raw == null || '$raw' == cell.textRotation)
          ? raw
          : cell.textRotation;
    }
    if (cell.hasRawTextRotationMode || cell.textRotationMode != null) {
      json['tr'] = _rawOrStyleValue(
        value: cell.textRotationMode,
        raw: cell.rawTextRotationMode,
        hasRaw: cell.hasRawTextRotationMode,
        numericDefault: false,
      );
    }
    return json;
  }

  static void _applySheetHyperlinks(
    Object? raw,
    Map<FortuneCellCoord, FortuneCell> cells, {
    required String sheetId,
  }) {
    if (raw is! Map) {
      return;
    }
    raw.forEach((key, value) {
      if (value is! Map) {
        return;
      }
      final parts = '$key'.split('_');
      if (parts.length != 2) {
        return;
      }
      final row = int.tryParse(parts[0]);
      final column = int.tryParse(parts[1]);
      if (row == null || column == null) {
        return;
      }
      final coord = FortuneCellCoord(row, column);
      final cell = cells[coord];
      if (cell == null) {
        return;
      }
      final map = Map<String, Object?>.from(value);
      final hyperlink = cell.hyperlink ?? const FortuneHyperlink();
      cells[coord] = cell.copyWith(
        hyperlink: hyperlink.copyWith(
          row: row,
          column: column,
          id: hyperlink.id ?? sheetId,
          linkType: _string(map['linkType']),
          rawLinkType: cloneFortuneMetadata(map['linkType']),
          hasRawLinkType: map.containsKey('linkType'),
          linkAddress: _string(map['linkAddress']),
          rawLinkAddress: cloneFortuneMetadata(map['linkAddress']),
          hasRawLinkAddress: map.containsKey('linkAddress'),
          extraFields: {
            ...hyperlink.extraFields,
            ..._unhandledFields(map, {'linkType', 'linkAddress'}),
          },
        ),
      );
    });
  }

  static void _applyConfigMerge(
    Object? raw,
    Map<FortuneCellCoord, FortuneCell> cells,
  ) {
    if (raw is! Map) {
      return;
    }
    raw.forEach((_, value) {
      if (value is! Map) {
        return;
      }
      final map = Map<String, Object?>.from(value);
      final row = _int(map['r']);
      final column = _int(map['c']);
      final rowSpan = _int(map['rs']) ?? 1;
      final columnSpan = _int(map['cs']) ?? 1;
      if (row == null || column == null) {
        return;
      }
      final merge = FortuneCellMerge(
        row: row,
        rawRow: cloneFortuneMetadata(map['r']),
        hasRawRow: map.containsKey('r'),
        column: column,
        rawColumn: cloneFortuneMetadata(map['c']),
        hasRawColumn: map.containsKey('c'),
        rowSpan: rowSpan,
        rawRowSpan: cloneFortuneMetadata(map['rs']),
        hasRawRowSpan: map.containsKey('rs'),
        columnSpan: columnSpan,
        rawColumnSpan: cloneFortuneMetadata(map['cs']),
        hasRawColumnSpan: map.containsKey('cs'),
        extraFields: _unhandledFields(map, {'r', 'c', 'rs', 'cs'}),
      );
      final anchor = FortuneCellCoord(row, column);
      cells[anchor] = (cells[anchor] ?? const FortuneCell()).copyWith(
        merge: merge,
      );
      for (var r = row; r < row + rowSpan; r += 1) {
        for (var c = column; c < column + columnSpan; c += 1) {
          final coord = FortuneCellCoord(r, c);
          if (coord == anchor) {
            continue;
          }
          cells[coord] = (cells[coord] ?? const FortuneCell()).copyWith(
            merge: FortuneCellMerge(row: row, column: column),
          );
        }
      }
    });
  }

  static FortuneCellComment? _comment(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, Object?>.from(raw);
    return FortuneCellComment(
      value: _string(map['value']) ?? '',
      rawValue: cloneFortuneMetadata(map['value']),
      hasRawValue: map.containsKey('value'),
      left: _double(map['left']),
      rawLeft: cloneFortuneMetadata(map['left']),
      hasRawLeft: map.containsKey('left'),
      top: _double(map['top']),
      rawTop: cloneFortuneMetadata(map['top']),
      hasRawTop: map.containsKey('top'),
      width: _double(map['width']),
      rawWidth: cloneFortuneMetadata(map['width']),
      hasRawWidth: map.containsKey('width'),
      height: _double(map['height']),
      rawHeight: cloneFortuneMetadata(map['height']),
      hasRawHeight: map.containsKey('height'),
      isShow: _boolFlag(map['isShow']),
      rawIsShow: cloneFortuneMetadata(map['isShow']),
      hasRawIsShow: map.containsKey('isShow'),
      extraFields: _unhandledFields(map, {
        'left',
        'top',
        'width',
        'height',
        'value',
        'isShow',
      }),
    );
  }

  static Map<String, Object?> _commentToJson(FortuneCellComment comment) {
    return {
      for (final entry in comment.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      if (comment.hasRawLeft || comment.left != null)
        'left': _rawOrJsonNumber(
          value: comment.left,
          raw: comment.rawLeft,
          hasRaw: comment.hasRawLeft,
        ),
      if (comment.hasRawTop || comment.top != null)
        'top': _rawOrJsonNumber(
          value: comment.top,
          raw: comment.rawTop,
          hasRaw: comment.hasRawTop,
        ),
      if (comment.hasRawWidth || comment.width != null)
        'width': _rawOrJsonNumber(
          value: comment.width,
          raw: comment.rawWidth,
          hasRaw: comment.hasRawWidth,
        ),
      if (comment.hasRawHeight || comment.height != null)
        'height': _rawOrJsonNumber(
          value: comment.height,
          raw: comment.rawHeight,
          hasRaw: comment.hasRawHeight,
        ),
      if (comment.hasRawValue || comment.value.isNotEmpty)
        'value': _rawOrString(
          value: comment.value,
          raw: comment.rawValue,
          hasRaw: comment.hasRawValue,
        ),
      if (comment.hasRawIsShow || comment.isShow)
        'isShow': _rawOrBoolFlag(
          value: comment.isShow,
          raw: comment.rawIsShow,
          hasRaw: comment.hasRawIsShow,
        ),
    };
  }

  static FortuneHyperlink? _cellHyperlink(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, Object?>.from(raw);
    return FortuneHyperlink(
      row: _int(map['r']),
      rawRow: cloneFortuneMetadata(map['r']),
      hasRawRow: map.containsKey('r'),
      column: _int(map['c']),
      rawColumn: cloneFortuneMetadata(map['c']),
      hasRawColumn: map.containsKey('c'),
      id: _string(map['id']),
      rawId: cloneFortuneMetadata(map['id']),
      hasRawId: map.containsKey('id'),
      linkType: _string(map['linkType']),
      rawLinkType: cloneFortuneMetadata(map['linkType']),
      hasRawLinkType: map.containsKey('linkType'),
      linkAddress: _string(map['linkAddress']),
      rawLinkAddress: cloneFortuneMetadata(map['linkAddress']),
      hasRawLinkAddress: map.containsKey('linkAddress'),
      extraFields: _unhandledFields(map, {
        'r',
        'c',
        'id',
        'linkType',
        'linkAddress',
      }),
    );
  }

  static Map<String, Object?> _cellHyperlinkToJson(FortuneHyperlink hyperlink) {
    return {
      for (final entry in hyperlink.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      if (hyperlink.hasRawRow || hyperlink.row != null)
        'r': _rawOrJsonNullableInt(
          value: hyperlink.row,
          raw: hyperlink.rawRow,
          hasRaw: hyperlink.hasRawRow,
        ),
      if (hyperlink.hasRawColumn || hyperlink.column != null)
        'c': _rawOrJsonNullableInt(
          value: hyperlink.column,
          raw: hyperlink.rawColumn,
          hasRaw: hyperlink.hasRawColumn,
        ),
      if (hyperlink.hasRawId || hyperlink.id != null)
        'id': _rawOrString(
          value: hyperlink.id,
          raw: hyperlink.rawId,
          hasRaw: hyperlink.hasRawId,
        ),
      if (hyperlink.hasRawLinkType || hyperlink.linkType != null)
        'linkType': _rawOrString(
          value: hyperlink.linkType,
          raw: hyperlink.rawLinkType,
          hasRaw: hyperlink.hasRawLinkType,
        ),
      if (hyperlink.hasRawLinkAddress || hyperlink.linkAddress != null)
        'linkAddress': _rawOrString(
          value: hyperlink.linkAddress,
          raw: hyperlink.rawLinkAddress,
          hasRaw: hyperlink.hasRawLinkAddress,
        ),
    };
  }

  static Map<String, Object?> _mergeToJson(FortuneCellMerge merge) {
    if (merge.preserveEmpty &&
        !merge.hasRawRow &&
        !merge.hasRawColumn &&
        !merge.hasRawRowSpan &&
        !merge.hasRawColumnSpan &&
        merge.row == 0 &&
        merge.column == 0 &&
        merge.rowSpan == 1 &&
        merge.columnSpan == 1 &&
        merge.extraFields.isEmpty) {
      return {};
    }
    return {
      for (final entry in merge.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'r': _rawOrJsonInt(
        value: merge.row,
        raw: merge.rawRow,
        hasRaw: merge.hasRawRow,
      ),
      'c': _rawOrJsonInt(
        value: merge.column,
        raw: merge.rawColumn,
        hasRaw: merge.hasRawColumn,
      ),
      if (merge.hasRawRowSpan || merge.rowSpan != 1)
        'rs': _rawOrJsonInt(
          value: merge.rowSpan,
          raw: merge.rawRowSpan,
          hasRaw: merge.hasRawRowSpan,
        ),
      if (merge.hasRawColumnSpan || merge.columnSpan != 1)
        'cs': _rawOrJsonInt(
          value: merge.columnSpan,
          raw: merge.rawColumnSpan,
          hasRaw: merge.hasRawColumnSpan,
        ),
    };
  }

  static Map<String, Object?> _cellTypeToJson(FortuneCell cell) {
    final type = cell.cellType;
    final json = <String, Object?>{
      for (final entry in type?.extraFields.entries ?? const Iterable.empty())
        entry.key: cloneFortuneMetadata(entry.value),
    };
    if (type != null && (type.hasRawFormat || type.format != null)) {
      final raw = cloneFortuneMetadata(type.rawFormat);
      json['fa'] = type.hasRawFormat && raw != null && '$raw' == type.format
          ? raw
          : type.format;
    }
    if (type != null && (type.hasRawType || type.type != null)) {
      final raw = cloneFortuneMetadata(type.rawType);
      json['t'] = type.hasRawType && raw != null && '$raw' == type.type
          ? raw
          : type.type;
    }
    if (type != null && (type.hasRawStyle || type.style != null)) {
      json['s'] = cloneFortuneMetadata(type.style);
    } else if (cell.inlineRuns != null) {
      json['s'] = [for (final run in cell.inlineRuns!) _inlineRunToJson(run)];
      json.putIfAbsent('t', () => 'inlineStr');
    }
    return json;
  }

  static Map<String, Object?> _inlineRunToJson(FortuneInlineTextRun run) {
    return {
      for (final entry in run.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      if (run.hasRawText || run.text.isNotEmpty || run.wrap != true)
        'v': _rawOrString(
          value: run.text,
          raw: run.rawText,
          hasRaw: run.hasRawText,
        ),
      if (run.foreground != null)
        'fc': _rawOrHexColor(
          color: run.foreground!,
          raw: run.rawForeground,
          hasRaw: run.hasRawForeground,
        )
      else if (run.hasRawForeground)
        'fc': cloneFortuneMetadata(run.rawForeground),
      if (run.hasRawBold || run.bold != null)
        'bl': _rawOrNullableNumericBoolFlag(
          value: run.bold,
          raw: run.rawBold,
          hasRaw: run.hasRawBold,
        ),
      if (run.hasRawItalic || run.italic != null)
        'it': _rawOrNullableNumericBoolFlag(
          value: run.italic,
          raw: run.rawItalic,
          hasRaw: run.hasRawItalic,
        ),
      if (run.hasRawStrikeThrough || run.strikeThrough != null)
        'cl': _rawOrNullableNumericBoolFlag(
          value: run.strikeThrough,
          raw: run.rawStrikeThrough,
          hasRaw: run.hasRawStrikeThrough,
        ),
      if (run.hasRawUnderline || run.underline != null)
        'un': _rawOrNullableNumericBoolFlag(
          value: run.underline,
          raw: run.rawUnderline,
          hasRaw: run.hasRawUnderline,
        ),
      if (run.hasRawFontSize || run.fontSize != null)
        'fs': _rawOrJsonNumber(
          value: run.fontSize,
          raw: run.rawFontSize,
          hasRaw: run.hasRawFontSize,
        ),
      if (run.hasRawFontFamily || run.fontFamily != null)
        'ff': _rawOrStyleValue(
          value: run.fontFamily,
          raw: run.rawFontFamily,
          hasRaw: run.hasRawFontFamily,
        ),
      if (run.hasRawWrap || run.wrap != null)
        'wrap': _rawOrNullableBoolFlag(
          value: run.wrap,
          raw: run.rawWrap,
          hasRaw: run.hasRawWrap,
        ),
    };
  }

  static Map<String, Object?> _unhandledCellFields(Map<String, Object?> json) {
    const handled = {
      'v',
      'm',
      'mc',
      'f',
      'ct',
      'qp',
      'spl',
      'bg',
      'lo',
      'rt',
      'ps',
      'hl',
      'bl',
      'it',
      'ff',
      'fs',
      'fc',
      'ht',
      'vt',
      'tb',
      'cl',
      'un',
      'tr',
    };
    return {
      for (final entry in json.entries)
        if (!handled.contains(entry.key))
          entry.key: cloneFortuneMetadata(entry.value),
    };
  }

  static List<FortuneBorderInfo> _borderInfo(Object? raw) {
    if (raw is! List) {
      return [];
    }
    final items = <FortuneBorderInfo>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, Object?>.from(item);
      final ranges = _ranges(map['range']);
      if (ranges.isEmpty) {
        continue;
      }
      items.add(
        FortuneBorderInfo(
          rangeType: _string(map['rangeType']) ?? 'range',
          borderType: _string(map['borderType']) ?? '',
          color: parseColor(_string(map['color'])) ?? const Color(0xff000000),
          style: _int(map['style']) ?? 1,
          strokeWidth: _double(map['strokeWidth']),
          ranges: ranges,
          rawColor: cloneFortuneMetadata(map['color']),
          hasRawColor: map.containsKey('color'),
          extraFields: _unhandledFields(map, {
            'rangeType',
            'borderType',
            'color',
            'style',
            'strokeWidth',
            'range',
          }),
        ),
      );
    }
    return items;
  }

  static Map<String, Object?> _borderInfoToJson(FortuneBorderInfo border) {
    return {
      for (final entry in border.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'rangeType': border.rangeType,
      'borderType': border.borderType,
      'color': _rawOrHexColor(
        color: border.color,
        raw: border.rawColor,
        hasRaw: border.hasRawColor,
      ),
      'style': border.style,
      if (border.strokeWidth != null) 'strokeWidth': border.strokeWidth,
      'range': [for (final range in border.ranges) _rangeToJson(range)],
    };
  }

  static Object? _rawOrBorderInfoToJson({
    required List<FortuneBorderInfo> values,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw &&
        raw is List &&
        _borderInfoListEquals(_borderInfo(raw), values)) {
      return cloneFortuneMetadata(raw);
    }
    return [for (final border in values) _borderInfoToJson(border)];
  }

  static bool _borderInfoListEquals(
    List<FortuneBorderInfo> left,
    List<FortuneBorderInfo> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i += 1) {
      if (!_borderInfoEquals(left[i], right[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _borderInfoEquals(
    FortuneBorderInfo left,
    FortuneBorderInfo right,
  ) {
    if (left.rangeType != right.rangeType ||
        left.borderType != right.borderType ||
        left.color != right.color ||
        left.style != right.style ||
        left.strokeWidth != right.strokeWidth ||
        !_metadataEquals(left.rawColor, right.rawColor) ||
        left.hasRawColor != right.hasRawColor ||
        !_metadataEquals(left.extraFields, right.extraFields) ||
        left.ranges.length != right.ranges.length) {
      return false;
    }
    for (var i = 0; i < left.ranges.length; i += 1) {
      if (!_rangeEquals(left.ranges[i], right.ranges[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _rangeEquals(FortuneRange left, FortuneRange right) {
    return left.rowStart == right.rowStart &&
        left.rowEnd == right.rowEnd &&
        left.columnStart == right.columnStart &&
        left.columnEnd == right.columnEnd &&
        left.rowFocus == right.rowFocus &&
        left.columnFocus == right.columnFocus &&
        left.hasRawRow == right.hasRawRow &&
        left.hasRawColumn == right.hasRawColumn &&
        left.hasRawRowFocus == right.hasRawRowFocus &&
        left.hasRawColumnFocus == right.hasRawColumnFocus &&
        _metadataEquals(left.rawRow, right.rawRow) &&
        _metadataEquals(left.rawColumn, right.rawColumn) &&
        _metadataEquals(left.rawRowFocus, right.rawRowFocus) &&
        _metadataEquals(left.rawColumnFocus, right.rawColumnFocus) &&
        _metadataEquals(left.extraFields, right.extraFields);
  }

  static List<FortuneRange> _ranges(Object? raw) {
    if (raw is! List) {
      return [];
    }
    final ranges = <FortuneRange>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, Object?>.from(item);
      final row = map['row'];
      final column = map['column'];
      if (row is! List ||
          column is! List ||
          row.length < 2 ||
          column.length < 2) {
        continue;
      }
      final rowStart = _int(row[0]);
      final rowEnd = _int(row[1]);
      final columnStart = _int(column[0]);
      final columnEnd = _int(column[1]);
      if (rowStart == null ||
          rowEnd == null ||
          columnStart == null ||
          columnEnd == null) {
        continue;
      }
      ranges.add(
        FortuneRange(
          rowStart: rowStart,
          rowEnd: rowEnd,
          rawRow: cloneFortuneMetadata(row),
          hasRawRow: map.containsKey('row'),
          columnStart: columnStart,
          columnEnd: columnEnd,
          rawColumn: cloneFortuneMetadata(column),
          hasRawColumn: map.containsKey('column'),
          rowFocus: _int(map['row_focus']),
          rawRowFocus: cloneFortuneMetadata(map['row_focus']),
          hasRawRowFocus: map.containsKey('row_focus'),
          columnFocus: _int(map['column_focus']),
          rawColumnFocus: cloneFortuneMetadata(map['column_focus']),
          hasRawColumnFocus: map.containsKey('column_focus'),
          extraFields: _unhandledFields(map, {
            'row',
            'column',
            'row_focus',
            'column_focus',
          }),
        ),
      );
    }
    return ranges;
  }

  static Map<String, Object?> _rangeToJson(FortuneRange range) {
    return {
      for (final entry in range.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'row': _rawOrRangePair(
        start: range.rowStart,
        end: range.rowEnd,
        raw: range.rawRow,
        hasRaw: range.hasRawRow,
      ),
      'column': _rawOrRangePair(
        start: range.columnStart,
        end: range.columnEnd,
        raw: range.rawColumn,
        hasRaw: range.hasRawColumn,
      ),
      if (range.hasRawRowFocus || range.rowFocus != null)
        'row_focus': _rawOrJsonNullableInt(
          value: range.rowFocus,
          raw: range.rawRowFocus,
          hasRaw: range.hasRawRowFocus,
        ),
      if (range.hasRawColumnFocus || range.columnFocus != null)
        'column_focus': _rawOrJsonNullableInt(
          value: range.columnFocus,
          raw: range.rawColumnFocus,
          hasRaw: range.hasRawColumnFocus,
        ),
    };
  }

  static List<FortuneInlineTextRun>? _inlineRuns(Object? raw) {
    if (raw is! List) {
      return null;
    }
    final runs = <FortuneInlineTextRun>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, Object?>.from(item);
      final hasRawText = map.containsKey('v');
      final hasRawWrap = map.containsKey('wrap');
      final text = _optionalCellValue(map['v']) ?? '';
      if (text.isEmpty && !hasRawText && !hasRawWrap) {
        continue;
      }
      runs.add(
        FortuneInlineTextRun(
          text: text
              .replaceAll('\r\n', '\n')
              .replaceAll('&#13;&#10;', '\n')
              .replaceAll('\r', '\n'),
          rawText: cloneFortuneMetadata(map['v']),
          hasRawText: hasRawText,
          foreground: parseColor(_string(map['fc'])),
          rawForeground: cloneFortuneMetadata(map['fc']),
          hasRawForeground: map.containsKey('fc'),
          bold: _nullableBoolFlag(map['bl']),
          rawBold: cloneFortuneMetadata(map['bl']),
          hasRawBold: map.containsKey('bl'),
          italic: _nullableBoolFlag(map['it']),
          rawItalic: cloneFortuneMetadata(map['it']),
          hasRawItalic: map.containsKey('it'),
          strikeThrough: _nullableBoolFlag(map['cl']),
          rawStrikeThrough: cloneFortuneMetadata(map['cl']),
          hasRawStrikeThrough: map.containsKey('cl'),
          underline: _nullableBoolFlag(map['un']),
          rawUnderline: cloneFortuneMetadata(map['un']),
          hasRawUnderline: map.containsKey('un'),
          fontSize: _double(map['fs']),
          rawFontSize: cloneFortuneMetadata(map['fs']),
          hasRawFontSize: map.containsKey('fs'),
          fontFamily: _string(map['ff']),
          rawFontFamily: cloneFortuneMetadata(map['ff']),
          hasRawFontFamily: map.containsKey('ff'),
          wrap: _nullableBoolFlag(map['wrap']),
          rawWrap: cloneFortuneMetadata(map['wrap']),
          hasRawWrap: hasRawWrap,
          extraFields: _unhandledFields(map, {
            'v',
            'fc',
            'bl',
            'it',
            'cl',
            'un',
            'fs',
            'ff',
            'wrap',
          }),
        ),
      );
    }
    return runs.isEmpty ? null : runs;
  }

  static Color? parseColor(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value.trim();
    final shortHex = RegExp(r'^#([0-9a-fA-F]{3})$');
    final shortHexMatch = shortHex.firstMatch(normalized);
    if (shortHexMatch != null) {
      final body = shortHexMatch.group(1)!;
      final expanded = body.split('').map((digit) => '$digit$digit').join();
      return Color(int.parse('ff$expanded', radix: 16));
    }
    final hex = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    final hexMatch = hex.firstMatch(normalized);
    if (hexMatch != null) {
      final body = hexMatch.group(1)!;
      if (body.length == 6) {
        return Color(int.parse('ff$body', radix: 16));
      }
      return Color(int.parse(body, radix: 16));
    }
    final rgb = RegExp(
      r'^rgba?\(\s*(\d+),\s*(\d+),\s*(\d+)(?:,\s*([0-9.]+))?\s*\)$',
      caseSensitive: false,
    );
    final rgbMatch = rgb.firstMatch(normalized);
    if (rgbMatch != null) {
      final r = int.parse(rgbMatch.group(1)!).clamp(0, 255);
      final g = int.parse(rgbMatch.group(2)!).clamp(0, 255);
      final b = int.parse(rgbMatch.group(3)!).clamp(0, 255);
      final alpha = rgbMatch.group(4) == null
          ? 255
          : ((double.tryParse(rgbMatch.group(4)!) ?? 1).clamp(0, 1) * 255)
                .round();
      return Color.fromARGB(alpha, r, g, b);
    }
    return null;
  }

  static String colorToHex(Color color) {
    final alpha = _colorChannel(color.a);
    final rgb =
        '${_colorChannel(color.r).toRadixString(16).padLeft(2, '0')}'
        '${_colorChannel(color.g).toRadixString(16).padLeft(2, '0')}'
        '${_colorChannel(color.b).toRadixString(16).padLeft(2, '0')}';
    if (alpha == 255) {
      return '#$rgb';
    }
    return '#${alpha.toRadixString(16).padLeft(2, '0')}$rgb';
  }

  static Object? _rawOrHexColor({
    required Color color,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      final rawColor = parseColor(_string(raw));
      if (rawColor == color) {
        return cloneFortuneMetadata(raw);
      }
    }
    return colorToHex(color);
  }

  static Object? _rawOrJsonNumber({
    required double? value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawNumber = _double(raw);
      if (rawNumber != null && rawNumber == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value == null ? null : _jsonNumber(value);
  }

  static Object? _rawOrJsonInt({
    required int value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawInt = _int(raw);
      if (rawInt == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value;
  }

  static Object? _rawOrJsonNullableInt({
    required int? value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawInt = _int(raw);
      if (rawInt != null && rawInt == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value;
  }

  static Object? _rawOrRangePair({
    required int start,
    required int end,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      if (raw is List && raw.length >= 2) {
        final rawStart = _int(raw[0]);
        final rawEnd = _int(raw[1]);
        if (rawStart == start && rawEnd == end) {
          return cloneFortuneMetadata(raw);
        }
      }
    }
    return [start, end];
  }

  static Object? _rawOrBoolFlag({
    required bool value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawFlag = _nullableBoolFlag(raw);
      if (rawFlag == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value;
  }

  static Object? _rawOrNullableBoolFlag({
    required bool? value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawFlag = _nullableBoolFlag(raw);
      if (rawFlag == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value;
  }

  static Object? _rawOrNumericBoolFlag({
    required bool value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawFlag = _nullableBoolFlag(raw);
      if (rawFlag == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value ? 1 : 0;
  }

  static Object? _rawOrNullableNumericBoolFlag({
    required bool? value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      final rawFlag = _nullableBoolFlag(raw);
      if (rawFlag == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value == null
        ? null
        : value
        ? 1
        : 0;
  }

  static int _colorChannel(double value) {
    return (value * 255).round().clamp(0, 255).toInt();
  }

  static List<FortuneImage> _images(Object? raw) {
    if (raw is! List) {
      return [];
    }
    final images = <FortuneImage>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, Object?>.from(item);
      final id = _string(map['id']);
      final src = _string(map['src']);
      final left = _double(map['left']);
      final top = _double(map['top']);
      final width = _double(map['width']);
      final height = _double(map['height']);
      if (id == null ||
          src == null ||
          left == null ||
          top == null ||
          width == null ||
          height == null) {
        continue;
      }
      images.add(
        FortuneImage(
          id: id,
          src: src,
          left: left,
          rawLeft: cloneFortuneMetadata(map['left']),
          hasRawLeft: map.containsKey('left'),
          top: top,
          rawTop: cloneFortuneMetadata(map['top']),
          hasRawTop: map.containsKey('top'),
          width: width,
          rawWidth: cloneFortuneMetadata(map['width']),
          hasRawWidth: map.containsKey('width'),
          height: height,
          rawHeight: cloneFortuneMetadata(map['height']),
          hasRawHeight: map.containsKey('height'),
          extraFields: _unhandledFields(map, {
            'id',
            'src',
            'left',
            'top',
            'width',
            'height',
          }),
        ),
      );
    }
    return images;
  }

  static Map<String, Object?> _imageToJson(FortuneImage image) {
    return {
      for (final entry in image.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'id': image.id,
      'src': image.src,
      'left': _rawOrJsonNumber(
        value: image.left,
        raw: image.rawLeft,
        hasRaw: image.hasRawLeft,
      ),
      'top': _rawOrJsonNumber(
        value: image.top,
        raw: image.rawTop,
        hasRaw: image.hasRawTop,
      ),
      'width': _rawOrJsonNumber(
        value: image.width,
        raw: image.rawWidth,
        hasRaw: image.hasRawWidth,
      ),
      'height': _rawOrJsonNumber(
        value: image.height,
        raw: image.rawHeight,
        hasRaw: image.hasRawHeight,
      ),
    };
  }

  static Object? _rawOrImagesToJson({
    required List<FortuneImage> values,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw && raw is List && _imageListEquals(_images(raw), values)) {
      return cloneFortuneMetadata(raw);
    }
    return [for (final image in values) _imageToJson(image)];
  }

  static bool _imageListEquals(
    List<FortuneImage> left,
    List<FortuneImage> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i += 1) {
      if (!_imageEquals(left[i], right[i])) {
        return false;
      }
    }
    return true;
  }

  static bool _imageEquals(FortuneImage left, FortuneImage right) {
    return left.id == right.id &&
        left.src == right.src &&
        left.left == right.left &&
        left.top == right.top &&
        left.width == right.width &&
        left.height == right.height &&
        left.hasRawLeft == right.hasRawLeft &&
        left.hasRawTop == right.hasRawTop &&
        left.hasRawWidth == right.hasRawWidth &&
        left.hasRawHeight == right.hasRawHeight &&
        _metadataEquals(left.rawLeft, right.rawLeft) &&
        _metadataEquals(left.rawTop, right.rawTop) &&
        _metadataEquals(left.rawWidth, right.rawWidth) &&
        _metadataEquals(left.rawHeight, right.rawHeight) &&
        _metadataEquals(left.extraFields, right.extraFields);
  }

  static FortuneFrozenPane? _frozen(Object? raw) {
    final map = _map(raw);
    final type = _string(map['type']);
    if (type == null || type.isEmpty) {
      return null;
    }
    final range = _map(map['range']);
    return FortuneFrozenPane(
      type: type,
      rowFocus: _int(range['row_focus']),
      rawRowFocus: cloneFortuneMetadata(range['row_focus']),
      hasRawRowFocus: range.containsKey('row_focus'),
      columnFocus: _int(range['column_focus']),
      rawColumnFocus: cloneFortuneMetadata(range['column_focus']),
      hasRawColumnFocus: range.containsKey('column_focus'),
      extraFields: _unhandledFields(map, {'type', 'range'}),
      rangeExtraFields: _unhandledFields(range, {'row_focus', 'column_focus'}),
    );
  }

  static Map<String, Object?> _frozenToJson(FortuneFrozenPane frozen) {
    return {
      for (final entry in frozen.extraFields.entries)
        entry.key: cloneFortuneMetadata(entry.value),
      'type': frozen.type,
      if (frozen.hasRawRowFocus ||
          frozen.rowFocus != null ||
          frozen.hasRawColumnFocus ||
          frozen.columnFocus != null ||
          frozen.rangeExtraFields.isNotEmpty)
        'range': {
          for (final entry in frozen.rangeExtraFields.entries)
            entry.key: cloneFortuneMetadata(entry.value),
          if (frozen.hasRawRowFocus || frozen.rowFocus != null)
            'row_focus': _rawOrJsonNullableInt(
              value: frozen.rowFocus,
              raw: frozen.rawRowFocus,
              hasRaw: frozen.hasRawRowFocus,
            ),
          if (frozen.hasRawColumnFocus || frozen.columnFocus != null)
            'column_focus': _rawOrJsonNullableInt(
              value: frozen.columnFocus,
              raw: frozen.rawColumnFocus,
              hasRaw: frozen.hasRawColumnFocus,
            ),
        },
    };
  }

  static Object? _rawOrFrozenToJson({
    required FortuneFrozenPane value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      final rawFrozen = _frozen(raw);
      if (rawFrozen != null && _frozenEquals(rawFrozen, value)) {
        return cloneFortuneMetadata(raw);
      }
    }
    return _frozenToJson(value);
  }

  static bool _frozenEquals(FortuneFrozenPane left, FortuneFrozenPane right) {
    return left.type == right.type &&
        left.rowFocus == right.rowFocus &&
        left.columnFocus == right.columnFocus &&
        left.hasRawRowFocus == right.hasRawRowFocus &&
        left.hasRawColumnFocus == right.hasRawColumnFocus &&
        _metadataEquals(left.rawRowFocus, right.rawRowFocus) &&
        _metadataEquals(left.rawColumnFocus, right.rawColumnFocus) &&
        _metadataEquals(left.extraFields, right.extraFields) &&
        _metadataEquals(left.rangeExtraFields, right.rangeExtraFields);
  }

  static Map<String, Object?> _mergeConfigToJson(
    Map<FortuneCellCoord, FortuneCell> cells,
  ) {
    final result = <String, Object?>{};
    final entries = cells.entries.toList()
      ..sort((a, b) {
        final rowCompare = a.key.row.compareTo(b.key.row);
        return rowCompare == 0
            ? a.key.column.compareTo(b.key.column)
            : rowCompare;
      });
    for (final entry in entries) {
      final merge = entry.value.merge;
      if (merge == null ||
          merge.row != entry.key.row ||
          merge.column != entry.key.column ||
          (merge.rowSpan <= 1 &&
              merge.columnSpan <= 1 &&
              !merge.hasRawRowSpan &&
              !merge.hasRawColumnSpan)) {
        continue;
      }
      result['${entry.key.row}_${entry.key.column}'] = _mergeToJson(merge);
    }
    return result;
  }

  static Object? _rawOrMergeConfigToJson({
    required Map<String, Object?> values,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw && raw is Map) {
      final rawCells = <FortuneCellCoord, FortuneCell>{};
      _applyConfigMerge(raw, rawCells);
      if (_metadataEquals(_mergeConfigToJson(rawCells), values)) {
        return cloneFortuneMetadata(raw);
      }
    }
    return values;
  }

  static Map<String, Object?> _intDoubleMapToJson(Map<int, double> values) {
    return {
      for (final entry in _sortedIntDoubleEntries(values))
        '${entry.key}': _jsonNumber(entry.value),
    };
  }

  static Object? _rawOrIntDoubleMapToJson({
    required Map<int, double> values,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw && raw is Map && _mapsEqual(_numberMap(raw), values)) {
      return cloneFortuneMetadata(raw);
    }
    return _intDoubleMapToJson(values);
  }

  static bool _mapsEqual(Map<int, double> left, Map<int, double> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static bool _objectMapsEqual(
    Map<int, Object?> left,
    Map<int, Object?> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static bool _setsEqual(Set<int> left, Set<int> right) {
    if (left.length != right.length) {
      return false;
    }
    return left.containsAll(right);
  }

  static bool _metadataEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key) ||
            !_metadataEquals(entry.value, right[entry.key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var i = 0; i < left.length; i += 1) {
        if (!_metadataEquals(left[i], right[i])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }

  static List<MapEntry<int, double>> _sortedIntDoubleEntries(
    Map<int, double> values,
  ) {
    return values.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  static Map<String, Object?> _intObjectMapToJson(
    Map<int, Object?> values,
    Set<int> keys,
  ) {
    final sorted = keys.toList()..sort();
    return {
      for (final key in sorted)
        '$key': cloneFortuneMetadata(values.containsKey(key) ? values[key] : 0),
    };
  }

  static Object? _rawOrIntObjectMapToJson({
    required Map<int, Object?> values,
    required Set<int> keys,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw && raw is Map) {
      final rawValues = _intObjectMap(raw);
      final rawKeys = rawValues.keys.toSet();
      if (_setsEqual(rawKeys, keys) && _objectMapsEqual(rawValues, values)) {
        return cloneFortuneMetadata(raw);
      }
    }
    return _intObjectMapToJson(values, keys);
  }

  static Map<String, Object?> _stringObjectMapToJson(
    Map<String, Object?> values,
  ) {
    return {
      for (final entry in values.entries)
        entry.key: cloneFortuneMetadata(entry.value),
    };
  }

  static Map<String, Object?> _map(Object? raw) {
    return raw is Map ? Map<String, Object?>.from(raw) : {};
  }

  static Map<String, Object?> _objectMap(Object? raw) {
    return raw is Map ? Map<String, Object?>.from(raw) : {};
  }

  static Map<int, double> _numberMap(Object? raw) {
    if (raw is! Map) {
      return {};
    }
    final result = <int, double>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      final value = _double(entry.value);
      if (key != null && value != null && value > 0) {
        result[key] = value;
      }
    }
    return result;
  }

  static Map<int, Object?> _intObjectMap(Object? raw) {
    if (raw is! Map) {
      return {};
    }
    final result = <int, Object?>{};
    for (final entry in raw.entries) {
      final key = int.tryParse('${entry.key}');
      if (key != null) {
        result[key] = cloneFortuneMetadata(entry.value);
      }
    }
    return result;
  }

  static String _cellValue(Object? value) => _optionalCellValue(value) ?? '';

  static String? _optionalCellValue(Object? value) {
    return value == null ? null : '$value';
  }

  static String? _string(Object? value) => value == null ? null : '$value';

  static List<String>? _stringList(Object? value) {
    if (value is! List) {
      return null;
    }
    return [for (final item in value) '$item'];
  }

  static List<FortuneCustomToolbarItem>? _customToolbarItems(Object? value) {
    if (value is! List) {
      return null;
    }
    final items = <FortuneCustomToolbarItem>[];
    for (final item in value.whereType<Map>()) {
      final map = Map<String, Object?>.from(item);
      final key = _string(map['key']);
      if (key == null || key.isEmpty) {
        continue;
      }
      items.add(
        FortuneCustomToolbarItem(
          key: key,
          tooltip: _string(map['tooltip']),
          children: cloneFortuneMetadata(map['children']),
          iconName: _string(map['iconName']),
          icon: cloneFortuneMetadata(map['icon']),
          disabled: _bool(map['disabled']) ?? false,
        ),
      );
    }
    return items;
  }

  static bool _stringListsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  static int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }

  static double? _double(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value');
  }

  static bool? _bool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = '$value'.trim().toLowerCase();
    return switch (normalized) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }

  static num _jsonNumber(num value) {
    return value % 1 == 0 ? value.toInt() : value;
  }

  static Object _numericStyleValue(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && '$parsed' == value ? parsed : value;
  }

  static Object? _rawOrStyleValue({
    required String? value,
    required Object? raw,
    required bool hasRaw,
    bool numericDefault = true,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      if ('$raw' == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    if (value == null) {
      return null;
    }
    return numericDefault ? _numericStyleValue(value) : value;
  }

  static bool _boolFlag(Object? value, {bool defaultValue = false}) {
    return _nullableBoolFlag(value) ?? defaultValue;
  }

  static bool? _nullableBoolFlag(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final string = '$value';
    if (string == '0' || string.toLowerCase() == 'false') {
      return false;
    }
    if (string == '1' || string.toLowerCase() == 'true') {
      return true;
    }
    return null;
  }

  static Object? _rawOrString({
    required String? value,
    required Object? raw,
    required bool hasRaw,
  }) {
    if (hasRaw) {
      if (raw == null) {
        return null;
      }
      if ('$raw' == value) {
        return cloneFortuneMetadata(raw);
      }
    }
    return value;
  }
}
