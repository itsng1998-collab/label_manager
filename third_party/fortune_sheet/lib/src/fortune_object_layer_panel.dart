import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fortune_sheet_canvas.dart';
import 'fortune_sheet_painter.dart';

class FortuneObjectLayerPanel extends StatelessWidget {
  const FortuneObjectLayerPanel({
    super.key,
    required this.controller,
    this.onClose,
  });

  final FortuneSheetController controller;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final snapshot = controller.objectSelection;
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
                    if (onClose != null)
                      IconButton(
                        tooltip: Overlay.maybeOf(context) == null ? null : '닫기',
                        onPressed: onClose,
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
                          : controller.deleteSelectedObjects,
                    ),
                    _PanelAction(
                      tooltip: '맨 앞으로',
                      icon: Icons.vertical_align_top,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : controller.bringSelectedObjectsToFront,
                    ),
                    _PanelAction(
                      tooltip: '앞으로',
                      icon: Icons.keyboard_arrow_up,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : controller.bringSelectedObjectsForward,
                    ),
                    _PanelAction(
                      tooltip: '뒤로',
                      icon: Icons.keyboard_arrow_down,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : controller.sendSelectedObjectsBackward,
                    ),
                    _PanelAction(
                      tooltip: '맨 뒤로',
                      icon: Icons.vertical_align_bottom,
                      onPressed: snapshot.activeKey == null
                          ? null
                          : controller.sendSelectedObjectsToBack,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: objects.length,
                        itemExtent: 38,
                        itemBuilder: (context, index) {
                          final object = objects[index];
                          final selected = snapshot.selectedKeys.contains(
                            object.key,
                          );
                          return InkWell(
                            onTap: () {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                controller.selectObjectRange(object.key);
                              } else if (HardwareKeyboard
                                  .instance
                                  .isControlPressed ||
                                  HardwareKeyboard.instance.isMetaPressed) {
                                controller.toggleObject(object.key);
                              } else {
                                controller.selectObject(object.key);
                              }
                            },
                            child: ColoredBox(
                              color: selected
                                  ? const Color(0xffe8f0fe)
                                  : Colors.transparent,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
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