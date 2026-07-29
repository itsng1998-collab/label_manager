import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/label_column/domain/label_column_candidates.dart';
import 'package:label_manager/database/dao.dart';

class FixedColumnDAO {
  static const selectTypesSql =
      '''
SELECT
  RICH_FIX_COL_TYPE_ID,
  COALESCE(CONVERT(NVARCHAR(30), RICH_TYPE_NAME COLLATE ${DAO.CP949}), N'') AS RICH_TYPE_NAME
FROM BM_RICH_FIX_COL_TYPE
''';

  static const selectCandidatesSql =
      '''
SELECT
  RICH_FIX_COLUMN_ID,
  RICH_FIX_COL_TYPE_ID,
  RICH_TYPE,
  COALESCE(CONVERT(NVARCHAR(100), RICH_KEYWORD COLLATE ${DAO.CP949}), N'') AS RICH_KEYWORD,
  COALESCE(CONVERT(NVARCHAR(50), RICH_COLUMN_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_NAME
FROM BM_RICH_FIX_COLUMN
WHERE RICH_FIX_COL_TYPE_ID=@typeId
''';

  static Future<List<FixedColumnType>> selectTypes() async {
    final result = await DbClient.instance.getData(selectTypesSql);
    return DAO.mapRows(result, FixedColumnType.fromMap);
  }

  static Future<List<FixedColumnCandidate>> selectCandidates(int typeId) async {
    final result = await DbClient.instance.getDataWithParams(
      selectCandidatesSql,
      {'typeId': typeId},
    );
    return DAO.mapRows(result, FixedColumnCandidate.fromMap);
  }
}

class CustomerColumnDAO {
  static const selectSql =
      '''
SELECT
  RICH_CUST_COLUMN_ID,
  RICH_CUSTOMER_ID,
  RICH_TYPE,
  COALESCE(CONVERT(NVARCHAR(100), RICH_KEYWORD COLLATE ${DAO.CP949}), N'') AS RICH_KEYWORD,
  COALESCE(CONVERT(NVARCHAR(50), RICH_COLUMN_NAME COLLATE ${DAO.CP949}), N'') AS RICH_COLUMN_NAME
FROM BM_RICH_CUST_COLUMN
WHERE RICH_CUSTOMER_ID=@customerId
''';

  static const saveSql = r'''
SET NOCOUNT ON;

DECLARE @OriginalColumnsDocument XML = CONVERT(XML, @originalColumnsXml);
DECLARE @NewColumnsDocument XML = CONVERT(XML, @newColumnsXml);
DECLARE @UpdatedColumnsDocument XML = CONVERT(XML, @updatedColumnsXml);
DECLARE @DeletedIdsDocument XML = CONVERT(XML, @deletedIdsXml);
DECLARE @New TABLE (
  DRAFT_KEY NVARCHAR(100) NOT NULL,
  RICH_TYPE TINYINT NOT NULL,
  RICH_KEYWORD NVARCHAR(100) NOT NULL,
  RICH_COLUMN_NAME NVARCHAR(50) NOT NULL
);
DECLARE @Updated TABLE (
  RICH_CUST_COLUMN_ID INT NOT NULL PRIMARY KEY,
  RICH_TYPE TINYINT NOT NULL,
  RICH_KEYWORD NVARCHAR(100) NOT NULL,
  RICH_COLUMN_NAME NVARCHAR(50) NOT NULL,
  KEYWORD_CHANGED BIT NOT NULL
);
DECLARE @Deleted TABLE (RICH_CUST_COLUMN_ID INT NOT NULL PRIMARY KEY);
DECLARE @Original TABLE (
  RICH_CUST_COLUMN_ID INT NOT NULL PRIMARY KEY,
  RICH_TYPE TINYINT NOT NULL,
  RICH_KEYWORD NVARCHAR(100) NOT NULL,
  RICH_COLUMN_NAME NVARCHAR(50) NOT NULL
);

INSERT INTO @Original
SELECT
  N.value('@id', 'INT'),
  N.value('@type', 'TINYINT'),
  N.value('string((keyword/text())[1])', 'NVARCHAR(100)'),
  N.value('string((columnName/text())[1])', 'NVARCHAR(50)')
FROM @OriginalColumnsDocument.nodes('/columns/column') X(N);

INSERT INTO @New
SELECT
  N.value('string((key/text())[1])', 'NVARCHAR(100)'),
  N.value('@type', 'TINYINT'),
  N.value('string((keyword/text())[1])', 'NVARCHAR(100)'),
  N.value('string((columnName/text())[1])', 'NVARCHAR(50)')
FROM @NewColumnsDocument.nodes('/columns/column') X(N);

INSERT INTO @Updated
SELECT
  N.value('@id', 'INT'),
  N.value('@type', 'TINYINT'),
  N.value('string((keyword/text())[1])', 'NVARCHAR(100)'),
  N.value('string((columnName/text())[1])', 'NVARCHAR(50)'),
  N.value('@keywordChanged', 'BIT')
FROM @UpdatedColumnsDocument.nodes('/columns/column') X(N);

INSERT INTO @Deleted
SELECT N.value('@value', 'INT')
FROM @DeletedIdsDocument.nodes('/ids/id') X(N);

DECLARE @LockedCustomerColumnId INT;
SELECT @LockedCustomerColumnId=C.RICH_CUST_COLUMN_ID
FROM BM_RICH_CUST_COLUMN C WITH (UPDLOCK, HOLDLOCK)
WHERE C.RICH_CUSTOMER_ID=@customerId;

IF (SELECT COUNT(*) FROM BM_RICH_CUST_COLUMN WHERE RICH_CUSTOMER_ID=@customerId)
     <> (SELECT COUNT(*) FROM @Original)
   OR EXISTS (
     SELECT RICH_CUST_COLUMN_ID, RICH_TYPE,
       CONVERT(VARBINARY(MAX), COALESCE(CONVERT(NVARCHAR(MAX), RICH_KEYWORD), N'')),
       CONVERT(VARBINARY(MAX), COALESCE(CONVERT(NVARCHAR(MAX), RICH_COLUMN_NAME), N''))
     FROM BM_RICH_CUST_COLUMN WHERE RICH_CUSTOMER_ID=@customerId
     EXCEPT
     SELECT RICH_CUST_COLUMN_ID, RICH_TYPE,
       CONVERT(VARBINARY(MAX), RICH_KEYWORD),
       CONVERT(VARBINARY(MAX), RICH_COLUMN_NAME)
     FROM @Original
   )
  THROW 51027, 'Customer columns changed after editing started.', 1;

IF EXISTS (
  SELECT 1
  FROM @Updated U
  LEFT JOIN BM_RICH_CUST_COLUMN C
    ON C.RICH_CUST_COLUMN_ID=U.RICH_CUST_COLUMN_ID
   AND C.RICH_CUSTOMER_ID=@customerId
  WHERE C.RICH_CUST_COLUMN_ID IS NULL
) THROW 51020, 'Customer column update ownership mismatch.', 1;

IF EXISTS (
  SELECT 1
  FROM @Deleted D
  LEFT JOIN BM_RICH_CUST_COLUMN C
    ON C.RICH_CUST_COLUMN_ID=D.RICH_CUST_COLUMN_ID
   AND C.RICH_CUSTOMER_ID=@customerId
  WHERE C.RICH_CUST_COLUMN_ID IS NULL
) THROW 51021, 'Customer column delete ownership mismatch.', 1;

IF EXISTS (
  SELECT RICH_KEYWORD FROM (
    SELECT RICH_KEYWORD FROM @New
    UNION ALL
    SELECT RICH_KEYWORD FROM @Updated WHERE KEYWORD_CHANGED=1
  ) K
  GROUP BY RICH_KEYWORD COLLATE Korean_Wansung_CI_AS
  HAVING COUNT(*) > 1
) THROW 51022, 'Duplicate customer column keyword.', 1;

IF EXISTS (
  SELECT 1
  FROM (
    SELECT NULL AS RICH_CUST_COLUMN_ID, RICH_KEYWORD FROM @New
    UNION ALL
    SELECT RICH_CUST_COLUMN_ID, RICH_KEYWORD FROM @Updated WHERE KEYWORD_CHANGED=1
  ) K
  JOIN BM_RICH_CUST_COLUMN C
    ON C.RICH_CUSTOMER_ID=@customerId
   AND C.RICH_KEYWORD COLLATE Korean_Wansung_CI_AS=K.RICH_KEYWORD COLLATE Korean_Wansung_CI_AS
   AND (K.RICH_CUST_COLUMN_ID IS NULL OR C.RICH_CUST_COLUMN_ID<>K.RICH_CUST_COLUMN_ID)
  LEFT JOIN @Deleted D ON D.RICH_CUST_COLUMN_ID=C.RICH_CUST_COLUMN_ID
  WHERE D.RICH_CUST_COLUMN_ID IS NULL
) THROW 51023, 'Duplicate customer column keyword.', 1;

DELETE C
FROM BM_RICH_CUST_COLUMN C
JOIN @Deleted D ON D.RICH_CUST_COLUMN_ID=C.RICH_CUST_COLUMN_ID
WHERE C.RICH_CUSTOMER_ID=@customerId;
IF @@ROWCOUNT<>(SELECT COUNT(*) FROM @Deleted)
  THROW 51024, 'Customer column delete count mismatch.', 1;

UPDATE C
SET RICH_KEYWORD=CONVERT(VARCHAR(100), U.RICH_KEYWORD COLLATE Korean_Wansung_CI_AS),
    RICH_COLUMN_NAME=CONVERT(VARCHAR(50), U.RICH_COLUMN_NAME COLLATE Korean_Wansung_CI_AS),
    RICH_TYPE=U.RICH_TYPE
FROM BM_RICH_CUST_COLUMN C
JOIN @Updated U ON U.RICH_CUST_COLUMN_ID=C.RICH_CUST_COLUMN_ID
WHERE C.RICH_CUSTOMER_ID=@customerId;
IF @@ROWCOUNT<>(SELECT COUNT(*) FROM @Updated)
  THROW 51025, 'Customer column update count mismatch.', 1;

INSERT INTO BM_RICH_CUST_COLUMN (
  RICH_CUSTOMER_ID, RICH_KEYWORD, RICH_COLUMN_NAME, RICH_TYPE
)
SELECT @customerId,
       CONVERT(VARCHAR(100), RICH_KEYWORD COLLATE Korean_Wansung_CI_AS),
       CONVERT(VARCHAR(50), RICH_COLUMN_NAME COLLATE Korean_Wansung_CI_AS),
       RICH_TYPE
FROM @New;
IF @@ROWCOUNT<>(SELECT COUNT(*) FROM @New)
  THROW 51026, 'Customer column insert count mismatch.', 1;
''';

  static Future<List<CustomerColumnCandidate>> selectByCustomerId(
    int customerId,
  ) async {
    final result = await DbClient.instance.getDataWithParams(selectSql, {
      'customerId': customerId,
    });
    return DAO.mapRows(result, CustomerColumnCandidate.fromMap);
  }

  static DbTransactionStatement buildSaveStatement(
    CustomerColumnSaveCommand command,
  ) {
    return DbTransactionStatement(sql: saveSql, params: command.toSqlParams());
  }

  static Future<void> save(CustomerColumnSaveCommand command) async {
    if (command.newColumns.isEmpty &&
        command.updatedColumns.isEmpty &&
        command.deletedIds.isEmpty) {
      return;
    }
    await DbClient.instance.transaction([buildSaveStatement(command)]);
  }
}
