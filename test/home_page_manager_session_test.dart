import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/home_page_manager.dart';

void main() {
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
}