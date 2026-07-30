import 'package:flutter/material.dart';

class SettingsNameEditResult {
  const SettingsNameEditResult({required this.name, this.useScale = false});

  final String name;
  final bool useScale;
}

class SettingsCrudToolbar extends StatelessWidget {
  const SettingsCrudToolbar({
    super.key,
    required this.addTooltip,
    required this.editTooltip,
    required this.deleteTooltip,
    required this.enabled,
    required this.hasSelection,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String addTooltip;
  final String editTooltip;
  final String deleteTooltip;
  final bool enabled;
  final bool hasSelection;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: addTooltip,
          icon: const Icon(Icons.add),
          onPressed: enabled ? onAdd : null,
        ),
        IconButton(
          tooltip: editTooltip,
          icon: const Icon(Icons.edit),
          onPressed: enabled && hasSelection ? onEdit : null,
        ),
        IconButton(
          tooltip: deleteTooltip,
          icon: const Icon(Icons.delete),
          onPressed: enabled && hasSelection ? onDelete : null,
        ),
      ],
    );
  }
}

class SettingsNameEditDialog extends StatefulWidget {
  const SettingsNameEditDialog({
    super.key,
    required this.title,
    required this.initialName,
    required this.onCancel,
    required this.onSubmit,
    this.showUseScale = false,
    this.initialUseScale = false,
  });

  final String title;
  final String initialName;
  final bool showUseScale;
  final bool initialUseScale;
  final VoidCallback onCancel;
  final ValueChanged<SettingsNameEditResult> onSubmit;

  @override
  State<SettingsNameEditDialog> createState() => _SettingsNameEditDialogState();
}

class _SettingsNameEditDialogState extends State<SettingsNameEditDialog> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late bool _useScale;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName)
      ..addListener(_handleNameChanged);
    _nameFocusNode = FocusNode();
    _useScale = widget.initialUseScale;
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_handleNameChanged)
      ..dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _handleNameChanged() => setState(() {});

  void _submit() {
    if (!_canSubmit) return;
    widget.onSubmit(
      SettingsNameEditResult(
        name: _nameController.text.trim(),
        useScale: _useScale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('settings-name-edit-field'),
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: '이름'),
            ),
            if (widget.showUseScale) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const ValueKey('settings-name-use-scale'),
                value: _useScale,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('전자저울 사용'),
                onChanged: (value) =>
                    setState(() => _useScale = value ?? false),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('취소')),
        FilledButton(
          key: const ValueKey('settings-name-submit'),
          onPressed: _canSubmit ? _submit : null,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
