import 'dart:convert';
import 'dart:async';
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

    test('draft key uses user, customer, brand, and label size', () {
      expect(
        itemManagerDraftKey(
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
        ),
        'user-1_2_8_4',
      );
    });

    test('start clears the previous session journal for another key', () async {
      final draftsDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}item_manager_drafts',
      );
      await draftsDirectory.create();
      final staleFile = File(
        '${draftsDirectory.path}${Platform.pathSeparator}old-key.json',
      );
      await staleFile.writeAsString('{}');
      SharedPreferences.setMockInitialValues({
        ItemManagerDraftJournal.lastPathPreferenceKey: staleFile.path,
        ItemManagerDraftJournal.lastDraftKeyPreferenceKey: 'old-key',
        ItemManagerDraftJournal.lastSavedAtPreferenceKey:
            '2026-07-09T00:00:00Z',
      });
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'new-key',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3],
        ),
        directoryProvider: () async => directory,
      );

      await journal.start();

      expect(await staleFile.exists(), isFalse);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(ItemManagerDraftJournal.lastPathPreferenceKey),
        isNull,
      );
      await journal.close();
    });

    test('writes the pre-import view state into journal metadata', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      controller.replaceAllWithImportedRows(
        const [
          ItemManagerImportedRow(
            itemName: '가져온 품목',
            elementPlain: '',
            elementPayload: 'UEsDempty',
          ),
        ],
        importViewState: const ItemManagerImportViewState(
          selectedItemId: 10,
          selectedIndex: 0,
          baselineChecksum: 'baseline-1',
        ),
      );
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'user-1_2_8_4',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3],
        ),
        directoryProvider: () async => directory,
      );
      await journal.start();
      await journal.flush();

      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      final document =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      final metadata = document['metadata'] as Map<String, dynamic>;
      expect(metadata['importViewState'], {
        'selectedItemId': 10,
        'selectedIndex': 0,
        'baselineChecksum': 'baseline-1',
        'sortState': const [],
        'filterState': const {},
      });
      await journal.close();
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
        expect(document['version'], ItemManagerDraftJournal.schemaVersion);
        expect(DateTime.tryParse(document['createdAt'] as String), isNotNull);
        expect(DateTime.tryParse(document['updatedAt'] as String), isNotNull);
        final baseline = document['baseline'] as Map<String, dynamic>;
        final baselineRow =
            (baseline['rows'] as List).single as Map<String, dynamic>;
        expect(baseline['rowCount'], 1);
        expect(baseline['checksum'], hasLength(16));
        expect(
          baseline['checksumSchemaVersion'],
          ItemManagerDraftJournal.checksumSchemaVersion,
        );
        expect(
          baseline['checksumFields'],
          ItemManagerDraftJournal.checksumFields,
        );
        expect(baselineRow['payloadLength'], source.item.elementRTF.length);
        expect(baselineRow.containsKey('elementPayload'), isFalse);
        expect(baseline['mappingFingerprints'], {
          '10': [3, 5],
        });

        final changes = document['changes'] as Map<String, dynamic>;
        final beforeSnapshots = document['beforeSnapshots'] as List;
        final changedRows = changes['rows'] as List;
        final deletedRows = changes['deletedRows'] as List;
        expect(beforeSnapshots, hasLength(1));
        final beforeSnapshot = beforeSnapshots.single as Map;
        final beforeSource = beforeSnapshot['source'] as Map;
        final beforeItem = beforeSource['item'] as Map;
        expect(beforeItem['itemName'], '기존 품목');
        expect(beforeItem['elementRTF'], source.item.elementRTF);
        expect(
          (beforeSnapshot['columns'] as List).single,
          containsPair('dataString', '00123'),
        );
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

    test('baseline checksum changes with reloaded DB row values', () {
      ItemManagerDraftController controllerFor(String itemName) {
        final source = _itemOfMarket(itemName: itemName);
        return ItemManagerDraftController.fromItems(
          items: [source],
          rawSnapshots: {10: _snapshot()},
          scopedColumnContents: TColumnContentScopedView(const {}),
        );
      }

      final original = controllerFor('기존 품목');
      final same = controllerFor('기존 품목');
      final changed = controllerFor('외부 변경 품목');
      addTearDown(original.dispose);
      addTearDown(same.dispose);
      addTearDown(changed.dispose);

      expect(
        itemManagerBaselineChecksum(same),
        itemManagerBaselineChecksum(original),
      );
      expect(
        itemManagerBaselineChecksum(changed),
        isNot(itemManagerBaselineChecksum(original)),
      );
    });

    test(
      'restores baseline selection from the journal and clears it',
      () async {
        final controller = ItemManagerDraftController.fromItems(
          items: [_itemOfMarket()],
          rawSnapshots: {10: _snapshot()},
          scopedColumnContents: TColumnContentScopedView(const {}),
        );
        addTearDown(controller.dispose);
        controller.setSelection(const ['item:10'], anchorRowKey: 'item:10');
        final journal = ItemManagerDraftJournal(
          controller: controller,
          mappingFingerprints: ItemMarketMappingFingerprints(const {}),
          metadata: const ItemManagerDraftJournalMetadata(
            draftKey: 'restore-key',
            userId: 'user-1',
            customerId: 2,
            brandId: 8,
            labelSizeId: 4,
            currentMarketId: 3,
            targetMarketIds: [3],
          ),
          directoryProvider: () async => directory,
        );
        await journal.start();
        controller.updateItemName('item:10', '변경 품목');
        controller.setSelection(const []);
        await journal.flush();

        expect(
          await journal.restoreBaseline(),
          ItemManagerJournalRestoreResult.restored,
        );
        expect(controller.rows.single.itemName, '기존 품목');
        expect(controller.selectedRowKeys, {'item:10'});
        expect(controller.anchorRowKey, 'item:10');
        expect(controller.isDirty, isFalse);
        final preferences = await SharedPreferences.getInstance();
        expect(
          preferences.getString(ItemManagerDraftJournal.lastPathPreferenceKey),
          isNull,
        );
        await journal.close();
      },
    );

    test('rejects a damaged journal without discarding memory draft', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'damaged-key',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3],
        ),
        directoryProvider: () async => directory,
      );
      await journal.start();
      controller.updateItemName('item:10', '변경 품목');
      await journal.flush();
      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      await File(path).writeAsString('{broken');

      await expectLater(journal.restoreBaseline(), throwsFormatException);
      expect(controller.rows.single.itemName, '변경 품목');
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test('marks a baseline checksum mismatch as invalid', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'mismatch-key',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3],
        ),
        directoryProvider: () async => directory,
      );
      await journal.start();
      controller.updateItemName('item:10', '변경 품목');
      await journal.flush();
      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      final document = jsonDecode(await File(path).readAsString()) as Map;
      (document['baseline'] as Map)['checksum'] = '0000000000000000';
      await File(path).writeAsString(jsonEncode(document));

      expect(
        await journal.restoreBaseline(),
        ItemManagerJournalRestoreResult.invalid,
      );
      expect(controller.rows.single.itemName, '변경 품목');
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test(
      'rejects a tampered before snapshot with a valid checksum field',
      () async {
        final controller = ItemManagerDraftController.fromItems(
          items: [_itemOfMarket()],
          rawSnapshots: {10: _snapshot()},
          scopedColumnContents: TColumnContentScopedView(const {}),
        );
        addTearDown(controller.dispose);
        final journal = ItemManagerDraftJournal(
          controller: controller,
          mappingFingerprints: ItemMarketMappingFingerprints(const {}),
          metadata: const ItemManagerDraftJournalMetadata(
            draftKey: 'tampered-key',
            userId: 'user-1',
            customerId: 2,
            brandId: 8,
            labelSizeId: 4,
            currentMarketId: 3,
            targetMarketIds: [3],
          ),
          directoryProvider: () async => directory,
        );
        await journal.start();
        controller.updateItemName('item:10', '변경 품목');
        await journal.flush();
        final preferences = await SharedPreferences.getInstance();
        final path = preferences.getString(
          ItemManagerDraftJournal.lastPathPreferenceKey,
        )!;
        final document = jsonDecode(await File(path).readAsString()) as Map;
        final snapshot = (document['beforeSnapshots'] as List).single as Map;
        final item = (snapshot['source'] as Map)['item'] as Map;
        item['itemName'] = '변조된 원본';
        await File(path).writeAsString(jsonEncode(document));

        expect(
          await journal.restoreBaseline(),
          ItemManagerJournalRestoreResult.invalid,
        );
        expect(controller.rows.single.itemName, '변경 품목');
        expect(controller.isDirty, isTrue);
        await journal.close();
      },
    );

    test('rejects journal metadata from another current market', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'market-key',
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
      controller.updateItemName('item:10', '변경 품목');
      await journal.flush();
      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      final document = jsonDecode(await File(path).readAsString()) as Map;
      (document['metadata'] as Map)['currentMarketId'] = 9;
      await File(path).writeAsString(jsonEncode(document));

      expect(
        await journal.restoreBaseline(),
        ItemManagerJournalRestoreResult.invalid,
      );
      expect(controller.rows.single.itemName, '변경 품목');
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test(
      'restores deleted row when mapping fingerprint still matches',
      () async {
        final controller = ItemManagerDraftController.fromItems(
          items: [_itemOfMarket()],
          rawSnapshots: {10: _snapshot()},
          scopedColumnContents: TColumnContentScopedView(const {}),
        );
        addTearDown(controller.dispose);
        final journal = ItemManagerDraftJournal(
          controller: controller,
          mappingFingerprints: ItemMarketMappingFingerprints(const {
            10: [3, 5],
          }),
          mappingFingerprintProvider: (_) async =>
              ItemMarketMappingFingerprints(const {
                10: [5, 3],
              }),
          metadata: const ItemManagerDraftJournalMetadata(
            draftKey: 'mapping-match-key',
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
        controller.deleteRows(const ['item:10']);
        await journal.flush();

        expect(
          await journal.restoreBaseline(),
          ItemManagerJournalRestoreResult.restored,
        );
        expect(controller.rows.single.itemName, '기존 품목');
        expect(controller.isDirty, isFalse);
        await journal.close();
      },
    );

    test('detects an external mapping change before delete restore', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {
          10: [3, 5],
        }),
        mappingFingerprintProvider: (_) async =>
            ItemMarketMappingFingerprints(const {
              10: [3, 7],
            }),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'mapping-change-key',
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
      controller.deleteRows(const ['item:10']);
      await journal.flush();

      expect(
        await journal.restoreBaseline(),
        ItemManagerJournalRestoreResult.externalChange,
      );
      expect(controller.rows, isEmpty);
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test('detects a duplicate mapping count change before restore', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {
          10: [3, 5],
        }),
        mappingFingerprintProvider: (_) async =>
            ItemMarketMappingFingerprints(const {
              10: [3, 5, 5],
            }),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'mapping-count-change-key',
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
      controller.deleteRows(const ['item:10']);
      await journal.flush();

      expect(
        await journal.restoreBaseline(),
        ItemManagerJournalRestoreResult.externalChange,
      );
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test('rejects a malformed stored mapping fingerprint', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {
          10: [3, 5],
        }),
        mappingFingerprintProvider: (_) async =>
            ItemMarketMappingFingerprints(const {
              10: [3, 5],
            }),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'mapping-malformed-key',
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
      controller.deleteRows(const ['item:10']);
      await journal.flush();

      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      final document =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      final baseline = document['baseline'] as Map<String, dynamic>;
      final fingerprints =
          baseline['mappingFingerprints'] as Map<String, dynamic>;
      fingerprints['10'] = [3, '5'];
      await File(path).writeAsString(jsonEncode(document));

      expect(
        await journal.restoreBaseline(),
        ItemManagerJournalRestoreResult.invalid,
      );
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test('preserves delete draft when fingerprint lookup fails', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {
          10: [3, 5],
        }),
        mappingFingerprintProvider: (_) async =>
            throw StateError('fingerprint lookup failed'),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'mapping-error-key',
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
      controller.deleteRows(const ['item:10']);
      await journal.flush();

      await expectLater(journal.restoreBaseline(), throwsStateError);
      expect(controller.rows, isEmpty);
      expect(controller.isDirty, isTrue);
      await journal.close();
    });

    test(
      'restores changed row data from file into another controller',
      () async {
        final original = _itemOfMarket();
        final writerController = ItemManagerDraftController.fromItems(
          items: [original],
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
        addTearDown(writerController.dispose);
        final metadata = const ItemManagerDraftJournalMetadata(
          draftKey: 'cross-controller-key',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3],
        );
        final writer = ItemManagerDraftJournal(
          controller: writerController,
          mappingFingerprints: ItemMarketMappingFingerprints(const {}),
          metadata: metadata,
          directoryProvider: () async => directory,
        );
        await writer.start();
        writerController.updateItemName('item:10', '변경 품목');
        writerController.updateColumnValue(
          'item:10',
          columnId: 7,
          editable: true,
          dataString: '99999',
        );
        await writer.flush();
        await writer.close(clearFile: false);

        final readerController = ItemManagerDraftController.fromItems(
          items: [original],
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
        addTearDown(readerController.dispose);
        readerController.updateItemName('item:10', '다른 메모리 변경');
        readerController.updateColumnValue(
          'item:10',
          columnId: 7,
          editable: true,
          dataString: '88888',
        );
        final reader = ItemManagerDraftJournal(
          controller: readerController,
          mappingFingerprints: ItemMarketMappingFingerprints(const {}),
          metadata: metadata,
          directoryProvider: () async => directory,
        );

        expect(
          await reader.restoreBaseline(),
          ItemManagerJournalRestoreResult.restored,
        );
        expect(readerController.rows.single.itemName, '기존 품목');
        expect(
          readerController.columnValue(readerController.rows.single, 7),
          '00123',
        );
        expect(readerController.isDirty, isFalse);
        await reader.close();
      },
    );

    test('can retain a committed journal until reload cleanup', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
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
      controller.updateItemName('item:10', '저장된 품목');
      await journal.flush();

      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      await journal.close(clearFile: false);

      expect(await File(path).exists(), isTrue);
      expect(
        preferences.getString(ItemManagerDraftJournal.lastPathPreferenceKey),
        path,
      );

      await journal.clear();
      expect(await File(path).exists(), isFalse);
      expect(
        preferences.getString(ItemManagerDraftJournal.lastPathPreferenceKey),
        isNull,
      );
    });

    test('recovers a later flush after a journal write failure', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      final invalidDirectoryFile = File('${directory.path}/not-a-directory');
      await invalidDirectoryFile.writeAsString('file');
      var failWrite = true;
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'user-1_4_3',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3, 5],
        ),
        directoryProvider: () async =>
            failWrite ? Directory(invalidDirectoryFile.path) : directory,
      );
      await journal.start();
      controller.updateItemName('item:10', '복구 품목');

      await expectLater(journal.flush(), throwsA(isA<FileSystemException>()));
      failWrite = false;
      await journal.flush();

      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      );
      expect(path, isNotNull);
      expect(await File(path!).exists(), isTrue);
      await journal.close();
    });

    test('keeps draft listener when close cleanup fails', () async {
      final controller = ItemManagerDraftController.fromItems(
        items: [_itemOfMarket()],
        rawSnapshots: {10: _snapshot()},
        scopedColumnContents: TColumnContentScopedView(const {}),
      );
      addTearDown(controller.dispose);
      var failDirectory = false;
      Completer<void>? retryWriteStarted;
      final journal = ItemManagerDraftJournal(
        controller: controller,
        mappingFingerprints: ItemMarketMappingFingerprints(const {}),
        metadata: const ItemManagerDraftJournalMetadata(
          draftKey: 'user-1_4_3',
          userId: 'user-1',
          customerId: 2,
          brandId: 8,
          labelSizeId: 4,
          currentMarketId: 3,
          targetMarketIds: [3, 5],
        ),
        debounceDuration: Duration.zero,
        directoryProvider: () async {
          if (failDirectory) {
            throw const FileSystemException('close cleanup failed');
          }
          if (retryWriteStarted case final completer?
              when !completer.isCompleted) {
            completer.complete();
          }
          return directory;
        },
      );
      await journal.start();
      controller.updateItemName('item:10', '첫 변경');
      await journal.flush();

      final preferences = await SharedPreferences.getInstance();
      final path = preferences.getString(
        ItemManagerDraftJournal.lastPathPreferenceKey,
      )!;
      failDirectory = true;
      await expectLater(journal.close(), throwsA(isA<FileSystemException>()));
      failDirectory = false;
      await File(path).delete();

      retryWriteStarted = Completer<void>();
      controller.updateItemName('item:10', '두 번째 변경');
      await retryWriteStarted.future.timeout(const Duration(seconds: 1));
      await journal.flush();
      expect(await File(path).exists(), isTrue);
      await journal.close();
    });
  });
}

ItemOfMarket _itemOfMarket({String itemName = '기존 품목'}) {
  final date = DateTime(2026, 1, 1);
  return ItemOfMarket(
    marketId: 3,
    item: Item(
      itemId: 10,
      labelSizeId: 4,
      itemName: itemName,
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
