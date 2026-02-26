import 'app_logger.dart';

class Log {
  Log._();

  static void t(String msg) => appLogger.t(msg); // trace
  static void d(String msg) => appLogger.d(msg); // debug
  static void i(String msg) => appLogger.i(msg); // info
  static void w(String msg) => appLogger.w(msg); // warning

  static void e(
      String msg, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    appLogger.e(msg, error: error, stackTrace: stackTrace);
    // 🔮 Future hook: add Crashlytics or Sentry here
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  static void f(
      String msg, {
        Object? error,
        StackTrace? stackTrace,
      }) {
    appLogger.f(msg, error: error, stackTrace: stackTrace);
  }
}