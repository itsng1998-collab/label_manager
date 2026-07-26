String systemPasswordForDate([DateTime? now]) {
  final value = now ?? DateTime.now();
  return (value.month * 3 + value.day).toString().padLeft(4, '0');
}