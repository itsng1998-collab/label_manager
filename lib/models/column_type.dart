// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

class TColumnType {
  static const int TYPE_BASE = 0;
  static const int TYPE_VALIDDATE = 1;
  static const int TYPE_VALIDTIME = 2;
  static const int TYPE_BARCODE = 3;
  static const int TYPE_IMAGE = 4;
  static const int TYPE_FIX = 5;
  static const int TYPE_MAKEDATE = 6;
  static const int TYPE_MAKETIME = 7;
  static const int TYPE_NUT = 8;
  static const int TYPE_QR_CODE = 9;
  static const int TYPE_PRINTCOUNT = 10;
  static const int TYPE_GS1_AI = 11;
  static const int TYPE_GS1_BARCODE = 12;
  static const int TYPE_END_OF_CULUMN = 13;

  final int code;
  final String name;
  final int order;

  const TColumnType({
    required this.code,
    required this.name,
    required this.order,
  });

  factory TColumnType.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    dynamic v(String key) => map[key];
    return TColumnType(
      code: v('RICH_COLUMN_TYPE_CODE'),
      name: s('RICH_COLUMN_TYPE_NAME'),
      order: v('RICH_COLUMN_TYPE_ORDER'),
    );
  }

  static List<TColumnType>? datas;

  static TColumnType getFromCode(int code) {
    final columns = datas;
    if (columns == null || columns.isEmpty) {
      throw StateError('TColumnType.datas is not initialized');
    }
    return columns.firstWhere(
      (e) => e.code == code,
      orElse: () => columns.firstWhere(
        (e) => e.code == TYPE_BASE,
        orElse: () => columns.first,
      ),
    );
  }

  static Future<void> init() async {
    try {
      debugLog(START);
      if (datas != null) return;

      final sql =
          '''
        SELECT
          RICH_COLUMN_TYPE_CODE,
          COALESCE(CONVERT(NVARCHAR(100), RICH_COLUMN_TYPE_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_TYPE_NAME,
          RICH_COLUMN_TYPE_ORDER
        FROM BM_RICH_COLUMN_TYPE
        ORDER BY RICH_COLUMN_TYPE_ORDER ASC
      ''';

      final res = await DbClient.instance.getData(sql);
      datas = DAO.mapRows(res, TColumnType.fromMap);
    } catch (e) {
      throw Exception(e);
    } finally {
      debugLog(END);
    }
  }

  @override
  String toString() => 'code: $code, name: $name, order: $order';
}
