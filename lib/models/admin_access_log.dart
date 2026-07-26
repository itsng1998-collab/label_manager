// ignore_for_file: constant_identifier_names

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_result_utils.dart';
import 'package:label_manager/models/dao.dart';
import 'package:r_get_ip/r_get_ip.dart';

class AdminAccessLogDAO extends DAO {
  static const String InsertSql = '''
    INSERT INTO BM_ADMIN_ACCESS_LOG
      (ACCESS_USER_ID, ACCESS_TARGET_USER_ID, ACCESS_TARGET_CUSTOMER,
       ACCESS_INNER_IP, ACCESS_OUTER_IP, ACCESS_DATETIME)
    VALUES
      (CONVERT(VARCHAR(30), CONVERT(VARBINARY(100), @accessUserId, 1)) COLLATE ${DAO.CP949},
       CONVERT(VARCHAR(30), CONVERT(VARBINARY(100), @targetUserId, 1)) COLLATE ${DAO.CP949},
       @targetCustomerId,
       CONVERT(VARCHAR(48), CONVERT(VARBINARY(100), @innerIp, 1)) COLLATE ${DAO.CP949},
       CONVERT(VARCHAR(48), CONNECTIONPROPERTY('client_net_address')),
       GETDATE())
  ''';

  static Future<void> insert({
    required String accessUserId,
    required String targetUserId,
    required int targetCustomerId,
  }) async {
    final innerIp = await RGetIp.internalIP;
    final result = await DbClient.instance.writeDataWithParams(InsertSql, {
      'accessUserId': await stringToHexCp949(accessUserId),
      'targetUserId': await stringToHexCp949(targetUserId),
      'targetCustomerId': targetCustomerId,
      'innerIp': await stringToHexCp949(innerIp!),
    });
    if (DAO.affectedRows(result) <= 0) {
      throw Exception('Admin access log insert failed');
    }
  }
}