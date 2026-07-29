import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/login_log.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/widgets/blocking_date_picker.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

typedef LoginHistoryQuery = Future<List<LoginLog>> Function({
  required String startDate,
  required String endDate,
  required int customerId,
});

typedef LoginHistoryCooperatorLoader = Future<List<Cooperator>> Function();
typedef LoginHistoryCustomerLoader =
    Future<List<Customer>> Function(String cooperatorId);

class LoginHistoryDialogContent extends StatefulWidget {
  const LoginHistoryDialogContent({
    super.key,
    required this.userGrade,
    required this.initialCooperator,
    required this.initialCustomer,
    this.query = LoginLogDAO.selectBetweenDatesAndCustomer,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
  });

  final UserGrade userGrade;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final LoginHistoryQuery query;
  final LoginHistoryCooperatorLoader loadCooperators;
  final LoginHistoryCustomerLoader loadCustomers;

  @override
  State<LoginHistoryDialogContent> createState() =>
      _LoginHistoryDialogContentState();
}

class _LoginHistoryDialogContentState
    extends State<LoginHistoryDialogContent> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  Cooperator? _selectedCooperator;
  Customer? _selectedCustomer;
  List<LoginLog> _rows = const [];
  bool _initializing = true;
  bool _querying = false;

  bool get _isSystemAdmin =>
      widget.userGrade == UserGrade.SYSTEM_ADMIN_USER;
  bool get _isCoopAdmin => widget.userGrade == UserGrade.COOP_ADMIN_USER;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
    _selectedCooperator = widget.initialCooperator;
    _selectedCustomer = widget.initialCustomer;
    _initializeFilters();
  }

  Future<void> _initializeFilters() async {
    try {
      if (_isSystemAdmin) {
        _cooperators = await widget.loadCooperators();
      }
      if (_isSystemAdmin || _isCoopAdmin) {
        _customers = await widget.loadCustomers(widget.initialCooperator.id);
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _changeCooperator(Cooperator? cooperator) async {
    if (cooperator == null || _querying) return;
    setState(() {
      _selectedCooperator = cooperator;
      _selectedCustomer = null;
      _customers = const [];
      _initializing = true;
    });
    try {
      final customers = await widget.loadCustomers(cooperator.id);
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _query() async {
    final customer = _selectedCustomer;
    if (customer == null || _querying) return;
    setState(() => _querying = true);
    try {
      final rows = await widget.query(
        startDate: DateFormat('yyyyMMdd').format(_startDate),
        endDate: DateFormat('yyyyMMdd').format(_endDate),
        customerId: customer.customerId,
      );
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) {
        await _showMessage('검색결과가 없습니다!');
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _querying = false);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showBlockingDatePicker(
      context: context,
      title: start ? '시작일' : '종료일',
      initialDate: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              _DateField(
                label: '시작일',
                value: _startDate,
                onPressed: _querying ? null : () => _pickDate(start: true),
              ),
              _DateField(
                label: '종료일',
                value: _endDate,
                onPressed: _querying ? null : () => _pickDate(start: false),
              ),
              if (_isSystemAdmin)
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCooperator?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '협력업체',
                      isDense: true,
                    ),
                    items: [
                      for (final cooperator in _cooperators)
                        DropdownMenuItem(
                          value: cooperator.id,
                          child: Text(
                            cooperator.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _initializing || _querying
                        ? null
                        : (id) => _changeCooperator(
                            _cooperators.firstWhere(
                              (cooperator) => cooperator.id == id,
                            ),
                          ),
                  ),
                ),
              if (_isSystemAdmin || _isCoopAdmin)
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(_selectedCooperator?.id),
                    initialValue: _selectedCustomer?.customerId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '거래처',
                      isDense: true,
                    ),
                    items: [
                      for (final customer in _customers)
                        DropdownMenuItem(
                          value: customer.customerId,
                          child: Text(
                            customer.customerName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _initializing || _querying
                        ? null
                        : (id) => setState(
                            () => _selectedCustomer = _customers.firstWhere(
                              (customer) => customer.customerId == id,
                            ),
                          ),
                  ),
                ),
              FilledButton.icon(
                onPressed:
                    _initializing || _querying || _selectedCustomer == null
                    ? null
                    : _query,
                icon: const Icon(Icons.search),
                label: const Text('조회'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FortuneTable<LoginLog>(
                    rows: _rows,
                    columns: _columns,
                    autoFitColumns: true,
                    fillLastColumn: true,
                    keyboardSelectionShortcutsEnabled: false,
                  ),
                ),
                if (_initializing || _querying)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55FFFFFF),
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

  List<FortuneTableColumn<LoginLog>> get _columns => [
    FortuneTableColumn(id: 'userId', header: '사용자 ID', text: (row) => row.userId),
    FortuneTableColumn(
      id: 'userGrade',
      header: '사용자 등급',
      text: (row) => row.userGrade,
    ),
    FortuneTableColumn(
      id: 'loginDate',
      header: '시간',
      text: (row) => row.loginDate,
    ),
    FortuneTableColumn(
      id: 'condition',
      header: '로그인/로그아웃',
      text: (row) => row.loginCondition == LoginCondition.LOGIN ? '로그인' : '로그아웃',
    ),
    FortuneTableColumn(id: 'ip', header: 'IP주소', text: (row) => row.loginIP),
    FortuneTableColumn(
      id: 'customer',
      header: '거래처 이름',
      text: (row) => row.customerName,
    ),
    FortuneTableColumn(
      id: 'version',
      header: '프로그램 버전',
      text: (row) => row.programVersion,
    ),
  ];
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text('$label ${DateFormat('yyyy-MM-dd').format(value)}'),
      ),
    );
  }
}
