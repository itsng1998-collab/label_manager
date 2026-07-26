import 'dart:collection';

import 'package:flutter/widgets.dart';

class AppShortcutBlocker extends ChangeNotifier {
  AppShortcutBlocker._();

  static final AppShortcutBlocker instance = AppShortcutBlocker._();

  final Set<Object> _activeOwners = HashSet<Object>.identity();

  bool get isBlocked => _activeOwners.isNotEmpty;

  void activate(Object owner) {
    if (_activeOwners.add(owner)) notifyListeners();
  }

  void deactivate(Object owner) {
    if (_activeOwners.remove(owner)) notifyListeners();
  }

  @visibleForTesting
  void reset() {
    if (_activeOwners.isEmpty) return;
    _activeOwners.clear();
    notifyListeners();
  }
}

class AppShortcutBlockingScope extends StatefulWidget {
  const AppShortcutBlockingScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppShortcutBlockingScope> createState() =>
      _AppShortcutBlockingScopeState();
}

class _AppShortcutBlockingScopeState extends State<AppShortcutBlockingScope> {
  @override
  void initState() {
    super.initState();
    AppShortcutBlocker.instance.activate(this);
  }

  @override
  void dispose() {
    AppShortcutBlocker.instance.deactivate(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}