import 'package:flutter/widgets.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  runApp(const FortuneSheetHostApp());
}

class FortuneSheetHostApp extends StatefulWidget {
  const FortuneSheetHostApp({super.key});

  @override
  State<FortuneSheetHostApp> createState() => _FortuneSheetHostAppState();
}

class _FortuneSheetHostAppState extends State<FortuneSheetHostApp>
    with WidgetsBindingObserver {
  late Locale? _osLocale = _currentOsLocale();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {
      _osLocale = locales?.isNotEmpty == true
          ? locales!.first
          : _currentOsLocale();
    });
  }

  Locale? _currentOsLocale() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    return locales.isNotEmpty
        ? locales.first
        : WidgetsBinding.instance.platformDispatcher.locale;
  }

  @override
  Widget build(BuildContext context) {
    return FortuneSheetApp(locale: FortuneSheetLocale.forLocale(_osLocale));
  }
}
