import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';

void main() {
  group('[barcode/output preview] barcode type normalization', () {
    test('keeps EAN-8 aliases distinct from Code128', () {
      for (final alias in ['EAN8', 'EAN-8', 'CodeEAN8']) {
        expect(barcodeTypeFromDbName(alias), BarcodeType.CodeEAN8);
      }
      for (final alias in ['CODE128', 'Code128']) {
        expect(barcodeTypeFromDbName(alias), BarcodeType.Code128);
      }
    });

    test('normalizes only meaning-preserving numeric payloads', () {
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.CodeEAN8,
          '1234567',
        ),
        BarcodeDataHelper.ean8('1234567'),
      );
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.CodeEAN8,
          '12345670',
        ),
        BarcodeDataHelper.ean8('12345670'),
      );
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.CodeEAN8,
          '123456',
        ),
        isNull,
      );
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.CodeEAN8,
          '123456789',
        ),
        isNull,
      );
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.Itf,
          '1234',
        ),
        '1234',
      );
      expect(
        BarcodeDataHelper.normalizeMeaningPreservingForPrint(
          BarcodeType.Itf,
          '123',
        ),
        isNull,
      );
    });
  });
}
