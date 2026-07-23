import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/automatic_item_update_draft.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/update_item.dart';
import 'package:label_manager/page_home/automatic_item_update_page.dart';
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

    testWidgets('추가 mode에서는 dirty여도 기본 취소 저장이 비활성화된다', (tester) async {
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

      expect(_buttonEnabled(tester, '취소'), isFalse);
      expect(_buttonEnabled(tester, '저장'), isFalse);
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

    testWidgets('빈 영역 우클릭에서는 날짜입력과 품목찾기가 비활성화된다', (tester) async {
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

      final inputDateItem = tester.widget<PopupMenuItem<String>>(
        find.widgetWithText(PopupMenuItem<String>, '블럭선택 날짜입력'),
      );
      final findItemItem = tester.widget<PopupMenuItem<String>>(
        find.widgetWithText(PopupMenuItem<String>, '품목찾기'),
      );

      expect(inputDateItem.enabled, isFalse);
      expect(findItemItem.enabled, isFalse);
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

    testWidgets('add mode source pane은 공용 table surface를 사용한다', (tester) async {
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
    });

    testWidgets('add mode에서 source 선택을 staged row로 추가하고 적용할 수 있다', (tester) async {
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

      expect(find.byTooltip('선택 품목 추가'), findsOneWidget);
      expect(controller.rows.last.itemName, '추가 품목');
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.staged);
      expect(find.widgetWithText(FilledButton, '적용'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '적용'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '적용').last);
      await tester.pumpAndSettle();

      expect(applied, isTrue);
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.added);
      expect(controller.addModeOpen, isFalse);
    });

    testWidgets('add mode에서 source row drag drop이 target 끝에 staged row를 추가한다', (tester) async {
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

      final source = find.text('추가 품목').first;
      final target = find.byType(FortuneTable<AutoItemUpdateDraftRow>);
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.rows.last.itemName, '추가 품목');
      expect(controller.rows.last.rowState, AutoItemUpdateRowState.staged);
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

TColumn _column(int id, String name) {
  const type = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
  return TColumn(
    columnType: type,
    keyword: name,
    columnName: name,
    useMissingKeywordCheck: false,
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