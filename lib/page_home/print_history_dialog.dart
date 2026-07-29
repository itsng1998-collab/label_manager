import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/print_log.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/widgets/blocking_date_picker.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef PrintHistoryQuery =
    Future<List<PrintLog>> Function({
      required String startDate,
      required String endDate,
      required PrintLogSearchType searchType,
      required String searchText,
      int? customerId,
    });

typedef PrintHistorySumQuery =
    Future<int> Function({
      String? startDate,
      String? endDate,
      String? customerName,
      String? labelSizeName,
    });

typedef PrintHistoryCooperatorLoader = Future<List<Cooperator>> Function();
typedef PrintHistoryCustomerLoader =
    Future<List<Customer>> Function(String cooperatorId);

enum PrintHistoryRowKind { total, period, labelSize, log }

class PrintHistoryTableRow {
  const PrintHistoryTableRow._({
    required this.kind,
    this.summaryLabel = '',
    this.summaryCustomerName = '',
    this.summaryPrintCount = 0,
    this.log,
  });

  const PrintHistoryTableRow.summary({
    required PrintHistoryRowKind kind,
    required String label,
    required String customerName,
    required int printCount,
  }) : this._(
         kind: kind,
         summaryLabel: label,
         summaryCustomerName: customerName,
         summaryPrintCount: printCount,
       );

  const PrintHistoryTableRow.log(PrintLog value)
    : this._(kind: PrintHistoryRowKind.log, log: value);

  final PrintHistoryRowKind kind;
  final String summaryLabel;
  final String summaryCustomerName;
  final int summaryPrintCount;
  final PrintLog? log;

  bool get isSummary => kind != PrintHistoryRowKind.log;
  String get customerName => log?.customerName ?? summaryCustomerName;
  String get itemName => log?.itemName ?? summaryLabel;
  int get printCount => log?.printCount ?? summaryPrintCount;
}

class PrintHistoryDialogContent extends StatefulWidget {
  const PrintHistoryDialogContent({
    super.key,
    required this.userGrade,
    required this.initialCooperator,
    required this.initialCustomer,
    this.query = PrintLogDAO.select,
    this.querySum = PrintLogDAO.selectPrintCountSum,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
  });

  final UserGrade userGrade;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final PrintHistoryQuery query;
  final PrintHistorySumQuery querySum;
  final PrintHistoryCooperatorLoader loadCooperators;
  final PrintHistoryCustomerLoader loadCustomers;

  @override
  State<PrintHistoryDialogContent> createState() =>
      _PrintHistoryDialogContentState();
}

class _PrintHistoryDialogContentState extends State<PrintHistoryDialogContent> {
  static const _allCustomer = Customer(
    customerId: -1,
    cooperatorId: '',
    customerName: '[전체 보기]',
  );

  final _searchController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  Cooperator? _selectedCooperator;
  Customer? _selectedCustomer;
  PrintLogSearchType _searchType = PrintLogSearchType.itemName;
  List<PrintHistoryTableRow> _rows = const [];
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _customers = _customerOptions(
          customers,
          selected: widget.initialCustomer,
        );
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  List<Customer> _customerOptions(
    List<Customer> customers, {
    Customer? selected,
  }) => [
    _allCustomer,
    ?selected,
    ...customers.where(
      (customer) =>
          selected == null || customer.customerId != selected.customerId,
    ),
  ];

  Future<void> _changeCooperator(Cooperator? cooperator) async {
    if (cooperator == null || _querying) return;
    setState(() {
      _selectedCooperator = cooperator;
      _selectedCustomer = null;
      _customers = const [];
      _rows = const [];
      _initializing = true;
    });
    try {
      final customers = await widget.loadCustomers(cooperator.id);
      if (!mounted) return;
      final isInitial = cooperator.id == widget.initialCooperator.id;
      final selected = isInitial ? widget.initialCustomer : _allCustomer;
      setState(() {
        _customers = _customerOptions(
          customers,
          selected: isInitial ? selected : null,
        );
        _selectedCustomer = selected;
        _syncCustomerSearchText();
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _changeCustomer(Customer? customer) {
    if (customer == null || _querying) return;
    setState(() {
      _selectedCustomer = customer;
      _rows = const [];
      _syncCustomerSearchText();
    });
  }

  void _changeSearchType(PrintLogSearchType? searchType) {
    if (searchType == null || _querying) return;
    setState(() {
      _searchType = searchType;
      _rows = const [];
      _syncCustomerSearchText();
    });
  }

  void _syncCustomerSearchText() {
    _searchController.text = _searchType == PrintLogSearchType.customerName
        ? (_selectedCustomer?.customerName ?? '')
        : '';
  }

  Future<void> _query() async {
    final customer = _selectedCustomer;
    if (customer == null || _querying || _initializing) return;
    setState(() => _querying = true);
    try {
      final startDate = DateFormat('yyyyMMdd').format(_startDate);
      final endDate = DateFormat('yyyyMMdd').format(_endDate);
      var searchText = _searchController.text;
      if (_searchType == PrintLogSearchType.customerName &&
          searchText.isEmpty) {
        searchText = customer.customerName;
      }
      final customerId = customer.customerId == _allCustomer.customerId
          ? null
          : customer.customerId;
      final logs = await widget.query(
        startDate: startDate,
        endDate: endDate,
        searchType: _searchType,
        searchText: searchText,
        customerId: customerId,
      );
      final summaryCustomerName = customerId == null
          ? null
          : customer.customerName;
      final total = await widget.querySum(customerName: summaryCustomerName);
      final period = await widget.querySum(
        startDate: startDate,
        endDate: endDate,
        customerName: summaryCustomerName,
      );
      final nextRows = <PrintHistoryTableRow>[
        PrintHistoryTableRow.summary(
          kind: PrintHistoryRowKind.total,
          label: '[총 누계]',
          customerName: summaryCustomerName ?? '',
          printCount: total,
        ),
        PrintHistoryTableRow.summary(
          kind: PrintHistoryRowKind.period,
          label: '[기간별 합계]',
          customerName: summaryCustomerName ?? '',
          printCount: period,
        ),
      ];
      final customerIds = logs.map((log) => log.customerId).toSet();
      if (logs.isNotEmpty && customerIds.length == 1) {
        final customerName = logs.first.customerName;
        final labelSizes = <String>{for (final log in logs) log.labelSizeName};
        for (final labelSizeName in labelSizes) {
          final count = await widget.querySum(
            startDate: startDate,
            endDate: endDate,
            customerName: customerName,
            labelSizeName: labelSizeName,
          );
          if (count != 0) {
            nextRows.add(
              PrintHistoryTableRow.summary(
                kind: PrintHistoryRowKind.labelSize,
                label: '[라벨사이즈별 합계] $labelSizeName',
                customerName: customerName,
                printCount: count,
              ),
            );
          }
        }
      }
      nextRows.addAll(logs.map(PrintHistoryTableRow.log));
      if (mounted) setState(() => _rows = nextRows);
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

  Future<void> _showDetail(PrintHistoryTableRow row) {
    final log = row.log;
    if (log == null) return Future.value();
    final columnNames = log.columnNames;
    final savedCells = log.savedCells;
    final printCells = log.printCells;
    final rowCount = math.min(
      columnNames.length,
      math.min(savedCells.length, printCells.length),
    );
    final detailRows = [
      for (var index = 0; index < rowCount; index += 1)
        _PrintLogDetailRow(
          columnName: columnNames[index],
          savedValue: savedCells[index],
          printValue: printCells[index],
        ),
    ];
    return showBlockingModelessOverlayDialog<void>(
      context: context,
      builder: (overlayContext, close) => BlockingModelessDialogFrame(
        title: '발행내역 상세',
        width: 900,
        height: 560,
        onClose: () => close(null),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _PrintLogValueTable(
                  title: '저장값',
                  rows: detailRows,
                  value: (row) => row.savedValue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrintLogValueTable(
                  title: '출력값',
                  rows: detailRows,
                  value: (row) => row.printValue,
                  highlightDifferences: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): _query},
      child: Focus(
        autofocus: true,
        child: Padding(
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
                      width: 190,
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
                            : _changeCooperator,
                      ),
                    ),
                  if (_isSystemAdmin || _isCoopAdmin)
                    SizedBox(
                      width: 210,
                      child: ModelessDropdownFormField<Customer>(
                        key: ValueKey(_selectedCooperator?.id),
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
                            : _changeCustomer,
                      ),
                    ),
                  SizedBox(
                    width: 135,
                    child: ModelessDropdownFormField<PrintLogSearchType>(
                      initialValue: _searchType,
                      decoration: const InputDecoration(
                        labelText: '검색 종류',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: PrintLogSearchType.itemName,
                          child: Text('품명'),
                        ),
                        DropdownMenuItem(
                          value: PrintLogSearchType.userId,
                          child: Text('사용자ID'),
                        ),
                        DropdownMenuItem(
                          value: PrintLogSearchType.customerName,
                          child: Text('거래처'),
                        ),
                      ],
                      onChanged: _querying ? null : _changeSearchType,
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: TextField(
                      controller: _searchController,
                      enabled: !_querying,
                      onSubmitted: (_) => _query(),
                      decoration: const InputDecoration(
                        labelText: '검색어',
                        isDense: true,
                      ),
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
                      child: FortuneTable<PrintHistoryTableRow>(
                        rows: _rows,
                        columns: _columns,
                        autoFitColumns: true,
                        fillLastColumn: false,
                        keyboardSelectionShortcutsEnabled: false,
                        rowColorBuilder: (row, index, selected) =>
                            switch (row.kind) {
                              PrintHistoryRowKind.total => const Color(
                                0xFFE6B9B8,
                              ),
                              PrintHistoryRowKind.period ||
                              PrintHistoryRowKind.labelSize => const Color(
                                0xFFD7E4BC,
                              ),
                              PrintHistoryRowKind.log => null,
                            },
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
        ),
      ),
    );
  }

  List<FortuneTableColumn<PrintHistoryTableRow>> get _columns {
    FortuneTableColumn<PrintHistoryTableRow> column({
      required String id,
      required String header,
      required String Function(PrintHistoryTableRow row) text,
      double width = 110,
    }) => FortuneTableColumn(
      id: id,
      header: header,
      text: text,
      initialWidth: width,
      onDoubleTap: (row, index) => _showDetail(row),
    );

    return [
      column(id: 'customer', header: '거래처', text: (row) => row.customerName),
      column(
        id: 'brand',
        header: '브랜드',
        text: (row) => row.log?.brandName ?? '',
      ),
      column(
        id: 'labelSize',
        header: '라벨사이즈',
        text: (row) => row.log?.labelSizeName ?? '',
      ),
      column(id: 'item', header: '품명', text: (row) => row.itemName, width: 150),
      column(
        id: 'count',
        header: '발행 수량',
        text: (row) => row.printCount.toString(),
      ),
      column(
        id: 'userId',
        header: '사용자 ID',
        text: (row) => row.log?.userId ?? '',
      ),
      column(
        id: 'userName',
        header: '사용자 이름',
        text: (row) => row.log?.userName ?? '',
      ),
      column(
        id: 'userGrade',
        header: '사용자 등급',
        text: (row) => _userGradeLabel(row.log?.userGrade),
      ),
      column(
        id: 'dateTime',
        header: '발행 시각',
        text: (row) => row.log?.dateTime ?? '',
        width: 150,
      ),
      column(
        id: 'printer',
        header: '프린터',
        text: (row) => row.log?.printerName ?? '',
        width: 150,
      ),
      column(
        id: 'width',
        header: '서식 폭',
        text: (row) => row.log?.formWidth.toString() ?? '',
      ),
      column(
        id: 'height',
        header: '서식 높이',
        text: (row) => row.log?.formHeight.toString() ?? '',
      ),
      column(
        id: 'leftMargin',
        header: '왼쪽 여백',
        text: (row) => row.log?.leftMargin.toString() ?? '',
      ),
      column(
        id: 'rightMargin',
        header: '오른쪽 여백',
        text: (row) => row.log?.rightMargin.toString() ?? '',
      ),
      column(
        id: 'topMargin',
        header: '위 여백',
        text: (row) => row.log?.topMargin.toString() ?? '',
      ),
      column(
        id: 'leftPush',
        header: '왼쪽 밀기',
        text: (row) => row.log?.leftPush.toString() ?? '',
      ),
      column(
        id: 'topPush',
        header: '위 밀기',
        text: (row) => row.log?.topPush.toString() ?? '',
      ),
      column(
        id: 'appendant',
        header: '추가 영역',
        text: (row) => row.log?.appendant.toString() ?? '',
      ),
    ];
  }

  String _userGradeLabel(int? code) {
    for (final grade in UserGrade.values) {
      if (grade.code == code) return grade.label;
    }
    return code?.toString() ?? '';
  }
}

class _PrintLogDetailRow {
  const _PrintLogDetailRow({
    required this.columnName,
    required this.savedValue,
    required this.printValue,
  });

  final String columnName;
  final String savedValue;
  final String printValue;
  bool get isDifferent => savedValue != printValue;
}

class _PrintLogValueTable extends StatelessWidget {
  const _PrintLogValueTable({
    required this.title,
    required this.rows,
    required this.value,
    this.highlightDifferences = false,
  });

  final String title;
  final List<_PrintLogDetailRow> rows;
  final String Function(_PrintLogDetailRow row) value;
  final bool highlightDifferences;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Expanded(
          child: FortuneTable<_PrintLogDetailRow>(
            rows: rows,
            columns: [
              FortuneTableColumn(
                id: 'column',
                header: '컬럼',
                text: (row) => row.columnName,
              ),
              FortuneTableColumn(
                id: 'value',
                header: '값',
                text: value,
                fillRemaining: true,
              ),
            ],
            autoFitColumns: true,
            fillLastColumn: true,
            keyboardSelectionShortcutsEnabled: false,
            rowColorBuilder: highlightDifferences
                ? (row, index, selected) =>
                      row.isDifferent ? const Color(0xFFFFC000) : null
                : null,
          ),
        ),
      ],
    );
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
