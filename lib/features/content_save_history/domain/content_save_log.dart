import 'dart:math' as math;

enum ContentSaveStatus {
  newItem(0),
  modified(1);

  const ContentSaveStatus(this.code);

  final int code;

  static ContentSaveStatus fromCode(int code) =>
      code == newItem.code ? newItem : modified;

  String get label => this == newItem ? '신규' : '수정';
}

class ContentSaveLogDetail {
  const ContentSaveLogDetail({required this.columnName, required this.content});

  final String columnName;
  final String content;
}

class ContentSaveLog {
  const ContentSaveLog({
    required this.logId,
    required this.userId,
    required this.userGrade,
    required this.customerId,
    required this.customerName,
    required this.labelSizeName,
    required this.itemName,
    required this.goodsNumber,
    required this.contentColumnsWire,
    required this.contentsWire,
    required this.saveDate,
    required this.saveDateYYYYMMDD,
    required this.saveIp,
    required this.saveStatus,
    required this.elementRtf,
  });

  final int logId;
  final String userId;
  final String userGrade;
  final int customerId;
  final String customerName;
  final String labelSizeName;
  final String itemName;
  final int goodsNumber;
  final String contentColumnsWire;
  final String contentsWire;
  final String saveDate;
  final String saveDateYYYYMMDD;
  final String saveIp;
  final ContentSaveStatus saveStatus;
  final String elementRtf;

  factory ContentSaveLog.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

    return ContentSaveLog(
      logId: intValue('LOG_ID'),
      userId: stringValue('USER_ID'),
      userGrade: stringValue('USER_GRADE'),
      customerId: intValue('CUSTOMER_ID'),
      customerName: stringValue('CUSTOMER_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      itemName: stringValue('ITEM_NAME'),
      goodsNumber: intValue('GDS_NO'),
      contentColumnsWire: stringValue('CONTENT_COLUMNS'),
      contentsWire: stringValue('CONTENTS'),
      saveDate: stringValue('SAVE_DATE'),
      saveDateYYYYMMDD: stringValue('SAVE_DATE_YYYYMMDD'),
      saveIp: stringValue('SAVE_IP'),
      saveStatus: ContentSaveStatus.fromCode(intValue('SAVE_STATUS')),
      elementRtf: stringValue('ELEMENT_DATA'),
    );
  }

  List<ContentSaveLogDetail> get details {
    final columns = _splitWire(contentColumnsWire);
    final contents = _splitWire(contentsWire);
    final count = math.min(columns.length, contents.length);
    return [
      for (var index = 0; index < count; index += 1)
        ContentSaveLogDetail(
          columnName: columns[index],
          content: contents[index],
        ),
    ];
  }

  static List<String> _splitWire(String value) {
    final parts = value.split('\n');
    if (parts.isNotEmpty && parts.last.isEmpty) parts.removeLast();
    return parts;
  }
}
