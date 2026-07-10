import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/date_manager.dart';
import 'package:label_manager/models/label_size.dart';

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
    final labelSize = LabelSize.fromMap({
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
}