import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/preview_floating_window.dart';

void main() {
  test('edge resize preserves the opposite edge in all four directions', () {
    const base = Rect.fromLTWH(100, 80, 200, 120);
    const minSize = Size(80, 60);

    final left = previewFloatingEdgeResizedRect(
      base,
      minSize,
      left: -30,
    );
    expect(left.left, 70);
    expect(left.right, base.right);

    final top = previewFloatingEdgeResizedRect(
      base,
      minSize,
      top: -20,
    );
    expect(top.top, 60);
    expect(top.bottom, base.bottom);

    final right = previewFloatingEdgeResizedRect(
      base,
      minSize,
      right: 30,
    );
    expect(right.left, base.left);
    expect(right.right, 330);

    final bottom = previewFloatingEdgeResizedRect(
      base,
      minSize,
      bottom: 20,
    );
    expect(bottom.top, base.top);
    expect(bottom.bottom, 220);
  });

  test('edge resize keeps the opposite edge at minimum size', () {
    const base = Rect.fromLTWH(100, 80, 200, 120);
    const minSize = Size(80, 60);

    final left = previewFloatingEdgeResizedRect(
      base,
      minSize,
      left: 500,
    );
    expect(left, const Rect.fromLTRB(220, 80, 300, 200));

    final top = previewFloatingEdgeResizedRect(
      base,
      minSize,
      top: 500,
    );
    expect(top, const Rect.fromLTRB(100, 140, 300, 200));
  });

  test('movement clamp keeps the floating window inside the overlay', () {
    const bounds = Size(800, 600);
    expect(
      previewFloatingClampedRect(
        const Rect.fromLTWH(-50, -30, 300, 200),
        bounds,
      ),
      const Rect.fromLTWH(0, 0, 300, 200),
    );
    expect(
      previewFloatingClampedRect(
        const Rect.fromLTWH(700, 550, 300, 200),
        bounds,
      ),
      const Rect.fromLTWH(500, 400, 300, 200),
    );
  });
}