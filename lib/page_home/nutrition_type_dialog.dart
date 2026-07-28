import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef NutritionTypeListLoader = Future<List<NutritionType>> Function();
typedef NutritionTypeColumnsLoader =
    Future<List<NutritionTypeColumn>> Function(int typeId);
typedef NutritionTypeWriter =
    Future<void> Function(String name, List<NutritionTypeColumn> columns);
typedef NutritionTypeUpdater = Future<void> Function(
  int typeId,
  String name,
  List<NutritionTypeColumn> columns,
);
typedef NutritionTypeDeleter = Future<void> Function(int typeId);

@visibleForTesting
String nutritionTypeNextKeyword(List<NutritionTypeColumn> rows) {
  if (rows.isEmpty) {
    return 'N01';
  }
  final tail = rows.last.keyword;
  final suffix = tail.length >= 2 ? tail.substring(tail.length - 2) : '';
  final value = int.tryParse(suffix) ?? 0;
  return 'N${(value + 1).toString().padLeft(2, '0')}';
}

enum NutritionTypeEditorMode { create, edit }

class NutritionTypeDialogController extends ChangeNotifier {
  bool _writeBusy = false;
  bool _activeEditing = false;
  bool _childDirty = false;
  LifecycleExitAction? _discardChildDraft;
  bool _disposed = false;

  bool get writeBusy => _writeBusy;
  bool get activeEditing => _activeEditing;
  bool get childDirty => _childDirty;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '영양성분 형식 저장 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '영양성분 형식 편집을 먼저 완료한 뒤 다시 시도해주세요.'
        : null,
    dirtyWorks: [
      if (_childDirty && _discardChildDraft != null)
        LifecycleDirtyWork(name: '영양성분 형식추가', discard: _discardChildDraft!),
    ],
  );

  void setWriteBusy(bool value) {
    if (_disposed || _writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }

  void setActiveEditing(bool value) {
    if (_disposed || _activeEditing == value) return;
    _activeEditing = value;
    notifyListeners();
  }

  void setChildDirty({
    required bool dirty,
    required LifecycleExitAction discard,
  }) {
    if (_disposed) return;
    final changed = _childDirty != dirty || !identical(_discardChildDraft, discard);
    if (!changed) return;
    _childDirty = dirty;
    _discardChildDraft = discard;
    notifyListeners();
  }

  void clearChildDirty() {
    if (_disposed) return;
    if (!_childDirty && _discardChildDraft == null) return;
    _childDirty = false;
    _discardChildDraft = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class NutritionTypeDialogContent extends StatefulWidget {
  const NutritionTypeDialogContent({
    super.key,
    required this.controller,
    required this.onCommitOutcomeUnknown,
    this.loadTypes = NutritionTypeDAO.selectTypes,
    this.loadTypesById = NutritionTypeDAO.selectTypesById,
    this.loadColumns = NutritionTypeDAO.selectColumns,
    this.insert = NutritionTypeDAO.insert,
    this.update = NutritionTypeDAO.update,
    this.delete = NutritionTypeDAO.delete,
  });

  final NutritionTypeDialogController controller;
  final VoidCallback onCommitOutcomeUnknown;
  final NutritionTypeListLoader loadTypes;
  final NutritionTypeListLoader loadTypesById;
  final NutritionTypeColumnsLoader loadColumns;
  final NutritionTypeWriter insert;
  final NutritionTypeUpdater update;
  final NutritionTypeDeleter delete;

  @override
  State<NutritionTypeDialogContent> createState() =>
      _NutritionTypeDialogContentState();
}

class _NutritionTypeDialogContentState extends State<NutritionTypeDialogContent> {
  List<NutritionType> _types = const [];
  int? _selectedManagerIndex;
  bool _loading = true;

  NutritionTypeEditorMode? _editorMode;
  int? _editingTypeId;
  final TextEditingController _nameController = TextEditingController();
  final FortuneTableEditingController _detailEditingController =
      FortuneTableEditingController();
  List<NutritionTypeColumn> _detailRows = const [];
  int? _selectedDetailIndex;
  List<NutritionType> _templateTypes = const [];
  int? _selectedTemplateTypeId;
  String _baselineName = '';
  List<NutritionTypeColumn> _baselineRows = const [];

  bool get _inEditor => _editorMode != null;
  bool get _busy => _loading || widget.controller.writeBusy;
  bool get _detailEditingActive => _detailEditingController.hasActiveEditing;

  bool get _editorDirty {
    if (!_inEditor) return false;
    if (_baselineName != _nameController.text) return true;
    if (_baselineRows.length != _detailRows.length) return true;
    for (var index = 0; index < _detailRows.length; index += 1) {
      final left = _baselineRows[index];
      final right = _detailRows[index];
      if (left.keyword != right.keyword || left.name != right.name) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _detailEditingController.addListener(_syncControllerState);
    _reloadTypes(showError: true);
  }

  @override
  void dispose() {
    _detailEditingController.removeListener(_syncControllerState);
    _detailEditingController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _reloadTypes({required bool showError}) async {
    setState(() => _loading = true);
    try {
      final rows = await widget.loadTypes();
      if (!mounted) return;
      setState(() {
        _types = rows;
        _selectedManagerIndex = null;
      });
    } catch (error) {
      if (showError && mounted) {
        await _showMessage(error.toString());
      } else {
        rethrow;
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reloadTemplateTypes() async {
    final rows = await widget.loadTypesById();
    if (!mounted) return;
    setState(() {
      _templateTypes = rows;
      _selectedTemplateTypeId = null;
    });
  }

  Future<void> _openCreateEditor() async {
    if (_busy) return;
    setState(() {
      _editorMode = NutritionTypeEditorMode.create;
      _editingTypeId = null;
      _nameController.text = '';
      _detailRows = const [];
      _selectedDetailIndex = null;
      _baselineName = '';
      _baselineRows = const [];
      _templateTypes = const [];
      _selectedTemplateTypeId = null;
    });
    _syncControllerState();
    try {
      await _reloadTemplateTypes();
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    }
  }

  Future<void> _openModifyEditor() async {
    if (_busy) return;
    final selected = _selectedManagerType;
    if (selected == null) {
      await _showMessage('수정할 행을 먼저 선택해주세요!!');
      return;
    }
    setState(() => _loading = true);
    try {
      final details = await widget.loadColumns(selected.id);
      final templates = await widget.loadTypesById();
      if (!mounted) return;
      setState(() {
        _editorMode = NutritionTypeEditorMode.edit;
        _editingTypeId = selected.id;
        _nameController.text = selected.name;
        _detailRows = List<NutritionTypeColumn>.from(details);
        _selectedDetailIndex = null;
        _templateTypes = templates;
        _selectedTemplateTypeId = null;
        _baselineName = selected.name;
        _baselineRows = List<NutritionTypeColumn>.from(details);
      });
      _syncControllerState();
    } catch (error) {
      if (mounted) {
        await _showMessage(error.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  NutritionType? get _selectedManagerType {
    final index = _selectedManagerIndex;
    if (index == null || index < 0 || index >= _types.length) {
      return null;
    }
    return _types[index];
  }

  Future<void> _deleteSelected() async {
    if (_busy) return;
    final confirmed = await _showConfirmation(
      title: '영양성분 형식삭제',
      message: '해당 형식을 사용하는 영양성분표가 모두 삭제됩니다!\n정말 삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final selected = _selectedManagerType;
    if (selected == null) {
      await _showMessage('삭제할 행을 먼저 선택해주세요!!');
      return;
    }
    await _runWrite(
      write: () => widget.delete(selected.id),
      onSuccess: () async {
        await _reloadTypes(showError: false);
      },
    );
  }

  void _syncControllerState() {
    final activeEditing = _inEditor && _detailEditingActive;
    widget.controller.setActiveEditing(activeEditing);
    if (_inEditor) {
      widget.controller.setChildDirty(
        dirty: _editorDirty,
        discard: _discardEditorDraft,
      );
    } else {
      widget.controller.clearChildDirty();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _discardEditorDraft() async {
    if (!_inEditor) return;
    setState(() {
      _editorMode = null;
      _editingTypeId = null;
      _nameController.text = '';
      _detailRows = const [];
      _selectedDetailIndex = null;
      _selectedTemplateTypeId = null;
      _baselineName = '';
      _baselineRows = const [];
    });
    _syncControllerState();
  }

  Future<void> _closeEditor() async {
    await _discardEditorDraft();
    await _reloadTypes(showError: false);
  }

  Future<void> _changeTemplate(int? typeId) async {
    if (!_inEditor || _busy || typeId == null) return;
    try {
      final rows = await widget.loadColumns(typeId);
      if (!mounted) return;
      setState(() {
        _selectedTemplateTypeId = typeId;
        _detailRows = List<NutritionTypeColumn>.from(rows);
        _selectedDetailIndex = null;
      });
      _syncControllerState();
    } catch (error) {
      if (mounted) {
        await _showMessage(error.toString());
      }
    }
  }

  Future<void> _runWrite({
    required Future<void> Function() write,
    required Future<void> Function() onSuccess,
  }) async {
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    var committed = false;
    try {
      await write();
      committed = true;
      await onSuccess();
    } on DbCommitOutcomeUnknown catch (error) {
      if (mounted) {
        await _showMessage(error.toString());
      }
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

  void _addDetailRow() {
    if (!_inEditor || _busy) return;
    final row = NutritionTypeColumn(
      id: 0,
      keyword: nutritionTypeNextKeyword(_detailRows),
      name: '',
    );
    setState(() {
      _detailRows = [..._detailRows, row];
      _selectedDetailIndex = _detailRows.length - 1;
    });
    _syncControllerState();
  }

  Future<void> _deleteDetailRow() async {
    if (!_inEditor || _busy) return;
    final selectedIndex = _selectedDetailIndex;
    if (selectedIndex == null ||
        selectedIndex < 0 ||
        selectedIndex >= _detailRows.length) {
      await _showMessage('삭제할 행을 먼저 선택해주세요!!');
      return;
    }
    setState(() {
      final next = [..._detailRows]..removeAt(selectedIndex);
      _detailRows = next;
      _selectedDetailIndex = null;
    });
    _syncControllerState();
  }

  Future<void> _saveEditor() async {
    if (!_inEditor || _busy) return;
    if (_nameController.text.isEmpty) {
      await _showMessage('형식명을 입력해주세요!!');
      return;
    }
    if (_detailRows.isEmpty) {
      await _showMessage('영양성분 구성을 한 개 이상 입력해주세요!!');
      return;
    }

    final mode = _editorMode;
    if (mode == null) return;
    if (mode == NutritionTypeEditorMode.create) {
      await _runWrite(
        write: () => widget.insert(_nameController.text, _detailRows),
        onSuccess: () async {
          _baselineName = _nameController.text;
          _baselineRows = List<NutritionTypeColumn>.from(_detailRows);
          _syncControllerState();
        },
      );
      return;
    }

    final typeId = _editingTypeId;
    if (typeId == null) return;
    await _runWrite(
      write: () => widget.update(typeId, _nameController.text, _detailRows),
      onSuccess: () async {
        _baselineName = _nameController.text;
        _baselineRows = List<NutritionTypeColumn>.from(_detailRows);
        _syncControllerState();
      },
    );
  }

  void _updateDetailName(int index, String value) {
    if (!_inEditor || _busy || index < 0 || index >= _detailRows.length) {
      return;
    }
    final next = [..._detailRows];
    next[index] = next[index].copyWith(name: value);
    setState(() => _detailRows = next);
    _syncControllerState();
  }

  Future<bool?> _showConfirmation({
    required String title,
    required String message,
  }) {
    return showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (overlayContext, close) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          FilledButton(onPressed: () => close(true), child: const Text('확인')),
        ],
      ),
    );
  }

  Future<void> _showMessage(String message) {
    return showBlockingModelessOverlayDialog<void>(
      context: context,
      builder: (overlayContext, close) => AlertDialog(
        content: Text(message),
        actions: [
          FilledButton(onPressed: () => close(null), child: const Text('확인')),
        ],
      ),
    );
  }

  Widget _buildManager() {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          _openModifyEditor();
        },
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: '영양성분 형식 추가',
                    child: IconButton(
                      key: const ValueKey('nutritionTypeAddButton'),
                      onPressed: _busy ? null : _openCreateEditor,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  Tooltip(
                    message: '영양성분 형식 수정',
                    child: IconButton(
                      key: const ValueKey('nutritionTypeModifyButton'),
                      onPressed: _busy ? null : _openModifyEditor,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                  Tooltip(
                    message: '영양성분 형식 삭제',
                    child: IconButton(
                      key: const ValueKey('nutritionTypeDeleteButton'),
                      onPressed: _busy ? null : _deleteSelected,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FortuneTable<NutritionType>(
                        key: const ValueKey('nutritionTypeManagerTable'),
                        rows: _types,
                        selectedIndex: _selectedManagerIndex,
                        columns: [
                          FortuneTableColumn<NutritionType>(
                            id: 'id',
                            header: '번호',
                            text: (row) => '${row.id}',
                            initialWidth: 110,
                            minWidth: 90,
                          ),
                          FortuneTableColumn<NutritionType>(
                            id: 'name',
                            header: '형식명',
                            text: (row) => row.name,
                            fillRemaining: true,
                          ),
                        ],
                        onRowSelected: (_, index) {
                          setState(() => _selectedManagerIndex = index);
                        },
                        onRowDoubleTap: (_, index) {
                          setState(() => _selectedManagerIndex = index);
                          _openModifyEditor();
                        },
                        autoFitColumns: false,
                        fillLastColumn: true,
                      ),
                    ),
                    if (_loading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    final title = _editorMode == NutritionTypeEditorMode.create
        ? '영양성분 형식 추가'
        : '영양성분 형식 수정';
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_detailEditingActive) {
            return;
          }
          _saveEditor();
        },
      },
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('nutritionTypeNameField'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '형식명',
                        isDense: true,
                      ),
                      onChanged: (_) => _syncControllerState(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 260,
                    child: ModelessDropdownFormField<int>(
                      key: const ValueKey('nutritionTypeTemplateSelector'),
                      initialValue: _selectedTemplateTypeId,
                      decoration: const InputDecoration(
                        labelText: '기존내용 참조',
                        isDense: true,
                      ),
                      items: [
                        for (final row in _templateTypes)
                          DropdownMenuItem<int>(
                            value: row.id,
                            child: Text('${row.id} - ${row.name}'),
                          ),
                      ],
                      onChanged: _busy ? null : _changeTemplate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    key: const ValueKey('nutritionTypeDraftAddRowButton'),
                    tooltip: '구성 추가',
                    onPressed: _busy ? null : _addDetailRow,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    key: const ValueKey('nutritionTypeDraftDeleteRowButton'),
                    tooltip: '구성 삭제',
                    onPressed: _busy ? null : _deleteDetailRow,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FortuneTable<NutritionTypeColumn>(
                  key: const ValueKey('nutritionTypeDraftTable'),
                  rows: _detailRows,
                  selectedIndex: _selectedDetailIndex,
                  editingController: _detailEditingController,
                  columns: [
                    FortuneTableColumn<NutritionTypeColumn>(
                      id: 'keyword',
                      header: 'Keyword',
                      text: (row) => row.keyword,
                      initialWidth: 140,
                      minWidth: 100,
                    ),
                    FortuneTableColumn<NutritionTypeColumn>(
                      id: 'name',
                      header: '성분명',
                      text: (row) => row.name,
                      isTextEditable: (_, __) => !_busy,
                      onTextCommitted: (_, index, value) {
                        _updateDetailName(index, value);
                      },
                      fillRemaining: true,
                    ),
                  ],
                  onRowSelected: (_, index) {
                    setState(() => _selectedDetailIndex = index);
                  },
                  autoFitColumns: false,
                  fillLastColumn: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('nutritionTypeDraftCancelButton'),
                    onPressed: _busy ? null : _closeEditor,
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const ValueKey('nutritionTypeDraftSaveButton'),
                    onPressed: _busy ? null : _saveEditor,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_inEditor) {
      return _buildEditor();
    }
    return _buildManager();
  }
}