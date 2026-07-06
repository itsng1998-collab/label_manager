import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/page_home/common_label_manage.dart';

TColumnBase _column(
  String keyword, {
  String? columnName,
  bool useMissingKeywordCheck = false,
}) {
  return TColumnBase(
    columnType: const TColumnType(
      code: TColumnType.TYPE_BASE,
      name: 'base',
      order: 0,
    ),
    keyword: keyword,
    columnName: columnName ?? keyword,
    useMissingKeywordCheck: useMissingKeywordCheck,
  );
}

void main() {
  test('barcode object ids are prefixed and deduplicated from keywords', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [
        _column('barcode_id'),
        _column('#QRCODE_VALUE'),
        _column('  Barcode_Id  '),
        _column('ITEMNAME'),
      ],
      const [],
    );

    expect(objectIds, ['#barcode_id', '#QRCODE_VALUE']);
  });

  test('barcode object ids fall back to default when no barcode keyword exists', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [_column('ITEMNAME')],
      const [],
    );

    expect(objectIds, ['#BARCODE']);
  });

  test('image object ids include every special and used keyword', () {
    final objectIds = commonLabelImageObjectIdsFromColumns(
      [_column('ITEMNAME'), _column('  #ELEMENT  ')],
    );

    final combined = commonLabelImageObjectIdsFromColumns([
      _column('ITEMNAME'),
      _column('  #ELEMENT  '),
      _column('BARCODE_ID'),
      _column('itemname'),
      _column('PRICE'),
    ]);

    expect(objectIds, ['#ITEMNAME', '#ELEMENT']);
    expect(combined, ['#ITEMNAME', '#ELEMENT', '#BARCODE_ID', '#PRICE']);
  });

  test('required keywords include only missing-keyword checked columns', () {
    final required = commonLabelRequiredKeywordsFromColumns([
      _column(
        'ITEMNAME',
        columnName: '품명',
        useMissingKeywordCheck: true,
      ),
      _column('PRICE', columnName: '가격'),
      _column(
        '  #BARCODE_ID  ',
        columnName: '바코드',
        useMissingKeywordCheck: true,
      ),
      _column('itemname', columnName: '중복', useMissingKeywordCheck: true),
    ]);

    expect(required.map((item) => item.keyword), ['ITEMNAME', '#BARCODE_ID']);
    expect(required.map((item) => item.itemName), ['품명', '바코드']);
  });
}
