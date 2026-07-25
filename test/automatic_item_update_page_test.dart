import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/update_item.dart';
import 'package:label_manager/page_home/automatic_item_update_page.dart';
import 'package:label_manager/page_home/table_search.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

void main() {
  group('[automatic item update page]', () {
    testWidgets('dirty일 때만 기본 취소 저장이 활성화된다', (tester) async {
      final controller = _controller();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              onCancelDraft: () async {},
              onSaveDraft: () async {},
            ),
          ),
        ),
      );

      expect(_buttonEnabled(tester, '취소'), isFalse);
      expect(_buttonEnabled(tester, '저장'), isFalse);

      controller.updateApplyDate('update:10', '20260726');
      await tester.pump();

      expect(_buttonEnabled(tester, '취소'), isTrue);
      expect(_buttonEnabled(tester, '저장'), isTrue);
    });

    testWidgets('추가 mode에서도 dirty면 기본 취소 저장이 유지된다', (tester) async {
      final controller = _controller();
      controller.stageAppendItems([_seed(30, '추가 품목')]);
      controller.applyStagedRows();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              onCancelDraft: () async {},
              onSaveDraft: () async {},
            ),
          ),
        ),
      );

      expect(_buttonEnabled(tester, '취소'), isTrue);
      expect(_buttonEnabled(tester, '저장'), isTrue);

      controller.startAddMode();
      await tester.pump();

      expect(_buttonEnabled(tester, '취소'), isTrue);
      expect(_buttonEnabled(tester, '저장'), isTrue);
    });

    testWidgets('clean add mode에서는 기본 취소로 원본 품목 영역을 닫는다', (tester) async {
      final controller = _controller();
      controller.startAddMode();
      var cancelCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [_seed(30, '추가 품목')],
              sourceReady: true,
              onCancelDraft: () async => cancelCalls += 1,
            ),
          ),
        ),
      );

      expect(_buttonEnabled(tester, '취소'), isTrue);
      expect(_buttonEnabled(tester, '저장'), isFalse);
      expect(find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(controller.addModeOpen, isFalse);
      expect(cancelCalls, 0);
      expect(find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>), findsNothing);
    });

    testWidgets('dirty 상태의 취소는 외부 onCancelDraft에 위임한다', (tester) async {
      final controller = _controller();
      controller.updateApplyDate('update:10', '20260726');
      var cancelCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              onCancelDraft: () async => cancelCalls += 1,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, '취소'));
      await tester.pumpAndSettle();

      expect(cancelCalls, 1);
      expect(controller.isDirty, isTrue);
    });

    testWidgets('행 상태에 따라 기본 컬럼과 색을 렌더링한다', (tester) async {
      final controller = _controller();
      controller.updateApplyDate('update:10', '20260726');
      controller.stageAppendItems([_seed(30, '추가 품목')]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      expect(find.text('번호'), findsOneWidget);
      expect(find.text('품목명'), findsOneWidget);
      expect(find.text('갱신날짜'), findsOneWidget);
      expect(find.text('유통기한'), findsOneWidget);
      expect(find.text('첫 품목'), findsOneWidget);
      expect(find.text('추가 품목'), findsOneWidget);
    });

    testWidgets('갱신날짜 편집 commit이 controller에 반영된다', (tester) async {
      final controller = _controller();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      controller.updateApplyDate('update:10', '20260726');
      await tester.pump();

      expect(find.text('20260726'), findsOneWidget);
    });

    testWidgets('우클릭 메뉴에 삭제와 새로 고침이 보인다', (tester) async {
      final controller = _controller();
      controller.setSelection(['update:10'], anchorRowKey: 'update:10');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      final table = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      await tester.tapAt(tester.getCenter(table), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('품목삭제'), findsOneWidget);
      expect(find.text('새로 고침'), findsOneWidget);
    });

    testWidgets('controller search selects the next matching auto update row', (tester) async {
      final controller = AutoItemUpdateDraftController(
        rows: [
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 10,
              itemId: 100,
              itemName: '첫 품목',
              labelSizeId: 4,
              element: '주원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 25),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 0,
          ),
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 20,
              itemId: 200,
              itemName: '둘째 품목',
              labelSizeId: 4,
              element: '부원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 26),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 1,
          ),
        ],
        cellValues: const {},
        serverToday: DateTime(2026, 7, 23),
      );
      final pageController = AutoItemUpdatePageController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: const <TColumn>[],
              draftController: controller,
              controller: pageController,
            ),
          ),
        ),
      );

      expect(pageController.search('둘째'), TableSearchResult.found);
      await tester.pump();

      expect(controller.selectedRowKeys, {'update:20'});
      expect(controller.anchorRowKey, 'update:20');
    });

    testWidgets('블럭 선택 상태에서 우클릭한 선택 행은 블럭을 유지하고 삭제한다', (tester) async {
      final controller = AutoItemUpdateDraftController(
        rows: [
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 10,
              itemId: 100,
              itemName: '첫 품목',
              labelSizeId: 4,
              element: '주원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 25),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 0,
          ),
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 20,
              itemId: 200,
              itemName: '둘째 품목',
              labelSizeId: 4,
              element: '주원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 26),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 1,
          ),
        ],
        cellValues: {
          const AutoItemUpdateCellKey(
            columnId: 7,
            rowKey: 'update:10',
          ): const AutoItemUpdateCellValue(
            contentId: 1,
            columnId: 7,
            rowKey: 'update:10',
            editable: true,
            dataString: '원본 값 1',
          ),
          const AutoItemUpdateCellKey(
            columnId: 7,
            rowKey: 'update:20',
          ): const AutoItemUpdateCellValue(
            contentId: 2,
            columnId: 7,
            rowKey: 'update:20',
            editable: true,
            dataString: '원본 값 2',
          ),
        },
        serverToday: DateTime(2026, 7, 23),
      );
      final deletedRowKeys = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              onDeleteRows: (rowKeys) async {
                deletedRowKeys
                  ..clear()
                  ..addAll(rowKeys);
              },
            ),
          ),
        ),
      );

      final firstCell = find.text('첫 품목');
      final secondCell = find.text('둘째 품목');

      await tester.tap(firstCell);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(secondCell);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(controller.selectedRowKeys, {'update:10', 'update:20'});

      await tester.tapAt(
        tester.getCenter(secondCell),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(controller.selectedRowKeys, {'update:10', 'update:20'});

      await tester.tap(find.text('블럭선택 품목삭제'));
      await tester.pumpAndSettle();

      expect(deletedRowKeys.toSet(), {'update:10', 'update:20'});
    });

    testWidgets('우클릭 삭제 전에 활성 편집을 먼저 commit한다', (tester) async {
      final controller = _controller();
      final pageController = AutoItemUpdatePageController();
      String? committedApplyDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              controller: pageController,
              onDeleteRows: (rowKeys) async {
                expect(rowKeys.toSet(), {'update:10'});
                committedApplyDate = controller.applyDateText(controller.rows.first);
              },
            ),
          ),
        ),
      );

      await _doubleTap(tester, find.text('20260725'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '20260726');
      await tester.pump();

      await tester.tapAt(
        tester.getCenter(find.text('첫 품목')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('품목삭제'));
      await tester.pumpAndSettle();

      expect(committedApplyDate, '20260726');
      expect(controller.applyDateText(controller.rows.first), '20260726');
    });

    testWidgets('controller 없이도 우클릭 삭제 전에 활성 편집을 먼저 commit한다', (tester) async {
      final controller = _controller();
      String? committedApplyDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              onDeleteRows: (rowKeys) async {
                expect(rowKeys.toSet(), {'update:10'});
                committedApplyDate = controller.applyDateText(controller.rows.first);
              },
            ),
          ),
        ),
      );

      await _doubleTap(tester, find.text('20260725'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), '20260726');
      await tester.pump();

      await tester.tapAt(
        tester.getCenter(find.text('첫 품목')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('품목삭제'));
      await tester.pumpAndSettle();

      expect(committedApplyDate, '20260726');
      expect(controller.applyDateText(controller.rows.first), '20260726');
    });

    testWidgets('range 선택 후 anchor는 마지막으로 클릭한 행을 따른다', (tester) async {
      final controller = AutoItemUpdateDraftController(
        rows: [
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 10,
              itemId: 100,
              itemName: '첫 품목',
              labelSizeId: 4,
              element: '주원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 25),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 0,
          ),
          AutoItemUpdateDraftRow.existing(
            source: UpdateItem(
              updateItemId: 20,
              itemId: 200,
              itemName: '둘째 품목',
              labelSizeId: 4,
              element: '주원료',
              elementRTF: r'{\rtf1 element}',
              price: 0,
              applyDate: DateTime(2026, 7, 26),
              isApply: false,
            ),
            currentMarketId: 3,
            originalIndex: 1,
          ),
        ],
        cellValues: {
          const AutoItemUpdateCellKey(
            columnId: 7,
            rowKey: 'update:10',
          ): const AutoItemUpdateCellValue(
            contentId: 1,
            columnId: 7,
            rowKey: 'update:10',
            editable: true,
            dataString: '원본 값 1',
          ),
          const AutoItemUpdateCellKey(
            columnId: 7,
            rowKey: 'update:20',
          ): const AutoItemUpdateCellValue(
            contentId: 2,
            columnId: 7,
            rowKey: 'update:20',
            editable: true,
            dataString: '원본 값 2',
          ),
        },
        serverToday: DateTime(2026, 7, 23),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      await tester.tap(find.text('첫 품목'));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(find.text('둘째 품목'));
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(controller.selectedRowKeys, {'update:10', 'update:20'});
      expect(controller.anchorRowKey, 'update:20');
    });

    testWidgets('우클릭 메뉴 간격이 품목관리 기준 높이와 divider를 따른다', (tester) async {
      final controller = _controller();
      controller.setSelection(['update:10'], anchorRowKey: 'update:10');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      final table = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      await tester.tapAt(tester.getCenter(table), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      final addItem = tester.widget<PopupMenuItem<String>>(
        find.widgetWithText(PopupMenuItem<String>, '자동갱신 품목추가'),
      );
      final divider = tester.widgetList<PopupMenuDivider>(find.byType(PopupMenuDivider)).single;

      expect(addItem.height, fortuneContextMenuRowHeight);
      expect(addItem.padding, const EdgeInsets.symmetric(horizontal: 12));
      expect(divider.height, fortuneContextMenuDividerHeight);
    });

    testWidgets('빈 영역 우클릭에서는 제거된 보조 메뉴가 보이지 않는다', (tester) async {
      final controller = AutoItemUpdateDraftController(
        rows: const [],
        cellValues: const {},
        serverToday: DateTime(2026, 7, 25),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
            ),
          ),
        ),
      );

      final table = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      await tester.tapAt(tester.getCenter(table), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('블럭선택 날짜입력'), findsNothing);
      expect(find.text('품목찾기'), findsNothing);
      expect(find.text('새로 고침'), findsOneWidget);
    });

    testWidgets('add mode에서는 대상 우클릭 메뉴가 열리지 않는다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [_seed(30, '추가 품목')],
              sourceReady: true,
            ),
          ),
        ),
      );

      final target = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      await tester.tapAt(tester.getCenter(target), buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('자동갱신 품목추가'), findsNothing);
      expect(find.text('새로 고침'), findsNothing);
    });

    testWidgets('add mode source pane은 공용 table surface를 사용하고 title 없이 원본 품목명 header를 쓴다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [_seed(30, '추가 품목')],
              sourceReady: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('auto-item-update-source-table')), findsOneWidget);
      expect(find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>), findsOneWidget);
      expect(find.text('원본 품목'), findsNothing);
      expect(find.text('원본 품목명'), findsOneWidget);
      expect(find.byKey(const Key('auto-item-update-source-close-button')), findsOneWidget);
      expect(find.byTooltip('원본 품목 영역 닫기'), findsOneWidget);
    });

    testWidgets('source header 닫기 버튼을 누르면 원본 품목 영역이 숨겨진다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [_seed(30, '추가 품목')],
              sourceReady: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('auto-item-update-source-close-button')));
      await tester.pumpAndSettle();

      expect(controller.addModeOpen, isFalse);
      expect(find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>), findsNothing);
    });

    testWidgets('add mode에서 source 선택은 즉시 추가하고 source pane을 닫는다', (tester) async {
      final controller = _controller();
      controller.startAddMode();
      var applied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
              ],
              sourceReady: true,
              onApplyStagedRows: () async {
                applied = true;
                controller.applyStagedRows();
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('추가 품목').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('선택 품목 추가').first);
      await tester.pumpAndSettle();

      expect(applied, isTrue);
      expect(controller.rows.last.itemName, '추가 품목');
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.added);
      expect(controller.addModeOpen, isFalse);
      expect(find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>), findsNothing);
    });

    testWidgets('이미 추가된 source 항목은 선택과 드래그가 비활성화된다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(100, '첫 품목'),
                _seed(30, '추가 품목'),
              ],
              sourceReady: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('첫 품목').first);
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );

      expect(sourceTable.selectedIndex, isNull);
      expect(sourceTable.rowDragDataBuilder!(sourceTable.rows.first, 0), isNull);
      expect(sourceTable.rowDragDataBuilder!(sourceTable.rows[1], 1), isNotNull);
    });

    testWidgets('plain click은 source 단일 선택만 유지한다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
              ],
              sourceReady: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('추가 품목').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('다른 품목').first);
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final payload = sourceTable.rowDragDataBuilder!(sourceTable.rows[1], 1) as dynamic;

      expect(sourceTable.selectedIndex, 1);
      expect((payload.rows as List).length, 1);
      expect((payload.rows.first as AutoItemUpdateSourceSeed).itemId, 40);
    });

    testWidgets('ctrl+a는 선택 가능한 source 행 전체를 선택한다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(100, '첫 품목'),
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
              ],
              sourceReady: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('추가 품목').first);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final firstSelectablePayload =
          sourceTable.rowDragDataBuilder!(sourceTable.rows[1], 1) as dynamic;

      expect(sourceTable.selectedIndex, 1);
      expect((firstSelectablePayload.rows as List).length, 2);
      expect(
        (firstSelectablePayload.rows as List)
            .map((row) => (row as AutoItemUpdateSourceSeed).itemId)
            .toList(),
        [30, 40],
      );
    });

    testWidgets('source 세로 드래그는 범위 멀티선택으로 확장되지 않는다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
                _seed(50, '세번째 품목'),
              ],
              sourceReady: true,
            ),
          ),
        ),
      );

      final start = tester.getCenter(find.text('추가 품목').first);
      final target = tester.getCenter(find.text('세번째 품목').first);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final payload = sourceTable.rowDragDataBuilder!(sourceTable.rows.first, 0) as dynamic;

      expect(sourceTable.selectedIndex, 0);
      expect((payload.rows as List).length, 1);
      expect((payload.rows.first as AutoItemUpdateSourceSeed).itemId, 30);
    });

    testWidgets('source 가로 드래그는 범위 멀티선택으로 확장되지 않는다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
                _seed(50, '세번째 품목'),
              ],
              sourceReady: true,
            ),
          ),
        ),
      );

      final start = tester.getCenter(find.text('추가 품목').first);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(80, 6));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final payload = sourceTable.rowDragDataBuilder!(sourceTable.rows.first, 0) as dynamic;

      expect(sourceTable.selectedIndex, 0);
      expect((payload.rows as List).length, 1);
      expect((payload.rows.first as AutoItemUpdateSourceSeed).itemId, 30);
    });

    testWidgets('add mode에서 source row drag drop은 target 끝에 즉시 added row를 추가한다', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
              ],
              sourceReady: true,
              onApplyStagedRows: () async {
                controller.applyStagedRows();
              },
            ),
          ),
        ),
      );

      final source = find.text('추가 품목').first;
      final target = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump();

      final pressedSourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final pressedPayload =
          pressedSourceTable.rowDragDataBuilder!(pressedSourceTable.rows.first, 0)
              as dynamic;

        expect((pressedPayload.rows as List).length, 1);
      await tester.pump(const Duration(milliseconds: 120));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.rows.last.itemName, '추가 품목');
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.added);
      expect(controller.addModeOpen, isFalse);
    });

    testWidgets('add mode source multi drag drops every selected row with stacked feedback', (tester) async {
      final controller = _controller();
      controller.startAddMode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoItemUpdatePage(
              columns: [_column(7, '유통기한')],
              draftController: controller,
              sourceRows: [
                _seed(30, '추가 품목'),
                _seed(40, '다른 품목'),
                _seed(50, '세번째 품목'),
              ],
              sourceReady: true,
              onApplyStagedRows: () async {
                controller.applyStagedRows();
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('추가 품목').first);
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('다른 품목').first);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final sourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final payload = sourceTable.rowDragDataBuilder!(sourceTable.rows.first, 0) as dynamic;

      expect(sourceTable.rowDragFeedbackBuilder, isNotNull);
      expect((payload.rows as List).length, 2);

      final source = find.text('추가 품목').first;
      final target = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump();

      final pressedSourceTable = tester.widget<SwipeActionTable<AutoItemUpdateSourceSeed>>(
        find.byType(SwipeActionTable<AutoItemUpdateSourceSeed>),
      );
      final pressedPayload =
          pressedSourceTable.rowDragDataBuilder!(pressedSourceTable.rows.first, 0)
              as dynamic;

      expect((pressedPayload.rows as List).length, 2);
        await tester.pump(const Duration(milliseconds: 120));

      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final lastTwo = controller.rows.skip(controller.rows.length - 2).toList();

      expect(
        lastTwo.map((row) => row.itemName).toList(),
        ['추가 품목', '다른 품목'],
      );
      expect(
        lastTwo.every((row) => row.rowState == AutoItemUpdateRowState.added),
        isTrue,
      );
      expect(controller.addModeOpen, isFalse);
    });

  });
}

bool _buttonEnabled(WidgetTester tester, String text) {
  final finder = find.widgetWithText(OutlinedButton, text).evaluate().isNotEmpty
      ? find.widgetWithText(OutlinedButton, text)
      : find.widgetWithText(FilledButton, text);
  final button = tester.widgetList<ButtonStyleButton>(finder).last;
  return button.onPressed != null;
}

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
}

TColumn _column(int id, String name) {
  const type = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
  return TColumn(
    columnType: type,
    keyword: name,
    columnName: name,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    columnId: id,
    labelSizeId: 4,
    order: 1,
    width: 0,
    height: 0,
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
    visible: false,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 10,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
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
    gs1ai: '01',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

AutoItemUpdateDraftController _controller() {
  return AutoItemUpdateDraftController(
    rows: [
      AutoItemUpdateDraftRow.existing(
        source: UpdateItem(
          updateItemId: 10,
          itemId: 100,
          itemName: '첫 품목',
          labelSizeId: 4,
          element: '주원료',
          elementRTF: r'{\rtf1 element}',
          price: 0,
          applyDate: DateTime(2026, 7, 25),
          isApply: false,
        ),
        currentMarketId: 3,
        originalIndex: 0,
      ),
    ],
    cellValues: {
      const AutoItemUpdateCellKey(columnId: 7, rowKey: 'update:10'): const AutoItemUpdateCellValue(
        contentId: 1,
        columnId: 7,
        rowKey: 'update:10',
        editable: true,
        dataString: '원본 값',
      ),
    },
    serverToday: DateTime(2026, 7, 23),
  );
}

AutoItemUpdateSourceSeed _seed(int itemId, String itemName) {
  return AutoItemUpdateSourceSeed(
    itemId: itemId,
    itemName: itemName,
    labelSizeId: 4,
    element: '주원료',
    elementRtf: r'{\rtf1 element}',
    price: 0,
    currentMarketId: 3,
    columnValues: const {},
  );
}