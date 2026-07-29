import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/content_save_history/data/content_save_log_dao.dart';
import 'package:label_manager/features/content_save_history/domain/content_save_log.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/widgets/blocking_date_picker.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef ContentSaveHistoryQuery =
    Future<List<ContentSaveLog>> Function({
      required String startDate,
      required String endDate,
      required int customerId,
    });

typedef ContentSaveHistoryCooperatorLoader =
    Future<List<Cooperator>> Function();
typedef ContentSaveHistoryCustomerLoader =
    Future<List<Customer>> Function(String cooperatorId);

class ContentSaveHistoryDialogContent extends StatefulWidget {
  const ContentSaveHistoryDialogContent({
    super.key,
    required this.userGrade,
    required this.initialCooperator,
    required this.initialCustomer,
    this.query = ContentSaveLogDAO.selectBetweenDatesAndCustomer,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
  });

  final UserGrade userGrade;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final ContentSaveHistoryQuery query;
  final ContentSaveHistoryCooperatorLoader loadCooperators;
  final ContentSaveHistoryCustomerLoader loadCustomers;

  @override
  State<ContentSaveHistoryDialogContent> createState() =>
      _ContentSaveHistoryDialogContentState();
}

class _ContentSaveHistoryDialogContentState
    extends State<ContentSaveHistoryDialogContent> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  Cooperator? _selectedCooperator;
  Customer? _selectedCustomer;
  List<ContentSaveLog> _rows = const [];
  bool _initializing = true;
  bool _querying = false;

  bool get _isSystemAdmin => widget.userGrade == UserGrade.SYSTEM_ADMIN_USER;
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
        final cooperators = await widget.loadCooperators();
        _cooperators = [
          widget.initialCooperator,
          ...cooperators.where(
            (cooperator) => cooperator.id != widget.initialCooperator.id,
          ),
        ];
      }
      if (_isSystemAdmin || _isCoopAdmin) {
        final customers = await widget.loadCustomers(
          widget.initialCooperator.id,
        );
        _customers = [
          widget.initialCustomer,
          ...customers.where(
            (customer) =>
                customer.customerId != widget.initialCustomer.customerId,
          ),
        ];
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _query() async {
    if (_querying || _initializing) return;
    final selectedCustomer = _selectedCustomer;
    if (_isSystemAdmin && selectedCustomer == null) return;
    setState(() => _querying = true);
    try {
      final rows = await widget.query(
        startDate: DateFormat('yyyyMMdd').format(_startDate),
        endDate: DateFormat('yyyyMMdd').format(_endDate),
        customerId: _isSystemAdmin
            ? selectedCustomer!.customerId
            : widget.initialCustomer.customerId,
      );
      if (!mounted) return;
      setState(() => _rows = rows);
      if (rows.isEmpty) await _showMessage('검색결과가 없습니다!');
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
      _rows = const [];
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

  Future<void> _showDetail(ContentSaveLog row) {
    return showBlockingModelessOverlayDialog<void>(
      context: context,
      builder: (overlayContext, close) => BlockingModelessDialogFrame(
        title: '데이터내용 이력 상세',
        width: 820,
        height: 520,
        onClose: () => close(null),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FortuneTable<ContentSaveLogDetail>(
            rows: row.details,
            columns: [
              FortuneTableColumn(
                id: 'column',
                header: '컬럼',
                text: (detail) => detail.columnName,
              ),
              FortuneTableColumn(
                id: 'content',
                header: '내용',
                text: (detail) => detail.content,
                fillRemaining: true,
              ),
            ],
            autoFitColumns: true,
            fillLastColumn: true,
            keyboardSelectionShortcutsEnabled: false,
          ),
        ),
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
                  child: ModelessDropdownFormField<Cooperator>(
                    initialValue: _selectedCooperator,
                    decoration: const InputDecoration(
                      labelText: '협력업체',
                      isDense: true,
                    ),
                    items: [
                      for (final cooperator in _cooperators)
                        DropdownMenuItem(
                          value: cooperator,
                          child: Text(cooperator.name),
                        ),
                    ],
                    onChanged: _initializing || _querying
                        ? null
                        : (value) => setState(() {
                            _selectedCooperator = value;
                            _rows = const [];
                          }),
                  ),
                ),
              if (_isSystemAdmin || _isCoopAdmin)
                SizedBox(
                  width: 230,
                  child: ModelessDropdownFormField<Customer>(
                    initialValue: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: '거래처',
                      isDense: true,
                    ),
                    items: [
                      for (final customer in _customers)
                        DropdownMenuItem(
                          value: customer,
                          child: Text(customer.customerName),
                        ),
                    ],
                    onChanged: _initializing || _querying
                        ? null
                        : (value) => setState(() {
                            _selectedCustomer = value;
                            _rows = const [];
                          }),
                  ),
                ),
              FilledButton.icon(
                onPressed: _initializing || _querying ? null : _query,
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
                  child: FortuneTable<ContentSaveLog>(
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

  List<FortuneTableColumn<ContentSaveLog>> get _columns {
    FortuneTableColumn<ContentSaveLog> column({
      required String id,
      required String header,
      required String Function(ContentSaveLog row) text,
      double width = 120,
    }) => FortuneTableColumn(
      id: id,
      header: header,
      text: text,
      initialWidth: width,
      onDoubleTap: (row, index) => _showDetail(row),
    );

    return [
      column(id: 'userId', header: '사용자 ID', text: (row) => row.userId),
      column(id: 'userGrade', header: '사용자 등급', text: (row) => row.userGrade),
      column(
        id: 'itemName',
        header: '품목명',
        text: (row) => row.itemName,
        width: 180,
      ),
      column(
        id: 'labelSize',
        header: '라벨사이즈',
        text: (row) => row.labelSizeName,
      ),
      column(
        id: 'saveDate',
        header: '저장 시각',
        text: (row) => row.saveDate,
        width: 160,
      ),
      column(id: 'ip', header: '저장 IP', text: (row) => row.saveIp, width: 150),
      column(id: 'status', header: '상태', text: (row) => row.saveStatus.label),
    ];
  }
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
