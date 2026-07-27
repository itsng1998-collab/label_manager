import 'package:flutter/material.dart';
import 'package:label_manager/models/date_manager.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

class DateTypeSetupDialog extends StatefulWidget {
  const DateTypeSetupDialog({
    super.key,
    required this.initialSetup,
    required this.showInvalidValueWarning,
    this.readOnly = false,
  });

  final LabelSizeSetup initialSetup;
  final bool showInvalidValueWarning;
  final bool readOnly;

  @override
  State<DateTypeSetupDialog> createState() => _DateTypeSetupDialogState();
}

class _DateTypeSetupDialogState extends State<DateTypeSetupDialog> {
  late bool _useMakeDate;
  late bool _useMakeTime;
  late bool _useValidDate;
  late bool _useValidTime;
  late PrintDateFormat _makeDateFormat;
  late PrintTimeFormat _makeTimeFormat;
  late PrintDateFormat _validDateFormat;
  late PrintTimeFormat _validTimeFormat;
  late final TextEditingController _makeDateText;
  late final TextEditingController _makeTimeText;
  late final TextEditingController _validDateText;
  late final TextEditingController _validTimeText;

  @override
  void initState() {
    super.initState();
    final setup = widget.initialSetup;
    _useMakeDate = setup.useMakeDate;
    _useMakeTime = setup.useMakeTime;
    _useValidDate = setup.useValidDate;
    _useValidTime = setup.useValidTime;
    _makeDateFormat = setup.makingDateFormat;
    _makeTimeFormat = setup.makingTimeFormat;
    _validDateFormat = setup.validDateFormat;
    _validTimeFormat = setup.validTimeFormat;
    _makeDateText = TextEditingController(text: setup.strMakeDate);
    _makeTimeText = TextEditingController(text: setup.strMakeTime);
    _validDateText = TextEditingController(text: setup.strValidDate);
    _validTimeText = TextEditingController(text: setup.strValidTime);
  }

  @override
  void dispose() {
    _makeDateText.dispose();
    _makeTimeText.dispose();
    _validDateText.dispose();
    _validTimeText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('날짜 타입 설정'),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showInvalidValueWarning)
              const _SetupWarning(
                text: '저장된 날짜/시간 설정 값이 지원 범위를 벗어나 기본값으로 표시됩니다.',
              ),
            _DateSetupRow(
              title: '제조일자',
              readOnly: widget.readOnly,
              enabled: _useMakeDate,
              onEnabled: (value) => setState(() => _useMakeDate = value),
              format: _makeDateFormat,
              customController: _makeDateText,
              onFormat: (value) => setState(() => _makeDateFormat = value),
            ),
            _TimeSetupRow(
              title: '제조시한',
              readOnly: widget.readOnly,
              enabled: _useMakeTime,
              onEnabled: (value) => setState(() => _useMakeTime = value),
              format: _makeTimeFormat,
              customController: _makeTimeText,
              onFormat: (value) => setState(() => _makeTimeFormat = value),
            ),
            _DateSetupRow(
              title: '소비기한',
              readOnly: widget.readOnly,
              enabled: _useValidDate,
              onEnabled: (value) => setState(() => _useValidDate = value),
              format: _validDateFormat,
              customController: _validDateText,
              onFormat: (value) => setState(() => _validDateFormat = value),
            ),
            _TimeSetupRow(
              title: '소비시한',
              readOnly: widget.readOnly,
              enabled: _useValidTime,
              onEnabled: (value) => setState(() => _useValidTime = value),
              format: _validTimeFormat,
              customController: _validTimeText,
              onFormat: (value) => setState(() => _validTimeFormat = value),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '* 소비시한은 별도 만료 시각 계산 없이 원본 시각을 선택 형식으로 표시합니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: widget.readOnly
            ? null
            : () => Navigator.of(context).pop(_result()),
        child: const Text('저장'),
      ),
    ],
  );

  LabelSizeDateSetupUpdate _result() => LabelSizeDateSetupUpdate(
    useMakeDate: _useMakeDate,
    useMakeTime: _useMakeTime,
    useValidDate: _useValidDate,
    useValidTime: _useValidTime,
    makingDateFormat: _makeDateFormat,
    makingTimeFormat: _makeTimeFormat,
    validDateFormat: _validDateFormat,
    validTimeFormat: _validTimeFormat,
    strMakeDate: _makeDateText.text,
    strMakeTime: _makeTimeText.text,
    strValidDate: _validDateText.text,
    strValidTime: _validTimeText.text,
  );
}

class _SetupWarning extends StatelessWidget {
  const _SetupWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(Icons.warning_amber, size: 18, color: Colors.orange.shade800),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _DateSetupRow extends StatefulWidget {
  const _DateSetupRow({
    required this.title,
    required this.readOnly,
    required this.enabled,
    required this.onEnabled,
    required this.format,
    required this.customController,
    required this.onFormat,
  });

  final String title;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final PrintDateFormat format;
  final TextEditingController customController;
  final ValueChanged<PrintDateFormat> onFormat;

  @override
  State<_DateSetupRow> createState() => _DateSetupRowState();
}

class _DateSetupRowState extends State<_DateSetupRow> {
  @override
  void initState() {
    super.initState();
    widget.customController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.customController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => _SetupRow<PrintDateFormat>(
    title: widget.title,
    readOnly: widget.readOnly,
    enabled: widget.enabled,
    onEnabled: widget.onEnabled,
    format: widget.format,
    formats: PrintDateFormat.values,
    formatLabel: _dateFormatLabel,
    customFormat: PrintDateFormat.DATE_FORMAT_USER_DEFINE,
    customController: widget.customController,
    onFormat: widget.onFormat,
    preview: DateManager.datePreview(
      widget.format,
      custom: widget.customController.text,
    ),
  );
}

class _TimeSetupRow extends StatefulWidget {
  const _TimeSetupRow({
    required this.title,
    required this.readOnly,
    required this.enabled,
    required this.onEnabled,
    required this.format,
    required this.customController,
    required this.onFormat,
  });

  final String title;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final PrintTimeFormat format;
  final TextEditingController customController;
  final ValueChanged<PrintTimeFormat> onFormat;

  @override
  State<_TimeSetupRow> createState() => _TimeSetupRowState();
}

class _TimeSetupRowState extends State<_TimeSetupRow> {
  @override
  void initState() {
    super.initState();
    widget.customController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.customController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => _SetupRow<PrintTimeFormat>(
    title: widget.title,
    readOnly: widget.readOnly,
    enabled: widget.enabled,
    onEnabled: widget.onEnabled,
    format: widget.format,
    formats: PrintTimeFormat.values,
    formatLabel: _timeFormatLabel,
    customFormat: PrintTimeFormat.TIME_FORMAT_USER_DEFINE,
    customController: widget.customController,
    onFormat: widget.onFormat,
    preview: DateManager.timePreview(
      widget.format,
      custom: widget.customController.text,
    ),
  );
}

class _SetupRow<T> extends StatelessWidget {
  const _SetupRow({
    required this.title,
    required this.readOnly,
    required this.enabled,
    required this.onEnabled,
    required this.format,
    required this.formats,
    required this.formatLabel,
    required this.customFormat,
    required this.customController,
    required this.onFormat,
    required this.preview,
  });

  final String title;
  final bool readOnly;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final T format;
  final List<T> formats;
  final String Function(T) formatLabel;
  final T customFormat;
  final TextEditingController customController;
  final ValueChanged<T> onFormat;
  final String preview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(title),
            value: enabled,
            onChanged: readOnly ? null : (value) => onEnabled(value ?? false),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 165,
          child: ModelessDropdownFormField<T>(
            initialValue: format,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '형식',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: [
              for (final value in formats)
                DropdownMenuItem(value: value, child: Text(formatLabel(value))),
            ],
            onChanged: enabled && !readOnly
              ? (value) => onFormat(value as T)
              : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: customController,
            enabled: enabled && format == customFormat && !readOnly,
            decoration: const InputDecoration(
              labelText: '사용자 정의',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '미리보기',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            child: Text(enabled ? preview : '원본값'),
          ),
        ),
      ],
    ),
  );
}

String _dateFormatLabel(PrintDateFormat format) => switch (format) {
  PrintDateFormat.DATE_FORMAT_DOT => '2000.01.01',
  PrintDateFormat.DATE_FORMAT_SLASH => '2000/01/01',
  PrintDateFormat.DATE_FORMAT_HANGUL => '2000년01월01일',
  PrintDateFormat.DATE_FORMAT_NONE => '입력 그대로',
  PrintDateFormat.DATE_FORMAT_DOT_MMDD => '01.01',
  PrintDateFormat.DATE_FORMAT_SLASH_MMDD => '01/01',
  PrintDateFormat.DATE_FORMAT_HANGUL_MMDD => '01월01일',
  PrintDateFormat.DATE_FORMAT_USER_DEFINE => '사용자 정의',
};

String _timeFormatLabel(PrintTimeFormat format) => switch (format) {
  PrintTimeFormat.TIME_FORMAT_COLON => '12:01',
  PrintTimeFormat.TIME_FORMAT_HANGUL => '12시01분',
  PrintTimeFormat.TIME_FORMAT_NONE => '입력 그대로',
  PrintTimeFormat.TIME_FORMAT_HANGUL_hh => '12시',
  PrintTimeFormat.TIME_FORMAT_USER_DEFINE => '사용자 정의',
};