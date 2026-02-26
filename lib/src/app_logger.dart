import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final appLogger = Logger(
  level: kReleaseMode ? Level.off : Level.trace,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 100,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);