class Brand {
  static List<Brand>? datas;

  final int brandId;
  final int customerId;
  final String brandName;

  const Brand({
    required this.brandId,
    required this.customerId,
    required this.brandName,
  });

  static void setDatas(List<Brand>? values) {
    datas = values;
  }

  @override
  String toString() =>
      'BrandId: $brandId, CustomerId: $customerId, BrandName: $brandName';
}

class BrandOrderUpdate {
  final int brandId;
  final int brandOrder;

  const BrandOrderUpdate({required this.brandId, required this.brandOrder});
}
