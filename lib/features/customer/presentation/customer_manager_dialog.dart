import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef CustomerCooperatorLoader = Future<List<Cooperator>> Function();
typedef CustomerLoader = Future<List<Customer>> Function(String cooperatorId);
typedef CustomerWriter = Future<void> Function(Customer customer);
typedef CustomerDeleter = Future<void> Function(int customerId);

class CustomerManagerController extends ChangeNotifier {
  bool _activeEditing = false;
  bool _writeBusy = false;
  bool _disposed = false;

  bool get activeEditing => _activeEditing;
  bool get writeBusy => _writeBusy;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '거래처 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '거래처 입력을 먼저 적용하거나 취소해주세요.'
        : null,
  );

  void setActiveEditing(bool value) {
    if (_disposed) return;
    if (_activeEditing == value) return;
    _activeEditing = value;
    notifyListeners();
  }

  void setWriteBusy(bool value) {
    if (_disposed) return;
    if (_writeBusy == value) return;
    _writeBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class CustomerManagerDialogContent extends StatefulWidget {
  const CustomerManagerDialogContent({
    super.key,
    required this.controller,
    required this.initialCooperator,
    required this.cooperatorSelectionEnabled,
    required this.onClose,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.insert = CustomerDAO.insert,
    this.update = CustomerDAO.update,
    this.delete = CustomerDAO.delete,
    this.systemPassword = systemPasswordForDate,
  });

  final CustomerManagerController controller;
  final Cooperator initialCooperator;
  final bool cooperatorSelectionEnabled;
  final VoidCallback onClose;
  final CustomerCooperatorLoader loadCooperators;
  final CustomerLoader loadCustomers;
  final CustomerWriter insert;
  final CustomerWriter update;
  final CustomerDeleter delete;
  final String Function([DateTime? now]) systemPassword;

  @override
  State<CustomerManagerDialogContent> createState() =>
      _CustomerManagerDialogContentState();
}

class _CustomerManagerDialogContentState
    extends State<CustomerManagerDialogContent> {
  List<Cooperator> _cooperators = const [];
  List<Customer> _rows = const [];
  late String _selectedCooperatorId;
  int? _selectedIndex;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;

  @override
  void initState() {
    super.initState();
    _selectedCooperatorId = widget.initialCooperator.id;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cooperators = await widget.loadCooperators();
      final customers = await widget.loadCustomers(_selectedCooperatorId);
      if (!mounted) return;
      setState(() {
        _cooperators = [
          widget.initialCooperator,
          ...cooperators.where((value) => value.id != widget.initialCooperator.id),
        ];
        _rows = customers;
        _selectedIndex = null;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeCooperator(String? cooperatorId) async {
    if (cooperatorId == null || _busy) return;
    setState(() {
      _loading = true;
      _selectedCooperatorId = cooperatorId;
      _selectedIndex = null;
    });
    try {
      final customers = await widget.loadCustomers(cooperatorId);
      if (!mounted) return;
      setState(() {
        _rows = customers;
        _selectedIndex = null;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    final customers = await widget.loadCustomers(_selectedCooperatorId);
    if (!mounted) return;
    setState(() {
      _rows = customers;
      _selectedIndex = null;
    });
  }

  Future<void> _add() async {
    if (_busy) return;
    final name = await _showInputDialog(title: '거래처 추가');
    if (name == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.insert(
        Customer(
          customerId: -1,
          cooperatorId: _selectedCooperatorId,
          customerName: name,
        ),
      ),
      successMessage: '추가가 완료되었습니다.',
    );
  }

  Future<void> _edit(Customer selected, int index) async {
    if (_busy) return;
    setState(() => _selectedIndex = index);
    final name = await _showInputDialog(
      title: '거래처 수정',
      initialName: selected.customerName,
    );
    if (name == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.update(
        Customer(
          customerId: selected.customerId,
          cooperatorId: selected.cooperatorId,
          customerName: name,
        ),
      ),
      successMessage: '수정이 완료되었습니다.',
    );
  }

  Customer? get _selectedCustomer {
    final index = _selectedIndex;
    return index == null || index >= _rows.length ? null : _rows[index];
  }

  Future<void> _deleteSelected() async {
    if (_busy) return;
    final selected = _selectedCustomer;
    if (selected == null) {
      await _showMessage('삭제할 행을 먼저 선택해주세요!!');
      return;
    }
    final password = await _showPasswordDialog();
    if (password == null || password != widget.systemPassword() || !mounted) {
      return;
    }
    final confirmed = await _showConfirmation(
      title: '거래처 삭제',
      message: '해당 거래처의 모든 데이터가 삭제됩니다!\n정말 삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) return;
    await _writeThenReload(
      write: () => widget.delete(selected.customerId),
      successMessage: '삭제가 완료되었습니다.',
    );
  }

  Future<void> _writeThenReload({
    required Future<void> Function() write,
    required String successMessage,
  }) async {
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    var committed = false;
    var closeAfterWrite = false;
    try {
      await write();
      committed = true;
      await _reload();
      if (mounted) await _showMessage(successMessage);
    } on DbCommitOutcomeUnknown catch (error) {
      if (mounted) await _showMessage(error.toString());
      closeAfterWrite = true;
    } catch (error) {
      if (committed) {
        if (mounted) {
          await _showMessage('저장은 완료됐지만 화면 갱신에 실패했습니다.');
        }
        closeAfterWrite = true;
      } else if (mounted) {
        await _showMessage(error.toString());
      }
    } finally {
      widget.controller.setWriteBusy(false);
      if (mounted) setState(() {});
    }
    if (closeAfterWrite) widget.onClose();
  }

  Future<String?> _showInputDialog({
    required String title,
    String initialName = '',
  }) async {
    widget.controller.setActiveEditing(true);
    try {
      return await showBlockingModelessOverlayDialog<String>(
        context: context,
        builder: (overlayContext, close) => _CustomerInputDialog(
          title: title,
          initialName: initialName,
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
      builder: (overlayContext, close) => _CustomerPasswordDialog(
        onCancel: () => close(null),
        onApply: close,
      ),
    );
  }

  Future<bool?> _showConfirmation({
    required String title,
    required String message,
  }) => showBlockingModelessOverlayDialog<bool>(
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

  Future<void> _showMessage(String message) =>
      showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (overlayContext, close) => AlertDialog(
          content: Text(message),
          actions: [
            FilledButton(onPressed: () => close(null), child: const Text('확인')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cooperatorSelectionEnabled =
        widget.cooperatorSelectionEnabled && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 76, child: Text('협력업체')),
              SizedBox(
                width: 260,
                child: DropdownMenu<String>(
                  key: const ValueKey('customerCooperatorSelector'),
                  width: 260,
                  initialSelection: _cooperators.any(
                    (value) => value.id == _selectedCooperatorId,
                  )
                      ? _selectedCooperatorId
                      : null,
                  dropdownMenuEntries: [
                    for (final cooperator in _cooperators)
                      DropdownMenuEntry(
                        value: cooperator.id,
                        label: cooperator.id,
                        style: MenuItemButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 28),
                          maximumSize: const Size(double.infinity, 28),
                          visualDensity: VisualDensity.standard,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                  enableFilter: false,
                  enableSearch: false,
                  enabled: cooperatorSelectionEnabled,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: cooperatorSelectionEnabled
                        ? Colors.white
                        : const Color(0xFFE9ECEF),
                    isDense: true,
                    constraints: const BoxConstraints.tightFor(height: 40),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  requestFocusOnTap: false,
                  onSelected: cooperatorSelectionEnabled
                      ? _changeCooperator
                      : null,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const ValueKey('customerAddButton'),
                tooltip: '거래처 추가',
                onPressed: _busy ? null : _add,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                key: const ValueKey('customerDeleteButton'),
                tooltip: '선택한 거래처 삭제',
                onPressed: _busy ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FortuneTable<Customer>(
                    rows: _rows,
                    selectedIndex: _selectedIndex,
                    columns: [
                      FortuneTableColumn<Customer>(
                        id: 'name',
                        header: '거래처 이름',
                        text: (value) => value.customerName,
                        fillRemaining: true,
                      ),
                    ],
                    onRowSelected: (row, index) {
                      if (mounted) setState(() => _selectedIndex = index);
                    },
                    onRowDoubleTap: _edit,
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

class _CustomerInputDialog extends StatefulWidget {
  const _CustomerInputDialog({
    required this.title,
    required this.initialName,
    required this.onCancel,
    required this.onApply,
  });

  final String title;
  final String initialName;
  final VoidCallback onCancel;
  final ValueChanged<String> onApply;

  @override
  State<_CustomerInputDialog> createState() => _CustomerInputDialogState();
}

class _CustomerInputDialogState extends State<_CustomerInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => widget.onApply(_controller.text);

  @override
  Widget build(BuildContext context) => BlockingModelessDialogFrame(
    title: widget.title,
    width: 440,
    height: 210,
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
      child: TextField(
        key: const ValueKey('customerNameField'),
        controller: _controller,
        autofocus: true,
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        decoration: const InputDecoration(labelText: '거래처 이름'),
        onSubmitted: (_) => _apply(),
      ),
    ),
  );
}

class _CustomerPasswordDialog extends StatefulWidget {
  const _CustomerPasswordDialog({required this.onCancel, required this.onApply});

  final VoidCallback onCancel;
  final ValueChanged<String> onApply;

  @override
  State<_CustomerPasswordDialog> createState() => _CustomerPasswordDialogState();
}

class _CustomerPasswordDialogState extends State<_CustomerPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => widget.onApply(_controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('시스템 비밀번호'),
    content: TextField(
      key: const ValueKey('customerSystemPasswordField'),
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