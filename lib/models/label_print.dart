import 'package:flutter/foundation.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';

int resolveLabelPrintCopies({
  required ItemOfMarket item,
  required Iterable<TColumn> columns,
  required TColumnContentScopedView columnContents,
}) {
  final ordered = columns.toList()
    ..sort((left, right) {
      final byOrder = left.order.compareTo(right.order);
      return byOrder != 0 ? byOrder : left.columnId.compareTo(right.columnId);
    });
  TColumn? printCountColumn;
  for (final column in ordered) {
    if (column.columnType.code == TColumnType.TYPE_PRINTCOUNT) {
      printCountColumn = column;
      break;
    }
  }
  if (printCountColumn == null) return item.printCount;
  final value = columnContents
      .value(printCountColumn.columnId, item.item.itemId)
      .trim();
  if (value.isEmpty) return 0;
  final copies = int.tryParse(value);
  if (copies == null) {
    throw FormatException('발행매수는 0 이상의 정수여야 합니다.', value);
  }
  return copies;
}

enum LabelPrintValueSource {
  itemBaseline,
  itemOverride,
  labelSizeFallback,
  preferenceFallback,
  sessionEdited,
}

enum LabelPrintOrientation { horizontal, vertical }

@immutable
class LabelPrintSettingsSnapshot {
  const LabelPrintSettingsSnapshot({
    required this.printerName,
    required this.leftMarginMm,
    required this.rightMarginMm,
    required this.topMarginMm,
    required this.leftPushMm,
    required this.topPushMm,
    required this.lineSpacingPercent,
    required this.extraAreaMm,
    required this.orientation,
  });

  const LabelPrintSettingsSnapshot.empty()
      : printerName = null,
        leftMarginMm = 0,
        rightMarginMm = 0,
        topMarginMm = 0,
        leftPushMm = 0,
        topPushMm = 0,
        lineSpacingPercent = 100,
        extraAreaMm = 0,
        orientation = LabelPrintOrientation.horizontal;

  final String? printerName;
  final double leftMarginMm;
  final double rightMarginMm;
  final double topMarginMm;
  final double leftPushMm;
  final double topPushMm;
  final int? lineSpacingPercent;
  final double extraAreaMm;
  final LabelPrintOrientation orientation;
}

@immutable
class LabelPrintRowDraft {
  const LabelPrintRowDraft({
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

  factory LabelPrintRowDraft.fromBaseline({
    required ItemOfMarket item,
    required LabelSize labelSize,
    required int copies,
    required LabelPrintSettingsSnapshot settings,
  }) {
    final common = labelSize.labelSizeCommon;
    final usesItemSize = item.useLabelSize;
    final usesItemMargins = item.useMargin;
    final usesItemLineSpacing = item.useLinefeed;
    return LabelPrintRowDraft(
      item: item,
      copies: copies,
      widthMm: usesItemSize ? item.labelSizeWidth : common?.width ?? 0,
      heightMm: usesItemSize ? item.labelSizeHeight : common?.height ?? 0,
      leftMarginMm:
          usesItemMargins ? item.leftMargin : settings.leftMarginMm,
      rightMarginMm:
          usesItemMargins ? item.rightMargin : settings.rightMarginMm,
      topMarginMm: usesItemMargins ? item.topMargin : settings.topMarginMm,
      leftPushMm: usesItemMargins ? item.leftPush : settings.leftPushMm,
      topPushMm: usesItemMargins ? item.topPush : settings.topPushMm,
      lineSpacingPercent: usesItemLineSpacing
          ? (item.linefeed == 0 ? null : item.linefeed)
          : settings.lineSpacingPercent,
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
  final LabelPrintValueSource copiesSource;
  final LabelPrintValueSource widthSource;
  final LabelPrintValueSource heightSource;
  final LabelPrintValueSource leftMarginSource;
  final LabelPrintValueSource rightMarginSource;
  final LabelPrintValueSource topMarginSource;
  final LabelPrintValueSource leftPushSource;
  final LabelPrintValueSource topPushSource;
  final LabelPrintValueSource lineSpacingSource;

  LabelPrintRowDraft copyWith({
    int? copies,
    int? widthMm,
    int? heightMm,
    double? leftMarginMm,
    double? rightMarginMm,
    double? topMarginMm,
    double? leftPushMm,
    double? topPushMm,
    Object? lineSpacingPercent = _unchanged,
    LabelPrintValueSource? copiesSource,
    LabelPrintValueSource? widthSource,
    LabelPrintValueSource? heightSource,
    LabelPrintValueSource? leftMarginSource,
    LabelPrintValueSource? rightMarginSource,
    LabelPrintValueSource? topMarginSource,
    LabelPrintValueSource? leftPushSource,
    LabelPrintValueSource? topPushSource,
    LabelPrintValueSource? lineSpacingSource,
  }) => LabelPrintRowDraft(
    item: item,
    copies: copies ?? this.copies,
    widthMm: widthMm ?? this.widthMm,
    heightMm: heightMm ?? this.heightMm,
    leftMarginMm: leftMarginMm ?? this.leftMarginMm,
    rightMarginMm: rightMarginMm ?? this.rightMarginMm,
    topMarginMm: topMarginMm ?? this.topMarginMm,
    leftPushMm: leftPushMm ?? this.leftPushMm,
    topPushMm: topPushMm ?? this.topPushMm,
    lineSpacingPercent: identical(lineSpacingPercent, _unchanged)
        ? this.lineSpacingPercent
        : lineSpacingPercent as int?,
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
}

const Object _unchanged = Object();

class LabelPrintSessionController extends ChangeNotifier {
  LabelPrintSessionController({
    this.settings = const LabelPrintSettingsSnapshot.empty(),
  });

  LabelPrintSettingsSnapshot settings;
  List<LabelPrintRowDraft> _rows = const <LabelPrintRowDraft>[];
  int? _selectedItemId;
  bool _busy = false;
  bool _cancellationRequested = false;
  int _issueUnitNumber = 0;
  int _issueTotalUnits = 0;

  List<LabelPrintRowDraft> get rows => List.unmodifiable(_rows);
  int? get selectedItemId => _selectedItemId;
  int get totalCopies => _rows.fold(0, (sum, row) => sum + row.copies);
  bool get busy => _busy;
  bool get cancellationRequested => _cancellationRequested;
  int get issueUnitNumber => _issueUnitNumber;
  int get issueTotalUnits => _issueTotalUnits;

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
    required LabelPrintRowDraft Function(ItemOfMarket item) createRow,
  }) {
    final previous = <int, LabelPrintRowDraft>{
      for (final row in _rows) row.itemId: row,
    };
    _rows = <LabelPrintRowDraft>[
      for (final item in baselineItems)
        if (checkedItemIds.contains(item.item.itemId))
          previous[item.item.itemId] ?? createRow(item),
    ];
    if (!_rows.any((row) => row.itemId == _selectedItemId)) {
      _selectedItemId = _rows.firstOrNull?.itemId;
    }
    notifyListeners();
  }

  void editCopies(int itemId, int copies) {
    updateRow(
      itemId,
      (row) => row.copyWith(
        copies: copies,
        copiesSource: LabelPrintValueSource.sessionEdited,
      ),
    );
  }

  void updateRow(
    int itemId,
    LabelPrintRowDraft Function(LabelPrintRowDraft row) update,
  ) {
    final index = _rows.indexWhere((row) => row.itemId == itemId);
    if (index < 0) return;
    final next = [..._rows];
    next[index] = update(next[index]);
    _rows = next;
    notifyListeners();
  }

  void selectItem(int itemId) {
    if (_selectedItemId == itemId || !_rows.any((row) => row.itemId == itemId)) {
      return;
    }
    _selectedItemId = itemId;
    notifyListeners();
  }

  bool selectNextExact(
    String query,
    Iterable<String> Function(LabelPrintRowDraft row) valuesFor,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty || _rows.isEmpty) return false;
    final selectedIndex = _rows.indexWhere(
      (row) => row.itemId == _selectedItemId,
    );
    for (var offset = 1; offset <= _rows.length; offset += 1) {
      final index = (selectedIndex + offset) % _rows.length;
      final matched = valuesFor(_rows[index]).any(
        (value) => value.trim().toLowerCase() == normalized,
      );
      if (!matched) continue;
      _selectedItemId = _rows[index].itemId;
      notifyListeners();
      return true;
    }
    return false;
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

  void applyCommittedAutoIncrementValues({
    required List<TColumn> columns,
    required Map<ColumnItemKey, String> values,
  }) {
    final ordered = [...columns]
      ..sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.columnId.compareTo(right.columnId);
      });
    final printCountColumn = ordered
        .where(
          (column) => column.columnType.code == TColumnType.TYPE_PRINTCOUNT,
        )
        .firstOrNull;
    if (printCountColumn == null) return;
    var changed = false;
    _rows = [
      for (final row in _rows)
        if (row.copiesSource == LabelPrintValueSource.itemBaseline &&
            values.containsKey(
              ColumnItemKey(
                columnId: printCountColumn.columnId,
                itemId: row.itemId,
              ),
            ))
          (() {
            final raw = values[ColumnItemKey(
              columnId: printCountColumn.columnId,
              itemId: row.itemId,
            )]!
                .trim();
            final copies = raw.isEmpty ? 0 : int.tryParse(raw);
            if (copies == null || copies < 0) {
              throw FormatException('발행매수는 0 이상의 정수여야 합니다.', raw);
            }
            changed = true;
            return row.copyWith(copies: copies);
          })()
        else
          row,
    ];
    if (changed) notifyListeners();
  }
}