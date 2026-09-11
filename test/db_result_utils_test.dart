import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_result_utils.dart';

void main() {
  test('CP949 batch encoding uses one conversion and preserves fields', () async {
    var encodeCalls = 0;

    final encoded = await stringsToHexCp949(
      ['3575', '사용자', '1.3.117', '테스트 거래처', '20260911'],
      encode: (text) async {
        encodeCalls += 1;
        return text.codeUnits;
      },
    );

    expect(encodeCalls, 1);
    expect(encoded, [
      '0x33353735',
      '0xC0ACC6A9C790',
      '0x312E332E313137',
      '0xD14CC2A4D2B820AC70B798CC98',
      '0x3230323630393131',
    ]);
  });

  test('CP949 batch encoding rejects its reserved separator', () async {
    expect(
      () => stringsToHexCp949(['정상', '잘못\u001f된 값']),
      throwsArgumentError,
    );
  });
}