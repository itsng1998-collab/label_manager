// UTF-8, 한국어 주석

class Customer {
  static Customer? instance;

  final int customerId;
  final String cooperatorId;
  final String customerName;

  const Customer({
    required this.customerId,
    required this.cooperatorId,
    required this.customerName,
  });

  static void setInstance(Customer? customer) {
    instance = customer;
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return Customer(
      customerId: i('CUSTOMER_ID'),
      cooperatorId: s('COOP_ID'),
      customerName: s('NAME'),
    );
  }

  @override
  String toString() =>
      'CustomerId: $customerId, CoopId: $cooperatorId, CustomerName: $customerName';
}
