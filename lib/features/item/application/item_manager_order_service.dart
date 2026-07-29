import 'package:label_manager/features/item/data/item_dao.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/models/item_of_market.dart';

typedef ItemManagerOrderLoader = Future<List<ItemOfMarket>?> Function(
  int marketId,
  int labelSizeId,
);
typedef ItemManagerOrderWriter = Future<void> Function(
  List<ItemOrderUpdate> updates,
);

Future<List<ItemOfMarket>> loadItemManagerOrder({
  required int marketId,
  required int labelSizeId,
  ItemManagerOrderLoader load =
      ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId,
}) async => await load(marketId, labelSizeId) ?? const <ItemOfMarket>[];

List<ItemOrderUpdate> buildItemManagerOrderUpdates(
  List<ItemOfMarket> orderedItems,
) => [
  for (var index = 0; index < orderedItems.length; index++)
    ItemOrderUpdate(itemId: orderedItems[index].item.itemId, order: index + 1),
];

Future<void> saveItemManagerOrder({
  required List<ItemOfMarket> orderedItems,
  ItemManagerOrderWriter save = ItemDAO.updateOrders,
}) => save(buildItemManagerOrderUpdates(orderedItems));