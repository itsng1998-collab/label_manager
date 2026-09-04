import 'dart:async';

import 'package:flutter/widgets.dart';

typedef LifecycleCallback = Future<void> Function();
typedef ExitRequestCallback = Future<bool> Function();
typedef LifecycleExitAction = FutureOr<void> Function();
typedef LifecycleExitSnapshotProvider =
    FutureOr<LifecycleExitSnapshot> Function();

Future<void> requestApplicationExit({
  required bool isDesktop,
  required LifecycleExitAction requestDesktopWindowClose,
  required ExitRequestCallback requestNonDesktopExit,
  required LifecycleExitAction closeNonDesktopApplication,
}) async {
  if (isDesktop) {
    await requestDesktopWindowClose();
    return;
  }
  if (!await requestNonDesktopExit()) return;
  await closeNonDesktopApplication();
}

class LifecycleDirtyWork {
  const LifecycleDirtyWork({required this.name, required this.discard});

  final String name;
  final LifecycleExitAction discard;
}

class LifecycleExitSnapshot {
  const LifecycleExitSnapshot({
    this.blockingReason,
    this.dirtyWorks = const [],
  });

  final String? blockingReason;
  final List<LifecycleDirtyWork> dirtyWorks;
}

class LifecycleParticipant {
  const LifecycleParticipant({required this.snapshot, required this.close});

  final LifecycleExitSnapshotProvider snapshot;
  final LifecycleExitAction close;
}

class LifecycleExitPlan {
  LifecycleExitPlan._({
    required this.blockingReasons,
    required this.dirtyWorks,
    required List<LifecycleExitAction> closeActions,
  }) : _closeActions = closeActions;

  final List<String> blockingReasons;
  final List<LifecycleDirtyWork> dirtyWorks;
  final List<LifecycleExitAction> _closeActions;
  bool _discarded = false;
  bool _closed = false;

  Future<void> discardDirty() async {
    if (_discarded) return;
    _discarded = true;
    for (final work in dirtyWorks) {
      await work.discard();
    }
  }

  Future<void> closeParticipants() async {
    if (_closed) return;
    _closed = true;
    for (final close in _closeActions) {
      await close();
    }
  }
}

/// 콜백 모음: 필요한 이벤트만 선택적으로 전달하면 됩니다.
class LifecycleCallbacks {
  final LifecycleCallback? onResumed;
  final LifecycleCallback? onInactive;
  final LifecycleCallback? onPaused;
  final LifecycleCallback? onDetached; // 엔진 분리 (종료 직전)
  final ExitRequestCallback? onExitRequested; // false면 명시적 종료 요청 취소

  const LifecycleCallbacks({
    this.onResumed,
    this.onInactive,
    this.onPaused,
    this.onDetached,
    this.onExitRequested,
  });
}

/// 앱 전역 라이프사이클을 관찰/브로드캐스트하는 싱글톤 매니저.
class LifecycleManager with WidgetsBindingObserver {
  LifecycleManager._internal();
  static final LifecycleManager instance = LifecycleManager._internal();

  bool _initialized = false;
  final Set<LifecycleCallbacks> _observers = <LifecycleCallbacks>{};
  final Set<LifecycleParticipant> _participants = <LifecycleParticipant>{};

  /// WidgetsBinding에 옵저버를 1회만 등록합니다.
  void ensureInitialized() {
    if (_initialized) return;
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    _initialized = true;
  }

  /// 옵저버(콜백 묶음)를 등록합니다.
  void addObserver(LifecycleCallbacks callbacks) {
    _observers.add(callbacks);
  }

  /// 등록된 옵저버를 제거합니다.
  void removeObserver(LifecycleCallbacks callbacks) {
    _observers.remove(callbacks);
  }

  void addParticipant(LifecycleParticipant participant) {
    _participants.add(participant);
  }

  void removeParticipant(LifecycleParticipant participant) {
    _participants.remove(participant);
  }

  Future<LifecycleExitPlan> collectExitPlan({
    Iterable<LifecycleExitSnapshot> ownerSnapshots = const [],
  }) async {
    final snapshots = <LifecycleExitSnapshot>[...ownerSnapshots];
    final participants = List<LifecycleParticipant>.from(_participants);
    for (final participant in participants) {
      snapshots.add(await participant.snapshot());
    }
    return LifecycleExitPlan._(
      blockingReasons: [
        for (final snapshot in snapshots)
          ?snapshot.blockingReason,
      ],
      dirtyWorks: [
        for (final snapshot in snapshots) ...snapshot.dirtyWorks,
      ],
      closeActions: [for (final participant in participants) participant.close],
    );
  }

  /// 수명 종료 시 매니저를 해제합니다.
  void dispose() {
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      _initialized = false;
    }
    _observers.clear();
    _participants.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Future<void> runCallback(LifecycleCallback? callback) async {
      try {
        await callback?.call();
      } catch (_) {
        // 개별 콜백 오류는 전파하지 않음
      }
    }

    for (final cb in List<LifecycleCallbacks>.from(_observers)) {
      switch (state) {
        case AppLifecycleState.resumed:
          runCallback(cb.onResumed);
          break;
        case AppLifecycleState.inactive:
          runCallback(cb.onInactive);
          break;
        case AppLifecycleState.paused:
          runCallback(cb.onPaused);
          break;
        case AppLifecycleState.detached:
          runCallback(cb.onDetached);
          break;
        case AppLifecycleState.hidden:
          // Android/desktop에서 화면이 완전히 숨겨졌을 때. 특별 처리 필요시 콜백을 추가하세요.
          break;
      }
    }
  }

  /// 창 닫기 등 명시적 종료 요청 시 수동으로 호출해 콜백을 알립니다.
  Future<bool> notifyExitRequested() async {
    for (final cb in List<LifecycleCallbacks>.from(_observers)) {
      try {
        if (await cb.onExitRequested?.call() == false) return false;
      } catch (_) {
        return false;
      }
    }
    return true;
  }
}
