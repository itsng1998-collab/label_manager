import 'dart:convert';

import 'package:label_manager/features/label_column/domain/column_type.dart';

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
    required this.originalColumnsById,
    required this.newColumns,
    required this.updatedColumns,
    required this.keywordChangedIds,
    required this.deletedIds,
  });

  final int customerId;
  final Map<int, CustomerColumnDraft> originalColumnsById;
  final List<CustomerColumnDraft> newColumns;
  final List<CustomerColumnDraft> updatedColumns;
  final Set<int> keywordChangedIds;
  final Set<int> deletedIds;

  Map<String, dynamic> toSqlParams() => {
    'customerId': customerId,
    'originalColumnsXml': _customerColumnsXml(originalColumnsById.values),
    'newColumnsXml': _customerColumnsXml(newColumns),
    'updatedColumnsXml': _customerColumnsXml(
      updatedColumns,
      keywordChangedIds: keywordChangedIds,
    ),
    'deletedIdsXml':
        '<ids>${[for (final id in deletedIds) '<id value="$id" />'].join()}</ids>',
  };
}

String _customerColumnsXml(
  Iterable<CustomerColumnDraft> columns, {
  Set<int> keywordChangedIds = const {},
}) {
  final xml = StringBuffer('<columns>');
  for (final column in columns) {
    xml
      ..write('<column id="${column.id}" type="${column.columnType.code}" ')
      ..write(
        'keywordChanged="${keywordChangedIds.contains(column.id) ? 1 : 0}">',
      )
      ..write('<key>${_customerColumnXmlText(column.key)}</key>')
      ..write('<keyword>${_customerColumnXmlText(column.keyword)}</keyword>')
      ..write(
        '<columnName>${_customerColumnXmlText(column.columnName)}</columnName>',
      )
      ..write('</column>');
  }
  return (xml..write('</columns>')).toString();
}

String _customerColumnXmlText(Object? value) =>
    const HtmlEscape(HtmlEscapeMode.element).convert(value?.toString() ?? '');

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
    final rows = [
      for (final value in candidates) CustomerColumnDraft.fromCandidate(value),
    ];
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

  CustomerColumnEditSession beginEdit() => _copy(selectedKey: selectedKey);

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
      working: [
        for (final value in working) value.key == row.key ? row : value,
      ],
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
      selectedKey: next.isEmpty
          ? null
          : next[index.clamp(0, next.length - 1)].key,
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
      originalColumnsById: Map.unmodifiable({
        for (final row in original) row.id: row,
      }),
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
          (value) =>
              value.key != row.key && value.keyword.toUpperCase() == keyword,
        )) {
      throw FormatException('중복 키워드입니다: $keyword');
    }
  }

  void _validateNewKeywordConflicts(
    Map<String, CustomerColumnDraft> originals,
  ) {
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
