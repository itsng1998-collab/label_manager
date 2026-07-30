import 'package:flutter/material.dart';
import 'package:label_manager/features/item/application/item_manager_xlsx.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';

Future<ItemManagerImportTransforms?> showItemManagerImportTransformDialog(
  BuildContext context, {
  required ItemManagerXlsxImportResult result,
  required List<ItemManagerXlsxColumn> columns,
}) => showDialog<ItemManagerImportTransforms>(
  context: context,
  barrierDismissible: false,
  builder: (context) => ItemManagerImportTransformDialog(
    result: result,
    columns: columns,
  ),
);

class ItemManagerImportTransformDialog extends StatefulWidget {
  const ItemManagerImportTransformDialog({
    super.key,
    required this.result,
    required this.columns,
  });

  final ItemManagerXlsxImportResult result;
  final List<ItemManagerXlsxColumn> columns;

  @override
  State<ItemManagerImportTransformDialog> createState() =>
      _ItemManagerImportTransformDialogState();
}

class _ItemManagerImportTransformDialogState
    extends State<ItemManagerImportTransformDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<_TransformTarget> _targets;
  final Map<String, _TransformDraft> _drafts = {};

  @override
  void initState() {
    super.initState();
    _targets = [
      _TransformTarget(
        key: 'item',
        label: '품목',
        sample: widget.result.rows
            .map((row) => row.itemName)
            .firstWhere((value) => value.isNotEmpty, orElse: () => ''),
      ),
      for (final column in widget.columns)
        if (column.typeCode != TColumnType.TYPE_IMAGE &&
            widget.result.rows.any(
              (row) => row.columnDrafts.containsKey(column.columnId),
            ))
          _TransformTarget(
            key: 'column:${column.columnId}',
            label: column.name,
            sample: widget.result.rows
              .map(
                (row) =>
                  row.columnDrafts[column.columnId]?.dataString ?? '',
              )
              .firstWhere((value) => value.isNotEmpty, orElse: () => ''),
            columnId: column.columnId,
          ),
    ];
    for (final target in _targets) {
      _drafts[target.key] = _TransformDraft();
    }
  }

  void _apply() {
    if (_formKey.currentState?.validate() != true) return;
    ItemManagerImportTransform? itemName;
    final columns = <int, ItemManagerImportTransform>{};
    for (final target in _targets) {
      final transform = _drafts[target.key]!.toTransform();
      if (transform == null) continue;
      if (target.columnId == null) {
        itemName = transform;
      } else {
        columns[target.columnId!] = transform;
      }
    }
    Navigator.of(context).pop(
      ItemManagerImportTransforms(
        itemName: itemName,
        columns: Map.unmodifiable(columns),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Excel 가져오기 연산 설정'),
    content: SizedBox(
      width: 760,
      height: 440,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('가져온 값을 품목관리에 적용하기 전에 컬럼별 연산을 설정합니다.'),
            const SizedBox(height: 12),
            const _TransformHeader(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: _targets.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final target = _targets[index];
                  return _TransformRow(
                    target: target,
                    draft: _drafts[target.key]!,
                    onOperationChanged: (operation) {
                      setState(
                        () => _drafts[target.key]!.operation = operation,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        key: const Key('item-import-transform-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        key: const Key('item-import-transform-apply'),
        onPressed: _apply,
        child: const Text('가져오기'),
      ),
    ],
  );
}

class _TransformHeader extends StatelessWidget {
  const _TransformHeader();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 32,
    child: Row(
      children: [
        SizedBox(width: 120, child: Text('대상 컬럼')),
        SizedBox(width: 150, child: Text('Excel 샘플값')),
        SizedBox(width: 190, child: Text('연산')),
        Expanded(child: Text('설정값')),
      ],
    ),
  );
}

class _TransformRow extends StatelessWidget {
  const _TransformRow({
    required this.target,
    required this.draft,
    required this.onOperationChanged,
  });

  final _TransformTarget target;
  final _TransformDraft draft;
  final ValueChanged<ItemManagerImportTransformOperation> onOperationChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(target.label, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: 150,
          child: Text(target.sample, overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<ItemManagerImportTransformOperation>(
            key: ValueKey('item-import-operation:${target.key}'),
            initialValue: draft.operation,
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            items: [
              for (final operation in ItemManagerImportTransformOperation.values)
                DropdownMenuItem(
                  value: operation,
                  child: Text(_operationLabel(operation)),
                ),
            ],
            onChanged: (operation) {
              if (operation != null) onOperationChanged(operation);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildSettings()),
      ],
    ),
  );

  Widget _buildSettings() {
    if (draft.operation == ItemManagerImportTransformOperation.none) {
      return const SizedBox.shrink();
    }
    final numeric = _isNumericOperation(draft.operation);
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('item-import-value:${target.key}'),
            initialValue: draft.value,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : TextInputType.text,
            decoration: InputDecoration(
              isDense: true,
              labelText: numeric ? '연산값' : '추가 텍스트',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => draft.value = value,
            validator: (value) {
              if (value == null || value.isEmpty) return '설정값을 입력하세요.';
              if (numeric &&
                  double.tryParse(value.trim().replaceAll(',', '')) == null) {
                return '숫자를 입력하세요.';
              }
              if (draft.operation ==
                      ItemManagerImportTransformOperation.divide &&
                  double.tryParse(value.trim().replaceAll(',', '')) == 0) {
                return '0으로 나눌 수 없습니다.';
              }
              return null;
            },
          ),
        ),
        if (draft.operation == ItemManagerImportTransformOperation.divide) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 78,
            child: TextFormField(
              key: ValueKey('item-import-decimals:${target.key}'),
              initialValue: '${draft.decimalPlaces}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                labelText: '소수 자리',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => draft.decimalPlaces = int.tryParse(value),
              validator: (_) {
                final value = draft.decimalPlaces;
                if (value == null || value < 0 || value > 12) return '0~12';
                return null;
              },
            ),
          ),
        ],
        if (draft.operation ==
          ItemManagerImportTransformOperation.replaceAfter) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 78,
            child: TextFormField(
              key: ValueKey('item-import-position:${target.key}'),
              initialValue: '${draft.position}',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                labelText: '왼쪽 자리',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => draft.position = int.tryParse(value),
              validator: (_) {
                final value = draft.position;
                if (value == null || value < 0) return '0 이상';
                return null;
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _TransformTarget {
  const _TransformTarget({
    required this.key,
    required this.label,
    required this.sample,
    this.columnId,
  });

  final String key;
  final String label;
  final String sample;
  final int? columnId;
}

class _TransformDraft {
  ItemManagerImportTransformOperation operation =
      ItemManagerImportTransformOperation.none;
  String value = '';
  int? decimalPlaces = 2;
  int? position = 1;

  ItemManagerImportTransform? toTransform() {
    if (operation == ItemManagerImportTransformOperation.none) return null;
    return ItemManagerImportTransform(
      operation: operation,
      value: value,
      decimalPlaces: decimalPlaces ?? 2,
      position: position ?? 1,
    );
  }
}

bool _isNumericOperation(ItemManagerImportTransformOperation operation) =>
    switch (operation) {
      ItemManagerImportTransformOperation.add ||
      ItemManagerImportTransformOperation.subtract ||
      ItemManagerImportTransformOperation.multiply ||
      ItemManagerImportTransformOperation.divide => true,
      _ => false,
    };

String _operationLabel(ItemManagerImportTransformOperation operation) =>
    switch (operation) {
      ItemManagerImportTransformOperation.none => '적용 안 함',
      ItemManagerImportTransformOperation.add => '+ 더하기',
      ItemManagerImportTransformOperation.subtract => '- 빼기',
      ItemManagerImportTransformOperation.multiply => '× 곱하기',
      ItemManagerImportTransformOperation.divide => '÷ 나누기',
      ItemManagerImportTransformOperation.append => 'Right (뒤에 추가)',
      ItemManagerImportTransformOperation.prepend => 'Left (앞에 추가)',
      ItemManagerImportTransformOperation.replaceAfter =>
        'Mid (왼쪽 N자 이후 대체)',
    };