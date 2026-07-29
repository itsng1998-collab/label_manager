// ignore_for_file: constant_identifier_names

enum SpecalKeyword {
  NDEX_ITEMNAME(0, 'ITEMNAME', '품명'),
  INDEX_ELEMENT(1, 'ELEMENT', '주원료'),
  INDEX_SCALE_WEIGHT(2, 'SWEIGHT', '저울중량'),
  INDEX_SCALE_PRICE(3, 'SPRICE', '최종가격');

  final int code;
  final String keyword;
  final String columnName;

  const SpecalKeyword(this.code, this.keyword, this.columnName);
}
