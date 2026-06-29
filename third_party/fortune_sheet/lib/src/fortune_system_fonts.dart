import 'package:flutter/services.dart';

import 'fortune_debug_log.dart';
import 'fortune_sheet_model.dart';

class FortuneSystemFonts {
  const FortuneSystemFonts._();

  static const MethodChannel channel = MethodChannel('fortune_sheet/fonts');

  static Future<List<String>> loadFontFamilies() async {
    final result = await channel.invokeMethod<Object?>('listFontFamilies');
    final rawFamilies = _fontNamesFromChannelResult(result).toList();
    final collapsedFamilies = <String>[];
    final duplicateFamilies = <String>[];
    final filteredFamilies = <String>[];
    final families = fortuneMergeFontFamilies(
      rawFamilies,
      onCollapsedFamily: (source, family) {
        collapsedFamilies.add('$source -> $family');
      },
      onDuplicateFamily: (source, family) {
        duplicateFamilies.add('$source -> $family');
      },
      onFilteredFamily: filteredFamilies.add,
    );
    fortuneSheetDebugLog(
      'font system load raw=${rawFamilies.length} merged=${families.length} '
      'collapsed=${collapsedFamilies.length} duplicates=${duplicateFamilies.length} '
      'filtered=${filteredFamilies.length}',
    );
    for (final collapse in collapsedFamilies.take(80)) {
      fortuneSheetDebugLog('font system collapse $collapse');
    }
    for (final duplicate in duplicateFamilies.take(80)) {
      fortuneSheetDebugLog('font system duplicate $duplicate');
    }
    for (final filtered in filteredFamilies.take(80)) {
      fortuneSheetDebugLog('font system filtered $filtered');
    }
    for (final line in fortuneFontFamilyDebugListLines('system', families)) {
      fortuneSheetDebugLog(line);
    }
    return families;
  }

  static Iterable<String> _fontNamesFromChannelResult(Object? result) sync* {
    if (result is! Iterable) {
      return;
    }
    for (final item in result) {
      if (item is String) {
        yield item;
      } else if (item is Map) {
        final family = item['family'] ?? item['name'] ?? item['label'];
        if (family is String) {
          yield family;
        }
      }
    }
  }
}
