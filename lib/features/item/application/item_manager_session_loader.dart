import 'package:collection/collection.dart';
import 'package:label_manager/features/gs1/application/gs1_ai_definitions.dart';
import 'package:label_manager/features/gs1/domain/gs1_ai_definition.dart';
import 'package:label_manager/features/item/data/column_content_dao.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/label_column/application/special_columns.dart';
import 'package:label_manager/features/label_column/data/column_dao.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/features/market/data/market_dao.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/features/item/data/item_of_market_dao.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/models/market.dart';
import 'package:label_manager/core/user.dart';

class ItemManagerSessionData {
  const ItemManagerSessionData({
    required this.targetMarketIds,
    required this.columns,
    required this.specialColumns,
    required this.items,
    required this.scopedColumnContents,
    required this.draftController,
  });

  final List<int> targetMarketIds;
  final List<TColumn> columns;
  final List<TColumnBase> specialColumns;
  final List<ItemOfMarket> items;
  final TColumnContentScopedView scopedColumnContents;
  final ItemManagerDraftController draftController;
}

Future<ItemManagerSessionData> loadItemManagerSession({
  required LabelSize labelSize,
  required Customer? customer,
  required Market? market,
  required User? user,
}) async {
  if (customer == null || market == null || user == null) {
    throw StateError('품목관리 편집 세션의 로그인 정보가 없습니다.');
  }
  if (market.customerId != customer.customerId) {
    throw StateError('현재 거래처와 로그인 고객 정보가 일치하지 않습니다.');
  }

  final targetMarkets =
      await MarketDAO.selectByCustomerId(customer.customerId) ??
      const <Market>[];
  if (targetMarkets.isEmpty ||
      !targetMarkets.any((value) => value.marketId == market.marketId)) {
    throw StateError('저장 대상 market 목록에서 현재 market을 찾을 수 없습니다.');
  }

  final columns =
      await TColumnDAO.selectByLabelSizeId(labelSize.labelSizeId) ??
      const <TColumn>[];
  final specialColumns =
      await TColumnSpecial.selectByLabelSizeId(labelSize.labelSizeId) ??
      const <TColumnBase>[];
  final items =
      await ItemOfMarketDAO.selectByItemOfMarketAndLabelSizeId(
        market.marketId,
        labelSize.labelSizeId,
      ) ??
      const <ItemOfMarket>[];
  final scopedColumnContents = await TColumnContentDAO.selectScopedByItemIds(
    items.map((item) => item.item.itemId),
  );
  final draftController = ItemManagerDraftController.fromItems(
    items: items,
    scopedColumnContents: scopedColumnContents,
    validationRules: [
      for (final column in columns)
        ItemManagerColumnValidationRule(
          columnId: column.columnId,
          columnName: column.columnName,
          typeCode: column.columnType.code,
          required: column.useMissingKeywordCheck,
          barcodeType: column.barcodeType,
          useBarcodeCheckDigit: column.useBarcodeCheckDigit,
          useDateRange: column.useDateRange,
          dateRange: column.dateRange,
          gs1Definition: _itemManagerGs1Definition(column),
          timeBarcodeType: column.timeBarcodeType,
        ),
    ],
    requireElement:
        specialColumns
            .firstWhereOrNull(
              (column) =>
                  column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword,
            )
            ?.useMissingKeywordCheck ==
        true,
    labelSizeName: labelSize.labelSizeName,
  );

  return ItemManagerSessionData(
    targetMarketIds: targetMarkets
        .map((value) => value.marketId)
        .toList(growable: false),
    columns: columns,
    specialColumns: specialColumns,
    items: items,
    scopedColumnContents: scopedColumnContents,
    draftController: draftController,
  );
}

Gs1AiDefinition? _itemManagerGs1Definition(TColumn column) {
  if (column.columnType.code != TColumnType.TYPE_GS1_AI) return null;
  final ai = column.gs1ai;
  final definitionCode = column.formatOption == -1
      ? ai
      : ai.length >= 2
      ? ai.substring(0, ai.length - 1)
      : '';
  return Gs1AiDefinitions.values[definitionCode];
}