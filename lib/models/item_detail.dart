// ignore_for_file: constant_identifier_names

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/models/dao.dart';

enum ItemDetailSearchType { itemName, element }

class ItemDetail {
  const ItemDetail({
    required this.itemId,
    required this.labelSizeId,
    required this.itemName,
    required this.labelSizeName,
    required this.element,
    required this.elementSheet,
    required this.brandId,
    required this.brandName,
  });

  final int itemId;
  final int labelSizeId;
  final String itemName;
  final String labelSizeName;
  final String element;
  final String elementSheet;
  final int brandId;
  final String brandName;

  factory ItemDetail.fromMap(Map<String, dynamic> map) {
    String stringValue(String key) => (map[key] ?? '').toString();
    int intValue(String key) => int.tryParse(stringValue(key)) ?? 0;
    return ItemDetail(
      itemId: intValue('ITEM_ID'),
      labelSizeId: intValue('LABELSIZE_ID'),
      itemName: stringValue('ITEM_NAME'),
      labelSizeName: stringValue('LABELSIZE_NAME'),
      element: stringValue('ELEMENT'),
      elementSheet: stringValue('ELEMENT_SHEET'),
      brandId: intValue('BRAND_ID'),
      brandName: stringValue('BRAND_NAME'),
    );
  }
}

class ItemDetailDAO extends DAO {
  static const String _SelectSql = '''
    SELECT
      COALESCE(CONVERT(NVARCHAR(20), I.RICH_ITEM_ID), N'') AS ITEM_ID,
      COALESCE(CONVERT(NVARCHAR(20), I.RICH_LABELSIZE_ID), N'') AS LABELSIZE_ID,
      COALESCE(CONVERT(NVARCHAR(100), I.RICH_ITEM_NAME COLLATE ${DAO.CP949}), N'') AS ITEM_NAME,
      COALESCE(CONVERT(NVARCHAR(50), L.RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      COALESCE(CONVERT(NVARCHAR(MAX), I.RICH_ELEMENT COLLATE ${DAO.CP949}), N'') AS ELEMENT,
      COALESCE(
        CONVERT(NVARCHAR(MAX), NULLIF(I.RICH_ELEMENT_SHEET, '') COLLATE ${DAO.CP949}),
        CONVERT(NVARCHAR(MAX), I.RICH_ELEMENT_RTF COLLATE ${DAO.CP949}),
        N''
      ) AS ELEMENT_SHEET,
      COALESCE(CONVERT(NVARCHAR(20), B.RICH_BRAND_ID), N'') AS BRAND_ID,
      COALESCE(CONVERT(NVARCHAR(50), B.RICH_BRAND_NAME COLLATE ${DAO.CP949}), N'') AS BRAND_NAME
    FROM BM_RICH_ITEM I
    INNER JOIN BM_RICH_LABELSIZE_FORM L
      ON I.RICH_LABELSIZE_ID=L.RICH_LABELSIZE_ID
    INNER JOIN BM_RICH_BRAND B
      ON L.RICH_BRAND_ID=B.RICH_BRAND_ID
    WHERE B.RICH_CUSTOMER_ID=@customerId
      AND (@useBrand=0 OR B.RICH_BRAND_ID=@brandId)
      AND (@useLabelSize=0 OR L.RICH_LABELSIZE_ID=@labelSizeId)
  ''';

  static const String SearchByItemNameSql = '''
    $_SelectSql
      AND I.RICH_ITEM_NAME LIKE N'%' + @query + N'%'
    ORDER BY B.RICH_BRAND_ID ASC
  ''';

  static const String SearchByElementSql = '''
    $_SelectSql
      AND I.RICH_ELEMENT LIKE N'%' + @query + N'%'
    ORDER BY B.RICH_BRAND_ID ASC
  ''';

  static Future<List<ItemDetail>> search({
    required int customerId,
    required ItemDetailSearchType type,
    required String query,
    int? brandId,
    int? labelSizeId,
  }) async {
    final result = await DbClient.instance.getDataWithParams(
      type == ItemDetailSearchType.itemName
          ? SearchByItemNameSql
          : SearchByElementSql,
      {
        'customerId': customerId,
        'query': type == ItemDetailSearchType.element
            ? escapeElementLikePattern(query)
            : query,
        'useBrand': brandId == null ? 0 : 1,
        'brandId': brandId ?? -1,
        'useLabelSize': labelSizeId == null ? 0 : 1,
        'labelSizeId': labelSizeId ?? -1,
      },
    );
    return DAO.mapRows(result, ItemDetail.fromMap);
  }

  static String escapeElementLikePattern(String value) {
    final result = StringBuffer();
    for (final codePoint in value.runes) {
      final character = String.fromCharCode(codePoint);
      result.write(switch (character) {
        '[' => '[[]',
        '%' => '[%]',
        '_' => '[_]',
        '^' => '[^]',
        _ => character,
      });
    }
    return result.toString();
  }
}