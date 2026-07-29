class AdminLabelSizeCopyCommand {
  const AdminLabelSizeCopyCommand({
    required this.sourceLabelSizeId,
    required this.targetLabelSizeId,
    required this.overwriteExisting,
    required this.copyItems,
    this.targetFirstMarketId,
  });

  final int sourceLabelSizeId;
  final int targetLabelSizeId;
  final bool overwriteExisting;
  final bool copyItems;
  final int? targetFirstMarketId;
}

class AdminBrandCopyCommand {
  const AdminBrandCopyCommand({
    required this.sourceBrandId,
    required this.targetCustomerId,
    required this.sourceBrandName,
    required this.copyItems,
    this.targetFirstMarketId,
  });

  final int sourceBrandId;
  final int targetCustomerId;
  final String sourceBrandName;
  final bool copyItems;
  final int? targetFirstMarketId;
}
