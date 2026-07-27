import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  testWidgets('opens above modeless overlay and selects an item', (
    tester,
  ) async {
    String? selected;
    await _pumpInOverlay(
      tester,
      ModelessDropdownFormField<String>(
        initialValue: 'A',
        items: const [
          DropdownMenuItem(value: 'A', child: Text('A')),
          DropdownMenuItem(value: 'B', child: Text('B')),
        ],
        onChanged: (value) => selected = value,
      ),
    );

    final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.fillColor, Colors.white);
    expect(tester.getSize(find.byType(InputDecorator)).height, 40);

    await tester.tap(find.byType(ModelessDropdownFormField<String>));
    await tester.pump();
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('modeless-dropdown-menu-item-1')),
          )
          .height,
      28,
    );
    await tester.tap(find.text('B').last);
    await tester.pump();

    expect(selected, 'B');
  });

  testWidgets('escape closes menu and disabled field uses gray background', (
    tester,
  ) async {
    await _pumpInOverlay(
      tester,
      ModelessDropdownFormField<String>(
        initialValue: 'A',
        items: const [
          DropdownMenuItem(value: 'A', child: Text('A')),
          DropdownMenuItem(value: 'B', child: Text('B')),
        ],
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.byType(ModelessDropdownFormField<String>));
    await tester.pump();
    expect(find.text('B'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('B'), findsNothing);

    await _pumpInOverlay(
      tester,
      const ModelessDropdownFormField<String>(
        initialValue: 'A',
        items: [DropdownMenuItem(value: 'A', child: Text('A'))],
        onChanged: null,
      ),
    );
    final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.fillColor, const Color(0xFFE9ECEF));
  });
}

Future<void> _pumpInOverlay(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(key: UniqueKey(), home: _OverlayHost(child: child)),
  );
  await tester.pump();
}

class _OverlayHost extends StatefulWidget {
  const _OverlayHost({required this.child});

  final Widget child;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final entry = OverlayEntry(
        builder: (_) => Center(
          child: Material(child: SizedBox(width: 220, child: widget.child)),
        ),
      );
      _entry = entry;
      Overlay.of(context).insert(entry);
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}