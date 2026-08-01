import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:label_manager/core/app_menu_command.dart';
import 'package:label_manager/core/app_menu_policy.dart';
import 'package:label_manager/core/user.dart';

typedef AppMenuCommandHandler = FutureOr<void> Function();

class AppMenuController extends ChangeNotifier {
  final Map<Object, Map<AppMenuCommandId, AppMenuCommandHandler>>
  _handlersByOwner = {};
  final Set<AppMenuCommandId> _runningCommands = {};

  UserGrade? _userGrade;
  bool _isAdminConnect = false;
  bool _isCoopAdminConnect = false;
  bool _isFirstConnectByAdmin = false;
  bool _hasScaleOutputLabelSize = false;
  bool _workBlocked = false;
  Set<AppMenuCommandId> _busyCommands = const {};
  Set<AppMenuCommandId> _contextBlockedCommands = const {};

  bool _notificationScheduled = false;
  bool _disposed = false;

  Map<AppMenuCommandId, AppMenuCommandState> get commandStates {
    final policy = AppMenuPolicy(
      AppMenuPolicyContext(
        userGrade: _userGrade,
        isAdminConnect: _isAdminConnect,
        isCoopAdminConnect: _isCoopAdminConnect,
        isFirstConnectByAdmin: _isFirstConnectByAdmin,
        workBlocked: _workBlocked,
        hasScaleOutputLabelSize: _hasScaleOutputLabelSize,
        busyCommands: {..._busyCommands, ..._runningCommands},
        contextBlockedCommands: _contextBlockedCommands,
      ),
    );
    return {
      for (final command in appMenuCommands)
        command.id: _hasHandler(command.id)
            ? policy.stateFor(command.id)
            : const AppMenuCommandState.hidden(),
    };
  }

  void attach({
    required Object owner,
    required Map<AppMenuCommandId, AppMenuCommandHandler> handlers,
  }) {
    _handlersByOwner[owner] = Map.unmodifiable(handlers);
    _notifyListenersSafely();
  }

  void detach(Object owner) {
    if (_handlersByOwner.remove(owner) != null) {
      _notifyListenersSafely();
    }
  }

  void updateSession({
    required UserGrade? userGrade,
    bool isAdminConnect = false,
    bool isCoopAdminConnect = false,
    bool isFirstConnectByAdmin = false,
  }) {
    if (_userGrade == userGrade &&
        _isAdminConnect == isAdminConnect &&
        _isCoopAdminConnect == isCoopAdminConnect &&
        _isFirstConnectByAdmin == isFirstConnectByAdmin) {
      return;
    }
    _userGrade = userGrade;
    _isAdminConnect = isAdminConnect;
    _isCoopAdminConnect = isCoopAdminConnect;
    _isFirstConnectByAdmin = isFirstConnectByAdmin;
    _notifyListenersSafely();
  }

  void updateWorkState({
    required bool hasScaleOutputLabelSize,
    bool workBlocked = false,
    Set<AppMenuCommandId> busyCommands = const {},
    Set<AppMenuCommandId> contextBlockedCommands = const {},
  }) {
    if (_hasScaleOutputLabelSize == hasScaleOutputLabelSize &&
        _workBlocked == workBlocked &&
        setEquals(_busyCommands, busyCommands) &&
        setEquals(_contextBlockedCommands, contextBlockedCommands)) {
      return;
    }
    _hasScaleOutputLabelSize = hasScaleOutputLabelSize;
    _workBlocked = workBlocked;
    _busyCommands = Set.unmodifiable(busyCommands);
    _contextBlockedCommands = Set.unmodifiable(contextBlockedCommands);
    _notifyListenersSafely();
  }

  Future<void> execute(AppMenuCommandId id) async {
    final state = commandStates[id];
    final handler = _handlerFor(id);
    if (state?.enabled != true || handler == null) return;

    _runningCommands.add(id);
    _notifyListenersSafely();
    try {
      await handler();
    } finally {
      _runningCommands.remove(id);
      _notifyListenersSafely();
    }
  }

  void _notifyListenersSafely() {
    if (_disposed || _notificationScheduled) return;

    // Do not notify AnimatedBuilder synchronously. attach/updateWorkState can
    // be called from a descendant's initState or didUpdateWidget while an
    // ancestor AnimatedBuilder has already been built in the same build pass.
    // Deferring every notification avoids relying on schedulerPhase, which is
    // not a reliable public indicator for every BuildOwner.buildScope call.
    _notificationScheduled = true;

    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });

    // addPostFrameCallback does not request a frame by itself. This is needed
    // when the controller changes while the scheduler is idle or already in a
    // post-frame callback.
    binding.ensureVisualUpdate();
  }

  bool _hasHandler(AppMenuCommandId id) => _handlerFor(id) != null;

  AppMenuCommandHandler? _handlerFor(AppMenuCommandId id) {
    for (final handlers in _handlersByOwner.values) {
      final handler = handlers[id];
      if (handler != null) return handler;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
