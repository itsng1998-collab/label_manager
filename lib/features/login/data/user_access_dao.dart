import 'package:label_manager/database/dao.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/utils/log_context.dart';

class UserAccessDAO extends DAO {
  static const selectSql = '''
    SELECT CONVERT(NVARCHAR(17), ACCESS_DATA) AS ACCESS_DATA
    FROM BM_USER_ACCESS
    WHERE USER_ID=@userId
  ''';

  static const saveSql = '''
    SET NOCOUNT ON;
    DECLARE @accessData VARCHAR(17) =
      CONVERT(CHAR(8), GETDATE(), 112) +
      REPLACE(CONVERT(CHAR(12), GETDATE(), 114), ':', '');

    IF EXISTS (SELECT 1 FROM BM_USER_ACCESS WHERE USER_ID=@userId)
      UPDATE BM_USER_ACCESS
      SET USER_NAME=@userName, ACCESS_DATA=@accessData
      WHERE USER_ID=@userId;
    ELSE
      INSERT INTO BM_USER_ACCESS (USER_ID, USER_NAME, ACCESS_MAC, ACCESS_DATA)
      VALUES (@userId, @userName, '', @accessData);

    INSERT INTO BM_USER_ACCESS_LOG
    SELECT USER_ID, USER_NAME, ACCESS_MAC, ACCESS_DATA,
           CONVERT(CHAR(8), GETDATE(), 112), GETDATE()
    FROM BM_USER_ACCESS
    WHERE USER_ID=@userId;

    SELECT @accessData AS ACCESS_DATA;
  ''';

  static Future<String?> selectAccessData(String userId) async {
    final result = await DbClient.instance.getDataWithParams(selectSql, {
      'userId': userId,
    });
    final row = DAO.getRowMapFromResult(result, throwIfNoRows: false);
    return row?['ACCESS_DATA']?.toString();
  }

  static Future<String> saveAccess({
    required String userId,
    required String userName,
  }) async {
    final results = await DbClient.instance.transaction([
      DbTransactionStatement(
        sql: saveSql,
        params: {'userId': userId, 'userName': userName},
        returnsRows: true,
      ),
    ]);
    final row = DAO.getRowMapFromResult(results.single);
    final accessData = row?['ACCESS_DATA']?.toString() ?? '';
    if (accessData.length != 17) {
      throw Exception('${runtimeLogTag()} Invalid user access data');
    }
    return accessData;
  }
}