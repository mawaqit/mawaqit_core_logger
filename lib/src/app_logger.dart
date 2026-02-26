import 'package:logger/logger.dart';
import 'log_config.dart';

Logger buildLogger() => Logger(
  level: LogConfig.shouldLog ? Level.trace : Level.off,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

// Mutable so it can be rebuilt after LogConfig changes
Logger appLogger = buildLogger();

/// Call this after enabling/disabling release logs
/// to rebuild the logger with updated config.
void refreshLogger() {
  appLogger = buildLogger();
}