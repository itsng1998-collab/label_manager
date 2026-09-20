import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/utils/regression_debug_log.dart';

void main() {
  test('regression log includes version feature event and ordered fields', () {
    expect(
      RegressionDebugLog.message(
        'userSearch',
        'focusRestored',
        fields: const {'selectedIndex': 2, 'hasFocus': true},
      ),
      '[regression-debug-v1] feature=userSearch event=focusRestored '
      'selectedIndex=2 hasFocus=true',
    );
  });
}