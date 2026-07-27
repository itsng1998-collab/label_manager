import 'package:flutter/material.dart';
import 'package:label_manager/core/lifecycle.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/admin_copy.dart';
import 'package:label_manager/models/brand.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

typedef AdminCopyCooperatorLoader = Future<List<Cooperator>> Function();
typedef AdminCopyCustomerLoader = Future<List<Customer>> Function(String);
typedef AdminCopyBrandLoader = Future<List<Brand>?> Function(int);
typedef AdminCopyLabelSizeLoader = Future<List<LabelSize>?> Function(int);
typedef AdminCopyMarketLoader = Future<List<Market>> Function(int);
typedef AdminLabelSizeCopier = Future<void> Function(
  AdminLabelSizeCopyCommand,
);
typedef AdminBrandCopier = Future<void> Function(AdminBrandCopyCommand);

class AdminCopyController extends ChangeNotifier {
  bool _writeBusy = false;
  bool _disposed = false;

  bool get writeBusy => _writeBusy;

  LifecycleExitSnapshot snapshot() => LifecycleExitSnapshot(
    blockingReason: _writeBusy ? '관리자 복사가 끝난 뒤 다시 시도해주세요.' : null,
  );

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

class AdminCopyDialogContent extends StatefulWidget {
  const AdminCopyDialogContent({
    super.key,
    required this.controller,
    required this.initialCooperator,
    required this.cooperatorSelectionEnabled,
    required this.onCommitted,
    required this.onCommitOutcomeUnknown,
    this.loadCooperators = CooperatorDAO.selectAll,
    this.loadCustomers = CustomerDAO.selectByCooperatorId,
    this.loadBrands = BrandDAO.selectByCustomerIdByBrandOrder,
    this.loadLabelSizes = LabelSizeDAO.selectByBrandIdByLabelSizeOrder,
    this.loadMarkets = MarketDAO.selectForAdminConnect,
    this.targetHasColumns = AdminCopyDAO.targetHasColumns,
    this.copyLabelSize = AdminCopyDAO.copyLabelSize,
    this.copyBrand = AdminCopyDAO.copyBrand,
  });

  final AdminCopyController controller;
  final Cooperator initialCooperator;
  final bool cooperatorSelectionEnabled;
  final Future<void> Function() onCommitted;
  final VoidCallback onCommitOutcomeUnknown;
  final AdminCopyCooperatorLoader loadCooperators;
  final AdminCopyCustomerLoader loadCustomers;
  final AdminCopyBrandLoader loadBrands;
  final AdminCopyLabelSizeLoader loadLabelSizes;
  final AdminCopyMarketLoader loadMarkets;
  final Future<bool> Function(int) targetHasColumns;
  final AdminLabelSizeCopier copyLabelSize;
  final AdminBrandCopier copyBrand;

  @override
  State<AdminCopyDialogContent> createState() =>
      _AdminCopyDialogContentState();
}

class _AdminCopyDialogContentState extends State<AdminCopyDialogContent> {
  List<Cooperator> _cooperators = const [];
  List<Customer> _customers = const [];
  List<Brand> _sourceBrands = const [];
  List<Brand> _targetBrands = const [];
  List<LabelSize> _sourceLabelSizes = const [];
  List<LabelSize> _targetLabelSizes = const [];
  late String _cooperatorId;
  int? _sourceCustomerId;
  int? _sourceBrandId;
  int? _sourceLabelSizeId;
  int? _targetCustomerId;
  int? _targetBrandId;
  int? _targetLabelSizeId;
  bool _copyWholeBrand = false;
  bool _copyItems = false;
  bool _sourceLabelSizeEnabled = false;
  bool _targetCustomerEnabled = false;
  bool _targetBrandEnabled = false;
  bool _targetLabelSizeEnabled = false;
  bool _copyEnabled = false;
  bool _loading = true;

  bool get _busy => _loading || widget.controller.writeBusy;

  @override
  void initState() {
    super.initState();
    _cooperatorId = widget.initialCooperator.id;
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final values = await Future.wait([
        widget.loadCooperators(),
        widget.loadCustomers(_cooperatorId),
      ]);
      if (!mounted) return;
      final cooperators = values[0] as List<Cooperator>;
      setState(() {
        _cooperators = [
          widget.initialCooperator,
          ...cooperators.where((value) => value.id != _cooperatorId),
        ];
        _customers = values[1] as List<Customer>;
      });
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearSelectionsAfterCooperator() {
    _sourceCustomerId = null;
    _sourceBrandId = null;
    _sourceLabelSizeId = null;
    _targetCustomerId = null;
    _targetBrandId = null;
    _targetLabelSizeId = null;
    _sourceBrands = const [];
    _sourceLabelSizes = const [];
    _targetBrands = const [];
    _targetLabelSizes = const [];
    _sourceLabelSizeEnabled = false;
    _targetCustomerEnabled = false;
    _targetBrandEnabled = false;
    _targetLabelSizeEnabled = false;
    _copyEnabled = false;
  }

  Future<void> _changeCooperator(String? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _cooperatorId = value;
      _customers = const [];
      _clearSelectionsAfterCooperator();
    });
    try {
      final customers = await widget.loadCustomers(value);
      if (mounted) setState(() => _customers = customers);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeSourceCustomer(int? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _sourceCustomerId = value;
      _sourceBrandId = null;
      _sourceLabelSizeId = null;
      _sourceBrands = const [];
      _sourceLabelSizes = const [];
      _sourceLabelSizeEnabled = false;
      _targetCustomerEnabled = false;
      _copyEnabled = false;
    });
    try {
      final brands = await widget.loadBrands(value);
      if (mounted) setState(() => _sourceBrands = brands ?? const []);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeSourceBrand(int? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _sourceBrandId = value;
      _sourceLabelSizeId = null;
      _sourceLabelSizes = const [];
      _sourceLabelSizeEnabled = !_copyWholeBrand;
      _targetCustomerEnabled = _copyWholeBrand;
      _copyEnabled = false;
    });
    try {
      if (!_copyWholeBrand) {
        final sizes = await widget.loadLabelSizes(value);
        if (mounted) setState(() => _sourceLabelSizes = sizes ?? const []);
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeSourceLabelSize(int? value) {
    if (value == null || _busy) return;
    setState(() {
      _sourceLabelSizeId = value;
      _targetCustomerEnabled = true;
      _copyEnabled = false;
    });
  }

  Future<void> _changeTargetCustomer(int? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _targetCustomerId = value;
      _targetBrandId = null;
      _targetLabelSizeId = null;
      _targetBrands = const [];
      _targetLabelSizes = const [];
      _targetBrandEnabled = !_copyWholeBrand;
      _targetLabelSizeEnabled = false;
      _copyEnabled = _copyWholeBrand;
    });
    try {
      if (!_copyWholeBrand) {
        final brands = await widget.loadBrands(value);
        if (mounted) setState(() => _targetBrands = brands ?? const []);
      }
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeTargetBrand(int? value) async {
    if (value == null || _busy) return;
    setState(() {
      _loading = true;
      _targetBrandId = value;
      _targetLabelSizeId = null;
      _targetLabelSizes = const [];
      _targetLabelSizeEnabled = true;
      _copyEnabled = false;
    });
    try {
      final sizes = await widget.loadLabelSizes(value);
      if (mounted) setState(() => _targetLabelSizes = sizes ?? const []);
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeTargetLabelSize(int? value) {
    if (value == null || _busy) return;
    setState(() {
      _targetLabelSizeId = value;
      _copyEnabled = true;
    });
  }

  Future<void> _copy() async {
    if (_busy || !_copyEnabled || _targetCustomerId == null) return;
    widget.controller.setWriteBusy(true);
    if (mounted) setState(() {});
    try {
      int? targetFirstMarketId;
      if (_copyItems) {
        final markets = await widget.loadMarkets(_targetCustomerId!);
        if (markets.isEmpty) {
          throw StateError('품목을 복사할 대상 거래처에 지점이 없습니다.');
        }
        targetFirstMarketId = markets.first.marketId;
      }
      if (_copyWholeBrand) {
        final sourceBrand = _sourceBrands.firstWhere(
          (value) => value.brandId == _sourceBrandId,
        );
        await widget.copyBrand(
          AdminBrandCopyCommand(
            sourceBrandId: sourceBrand.brandId,
            targetCustomerId: _targetCustomerId!,
            sourceBrandName: sourceBrand.brandName,
            copyItems: _copyItems,
            targetFirstMarketId: targetFirstMarketId,
          ),
        );
      } else {
        final targetLabelSizeId = _targetLabelSizeId!;
        final hasColumns = await widget.targetHasColumns(targetLabelSizeId);
        if (hasColumns) {
          final confirmed = await _confirmOverwrite();
          if (confirmed != true || !mounted) return;
        }
        await widget.copyLabelSize(
          AdminLabelSizeCopyCommand(
            sourceLabelSizeId: _sourceLabelSizeId!,
            targetLabelSizeId: targetLabelSizeId,
            overwriteExisting: hasColumns,
            copyItems: _copyItems,
            targetFirstMarketId: targetFirstMarketId,
          ),
        );
      }
      await widget.onCommitted();
    } on DbCommitOutcomeUnknown catch (error) {
      if (mounted) await _showMessage(error.toString());
      widget.onCommitOutcomeUnknown();
    } catch (error) {
      if (mounted) await _showMessage(error.toString());
    } finally {
      widget.controller.setWriteBusy(false);
      if (mounted) setState(() {});
    }
  }

  Future<bool?> _confirmOverwrite() =>
      showBlockingModelessOverlayDialog<bool>(
        context: context,
        builder: (_, close) => AlertDialog(
      title: const Text('관리자 복사'),
      content: const Text('대상 라벨의 기존 데이터가 삭제됩니다.\n계속하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => close(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => close(true),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  Future<void> _showMessage(String message) =>
      showBlockingModelessOverlayDialog<void>(
        context: context,
        builder: (_, close) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => close(null),
          child: const Text('확인'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _labeledSelector(
          label: '협력업체',
          child: _selector<String>(
            key: 'adminCopyCooperator',
            value: _cooperatorId,
            enabled: widget.cooperatorSelectionEnabled,
            items: [
              for (final value in _cooperators)
                DropdownMenuItem(value: value.id, child: Text(value.name)),
            ],
            onChanged: _changeCooperator,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _copyScopePanel(source: true),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _copyScopePanel(source: false),
            ),
          ],
        ),
        const Divider(height: 24),
        Row(
          children: [
            _copyOption(
              key: 'adminCopyWholeBrand',
              label: '브랜드 복사',
              value: _copyWholeBrand,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _copyWholeBrand = value),
            ),
            const SizedBox(width: 32),
            _copyOption(
              key: 'adminCopyItems',
              label: '품목까지 복사',
              value: _copyItems,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _copyItems = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('adminCopyExecute'),
            onPressed: _copyEnabled && !_busy ? _copy : null,
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(widget.controller.writeBusy ? '복사 중' : '복사'),
          ),
        ),
      ],
    ),
  );

  Widget _copyScopePanel({required bool source}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        source ? '원본' : '대상',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      _labeledSelector(
        label: '거래처',
        child: _customerSelector(source),
      ),
      const SizedBox(height: 8),
      _labeledSelector(label: '브랜드', child: _brandSelector(source)),
      const SizedBox(height: 8),
      _labeledSelector(
        label: '라벨 크기',
        child: _labelSizeSelector(source),
      ),
    ],
  );

  Widget _labeledSelector({required String label, required Widget child}) => Row(
    children: [
      SizedBox(width: 72, child: Text(label)),
      Expanded(child: child),
    ],
  );

  Widget _copyOption({
    required String key,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(
        key: ValueKey(key),
        value: value,
        onChanged: onChanged == null
            ? null
            : (nextValue) => onChanged(nextValue == true),
      ),
      Text(label),
    ],
  );

  Widget _customerSelector(bool source) => _selector<int>(
    key: source ? 'adminCopySourceCustomer' : 'adminCopyTargetCustomer',
    value: source ? _sourceCustomerId : _targetCustomerId,
    enabled: source || _targetCustomerEnabled,
    items: [
      for (final value in _customers)
        DropdownMenuItem(
          value: value.customerId,
          child: Text(value.customerName),
        ),
    ],
    onChanged: source ? _changeSourceCustomer : _changeTargetCustomer,
  );

  Widget _brandSelector(bool source) {
    final values = source ? _sourceBrands : _targetBrands;
    return _selector<int>(
      key: source ? 'adminCopySourceBrand' : 'adminCopyTargetBrand',
      value: source ? _sourceBrandId : _targetBrandId,
      enabled: source ? _sourceCustomerId != null : _targetBrandEnabled,
      items: [
        for (final value in values)
          DropdownMenuItem(
            value: value.brandId,
            child: Text(value.brandName),
          ),
      ],
      onChanged: source ? _changeSourceBrand : _changeTargetBrand,
    );
  }

  Widget _labelSizeSelector(bool source) {
    final values = source ? _sourceLabelSizes : _targetLabelSizes;
    return _selector<int>(
      key: source ? 'adminCopySourceLabelSize' : 'adminCopyTargetLabelSize',
      value: source ? _sourceLabelSizeId : _targetLabelSizeId,
      enabled: source ? _sourceLabelSizeEnabled : _targetLabelSizeEnabled,
      items: [
        for (final value in values)
          DropdownMenuItem(
            value: value.labelSizeId,
            child: Text(value.labelSizeName),
          ),
      ],
      onChanged: source
          ? (value) => _changeSourceLabelSize(value)
          : (value) => _changeTargetLabelSize(value),
    );
  }

  Widget _selector<T>({
    required String key,
    required T? value,
    required bool enabled,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) => ModelessDropdownFormField<T>(
    key: ValueKey(key),
    initialValue: items.any((item) => item.value == value) ? value : null,
    items: items,
    onChanged: enabled && !_busy ? onChanged : null,
  );
}