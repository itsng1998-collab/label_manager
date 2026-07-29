enum ItemDetailSearchType { itemName, element }

class ItemDetail {
  const ItemDetail({
    required this.itemId,
    required this.labelSizeId,
    required this.itemName,
    required this.labelSizeName,
    required this.element,
    required this.elementSheet,
    required this.brandId,
    required this.brandName,
  });

  final int itemId;
  final int labelSizeId;
  final String itemName;
  final String labelSizeName;
  final String element;
  final String elementSheet;
  final int brandId;
  final String brandName;
}
