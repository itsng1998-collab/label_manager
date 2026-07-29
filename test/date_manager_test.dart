import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/date_setup/domain/date_manager.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';

void main() {
  test('date and time custom previews replace legacy tokens', () {
    expect(
      DateManager.datePreview(
        PrintDateFormat.DATE_FORMAT_USER_DEFINE,
        custom: 'Y년 M월 D일',
      ),
      '2000년 01월 01일',
    );
    expect(
      DateManager.timePreview(
        PrintTimeFormat.TIME_FORMAT_USER_DEFINE,
        custom: 'H시 M분',
      ),
      '12시 01분',
    );
  });

  test('invalid date setup indexes use defaults and expose warning state', () {
    final labelSize = labelSizeFromRow({
      'LABELSIZE_ID': 1,
      'BRAND_ID': 2,
      'LABELSIZE_NAME': '테스트',
      'FORM_WIDTH': 80,
      'FORM_HEIGHT': 60,
      'FORM_DATA': '',
      'SETUP_READONLY': 0,
      'SETUP_USE_MAKEDATE': 1,
      'SETUP_USE_MAKETIME': 1,
      'SETUP_USE_VALIDDATE': 1,
      'SETUP_USE_VALIDTIME': 1,
      'SETUP_MAKEDATE_TYPE': '99',
      'SETUP_MAKETIME_TYPE': '-1',
      'SETUP_VALIDDATE_TYPE': '1',
      'SETUP_VALIDTIME_TYPE': 1,
      'USER_MAKEDATE': '',
      'USER_MAKETIME': '',
      'USER_VALIDDATE': '',
      'USER_VALIDTIME': '',
      'SETUP_USE_SCALE': 0,
    });

    expect(
      labelSize.labelSizeSetup!.makingDateFormat,
      PrintDateFormat.DATE_FORMAT_DOT,
    );
    expect(
      labelSize.labelSizeSetup!.makingTimeFormat,
      PrintTimeFormat.TIME_FORMAT_COLON,
    );
    expect(
      labelSize.labelSizeSetup!.validDateFormat,
      PrintDateFormat.DATE_FORMAT_SLASH,
    );
    expect(labelSize.hasInvalidDateSetupValues, isTrue);
  });

  test('date setup update preserves unrelated setup fields', () {
    const current = LabelSizeSetup(
      readOnly: true,
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
      useScale: true,
    );
    const update = LabelSizeDateSetupUpdate(
      useMakeDate: true,
      useMakeTime: true,
      useValidDate: true,
      useValidTime: true,
      makingDateFormat: PrintDateFormat.DATE_FORMAT_HANGUL,
      makingTimeFormat: PrintTimeFormat.TIME_FORMAT_HANGUL,
      validDateFormat: PrintDateFormat.DATE_FORMAT_SLASH_MMDD,
      validTimeFormat: PrintTimeFormat.TIME_FORMAT_HANGUL_hh,
      strMakeDate: 'Y-M-D',
      strMakeTime: 'H:M',
      strValidDate: 'M/D',
      strValidTime: 'H시',
    );

    final merged = current.copyWithDateSetup(update);
    expect(merged.readOnly, isTrue);
    expect(merged.useScale, isTrue);
    expect(merged.validDateFormat, PrintDateFormat.DATE_FORMAT_SLASH_MMDD);
    expect(update.toParams(), hasLength(12));
    expect(update.toParams()['validTimeType'], 3);
  });

  test('date setup SQL updates only date fields without schema branching', () {
    final updateSql = LabelSizeDAO.dateSetupUpdateSql.toUpperCase();
    expect(updateSql, contains('RICH_SETUP_USE_MAKEDATE'));
    expect(updateSql, contains('RICH_USER_VALIDTIME'));
    expect(updateSql, isNot(contains('RICH_SETUP_READONLY')));
    expect(updateSql, isNot(contains('RICH_SETUP_USE_SCALE')));
    expect(updateSql, isNot(contains('SYS.COLUMNS')));
    expect(updateSql, isNot(contains('BM_RICH_LABELSIZE_FORM_LOG')));
  });
}