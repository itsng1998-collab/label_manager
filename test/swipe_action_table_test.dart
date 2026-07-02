import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

class _Row {
  const _Row(this.name, this.code);

  final String name;
  final String code;
}

Future<void> _pumpTable(
  WidgetTester tester, {
  required void Function(_Row row, int index) onNameDoubleTap,
  bool interactive = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 160,
          child: SwipeActionTable<_Row>(
            rows: const [_Row('Brand A', 'A001')],
            autoFitColumns: false,
            isRowContentInteractive: (_, _) => interactive,
            columns: [
              SwipeActionTableColumn<_Row>(
                header: '브랜드 이름',
                initialWidth: 160,
                text: (row) => row.name,
                onDoubleTap: onNameDoubleTap,
              ),
              SwipeActionTableColumn<_Row>(
                header: '코드',
                initialWidth: 120,
                text: (row) => row.code,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpReorderTable(WidgetTester tester) async {
  final rows = <_Row>[
    const _Row('Brand A', 'A001'),
    const _Row('Brand B', 'B001'),
    const _Row('Brand C', 'C001'),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 180,
          child: StatefulBuilder(
            builder: (context, setState) {
              return SwipeActionTable<_Row>(
                rows: rows,
                autoFitColumns: false,
                rowReorderEnabled: true,
                rowNumberText: (row, _) => 'No ${row.code[0]}',
                onRowReorder: (fromIndex, toIndex) {
                  setState(() {
                    if ((fromIndex - toIndex).abs() == 1) {
                      final movingRow = rows[fromIndex];
                      rows[fromIndex] = rows[toIndex];
                      rows[toIndex] = movingRow;
                      return;
                    }
                    final insertIndex = fromIndex < toIndex
                        ? toIndex - 1
                        : toIndex;
                    final row = rows.removeAt(fromIndex);
                    rows.insert(insertIndex, row);
                  });
                },
                columns: [
                  SwipeActionTableColumn<_Row>(
                    header: '브랜드 이름',
                    initialWidth: 160,
                    text: (row) => row.name,
                  ),
                  SwipeActionTableColumn<_Row>(
                    header: '코드',
                    initialWidth: 120,
                    text: (row) => row.code,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('column double tap invokes only matching column callback', (
    tester,
  ) async {
    _Row? selectedRow;
    int? selectedIndex;

    await _pumpTable(
      tester,
      onNameDoubleTap: (row, index) {
        selectedRow = row;
        selectedIndex = index;
      },
    );

    await _doubleTap(tester, find.text('Brand A'));

    expect(selectedRow?.name, 'Brand A');
    expect(selectedIndex, 0);

    selectedRow = null;
    selectedIndex = null;
    await _doubleTap(tester, find.text('A001'));

    expect(selectedRow, isNull);
    expect(selectedIndex, isNull);
  });

  testWidgets('column double tap runs after row selection frame', (
    tester,
  ) async {
    var called = false;
    var selectedBeforeCallback = false;

    await _pumpTable(
      tester,
      onNameDoubleTap: (_, _) {
        called = true;
        selectedBeforeCallback = tester
            .widgetList<Container>(find.byType(Container))
            .any((container) {
              final decoration = container.decoration;
              return decoration is BoxDecoration &&
                  decoration.color == const Color(0xFFE3F2FD);
            });
      },
    );

    await _doubleTap(tester, find.text('Brand A'));
    expect(called, isTrue);
    expect(selectedBeforeCallback, isTrue);
  });

  testWidgets('column double tap works on blank cell area', (tester) async {
    _Row? selectedRow;
    int? selectedIndex;

    await _pumpTable(
      tester,
      onNameDoubleTap: (row, index) {
        selectedRow = row;
        selectedIndex = index;
      },
    );

    final tableTopLeft = tester.getTopLeft(find.byType(SwipeActionTable<_Row>));
    await _doubleTapAt(tester, tableTopLeft + const Offset(190, 50));

    expect(selectedRow?.name, 'Brand A');
    expect(selectedIndex, 0);
  });

  testWidgets('column double tap is ignored while row content is interactive', (
    tester,
  ) async {
    var called = false;

    await _pumpTable(
      tester,
      interactive: true,
      onNameDoubleTap: (_, _) {
        called = true;
      },
    );

    await _doubleTap(tester, find.text('Brand A'));

    expect(called, isFalse);
  });

  testWidgets('row reorder drag moves row above drop target', (tester) async {
    await _pumpReorderTable(tester);

    final start = tester.getCenter(find.text('Brand A'));
    final target = tester.getCenter(find.text('Brand C'));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    final brandBTop = tester.getTopLeft(find.text('Brand B')).dy;
    final brandATop = tester.getTopLeft(find.text('Brand A')).dy;
    final brandCTop = tester.getTopLeft(find.text('Brand C')).dy;

    expect(brandBTop, lessThan(brandATop));
    expect(brandATop, lessThan(brandCTop));
  });

  testWidgets('adjacent row reorder swaps rows', (tester) async {
    await _pumpReorderTable(tester);

    final start = tester.getCenter(find.text('Brand A'));
    final target = tester.getCenter(find.text('Brand B'));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    final brandBTop = tester.getTopLeft(find.text('Brand B')).dy;
    final brandATop = tester.getTopLeft(find.text('Brand A')).dy;
    final brandCTop = tester.getTopLeft(find.text('Brand C')).dy;

    expect(brandBTop, lessThan(brandATop));
    expect(brandATop, lessThan(brandCTop));
  });

  testWidgets('row drag feedback includes row header', (tester) async {
    await _pumpReorderTable(tester);

    expect(find.text('No A'), findsOneWidget);

    final start = tester.getCenter(find.text('Brand A'));
    final target = tester.getCenter(find.text('Brand B'));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();

    expect(find.text('No A'), findsNWidgets(2));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('row header drag uses shared row reorder behavior', (
    tester,
  ) async {
    await _pumpReorderTable(tester);

    final start = tester.getCenter(find.text('No A'));
    final target = tester.getCenter(find.text('No C'));
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    final rowBTop = tester.getTopLeft(find.text('No B')).dy;
    final rowATop = tester.getTopLeft(find.text('No A')).dy;
    final rowCTop = tester.getTopLeft(find.text('No C')).dy;

    expect(rowBTop, lessThan(rowATop));
    expect(rowATop, lessThan(rowCTop));
  });
}
