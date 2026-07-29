class LabelSheetRequiredKeyword {
  const LabelSheetRequiredKeyword({
    required this.keyword,
    required this.itemName,
  });

  final String keyword;
  final String itemName;

  String get normalizedKeyword {
    final value = keyword.trim();
    return value.startsWith('#') ? value : '#$value';
  }
}
