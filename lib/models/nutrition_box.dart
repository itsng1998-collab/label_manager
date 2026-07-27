import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/dao.dart';

class NutritionBox {
  const NutritionBox({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.name,
    required this.rtf,
    required this.width,
  });

  final int id;
  final int typeId;
  final String typeName;
  final String name;
  final String rtf;
  final int width;

  factory NutritionBox.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    return NutritionBox(
      id: intValue('NUTBOX_ID'),
      typeId: intValue('NUTTYPE_ID'),
      typeName: stringValue('NUTTYPE_NAME'),
      name: stringValue('NUTBOX_NAME'),
      rtf: stringValue('NUTBOX_DATA'),
      width: intValue('NUTBOX_WIDTH'),
    );
  }
}

class NutritionBoxDAO extends DAO {
  static const String SelectSql = '''
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

  static const String InsertSql = '''
    INSERT INTO BM_RICH_NUTBOX (
      RICH_NUTBOX_TYPE,
      RICH_NUTBOX_NAME,
      RICH_NUTBOX_DATA,
      RICH_NUTBOX_WIDTH
    ) VALUES (@typeId, @name, @rtf, @width);
  ''';

  static const String UpdateSql = '''
    UPDATE BM_RICH_NUTBOX
       SET RICH_NUTBOX_TYPE=@typeId,
           RICH_NUTBOX_NAME=@name,
           RICH_NUTBOX_DATA=@rtf,
           RICH_NUTBOX_WIDTH=@width
     WHERE RICH_NUTBOX_ID=@boxId;
    IF @@ROWCOUNT<>1
      THROW 51012, 'Nutrition box update count mismatch.', 1;
  ''';

  static const String DeleteSql = '''
    DELETE FROM BM_RICH_NUTBOX
     WHERE RICH_NUTBOX_ID=@boxId;
    IF @@ROWCOUNT<>1
      THROW 51013, 'Nutrition box delete count mismatch.', 1;
  ''';

  static Future<List<NutritionBox>> selectAll() async {
    final result = await DbClient.instance.getData(SelectSql);
    return DAO.mapRows(result, NutritionBox.fromMap);
  }

  static DbTransactionStatement insertStatement({
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbTransactionStatement(
    sql: InsertSql,
    params: {'typeId': typeId, 'name': name, 'rtf': rtf, 'width': width},
  );

  static DbTransactionStatement updateStatement({
    required int boxId,
    required int typeId,
    required String name,
    required String rtf,
    required int width,
  }) => DbTransactionStatement(
    sql: UpdateSql,
    params: {
      'boxId': boxId,
      'typeId': typeId,
      'name': name,
      'rtf': rtf,
      'width': width,
    },
  );

  static DbTransactionStatement deleteStatement(int boxId) =>
      DbTransactionStatement(sql: DeleteSql, params: {'boxId': boxId});

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