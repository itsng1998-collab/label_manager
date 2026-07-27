import 'dart:convert';

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/dao.dart';

class NutritionType {
  const NutritionType({required this.id, required this.name});

  final int id;
  final String name;

  factory NutritionType.fromMap(Map<String, dynamic> map) => NutritionType(
    id: int.tryParse((map['NUTTYPE_ID'] ?? '').toString()) ?? 0,
    name: (map['NUTTYPE_NAME'] ?? '').toString(),
  );
}

class NutritionTypeColumn {
  const NutritionTypeColumn({
    required this.id,
    required this.keyword,
    required this.name,
  });

  final int id;
  final String keyword;
  final String name;

  NutritionTypeColumn copyWith({String? name}) => NutritionTypeColumn(
    id: id,
    keyword: keyword,
    name: name ?? this.name,
  );

  factory NutritionTypeColumn.fromMap(Map<String, dynamic> map) =>
      NutritionTypeColumn(
        id: int.tryParse((map['NUTCOL_ID'] ?? '').toString()) ?? 0,
        keyword: (map['NUTCOL_KEYWORD'] ?? '').toString(),
        name: (map['NUTCOL_NAME'] ?? '').toString(),
      );
}

class NutritionTypeDAO extends DAO {
  static const String SelectTypesSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_NUTTYPE_ID), N'') AS NUTTYPE_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NUTTYPE_NAME COLLATE ${DAO.CP949}), N'') AS NUTTYPE_NAME
    FROM BM_RICH_NUTTYPE
  ''';

  static const String SelectTypesByIdSql = '''
    $SelectTypesSql
    ORDER BY RICH_NUTTYPE_ID
  ''';

  static const String SelectColumnsSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), RICH_NUTCOL_ID), N'') AS NUTCOL_ID,
      COALESCE(CONVERT(NVARCHAR(10), RICH_NUTCOL_KEYWORD COLLATE ${DAO.CP949}), N'') AS NUTCOL_KEYWORD,
      COALESCE(CONVERT(NVARCHAR(50), RICH_NUTCOL_NAME COLLATE ${DAO.CP949}), N'') AS NUTCOL_NAME
    FROM BM_RICH_NUTCOLUMN
    WHERE RICH_NUTCOL_SIZE=@typeId
    ORDER BY RICH_NUTCOL_ID
  ''';

  static const String InsertSql = '''
    DECLARE @Details XML=CONVERT(XML, @detailsXml);
    DECLARE @InsertedType TABLE (NUTTYPE_ID INT NOT NULL);

    INSERT INTO BM_RICH_NUTTYPE (RICH_NUTTYPE_NAME)
    OUTPUT INSERTED.RICH_NUTTYPE_ID INTO @InsertedType (NUTTYPE_ID)
    VALUES (@name);

    INSERT INTO BM_RICH_NUTCOLUMN (
      RICH_NUTCOL_SIZE,
      RICH_NUTCOL_KEYWORD,
      RICH_NUTCOL_NAME
    )
    SELECT
      I.NUTTYPE_ID,
      N.value('@keyword', 'VARCHAR(10)'),
      N.value('@name', 'VARCHAR(50)')
    FROM @InsertedType I
    CROSS JOIN @Details.nodes('/columns/column') X(N);
  ''';

  static const String UpdateSql = '''
    DECLARE @Details XML=CONVERT(XML, @detailsXml);

    UPDATE BM_RICH_NUTTYPE
       SET RICH_NUTTYPE_NAME=@name
     WHERE RICH_NUTTYPE_ID=@typeId;
    IF @@ROWCOUNT<>1
      THROW 51010, 'Nutrition type update count mismatch.', 1;

    DELETE FROM BM_RICH_NUTCOLUMN
     WHERE RICH_NUTCOL_SIZE=@typeId;

    INSERT INTO BM_RICH_NUTCOLUMN (
      RICH_NUTCOL_SIZE,
      RICH_NUTCOL_KEYWORD,
      RICH_NUTCOL_NAME
    )
    SELECT
      @typeId,
      N.value('@keyword', 'VARCHAR(10)'),
      N.value('@name', 'VARCHAR(50)')
    FROM @Details.nodes('/columns/column') X(N);
  ''';

  static const String DeleteSql = '''
    DELETE FROM BM_RICH_NUTBOX
     WHERE RICH_NUTBOX_TYPE=@typeId;

    DELETE FROM BM_RICH_NUTCOLUMN
     WHERE RICH_NUTCOL_SIZE=@typeId;

    DELETE FROM BM_RICH_NUTTYPE
     WHERE RICH_NUTTYPE_ID=@typeId;
    IF @@ROWCOUNT<>1
      THROW 51011, 'Nutrition type delete count mismatch.', 1;
  ''';

  static Future<List<NutritionType>> selectTypes() async {
    final result = await DbClient.instance.getData(SelectTypesSql);
    return DAO.mapRows(result, NutritionType.fromMap);
  }

  static Future<List<NutritionType>> selectTypesById() async {
    final result = await DbClient.instance.getData(SelectTypesByIdSql);
    return DAO.mapRows(result, NutritionType.fromMap);
  }

  static Future<List<NutritionTypeColumn>> selectColumns(int typeId) async {
    final result = await DbClient.instance.getDataWithParams(
      SelectColumnsSql,
      {'typeId': typeId},
    );
    return DAO.mapRows(result, NutritionTypeColumn.fromMap);
  }

  static DbTransactionStatement insertStatement(
    String name,
    List<NutritionTypeColumn> columns,
  ) => DbTransactionStatement(
    sql: InsertSql,
    params: {'name': name, 'detailsXml': _detailsXml(columns)},
  );

  static DbTransactionStatement updateStatement(
    int typeId,
    String name,
    List<NutritionTypeColumn> columns,
  ) => DbTransactionStatement(
    sql: UpdateSql,
    params: {
      'typeId': typeId,
      'name': name,
      'detailsXml': _detailsXml(columns),
    },
  );

  static DbTransactionStatement deleteStatement(int typeId) =>
      DbTransactionStatement(sql: DeleteSql, params: {'typeId': typeId});

  static Future<void> insert(
    String name,
    List<NutritionTypeColumn> columns,
  ) => DbClient.instance.transaction([insertStatement(name, columns)]);

  static Future<void> update(
    int typeId,
    String name,
    List<NutritionTypeColumn> columns,
  ) => DbClient.instance.transaction([
    updateStatement(typeId, name, columns),
  ]);

  static Future<void> delete(int typeId) =>
      DbClient.instance.transaction([deleteStatement(typeId)]);

  static String _detailsXml(List<NutritionTypeColumn> columns) {
    final escape = const HtmlEscape(HtmlEscapeMode.attribute);
    final xml = StringBuffer('<columns>');
    for (final column in columns) {
      xml
        ..write('<column keyword="')
        ..write(escape.convert(column.keyword))
        ..write('" name="')
        ..write(escape.convert(column.name))
        ..write('" />');
    }
    return (xml..write('</columns>')).toString();
  }
}