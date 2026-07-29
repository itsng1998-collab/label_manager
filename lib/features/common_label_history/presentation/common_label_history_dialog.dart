import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart'
  show FortuneTable, FortuneTableColumn;
import 'package:fortune_sheet/fortune_sheet.dart' as fs;
import 'package:intl/intl.dart';
import 'package:label_manager/features/common_label_history/data/common_label_history_dao.dart';
import 'package:label_manager/features/common_label_history/domain/common_label_history.dart';
import 'package:label_manager/features/cooperator/data/cooperator_dao.dart';
import 'package:label_manager/features/customer/data/customer_dao.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/label_sheet/label_sheet_save_codec.dart';
import 'package:label_manager/features/label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/blocking_date_picker.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/horizontal_pane_splitter.dart';
import 'package:label_manager/widgets/label_output_preview.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef CommonLabelHistoryQuery =
    Future<List<CommonLabelHistory>> Function({
      required String startDate,
      required String endDate,
      required int customerId,
    });
typedef CommonLabelHistoryCooperatorLoader = Future<List<Cooperator>> Function();
typedef CommonLabelHistoryCustomerLoader =
    Future<List<Customer>> Function(String cooperatorId);
typedef CommonLabelHistoryPreviewLoader =
    Future<fs.FortuneWorkbook?> Function(
      CommonLabelHistoryPayload payload, {
      required int width,
      required int height,
    });

  const Color commonLabelHistoryPreviewBorderColor = Color(0xFFD3D3D3);

  fs.FortuneWorkbook? commonLabelHistoryPreviewWorkbook(
    fs.FortuneWorkbook? workbook,
  ) => workbook?.copyWith(
    sheets: [
      for (final sheet in workbook.sheets)
        sheet.copyWith(showGridLines: false),
    ],
  );

Future<fs.FortuneWorkbook?> loadCommonLabelHistoryPreview(
  CommonLabelHistoryPayload payload, {
  required int width,
  required int height,
}) async {
  if (payload.usesSheet) {
    final workbook = labelSheetTryDecodeWorkbookSave(payload.value);
    return workbook == null
        ? null
        : labelSheetNormalizeWorkbookForCurrentSaveFormat(workbook);
  }
  if (payload.value.isEmpty) return null;
  final labelSize = LabelSize(
    labelSizeId: 0,
    brandId: 0,
    labelSizeName: '',
    labelSizeCommon: LabelSizeCommon(width: width, height: height, rtf: payload.value),
  );
  final workbook = await labelSheetWorkbookWithRtf(
    fs.FortuneWorkbook(
      sheets: [fs.FortuneSheet(id: 'common_label_history', name: 'Label')],
    ),
    labelSize: labelSize,
    labelRtf: payload.value,
  );
  return labelSheetNormalizeWorkbookForCurrentSaveFormat(workbook);
}

class CommonLabelHistoryDialogContent extends StatefulWidget {
  const CommonLabelHistoryDialogContent({
    super.key,
    required this.userGrade,
    required this.initialCooperator,
    required this.initialCustomer,
    this.query = CommonLabelHistoryDAO.selectBetweenDatesAndCustomer,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.loadPreview = loadCommonLabelHistoryPreview,
  });

  final UserGrade userGrade;
  final Cooperator initialCooperator;
  final Customer initialCustomer;
  final CommonLabelHistoryQuery query;
  final CommonLabelHistoryCooperatorLoader loadCooperators;
  final CommonLabelHistoryCustomerLoader loadCustomers;
  final CommonLabelHistoryPreviewLoader loadPreview;

  @override
  State<CommonLabelHistoryDialogContent> createState() =>
      _CommonLabelHistoryDialogContentState();
}

class _CommonLabelHistoryDialogContentState
    extends State<CommonLabelHistoryDialogContent> {
  static const double _splitterHeight = 7;
  static const double _minimumTableHeight = 120;
  static const double _minimumPreviewHeight = 140;
  late DateTime _startDate;
  late DateTime _endDate;
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  Cooperator? _selectedCooperator;
  Customer? _selectedCustomer;
  List<CommonLabelHistory> _rows = const [];
  CommonLabelHistory? _selectedRow;
  fs.FortuneWorkbook? _beforeWorkbook;
  fs.FortuneWorkbook? _afterWorkbook;
  bool _initializing = true;
  bool _querying = false;
  bool _loadingPreview = false;
  int _previewGeneration = 0;
  double _tableHeight = 220;
  double _tableHeightAtDragStart = 220;
  final LabelSheetZoomController _beforeZoomController =
      LabelSheetZoomController(initialPercent: 100, minPercent: 20, maxPercent: 500);
  final LabelSheetZoomController _afterZoomController =
      LabelSheetZoomController(initialPercent: 100, minPercent: 20, maxPercent: 500);

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
    _previewGeneration += 1;
    _beforeZoomController.dispose();
    _afterZoomController.dispose();
    super.dispose();
  }

  Future<void> _initializeFilters() async {
    try {
      if (_isSystemAdmin) {
        final cooperators = await widget.loadCooperators();
        _cooperators = _withInitialCooperator(cooperators);
      }
      if (_isSystemAdmin || _isCoopAdmin) {
        _customers = _withInitialCustomer(
          await widget.loadCustomers(widget.initialCooperator.id),
        );
      }
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

  Future<void> _changeCooperator(Cooperator? value) async {
    if (value == null || _initializing || _querying) return;
    setState(() {
      _initializing = true;
      _selectedCooperator = value;
      _selectedCustomer = null;
      _clearResults();
    });
    try {
      final customers = await widget.loadCustomers(value.id);
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _selectedCustomer = customers
            .where(
              (customer) =>
                  customer.customerId == widget.initialCustomer.customerId,
            )
            .firstOrNull;
        _selectedCustomer ??= customers.firstOrNull;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  void _clearResults() {
    _previewGeneration += 1;
    _rows = const [];
    _selectedRow = null;
    _beforeWorkbook = null;
    _afterWorkbook = null;
    _loadingPreview = false;
  }

  Future<void> _query() async {
    if (_querying || _initializing) return;
    final customerId = _isSystemAdmin || _isCoopAdmin
        ? _selectedCustomer?.customerId
        : widget.initialCustomer.customerId;
    if (customerId == null) return;
    setState(() {
      _querying = true;
      _clearResults();
    });
    try {
      final rows = await widget.query(
        startDate: DateFormat('yyyyMMdd').format(_startDate),
        endDate: DateFormat('yyyyMMdd').format(_endDate),
        customerId: customerId,
      );
      if (mounted) setState(() => _rows = rows);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _querying = false);
    }
  }

  Future<void> _selectRow(CommonLabelHistory row, int index) async {
    final generation = ++_previewGeneration;
    setState(() {
      _selectedRow = row;
      _beforeWorkbook = null;
      _afterWorkbook = null;
      _loadingPreview = true;
    });
    try {
      final workbooks = await Future.wait([
        widget.loadPreview(
          row.beforePayload,
          width: row.beforeWidth,
          height: row.beforeHeight,
        ),
        widget.loadPreview(
          row.afterPayload,
          width: row.afterWidth,
          height: row.afterHeight,
        ),
      ]);
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _beforeWorkbook = commonLabelHistoryPreviewWorkbook(workbooks[0]);
        _afterWorkbook = commonLabelHistoryPreviewWorkbook(workbooks[1]);
      });
    } finally {
      if (mounted && generation == _previewGeneration) {
        setState(() => _loadingPreview = false);
      }
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
          _buildFilters(),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxTableHeight = math.max(
                  _minimumTableHeight,
                  constraints.maxHeight -
                      _splitterHeight -
                      _minimumPreviewHeight,
                );
                final tableHeight = _tableHeight.clamp(
                  _minimumTableHeight,
                  maxTableHeight,
                );
                return Column(
                  children: [
                    SizedBox(
                      key: const ValueKey('common-label-history-table-pane'),
                      height: tableHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: FortuneTable<CommonLabelHistory>(
                              rows: _rows,
                              columns: _columns,
                              onRowSelected: _selectRow,
                              autoFitColumns: true,
                              fillLastColumn: true,
                              keyboardSelectionShortcutsEnabled: false,
                            ),
                          ),
                          if (_initializing || _querying)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x55FFFFFF),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    HorizontalPaneSplitter(
                      key: const ValueKey('common-label-history-splitter'),
                      height: _splitterHeight,
                      onDragStart: () {
                        _tableHeightAtDragStart = tableHeight;
                      },
                      onDrag: (totalDelta) {
                        setState(() {
                          _tableHeight =
                              (_tableHeightAtDragStart + totalDelta).clamp(
                                _minimumTableHeight,
                                maxTableHeight,
                              );
                        });
                      },
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _HistoryPreviewPane(
                              key: const ValueKey(
                                'common-label-history-before-preview',
                              ),
                              title: '변경 전',
                              workbook: _beforeWorkbook,
                              hintText: _previewHint('변경 전'),
                              identityKey:
                                  'before-${_selectedRow?.logId ?? 0}',
                              zoomController: _beforeZoomController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HistoryPreviewPane(
                              key: const ValueKey(
                                'common-label-history-after-preview',
                              ),
                              title: '변경 후',
                              workbook: _afterWorkbook,
                              hintText: _previewHint('변경 후'),
                              identityKey:
                                  'after-${_selectedRow?.logId ?? 0}',
                              zoomController: _afterZoomController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
              onChanged: _initializing || _querying ? null : _changeCooperator,
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

  String _previewHint(String side) {
    if (_selectedRow == null) return '이력 행을 선택하세요.';
    if (_loadingPreview) return '$side 미리보기를 불러오는 중입니다.';
    return '$side 미리보기를 표시할 수 없습니다.';
  }

  List<FortuneTableColumn<CommonLabelHistory>> get _columns => [
    FortuneTableColumn(
      id: 'modifiedAt',
      header: '수정 시각',
      text: (row) => row.modifiedAt,
      initialWidth: 160,
    ),
    FortuneTableColumn(
      id: 'userId',
      header: '사용자 ID',
      text: (row) => row.userId,
      initialWidth: 110,
    ),
    FortuneTableColumn(
      id: 'brandName',
      header: '브랜드명',
      text: (row) => row.brandName,
      initialWidth: 150,
    ),
    FortuneTableColumn(
      id: 'labelSizeName',
      header: '라벨사이즈',
      text: (row) => row.labelSizeName,
      initialWidth: 140,
    ),
    FortuneTableColumn(
      id: 'beforeWidth',
      header: '변경 전 폭',
      text: (row) => '${row.beforeWidth}',
    ),
    FortuneTableColumn(
      id: 'beforeHeight',
      header: '변경 전 높이',
      text: (row) => '${row.beforeHeight}',
    ),
    FortuneTableColumn(
      id: 'afterWidth',
      header: '변경 후 폭',
      text: (row) => '${row.afterWidth}',
    ),
    FortuneTableColumn(
      id: 'afterHeight',
      header: '변경 후 높이',
      text: (row) => '${row.afterHeight}',
    ),
    FortuneTableColumn(
      id: 'innerIp',
      header: '내부 IP',
      text: (row) => row.innerIp,
      initialWidth: 130,
    ),
    FortuneTableColumn(
      id: 'outerIp',
      header: '외부 IP',
      text: (row) => row.outerIp,
      initialWidth: 130,
    ),
  ];
}

class _HistoryPreviewPane extends StatelessWidget {
  const _HistoryPreviewPane({
    super.key,
    required this.title,
    required this.workbook,
    required this.hintText,
    required this.identityKey,
    required this.zoomController,
  });

  final String title;
  final fs.FortuneWorkbook? workbook;
  final String hintText;
  final String identityKey;
  final LabelSheetZoomController zoomController;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: commonLabelHistoryPreviewBorderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                LabelSheetZoomToolbar(
                  controller: zoomController,
                  backgroundColor: blockingModelessDialogBackgroundColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LabelOutputPreview(
              workbook: workbook,
              hintText: workbook == null ? hintText : null,
              identityKey: identityKey,
              imageObjectIds: const [],
              barcodeObjectIds: const [],
              zoomToolbarPlacement: LabelSheetZoomToolbarPlacement.hidden,
              zoomController: zoomController,
            ),
          ),
        ],
      ),
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
