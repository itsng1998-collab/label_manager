import 'dart:convert';

import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/dao.dart';

class FixedColumnType {
  const FixedColumnType({required this.id, required this.name});

  factory FixedColumnType.fromMap(Map<String, dynamic> map) {
    return FixedColumnType(
      id: int.parse(map['RICH_FIX_COL_TYPE_ID'].toString()),
      name: (map['RICH_TYPE_NAME'] ?? '').toString(),
    );
  }

  final int id;
  final String name;
}

class FixedColumnCandidate {
  const FixedColumnCandidate({
    required this.id,
    required this.typeId,
    required this.columnType,
    required this.keyword,
    required this.columnName,
  });

  factory FixedColumnCandidate.fromMap(Map<String, dynamic> map) {
    return FixedColumnCandidate(
      id: int.parse(map['RICH_FIX_COLUMN_ID'].toString()),
      typeId: int.parse(map['RICH_FIX_COL_TYPE_ID'].toString()),
      columnType: TColumnType.getFromCode(
        int.parse(map['RICH_TYPE'].toString()),
      ),
      keyword: (map['RICH_KEYWORD'] ?? '').toString(),
      columnName: (map['RICH_COLUMN_NAME'] ?? '').toString(),
    );
  }

  final int id;
  final int typeId;
  final TColumnType columnType;
  final String keyword;
  final String columnName;
}

class CustomerColumnCandidate {
  const CustomerColumnCandidate({
    required this.id,
    required this.customerId,
    required this.columnType,
    required this.keyword,
    required this.columnName,
  });

  factory CustomerColumnCandidate.fromMap(Map<String, dynamic> map) {
    return CustomerColumnCandidate(
      id: int.parse(map['RICH_CUST_COLUMN_ID'].toString()),
      customerId: int.parse(map['RICH_CUSTOMER_ID'].toString()),
      columnType: TColumnType.getFromCode(
        int.parse(map['RICH_TYPE'].toString()),
      ),
      keyword: (map['RICH_KEYWORD'] ?? '').toString(),
      columnName: (map['RICH_COLUMN_NAME'] ?? '').toString(),
    );
  }

  final int id;
  final int customerId;
  final TColumnType columnType;
  final String keyword;
  final String columnName;
}

class CustomerColumnDraft {
  const CustomerColumnDraft({
    required this.key,
    required this.id,
    required this.customerId,
    required this.columnType,
    required this.keyword,
    required this.columnName,
    required this.isNew,
  });

  factory CustomerColumnDraft.fromCandidate(CustomerColumnCandidate value) {
    return CustomerColumnDraft(
      key: 'customer-column:${value.id}',
      id: value.id,
      customerId: value.customerId,
      columnType: value.columnType,
      keyword: value.keyword,
      columnName: value.columnName,
      isNew: false,
    );
  }

  factory CustomerColumnDraft.empty({
    required String key,
    required int customerId,
    required TColumnType columnType,
  }) {
    return CustomerColumnDraft(
      key: key,
      id: 0,
      customerId: customerId,
      columnType: columnType,
      keyword: '',
      columnName: '',
      isNew: true,
    );
  }

  final String key;
  final int id;
  final int customerId;
  final TColumnType columnType;
  final String keyword;
  final String columnName;
  final bool isNew;

  CustomerColumnDraft copyWith({
    TColumnType? columnType,
    String? keyword,
    String? columnName,
  }) {
    return CustomerColumnDraft(
      key: key,
      id: id,
      customerId: customerId,
      columnType: columnType ?? this.columnType,
      keyword: keyword == null ? this.keyword : keyword.trim().toUpperCase(),
      columnName: columnName ?? this.columnName,
      isNew: isNew,
    );
  }

  bool sameValues(CustomerColumnDraft other) {
    return columnType.code == other.columnType.code &&
        keyword == other.keyword &&
        columnName == other.columnName;
  }

  Map<String, Object> toJson({bool keywordChanged = false}) => {
    'key': key,
    'id': id,
    'customerId': customerId,
    'type': columnType.code,
    'keyword': keyword,
    'columnName': columnName,
    'keywordChanged': keywordChanged,
  };
}

class CustomerColumnSaveCommand {
  const CustomerColumnSaveCommand({
    required this.customerId,
    required this.newColumns,
    required this.updatedColumns,
    required this.keywordChangedIds,
    required this.deletedIds,
  });

  final int customerId;
  final List<CustomerColumnDraft> newColumns;
  final List<CustomerColumnDraft> updatedColumns;
  final Set<int> keywordChangedIds;
  final Set<int> deletedIds;

  Map<String, dynamic> toSqlParams() => {
    'customerId': customerId,
    'newColumnsJson': jsonEncode([
      for (final row in newColumns) row.toJson(keywordChanged: true),
    ]),
    'updatedColumnsJson': jsonEncode([
      for (final row in updatedColumns)
        row.toJson(keywordChanged: keywordChangedIds.contains(row.id)),
    ]),
    'deletedIdsJson': jsonEncode([for (final id in deletedIds) {'id': id}]),
  };
}

class CustomerColumnEditSession {
  CustomerColumnEditSession._({
    required this.customerId,
    required this.original,
    required this.working,
    required this.deletedIds,
    required this.selectedKey,
  });

  factory CustomerColumnEditSession.fromCandidates({
    required int customerId,
    required List<CustomerColumnCandidate> candidates,
  }) {
    final rows = [for (final value in candidates) CustomerColumnDraft.fromCandidate(value)];
    if (rows.any((row) => row.customerId != customerId)) {
      throw ArgumentError('Customer column ownership mismatch.');
    }
    return CustomerColumnEditSession._(
      customerId: customerId,
      original: List.unmodifiable(rows),
      working: List.unmodifiable(rows),
      deletedIds: const {},
      selectedKey: null,
    );
  }

  final int customerId;
  final List<CustomerColumnDraft> original;
  final List<CustomerColumnDraft> working;
  final Set<int> deletedIds;
  final String? selectedKey;

  bool get isDirty {
    if (deletedIds.isNotEmpty || working.length != original.length) return true;
    final originals = {for (final row in original) row.key: row};
    return working.any((row) {
      final value = originals[row.key];
      return value == null || !value.sameValues(row);
    });
  }

  CustomerColumnEditSession add(CustomerColumnDraft row) {
    if (!row.isNew || row.customerId != customerId) {
      throw ArgumentError('Invalid customer column draft.');
    }
    if (working.any((value) => value.key == row.key)) {
      throw ArgumentError('Duplicate draft key: ${row.key}');
    }
    return _copy(working: [...working, row], selectedKey: row.key);
  }

  CustomerColumnEditSession update(CustomerColumnDraft row) {
    if (row.customerId != customerId ||
        !working.any((value) => value.key == row.key)) {
      throw ArgumentError('Unknown customer column: ${row.key}');
    }
    return _copy(
      working: [for (final value in working) value.key == row.key ? row : value],
      selectedKey: row.key,
    );
  }

  CustomerColumnEditSession select(String key) {
    if (!working.any((row) => row.key == key)) return this;
    return _copy(selectedKey: key);
  }

  CustomerColumnEditSession remove(String key) {
    final index = working.indexWhere((row) => row.key == key);
    if (index < 0) return this;
    final target = working[index];
    final next = working.where((row) => row.key != key).toList();
    final deleted = {...deletedIds};
    if (!target.isNew) deleted.add(target.id);
    return _copy(
      working: next,
      deletedIds: deleted,
      selectedKey: next.isEmpty ? null : next[index.clamp(0, next.length - 1)].key,
    );
  }

  CustomerColumnSaveCommand toSaveCommand() {
    final originals = {for (final row in original) row.key: row};
    final changedKeywords = <int>{};
    final updated = <CustomerColumnDraft>[];
    for (final row in working) {
      _validate(row, originals[row.key]);
      final original = originals[row.key];
      if (!row.isNew && original != null && !row.sameValues(original)) {
        updated.add(row);
        if (row.keyword != original.keyword) changedKeywords.add(row.id);
      }
    }
    _validateNewKeywordConflicts(originals);
    return CustomerColumnSaveCommand(
      customerId: customerId,
      newColumns: List.unmodifiable(working.where((row) => row.isNew)),
      updatedColumns: List.unmodifiable(updated),
      keywordChangedIds: Set.unmodifiable(changedKeywords),
      deletedIds: Set.unmodifiable(deletedIds),
    );
  }

  void _validate(CustomerColumnDraft row, CustomerColumnDraft? original) {
    final keyword = row.keyword.trim();
    if (keyword.isEmpty || !RegExp(r'^[A-Z0-9]+$').hasMatch(keyword)) {
      throw FormatException('키워드는 영문 대문자와 숫자만 사용할 수 있습니다.');
    }
    if (keyword.length > 100) {
      throw const FormatException('키워드는 100자 이하여야 합니다.');
    }
    if (row.columnName.trim().isEmpty) {
      throw const FormatException('항목명을 입력하세요.');
    }
    final keywordChanged = original == null || original.keyword != keyword;
    if (keywordChanged &&
        working.any(
          (value) => value.key != row.key && value.keyword.toUpperCase() == keyword,
        )) {
      throw FormatException('중복 키워드입니다: $keyword');
    }
  }

  void _validateNewKeywordConflicts(Map<String, CustomerColumnDraft> originals) {
    for (final row in working) {
      final original = originals[row.key];
      if (original == null || original.keyword != row.keyword) {
        _validate(row, original);
      }
    }
  }

  CustomerColumnEditSession _copy({
    List<CustomerColumnDraft>? working,
    Set<int>? deletedIds,
    String? selectedKey,
  }) {
    return CustomerColumnEditSession._(
      customerId: customerId,
      original: original,
      working: List.unmodifiable(working ?? this.working),
      deletedIds: Set.unmodifiable(deletedIds ?? this.deletedIds),
      selectedKey: selectedKey,
    );
  }
}

class FixedColumnDAO {
  static const selectTypesSql = '''
SELECT
  RICH_FIX_COL_TYPE_ID,
  COALESCE(CONVERT(NVARCHAR(30), RICH_TYPE_NAME COLLATE ${DAO.CP949}), N'') AS RICH_TYPE_NAME
FROM BM_RICH_FIX_COL_TYPE
''';

  static const selectCandidatesSql = '''
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
  static const selectSql = '''
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

INSERT INTO @New
SELECT DRAFT_KEY, RICH_TYPE, RICH_KEYWORD, RICH_COLUMN_NAME
FROM OPENJSON(@newColumnsJson)
WITH (
  DRAFT_KEY NVARCHAR(100) '$.key',
  RICH_TYPE TINYINT '$.type',
  RICH_KEYWORD NVARCHAR(100) '$.keyword',
  RICH_COLUMN_NAME NVARCHAR(50) '$.columnName'
);

INSERT INTO @Updated
SELECT RICH_CUST_COLUMN_ID, RICH_TYPE, RICH_KEYWORD, RICH_COLUMN_NAME, KEYWORD_CHANGED
FROM OPENJSON(@updatedColumnsJson)
WITH (
  RICH_CUST_COLUMN_ID INT '$.id',
  RICH_TYPE TINYINT '$.type',
  RICH_KEYWORD NVARCHAR(100) '$.keyword',
  RICH_COLUMN_NAME NVARCHAR(50) '$.columnName',
  KEYWORD_CHANGED BIT '$.keywordChanged'
);

INSERT INTO @Deleted
SELECT RICH_CUST_COLUMN_ID
FROM OPENJSON(@deletedIdsJson)
WITH (RICH_CUST_COLUMN_ID INT '$.id');

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
    final result = await DbClient.instance.getDataWithParams(
      selectSql,
      {'customerId': customerId},
    );
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