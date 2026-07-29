// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

const int TYPE_VALIDDATE = 1;
const int TYPE_VALIDTIME = 2;
const int TYPE_MAKEDATE = 6;
const int TYPE_MAKETIME = 7;

/*
	주의! 해당 상수의 위치, 값을 수정하면 안된다. 데이터베이스에 특정값으로 저장되어있다.
*/
enum PrintDateFormat {
  DATE_FORMAT_DOT, // YYYY.MM.DD
  DATE_FORMAT_SLASH, // YYYY/MM/DD
  DATE_FORMAT_HANGUL, // YYYY년MM월DD일
  DATE_FORMAT_NONE, // 입력한 그대로
  DATE_FORMAT_DOT_MMDD,
  DATE_FORMAT_SLASH_MMDD,
  DATE_FORMAT_HANGUL_MMDD,
  DATE_FORMAT_USER_DEFINE, // 사용자 정의
}

enum PrintTimeFormat {
  TIME_FORMAT_COLON, // hh:mm
  TIME_FORMAT_HANGUL, // hh시mm분
  TIME_FORMAT_NONE, // 입력그대로
  TIME_FORMAT_HANGUL_hh, // hh시
  TIME_FORMAT_USER_DEFINE, // 사용자 정의
}

class DateManager {
  const DateManager._();

  static String datePreview(PrintDateFormat format, {String custom = ''}) =>
      switch (format) {
        PrintDateFormat.DATE_FORMAT_DOT => '2000.01.01',
        PrintDateFormat.DATE_FORMAT_SLASH => '2000/01/01',
        PrintDateFormat.DATE_FORMAT_HANGUL => '2000년01월01일',
        PrintDateFormat.DATE_FORMAT_NONE => '20000101',
        PrintDateFormat.DATE_FORMAT_DOT_MMDD => '01.01',
        PrintDateFormat.DATE_FORMAT_SLASH_MMDD => '01/01',
        PrintDateFormat.DATE_FORMAT_HANGUL_MMDD => '01월01일',
        PrintDateFormat.DATE_FORMAT_USER_DEFINE =>
          custom
              .replaceAll('Y', '2000')
              .replaceAll('M', '01')
              .replaceAll('D', '01'),
      };

  static String timePreview(PrintTimeFormat format, {String custom = ''}) =>
      switch (format) {
        PrintTimeFormat.TIME_FORMAT_COLON => '12:01',
        PrintTimeFormat.TIME_FORMAT_HANGUL => '12시01분',
        PrintTimeFormat.TIME_FORMAT_NONE => '1201',
        PrintTimeFormat.TIME_FORMAT_HANGUL_hh => '12시',
        PrintTimeFormat.TIME_FORMAT_USER_DEFINE =>
          custom.replaceAll('H', '12').replaceAll('M', '01'),
      };
}
