import 'package:label_manager/models/item_of_market.dart';

bool searchPrintModeBlocksTabSelection({
  required bool active,
  required Object? currentTab,
  required Object? requestedTab,
}) => active && currentTab != requestedTab;

ItemOfMarket? searchPrintFindBaselineItem(
  Iterable<ItemOfMarket> items,
  int itemId,
) {
  for (final item in items) {
    if (item.item.itemId == itemId) return item;
  }
  return null;
}

class SearchPrintResult {
  const SearchPrintResult({
    required this.brandId,
    required this.labelSizeId,
    required this.itemId,
  });

  final int brandId;
  final int labelSizeId;
  final int itemId;

  factory SearchPrintResult.fromMap(Map<String, dynamic> map) =>
      SearchPrintResult(
        brandId: int.parse(map['BRAND_ID'].toString()),
        labelSizeId: int.parse(map['LABELSIZE_ID'].toString()),
        itemId: int.parse(map['ITEM_ID'].toString()),
      );
}
