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
      formatDate(format, year: 2000, month: 1, day: 1, custom: custom);

  static String timePreview(PrintTimeFormat format, {String custom = ''}) =>
      formatTime(format, hour: 12, minute: 1, custom: custom);

  static String formatDateValue(
    PrintDateFormat format,
    String value, {
    String custom = '',
  }) {
    final source = value.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(source)) return value;
    final year = int.parse(source.substring(0, 4));
    final month = int.parse(source.substring(4, 6));
    final day = int.parse(source.substring(6, 8));
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return value;
    }
    return formatDate(
      format,
      year: year,
      month: month,
      day: day,
      custom: custom,
    );
  }

  static String formatTimeValue(
    PrintTimeFormat format,
    String value, {
    String custom = '',
  }) {
    final source = value.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(source)) return value;
    final hour = int.parse(source.substring(0, 2));
    final minute = int.parse(source.substring(2, 4));
    if (hour > 23 || minute > 59) return value;
    return formatTime(format, hour: hour, minute: minute, custom: custom);
  }

  static String formatDate(
    PrintDateFormat format, {
    required int year,
    required int month,
    required int day,
    String custom = '',
  }) => switch (format) {
    PrintDateFormat.DATE_FORMAT_DOT =>
      '${year.toString().padLeft(4, '0')}.'
          '${month.toString().padLeft(2, '0')}.'
          '${day.toString().padLeft(2, '0')}',
    PrintDateFormat.DATE_FORMAT_SLASH =>
      '${year.toString().padLeft(4, '0')}/'
          '${month.toString().padLeft(2, '0')}/'
          '${day.toString().padLeft(2, '0')}',
    PrintDateFormat.DATE_FORMAT_HANGUL =>
      '${year.toString().padLeft(4, '0')}년'
          '${month.toString().padLeft(2, '0')}월'
          '${day.toString().padLeft(2, '0')}일',
    PrintDateFormat.DATE_FORMAT_NONE =>
      '${year.toString().padLeft(4, '0')}'
          '${month.toString().padLeft(2, '0')}'
          '${day.toString().padLeft(2, '0')}',
    PrintDateFormat.DATE_FORMAT_DOT_MMDD =>
      '${month.toString().padLeft(2, '0')}.'
          '${day.toString().padLeft(2, '0')}',
    PrintDateFormat.DATE_FORMAT_SLASH_MMDD =>
      '${month.toString().padLeft(2, '0')}/'
          '${day.toString().padLeft(2, '0')}',
    PrintDateFormat.DATE_FORMAT_HANGUL_MMDD =>
      '${month.toString().padLeft(2, '0')}월'
          '${day.toString().padLeft(2, '0')}일',
    PrintDateFormat.DATE_FORMAT_USER_DEFINE => custom.replaceAllMapped(
      RegExp(r'[yY]+|[mM]+|[dD]+'),
      (match) => switch (match.group(0)![0].toLowerCase()) {
        'y' => _yearWithWidth(year, match.group(0)!.length),
        'm' => _componentWithWidth(month, match.group(0)!.length),
        _ => _componentWithWidth(day, match.group(0)!.length),
      },
    ),
  };

  static String formatTime(
    PrintTimeFormat format, {
    required int hour,
    required int minute,
    String custom = '',
  }) => switch (format) {
    PrintTimeFormat.TIME_FORMAT_COLON =>
      '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}',
    PrintTimeFormat.TIME_FORMAT_HANGUL =>
      '${hour.toString().padLeft(2, '0')}시'
          '${minute.toString().padLeft(2, '0')}분',
    PrintTimeFormat.TIME_FORMAT_NONE =>
      '${hour.toString().padLeft(2, '0')}'
          '${minute.toString().padLeft(2, '0')}',
    PrintTimeFormat.TIME_FORMAT_HANGUL_hh =>
      '${hour.toString().padLeft(2, '0')}시',
    PrintTimeFormat.TIME_FORMAT_USER_DEFINE => custom.replaceAllMapped(
      RegExp(r'[hH]+|[mM]+'),
      (match) => match.group(0)![0].toLowerCase() == 'h'
          ? _componentWithWidth(hour, match.group(0)!.length)
          : _componentWithWidth(minute, match.group(0)!.length),
    ),
  };

  static String _yearWithWidth(int year, int width) {
    final source = year.toString();
    return width <= source.length
        ? source.substring(source.length - width)
        : source.padLeft(width, '0');
  }

  static String _componentWithWidth(int value, int width) {
    final source = value.toString();
    return width == 1 ? source : source.padLeft(width, '0');
  }
}
