import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int labelSheetDefaultZoomPercent = 100;
const int labelSheetMinZoomPercent = 10;
const int labelSheetMaxZoomPercent = 400;

enum LabelSheetZoomToolbarPlacement {
  sheetToolbarEnd,
  previewTabAreaEnd,
  hidden,
}

class LabelSheetZoomController extends ValueNotifier<int> {
  LabelSheetZoomController({
    int initialPercent = labelSheetDefaultZoomPercent,
    this.minPercent = labelSheetMinZoomPercent,
    this.maxPercent = labelSheetMaxZoomPercent,
  }) : assert(minPercent <= maxPercent),
       super(
        initialPercent.clamp(
          minPercent,
          maxPercent,
        ),
      );

  final int minPercent;
  final int maxPercent;

  ValueChanged<int>? _setZoomPercent;
  bool _initialAutoFitApplied = false;

  void applyInitialAutoFit(int percent) {
    if (_initialAutoFitApplied) return;
    _initialAutoFitApplied = true;
    setZoomPercent(percent);
  }

  void setZoomPercent(int percent) {
    final callback = _setZoomPercent;
    if (callback != null) {
      callback(percent);
      return;
    }
    value = percent.clamp(minPercent, maxPercent);
  }

  void step(int deltaPercent) => setZoomPercent(value + deltaPercent);

  void bindZoomSetter(ValueChanged<int> setZoomPercent) {
    _setZoomPercent = setZoomPercent;
  }

  void unbindZoomSetter(ValueChanged<int> setZoomPercent) {
    if (_setZoomPercent == setZoomPercent) {
      _setZoomPercent = null;
    }
  }
}

class LabelSheetZoomToolbar extends StatefulWidget {
  const LabelSheetZoomToolbar({
    super.key,
    required this.controller,
    this.backgroundColor = const Color(0xFFF7F8FA),
  });

  final LabelSheetZoomController controller;
  final Color backgroundColor;

  @override
  State<LabelSheetZoomToolbar> createState() => _LabelSheetZoomToolbarState();
}

class _LabelSheetZoomToolbarState extends State<LabelSheetZoomToolbar> {
  late final TextEditingController _textController = TextEditingController(
    text: '${widget.controller.value}',
  );
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleZoomChanged);
  }

  @override
  void didUpdateWidget(covariant LabelSheetZoomToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleZoomChanged);
      widget.controller.addListener(_handleZoomChanged);
      _handleZoomChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleZoomChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleZoomChanged() {
    final text = '${widget.controller.value}';
    if (_textController.text == text) return;
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _commit() {
    widget.controller.setZoomPercent(
      int.tryParse(_textController.text) ?? labelSheetDefaultZoomPercent,
    );
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.backgroundColor,
    child: Row(
      key: const ValueKey('label-sheet-zoom-toolbar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelSheetZoomToolbarButton(
          label: '-',
          onPressed: () => widget.controller.step(-10),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 42,
          height: 25,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xffffffff),
              border: Border.all(color: const Color(0xffd4d4d4)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
              child: EditableText(
                key: const ValueKey('label-sheet-zoom-input'),
                controller: _textController,
                focusNode: _focusNode,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 13,
                  height: 1,
                  color: Color(0xff222222),
                ),
                cursorColor: const Color(0xff0188fb),
                cursorOffset: Offset.zero,
                backgroundCursorColor: const Color(0x330188fb),
                maxLines: 1,
                onSubmitted: (_) => _commit(),
                onEditingComplete: _commit,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        const Text(
          '%',
          style: TextStyle(fontSize: 13, color: Color(0xff222222)),
        ),
        const SizedBox(width: 4),
        _LabelSheetZoomToolbarButton(
          label: '+',
          onPressed: () => widget.controller.step(10),
        ),
      ],
    ),
  );
}

class _LabelSheetZoomToolbarButton extends StatefulWidget {
  const _LabelSheetZoomToolbarButton({
    this.label,
    this.child,
    required this.onPressed,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback onPressed;

  @override
  State<_LabelSheetZoomToolbarButton> createState() =>
      _LabelSheetZoomToolbarButtonState();
}

class _LabelSheetZoomToolbarButtonState
    extends State<_LabelSheetZoomToolbarButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _pressed
        ? const Color(0xffdfe5f2)
        : _hovered
        ? const Color(0xffedf2fb)
        : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(3),
          ),
          child: SizedBox(
            width: 23,
            height: 25,
            child: Center(
              child:
                  widget.child ??
                  Text(
                    widget.label!,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1,
                      color: Color(0xff5f6368),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
