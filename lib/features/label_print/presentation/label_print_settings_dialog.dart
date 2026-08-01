import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:label_manager/features/label_print/application/label_print_settings.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/printing/printer_profiles.dart';
import 'package:label_manager/printing/raw_printer_win32.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/label_print_dialog_close_icon.dart';
import 'package:label_manager/widgets/label_print_settings_panel.dart';
import 'package:printing/printing.dart';

Future<LabelPrintSettingsSnapshot?> showLabelPrintSettingsDialog({
  required BuildContext context,
  required LabelPrintSettingsSnapshot initial,
  bool showPdfSingleFileOption = true,
}) async {
  final leftMargin = TextEditingController(text: '${initial.leftMarginMm}');
  final rightMargin = TextEditingController(text: '${initial.rightMarginMm}');
  final topMargin = TextEditingController(text: '${initial.topMarginMm}');
  final leftPush = TextEditingController(text: '${initial.leftPushMm}');
  final topPush = TextEditingController(text: '${initial.topPushMm}');
  final lineSpacing = TextEditingController(
    text: initial.lineSpacingPercent == null
        ? '0'
        : '${normalizeLegacyLabelPrintSpacingPercent(initial.lineSpacingPercent)}',
  );
  final extraArea = TextEditingController(text: '${initial.extraAreaMm}');
  var printerName = initial.printerName ?? '';
  var orientation = initial.orientation == LabelPrintOrientation.vertical
      ? 'vertical'
      : 'horizontal';
  var pdfSingleFile = initial.pdfSingleFile;
  var isPdfPrinter = showPdfSingleFileOption &&
      detectPrinterProfile(
            Printer(url: printerName, name: printerName),
          ).language ==
          PrinterLanguage.rasterOnly;
  var initialBackendResolveStarted = false;
  String? errorText;

  try {
    return await showGeneralDialog<LabelPrintSettingsSnapshot>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x8A000000),
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, _, _) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (showPdfSingleFileOption && !initialBackendResolveStarted) {
            initialBackendResolveStarted = true;
            unawaited(() async {
              final resolved = await _isPdfPrinterName(printerName);
              if (!context.mounted || resolved == isPdfPrinter) return;
              setDialogState(() {
                isPdfPrinter = resolved;
              });
            }());
          }
          return BlockingModelessDialogFrame(
          title: '프린터 설정',
          width: 526,
          height: 390,
          closeIcon: const LabelPrintDialogCloseIcon(),
          onClose: () => Navigator.of(dialogContext).pop(),
          child: LabelPrintSettingsPanel(
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
            showPdfSingleFileOption:
                showPdfSingleFileOption && isPdfPrinter,
            pdfSingleFile: pdfSingleFile,
            onPdfSingleFileChanged: (value) {
              if (value == null) return;
              setDialogState(() {
                pdfSingleFile = value;
                errorText = null;
              });
            },
            autoSpacingItems: LabelPrintSettingsPanel.buildAutoSpacingItems(
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
              final normalizedName = selected.trim();
              final selectedIsPdf = showPdfSingleFileOption
                  ? await _isPdfPrinterName(normalizedName)
                  : false;
              if (!context.mounted) return;
              setDialogState(() {
                printerName = normalizedName;
                isPdfPrinter = selectedIsPdf;
                errorText = null;
              });
            },
            onClose: () => Navigator.of(dialogContext).pop(),
            errorText: errorText,
            onApply: printerName.isEmpty
                ? null
                : () {
                    final settings = parseLabelPrintSettingsSnapshot(
                      printerName: printerName,
                      leftMargin: leftMargin.text,
                      rightMargin: rightMargin.text,
                      topMargin: topMargin.text,
                      leftPush: leftPush.text,
                      topPush: topPush.text,
                      lineSpacing: lineSpacing.text,
                      extraArea: extraArea.text,
                      orientation: orientation,
                      pdfSingleFile: pdfSingleFile,
                    );
                    if (settings == null) {
                      setDialogState(() {
                        errorText = '입력값을 확인해 주세요.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(settings);
                  },
            ),
          );
        },
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

Future<bool> _isPdfPrinterName(String printerName) async {
  final normalizedName = printerName.trim();
  if (normalizedName.isEmpty) return false;
  Printer? printer;
  try {
    final printers = await Printing.listPrinters();
    for (final candidate in printers) {
      if (candidate.name.trim().toLowerCase() ==
          normalizedName.toLowerCase()) {
        printer = candidate;
        break;
      }
    }
  } catch (_) {
    // The selected name still provides enough information for raster printers.
  }
  printer ??= Printer(url: normalizedName, name: normalizedName);
  final profile = detectPrinterProfile(printer);
  final portName = Platform.isWindows
      ? await RawPrinterWin32.queryPrinterPortName(printer)
      : null;
  return resolveLabelPrintBackend(
        language: profile.language,
        portName: portName,
      ) ==
      LabelPrintBackend.pdf;
}