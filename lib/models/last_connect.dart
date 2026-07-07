// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';

import 'dao.dart';

class LastConnect {
  final String userId;
  final int brandId;
  final int labelSizeId;

  const LastConnect({
    required this.userId,
    required this.brandId,
    required this.labelSizeId,
  });

  factory LastConnect.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();
    int i(String key) => int.tryParse(s(key)) ?? 0;

    return LastConnect(
      userId: s('USER_ID'),
      brandId: i('BRAND_ID'),
      labelSizeId: i('LABELSIZE_ID'),
    );
  }

  @override
  String toString() =>
      'UserId: $userId, BrandId: $brandId, LabelSizeId: $labelSizeId';
}

class LastConnectDAO extends DAO {
  static const String SelectSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_ID COLLATE ${DAO.CP949}), N'') AS USER_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_LAST_BRAND_ID), N'') AS BRAND_ID,
      COALESCE(CONVERT(NVARCHAR(20), RICH_LAST_SIZE_ID), N'') AS LABELSIZE_ID
    FROM BM_RICH_LAST_ID
  ''';

  static const String WhereSqlUserId = '''
    WHERE RICH_USER_ID=@userId
  ''';

  static const String WhereSqlBrandId = '''
    WHERE RICH_LAST_BRAND_ID=@brandId
  ''';

  static const String WhereSqlLabelSizeId = '''
    WHERE RICH_LAST_SIZE_ID=@labelSizeId
  ''';

  static const String DeleteSqlByBrandId = '''
    DELETE FROM BM_RICH_LAST_ID
     WHERE RICH_LAST_BRAND_ID=@brandId
  ''';

  static const String DeleteSqlByLabelSizeId = '''
    DELETE FROM BM_RICH_LAST_ID
     WHERE RICH_LAST_SIZE_ID=@labelSizeId
  ''';

  static Future<LastConnect?> selectByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlUserId',
        {'userId': userId},
      );

      final lastConnect = DAO.mapRow(
        res,
        LastConnect.fromMap,
        throwIfNoRows: false,
      );

      debugLog('$END, lastConnect:$lastConnect');
      return lastConnect;
    } catch (e) {
      debugLog('$END, $e');
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

      final res = await DbClient.instance.writeDataWithParams(insertSql, {
        'userId': lastConnect.userId,
        'brandId': lastConnect.brandId,
        'labelSizeId': lastConnect.labelSizeId,
      });

      final affected = DAO.affectedRows(res);
      final succeeded = affected > 0;
      if (!succeeded) {
        throw Exception(
          '${runtimeLogTag()} Insert failed for userId:${lastConnect.userId}',
        );
      }

      debugLog(
        '$END, BM_RICH_LAST_ID insert Result: $res, affected:$affected, succeeded:$succeeded',
      );
    } catch (e) {
      debugLog('$END, $e');
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

      final res = await DbClient.instance.writeDataWithParams(updateSql, {
        'userId': lastConnect.userId,
        'brandId': lastConnect.brandId,
        'labelSizeId': lastConnect.labelSizeId,
      });

      final affected = DAO.affectedRows(res);
      final succeeded = affected > 0;
      if (!succeeded) {
        throw Exception(
          '${runtimeLogTag()} Update failed for userId:${lastConnect.userId}',
        );
      }

      debugLog(
        '$END, BM_RICH_LAST_ID update Result: $res, affected:$affected, succeeded:$succeeded',
      );
    } catch (e) {
      debugLog('$END, $e');
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
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<void> delete(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      await _deleteByWhere(
        WhereSqlUserId,
        {'userId': userId},
      );
      debugLog(END);
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<void> deleteByBrandId(int brandId) async {
    debugLog('$START, brandId:$brandId');

    try {
      await _deleteBySql(
        DeleteSqlByBrandId,
        {'brandId': brandId},
      );
      debugLog(END);
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<void> deleteByLabelSizeId(int labelSizeId) async {
    debugLog('$START, labelSizeId:$labelSizeId');

    try {
      await _deleteBySql(
        DeleteSqlByLabelSizeId,
        {'labelSizeId': labelSizeId},
      );
      debugLog(END);
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<bool> isExistByUserId(String userId) async {
    debugLog('$START, userId:$userId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlUserId',
        {'userId': userId},
      );
      final exists = DAO.getRowMapFromResult(res, throwIfNoRows: false) != null;

      debugLog('$END, exists:$exists');
      return exists;
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }

  static Future<void> _deleteByWhere(
    String whereSql,
    Map<String, Object?> params,
  ) async {
    await _deleteBySql('DELETE FROM BM_RICH_LAST_ID $whereSql', params);
  }

  static Future<void> _deleteBySql(
    String sql,
    Map<String, Object?> params,
  ) async {
    final res = await DbClient.instance.writeDataWithParams(
      sql,
      params,
    );

    final affected = DAO.affectedRows(res);

    debugLog(
      'BM_RICH_LAST_ID delete Result: $res, affected:$affected',
    );
  }
}
