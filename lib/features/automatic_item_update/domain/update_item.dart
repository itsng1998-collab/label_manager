class UpdateItem {
  static List<UpdateItem>? datas;

  final int updateItemId;
  final int itemId;
  final String itemName;
  final int labelSizeId;
  final String element;
  final String elementRTF;
  final int price;
  final DateTime applyDate;
  final bool isApply;

  const UpdateItem({
    required this.updateItemId,
    required this.itemId,
    required this.itemName,
    required this.labelSizeId,
    required this.element,
    required this.elementRTF,
    required this.price,
    required this.applyDate,
    required this.isApply,
  });

  static void setDatas(List<UpdateItem>? values) {
    datas = values;
  }

  factory UpdateItem.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    final applyDateText = stringValue('APPLY_DATE');
    final applyDate = parseUpdateItemApplyDate(applyDateText);
    if (applyDate == null) {
      throw FormatException('Invalid APPLY_DATE: $applyDateText');
    }

    return UpdateItem(
      updateItemId: intValue('UPDATE_ITEM_ID'),
      itemId: intValue('ITEM_ID'),
      itemName: stringValue('ITEM_NAME'),
      labelSizeId: intValue('LABEL_SIZE_ID'),
      element: stringValue('ELEMENT'),
      elementRTF: stringValue('ELEMENT_RTF'),
      price: intValue('PRICE'),
      applyDate: applyDate,
      isApply: parseUpdateItemIsApply(stringValue('IS_APPLY')),
    );
  }

  @override
  String toString() =>
      'UpdateItemId: $updateItemId, ItemId: $itemId, ItemName: $itemName, '
      'LabelSizeId: $labelSizeId, Element: $element, ElementRTF: $elementRTF, '
      'Price: $price, ApplyDate: $applyDate, IsApply: $isApply';
}

DateTime? parseUpdateItemApplyDate(String value) {
  if (!RegExp(r'^\d{8}$').hasMatch(value)) {
    return null;
  }
  final year = int.tryParse(value.substring(0, 4));
  final month = int.tryParse(value.substring(4, 6));
  final day = int.tryParse(value.substring(6, 8));
  if (year == null || month == null || day == null) {
    return null;
  }
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

bool parseUpdateItemIsApply(String value) => value.trim() == '1';