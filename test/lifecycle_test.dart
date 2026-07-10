import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/lifecycle.dart';

void main() {
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
}
