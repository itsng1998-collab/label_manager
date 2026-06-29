// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';

class NoticeDAO extends DAO {
  static const String Sql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(3000), UN_MSG COLLATE ${DAO.CP949}), N'') AS UN_MSG
    FROM
      BM_UPDATE_NOTICE
    WHERE
      LTRIM(RTRIM(CONVERT(NVARCHAR(30),UN_USER_ID COLLATE ${DAO.CP949}))) =
      LTRIM(RTRIM(CONVERT(NVARCHAR(30),@userId)));
  ''';
 
  static Future<String> getByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
			final res = await DbClient.instance.getDataWithParams(
        Sql, { 'userId': userId }
			);

      final map = DAO.getRowMapFromResult(res);
      
      debugLog(END);
      return map!.values.first as String;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }
}
