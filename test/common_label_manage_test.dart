import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/page_home/common_label_manage.dart';

TColumnBase _column(String keyword) {
  return TColumnBase(
    columnType: const TColumnType(
      code: TColumnType.TYPE_BASE,
      name: 'base',
      order: 0,
    ),
    keyword: keyword,
    columnName: keyword,
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
}
