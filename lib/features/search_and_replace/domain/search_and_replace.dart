import 'package:label_manager/models/item_detail.dart';

class SearchReplaceEditTarget {
  const SearchReplaceEditTarget({
    required this.brandId,
    required this.labelSizeId,
    required this.itemId,
  });

  final int brandId;
  final int labelSizeId;
  final int itemId;
}

class SearchReplacePrintTarget {
  const SearchReplacePrintTarget({
    required this.brandId,
    required this.labelSizeId,
    required this.itemIds,
  });

  final int brandId;
  final int labelSizeId;
  final List<int> itemIds;
}

class SearchReplaceDraftRow {
  const SearchReplaceDraftRow({
    required this.source,
    required this.element,
    required this.elementSheet,
    this.checked = false,
    this.changed = false,
  });

  final ItemDetail source;
  final String element;
  final String elementSheet;
  final bool checked;
  final bool changed;

  SearchReplaceDraftRow copyWith({
    String? element,
    String? elementSheet,
    bool? checked,
    bool? changed,
  }) => SearchReplaceDraftRow(
    source: source,
    element: element ?? this.element,
    elementSheet: elementSheet ?? this.elementSheet,
    checked: checked ?? this.checked,
    changed: changed ?? this.changed,
  );
}
