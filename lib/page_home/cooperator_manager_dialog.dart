import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef CooperatorLoader = Future<List<Cooperator>> Function();
typedef CooperatorWriter = Future<void> Function(Cooperator cooperator);
typedef CooperatorUpdater = Future<void> Function(
  String oldCooperatorId,
  Cooperator cooperator,
);
typedef CooperatorDeleter = Future<void> Function(String cooperatorId);

class CooperatorManagerController extends ChangeNotifier {
  bool _activeEditing = false;
  bool _writeBusy = false;

  bool get activeEditing => _activeEditing;
  bool get writeBusy => _writeBusy;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '협력업체 저장 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '협력업체 입력을 먼저 적용하거나 취소해주세요.'
        : null,
  );

  void setActiveEditing(bool value) {
    if (_activeEditing == value) return;
    _activeEditing = value;
    notifyListeners();
  }

  void setWriteBusy(bool value) {
    if (_writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }
}

class CooperatorManagerDialogContent extends StatefulWidget {
  const CooperatorManagerDialogContent({
    super.key,
    required this.controller,
    this.load = CooperatorDAO.selectAll,
    this.insert = CooperatorDAO.insert,
    this.update = CooperatorDAO.update,
    this.delete = CooperatorDAO.delete,
    this.systemPassword = systemPasswordForDate,
  });

  final CooperatorManagerController controller;
  final CooperatorLoader load;
  final CooperatorWriter insert;
  final CooperatorUpdater update;
  final CooperatorDeleter delete;
  final String Function([DateTime? now]) systemPassword;

  @override
  State<CooperatorManagerDialogContent> createState() =>
      _CooperatorManagerDialogContentState();
}

class _CooperatorManagerDialogContentState
    extends State<CooperatorManagerDialogContent> {
  List<Cooperator> _rows = const [];
  int? _selectedIndex;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;

  @override
  void initState() {
    super.initState();
    _reload(showError: true);
  }

  Future<void> _reload({required bool showError}) async {
    try {
      final rows = await widget.load();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _selectedIndex = null;
      });
    } catch (error) {
      if (showError) {
        if (mounted) await _showMessage(error.toString());
        return;
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    final draft = await _showInputDialog(title: '협력업체 추가');
    if (draft == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.insert(draft),
      successMessage: '추가가 완료되었습니다.',
    );
  }

  Future<void> _edit(Cooperator selected, int index) async {
    if (_busy) return;
    setState(() => _selectedIndex = index);
    final draft = await _showInputDialog(
      title: '협력업체 수정',
      initialValue: selected,
    );
    if (draft == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.update(selected.id, draft),
      successMessage: '수정이 완료되었습니다.',
    );
  }

  Future<void> _deleteSelected() async {
    if (_busy) return;
    final selectedIndex = _selectedIndex;
    if (selectedIndex == null || selectedIndex >= _rows.length) {
      await _showMessage('삭제할 행을 먼저 선택해주세요!!');
      return;
    }

    final password = await _showPasswordDialog();
    if (password == null || password != widget.systemPassword() || !mounted) {
      return;
    }
    final confirmed = await _showConfirmation(
      title: '거래처 삭제',
      message: '해당 협력업체에 해당하는 모든 거래처가 삭제됩니다!\n정말 삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) return;

    final selected = _rows[selectedIndex];
    await _writeThenReload(
      write: () => widget.delete(selected.id),
      successMessage: '삭제가 완료되었습니다.',
    );
  }

  Future<void> _writeThenReload({
    required Future<void> Function() write,
    required String successMessage,
  }) async {
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    try {
      await write();
      await _reload(showError: false);
      if (mounted) await _showMessage(successMessage);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      widget.controller.setWriteBusy(false);
      if (mounted) setState(() {});
    }
  }

  Future<Cooperator?> _showInputDialog({
    required String title,
    Cooperator? initialValue,
  }) async {
    widget.controller.setActiveEditing(true);
    try {
      return await showBlockingModelessOverlayDialog<Cooperator>(
        context: context,
        builder: (overlayContext, close) => _CooperatorInputDialog(
          title: title,
          initialValue: initialValue,
          onCancel: () => close(null),
          onApply: close,
        ),
      );
    } finally {
      widget.controller.setActiveEditing(false);
    }
  }

  Future<String?> _showPasswordDialog() {
    return showBlockingModelessOverlayDialog<String>(
      context: context,
      builder: (overlayContext, close) => _SystemPasswordDialog(
        onCancel: () => close(null),
        onApply: close,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Tooltip(
                message: '협력업체 추가',
                child: IconButton(
                  key: const ValueKey('cooperatorAddButton'),
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add),
                ),
              ),
              Tooltip(
                message: '선택한 협력업체 삭제',
                child: IconButton(
                  key: const ValueKey('cooperatorDeleteButton'),
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
                  child: FortuneTable<Cooperator>(
                    rows: _rows,
                    selectedIndex: _selectedIndex,
                    columns: [
                      FortuneTableColumn<Cooperator>(
                        id: 'id',
                        header: '협력업체 ID',
                        text: (value) => value.id,
                        initialWidth: 180,
                        minWidth: 120,
                      ),
                      FortuneTableColumn<Cooperator>(
                        id: 'name',
                        header: '협력업체 이름',
                        text: (value) => value.name,
                        fillRemaining: true,
                      ),
                    ],
                    onRowSelected: (row, index) {
                      if (mounted) setState(() => _selectedIndex = index);
                    },
                    onRowDoubleTap: _edit,
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
    );
  }
}

class _CooperatorInputDialog extends StatefulWidget {
  const _CooperatorInputDialog({
    required this.title,
    required this.initialValue,
    required this.onCancel,
    required this.onApply,
  });

  final String title;
  final Cooperator? initialValue;
  final VoidCallback onCancel;
  final ValueChanged<Cooperator> onApply;

  @override
  State<_CooperatorInputDialog> createState() => _CooperatorInputDialogState();
}

class _CooperatorInputDialogState extends State<_CooperatorInputDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialValue?.id ?? '');
    _nameController = TextEditingController(
      text: widget.initialValue?.name ?? '',
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      Cooperator(id: _idController.text, name: _nameController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlockingModelessDialogFrame(
      title: widget.title,
      width: 460,
      height: 270,
      onClose: widget.onCancel,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: widget.onCancel, child: const Text('취소')),
            const SizedBox(width: 8),
            FilledButton(onPressed: _apply, child: const Text('적용')),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const ValueKey('cooperatorIdField'),
              controller: _idController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '협력업체 ID'),
              onSubmitted: (_) => _apply(),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('cooperatorNameField'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: '협력업체 이름'),
              onSubmitted: (_) => _apply(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemPasswordDialog extends StatefulWidget {
  const _SystemPasswordDialog({required this.onCancel, required this.onApply});

  final VoidCallback onCancel;
  final ValueChanged<String> onApply;

  @override
  State<_SystemPasswordDialog> createState() => _SystemPasswordDialogState();
}

class _SystemPasswordDialogState extends State<_SystemPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => widget.onApply(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('시스템 비밀번호'),
      content: TextField(
        key: const ValueKey('systemPasswordField'),
        controller: _controller,
        autofocus: true,
        obscureText: true,
        onSubmitted: (_) => _apply(),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('취소')),
        FilledButton(onPressed: _apply, child: const Text('확인')),
      ],
    );
  }
}