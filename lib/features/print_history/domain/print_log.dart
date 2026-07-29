enum PrintLogSearchType { itemName, userId, customerName }

class PrintLog {
  const PrintLog({
    required this.logId,
    required this.userId,
    required this.userName,
    required this.userGrade,
    required this.marketId,
    required this.marketName,
    required this.customerId,
    required this.customerName,
    required this.brandName,
    required this.labelSizeName,
    required this.itemName,
    required this.printCount,
    required this.dateTime,
    required this.dateYYYYMMDD,
    required this.printerName,
    required this.columnsWire,
    required this.printCellsWire,
    required this.savedCellsWire,
    required this.formWidth,
    required this.formHeight,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.leftPush,
    required this.topPush,
    required this.appendant,
    required this.itemId,
  });

  final int logId;
  final String userId;
  final String userName;
  final int userGrade;
  final int marketId;
  final String marketName;
  final int customerId;
  final String customerName;
  final String brandName;
  final String labelSizeName;
  final String itemName;
  final int printCount;
  final String dateTime;
  final String dateYYYYMMDD;
  final String printerName;
  final String columnsWire;
  final String printCellsWire;
  final String savedCellsWire;
  final int formWidth;
  final int formHeight;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;
  final double appendant;
  final int itemId;

  factory PrintLog.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    double doubleValue(String key) => double.tryParse(stringValue(key)) ?? 0;

    return PrintLog(
      logId: intValue('LOG_ID'),
      userId: stringValue('USER_ID'),
      userName: stringValue('USER_NAME'),
      userGrade: intValue('USER_GRADE'),
      marketId: intValue('MARKET_ID'),
      marketName: stringValue('MARKET_NAME'),
      customerId: intValue('CUSTOMER_ID'),
      customerName: stringValue('CUSTOMER_NAME'),
      brandName: stringValue('BRAND_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      itemName: stringValue('ITEM_NAME'),
      printCount: intValue('PRINT_COUNT'),
      dateTime: stringValue('DATETIME'),
      dateYYYYMMDD: stringValue('DATE_YYYYMMDD'),
      printerName: stringValue('PRINTER'),
      columnsWire: stringValue('COLUMNS'),
      printCellsWire: stringValue('PRINT_CELLS'),
      savedCellsWire: stringValue('SAVE_IN_DB_CELLS'),
      formWidth: intValue('FORM_WIDTH'),
      formHeight: intValue('FORM_HEIGHT'),
      leftMargin: doubleValue('LEFT_MARGIN'),
      rightMargin: doubleValue('RIGHT_MARGIN'),
      topMargin: doubleValue('TOP_MARGIN'),
      leftPush: doubleValue('LEFT_PUSH'),
      topPush: doubleValue('TOP_PUSH'),
      appendant: doubleValue('APPENDANT'),
      itemId: intValue('ITEM_ID'),
    );
  }

  List<String> get columnNames => _splitWire(columnsWire);
  List<String> get printCells => _splitWire(printCellsWire);
  List<String> get savedCells => _splitWire(savedCellsWire);

  static List<String> _splitWire(String value) {
    final parts = value.split('|');
    if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
    return parts;
  }
}
