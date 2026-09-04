import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/lifecycle.dart';

void main() {
  test('desktop exit delegates once to the native window close listener', () async {
    var desktopCloseCount = 0;
    var lifecycleRequestCount = 0;
    var navigatorCloseCount = 0;

    await requestApplicationExit(
      isDesktop: true,
      requestDesktopWindowClose: () => desktopCloseCount += 1,
      requestNonDesktopExit: () async {
        lifecycleRequestCount += 1;
        return true;
      },
      closeNonDesktopApplication: () => navigatorCloseCount += 1,
    );

    expect(desktopCloseCount, 1);
    expect(lifecycleRequestCount, 0);
    expect(navigatorCloseCount, 0);
  });

  test('non-desktop exit closes only after lifecycle approval', () async {
    var closeCount = 0;

    await requestApplicationExit(
      isDesktop: false,
      requestDesktopWindowClose: () {},
      requestNonDesktopExit: () async => false,
      closeNonDesktopApplication: () => closeCount += 1,
    );
    expect(closeCount, 0);

    await requestApplicationExit(
      isDesktop: false,
      requestDesktopWindowClose: () {},
      requestNonDesktopExit: () async => true,
      closeNonDesktopApplication: () => closeCount += 1,
    );
    expect(closeCount, 1);
  });

  test('exit request stops when an observer rejects it', () async {
    final manager = LifecycleManager.instance;
    var laterObserverCalled = false;
    final rejecting = LifecycleCallbacks(onExitRequested: () async => false);
    final later = LifecycleCallbacks(
      onExitRequested: () async {
        laterObserverCalled = true;
        return true;
      },
    );
    manager.addObserver(rejecting);
    manager.addObserver(later);
    addTearDown(() {
      manager.removeObserver(rejecting);
      manager.removeObserver(later);
    });

    expect(await manager.notifyExitRequested(), isFalse);
    expect(laterObserverCalled, isFalse);
  });

  test('exit plan collects each participant snapshot once', () async {
    final manager = LifecycleManager.instance;
    var snapshotCount = 0;
    final participant = LifecycleParticipant(
      snapshot: () {
        snapshotCount += 1;
        return const LifecycleExitSnapshot(blockingReason: '작업 중');
      },
      close: () {},
    );
    manager.addParticipant(participant);
    addTearDown(() => manager.removeParticipant(participant));

    final plan = await manager.collectExitPlan();

    expect(snapshotCount, 1);
    expect(plan.blockingReasons, ['작업 중']);
  });

  test('exit plan runs dirty discard and participant close once', () async {
    final manager = LifecycleManager.instance;
    var discardCount = 0;
    var closeCount = 0;
    final participant = LifecycleParticipant(
      snapshot: () => LifecycleExitSnapshot(
        dirtyWorks: [
          LifecycleDirtyWork(
            name: '품목관리',
            discard: () => discardCount += 1,
          ),
        ],
      ),
      close: () => closeCount += 1,
    );
    manager.addParticipant(participant);
    addTearDown(() => manager.removeParticipant(participant));

    final plan = await manager.collectExitPlan();
    await plan.discardDirty();
    await plan.discardDirty();
    await plan.closeParticipants();
    await plan.closeParticipants();

    expect(plan.dirtyWorks.map((work) => work.name), ['품목관리']);
    expect(discardCount, 1);
    expect(closeCount, 1);
  });
}
