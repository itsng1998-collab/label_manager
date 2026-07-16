import 'dart:io';

import 'package:flutter/material.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
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
    return await showDialog<LabelPrintSettingsSnapshot>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('프린터 설정'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          printerName.isEmpty ? '선택된 프린터 없음' : printerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('프린터 선택'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _NumberSetting(label: '왼쪽 여백', controller: leftMargin),
                      _NumberSetting(label: '오른쪽 여백', controller: rightMargin),
                      _NumberSetting(label: '위쪽 여백', controller: topMargin),
                      _NumberSetting(label: '왼쪽 밀기', controller: leftPush),
                      _NumberSetting(label: '위쪽 밀기', controller: topPush),
                      _NumberSetting(
                        label: '줄간격(0 또는 30~300)',
                        controller: lineSpacing,
                        suffixText: '%',
                      ),
                      _NumberSetting(label: '추가 영역', controller: extraArea),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<LabelPrintOrientation>(
                    segments: const [
                      ButtonSegment(
                        value: LabelPrintOrientation.horizontal,
                        label: Text('가로'),
                      ),
                      ButtonSegment(
                        value: LabelPrintOrientation.vertical,
                        label: Text('세로'),
                      ),
                    ],
                    selected: {orientation},
                    onSelectionChanged: (value) {
                      setDialogState(() => orientation = value.single);
                    },
                  ),
                  if (mode == LabelPrintSettingsMode.commonLabel)
                    const SizedBox(height: 1),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: printerName.isEmpty
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
              child: const Text('적용'),
            ),
          ],
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

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.label,
    required this.controller,
    this.suffixText = 'mm',
  });

  final String label;
  final TextEditingController controller;
  final String suffixText;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 165,
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(labelText: label, suffixText: suffixText),
    ),
  );
}