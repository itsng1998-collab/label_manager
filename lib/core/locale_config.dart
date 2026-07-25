import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

String labelManagerLocaleName(Locale locale) => locale.toString();

Future<void> initializeLabelManagerLocale(Locale locale) async {
  final localeName = labelManagerLocaleName(locale);
  Intl.defaultLocale = localeName;
  await initializeDateFormatting(localeName);
}
