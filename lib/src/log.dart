import 'app_logger.dart';
import 'log_config.dart';

class Log {
  Log._();

  static void t(dynamic msg) {
    if (LogConfig.shouldLog) appLogger.t(msg);
  }

  static void d(dynamic msg) {
    if (LogConfig.shouldLog) appLogger.d(msg);
  }

  static void i(dynamic msg) {
    if (LogConfig.shouldLog) appLogger.i(msg);
  }

  static void w(dynamic msg) {
    if (LogConfig.shouldLog) appLogger.w(msg);
  }

  static void e(
      dynamic msg, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    if (LogConfig.shouldLog) {
      appLogger.e(msg, error: error, stackTrace: stackTrace);
      // 🔮 Future hook: Crashlytics / Sentry always runs regardless of shouldLog
      // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }

  static void f(
      dynamic msg, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    if (LogConfig.shouldLog) {
      appLogger.f(msg, error: error, stackTrace: stackTrace);
    }
  }

  /// Enable release logging + rebuild logger instance
  static void enableReleaseLogging({Duration? timeout}) {
    LogConfig.enableTemporarily(timeout: timeout);
    refreshLogger(); // rebuild with new level
  }

  /// Disable release logging + rebuild logger instance
  static void disableReleaseLogging() {
    LogConfig.disable();
    refreshLogger();
  }
}