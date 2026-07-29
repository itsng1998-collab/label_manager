import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/brand/data/brand_dao.dart';

void main() {
  test('brand row maps database values', () {
    final brand = brandFromRow(const {
      'BRAND_ID': '11',
      'CUSTOMER_ID': '22',
      'BRAND_NAME': '브랜드',
    });

    expect(brand.brandId, 11);
    expect(brand.customerId, 22);
    expect(brand.brandName, '브랜드');
  });

  test('brand query keeps customer scope and order', () {
    expect(BrandDAO.selectSql, contains('FROM BM_RICH_BRAND'));
    expect(BrandDAO.whereSqlCustomerId, contains('@customerId'));
    expect(BrandDAO.orderSqlByBrandOrder, contains('RICH_BRAND_ORDER ASC'));
  });
}
