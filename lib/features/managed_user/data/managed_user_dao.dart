import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/managed_user/domain/managed_user.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class ManagedUserDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(30), P1.RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_MARKET_ID), N'') AS MARKET_ID,
      COALESCE(CONVERT(NVARCHAR(50), P1.RICH_NAME COLLATE ${DAO.CP949}), N'') AS NAME,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_PWD COLLATE ${DAO.CP949}), N'') AS PASSWORD,
      COALESCE(CONVERT(NVARCHAR(20), P1.RICH_USER_GRADE), N'') AS GRADE,
      COALESCE(CONVERT(NVARCHAR(50), P2.RICH_NAME COLLATE ${DAO.CP949}), N'') AS MARKET_NAME,
      COALESCE(CONVERT(NVARCHAR(50), P3.RICH_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME
    FROM BM_USER P1
    INNER JOIN BM_MARKET P2 ON P1.RICH_MARKET_ID=P2.RICH_MARKET_ID
    INNER JOIN BM_CUSTOMER P3 ON P2.RICH_CUSTOMER_ID=P3.RICH_CUSTOMER_ID
    INNER JOIN BM_COOPERATOR P4 ON P3.RICH_COOP_ID=P4.RICH_COOP_ID
  ''';

  static const String whereMarketSql = '''
    WHERE P1.RICH_MARKET_ID=@marketId
      AND P1.RICH_USER_GRADE<>0
  ''';

  static const String whereCooperatorSql = '''
    WHERE P4.RICH_COOP_ID=@cooperatorId
      AND P1.RICH_USER_GRADE<>0
    ORDER BY P3.RICH_CUSTOMER_ID, P2.RICH_MARKET_ID
  ''';

  static const String whereUserIdSql = '''
    WHERE P1.RICH_USER_ID=@userId
  ''';

  static const String insertSql = '''
    INSERT INTO BM_USER
      (RICH_USER_ID, RICH_MARKET_ID, RICH_NAME, RICH_PWD, RICH_USER_GRADE)
    VALUES (@userId, @marketId, @name, @password, @grade)
  ''';

  static const String updateSql = '''
    UPDATE BM_USER
       SET RICH_USER_ID=@userId,
           RICH_MARKET_ID=@marketId,
           RICH_NAME=@name,
           RICH_PWD=@password,
           RICH_USER_GRADE=@grade
     WHERE RICH_USER_ID=@originalUserId
  ''';

  static const String deleteSql = '''
    DELETE FROM BM_USER WHERE RICH_USER_ID=@userId
  ''';

  static Future<List<ManagedUser>> selectByMarketId(int marketId) async {
    final result = await DbClient.instance.getDataWithParams(
      '$selectSql $whereMarketSql',
      {'marketId': marketId},
    );
    return DAO.mapRows(result, ManagedUser.fromMap);
  }

  static Future<List<ManagedUser>> selectByCooperatorId(
    String cooperatorId,
  ) async {
    final result = await DbClient.instance.getDataWithParams(
      '$selectSql $whereCooperatorSql',
      {'cooperatorId': cooperatorId},
    );
    return DAO.mapRows(result, ManagedUser.fromMap);
  }

  static Future<ManagedUser?> selectByUserId(String userId) async {
    final result = await DbClient.instance.getDataWithParams(
      '$selectSql $whereUserIdSql',
      {'userId': userId},
    );
    final row = DAO.getRowMapFromResult(result);
    return row == null ? null : ManagedUser.fromMap(row);
  }

  static Future<void> insert(ManagedUser user) async {
    final result = await DbClient.instance.writeDataWithParams(
      insertSql,
      _params(user),
    );
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('${runtimeLogTag()} Insert failed for managed user');
    }
  }

  static Future<void> update(String originalUserId, ManagedUser user) async {
    final result = await DbClient.instance.writeDataWithParams(updateSql, {
      ..._params(user),
      'originalUserId': originalUserId,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('${runtimeLogTag()} Update failed for managed user');
    }
  }

  static Future<void> delete(String userId) async {
    final result = await DbClient.instance.writeDataWithParams(deleteSql, {
      'userId': userId,
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('${runtimeLogTag()} Delete failed for managed user');
    }
  }

  static Map<String, dynamic> _params(ManagedUser user) => {
    'userId': user.userId,
    'marketId': user.marketId,
    'name': user.name,
    'password': user.password,
    'grade': user.grade.code,
  };
}
