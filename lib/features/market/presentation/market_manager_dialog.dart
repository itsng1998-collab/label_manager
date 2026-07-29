import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/core/system_password.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef MarketCooperatorLoader = Future<List<Cooperator>> Function();
typedef MarketCustomerLoader = Future<List<Customer>> Function(String);
typedef MarketLoader = Future<List<Market>?> Function(int);
typedef MarketInserter = Future<int> Function(Market);
typedef MarketWriter = Future<void> Function(Market);
typedef MarketDeleter = Future<void> Function(int);

class MarketManagerController extends ChangeNotifier {
  bool _activeEditing = false;
  bool _writeBusy = false;
  bool _disposed = false;

  bool get activeEditing => _activeEditing;
  bool get writeBusy => _writeBusy;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '지점 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '지점 입력을 먼저 적용하거나 취소해주세요.'
        : null,
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MarketManagerDialogContent extends StatefulWidget {
  const MarketManagerDialogContent({
    super.key,
    required this.controller,
    required this.initialCooperator,
    required this.initialCustomer,
    required this.cooperatorSelectionEnabled,
    required this.onClose,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.loadMarkets = MarketDAO.selectByCustomerId,
    this.insert = MarketDAO.insertWithItemMappings,
    this.update = MarketDAO.update,
    this.delete = MarketDAO.deleteWithItemMappings,
    this.systemPassword = systemPasswordForDate,
  });

  final MarketManagerController controller;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final bool cooperatorSelectionEnabled;
  final VoidCallback onClose;
  final MarketCooperatorLoader loadCooperators;
  final MarketCustomerLoader loadCustomers;
  final MarketLoader loadMarkets;
  final MarketInserter insert;
  final MarketWriter update;
  final MarketDeleter delete;
  final String Function([DateTime? now]) systemPassword;

  @override
  State<MarketManagerDialogContent> createState() =>
      _MarketManagerDialogContentState();
}

class _MarketManagerDialogContentState
    extends State<MarketManagerDialogContent> {
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  List<Market> _rows = const [];
  late String _selectedCooperatorId;
  int? _selectedCustomerId;
  int? _selectedIndex;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;
  bool get _customerSelected => _selectedCustomerId != null;

  @override
  void initState() {
    super.initState();
    _selectedCooperatorId = widget.initialCooperator.id;
    _selectedCustomerId = widget.initialCustomer.customerId;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cooperators = await widget.loadCooperators();
      final customers = await widget.loadCustomers(_selectedCooperatorId);
      final markets = await widget.loadMarkets(_selectedCustomerId!);
      if (!mounted) return;
      setState(() {
        _cooperators = [
          widget.initialCooperator,
          ...cooperators.where(
            (value) => value.id != widget.initialCooperator.id,
          ),
        ];
        _customers = customers;
        _rows = markets ?? const [];
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
      _selectedCustomerId = null;
      _customers = const [];
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final customers = await widget.loadCustomers(cooperatorId);
      if (mounted) setState(() => _customers = customers);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeCustomer(int? customerId) async {
    if (customerId == null || _busy) return;
    setState(() {
      _loading = true;
      _selectedCustomerId = customerId;
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final markets = await widget.loadMarkets(customerId);
      if (mounted) setState(() => _rows = markets ?? const []);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    final markets = await widget.loadMarkets(_selectedCustomerId!);
    if (!mounted) return;
    setState(() {
      _rows = markets ?? const [];
      _selectedIndex = null;
    });
  }

  Future<void> _add() async {
    if (_busy || !_customerSelected) return;
    final name = await _showInputDialog(title: '지점 추가');
    if (name == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.insert(
        Market(marketId: -1, customerId: _selectedCustomerId!, name: name),
      ),
      successMessage: '추가가 완료되었습니다.',
    );
  }

  Future<void> _edit(Market selected, int index) async {
    if (_busy || !_customerSelected) return;
    setState(() => _selectedIndex = index);
    final name = await _showInputDialog(
      title: '지점 수정',
      initialName: selected.name,
    );
    if (name == null || !mounted) return;
    await _writeThenReload(
      write: () => widget.update(
        Market(
          marketId: selected.marketId,
          customerId: selected.customerId,
          name: name,
        ),
      ),
      successMessage: '수정이 완료되었습니다.',
    );
  }

  Market? get _selectedMarket {
    final index = _selectedIndex;
    return index == null || index >= _rows.length ? null : _rows[index];
  }

  Future<void> _deleteSelected() async {
    if (_busy || !_customerSelected) return;
    final selected = _selectedMarket;
    if (selected == null) {
      await _showMessage('삭제할 행을 먼저 선택해주세요!!');
      return;
    }
    final password = await _showPasswordDialog();
    if (password == null || password != widget.systemPassword() || !mounted) {
      return;
    }
    final confirmed = await _showConfirmation(
      message: '해당 지점에 해당하는 모든 ID가 삭제됩니다!\n정말 삭제하시겠습니까?',
    );
    if (confirmed != true || !mounted) return;
    await _writeThenReload(
      write: () => widget.delete(selected.marketId),
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
        builder: (overlayContext, close) => _MarketInputDialog(
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

  Future<String?> _showPasswordDialog() =>
      showBlockingModelessOverlayDialog<String>(
        context: context,
        builder: (overlayContext, close) =>
            _MarketPasswordDialog(onCancel: () => close(null), onApply: close),
      );

  Future<bool?> _showConfirmation({required String message}) =>
      showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (overlayContext, close) => AlertDialog(
          title: const Text('지점 삭제'),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 76, child: Text('협력업체')),
            SizedBox(
              width: 220,
              child: ModelessDropdownFormField<String>(
                key: const ValueKey('marketCooperatorSelector'),
                initialValue:
                    _cooperators.any(
                      (value) => value.id == _selectedCooperatorId,
                    )
                    ? _selectedCooperatorId
                    : null,
                items: [
                  for (final cooperator in _cooperators)
                    DropdownMenuItem(
                      value: cooperator.id,
                      child: Text(cooperator.id),
                    ),
                ],
                onChanged: widget.cooperatorSelectionEnabled && !_busy
                    ? _changeCooperator
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            const SizedBox(width: 52, child: Text('거래처')),
            SizedBox(
              width: 240,
              child: ModelessDropdownFormField<int>(
                key: const ValueKey('marketCustomerSelector'),
                initialValue:
                    _customers.any(
                      (value) => value.customerId == _selectedCustomerId,
                    )
                    ? _selectedCustomerId
                    : null,
                items: [
                  for (final customer in _customers)
                    DropdownMenuItem(
                      value: customer.customerId,
                      child: Text(customer.customerName),
                    ),
                ],
                onChanged: _busy ? null : _changeCustomer,
              ),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('marketAddButton'),
              tooltip: '지점 추가',
              onPressed: _busy || !_customerSelected ? null : _add,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              key: const ValueKey('marketDeleteButton'),
              tooltip: '선택한 지점 삭제',
              onPressed: _busy || !_customerSelected ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: FortuneTable<Market>(
                  rows: _rows,
                  selectedIndex: _selectedIndex,
                  columns: [
                    FortuneTableColumn<Market>(
                      id: 'name',
                      header: '지점 이름',
                      text: (value) => value.name,
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

class _MarketInputDialog extends StatefulWidget {
  const _MarketInputDialog({
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
  State<_MarketInputDialog> createState() => _MarketInputDialogState();
}

class _MarketInputDialogState extends State<_MarketInputDialog> {
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
        key: const ValueKey('marketNameField'),
        controller: _controller,
        autofocus: true,
        inputFormatters: [LengthLimitingTextInputFormatter(50)],
        decoration: const InputDecoration(labelText: '지점 이름'),
        onSubmitted: (_) => _apply(),
      ),
    ),
  );
}

class _MarketPasswordDialog extends StatefulWidget {
  const _MarketPasswordDialog({required this.onCancel, required this.onApply});

  final VoidCallback onCancel;
  final ValueChanged<String> onApply;

  @override
  State<_MarketPasswordDialog> createState() => _MarketPasswordDialogState();
}

class _MarketPasswordDialogState extends State<_MarketPasswordDialog> {
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
      key: const ValueKey('marketSystemPasswordField'),
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
