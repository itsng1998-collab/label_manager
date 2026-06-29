# fortune_sheet

Flutter canvas port of FortuneSheet.

## Usage

Import the public package barrel and place `FortuneSheetApp` in your widget tree:

```dart
import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';

void main() {
  runApp(const FortuneSheetApp());
}
```

To open a specific workbook, pass it to the app wrapper:

```dart
final workbook = FortuneWorkbook(
  sheets: [FortuneSheet(id: 'sheet_01', name: 'Sheet1')],
);

runApp(FortuneSheetApp(workbook: workbook));
```

For lower-level embedding, use `FortuneSheetCanvas` directly with a `FortuneWorkbook`.

Third-party license notices are kept in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
