class NutritionBox {
  const NutritionBox({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.name,
    required this.rtf,
    required this.width,
  });

  final int id;
  final int typeId;
  final String typeName;
  final String name;
  final String rtf;
  final int width;

  factory NutritionBox.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    return NutritionBox(
      id: intValue('NUTBOX_ID'),
      typeId: intValue('NUTTYPE_ID'),
      typeName: stringValue('NUTTYPE_NAME'),
      name: stringValue('NUTBOX_NAME'),
      rtf: stringValue('NUTBOX_DATA'),
      width: intValue('NUTBOX_WIDTH'),
    );
  }
}
