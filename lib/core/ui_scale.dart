import 'dart:math' as math;

import 'package:flutter/material.dart';

const double labelManagerBaseFontSize = 14;
const double labelManagerFontDelta = -1;
const double labelManagerUiScale =
    (labelManagerBaseFontSize + labelManagerFontDelta) /
    labelManagerBaseFontSize;

const TextScaler labelManagerTextScaler = _LabelManagerTextScaler(
  TextScaler.noScaling,
);

double lmSize(num value) => value * labelManagerUiScale;

Size lmSize2(num width, num height) => Size(lmSize(width), lmSize(height));

EdgeInsets lmInsetsAll(num value) => EdgeInsets.all(lmSize(value));

EdgeInsets lmInsetsSymmetric({num horizontal = 0, num vertical = 0}) =>
    EdgeInsets.symmetric(
      horizontal: lmSize(horizontal),
      vertical: lmSize(vertical),
    );

EdgeInsets lmInsetsOnly({
  num left = 0,
  num top = 0,
  num right = 0,
  num bottom = 0,
}) => EdgeInsets.only(
  left: lmSize(left),
  top: lmSize(top),
  right: lmSize(right),
  bottom: lmSize(bottom),
);

ThemeData labelManagerTheme(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    appBarTheme: AppBarTheme(toolbarHeight: lmSize(kToolbarHeight)),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      contentPadding: lmInsetsSymmetric(horizontal: 10, vertical: 8),
    ),
  );
}

Widget withLabelManagerCompactUi(BuildContext context, Widget child) {
  final mediaQuery = MediaQuery.of(context);
  final originalTextScaler = mediaQuery.textScaler;
  return _LabelManagerOriginalTextScaler(
    textScaler: originalTextScaler,
    child: MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: _LabelManagerTextScaler(originalTextScaler),
      ),
      child: child,
    ),
  );
}

Widget withoutLabelManagerCompactUi(BuildContext context, Widget child) {
  final mediaQuery = MediaQuery.of(context);
  final originalTextScaler = _LabelManagerOriginalTextScaler.maybeOf(context);
  if (originalTextScaler == null) {
    return child;
  }
  return MediaQuery(
    data: mediaQuery.copyWith(textScaler: originalTextScaler),
    child: child,
  );
}

class _LabelManagerTextScaler extends TextScaler {
  const _LabelManagerTextScaler(this.base);

  final TextScaler base;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor;

  @override
  double scale(double fontSize) => math.max(1, base.scale(fontSize) - 1);

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    return _LabelManagerTextScaler(
      base.clamp(
        minScaleFactor: minScaleFactor,
        maxScaleFactor: maxScaleFactor,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _LabelManagerTextScaler && other.base == base;
  }

  @override
  int get hashCode => Object.hash(_LabelManagerTextScaler, base);
}

class _LabelManagerOriginalTextScaler extends InheritedWidget {
  const _LabelManagerOriginalTextScaler({
    required this.textScaler,
    required super.child,
  });

  final TextScaler textScaler;

  static TextScaler? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_LabelManagerOriginalTextScaler>()
        ?.textScaler;
  }

  @override
  bool updateShouldNotify(_LabelManagerOriginalTextScaler oldWidget) {
    return oldWidget.textScaler != textScaler;
  }
}
