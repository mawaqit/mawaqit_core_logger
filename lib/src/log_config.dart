import 'package:flutter/foundation.dart';

class LogConfig {
  LogConfig._(); // prevent instantiation

  static bool _forceEnableInRelease = false;
  static DateTime? _enabledAt;
  static Duration _timeout = const Duration(hours: 2);

  /// Enable logging temporarily in release mode.
  /// [timeout] defaults to 2 hours, after which logging auto-disables.
  static void enableTemporarily({Duration? timeout}) {
    if (timeout != null) _timeout = timeout;
    _forceEnableInRelease = true;
    _enabledAt = DateTime.now();
    debugPrint(
      '[LogConfig] ⚠️ WARNING: Logging force-enabled in release mode. '
          'Will auto-disable after ${_timeout.inMinutes} minutes.',
    );
  }

  /// Manually disable release logging immediately.
  static void disable() {
    _forceEnableInRelease = false;
    _enabledAt = null;
    debugPrint('[LogConfig] ✅ Release logging disabled.');
  }

  /// Whether logging is currently allowed.
  static bool get shouldLog {
    // Always log in debug/profile
    if (kDebugMode || kProfileMode) return true;

    // Release mode — check if force-enabled
    if (!_forceEnableInRelease) return false;

    // Auto-expire after timeout
    if (_enabledAt != null &&
        DateTime.now().difference(_enabledAt!) > _timeout) {
      disable();
      return false;
    }

    return true;
  }

  /// How much time is left before auto-disable (null if not active)
  static Duration? get timeRemaining {
    if (!_forceEnableInRelease || _enabledAt == null) return null;
    final elapsed = DateTime.now().difference(_enabledAt!);
    final remaining = _timeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether release logging is currently force-enabled
  static bool get isForceEnabled => _forceEnableInRelease;
}