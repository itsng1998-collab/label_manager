import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/nutrition/domain/nutrition_box.dart';
import 'package:label_manager/database/dao.dart';

class NutritionBoxDAO extends DAO {
  static const String selectSql =
      '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), B.RICH_NUTBOX_ID), N'') AS NUTBOX_ID,
      COALESCE(CONVERT(NVARCHAR(20), T.RICH_NUTTYPE_ID), N'') AS NUTTYPE_ID,
      COALESCE(CONVERT(NVARCHAR(MAX), B.RICH_NUTBOX_DATA COLLATE ${DAO.CP949}), N'') AS NUTBOX_DATA,
      COALESCE(CONVERT(NVARCHAR(50), T.RICH_NUTTYPE_NAME COLLATE ${DAO.CP949}), N'') AS NUTTYPE_NAME,
      COALESCE(CONVERT(NVARCHAR(50), B.RICH_NUTBOX_NAME COLLATE ${DAO.CP949}), N'') AS NUTBOX_NAME,
      COALESCE(CONVERT(NVARCHAR(20), B.RICH_NUTBOX_WIDTH), N'') AS NUTBOX_WIDTH
    FROM BM_RICH_NUTBOX B
    INNER JOIN BM_RICH_NUTTYPE T
      ON B.RICH_NUTBOX_TYPE=T.RICH_NUTTYPE_ID
    ORDER BY T.RICH_NUTTYPE_ID
  ''';

  static const String insertSql = '''
    INSERT INTO BM_RICH_NUTBOX (
      RICH_NUTBOX_TYPE,
      RICH_NUTBOX_NAME,
      RICH_NUTBOX_DATA,
      RICH_NUTBOX_WIDTH
    ) VALUES (@typeId, @name, @rtf, @width);
  ''';

  static const String updateSql = '''
    UPDATE BM_RICH_NUTBOX
       SET RICH_NUTBOX_TYPE=@typeId,
           RICH_NUTBOX_NAME=@name,
           RICH_NUTBOX_DATA=@rtf,
           RICH_NUTBOX_WIDTH=@width
     WHERE RICH_NUTBOX_ID=@boxId;
    IF @@ROWCOUNT<>1
      THROW 51012, 'Nutrition box update count mismatch.', 1;
  ''';

  static const String deleteSql = '''
    DELETE FROM BM_RICH_NUTBOX
     WHERE RICH_NUTBOX_ID=@boxId;
    IF @@ROWCOUNT<>1
      THROW 51013, 'Nutrition box delete count mismatch.', 1;
  ''';

  static Future<List<NutritionBox>> selectAll() async {
    final result = await DbClient.instance.getData(selectSql);
    return DAO.mapRows(result, NutritionBox.fromMap);
  }

  static DbTransactionStatement insertStatement({
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbTransactionStatement(
    sql: insertSql,
    params: {'typeId': typeId, 'name': name, 'rtf': rtf, 'width': width},
  );

  static DbTransactionStatement updateStatement({
    required int boxId,
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbTransactionStatement(
    sql: updateSql,
    params: {
      'boxId': boxId,
      'typeId': typeId,
      'name': name,
      'rtf': rtf,
      'width': width,
    },
  );

  static DbTransactionStatement deleteStatement(int boxId) =>
      DbTransactionStatement(sql: deleteSql, params: {'boxId': boxId});

  static Future<void> insert({
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbClient.instance.transaction([
    insertStatement(typeId: typeId, name: name, rtf: rtf, width: width),
  ]);

  static Future<void> update({
    required int boxId,
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbClient.instance.transaction([
    updateStatement(
      boxId: boxId,
      typeId: typeId,
      name: name,
      rtf: rtf,
      width: width,
    ),
  ]);

  static Future<void> delete(int boxId) =>
      DbClient.instance.transaction([deleteStatement(boxId)]);
}
