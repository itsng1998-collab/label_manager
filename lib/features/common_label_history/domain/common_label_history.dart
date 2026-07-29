class CommonLabelHistoryPayload {
  const CommonLabelHistoryPayload({required this.sheet, required this.rtf});

  final String sheet;
  final String rtf;

  bool get usesSheet => sheet.isNotEmpty;
  String get value => usesSheet ? sheet : rtf;
}

class CommonLabelHistory {
  const CommonLabelHistory({
    required this.logId,
    required this.modifiedAt,
    required this.userId,
    required this.brandName,
    required this.labelSizeName,
    required this.beforeWidth,
    required this.beforeHeight,
    required this.beforeFormData,
    required this.beforeFormSheet,
    required this.afterWidth,
    required this.afterHeight,
    required this.afterFormData,
    required this.afterFormSheet,
    required this.innerIp,
    required this.outerIp,
  });

  final int logId;
  final String modifiedAt;
  final String userId;
  final String brandName;
  final String labelSizeName;
  final int beforeWidth;
  final int beforeHeight;
  final String beforeFormData;
  final String beforeFormSheet;
  final int afterWidth;
  final int afterHeight;
  final String afterFormData;
  final String afterFormSheet;
  final String innerIp;
  final String outerIp;

  CommonLabelHistoryPayload get beforePayload =>
      CommonLabelHistoryPayload(sheet: beforeFormSheet, rtf: beforeFormData);

  CommonLabelHistoryPayload get afterPayload =>
      CommonLabelHistoryPayload(sheet: afterFormSheet, rtf: afterFormData);

  factory CommonLabelHistory.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

    return CommonLabelHistory(
      logId: intValue('LOG_ID'),
      modifiedAt: stringValue('MODIFIED_AT'),
      userId: stringValue('USER_ID'),
      brandName: stringValue('BRAND_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      beforeWidth: intValue('BEFORE_WIDTH'),
      beforeHeight: intValue('BEFORE_HEIGHT'),
      beforeFormData: stringValue('BEFORE_FORM_DATA'),
      beforeFormSheet: stringValue('BEFORE_FORM_SHEET'),
      afterWidth: intValue('AFTER_WIDTH'),
      afterHeight: intValue('AFTER_HEIGHT'),
      afterFormData: stringValue('AFTER_FORM_DATA'),
      afterFormSheet: stringValue('AFTER_FORM_SHEET'),
      innerIp: stringValue('INNER_IP'),
      outerIp: stringValue('OUTER_IP'),
    );
  }
}
