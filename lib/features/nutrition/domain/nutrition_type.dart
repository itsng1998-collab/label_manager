class NutritionType {
  const NutritionType({required this.id, required this.name});

  final int id;
  final String name;

  factory NutritionType.fromMap(Map<String, dynamic> map) => NutritionType(
    id: int.tryParse((map['NUTTYPE_ID'] ?? '').toString()) ?? 0,
    name: (map['NUTTYPE_NAME'] ?? '').toString(),
  );
}

class NutritionTypeColumn {
  const NutritionTypeColumn({
    required this.id,
    required this.keyword,
    required this.name,
  });

  final int id;
  final String keyword;
  final String name;

  NutritionTypeColumn copyWith({String? name}) =>
      NutritionTypeColumn(id: id, keyword: keyword, name: name ?? this.name);

  factory NutritionTypeColumn.fromMap(Map<String, dynamic> map) =>
      NutritionTypeColumn(
        id: int.tryParse((map['NUTCOL_ID'] ?? '').toString()) ?? 0,
        keyword: (map['NUTCOL_KEYWORD'] ?? '').toString(),
        name: (map['NUTCOL_NAME'] ?? '').toString(),
      );
}
