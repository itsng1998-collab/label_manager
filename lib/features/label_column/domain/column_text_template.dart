import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';

String labelColumnTextToken(String keyword) {
  final value = keyword.trim();
  return value.startsWith('#') ? value : '#$value';
}

RegExp? _tokenPattern(Iterable<String> keywords) {
  final tokens = {
    for (final keyword in keywords)
      if (keyword.trim().isNotEmpty && keyword.trim() != '#')
        labelColumnTextToken(keyword),
  }.toList()..sort((left, right) => right.length.compareTo(left.length));
  if (tokens.isEmpty) return null;
  return RegExp(
    '(?:${tokens.map(RegExp.escape).join('|')})(?![A-Za-z0-9_])',
  );
}

Set<String> labelColumnTextReferences(String text, Iterable<String> keywords) {
  final pattern = _tokenPattern(keywords);
  return pattern == null
      ? const {}
      : {for (final match in pattern.allMatches(text)) match.group(0)!};
}

String replaceLabelColumnTextTokens(
  String template,
  Map<String, String> values,
) {
  final normalized = {
    for (final entry in values.entries)
      labelColumnTextToken(entry.key): entry.value,
  };
  final pattern = _tokenPattern(normalized.keys);
  if (pattern == null) return template;
  return template.replaceAllMapped(pattern, (match) => normalized[match[0]]!);
}

String basicColumnTextTemplate(TColumn column) {
  if (column.columnType.code != TColumnType.TYPE_BASE) return '';
  if (column.userDefineBarcodeText.isNotEmpty) return column.userDefineBarcodeText;
  if (column.qrCodeCreateType != QRCodeCreateType.QRCODE_TYPE_USER_DEFINE) {
    return '';
  }
  return column.userDefineQRData.isNotEmpty
      ? column.userDefineQRData
      : column.userDefineQRText;
}

Map<String, String> basicColumnTextReplacements({
  required Iterable<TColumn> columns,
  required Map<String, String> itemValues,
}) => {
  for (final column in columns)
    if (basicColumnTextTemplate(column).isNotEmpty)
      labelColumnTextToken(column.keyword): replaceLabelColumnTextTokens(
        basicColumnTextTemplate(column),
        itemValues,
      ),
};
