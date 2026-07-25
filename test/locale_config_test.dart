import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:label_manager/core/locale_config.dart';

void main() {
  test('OS locale initializes intl default locale and date symbols', () async {
    await initializeLabelManagerLocale(const Locale('en', 'US'));
    expect(Intl.defaultLocale, 'en_US');
    expect(DateFormat.yMd().format(DateTime(2026, 7, 8)), '7/8/2026');

    await initializeLabelManagerLocale(const Locale('ko', 'KR'));
    expect(Intl.defaultLocale, 'ko_KR');
    expect(DateFormat.yMd().format(DateTime(2026, 7, 8)), '2026. 7. 8.');
  });
}