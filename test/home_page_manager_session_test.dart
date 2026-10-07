import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/home_page_manager.dart';

void main() {
  test('search replace brand notification skips duplicate first label load', () {
    expect(
      itemManagerBrandChangeNeedsLabelLoad(
        selectedBrandId: 1200,
        searchReplaceTargetBrandId: 1200,
      ),
      isFalse,
    );
    expect(
      itemManagerBrandChangeNeedsLabelLoad(
        selectedBrandId: 1200,
        searchReplaceTargetBrandId: null,
      ),
      isTrue,
    );
    expect(
      itemManagerBrandChangeNeedsLabelLoad(
        selectedBrandId: 1201,
        searchReplaceTargetBrandId: 1200,
      ),
      isTrue,
    );
    expect(
      itemManagerBrandChangeNeedsLabelLoad(
        selectedBrandId: null,
        searchReplaceTargetBrandId: null,
      ),
      isTrue,
    );
  });

  test('item preview alignment stays above horizontal table scrollbar', () {
    expect(
      itemPreviewBottomRightTarget(
        tableRect: const Rect.fromLTWH(100, 50, 800, 600),
        scrollbarThickness: 12,
      ),
      const Offset(878, 628),
    );
  });

  test('item refresh and order reload do not wait for render readiness', () {
    expect(itemManagerSessionLoadWaitsForRenderReady(isReload: false), isTrue);
    expect(itemManagerSessionLoadWaitsForRenderReady(isReload: true), isFalse);
  });

  test('initial item manager load starts without waiting for progress UI', () {
    final calls = <String>[];

    startItemManagerInitialLoad(
      showProgress: () => calls.add('progress'),
      load: () async => calls.add('load'),
    );

    expect(calls, ['progress', 'load']);
  });

  test('date setup completion clears busy before rebuilding cached tabs', () {
    var commandBusy = true;
    bool? rebuiltWithBusy;

    completeDateSetupCommand(
      setCommandBusy: (value) => commandBusy = value,
      rebuildTabs: () => rebuiltWithBusy = commandBusy,
    );

    expect(commandBusy, isFalse);
    expect(rebuiltWithBusy, isFalse);
  });

  test('item refresh completion clears busy before rebuilding cached tabs', () {
    var commandBusy = true;
    bool? rebuiltWithBusy;

    completeItemRefreshCommand(
      setCommandBusy: (value) => commandBusy = value,
      rebuildTabs: () => rebuiltWithBusy = commandBusy,
    );

    expect(commandBusy, isFalse);
    expect(rebuiltWithBusy, isFalse);
  });

  test('same label reloads when the item manager session is absent', () {
    expect(
      itemManagerSessionAlreadyLoaded(
        requestedLabelSizeId: null,
        currentLabelSizeId: null,
        selectedLabelSizeId: null,
        loadedLabelSizeId: null,
      ),
      isFalse,
    );
    expect(
      itemManagerSessionAlreadyLoaded(
        requestedLabelSizeId: 10,
        currentLabelSizeId: 10,
        selectedLabelSizeId: 10,
        loadedLabelSizeId: null,
      ),
      isFalse,
    );
    expect(
      itemManagerSessionAlreadyLoaded(
        requestedLabelSizeId: 10,
        currentLabelSizeId: 10,
        selectedLabelSizeId: 10,
        loadedLabelSizeId: 10,
      ),
      isTrue,
    );
    expect(
      itemManagerSessionAlreadyLoaded(
        requestedLabelSizeId: 11,
        currentLabelSizeId: 10,
        selectedLabelSizeId: 10,
        loadedLabelSizeId: 10,
      ),
      isFalse,
    );
  });

  test('item output preview allows active editing and unsaved draft', () {
    expect(
      itemOutputPreviewSelectionAllowed(itemDraftCommandBusy: false),
      isTrue,
    );
    expect(
      itemOutputPreviewSelectionAllowed(itemDraftCommandBusy: true),
      isFalse,
    );
  });

  test('item output preview overlays unsaved column drafts', () {
    expect(
      itemOutputPreviewDraftColumnValues(
        baseline: const {7: '저장값', 8: '유지값'},
        drafts: const {
          7: ItemManagerColumnDraft(editable: true, dataString: '편집값'),
          9: ItemManagerColumnDraft(editable: true, dataString: '신규값'),
        },
      ),
      const {7: '편집값', 8: '유지값', 9: '신규값'},
    );
  });
}
