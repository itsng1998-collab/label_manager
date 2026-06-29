import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:label_manager/utils/log_context.dart';

typedef PreviewFloatingRectChanged =
    void Function(Rect rect, {required bool isResizing});

/// Floating preview window.
/// Show/hide via [show] and [hide]. Call [dispose] from the owner.
class PreviewFloatingWindow {
  PreviewFloatingWindow({
    this.initialPosition = const Offset(300, 220),
    this.initialSize = const Size(400, 300),
    this.minSize = const Size(80, 60),
    String? tooltip,
    Widget? child,
    this.onRectChanged,
    this.onResizeCompleted,
    this.onCloseRequested,
  }) : _rect = ValueNotifier<Rect>(
         Rect.fromLTWH(
           initialPosition.dx,
           initialPosition.dy,
           initialSize.width,
           initialSize.height,
         ),
       ),
       _child = ValueNotifier<Widget?>(child),
       _tooltip = ValueNotifier<String?>(tooltip),
      _isResizing = ValueNotifier<bool>(false),
      _controlsVisible = ValueNotifier<bool>(true);

  final Offset initialPosition;
  final Size initialSize;
  final Size minSize;
  final PreviewFloatingRectChanged? onRectChanged;
  final ValueChanged<Rect>? onResizeCompleted;
  final VoidCallback? onCloseRequested;

  final ValueNotifier<Rect> _rect;
  final ValueNotifier<Widget?> _child;
  final ValueNotifier<String?> _tooltip;
  final ValueNotifier<bool> _isResizing;
  final ValueNotifier<bool> _controlsVisible;
  final ValueNotifier<bool> _visible = ValueNotifier<bool>(true);
  _PreviewFloatingRoute? _route;
  bool _positionInitialized = false;
  bool get isVisible => _route != null && _visible.value;
  Rect get rect => _rect.value;

  static String _formatOffset(Offset value) =>
      '${value.dx.toStringAsFixed(1)},${value.dy.toStringAsFixed(1)}';

  static String _formatSize(Size value) =>
      '${value.width.toStringAsFixed(1)}x${value.height.toStringAsFixed(1)}';

  static String _formatRect(Rect value) =>
      'l=${value.left.toStringAsFixed(1)} t=${value.top.toStringAsFixed(1)} '
      'w=${value.width.toStringAsFixed(1)} h=${value.height.toStringAsFixed(1)}';
  int? get debugRouteId => _route?.debugId;

  static void _log(String message) {
    debugLog(message, skipFrames: 1);
  }

  OverlayEntry _createEntry() {
    _log('create overlay entry routeId=${_route?.debugId ?? 'pending'}');
    return OverlayEntry(
      builder: (ctx) {
        _log(
          'build overlay entry routeId=${_route?.debugId ?? 'pending'} '
          'rect=${_formatRect(_rect.value)}',
        );
        return ValueListenableBuilder<bool>(
          valueListenable: _visible,
          builder: (context, visible, _) {
            return ValueListenableBuilder<Rect>(
              valueListenable: _rect,
              builder: (context, rect, _) {
                return Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: Offstage(
                    offstage: !visible,
                    child: IgnorePointer(
                      ignoring: !visible,
                      child: _FloatingCard(
                        rect: rect,
                        minSize: minSize,
                        childListenable: _child,
                        tooltipListenable: _tooltip,
                        isResizingListenable: _isResizing,
                        controlsVisibleListenable: _controlsVisible,
                        onMove: _updatePosition,
                        onResize: _updateRect,
                        onResizeStart: _handleResizeStart,
                        onResizeEnd: _handleResizeEnd,
                        onClose: _handleCloseRequested,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void show(BuildContext context, {Widget? child}) {
    if (child != null) {
      _child.value = child;
    }
    if (_route != null) {
      if (!_visible.value) {
        _controlsVisible.value = true;
        _visible.value = true;
        _route?.markNeedsBuild();
      }
      _log('show ignored existingRouteId=${_route!.debugId}');
      return;
    }
    if (!_positionInitialized) {
      final size = MediaQuery.of(context).size;
      final rect = _rect.value;
      const double margin = 24;
      final availableWidth = max(minSize.width, size.width - margin * 2);
      final availableHeight = max(minSize.height, size.height - margin * 2);
      final width = min(rect.width, availableWidth);
      final height = min(rect.height, availableHeight);
      final dx = max(0.0, (size.width - width) / 2);
      final dy = max(0.0, (size.height - height) / 2);
      _rect.value = Rect.fromLTWH(dx, dy, width, height);
      _positionInitialized = true;
    }
    _log(
      'show requested rect=${_formatRect(_rect.value)} '
      'tooltip=${_tooltip.value != null}',
    );
    _controlsVisible.value = true;
    final route = _PreviewFloatingRoute(
      createEntry: _createEntry,
      onLog: _log,
    );
    _route = route;
    _log('push routeId=${route.debugId} rootNavigator=1');
    unawaited(route.popped.then((_) {
      _log('popped routeId=${route.debugId} stillCurrent=${identical(_route, route)}');
      if (identical(_route, route)) {
        _route = null;
      }
    }));
    Navigator.of(context, rootNavigator: true).push(route);
  }

  void keepBelowRoutePopups(BuildContext context) {
    _log(
      'keepBelowRoutePopups routeId=${_route?.debugId ?? 'none'} '
      'visible=$isVisible',
    );
    _route?.markNeedsBuild();
  }

  void hide() {
    final route = _route;
    if (route == null) {
      return;
    }
    _log('hide routeId=${route.debugId} rect=${_formatRect(_rect.value)}');
    _visible.value = false;
    route.markNeedsBuild();
  }

  Future<void> hideToRect(Rect targetRect) async {
    final route = _route;
    if (route == null || !_visible.value) {
      hide();
      return;
    }
    final original = _rect.value;
    _log(
      'hideToRect routeId=${route.debugId} '
      'from=${_formatRect(original)} to=${_formatRect(targetRect)}',
    );
    _controlsVisible.value = false;
    route.markNeedsBuild();
    const steps = 12;
    const duration = Duration(milliseconds: 180);
    final stepDuration = Duration(
      microseconds: duration.inMicroseconds ~/ steps,
    );
    for (var i = 1; i <= steps; i++) {
      if (!_visible.value) break;
      final t = Curves.easeInOutCubic.transform(i / steps);
      _rect.value = Rect.lerp(original, targetRect, t)!;
      route.markNeedsBuild();
      await Future<void>.delayed(stepDuration);
    }
    _visible.value = false;
    _rect.value = original;
    _controlsVisible.value = true;
    route.markNeedsBuild();
  }

  void _handleCloseRequested() {
    if (onCloseRequested != null) {
      onCloseRequested!();
      return;
    }
    hide();
  }

  void _removeRoute() {
    final route = _route;
    if (route == null) {
      return;
    }
    _route = null;
    final navigator = route.navigator;
    if (navigator != null) {
      _log('remove routeId=${route.debugId} navigatorAttached=1');
      navigator.removeRoute(route);
    } else {
      _log('remove skipped routeId=${route.debugId} navigatorAttached=0');
    }
  }

  void dispose() {
    _removeRoute();
    _rect.dispose();
    _child.dispose();
    _tooltip.dispose();
    _isResizing.dispose();
    _controlsVisible.dispose();
    _visible.dispose();
  }

  void setChild(Widget? child) {
    _child.value = child;
    _log('setChild routeId=${_route?.debugId ?? 'none'} hasChild=${child != null}');
    _route?.markNeedsBuild();
  }

  void setTooltip(String? tooltip) {
    _tooltip.value = tooltip;
    _log('setTooltip enabled=${tooltip?.trim().isNotEmpty == true}');
    _route?.markNeedsBuild();
  }

  void setSize(BuildContext context, Size size, {bool center = false}) {
    final overlaySize = MediaQuery.of(context).size;
    const double margin = 24;
    final width = min(
      max(size.width, minSize.width),
      overlaySize.width - margin * 2,
    );
    final height = min(
      max(size.height, minSize.height),
      overlaySize.height - margin * 2,
    );
    final current = _rect.value;
    final left = center
        ? max(0.0, (overlaySize.width - width) / 2)
        : min(max(0.0, current.left), max(0.0, overlaySize.width - width));
    final top = center
        ? max(0.0, (overlaySize.height - height) / 2)
        : min(max(0.0, current.top), max(0.0, overlaySize.height - height));
    _log(
      'setSize requested=${_formatSize(size)} overlay=${_formatSize(overlaySize)} '
      'center=$center current=${_formatRect(current)} '
      'applied=${_formatRect(Rect.fromLTWH(left, top, width, height))}',
    );
    _rect.value = Rect.fromLTWH(left, top, width, height);
    _positionInitialized = true;
    _notifyRectChanged(isResizing: false);
  }

  void alignBottomRightTo(BuildContext context, Offset bottomRight) {
    final overlaySize = MediaQuery.of(context).size;
    final current = _rect.value;
    final left = min(
      max(0.0, bottomRight.dx - current.width),
      max(0.0, overlaySize.width - current.width),
    );
    final top = min(
      max(0.0, bottomRight.dy - current.height),
      max(0.0, overlaySize.height - current.height),
    );
    final next = Rect.fromLTWH(left, top, current.width, current.height);
    _log(
      'alignBottomRight target=${_formatOffset(bottomRight)} '
      'overlay=${_formatSize(overlaySize)} applied=${_formatRect(next)}',
    );
    _rect.value = next;
    _positionInitialized = true;
    _notifyRectChanged(isResizing: false);
  }

  void _updatePosition(Offset delta) {
    if (_isResizing.value) {
      return;
    }
    _rect.value = _rect.value.shift(delta);
    _notifyRectChanged(isResizing: false);
  }

  void _handleResizeStart(String handleName, int pointer) {
    _log(
      'resize state=start handle=$handleName pointer=$pointer '
      'rect=${_formatRect(_rect.value)}',
    );
    _isResizing.value = true;
  }

  void _handleResizeEnd(String handleName, int pointer) {
    _log(
      'resize state=end handle=$handleName pointer=$pointer '
      'rect=${_formatRect(_rect.value)}',
    );
    _isResizing.value = false;
    _notifyRectChanged(isResizing: false);
    onResizeCompleted?.call(_rect.value);
  }

  void _updateRect(Rect next) {
    final width = max(next.width, minSize.width);
    final height = max(next.height, minSize.height);
    final applied = Rect.fromLTWH(next.left, next.top, width, height);
    _rect.value = applied;
    _notifyRectChanged(isResizing: true);
  }

  void _notifyRectChanged({required bool isResizing}) {
    onRectChanged?.call(_rect.value, isResizing: isResizing);
  }
}

class _PreviewFloatingRoute extends OverlayRoute<void> {
  _PreviewFloatingRoute({required this.createEntry, required this.onLog})
    : debugId = _nextDebugId++;

  static int _nextDebugId = 1;

  final OverlayEntry Function() createEntry;
  final ValueChanged<String> onLog;
  final int debugId;
  final List<OverlayEntry> _entries = <OverlayEntry>[];

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    onLog('route createOverlayEntries routeId=$debugId');
    final entry = createEntry();
    _entries.add(entry);
    onLog('route overlayEntries routeId=$debugId count=${_entries.length}');
    return _entries;
  }

  void markNeedsBuild() {
    onLog('route markNeedsBuild routeId=$debugId entries=${_entries.length}');
    for (final entry in _entries) {
      entry.markNeedsBuild();
    }
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.rect,
    required this.minSize,
    required this.childListenable,
    required this.tooltipListenable,
    required this.isResizingListenable,
    required this.controlsVisibleListenable,
    required this.onMove,
    required this.onResize,
    required this.onResizeStart,
    required this.onResizeEnd,
    required this.onClose,
  });

  final Rect rect;
  final Size minSize;
  final ValueListenable<Widget?> childListenable;
  final ValueListenable<String?> tooltipListenable;
  final ValueListenable<bool> isResizingListenable;
  final ValueListenable<bool> controlsVisibleListenable;
  final ValueChanged<Offset> onMove;
  final ValueChanged<Rect> onResize;
  final void Function(String handleName, int pointer) onResizeStart;
  final void Function(String handleName, int pointer) onResizeEnd;
  final VoidCallback onClose;

  static const double _handleSize = 16;
  static const double _cornerHandleSize = 44;
  static const double _edgeThickness = 10;

  @override
  Widget build(BuildContext context) {
    return _FloatingTooltipRegion(
      tooltipListenable: tooltipListenable,
      isResizingListenable: isResizingListenable,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ValueListenableBuilder<Widget?>(
                  valueListenable: childListenable,
                  builder: (context, child, _) {
                    return child ?? const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
          // Edge resize handles stay below the move handle.
          ..._buildEdgeResizeHandles(),
          ValueListenableBuilder<bool>(
            valueListenable: controlsVisibleListenable,
            builder: (context, controlsVisible, _) {
              if (!controlsVisible) return const SizedBox.shrink();
              return ValueListenableBuilder<bool>(
                valueListenable: isResizingListenable,
                builder: (context, isResizing, _) {
                  if (isResizing) return const SizedBox.shrink();
                  return Positioned(
                    top: -1,
                    left: (rect.width - 70) / 2,
                    child: _MoveHandle(
                      key: const ValueKey('floating-move-handle'),
                      isResizingListenable: isResizingListenable,
                      onMove: onMove,
                      onClose: onClose,
                    ),
                  );
                },
              );
            },
          ),
          // Corner resize handles stay above the move handle.
          ..._buildCornerResizeHandles(),
        ],
      ),
    );
  }

  List<Widget> _buildCornerResizeHandles() {
    return [
      _ResizeHandle(
        key: const ValueKey('floating-resize-top-left'),
        name: 'top-left',
        rect: rect,
        computeRect: (base, delta) =>
            _buildProportionalCornerRect(base, delta, left: true, top: true),
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        left: 0,
        top: 0,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
        size: _cornerHandleSize,
        showHoverIndicator: true,
        hideIndicatorListenable: isResizingListenable,
      ),
      _ResizeHandle(
        key: const ValueKey('floating-resize-top-right'),
        name: 'top-right',
        rect: rect,
        computeRect: (base, delta) =>
            _buildProportionalCornerRect(base, delta, right: true, top: true),
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        right: 0,
        top: 0,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
        size: _cornerHandleSize,
        showHoverIndicator: true,
        hideIndicatorListenable: isResizingListenable,
      ),
      _ResizeHandle(
        key: const ValueKey('floating-resize-bottom-left'),
        name: 'bottom-left',
        rect: rect,
        computeRect: (base, delta) =>
            _buildProportionalCornerRect(base, delta, left: true, bottom: true),
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        left: 0,
        bottom: 0,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
        size: _cornerHandleSize,
        showHoverIndicator: true,
        hideIndicatorListenable: isResizingListenable,
      ),
      _ResizeHandle(
        key: const ValueKey('floating-resize-bottom-right'),
        name: 'bottom-right',
        rect: rect,
        computeRect: (base, delta) => _buildProportionalCornerRect(
          base,
          delta,
          right: true,
          bottom: true,
        ),
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        right: 0,
        bottom: 0,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
        size: _cornerHandleSize,
        showHoverIndicator: true,
        hideIndicatorListenable: isResizingListenable,
      ),
    ];
  }

  List<Widget> _buildEdgeResizeHandles() {
    return [
      _ResizeHandle(
        name: 'top-edge',
        rect: rect,
        computeRect: (base, delta) => _buildRectFromDeltas(base, top: delta.dy),
        cursor: SystemMouseCursors.resizeUpDown,
        left: _cornerHandleSize,
        right: _cornerHandleSize,
        top: 0,
        size: _edgeThickness,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
      _ResizeHandle(
        name: 'bottom-edge',
        rect: rect,
        computeRect: (base, delta) =>
            _buildRectFromDeltas(base, bottom: delta.dy),
        cursor: SystemMouseCursors.resizeUpDown,
        left: _cornerHandleSize,
        right: _cornerHandleSize,
        bottom: 0,
        size: _edgeThickness,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
      _ResizeHandle(
        name: 'left-edge',
        rect: rect,
        computeRect: (base, delta) =>
            _buildRectFromDeltas(base, left: delta.dx),
        cursor: SystemMouseCursors.resizeLeftRight,
        left: 0,
        top: _cornerHandleSize,
        bottom: _cornerHandleSize,
        size: _edgeThickness,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
      _ResizeHandle(
        name: 'right-edge',
        rect: rect,
        computeRect: (base, delta) =>
            _buildRectFromDeltas(base, right: delta.dx),
        cursor: SystemMouseCursors.resizeLeftRight,
        right: 0,
        top: _cornerHandleSize,
        bottom: _cornerHandleSize,
        size: _edgeThickness,
        onResize: onResize,
        onResizeStart: onResizeStart,
        onResizeEnd: onResizeEnd,
      ),
    ];
  }

  Rect _buildRectFromDeltas(
    Rect base, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final widthDelta = right != 0 ? right : -left;
    final heightDelta = bottom != 0 ? bottom : -top;
    final width = max(base.width + widthDelta, minSize.width);
    final height = max(base.height + heightDelta, minSize.height);

    return Rect.fromLTWH(base.left, base.top, width, height);
  }

  Rect _buildProportionalCornerRect(
    Rect base,
    Offset delta, {
    bool left = false,
    bool top = false,
    bool right = false,
    bool bottom = false,
  }) {
    final horizontalDelta = left ? -delta.dx : delta.dx;
    final verticalDelta = top ? -delta.dy : delta.dy;
    final scaleX = (base.width + horizontalDelta) / base.width;
    final scaleY = (base.height + verticalDelta) / base.height;
    final dominantScale = scaleX >= 1 || scaleY >= 1
        ? max(scaleX, scaleY)
        : min(scaleX, scaleY);
    final minScale = max(
      minSize.width / base.width,
      minSize.height / base.height,
    );
    final scale = max(dominantScale, minScale);
    final width = base.width * scale;
    final height = base.height * scale;

    return Rect.fromLTWH(base.left, base.top, width, height);
  }
}

class _FloatingCloseButton extends StatefulWidget {
  const _FloatingCloseButton({
    required this.onPressed,
    required this.onHoverChanged,
  });

  final VoidCallback onPressed;
  final ValueChanged<bool> onHoverChanged;

  @override
  State<_FloatingCloseButton> createState() => _FloatingCloseButtonState();
}

class _FloatingCloseButtonState extends State<_FloatingCloseButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  void dispose() {
    widget.onHoverChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _pressed
        ? const Color(0xFF9AA0A6)
        : _hovered
        ? const Color(0xFFDADCE0)
        : Colors.transparent;
    final iconColor = _pressed
        ? const Color(0xFF202124)
        : _hovered
        ? const Color(0xFF3C4043)
        : const Color(0xFF5F6368);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: true,
      onEnter: (_) {
        widget.onHoverChanged(true);
        setState(() => _hovered = true);
      },
      onExit: (_) {
        widget.onHoverChanged(false);
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          widget.onHoverChanged(false);
          widget.onPressed();
        },
        child: SizedBox(
          width: 20,
          height: 14,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 16,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.close, size: 11, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _FloatingTooltipRegion extends StatefulWidget {
  const _FloatingTooltipRegion({
    required this.tooltipListenable,
    required this.isResizingListenable,
    required this.child,
  });

  final ValueListenable<String?> tooltipListenable;
  final ValueListenable<bool> isResizingListenable;
  final Widget child;

  @override
  State<_FloatingTooltipRegion> createState() => _FloatingTooltipRegionState();
}

class _FloatingTooltipRegionState extends State<_FloatingTooltipRegion> {
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _visible = false;
  Offset _tooltipPosition = const Offset(10, 18);

  @override
  void initState() {
    super.initState();
    widget.tooltipListenable.addListener(_handleTooltipChanged);
    widget.isResizingListenable.addListener(_handleResizeChanged);
  }

  @override
  void didUpdateWidget(covariant _FloatingTooltipRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tooltipListenable != widget.tooltipListenable) {
      oldWidget.tooltipListenable.removeListener(_handleTooltipChanged);
      widget.tooltipListenable.addListener(_handleTooltipChanged);
      _handleTooltipChanged();
    }
    if (oldWidget.isResizingListenable != widget.isResizingListenable) {
      oldWidget.isResizingListenable.removeListener(_handleResizeChanged);
      widget.isResizingListenable.addListener(_handleResizeChanged);
      _handleResizeChanged();
    }
  }

  @override
  void dispose() {
    widget.tooltipListenable.removeListener(_handleTooltipChanged);
    widget.isResizingListenable.removeListener(_handleResizeChanged);
    _cancelTimers();
    super.dispose();
  }

  void _handleTooltipChanged() {
    if (_tooltipText == null && _visible) {
      setState(() => _visible = false);
    }
  }

  void _handleResizeChanged() {
    if (!widget.isResizingListenable.value) return;
    _cancelTimers();
    if (_visible) {
      PreviewFloatingWindow._log('tooltip hide while resizing');
      setState(() => _visible = false);
    }
  }

  String? get _tooltipText {
    final text = widget.tooltipListenable.value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  void _handleEnter(PointerEnterEvent event) {
    if (_tooltipText == null || widget.isResizingListenable.value) return;
    _tooltipPosition = event.localPosition;
    PreviewFloatingWindow._log(
      'tooltip enter local=${PreviewFloatingWindow._formatOffset(event.localPosition)}',
    );
    _cancelTimers();
    _showTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _tooltipText == null) return;
      PreviewFloatingWindow._log(
        'tooltip show local=${PreviewFloatingWindow._formatOffset(_tooltipPosition)}',
      );
      setState(() => _visible = true);
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          PreviewFloatingWindow._log('tooltip autoHide');
          setState(() => _visible = false);
        }
      });
    });
  }

  void _handleHover(PointerHoverEvent event) {
    if (_tooltipText == null || widget.isResizingListenable.value) return;
    _tooltipPosition = event.localPosition;
    if (_visible) {
      setState(() {});
    }
  }

  void _handleExit(PointerExitEvent event) {
    if (_showTimer != null || _visible) {
      PreviewFloatingWindow._log('tooltip exit');
    }
    _cancelTimers();
    if (_visible) {
      setState(() => _visible = false);
    }
  }

  void _cancelTimers() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _showTimer = null;
    _hideTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final tooltipText = _tooltipText;
    return MouseRegion(
      onEnter: _handleEnter,
      onHover: _handleHover,
      onExit: _handleExit,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_visible && tooltipText != null)
            Positioned(
              left: _tooltipPosition.dx + 10,
              top: _tooltipPosition.dy + 12,
              child: IgnorePointer(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF2222222),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Text(
                        tooltipText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          height: 1.25,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoveHandle extends StatelessWidget {
  const _MoveHandle({
    super.key,
    required this.isResizingListenable,
    required this.onMove,
    required this.onClose,
  });
  final ValueListenable<bool> isResizingListenable;
  final ValueChanged<Offset> onMove;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return _MoveHandleBody(
      isResizingListenable: isResizingListenable,
      onMove: onMove,
      onClose: onClose,
    );
  }
}

class _MoveHandleBody extends StatefulWidget {
  const _MoveHandleBody({
    required this.isResizingListenable,
    required this.onMove,
    required this.onClose,
  });

  final ValueListenable<bool> isResizingListenable;
  final ValueChanged<Offset> onMove;
  final VoidCallback onClose;

  @override
  State<_MoveHandleBody> createState() => _MoveHandleBodyState();
}

class _MoveHandleBodyState extends State<_MoveHandleBody> {
  int _moveCount = 0;
  Offset _accDelta = Offset.zero;
  bool _closeHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 14,
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: const Color(0xFFE8E8E8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                if (_closeHovered) return;
                _moveCount = 0;
                _accDelta = Offset.zero;
                final geometry = _renderGeometry(context);
                PreviewFloatingWindow._log(
                  'move start global=${PreviewFloatingWindow._formatOffset(details.globalPosition)} '
                  'local=${PreviewFloatingWindow._formatOffset(details.localPosition)} '
                  'isResizing=${widget.isResizingListenable.value} $geometry',
                );
              },
              onPanUpdate: (d) {
                if (_closeHovered) return;
                _moveCount += 1;
                _accDelta += d.delta;
                PreviewFloatingWindow._log(
                  'move update count=$_moveCount delta=${PreviewFloatingWindow._formatOffset(d.delta)} '
                  'acc=${PreviewFloatingWindow._formatOffset(_accDelta)} '
                  'global=${PreviewFloatingWindow._formatOffset(d.globalPosition)} '
                  'local=${PreviewFloatingWindow._formatOffset(d.localPosition)} '
                  'isResizing=${widget.isResizingListenable.value}',
                );
                if (!widget.isResizingListenable.value) {
                  widget.onMove(d.delta);
                } else {
                  PreviewFloatingWindow._log(
                    'move update blocked count=$_moveCount '
                    'delta=${PreviewFloatingWindow._formatOffset(d.delta)}',
                  );
                }
              },
              onPanEnd: (_) {
                if (_closeHovered) return;
                PreviewFloatingWindow._log(
                  'move end moves=$_moveCount acc=${PreviewFloatingWindow._formatOffset(_accDelta)} '
                  'isResizing=${widget.isResizingListenable.value}',
                );
              },
              onPanCancel: () {
                if (_closeHovered) return;
                PreviewFloatingWindow._log(
                  'move cancel moves=$_moveCount acc=${PreviewFloatingWindow._formatOffset(_accDelta)} '
                  'isResizing=${widget.isResizingListenable.value}',
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.move,
                onEnter: (event) {
                  PreviewFloatingWindow._log(
                    'move hover enter global=${PreviewFloatingWindow._formatOffset(event.position)} '
                    'local=${PreviewFloatingWindow._formatOffset(event.localPosition)} '
                    '${_renderGeometry(context)}',
                  );
                },
                onExit: (event) {
                  PreviewFloatingWindow._log(
                    'move hover exit global=${PreviewFloatingWindow._formatOffset(event.position)} '
                    'local=${PreviewFloatingWindow._formatOffset(event.localPosition)}',
                  );
                },
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MoveHandleDotRow(),
                      SizedBox(height: 2),
                      _MoveHandleDotRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _FloatingCloseButton(
            onPressed: widget.onClose,
            onHoverChanged: (hovered) {
              if (_closeHovered == hovered) return;
              setState(() => _closeHovered = hovered);
            },
          ),
        ],
      ),
    );
  }

  String _renderGeometry(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return 'box=unavailable';
    }
    return 'boxTopLeft=${PreviewFloatingWindow._formatOffset(renderObject.localToGlobal(Offset.zero))} '
        'boxSize=${PreviewFloatingWindow._formatSize(renderObject.size)}';
  }
}

class _MoveHandleDotRow extends StatelessWidget {
  const _MoveHandleDotRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [_MoveHandleDot(), SizedBox(width: 5), _MoveHandleDot()],
    );
  }
}

class _MoveHandleDot extends StatelessWidget {
  const _MoveHandleDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 2.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF6F6F6F),
        ),
      ),
    );
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    super.key,
    required this.name,
    required this.rect,
    required this.computeRect,
    required this.cursor,
    required this.onResize,
    required this.onResizeStart,
    required this.onResizeEnd,
    this.size,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.showHoverIndicator = false,
    this.hideIndicatorListenable,
  });

  final String name;
  final Rect rect;
  final Rect Function(Rect base, Offset delta) computeRect;
  final MouseCursor cursor;
  final ValueChanged<Rect> onResize;
  final void Function(String handleName, int pointer) onResizeStart;
  final void Function(String handleName, int pointer) onResizeEnd;
  final double? size;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final bool showHoverIndicator;
  final ValueListenable<bool>? hideIndicatorListenable;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  Rect? _startRect;
  Offset? _startGlobalPosition;
  Offset _accDelta = Offset.zero;
  bool _hovered = false;
  int _moveCount = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom,
      child: MouseRegion(
        cursor: widget.cursor,
        onEnter: (event) {
          setState(() => _hovered = true);
          PreviewFloatingWindow._log(
            'resize hover enter handle=${widget.name} '
            'global=${PreviewFloatingWindow._formatOffset(event.position)} '
            'local=${PreviewFloatingWindow._formatOffset(event.localPosition)} '
            '${_renderGeometry(context)}',
          );
        },
        onExit: (event) {
          setState(() => _hovered = false);
          PreviewFloatingWindow._log(
            'resize hover exit handle=${widget.name} '
            'global=${PreviewFloatingWindow._formatOffset(event.position)} '
            'local=${PreviewFloatingWindow._formatOffset(event.localPosition)}',
          );
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            setState(() {
              _startRect = widget.rect;
              _startGlobalPosition = event.position;
              _accDelta = Offset.zero;
              _moveCount = 0;
            });
            PreviewFloatingWindow._log(
              'resize start handle=${widget.name} pointer=${event.pointer} '
              'global=${PreviewFloatingWindow._formatOffset(event.position)} '
              'local=${PreviewFloatingWindow._formatOffset(event.localPosition)} '
              '${_renderGeometry(context)} '
              'anchors=${_anchorDescription()} size=${widget.size?.toStringAsFixed(1) ?? 'default'} '
              'rect=${PreviewFloatingWindow._formatRect(widget.rect)}',
            );
            widget.onResizeStart(widget.name, event.pointer);
          },
          onPointerMove: (event) {
            if (_startRect == null || _startGlobalPosition == null) return;
            _accDelta = event.position - _startGlobalPosition!;
            _moveCount += 1;
            final computed = widget.computeRect(_startRect!, _accDelta);
            PreviewFloatingWindow._log(
              'resize move handle=${widget.name} pointer=${event.pointer} '
              'count=$_moveCount global=${PreviewFloatingWindow._formatOffset(event.position)} '
              'local=${PreviewFloatingWindow._formatOffset(event.localPosition)} '
              'delta=${PreviewFloatingWindow._formatOffset(_accDelta)} '
              'start=${PreviewFloatingWindow._formatRect(_startRect!)} '
              'next=${PreviewFloatingWindow._formatRect(computed)}',
            );
            widget.onResize(computed);
          },
          onPointerUp: (event) {
            PreviewFloatingWindow._log(
              'resize end handle=${widget.name} pointer=${event.pointer} '
              'moves=$_moveCount delta=${PreviewFloatingWindow._formatOffset(_accDelta)}',
            );
            setState(() {
              _startRect = null;
              _startGlobalPosition = null;
            });
            widget.onResizeEnd(widget.name, event.pointer);
          },
          onPointerCancel: (event) {
            PreviewFloatingWindow._log(
              'resize cancel handle=${widget.name} pointer=${event.pointer} '
              'moves=$_moveCount delta=${PreviewFloatingWindow._formatOffset(_accDelta)}',
            );
            setState(() {
              _startRect = null;
              _startGlobalPosition = null;
            });
            widget.onResizeEnd(widget.name, event.pointer);
          },
          child: SizedBox(
            width: widget.size ?? _FloatingCard._handleSize,
            height: widget.size ?? _FloatingCard._handleSize,
            child: widget.showHoverIndicator ? _buildHoverIndicator() : null,
          ),
        ),
      ),
    );
  }

  Widget _buildHoverIndicator() {
    final hideIndicatorListenable = widget.hideIndicatorListenable;
    if (hideIndicatorListenable == null) {
      return _buildHoverIndicatorPaint();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: hideIndicatorListenable,
      builder: (context, hideIndicator, _) {
        if (hideIndicator) return const SizedBox.shrink();
        return _buildHoverIndicatorPaint();
      },
    );
  }

  Widget _buildHoverIndicatorPaint() {
    return AnimatedOpacity(
      opacity: _hovered || _startRect != null ? 1 : 0,
      duration: const Duration(milliseconds: 90),
      child: CustomPaint(
        painter: _ResizeCornerGripPainter(
          name: widget.name,
          color: _hovered || _startRect != null
              ? const Color(0xFF1E6FD9)
              : const Color(0xFF7A8CA3),
        ),
      ),
    );
  }

  String _anchorDescription() {
    return 'left=${widget.left?.toStringAsFixed(1) ?? '-'} '
        'top=${widget.top?.toStringAsFixed(1) ?? '-'} '
        'right=${widget.right?.toStringAsFixed(1) ?? '-'} '
        'bottom=${widget.bottom?.toStringAsFixed(1) ?? '-'}';
  }

  String _renderGeometry(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return 'box=unavailable';
    }
    return 'boxTopLeft=${PreviewFloatingWindow._formatOffset(renderObject.localToGlobal(Offset.zero))} '
        'boxSize=${PreviewFloatingWindow._formatSize(renderObject.size)}';
  }
}

class _ResizeCornerGripPainter extends CustomPainter {
  const _ResizeCornerGripPainter({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const padding = 8.0;
    const length = 18.0;

    switch (name) {
      case 'top-left':
        canvas.drawLine(
          const Offset(padding, padding),
          const Offset(padding + length, padding),
          paint,
        );
        canvas.drawLine(
          const Offset(padding, padding),
          const Offset(padding, padding + length),
          paint,
        );
        break;
      case 'top-right':
        canvas.drawLine(
          Offset(size.width - padding - length, padding),
          Offset(size.width - padding, padding),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - padding, padding),
          Offset(size.width - padding, padding + length),
          paint,
        );
        break;
      case 'bottom-left':
        canvas.drawLine(
          Offset(padding, size.height - padding),
          Offset(padding + length, size.height - padding),
          paint,
        );
        canvas.drawLine(
          Offset(padding, size.height - padding - length),
          Offset(padding, size.height - padding),
          paint,
        );
        break;
      case 'bottom-right':
        canvas.drawLine(
          Offset(size.width - padding - length, size.height - padding),
          Offset(size.width - padding, size.height - padding),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - padding, size.height - padding - length),
          Offset(size.width - padding, size.height - padding),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ResizeCornerGripPainter oldDelegate) {
    return oldDelegate.name != name || oldDelegate.color != color;
  }
}
