import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/nutrition_box.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/page_label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef NutritionBoxListLoader = Future<List<NutritionBox>> Function();
typedef NutritionBoxTypeListLoader = Future<List<NutritionType>> Function();
typedef NutritionBoxTypeColumnsLoader =
  Future<List<NutritionTypeColumn>> Function(int typeId);
typedef NutritionBoxWriter = Future<void> Function({
  required int typeId,
  required String name,
  required String rtf,
  required int width,
});
typedef NutritionBoxUpdater = Future<void> Function({
  required int boxId,
  required int typeId,
  required String name,
  required String rtf,
  required int width,
});
typedef NutritionBoxDeleter = Future<void> Function(int boxId);
typedef NutritionBoxRtfEditor = Future<String?> Function(String rtf);

@visibleForTesting
String? nutritionBoxValidationMessage(String name, int width, int? typeId) {
  if (name.isEmpty) return '명칭을 입력하셔야 합니다 !!';
  if (width == 0) return '너비를 입력하셔야 합니다 !!';
  if (typeId == null) return '영양성분 형식을 선택하세요';
  return null;
}

enum NutritionBoxEditorMode { create, edit }

class NutritionBoxDialogController extends ChangeNotifier {
  bool _writeBusy = false;
  bool _activeEditing = false;
  bool _childDirty = false;
  LifecycleExitAction? _discard;
  bool _disposed = false;

  bool get writeBusy => _writeBusy;
  bool get activeEditing => _activeEditing;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '영양성분표 저장 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '영양성분표 편집을 먼저 완료한 뒤 다시 시도해주세요.'
        : null,
    dirtyWorks: [
      if (_childDirty && _discard != null)
        LifecycleDirtyWork(name: '영양성분표 추가', discard: _discard!),
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

  void setChildDirty({required bool dirty, required LifecycleExitAction discard}) {
    if (_disposed) return;
    _childDirty = dirty;
    _discard = discard;
    notifyListeners();
  }

  void clearChildDirty() {
    if (_disposed) return;
    _childDirty = false;
    _discard = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class NutritionBoxDialogContent extends StatefulWidget {
  const NutritionBoxDialogContent({
    super.key,
    required this.controller,
    required this.onCommitOutcomeUnknown,
    this.loadBoxes = NutritionBoxDAO.selectAll,
    this.loadTypes = NutritionTypeDAO.selectTypesById,
    this.loadColumns = NutritionTypeDAO.selectColumns,
    this.insert = NutritionBoxDAO.insert,
    this.update = NutritionBoxDAO.update,
    this.delete = NutritionBoxDAO.delete,
    this.editRtf = labelSheetEditRichText,
  });

  final NutritionBoxDialogController controller;
  final VoidCallback onCommitOutcomeUnknown;
  final NutritionBoxListLoader loadBoxes;
  final NutritionBoxTypeListLoader loadTypes;
  final NutritionBoxTypeColumnsLoader loadColumns;
  final NutritionBoxWriter insert;
  final NutritionBoxUpdater update;
  final NutritionBoxDeleter delete;
  final NutritionBoxRtfEditor editRtf;

  @override
  State<NutritionBoxDialogContent> createState() =>
      _NutritionBoxDialogContentState();
}

class _NutritionBoxDialogContentState extends State<NutritionBoxDialogContent> {
  List<NutritionBox> _boxes = const [];
  int? _selectedIndex;
  bool _loading = true;
  NutritionBoxEditorMode? _mode;
  int? _editingBoxId;
  int? _selectedTypeId;
  List<NutritionType> _types = const [];
  List<NutritionTypeColumn> _columns = const [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  String _rtf = '';
  int? _baselineTypeId;
  String _baselineName = '';
  String _baselineWidth = '';
  String _baselineRtf = '';

  bool get _inEditor => _mode != null;
  bool get _busy => _loading || widget.controller.writeBusy;
  NutritionBox? get _selectedBox {
    final index = _selectedIndex;
    return index == null || index < 0 || index >= _boxes.length
        ? null
        : _boxes[index];
  }

  bool get _dirty =>
      _inEditor &&
      (_selectedTypeId != _baselineTypeId ||
          _nameController.text != _baselineName ||
          _widthController.text != _baselineWidth ||
          _rtf != _baselineRtf);

  @override
  void initState() {
    super.initState();
    _reloadBoxes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  Future<void> _reloadBoxes({int? restoreIndex, bool showError = true}) async {
    setState(() => _loading = true);
    try {
      final rows = await widget.loadBoxes();
      if (!mounted) return;
      setState(() {
        _boxes = rows;
        _selectedIndex = restoreIndex != null && restoreIndex < rows.length
            ? restoreIndex
            : null;
      });
    } catch (error) {
      if (showError && mounted) {
        await _showMessage(error.toString());
      } else {
        rethrow;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor(NutritionBoxEditorMode mode) async {
    if (_busy) return;
    final selected = _selectedBox;
    if (mode == NutritionBoxEditorMode.edit && selected == null) {
      await _showMessage('수정할 영양성분표를 선택해주세요!');
      return;
    }
    setState(() => _loading = true);
    try {
      final types = await widget.loadTypes();
      final typeId = selected?.typeId;
      final columns = typeId == null
          ? <NutritionTypeColumn>[]
          : await widget.loadColumns(typeId);
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _editingBoxId = selected?.id;
        _selectedTypeId = typeId;
        _types = types;
        _columns = columns;
        _nameController.text = selected?.name ?? '';
        _widthController.text = '${selected?.width ?? 0}';
        _rtf = selected?.rtf ?? '';
        _baselineTypeId = typeId;
        _baselineName = _nameController.text;
        _baselineWidth = _widthController.text;
        _baselineRtf = _rtf;
      });
      _syncDirty();
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeType(int? typeId) async {
    setState(() {
      _selectedTypeId = typeId;
      _columns = const [];
    });
    _syncDirty();
    if (typeId == null) return;
    try {
      final rows = await widget.loadColumns(typeId);
      if (mounted && _selectedTypeId == typeId) setState(() => _columns = rows);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    }
  }

  Future<void> _editRtf() async {
    if (_busy) return;
    widget.controller.setActiveEditing(true);
    try {
      final edited = await widget.editRtf(_rtf);
      if (edited != null && mounted) {
        setState(() => _rtf = edited);
        _syncDirty();
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      widget.controller.setActiveEditing(false);
    }
  }

  void _syncDirty() {
    if (_inEditor) {
      widget.controller.setChildDirty(dirty: _dirty, discard: _discardEditor);
    } else {
      widget.controller.clearChildDirty();
    }
    if (mounted) setState(() {});
  }

  Future<void> _discardEditor() async {
    setState(() {
      _mode = null;
      _editingBoxId = null;
      _types = const [];
      _columns = const [];
      _selectedTypeId = null;
      _rtf = '';
    });
    _syncDirty();
  }

  Future<void> _closeEditor() async {
    final restoreIndex = _mode == NutritionBoxEditorMode.edit
        ? _selectedIndex
        : null;
    await _discardEditor();
    await _reloadBoxes(restoreIndex: restoreIndex);
  }

  Future<void> _save() async {
    if (_busy) return;
    final width = int.tryParse(_widthController.text) ?? 0;
    final message = nutritionBoxValidationMessage(
      _nameController.text,
      width,
      _selectedTypeId,
    );
    if (message != null) {
      await _showMessage(message);
      return;
    }
    final typeId = _selectedTypeId!;
    final boxId = _editingBoxId;
    await _runWrite(
      write: _mode == NutritionBoxEditorMode.create
          ? () => widget.insert(
              typeId: typeId,
              name: _nameController.text,
              rtf: _rtf,
              width: width,
            )
          : () => widget.update(
              boxId: boxId!,
              typeId: typeId,
              name: _nameController.text,
              rtf: _rtf,
              width: width,
            ),
      onSuccess: () async {
        _baselineTypeId = typeId;
        _baselineName = _nameController.text;
        _baselineWidth = _widthController.text;
        _baselineRtf = _rtf;
        _syncDirty();
      },
    );
  }

  Future<void> _deleteSelected() async {
    if (_busy) return;
    final confirmed = await _showConfirmation('정말 삭제하시겠습니까?');
    if (confirmed != true || !mounted) return;
    final selected = _selectedBox;
    if (selected == null) {
      await _showMessage('삭제할 영양성분표를 선택해주세요!');
      return;
    }
    await _runWrite(
      write: () => widget.delete(selected.id),
      onSuccess: () => _reloadBoxes(showError: false),
    );
  }

  Future<void> _runWrite({
    required Future<void> Function() write,
    required Future<void> Function() onSuccess,
  }) async {
    widget.controller.setWriteBusy(true);
    var committed = false;
    try {
      await write();
      committed = true;
      await onSuccess();
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
    }
  }

  Future<bool?> _showConfirmation(String message) =>
      showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (_, close) => AlertDialog(
          title: const Text('삭제'),
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
        builder: (_, close) => AlertDialog(
          content: Text(message),
          actions: [
            FilledButton(onPressed: () => close(null), child: const Text('확인')),
          ],
        ),
      );

  Widget _preview(String rtf, {int widthMm = 100}) => rtf.isEmpty
      ? const SizedBox.expand()
      : LabelSheetRtfPreview(rtf: rtf, widthMm: widthMm, heightMm: 100);

  Widget _buildManager() => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.enter): () =>
          _openEditor(NutritionBoxEditorMode.edit),
    },
    child: Focus(
      autofocus: true,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  key: const ValueKey('nutritionBoxAddButton'),
                  tooltip: '영양성분표 추가',
                  onPressed: _busy
                      ? null
                      : () => _openEditor(NutritionBoxEditorMode.create),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  key: const ValueKey('nutritionBoxModifyButton'),
                  tooltip: '영양성분표 수정',
                  onPressed: _busy
                      ? null
                      : () => _openEditor(NutritionBoxEditorMode.edit),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key: const ValueKey('nutritionBoxDeleteButton'),
                  tooltip: '영양성분표 삭제',
                  onPressed: _busy ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: FortuneTable<NutritionBox>(
                      key: const ValueKey('nutritionBoxManagerTable'),
                      rows: _boxes,
                      selectedIndex: _selectedIndex,
                      columns: [
                        FortuneTableColumn<NutritionBox>(
                          id: 'type',
                          header: '영양성분 형식',
                          text: (row) => row.typeName,
                          initialWidth: 220,
                        ),
                        FortuneTableColumn<NutritionBox>(
                          id: 'name',
                          header: '표 명칭',
                          text: (row) => row.name,
                          fillRemaining: true,
                        ),
                      ],
                      onRowSelected: (_, index) =>
                          setState(() => _selectedIndex = index),
                      onRowDoubleTap: (_, index) {
                        setState(() => _selectedIndex = index);
                        _openEditor(NutritionBoxEditorMode.edit);
                      },
                      autoFitColumns: false,
                      fillLastColumn: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 360,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: _preview(_selectedBox?.rtf ?? '',
                          widthMm: _selectedBox?.width ?? 100),
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

  Widget _buildEditor() => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.enter): _save},
    child: Focus(
      autofocus: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const ValueKey('nutritionBoxTypeSelector'),
                    initialValue: _selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: '영양성분 형식',
                      isDense: true,
                    ),
                    items: [
                      for (final type in _types)
                        DropdownMenuItem(value: type.id, child: Text(type.name)),
                    ],
                    onChanged: _busy ? null : _changeType,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('nutritionBoxNameField'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '표 명칭', isDense: true),
                    onChanged: (_) => _syncDirty(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  child: TextField(
                    key: const ValueKey('nutritionBoxWidthField'),
                    controller: _widthController,
                    decoration: const InputDecoration(labelText: '폭', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _syncDirty(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: FortuneTable<NutritionTypeColumn>(
                key: const ValueKey('nutritionBoxTypeColumns'),
                rows: _columns,
                columns: [
                  FortuneTableColumn<NutritionTypeColumn>(
                    id: 'keyword',
                    header: 'Keyword',
                    text: (row) => row.keyword,
                    initialWidth: 180,
                  ),
                  FortuneTableColumn<NutritionTypeColumn>(
                    id: 'name',
                    header: '성분명',
                    text: (row) => row.name,
                    fillRemaining: true,
                  ),
                ],
                autoFitColumns: false,
                fillLastColumn: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: _preview(_rtf,
                          widthMm: int.tryParse(_widthController.text) ?? 100),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: FilledButton.icon(
                      key: const ValueKey('nutritionBoxRtfEditButton'),
                      onPressed: _busy ? null : _editRtf,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('RTF 편집'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _busy ? null : _closeEditor, child: const Text('닫기')),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('nutritionBoxSaveButton'),
                  onPressed: _busy ? null : _save,
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

  @override
  Widget build(BuildContext context) =>
      _inEditor ? _buildEditor() : _buildManager();
}