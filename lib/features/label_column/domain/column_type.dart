// ignore_for_file: constant_identifier_names

class TColumnType {
  static const int TYPE_BASE = 0;
  static const int TYPE_VALIDDATE = 1;
  static const int TYPE_VALIDTIME = 2;
  static const int TYPE_BARCODE = 3;
  static const int TYPE_IMAGE = 4;
  static const int TYPE_FIX = 5;
  static const int TYPE_MAKEDATE = 6;
  static const int TYPE_MAKETIME = 7;
  static const int TYPE_NUT = 8;
  static const int TYPE_QR_CODE = 9;
  static const int TYPE_PRINTCOUNT = 10;
  static const int TYPE_GS1_AI = 11;
  static const int TYPE_GS1_BARCODE = 12;
  static const int TYPE_END_OF_CULUMN = 13;

  const TColumnType({
    required this.code,
    required this.name,
    required this.order,
  });

  final int code;
  final String name;
  final int order;

  static List<TColumnType>? datas;

  static TColumnType getFromCode(int code) {
    final columns = datas;
    if (columns == null || columns.isEmpty) {
      throw StateError('TColumnType.datas is not initialized');
    }
    return columns.firstWhere(
      (column) => column.code == code,
      orElse: () => columns.firstWhere(
        (column) => column.code == TYPE_BASE,
        orElse: () => columns.first,
      ),
    );
  }

  @override
  String toString() => 'code: $code, name: $name, order: $order';
}
