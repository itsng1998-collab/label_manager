import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/item.dart';

class ItemOfMarket {
  static List<ItemOfMarket>? datas;

  final int marketId;
  final Item item;
  final AdditionalItem additionalItem;
  final int gdsNo;
  final DateTime dateSaleStart;
  final DateTime dateSaleEnd;
  final double discountPercent;
  final int discountAmount;
  final DateTime dateStartDiscount;
  final DateTime dateEndDiscount;
  final bool useDefineElement;
  final String rtfText;
  final bool useLinefeed;
  final int linefeed;
  final bool useScaleBarcode;
  final int printCount;
  final bool useLabelSize;
  final int labelSizeWidth;
  final int labelSizeHeight;
  final bool useMargin;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPush;
  final double topPush;

  const ItemOfMarket({
    required this.marketId,
    required this.item,
    required this.additionalItem,
    required this.gdsNo,
    required this.dateSaleStart,
    required this.dateSaleEnd,
    required this.discountPercent,
    required this.discountAmount,
    required this.dateStartDiscount,
    required this.dateEndDiscount,
    required this.useDefineElement,
    required this.rtfText,
    required this.useLinefeed,
    required this.linefeed,
    required this.useScaleBarcode,
    required this.printCount,
    required this.useLabelSize,
    required this.labelSizeWidth,
    required this.labelSizeHeight,
    required this.useMargin,
    required this.leftMargin,
    required this.rightMargin,
    required this.topMargin,
    required this.leftPush,
    required this.topPush,
  });

  static void setDatas(List<ItemOfMarket>? values) => datas = values;

  ItemOfMarket copyWith({
    Item? item,
    bool? useLinefeed,
    int? linefeed,
    bool? useScaleBarcode,
    int? printCount,
    bool? useLabelSize,
    int? labelSizeWidth,
    int? labelSizeHeight,
    bool? useMargin,
    double? leftMargin,
    double? rightMargin,
    double? topMargin,
    double? leftPush,
    double? topPush,
  }) => ItemOfMarket(
    marketId: marketId,
    item: item ?? this.item,
    additionalItem: additionalItem,
    gdsNo: gdsNo,
    dateSaleStart: dateSaleStart,
    dateSaleEnd: dateSaleEnd,
    discountPercent: discountPercent,
    discountAmount: discountAmount,
    dateStartDiscount: dateStartDiscount,
    dateEndDiscount: dateEndDiscount,
    useDefineElement: useDefineElement,
    rtfText: rtfText,
    useLinefeed: useLinefeed ?? this.useLinefeed,
    linefeed: linefeed ?? this.linefeed,
    useScaleBarcode: useScaleBarcode ?? this.useScaleBarcode,
    printCount: printCount ?? this.printCount,
    useLabelSize: useLabelSize ?? this.useLabelSize,
    labelSizeWidth: labelSizeWidth ?? this.labelSizeWidth,
    labelSizeHeight: labelSizeHeight ?? this.labelSizeHeight,
    useMargin: useMargin ?? this.useMargin,
    leftMargin: leftMargin ?? this.leftMargin,
    rightMargin: rightMargin ?? this.rightMargin,
    topMargin: topMargin ?? this.topMargin,
    leftPush: leftPush ?? this.leftPush,
    topPush: topPush ?? this.topPush,
  );

  @override
  String toString() =>
      'marketId: $marketId, gdsNo: $gdsNo, dateSaleStart: $dateSaleStart, dateSaleEnd: $dateSaleEnd, '
      'discountPercent: $discountPercent, discountAmount: $discountAmount, dateStartDiscount: $dateStartDiscount, '
      'dateEndDiscount: $dateEndDiscount, useDefineElement: $useDefineElement, rtfText: $rtfText, '
      'useLinefeed: $useLinefeed, linefeed: $linefeed, useScaleBarcode: $useScaleBarcode, '
      'printCount: $printCount, useLabelSize: $useLabelSize, labelSizeWidth: $labelSizeWidth, '
      'labelSizeHeight: $labelSizeHeight, useMargin: $useMargin, leftMargin: $leftMargin, '
      'rightMargin: $rightMargin, topMargin: $topMargin, leftPush: $leftPush, topPush: $topPush';
}
