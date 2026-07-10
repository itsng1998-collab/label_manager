import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_manager_draft_journal.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[item manager draft journal]', () {
    late Directory directory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      directory = await Directory.systemTemp.createTemp('item-draft-journal-');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test(
      'writes lightweight baseline and changed row journal atomically',
      () async {
        final source = _itemOfMarket();
        final controller = ItemManagerDraftController.fromItems(
          items: [source],
          rawSnapshots: {10: _snapshot()},
          scopedColumnContents: TColumnContentScopedView({
            const ColumnItemKey(columnId: 7, itemId: 10): TColumnContent(
              colContentId: 1,
              columnId: 7,
              itemId: 10,
              editable: true,
              dataString: '00123',
            ),
          }),
        );
        addTearDown(controller.dispose);
        final journal = ItemManagerDraftJournal(
          controller: controller,
          mappingFingerprints: ItemMarketMappingFingerprints(const {
            10: [5, 3],
          }),
          metadata: const ItemManagerDraftJournalMetadata(
            draftKey: 'user-1_4_3',
            userId: 'user-1',
            customerId: 2,
            brandId: 8,
            labelSizeId: 4,
            currentMarketId: 3,
            targetMarketIds: [3, 5],
          ),
          directoryProvider: () async => directory,
        );
        await journal.start();

        controller.updateElement(
          'item:10',
          elementPlain: '변경 원료',
          elementPayload: 'UEsD${'x' * 512}',
        );
        controller.deleteRows(const ['item:10']);
        final added = controller.addRows(1, emptyElementPayload: 'UEsDempty');
        controller.updateItemName(added.single.rowKey, '신규 품목');
        await journal.flush();

        final preferences = await SharedPreferences.getInstance();
        final path = preferences.getString(
          ItemManagerDraftJournal.lastPathPreferenceKey,
        );
        expect(path, isNotNull);
        final file = File(path!);
        expect(await file.exists(), isTrue);
        expect(await File('$path.tmp').exists(), isFalse);
        expect(await File('$path.bak').exists(), isFalse);
        final document =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final baseline = document['baseline'] as Map<String, dynamic>;
        final baselineRow =
            (baseline['rows'] as List).single as Map<String, dynamic>;
        expect(baseline['rowCount'], 1);
        expect(baseline['checksum'], hasLength(16));
        expect(baselineRow['payloadLength'], source.item.elementRTF.length);
        expect(baselineRow.containsKey('elementPayload'), isFalse);
        expect(baseline['mappingFingerprints'], {
          '10': [3, 5],
        });

        final changes = document['changes'] as Map<String, dynamic>;
        final changedRows = changes['rows'] as List;
        final deletedRows = changes['deletedRows'] as List;
        expect(changedRows, hasLength(1));
        expect((changedRows.single as Map)['itemName'], '신규 품목');
        expect(deletedRows, hasLength(1));
        expect(
          (deletedRows.single as Map)['elementPayload'],
          startsWith('UEsD'),
        );
        expect(changes['deletedSourceItemIds'], [10]);
        expect(
          preferences.getString(
            ItemManagerDraftJournal.lastDraftKeyPreferenceKey,
          ),
          'user-1_4_3',
        );

        await journal.close();
        expect(await file.exists(), isFalse);
        expect(
          preferences.getString(ItemManagerDraftJournal.lastPathPreferenceKey),
          isNull,
        );
      },
    );
  });
}

ItemOfMarket _itemOfMarket() {
  final date = DateTime(2026, 1, 1);
  return ItemOfMarket(
    marketId: 3,
    item: const Item(
      itemId: 10,
      labelSizeId: 4,
      itemName: '기존 품목',
      labelSizeName: '60x40',
      element: '기존 원료',
      elementRTF: 'UEsDoriginal-payload',
      price: 0,
      order: 1,
    ),
    additionalItem: const AdditionalItem(
      AdditionalItemId: 0,
      itemId: 10,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: date,
    dateSaleEnd: date,
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: date,
    dateEndDiscount: date,
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 100,
    useScaleBarcode: false,
    printCount: 1,
    useLabelSize: false,
    labelSizeWidth: 0,
    labelSizeHeight: 0,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );
}

ItemOfMarketRawSnapshot _snapshot() {
  return const ItemOfMarketRawSnapshot(
    marketId: 3,
    itemId: 10,
    additionalItemId: null,
    gdsNo: null,
    dateSaleStart: null,
    dateSaleEnd: null,
    discountPercent: null,
    discountAmount: null,
    dateStartDiscount: null,
    dateEndDiscount: null,
    useDefineElement: null,
    rtfText: null,
    useLinefeed: null,
    linefeed: null,
    useScaleBarcode: null,
    printCount: null,
    useLabelSize: null,
    labelSizeWidth: null,
    labelSizeHeight: null,
    useMargin: null,
    leftMargin: null,
    rightMargin: null,
    topMargin: null,
    leftPush: null,
    topPush: null,
  );
}
