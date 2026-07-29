class Gs1AiDefinition {
  const Gs1AiDefinition({
    required this.code,
    required this.name,
    required this.content,
    required this.dataFormat,
    required this.dataFormatType,
    required this.needsFnc1,
  });

  final String code;
  final String name;
  final String content;
  final String dataFormat;
  final int dataFormatType;
  final bool needsFnc1;

  bool accepts(String value) {
    if (dataFormat.trim().isEmpty) return true;
    final segments = dataFormat
        .split('+')
        .skip(1)
        .where((segment) => segment.trim().isNotEmpty);
    var offset = 0;
    for (final rawSegment in segments) {
      final segment = rawSegment.trim().toUpperCase();
      final match = RegExp(r'^([NX])(\.\.)?(\d+)$').firstMatch(segment);
      if (match == null) return false;
      final variable = match.group(2) != null;
      final length = int.parse(match.group(3)!);
      final remaining = value.length - offset;
      final take = variable ? remaining.clamp(0, length) : length;
      if (!variable && remaining < length) return false;
      if (variable && remaining > length) return false;
      final part = value.substring(offset, offset + take);
      if (match.group(1) == 'N' && !RegExp(r'^\d*$').hasMatch(part)) {
        return false;
      }
      offset += take;
    }
    return offset == value.length;
  }
}
