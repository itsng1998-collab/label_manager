import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fortune_sheet_canvas.dart';
import 'fortune_sheet_model.dart';
import 'fortune_sheet_painter.dart';

typedef _BarcodePropertyOwner = ({
  String sheetId,
  FortuneSheetObjectKey key,
});

class _BarcodePropertyDraftState {
  const _BarcodePropertyDraftState({
    required this.fields,
    required this.showText,
    required this.preserveTemplateFormat,
    required this.pending,
    this.error,
  });

  final Map<String, String> fields;
  final bool showText;
  final bool preserveTemplateFormat;
  final bool pending;
  final String? error;

  _BarcodePropertyDraftState copyWith({
    Map<String, String>? fields,
    bool? showText,
    bool? preserveTemplateFormat,
    bool? pending,
    String? error,
    bool clearError = false,
  }) {
    return _BarcodePropertyDraftState(
      fields: fields ?? this.fields,
      showText: showText ?? this.showText,
      preserveTemplateFormat:
          preserveTemplateFormat ?? this.preserveTemplateFormat,
      pending: pending ?? this.pending,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class FortuneObjectLayerPanel extends StatefulWidget {
  const FortuneObjectLayerPanel({
    super.key,
    required this.controller,
    this.imageObjectOptions = const <FortuneObjectConnectionOption>[],
    this.barcodeObjectOptions = const <FortuneObjectConnectionOption>[],
    this.imageObjectIds = const <String>[],
    this.barcodeObjectIds = const <String>[],
    this.onClose,
    this.presentation = FortuneObjectPanelPresentation.hidden,
    this.layerFocusGeneration = 0,
    this.propertyFocusField,
    this.propertyFocusSheetId,
    this.propertyFocusObjectKey,
    this.propertyFocusGeneration = 0,
  });

  final FortuneSheetController controller;
  final List<FortuneObjectConnectionOption> imageObjectOptions;
  final List<FortuneObjectConnectionOption> barcodeObjectOptions;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final VoidCallback? onClose;
  final FortuneObjectPanelPresentation presentation;
  final int layerFocusGeneration;
  final String? propertyFocusField;
  final String? propertyFocusSheetId;
  final FortuneSheetObjectKey? propertyFocusObjectKey;
  final int propertyFocusGeneration;

  @override
  State<FortuneObjectLayerPanel> createState() =>
      _FortuneObjectLayerPanelState();
}

class _FortuneObjectLayerPanelState extends State<FortuneObjectLayerPanel> {
  final FocusNode _layerFocusNode = FocusNode(
    debugLabel: 'Fortune object layer list',
  );
  final ScrollController _layerScrollController = ScrollController();
  final ScrollController _propertyScrollController = ScrollController();
  String? _sheetId;
  FortuneSheetObjectKey? _dropTargetKey;
  FortuneObjectDropSide? _dropSide;
  int _consumedLayerFocusGeneration = 0;
  final Map<_BarcodePropertyOwner, _BarcodePropertyDraftState>
  _barcodePropertyDrafts = {};
  late bool _objectEditingAllowed;
  int _permissionDiscardGeneration = 0;

  @override
  void initState() {
    super.initState();
    _objectEditingAllowed = widget.controller.objectEditingAllowed;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FortuneObjectLayerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _objectEditingAllowed = widget.controller.objectEditingAllowed;
      widget.controller.addListener(_handleControllerChanged);
    }
    _scheduleLayerFocus();
  }

  void _handleControllerChanged() {
    final objectEditingAllowed = widget.controller.objectEditingAllowed;
    if (_objectEditingAllowed && !objectEditingAllowed) {
      _barcodePropertyDrafts.clear();
      _permissionDiscardGeneration += 1;
    }
    _objectEditingAllowed = objectEditingAllowed;
  }

  void _scheduleLayerFocus() {
    final generation = widget.layerFocusGeneration;
    if (generation <= _consumedLayerFocusGeneration ||
        widget.presentation == FortuneObjectPanelPresentation.hidden) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.layerFocusGeneration != generation ||
          widget.presentation == FortuneObjectPanelPresentation.hidden) {
        return;
      }
      _consumedLayerFocusGeneration = generation;
      _layerFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _layerFocusNode.dispose();
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
        final canMutate = widget.controller.objectMutationEnabled;
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
                    Expanded(
                      child: _PanelAction(
                        tooltip: '선택한 개체 삭제',
                        icon: Icons.delete_outline,
                        onPressed: snapshot.activeKey == null || !canMutate
                            ? null
                            : widget.controller.deleteSelectedObjects,
                      ),
                    ),
                    Expanded(
                      child: _PanelAction(
                        tooltip: '선택한 개체 복제',
                        icon: Icons.copy,
                        onPressed: snapshot.activeKey == null || !canMutate
                            ? null
                            : widget.controller.duplicateSelectedObjects,
                      ),
                    ),
                    Expanded(
                      child: _PanelAction(
                        tooltip: '맨 앞으로',
                        icon: Icons.vertical_align_top,
                        onPressed:
                            !widget.controller.isSelectedObjectCommandEnabled(
                              fortuneContextBringToFrontCommand,
                            )
                            ? null
                            : widget.controller.bringSelectedObjectsToFront,
                      ),
                    ),
                    Expanded(
                      child: _PanelAction(
                        tooltip: '앞으로',
                        icon: Icons.keyboard_arrow_up,
                        onPressed:
                            !widget.controller.isSelectedObjectCommandEnabled(
                              fortuneContextBringForwardCommand,
                            )
                            ? null
                            : widget.controller.bringSelectedObjectsForward,
                      ),
                    ),
                    Expanded(
                      child: _PanelAction(
                        tooltip: '뒤로',
                        icon: Icons.keyboard_arrow_down,
                        onPressed:
                            !widget.controller.isSelectedObjectCommandEnabled(
                              fortuneContextSendBackwardCommand,
                            )
                            ? null
                            : widget.controller.sendSelectedObjectsBackward,
                      ),
                    ),
                    Expanded(
                      child: _PanelAction(
                        tooltip: '맨 뒤로',
                        icon: Icons.vertical_align_bottom,
                        onPressed:
                            !widget.controller.isSelectedObjectCommandEnabled(
                              fortuneContextSendToBackCommand,
                            )
                            ? null
                            : widget.controller.sendSelectedObjectsToBack,
                      ),
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
                    : Focus(
                        focusNode: _layerFocusNode,
                        onKeyEvent: _handleLayerKeyEvent,
                        child: ListView.builder(
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
                                _layerFocusNode.requestFocus();
                                if (!selected) {
                                  widget.controller.selectObject(object.key);
                                }
                              },
                              onHover: (side) {
                                if (snapshot.selectedKeys.contains(
                                  object.key,
                                )) {
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
                                if (side != null && canMutate) {
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
              ),
              if (snapshot.activeKey != null) ...[
                const Divider(height: 1),
                Flexible(
                  flex: 2,
                  child: snapshot.selectedKeys.length > 1
                      ? _MultipleSelectionPanel(
                          count: snapshot.selectedKeys.length,
                          controller: widget.controller,
                          canMutate: canMutate,
                        )
                      : Focus(
                          canRequestFocus: false,
                          onKeyEvent: _handlePropertyKeyEvent,
                          child: _ObjectPropertyEditor(
                            key: ValueKey(
                              '${snapshot.sheetId}|${snapshot.activeKey}|'
                              '$_permissionDiscardGeneration',
                            ),
                            snapshot: snapshot,
                            controller: widget.controller,
                            scrollController: _propertyScrollController,
                            imageObjectOptions: widget.imageObjectOptions,
                            barcodeObjectOptions: widget.barcodeObjectOptions,
                            imageObjectIds: widget.imageObjectIds,
                            barcodeObjectIds: widget.barcodeObjectIds,
                            presentation: widget.presentation,
                            propertyFocusField: widget.propertyFocusField,
                            propertyFocusSheetId: widget.propertyFocusSheetId,
                            propertyFocusObjectKey:
                                widget.propertyFocusObjectKey,
                            propertyFocusGeneration:
                                widget.propertyFocusGeneration,
                            barcodeDraft: snapshot.sheetId == null
                                ? null
                                : _barcodePropertyDrafts[(
                                    sheetId: snapshot.sheetId!,
                                    key: snapshot.activeKey!,
                                  )],
                            onBarcodeDraftChanged: (draft) {
                              final sheetId = snapshot.sheetId;
                              final key = snapshot.activeKey;
                              if (sheetId == null || key == null) return;
                              _barcodePropertyDrafts[(
                                    sheetId: sheetId,
                                    key: key,
                                  )] =
                                  draft;
                            },
                            onBarcodeDraftRemoved: () {
                              final sheetId = snapshot.sheetId;
                              final key = snapshot.activeKey;
                              if (sheetId == null || key == null) return;
                              _barcodePropertyDrafts.remove((
                                sheetId: sheetId,
                                key: key,
                              ));
                            },
                          ),
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
    _layerFocusNode.requestFocus();
    if (!widget.controller.barcodePropertyRenderPending) {
      widget.controller.finalizeActiveObjectPropertyDraft();
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      widget.controller.selectObjectRange(key);
    } else if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      widget.controller.toggleObject(key);
    } else {
      widget.controller.selectObject(key);
    }
  }

  KeyEventResult _handlePropertyKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        widget.controller.discardActiveObjectPropertyDraft()) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleLayerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final control =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final key = event.logicalKey;
    if (control) {
      if (key == LogicalKeyboardKey.keyA) {
        widget.controller.selectAllObjects();
      } else if (key == LogicalKeyboardKey.keyC) {
        widget.controller.copySelectedObjects();
      } else if (key == LogicalKeyboardKey.keyX) {
        widget.controller.cutSelectedObjects();
      } else if (key == LogicalKeyboardKey.keyV) {
        widget.controller.pasteObjects();
      } else if (key == LogicalKeyboardKey.keyD) {
        widget.controller.duplicateSelectedObjects();
      } else if (key == LogicalKeyboardKey.arrowUp) {
        widget.controller.bringSelectedObjectsForward();
      } else if (key == LogicalKeyboardKey.arrowDown) {
        widget.controller.sendSelectedObjectsBackward();
      } else if (key == LogicalKeyboardKey.home) {
        widget.controller.bringSelectedObjectsToFront();
      } else if (key == LogicalKeyboardKey.end) {
        widget.controller.sendSelectedObjectsToBack();
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      widget.controller.deleteSelectedObjects();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.arrowUp &&
        key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.home &&
        key != LogicalKeyboardKey.end) {
      return KeyEventResult.ignored;
    }
    final objects = widget.controller.objectSelection.objects.reversed
        .map((object) => object.key)
        .toList(growable: false);
    if (objects.isEmpty) {
      return KeyEventResult.handled;
    }
    final active = widget.controller.objectSelection.activeKey;
    final currentIndex = active == null
        ? 0
        : math.max(0, objects.indexOf(active));
    final nextIndex = key == LogicalKeyboardKey.home
        ? 0
        : key == LogicalKeyboardKey.end
        ? objects.length - 1
        : key == LogicalKeyboardKey.arrowUp
        ? math.max(0, currentIndex - 1)
        : math.min(objects.length - 1, currentIndex + 1);
    if (HardwareKeyboard.instance.isShiftPressed) {
      widget.controller.selectObjectRange(objects[nextIndex]);
    } else {
      widget.controller.selectObject(objects[nextIndex]);
    }
    return KeyEventResult.handled;
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
      key: ValueKey(
        'fortune-object-row-${object.key.kind.name}-${object.key.id}',
      ),
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
              const Icon(
                Icons.drag_indicator,
                size: 17,
                color: Color(0xff80868b),
              ),
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
  final image = snapshot.activeImage;
  if (image != null) {
    final fields = image.extraFields;
    return '${snapshot.sheetId}|${image.id}|${image.src}|${image.left}|${image.top}|${image.width}|${image.height}|${fields['rotation']}|${fields[fortuneImageObjectIdExtraKey]}|${fields[fortuneBarcodeObjectIdExtraKey]}|${fields['barcodeText']}|${fields['barcodeFormatId']}|${fields['barcodeFormatLabel']}|${fields['barcodeModuleScale']}|${fields['barcodeBarHeight']}|${fields['barcodeLeadingText']}|${fields['barcodeTrailingText']}|${fields['barcodeShowText']}|${fields['barcodeHumanReadableFontFamily']}|${fields['barcodeHumanReadableFontSize']}|${fields['preserveTemplateBarcodeFormat']}';
  }
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
    required this.canMutate,
  });

  final int count;
  final FortuneSheetController controller;
  final bool canMutate;

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
              onPressed: canMutate ? controller.duplicateSelectedObjects : null,
              icon: const Icon(Icons.copy, size: 17),
              label: const Text('복제'),
            ),
            OutlinedButton.icon(
              onPressed: canMutate ? controller.deleteSelectedObjects : null,
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
    required this.imageObjectOptions,
    required this.barcodeObjectOptions,
    required this.imageObjectIds,
    required this.barcodeObjectIds,
    required this.presentation,
    required this.propertyFocusField,
    required this.propertyFocusSheetId,
    required this.propertyFocusObjectKey,
    required this.propertyFocusGeneration,
    required this.barcodeDraft,
    required this.onBarcodeDraftChanged,
    required this.onBarcodeDraftRemoved,
  });

  final FortuneObjectSelectionSnapshot snapshot;
  final FortuneSheetController controller;
  final ScrollController scrollController;
  final List<FortuneObjectConnectionOption> imageObjectOptions;
  final List<FortuneObjectConnectionOption> barcodeObjectOptions;
  final List<String> imageObjectIds;
  final List<String> barcodeObjectIds;
  final FortuneObjectPanelPresentation presentation;
  final String? propertyFocusField;
  final String? propertyFocusSheetId;
  final FortuneSheetObjectKey? propertyFocusObjectKey;
  final int propertyFocusGeneration;
  final _BarcodePropertyDraftState? barcodeDraft;
  final ValueChanged<_BarcodePropertyDraftState> onBarcodeDraftChanged;
  final VoidCallback onBarcodeDraftRemoved;

  @override
  State<_ObjectPropertyEditor> createState() => _ObjectPropertyEditorState();
}

class _ObjectPropertyEditorState extends State<_ObjectPropertyEditor> {
  final Object _draftOwner = Object();
  final Map<String, TextEditingController> _fields = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Map<String, String> _initialFieldText = {};
  FortuneStrokeStyle _strokeStyle = FortuneStrokeStyle.solid;
  bool _noFill = false;
  bool _imageAspectLocked = true;
  double? _imageAspectRatio;
  String? _lastImageSizeField;
  bool _imagePickerPending = false;
  bool _barcodeRenderPending = false;
  bool _barcodeShowText = false;
  bool _barcodePreserveTemplateFormat = false;
  String? _error;
  bool _draftFinalized = false;
  int _consumedFocusGeneration = 0;
  int _scheduledFocusGeneration = 0;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _installFieldListeners();
    _schedulePropertyFocus();
  }

  @override
  void didUpdateWidget(covariant _ObjectPropertyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_propertySnapshotIdentity(oldWidget.snapshot) ==
        _propertySnapshotIdentity(widget.snapshot)) {
      _schedulePropertyFocus();
      return;
    }
    final preserveImageAspect =
        oldWidget.snapshot.activeKey == widget.snapshot.activeKey &&
        oldWidget.snapshot.activeImage != null &&
        widget.snapshot.activeImage != null;
    final imageAspectLocked = _imageAspectLocked;
    final imageAspectRatio = _imageAspectRatio;
    for (final controller in _fields.values) {
      controller.removeListener(_markPropertyDraft);
      controller.dispose();
    }
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.dispose();
    }
    _fieldFocusNodes.clear();
    _fields.clear();
    _initialFieldText.clear();
    _strokeStyle = FortuneStrokeStyle.solid;
    _noFill = false;
    _barcodeRenderPending = false;
    _barcodeShowText = false;
    _barcodePreserveTemplateFormat = false;
    _error = null;
    _initializeFields();
    if (preserveImageAspect) {
      _imageAspectLocked = imageAspectLocked;
      if (imageAspectLocked) {
        _imageAspectRatio = imageAspectRatio;
      }
    }
    _lastImageSizeField = null;
    _draftFinalized = false;
    _installFieldListeners();
    _schedulePropertyFocus();
  }

  void _schedulePropertyFocus() {
    final field = widget.propertyFocusField;
    final generation = widget.propertyFocusGeneration;
    if (field == null ||
        generation <= _consumedFocusGeneration ||
        generation == _scheduledFocusGeneration ||
        widget.presentation == FortuneObjectPanelPresentation.hidden) {
      return;
    }
    _scheduledFocusGeneration = generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scheduledFocusGeneration == generation) {
        _scheduledFocusGeneration = 0;
      }
      if (!mounted ||
          widget.propertyFocusGeneration != generation ||
          widget.presentation == FortuneObjectPanelPresentation.hidden ||
          widget.snapshot.sheetId != widget.propertyFocusSheetId ||
          widget.snapshot.activeKey != widget.propertyFocusObjectKey) {
        return;
      }
      _consumedFocusGeneration = generation;
      _fieldFocusNodes
          .putIfAbsent(
            field,
            () => FocusNode(debugLabel: 'Fortune object property $field'),
          )
          .requestFocus();
    });
  }

  @override
  void dispose() {
    widget.controller.unregisterActiveObjectPropertyDraft(_draftOwner);
    for (final controller in _fields.values) {
      controller.removeListener(_markPropertyDraft);
      controller.dispose();
    }
    for (final focusNode in _fieldFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _installFieldListeners() {
    for (final controller in _fields.values) {
      controller.addListener(_markPropertyDraft);
    }
  }

  void _markPropertyDraft() {
    _draftFinalized = false;
    if (widget.snapshot.activeKey?.kind == FortuneSheetObjectKind.barcode) {
      if (_error != null && mounted) {
        setState(() => _error = null);
      }
      _storeBarcodeDraft(clearError: true);
    }
    widget.controller.registerActiveObjectPropertyDraft(
      owner: _draftOwner,
      key: widget.snapshot.activeKey!,
      finalize: () => _apply(forCommand: true),
      discard: _discardPropertyDraft,
      project: _projectPropertyDraft,
    );
  }

  FortunePropertyDraftProjection _projectPropertyDraft() {
    if (_fieldsMatchInitialText()) {
      return FortunePropertyDraftProjection.noChange;
    }
    final image = widget.snapshot.activeImage;
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    if (image != null) {
      final left = _number('left', geometry: true);
      final top = _number('top', geometry: true);
      var width = _number('width', geometry: true);
      var height = _number('height', geometry: true);
      final rotation = _number('rotation');
      if ([left, top, width, height, rotation].contains(null)) {
        return FortunePropertyDraftProjection.invalid;
      }
      final aspectRatio = _imageAspectRatio;
      if (_imageAspectLocked && aspectRatio != null) {
        if (_lastImageSizeField == 'width') {
          height = width! / aspectRatio;
        } else if (_lastImageSizeField == 'height') {
          width = height! * aspectRatio;
        }
      }
      final connectionId = _fields['connectionId']?.text.trim() ?? '';
      if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.barcode) {
        return FortunePropertyDraftProjection.invalid;
      }
      if (connectionId.isEmpty &&
          image.extraFields[fortuneImageObjectIdExtraKey]
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true) {
        return FortunePropertyDraftProjection.invalid;
      }
      return widget.controller.wouldUpdateSelectedImage(
            left: left,
            top: top,
            width: width,
            height: height,
            rotationDegrees: rotation,
            connectionId: connectionId,
          )
          ? FortunePropertyDraftProjection.change
          : FortunePropertyDraftProjection.noChange;
    }

    final strokeWidth = _number('strokeWidth');
    final strokeColor = _fields['strokeColor']?.text.trim();
    if (strokeWidth == null || strokeColor == null) {
      return FortunePropertyDraftProjection.invalid;
    }
    if (line != null) {
      final x1 = _number('x1', geometry: true);
      final y1 = _number('y1', geometry: true);
      final x2 = _number('x2', geometry: true);
      final y2 = _number('y2', geometry: true);
      if ([x1, y1, x2, y2].contains(null)) {
        return FortunePropertyDraftProjection.invalid;
      }
      return widget.controller.wouldUpdateSelectedLine(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            strokeStyle: _strokeStyle,
            strokeWidthMm: strokeWidth,
            strokeColor: strokeColor,
          )
          ? FortunePropertyDraftProjection.change
          : FortunePropertyDraftProjection.noChange;
    }
    if (shape != null) {
      final left = _number('left', geometry: true);
      final top = _number('top', geometry: true);
      final width = _number('width', geometry: true);
      final height = _number('height', geometry: true);
      final rotation = _number('rotation');
      final radius = shape.kind == FortuneShapeKind.roundedRectangle
          ? _number('cornerRadius')
          : 0.0;
      if ([left, top, width, height, rotation, radius].contains(null)) {
        return FortunePropertyDraftProjection.invalid;
      }
      return widget.controller.wouldUpdateSelectedShape(
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
          )
          ? FortunePropertyDraftProjection.change
          : FortunePropertyDraftProjection.noChange;
    }
    return FortunePropertyDraftProjection.invalid;
  }

  void _completePropertyDraft() {
    _draftFinalized = true;
    widget.controller.unregisterActiveObjectPropertyDraft(_draftOwner);
  }

  void _discardPropertyDraft() {
    _draftFinalized = true;
    for (final controller in _fields.values) {
      controller.removeListener(_markPropertyDraft);
      controller.dispose();
    }
    _fields.clear();
    _initialFieldText.clear();
    widget.onBarcodeDraftRemoved();
    _initializeFields();
    _installFieldListeners();
    if (mounted) setState(() => _error = null);
  }

  void _initializeFields() {
    final image = widget.snapshot.activeImage;
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    if (image != null) {
      if (image.width.isFinite &&
          image.height.isFinite &&
          image.width > 0 &&
          image.height > 0) {
        _imageAspectRatio = image.width / image.height;
      }
      _setGeometryField('left', image.left);
      _setGeometryField('top', image.top);
      _setGeometryField('width', image.width);
      _setGeometryField('height', image.height);
      _setField('rotation', _imageRotation(image));
      final metadataKey =
          widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.barcode
          ? fortuneBarcodeObjectIdExtraKey
          : fortuneImageObjectIdExtraKey;
      _setField('connectionId', image.extraFields[metadataKey] ?? '');
      if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.barcode) {
        final extra = image.extraFields;
        _setField('barcodeText', extra['barcodeText'] ?? '');
        _setField('barcodeFormatId', extra['barcodeFormatId'] ?? '');
        _setField('moduleScale', extra['barcodeModuleScale'] ?? 3.0);
        _setField('barHeight', extra['barcodeBarHeight'] ?? 10.0);
        _setField('leadingText', extra['barcodeLeadingText'] ?? '');
        _setField('trailingText', extra['barcodeTrailingText'] ?? '');
        _setField('fontFamily', extra['barcodeHumanReadableFontFamily'] ?? '');
        _setField('fontSize', extra['barcodeHumanReadableFontSize'] ?? 14.0);
        _barcodeShowText = extra['barcodeShowText'] == true;
        _barcodePreserveTemplateFormat =
            extra['preserveTemplateBarcodeFormat'] == true;
        final draft = widget.barcodeDraft;
        if (draft != null) {
          for (final entry in draft.fields.entries) {
            final controller = _fields[entry.key];
            if (controller != null) {
              controller.text = entry.value;
            }
          }
          _barcodeShowText = draft.showText;
          _barcodePreserveTemplateFormat = draft.preserveTemplateFormat;
          _barcodeRenderPending = draft.pending;
          _error = draft.error;
        }
      }
    } else if (line != null) {
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
    final text = value is double ? _formatNumber(value) : '$value';
    _initialFieldText[name] = text;
    _fields[name] = TextEditingController(text: text);
  }

  bool _fieldsMatchInitialText() => _fields.entries.every(
    (entry) => _initialFieldText[entry.key] == entry.value.text,
  );

  double? _number(String name, {bool geometry = false}) {
    final value = double.tryParse(_fields[name]?.text.trim() ?? '');
    if (value == null || !value.isFinite) {
      return null;
    }
    return geometry && widget.snapshot.geometryUsesMillimeters
        ? fortuneMillimetersToLogicalPixels(value)
        : value;
  }

  bool _apply({bool forCommand = false}) {
    if (_draftFinalized && !forCommand) return false;
    if (_fieldsMatchInitialText()) {
      _completePropertyDraft();
      return true;
    }
    final image = widget.snapshot.activeImage;
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    if (image != null) {
      final left = _number('left', geometry: true);
      final top = _number('top', geometry: true);
      var width = _number('width', geometry: true);
      var height = _number('height', geometry: true);
      final rotation = _number('rotation');
      if ([left, top, width, height, rotation].contains(null)) {
        setState(() => _error = '유효한 이미지 값을 입력하세요.');
        return false;
      }
      final aspectRatio = _imageAspectRatio;
      if (_imageAspectLocked && aspectRatio != null) {
        if (_lastImageSizeField == 'width') {
          height = width! / aspectRatio;
        } else if (_lastImageSizeField == 'height') {
          width = height! * aspectRatio;
        }
      }
      final connectionId = _fields['connectionId']?.text.trim() ?? '';
      if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.image &&
          connectionId.isEmpty &&
          image.extraFields[fortuneImageObjectIdExtraKey]
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true) {
        setState(() => _error = '연결을 해제하려면 이미지 파일을 선택하세요.');
        return false;
      }
      if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.barcode) {
        final moduleScale = _number('moduleScale');
        final barHeight = _number('barHeight');
        final fontSize = _number('fontSize');
        final text = _fields['barcodeText']?.text ?? '';
        final formatId = _fields['barcodeFormatId']?.text ?? '';
        if (moduleScale == null ||
            barHeight == null ||
            fontSize == null ||
            text.trim().isEmpty ||
            formatId.trim().isEmpty) {
          setState(() => _error = '바코드 입력값을 확인하세요.');
          return false;
        }
        if (forCommand) return false;
        _renderBarcode(
          text: text,
          formatId: formatId,
          left: left!,
          top: top!,
          width: width!,
          height: height!,
          rotation: rotation!,
          moduleScale: moduleScale,
          barHeight: barHeight,
          fontSize: fontSize,
          connectionId: connectionId,
        );
        _completePropertyDraft();
        return true;
      }
      widget.controller.updateSelectedImage(
        left: left,
        top: top,
        width: width,
        height: height,
        rotationDegrees: rotation,
        connectionId: connectionId,
      );
      setState(() => _error = null);
      _completePropertyDraft();
      return true;
    }
    final strokeWidth = _number('strokeWidth');
    final strokeColor = _fields['strokeColor']?.text.trim();
    if (strokeWidth == null || strokeColor == null) {
      setState(() => _error = '유효한 숫자와 색상을 입력하세요.');
      return false;
    }
    if (line != null) {
      final x1 = _number('x1', geometry: true);
      final y1 = _number('y1', geometry: true);
      final x2 = _number('x2', geometry: true);
      final y2 = _number('y2', geometry: true);
      if ([x1, y1, x2, y2].contains(null)) {
        setState(() => _error = '유효한 좌표를 입력하세요.');
        return false;
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
        return false;
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
    _completePropertyDraft();
    return true;
  }

  Future<void> _renderBarcode({
    required String text,
    required String formatId,
    required double left,
    required double top,
    required double width,
    required double height,
    required double rotation,
    required double moduleScale,
    required double barHeight,
    required double fontSize,
    required String connectionId,
  }) async {
    if (_barcodeRenderPending) {
      return;
    }
    setState(() {
      _barcodeRenderPending = true;
      _error = null;
    });
    final requestDraft = _barcodeDraftState(
      pending: true,
      clearError: true,
    );
    final onDraftChanged = widget.onBarcodeDraftChanged;
    final onDraftRemoved = widget.onBarcodeDraftRemoved;
    onDraftChanged(requestDraft);
    final outcome = await widget.controller.renderSelectedBarcodeOutcome(
      text: text,
      formatId: formatId,
      left: left,
      top: top,
      width: width,
      height: height,
      rotationDegrees: rotation,
      moduleScale: moduleScale,
      barHeight: barHeight,
      leadingText: _fields['leadingText']?.text ?? '',
      trailingText: _fields['trailingText']?.text ?? '',
      showHumanReadableText: _barcodeShowText,
      humanReadableFontFamily:
          _fields['fontFamily']?.text.trim().isNotEmpty == true
          ? _fields['fontFamily']!.text.trim()
          : null,
      humanReadableFontSize: fontSize,
      connectionId: connectionId,
      preserveTemplateFormat: _barcodePreserveTemplateFormat,
    );
    if (outcome == FortuneBarcodePropertyRenderOutcome.success) {
      onDraftRemoved();
    } else if (outcome == FortuneBarcodePropertyRenderOutcome.failure) {
      onDraftChanged(
        requestDraft.copyWith(
          pending: false,
          error: '바코드를 생성하지 못했습니다.',
        ),
      );
    }
    if (mounted) {
      setState(() {
        _barcodeRenderPending = false;
        if (outcome != FortuneBarcodePropertyRenderOutcome.stale) {
          _error = outcome == FortuneBarcodePropertyRenderOutcome.success
              ? null
              : '바코드를 생성하지 못했습니다.';
        }
      });
    }
  }

  void _storeBarcodeDraft({
    bool? pending,
    String? error,
    bool clearError = false,
  }) {
    if (widget.snapshot.activeKey?.kind != FortuneSheetObjectKind.barcode) {
      return;
    }
    widget.onBarcodeDraftChanged(
      _barcodeDraftState(
        pending: pending,
        error: error,
        clearError: clearError,
      ),
    );
  }

  _BarcodePropertyDraftState _barcodeDraftState({
    bool? pending,
    String? error,
    bool clearError = false,
  }) {
    return _BarcodePropertyDraftState(
      fields: {
        for (final entry in _fields.entries) entry.key: entry.value.text,
      },
      showText: _barcodeShowText,
      preserveTemplateFormat: _barcodePreserveTemplateFormat,
      pending: pending ?? _barcodeRenderPending,
      error: clearError ? null : error ?? _error,
    );
  }

  Future<void> _replaceImageFile() async {
    if (_imagePickerPending) {
      return;
    }
    setState(() {
      _imagePickerPending = true;
      _error = null;
    });
    await widget.controller.replaceSelectedImageFile();
    if (mounted) {
      setState(() {
        _imagePickerPending = false;
        _error = widget.controller.activeImagePickerFailed
            ? '이미지를 불러오지 못했습니다.'
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.snapshot.activeImage;
    final line = widget.snapshot.activeLine;
    final shape = widget.snapshot.activeShape;
    final canMutate = widget.controller.objectMutationEnabled;
    if (image == null && line == null && shape == null) {
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
    if (image != null) {
      fields.addAll([
        _connectionField(),
        _field('X', 'left', suffix: unit),
        _field('Y', 'top', suffix: unit),
        _field(
          '폭',
          'width',
          suffix: unit,
          onChanged: (_) => _lastImageSizeField = 'width',
        ),
        _field(
          '높이',
          'height',
          suffix: unit,
          onChanged: (_) => _lastImageSizeField = 'height',
        ),
        if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.image)
          CheckboxListTile(
            key: const ValueKey('fortune-object-property-aspect-lock'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('비율 유지', style: TextStyle(fontSize: 13)),
            value: _imageAspectLocked,
            onChanged: canMutate
                ? (value) {
                    setState(() => _imageAspectLocked = value ?? true);
                  }
                : null,
          ),
        if (widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.image)
          OutlinedButton.icon(
            key: const ValueKey('fortune-object-property-replace-file'),
            onPressed: _imagePickerPending || !canMutate
                ? null
                : _replaceImageFile,
            icon: _imagePickerPending
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open, size: 17),
            label: const Text('파일 교체'),
          ),
        _field('회전', 'rotation', suffix: '°'),
        if (widget.snapshot.activeKey!.kind ==
            FortuneSheetObjectKind.barcode) ...[
          _field('형식', 'barcodeFormatId'),
          _field('데이터', 'barcodeText'),
          _field('모듈 배율', 'moduleScale'),
          _field('바 높이', 'barHeight'),
          _field('앞쪽 텍스트', 'leadingText'),
          _field('뒤쪽 텍스트', 'trailingText'),
          CheckboxListTile(
            key: const ValueKey('fortune-object-property-barcode-show-text'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('사람이 읽는 텍스트 표시', style: TextStyle(fontSize: 13)),
            value: _barcodeShowText,
            onChanged: canMutate
                ? (value) {
                    setState(() => _barcodeShowText = value ?? false);
                    _markPropertyDraft();
                  }
                : null,
          ),
          _field('텍스트 글꼴', 'fontFamily'),
          _field('텍스트 크기', 'fontSize'),
          CheckboxListTile(
            key: const ValueKey(
              'fortune-object-property-barcode-preserve-template',
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('템플릿 바코드 형식 유지', style: TextStyle(fontSize: 13)),
            value: _barcodePreserveTemplateFormat,
            onChanged: canMutate
                ? (value) {
                    setState(() {
                      _barcodePreserveTemplateFormat = value ?? false;
                    });
                    _markPropertyDraft();
                  }
                : null,
          ),
        ],
      ]);
    } else if (line != null) {
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
          value: switch (_lineAngle(line)) {
            final angle? => '${_formatNumber(angle)}°',
            null => '-',
          },
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
    if (image == null) {
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
          onChanged: canMutate
              ? (value) {
                  if (value != null) {
                    setState(() => _strokeStyle = value);
                    _markPropertyDraft();
                  }
                }
              : null,
        ),
        _field('테두리 폭', 'strokeWidth', suffix: 'mm'),
        _field('테두리 색상', 'strokeColor'),
      ]);
    }
    if (shape != null) {
      fields.addAll([
        CheckboxListTile(
          key: const ValueKey('fortune-object-property-no-fill'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('채우기 없음', style: TextStyle(fontSize: 13)),
          value: _noFill,
          onChanged: canMutate
              ? (value) {
                  setState(() => _noFill = value ?? false);
                  _markPropertyDraft();
                }
              : null,
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
        onPressed:
            _barcodeRenderPending || !widget.controller.objectMutationEnabled
            ? null
            : _apply,
        child: _barcodeRenderPending
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('적용'),
      ),
    ]);
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(12),
      children: fields,
    );
  }

  Widget _field(
    String label,
    String name, {
    String? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      key: ValueKey('fortune-object-property-$name'),
      controller: _fields[name],
      focusNode: _fieldFocusNodes.putIfAbsent(
        name,
        () => FocusNode(debugLabel: 'Fortune object property $name'),
      ),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      style: const TextStyle(fontSize: 13),
      readOnly: !widget.controller.objectMutationEnabled,
      onChanged: onChanged,
      onSubmitted: widget.controller.objectMutationEnabled
          ? (_) => _apply()
          : null,
    );
  }

  Widget _connectionField() {
    final barcode =
        widget.snapshot.activeKey!.kind == FortuneSheetObjectKind.barcode;
    final current = _fields['connectionId']!.text.trim();
    final choices = fortuneObjectConnectionChoices(
      options: barcode
          ? widget.barcodeObjectOptions
          : widget.imageObjectOptions,
      legacyIds: barcode ? widget.barcodeObjectIds : widget.imageObjectIds,
      currentValue: current,
    );
    return DropdownButtonFormField<String>(
      key: const ValueKey('fortune-object-property-connectionId'),
      focusNode: _fieldFocusNodes.putIfAbsent(
        'connectionId',
        () => FocusNode(debugLabel: 'Fortune object property connectionId'),
      ),
      initialValue: current,
      decoration: const InputDecoration(labelText: '연결 ID'),
      items: choices
          .map(
            (choice) => DropdownMenuItem<String>(
              value: choice.value,
              child: Text(
                choice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: widget.controller.objectMutationEnabled
          ? (value) {
              _fields['connectionId']!.text = value ?? '';
              setState(() => _error = null);
            }
          : null,
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

  double? _lineAngle(FortuneLine line) {
    if (line.x1 == line.x2 && line.y1 == line.y2) {
      return null;
    }
    final degrees =
        math.atan2(line.y2 - line.y1, line.x2 - line.x1) * 180 / math.pi;
    return degrees < 0 ? degrees + 360 : degrees;
  }

  double _imageRotation(FortuneImage image) {
    final raw = image.extraFields['rotation'];
    final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
    return value != null && value.isFinite ? value : 0;
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
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
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
