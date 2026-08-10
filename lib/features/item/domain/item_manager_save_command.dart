class ItemManagerNewMappingDefaults {
  final int gdsNo;
  final DateTime? dateSaleStart;
  final DateTime? dateSaleEnd;
  final double discountPercent;
  final int discountAmount;
  final DateTime? dateStartDiscount;
  final DateTime? dateEndDiscount;
  final bool useDefineElement;
  final String rtfText;
  final bool useLinefeed;
  final int linefeed;
  final bool useScaleBarcode;
  final int printCount;
  final bool useLabelSize;
  final int labelSizeWidth;
  final int labelSizeHeight;
  final bool useMargin;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;

  const ItemManagerNewMappingDefaults({
    this.gdsNo = 0,
    this.dateSaleStart,
    this.dateSaleEnd,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.dateStartDiscount,
    this.dateEndDiscount,
    this.useDefineElement = false,
    this.rtfText = '',
    this.useLinefeed = false,
    this.linefeed = 100,
    this.useScaleBarcode = false,
    this.printCount = 1,
    this.useLabelSize = false,
    this.labelSizeWidth = 0,
    this.labelSizeHeight = 0,
    this.useMargin = false,
    this.leftMargin = 0,
    this.rightMargin = 0,
    this.topMargin = 0,
    this.leftPush = 0,
    this.topPush = 0,
  });
}

class ItemManagerExistingRowSave {
  final int sourceItemId;
  final String itemName;
  final String elementPlain;
  final String elementSheet;
  final int order;

  const ItemManagerExistingRowSave({
    required this.sourceItemId,
    required this.itemName,
    required this.elementPlain,
    required this.elementSheet,
    required this.order,
  });
}

class ItemManagerNewRowSave {
  final String draftRowKey;
  final int labelSizeId;
  final String itemName;
  final String elementPlain;
  final String elementSheet;
  final int order;
  final ItemManagerNewMappingDefaults mappingDefaults;

  const ItemManagerNewRowSave({
    required this.draftRowKey,
    required this.labelSizeId,
    required this.itemName,
    required this.elementPlain,
    required this.elementSheet,
    required this.order,
    this.mappingDefaults = const ItemManagerNewMappingDefaults(),
  });
}

class ItemManagerColumnValueSave {
  final int? sourceItemId;
  final String? draftRowKey;
  final int columnId;
  final bool editable;
  final String dataString;

  const ItemManagerColumnValueSave({
    this.sourceItemId,
    this.draftRowKey,
    required this.columnId,
    this.editable = true,
    required this.dataString,
  });
}

class ItemManagerMinColumnCheckSave {
  final int labelSizeId;
  final int columnId;
  final String keyword;
  final String columnName;
  final int columnOrder;
  final bool checked;

  const ItemManagerMinColumnCheckSave({
    required this.labelSizeId,
    required this.columnId,
    required this.keyword,
    required this.columnName,
    required this.columnOrder,
    required this.checked,
  });
}

class ItemManagerSaveCommand {
  final List<int> targetMarketIds;
  final List<int> deletedSourceItemIds;
  final List<ItemManagerExistingRowSave> existingRows;
  final List<ItemManagerNewRowSave> newRows;
  final List<ItemManagerColumnValueSave> columnValues;
  final List<ItemManagerMinColumnCheckSave> minColumnChecks;

  const ItemManagerSaveCommand({
    required this.targetMarketIds,
    this.deletedSourceItemIds = const [],
    this.existingRows = const [],
    this.newRows = const [],
    this.columnValues = const [],
    this.minColumnChecks = const [],
  });

  void validate() {
    void requireUniquePositive(Iterable<int> values, String field) {
      final list = values.toList();
      if (list.any((value) => value <= 0) ||
          list.toSet().length != list.length) {
        throw ArgumentError('$field requires unique positive ids.');
      }
    }

    requireUniquePositive(targetMarketIds, 'targetMarketIds');
    requireUniquePositive(deletedSourceItemIds, 'deletedSourceItemIds');
    requireUniquePositive(
      existingRows.map((row) => row.sourceItemId),
      'existingRows.sourceItemId',
    );
    final draftKeys = newRows.map((row) => row.draftRowKey).toList();
    if (draftKeys.any((key) => key.trim().isEmpty) ||
        draftKeys.toSet().length != draftKeys.length) {
      throw ArgumentError('newRows.draftRowKey requires unique values.');
    }
    if (newRows.isNotEmpty && targetMarketIds.isEmpty) {
      throw ArgumentError('New rows require targetMarketIds.');
    }
    for (final value in columnValues) {
      final hasSource = value.sourceItemId != null;
      final hasDraft = value.draftRowKey?.isNotEmpty == true;
      if (hasSource == hasDraft || value.columnId <= 0) {
        throw ArgumentError(
          'Column values require one row identity and a positive column id.',
        );
      }
    }
    final minColumnKeys = <(int, int)>{};
    for (final value in minColumnChecks) {
      if (value.labelSizeId <= 0 || value.columnId < 0) {
        throw ArgumentError(
          'Minimum column checks require a positive label size id and a non-negative column id.',
        );
      }
      if (!minColumnKeys.add((value.labelSizeId, value.columnId))) {
        throw ArgumentError('Minimum column checks require unique columns.');
      }
    }
  }
}

class ItemManagerSaveResult {
  final Map<String, int> insertedItemIdsByDraftKey;

  const ItemManagerSaveResult({required this.insertedItemIdsByDraftKey});
}