import 'dart:math' as math;

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';

import 'dao.dart';

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

class ContentSaveLogDAO extends DAO {
  static const String selectBetweenDatesAndCustomerSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), CONTENT_SAVE_LOG_ID), N'') AS LOG_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(30), USER_GRADE COLLATE ${DAO.CP949}), N'') AS USER_GRADE,
      COALESCE(CONVERT(NVARCHAR(20), CUST_ID), N'') AS CUSTOMER_ID,
      COALESCE(CONVERT(NVARCHAR(50), CUST_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME,
      COALESCE(CONVERT(NVARCHAR(50), LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(100), ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(20), GDS_NO), N'') AS GDS_NO,
      COALESCE(CONVERT(NVARCHAR(MAX), CONTENT_COLUMNS COLLATE ${DAO.CP949}), N'') AS CONTENT_COLUMNS,
      COALESCE(CONVERT(NVARCHAR(MAX), CONTENTS COLLATE ${DAO.CP949}), N'') AS CONTENTS,
      COALESCE(CONVERT(NVARCHAR(30), SAVE_DATE, 120), N'') AS SAVE_DATE,
      COALESCE(CONVERT(NVARCHAR(8), SAVE_DATE_YYYYMMDD COLLATE ${DAO.CP949}), N'') AS SAVE_DATE_YYYYMMDD,
      COALESCE(CONVERT(NVARCHAR(100), SAVE_IP COLLATE ${DAO.CP949}), N'') AS SAVE_IP,
      COALESCE(CONVERT(NVARCHAR(20), SAVE_STATUS), N'') AS SAVE_STATUS,
      COALESCE(CONVERT(NVARCHAR(MAX), ELEMENT_DATA COLLATE ${DAO.CP949}), N'') AS ELEMENT_DATA
    FROM BM_CONTENT_SAVE_LOG
    WHERE SAVE_DATE_YYYYMMDD BETWEEN CONVERT(VARCHAR(8), @startDate)
      AND CONVERT(VARCHAR(8), @endDate)
      AND CUST_ID=@customerId
    ORDER BY SAVE_DATE ASC
  ''';

  static Future<List<ContentSaveLog>> selectBetweenDatesAndCustomer({
    required String startDate,
    required String endDate,
    required int customerId,
  }) async {
    try {
      final result = await DbClient.instance.getDataWithParams(
        selectBetweenDatesAndCustomerSql,
        {'startDate': startDate, 'endDate': endDate, 'customerId': customerId},
      );
      return DAO
          .getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => ContentSaveLog.fromMap(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    } catch (error) {
      throw Exception('${runtimeLogTag()} $error');
    }
  }
}
