import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:label_manager/features/scale_output/data/db_scale_connect_info.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/domain/label_print_auto_increment.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/core/table_search.dart';
import 'package:label_manager/printing/label_print_pipeline.dart';
import 'package:serial_port_win32/serial_port_win32.dart';
import 'package:win32/win32.dart';

const int scaleOutputItemNameColumnId = -1;
const int scaleOutputElementColumnId = -2;
const int scaleOutputWeightColumnId = -3;
const int scaleOutputPriceColumnId = -4;

const Object _scaleOutputUnchanged = Object();

int? scaleOutputSpecialColumnIdForKeyword(String keyword) {
  switch (keyword.trim().toUpperCase()) {
    case 'ITEMNAME':
      return scaleOutputItemNameColumnId;
    case 'ELEMENT':
      return scaleOutputElementColumnId;
    case 'SWEIGHT':
      return scaleOutputWeightColumnId;
    case 'SPRICE':
      return scaleOutputPriceColumnId;
    default:
      return null;
  }
}

int? scaleOutputColumnIdForKeyword(Iterable<TColumn> columns, String keyword) {
  final normalized = keyword.trim().toUpperCase();
  return columns
      .firstWhereOrNull((column) => column.keyword.trim().toUpperCase() == normalized)
      ?.columnId;
}

const List<int> scaleOutputSupportedBaudRates = <int>[
  110,
  300,
  600,
  1200,
  2400,
  4800,
  9600,
  14400,
  19200,
  38400,
  56000,
  57600,
  115200,
  128000,
  256000,
];

bool scaleOutputIsSupportedBaudRate(int value) {
  return scaleOutputSupportedBaudRates.contains(value);
}

bool scaleOutputIsSupportedDataBit(int value) {
  return value >= 4 && value <= 8;
}

bool scaleOutputIsSupportedStopBit(double value) {
  return value == 1 || value == 1.5 || value == 2;
}

class ScaleOutputIncomingReading {
  const ScaleOutputIncomingReading({
    required this.state,
    required this.weight,
  });

  final String state;
  final String weight;
}

ScaleOutputIncomingReading? scaleOutputParseIncomingReading(String raw) {
  final match = RegExp(
    r'^\s*([A-Za-z]{2})\b.*?([+-]?\s*\d+(?:\.\d+)?)\s*(kg|g)\b',
    caseSensitive: false,
  ).firstMatch(raw);
  if (match == null) return null;
  return ScaleOutputIncomingReading(
    state: match.group(1)!.toUpperCase(),
    weight: '${match.group(2)!.replaceAll(' ', '')}${match.group(3)!}',
  );
}

bool scaleOutputIsStablePositiveReading(ScaleOutputIncomingReading reading) {
  if (reading.state != 'ST') return false;
  final value = double.tryParse(scaleOutputNormalizedWeightText(reading.weight));
  return value != null && value > 0;
}

String scaleOutputNormalizedWeightText(String raw) {
  final compact = raw.replaceAll(' ', '').trim();
  if (compact.isEmpty) return '';
  final lower = compact.toLowerCase();
  final kgIndex = lower.indexOf('kg');
  if (kgIndex >= 0) {
    return compact.substring(0, kgIndex).trim();
  }
  final gIndex = lower.indexOf('g');
  if (gIndex >= 0) {
    return compact.substring(0, gIndex).trim();
  }
  return compact;
}

String scaleOutputNormalizedPriceText(String raw) {
  return raw.replaceAll(RegExp(r'[^0-9]'), '');
}

bool scaleOutputBlocksMultiIssue({
  required bool useScale,
  required int rowCount,
}) {
  return useScale && rowCount > 1;
}

bool scaleOutputNeedsIssueConfirmation({
  required bool useScale,
  required bool isConnected,
  required String weightText,
}) {
  return useScale && (!isConnected || weightText.trim().isEmpty);
}

Set<int> scaleOutputVisibleItemIds({
  required bool showAllRows,
  required Iterable<ItemOfMarket> baselineItems,
  required Set<int> checkedItemIds,
}) {
  if (!showAllRows) return checkedItemIds;
  return <int>{for (final item in baselineItems) item.item.itemId};
}

String? scaleOutputComputePriceText({
  required String rawWeightText,
  required String priceBaseText,
}) {
  final weightText = rawWeightText.replaceAll(' ', '').trim();
  final lower = weightText.toLowerCase();
  final priceBase = double.tryParse(priceBaseText.trim());
  if (weightText.isEmpty || priceBase == null || !priceBase.isFinite) {
    return null;
  }
  double? price;
  if (lower.contains('kg')) {
    final endIndex = lower.indexOf('kg');
    final weight = double.tryParse(weightText.substring(0, endIndex));
    if (weight != null && weight.isFinite) {
      price = (weight * 10) * priceBase;
    }
  } else if (lower.contains('g')) {
    final endIndex = lower.indexOf('g');
    final weight = double.tryParse(weightText.substring(0, endIndex));
    if (weight != null && weight.isFinite) {
      price = (weight / 100) * priceBase;
    }
  }
  if (price == null) return null;
  final rounded = ((price / 10) + 0.5).floor() * 10;
  if (rounded == 0) return '';
  return rounded.toString();
}

Map<int, String> scaleOutputProjectedSpecialValues({
  required ItemOfMarket item,
  required String weightText,
  required String priceText,
}) => <int, String>{
  scaleOutputItemNameColumnId: item.item.itemName,
  scaleOutputElementColumnId: item.item.element,
  scaleOutputWeightColumnId: weightText,
  scaleOutputPriceColumnId: priceText,
};

enum ScaleOutputConnectionState { disconnected, connecting, connected, error }

@immutable
class ScaleOutputRowDraft {
  const ScaleOutputRowDraft({
    required this.item,
    required this.copies,
    required this.widthMm,
    required this.heightMm,
    required this.leftMarginMm,
    required this.rightMarginMm,
    required this.topMarginMm,
    required this.leftPushMm,
    required this.topPushMm,
    required this.lineSpacingPercent,
    required this.defaultWeightText,
    required this.priceBaseText,
    required this.weightText,
    required this.priceText,
    required this.copiesSource,
    required this.widthSource,
    required this.heightSource,
    required this.leftMarginSource,
    required this.rightMarginSource,
    required this.topMarginSource,
    required this.leftPushSource,
    required this.topPushSource,
    required this.lineSpacingSource,
  });

  factory ScaleOutputRowDraft.fromBaseline({
    required ItemOfMarket item,
    required LabelSize labelSize,
    required int copies,
    required LabelPrintSettingsSnapshot settings,
    required String defaultWeightText,
    required String priceBaseText,
  }) {
    final common = labelSize.labelSizeCommon;
    final usesItemSize = item.useLabelSize;
    final usesItemMargins = item.useMargin;
    final usesItemLineSpacing = item.useLinefeed;
    final initialPrice = scaleOutputComputePriceText(
      rawWeightText: defaultWeightText,
      priceBaseText: priceBaseText,
    );
    return ScaleOutputRowDraft(
      item: item,
      copies: copies,
      widthMm: usesItemSize ? item.labelSizeWidth : common?.width ?? 0,
      heightMm: usesItemSize ? item.labelSizeHeight : common?.height ?? 0,
      leftMarginMm: usesItemMargins ? item.leftMargin : settings.leftMarginMm,
      rightMarginMm: usesItemMargins ? item.rightMargin : settings.rightMarginMm,
      topMarginMm: usesItemMargins ? item.topMargin : settings.topMarginMm,
      leftPushMm: usesItemMargins ? item.leftPush : settings.leftPushMm,
      topPushMm: usesItemMargins ? item.topPush : settings.topPushMm,
      lineSpacingPercent: usesItemLineSpacing
          ? (item.linefeed == 0 ? null : item.linefeed)
          : settings.lineSpacingPercent,
      defaultWeightText: defaultWeightText,
      priceBaseText: priceBaseText,
      weightText: scaleOutputNormalizedWeightText(defaultWeightText),
      priceText: initialPrice ?? '',
      copiesSource: LabelPrintValueSource.itemBaseline,
      widthSource: usesItemSize
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.labelSizeFallback,
      heightSource: usesItemSize
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.labelSizeFallback,
      leftMarginSource: usesItemMargins
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
      rightMarginSource: usesItemMargins
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
      topMarginSource: usesItemMargins
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
      leftPushSource: usesItemMargins
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
      topPushSource: usesItemMargins
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
      lineSpacingSource: usesItemLineSpacing
          ? LabelPrintValueSource.itemOverride
          : LabelPrintValueSource.preferenceFallback,
    );
  }

  int get itemId => item.item.itemId;

  final ItemOfMarket item;
  final int copies;
  final int widthMm;
  final int heightMm;
  final double leftMarginMm;
  final double rightMarginMm;
  final double topMarginMm;
  final double leftPushMm;
  final double topPushMm;
  final int? lineSpacingPercent;
  final String defaultWeightText;
  final String priceBaseText;
  final String weightText;
  final String priceText;
  final LabelPrintValueSource copiesSource;
  final LabelPrintValueSource widthSource;
  final LabelPrintValueSource heightSource;
  final LabelPrintValueSource leftMarginSource;
  final LabelPrintValueSource rightMarginSource;
  final LabelPrintValueSource topMarginSource;
  final LabelPrintValueSource leftPushSource;
  final LabelPrintValueSource topPushSource;
  final LabelPrintValueSource lineSpacingSource;

  ScaleOutputRowDraft copyWith({
    int? copies,
    int? widthMm,
    int? heightMm,
    double? leftMarginMm,
    double? rightMarginMm,
    double? topMarginMm,
    double? leftPushMm,
    double? topPushMm,
    Object? lineSpacingPercent = _scaleOutputUnchanged,
    String? defaultWeightText,
    String? priceBaseText,
    String? weightText,
    String? priceText,
    LabelPrintValueSource? copiesSource,
    LabelPrintValueSource? widthSource,
    LabelPrintValueSource? heightSource,
    LabelPrintValueSource? leftMarginSource,
    LabelPrintValueSource? rightMarginSource,
    LabelPrintValueSource? topMarginSource,
    LabelPrintValueSource? leftPushSource,
    LabelPrintValueSource? topPushSource,
    LabelPrintValueSource? lineSpacingSource,
  }) => ScaleOutputRowDraft(
    item: item,
    copies: copies ?? this.copies,
    widthMm: widthMm ?? this.widthMm,
    heightMm: heightMm ?? this.heightMm,
    leftMarginMm: leftMarginMm ?? this.leftMarginMm,
    rightMarginMm: rightMarginMm ?? this.rightMarginMm,
    topMarginMm: topMarginMm ?? this.topMarginMm,
    leftPushMm: leftPushMm ?? this.leftPushMm,
    topPushMm: topPushMm ?? this.topPushMm,
    lineSpacingPercent: identical(lineSpacingPercent, _scaleOutputUnchanged)
        ? this.lineSpacingPercent
        : lineSpacingPercent as int?,
    defaultWeightText: defaultWeightText ?? this.defaultWeightText,
    priceBaseText: priceBaseText ?? this.priceBaseText,
    weightText: weightText ?? this.weightText,
    priceText: priceText ?? this.priceText,
    copiesSource: copiesSource ?? this.copiesSource,
    widthSource: widthSource ?? this.widthSource,
    heightSource: heightSource ?? this.heightSource,
    leftMarginSource: leftMarginSource ?? this.leftMarginSource,
    rightMarginSource: rightMarginSource ?? this.rightMarginSource,
    topMarginSource: topMarginSource ?? this.topMarginSource,
    leftPushSource: leftPushSource ?? this.leftPushSource,
    topPushSource: topPushSource ?? this.topPushSource,
    lineSpacingSource: lineSpacingSource ?? this.lineSpacingSource,
  );

  LabelPrintRowDraft toLabelPrintRowDraft() => LabelPrintRowDraft(
    item: item,
    copies: copies,
    widthMm: widthMm,
    heightMm: heightMm,
    leftMarginMm: leftMarginMm,
    rightMarginMm: rightMarginMm,
    topMarginMm: topMarginMm,
    leftPushMm: leftPushMm,
    topPushMm: topPushMm,
    lineSpacingPercent: lineSpacingPercent,
    copiesSource: copiesSource,
    widthSource: widthSource,
    heightSource: heightSource,
    leftMarginSource: leftMarginSource,
    rightMarginSource: rightMarginSource,
    topMarginSource: topMarginSource,
    leftPushSource: leftPushSource,
    topPushSource: topPushSource,
    lineSpacingSource: lineSpacingSource,
  );
}

class ScaleOutputPageController {
  Object? _owner;
  TableSearchResult Function(String query)? _search;
  VoidCallback? _resetSearch;
  Future<void> Function()? _commitEditing;
  bool Function()? _hasActiveEditing;

  bool get hasActiveEditing => _hasActiveEditing?.call() ?? false;

  TableSearchResult search(String query) =>
      _search?.call(query) ?? TableSearchResult.unavailable;

  void resetSearch() => _resetSearch?.call();

  Future<void> commitEditing() async {
    await _commitEditing?.call();
  }

  void attach({
    required Object owner,
    required TableSearchResult Function(String query) search,
    required VoidCallback resetSearch,
    required Future<void> Function() commitEditing,
    required bool Function() hasActiveEditing,
  }) {
    _owner = owner;
    _search = search;
    _resetSearch = resetSearch;
    _commitEditing = commitEditing;
    _hasActiveEditing = hasActiveEditing;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _search = null;
    _resetSearch = null;
    _commitEditing = null;
    _hasActiveEditing = null;
  }
}

class ScaleOutputSessionController extends ChangeNotifier {
  ScaleOutputSessionController({
    this.settings = const LabelPrintSettingsSnapshot.empty(),
    this.connectInfo = const ScaleConnectInfo.defaults(),
  });

  LabelPrintSettingsSnapshot settings;
  ScaleConnectInfo connectInfo;
  List<ScaleOutputRowDraft> _rows = const <ScaleOutputRowDraft>[];
  int? _selectedItemId;
  bool _busy = false;
  bool _cancellationRequested = false;
  int _issueUnitNumber = 0;
  int _issueTotalUnits = 0;
  ScaleOutputConnectionState _connectionState =
      ScaleOutputConnectionState.disconnected;
  String _connectionStatusText = '연결 안 됨';
  String _currentPortName = '';
  String _lastReceivedWeightRaw = '';

  List<ScaleOutputRowDraft> get rows => List.unmodifiable(_rows);
  int? get selectedItemId => _selectedItemId;
  ScaleOutputRowDraft? get selectedRow => _rows.firstWhereOrNull(
    (row) => row.itemId == _selectedItemId,
  );
  bool get busy => _busy;
  bool get cancellationRequested => _cancellationRequested;
  int get issueUnitNumber => _issueUnitNumber;
  int get issueTotalUnits => _issueTotalUnits;
  ScaleOutputConnectionState get connectionState => _connectionState;
  String get connectionStatusText => _connectionStatusText;
  String get currentPortName => _currentPortName;
  String get currentWeightText => selectedRow?.weightText ?? '';
  String get currentPriceText => selectedRow?.priceText ?? '';
  String get lastReceivedWeightRaw => _lastReceivedWeightRaw;
  bool get isConnected => _connectionState == ScaleOutputConnectionState.connected;

  void refreshPreview() => notifyListeners();

  bool beginIssue() {
    if (_busy) return false;
    _busy = true;
    _cancellationRequested = false;
    _issueUnitNumber = 0;
    _issueTotalUnits = 0;
    notifyListeners();
    return true;
  }

  void reportIssueUnit({required int unitNumber, required int totalUnits}) {
    if (!_busy) return;
    _issueUnitNumber = unitNumber;
    _issueTotalUnits = totalUnits;
    notifyListeners();
  }

  void requestCancel() {
    if (!_busy || _cancellationRequested) return;
    _cancellationRequested = true;
    notifyListeners();
  }

  void endIssue() {
    if (!_busy && !_cancellationRequested) return;
    _busy = false;
    _cancellationRequested = false;
    _issueUnitNumber = 0;
    _issueTotalUnits = 0;
    notifyListeners();
  }

  void syncCheckedItems({
    required List<ItemOfMarket> baselineItems,
    required Set<int> checkedItemIds,
    required ScaleOutputRowDraft Function(ItemOfMarket item) createRow,
  }) {
    final previous = <int, ScaleOutputRowDraft>{for (final row in _rows) row.itemId: row};
    _rows = <ScaleOutputRowDraft>[
      for (final item in baselineItems)
        if (checkedItemIds.contains(item.item.itemId))
          _mergeScaleOutputRow(
            fresh: createRow(item),
            previous: previous[item.item.itemId],
          ),
    ];
    if (!_rows.any((row) => row.itemId == _selectedItemId)) {
      _selectedItemId = _rows.firstOrNull?.itemId;
    }
    notifyListeners();
  }

  void selectItem(int itemId) {
    if (_selectedItemId == itemId || !_rows.any((row) => row.itemId == itemId)) {
      return;
    }
    _selectedItemId = itemId;
    notifyListeners();
  }

  void updateRow(
    int itemId,
    ScaleOutputRowDraft Function(ScaleOutputRowDraft row) update,
  ) {
    final index = _rows.indexWhere((row) => row.itemId == itemId);
    if (index < 0) return;
    final next = [..._rows];
    next[index] = update(next[index]);
    _rows = next;
    notifyListeners();
  }

  void updateSelectedWeight(String text, {bool recomputePrice = false}) {
    final selected = selectedRow;
    if (selected == null) return;
    updateRow(selected.itemId, (row) {
      final nextWeight = scaleOutputNormalizedWeightText(text);
      final nextPrice = recomputePrice
          ? scaleOutputComputePriceText(
                  rawWeightText: text,
                  priceBaseText: row.priceBaseText,
                ) ??
                row.priceText
          : row.priceText;
      return row.copyWith(weightText: nextWeight, priceText: nextPrice);
    });
  }

  void updateSelectedPrice(String text) {
    final selected = selectedRow;
    if (selected == null) return;
    updateRow(
      selected.itemId,
      (row) => row.copyWith(priceText: scaleOutputNormalizedPriceText(text)),
    );
  }

  void applyIncomingWeight(String raw) {
    final selected = selectedRow;
    if (selected == null) return;
    final normalized = scaleOutputNormalizedWeightText(raw);
    final computedPrice = scaleOutputComputePriceText(
      rawWeightText: raw,
      priceBaseText: selected.priceBaseText,
    );
    _lastReceivedWeightRaw = raw;
    updateRow(
      selected.itemId,
      (row) => row.copyWith(
        weightText: normalized,
        priceText: computedPrice ?? '',
      ),
    );
  }

  void applySettings(LabelPrintSettingsSnapshot value) {
    settings = value;
    _rows = [
      for (final row in _rows)
        row.copyWith(
          leftMarginMm:
              row.leftMarginSource == LabelPrintValueSource.preferenceFallback
              ? value.leftMarginMm
              : row.leftMarginMm,
          rightMarginMm:
              row.rightMarginSource == LabelPrintValueSource.preferenceFallback
              ? value.rightMarginMm
              : row.rightMarginMm,
          topMarginMm:
              row.topMarginSource == LabelPrintValueSource.preferenceFallback
              ? value.topMarginMm
              : row.topMarginMm,
          leftPushMm:
              row.leftPushSource == LabelPrintValueSource.preferenceFallback
              ? value.leftPushMm
              : row.leftPushMm,
          topPushMm:
              row.topPushSource == LabelPrintValueSource.preferenceFallback
              ? value.topPushMm
              : row.topPushMm,
          lineSpacingPercent:
              row.lineSpacingSource == LabelPrintValueSource.preferenceFallback
              ? value.lineSpacingPercent
              : row.lineSpacingPercent,
        ),
    ];
    notifyListeners();
  }

  void updateConnectInfo(ScaleConnectInfo value) {
    connectInfo = value;
    _currentPortName = value.portName;
    notifyListeners();
  }

  ScaleOutputRowDraft _mergeScaleOutputRow({
    required ScaleOutputRowDraft fresh,
    required ScaleOutputRowDraft? previous,
  }) {
    if (previous == null) return fresh;
    // Baseline-derived print settings should refresh from the latest source row.
    // Keep only the operator-edited screen values across rebuilds.
    return fresh.copyWith(
      weightText: previous.weightText,
      priceText: previous.priceText,
    );
  }

  void setConnectionState(
    ScaleOutputConnectionState value, {
    String? statusText,
    String? portName,
  }) {
    _connectionState = value;
    if (statusText != null) _connectionStatusText = statusText;
    if (portName != null) _currentPortName = portName;
    notifyListeners();
  }
}

class ScaleOutputPrintSettingsStore {
  const ScaleOutputPrintSettingsStore._();

  static Future<LabelPrintSettingsSnapshot> load(int labelSizeId) async {
    return await DbScaleConnectInfoHelper.loadPrinterSettings(labelSizeId) ??
        const LabelPrintSettingsSnapshot.empty();
  }

  static Future<void> save(int labelSizeId, LabelPrintSettingsSnapshot settings) {
    return DbScaleConnectInfoHelper.savePrinterSettings(labelSizeId, settings);
  }

  static List<ScaleOutputRowDraft> applyToRows(
    List<ScaleOutputRowDraft> rows,
    LabelPrintSettingsSnapshot settings,
  ) => [
    for (final row in rows)
      row.copyWith(
        leftMarginMm:
            row.leftMarginSource == LabelPrintValueSource.preferenceFallback
            ? settings.leftMarginMm
            : row.leftMarginMm,
        rightMarginMm:
            row.rightMarginSource == LabelPrintValueSource.preferenceFallback
            ? settings.rightMarginMm
            : row.rightMarginMm,
        topMarginMm:
            row.topMarginSource == LabelPrintValueSource.preferenceFallback
            ? settings.topMarginMm
            : row.topMarginMm,
        lineSpacingPercent:
            row.lineSpacingSource == LabelPrintValueSource.preferenceFallback
            ? settings.lineSpacingPercent
            : row.lineSpacingPercent,
      ),
  ];
}

class ScaleOutputUnit {
  const ScaleOutputUnit({
    required this.row,
    required this.rowIndex,
    required this.copyIndex,
    required this.projectedColumnValues,
  });

  final ScaleOutputRowDraft row;
  final int rowIndex;
  final int copyIndex;
  final Map<int, String> projectedColumnValues;

  LabelPrintUnit toLabelPrintUnit() => LabelPrintUnit(
    row: row.toLabelPrintRowDraft(),
    rowIndex: rowIndex,
    copyIndex: copyIndex,
    projectedColumnValues: projectedColumnValues,
  );
}

List<ScaleOutputUnit> expandScaleOutputUnits(
  List<ScaleOutputRowDraft> rows, {
  required DateTime referenceAt,
  required List<TColumn> columns,
  required Map<ColumnItemKey, TColumnContent> columnContents,
}) => [
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1)
    for (var copyIndex = 0; copyIndex < rows[rowIndex].copies; copyIndex += 1)
      (() {
        final row = rows[rowIndex];
        final projected = <int, String>{
          ...projectLabelPrintColumnValues(
            itemId: row.itemId,
            copyIndex: copyIndex,
            columns: columns,
            columnContents: columnContents,
            referenceAt: referenceAt,
          ),
          ...scaleOutputProjectedSpecialValues(
            item: row.item,
            weightText: row.weightText,
            priceText: row.priceText,
          ),
        };
        return ScaleOutputUnit(
          row: row,
          rowIndex: rowIndex,
          copyIndex: copyIndex,
          projectedColumnValues: Map.unmodifiable(projected),
        );
      })(),
];

class ScaleConnectionService {
  SerialPort? _port;
  bool _running = false;
  Future<void>? _reader;
  int _generation = 0;
  final StringBuffer _buffer = StringBuffer();

  bool get isConnected => _port != null && _port!.isOpened;

  List<String> availablePorts() {
    if (!Platform.isWindows) return const <String>[];
    return SerialPort.getAvailablePorts().where((port) => port.isNotEmpty).toList();
  }

  Future<bool> connect({
    required ScaleConnectInfo info,
    required void Function(String rawWeight) onWeight,
  }) async {
    final generation = ++_generation;
    await _disconnectCurrent();
    if (generation != _generation) return false;
    if (!Platform.isWindows) {
      throw UnsupportedError('저울 연결은 Windows에서만 지원합니다.');
    }
    final port = SerialPort(
      info.portName,
      BaudRate: _baudRateValue(info.baudRate),
      ByteSize: info.dataBit,
      StopBits: info.stopBit == 2
          ? TWOSTOPBITS
          : info.stopBit == 1.5
          ? ONE5STOPBITS
          : ONESTOPBIT,
      Parity: _parityValue(info.parityBit),
      ReadIntervalTimeout: 0xFFFFFFFF,
      ReadTotalTimeoutConstant: 0,
      ReadTotalTimeoutMultiplier: 0,
      openNow: true,
    );
    if (generation != _generation) {
      port.close();
      return false;
    }
    _port = port;
    _running = true;
    _reader = _readLoop(generation, onWeight);
    return true;
  }

  Future<void> disconnect() async {
    _generation += 1;
    await _disconnectCurrent();
  }

  Future<void> _disconnectCurrent() async {
    _running = false;
    final port = _port;
    _port = null;
    if (port == null) return;
    try {
      port.close();
    } catch (_) {
      // ignore close failure
    }
    final reader = _reader;
    _reader = null;
    if (reader != null) {
      await reader;
    }
  }

  Future<void> _readLoop(
    int generation,
    void Function(String rawWeight) onWeight,
  ) async {
    while (_running && generation == _generation) {
      final port = _port;
      if (port == null || !port.isOpened) return;
      final bytes = await port.readBytes(
        256,
        timeout: const Duration(milliseconds: 200),
      );
      if (bytes.isEmpty) continue;
      final chunk = ascii.decode(bytes, allowInvalid: true);
      if (chunk.isEmpty) continue;
      _buffer.write(chunk);
      final normalized = _buffer.toString().replaceAll('\r', '\n');
      final parts = normalized.split('\n');
      _buffer
        ..clear()
        ..write(parts.last);
      for (final line in parts.take(parts.length - 1)) {
        final value = line.trim();
        if (value.isNotEmpty && generation == _generation) onWeight(value);
      }
    }
  }

  static int _baudRateValue(int value) {
    switch (value) {
      case 110:
        return CBR_110;
      case 300:
        return CBR_300;
      case 600:
        return CBR_600;
      case 1200:
        return CBR_1200;
      case 2400:
        return CBR_2400;
      case 4800:
        return CBR_4800;
      case 9600:
        return CBR_9600;
      case 14400:
        return CBR_14400;
      case 19200:
        return CBR_19200;
      case 38400:
        return CBR_38400;
      case 56000:
        return CBR_56000;
      case 57600:
        return CBR_57600;
      case 115200:
        return CBR_115200;
      case 128000:
        return CBR_128000;
      case 256000:
        return CBR_256000;
      default:
        throw ArgumentError.value(value, 'value', 'Unsupported baud rate');
    }
  }

  static int _parityValue(String parity) {
    switch (parity.trim().toLowerCase()) {
      case 'odd':
        return ODDPARITY;
      case 'even':
        return EVENPARITY;
      case 'mark':
        return MARKPARITY;
      case 'space':
        return SPACEPARITY;
      case 'none':
      default:
        return NOPARITY;
    }
  }
}