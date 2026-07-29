String directPasswordForDate([DateTime? now]) {
  final value = now ?? DateTime.now();
  final calculated = value.month * 3 + value.day;
  final day = value.day.toString().padLeft(2, '0');
  final password = calculated.toString().padLeft(2, '0');
  return '$day$password';
}

String systemPasswordForDate([DateTime? now]) {
  final value = now ?? DateTime.now();
  return (value.month * 3 + value.day).toString().padLeft(4, '0');
}
