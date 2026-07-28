import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/status_print.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/page_home/item_manager_table_dimensions.dart';
import 'package:label_manager/widgets/blocking_date_picker.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef StatusPrintQuery = Future<List<StatusPrintRow>> Function(
  StatusPrintQuerySpec spec,
);
typedef StatusPrintDetailQuery = Future<StatusPrintDetail> Function(
  String statusId,
);
typedef StatusPrintCooperatorLoader = Future<List<Cooperator>> Function();
typedef StatusPrintCustomerLoader =
    Future<List<Customer>> Function(String cooperatorId);
typedef StatusPrintBrandLoader = Future<List<Brand>?> Function(int customerId);
typedef StatusPrintLabelSizeLoader =
    Future<List<LabelSize>?> Function(int brandId);
typedef StatusPrintColumnNamesLoader = Future<List<String>> Function(
  List<int> labelSizeIds,
);

const Color statusPrintTotalColor = Color(0xFFD7E4BC);
const Color statusPrintDeletedColor = Color(0xFFF7EB00);

enum StatusPrintRowKind { total, deleted, result }

class StatusPrintTableRow {
  const StatusPrintTableRow._({
    required this.kind,
    this.summaryLabel = '',
    this.summaryCount = 0,
    this.result,
  });

  const StatusPrintTableRow.summary({
    required StatusPrintRowKind kind,
    required String label,
    required int count,
  }) : this._(kind: kind, summaryLabel: label, summaryCount: count);

  const StatusPrintTableRow.result(StatusPrintRow value)
    : this._(kind: StatusPrintRowKind.result, result: value);

  final StatusPrintRowKind kind;
  final String summaryLabel;
  final int summaryCount;
  final StatusPrintRow? result;

  bool get isSummary => kind != StatusPrintRowKind.result;
  int get printCount => result?.printCount ?? summaryCount;
  String get itemName => result?.itemName ?? summaryLabel;
}

Color? statusPrintRowColor(StatusPrintTableRow row) => switch (row.kind) {
  StatusPrintRowKind.total => statusPrintTotalColor,
  StatusPrintRowKind.deleted => statusPrintDeletedColor,
  StatusPrintRowKind.result when row.result!.deleted => statusPrintDeletedColor,
  StatusPrintRowKind.result => null,
};

class StatusPrintDialogContent extends StatefulWidget {
  const StatusPrintDialogContent({
    super.key,
    required this.userGrade,
    required this.initialCooperator,
    required this.initialCustomer,
    this.query = StatusPrintDAO.select,
    this.queryDetail = StatusPrintDAO.selectDetail,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.loadBrands = BrandDAO.selectByCustomerIdByBrandOrder,
    this.loadLabelSizes = LabelSizeDAO.selectByBrandIdByLabelSizeOrder,
    this.loadColumnNames = TColumnDAO.selectNamesByLabelSizeIds,
  });

  final UserGrade userGrade;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final StatusPrintQuery query;
  final StatusPrintDetailQuery queryDetail;
  final StatusPrintCooperatorLoader loadCooperators;
  final StatusPrintCustomerLoader loadCustomers;
  final StatusPrintBrandLoader loadBrands;
  final StatusPrintLabelSizeLoader loadLabelSizes;
  final StatusPrintColumnNamesLoader loadColumnNames;

  @override
  State<StatusPrintDialogContent> createState() =>
      _StatusPrintDialogContentState();
}

class _StatusPrintDialogContentState extends State<StatusPrintDialogContent> {
  static const int _allId = -1;

  final _itemNameController = TextEditingController();
  final _searchValueController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  List<Brand> _brands = const [];
  List<LabelSize> _labelSizes = const [];
  List<String> _searchColumns = const [statusPrintElementColumn];
  String? _selectedCooperatorId;
  int? _selectedCustomerId;
  int _selectedBrandId = _allId;
  int _selectedLabelSizeId = _allId;
  String _selectedSearchColumn = statusPrintElementColumn;
  bool _exactMatch = false;
  List<StatusPrintTableRow> _rows = const [];
  bool _initializing = true;
  bool _querying = false;

  bool get _isSystemAdmin => widget.userGrade == UserGrade.SYSTEM_ADMIN_USER;
  int get _effectiveCustomerId => _isSystemAdmin
      ? (_selectedCustomerId ?? widget.initialCustomer.customerId)
      : widget.initialCustomer.customerId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
    _selectedCooperatorId = widget.initialCooperator.id;
    _selectedCustomerId = widget.initialCustomer.customerId;
    _initializeFilters();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _searchValueController.dispose();
    super.dispose();
  }

  Future<void> _initializeFilters() async {
    try {
      if (_isSystemAdmin) {
        _cooperators = _withInitialCooperator(await widget.loadCooperators());
        _customers = _withInitialCustomer(
          await widget.loadCustomers(widget.initialCooperator.id),
        );
      }
      await _loadCustomerScope(widget.initialCustomer.customerId);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  List<Cooperator> _withInitialCooperator(List<Cooperator> values) => [
    widget.initialCooperator,
    ...values.where((value) => value.id != widget.initialCooperator.id),
  ];

  List<Customer> _withInitialCustomer(List<Customer> values) => [
    widget.initialCustomer,
    ...values.where(
      (value) => value.customerId != widget.initialCustomer.customerId,
    ),
  ];

  Future<void> _loadCustomerScope(int customerId) async {
    _brands = await widget.loadBrands(customerId) ?? const [];
    _selectedBrandId = _allId;
    _labelSizes = await _loadLabelSizesForBrands(_brands);
    _selectedLabelSizeId = _allId;
    await _loadSearchColumns(_labelSizes);
  }

  Future<List<LabelSize>> _loadLabelSizesForBrands(List<Brand> brands) async {
    final groups = await Future.wait([
      for (final brand in brands) widget.loadLabelSizes(brand.brandId),
    ]);
    return [for (final group in groups) ...?group];
  }

  Future<void> _loadSearchColumns(List<LabelSize> labelSizes) async {
    final loadedNames = await widget.loadColumnNames([
      for (final labelSize in labelSizes) labelSize.labelSizeId,
    ]);
    final names = <String>{statusPrintElementColumn};
    for (final name in loadedNames) {
      if (name.isNotEmpty) names.add(name);
    }
    _searchColumns = names.toList(growable: false);
    if (!_searchColumns.contains(_selectedSearchColumn)) {
      _selectedSearchColumn = statusPrintElementColumn;
    }
  }

  Future<void> _changeCooperator(String? cooperatorId) async {
    if (cooperatorId == null || _initializing || _querying) return;
    setState(() {
      _initializing = true;
      _selectedCooperatorId = cooperatorId;
      _selectedCustomerId = null;
      _customers = const [];
      _clearResults();
    });
    try {
      final customers = await widget.loadCustomers(cooperatorId);
      if (!mounted) return;
      final selected = customers
          .where(
            (value) =>
                value.customerId == widget.initialCustomer.customerId,
          )
          .firstOrNull;
      _customers = customers;
      _selectedCustomerId = selected?.customerId ?? customers.firstOrNull?.customerId;
      final customerId = _selectedCustomerId;
      if (customerId != null) await _loadCustomerScope(customerId);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _changeCustomer(int? customerId) async {
    if (customerId == null || _initializing || _querying) return;
    setState(() {
      _initializing = true;
      _selectedCustomerId = customerId;
      _clearResults();
    });
    try {
      await _loadCustomerScope(customerId);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _changeBrand(int? brandId) async {
    if (brandId == null || _initializing || _querying) return;
    setState(() {
      _initializing = true;
      _selectedBrandId = brandId;
      _selectedLabelSizeId = _allId;
      _clearResults();
    });
    try {
      _labelSizes = brandId == _allId
          ? await _loadLabelSizesForBrands(_brands)
          : await widget.loadLabelSizes(brandId) ?? const [];
      await _loadSearchColumns(_labelSizes);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _changeLabelSize(int? labelSizeId) async {
    if (labelSizeId == null || _initializing || _querying) return;
    setState(() {
      _initializing = true;
      _selectedLabelSizeId = labelSizeId;
      _clearResults();
    });
    try {
      final selected = labelSizeId == _allId
          ? _labelSizes
          : _labelSizes
                .where((value) => value.labelSizeId == labelSizeId)
                .toList(growable: false);
      await _loadSearchColumns(selected);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _clearResults() => _rows = const [];

  Future<void> _query() async {
    if (_querying || _initializing) return;
    setState(() => _querying = true);
    try {
      final results = await widget.query(
        StatusPrintQuerySpec(
          startDate: DateFormat('yyyyMMdd').format(_startDate),
          endDate: DateFormat('yyyyMMdd').format(_endDate),
          customerId: _effectiveCustomerId,
          brandId: _selectedBrandId == _allId ? null : _selectedBrandId,
          labelSizeId: _selectedLabelSizeId == _allId
              ? null
              : _selectedLabelSizeId,
          itemName: _itemNameController.text,
          searchColumn: _selectedSearchColumn,
          searchText: _searchValueController.text,
          exactMatch: _exactMatch,
        ),
      );
      final total = results.fold<int>(
        0,
        (sum, result) => sum + result.printCount,
      );
      final deleted = results
          .where((result) => result.deleted)
          .fold<int>(0, (sum, result) => sum + result.printCount);
      if (!mounted) return;
      setState(() {
        _rows = [
          StatusPrintTableRow.summary(
            kind: StatusPrintRowKind.total,
            label: '[총 발행 매수]',
            count: total,
          ),
          StatusPrintTableRow.summary(
            kind: StatusPrintRowKind.deleted,
            label: '[삭제된 품목 매수]',
            count: deleted,
          ),
          ...results.map(StatusPrintTableRow.result),
        ];
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _querying = false);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showBlockingDatePicker(
      context: context,
      title: start ? '시작일' : '종료일',
      initialDate: start ? _startDate : _endDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _clearResults();
    });
  }

  Future<void> _showDetail(StatusPrintTableRow row) async {
    final result = row.result;
    if (result == null) return;
    try {
      final detail = await widget.queryDetail(result.statusId);
      if (!mounted) return;
      await showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (overlayContext, close) => BlockingModelessDialogFrame(
          title: '발행 통계 상세',
          width: 820,
          height: 560,
          onClose: () => close(null),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('품명  ${detail.itemName}'),
                const SizedBox(height: 6),
                Text('주원료  ${detail.itemElement}'),
                const SizedBox(height: 12),
                Expanded(
                  child: FortuneTable<StatusPrintDetailRow>(
                    rows: detail.rows,
                    columns: [
                      FortuneTableColumn(
                        id: 'name',
                        header: '이름',
                        text: (value) => value.columnName,
                      ),
                      FortuneTableColumn(
                        id: 'savedAt',
                        header: '저장일',
                        text: (value) => value.changeDeleteDate,
                      ),
                      FortuneTableColumn(
                        id: 'value',
                        header: '값',
                        text: (value) => value.value,
                        fillRemaining: true,
                      ),
                    ],
                    autoFitColumns: true,
                    fillLastColumn: true,
                    keyboardSelectionShortcutsEnabled: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    }
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
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): _query},
      child: Focus(
        autofocus: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFilters(),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FortuneTable<StatusPrintTableRow>(
                        rows: _rows,
                        columns: _columns,
                        autoFitColumns: true,
                        fillLastColumn: true,
                        keyboardSelectionShortcutsEnabled: false,
                        rowColorBuilder: (row, index, selected) =>
                            statusPrintRowColor(row),
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

  Widget _buildFilters() {
    return Wrap(
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
          _dropdown<String>(
            width: 180,
            label: '협력업체',
            value: _selectedCooperatorId,
            items: [(value: widget.initialCooperator.id, text: widget.initialCooperator.name), ..._cooperators.map((value) => (value: value.id, text: value.name))]
                .fold(<String, String>{}, (map, value) => map..putIfAbsent(value.value, () => value.text))
                .entries
                .map((entry) => (value: entry.key, text: entry.value)),
            onChanged: _changeCooperator,
          ),
        if (_isSystemAdmin)
          _dropdown<int>(
            width: 200,
            label: '거래처',
            value: _selectedCustomerId,
            items: _customers.map(
              (value) => (value: value.customerId, text: value.customerName),
            ),
            onChanged: _changeCustomer,
          ),
        _dropdown<int>(
          width: 160,
          label: '브랜드',
          value: _selectedBrandId,
          items: [
            (value: _allId, text: '[전체 보기]'),
            ..._brands.map(
              (value) => (value: value.brandId, text: value.brandName),
            ),
          ],
          onChanged: _changeBrand,
        ),
        _dropdown<int>(
          width: 170,
          label: '라벨사이즈',
          value: _selectedLabelSizeId,
          items: [
            (value: _allId, text: '[전체 보기]'),
            ..._labelSizes.map(
              (value) =>
                  (value: value.labelSizeId, text: value.labelSizeName),
            ),
          ],
          onChanged: _changeLabelSize,
        ),
        _textField(label: '품목명', controller: _itemNameController),
        _dropdown<String>(
          width: 150,
          label: '검색 항목',
          value: _selectedSearchColumn,
          items: _searchColumns.map((value) => (value: value, text: value)),
          onChanged: (value) {
            if (value == null || _querying) return;
            setState(() {
              _selectedSearchColumn = value;
              _clearResults();
            });
          },
        ),
        _textField(label: '검색 값', controller: _searchValueController),
        SizedBox(
          width: 118,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('완전 일치'),
            value: _exactMatch,
            onChanged: _querying
                ? null
                : (value) => setState(() {
                    _exactMatch = value ?? false;
                    _clearResults();
                  }),
          ),
        ),
        FilledButton.icon(
          onPressed: _initializing || _querying ? null : _query,
          icon: const Icon(Icons.search),
          label: const Text('조회'),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required double width,
    required String label,
    required T? value,
    required Iterable<({T value, String text})> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: ModelessDropdownFormField<T>(
        key: ValueKey('$label:$value'),
        initialValue: value,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item.value, child: Text(item.text)),
        ],
        onChanged: _initializing || _querying ? null : onChanged,
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        enabled: !_querying,
        onSubmitted: (_) => _query(),
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }

  List<FortuneTableColumn<StatusPrintTableRow>> get _columns {
    FortuneTableColumn<StatusPrintTableRow> column({
      required String id,
      required String header,
      required String Function(StatusPrintTableRow row) text,
      double width = 130,
    }) => FortuneTableColumn(
      id: id,
      header: header,
      text: text,
      initialWidth: width,
      onDoubleTap: (row, index) => _showDetail(row),
    );

    return [
      column(
        id: 'date',
        header: '발행일',
        text: (row) => row.result?.printDate ?? row.summaryLabel,
        width: 170,
      ),
      column(
        id: 'count',
        header: '발행매수',
        text: (row) => row.printCount.toString(),
      ),
      column(
        id: 'item',
        header: '품목명',
        text: (row) => row.result?.itemName ?? '',
        width: 180,
      ),
      column(
        id: 'searchValue',
        header: _selectedSearchColumn,
        text: (row) => row.result?.searchValue ?? '',
        width: _selectedSearchColumn == statusPrintElementColumn
            ? itemManagerExpandedElementColumnWidth
            : 180,
      ),
      column(
        id: 'brand',
        header: '브랜드',
        text: (row) => row.result?.brandName ?? '',
      ),
      column(
        id: 'labelSize',
        header: '라벨사이즈',
        text: (row) => row.result?.labelSizeName ?? '',
      ),
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