const String statusPrintElementColumn = '주원료';

class StatusPrintRow {
  const StatusPrintRow({
    required this.statusId,
    required this.printDate,
    required this.printCount,
    required this.itemName,
    required this.itemElement,
    required this.searchValue,
    required this.brandName,
    required this.labelSizeName,
    required this.itemChangeDeleteDate,
  });

  final String statusId;
  final String printDate;
  final int printCount;
  final String itemName;
  final String itemElement;
  final String searchValue;
  final String brandName;
  final String labelSizeName;
  final String itemChangeDeleteDate;

  bool get deleted => itemChangeDeleteDate.isNotEmpty;

  factory StatusPrintRow.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    return StatusPrintRow(
      statusId: stringValue('STATUS_ID'),
      printDate: stringValue('PRINT_DATE'),
      printCount: int.tryParse(stringValue('PRINT_COUNT')) ?? 0,
      itemName: stringValue('ITEM_NAME'),
      itemElement: stringValue('ITEM_ELEMENT'),
      searchValue: stringValue('SEARCH_VALUE'),
      brandName: stringValue('BRAND_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      itemChangeDeleteDate: stringValue('ITEM_CHANGE_DELETE_DATE'),
    );
  }
}

class StatusPrintDetailRow {
  const StatusPrintDetailRow({
    required this.columnName,
    required this.changeDeleteDate,
    required this.value,
  });

  final String columnName;
  final String changeDeleteDate;
  final String value;

  factory StatusPrintDetailRow.fromMap(Map<String, dynamic> map) =>
      StatusPrintDetailRow(
        columnName: (map['COLUMN_NAME'] ?? '').toString(),
        changeDeleteDate: (map['CHANGE_DELETE_DATE'] ?? '').toString(),
        value: (map['COLUMN_VALUE'] ?? '').toString(),
      );
}

class StatusPrintDetail {
  const StatusPrintDetail({
    required this.itemName,
    required this.itemElement,
    required this.itemChangeDeleteDate,
    required this.rows,
  });

  final String itemName;
  final String itemElement;
  final String itemChangeDeleteDate;
  final List<StatusPrintDetailRow> rows;
}

class StatusPrintQuerySpec {
  const StatusPrintQuerySpec({
    required this.startDate,
    required this.endDate,
    required this.customerId,
    required this.searchColumn,
    required this.exactMatch,
    this.brandId,
    this.labelSizeId,
    this.itemName = '',
    this.searchText = '',
  });

  final String startDate;
  final String endDate;
  final int customerId;
  final int? brandId;
  final int? labelSizeId;
  final String itemName;
  final String searchColumn;
  final String searchText;
  final bool exactMatch;

  bool get searchesElement => searchColumn == statusPrintElementColumn;

  Map<String, dynamic> get parameters => {
    'startDate': startDate,
    'endDate': endDate,
    'customerId': customerId,
    if (brandId != null) 'brandId': brandId,
    if (labelSizeId != null) 'labelSizeId': labelSizeId,
    if (itemName.isNotEmpty) 'itemName': '%$itemName%',
    if (!searchesElement) 'searchColumn': searchColumn,
    if (searchesElement || searchText.isNotEmpty)
      'searchText': exactMatch ? searchText : '%$searchText%',
  };
}
