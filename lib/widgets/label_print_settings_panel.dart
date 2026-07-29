import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class LabelPrintSettingsPanel extends StatelessWidget {
  const LabelPrintSettingsPanel({
    super.key,
    required this.leftMarginController,
    required this.topMarginController,
    required this.extraAreaController,
    required this.autoSpacing,
    required this.orientation,
    required this.selectedPrinterName,
    required this.onAutoSpacingChanged,
    required this.onOrientationChanged,
    required this.onSelectPrinter,
    required this.onApply,
    required this.onClose,
    this.copiesController,
    this.rightMarginController,
    this.leftPushController,
    this.topPushController,
    this.errorText,
    this.onIssue,
    this.autoSpacingItems,
  });

  final TextEditingController leftMarginController;
  final TextEditingController topMarginController;
  final TextEditingController extraAreaController;
  final TextEditingController? copiesController;
  final TextEditingController? rightMarginController;
  final TextEditingController? leftPushController;
  final TextEditingController? topPushController;
  final String autoSpacing;
  final String orientation;
  final String selectedPrinterName;
  final String? errorText;
  final ValueChanged<String?> onAutoSpacingChanged;
  final ValueChanged<String?> onOrientationChanged;
  final VoidCallback onSelectPrinter;
  final VoidCallback? onIssue;
  final VoidCallback? onApply;
  final VoidCallback onClose;
  final List<DropdownMenuItem<String>>? autoSpacingItems;

  bool get _hasLabelPrintAdjustments =>
      rightMarginController != null &&
      leftPushController != null &&
      topPushController != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey(
        _hasLabelPrintAdjustments
            ? 'label-print-settings-dialog'
            : 'label-sheet-print-settings-dialog',
      ),
      width: 526,
      height: _hasLabelPrintAdjustments ? 354 : 200,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 8,
            width: _hasLabelPrintAdjustments ? 484 : 300,
            height: 58,
            child: _PrintDialogGroup(
              title: '여백',
              child: _hasLabelPrintAdjustments
                  ? Row(
                      children: [
                        const SizedBox(width: 10),
                        const _PrintDialogCenteredLabel('왼쪽'),
                        const SizedBox(width: 8),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: leftMarginController,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                        const SizedBox(width: 24),
                        const _PrintDialogCenteredLabel('오른쪽'),
                        const SizedBox(width: 8),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: rightMarginController!,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                        const SizedBox(width: 24),
                        const _PrintDialogCenteredLabel('위쪽'),
                        const SizedBox(width: 8),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: topMarginController,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 7),
                        const _PrintDialogCenteredLabel('왼쪽'),
                        const SizedBox(width: 8),
                        _PrintDialogShiftedDown(
                          child: _PrintDialogInput(
                            controller: leftMarginController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _PrintDialogCenteredLabel('mm'),
                        const SizedBox(width: 24),
                        const _PrintDialogCenteredLabel('위쪽'),
                        const SizedBox(width: 8),
                        _PrintDialogShiftedDown(
                          child: _PrintDialogInput(
                            controller: topMarginController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _PrintDialogCenteredLabel('mm'),
                      ],
                    ),
            ),
          ),
          if (!_hasLabelPrintAdjustments)
            Positioned(
              left: 336,
              top: 8,
              width: 168,
              height: 58,
              child: _PrintDialogGroup(
                title: '자동줄간격',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: _autoSpacingDropdownWidth,
                      height: _compactDropdownHeight,
                      child: DropdownButton2<String>(
                        value: autoSpacing,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: labelStyle,
                        items: autoSpacingItems ?? defaultAutoSpacingItems,
                        onChanged: onAutoSpacingChanged,
                        buttonStyleData: const ButtonStyleData(
                          height: _compactDropdownHeight,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 260,
                          useRootNavigator: true,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: _compactDropdownMenuItemHeight,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        iconStyleData: const IconStyleData(
                          iconSize: 18,
                          iconEnabledColor: Color(0xff6a6a6a),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const _PrintDialogCenteredLabel('%'),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          if (_hasLabelPrintAdjustments)
            Positioned(
              left: 24,
              right: 22,
              top: 250,
              height: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 71,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('발행 프린터', style: sectionStyle),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const ValueKey('label-print-printer-value'),
                    width: 291,
                    height: 30,
                    child: _PrintDialogInsetValue(value: selectedPrinterName),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    key: const ValueKey('label-print-printer-select'),
                    width: 94,
                    height: 30,
                    child: _PrintDialogButton(
                      label: '프린터 선택',
                      onPressed: onSelectPrinter,
                    ),
                  ),
                ],
              ),
            ),
          if (!_hasLabelPrintAdjustments)
            const Positioned(
              left: 24,
              top: 81,
              child: Text('발행 프린터', style: sectionStyle),
            ),
          if (!_hasLabelPrintAdjustments)
            Positioned(
              left: 107,
              top: 74,
              width: 291,
              height: 30,
              child: _PrintDialogInsetValue(value: selectedPrinterName),
            ),
          if (!_hasLabelPrintAdjustments)
            Positioned(
              right: 22,
              top: 74,
              width: 94,
              height: 30,
              child: _PrintDialogButton(
                label: '프린터 선택',
                onPressed: onSelectPrinter,
              ),
            ),
          if (!_hasLabelPrintAdjustments)
            Positioned(
              left: 104,
              top: 116,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _PrintDialogCenteredLabel('추가 영역'),
                  const SizedBox(width: 8),
                  _PrintDialogShiftedDown(
                    child: _PrintDialogInput(controller: extraAreaController),
                  ),
                  const SizedBox(width: 8),
                  const _PrintDialogCenteredLabel('mm'),
                ],
              ),
            ),
          if (!_hasLabelPrintAdjustments)
            Positioned(
              left: 322,
              top: 118,
              child: Row(
                children: [
                  _PrintDialogRadio(
                    label: '가로',
                    value: 'horizontal',
                    groupValue: orientation,
                    onChanged: onOrientationChanged,
                  ),
                  const SizedBox(width: 18),
                  _PrintDialogRadio(
                    label: '세로',
                    value: 'vertical',
                    groupValue: orientation,
                    onChanged: onOrientationChanged,
                  ),
                ],
              ),
            ),
          if (_hasLabelPrintAdjustments)
            Positioned(
              left: 20,
              top: 74,
              width: 484,
              height: 94,
              child: _PrintDialogGroup(
                title: '출력 조정',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const _PrintDialogCenteredLabel('왼쪽 밀기'),
                        const SizedBox(width: 6),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: leftPushController!,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                        const SizedBox(width: 24),
                        const _PrintDialogCenteredLabel('위쪽 밀기'),
                        const SizedBox(width: 6),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: topPushController!,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const _PrintDialogCenteredLabel('추가 영역'),
                        const SizedBox(width: 6),
                        _PrintDialogShiftedDown(
                          offset: 4,
                          child: _PrintDialogInput(
                            controller: extraAreaController,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const _PrintDialogCenteredLabel('mm'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (_hasLabelPrintAdjustments)
            Positioned(
              left: 20,
              top: 176,
              width: 300,
              height: 58,
              child: _PrintDialogGroup(
                title: '자동줄간격',
                child: Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: _autoSpacingDropdownWidth,
                      height: _compactDropdownHeight,
                      child: DropdownButton2<String>(
                        value: autoSpacing,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: labelStyle,
                        items: autoSpacingItems ?? defaultAutoSpacingItems,
                        onChanged: onAutoSpacingChanged,
                        buttonStyleData: const ButtonStyleData(
                          height: _compactDropdownHeight,
                          padding: EdgeInsets.zero,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 260,
                          useRootNavigator: true,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: _compactDropdownMenuItemHeight,
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        iconStyleData: const IconStyleData(
                          iconSize: 18,
                          iconEnabledColor: Color(0xff6a6a6a),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          if (_hasLabelPrintAdjustments)
            Positioned(
              left: 336,
              top: 176,
              width: 168,
              height: 58,
              child: _PrintDialogGroup(
                title: '출력 방향',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PrintDialogRadio(
                      label: '가로',
                      value: 'horizontal',
                      groupValue: orientation,
                      onChanged: onOrientationChanged,
                    ),
                    const SizedBox(width: 12),
                    _PrintDialogRadio(
                      label: '세로',
                      value: 'vertical',
                      groupValue: orientation,
                      onChanged: onOrientationChanged,
                    ),
                  ],
                ),
              ),
            ),
          if (_hasLabelPrintAdjustments && errorText != null)
            Positioned(
              left: 24,
              top: 284,
              child: Text(
                errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (!_hasLabelPrintAdjustments && copiesController != null)
            const Positioned(
              left: 24,
              top: 149,
              child: Text(
                '매수',
                style: TextStyle(fontSize: 30, color: Color(0xff000000)),
              ),
            ),
          if (!_hasLabelPrintAdjustments && copiesController != null)
            Positioned(
              left: 91,
              top: 151,
              width: 84,
              height: 38,
              child: _PrintDialogInput(
                controller: copiesController!,
                fontSize: 23,
                height: 38,
                contentPadding: const EdgeInsets.fromLTRB(8, 3, 8, 5),
              ),
            ),
          Positioned(
            left: _hasLabelPrintAdjustments ? 334 : 245,
            bottom: 12,
            width: 84,
            height: 30,
            child: _PrintDialogButton(label: '취소', onPressed: onClose),
          ),
          Positioned(
            left: _hasLabelPrintAdjustments ? 423 : 334,
            bottom: 12,
            width: 84,
            height: 30,
            child: _PrintDialogButton(label: '적용', onPressed: onApply),
          ),
          if (onIssue != null)
            Positioned(
              left: 423,
              bottom: 12,
              width: 84,
              height: 30,
              child: _PrintDialogButton(label: '발행', onPressed: onIssue!),
            ),
        ],
      ),
    );
  }

  static const labelStyle = TextStyle(fontSize: 13, color: Color(0xff111111));

  static const sectionStyle = TextStyle(fontSize: 14, color: Color(0xff111111));
  static const double _compactDropdownHeight = 28;
  static const double _compactDropdownMenuItemHeight = 28;
  static const double _autoSpacingDropdownWidth = 117;

  static final List<DropdownMenuItem<String>> defaultAutoSpacingItems =
      buildAutoSpacingItems(minimum: 80, step: 5);

  static List<DropdownMenuItem<String>> buildAutoSpacingItems({
    required int minimum,
    required int step,
    bool includePercent = false,
  }) => [
    const DropdownMenuItem(
      value: 'none',
      child: _PrintDialogDropdownItemLabel('간격조정 없음'),
    ),
    for (var value = minimum; value <= 300; value += step)
      DropdownMenuItem(
        value: '$value',
        child: _PrintDialogDropdownItemLabel(
          includePercent ? '$value %' : '$value',
        ),
      ),
  ];
}

class _PrintDialogDropdownItemLabel extends StatelessWidget {
  const _PrintDialogDropdownItemLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: LabelPrintSettingsPanel.labelStyle),
      ),
    );
  }
}

class _PrintDialogCenteredLabel extends StatelessWidget {
  const _PrintDialogCenteredLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Center(
        child: Text(label, style: LabelPrintSettingsPanel.labelStyle),
      ),
    );
  }
}

class _PrintDialogShiftedDown extends StatelessWidget {
  const _PrintDialogShiftedDown({required this.child, this.offset = 3});

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(offset: Offset(0, offset), child: child);
  }
}

class _PrintDialogInsetValue extends StatelessWidget {
  const _PrintDialogInsetValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xffffffff),
        border: Border.all(color: const Color(0xffd4d4d4)),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: LabelPrintSettingsPanel.labelStyle,
          ),
        ),
      ),
    );
  }
}

class _PrintDialogGroup extends StatelessWidget {
  const _PrintDialogGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          top: 6,
          child: Container(
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
              child: Text(
                title,
                style: LabelPrintSettingsPanel.labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrintDialogInput extends StatelessWidget {
  const _PrintDialogInput({
    required this.controller,
    this.fontSize = 13,
    this.height,
    this.contentPadding = const EdgeInsets.fromLTRB(5, 2, 5, 3),
  });

  final TextEditingController controller;
  final double fontSize;
  final double? height;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fontSize > 20 ? 84 : 56,
      height: height ?? (fontSize > 20 ? 56 : 28),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: fontSize, color: const Color(0xff111111)),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: const Color(0xffffffff),
          contentPadding: contentPadding,
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xffc7c7c7)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff0067c0), width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _PrintDialogButton extends StatelessWidget {
  const _PrintDialogButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xffffffff),
        foregroundColor: const Color(0xff111111),
        side: const BorderSide(color: Color(0xffc7c7c7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 13),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _PrintDialogRadio extends StatelessWidget {
  const _PrintDialogRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? const Color(0xff0067c0)
                    : const Color(0xff7a7a7a),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xff0067c0),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 4),
          Text(label, style: LabelPrintSettingsPanel.labelStyle),
        ],
      ),
    );
  }
}