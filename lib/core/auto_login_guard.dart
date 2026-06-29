/// Global flag holder that tracks whether the current session requested
/// auto-login behavior.
class AutoLoginGuard {
  AutoLoginGuard._();

  static final AutoLoginGuard instance = AutoLoginGuard._();

  bool _isAutoLogin = false;

  bool get enabled => _isAutoLogin;

  void configure({required bool enabled}) {
    _isAutoLogin = enabled;
  }

  void reset() {
    _isAutoLogin = false;
  }
}
