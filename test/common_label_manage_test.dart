import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/page_home/common_label_manage.dart';

TColumnBase _column(
  String keyword, {
  String? columnName,
  bool useMissingKeywordCheck = false,
  int typeCode = TColumnType.TYPE_BASE,
}) {
  return TColumnBase(
    columnType: TColumnType(
      code: typeCode,
      name: 'base',
      order: 0,
    ),
    keyword: keyword,
    columnName: columnName ?? keyword,
    useMissingKeywordCheck: useMissingKeywordCheck,
  );
}

TColumn _storedColumn(
  String keyword, {
  required int typeCode,
  String? columnName,
  BarcodeType barcodeType = BarcodeType.Code128,
  bool showBarcodeNum = false,
}) {
  return TColumn(
    columnType: TColumnType(code: typeCode, name: '항목', order: 0),
    keyword: keyword,
    columnName: columnName ?? keyword,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    columnId: 1,
    labelSizeId: 10,
    order: 1,
    width: 0,
    height: 0,
    barcodeType: barcodeType,
    useBarcodeCheckDigit: false,
    showBarcodeNum: showBarcodeNum,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: true,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 10,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
    timeBarcodeType: 0,
    autoInc: false,
    autoIncSize: 0,
    autoIncSave: false,
    autoIncRange: 0,
    autoIncZeroDel: false,
    autoIncUpdate: false,
    searchPrint: false,
    userDefineBarcodeText: '',
    lineCheck: 0,
    lineSize: 0,
    gs1ai: '',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

void main() {
  test('right pane starts and stops at ten less than previous table width', () {
    expect(commonLabelRightPaneInitialWidth, 350);
    expect(commonLabelRightPaneMinWidth, 350);
  });

  test('keyword and name share resize space while required width stays fixed', () {
    expect(commonLabelColumnWidthsForViewport(350), [120, 120, 70]);
    expect(commonLabelColumnWidthsForViewport(450), [170, 170, 70]);
  });

  test('barcode object ids include only barcode column types', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [
        _column('CODE', typeCode: TColumnType.TYPE_BARCODE),
        _column('#QR_VALUE', typeCode: TColumnType.TYPE_QR_CODE),
        _column('  CODE  ', typeCode: TColumnType.TYPE_GS1_BARCODE),
        _column('BARCODE_TEXT'),
        _column('ITEMNAME'),
      ],
      const [],
    );

    expect(objectIds, ['#CODE', '#QR_VALUE']);
  });

  test('barcode object ids fall back to default when no barcode keyword exists', () {
    final objectIds = commonLabelBarcodeObjectIdsFor(
      [_column('ITEMNAME')],
      const [],
    );

    expect(objectIds, ['#BARCODE']);
  });

  test('image object ids include only image column types', () {
    final objectIds = commonLabelImageObjectIdsFromColumns(
      [
        _column('ITEM_IMAGE', typeCode: TColumnType.TYPE_IMAGE),
        _column('ELEMENT'),
      ],
    );

    final combined = commonLabelImageObjectIdsFromColumns([
      _column('ITEM_IMAGE', typeCode: TColumnType.TYPE_IMAGE),
      _column('  #SUB_IMAGE  ', typeCode: TColumnType.TYPE_IMAGE),
      _column('BARCODE_ID', typeCode: TColumnType.TYPE_BARCODE),
      _column('item_image', typeCode: TColumnType.TYPE_IMAGE),
    ]);

    expect(objectIds, ['#ITEM_IMAGE']);
    expect(combined, ['#ITEM_IMAGE', '#SUB_IMAGE']);
  });

  test('barcode connection options preserve column metadata', () {
    final options = commonLabelBarcodeObjectOptionsFromColumns([
      _storedColumn(
        'ITEM_CODE',
        typeCode: TColumnType.TYPE_BARCODE,
        columnName: '품목 코드',
        barcodeType: BarcodeType.CodeEAN13,
        showBarcodeNum: true,
      ),
      _storedColumn('IMAGE', typeCode: TColumnType.TYPE_IMAGE),
    ]);

    expect(options, hasLength(1));
    expect(options.single.value, '#ITEM_CODE');
    expect(options.single.label, '품목 코드 (#ITEM_CODE) · EAN13');
    expect(options.single.formatId, 'ean13');
    expect(options.single.formatLabel, 'EAN13');
    expect(options.single.showHumanReadableText, isTrue);
  });

  test('image connection options include image columns only', () {
    final options = commonLabelImageObjectOptionsFromColumns([
      _storedColumn(
        '#ITEM_IMAGE',
        typeCode: TColumnType.TYPE_IMAGE,
        columnName: '품목 이미지',
      ),
      _storedColumn('CODE', typeCode: TColumnType.TYPE_BARCODE),
    ]);

    expect(options, hasLength(1));
    expect(options.single.value, '#ITEM_IMAGE');
    expect(options.single.label, '품목 이미지 (#ITEM_IMAGE)');
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
