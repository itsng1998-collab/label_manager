// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';

enum CooperatorGrade {
	COOP_GRADE_SYS_ADMIN(0),
	COOP_GRADE_COOP_MANAGER(1);

  final int code;
  const CooperatorGrade(this.code);
  static CooperatorGrade fromCode(int code) => CooperatorGrade.values.firstWhere((e) => e.code == code);

  String get label {
    switch (this) {
      case CooperatorGrade.COOP_GRADE_SYS_ADMIN:
        return '시스템 관리자';
      case CooperatorGrade.COOP_GRADE_COOP_MANAGER:
        return '협력업체 책임자';
    }
  }
}

class Cooperator {
  static Cooperator? instance;

	final String id;
	final String name;

  const Cooperator({
    required this.id,
    required this.name,
  });

  static void setInstance(Cooperator? cooperator) {
    instance = cooperator;
  }

  factory Cooperator.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();

    return Cooperator(
      id:   s('COOP_ID'),
      name: s('NAME'),
    );
  }

  @override
  String toString() => 'CooperatorId: $id, Name: $name';
}

class CooperatorDAO extends DAO {
  static const String SelectSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(30), RICH_COOP_ID COLLATE ${DAO.CP949}), N'') AS COOP_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME
    FROM BM_COOPERATOR
  ''';

  static const String WhereSqlCooperatorId = '''
    WHERE LTRIM(RTRIM(CONVERT(NVARCHAR(30),RICH_COOP_ID COLLATE ${DAO.CP949}))) =
          LTRIM(RTRIM(CONVERT(NVARCHAR(30),@cooperatorId)))
  ''';

  static const String InsertSql = '''
    INSERT INTO BM_COOPERATOR (RICH_COOP_ID, RICH_NAME)
    VALUES (@cooperatorId, @name)
  ''';

  static const String UpdateSql = '''
    UPDATE BM_COOPERATOR
       SET RICH_COOP_ID=@cooperatorId,
           RICH_NAME=@name
     WHERE RICH_COOP_ID=@oldCooperatorId
  ''';

  static const String DeleteSql = '''
    DELETE FROM BM_COOPERATOR
     WHERE RICH_COOP_ID=@cooperatorId
  ''';

  static Future<List<Cooperator>> selectAll() async {
    debugLog(START);
    try {
      final result = await DbClient.instance.getData(SelectSql);
      final rows = DAO.getRowsFromResult(result)
          .whereType<Map>()
          .map((row) => Cooperator.fromMap(Map<String, dynamic>.from(row)))
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
				'$SelectSql $WhereSqlCooperatorId', { 'cooperatorId': cooperatorId }
			);

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return Cooperator.fromMap(map!);
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> insert(Cooperator cooperator) async {
    try {
      final result = await DbClient.instance.writeDataWithParams(InsertSql, {
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
      final result = await DbClient.instance.writeDataWithParams(UpdateSql, {
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
      final result = await DbClient.instance.writeDataWithParams(DeleteSql, {
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
