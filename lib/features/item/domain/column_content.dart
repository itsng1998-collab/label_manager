class TColumnContent {
  static const int noId = 0;

  TColumnContent({
    required this.colContentId,
    required this.columnId,
    required this.itemId,
    required this.editable,
    required this.dataString,
  });

  final int colContentId;
  final int columnId;
  final int itemId;
  final bool editable;
  final String dataString;

  static Map<ColumnItemKey, TColumnContent>? datas;

  static void setDatas(Map<ColumnItemKey, TColumnContent>? values) {
    datas = values;
  }

  static TColumnContent? get(int columnId, int itemId) {
    final map = datas;
    if (map == null) return null;
    return map[ColumnItemKey(columnId: columnId, itemId: itemId)];
  }

  @override
  String toString() =>
      'colContentId: $colContentId, columnId: $columnId, itemId: $itemId, editable: $editable, dataString: $dataString';
}

class ColumnItemKey {
  const ColumnItemKey({required this.columnId, required this.itemId});

  final int columnId;
  final int itemId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnItemKey &&
          runtimeType == other.runtimeType &&
          columnId == other.columnId &&
          itemId == other.itemId;

  @override
  int get hashCode => Object.hash(columnId, itemId);
}

class TColumnContentScopedView {
  TColumnContentScopedView(Map<ColumnItemKey, TColumnContent> values)
    : _values = Map.unmodifiable(values);

  final Map<ColumnItemKey, TColumnContent> _values;

  TColumnContent? get(int columnId, int itemId) {
    return _values[ColumnItemKey(columnId: columnId, itemId: itemId)];
  }

  String value(int columnId, int itemId) {
    return get(columnId, itemId)?.dataString ?? '';
  }

  Map<ColumnItemKey, TColumnContent> get values => _values;
}
