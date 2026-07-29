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

  factory Market.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return Market(
      marketId: i('MARKET_ID'),
      customerId: i('CUSTOMER_ID'),
      name: s('NAME'),
    );
  }

  @override
  String toString() =>
      'MarketId: $marketId, CustomerId: $customerId, Name: $name';
}
