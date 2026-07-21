import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fortune_sheet_canvas.dart';
import 'fortune_sheet_model.dart';
import 'fortune_sheet_painter.dart';

class FortuneObjectLayerPanel extends StatefulWidget {
  const FortuneObjectLayerPanel({
    super.key,
    required this.controller,
    this.onClose,
  });

  final FortuneSheetController controller;
  final VoidCallback? onClose;

  @override
  State<FortuneObjectLayerPanel> createState() =>
      _FortuneObjectLayerPanelState();
}

class _FortuneObjectLayerPanelState extends State<FortuneObjectLayerPanel> {
  final ScrollController _layerScrollController = ScrollController();
  final ScrollController _propertyScrollController = ScrollController();
  String? _sheetId;
  FortuneSheetObjectKey? _dropTargetKey;
  FortuneObjectDropSide? _dropSide;

  @override
  void dispose() {
    _layerScrollController.dispose();
    _propertyScrollController.dispose();
    super.dispose();
  }

  void _resetScrollForSheet(String? sheetId) {
    if (sheetId == null || _sheetId == sheetId) {
      return;
    }
    _sheetId = sheetId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _sheetId != sheetId) {
        return;
      }
      if (_layerScrollController.hasClients) {
        _layerScrollController.jumpTo(0);
      }
      if (_propertyScrollController.hasClients) {
        _propertyScrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final snapshot = widget.controller.objectSelection;
        _resetScrollForSheet(snapshot.sheetId);
        final objects = snapshot.objects.reversed.toList(growable: false);
        return Material(
          color: const Color(0xfff8f9fa),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '개체',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        tooltip: Overlay.maybeOf(context) == null ? null : '닫기',
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 19),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PanelAction(
                      tooltip: '선택한 개체 삭제',
                      icon: Icons.delete_outline,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.deleteSelectedObjects,
                    ),
                    _PanelAction(
                      tooltip: '선택한 개체 복제',
                      icon: Icons.copy,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.duplicateSelectedObjects,
                    ),
                    _PanelAction(
                      tooltip: '맨 앞으로',
                      icon: Icons.vertical_align_top,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.bringSelectedObjectsToFront,
                    ),
                    _PanelAction(
                      tooltip: '앞으로',
                      icon: Icons.keyboard_arrow_up,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.bringSelectedObjectsForward,
                    ),
                    _PanelAction(
                      tooltip: '뒤로',
                      icon: Icons.keyboard_arrow_down,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.sendSelectedObjectsBackward,
                    ),
                    _PanelAction(
                      tooltip: '맨 뒤로',
                      icon: Icons.vertical_align_bottom,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : widget.controller.sendSelectedObjectsToBack,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                flex: 3,
                child: objects.isEmpty
                    ? const Center(
                        child: Text(
                          '개체 없음',
                          style: TextStyle(
                            color: Color(0xff6b7280),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                      controller: _layerScrollController,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: objects.length,
                        itemExtent: 38,
                        itemBuilder: (context, index) {
                          final object = objects[index];
                          final selected = snapshot.selectedKeys.contains(
                            object.key,
                          );
                          return _ObjectLayerRow(
                            object: object,
                            selected: selected,
                            selectedKeys: snapshot.selectedKeys,
                            dropSide: _dropTargetKey == object.key
                                ? _dropSide
                                : null,
                            onTap: () => _selectRow(object.key),
                            onDragStarted: () {
                              if (!selected) {
                                widget.controller.selectObject(object.key);
                              }
                            },
                            onHover: (side) {
                              if (snapshot.selectedKeys.contains(object.key)) {
                                side = null;
                              }
                              if (_dropTargetKey != object.key ||
                                  _dropSide != side) {
                                setState(() {
                                  _dropTargetKey = object.key;
                                  _dropSide = side;
                                });
                              }
                            },
                            onLeave: () => _clearDropIndicator(object.key),
                            onAccept: (side) {
                              _clearDropIndicator(object.key);
                              if (side != null) {
                                widget.controller.reorderSelectedObjects(
                                  object.key,
                                  side,
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
              if (snapshot.activeKey != null) ...[
                const Divider(height: 1),
                Flexible(
                  flex: 2,
                  child: snapshot.selectedKeys.length > 1
                      ? _MultipleSelectionPanel(
                          count: snapshot.selectedKeys.length,
                          controller: widget.controller,
                        )
                      : _ObjectPropertyEditor(
                          key: ValueKey(_propertySnapshotIdentity(snapshot)),
                          snapshot: snapshot,
                          controller: widget.controller,
                          scrollController: _propertyScrollController,
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _selectRow(FortuneSheetObjectKey key) {
    if (HardwareKeyboard.instance.isShiftPressed) {
      widget.controller.selectObjectRange(key);
    } else if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      widget.controller.toggleObject(key);
    } else {
      widget.controller.selectObject(key);
    }
  }

  void _clearDropIndicator(FortuneSheetObjectKey key) {
    if (_dropTargetKey == key) {
      setState(() {
        _dropTargetKey = null;
        _dropSide = null;
      });
    }
  }
}

class _ObjectLayerRow extends StatelessWidget {
  const _ObjectLayerRow({
    required this.object,
    required this.selected,
    required this.selectedKeys,
    required this.dropSide,
    required this.onTap,
    required this.onDragStarted,
    required this.onHover,
    required this.onLeave,
    required this.onAccept,
  });

  final FortuneSheetObjectRef object;
  final bool selected;
  final Set<FortuneSheetObjectKey> selectedKeys;
  final FortuneObjectDropSide? dropSide;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final ValueChanged<FortuneObjectDropSide?> onHover;
  final VoidCallback onLeave;
  final ValueChanged<FortuneObjectDropSide?> onAccept;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      key: ValueKey('fortune-object-row-${object.key.kind.name}-${object.key.id}'),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xffe8f0fe) : Colors.transparent,
          border: Border(
            top: dropSide == FortuneObjectDropSide.before
                ? const BorderSide(color: Color(0xff1967d2), width: 2)
                : BorderSide.none,
            bottom: dropSide == FortuneObjectDropSide.after
                ? const BorderSide(color: Color(0xff1967d2), width: 2)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                _objectIcon(object.key.kind),
                size: 18,
                color: selected
                    ? const Color(0xff1967d2)
                    : const Color(0xff5f6368),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${_objectKindLabel(object.key.kind)} ${object.key.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Icon(Icons.drag_indicator, size: 17, color: Color(0xff80868b)),
            ],
          ),
        ),
      ),
    );
    return DragTarget<FortuneSheetObjectKey>(
      onWillAcceptWithDetails: (details) {
        final box = context.findRenderObject() as RenderBox?;
        final localY = box?.globalToLocal(details.offset).dy ?? 0;
        final side = localY < 19
            ? FortuneObjectDropSide.before
            : FortuneObjectDropSide.after;
        onHover(selectedKeys.contains(object.key) ? null : side);
        return true;
      },
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        final localY = box?.globalToLocal(details.offset).dy ?? 0;
        final side = localY < 19
            ? FortuneObjectDropSide.before
            : FortuneObjectDropSide.after;
        onHover(selectedKeys.contains(object.key) ? null : side);
      },
      onLeave: (_) => onLeave(),
      onAcceptWithDetails: (_) => onAccept(dropSide),
      builder: (context, candidates, rejected) {
        return Draggable<FortuneSheetObjectKey>(
          data: object.key,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onLeave(),
          feedback: Material(
            elevation: 4,
            child: SizedBox(width: 260, height: 38, child: row),
          ),
          childWhenDragging: Opacity(opacity: 0.45, child: row),
          child: row,
        );
      },
    );
  }
}

String _propertySnapshotIdentity(FortuneObjectSelectionSnapshot snapshot) {
  final line = snapshot.activeLine;
  if (line != null) {
    return '${snapshot.sheetId}|${line.id}|${line.x1}|${line.y1}|${line.x2}|${line.y2}|${line.strokeStyle}|${line.strokeWidthMm}|${line.strokeColor}';
  }
  final shape = snapshot.activeShape;
  if (shape != null) {
    return '${snapshot.sheetId}|${shape.id}|${shape.left}|${shape.top}|${shape.width}|${shape.height}|${shape.rotationDegrees}|${shape.strokeStyle}|${shape.strokeWidthMm}|${shape.strokeColor}|${shape.fillColor}|${shape.cornerRadiusMm}';
  }
  return '${snapshot.sheetId}|${snapshot.activeKey}';
}

class _MultipleSelectionPanel extends StatelessWidget {
  const _MultipleSelectionPanel({
    required this.count,
    required this.controller,
  });

  final int count;
  final FortuneSheetController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '$count개 개체 선택됨',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: controller.duplicateSelectedObjects,
              icon: const Icon(Icons.copy, size: 17),
              label: const Text('복제'),
            ),
            OutlinedButton.icon(
              onPressed: controller.deleteSelectedObjects,
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('삭제'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ObjectPropertyEditor extends StatefulWidget {
  const _ObjectPropertyEditor({
    super.key,
    required this.snapshot,
    required this.controller,
    required this.scrollController,
  });

  final FortuneObjectSelectionSnapshot snapshot;
  final FortuneSheetController controller;
  final ScrollController scrollController;

  @override
  State<_ObjectPropertyEditor> createState() => _ObjectPropertyEditorState();
}

class _ObjectPropertyEditorState extends State<_ObjectPropertyEditor> {
  final Map<String, TextEditingController> _fields = {};
  FortuneStrokeStyle _strokeStyle = FortuneStrokeStyle.solid;
  bool _noFill = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeFields() {
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    if (line != null) {
      _strokeStyle = line.strokeStyle;
      _setGeometryField('x1', line.x1);
      _setGeometryField('y1', line.y1);
      _setGeometryField('x2', line.x2);
      _setGeometryField('y2', line.y2);
      _setField('strokeWidth', line.strokeWidthMm);
      _setField('strokeColor', line.strokeColor);
    } else if (shape != null) {
      _strokeStyle = shape.strokeStyle;
      _noFill = shape.fillColor == null;
      _setGeometryField('left', shape.left);
      _setGeometryField('top', shape.top);
      _setGeometryField('width', shape.width);
      _setGeometryField('height', shape.height);
      _setField('rotation', shape.rotationDegrees);
      _setField('strokeWidth', shape.strokeWidthMm);
      _setField('strokeColor', shape.strokeColor);
      _setField('fillColor', shape.fillColor ?? '#FFFFFF');
      if (shape.kind == FortuneShapeKind.roundedRectangle) {
        _setField('cornerRadius', shape.cornerRadiusMm);
      }
    }
  }

  void _setGeometryField(String name, double logicalValue) {
    final value = widget.snapshot.geometryUsesMillimeters
        ? fortuneLogicalPixelsToMillimeters(logicalValue)
        : logicalValue;
    _setField(name, value);
  }

  void _setField(String name, Object value) {
    _fields[name] = TextEditingController(
      text: value is double ? _formatNumber(value) : '$value',
    );
  }

  double? _number(String name, {bool geometry = false}) {
    final value = double.tryParse(_fields[name]?.text.trim() ?? '');
    if (value == null || !value.isFinite) {
      return null;
    }
    return geometry && widget.snapshot.geometryUsesMillimeters
        ? fortuneMillimetersToLogicalPixels(value)
        : value;
  }

  void _apply() {
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    final strokeWidth = _number('strokeWidth');
    final strokeColor = _fields['strokeColor']?.text.trim();
    if (strokeWidth == null || strokeColor == null) {
      setState(() => _error = '유효한 숫자와 색상을 입력하세요.');
      return;
    }
    if (line != null) {
      final x1 = _number('x1', geometry: true);
      final y1 = _number('y1', geometry: true);
      final x2 = _number('x2', geometry: true);
      final y2 = _number('y2', geometry: true);
      if ([x1, y1, x2, y2].contains(null)) {
        setState(() => _error = '유효한 좌표를 입력하세요.');
        return;
      }
      widget.controller.updateSelectedLine(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        strokeStyle: _strokeStyle,
        strokeWidthMm: strokeWidth,
        strokeColor: strokeColor,
      );
    } else if (shape != null) {
      final left = _number('left', geometry: true);
      final top = _number('top', geometry: true);
      final width = _number('width', geometry: true);
      final height = _number('height', geometry: true);
      final rotation = _number('rotation');
      final radius = shape.kind == FortuneShapeKind.roundedRectangle
          ? _number('cornerRadius')
          : 0.0;
      if ([left, top, width, height, rotation, radius].contains(null)) {
        setState(() => _error = '유효한 도형 값을 입력하세요.');
        return;
      }
      widget.controller.updateSelectedShape(
        left: left,
        top: top,
        width: width,
        height: height,
        rotationDegrees: rotation,
        strokeStyle: _strokeStyle,
        strokeWidthMm: strokeWidth,
        strokeColor: strokeColor,
        fillColor: _noFill ? null : _fields['fillColor']?.text.trim(),
        cornerRadiusMm: radius,
      );
    }
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    if (line == null && shape == null) {
      return const SizedBox.shrink();
    }
    final unit = widget.snapshot.geometryUsesMillimeters ? 'mm' : 'px';
    final fields = <Widget>[
      Text(
        '${_objectKindLabel(widget.snapshot.activeKey!.kind)} 속성',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      _ReadOnlyProperty(label: '개체 ID', value: widget.snapshot.activeKey!.id),
    ];
    if (line != null) {
      fields.addAll([
        _field('시작 X', 'x1', suffix: unit),
        _field('시작 Y', 'y1', suffix: unit),
        _field('끝 X', 'x2', suffix: unit),
        _field('끝 Y', 'y2', suffix: unit),
        _ReadOnlyProperty(
          label: '길이',
          value: '${_formatNumber(_displayLength(line))} $unit',
        ),
        _ReadOnlyProperty(
          label: '각도',
          value: '${_formatNumber(_lineAngle(line))}°',
        ),
      ]);
    } else if (shape != null) {
      fields.addAll([
        _field('X', 'left', suffix: unit),
        _field('Y', 'top', suffix: unit),
        _field('폭', 'width', suffix: unit),
        _field('높이', 'height', suffix: unit),
        _field('회전', 'rotation', suffix: '°'),
      ]);
    }
    fields.addAll([
      DropdownButtonFormField<FortuneStrokeStyle>(
        initialValue: _strokeStyle,
        decoration: const InputDecoration(labelText: '테두리 스타일'),
        items: FortuneStrokeStyle.values
            .map(
              (style) => DropdownMenuItem(
                value: style,
                child: Text(_strokeStyleLabel(style)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) {
            setState(() => _strokeStyle = value);
          }
        },
      ),
      _field('테두리 폭', 'strokeWidth', suffix: 'mm'),
      _field('테두리 색상', 'strokeColor'),
    ]);
    if (shape != null) {
      fields.addAll([
        CheckboxListTile(
          key: const ValueKey('fortune-object-property-no-fill'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('채우기 없음', style: TextStyle(fontSize: 13)),
          value: _noFill,
          onChanged: (value) => setState(() => _noFill = value ?? false),
        ),
        if (!_noFill) _field('채우기 색상', 'fillColor'),
        if (shape.kind == FortuneShapeKind.roundedRectangle)
          _field('모서리 반경', 'cornerRadius', suffix: 'mm'),
      ]);
    }
    fields.addAll([
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _error!,
            style: const TextStyle(color: Color(0xffb3261e), fontSize: 12),
          ),
        ),
      const SizedBox(height: 10),
      FilledButton(
        key: const ValueKey('fortune-object-property-apply'),
        onPressed: _apply,
        child: const Text('적용'),
      ),
    ]);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(12),
      children: fields,
    );
  }

  Widget _field(String label, String name, {String? suffix}) {
    return TextField(
      key: ValueKey('fortune-object-property-$name'),
      controller: _fields[name],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      style: const TextStyle(fontSize: 13),
      onSubmitted: (_) => _apply(),
    );
  }

  double _displayLength(FortuneLine line) {
    final logical = math.sqrt(
      math.pow(line.x2 - line.x1, 2) + math.pow(line.y2 - line.y1, 2),
    );
    return widget.snapshot.geometryUsesMillimeters
        ? fortuneLogicalPixelsToMillimeters(logical)
        : logical;
  }

  double _lineAngle(FortuneLine line) {
    final degrees = math.atan2(line.y2 - line.y1, line.x2 - line.x1) * 180 / math.pi;
    return degrees < 0 ? degrees + 360 : degrees;
  }
}

class _ReadOnlyProperty extends StatelessWidget {
  const _ReadOnlyProperty({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xff5f6368), fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

String _formatNumber(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _strokeStyleLabel(FortuneStrokeStyle style) {
  return switch (style) {
    FortuneStrokeStyle.solid => '실선',
    FortuneStrokeStyle.dashed => '긴 점선',
    FortuneStrokeStyle.dotted => '점선',
    FortuneStrokeStyle.dashDot => '일점쇄선',
  };
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: Overlay.maybeOf(context) == null ? null : tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      visualDensity: VisualDensity.compact,
    );
  }
}

IconData _objectIcon(FortuneSheetObjectKind kind) {
  return switch (kind) {
    FortuneSheetObjectKind.image => Icons.image_outlined,
    FortuneSheetObjectKind.barcode => Icons.qr_code_2,
    FortuneSheetObjectKind.line => Icons.show_chart,
    FortuneSheetObjectKind.rectangle => Icons.crop_square,
    FortuneSheetObjectKind.roundedRectangle => Icons.rounded_corner,
    FortuneSheetObjectKind.ellipse => Icons.circle_outlined,
  };
}

String _objectKindLabel(FortuneSheetObjectKind kind) {
  return switch (kind) {
    FortuneSheetObjectKind.image => '이미지',
    FortuneSheetObjectKind.barcode => '바코드',
    FortuneSheetObjectKind.line => '선',
    FortuneSheetObjectKind.rectangle => '사각형',
    FortuneSheetObjectKind.roundedRectangle => '둥근 사각형',
    FortuneSheetObjectKind.ellipse => '타원',
  };
}