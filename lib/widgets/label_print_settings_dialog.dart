import 'dart:io';

import 'package:flutter/material.dart';
import 'package:label_manager/models/label_print.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/printing/label_printer_preferences.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:printing/printing.dart';

enum LabelPrintSettingsMode { commonLabel, labelPrint }

int? _legacyAutoSpacingPercent(int? value) {
  if (value == null) return null;
  return value >= 80 && value <= 300 && (value - 80) % 5 == 0 ? value : 100;
}

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

  final autoSpacing = settings.autoSpacing.trim();
  final spacing = autoSpacing == 'none' || autoSpacing == '0'
      ? null
      : _legacyAutoSpacingPercent(int.tryParse(autoSpacing)) ?? 100;
  return LabelPrintSettingsSnapshot(
    printerName: settings.printerName,
    leftMarginMm: nonNegative(settings.leftMargin),
    rightMarginMm: nonNegative(settings.rightMargin),
    topMarginMm: nonNegative(settings.topMargin),
    leftPushMm: signed(settings.leftPush),
    topPushMm: signed(settings.topPush),
    lineSpacingPercent: spacing,
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
        : '${_legacyAutoSpacingPercent(initial.lineSpacingPercent)}',
  );
  final extraArea = TextEditingController(text: '${initial.extraAreaMm}');
  var printerName = initial.printerName ?? '';
  var orientation = initial.orientation == LabelPrintOrientation.vertical
      ? 'vertical'
      : 'horizontal';
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
          height: 390,
          closeIcon: const LabelSheetPrintDialogCloseIcon(),
          onClose: () => Navigator.of(dialogContext).pop(),
          child: LabelSheetPrintSettingsDialog(
            leftMarginController: leftMargin,
            rightMarginController: rightMargin,
            topMarginController: topMargin,
            leftPushController: leftPush,
            topPushController: topPush,
            extraAreaController: extraArea,
            autoSpacing: lineSpacing.text == '0'
                ? 'none'
                : lineSpacing.text,
            orientation: orientation,
            selectedPrinterName: printerName,
            autoSpacingItems:
                LabelSheetPrintSettingsDialog.buildAutoSpacingItems(
                  minimum: 80,
                  step: 5,
                  includePercent: true,
                ),
            onAutoSpacingChanged: (value) {
              if (value == null) return;
              setDialogState(() {
                lineSpacing.text = value == 'none' ? '0' : value;
                errorText = null;
              });
            },
            onOrientationChanged: (value) {
              if (value == null) return;
              setDialogState(() {
                orientation = value;
                errorText = null;
              });
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
            onClose: () => Navigator.of(dialogContext).pop(),
            errorText: errorText,
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
                        (spacing != 0 &&
                          (spacing < 80 ||
                            spacing > 300 ||
                            (spacing - 80) % 5 != 0))) {
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
                        orientation: orientation == 'vertical'
                          ? LabelPrintOrientation.vertical
                          : LabelPrintOrientation.horizontal,
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
