import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/features/managed_user/data/managed_user_dao.dart';
import 'package:label_manager/features/managed_user/domain/managed_user.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef ManagedUserCooperatorLoader = Future<List<Cooperator>> Function();
typedef ManagedUserCustomerLoader = Future<List<Customer>> Function(String);
typedef ManagedUserMarketLoader = Future<List<Market>?> Function(int);
typedef ManagedUserListLoader = Future<List<ManagedUser>> Function(int);
typedef ManagedUserCooperatorListLoader =
    Future<List<ManagedUser>> Function(String);
typedef ManagedUserLookup = Future<ManagedUser?> Function(String);
typedef ManagedUserWriter = Future<void> Function(ManagedUser);
typedef ManagedUserUpdater = Future<void> Function(String, ManagedUser);
typedef ManagedUserDeleter = Future<void> Function(String);

class UserManagerController extends ChangeNotifier {
  bool _activeEditing = false;
  bool _writeBusy = false;
  bool _disposed = false;

  bool get activeEditing => _activeEditing;
  bool get writeBusy => _writeBusy;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy
        ? '사용자 작업이 끝난 뒤 다시 시도해주세요.'
        : _activeEditing
        ? '사용자 입력을 먼저 적용하거나 취소해주세요.'
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

class UserManagerDialogContent extends StatefulWidget {
  const UserManagerDialogContent({
    super.key,
    required this.controller,
    required this.initialCooperator,
    required this.initialCustomer,
    required this.initialMarket,
    required this.cooperatorSelectionEnabled,
    required this.customerSelectionEnabled,
    required this.marketSelectionEnabled,
    required this.showCredentials,
    required this.onClose,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.loadMarkets = MarketDAO.selectByCustomerId,
    this.loadUsers = ManagedUserDAO.selectByMarketId,
    this.loadCooperatorUsers = ManagedUserDAO.selectByCooperatorId,
    this.lookupUser = ManagedUserDAO.selectByUserId,
    this.insert = ManagedUserDAO.insert,
    this.update = ManagedUserDAO.update,
    this.delete = ManagedUserDAO.delete,
  });

  final UserManagerController controller;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final Market initialMarket;
  final bool cooperatorSelectionEnabled;
  final bool customerSelectionEnabled;
  final bool marketSelectionEnabled;
  final bool showCredentials;
  final VoidCallback onClose;
  final ManagedUserCooperatorLoader loadCooperators;
  final ManagedUserCustomerLoader loadCustomers;
  final ManagedUserMarketLoader loadMarkets;
  final ManagedUserListLoader loadUsers;
  final ManagedUserCooperatorListLoader loadCooperatorUsers;
  final ManagedUserLookup lookupUser;
  final ManagedUserWriter insert;
  final ManagedUserUpdater update;
  final ManagedUserDeleter delete;

  @override
  State<UserManagerDialogContent> createState() =>
      _UserManagerDialogContentState();
}

class _UserManagerDialogContentState extends State<UserManagerDialogContent> {
  final _searchController = TextEditingController();
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  List<Market> _markets = const [];
  List<ManagedUser> _rows = const [];
  late String _selectedCooperatorId;
  int? _selectedCustomerId;
  int? _selectedMarketId;
  int? _selectedIndex;
  bool _showAll = false;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;
  bool get _canAdd => !_showAll && _selectedMarketId != null && !_busy;
  ManagedUser? get _selectedUser {
    final index = _selectedIndex;
    return index == null || index >= _rows.length ? null : _rows[index];
  }

  @override
  void initState() {
    super.initState();
    _selectedCooperatorId = widget.initialCooperator.id;
    _selectedCustomerId = widget.initialCustomer.customerId;
    _selectedMarketId = widget.initialMarket.marketId;
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final cooperators = await widget.loadCooperators();
      final customers = await widget.loadCustomers(_selectedCooperatorId);
      final markets = await widget.loadMarkets(_selectedCustomerId!);
      final users = await widget.loadUsers(_selectedMarketId!);
      if (!mounted) return;
      setState(() {
        _cooperators = [
          widget.initialCooperator,
          ...cooperators.where(
            (value) => value.id != widget.initialCooperator.id,
          ),
        ];
        _customers = customers;
        _markets = markets ?? const [];
        _rows = users;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeCooperator(String? id) async {
    if (id == null || _busy) return;
    setState(() {
      _loading = true;
      _selectedCooperatorId = id;
      _selectedCustomerId = null;
      _selectedMarketId = null;
      _customers = const [];
      _markets = const [];
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final customers = await widget.loadCustomers(id);
      if (mounted) setState(() => _customers = customers);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeCustomer(int? id) async {
    if (id == null || _busy) return;
    setState(() {
      _loading = true;
      _selectedCustomerId = id;
      _selectedMarketId = null;
      _markets = const [];
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final markets = await widget.loadMarkets(id) ?? const <Market>[];
      if (markets.isEmpty) {
        if (mounted) setState(() => _markets = const []);
        return;
      }
      final first = markets.first;
      final users = await widget.loadUsers(first.marketId);
      if (!mounted) return;
      setState(() {
        _markets = markets;
        _selectedMarketId = first.marketId;
        _rows = users;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeMarket(int? id) async {
    if (id == null || _busy) return;
    setState(() {
      _loading = true;
      _selectedMarketId = id;
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final users = await widget.loadUsers(id);
      if (mounted) setState(() => _rows = users);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleShowAll(bool value) async {
    if (_busy) return;
    setState(() {
      _loading = true;
      _showAll = value;
      _rows = const [];
      _selectedIndex = null;
    });
    try {
      final users = value
          ? await widget.loadCooperatorUsers(_selectedCooperatorId)
          : _selectedMarketId == null
          ? const <ManagedUser>[]
          : await widget.loadUsers(_selectedMarketId!);
      if (mounted) setState(() => _rows = users);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    final users = _showAll
        ? await widget.loadCooperatorUsers(_selectedCooperatorId)
        : await widget.loadUsers(_selectedMarketId!);
    if (!mounted) return;
    setState(() {
      _rows = users;
      _selectedIndex = null;
    });
  }

  Future<void> _add() async {
    if (!_canAdd) return;
    final draft = await _showInputDialog();
    if (draft == null || !mounted) return;
    if (await widget.lookupUser(draft.userId) != null) {
      if (mounted) await _showDuplicateMessage(draft.userId);
      return;
    }
    await _writeThenReload(() => widget.insert(draft), '추가가 완료되었습니다!');
  }

  Future<void> _edit(ManagedUser selected, int index) async {
    if (_busy) return;
    setState(() => _selectedIndex = index);
    final draft = await _showInputDialog(initial: selected);
    if (draft == null || !mounted) return;
    final duplicate = await widget.lookupUser(draft.userId);
    if (duplicate != null && draft.userId != selected.userId) {
      if (mounted) await _showDuplicateMessage(draft.userId);
      return;
    }
    await _writeThenReload(
      () => widget.update(selected.userId, draft),
      '수정이 완료되었습니다!',
    );
  }

  Future<void> _deleteSelected() async {
    final selected = _selectedUser;
    if (_busy || selected == null) return;
    final confirmed = await _confirmDelete();
    if (confirmed != true || !mounted) return;
    await _writeThenReload(
      () => widget.delete(selected.userId),
      '삭제가 완료되었습니다!',
    );
  }

  void _searchNext() {
    final query = _searchController.text;
    if (query.isEmpty || _rows.isEmpty) return;
    final start = (_selectedIndex ?? -1) + 1;
    int? found;
    for (var offset = 0; offset < _rows.length; offset += 1) {
      final index = (start + offset) % _rows.length;
      if (_rows[index].name.contains(query)) {
        found = index;
        break;
      }
    }
    if (found == null) {
      _showMessage('검색 결과가 없습니다.');
    } else {
      setState(() => _selectedIndex = found);
    }
  }

  Future<void> _writeThenReload(
    Future<void> Function() write,
    String message,
  ) async {
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    var committed = false;
    var closeAfterWrite = false;
    try {
      await write();
      committed = true;
      await _reload();
      if (mounted) await _showMessage(message);
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

  Future<ManagedUser?> _showInputDialog({ManagedUser? initial}) async {
    widget.controller.setActiveEditing(true);
    try {
      return await showBlockingModelessOverlayDialog<ManagedUser>(
        context: context,
        builder: (overlayContext, close) => _ManagedUserInputDialog(
          marketId: initial?.marketId ?? _selectedMarketId!,
          initial: initial,
          onCancel: () => close(null),
          onApply: close,
        ),
      );
    } finally {
      widget.controller.setActiveEditing(false);
    }
  }

  Future<void> _showDuplicateMessage(String id) =>
      _showMessage(" '$id' 는 이미 존재하는 ID입니다!\n다른 ID를 선택해주세요!");

  Future<bool?> _confirmDelete() => showBlockingModelessOverlayDialog<bool>(
    context: context,
    builder: (overlayContext, close) => AlertDialog(
      title: const Text('사용자 삭제'),
      content: const Text('해당 사용자를 정말 삭제하시겠습니까?'),
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

  List<FortuneTableColumn<ManagedUser>> get _columns => [
    FortuneTableColumn(
      id: 'customer',
      header: '거래처',
      text: (value) => value.customerName,
    ),
    FortuneTableColumn(
      id: 'market',
      header: '지점',
      text: (value) => value.marketName,
    ),
    if (widget.showCredentials)
      FortuneTableColumn(
        id: 'userId',
        header: '사용자 ID',
        text: (value) => value.userId,
      ),
    if (widget.showCredentials)
      FortuneTableColumn(
        id: 'password',
        header: '비밀번호',
        text: (value) => value.password,
      ),
    FortuneTableColumn(
      id: 'name',
      header: '이름',
      text: (value) => value.name,
      fillRemaining: true,
    ),
    FortuneTableColumn(
      id: 'grade',
      header: '등급',
      text: (value) => value.grade.label,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedUser != null && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          Align(
            key: const ValueKey('userScopeSelectors'),
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    key: ValueKey('userCooperatorLabel'),
                    width: 76,
                    child: Text('협력업체'),
                  ),
                  _selector<String>(
                    key: 'userCooperatorSelector',
                    width: 180,
                    value: _selectedCooperatorId,
                    enabled: widget.cooperatorSelectionEnabled && !_showAll,
                    items: [
                      for (final value in _cooperators)
                        DropdownMenuItem(
                          value: value.id,
                          child: Text(value.name),
                        ),
                    ],
                    onChanged: _changeCooperator,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    key: ValueKey('userCustomerLabel'),
                    width: 52,
                    child: Text('거래처'),
                  ),
                  _selector<int>(
                    key: 'userCustomerSelector',
                    width: 190,
                    value: _selectedCustomerId,
                    enabled: widget.customerSelectionEnabled && !_showAll,
                    items: [
                      for (final value in _customers)
                        DropdownMenuItem(
                          value: value.customerId,
                          child: Text(value.customerName),
                        ),
                    ],
                    onChanged: _changeCustomer,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    key: ValueKey('userMarketLabel'),
                    width: 40,
                    child: Text('지점'),
                  ),
                  _selector<int>(
                    key: 'userMarketSelector',
                    width: 170,
                    value: _selectedMarketId,
                    enabled: widget.marketSelectionEnabled && !_showAll,
                    items: [
                      for (final value in _markets)
                        DropdownMenuItem(
                          value: value.marketId,
                          child: Text(value.name),
                        ),
                    ],
                    onChanged: _changeMarket,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    key: const ValueKey('userShowAllCheckbox'),
                    value: _showAll,
                    onChanged: widget.customerSelectionEnabled && !_busy
                        ? (value) => _toggleShowAll(value == true)
                        : null,
                  ),
                  const Text('전체 표시'),
                ],
              ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('userSearchField'),
                  controller: _searchController,
                  decoration: const InputDecoration(labelText: '이름 검색'),
                  onSubmitted: (_) => _searchNext(),
                ),
              ),
              IconButton(
                key: const ValueKey('userSearchButton'),
                tooltip: '다음 사용자 검색',
                onPressed: _busy ? null : _searchNext,
                icon: const Icon(Icons.search),
              ),
              const SizedBox(width: 16),
              IconButton(
                key: const ValueKey('userAddButton'),
                tooltip: '사용자 추가',
                onPressed: _canAdd ? _add : null,
                icon: const Icon(Icons.add),
              ),
              IconButton(
                key: const ValueKey('userDeleteButton'),
                tooltip: '선택한 사용자 삭제',
                onPressed: hasSelection ? _deleteSelected : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FortuneTable<ManagedUser>(
              rows: _rows,
              columns: _columns,
              selectedIndex: _selectedIndex,
              onRowSelected: (row, index) =>
                  setState(() => _selectedIndex = index),
              onRowDoubleTap: _edit,
              fillLastColumn: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selector<T>({
    required String key,
    required double width,
    required T? value,
    required bool enabled,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => SizedBox(
    width: width,
    child: ModelessDropdownFormField<T>(
      key: ValueKey(key),
      initialValue: items.any((item) => item.value == value) ? value : null,
      items: items,
      onChanged: enabled && !_busy ? onChanged : null,
    ),
  );
}

class _ManagedUserInputDialog extends StatefulWidget {
  const _ManagedUserInputDialog({
    required this.marketId,
    required this.initial,
    required this.onCancel,
    required this.onApply,
  });

  final int marketId;
  final ManagedUser? initial;
  final VoidCallback onCancel;
  final ValueChanged<ManagedUser> onApply;

  @override
  State<_ManagedUserInputDialog> createState() =>
      _ManagedUserInputDialogState();
}

class _ManagedUserInputDialogState extends State<_ManagedUserInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _password;
  late final TextEditingController _passwordCheck;
  late final TextEditingController _name;
  late UserGrade _grade;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = TextEditingController(text: initial?.userId ?? '');
    _password = TextEditingController(text: initial?.password ?? '');
    _passwordCheck = TextEditingController(text: initial?.password ?? '');
    _name = TextEditingController(text: initial?.name ?? '');
    _grade = initial?.grade ?? UserGrade.CLIENT_USER;
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _passwordCheck.dispose();
    _name.dispose();
    super.dispose();
  }

  void _apply() {
    if (_formKey.currentState?.validate() != true) return;
    widget.onApply(
      ManagedUser(
        userId: _id.text,
        marketId: widget.marketId,
        name: _name.text,
        password: _password.text,
        grade: _grade,
        marketName: widget.initial?.marketName ?? '',
        customerName: widget.initial?.customerName ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlockingModelessDialogFrame(
    title: widget.initial == null ? '사용자 추가' : '사용자 수정',
    width: 480,
    height: 500,
    onClose: widget.onCancel,
    footer: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: widget.onCancel, child: const Text('취소')),
          const SizedBox(width: 8),
          FilledButton(
            key: const ValueKey('managedUserApplyButton'),
            onPressed: _apply,
            child: const Text('적용'),
          ),
        ],
      ),
    ),
    child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('managedUserIdField', '사용자 ID', _id, 'ID를 입력해주세요!'),
          _field(
            'managedUserPasswordField',
            '비밀번호',
            _password,
            '비밀번호를 입력해주세요!',
            obscure: true,
          ),
          _field(
            'managedUserPasswordCheckField',
            '비밀번호 확인',
            _passwordCheck,
            '비밀번호 확인을 입력해주세요!',
            obscure: true,
            validator: (value) => value != _password.text
                ? '비밀번호 확인입력이 일치하지않습니다! 비밀번호 입력을 다시 확인해주세요!'
                : null,
          ),
          _field('managedUserNameField', '이름', _name, '이름을 입력해주세요!'),
          ModelessDropdownFormField<UserGrade>(
            key: const ValueKey('managedUserGradeField'),
            initialValue: _grade,
            items: const [
              DropdownMenuItem(
                value: UserGrade.CLIENT_USER,
                child: Text('일반 사용자'),
              ),
              DropdownMenuItem(
                value: UserGrade.MANAGER_USER,
                child: Text('책임자'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _grade = value);
            },
          ),
        ],
      ),
    ),
  );

  Widget _field(
    String key,
    String label,
    TextEditingController controller,
    String requiredMessage, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey(key),
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) return requiredMessage;
        return validator?.call(value);
      },
    ),
  );
}
