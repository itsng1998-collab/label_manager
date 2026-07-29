import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/update_notice/domain/notice.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/utils/log_context.dart';

class NoticeDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(3000), UN_MSG COLLATE ${DAO.CP949}), N'') AS UN_MSG,
      COALESCE(UN_STATE, 0) AS UN_STATE
    FROM
      BM_UPDATE_NOTICE
    WHERE
      LTRIM(RTRIM(CONVERT(NVARCHAR(30),UN_USER_ID COLLATE ${DAO.CP949}))) =
      LTRIM(RTRIM(CONVERT(NVARCHAR(30),@userId)));
  ''';

  static const String selectTargetUsersSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(30), A.RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(50), C.RICH_NAME COLLATE ${DAO.CP949}), N'') AS CUSTOMER_NAME
    FROM BM_USER A
    INNER JOIN BM_MARKET B ON A.RICH_MARKET_ID=B.RICH_MARKET_ID
    INNER JOIN BM_CUSTOMER C ON B.RICH_CUSTOMER_ID=C.RICH_CUSTOMER_ID
    WHERE C.RICH_COOP_ID=@cooperatorId
    ORDER BY C.RICH_NAME
  ''';

  static const String updateSelectedUserSql = '''
    UPDATE BM_UPDATE_NOTICE
       SET UN_MSG=@message, UN_STATE=0, UN_TIME=GETDATE()
     WHERE UN_USER_ID=@userId;
  ''';

  static const String updateAllSql = '''
    UPDATE BM_UPDATE_NOTICE
       SET UN_MSG=@message, UN_STATE=2, UN_TIME=GETDATE();
  ''';

  static const String updateCooperatorSql = '''
    UPDATE BM_UPDATE_NOTICE
       SET UN_MSG=@message, UN_STATE=0, UN_TIME=GETDATE()
     WHERE UN_COOP_ID=@cooperatorId;
  ''';

  static const String updateUserStateSql = '''
    UPDATE BM_UPDATE_NOTICE
       SET UN_STATE=@state, UN_TIME=GETDATE()
     WHERE UN_USER_ID=@userId;
  ''';

  static Future<Notice> selectNoticeByUserId(String userId) async {
    final result = await DbClient.instance.getDataWithParams(selectSql, {
      'userId': userId,
    });
    final map = DAO.getRowMapFromResult(result);
    if (map == null) throw StateError('업데이트 메시지를 찾을 수 없습니다.');
    return Notice.fromMap(map);
  }

  static Future<String> selectByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      final res = await DbClient.instance.getDataWithParams(selectSql, {
        'userId': userId,
      });

      final map = DAO.getRowMapFromResult(res);

      debugLog(END);
      return Notice.fromMap(map!).message;
    } catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<List<NoticeTargetUser>> selectTargetUsers(
    String cooperatorId,
  ) async {
    final result = await DbClient.instance.getDataWithParams(
      selectTargetUsersSql,
      {'cooperatorId': cooperatorId},
    );
    return DAO.mapRows(result, NoticeTargetUser.fromMap);
  }

  static DbTransactionStatement selectedUserStatement({
    required String userId,
    required String message,
  }) => DbTransactionStatement(
    sql: updateSelectedUserSql,
    params: {'userId': userId, 'message': message},
  );

  static Future<void> updateSelectedUsers({
    required List<String> userIds,
    required String message,
  }) {
    if (userIds.isEmpty) {
      throw ArgumentError.value(userIds, 'userIds', '사용자를 선택해주세요.');
    }
    return DbClient.instance.transaction([
      for (final userId in userIds)
        selectedUserStatement(userId: userId, message: message),
    ]);
  }

  static Future<void> updateAll(String message) =>
      DbClient.instance.transaction([
        DbTransactionStatement(sql: updateAllSql, params: {'message': message}),
      ]);

  static Future<void> updateCooperator({
    required String cooperatorId,
    required String message,
  }) => DbClient.instance.transaction([
    DbTransactionStatement(
      sql: updateCooperatorSql,
      params: {'cooperatorId': cooperatorId, 'message': message},
    ),
  ]);

  static Future<void> updateUserState({
    required String userId,
    required bool dontShowAgain,
  }) => DbClient.instance.transaction([
    DbTransactionStatement(
      sql: updateUserStateSql,
      params: {'userId': userId, 'state': dontShowAgain ? 1 : 0},
    ),
  ]);
}
