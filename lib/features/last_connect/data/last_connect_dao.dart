import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/last_connect/domain/last_connect.dart';
import 'package:label_manager/database/dao.dart';
import 'package:label_manager/utils/log_context.dart';

LastConnect lastConnectFromRow(Map<String, dynamic> row) {
  String stringValue(String key) => (row[key] ?? '').toString();
  int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;

  return LastConnect(
    userId: stringValue('USER_ID'),
    brandId: intValue('BRAND_ID'),
    labelSizeId: intValue('LABELSIZE_ID'),
  );
}

class LastConnectDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_LAST_BRAND_ID), N'') AS BRAND_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_LAST_SIZE_ID), N'') AS LABELSIZE_ID
    FROM BM_RICH_LAST_ID
  ''';

  static const String whereSqlUserId = '''
    WHERE RICH_USER_ID=@userId
  ''';

  static const String deleteSqlByBrandId = '''
    DELETE FROM BM_RICH_LAST_ID
     WHERE RICH_LAST_BRAND_ID=@brandId
  ''';

  static const String deleteSqlByLabelSizeId = '''
    DELETE FROM BM_RICH_LAST_ID
     WHERE RICH_LAST_SIZE_ID=@labelSizeId
  ''';

  static Future<LastConnect?> selectByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlUserId',
        {'userId': userId},
      );
      final lastConnect = DAO.mapRow(
        result,
        lastConnectFromRow,
        throwIfNoRows: false,
      );

      debugLog('$END, lastConnect:$lastConnect');
      return lastConnect;
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> insert(LastConnect lastConnect) async {
    debugLog(
      '$START, userId:${lastConnect.userId}, brandId:${lastConnect.brandId}, labelSizeId:${lastConnect.labelSizeId}',
    );

    try {
      const insertSql = '''
        INSERT INTO BM_RICH_LAST_ID
          (RICH_USER_ID, RICH_LAST_BRAND_ID, RICH_LAST_SIZE_ID)
        VALUES
          (@userId, @brandId, @labelSizeId)
      ''';
      final result = await DbClient.instance.writeDataWithParams(insertSql, {
        'userId': lastConnect.userId,
        'brandId': lastConnect.brandId,
        'labelSizeId': lastConnect.labelSizeId,
      });
      final affected = DAO.affectedRows(result);
      final succeeded = affected > 0;
      if (!succeeded) {
        throw Exception(
          '${runtimeLogTag()} Insert failed for userId:${lastConnect.userId}',
        );
      }

      debugLog(
        '$END, BM_RICH_LAST_ID insert Result: $result, affected:$affected, succeeded:$succeeded',
      );
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> update(LastConnect lastConnect) async {
    debugLog(
      '$START, userId:${lastConnect.userId}, brandId:${lastConnect.brandId}, labelSizeId:${lastConnect.labelSizeId}',
    );

    try {
      const updateSql = '''
        UPDATE BM_RICH_LAST_ID
           SET RICH_LAST_BRAND_ID=@brandId,
               RICH_LAST_SIZE_ID=@labelSizeId
         WHERE RICH_USER_ID=@userId
      ''';
      final result = await DbClient.instance.writeDataWithParams(updateSql, {
        'userId': lastConnect.userId,
        'brandId': lastConnect.brandId,
        'labelSizeId': lastConnect.labelSizeId,
      });
      final affected = DAO.affectedRows(result);
      final succeeded = affected > 0;
      if (!succeeded) {
        throw Exception(
          '${runtimeLogTag()} Update failed for userId:${lastConnect.userId}',
        );
      }

      debugLog(
        '$END, BM_RICH_LAST_ID update Result: $result, affected:$affected, succeeded:$succeeded',
      );
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> upsert(LastConnect lastConnect) async {
    debugLog(
      '$START, userId:${lastConnect.userId}, brandId:${lastConnect.brandId}, labelSizeId:${lastConnect.labelSizeId}',
    );

    try {
      if (await isExistByUserId(lastConnect.userId)) {
        await update(lastConnect);
      } else {
        await insert(lastConnect);
      }
      debugLog(END);
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> delete(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      await _deleteBySql('DELETE FROM BM_RICH_LAST_ID $whereSqlUserId', {
        'userId': userId,
      });
      debugLog(END);
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<bool> isExistByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      final result = await DbClient.instance.getDataWithParams(
        '$selectSql $whereSqlUserId',
        {'userId': userId},
      );
      final exists =
          DAO.getRowMapFromResult(result, throwIfNoRows: false) != null;

      debugLog('$END, exists:$exists');
      return exists;
    } catch (error) {
      debugLog('$END, $error');
      rethrow;
    }
  }

  static Future<void> _deleteBySql(
    String sql,
    Map<String, Object?> params,
  ) async {
    final result = await DbClient.instance.writeDataWithParams(sql, params);
    final affected = DAO.affectedRows(result);
    debugLog('BM_RICH_LAST_ID delete Result: $result, affected:$affected');
  }
}
