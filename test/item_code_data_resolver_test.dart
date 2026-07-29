import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/gs1/data/gs1_ai_dao.dart';
import 'package:label_manager/features/gs1/domain/gs1_ai_definition.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_print/domain/item_code_data_resolver.dart';

void main() {
  group('[QR viewer][barcode/output preview]', () {
    test('maps GS1 AI database flags from string values', () {
      final definition = gs1AiDefinitionFromRow(const {
        'GS1_AI_CODE': '10',
        'GS1_AI_NAME': '로트 번호',
        'GS1_AI_CONTENT': '로트',
        'GS1_DATA_FORMAT': 'X..20',
        'GS1_DATA_FORMAT_TYPE': '1',
        'GS1_NEED_FNC1': '1',
      });

      expect(definition.code, '10');
      expect(definition.dataFormatType, 1);
      expect(definition.needsFnc1, isTrue);
    });

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

    test('resolves valid-date token with DATE_FORMAT_NONE calculation', () {
      final columns = [
        _column(
          id: 1,
          keyword: 'QR',
          name: 'QR 데이터',
          type: TColumnType.TYPE_QR_CODE,
          createType: QRCodeCreateType.QRCODE_TYPE_USER_DEFINE,
          data: '#유통기한',
        ),
        _column(
          id: 2,
          keyword: '제조일자',
          name: '제조일자',
          type: TColumnType.TYPE_MAKEDATE,
        ),
        _column(
          id: 3,
          keyword: '유통기한',
          name: '유통기한',
          type: TColumnType.TYPE_VALIDDATE,
        ),
      ];
      String value(int id) => {2: '20260711', 3: '3'}[id] ?? '';
      final resolver = ItemCodeDataResolver(
        itemName: '품목',
        columns: columns,
        columnValue: value,
        tokenColumnValue: (column) => itemCodeTokenColumnValue(
          column: column,
          columns: columns,
          columnValue: value,
          referenceAt: DateTime(2026, 1, 1),
        ),
      );

      expect(resolver.resolveViewerData().single.data, '20260714');
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

    test('builds GS1 data in contain-column order with FNC1', () {
      final gs1 = _column(
        id: 10,
        keyword: 'GS1',
        name: 'GS1 바코드',
        type: TColumnType.TYPE_GS1_BARCODE,
        useGs1: true,
        containIds: const [2, 1, 3],
        showGs1: true,
      );
      final columns = [
        gs1,
        _column(id: 1, keyword: 'GTIN', name: '상품코드', gs1Ai: '01'),
        _column(id: 2, keyword: 'LOT', name: '로트', gs1Ai: '10'),
        _column(
          id: 3,
          keyword: 'DATE',
          name: '유통기한',
          gs1Ai: '3102',
          gs1FormatOption: 2,
        ),
      ];
      final resolver = ItemCodeDataResolver(
        itemName: '품목',
        columns: columns,
        columnValue: (id) => {1: '123', 2: 'LOT-A', 3: 'display-date'}[id]!,
        tokenColumnValue: (column) => column.columnId == 3
            ? '250101'
            : {1: '123', 2: 'LOT-A'}[column.columnId]!,
        gs1Definitions: const {
          '01': Gs1AiDefinition(
            code: '01',
            name: '',
            content: '',
            dataFormat: '',
            dataFormatType: 0,
            needsFnc1: false,
          ),
          '10': Gs1AiDefinition(
            code: '10',
            name: '',
            content: '',
            dataFormat: '',
            dataFormatType: 0,
            needsFnc1: true,
          ),
          '310': Gs1AiDefinition(
            code: '310',
            name: '',
            content: '',
            dataFormat: '',
            dataFormatType: 0,
            needsFnc1: false,
          ),
        },
      );

      final result = resolver.resolve(gs1);
      expect(result.error, isNull);
      expect(result.data, '10LOT-A${String.fromCharCode(29)}011233102250101');
      expect(result.displayText, result.data);
    });

    test('reports missing GS1 AI definitions without fallback', () {
      final gs1 = _column(
        id: 10,
        keyword: 'GS1',
        name: 'GS1 바코드',
        type: TColumnType.TYPE_GS1_BARCODE,
        useGs1: true,
        containIds: const [1],
      );
      final result = ItemCodeDataResolver(
        itemName: '품목',
        columns: [
          gs1,
          _column(id: 1, keyword: 'LOT', name: '로트', gs1Ai: '10'),
        ],
        columnValue: (_) => 'A',
      ).resolve(gs1);

      expect(result.data, isEmpty);
      expect(result.warning, isNull);
      expect(result.error, contains('GS1 AI 10'));
    });

    test('reports GS1 source values outside the AI data format', () {
      final source = _column(id: 1, keyword: 'GTIN', name: 'GTIN', gs1Ai: '01');
      final gs1 = _column(
        id: 2,
        keyword: 'GS1',
        name: 'GS1',
        type: TColumnType.TYPE_GS1_BARCODE,
        useGs1: true,
        containIds: const [1],
      );
      final resolver = ItemCodeDataResolver(
        itemName: '품목',
        columns: [source, gs1],
        columnValue: (_) => '1234',
        gs1Definitions: const {
          '01': Gs1AiDefinition(
            code: '01',
            name: 'GTIN',
            content: '',
            dataFormat: '01+N14',
            dataFormatType: 0,
            needsFnc1: false,
          ),
        },
      );

      expect(resolver.resolve(gs1).error, contains('GS1 AI 01 형식'));
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
  String gs1Ai = '',
  int gs1FormatOption = -1,
  bool useGs1 = false,
  List<int> containIds = const [],
  bool showGs1 = false,
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
  gs1Ai: gs1Ai,
  gs1FormatOption: gs1FormatOption,
  useGs1Code: useGs1,
  containColumnIds: containIds,
  showGs1Code: showGs1,
);
