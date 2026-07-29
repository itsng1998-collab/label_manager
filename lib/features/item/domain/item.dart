class Item {
  final int itemId;
  final int labelSizeId;
  final String itemName;
  final String labelSizeName;
  final String element;
  final String elementRTF;
  final int price;
  final int order;

  const Item({
    required this.itemId,
    required this.labelSizeId,
    required this.itemName,
    required this.labelSizeName,
    required this.element,
    required this.elementRTF,
    required this.price,
    required this.order,
  });

  Item copyWith({
    String? itemName,
    String? element,
    String? elementRTF,
    int? order,
  }) => Item(
    itemId: itemId,
    labelSizeId: labelSizeId,
    itemName: itemName ?? this.itemName,
    labelSizeName: labelSizeName,
    element: element ?? this.element,
    elementRTF: elementRTF ?? this.elementRTF,
    price: price,
    order: order ?? this.order,
  );

  @override
  String toString() =>
      'itemId: $itemId, labelSizeId: $labelSizeId, itemName: $itemName, labelSizeName: $labelSizeName, '
      'element: $element, elementRTF: $elementRTF, price: $price, order: $order';
}

class ItemOrderUpdate {
  final int itemId;
  final int order;

  const ItemOrderUpdate({required this.itemId, required this.order});
}

class ItemElementSearchReplaceUpdate {
  const ItemElementSearchReplaceUpdate({
    required this.itemId,
    required this.element,
    required this.elementSheet,
  });

  final int itemId;
  final String element;
  final String elementSheet;
}
