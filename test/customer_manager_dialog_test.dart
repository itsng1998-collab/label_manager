import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/cooperator.dart';
import 'package:label_manager/models/customer.dart';
import 'package:label_manager/page_home/customer_manager_dialog.dart';

void main() {
  const customerA = Customer(
    customerId: 1,
    cooperatorId: 'A',
    customerName: 'A 거래처',
  );

  test('manager lifecycle blocks child and write work', () {
    final controller = CustomerManagerController();
    expect(controller.snapshot().blockingReason, isNull);
    controller.setActiveEditing(true);
    expect(controller.snapshot().blockingReason, contains('입력'));
    controller.setActiveEditing(false);
    controller.setWriteBusy(true);
    expect(controller.snapshot().blockingReason, contains('작업'));
    controller.dispose();
    controller.setWriteBusy(false);
  });

  testWidgets('disabled cooperator selector keeps current scope', (tester) async {
    final loadedScopes = <String>[];
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (cooperatorId) async {
        loadedScopes.add(cooperatorId);
        return const [customerA];
      },
    );

    final dropdown = tester.widget<DropdownMenu<String>>(
      find.byKey(const ValueKey('customerCooperatorSelector')),
    );
    expect(dropdown.enabled, isFalse);
    expect(loadedScopes, ['A']);
    expect(find.text('A 거래처'), findsOneWidget);
  });

  testWidgets('enabled selector reloads selected cooperator without row selection', (
    tester,
  ) async {
    final loadedScopes = <String>[];
    await _pumpManager(
      tester,
      selectionEnabled: true,
      inModelessOverlay: true,
      loadCustomers: (cooperatorId) async {
        loadedScopes.add(cooperatorId);
        return cooperatorId == 'A' ? const [customerA] : const [];
      },
    );

    await tester.tap(find.byKey(const ValueKey('customerCooperatorSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B').last);
    await tester.pumpAndSettle();

    expect(loadedScopes, ['A', 'B']);
    expect(find.text('A 거래처'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('customerConnectButton')));
    await tester.pumpAndSettle();
    expect(find.text('접속 할 행을 먼저 선택해주세요!!'), findsOneWidget);
  });

  testWidgets('add allows empty name and limits entered name to 50 chars', (
    tester,
  ) async {
    final inserted = <Customer>[];
    var loads = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (_) async {
        loads += 1;
        return const [];
      },
      insert: (customer) async => inserted.add(customer),
    );

    await tester.tap(find.byKey(const ValueKey('customerAddButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customerNameField')),
      '가' * 51,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(inserted, hasLength(1));
    expect(inserted.single.customerName.length, 50);
    expect(inserted.single.cooperatorId, 'A');
    expect(loads, 2);
  });

  testWidgets('connect needs selection and invokes selected row once', (
    tester,
  ) async {
    final connected = <int>[];
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (_) async => const [customerA],
      connect: (customer) async => connected.add(customer.customerId),
    );

    await tester.tap(find.byKey(const ValueKey('customerConnectButton')));
    await tester.pumpAndSettle();
    expect(connected, isEmpty);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('A 거래처'));
    await tester.tap(find.byKey(const ValueKey('customerConnectButton')));
    await tester.pumpAndSettle();
    expect(connected, [1]);
  });

  testWidgets('valid row double tap updates once and reloads', (tester) async {
    final updated = <Customer>[];
    var loads = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (_) async {
        loads += 1;
        return const [customerA];
      },
      update: (customer) async => updated.add(customer),
    );

    await _doubleTap(tester, find.text('A 거래처'));
    await tester.enterText(
      find.byKey(const ValueKey('customerNameField')),
      '수정 거래처',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(updated, hasLength(1));
    expect(updated.single.customerId, 1);
    expect(updated.single.customerName, '수정 거래처');
    expect(loads, 2);
  });

  testWidgets('committed add closes after reload failure', (tester) async {
    var loads = 0;
    var closes = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (_) async {
        loads += 1;
        if (loads > 1) throw Exception('reload failed');
        return const [];
      },
      insert: (_) async {},
      onClose: () => closes += 1,
    );

    await tester.tap(find.byKey(const ValueKey('customerAddButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('적용'));
    await tester.pumpAndSettle();

    expect(find.text('저장은 완료됐지만 화면 갱신에 실패했습니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(closes, 1);
  });

  testWidgets('delete uses password and one cascade warning', (tester) async {
    final deleted = <int>[];
    var loads = 0;
    await _pumpManager(
      tester,
      selectionEnabled: false,
      loadCustomers: (_) async {
        loads += 1;
        return const [customerA];
      },
      delete: (customerId) async => deleted.add(customerId),
      systemPassword: ([now]) => '1234',
    );

    await tester.tap(find.text('A 거래처'));
    await tester.tap(find.byKey(const ValueKey('customerDeleteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customerSystemPasswordField')),
      '0000',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
    expect(find.textContaining('모든 데이터가 삭제됩니다'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('customerDeleteButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customerSystemPasswordField')),
      '1234',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('모든 데이터가 삭제됩니다'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(loads, 2);
  });
}

Future<void> _pumpManager(
  WidgetTester tester, {
  required bool selectionEnabled,
  required Future<List<Customer>> Function(String cooperatorId) loadCustomers,
  Future<void> Function(Customer customer)? insert,
  Future<void> Function(Customer customer)? update,
  Future<void> Function(int customerId)? delete,
  Future<void> Function(Customer customer)? connect,
  String Function([DateTime? now])? systemPassword,
  VoidCallback? onClose,
  bool inModelessOverlay = false,
}) async {
  final controller = CustomerManagerController();
  addTearDown(controller.dispose);
  final manager = SizedBox(
    width: 820,
    height: 660,
    child: CustomerManagerDialogContent(
      controller: controller,
      onClose: onClose ?? () {},
      initialCooperator: const Cooperator(id: 'A', name: 'A 업체'),
      cooperatorSelectionEnabled: selectionEnabled,
      loadCooperators: () async => const [
        Cooperator(id: 'A', name: 'A 업체'),
        Cooperator(id: 'B', name: 'B 업체'),
      ],
      loadCustomers: loadCustomers,
      insert: insert ?? (customer) async {},
      update: update ?? (customer) async {},
      delete: delete ?? (customerId) async {},
      connect: connect ?? (customer) async {},
      systemPassword: systemPassword ?? ([now]) => '1234',
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