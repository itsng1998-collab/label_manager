import 'dart:ui' show PointerDeviceKind;

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
  Widget? headerTrailing,
  Widget Function(BuildContext context, bool hasInteractiveRow)?
  headerTrailingBuilder,
  String? rowTooltip,
  void Function(_Row row, int index)? onRowSelected,
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
            rowTooltip: rowTooltip,
            columns: [
              SwipeActionTableColumn<_Row>(
                header: '브랜드 이름',
                initialWidth: 160,
                text: (row) => row.name,
                headerTrailing: headerTrailing,
                headerTrailingBuilder: headerTrailingBuilder,
                onDoubleTap: onNameDoubleTap,
              ),
              SwipeActionTableColumn<_Row>(
                header: '코드',
                initialWidth: 120,
                text: (row) => row.code,
              ),
            ],
            onRowSelected: onRowSelected,
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

Future<void> _pumpEditableNameTable(
  WidgetTester tester, {
  int? editingIndex,
  bool rowSwipeEnabled = true,
  void Function(_Row row, int index)? onNameDoubleTap,
  Widget Function(BuildContext context, _Row row, int index)?
  inlineTrailingBuilder,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 160,
          child: EditableSwipeNameTable<_Row>(
            rows: const [_Row('Brand A', 'A001'), _Row('Brand B', 'B001')],
            header: '브랜드 이름',
            text: (row) => row.name,
            editController: TextEditingController(text: 'Brand A'),
            editFocusNode: FocusNode(),
            editingIndex: editingIndex,
            insertActionIndex: null,
            inserting: false,
            canSubmit: false,
            onToggleEdit: (_, _) {},
            onToggleInsert: (_, _) {},
            onCancelEdit: () {},
            onSubmitEdit: (_) {},
            onNameDoubleTap: onNameDoubleTap,
            inlineTrailingBuilder: inlineTrailingBuilder,
            rowSwipeEnabled: rowSwipeEnabled,
            keepRowContentOnSwipe: true,
            showActionsWhenEmpty: true,
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

  testWidgets('header trailing widget is rendered inside column header', (
    tester,
  ) async {
    await _pumpTable(
      tester,
      headerTrailing: const Icon(Icons.swap_vert, key: ValueKey('order-icon')),
      onNameDoubleTap: (_, _) {},
    );

    expect(find.byKey(const ValueKey('order-icon')), findsOneWidget);
  });

  testWidgets('row selection callback exposes selected row and index', (
    tester,
  ) async {
    _Row? selectedRow;
    int? selectedIndex;

    await _pumpTable(
      tester,
      onNameDoubleTap: (_, _) {},
      onRowSelected: (row, index) {
        selectedRow = row;
        selectedIndex = index;
      },
    );

    await tester.tap(find.text('Brand A'));
    await tester.pump();

    expect(selectedRow?.name, 'Brand A');
    expect(selectedIndex, 0);
  });

  testWidgets('resizable table preserves configured widths and zebra rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 140,
            child: ResizableTable<_Row>(
              rows: const [_Row('Brand A', 'A001'), _Row('Brand B', 'B001')],
              columns: [
                ResizableTableColumn<_Row>(
                  id: 'long-name',
                  title: '매우긴브랜드이름컬럼',
                  width: 80,
                  minWidth: 40,
                  textAccessor: (row) => row.name,
                  cellBuilder: (context, row, index) => SizedBox.expand(
                    key: ValueKey('name-cell-$index'),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(row.name),
                    ),
                  ),
                ),
                ResizableTableColumn<_Row>(
                  id: 'code',
                  title: '코드',
                  width: 120,
                  minWidth: 40,
                  textAccessor: (row) => row.code,
                  cellBuilder: (context, row, index) => SizedBox.expand(
                    key: ValueKey('code-cell-$index'),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(row.code),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('name-cell-0'))).width, 80);
    expect(
      tester.getSize(find.byKey(const ValueKey('code-cell-0'))).width,
      120,
    );
    expect(
      tester.widgetList<Container>(find.byType(Container)).any((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration &&
            decoration.color == const Color(0xFFF2F4F7);
      }),
      isTrue,
    );
  });

  testWidgets(
    'resizable table auto fits column width on separator double tap',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 120,
              child: ResizableTable<_Row>(
                rows: const [_Row('Very long brand name value', 'A001')],
                columns: [
                  ResizableTableColumn<_Row>(
                    id: 'name',
                    title: 'Name',
                    width: 60,
                    minWidth: 40,
                    textAccessor: (row) => row.name,
                    cellBuilder: (context, row, index) => SizedBox.expand(
                      key: const ValueKey('autofit-name-cell'),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(row.name),
                      ),
                    ),
                  ),
                  ResizableTableColumn<_Row>(
                    id: 'code',
                    title: 'Code',
                    width: 120,
                    minWidth: 40,
                    textAccessor: (row) => row.code,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final cellFinder = find.byKey(const ValueKey('autofit-name-cell'));
      expect(tester.getSize(cellFinder).width, 60);

      final separatorX = tester.getTopRight(cellFinder).dx;
      await tester.tapAt(Offset(separatorX, 10));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(Offset(separatorX, 10));
      await tester.pumpAndSettle();

      expect(tester.getSize(cellFinder).width, greaterThan(60));
    },
  );

  testWidgets(
    'editable name table toggle button opens and closes action rail',
    (tester) async {
      await _pumpEditableNameTable(tester);

      expect(find.byTooltip('수정/삽입/삭제 열기'), findsNWidgets(2));
      expect(find.byTooltip('수정/삽입/삭제 닫기'), findsNothing);
      expect(
        tester.getCenter(find.byTooltip('수정/삽입/삭제 열기').first).dx,
        greaterThan(tester.getCenter(find.text('Brand A')).dx),
      );
      final openButton = find.descendant(
        of: find.byTooltip('수정/삽입/삭제 열기').first,
        matching: find.byType(IconButton),
      );
      expect(
        tester.getTopRight(openButton).dx,
        lessThanOrEqualTo(
          tester.getTopRight(find.byType(SwipeActionTable<_Row>)).dx - 2,
        ),
      );

      await tester.tap(find.byTooltip('수정/삽입/삭제 열기').first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('수정/삽입/삭제 닫기'), findsOneWidget);

      await tester.tap(find.byTooltip('수정/삽입/삭제 닫기'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('수정/삽입/삭제 열기'), findsNWidgets(2));
      expect(find.byTooltip('수정/삽입/삭제 닫기'), findsNothing);
    },
  );

  testWidgets(
    'editable name table toggle button does not trigger name double tap',
    (tester) async {
      var doubleTapCount = 0;
      await _pumpEditableNameTable(
        tester,
        onNameDoubleTap: (_, _) => doubleTapCount += 1,
      );

      await tester.tap(find.byTooltip('수정/삽입/삭제 열기').first);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byTooltip('수정/삽입/삭제 닫기'));
      await tester.pumpAndSettle();

      expect(doubleTapCount, 0);
    },
  );

  testWidgets(
    'editable name table disables swipe toggle while inline editing',
    (tester) async {
      await _pumpEditableNameTable(tester, editingIndex: 0);

      final button = tester.widget<IconButton>(
        find.descendant(
          of: find.byTooltip('수정/삽입/삭제 열기'),
          matching: find.byType(IconButton),
        ),
      );

      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'editable name table hides swipe toggle when row swipe is disabled',
    (tester) async {
      await _pumpEditableNameTable(tester, rowSwipeEnabled: false);

      expect(find.byTooltip('수정/삽입/삭제 열기'), findsNothing);
      expect(find.byTooltip('수정/삽입/삭제 닫기'), findsNothing);
    },
  );

  testWidgets(
    'editable name table places inline trailing after submit button',
    (tester) async {
      await _pumpEditableNameTable(
        tester,
        editingIndex: 0,
        inlineTrailingBuilder: (_, _, _) => const SizedBox(
          key: ValueKey('inline-trailing'),
          width: 44,
          height: 22,
        ),
      );

      expect(find.byKey(const ValueKey('inline-trailing')), findsOneWidget);
      expect(
        tester.getTopRight(find.byType(TextField)).dx,
        lessThanOrEqualTo(tester.getTopLeft(find.byTooltip('변경 적용')).dx),
      );
      expect(
        tester.getCenter(find.byTooltip('변경 적용')).dx,
        lessThan(
          tester.getCenter(find.byKey(const ValueKey('inline-trailing'))).dx,
        ),
      );
    },
  );

  testWidgets('editable name table allows keyboard text editing', (
    tester,
  ) async {
    await _pumpEditableNameTable(tester, editingIndex: 0);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Brand A edited');
    await tester.pump();

    expect(find.text('Brand A edited'), findsOneWidget);
  });

  testWidgets('header trailing builder receives interactive row state', (
    tester,
  ) async {
    var pressed = false;

    await _pumpTable(
      tester,
      interactive: true,
      onNameDoubleTap: (_, _) {},
      headerTrailingBuilder: (context, hasInteractiveRow) => IconButton(
        key: const ValueKey('order-button'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.swap_vert),
        onPressed: hasInteractiveRow ? null : () => pressed = true,
      ),
    );

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('order-button')),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('order-button')));
    await tester.pump();

    expect(pressed, isFalse);
  });

  testWidgets('row tooltip refreshes when message changes under cursor', (
    tester,
  ) async {
    var tooltip = '행 드래그로 순서 변경, 컬럼 왼쪽 스와이프 수정/삽입/삭제';
    late StateSetter updateState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return SizedBox(
                width: 360,
                height: 160,
                child: SwipeActionTable<_Row>(
                  rows: const [_Row('Brand A', 'A001')],
                  autoFitColumns: false,
                  rowTooltip: tooltip,
                  columns: [
                    SwipeActionTableColumn<_Row>(
                      header: '브랜드 이름',
                      initialWidth: 160,
                      text: (row) => row.name,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final bodyPosition = tester.getCenter(find.text('Brand A'));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: bodyPosition);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(tooltip), findsOneWidget);

    updateState(() {
      tooltip = '순서 변경 중에는 스와이프 수정/삽입/삭제를 사용할 수 없습니다';
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('순서 변경 중에는 스와이프 수정/삽입/삭제를 사용할 수 없습니다'), findsOneWidget);

    await gesture.removePointer();
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
