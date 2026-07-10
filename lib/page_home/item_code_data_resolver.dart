import 'package:flutter/foundation.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';

@immutable
class ItemCodeColumnSpec {
  const ItemCodeColumnSpec({
    required this.columnId,
    required this.keyword,
    required this.columnName,
    required this.typeCode,
    required this.barcodeType,
    required this.createType,
    required this.userDefineData,
    required this.userDefineText,
    required this.natriumJoinString,
    required this.showBarcodeText,
    required this.showQrText,
  });

  factory ItemCodeColumnSpec.fromColumn(TColumn column) => ItemCodeColumnSpec(
    columnId: column.columnId,
    keyword: column.keyword,
    columnName: column.columnName,
    typeCode: column.columnType.code,
    barcodeType: column.barcodeType,
    createType: column.qrCodeCreateType,
    userDefineData: column.userDefineQRData,
    userDefineText: column.userDefineQRText,
    natriumJoinString: column.natriumJoinString,
    showBarcodeText: column.showBarcodeNum,
    showQrText: column.showQRCodeText,
  );

  final int columnId;
  final String keyword;
  final String columnName;
  final int typeCode;
  final BarcodeType barcodeType;
  final QRCodeCreateType createType;
  final String userDefineData;
  final String userDefineText;
  final String natriumJoinString;
  final bool showBarcodeText;
  final bool showQrText;
}

@immutable
class ItemCodeDataResult {
  const ItemCodeDataResult({
    required this.column,
    required this.data,
    required this.displayText,
    required this.barcodeFormatId,
    required this.barcodeFormatLabel,
    required this.showText,
    this.warning,
    this.error,
  });

  final ItemCodeColumnSpec column;
  final String data;
  final String displayText;
  final String barcodeFormatId;
  final String barcodeFormatLabel;
  final bool showText;
  final String? warning;
  final String? error;
}

class ItemCodeDataResolver {
  const ItemCodeDataResolver({
    required this.itemName,
    required this.columns,
    required this.columnValue,
    this.tokenColumnValue,
  });

  final String itemName;
  final List<ItemCodeColumnSpec> columns;
  final String Function(int columnId) columnValue;

  /// Allows callers to supply DATE_FORMAT_NONE values for date-like tokens.
  final String Function(ItemCodeColumnSpec column)? tokenColumnValue;

  List<ItemCodeDataResult> resolveViewerData() => [
    for (final column in columns)
      if (_isViewerColumn(column)) resolve(column),
  ];

  ItemCodeDataResult? resolveObject(
    String objectId, {
    String? templateFormatId,
    bool preserveTemplateBarcodeFormat = false,
  }) {
    final normalized = objectId.trim().toLowerCase();
    for (final column in columns) {
      if (!_isBarcodeColumn(column)) continue;
      final keyword = column.keyword.trim();
      final candidate = (keyword.startsWith('#') ? keyword : '#$keyword')
          .toLowerCase();
      if (candidate != normalized) continue;
      return resolve(
        column,
        templateFormatId: templateFormatId,
        preserveTemplateBarcodeFormat: preserveTemplateBarcodeFormat,
      );
    }
    return null;
  }

  ItemCodeDataResult resolve(
    ItemCodeColumnSpec column, {
    String? templateFormatId,
    bool preserveTemplateBarcodeFormat = false,
  }) {
    final payload = _payload(column);
    final requestedFormat = preserveTemplateBarcodeFormat
        ? templateFormatId ?? _formatId(column)
        : _formatId(column);
    final normalized = _normalize(requestedFormat, payload.data);
    if (normalized != null) {
      return _result(
        column,
        data: normalized,
        displayText: payload.text,
        formatId: requestedFormat,
      );
    }
    if (preserveTemplateBarcodeFormat ||
        column.typeCode == TColumnType.TYPE_GS1_BARCODE) {
      return _result(
        column,
        data: payload.data,
        displayText: payload.text,
        formatId: requestedFormat,
        error: '${column.columnName} 데이터를 $requestedFormat 형식으로 표시할 수 없습니다.',
      );
    }
    final fallback = _isQrColumn(column) ? 'qrCode' : 'code128';
    final fallbackValue = _normalize(fallback, payload.data);
    return _result(
      column,
      data: fallbackValue ?? payload.data,
      displayText: payload.text,
      formatId: fallback,
      warning: fallbackValue == null
          ? null
          : '${column.columnName}은 선택 형식에 맞지 않아 $fallback 형식을 사용합니다.',
      error: fallbackValue == null
          ? '${column.columnName} 바코드 데이터가 비어 있습니다.'
          : null,
    );
  }

  ItemCodeDataResult _result(
    ItemCodeColumnSpec column, {
    required String data,
    required String displayText,
    required String formatId,
    String? warning,
    String? error,
  }) => ItemCodeDataResult(
    column: column,
    data: data,
    displayText: displayText,
    barcodeFormatId: formatId,
    barcodeFormatLabel: _formatLabel(formatId),
    showText: _isQrColumn(column) ? column.showQrText : column.showBarcodeText,
    warning: warning,
    error: error,
  );

  ({String data, String text}) _payload(ItemCodeColumnSpec column) {
    final raw = columnValue(column.columnId);
    return switch (column.createType) {
      QRCodeCreateType.QRCODE_TYPE_USER_DEFINE => (
        data: _replaceTokens(column.userDefineData),
        text: _replaceTokens(column.userDefineText),
      ),
      QRCodeCreateType.QRCODE_TYPE_NATRIUM => (
        data: _natriumUrl(column.natriumJoinString),
        text: _natriumUrl(column.natriumJoinString),
      ),
      QRCodeCreateType.BARCODE_TEXT_LINK => (
        data: _replaceTokens(column.userDefineData),
        text: _replaceTokens(column.userDefineData),
      ),
      QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT => (data: raw, text: raw),
    };
  }

  String _replaceTokens(String template) {
    var value = template
        .replaceAll('#품목', itemName)
        .replaceAll('#ITEMNAME', itemName);
    for (final column in columns) {
      final keyword = column.keyword.trim();
      if (keyword.isEmpty) continue;
      final token = keyword.startsWith('#') ? keyword : '#$keyword';
      value = value.replaceAll(
        token,
        tokenColumnValue?.call(column) ?? columnValue(column.columnId),
      );
    }
    return value;
  }

  String _natriumUrl(String serialized) {
    final records = serialized.split('/');
    if (records.length == 7 && records.last.isEmpty) records.removeLast();
    if (records.length != 6) return '';
    final values = <String>[];
    for (final record in records) {
      final separator = record.indexOf('-');
      if (separator <= 0) return '';
      final keyword = record
          .substring(separator + 1)
          .replaceFirst(RegExp(r'-$'), '');
      values.add(
        keyword == '품목' || keyword == '#품목'
            ? itemName
            : _valueForKeyword(keyword),
      );
    }
    final sodium = int.tryParse(values[1]) ?? 0;
    final comparison = int.tryParse(values[3]) ?? 0;
    final rate = comparison == 0
        ? ''
        : '${(sodium / comparison * 100).truncate()}';
    return 'http://www.itsng.co.kr/na3.php'
        '?i=${_legacyUriValue(values[0])}'
        '&p=${_legacyUriValue(values[4])}'
        '&n=$sodium'
        '&t=${_legacyUriValue(values[2])}'
        '&nn=$rate'
        '&it=${Uri.encodeComponent(values[5])}';
  }

  String _valueForKeyword(String keyword) {
    final normalized = keyword.startsWith('#') ? keyword.substring(1) : keyword;
    for (final column in columns) {
      final columnKeyword = column.keyword.startsWith('#')
          ? column.keyword.substring(1)
          : column.keyword;
      if (columnKeyword == normalized) {
        return tokenColumnValue?.call(column) ?? columnValue(column.columnId);
      }
    }
    return '';
  }
}

Map<String, Object?> itemCodeBarcodeMetadata(
  Map<String, Object?> current,
  ItemCodeDataResult result, {
  required bool preserveTemplateBarcodeFormat,
}) {
  final next = Map<String, Object?>.from(current)
    ..['barcodeText'] = result.data;
  if (!preserveTemplateBarcodeFormat) {
    next
      ..['barcodeFormatId'] = result.barcodeFormatId
      ..['barcodeFormatLabel'] = result.barcodeFormatLabel
      ..['barcodeShowText'] = result.showText;
  }
  if (result.warning != null) next['itemCodeWarning'] = result.warning;
  if (result.error != null) next['itemCodeError'] = result.error;
  return next;
}

bool _isViewerColumn(ItemCodeColumnSpec column) =>
    column.typeCode == TColumnType.TYPE_QR_CODE ||
    (column.typeCode == TColumnType.TYPE_BASE &&
        column.createType == QRCodeCreateType.QRCODE_TYPE_USER_DEFINE) ||
    (column.typeCode == TColumnType.TYPE_BARCODE &&
        column.createType == QRCodeCreateType.BARCODE_TEXT_LINK);

bool _isBarcodeColumn(ItemCodeColumnSpec column) =>
    column.typeCode == TColumnType.TYPE_BARCODE ||
    column.typeCode == TColumnType.TYPE_QR_CODE ||
    column.typeCode == TColumnType.TYPE_GS1_BARCODE;

bool _isQrColumn(ItemCodeColumnSpec column) =>
    column.typeCode == TColumnType.TYPE_QR_CODE;

String _formatId(ItemCodeColumnSpec column) {
  if (_isQrColumn(column) &&
      column.barcodeType != BarcodeType.QrCode &&
      column.barcodeType != BarcodeType.MicroQrCode &&
      column.barcodeType != BarcodeType.DataMatrix) {
    return 'qrCode';
  }
  return switch (column.barcodeType) {
    BarcodeType.CodeEAN13 => 'ean13',
    BarcodeType.Code128 => 'code128',
    BarcodeType.Itf => 'itf',
    BarcodeType.DataMatrix => 'dataMatrix',
    BarcodeType.Code39 => 'code39',
    BarcodeType.QrCode => 'qrCode',
    BarcodeType.MicroQrCode => 'microQRCode',
    BarcodeType.UpcA => 'upca',
    BarcodeType.Code93 => 'code93',
    BarcodeType.CodeEAN8 => 'ean8',
  };
}

String? _normalize(String formatId, String raw) {
  if (raw.isEmpty) return null;
  final type = switch (formatId) {
    'ean13' => BarcodeType.CodeEAN13,
    'ean8' => BarcodeType.CodeEAN8,
    'upca' => BarcodeType.UpcA,
    'itf' => BarcodeType.Itf,
    _ => null,
  };
  return type == null
      ? raw
      : BarcodeDataHelper.normalizeMeaningPreservingForPrint(type, raw);
}

String _formatLabel(String formatId) => switch (formatId) {
  'ean13' => 'EAN-13',
  'ean8' => 'EAN-8',
  'upca' => 'UPC-A',
  'itf' => 'ITF',
  'dataMatrix' => 'Data Matrix',
  'qrCode' => 'QR Code',
  'microQRCode' => 'Micro QR Code',
  'code39' => 'Code 39',
  'code93' => 'Code 93',
  _ => 'Code 128',
};

String _legacyUriValue(String value) =>
    Uri.encodeComponent(value).replaceAll('%26', '%09');
