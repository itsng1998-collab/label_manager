// UTF-8, 한국어 주석

class Market {
  static Market? instance;

  final int marketId;
  final int customerId;
  final String name;

  const Market({
    required this.marketId,
    required this.customerId,
    required this.name,
  });

  static void setInstance(Market? market) {
    instance = market;
  }

  @override
  String toString() =>
      'MarketId: $marketId, CustomerId: $customerId, Name: $name';
}