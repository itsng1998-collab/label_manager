class LastConnect {
  final String userId;
  final int brandId;
  final int labelSizeId;

  const LastConnect({
    required this.userId,
    required this.brandId,
    required this.labelSizeId,
  });

  @override
  String toString() =>
      'UserId: $userId, BrandId: $brandId, LabelSizeId: $labelSizeId';
}
