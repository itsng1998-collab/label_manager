import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart' hide Rect;
import 'package:label_manager/models/additional_item.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_base.dart';
import 'package:label_manager/models/column_content.dart';
import 'package:label_manager/models/column_special.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/item.dart';
import 'package:label_manager/models/item_manager_draft.dart';
import 'package:label_manager/models/item_of_market.dart';
import 'package:label_manager/models/label_size.dart';
import 'package:label_manager/page_home/item_manage.dart';
import 'package:label_manager/page_home/table_search.dart';
import 'package:label_manager/home_page_manager.dart';

void main() {
  testWidgets('row double tap only reports a valid data row', (tester) async {
    final activated = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 240,
            child: FortuneTable<String>(
              rows: const ['협력업체 A'],
              columns: [
                FortuneTableColumn<String>(
                  id: 'name',
                  header: '이름',
                  text: (value) => value,
                ),
              ],
              onRowDoubleTap: (row, index) => activated.add('$index:$row'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('이름'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('이름'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(activated, isEmpty);

    await tester.tap(find.text('협력업체 A'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('협력업체 A'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(activated, ['0:협력업체 A']);
  });

  test('settings operation gate ignores concurrent operations', () async {
    final gate = SettingsOperationGate();
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

  test('settings operation gate unlocks after failure', () async {
    final gate = SettingsOperationGate();

    await expectLater(
      gate.run(() async => throw StateError('save failed')),
      throwsStateError,
    );

    expect(gate.submitting, isFalse);
    await gate.run(() async {});
  });

  test('settings write keeps commit when reload fails', () async {
    var writes = 0;
    var commits = 0;
    var reloads = 0;

    final error = await runSettingsWriteThenReload<int>(
      write: () async {
        writes += 1;
        return 7;
      },
      onCommitted: (value) {
        expect(value, 7);
        commits += 1;
      },
      reload: (value) async {
        expect(value, 7);
        reloads += 1;
        throw StateError('reload failed');
      },
    );

    expect(writes, 1);
    expect(commits, 1);
    expect(reloads, 1);
    expect(error, isA<StateError>());
  });

  test('settings write operation waits for reload completion', () async {
    final reloadCompleter = Completer<void>();
    var committed = false;
    var completed = false;

    final operation = runSettingsWriteThenReload<int>(
      write: () async => 7,
      onCommitted: (_) => committed = true,
      reload: (_) => reloadCompleter.future,
    ).whenComplete(() => completed = true);

    await Future<void>.delayed(Duration.zero);
    expect(committed, isTrue);
    expect(completed, isFalse);

    reloadCompleter.complete();
    expect(await operation, isNull);
    expect(completed, isTrue);
  });

  test('settings write failure skips commit and reload', () async {
    var commits = 0;
    var reloads = 0;

    await expectLater(
      runSettingsWriteThenReload<int>(
        write: () async => throw StateError('write failed'),
        onCommitted: (_) => commits += 1,
        reload: (_) async => reloads += 1,
      ),
      throwsStateError,
    );

    expect(commits, 0);
    expect(reloads, 0);
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

  test('top search is visible on item, label print, auto update, and scale output tabs', () {
    expect(itemManagerSearchVisibleForTab('items'), isTrue);
    expect(itemManagerSearchVisibleForTab('common_label'), isFalse);
    expect(itemManagerSearchVisibleForTab('label_print'), isTrue);
    expect(itemManagerSearchVisibleForTab('auto_update'), isTrue);
    expect(itemManagerSearchVisibleForTab('scale_output'), isTrue);
    expect(itemManagerSearchVisibleForTab(null), isFalse);
  });

  test('home tab shortcuts map only unmodified F keys outside edit mode', () {
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f1,
        editing: false,
        modifierPressed: false,
      ),
      'items',
    );
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f2,
        editing: false,
        modifierPressed: false,
      ),
      'common_label',
    );
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f3,
        editing: false,
        modifierPressed: false,
      ),
      'label_print',
    );
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f2,
        editing: true,
        modifierPressed: false,
      ),
      isNull,
    );
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f2,
        editing: false,
        modifierPressed: true,
      ),
      isNull,
    );
    expect(
      homeTabShortcutValue(
        key: LogicalKeyboardKey.f4,
        editing: false,
        modifierPressed: false,
      ),
      isNull,
    );
  });

  test('label print tab gate blocks only active item editing states', () {
    expect(
      labelPrintTabSelectionBlocked(
        hasActiveEditing: false,
        itemDraftCommandBusy: false,
        itemDraftDirty: false,
      ),
      isFalse,
    );
    for (final blockedState in const [
      (true, false, false),
      (false, true, false),
      (false, false, true),
    ]) {
      expect(
        labelPrintTabSelectionBlocked(
          hasActiveEditing: blockedState.$1,
          itemDraftCommandBusy: blockedState.$2,
          itemDraftDirty: blockedState.$3,
        ),
        isTrue,
      );
    }
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

  testWidgets('FortuneTable keeps fixed column width during auto fit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 120,
            child: FortuneTable<String>(
              rows: const ['자동 맞춤보다 훨씬 긴 셀 내용'],
              columns: [
                FortuneTableColumn<String>(
                  id: 'fixed',
                  header: '고정',
                  text: (row) => row,
                  initialWidth: 90,
                  autoFit: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final header = find.ancestor(
      of: find.text('고정'),
      matching: find.byType(Container),
    ).first;
    expect(tester.getSize(header).width, 90);
  });

  testWidgets('FortuneTable resizes columns and keeps manual width', (
    tester,
  ) async {
    var rows = const ['짧음'];
    var fixedWidth = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 120,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FortuneTable<String>(
                  rows: rows,
                  columns: [
                    FortuneTableColumn<String>(
                      id: 'resizable',
                      header: '크기 조정',
                      text: (row) => row,
                      initialWidth: fixedWidth ? 80 : 120,
                      minWidth: 70,
                      autoFit: !fixedWidth,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(
      const ValueKey('fortune_table_column_resize_resizable'),
    );
    final mouseRegion = tester.widget<MouseRegion>(
      find.descendant(of: handle, matching: find.byType(MouseRegion)),
    );
    expect(mouseRegion.cursor, SystemMouseCursors.resizeColumn);

    double headerWidth() => tester
        .getSize(
          find.ancestor(
            of: find.text('크기 조정'),
            matching: find.byType(SizedBox),
          ).first,
        )
        .width;

    final initialWidth = headerWidth();
    await tester.drag(handle, const Offset(50, 0));
    await tester.pump();
    expect(headerWidth(), closeTo(initialWidth + 50, 0.1));

    rebuild(() => rows = const ['자동 맞춤을 다시 계산할 만큼 훨씬 긴 셀 내용']);
    await tester.pump();
    expect(headerWidth(), closeTo(initialWidth + 50, 0.1));

    await tester.drag(handle, const Offset(-1000, 0));
    await tester.pump();
    expect(headerWidth(), 70);

    rebuild(() => fixedWidth = true);
    await tester.pump();
    expect(headerWidth(), 80);
  });

  testWidgets('FortuneTable resizes fill column from displayed width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 120,
            child: FortuneTable<String>(
              rows: const ['값'],
              columns: [
                FortuneTableColumn<String>(
                  id: 'fill',
                  header: '채움',
                  text: (row) => row,
                  initialWidth: 100,
                  fillRemaining: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(
      const ValueKey('fortune_table_column_resize_fill'),
    );
    double headerWidth() => tester
        .getSize(
          find.ancestor(
            of: find.text('채움'),
            matching: find.byType(SizedBox),
          ).first,
        )
        .width;
    final displayedWidth = headerWidth();

    await tester.drag(handle, const Offset(30, 0));
    await tester.pump();

    expect(headerWidth(), closeTo(displayedWidth + 30, 0.1));
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
    expect(editingController.hasActiveEditing, isFalse);

    await tester.tap(find.text('원본'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('원본'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), '수정');
    expect(editingController.hasActiveEditing, isTrue);

    var completed = false;
    final commit = editingController.commitEditing().then((_) {
      completed = true;
    });
    await tester.pump();
    expect(completed, isFalse);
    expect(committed, isEmpty);
    expect(editingController.hasActiveEditing, isTrue);

    commitCompleter.complete();
    await commit;
    expect(completed, isTrue);
    expect(committed, '수정');
    expect(editingController.hasActiveEditing, isFalse);
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

  testWidgets('FortuneTable drag reports the last selection focus row', (tester) async {
    final selectionController = FortuneTableSelectionController();
    addTearDown(selectionController.dispose);
    var focusedRow = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 260,
            height: 180,
            child: FortuneTable<String>(
              rows: const ['첫째', '둘째', '셋째', '넷째'],
              autoFitColumns: false,
              multiSelectionEnabled: true,
              selectionController: selectionController,
              onSelectionFocusChanged: (_, rowIndex) {
                focusedRow = rowIndex;
              },
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

    expect(focusedRow, 2);
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
    expect(table.autoFitColumns, isTrue);
    expect(table.columns.map((column) => column.initialWidth), [
      40,
      100,
      280,
      420,
    ]);
    expect(table.columns.map((column) => column.autoFit), [
      true,
      true,
      true,
      false,
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

    expect(readyCount, 1);
    await tester.pump();
    expect(readyCount, 1);

    await tester.pumpWidget(buildItemManage(() => readyCount += 10));
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

    expect(searchController.search('Alpha'), TableSearchResult.found);
    expect(selectedIndex, 0);
    expect(searchController.search('Alpha'), TableSearchResult.found);
    expect(selectedIndex, 1);
    expect(
      searchController.search('Alpha'),
      TableSearchResult.reachedEnd,
    );

    searchController.resetSearch();
    expect(searchController.search('Alpha'), TableSearchResult.found);
    expect(selectedIndex, 0);

    await tester.tap(find.text('둘째 원료'));
    await tester.pump();
    expect(searchController.search('셋째'), TableSearchResult.found);
    expect(selectedIndex, 2);
  });

  testWidgets('ItemManage keeps the element column read-only', (tester) async {
    final source = _testItemOfMarket(itemName: '테스트 품목');
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
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

  testWidgets('ItemManage shows minimum-column header checkboxes', (
    tester,
  ) async {
    final originalColumns = TColumn.datas;
    final originalSpecialColumns = TColumnSpecial.datas;
    addTearDown(() {
      TColumn.datas = originalColumns;
      TColumnSpecial.datas = originalSpecialColumns;
    });

    final dynamicColumn = _testColumn(columnId: 101, columnName: '판매가격');
    dynamicColumn.useMinColumnCheck = true;
    TColumn.datas = [dynamicColumn];
    TColumnSpecial.datas = [
      TColumnBase(
        columnType: const TColumnType(
          code: TColumnType.TYPE_FIX,
          name: '고정',
          order: 0,
        ),
        keyword: SpecalKeyword.INDEX_ELEMENT.keyword,
        columnName: SpecalKeyword.INDEX_ELEMENT.columnName,
        useMinColumnCheck: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 220,
            child: ItemManage(items: [_testItemOfMarket(itemName: '품목')]),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fortune_table_header_checkbox_element')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fortune_table_header_checkbox_dyn_101')),
      findsOneWidget,
    );

    final table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.headerMaxLines, 2);
    expect(table.headerWrapAfterCharacters, 2);
    expect(table.headerLineSpacingReduction, 2);
    expect(table.headerCheckboxPadding, 1);
    expect(table.headerCheckboxLabelGap, 1);
    expect(table.columns[3].initialWidth, 70);
    expect(table.columns[3].autoFit, isFalse);
    expect(table.columns[4].initialWidth, 70);
    expect(table.columns[4].autoFit, isFalse);
    for (final column in table.columns) {
      final headerText = tester.widget<Text>(
        find.byKey(ValueKey('fortune_table_header_text:${column.header}')),
      );
      expect(headerText.style?.fontSize, 13);
      expect(headerText.style?.fontWeight, FontWeight.normal);
    }
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey('fortune_table_header_text:판매가격'),
            ),
          )
          .data,
      '판매\n가격',
    );

    final checkboxRect = tester.getRect(
      find.byKey(const ValueKey('fortune_table_header_checkbox_dyn_101')),
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('fortune_table_header_text:판매가격')),
    );
    final groupRect = tester.getRect(
      find.byKey(const ValueKey('fortune_table_header_group_dyn_101')),
    );
    expect(checkboxRect.center.dy, closeTo(headerRect.center.dy, 0.5));
    expect(headerRect.left - checkboxRect.right, closeTo(1, 0.5));
    expect(
      (checkboxRect.left + headerRect.right) / 2,
      closeTo(groupRect.center.dx, 0.5),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey('fortune_table_header_text:판매가격'),
            ),
          )
          .style
          ?.height,
      lessThan(1.2),
    );
  });

  testWidgets('ItemManage header checkbox updates minimum-column state', (
    tester,
  ) async {
    final originalColumns = TColumn.datas;
    final originalSpecialColumns = TColumnSpecial.datas;
    addTearDown(() {
      TColumn.datas = originalColumns;
      TColumnSpecial.datas = originalSpecialColumns;
    });

    final dynamicColumn = _testColumn(columnId: 101, columnName: '판매가');
    TColumn.datas = [dynamicColumn];
    TColumnSpecial.datas = [
      TColumnBase(
        columnType: const TColumnType(
          code: TColumnType.TYPE_FIX,
          name: '고정',
          order: 0,
        ),
        keyword: SpecalKeyword.INDEX_ELEMENT.keyword,
        columnName: SpecalKeyword.INDEX_ELEMENT.columnName,
      ),
    ];
    TColumnBase? changedColumn;
    bool? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 220,
            child: ItemManage(
              items: [_testItemOfMarket(itemName: '품목')],
              onMinColumnCheckChanged: (column, checked) async {
                changedColumn = column;
                changedValue = checked;
              },
            ),
          ),
        ),
      ),
    );

    var table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns[4].autoFit, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('fortune_table_header_checkbox_dyn_101')),
    );
    await tester.pumpAndSettle();

    expect(changedColumn, same(dynamicColumn));
    expect(changedValue, isTrue);
    expect(dynamicColumn.useMinColumnCheck, isTrue);

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.columns[4].initialWidth, 70);
    expect(table.columns[4].autoFit, isFalse);
  });

  testWidgets('ItemManage distinguishes added and modified draft rows', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '기존 품목', marketId: 1);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
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
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    final itemManageController = ItemManageController();
    Set<int> notifiedItemIds = const <int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              controller: itemManageController,
              onPublishCheckedItemIdsChanged: (value) {
                notifiedItemIds = value;
              },
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
    table.columns.first.checkboxController!.setChecked('publish', 1, true);
    expect(itemManageController.publishCheckedItemIds, const <int>{10, 20});
    expect(notifiedItemIds, const <int>{10, 20});
    controller.deleteRows(['item:20']);
    await tester.pump();

    table = tester.widget<FortuneTable<ItemOfMarket>>(
      find.byType(FortuneTable<ItemOfMarket>),
    );
    expect(table.rows.single.item.itemId, 10);
    expect(table.columns.first.checkboxValueAt!(table.rows.single, 0), isTrue);
    expect(itemManageController.publishCheckedItemIds, const <int>{10});
    expect(notifiedItemIds, const <int>{10});

    final refreshedController = ItemManagerDraftController.fromItems(
      items: [first],
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
              controller: itemManageController,
              onPublishCheckedItemIdsChanged: (value) {
                notifiedItemIds = value;
              },
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
    expect(itemManageController.publishCheckedItemIds, isEmpty);
    expect(notifiedItemIds, isEmpty);
  });

  testWidgets('ItemManage keeps publish selection available in read-only mode', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '조회 전용 품목', itemId: 10);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
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

  testWidgets('ItemManage disables Excel actions while a cell edit is active', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '정상 품목', itemId: 10);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
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
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 내보내기'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('정상 품목'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('정상 품목'));
    await tester.pump();

    expect(find.byType(EditableText), findsOneWidget);
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
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 내보내기'),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(EditableText), '수정된 품목');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.byType(EditableText), findsNothing);
    expect(controller.rows.single.itemName, '수정된 품목');
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ItemManage re-enables Excel actions after committing a clean cell edit', (
    tester,
  ) async {
    final source = _testItemOfMarket(itemName: '그대로 품목', itemId: 11);
    final controller = ItemManagerDraftController.fromItems(
      items: [source],
      scopedColumnContents: TColumnContentScopedView(const {}),
    );
    addTearDown(controller.dispose);
    final itemManageController = ItemManageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 220,
            child: ItemManage(
              items: const [],
              controller: itemManageController,
              draftController: controller,
              labelSize: const LabelSize(
                labelSizeId: 20,
                brandId: 30,
                labelSizeName: '테스트 라벨',
              ),
              marketId: 1,
              canEdit: true,
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
      isNotNull,
    );

    await tester.tap(find.text('그대로 품목'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('그대로 품목'));
    await tester.pump();

    expect(find.byType(EditableText), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNull,
    );

    await itemManageController.commitEditing();
    await tester.pump();

    expect(find.byType(EditableText), findsNothing);
    expect(controller.isDirty, isFalse);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 가져오기'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, '엑셀 내보내기'),
          )
          .onPressed,
      isNotNull,
    );
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

    expect(find.text('엑셀 가져오기'), findsNothing);
    expect(find.text('엑셀 내보내기'), findsNothing);
    expect(find.text('취소'), findsNothing);
    expect(find.text('저장'), findsNothing);
    expect(find.byType(FortuneTable<ItemOfMarket>), findsOneWidget);

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

  testWidgets('FortuneTable scroll controller reveals an offscreen row', (
    tester,
  ) async {
    final controller = FortuneTableScrollController();
    final rows = List<String>.generate(100, (index) => '행-$index');

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 140,
          child: FortuneTable<String>(
            rows: rows,
            columns: [
              FortuneTableColumn<String>(
                id: 'name',
                header: '이름',
                text: (row) => row,
              ),
            ],
            scrollController: controller,
          ),
        ),
      ),
    );

    expect(find.text('행-80'), findsNothing);
    controller.revealRow(80);
    await tester.pump();
    await tester.pump();
    expect(find.text('행-80'), findsOneWidget);
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

TColumn _testColumn({
  int columnId = 101,
  String columnName = '동적컬럼',
  int width = 120,
}) {
  return TColumn(
    columnId: columnId,
    labelSizeId: 20,
    order: 1,
    width: width,
    height: 30,
    barcodeType: BarcodeType.Code128,
    useBarcodeCheckDigit: false,
    showBarcodeNum: false,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: true,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 0,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
    columnType: const TColumnType(
      code: TColumnType.TYPE_FIX,
      name: '고정',
      order: 0,
    ),
    keyword: 'COL_$columnId',
    columnName: columnName,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    timeBarcodeType: 0,
    autoInc: false,
    autoIncSize: 0,
    autoIncSave: false,
    autoIncRange: 0,
    autoIncZeroDel: false,
    autoIncUpdate: false,
    searchPrint: false,
    userDefineBarcodeText: '',
    lineCheck: 0,
    lineSize: 0,
    gs1ai: '',
    formatOption: 0,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}
