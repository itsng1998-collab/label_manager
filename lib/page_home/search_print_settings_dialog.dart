import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/search_print_settings.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

class SearchPrintSettingsDialogController extends ChangeNotifier {
  bool _dirty = false;
  bool _writeBusy = false;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy ? '검색출력 설정 저장이 끝난 뒤 다시 시도해주세요.' : null,
    dirtyWorks: [
      if (_dirty)
        LifecycleDirtyWork(name: '검색출력 설정', discard: discard),
    ],
  );

  void setDirty(bool value) {
    if (_dirty == value) return;
    _dirty = value;
    notifyListeners();
  }

  void setWriteBusy(bool value) {
    if (_writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }

  void discard() => setDirty(false);
}

class SearchPrintSettingsDialog extends StatefulWidget {
  const SearchPrintSettingsDialog({
    super.key,
    required this.controller,
    required this.brands,
    required this.initialBrand,
    required this.initialLabelSize,
    required this.loadLabelSizes,
    required this.loadColumns,
    required this.apply,
    required this.onClose,
  });

  final SearchPrintSettingsDialogController controller;
  final List<Brand> brands;
  final Brand? initialBrand;
  final LabelSize? initialLabelSize;
  final Future<List<LabelSize>> Function(int brandId) loadLabelSizes;
  final Future<List<TColumn>> Function(int labelSizeId) loadColumns;
  final Future<List<TColumn>> Function({
    required int labelSizeId,
    required List<TColumn> originalColumns,
    required List<TColumn> workingColumns,
  }) apply;
  final VoidCallback onClose;

  @override
  State<SearchPrintSettingsDialog> createState() =>
      _SearchPrintSettingsDialogState();
}

class _SearchPrintSettingsDialogState
    extends State<SearchPrintSettingsDialog> {
  Brand? _brand;
  LabelSize? _labelSize;
  List<LabelSize> _labelSizes = const [];
  List<TColumn> _committedColumns = const [];
  SearchPrintSettingsDraft? _draft;
  bool _busy = true;
  String? _error;
  final FocusNode _initialFocusNode = FocusNode(
    debugLabel: 'SearchPrintSettingsInitialFocus',
  );

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadInitial();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _draft?.dispose();
    _initialFocusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape && !_busy) {
      _requestClose();
      return true;
    }
    if (event.logicalKey != LogicalKeyboardKey.enter || _busy) return false;
    _apply();
    return true;
  }

  Future<void> _loadInitial() async {
    final brand = _resolveBrand(widget.initialBrand) ??
        (widget.brands.isEmpty ? null : widget.brands.first);
    if (brand == null) {
      setState(() {
        _busy = false;
        _error = '브랜드가 없습니다.';
      });
      return;
    }
    await _loadBrand(
      brand,
      preferredLabelSizeId: widget.initialLabelSize?.labelSizeId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialFocusNode.requestFocus();
    });
  }

  Brand? _resolveBrand(Brand? preferred) {
    if (preferred == null) return null;
    for (final brand in widget.brands) {
      if (brand.brandId == preferred.brandId) return brand;
    }
    return null;
  }

  Future<bool> _confirmDiscard() async {
    if (_draft?.isDirty != true) return true;
    final discard = await showBlockingModelessOverlayDialog<bool>(
      context: context,
      builder: (dialogContext, close) => AlertDialog(
        title: const Text('변경 내용 취소'),
        content: const Text('저장하지 않은 변경 내용을 버리시겠습니까?'),
        actions: [
          TextButton(onPressed: () => close(false), child: const Text('취소')),
          FilledButton(onPressed: () => close(true), child: const Text('버리기')),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _loadBrand(
    Brand brand, {
    int? preferredLabelSizeId,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final labelSizes = await widget.loadLabelSizes(brand.brandId);
      LabelSize? selected;
      if (preferredLabelSizeId != null) {
        for (final labelSize in labelSizes) {
          if (labelSize.labelSizeId == preferredLabelSizeId) {
            selected = labelSize;
            break;
          }
        }
      }
      selected ??= labelSizes.isEmpty ? null : labelSizes.first;
      final columns = selected == null
          ? const <TColumn>[]
          : await widget.loadColumns(selected.labelSizeId);
      if (!mounted) return;
      _draft?.dispose();
      setState(() {
        _brand = brand;
        _labelSizes = labelSizes;
        _labelSize = selected;
        _committedColumns = List<TColumn>.unmodifiable(columns);
        _draft = SearchPrintSettingsDraft(columns)..addListener(_rebuild);
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadLabelSize(LabelSize labelSize) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final columns = await widget.loadColumns(labelSize.labelSizeId);
      if (!mounted) return;
      _draft?.dispose();
      setState(() {
        _labelSize = labelSize;
        _committedColumns = List<TColumn>.unmodifiable(columns);
        _draft = SearchPrintSettingsDraft(columns)..addListener(_rebuild);
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  void _rebuild() {
    widget.controller.setDirty(_draft?.isDirty == true);
    if (mounted) setState(() {});
  }

  Future<void> _apply() async {
    final labelSize = _labelSize;
    final draft = _draft;
    if (_busy || labelSize == null || draft == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.controller.setWriteBusy(true);
    try {
      final reloaded = await widget.apply(
        labelSizeId: labelSize.labelSizeId,
        originalColumns: _committedColumns,
        workingColumns: draft.columns,
      );
      if (!mounted) return;
      _committedColumns = List<TColumn>.unmodifiable(reloaded);
      draft.replaceCommitted(reloaded);
      widget.controller.setDirty(false);
      setState(() => _busy = false);
      await _showMessage('저장되었습니다.');
    } on LabelColumnSaveCommittedException catch (error) {
      if (!mounted) return;
      await _showMessage(error.message);
      if (mounted) widget.onClose();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    } finally {
      widget.controller.setWriteBusy(false);
    }
  }

  Future<void> _showMessage(String message) =>
      showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (dialogContext, close) => AlertDialog(
          content: Text(message),
          actions: [
            FilledButton(onPressed: () => close(null), child: const Text('확인')),
          ],
        ),
      );

  Future<void> _requestClose() async {
    if (_busy || !await _confirmDiscard()) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final columns = _draft?.columns ?? const <TColumn>[];
    return BlockingModelessDialogFrame(
      title: '검색출력 설정',
      width: (size.width - 64).clamp(640, 920),
      height: (size.height - 80).clamp(420, 720),
      onClose: _requestClose,
      closeEnabled: !_busy,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            if (_error != null)
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Spacer(),
            TextButton(
              key: const ValueKey('searchPrintSettingsCancelButton'),
              onPressed: _busy ? null : _requestClose,
              child: const Text('취소'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const ValueKey('searchPrintSettingsApplyButton'),
              onPressed: _busy ? null : _apply,
              child: const Text(' 적용'),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ModelessDropdownFormField<Brand>(
                    focusNode: _initialFocusNode,
                    initialValue: _brand,
                    decoration: const InputDecoration(labelText: '브랜드'),
                    items: [
                      for (final brand in widget.brands)
                        DropdownMenuItem(value: brand, child: Text(brand.brandName)),
                    ],
                    onChanged: _busy
                        ? null
                        : (brand) async {
                            if (brand == null || !await _confirmDiscard()) return;
                            await _loadBrand(brand);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModelessDropdownFormField<LabelSize>(
                    initialValue: _labelSize,
                    decoration: const InputDecoration(labelText: '라벨'),
                    items: [
                      for (final labelSize in _labelSizes)
                        DropdownMenuItem(
                          value: labelSize,
                          child: Text(labelSize.labelSizeName),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (labelSize) async {
                            if (labelSize == null || !await _confirmDiscard()) return;
                            await _loadLabelSize(labelSize);
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _draft?.setAll(true),
                  child: const Text('전체 선택'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _draft?.setAll(false),
                  child: const Text('전체 해제'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _busy && _draft == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: columns.length,
                      itemBuilder: (context, index) {
                        final column = columns[index];
                        return CheckboxListTile(
                          value: column.searchPrint,
                          title: Text(column.columnName),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: _busy
                              ? null
                              : (value) => _draft?.setSearchPrint(
                                    column.columnId,
                                    value ?? false,
                                  ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
