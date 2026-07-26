import 'package:flutter/material.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

Future<DateTime?> showBlockingDatePicker({
  required BuildContext context,
  required String title,
  required DateTime initialDate,
}) {
  return showBlockingModelessOverlayDialog<DateTime>(
    context: context,
    builder: (overlayContext, close) {
      var selected = initialDate;
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            height: 340,
            child: CalendarDatePicker(
              initialDate: initialDate,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
              onDateChanged: (value) {
                setDialogState(() => selected = value);
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => close(null), child: const Text('취소')),
            FilledButton(
              onPressed: () => close(selected),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    },
  );
}
