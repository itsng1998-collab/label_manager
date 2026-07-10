import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/page_home/item_code_data_resolver.dart';

void main() {
  group('[QR viewer][barcode/output preview]', () {
    test('resolves user-defined QR tokens from current row values', () {
      final columns = [
        _column(
          id: 1,
          keyword: 'QR',
          name: 'QR 데이터',
          type: TColumnType.TYPE_QR_CODE,
          barcodeType: BarcodeType.Code128,
          createType: QRCodeCreateType.QRCODE_TYPE_USER_DEFINE,
          data: '#품목/#CODE',
          text: '#ITEMNAME',
        ),
        _column(id: 2, keyword: 'CODE', name: '코드'),
      ];
      final resolver = ItemCodeDataResolver(
        itemName: '딸기잼',
        columns: columns,
        columnValue: (id) => {1: 'unused', 2: '00123'}[id] ?? '',
      );

      final result = resolver.resolveViewerData().single;
      expect(result.data, '딸기잼/00123');
      expect(result.displayText, '딸기잼');
      expect(result.barcodeFormatId, 'qrCode');
      expect(result.showText, isTrue);
    });

    test('normalizes EAN-8 and falls back without lossy padding', () {
      final column = _column(
        id: 1,
        keyword: 'BARCODE',
        name: '바코드',
        type: TColumnType.TYPE_BARCODE,
        barcodeType: BarcodeType.CodeEAN8,
      );
      var value = '1234567';
      final resolver = ItemCodeDataResolver(
        itemName: '품목',
        columns: [column],
        columnValue: (_) => value,
      );

      expect(resolver.resolve(column).data, BarcodeDataHelper.ean8(value));
      expect(resolver.resolve(column).barcodeFormatId, 'ean8');

      value = '123456';
      final fallback = resolver.resolve(column);
      expect(fallback.data, '123456');
      expect(fallback.barcodeFormatId, 'code128');
      expect(fallback.warning, isNotNull);
    });

    test('preserves template format instead of applying fallback', () {
      final column = _column(
        id: 1,
        keyword: 'BARCODE',
        name: '바코드',
        type: TColumnType.TYPE_BARCODE,
      );
      final result =
          ItemCodeDataResolver(
            itemName: '품목',
            columns: [column],
            columnValue: (_) => '123456',
          ).resolve(
            column,
            templateFormatId: 'ean8',
            preserveTemplateBarcodeFormat: true,
          );

      expect(result.barcodeFormatId, 'ean8');
      expect(result.warning, isNull);
      expect(result.error, isNotNull);
    });

    test('updates barcode metadata while preserving template geometry', () {
      final column = _column(
        id: 1,
        keyword: 'BARCODE',
        name: '바코드',
        type: TColumnType.TYPE_BARCODE,
        barcodeType: BarcodeType.CodeEAN8,
      );
      final resolver = ItemCodeDataResolver(
        itemName: '품목',
        columns: [column],
        columnValue: (_) => '1234567',
      );
      final result = resolver.resolveObject('#BARCODE')!;
      final metadata = itemCodeBarcodeMetadata(
        const {
          'barcodeFormatId': 'code128',
          'barcodeModuleScale': 2,
          'rotation': 90,
        },
        result,
        preserveTemplateBarcodeFormat: false,
      );

      expect(metadata['barcodeText'], BarcodeDataHelper.ean8('1234567'));
      expect(metadata['barcodeFormatId'], 'ean8');
      expect(metadata['barcodeFormatLabel'], 'EAN-8');
      expect(metadata['barcodeShowText'], isTrue);
      expect(metadata['barcodeModuleScale'], 2);
      expect(metadata['rotation'], 90);

      final preserved = itemCodeBarcodeMetadata(
        metadata,
        result,
        preserveTemplateBarcodeFormat: true,
      );
      expect(preserved['barcodeFormatId'], 'ean8');
      expect(preserved['barcodeModuleScale'], 2);
    });

    test('builds legacy sodium URL from six serialized records', () {
      final columns = [
        _column(
          id: 1,
          keyword: 'QR',
          name: '나트륨 QR',
          type: TColumnType.TYPE_QR_CODE,
          barcodeType: BarcodeType.QrCode,
          createType: QRCodeCreateType.QRCODE_TYPE_NATRIUM,
          natrium:
              '제품명-품목-/나트륨mg-NA-/제공량-AMOUNT-/비교표준값-AVG-/제조원-MAKER-/제품유형-TYPE-',
        ),
        _column(id: 2, keyword: 'NA', name: '나트륨'),
        _column(id: 3, keyword: 'AMOUNT', name: '제공량'),
        _column(id: 4, keyword: 'AVG', name: '비교값'),
        _column(id: 5, keyword: 'MAKER', name: '제조원'),
        _column(id: 6, keyword: 'TYPE', name: '유형'),
      ];
      final values = {2: '500', 3: '100 g', 4: '1000', 5: 'A&B', 6: '면류'};
      final result = ItemCodeDataResolver(
        itemName: '매운 면',
        columns: columns,
        columnValue: (id) => values[id] ?? '',
      ).resolveViewerData().single;

      expect(result.data, contains('i=%EB%A7%A4%EC%9A%B4%20%EB%A9%B4'));
      expect(result.data, contains('p=A%09B'));
      expect(result.data, contains('&n=500&t=100%20g&nn=50'));
      expect(result.data, contains('it=%EB%A9%B4%EB%A5%98'));
    });
  });
}

ItemCodeColumnSpec _column({
  required int id,
  required String keyword,
  required String name,
  int type = TColumnType.TYPE_BASE,
  BarcodeType barcodeType = BarcodeType.Code128,
  QRCodeCreateType createType = QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
  String data = '',
  String text = '',
  String natrium = '',
}) => ItemCodeColumnSpec(
  columnId: id,
  keyword: keyword,
  columnName: name,
  typeCode: type,
  barcodeType: barcodeType,
  createType: createType,
  userDefineData: data,
  userDefineText: text,
  natriumJoinString: natrium,
  showBarcodeText: true,
  showQrText: true,
);
