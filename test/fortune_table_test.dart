import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/item_manage.dart';
import 'package:label_manager/home_page_manager.dart';

void main() {
  test('brand name submission gate ignores concurrent submissions', () async {
    final gate = BrandNameSubmissionGate();
    final completer = Completer<void>();
    var submissions = 0;

    final first = gate.run(() async {
      submissions += 1;
      await completer.future;
    });
    final second = gate.run(() async {
      submissions += 1;
    });

    expect(gate.submitting, isTrue);
    await second;
    expect(submissions, 1);
    completer.complete();
    await first;
    expect(gate.submitting, isFalse);

    await gate.run(() async {
      submissions += 1;
    });
    expect(submissions, 2);
  });

  test('brand name submission gate unlocks after failure', () async {
    final gate = BrandNameSubmissionGate();

    await expectLater(
      gate.run(() async => throw StateError('save failed')),
      throwsStateError,
    );

    expect(gate.submitting, isFalse);
    await gate.run(() async {});
  });

  test('item element commit queue serializes work and reports failure', () async {
    final queue = ItemElementCommitQueue();
    final firstCompleter = Completer<void>();
    final calls = <String>[];

    final first = queue.enqueue(() async {
      calls.add('first-start');
      await firstCompleter.future;
      calls.add('first-end');
    });
    final second = queue.enqueue(() async {
      calls.add('second');
      throw StateError('backup failed');
    });

    await Future<void>.delayed(Duration.zero);
    expect(calls, ['first-start']);
    firstCompleter.complete();
    await first;
    await expectLater(second, throwsStateError);
    expect(calls, ['first-start', 'first-end', 'second']);
    await expectLater(queue.wait(), throwsStateError);
    await queue.wait();
  });

  test('item manager search is visible only on the item tab', () {
    expect(itemManagerSearchVisibleForTab('items'), isTrue);
    expect(itemManagerSearchVisibleForTab('common_label'), isFalse);
    expect(itemManagerSearchVisibleForTab('label_print'), isFalse);
    expect(itemManagerSearchVisibleForTab('auto_update'), isFalse);
    expect(itemManagerSearchVisibleForTab(null), isFalse);
  });

  test('item manager formats single and multiple delete confirmations', () {
    expect(
      itemManagerDeleteConfirmationMessage(
        firstItemName: 'A',
        selectedCount: 1,
      ),
      "선택한 'A'를 삭제하시겠습니까?",
    );
    expect(
      itemManagerDeleteConfirmationMessage(
        firstItemName: 'A',
        selectedCount: 2,
      ),
      "선택한 'A' 외 1개 항목을 모두 삭제하시겠습니까?",
    );
  });

  test('item manager persists dynamic cells only for legacy editable grades', () {
    expect(
      itemManagerCanPersistDynamicCell(
        canManageItemStructure: true,
        commandBusy: false,
        hasDraftRow: true,
      ),
      isTrue,
    );
    expect(
      itemManagerCanPersistDynamicCell(
        canManageItemStructure: false,
        commandBusy: false,
        hasDraftRow: true,
      ),
      isFalse,
    );
  });

  testWidgets('FortuneTable commits and cancels inline text editing', (
    tester,
  ) async {
    var value = '원본';
    var committed = '';
    var commitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: StatefulBuilder(
              builder: (context, setState) => FortuneTable<String>(
                rows: [value],
                columns: [
                  FortuneTableColumn<String>(
                    id: 'name',
                    header: '이름',
                    text: (row) => row,
                    isTextEditable: (_, _) => true,
                    onTextCommitted: (_, _, next) {
                      commitCount += 1;
                      committed = next;
                      setState(() => value = next);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('원본'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('원본'));
    await tester.pump();
    expect(find.byType(EditableText), findsOneWidget);
    final editorBox = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.byType(EditableText),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final editorSize = tester.getSize(
      find.ancestor(
        of: find.byType(EditableText),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    expect(editorSize, const Size(59, 27));
    final editorDecoration = editorBox.decoration as BoxDecoration;
    expect(editorDecoration.color, const Color(0xFFE3F2FD));
    expect(
      editorDecoration.border,
      Border.all(color: const Color(0xFF0188FB), width: 2),
    );
    await tester.enterText(find.byType(EditableText), '수정');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(committed, '수정');
    expect(commitCount, 1);
    expect(find.text('수정'), findsOneWidget);

    await tester.tap(find.text('수정'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('수정'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(commitCount, 1);

    await tester.tap(find.text('수정'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('수정'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '취소 값');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(committed, '수정');
    expect(commitCount, 1);
    expect(find.text('수정'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('FortuneTable editing controller waits for active commit', (
    tester,
  ) async {
    final editingController = FortuneTableEditingController();
    final commitCompleter = Completer<void>();
    var committed = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: FortuneTable<String>(
              rows: const ['원본'],
              editingController: editingController,
              columns: [
                FortuneTableColumn<String>(
                  id: 'name',
                  header: '이름',
                  text: (row) => row,
                  isTextEditable: (_, _) => true,
                  onTextCommitted: (_, _, next) async {
                    await commitCompleter.future;
                    committed = next;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('원본'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('원본'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '수정');

    var completed = false;
    final commit = editingController.commitEditing().then((_) {
      completed = true;
    });
    await tester.pump();
    expect(completed, isFalse);
    expect(committed, isEmpty);

    commitCompleter.complete();
    await commit;
    expect(completed, isTrue);
    expect(committed, '수정');
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('FortuneTable delegates custom double tap editing', (
    tester,
  ) async {
    var doubleTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: FortuneTable<String>(
              rows: const ['logo.bmp'],
              columns: [
                FortuneTableColumn<String>(
                  id: 'image',
                  header: '이미지',
                  text: (row) => row,
                  onDoubleTap: (_, _) => doubleTapCount += 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('logo.bmp'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('logo.bmp'));
    await tester.pump();

    expect(doubleTapCount, 1);
    expect(find.byType(EditableText), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('FortuneTable commits editing when another cell is clicked', (
    tester,
  ) async {
    final rows = ['첫째', '둘째'];
    var commitCount = 0;
    var selectedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: StatefulBuilder(
              builder: (context, setState) => FortuneTable<String>(
                rows: rows,
                onRowSelected: (_, index) => selectedIndex = index,
                columns: [
                  FortuneTableColumn<String>(
                    id: 'name',
                    header: '이름',
                    text: (row) => row,
                    isTextEditable: (_, _) => true,
                    onTextCommitted: (row, _, next) {
                      commitCount += 1;
                      setState(() => rows[rows.indexOf(row)] = next);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('첫째'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('첫째'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '첫째 수정');

    await tester.tap(find.text('둘째'));
    await tester.pumpAndSettle();

    expect(commitCount, 1);
    expect(find.byType(EditableText), findsNothing);
    expect(find.text('첫째 수정'), findsOneWidget);
    expect(selectedIndex, 1);
  });

  testWidgets('FortuneTable starts selected cell editing from keyboard', (
    tester,
  ) async {
    var value = '원본';
    var commitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 140,
            child: StatefulBuilder(
              builder: (context, setState) => FortuneTable<String>(
                rows: [value],
                columns: [
                  FortuneTableColumn<String>(
                    id: 'name',
                    header: '이름',
                    text: (row) => row,
                    isTextEditable: (_, _) => true,
                    onTextCommitted: (_, _, next) {
                      commitCount += 1;
                      setState(() => value = next);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('원본'));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'FortuneTable');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    expect(find.byType(EditableText), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, 'k');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(find.byType(EditableText), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, '원본');
    await tester.enterText(find.byType(EditableText), '변경');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(commitCount, 1);
    expect(find.text('변경'), findsOneWidget);
  });

  testWidgets('FortuneTable focus controller reveals an off-screen cell', (
    tester,
  ) async {
    final focusController = FortuneTableFocusController();
    final selectionController = FortuneTableSelectionController();
    addTearDown(focusController.dispose);
    addTearDown(selectionController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: FortuneTable<int>(
              rows: List.generate(40, (index) => index),
              autoFitColumns: false,
              focusController: focusController,
              selectionController: selectionController,
              columns: List.generate(
                5,
                (column) => FortuneTableColumn<int>(
                  id: 'c$column',
                  header: 'C$column',
                  initialWidth: 120,
                  text: (row) => 'r${row}c$column',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('r39c4'), findsNothing);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusController.focusCell(39, 'c4');
    });
    await tester.pumpAndSettle();

    expect(selectionController.selectedRows, {39});
    expect(find.text('r39c4'), findsOneWidget);
    expect(
      tester
          .getRect(find.text('r39c4'))
          .overlaps(tester.getRect(find.byType(FortuneTable<int>))),
      isTrue,
    );
  });

  testWidgets('FortuneTable selects rows and toggles checkbox cells', (
    tester,
  ) async {
    final rows = ['첫째', '둘째', '셋째'];
    final checked = <String>{};
    var selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FortuneTable<String>(
                  rows: rows,
                  autoFitColumns: false,
                  onRowSelected: (row, index) => selectedIndex = index,
                  columns: [
                    FortuneTableColumn<String>(
                      id: 'name',
                      header: '이름',
                      initialWidth: 100,
                      text: (row) => row,
                    ),
                    FortuneTableColumn<String>(
                      id: 'check',
                      header: '체크',
                      initialWidth: 60,
                      text: (_) => '',
                      checkboxValue: checked.contains,
                      onCheckboxChanged: (row, value) {
                        setState(() {
                          if (value) {
                            checked.add(row);
                          } else {
                            checked.remove(row);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('둘째'));
    await tester.pump();

    expect(selectedIndex, 1);

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 100 + 30, 36 + 14));
    await tester.pump();

    expect(checked, {'첫째'});

    await tester.tapAt(
      tableTopLeft + const Offset(40 + 100 + 30, 36 + 28 + 14),
    );
    await tester.pump();

    expect(checked, {'첫째', '둘째'});

    await tester.tapAt(tableTopLeft + const Offset(40 + 100 + 30, 36 + 14));
    await tester.pump();

    expect(checked, {'둘째'});
  });

  testWidgets('FortuneTable row-index checkbox callbacks toggle only one row', (
    tester,
  ) async {
    const rows = ['같은 값', '같은 값'];
    final checkedRows = <int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 120,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FortuneTable<String>(
                  rows: rows,
                  autoFitColumns: false,
                  columns: [
                    FortuneTableColumn<String>(
                      id: 'check',
                      header: '체크',
                      initialWidth: 60,
                      text: (_) => '',
                      checkboxValueAt: (row, rowIndex) =>
                          checkedRows.contains(rowIndex),
                      onCheckboxChangedAt: (row, rowIndex, value) {
                        setState(() {
                          if (value) {
                            checkedRows.add(rowIndex);
                          } else {
                            checkedRows.remove(rowIndex);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 14));
    await tester.pump();

    expect(checkedRows, {0});

    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 28 + 14));
    await tester.pump();

    expect(checkedRows, {0, 1});

    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 14));
    await tester.pump();

    expect(checkedRows, {1});
  });

  testWidgets('FortuneTable checkbox controller gets and sets state', (
    tester,
  ) async {
    final controller = FortuneTableCheckboxController();
    addTearDown(controller.dispose);

    controller.setChecked('check', 1, true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 120,
            child: FortuneTable<String>(
              rows: const ['첫째', '둘째'],
              autoFitColumns: false,
              columns: [
                FortuneTableColumn<String>(
                  id: 'check',
                  header: '체크',
                  initialWidth: 60,
                  text: (_) => '',
                  checkboxController: controller,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(controller.isChecked('check', 0), isFalse);
    expect(controller.isChecked('check', 1), isTrue);
    expect(controller.checkedRows('check'), {1});

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 30, 36 + 14));
    await tester.pump();

    expect(controller.isChecked('check', 0), isTrue);
    expect(controller.checkedRows('check'), {0, 1});

    controller.toggleChecked('check', 1);
    await tester.pump();

    expect(controller.checkedRows('check'), {0});

    controller.setCheckedRows('check', const [1]);
    await tester.pump();

    expect(controller.isChecked('check', 0), isFalse);
    expect(controller.isChecked('check', 1), isTrue);
  });

  testWidgets('FortuneTable supports multi row selection shortcuts', (
    tester,
  ) async {
    final selectionController = FortuneTableSelectionController();
    addTearDown(selectionController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            height: 180,
            child: FortuneTable<String>(
              rows: const ['첫째', '둘째', '셋째', '넷째'],
              autoFitColumns: false,
              selectionController: selectionController,
              multiSelectionEnabled: true,
              columns: [
                FortuneTableColumn<String>(
                  id: 'name',
                  header: '이름',
                  initialWidth: 120,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    await tester.tapAt(tableTopLeft + const Offset(40 + 60, 36 + 28 + 14));
    await tester.pump();

    expect(selectionController.selectedRows, {1});

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tapAt(tableTopLeft + const Offset(40 + 60, 36 + 84 + 14));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(selectionController.selectedRows, {1, 3});

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(tableTopLeft + const Offset(40 + 60, 36 + 14));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

    expect(selectionController.selectedRows, {0, 1, 2, 3});

    selectionController.clear();
    await tester.pump();

    await tester.tapAt(tableTopLeft + const Offset(40 + 60, 36 + 14));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(selectionController.selectedRows, {0, 1, 2, 3});

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(selectionController.selectedRows, isEmpty);
  });

  testWidgets('FortuneTable drag selects row ranges', (tester) async {
    final selectionController = FortuneTableSelectionController();
    addTearDown(selectionController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            height: 180,
            child: FortuneTable<String>(
              rows: const ['첫째', '둘째', '셋째', '넷째'],
              autoFitColumns: false,
              selectionController: selectionController,
              multiSelectionEnabled: true,
              columns: [
                FortuneTableColumn<String>(
                  id: 'name',
                  header: '이름',
                  initialWidth: 120,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    final gesture = await tester.startGesture(
      tableTopLeft + const Offset(40 + 60, 36 + 14),
    );
    await gesture.moveBy(const Offset(0, 56));
    await gesture.up();
    await tester.pump();

    expect(selectionController.selectedRows, {0, 1, 2});
  });

  testWidgets('ItemManage renders the FortuneTable management table', (
    tester,
  ) async {
    ItemOfMarket? selected;
    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: [_testItemOfMarket(itemName: '테스트 품목')],
              onRowSelected: (row, index) {
                selected = row;
                selectedIndex = index;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(FortuneTable<ItemOfMarket>), findsOneWidget);
    expect(find.text('테스트 품목'), findsOneWidget);

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.autoFitColumns, isFalse);
    expect(table.columns.map((column) => column.initialWidth), [
      40,
      100,
      280,
      180,
    ]);

    await tester.tap(find.text('테스트 품목'));
    await tester.pump();

    expect(selected?.item.itemName, '테스트 품목');
    expect(selectedIndex, 0);
  });

  testWidgets('ItemManage reports ready after render work completes', (
    tester,
  ) async {
    var readyCount = 0;
    Widget buildItemManage(VoidCallback onReady) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 220,
          child: ItemManage(
            items: [_testItemOfMarket()],
            onReady: onReady,
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildItemManage(() => readyCount += 1));

    expect(readyCount, 0);
    await tester.pump();
    expect(readyCount, 1);
    await tester.pump();
    expect(readyCount, 1);

    await tester.pumpWidget(buildItemManage(() => readyCount += 10));
    expect(readyCount, 1);
    await tester.pump();
    expect(readyCount, 11);
  });

  testWidgets('ItemManage searches the active column from the next row', (
    tester,
  ) async {
    final searchController = ItemManageController();
    int? selectedIndex;
    final items = [
      _testItemOfMarket(
        itemName: 'Alpha 사과',
        element: '첫째 원료',
        itemId: 10,
      ),
      _testItemOfMarket(
        itemName: 'Alpha 배',
        element: '둘째 원료',
        itemId: 20,
      ),
      _testItemOfMarket(
        itemName: 'alpha 포도',
        element: '셋째 원료',
        itemId: 30,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 220,
            child: ItemManage(
              controller: searchController,
              items: items,
              onRowSelected: (_, index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );

    expect(searchController.search('Alpha'), ItemManageSearchResult.found);
    expect(selectedIndex, 0);
    expect(searchController.search('Alpha'), ItemManageSearchResult.found);
    expect(selectedIndex, 1);
    expect(
      searchController.search('Alpha'),
      ItemManageSearchResult.reachedEnd,
    );

    searchController.resetSearch();
    expect(searchController.search('Alpha'), ItemManageSearchResult.found);
    expect(selectedIndex, 0);

    await tester.tap(find.text('둘째 원료'));
    await tester.pump();
    expect(searchController.search('셋째'), ItemManageSearchResult.found);
    expect(selectedIndex, 2);
  });

  testWidgets('ItemManage keeps the element column read-only', (tester) async {
    final source = _testItemOfMarket(itemName: '테스트 품목');
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
      rawSnapshots: {source.item.itemId: _rawSnapshot(source.item.itemId)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );

    final elementText = controller.rows.single.elementPlain;
    await tester.tap(find.text(elementText));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text(elementText));
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
    expect(controller.rows.single.elementPlain, elementText);
    expect(controller.isDirty, isFalse);
  });

  testWidgets('ItemManage publish checkbox is scoped to clicked row', (
    tester,
  ) async {
    final items = [
      _testItemOfMarket(itemName: '첫째 품목', marketId: 1),
      _testItemOfMarket(itemName: '둘째 품목', marketId: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(items: items),
          ),
        ),
      ),
    );

    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    final publishColumn = table.columns.first;
    expect(
      publishColumn.checkboxController!.isChecked(publishColumn.id, 0),
      isFalse,
    );
    expect(
      publishColumn.checkboxController!.isChecked(publishColumn.id, 1),
      isFalse,
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await tester.tapAt(tableTopLeft + const Offset(40 + 20, 36 + 14));
    await tester.pump();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    final updatedPublishColumn = table.columns.first;
    expect(
      updatedPublishColumn.checkboxController!.isChecked(
        updatedPublishColumn.id,
        0,
      ),
      isTrue,
    );
    expect(
      updatedPublishColumn.checkboxController!.isChecked(
        updatedPublishColumn.id,
        1,
      ),
      isFalse,
    );

    await tester.tap(find.text('둘째 품목'));
    await tester.pump();

    expect(_cellColorForText(tester, '첫째 품목'), const Color(0xFFEAF4FF));
    expect(_cellColorForText(tester, '둘째 품목'), const Color(0xFFE3F2FD));
  });

  testWidgets('ItemManage distinguishes added and modified draft rows', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '기존 품목', marketId: 1);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
      rawSnapshots: {source.item.itemId: _rawSnapshot(source.item.itemId)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    controller.updateItemName('item:${source.item.itemId}', '수정 품목');
    controller.addRows(1, emptyElementPayload: 'UEsDempty');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.rowColorBuilder!(table.rows[0], 0, false), const Color(0xFFFFF6DF));
    expect(table.rowColorBuilder!(table.rows[1], 1, false), const Color(0xFFEAF7EE));
    expect(table.rowColorBuilder!(table.rows[1], 1, true), isNull);
  });

  testWidgets('ItemManage remaps publish checks by item id after deletion', (
    tester,
  ) async {
    final first = _testItemOfMarket(itemName: '첫째 품목', itemId: 10);
    final second = _testItemOfMarket(itemName: '둘째 품목', itemId: 20);
    final controller = ItemManagerDraftController.fromItems(
      items: [first, second],
      rawSnapshots: {10: _rawSnapshot(10), 20: _rawSnapshot(20)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );

    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    table.columns.first.checkboxController!.setChecked('publish', 0, true);
    controller.deleteRows(['item:20']);
    await tester.pump();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.rows.single.item.itemId, 10);
    expect(table.columns.first.checkboxValueAt!(table.rows.single, 0), isTrue);

    final refreshedController = ItemManagerDraftController.fromItems(
      items: [first],
      rawSnapshots: {10: _rawSnapshot(10)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(refreshedController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: refreshedController,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns.first.checkboxController!.checkedRows('publish'), isEmpty);
  });

  testWidgets('ItemManage keeps publish selection available in read-only mode', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '조회 전용 품목', itemId: 10);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
      rawSnapshots: {10: _rawSnapshot(10)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              canEdit: false,
            ),
          ),
        ),
      ),
    );

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns.first.checkboxController, isNotNull);
    table.selectionController!.setSelectedRows(const [0]);
    await tester.pump();

    await _openItemManageContextMenu(
      tester,
      tester.getTopLeft(find.byType(FortuneTable<ItemOfMarket>)),
    );
    final publishItem = tester.widget<PopupMenuItem<String>>(
      find.ancestor(
        of: find.text('블럭 선택 발행 체크'),
        matching: find.byType(PopupMenuItem<String>),
      ),
    );
    expect(publishItem.enabled, isTrue);
  });

  testWidgets('ItemManage blocks publish command when open menu becomes dirty', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '기존 품목');
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
      rawSnapshots: {10: _rawSnapshot(10)},
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('기존 품목'));
    await tester.pump();
    await _openItemManageContextMenu(
      tester,
      tester.getTopLeft(find.byType(FortuneTable<ItemOfMarket>)),
    );
    controller.updateItemName('item:10', '수정 품목');
    await tester.pump();
    await tester.tap(find.text('블럭 선택 발행 체크'));
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns.first.checkboxValueAt!(table.rows.single, 0), isFalse);
  });

  testWidgets('ItemManage closes a focused count menu on first outside tap', (
    tester,
  ) async {
    final popupRouteObserver = _PopupRouteObserver();
    final controller = ItemManagerDraftController(
      rows: [
        for (var index = 0; index < 2; index++)
          ItemManagerDraftRow.newRow(
            draftRowKey: 'draft-outside-$index',
            order: index + 1,
            originalIndex: index,
            insertAnchorItemId: null,
            rowState: ItemManagerDraftRowState.added,
            emptyElementPayload: 'UEsDempty',
          ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [popupRouteObserver],
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
            ),
          ),
        ),
      ),
    );

    final tableFinder = find.byType(FortuneTable<ItemOfMarket>);
    final menuPosition =
        tester.getTopLeft(tableFinder) + const Offset(40 + 80, 36 + 14);
    final rowGesture = tester.widget<GestureDetector>(
      find
          .descendant(
            of: tableFinder,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is GestureDetector &&
                  widget.onSecondaryTapDown != null,
            ),
          )
          .first,
    );
    final outerGesture = tester.widget<GestureDetector>(
      find.ancestor(of: tableFinder, matching: find.byType(GestureDetector)).first,
    );
    final details = TapDownDetails(globalPosition: menuPosition);
    rowGesture.onSecondaryTapDown!(details);
    outerGesture.onSecondaryTapDown!(details);
    await tester.pumpAndSettle();

    expect(popupRouteObserver.popupPushCount, 1);
    final countFields = tester.widgetList<TextField>(
      find.descendant(
        of: find.byType(PopupMenuItem<String>),
        matching: find.byType(TextField),
      ),
    ).toList();
    expect(countFields, hasLength(2));
    expect(countFields[0].groupId, same(countFields[1].groupId));
    expect(countFields[0].groupId, isNot(same(EditableText)));
    final countField = find
        .descendant(
          of: find.byType(PopupMenuItem<String>),
          matching: find.byType(TextField),
        )
        .first;
    await tester.tap(countField);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<String>), findsNothing);

    await _openItemManageContextMenu(
      tester,
      tester.getTopLeft(find.byType(FortuneTable<ItemOfMarket>)),
    );
    await tester.tap(
      find
          .descendant(
            of: find.byType(PopupMenuItem<String>),
            matching: find.byType(TextField),
          )
          .first,
    );
    await tester.pump();
    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, {0, 1});
  });

  testWidgets('ItemManage context menu controls selection and publish checks', (
    tester,
  ) async {
    final items = [
      _testItemOfMarket(itemName: '첫째 품목', marketId: 1),
      _testItemOfMarket(itemName: '둘째 품목', marketId: 2),
      _testItemOfMarket(itemName: '셋째 품목', marketId: 3),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(items: items),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );

    await _openItemManageContextMenu(tester, tableTopLeft);
    expect(
      tester
          .widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>))
          .map((item) => item.height),
      everyElement(fortuneContextMenuRowHeight),
    );
    expect(
      tester
          .widgetList<PopupMenuDivider>(find.byType(PopupMenuDivider))
          .map((divider) => divider.height),
      everyElement(fortuneContextMenuDividerHeight),
    );
    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();

    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, {0, 1, 2});

    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('블럭 선택 발행 체크'));
    await tester.pumpAndSettle();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    final publishColumn = table.columns.first;
    expect(publishColumn.checkboxController!.checkedRows(publishColumn.id), {
      0,
      1,
      2,
    });

    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('전체 선택 해제'));
    await tester.pumpAndSettle();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, isEmpty);
  });

  testWidgets('ItemManage order command follows delete and invokes callback', (
    tester,
  ) async {
    var invoked = false;
    var popupRemovedBeforeCallback = false;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: [
                _testItemOfMarket(itemName: '첫째 품목'),
                _testItemOfMarket(itemName: '둘째 품목'),
              ],
              onItemOrderChange: () async {
                invoked = true;
                popupRemovedBeforeCallback = find
                    .byType(PopupMenuItem<String>)
                    .evaluate()
                    .isEmpty;
                await showDialog<void>(
                  context: navigatorKey.currentContext!,
                  builder: (context) => AlertDialog(
                    title: const Text('품목 순서 변경'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await _openItemManageContextMenu(tester, tableTopLeft);

    expect(
      tester.getTopLeft(find.text('품목 삭제')).dy,
      lessThan(tester.getTopLeft(find.text('순서 변경')).dy),
    );
    expect(
      tester.getTopLeft(find.text('순서 변경')).dy,
      lessThan(tester.getTopLeft(find.text('QR코드 데이터 보기')).dy),
    );
    await tester.tap(find.text('순서 변경'));
    await tester.pumpAndSettle();

    expect(invoked, isTrue);
  expect(popupRemovedBeforeCallback, isTrue);
    expect(find.text('품목 순서 변경'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<String>), findsNothing);
  });

  testWidgets('ItemManage disables order command while draft is dirty', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: [
        ItemManagerDraftRow.newRow(
          draftRowKey: 'draft-order',
          order: 1,
          originalIndex: 0,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.added,
          emptyElementPayload: 'UEsDempty',
        ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    var invoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              onItemOrderChange: () async => invoked = true,
            ),
          ),
        ),
      ),
    );

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    final publishColumn = table.columns.firstWhere(
      (column) => column.id == 'publish',
    );
    expect(publishColumn.checkboxController, isNull);
    expect(publishColumn.checkboxValueAt, isNotNull);

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await _openItemManageContextMenu(tester, tableTopLeft);

    expect(find.text('저장 완료 또는 변경 취소 확정 후 순서 변경을 실행해 주세요.'), findsOneWidget);
    await tester.tap(find.text('순서 변경'));
    await tester.pump();
    expect(invoked, isFalse);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();
  });

  testWidgets('ItemManage disables order command without edit permission', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: [
                _testItemOfMarket(itemName: '첫째 품목'),
                _testItemOfMarket(itemName: '둘째 품목'),
              ],
              onItemOrderChange: () async => invoked = true,
              itemOrderDisabledReason: '편집 권한이 없습니다.',
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await _openItemManageContextMenu(tester, tableTopLeft);

    expect(find.text('편집 권한이 없습니다.'), findsOneWidget);
    await tester.tap(find.text('순서 변경'));
    await tester.pump();
    expect(invoked, isFalse);
  });

  testWidgets('ItemManage adds and confirms deletion of a draft row', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: const [],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    ItemOfMarket? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              emptyElementPayload: 'UEsDempty',
              onRowSelected: (row, _) => selected = row,
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('품목 추가'));
    await tester.pumpAndSettle();

    expect(controller.rows, hasLength(1));
    expect(controller.rows.single.rowState, ItemManagerDraftRowState.added);
    expect(selected?.item.itemId, 0);
    controller.updateItemName(controller.rows.single.rowKey, 'A');
    await tester.pump();
    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, {0});

    await _openItemManageContextMenu(tester, tableTopLeft);
    final activeColor = Theme.of(
      tester.element(find.byType(ItemManage)),
    ).colorScheme.onSurface;
    expect(tester.widget<Text>(find.text('품목 추가')).style?.color, activeColor);
    expect(tester.widget<Text>(find.text('품목 삽입')).style?.color, activeColor);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.enabled),
      everyElement(isTrue),
    );
    await tester.tap(find.text('품목 삭제'));
    await tester.pumpAndSettle();
    expect(find.text("선택한 'A'를 삭제하시겠습니까?"), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '계속 편집'));
    await tester.pumpAndSettle();
    expect(find.text("선택한 'A'를 삭제하시겠습니까?"), findsNothing);
    expect(find.byType(PopupMenuItem<String>), findsNothing);

    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('품목 삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();

    expect(controller.rows, isEmpty);
    expect(controller.deletedSourceItemIds, isEmpty);
    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, isEmpty);
  });

  testWidgets('ItemManage closes add popup and reveals the first added row', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: [
        for (var index = 0; index < 20; index++)
          ItemManagerDraftRow.newRow(
            draftRowKey: 'draft-$index',
            order: index + 1,
            originalIndex: index,
            insertAnchorItemId: null,
            rowState: ItemManagerDraftRowState.added,
            emptyElementPayload: 'UEsDempty',
          ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              emptyElementPayload: 'UEsDempty',
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    final bodyVerticalController = _bodyVerticalController(tester);
    expect(bodyVerticalController.offset, 0);

    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('품목 추가'));
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<String>), findsNothing);
    expect(controller.rows, hasLength(21));
    expect(bodyVerticalController.offset, greaterThan(0));
    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.selectionController!.selectedRows, {20});
  });

  testWidgets('ItemManage QR viewer uses the right-clicked draft row', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: [
        ItemManagerDraftRow.newRow(
          draftRowKey: 'draft-qr',
          order: 1,
          originalIndex: 0,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.added,
          emptyElementPayload: 'UEsDempty',
        ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    controller.updateItemName('draft:draft-qr', 'QR 품목');
    ItemManagerDraftRow? viewedRow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              onQrDataView: (row) async => viewedRow = row,
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    await _openItemManageContextMenu(tester, tableTopLeft);
    await tester.tap(find.text('QR코드 데이터 보기'));
    await tester.pumpAndSettle();

    expect(viewedRow?.rowKey, 'draft:draft-qr');
    expect(controller.rows.single.rowState, ItemManagerDraftRowState.added);

    viewedRow = null;
    await _openItemManageContextMenu(tester, tableTopLeft);
    controller.deleteRows(const ['draft:draft-qr']);
    await tester.pump();
    await tester.tap(find.text('QR코드 데이터 보기'));
    await tester.pumpAndSettle();
    expect(viewedRow, isNull);
  });

  testWidgets('ItemManage commits item name edits to the draft row', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: [
        ItemManagerDraftRow.newRow(
          draftRowKey: 'draft-1',
          order: 1,
          originalIndex: 0,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.added,
          emptyElementPayload: 'UEsDempty',
        ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    controller.updateItemName('draft:draft-1', '편집 전 품명');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              onCancelDraft: () async {},
              onSaveDraft: () async {},
              onExcelImport: () async {},
              onExcelExport: () async {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '취소'))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '저장'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('편집 전 품명'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('편집 전 품명'));
    await tester.pump();
    final editorBox = tester.widget<DecoratedBox>(
      find.ancestor(
        of: find.byType(EditableText),
        matching: find.byType(DecoratedBox),
      ).first,
    );
    final editorDecoration = editorBox.decoration as BoxDecoration;
    expect(editorDecoration.color, const Color(0xFFE3F2FD));
    expect(
      editorDecoration.border,
      Border.all(color: const Color(0xFF0188FB), width: 2),
    );
    await tester.enterText(find.byType(EditableText), '편집 후 품명');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.rows.single.itemName, '편집 후 품명');
    expect(find.text('편집 후 품명'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ItemManage blocks mutations when edit permission is missing', (
    tester,
  ) async {
    final controller = ItemManagerDraftController(
      rows: [
        ItemManagerDraftRow.newRow(
          draftRowKey: 'draft-read-only',
          order: 1,
          originalIndex: 0,
          insertAnchorItemId: null,
          rowState: ItemManagerDraftRowState.added,
          emptyElementPayload: 'UEsDempty',
        ),
      ],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    controller.updateItemName('draft:draft-read-only', '조회 전용 품목');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              canEdit: false,
              onExcelImport: () async {},
              onExcelExport: () async {},
              onCancelDraft: () async {},
              onSaveDraft: () async {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '취소'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '저장'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('조회 전용 품목'));
    await tester.pump();
    await tester.tap(find.text('조회 전용 품목'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ItemManage shows progress while a command is running', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(items: [], commandBusy: true),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('처리 중'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FortuneTable consumes mouse wheel inside a parent scroll view', (
    tester,
  ) async {
    final parentController = ScrollController();
    addTearDown(parentController.dispose);
    final rows = List<String>.generate(40, (index) => '행 $index');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: SingleChildScrollView(
              controller: parentController,
              child: Column(
                children: [
                  SizedBox(
                    width: 360,
                    height: 180,
                    child: FortuneTable<String>(
                      rows: rows,
                      autoFitColumns: false,
                      columns: [
                        FortuneTableColumn<String>(
                          id: 'name',
                          header: '이름',
                          initialWidth: 240,
                          text: (row) => row,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
    final bodyVerticalController = _bodyVerticalController(tester);
    final headerCenter = tableTopLeft + const Offset(120, 18);
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: headerCenter,
        scrollDelta: const Offset(0, 100),
      ),
    );
    await tester.pump();

    expect(parentController.offset, 0);
    expect(bodyVerticalController.offset, greaterThan(0));

    final firstRowCenter = tableTopLeft + const Offset(120, 36 + 14);
    for (var index = 0; index < 20; index += 1) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: firstRowCenter,
          scrollDelta: const Offset(0, 100),
        ),
      );
      await tester.pump();
    }

    expect(parentController.offset, 0);
    expect(bodyVerticalController.offset, greaterThan(0));
  });

  testWidgets(
    'FortuneTable consumes trackpad pan inside a parent scroll view',
    (tester) async {
      final parentController = ScrollController();
      addTearDown(parentController.dispose);
      final rows = List<String>.generate(40, (index) => '행 $index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 220,
              child: SingleChildScrollView(
                controller: parentController,
                child: Column(
                  children: [
                    SizedBox(
                      width: 360,
                      height: 180,
                      child: FortuneTable<String>(
                        rows: rows,
                        autoFitColumns: false,
                        columns: [
                          FortuneTableColumn<String>(
                            id: 'name',
                            header: '이름',
                            initialWidth: 240,
                            text: (row) => row,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final tableTopLeft = tester.getTopLeft(find.byType(FortuneTable<String>));
      final bodyVerticalController = _bodyVerticalController(tester);
      final firstRowCenter = tableTopLeft + const Offset(120, 36 + 14);
      tester.binding.handlePointerEvent(
        PointerPanZoomStartEvent(position: firstRowCenter),
      );
      await tester.pump();
      for (var index = 0; index < 20; index += 1) {
        tester.binding.handlePointerEvent(
          PointerPanZoomUpdateEvent(
            position: firstRowCenter,
            panDelta: const Offset(0, 100),
          ),
        );
        await tester.pump();
      }
      tester.binding.handlePointerEvent(
        PointerPanZoomEndEvent(position: firstRowCenter),
      );
      await tester.pump();

      expect(parentController.offset, 0);
      expect(bodyVerticalController.offset, greaterThan(0));
    },
  );

  testWidgets('FortuneTable shows scrollbars only when content overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 140,
            child: FortuneTable<String>(
              rows: List<String>.generate(20, (index) => '행 $index'),
              autoFitColumns: false,
              columns: [
                FortuneTableColumn<String>(
                  id: 'wide',
                  header: '넓은 컬럼',
                  initialWidth: 320,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    var scrollbars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar));
    expect(scrollbars.map((scrollbar) => scrollbar.thumbVisibility), [
      true,
      true,
    ]);
    expect(
      scrollbars.map(
        (scrollbar) => scrollbar.notificationPredicate(
          ScrollStartNotification(
            metrics: FixedScrollMetrics(
              minScrollExtent: 0,
              maxScrollExtent: 100,
              pixels: 0,
              viewportDimension: 50,
              axisDirection: AxisDirection.down,
              devicePixelRatio: 1,
            ),
            context: tester.element(find.byType(FortuneTable<String>)),
          ),
        ),
      ),
      [true, false],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FortuneTable<String>(
              rows: const ['행 1'],
              autoFitColumns: false,
              columns: [
                FortuneTableColumn<String>(
                  id: 'narrow',
                  header: '좁은 컬럼',
                  initialWidth: 120,
                  text: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    scrollbars = tester.widgetList<RawScrollbar>(find.byType(RawScrollbar));
    expect(scrollbars.map((scrollbar) => scrollbar.thumbVisibility), [
      false,
      false,
    ]);
  });
}

class _PopupRouteObserver extends NavigatorObserver {
  int popupPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PopupRoute<dynamic>) popupPushCount += 1;
  }
}

ScrollController _bodyVerticalController(WidgetTester tester) {
  final listViews = tester.widgetList<ListView>(find.byType(ListView));
  return listViews.last.controller!;
}

Future<void> _openItemManageContextMenu(
  WidgetTester tester,
  Offset tableTopLeft,
) async {
  final gesture = await tester.startGesture(
    tableTopLeft + const Offset(40 + 80, 36 + 14),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}

Color? _cellColorForText(WidgetTester tester, String text) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: find.text(text),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color;
}

ItemOfMarket _testItemOfMarket({
  String itemName = '테스트 품목',
  String element = '원재료',
  int marketId = 1,
  int itemId = 10,
}) {
  final now = DateTime(2026, 7, 8);
  return ItemOfMarket(
    marketId: marketId,
    item: Item(
      itemId: itemId,
      labelSizeId: 20,
      itemName: itemName,
      labelSizeName: '테스트 라벨',
      element: element,
      elementRTF: '',
      price: 0,
      order: 0,
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: 0,
      itemId: itemId,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: now,
    dateSaleEnd: now,
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: now,
    dateEndDiscount: now,
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 0,
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

ItemOfMarketRawSnapshot _rawSnapshot(int itemId) {
  return ItemOfMarketRawSnapshot(
    marketId: 1,
    itemId: itemId,
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
