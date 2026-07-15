import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/label_column_candidates.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

typedef FixedColumnTypesLoader = Future<List<FixedColumnType>> Function();
typedef FixedColumnCandidatesLoader =
    Future<List<FixedColumnCandidate>> Function(int typeId);
typedef CustomerColumnCandidatesLoader =
    Future<List<CustomerColumnCandidate>> Function(int customerId);
typedef CustomerColumnSaveCallback =
    Future<void> Function(CustomerColumnSaveCommand command);

enum LabelColumnCandidateSource { fixed, customer }

class LabelColumnEditDialog extends StatefulWidget {
  const LabelColumnEditDialog({
    super.key,
    required this.labelSizeId,
    required this.customerId,
    required this.initialColumns,
    required this.canSave,
    required this.onSave,
    required this.onClose,
    this.loadFixedTypes = FixedColumnDAO.selectTypes,
    this.loadFixedCandidates = FixedColumnDAO.selectCandidates,
    this.loadCustomerCandidates = CustomerColumnDAO.selectByCustomerId,
    this.saveCustomerColumns = CustomerColumnDAO.save,
  });

  final int labelSizeId;
  final int customerId;
  final List<TColumn> initialColumns;
  final Future<bool> Function() canSave;
  final Future<void> Function(LabelColumnSaveCommand command) onSave;
  final VoidCallback onClose;
  final FixedColumnTypesLoader loadFixedTypes;
  final FixedColumnCandidatesLoader loadFixedCandidates;
  final CustomerColumnCandidatesLoader loadCustomerCandidates;
  final CustomerColumnSaveCallback saveCustomerColumns;

  @override
  State<LabelColumnEditDialog> createState() => _LabelColumnEditDialogState();
}

class _LabelColumnEditDialogState extends State<LabelColumnEditDialog> {
  late LabelColumnEditSession _session;
  LabelColumnCandidateSource _candidateSource = LabelColumnCandidateSource.fixed;
  List<FixedColumnType> _fixedTypes = const [];
  List<FixedColumnCandidate> _fixedCandidates = const [];
  List<CustomerColumnCandidate> _customerCandidates = const [];
  CustomerColumnEditSession? _customerSession;
  int? _fixedTypeId;
  String? _selectedCandidateKey;
  bool _busy = false;
  bool _loadingCandidates = true;
  int _draftSequence = 0;
  int _propertyRevision = 0;
  String? _editingCustomerKey;
  int? _customerScrollToIndex;
  bool _candidateTableDragging = false;
  bool _candidateTableFocused = false;
  bool _removeDropEating = false;

  bool get _exclusiveMode => _session.mode != LabelColumnEditMode.normal;
  bool get _normalEnabled => !_busy && !_exclusiveMode;
  List<TColumnType> get _columnTypes {
    final configured = TColumnType.datas;
    if (configured != null && configured.isNotEmpty) return configured;
    final byCode = <int, TColumnType>{
      for (final row in widget.initialColumns) row.columnType.code: row.columnType,
    };
    byCode.putIfAbsent(
      TColumnType.TYPE_BASE,
      () => const TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 0),
    );
    return byCode.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  void initState() {
    super.initState();
    _session = LabelColumnEditSession.fromColumns(
      labelSizeId: widget.labelSizeId,
      columns: List<TColumn>.unmodifiable(widget.initialColumns),
    );
    if (_session.selectedColumn != null) {
      _session = _session.beginPropertyEdit();
    }
    _loadInitialCandidates();
  }

  Future<void> _loadInitialCandidates() async {
    try {
      final types = await widget.loadFixedTypes();
      if (!mounted) return;
      final typeId = types.isEmpty ? null : types.first.id;
      final fixed = typeId == null
          ? const <FixedColumnCandidate>[]
          : await widget.loadFixedCandidates(typeId);
      final customer = await widget.loadCustomerCandidates(widget.customerId);
      if (!mounted) return;
      setState(() {
        _fixedTypes = types;
        _fixedTypeId = typeId;
        _fixedCandidates = fixed;
        _customerCandidates = customer;
        _loadingCandidates = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingCandidates = false);
      await _showMessage('후보 조회 실패', error.toString());
    }
  }

  Future<void> _changeFixedType(int? typeId) async {
    if (typeId == null || _busy) return;
    setState(() {
      _fixedTypeId = typeId;
      _selectedCandidateKey = null;
      _loadingCandidates = true;
    });
    try {
      final rows = await widget.loadFixedCandidates(typeId);
      if (!mounted || _fixedTypeId != typeId) return;
      setState(() {
        _fixedCandidates = rows;
        _loadingCandidates = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingCandidates = false);
      await _showMessage('후보 조회 실패', error.toString());
    }
  }

  Future<bool> _discardPendingProperty() async {
    final pending = _session.propertyDirty ||
        (_session.propertyBaseline != null &&
            _session.pendingInitialApplyColumnKeys.contains(
              _session.propertyBaseline!.key,
            ));
    if (!pending) return true;
    final discard = await _confirm(
      '미적용 속성',
      '적용하지 않은 속성 변경을 취소하고 계속하시겠습니까?',
      confirmText: '계속',
    );
    if (discard != true || !mounted) return false;
    setState(() => _session = _session.cancelProperty());
    return true;
  }

  Future<void> _selectColumn(String key) async {
    if (!_normalEnabled || key == _session.selectedColumnKey) return;
    if (!await _discardPendingProperty() || !mounted) return;
    setState(() {
      _session = _session.select(key).beginPropertyEdit();
      _propertyRevision += 1;
    });
  }

  void _updateProperty(TColumn column) {
    if (!_normalEnabled || _session.propertyDraft == null) return;
    setState(() {
      _session = _session.updatePropertyDraft(
        _session.propertyDraft!.copyWith(column: column),
      );
    });
  }

  Future<void> _applyProperty() async {
    if (!_normalEnabled) return;
    try {
      setState(() {
        _session = _session.applyProperty();
        if (_session.selectedColumn != null) {
          _session = _session.beginPropertyEdit();
        }
        _propertyRevision += 1;
      });
    } catch (error) {
      await _showMessage('입력 확인', error.toString());
    }
  }

  void _cancelProperty() {
    if (!_normalEnabled) return;
    setState(() {
      _session = _session.cancelProperty();
      if (_session.selectedColumn != null) {
        _session = _session.beginPropertyEdit();
      }
      _propertyRevision += 1;
    });
  }

  bool _candidateDisabled(String keyword) {
    final normalized = keyword.trim().toUpperCase();
    return LabelColumnLimits.reservedKeywords.contains(normalized) ||
        _session.workingColumns.any(
          (row) => row.column.keyword.trim().toUpperCase() == normalized,
        );
  }

  Future<void> _addSelectedCandidate() async {
    if (!_normalEnabled || !await _discardPendingProperty() || !mounted) return;
    final candidate = _selectedCandidate;
    if (candidate == null || _candidateDisabled(candidate.keyword)) return;
    try {
      final draft = LabelColumnDraft.fromCandidate(
        draftKey: 'dialog-draft:${++_draftSequence}',
        labelSizeId: widget.labelSizeId,
        order: _session.workingColumns.length + 1,
        columnType: candidate.columnType,
        keyword: candidate.keyword,
        columnName: candidate.columnName,
      );
      setState(() => _session = _session.add(draft));
    } catch (error) {
      await _showMessage('항목 추가 실패', error.toString());
    }
  }

  _CandidateValue? get _selectedCandidate {
    final key = _selectedCandidateKey;
    if (key == null) return null;
    if (_candidateSource == LabelColumnCandidateSource.fixed) {
      for (final row in _fixedCandidates) {
        if ('fixed:${row.id}' == key) {
          return _CandidateValue(
            key,
            row.columnType,
            row.keyword,
            row.columnName,
          );
        }
      }
    } else {
      for (final row in _customerCandidates) {
        if ('customer:${row.id}' == key) {
          return _CandidateValue(
            key,
            row.columnType,
            row.keyword,
            row.columnName,
          );
        }
      }
    }
    return null;
  }

  Future<void> _removeSelectedColumn() async {
    final key = _session.selectedColumnKey;
    if (key == null) return;
    await _removeColumn(key);
  }

  Future<void> _removeColumn(String key) async {
    if (!_normalEnabled) return;
    if (!await _discardPendingProperty() || !mounted) return;
    setState(() {
      _session = _session.remove(key);
      if (_session.selectedColumn != null) {
        _session = _session.beginPropertyEdit();
      }
    });
  }

  Future<void> _acceptUsedColumnDrop(String key) async {
    if (!_normalEnabled || _removeDropEating) return;
    setState(() => _removeDropEating = true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _removeColumn(key);
    if (mounted) setState(() => _removeDropEating = false);
  }

  Future<void> _enterReorder() async {
    if (!_normalEnabled || !await _discardPendingProperty() || !mounted) return;
    setState(() => _session = _session.enterReorder());
  }

  void _moveSelected(int delta) {
    if (_busy || _session.mode != LabelColumnEditMode.reorder) return;
    final key = _session.selectedColumnKey;
    final index = _session.workingColumns.indexWhere((row) => row.key == key);
    if (index < 0) return;
    setState(() => _session = _session.reorder(key!, index + delta));
  }

  void _cancelReorder() {
    if (_busy) return;
    setState(() {
      _session = _session.cancelReorder();
      if (_session.selectedColumn != null) {
        _session = _session.beginPropertyEdit();
      }
    });
  }

  void _applyReorder() {
    if (_busy) return;
    setState(() {
      _session = _session.applyReorder();
      if (_session.selectedColumn != null) {
        _session = _session.beginPropertyEdit();
      }
    });
  }

  Future<void> _enterUserEdit() async {
    if (!_normalEnabled || !await _discardPendingProperty() || !mounted) return;
    setState(() {
      _session = _session.enterUserItemEdit();
      _customerSession = CustomerColumnEditSession.fromCandidates(
        customerId: widget.customerId,
        candidates: _customerCandidates,
      );
    });
  }

  void _cancelUserEdit() {
    if (_busy) return;
    setState(() {
      _customerSession = null;
      _editingCustomerKey = null;
      _customerScrollToIndex = null;
      _session = _session.exitUserItemEdit();
      if (_session.selectedColumn != null) {
        _session = _session.beginPropertyEdit();
      }
    });
  }

  void _addCustomerRow() {
    if (_busy || _customerSession == null) return;
    final row = CustomerColumnDraft.empty(
      key: 'customer-draft:${++_draftSequence}',
      customerId: widget.customerId,
      columnType: _columnTypes.first,
    );
    setState(() {
      _customerSession = _customerSession!.add(row);
      _editingCustomerKey = row.key;
      _customerScrollToIndex = _customerSession!.working.length - 1;
    });
  }

  void _updateCustomerRow(CustomerColumnDraft row) {
    if (_busy || _customerSession == null) return;
    setState(() => _customerSession = _customerSession!.update(row));
  }

  void _removeCustomerRow(String key) {
    if (_busy || _customerSession == null) return;
    setState(() {
      _customerSession = _customerSession!.remove(key);
      if (_editingCustomerKey == key) _editingCustomerKey = null;
    });
  }

  void _selectCustomerRow(String key) {
    if (_busy || _customerSession == null) return;
    setState(() {
      _customerSession = _customerSession!.select(key);
      if (_editingCustomerKey != key) _editingCustomerKey = null;
    });
  }

  void _editCustomerRow(String key) {
    if (_busy || _customerSession == null) return;
    setState(() {
      _customerSession = _customerSession!.select(key);
      _editingCustomerKey = key;
    });
  }

  Future<void> _saveCustomerRows() async {
    if (_busy || _customerSession == null) return;
    CustomerColumnSaveCommand command;
    try {
      command = _customerSession!.toSaveCommand();
    } catch (error) {
      await _showMessage('입력 확인', error.toString());
      return;
    }
    if (command.newColumns.isEmpty &&
      command.updatedColumns.isEmpty &&
      command.deletedIds.isEmpty) {
      _cancelUserEdit();
      return;
    }
    final confirmed = await _confirm(
      '사용자 항목 저장',
      '사용자 항목 사전의 변경 내용을 저장하시겠습니까? 삭제해도 이미 추가된 사용 항목은 삭제되지 않습니다.',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.saveCustomerColumns(command);
      final reloaded = await widget.loadCustomerCandidates(widget.customerId);
      if (!mounted) return;
      setState(() {
        _customerCandidates = reloaded;
        _customerSession = null;
        _editingCustomerKey = null;
        _customerScrollToIndex = null;
        _session = _session.exitUserItemEdit();
        _busy = false;
        if (_session.selectedColumn != null) {
          _session = _session.beginPropertyEdit();
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _showMessage('사용자 항목 저장 실패', error.toString());
    }
  }

  Future<void> _save() async {
    if (!_normalEnabled || !_session.workingDirty) return;
    if (!await _discardPendingProperty() || !mounted) return;
    LabelColumnSaveCommand command;
    try {
      command = _session.toSaveCommand();
    } catch (error) {
      await _showMessage('입력 확인', error.toString());
      return;
    }
    setState(() => _busy = true);
    try {
      final allowed = await widget.canSave();
      if (!mounted) return;
      if (!allowed) {
        setState(() => _busy = false);
        await _showMessage('저장할 수 없음', '상위 화면의 미저장 작업을 먼저 완료하세요.');
        return;
      }
      final confirmed = await _confirm(
        '라벨 항목 저장',
        '추가, 수정, 삭제와 순서 변경을 저장하시겠습니까? 기존 라벨 내용과 출력 참조에 영향을 줄 수 있습니다.',
      );
      if (confirmed != true || !mounted) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      await widget.onSave(command);
      if (mounted) widget.onClose();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _showMessage('라벨 항목 저장 실패', error.toString());
    }
  }

  Future<void> _requestClose() async {
    if (_busy || _exclusiveMode) return;
    if (!await _discardPendingProperty() || !mounted) return;
    if (_session.workingDirty) {
      final discard = await _confirm('변경 내용 취소', '저장하지 않은 변경 내용을 버리시겠습니까?', confirmText: '버리기');
      if (discard != true || !mounted) return;
    }
    widget.onClose();
  }

  Future<bool?> _confirm(
    String title,
    String message, {
    String confirmText = '확인',
  }) {
    return showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          FilledButton(onPressed: () => close(true), child: Text(confirmText)),
        ],
      ),
    );
  }

  Future<void> _showMessage(String title, String message) {
    return showBlockingModelessOverlayDialog<void>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => close(null), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 56).clamp(320.0, 1168.0);
    final height = (screen.height - 64).clamp(320.0, 720.0);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontSizeDelta: -1),
        primaryTextTheme: theme.primaryTextTheme.apply(fontSizeDelta: -1),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.escape): _CloseIntent(),
        },
        child: Actions(
          actions: {
            _CloseIntent: CallbackAction<_CloseIntent>(
              onInvoke: (_) => _requestClose(),
            ),
          },
          child: BlockingModelessDialogFrame(
            key: const Key('label-column-edit-dialog'),
            title: '라벨 항목 편집',
            width: width,
            height: height,
            closeEnabled: !_busy && !_exclusiveMode,
            onClose: _requestClose,
            footer: _buildMainFooter(),
            child: LayoutBuilder(
              builder: (context, constraints) => Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < 1028
                        ? 1028
                        : constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 282, child: _buildPropertyPanel()),
                          const VerticalDivider(width: 14),
                          Expanded(flex: 5, child: _buildUsedColumns()),
                          SizedBox(width: 48, child: _buildCommandRail()),
                          Expanded(flex: 4, child: _buildCandidates()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainFooter() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x22000000)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_busy) ...[
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
          ],
          OutlinedButton(
            key: const Key('label-column-main-cancel'),
            onPressed: _normalEnabled ? _requestClose : null,
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('label-column-main-save'),
            onPressed: _normalEnabled && _session.workingDirty ? _save : null,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsedColumns() {
    final userEdit = _session.mode == LabelColumnEditMode.userItemEdit;
    final selectedIndex = _session.workingColumns.indexWhere(
      (row) => row.key == _session.selectedColumnKey,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Text('사용 항목', style: TextStyle(fontWeight: FontWeight.w700))),
            IconButton(
              key: const Key('label-column-reorder'),
              tooltip: '순서 변경',
              iconSize: 22,
              constraints: const BoxConstraints.tightFor(
                width: 38,
                height: 38,
              ),
              onPressed: _normalEnabled ? _enterReorder : null,
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
        Expanded(
          child: DragTarget<_ColumnDragPayload>(
            onWillAcceptWithDetails: (_) => _normalEnabled,
            onAcceptWithDetails: (_) => _addSelectedCandidate(),
            builder: (context, candidateData, rejectedData) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: candidateData.isEmpty ? Colors.transparent : Theme.of(context).colorScheme.primary),
              ),
              child: IgnorePointer(
                ignoring: userEdit,
                child: Opacity(
                  opacity: userEdit ? 0.55 : 1,
                  child: SwipeActionTable<LabelColumnDraft>(
                key: const Key('label-column-used-table'),
                rows: _session.workingColumns,
                rowNumberWidth: 34,
                autoFitColumns: false,
                fillLastColumn: true,
                selectedIndex: selectedIndex < 0 ? null : selectedIndex,
                rowReorderEnabled: !_busy && _session.mode == LabelColumnEditMode.reorder,
                rowDragDataBuilder: (row, index) => _normalEnabled
                    ? _UsedColumnDragPayload(row.key)
                    : null,
                onRowSelected: userEdit
                    ? null
                    : (row, index) {
                        if (_session.mode == LabelColumnEditMode.reorder && !_busy) {
                          setState(() => _session = _session.reorder(row.key, index));
                        } else {
                          _selectColumn(row.key);
                        }
                      },
                onRowReorder: (fromIndex, toIndex) {
                  if (_session.mode != LabelColumnEditMode.reorder || _busy) return;
                  final key = _session.workingColumns[fromIndex].key;
                  setState(() => _session = _session.reorder(key, toIndex));
                },
                columns: [
                  SwipeActionTableColumn(header: '상태', initialWidth: 44, minWidth: 40, text: (row) => row.isNew ? '신규' : ''),
                  SwipeActionTableColumn(header: '키워드', initialWidth: 78, minWidth: 64, text: (row) => row.column.keyword),
                  SwipeActionTableColumn(header: '항목명', initialWidth: 75, minWidth: 63, text: (row) => row.column.columnName),
                  SwipeActionTableColumn(header: '종류', initialWidth: 71, minWidth: 59, fillRemaining: true, text: (row) => row.column.columnType.name),
                  SwipeActionTableColumn(header: '제목', initialWidth: 58, minWidth: 48, text: (row) => row.column.title),
                  SwipeActionTableColumn(
                    header: '표시',
                    initialWidth: 44,
                    minWidth: 44,
                    text: (row) => row.column.visible ? '예' : '아니오',
                    cellBuilder: (context, row, width) => SizedBox(
                      width: width,
                      child: Center(
                        child: IgnorePointer(
                          child: Checkbox(
                            value: row.column.visible,
                            onChanged: (_) {},
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_session.mode == LabelColumnEditMode.reorder)
          _ModeFooter(
            label: '순서 변경',
            cancelKey: const Key('label-column-reorder-cancel'),
            saveKey: const Key('label-column-reorder-apply'),
            onCancel: _busy ? null : _cancelReorder,
            onSave: _busy ? null : _applyReorder,
          ),
      ],
    );
  }

  Widget _buildCommandRail() {
    final userEdit = _session.mode == LabelColumnEditMode.userItemEdit;
    final selectedCustomerKey = _customerSession?.selectedKey;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DragTarget<Object>(
          onWillAcceptWithDetails: (details) => userEdit
              ? details.data is _CustomerColumnDragPayload && !_busy
              : details.data is _UsedColumnDragPayload && _normalEnabled,
          onAcceptWithDetails: (details) {
            final data = details.data;
            if (userEdit && data is _CustomerColumnDragPayload) {
              _removeCustomerRow(data.key);
            } else if (data is _UsedColumnDragPayload) {
              _acceptUsedColumnDrop(data.key);
            }
          },
          builder: (context, candidateData, rejectedData) => AnimatedScale(
            key: const Key('label-column-remove-drop-animation'),
            scale: _removeDropEating ? 0.72 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeInBack,
            child: IconButton(
              key: const Key('label-column-remove'),
              tooltip: '사용 항목 삭제',
              iconSize: 22,
              constraints: const BoxConstraints.tightFor(
                width: 38,
                height: 38,
              ),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                disabledBackgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: userEdit
                ? selectedCustomerKey == null || _busy
                    ? null
                    : () => _removeCustomerRow(selectedCustomerKey)
                : _normalEnabled &&
                      !_candidateTableDragging &&
                      !_candidateTableFocused &&
                      _session.selectedColumnKey != null
                ? _removeSelectedColumn
                : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
        const SizedBox(height: 10),
        IconButton(
          key: const Key('label-column-add'),
          tooltip: '선택 후보 추가',
          iconSize: 22,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            disabledBackgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: _normalEnabled &&
              !_candidateTableDragging &&
              _selectedCandidate != null &&
              !_candidateDisabled(_selectedCandidate!.keyword)
              ? _addSelectedCandidate
              : null,
          icon: const Icon(Icons.arrow_back),
        ),
        if (_session.mode == LabelColumnEditMode.reorder) ...[
          const SizedBox(height: 24),
          IconButton(
            key: const Key('label-column-move-up'),
            tooltip: '위로 이동',
            onPressed: _busy ? null : () => _moveSelected(-1),
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            key: const Key('label-column-move-down'),
            tooltip: '아래로 이동',
            onPressed: _busy ? null : () => _moveSelected(1),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ],
    );
  }

  Widget _buildCandidates() {
    final userEdit = _session.mode == LabelColumnEditMode.userItemEdit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<LabelColumnCandidateSource>(
          key: const Key('label-column-candidate-source'),
          segments: const [
            ButtonSegment(value: LabelColumnCandidateSource.fixed, label: Text('고정 항목')),
            ButtonSegment(value: LabelColumnCandidateSource.customer, label: Text('사용자 항목')),
          ],
          selected: {_candidateSource},
          onSelectionChanged: _normalEnabled
              ? (value) => setState(() {
                    _candidateSource = value.single;
                    _selectedCandidateKey = null;
                  })
              : null,
        ),
        const SizedBox(height: 8),
        if (_candidateSource == LabelColumnCandidateSource.fixed)
          _DialogDropdown<int>(
            key: const Key('label-column-fixed-type'),
            label: '분류',
            value: _fixedTypeId,
            entries: [
              for (final type in _fixedTypes)
                DropdownMenuEntry(value: type.id, label: type.name),
            ],
            onChanged: _normalEnabled ? _changeFixedType : null,
          )
        else
          Row(
            children: [
              const Expanded(child: Text('고객별 사용자 항목')),
              IconButton(
                key: const Key('label-column-user-edit'),
                tooltip: '사용자 항목 설정',
                iconSize: 22,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
                onPressed: _normalEnabled ? _enterUserEdit : null,
                icon: const Icon(Icons.edit),
              ),
              if (userEdit)
                IconButton(
                  key: const Key('label-column-user-add'),
                  tooltip: '사용자 항목 추가',
                  iconSize: 22,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  onPressed: _busy ? null : _addCustomerRow,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingCandidates
              ? const Center(child: CircularProgressIndicator())
              : userEdit
                  ? _buildCustomerEditor()
                  : _buildCandidateList(),
        ),
        if (userEdit)
          _ModeFooter(
            label: '사용자 항목 설정',
            cancelKey: const Key('label-column-user-cancel'),
            saveKey: const Key('label-column-user-save'),
            onCancel: _busy ? null : _cancelUserEdit,
            onSave: _busy || !(_customerSession?.isDirty ?? false) ? null : _saveCustomerRows,
          ),
      ],
    );
  }

  Widget _buildCandidateList() {
    final values = _candidateSource == LabelColumnCandidateSource.fixed
        ? [
            for (final row in _fixedCandidates)
              _CandidateValue(
                'fixed:${row.id}',
                row.columnType,
                row.keyword,
                row.columnName,
              ),
          ]
        : [
            for (final row in _customerCandidates)
              _CandidateValue(
                'customer:${row.id}',
                row.columnType,
                row.keyword,
                row.columnName,
              ),
          ];
    if (values.isEmpty) return const Center(child: Text('후보가 없습니다.'));
    final selectedIndex = values.indexWhere(
      (row) => row.key == _selectedCandidateKey,
    );
    return SwipeActionTable<_CandidateValue>(
      key: const Key('label-column-candidate-list'),
      rows: values,
      rowNumberWidth: 34,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      headerHeight: 34,
      rowHeight: 27,
      rowColorBuilder: (row, index, selected) =>
          _candidateDisabled(row.keyword)
          ? Theme.of(context).disabledColor.withValues(alpha: 0.08)
          : selected
          ? const Color(0xFFE3F2FD)
          : index.isEven
          ? Colors.white
          : const Color(0xFFF2F4F7),
      onRowSelected: (row, index) {
        if (!_normalEnabled || _candidateDisabled(row.keyword)) return;
        setState(() => _selectedCandidateKey = row.key);
      },
      rowDragDataBuilder: (row, index) =>
          _normalEnabled && !_candidateDisabled(row.keyword)
          ? _ColumnDragPayload(row.key)
          : null,
      onRowDragStarted: (row, index) =>
          setState(() {
            _selectedCandidateKey = row.key;
            _candidateTableDragging = true;
          }),
      onRowDragEnded: (_, _) => setState(() => _candidateTableDragging = false),
      onFocusChanged: (focused) {
        if (_candidateTableFocused == focused) return;
        setState(() => _candidateTableFocused = focused);
      },
      columns: [
        SwipeActionTableColumn(
          header: '키워드',
          initialWidth: 105,
          text: (row) => row.keyword,
        ),
        SwipeActionTableColumn(
          header: '항목명',
          initialWidth: 111,
          text: (row) => row.columnName,
        ),
        SwipeActionTableColumn(
          header: '종류',
          initialWidth: 80,
          text: (row) => row.columnType.name,
        ),
      ],
    );
  }

  Widget _buildCustomerEditor() {
    final rows = _customerSession?.working ?? const <CustomerColumnDraft>[];
    final selectedIndex = rows.indexWhere(
      (row) => row.key == _customerSession?.selectedKey,
    );
    return SwipeActionTable<CustomerColumnDraft>(
      key: const Key('label-column-user-editor'),
      rows: rows,
      rowNumberWidth: 34,
      headerHeight: 34,
      rowHeight: 28,
      autoFitColumns: false,
      fillLastColumn: true,
      scrollToIndex: _customerScrollToIndex,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      onRowSelected: (row, _) => _selectCustomerRow(row.key),
      isRowContentInteractive: (row, _) => row.key == _editingCustomerKey,
      isCellContentInteractive: (_, _, columnIndex) => columnIndex == 2,
      columns: [
        SwipeActionTableColumn(
          header: '키워드',
          initialWidth: 105,
          minWidth: 80,
          text: (row) => row.keyword,
          cellBuilder: (context, row, width) => _buildCustomerTextCell(
            row: row,
            width: width,
            value: row.keyword,
            key: ValueKey('customer-keyword:${row.key}'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(100),
            ],
            onChanged: (value) =>
                _updateCustomerRow(row.copyWith(keyword: value)),
          ),
          onDoubleTap: (row, _) => _editCustomerRow(row.key),
        ),
        SwipeActionTableColumn(
          header: '항목명',
          initialWidth: 111,
          minWidth: 80,
          text: (row) => row.columnName,
          cellBuilder: (context, row, width) => _buildCustomerTextCell(
            row: row,
            width: width,
            value: row.columnName,
            key: ValueKey('customer-name:${row.key}'),
            onChanged: (value) =>
                _updateCustomerRow(row.copyWith(columnName: value)),
          ),
          onDoubleTap: (row, _) => _editCustomerRow(row.key),
        ),
        SwipeActionTableColumn(
          header: '종류',
          initialWidth: 80,
          minWidth: 70,
          text: (row) => row.columnType.name,
          cellBuilder: (context, row, width) => SizedBox(
            width: width,
            child: _DialogDropdown<TColumnType>(
              value: row.columnType,
              compact: true,
              entries: [
                for (final type in _columnTypes)
                  DropdownMenuEntry(value: type, label: type.name),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        _updateCustomerRow(row.copyWith(columnType: value));
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerTextCell({
    required CustomerColumnDraft row,
    required double width,
    required String value,
    required Key key,
    required ValueChanged<String> onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    if (row.key == _editingCustomerKey) {
      return SizedBox(
        width: width,
        child: TextFormField(
          key: key,
          initialValue: value,
          enabled: !_busy,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 6),
          ),
          inputFormatters: inputFormatters,
          onChanged: onChanged,
        ),
      );
    }
    return Draggable<_CustomerColumnDragPayload>(
      data: _CustomerColumnDragPayload(row.key),
      maxSimultaneousDrags: _busy ? 0 : 1,
      feedback: Material(
        elevation: 4,
        child: SizedBox(
          width: width,
          height: 28,
          child: _customerText(value, width),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: _customerText(value, width),
      ),
      onDragStarted: () => _selectCustomerRow(row.key),
      child: _customerText(value, width),
    );
  }

  Widget _customerText(String value, double width) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ),
  );

  Widget _buildPropertyPanel() {
    final draft = _session.propertyDraft;
    final enabled = _normalEnabled && draft != null;
    return Material(
      color: Colors.white.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('속성', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: draft == null
                ? const Center(child: Text('사용 항목을 선택하세요.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: _PropertyFields(
                      key: ValueKey('property:${draft.key}:$_propertyRevision'),
                      column: draft.column,
                      columnTypes: _columnTypes,
                      enabled: enabled,
                      onChanged: _updateProperty,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('label-column-property-cancel'),
                  onPressed: enabled ? _cancelProperty : null,
                  child: const Text('취소'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  key: const Key('label-column-property-apply'),
                  onPressed: enabled && (_session.propertyDirty || _session.pendingInitialApplyColumnKeys.contains(draft.key))
                      ? _applyProperty
                      : null,
                  child: const Text('적용'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyFields extends StatelessWidget {
  const _PropertyFields({
    super.key,
    required this.column,
    required this.columnTypes,
    required this.enabled,
    required this.onChanged,
  });

  final TColumn column;
  final List<TColumnType> columnTypes;
  final bool enabled;
  final ValueChanged<TColumn> onChanged;

  Widget _field(Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: SizedBox(height: 40, child: child),
  );

  Widget _text(String label, String value, ValueChanged<String> changed, {Key? key}) {
    return _field(
      TextFormField(
        key: key,
        initialValue: value,
        enabled: enabled,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: changed,
      ),
    );
  }

  Widget _integer(String label, int value, ValueChanged<int> changed) {
    return _text(label, '$value', (text) => changed(int.tryParse(text) ?? 0));
  }

  Widget _check(String label, bool value, ValueChanged<bool> changed) {
    return _field(
      CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: enabled ? (next) => changed(next ?? false) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _text('키워드', column.keyword, (value) => onChanged(column.copyWith(keyword: value.trim().toUpperCase())), key: const Key('label-column-keyword')),
        _text('항목명', column.columnName, (value) => onChanged(column.copyWith(columnName: value)), key: const Key('label-column-name')),
        _field(
          _DialogDropdown<TColumnType>(
            key: const Key('label-column-type'),
            label: '항목 종류',
            value: columnTypes.where((type) => type.code == column.columnType.code).firstOrNull,
            entries: [
              for (final type in columnTypes)
                DropdownMenuEntry(value: type, label: type.name),
            ],
            onChanged: enabled ? (value) { if (value != null) onChanged(_changeType(column, value)); } : null,
          ),
        ),
        _text('제목', column.title, (value) => onChanged(column.copyWith(title: value))),
        _check('표시', column.visible, (value) => onChanged(column.copyWith(visible: value))),
        _check('누락 키워드 검사', column.useMissingKeywordCheck, (value) => onChanged(column.copyWith(useMissingKeywordCheck: value))),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Divider(height: 1),
        ),
        ..._typeFields(),
      ],
    );
  }

  List<Widget> _typeFields() {
    switch (column.columnType.code) {
      case TColumnType.TYPE_BARCODE:
        return [
          _barcodeDropdown(),
          _integer('폭', column.width, (value) => onChanged(column.copyWith(width: value))),
          _integer('높이', column.height, (value) => onChanged(column.copyWith(height: value))),
          _check('체크디지트 사용', column.useBarcodeCheckDigit, (value) => onChanged(column.copyWith(useBarcodeCheckDigit: value))),
          _check('번호 표시', column.showBarcodeNum, (value) => onChanged(column.copyWith(showBarcodeNum: value))),
          _check('비율 조절', column.showQRCodeText, (value) => onChanged(column.copyWith(showQRCodeText: value))),
          _integer('비율', column.qrTextFontSize, (value) => onChanged(column.copyWith(qrTextFontSize: value))),
          _integer('타임바코드', column.timeBarcodeType, (value) => onChanged(column.copyWith(timeBarcodeType: value))),
          ..._autoFields(),
          _text('사용자 정의 text', column.userDefineBarcodeText, (value) => onChanged(column.copyWith(userDefineBarcodeText: value))),
          _integer('Line check', column.lineCheck, (value) => onChanged(column.copyWith(lineCheck: value))),
          _integer('Line size', column.lineSize, (value) => onChanged(column.copyWith(lineSize: value))),
          _integer('회전', column.rotate, (value) => onChanged(column.copyWith(rotate: value))),
        ];
      case TColumnType.TYPE_IMAGE:
        return [
          _integer('폭', column.width, (value) => onChanged(column.copyWith(width: value))),
          _integer('높이', column.height, (value) => onChanged(column.copyWith(height: value))),
        ];
      case TColumnType.TYPE_QR_CODE:
        return [
          _barcodeDropdown(),
          _field(
            _DialogDropdown<QRCodeCreateType>(
              label: '생성 방식',
              value: column.qrCodeCreateType,
              entries: [
                for (final type in QRCodeCreateType.values)
                  DropdownMenuEntry(value: type, label: type.name),
              ],
              onChanged: enabled ? (value) { if (value != null) onChanged(column.copyWith(qrCodeCreateType: value)); } : null,
            ),
          ),
          _check('사용자 정의 data', column.useUserDefineQRData, (value) => onChanged(column.copyWith(useUserDefineQRData: value))),
          _text('QR data', column.userDefineQRData, (value) => onChanged(column.copyWith(userDefineQRData: value))),
          _text('하단 text', column.userDefineQRText, (value) => onChanged(column.copyWith(userDefineQRText: value))),
          _text('나트륨 조합', column.natriumJoinString, (value) => onChanged(column.copyWith(natriumJoinString: value))),
          _integer('Pixel size', column.pixelSize, (value) => onChanged(column.copyWith(pixelSize: value))),
          _integer('Scale', column.qrCodeScalePercent, (value) => onChanged(column.copyWith(qrCodeScalePercent: value))),
          _check('하단 text 표시', column.showQRCodeText, (value) => onChanged(column.copyWith(showQRCodeText: value))),
          _field(
            _DialogDropdown<QRTextAlignment>(
              label: '정렬',
              value: column.qrTextAlignment,
              entries: [
                for (final value in QRTextAlignment.values)
                  DropdownMenuEntry(value: value, label: value.name),
              ],
              onChanged: enabled ? (value) { if (value != null) onChanged(column.copyWith(qrTextAlignment: value)); } : null,
            ),
          ),
          _text('글꼴', column.qrTextFontName, (value) => onChanged(column.copyWith(qrTextFontName: value))),
          _integer('글꼴 크기', column.qrTextFontSize, (value) => onChanged(column.copyWith(qrTextFontSize: value))),
          ..._autoFields(),
        ];
      case TColumnType.TYPE_GS1_AI:
        return [
          _text('AI code', column.gs1ai, (value) => onChanged(column.copyWith(gs1ai: value))),
          _integer('Format option', column.formatOption, (value) => onChanged(column.copyWith(formatOption: value))),
          _check('GS1 code 표시', column.showGS1Code, (value) => onChanged(column.copyWith(showGS1Code: value))),
        ];
      case TColumnType.TYPE_GS1_BARCODE:
        return [
          _barcodeDropdown(),
          _integer('폭', column.width, (value) => onChanged(column.copyWith(width: value))),
          _integer('높이', column.height, (value) => onChanged(column.copyWith(height: value))),
          _text('포함 GS1 AI 키워드', column.containColumns, (value) => onChanged(column.copyWith(containColumns: value))),
          _check('GS1 code 사용', column.useGS1Code, (value) => onChanged(column.copyWith(useGS1Code: value))),
        ];
      case TColumnType.TYPE_VALIDDATE:
      case TColumnType.TYPE_VALIDTIME:
      case TColumnType.TYPE_MAKEDATE:
      case TColumnType.TYPE_MAKETIME:
        return [
          ..._autoFields(),
          _check('날짜 범위 사용', column.useDateRange, (value) => onChanged(column.copyWith(useDateRange: value))),
          _text('날짜 범위', column.dateRange, (value) => onChanged(column.copyWith(dateRange: value))),
        ];
      default:
        return [
          ..._autoFields(),
          _check('검색 출력', column.searchPrint, (value) => onChanged(column.copyWith(searchPrint: value))),
          _text('사용자 정의 text', column.userDefineBarcodeText, (value) => onChanged(column.copyWith(userDefineBarcodeText: value))),
        ];
    }
  }

  List<Widget> _autoFields() => [
    _check('자동 증가', column.autoInc, (value) => onChanged(column.copyWith(autoInc: value))),
    _integer('자동 증가 크기', column.autoIncSize, (value) => onChanged(column.copyWith(autoIncSize: value))),
    _check('자동 증가 저장', column.autoIncSave, (value) => onChanged(column.copyWith(autoIncSave: value))),
    _integer('자동 증가 범위', column.autoIncRange, (value) => onChanged(column.copyWith(autoIncRange: value))),
    _check('앞자리 0 제거', column.autoIncZeroDel, (value) => onChanged(column.copyWith(autoIncZeroDel: value))),
    _check('자동 증가 갱신', column.autoIncUpdate, (value) => onChanged(column.copyWith(autoIncUpdate: value))),
  ];

  Widget _barcodeDropdown() {
    return _field(
      _DialogDropdown<BarcodeType>(
        label: '바코드 종류',
        value: column.barcodeType,
        entries: [
          for (final type in BarcodeType.values)
            DropdownMenuEntry(value: type, label: type.dbName),
        ],
        onChanged: enabled ? (value) { if (value != null) onChanged(column.copyWith(barcodeType: value)); } : null,
      ),
    );
  }

  static TColumn _changeType(TColumn column, TColumnType type) {
    final crossesQrBoundary = (column.columnType.code == TColumnType.TYPE_BASE) !=
        (type.code == TColumnType.TYPE_BASE) &&
        (column.columnType.code == TColumnType.TYPE_QR_CODE || type.code == TColumnType.TYPE_QR_CODE);
    if (!crossesQrBoundary) return column.copyWith(columnType: type);
    return column.copyWith(
      columnType: type,
      qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
      useUserDefineQRData: false,
      userDefineQRData: '',
      userDefineQRText: '',
      natriumJoinString: '',
    );
  }
}

class _DialogDropdown<T> extends StatelessWidget {
  const _DialogDropdown({
    super.key,
    this.label,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.compact = false,
  });

  final String? label;
  final T? value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<T>(
        width: constraints.maxWidth,
        initialSelection: value,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        label: label == null ? null : Text(label!),
        dropdownMenuEntries: entries,
        enabled: onChanged != null,
        enableFilter: false,
        enableSearch: false,
        requestFocusOnTap: false,
        trailingIcon: _dropdownIcon(compact),
        selectedTrailingIcon: _dropdownIcon(compact),
        menuStyle: const MenuStyle(
          visualDensity: VisualDensity(horizontal: -1, vertical: -3),
          minimumSize: WidgetStatePropertyAll(Size(0, 36)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: BoxConstraints.tightFor(height: compact ? 28 : 40),
          suffixIconConstraints: BoxConstraints.tightFor(
            width: 32,
            height: compact ? 28 : 40,
          ),
        ),
        onSelected: onChanged,
      ),
    );
  }

  Widget _dropdownIcon(bool compact) => SizedBox(
    width: 32,
    height: compact ? 28 : 40,
    child: Transform.translate(
      offset: Offset(0, compact ? -0.5 : 0),
      child: const Center(child: Icon(Icons.arrow_drop_down, size: 20)),
    ),
  );
}

class _ModeFooter extends StatelessWidget {
  const _ModeFooter({
    required this.label,
    required this.cancelKey,
    required this.saveKey,
    required this.onCancel,
    required this.onSave,
  });

  final String label;
  final Key cancelKey;
  final Key saveKey;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(key: cancelKey, onPressed: onCancel, child: const Text('취소')),
          const SizedBox(width: 6),
          FilledButton(key: saveKey, onPressed: onSave, child: const Text('저장')),
        ],
      ),
    );
  }
}

class _CandidateValue {
  const _CandidateValue(
    this.key,
    this.columnType,
    this.keyword,
    this.columnName,
  );

  final String key;
  final TColumnType columnType;
  final String keyword;
  final String columnName;
}

class _ColumnDragPayload {
  const _ColumnDragPayload(this.candidateKey);

  final String candidateKey;
}

class _UsedColumnDragPayload {
  const _UsedColumnDragPayload(this.key);

  final String key;
}

class _CustomerColumnDragPayload {
  const _CustomerColumnDragPayload(this.key);

  final String key;
}

class _CloseIntent extends Intent {
  const _CloseIntent();
}
