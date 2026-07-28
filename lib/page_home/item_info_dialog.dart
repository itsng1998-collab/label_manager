import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef ItemInfoLoader = Future<List<ItemOfMarket>?> Function(
  int marketId,
  int labelSizeId,
);
typedef ItemInfoSaver = Future<void> Function(List<ItemOfMarket> items);

class ItemInfoController extends ChangeNotifier {
  List<ItemOfMarket> _rows = const [];
  List<ItemOfMarket> _committedRows = const [];
  bool _loading = false;
  bool _writeBusy = false;
  bool _disposed = false;

  List<ItemOfMarket> get rows => _rows;
  bool get loading => _loading;
  bool get writeBusy => _writeBusy;
  bool get dirty => !_sameRows(_rows, _committedRows);

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy ? '품목별 정보 저장이 끝난 뒤 다시 시도해주세요.' : null,
    dirtyWorks: [
      if (dirty)
        LifecycleDirtyWork(name: '품목별 정보 편집', discard: discard),
    ],
  );

  void setLoading(bool value) {
    if (_disposed || _loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void load(List<ItemOfMarket> values) {
    if (_disposed) return;
    _rows = List.unmodifiable(values);
    _committedRows = List.unmodifiable(values);
    notifyListeners();
  }

  void update(int index, ItemOfMarket value) {
    if (_disposed || _writeBusy) return;
    final next = [..._rows];
    next[index] = value;
    _rows = List.unmodifiable(next);
    notifyListeners();
  }

  void markCommitted() {
    if (_disposed) return;
    _committedRows = List.unmodifiable(_rows);
    notifyListeners();
  }

  void setWriteBusy(bool value) {
    if (_disposed || _writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }

  void discard() {
    if (_disposed) return;
    _rows = List.unmodifiable(_committedRows);
    notifyListeners();
  }

  static bool _sameRows(List<ItemOfMarket> left, List<ItemOfMarket> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      final a = left[index];
      final b = right[index];
      if (a.useLinefeed != b.useLinefeed ||
          a.linefeed != b.linefeed ||
          a.useScaleBarcode != b.useScaleBarcode ||
          a.printCount != b.printCount ||
          a.useLabelSize != b.useLabelSize ||
          a.labelSizeWidth != b.labelSizeWidth ||
          a.labelSizeHeight != b.labelSizeHeight ||
          a.useMargin != b.useMargin ||
          a.leftMargin != b.leftMargin ||
          a.rightMargin != b.rightMargin ||
          a.topMargin != b.topMargin ||
          a.leftPush != b.leftPush ||
          a.topPush != b.topPush) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ItemInfoDialogContent extends StatefulWidget {
  const ItemInfoDialogContent({
    super.key,
    required this.controller,
    required this.marketId,
    required this.labelSizeId,
    required this.onCommitted,
    required this.onCommitOutcomeUnknown,
    required this.onClose,
    this.load = ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId,
    this.save = ItemOfMarketDAO.updateItemInfoBatch,
  });

  final ItemInfoController controller;
  final int? marketId;
  final int? labelSizeId;
  final ValueChanged<List<ItemOfMarket>> onCommitted;
  final VoidCallback onCommitOutcomeUnknown;
  final VoidCallback onClose;
  final ItemInfoLoader load;
  final ItemInfoSaver save;

  @override
  State<ItemInfoDialogContent> createState() => _ItemInfoDialogContentState();
}

class _ItemInfoDialogContentState extends State<ItemInfoDialogContent> {
  int? _selectedIndex;

  bool get _busy => widget.controller.loading || widget.controller.writeBusy;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final marketId = widget.marketId;
    final labelSizeId = widget.labelSizeId;
    if (marketId == null || labelSizeId == null) {
      widget.controller.load(const []);
      return;
    }
    widget.controller.setLoading(true);
    try {
      widget.controller.load(await widget.load(marketId, labelSizeId) ?? const []);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      widget.controller.setLoading(false);
    }
  }

  Future<void> _save() async {
    if (_busy || !widget.controller.dirty || widget.controller.rows.isEmpty) {
      return;
    }
    widget.controller.setWriteBusy(true);
    try {
      await widget.save(widget.controller.rows);
      widget.controller.markCommitted();
      widget.onCommitted(widget.controller.rows);
    } on DbCommitOutcomeUnknown catch (error) {
      if (mounted) await _showMessage(error.toString());
      widget.onCommitOutcomeUnknown();
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      widget.controller.setWriteBusy(false);
    }
  }

  void _update(int index, ItemOfMarket Function(ItemOfMarket) update) {
    widget.controller.update(index, update(widget.controller.rows[index]));
  }

  FortuneTableColumn<ItemOfMarket> _checkboxColumn({
    required String id,
    required String header,
    required bool Function(ItemOfMarket) value,
    required ItemOfMarket Function(ItemOfMarket, bool) update,
  }) => FortuneTableColumn(
    id: id,
    header: header,
    initialWidth: 76,
    text: (_) => '',
    checkboxValue: value,
    onCheckboxChangedAt: (row, index, checked) {
      if (!_busy) _update(index, (current) => update(current, checked));
    },
  );

  FortuneTableColumn<ItemOfMarket> _integerColumn({
    required String id,
    required String header,
    required int Function(ItemOfMarket) value,
    required bool Function(ItemOfMarket) enabled,
    required ItemOfMarket Function(ItemOfMarket, int) update,
    Set<int>? allowed,
  }) => FortuneTableColumn(
    id: id,
    header: header,
    initialWidth: 82,
    text: (row) => '${value(row)}',
    isTextEditable: (row, _) => !_busy && enabled(row),
    onTextCommitted: (row, index, text) {
      final parsed = int.tryParse(text);
      if (parsed == null || (allowed != null && !allowed.contains(parsed))) {
        return;
      }
      _update(index, (current) => update(current, parsed));
    },
  );

  FortuneTableColumn<ItemOfMarket> _doubleColumn({
    required String id,
    required String header,
    required double Function(ItemOfMarket) value,
    required bool Function(ItemOfMarket) enabled,
    required ItemOfMarket Function(ItemOfMarket, double) update,
  }) => FortuneTableColumn(
    id: id,
    header: header,
    initialWidth: 82,
    text: (row) => '${value(row)}',
    isTextEditable: (row, _) => !_busy && enabled(row),
    onTextCommitted: (row, index, text) {
      final parsed = double.tryParse(text);
      if (parsed == null) return;
      _update(index, (current) => update(current, parsed));
    },
  );

  List<FortuneTableColumn<ItemOfMarket>> get _columns => [
    FortuneTableColumn(
      id: 'itemName',
      header: '품명',
      initialWidth: 180,
      text: (row) => row.item.itemName,
    ),
    _checkboxColumn(
      id: 'useLinefeed',
      header: '줄간격 사용',
      value: (row) => row.useLinefeed,
      update: (row, value) => row.copyWith(useLinefeed: value),
    ),
    _integerColumn(
      id: 'linefeed',
      header: '줄간격',
      value: (row) => row.linefeed,
      enabled: (row) => row.useLinefeed,
      update: (row, value) => row.copyWith(linefeed: value),
      allowed: {for (var value = 80; value <= 150; value += 5) value},
    ),
    _checkboxColumn(
      id: 'useScaleBarcode',
      header: '저울 바코드',
      value: (row) => row.useScaleBarcode,
      update: (row, value) => row.copyWith(useScaleBarcode: value),
    ),
    _integerColumn(
      id: 'printCount',
      header: '기본 발행 수량',
      value: (row) => row.printCount,
      enabled: (_) => true,
      update: (row, value) => row.copyWith(printCount: value),
    ),
    _checkboxColumn(
      id: 'useLabelSize',
      header: '개별 크기',
      value: (row) => row.useLabelSize,
      update: (row, value) => row.copyWith(useLabelSize: value),
    ),
    _integerColumn(
      id: 'labelSizeWidth',
      header: '폭',
      value: (row) => row.labelSizeWidth,
      enabled: (row) => row.useLabelSize,
      update: (row, value) => row.copyWith(labelSizeWidth: value),
    ),
    _integerColumn(
      id: 'labelSizeHeight',
      header: '높이',
      value: (row) => row.labelSizeHeight,
      enabled: (row) => row.useLabelSize,
      update: (row, value) => row.copyWith(labelSizeHeight: value),
    ),
    _checkboxColumn(
      id: 'useMargin',
      header: '개별 여백',
      value: (row) => row.useMargin,
      update: (row, value) => row.copyWith(useMargin: value),
    ),
    _doubleColumn(
      id: 'leftMargin',
      header: '좌 여백',
      value: (row) => row.leftMargin,
      enabled: (row) => row.useMargin,
      update: (row, value) => row.copyWith(leftMargin: value),
    ),
    _doubleColumn(
      id: 'rightMargin',
      header: '우 여백',
      value: (row) => row.rightMargin,
      enabled: (row) => row.useMargin,
      update: (row, value) => row.copyWith(rightMargin: value),
    ),
    _doubleColumn(
      id: 'topMargin',
      header: '상 여백',
      value: (row) => row.topMargin,
      enabled: (row) => row.useMargin,
      update: (row, value) => row.copyWith(topMargin: value),
    ),
    _doubleColumn(
      id: 'leftPush',
      header: '좌 밀기',
      value: (row) => row.leftPush,
      enabled: (row) => row.useMargin,
      update: (row, value) => row.copyWith(leftPush: value),
    ),
    _doubleColumn(
      id: 'topPush',
      header: '상 밀기',
      value: (row) => row.topPush,
      enabled: (row) => row.useMargin,
      update: (row, value) => row.copyWith(topPush: value),
    ),
  ];

  Future<void> _showMessage(String message) =>
      showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (context, close) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => close(null), child: const Text('확인')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: FortuneTable<ItemOfMarket>(
          rows: widget.controller.rows,
          columns: _columns,
          selectedIndex: _selectedIndex,
          onRowSelected: (_, index) => setState(() => _selectedIndex = index),
          autoFitColumns: false,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton.icon(
              key: const ValueKey('itemInfoSaveButton'),
              onPressed:
                  !_busy && widget.controller.dirty && widget.controller.rows.isNotEmpty
                  ? _save
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('저장'),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('itemInfoCloseButton'),
              onPressed: widget.controller.writeBusy ? null : widget.onClose,
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    ],
  );
}