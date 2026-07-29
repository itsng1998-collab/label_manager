// UTF-8, 한국어 주석

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/models/dao.dart';

Cooperator cooperatorFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();

  return Cooperator(
    id: stringValue('COOP_ID'),
    name: stringValue('NAME'),
  );
}

class CooperatorDAO extends DAO {
  static const String selectSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(30), RICH_COOP_ID COLLATE ${DAO.CP949}), N'') AS COOP_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME
    FROM BM_COOPERATOR
  ''';

  static const String whereSqlCooperatorId = '''
    WHERE LTRIM(RTRIM(CONVERT(NVARCHAR(30),RICH_COOP_ID COLLATE ${DAO.CP949}))) =
          LTRIM(RTRIM(CONVERT(NVARCHAR(30),@cooperatorId)))
  ''';

  static const String insertSql = '''
    INSERT INTO BM_COOPERATOR (RICH_COOP_ID, RICH_NAME)
    VALUES (@cooperatorId, @name)
  ''';

  static const String updateSql = '''
    UPDATE BM_COOPERATOR
       SET RICH_COOP_ID=@cooperatorId,
           RICH_NAME=@name
     WHERE RICH_COOP_ID=@oldCooperatorId
  ''';

  static const String deleteSql = '''
    DELETE FROM BM_COOPERATOR
     WHERE RICH_COOP_ID=@cooperatorId
  ''';

  static Future<List<Cooperator>> selectAll() async {
    debugLog(START);
    try {
      final result = await DbClient.instance.getData(selectSql);
      final rows = DAO.getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => cooperatorFromRow(Map<String, dynamic>.from(row)))
          .toList(growable: false);
      debugLog(END);
      return rows;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<Cooperator?> selectByCooperatorId(String cooperatorId) async {
    debugLog('$START, cooperatorId:$cooperatorId');

    try {
			final res = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlCooperatorId', { 'cooperatorId': cooperatorId }
			);

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return cooperatorFromRow(map!);
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> insert(Cooperator cooperator) async {
    try {
      final result = await DbClient.instance.writeDataWithParams(insertSql, {
        'cooperatorId': cooperator.id,
        'name': cooperator.name,
      });
      if (DAO.affectedRows(result) <= 0) {
        throw Exception('${runtimeLogTag()} Insert failed for cooperatorId:${cooperator.id}');
      }
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> update(
    String oldCooperatorId,
    Cooperator cooperator,
  ) async {
    try {
      final result = await DbClient.instance.writeDataWithParams(updateSql, {
        'oldCooperatorId': oldCooperatorId,
        'cooperatorId': cooperator.id,
        'name': cooperator.name,
      });
      if (DAO.affectedRows(result) <= 0) {
        throw Exception('${runtimeLogTag()} Update failed for cooperatorId:$oldCooperatorId');
      }
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> delete(String cooperatorId) async {
    try {
      final result = await DbClient.instance.writeDataWithParams(deleteSql, {
        'cooperatorId': cooperatorId,
      });
      if (DAO.affectedRows(result) <= 0) {
        throw Exception('${runtimeLogTag()} Delete failed for cooperatorId:$cooperatorId');
      }
    } catch (_) {
      rethrow;
    }
  }
}
