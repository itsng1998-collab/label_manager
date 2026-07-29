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

  @override
  String toString() =>
      'CustomerId: $customerId, CoopId: $cooperatorId, CustomerName: $customerName';
}