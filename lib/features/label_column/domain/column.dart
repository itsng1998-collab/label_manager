// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/models/barcode.dart';

enum QRTextAlignment {
  ALIGN_LEFT(0),
  ALIGN_CENTER(1),
  ALIGN_RIGHT(2);

  final int code;
  const QRTextAlignment(this.code);
}

enum QRCodeCreateType {
  QRCODE_TYPE_PLAIN_TEXT(0),
  QRCODE_TYPE_USER_DEFINE(1),
  QRCODE_TYPE_NATRIUM(2),
  BARCODE_TEXT_LINK(3);

  final int code;
  const QRCodeCreateType(this.code);
}

class TColumn extends TColumnBase {
  final int columnId;
  final int labelSizeId;
  final int order;
  final int width;
  final int height;
  final BarcodeType barcodeType;
  final bool useBarcodeCheckDigit;
  final bool showBarcodeNum;
  final bool showQRCodeText;
  bool checkMode = false;
  final QRTextAlignment qrTextAlignment;
  final bool useUserDefineQRData;
  final String userDefineQRData;
  final String userDefineQRText;
  final int pixelSize;
  final String title;
  final bool visible;
  int editableCellNum = 0;
  final QRCodeCreateType qrCodeCreateType;
  final String natriumJoinString;
  final int qrTextFontSize;
  final String qrTextFontName;
  final int qrCodeScalePercent;
  bool newColumnQRCodeInfo = false;
  final int timeBarcodeType;
  int barFontSize = 0;
  final bool autoInc;
  final int autoIncSize;
  final bool autoIncSave;
  final int autoIncRange;
  final bool autoIncZeroDel;
  final bool autoIncUpdate;

  bool modify = false;
  final bool searchPrint;
  final String userDefineBarcodeText;

  bool change = false;
  final int lineCheck;
  final int lineSize;

  final String gs1ai;
  final int formatOption;
  final bool useGS1Code;
  final String containColumns;
  final bool showGS1Code;

  final int rotate;

  final bool useDateRange;
  final String dateRange;

  TColumn({
    required super.columnType,
    required super.keyword,
    required super.columnName,
    required super.useMissingKeywordCheck,
    required super.useMinColumnCheck,
    required this.columnId,
    required this.labelSizeId,
    required this.order,
    required this.width,
    required this.height,
    required this.barcodeType,
    required this.useBarcodeCheckDigit,
    required this.showBarcodeNum,
    required this.showQRCodeText,
    required this.qrTextAlignment,
    required this.useUserDefineQRData,
    required this.userDefineQRData,
    required this.userDefineQRText,
    required this.pixelSize,
    required this.title,
    required this.visible,
    required this.qrCodeCreateType,
    required this.natriumJoinString,
    required this.qrTextFontSize,
    required this.qrTextFontName,
    required this.qrCodeScalePercent,
    required this.timeBarcodeType,
    required this.autoInc,
    required this.autoIncSize,
    required this.autoIncSave,
    required this.autoIncRange,
    required this.autoIncZeroDel,
    required this.autoIncUpdate,
    required this.searchPrint,
    required this.userDefineBarcodeText,
    required this.lineCheck,
    required this.lineSize,
    required this.gs1ai,
    required this.formatOption,
    required this.useGS1Code,
    required this.containColumns,
    required this.showGS1Code,
    required this.rotate,
    required this.useDateRange,
    required this.dateRange,
  });

  TColumn copyWith({
    TColumnType? columnType,
    String? keyword,
    String? columnName,
    bool? useMissingKeywordCheck,
    bool? useMinColumnCheck,
    int? columnId,
    int? labelSizeId,
    int? order,
    int? width,
    int? height,
    BarcodeType? barcodeType,
    bool? useBarcodeCheckDigit,
    bool? showBarcodeNum,
    bool? showQRCodeText,
    QRTextAlignment? qrTextAlignment,
    bool? useUserDefineQRData,
    String? userDefineQRData,
    String? userDefineQRText,
    int? pixelSize,
    String? title,
    bool? visible,
    QRCodeCreateType? qrCodeCreateType,
    String? natriumJoinString,
    int? qrTextFontSize,
    String? qrTextFontName,
    int? qrCodeScalePercent,
    int? timeBarcodeType,
    bool? autoInc,
    int? autoIncSize,
    bool? autoIncSave,
    int? autoIncRange,
    bool? autoIncZeroDel,
    bool? autoIncUpdate,
    bool? searchPrint,
    String? userDefineBarcodeText,
    int? lineCheck,
    int? lineSize,
    String? gs1ai,
    int? formatOption,
    bool? useGS1Code,
    String? containColumns,
    bool? showGS1Code,
    int? rotate,
    bool? useDateRange,
    String? dateRange,
  }) {
    return TColumn(
      columnType: columnType ?? this.columnType,
      keyword: keyword ?? this.keyword,
      columnName: columnName ?? this.columnName,
      useMissingKeywordCheck: useMissingKeywordCheck ?? this.useMissingKeywordCheck,
      useMinColumnCheck: useMinColumnCheck ?? this.useMinColumnCheck,
      columnId: columnId ?? this.columnId,
      labelSizeId: labelSizeId ?? this.labelSizeId,
      order: order ?? this.order,
      width: width ?? this.width,
      height: height ?? this.height,
      barcodeType: barcodeType ?? this.barcodeType,
      useBarcodeCheckDigit: useBarcodeCheckDigit ?? this.useBarcodeCheckDigit,
      showBarcodeNum: showBarcodeNum ?? this.showBarcodeNum,
      showQRCodeText: showQRCodeText ?? this.showQRCodeText,
      qrTextAlignment: qrTextAlignment ?? this.qrTextAlignment,
      useUserDefineQRData: useUserDefineQRData ?? this.useUserDefineQRData,
      userDefineQRData: userDefineQRData ?? this.userDefineQRData,
      userDefineQRText: userDefineQRText ?? this.userDefineQRText,
      pixelSize: pixelSize ?? this.pixelSize,
      title: title ?? this.title,
      visible: visible ?? this.visible,
      qrCodeCreateType: qrCodeCreateType ?? this.qrCodeCreateType,
      natriumJoinString: natriumJoinString ?? this.natriumJoinString,
      qrTextFontSize: qrTextFontSize ?? this.qrTextFontSize,
      qrTextFontName: qrTextFontName ?? this.qrTextFontName,
      qrCodeScalePercent: qrCodeScalePercent ?? this.qrCodeScalePercent,
      timeBarcodeType: timeBarcodeType ?? this.timeBarcodeType,
      autoInc: autoInc ?? this.autoInc,
      autoIncSize: autoIncSize ?? this.autoIncSize,
      autoIncSave: autoIncSave ?? this.autoIncSave,
      autoIncRange: autoIncRange ?? this.autoIncRange,
      autoIncZeroDel: autoIncZeroDel ?? this.autoIncZeroDel,
      autoIncUpdate: autoIncUpdate ?? this.autoIncUpdate,
      searchPrint: searchPrint ?? this.searchPrint,
      userDefineBarcodeText: userDefineBarcodeText ?? this.userDefineBarcodeText,
      lineCheck: lineCheck ?? this.lineCheck,
      lineSize: lineSize ?? this.lineSize,
      gs1ai: gs1ai ?? this.gs1ai,
      formatOption: formatOption ?? this.formatOption,
      useGS1Code: useGS1Code ?? this.useGS1Code,
      containColumns: containColumns ?? this.containColumns,
      showGS1Code: showGS1Code ?? this.showGS1Code,
      rotate: rotate ?? this.rotate,
      useDateRange: useDateRange ?? this.useDateRange,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  static List<TColumn>? datas;

  static void setDatas(List<TColumn>? values) {
    datas = values;
  }
}