import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/nutrition_box.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/page_home/preview_floating_window.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_preview.dart';
import 'package:label_manager/page_label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';

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

@visibleForTesting
Future<FortuneWorkbook> nutritionBoxWorkbookFromData(
  String data, {
  required int widthMm,
}) async {
  final labelSize = _nutritionBoxLabelSize(data, widthMm);
  final savedWorkbook = labelSheetTryDecodeWorkbookSave(data);
  if (savedWorkbook != null) {
    return labelSheetWorkbook(savedWorkbook, labelSize: labelSize);
  }
  return labelSheetWorkbookWithRtf(
    FortuneWorkbook(
      sheets: [FortuneSheet(id: 'nutrition_box_01', name: 'Nutrition')],
    ),
    labelSize: labelSize,
    labelRtf: data,
  );
}

LabelSize _nutritionBoxLabelSize(String data, int widthMm) => LabelSize(
  labelSizeId: -1,
  brandId: -1,
  labelSizeName: '영양성분표',
  labelSizeCommon: LabelSizeCommon(
    width: widthMm > 0 ? widthMm : 100,
    height: 100,
    rtf: data,
  ),
);

final List<String> _nutritionBoxSheetToolbarItems = List.unmodifiable([
  for (final item in labelSheetToolbarItems)
    if (item != labelSheetSaveToolbarCommand &&
        item != fortuneToolbarObjectPanelCommand)
      item,
]);

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
  });

  final NutritionBoxDialogController controller;
  final VoidCallback onCommitOutcomeUnknown;
  final NutritionBoxListLoader loadBoxes;
  final NutritionBoxTypeListLoader loadTypes;
  final NutritionBoxTypeColumnsLoader loadColumns;
  final NutritionBoxWriter insert;
  final NutritionBoxUpdater update;
  final NutritionBoxDeleter delete;

  @override
  State<NutritionBoxDialogContent> createState() =>
      _NutritionBoxDialogContentState();
}

class _NutritionBoxDialogContentState extends State<NutritionBoxDialogContent> {
  static const double _managerSplitterWidth = 8;
  static const double _managerInitialPreviewWidth = 360;
  static const double _managerMinTableWidth = 420;
  static const double _managerMinPreviewWidth = 280;

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
  FortuneWorkbook? _editorWorkbook;
  int? _baselineTypeId;
  String _baselineName = '';
  String _baselineWidth = '';
  String _baselineRtf = '';
  double _managerPreviewFraction = 0;
  bool _managerPreviewWidthChangedByUser = false;
  final GlobalKey _rtfPreviewRestoreKey = GlobalKey();
  PreviewFloatingWindow? _rtfPreviewWindow;
  String? _rtfPreviewData;
  bool _rtfPreviewClosedByUser = false;

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
    _rtfPreviewWindow?.dispose();
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
          _syncSelectedRtfPreview();
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
    _rtfPreviewWindow?.hide();
    try {
      final types = await widget.loadTypes();
      final typeId = selected?.typeId;
      final columns = typeId == null
          ? <NutritionTypeColumn>[]
          : await widget.loadColumns(typeId);
      final sourceRtf = selected?.rtf ?? '';
      final workbook = await nutritionBoxWorkbookFromData(
        sourceRtf,
        widthMm: selected?.width ?? 100,
      );
      final sheetData = labelSheetEncodeWorkbookSave(workbook);
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _editingBoxId = selected?.id;
        _selectedTypeId = typeId;
        _types = types;
        _columns = columns;
        _nameController.text = selected?.name ?? '';
        _widthController.text = '${selected?.width ?? 0}';
        _rtf = sheetData;
        _editorWorkbook = workbook;
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
      _editorWorkbook = null;
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
    final editorWorkbook = _editorWorkbook;
    if (editorWorkbook != null) {
      final sizedWorkbook = labelSheetWorkbook(
        editorWorkbook,
        labelSize: _nutritionBoxLabelSize(_rtf, width),
      );
      _editorWorkbook = sizedWorkbook;
      _rtf = labelSheetEncodeWorkbookSave(sizedWorkbook);
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

  void _selectManagerRow(int index) {
    setState(() => _selectedIndex = index);
    _syncSelectedRtfPreview();
  }

  void _syncSelectedRtfPreview() {
    final selected = _selectedBox;
    final data = selected?.rtf;
    if (!labelSheetLooksLikeRichEditRtf(data)) {
      _rtfPreviewData = null;
      _rtfPreviewClosedByUser = false;
      _rtfPreviewWindow?.setChild(null);
      _rtfPreviewWindow?.hide();
      return;
    }
    final rtf = data!;
    final preview = LabelSheetRtfPreview(
      key: ValueKey('nutrition-box-rtf-preview:${rtf.hashCode}'),
      rtf: rtf,
      widthMm: selected!.width,
      heightMm: 100,
    );
    _rtfPreviewData = rtf;
    final existingWindow = _rtfPreviewWindow;
    if (existingWindow == null) {
      _rtfPreviewWindow = PreviewFloatingWindow(
        initialSize: Size(
          LabelSheetRtfPreview.pixelsForMm(selected.width) + 8,
          LabelSheetRtfPreview.pixelsForMm(100) + 8,
        ),
        tooltip: 'RTF 미리보기',
        child: preview,
        onCloseRequested: _closeRtfPreviewWindow,
        usePortalHost: true,
      );
      if (mounted) setState(() {});
    } else {
      existingWindow.setChild(preview);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _rtfPreviewClosedByUser || _rtfPreviewData != rtf) {
        return;
      }
      _rtfPreviewWindow?.show(context);
    });
  }

  void _closeRtfPreviewWindow() {
    final window = _rtfPreviewWindow;
    if (window == null || !window.isVisible) return;
    window.hide();
    if (!mounted) return;
    setState(() => _rtfPreviewClosedByUser = true);
  }

  void _restoreRtfPreviewWindow() {
    if (_rtfPreviewWindow == null || _rtfPreviewData == null) return;
    setState(() => _rtfPreviewClosedByUser = false);
    _syncSelectedRtfPreview();
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

  Widget _buildManager() {
    Widget result = CallbackShortcuts(
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
            SizedBox(
              key: const ValueKey('nutritionBoxManagerToolbar'),
              height: 34,
              child: Row(
              children: [
                IconButton(
                  key: const ValueKey('nutritionBoxAddButton'),
                  tooltip: '영양성분표 추가',
                  onPressed: _busy
                      ? null
                      : () => _openEditor(NutritionBoxEditorMode.create),
                  icon: const Icon(Icons.add),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
                IconButton(
                  key: const ValueKey('nutritionBoxModifyButton'),
                  tooltip: '영양성분표 수정',
                  onPressed: _busy
                      ? null
                      : () => _openEditor(NutritionBoxEditorMode.edit),
                  icon: const Icon(Icons.edit_outlined),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
                IconButton(
                  key: const ValueKey('nutritionBoxDeleteButton'),
                  tooltip: '영양성분표 삭제',
                  onPressed: _busy ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  key: _rtfPreviewRestoreKey,
                  width: 28,
                  height: 28,
                  child: IgnorePointer(
                    ignoring: !_rtfPreviewClosedByUser,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _rtfPreviewClosedByUser ? 1 : 0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: _rtfPreviewClosedByUser ? 1 : 0.75,
                        child: IconButton(
                          key: const ValueKey('nutritionBoxRtfPreviewRestore'),
                          tooltip: 'RTF 미리보기 다시 보기',
                          onPressed: _restoreRtfPreviewWindow,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.preview, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 116),
              ],
            ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final maxPreviewWidth =
                      totalWidth - _managerMinTableWidth - _managerSplitterWidth;
                  final minPreviewWidth = maxPreviewWidth < _managerMinPreviewWidth
                      ? maxPreviewWidth
                      : _managerMinPreviewWidth;
                  final previewWidth = (_managerPreviewWidthChangedByUser
                          ? totalWidth * _managerPreviewFraction
                          : _managerInitialPreviewWidth)
                      .clamp(minPreviewWidth, maxPreviewWidth)
                      .toDouble();
                  final tableWidth =
                      totalWidth - previewWidth - _managerSplitterWidth;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: tableWidth,
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
                      onRowSelected: (_, index) => _selectManagerRow(index),
                      onRowDoubleTap: (_, index) {
                        _selectManagerRow(index);
                        _openEditor(NutritionBoxEditorMode.edit);
                      },
                      autoFitColumns: false,
                      fillLastColumn: true,
                        ),
                      ),
                      VerticalPaneSplitter(
                        key: const ValueKey('nutritionBoxPreviewSplitter'),
                        width: _managerSplitterWidth,
                        onDrag: (dx) {
                          setState(() {
                            final currentWidth =
                                _managerPreviewWidthChangedByUser
                                ? totalWidth * _managerPreviewFraction
                                : previewWidth;
                            final nextWidth = (currentWidth - dx).clamp(
                              minPreviewWidth,
                              maxPreviewWidth,
                            );
                            _managerPreviewWidthChangedByUser = true;
                            _managerPreviewFraction = nextWidth / totalWidth;
                          });
                        },
                      ),
                      SizedBox(
                        key: const ValueKey('nutritionBoxPreviewPane'),
                        width: previewWidth,
                        child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: NutritionBoxSheetPreview(
                        data: _selectedBox?.rtf ?? '',
                        widthMm: _selectedBox?.width ?? 100,
                      ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
    final rtfPreviewWindow = _rtfPreviewWindow;
    if (rtfPreviewWindow != null) {
      result = rtfPreviewWindow.wrapPortalHost(child: result);
    }
    return result;
  }

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
                  child: ModelessDropdownFormField<int>(
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
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      key: const ValueKey('nutritionBoxEditorSheet'),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: LabelSheetWorkbench(
                        key: ValueKey('nutritionBoxSheet:${_editingBoxId ?? 'new'}'),
                        initialWorkbook: _editorWorkbook,
                        labelSize: _nutritionBoxLabelSize(
                          _rtf,
                          int.tryParse(_widthController.text) ?? 100,
                        ),
                        toolbarItems: _nutritionBoxSheetToolbarItems,
                        hideRowColumnHeaderLabels: true,
                        rulerCornerSizeLabelUsesAsterisk: true,
                        disableSheetRulerGuideInteraction: true,
                        hideStatisticBar: true,
                        allowObjectPanel: false,
                        showObjectPanelOpenButton: false,
                        onUserWorkbookChanged: (workbook) {
                          _editorWorkbook = workbook;
                          _rtf = labelSheetEncodeWorkbookSave(workbook);
                          _syncDirty();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 360,
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _busy ? null : _closeEditor, child: const Text('취소')),
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

class NutritionBoxSheetPreview extends StatefulWidget {
  const NutritionBoxSheetPreview({
    super.key,
    required this.data,
    required this.widthMm,
  });

  final String data;
  final int widthMm;

  @override
  State<NutritionBoxSheetPreview> createState() =>
      _NutritionBoxSheetPreviewState();
}

class _NutritionBoxSheetPreviewState extends State<NutritionBoxSheetPreview> {
  late Future<FortuneWorkbook> _workbook = _loadWorkbook();

  Future<FortuneWorkbook> _loadWorkbook() async {
    final workbook = await nutritionBoxWorkbookFromData(
      widget.data,
      widthMm: widget.widthMm,
    );
    return workbook.copyWith(
      sheets: [
        for (final sheet in workbook.sheets)
          sheet.copyWith(showGridLines: false),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant NutritionBoxSheetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.widthMm != widget.widthMm) {
      _workbook = _loadWorkbook();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FortuneWorkbook>(
    future: _workbook,
    builder: (context, snapshot) => LabelOutputPreview(
      workbook: snapshot.data,
      hintText: snapshot.hasError
          ? '미리보기를 불러올 수 없습니다.'
          : snapshot.hasData
          ? null
          : '미리보기를 불러오는 중입니다.',
      identityKey:
          'nutrition-box:${widget.widthMm}:${widget.data.length}:${widget.data.hashCode}',
      labelSize: _nutritionBoxLabelSize(widget.data, widget.widthMm),
      imageObjectIds: const [],
      barcodeObjectIds: const [],
      autoFitWidth: true,
      zoomToolbarBackgroundColor: blockingModelessDialogBackgroundColor,
      zoomToolbarUseIcons: true,
    ),
  );
}