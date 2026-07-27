import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_detail.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/search_and_replace_sheet.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef ItemDetailSearcher = Future<List<ItemDetail>> Function({
  required int customerId,
  required ItemDetailSearchType type,
  required String query,
  int? brandId,
  int? labelSizeId,
});
typedef SearchReplaceSaver = Future<void> Function(
  List<ItemElementSearchReplaceUpdate>,
);

class SearchReplaceEditTarget {
  const SearchReplaceEditTarget({
    required this.brandId,
    required this.labelSizeId,
    required this.itemId,
  });

  final int brandId;
  final int labelSizeId;
  final int itemId;
}

class SearchReplacePrintTarget {
  const SearchReplacePrintTarget({
    required this.brandId,
    required this.labelSizeId,
    required this.itemIds,
  });

  final int brandId;
  final int labelSizeId;
  final List<int> itemIds;
}

class SearchAndReplaceController extends ChangeNotifier {
  bool _activeEditing = false;
  bool _writeBusy = false;
  bool _dirty = false;
  bool _disposed = false;
  VoidCallback? _discard;

  bool get activeEditing => _activeEditing;
  bool get writeBusy => _writeBusy;
  bool get dirty => _dirty;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '검색 및 치환 저장이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '주원료 편집을 먼저 적용하거나 취소해주세요.'
        : null,
    dirtyWorks: [
      if (_dirty)
        LifecycleDirtyWork(
          name: '검색 및 치환',
          discard: () => _discard?.call(),
        ),
    ],
  );

  void setActiveEditing(bool value) {
    if (_disposed || _activeEditing == value) return;
    _activeEditing = value;
    notifyListeners();
  }

  void setWriteBusy(bool value) {
    if (_disposed || _writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }

  void setDirty(bool value, {VoidCallback? discard}) {
    if (_disposed) return;
    _dirty = value;
    _discard = value ? discard : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SearchReplaceDraftRow {
  const SearchReplaceDraftRow({
    required this.source,
    required this.element,
    required this.elementSheet,
    this.checked = false,
    this.changed = false,
  });

  final ItemDetail source;
  final String element;
  final String elementSheet;
  final bool checked;
  final bool changed;

  SearchReplaceDraftRow copyWith({
    String? element,
    String? elementSheet,
    bool? checked,
    bool? changed,
  }) => SearchReplaceDraftRow(
    source: source,
    element: element ?? this.element,
    elementSheet: elementSheet ?? this.elementSheet,
    checked: checked ?? this.checked,
    changed: changed ?? this.changed,
  );
}

class SearchAndReplaceDialogContent extends StatefulWidget {
  const SearchAndReplaceDialogContent({
    super.key,
    required this.controller,
    required this.customerId,
    required this.editable,
    required this.onMoveToEdit,
    required this.onMoveToPrint,
    required this.onSaved,
    required this.onCommitOutcomeUnknown,
    this.initialSearchText = '',
    this.loadBrands = BrandDAO.selectByCustomerIdByBrandOrder,
    this.loadLabelSizes = LabelSizeDAO.selectByBrandIdByLabelSizeOrder,
    this.search = ItemDetailDAO.search,
    this.save = ItemDAO.updateSearchReplaceElements,
  });

  final SearchAndReplaceController controller;
  final int customerId;
  final bool editable;
  final String initialSearchText;
  final Future<void> Function(SearchReplaceEditTarget) onMoveToEdit;
  final Future<void> Function(SearchReplacePrintTarget) onMoveToPrint;
  final Future<void> Function() onSaved;
  final VoidCallback onCommitOutcomeUnknown;
  final Future<List<Brand>?> Function(int) loadBrands;
  final Future<List<LabelSize>?> Function(int) loadLabelSizes;
  final ItemDetailSearcher search;
  final SearchReplaceSaver save;

  @override
  State<SearchAndReplaceDialogContent> createState() =>
      _SearchAndReplaceDialogContentState();
}

class _SearchAndReplaceDialogContentState
    extends State<SearchAndReplaceDialogContent> {
  late final TextEditingController _searchController;
  List<Brand> _brands = const [];
  List<LabelSize> _labelSizes = const [];
  List<SearchReplaceDraftRow> _rows = const [];
  ItemDetailSearchType _searchType = ItemDetailSearchType.itemName;
  bool _useBrand = false;
  bool _useLabelSize = false;
  int? _brandId;
  int? _labelSizeId;
  int? _selectedIndex;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;
  SearchReplaceDraftRow? get _selectedRow {
    final index = _selectedIndex;
    return index == null || index < 0 || index >= _rows.length
        ? null
        : _rows[index];
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchText);
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final brands = await widget.loadBrands(widget.customerId);
      if (!mounted) return;
      setState(() {
        _brands = brands ?? const [];
        _loading = false;
      });
      if (widget.initialSearchText.isNotEmpty) await _search();
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectBrand(int? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _brandId = value;
      _labelSizeId = null;
      _labelSizes = const [];
    });
    try {
      final sizes = await widget.loadLabelSizes(value);
      if (mounted) setState(() => _labelSizes = sizes ?? const []);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    if (_busy) return;
    final query = _searchController.text;
    if (query.isEmpty) {
      await _showMessage('검색할 내용을 입력해주세요!');
      return;
    }
    if (_useBrand && _brandId == null) {
      await _showMessage('브랜드가 선택되어있지 않습니다!');
      return;
    }
    if (_useLabelSize && _labelSizeId == null) {
      await _showMessage('라벨사이즈가 선택되어있지 않습니다!');
      return;
    }
    setState(() => _loading = true);
    try {
      final values = await widget.search(
        customerId: widget.customerId,
        type: _searchType,
        query: query,
        brandId: _useBrand ? _brandId : null,
        labelSizeId: _useLabelSize ? _labelSizeId : null,
      );
      if (!mounted) return;
      setState(() {
        _rows = [
          for (final value in values)
            SearchReplaceDraftRow(
              source: value,
              element: value.element,
              elementSheet: value.elementSheet,
            ),
        ];
        _selectedIndex = null;
      });
      widget.controller.setDirty(false);
      if (values.isEmpty) await _showMessage('검색결과가 존재하지 않습니다!');
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setChecked(int index, bool value) {
    final next = [..._rows];
    next[index] = next[index].copyWith(checked: value);
    setState(() => _rows = next);
  }

  void _setAllChecked(bool value) {
    setState(() {
      _rows = [for (final row in _rows) row.copyWith(checked: value)];
    });
  }

  void _markDirty() {
    widget.controller.setDirty(
      _rows.any((row) => row.changed),
      discard: _discardChanges,
    );
  }

  void _discardChanges() {
    if (!mounted) return;
    setState(() {
      _rows = [
        for (final row in _rows)
          row.copyWith(
            element: row.source.element,
            elementSheet: row.source.elementSheet,
            changed: false,
          ),
      ];
    });
    widget.controller.setDirty(false);
  }

  Future<void> _editRow(SearchReplaceDraftRow row, int index) async {
    if (!widget.editable || _busy) return;
    setState(() => _selectedIndex = index);
    widget.controller.setActiveEditing(true);
    try {
      final value = await _showElementEditor(row.element);
      if (value == null || !mounted) return;
      final updated = await setSearchElement(
        element: value,
        elementSheet: row.elementSheet,
      );
      if (!mounted) return;
      final next = [..._rows];
      next[index] = row.copyWith(
        element: updated.element,
        elementSheet: updated.elementSheet,
        changed: true,
      );
      setState(() => _rows = next);
      _markDirty();
    } finally {
      widget.controller.setActiveEditing(false);
    }
  }

  Future<void> _batchReplace() async {
    if (!widget.editable || _busy || !_rows.any((row) => row.checked)) return;
    widget.controller.setActiveEditing(true);
    try {
      final values = await _showBatchEditor();
      if (values == null || !mounted) return;
      final confirmed = await _confirm(
        "선택한 품목의 주원료 '${values.find}'가 '${values.replacement}'로 변환됩니다. 진행하시겠습니까?",
        title: '바꾸기',
      );
      if (confirmed != true || !mounted) return;
      final next = [..._rows];
      for (var index = 0; index < next.length; index += 1) {
        final row = next[index];
        if (!row.checked) continue;
        final updated = await replaceSearchElement(
          element: row.element,
          elementSheet: row.elementSheet,
          find: values.find,
          replacement: values.replacement,
        );
        next[index] = row.copyWith(
          element: updated.element,
          elementSheet: updated.elementSheet,
          changed: true,
        );
      }
      if (!mounted) return;
      setState(() => _rows = next);
      _markDirty();
    } finally {
      widget.controller.setActiveEditing(false);
    }
  }

  Future<void> _save() async {
    if (!widget.editable || _busy || !widget.controller.dirty) return;
    final confirmed = await _confirm('변경내용을 저장하시겠습니까?', title: '저장');
    if (confirmed != true || !mounted) return;
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    var committed = false;
    try {
      await widget.save([
        for (final row in _rows)
          if (row.changed)
            ItemElementSearchReplaceUpdate(
              itemId: row.source.itemId,
              element: row.element,
              elementSheet: row.elementSheet,
            ),
      ]);
          committed = true;
      if (!mounted) return;
      setState(() {
        _rows = [for (final row in _rows) row.copyWith(changed: false)];
      });
      widget.controller.setDirty(false);
      await widget.onSaved();
    } on DbCommitOutcomeUnknown catch (error) {
      if (mounted) await _showMessage(error.toString());
      widget.onCommitOutcomeUnknown();
    } catch (error) {
      if (committed) {
        if (mounted) {
          await _showMessage('저장은 완료됐지만 화면 갱신에 실패했습니다.');
        }
        widget.onCommitOutcomeUnknown();
      } else if (mounted) {
        await _showMessage(error.toString());
      }
    } finally {
      widget.controller.setWriteBusy(false);
      if (mounted) setState(() {});
    }
  }

  Future<void> _moveToEdit() async {
    final row = _selectedRow;
    if (_busy || row == null) return;
    await widget.onMoveToEdit(
      SearchReplaceEditTarget(
        brandId: row.source.brandId,
        labelSizeId: row.source.labelSizeId,
        itemId: row.source.itemId,
      ),
    );
  }

  Future<void> _moveToPrint() async {
    if (_busy) return;
    final checked = _rows.where((row) => row.checked).toList();
    if (checked.isEmpty) return;
    final first = checked.first.source;
    if (checked.any(
      (row) =>
          row.source.brandId != first.brandId ||
          row.source.labelSizeId != first.labelSizeId,
    )) {
      await _showMessage('같은 브랜드의 라벨사이즈만 선택해주세요.');
      return;
    }
    await widget.onMoveToPrint(
      SearchReplacePrintTarget(
        brandId: first.brandId,
        labelSizeId: first.labelSizeId,
        itemIds: [for (final row in checked) row.source.itemId],
      ),
    );
  }

  Future<String?> _showElementEditor(String initial) {
    final controller = TextEditingController(text: initial);
    return showBlockingModelessOverlayDialog<String>(
      context: context,
      builder: (context, close) => BlockingModelessDialogFrame(
        title: '주원료 변경',
        width: 620,
        height: 440,
        onClose: () => close(null),
        footer: _editorFooter(close, () => close(controller.text)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            key: const ValueKey('searchReplaceElementEditor'),
            controller: controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textInputAction: TextInputAction.newline,
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  Future<({String find, String replacement})?> _showBatchEditor() {
    final find = TextEditingController();
    final replacement = TextEditingController();
    return showBlockingModelessOverlayDialog<({
      String find,
      String replacement,
    })>(
      context: context,
      builder: (context, close) => BlockingModelessDialogFrame(
        title: '선택 주원료 일괄 변경',
        width: 520,
        height: 300,
        onClose: () => close(null),
        footer: _editorFooter(
          close,
          () => close((find: find.text, replacement: replacement.text)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                key: const ValueKey('searchReplaceFindField'),
                controller: find,
                decoration: const InputDecoration(labelText: '찾을 내용'),
                onSubmitted: (_) {},
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('searchReplaceReplacementField'),
                controller: replacement,
                decoration: const InputDecoration(labelText: '바꿀 내용'),
                onSubmitted: (_) {},
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      find.dispose();
      replacement.dispose();
    });
  }

  Widget _editorFooter<T>(
    void Function(T? result) close,
    VoidCallback apply,
  ) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => close(null), child: const Text('취소')),
        const SizedBox(width: 8),
        FilledButton(onPressed: apply, child: const Text('적용')),
      ],
    ),
  );

  Future<bool?> _confirm(String message, {required String title}) =>
      showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (context, close) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => close(false), child: const Text('취소')),
            FilledButton(onPressed: () => close(true), child: const Text('확인')),
          ],
        ),
      );

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

  List<FortuneTableColumn<SearchReplaceDraftRow>> get _columns => [
    if (widget.editable)
      FortuneTableColumn(
        id: 'checked',
        header: '',
        initialWidth: 48,
        text: (_) => '',
        checkboxValue: (row) => row.checked,
        onCheckboxChangedAt: (_, index, value) => _setChecked(index, value),
        headerCheckboxValue:
            _rows.isNotEmpty && _rows.every((row) => row.checked),
        onHeaderCheckboxChanged: _setAllChecked,
      ),
    FortuneTableColumn(
      id: 'brand',
      header: '브랜드',
      text: (row) => row.source.brandName,
    ),
    FortuneTableColumn(
      id: 'labelSize',
      header: '라벨 크기',
      text: (row) => row.source.labelSizeName,
    ),
    FortuneTableColumn(
      id: 'itemName',
      header: '품명',
      text: (row) => row.source.itemName,
    ),
    FortuneTableColumn(
      id: 'element',
      header: '주원료',
      text: (row) => row.element,
      fillRemaining: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final checked = _rows.where((row) => row.checked).length;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 130,
                child: DropdownButtonFormField<ItemDetailSearchType>(
                  key: const ValueKey('searchReplaceType'),
                  initialValue: _searchType,
                  items: const [
                    DropdownMenuItem(
                      value: ItemDetailSearchType.itemName,
                      child: Text('품명'),
                    ),
                    DropdownMenuItem(
                      value: ItemDetailSearchType.element,
                      child: Text('주원료'),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _searchType = value!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('searchReplaceQuery'),
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: '검색어'),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
              ),
              IconButton(
                key: const ValueKey('searchReplaceSearchButton'),
                tooltip: '검색',
                onPressed: _busy ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                key: const ValueKey('searchReplaceUseBrand'),
                value: _useBrand,
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _useBrand = value == true;
                        if (!_useBrand) _useLabelSize = false;
                      }),
              ),
              const Text('브랜드'),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('searchReplaceBrand'),
                  initialValue: _brands.any((value) => value.brandId == _brandId)
                      ? _brandId
                      : null,
                  items: [
                    for (final value in _brands)
                      DropdownMenuItem(
                        value: value.brandId,
                        child: Text(value.brandName),
                      ),
                  ],
                  onChanged: _useBrand && !_busy ? _selectBrand : null,
                ),
              ),
              const SizedBox(width: 16),
              Checkbox(
                key: const ValueKey('searchReplaceUseLabelSize'),
                value: _useLabelSize,
                onChanged: _useBrand && !_busy
                    ? (value) => setState(() => _useLabelSize = value == true)
                    : null,
              ),
              const Text('라벨 크기'),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<int>(
                  key: const ValueKey('searchReplaceLabelSize'),
                  initialValue: _labelSizes.any(
                    (value) => value.labelSizeId == _labelSizeId,
                  )
                      ? _labelSizeId
                      : null,
                  items: [
                    for (final value in _labelSizes)
                      DropdownMenuItem(
                        value: value.labelSizeId,
                        child: Text(value.labelSizeName),
                      ),
                  ],
                  onChanged: _useLabelSize && !_busy
                      ? (value) => setState(() => _labelSizeId = value)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FortuneTable<SearchReplaceDraftRow>(
              rows: _rows,
              columns: _columns,
              selectedIndex: _selectedIndex,
              onRowSelected: (_, index) =>
                  setState(() => _selectedIndex = index),
              onRowDoubleTap: widget.editable ? _editRow : null,
              fillLastColumn: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.editable)
                OutlinedButton.icon(
                  key: const ValueKey('searchReplaceBatchButton'),
                  onPressed: checked > 0 && !_busy ? _batchReplace : null,
                  icon: const Icon(Icons.find_replace),
                  label: const Text('선택 일괄 치환'),
                ),
              if (widget.editable) const SizedBox(width: 8),
              if (widget.editable)
                FilledButton.icon(
                  key: const ValueKey('searchReplaceSaveButton'),
                  onPressed:
                      widget.controller.dirty && !_busy ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('저장'),
                ),
              const Spacer(),
              OutlinedButton.icon(
                key: const ValueKey('searchReplaceMoveEditButton'),
                onPressed: _selectedRow != null && !_busy ? _moveToEdit : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('품목편집 이동'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const ValueKey('searchReplaceMovePrintButton'),
                onPressed: checked > 0 && !_busy ? _moveToPrint : null,
                icon: const Icon(Icons.print_outlined),
                label: const Text('출력 이동'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}