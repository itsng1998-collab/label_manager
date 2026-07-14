import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';

void main() {
  testWidgets('frame renders shared title bar body footer and close action', (
    tester,
  ) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialogFrame(
          title: '공통 설정',
          width: 240,
          height: 160,
          onClose: () => closeCount += 1,
          footer: const Text('footer'),
          child: const Text('body'),
        ),
      ),
    );

    expect(find.text('공통 설정'), findsOneWidget);
    expect(find.text('body'), findsOneWidget);
    expect(find.text('footer'), findsOneWidget);

    await tester.tap(find.byTooltip('닫기'));
    expect(closeCount, 1);
  });

  testWidgets('frame disables close action while operation is active', (
    tester,
  ) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialogFrame(
          title: '공통 설정',
          width: 240,
          height: 160,
          closeEnabled: false,
          onClose: () => closeCount += 1,
          child: const Text('body'),
        ),
      ),
    );

    final closeButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(closeButton.onPressed, isNull);
    await tester.tap(find.byType(IconButton));
    expect(closeCount, 0);
  });

  testWidgets('blocks pointer events outside dialog content', (tester) async {
    var outsideTapCount = 0;
    var insideTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => outsideTapCount += 1,
              ),
            ),
            BlockingModelessDialog(
              child: Center(
                child: SizedBox(
                  width: 120,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => insideTapCount += 1,
                    child: const Text('inside'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tapAt(const Offset(10, 10));
    await tester.tap(find.text('inside'));

    expect(outsideTapCount, 0);
    expect(insideTapCount, 1);
  });

  testWidgets('allows listener callbacks inside dialog content', (
    tester,
  ) async {
    var insidePointerDownCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialog(
          child: Center(
            child: Listener(
              onPointerDown: (_) => insidePointerDownCount += 1,
              child: const SizedBox(
                width: 120,
                height: 80,
                child: ColoredBox(
                  key: ValueKey('inside-listener-target'),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('inside-listener-target'))),
    );

    expect(insidePointerDownCount, 1);
  });

  testWidgets('does not block non input listeners behind overlay', (
    tester,
  ) async {
    final notifier = ValueNotifier<int>(0);
    var listenerCount = 0;
    notifier.addListener(() => listenerCount += 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: notifier,
              builder: (context, value, _) => Text('outside $value'),
            ),
            const BlockingModelessDialog(child: Center(child: Text('dialog'))),
          ],
        ),
      ),
    );

    notifier.value = 1;
    await tester.pump();

    expect(listenerCount, 1);
    expect(find.text('outside 1'), findsOneWidget);

    notifier.dispose();
  });

  testWidgets('allows dialog callbacks to update outside listeners', (
    tester,
  ) async {
    final notifier = ValueNotifier<int>(0);
    var listenerCount = 0;
    notifier.addListener(() => listenerCount += 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: notifier,
              builder: (context, value, _) => Text('outside $value'),
            ),
            BlockingModelessDialog(
              child: Center(
                child: ElevatedButton(
                  onPressed: () => notifier.value += 1,
                  child: const Text('dialog update'),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('dialog update'));
    await tester.pump();

    expect(listenerCount, 1);
    expect(find.text('outside 1'), findsOneWidget);

    notifier.dispose();
  });

  testWidgets('allows modal alert dialogs above modeless dialog', (
    tester,
  ) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialog(
          child: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      content: const Text('확인하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                  confirmed = result == true;
                },
                child: const Text('open alert'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open alert'));
    await tester.pumpAndSettle();

    expect(find.text('확인하시겠습니까?'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('shows alert above modeless OverlayEntry', (tester) async {
    var confirmed = false;
    OverlayEntry? entry;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              entry = OverlayEntry(
                builder: (overlayContext) => BlockingModelessDialog(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final result =
                            await showBlockingModelessOverlayDialog<bool>(
                              context: overlayContext,
                              builder: (dialogContext, close) => AlertDialog(
                                content: const Text('오버레이 확인'),
                                actions: [
                                  TextButton(
                                    onPressed: () => close(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => close(true),
                                    child: const Text('확인'),
                                  ),
                                ],
                              ),
                            );
                        confirmed = result == true;
                      },
                      child: const Text('open overlay alert'),
                    ),
                  ),
                ),
              );
              Overlay.of(context).insert(entry!);
            },
            child: const Text('open modeless'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open modeless'));
    await tester.pump();
    await tester.tap(find.text('open overlay alert'));
    await tester.pump();

    expect(find.text('오버레이 확인'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pump();

    expect(confirmed, isTrue);

    entry?.remove();
  });

  testWidgets('blocks key events from focused widget behind overlay', (
    tester,
  ) async {
    var outsideKeyCount = 0;
    final outsideFocus = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Focus(
              focusNode: outsideFocus,
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  outsideKeyCount += 1;
                }
                return KeyEventResult.handled;
              },
              child: const SizedBox.expand(),
            ),
            const BlockingModelessDialog(child: Center(child: Text('dialog'))),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);

    expect(outsideKeyCount, 0);

    outsideFocus.dispose();
  });

  testWidgets('allows keyboard text editing inside dialog content', (
    tester,
  ) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: BlockingModelessDialog(
          child: Center(
            child: Material(
              child: SizedBox(
                width: 220,
                child: TextField(controller: controller, autofocus: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'typing works');
    await tester.pump();

    expect(controller.text, 'typing works');

    controller.dispose();
  });
}
