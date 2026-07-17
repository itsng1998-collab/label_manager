import 'dart:io';

import 'package:flutter/material.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:printing/printing.dart';

enum LabelPrintSettingsMode { commonLabel, labelPrint }

Future<LabelPrintSettingsSnapshot> loadLabelPrintSettingsSnapshot() async {
  final settings = await LabelPrinterPreferences.loadPreferredPrintSettings();
  if (settings == null) return const LabelPrintSettingsSnapshot.empty();
  double nonNegative(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : 0;
  }

  double signed(String value) {
    final parsed = double.tryParse(value.trim());
    return parsed != null && parsed.isFinite ? parsed : 0;
  }

  final spacing = int.tryParse(settings.autoSpacing.trim());
  return LabelPrintSettingsSnapshot(
    printerName: settings.printerName,
    leftMarginMm: nonNegative(settings.leftMargin),
    rightMarginMm: nonNegative(settings.rightMargin),
    topMarginMm: nonNegative(settings.topMargin),
    leftPushMm: signed(settings.leftPush),
    topPushMm: signed(settings.topPush),
    lineSpacingPercent:
        spacing != null && spacing >= 30 && spacing <= 300 ? spacing : null,
    extraAreaMm: nonNegative(settings.extraArea),
    orientation: settings.orientation == 'vertical'
        ? LabelPrintOrientation.vertical
        : LabelPrintOrientation.horizontal,
  );
}

Future<LabelPrintSettingsSnapshot?> showLabelPrintSettingsDialog({
  required BuildContext context,
  required LabelPrintSettingsSnapshot initial,
  LabelPrintSettingsMode mode = LabelPrintSettingsMode.labelPrint,
}) async {
  final leftMargin = TextEditingController(text: '${initial.leftMarginMm}');
  final rightMargin = TextEditingController(text: '${initial.rightMarginMm}');
  final topMargin = TextEditingController(text: '${initial.topMarginMm}');
  final leftPush = TextEditingController(text: '${initial.leftPushMm}');
  final topPush = TextEditingController(text: '${initial.topPushMm}');
  final lineSpacing = TextEditingController(
    text: initial.lineSpacingPercent == null
        ? '0'
        : '${initial.lineSpacingPercent}',
  );
  final extraArea = TextEditingController(text: '${initial.extraAreaMm}');
  var printerName = initial.printerName ?? '';
  var orientation = initial.orientation;
  String? errorText;

  try {
    return await showGeneralDialog<LabelPrintSettingsSnapshot>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x8A000000),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) => StatefulBuilder(
        builder: (context, setDialogState) => BlockingModelessDialogFrame(
          title: '프린터 설정',
          width: 526,
          height: 348,
          onClose: () => Navigator.of(dialogContext).pop(),
          child: _LabelPrintSettingsDialogContent(
            leftMargin: leftMargin,
            rightMargin: rightMargin,
            topMargin: topMargin,
            leftPush: leftPush,
            topPush: topPush,
            lineSpacing: lineSpacing,
            extraArea: extraArea,
            printerName: printerName,
            orientation: orientation,
            errorText: errorText,
            onOrientationChanged: (value) {
              setDialogState(() => orientation = value);
            },
            onSelectPrinter: () async {
              final selected = Platform.isWindows
                  ? await RawPrinterWin32.showPrinterSetupDialog()
                  : (await Printing.pickPrinter(
                      context: dialogContext,
                      title: '프린터 선택',
                    ))?.name;
              if (selected == null || selected.trim().isEmpty) return;
              setDialogState(() {
                printerName = selected.trim();
                errorText = null;
              });
            },
            onCancel: () => Navigator.of(dialogContext).pop(),
            onApply: printerName.isEmpty
                ? null
                : () {
                    double? nonNegative(TextEditingController controller) {
                      final value = double.tryParse(controller.text.trim());
                      return value != null && value.isFinite && value >= 0
                          ? value
                          : null;
                    }

                    double? signed(TextEditingController controller) {
                      final value = double.tryParse(controller.text.trim());
                      return value != null && value.isFinite ? value : null;
                    }

                    final left = nonNegative(leftMargin);
                    final right = nonNegative(rightMargin);
                    final top = nonNegative(topMargin);
                    final horizontalPush = signed(leftPush);
                    final verticalPush = signed(topPush);
                    final extra = nonNegative(extraArea);
                    final spacing = int.tryParse(lineSpacing.text.trim());
                    if (left == null ||
                        right == null ||
                        top == null ||
                        horizontalPush == null ||
                        verticalPush == null ||
                        extra == null ||
                        spacing == null ||
                        (spacing != 0 && (spacing < 30 || spacing > 300))) {
                      setDialogState(() {
                        errorText = '입력값을 확인해 주세요.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      LabelPrintSettingsSnapshot(
                        printerName: printerName,
                        leftMarginMm: left,
                        rightMarginMm: right,
                        topMarginMm: top,
                        leftPushMm: horizontalPush,
                        topPushMm: verticalPush,
                        lineSpacingPercent: spacing == 0 ? null : spacing,
                        extraAreaMm: extra,
                        orientation: orientation,
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  } finally {
    leftMargin.dispose();
    rightMargin.dispose();
    topMargin.dispose();
    leftPush.dispose();
    topPush.dispose();
    lineSpacing.dispose();
    extraArea.dispose();
  }
}

Future<void> saveLabelPrintSettingsSnapshot(
  LabelPrintSettingsSnapshot settings,
) => LabelPrinterPreferences.savePreferredPrintSettings(
  LabelSheetPreferredPrintSettings(
    printerName: settings.printerName ?? '',
    leftMargin: '${settings.leftMarginMm}',
    rightMargin: '${settings.rightMarginMm}',
    topMargin: '${settings.topMarginMm}',
    leftPush: '${settings.leftPushMm}',
    topPush: '${settings.topPushMm}',
    autoSpacing: settings.lineSpacingPercent == null
        ? 'none'
        : '${settings.lineSpacingPercent}',
    extraArea: '${settings.extraAreaMm}',
    orientation: settings.orientation == LabelPrintOrientation.vertical
        ? 'vertical'
        : 'horizontal',
  ),
);

class _LabelPrintSettingsDialogContent extends StatelessWidget {
  const _LabelPrintSettingsDialogContent({
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.leftPush,
    required this.topPush,
    required this.lineSpacing,
    required this.extraArea,
    required this.printerName,
    required this.orientation,
    required this.errorText,
    required this.onOrientationChanged,
    required this.onSelectPrinter,
    required this.onCancel,
    required this.onApply,
  });

  final TextEditingController leftMargin;
  final TextEditingController rightMargin;
  final TextEditingController topMargin;
  final TextEditingController leftPush;
  final TextEditingController topPush;
  final TextEditingController lineSpacing;
  final TextEditingController extraArea;
  final String printerName;
  final LabelPrintOrientation orientation;
  final String? errorText;
  final ValueChanged<LabelPrintOrientation> onOrientationChanged;
  final VoidCallback onSelectPrinter;
  final VoidCallback onCancel;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('label-print-settings-dialog'),
    padding: const EdgeInsets.fromLTRB(20, 8, 19, 12),
    child: Column(
      children: [
        _PrintSettingsGroup(
          title: '여백',
          child: Row(
            children: [
              _PrintSettingsNumber(label: '왼쪽', controller: leftMargin),
              const SizedBox(width: 12),
              _PrintSettingsNumber(label: '오른쪽', controller: rightMargin),
              const SizedBox(width: 12),
              _PrintSettingsNumber(label: '위쪽', controller: topMargin),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _PrintSettingsGroup(
          title: '출력 조정',
          child: Row(
            children: [
              _PrintSettingsNumber(label: '왼쪽 밀기', controller: leftPush),
              const SizedBox(width: 8),
              _PrintSettingsNumber(label: '위쪽 밀기', controller: topPush),
              const SizedBox(width: 8),
              _PrintSettingsNumber(
                label: '줄간격',
                controller: lineSpacing,
                unit: '%',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('발행 프린터', style: _PrintSettingsStyles.section),
            const SizedBox(width: 12),
            Expanded(child: _PrintSettingsInsetValue(value: printerName)),
            const SizedBox(width: 8),
            SizedBox(
              width: 94,
              height: 30,
              child: _PrintSettingsButton(
                label: '프린터 선택',
                onPressed: onSelectPrinter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _PrintSettingsNumber(label: '추가 영역', controller: extraArea),
            const Spacer(),
            RadioGroup<LabelPrintOrientation>(
              groupValue: orientation,
              onChanged: (value) {
                if (value != null) onOrientationChanged(value);
              },
              child: Row(
                children: [
                  _PrintSettingsRadio(
                    label: '가로',
                    value: LabelPrintOrientation.horizontal,
                    onChanged: onOrientationChanged,
                  ),
                  const SizedBox(width: 16),
                  _PrintSettingsRadio(
                    label: '세로',
                    value: LabelPrintOrientation.vertical,
                    onChanged: onOrientationChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: errorText == null
                ? null
                : Text(
                    errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 84,
              height: 30,
              child: _PrintSettingsButton(
                label: '취소',
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 84,
              height: 30,
              child: _PrintSettingsButton(
                label: '적용',
                onPressed: onApply,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

abstract final class _PrintSettingsStyles {
  static const label = TextStyle(fontSize: 13, color: Color(0xff111111));
  static const section = TextStyle(fontSize: 14, color: Color(0xff111111));
}

class _PrintSettingsGroup extends StatelessWidget {
  const _PrintSettingsGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffd8d8d8)),
            ),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
        Positioned(
          left: 8,
          top: -3,
          child: ColoredBox(
            color: const Color(0xffece6f0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(title, style: _PrintSettingsStyles.label),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PrintSettingsNumber extends StatelessWidget {
  const _PrintSettingsNumber({
    required this.label,
    required this.controller,
    this.unit = 'mm',
  });

  final String label;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: _PrintSettingsStyles.label),
      const SizedBox(width: 6),
      SizedBox(
        width: 52,
        height: 28,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          style: _PrintSettingsStyles.label,
          decoration: const InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.fromLTRB(5, 2, 5, 3),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xffc7c7c7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xff0067c0), width: 1.2),
            ),
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text(unit, style: _PrintSettingsStyles.label),
    ],
  );
}

class _PrintSettingsInsetValue extends StatelessWidget {
  const _PrintSettingsInsetValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffd4d4d4)),
      borderRadius: BorderRadius.circular(2),
      boxShadow: const [
        BoxShadow(color: Color(0x12000000), offset: Offset(0, 1)),
      ],
    ),
    child: Text(
      value.isEmpty ? '선택된 프린터 없음' : value,
      overflow: TextOverflow.ellipsis,
      style: _PrintSettingsStyles.label,
    ),
  );
}

class _PrintSettingsButton extends StatelessWidget {
  const _PrintSettingsButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xff111111),
      disabledForegroundColor: const Color(0xff8a8a8a),
      side: const BorderSide(color: Color(0xffc7c7c7)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      padding: EdgeInsets.zero,
      textStyle: _PrintSettingsStyles.label,
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

class _PrintSettingsRadio extends StatelessWidget {
  const _PrintSettingsRadio({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final LabelPrintOrientation value;
  final ValueChanged<LabelPrintOrientation> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(value),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<LabelPrintOrientation>(
          value: value,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: _PrintSettingsStyles.label),
      ],
    ),
  );
}