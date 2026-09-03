import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/item/domain/item_manager_draft.dart';
import 'package:label_manager/home_page_manager.dart';

void main() {
  test('item refresh and order reload do not wait for render readiness', () {
    expect(itemManagerSessionLoadWaitsForRenderReady(isReload: false), isTrue);
    expect(itemManagerSessionLoadWaitsForRenderReady(isReload: true), isFalse);
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
