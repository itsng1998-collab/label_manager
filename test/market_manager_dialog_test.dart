import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/cooperator/domain/cooperator.dart';
import 'package:label_manager/features/customer/domain/customer.dart';
import 'package:label_manager/features/market/domain/market.dart';
import 'package:label_manager/features/market/presentation/market_manager_dialog.dart';
import 'package:label_manager/widgets/modeless_dropdown_form_field.dart';

void main() {
  const marketA = Market(marketId: 1, customerId: 10, name: 'A 지점');

  test('manager lifecycle blocks child and write work', () {
    final controller = MarketManagerController();
    expect(controller.snapshot().blockingReason, isNull);
    controller.setActiveEditing(true);
    expect(controller.snapshot().blockingReason, contains('입력'));
    controller.setActiveEditing(false);
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, contains('작업'));
    controller.dispose();
    controller.setWriteBusy(false);
  });

  testWidgets(
    'cooperator change clears customer and commands without fallback',
    (tester) async {
      final marketScopes = <int>[];
      await _pumpManager(
        tester,
        selectionEnabled: true,
        inModelessOverlay: true,
        loadMarkets: (customerId) async {
          marketScopes.add(customerId);
          return const [marketA];
        },
      );

      await tester.tap(find.byKey(const ValueKey('marketCooperatorSelector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B').last);
      await tester.pumpAndSettle();

      expect(marketScopes, [10]);
      expect(find.text('A 지점'), findsNothing);
      final add = tester.widget<IconButton>(
        find.byKey(const ValueKey('marketAddButton')),
      );
      final delete = tester.widget<IconButton>(
        find.byKey(const ValueKey('marketDeleteButton')),
      );
      expect(add.onPressed, isNull);
      expect(delete.onPressed, isNull);
    },
  );

  testWidgets('selectors use compact height and centered labels', (
    tester,
  ) async {
    await _pumpManager(
      tester,
      selectionEnabled: true,
      loadMarkets: (_) async => const [marketA],
    );

    for (final key in const [
      ValueKey('marketCooperatorSelector'),
      ValueKey('marketCustomerSelector'),
    ]) {
      final selector = find.byKey(key);
      expect(tester.getSize(selector).height, modelessDropdownFieldHeight);
    }

    final cooperatorCenter = tester.getCenter(
      find.byKey(const ValueKey('marketCooperatorSelector')),
    );
    expect(
      tester.getCenter(find.text('A')).dy,
      moreOrLessEquals(cooperatorCenter.dy),
    );
  });

  testWidgets('explicit customer selection enables empty-name add and reload', (
    tester,
  ) async {
    final inserted = <Market>[];
    var loads = 0;
    await _pumpManager(
      tester,
      selectionEnabled: true,
      loadMarkets: (_) async {
        loads += 1;
        return const [];
      },
      insert: (market) async {
        inserted.add(market);
        return 20;
      },
    );
    await tester.tap(find.byKey(const ValueKey('marketCooperatorSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('marketCustomerSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B 거래처').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('marketAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(inserted, hasLength(1));
    expect(inserted.single.customerId, 20);
    expect(inserted.single.name, isEmpty);
    expect(loads, 3);
  });

  testWidgets('valid row double tap updates and delete uses one warning', (
    tester,
  ) async {
    final updated = <Market>[];
    final deleted = <int>[];
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadMarkets: (_) async => const [marketA],
      update: (market) async => updated.add(market),
      delete: (marketId) async => deleted.add(marketId),
    );

    await _doubleTap(tester, find.text('A 지점'));
    await tester.enterText(
      find.byKey(const ValueKey('marketNameField')),
      '수정 지점',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(updated.single.name, '수정 지점');

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A 지점'));
    await tester.tap(find.byKey(const ValueKey('marketDeleteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('marketSystemPasswordField')),
      '1234',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('모든 ID가 삭제됩니다'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(deleted, [1]);
  });

  testWidgets('committed update closes after reload failure', (tester) async {
    var loads = 0;
    var closes = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadMarkets: (_) async {
        loads += 1;
        if (loads > 1) throw Exception('reload failed');
        return const [marketA];
      },
      update: (_) async {},
      onClose: () => closes += 1,
    );

    await _doubleTap(tester, find.text('A 지점'));
    await tester.enterText(
      find.byKey(const ValueKey('marketNameField')),
      '수정 지점',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });

  testWidgets('unknown commit outcome closes without reload', (tester) async {
    var loads = 0;
    var closes = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadMarkets: (_) async {
        loads += 1;
        return const [marketA];
      },
      update: (_) async => throw const DbCommitOutcomeUnknown('commit lost'),
      onClose: () => closes += 1,
    );

    await _doubleTap(tester, find.text('A 지점'));
    await tester.enterText(
      find.byKey(const ValueKey('marketNameField')),
      '수정 지점',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('commit lost'), findsOneWidget);
    expect(loads, 1);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });
}

Future<void> _pumpManager(
  WidgetTester tester, {
  required bool selectionEnabled,
  required Future<List<Market>?> Function(int customerId) loadMarkets,
  Future<int> Function(Market market)? insert,
  Future<void> Function(Market market)? update,
  Future<void> Function(int marketId)? delete,
  VoidCallback? onClose,
  bool inModelessOverlay = false,
}) async {
  final controller = MarketManagerController();
  addTearDown(controller.dispose);
  final manager = SizedBox(
    width: 900,
    height: 660,
    child: MarketManagerDialogContent(
      controller: controller,
      onClose: onClose ?? () {},
      initialCooperator: const Cooperator(id: 'A', name: 'A 업체'),
      initialCustomer: const Customer(
        customerId: 10,
        cooperatorId: 'A',
        customerName: 'A 거래처',
      ),
      cooperatorSelectionEnabled: selectionEnabled,
      loadCooperators: () async => const [
        Cooperator(id: 'A', name: 'A 업체'),
        Cooperator(id: 'B', name: 'B 업체'),
      ],
      loadCustomers: (cooperatorId) async => cooperatorId == 'A'
          ? const [
              Customer(
                customerId: 10,
                cooperatorId: 'A',
                customerName: 'A 거래처',
              ),
            ]
          : const [
              Customer(
                customerId: 20,
                cooperatorId: 'B',
                customerName: 'B 거래처',
              ),
            ],
      loadMarkets: loadMarkets,
      insert: insert ?? (market) async => 1,
      update: update ?? (market) async {},
      delete: delete ?? (marketId) async {},
      systemPassword: ([now]) => '1234',
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: inModelessOverlay
          ? _OverlayHost(child: manager)
          : Scaffold(body: manager),
    ),
  );
  await tester.pumpAndSettle();
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
        builder: (_) => Center(child: Material(child: widget.child)),
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

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
}
