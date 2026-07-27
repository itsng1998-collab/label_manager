import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/models/nutrition_type.dart';
import 'package:label_manager/page_home/nutrition_type_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required NutritionTypeDialogController controller,
    NutritionTypeListLoader? loadTypes,
    NutritionTypeListLoader? loadTypesById,
    NutritionTypeColumnsLoader? loadColumns,
    NutritionTypeWriter? insert,
    NutritionTypeUpdater? update,
    NutritionTypeDeleter? delete,
    VoidCallback? onClose,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NutritionTypeDialogContent(
            controller: controller,
            onCommitOutcomeUnknown: onClose ?? () {},
            loadTypes: loadTypes ?? (() async => const []),
            loadTypesById: loadTypesById ?? (() async => const []),
            loadColumns: loadColumns ?? ((_) async => const []),
            insert: insert ?? ((_, __) async {}),
            update: update ?? ((_, __, ___) async {}),
            delete: delete ?? ((_) async {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('keyword numbering uses displayed last row and reset after clear', () {
    expect(nutritionTypeNextKeyword(const []), 'N01');
    expect(
      nutritionTypeNextKeyword(const [
        NutritionTypeColumn(id: 1, keyword: 'N01', name: '열량'),
        NutritionTypeColumn(id: 3, keyword: 'N03', name: '탄수화물'),
      ]),
      'N04',
    );
    expect(nutritionTypeNextKeyword(const []), 'N01');
  });

  testWidgets('manager commands are enabled and modify without selection shows hint', (
    tester,
  ) async {
    final controller = NutritionTypeDialogController();
    addTearDown(controller.dispose);
    await pumpDialog(
      tester,
      controller: controller,
      loadTypes: () async => const [NutritionType(id: 1, name: '기본형')],
    );

    final addButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionTypeAddButton')),
    );
    final modifyButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionTypeModifyButton')),
    );
    final deleteButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('nutritionTypeDeleteButton')),
    );
    expect(addButton.onPressed, isNotNull);
    expect(modifyButton.onPressed, isNotNull);
    expect(deleteButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('nutritionTypeModifyButton')));
    await tester.pumpAndSettle();

    expect(find.text('수정할 행을 먼저 선택해주세요!!'), findsOneWidget);
  });

  testWidgets('template replacement keeps create mode and name', (tester) async {
    final controller = NutritionTypeDialogController();
    addTearDown(controller.dispose);

    var insertCalls = 0;
    var updateCalls = 0;
    List<NutritionTypeColumn> insertedRows = const [];
    await pumpDialog(
      tester,
      controller: controller,
      loadTypes: () async => const [NutritionType(id: 10, name: '기존')],
      loadTypesById: () async => const [
        NutritionType(id: 1, name: '템플릿A'),
        NutritionType(id: 2, name: '템플릿B'),
      ],
      loadColumns: (typeId) async {
        if (typeId == 2) {
          return const [
            NutritionTypeColumn(id: 9, keyword: 'N09', name: '지방'),
            NutritionTypeColumn(id: 10, keyword: 'N10', name: '당류'),
          ];
        }
        return const [
          NutritionTypeColumn(id: 1, keyword: 'N01', name: '열량'),
        ];
      },
      insert: (name, rows) async {
        insertCalls += 1;
        insertedRows = rows;
      },
      update: (_, __, ___) async {
        updateCalls += 1;
      },
    );

    await tester.tap(find.byKey(const ValueKey('nutritionTypeAddButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('nutritionTypeNameField')),
      '사용자입력 형식',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('nutritionTypeTemplateSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 - 템플릿B').last);
    await tester.pumpAndSettle();

    expect(find.text('영양성분 형식 추가'), findsOneWidget);
    expect(find.text('사용자입력 형식'), findsOneWidget);

    final table = tester.widget<FortuneTable<NutritionTypeColumn>>(
      find.byKey(const ValueKey('nutritionTypeDraftTable')),
    );
    expect(table.rows.map((row) => row.keyword).toList(), ['N09', 'N10']);

    await tester.tap(find.byKey(const ValueKey('nutritionTypeDraftSaveButton')));
    await tester.pumpAndSettle();

    expect(insertCalls, 1);
    expect(updateCalls, 0);
    expect(insertedRows.map((row) => row.keyword).toList(), ['N09', 'N10']);
  });

  testWidgets('save validates only empty name and empty rows', (tester) async {
    final controller = NutritionTypeDialogController();
    addTearDown(controller.dispose);
    await pumpDialog(
      tester,
      controller: controller,
      loadTypesById: () async => const [NutritionType(id: 1, name: '기본')],
      loadColumns: (_) async => const [
        NutritionTypeColumn(id: 1, keyword: 'N01', name: ''),
      ],
    );

    await tester.tap(find.byKey(const ValueKey('nutritionTypeAddButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nutritionTypeDraftSaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('형식명을 입력해주세요!!'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('nutritionTypeNameField')),
      '새 형식',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('nutritionTypeDraftSaveButton')));
    await tester.pumpAndSettle();
    expect(find.text('영양성분 구성을 한 개 이상 입력해주세요!!'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nutritionTypeTemplateSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 - 기본').last);
    await tester.pumpAndSettle();

    final table = tester.widget<FortuneTable<NutritionTypeColumn>>(
      find.byKey(const ValueKey('nutritionTypeDraftTable')),
    );
    expect(table.rows.single.name, '');
  });

  testWidgets('committed delete closes after list reload failure', (
    tester,
  ) async {
    final controller = NutritionTypeDialogController();
    addTearDown(controller.dispose);
    var loads = 0;
    var closes = 0;
    await pumpDialog(
      tester,
      controller: controller,
      loadTypes: () async {
        loads += 1;
        if (loads > 1) throw Exception('reload failed');
        return const [NutritionType(id: 1, name: '기본형')];
      },
      delete: (_) async {},
      onClose: () => closes += 1,
    );

    await tester.tap(find.text('기본형'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('nutritionTypeDeleteButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });
}