import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/date_setup/domain/date_manager.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_print/domain/label_print_auto_increment.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';

void main() {
  test('legacy atoi follows active zero and mixed string rules', () {
    expect(legacyAtoi('0'), 0);
    expect(legacyAtoi('00'), 0);
    expect(legacyAtoi('1A'), 1);
    expect(legacyAtoi(' -12x'), -12);
  });

  test('auto increment uses zero-based index and legacy active check', () {
    expect(_project('0', 0).value, '0000');
    expect(_project('0', 1).value, '0001');
    expect(_project('00', 1).applied, isFalse);
    expect(_project('000', 1).value, '000');
    expect(_project('1A', 0).value, '0001');
    expect(_project('1A', 1).value, '0002');
  });

  test('auto increment subtracts range limit exactly once', () {
    expect(_project('9999', 1, size: 2).value, '0001');
    expect(_project('9999', 1, size: 20002).value, '20001');
  });

  test('auto increment zero deletion controls padding', () {
    expect(_project('0001', 1, zeroDel: false).value, '0002');
    expect(_project('0001', 1, zeroDel: true).value, '2');
  });

  test('barcode transforms run only for active auto increment values', () {
    var checkDigitCalls = 0;
    var timeBarcodeCalls = 0;
    LabelAutoIncrementProjection project(String value) =>
        projectLabelAutoIncrement(
          original: value,
          copyIndex: 1,
          autoIncSize: 1,
          autoIncRange: 2,
          autoIncZeroDel: false,
          referenceAt: DateTime(2026, 7, 16),
          timeBarcodeSuffixLength: 5,
          hasBarcodeCheckDigit: true,
          applyBarcodeCheckDigit: (value) {
            checkDigitCalls += 1;
            return '${value}C';
          },
          applyTimeBarcode: (value, referenceAt) {
            timeBarcodeCalls += 1;
            return '${value}T${referenceAt.day}';
          },
        );

    expect(project('12A0X12345').value, '12A0X12345');
    expect(checkDigitCalls, 0);
    expect(timeBarcodeCalls, 0);
    expect(project('1201X12345').value, '1202CT16');
    expect(checkDigitCalls, 1);
    expect(timeBarcodeCalls, 1);
  });

  test('date setup formats direct output with lowercase custom tokens', () {
    const setup = LabelSizeSetup(
      readOnly: false,
      useMakeDate: true,
      useMakeTime: true,
      useValidDate: true,
      useValidTime: true,
      makingDateFormat: PrintDateFormat.DATE_FORMAT_USER_DEFINE,
      makingTimeFormat: PrintTimeFormat.TIME_FORMAT_USER_DEFINE,
      validDateFormat: PrintDateFormat.DATE_FORMAT_DOT,
      validTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      strMakeDate: 'y/mm/dd',
      strMakeTime: 'h:mm',
      strValidDate: '',
      strValidTime: '',
      useScale: false,
    );

    expect(
      formatLabelDateColumnValue(
        columnType: TColumnType.TYPE_MAKEDATE,
        rawValue: '20260730',
        projectedValue: '20260730',
        setup: setup,
      ),
      '6/07/30',
    );
    expect(
      formatLabelDateColumnValue(
        columnType: TColumnType.TYPE_MAKETIME,
        rawValue: '1201',
        projectedValue: '1201',
        setup: setup,
      ),
      '12:01',
    );
    expect(
      formatLabelDateColumnValue(
        columnType: TColumnType.TYPE_VALIDDATE,
        rawValue: '3',
        projectedValue: '20260802',
        setup: setup,
      ),
      '2026.08.02',
    );
  });

  test('disabled date setup preserves raw cell value', () {
    const setup = LabelSizeSetup(
      readOnly: false,
      useMakeDate: false,
      useMakeTime: false,
      useValidDate: false,
      useValidTime: false,
      makingDateFormat: PrintDateFormat.DATE_FORMAT_DOT,
      makingTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      validDateFormat: PrintDateFormat.DATE_FORMAT_DOT,
      validTimeFormat: PrintTimeFormat.TIME_FORMAT_COLON,
      strMakeDate: '',
      strMakeTime: '',
      strValidDate: '',
      strValidTime: '',
      useScale: false,
    );

    expect(
      formatLabelDateColumnValue(
        columnType: TColumnType.TYPE_VALIDDATE,
        rawValue: '3',
        projectedValue: '20260802',
        setup: setup,
      ),
      '3',
    );
  });

}

LabelAutoIncrementProjection _project(
  String value,
  int index, {
  int size = 1,
  bool zeroDel = false,
}) => projectLabelAutoIncrement(
  original: value,
  copyIndex: index,
  autoIncSize: size,
  autoIncRange: 4,
  autoIncZeroDel: zeroDel,
  referenceAt: DateTime(2026, 7, 16, 12, 34, 56),
);