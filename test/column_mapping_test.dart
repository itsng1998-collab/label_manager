import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';

void main() {
  group('TColumn.fromMap', () {
    setUp(() {
      TColumnType.datas = const <TColumnType>[
        TColumnType(code: TColumnType.TYPE_BASE, name: 'base', order: 0),
        TColumnType(code: TColumnType.TYPE_BARCODE, name: 'barcode', order: 1),
      ];
    });

    test('falls back when database enum values are unknown', () {
      final column = TColumn.fromMap({
        'RICH_COLUMN_ID': 1,
        'RICH_LABELSIZE_ID': 4935,
        'RICH_COLUMN_ORDER': 1,
        'RICH_WIDTH': 80,
        'RICH_HEIGHT': 20,
        'RICH_BARCODE_TYPE': 'UNKNOWN_BARCODE',
        'RICH_USE_BARCODE_CHECKDIGIT': 0,
        'RICH_SHOW_BARCODE_NUM': 0,
        'RICH_SHOW_QRCODE_TEXT': 0,
        'RICH_QRTEXT_ALIGNMENT': 999,
        'RICH_USE_USER_DEFINE_QRDATA': 0,
        'RICH_USER_DEFINE_QRDATA': '',
        'RICH_USER_DEFINE_QRTEXT': '',
        'RICH_PIXELSIZE': 0,
        'RICH_TITLE': '',
        'RICH_VISIBLE': 1,
        'RICH_QRCODE_CREATE_TYPE': 999,
        'RICH_NATRIUM_JOIN_STRING': '',
        'RICH_QRTEXT_FONTSIZE': 0,
        'RICH_QRTEXT_FONTNAME': '',
        'RICH_QRCODE_SCALE': 100,
        'RICH_TYPE': 999,
        'RICH_KEYWORD': 'ITEMNAME',
        'RICH_COLUMN_NAME': '품명',
        'RICH_CHECK_YN': 0,
        'RICH_TIMEBARCODE_TYPE': 0,
        'RICH_AUTO_INC': 0,
        'RICH_AUTO_INC_SIZE': 0,
        'RICH_AUTO_INC_RANGE': 0,
        'RICH_AUTO_INC_SAVE': 0,
        'RICH_AUTO_INC_ZERODEL': 0,
        'RICH_SEARCH_PRINT': 0,
        'RICH_USER_DEFINE_BARCODE_TEXT': '',
        'RICH_BARCODE_LINE': 0,
        'RICH_BARCODE_LINE_SIZE': 0,
        'RICH_BARCODE_ROTATE': 0,
        'RICH_AUTO_INC_UPDATE': 0,
        'RICH_USE_DATERANGE': 0,
        'RICH_DATERANGE': '',
        'COLUMN_GS1_CODE': '01',
        'COLUMN_GS1_FORMAT_OPTION': -1,
        'USE_GS1_CODE': 0,
        'CONTAIN_COLUMNS_ID': '',
        'COLUMN_SHOW_GS1CODE': 0,
      });

      expect(column.barcodeType, BarcodeType.Code128);
      expect(column.qrTextAlignment, QRTextAlignment.ALIGN_LEFT);
      expect(column.qrCodeCreateType, QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT);
      expect(column.columnType.code, TColumnType.TYPE_BASE);
    });
  });
}
